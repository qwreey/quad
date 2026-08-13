# Bind 시스템 — pluggable key/value 핸들러 (base로 승격됨)

> **📄 [2026-08-13 아홉 번째 세션] 이 문서는 분할 중입니다 — 1단계 완료.**
> 2989줄까지 불어나 사람이 검토할 수 없고 한 곳의 실수가 미치는 범위가
> 너무 크다는 사용자 지적으로 쪼개는 중. **1단계로 분리된 것(내용/결정은
> 하나도 안 바뀜, 순수 이동)**:
>
> | 나간 것 | 어디로 |
> |---|---|
> | `Ref`/`PreRef` 전체 | `base/ref-plan.md` |
> | 이벤트 바인딩(self 미전달, `false`로 disconnect) | `base/event-plan.md` |
> | `Brand`(런타임 nominal 판별) | `base/brand-plan.md` |
>
> **2단계(예정, 0-Z 반영과 같은 패스에서 할 것)**: 아직 여기 남아있는
> **디스패치 코어**(핸들러 계약 / 확정된 디스패치 모델 / Dispatch 체인 /
> Handler 작성 체크리스트 / Length/Offset, ~1000줄)와 **반응형 코어**
> (`:With`+`:Compute` / Store·State·Source 온톨로지, ~950줄)를 각각
> 별도 문서로. **지금 안 쪼갠 이유**: 디스패치 코어는 0-Z 확정 시
> 어차피 전면 재작성 대상이라, 지금 옮기면 같은 텍스트를 두 번 만지고
> 인바운드 참조(~37곳)도 두 번 고쳐야 함 — 재작성하는 그 패스에서 파일을
> 가르는 게 총 변경량과 실수 위험이 모두 작음. 1단계가 인바운드 참조
> 12곳으로 끝난 것과 대조됨.

> **⚠️ [2026-08-13 여섯 번째 세션] 이 문서의 `hintValue`/`retractFrom` 선행
> 호출 서술은 곧 교체될 예정 — 아직 반영 안 됨.** 힌트가 `None` 센티널이나
> `State`/`Tween` 래퍼로 오염돼 말단 핸들러의 `isX(hint)` 가드를 거짓으로
> 만들고 깜빡임/재생성 방지를 조용히 끄는 결함이 확인됐고, 대체 모델
> (**래핑 핸들러의 `retractFrom` 선행 호출 폐기 + `Dispatch.process`가
> 핸들러를 먼저 비교**)까지 거의 확정됐음 — 다만 `question.md` **0-Z**
> (Attribute 이름 소유권) 하나가 남아 아직 옮기지 않음. **여기 적힌 대로
> 구현하면 옛 모델로 짜게 됨** — 반드시
> `research/dispatch-redispatch-diff-plan.md`를 먼저 읽을 것.

**상태**: base — 핵심 디스패치 모델(`process` + 그가 반환하는 retract
클로저, 핸들러 3종 계약 — 2026-08-13 다섯 번째 세션에 별도 `retract`
필드가 반환값으로 합쳐지기 전엔 `process`/`retract` 4종이었음,
Signal 미채택, Ref 역할)과 소스 트리 상 패키지 경계(디스패치 엔진은
`quad-base`가 인터페이스로 소유, `quad-roblox`는 실제 구현만)까지 전부
2026-08-04 세션에서 확정되어 `research/`에서 승격됨(`base/architecture.md`의
"구현 착수: 소스 트리 구조 확정" 절 참고). 남은 건 세부 시그니처(dependency
array API) 뿐 — 구현 단계에서 자연히 정리됨. 원본:
`.claude/initreq/raw-userinput.md`
"key와 value에 대한 바인드 연산은 pluggable 하도록 구성하기" / "스토어는 스토어를
저장 가능한가" / "Ref는 고민중" 절. v1의 문제점은 `reference/quad-v1-architecture.md`
("ProcessQuadProperty" 하드코딩 디스패처), 참고 패턴은 `.claude/initreq/tbox`
(레지스트리)와 Fusion/Vide 비교는 `reference/comparison-fusion-vide.md` 참고.

## 문제

v1의 `ProcessQuadProperty`(`.claude/initreq/quad/src/class.lua:134-214`)는
숫자 키(children/style) vs 문자열 키(prop/event) vs `__type` 태그 테이블
(register/linker/style)을 하드코딩된 if/elseif 체인으로 구분한다. 새 특수 키
(`[Attribute "X"]`, `[Tag ""]`, `PropertyChangedEvent ""` 등)를 추가하려면 이
중앙 함수 자체를 고쳐야 한다 — 라이브러리로서 확장 불가능한 구조.

## 핸들러 계약 (확정 — 아래 "확정된 디스패치 모델" 절과 통합해서 읽을 것)

**[전면 재정정, 2026-08-13 다섯 번째 세션] `process`/`retract` 2-메소드
계약에서 `process`가 자기 retract 클로저를 반환하는 1-메소드 계약으로
전환.** 계기와 근거는 아래 "Dispatch 체인" 절 참고 — 이 절은 바뀐 최종
계약만 서술.

핸들러는 다음 3개를 제공하는 등록 가능한 객체:

