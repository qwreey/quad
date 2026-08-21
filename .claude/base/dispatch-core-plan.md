# 디스패치 코어 — Handler 계약 / Dispatch 체인 / 재디스패치 하강 diff

**상태**: base — 2026-08-13 열네 번째 세션에 `bind-system-plan.md`에서
분리(2단계 분할). 같은 세션에 `question.md` **0-A/0-Z**가 확정되어
**재디스패치 모델이 "철거 후 재구축"에서 "하강 diff"로 전면 교체**됐고,
그 재작성과 분할을 한 패스에서 같이 처리했음(같은 텍스트를 두 번 만지지
않기 위해 9차 세션이 의도적으로 미뤄뒀던 것 — 경위는 아래 "재디스패치
모델의 역사" 절, 뒤집힌 옛 모델 원문은
`archive/dispatch-hintvalue-model-reversed.md`).

**이 문서가 담는 것**: 핸들러 계약 / 확정된 디스패치 모델 / `None` 센티널 /
`Dispatch`가 프리미티브가 아닌 이유 / `chains` 인덱스 체인과
`Dispatch.retractFrom` / Handler 작성 체크리스트 / Length·Offset(형제
순서 보장) / store 바인드가 래핑이라는 결론.

**여기 없는 것**: `:With`/`:Compute` 등 반응형 값 조합과 Store/State/Source
온톨로지는 `base/bind-system-plan.md`, 개별 핸들러의 도메인 로직은
`base/tag-plan.md`/`attribute-plan.md`/`slot-plan.md`/`ref-plan.md`/
`event-plan.md`, 런타임 판별은 `base/brand-plan.md`.

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
- `process(inst, key, value, index): (nextValue: any?) -> ()` — 실제 처리
  수행(아래 "확정된 디스패치 모델"/"Dispatch 체인" 절 참고) 하고,
  **자기 자신이 방금 벌인 일을 무르는 1-인자 클로저를 반환**.
  v1/기존 논의에서 "bind"라 부르던 것과 동일한 역할 + 예전의 `retract`
  필드가 여기로 합쳐짐(**[전면 재정정, 2026-08-13 다섯 번째 세션]**,
  계기·근거는 아래 "Dispatch 체인" 절). 그 인자는 **`nil`(단순 철거)
  이거나, 같은 핸들러가 곧바로 처리할 새 값**이라는 게 계약 — 코퍼스
  전반에서 이 인자를 `hintValue`라고 부르는데 이는 타입이 보장되지 않던
  옛 모델에서 온 이름이고, 지금은 "힌트"가 아니라 보장된 값임에 유의
  (이름 자체는 `question.md` 용어 정리 대기열). **반환값 생략 불가 —
  정리할 게 없는 핸들러도 항상 `function() end`(no-op) 형태로 반환할 것** —
  `Dispatch.process`(아래 절)가 이 반환값을 `chains`에 저장해뒀다가
  나중에 정확히 이 클로저 하나만 호출해서 정리하므로(예전 "retract 필드
  생략 불가" 규칙과 같은 이유, 자리만 옮겨옴). **생략했을 때 실제로
  벌어지는 일**: 그 자리 슬롯이 완성되지 못해 `#list`가 Lua 명세상
  정의되지 않게 되고(`retractFrom`의 순회 시작점이 어긋남) 체인 추적이
  통째로 깨짐 — 그래서 `Dispatch.process`가 반환값 `nil`을 즉시 error로
  잡음(2026-08-13 7차 감사에서 조용히 삼키던 가드를 error로 바꾼 것,
  하강 diff 모델에서도 그대로 유지).
  **핸들러가 직접 자기 자신의 하위 위임(재귀 `Dispatch.process`로 만든
  것들)까지 클로저 안에서 다시 정리할 필요는 없음** — `Dispatch.
  retractFrom`의 순회 구조 자체가 항상 깊은 인덱스부터 먼저 정리하고
  나서 얕은 인덱스로 올라오므로, 이 클로저가 불릴 시점엔 자기보다
  아래(자기가 만들어낸 하위 위임)는 이미 전부 정리된 뒤임(아래
  "Dispatch 체인" 절 참고) — 클로저는 **오직 자기 자신의 직접
  자원**(Observer 구독 등)만 정리하면 됨.

  > **[용어 풀이, 2026-08-20 구현 전 QA 4라운드 `D-3`] "깊은 인덱스"가 뭘
  > 뜻하는가 — 그리고 설치와 철거는 실제로 반대 방향이 맞다.**
  > "깊다"는 **인덱스 숫자가 크다**는 뜻이다(트리 깊이가 아니라 **같은
  > `(inst,k)` 체인 안에서의 재귀 깊이**). `State<State<Tag>>`를 예로 들면:
  >
  > ```
  > (inst, k) 체인
  >   index 1 : StoreBind   ← 바깥 State를 구독. "얕음"
  >   index 2 : StoreBind   ← 안쪽 State를 구독(바깥이 재귀로 만든 것)
  >   index 3 : TagHandler  ← 최종 Tag를 실제로 반영. "깊음"
  > ```
  >
  > - **설치(`Dispatch.process`)는 1 → 2 → 3 순** — 사용자가 짚은 그대로.
  >   각 레벨이 값을 한 겹 벗겨 `index + 1`로 재귀하므로 인덱스가 커지는
  >   방향으로 진행한다.
  > - **철거(`Dispatch.retractFrom`)는 그 반대인 3 → 2 → 1 순이 맞다** —
  >   아래 "Dispatch 체인" 절의 의사코드가 `for i = #list, index, -1`로
  >   **꼬리부터 역순**으로 돈다. 즉 사용자가 되물은 *"달라질 때 5, 4, 3, 2
  >   … 순이 되는건 아니지?"*의 답은 **"맞다, 그 순서가 된다"** 이다.
  > - **왜 반대여야 하는가**: index 2의 `StoreBind`가 index 3의
  >   `TagHandler`를 *만들어낸* 주체다. 만든 쪽을 먼저 지우면 만들어진
  >   쪽을 정리할 주체가 사라진다 — 스택을 쌓은 역순으로 푸는 것과 같은
  >   이유(LIFO). 그래서 각 핸들러의 retractor는 자기가 재귀로 만든 하위
  >   인덱스를 쫓아갈 필요가 없다: **자기 차례가 왔을 땐 이미 아래가 다
  >   비어 있다.**
  > - **주의 — "3 → 2 → 1"은 한 `(inst,k)` 체인 안에서의 이야기다.**
  >   서로 다른 키(`(inst,k1)` vs `(inst,k2)`)는 완전히 별개 배열이고
  >   서로의 순서와 무관하다(아래 "인덱스의 의미" 항목).
  > - **⭐ [2026-08-20 `B-1`] "스택을 역순으로 푼다"는 `retractFrom`에만
  >   해당한다 — (A) 분기는 스택을 푸는 게 아니라 그 자리를 *교체*하는
  >   것이다.** 사용자 정리: *"같은 핸들러의 process로 retract 가 교체되는건,
  >   말 그대로 교체라 stack down 이 아니고 retractFrom 는 stack down 을
  >   수행한다."* 둘을 같은 말로 묶어 읽으면 안 된다:
  >   - **(A) 분기(같은 핸들러 재프로세스)** — `slot.retractor(v)` 하나만
  >     불리고 **아래(index+1 이하)는 전혀 안 건드린다.** 그 자리 하나가
  >     새 클로저로 갈아끼워질 뿐이라 순서 개념 자체가 없다.
  >   - **`retractFrom`(단순 철거)** — 그때만 꼬리부터 목표 인덱스까지
  >     **스택을 역순으로 푼다.**
  >   위 "자기 아래는 이미 정리된 뒤"라는 보장도 **`retractFrom` 경로의
  >   이야기**다 — (A) 분기에서 클로저가 불릴 땐 아래가 그대로 살아 있고,
  >   그게 바로 "깜빡임 없이 갈아끼우기"가 성립하는 이유다.

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
- **`HANDLER_PRIORITY_FALLBACK` — 최하위 밴드, "base가 제공하되 백엔드가
  덮어쓸 수 있는" 핸들러의 자리 (2026-08-13 열네 번째 세션 신설, 사용자
  제안).** **base 소속 핸들러가 전부 여기 오는 게 아님에 주의** —
  `StoreBind`/`NoneHandler`/`Leaf`처럼 디스패치 골격 자체인 것들은 여전히
  높은 우선순위여야 함(`StoreBind`가 프로퍼티 세터보다 먼저 매치돼야
  반응형 값이 언랩됨). `Tag`/
  `Attribute`처럼 **알고리즘은 엔진 무관이라 base가 소유하고 실제 효과만
  주입받는** 핸들러(아래 "base가 소유하는 핸들러와 주입되는 엔진 op" 절)는
  이 밴드에 등록한다. 그러면 특정 백엔드가 그 키/값을 자기 방식으로
  통째로 다르게 처리하고 싶을 때 **그냥 평범한 우선순위로 자기 핸들러를
  하나 더 등록하면 언제나 이김** — base 쪽을 비활성화하거나 등록 순서를
  신경 쓸 필요가 없음(사용자 표현: "위에서 처리되면 상관 없게 잘
  처리되니까"). base 핸들러가 실제로 매치되는 건 "아무도 그 자리를 안
  가져간 경우"뿐이므로, 주입 op이 없는 백엔드에서의 실패도 이 자리에서
  명확한 에러 하나로 수렴함(같은 절 참고).
- **매치 실패(`isHandlable`을 만족하는 핸들러가 하나도 없음)는 조용한
  무시 없이 즉시 `error`.** 에러 메시지엔 값의 `Brand`(있으면)와
  `typeof(v)`를 함께 출력하고, "quad-roblox 등 필요한 provider가
  초기화됐는지 확인하라"는 안내만 덧붙임 — 그 이상의 특수 분기는 두지
  않음(다른 라이브러리에서도 흔한 "매치 실패=에러" 패턴 그대로).
  **이걸로 `module-lifecycle-plan.md`의 "열린 질문이었던 것 — 전부
  해소됨" 절에 있는 "provider가 아직 주입 안 된 상태에서 dispatch가
  호출되면?" 케이스(`pre-implementation-audit.md`
  1-4)도 별도 분기 없이 자동으로 해소됨** — **backend가 직접 소유하는
  핸들러(`Property`/`Event`/`Slot`류)에 한해** provider 미주입 상태는
  결국 그 클래스를 다루는 핸들러가 레지스트리에 하나도 없는 상태이므로
  "매치 실패"와 정확히 같은 경로로 수렴함. **[한정, 2026-08-18 `/code-review
  high` — `D-7` 재역전과의 정합성]** `Tag`/`Attribute`처럼 **base가
  Fallback Handler를 자기 로드 시점에 스스로 등록하는 것**(위 문단,
  "base가 소유하는 핸들러와 주입되는 엔진 op" 절)은 이 일반화의 예외다 —
  백엔드가 하나도 없어도 그 Fallback Handler는 이미 레지스트리에 있으므로
  **매치는 되고**, 실패는 "매치 실패" 에러가 아니라 그 자리에서 실행되는
  주입 op 스텁의 명시적 에러(`addTag가 구현되지 않음...` 류)로 남
  — "provider 미주입"과 "매치 실패"가 **에러 경로 자체는 다르지만 둘
  다 명확한 에러로 수렴한다"**는 결론은 안 바뀜, 다만 오타 키/미지원
  조합과 provider 미주입을 구분할 필요가 없다는 문장은 backend 소유
  핸들러에만 해당한다.
