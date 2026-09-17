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

- `q.Bookkeeping.claimOwnerAt(element, inst, k)` / `q.Bookkeeping.releaseOwner(element, ownerKey)` — 숫자 키 자리에 값을 놓는 핸들러가 "이 값은 이 자리에 앉아 있다"를 등록·해제하는 소유권 op. `Slot`이 원소에 쓰던 그 레지스트리 하나를 정적 자식·숏핸드 관리 자식과 같이 씁니다. 자기 핸들러가 자식을 부모에 붙인다면 이 둘을 불러야 아래 단일 마운트 규칙에 들어갑니다.

- 백엔드 계약 op `isClaimed(inst)` — "이 요소가 이미 quad 소유인가". `Slot`이 원소를 받을 때와 정적 자식 자리마다(구동 hot path) 부릅니다. **BREAKING(프로바이더 작성자)** — 자기 백엔드를 만든 쪽은 이 op를 설치해야 합니다(quad-roblox는 claim 셋업 유무, mock은 항상 참). 앱 코드에는 영향이 없습니다.

- `quad_roblox` 패키지 루트가 프로퍼티 값 타입 `Field<T>`(setter가 받는 값)와 `FieldOut<T>`(변환 함수의 `old`·`Peek`이 돌려주는 저장된 값)를 내보냅니다. 전에는 생성 모듈 경로로만 닿았는데, pesde 설치에서는 그 경로가 드러나지 않았습니다. 클래스별 타입도 같은 루트에서 내보냅니다 — `<Class>Modifier`(상위 클래스 포함), `Into<Class>`, `<Class>Elem`. how-to의 `require(<생성 모듈 경로>)` 자리표시자는 이 경로로 바뀌었습니다.

- `q.moduleIdentity` — 모듈 인스턴스마다 하나인 빈 identity 토큰. 백엔드·플러그인이 자기 값에 붙여 두고 "이 인스턴스가 만든 값인가"를 비교하는 데 씁니다(quad-base가 아래 인스턴스 교차 검사에 같은 방법을 씁니다).

- `q.debug`가 켜져 있을 때 `q:AddPlugin`이 모듈의 기존 필드를 덮어쓰면 설치 시점에 한 줄을 출력합니다. 덮어쓰기 자체는 그대로 허용됩니다(코어 부품을 일부러 갈아 끼우는 플러그인용). `UseProvider`는 해당 없음.
- `q.debug`가 켜져 있으면 옵션 테이블의 모르는 키(오타·옛 이름)를 한 줄로 알립니다 — `q.Debounce`/`q.Throttle`, `slot:List`/`slot:Single`의 `opts`, `q.Tween`, `q.Animate`. 경고만 하고 실행은 계속합니다(모르는 키는 전처럼 무시).

### Changed

- **BREAKING — `Slot`이 quad 밖에서 만든(claim되지 않은) 인스턴스를 더는 원소로 받지 않습니다.** 전에는 조용히 들어갔고 죽음 추적이 없어 밖에서 `Destroy`되면 Slot이 stale해졌습니다. 이제 `Add`·생성자·`Replace`·`Extract`·`Splice`·`List`/`Single`이 `Slot: this element is not claimed by quad …`로 거부합니다(`State`에 담긴 원소도 그 현재값으로 미리 검사합니다). `List`/`Single`의 `updateFn`이 그런 원소를 돌려주면 재조정 도중의 예외라 그 Slot은 더 이상 재조정되지 않습니다 — 원소를 만들 때 claim하세요. 옮기는 법: 그 인스턴스를 먼저 `Claim`으로 넘겨받거나 `Declaration`으로 만드세요 — Slot이 대신 claim하지 않습니다. **정적 자식 자리도 같습니다** — `D.Frame { Instance.new("TextLabel") }`처럼 숫자 키에 놓은 미claim 인스턴스는 `InstanceChild: this Instance is not claimed by quad …`로 거부됩니다. 그 자리의 `State<Instance?>`를 나중에 미claim 인스턴스로 `:Set`하는 경우도 같은 거부인데, 이때는 옛 자식이 이미 내려간 뒤(체인 철거 뒤 새 값 처리)라 그 자리는 빈 채로 남습니다.