- `isHandlable(inst, key, value): boolean` — 이 핸들러가 이 inst/key/value
  조합을 처리할 수 있는지 판별하는 predicate. **부작용 없이, 빠르게** —
  tbox의 type-check/constraint-check 분리 원칙(`.claude/initreq/tbox/
  CLAUDE.md`의 "타입 체크는 분기 선택에 쓰이므로 순수해야 함")을 그대로
  적용: `isHandlable`은 오직 "이 핸들러가 맞는가" 판별에만 쓰이고, 실제
  유효성 검사는 핸들러가 선택된 *이후* 별도 단계에서. **`inst`도 받음
  (2026-08-07 여덟 번째 세션 정정, 원래 `(key,value)`뿐이었음)** —
  `process`/`retract`는 처음부터 항상 `inst`를 받았는데("모든 핸들러는
  대상 Instance를 직접, 항상 받는다", 아래 "확정된 디스패치 모델" 절)
  `isHandlable`만 예외였던 게 애초에 약간의 불일치. 지금 당장 `inst`에
  따라 매치 여부가 갈리는 케이스는 없지만, 나중에 필요해지면(다른
  백엔드에서 인스턴스 종류별로 매치가 달라져야 하는 경우 등) 핸들러
  계약 자체를 깨는 breaking change가 되므로 지금 넣어두는 게 훨씬 쌈 —
  사용자 판단으로 확정. **[2026-08-13 세션] 생략 불가, 항상 정의할
  것** — 같은 날 네 번째 세션에서 한때 "생략하면 스캔 불가시 체크포인트
  핸들러"로 확장했으나, 다섯 번째 세션(아래 "Dispatch 체인" 절)의 인덱스
  기반 재설계로 그 용도(`AttributeGroupKeyHandler`류 마커) 자체가
  없어져 이 확장도 같은 세션 안에서 신설·철회가 끝나 archive 이전 없이
  이 한 줄로만 기록.
- `priority: number` — 우선순위. 등록 순서(Fusion의 4단계 고정 stage, Vide의
  action() 우선순위)보다 일반화된 **열린 숫자 공간**으로.
- `process(inst, key, value, index): (hintValue) -> ()` — 실제 처리
  수행(아래 "확정된 디스패치 모델"/"Dispatch 체인" 절 참고) 하고,
  **자기 자신이 방금 벌인 일을 무르는 1-인자 클로저를 반환**.
  v1/기존 논의에서 "bind"라 부르던 것과 동일한 역할 + 예전의 `retract`
  필드가 여기로 합쳐짐(**[전면 재정정, 2026-08-13 다섯 번째 세션]**,
  계기·근거는 아래 "Dispatch 체인" 절). **반환값 생략 불가 — 정리할
  게 없는 핸들러도 항상 `function() end`(no-op) 형태로 반환할 것** —
  `Dispatch.process`(아래 절)가 이 반환값을 `chains`에 저장해뒀다가
  나중에 정확히 이 클로저 하나만 호출해서 정리하므로(예전 "retract 필드
  생략 불가" 규칙과 같은 이유, 자리만 옮겨옴). **[정정, 2026-08-13 7차
  감사] 생략했을 때 실제로 벌어지는 일**: `list[index] = nil`이 되어
  **배열에 구멍이 뚫림** — `#list`가 Lua 명세상 정의되지 않게 되고
  (`retractFrom`의 순회 시작점이 어긋남), 그 자리가 비어 보이므로
  `Dispatch.process`의 점유 체크도 통과해버려 **소유권 충돌 감지가 조용히
  꺼짐**. 옛 서술("`attempt to call a nil value`로 크래시")은 부정확했음 —
  `retractFrom`이 `if retractor then` 가드로 넘기고 있어서 크래시조차 안
  났음. 그 가드를 즉시 error로 바꿔 계약 위반이 실제로 드러나게 함.
  **핸들러가 직접 자기 자신의 하위 위임(재귀 `Dispatch.process`로 만든
  것들)까지 클로저 안에서 다시 정리할 필요는 없음** — `Dispatch.
  retractFrom`의 순회 구조 자체가 항상 깊은 인덱스부터 먼저 정리하고
  나서 얕은 인덱스로 올라오므로, 이 클로저가 불릴 시점엔 자기보다
  아래(자기가 만들어낸 하위 위임)는 이미 전부 정리된 뒤임(아래
  "Dispatch 체인" 절 참고) — 클로저는 **오직 자기 자신의 직접
  자원**(Observer 구독 등)만 정리하면 됨.

디스패치는 등록된 핸들러를 우선순위 순으로 스캔하며 `isHandlable`을 호출,
첫 매치가 처리(Fusion의 SpecialKey 우선순위 스캔과 유사하되 4단계 고정이 아니라
열린 레지스트리). tbox의 `TUnion` 런타임 체커가 이미 이 "순서대로 스캔, 첫 매치
반환, 실패 정보는 클로저로 지연 생성" 패턴을 구현해뒀음(`.claude/initreq/tbox/
src/schema/union.luau:48-68`) — 에러 메시지는 즉시 문자열로 만들지 말고 매치
실패 시에만 클로저 호출.

**우선순위 동률/매치 실패 처리 — 확정(2026-08-12 열일곱 번째 세션,
`pre-implementation-audit.md` 1-3/1-4 해소).**

- **동률(같은 `priority` 값)에 대한 tiebreak 규칙은 강제하지 않는다.**
  "등록 순서가 이긴다" 같은 규칙을 강제하면 `NoneHandler`/`StoreBind`처럼
  이미 서로 `isHandlable`이 안 겹치는 내장 핸들러에까지 전부 그 규칙을
  지켜가며 순서를 신경 써야 하고, 나중에 서드파티 핸들러가 늘어나면 더
  골치아파짐(사용자 판단). 대신 **목적별로 이름 붙은 우선순위 상수**
  (`HANDLER_PRIORITY_HIGH`/`HANDLER_PRIORITY_NORMAL`/`HANDLER_PRIORITY_LOW`
  등, 여전히 열린 숫자 공간 위의 편의 상수라 `HANDLER_PRIORITY_HIGH + 1`처럼
  세밀 조정도 가능)를 제공해 애초에 동률이 잘 안 나오게 유도 — "우선순위
  밴드 + 오프셋"은 여러 업계에서 이미 흔한 패턴. 실제로 동률이 나면 그건
  대개 핸들러 설계 실수라, 강제 규칙보다 아래 디버그 가시성으로 대응하는
  쪽이 맞음.
- **매치 실패(`isHandlable`을 만족하는 핸들러가 하나도 없음)는 조용한
  무시 없이 즉시 `error`.** 에러 메시지엔 값의 `Brand`(있으면)와
  `typeof(v)`를 함께 출력하고, "quad-roblox 등 필요한 provider가
  초기화됐는지 확인하라"는 안내만 덧붙임 — 그 이상의 특수 분기는 두지
  않음(다른 라이브러리에서도 흔한 "매치 실패=에러" 패턴 그대로).
  **이걸로 `module-lifecycle-plan.md`의 "provider가 아직 주입 안 된
  상태에서 dispatch가 호출되면?" 케이스(`pre-implementation-audit.md`
  1-4)도 별도 분기 없이 자동으로 해소됨** — provider 미주입 상태는
  결국 그 클래스를 다루는 핸들러가 레지스트리에 하나도 없는 상태이므로
  "매치 실패"와 정확히 같은 경로로 수렴함. 오타 키/미지원 조합/provider
  미주입을 서로 다른 에러 종류로 구분할 필요가 없음.
- **디버그 모드 — 핸들러 등록/정렬 시점에 동률 감지 시 print 경고 +
  전체 핸들러 목록 조회 함수.** 우선순위는 핸들러 등록 시점에 정적으로
  sort되므로 동률 감지 자체는 그 시점에 공짜로 가능 — `priority`가 같은
  두 핸들러가 등록되면 콘솔에 경고를 찍고, `Dispatch.listHandlers()`류
  함수로 현재 등록된 전체 핸들러(이름/priority)를 덤프할 수 있게 함.
  구현 비용이 거의 없고 실제 개발 중 디버깅에 바로 도움되는 항목이라
  M2(Dispatch 엔진) 착수 시 기본 기능으로 같이 넣음 — 런타임 플러그인인
  `quad-debug`(후순위, `research/debug-tooling-plan.md`)와는 다른 층위의,
  라이브러리 자체에 내장된 개발자 편의 기능.

## 확정된 디스패치 모델: `process(inst, k, v, index) -> retractor`

**사용자가 직접 준 구체적인 모델 — 이 문서의 이전 초안보다 우선함.** 아래가
실제로 구현할 모양. **[전면 재정정, 2026-08-13 다섯 번째 세션]** 이 절은
원래 `process(inst,k,v)`/`retract(inst,k,v)` 별개 2-메소드로 서술돼
있었으나, `chains`를 핸들러 **객체 identity**가 아니라 **인덱스**로
추적하는 재설계(아래 "Dispatch 체인" 절)와 함께 `process`가 자기
retract 클로저를 반환하는 1-메소드 계약으로 합쳐짐 — 이 절의 예시/규칙은
전부 새 모델로 갱신됨, 옛 2-메소드 버전은 `archive/`로 옮기지 않고 이
정정 표시로만 남김(오늘 하루 안에서 신설→재정정이 끝났기 때문).

- 모든 핸들러는 대상 **Instance를 직접, 항상** 받는다. quad는 "인스턴스를 생성하고
  그 인스턴스를 처리하는" 라이브러리다 — 다른 라이브러리가 만든 값(예: Store)을
  그 인스턴스에 적용하도록 돕는 역할에 가깝다. 그래서 핸들러가 "나중에 생길
  대상"을 비동기로 기다릴 필요 자체가 없음(`ref-plan.md`의 Ref 절 참고 — Ref는
  다른 이유로 존재).
  - **보강(2026-08-04)**: `inst`가 항상 살아있는 엔진 객체(Roblox Instance)일
    필요는 없음 — 특정 백엔드에서 실제 엔진 객체 생성/바인딩 비용이 비싸면
    (예: 웹 DOM) 중간 표현으로 평범한 테이블을 만들고 나중에 그 테이블을
    렌더링하는 것도 가능. 이건 core(base)가 신경 쓸 일이 아니라 각 최종
    엔드포인트 백엔드(`quad-roblox`/`quad-web` 등)가 알아서 결정할 문제 —
    base 인터페이스는 "무언가를 inst로 받아 process/retract한다"는 계약만
    지키면 됨, 그 inst의 실체가 뭔지는 백엔드 재량.
- `process(inst, k, v, index)` — 우선순위 순으로 등록된 핸들러를 스캔,
  `isHandlable(inst,k,v)`를 만족하는 최상위 핸들러가 실제 처리를 담당하고
  자기 retract 클로저를 반환. **이 "스캔+실행" 오케스트레이터는
  `Dispatch.process`로, 순수 스캔 부분은 `Dispatch.getHandler`로 이름이
  공식화됨**(아래 `None` 센티널 절, 2026-08-07 여덟 번째 세션) — 이
  절에서는 개념 설명이라 편의상 그냥 `process`로 계속 씀. **`index`가
  뭔지·왜 필요한지는 아래 "Dispatch 체인" 절 참고** — 요약하면 같은
  `(inst,k)` 안에서 "지금 몇 번째로 겹쳐 위임됐는지"를 나타내는 정수로,
  핸들러 객체 identity 대신 이 숫자로 체인 위치를 추적함.
- 예시: `Dispatch/StoreBind.luau`(범용, 엔진 무관)는 **`k`는 무엇이든 받고
  `v`가 State/Source인 경우를 잡아내는, 우선순위가 매우 높은 핸들러** —
  `v`가 반응형이면 그 값을 처리(구독)함. 이 핸들러 안에서:
  1. 지금 이 처리가 실행되어도 되는지 라이프타임(`Connected`)을 확인 —
     확인 안 하면 이미 Destroy된 대상에 대해 처리가 실행되는 문제가 생김. GC가
     결국 정리하긴 하지만, GC 되기 전에도 store 값이 업데이트될 수 있으므로
     그 시점엔 그냥 `Connected`를 보고 무시(no-op).
  2. 처리해도 되면, 사용자가 넘긴 함수들을 거쳐 실제 값(`realv`)을 계산.
  3. **재귀 호출 전에 먼저 `Dispatch.retractFrom(inst, k, index + 1, realv)`를
     불러 자기 밑에 위임돼 있던 걸 정리한 뒤, `realv`를 들고
     `Dispatch.process(inst, k, realv, index + 1)`를 재귀 호출**(정확한
     메커니즘은 아래 "Dispatch 체인" 절, 2026-08-08 세 번째 세션에 처음
     확정, 2026-08-13 다섯 번째 세션에 인덱스 기반으로 재정정 — 오케스트레이터
     이름 공식화는 아래 `None` 센티널 절 참고, 2026-08-07 여덟 번째
     세션) — 이게 바로 "store 바인드는 pluggable 바인드를 재실행하는
     래핑"이라는 이 문서 이전 초안의 결론과 일치. `realv`가 반응형이
     아니라면 자연히 `StoreBind`의 `isHandlable`을 통과 못 하고 우선순위상
     다음 핸들러(일반 프로퍼티 세터 등)로 흘러감 — 무한 재귀 걱정 없음.
     `realv`가 또 State/Source(`State<State<T>>`)여도 이제 **자연스럽게
     처리됨** — 안쪽 재귀는 `index+1`이라는 별개 슬롯을 쓰므로 바깥
     StoreBind의 슬롯(`index`)과 절대 안 겹침(아래 "Dispatch 체인" 절의
     `State<State<T>>` 재정정 참고, 예전엔 이게 UB였음).
     **[정정, 2026-08-10 세션]** 이 예시는 원래 "Tween의 store-bind
     핸들러"였으나, Tween이 독립 Dispatch 핸들러가 아니라 PropertyHandler가
     소비하는 값-레벨 래퍼(`Tween<T>`)로 재설계되며(`research/
     tween-plan.md`, `archive/tween-special-bind-key-reversed.md`) 이
     자리의 대표 예시에서 빠짐 — `NoneHandler`(아래 절)가 지금은 이
     패턴의 남은 대표 예시.
- **`process`가 반환하는 retractor(`(hintValue) -> ()`)** (이전 초안의
  "cleanup"/별도 `retract` 필드, 이름 변경 근거는 `base/lifecycle-pattern.md`
  참고, 별도 필드에서 반환값으로 합쳐진 경위는 위 "핸들러 계약" 절 —
  이전 처리를 무르는/멈추는 함수. **오직 "같은 key에 새 값이 들어와서
  이전 처리를 갈아치우는" 시나리오에만 존재** — 인스턴스/바인드 전체가
  Destroy될 때는 이 클로저가 호출되지 않음(`base/lifecycle-pattern.md`의
  "quad는 라이프사이클 중간에 있지 않다" 원칙 참고).
  - 일반 프로퍼티는 애초에 "unset" 개념이 없음(`nil`로 셋하는 것도 그냥 셋
    동작) — 그래서 프로퍼티 핸들러는 보통 no-op 클로저(`function() end`)만
    반환하면 됨.
  - **[정정, 2026-08-12 열한 번째 세션, 2026-08-13 다섯 번째 세션에 계약
    자체가 클로저로 바뀌며 서술 갱신] 이 클로저는 "핸들러 타입이 바뀔
    때만" 불리는 게 아니라, store 바인드가 재발행될 때마다(값이 뭐로
    바뀌든) 항상 불림** — 위 "확정된 디스패치 모델" 절이 처음부터
    말해온 그대로: `StoreBind`는 재-dispatch 전에 **무조건**
    `Dispatch.retractFrom(inst,k,index+1,realv)`를 불러 자기 밑에 쌓인
    클로저들을 꼬리부터 전부 부른 뒤에야 `Dispatch.process`가 다시
    매치를 시도해 새 체인을 쌓음. 즉 **"핸들러가 안 바뀌면 retract
    없이 process가 diff"라는 이전 서술은 틀렸음** — 그 오류의 상세
    경위(`Tag`의 옛 `assert(v==nil)`을 액면 그대로 믿고 거꾸로 일반
    규칙을 추론한 것)는 `archive/retract-always-fires-reversed.md` 참고,
    지금은 결론만 인용.
  - **정정된 원칙 — 대부분의 핸들러는 이 반복 호출에서 실제로 할 일이
    없어(일반 프로퍼티처럼 값을 그냥 덮어쓰면 끝이라 "unset" 개념 자체가
    없음) 반환하는 클로저가 사실상 no-op일 뿐, "타입이 안 바뀌면 아예
    안 불린다"는 뜻이 아님.** `Tag`/`Ref`/`Slot`/`Attribute`처럼 **여러
    위치가 하나의 실제 리소스(엔진 attribute/tag/mounted 서브트리 등)를
    공유하거나, 값 자체가 정리가 필요한 상태를 들고 있는** 핸들러는,
    이 클로저가 매번 불려도 **"이전 값이 지금 들어오는 새 값(`hintValue`)과
    사실상 같은지/그 새 값이 여전히 이 자원을 필요로 하는지"를 힌트
    삼아 판단해 실제 엔진 호출만 skip**하는 방식으로 대응해야 함 —
    `Tag`의 `Contains` 힌트, `Ref`/`Slot`의 identity 비교가 그 예.
    **`hintValue`를 반드시 `nil`로 가정하면 절대 안 됨**(대체하는 새 값
    그 자체일 수 있음) — 새 핸들러를 짤 때 이 클로저 안에서 `hintValue`의
    타입을 방어적으로 확인할 것.
  - **자연스러운 분업**: 여러 위치가 자원을 공유하는 핸들러는 대개
    "반환한 클로저가 이전 기여를 걷어내고(실제 해제는 힌트로 skip
    가능), `process`가 새 기여를 등록한다"는 모양으로 깔끔히 갈림 —
    `process` 쪽에 별도 old-vs-new diff가 필요 없어짐(그 diff를 클로저가
    이미 통째로, 매번 정확하게 해주므로). `Tag(...)`↔`nil`, `Attribute`의
    그룹이 이름을 놓는 경우도 이 분업의 자연스러운 특수 케이스일 뿐, 별도
    패턴이 아님 — 상세 구현은 `base/tag-plan.md`/`base/attribute-plan.md`
    "이름 소유권" 절, `Ref`는 아래 "`Ref`의 retract" 절, `Slot`은
    `slot-plan.md` "Slot과 Store 바인드의 관계" 절 참고.
  - **[일반 규칙] 클로저의 `hintValue`는 타입을 보장 안 함 — 내용(메소드/
    필드)을 보려면 반드시 `isX(hintValue)` 가드부터.** identity/nil만
    비교하면 가드가 필요 없지만(`Ref`/`Slot`/`AttributeKey`가 이 경우),
    내용을 실제로 들여다봐야 하면(`TagHandler`의 `newv:Contains(name)`처럼)
    그 전에 반드시 `isTag(newv)` 같은 타입 가드를 거칠 것 — 안 그러면
    그 자리 핸들러 *타입*이 바뀌는 드문 경우에 엉뚱한 값의 메소드를
    호출해 크래시함.
  - **[일반 규칙] 이 클로저 안에서 `Dispatch.process`를 부르는 것은
    UB — `Dispatch.retractFrom`이 체인을 걷는 도중의 트래킹이 꼬임.**
    이 클로저는 오직 청소(구조적 팝, 내부 자원 해제)만 전담하고 새
    등록을 트리거하면 안 됨 — 새 등록은 항상 바깥의 StoreBind/그룹
    로직이 클로저 호출이 다 끝난 *뒤에* 별도로 `process`를 부르는
    순서로만 일어나야 함. **`Dispatch.retractFrom`은 "다른 키에 대해서만"
    허용** — `Attribute` 그룹이 자기가 위임했던 `AttributeKey(name)`들을
    걷어내는 게 정확히 이 경우. **같은 `(inst,k)`에 대해 이 클로저 안에서
    `retractFrom`을 부르는 것도 `process`와 똑같이 금지(UB)** — 지금
    돌고 있는 바깥 `retractFrom`의 루프가 `#list`를 이미 캡처한 채
    꼬리부터 내려오는 중이라, 그 도중에 같은 list를 다시 훑으면 같은
    retractor가 두 번 불리거나 건너뛰어짐(2026-08-13 감사에서 명시화 —
    원래는 "다른 키에 대해"라는 괄호로만 암시돼 있었음).
  - **자기 자신의 하위 위임까지 클로저 안에서 수동으로 다시 정리할
    필요 없음** — 위 "핸들러 계약" 절 참고, `Dispatch.retractFrom`의
    순회 구조 자체가 항상 깊은 인덱스부터 정리하고 나서 얕은 인덱스로
    올라오므로 자동으로 해결됨(재귀/래핑 핸들러가 다단으로 겹쳐도
    각 클로저는 자기 자신의 자원만 책임지면 전체 cascade가 저절로 됨 —
    2026-08-08 세 번째 세션에 확정된 "다단 체인 자동 전파" 성질이 인덱스
    모델에서도 그대로 유지, 오히려 더 단순해짐).
  - Tween은 이 패턴과 무관 — 독립 Dispatch 핸들러가 아니라 PropertyHandler가
    소비하는 값-레벨 래퍼(`Tween<T>`)라 매치되는 핸들러가 항상
    PropertyHandler 하나뿐(2026-08-10 세션 재설계) — 트윈 취소/전환은
    PropertyHandler 내부의 3-상태 릴레이션 슬롯으로 처리(`base/tween-plan.md`,
    `archive/tween-special-bind-key-reversed.md`).
- **핸들러 내부 상태 저장 — 클로저로 충분한 것과 `Relate`가 필요한 것을
  구분할 것.** "이 `process` 호출이 만든 걸 나중에 정리하는" 단발성
  handoff는 이제 클로저의 업밸류 캡처만으로 충분(예: Observer 객체를
  로컬 변수로 만들고 그대로 반환 클로저가 캡처) — 예전처럼 `Relate`에
  저장했다가 나중에 다시 조회할 필요가 없어짐(**[2026-08-13 다섯 번째
  세션, 이 문단 재작성]**). `Relate`가 여전히 필요한 경우는 **여러 번의
  독립적인 `process`/클로저 호출을 가로질러 누적되는 상태**뿐 —
  `Tag`의 `tagNameMap`(여러 위치가 같은 이름을 공유), `Attribute`의
  이름 소유권처럼 "이 `(inst,k)` 하나의 클로저 수명을 넘어서는" 정보만
  `local relate = Relate()`(모듈 톱레벨, `relate:SetStrong(inst,k,v)`/
  `:GetStrong(inst,k)`)로 저장. `base/lifecycle-pattern.md`의
  `bindLifetime`/`canExecute`도 같은 `Relate`를 내부적으로 씀(용도가
  다르니 별도 `Relate()` 인스턴스) — 이건 "언제까지 실행돼도 되는지"를
  묻는 것이라 애초에 클로저 수명과 무관한, 계속 남는 질문이라 그대로
  `Relate` 기반.
- **다른 값 변경을 추적하는 것도 process 함수의 정상 범위**: 예를 들어 Slot
  핸들러는 자기가 감시하는 값(배열/스토어)이 바뀌면 그에 따라 child를
  갱신해야 함 — `retract` 시점엔 그 추적(구독)만 풀면 됨.
- **일반적인 무한루프 방어(사이클 감지 등)는 하지 않기로 확정(2026-08-04,
  로드맵 인수인계 라운드)**: 우선순위 스캔+재귀 `process` 구조 자체는 핸들러가
  규율을 안 지키면(예: 값을 좁히지/변형하지 않고 같은 값을 그대로 다시
  `process`에 넘김) 무한루프에 빠질 수 있음 — 하지만 이건 base가 방어 로직을
  둬야 할 문제가 아니라 오작동하는 handler/provider(`quad-roblox` 등) 쪽
  버그로 간주 — **사용자 확정**("입력된 값이 다시 입력되면 무한루프
  빠지겠지만, 그건 막기 힘들고 유저가 내기도 힘들어. 아예 quad-roblox나
  프로바이더가 잘못 짠 코드일테니까"). `StoreBind`의 재귀 케이스(위 절)처럼
  자연히 좁혀지는 경우가 일반적이고, 일반 사용자가 만들어낼 수 있는 상황이
  아니라고 판단해 별도 가드 없이 진행.

- **props 순회 순서는 base 디스패치 드라이버가 명시적으로 두 단계로
  고정한다 — 배열 파트(숫자 키, children/Ref류) 먼저, 해시 파트(문자열 키,
  프로퍼티/이벤트/특수 DI 키) 나중(2026-08-07 세 번째 세션).** Luau
  테이블을 `pairs`/제네릭 `for`로 순회하면 실제로 배열 파트가 해시 파트보다
  먼저 나옴(`for i, v in {a=1, 2, b=3} do print(i,v) end` → `1 2`, `a 1`,
  `b 3` 순서 — 사용자가 직접 확인). 이 관찰된 동작에 그냥 얹혀가지 않고,
  **base 드라이버가 명시적으로 두 패스로 나눠 돌기로 계약화**한다 — 숫자
  키(children)를 먼저 index 순서대로 처리하고, 그 다음 나머지 키를 처리.
  이유: (1) 다른 백엔드(`quad-web` 등)가 병합된 props를 Lua 테이블이 아닌
  다른 자료구조로 표현할 수도 있어서 "Lua 테이블의 우연한 내부 동작"에
  기대면 이식성이 깨짐, (2) 어차피 숫자 키(children/Ref)와 문자열
  키(프로퍼티/이벤트)를 다른 의미로 취급해야 하니 구분 비용이 이미 드는
  참에 순서까지 명시적으로 고정하는 게 거의 공짜. **결과적으로 배열
  슬롯에 놓인 어떤 값(Ref 포함)이든 모든 프로퍼티/이벤트 세팅보다 항상
  먼저 처리된다는 게 base 자체의 보장**이 됨 — `ref-plan.md`의 "Ref 일반화" 절
  뒤에 이어지는 "PreRef" 절이 이 보장 위에서 성립. **M0 스파이크에서 실제
  Luau로 이 순회 동작 자체를 검증할 것**(지금까지 추론/관찰만으로 확정된
  항목 — `research/pre-implementation-audit.md`가 짚은 "실제 Luau로
  부딪혀본 적 없는 것" 범주와 같은 급이라 신중하게 다룸).

### `None` 센티널 — StoreBind와 같은 재귀 재디스패치 패턴 재사용 (2026-08-07 여덟 번째 세션, 예시는 2026-08-10 세션에 StoreBind로 정정)

`modifier-plan.md` "2-1"절의 "인라인 키로 modifier 필드를 명시적으로
지우기" 문제 — raw 저장 계층(Modifier 필드/인라인 props/`Peek`)에서 쓰는
`None` 센티널이 실제로 인스턴스에 반영될 때 base가 뭘 하는지가 이 문서의
층위. 결론: **새 메커니즘이 아니라 위 "확정된 디스패치 모델"의
`StoreBind` 핸들러(위 절)와 완전히 같은 모양의 핸들러 하나 추가.**

```lua
NoneHandler.priority = <매우 높음>
NoneHandler.isHandlable(inst, k, v) = (v == None)
function NoneHandler.process(inst, k, v, index)
    Dispatch.process(inst, k, nil, index + 1)  -- 재귀 재호출, 별개 인덱스
    return function() end  -- 자기 자신은 아무 상태도 없어 no-op
end
```

- **매치 predicate는 `isHandlable`** — `canExecute`가 아님. 둘은 완전히
  다른 개념이라 혼동하지 말 것: `isHandlable(inst,k,v)`는 KV 매치 predicate
  (핸들러 계약 3종 중 하나, 이 절에서 다루는 것 — 예전엔 `(k,v)` 2-인자에
  4종 계약이었으나 각각 2026-08-07 여덟 번째/2026-08-13 다섯 번째 세션에
  바뀜, 이 문단만 갱신에서 누락돼 있던 걸 같은 날 감사에서 발견), `canExecute`는 인자로 받은 특정
  바인딩/등록 하나가 "지금 살아있어서 실행돼도 되는가"만 보는 별개의
  라이프타임 게이트(`base/lifecycle-pattern.md` "생명 바인드 유틸" 절) —
  KV 매치와 무관.
  **이 `NoneHandler`는 해시 파트(프로퍼티/이벤트) 전용 — 배열 파트에서
  `None`을 만나는 건 완전히 다른 규칙(2026-08-07 열 번째 세션, "PreRef"
  절 "호이스팅의 실제 구현" 참고).** 배열 파트의 `None`은 "빈 슬롯"
  표시일 뿐 처리할 핸들러 자체가 없으므로, `Dispatch.drive`의 두 패스
  루프 자신이 `NoneHandler`/`Dispatch.process`를 거치지 않고 바로
  건너뜀 — 같은 센티널 값이지만 배열 파트냐 해시 파트냐에 따라 처리
  경로가 다르다는 점에 유의.
  `NoneHandler.isHandlable`은 `v == None`(센티널 자체)을 잡는 것이지
  `v == nil`이 아님 — 진짜 `nil`은 애초에 테이블 순회로 나올 수 없다는 게
  이 문제의 출발점이었으므로, 매치 대상은 항상 `None` 마커.
  `Dispatch.process(inst, k, nil)`로 재귀 호출하는 순간 `None`은 더 이상
  존재하지 않고 진짜 `nil`이 되므로, 다음 우선순위 스캔은 자연히 키 `k`를
  원래 담당하던 핸들러(프로퍼티/이벤트/UI shorthand 등)로 흘러감 —
  `StoreBind` 핸들러가 `realv`를 들고 재귀하면 자연히 다음 핸들러로 좁혀지는
  것과 정확히 같은 원리, 무한루프 걱정도 동일하게 없음.
- **`Dispatch.process`/`Handler.process` 이름 겹침 — 소유자 네임스페이싱으로
  해소, 새 이름 발명 안 함 (2026-08-07 여덟 번째 세션 후속).** 원래
  "확정된 디스패치 모델" 절은 "스캔+실행"과 "매치된 핸들러 자신의 처리
  로직" 둘 다 그냥 `process`라고 불러서 이름이 겹쳤음 — 이제 두 계층을
  명시적으로 분리:
  - `Dispatch.getHandler(inst,k,v): Handler?` — 순수 스캔(`handler.isHandlable(inst,k,v)`+
    `priority`), 부작용 없음.
  - `Dispatch.process(inst,k,v,index)` — 오케스트레이터: 그 인덱스가 이미
    점유돼 있으면 즉시 error(핸들러 호출 전에 걸러짐) → 아니면
    `getHandler` 호출 → 매치된 핸들러의 `.process`를 불러 그 반환값
    (retractor 클로저)을 `(inst,k)` 체인의 그 인덱스에 저장. **"이전
    핸들러와 다르면 retract"라는 diff는 `Dispatch.process` 자신의 일이
    아님** — 재귀/래핑 핸들러(`StoreBind`/`NoneHandler`)가 재-dispatch
    전에 스스로 `Dispatch.retractFrom(inst, k, index + 1, newV)`를 먼저
    불러 자기 밑을 정리하는 책임을 짐(정확한 메커니즘·기각된 대안은
    아래 "Dispatch 체인" 절 참고 — 전역 소유자 슬롯 하나로 diff하는
    안은 래핑 핸들러에서 깨져서 기각됨).
  - `Dispatch.addHandler(handler: Handler)` — 핸들러를 우선순위 레지스트리에
    등록. `Dispatch.process`/`getHandler`와 마찬가지로 base엔 인터페이스만
    있고, quad-roblox의 concrete Handler들(PropertyHandler/EventHandler/
    OnChangeHandler/UICornerHandler/TagHandler/AttributeHandler 등)은
    팩토리가 `BaseModule`을
    뮤테이션하는 시점에 이걸로 등록됨(아래 "base 유틸은 인터페이스" 절과
    같은 패턴, 새 메커니즘 아님).
  - Handler 자신의 필드는 계속 `process`/`retract`(이미 확정된 이름,
    `question.md`에 "특별한 문제 없음"으로 못박혀 있어 재검토 대상 아님) —
    겹침은 실제 런타임 충돌이 아니라 프로즈 표기 문제였을 뿐이라, 항상
    소유자를 명시(`Dispatch.process` vs `handler.process`)하는 것으로 해소.
  - **base 드라이버 루프 자신의 이름은 `Dispatch.drive(inst, flattened)`로
    확정** — 이미 위 "props 순회 순서" 절이 이걸 비공식적으로 "base
    디스패치 드라이버"라고 불러왔던 걸 그대로 동사화(`apply`는 "Dispatch를
    뮤테이션해서 결과를 낸다"는 어감이라 기각 — 사용자 판단). `inst`와
    flatten된 props 테이블을 받아 배열 파트(children/Ref) 먼저, 해시
    파트(프로퍼티/이벤트) 나중으로 두 패스 순회하며 각 `(k,v)`에
    `Dispatch.process(inst, k, v, 1)`을 호출하는 게 이 함수의 본체.
    **진입 인덱스는 항상 `1`**(2026-08-13 감사에서 명시화 — 인덱스 도입
    후에도 이 자리만 인자가 안 적혀 있었음) — `drive`는 그 키의 체인을
    처음 여는 자리이므로 "다른 키로 위임할 때는 그 키의 재귀 깊이와
    무관하게 항상 1부터"(아래 "Dispatch 체인" 절)라는 규칙의 가장 기본
    사례. 같은 키가 두 번 나올 수 없는 테이블 순회라 여기서 점유 충돌이
    날 일도 없음(단, 그룹 `Attribute`가 배열 파트에서 먼저 점유해둔
    이름을 해시 파트 직접 쓰기가 다시 건드리면 그건 정상적으로 점유
    error — `base/attribute-plan.md` "이름 소유권" 절).
- **`v=nil`이 구체적으로 뭘 뜻하는지는 핸들러마다 다름, `None` 자신은
  "리셋"이 아님** — 일반 프로퍼티는 "`nil`로 셋하는 것도 그냥 셋 동작"이라
  사실상 그대로 두는 것과 다름없고, UICorner 같은 숏핸드 핸들러는 만들어둔
  자식 Instance를 실제로 지우는 것까지 포함 — 구체 예시는
  `base/ui-shorthand-plan.md`/`base/tag-plan.md`/`base/attribute-plan.md`.
  `None`은 **"이 조합 단계에서 나는 이 필드를 세팅 안 한다"**는 뜻이고,
  그걸 받은 실제 핸들러가 무엇을 할지는 각자 몫. 개별 프로퍼티/이벤트/UI
  shorthand 핸들러의 `process` 시그니처는 안 바뀜 — 이들은 원래도 `v`가
  State 계산 결과로 `nil`이 되는 경우를 처리할 수 있어야 했으므로(일반
  반응형 케이스), `None`은 그 기존 경로에 도달하는 방법 하나가 늘어난 것뿐.
  **구현 디테일 캐비엇**: `None→nil`이 Roblox의 nil을 허용 안 하는 타입
  프로퍼티(Color3/number 등)에 도달하면 `inst[k] = nil`은 런타임 에러 —
  PropertyHandler 자신이 `v == nil`이면 셋을 건너뛰는 방어를 갖고 있어야
  함(None 자체의 문제가 아니라 PropertyHandler 구현 디테일, M9/M10로 미룸).
- **반환하는 retractor는 여기서 할 일이 없음** — `NoneHandler`는 `v==None`을
  매치했을 때 재귀 호출로 곧바로 `Dispatch.process(inst,k,nil,index+1)`을
  부르는 게 전부고 자기 자신이 들고 있는 별도 상태가 없어서(`Relate` 등
  전혀 안 씀) `function() end`(no-op)만 반환하면 됨 — 일반 프로퍼티
  핸들러가 no-op 클로저를 반환하는 것과 같은 이유. 자기 아래(index+1)에
  쌓인 것의 정리는 `Dispatch.retractFrom`의 순회 구조가 대신해줌(위
  "핸들러 계약" 절 참고), `NoneHandler` 자신이 손댈 필요 없음.
- **[해소됨, 2026-08-08 세 번째 세션, 2026-08-13 다섯 번째 세션에
  인덱스 기반으로 재정정]** "이 키를 지금 누가 담당 중인가" bookkeeping —
  `pre-implementation-audit.md` 우선순위1 "이전에 실제로 매치됐던 핸들러
  추적" 항목이 여기서 다시 언급됐던 것. 아래 "Dispatch 체인" 절의
  `chains`/`Dispatch.retractFrom`로 구체화됨 — `NoneHandler`의 재귀
  재호출도 이 메커니즘 위에서 동일하게 동작(`None`으로 유지되는 매
  사이클마다 담당자가 자연히 정확하게 갱신됨, 별도 특수 처리 불필요).

### Dispatch는 프리미티브가 아니다 — 탑레벨 싱글톤 확정 (2026-08-08 두 번째 세션)

`Dispatch.process`/`getHandler`/`addHandler`/`drive`를 `Source`/`Ref`/`Store`/
`Modifier`처럼 생성자가 있는 프리미티브(예: `Dispatch()`로 인스턴스를 여러 개
만들 수 있는 것)로 바꿔야 하는지 검토 후 **기각, 지금 형태(모듈 require로
바로 닿는 flat 탑레벨 함수) 유지로 확정**:

- **재귀 재-dispatch가 요구하는 필연** — `NoneHandler`/`Dispatch/
  StoreBind.luau` 전부 자기 `process` 안에서 다시 `Dispatch.process(inst,k,
  realv)`를 호출함(위 "확정된 디스패치 모델"/"`None` 센티널" 절). 이게
  성립하려면 Dispatch가 `canExecute`/`bindLifetime`(`base/
  lifecycle-pattern.md`)과 똑같이 require 한 번으로 바로 닿는 안정된
  전역이어야 함 — 인스턴스화 가능한 프리미티브로 만들면 모든 Handler
  등록/호출 경로에 Dispatch 핸들을 인자로 계속 실어날라야 하는 스레딩
  비용이 생기는데, 지금 형태는 그 비용을 아예 안 짐.
- **순환참조로 보이는 건 착시 — 실제로는 단방향.** "Handler"라는 말이 두
  가지를 가리켜서 헷갈릴 수 있음: (a) `Handler.luau`의 **타입 계약**
  (`isHandlable`/`priority`/`process`(반환값 포함) 시그니처만 있는 순수
  leaf, Dispatch를 몰라도 됨) vs (b) `StoreBind.luau`처럼 그 계약을
  **구현하는 concrete 값 모듈**(재귀호출 위해 Dispatch를 require함). 의존
  방향은 항상 한쪽으로만 흐름 — `Handler.luau`(leaf) ← `Dispatch/init.luau`
  (`addHandler(h: Handler)`가 `Handler` 타입만 참조) ← `StoreBind.luau`
  (재귀호출 위해 Dispatch를 참조). `Handler.luau` 자신이
  Dispatch를 되받아 참조하는 일이 없으니 타입 레벨에서도 사이클이 안 생김.
  런타임에서도 마찬가지 — 어떤 handler의 `process`든 실제로 *호출*되는
  시점은 컴포넌트가 렌더되는 시점이라, 그때는 이미 Dispatch 모듈 require가
  완전히 끝나있어 부트스트랩 문제도 없음.
- **quad-base 자신의 기본 핸들러도 같은 레지스트리를 씀** — `NoneHandler`,
  `Dispatch/StoreBind.luau`("범용, 엔진 무관")뿐 아니라, children 배열
  숫자 슬롯에 `Ref`/`Observer`/`PreRef`를 직접 놓는 leaf 값을 매칭하는
  Handler도 여기 속함(`inst`를 `any`로 취급, 엔진 특정 API 불필요 —
  `.claude/question.md`가 2026-08-08 세션에 "quad-base/quad-roblox 중
  어디 사는지 미확인"으로 남겨뒀던 항목, 이 결론으로 해소: quad-base,
  `Dispatch/Leaf.luau`, `Dispatch.addHandler`로 등록). quad-roblox의
  Property/Event 핸들러도 **같은** `Dispatch.addHandler` 레지스트리에
  등록됨 — base 기본 핸들러와 backend 핸들러가 별도 경로로 안 갈리고
  전부 하나의 우선순위 스캔을 공유. **[정정, 2026-08-10 세션]** Tween은
  더 이상 별도로 등록되는 핸들러가 아님 — Property 핸들러 내부에서
  소비되는 값-레벨 래퍼로 재설계됨(`base/tween-plan.md`).
- **모듈 재생성(`New()`)과의 관계 — 새 설계 불필요, 이미 있는 선례로 자연히
  풀림.** v1처럼 `require`를 감싸 `Init(QuadId?)`로 격리 인스턴스를 만드는
  방식은 안 씀(위 "확정된 것" 절 — id 기반 조회 자체가 Ref로 대체되며
  기각됨). 대신 이미 확정된 "base 유틸은 인터페이스, 실제 구현은 팩토리가
  `BaseModule`을 뮤테이션해서 주입"(`RobloxFactory(BaseModule)`) 패턴을
  그대로 따름 — Dispatch의 handler 레지스트리도 `BaseModule` 테이블에
  딸린 state 중 하나일 뿐이라, `_initializedBy` 마커에 대해 이미 확정된
  것과 완전히 같은 논리가 적용됨(위 "base 유틸은 인터페이스" 절, "`New()`가
  생기면 각 인스턴스가 별도 테이블이 되므로 이 마커도 테이블별로 독립적으로
  스코핑됨, 재설계 불필요"). `New()`가 실제로 생기면 그 시점에 BaseModule
  전체를 인스턴스별 테이블로 만드는 메커니즘에 Dispatch도 자연히 같이
  딸려가고, 호출부는 `module.Dispatch.process(...)`처럼 그 인스턴스
  테이블을 통해 접근하게 됨 — 지금 미리 프리미티브화해둘 이유가 없음.

### Dispatch 체인 — 인덱스 기반 재추적, `Dispatch.retractFrom` (2026-08-08 세 번째 세션 신설, 2026-08-13 다섯 번째 세션 전면 재설계)

**[전면 재설계, 2026-08-13 다섯 번째 세션]** 이 절은 원래 `chains`를
핸들러 **객체 identity**로 추적했으나(옛 버전은 `archive/
checkpoint-handler-pattern-reversed.md`에 그 위에 얹혔던 체크포인트
패턴과 함께 보존), 그 표현 자체가 `State<State<T>>`를 UB로 만든
근본 원인이었음이 드러나 **재귀 깊이를 나타내는 정수 인덱스**로
추적하도록 다시 설계됨. 계기: `AttributeGroupHandler`의 소유권 충돌
버그를 고치려고 체크포인트 핸들러 패턴을 얹었다가, 사용자가 "그 문제도
결국 identity 기반 추적이 원인 아니냐"고 되짚으면서 인덱스 기반으로
가면 체크포인트 없이도 같은 문제가 풀리고 `State<State<T>>` UB 자체도
없앨 수 있다는 게 같은 세션 안에서 확인됨.

**문제(원래 동기, 여전히 유효)**: `NoneHandler`/`StoreBind`처럼 자기
`process` 안에서 `Dispatch.process(inst,k,realv)`를 다시 부르는 래핑
핸들러가 있으면, 같은 `(inst,k)`에 대해 "지금 누가 담당 중인가"를 슬롯
하나로 추적하는 순간 깨짐 — 래핑 핸들러 A 자신의 생명주기(예: StoreBind의
Observer 구독)와, A가 재귀로 위임한 핸들러 B의 생명주기가 **같은 슬롯을
두고 서로 덮어씀**. 처음 검토했던 "Dispatch 전역 소유자맵 슬롯 하나" 안은
이 이유로 기각됨.

**해법 — Dispatch가 `(inst,k)`별로 인덱스 배열을 소유, 각 슬롯엔 그
`process` 호출이 반환한 retractor 클로저만 저장**:

```lua
-- Dispatch/init.luau
local chains = Relate()  -- {[inst(weak)] = {[k] = {[index] = retractor}(strong)}}
local NOOP = function() end

function Dispatch.process(inst, k, v, index)
    -- [순서 주의, 2026-08-13 감사] 아래 두 줄(list 확보 + chains 등록)은 반드시
    -- h.process 호출 *전에* 끝나야 함 — h.process가 내부에서 재귀
    -- Dispatch.process(inst,k,...,index+1)를 부르는 게 정상 경로이고(StoreBind/
    -- NoneHandler), 그때 chains에 이 list가 아직 안 들어가 있으면 재귀 호출이
    -- `or {}`로 자기만의 새 테이블을 만들어 저장해버린 뒤 바깥이 그걸 덮어써서
    -- 하위 위임 retractor가 통째로 유실됨(최초 마운트에서 항상 발생).
    local list = chains:GetStrong(inst, k)
    if not list then
        list = {}
        chains:SetStrong(inst, k, list)
    end
    if list[index] ~= nil then
        error("Dispatch: (inst,k)의 이 인덱스는 이미 점유돼 있음 — 먼저 retract할 것")
    end
    -- 점유 마커를 먼저 박는 이유: (1) h.process가 재귀하는 동안 list가 구멍
    -- 없는 시퀀스로 유지돼야 `#list`가 정의됨(hole 있는 테이블의 `#`는 Lua가
    -- 보장 안 함), (2) 핸들러가 같은 index로 재진입하는 버그도 이 가드에 걸림.
    list[index] = NOOP
    local h = Dispatch.getHandler(inst, k, v)  -- 매치 실패는 기존 규칙대로 즉시 error
    list[index] = h.process(inst, k, v, index)  -- 반환값 = retractor 클로저, 생략 불가
end

function Dispatch.retractFrom(inst, k, index, v)
    -- index부터(포함) 끝까지, 꼬리(가장 깊은 인덱스)부터 역순으로 정리.
    local list = chains:GetStrong(inst, k)
    if not list then return end
    for i = #list, index, -1 do
        local retractor = list[i]
        -- [정정, 2026-08-13 7차 감사] 예전엔 `if retractor then ... end` 가드였으나,
        -- 그 가드에 걸리는 경우는 **핸들러가 계약을 어기고 nil을 반환한 것뿐**이고
        -- (정상 경로는 process가 항상 NOOP 마커를 먼저 박음) 조용히 넘기면 이미
        -- 배열에 구멍이 난 뒤라 `#list`도 점유 체크도 같이 망가짐 — 즉시 error가 맞음.
        if retractor == nil then
            error("Dispatch: 인덱스 " .. i .. "에 retractor가 없음 — 핸들러가 반환을 생략했음")
        end
        retractor(if i == index then v else nil)
        list[i] = nil
    end
end
```

- **점유 체크는 핸들러를 부르기 전에, Dispatch가 직접 함** — 매치된
  핸들러의 `.process`가 실제 부작용(`SetAttribute`, Observer 구독 등)을
  일으키기 *전에* 걸러야, "일단 실행해보고 나중에 되돌리는" 낭비/깜빡임이
  없음. 충돌이 나면 핸들러 코드는 한 줄도 안 돔. **에러 메시지가
  도메인 특화(예: "attribute 이름 foo 충돌")로 상세하지 않은 건 의도된
  트레이드오프** — 에러가 나는 순간 이미 처리는 패닉 상태이고 그 이후의
  정합성은 애초에 관리 대상이 아니므로(2026-08-04 "일반적 무한루프 방어
  안 함"과 같은 결), 상세한 설명을 위해 먼저 실행해보는 비용을 들일
  이유가 없음. 필요하면 호출부(`AttributeGroupHandler` 등)가 이 에러를
  잡아 도메인 언어로 다시 던지는 건 자유(강제 안 함).
- **인덱스의 의미 — 재귀 깊이, 서로 다른 키는 항상 1부터**: 같은 키에서
  값이 한 겹 더 반응형으로 감싸져 재귀하면(`StoreBind`가 `realv`를 들고
  다시 `Dispatch.process`를 부르는 경우) `index+1`을 넘김. **다른
  키로 위임할 때는 그 키의 재귀 깊이와 무관하게 항상 `1`부터 시작** —
  `chains[inst][key2]`는 `chains[inst][key1]`과 완전히 별개의 배열이라
  연속성이 필요 없음(예: `Attribute` 그룹이 `(inst,index)`에서
  `(inst,AttributeKey(name))`으로 위임할 때). **시작 인덱스는 0이 아니라
  1** — Luau `ipairs`/`#`(배열 part 순회)는 1부터 연속된 정수 키를
  전제하므로(quad 자신이 "props 순회 순서" 절에서 이 관례에 의존), 0을
  쓰면 그 항목이 `ipairs` 순회에서 조용히 빠지고 `quad-debug`가 나중에
  `chains`를 그대로 순회해서 보여주려는 계획과도 부딪힘.
- **`handler.process(inst,k,v,index)`를 `Dispatch.process`를 거치지 않고
  직접 호출하는 것은 UB — 반드시 `Dispatch.process`를 통해서만 진입할
  것.** 이유: 점유 체크·`chains` 저장 bookkeeping이 `Dispatch.process`
  내부에만 있어서, `handler.process`를 직접 부르면 그 핸들러가 실제로
  활성화됐는데도 체인에 안 올라가 — 나중에 `retractFrom`이 이 핸들러의
  존재를 몰라 정리가 영영 안 되거나(리소스 누수), 반대로 같은 인덱스를
  다른 핸들러가 또 점유 시도해 정합성이 깨짐.
- **재귀/래핑 핸들러는 재-dispatch 전에 반드시 `Dispatch.retractFrom(inst,
  k, index + 1, newV)`를 먼저 부른 뒤 `Dispatch.process(inst, k, newV,
  index + 1)`를 부름** — "내 바로 아래부터 전부 정리하고 새로 위임".
  자기 자신(`index`)은 그대로 살아있으므로 자기 자신의 retractor는 이
  시점에 안 불림 — 자기가 완전히 사라질 때(더 바깥의 `retractFrom`이
  자기 인덱스까지 포함해서 부를 때)만 불림.
- **개별 핸들러의 retractor는 더 이상 자기 위임 대상을 수동으로 안
  쫓아가도 됨** — `retractFrom`이 꼬리(가장 깊은 인덱스)부터 목표
  인덱스까지 한 번의 루프로 순서대로 정리해주므로, A→B→C처럼 몇 단계든
  각 핸들러는 **자기 자신의 자원만** 정리하면 자동으로 전파됨. 자기
  자신을 포함해서 지우고 싶으면(`Attribute` 그룹처럼 위임한 것 전체를
  통째로 걷어내고 싶은 경우) 호출자가 자기 자신의 인덱스를 그대로
  넘기면 되고, 자기 아래만 지우고 싶으면(`StoreBind`가 자기 구독은
  유지한 채 하위만 갈아치우는 경우) `index+1`을 넘기면 됨 — **"미만"과
  "이하"를 별도 함수로 안 쪼개고 호출자가 넘기는 인덱스 하나로 통일**
  (옛 `retractUnder`/`retractSelfAndUnder` 두 함수가 이걸로 하나가 됨,
  `archive/checkpoint-handler-pattern-reversed.md` 참고).
- **`process`가 반환하는 retractor는 여전히 `hintValue` 1-인자** — 드롭하자는
  제안이 대화 중 한 번 나왔으나 기각(전체 삭제 vs 부분 diff를 갈라야
  하는 핸들러가 있어서, `base/tag-plan.md` 참고). `Tag`는 오히려
  이 힌트를 반드시 봐야 하는 대표 사례다: 이 클로저는 store 재발행마다
  (핸들러 타입이 안 바뀌어도) 항상 불리므로, `TagHandler`가 반환한
  클로저는 `hintValue`가 여전히 그 이름을 `Contains`하는지 확인해 실제
  엔진 `RemoveTag` 호출만 skip한다 — 상세는 `base/tag-plan.md` "메커니즘"
  절 참고. `hintValue`는 "계약상 항상 주어지지만 안 쓰는 핸들러가
  있어도 됨" 정도로 이해할 것.
- **`hintValue`는 "직속 위임 1단계"에만 보장됨 — 깊은 인덱스는 항상 `nil`
  (2026-08-13 여섯 번째 세션 명시화).** 위 `retractFrom` 의사코드의
  `retractor(if i == index then v else nil)`이 그대로 계약임: 힌트를 받는
  건 **호출자가 지목한 `index` 자리 하나뿐**이고, 그보다 깊은(꼬리 쪽)
  인덱스들은 전부 `nil`을 받음. 결과:
  - **`State<Tag>`/`State<Ref>`/`State<Slot>`(한 겹)은 힌트가 확실히
    전달됨** — StoreBind가 인덱스 1, 실제 핸들러가 인덱스 2이고
    StoreBind는 `retractFrom(inst,k,index+1=2,realv)`를 부르므로
    `i == index`가 정확히 그 핸들러에 걸림. 즉 `Tag`의 `Contains` 힌트,
    `Ref`/`Slot`의 identity 비교 같은 깜빡임/재생성 방지가 **흔한
    경로에서는 유실 없이 동작**함.
  - **두 겹 이상(`State<State<Tag>>` 등)에서 바깥이 재발행하면 안쪽
    핸들러는 `nil` 힌트를 받음** — 구조적으로 불가피(바깥 단계는 안쪽
    State가 결국 어떤 값을 내놓을지 모름). 동작은 정상이지만 힌트 기반
    최적화만 꺼짐.
  - **[검토 후 기각] `chains`에 핸들러도 같이 저장해두고, 깊은 인덱스의
    핸들러가 새 값에 매치될 핸들러와 같으면 값을 한 겹 풀어 힌트로
    내려보내는 안**(사용자 제시). 두 가지 이유로 기각: (1) `process`와
    retractor 호출이 **1:1이 아님** — 전체 철거(`retractFrom(inst,k,1,nil)`)
    처럼 뒤따르는 `process`가 아예 없는 경로가 정상적으로 존재해서, 그
    경우엔 애초에 내려보낼 "새 값"이 없음(사용자 스스로 지적한 한계).
    (2) 더 근본적으로, 값을 한 겹 풀려면 teardown 도중에
    `innerState:Get()`을 **투기적으로** 호출해야 하는데 — State는
    pull-recompute 계약(`base/store-semantics.md`)이라 이 호출이 실제
    재계산을 유발할 수 있고, 곧이어 `process`가 다시 `:Get()`을 부르면
    같은 사이클에 이중 계산이 됨. 또 그렇게 얻은 값은 어디까지나 추정이라
    실제 `process` 시점의 값과 다를 수 있음("값 비교/캐싱 금지" 원칙과
    같은 결). **대신 채택할 방향은 값 층에서의 평탄화**(`State<State<T>>`
    → `State<T>` 콤비네이터, `research/operator-sugar-plan.md` 백로그) —
    체인을 한 겹으로 유지하면 위 첫 번째 항목의 보장이 그대로 적용되므로
    Dispatch 층에 특수 배관을 넣을 이유가 없어짐.
- **순환은 UB, 방어 로직 없음** — Handler 간 순환 참조(A가 B를 부르고
  B가 다시 A로 돌아오는 것, 또는 값 자체가 결국 자기 자신을 가리켜
  무한히 깊어지는 인덱스)는 재귀 호출이 안 끝나 바로 스택오버플로가
  나므로 애초에 일어날 수 없는 구조 — 값에 별도 플래그를 심어 의도적으로
  순환을 만드는 것도 이론상 가능하지만 use case가 없어 문서화 대상 밖,
  2026-08-04 세션에 이미 확정된 "일반적 무한루프 방어 안 함" 원칙과
  같은 결로 UB 취급.
- **`State<State<T>>`는 더 이상 UB가 아님 — 정상 지원 대상으로 재정정
  (2026-08-13 다섯 번째 세션).** 원래(같은 날 두 번째 세션) `store.key
  = a`(State), `a:Get() = b`(State)일 때 같은 `StoreBind` 싱글톤이 같은
  `(inst,k)`에 identity로 두 번 매치돼 `retractUnder`의 cutoff 계산이
  안쪽 자신을 잘못 retract하는 실제 버그(체인 파손, 구독이 등록 직후
  스스로 끊김)로 재현돼 "같은 (inst,k)에 같은 핸들러 객체가 이미 있으면
  즉시 error" 가드로 막았었음(당시 고정, `archive/
  checkpoint-handler-pattern-reversed.md`가 인용하는 옛 코드 참고). 이
  버그의 근본 원인은 "핸들러당 최대 한 번씩만 그 키에서 호출됨"을
  객체 identity로 강제하려 한 것 — 인덱스 기반으로 바꾸면 `a`를 처리하는
  StoreBind는 인덱스 N, `a:Get()`(=`b`)을 처리하는(같은 싱글톤이지만)
  StoreBind는 인덱스 N+1을 써서 **애초에 슬롯이 안 겹침** — 같은 핸들러
  객체가 같은 키에서 여러 번 매치되는 것 자체가 문제가 아니게 됨.
  임의 깊이의 `State<State<State<...>>>`도 그냥 인덱스가 계속 늘어날
  뿐 정상 동작 — 유일하게 남는 UB는 위 "순환" 항목(값이 결국 순환 참조를
  이뤄 무한히 깊어지는 경우)뿐.
- **부수 효과 — 미래 재바인드/quad-debug에 유리**: 이 체인이 Dispatch에
  중앙화돼 있으므로, `research/existing-instance-bind-plan.md`가 다룰
  미래의 재바인드는 `Dispatch.retractFrom(inst, k, 1, newV);
  Dispatch.process(inst, k, newV, 1)` 두 줄로 "이 키의 체인을 통째로 갈아
  끼우기"가 자연스럽게 됨. `research/debug-tooling-plan.md`의 "무엇이
  무엇에 연결됐는가" 그래프도 이 `chains` 구조를 그대로 읽으면 됨 —
  quad-debug 착수 시점에 새로 설계할 필요 없음.

### Handler 작성 체크리스트 — 새 모델에서 실제로 반복된 실수들 (2026-08-13 여섯 번째 세션 신설)

**왜 이 절이 있는가**: 인덱스 기반 재설계 직후 작성된 의사코드
(`Dispatch` 자신, `Ref`, `Tag`, `Slot`, `Attribute`)에서 **같은 세션
안에 버그 4건**이 나왔고, 그중 셋이 서로 다른 문서에 있으면서도
**같은 종류의 착각**에서 나왔음. 새 Handler를 짜거나 기존 걸 고칠 때
이 목록을 먼저 훑을 것 — 전부 "그럴듯해 보이는데 틀린" 것들이라
리뷰로 잡기 어렵다.

**1. 클로저는 early-return해도 체인에서 *소비*된다.**
`Dispatch.retractFrom`은 저장된 retractor를 호출하고 **항상**
`list[i] = nil`로 지움 — 그 클로저가 `hintValue == v`로 아무 일도 안 하고
돌아왔더라도 마찬가지. 그러므로:
- **매 `process` 호출은 "이 자리를 무르는 책임"을 온전히 새로 짊어진
  클로저를 반환해야 한다.** "이번엔 내가 실제로 한 일이 없으니 no-op을
  돌려주자"는 거의 항상 버그 — 다음 사이클에 진짜 교체가 올 때 정리할
  주체가 사라짐. (`SlotHandler`에서 실제로 이 함정에 빠졌었음.)
- 반대로 "아무 일도 안 했으니 무를 것도 없다"가 **진짜로** 맞으려면,
  그 자리가 무를 자원을 애초에 아무도 안 갖고 있어야 함(일반
  PropertyHandler처럼).

**2. `process`가 재귀 위임 전에 `retractFrom`을 부르는 건 *같은 키에
자기 아래*일 때만이다.**
`StoreBind`가 `retractFrom(inst,k,index+1,realv)`를 부르는 건 자기가
직전 사이클에 만든 하위 체인을 자기가 치우는 것 — 정당함. 반면 **다른
키로 위임하면서 그 키의 인덱스 1을 미리 `retractFrom`으로 비우는 것은
거의 항상 버그**: 그 자리를 누가 점유했든 지워버리므로
`Dispatch.process`의 점유 체크(= 소유권 충돌 감지)가 통째로 무력화됨.
`AttributeGroupHandler`가 정확히 이걸로 그룹↔그룹 충돌을 조용히
넘기고 있었음. **다른 키의 정리는 그 키를 등록했던 클로저가 한다.**

**3. `hintValue`는 `nil`이 아니고, 타입도 보장 안 되고, 깊은 인덱스엔
안 온다.** 셋 다 별개의 함정:
- `nil`이라고 가정하고 `assert(v == nil)`을 쓰면 안 됨(이미 한 번 전면
  정정된 이력, `archive/retract-always-fires-reversed.md`).
- 내용(메소드/필드)을 보려면 `isTag(hintValue)` 같은 가드부터 —
  그 자리 핸들러 *타입*이 바뀌는 경우 엉뚱한 값이 옴.
- 깊이 2 이상에는 `nil`이 옴(위 "`hintValue`는 직속 위임 1단계에만
  보장됨" 항목) — 힌트가 있으면 최적화, 없으면 정직하게 전부 정리하는
  코드여야 함. 힌트를 **정확성**의 근거로 삼으면 안 됨.

**4. "이전 값"을 알고 싶으면 클로저 캡처, "여러 위치/사이클을 가로지르는
누적 상태"만 `Relate`.** 이 경계를 헷갈리면 양방향으로 틀림:
- 불필요한 `Relate`: `process`가 만든 걸 그 클로저가 정리하는 단발성
  handoff는 upvalue 캡처로 끝(옛 `kSlotMap`/`kTagMap`이 이걸로 삭제됨).
- 부족한 `Relate`: `Tag`의 `tagNameMap`(여러 위치가 한 이름을 공유),
  `Ref`의 spurious 재바인딩 dedup처럼 **자기 클로저 수명 밖의 정보**는
  캡처로 대체 불가.
- 그리고 `Relate`에 쓴 걸 클로저에서 지울 땐 **"내가 실제로 물러날
  때만"** 지울 것 — 조건 밖에서 무조건 지우면 dedup이 무력화됨
  (`RefLeafHandler`가 정확히 이 버그였음).

**5. `Dispatch`를 통해서만 진입한다.**
`handler.process(...)`를 직접 부르면 점유 체크와 `chains` 기록이 통째로
빠져 나중에 정리가 안 되거나 정합성이 깨짐(위 "Dispatch 체인" 절).
마찬가지로 클로저 안에서는 `Dispatch.process` 금지, **같은 키**에 대한
`Dispatch.retractFrom`도 금지(진행 중인 루프가 `#list`를 이미 캡처).

**6. 인덱스는 "같은 키 안의 재귀 깊이"다.**
같은 키로 재귀하면 `index + 1`, **다른 키로 위임하면 그 키에서 다시
`1`부터**, `Dispatch.drive`의 최초 진입도 `1`. 배열 파트의 위치(`k`)와
이 `index`는 완전히 다른 것 — `AttributeGroupHandler`가 배열 위치를
`index`라고 이름 붙였다가 시그니처 자체가 계약과 어긋난 전례가 있음.

**7. 반환 생략 금지.** 정리할 게 없어도 `function() end`. `nil`을
반환하면 `list[index]`에 **구멍이 뚫려** `#list`가 정의되지 않게 되고
(순회 시작점이 어긋남) 그 자리가 비어 보여 **점유 체크까지 조용히
통과** — 즉 소유권 충돌 감지가 꺼짐. **[정정, 2026-08-13 7차 감사]**
예전엔 이 항목이 "`attempt to call a nil value`로 크래시"라고 적혀
있었으나 `retractFrom`이 `if retractor then`으로 넘기고 있어 크래시조차
안 나는 게 실제였음 — 지금은 `retractFrom`이 즉시 error를 냄(위
"Dispatch 체인" 절 의사코드).

### Length/Offset — 여러 Slot이 형제로 섞일 때 순서 보장 (2026-08-09 여섯 번째 세션)

**문제(`base/slot-plan.md`의 "여러 Slot이 섞일 때 순서 보장" 열린 질문,
2026-08-04 신설)**: `Frame { Slot1, Element, Slot2 }`처럼 Slot과 정적
자식이 형제로 섞일 때, Slot1의 동적 개수가 바뀌어도 "Slot1 전체는 항상
Element보다 앞, Slot2보다 앞"이라는 저작 순서가 유지돼야 함. Slot2가
자기 순서를 정하려고 "Slot1이 지금 몇 개인지"를 직접 세는 방식은
Slot1이 바뀔 때마다 Slot2에 다시 알려줘야 하는 캐스케이드 의존을
만들어서 막다른 길.

**해법의 핵심 전환**: 절대 위치를 계산해서 전파하는 게 아니라, **각
구조적 위치(자리 자체는 저작 시점에 고정)가 자기 앞의 형제들이 지금까지
기여한 개수의 누적합만 알면 됨** — Roblox는 `LayoutOrder`/`ZIndex`가
`Instance.Parent` 배열의 물리적 순서와 완전히 분리된 정수 프로퍼티라,
이 누적합을 그 프로퍼티에 반응형으로 바인딩하기만 하면 별도 배선이
필요 없음(이미 있는 store-bind 재실행 패턴 재사용).

**`Dispatch`의 두 API — 둘 다 Handler→Dispatch 등록(push) 방향**:

```lua
Dispatch.setLength(inst, i, len: number | State<number>)
Dispatch.setOffsetSource(inst, i, offset: Source<number> | None)
```

**[2026-08-11 세션] 첫 인자(`inst`)는 물리 Instance일 필요가 없음 —
`Relate`가 weak table 기반이라 아무 테이블이나 키로 가능.** 이 사실을
재사용해 **Slot 자신을 owner 키로 써서 같은 두 함수를 한 번 더
부르면, 최상위(Dispatch.drive의 리터럴 배열)와 중첩(Slot이 자기
자신의 요소들에 대해)이 완전히 같은 메커니즘으로 재귀됨** — 새 함수를
만들 필요 없음. 상세 재귀 흐름(Slot-in-Slot)은 `base/slot-plan.md`의
"Slot-in-Slot 중첩" 절 참고, 이 문서는 그 절이 재사용하는 `recompute`
자체만 다룸(아래).

- **`setLength`**: 이 위치(array part의 number 인덱스 `i`)가 지금 몇 개의
  실제 마운트 가능한 leaf를 기여하는지 보고. 정적 단일 자식은 상수
  `1`(또는 `nil`/`None`이면 `0`), Slot은 자기 `.Length`(`State<number>`,
  아래 참고), `state<Frame>`처럼 store-bind로 오가는 단일 위치는 그
  store-bind 핸들러가 값이 바뀔 때마다 다시 호출. **호출 책임은 `Slot`
  자신의 `:List`/CRUD가 아니라 그 위치를 처음 매치한 Handler(`Dispatch/
  Slot.luau`)** — `Slot`은 `inst`/`i`를 모르는 독립 값(어디 마운트될지
  자기가 결정 안 함)이라, `process(inst, i, slotValue)`가 매치되는
  시점에 그 Handler가 `Dispatch.setLength(inst, i, slotValue.Length)`를
  1회 호출(길이 자체가 바뀌는 매 순간은 이미 `slotValue.Length`가
  `State`라 알아서 전파됨, Handler가 매번 다시 부를 필요 없음). `state<Slot>`
  교체 시엔 이 Handler가 새 값으로 다시 `setLength`를 호출.
- **`setOffsetSource`**: 이 위치가 자기 순서 계산에 쓸 `Source<number>`를
  **스스로 만들어서** 등록 — Dispatch는 그냥 레지스트리에 넣어두기만
  하고, `recompute`가 그 자리에 값을 `:Set()`함. Slot이 매치되는 경우
  이 Source는 그 자리에서 `Slot.Offset` 필드로도 그대로 저장됨(아래
  참고) — 순수 숫자 누적합 계산이라 엔진 지식이 전혀 필요 없어서, 이
  등록 자체는 `quad-base`(`Dispatch/Slot.luau`)가 함. **[정정,
  2026-08-11 세션] 예전엔 이 Source를 "Handler가 자기 원소(들)의
  `LayoutOrder` 바인딩에 그대로 쓴다"고 서술했었는데 — 폐기.** Slot이
  마운트한 원소에 `LayoutOrder`를 자동으로 덮어쓰면 (a) 사용자가 그
  원소 자신의 프로퍼티로 `LayoutOrder`를 이미 지정해도 조용히 씹히는
  매직이 되고, (b) `LayoutOrder`는 애초에 Roblox 전용 프로퍼티라 그
  지식이 `Dispatch/Slot.luau`(엔진 무관) 층위로 새는 레이어링 위반이기도
  함. 이제 `Offset`은 `Slot.Offset`으로 공개 노출만 되고, 각 원소의
  `LayoutOrder`(또는 웹의 CSS `order`)를 실제로 계산해 세팅하는 건
  `updateFn`(또는 수동 Slot 사용자)의 몫 — `updateFn`은 `index`를 raw
  number로만 받고(`Slot.Length`/`item`과 같은 원칙, `:List`가 반응형을
  강제하지 않음), 반응형이 필요하면 자기 `userdata` 안에 직접 `Source`를
  만들어 `Frame { LayoutOrder = layoutOrder:With(offset):Compute(fn) }`처럼
  써넣으면 됨 — 새 메커니즘 불필요. 상세는 `base/slot-plan.md`의
  `Slot:List` 절 참고. **실제 마운트를 하지 않는 위치는 `None`을 등록** — 순서 계산에
  참여할 게 없다는 명시적 선언. 대상은 Ref/PreRef뿐 아니라 **그 배열
  위치의 값 자체가 `None`인 모든 경우**(예: `props.Ref or None` 관용구로
  캐우칭된 미전달 Ref, PreRef pre-pass가 소진시킨 슬롯 등) — `setLength`도
  같은 위치엔 짝을 맞춰 `0`으로 등록해야 함(위 `setLength` 항목의
  "`nil`/`None`이면 `0`" 규칙과 항상 같이 감, 둘 중 하나만 반영되면
  길이 합계와 실제 순서 계산이 어긋남).

**해제(그 자리가 더 이상 기여하지 않게 될 때)는 `setOffsetSource(...,None)`
→ `setLength(...,0)` 순서로 (2026-08-13 여섯 번째 세션, 사용자 지적).**
별도 unregister API는 없고 `0`/`None` 재등록이 곧 해제인데, **순서가
반대면 위험함**: `setLength`가 끝에서 `recompute`를 돌리므로, 먼저
부르면 그 `recompute`가 아직 남아있는 옛 `Source`(지금 막 떼어내는
서브트리의 것)에 `:Set()`을 날려 죽는 중인 다운스트림을 헛되이
캐스케이드시킴. `setOffsetSource(None)`을 먼저 하면 아래 `recompute`의
`offset ~= None` 가드에 바로 걸려 그 Source를 아예 안 건드림. 값이
틀려지는 문제는 아니지만(자기 length가 줄어도 자기 offset은 그대로라
갱신될 일 자체가 없음) **invalid한 Source가 순회 대상에 남아있는 것
자체가 위험**하므로 순서를 계약으로 고정. 상세·부수 방어 조치는
`base/slot-plan.md`의 "구현상 바뀌어야 하는 것" 절 참고.

**둘 다 array part의 모든 number 인덱스에 대해 반드시 호출 — 생략은 UB
(2026-08-09 여섯 번째 세션 확정).** `retract` 필드 생략 불가와 같은 톤 —
이건 **Handler 구현체 작성자만 지키는 계약**이고 일반 컴포넌트 작성자는
이 존재 자체를 몰라도 됨(사용성 저하 없음), API 문서화만 명확히 하면 됨.

**저장 위치**: `lengthList`/`sourceList`(부모 `inst` 하나에 귀속, 그
`inst`의 array part 크기 `N` — `bk.N`으로 같이 저장, `Dispatch.drive`가
최초 배열 파트 순회 시점에 이미 알고 있는 값) — `Relate(parentInst)`에
lazy 생성.

**`sourceList`에도 `nil`이 아니라 `None`을 쓰는 이유는 기존 배열 파트
원칙 재사용** — 모든 number 인덱스를 반드시 채워야 하는데(위 UB 규칙)
`nil`을 넣으면 (1) 그 자리가 "안 채워짐"과 구별이 안 되고 (2) 배열이
구멍 나면서 순수 array 취급이 깨져 접근 비용이 올라감(해시 파트로 밀림)
— `None`은 실재하는 값이라 자리를 "채워짐"으로 유지시켜줌, PreRef
pre-pass 소진 슬롯에 이미 적용된 것과 같은 원칙(`ref-plan.md`의 "PreRef" 절의
"왜 `None`이 아니라 `nil`인가" 참고 — **단, 그 절에서 최종적으로 `nil`로
되돌아간 건 Ref 콜백/대기자 배열 한정**이고 `sourceList`/PreRef
pre-pass처럼 순서가 실제로 중요하거나 "채워짐 여부"를 엄밀히 구별해야
하는 배열은 여전히 `None`이 맞음, 헷갈리지 말 것). 다만 `recompute`가
`1..N` 고정 범위를 도는 인덱스 `for`라 애초에 성긴 정수 키 순회 문제
자체는 안 생김 — `None`이 필요한 이유는 순회 순서 보존이 아니라 "채워짐
여부 구별과 접근 비용" 쪽.

**recompute — 매번 전체 순회, `Get` 가드로 캐스케이드만 방지**:

**[정정, 2026-08-11 세션] `sum` 누적과 `offset:Set` 순서가 뒤바뀌어
있던 off-by-one 버그.** 원래 코드는 `sum += lengthList[i]`를 먼저 한
뒤 `offset:Set(sum)`을 해서, `offset[i]`가 "자기 앞의 형제들이 기여한
개수"가 아니라 **자기 자신을 포함한** 누적합이 되고 있었음 — 예를
들어 `Frame{Slot1}` 하나뿐이어도(앞에 아무것도 없는데) `Slot1.Offset`이
`Slot1.Length`가 되어버려 `index+offset` 공식이 어긋남. 순서를
뒤집어(offset 먼저 Set, 그 다음에 자기 기여도를 sum에 누적) 수정 —
지금까지 실제 Luau로 돌려본 적이 없어 아무도 못 잡았던, Length/Offset
메커니즘 자체의 버그(오늘 논의한 중첩 기능과는 별개).

**[검토했다가 기각, 2026-08-11 세션] 재진입 방지 가드 — 불필요함이
재추적으로 확인됨.** 처음엔 recompute 도중 재귀 호출이 들어오는 경우를
대비해 `_recomputing`/`_dirty` 플래그로 방어하는 안을 검토했으나, 실제
호출 경로를 다시 추적한 결과 **각 Slot이 `Relate(자기 자신)`으로 독립된
`bk`를 갖기 때문에, 중첩된 Slot의 Length 변경이 상위로 전파되는 경로는
항상 서로 다른 `bk`를 거쳐 지나감** — 부모의 `recompute(parent, parentBk)`가
자식의 `bk`를 건드리지 않고, 자식의 `recompute(child, childBk)`도 부모의
`bk`를 안 건드림. 즉 **nesting이 있다는 사실만으로는 같은 `(ownerKey,bk)`가
재진입되는 경로 자체가 없음** — "중첩 Slot이 있으면 항상 dirty가 켜진다"는
초기 우려는 틀렸고, 가드 자체가 불필요한 걸로 확인됨. 진짜 재진입은
`updateFn` 같은 부작용이 recompute 도중 **같은** Slot에 다시 `Add`/`Remove`를
거는 것처럼 순수하게 사용자 코드가 만드는 경우뿐인데, 이건 이미 확정된
"일반적인 재진입/무한루프는 방어 안 함, provider/사용자 코드 버그로
간주"(2026-08-04) 원칙 그대로 두면 됨 — 별도 가드를 만들 근거가 없음.
**결론: `recompute`는 off-by-one만 고친 순수 버전으로 유지, 재진입
가드 없음.**

**이 케이스를 명시적으로 UB로 명명(2026-08-11 세션, 사용자 제안)** —
`Source<T>`가 `State<T>`를 "단방향"으로만 만족한다는 이미 확정된 원칙
(`base/store-semantics.md` "Source가 State를 만족함" 절 — 파생값이
자기 upstream Source로 거꾸로 쓰기를 하지 않는다는 것)과 **같은 카테고리의
위반**이라는 게 근거: `recompute`가 만드는 `offset`/`Length`는 전부
`lengthList`(그 Slot의 upstream 입력)에서 파생된 다운스트림 값인데,
계산 도중 촉발된 부작용이 **자기 자신의 `lengthList` 입력을 다시
mutate**하는 게 바로 그 반대 방향 쓰기. "State가 자기 Source에 `Set`을
가하는 것"이 UB인 것과 동일한 이유로, "recompute 도중 발생한 부작용이
같은 Slot의 length에 다시 쓰기를 가하는 것"도 UB로 문서화 — 새 원칙이
아니라 이미 있는 단방향 흐름 원칙을 recompute라는 구체 지점에 적용한
것뿐, 그래서 별도 방어 로직도 필요 없음.

```lua
local function recompute(ownerKey, bk)
    local sum = 0
    for i = 1, bk.N do
        local offset = bk.sourceList[i]
        -- offset은 실제 Source이거나 None(참여 안 함) — None은 truthy라
        -- `if offset then`만으로는 안 걸러짐, 명시적으로 배제해야 함.
        -- [방어, 2026-08-13 여섯 번째 세션] `nil`도 같이 배제 — 정상
        -- 상태에선 항상 None으로 채워지는 게 계약이지만(위 "None을 쓰는
        -- 이유"), 해제/재마운트가 얽히는 전이 구간에서 `nil`이 관측돼도
        -- 크래시 대신 skip이어야 함. 등록 쪽의 "반드시 None" 의무는 그대로.
        if offset ~= nil and offset ~= None and offset:Get() ~= sum then   -- 실제로 다를 때만 Set
            offset:Set(sum)
        end
        local v = bk.lengthList[i]
        sum += (if isState(v) then v:Get() else v)
    end
    if isSlot(ownerKey) and ownerKey.Length:Get() ~= sum then
        ownerKey.Length:Set(sum)   -- ownerKey가 물리 inst가 아니라 Slot 자신인 재귀 케이스
    end                            -- (`base/slot-plan.md`의 "Slot-in-Slot 중첩" 절)
end
```

**`offset`/`sum`은 0-based *개수*이지 Lua 배열 인덱스가 아님(2026-08-11
세션 명시화).** Luau/Lua 배열은 1-based 관례지만, 여기서 계산하는
`offset[i]`는 "그 앞에 몇 개가 있는가"라는 순수 카디널 수라 자연스럽게
0에서 시작함 — `updateFn`의 `index`(로컬 위치, 1-based Lua 관례)와
`index + offset` 공식으로 섞이는 게 의도된 것이지 인덱싱 불일치가
아님. `LayoutOrder` 자체도 0/음수가 허용되는 값이라 최종 결과에도
문제 없음 — 구현/문서화 시 "이 두 숫자는 서로 다른 기준(1-based 위치
vs 0-based 개수)"이라는 걸 명시적으로 적어둘 것.

전체 순회의 O(N) 비용은 무시 가능(`N`은 저작 시점에 고정된 배열 리터럴
길이, 보통 작음) — 진짜 비싼 건 `Set`이 트리거하는 다운스트림 리액티브
캐스케이드(그 위치에 이미 마운트된 원소들의 `LayoutOrder` 재적용)라,
`Get() ~= sum`일 때만 `Set`해서 안 바뀐 앞쪽 위치들은 캐스케이드가 안
일어나게 막음.

**`setLength` 구현 — leaf-lifetime 경로(`bindLifetime`/`unbindLifetime`),
`:Subscribe()` 아님(2026-08-09 여섯 번째 세션)**:

```lua
function Dispatch.setLength(inst, i, len)
    local bk = getBookkeeping(inst)   -- Relate(inst) 기반, lazy 생성

    local oldObserver = bk.observers[i]
    if oldObserver then
        unbindLifetime(inst, oldObserver)   -- gchold 내부 구조 몰라도 됨
        bk.observers[i] = nil
    end

    bk.lengthList[i] = len

    if isState(len) then
        local observer = len:Observer(function()
            recompute(inst, bk)
        end)
        bindLifetime(inst, observer)   -- inst 생명주기에 귀속, Subscribe 아님
        bk.observers[i] = observer
    end

    recompute(inst, bk)   -- 등록 즉시 1회(Observer 자체의 "등록 즉시 1회 실행"과 겹쳐도 무해)
end
```

`:Subscribe()`/`:Unsubscribe()`(독립 경로)를 안 쓰는 이유: 이 Observer는
본질적으로 `inst` 하나에 종속된 내부 배관이라, `inst`가 Destroy될 때
같이 죽어야 함 — `:Subscribe()`는 명시적 `:Unsubscribe()`가 없으면 안
끊기므로 안 맞음. `bindLifetime`/`unbindLifetime`이 이미 이 요구(GC-native,
`inst` 생명주기에 자동 귀속)를 충족.

**동기 순서 — offset 갱신이 마운트보다 먼저 끝나야 함(안 그러면 Roblox의
실시간 `UIListLayout` reflow에서 한 프레임 순서가 깨진 채 노출될 위험)**:
Slot의 `rawAdd`는 `self.Length:Set(newCount)`(→ 다운스트림 offset/LayoutOrder
갱신이 동기적으로 여기서 끝남) 다음에 `element.Parent = target`(→ 이제
트리에 보이는 시점엔 다운스트림이 이미 정합적) 순서로 호출. `Length:Set`
자체도 이전 카운트와 실제로 다를 때만 호출(no-op 캐스케이드 방지, 위
`Get` 가드와 같은 원칙을 호출부에서도 적용).

**`:List` reconcile에서 `Length` 갱신 시점**: 한 사이클(여러 항목이
한꺼번에 추가/제거되는 경우 포함) 전체가 끝난 뒤 **한 번만** — 사이클
도중 항목마다 갱신하면 캐스케이드가 그만큼 반복됨.

**웹 백엔드(quad-web, 아직 없음) — 같은 `lengthList`/`sourceList`/
`recompute`를 그대로 재사용, 다른 건 "offset 변경 시 무엇을 하는가"뿐**:
DOM의 `insertBefore`류는 물리적으로 삽입하면 뒤 형제가 자연히 밀려나므로,
`offset`이 바뀌었다고 이미 마운트된 원소를 실제로 옮길 필요가 없음 —
quad-web의 해당 Handler는 offset 변경 관측 시 아무것도 안 하는 no-op이고,
`offset` 숫자는 그 위치가 **다음에** 스스로 insert/remove할 때 어느
물리 인덱스에서 해야 하는지를 위해서만 부기됨. base 레벨 로직은 완전히
동일, backend Handler의 "무엇을 하는가"만 다름.

**`Slot.Length`와 `Slot.Offset`은 별개(사용자 질문으로 명시화)**:
`Length`는 Slot이 스스로 노출하는 순수 출력값(지금 실제로 마운트된
개수) — "n개 검색됨" 같은 UI에 그대로 써도 되고, 동시에 위 `setLength`가
읽는 바로 그 값(하나의 State가 두 용도를 겸함). `:List`가 filter 탈락을
실제 `Remove`로 처리하도록 이미 확정해둔 덕에(Visible 토글 아님) `Length`는
자동으로 "실제 마운트된 것"만 반영 — 수동 Visible 토글을 쓰는 경우엔
`Length`가 그걸 못 잡는 게 맞고, 그건 별도 State로 계산해야 하는 사용자
몫. `Offset`은 Dispatch가 `setOffsetSource`로 등록받아 `recompute`가
채워주는 입력값, 순서 계산 전용 — 서로 다른 두 `Source<number>`.

**`Slot.Offset`도 `Slot.Length`와 마찬가지로 공개 필드(2026-08-11
세션 명시화)** — Slot이 마운트되는 시점(`Dispatch/Slot.luau`가
`setOffsetSource`를 등록하는 바로 그 자리)에 같은 Source 객체를
`self.Offset`으로도 저장, 마운트 전엔 `nil`. 위 정정대로 이 값을
`LayoutOrder` 등에 실제로 반영하는 건 Slot 자신이 하지 않으므로,
`:List`의 `updateFn`이 이 값을 받아 쓰거나(아래 `base/slot-plan.md`
참고) 수동 CRUD 사용자가 직접 `slot.Offset`을 읽어 자기 원소 프로퍼티를
구성해야 함 — 아무것도 안 하면 그냥 `LayoutOrder`가 안 바뀔 뿐.

`base/slot-plan.md`의 "여러 Slot이 섞일 때 순서 보장" 절이 이 메커니즘으로
해소됨 — 상세는 그 문서 참고.

**동적 자식 추가/제거의 유일한 정당 경로는 `Slot` 또는 `state<Frame>`류
store-bind — 그 외 방식은 UB로 확정(2026-08-10 세션).** `Length`/`Offset`
카운팅은 그 위치를 담당하는 Handler(`Dispatch/Slot.luau`, store-bind
프로퍼티 핸들러)가 `Dispatch.setLength`/`Dispatch.setOffsetSource`를
호출해줘야만 정합적으로 유지됨 — 이 두 API를 부르지 않고 quad가 관리하는
부모 Instance에 자식을 끼워 넣는 경로(예: 사용자 코드가 `newInst.Parent =
parentInst`를 직접 호출해 Slot이 마운트해둔 부모 밑에 자식을 몰래
추가/제거하는 것)는 `lengthList`/`sourceList`가 그 변화를 전혀 모르게
만들어 카운트·형제 순서 계산이 조용히 어긋남 — 별도 방어 로직 없는 UB.
`Slot`이든 `state<Frame>`이든 둘 다 이미 이 두 API를 정확히 호출하는
유일한 정당 경로로 확정돼 있음(위 `setLength`/`setOffsetSource` 절
참고) — 새 경로를 만들 필요 없이 "동적 자식은 반드시 이 둘 중 하나를
거쳐야 한다"는 규칙만 문서화하면 됨.

## Store 바인드는 특수 경우인가, 아니면 pluggable 바인드를 재실행하는 래핑인가

사용자 원 메모: "스토어 바인드는 특수 경우로 둘지, 아니면 다른 pluggable 바인드를
재실행하는 래핑으로 쓸지 생각해봐야함... 충분히 확장 가능하게 둘 수 있음."

**확정**: 래핑 쪽. 위 "확정된 디스패치 모델" 절 참고 — store 바인드 핸들러도
다른 핸들러와 동일한 `isHandlable`/`priority`/`process`(반환값 포함) 계약을
따르되, 자신의 `process`가 내부적으로 "실제 값이 바뀔 때마다 (원래 key, 새
value)로 `Dispatch.process(inst,k,realv,index+1)`를 재귀 호출"하는 식으로
구현됨. 이러면 store 값 자체가 대부분의 타입(원시값, 인스턴스 등)에 대해
동일한 재귀적 디스패치로 처리 가능 — 아래 "store가 store를 저장 가능한가"와
직결. **[2026-08-13 세션, 두 차례 정정]** 이 "동일한 재귀적 디스패치로
처리 가능"은 처음엔 값이 또 State/Source면(`State<State<T>>`) 같은
핸들러가 같은 `(inst,k)`에 identity로 두 번 push돼 체인이 파손되는 실제
버그로 낙관적으로 틀린 서술임이 드러났었으나(같은 날 두 번째 세션), 같은
날 다섯 번째 세션에 `chains`를 핸들러 identity가 아니라 재귀 깊이
인덱스로 추적하도록 재설계되며 **다시 맞는 서술로 돌아옴** — `realv`가
또 State면 `index+1`이라는 별개 슬롯을 쓰므로 identity 충돌 자체가 없어짐
(위 "확정된 디스패치 모델"/"Dispatch 체인" 절 참고).

**"값이 바뀔 때마다"의 실제 구독 메커니즘 = `state:Observer(fn)` 재사용으로
확정(2026-08-08 세션).** 이전엔 이 절이 구독 메커니즘 자체를 추상적으로만
서술했는데(새 프리미티브를 발명하는 것처럼 읽힐 수 있었음), 실제로는 아래
"`state:Observer(fn)`" 절에서 이미 확정된 것을 그대로 재사용하면 됨 — 새
구독 primitive를 store-bind 전용으로 따로 만들 이유가 없음:

```lua
-- 예: 일반 프로퍼티 store-bind 핸들러의 process(inst, k, state, index)
function StoreBind.process(inst, k, state, index)
    local observer = state:Observer(function()
        local realv = state:Get()
        Dispatch.retractFrom(inst, k, index + 1, realv)  -- 내 바로 아래부터 정리
        Dispatch.process(inst, k, realv, index + 1)       -- 새로 위임(체인에 push)
    end)
    bindLifetime(inst, observer)
    return function()
        -- 자기 자신의 자원(Observer 구독)만 정리 — observer는 위 클로저가
        -- upvalue로 이미 캡처하고 있어 별도 Relate 저장/조회가 필요 없음
        -- (2026-08-13 다섯 번째 세션, 계약이 클로저 반환으로 바뀌며 단순화됨).
        unbindLifetime(inst, observer)
    end
end
```

**[정정, 2026-08-09 여섯 번째 세션] `:Subscribe()`/`:Unsubscribe()`가
아니라 `bindLifetime`/`unbindLifetime`을 씀 — 원래 이 절이 "leaf가
아니니 `:Subscribe()`가 유일한 선택"이라고 적어뒀던 게 틀림.** `:Subscribe()`/
`:Unsubscribe()`는 **`inst`와 아예 무관한 전역/독립** Observer(모듈
최상위에 두는 디버그 print용 등)를 위한 전역 GC 방지 테이블 전용 —
"leaf가 아니면 `:Subscribe()`"가 아니라 "**`inst`에 안 묶이면**
`:Subscribe()`, `inst`에 묶이면(leaf든 이런 핸들러 내부 배관이든)
`bindLifetime`"이 실제 기준. 이 Observer는 처음부터 `inst`(그리고 그
자식 프로퍼티 `k`)에 묶여있는 존재라 `bindLifetime`이 맞음 — 위 "이중
바인딩 금지" 절의 정정 참고(leaf 부착도 사실 `bindLifetime` 호출이라,
`:Subscribe()`와 상호 배타적인 건 leaf가 아니라 "전역이냐 inst냐"임).

