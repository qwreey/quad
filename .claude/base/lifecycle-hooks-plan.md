# 생명주기 훅 슈가 — `OnCreated` / `OnRendered` / `OnDestroyed`

> **[2026-08-14 아홉 번째 세션] `research/` → `base/` 승격.** 마지막 열린
> 항목이던 `OnRendered`의 채택 여부/메커니즘을 사용자가 확정 — **채택**,
> 메커니즘은 아래 ② 절의 `PostRef`(착수 선택지 (a)). `PostRef` 자체는
> `base/ref-plan.md`의 "`PostRef`" 절로 편입되어 **base 프리미티브로
> 확정**됐고, 이 문서는 그 위에 얹히는 훅 슈가 셋을 다룸.

**상태**: base — 확정. **[2026-08-14 아홉 번째 세션 기준]** 설계에 열린
질문 없음(이름 재검토 여지 하나만
`question.md` 용어 정리 대기열에 남음, 아래 "이름 컨벤션" 절).
`Ref`/`PreRef`/`PostRef`(`base/ref-plan.md`)와
`Effect`(`base/effect-plan.md`) 프리미티브 위에 얹는 **순수 슈가** —
`base/fallback-plan.md`의 `Fallback`/`Traceback`이
`additional-primitives-plan.md`의 기존 결론 위에 얹혔던 것과 같은 관계,
이 문서도 그 프리미티브들의 확정 사항을 하나도 안 뒤집음.

**구현 우선순위는 여전히 맨 뒤** — 설계가 확정됐다는 것과 지금 만든다는
건 다름. 형제 백로그들(`quad-mock`/`quad-debug`/`Operator`/`Fallback`)과
동급으로 "quad 개발 상당 부분 끝난 뒤". 단 **`PostRef` 자신은 슈가가
아니라 디스패치 코어의 일부**라 `ROADMAP.md` M8(Ref)에서 `PreRef`와 같이
구현됨 — 이 문서의 슈가 셋만 뒤로 미뤄지는 것.

## 동기 (사용자 원 메모)

React/Vue류 프레임워크의 `OnCreated`/`OnRendered`/`OnDisposed` 생명주기
훅을 quad에도 두면 좋겠다는 제안. 처음엔 `Frame{[OnCreated] = fn}`처럼
싱글톤 프리미티브를 해시 파트 특수 키로 쓰는 안을 검토했으나, `:Compute`
콜백에 `State<function>`이 들어올 때의 처리가 까다로워질 것 같다는 우려로
스스로 기각 — 대신 `OnCreated(fn)`이 이미 있는 `PreRef` 인스턴스를 반환하는
**순수 팩토리 함수**(children 배열에 놓는 슈가)라면 그 우려 자체가 안
생긴다는 데 도달했음. 이후 방향이 더 좁혀져 **핵심 우선순위는
`OnCreated`/`OnDestroyed` 둘**로 확정되고(`OnDisposed`라는 최초 가칭
대신 `OnDestroyed`를 사용자가 선호 — 아래 "이름 컨벤션" 절 참고), 두
훅 모두 **여러 번 나란히 등록 가능**하다는 게 이 제안의 특징으로
명시됐음. `OnRendered`는 처음엔 사용자가 **의도적으로 보류**했었으나
(디스패치 코어에 실제 post-pass가 필요해 "공짜"가 아니라서), 그때 같이
남겨둔 `PostRef` 스케치가 **"구현 난이도가 아주 낮고 Pre-Post 둘을 지원
안 할 이유가 없다"**는 판단으로 2026-08-14 아홉 번째 세션에 **채택**됨
— 아래 ② 절이 그 확정 내용(원래 "착수 시점에 판단할 선택지"였던
(a)/(b)/(c) 중 **(a)** 확정).

## 핵심 논지 — 이 셋은 사실 새로운 타입/개념이 아니다

`OnCreated`/`OnRendered`/`OnDestroyed`가 "정말 공짜"인 이유는 단 하나로
귀결됨(`OnRendered`는 자기가 반환하는 `PostRef`라는 프리미티브가 base에
생긴 뒤부터 — 그 프리미티브 자체는 공짜가 아니었고, 그래서 별도로 확정을
받아야 했음):
**이것들은 Dispatch/Brand/타입 시스템이 알아야 하는 새 개념이 아니라,
호출되는 즉시 평가되어 이미 존재하는 프리미티브의 인스턴스로 사라지는
plain 함수일 뿐**이기 때문.