- **BREAKING — 정적 자식과 숏핸드 관리 자식도 "한 값은 한 자리" 규칙 안에 들어갑니다.** 전에는 같은 Instance를 `D.Frame { c }` 둘에 놓으면 에러 없이 둘째가 가져가고 첫째의 자리 부기는 남아, 첫째가 자리를 내릴 때 살아 있는 둘째 트리에서 그 자식을 뜯어냈습니다. `{ c, c }`도 통과했고, 정적 자식을 `slot:Add`하거나 `q.dispose`하는 것도 막히지 않았습니다. 이제 둘째 자리는 `Bookkeeping.claimOwnerAt: this element is already mounted elsewhere …`로 거부되고(첫째 트리는 그대로), 앉아 있는 자식은 `q.dispose`가 `dispose: this value is still held by a Slot or a mounted position …`로 거부합니다. `UICorner = 8` 같은 숏핸드가 만든 관리 자식(`_quad_round`·`_quad_padding`·`_quad_scale`)도 같습니다 — 전에는 `q.dispose`가 조용히 파괴한 뒤 다음 값 발행이 파괴된 인스턴스에 써졌습니다. 옮기는 법: 한 Instance를 다른 자리로 옮기려면 먼저 그 자리에서 내리세요(자리를 쥔 State를 `:Set(nil)`, Slot이면 `Extract`). 두 곳에 같은 모양이 필요하면 Instance를 둘 만드세요. 제대로 돌던 코드는 영향이 없습니다 — 이 변경은 원래 막혔어야 할 것을 막은 것입니다.

- **`:Compute` 계산 함수의 재진입이 에러가 됩니다.** 계산 함수가 자기 노드의 값을 읽는 의존성 순환(직접, 또는 하류 State를 거쳐)은 전에는 내부 파일을 가리키는 `stack overflow`였고, 그것을 `q.Fallback` 같은 프레임이 삼키면 반쯤 계산된 값이 유효 캐시로 굳었습니다. yield하는 계산 함수를 다른 코루틴이 그 사이 읽으면 함수가 두 번 돌았습니다. 이제 둘 다 읽는 줄에서 `State: Compute fn is already running for this value …`로 즉시 에러입니다. 부수 규칙 하나: 계산 함수가 던지면 **같은 세대의 재읽기**도 그 문구로 에러이고(전에는 함수가 다시 돌았습니다), 상류가 바뀌면 다시 돕니다. 순환·yield·던지는 계산 함수를 쓰지 않던 코드는 영향이 없습니다. 핸들러 작성자용 한 줄: 길이로 등록한 `State`의 계산 함수가 같은 owner의 부기를 건드리면 이 에러입니다(중첩 재계산이 자기 값을 읽습니다).

- 옵션 테이블을 변수에 담아 넘겨도 strict 타입 검사가 통과합니다 — `q.Debounce`/`q.Throttle`의 옵션, `slot:List`/`slot:Single`의 `opts`, 그리고 `q.Slot(initial)`의 배열(필드·원소가 읽기 전용 `read`로 선언됨). 전에는 `local opts = { Time = 0.3 }` 뒤 `q.Debounce(opts)`가 가변 필드 불변성으로 거부됐습니다. 받는 입력이 넓어지기만 해 기존 코드는 그대로 통과합니다.

- **BREAKING(타입만) — `q.Effect`가 돌려주는 핸들의 타입 이름이 `EffectHandle`에서 `Effect`로, 입력 자리 마커가 `EffectHandleMarker`에서 `EffectMarker`로 바뀌었습니다.** `state:Observer` → `Observer`, `q.Slot` → `Slot`처럼 생성자와 타입 이름이 같은 규칙에서 이것만 벗어나 있었습니다(술어 `isEffect`와도 맞춤). 런타임은 같습니다. 옮기는 법: 주석·재수출의 `EffectHandle`을 `Effect`로(설정 모듈의 `export type EffectHandle = QuadTypes.EffectHandle` → `export type Effect = QuadTypes.Effect`).

