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
"이름 붙은 자식을 찾거나 만들고 그 자식의 프로퍼티를 세팅"을
`process(inst, k, v, index)`에 구현(**[2026-08-14 세션]** 그 마지막
"세팅"은 직접 대입이 아니라 `Dispatch.process(child, prop, ..., 1)`로
되돌려주는 위임으로 확정 — 아래 "Tween 지원" 절)
— v1의 하드코딩 if/elseif 대신 정식 핸들러 계약(`isHandlable`/
`priority`/`process`, 2026-08-13 다섯 번째 세션 전까진 `retract`가 별도
필드였음)을 따르는 것만 다름. `modifier-plan.md`가
이미 예시로 든 `mod:UICorner(8)`은 이 특수 키를 flatten해서 props에
꽂아넣는 사탕 문법일 뿐, 실제 처리는 이 Handler가 함 — Modifier를 안 거치고
`Frame { UICorner = 8 }`처럼 순수 인라인 키로 직접 써도(v1처럼) 동일하게
작동함, `architecture.md`의 `[AttributeKey "Name"]`류 특수 키와 같은 층위.
자동 생성된 자식은 기존 관례대로 `_`/`QUAD_` 접두어 네이밍
(`research/debug-tooling-plan.md` 9번, v1의 `_quad_round`류 그대로 재사용).

**[보강, 2026-08-09 열한 번째 세션] `mod:UICorner(8)`류 체이닝이 실제로
타입체크되려면, 생성되는 `FrameModifier`류 정적 타입의 메소드 목록에
`UICorner`/`UIPadding`/`UIScale`이 (진짜 프로퍼티들과 나란히) 포함돼
있어야 함 — 순수 런타임 관점(제네릭 `__index`가 처리)에선 문제없지만,
타입 레벨에선 별도로 챙겨야 하는 항목.** quad-roblox의 각종 타입(DI
인스턴스 타입, Modifier 타입 등)이 Roblox API 덤프를 읽어 Luau 타입
파일을 구워내는 스크립트로 생성될 예정이라(구현 단계 결정 사항) — 이
스크립트가 실제 Roblox 프로퍼티뿐 아니라 이 3개 숏핸드 키도 각
Modifier 타입의 메소드 목록에 끼워 넣도록 챙기면 됨, 새로 설계할
게 없는 구현 체크리스트 항목.

**기존 자식과의 매칭 기준(2026-08-06 감사에서 지적된 항목, 여기서 같이
확정)**: 재사용 대상은 quad가 이전에 만든 고정 이름(`_quad_corner`류)
자식으로 한정 — 타입만 보고(`UICorner`이기만 하면 아무거나) 재사용하지
않음. 사용자가 직접 만든 `UICorner`를 quad가 멋대로 건드리는 부작용을
피하기 위함.

### `v`가 `nil`인 경우 — `process`가 직접 자식 제거, 반환 클로저는 관여 안 함 (2026-08-07 여덟 번째 세션)

`modifier-plan.md`의 `None` 센티널(`base/dispatch-core-plan.md`의
`NoneHandler` 재귀 재디스패치 절 참고)이 최종적으로 이 Handler의
`process(inst, k, nil)`을 호출하는 구체 사례 — 이 Handler에서 "`v`가
`nil`"은 만들어둔 `_quad_corner`류 자식이 있으면 그냥 지우는 것으로 확정.
일반 프로퍼티 핸들러와 달리 이 숏핸드는 실제 Instance를 만들어 붙이는
쪽이라 "`nil` = 셋 안 함"이 곧 "만들어둔 게 있으면 치운다"는 뜻이 됨.