- **반환하는 클로저가 할 일은 `unbindLifetime(inst, observer)` 호출뿐 —
  위임 대상까지 수동으로 안 쫓아가도 됨.** `Dispatch.retractFrom`이 자기
  밑에 위임된 걸 알아서 정리해주므로(위 "Dispatch 체인" 절), 이
  클로저는 정확히 자기 자신의 자원(Observer)만 정리하면 끝 — 이게
  `event-plan.md`의 "이벤트도 store-bind 가능" 절에서 이미 "엔지니어링 비용이 낮다"고
  서술한 것과 같은 이유(새 디스패치 메커니즘 없이 기존 계약만 구현).
  **[2026-08-13 다섯 번째 세션] 별도 `Relate`가 더 이상 필요 없음** —
  `observer`는 `process` 안의 로컬 변수를 반환 클로저가 upvalue로 그대로
  캡처하므로, 예전처럼 `relate:SetStrong(inst,k,observer)`로 저장해뒀다가
  나중에 `relate:GetStrong(inst,k)`로 다시 찾아올 필요가 없어짐(위
  "핸들러 계약"/"핸들러 내부 상태 저장" 절 참고).
- **핸들러가 직접 `canExecute`/liveness를 재구현할 필요 없음** — Observer가
  이미 자기 `Subscribed` 상태로 게이팅됨(아래 `base/lifecycle-pattern.md`의
  `canExecute(inst, value)` 절 참고, Observer/Effect는 그 함수 안에서
  특별 취급됨). `bindLifetime`도 이 `.Subscribed` 필드를 그대로
  세팅/해제하므로(위 "이중 바인딩 금지" 절 참고) 이 게이팅은 그대로 유효.