- **BREAKING — 백엔드가 심는 계약 op가 `q.Backend`로, Length/Offset 부기 함수가 `q.Bookkeeping`으로 옮겨졌습니다.** 앱 코드가 부를 표면이 아닌 것들이 `q.` 자동완성에 섞여 있었습니다. 멤버 이름은 그대로입니다.
  - `q.Backend`: `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`, `nativeInsert`/`nativeExtract`/`nativeRemove`/`nativeMove`/`nativeSwap`/`nativeDispose`, `nativeClaim`/`nativeFindChild`/`isInst`/`onDestroying`, `addTag`/`removeTag`/`setAttr`, `setTimeout`/`clearTimeout`.
  - `q.Bookkeeping`: `setLength`/`setOffsetSource`/`setEmpty`/`getOffsetAt`/`getBlocker`/`getBookkeeping` — `q.Dispatch`에서는 빠졌습니다. 에러 문구의 접두도 `Dispatch.`에서 `Bookkeeping.`으로 바뀌었습니다.
  - `q.dispose`, `q.newMapperClass`, `is*` 술어는 그대로 `q.`에 있습니다.
  - 옮기는 법: 백엔드 작성자는 `quad.nativeInsert = …`를 `quad.Backend.nativeInsert = …`로, 핸들러 작성자는 `q.Dispatch.setLength(…)`를 `q.Bookkeeping.setLength(…)`로, 테스트에서 `q.bindLifetime(…)`을 부르던 코드는 `q.Backend.bindLifetime(…)`으로.

- **Observer·Effect·Slot·State를 만든 quad 인스턴스가 아닌 다른 인스턴스의 트리에 놓으면 그 자리에서 에러가 납니다**(`…: this value was made by another quad module instance …`) — 숫자 키 자리, 프로퍼티 값, `slot:List`의 데이터 State. 전에는 에러 없이 받아들여졌지만 생명주기 기록이 인스턴스마다 따로라 그 값이 조용히 돌지 않았습니다(`quad_base` 사본이 둘 생긴 프로젝트에서 흔히 밟는 경우). 제대로 돌던 코드는 영향이 없습니다. 의존성으로만 잇는 것(`q.Effect(fn, 다른 인스턴스의 Source)`)은 그대로 되고, `Ref`·`Blocker` 같은 공유 값은 검사하지 않습니다(두 인스턴스에 걸쳐 쓰면 정의되지 않은 동작).

