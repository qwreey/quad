# UI 편의 숏핸드 (Corner/Padding/Scale 등) — 인라인 적용 계획

**상태**: research — 2026-08-06 세션에서 결론까지 남. `Corner`/
`PaddingAll`/`Scale` 숏핸드 자체는 **여전히 필요**(사용자 재확정, 아래
"결론" 절 — 이전에 이 문서가 한 차례 "포팅 불필요"로 잘못 정리했던 걸
정정함). 패키지 배치는 `quad-roblox` 코어 직접 포함으로 확정.

## 배경

사용자 기억: v1을 쓸 때 "UICorner/UIPadding/UIScale 같은 걸 직접
`Instance.new`로 만들어 Parent하는 귀찮은 작업 없이, Frame 안에 인라인으로
넣기만 해도 CSS 스타일처럼 적용됐다 — 코드가 줄고 읽기도 편해서 꽤
괜찮았다"는 것. 문서 어디에도 기록된 적 없어 v1 소스(`.claude/initreq/quad`)와
PA님 코드(`.claude/initreq/artworks`)를 서브에이전트로 조사.

## v1 실제 메커니즘 (조사 완료)

`class.lua`의 `SetProperty`/`GetProperty`(38~109행)와 `ProcessQuadProperty`
(134~213행)에 하드코딩된 if/elseif 분기로 특수 문자열 키 5종을 지원:

- `RoundSize = 16` → `ImageLabel`/`ImageButton` 전용, UICorner가 아니라
  이미지 자체의 9-slice 라운드 처리(`round.SetRound()`) — **UICorner 계열과
  메커니즘이 다름**.
- `Corner = 8` → 숫자 하나. 기존 `UICorner` 자식이 있으면 재사용, 없으면
  `Instance.new("UICorner", item)`으로 생성(`Name = "_quad_round"`),
  `CornerRadius = UDim.new(0, value)` 설정.
- `PaddingAll = UDim.new(...)` / `PaddingAllOffset = 50` → 동일 패턴,
  `UIPadding`(`_quad_padding`).
- `Scale = 1.2` → 동일 패턴, `UIScale`(`_quad_scale`).

값 모양은 항상 **리터럴 하나**(숫자/UDim) — 테이블도 `__type` 태그도 아님.
실사용 예시(`md/kr/tutorial/7_quadProperty.md`):
```lua
Frame "mainFrame" {
    PaddingAllOffset = 50;
    ImageFrame { RoundSize = 16; ... };
}
```

**`UIListLayout`/`UIGridLayout`/flex는 이런 전용 숏핸드가 v1에 없었음** —
`ProcessQuadProperty`의 범용 자식 나열 분기(배열 인덱스로 놓인 Instance/
Class 결과를 자동 mount, 207~213행)로 `UIListLayout{...}`을 그냥 직접
나열했을 뿐, `List = true` 같은 전용 축약 문법은 레포 전체(PA님 코드
포함)에서 찾지 못함. **quad-v2도 이 부분은 이미 있는 children-array +
인스턴스 생성 문법으로 그대로 커버됨 — 새로 설계할 것 없음.** 사용자
기억 중 이 부분은 "전용 숏핸드"가 아니라 "선언형 문법 자체가 원래
간결하다"는 것과 섞였을 가능성이 큼.

## 결론 (2026-08-06, 한 차례 오해 후 재정정)

**RoundSize와 Corner는 서로 다른 이유로 존재했던 별개 기능 — 혼동하지
말 것**:
- **`RoundSize`(이미지 9-slice 라운드)**: `ImageLabel`/`Button`을
  이미지 트릭으로 둥글게 보이게 하던 것 — **당시 Roblox에 `UICorner` 같은
  네이티브 구현체가 없었기 때문에** 존재하던 워크어라운드. 지금은
  `UICorner`가 안정적인 네이티브 Instance라 이 이미지 트릭 자체를 그대로
  포팅할 이유는 없음(이미지에도 그냥 실제 `UICorner`를 쓰면 됨) —
  **RoundSize는 포팅 안 함**.