- Observer가 "등록 즉시 1회 실행"이므로 **최초 적용과 이후 재실행이 같은
  코드 경로로 자동 통일**됨 — 프로퍼티 store-bind 핸들러가 "설치 시 1회
  적용"을 별도로 안 짜도 되는 이유(위 Observer 절의 원래 근거 그대로).

Slot이 store 바인드로 넘어오는 경우, pluggable 처리기에 `retract` 핸들러가
필요하다는 점(부모가 slot을 정리하고 다시 process하는 방식)도 이 래핑 방식과
자연스럽게 맞음 — `base/slot-plan.md` 참고.

## Store가 Store를 저장 가능한가

사용자 원 메모: "슬롯을 스토어처럼 생각 가능하다면 이건 가능하다고 봐야하는가?
아니면 아예 다른 값으로 둬야 하는가? table/number 같은 프리미티브 타입이나
ref 타입처럼 생각하는 게 맞는 거 같음 — 그걸 처리하는 플러그를 만드는 걸로."

**2026-08-04 6차 확정: 그런 경우는 없다고 본다.** 위에 적힌 "재실행 래핑으로
기계적으로는 커버 가능하다"는 제안은 메커니즘상 틀리지 않지만, 실제 설계
의도와 안 맞음 — Store는 Source에 준하는 존재로 모든 반응형 값의 "시작점"
역할만 함. 시작점은 다른 변화하는 무언가에 연결되는 것을 제공하고자 하지
않음(= Store가 다른 Store/State를 값으로 담아 자동으로 따라가게 하는 용도로
쓰지 않음). Store에서 값을 꺼내 State를 옵저빙하다가 콜백으로 다른 Store 값을
바꾸는 식의 수동 연결은 있을 수 있지만, 잘 짜인 UI에서 실사용 사례를 거의
보지 못했다는 게 사용자 판단 — 그래서 이 케이스를 위해 별도로 신경 쓰지 않음.

