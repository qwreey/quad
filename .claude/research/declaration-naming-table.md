# Declaration 새 표면 이름표 — 사용 빈도와 자기서술성으로 체계 맞추기

> **[2026-10-16 신설 — 사용자 요청, 결정 없음]** `declaration-surface-plan.md` 4절 1번(값은 이름·타입은 클래스 타입, 백엔드 계약, `q.Raw`) 회신 중 사용자가
> 배열 자리 타입 이름을 고르다 질문을 넓혔다: *"질문의 범위가 그렇게 국소적인게 아니라, 새로 들어올 Build 를 쓰는 네이밍들이 모두 자기서술적이고, 사용 빈도에 비해서
> 네이밍이 그게 맞는가 의심되는 부분"*. 이 문서는 그 이름 전체를 한 표에 놓은 초안이다 — 초안 이름은 메인 제안이고 결정이 아니다. 실측 근거는
> `audit/decl-typefn-probe-2026-10-16/REPORT.md`, 이름 탐색 둘은 `audit/naming-ctor-2026-10-16/`·`audit/naming-arritem-2026-10-16/`.
>
> **[2026-10-16 같은 날 — 검토(`audit/naming-table-review-2026-10-16/`) 뒤 사용자 결정]** 5절이 결정 목록이다 — 3절 표의 "초안" 칸 중 5절과 다른 것은 5절이 이긴다.

## 1. 원칙(사용자 2026-10-16, 메인 정리)

