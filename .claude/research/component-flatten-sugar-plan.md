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

**[2026-10-12 관측 — 첫 소비자 사례]** Material 킷을 쓰는 table-sim이 `Material.Button({ Modifier = D.Modifier.TextButton():Name("SaveButton") })`로
호스트 이름을 못 바꿨다(킷이 호스트에 `Name = "Button"`을 인라인으로 적고, 인라인 문자 키가 Modifier를 이긴다). 그날 처방은 킷이 호스트
`Name`을 기본 Modifier로 옮기는 것(사용자 승인)이지만, 사용자가 짚은 대로 이 슈거가 없어서 생기는 모양이기도 하다 — *"인라인 값으로 함수에
인자로 넣어도 가능해도 될것 같긴 한데 … flatten 슈거 안 만들어진 이슈가 조금 들어오는 부분인가"*. 킷의 Props는 닫힌 필드 목록이라
`Material.Button({ Name = "SaveButton", Label = … })`처럼 호스트 프로퍼티를 인라인으로 받으려면 컴포넌트마다 필드를 하나씩 선언해 손으로
넘겨야 하고, 그래서 킷은 호스트 프로퍼티 전부를 `Modifier` 한 필드로만 받는다. `Split`의 `fields`/`rest`가 있으면 "킷이 쓰는 키는 소비하고
나머지는 기본값 위에 얹어 호스트로"가 한 줄이 된다. 근거 사례 하나로 기록만 한다(경위 `feedback/table-sim-2026-10-12.md`).

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

**[2026-09-08 사용자 메모 — 답은 "내일", 생각할 거리가 더 있다]** 사용자: *"여기에 있어서는 named
ref 나 named modifier 등을 지원하게 될 텐데, 이거는 일반 leaf 와는 다름 — 이게 핸들러를 안 탄다는
점에서 약간 달라지는건데, 이 슈거에 대해서 어떻게 다뤄야 하는가, 오해의 소지를 어떻게 해결하냐 (이
자체로 drive 되는걸로 보이면 안 되기에) 를 더 생각해보아야할듯. 아에 named ref 등만 받게 하는게 맞을
수도 있고, 명확한 결론이 아직 안 나온걸로 보임."* 즉 위 1~7에 더해 여덟째 축이 하나 더 있다 —
`props.Ref`/`props.Modifier` 같은 **named 자리**는 디스패치 핸들러를 타지 않는 값인데, `Split`이 그
값들을 받으면 "이 테이블이 그대로 drive된다"는 오독을 낳을 수 있다는 것. 갈래로는 (ㄱ) named 자리만
받는 좁은 슈거, (ㄴ) 배열부까지 받되 named/배열 구분을 이름·타입으로 드러내기 등이 있겠으나 사용자
결론 전이라 여기 적지 않는다.

## 3. 관련

- `base/component-composition-plan.md` "최종 결론" 절(관례 정본), `base/modifier-plan.md`
  11절(`Into`·`As` — 커스텀 서브타입의 런타임 틈이 `H-340`), `base/dispatch-core-plan.md`
  flatten 규칙, `archive/v2-initial-implementation/m9-implementation-round21.md` §4.
- `base/operator-plan.md` — 같은 "순수 슈거는 나중에, 코어는 건드리지 않는다" 결.

## 4. [2026-10-06 사용자 방향] 행동 묶음 — 첫 소비자 킷 피드백 C7과의 연결