```lua
-- ⭐⭐ [2026-08-26 확정, 8라운드 `H-120`] 훅 슈가는 **nil 가드 래퍼**를 끼운다.
--   `Ref`의 콜백 계약은 "등록 즉시 1회 호출, 값이 nil/미설정이어도 그대로"라
--   (`base/ref-plan.md`), `PreRef()`/`PostRef()`처럼 default 없이 만든 뒤
--   콜백을 걸면 **생성 시점에 `fn(nil)`이 먼저 한 번 불린다.** 그러면
--   `OnCreated(function(inst) inst.Name = "x" end)`은 pre-pass에 도달하기도
--   전에 "attempt to index nil"로 죽는다 — `fn`의 선언 타입이 non-nil
--   `Instance`인데도 그렇다. `Ref` 계약을 바꾸는 대신 여기서 막는다
--   (사용자 확정: `Ref` 쪽은 무수정).
local function guard(fn)
    -- ⭐ [2026-08-26, `/code-review high` 5차] **2-인자를 그대로 흘린다.**
    --   같은 라운드에 `Ref` 콜백이 `fn(value, ref)`가 됐다(`H-107`) — 1-인자로
    --   짜면 두 번째 인자(`Ref` 자신 = `Epoch`)를 조용히 삼킨다. 훅 셋은
    --   지금 그걸 안 쓰지만, 아래 children 배열 관용구가 "위와 같은 가드"를
    --   쓰라고 하므로 `_epochs:Update(ref)` 같은 소비자가 `nil`을 받게 된다.
    return function(v, r) if v ~= nil then fn(v, r) end end
end

-- ⚠️ [2026-08-26, `/code-review high` 6차] `fn`의 선언 타입이 **2-인자**다 —
--   `guard`가 `fn(v, r)`로 부르므로 1-인자로 선언하면 `--!strict`에서 arity
--   에러다. 사용자가 1-인자 람다를 넘기는 건 그대로 된다(Luau 함수 타입은
--   파라미터에 반변이라 인자를 덜 받는 함수가 대입 가능).
local function OnCreated(fn: (inst: Instance, ref: PreRef<Instance>) -> ()): PreRef<Instance>
    return PreRef():Callback(guard(fn))
end

local function OnRendered(fn: (inst: Instance, ref: PostRef<Instance>) -> ()): PostRef<Instance>
    return PostRef():Callback(guard(fn))   -- [2026-08-14 아홉 번째 세션 확정]
end

local function OnDestroyed(fn: () -> ()): EffectHandle
    return Effect(function() return fn end)
end
```

**⚠️ 같은 함정이 children 배열 관용구에도 있다** — `base/ref-plan.md`가
v1 대체안으로 제시하는 `Ref():Callback(function(inst) ... end)`도 default가
`nil`인 흔한 경우 **생성 시점에 `fn(nil, ref)`가 한 번 돈다.** 문서에서 이
관용구를 보일 때는 위와 같은 가드를 함께 보이거나, `Ref(default)`로 채워진
경우임을 명시할 것. **기각된 대안 둘**: (b) `:Callback`의 즉시 1회 호출을
"한 번이라도 `Set`된 뒤"로 좁히는 안(`Ref` 계약 자체를 되짚어야 하고
"미설정 상태를 알고 싶어 콜백을 거는" 용례의 파급 확인이 필요),
(c) *"콜백은 nil을 항상 처리하라"*는 문서 경고만 두는 안(훅 슈가의
인체공학 약속과 어긋난다).

*(위 시그니처의 `Instance`는 읽기 편하라고 quad-roblox 기준으로 적은
것 — 이 셋은 quad-base 소속이므로 실제 선언은 `Ref<T>`가 그렇듯 백엔드
Instance 타입을 모르는 제네릭/불투명 타입 자리로 남음. `bindLifetime(inst,
value)`류 base 유틸을 문서가 `inst`라고만 부르는 것과 같은 관례.)*

호출 즉시 `PreRef():Callback(guard(fn))`/`PostRef():Callback(guard(fn))`/`Effect(...)`가
실행되고, children 배열에 실제로 놓이는 건 **그 결과인 `PreRef`/`PostRef`/
`EffectHandle` 인스턴스 자체**임 — `OnCreated`라는 이름이나 개념은 이
시점 이후 어디에도
안 남음. `Dispatch`는 이미 아는 `(v=PreRef)`/`(v=PostRef)`/`(v=EffectHandle)` 매치
핸들러로 정확히 똑같이 처리하고, 새 브랜드 태그조차 필요 없음(이미
존재하는 `Brand`로 그대로 식별됨).