- **이건 반환 클로저가 아니라 `process` 자신의 로직** — **[정정, 2026-08-12
  열한 번째 세션, 2026-08-13 다섯 번째 세션에 클로저 반환 계약으로 서술
  갱신]** 그 클로저는 store 재발행마다 항상 불리지만(핸들러 타입이 안
  바뀌어도, `dispatch-core-plan.md` 일반 retract 계약 절 정정분 참고), 이
  Handler는 `process(inst,k,v,index)` 자체가 `v`가 `nil`이든 숫자든
  전부 완결적으로 처리하므로(있으면 지우거나 만들거나) 반환 클로저가 할 일이
  없어 `function() end`이면 충분 — 일반 프로퍼티 핸들러가 no-op 클로저를
  반환하는 것과 같은 이유. 값이 나중에 다시 숫자로(`2`→`nil`→`3`처럼)
  바뀌면 `process`가 다시 자식을 만들면 그만이라 클로저 쪽에 별도로
  구현할 게 없음.
- **캐비엇**: 이 왔다갔다가 잦으면(예: 반응형 State가 `nil`과 숫자 사이를
  자주 토글) 매번 Instance 생성/제거 비용이 그대로 듦 — Tween처럼 무거운
  API는 아니지만 공짜도 아니므로, 잦은 토글이 예상되는 값을 이 숏핸드에
  직접 물리는 건 문서화 시점에 캐비엇으로 명시할 것(지금은 메모만).

## Tween 지원 — 자식 프로퍼티를 `Dispatch.process`로 다시 흘려보내면 공짜 (2026-08-14 세션 확정)

**[역전] "트윈처럼 애니메이션까지 지원할 필요는 없음"이라던 아래 store-bind
절의 서술은 폐기.** 그 판단은 Tween이 아직 *독립 Dispatch 핸들러*였던
시절(우선순위를 다투는 특수 bind key, `archive/tween-special-bind-key-reversed.md`)
기준이라 "이 숏핸드도 그 경쟁에 끼워 넣어야 하나"가 비용이었는데,
2026-08-10 재설계로 Tween이 **값-레벨 래퍼 `Tween<T>` + PropertyHandler
내부 분기**가 되면서(`base/tween-plan.md`) 그 비용이 통째로 사라짐 —
이제는 숏핸드가 **자식 프로퍼티 세팅을 자기 손으로 하지 않고 Dispatch에
되돌려주기만 하면** Tween이 저절로 따라옴.

**메커니즘 — 인스턴스 관리 후 `process`로 위임**:

```lua
-- 개념 스케치. Handler 계약은 base/dispatch-core-plan.md가 정본
function UICornerHandler.process(inst, k, v, index)
    if v == nil then
        -- 기존 규칙 그대로: 만들어둔 자식이 있으면 지움(아래 "v가 nil인 경우" 절)
        destroyManagedChild(inst, k)
        return function() end
    end
    local child = ensureManagedChild(inst, k)   -- 없으면 Instance.new + Parent, 있으면 재사용
    Dispatch.process(child, "CornerRadius", mapTweenValue(v, toUDim), 1)
    return function(hint)
        if hint == nil then destroyManagedChild(inst, k) end
    end
end
```

- **`process` 도중에 대상 `inst`를 바꾸는 것은 UB가 아님(사용자 확정)** —
  키가 바뀔 수 있는 것과 정확히 같음. `chains`가 `(inst,k)` 쌍으로
  인덱싱되므로 `(inst, "UICorner")` → `(child, "CornerRadius")` 위임은
  Dispatch 입장에서 `Attribute` 그룹이 다른 키로 위임하는 것과 구조적으로
  동일한 일이고, 새 체인이라 인덱스는 `1`부터. 일반 규칙은
  `base/dispatch-core-plan.md`의 "인덱스의 의미" 절에 같이 명문화해뒀음.