첫 실사용 소비자(`feedback/consumer-kits-2026-10-05.md` C7)가 hover·drag·focus 같은 재사용 "행동"을 묶을 자리가 없어(Modifier는 이벤트 핸들러를 거부 — `Quad0063`) PostRef + 직접 `:Connect` 훅을 발명했다. 사용자 판단(2026-10-06): **그건 Modifier의 자리가 아니다** — *"이거는 정적 아니고, 적용 대상을 알고 적용 대상에 따라 진행되는 요소라서 Modifier 에 들어갈 자리는 아니야. 나온다 하면 다른게 나와야해."* 방향으로 낸 모양: 팩토리·커링(상위 요소도 받고 하위 요소도 받는)으로 행동을 만들고, `Frame { GivenFactory(...) }`처럼 놓였을 때 **그 출력이 flatten 단계에서 실제로 펴지는 값**이 되게 허용 — 숫자 키는 `table.move`로 옮기면 빠르고 문자 키도 가능. 열린 문제 둘(사용자): 덮어쓰기가 어떻게 되는지 사용자가 알아야 한다, Modifier와 이 펴짐 중 무엇이 먼저인가 — 사용자 기본 입장은 *"별다른 추가 메커니즘 없이 modifier 처럼 유저가 아래 직접 쓴게 먼저(오버라이딩 혹시나 싶으면 가능함)"*. `Frame { MouseEnter = …, MouseLeave = … }`를 손으로 반복하는 것은 끔찍해 보인다는 데엔 동의. **결정 아님 — 지금 정할 수 없음**(사용자: *"C7 은 그래서 지금 당장 결정 가능한게 아닌것 같아"*); 이 문서 2절 스캐폴딩(경계 flatten 슈거)과 같은 메커니즘 축이라 같이 볼 것. 도그푸딩으로 근거가 더 쌓이면 다시.

**[2026-10-06 같은 날 사용자 보강 — 순서와 소유]** *"그냥 본인 먼저 풀리는게 기본이여야할듯. GivenFactory 가 던져주는거 안에 Modifier 가 있는건 정의된 경로인가? -> 그럴 수도 있지 않나 싶음. 두 스테이지로 output flatten 해주는게 먼저, 그 다음 modifier 는 이미 있던 방식 그대로 갈 수 있어보여. 이건 사용자가 승인한, 외부에 위임한 쓰기로 사용자가 외부에서 써내려 줬음을 인정한다고 봐야할 것 같아. 그래서 그게 flatten 되고 나서는 사용자의 선택이 되고, modifier 는 덮어쓰지 못하는 방식. 원한다면, modifier 로 폴백 되어 설정 가능하게 할 수 있고 modifier 가 놓이는 위치도 팩토리 내에서 자유로워. 팩토리를 어디에 실행할 지 유저가 아래로 내리거나 올릴수도 있어. 팩토리의 설명만 해결되면 된다고 보임."* 정리(사용자 방향, 아직 설계 확정 아님): (1) 두 단계 — 먼저 팩토리 출력을 펴고(1단계), 그다음 Modifier가 지금 방식 그대로(2단계); (2) 펴진 출력은 **사용자가 위임해 써 준 쓰기**로 사용자의 선택과 같은 지위 — Modifier는 그것을 덮어쓰지 못한다; (3) 팩토리 출력 안에 Modifier가 있어도 정의된 경로일 수 있다(그 Modifier는 2단계로 간다 — 팩토리가 "덮어쓰지 않는 기본값"을 주고 싶으면 출력에 Modifier로 넣으면 된다); (4) 팩토리를 props 어디에 두느냐(위·아래)는 사용자 자유. 남은 일: "팩토리의 설명"(이 값이 무엇이고 무엇을 펴는지 문서로 정의하는 것), 사용자가 직접 쓴 키와 펴진 키가 겹칠 때의 규칙(위 "본인 먼저" — 직접 쓴 것이 이김으로 읽힘, 확인 필요).
**[같은 날 확인]** 겹치는 키는 **직접 쓴 키가 이긴다 — 그 키는 펴지지 않는다**(사용자: *"사용자가 직접 쓴 키가 있으면, 안 펴지는걸로. 사용자가 쓴 키, 직접 쓴 키가 이김. 명시적으로 덮어쓰는거니까"*). 우선순위: 직접 쓴 키 > 펴진 팩토리 출력 > Modifier.

## 5. [2026-10-15 사용자 결정] 펴 넣는 묶음 `q.Spread` — 이름 확정, 표면은 설계 중

