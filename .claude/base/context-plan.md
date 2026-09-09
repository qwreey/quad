# `Context` — 명시적 값 컨테이너 (2026-09-08 신설·구현)

**상태**: base — 사용자 방향 확정 + 같은 날 구현(`quad-base/src/Context.luau`, 스펙 `spec.context`). 발단은 문서화
스캐폴딩 에이전트가 제기한 docs-ignoreme 초안의 research 문서 explicit-context-sugar-plan(무시 파일, 커밋 밖 — **[2026-09-09 삭제]** 구현·문서화 뒤 사용자 결정으로 초안에서 제거, `session/2026-09-09-01-docs-polish.md`)를 사용자가
검토해 *"필요가 내가 보아도 있는듯"*이라고 한 것(`session/2026-09-08-04-sugar-implementation.md` §6).

## 왜 — `archive/context-rejected.md`와 어떻게 다른가

옛 기각은 **암묵 맥락**(React `Context`/Vue `provide`-`inject`처럼 트리 위에 심어 두면 하위가 알아서 읽는 것 — Vide/Fusion은
코루틴 키로 해킹)이었다. 사용자 원문(2026-09-08): *"context 정본은, 정확히는 배경 맥락에서 내려가는걸 안 한다였지, 이건
슈거이고 직접적으로 내려먹이는거라 약간 다름. 이전 context를 안 한다 했던 이유는 한계가 명확한, 그냥 알아서 내려가는 맥락이
안 된다였지, 이거는 정확히 보면 직접 내려주는것이고, 순수 슈거인 편의도구라 괜찮은 부분이야."* 즉 이 문서의 `Context`는
트리를 탐색하지 않는다 — props로 **직접** 넘기는 타입드 가방일 뿐이고, 기각의 근거(비동기 Slot 추가에서 조용히 폴백, 선언되지
않은 채널)는 여기 해당하지 않는다.

**무엇을 푸나** — 중간 계층 문제. 사용자: *"우리가 store 등을 모아서 던질 표면을 안 줬다는거. 명시적으로 다 내려야하는데,
중간에 잘 모르는 계층이 있다고 치면 그걸 내리기가 어려워. 따라서 context 는 어떤 store 든 provider 를 키로써 담아주고 모르는
계층은 그냥 무시하고, 내려 보내기가 가능해지는 구조임."* 셸 컴포넌트가 앱의 Store 스키마를 몰라도 `Context` 하나를 그대로
내려보내면 깊은 자식이 자기 키만 꺼낸다. 내려보내는 것 자체는 여전히 명시적(문서화 대상).

## 표면 (확정)

```lua
local InventoryProvider = quad.Context.Provider("Inventory") :: QuadTypes.Provider<Store<Inv>>  -- 신원 키, 이름은 선택(메시지용)
local ctx = quad.Context():Set(InventoryProvider, inventoryStore):Set(SettingsProvider, settings)
Shell { Context = ctx }                       -- 셸은 스키마를 모른 채 그대로 내린다
local inv = props.Context:Get(InventoryProvider)   -- Store<Inv>로 추론(Provider<T>의 팬텀 T)
if props.Context:Peek(ThemeProvider) then ... end  -- 있는지 확인
```

- **`Provider<T>`는 테이블 신원** — 모듈 간 문자열 키 충돌이 없다. `T`는 팬텀 필드(`__quadProviderValue`)로만 실린다(`H-300`
  관례대로 마커 `__quadProvider`는 런타임에도 있음). `Provider(name?)`의 이름은 `tostring`/에러 메시지용.
- **`Get`은 없으면 에러, `Peek`은 nil.** 사용자 결정: *"루아우는 `?.` 같은 널 케이싱 처리가 없어서, 애초에 프로바이더가 필요한데
  제공 안 하는거면 에러를 내는게 일반적이라, Get은 nil을 떼고 던지고, 대신 있는지 확인을 위한 peek() 나 has 같은걸 제공하는게
  맞아보임."* — `Peek` 하나로 has 역할까지(`Peek(p) ~= nil`).
- **`Set`은 값 nil 거부**(부재는 "안 넣음"으로만 표현), 자기 가방을 변경하고 self를 돌려준다(체이닝). Provider가 아닌 키는 셋 다
  에러. 브랜드 `isContext`/`isProvider`.
- **패키지**: quad-base, 의존 없는 잎, 코어 변경 0(순수 슈거).

## Slot 권위 불변식 (스캐폴딩 문서의 관찰 — 코드 변경 없음)

Slot을 만들어 자식에게 넘기는 쪽이 그 요소들의 생산자다. 자식이 받은 Slot에 자기 `Context`를 다시 묶는 표면은 없고 만들지도
않는다 — 생산자가 환경을 정하고 소비자는 마운트만 한다(`slot-plan.md`의 소유권 모델 그대로).

## 불변 확장은 만들지 않는다 (2026-09-08 사용자 결정)

`Set`은 변경이고, Tag/Modifier식 복제 반환(`:With`류)은 **두지 않는다**. 사용자 원문: *"context 의 불변 확장은 필요 없는듯. 오히려
여기는 뭔가 나뉘고 갈리면 디버깅 어려워지는 부분이고 … context 는 진실 원천이 하나. 모듈 최상위에 만들 수도 있고, 앱 진입점에 만들
수도 있고, 위치는 어디든 같으나, 디버깅 할 때 context 를 찍으면 전부 확인 가능. 분기가 없는게 맞아보여. modifier나 tag와 다르게
'유저가 지정하는 모든 데이터' 를 넣을 수 있거든."* 자식이 채워 주길 기대하는 것도, 형제들 처리가 묶이는 것도 이 모델의 의도가
아니다 — 가방은 하나, 어디서 만들든 같은 것 하나를 내린다. 그래서 **열거 표면(`Providers()`류)도 없다** — 셸이 가방을 "옮겨 담을"
필요 자체가 없다(round9 둘째 리뷰가 짚은 대로, 열거 없이는 옮겨 담기가 불가능한데 그건 이 모델의 의도와 맞다).

## 소유권·사본 (round9 둘째 리뷰 반영)

값 맵은 **강참조** — `Context`의 수명이 그 안의 Store들 수명의 하한이고 약한 보관은 없다(명시적 전달 모델에서 자연스러운 것).
`Provider` 신원은 quad-base **사본**마다 갈린다(`Brand.luau`와 같은 이유) — 다른 사본에서 만든 Provider는 `isProvider`가 거짓이라
`Context:Set: key must be a Provider …`로 죽는다. 한 앱에 quad-base 사본이 둘이면 그게 원인.
