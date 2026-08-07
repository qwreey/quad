# UI 편의 숏핸드 (UICorner/UIPadding/UIScale) — 인라인 적용

**상태**: base — 기능 필요 여부·이름·메커니즘·패키지 배치·store-bind 가능성까지
전부 확정(2026-08-07 문서 정리에서 `research/`→`base/` 승격). 남은 건 구현
단계의 세부 시그니처뿐.

## 배경

사용자 기억: v1을 쓸 때 "UICorner/UIPadding/UIScale 같은 걸 직접
`Instance.new`로 만들어 Parent하는 귀찮은 작업 없이, Frame 안에 인라인으로
넣기만 해도 CSS 스타일처럼 적용됐다 — 코드가 줄고 읽기도 편해서 꽤
괜찮았다"는 것. v1 소스(`.claude/initreq/quad`)와 PA님 코드
(`.claude/initreq/artworks`)를 서브에이전트로 조사해 확인.

## v1 실제 메커니즘 (조사 완료)

`class.lua`의 `SetProperty`/`GetProperty`(38~109행)와 `ProcessQuadProperty`
(134~213행)에 하드코딩된 if/elseif 분기로 특수 문자열 키 5종을 지원했음 —
`Corner = 8` → 숫자 하나, 기존 `UICorner` 자식이 있으면 재사용, 없으면
`Instance.new("UICorner", item)`으로 생성(`Name = "_quad_round"`),
`CornerRadius = UDim.new(0, value)` 설정. `PaddingAll`/`PaddingAllOffset`,
`Scale`도 동일 패턴(`UIPadding`/`UIScale`, `_quad_padding`/`_quad_scale`).
값 모양은 항상 **리터럴 하나**(숫자/UDim) — 테이블도 `__type` 태그도 아님.
v1엔 이 5종과 별개로 `RoundSize`(이미지 9-slice 라운드 트릭, UICorner와는
전혀 다른 메커니즘)도 있었으나 **이건 드롭 확정** — 자세한 사유는
`archive/ui-shorthand-roundsize-dropped.md` 참고, 이 문서에서는 반복하지
않음.

**`UIListLayout`/`UIGridLayout`/flex 전용 숏핸드는 v1에 없었음** —
`ProcessQuadProperty`의 범용 자식 나열 분기(배열 인덱스로 놓인 Instance/
Class 결과를 자동 mount)로 `UIListLayout{...}`을 그냥 직접 나열했을 뿐,
`List = true` 같은 전용 축약 문법은 레포 전체(PA님 코드 포함)에서 찾지
못했음. quad-v2도 이 부분은 이미 있는 children-array + 인스턴스 생성
문법으로 그대로 커버됨 — 새로 설계할 것 없음.

## 결론 — 이름은 UICorner/UIPadding/UIScale로 확정 (프리픽스 필요)