**계기.** devui 창 핸들 논의(`session/2026-10-15-01-release-recheck-kits-list-lazy.md`)에서 Hook 꼴 값이 늘어나는 문제가 다시 드러났다 — 사용자: *"Hook 모양을 전부 풀려면 그 때 말했던 Modifier 와는 다르게 한 곳에서만 쓸 수 있고, unpack 해주는 도구가 있어야 뭔가 논의가 진행 되는거 아닐까"*, 이어서 *"지금 나오는 고통 포인트들은 다 팩토리나 그런것에서 테이블 형태로 내려주고, 그게 derive 대상 테이블에 잘 융합해 들어갈 길이 없다 같아보이는듯. 즉 훅 말이지. 그거 돕는 도구를 만들고자 해야할것 같아."* 4절(행동 묶음, 2026-10-06)의 "팩토리 출력이 펴지는 값"이 바로 그 도구다.

**이름 — `q.Spread`(확정).** sonnet(레포를 안 읽은 외부자)과 Gemini(`audit/naming-spread-2026-10-15/gemini.md`)가 따로 `Spread`를 추천했다 — 동작("놓인 요소에 펼쳐 넣는다")이 이름 그대로이고, JS `{...t}`·Roact 경험자가 바로 읽으며, `Modifier`(정적 기본값)와 역할이 갈린다. 차선은 갈림(sonnet `Mixin`, Gemini `Bundle`); `Fragment`(React에선 자식 전용 가상 노드)·`Unpack`(Luau `unpack`은 배열만)은 둘 다 반대. 사용자: *"나도 동의. 말 그대로 Spread 해주는거니까 그럴만 한것 같음."*

**표면(4절 방향 그대로, 상세는 아직 결정 아님).**
```luau
local function Hoverable(onEnter, onLeave)
    return q.Spread { MouseEnter = onEnter, MouseLeave = onLeave, q.PostRef(...) }
end
D.Frame { Size = ..., Hoverable(enter, leave), MouseLeave = myLeave } -- 직접 쓴 MouseLeave가 이긴다
```
- 배열부에 놓인 `q.Spread{…}`는 펴기 단계에서 그 문자 키·배열 값이 놓인 요소에 직접 쓴 것처럼 들어간다. 우선순위: 직접 쓴 키 > 펴진 Spread > Modifier(4절 "같은 날 확인").
- 묶음 안의 Modifier는 Modifier 단계로 간다(4절 (3)), 묶음 안에 묶음 허용, 한 묶음은 한 요소에 놓이는 값(안에 그 요소용 Ref 등이 있을 수 있어서).

**열린 문항(사용자 답 대상).**
1. 두 Spread가 같은 키를 가질 때 — 앞이 이김 / 뒤가 이김 / 에러. 핸들러를 이어 부르는 합성은 quad의 "마법 없음"과 안 맞아 메인은 후보에서 뺀다.
2. 같은 Spread 값을 두 요소에 놓았을 때 — 에러로 막을지(안의 Ref·Observer가 한 요소용이라), 문서 UB로 둘지.
3. 펴기 루프 재구성 — 지금 `quad-base/src/Dispatch/Modifier/init.luau`의 flatten이 Modifier만 역순으로 펴므로 "직접 쓴 키 보존 → Spread 전개 → Modifier" 세 단계가 된다(Gemini 추정, 메인 확인 전). `drive` 단계 순서 계약(`docs/reference/extend/02-dispatch-handler-contract.md`)이 바뀌는 작은 Changed.
4. 타입 — 생성 `Declaration`의 props 타입이 이 값을 배열부에서 받게 하는 법(마커 타입), 펴진 문자 키의 타입 검사는 포기할지.
5. 2절 "정해야 할 것" 일곱(컴포넌트 경계 flatten — `Split`의 `fields`/`rest`)과의 관계 — 같은 펴기 단계를 공유하는지, 따로 가는지.

