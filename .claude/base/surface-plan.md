# 클래스 먼저 표면 — `q.Elem`·`Modifier`·`Spread`·`Mapper`·`OnChange`·`OnEvent`·`Out`·`ForClasses` (3.4.0)

> **[2026-10-20 신설 — research에서 승격]** 3.3까지의 생성 `Declaration`(`D.Frame {…}`, 생성 파일 `quad-roblox/src/Declaration/`)을
> 대체한 공개 표면의 확정 설계. 결정의 논쟁 원문과 날짜별 사용자 인용은 그대로 research 문서에 있다 — 표면·원천은
> `research/declaration-surface-plan.md` 5절, 이름은 `research/declaration-naming-table.md` 5절, Spread는
> `research/component-flatten-sugar-plan.md` 5절, 실측은 `audit/decl-typefn-probe-2026-10-16/REPORT.md`. 실행 경과는
> `research/release-3.4.0-plan.md`(단위 0~8)와 `session/2026-10-20-01-spread-add-crud.md`. 사용자 문서 정본은
> `docs/reference/roblox/02-elem.md`·`03-modifier-spread.md`·`04-claim-mapper.md`·`05-onchange.md`.
> 이 문서는 **지금 유효한 결정과 그 이유 한 줄**만 쥔다.

## 1. 모양

- **클래스를 먼저 받는 커리.** `q.Elem "Frame" {…}`, `q.Modifier "Frame" (…)`, `q.Spread "Frame" {…}`,
  `q.Mapper "Frame" (key) {…}`, `q.OnChange "Frame" "Size" (fn)`, `q.OnEvent "Frame" "MouseEnter" (fn)`,
  `q.Out "TextBox" "Text" (src)`. 첫 단계는 런타임에서 **문자열만** 본다(`Quad0278`) — 없는 클래스는 타입이 먼저, 런타임에선
  엔진이 그 클래스를 만나는 자리에서 잡는다(사용자 2026-10-20: 안 맞는 이름이 확실히 에러가 나면 됨). 디스크립터 셋은 클래스
  단계에 인자 둘 이상이면 `Quad0281`(3.3 `q.OnChange("Text", fn)` 꼴이 조용히 단계 함수가 되던 것).
- **꺼내 두기가 기본 권장**(`local Frame = q.Elem "Frame"`) — 생성자 함수 타입을 통째 타입 함수로 만들어 꺼내 두는 자리에서
  한 번 줄게 했다(단위 0 실측: 호출마다 줄지 않으면 약 2300줄에서 `LuauSolverConstraintLimit=1500`에 닿음, 통째로는 5730줄 깨끗).
  디스크립터는 한 모듈 약 1200개가 문턱.
- **클래스 맵 둘**: `Elem`·`Mapper`는 만들 수 있는 클래스(31), `Modifier`·`Spread`·디스크립터 클래스 단계는 추상 조상 포함(47).
  GUI 중심 유지(M4 — 큰 바운드는 override 없는 설정에서 too complex).
- **탈출구 `q.ForClasses<<Map>>()`** — 사용자 클래스 맵으로 같은 일곱을 돌려준다. 내장 맵과 합치지 않는다, 맵은 검사하지 않는다,
  100개 아래·분야별 권장. 타입 없는 탈출구(옛 `D.New(name)`의 any props)는 두지 않는다.
- **base 원재료 `q.Raw`** — `Raw.Modifier`(옛 `q.Modifier` 묶음 — `Overridden`·`TypedFactory`·`DefineSubtype`), `Raw.Spread`,
  `Raw.Mapper`(옛 `newMapperClass`). `q.New` → `q.NewModule`.
- **최상위 백엔드 이름 여덟은 base가 정한다** — `quad-base/src/BackendStubs.luau`가 `Elem`·`Modifier`·`Spread`·`Mapper`·
  `OnChange`·`OnEvent`·`Out`·`ForClasses`에 `Quad0108` 스텁을 깔고 프로바이더가 덮어쓴다(round15 `H-929`). `Backend.*` op 스텁의
  이 표 이전은 미룸.

## 2. 타입 — 원천은 사용자의 검사기

- **타입 함수가 검사기의 클래스 타입을 읽어 표면을 만든다**(`quad-roblox/src/Surface/init.luau` — `Build(mode, class, policy)` 하나에
  모드 여럿). 덤프는 체커가 갖지 않는 것만 채우는 **정책 데이터**로 남는다(`quad-roblox/src/Surface/Data.luau`, `scripts/gen-d.py emit`
  — 클래스 맵 둘, 정의 클래스 기준 DenyIn·DenyWriteIn, 되살린 레거시 Inject, 숏핸드, 런타임 `Superclass` 표).
- **체커 차이는 흡수하지 않고 문서화한다**(사용자 2026-10-19: `p: Part`도 체커마다 다른 것 — 사용자가 인지할 부분). 예: 레포 핀 defs엔
  `UIShadow.ShowBehindParent`가 없다(material `Elevation.luau`가 생성 뒤 `:: any`로 씀).
- **위험 하나**: 타입 함수엔 pcall이 없어 멤버 하나가 `parameters()`에서 죽으면 그 클래스 표면 전체가 `never`. 그런 멤버는
  `gen-d.py`에서 Deny하고, 게이트 `scripts/surface-gate.py`가 레포 핀 defs로 모든 클래스 표면이 비지 않는지와 음성 고정물
  (`quad-roblox/test/surface/cases.luau`)을 본다.