**[2026-08-13 세션, 스코프 명확화, 같은 날 다섯 번째 세션에 결론 갱신]**
이 절은 "Store *필드*가 Store/State를 담는가"(예: `store.a = otherStore`)
얘기이고, "State가 *emit하는 값*이 State/Source인가"(`State<State<T>>`,
예: `store.key`에 대입된 값 자체가 State)는 다른 축. 이 절의 "별도로
신경 쓰지 않음"(Store 필드 얘기)은 그대로 유지 — 후자(`State<State<T>>`)는
한때 실제 체인 파손 버그로 확인돼 `Dispatch.process`가 명시적으로 error
하도록 막았었으나, 같은 날 다섯 번째 세션에 `chains`의 인덱스 기반
재설계로 그 버그의 근본 원인이 없어져 **지금은 정상 지원 대상**(위
"Dispatch 체인" 절의 `State<State<T>>` 재정정 참고) — "신경 안 씀"의
의미가 "조용히 UB"도 "즉시 실패"도 아니라 "그냥 정상적으로 동작함"으로
다시 한번 바뀜.

## Ref / PreRef — 전용 문서로 분리됨 (2026-08-13 아홉 번째 세션)

`Ref`/`PreRef`(용도 재정의, `.Value`/`:Set`/`:Callback`/`:Wait` API,
`Ref`의 retract, 이중 바인딩 금지, PreRef 호이스팅/1회용 가드)는
**`base/ref-plan.md`로 분리**됨 — 이 문서가 3000줄에 육박해 분할한
1단계. 내용/결정은 안 바뀜.

## 이벤트 바인딩 — 전용 문서로 분리됨 (2026-08-13 아홉 번째 세션)

"이벤트 핸들러는 self(Instance)를 받지 않는다"와 "이벤트도 store-bind
가능 — `false`로 disconnect" 두 절은 **`base/event-plan.md`로 분리**됨
(사용자가 직접 지목한 분할 대상). 내용/결정은 안 바뀜.

단 이벤트 *네이밍* 관례는 인스턴스 생성과 한 절에 섞여 있어 이 문서의
"인스턴스 생성 / 이벤트 네이밍 인체공학" 절에 그대로 있음.

## 여러 Store 값을 묶어 파생값 만들기 — `:With` + `:Compute`, 포지셔널 인자 지양

**사용자 확인 완료, 상세 방향 확정.** 후보로 검토했던 두 방식 모두 기각:

- **암묵적 자동 추적(Vide식 ambient stack)** 기각 — "함수 실행 중과 끝 사이를
  확인하고 부작용이 필요"한 방식이라 Lua에서 깔끔한 방법이 아니라고 판단.
- **명시적 디펜던시 배열 + 포지셔널 인자**(`Store.Combine({a,b}, function(av,bv)
  ...)`)도 기각 — 두 가지 이유: (1) 팩토리 함수로 store-bind 처리기를 쉽게 못
  만들어줌, (2) 여러 팩토리를 체이닝하면 인자 순서가 꼬일 수 있고, 타입 표기도
  어려워짐.