1. **이름 길이는 사용 빈도에 맞춘다.** 매일 쓰는 이름은 한 단어로 짧게, 거의 안 쓰는 이름은 길어도 정확하게(사용자: *"실제로 사용될 가능성이 적고, 충분히 자기서술적이여도
   상관 없는 부분"*). 흔한 단어를 드문 타입에 써서 소진하지 않는다(사용자: `Entry`는 *"작지만 네이밍을 소진시켜"*).
2. **자기서술적일 것** — 이름만으로 무엇이 들어가는지 읽혀야 한다(지금 `<Class>Elem`은 *"자기서술적이지 못했다"*).
3. **부품은 부모 이름을 앞에 붙여 묶는다**(메인 제안, 사용자 *"PropsHashPart 나쁘지 않게 보임"*) — 자동완성에서 모이고 흔한 단어를 안 쓴다.
4. **값과 타입이 같은 이름이면 같은 것을 가리킨다** — 값 `Modifier "Frame"`이 만드는 것의 타입이 `Modifier<Frame>`이듯.
5. (선택지) **사람이 주석에 쓰지 않는 부품은 아예 내보내지 않는다** — 이름 비용 0. 지금 킷 둘에서 0회인 타입들이 후보(2절 빈도).

## 2. 지금 이름의 실제 사용 빈도 (2026-10-16 메인 실측 — 생성 Declaration 파일 자체는 제외)

| 이름(지금) | material | devui | roblox 테스트 | 문서 |
|---|---|---|---|---|
| 값 `D.<C>`(생성자) | 787 | 229 | 36 | 106 |
| 값 `D.Modifier.<C>(…)` | 179 | 39 | 13 | 20 |
| 타입 `<C>Modifier` | 94 | 98 | 13 | 28 |
| 타입 `Into<C>`(컴포넌트가 Modifier를 prop으로 받을 때 — `read Modifier: q.IntoGuiObject?`) | 25 | 22 | 3 | 5 |
| 타입 `Field<T>`/`FieldOut<T>`(Modifier 필드 값·저장값) | 4 | 4 | 9 | 25 |
| 값 `:As<C>()`/`:Into()` | 8 | 0 | 11 | 7 |
| 타입 `<C>Elem` | 0 | 0 | 1 | 2 |
| 타입 `<C>Param` | 0 | 0 | 0 | 4 |
| 타입 `<C>RefMarker`·`<C>OnChange`·`<C>MapperElem` | 0 | 0 | 3 | 2 |
| 타입 `PropTypes`/`PropTypesRead`·`OnChangeDescriptor` | 0 | 0 | 3 | 21 |
| 값 `D.Mapper.<C>` | 0 | 0 | 3 | 1 |

주의: 공용 모듈(`D = { Frame = X "Frame", … }` — 같은 날 기본 권장은 파일별 꺼내 두기로 정해졌고 공용 모듈은 작을 때의 대안, `declaration-surface-plan.md` 5절)을 쓰면, **생성자 꺼내기 함수 X 자체는 클래스 수만큼 한 파일에만** 적히고, 매일 쓰이는 것은 사용자가 정한
`D.Frame`이다. Modifier도 같은 권장을 따르면(`D.FrameModifier = Modifier "Frame"` 꼴 — 사용자: *"Modifier 또한 적어놓고 쓰는게 권장되는 경로 아니냐"*) 꺼내기 함수 `Modifier`는 드물고
매일 쓰이는 것은 꺼낸 값과 타입 `Modifier<Frame>`이다.

## 3. 이름표 초안

### 3.1 값(런타임) — 백엔드 계약(quad-roblox가 런타임과 타입을 채움, base는 `notInstalled` 스텁)

| 축 | 지금 | 초안 | 층(근거) | 비고 |
|---|---|---|---|---|
| 요소 생성자 꺼내기 | `D.<C>` 값, `D.New(name)` | **`Elem "Frame"`** → 생성자 | 꺼내기 자체는 드묾(공용 모듈), 결과 생성자는 매일 | **토론 대상**(4절). 이름 탐색: sonnet `Class`, Gemini `New` — 사용자는 둘 다 기각(`Class`는 Luau RFC `class` 문·묶음처럼 보임, `New`는 즉시 생성으로 읽힘) |
| Modifier 꺼내기 | `D.Modifier.<C>(…)` | `Modifier "Frame"` → `(…) -> Modifier<Frame>` | 꺼내기는 드묾(꺼내 두기 권장 시), 결과 호출은 매일 | 값·타입 같은 이름(원칙 4) |
| 속성 묶음 | (없음, 새로) | `Spread "Frame" {…}` → `Spread<Frame>`(`:Append` — 2026-10-20 `:Add`에서 개명; 5절 — 마커는 입력 자리 전용) | 중간 예상 | 커리(두 인자 꼴은 실측상 틀린 꼴) |
| 기존 트리 매퍼 | `D.Mapper.<C>(key)(props)` | `Mapper "Frame" (key) {…}` | 드묾(킷 0) | |
| 프로퍼티 변화 | `q.OnChange(name, fn)` | 그대로 | 중간 | 무주석 콜백은 검사만 — **→ 5절 확정: 클래스 먼저 커리 `OnChange "Frame" "Visible" (fn)`** |
| 이벤트 | (없음, 새로) `q.OnEvent(name, fn)` 확정 | 그대로 | 중간 예상 | 커리 꼴만 콜백 인자에 문맥 타입이 흐름 — **→ 5절 확정: 클래스 먼저 커리 `OnEvent "Frame" "MouseEnter" (fn)`** |
| 되쓰기 | `q.Out(name, src)` | 그대로 | 드묾 | |
| base 원재료 | `q.Modifier`(통째)·`q.newMapperClass` | `q.Raw.Modifier`·`q.Raw.Spread`·`q.Raw.Mapper` | 드묾(킷 0, 백엔드·자기 Modifier 정의자만) | 사용자 결정 2026-10-16 |
| 매퍼 루트 | `q.MapperRoot`·`D.Mapper.Root` | 그대로(base `Claim`의 센티널) | 드묾 | |
| 모듈 사본 | `q.New()` | `q.NewModule()` | 드묾 | 사용자 동의 2026-10-16 |

### 3.2 타입 — 타입 함수 `Build<Mode, C, Policy>`가 만드는 것

| 축 | 지금 | 초안 | 층 | 비고 |
|---|---|---|---|---|
| Modifier 값 타입 | `<C>Modifier`(45벌) | **`Modifier<C>`** | 매일 | |
| Modifier로 바뀔 수 있는 것(컴포넌트 prop) | `Into<C>`(`IntoFrame` 등) | `Into<C>`? | 자주(킷 47) | 짧은 이름이 맞는 빈도. 다만 "무엇으로 into인가"가 이름에 없다 — `ModifierInto<C>`·`AsModifier<C>` 같은 서술형과 비교 필요 |
| props 테이블 전체 | `<C>Param<E>` | `Props<C>` | 가끔(Spread 팩토리 서명 등) | |
| props 배열 자리 원소 | `<C>Elem` | **`PropsArrayItem<C>`** | 드묾(킷 0) | 사용자 예시 `ArrItem`의 완어 + 부모 접두. `Entry`·`Content`·`Child`는 기각·탈락(아래 4절 끝) |
| props 해시 자리(필드 집합) | (`<C>Param` 안) | **`PropsHashPart<C>`** | 드묾 | 사용자 *"나쁘지 않게"*. 해시 쪽은 원소 유니언이 아니라 필드 집합이라 `Item` 대신 `Part` |
| 요소 생성자 타입 | (인라인 `(FrameParam<FrameElem>) -> Frame`) | `Elem<C>` = `(Props<C>) -> C`? | 가끔(생성자를 넘길 때) | **토론 대상**(4절) — 프로브 이름은 `Ctor<C>` |
| Spread 결과 | (없음) | `SpreadMarker<C>` | 가끔(팩토리 반환 주석) | 누적형이면 메소드가 붙음 — **→ 5절: `Spread<C>`**(마커는 입력 자리 전용) |
| Mapper props | `<C>Param<<C>MapperElem>` | `MapperProps<C>` | 드묾 | 배열 자리 원소가 필요하면 `MapperPropsArrayItem<C>` |
| Modifier 필드 값·저장값 | `Field<T>`·`FieldOut<T>` | `ModifierField<T>`·`ModifierFieldOut<T>`? | 가끔(킷 8 — 자기 Modifier 정의) | 드문 쪽이라 부모 접두가 원칙에 맞음 |
| 클래스별 Ref 마커 | `<C>RefMarker` | 내보내지 않음? | 드묾(킷 0) | 배열 자리 원소의 부품 |
| 클래스별 OnChange 유니언 | `<C>OnChange` | 내보내지 않음? | 드묾(킷 0) | 배열 자리 원소의 부품 |
| 이름→타입 맵(쓰기·읽기) | `PropTypes`·`PropTypesRead` | `PropTypes`·`PropTypesRead` 또는 `WritablePropTypes`·`ReadablePropTypes` | 드묾(문서 13) | OnChange·Out 서명의 부품 |
| 이벤트 맵·인자 | (없음) | 내보내지 않음? | 드묾 | OnEvent 서명의 부품 |
| 디스크립터 | `OnChangeDescriptor` | `OnChangeDescriptor`·`OnEventDescriptor` | 드묾(문서 8) | 짝 맞춤(프로브는 `EventDesc`) |
| 타입 함수·정책 데이터 | (없음 — 생성기) | `Build`·`Policy`·클래스맵 — 내보내지 않음 | — | 생성기가 데이터만 채움 |

## 4. 토론 — 값 쪽 생성자 꺼내기의 이름(`Elem`)

사용자: *"Elem 관해서는 토론을 붙여보는 쪽이 맞아보임. 지금을 유지할 근거도 팽팽하고, 굳이 그렇게 나올 필요가 없다는 점도 팽팽함."* 사용자가 낸 근거(본인이 *"주관적이므로 과신하진
말고, 근거가 되는지 봐야"*라고 단서):

- **일관성 근거(찬)**: Elem은 *생성자*다 — 실제 객체를 만드는 함수를 만드는 표면이므로 `type Elem<T> = Ctor<T>`이고 값은 `Elem "Frame": Elem<Frame>`일 수 있다. 이미
  `Modifier<T>` 타입과 `Modifier "" ()` 생성 경로가 그 모양이다(원칙 4).
- **차이(단서)**: 다만 Elem은 *커링 함수의 결과가 생성자*이고, Modifier는 *생성자가 커링된 것*으로 볼 수 있다 — `Elem "Frame"`의 결과는 props를 받아 Frame을 만드는 생성자,
  `Modifier "Frame"`의 결과는 인자를 받아 Modifier 값을 만드는 팩토리. 둘 다 "이름 → (인자 → 값)"이지만 `Elem<Frame>` 타입이 생성자(함수)를, `Modifier<Frame>` 타입이 값을 가리킨다.
- **반대 근거(빈도)**: 꺼내 두기를 권장하면(파일별이든 공용 모듈이든) 꺼내기 함수는 파일 머리에만 적히니 짧을 필요가 없다(원칙 1) — 서술형 이름이어도 된다. 이 근거는 Modifier에도 똑같이 적용된다(2절 끝).

**배열 자리 타입 이름 탐색에서 기각·탈락한 것**(같은 날): `Entry`(sonnet 1순위 — 사용자: Ref·PreRef까지 들어가는데 흔한 단어를 소진, `SlotEntry` 짝도 *"그닥"*), `Content`
(Gemini 1순위 — Roblox 정의에 `declare extern type Content`·전역 `Content`가 있음, 메인 확인), `Child`·`ChildrenOf`(Modifier·디스크립터를 가림, 복수형은 `{ … }` 자리에서 이중 복수).
`SlotElement<T>`는 그대로 둔다(사용자: Elem은 *"결정적으로 하나를 의미"* — 유니언이어도).

## 5. 결정 [2026-10-16 — 사용자, 검토 뒤]

검토는 `audit/naming-table-review-2026-10-16/`(Gemini 체계 검토 + sonnet 찬반 토론). 사용자: *"동의. ElemCtor 도 맞아보임. Into 도 ModifierInto 로 두는거 동의. modifierField 도 동의 … 다른 부분도 동의"*.
- **값 `Elem "Frame"`은 그대로, 생성자 타입은 `ElemCtor<C>`**(타입 `Elem<C>`는 만들지 않는다). 토론이 "값·타입 이름을 갈라도 되나"로 좁혀졌고, 원칙 4를 "이름은 최종 산물을 가리킨다"로 읽으면
  `Elem "Frame"`의 산물은 `Frame`이라 `Elem<…>` 타입이 없어야 깨지지 않는다(Modifier도 이 읽기 — `Modifier "Frame"`의 산물이 `Modifier<Frame>`). 생성자 타입은 드물어 길어도 된다(원칙 1).
- **`Into<C>` → `ModifierInto<C>`**(무엇으로 into인지 + 부모 접두). **[2026-10-20]** 뜻은 "C에 들어갈 수 있는 Modifier" 마커로 바뀐다(인터페이스 아님) — `research/declaration-surface-plan.md` 5절 끝 문단.
- **`SpreadMarker<C>` → `Spread<C>`**(`:Add`(2026-10-20 `:Append`로 개명)가 붙은 값은 전체형, 요소 자리에서 받는 쪽만 마커 — quad-types의 마커 정의 "입력받는 자리 전용, 메소드가 필요한 자리는 전체형",
  `State`/`StateMarker`·`Modifier`/`ModifierMarker`와 같은 짝; `Spread "Frame" {…}: Spread<Frame>`).
- **`Field<T>`·`FieldOut<T>` → `ModifierField<T>`·`ModifierFieldOut<T>`.** 변형 열(`FieldP`·`FieldN`·`FieldPN`·`FieldV`·`FieldPV`·`FieldNV`·`FieldPNV`·`FieldOutP` — 보간 가능 여부·nil 수용
  조합)은 **지금은 내보내지 않는다** — 사용자: *"바리에이션에 대해서는 좀 더 논의해보고. 지금은 내지 않고, 정해지는게 생기면 낼 지 보는정도로"*.
- **이름→타입 맵은 `PropertyMap` 계열**(`EventMap`과 짝 — 읽기 쪽 이름은 미정), 나머지 표 행(`Props<C>`·`PropsArrayItem<C>`·`PropsHashPart<C>`·`MapperProps<C>`·`OnEventDescriptor`·
  부품 비노출)도 동의.
- **표에 빠졌던 축**(Gemini 발견, 메인 확인 — 이름은 다음 개정에서; **[2026-10-20]** 공용 모듈 레코드는 D와 함께 삭제, 서명 타입·읽기 쪽 맵은 비노출, 매퍼 루트는 값·타입 짝, 탈출구는 사용자 클래스 맵 함수 `q.ForClasses<<Map>>()` 하나 — `research/declaration-surface-plan.md` 5절 끝): 공용 모듈 레코드 타입(`Declaration`·`DeclarationMapper`·`DeclarationModifier`), 서명 타입 `OnChangeFn`·`OutFn`(·`OnEventFn`),
  31 클래스 밖 동적 탈출구(지금 `D.New(name)`, 프로브 `NewLoose`), 매퍼 루트 센티널 타입.
- **OnEvent·OnChange 커리** — 사용자: *"커리 꼴이 되면 타이핑 문제에 해결이 보일것 같다 … 오버라이딩으로 선택될 수 있는지 보는게 필요"*. 실측(`audit/decl-typefn-probe-2026-10-16/REPORT.md`
  끝 절): 클래스 먼저 커리 `OnEvent "Frame" "MouseEnter" (fn)`는 제네릭·오버로드 둘 다 콜백에 문맥 타입이 흐르나 **오버로드는 이름 자동완성을 잃는다** — 확정 여부는 사용자 몫.
- **[확정] OnEvent·OnChange는 클래스 먼저 커리 `OnEvent "Frame" "MouseEnter" (fn)`·`OnChange "Frame" "Visible" (fn)`, 둘째 호출은 제네릭(`K & keyof<…>` + `index<>`)** — 사용자:
  *"모양 자체는 커링으로 같기에. breaking 자체는 없을것임. 지금 가장 안정적인 방법인 그것으로 가자"*. 즉 둘째 호출의 타이핑 방식(제네릭↔오버로드)은 모양이 같아 나중에 바꿔도
  호환이 안 깨지고, 지금은 이름 자동완성까지 사는 제네릭으로 간다. 읽기 표면(ReadOnly 포함) 정책 데이터는 구현 때.