- **BREAKING — `quad_types`의 `Brand()`가 돌려주는 객체의 메소드가 `:register`/`:is`에서 `:Register`/`:Is`로 바뀌었습니다.** 자기 값 타입에 브랜드를 붙이는 백엔드·플러그인 작성자에게만 해당하고, `q.isState` 같은 술어를 쓰는 코드는 그대로입니다. 옮기는 법: 호출부의 메소드 이름 첫 글자만 대문자로.
- 문서에 명시: `_`로 시작하는 필드(`_bookkeeping` 등)는 공개 표면이 아니며 예고 없이 바뀝니다.
- 문서에 명시: 에러 메시지는 사람이 읽는 진단이지 API가 아닙니다 — 문구는 예고 없이 다듬어질 수 있으니 문구로 분기하지 마세요.
- 문서에 명시(정의되지 않은 동작): 같은 원천을 구독한 하류·Ref 콜백끼리의 발화 순서와 `KeyGone` 호출끼리의 순서(등록 순서가 아닙니다), Observer·Effect·계산 함수·Ref 콜백 안의 yield, `updateFn`이 도중에 던진 뒤의 그 Slot(더 재조정되지 않습니다), 서로를 설치하는 플러그인 순환.
- **BREAKING — `slot:List`/`slot:Single`의 옵션 `Owned`가 `OwnsElements`로 바뀌었습니다.** 뜻은 그대로입니다(기본 `true`, `false`면 이 Slot이 원소의 수명을 책임지지 않음). 옛 키는 조용히 무시되어 기본값(소유)으로 돌아가니 반드시 옮기세요 — `q.debug`를 켜면 모르는 키로 알려 줍니다. 옮기는 법: `{ Owned = false }`를 `{ OwnsElements = false }`로.
- `q.Effect`의 `fn`이 함수도 `nil`도 아닌 값을 돌려주면 그 자리에서 `Effect: fn must return a cleanup function or nothing (got …)`을 던집니다(사용자 줄 blame). 전에는 값을 저장했다가 다음 정리 때 quad 내부에서 `attempt to call …`로 터지고 그 `Effect`가 조용히 멈췄습니다. 연결 객체를 돌려주던 코드는 `return function() conn:Disconnect() end`로 감싸세요.
- `q:AddPlugin`이 같은 플러그인 함수를 다시 받으면 아무것도 하지 않습니다(`q:RunInit`과 같은 identity 기준). 여러 스크립트가 각자 설치해도 한 번만 돕니다. 도중에 던진 플러그인은 설치된 것으로 치지 않아 다시 부르면 처음부터 돕니다.
- `quad_roblox`가 요구하는 `quad_base` 버전이 정확히 일치에서 **같은 메이저 안의 하한**(`3.2^.0^` — 3.2.0 이상, 메이저 3)으로 풀렸습니다. `quad_base`만 올라가도 설치 시점 검사에서 막히지 않습니다. 프리릴리즈 빌드는 그 빌드만 받습니다(패턴 `3.3.0-rc.2`).
- **BREAKING — `q.Store`의 필드 이름으로 `__`(밑줄 둘)로 시작하는 이름을 전부 쓸 수 없습니다**(전에는 `__reservedCheck` 하나만 막았습니다). 생성자와 `:Of` 모두 `Store: "{name}" is a reserved store key`를 던지고 strict 타입 검사도 알립니다. 대신 Store의 메소드는 `Of`/`Names`에서 더 늘리지 않기로 해, 그 둘과 `__` 접두만 피하면 앞으로 필드 이름이 새 메소드와 부딪히지 않습니다. 옮기는 법: `__`로 시작하는 필드 이름을 다른 이름으로 바꾸세요.
- **`quad_error`와 `type_version_check`가 quad와 같은 버전 번호를 쓰지 않습니다.** 둘은 quad에 묶이지 않은 범용 패키지라 이제 각자의 SemVer로 올라가고, 첫 독립 릴리즈가 **4.0.0**입니다(번호는 이어서 — 옛 3.x는 회수). 각 패키지의 변경은 그 폴더의 `CHANGELOG.md`에 적습니다. `quad_base`·`quad_roblox`·`quad_types`만 계속 같은 번호로 게시되고, 이 둘은 의존성으로 따라 들어오니 소비자가 적을 일은 여전히 없습니다. 둘을 직접 적어 두었다면 `^4.0.0`으로 옮기세요.
- **BREAKING(타입만) — `slot.Length`/`slot.Offset`과 `updateFn`의 `offset` 인자가 `Source<number>`에서 읽기 전용 `State<number>`로 좁혀졌습니다.** 값을 채우는 것은 quad뿐이라 `:Set`을 부르면 조용히 레이아웃이 어긋났는데, 이제 strict에서 막힙니다. `:Get`/`:Compute`/`:Observer`/`:Depend`는 그대로입니다. 옮기는 법: `slot.Length`/`slot.Offset`이나 `updateFn`의 `ctx.Offset`에 `Source<number>`라고 주석을 달았다면 `State<number>`로 바꾸세요(`updateFn`의 인자 모양 변화는 아래 항목).
- **BREAKING — `state:With(...)`가 `state:Depend(...)`로 이름이 바뀌었습니다.** 동작은 그대로(값은 리시버 것, 넘긴 deps가 변할 때도 다시 발행)이고, `:Compute(fn, ...deps)`·`q.Effect(fn, ...deps)`의 deps와 같은 낱말이 됐습니다. `With`는 "값이 따라온다"로 읽히기 쉬웠습니다. 옮기는 법: `:With(`를 `:Depend(`로. 옛 이름은 남기지 않았습니다.
- **BREAKING — `slot:List`/`slot:Single`의 `updateFn`이 위치 인자 다섯 대신 테이블 하나를 받습니다**: `updateFn(ctx)` — `ctx.Item`/`ctx.Index`/`ctx.Offset`/`ctx.Prev`/`ctx.UserData`. `:Single`에도 `Index`가 들어와 같은 `updateFn`을 두 곳에 쓸 수 있습니다. 반환 `(result, userdata)`는 그대로입니다. 호출마다 새 테이블이라 안에서 만든 클로저가 `ctx`를 붙잡아도 안전합니다. 옮기는 법: `function(item, index, offset, prev, ud)`를 `function(ctx)`로 바꾸고 필드로 읽으세요(`:Single`은 옛 `(item, offset, prev, ud)`).
- **BREAKING — `blocker.IsBlocked`와 `blocker:IsOn()`이 `blocker.Blocking` 필드 하나로 바뀌었습니다.** 같은 값을 읽는 길이 둘이었습니다. 진행형인 이유는 "지금 막고 있다"를 뜻하기 때문입니다(과거형은 "막아 낸 적이 있다"로 읽힙니다). 옮기는 법: `blocker:IsOn()`과 `blocker.IsBlocked`를 `blocker.Blocking`으로.
- **BREAKING — `tag:Names()`가 없어지고 Tag를 직접 반복합니다**: `for name in tag do`(Luau 일반화 반복 `__iter`, 새 테이블을 만들지 않음). `store:Names()`는 배열을 돌려주는데 `tag:Names()`는 이터레이터라 이름이 같고 모양이 달랐습니다. 옛 호출은 없는 메소드라 즉시 에러가 납니다. 옮기는 법: `for name in tag:Names() do`를 `for name in tag do`로. `pairs(tag)`는 이름을 돌지 않습니다(Luau가 `__pairs`를 `__iter`로 대체).
- **BREAKING(타입만) — `Provider<T>`(Context의 열쇠)가 `T`에 불변이 됐습니다.** 전에는 `Provider<number>`에 문자열을 `ctx:Set` 해도 타입 검사가 통과해 `ctx:Get`의 약속이 깨졌습니다. 이제 넣는 값의 타입이 열쇠와 같아야 하고, `Provider<Frame>`을 `Provider<Instance>` 자리에 넘길 수도 없습니다(`Ref<T>`와 같은 규칙). 런타임 동작은 같습니다. 옮기는 법: 열쇠를 넘겨받는 자리의 타입을 그 열쇠와 같게 적으세요.
- **BREAKING(타입만) — 사용자가 읽기만 하는 상태 필드에 `read`가 붙었습니다**: `Ref`의 `Value`/`Revision`/`Callbacks`/`WeakCallbacks`, `Source.Revision`과 `quad_types`의 `Epoch` 타입의 `Revision`, `Observer`·`Effect`의 `Subscribed`, `Blocker.Blocking`(아래 개명), `AttrKey`의 `Name`, `Timeout._native`. 런타임 동작은 같습니다. 옮기는 법: 이 필드에 직접 대입하던 코드는 `ref:Set(v)`, `:Subscribe()`/`:Unsubscribe()`, `blocker:On()`/`:Off()` 같은 메소드로 바꾸세요.

