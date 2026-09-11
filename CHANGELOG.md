# Changelog

이 파일은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 형식을 따르고, 버전은 [SemVer](https://semver.org/lang/ko/)입니다.
소비자가 겪는 변화만 적습니다 — 항목은 **Added / Changed / Deprecated / Removed / Fixed** 다섯으로 나누고, 호환이 깨지는 항목은 앞에 **BREAKING**을 붙이고 옮기는 법을 한 줄로 답니다. 내부 원장 번호는 쓰지 않습니다.
공개 표면이나 동작을 바꾸는 변경은 그 커밋에서 `[Unreleased]`에 한 줄을 넣고, 릴리즈 때 `scripts/check-version.py bump <version>`이 그 절을 버전 헤딩으로 자릅니다.

## [Unreleased]

### Changed

- `slot:Single`의 타입이 `:List`와 같은 `<Item, UD>`가 됐습니다 — 구동 `state`가 데이터(`Item`)라 원소 타입에 묶이지 않습니다. `Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 코드가 이제 strict를 통과합니다(런타임 변화 없음).
- **BREAKING — `q.Operator.Index`가 `q.Operator.Indexed`로 이름이 바뀌었습니다.** 동작·시그니처는 그대로(`state:Apply(q.Operator.Indexed<<V>>("Key"))`, `V`는 인덱스된 값의 타입) — 호출부의 이름만 바꾸면 됩니다. 픽 함수를 직접 받는 일반형(`Indexer`)은 타입 추론이 가능해지면 따로 추가할 예정이라 이름을 미리 갈라 두었습니다.
- 숫자 키 자리 중간에 `nil`이 있을 때 나는 에러 문구가 먼저 그 가능성을 묻습니다 — `Dispatch.recompute: sourceList[N] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; …`(뒤는 핸들러 작성자용 힌트 그대로). 동작 변화 없음.

### Fixed

- `type_version_check`의 `CheckVersion` type function에서 `pcall`을 없앴습니다. luau-lsp(신 솔버)가 `Unknown global 'pcall'` 진단을 내던 것이 사라집니다. 값 여부는 `tag == "singleton"`으로 봅니다(판정 규칙은 그대로).

## [3.0.0] - 2026-09-10

**BREAKING — 처음부터 다시 쓴 별개 라이브러리입니다.** 3.x는 quad v1과 API 호환이 없고, 패키지 이름과 설치 경로도 다릅니다. 아래 목록은 v1의 마지막 릴리즈인 **2.24를 기준으로** 무엇이 생기고, 바뀌고, 없어졌는지입니다. 옮기는 절차는 [quad v1에서 v2로 옮기기](./docs/how-to/08-migrating-from-v1.md), 없앤 이유는 [quad v1에서 오는 분께](./docs/overview/02-from-v1.md)에 있습니다. v1은 `master` 브랜치와 GitHub 릴리즈(rbxmx)에 그대로 남습니다.

### Added

- 패키지 다섯 — `qwreey/quad_base`(엔진에 묶이지 않은 코어), `qwreey/quad_roblox`(Roblox 백엔드), `qwreey/quad_types`(구현 없는 공개 타입 계약), `qwreey/quad_error`(호출한 줄을 가리키는 에러 유틸), `qwreey/type_version_check`(버전 패턴을 타입 수준과 런타임에서 검사하는 유틸).
- 모듈 — `require`가 돌려주는 기본 인스턴스, 격리된 인스턴스를 만드는 `Quad.New()`, 백엔드를 설치하는 `q:UseProvider()`, `q:AddPlugin()`, `q:RunInit()`, `q.Version`, `q.debug`, 약한 관계 테이블을 만드는 `q.Relate()`.
- 반응형 코어 — `q.Source`(`:Set`/`:Emit`), `State`(`:Get`/`:Compute`/`:With`/`:Apply`/`:Gate`/`:Observer`), 필드로 `Source`를 선언하는 `q.Store`(`:Of`/`:Names`).
- 구독 핸들 — `Observer`와 `q.Effect`. 강한 구독과 약한 구독(`:Subscribe`/`:WeakSubscribe`/`:Unsubscribe`/`:WeakUnsubscribe`), `effect:Rerun()`.
- 전파 게이트 — `q.Blocker`(`:On`/`:Off`/`:OffWithoutEmit`/`:Policy`).
- `q.Slot` — 자식 목록을 소유하는 값. 편집(`:Add`/`:Remove`/`:Replace`/`:Extract`/`:ExtractAll`/`:Splice`/`:Clear`/`:Move`/`:Swap`/`:Get`/`:IndexOf`)과 데이터 바인딩(키로 인스턴스를 재활용하는 `:List`, 값 하나를 따르는 `:Single`).
- `q.Ref` / `q.PreRef` / `q.PostRef` — 인스턴스 참조를 그 자리에서 받는 값(`:Set`/`:Callback`/`:WeakCallback`/`:Uncallback`/`:Wait`/`:Unwrap`).
- `q.Modifier` — props의 숫자 키 자리에 놓는 불변 스타일 값(`:Apply`/`:Overridden`/`:As`/`:Peek`, `q.Modifier.TypedFactory`/`DefineSubtype`). Roblox 클래스별로 `D.Modifier.<Class>`.
- `q.Tag`와 `q.Attr` — 태그와 어트리뷰트를 선언적으로 붙이는 값(`q.Tag.Merged`, `q.AttrKey`, `q.StringAttr`/`NumberAttr`/`BooleanAttr`, `q.Attr.Merged`/`Overridden`).
- 센티널과 수명 도구 — `q.None`/`q.Detach`/`q.KeyGone`/`q.Void`, `q.dispose()`, `q.bindLifetime()`/`q.unbindLifetime()`, 값의 종류를 판별하는 `q.is*` 술어.
- 슈거 — `q.Context`(`q.Context.Provider`), `q.Operator`(`Not`/`Sum`/`Product`/`Min`/`Max`/`Clamp`/비트 연산/`Alternative`/`Index`), `q.Debounce`/`q.Throttle`, 생명주기 훅 `q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`, 에러 격리 `q.Fallback`/`q.Traceback`.
- Roblox 백엔드 — 클래스마다 프로퍼티 타입이 붙은 `D.<Class>`와 `D.New()`, 프로퍼티 변화를 받는 `q.OnChange(name, fn)`.
- 선언형 애니메이션 — 프로퍼티 자리에 값으로 놓는 `q.Tween{}`(`:Mapped`)과, `state:Apply(q.Animate{...})`로 상태에 붙이는 `q.Animate{}`. 겹칠 때의 처리는 `Override = "Cancel" | "Finish"`.
- `q.Claim(inst, D.Mapper.<Class>(...))` — Studio에서 만든 기존 트리를 quad 소유로 넘겨받습니다(인스턴스당 한 번).
- 확장 계약 — 백엔드 프로바이더 규약, `q.Dispatch`(핸들러 등록·우선순위 밴드), 백엔드와 플러그인이 함께 쓰는 에러 네임스페이스 `q.errorNamespace`. 라이브러리를 고치지 않고 props의 특수 키를 추가할 수 있습니다.

### Changed

아래는 이름의 대응입니다. 콜백 인자, 발화 시점, 우선순위 같은 동작 차이는 [quad v1에서 v2로 옮기기](./docs/how-to/08-migrating-from-v1.md)가 다룹니다.

- 설치 — rbxmx 모델 내려받기·레포 클론·git submodule에서 pesde 패키지로. Roblox 프로젝트에는 `roblox_packages/` 한 곳에 설치됩니다.
- 타입 검사 — luau 플래그 넷(`LuauSolverV2`, `LuauTarjanChildLimit`, `LuauSubtypingIterationLimit`, `LuauTypeInferIterationLimit`)을 켠 luau-lsp 환경이 필요합니다. 플래그 없이는 quad 소스의 타입 검사가 실패합니다.
- 진입 — `require(quad).Init(id)` → `Quad:UseProvider(QuadRoblox)`. 같은 id로 같은 인스턴스를 다시 얻는 공유는 없고, 공유는 모듈 export나 `q.Context`로 합니다.
- 인스턴스 생성 — `Class "Frame" {...}` → `D.Frame {...}`.
- 이벤트 — `[Event "Activated"] = fn(self, ...)` → 문자 키 `Activated = fn(...)`(`self` 없음). `[Event.Prop "Text"] = fn` → 숫자 키 자리의 `q.OnChange("Text", fn)`.
- 부모 지정 — `Mount(parent, obj)` → `obj.Parent = parent`. `mounts:Add()`/`:Unmount()` → `q.Slot`.
- 스토어 — `Store.GetStore("name")` → `q.Store { key = q.Source(v) }`(이름으로 찾지 않음). `myStore "color"` → `store.color`.
- 파생 — `register:With(fn)` → `state:Compute(fn, ...deps)`, `:Add(v)` → `:Apply(q.Operator.Sum(v))`, `:Default(v)` → `:Apply(q.Operator.Alternative(v))`. 3.x의 `state:With()`는 이름만 같은 다른 API입니다.
- 애니메이션 — `register:Tween{...}` → `state:Apply(q.Animate{...})`.
- 관측 — `register:Register(fn)` → `state:Observer(fn)`.
- 생명주기 훅 — `[Event.Created]` → `q.OnCreated(fn)`, `Class.Extend`의 `:AfterRender()` → `q.OnRendered(fn)`, `:Unload()` → `q.OnDestroyed(fn)`.
- 스타일 — `Style {...}` → 숫자 키 자리의 `D.Modifier.<Class> {...}`.
- 숏핸드 키 — `Corner` → `UICorner`, `PaddingAll` → `UIPadding`, `PaddingAllOffset` → `UIPaddingOffset`, `Scale` → `UIScale`.
- 컴포넌트 — `Class.Extend()` + `:Render()` → 평범한 함수. `self "_name"` 링커 → `q.PreRef()` + `ref:Unwrap()`.
- 정리 — props로 건 구독과 트윈은 인스턴스 수명에 묶여 인스턴스와 함께 멈춥니다(직접 `:Subscribe()`한 구독은 따로 해제해야 합니다). quad가 만든 인스턴스는 참조를 놓는 것만으로는 회수되지 않고 `Destroy()`로만 회수됩니다.
- 에러 — 메시지가 `주어: 이유` 모양으로 통일되고(받은 값을 말할 때는 `(got X)`가 붙습니다), 대부분 라이브러리 안쪽이 아니라 그걸 부른 사용자 코드의 줄을 가리킵니다.

### Removed

- id로 인스턴스를 찾는 전역 조회 — `Frame "id" {...}`, `Store.GetObject`/`GetObjects`/`AddObject`.
- id 문자열로 대상을 고르는 스타일 — `Style "Child" {}`(`Frame "..."`에 준 id에 스타일 이름을 패턴으로 맞추던 방식).
- `Class.Extend`의 `Getter`/`Setter`/`UpdateTriggers`/`:Update()`와 `:GetPropertyChangedSignal()`/`:EmitPropertyChangedSignal()`.
- 코루틴 안에서 도는 비차단 생성 훅 `[Event.CreatedAsync]`.
- register 체이닝 — `:With` → `:Add` → `:Tween`처럼 이어 붙이는 누적.
- 명령형 트윈 API — `Tween.RunTween`/`RunTweens`/`StopTween`/`IsTweening`, `Tween.Easings`와 함수 이징, `CallBack`/`OnStepped`/`Ended` 콜백, 인스턴스가 아닌 테이블(컴포넌트의 `self` 등)을 트윈하는 것. 선언형 `q.Tween`/`q.Animate`가 그 자리입니다.
- `Signal.Bindable` / `Disconnecter`.
- `Quad.Lang`.
- `Quad.Round`.
- 핫리로드 모듈 `tracker` — 튜토리얼이 `require(Quad.tracker)`로 안내하던 자동 리로드입니다.
- 이미지용 숏핸드 키 `RoundSize`.


---

## 2.x (quad v1)

아래는 v1(2.x)의 변경 이력입니다. **원래 목록은 손으로 쓴 한두 줄짜리 메모였습니다** — `master` 브랜치의 `md/kr/changelogs.md`에 그 원문이 그대로 남아 있습니다. 그것만으로는 무엇이 어떻게 바뀌었는지 알 수 없어서, Git 히스토리를 되짚어 각 번호에 해당하는 커밋을 찾고 실제 diff를 근거로 다시 썼습니다. 세 가지만 짚습니다.

1. **이 목록에 없는 번호(2.10, 2.16)는 배포 뒤 결함이 발견되어 회수한 릴리즈입니다.** 사용을 막기 위해 번호째 지웠습니다 — Git에도 그 번호에 해당하는 커밋이나 태그가 없어서 무엇이 담겨 있었는지는 복원할 수 없습니다.
2. **2.25는 배포되지 않았습니다.** 소스와 이 목록에만 남았고 릴리즈 태그도 rbxmx 배포도 없습니다. 마지막 릴리즈는 2.24이고, `master`의 태그도 그 하나뿐입니다.
3. **번호 순서와 날짜 순서가 맞지 않습니다.** 이 목록은 개발이 끝난 뒤 한꺼번에 번호를 붙여 쓴 것이라 번호가 개발 순서를 뜻하지 않습니다 — 2.9·2.12·2.18~2.22는 2023-02-21 한 커밋(`0689ad8`)에 함께 들어 있고, 2.17은 2.7과 같은 날(2023-02-16) 가장 먼저 커밋됐습니다. 소스의 버전 상수도 여섯 값(`1.14`·`2.14`·`2.18`·`2.22`·`2.24`·`2.25`)만 거쳐서, 대부분의 번호는 상수로 존재한 적조차 없습니다.
   그래서 헤딩의 앵커는 버전을 올린 커밋이 아니라 **그 변경이 실제로 들어간 커밋**입니다. 한 번호가 여러 커밋에 걸쳐 있으면 오래된 것부터 나란히 적었고, 해시는 모두 `master` 브랜치, 날짜는 작성일(KST)입니다.

### 2.25 - 2023-02-23 (`dd980aa`)

실험적 API입니다. 이 번호는 배포되지 않았습니다.

- **Added** — `Class.Extend` 인스턴스에 `GetChildren()`이 생겼습니다. 그 인스턴스에 마운트된 자식들을 새 배열에 담아 돌려줍니다(내부 `__child` 자체가 아니라 사본이고, 자식이 없으면 빈 배열). 인자는 받지 않습니다.
- **Added** — `Class.Extend` 인스턴스에 `ChildAdded` 필드가 생겼습니다. `Signal`의 Bindable이고, 그 인스턴스에 자식이 마운트될 때마다 **추가된 자식 하나**를 인자로 발행합니다.

### 2.24 - 2023-02-22 (`16cf39d`, `80242eb`, `9a8e39a`)

v1의 마지막 공식 릴리즈입니다. 태그 `2.24`는 문서 손질 커밋 `81d981d`를 가리킵니다.

- **Added** — 거의 비어 있던 튜토리얼 9~11장(Lang·Signal·Extend)을 채워 한국어 튜토리얼을 완성했습니다.
- **Added** — 레퍼런스 문서를 새로 썼습니다. `Signal`(Bindable·Disconnecter), `Store`(ObjectList), `Tween`(TweenOptions·Easings·Directions), 그리고 Event·Extend·Lang·Mounts·QuadProperty 항목입니다.
- **Added** — 빌드된 Mkdocs 정적 사이트를 레포에 함께 커밋했습니다.

### 2.23 - 2023-02-21~22 (`5c646f7`, `80242eb`)

- **Fixed** — 객체를 만들 때 나던 오류를 고쳤습니다. 클래스 내부가 자식을 마운트할 때 반환 형태가 바뀐 `Mount` 대신 `MountOne`을 쓰도록 바로잡았습니다.
- **Fixed** — `Extend` 객체의 자식이 Unmount되면 이제 부모의 `__child` 목록에서도 빠집니다. 전에는 목록에 그대로 남아서 `Extend`가 이미 사라진 자식을 계속 쥐고 있었습니다.
- **Fixed** — `types`의 오타 두 개. `TweenGetter`에 반환 타입이 비어 있던 것을 `any`로, `Easing` 목록에서 빠져 있던 `"Back"`을 채웠습니다.

### 2.22 - 2023-02-21 (`0689ad8`, `04916eb`)

- **Fixed** — `Event.Prop`으로 건 리스너가 인스턴스를 만드는 도중에 한 번 실행되던 문제를 고쳤습니다. 이제 프로퍼티와 자식을 다 세운 뒤에 모아둔 바인딩을 한꺼번에 연결하므로, 리스너는 인스턴스가 완성된 다음부터 불립니다. (`0689ad8`에 인자를 빠뜨린 버그가 있어서 실제로 동작하기 시작한 것은 `04916eb`입니다.)

### 2.21 - 2023-02-21 (`0689ad8`)

- **Changed** — `Linker`를 클래스 안의 클래스에서도 쓸 수 있습니다. 중첩 생성 경로가 props에 섞인 `Linker`를 따로 모아 두고 인스턴스가 만들어진 뒤에 연결하므로, 바깥 클래스뿐 아니라 안쪽 클래스의 자식·프로퍼티에도 걸 수 있습니다.

### 2.20 - 2023-02-21 (`0689ad8`)

- **Added** — 한국어 튜토리얼이 `import`부터 `extend`까지 11장 구성으로 자리를 잡았습니다. 다만 9~11장은 아직 거의 비어 있었고 채워진 것은 2.24입니다. Mkdocs Material 테마와 검색 설정도 들어갔습니다.
- **Added** — `Makefile`이 생겨서 `rojo build`(rbxmx 모델 번들)와 `mkdocs build`/`serve`를 명령 하나로 돌립니다.

### 2.19 - 2023-02-21 (`0689ad8`)

- **Added** — 링커가 생겼습니다. `Class.Extend` 인스턴스를 `self "name"`처럼 문자열로 호출하면 링커가 만들어지고, 그것을 props 자리에 놓으면 마운트할 때 그 인스턴스와 이어줍니다. 자식 자리(숫자 키)에 놓으면 만들어진 자식 인스턴스를 `self`의 `name` 키에 꽂아 주고(그래서 `self`에 자식 참조를 받아둘 수 있습니다), 이벤트 자리(문자 키)에 놓으면 그 이벤트를 `self:GetPropertyChangedSignal(name)`으로 흘려보냅니다.

### 2.18 - 2023-02-21 (`0689ad8`)

- **Fixed** — `Store`에 넣은 Instance가 가비지 컬렉터에 수거되어 목록에서 사라지던 문제를 고쳤습니다. `AddObject`가 인스턴스를 붙잡는 더미 시그널 연결을 함께 걸어 둡니다.

### 2.17 - 2023-02-16 (`9f2872e`)

- **BREAKING** — Tween `CallBack`에 등록한 함수가 받는 인자가 바뀌었습니다. 와일드카드 `*`는 `(Index, Alpha, Item)`에서 `(Item, Index, Alpha)`로, 수치 인덱스는 `(Alpha, Item)`에서 `(Alpha, Index, Item)`로 갑니다. 두 형태 모두 순서가 달라졌으니 기존 콜백은 매개변수 순서를 고쳐야 합니다.
- **BREAKING** — `~` 문법이 없어졌습니다. `CallBack["~0.5"]`처럼 알파 기준으로 호출 시점을 적던 키는 더 이상 해석되지 않고 수치 인덱스(`CallBack[0.5]`)만 남습니다. 두 기준은 값이 다르므로 숫자를 그대로 옮기면 시점이 어긋납니다 — 수치 인덱스는 선형 시간 진행률과 비교하고, 없어진 `~` 키는 거기에 이징을 적용한 값과 비교했습니다. 옮기려면 쓰던 이징 함수를 역으로 풀어 같은 시점의 진행률을 구해야 하고, `Linear`면 두 값이 같아서 숫자를 그대로 써도 됩니다.

### 2.15 - 2023-02-17~18 (`11c3268`, `723d3f9`)

- **BREAKING** — `Lang`의 필드 이름이 바뀌었습니다. `Lang.Lang` → `Lang.CurrentLocale`, `Lang.Default` → `Lang.Locales.Default`이니, 옛 이름을 읽거나 쓰던 자리를 전부 새 이름으로 고쳐야 합니다. 폴백도 성격이 바뀌어서, 2.14까지 영어로 떨어졌던 것이 이제 전용 키인 `Locales.Default`로 떨어집니다 — 사전에 `[Lang.Locales.Default] = ...` 항목을 넣어두지 않으면 다른 언어에서 현지화가 실패합니다.
- **Added** — `Lang.FailedMessage`. 현지화에 실패한 자리에 대신 넣을 문자열입니다.
- **Changed** — `Lang.CurrentLocale`이나 `Lang.FailedMessage`에 값을 넣으면 등록된 텍스트가 자동으로 다시 갱신됩니다. 전에는 값을 바꾼 뒤 갱신을 직접 불러야 했습니다. (이름을 바꾼 `11c3268`이 내부에서 옛 필드를 계속 읽고 있었는데, 그 자리까지 새 이름으로 바로잡은 것도 `723d3f9`입니다.)

### 2.14 - 2023-02-17 (`7361c01`)

- **Added** — `Lang` 모듈이 생겼습니다. 로케일별 사전을 등록해 두고(`Lang.New(id, handlers)`) `register`로 UI에 물리면, 현재 로케일에 맞는 문자열이 그 자리에 들어갑니다. 이 시점의 폴백은 영어(`Locales.English`)이고, 전용 폴백 키로 바뀌는 것은 2.15입니다.

### 2.13 - 2023-02-17~18 (`9e1216c`, `7361c01`, `52bc94c`)

- **Added** — `Signal` 모듈이 생겼습니다. 순수 Luau로 만든 Bindable(`New`/`Connect`/`Fire`)과, 연결을 모아 한 번에 끊는 `Disconnecter`입니다.
- **Added** — `Class.Extend` 인스턴스에서 `GetPropertyChangedSignal(name)`과 `EmitPropertyChangedSignal(name, value)`를 쓸 수 있습니다. 시그널은 처음 요청할 때 만들어지고, 그 프로퍼티에 다른 값을 넣으면 자동으로 발행됩니다. 두 이름은 2.7과 같은 커밋에 빈 껍데기로 먼저 들어와 있었습니다. (`7361c01`이 두 메서드를 `Signal`에 연결했지만 그때는 `Bindable.New()`가 만든 객체를 돌려주지 않았습니다. 그래서 `GetPropertyChangedSignal`은 `nil`을 돌려줘 `:Connect`에서 에러가 났고 `EmitPropertyChangedSignal`은 아무 일도 하지 않았습니다. 실제로 동작하기 시작한 것은 그 반환을 채운 `52bc94c`입니다.)

### 2.12 - 2023-02-21 (`0689ad8`)

- **Added** — `Mount`가 돌려주는 목록 객체에 `:Add(...)`가 생겼습니다. 같은 부모에 자식을 나중에 더 붙이면서 그 목록에도 함께 담을 수 있습니다.
- **BREAKING** — 그러면서 `Mount`가 자식을 **하나만** 넘겼을 때도 목록 객체를 돌려주게 됐습니다. 전에는 하나면 마운트 객체를 그대로 돌려주는 분기가 있었지만 그 반환값에는 `:Add`를 걸 수 없어서 없앴습니다. 반환값을 마운트 객체로 바로 쓰던 코드는 `MountOne`을 쓰거나 목록의 첫 원소를 꺼내야 합니다 — v1 자신도 이걸 놓쳐서 2.23의 객체 생성 오류가 났습니다.

### 2.11 - 2023-02-19 (`3e38345`)

- **Added** — `Store.GetObjects`에 `&`(AND)를 쓸 수 있습니다. `"button & active, modal"`처럼 적으면 `button`과 `active`를 **모두** 가진 오브젝트와 `modal`을 가진 오브젝트가 함께 나옵니다. 콤마(OR)도 이 커밋에서야 제대로 동작하기 시작했습니다 — 전에는 콤마가 든 문자열을 통째로 키로 찾아 빈 목록이 나왔습니다.
- **Changed** — `&`나 콤마를 쓴 쿼리 결과는 원본이 아니라 그때 만들어진 파생 목록이라 `:Remove`를 막았습니다. 다만 잠금 표시가 목록마다가 아니라 공용 클래스에 걸려서, 복합 쿼리를 한 번이라도 쓰면 그 뒤로는 평범한 목록까지 모든 목록의 `:Remove`가 에러를 냅니다(2.24까지 고쳐지지 않았습니다).

### 2.9 - 2023-02-21 (`0689ad8`)

- **Changed** — `round`가 쓰는 모서리·아웃라인 이미지를 모듈이 로드될 때 `ContentProvider:PreloadAsync`로 미리 받아둡니다. 둥근 프레임이 처음 그려질 때 이미지가 늦게 떠서 깜빡이던 것이 줄어듭니다.

### 2.8 - 2023-02-18 (`723d3f9`)

- **Changed** — `require(quad)`가 돌려주는 값에 타입이 붙어서 나옵니다. 반환 코드를 `exports`로 분리하고 `init.lua`가 그것을 `types.module`로 캐스팅해 돌려주도록 바꾼 결과라, 쓰는 쪽에서 타입을 따로 달지 않아도 정적 검사와 자동완성이 됩니다.

### 2.7 - 2023-02-16 (`9f2872e`)

- **Added** — `types` 모듈이 생겼습니다. 라이브러리 전체의 Luau 타입 정의를 한곳에 담았고, `require(quad.types)`로 직접 가져와 자기 코드의 어노테이션에 쓸 수 있습니다.

### 2.1~2.6 - 2023-02-17 (`83bb7ee`, `46da90f`)

- **BREAKING** — 모든 모듈과 메서드의 이름이 대문자 시작(PascalCase)으로 바뀌었습니다. `module.init` → `Init`, `this.store`/`this.tween`/`this.class` → `Store`/`Tween`/`Class`, `round.setRound` → `SetRound`, `event.bind`/`prop` → `Bind`/`Prop` 식입니다. 옛 소문자 이름은 남겨두지 않았으니 호출부를 전부 고쳐야 합니다.

### 2.0 - 2023-02-17 (`83bb7ee`)

- **BREAKING** — 메이저 번호를 2로 올렸습니다. 위의 이름 개편과 정적 타이핑, 시그널, 다국어 모듈까지 1.x와 호환되지 않는 변경이 한꺼번에 들어가서 1.x 코드는 그대로 올려 쓸 수 없습니다. 실제로 무엇을 고쳐야 하는지는 위의 2.1~2.6과 2.15를 보세요 — 대부분은 이름 개편입니다. 다만 소스의 버전 상수는 이 커밋에서도 아직 `1.14`였고, 실제로 `2.14`가 되는 것은 같은 날 몇 시간 뒤 `7361c01`입니다.