- **디버그 모드 — 핸들러 등록/정렬 시점에 동률 감지 시 print 경고 +
  전체 핸들러 목록 조회 함수.** 우선순위는 핸들러 등록 시점에 정적으로
  sort되므로 동률 감지 자체는 그 시점에 공짜로 가능 — `priority`가 같은
  두 핸들러가 등록되면 콘솔에 경고를 찍되, **[요구 추가, 2026-08-18 구현 전
  QA] 무조건 찍는 게 아니라 모듈 표면의 불리언 플래그 `Quad.debug`(기본
  `false`)가 `true`일 때만 찍는다**(사용자: *"동률 print 는 라이브러리가
  debug 모드일 때만. (Quad.debug: boolean = default false) 식이고, true 로
  하면 디버깅 가능"*). `Quad.debug`는 **새 공개 API 표면**이라
  `base/module-lifecycle-plan.md`(모듈 표면)에도 반영이 필요하고,
  다중 인스턴스화(`New()`, `base/architecture.md` "확정된 결정" 13번) 시
  이 플래그가 인스턴스별인지 전역인지는 그때 같이 정한다.
  **[해소, 2026-08-20 구현 전 QA 4라운드 `D-8`] `Dispatch.listHandlers()`는
  `Quad.debug`와 무관하게 항상 호출 가능하다** — 옛 서술은 "같은 디버그 표면에
  속하는지 구현 시 정할 것"으로 열어뒀으나, 사용자 판정으로 닫힘: *"listHandlers
  는 항상 실행 가능. 유저가 필요하면 수행 시 목록들을 단순 반환해주고 출력하고
  싶다면 출력하는 용도임."* 즉 이 함수는 **아무것도 출력하지 않고 목록을 반환만
  하는 순수 조회**이고, 찍을지 말지는 호출한 쪽이 정한다 — 게이팅이 필요한 건
  "라이브러리가 스스로 콘솔에 쓰는" 동작(동률 경고 print)뿐이라 조회 함수는
  애초에 그 대상이 아니다.
  그래서 `Dispatch.listHandlers()`는 현재 등록된 전체 핸들러(이름/priority)를
  **반환**하는 함수로 둔다.
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
  3. **`realv`를 들고 `Dispatch.process(inst, k, realv, index + 1)`를 재귀
     호출 — 선행 철거는 하지 않음**(**[정정, 2026-08-13 열네 번째 세션]**
     옛 모델은 이 자리에서 `Dispatch.retractFrom(inst,k,index+1,realv)`를
     먼저 불렀으나 하강 diff로 폐기됨. 정확한 메커니즘은 아래 "Dispatch
     체인" 절, 2026-08-08 세 번째 세션에 처음 확정, 2026-08-13 다섯 번째
     세션에 인덱스 기반으로 재정정 — 오케스트레이터
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
  "quad는 자신이 만든 Instance의 라이프사이클" 절의 원칙 참고).
  - 일반 프로퍼티는 애초에 "unset" 개념이 없음(`nil`로 셋하는 것도 그냥 셋
    동작) — 그래서 프로퍼티 핸들러는 보통 no-op 클로저(`function() end`)만
    반환하면 됨.
  - **[정정 이력, 2026-08-12 열한 번째 → 2026-08-13 다섯 번째 → 열네 번째
    세션] 이 클로저는 "핸들러 타입이 바뀔 때만" 불리는 게 아니라, store
    바인드가 재발행될 때마다(값이 뭐로 바뀌든) 항상 불림** — 다만 **누가
    부르는지가 열네 번째 세션에 바뀌었음**: 옛 모델에선 `StoreBind`가
    재-dispatch 전에 무조건 `retractFrom`을 때려서 자기 밑을 통째로
    비웠고, 지금은 `Dispatch.process`가 핸들러를 비교해 **같으면 그 자리
    클로저에 새 값을 넘기고(아래를 안 건드림), 다르면 그 자리부터 아래를
    전량 철거**함(아래 "Dispatch 체인" 절 (A)/(B) 분기). **호출 빈도는
    그대로, 아래 체인이 매번 통째로 재구축되지 않는다는 점만 달라짐** —
    그래서 깜빡임 방지가 깊은 체인에서도 유지됨. 한때 "핸들러가 안
    바뀌면 retract 없이 process가 diff"라고 적혀 있던 서술은 그때도
    틀렸고 지금 모델과도 다름(지금은 **핸들러가 안 바뀌어도 클로저는
    불리되, 그 클로저가 새 값을 받아 스스로 전이를 처리**함) — 옛 오류의
    상세 경위는 `archive/retract-always-fires-reversed.md`.
  - **정정된 원칙 — 대부분의 핸들러는 이 반복 호출에서 실제로 할 일이
    없어(일반 프로퍼티처럼 값을 그냥 덮어쓰면 끝이라 "unset" 개념 자체가
    없음) 반환하는 클로저가 사실상 no-op일 뿐, "타입이 안 바뀌면 아예
    안 불린다"는 뜻이 아님.** `Tag`/`Ref`/`Slot`/`Attribute`처럼 **여러
    위치가 하나의 실제 리소스(엔진 attribute/tag/mounted 서브트리 등)를
    공유하거나, 값 자체가 정리가 필요한 상태를 들고 있는** 핸들러는,
    이 클로저가 매번 불려도 **"이전 값이 지금 들어오는 새 값과 사실상
    같은지/그 새 값이 여전히 이 자원을 필요로 하는지"를 인자로 받은 새
    값으로 판단해 실제 엔진 호출만 skip**하는 방식으로 대응해야 함 —
    `Tag`의 `Contains` 비교, `Ref`/`Slot`의 identity 비교가 그 예.
    **인자를 반드시 `nil`로 가정하면 절대 안 됨**(대체하는 새 값 그
    자체일 수 있음). 반대로 **타입은 이제 보장됨** — 값이 넘어오는 건
    같은 핸들러로 재프로세스될 때뿐이라 그 값은 정의상 자기
    `isHandlable`을 만족함(아래 "Dispatch 체인" 절).
  - **자연스러운 분업**: 여러 위치가 자원을 공유하는 핸들러는 대개
    "반환한 클로저가 이전 기여를 걷어내고(실제 해제는 힌트로 skip
    가능), `process`가 새 기여를 등록한다"는 모양으로 깔끔히 갈림 —
    `process` 쪽에 별도 old-vs-new diff가 필요 없어짐(그 diff를 클로저가
    이미 통째로, 매번 정확하게 해주므로). `Tag(...)`↔`nil`, `Attribute`의
    그룹이 이름을 놓는 경우도 이 분업의 자연스러운 특수 케이스일 뿐, 별도
    패턴이 아님 — 상세 구현은 `base/tag-plan.md`/`base/attribute-plan.md`
    "이름 소유권" 절, `Ref`는 아래 "`Ref`의 retract" 절, `Slot`은
    `slot-plan.md` "Slot과 Store 바인드의 관계" 절 참고.
  - **[일반 규칙, 2026-08-13 열네 번째 세션에 폐지] 옛 "클로저 인자는
    타입 보장이 안 되니 `isX(hintValue)` 가드부터" 규칙은 없어졌음** —
    그 규칙은 힌트가 `None`/`State`/`Tween` 래퍼로 오염될 수 있던 옛
    철거-선행 모델을 메우던 임시방편이었고, 하강 diff에선 오염 경로 자체가
    구조적으로 없음(아래 "Dispatch 체인" 절). 지금 필요한 구분은
    **`nil`이냐 아니냐 하나뿐**. 방어 가드를 남겨둬도 무해하지만 죽은
    코드이고, 반대로 **그 가드가 있어야만 정확한 코드는 이제 없음**.
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
  프로퍼티/이벤트/특수 키) 나중(2026-08-07 세 번째 세션).** Luau
  테이블을 `pairs`/제네릭 `for`로 순회하면 실제로 배열 파트가 해시 파트보다
  먼저 나옴(`for i, v in {a=1, 2, b=3} do print(i,v) end` → `1 2`, `a 1`,
  `b 3` 순서 — 사용자가 직접 확인). 이 관찰된 동작에 그냥 얹혀가지 않고,
  **base 드라이버가 이 순서를 계약으로 보장**한다 — 배열 슬롯에 놓인 어떤
  값이든 모든 프로퍼티/이벤트 세팅보다 항상 먼저 처리된다.

  **⚠️ [구현 방식 정정, 2026-08-21 구현 전 QA 4라운드 `F-4-1`] "계약으로
  보장한다"와 "루프를 두 번 돈다"는 다른 얘기다 — 실제 구현은 일반화 `for`
  **한 번**이다.** 옛 서술은 "명시적으로 두 패스로 나눠 돌기로 계약화"라고
  적어 **구현까지 2회 순회로 못박은 것처럼** 읽혔고, 실제로 M0 스파이크
  `01`도 숫자 `for` + 일반화 `for` 두 루프로 짜여 있었다. 사용자 판정으로
  단일 순회로 정정: *"ipairs, pairs 를 따로 사용하게 되는게 아닌 단순
  일반화 for 로써 얻어지는게 맞는 상태라면, 맞는 구현이다 … `__pairs`/
  `__ipairs` 직접 구현체를 담은 ud 등을 받는 `flattened` 는 없고, luau
  테이블만 사용하는게 맞음."*
  - **`flattened`는 항상 평범한 Luau 테이블이다** — props는 사용자가 쓴
    Lua 테이블 리터럴에서 오고, `flatten`도 그걸 제자리에서 뮤테이션할 뿐
    (`base/modifier-plan.md`의 "flatten의 정확한 형태" 절). 메타테이블로
    순회를 갈아끼운 userdata 같은 게 들어올 경로가 **없다.**
  - **그래서 일반화 `for k, v in flattened do`가 배열 → 해시 순서를 그대로
    준다** — 두 층위는 `type(k) == "number"`로 가르면 된다. 순회 1회 절약.
  - **옛 근거 (1)은 과했다** — "다른 백엔드가 props를 Lua 테이블이 아닌
    자료구조로 표현할 수도"는 **`inst`에는 해당해도 `flattened`에는 해당하지
    않는다**(백엔드가 뭐든 사용자는 Luau로 props를 쓴다). 근거 (2)(숫자/문자열
    키를 어차피 다르게 취급해야 함)는 그대로 유효하고, 그건 **한 루프 안의
    분기**로 충분하다.
  - **계약 자체는 안 바뀐다** — "배열 파트 전체가 해시 파트보다 먼저"는 여전히
    base가 보장하는 것이고, 백엔드가 자기 드라이버를 짜더라도 지켜야 한다.
    바뀐 건 quad-base 자신의 구현이 그 보장을 **몇 번의 순회로 얻는가**뿐.
  - **`nil`-hole 위험은 어느 방식이든 동일** — 구멍이 생기면 숫자 키 일부가
    해시 파트로 밀려 순서가 섞이는데, `#flattened`를 쓰던 옛 방식도 똑같이
    깨진다. 방어는 그대로 `02`/`06` 스파이크의 nil-hole 규율(`None` 관용구)에
    맡긴다.
  - **⚠️ 스파이크 `01` 재작성 필요** — `luau-test/rewrite-required/01-two-pass-array-hash-order.luau`가
    두 루프 버전이라 지금 계약의 구현과 안 맞는다. 단일 일반화 `for` 버전으로
    재작성하면서 **"배열 파트 전체가 해시보다 먼저 + 배열 안에서는 index
    순서"** 를 그대로 확인할 것.
  **[정정, 2026-08-18 구현 전 QA] `PreRef`/`PostRef`는 이 보장 위에서
  성립하는 게 아니다** — 옛 서술은 `ref-plan.md`의 "PreRef" 절이 "이 보장
  위에서 성립"한다고 적었는데, 실제로는 **두 패스 순회보다 더 위의 별도
  pre-pass for 문**에서 먼저 처리되고 `flattened`에는 소진
  마커(`ProcessedPreRef`/`ProcessedPostRef`)만 남는다(사용자: *"preref 랑
  postref 는 정확히는 다른, 더 위에 있는 for 문에서 처리되고"*). 두 보장은
  **서로 독립**이다 — `PreRef`가 먼저 도는 건 배열 파트 우선 규칙 때문이
  아니라 pre-pass가 따로 있기 때문. 일반 `Ref`(pre-pass 대상이 아닌 것)가
  프로퍼티보다 먼저 처리되는 것은 위 보장 그대로 유효.
  **[실측 완료, 2026-08-19 M0 — 이후 `F-4-1`로 무효화, 지금은
  `rewrite-required/`]** `luau-test/01-two-pass-array-hash-order.luau`가
  두 패스 드라이버를 최소 재현해 "array pass 전체가 항상 hash pass보다 먼저,
  array pass 안에서는 index 순서 정확" 을 확인함 — "M0에서 검증할 것"이던
  항목은 닫혔다.

  **⚠️ [혼동 방지, 2026-08-20 구현 전 QA 4라운드 `D-10`] 이 실측은 "Luau가
  이 순서를 주는가"를 확인한 게 아니다.** 사용자 지적대로 **Luau의 일반화된
  반복 `for`는 이미 배열 파트를 먼저 훑고 해시 파트로 넘어간다** — 그건
  의심한 적이 없고, 2026-08-07에 사용자가 REPL로 직접 확인한 관찰이기도
  하다(`for i,v in {a=1, 2, b=3} do end` → `1,2` 다음 `a,b`).
  **그런데도 base 드라이버가 이 순서를 *계약*으로 들고 있는 이유는 순서를
  못 믿어서가 아니다** — **⚠️ [2026-08-21 `F-4-1` 이후 정정]** 여기 한때
  이유가 둘("이식성" + "구분 비용이 이미 듦")이라고 적혀 있었으나, **위
  `F-4-1` 정정 문단이 이식성 논거를 이미 기각했다**(`flattened`는 항상
  사용자가 Luau로 쓴 평범한 테이블이라, 다른 백엔드가 와도 이 자료구조는
  안 바뀐다 — 백엔드에 따라 달라지는 건 `inst`뿐). 남는 이유는 하나다:
  **숫자 키와 문자열 키를 어차피 다른 의미로 처리해야 하므로, 순서까지
  계약으로 고정하는 건 거의 공짜다.** 그리고 그 계약을 얻는 데 필요한
  구현은 **두 패스가 아니라 한 루프 안의 `type(k) == "number"` 분기**다.

  **⚠️ [2026-08-22 정정] `F-4-1` 이후로는 "base가 언어 동작에 안 기댄다"고
  말할 수 없다.** 여기 한때 *"스파이크 `01`이 검증한 건 '우리가 짠 두 패스
  드라이버가 계약대로 도는가'이지 언어 동작이 아니다"*, *"base는 이 우연한
  동작에 기대지 않고 명시적으로 강제한다"*라고 적혀 있었는데, **단일 일반화
  `for` 구현은 정확히 그 언어 동작에 기대는 구현이다.** 지금 정확한 서술은:
  - base는 배열→해시 순서를 **계약으로 약속**한다(다른 백엔드가 자기
    드라이버를 짜도 지켜야 한다).
  - quad-base 자신은 그 약속을 **Luau 일반화 `for`의 순회 순서에 기대어**
    지킨다 — 그게 `F-4-1`이 확정한 구현이다.
  - 그래서 **재작성될 `01`이 검증할 것은 언어 동작 그 자체**다("일반화 `for`가
    배열 파트 전체를 해시보다 먼저, 배열 안에서는 index 순서로 주는가").
    옛 `01`은 두 루프 드라이버를 최소 재현한 것이라 이 질문을 안 물었다.
  - **⚠️ 따라서 `nil`-hole 방어를 "계약이 보장하니 불필요"로 생략하면 안
    된다** — 구멍이 나면 계약 위반이 아니라 **전제 위반**이라 계약이
    지켜줄 수가 없다. 구체적인 깨짐 방식과 방어 위치는 위 "`nil`-hole
    위험은 어느 방식이든 동일" 항목이 소스.

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
  **[재설계, 2026-08-18 구현 전 QA] `NoneHandler`는 해시 파트 전용이
  아니고, `Dispatch.drive`는 `None`을 건너뛰지 않는다.** 옛 서술은
  "배열 파트의 `None`은 두 패스 루프가 `Dispatch.process`를 거치지 않고
  바로 건너뛴다"였는데, 그 전제 자체가 거짓이었음 — 리터럴
  `Frame{None}`만 생각하면 루프가 걸러내면 그만이지만
  **`Frame{ State<Slot|None> }`처럼 반응형 값이 `None`을 내놓으면 그
  `None`은 `StoreBind`의 재귀를 타고 `Dispatch.process`에 그대로
  도착**하기 때문. 사용자 판정: *"drive 는 v == None 인지 확인 안하고
  그냥 프로세스 태우는게 가장 적절한 처리로 보임"*. 따라서:
  - **`Dispatch.drive`에 `None` 특수 분기는 없다** — 배열이든 해시든
    모든 `(k,v)`가 `Dispatch.process(inst,k,v,1)`을 탄다.
  - **`NoneHandler`가 하는 일은 재귀 하나뿐** — `v == None`을 매치해
    `Dispatch.process(inst, k, nil, index+1)`로 내려보내는 것. 배열/해시
    구분도 하지 않는다.
  - **실질 정리(그리고 `setLength(0)`/`setOffsetSource(None)` 등록)는
    아래 `NilHandler`가 맡는다** — 사용자 선택(2026-08-18): *"NoneHandler는
    재귀만, NilHandler가 실질 담당"*. 즉 배열 자리가 비는 처리 로직은
    `None` 경로든 진짜 `nil` 경로든 **한 곳에만** 있다.
  - **`process` 자체가 이전 것을 걷어낸다** — `Tag` → `None` 전환에서
    이전 `Tag` 기여가 실제로 사라져야 하는데, 이건 하강 diff가 자동으로
    해준다(핸들러가 `TagHandler`에서 `NoneHandler`로 바뀌므로 아래
    "Dispatch 체인" 절 (B) 분기가 `retractFrom`을 부름). `NoneHandler`가
    반환하는 retractor 자체는 no-op이어도 된다.

  **`ProcessedPreRef`/`ProcessedPostRef`는 그대로 별개다** — pre-pass가
  소진시킨 자리는 `None`이 아니라 전용 센티널로 채워지고 전용 nop
  핸들러(`ProcessedPreRefHandler`/`ProcessedPostRefHandler`,
  `base/ref-plan.md`의 "PreRef"/"`PostRef`" 절)가 정상 `Dispatch.process`
  경로에서 캐치한다. 예전엔 "원래부터 빈 자리"와 "한때 PreRef였다가 소진된
  자리"가 똑같이 `None`으로 뭉뚱그려져 등록 책임 소재가 불분명한 갭이
  있었고(2026-08-14 첫 번째 세션 조사), 지금은 서로 다른 센티널로 명확히
  분리돼 있음.

  `NoneHandler.isHandlable`은 `v == None`(센티널 자체)을 잡는 것이지
  `v == nil`이 아님 — 진짜 `nil`은 테이블 순회로 나올 수 없다는 게
  이 문제의 출발점이었으므로, 매치 대상은 항상 `None` 마커(반응형 값이
  내놓는 진짜 `nil`은 아래 `NilHandler`가 받는다).
  `Dispatch.process(inst, k, nil)`로 재귀 호출하는 순간 `None`은 더 이상
  존재하지 않고 진짜 `nil`이 되므로, 다음 우선순위 스캔은 자연히 그
  `nil`을 담당하는 핸들러로 흘러감 — 배열 자리(`k`가 숫자)면 `NilHandler`,
  해시 자리면 키 `k`를 원래 담당하던 핸들러(프로퍼티/이벤트/UI shorthand
  등)로. `StoreBind` 핸들러가 `realv`를 들고 재귀하면 자연히 다음 핸들러로
  좁혀지는 것과 정확히 같은 원리, 무한루프 걱정도 동일하게 없음.
- **`Dispatch.process`/`Handler.process` 이름 겹침 — 소유자 네임스페이싱으로
  해소, 새 이름 발명 안 함 (2026-08-07 여덟 번째 세션 후속).** 원래
  "확정된 디스패치 모델" 절은 "스캔+실행"과 "매치된 핸들러 자신의 처리
  로직" 둘 다 그냥 `process`라고 불러서 이름이 겹쳤음 — 이제 두 계층을
  명시적으로 분리:
  - `Dispatch.getHandler(inst,k,v): Handler?` — 순수 스캔(`handler.isHandlable(inst,k,v)`+
    `priority`), 부작용 없음.
  - `Dispatch.process(inst,k,v,index)` — 오케스트레이터: `getHandler`로
    새 핸들러를 고른 뒤 **그 인덱스에 이미 있던 핸들러와 비교** → 같으면
    그 자리 클로저에 새 값을 넘기고 같은 핸들러의 `.process`를 다시 불러
    자리를 교체, 다르면 그 자리부터 아래를 전량 철거하고 새로 설치. 즉
    **"이전 핸들러와 다르면 철거"라는 diff는 `Dispatch.process` 자신의
    일**(**[정정, 2026-08-13 열네 번째 세션]** 옛 모델에선 반대로 래핑
    핸들러가 재-dispatch 전에 스스로 `retractFrom`을 부르는 책임을 졌고,
    그게 힌트 오염의 원인이었음 — 아래 "Dispatch 체인" 절).
  - `Dispatch.addHandler(handler: Handler)` — 핸들러를 우선순위 레지스트리에
    등록. `Dispatch.process`/`getHandler`와 마찬가지로 base엔 인터페이스만
    있고, quad-roblox의 concrete Handler들(PropertyHandler/EventHandler/
    OnChangeHandler/UICornerHandler 등)은 팩토리가 `BaseModule`을
    뮤테이션하는 시점에 이걸로 등록됨(아래 "base 유틸은 인터페이스" 절과
    같은 패턴, 새 메커니즘 아님). **`Tag`/`Attribute`의 base 소유
    Fallback Handler들(`TagFallbackHandler` 등)은 이와 달리 quad-base
    자신이 등록함**(**[재역전, 2026-08-18 구현 전 QA]** — 백엔드가 하나도
    안 붙은 상태에서도 안내 에러 경로가 돌아야 하기 때문), 상세는 아래
    "base가 소유하는 핸들러와 주입되는 엔진 op" 절.
  - Handler 자신의 필드는 계속 `process`/`retract`(이미 확정된 이름,
    `question.md`에 "특별한 문제 없음"으로 못박혀 있어 재검토 대상 아님) —
    겹침은 실제 런타임 충돌이 아니라 프로즈 표기 문제였을 뿐이라, 항상
    소유자를 명시(`Dispatch.process` vs `handler.process`)하는 것으로 해소.
  - **base 드라이버 루프 자신의 이름은 `Dispatch.drive(inst, flattened)`로
    확정** — 이미 위 "props 순회 순서" 절이 이걸 비공식적으로 "base
    디스패치 드라이버"라고 불러왔던 걸 그대로 동사화(`apply`는 "Dispatch를
    뮤테이션해서 결과를 낸다"는 어감이라 기각 — 사용자 판단). `inst`와
    flatten된 props 테이블을 받아 배열 파트(children/Ref) 먼저, 해시
    파트(프로퍼티/이벤트) 나중이라는 **순서 계약대로** 각 `(k,v)`에
    `Dispatch.process(inst, k, v, 1)`을 호출하는 게 이 함수의 본체
    (**[2026-08-21 `F-4-1`]** 그 계약을 얻는 구현은 두 루프가 아니라
    **단일 일반화 `for` + `type(k) == "number"` 분기** — 위 `F-4-1` 정정
    문단).
    **[2026-08-14 아홉 번째 세션] 이 본체 루프 앞뒤에 `Ref` 계열 훅 처리가
    붙음** — 앞에는 `PreRef`/`PostRef`를 한 번에 훑는 pre-pass(`PreRef`는
    그 자리에서 fire, `PostRef`는 이 호출에만 로컬인 `postRefList`에 적재만
    하고 둘 다 전용 센티널로 소진), 뒤에는 그 `postRefList`를 순회하며 각
    `PostRef`를 fire하는 짧은 루프. 둘 다 배열 재순회가 아니라 pre-pass
    하나 + 실제 `PostRef` 개수만큼의 목록 순회라 비용이 작음 — 상세는
    `base/ref-plan.md`의 "`PostRef`" 절.
    **[2026-08-18 구현 전 QA 2라운드 후속, `RC-1` 해결] 배열 파트 순회
    전체를 `inst` 전용 `Blocker`로 감싼다** — 순회 시작 전에
    `Relate(inst)`에 lazy 생성한 Blocker를 `:On()`하고, 배열 파트 순회가
    (pre-pass/post-pass 포함) 전부 끝나면 `:OffWithoutEmit()` 한 뒤
    `recompute(inst, bk)`를 명시적으로 1회 호출 — 상세 근거·`setLength`/
    `setOffsetSource`가 이 Blocker를 어떻게 쓰는지는 아래 "배치 등록을
    안전하게 만드는 Blocker 게이팅" 절이 소스.
    **진입 인덱스는 항상 `1`**(2026-08-13 감사에서 명시화 — 인덱스 도입
    후에도 이 자리만 인자가 안 적혀 있었음) — `drive`는 그 키의 체인을
    처음 여는 자리이므로 "다른 키로 위임할 때는 그 키의 재귀 깊이와
    무관하게 항상 1부터"(아래 "Dispatch 체인" 절)라는 규칙의 가장 기본
    사례. 같은 키가 두 번 나올 수 없는 테이블 순회라 이 루프 자신이
    한 키를 두 번 여는 일은 없음(다만 그룹 `Attribute`가 배열 파트에서
    이미 관리 중인 *이름*을 해시 파트 직접 쓰기가 다시 건드리는 건
    별개 문제이고, 그건 Attribute 자신의 이름 claim이 즉시 error로
    잡음 — `base/attribute-plan.md` "이름 소유권" 절).
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

### `NilHandler` — 배열 자리의 진짜 `nil`을 받는 짝 핸들러 (2026-08-18 신설, 사용자 요구)

**왜 필요한가**: 반응형 값이 `None`이 아니라 **진짜 `nil`** 을 내놓는
경우(`State<Slot|nil>`)도 정상 동작해야 한다는 사용자 요구. `None`을
쓰라고 강제하지 않는다 — *"State<Slot|None> 일 수도 있지만,
State<Slot|nil> 이여도 작동은 함"*.

```lua
NilHandler.priority = <매우 높음>
NilHandler.isHandlable(inst, k, v) = (type(k) == "number" and v == nil)
function NilHandler.process(inst, k, v, index)
    -- 이 자리는 아무것도 마운트하지 않는다 — 순서 계산에서 빠지도록 등록만 한다.
    -- 순서 주의: setOffsetSource가 먼저, setLength가 나중(아래 "해제(그 자리가
    -- 더 이상 기여하지 않게 될 때)는 `setOffsetSource(...,None)`" 절의 계약 —
    -- setLength가 끝에서 gatedRecompute를 경유해 recompute를 돌리므로
    -- 반대로 하면 죽는 중인 서브트리의 Source에 :Set()이 날아간다).
    -- [2026-08-18 감사에서 순서 정정]
    Dispatch.setOffsetSource(inst, k, None)
    Dispatch.setLength(inst, k, 0)
    return function() end
end
```

- **매치 범위는 `k`가 숫자인 자리로 한정** — 해시 자리의 `nil`은 그 키를
  원래 담당하던 핸들러(프로퍼티/이벤트)의 몫이다(`None` 재귀가 도착하는
  기존 경로 그대로, 위 절). 이벤트 키에서 `nil`이 disconnect를 뜻한다는
  규정은 `base/event-plan.md`가 소스.
- **재귀는 하지 않는다** — 이미 `nil`이라 더 내려보낼 곳이 없다.
  `NoneHandler`가 재귀만 담당하고 여기로 흘려보내므로, 배열 자리가 비는
  처리 로직은 **이 한 곳에만** 있다(사용자 선택, 2026-08-18).
- **호출 순서는 `setOffsetSource` → `setLength`** — 아래 "해제(그 자리가 더
  이상 기여하지 않게 될 때)는 `setOffsetSource(...,None)`" 절이 계약으로
  고정해둔 순서를 그대로 따른다. (`base/ref-plan.md`의
  `ProcessedPreRefHandler`/`ProcessedPostRefHandler` 의사코드는 아직 반대
  순서로 적혀 있음 — 이 세션 이전부터 있던 것이라 같이 고쳤다.)
- **`setLength(0)` / `setOffsetSource(None)`의 비대칭은 의도된 것** —
  타입이 각각 `number | State<number>`와 `Source<number> | None`이라서
  (`base/ref-plan.md`의 "왜 `None`이 아니라 `nil`인가" 절, 아래
  "Length/Offset" 절).
- **retractor는 no-op이어도 된다** — 이전 것의 철거는 하강 diff가
  `retractFrom`으로 해준다(위 `NoneHandler` 항목과 같은 이유).
- **"중간 노드는 `inst`에 부작용을 가하지 않는다"(아래 "Dispatch 체인" 절)와
  충돌하지 않는다** — `setLength`/`setOffsetSource`는 `inst`의 프로퍼티를
  건드리는 게 아니라 Dispatch 자신의 순서 부기이고, 애초에 `NilHandler`는
  재위임을 하지 않는 **말단** 핸들러다.

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
  풀림.** (**[재정정, 2026-08-19]** 이 헤딩을 한때 `Quad()`로 바꿨던 게
  틀렸음 — `New()`가 맞는 이름, `architecture.md` "확정된 결정" 13번의
  재정정이 소스. 요지: `Quad`(`require`의 반환값)는 이미 만들어진 기본
  인스턴스이고, 그 안의 `New` 필드를 명시적으로 호출해야만 별도의 새
  Quad 네임스페이스가 생긴다 — "그냥 `Quad()`를 부르면 매번 새 인스턴스"가
  아니다.) v1처럼 `require`를 감싸 `Init(QuadId?)`로 격리 인스턴스를 만드는
  방식은 안 씀(위 "확정된 것" 절 — id 기반 조회 자체가 Ref로 대체되며
  기각됨). 대신 이미 확정된 "base 유틸은 인터페이스, 실제 구현은 팩토리가
  `BaseModule`을 뮤테이션해서 주입"(`RobloxFactory(BaseModule)`) 패턴을
  그대로 따름 — Dispatch의 handler 레지스트리도 `BaseModule` 테이블에
  딸린 state 중 하나일 뿐이라, `_initializedBy` 마커에 대해 이미 확정된
  것과 완전히 같은 논리가 적용됨(위 "base 유틸은 인터페이스" 절, "`New()`가
  실제로 호출되면 그 호출이 만드는 인스턴스가 별도 테이블이 되므로 이
  마커도 테이블별로 독립적으로 스코핑됨" — 단 아래 "[한정]" 문단대로 코드
  손질은 필요, 재설계까지는 불필요). 다중 인스턴스화가 실제로 생기면 그
  시점에 BaseModule 전체를 인스턴스별 테이블로 만드는 메커니즘에 Dispatch도
  자연히 같이 딸려가고, 호출부는 `module.Dispatch.process(...)`처럼 그
  인스턴스 테이블을 통해 접근하게 됨 — 지금 미리 프리미티브화해둘 이유가
  없음. **[한정, 2026-08-18 구현 전 QA]** 다만 "재설계 불필요"가 **"코드
  변경 불필요"는 아니다** — 사용자 판정에 따르면 그때는 module-level
  state를 참조하는 코드들이 모듈 인스턴스를 인자로 받도록
  (`InitModule(module)` 류) 손을 봐야 한다(`base/architecture.md` "확정된
  결정" 13번). 지금은 `New()` 자체가 노출 안 된 싱글톤 단계라
  `Quad.Dispatch`로 바로 접근한다. **[2026-08-19 추가]** 이 문단이 말하는
  "`InitModule(module)` 류"의 정확한 형태(각 서브시스템별 `InitXxx(module)`
  팩토리 체이닝 + `Relate` 기반 인스턴스별 멱등 가드)가
  `module-lifecycle-plan.md`의 "New()의 내부 구성" 절에 구체화됨 —
  `Dispatch/init.luau`도 그 패턴을 따르는 `InitDispatch(module)` 하나로
  구현된다.

### base가 소유하는 핸들러와 주입되는 엔진 op (2026-08-13 열네 번째 세션 신설)

**원칙**: 핸들러를 base와 backend 중 어디에 둘지는 "이 키/값이 엔진
개념인가"가 아니라 **"이 핸들러가 하는 부기(bookkeeping)가 엔진 지식을
요구하는가"**로 가른다. 부기가 순수하면 **알고리즘은 base가 소유하고,
엔진에 실제로 손대는 마지막 한 줄만 함수로 주입**받는다.

- **base 소유 + op 주입**: `Tag`(위치별 참조 카운트), `Attribute` 단일
  키/그룹(이름 claim, 그룹→단일 키 위임, `None` 처리). 둘 다 웹에도
  대응물이 있고(`className`, `data-*`) 부기 로직이 엔진과 무관해서,
  백엔드마다 재구현하면 **같은 참조 카운트/소유권 알고리즘이 통째로
  복제**됨 — `architecture.md`의 "패키지 경계" 절이 세운 원칙이 그대로 적용되는
  자리(2026-08-13 열네 번째 세션, 사용자 판단으로 재배치). **같은 패턴이
  Dispatch 바깥에도 적용됨** — `dispose(value)`(`base/slot-plan.md`)는
  Dispatch 핸들러가 아니라 독립 탑레벨 유틸이지만, `isSlot`이 아닌 값은
  `elementOwner` 같은 순수 부기 판정 뒤에 마지막 한 줄만
  `nativeDispose(element: any): ()`로 위임(quad-roblox는 `inst:Destroy()`) —
  **[2026-08-21 5라운드, 같은 날 이름 확정] 같은 계열이 `native*` 물리 트리
  조작 계층으로 정리됐다**(base는 `Parent`를 모른다는 지적에서 나옴).
  **⚠️ [2026-08-22 정정] 여기 한때 `disposeInst`/`mountInst(target, element,
  index)`/`unmountInst(element)`로 적히고 "이름은 아직 가칭이라 정식 등재는
  확정 시점에 한다"고 미뤄져 있었으나, 이름은 같은 날 `native*`로
  확정됐다** — `nativeInsert`/`nativeExtract`/`nativeRemove`/`nativeMove`/
  `nativeSwap`/`nativeDispose`. 시그니처와 조합 폴백 규칙의 소스는
  `base/slot-plan.md`의 "물리 조작은 주입 op다" 절이고, 주입 op 전체
  목록의 소스는 `base/architecture.md`의 소스 트리 안 `EngineOps.luau`
  줄이다 — 여기서 다시 나열하지 않는다.
  같은 "base 소유 + op 주입" 원칙은 2026-08-14 열 번째 세션에 확정.
- **backend 소유**: `Property`/`Event`/`OnChange`(Reflection·시그널 같은
  엔진 개념 자체가 로직), `InstanceChild`, `Slot`의 실제 부모 조작
  (재조정 알고리즘은 base `Dispatch/Slot.luau`, 물리 마운트만 backend) —
  이들은 "한 줄 op"으로 줄어들지 않으므로 그대로 backend.

**Tag/Attribute가 쓰는 주입 op**(**⚠️ [2026-08-22] 이건 주입 op *전체
목록*이 아니다** — 이 절이 다루는 Tag/Attribute 경로에 필요한 셋일 뿐이고,
`native*` 물리 조작 계층과 `setTimeout`/`clearTimeout`은 여기 없다. 전체
목록의 소스는 위에서 지정한 `base/architecture.md`의 `EngineOps.luau` 줄
하나다 — 여기에 다시 쌓지 말 것):

```lua
addTag(inst: any, names: {string}): ()       -- 웹은 className을 한 번에 갱신
removeTag(inst: any, names: {string}): ()
setAttribute(inst: any, name: string, v: any?): ()  -- v == nil이면 그 이름을 지움
```

- **왜 vararg가 아니라 `{string}`인가**: 호출자는 항상 quad 자신이고
  넘기는 것도 "이번 사이클에 추가/제거된 이름 집합"이라 테이블이 자연
  단위임. vararg로 두면 `table.unpack(t)`가 **인자 목록 tail 위치일
  때만** 완전히 펼쳐진다는 Lua 문법 제약에 걸리고(대량 이름에서 unpack
  한계도 있음), 이건 이미 `Tag:Added`가 vararg → `string | {string}`로
  되돌아갔던 것과 **같은 이유**(`base/tag-plan.md`). 배치 호출 자체는
  테이블로도 그대로 되므로 웹의 className 일괄 갱신 요구도 충족됨.
- **`setAttribute(inst, name, nil)`이 "지운다"는 의미**인 건 Roblox
  `SetAttribute`의 네이티브 동작과 일치하고, 다른 백엔드는 자기 방식으로
  매핑하면 됨(웹이면 `removeAttribute`). base 쪽 규칙 — "Attribute는 오직
  명시적 `None`/`nil`로만 지워진다"(`base/attribute-plan.md`) — 은 그대로.

**[재정정, 2026-08-14 열두 번째 세션] `TagHandler`/`AttributeKeyHandler`/
`AttributeGroupHandler`는 참조 카운트/이름 claim **알고리즘 구현**일
뿐이고, 스스로 등록되는 주체가 아니다.** `HANDLER_PRIORITY_FALLBACK`에
실제로 꽂히는 건 그 알고리즘을 그대로 감싸는 **별도 이름의 엔티티**
(`TagFallbackHandler`/`AttributeKeyFallbackHandler`/
`AttributeGroupFallbackHandler`) — "이게 기본 안전망으로 자동 설치되는
대상"임을 이름 자체로 구분한다.

**[재역전, 2026-08-18 구현 전 QA — 사용자 확정] 등록 주체는 다시
quad-base 자신이다(모듈이 자기 레지스트리를 구성하는 시점).** 2026-08-14
열두 번째 세션은 이걸 "백엔드 팩토리가 자기 Handler들과 같이 등록한다"로
뒤집었었는데, 그러면 **quad-roblox를 아예 로드하지 않은 상태에서는 이
Fallback Handler들도 존재하지 않아**, 위 "매치 실패는 즉시 `error`" 절이
약속한 *"provider가 초기화됐는지 확인하라"* 안내 경로 자체가 동작하지
않는다(사용자: *"안 그러면 quad-roblox 를 로드하지 않았을 때 로드했는지
물어보는 요소가 처리가 안 된다"*). Fallback 밴드의 존재 이유가 "아무도 이
자리를 안 가져갔을 때"인데, 그 등록을 "누군가 자리를 가져가는 시점"에
의존시키면 밴드가 가장 필요한 상황에서 비어 있게 된다.

**`InitNamespace` 거부 원칙과 충돌하지 않는 이유**: 그 원칙이 금지한 건
**라이브러리마다 사용자가 수동으로 init을 호출하게 만드는 것**과 **모듈이
로드되면서 *남의* 상태를 건드리는 것**이다(`base/lifecycle-pattern.md`의
"rbvm에서 그대로 가져오면 안 되는 것" 절). base가 **자기 모듈 안의 자기
레지스트리**를 자기가 채우는 건 그 어느 쪽도 아니다 — 외부에 노출되는 init
표면이 늘지 않고, 순서 의존도 없고(레지스트리와 등록 코드가 같은 모듈),
사용자가 할 일도 없다. 백엔드가 나중에 자기 Handler를 등록해 이기는 구조도
그대로다(Fallback 밴드는 항상 최하위). A-3의 다중 인스턴스화(`New()`)로
가더라도 자리는 그대로 — 그때는 "모듈 로드 시"가 "인스턴스 생성 시"가 될
뿐이다.

옛 역전 원문은 `archive/tag-attribute-load-time-registration-reversed.md`
(그 문서 자체가 이번에 재역전됐다는 배너를 달아뒀음). **그 역전이 같이
고쳤던 "이름" 쪽 결론은 그대로 유효** — 등록되는 엔티티는 알고리즘 구현체
(`TagHandler` 등)가 아니라 그걸 감싼 `*FallbackHandler`다.

`HANDLER_PRIORITY_FALLBACK`이라는 밴드 자체가 정확히 이런 용도 —
"아무도 이 자리를 안 가져갔을 때의 안전한 기본 동작"을 base가 값싸게
제공하는 것. 엔진 저자 입장에서 "자동/공짜"인 이유는 직접 알고리즘을
안 짜도 되기 때문이고, **백엔드를 아직 안 붙였어도 이 밴드는 이미 채워져
있다**(위 재역전) — 그래서 모든 백엔드가 `Tag`/`Attribute` 부기를 공짜로
얻고, 백엔드가 하나도 없을 때조차 "이 값이 어떤 자리에 놓이든 최소한
매치는 되고, 엔진 op이 없으면 그 자리에서 명확한 에러가 난다"가 성립한다.

`addTag`/`removeTag`/`setAttribute`는 base가 시그니처만 소유하고
실제 구현은 팩토리가 뮤테이션으로 주입하는 **타입 계약**(`bindLifetime`/
`canExecute`와 같은 패턴, 엔진이 실제로 손대는 부분은 백엔드가 채우기로
"계약"한 것) — 이건 그대로 유지:

- **아직 아무 팩토리도 채우지 않은 슬롯의 기본값은 quad-base가 준다 —
  단 "동작하는 구현을 추측"하지 않고 명시적으로 에러내는 스텁으로.**
  `BaseModule.addTag = function() error("addTag가 구현되지 않음 —
  provider가 초기화됐는지, 이 백엔드가 Tag를 지원하는지 확인하라") end`
  류. base가 "그럴듯한 기본 동작"(예: 조용한 no-op)을 대신 만들어주는
  건 기각 — 임의의 엔진에 뭐가 맞는 기본값인지 base는 알 수 없고,
  조용한 no-op은 실수(provider 초기화를 잊음)를 가려버림. 명시적 에러가
  유일하게 안전한 기본값.
  - **"provider 미주입"과 "이 백엔드가 애초에 Tag를 지원 안 함"은 이
    기본 스텁 수준에서 여전히 구분 안 됨** — 둘 다 그 슬롯이 안
    채워진 같은 상태라 원천적으로 구별 불가(`pre-implementation-audit.md`
    1-4, 2026-08-12 열일곱 번째 세션 확정 원칙 그대로).
- **[관례, opt-in] 더 명확한 메시지나 진짜 원자적 실패(부기 mutation
  0회)를 원하는 백엔드는, 그거대로 `HANDLER_PRIORITY_FALLBACK + 1`
  우선순위의 얇은 가로채기 Handler를 추가로 등록할 수 있음**:
  ```lua
  { priority = HANDLER_PRIORITY_FALLBACK + 1,
    isHandlable = function(inst,k,v) return isTag(v) end,
    process = function(inst,k,v) error("이 백엔드는 Tag를 지원하지 않음") end }
  ```
  실제로 `FALLBACK`에 등록돼 있는 `TagFallbackHandler`보다 한 단계
  높아 스캔에서 먼저 매치되고(2026-08-14 열두 번째 세션 정정 — `TagHandler`
  자신은 스스로 등록되지 않음, 위 "base가 소유하는 핸들러와 주입되는
  엔진 op" 절 참고), "매치된 Handler 하나만 실행"이라는 기존 규칙
  덕분에 `TagHandler.process`(와 그 안의 `tagNameMap` mutation)는 아예
  안 불림 — op 에러보다 이르고 정확한, 진짜 원자적 실패. 단 이건
  **선택적 업그레이드**일 뿐
  기본 요구사항은 아님 — base 기본 스텁 하나로도 이미 충분히 안전하게
  실패함(`AttributeGroupHandler`의 "부분 실패 경로" 절이 이미 정리한
  "에러=패닉 상태, 그 이후 정합성은 관리 대상 아님" 원칙 + `nameClaims`/
  `tagNameMap`이 `inst`에 대해 weak라 그 인스턴스가 GC되면 잔여 부기도
  같이 사라지는 것으로 충분히 커버됨), 더 깔끔한 실패를 원하는 백엔드만
  추가로 얹으면 됨.
- **타입 패밀리는 백엔드 몫**: `AttributeKey<<T>>` 제네릭 생성자와
  스칼라 편의 패밀리(`StringAttribute`/`NumberAttribute`/`BooleanAttribute`)
  까지가 base이고, `Color3Attribute`류처럼 **엔진 고유 타입**에 묶인
  패밀리는 그 백엔드(quad-roblox의 `D` 층)가 자기 것으로 추가함 —
  "이 값이 이 백엔드에서 표현 가능한가"라는 검증도 base가 아니라 주입된
  `setAttribute`의 몫(`base/attribute-plan.md` "패키지 배치" 절).

### Dispatch 체인 — 인덱스 기반 추적, 재디스패치는 하강 diff (2026-08-08 세 번째 세션 신설, 2026-08-13 다섯 번째 세션 인덱스화, 같은 날 열네 번째 세션 하강 diff로 전면 교체)

**[전면 교체, 2026-08-13 열네 번째 세션 — `question.md` 0-A/0-Z 확정]**
이 절은 원래 **"래핑 핸들러가 재-dispatch 전에 자기 아래를 먼저
`retractFrom`으로 철거한다"**는 모델이었으나, 그 모델은 철거 시점에
넘기는 힌트(`hintValue`)의 **타입이 계약으로 보장되지 않는다**는 실제
결함이 있었음(`None` 센티널이나 `State`/`Tween` 래퍼가 그대로 말단
핸들러에 도착해 `isTag(hint)` 가드를 거짓으로 만들고 깜빡임/재생성
방지를 조용히 끔). 지금은 **철거 선행을 폐기하고 `Dispatch.process`가
핸들러를 먼저 비교하는 "하강 diff"** 모델 — 뒤집힌 옛 모델의 원문·재현
사례·역전 근거는 `archive/dispatch-hintvalue-model-reversed.md`.

**문제(원래 동기, 여전히 유효)**: `NoneHandler`/`StoreBind`처럼 자기
`process` 안에서 `Dispatch.process(inst,k,realv,...)`를 다시 부르는 래핑
핸들러가 있으면, 같은 `(inst,k)`에 대해 "지금 누가 담당 중인가"를 슬롯
하나로 추적하는 순간 깨짐 — 래핑 핸들러 A 자신의 생명주기(예: StoreBind의
Observer 구독)와, A가 재귀로 위임한 핸들러 B의 생명주기가 **같은 슬롯을
두고 서로 덮어씀**. 처음 검토했던 "Dispatch 전역 소유자맵 슬롯 하나" 안은
이 이유로 기각됨.

**해법 — Dispatch가 `(inst,k)`별로 인덱스 배열을 소유, 각 슬롯엔 그
`process` 호출을 담당한 **핸들러**와 그가 반환한 **retractor 클로저**를
같이 저장**(핸들러를 같이 저장하는 게 하강 diff의 유일한 추가 저장분 —
"이전 값"은 클로저가 이미 upvalue로 알고 있으므로 따로 저장 안 함):

```lua
-- Dispatch/init.luau
local chains = Relate()  -- {[inst(weak)] = {[k] = {[index] = {handler, retractor}}(strong)}}
local NOOP = function() end

function Dispatch.process(inst, k, v, index)
    -- [순서 주의] list 확보 + chains 등록은 반드시 h.process 호출 *전에* 끝나야 함 —
    -- h.process가 내부에서 재귀 Dispatch.process(inst,k,...,index+1)를 부르는 게
    -- 정상 경로이고(StoreBind/NoneHandler), 그때 chains에 이 list가 아직 안 들어가
    -- 있으면 재귀 호출이 `or {}`로 자기만의 새 테이블을 만들어 저장해버린 뒤 바깥이
    -- 그걸 덮어써서 하위 위임 retractor가 통째로 유실됨(최초 마운트에서 항상 발생).
    local list = chains:GetStrong(inst, k)
    if not list then
        list = {}
        chains:SetStrong(inst, k, list)
    end

    local slot = list[index]
    local h = Dispatch.getHandler(inst, k, v)   -- 매치 실패는 기존 규칙대로 즉시 error

    if slot ~= nil and slot.handler == h then
        -- (A) 같은 핸들러 — 아래를 안 건드리고, 이 자리 클로저에 새 값을 넘겨
        -- 스스로 전이를 처리하게 한 뒤 같은 자리를 새 클로저로 교체.
        -- v는 getHandler가 h를 골랐다는 사실만으로 h.isHandlable(inst,k,v)를 만족함이 보장됨.
        slot.retractor(v)
        slot.retractor = NOOP   -- 이미 소비된 클로저가 두 번 불릴 여지를 없앰
                                -- (h.process가 재귀하는 동안 잠깐 열려 있는 구간)
        local retractor = h.process(inst, k, v, index)
        if retractor == nil then
            error("Dispatch: 핸들러가 retractor 반환을 생략했음 — 생략 불가")
        end
        slot.retractor = retractor
    else
        -- (B) 다른 핸들러(또는 빈 자리) — 이 자리부터 아래를 전부 철거하고 새로 설치.
        Dispatch.retractFrom(inst, k, index)
        -- 점유 마커를 먼저 박는 이유: h.process가 재귀하는 동안 list가 구멍 없는
        -- 시퀀스로 유지돼야 `#list`가 정의됨(hole 있는 테이블의 `#`는 Lua가 보장 안 함).
        list[index] = { handler = h, retractor = NOOP }
        local retractor = h.process(inst, k, v, index)
        if retractor == nil then
            error("Dispatch: 핸들러가 retractor 반환을 생략했음 — 생략 불가")
        end
        list[index] = { handler = h, retractor = retractor }
    end
end

function Dispatch.retractFrom(inst, k, index)
    -- index부터(포함) 끝까지, 꼬리(가장 깊은 인덱스)부터 역순으로 정리.
    -- 힌트는 항상 nil — "뒤따르는 process가 없는 단순 철거"가 이 함수의 유일한 용도.
    local list = chains:GetStrong(inst, k)
    if not list then return end
    for i = #list, index, -1 do
        local slot = list[i]
        if slot == nil then
            error("Dispatch: 인덱스 " .. i .. "에 슬롯이 없음 — 배열에 구멍이 뚫렸음")
        end
        slot.retractor(nil)
        list[i] = nil
    end
end
```

- **래핑 핸들러는 재-dispatch 전에 아무것도 철거하지 않는다 — 그냥 아래로
  내려보낸다.** `StoreBind`/`NoneHandler`가 하는 일은 이제 한 줄:
  ```lua
  Dispatch.process(inst, k, realv, index + 1)   -- 선행 retractFrom 없음
  ```
  전이 판정은 그 재귀 호출 안에서 `Dispatch.process`가 스스로 함(위 (A)/(B)
  분기). **이게 이 모델의 전부** — "누가 무엇을 언제 철거하는가"라는 질문이
  래핑 핸들러들에서 Dispatch 한 곳으로 옮겨갔음.
- **retractor가 받는 값의 타입이 계약으로 보장됨.** 클로저에 `nil`이 아닌
  값이 넘어가는 건 **오직 (A) 분기, 즉 새 값이 같은 핸들러에 매치될 때뿐**이고,
  "같다"는 판정 자체가 `getHandler(inst,k,v) == slot.handler`이므로 그 `v`는
  정의상 그 핸들러의 `isHandlable`을 만족함. 즉 말단 핸들러는 **`nil` 여부만
  구분하면 되고**, 옛 모델이 요구하던 `isX(hintValue)` 방어 가드는 필요
  없어짐(옛 규칙은 힌트의 타입 미보장을 메우던 임시방편이었음).
  **[한정, 2026-08-18 구현 전 QA] 보장 범위는 "같은 핸들러"까지지 "같은 값
  모양"까지가 아니다** — `isHandlable`이 **여러 모양의 값**을 받아들이는
  핸들러라면 그 안에서 어느 모양인지 가르는 `is` 판별은 **여전히 필수**이고,
  그건 그 핸들러 자신의 몫이다(사용자: *"처음부터 한 핸들러가 여러 값을
  가질 수 있어 is 처리가 필요한건, 그 핸들러의 몫입니다"*). 실제 사례가
  이미 있음 — `PropertyHandler`는 평범한 값과 `Tween<T>` 래퍼를 **둘 다**
  받아 `isTween(realv)`로 분기한다(`base/tween-plan.md`). 없어진 건
  **타입 미보장을 메우려던 방어 가드**뿐이다.
- **깊은 체인에서도 힌트가 안 사라짐** — 힌트를 위에서 아래로 실어
  보내는 게 아니라 **각 레벨이 자기 재프로세스에서 자기 힌트를 받기**
  때문. `State<State<Tag>>`에서 바깥이 새 inner State를 내놓아도 인덱스 2는
  StoreBind끼리 같으니 자기 클로저가 구독을 갈아타고, 재위임으로 내려간
  인덱스 3은 TagHandler끼리 같으니 **진짜 `Tag` 객체를 힌트로 받아**
  `Contains` skip이 정상 동작함. 옛 모델의 "깊이 2 이상에선 힌트가 `nil`,
  구조상 불가피" 캐비엇은 **철거 선행 모델에서만 불가피했던 것**이라 같이
  없어짐.
- **두 종류의 retract가 계약상 갈림**(사용자 정리: "새 프로세싱으로 인한
  retract처리와, 단순 retract는 다르다"):
  - **단순 retract**(언마운트/전체 철거, `Dispatch.retractFrom`): 뒤따르는
    `process`가 없음. 인자는 항상 `nil`. 핸들러는 자기 기여를 무조건 전부
    걷어냄.
  - **재프로세싱**(`Dispatch.process`의 (A) 분기): 그 자리 클로저가 **새
    값을 인자로** 받고, 곧바로 같은 핸들러의 `process`가 다시 불림.
  - **그래서 `Dispatch.retractFrom`은 3-인자다** — 옛 모델의 4번째 인자
    (`v`, 힌트)는 "철거 직후 이 값이 올 것"을 알려주려던 것인데, 새
    모델에서 값을 넘기는 경로가 (A) 분기 하나로 통일되면서 **외부에서
    힌트를 만들어 넣을 자리 자체가 없어짐**. 옛 결함(래퍼/센티널이 힌트로
    새는 것)이 구조적으로 재발할 수 없는 이유이기도 함.
- **`inst`에 실제 부작용을 가하는 것은 말단 핸들러뿐 — 중간(래핑) 노드는
  순수 언랩만 한다**(사용자 명시, 새 제약이 아니라 이미 성립하던 성질의
  계약 승격):

  | 핸들러 | 위치 | `inst` 부작용 |
  |---|---|---|
  | `StoreBind` | 중간 | 없음(구독 + 재위임만) |
  | `NoneHandler` | 중간 | 없음(재위임만) |
  | `NilHandler` | 말단 | 없음(`setLength`/`setOffsetSource` 부기만 — 2026-08-18 신설) |
  | `PropertyHandler` | 말단 | 프로퍼티 세팅 |
  | `TagHandler` | 말단 | `addTag`/`removeTag` |
  | `AttributeKeyHandler` | 말단 | `setAttribute` |
  | `AttributeGroupHandler` | 자기 체인에선 말단 | 없음(다른 키로 위임) |
  | `SlotHandler` | 말단 | 마운트/언마운트 |
  | `RefLeafHandler` | 말단 | `Ref:Set` |
  | `UICornerHandler` | 말단 | 자식 Instance 생성/제거 |

  이 계약이 필요한 이유: (A) 분기는 **아래를 안 건드린 채** 중간 노드만
  갈아치우므로, 중간 노드가 `inst`에 직접 손을 댔다면 그 흔적을 지울
  주체가 없어짐.
- **재위임하는 핸들러는 (A) 분기에서도 반드시 다시 재위임해야 한다.** 안
  그러면 자기 아래 인덱스가 고아로 남음(아무도 안 지움). `StoreBind`/
  `NoneHandler`는 항상 재위임하므로 지금 위반 사례는 없지만, "조건부로만
  재위임하는" 핸들러를 새로 만들면 재위임을 건너뛰는 그 자리에서
  `Dispatch.retractFrom(inst, k, index + 1)`을 직접 불러 아래를 정리해야 함.

  **[예시 추가, 2026-08-20 구현 전 QA 4라운드 `B-3`]** 규칙만으론 뭐가
  위험한지 안 드러난다는 지적을 받아 가상의 위반 사례를 같이 적어둠:

  ```lua
  -- ⚠️ 이런 핸들러를 새로 만들면 고아 체인이 생긴다
  function MaybeWrapHandler.process(inst, k, v, index)
      if v.enabled then
          Dispatch.process(inst, k, v.inner, index + 1)  -- 재위임함
      end
      -- v.enabled가 false면 아무것도 안 함 ← 여기가 문제
      return function() end
  end
  ```

  - 1차 사이클 `v.enabled == true` → index+1에 하위 체인이 설치됨.
  - 2차 사이클에 **같은 핸들러**로 `v.enabled == false`가 오면 (A) 분기다 —
    (A)는 정의상 **아래를 안 건드리므로** `retractFrom`이 안 불린다.
  - 그런데 이번엔 재위임을 안 했으니 **index+1의 옛 하위 체인이 그대로
    남는다.** 아무도 안 지우고, 옛 값에 대한 구독/부작용이 계속 산다.
  - **해법**: `else` 자리에서
    `Dispatch.retractFrom(inst, k, index + 1)`을 직접 부른다.
- **`HandlerChanged` 같은 마커 값은 두지 않음** — "핸들러가 바뀜"은 **그
  자리 retractor가 `nil`로 불린다는 사실 자체**로 이미 표현됨. 별도 마커를
  만들면 그것도 결국 "인자로 넘어오는 정체불명의 값"이 되어 옛 모델의
  결함을 되풀이함.
- **"이전 값"을 Dispatch가 저장하지 않는 이유**(사용자 지적: "이전 값인
  oldValue는 처음부터 클로저라 이미 본인이 알지 않아요?") — 맞음. 클로저는
  자기 `process` 호출의 `v`를 upvalue로 캡처하고 있고 새 값을 인자로 받으므로
  old/new를 이미 둘 다 갖고 있음. `chains`에 추가로 저장해야 하는 건 **비교용
  `handler` 하나뿐**.
- **인덱스의 의미 — 재귀 깊이, 서로 다른 키는 항상 1부터**: 같은 키에서
  값이 한 겹 더 반응형으로 감싸져 재귀하면(`StoreBind`가 `realv`를 들고
  다시 `Dispatch.process`를 부르는 경우) `index+1`을 넘김. **다른
  키로 위임할 때는 그 키의 재귀 깊이와 무관하게 항상 `1`부터 시작** —
  `chains[inst][key2]`는 `chains[inst][key1]`과 완전히 별개의 배열이라
  연속성이 필요 없음(예: `Attribute` 그룹이 `(inst,배열위치)`에서
  `(inst,그룹전용 AttributeKey)`로 위임할 때). **시작 인덱스는 0이 아니라
  1** — Luau `ipairs`/`#`(배열 part 순회)는 1부터 연속된 정수 키를
  전제하므로(quad 자신이 "props 순회 순서" 절에서 이 관례에 의존), 0을
  쓰면 그 항목이 `ipairs` 순회에서 조용히 빠지고 `quad-debug`가 나중에
  `chains`를 그대로 순회해서 보여주려는 계획과도 부딪힘.
- **위임 대상은 다른 `k`뿐 아니라 다른 `inst`여도 됨 — UB 아님
  (2026-08-14 세션, 명시화).** `chains`는 `(inst,k)` 쌍으로 인덱싱되므로
  `(inst,k1)`을 처리하던 핸들러가 `(inst,k2)`로 위임하는 것과
  `(child,k2)`로 위임하는 것은 Dispatch 입장에서 **구조적으로 완전히 같은
  일**임(둘 다 별개의 새 배열, 그래서 둘 다 인덱스 `1`부터). 즉 핸들러가
  **자기가 관리하는 자식 Instance를 먼저 만들거나 찾아둔 뒤 그 자식에
  대해 `Dispatch.process(child, prop, v, 1)`을 부르는 패턴은 정상**이고,
  이게 `base/ui-shorthand-plan.md`의 `UICorner`/`UIPadding`/`UIScale`
  숏핸드가 Tween을 공짜로 얻는 방식임(그 자식 프로퍼티를 최종 처리하는
  건 `PropertyHandler`이고, Tween 해석은 원래 거기 하나에만 있음 —
  `base/tween-plan.md`). 단 **그 자식의 수명은 위임한 핸들러가 책임진다**
  — Dispatch는 `(child,prop)` 체인이 누구 소유인지 모르므로, 자식을
  없앨 때 `retractFrom(child, prop, 1)`까지 부르는 건 위임한 쪽 몫
  (자식 Instance 자체를 버리면 `chains`가 `inst`로 weak-keyed라 결국
  GC되지만, 실행 중인 Tween/구독처럼 즉시 끊어야 하는 게 있으면 명시적
  정리가 필요).
- **`handler.process(inst,k,v,index)`를 `Dispatch.process`를 거치지 않고
  직접 호출하는 것은 UB — 반드시 `Dispatch.process`를 통해서만 진입할
  것.** 이유: 핸들러 비교·`chains` 저장 bookkeeping이 `Dispatch.process`
  내부에만 있어서, `handler.process`를 직접 부르면 그 핸들러가 실제로
  활성화됐는데도 체인에 안 올라가 — 나중에 `retractFrom`이 이 핸들러의
  존재를 몰라 정리가 영영 안 되거나(리소스 누수), 반대로 같은 인덱스를
  다른 핸들러가 또 차지해 정합성이 깨짐.
- **개별 핸들러의 retractor는 자기 위임 대상을 수동으로 안 쫓아가도 됨** —
  `retractFrom`이 꼬리(가장 깊은 인덱스)부터 목표 인덱스까지 한 번의
  루프로 순서대로 정리해주므로, A→B→C처럼 몇 단계든 각 핸들러는 **자기
  자신의 자원만** 정리하면 자동으로 전파됨. 자기 자신을 포함해서 지우고
  싶으면 자기 인덱스를 그대로 넘기고, 자기 아래만 지우고 싶으면 `index+1`을
  넘김 — **"미만"과 "이하"를 별도 함수로 안 쪼개고 호출자가 넘기는 인덱스
  하나로 통일**(옛 `retractUnder`/`retractSelfAndUnder` 두 함수가 이걸로
  하나가 됨, `archive/checkpoint-handler-pattern-reversed.md` 참고).
- **소유권 충돌 감지는 이제 Dispatch의 일이 아님 — 필요한 도메인이 직접
  한다.** 옛 모델의 `Dispatch.process`는 "이 인덱스가 이미 점유돼 있으면
  즉시 error"를 냈고 `Attribute` 이름 소유권이 그 부수 효과에 얹혀
  있었으나, 하강 diff에선 **점유는 정상 상태**(재프로세스가 늘 그 자리를
  다시 씀)라 그 체크 자체가 성립하지 않음. 실제로 두 소유자가 한 자원을
  다투는 유일한 사례였던 Attribute 이름은 **자기 도메인 안에서 이름별
  claim으로 해결**함(`base/attribute-plan.md` "이름 소유권" 절, `question.md`
  0-Z 결정) — Dispatch에 claimant 개념을 일반화하는 안은 명시적으로 기각.
- **순환은 UB, 방어 로직 없음** — Handler 간 순환 참조(A가 B를 부르고
  B가 다시 A로 돌아오는 것, 또는 값 자체가 결국 자기 자신을 가리켜
  무한히 깊어지는 인덱스)는 재귀 호출이 안 끝나 바로 스택오버플로가
  나므로 애초에 일어날 수 없는 구조 — 값에 별도 플래그를 심어 의도적으로
  순환을 만드는 것도 이론상 가능하지만 use case가 없어 문서화 대상 밖,
  2026-08-04 세션에 이미 확정된 "일반적 무한루프 방어 안 함" 원칙과
  같은 결로 UB 취급. 핸들러가 **같은 인덱스로** 자기 자신을 재진입시키는
  버그도 같은 경로로 수렴함(자기 자신과 핸들러가 같으니 (A) 분기를 무한히
  반복 → 스택오버플로).
- **`State<State<T>>`는 정상 지원 대상** (2026-08-13 다섯 번째 세션
  재정정, 열네 번째 세션에 힌트까지 보강). 원래(같은 날 두 번째 세션)
  `store.key = a`(State), `a:Get() = b`(State)일 때 같은 `StoreBind`
  싱글톤이 같은 `(inst,k)`에 identity로 두 번 매치돼 옛 `retractUnder`의
  cutoff 계산이 안쪽 자신을 잘못 retract하는 실제 버그(체인 파손, 구독이
  등록 직후 스스로 끊김)로 재현돼 "같은 핸들러 객체가 이미 있으면 즉시
  error" 가드로 막았었음(`archive/checkpoint-handler-pattern-reversed.md`가
  인용하는 옛 코드 참고). 근본 원인은 "핸들러당 그 키에서 최대 한 번"을
  **객체 identity로** 강제하려 한 것 — 인덱스 기반에선 `a`를 처리하는
  StoreBind가 인덱스 N, `a:Get()`(=`b`)을 처리하는 (같은 싱글톤인)
  StoreBind가 N+1을 써서 애초에 슬롯이 안 겹침. 임의 깊이의
  `State<State<State<...>>>`도 인덱스가 늘어날 뿐 정상 동작하고, 위
  "깊은 체인에서도 힌트가 안 사라짐" 항목대로 **깜빡임 방지 최적화까지
  정상 작동**함 — 유일하게 남는 UB는 위 "순환" 항목.
- **부수 효과 — quad-debug에 유리**: 이 체인이 Dispatch에 중앙화돼
  있으므로, 임의 시점의 재바인드도 `Dispatch.process(inst, k, newV, 1)`
  **한 줄**로 "이 키의 체인을 새 값에 맞춰 갈아 끼우기"가 됨(옛 모델에선
  `retractFrom` + `process` 두 줄이었음 — 하강 diff가 그 선행 철거를
  흡수). **[2026-08-14 세션]** 이 문장이 원래 근거로 들던 "미래의
  existing-instance-bind"는 기각됐지만
  (`archive/existing-instance-bind-rejected.md`), 여기서 말하는 성질은
  quad가 **자기가 만든** 인스턴스의 store 재발행에서 매번 쓰는 그 경로
  자체라 그대로 유효. 완전 해제만
  원하면 `Dispatch.retractFrom(inst, k, 1)`. `research/debug-tooling-plan.md`의
  "무엇이 무엇에 연결됐는가" 그래프도 이 `chains` 구조를 그대로 읽으면 됨 —
  `handler`가 슬롯에 같이 저장되므로 "이 자리를 지금 누가 담당하는가"를
  이름으로 바로 덤프할 수 있어 옛 모델보다 오히려 유리해짐.

### Handler 작성 체크리스트 — 실제로 반복된 실수들 (2026-08-13 여섯 번째 세션 신설, 열네 번째 세션 하강 diff 기준으로 갱신)

**왜 이 절이 있는가**: 인덱스 기반 재설계 직후 작성된 의사코드
(`Dispatch` 자신, `Ref`, `Tag`, `Slot`, `Attribute`)에서 **같은 세션
안에 버그 4건**이 나왔고, 그중 셋이 서로 다른 문서에 있으면서도
**같은 종류의 착각**에서 나왔음. 새 Handler를 짜거나 기존 걸 고칠 때
이 목록을 먼저 훑을 것 — 전부 "그럴듯해 보이는데 틀린" 것들이라
리뷰로 잡기 어렵다.

**1. 클로저는 early-return해도 체인에서 *소비*된다.**
`Dispatch.retractFrom`은 저장된 retractor를 호출하고 **항상**
`list[i] = nil`로 지움 — 그 클로저가 "새 값이 옛 값과 같으니 할 일 없음"으로
바로 돌아왔더라도 마찬가지. `Dispatch.process`의 (A) 분기도 클로저를 부른
직후 그 자리를 새 클로저로 교체함. 그러므로:
- **매 `process` 호출은 "이 자리를 무르는 책임"을 온전히 새로 짊어진
  클로저를 반환해야 한다.** "이번엔 내가 실제로 한 일이 없으니 no-op을
  돌려주자"는 거의 항상 버그 — 다음 사이클에 진짜 교체가 올 때 정리할
  주체가 사라짐. (`SlotHandler`에서 실제로 이 함정에 빠졌었음.)
- 반대로 "아무 일도 안 했으니 무를 것도 없다"가 **진짜로** 맞으려면,
  그 자리가 무를 자원을 애초에 아무도 안 갖고 있어야 함(일반
  PropertyHandler처럼).

**2. 재-dispatch 전에 미리 철거하지 않는다.**
**[전면 교체, 열네 번째 세션]** 옛 모델에서 `StoreBind`가
`retractFrom(inst,k,index+1,realv)`를 선행 호출하던 것은 **폐기됨** —
지금은 그냥 `Dispatch.process(inst,k,realv,index+1)`만 부르고, 무엇을
철거할지는 `Dispatch.process`가 핸들러를 비교해 결정함(위 "Dispatch 체인"
절 (A)/(B) 분기). **다른 키로 위임하면서 그 키를 미리 `retractFrom`으로
비우는 것은 여전히, 그리고 더 명확하게 버그** — 그 자리를 누가 점유했든
말없이 지워버려 **다른 소유자의 바인딩을 조용히 파괴**함. 다른 키의 정리는
**그 키를 등록했던 클로저가** 자기 철거 시점에 한다.

**3. 클로저의 인자는 `nil`이거나, 같은 핸들러가 처리할 새 값이다 — 그
둘뿐.**
**[전면 교체, 열네 번째 세션]** 옛 모델의 3대 함정("타입 보장 안 됨 /
깊은 인덱스엔 안 옴 / `nil`이라 가정 금지") 중 앞의 둘은 하강 diff로
구조적으로 사라졌음:
- 값이 넘어오는 건 **오직 같은 핸들러로 재프로세스될 때**이므로 그 값은
  정의상 `isHandlable`을 만족함 → **타입 미보장을 메우려던 방어 가드**
  (`isTag(...)`를 "혹시 래퍼가 새어 들어왔을까 봐" 부르는 것)는 이제
  불필요. **[한정, 2026-08-18 구현 전 QA] 다만 한 핸들러가 여러 값 모양을
  받는다면 그 판별은 여전히 필수이고, 그건 그 핸들러 자신의 책임**
  (`PropertyHandler`의 `isTween(realv)` 분기가 실제 사례 — 위 "Dispatch
  체인" 절의 같은 한정 참고). 보장 범위는 "같은 핸들러"까지지 "같은 값
  모양"까지가 아니다.
- 깊이와 무관하게 **각 레벨이 자기 인자를 받음** → 깜빡임 방지 최적화가
  깊은 체인에서도 유효.
- 다만 **`nil`이라고 가정하는 것은 여전히 금지**(단순 철거일 때만 `nil`).
  `assert(v == nil)`류를 쓰면 안 됨 — 이미 한 번 전면 정정된 이력이 있음
  (`archive/retract-always-fires-reversed.md`).

**4. "이전 값"을 알고 싶으면 클로저 캡처, "여러 위치/사이클을 가로지르는
누적 상태"만 `Relate`.** 이 경계를 헷갈리면 양방향으로 틀림:
- 불필요한 `Relate`: `process`가 만든 걸 그 클로저가 정리하는 단발성
  handoff는 upvalue 캡처로 끝(옛 `kSlotMap`/`kTagMap`이 이걸로 삭제됨).
- 부족한 `Relate`: `Tag`의 `tagNameMap`(여러 위치가 한 이름을 공유),
  `Attribute`의 이름 claim(`nameClaims`), `Ref`의 spurious 재바인딩
  dedup처럼 **자기 클로저 수명 밖의 정보**는 캡처로 대체 불가.
- 그리고 `Relate`에 쓴 걸 클로저에서 지울 땐 **"내가 실제로 물러날
  때만"** 지울 것 — 조건 밖에서 무조건 지우면 dedup이 무력화됨
  (`RefLeafHandler`가 정확히 이 버그였음).
- **`Observer`/`Effect`의 Leaf 바인딩(`Dispatch/Leaf.luau`)도 `RefLeafHandler`와
  같은 `old ~= v` dedup을 둠 — correctness 문제는 아니지만 순수 성능
  최적화로 채택(2026-08-14 세션, 사용자 판단).** `State<Observer>`/
  `State<Effect>`가 재-dispatch될 때 안쪽 값이 실제로 안 바뀌어도(같은
  객체가 다시 옴) (A) 분기는 무조건 `retractor(v)`→`h.process(inst,k,v,index)`를
  다시 부름 — `Ref`와 달리 이걸 그냥 둬도 **깨지진 않음**: `bindLifetime`/
  `unbindLifetime`은 `Relate` weak 테이블 쓰기 몇 개뿐이라(`base/
  lifecycle-pattern.md`) 같은 값에 unbind 직후 바로 rebind해도 실제 Roblox
  커넥션을 만들거나 끊지 않고, 사용자에게 보이는 재통지도 없음(`Observer`/
  `Effect`의 `fn`은 이 leaf 바인딩이 아니라 자기 내부 구독이 따로 발화시킴 —
  `base/effect-plan.md`). 하지만 **`==` 비교(바이트코드 1개+분기)가 매번 여러
  weak 테이블 쓰기(해싱 비용)를 도는 것보다 항상 더 쌈** — 이득이 공짜에
  가까운데 안 넣을 이유가 없다는 판단으로 `RefLeafHandler`와 동일한 패턴을
  그대로 적용. 상세 pseudocode는 `base/source-state-plan.md`의
  "Observer/Effect Leaf dedup" 절.

**5. `Dispatch`를 통해서만 진입한다.**
`handler.process(...)`를 직접 부르면 핸들러 비교와 `chains` 기록이 통째로
빠져 나중에 정리가 안 되거나 정합성이 깨짐(위 "Dispatch 체인" 절).
마찬가지로 클로저 안에서는 `Dispatch.process` 금지, **같은 키**에 대한
`Dispatch.retractFrom`도 금지(진행 중인 루프가 `#list`를 이미 캡처).

**6. 인덱스는 "같은 키 안의 재귀 깊이"다.**
같은 키로 재귀하면 `index + 1`, **다른 키로 위임하면 그 키에서 다시
`1`부터**, `Dispatch.drive`의 최초 진입도 `1`. 배열 파트의 위치(`k`)와
이 `index`는 완전히 다른 것 — `AttributeGroupHandler`가 배열 위치를
`index`라고 이름 붙였다가 시그니처 자체가 계약과 어긋난 전례가 있음.

**7. 반환 생략 금지.** 정리할 게 없어도 `function() end`. `nil`을
반환하면 그 자리 슬롯이 완성되지 못해 `#list`가 정의되지 않게 되고
(`retractFrom` 순회 시작점이 어긋남) 체인 추적 자체가 깨짐 —
`Dispatch.process`가 (A)/(B) 양쪽에서 즉시 error를 냄. **[정정, 2026-08-13
7차 감사]** 예전엔 이 항목이 "`attempt to call a nil value`로 크래시"라고
적혀 있었으나 그때의 `retractFrom`이 `if retractor then`으로 조용히 넘기고
있어 크래시조차 안 나는 게 실제였음.

**8. 중간(래핑) 노드는 `inst`에 손대지 않는다, 그리고 항상 다시
재위임한다.** (A) 분기는 아래를 안 건드린 채 중간 노드만 갈아치우므로,
중간 노드가 `inst`에 직접 부작용을 냈다면 그 흔적을 지울 주체가 없어짐.
조건부로만 재위임하는 핸들러를 만들면 재위임을 건너뛰는 자리에서
`Dispatch.retractFrom(inst, k, index + 1)`로 아래를 직접 정리할 것.

**9. `process` 안에서(또는 `process`가 부르는 컴포넌트 함수/`updateFn`
안에서) 코루틴 yield 금지(2026-08-18 신설, `/code-review high`로 이
불변식이 "Length/Offset" 절에만 묻혀 있던 걸 발견해 여기로도 끌어올림).**
아래 "Length/Offset" 절의 배치 게이팅(`Blocker`)이 "position이 항상
순서대로, 다른 코드가 끼어들 틈 없이 동기로 처리된다"는 전제 위에
서 있음 — 이 체인 도중 yield가 끼면 같은 owner의 `Blocker`를 다른
코드가 그 사이에 건드릴 수 있어 게이팅 순서 보장이 깨짐. 상세 근거는
"배치 등록을 안전하게 만드는 Blocker 게이팅" 절.

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
Dispatch.setLength(ownerKey, i, len: number | State<number>, anchor?)
Dispatch.setOffsetSource(ownerKey, i, offset: Source<number> | None)
Dispatch.getOffsetAt(ownerKey, i): number      -- [2026-08-21 5라운드] 그 자리의 절대 offset
```
**[2026-08-21 5라운드]** `anchor`는 생명주기 앵커(생략 시 `ownerKey`, 자세한
건 아래 "`setLength` 구현" 절), `getOffsetAt`은 발행 채널(`Source`) 없이
숫자만 필요한 쪽(물리 삽입 위치 등)이 쓰는 pull 경로.

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
  자신의 `:List`/CRUD가 아니라 그 위치의 체인을 실제로 끝내는 말단
  Handler(`Dispatch/Slot.luau`)** — **[정정, 2026-08-18 구현 전 QA]**
  옛 서술은 "그 위치를 **처음** 매치한 Handler"였는데 부정확했다: 배열
  위치에 `State<Slot>`이 오면 처음 매치하는 건 `StoreBind`(중간 노드)이고,
  중간 노드는 `inst`에 부작용을 가하지 않는다는 계약(아래 "Dispatch 체인"
  절)과 정면으로 어긋난다. 사용자 판정은 *"최종 말단 요소가 이를
  처리하는게 더 올바른것으로 보이는데"* — 재귀가 끝나 실제 값을 받은
  말단 Handler가 등록한다(`State<Slot>`이면 재귀 끝의 `Dispatch/Slot.luau`,
  빈 자리면 `NilHandler`, `PreRef`/`PostRef` 소진 자리면 각 nop Handler).
  같이 검토 대상이던 *"단순히 모든 핸들러가 `k=number`일 때 처리하도록
  두는"* 안은 채택 안 함 — 그 안이 메우려던 갭(`State<Slot|None>`에서
  `None`이 올 때 아무도 `0`을 안 채우는 것)이 위 `NilHandler` 신설로 이미
  닫혔고, 말단 규칙 하나로 전부 커버되기 때문. `Slot`은 `inst`/`i`를
  모르는 독립 값(어디 마운트될지
  자기가 결정 안 함)이라, `process(inst, i, slotValue)`가 매치되는
  시점에 그 Handler가 `Dispatch.setLength(inst, i, slotValue.Length)`를
  1회 호출(길이 자체가 바뀌는 매 순간은 이미 `slotValue.Length`가
  `State`라 알아서 전파됨, Handler가 매번 다시 부를 필요 없음). `state<Slot>`
  교체 시엔 이 Handler가 새 값으로 다시 `setLength`를 호출.
- **`setOffsetSource`**: 이 위치가 자기 순서 계산에 쓸 `Source<number>`를
  **스스로 만들어서** 등록. **[2026-08-18 구현 전 QA 2라운드 후속 —
  `RC-1` 해결]** 예전엔 "Dispatch는 그냥 레지스트리에 넣어두기만 하고
  `recompute`가 그 자리에 값을 `:Set()`한다"였는데, 이제 **등록되는 그
  자리에서 자기보다 앞선 position들의 길이 합을 직접 계산해 즉시
  `:Set()`한다**(아래 "배치 등록을 안전하게 만드는 Blocker 게이팅" 절의
  "`setOffsetSource`의 즉시 계산" 참고) — `recompute`는 이후 값이 바뀔 때
  전체를 다시 계산하는 역할로 남는다. Slot이 매치되는 경우
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
  `Slot:List` 절 참고. **⭐ [정정, 2026-08-21 G절] `None`은 "발행 채널이 없다"는 뜻이다** —
  옛 서술은 "실제 마운트를 하지 않는 위치"였는데, **plain 요소도 `None`을
  등록**(마운트는 하지만 그 자리의 offset을 반응형으로 받아볼 소비자가 없음)하므로
  정확하지 않았다. **순서 계산에 참여하는지는 `setLength`가 답한다**(0이면 안
  차지). 숫자가 필요하면 채널 유무와 무관하게 `Dispatch.getOffsetAt(ownerKey, i)`을
  부르면 된다. 아래 "짝을 맞춰 `0`" 규칙은 **값이 정말 없는 자리**(Ref/`nil`)에만
  해당한다 — plain 요소는 `None` + `setLength(1)`이 정상이다. 대상은 일반 `Ref`뿐 아니라 **그 배열
  위치의 값 자체가 `None`인 모든 경우**(예: `props.Ref or None` 관용구로
  캐우칭된 미전달 Ref) — `setLength`도
  같은 위치엔 짝을 맞춰 `0`으로 등록해야 함(위 `setLength` 항목의
  "`nil`/`None`이면 `0`" 규칙과 항상 같이 감, 둘 중 하나만 반영되면
  길이 합계와 실제 순서 계산이 어긋남). **[정정, 2026-08-14 두 번째 세션]
  `PreRef` pre-pass가 소진시킨 슬롯은 더 이상 이 목록에 없음** — 예전엔
  그 슬롯도 `None`으로 뭉뚱그려 등록해야 한다고만 서술돼 있었는데,
  `None` 소진 슬롯은 정의상 어떤 Handler도 안 거치므로(위 "`None` 센티널"
  절) "누가 이 등록을 실제로 호출하는가"가 답 없는 갭이었음(2026-08-14
  첫 번째 세션 조사에서 발견). 지금은 그 슬롯이 전용 센티널
  `ProcessedPreRef`로 소진되고, **`ProcessedPreRefHandler`(`base/
  ref-plan.md`의 "PreRef" 절)가 정상 매치 과정에서 직접 `setLength(0)`/
  `setOffsetSource(None)`을 등록** — "그 위치의 말단 Handler가 등록 책임을
  진다"는 위 원칙을 특수 취급 없이 그대로 만족.
  **[2026-08-14 아홉 번째 세션] `PostRef` 소진 자리도 동일** —
  `ProcessedPostRefHandler`(`base/ref-plan.md`의 "`PostRef`" 절)가 같은
  두 등록을 하는 거울상 Handler라, 새 규칙 없이 그대로 맞물림.
  **[정정, 2026-08-18 구현 전 QA] 값 자체가 `None`/`nil`인 자리도 이제
  같은 원칙으로 덮인다** — `Dispatch.drive`가 `None`을 건너뛰지 않으므로
  그 자리는 `NoneHandler`(재귀만) → `NilHandler`(말단)를 거치고,
  **등록을 실제로 하는 건 `NilHandler`**(위 "`NilHandler`" 절).
  `State<Slot|None>`처럼 반응형 값이 뒤늦게 `None`을 내놓는 경로도
  같은 자리로 수렴한다.

**해제(그 자리가 더 이상 기여하지 않게 될 때)는 `setOffsetSource(...,None)`
→ `setLength(...,0)` 순서로 (2026-08-13 여섯 번째 세션, 사용자 지적).**
별도 unregister API는 없고 `0`/`None` 재등록이 곧 해제인데, **순서가
반대면 위험함**: `setLength`가 끝에서 `gatedRecompute`를 경유해(배치
게이팅 중이 아니면) `recompute`를 돌리므로, 먼저 부르면 그 `recompute`가
아직 남아있는 옛 `Source`(지금 막 떼어내는
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

**저장 위치**: `lengthList`/`sourceList`/`observers`(부모 `inst` 하나에
귀속) + 그 owner가 지금 등록해둔 position 개수 `N`(`bk.N`으로 같이 저장)
— `Relate(parentInst)`에 lazy 생성.

**[신설, 2026-08-18 구현 전 QA 3라운드] `bk.N`의 수명주기 — 두 owner
타입(물리 `inst`, Slot 자신) 모두 같은 규칙 하나로 통일.** 이전엔
`bk.N`을 "`Dispatch.drive`가 최초 배열 파트 순회 시점에 이미 아는, 저작
시점에 고정된 값"으로만 서술했는데, `base/slot-plan.md`의 "재귀
메커니즘" 절이 같은 `recompute`/`getBookkeeping`을 **Slot 자신**을
ownerKey로 재사용하면서 이 전제(N이 고정)가 안 맞는 케이스가 생겼다 —
Slot의 자식 개수는 생애주기 내내 바뀐다(그게 Slot의 존재 이유). **사용자
확정(2026-08-18)**: *"bk.N = 그때그때 실제 개수(새 최대 위치가 등록될
때마다 증가, spliceArraysDown이 압축할 때 감소)로 두 owner 타입에
동일하게 적용"* — 즉:
- `Dispatch.setLength`가 이전에 등록된 적 없는 더 큰 position `i`를
  등록할 때마다 `bk.N`이 `i`로 늘어난다(`Dispatch.drive`의 배열 파트
  순회, `materializeSlotTree`의 등록 배치, Slot의 런타임 단건 `rawAdd` 전부 이
  하나의 규칙) — **`Dispatch.setOffsetSource`는 `bk.N`을 건드리지
  않는다**, 호출 순서가 항상 `setOffsetSource(i)` → `setLength(i)`라서
  (아래 "`setLength` 구현" 절) `bk.N`을 `setLength`에서만 올려야
  `lengthList[i]`가 아직 안 채워진 채로 `bk.N`만 먼저 커지는 창이 안
  생긴다.
- `spliceArraysDown`(Slot의 `rawRemove`/`rawUnmount`가 부름, `base/
  slot-plan.md` "파괴" 절)이 position 하나를 구조적으로 제거할 때마다
  `bk.N`이 그만큼 줄어든다.
- `Dispatch.drive`의 `inst`에서는 이 규칙이 사실상 안 보인다 — 최상위
  배열 리터럴은 구조적으로 늘거나 줄지 않으므로(재-dispatch는 전체
  교체) `bk.N`이 등록이 끝난 뒤로는 그냥 고정값처럼 보일 뿐, 별도
  케이스가 아니라 같은 규칙의 특수한 안정 상태다.

**이게 배치 등록 중 크래시(`RC-1`)를 다시 불러오지 않는 이유**: 배치
등록 중(`Dispatch.drive`/`materializeSlotTree`의 등록 루프)엔 아래 "배치 등록을
안전하게 만드는 Blocker 게이팅" 절의 `blocker:IsOn()` 게이트가
`recompute` 호출 자체를 막는다 — 이 게이트는 `bk.N`을 전혀 보지 않으므로,
배치 도중 `bk.N`이 최종 크기보다 작은 채로 계속 늘어나는 중이어도
안전하다. `RC-1`의 원래 크래시는 **`bk.N`이 배치가 시작되기도 전에 이미
최종 크기로 고정돼 있었던 것**의 부산물이었을 뿐 — 지금은 그 전제 자체가
없다. 그런데도 Blocker 게이팅이 여전히 필요한 이유는 크래시 방지가
아니라 **비용**이다(등록마다 `recompute`가 한 번씩 도는 O(N²) 대신
배치 끝에 O(1)번만) — `RC-1` 해결 논의에서 사용자가 직접 지적한 "이러면
첫 실행에서 계속 recompute 비용이 쌓임" 문제 그대로. 상세 트레이싱은
`qa-request/pre-implementation-qa-round3.md`의 "`bk.N`의 수명주기가
명세에 없음" 절.

**`sourceList`에도 `nil`이 아니라 `None`을 쓰는 이유는 기존 배열 파트
원칙 재사용** — 모든 number 인덱스를 반드시 채워야 하는데(위 UB 규칙)
`nil`을 넣으면 (1) 그 자리가 "안 채워짐"과 구별이 안 되고 (2) 배열이
구멍 나면서 순수 array 취급이 깨져 접근 비용이 올라감(해시 파트로 밀림)
— `None`은 실재하는 값이라 자리를 "채워짐"으로 유지시켜줌, `flattened`
배열이 진짜 빈 자리(`None`, 예: `props.Ref or None`)와 pre-pass 소진
자리(`ProcessedPreRef`/`ProcessedPostRef`, 2026-08-14 두 번째 세션
이전엔 여기도 `None`)
둘 다 실재하는 센티널로 채워 구멍을 피하는 것과 같은 원칙(`ref-plan.md`의
"Ref 일반화" 절 "왜 `None`이 아니라 `nil`인가" 참고 — **단, 그 절에서
최종적으로 `nil`로 되돌아간 건 Ref 콜백/대기자 배열 한정**이고
`sourceList`/`flattened`처럼 순서가 실제로 중요하거나 "채워짐 여부"를
엄밀히 구별해야 하는 배열은 여전히 실재하는 센티널이 맞음, 헷갈리지
말 것). 다만 `recompute`가
`1..N` 고정 범위를 도는 인덱스 `for`라 애초에 성긴 정수 키 순회 문제
자체는 안 생김 — `None`이 필요한 이유는 순회 순서 보존이 아니라 "채워짐
여부 구별과 접근 비용" 쪽.

**recompute — 매번 전체 순회, `Get` 가드로 캐스케이드만 방지**:

**✅ [해결, 2026-08-18 구현 전 QA 2라운드 후속] 아래 의사코드를 배치
등록 중 안전하지 않게 만들던 크래시(`RC-1`)는 해결됨 — 해법은 "배치
등록을 안전하게 만드는 Blocker 게이팅" 절(바로 아래)이 소스, 여기
`recompute` 자체의 코드는 안 바뀜(off-by-one 수정 버전 그대로). 바뀐
건 **언제 호출되는가**뿐 — `setLength`/`setOffsetSource`가 새로 개입한다.
트레이싱 경위·논의 원문은 `qa-request/pre-implementation-qa-round2.md`의
"RC-1" 절.

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
**⭐ [2026-08-21 5라운드 `DC-14`] 게다가 그 마지막 경로조차 사용자에겐
막혀 있다** — `updateFn`이 도는 Slot은 정의상 `_listed`이고, `_crudUsed` ↔
`_listed` 상호 배타 가드(`base/slot-plan.md`) 때문에 그 Slot의 공개 CRUD가
이미 error다(사용자 지적: *"외부 입장에서는 그럴 방법이 없어보인다. crud 가
list 시에는 더이상 불가능해지기 때문"*). 즉 같은 `(ownerKey, bk)` 재진입은
**정상 API로는 만들 수 없다** — `updateFn` 안에서 *다른* Slot을 건드리는 건
다른 `bk`라 무관하다.
**결론: `recompute`는 off-by-one만 고친 순수 버전으로 유지, 재진입
가드 없음.**

**이 케이스를 명시적으로 UB로 명명(2026-08-11 세션, 사용자 제안)** —
`Source<T>`가 `State<T>`를 "단방향"으로만 만족한다는 이미 확정된 원칙
(`base/source-state-plan.md` "Source가 State를 만족함" 절 — 파생값이
자기 upstream Source로 거꾸로 쓰기를 하지 않는다는 것)과 **같은 카테고리의
위반**이라는 게 근거: `recompute`가 만드는 `offset`/`Length`는 전부
`lengthList`(그 Slot의 upstream 입력)에서 파생된 다운스트림 값인데,
계산 도중 촉발된 부작용이 **자기 자신의 `lengthList` 입력을 다시
mutate**하는 게 바로 그 반대 방향 쓰기. "State가 자기 Source에 `Set`을
가하는 것"이 UB인 것과 동일한 이유로, "recompute 도중 발생한 부작용이
같은 Slot의 length에 다시 쓰기를 가하는 것"도 UB로 문서화 — 새 원칙이
아니라 이미 있는 단방향 흐름 원칙을 recompute라는 구체 지점에 적용한
것뿐, 그래서 별도 방어 로직도 필요 없음.

**⭐ [2026-08-21 구현 전 QA 5라운드 G절, 사용자 확정] 이 절이 두 번 고쳐졌다.**
물리 삽입 op(당시 가칭 `mountInst`, 확정 이름은 `nativeInsert`)에 삽입 위치를
어떻게 주느냐는 질문에서 결함 둘이 드러났고,
사용자가 제시한 방향으로 정리됐다:

1. **`sourceList`의 `None`은 "발행 채널 없음"만 뜻한다** — 예전엔 "실제 마운트를
   하지 않는 위치"라고 정의해놓고 정작 plain 요소를 `None` + `setLength(1)`로
   등록하고 있었다(그래서 그 자리의 offset 숫자가 **계산조차 안 됐고**, DOM류
   백엔드가 삽입 위치를 알 방법이 없었다). **참여 여부는 `lengthList`가 이미
   표현하므로** `sourceList`는 "반응형으로 받아볼 채널이 있나"만 답하면 된다.
2. **숫자가 필요한 쪽은 `Dispatch.getOffsetAt(ownerKey, i)`로 직접 뽑는다**
   (사용자 제안: *"setOffsetSource 에선 source 를 받으면 그건 set 해주지만,
   아니면 그냥 얼리리턴에 None 으로만 둬주고, getOffsetAt 은 직접 호출하는걸로"*)
   — 모든 자리에 숫자를 밀어 넣는 네 번째 병렬 배열을 만들지 않고 **pull로**
   둔다("관측해야 실체화된다" 원칙과 같은 결).
3. **`sum`이 owner의 자기 offset에서 시작한다** — 예전엔 `0`이라 **depth ≥ 2에서
   중첩 Slot의 자식 offset이 부모 베이스만큼 어긋났다**(depth 1만 쓰던 동안
   드러나지 않았음). **베이스를 따로 저장하지 않는다** — Slot이면 자기
   `.Offset`이 곧 그 값이고(부모가 먼저 설정해주므로 이미 정확), 최상위 물리
   inst엔 베이스라는 개념이 없어 항상 0이다. 한때 `bk.base` 필드에 복사해두는
   안을 적었다가 **사용자 지적으로 걷어냈다**: *"bk.base 가 왜 필요한거임? …
   이건 slot 안의 slot.offset 이랑 기능이 겹칠텐데, 부모 slot 의 offset 읽는게
   이미 정확해 … 최상위에선 애초에 base자체가 없지 않아? 항상 0 일텐데."*
   같은 값을 두 곳에 두면 갈라진다는, 이 코퍼스가 반복해서 물린 패턴 그대로다.
   **`isSlot` 분기가 남는 건 타입 분기라서가 아니라 검사할 다른 방법이 없어서다**
   — `ownerKey.Offset`을 그냥 인덱싱해 확인하는 duck-typing은 Roblox userdata에서
   정의 안 된 키 인덱싱이 에러를 던질 수 있어 금지돼 있다(`base/brand-plan.md`의
   duck-typing 기각 근거).
4. **깊은 전파를 위해 중첩 Slot은 자기 `Offset`을 관측한다** — 앞 형제의 길이가
   변해 자기 베이스가 밀리면 자기 자식들의 offset도 다시 계산돼야 한다(사용자:
   *"자식 slot 의 offset 을 다시 설정해주기 위함이구나. offset의 깊은 전파를
   위한거군"*).

```lua
-- [신설, 2026-08-21 G절] 그 자리의 **절대 offset(0-based)** 을 그때그때 계산해 반환.
-- 발행 채널(Source) 유무와 무관하게 누구나 부를 수 있다 — nativeInsert의 삽입 위치,
-- setOffsetSource의 즉시 계산이 둘 다 이걸 쓴다.
function Dispatch.getOffsetAt(ownerKey, at)
    local bk = getBookkeeping(ownerKey)
    -- [2026-08-21 사용자 제안, 같은 날 의사코드 정정] **단일 함수 + 접두합 캐시.**
    -- `bk.offsetCache[i]` = i 자리의 절대 offset, `bk.invalidAfter` = **여기까지는
    -- 캐시가 유효**(그 뒤부터 다시 누적해야 함). 함수를 둘로 나누지 않는다 —
    -- 이 하나가 필요한 만큼만 앞으로 이어붙이므로, 순차 호출이면 한 칸씩만
    -- 늘어나 전체가 O(N)이 된다(사용자: *"그러면 알아서 순차적으로 합캐시가
    -- 처리됨"*).
    if bk.invalidAfter == 0 then
        -- 시작점 — 1번 자리의 offset은 이 owner의 베이스 그 자체.
        bk.offsetCache[1] = if isSlot(ownerKey) then ownerKey.Offset:Get() else 0
        bk.invalidAfter = 1
    end
    if at <= bk.invalidAfter then
        return bk.offsetCache[at]              -- 유효 구간 — O(1)
    end
    local cur = bk.offsetCache[bk.invalidAfter]
    for i = bk.invalidAfter, at - 1 do
        cur += contribution(bk, i)             -- lengthList[i](State면 :Get())
        bk.offsetCache[i + 1] = cur            -- **지금 자리의 길이가 다음 자리의 offset을 정한다**
    end
    bk.invalidAfter = at                       -- 여기까지 유효해짐
    return cur
end
```

**⭐ [2026-08-21] 캐시 무효화 — 규칙이 하나다**

`bk.invalidAfter`는 **"이 인덱스까지는 캐시가 유효"**를 뜻하고, 무효화는 전부
같은 모양이다 — **`bk.invalidAfter = math.min(bk.invalidAfter, i)`**(앞으로만
당긴다):

| 무엇이 바뀌나 | 어디까지 당기나 | 왜 |
|---|---|---|
| `setLength(ownerKey, i, ...)`, 그리고 그 State가 나중에 emit할 때 | `i` | **`i` 자리의 offset은 안 바뀐다**(그건 `1..i-1`의 합) — 바뀌는 건 그 **뒤**뿐. 사용자: *"정확히 입력받은 자신 인덱스까지 당김"* |
| `spliceArraysUp`/`spliceArraysDown`(자리 삽입·삭제) | `i` | 같은 이유 — 삽입/삭제 후에도 `i` 자리의 offset은 여전히 `1..i-1`의 합이다 |
| owner의 베이스 변경(`ownerKey.Offset`이 바뀜 = `_baseObserver`가 도는 순간) | `0` | 1번 자리부터 전부 다시 |

**`recompute`도 이 캐시 위에 얹힌다** — `1..N`을 순서대로 도는 함수라 매 자리에서
`getOffsetAt`이 한 칸씩만 이어붙이므로 전체가 O(N)이고, 별도 접두합 로직을 따로
두지 않는다. (그래서 "`recompute`가 캐시를 채울지 말지"라는 갈래 자체가 없어졌다 —
사용자: *"함수를 나눠야할 이유를 모르겠음. 하나로 두는게 나아보임."*)

```lua
local function recompute(ownerKey, bk)
    -- [2026-08-21 G절] `0`이 아니라 이 owner의 베이스에서 시작한다.
    -- 베이스는 별도로 저장하지 않는다 — Slot이면 자기 `.Offset`이 곧 그 값이고
    -- (부모가 먼저 설정해두므로 이미 정확하다), 최상위 물리 inst엔 베이스가
    -- 아예 없어 항상 0이다. 위 `getOffsetAt`과 같은 식.
    -- [2026-08-21] offset 값은 위 `getOffsetAt`(접두합 캐시)에서 받는다 —
    -- 여기서 따로 누적하지 않는다. 순서대로 도는 순회라 캐시가 한 칸씩만 늘어나
    -- 전체 O(N).
    local sum = 0
    -- [2026-08-21 5라운드 감사] `bk.N or 0` — **빈 Slot 크래시 방어**.
    -- `bk.N`은 `setLength`가 처음 불릴 때 생기므로(`bk.N = math.max(bk.N or 0, i)`),
    -- 요소가 하나도 없는 Slot(`Slot()` 직후, 데이터가 빈 `:List` 등)은 `N`이 `nil`인
    -- 채로 `materializeSlotTree` 끝의 recompute에 도달한다 — `for i = 1, nil`은
    -- 그 자리에서 터진다. 빈 Slot은 완전히 정상적인 상태라 이건 방어가 아니라 계약.
    for i = 1, bk.N or 0 do
        local offset = bk.sourceList[i]
        -- offset은 실제 Source이거나 None(발행 채널 없음) — None은 truthy라
        -- `if offset then`만으로는 안 걸러짐, 명시적으로 배제해야 함.
        -- [전면 정정, 2026-08-20 QA 4라운드 `C-6`] `nil`은 skip이 아니라 error.
        -- 도달 경로가 없다는 게 재추적 결론이므로(bk.N=실제 개수, 배치 중엔
        -- Blocker 게이팅, 해제는 None, spliceArraysDown은 압축), nil이 보이면
        -- 부기가 깨진 것 — 조용히 건너뛰면 위치 하나가 순서 계산에서 빠지는
        -- 추적 어려운 오작동이 된다. 상세는 base/slot-plan.md의 "추가 방어 조치".
        if offset == nil then
            error("Dispatch.recompute: sourceList[" .. i .. "]가 nil — 부기가 깨졌음(계약상 None이어야 함)")
        end
        local abs = Dispatch.getOffsetAt(ownerKey, i)           -- 절대 offset(캐시 경유)
        if offset ~= None and offset:Get() ~= abs then          -- 실제로 다를 때만 Set
            offset:Set(abs)
        end
        local v = bk.lengthList[i]
        sum += (if isState(v) then v:Get() else v)
    end
    if isSlot(ownerKey) and ownerKey.Length:Get() ~= sum then
        ownerKey.Length:Set(sum)   -- **Length엔 base를 안 더한다** — 길이는 위치와 무관
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

전체 순회의 O(N) 비용은 무시 가능(`Dispatch.drive`의 최상위 `inst`
기준으로는 `N`이 저작 시점에 고정된 배열 리터럴 길이, 보통 작음 —
Slot 자신이 `ownerKey`인 재귀 케이스는 `N`이 생애주기 내내 바뀌지만
그 실제 개수 자체도 보통 작아서 결론은 같음, `N`의 정확한 수명주기는
위 "저장 위치" 절 참고) — 진짜 비싼 건 `Set`이 트리거하는 다운스트림 리액티브
캐스케이드(그 위치에 이미 마운트된 원소들의 `LayoutOrder` 재적용)라,
`Get() ~= sum`일 때만 `Set`해서 안 바뀐 앞쪽 위치들은 캐스케이드가 안
일어나게 막음.

**`setLength` 구현 — leaf-lifetime 경로(`bindLifetime`/`unbindLifetime`),
`:Subscribe()` 아님(2026-08-09 여섯 번째 세션).** **[재작성, 2026-08-18
구현 전 QA 2라운드 후속 — `RC-1` 해결]** `setLength`는 더 이상 `recompute`를
직접 부르지 않는다 — State든 상수든 항상 아래 `gatedRecompute` 하나를
경유하고, 그 함수가 `blocker:IsOn()`을 확인해 배치 등록 중이면 건너뛴다
(Observer의 "등록 즉시 1회 실행"으로 촉발되는 최초 호출도 예외 없이 이
게이트를 통과한다 — 사용자: *"setLength 는 recompute 를 직접 수행하진
않고, Observer 에서 recompute 를 수행해. 맨 처음 emit 에서도 blocker 가
on 이면 무시하는식"*). `blocker`가 무엇이고 어디서 오는지는 바로 아래
"배치 등록을 안전하게 만드는 Blocker 게이팅" 절 참고 — 이 함수는 그
Blocker를 `getBlocker(ownerKey)`로 조회만 한다(만들거나 켜고 끄지 않음,
그건 호출하는 배치 쪽 책임):

```lua
-- [시그니처 변경, 2026-08-21 구현 전 QA 5라운드 `C-4`] 4번째 인자 `anchor` 신설 —
-- **부기 키(`ownerKey`)와 생명주기 앵커(`anchor`)를 분리**한다. 아래 절 참고.
-- **생략하면 `ownerKey`** — 최상위(물리 inst가 곧 owner)에선 둘이 같은 값이라
-- 기존 3-인자 호출부가 전부 그대로 맞고, **`ownerKey`가 Slot일 때만** 물리
-- target을 명시적으로 넘기면 된다(그 경우에만 둘이 갈린다).
function Dispatch.setLength(ownerKey, i, len, anchor)
    anchor = anchor or ownerKey
    local bk = getBookkeeping(ownerKey)   -- Relate(ownerKey) 기반, lazy 생성
    local blocker = getBlocker(ownerKey)  -- Relate(ownerKey) 기반, lazy 생성(아래 절 참고)

    local oldObserver = bk.observers[i]
    if oldObserver then
        unbindLifetime(oldObserver)   -- gchold 내부 구조도, 어느 inst였는지도 몰라도 됨
        bk.observers[i] = nil
    end

    bk.lengthList[i] = len
    bk.N = math.max(bk.N or 0, i)   -- [2026-08-18 3라운드] N 수명주기 — "저장 위치" 절 참고

    local function gatedRecompute()
        if not blocker:IsOn() then
            recompute(ownerKey, bk)
        end
    end

    if isState(len) then
        local observer = len:Observer(gatedRecompute)   -- 등록 즉시 1회 실행도 게이팅됨
        bindLifetime(anchor, observer)     -- **물리 target**의 생명주기에 귀속, Subscribe 아님
                                           -- (ownerKey는 부기 키일 뿐 — 아래 절)
        bk.observers[i] = observer
    else
        gatedRecompute()   -- 상수 길이도 같은 게이트를 통과 — setLength 자신은 recompute를 직접 안 부름
    end
end
```

**⭐ [2026-08-21 구현 전 QA 5라운드 `C-4`] 부기 키와 생명주기 앵커는 별개다 —
4라운드 `D-56`의 결론을 되돌린다.**

4라운드는 "`ownerKey`가 Slot일 수 있으니 **백엔드의 `bindLifetime`이 Slot을
첫 인자로 받는 경우를 핸들링**하고, `isBoundAlive`에 세 번째 분기를 둬라"로
결론냈었다. 5라운드에서 사용자가 그 전제 자체에 의문을 제기했고(*"애초에
Slot 이 effect 나 다른 요소들을 소유할 수가 없다 … 실제 observer/effect 는
실제 inst 에 불림 … 우리가 왜 slot 을 소유 대상으로 둘 수 있게 한거였는지
다시 생각해봐야할 부분"*), 검토 결과 **되돌리는 쪽이 맞다**:

- 이 Observer가 살아야 하는 기간은 "이 Slot이 **그 물리 트리에 마운트돼
  있는 동안**"이고, 그건 `physicalTarget`이 정확히 표현한다. Slot 자신의
  생존은 부모의 `_elements` 강참조가 이미 보장한다.
- **`setLength`가 불리는 모든 자리에서 물리 target을 이미 알고 있다** —
  `Dispatch.drive`(=`inst`), `materializeSlotTree`(=`physicalTarget`),
  런타임 단건 `rawAdd`/`rawReplace`(=`self._mountedInst`).
- 그래서 **`bindLifetime`의 첫 인자는 항상 물리 Instance**로 되돌아가고,
  `base/lifecycle-pattern.md`가 지고 있던 백엔드 요구사항(비-Instance 첫 인자
  핸들링)과 `isBoundAlive`의 **세 번째 분기가 통째로 불필요**해진다(그건
  아직 형태가 미정인 채 열려 있던 항목이었다). 옛 결론 원문은
  `archive/bindlifetime-slot-owner-reversed.md`.
- **포탈(언마운트→재마운트)에서도 자연히 맞는다** — `unmountSlotTree`가
  `bk.observers`를 `unbindLifetime`하고, 재마운트 시 `materializeSlotTree`가
  새 `physicalTarget`을 앵커로 다시 등록한다.
- **`getBookkeeping(ownerKey)`/`getBlocker(ownerKey)`는 그대로 Slot을 키로
  쓴다** — 그건 `Relate`의 weak 키일 뿐 생명주기 앵커가 아니다.
- **`anchor`는 `len`이 State일 때만 실제로 쓰인다**(상수 길이는 Observer를
  안 만들므로). **생략 시 `ownerKey`로 폴백**하므로 최상위 호출부
  (`Dispatch.drive`, `ProcessedPreRefHandler`/`NilHandler` 등 `inst`를 owner로
  쓰는 자리 전부)는 **기존 3-인자 그대로 두면 된다** — 거기선 `ownerKey`가 곧
  물리 target이다. 4번째 인자를 실제로 넘겨야 하는 건 **`ownerKey`가 Slot인
  자리**(`materializeSlotTree`의 등록 루프, 런타임 `rawAdd`/`rawReplace`)뿐이다.

`:Subscribe()`/`:Unsubscribe()`(독립 경로)를 안 쓰는 이유: 이 Observer는
본질적으로 `ownerKey` 하나에 종속된 내부 배관이라, `ownerKey`(물리 inst
또는 Slot 자신)가 죽을 때 같이 죽어야 함 — `:Subscribe()`는 명시적
`:Unsubscribe()`가 없으면 안 끊기므로 안 맞음. `bindLifetime`/
`unbindLifetime`이 이미 이 요구(GC-native, `ownerKey` 생명주기에 자동
귀속)를 충족.

### 배치 등록을 안전하게 만드는 Blocker 게이팅 (2026-08-18, `RC-1` 해결)

**문제 재확인**: `bk.N`(그 owner의 array part 크기)은 배치가 시작되는
시점에 이미 정해져 있는데, `bk.lengthList[1..N]`은 각 position이 처리될
때마다 하나씩 채워진다 — 순차 처리 도중에 `recompute`가 돌면 아직 안
채워진 뒤쪽 position을 `nil`로 읽어 산술 에러가 난다(`Frame{A,B}`처럼
정적 자식 2개짜리도 재현됨, 트레이싱 상세는
`qa-request/pre-implementation-qa-round2.md`의 "RC-1" 절).

**[정정, 2026-08-18 구현 전 QA 3라운드] 위 크래시는 `bk.N`이 "배치 시작
전에 이미 최종 크기로 고정"이라는, 그때 당시의 전제 위에서만 성립한다 —
그 전제 자체가 위 "저장 위치" 절에서 뒤집혔다(`bk.N`은 이제 그때그때
실제 개수). 아래 게이팅은 여전히 필요하지만, 지금은 **크래시 방지가
아니라 비용** 때문이다 — 게이팅 없이 등록마다 `recompute`가 한 번씩
돌면 O(N²), 게이팅으로 배치 끝에 한 번만 돌면 O(N). 상세는 "저장 위치"
절 참고.

**해법의 핵심 — recompute를 배치가 끝날 때까지 미루고, offset은 그
자리에서 직접 계산한다(사용자 설계, 2026-08-18)**:

1. **배치를 여는 쪽(`Dispatch.drive` 최상위, 또는 `materializeSlotTree`가
   자기 자신의 `_elements`를 등록하는 자리 — 아래 "적용 지점" 참고)이 그
   owner 전용 `Blocker`를 `Relate(ownerKey)`에 lazy 생성하고 배치 시작
   전에 `:On()`한다.** 이 Blocker는 `state:Block()`을 거치지 않고
   **직접** 쓰인다 — `base/blocker-plan.md`의 "`state:Block()` 없이
   직접 쓰는 두 번째 용례" 절 참고.
2. 배치가 도는 동안, 각 position의 `setLength`가 트리거하는
   `gatedRecompute`(위)는 `blocker:IsOn()`이 참이라 전부 스킵된다 — 즉
   **배치 도중엔 `recompute`가 단 한 번도 안 돈다**, 그래서
   `bk.lengthList`의 빈 자리를 읽을 일 자체가 없다.
3. **`setOffsetSource`는 그동안 손 놓고 있지 않는다 — 등록되는 그
   자리에서 자기보다 앞선 position들의 길이 합을 직접 계산해 `:Set`한다**
   (아래 "`setOffsetSource`의 즉시 계산" 참고). 배치가 항상 position을
   순서대로(1,2,...,N) 처리하므로, position `i`를 등록하는 시점엔 `1..i-1`이
   이미 전부 끝나 있어 이 합산이 항상 정확하다. **이게 "recompute를
   미루면 초기 레이아웃이 이상해진다"는 우려를 없앤다** — `:List`가
   실체화되며 `Slot.Offset`을 곧바로 읽어 쓰는 자리(`activateList`)가
   배치 중이라도 항상 최신값을 보게 됨.
4. 배치가 끝나면(`Dispatch.drive`의 배열 파트 순회 전체, 또는
   `materializeSlotTree`의 등록 루프 전체가 끝나면) `blocker:OffWithoutEmit()`을
   부르고, **그 직후 딱 한 번** `recompute(ownerKey, bk)`를 명시적으로
   호출한다. 이 시점엔 `bk.N`개 position이 전부 등록돼 있어 안전하고,
   `ownerKey`가 Slot이면 이 한 번의 recompute가 `ownerKey.Length`(위
   재귀 케이스)도 같이 확정시킨다.
   - **⭐ [2026-08-21 5라운드 `DC-11`] 이 마지막 호출이 실제로 하는 일은
     "offset 채우기"가 아니다.** offset은 3번의 즉시 계산이 등록 시점마다
     이미 정확히 넣어뒀고(position `i`의 offset은 `1..i-1`의 길이 합인데
     그것들은 `i`보다 먼저 등록되므로), 이 호출에서 `offset:Get() ~= sum`
     가드에 걸려 대부분 아무것도 안 쓴다. 실제 역할은 둘 —
     **(a) `ownerKey`가 Slot이면 `ownerKey.Length`(= 기여도 합) 확정**
     (사용자 추측대로 이게 주 목적), **(b) 등록된 뒤에 값이 바뀐 길이가
     있으면 그 뒤 형제들의 offset 교정**. 그래서 `ownerKey`가 물리 `inst`인
     `Dispatch.drive` 경로에선 (a)가 없어 사실상 검증 패스에 가깝지만,
     O(N) 순회에 `Set`이 거의 없으므로 분기해서 빼지 않고 그냥 항상 부른다.

**`setOffsetSource`의 즉시 계산(2026-08-18 신설, 2026-08-21 G절에 정리)** —
등록되는 그 자리에서 **`Dispatch.getOffsetAt(ownerKey, i)`**(= 베이스 +
`bk.lengthList[1..i-1]` 합)를 구해 곧바로 `:Set`한다. `source == None`이면
**얼리 리턴** — 발행할 채널이 없으니 계산할 이유가 없고, 그 자리 숫자가
필요한 쪽(예: `nativeInsert`의 삽입 위치)은 `getOffsetAt`을 직접 부른다:

```lua
-- [정리, 2026-08-21 G절] 합산 루프가 `Dispatch.getOffsetAt`으로 빠지면서
-- 이 함수는 "등록 + (채널이 있으면) 즉시 1회 발행"만 남는다.
function Dispatch.setOffsetSource(ownerKey, i, source)
    local bk = getBookkeeping(ownerKey)
    bk.sourceList[i] = source
    if source == None then
        return   -- 발행 채널이 없는 자리 — 계산할 이유가 없다. 숫자가 필요하면
                 -- 그때 `Dispatch.getOffsetAt(ownerKey, i)`을 직접 부른다.
    end
    local offset = Dispatch.getOffsetAt(ownerKey, i)   -- 배치가 순서대로 처리되므로
    if source:Get() ~= offset then                     -- 1..i-1은 항상 이미 등록돼 있음
        source:Set(offset)
    end
end
```

이건 `recompute`의 로직을 대체하는 게 아니라 **보완**한다 — 이 즉시
계산은 "지금 막 등록되는 이 position의 초기값"만 맞춰줄 뿐이고, 이후 어느
position의 length가 바뀌면(배치가 끝난 뒤 steady state에서) 그보다 뒤에
있는 모든 position의 offset을 다시 계산해야 하므로 여전히 `recompute`의
전체 순회가 필요하다 — 그 경로는 안 바뀜(위 `recompute` 코드 그대로).

**적용 지점 — `Dispatch.drive`와 `attachSlot`, 각각 자기 owner 키로
별도 Blocker**
(**[2026-08-21] `attachSlot` 쪽은 이제 정확히는 그 안의
`materializeSlotTree`다** — `attachSlot`이 "부기만 만드는 재귀"와 "물리만
붙이는 재귀" 둘로 분해되면서 Blocker가 **등록 쪽 하나만** 감싸게 됐고,
그래서 "배치 *등록* 게이팅"이라는 이 절의 정의와 실제 범위가 정확히
일치하게 됐다. 옛 코드는 물리 마운트까지 같이 감싸고 있었음.
`base/slot-plan.md`의 "재귀 메커니즘" 절이 소스): 이 배치 패턴이 실제로 크래시 위험이 있는 자리는 정확히
둘뿐이다(사용자 확인, 2026-08-18) — (a) `Dispatch.drive`가 최상위
`inst`의 배열 파트를 순회할 때, (b) `attachSlot`이 **자기 자신의**
`_elements`를 flush할 때(`base/slot-plan.md`의 "재귀 메커니즘" 절 —
중첩된 Slot마다 그 Slot 자신의 owner 키로 **별도** Blocker를 새로 만듦,
부모 Blocker 재사용 금지는 `base/blocker-plan.md`의 "재진입" 절 그대로).
**런타임에 이미 마운트된 Slot에 한 번에 하나씩 `:Add()`하는 흔한 패턴은
이 게이팅이 필요 없다** — 사용자 확인: *"그건 이미 마운트가 된
이후라서 별 상관 없음... 새로운 개체가 뒤에 붙는 현상에서는 위
요소들로 하여금 위치를 구하면 돼, 뒷 요소를 밀어내는게 아니라서,
setLength 가 emit 되지 않는것에 영향 안 받고 수행 가능함"* — 이미
마운트된 배치 밖에서 하나씩 추가되는 position은 그 앞의 모든 position이
이미 안정적으로 등록돼 있어 `nil` 자리를 만들 여지가 없고, 그 owner의
Blocker는 이미 `OffWithoutEmit()`으로 꺼진 채라 `gatedRecompute`가
평소처럼 즉시 돈다.

**⚠️ 불변식 — `Dispatch.process`/`attachSlot` 호출 체인 도중에는 코루틴
yield 금지(2026-08-18 신설, 사용자 확정).** 이 배치 게이팅 전체가
"position이 항상 1,2,...,N 순서대로, 다른 코드가 끼어들 틈 없이 동기로
처리된다"는 전제 위에 서 있다 — 이 체인 도중 어딘가(컴포넌트 함수,
`updateFn`, Handler 등) yield가 끼면, 아직 배치가 안 끝난 owner의 같은
`Blocker`를 다른 코드가 그 사이에 건드릴 수 있어(예: 다른 이벤트 콜백이
같은 owner에 `setLength`를 부르는 것) 배치 도중/직후의 게이팅 순서 보장이
깨진다. 사용자: *"모든 컴포넌트든 뭐든 yield 되면 안되는 sync 함수이여야
할듯. 안 그럼 꼬이는 문제가 발생하지 않나 생각함"* — 웹 백엔드처럼
`setLength`가 뒤섞이면 특히 골치 아파짐. 새 방어 로직을 넣는다는 뜻이
아니라(이미 확정된 "일반적인 재진입/무한루프는 방어 안 함" 원칙과 같은
톤), 이 계약을 어기면 UB라는 걸 문서로 못박아두는 것.

### ⭐ 일반 계약 — 물리와 부기의 순서 (2026-08-20 `C-7`로 승격, **2026-08-21 5라운드에 재정의**)

> **🔄 [역전됨, 2026-08-21] "부기가 물리 트리 조작보다 항상 먼저 끝난다"는
> 계약은 폐기됐다.** 원문은 `archive/bookkeeping-before-physical-reversed.md`.

**왜 뒤집혔나**: 그 계약은 *"`Length`를 먼저 올려 뒤 형제를 밀어내고, 비워진
그 공간에 넣는다"*는 그림 위에 서 있었는데, **base에는 물리적으로 자리를
비워둘 수단이 없다**(자리를 비워 `null`을 꽂아둘 수도 없다). 미는 주체는
언제나 백엔드의 삽입 연산 자신이다 — `native*` 계층이 들어오면서 이게
명확해졌다(사용자: *"nativeInsert 라는것 자체가 밀어내기 동작을 강제하는데,
그렇다면 length 를 나중에 설정한 다음 offset들이 무시되어야함. 일종의 웹 돔과
같은 동작을 내도록 강제하는 시스템"*).

**지금의 계약 — 셋으로 줄었다**:

1. **물리 조작은 `native*`가 전담하고, 밀고 당기는 건 그 op 자신이 한다**
   (DOM식 의미론을 시스템 전체가 강제).
2. **base의 offset 부기는 "배치 지시"가 아니라 계산값이다** — 이미 배치된
   것을 옮기지 않는다(`base/slot-plan.md`의 웹 백엔드 문단, 5라운드 확정).
3. **순서 규칙은 "자기 자리를 정하는 것 먼저 / 뒤를 미는 것 나중"** 하나다:
   - **`setOffsetSource`는 먼저** — 그 자리의 offset은 `1..i-1`의 합이라
     **자기 삽입/제거로 안 변한다.** 게다가 삽입 위치 계산이 이 값이고,
     Slot이면 `activateList`가 곧바로 그 값을 쓴다(C1).
   - **`setLength` → `recompute`는 나중** — 이게 **뒤를 미는** 쪽이다.
   - 그래서 `rawAdd`는 `spliceArraysUp` → `setOffsetSource` → `nativeInsert`
     → `setLength` → `recompute` 순서다(`base/slot-plan.md`).
4. **배치 경로는 여전히 "부기 전량 먼저"** — `materializeSlotTree` →
   `mountSlotTree` 분해는 그대로다. 그때는 삽입 위치가 전부 확정된 뒤에
   물리가 몰리는 것이고, C6("부모에게 미는 길이는 최종값")가 그걸 요구한다.
   위 3번과 모순이 아니다 — 3번은 **단건 경로**의 규칙이다.
- **⚠️ 프레임 경계는 여전히 안 낀다**(yield 금지) — 그래서 이 순서 변경으로
  사용자에게 보이는 중간 상태가 생기지 않는다. 옛 계약이 내세웠던 "한 프레임
  순서가 깨진 채 노출될 위험"은 그때 이미 근거에서 빠져 있었다.

**⚠️ [2026-08-22 정정] 여기 있던 "동기 순서 — offset 갱신이 마운트보다
먼저 끝나야 함" 문단은 위 역전으로 폐기됐다.** 그 문단은 *"Slot의 `rawAdd`는
부기를 먼저 완결하고(`setOffsetSource`/`setLength` 등록 → `recompute`) 그
다음에 물리 마운트를 호출한다"*고 적어, 바로 위 3번(자기 자리 먼저 →
`nativeInsert` → 뒤를 미는 것 나중)과 **정반대**였다. 실제 의사코드도 3번
쪽이다(`base/slot-plan.md`의 `rawAdd`). 이번 세션이 그 문단의 옛 op 이름만
`native*`로 바꾸고 순서 주장은 지나쳐서 남아 있던 것.
그 문단이 근거로 들던 "한 프레임 순서가 깨진 채 노출될 위험"은 **위
⚠️ 문단이 이미 기각**했다 — 프레임 경계가 안 끼므로 중간 상태 자체가
사용자에게 안 보인다.

**⭐ [전면 정정, 2026-08-21 구현 전 QA 5라운드 `C-2`] `rawAdd`가
`self.Length:Set(newCount)`를 직접 부른다는 옛 서술은 틀렸다.** 사용자
지적(*"rawAdd 에서도 필요한가는 모르겠음. 목적이 다르지 않나?"*)을 파고들다
확인된 것 셋:

1. **`newCount`(개수)는 더 이상 `Length`의 정의가 아니다** — `Length`는
   "요소별 기여도의 합"(plain=1, nested Slot=그 `.Length`)이라, 중첩이 있는
   순간 개수로 `Set`하면 틀린 값이 된다.
2. **쓰는 주체가 둘이 되면 안 된다** — `recompute`가 이미
   `ownerKey.Length:Set(sum)`으로 확정 기록을 한다.
3. **그 자리의 `Get() ~= newCount` 가드는 아무것도 안 거른다** — `rawAdd`에선
   카운트가 **항상** 달라지기 때문. 가드가 값을 하는 건 `recompute`의 전체
   순회 쪽뿐이다(위 `Get` 가드 문단).

**확정**: `Length`는 **`recompute`만 쓴다.** `rawAdd`/`rawReplace`는 자기 자리
부기를 등록하고 `recompute`를 한 번 부를 뿐이다.
**⚠️ [2026-08-22 정정]** 여기 *"그게 `Parent` 대입 앞에 오므로 '부기가 물리보다
먼저'는 그대로 지켜진다"*(+ 사용자 인용 *"recompute 가 length 를 잘 처리해놓고
나서 빈 공간에 들어가므로"*)라고 적혀 있었으나, 그건 **같은 라운드에 역전된
옛 C-7 일반 규칙**을 전제한 서술이다 — 지금 단건 경로는 `setOffsetSource` →
`nativeInsert` → `setLength` → `recompute`라 `recompute`가 물리 삽입보다
**뒤**다(위 "지금의 계약" 3번). 이 절의 결론(`Length`를 쓰는 주체는
`recompute` 하나뿐)은 그 순서와 무관하게 그대로 유효하다.
의사코드는 `base/slot-plan.md`의 `rawAdd`/`rawReplace`가 소스.

**`:List` reconcile에서 `Length` 갱신 시점**: 한 사이클(여러 항목이
한꺼번에 추가/제거되는 경우 포함) 전체가 끝난 뒤 **한 번만** — 사이클
도중 항목마다 갱신하면 캐스케이드가 그만큼 반복됨.

**웹 백엔드(quad-web, 아직 없음) — 같은 `lengthList`/`sourceList`/
`recompute`를 그대로 재사용, 다른 건 "offset 변경 시 무엇을 하는가"뿐**:
DOM의 `insertBefore`류는 물리적으로 삽입하면 뒤 형제가 자연히 밀려나므로,
`offset`이 바뀌었다고 이미 마운트된 원소를 실제로 옮길 필요가 없음
(**[2026-08-21 5라운드 재확인]** `nativeInsert`가 삽입 위치를 받게 된 뒤에도 이
결론은 그대로다 — 사용자 확정: *"애초에 offset 바뀌여도 상관 없는게 위에서 넣고
빼면 insert 같은거로 일어나서 뒤로 밀린다는거였긴함"*. 단 그게 성립하려면
백엔드 op이 **아토믹한 최소 단위**여야 한다) —
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
`self.Offset`으로도 저장. **[정정, 2026-08-20 구현 전 QA 4라운드 `D-60`/`SL-75`]
마운트 전엔 `nil`이 아니라 `0`이고, 언마운트해도 `nil`로 되돌리지 않는다** —
사용자 판정: *"마운트 전에는 0 이긴 함. 다만 list 의 관측으로 실체화된 값이
나오는게 offset 설정 이후라서 그 땐 0 이 아닐 수 있을 뿐"*. 즉 `Offset`은 항상
읽을 수 있는 `Source<number>`이고 마운트 전/언마운트 후엔 잠정값(`0` 또는 마지막
값)을 들고 있을 뿐이다. `nil`로 갈아치우면 그 Source를 이미 구독 중인
다운스트림이 끊겨 포탈이 깨진다 — 근거는 `base/slot-plan.md`의 "추가 방어 조치"
항목. **⭐ [2026-08-21 5라운드 `DC-6`, 사용자 정밀화] 더 정확히는, 언마운트
시점에 그 Slot이 이미 렌더해둔 요소들이 `LayoutOrder` 등을 위해 이 Source를
**계속 구독한 채로 함께 딸려 나간다**는 게 핵심이다. 그 상태에서 재마운트
때 `slot.Offset`에 **다른 Source 객체**를 넣으면, 딸려 나갔던 요소들은 여전히
옛 객체를 보고 있어 새 위치가 반영되지 않는다 — 포탈이 그 지점에서 깨진다.
그래서 언마운트는 값이 stale하게 남는 걸 감수하고 **객체 identity를 유지**하고,
재마운트 시 `setOffsetSource`의 즉시 계산이 같은 객체에 새 값을 `Set`한다. 위 정정대로 이 값을
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
부모 Instance에 자식을 끼워 넣는 경로(예: **사용자 코드**가 `newInst.Parent =
parentInst`를 직접 호출해 Slot이 마운트해둔 부모 밑에 자식을 몰래
추가/제거하는 것 — base 의사코드 쪽의 `Parent` 직접 조작은 2026-08-21에
전부 주입 op로 정정됐다, `base/slot-plan.md`의 "물리 조작은 주입 op다" 절)는 `lengthList`/`sourceList`가 그 변화를 전혀 모르게
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
서술했는데(새 프리미티브를 발명하는 것처럼 읽힐 수 있었음), 실제로는
`base/source-state-plan.md`의 "`state:Observer(fn)`" 절에서 이미 확정된 것을 그대로 재사용하면 됨 — 새
구독 primitive를 store-bind 전용으로 따로 만들 이유가 없음:

```lua
-- 예: 일반 프로퍼티 store-bind 핸들러의 process(inst, k, state, index)
function StoreBind.process(inst, k, state, index)
    local observer = state:Observer(function()
        local realv = state:Get()
        -- 선행 철거 없음 — 아래로 그냥 내려보내면 Dispatch.process가
        -- 핸들러를 비교해 (같으면) 그 자리 클로저에 realv를 넘기고,
        -- (다르면) 그 자리부터 아래를 철거하고 새로 설치함.
        Dispatch.process(inst, k, realv, index + 1)
    end)
    bindLifetime(inst, observer)
    return function()
        -- 자기 자신의 자원(Observer 구독)만 정리 — observer는 위 클로저가
        -- upvalue로 이미 캡처하고 있어 별도 Relate 저장/조회가 필요 없음
        -- (2026-08-13 다섯 번째 세션, 계약이 클로저 반환으로 바뀌며 단순화됨).
        unbindLifetime(observer)   -- 1-인자(2026-08-14 다섯 번째 세션)
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

- **반환하는 클로저가 할 일은 `unbindLifetime(observer)` 호출뿐 —
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
- **핸들러가 직접 `canExecute`/liveness를 재구현할 필요 없음** — State의
  전파 루프가 발화 때마다 `canExecute(observer)`로 각 구독자를 게이팅하고,
  그 판정 근거(`inst` 생존)는 `bindLifetime`이 `observer` 쪽에 복사해둔
  gcconn 참조가 제공함(`base/lifecycle-pattern.md`의
  "`bindLifetime`/`canBound`/`canExecute`/`unbindLifetime`" 절).
  **[정정, 2026-08-14 다섯 번째 세션]** 이 항목의 옛 근거(*"Observer가 이미
  자기 `Subscribed` 상태로 게이팅됨, `bindLifetime`도 그 필드를 세팅/해제"*)는
  틀렸음 — `.Subscribed`는 전역 `:Subscribe()` 전용 필드이고 `bindLifetime`은
  건드리지 않음. 결론(핸들러가 따로 안 짜도 됨)은 그대로, 근거만 바뀜.
  상세는 `archive/canexecute-inst-arg-reversed.md`.
- Observer가 "등록 즉시 1회 실행"이므로 **최초 적용과 이후 재실행이 같은
  코드 경로로 자동 통일**됨 — 프로퍼티 store-bind 핸들러가 "설치 시 1회
  적용"을 별도로 안 짜도 되는 이유(`base/bind-system-plan.md`의 Observer 절의
  원래 근거 그대로).

Slot이 store 바인드로 넘어오는 경우도 이 래핑 방식과 자연스럽게 맞음 —
`State<Slot>` 교체는 `Dispatch.process`가 (A)/(B) 분기로 판정하고, 그 자리
클로저가 이전 Slot을 언마운트한다(파괴가 아님 — `base/slot-plan.md`).