- **공개 타입 이름**(quad-roblox 루트): `Props<C>`·`PropsHashPart<C>`·`PropsArrayItem<C>`·`MapperProps<C>`·`ElemCtor<C>`·
  `PropertyMap<C>`·`Modifier<C>`·`ModifierInto<C>`·`Spread<C>`·`SpreadInto<C>`·`OnChangeDescriptor<K>`·`OnEventDescriptor<K>`·
  `ModifierField<T>`·`ModifierFieldOut<T>`, 값 층(`Tween<T>` 등), `RobloxExtension`. 비노출: 읽기 쪽 프로퍼티 맵(체커의
  `index<C, "Name">`이 그 자리), `OnChangeFn`·`OutFn`·`OnEventFn`(오해를 부르는 이름 — 필요하면 `typeof(q.OnChange)`), `NewChild`,
  `Field*` 변형 열, 클래스별 복제 이름(`FrameModifier`·`IntoFrame`·`FrameElem` — 이전 기간 없이 삭제, 사용자 2026-10-16).
- **입력 자리는 마커**: `ModifierInto<C>` = `{ read __quadModifier: "C" | <조상 이름들> }`(메소드 없음), `SpreadInto<C>` 같은 꼴.
  quad-types의 "입력 자리 전용은 마커, 메소드가 필요한 자리는 전체형" 규칙. 이것으로 `base/modifier-plan.md` 11절의 Rust식 `Into`
  인터페이스(As 메소드를 구현한 값이면 받음)는 물러났다 — 커스텀 클래스 Modifier는 넘기는 쪽이 `:AsX()`로 내려서 넘긴다.
- **읽기 표면**(OnChange·Out 이름): ReadOnly 포함, Instance 계열 extern 프로퍼티는 `T?`(Q127 (a)). 이름의 타입은 클래스가 정한다
  (3.3 스코프 전체 맵의 충돌 이름 여섯 `any`와 `q.Out` 거짓 양성이 같이 풀림).
- **Modifier 변환 함수 `old`·`Peek`의 State·Tween 팔은 읽기 뷰**(`StateView<X> = { Get }`, `TweenView<T> = { Value }` —
  `quad-roblox/src/types.luau`). 타입 함수 안에 전체 `QuadTypes.State<T>`를 넣으면 `*error-type*`(2026-10-20 실측). round3 Q23 (a)의
  "저장된 그대로 전체형"에서 한 걸음 물러난 것 — 사용자 보고 항목(`typing-limits.md` 8.39).
- **한도 플래그**: 새 솔버는 필수, 한도 셋은 권장 — 기본 한도에서 무너지는 확인된 자리는 조상 클래스 `Modifier<C>` 주석 비교 하나
  (`typing-limits.md` 8.40).

## 3. Spread

- 요소 테이블과 같은 모양의 **일회용·가변 조각**. 숫자 키 자리에 놓이면 펴진다(`Dispatch/Spread.luau`의 `expand` — `drive`의
  첫 선처리, Modifier `flatten` 앞).
- **깊이 1, 먼저 자리 잡은 것이 이긴다**(생성자·`:Append`·요소에 놓기가 한 동작 — "이미 있으면 건너뛰고 배열은 뒤에").
  우선순위: 인라인 문자 키 > 앞 Spread > 뒤 Spread > Modifier(뒤가 이김). JS 펼치기와 반대인 이유: Luau 테이블 생성자는 인라인 키와
  배열 값 사이의 순서를 남기지 않는다(사용자 근거 원문은 research 5절 끝).
- **`:Append(other)`** — Spread만 받고(`SpreadInto<C>`) 아무것도 돌려주지 않는다. 요소에 놓이거나 다른 Spread에 펴지면 잠긴다
  (`Quad0275`). 읽기·지우기 없음(필요가 보이면 순수 추가).
- **문자 키 함수 값은 막지 않는다** — `q.debug`일 때 앞선 Spread에 밀려난 함수만 알린다. 여러 핸들러가 필요한 이벤트는 배열부
  `q.OnEvent` 디스크립터(문자 키 이벤트는 손으로 쓸 때의 "한 칸"으로 남음).
- 에러: `Quad0273`(평범한 테이블 아님)·`Quad0274`(Spread를 키 값으로 — 생성)·`Quad0277`(같은 것 — drive)·`Quad0276`(`:Append`에
  Spread 아닌 값).
- 키트 안쪽 요소 자리는 `FieldModifier`/`TrackModifier` 옆에 `FieldSpread`/`TrackSpread`(마커 `SpreadInto<C>`). `Split`과의 관계는
  보류(research 5절).

## 4. 런타임 배치

- quad-base: `BackendStubs.luau`, `Dispatch/Spread.luau`, `Brand.luau`의 내부 `SpreadBrand`(공개 `q.isSpread` 없음), `Claim.luau`가
  `Raw.Mapper`를 심음.
- quad-roblox: `Surface/Runtime.luau`(공개 단계는 태그된 테이블 필드 함수 — 태그 없는 본체만 부른다: 태그된 함수끼리 부르면 blame이
  quad 줄로 간다), `Handlers/OnEvent.luau`(우선순위 NORMAL-2, `{ Event, Callback }` 디스크립터, 철거 때 Disconnect),
  `Handlers/OnChange.luau`의 `makeOnChange`/`makeOut`, `RobloxFactory.luau`가 표면을 돌려줌, `As` 간선은 설치 때 `Data.Superclass`
  전부 등록(만들 수 있는 모든 클래스 사슬 — ForClasses의 `BasePart → Part` 포함).
- 옮기기: `scripts/migrate-3.4.py`(제자리, `--check`·`--report`, 다시 돌려도 무변화, 못 정한 자리·캐스트 경유 D는 목록).