이게 바로 사용자가 처음에 걱정했던 **"`:Compute` 콜백에 `State<function>`이
들어오면 처리가 까다로워지지 않을까"** 문제가 애초에 안 생기는 이유와
정확히 같은 뿌리: 그 우려는 `OnCreated`가 **해시 파트 특수 키**(예:
`[OnCreated] = fn`)였다면 실제로 발생했을 문제임 — 특수 키는 Store/Dispatch
디스패치 경로를 거쳐야 하고, 그 값이 `State<function>`으로 감싸이는
경우까지 핸들러가 다뤄야 함. 반면 팩토리 함수 호출은 **Store/Dispatch
경로를 아예 안 탐** — 순수 Lua 함수 호출이 즉시 평가되어 끝나고, 그
결과(`PreRef`/`EffectHandle`)가 이미 Store/State 값이 아니라 확정된
객체로서 children 배열에 얹히기 때문. 즉 `State<function>` 문제는
"이 값이 언제/어떻게 디스패치되는가"의 문제인데, 팩토리 접근은 애초에
디스패치될 "값"을 안 만들고 곧장 "결과 객체"를 만들어버림.

## ① 확정된 슈가 셋

### `OnCreated(fn)`

`PreRef():Callback(guard(fn))`를 반환하는 순수 팩토리(**[2026-08-26 `H-120`]**
`guard`는 생략 불가 — 위 확정 스케치가 소스). `PreRef`의 기존 계약을
그대로 물려받음(`base/ref-plan.md` "`phase` 옵션 폐기 → 위치로 표현,
`PreRef` 신설" 절) — 다른 모든 children/프로퍼티/이벤트보다 먼저
호이스팅되어 fire, 즉 "이 인스턴스에 뭐가 됐든 일어나기 전"에 콜백이
불림. 새 Dispatch 메커니즘 불필요, `PreRef` 그대로 재사용.

**[2026-08-28 `Claim` 캐비엇]** `Claim`(`base/claim-plan.md` §4)한 inst에선 이 보장이 약해진다 — inst는 이미 템플릿의 자식·프로퍼티를 갖고 있고 `OnCreated`가 뜻하는 건 "quad가 손대기 전"뿐이다.

**v1과의 관계 — 이름이 같아 보여도 메커니즘은 다름.** `base/ref-plan.md`
"`phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설" 절에 이미 이렇게 확정돼
있음:

> quad v1의 `OnCreated` 특수 키는 이식하지 않는다.
> `Ref():Callback(function(inst) end)`를 children 배열에 넣는 것만으로
> 완전히 대체됨(여러 개 등록도 자연히 지원, 별도 특수 키 불필요) — v1
> 대비 빠진 기능처럼 보이지 않도록 이 대체 관계를 문서에 남겨둠.

이 문장이 거부한 건 v1식 **"특수 키"** 메커니즘(해시 파트에 매직
키를 두고 Dispatch가 그 키를 특별 취급하는 것)이지, **"팩토리 함수가
기존 `Ref`/`PreRef`를 반환해서 children 배열에 놓는 것"**과는 층위가
다름 — 이 문서의 `OnCreated(fn)`은 정확히 저 문단이 이미 권장한
관용구(`Ref()`/`PreRef():Callback(guard(fn))`)를 이름 하나로 감싼 것뿐이라
모순이 아니라 그 결론의 자연스러운 재포장임. 이름이 v1과 같아 헷갈릴
수 있다는 점만 "이름 컨벤션" 절에서 별도로 짚음.

### `OnRendered(fn)` (2026-08-14 아홉 번째 세션 확정)

`PostRef():Callback(guard(fn))`를 반환하는 순수 팩토리 — `OnCreated`와 완전히
같은 패턴이고, 반환하는 프리미티브만 거울상. `PostRef`의 계약을 그대로
물려받으므로(`base/ref-plan.md`의 "`PostRef`" 절):

- **불리는 시점**: 이 인스턴스의 children(과 그 서브트리 전체)과
  프로퍼티/이벤트가 **전부 세팅된 뒤**.
- **⚠️ 불리지 *않는* 시점**: 이 인스턴스가 **부모에 붙은 뒤가 아님**.
  `PostRef`는 자기 아래(서브트리)의 완성만 보장하고 자기 위(조상 체인)는
  아직 없을 수 있음 — React `componentDidMount`가 DOM 삽입 **후**인 것과
  다르므로, 이름만 보고 "화면에 올라간 뒤"로 기대하지 않도록 **사용자
  문서에 반드시 명시**할 것(아래 "이름 컨벤션" 절도 참고).
- 복수 `OnRendered` 간 상대 순서는 **배열 index 순서로 보장**(`PostRef`
  계약, `OnCreated`도 동일).

### `OnDestroyed(fn)`

`Effect(function() return fn end)`를 반환하는 팩토리. `Effect(fn, ...deps)`가
**deps 생략 시** "설치 시 즉시 1회 실행 + 반환값이 leaf 사망 시 정확히
1회 호출되는 cleanup"이라는 기존 계약(`base/effect-plan.md` 28행)을
그대로 재사용 — 다만 여기서는 **설치 단계에서 실행되는 함수가 `fn`
자신이 아니라 `function() return fn end`라는 래퍼**라는 점에 주의.
그 래퍼의 "즉시 1회 실행"은 그냥 `fn`을 감싸 리턴하는 것뿐이라 부작용이
없고, **`fn` 자신은 leaf가 죽을 때(cleanup 시점)에만 실제로 호출됨** —
`fn`을 설치 단계에서 안 부르고 cleanup으로만 등록하는 트릭. 새
Dispatch/Effect 메커니즘 불필요, 기존 계약 재사용만으로 정확히
"Destroy 시 1회 호출"이 나옴.

### 다중 등록 가능 — 이 제안의 핵심 특징

```lua
Frame {
    OnCreated(fn1),
    OnCreated(fn2),
    OnRendered(fn3),
    OnDestroyed(cleanupA),
    OnDestroyed(cleanupB),
}
```

**같은 계열끼리의 상대 순서는 배열 index 순서로 보장됨** — `fn1`이
`fn2`보다 먼저 불림(`PreRef`/`PostRef` 공통 계약, `base/ref-plan.md`).
이게 유용한 대표 사례는 **`PreRef`를 반환하는 다른 팩토리와의 합성**:
예컨대 `FastQuery(...) -> PreRef`처럼 앞자리 항목이 뭔가를 미리
해결해두면, 그 뒤에 오는 `OnCreated(fn)`은 **그게 이미 끝났음을 전제로**
동작할 수 있음(사용자 제시 사례).

```lua
Frame {
    FastQuery(...),          -- PreRef를 반환하는 팩토리
    OnCreated(function(inst) -- 위가 이미 끝난 뒤에 불림
        ...
    end),
}
```

**다만 스타일 권고**: 서로 얽힌 두 훅을 순서로 조율하는 것보다 **하나의
훅 안에서 순서대로 부르는 게** 대개 의도가 더 잘 드러남 — 보장은 하되,
위처럼 "앞의 것이 뒤의 것의 전제를 만들어주는" 명시적 합성이 아니면
기대지 말 것.

`OnCreated(fn)`/`OnRendered(fn)`/`OnDestroyed(fn)` 호출마다
`PreRef()`/`PostRef()`/`Effect(...)`
**생성자가 매번 새로 불려 독립된 인스턴스**를 만들어냄 — children
배열의 서로 다른 숫자 슬롯에 놓이므로, 같은 인스턴스에 여러 개를
나란히 등록하는 게 자연히 지원됨. 이건 `Ref():Callback(fn)` 단일
슈가 관용구나 v1의 단일 특수 키 관례와 달리, **팩토리-함수 접근이 주는
공짜 이점**임(v1처럼 "이 키엔 콜백 하나만" 같은 제약이 아예 성립할
자리가 없음 — 애초에 키가 아니라 매번 새로 만들어지는 값이므로).

**`PreRef`의 "1회용, 재사용 시 error" 가드와 안 충돌하는 이유
(`base/ref-plan.md` "`phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설" 절의
`_fired` 관련 대목)**: 그 가드가 막는 건 **같은 `PreRef` 객체를 두 번째
construction에 재사용**하는 것("이미 한 번 fire된 PreRef 객체를 다시
놓으면 stale `.Value`로 콜백이 조용히 잘못 호출됨") — "여러 개의 서로
다른 `PreRef`를 나란히 쓰지 마라"가 아님. `OnCreated(fn1)`과
`OnCreated(fn2)`는 각각 `PreRef()`를 독립적으로 호출해 서로 다른 객체를
만드므로, 이 가드가 막으려는 재사용 시나리오 자체가 발생하지 않음.

## ② `OnRendered`(+`PostRef`) — 채택 확정 (2026-08-14 아홉 번째 세션)

> **[역전, 2026-08-14 아홉 번째 세션]** 이 절은 원래 "의도적으로 지금
> 구현 안 함, 백로그 후보만"이었음(같은 날 여섯 번째 세션 결정) —
> `OnCreated`/`OnDestroyed`와 달리 디스패치 코어에 새 단계가 필요해
> "공짜가 아니다"라는 게 근거였고, 그 판단 자체는 지금도 맞음. 뒤집힌
> 건 **그 비용을 지불할지**로, 사용자 판단은 **"Pre-Post 둘을 지원 안 할
> 이유가 없고, 구현 난이도가 아주 낮아서 괜찮다"** — 아래 스케치가 이미
> "새 전체 순회 없음, pre-pass에 분기 하나 + 짧은 목록 소비"까지
> 줄여놨던 게 결정적. **정본은 이제 `base/ref-plan.md`의 "`PostRef`"
> 절**(프리미티브로서의 계약·보장 범위·Handler)이고, 아래는 그 결론에
> 이르게 된 조사/논거를 그대로 보존한 것.

`base/dispatch-core-plan.md`의 "확정된 디스패치 모델" 절이 계약하는
본체 루프의 배열→해시 순서 계약(**[2026-08-22 용어]** 이 문서가 쓰는
"두 패스"는 그 본체 루프의 옛 이름이다 — 구현은 단일 일반화 `for`,
`base/ref-plan.md`의 같은 용어 각주와 `base/dispatch-core-plan.md`의
`F-4-1` 정정 문단) 기준으로 현재 base가 제공하는
훅들의 타이밍을 정리하면:

| 훅 | 시점 |
|---|---|
| `PreRef` | 두 패스보다도 **먼저**(호이스팅 pre-pass) |
| 일반 `Ref`/`Effect`(children 배열 위치) | **배열 파트** 처리 시점(아직 해시 파트 전) |
| `PostRef` **[2026-08-14 아홉 번째 세션 신설]** | 해시 파트(프로퍼티/이벤트)까지 **전부 끝난 뒤** |

즉 "이 인스턴스의 프로퍼티/이벤트까지 전부 세팅된 뒤"를 보장하는 훅이
**당시 base 설계엔 없었음**. 이건 기존 프리미티브 재사용만으로는 안 되고
디스패치 코어에 실제로 새 단계가 필요하다는 뜻이라, `OnCreated`/
`OnDestroyed`와 달리 **진짜로 공짜가 아님** — 그래서 처음엔 채택을
보류했고, 아래 스케치로 비용이 충분히 작다는 게 드러난 뒤 채택됨.

**`PostRef` 스케치(사용자 제안, 2026-08-14, 두 번째 세션에 `ProcessedPreRef`
선례 반영해 갱신, 같은 세션 후속 제안으로 다시 갱신 — "후행 스캔" 초안
폐기)** — 완전히 새로운 메커니즘을 발명할 필요는 없어 보임. **핵심 통찰
(사용자 제안): `PreRef`의 pre-pass가 이미 배열 파트 전체를 index 순서로
한 번 훑고 있으니, 같은 스윕에서 `isPostRef(v)`도 같이 잡아내면 되고
`PostRef` 전용 후행 재순회(두 번째 전체 `for`)는 아예 필요 없음.**

- **pre-pass 한 번으로 `PreRef`/`PostRef` 둘 다 처리**: 같은 루프 안에서
  `isPreRef(v)`면 기존 그대로 그 자리에서 즉시 fire하고
  `flattened[i] = ProcessedPreRef`로 소진. `isPostRef(v)`면 **아직
  fire하지 않고**, 이 `Dispatch.drive(inst, flattened)` 호출 하나에만
  로컬인 평범한 배열 `postRefList`(`Relate` 같은 별도 저장소 불필요 —
  이 함수 콜스택 안에서만 살면 됨)에 그 인스턴스를 순서대로 push하고
  즉시 `flattened[i] = ProcessedPostRef`로 소진(1회용 재사용 가드
  `_fired`도 이 시점에 세팅 — "슬롯이 소진되는 시점"과 "재사용 방지가
  걸리는 시점"을 `PreRef`와 동일하게 맞춤, 실제 콜백 fire와 시점이
  갈리는 건 아래 항목뿐).
- **`ProcessedPostRefHandler`는 `ProcessedPreRefHandler`와 완전히
  대칭**: 정상 본체 루프가 `ProcessedPostRef`를 매치해
  `setLength(0)`/`setOffsetSource(None)`을 등록하고 no-op retract를
  반환 — 새 비대칭 규칙이 필요 없음. **[정정] 이전 초안은 "PostRef는
  소진 전 원본 값이 정상 본체 루프의 매치 대상이어야 한다"고
  잘못 짚었었는데, pre-pass에서 미리 소진해두면 그 비대칭 자체가 안
  생김** — `PreRef`의 "동적 경로 가드" Handler(정상 스캔에서
  `isPreRef(v)`를 잡아 즉시 error)와 짝이 되는 `PostRef`용 가드 Handler도
  똑같이 필요(pre-pass가 놓쳤을 때만 매치되는 버그 케이스 전용, `error`).
- **두 패스가 끝난 뒤, `Dispatch.drive`가 `postRefList`를 그 순서 그대로
  순회하며 각 `PostRef`를 fire** — 별도 후행 전체 재순회가 필요 없음,
  pre-pass가 이미 만들어둔 목록을 그대로 소비하면 끝. 복수 `PostRef`
  간 순서는 복수 `PreRef`와 같은 원칙(배열 index 순서 그대로, **보장**)이
  자연히 적용됨 — 2026-08-14 아홉 번째 세션에 이 보장을 잠깐 미보장으로
  뒤집었다가 같은 세션에 철회했음
  (`archive/preref-order-unguaranteed-withdrawn.md`).
- 결과적으로 `PreRef`와 `PostRef`는 **소진 메커니즘이 완전히 대칭**
  (둘 다 pre-pass에서 즉시 `Processed*` 센티널로 소진, 둘 다 전담
  `Processed*Handler`가 Length/Offset을 등록) — 유일한 차이는 "실제
  콜백을 언제 부르는가"(`PreRef`는 pre-pass 그 자리, `PostRef`는 두
  패스가 다 끝난 뒤 `postRefList` 순회) 하나뿐. `_fired` 1회용 가드도
  거울상 그대로 재사용. 비용도 애초 우려("루프 한 번이 추가되는 비용")보다
  작음 — 추가되는 건 전체 배열 재순회가 아니라 `postRefList`(실제
  `PostRef` 개수만큼)의 순회뿐이라, "공짜"는 아니어도 이전 "후행 스캔"
  초안보다 훨씬 저렴. `OnRendered(fn)`은 `PostRef():Callback(guard(fn))`을
  반환하는 팩토리로, 위 `OnCreated`와 완전히 같은 패턴이 됨.

**스코프 — 해소됨(2026-08-14 아홉 번째 세션).** 원래 이 자리엔 "렌더
완료"가 (a) 이 인스턴스 자신의 프로퍼티/이벤트 세팅만인지 (b) 자식
서브트리 전체 완료까지인지가 **불명확**하다고 적혀 있었고, "(a) 메커니즘은
(b)를 못 준다"고 판단했었음 — **그 판단이 틀렸다는 게 사용자 지적으로
드러남**: 배열 파트 루프가 각 자식의 마운트를 **동기적으로 끝내고**
(`Slot`은 실 확정 시 요소를 그 자리에서 주입, `State<Frame>`도 최초 값을
그 자리에서 처리) 넘어가므로, 두 패스가 끝난 시점엔 **정적으로 선언된
서브트리가 이미 전부 완성돼 있음**. 즉 (a) 메커니즘이 사실상 (b) 스코프를
공짜로 줌.

**단, 진짜 경계는 (a)/(b)가 아니라 "자기 아래 vs 자기 위"였음** —
`PostRef`는 자기 서브트리 완성은 보장하지만 **이 인스턴스가 부모에 붙는
것보다는 여전히 먼저** 불림. 이 캐비엇의 정본 서술은 `base/ref-plan.md`의
"`PostRef`" 절 "보장 범위" 항목.

**[풀어쓰기, 2026-08-20 구현 전 QA 4라운드 `LH-8`]** 위 두 문단이 너무
압축돼 있어 그것만 읽고는 판단이 안 된다는 지적이 있어서, 같은 내용을
코드로 다시 적는다. `Frame { Frame { TextLabel {} , OnRendered(fn) } }`에서
안쪽 `Frame`의 `fn`이 불릴 때:

```
바깥 Frame { ... }          ← ⑤ 이 호출은 아직 시작도 안 함
  └ 안쪽 Frame { ... }      ← ④ 이 drive가 지금 끝나는 중
      ├ TextLabel {}        ← ① 이미 완성돼 안쪽 Frame에 붙어 있음
      └ OnRendered(fn)      ← ③ fn이 여기서 불림
      (프로퍼티/이벤트)       ← ② 이미 전부 세팅됨
```

- **①② = "자기 아래"** — 안쪽 `Frame`의 자식(그리고 그 서브트리 전체)과
  자기 프로퍼티/이벤트. `fn`이 불릴 때 **전부 끝나 있다.**
- **⑤ = "자기 위"** — 안쪽 `Frame`이 바깥 `Frame`의 자식이 되는 일.
  Lua 표현식 평가 순서상 **안쪽 `Frame{...}` 호출이 완전히 끝나야** 바깥
  `Frame`의 props 테이블이 완성되므로, `fn`이 불리는 시점엔 바깥 `Frame`은
  아직 존재하지도 않는다. 조상 체인 전체가 마찬가지다.
- **그래서 "화면에 올라간 뒤"가 아니다** — 화면에 올라가려면 루트까지의
  조상 체인이 다 이어져야 하는데 그건 ⑤ 이후 일이다. React
  `componentDidMount`(DOM 삽입 **후**)를 기대하면 어긋난다.
- **원래 뭐가 헷갈렸나**: 처음엔 경계를 "이 인스턴스의 프로퍼티만이냐(a),
  자식 서브트리까지냐(b)"로 놓고 "(a) 메커니즘으론 (b)를 못 준다"고
  판단했는데, 배열 파트 루프가 각 자식을 **동기적으로 끝내고** 넘어가므로
  ①이 공짜로 따라온다 — (a)/(b)는 애초에 갈리는 지점이 아니었고, 실제로
  갈리는 건 ①②(자기 아래)와 ⑤(자기 위)였다.

**착수 시점 선택지 — (a) 확정.** 원래 (a)/(b)/(c) 셋을 열어뒀었고
((b)는 일반 `Ref`로 근사, (c)는 계속 스코프 아웃), 사용자가 **(a)**
(위 `PostRef` 스케치대로 두 패스 뒤 `postRefList` 소비)를 선택함.

## 이름 컨벤션

- **`On` 접두 자체는 이미 선례가 있음** — `base/onchange-plan.md`의
  `OnChange(name)`(`GetPropertyChangedSignal` 바인딩용 특수 키). 단
  **메커니즘은 다름**: `OnChange`는 이름을 인자로 받아 캐시된 키 객체를
  반환하는 **해시 파트 특수 키 팩토리**(`base/onchange-plan.md` "확정"
  절)인 반면, 이 문서의 `OnCreated`/`OnRendered`/`OnDestroyed`는 **배열
  파트에 놓이는 값(`PreRef`/`PostRef`/`EffectHandle`)을 만드는 팩토리**라
  이름 패턴만
  같고 소속 카테고리가 다름 — `OnChange` 쪽 "다른 특수 키와의 대조"
  표에 이 둘을 끼워 넣을 필요는 없어 보임(별도 표로 다루는 게 맞음).
- `OnCreated`/`OnDestroyed` **이름 확정** — 다만 v1이 이미
  `OnCreated`라는 이름을 다른 메커니즘(특수 키)으로 썼던 전례가
  있어 위 "①" 절의 대조 설명 없이 이름만 보면 헷갈릴 수 있음, 문서화
  시 명시할 것.
- `OnDestroyed`는 최초 가칭이던 `OnDisposed`보다 사용자가 선호 —
  **`OnDestroyed`로 영구 확정**(2026-08-14 열 번째 세션, `dispose()` 범위
  확정으로 재검토 조건 자체가 종결됨 — 아래). `OnDisposed`가 제안된
  이유는 미래 `dispose()` 함수(`archive/question-resolved.md` 0-B)와
  이름을 맞추자는 발상이었는데, 대조해보면 트리거 자체가 다름:
  - `dispose(value)`는 사용자가 **의도적으로** 부르는 명시적 파괴
    API(대상이 아직 트리에 의해 살아있길 요구되면 파괴를 **거부하고
    error**, `base/slot-plan.md`). "언제 부를지"를 호출자가 고르는
    능동적 경로.
  - 반면 이 문서의 훅은 `Effect`의 leaf-death cleanup에 얹히므로,
    실제 트리거는 **물리 Instance가 죽는 시점**(엔진 `Destroying`
    신호, `bindLifetime`이 감시하는 이벤트)임 — 그 죽음이 `dispose()`를
    거쳤는지, 누가 직접 `:Destroy()`를 불렀는지, reconcile이 알아서
    정리했는지는 이 훅 입장에서 구분도 안 되고 상관도 없음.
  - 그래서 `OnDisposed`는 "`dispose()`를 불렀을 때만 발화한다"는
    잘못된 인상을 줄 위험이 있고, `OnDestroyed`가 실제 트리거(엔진
    `Destroying`)를 더 정직하게 반영함 — **`OnDestroyed`가 최종 이름**.
  - **[해소, 2026-08-14 열 번째 세션]** 재검토 조건이던 "`dispose()`가
    Slot뿐 아니라 Instance/Effect까지 포함해 quad가 만드는 모든 것의
    유일한 파괴 경로로 확정되면"은 **발동하지 않는 쪽으로 결정됨** —
    `dispose()`의 범위는 오히려 `Slot`+`Instance`로 좁혀지고
    `Observer`/`Effect`는 명시적으로 제외됐음(`archive/
    question-resolved.md` 0-B). `OnDestroyed`↔`dispose()` 이름을 맞출
    이유 자체가 사라져 더 이상 재검토 대상 아님.
- **`OnRendered`/`PostRef` — 이름 확정(2026-08-14 아홉 번째 세션).**
  `PostRef`는 `PreRef`와의 대칭성이 이름에서 바로 읽혀 이견 없음.
  `OnRendered`는 채택되며 이름도 그대로 확정 — 다만 **"렌더"가 quad엔
  없는 개념**(React식 재렌더 루프가 없음, `base/architecture.md`)이라는
  원래 우려는 유효하고, 여기에 **"이 인스턴스가 부모에 붙기 전에
  불린다"**는 캐비엇까지 겹침. 즉 이 이름은 **"React에서 오는 사람이
  기대하는 것과 미묘하게 다른 시점"**을 가리키므로, 문서화 시 위 ①
  절의 ⚠️ 항목을 반드시 같이 노출할 것(이름을 바꾸는 대신 문서로
  대응하기로 한 것 — 이름의 친숙함이 주는 이득이 더 크다는 판단).
  **[백로그 신설, 2026-08-20 구현 전 QA 4라운드]** 진짜
  `componentDidMount`(= 조상 체인까지 이어져 화면에 실제로 올라간 뒤)에
  해당하는 훅은 **지금 만들지 않되 백로그로 남긴다.** 사용자 메모:
  *"OnRendered 라는 이름이 componentDidMount 같은거 구현 가능하면 좋긴
  하겠는데 별로 애매한가 생각중... 화면 그려지기 전에 애니메이션이 된다던가
  하지 않게 하는 방안이 있음 좋아보임. 하지만 나중에 얹어져도 좋을
  이야기이고, 당장은 사용사례가 안 보이므로 추가 프리미티브에 백로깅만 하고,
  나중에 필요하다는 의견이 나오면 재생각 해볼 예정."*
  - **쓸모 있는 시나리오**: "화면에 그려지기 전에 애니메이션이 시작돼버리는"
    것을 막는 것 — 진입 애니메이션(`base/tween-plan.md`의 `initValue`,
    루트 `HUMAN_TODO.md` 10번)과 맞닿는 자리다.
  - **왜 지금 안 만드는가**: `PostRef`와 달리 **자기 위**를 알아야 하므로
    `Dispatch.drive` 한 번의 콜스택 안에서 표현할 수가 없고(부모의 drive가
    자식을 붙인 뒤에야 알 수 있음), 별도 전파 경로가 필요하다 — "공짜"가
    전혀 아니다. 그런데 구체적 사용 사례가 아직 안 보이므로
    `conventions.md`의 "드문 오용이나 가상의 미래 요구까지 방어/최적화하려고
    구조를 복잡하게 만들지 않는다" 원칙대로 보류.
  - **요구가 나오면 재검토** — 그때 `OnRendered`와 이름을 어떻게 가를지도
    같이 정해야 한다(지금 `OnRendered`가 이미 그 이름을 점유 중이라
    혼동 위험이 있음).

## 패키지 배치

**quad-base 확정(2026-08-14 아홉 번째 세션).** `Ref`/`PreRef`/`PostRef`/
`Effect`가 전부 quad-base 프리미티브이므로 이 훅 셋은 그 위의 순수
함수일 뿐 — `Operator`/`Fallback`과 같은 결(엔진 지식이 전혀 필요 없는
순수 조합). `PostRef`의 pre-pass 수집/`postRefList` 소비도 `Dispatch.drive`
(quad-base) 소유라 층위가 일관됨.

## 우선순위

**두 층위를 구분할 것**:
- **`PostRef` 프리미티브 자신** — 디스패치 코어의 일부라 `ROADMAP.md`
  M8(Ref)에서 `PreRef`와 **같이** 구현됨. 뒤로 미루는 대상이 아님.
- **이 문서의 훅 슈가 셋(`OnCreated`/`OnRendered`/`OnDestroyed`)** —
  형제 백로그 항목들과 동급, 맨 뒤(`quad-mock`/`quad-debug`/`Operator`/
  `Fallback`과 같이 "quad 개발 상당 부분 끝난 뒤"). 착수 시점에 위 코드
  스케치를 그대로 옮기면 될 만큼 단순하고, 순수 슈가라 없어도
  `PreRef()/PostRef():Callback(guard(fn))`·`Effect(fn)`를 직접 쓰면 되므로
  기능 격차가 없음.

## 열린 질문

**[2026-08-14 열 번째 세션] 열린 질문 없음** — 채택 여부/메커니즘/
스코프/패키지 배치에 이어, 마지막까지 남아있던 `OnDestroyed` 이름
재검토 조건도 `dispose()` 범위(0-B)가 `Slot`+`Instance`로 좁혀지고
`Observer`/`Effect`는 제외되는 쪽으로 확정되며 발동 없이 종결됨(위
"이름 컨벤션" 절) — `OnDestroyed`가 최종 이름. 착수 시점에 위 각 절을
순서대로 확인하면 됨.