- **`Corner`/`PaddingAll`/`Scale`(UICorner/UIPadding/UIScale 자동
  생성)**: 이건 워크어라운드가 아니라 **지금도 유효한 편의 기능** —
  **사용자 재확정**: "UIScale 같은 건 여전히 별도의 Instance고 부모
  Frame에 영향을 주는 구조, 숏핸드는 여전히 필요하다". `UICorner`가
  네이티브가 됐다고 해서 "별도 Instance를 만들어 부모에 Parent해야
  한다"는 구조적 번거로움 자체가 없어지는 게 아니므로, 이 숏핸드의
  존재 이유는 여전히 유효함 — **이전 정리("포팅 불필요")는 오해였고
  정정함, `Corner`/`PaddingAll`/`Scale`은 그대로 포팅 대상.**

**메커니즘 — 새 아키텍처 개념 불필요**: 이미 있는 pluggable Handler로
그대로 커버됨. `Corner`/`PaddingAll`/`Scale` 같은 특수 키를 인식하는
Handler(`isHandlable`이 그 키를 매칭)가 "이름 붙은 자식을 찾거나 만들고
프로퍼티 세팅"을 `process(inst, k, v)`에 구현 — v1의 하드코딩 if/elseif
대신 정식 핸들러 계약(`isHandlable`/`priority`/`process`/`retract`)을
따르는 것만 다름. `modifier-plan.md`가 이미 예시로 든
`Modifier.Rounded(8)`은 이 특수 키를 flatten해서 props에 꽂아넣는 사탕
문법일 뿐, 실제 처리는 이 Handler가 함 — Modifier를 안 거치고
`Frame { Corner = 8 }`처럼 순수 인라인 키로 직접 써도(v1처럼) 동일하게
작동함, `architecture.md`의 `[Attribute "Name"]`류 특수 키와 같은 층위.
자동 생성된 자식은 위 "핵심 설계 방향" 관례대로 `_`/`QUAD_` 접두어
네이밍(`research/debug-tooling-plan.md` 9번, v1의 `_quad_round`류
그대로 재사용).

**패키지 배치 — `quad-roblox` 코어에 직접 포함, 확정**: "트윈도 인스턴스
생성/제어를 직접 구현 가능한 걸 하나로 묶어 쉽게 쓰게 합친 것 — 너무
잘게 쪼개 오버엔지니어링하기보다 확실히 하나로 코어에 넣어도 충분하다,
opt-out할 이유가 별로 없다"는 게 사용자 판단 — **작고 항상 켜져 있어도
비용이 무시할 만한 편의 기능은 별도 opt-out 패키지로 쪼개지 말고
`quad-roblox` 코어에 직접 포함한다**는 원칙으로 확정(이미 계획된 Tween
핸들러가 같은 모양이라는 게 근거). 이 원칙은 일반화해서 재사용 가능 —
앞으로 비슷한 "작은 인스턴스 편의 기능"이 제안되면 `quad-roblox-util`
같은 걸 새로 만들지 않고 이 선례를 따르면 됨.

**중요도**: 낮음("이건 나중에도 쉽게 구현됨" — 사용자) — 지금 M0 우선순위를
바꿀 이유는 없음, M10(Handlers/Attribute 등) 전후로 다른 세부 Handler와
함께 구현하면 충분.

## 열린 질문 (`.claude/question.md`에도 취합)

- 이름 그대로 가져올지(`Corner`/`PaddingAll`/`PaddingAllOffset`/`Scale`)
  재검토할지 — 진행 중인 용어 정리(`CLAUDE.md` "지금 할 일" 2번)에 합류
  대상.
- `RoundSize`(이미지 라운드)를 완전히 드롭할지, 아니면 이미지 대상에도
  그냥 실제 `UICorner`를 자동 적용하는 것으로 대체할지 — 후순위.
