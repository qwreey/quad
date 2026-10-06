---
title: "Changelog (변경 이력)"
description: "3.x 릴리즈마다 무엇이 생기고 바뀌고 없어졌는지 — 루트 CHANGELOG.md 원본 그대로"
---
이 파일은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 형식을 따르고, 버전은 [SemVer](https://semver.org/lang/ko/)입니다.
소비자가 겪는 변화만 적습니다 — 항목은 **Added / Changed / Deprecated / Removed / Fixed** 다섯으로 나누고, 호환이 깨지는 항목은 앞에 **BREAKING**을 붙이고 옮기는 법을 한 줄로 답니다. 내부 원장 번호는 쓰지 않습니다.
공개 표면이나 동작을 바꾸는 변경은 그 커밋에서 `[Unreleased]`에 한 줄을 넣고, 릴리즈 때 `scripts/check-version.py bump <version>`이 그 절을 버전 헤딩으로 자릅니다.

## [Unreleased]

_아직 게시되지 않은 변경입니다 — 다음 릴리즈에 실립니다. 비어 있으면 게시된 최신 버전이 곧 현재 상태입니다._

### Added

- `q.Tween{…}`(그리고 `q.Animate{…}`)에 콜백 셋 `Started`/`Completed`/`Cancelled`가 생겼습니다 — `(inst, prop, value)`(그 트윈이 도는 인스턴스·프로퍼티 이름·목표 값)를 받고, 인자 없는 함수도 됩니다. 모든 콜백은 그 자리의 기록을 마친 뒤 불리므로 어느 콜백 안에서 같은 원천을 `:Set`해 다음 트윈을 이어도 됩니다(마운트 중 첫 세팅의 `Started` 안은 예외 — 화면이 따라가지 않을 수 있습니다). `Started`는 트윈이 시작된 직후, `Completed`는 **자연히 끝났을 때만**, `Cancelled`는 새 값이나 철거가 돌고 있던 트윈을 끊을 때 불립니다(순서는 이전 `Cancelled` → 새 `Started` → 새 `Completed`; 교체 때 옛 트윈이 목표에 닿고 통지만 남았으면 이전 `Completed`, 자리 철거 때는 통지만 남은 트윈도 `Cancelled`). 같은 Tween을 프로퍼티 여럿에 걸면 자리마다 한 번씩 불리고, 숏핸드 키(`UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale`)는 값 하나에 한 번 `(숏핸드를 건 인스턴스, 숏핸드 키, 준 값)`으로 불립니다. 첫 세팅처럼 스냅되는 자리에서는 `Started`·`Completed`가 바로 이어서 불리고, `CanAnimate = false`여도 콜백이 있으면 그 둘은 불립니다. 트윈이 도는 동안 인스턴스가 파괴되면(파괴는 자리별 되돌리기를 거치지 않으므로 트윈은 끝까지 돕니다) 그 뒤의 `Completed`는 불리지 않습니다(파괴된 인스턴스의 자리를 직접 되돌려도 콜백은 불리지 않습니다).
- `tween:Wrapped(wrap)`와 `tween:Mapped(fn, wrap)` — 값을 그대로 두거나 바꾸면서 콜백 셋만 다시 정한 사본을 만듭니다. `wrap`은 원본 콜백 셋을 보는 핸들(`cb.Started` 등, `cb:Map(g)`)을 받아 새 셋을 돌려줍니다 — 같은 Tween을 여러 자리에 쓸 때 거르거나 합치는 자리입니다.
- **모든 quad 에러 메시지가 `QuadNNNN` 식별자로 시작합니다**(Luau의 `파일:줄:` 접두 바로 뒤, 예: `Quad0145 Slot:List: duplicate key a`). 번호는 한 번 붙으면 바뀌지 않고 재사용하지 않으므로 검색·분기는 번호로 하세요(문구는 여전히 API가 아닙니다). 번호마다 설명은 [레퍼런스 › 에러 코드](docs/reference/errors/00-index.md). 엔진(Roblox)이 내는 에러에는 번호가 없습니다.
- `q.Out(name, src)` — 엔진이 바꾼 프로퍼티 값을 `Source`에 되쓰는 슈거(`q.OnChange` 위, 같은 디스크립터). `D.TextBox { Text = text, q.Out("Text", text) }`처럼 내려가는 문자 키 옆에 나란히 둡니다. 새 값이 `src:Get()`과 같으면 `:Set`하지 않습니다(첫 쓰기의 메아리 방지). `:Compute` 결과 같은 읽기 전용 `State`는 타입에서 거부됩니다.
- `source:SetIfChanged(v)` — 값이 현재 값과 `==`로 같으면 아무것도 하지 않고(리비전도 전파도 없음), 다르면 `:Set(v)`와 똑같은 쓰기입니다. 비교는 Luau `==` 그대로라 두 값이 같은 `__eq` 메타메서드를 가지면 그것이 같음을 정하고, `NaN`은 늘 씁니다. `:Set`처럼 자기 자신을 돌려줍니다. `:Set`은 그대로 같은 값에도 늘 전파합니다 — 이 메서드는 되먹임 고리를 끊어야 하는 자리(`Effect`가 자기 의존성을 다듬어 되쓸 때, 엔진 신호를 `Source`로 올릴 때)를 위한 것입니다. `Store` 필드에서도 그대로 씁니다.
- `source:SetAndDispose(v)` — `:Set(v)`을 한 뒤 바뀌기 전 값을 `q.dispose`로 파괴합니다. 전파가 먼저 끝나 그 값을 앉혀 두었던 자리가 비워진 뒤에 파괴하므로, `Get()`으로 옛 값을 잡아 두고 `Set` 뒤 `dispose`하던 세 줄이 한 줄이 됩니다. 옛 값이 `nil`·`q.None`이거나 방금 넣은 값과 같은 참조이면 파괴하지 않습니다. 그 밖의 옛 값에서 `dispose`가 던지는 에러(파괴할 수 없는 값, 아직 다른 자리가 쥔 값)는 쓰기가 끝난 뒤에 그대로 납니다. `:Set`처럼 자기 자신을 돌려줍니다.
- `Effect`의 cleanup이 인자 하나 `dying: boolean`을 받습니다 — 묶인 인스턴스가 **죽어서** 소진될 때만 `true`, 다음 `fn` 실행 직전·`:Unsubscribe()`·숫자 키 자리를 떠날 때는 `false`. 인자를 안 받던 cleanup은 그대로 됩니다 — 단 **BREAKING(타입만)**: cleanup 타입이 `() -> ()`에서 `(dying: boolean) -> ()`로 바뀌어 `local cleanup: () -> () = …`처럼 옛 타입을 명시해 돌려주면 strict 에러입니다(인라인 리터럴·추론된 로컬 함수는 그대로 통과). 옮기는 법: 주석을 `(dying: boolean) -> ()`로 바꾸거나 빼세요. 이걸로 `q.OnDestroyed`가 고쳐졌습니다(아래 Fixed).

- `q.Bookkeeping.claimOwnerAt(element, inst, k)` / `q.Bookkeeping.releaseOwner(element, ownerKey)` — 숫자 키 자리에 값을 놓는 핸들러가 "이 값은 이 자리에 앉아 있다"를 등록·해제하는 소유권 op. `Slot`이 원소에 쓰던 그 레지스트리 하나를 정적 자식·숏핸드 관리 자식과 같이 씁니다. 자기 핸들러가 자식을 부모에 붙인다면 이 둘을 불러야 아래 단일 마운트 규칙에 들어갑니다.

- 백엔드 계약 op `isClaimed(inst)` — "이 요소가 이미 quad 소유인가". `Slot`이 원소를 받을 때와 정적 자식 자리마다(구동 hot path) 부릅니다. **BREAKING(프로바이더 작성자)** — 자기 백엔드를 만든 쪽은 이 op를 설치해야 합니다(quad-roblox는 claim 셋업 유무; 테스트 mock은 `Instance.new`가 태어날 때 claim된 것, 밖의 것은 `Instance.foreign`). 앱 코드에는 영향이 없습니다.

- `quad_roblox` 패키지 루트가 프로퍼티 값 타입 `Field<T>`(setter가 받는 값)와 `FieldOut<T>`(변환 함수의 `old`·`Peek`이 돌려주는 저장된 값)를 내보냅니다. 전에는 생성 모듈 경로로만 닿았는데, pesde 설치에서는 그 경로가 드러나지 않았습니다. 클래스별 타입도 같은 루트에서 내보냅니다 — `<Class>Modifier`(상위 클래스 포함), `Into<Class>`, `<Class>Elem`. how-to의 `require(<생성 모듈 경로>)` 자리표시자는 이 경로로 바뀌었습니다.

- `q.moduleIdentity` — 모듈 인스턴스마다 하나인 빈 identity 토큰. 백엔드·플러그인이 자기 값에 붙여 두고 "이 인스턴스가 만든 값인가"를 비교하는 데 씁니다(quad-base가 아래 인스턴스 교차 검사에 같은 방법을 씁니다).

- `q.debug`가 켜져 있을 때 `q:AddPlugin`이 모듈의 기존 필드를 덮어쓰면 설치 시점에 한 줄을 출력합니다. 덮어쓰기 자체는 그대로 허용됩니다(코어 부품을 일부러 갈아 끼우는 플러그인용). `UseProvider`는 해당 없음.
- `q.debug`가 켜져 있으면 옵션 테이블의 모르는 키(오타·옛 이름)를 한 줄로 알립니다 — `q.Debounce`/`q.Throttle`, `slot:List`/`slot:Single`의 `opts`, `q.Tween`, `q.Animate`. 경고만 하고 실행은 계속합니다(모르는 키는 전처럼 무시).
- `q.debug`가 켜져 있으면 `Claim`이 두 가지 실수를 알려 줍니다: 루트 디스크립터에 문자열 키를 준 경우(`M.Frame("Name")` — 키는 무시되고 루트 자신이 claim됩니다)와 자식 자리의 키가 문자열이 아닌 경우(`M.Root`를 자식에). 동작은 그대로입니다(런타임 검사를 두지 않는 `Claim`의 규칙).
- `q.debug`가 켜져 있으면 비용이 드는 검사 하나가 더 돕니다 — 평소 경로에서 빼 둔 대신 켜 둔 개발 중에는 **에러로 멈춥니다**: 디스패치 핸들러의 `process`가 함수가 아닌 retractor(`true`·숫자·테이블)를 돌려주면 그 자리에서 `Quad0077`(꺼져 있으면 지금처럼 `nil`만 검사하고, 그런 값은 나중에 그 자리를 무를 때 번호 없는 에러로 죽습니다). `Quad0077`의 문구는 `… must return a retractor function … (got {type})`으로 바뀌었습니다.
- 디스패치 핸들러 계약에 선택 필드 `debugOnly: boolean?` — `true`면 그 핸들러는 `q.debug`가 켜져 있을 때만 후보가 됩니다(꺼져 있으면 에러 없이 후보에서 빠짐; `q.debug`는 스캔마다 읽으므로 켜고 끄면 바로 반영). 진단 필터(경고를 찍고 `false`를 돌려 스캔을 그대로 흘려보냄)나 개발 중에만 키를 맡는 핸들러에 씁니다. 꺼 둔 비용은 분기 하나이고, 등록해도 다른 핸들러끼리의 순서는 바뀌지 않습니다. `true`/`false`/`nil`이 아니면 등록 때 `Quad0266`. `q.Dispatch.listHandlers()`는 이 핸들러도 늘 돌려줍니다.
- `q.debug`가 켜져 있으면 경고 일곱이 더 나옵니다(한 줄씩, 동작은 그대로): 배열 원소로만 쓰는 quad 값(`Ref` 가족·`Observer`·`Effect`·`Slot`·`Tag`·`Attr`)이 props의 문자 키에 놓였을 때(반영 프로퍼티·이벤트 이름이면 그 값의 전용 거절 대신 프로퍼티·이벤트로 들어가던 자리 — 같은 요소·키는 한 번), `:Compute` 계산 함수가 도는 도중 `Source:Set`/`:Emit`이 불렸을 때(같은 `Source`는 한 번), 같은 노드의 앞선 계산이 다른 코루틴에서 멈춘 채(계산 함수 안 yield) 새 계산이 시작될 때, `state:Observer(fn)`의 콜백이 도는 도중(첫 발화 포함) 같은 핸들에 변경이 다시 도착했을 때(콜백이 자기 상류를 되먹였다는 뜻 — 핸들마다 한 번; props 자리에 놓인 `State`의 값을 처리하는 동안 불린 콜백이나 엔진 신호가 그 `State`를 되쓴 경우도 포함; quad가 자리 계산·목록에 내부로 쓰는 Observer와, Slot의 `Offset`/`Length`를 보는 콜백이 Slot을 CRUD해 그 값이 다시 바뀌는 고리(마운트·다시 앉히기 포함)는 빠집니다 — 그 고리는 Slot이 스스로 다시 계산해 맞추는 정의된 경로), `Debounce`/`Throttle` 게이트가 보류분을 내보내는 도중 그 통지를 받은 콜백 안에서 같은 게이트의 `handle:Cancel()`이 불렸을 때(정의되지 않은 동작 — 지금은 창이 다시 열려 다음 leading 신호가 `Time` 하나를 더 기다립니다), 디스패치가 quad가 claim하지 않은 인스턴스 — 파괴됐거나(`q.dispose`든 quad 밖이든) quad가 만들지 않은 것 — 에 돌 때(정의되지 않은 동작; `D.<Class>`·`drive`·`process` 모두, 키마다), 마운트 대상 인스턴스가 더는 claim돼 있지 않은 `Slot`에 CRUD를 부를 때(정의되지 않은 동작 — 그 변경은 죽은 인스턴스로 갑니다).
- `q.Protocols.DispatchHint` — 디스패치가 값에 맞는 핸들러를 못 찾을 때(`Quad0076`) **그 값이 직접 원인 문장을 주게** 하는 능력 브랜드입니다. 값을 만들 때 `quad.Protocols.DispatchHint:Register(value)`로 등록하고 `value:__dispatchHint(key) -> string?`을 두면 그 문장이 메시지 꼬리가 됩니다(`nil`이면 일반 꼬리; 에러 위치는 그대로; 훅이 던지는 것은 정의되지 않은 동작). quad의 `Store`·`Context`·`Provider`·`Blocker`·`AttrKey`와 quad-roblox의 `Tween`이 자기 문장을 등록합니다 — 그래서 `Blocker`·`AttrKey`를 값 자리에 두면 "숫자 키 자리로 옮기라"(옮기면 같은 에러) 대신 `state:Apply(blocker)`·`[q.AttrKey(name)] = value`를 안내하고, `Tween`을 없는(오타·읽기 전용·다른 클래스) 프로퍼티 키에 두면 그 키를 의심하라고 안내합니다. 이름 규약: 두 밑줄로 시작하는 이름(`__dispatchHint`)은 quad가 부르는 공개 훅(계약)이고, 밑줄 하나는 비공개입니다. 브랜드 술어 등록부 `q.BrandPredicates`와는 별개입니다.

### Changed

- `Slot`의 CRUD(`Add`/`Replace`/`Extract(i, new)`/`Splice`/생성자)가 넣기 전에 미리 하는 검사는 이제 **원소 종류**(마운트 가능한 값·quad 소유·파괴된 Slot 아님) 하나입니다 — 이 검사에 걸리면 전처럼 아무것도 바뀌지 않습니다. 같은 원소를 두 번 넣거나 이미 다른 곳에 마운트된 원소는 그 원소를 자리에 넣는 순간 거부합니다 — 같은 Slot이면 `Quad0170 Slot: this element is already in this Slot (a second mount) - reorder with Move/Swap …`(`slot:Add(a); slot:Add(a)`와 `q.Slot({ a, a })`가 같은 에러), 다른 곳이면 `Quad0172`. 여러 원소를 받는 호출(`Splice`·생성자)이 중간 원소에서 이렇게 던지면 앞 원소는 이미 들어가 있습니다(관측 — 계약 아님). 한 호출 안의 중복을 넣기 전에 잡는 `Quad0171`은 `q.debug`일 때만 돕니다. **`State`로 넣은 원소는 넣을 때 값을 읽지 않고** `:List`/`:Single` 항목처럼 마운트·값 변경 때 검사합니다 — 마운트 전 Slot에 같은 Instance를 쥔 `State` 둘을 넣으면 넣는 줄 대신 마운트 줄에서 `Quad0156`이 나며(문구가 그 원인을 말합니다), `slot:Add(computed)`가 그 계산 함수를 마운트 전에 돌리지 않습니다. 기존 원소 전체를 훑던 검사가 빠져 원소 하나씩 `Add`하는 비용이 길이에 비례하지 않습니다. `Splice`가 같은 호출에서 빼는 원소를 다시 넣는 것은 이제 됩니다(빼는 쪽이 먼저 풀립니다 — 전엔 "같은 원소가 두 번"으로 거부).

- 문서: `:Compute` 계산 함수 안의 `:Set`/`:Emit`과 yield는 **정의되지 않은 동작**으로 명시했습니다 — 반응형 콜백은 파동 도중 yield하지 않고, 꼬인 파동을 풀어 줄 도구가 없는 곳에서 자기 입력을 되먹이지 않습니다(`Effect`가 자기 의존성을 `:Set`해 끝난 뒤 한 번 더 도는 것은 정의된 예외). 레퍼런스가 서술하던 yield 시 동작(`Quad0184`가 나는 자리)은 계약이 아니라 지금의 관측입니다. `Observer`는 최종 소비자로 명시했습니다 — 콜백이 **다른** 대상을 `:Set`하는 것은 정상이고, **자기 상류**(관측 대상이나 그 원천)를 직접 또는 다른 핸들을 거쳐 되먹이는 것은 정의되지 않은 동작입니다(되써서 바로잡아야 하면 `Effect`로). 엔진을 한 바퀴 도는 `q.Out`/`OnChange` 왕복과, Slot의 `Offset`/`Length`를 보는 콜백이 Slot을 CRUD해 그 값이 다시 바뀌는 고리(Slot이 스스로 다시 계산해 맞춤)는 여기 해당하지 않습니다. 반응형 콜백 안의 yield는 어느 콜백에서든 정의되지 않은 동작입니다. 같은 맥락의 문서 축소: `ref:Wait(thread)`의 정의는 "그 Ref가 다음에 `:Set`될 때 등록된 코루틴을 한 번 resume한다"뿐이고, 한 코루틴을 여러 Ref에 거는 조율("둘 중 먼저" 등)은 quad가 정의하지 않습니다(코루틴 조율 도구의 몫).
- `state:Get()`(`:Compute` 결과 등)은 이제 재계산을 한 번만 합니다 — 전에는 계산 함수 도중 상류가 움직였으면 같은 `:Get()` 안에서 다시 계산했습니다. 정의된 경로의 동작은 같습니다(닫힌 게이트 뒤에서 움직인 상류도 여전히 알아채 최신 값을 돌려줍니다). 다른 것은 계산 함수 안의 `:Set`·yield(정의되지 않은 동작)뿐입니다 — 그때 그 `:Get()`은 한 파동 뒤처진 값을 돌려줄 수 있고(지금은 다음 `:Get()`이 따라잡습니다), yield로 겹친 계산이 어느 결과를 남기는지도 정하지 않습니다(멈췄다 돌아온 계산을 따로 다루던 장치를 걷어냈습니다 — 겹침은 `q.debug`의 경고가 알려 줍니다).
- strict 타입: `nil`을 기능으로 받는 입력 자리가 이제 `nil`이나 `q.None`을 내놓을 수 있는 `State`도 받습니다 — 객체 참조 프로퍼티(`Adornee`·`NextSelectionUp`·`PrimaryPart` 등 값이 Instance인 것), 이벤트, 숏핸드(`UICorner`·`UIPadding`·`UIScale` 등)와 그 Modifier setter, 타입드 Attr 슈거(`StringAttr` 등), `Slot` 원소 입력, 숫자 키 자리의 `State<OnChange 디스크립터?>`·`State<Ref?>`. 런타임은 원래 받던 것이라 동작은 같고 타입만 넓어집니다. `Text`처럼 엔진이 `nil` 쓰기를 거부하는 프로퍼티는 그대로 거부합니다. 속성을 지우려고 `:Set(q.None)`하는 State는 `q.Source<<boolean | typeof(q.None)>>(true)`처럼 `None`을 타입에 넣어 선언하세요.
- **BREAKING — 조용히 받아들이던 잘못된 입력 몇 가지를 이제 그 자리에서 거부합니다**: `:List`/`:Single`의 `opts.OwnsElements`에 불리언이 아닌 값(`"false"`, `0` — 전에는 소유로 처리, `Quad0259`), `:List` 데이터 항목 자체가 `q.KeyGone`인 것(전에는 조용히 빠짐, `Quad0260`), `q.Attr(store)`에서 Store 필드에 직접 넣은 함수·테이블 값(전에는 적용할 때 번호 없는 에러). 옮기는 법: `OwnsElements`에는 `true`/`false`만 넘기고, 데이터 배열에서 `q.KeyGone`을 빼고, `q.Attr(store)`로 넘길 Store의 필드에는 원시 값·`State`/`Source`·`q.None`만 두세요(함수·테이블은 다른 Store로 빼세요).
- `Effect`의 지연 재실행(`fn`이 자기 의존성을 `:Set`해 끝난 뒤 한 번 더 도는 것)이 한 번의 반복에서 1만 번 넘게 돌면 `Quad0263`으로 멈춥니다 — `q.debug`와 상관없이 늘 켜진 한도입니다. 3.2.0에서는 상한 없이 돌아, 자기 의존성을 계속 바꾸는 `fn`(`Source`는 같은 값도 전파하므로 조건 없이 같은 값을 되쓰는 `fn` 포함)이 에러 없이 끝나지 않았습니다. 1만 회 전까지의 재실행은 그대로이고, 멈춘 `Effect`는 `fn`이 던진 것과 같이 죽습니다. 옮기는 법: 되쓰기를 `dep:SetIfChanged(c)`로 하세요(값이 같으면 아무것도 하지 않습니다 — 위 Added).
- `Slot`의 `Offset`을 보는 콜백이 앞자리의 길이를 바꿔 자리 계산이 그 자리부터 다시 도는 고리(정의된 경로)가 한 번의 계산에서 1만 번 넘게 되감으면 `Quad0267`로 멈추고, 그 계산을 시작한 줄(CRUD·`:Set`)에서 던집니다 — `Effect`의 `Quad0263`과 같은 수이고 `q.debug`와 상관없이 늘 켜진 한도입니다. 3.2.0에서는 값마다 넣고 빼기를 뒤집는 콜백이 에러 없이 끝나지 않았습니다. 1만 번 전까지의 되감기는 그대로이고, 되감기가 없는 계산은 목록이 아무리 길어도 걸리지 않습니다. 옮기는 법: 넣고 뺄지를 콜백이 바꾸는 그 길이에 기대지 않는 값으로 정하세요.
- `q.debug`가 꺼져 있을 때 매번 돌던 검사 넷을 빼 평소 경로를 가볍게 했습니다 — 이제 `q.debug`가 켜져 있을 때만 돌고, 켜면 전처럼 그 자리에서 에러로 멈춥니다: (1) 중괄호를 잊은 `D.Frame(value)`의 `Quad0083` — 평소엔 메타테이블이 있는 값과 quad-base의 메타테이블 없는 값(`q.AttrKey` 등)만 봅니다. 메타테이블 없는 평범한 테이블에 브랜드를 붙이는 **프로바이더 값**은 꺼져 있으면 그 필드들이 props로 해석됩니다(대개 `Quad0076`). (2) `slot:List` 데이터의 `Quad0143` — 평소엔 배열 부분이 비어 있는데 다른 키가 있는 것(아이디 맵, JSON 오브젝트)만 잡습니다. 배열에 키가 **덧붙은** 데이터(`{ a, b, extra = 1 }`)는 꺼져 있으면 덧붙은 키가 무시됩니다. (3) `Slot`을 자기 자신이나 조상 Slot에 넣는 `Quad0173` — 꺼져 있으면 넣는 줄은 통과하고 그 트리의 다음 CRUD나 해체가 스택 오버플로로 죽습니다. (4) quad-roblox에서 Instance를 자기 자신이나 자손의 숫자 키 자리에 놓는 `Quad0220` — 꺼져 있으면 Roblox 엔진의 circular reference 에러가 대신 멈추되, quad가 자리를 잡은 뒤에 나는 에러라 그 요소는 버리세요. 개발 중에는 `q.debug = true`를 켜 두세요.
- 매치 실패 에러(`Quad0076`)와 중괄호 누락 에러(`Quad0083`)가 값이 가진 브랜드 이름을 하나만이 아니라 걸리는 것 전부, 이름순으로 싣습니다(예: `brand: Epoch, PreRef, Ref`).
- `q.Operator.Band()`·`Bor()`·`Bxor()`를 인자 없이 쓰면 이제 값을 `bit32` 규칙으로 정규화합니다(`-1` → `4294967295`) — 인자 하나일 때와 `Bnot`과 같아졌습니다. 전에는 값을 그대로 돌려줬습니다.

- 프로바이더 계약: 자기 값 타입의 브랜드 술어(`is<Brand>` 모듈 필드)를 설치 때 받은 모듈의 새 집합 `quad.BrandPredicates`에 `:Register(isX)`로 등록하세요 — 디스패치 진단(매치 실패 메시지의 브랜드 이름, 중괄호를 빠뜨린 `D.Frame(value)` 거부)이 등록된 술어만 봅니다. 등록하지 않아도 동작은 그대로이고 그 브랜드의 진단만 약해집니다. quad-roblox의 `isTween`은 등록돼 있습니다.
- `q.Tag(...)`·`tag:Added`·`tag:Removed`·`q.Tag.Merged`의 **인자 자리 `nil`은 이제 "없음"**입니다(전엔 검증 에러). `base:Added(if even then "Even" else nil)`처럼 조건을 인자 안에 쓰면 결과가 늘 새 `Tag`라 대입을 빠뜨릴 수 없습니다. 리스트 안 nil 구멍(`{ "a", nil, "b" }`)은 여전히 에러이고, `tag:Contains(nil)`도 그대로 에러입니다.
- `Info` 없이 `Time = 0`이고 `DelayTime`/`RepeatCount`/`Reverses`가 없거나 0·거짓인 `q.Tween{…}`은 이제 엔진 트윈 없이 값을 그 자리에서 씁니다(첫 세팅과 같은 스냅). 전에는 0초짜리 엔진 트윈을 만들어 다음 프레임에 썼습니다. 그 셋 중 하나라도 있으면 전과 같습니다.

- `Claim`이 트리를 해석하는 단계에서 **이미 quad 소유인 인스턴스**(루트든 자식이든 — 템플릿에 꽂아 둔 `Declaration` 위젯, 먼저 `Claim`한 자식)를 `Claim: <이름> is already claimed by quad …`로 거부합니다. 아무것도 claim하기 전이라 루트와 형제는 무손상이고, 그 자식을 디스크립터에서 빼면 같은 루트에 다시 걸 수 있습니다. 전에는 자식의 경우 루트와 앞선 형제가 claim된 채 남아 그 루트를 영영 `Claim`할 수 없었습니다. 자기 백엔드를 만든 쪽: `isClaimed`가 "`nativeClaim`이 지나간 것만 참"이어야 이 게이트가 성립합니다(quad-roblox는 원래 그렇습니다).

- `OwnsElements = false`인 `:List`/`:Single` Slot을 `q.dispose`하거나 소유하는 부모 Slot이 `Remove`/`Clear`로 버리면, 그 Slot이 쥐고 있던 원소 전부의 소유권이 풀립니다(원소는 파괴되지 않고 다른 Slot에 넣거나 `q.dispose`할 수 있습니다). 그 Slot은 빈 채로 살아남아 다시 쓸 수 있고, 다음 마운트에서 data로부터 처음부터 조정합니다. 전에는 원소가 버려진 Slot에 계속 묶여 있어 `already mounted elsewhere`/`still held by a Slot`으로 거부됐고, Slot 참조를 버린 뒤엔 되돌릴 길이 없었습니다. `Extract`로 빼는 경우는 전처럼 원소를 쥔 채 옮겨갑니다.

- **BREAKING — `Slot`이 quad 밖에서 만든(claim되지 않은) 인스턴스를 더는 원소로 받지 않습니다.** 전에는 조용히 들어갔고 죽음 추적이 없어 밖에서 `Destroy`되면 Slot이 stale해졌습니다. 이제 `Add`·생성자·`Replace`·`Extract`·`Splice`·`List`/`Single`이 `Slot: this element is not claimed by quad …`로 거부합니다(`State`에 담긴 원소도 그 현재값으로 미리 검사합니다). `List`/`Single`의 `updateFn`이 그런 원소를 돌려주면 재조정 도중의 예외라 그 Slot의 `Length`가 더 이상 발행되지 않습니다(재조정은 계속 돌지만 같은 부모의 형제 Slot이 옛 오프셋에 앉습니다, 에러 없이) — 원소를 만들 때 claim하세요. 옮기는 법: 그 인스턴스를 먼저 `Claim`으로 넘겨받거나 `Declaration`으로 만드세요 — Slot이 대신 claim하지 않습니다. **정적 자식 자리도 같습니다** — `D.Frame { Instance.new("TextLabel") }`처럼 숫자 키에 놓은 미claim 인스턴스는 `InstanceChild: this Instance is not claimed by quad …`로 거부됩니다. 그 자리의 `State<Instance?>`를 나중에 미claim 인스턴스로 `:Set`하는 경우도 같은 거부인데, 이때는 옛 자식이 이미 내려간 뒤(체인 철거 뒤 새 값 처리)라 그 자리는 빈 채로 남습니다.

- **BREAKING — 정적 자식과 숏핸드 관리 자식도 "한 값은 한 자리" 규칙 안에 들어갑니다.** 전에는 같은 Instance를 `D.Frame { c }` 둘에 놓으면 에러 없이 둘째가 가져가고 첫째의 자리 부기는 남아, 첫째가 자리를 내릴 때 살아 있는 둘째 트리에서 그 자식을 뜯어냈습니다. `{ c, c }`도 통과했고, 정적 자식을 `slot:Add`하거나 `q.dispose`하는 것도 막히지 않았습니다. 이제 둘째 자리는 `Bookkeeping.claimOwnerAt: this element is already mounted elsewhere …`로 거부되고(첫째 트리는 그대로 — 다만 그 둘째 자리가 `State`에 담긴 자리라면 거기 앉아 있던 옛 자식은 거부 전에 이미 내려가 그 자리는 빈 채로 남습니다, 미claim 인스턴스를 넣을 때와 같습니다), 앉아 있는 자식은 `q.dispose`가 `dispose: this value is still held by a Slot or a mounted position …`로 거부합니다. `UICorner = 8` 같은 숏핸드가 만든 관리 자식(`_quad_round`·`_quad_padding`·`_quad_scale`)도 같습니다 — 전에는 `q.dispose`가 조용히 파괴한 뒤 다음 값 발행이 파괴된 인스턴스에 써졌습니다. 옮기는 법: 한 Instance를 다른 자리로 옮기려면 먼저 그 자리에서 내리세요(자리를 쥔 State를 `:Set(nil)`, Slot이면 `Extract`). 두 곳에 같은 모양이 필요하면 Instance를 둘 만드세요. 제대로 돌던 코드는 영향이 없습니다 — 이 변경은 원래 막혔어야 할 것을 막은 것입니다.

- **BREAKING(좁은 범위) — `:Compute` 계산 함수의 재진입이 에러가 됩니다.** 계산 함수가 자기 노드의 값을 읽는 의존성 순환(직접, 또는 하류 State를 거쳐)은 전에는 내부 파일을 가리키는 `stack overflow`였고, 그것을 `q.Fallback` 같은 프레임이 삼키면 반쯤 계산된 값이 유효 캐시로 굳었습니다. yield하는 계산 함수를 다른 코루틴이 그 사이 읽으면 함수가 두 번 돌았습니다. 이제 둘 다 읽는 줄에서 `State: Compute fn is already running for this value …`로 즉시 에러입니다. 부수 규칙 하나: 계산 함수가 던지면 **같은 세대의 재읽기**도 그 문구로 에러이고(전에는 함수가 다시 돌았습니다), 상류가 바뀌면 다시 돕니다. 잡히지 않는 모양 하나: 계산 함수가 **자기 의존성을 `:Set`한 뒤** 자기 값을 읽는 순환은 세대가 바뀌어 새 계산으로 보이므로 전처럼 스택 오버플로입니다(계산 함수가 자기 의존성을 매번 다시 쓰는 것은 원래 정의되지 않은 동작). 순환·yield·던지는 계산 함수를 쓰지 않던 코드는 영향이 없습니다. 옮기는 법: 계산 함수가 던진 뒤 같은 값에서 다시 읽어 재시도하던 코드는 상류를 고쳐 `:Set`한 뒤 읽으세요. 핸들러 작성자용 한 줄: 길이로 등록한 `State`의 계산 함수가 같은 owner의 부기를 건드리면 이 에러입니다(중첩 재계산이 자기 값을 읽습니다).

- quad-roblox의 `Event`·`OnChange` 핸들러 우선순위가 `HANDLER_PRIORITY_NORMAL - 1`로 내려갔습니다(각각 `Property`·`InstanceChild`와 같은 값이었음). 판정이 서로 배타적이라 동작은 같고, `q.debug`를 켰을 때 설치 시점에 찍히던 "priority tie" 안내 두 줄이 사라집니다. 자기 핸들러를 NORMAL 근처에 두는 플러그인은 `q.Dispatch.listHandlers()`로 자리를 확인하세요.
- 자리에 놓인 `State`를 벗겨 실제 값을 같은 자리의 한 칸 아래로 다시 넘기는 내장 핸들러의 이름이 `StoreBind`에서 `StateHandler`로 바뀌었습니다 — `q.Dispatch.listHandlers()`가 돌려주는 `name`과, 에러 위치·traceback에 보이는 quad 내부 파일 이름(`StateHandler.luau`)이 달라집니다. 이름은 진단용이라 동작은 같습니다. 핸들러 이름을 비교하는 코드가 있다면 새 이름으로 바꾸세요.

- 옵션 테이블을 변수에 담아 넘겨도 strict 타입 검사가 통과합니다 — `q.Debounce`/`q.Throttle`의 옵션, `slot:List`/`slot:Single`의 `opts`, 그리고 `q.Slot(initial)`의 배열(필드·원소가 읽기 전용 `read`로 선언됨 — **BREAKING(타입만)**: 주석을 단 옵션 테이블을 만든 뒤 `o.Leading = true`처럼 고치는 코드는 strict 에러가 됩니다; 만들 때 값을 다 넣거나 주석 없는 테이블을 쓰세요). 전에는 `local opts = { Time = 0.3 }` 뒤 `q.Debounce(opts)`가 가변 필드 불변성으로 거부됐습니다. 받는 입력이 넓어지기만 해 기존 코드는 그대로 통과합니다.

- **BREAKING(타입만) — 생성 `Declaration`의 레거시 프로퍼티가 허용목록으로 줄었습니다.** 남는 것은 `Font`·`Transparency`(Hidden)·`FontSize`·`TextWrap`(Deprecated) 넷이고, `Draggable`·`BillboardGui.DistanceLowerLimit`/`DistanceUpperLimit`·`Camera.focus`(쓰기 표면)와 `className`(`q.OnChange` 읽기 표면 — 그 변경 시그널은 실기기에서 발화하지 않습니다)은 타입에서 빠집니다. 런타임은 같습니다(디스패치는 엔진 리플렉션을 따르므로 `Draggable = true`는 여전히 써집니다 — 다만 strict에서 타입 에러). 옮기는 법: 빠진 키를 쓰는 곳은 현행 API로 바꾸거나, 꼭 필요하면 `D.New`/`q.Dispatch.drive`에 `any`로 넘기세요.

- **BREAKING(타입만) — `q.OnChange("Parent", fn)`의 콜백 인자와 `AncestryChanged` 이벤트의 `parent` 인자가 `Instance`에서 `Instance?`로 바뀌었습니다.** 엔진은 인스턴스가 트리에서 빠질 때 이 두 자리에 `nil`을 주는데(그 순간을 잡는 것이 이 API를 쓰는 주된 이유), 생성 타입이 `Instance`라 `function(p: Instance) print(p.Name) end`가 strict를 통과한 채 실기기에서 죽었습니다. 런타임은 같습니다. 옮기는 법: 콜백 주석을 `Instance?`로 바꾸고 본문에서 `nil`을 먼저 거르세요 — 주석을 빼면 strict가 사용 모양에서 `Instance`로 추론해 `nil` 팔을 못 받아 오히려 에러가 납니다(3.2.0에선 통과하던 모양). `Camera.CameraSubject`·`Model.PrimaryPart`는 쓰기 자리라 그대로입니다.

- **BREAKING(타입만) — `q.Effect`가 돌려주는 핸들의 타입 이름이 `EffectHandle`에서 `Effect`로, 입력 자리 마커가 `EffectHandleMarker`에서 `EffectMarker`로 바뀌었습니다.** `state:Observer` → `Observer`, `q.Slot` → `Slot`처럼 생성자와 타입 이름이 같은 규칙에서 이것만 벗어나 있었습니다(술어 `isEffect`와도 맞춤). 런타임은 같습니다. 옮기는 법: 주석·재수출의 `EffectHandle`을 `Effect`로(설정 모듈의 `export type EffectHandle = QuadTypes.EffectHandle` → `export type Effect = QuadTypes.Effect`).

- **BREAKING(프로바이더 작성자) — 백엔드가 심는 생명주기 op가 바뀌었습니다.** 전에는 백엔드가 `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute` 넷을 통째로 구현했고, 그러려면 `Observer`/`Effect`의 밑줄 훅 셋을 정해진 순서로 불러야 했습니다. 이제 그 넷은 quad-base가 직접 구현하고, 백엔드는 인스턴스 쪽 부기만 담은 **hold op 넷**을 심습니다 — `holdLifetime(inst, value)`(값을 인스턴스의 강참조 홀더에 넣고 생존 근거를 남김, quad 소유가 아니면 던짐), `releaseLifetime(value)`(그 역), `isHeld(value)`(근거가 아직 살아 있는가), `isHeldBy(value, inst)`(이 인스턴스가 쥐고 있는가). 옮기는 법: 자기 백엔드의 `bindLifetime` 본문에서 gchold/gcconn 부기 부분만 `holdLifetime`으로, 해제 부분만 `releaseLifetime`으로 옮기고, 살아 있음 판정의 gcconn 절반을 `isHeld`로 두세요. 나머지 줄(nil 검사, 거부 메시지, 훅 호출, `.Subscribed` 판정)은 지우면 됩니다 — quad-base가 합니다. 앱 코드에는 영향이 없습니다(quad-roblox 사용자는 그대로).

- **BREAKING — 백엔드가 심는 계약 op가 `q.Backend`로, Length/Offset 부기 함수가 `q.Bookkeeping`으로 옮겨졌습니다.** 앱 코드가 부를 표면이 아닌 것들이 `q.` 자동완성에 섞여 있었습니다. 멤버 이름은 그대로입니다.
  - `q.Backend`: 백엔드가 **심는** 슬롯 스물 — `holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`(아래 hold op 항목), `nativeInsert`/`nativeExtract`/`nativeRemove`/`nativeMove`/`nativeSwap`/`nativeDispose`, `nativeClaim`/`isClaimed`/`nativeFindChild`/`isInst`/`onDestroying`, `addTag`/`removeTag`/`setAttr`, `setTimeout`/`clearTimeout`.
  - `q.Bookkeeping`: `setLength`/`setOffsetSource`/`setEmpty`/`getOffsetAt`/`getBookkeeping` — `q.Dispatch`에서는 빠졌습니다. `getBlocker`(배치 Blocker 조회)는 옮기지 않고 **공개 표면에서 빠졌습니다** — 배치를 여닫는 것은 `drive`와 `Slot`의 몫이고(닫으며 재계산하는 경로가 내부에만 있어 핸들러가 직접 열면 제대로 닫을 수 없었습니다), 진단 읽기는 `getBookkeeping`이 합니다. 에러 문구의 접두도 `Dispatch.`에서 `Bookkeeping.`으로 바뀌었습니다.
  - `q.dispose`, `q.newMapperClass`, `is*` 술어는 그대로 `q.`에 있습니다.
  - 옮기는 법: 백엔드 작성자는 `quad.nativeInsert = …`를 `quad.Backend.nativeInsert = …`로 옮기되 옛 `quad.bindLifetime = …`은 **옮기지 말고 지우세요**(그 넷은 이제 quad-base가 `q.Backend` 위에 조립합니다 — `quad.Backend.bindLifetime = …`로 옮기면 base의 게이트를 덮어쓴 채 에러 없이 돌아갑니다); 대신 hold op 넷을 심으세요. 핸들러 작성자는 `q.Dispatch.setLength(…)`를 `q.Bookkeeping.setLength(…)`로, 테스트에서 `q.bindLifetime(…)`을 부르던 코드는 `q.Backend.bindLifetime(…)`으로. 옛 모양(`quad.nativeInsert = …`)은 에러 없이 받아들여지고 첫 사용에서 `… is not available - no backend has installed …`가 나니, 프로바이더를 이미 설치했는데 이 문구가 보이면 이 이관을 의심하세요.

- **Observer·Effect·Slot·State를 만든 quad 인스턴스가 아닌 다른 인스턴스의 트리에 놓으면 그 자리에서 에러가 납니다**(`…: this value was made by another quad module instance …`) — 숫자 키 자리, 프로퍼티 값, `slot:List`의 데이터 State. 전에는 에러 없이 받아들여졌지만 생명주기 기록이 인스턴스마다 따로라 그 값이 조용히 돌지 않았습니다(`quad_base` 사본이 둘 생긴 프로젝트에서 흔히 밟는 경우). 제대로 돌던 코드는 영향이 없습니다. 의존성으로만 잇는 것(`q.Effect(fn, 다른 인스턴스의 Source)`)은 그대로 되고, `Ref`·`Blocker` 같은 공유 값은 검사하지 않습니다(두 인스턴스에 걸쳐 쓰면 정의되지 않은 동작).

- **BREAKING — `quad_types`의 `Brand()`가 돌려주는 객체의 메소드가 `:register`/`:is`에서 `:Register`/`:Is`로 바뀌었습니다.** 자기 값 타입에 브랜드를 붙이는 백엔드·플러그인 작성자에게만 해당하고, `q.isState` 같은 술어를 쓰는 코드는 그대로입니다. 옮기는 법: 호출부의 메소드 이름 첫 글자만 대문자로.
- 문서에 명시: `_`로 시작하는 필드(`_bookkeeping` 등)는 공개 표면이 아니며 예고 없이 바뀝니다.
- 문서에 명시: 에러 메시지는 사람이 읽는 진단이지 API가 아닙니다 — 문구는 예고 없이 다듬어질 수 있으니 문구로 분기하지 마세요.
- 문서에 명시(정의되지 않은 동작): 같은 원천을 구독한 하류·Ref 콜백끼리의 발화 순서와 `KeyGone` 호출끼리의 순서(등록 순서가 아닙니다), Observer·Effect·계산 함수·Ref 콜백 안의 yield, `updateFn`이 도중에 던진 뒤의 그 Slot(지금은 `Length` 발행이 멈춰 형제 Slot이 옛 오프셋에 앉습니다 — 관측이지 계약은 아닙니다), 서로를 설치하는 플러그인 순환.
- **BREAKING — `slot:List`/`slot:Single`의 옵션 `Owned`가 `OwnsElements`로 바뀌었습니다.** 뜻은 그대로입니다(기본 `true`, `false`면 이 Slot이 원소의 수명을 책임지지 않음). 옛 키는 조용히 무시되어 기본값(소유)으로 돌아가니 반드시 옮기세요 — `q.debug`를 켜면 모르는 키로 알려 줍니다(strict 타입도 이 키를 잡지 못합니다). 옮기는 법: `{ Owned = false }`를 `{ OwnsElements = false }`로.
- `q.Effect`의 `fn`이 함수도 `nil`도 아닌 값을 돌려주면 그 자리에서 `Effect: fn must return a cleanup function or nothing (got …)`을 던집니다(사용자 줄 blame). 전에는 값을 저장했다가 다음 정리 때 quad 내부에서 `attempt to call …`로 터지고 그 `Effect`가 조용히 멈췄습니다. 연결 객체를 돌려주던 코드는 `return function() conn:Disconnect() end`로 감싸세요.
- `q:AddPlugin`이 같은 플러그인 함수를 다시 받으면 아무것도 하지 않습니다(`q:RunInit`과 같은 identity 기준). 여러 스크립트가 각자 설치해도 한 번만 돕니다. 도중에 던진 플러그인은 지금은 설치된 것으로 치지 않아 다시 부르면 처음부터 돕니다(던진 뒤의 동작이라 관측이지 계약은 아닙니다).
- `quad_roblox`가 요구하는 `quad_base` 버전이 정확히 일치에서 **같은 메이저 안의 하한**(릴리즈 시점 버전이 하한 — 예: 3.3.0 릴리즈면 `3.3^.0^` = 3.3.0 이상, 메이저 3; bump가 갱신)으로 풀렸습니다. `quad_base`만 올라가도 `UseProvider`의 버전 검사(`Quad0228`)에 막히지 않습니다. 프리릴리즈 빌드는 그 빌드만 받습니다(패턴 `3.3.0-rc.2`).
- **BREAKING — `q.Store`의 필드 이름으로 `__`(밑줄 둘)로 시작하는 이름을 전부 쓸 수 없습니다**(전에는 `__reservedCheck` 하나만 막았습니다). 생성자와 `:Of` 모두 `Store: "{name}" is a reserved store key`를 던지고 strict 타입 검사도 알립니다. 대신 Store의 메소드는 `Of`/`Names`에서 더 늘리지 않기로 해, 그 둘과 `__` 접두만 피하면 앞으로 필드 이름이 새 메소드와 부딪히지 않습니다. 옮기는 법: `__`로 시작하는 필드 이름을 다른 이름으로 바꾸세요.
- **`quad_error`와 `type_version_check`가 quad와 같은 버전 번호를 쓰지 않습니다.** 둘은 quad에 묶이지 않은 범용 패키지라 이제 각자의 SemVer로 올라가고, 첫 독립 릴리즈가 **4.0.0**입니다(번호는 이어서 — 옛 3.x는 회수). 각 패키지의 변경은 그 폴더의 `CHANGELOG.md`에 적습니다. `quad_base`·`quad_roblox`·`quad_types`만 계속 같은 번호로 게시되고, 이 둘은 의존성으로 따라 들어오니 소비자가 적을 일은 여전히 없습니다. 둘을 직접 적어 두었다면 `^4.0.0`으로 옮기세요.
- **BREAKING(타입만) — `slot.Length`/`slot.Offset`과 `updateFn`의 `offset` 인자가 `Source<number>`에서 읽기 전용 `State<number>`로 좁혀졌습니다.** 값을 채우는 것은 quad뿐이라 `:Set`을 부르면 조용히 레이아웃이 어긋났는데, 이제 strict에서 막힙니다. `:Get`/`:Compute`/`:Observer`/`:Depend`는 그대로입니다. 옮기는 법: `slot.Length`/`slot.Offset`이나 `updateFn`의 `ctx.Offset`에 `Source<number>`라고 주석을 달았다면 `State<number>`로 바꾸세요(`updateFn`의 인자 모양 변화는 아래 항목).
- **BREAKING — `state:With(...)`가 `state:Depend(...)`로 이름이 바뀌었습니다.** 동작은 그대로(값은 리시버 것, 넘긴 deps가 변할 때도 다시 발행)이고, `:Compute(fn, ...deps)`·`q.Effect(fn, ...deps)`의 deps와 같은 낱말이 됐습니다. `With`는 "값이 따라온다"로 읽히기 쉬웠습니다. 옮기는 법: `:With(`를 `:Depend(`로. 옛 이름은 남기지 않았습니다.
- **BREAKING — `slot:List`/`slot:Single`의 `updateFn`이 위치 인자 다섯 대신 테이블 하나를 받습니다**: `updateFn(ctx)` — `ctx.Item`/`ctx.Index`/`ctx.Offset`/`ctx.Prev`/`ctx.UserData`. `:Single`에도 `Index`가 들어와 같은 `updateFn`을 두 곳에 쓸 수 있습니다. 반환 `(result, userdata)`는 그대로입니다. 호출마다 새 테이블이라 안에서 만든 클로저가 `ctx`를 붙잡아도 안전합니다. 옮기는 법: `function(item, index, offset, prev, ud)`를 `function(ctx)`로 바꾸고 필드로 읽으세요(`:Single`은 옛 `(item, offset, prev, ud)`). **옛 모양은 런타임 에러 없이 틀립니다** — 첫 인자로 `ctx` 테이블이 들어와 `item.label`·`index`가 `nil`인 행을 만들고 `if prev then return prev end` 재사용이 조용히 사라지며, 키가 빠질 때 가서야 `Slot:List: KeyGone accepts only …`로 죽습니다. strict는 잡습니다.
- **BREAKING — `blocker.IsBlocked`와 `blocker:IsOn()`이 `blocker.Blocking` 필드 하나로 바뀌었습니다.** 같은 값을 읽는 길이 둘이었습니다. 진행형인 이유는 "지금 막고 있다"를 뜻하기 때문입니다(과거형은 "막아 낸 적이 있다"로 읽힙니다). 옮기는 법: `blocker:IsOn()`과 `blocker.IsBlocked`를 `blocker.Blocking`으로. `:IsOn()`은 missing method로 죽지만 **`.IsBlocked`는 에러 없이 `nil`**이라 `if blocker.IsBlocked then`이 늘 거짓이 됩니다 — strict는 잡습니다.
- **BREAKING — `tag:Names()`가 없어지고 Tag를 직접 반복합니다**: `for name in tag do`(Luau 일반화 반복 `__iter`, 새 테이블을 만들지 않음). `store:Names()`는 배열을 돌려주는데 `tag:Names()`는 이터레이터라 이름이 같고 모양이 달랐습니다. 옛 호출은 없는 메소드라 즉시 에러가 납니다. 옮기는 법: `for name in tag:Names() do`를 `for name in tag do`로. `pairs(tag)`는 이름을 돌지 않습니다(Luau가 `__pairs`를 `__iter`로 대체).
- **BREAKING(타입만) — `Provider<T>`(Context의 열쇠)가 `T`에 불변이 됐습니다.** 전에는 `Provider<number>`에 문자열을 `ctx:Set` 해도 타입 검사가 통과해 `ctx:Get`의 약속이 깨졌습니다. 이제 넣는 값의 타입이 열쇠와 같아야 하고, `Provider<Frame>`을 `Provider<Instance>` 자리에 넘길 수도 없습니다(`Ref<T>`와 같은 규칙). 런타임 동작은 같습니다. 옮기는 법: 열쇠를 넘겨받는 자리의 타입을 그 열쇠와 같게 적으세요.
- **BREAKING(타입만) — 사용자가 읽기만 하는 상태 필드에 `read`가 붙었습니다**: `Ref`의 `Value`/`Revision`/`Callbacks`/`WeakCallbacks`, `Source.Revision`과 `quad_types`의 `Epoch` 타입의 `Revision`, `Observer`·`Effect`의 `Subscribed`, `Blocker.Blocking`(아래 개명), `AttrKey`의 `Name`, `Timeout._native`. 런타임 동작은 같습니다. 옮기는 법: 이 필드에 직접 대입하던 코드는 `ref:Set(v)`, `:Subscribe()`/`:Unsubscribe()`, `blocker:On()`/`:Off()` 같은 메소드로 바꾸세요.
- **BREAKING** — `q.Operator`의 `Sum`/`Product`/`Min`/`Max`/`Band`/`Bor`/`Bxor`가 값이 `nil`인 `State` 인자를 조용히 건너뛰고 나머지만 계산하던 것(`Clamp`/`Shl`은 내부 에러) — 읽는 시점에 `Operator.Sum: argument #N is a State whose current value is nil …`로 던집니다.
- **BREAKING — `q.Context`가 인자를 받지 않습니다.** `q.Context({ [P] = v })`처럼 초기값을 넘기면 전에는 조용히 버려 나중 `:Get(P)`에서 엉뚱한 에러로 죽었습니다 — 이제 호출 줄에서 `Quad0255`로 거부합니다. 옮기는 법: `q.Context()`로 빈 가방을 만들고 `ctx:Set(provider, value)`로 채우세요.
- **BREAKING — `q.Animate`의 `CanAnimate`는 불리언(또는 불리언 `State`)만 받습니다.** 불리언이 아닌 값(`"no"`·`0`·함수)은 전에는 참으로 취급돼 조용히 늘 애니메이션했습니다 — 이제 `Quad0253`으로 거부합니다(`State`가 쥔 값은 실행 때 `Quad0254`, `nil`은 생략과 같음). 옮기는 법: `CanAnimate = flag ~= nil`처럼 불리언으로 바꿔 넘기세요.
- **BREAKING — `q.Animate`의 콜백(`Started`/`Completed`/`Cancelled`)에 `State`를 줄 수 없습니다.** 전에는 애니메이션할 때는 동작하고 `CanAnimate = false`일 때만 `Quad0246`으로 죽었습니다 — 문서와 타입대로, 이제 `Animate{ … }` 호출 줄에서 늘 `Quad0246`으로 거부합니다. 옮기는 법: 콜백은 함수로 넘기고, 바뀌는 동작이 필요하면 그 함수 안에서 `State`를 읽으세요.
- **BREAKING — 이미 마운트된 트리에 `:List`/`:Single` Slot을 넣을 때, 그 첫 `updateFn`(또는 그때 동기로 발화하는 `Observer`)이 막는 범위가 바로 위 부모에서 맨 위까지의 조상 Slot 전부로 넓어졌습니다.** 전에는 조부모 이상의 `Remove`/`Clear`가 통과해 유령 자리를 남겼습니다 — 이제 `Quad0167`입니다. 그 창 안에서 무엇이든 던지면 그 사슬의 Slot 전부가 이후 CRUD를 `Quad0167`로 거부합니다(전에는 바로 위 부모만 — 사용자 코드의 예외를 복구하지 않는 계약). 옮기는 법: 조상 Slot은 마운트가 끝난 뒤, `updateFn` 밖에서 바꾸세요(Roblox라면 `task.defer`).
- **BREAKING — `mod:Field(fn)`의 변환 함수가 함수를 돌려주면 setter 줄에서 거부합니다**(`Quad0264`). 전에는 생 함수가 필드에 들어가 이벤트 이름 필드라면 핸들러로 연결됐습니다 — 초기 필드 테이블로 같은 값을 넣으면 이미 `Quad0063`으로 거부되던 것과 맞췄습니다. 옮기는 법: 이벤트 핸들러는 Modifier가 아니라 Declaration의 인라인 키로 넘기세요(꼭 Modifier에 담아야 하면 `State`로 감싸세요).
- **BREAKING(프로바이더·핸들러 작성자) — `q.Backend.bindLifetime`/`unbindLifetime`이 원시값(숫자·문자열·불리언·buffer·thread)을 거부합니다**(`Quad0265`). 전에는 통과해 무관한 두 바인딩이 같은 값으로 부딪치거나 백엔드 부기 자리를 덮을 수 있었고, `NaN`이면 VM 에러였습니다. 옮기는 법: 수명을 묶을 값은 테이블·함수·userdata로 넘기세요(원시값을 쥔 테이블이나 클로저를 묶으세요).

- **BREAKING — `state:Observer(fn)`가 첫 발화 전에 구독자 집합에 합류합니다.** 그래서 첫 발화 도중 대상이 바뀌면(콜백이 자기 대상을 `:Set`하든, 콜백이 깨운 다른 코드가 바꾸든) 그 변경은 버려지지 않고 보류됐다가, 핸들이 묶이거나 구독될 때 콜백이 **한 번** 더 돌며 반영됩니다(첫 발화 안에서 다시 돌지는 않습니다 — 그래서 게시 전 잠깐 있던 첫 발화 반복 한도 `Quad0262`도 폐기됐습니다; 아래 Fixed의 유실이 이것으로 고쳐졌습니다). 전에는 그 변경이 버려졌습니다. 첫 발화 도중 대상을 바꾸는 것 자체는 콜백이 자기 상류를 되먹이는 것이라 정의되지 않은 동작입니다(위 문서 항목). 첫 발화의 콜백이 던지면 그 핸들은 상류의 구독자 집합(약한 참조)에 남았다가 수거되며, 그동안 콜백은 돌지 않습니다. 옮기는 법: 첫 발화에서 대상을 되쓰는 콜백은 `Effect`로 옮기거나, 범위 강제는 값을 받는 자리에서 깎아 `:Set`하세요.
- `Source`를 직접 관측하는 `Observer`와 `Source`·`Ref`를 의존성으로 둔 `Effect`가 **같은 변경으로 두 번 돌지 않습니다** — 파동 도중 다른 콜백이 핸들을 구독·바인딩해 보류분 재생이 먼저 돈 경우, 그리고 (`Observer`) 다른 콜백이 같은 `Source`를 다시 `:Set`해 안쪽 파동이 먼저 닿은 경우에 뒤늦은 같은 통지를 건너뜁니다. 파생 State(`:Compute` 등)를 거쳐 관측하는 핸들은 이 경우 전처럼 같은 값으로 한 번 더 돌 수 있습니다. 통지 횟수가 아니라 값에 기대던 코드는 영향이 없습니다.
- `q.Effect`가 State·Source 의존성마다 따로 만들던 내부 구독 핸들이 없어져 `Effect`를 만드는 비용과 메모리가 줄었습니다.
- 문서에 명시: `Effect`의 첫 실행 `fn` 안에서 부른 `Rerun()`(또는 의존성 `:Set`)은 구독·바인딩 전이어도 보류되지 않고 그 실행이 끝난 자리에서 한 번 더 돕니다(동작은 전부터 이랬고, 레퍼런스가 "보류"라고 잘못 적고 있었습니다). 살아 있는 `Observer`의 콜백이 자기 대상을 되쓰는 것(clamp 등)은 정의되지 않은 동작입니다 — 지금은 콜백 안에서 재귀로 한 번 더 돌고 바깥 콜백의 나머지 부분이 옛 값으로 이어지는 것이 관측되지만 약속이 아닙니다. 되써서 바로잡아야 하면 `fn`이 끝난 뒤로 미루는 `Effect`를 쓰세요.

### Fixed

- 설치된 프로바이더가 붙인 브랜드의 값(예: `Tween`)이 맞는 핸들러를 찾지 못할 때, "프로바이더가 초기화됐는지 확인하라"는 엉뚱한 힌트 대신 quad 값용 힌트(숫자 키 자리로 옮기라 / 이 자리에 받을 핸들러가 없다)를 보여 줍니다.
- `state:Observer(fn)`의 첫 발화 도중 일어난 대상 변경이 유실되던 것 — 전에는 콜백이 옛 값에 머물고 구독·바인딩한 뒤에도 재생되지 않았습니다. 이제는 보류됐다가 구독·바인딩할 때 한 번 재생됩니다(위 Changed). 같은 원인의 증상 둘도 사라집니다: 형제 Slot의 `Offset`을 관측하는 콜백이 막 붙는 Slot 서브트리에 원소를 더하면 뒤 형제의 `Offset`이 에러 없이 옛 값에 남던 것(Slot의 `Offset`/`Length`를 보는 콜백의 CRUD가 그 값으로 다시 돌아오는 고리는 Slot이 스스로 다시 계산해 맞추는 정의된 경로입니다), 그리고 `:List`의 `updateFn`이 만든 원소의 `OnChange`가 마운트 중에 동기로 발화해(Immediate 시그널) `data`를 `:Set`하면 그 변경이 목록에 반영되지 않던 것(지금은 첫 재조정이 끝난 뒤 새 데이터로 한 번 더 재조정되는 것이 관측됩니다 — 다만 `updateFn`이 만든 원소가 그 목록의 `data`를 바꾸는 것은 여전히 정의되지 않은 동작이라 보장하지 않습니다).
- 게이트(`Blocker`·`state:Gate`, 그 위의 `Debounce`/`Throttle`)가 막고 있는 동안 만든 `Effect`가 그 게이트 뒤의 State를 의존성으로 두면, 게이트가 풀릴 때의 통지를 놓치던 것 — 이제 한 번 더 돕니다(막기 전에 만든 `Effect`와 같습니다; 값은 첫 실행 때와 같을 수 있습니다).
- `ref:Wait(thread)`로 등록해 둔 코루틴이 그 사이 끝났거나 `coroutine.close`로 닫혔으면 이제 `:Set`이 그 대기자를 건너뜁니다. 전에는 그런 대기자 때문에 `:Set`이 번호 없는 `cannot resume dead coroutine`으로 던지고 나머지 콜백을 건너뛰었습니다. (한 코루틴을 여러 Ref에 거는 조율은 quad가 정의하지 않습니다 — 위 Changed의 문서 항목.)
- `q.Debounce`/`q.Throttle`의 `Time`/`MaxTime`에 `math.huge`를 주면 통과해 게이트가 `Flush` 전까지(Throttle은 첫 통과 뒤 영원히) 값을 붙들던 것 — 이제 음수·NaN과 같이 거부합니다(`Quad0041`, State가 쥔 값은 신호 때 `Quad0039`). 두 에러는 받은 값이 숫자면 타입 대신 그 값(`got -1`·`got inf`)을 보여 주고, `setTimeout`의 `Quad0216`도 같은 꼬리(`got -1`·`got nan`)를 씁니다 — 단 `setTimeout`은 `math.huge`를 여전히 받습니다.
- `Slot`에 넣은 `State`의 값 사슬이 자기에게 돌아오면(`st:Set(st)`, `a`가 `b`를·`b`가 `a`를 담음) 스택 오버플로로 죽고 그 Slot이 굳던 것 — 이제 `q.debug`가 켜져 있으면 프로퍼티 자리와 같은 `Quad0070 State: the value chain is circular …`로 그 `:Set`(또는 넣는) 줄에서 거부하고, 그 뒤 Slot의 상태는 정해져 있지 않습니다(지금은 이전 원소를 보인 채 다음 `:Set`에서 이어지는 것이 관측됨 — 계약 아님). 사슬을 끝까지 따라가는 검사라 debug 층에 둡니다 — 꺼져 있으면 전처럼 스택 오버플로로 끝나는 정의되지 않은 동작입니다.
- `Modifier`의 필드에 `Claim`/`Mapper` 디스크립터를 넣으면 그 `Modifier`를 만드는 줄에서 `Quad0057`/`Quad0064`로 거부합니다(전에는 적용할 때 `Quad0076`).
- `q.Bookkeeping.setLength`에 값이 잘못된(음수 등) `State`를 넘기면 에러는 났지만 길이 목록을 이미 쓴 뒤라 오프셋이 조용히 어긋나고 그 자리가 다시는 움직이지 않던 것 — 이제 부기를 쓰기 전에 그 `State`의 현재 값을 검사합니다(`Quad0021`).
- `q.Animate{ … }`를 `State`가 아닌 곳(`mod:Apply`·`tag:Apply`·필드가 비었거나 평범한 값인 Modifier setter의 변환 함수 자리)에 붙이면 quad 내부 줄에서 VM 에러(`attempt to index nil with 'Get'` 등)로 죽던 것 — 이제 `Quad0252 Animate: Apply target must be a State …`로 거부합니다.
- 생성 Modifier setter(`D.Modifier.Frame():LayoutOrder(x)` 등)에 `nil`이나 `number?` 같은 옵셔널 값을 넘기는 호출이 strict에서 타입 에러였던 것 — 문서대로 `nil`은 "그 필드 없음"으로 받습니다(생성자 테이블 `D.Modifier.Frame({ LayoutOrder = maybe })`와 같은 동작). 런타임은 원래 받았습니다.
- `fn`이 던져 죽은 `Effect`를 `:Unsubscribe()`/`:WeakUnsubscribe()`로 놓아줄 수 있습니다. 전에는 죽은 핸들의 네 진입점이 전부 `cannot change subscription from inside fn or cleanup`으로 거부돼 강한 구독이 그 핸들과 상류를 모듈 수명 동안 붙들었습니다. `Observer`도 같습니다 — 콜백이 던져 굳은 핸들을 해제할 수 있고, 굳은 핸들은 (재)구독·재바인드만 막히지 발화는 계속된다는 것을 문서가 바로 적습니다. 부수로 콜백 안에서 자기를 해제하는 것도 됩니다(해제는 콜백을 다시 부르지 않습니다).
- `Effect`의 `fn`이 도는 동안 핸들이 실행 자격을 잃으면(fn 안에서 자기를 해제했거나, `fn`이 yield하는 사이 묶인 인스턴스가 죽거나 자리에서 내려간 경우) `fn`이 돌려준 cleanup을 저장하지 않고 **즉시 소진**합니다(인스턴스 죽음이 원인이면 `dying = true`). 전에는 그 cleanup이 아무도 소진하지 않는 핸들에 남아 조용한 영구 누수였습니다. `fn` 안 yield는 여전히 정의되지 않은 동작이지만, 가장 흔한 실수(네트워크 왕복 뒤 연결)의 결과가 "누수"에서 "정리됨"으로 바뀝니다.

- 정적 자식 자리에 그 부모 자신이나 조상을 넣으면(`src:Set(host)`) 엔진의 순환 에러로 죽던 것 — 이제 `Dispatch: cannot place an Instance inside itself or one of its own descendants …`로 거부합니다(Slot의 같은 규칙과 짝; `State` 자리라면 옛 자식은 거부 전에 이미 내려가 있습니다 — 위 두 거부와 같습니다).
- `Debounce`/`Throttle` 게이트 핸들의 `Flush`가 던질 때(백엔드 미설치) blame이 내부 파일이던 것 — 사용자 줄로.
- `q.Claim`이 자식 키 부재·클래스 불일치·디스크립터 재사용·같은 자식으로 해석되는 디스크립터 둘로 실패할 때 루트와 앞선 형제가 이미 claim된 채 남아, 키를 고친 재시도가 진짜 원인 대신 `nativeClaim: Instance is already claimed by quad`로 죽던 것 — 이제 트리 전체를 먼저 해석한 뒤에 루트부터 claim하고 아래에서 위로 적용하므로 그런 실패(그리고 이미 claim된 루트)는 아무것도 남기지 않습니다. 적용 단계에서 던지는 경우는 전과 같습니다.
- `q.Modifier({ __apply = … })`처럼 `__`로 시작하는 이름을 초기 필드로 주면 조용히 만들어졌다가 나중에 `Dispatch: no handler matched key __apply`로 죽던 것 — 이제 생성 줄에서 `Modifier: field "__apply" starts with "__" …`로 거부합니다(setter 경로와 같은 규칙).
- `slot:List`의 `data`에 배열이 아닌 테이블(id로 키잉한 맵, 디코드한 JSON 오브젝트, 해시 키가 섞인 배열)을 주면 에러 없이 목록이 통째로 비워지고 원소가 파괴되던 것 — 이제 `Slot:List: data must be a plain array - key "…" is not an array position`으로 거부하고 아무것도 건드리지 않습니다(생성자 `initial`과 같은 규칙). `updateFn`이 `q.KeyGone`을 돌려주면(`nil` 대신) 안내 문구로 거부합니다.
- 서로를 담은 `State` 사슬(`a:Set(b); b:Set(a)`, `s:Set(s)`)을 자리에 놓으면 내부 파일을 가리키는 stack overflow로 죽던 것 — 이제 `q.debug`가 켜져 있으면 `State: the value chain is circular …`입니다(emit마다 사슬을 따라가는 검사라 debug 층 — 꺼져 있으면 전처럼 stack overflow로 끝나는 정의되지 않은 동작).
- Roblox 기본 Deferred 시그널 모드에서, 인스턴스가 파괴된 뒤 **같은 프레임 안에** 같은 `Effect`/훅 핸들을 다른 인스턴스에 다시 놓으면(행 캐시가 핸들을 재사용하는 목록) 옛 인스턴스의 지연된 Destroying 콜백이 새 바인딩을 끊어 cleanup이 살아 있는 인스턴스에서 돌고 그 뒤 fn이 영영 다시 안 돌던 것 — 이제 더 이상 자기 것이 아닌 바인딩의 콜백은 무시됩니다.
- 모듈에 `is`로 시작하는 평범한 헬퍼(`q.isEmpty`, `q.isNonEmptyList`, 인자를 무시하는 플러그인 `isMobile`)가 얹히면 그 뒤로 모든 `D.<Class>{}`가 `Dispatch.drive: props must be a plain { ... } table …`로 죽던 것 — 이제 브랜드 스캔은 `q.BrandPredicates`에 등록된 술어만 보므로 등록되지 않은 헬퍼는 무시됩니다.
- 숫자 키 자리에 묶였던 `Effect`의 호스트가 파괴된 직후 같은 프레임 안에서 `:Subscribe()`/`:WeakSubscribe()`로 되살리면, 뒤늦게 배달되는 `Destroying`(Deferred 시그널 기본값)이 살아 있는 구독의 cleanup을 소진하고 fn을 영영 멈추게 하던 것 — 이제 되살릴 때 옛 연결을 끊어 그 콜백을 무시합니다.
- `tostring(store)`가 `rawset`으로 넣은 숫자 키가 섞여 있으면 "attempt to compare string < number"로 던지던 것 — 이제 키를 문자열로 비교해 항상 찍힙니다.
- `Context`/`Provider` 값을 `Declaration` 자리에 잘못 놓으면 "프로바이더가 초기화됐는지 확인하라"는 엉뚱한 안내가 붙던 것 — 이제 `Store`처럼 "어느 키에도 그대로 놓이지 않는다 — 필요한 값을 먼저 읽어 내라"는 안내가 나옵니다(전에 이 항목이 말했던 "숫자 키 자리에 두라"는 따라가면 같은 에러가 다시 나는 안내였습니다).
- `Frame { Children = slot }`·`Frame { Ref = ref }`처럼 Slot/Ref를 문자 키 값으로 주면 "프로바이더가 초기화됐는지 확인하라"는 엉뚱한 안내가 나오던 것 — 이제 매치 실패 에러(`Quad0076 … brand: …`)가 "a quad value at a string key: it belongs in a numeric (array) slot"(숫자 키 자리에 두라)로 안내합니다 — 다른 quad 값(Tag 등)도 같은 문구입니다.
- 핸들러 작성자용: `q.Dispatch.process`에 체인 길이보다 큰 `index`를 주면 어떤 철거도 닿지 않는 슬롯이 남고 체인 기록까지 풀리던 것 — 이제 `index {n} would leave a gap in the chain …`으로 거부. `process`/`retractFrom`의 `nil` 키, `addHandler`의 NaN/무한 `priority`, `newMapperClass`의 비문자열 이름도 각각 즉시 거부하고, 같은 핸들러 테이블을 두 번 등록하면 한 번만 등록됩니다. `q.Dispatch.getHandler`도 같은 검사를 받아, `inst`에 `nil`을 넘기면 다른 파일을 가리키는 VM 에러 대신 `process`와 같은 quad 메시지로 거부합니다.
- `q:RunInit(nil)`/`RunInit(5)`가 내부 파일 줄로 죽던 것 — `RunInit: initFn must be a function …`.
- 숫자 키 자리에서 내려가는 `Ref`의 `:Wait()` 대기자가 그 자리에서 던지면(`ref:Wait():Unwrap()`이 철거의 nil에 깨어남) 같은 Ref를 되꽂아도 영영 채워지지 않던 것 — 지금은 되꽂으면 채워집니다(대기자가 던진 뒤의 동작이라 관측이지 계약은 아닙니다).
- `state:Apply(modifier)`처럼 Modifier를 `Apply` 팩토리 자리에 넣으면 조용히 통과해 `__apply` 필드가 박힌 Modifier가 만들어지고 한참 뒤 `Dispatch: no handler matched key __apply`로 죽던 것 — 이제 `Apply`가 다른 비팩토리 값과 같은 문구로 그 자리에서 거부합니다(Modifier는 `__`로 시작하는 이름에 setter를 만들지 않습니다).
- `q.Operator.Clamp`의 두 경계가 엇갈리거나(`min > max`) `NaN`이면 내부 파일을 가리키는 `math.clamp` 에러가 나던 것 — 이제 읽는 줄에서 `Operator.Clamp: min must be <= max and neither NaN …`입니다. `q.Operator.Indexed`에 State를 키로 주면 영원히 `nil`만 읽던 것 — 이제 팩토리 줄에서 거부합니다(키는 반응형이 아닙니다).
- 프로퍼티 자리의 체인을 철거해도(숏핸드 `UICorner = …`를 `nil`로 내려 관리 자식을 파괴할 때, `q.Dispatch.retractFrom`) 진행 중인 엔진 Tween이 취소되지 않고 그 키의 Tween 기록이 남아, 파괴된 자식을 향해 Tween이 돌고 철거 뒤 같은 목표값의 Tween을 다시 선언하면 통째로 무시되던 것 — 이제 철거 때 진행 중이던 Tween을 취소합니다. "첫 설정은 스냅" 규칙의 기준은 **quad가 그 인스턴스의 그 프로퍼티를 처음 쓰는가**이고, 철거나 자리의 값 종류 변경(plain 값 ↔ `State`, `q.None` 경유)은 그 기록을 지우지 않습니다 — 그 뒤의 Tween은 애니메이션합니다. 철거 순간 Tween이 돌고 있었다면 그 목표값만 잊어 같은 목표를 다시 선언해도 재생됩니다(프로퍼티가 중간값에 멈춰 있으므로). 값 교체 때의 동작(`Override`)은 그대로입니다 — 한 가지: 자리의 값 종류가 바뀌는 교체가 Tween 도중에 일어나면 새 Tween의 `Override = "Finish"`는 옛 목표로 스냅하지 않고 중간값에서 이어갑니다.
- `q.OnDestroyed(fn)`을 `State` 자리에 담아 `q.None`으로 뺐을 때 인스턴스가 살아 있는데 `fn`이 돌고, 되꽂은 뒤 파괴하면 통틀어 두 번 돌던 것 — 이제 죽을 때 정확히 한 번만 돕니다(자리를 떠날 때는 돌지 않고, 뺀 채로 죽으면 돌지 않습니다).
- 중첩 `:List`/`:Single`의 `updateFn`이 첫 마운트 중에 조상 Slot을 CRUD하면 내부 에러(`bindLifetime: value is already bound`)로 죽고 그 트리의 부기가 영구히 깨지던 것 — 이제 그 자리에서 `Slot: cannot mutate a Slot while it is being mounted …`로 거부합니다(`updateFn`은 항목을 원소로 바꾸는 함수이고, 조상은 마운트 뒤 Observer에서 바꾸세요). 자기 자식 Slot을 채우거나 마운트 뒤에 조상을 바꾸던 코드는 영향이 없습니다.
- 핸들러 작성자용: `q.Dispatch.process(inst, 0, child, 1)`처럼 양의 정수가 아닌 숫자 키로 자식·Slot을 직접 넣으면 전에는 소유권 자리가 먼저 잡힌 뒤 위치 검사에서 던져 그 값이 영영 "already mounted"로 남았습니다 — 이제 아무것도 남기지 않고 거부합니다 — Slot도 Instance 자식도 그 핸들러가 그런 키에 매치되지 않아 `Dispatch: no handler matched key …`(`q.Dispatch.drive`는 원래 거부했습니다).
- `Effect`의 cleanup 안에서 의존성을 `:Set`하면 뒤따르는 `fn`이 그 값을 읽고도 (cleanup, fn) 사이클이 같은 입력으로 한 번 더 돌던 것 — 이제 한 사이클입니다. `fn` 안의 `:Set`이 한 번 더 돌게 하는 것은 그대로입니다.
- `Debounce`/`Throttle`의 `Time`이 `State`일 때 그 값이 잘못돼 신호가 창을 못 열면(음수·문자열, 또는 시간 op가 없는 백엔드) 게이트가 "막힘 상태인데 타이머 없음"으로 굳어 다음 신호까지 통지가 멈추던 것 — 창을 먼저 잡고 상태를 바꾸도록 순서를 고쳐, 그 `:Set` 줄에서 던지고 게이트는 그대로 둡니다. `MaxTime`도 신호가 들어올 때 상태를 바꾸기 전에 읽어, 잘못된 값이면 그 `:Set` 줄에서 던집니다. 던진 뒤의 게이트 상태는 관측이지 계약이 아닙니다 — 지금은 새 창은 열리지 않고, 그 신호는 leading이면 이미 통과했고 아니면 게이트의 보류분에 남아 다음 통과에 실려 나갑니다. 창 끝 통과 뒤나 `Flush` 뒤 다시 여는 창은 전처럼 그때 `Time`을 읽으므로, 그 사이 값이 잘못되면 타이머 콜백이나 그 `Flush` 줄에서 던집니다(그 뒤 상태도 관측 — 계약 아님).
- `Claim`의 매퍼 키가 트리에 없을 때 내부 파일 이름으로 죽던 것 — `Claim: no child matched key … under …`로 키를 말합니다. 이름은 맞는데 **클래스가 다른** 자식(`M.TextLabel("Kid")`인데 실제로는 `ImageLabel`)도 이제 같은 에러입니다 — 전에는 props가 겹치면 조용히 통과해 잘못된 타입의 핸들을 돌려줬습니다(하위 클래스는 `IsA`로 통과). **BREAKING(프로바이더 작성자)** — `nativeFindChild(inst, key, className?)`에 셋째 인자가 생겼습니다. 그 클래스가 아닌 자식이면 `nil`을 돌려주세요.
- `Modifier` 초기 필드에 함수를 넣었을 때의 안내가 이벤트 핸들러를 변환 함수 자리로 이끌던 것 — 이벤트는 Modifier에 두지 않고 선언의 인라인 키나 `State`로 넣으라고 안내합니다.
- 다른 quad 모듈 인스턴스가 만든 `Slot`을 `Slot`의 원소 자리(`Add`/생성자/`Replace`/`Extract`/`Splice`, `State`에 담아서, `:List`의 반환값으로)에 넣거나 `q.dispose`에 넘기면 이제 거부합니다 — 전에는 통과해 다른 인스턴스의 트리를 조용히 망가뜨릴 수 있었습니다(같은 자리의 `State`도 같은 문구로 거부합니다; `State`에 담은 것은 그 값을 정착시킬 때 — 마운트·값 변경 때 — 거부합니다).
- `q.Blocker()`를 `__apply`로 State가 아닌 값에 걸면 내부 에러가 나던 것 — `Blocker: Apply target must be a State …`.
- `Animate`가 건 `State`에 `Tween`이나 `State`를 넣었을 때 나는 검증 에러가 quad 내부 줄(`Animate.luau`)을 가리키던 것 — 호출한 줄을 가리킵니다.
- `Observer`·`Compute` 같은 콜백 안에서 부른 `q.Claim(...)`의 인자·모양 검사 에러가 그 `q.Claim` 줄이 아니라 콜백을 깨운 바깥 줄(`:Set` 등)을 가리키던 것 — 이제 다른 인자 검증처럼 `q.Claim`을 부른 줄을 가리킵니다.
- 인자 모양을 검사하지 않던 입구에 검사를 넣었습니다(전부 호출한 줄을 가리킵니다): `Dispatch.process`/`retractFrom`의 `index`(양의 정수), `Modifier:Apply`의 factory(함수), `slot:List`/`:Single`의 `opts`(테이블 — 문자열은 조용히 무시됐습니다), `AddPlugin`/`UseProvider`의 인자(함수)와 반환값(확장 테이블). `UseProvider(nil)`이 아무 일도 없이 성공하던 것도 이제 에러입니다.
- 검증에 실패한 CRUD 호출(`Add(nil)` 등)이 Slot을 수동 모드로 표시해 뒤의 `:List`가 "CRUD를 썼다"고 거부하던 것 — 실제로 바꾼 호출만 표시합니다.
- `Replace(i, slot:Get(i))`를 하면 "같은 원소가 두 번"이라던 것 — "이미 이 Slot에 있다(두 번째 마운트), Move/Swap을 쓰라"로 바르게 말합니다. `keyFn`이 NaN을 돌려주면 nil과 같은 도메인 에러입니다.
- strict 타입 검사가 조용히 꺼져 있던 자리 둘을 고쳤습니다: `q.Debounce`/`q.Throttle` 옵션의 `Time`·`MaxTime`(아무 값이나 통과했습니다)과 `q.Operator`의 계산 함수들이 돌려주는 타입(`s:Apply(q.Operator.Sum(1))` 결과가 무엇에든 대입됐습니다). 원인은 타입 선언 순서였고 런타임 동작은 같습니다. 이제 `Time = "x"` 같은 값은 타입 에러가 나며, 옵션의 State 자리는 `StateMarker<number>`로 선언됩니다(진짜 `State<number>`를 그대로 넘기면 됩니다).

---

## [3.2.0] - 2026-09-14

### Changed

- **BREAKING — `q.D`가 `q.Declaration`으로 이름이 바뀌었습니다.** 자동완성에서 `q.` 뒤에 뜻이 보이고, 한 글자 이름이라 코드 검색에 안 잡히던 문제가 사라집니다. 옮기는 법: 파일마다 받는 별칭 한 줄만 고치면 되고(`local D = q.Declaration`), 본문의 `D.Frame {…}` 표기는 그대로입니다 — 별칭 이름은 여러분이 원하는 대로 지어도 됩니다. 옛 `q.D`는 남기지 않았습니다.
- **BREAKING — 타입 이름 셋도 같이 바뀌었습니다**: `D` → `Declaration`, `DMapper` → `DeclarationMapper`, `DModifier` → `DeclarationModifier`. 클래스별 타입이 사는 생성 모듈의 하위 경로도 `D` → `Declaration`입니다(`require`로 그 모듈을 직접 가져다 쓰는 경우에만 해당).

## [3.1.0] - 2026-09-11

### Changed

- `slot:Single`의 타입이 `:List`와 같은 `<Item, UD>`가 됐습니다 — 구동 `state`가 데이터(`Item`)라 원소 타입에 묶이지 않습니다. `Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 코드가 이제 strict를 통과합니다(런타임 변화 없음).
- **BREAKING — `q.Operator.Index`가 `q.Operator.Indexed`로 이름이 바뀌었습니다.** 동작·시그니처는 그대로(`state:Apply(q.Operator.Indexed<<V>>("Key"))`, `V`는 인덱스된 값의 타입) — 호출부의 이름만 바꾸면 됩니다. 픽 함수를 직접 받는 일반형(`Indexer`)은 타입 추론이 가능해지면 따로 추가할 예정이라 이름을 미리 갈라 두었습니다.
- 숫자 키 자리 중간에 `nil`이 있을 때 나는 에러 문구가 먼저 그 가능성을 묻습니다 — `Dispatch.recompute: sourceList[N] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; …`(뒤는 핸들러 작성자용 힌트 그대로). 동작 변화 없음.

### Fixed

- `type_version_check`의 `CheckVersion` type function에서 `pcall`을 없앴습니다. luau-lsp(신 솔버)가 `Unknown global 'pcall'` 진단을 내던 것이 사라집니다. 값 여부는 `tag == "singleton"`으로 봅니다(판정 규칙은 그대로).

## [3.0.0] - 2026-09-10

**BREAKING — 처음부터 다시 쓴 별개 라이브러리입니다.** 3.x는 quad v1과 API 호환이 없고, 패키지 이름과 설치 경로도 다릅니다. 아래 목록은 v1의 마지막 릴리즈인 **2.24를 기준으로** 무엇이 생기고, 바뀌고, 없어졌는지입니다. 옮기는 절차는 [quad v1에서 v2로 옮기기](/how-to/08-migrating-from-v1/), 없앤 이유는 [quad v1에서 오는 분께](/overview/02-from-v1/)에 있습니다. v1은 `master` 브랜치와 GitHub 릴리즈(rbxmx)에 그대로 남습니다.

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

아래는 이름의 대응입니다. 콜백 인자, 발화 시점, 우선순위 같은 동작 차이는 [quad v1에서 v2로 옮기기](/how-to/08-migrating-from-v1/)가 다룹니다.

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
- **Changed** — 같은 커밋(`5c646f7`)에서 프로퍼티 트윈이 `Ended`/`OnStepped` 콜백을 `Tween`에 넘기던 래퍼 두 개가 주석 처리됐습니다. 이 커밋 이후로는 프로퍼티 자리에 준 트윈 옵션의 `Ended`/`OnStepped`가 호출되지 않습니다. 의도된 변경인지는 커밋 메시지로 알 수 없어 그대로 적어 둡니다.

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
