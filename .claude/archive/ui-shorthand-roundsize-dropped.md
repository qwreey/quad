# [기각됨] `RoundSize`(이미지 9-slice 라운드 트릭) 포팅 — 네이티브 `UICorner`로 대체되어 불필요

**기각 일시**: 2026-08-06. **현재 유효한 설계**: `base/ui-shorthand-plan.md` —
이 문서는 v1의 `RoundSize`가 왜 포팅 대상에서 빠졌는지, 그리고 그 판단이
한 차례 잘못 일반화됐다가 정정된 이력을 보존해둔 것. 능동적으로 참고할
필요 없음(구현에 안 씀) — `RoundSize`류 "네이티브 Instance가 나중에 생겨
워크어라운드가 필요 없어진 사례"는 `quadnomicon` 소재로 가치 있음.

## 무엇이었나

v1 `class.lua`가 지원하던 특수 키 `RoundSize = 16`(`ImageLabel`/
`ImageButton` 전용) — `UICorner`가 아니라 이미지 자체를 9-slice로 잘라
둥글게 보이게 만드는 트릭(`round.SetRound()`). `UICorner`/`UIPadding`/
`UIScale` 자동 생성 숏핸드(`Corner`/`PaddingAll`/`Scale`, 현재
`base/ui-shorthand-plan.md`가 이어받은 기능)와 겉보기엔 "인라인 리터럴 값
하나로 GUI를 꾸민다"는 카테고리가 비슷해 보이지만, **메커니즘 자체가
완전히 다름**(하나는 별도 Instance 생성, 하나는 이미지 처리) — 이 문서가
쓰인 이유가 바로 이 둘을 혼동하지 않기 위함.

## 기각 이유

`RoundSize`는 **당시 Roblox에 `UICorner` 같은 네이티브 구현체가 없었기
때문에** 존재하던 워크어라운드였음. 지금은 `UICorner`가 안정적인 네이티브
Instance라 이미지 대상에도 그냥 실제 `UICorner`를 붙이면 되므로, 이미지를
9-slice로 잘라 둥글게 "보이게" 만드는 트릭 자체를 그대로 포팅할 이유가
없음 — **포팅 안 함으로 확정**.

## 왜 archive에 남기나 — 한 차례 과잉일반화됐다가 정정된 이력

`RoundSize` 하나를 드롭하기로 한 판단이, 초안 작성 과정에서 실수로
**"UICorner가 네이티브가 됐으니 Corner/PaddingAll/Scale 숏핸드 자체가
불필요하다"는 훨씬 넓은 결론으로 잘못 일반화된 적이 있었음**("이전 정리
('포팅 불필요')는 오해였고 정정함"). 사용자가 직접 반박해 정정됨:
`UICorner`가 네이티브 Instance가 됐다는 사실은 "이미지를 트릭으로 둥글게
보이게 할 필요가 없어졌다"는 것만 의미할 뿐 — `UIScale`/`UIPadding`류가
**여전히 부모에 Parent해야 하는 별도 Instance**라는 구조적 사실 자체는
전혀 안 바뀌었으므로, `Corner`/`PaddingAll`/`Scale` 숏핸드(현재
`UICorner`/`UIPadding`/`UIScale`)의 존재 이유는 그대로 유효.

**교훈(재사용 가능)**: "네이티브 Instance가 생겼다"는 사실 하나로부터
"관련 숏핸드 전체가 불필요해졌다"를 성급히 일반화하지 말 것 — 워크어라운드가
드롭되는 이유(네이티브 대체재 등장)와 편의 숏핸드가 필요한 이유(별도
Instance를 만들어 Parent해야 하는 구조적 번거로움)는 서로 다른 축이라,
하나가 해소됐다고 다른 하나도 자동으로 해소되는 게 아님.