**채택 방향**: `:With(...)`로 필요한 의존성을 모으고, 그 뒤 `:Compute(function()
... end)`에서 **`with`한 값을 포지셔널 인자로 받지 않고 클로저로 직접 읽는다**
(정확히 어떤 방식으로 "직접 읽는지"는 2차 라운드에서 확정 — self/with 값 둘 다
lazy State 핸들로 통일, 아래 "Store/State/Source 온톨로지" 절의 "`:With`/
`:Compute`" 부분 참고).

**`fn`을 커링 스타일로 짜는 것도 권장(2026-08-07 일곱 번째 세션)** —
`key:Compute(makeFormatter("ko-KR"))`처럼 팩토리가 실제 `fn`을 만들어
반환하는 패턴, Observer/Effect의 동일 관용구(아래 "`fn`을 커링 스타일로
짜는 것도 모듈화 관용구로 권장" 절, `base/effect-plan.md`)와 같은 결 —
`:Compute`가 원래부터 이 셋 중 제일 먼저 있던 자리라 뒤늦게 문서화된
것뿐, 새 결정이라기보다 이미 있던 패턴을 명문화한 것.

### 네이밍 — `Compute`가 `-ed`가 아닌 이유 (2026-08-12, `State` 용어 정리 라운드 후속)

`Tag`의 `Added`/`Removed`, `Modifier`의 `Overridden`은 전부 `-ed`(과거분사)
어미를 의도적으로 씀 — `tag-plan.md`가 밝힌 이유는 "`Add`/`Remove`로 쓰면
뮤테이션 API처럼 보이기 때문"(실제로는 항상 clone 후 즉시 확정된 새 값을
반환). **`:Compute`/`:With`는 정반대 이유로 이 관례를 의도적으로 안 따름.**
Tag/Modifier의 클론은 호출 즉시 결과가 확정되는 값이라 "-ed"(이미 끝난
일)가 정확한 묘사지만, `:Compute(fn)`이 만드는 State 노드는 **호출 시점엔
`fn`을 등록만 해둔 것뿐이고 실제 계산은 나중에 `:Get()`이 pull할 때
일어남**(push-invalidate/pull-recompute 모델, 아래 "Store/State/Source
온톨로지" 절) — 즉 호출 시점에 "computed"(이미 계산됨)라고 부르면 거짓.
`State`를 `Computed`로 리네임하는 안이 최종 기각된 것(`question.md` 1번)도
같은 이유의 연장 — Vue `computed()`/Svelte `$derived`가 lazy인데도 그
이름을 쓰는 건 그쪽 생태계에서 문제없지만, quad 자신의 코퍼스 안에서는
"-ed 어미 = 이미 즉시 확정된 값"이라는 관례가 Tag/Modifier로 이미 자리
잡아서, 같은 어미를 lazy한 것에 재사용하면 quad 자기 관례와 충돌해 오히려
더 헷갈림. 그래서 `Compute`(동사 원형, "계산을 등록/설정한다"는 뜻)가
`Computed`보다 quad의 명명 체계 안에서 정확함.

### `:Compute(fn, ...)` — 추가 의존성을 trailing args로 직접 받는 sugar (2026-08-11)

**문제 제기(사용자)**: React의 `useMemo(fn, deps)`처럼 `:With(...)` 없이
`:Compute(fn, a, b, c)`로 바로 추가 의존성을 선언할 수 있으면 더 편하지
않은가 — `self`가 이미 lazy 핸들로 `fn`에 넘어가는 구조라 값 언랩 방식이
아니므로, 예전에 기각된 `Store.Combine({a,b}, function(av,bv)...)`(포지셔널
값 언랩이라 타입 표기가 꼬였던 안)과는 다른 제안.

**확정 — `Compute`엔 채택, `Observer`/`Effect`엔 채택 안 함. 근거는 "새
노드가 실제로 생기는가"의 차이(사용자가 직접 구분).**

- **`:Compute(fn, ...)`는 진짜 공짜 sugar.** `:Compute` 호출은 원래도
  결과를 담을 새 State 노드(자기 자신의 계산 캐시 슬롯)를 만들어야
  하므로, 그 노드가 `self` 말고 `a,b,c`에도 구독(무효화 엣지)을 추가로
  거는 건 **이미 만들어지는 노드에 엣지만 더 얹는 것** — `:With(a,b,c):Compute(fn)`
  체인(노드 2개: pass-through With 노드 + Compute 노드)과 달리 노드가
  안 늘어남(노드 1개). 구현은 `:With(...)`가 이미 하는 "구독 목록 확장"
  로직을 Compute 노드 생성 시점에 그대로 적용하는 것뿐 — 새 메커니즘
  아님.
- **`Effect(fn, ...)`/`state:Observer(fn, ...)`류 trailing-args 확장은
  기각 — 여기선 진짜 새 노드가 생기기 때문.** Effect/Observer는 Compute와
  달리 **자기 자신이 결과를 담는 State 노드가 아님**(파생값을 안 만드는
  순수 leaf 소비자, `base/store-semantics.md`의 "독립 프리미티브 vs
  파생 데이터" 분류에서도 확인되는 차이) — `state`(receiver) 하나만
  구독 가능하므로, 의존성이 둘 이상이면 그걸 하나로 합칠 별도 노드가
  필요하고 그게 바로 `:With(...)`가 만드는 새 노드임. 이건 절대 공짜가
  아니라 **정말 비용이 드는 지점**이라, trailing args로 감춰버리면 "이
  줄이 실제로 새 노드/구독을 만든다"는 걸 코드만 보고 알 수 없게 됨 —
  `:With`가 clone 빌더가 아니라 진짜 노드로 확정됐던 이유(2026-08-07 세
  번째 세션, "코드상의 호출 체인이 그래프 엣지와 1:1로 대응돼야 quad-debug
  그래프가 안 꼬임")와 정확히 같은 원칙. 그래서 다중 의존성 Effect/Observer는
  **`Effect(fn, state:With(a,b,c))`처럼 `:With` 호출을 코드에 그대로
  노출**하도록 유지 — 새 노드가 생기는 지점을 sugar로 숨기지 않는다는
  게 핵심.
- **일반 원칙으로 정리**: "trailing args sugar는 그게 정말 무료일 때만
  붙인다 — 호출부가 이미 만들어야 하는 노드에 엣지만 얹는 경우(Compute)엔
  sugar, 없던 노드를 새로 만들어야 하는 경우(Effect/Observer의 다중
  의존성 병합)엔 sugar 없이 `:With`를 명시적으로 남긴다." `quadnomicon`
  에세이 후보로 좋음(`research/documentation-content-map.md` 6번 항목
  다음에 추가) — "왜 Compute만 여러 deps를 편하게 받고 Effect/Observer는
  안 그런가"가 겉보기엔 비일관적으로 보이지만 실제로는 "숨겨지는 비용이
  있는가"라는 하나의 원칙에서 나온 것이라는 게 소재.

### trailing deps를 `fn`에 lazy positional 인자로도 노출 — 방향+순서(`fn(self, previous?, ...deps)`) 확정, 이형 다중 deps 표현 가능 여부만 실측 필요 (2026-08-11 후속)

> **[2026-08-13 열세 번째 세션, 해소]** 이 절이 얹혀 있던 "self도 lazy
> 핸들로 통일" 계약(구 `question.md` 0-Y)이 **그대로 유지로 확정**됨 —
> 전제가 안 흔들리므로 이 절의 결론도 유효. 다만 이 절이 남겨둔 실측
> 항목(이형 다중 deps를 제네릭 팩으로 표현 가능한지)은 **여전히
> 미검증**임: 그 스파이크(`15`)가 파싱 실패 상태라 재작성이 필요하고,
> 재작성해도 반환 타입 쪽은 `base/typing-limits.md` 1번 한계에 똑같이
> 걸림(명시 주석 바인딩으로 대응).

**문제 제기(사용자)**: `:Compute(fn, a, b, c)`가 이미 `a,b,c`를 trailing
args로 받아 구독을 건다면, 그 값을 `fn(self, a, b, c)`처럼 위치 인자로도
그대로 넘겨줘도 되지 않는가 — `:With`가 값을 포지셔널로 안 주는 이유는
`:With(a):With(b):With(c)`처럼 체인이 여러 호출에 걸쳐 길어지면 최종
합쳐진 노드가 몇 번째 인자로 뭘 받는지 추적하기 복잡해지기 때문인데,
`:Compute(fn, a, b, c)`의 trailing args는 그 호출문 **하나 안에 로컬하게**
다 드러나 있어서 같은 문제가 없다는 지적.

**방향 확정 — 채택.** 지적이 정확함:

- **`:With`가 회피하는 문제 자체가 여기엔 없음.** `:With` 체인의 위험은
  의존성 목록이 여러 호출/여러 스코프에 걸쳐 누적될 수 있어("체인이
  길어지면 순서 지키기가 복잡") 최종 위치 매핑을 코드 한 줄만 보고
  못 읽는다는 것 — `:Compute(fn, a, b, c)`는 그 반대로 한 호출문의
  인자 목록 자체가 곧 최종 순서라 누적/추적 문제가 원천적으로 없음.
- **실질적 이득 — 커링 패턴에서의 중복/드리프트 위험 제거.** 지금
  설계(trailing args는 구독 등록 전용, 값은 closure로 재획득)로
  `:Compute`를 커링 스타일(위 "`fn`을 커링 스타일로 짜는 것도 권장" 절)과
  같이 쓰면 `a, b`를 **두 번** 써야 함 — 한 번은 `makeComputer(f, a, b)`의
  클로저 캡처용, 한 번은 `:Compute(fn, a, b)`의 trailing args(구독
  등록용). 리팩터링 중 한쪽만 바뀌면 "구독은 `a`에 걸려있는데 실제로
  읽는 값은 `a'`"인 조용한 버그가 생길 수 있음. 값을 `fn`의 위치
  인자로 노출하면 `makeComputer(f)`가 `a,b`를 아예 몰라도 되고
  (`function(self, a, b) return f(self:Get(), a:Get(), b:Get()) end`),
  `:Compute`의 trailing args 목록 하나가 "무엇을 구독하는가"와 "`fn`이
  몇 번째 인자로 뭘 받는가" 둘 다의 유일한 소스가 됨 — 중복 자체가 사라짐.
- **`self`가 이미 raw 값이 아니라 lazy 핸들로 넘어가는 원칙을 trailing
  deps에도 그대로 적용** — `fn(self: State<T>, dep1: State<U1>, dep2:
  State<U2>, ...)`, 각 `depN:Get()`을 실제로 호출할 때만 그 값의 계산이
  트리거됨. self에 대해 이미 확정된 "조건부로 특정 값을 아예 안 읽고
  건너뛸 수 있음"이라는 이점이 trailing deps에도 똑같이 적용됨.

**`previous`(아래 절, 2026-08-06)와의 위치 충돌 — 사용자 정정으로 확정,
`fn(self, previous?, ...deps)`.** 처음엔 "`previous`를 dep 개수와 무관하게
항상 마지막 인자로 고정"(`fn(self, dep1, ..., depN, previous?)`)을
제안했으나 **틀림 — 사용자가 정정**: Luau 값 레벨 `...`(vararg)가
파라미터 리스트 맨 끝에만 올 수 있는 것과 똑같이, 타입 레벨 제네릭 팩
(`...U`)도 함수 타입 시그니처에서 **항상 맨 끝**이어야 함(팩이 나머지
자리를 전부 채우는 개념이라 그 뒤에 고정 타입이 하나 더 오는 건 Luau
타입 문법 자체가 원천적으로 허용 안 할 가능성이 매우 높음 — 이건 "안
될 수도 있는 불확실성"이 아니라 "거의 확실히 안 되는 문법 제약"에 가까움).
반대로 **`previous`를 `self` 바로 다음, deps 팩 앞에 두면**(`fn(self,
previous?, dep1, dep2, ..., depN)`) 고정 인자 다음에 팩이 오는 정상적인
모양이 되어 이 제약과 안 부딪힘 — **이게 유일하게 구조적으로 안전한
순서라 이걸로 확정**. `N=0`이면 기존 `fn(self, previous?)`로 그대로
축약되므로 하위 호환도 유지됨. **트레이드오프**: `previous`를 안 쓰고
deps만 받고 싶어도 `previous`가 2번째 자리를 차지하므로, 그 경우 호출부는
`function(self, _, dep1, dep2) ... end`처럼 안 쓰는 자리를 이름으로라도
비워둬야 함 — deps만 쓰는 흔한 케이스가 약간 불편해지지만, Luau 문법
제약상 다른 선택지가 없음(대안은 애초에 이 확장 자체를 안 하는 것뿐).

**실측 필요 — `luau-test`의 `15-type-compute-trailing-deps-typepack.luau`
신규(ROADMAP.md M3 반영).** 순서 문제 자체는 위 정정으로 구조적으로
풀렸으므로, 스파이크가 실제로 확인할 진짜 불확실성은 (B) 하나로 좁혀짐 —
나머지는 그 결론을 뒷받침하는 대조군: (A) 균일 타입 dep 1개를 고정
인자로 좁히는 대조군(실패하면 B/C/D를 볼 것도 없이 기반 자체가 문제),
(B) 이형(heterogeneous) 타입 dep 여러 개를 제네릭 팩 하나로 정확히
좁혀 받을 수 있는지(안 되면 위치 인자 노출 자체를 동종 타입 dep 1개로
한정), (C) 처음 제안했던(틀린) "팩 뒤에 `previous?`" 순서가 실제로
막히는지 보여주는 음성 대조군(막혀야 정상), (D) 정정된 "`previous?` 뒤에
팩" 순서가 통과하는지 보여주는 양성 대조군(통과해야 정상 — 예상과
다르게 C가 통과하거나 D가 막히면 이 순서 결정 자체를 재검토).

### `:Compute(fn)`의 선택적 두 번째 인자 — `previous` (무거운 파생 객체 재사용, 2026-08-06)

**배경**: `:Compute`의 결과가 그 자체로 무겁고 재생성 비용이 큰 엔진
객체일 수 있음(예: 큰 로케일 테이블을 Roblox `LocalizationTable`
Instance로 변환하는 경우 — `LocalizationTable`은 `Set`/`Get`/`List`로
부분 갱신 가능한 userdata). 매번 새로 만들지 않고 이전 결과를 그대로
재사용해 필드만 patch하고 싶을 때를 위해, `fn(value, previous)` 형태로
**직전에 이 Compute 함수가 반환했던 값**을 두 번째 인자로 받을 수 있게
한다.

- **opt-in**: 안 쓰는 Compute 함수는 두 번째 인자를 그냥 무시하면 됨 —
  비용 0. 대부분의 Compute는 이걸 쓸 필요 없음.
- **`previous`는 "바로 직전 버전"이 보장되지 않음.** lazy pull 모델이라
  중간에 여러 번 무효화됐어도 실제로 관측(`Get()`) 안 됐으면 재계산
  자체가 안 일어남 — 그래서 `previous`는 몇 세대 전 값인지 알 수 없음.
  **따라서 `previous`를 다루는 로직은 반드시 "현재 입력 전체 대 이전
  결과 전체"의 full diff여야 하고, "정확히 한 단계 전"이라고 가정하는
  incremental delta 로직을 짜면 안 됨.** 이건 React 자체의 reconciler가
  하는 것과 같은 모양(old tree/new tree 전체 비교 후 실제 host 객체에
  패치 적용)이라 새로 발명하는 패턴은 아님.
- 최종 소비처가 patch된 값을 다시 한번 Set/Parent하게 되는 경우가
  있어도(레퍼런스는 같은데 다시 대입) 대체로 치명적이지 않음(Roblox
  프로퍼티 재대입은 저렴/멱등인 경우가 대부분) — 문서화만 해두면 충분.

**⚠️ 이 패턴을 쓸 때 반드시 같이 지켜야 하는 것 — "확정(관측)되기 전엔
연산이 없다".** `previous`를 mutate하는 로직은 Compute 함수 **본문
안**에 있으므로, 그 함수가 재실행되지 않으면(=아무도 다시 `Get()`하지
않으면) mutation 코드 자체가 아예 실행되지 않는다 — 단순히 "가끔
stale하다" 수준이 아니라 **영영 갱신이 안 일어날 수 있음**. 이 패턴으로
만든 State는 반드시 다음 중 하나로 계속 능동적으로 관측되어야 함:
1. quad의 정상적인 선언적 prop 바인딩 경로(`[Property "X"] = someState`
   류)에 실제로 물려있어서, dispatch 엔진이 무효화 시 자동으로
   재`Get()`하게 되어 있거나,
2. 아래 "Observer" 절의 `state:Observer(fn)` + 콜백 안에서 명시적
   `Get()` 호출 + 그 결과를 children 배열에 넣어 라이프사이클에
   묶어두기.
"Ref로 한 번 얻어서 수동으로 Parent만 하고 끝"처럼 능동적 관측 경로가
안 남아있으면, 이 최적화는 그냥 조용히 작동을 멈춘다.

**[2026-08-09 세션] 오버엔지니어링 의심 재검토 — 기각, 현재 설계
유지.** `research/pre-implementation-audit.md` 3-1이 "클로저 업밸류로
이미 되는 걸 별도 API로 만든 것 아니냐"고 의심했던 것에 대한 사용자
반박: 클로저 업밸류 대안은 실제로 다음처럼 즉시실행함수(IIFE)로 감싸
업밸류를 준비해야 함 —

```lua
local computeFn = (function()
  local prev
  return function(self)
    -- prev를 읽고 새 값을 계산, prev 갱신
    prev = ...
    return prev
  end
end)()
someSource:Compute(computeFn)
```

이 준비 코드 자체가 이미 별도 `previous` 인자 하나보다 무겁고 번거로움
— "재사용하고 싶으면 그냥 캐시된 값을 바로 넘겨주면 되는" 게 더
단순하다는 게 사용자 논거. 반대로 `previous`가 없으면 `fn`은 매 호출마다
새 인스턴스를 만들어야 해서(예: `LocalizationTable.new()`) lazy든
아니든 재계산이 일어날 때마다 항상 비싼 재생성이 발생 — `previous`가
막으려는 문제는 실재함. **`pre-implementation-audit.md` 3-1 해소 —
현재 `fn(self, previous)` 설계 그대로 유지, API 표면을 줄이지 않음.**

**스코핑 명확화(이번 세션에 확인, 새 결정 아님) — `previous`는 `self`
(입력)가 아니라 "이 `:Compute` 호출 하나가 만들어낸 결과 State 노드"
자신에 귀속된다.** State가 `:With`/`:Compute` 호출마다 새 노드를
만든다는 건 이미 확정된 온톨로지(아래 "왜 State 체인을 Modifier처럼
플래튼하지 않는가" 절)라, `previous`도 그 새 노드의 내부 캐시 슬롯일
뿐 `self`에 얹히는 게 아님 — 같은 `self`에서 여러 `:Compute`가 갈라지는
팬아웃(`c1 = w:Compute(g1)`, `c2 = w:Compute(g2)`)이 있어도 `g1`/`g2`
각자의 `previous`는 각자의 결과 노드에 독립적으로 저장되므로 서로 안
섞임 — 새로 결정할 것 없이 기존 "노드별 캐시" 원칙의 당연한 귀결.
(참고: `self.Cache`처럼 `self` — 즉 입력 — 에 캐시를 얹는 모양은 이
스코핑과 안 맞아 채택하지 않음 — 팬아웃 시 여러 소비자가 같은
`self.Cache` 슬롯을 공유해 덮어쓰는 충돌이 생기기 때문.)

### `state:Observer(fn)` — 값을 안 실어주는 구독, children 배열에 직접 놓는 leaf 값

**결정(2026-08-06 후속 세션, 사용자 확정)**: 별도 `ObserverHolder`
래퍼 타입은 안 만듦 — `state:Observer(fn)`가 반환하는 값 자체가 이미
"children 배열에 바로 놓을 수 있는 leaf 값"이라 감쌀 필요가 없음.
`Ref`와 완전히 같은 층위. **자유 함수 `Observer(state, fn)`가
아니라 메소드 `state:Observer(fn)`로 확정** — `state`가 항상 필요한
필수 인자라 `:` 리시버 자리에 자연스럽게 들어가고(다른 형태면 인자
두 개짜리 자유 함수가 되어 읽는 순서가 어색해짐), `architecture.md`의
"함수지향 디폴트, `:` 체이닝은 예외적으로만(체이닝이 정말 편한 경우만)"
원칙이 정확히 이 경우를 가리킴 — Store 값 변경 체이닝과 같은 예외
카테고리. **더 근본적인 이유**: `base/store-semantics.md`의 "독립 존재
가능한 프리미티브 vs 원천에 종속된 파생 데이터" 원칙 참고 — Observer는
State처럼 원천 없이는 존재할 수 없는 파생 데이터라, 애초에 "타입
이름을 부르는 자유 함수 생성자" 카테고리에 안 속함(Source/Ref/Store/
Modifier와는 다른 부류).

```lua
local observer = state:Observer(function()
    state:Get()
end)

Frame {
    observer,
}
```

이러면 `observer`는 `Frame`이 살아있는 동안만 유지되고, `Frame`이
retract/Destroy되면 자동으로 정리됨.

- **`fn`은 등록 시점에 즉시 1회 실행된다(2026-08-07 여섯 번째 세션,
  사용자 확정 — 이전까지 미명시였던 항목).** 근거: (1) 이미 채워진
  State를 나중에 구독하면 그 값을 반영하는 연산이 아예 한 번도 안
  일어나는 문제가 생겨 초기화 순서에 디버깅 부담이 생김. (2) 초회
  실행을 하지 말아야 할 구체적 근거가 약함. (3) **이 결정 덕에
  Observer 하나로 "초기값 적용"과 "이후 변경 반영"을 같은 코드 경로로
  통일할 수 있음** — 예: State→프로퍼티 store-bind 핸들러가 그냥
  `state:Observer(function() inst.SomeProp = state:Get() end)`를 걸어
  두는 것만으로 최초 적용까지 공짜로 됨(별도의 "설치 시 1회 적용" 코드를
  따로 안 짜도 됨). `state:Observer()`(인자 없는 "항상 관측" 유틸)도
  이 규칙을 그대로 따름 — 호출 즉시 한 번 관측이 트리거됨.
- **값을 안 실어줌 — 반드시 `Get()`을 다시 해야 함.** 기존 "emit은
  무효화 신호 하나로 좁혀짐 — 값을 안 실어보내므로 저렴함" 원칙(아래
  "Store/State/Source 온톨로지" 절)이 그대로 적용됨: `fn`은 "뭔가
  바뀌었으니 다시 확인하라"는 신호만 받고 새 값 자체는 안 받음 —
  위 예시처럼 `fn` 본문에서 `state:Get()`을 명시적으로 다시
  읽어야 함. 자동으로 안 해주는 이유: 재계산이 진짜 필요한지가 다른
  `:With`한 값에 따라 갈리는 경우가 있어서(위 "포지셔널 인자 지양" 절의
  `noprint` 예시처럼 계산 자체를 통째로 생략하고 싶을 수 있음) — `Get()`
  호출 여부를 작성자가 직접 결정하게 열어둔 것.
- **`fn`을 커링 스타일로 짜는 것도 모듈화 관용구로 권장(2026-08-07 여섯
  번째 세션)** — `state:Observer(makeLogger("x"))`처럼 팩토리가 실제
  `fn`을 만들어 반환하는 패턴, `Modifier`의 `Boldify(10)` 커링(`modifier-plan.md`
  8번)과 같은 결. `base/effect-plan.md`의 Effect도 동일하게 권장.
- **base가 제공하는 것은 `isObserver`류 타입 판별자 하나** — children
  배열 dispatch가 숫자 슬롯 값을 훑을 때 "이게 Observer인가"를 판별해
  `Ref`와 같은 방식으로 라이프사이클에 묶어주는 것 말고는 base가
  더 해줄 일이 없음. 새 dispatch 메커니즘이 아니라 기존 children-array
  참가자 패턴의 반복.
- **콜백 실행은 기존 `canExecute` predicate로 게이팅**(Slot 생존 확인과
  동일한 재사용 — "canExecute 하나로 통일" 원칙, 새 메커니즘 발명 아님)
  — 발화 시점과 처리 시점 사이에 owning leaf가 이미 죽었으면 no-op.
- **구현 노트(사용자 제안, 확정된 아키텍처는 아니고 구현 시 참고)**:
  살아있는 Observer 집합을 Observer 값 내부 필드로 안 두고, 외부에
  weak table(`{[observer] = true}`, `__mode = "k"`)로 인덱싱하는 방식을
  선호 — 포인터 해싱 비용만 들고 값 자체엔 부작용 없음. rbvm의
  `getNamespaceOf`류가 비슷한 외부 weak-table 인덱싱을 씀
  (`base/lifecycle-pattern.md` 참고).
- **인자 없는 `state:Observer()` — "항상 관측" 유틸.** `fn`을 생략하면
  내부적으로 no-op 콜백을 쓰는 것으로 취급해, 그냥 "이 State를 계속
  능동적으로 관측 상태로 유지"하는 용도로만 씀. 위 "`previous` 인자"
  절의 캐비엇("능동적 관측 경로가 안 남아있으면 mutate 로직이 조용히
  멈춘다")을 만족시키는 가장 단순한 도구 — 별도 콜백 로직 없이 그냥
  이 State가 계속 재계산되게만 강제하고 싶을 때 씀. 문서화만 확실히
  하면 별문제 없음(사용자 판단).

### `state:Apply(factory)` — Modifier와 동일한 순수 체이닝 설탕으로 확정 (2026-08-07 일곱 번째 세션)

**처음 제안됐던 "`:With`/`:Compute` 등록을 커링으로 자동화하는 조합기"
방향은 기각됨 — 사용자가 재확인한 실제 의도는 그보다 훨씬 단순함.**
`Modifier:Apply(factory)`도 매번 새 값을 만들어내는 체이닝 설탕일 뿐이듯,
State/Source도 `:With`/`:Compute`마다 새 노드가 나오는 같은 모양이라 —
`state:Apply(factory)`는 그냥 `factory(state)`를 메소드 체이닝 문법으로
쓴 것뿐이고 그 이상의 계약은 없음(`Modifier:Apply`와 완전히 동일한
정의: `function(self, factory) return factory(self) end`).

- **동기**: 커링 팩토리 두 개 이상을 이미 있는 문법만으로 이으면 바깥에서
  안으로 겹쳐 읽어야 하는 중첩 호출이 됨 — 실제 형태로 예를 들면,
  ```lua
  -- Apply 없이: 안쪽(가장 최근에 만든 것)부터 거꾸로 읽어야 함
  local capped = capAt(100)(withLocale(localeStore.locale)(rawScore))

  -- state:Apply로: 왼쪽에서 오른쪽, 만든 순서 그대로 읽힘
  local capped = rawScore
    :Apply(withLocale(localeStore.locale))
    :Apply(capAt(100))
  ```
  팩토리가 세 개, 네 개로 늘어날수록 앞쪽 버전은 괄호 깊이와 읽는 방향이
  코드 작성 순서와 반대로 꼬여 diff/리뷰에서 특히 안 좋음 — `:Apply`
  버전은 각 줄이 "그다음 뭘 했는지"를 순서대로 나열하므로 Modifier
  체이닝(`mod:FontSize(14):Apply(Boldify(10)):Apply(Italicify)`)과 읽는
  방식이 완전히 통일됨. `:With`/`:Compute` 자체를 대신 호출해주는
  자동화가 아니므로, 여전히 팩토리 본문 안에서 `:With`/`:Compute`를
  직접 호출하는 건 팩토리 작성자 몫.
- **구현 비용 거의 0**: Modifier와 달리 State/Source는 제네릭 `__index`로
  필드 setter를 즉석 합성하는 메커니즘이 없어서(고정된 메소드 표면만
  존재), Modifier의 `Apply`처럼 "필드 이름으로 예약해야 하는" 충돌
  자체가 없음 — 그냥 고정 메소드 하나 추가하는 것.
- **타입은 `factory: (State<T>) -> U): U`로 완전히 열어둠** — Modifier의
  `Apply`는 `factory: (M) -> M`으로 같은 타입을 유지해야 체이닝이
  이어지지만, State의 `:Apply`는 팩토리가 State가 아닌 값(예: 최종
  요약된 plain 값)을 반환해 반응형 그래프를 벗어나는 탈출구로 쓰는 것도
  막을 이유가 없음 — Modifier보다 오히려 더 자유로운 시그니처.
- **Source도 자동 포함**: Source가 State를 구조적으로 만족하는 기존
  델리게이션(`__index`로 `:With`/`:Compute` 위임)에 `:Apply`도 그대로
  얹히므로 별도 구현 불필요.
- **Effect/Observer/Compute의 `fn` 커링 권장(위 절들)과 같은 스레드지만
  별개 기능** — 커링은 "`fn` 자체를 팩토리로 짜는 관용구" 권장이고,
  `:Apply`는 그렇게 만든 팩토리를 체이닝 문법으로 적용하는 수단. 둘이
  합쳐지면 `state:Apply(makeFormatter("ko-KR"))`처럼 자연스럽게 이어짐.
- **관용구 — 이름 붙여 재사용하는 콤비네이터는 항상 `:Apply`로 붙인다
  (2026-08-12 세션, `research/operator-sugar-plan.md`/`research/
  tween-plan.md`의 `Animate` 정정에서 도출)**: 그 자리에서 한 번 쓰고
  마는 인라인 람다(deps도 그 호출문에 바로 나열)는 `:Compute(fn,
  ...deps)`를 직접 쓰고, `local addTax = Sum(tax, shipping)`처럼 이름
  붙여 여러 곳에서 재사용할 콤비네이터는 인자 개수(0항/N항)와 무관하게
  전부 `factory(self) -> State`를 반환해 `:Apply`로 붙임 — 스타일
  선호가 아니라 정합성 문제: quad는 암묵적 자동 추적을 기각했으므로
  (위 "암묵적 자동 추적 기각" 절) 재사용 팩토리가 캡처한 deps를
  `:Compute`에 직접 꽂으면 그 deps가 구독 목록에 안 걸려 조용히
  멈추는 버그가 됨 — `:Apply`는 factory 내부에서 `self:Compute(fn,
  ...deps)`를 스스로 다시 전달하므로 이 문제가 없음.

**Observer/Effect의 `:Subscribe()`/`:Unsubscribe()`는 이 절과 무관한
별개 주제** — 아래 새 절로 분리(이전에 이 헤더 아래 잘못 걸려 있던
문서 버그 수정, 내용 자체는 이미 확정된 것 그대로).

### Observer의 `:Subscribe()`/`:Unsubscribe()` — children 배열 밖 독립 구독 (2026-08-06 후속 세션)

**문제**: children 배열에 넣는 자동 라이프사이클 바인딩은 Observer가
"어딘가 leaf에 붙어있다"는 걸 전제함. 근데 흔한 실사용 패턴 하나가 이
전제를 깨뜨림 — 개발자가 디버깅용으로 `RunService:IsStudio()` 가드
안에서 Store에 직접 Observer를 걸어 `print`하는 패턴(원하면 BooleanValue
로 부분부분 켰다 껐다 하기도 함). 이건 다크패턴이 아니라 오히려 방어적인
엔지니어링이고, 붙일 leaf 자체가 없는 "전역/독립" 사용이라 위 weak-table
기반 자동 추적이 적용 안 됨. **[용어 정정, 2026-08-09 여섯 번째 세션]**
여기서 "weak-table 기반 자동 추적"이라 부른 것이 나중에 정식으로
`bindLifetime`(`base/lifecycle-pattern.md`)으로 명명됨 — 별도 메커니즘
두 개가 아니라 같은 것의 명명 전/후 표현.

**해결**: 명시적 `:Subscribe()`/`:Unsubscribe()`를 추가로 지원. 이건 새
설계가 아니라 `bind-system-plan.md`의 PA님 코드 교차검증(라이프사이클
절)에서 이미 예고해둔 확장 지점을 실제로 채우는 것 — "나중에 GC만으로
정말 부족한 케이스가 생기면 명시적 dispose 경로를 추가로 얹는 게 가능한
디자인"이라고 그때 이미 못박아뒀음.

- **`local` 변수로 참조만 들고 있는 것으로는 부족한 이유**: 토글(BooleanValue로
  로깅 껐다 켰다) 케이스에서, 참조를 끊어도 실제 GC는 결정론적으로 즉시
  일어나지 않음 — "껐다"고 생각한 뒤에도 한동안 계속 발화할 수 있음.
  `:Unsubscribe()`는 즉시/결정론적으로 끊는 경로라 이 문제가 없음.
- **liveness 체크는 필드 우선, weak table은 폴백**(사용자 제안): 외부
  weak table 조회보다 리터럴 필드 접근이 더 쌈(Luau가 문자열 키 접근을
  미리 해시해둠) —
  ```lua
  if self.Subscribed then return true end
  if self.Connection then return self.Connection.Connected end
  ```
  자동(리프 부착)/수동(구독) 두 라이프사이클 경로를 하나의 `canExecute`류
  predicate로 OR 묶는 자연스러운 형태. 실측은 구현 단계에서 확인.
- **내부 강참조 레지스트리**: `SubscribedObservers: {[observer]: true}`류를
  **weak 아닌 강참조**로 둠 — 여기서 weak면 "구독해서 살려둔다"는 목적
  자체가 무의미해짐. 위 자동 케이스의 weak table과 역할이 명확히 갈림
  (weak table=자동/리프 전용, 강참조 레지스트리=수동 구독 전용).
  **`:Unsubscribe()`는 이 레지스트리에서 반드시 `SubscribedObservers[observer]
  = nil`까지 해야 함** — `Subscribed` 플래그만 내리고 강참조를 안 끊으면
  GC 대상이 안 되는 반쪽짜리 해제가 됨, 둘은 항상 같이 일어나는 한 세트.
- **`:Subscribe()`/`:Unsubscribe()` 둘 다 idempotent** — 이미 구독 중인데
  또 Subscribe해도, 구독 안 했는데 Unsubscribe해도 에러 안 나고 그냥
  no-op. 토글 로직 짤 때 상태 추적 부담을 줄여줌.
- **[정정, 2026-08-09 여섯 번째 세션] "`:Unsubscribe()`는 자동(리프)
  케이스에도 동일하게 씀"은 틀림 — 리프/`bindLifetime` 경로의 조기
  해제는 `unbindLifetime(inst, value)`가 담당, `:Unsubscribe()`는
  전역 강참조 레지스트리 경로 전용으로 남음.** `inst`를 모르는
  `:Unsubscribe()`가 `bindLifetime`이 어느 `inst`에 등록했는지 찾아낼
  방법이 없어서(레지스트리가 `inst`별로 나뉘어 있음) 하나로 통합할 수
  없음 — 위 "이중 바인딩 금지" 절의 정정 참고.
- **`state:Observer(fn):Subscribe()`처럼 참조를 아무 데도 안 담아도 정상**
  — 강참조 레지스트리 자체가 생존을 보장하는 유일한 근거라, 로컬 변수에
  담아둘 필요가 없음. 예외 없이 그냥 계속 돎(그게 이 메커니즘의 핵심
  포인트).
- **⚠️ 이건 quad 전역의 "정리는 기본적으로 GC에 위임" 원칙의 의도적
  예외 — 문서에 명시적으로 경고할 것(2026-08-09 열한 번째 세션).**
  `:Subscribe()`로 등록한 뒤 로컬 변수 참조를 전부 놓아도(스코프 이탈,
  변수 재할당 등) **GC되지 않고 영원히 계속 실행됨** — 강참조
  레지스트리가 그 자체로 생존을 보장하기 때문. `bindLifetime`(leaf
  부착 포함) 경로는 `inst`가 죽으면 자동으로 정리되는 GC-native 그대로지만,
  `:Subscribe()` 경로는 오직 명시적 `:Unsubscribe()` 호출로만 끊김 — 이
  차이를 모르고 "quad는 다 GC-native니까 참조만 버리면 되겠지"라고
  가정하면 조용한 누수(메모리뿐 아니라 계속 재실행되는 콜백까지)로
  이어짐. 용도도 "완전히 top-level(어떤 Instance 생명주기에도 안 묶인)
  사이드 이펙트"로 좁게 문서화할 것 — 특정 `inst`에 묶인 경우는
  `:Subscribe()`가 아니라 leaf 부착(`bindLifetime`)이 정상 경로.
- **`:Subscribe()`/`:Unsubscribe()` 둘 다 `self`를 리턴(대칭)** —
  `local obs = state:Observer(fn):Subscribe()`처럼 "구독 시작 + 나중에
  끊을 핸들 확보"가 한 줄로 되고, `table.insert(subs, state:Observer(fn)
  :Subscribe())`처럼 리스트에 담을 때도 줄바꿈 없이 됨. Observer가
  immutable 값이 아니라 원래 mutable한 구독 핸들이라 fluent 체이닝이
  자연스러움 — Modifier의 clone-then-return 체이닝과는 다른 이유(같은
  객체를 mutate하고 그대로 돌려주는 것)지만 표면 문법은 비슷하게
  체이닝 가능.

### 이중 바인딩 금지 — 진짜 독립된 경로는 `:Subscribe()`(전역)와 `bindLifetime`(inst-scoped) 둘뿐, `canBound(handle)`로 즉시 에러 (2026-08-07 일곱 번째 세션, 2026-08-09 세션에서 이름 확정, 같은 날 여섯 번째 세션에서 "leaf 부착=bindLifetime 호출"로 정정)

**규칙**: 같은 Observer/Effect 핸들 하나는 라이프사이클 바인딩 경로를
딱 하나만 가질 수 있음 — `:Subscribe()`로 전역 강참조 레지스트리에
등록되거나(위 절), `bindLifetime(inst, value)`로 특정 `inst`에 종속되거나
(아래 "`bindLifetime`도 같은 게이트를 공유" 절) — **이 둘 중 하나만**.

**[정정, 2026-08-09 여섯 번째 세션] "leaf 부착"은 세 번째 독립 경로가
아니라 `bindLifetime`을 호출하는 것 그 자체다.** `Frame { observer }`처럼
children 배열에 Observer를 직접 놓으면, `Dispatch/Leaf.luau`가 이걸
매치해 내부적으로 `bindLifetime(inst, observer)`를 호출 — "children
배열에 놓여 leaf에 자동 부착"과 "`bindLifetime`으로 특정 `inst`에
종속"은 **같은 동작**이라 서로 배타적일 수 없음(둘 다 하는 게 아니라
leaf 부착이 곧 `bindLifetime` 호출 방식 중 하나일 뿐). 그래서 실제
상호 배타는 "전역 소유(`:Subscribe()`)" vs "특정 `inst` 소유
(`bindLifetime`, 직접 호출이든 leaf 부착을 통한 호출이든)"라는
**2-way**로 정정 — 위 "Observer의 `:Subscribe()`/`:Unsubscribe()`" 절이
leaf 부착을 "weak table 기반 자동 추적"이라 불렀던 건 `bindLifetime`이
정식 이름을 얻기 전(2026-08-06 후속 세션) 표현이라 지금은 같은 것을
가리킴 — 별도 메커니즘 두 개가 있던 게 아니었음.

**둘 이상 동시에 걸리는 건 UB로 확정** — 이미 한 경로로 바인딩된 핸들을
다른 경로로 또 바인딩하는 건 금지(leaf로 이미 부착된 걸 `:Subscribe()`
하는 것, 또는 그 반대). 같은 값을 `bindLifetime`으로 두 번(leaf 부착
한 번 + 직접 호출 한 번, 또는 leaf로 두 Instance에 부착) 등록하려는
것도 걸림 — 이건 "leaf vs bindLifetime 충돌"이 아니라 "같은 단일
메커니즘을 중복 호출"하는 것이라 자연히 같은 게이트가 잡아줌.

**UB를 조용한 오동작이 아니라 즉시 에러로 만든다** — 판별 비용이 사실상
0(불리언 필드 하나 확인)이라, 조용히 이상하게 동작하게 두는 것보다
바로 에러를 던져 버그를 그 자리에서 잡는 게 엔지니어링상 훨씬 쌈.

**이름 확정 — `canBound(handle): boolean`, `canExecute`와 같은 결의
탑레벨 함수(2026-08-09 세션, 가칭 `Bound` 필드를 직접 노출하는 대신).**
`canExecute(inst, value)`가 "지금 살아있어서 실행돼도 되는가"를 묻는
탑레벨 predicate인 것과 똑같이, "아직 어느 경로로도 안 묶였는가"도
raw 필드(`self.Bound`)를 직접 보여주지 않고 같은 스타일의 탑레벨
함수로 감싼다 — Observer/Effect 둘 다 쓰는 범용 predicate라 특정
프리미티브 하나의 전용 소유물이 아니므로(`store-semantics.md`의
네이밍 케이싱 기준: "이 이름이 특정 프리미티브 타입 하나의 전용
소유물인가?"에 아니오라 소문자 탑레벨이 맞음, `architecture.md`
"코드 스타일 — 네이밍 케이싱" 절과 같은 기준):

```lua
-- :Subscribe() 진입부, bindLifetime 진입부(leaf 부착도 내부적으로 이걸 거침)
-- — 둘 다 진입 전 동일하게 확인
if not canBound(self) then
  error("Observer/Effect가 이미 다른 경로로 바인딩됨 — :Subscribe()와 bindLifetime(leaf 부착 포함)은 동시에 쓸 수 없음")
end
-- 통과했으면 여기서 바인딩됨으로 표시(내부 구현 디테일 — 공개 표면은 canBound 하나뿐)
```

- `canBound(handle)`은 "이 핸들이 아직 어느 경로로도 안 묶였으면
  `true`, 이미 한 번 묶였으면 `false`"를 답하는 순수 predicate — 내부
  구현은 여전히 불리언 플래그 하나(예전 가칭 `Bound`)로 충분하지만,
  공개 표면에서 그 raw 필드를 직접 보여주지 않고 함수로 감싼다는 점만
  바뀜. 동작 자체(둘 중 한 경로만 허용, 위반 시 그 자리에서 에러)는
  안 바뀜. **이 내부 플래그는 새 필드가 아니라 `canExecute`가 이미 보는
  `.Subscribed` 필드 그 자체(2026-08-09 여섯 번째 세션 명시)** —
  `:Subscribe()`뿐 아니라 `bindLifetime`도(Observer/Effect 값에 한해)
  이 필드를 `true`로 세팅, `:Unsubscribe()`/`unbindLifetime` 둘 다
  `false`로 되돌림 — 그래야 `bindLifetime`으로 등록된 Observer도
  `canExecute`가 정상적으로 "살아있음"으로 인식함(필드를 둘로 나누면
  `bindLifetime`으로만 등록된 Observer가 `canExecute`에서 항상
  `false`로 오판됨).
- 이 predicate는 어느 경로가 먼저 왔는지와 무관하게 "이미 바인딩됨"만
  답함 — 두 진입점이 똑같이 `canBound`를 확인하므로 순서와 무관하게
  대칭적으로 막힘.
- **`:Unsubscribe()`는 `:Subscribe()` 경로의 해제만 담당, `bindLifetime`
  (leaf 부착 포함) 경로는 `unbindLifetime(inst, value)`로 해제** —
  둘은 서로 다른 함수로 남음(호출자가 `bindLifetime`을 부른 쪽이
  `unbindLifetime`도 대칭적으로 부르는 책임을 짐 — `inst`를 모르는
  `:Unsubscribe()`가 대신 처리할 수 없는 정보라서). leaf 부착으로
  세워진 바인딩의 실제 해제도(예: Instance 파괴 전 조기 해제하고 싶을
  때) 결국 `unbindLifetime`이 담당 — 위 "`:Unsubscribe()`는 자동(리프)
  케이스에도 동일하게 씀" 절의 서술은 leaf 부착이 별도 메커니즘이라고
  전제했던 것이라 **이 정정으로 대체**(`:Unsubscribe()`가 아니라
  `unbindLifetime`이 leaf 해제의 실제 통로).
- **Effect도 동일 규칙 적용(사용자 확인)** — Effect가 `state` 인자로
  내부적으로 Observer를 조합하는 경우든, `state` 없는 경우든 같은
  `canBound` 게이트를 그대로 재사용(`base/effect-plan.md`) — Effect
  자신이 아니라 내부 Observer가 게이트를 갖고 있어서, Effect 구현이
  이 정정을 몰라도 자동으로 커버됨. 이전에 그 문서에 적어뒀던 "leaf
  부착과 `:Subscribe()`를 동시에 쓰는 것도 안전"이라는 서술은 **이
  규칙으로 대체(정정)** — 안전하게 지원하는 게 아니라 애초에 막아야
  하는 조합이었음.
- **문서화 경고 대상(api/심화)**: "한 Effect/Observer 핸들을 children
  배열에 놓았다면(=`bindLifetime`으로 등록된 것) 그걸 다시
  `:Subscribe()`하거나 다른 Instance에 또 leaf로 놓지 말 것, 반대도
  마찬가지 — 여러 경로를 동시에 쓰고 싶으면 각각 독립된 새
  `Effect(...)`/`state:Observer(...)` 호출로 따로 만들 것"을 명시할 것.

### `bindLifetime`이 이 게이트의 두 번째(이자 leaf 부착이 실제로 쓰는) 진입점이다 (2026-08-09 여섯 번째 세션)

`Dispatch.setLength`처럼 특정 `inst`에 종속된 내부 Observer를 등록할 때
쓰는 `bindLifetime(inst, value)`(`base/lifecycle-pattern.md`)도 **같은
`canBound` 게이트를 확인** — Observer/Effect 값을 `bindLifetime`할 때도
진입 전 `canBound(value)`를 확인하고, 통과하면 바인딩됨으로 표시.
**children 배열 leaf 부착도 바로 이 `bindLifetime` 호출** —
`Dispatch/Leaf.luau`가 `(i:number, v=Observer/Effect)`를 매치하면
그 자리에서 `bindLifetime(inst, v)`를 호출하는 것뿐, 별도 "leaf 전용"
바인딩 로직이 따로 있는 게 아님. 그래서 **실제 상호 배타는 `:Subscribe()`
(전역 강참조 레지스트리)와 `bindLifetime`(inst별 gchold, 직접 호출이든
leaf 부착을 통한 간접 호출이든) 둘뿐** — 새 규칙을 따로 만들 이유가
없음, 기존 게이트에 진입점 하나(`bindLifetime`, leaf 부착이 그 특수
사례)만 추가.

```lua
function bindLifetime(inst, value)
    local isOE = isObserver(value) or isEffect(value)
    if isOE and not canBound(value) then
        error("Observer/Effect가 이미 다른 경로로 바인딩됨")
    end
    ... -- gchold 등록(base/lifecycle-pattern.md)
    if isOE then value.Subscribed = true end   -- canExecute가 보는 필드 그대로 재사용
end

function unbindLifetime(inst, value)
    ... -- gchold 해제
    if isObserver(value) or isEffect(value) then value.Subscribed = false end
end
```

- **비-Observer/Effect 값(예: Tween 내부에 쓰는 평범한 클로저)은 이 게이트
  자체가 안 적용됨** — `canBound`는 `.Subscribed`류 필드가 있는 Observer/
  Effect 전용 predicate라, 그 외 값은 `bindLifetime`이 그냥 통과시킴(leaf/
  `:Subscribe()` 경로 자체가 성립 안 하는 값들이라 충돌 대상이 없음).
- Observer/Effect가 `bindLifetime`으로 바인딩된 뒤엔 `canBound`가
  `false`를 반환하므로, 그 뒤에 같은 값을 leaf로 놓거나 `:Subscribe()`하면
  기존 두 진입점의 기존 체크가 그대로 걸러줌 — 이 방향은 별도 코드 추가
  없이 이미 성립.

**quad의 Unix 파이프 영감(원래 동기)과 `Pipe`/`fromState` 후보 검토 경위는
`archive/quad2-try-research-findings-rejected.md`로 이전됨** — 최종 결론만
남기면: 목표(State끼리 자유롭게 합성/파이핑)는 아래 "Store/State/Source
온톨로지" 절의 `state(state)` 조합 모델로 달성됨, 별도 `Pipe`/`fromState`
콤비네이터 타입은 불필요로 폐기.

## Store/State/Source 온톨로지 — 핵심 메커니즘 확정 (2026-08-04 2차 라운드)

**상태**: 전파 모델/`:Compute` 인자 규칙/State 쓰기 금지/Slot 생존 확인/타입
추론(dot-access) 전부 `AskUserQuestion`으로 확인 완료. 남은 건 정확한 함수/
생성자 이름뿐(구현 단계). `base/store-semantics.md`의 "State 프리미티브는
실제로 필요하다" 정정에서 이어짐.

**핵심 온톨로지** (2026-08-06 후속 세션에서 Store/Source 부분 정정 —
아래 "State는 쓰기 대상이 아님" 절 이후 내용 및 `base/store-semantics.md`의
"Source가 State를 만족함" 절 참고):
- **Source** — 실제 값이 존재하고 변경될 수 있는 단일 지점(v1의 "값의 근원").
  **구조적으로 State를 만족(단방향 호환)** — `:Get()`/`:With`/`:Compute`
  전부 지원 위에 `:Set(value)`/`:Emit()` 추가.
- **Store** — Source들의 이름 붙은 모음, 그 이상 아님. `store.a`처럼 키로
  접근하면 **이미 만들어진 Source가 있으면 그대로 반환, 없으면 그 자리에서
  만들어 저장한 뒤 반환**(더 이상 별도 State wrapper를 매번 만들거나 따로
  캐싱하지 않음 — Source 자체가 이미 State를 만족하므로 wrapper 계층
  자체가 불필요해짐. **[정정, 2026-08-07]** "Store 생성 시 전부 eager하게만
  만들어진다"는 이전 서술은 부정확 — `defaults`가 선택이고 Luau 타입이
  런타임에 강제 안 되므로, 생성 시점 eager 생성(각 `defaults` 키)과
  `store.key` 접근 시점 lazy 생성(아직 없는 키를 그 자리에서 만듦)이 둘 다
  필요함, 상세는 `base/store-semantics.md` 참고).
- **State** — source(또는 다른 state)의 결과를 캐싱만 하는 존재, 자기 고유의
  독립적 value 개념이 없음. `state(state)`로 기존 state의 결과를 받아 새
  state를 만들어 분기 가능 — 이게 사실상 Unix 파이프 영감의 "State끼리
  합성 가능"이라는 원래 목표를 구현하는 방식.

**전파 모델 확정: push-invalidate(신호만) / pull-recompute(`Get()` 시점에만) —
Fusion식 eager 노드·생성순 정렬은 안 만듦**

- `Source`는 값이 바뀌면 구독 중인 State들에게 **"무효화됐다"는 신호만
  쏜다** — 새 값 자체는 신호에 안 실림("state는 세터를 내보내기보다
  업데이트 됐다는 신호만 쏜다" — 사용자 확정 문구).
- 신호를 받은 State는 자기 `invalid` 플래그만 세우고, 이미 `invalid`였다면
  그 아래로 더 전파하지 않는다 — 다이아몬드 의존성에서 중복 워크를 막는
  장치(Vide가 저자 스스로 `todo.md`에 미해결로 남긴 문제의 해결책).
- 실제 재계산은 `:Get()`이 호출되는 시점에만 일어남 —
  "필요할 때 계산" 원칙(사용자 확정). Fusion의 `timeliness="eager"` 노드/
  생성순 정렬 장치는 만들지 않음 — quad엔 그런 다단계 즉시 재계산이 필요한
  소비자가 없다는 판단. 유일하게 "즉시 반응해야 하는" 소비자는 store-bind
  pluggable 핸들러(위 "확정된 디스패치 모델" 절)인데, 이건 무효화 신호를
  받는 즉시 자기가 알아서 `Get()`을 호출해 pull하는 방식으로 충분함 —
  State 스스로 "지금 나를 보는 eager 소비자가 있나" 같은 부기가 전혀
  필요 없음.
- `emit`은 이 무효화 신호 하나로 좁혀짐 — 값을 안 실어보내므로 저렴함
  ("emit 필요 여부" 열린 질문은 이걸로 해소).

**전역 원칙으로 명문화: "관측해야 실체화된다" (2026-08-04 세션)**

위 pull-recompute 규칙을 State 하나의 재계산 메커니즘으로만 읽지 말고,
프로젝트 전역에 적용되는 원칙으로 명시함: **어떤 파생값도 `:Get()`으로
직접 읽히기(관측) 전까지는 계산되지 않는다.** 이 원칙은 State 자체뿐 아니라,
State를 필드 값으로 담고 있는 다른 구조(예: `base/modifier-plan.md`의
Modifier)에도 그대로 적용됨 — Modifier의 getter가 State 필드를 읽으면 그
순간이 바로 관측이고, 그 순간 계산이 확정됨.

**주의 — 구조적 복사는 관측이 아님.** `table.clone`처럼 테이블 레퍼런스만
복사하는 연산은 안에 담긴 State 핸들을 그대로 옮길 뿐 `:Get()`을
호출하지 않으므로 관측이 아니고, 계산을 트리거하지 않음. Modifier 체이닝
메소드가 `table.clone` 후 필드를 덮어쓰는 것(위 "Immutable 값 + clone 기반
체이닝")과 이 원칙이 충돌하지 않는 이유가 바로 이것 — clone은 그저 참조
복사라 State 필드는 클론 이후에도 여전히 살아있는 lazy 핸들로 남음.

**왜 State 체인을 Modifier처럼 플래튼하지 않는가 (2026-08-06 후속 세션)**

**문제 제기(사용자)**: State가 `a → b → c`처럼 계속 연결되는 구조면, 이전
노드가 다음 노드에 대한 emit 연결/값 연결을 항상 들고 있어야 함(weak
table로 GC는 되지만 별도 데이터스트럭처 관리 부담). 대안으로, 각 State가
자기 Compute 함수 목록을 통째로 누적해서 갖고(Modifier의 clone-then-return
체이닝처럼) 매번 클론+append하면 링크드 그래프 자체가 필요 없어지지
않는가?

**기각 이유 — State의 정의 자체가 "캐싱하는 존재"임.** 위 온톨로지에
"State — source(또는 다른 state)의 결과를 **캐싱만 하는** 존재"라고
확정돼 있고, `previous` 두 번째 인자 메커니즘(무거운 파생 엔진 객체
재생성 비용 절감)도 이 캐싱 전제 위에서만 의미가 있음. 만약 Compute
체인을 매번 통째로 클론해 각 leaf가 독립된 함수 목록을 갖게 하면, 중간
State를 여러 갈래가 공유하는 다이아몬드 형태(`b`에서 `c1 = b:Compute(g1)`,
`c2 = b:Compute(g2)`로 분기)에서 `b`까지의 계산이 캐시 공유 없이 소비자
수만큼 중복 실행됨 — `previous` 메커니즘이 막으려던 문제를 반대로 다시
만들어내는 셈이라 방향이 안 맞음.

**"별도 데이터스트럭처 관리" 부담은 실제로는 작음.** "관측해야
실체화된다" 원칙 때문에 살아있는 노드-대-노드 구독 엣지가 필요한 건
실제로 관측되는(`Get()`되는) State뿐 — 중간에 만들어놓고 아무도 안 보는
State는 구독 등록 자체가 안 일어남. 다이아몬드에서 중복 워크를 막는
`invalid` 플래그 dedup 장치도 체인 전체가 링크드일 것을 요구하지 않고
각 노드가 자기 구독자 목록만 가지면 되는 것이라, 이 결정과 무관하게
그대로 유지됨. 구현은 Observer와 동일한 패턴(외부 weak table,
`{[child] = true}` 류)으로 충분 — 새 메커니즘 발명 아님.

**결론**: 노드별 캐시 유지(현재 모델) 유지, 플래튼 기각. Modifier가
플래튼+클론을 쓰는 건 애초에 캐싱이 필요 없는 정적 데이터라 성립하는
것이고, State는 존재 이유 자체(캐싱)가 달라 같은 패턴을 적용할 수 없음.
`research/documentation-plan.md`의 심화 문서 후보로 남겨둠 — "왜 State는
Modifier처럼 플래튼하지 않는가"는 설계 근거를 알고 싶은 사용자를 위한
좋은 심화 콘텐츠 소재.

### `:With`도 새 State 노드로 확정, 가변인자로 체인 남발 방지 (2026-08-07)

**문제 제기(사용자)**: `:With(...)`가 문서상 가변인자 표기이긴 한데, 실제로
호출마다(`:With(a):With(b):With(c)`처럼 체이닝할 때) 매번 새 State 노드를
만드는 게 맞는지, 아니면 값 없이 의존성 목록만 clone-then-append로 누적하는
가벼운 빌더로 만들어 노드 증식을 피해야 하는지가 불명확했음.

**"빌더" 대안은 기각.** 세 가지 이유:

1. **디버그 그래프가 꼬임.** `quad-debug`의 핵심 UX는 "무엇이 무엇에
   연결됐는가" 그래프(`research/debug-tooling-plan.md`). With/Compute를
   전부 실제 노드로 두면 코드상의 호출 체인이 그래프 엣지와 1:1로 그대로
   대응됨. 빌더로 만들면 그래프 툴이 "이건 노드가 아니라 나중에 갈라지는
   지점"이라는 가상의 분기 모양을 따로 합성해야 함 — 그럴 이유가 없음.
2. **다이아몬드 dedup을 못 타고 특수 케이스가 생김.** With가 진짜 노드면
   `w = key1:With(key2)`에서 갈라지는 `c1 = w:Compute(g1)`, `c2 =
   w:Compute(g2)` 같은 흔한 fan-out이 이미 확정된 "invalid 플래그로
   다이아몬드 중복 워크 방지" 장치(위 "전파 모델 확정" 절)를 그대로
   재사용함. 빌더면 c1/c2가 key1/key2에 각자 직접 구독을 걸어야 해서
   기존 dedup 경로를 매번 우회하는 특수 케이스가 생김.
3. **clone 기반 구현은 Compute 노드 위에서 실제로 깨짐(사용자 지적,
   검증 완료).** `c = a:Compute(f)` 뒤에 `w = c:With(b)`를 clone으로
   구현하면, `table.clone`이 `c`의 캐시 슬롯(계산된 값 + `invalid`
   플래그)까지 그대로 복사해 `w`가 `c`와 별개의 독립 캐시를 갖는 사실상
   다른 노드가 됨. `c`와 `w`가 각자 관측되면 `f`가 두 번 따로
   실행/캐싱됨 — 바로 위 "왜 State 체인을 Modifier처럼 플래튼하지
   않는가" 절에서 이미 기각한 것과 정확히 같은 실패 모드(공유돼야 할
   계산이 소비자 수만큼 중복 실행). Modifier의 clone-then-append 패턴을
   State 쪽에 그대로 가져오면 안 되는 이유가 바로 이것.

**결정**: `:With(...)`는 호출마다 self+주어진 인자들을 구독하는 **새 State
노드**를 만든다(레퍼런스 기반 구독, clone 아님) — 계산 함수는 없고 값은
`self`를 그대로 통과(pass-through)시키되 구독 목록만 넓힌 얇은 노드. 이
노드는 Observer와 같은 패턴(외부 weak table)으로 상위 노드의 구독자 목록에
등록됨.

**⚠️ 문서 읽을 때 혼동 주의(2026-08-12 추가, 코퍼스 전체에 같은 패턴으로
적용): `Tag`(`:Added`/`:Removed`)와 `Modifier`(`:Apply` 등)는 겉보기엔
같은 `:` 체이닝 문법이지만 실제로는 clone-then-return이고, State의
`:With`/`:Compute`는 이름은 비슷해 보여도 정반대(clone이 아니라 진짜 새
노드)임.** 하나가 clone 계열, 다른 하나가 새-노드 계열이라는 걸 헷갈리기
쉬우니(둘 다 "값을 안 바꾸고 새 걸 반환하는 메소드 체이닝"으로 보이기
때문) 각 API 문서를 볼 때 이 문단을 기준으로 확인할 것 — clone 계열은
`Tag`/`Modifier`(값 객체, 확정 상태), 새-노드 계열은 `State`의
`:With`/`:Compute`(반응형, lazy)로 완전히 분리되어 있고 섞이지 않음.

**노드 증식 걱정은 가변인자로 해소.** 처음 문제 제기("With 하나마다 노드가
하나씩 늘어나는 게 낭비 아니냐")는 노드 자체를 없애는 대신, `:With(...)`가
여러 의존성을 한 번에 받을 수 있게 해서 해소함:

- `key1:With(a, b, c):Compute(fn)` — 노드 1개(구독 3개)로 끝남.
- `key1:With(a):With(b):With(c):Compute(fn)` — 여전히 가능하지만 노드
  3개가 만들어짐. 이건 나쁜 게 아니라 각 노드가 dedup/디버그 그래프에서
  실제 역할(구독 fan-in 지점)을 하는 저렴한 노드(계산 없음, Modifier
  clone과 같은 급의 비용)라 걱정할 비용이 아님.
- 그래도 **가변인자 스타일을 권장 관례로 삼음** — 그래프로 그릴 때도
  `:With(a, b, c)`가 `:With(a):With(b):With(c)`보다 단순(노드 1개에 들어오는
  엣지 3개 vs 노드 3개가 순서대로 이어지는 모양)해서 디버그하기 쉬움
  (사용자 확인).

**`:With`/`:Compute` — self 인자도 lazy 핸들로 통일**

> **[2026-08-13 열세 번째 세션, 해소 — 아래 계약은 그대로 확정]**
> 한때 이 계약이 Luau 추론과 충돌한다며 `question.md` 0-Y로 열려 있었고,
> "콜백이 raw 값을 받으면 완전히 클린"이라는 1차 판정까지 붙어 있었음.
> **44개 스파이크 재실측 결과 그 1차 판정이 뒤집혔음** — raw 값 계약도
> 똑같이 불안전했고, 진짜 문제는 콜백 계약이 아니라 **`Compute`가
> `State<U>`(자기 이름을 다른 타입 인자로 감싼 타입)를 반환한다는 것
> 자체**였음(Luau의 현 한계, RFC가 `Promise<T>.andThen`으로 예시 든 바로
> 그 패턴). **따라서 아래 lazy 핸들 계약은 바꿀 이유가 없고 그대로
> 확정**이며, 콜백 파라미터 추론은 타입 선언을 "데이터부/메소드부"로
> 쪼개면 해결됨. 반환 타입만 사용처에서 명시 주석으로 바인딩하면 됨 —
> 규약 전문은 **`base/typing-limits.md`**, 실측 근거는
> `audit/type-recursion-issue/`.

- 최초안(self 값은 포지셔널 raw 값, with한 값만 클로저로 읽음)에는 실제
  단점이 있었음 — self가 raw 값이면 `fn` 호출 전에 항상 self를 먼저
  `Get()`해야 하므로, `fn` 내부 로직이 with한 다른 값을 보고 "이 경우엔 self
  계산 자체가 필요 없다"고 판단해도 이미 늦음(예: `:With(noprint)`이고
  `noprint:Get() == true`면 앞단 계산을 통째로 생략하고 싶은 경우).
- **해결(사용자 확정)**: self도 raw 값이 아니라 **State 핸들 그 자체**를
  `fn`의 포지셔널 인자로 넘긴다 — `fn(self: State<T>)`, 내부에서
  `self:Get()`을 실제로 읽을 때만 계산이 트리거됨. with한 값과 동일한
  lazy 원칙을 self에도 그대로 적용 — 별도 `ComputeWithout` 변형은
  불필요, `Compute` 하나로 일관.
- **[정정, 2026-08-07] `.value`는 State/Source에서 제외, `:Get()`만 지원.**
  이전엔 `Get()`을 감싼 읽기 전용 계산 속성(`base/lifecycle-pattern.md`의
  `Connected`와 동일한 "저장되는 필드가 아니라 계산된 속성" 패턴)으로
  `.value`/`:Get()` 둘 다 지원하고 `.value`를 관용적 표기로 앞세웠으나,
  "관측해야 실체화된다"는 원칙이 가장 날카롭게 느껴져야 할 지점에서
  프로퍼티 문법이 그 느낌을 무디게 한다는 재검토 끝에 함수 호출
  `:Get()` 하나로 좁힘 — `:Set()`과의 동사 짝도 자연스러움. `.value`
  표기 자체는 폐기하지 않고 **Ref 전용으로 좁힘**(Ref는 lazy가 아니라
  값을 읽어도 계산이 트리거되지 않으므로 프로퍼티 문법이 정직함 — 이
  절 위쪽 "Ref 일반화" 절의 `.Value`가 그대로 유일한 존재가 됨, 이름
  충돌 자체가 사라져 별도 표기 정리 불필요).
- 예시 갱신: `store "key1":With(store "key2"):Compute(function(key1) return
  key1:Get() + store.key2:Get() end)` — `key1`은 이제 raw 숫자가 아니라
  State.

**[2026-08-12 세션 감사에서 확인] `:Compute` 콜백 인자에 `:Get()`을 빠뜨리는
실수가 반복되기 쉬움 — 실제로 `.claude/` 문서 예시 코드 4곳(`tag-plan.md`,
`slot-plan.md` 2곳, `base/tween-plan.md`)에서 발견·수정됨.** `fn(self,
...)`의 모든 인자가 raw 값이 아니라 lazy State 핸들이라는 원칙(바로 위 절)을
사람도 에이전트도 코드 작성 중에 잊기 쉬운 지점 — `:Compute`/`:With` 콜백
안에서 인자를 비교(`==`)/연산(`+`)/테이블에 담기 전에 항상 `:Get()`부터
거쳤는지 확인할 것. 예: `function(name) return name == "x" end`(버그) vs
`function(name) return name:Get() == "x" end`(올바름).

**State는 쓰기 대상이 아님 — 확정, Source는 독립 공개 프리미티브로 격상**

- `state:Get()`은 항상 읽기 전용. State에는 쓰기 API가 아예 없음. "State에
  직접 쓰기 API를 허용하면 다른 source에서 파생된 state에 직접 쓰기가
  가능해져 버린다"는 이전 우려는 이걸로 근본적으로 해소(그런 API 자체가
  없음).
- **[정정, 2026-08-06 후속 세션] 값을 쓰는 경로는 `store.key = value`
  (`__newindex`)가 아니라 `store.key:Set(value)`로 전환됨** — 이유와
  상세는 `base/store-semantics.md`의 "Store 값 설정 문법" 절 참고(요지:
  Source가 State를 만족하는 구조로 바뀌며 레코드 타입 읽기/쓰기 대칭을
  맞추려면 대입 문법을 포기해야 함 + `=`가 암시하는 "즉시 커밋"이 실제
  lazy 동작과 정서적으로 안 맞는다는 논거). 같은 문서의 "Source가 State를
  만족함" 절에 Source/State 서브타입 구조 전체가 정리돼 있음.
- **`Source`는 Store의 내부 구현 디테일이 아니라 별도의 가벼운 공개
  프리미티브로 노출** — Store는 다수의 source를 등록/관리하는 무거운
  구조라, 값 하나만 반응형으로 다루고 싶을 때 Store를 통째로 만드는 건
  비효율이라는 게 사용자 판단("store가 source 수십 개 만드는건 비효율이니
  둘이 다른 구현이라 봐도 될듯"). `Source(initial)` 류의 독립 생성자
  (정확한 이름은 구현 단계에서 확정)가 Store와 나란히 존재.
- **생성자 스타일 확정(2026-08-06 후속 세션): Kotlin Compose식 "타입
  이름 자체를 팩토리 함수로" — `Source(default)`, `Ref(default)`,
  `Store({defaults})`.** Ref도 예외 없이 이 스타일을 따름 — Ref가
  `Ref()`로 안 만들어질 특별한 이유는 없었고(이전 절에서 API 모양만
  다루고 생성자를 명시 안 해서 생긴 공백), `architecture.md`의 "복사
  구현 지양, 팩토리 함수로 대체" 원칙과도 정확히 일치. `Store({defaults})`도
  같은 스타일로 지원(`defaults`는 선택 — 안 주고 `Store()`만 호출해도
  됨, 순수 편의용 초기값 템플릿).
- **[보강, 2026-08-09 열한 번째 세션] `Source(default)`/`Ref(default)`의
  `default` 인자가 "선택"이라는 서술은 정확히는 `T`가 `nil`을 포함할 때만
  성립함 — 생략하면 실제로 `nil`이 그 자리를 채우기 때문.** `Source()`
  (무인자)는 `Source(nil)`과 동치라고 이미 명시돼 있으나, 이게 타입
  레벨에서 뭘 뜻하는지(`T`가 nilable이 아니면 타입과 실제 저장값이
  어긋난다는 것)는 지금까지 명시적으로 안 적혀 있었음. `Ref`도 마찬가지
  캐비엇이 있고 오히려 더 눈에 띄게 드러남 — `:Callback(fn)`은 등록
  즉시 그 시점 값으로 무조건 1회 호출되므로(미설정 상태여도 그 상태
  그대로 호출, 아래 `Ref` "바인드 방법" 절 참고), `default`를 생략한
  `Ref()`에 콜백을 걸면 그 콜백이 즉시 `nil`로 한 번 불림 — `T`가
  non-nilable이면 이 시점에 이미 타입 위반. 따라서 `default`를 생략해도
  되는 건 오직 `T`가 nilable(`T?`)로 선언된 경우뿐이라는 걸 문서 차원에서
  명시할 것(non-nilable `T`에 `default` 없이 생성하는 건 사용자 실수,
  타입으로 막을 수 있으면 막고 안 되면 UB로 문서 경고).
  **[정정, 2026-08-07]** 아래 두 문장은 이후 라운드에서 정정된 옛 서술 —
  실제 메커니즘·mutate 취급은 `base/store-semantics.md` "Source가 State를
  만족함" 절이 최종 소스: (a) "`__newindex`/`__index` 프록시로 감싸면
  됨"은 이후 `store.key = value` 쓰기 문법 자체가 `:Set()`으로 옮겨가며
  `__newindex`는 더 이상 관여 안 함(읽기 쪽 `__index`는 "없으면 그 자리에서
  Source를 만들어 저장"하는 lazy 생성 용도로 여전히 필요, 위 store-semantics.md
  참고). (b) "defaults 테이블 원본을 직접 mutate하는 건 UB로 둠"도 최신
  모델과 안 맞음 — `defaults`는 라이브 백킹 스토리지가 아니라 "아직 안
  만들어진 Source를 만들 때 참고하는 초기값 템플릿"으로만 쓰이므로, 생성
  후 원본을 바꿔도 문제없고 UB가 아님.

**Slot 생존 확인 — 별도 메커니즘 아님, `canExecute` 재사용으로 확정**

- `base/store-semantics.md`에 있던 "`isInit=false`면 허용, `isInit=true`+
  생존확인 거짓이면 불허" 분기 초안은 폐기. state-invalidate 리스너
  클로저도 `base/lifecycle-pattern.md`의 "생명 바인드 유틸"(canExecute
  predicate)로 등록하면, 발화 시 `canExecute(inst, value)`(2026-08-08 세션
  최종 시그니처) 하나만 확인하고 거짓이면
  그냥 no-op — `isInit` 분기라는 별도 개념 자체가 불필요(사용자 확정:
  "canExecute 하나로 통일").

**타입 추론 문제 — 확정(2026-08-04 3차 라운드)**

- `store "key"`(문자열 커링)로 `state<T>`를 오버로드 함수 타입으로 정확히
  추론하려는 시도는 포기하고, **`store.key`(dot-access)를 1급 경로로 확정**
  — Store 타입을 `{key: Source<number>, other: Source<string>}`류 평범한
  레코드 타입으로 지으면 일반 구조적 필드 타이핑으로 자동 해결되고, 문자열
  리터럴 narrowing 문제 자체가 안 생김([정정, 2026-08-06] 원래 `State<T>`
  필드로 적혀있었으나 Source가 State를 만족하는 구조로 바뀌며 `Source<T>`로
  갱신 — `store.key = value` 쓰기 문법이 `:Set()`으로 옮겨가 이 필드가
  더 이상 `__newindex`로 쓰이지 않으므로 읽기/쓰기 타입 대칭 문제도 같이
  해소됨, `base/store-semantics.md` "Source가 State를 만족함" 절 참고).
  `store "key"` 문자열 커링은 동적 키가 필요할 때 쓰는 미타입(`Source<any>`)
  폴백으로 격하.
- 이 패턴은 Store에만 국한되지 않고 **인스턴스 생성까지 관통하는 프로젝트
  전역 관습으로 확정**됨 — 단 이벤트는 이후 4차 라운드에서 이 관습의
  **유일한 예외**로 빠졌음(PA님 방식인 문자열 키+런타임 리플렉션으로 전환).
  아래 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절이 최신 확정 내용.

**`Pipe`(quad2-try 후보)는 폐기 확정** — 별도 `Pipe` 타입에 소유권/버전
가드를 넣어 재설계하는 대신, State 자체가 파이핑 결합체이고
`state(state)`로 분기하는 위 모델로 완전히 대체됨.

**`store.key` 레코드 필드 타이핑 — Luau 타입함수로 해결 확인
(2026-08-12 열일곱 번째 세션, `pre-implementation-audit.md` 1-10 해소).**

위 "타입 추론 문제" 절이 "`store.key`를 평범한 레코드 필드 타이핑으로 자동
해결"이라 서술했지만, `Store<T>`가 입력 `T`(예: `{ty: string}`)를 받아
`{ty: Source<string>}`류 결과 타입을 실제로 어떻게 합성하는지는 미검증으로
남아있었음. **Luau의 `type function`**(컴파일타임에 타입을 인자로 받아 새
타입을 조립하는 기능, https://luau.org/types/type-functions/ ,
https://luau.org/types-library/ — tbox에서도 이미 쓰이는 검증된 패턴)으로
정확히 풀림:

```luau
type function WrapStore(ty: type): type
    -- Source<T> 형태를 그대로 조립(:Get/:Set/:Compute/:With 등)
    local result = types.newtable()
    result:setproperty(types.singleton("Get"), types.newfunction(...))
    return result
end

type function ProcessStoreType(ty: type): type
    local props = ty:properties() :: { [type]: { read: type?, write: type? } }
    local result = types.newtable()
    for i, v in props do
        -- i는 프로퍼티 이름을 담은 singleton 타입, i:value()로 실제 문자열
        result:setproperty(i, WrapStore(v))
    end
    return result
end
```

`ProcessStoreType<{ty: string}>` → `{ty: Source<string>}`가 나옴 — 결과는
선언 시점에 이름 붙은 `Source<string>` 그 자체가 아니라 구조를 그대로 풀어낸
(flatten) 익명 타입이지만, **Luau는 이름이 아니라 "만족하는가"로 구조적
일치를 검사**하므로 문제없이 `Source<string>` 자리에 대입 가능 — 오히려 이
방식과 정확히 맞는 조합. 이걸로 `store.key`가 실제로 타입 명시 가능함이
확인돼 M0/M3 어느 시점에 검증해도 기술적으로 막힐 위험은 없음 —
`ROADMAP.md`의 M0/M3 배치를 강제로 바꿀 필요는 없어짐, 검증 난이도
문제였던 것만 해소.

**PA님 코드와의 교차검증(2026-08-04 4차 라운드) — 둘 다 기존 확정 유지**

`.claude/initreq/artworks/EventDrivenProgramming/`(Connection/Event/
Observable/Observer)을 조사한 결과, 두 지점에서 기존 확정과 실제로 다른
선택이 나와 재검토했으나 결론은 변경 없음. **이름 주의**: 아래에서 말하는
`Observer`는 PA님 코드의 클래스 이름(pub-sub, 8개 `subscribeXxx` 헬퍼)이고,
위 "`state:Observer(fn)`" 절에서 확정한 quad의 `Observer`와는 이름만
같을 뿐 무관한 별개 개념 — 이 절은 순수 역사적 교차검증 기록으로만 읽을 것.

- **전파 모델**: PA님의 pub-sub은 push-invalidate가 아니라 **push-값**
  (`Event:fire(...)`가 인자를 그대로 콜백에 전달, `Observable`의 `__newindex`가
  새 값을 실어 즉시 `changed:fire(key, value)`, dirty-flag/`Get()` pull 단계
  자체가 없음). 한때 "leaf(source 하나→sink 하나, 파생 없음)는 PA님처럼
  push-값으로 단순화하고 push-invalidate/pull-recompute는 실제 `:Compute`
  파생이 있을 때만 쓰자"는 이원화를 검토했으나 **기각** — invalidate+`Get()`
  방식도 leaf에서 딱히 더 복잡하지 않고(불리언 플래그 하나 + `Get()`/`emit`
  둘로 나뉘는 정도), 오히려 두 메커니즘을 병행하면 "leaf State가 나중에
  `:Compute`로 감싸일 때 두 메커니즘을 어떻게 연결하는가"라는 새 경계 문제가
  생겨 이원화가 더 복잡함. **결정적으로, PA님 코드엔 애초에 `:Compute`/`:With`
  같은 파생·합성 개념 자체가 없음** — quad-v2가 lazy pull을 도입한 이유(여러
  소비자가 하나의 파생 State를 공유할 때 오염 방지, 안 쓰이는 연산 스킵)를
  PA님 시스템은 처음부터 안 풀려던 문제라, 대등한 반례가 아니었음. **결론:
  push-invalidate/pull-recompute로 통일 유지, 변경 없음.** 사용자 최종 확인
  문구: "store 전파 처리는 우리 방식이 맞음. 이건 vide 에서 없었던것과
  동일함, [PA님] 저기도 디자인 상 해결 못하는 문제가 된거거든. 비 필요
  연산과 중복 연산을 지우는건 디자인 단계에서 구성할 일임. 우린 디자인
  단계부터 해당 문제를 해결하고 싶었던거야."
- **라이프사이클**: PA님 코드는 GC-native가 아니라 **전부 수동 해제**
  (`Connection.connected`는 계산 속성이 아니라 저장된 bool, `Observer`의
  8개 `subscribeXxx` 헬퍼 전부 명시적 `:unsubscribe()` 필요, weak table은
  `Observable`의 subject↔observable 캐시 한 곳뿐). rbvm 기반으로 확정한
  "GC 위임, 명시적 dispose 없음" 원칙과 반대 선택이라 재확인 질문했으나,
  **GC-native 유지로 확정** — 지금까지 이 정도 규모(명시적 dispose가 꼭
  필요할 만큼 큰 자원)를 요구하는 실제 사례가 없었다는 게 사용자 판단. 다만
  **완전히 막다른 길은 아님**을 기록해둠: rbvm처럼 관계를 양쪽 다 weak-keyed로
  두고 모든 걸 connection 람다에 담아 "연결이 살아있는 동안만 살아있게" 하는
  방식이면, 나중에 GC만으로 정말 부족한 케이스가 생겨도 그 connection을 얻어
  `disconnect()`하는 명시적 dispose 경로를 추가로 얹는 게 가능한 디자인 —
  지금 마일스톤에서는 필요 없어서 안 함(사용자: "필요하다면 dispose 핸들러를
  만들어주는 것도 가능한 디자인, 다만 지금까지 요구가 없었음"). (rbvm의
  GC-native 패턴이 실물에서 검증됐다는 근거는 `base/lifecycle-pattern.md` 상단
  참고 메모 참고.)

## quad2-try 리서치 결과 (완료) — 이전 시도에서 뭘 가져오고 뭘 버릴지

`.claude/initreq/quad2-try/out/quad-core`에 정확히 이 문제(Unix 파이프 영감의
State/스트림)를 다뤘던 이전 시도가 있어 조사함 — **확인된 죽은 접근(OOP 상속
`Base:Extends`/`--&` 커스텀 파서/Slot 빈 스텁/`Pipe` copy-on-write 절충안)은
절대 반복 조사하지 말 것**, 상세 근거와 "건질 만한 것"(`:With` 이름의
방증 등)은 `archive/quad2-try-research-findings-rejected.md` 참고 — 이
조사의 최종 결론은 이미 아래 "Store/State/Source 온톨로지" 절의 `state(state)`
조합 모델로 대체되어 있고 Slot은 `base/slot-plan.md`의 from-scratch 설계를
그대로 쓰면 됨(재조사 불필요).

## 확정된 것 (더 이상 열린 질문 아님)

- **핸들러 계약**: `isHandlable(inst,k,v)` + `priority` +
  `process(inst,k,v,index)` **3종**으로 확정 — tbox식 6-hook 세분화는 지금은
  안 함. 실제 구현하며 부족한 지점이 보이면 그때 hook 추가(점진적 확장).
  **[정정, 2026-08-13 다섯 번째 세션 — 이 항목이 갱신에서 누락돼 문서 상단
  "핸들러 계약" 절과 모순돼 있던 걸 같은 날 리뷰에서 발견]** 예전엔
  `process`(구 `bind`) + `retract`(구 `cleanup`) 4종이었으나, `retract`가
  별도 필드에서 **`process`의 반환값(retractor 클로저)** 으로 합쳐짐 —
  이름과 개념은 그대로 유효하고 자리만 옮겨온 것(위 "핸들러 계약" 절이
  정본).
- **Signal 클래스**: 안 만듦, 콜백 + `Connected` 계산 속성만(`base/
  lifecycle-pattern.md`).
- **Ref**: 도입 확정(위 절 참고), 용도는 "id 기반 조회 대체"가 아니라 "외부
  관리 instance를 점진적으로 다루기 위한 직접 참조 획득".

## base 유틸은 인터페이스, 실제 구현은 백엔드 팩토리가 주입 (2026-08-04 보강)

`base/lifecycle-pattern.md`가 말하는 "범용 유틸"(per-instance 상태 저장소,
생명 바인드 유틸)은 base가 직접 구현하는 게 아니라 **인터페이스만 정의** —
`inst`는 base 입장에선 `any`일 수 있음(다른 엔진일 수도 있으므로). 실제
구현은 `RobloxFactory(BaseModule)` 같은 팩토리 함수가 `BaseModule`을
뮤테이션해서 그 안에 실 구현체(`canExecute` 등)를 채워넣는 방식 — 사용자는
`quad-base`/`quad-roblox`를 각각 import해서 `const quad =
RobloxFactory(QuadBase)` 세 줄 정도로 직접 조립하면 됨(별도 번들 `quad`
패키지로 재수출할 필요 없음, 필요하면 만들어도 됨).

**확정(2026-08-04 3차 라운드)**: `RobloxFactory`를 같은 `BaseModule`에 여러
번 호출했을 때 — **같은 팩토리로 재호출하면 무시(no-op)**, hot-reload처럼
초기화 스크립트가 다시 도는 경우를 안전하게 만듦. **다른 팩토리
(`AnotherFactory` 등, 가상의 예)로 재호출하면 에러** — 이건 `base/module-lifecycle-plan.md`의 "bind는 유일 슬롯" 원칙(이미 구현체가 있는데 또
다른 구현체로 init하려 하면 오류)이 다루던 것과 정확히 같은 케이스, 이
문서의 이전 "무시" 잠정안과 그 문서의 "오류" 잠정안이 서로 모순되는 게
아니라 **같은 팩토리 재호출(무시) vs 다른 팩토리로 유일 슬롯 충돌(에러)이라는
서로 다른 케이스를 각각 가리키고 있었음**. 구현은 모듈 테이블에 "누가
초기화했는지" 마커(`_initializedBy = "roblox"`류, 정확한 이름은 구현 단계)만
두면 됨. 모듈 스코핑(`New()`, `base/architecture.md` 13번)과의 관계도 실은
열려있던 게 아니라 자연히 풀림 — `New()`가 생기면 각 인스턴스가 별도
테이블이 되므로 이 마커도 테이블별로 독립적으로 스코핑됨, 재설계 불필요.

## 인스턴스 생성 / 이벤트 네이밍 인체공학 — 확정(2026-08-04 3~4차 라운드, PA님 실 코드로 검증됨)

`Quad "Frame"`처럼 문자열로 인스턴스 종류를 지정하는 방식은 타입 추론이
어려움(위 온톨로지 절의 Luau 오버로드 문제와 같은 원인). 사용자가 실제
참고 코드를 `.claude/initreq/artworks/DeclarativeProgramming/
DeclarativeInstance.luau`(PA님 작성, UI 포함 전반적 설계 패턴을 시범 적용한
데모 모듈)에 공유해줘서 직접 확인 — **"DI"는 Dependency Injection이 아니라
"Declarative Instance"(선언형 인스턴스 생성)**.

**인스턴스 생성 — PA님 코드 그대로 채택**: 처음 제안했던 "필드=1급 타입
경로, 문자열=폴백"이라는 2트랙(`DI.Frame` vs `DI.New<<Frame>> "Frame"`) 구상
보다 실제로는 더 단순했음(`DeclarativeInstance.luau:104-160`) —
**제네릭 생성자 함수 하나(`new<ClassName>(className): from<index<UIInstances,
ClassName>>`)가 알려진 타입과 모르는 타입을 전부 커버**하고, 그중 UI에서 자주
쓰는 클래스 ~25개(`Frame`/`TextButton`/`UICorner` 등, `UIInstances` 타입
테이블에 등록된 것들)만 모듈 로드 시점에 **즉시(eager)** `constructor.Frame =
new("Frame")`처럼 필드로 미리 채워둠 — `__index` 메타메소드 지연 생성이
아니라 그냥 정적 테이블. quad-v2도 이 모양 그대로 채택: 하나의 제네릭
생성자 + 자주 쓰는 것만 정적으로 미리 바인딩.

**이벤트 바인딩 — `On.EventName` 도트액세스 안 씀, PA님 방식(평범한 문자열
키 + 런타임 리플렉션)으로 전환**: `DeclarativeInstance.luau:13-91`의
`assign(instance, key, value)`가 `ReflectionService:GetPropertiesOfClass`/
`GetEventsOfClass`로 클래스별 프로퍼티/이벤트 타입을 캐싱해두고, 키가
`RBXScriptSignal` 타입이면 자동으로 `instance[key]:Connect(value)`로 처리함
— `Frame { MouseButton1Click = fn }`처럼 별도 네임스페이스 없이 그냥 문자열
키로 씀. 이건 타입 안전성을 어느 정도 포기하는 대가지만(콜백 시그니처까지
Luau가 검증 못 함 — `apply<T,U>(instance: T, properties: U): T & U`가 스키마
검증 없이 구조적으로만 merge), 이미 UB로 남긴 "테이블 리터럴 안 키별 값
타입 자동 검증 불가"와 같은 급의 한계라 손해가 크지 않고, `On.` 접두어 없이
문법이 더 간결해짐 — **사용자 확정**("PA 님 방식 괜찮은듯. 타이핑은 인라인이
되긴 하겠지 정도면 괜찮다"). quad-v2 구현에서는 이 "키가 이벤트인가"
판별을 `isHandlable`로 감싼 pluggable 핸들러(`quad-roblox`가 `Reflection
Service` 기반으로 구현)로 두면 됨 — 별도 `On` 모듈/필드 접근 구조 자체가
불필요해짐.

**Store 쪽 dot-access는 그대로 유지**: `store.key`(1급 타입 경로)/
`store "key"`(문자열 커링, 동적 키 폴백)는 이벤트와 달리 실질적으로 Luau가
타입을 좁혀주는 이득이 있어서(Store 자체가 `{key: Source<number>, ...}`류
평범한 레코드 타입으로 지어짐[정정: 2026-08-06 후속 세션에서 필드 타입이
`State<T>`→`Source<T>`로 갱신, "Source가 State를 만족함" 절 참고]) 그대로
유지 — 이벤트만 예외였을 뿐, "정적으로 알려진 것=필드 접근" 원칙 자체가
깨진 건 아님.

**`GetPropertyChangedSignal`은 이 문자열 키 패턴이 안 통함 — 별도 `OnChange`
DI 키로 확정(2026-08-10 세션).** 이벤트는 `inst[key]`가 이미 Signal이라
그대로 `Connect`하면 되지만, `GetPropertyChangedSignal(name)`은 프로퍼티
이름을 인자로 받아야 하고 그 이름이 "값 세팅" 키 네임스페이스와 겹쳐서
평범한 문자열 키로는 세팅과 리스닝을 구분할 수 없음 — 상세는
`base/onchange-plan.md`.

**PA님 코드와 대조해서 재확인한 것(변경 없음)**:
- **OOP 회피 결정은 오히려 보강됨** — PA님의 `ObjectOrientedProgramming/
  class.luau`도 `setmetatable(methods, {__index = parent})` 체이닝 상속이라
  quad-v2가 피하기로 한 quad2-try `Base:Extends`와 같은 모양이고, 제네릭을
  파일마다 중첩해서 재선언해야 하는 보일러플레이트까지 동일하게 나타남.
- **Instance 태그는 CollectionService 직접 사용 그대로 유지** — PA님의
  `EventDrivenProgramming/Observer.luau`의 `subscribeTaggedInstance`도 얇은
  `CollectionService` 래퍼일 뿐. `DataOrientedProgramming/TagService.luau`는
  이것과 무관하게 plain-table 엔티티(비-Instance 데이터)용 커스텀 태그
  인덱스라 지금 quad-v2 스코프 밖 — Instance가 아닌 데이터에 태깅이 필요해질
  미래 시나리오를 위한 참고 자료로만 기록.
- **Store/State 전파 모델, 라이프사이클 — 둘 다 재검토 후 기존 확정 유지**
  (위 "Store/State/Source 온톨로지" 절의 "PA님 코드와의 교차검증" 참고).

## Tag/Attribute 특수 키 — 전용 문서로 분리됨 (2026-08-07 여덟 번째 세션)

`base/tag-plan.md`/`base/attribute-plan.md`로 이동 — 이 절이 다루던 타입
파라미터화 문제(`[AttributeKey<<boolean>> "name"]`(구 `Attribute<<boolean>>`)
vs `[BooleanAttribute "name"]`)뿐 아니라 `None`/`process`/`retract` 동작까지
확정 반영됨. UICorner 숏핸드/Tween처럼 "1 프리미티브 1 파일" 관례를 따라야
한다는 지적으로 분리. **[2026-08-11 아홉 번째 세션]** `attribute-plan.md`에
여러 Store를 한 번에 attribute로 묶는 그룹 `Attribute(...)` 프리미티브(`Tag`와
동형)가 추가되며, 단일 키 생성자는 이름 충돌 방지로 `AttributeKey<<T>>`로
리네임됨.

## `Brand` — 전용 문서로 분리됨 (2026-08-13 아홉 번째 세션)

런타임 nominal 타입 판별 통합 메커니즘(`Brand.set`/`Brand.get`, `isState`를
10종 branded 타입 전부로 일반화)은 **`base/brand-plan.md`로 분리**됨 —
이 문서가 3000줄에 육박해 분할한 1단계. 내용/결정은 안 바뀜.

## 남은 열린 질문 (`.claude/question.md`에도 취합)

> **⚠️ [2026-08-13 7차 감사 캐비엇, 13차 세션 갱신] 아래 "전부 확정됨"은
> 2026-08-13 **이전** 기준.** 지금 이 문서의 계약 중 **하나가 실제로
> 열려 있음** — `question.md` **0-Z**: 이 문서 최상단 ⚠️ 배너가 예고하는
> `hintValue`/`retractFrom` 재-dispatch 모델 교체. "API 표면 이름"이
> 아니라 **핵심 계약**이므로, 아래 목록만 보고 "이름만 남았다"고 읽지 말 것.
>
> (여기 같이 적혀 있던 **0-Y**(콜백의 lazy 핸들 계약)는 **해소됨** —
> 계약은 그대로 유지로 확정, 남은 건 Luau 자체의 한계라 우리가 할 게
> 없음. `base/typing-limits.md` 참고.)

이 문서의 핵심 설계 질문은 2026-08-04 세 라운드(전파 모델/`:Compute`/State
쓰기 금지/Slot 생존 확인 → dot-access 타입 추론/인스턴스·이벤트 네이밍/
`RobloxFactory` 재호출 가드)를 거치며 전부 확정됨. 그 라운드들 기준으로
남았던 건 순수 API 표면 이름뿐이었음:

- **`state()`/`Source()`/`Get()`/`DI`(또는 다른 이름) 등 정확한 함수·생성자·
  모듈 이름** — 방향은 전부 확정, 이름만 구현 단계에서 남음(`On` 모듈은
  이벤트 바인딩이 PA님 방식으로 바뀌며 아예 불필요해짐 — 위 "인스턴스 생성 /
  이벤트 네이밍" 절 참고).
- **매 `process()` 호출마다 우선순위 스캔 비용** — 실제 구현/벤치마크 단계에서
  확인 필요(디자인 자체는 확정됐으므로 더 이상 사용자 확인 대상 아님, 구현
  검증 대상).

**해소된 것**: "Store가 Store를 담는 경우 이중 해제(double-dispose) 방지가
필요한가"는 재검토 결과 질문 자체가 성립 안 함으로 결론 — 두 가지 독립적인
이유로 이중 해소됨. (1) 애초에 그런 경우를 만들지 않기로 확정(위 "Store가
Store를 저장 가능한가" 절, 2026-08-04 6차 — Store는 Source에 준하는 "시작점"
이라 다른 반응형 값을 담아 자동 연결되는 용도로 안 씀). (2) 설령 발생해도
State/Source 그래프 구독이 전부 weak-keyed GC-native(명시적 `dispose()` 호출이
아예 없음, `base/lifecycle-pattern.md`의 GC 위임 원칙 재사용)라 "같은 걸 두 번
해제"할 행위 자체가 존재하지 않음(GC는 멱등). "`:Compute`가 with한 값을 어떻게
읽는가"/"emit 필요 여부"도 전파 모델 확정으로 해소, `RobloxFactory` 중복
호출/충돌 시나리오·인스턴스 생성/이벤트 네이밍도 위 절에서 전부 확정.