- **Tween 해석 코드를 여기 복제하지 않는 게 핵심 이득** — `Tween<T>`를
  실제로 읽는 코드는 여전히 `PropertyHandler` 하나뿐이라는
  `base/tween-plan.md`의 불변식이 유지됨. 3-상태 릴레이션 슬롯
  (`{Tween, Value} | true | nil`), `Tween.Cancel`/`Tween.Finish` override
  정책, "첫 세팅은 애니메이션 없이 즉시" 규칙까지 전부 `(child, prop)`
  자리에서 그대로 재사용됨 — 이 문서가 따로 정할 게 없음.
- **타입 대수도 그대로** — 숏핸드 키의 값 타입이 `number`였다면 이제
  `number | Tween<number> | State<number | Tween<number>>`가 됨
  (`T' = T | Tween<T>` 치환, `tween-plan.md` "타입 대수" 절). StoreBind가
  State 레이어를 먼저 다 풀어내므로 이 Handler가 실제로 보는 `v`는
  `number` 아니면 `Tween<number>` 둘 중 하나.

**한 가지 진짜로 필요한 부품 — `wrap`을 Tween 위로 들어올리기.** 숏핸드는
"스칼라를 받아 자식 프로퍼티 타입으로 감싸는" 변환을 갖고 있음(`UICorner = 8`
→ `CornerRadius = UDim.new(0, 8)`, 열린 질문 절의 룩업 테이블 `wrap=fn`).
`v`가 `Tween<number>`면 그 변환을 **`Tween`을 벗기지 않고 `.Value`에만**
적용해야 함:

```lua
-- Tween<T>는 immutable 값 객체라 clone 후 Value만 교체(Brand 재설정은 Tween()이 함)
local function mapTweenValue(v, wrap)
    if isTween(v) then
        local opts = table.clone(v)
        opts.Value = wrap(v.Value)
        return Tween(opts)
    end
    return wrap(v)
end
```

- `UIScale`처럼 `wrap`이 항등(스칼라를 그대로 `Scale`에 씀)인 키는 이
  헬퍼를 거쳐도 결과가 같으므로 분기 없이 일관되게 씀.
- `UIPadding`처럼 **자식의 프로퍼티 여러 개**(`PaddingTop`/`Bottom`/
  `Left`/`Right`)에 같은 값을 쓰는 키는 각 프로퍼티마다 `Dispatch.process`를
  따로 부름 — 각자 독립된 `(child, prop)` 체인이 되고, PropertyHandler의
  트윈 슬롯도 프로퍼티별로 따로 잡혀서 자연스럽게 4개가 같이 애니메이션됨.
- **`Tween` 값 자체는 `quad-base`, 이 숏핸드 Handler는 `quad-roblox`** —
  `isTween`/`Tween()`을 base에서 가져다 쓰는 것뿐이라 패키지 경계
  (`tween-plan.md` "패키지 경계" 절)와 안 부딪힘.

**캐비엇 — 자식이 새로 만들어진 사이클에서는 트윈이 안 걸린다(의도된 동작).**
PropertyHandler의 "첫 세팅은 애니메이션 없이 즉시"(`prev == nil`) 규칙이
`(child, prop)` 기준이므로, `UICorner`가 `nil`↔숫자를 오가며 자식이 파괴/
재생성되면 그 직후 첫 값은 트윈 없이 스냅됨. 이건 버그가 아니라 그 규칙이
막으려는 것(기본값에서 목표값으로 날아오는 진입 애니메이션)과 정확히 같은
상황 — 계속 애니메이션되길 원하면 자식이 살아있도록 `nil`로 내리지 말고
값만 바꿀 것.

**자식을 없앨 때의 정리 책임은 이 Handler에 있음** — `v`가 `nil`이 되거나
retractor가 `nil` 힌트로 불려 자식을 파괴할 때, 실행 중인 엔진 Tween이
남아있을 수 있으므로 `Dispatch.retractFrom(child, prop, 1)`을 같이
부르는 게 정석(자식 Instance를 `Destroy`하면 엔진 트윈도 같이 죽고
`chains`도 weak-keyed라 결국 GC되지만, "즉시" 끊는 건 명시적 호출뿐).
`retractor` 안에서 **다른 키**에 대한 `retractFrom`을 부르는 건 허용된
경로임(`base/dispatch-core-plan.md`의 retract 계약 — 금지된 건 같은
`(inst,k)`에 대한 재진입).