**기능은 여전히 필요**: `UICorner`가 Roblox 네이티브 Instance가 됐어도
"별도 Instance를 만들어 부모에 Parent해야 한다"는 구조적 번거로움 자체는
없어지지 않으므로, 이 숏핸드의 존재 이유는 그대로 유효 — **사용자
재확정**("UIScale 같은 건 여전히 별도의 Instance고 부모 Frame에 영향을
주는 구조, 숏핸드는 여전히 필요하다").

**이름은 v1의 `Corner`/`PaddingAll`/`Scale`을 그대로 안 가져오고 실제
Roblox Instance 이름과 맞춘 `UICorner`/`UIPadding`(+`UIPaddingOffset`)/
`UIScale`로 확정** — v1식 짧은 이름을 그대로 쓰면 Modifier 체이닝
메소드(`mod:Corner(8)`)가 "진짜 UICorner를 만드는 숏핸드"인지 그냥 우연히
비슷한 이름의 부가 Modifier 필드인지 구분이 안 됨(사용자 지적). 접두어
`UI`를 붙이면 실제 대응하는 Roblox Instance 클래스 이름과 1:1로 읽혀서
이 모호함 자체가 사라짐 — `Frame { UICorner = 8 }`, `mod:UICorner(8)`.

## 메커니즘 — 새 아키텍처 개념 불필요

이미 있는 pluggable Handler로 그대로 커버됨. `UICorner`/`UIPadding`/
`UIScale` 같은 특수 키를 인식하는 Handler(`isHandlable`이 그 키를 매칭)가
"이름 붙은 자식을 찾거나 만들고 프로퍼티 세팅"을 `process(inst, k, v)`에
구현 — v1의 하드코딩 if/elseif 대신 정식 핸들러 계약(`isHandlable`/
`priority`/`process`/`retract`)을 따르는 것만 다름. `modifier-plan.md`가
이미 예시로 든 `Modifier.Rounded(8)`은 이 특수 키를 flatten해서 props에
꽂아넣는 사탕 문법일 뿐, 실제 처리는 이 Handler가 함 — Modifier를 안 거치고
`Frame { UICorner = 8 }`처럼 순수 인라인 키로 직접 써도(v1처럼) 동일하게
작동함, `architecture.md`의 `[Attribute "Name"]`류 특수 키와 같은 층위.
자동 생성된 자식은 기존 관례대로 `_`/`QUAD_` 접두어 네이밍
(`research/debug-tooling-plan.md` 9번, v1의 `_quad_round`류 그대로 재사용).

**기존 자식과의 매칭 기준(2026-08-06 감사에서 지적된 항목, 여기서 같이
확정)**: 재사용 대상은 quad가 이전에 만든 고정 이름(`_quad_corner`류)
자식으로 한정 — 타입만 보고(`UICorner`이기만 하면 아무거나) 재사용하지
않음. 사용자가 직접 만든 `UICorner`를 quad가 멋대로 건드리는 부작용을
피하기 위함.

## store-bind — 이 숏핸드도 지원, Tween만큼 무겁게 안 가도 됨

v1에서도 `Corner`/`PaddingAll`/`Scale`은 store 값으로 바인드 가능했음
(`myStore "key"` 체이닝으로 다른 프로퍼티와 동일하게 취급됨) — quad-v2도
이 능력을 유지한다. 트윈처럼 애니메이션까지 지원할 필요는 없음(API 표면만
복잡해짐) — 그냥 값이 바뀌면 `CornerRadius`/`Padding`/`Scale` 프로퍼티를
다시 세팅하는 정도로 충분. 구현 비용도 낮음: 각 Handler가 `process`에서
"이전에 자기가 찾거나 만든 자식 Instance"를 얻어야 하는데, 이건 이미
base가 범용 유틸로 제공하기로 확정한 per-instance weak-keyed 저장소
(`base.perInstanceState(inst)`, `base/bind-system-plan.md` "핸들러 내부
상태 저장" 절)를 그대로 재사용하면 됨 — Tween 핸들러가 실행 중인 Tween
객체를 기억해두는 것과 정확히 같은 패턴. 새 메커니즘 발명 불필요, 이미
있는 "store 바인드는 pluggable 바인드를 재실행하는 래핑" 원칙
(`base/bind-system-plan.md` "확정된 디스패치 모델" 절)이 그대로 적용됨.

## 패키지 배치 — `quad-roblox` 코어에 직접 포함, 확정

"트윈도 인스턴스 생성/제어를 직접 구현 가능한 걸 하나로 묶어 쉽게 쓰게
합친 것 — 너무 잘게 쪼개 오버엔지니어링하기보다 확실히 하나로 코어에
넣어도 충분하다, opt-out할 이유가 별로 없다"는 게 사용자 판단 — **작고
항상 켜져 있어도 비용이 무시할 만한 편의 기능은 별도 opt-out 패키지로
쪼개지 말고 `quad-roblox` 코어에 직접 포함한다**는 원칙으로 확정(이미
계획된 Tween 핸들러가 같은 모양이라는 게 근거). 이 원칙은 일반화해서
재사용 가능 — 앞으로 비슷한 "작은 인스턴스 편의 기능"이 제안되면
`quad-roblox-util` 같은 걸 새로 만들지 않고 이 선례를 따르면 됨.

**중요도**: 낮음("이건 나중에도 쉽게 구현됨" — 사용자) — 지금 M0 우선순위를
바꿀 이유는 없음, M10(Handlers/Attribute 등) 전후로 다른 세부 Handler와
함께 구현하면 충분.

## 남은 열린 질문 (단순화 후보, 사소함)

- Corner/PaddingAll/Scale 3개 거의 동일한 형태의 Handler를 각각 만들지,
  `{key -> {ChildClassName, ChildDefaultName, Property, wrap=fn}}` 룩업
  테이블로 구동되는 단일 `Handlers/InstanceShorthand.luau`로 통합할지 —
  `research/pre-implementation-audit.md` 3-2번 참고, 강제 사항 아님,
  구현 시점에 결정할 정도의 사소한 개선 후보.