**[2026-10-16 사용자 회신 — 5절 문항 1~5]**
- **(1) 같은 키 두 Spread → 뒤가 이김(Modifier와 같은 규칙), 단 props에만.** 사용자가 이벤트 문제를 짚음: *"이벤트는 props 와 다르게 한번만 쓸 수 있는것 아니고, 여러번 Connect 가능하잖아. 근데 이 시점에서 보면 우린 그걸 생각 안 하고 글자 필드에 놓은것 아닐까 … 이러면 사용자가 각각 spread 가 뭘 구독할 지 알고 겹침을 알아야해버려짐 … post/pre ref 를 받아서 구독해야한다면. 이건 API자체가 뭔가 잘못된 구석"*, *"props 는 진짜로 경쟁이 있으면 안 되는게 맞긴함"*. 사실 확인(메인): 이벤트는 문자 키 형태뿐(`quad-roblox/src/Handlers/Event.luau`), `OnChange`만 배열부 디스크립터라 여럿이 각각 연결된다 — 소비자 킷 C7의 PostRef + 직접 `:Connect` 훅이 이 빈칸의 증상. 메인 제안: (가) `OnChange`와 짝인 **배열부 이벤트 디스크립터**(이름 미정 — `q.On` 등)를 두고 문자 키 이벤트는 편의용 "한 칸"으로 남김 / (나) 펼 때 이벤트 키만 합치기(층이 섞이는 마법 — 비권장) / (다) 문자 키 값에 함수 배열(결국 합치기 규칙) — **사용자 결정 대기**.
- **(2) 같은 Spread 값을 두 요소에 → 따로 막지 않음(메인 의견대로).** Spread는 만들 때 얼린 읽기 전용 값, 펼 때 내용을 복사; 안의 한 요소용 값(Ref·Observer·PreRef)은 자기 에러가 잡는다 — 레퍼런스에 "팩토리로 매번 새로" 한 줄.
- **(3) 펴기 순서 Spread 전개 → Modifier → PreRef → 본문, 배열 값은 놓인 자리에 끼워 넣음 — 동의.**
- **(4) 내용 타입은 포기, 대신 만드는 자리의 자동완성** — 사용자: *"Speard<Ty>({}) 에서 자동완성으로 쓰는데 돕는걸 두고, 결과적으로 나온건 내용물에 대한 타입을 하나도 안 받고, SpeardMarker<Ty> 가 나오고, 이것이 New 에 들어갈 수 있는 방향"*, *"Spead<Ty>({ Sperad<Ty>() }) 의 경우는 재귀적으로, Spread 함수 자체가 안에 있는 Spread 를 보고 펼쳐 주는 방식 … 그러면 New 에 쓴 인자를 그대로 Spread 에 받아넣을 수 있는것"* — 안쪽 Spread는 **만드는 시점**에 펴고 `drive`에는 한 겹만. 그리고 *"타입 함수를 통해서 구성하는걸 생각해뒀던 부분도 처리를 해야할 때가 와가는 느낌 … 그걸 처리하면서 같이 Speard 를 생각해보는게 좋겠음"* → 타입은 `research/declaration-surface-plan.md`(Declaration 표면을 타입 함수로) 트랙 안에서 같이 설계.
- **(5) `Split`과의 관계 — 맞물린다는 데 동의, 처리 방식은 나중에**(*"Split/Flatten 슈거에서 어떻게 처리할지는 아직은 미정인것 같음. 나와 봐야 알것 같아"*).
- **순서(메인 제안)**: 이벤트 디스크립터 결정 → Declaration 타입 함수 트랙(그 안에서 `Spread<Ty>`/`SpreadMarker<Ty>`) → `Spread` 런타임 → `Split`은 나중.
- **[2026-10-16 같은 날 — 이벤트 (가) 결정]** 사용자: *"해시 디스크립터 상의 이벤트는 그대로 두고, OnEvent 는 speard 나 팩토리 등에서 결과로 내놓을 때 쓰는 것으로 두면 될 것 같아. 가 안으로 가면 되겠음. 다만 declaration 이 또 길어지겠다만, 타입 함수와 같이 처리가 가능해진다면 해소될 것 … 다음 트랙에서 같이 설계하면 되겠음"*. 문자 키 이벤트는 그대로(손으로 쓸 때의 편의), `OnChange`와 짝인 배열부 이벤트 디스크립터(사용자 1안 `OnEvent`, 이름 탐색 sonnet·Gemini — `audit/naming-onevent-2026-10-16/`)는 팩토리·Spread가 내놓는 형태. 타입은 Declaration 타입 함수 트랙에서 같이.