## store-bind — 이 숏핸드도 지원

v1에서도 `Corner`/`PaddingAll`/`Scale`은 store 값으로 바인드 가능했음
(`myStore "key"` 체이닝으로 다른 프로퍼티와 동일하게 취급됨) — quad-v2도
이 능력을 유지한다. **[정정, 2026-08-14 세션]** 이 절의 원 서술은 "트윈처럼
애니메이션까지 지원할 필요는 없음(API 표면만 복잡해짐) — 그냥 값이 바뀌면
프로퍼티를 다시 세팅하는 정도로 충분"이었으나, 위 "Tween 지원" 절에서
뒤집혔음(자식 프로퍼티를 `Dispatch.process`로 되돌려주면 Tween이 공짜로
따라오므로 "안 하는 게 더 비싸지는" 상황이 됨). 구현 비용은 여전히 낮음:
각 Handler가 `process`에서
"이전에 자기가 찾거나 만든 자식 Instance"를 얻어야 하는데, 이건 이미
base가 범용 유틸로 제공하기로 확정한 per-instance weak-keyed 저장소
(`Relate:SetStrong(inst,k,...)`, `base/relate-plan.md`/`base/dispatch-core-plan.md`
"핸들러 내부 상태 저장" 절)를 그대로 재사용하면 됨 — PropertyHandler가 실행 중인
Tween 상태를 기억해두는 것과 정확히 같은 패턴. 새 메커니즘 발명 불필요, 이미
있는 "store 바인드는 pluggable 바인드를 재실행하는 래핑" 원칙
(`base/dispatch-core-plan.md` "확정된 디스패치 모델" 절)이 그대로 적용됨.

## 패키지 배치 — `quad-roblox` 코어에 직접 포함, 확정

"트윈도 인스턴스 생성/제어를 직접 구현 가능한 걸 하나로 묶어 쉽게 쓰게
합친 것 — 너무 잘게 쪼개 오버엔지니어링하기보다 확실히 하나로 코어에
넣어도 충분하다, opt-out할 이유가 별로 없다"는 게 사용자 판단 — **작고
항상 켜져 있어도 비용이 무시할 만한 편의 기능은 별도 opt-out 패키지로
쪼개지 말고 `quad-roblox` 코어에 직접 포함한다**는 원칙으로 확정(이미
계획된 Tween 처리 로직이 같은 모양이라는 게 근거). 이 원칙은 일반화해서
재사용 가능 — 앞으로 비슷한 "작은 인스턴스 편의 기능"이 제안되면
`quad-roblox-util` 같은 걸 새로 만들지 않고 이 선례를 따르면 됨.

**중요도**: 낮음("이건 나중에도 쉽게 구현됨" — 사용자) — 지금 M0 우선순위를
바꿀 이유는 없음, M10(Handlers/Attribute 등) 전후로 다른 세부 Handler와
함께 구현하면 충분.

## 남은 열린 질문 (단순화 후보, 사소함)

- UICorner/UIPadding/UIScale 3개 거의 동일한 형태의 Handler를 각각 만들지,
  `{key -> {ChildClassName, ChildDefaultName, Properties, wrap=fn}}` 룩업
  테이블로 구동되는 단일 `Handlers/InstanceShorthand.luau`로 통합할지
  (`Properties`가 단수가 아니라 목록인 이유는 `UIPadding`이 자식 프로퍼티
  4개에 같은 값을 쓰기 때문 — 위 "Tween 지원" 절) —
  `research/pre-implementation-audit.md` 3-2번 참고, 강제 사항 아님,
  구현 시점에 결정할 정도의 사소한 개선 후보.
