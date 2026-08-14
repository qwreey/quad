# 모듈 라이프사이클 — Handler 패턴, bind/store는 누가 구현하는가 (base로 승격됨)

**상태**: base — "누가 store를 구현하는가"까지 포함해 전부 확정되어
`research/`에서 승격됨(`base/architecture.md`의 "구현 착수: 소스 트리 구조
확정" 절 참고). 원본:
`.claude/initreq/raw-userinput.md` "넘버 바인드는 누가 처리?" / "모듈은 스코핑
되는가" / "pluggable 하다면 해당 플러그를 초기화하는 건 누구 몫?" / "다시 돌아와서…
bind는 누가 어떻게 구현" / "스토어는 누가 구현해…" 절. 확정된 상위 결정은
`base/architecture.md` 12~14번 항목(멀티 백엔드, 싱글톤 모듈, 팩토리 초기화)
참고 — 이 문서는 그 안의 세부 미해결 사항만 다룸.

## 넘버 바인드(숫자 프로퍼티 등)는 누가 처리하는가

Slot과 맞물려서 잘 생각해서 구현해야 하는 부분. **기울어진 방향**: mount가
처리하는 게 맞아 보이지만, 그러면 확장성이 있을지가 문제. 결론: **표준 구현체는
인터페이스만 두고, 실제 구현은 `quad-roblox` 같은 백엔드 서브패키지가 해당
인터페이스를 구현**. 런타임에 Handler로 Roblox를 주입받는 방향(반대로
"Handler로 base를 받는" 게 아니라) — 이유: 여긴 가상돔이 없어서, base
쪽이 "누가 실제로 그려주는지" 모르는 채로 있다가 Roblox Handler를 주입받는
모양이 더 자연스러워 보임. (이름 자체는 이후 "Handler"로 확정 —
`base/dispatch-core-plan.md`의 핸들러 계약 절 참고, 이 문서는 여전히
초안 당시 표현인 "프로바이더"로 쓰여 있던 걸 정정.)

## pluggable 플러그 초기화는 누구 몫인가

RBVM처럼 `init namespace` 하나하나 부르는 방식은 별로(`base/lifecycle-pattern.md`
5번 항목에서 실제로 rbvm이 이렇게 되어 있는 걸 확인함 — `InitNamespace`/
`Registered`-가드/`NewLib` 3종 세트를 라이브러리마다 반복). 대신 **적절한 팩토리
함수 제공**: `InitRoblox(Module)` 식으로, 생성된 모듈을 뮤테이션할 수 있는 도구를
주고 사용자가 호출하도록. `base/architecture.md` 14번 항목과 동일한 결정 —
여기서는 "왜"만 보강.

## Bind는 누가, 어떻게 구현하는가

인터페이스 상 `bind`를 두고 이것도 pluggable하게 할지 고민 — 단 **1개만 존재할
수 있는 형태**로 구현하는 게 맞다고 기울어짐: 이미 bind 구현체가 있는데 또
init하려 하면 오류, 없는데 뭔가 생성해서 bind하려 해도 오류. 즉 "pluggable
슬롯이지만 유일하게 채워질 수 있는 슬롯" — 위의 `base/bind-system-plan.md`가
말하는 "여러 핸들러가 우선순위로 경쟁"하는 것과는 다른 층위: **핸들러
레지스트리 자체(그 배후의 실제 bind 구현/백엔드)는 유일해야 하고, 그 안에
등록되는 개별 핸들러들은 여럿+우선순위 경쟁이 맞는 모양.**

의존성을 부작용 식으로 주입해서 `quad-roblox` 바인드를 허용케 하는 건 괜찮아
보임(=`InitRoblox(Module)`가 하는 일이 바로 이 "유일 슬롯 채우기").

## Store는 누구 몫인가 — 상당 부분 확정됨

**사용자 확인 완료**: base가 `LifetimeHandle` 추상화(생명주기/`Connected`
계산 속성)를 소유하는 게 맞다고 확정. 추가로 명확해진 것 — **store 바인드가
수행하는 "처리된 값을 다시 `Dispatch.process(inst,k,realv)`로 넘기는" 재실행
로직 자체도 base가 한 번만 구현**해야 함(모든 백엔드/핸들러가 각자
재구현하면 안 됨). 근거: "모든 곳에서 다시 구현하는 건 나쁘니까." →
`base/dispatch-core-plan.md`의 "확정된 디스패치 모델"/`Dispatch` 네이밍 절이
바로 이 base 제공 로직.

부수적으로 확인된 것:
- **Store 자체의 연산은 더 단순해져도 됨** — v1의 `:Add`/`:With`/`:Tween` 같은
  이름 붙은 체이닝 연산(named modifier)은 명시적으로 안 만들기로 확정, 대신
  일반 함수를 받는 형태로 통일(`base/source-state-plan.md` 참고). "너무 verbose한
  연산들은 오히려 일관성을 해친다"는 게 이유. (주의: 아래의 v2 `:With(...)`는
  이름만 같을 뿐 여기서 안 만들기로 한 v1의 `:With`와는 다른 연산임 — v1은
  "함수/테이블에서 값을 가져오는" 가공 연산이었고, v2는 그냥 "여러 State를
  의존성으로 모으는" 수집 연산.)
- **여러 store 값을 묶어 유연하게 처리하는 방법**(`useEffect`류 dependency
  array)은 있으면 좋겠다는 요청이었고 — **API 시그니처도 확정됨**:
  `:With(...)`로 의존성을 모으고 `:Compute(fn)`으로 파생 State를 만드는
  형태, 상세는 `base/store-plan.md`의 "여러 스토어 값을 묶어 처리하는
  것" 절 참고.
- `can execute store bind` 후킹 자체는 `Connected` 계산 속성으로 대체된다는
  잠정 제안이 그대로 유지되고, 여기에 더해 **완전 소멸(Destroy) 시점엔 아무
  처리도 필요 없다**는 원칙까지 확정됨(`base/lifecycle-pattern.md`) — 즉 이
  질문은 "필요한가?"에서 "확정된 Connected 체크 하나로 충분하다"로 정리됨.
- 여러 `isHandlable`이 되는 플러그를 매번 우선순위 순으로 스캔하는 비용은
  여전히 실제 구현/벤치마크 단계에서 검증 필요 — 디자인 자체는 확정됐으므로
  더 이상 사용자 자문 대상이 아니라 구현 검증 대상.

## 모듈 스코핑 (참고, 확정은 `base/architecture.md` 13번)

한 Lua 스레드에서 둘 이상의 모듈 분화체(Roblox+비Roblox 동시)를 쓸 일이
거의 없을 거라 판단, 지금은 싱글톤으로 두고 필요해지면 `New()` 추가.

## Quad는 스크립트인가 라이브러리인가 (확정, 참고용)

이전엔 Instance를 보조하는 역할이라 "스크립트"로 분류했지만, 지금은 확실히
"라이브러리" — 구조화되어 있고 데이터 타입이 존재함. 기능을 각자 따로 묶는 게
아니라 하나의 시스템으로 돌 수 있게(pluggable 하게 두자는 논리의 근거이기도
함). `base/architecture.md` 도입부와 동일 결정.

## 열린 질문이었던 것 — 전부 해소됨 (2026-08-08 두 번째 세션 정리)

**이 문서 상단 "상태" 줄이 이미 "확정되어 승격됨"이라고 말하고 있었는데도
이 절 자체는 오래 stale로 방치돼 있었음** — 아래 4개 항목 중 2/3번은 그 뒤
`base/bind-system-plan.md`의 Handler 계약 확정으로 이미 풀렸는데 여기
반영이 안 됨. 원문은 남기고 각각에 해소 표시만 추가:

- **Store 책임 분리(base vs provider)는 확정됨** — 위 절 참고. ~~남은 건
  실제 구현 단계에서 base의 `LifetimeHandle`/재실행 유틸 API를 정확히
  어떻게 노출할지 정도~~ **[해소됨]** 노출 방식도 확정 — `bindLifetime`/
  `canExecute`는 네임스페이스 없는 탑레벨 함수(`base/lifecycle-pattern.md`),
  케이싱까지 포함해 `base/architecture.md` "코드 스타일 — 네이밍 케이싱"
  절 참고.
- ~~넘버 바인드/프로바이더 인터페이스의 정확한 함수 시그니처(base가 요구하는
  provider 인터페이스 계약)는 아직 미정~~ **[해소됨]** — 그 "provider
  인터페이스"가 곧 Handler 계약: `isHandlable(inst,key,value)`/
  `priority`/`process(inst,key,value,index)` **3종**(**[정정, 2026-08-13
  다섯 번째 세션]** 원래 별도 `retract(inst,key,value)` 필드가 있던 4종
  계약이었으나, `process`가 자기 retract 클로저 `(nextValue: any?) -> ()`를
  반환하는 1-메소드로 합쳐짐), 정리할 게 없어도 `function() end`
  반환 생략 불가까지 확정. `base/dispatch-core-plan.md` "핸들러 계약" 절.
- ~~**네이밍 미정(2026-08-04 보강)**: "프로바이더"라고 불러온 개념을 정확히
  뭐라고 부를지("provider" vs "processor" vs 그냥 "plug") 아직 안 정함~~
  **[해소됨]** — **`Handler`로 확정**, 위 항목이 가리키는 계약의 정식 이름.
  `Dispatch`(그 계약을 스캔/실행하는 엔진, 프리미티브 아닌 탑레벨 싱글톤)와
  구분해서 쓸 것 — `base/dispatch-core-plan.md` "Dispatch는 프리미티브가
  아니다" 절. **왜 다른 후보들을 기각했는지(2026-08-08 세션, 재확인)**:
  `Processor`는 계약 메소드 자체가 `process`라 이름 안에 같은 단어가
  겹쳐 눈에 거슬림, `Provider`는 `canProvide`처럼 "뭔가를 공급한다"는
  늬앙스인데 Handler는 실제로 값을 공급하는 게 아니라 처리/반응하는
  쪽이라 의미가 안 맞고 React `Context.Provider`류 맥락(context) 패턴과도
  헷갈릴 수 있음, `Plug`는 "동적으로 꽂힌다"는 어감은 맞지만 "값을
  처리한다"는 의미가 빠져 있음 — `Handler`가 계약 전체
  (`isHandlable`/`priority`/`process`, 위 항목 참고)를 가장 정확히
  담는다는 결론.
- **[해소됨, 2026-08-12 열일곱 번째 세션]** provider(팩토리)가 아직 한
  번도 실행 안 된 상태에서 dispatch가 호출되면 어떻게 되는지
  (`pre-implementation-audit.md` 1-4) — 별도 케이스로 처리하지 않음.
  provider 미주입 상태는 결국 그 클래스의 핸들러가 레지스트리에 하나도
  없는 상태이므로, `base/dispatch-core-plan.md` "우선순위 동률/매치 실패
  처리" 절의 일반 "매치 실패 시 즉시 error" 규칙 하나로 자연히 커버됨.
- base 유틸(per-instance 상태 저장소, 생명 바인드 유틸)이 인터페이스만 두고
  실제 구현은 백엔드 팩토리(`RobloxFactory(BaseModule)`류)가 뮤테이션으로
  주입한다는 패턴이 확정됨. **[2026-08-13 열네 번째 세션] 주입 대상 목록에
  엔진 op 3개가 추가됨** — `addTag(inst,{string})`/`removeTag(inst,{string})`/
  `setAttribute(inst,name,v)`(`v==nil`이면 삭제). `Tag`/`Attribute`의 부기
  알고리즘이 통째로 quad-base로 옮겨오면서, 엔진에 실제로 손대는 마지막
  한 줄만 이 경로로 주입받게 됨(`base/dispatch-core-plan.md` "base가
  소유하는 핸들러와 주입되는 엔진 op" 절). **`TagHandler`/
  `AttributeKeyHandler`/`AttributeGroupHandler` 자신은 quad-base가
  모듈 로드 시점에 `HANDLER_PRIORITY_FALLBACK`으로 스스로 등록** —
  `addTag`/`removeTag`/`setAttribute`만 백엔드 팩토리가 뮤테이션으로
  채우는 타입 계약. 아직 아무 팩토리도 안 채운 슬롯의 기본값은
  quad-base가 명시적으로 에러내는 스텁으로 미리 채워둠(조용한 no-op
  추측 아님 — base가 임의 엔진의 "맞는 기본 동작"을 알 수 없어서).
  더 명확한 메시지나 진짜 원자적 실패(부기 mutation 0회)를 원하는
  백엔드는 opt-in으로 `HANDLER_PRIORITY_FALLBACK + 1`짜리 가로채기
  Handler를 추가로 등록할 수 있음 — 상세는
  `base/dispatch-core-plan.md`의 같은 절. **중복 호출
  가드/`New()`와의 관계는 2026-08-04 3차 라운드에서 확정**: 같은 팩토리로
  재호출하면 무시(no-op), 다른 팩토리로 재호출하면 에러(유일 슬롯 충돌 —
  바로 위 "Bind는 누가, 어떻게 구현하는가" 절의 원칙과 일치) — `New()`가
  생기면 인스턴스별 테이블이 분리되므로 이 가드도 자연히 인스턴스별로
  스코핑됨, 별도 재설계 불필요. **이 결론이 Dispatch의 handler 레지스트리에도
  그대로 적용된다는 게 2026-08-08 두 번째 세션에서 재확인/일반화됨** —
  `base/dispatch-core-plan.md` "Dispatch는 프리미티브가 아니다" 절.