### Fixed

- 중첩 `:List`/`:Single`의 `updateFn`이 첫 마운트 중에 조상 Slot을 CRUD하면 내부 에러(`bindLifetime: value is already bound`)로 죽고 그 트리의 부기가 영구히 깨지던 것 — 이제 그 자리에서 `Slot: cannot mutate a Slot while it is being mounted …`로 거부합니다(`updateFn`은 항목을 원소로 바꾸는 함수이고, 조상은 마운트 뒤 Observer에서 바꾸세요). 자기 자식 Slot을 채우거나 마운트 뒤에 조상을 바꾸던 코드는 영향이 없습니다.
- `Effect`의 cleanup 안에서 의존성을 `:Set`하면 뒤따르는 `fn`이 그 값을 읽고도 (cleanup, fn) 사이클이 같은 입력으로 한 번 더 돌던 것 — 이제 한 사이클입니다. `fn` 안의 `:Set`이 한 번 더 돌게 하는 것은 그대로입니다.
- `Slot`에 `State`로 담아 넣은 원소의 검사(마운트 가능한 값인지·quad 소유인지·파괴된 Slot이 아닌지)가 삽입 **뒤**에 돌아, 거부된 호출이 유령 원소를 남기고 그 Slot의 재조정을 멈추게 하던 것 — 이제 다른 원소와 같이 넣기 전에 검사하고, 실패한 `Add`/`Replace`/`Extract`/`Splice`/생성자는 아무것도 바꾸지 않습니다(마운트 전 Slot도 그 자리에서 거부합니다).
- `Debounce`/`Throttle`의 `Time`이 `State`일 때 그 값이 잘못돼 창을 못 열면(음수·문자열, 또는 시간 op가 없는 백엔드) 게이트가 "막힘 상태인데 타이머 없음"으로 굳어 다음 신호까지 통지가 멈추던 것 — 창을 먼저 잡고 상태를 바꾸도록 순서를 고쳤습니다.
- `Claim`의 매퍼 키가 트리에 없을 때 내부 파일 이름으로 죽던 것 — `Claim: no child matched key … under …`로 키를 말합니다.
- `Modifier` 초기 필드에 함수를 넣었을 때의 안내가 이벤트 핸들러를 변환 함수 자리로 이끌던 것 — 이벤트는 Modifier에 두지 않고 선언의 인라인 키나 `State`로 넣으라고 안내합니다.
- `q.Operator`의 `Sum`/`Product`/`Min`/`Max`/`Band`/`Bor`/`Bxor`가 값이 `nil`인 `State` 인자를 조용히 건너뛰고 나머지만 계산하던 것(`Clamp`/`Shl`은 내부 에러) — 읽는 시점에 `Operator.Sum: argument #N is a State whose current value is nil …`로 던집니다.
- 다른 quad 모듈 인스턴스가 만든 `Slot`을 `Slot`의 원소 자리(`Add`/생성자/`Replace`/`Extract`/`Splice`, `State`에 담아서, `:List`의 반환값으로)에 넣거나 `q.dispose`에 넘기면 이제 거부합니다 — 전에는 통과해 다른 인스턴스의 트리를 조용히 망가뜨릴 수 있었습니다(`State`는 이미 거부됐고 이제 같은 자리에서 같은 문구로 거부합니다).
- `q.Blocker()`를 `__apply`로 State가 아닌 값에 걸면 내부 에러가 나던 것 — `Blocker: Apply target must be a State …`.
- `Animate`가 건 `State`에 `Tween`이나 `State`를 넣었을 때 나는 검증 에러가 quad 내부 줄(`Animate.luau`)을 가리키던 것 — 호출한 줄을 가리킵니다.
- `q.debug`가 켜져 있으면 `Claim`이 두 가지 실수를 알려 줍니다: 루트 디스크립터에 문자열 키를 준 경우(`M.Frame("Name")` — 키는 무시되고 루트 자신이 claim됩니다)와 자식 자리의 키가 문자열이 아닌 경우(`M.Root`를 자식에). 동작은 그대로입니다(런타임 검사를 두지 않는 `Claim`의 규칙).
- 인자 모양을 검사하지 않던 입구에 검사를 넣었습니다(전부 호출한 줄을 가리킵니다): `Dispatch.process`/`retractFrom`의 `index`(양의 정수), `Modifier:Apply`의 factory(함수), `slot:List`/`:Single`의 `opts`(테이블 — 문자열은 조용히 무시됐습니다), `AddPlugin`/`UseProvider`의 인자(함수)와 반환값(확장 테이블). `UseProvider(nil)`이 아무 일도 없이 성공하던 것도 이제 에러입니다.
- 검증에 실패한 CRUD 호출(`Add(nil)` 등)이 Slot을 수동 모드로 표시해 뒤의 `:List`가 "CRUD를 썼다"고 거부하던 것 — 실제로 바꾼 호출만 표시합니다.
- `Slot:Splice`가 같은 호출에서 빼는 원소를 되넣거나 `Replace(i, slot:Get(i))`를 하면 "같은 원소가 두 번"이라던 것 — "이미 이 Slot에 있다, Move/Swap을 쓰라"로 바르게 말합니다. `keyFn`이 NaN을 돌려주면 nil과 같은 도메인 에러입니다. `Tag`에 자기를 담은 리스트를 주면 내부 스택 오버플로 대신 도메인 에러입니다.
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
