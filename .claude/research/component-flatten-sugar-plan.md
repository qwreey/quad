# 컴포넌트 경계 flatten 슈거 — 백로그 (2026-09-06, 사용자 제기)

**상태**: research — **백로그, 사용자 답 대기.** 구현 착수 안 함. 사용자 판단
(2026-09-06): *"flatten 슈거 그거는 사실 추후에 개발되어도 되는 부분이고, 지금
개발하는데 결정이 막을 만한 요소도 아님. 그냥 백로깅 대상으로 두는게 맞아보여."*
이 문서는 그 "전반적 구조를 스캐폴딩할 계획"이다 — 사용자가 나중에 보고 답한다.
발단은 M9 round21 §4의 둘(`archive/v2-initial-implementation/m9-implementation-round21.md`): 경계 필드
이름 Q2와 `H-340`(커스텀 클래스 Modifier의 커스텀 필드를 벗겨 부모 클래스로 넘길
길이 없다). 둘 다 이 슈거가 있으면 자연히 풀리거나 무관해진다.

## 1. 문제 (왜 필요한가)

컴포넌트는 플레인 함수이고 경계는 named parameter다(`base/component-composition-plan.md`
"최종 결론"). 지금 컴포넌트 저작자가 받은 Modifier로 할 수 있는 일은 셋뿐이다 —
그대로 되꽂기(`props.Modifier or None`), `:Peek(key)`로 한 필드 읽기, `As(name)`
재태그. 다음이 안 된다:

- **커스텀 필드를 소비하고 나머지를 부모 클래스 루트에 넘기기**(`H-340`) —
  `Material({ Elevation = 2, BackgroundTransparency = 0.3 })`에서 `Elevation`은
  컴포넌트가 쓰고 나머지는 `TextButton`에 가야 하는데, `:Elevation(None)`은 키
  제거가 아니라 `None` 디스패치라 `no handler matched key Elevation`이 난다.
- **modifier를 데이터로 순회**하기 — `Peek`는 키 하나씩이라 "모든 필드"를 볼 수 없고,
  값이 State인지 리터럴인지 `None`인지를 저작자가 직접 갈라 봐야 한다.
- **배열부 값 분리** — `Frame{ props.Modifier or None, props.Ref or None, … }`처럼
  되꽂는 자리에서 PreRef/Ref/PostRef·Tag·Attr·자식 Instance를 종류별로 다루고
  싶을 때 도구가 없다.

사용자 원문(2026-09-06): *"처음부터 커스텀 modifier는 peek를 통해서 하나하나 확인하는게
일반적이지 않을까? 그걸 돕는 슈거를 만드는게 나을 수도 있겠다"*, *"일반적인
modifier를 위해서 그걸 flatten을 돕는 도구라던가(순수 슈거)"*. 더 앞선 발언(M7 단위 ④,
`session/2026-09-04-05-*.md`): *"preref, ref, postref를 추출하고 modifier를 flatten한
테이블을 만들어주는 슈거 함수로 나중에 외부에 둘 생각이었지. 그걸 통해 컴포넌트가
어느정도 여러 기능을 할 수 있게 해주는 생각."*

## 2. 스캐폴딩 (제안 — 전부 미정, 사용자 답 대상)

**원칙**: base 코어에 새 메커니즘을 넣지 않는다. 이미 있는 `flatten`(Dispatch pre-pass의
Modifier 병합 규칙)과 브랜드 술어(`isModifier`/`isRef`/`isPreRef`/…)를 조합한 **순수
슈거**로, quad-base가 아니라 별도 유틸(`quad-component` 가칭, 또는 quad-roblox 유틸
층 — `Animate`와 같은 지위)에 둔다.

```lua
-- 가칭. 이름·시그니처 전부 미정.
local parts = Component.Split(props)   -- props = 컴포넌트가 받은 테이블 그대로
-- parts.fields   : { [string]: any }   -- 해시부 + Modifier들을 flatten한 결과(뒤가 이김 — Overridden 규칙)
-- parts.preRefs  : { PreRef }          -- 배열부에서 종류별로 뽑아낸 것들(순서 보존)
-- parts.refs     : { Ref }
-- parts.postRefs : { PostRef }
-- parts.children : { any }             -- 나머지 배열부(Instance/State/Slot/Tag/Attr/OnChange 디스크립터 …)
-- parts.rest(keys) -> Modifier         -- 소비하지 않은 필드만으로 새 Modifier(부모 클래스 태그로) — H-340의 자리
```

컴포넌트 저작 예:

```lua
local function MaterialButton(props)
	local p = Component.Split(props)
	local elevation = p.fields.Elevation          -- 커스텀 옵션: 그냥 읽는다(State일 수도 있음 — 저작자가 안다)
	return D.TextButton({
		p.rest({ "Elevation" }):As("TextButton"),   -- 소비한 키를 뺀 나머지를 부모 클래스로
		p.refs, p.preRefs, p.postRefs,              -- 되꽂기 — 배열 리터럴에 nil 없음(빈 배열은 자리 기여 0)
		p.children,
		Text = p.fields.Text or "",
	})
end
```

**정해야 할 것(사용자)**:

1. **단위**: props 테이블 전체를 받는가(`Split(props)`), Modifier 하나만 받는가
   (`Modifier.Fields(mod) -> {[k]=v}`), 둘 다인가.
2. **State 필드 취급**: `fields`에 State를 그대로 두는가(저작자가 `isState`로 가르기),
   `:Get()`으로 풀어 주는가(반응성 상실 — 아마 아님), 둘 다(`fields`/`resolved`)인가.
3. **`rest`의 형태**: 남는 필드로 새 Modifier를 만드는 것(위) vs 소비 키만 빼는
   `Without`(round21 `H-340` (a) — 사용자는 `Without` 단독 제공엔 회의적).
4. **배열부 분리의 범위**: Ref 셋만 뽑을지, Tag/Attr/OnChange까지 종류별로
   나눌지, 아니면 `children`으로 뭉쳐 둘지.
5. **되꽂기 표기**: 배열을 배열 자리에 넣는 것(`{ p.refs, … }`)은 지금 디스패치가
   지원하지 않는다(배열 안 배열) — Slot을 쓰거나, `table.unpack` 관용구를 정하거나,
   디스패치가 중첩 배열을 평탄화하게 할지(코어 변경 — 이건 슈거가 아니다).
6. **경계 필드 이름**(Q2): 이 슈거가 있으면 `props.Modifier`/`props.Ref`는 "관례"일
   뿐이고 `Split`이 배열부에서 종류별로 뽑으니 named 자리 자체가 선택이 된다 — 그래도
   named 관례를 문서에 남길지.
7. **패키지**: quad-roblox 유틸(`Animate` 옆)인가, 엔진 무관이라 quad-base 옆
   별도 패키지인가(브랜드 술어만 쓰므로 엔진 무관이 맞아 보인다).

## 3. 관련

- `base/component-composition-plan.md` "최종 결론" 절(관례 정본), `base/modifier-plan.md`
  11절(`Into`·`As` — 커스텀 서브타입의 런타임 틈이 `H-340`), `base/dispatch-core-plan.md`
  flatten 규칙, `archive/v2-initial-implementation/m9-implementation-round21.md` §4.
- `research/operator-sugar-plan.md` — 같은 "순수 슈거는 나중에, 코어는 건드리지 않는다" 결.
