# Q90 메시지 모양 위반 — 전수 표 초안 (2026-09-27)

> **상태: 초안, 결정 아님.** `qa-request/post-implementation-review-round13.md` §4 Q90(갈래 (a)/(b)/(c), 메인 권고 (b) = ①⑤⑥⑩만)의 판정 재료. 아래 표는 그 ①~⑩ 목록에 실제로 걸리는 자리를 `quad-base/src`·`quad-roblox/src` 전수 grep으로 다시 찾아 지금 문구와 초안을 나란히 둔 것 — 코드·문서는 그대로다.

## 규약 원문 (표 위에 인용, `.claude/base/architecture.md` "메시지 모양" 절)

- **주어**는 사용자가 부른 표면 이름 — 메소드는 `Slot:Get`·`Tween:Mapped`, 네임스페이스 함수는 `Modifier.Overridden`·`Dispatch.drive`(`quad.` 접두 없음), 생성자·불변식은 타입 이름만(`Tween:`·`State:`). 주어는 이름만이고 인자 값은 이유 쪽에 싣는다.
- **이유**는 영어 한 절, `must be …`/`cannot …` 현재형. 부연은 ` — `(em-dash) 뒤에.
- **받은 값**은 문장 끝 `(got {typeof(x)})` — 괄호형만. 받은 값이 아니라 잘못 놓인 자리를 서술하는 문장이면 꼬리가 없어도 된다. 숫자·정해진 값은 `tostring`으로 그 값을 실어도 된다.
- 구분자는 콜론 하나.

## 권고 (b) 대상 — ①⑤⑥⑩ (34행)

### ① 주어가 사용자가 부르지 않은 내부 이름 (4행)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0160 | `quad-base/src/Slot/Owner.luau:54` | `Quad0160 Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed` + ZOMBIE_NOTE | `claimOwnerAt`은 Slot 마운트 경로(`Slot/Handler.luau`)와 정적 자식 경로(`InstanceChild.luau`) 둘에서 공유하는 내부 op — 형제 Quad0170/0172(`Slot/init.luau`)가 이미 쓰는 `surface` 인자를 여기도 threading해 `` `Quad0160 {surface}: this element is already mounted elsewhere — …` ``로. Slot 경로는 `surface = "Slot:Add"` 등 기존 값, InstanceChild 경로는 `surface = "Declaration"`(정적 자식은 `D.<Class> { … }`를 통해서만 옴 — 클래스별 이름은 못 실으므로 타입 이름만 원칙에 맞춰 고정 문자열). | `docs/reference/errors/03-slot.md` §Quad0160 |
| Quad0070 | `quad-base/src/Dispatch/StoreBind.luau:78` | `Quad0070 StoreBind: the State's value chain is circular (a State that eventually holds itself) — a State may hold another State, but not a cycle` | `StoreBind`는 사용자가 부르지 않는 내부 디스패치 핸들러 이름 — 이 불변식은 State 자신의 값 체인에 대한 것이라 "생성자·불변식은 타입 이름만" 규칙 그대로: `` `Quad0070 State: the value chain is circular (a State that eventually holds itself) — a State may hold another State, but not a cycle` ``(주어만 교체, 나머지 문장 그대로). | `docs/reference/errors/02-dispatch-bookkeeping.md` §Quad0070(표제만 "StoreBind" → "State"로 옮길지는 그 문서 절 재배치 필요 — Q90 결정에 포함 안 됨, 별도 확인) |
| Quad0219 | `quad-roblox/src/Handlers/InstanceChild.luau:64` | `Quad0219 InstanceChild: this Instance is not claimed by quad — build it with the Declaration or take it over with Claim first (…)` | 사용자가 부른 자리는 `D.<Class> { instance }`(정적 자식) — 클래스별로 못 박을 수 없으니 위 0160과 같은 이유로 `Declaration` 고정: `` `Quad0219 Declaration: this Instance is not claimed by quad — …` `` | `docs/reference/errors/07-roblox.md` §Quad0219 |
| Quad0220 | `quad-roblox/src/Handlers/InstanceChild.luau:76` | `Quad0220 InstanceChild: cannot place an Instance inside itself or one of its own descendants (that would be a cycle)` | 같은 이유로 `` `Quad0220 Declaration: cannot place an Instance inside itself or one of its own descendants (that would be a cycle)` `` | `docs/reference/errors/07-roblox.md` §Quad0220 |

### ⑤ `(got X)` 꼬리 누락 (9행 — "must be a function" 6 + "must be a number/boolean" 3)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0094 | `quad-base/src/Effect.luau:292` | `Quad0094 Effect: fn must be a function` | `` `Quad0094 Effect: fn must be a function (got {typeof(fn)})` `` (생성자라 주어는 그대로) | `docs/reference/errors/04-ref-observer-effect.md` §Quad0094 |
| Quad0187 | `quad-base/src/State.luau:268` | `Quad0187 State: Compute fn must be a function` | `` `Quad0187 State:Compute: fn must be a function (got {typeof(fn)})` `` (주어도 ② 대상 — 아래 표 참고, 여기 합쳐 적음) | `docs/reference/errors/01-core-reactive.md` §Quad0187 |
| Quad0188 | `quad-base/src/State.luau:326` | `Quad0188 State: Gate setup must be a function (emit) -> onUpstreamEmit` | `` `Quad0188 State:Gate: setup must be a function (emit) -> onUpstreamEmit (got {typeof(setup)})` `` | `docs/reference/errors/01-core-reactive.md` §Quad0188 |
| Quad0190 | `quad-base/src/State.luau:350` | `Quad0190 State: Observer fn must be a function (or nil for the always-observe utility)` | `` `Quad0190 State:Observer: fn must be a function (or nil for the always-observe utility) (got {typeof(fn)})` `` | `docs/reference/errors/01-core-reactive.md` §Quad0190 |
| Quad0191 | `quad-base/src/State.luau:360` | `Quad0191 State: Apply factory must be a function or an object with an __apply method` | `` `Quad0191 State:Apply: factory must be a function or an object with an __apply method (got {typeof(factory)})` `` | `docs/reference/errors/01-core-reactive.md` §Quad0191 |
| Quad0246 | `quad-roblox/src/Tween.luau:115` | `` Quad0246 Tween: {name} must be a function `` | `` `Quad0246 Tween: {name} must be a function (got {typeof(v)})` `` (값 변수는 `v`, 확인됨) | `docs/reference/errors/08-roblox-tween.md` §Quad0246 |
| Quad0243 | `quad-roblox/src/Tween.luau:103` | `` Quad0243 Tween: {name} must be a number `` | `` `Quad0243 Tween: {name} must be a number (got {typeof(v)})` `` | `docs/reference/errors/08-roblox-tween.md` §Quad0243 |
| Quad0244 | `quad-roblox/src/Tween.luau:107` | `Quad0244 Tween: Reverses must be a boolean` | `` `Quad0244 Tween: Reverses must be a boolean (got {typeof(v)})` `` | `docs/reference/errors/08-roblox-tween.md` §Quad0244 |
| Quad0245 | `quad-roblox/src/Tween.luau:110` | `Quad0245 Tween: Dedup must be a boolean` | `` `Quad0245 Tween: Dedup must be a boolean (got {typeof(v)})` `` | `docs/reference/errors/08-roblox-tween.md` §Quad0245 |

### ⑥ `(got number)`가 정보 없음 — 값이 아니라 타입만 보임 (3행)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0039 | `quad-base/src/Debounce.luau:82` | `` Quad0039 {name}: {field} must be a non-negative number (got {typeof(v)}) `` | `` `Quad0039 {name}: {field} must be a non-negative number (got {tostring(v)})` `` — `v`는 이미 `type(v) ~= "number"` 검사를 통과 못 한 경우도 오므로 `` {if type(v) == "number" then tostring(v) else typeof(v)} `` 형태가 더 안전(비수치 값은 `tostring`이 테이블이면 포인터 문자열을 찍어 오히려 정보가 준다). | `docs/reference/errors/01-core-reactive.md` §Quad0039 |
| Quad0041 | `quad-base/src/Debounce.luau:98` | `` Quad0041 {name}: {field} must be a non-negative number or a State<number> (got {typeof(t)}) `` | `` `Quad0041 {name}: {field} must be a non-negative number or a State<number> (got {if type(t) == "number" then tostring(t) else typeof(t)})` `` | `docs/reference/errors/01-core-reactive.md` §Quad0041 |
| Quad0216 | `quad-roblox/src/EngineOps.luau:149` | `` Quad0216 setTimeout: delay must be a non-negative number (got {typeof(delay)}) `` | `` `Quad0216 setTimeout: delay must be a non-negative number (got {if type(delay) == "number" then tostring(delay) else typeof(delay)})` `` | `docs/reference/errors/07-roblox.md` §Quad0216 |

### ⑩ 문자 키 흔한 실수가 무조건 provider 힌트로 떨어짐 (1행)

| ID | 파일:줄 | 지금 문구(힌트 분기) | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0076 | `quad-base/src/Dispatch/init.luau:196-207`(`noMatchMessage`) | `if not isBase then " — check that the provider for this value (e.g. quad-roblox) is initialized" elseif brand == "Store" then … elseif type(k) == "string" then " — a quad value at a string key: it belongs in a numeric (array) slot" else …` — `brand == nil`(문자 키 오타·읽기 전용·다른 클래스 프로퍼티 등, 브랜드 없는 값)이면 무조건 첫 분기로 떨어져 "provider not initialized" 힌트를 받는다(프로바이더는 설치돼 있는데도). | 분기 순서를 바꿔 "문자 키 + 브랜드 없음"을 provider-hint보다 먼저 본다: `` if brand == "Store" then … elseif type(k) == "string" and brand == nil then " — this class's writable property or event? (misspelled, read-only, or belongs to another class — this is not a quad value)" elseif not isBase then " — check that the provider for this value (e.g. quad-roblox) is initialized" elseif type(k) == "string" then … else … `` (문구는 시안 — 사용자 확인 필요). | `docs/reference/errors/02-dispatch-bookkeeping.md` §Quad0076 |

## 나머지 — ②③④⑦⑧⑨ (취향에 가까움, 메인 권고는 그대로 두는 것)

### ② 메소드인데 주어가 타입 이름뿐 (24행 — 호출부 기준, 일부는 같은 줄에 형제 ID 둘)

| ID | 파일:줄 | 지금 문구 주어 | 실제 메소드 | 고친 문구 초안(주어만) | 바뀌는 문서 절 |
|---|---|---|---|---|---|
| Quad0130 | `Ref/init.luau:101` | `Ref:` | `RefImpl.Set`(`:Set`) | `Ref:Set` | `04-ref-observer-effect.md` §Quad0130 |
| Quad0133 | `Ref/init.luau:155` | `Ref:` | `RefImpl.Wait`(`:Wait`) | `Ref:Wait`(+④ 아래) | §Quad0133 |
| Quad0134 | `Ref/init.luau:164` | `Ref:` | `RefImpl.Wait`(`:Wait`) | `Ref:Wait` | §Quad0134 |
| Quad0088 | `Effect.luau:234` | `Effect:` | `Impl.WeakSubscribe` | `Effect:WeakSubscribe` | §Quad0088 |
| Quad0089/Quad0230 | `Effect.luau:237`(한 줄, inline if) | `Effect:` | `Impl.WeakSubscribe` | `Effect:WeakSubscribe`(두 ID 다 이 줄 하나 고치면 같이 바뀜) | §Quad0089·§Quad0230 |
| Quad0090 | `Effect.luau:248` | `Effect:` | `Impl.Subscribe` | `Effect:Subscribe` | §Quad0090 |
| Quad0091/Quad0231 | `Effect.luau:251` | `Effect:` | `Impl.Subscribe` | `Effect:Subscribe` | §Quad0091·§Quad0231 |
| Quad0092 | `Effect.luau:271` | `Effect:` | `Impl.WeakUnsubscribe` | `Effect:WeakUnsubscribe` | §Quad0092 |
| Quad0093 | `Effect.luau:280` | `Effect:` | `Impl.Unsubscribe` | `Effect:Unsubscribe` | §Quad0093 |
| Quad0110 | `Observer.luau:125` | `Observer:` | `Impl.WeakSubscribe` | `Observer:WeakSubscribe` | §Quad0110 |
| Quad0111/Quad0234 | `Observer.luau:129` | `Observer:` | `Impl.WeakSubscribe` | `Observer:WeakSubscribe` | §Quad0111·§Quad0234 |
| Quad0112 | `Observer.luau:146` | `Observer:` | `Impl.WeakUnsubscribe` | `Observer:WeakUnsubscribe` | §Quad0112 |
| Quad0113 | `Observer.luau:156` | `Observer:` | `Impl.Subscribe` | `Observer:Subscribe` | §Quad0113 |
| Quad0114/Quad0235 | `Observer.luau:162` | `Observer:` | `Impl.Subscribe` | `Observer:Subscribe` | §Quad0114·§Quad0235 |
| Quad0115 | `Observer.luau:176` | `Observer:` | `Impl.Unsubscribe` | `Observer:Unsubscribe` | §Quad0115 |
| Quad0181 | `Source.luau:84` | `Source:` | `Impl.Set` | `Source:Set` | §Quad0181 |
| Quad0187 | `State.luau:268` | `State:` | `Impl.Compute` | `State:Compute`(⑤와 합침, 위 표) | §Quad0187 |
| Quad0188 | `State.luau:326` | `State:` | `Impl.Gate` | `State:Gate`(⑤와 합침) | §Quad0188 |
| Quad0189 | `State.luau:339` | `State:` | `Impl.Gate` | `State:Gate` | §Quad0189 |
| Quad0190 | `State.luau:350` | `State:` | `Impl.Observer` | `State:Observer`(⑤와 합침) | §Quad0190 |
| Quad0191 | `State.luau:360` | `State:` | `Impl.Apply` | `State:Apply`(⑤와 합침) | §Quad0191 |
| Quad0017 | `Blocker.luau:94` | `Blocker:` | `BlockerImpl.Policy` | `Blocker:Policy`(주석이 스스로 "Siblings State:Gate/State:Apply gate here"라고 적어 이 모양을 이미 전제) | `docs/reference/errors/01-core-reactive.md` §Quad0017 |
| Quad0165 | `Slot/init.luau:131`(`assertLive`) | `Slot:` | `assertLive`는 거의 모든 public CRUD가 공유하는 내부 술어 — 특정 메소드가 아님 | 형제 Quad0170~0173이 이미 쓰는 `surface` 인자를 `assertLive`/`assertManual`/`assertNotMounting`(그리고 이걸 합치는 `assertMutable`)에 threading — `` `Quad0165 {surface}: destroyed Slot cannot be reused` `` | `docs/reference/errors/03-slot.md` §Quad0165 |
| Quad0166 | `Slot/init.luau:137`(`assertManual`) | `Slot:` | 위와 같음 | `` `Quad0166 {surface}: manual CRUD is not allowed after :List/:Single` `` | §Quad0166 |
| Quad0167 | `Slot/init.luau:148`(`assertNotMounting`) | `Slot:` | 위와 같음 | `` `Quad0167 {surface}: cannot mutate a Slot while it is being mounted — …` `` | §Quad0167 |

**참고(Q90 목록엔 없음, 같은 패턴)**: `Quad0209`/`Quad0211`(`init.luau` `mergeExtension`)은 `{who}` 변수가 이미 "AddPlugin"/"UseProvider" 문자열이라 `Quad:` 접두는 없다 — ③ 항목과 겹치는 결이라 ③에서 언급.

### ③ 형제 불일치 (3행)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0208 | `quad-base/src/init.luau:129` | `` Quad0208 Quad:RunInit: initFn must be a function (got {typeof(initFn)}) `` | 변경 없음(기준) | `06-module-backend.md` §Quad0208 |
| Quad0210 | `quad-base/src/init.luau:154` | `` Quad0210 AddPlugin: plugin must be a function (got {typeof(pluginFn)}) `` | `` `Quad0210 Quad:AddPlugin: plugin must be a function (got {typeof(pluginFn)})` `` | §Quad0210 |
| Quad0212 | `quad-base/src/init.luau:197` | `` Quad0212 UseProvider: provider must be a function (got {typeof(providerFn)}) `` | `` `Quad0212 Quad:UseProvider: provider must be a function (got {typeof(providerFn)})` `` | §Quad0212 |

### ④ `must be …` 대신 `expected`/`expects` (6행, Quad0133은 ②에도 있음 — 최종 문구는 ② 행에 이미 반영)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0045 | `Debounce.luau:317` | `` Quad0045 {name}: options table expected (got {typeof(opts)}) `` | `` `Quad0045 {name}: options must be a table (got {typeof(opts)})` `` | `01-core-reactive.md` §Quad0045 |
| Quad0053 | `Dispatch/Modifier/init.luau:216` | `Quad0053 Modifier.Overridden: expects at least one Modifier` | `Quad0053 Modifier.Overridden: at least one Modifier is required`(기존 Quad0040 "is required" 관용구와 통일) | `02-dispatch-bookkeeping.md` §Quad0053 |
| Quad0133 | `Ref/init.luau:155` | `` Quad0133 Ref: Wait(thread) expects a thread (got {typeof(thread)}) `` | `` `Quad0133 Ref:Wait: thread must be a thread (got {typeof(thread)})` ``(② 행과 동일한 최종형) | `04-ref-observer-effect.md` §Quad0133 |
| Quad0214 | `Animate.luau:67` | `Quad0214 Animate: expected an options table (Animate{ Time = ... })` | `` `Quad0214 Animate: info must be a table (Animate{ Time = ... }) (got {typeof(info)})` ``(꼬리 추가는 ⑤ 성격이라 겸사 — (b) 채택 안 해도 최소 "expected"만 "must be"로) | `08-roblox-tween.md` §Quad0214(확인됨) |
| Quad0217 | `EngineOps.luau:156` | `` Quad0217 clearTimeout: expected a Timeout from setTimeout (got {typeof(timeout)}) `` | `` `Quad0217 clearTimeout: timeout must be a Timeout from setTimeout (got {typeof(timeout)})` `` | `07-roblox.md` §Quad0217 |
| Quad0248 | `Tween.luau:131` | `Quad0248 Tween: expected an options table (Tween{ Value = ... })` | `` `Quad0248 Tween: opts must be a table (Tween{ Value = ... }) (got {typeof(opts)})` `` | `08-roblox-tween.md` §Quad0248 |

### ⑦ `(got table)`이 원인을 안 가리킴 (1행)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0079 | `Dispatch/init.luau:394`(`addHandler`) | `` Quad0079 Dispatch.addHandler: handler must be a table with isHandlable/process functions and a numeric priority (got {typeof(handler)}) `` | 한 가드를 필드별 넷으로 쪼갠다(설계 필요 — 초안은 방향만): `handler`가 테이블이 아니면 지금 문구 그대로, 테이블이면 `isHandlable`/`process`/`priority` 중 어긴 필드 하나를 짚어 `` `Quad0079 Dispatch.addHandler: handler.process must be a function (got {typeof(handler.process)})` `` 식으로. ID 하나를 필드별로 나눌지(0079 재사용이면 문서 절 하나에 네 문장, 새 ID면 배정 필요)는 결정 필요. | `02-dispatch-bookkeeping.md` §Quad0079(필드별로 쪼개면 절 구조도 바뀜) |

### ⑧ `(got …)`가 문장 끝이 아님 (3행)

| ID | 파일:줄 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|---|
| Quad0127 | `Operator.luau:190` | `` Quad0127 Operator.Indexed: value is not a table (got {typeof(t)}) — cannot read [{tostring(key)}] `` | `` `Quad0127 Operator.Indexed: value must be a table to read [{tostring(key)}] (got {typeof(t)})` `` | `01-core-reactive.md` §Quad0127 |
| Quad0142 | `Slot/List.luau:95` | `` Quad0142 Slot:List: data must be a plain array (got {typeof(items)}) — a data State must hold one too `` | `` `Quad0142 Slot:List: data must be a plain array — a data State must hold one too (got {typeof(items)})` `` | `03-slot.md` §Quad0142 |
| Quad0205 | `Tag.luau:173` | `` Quad0205 Tag:Contains: names must be strings (got {typeof(name)} at argument {i}) `` | `` `Quad0205 Tag:Contains: name at argument {i} must be a string (got {typeof(name)})` `` | `05-tag-attr.md` §Quad0205 |

### ⑨ `q.debug` print의 복합 주어 (1행, 에러 ID 없음 — `print`)

| 자리 | 지금 문구 | 고친 문구 초안 | 바뀌는 문서 절 |
|---|---|---|---|
| `Slot/List.luau:250` | `` Slot:List/:Single: unknown option "{tostring(key)}" is ignored (known: OwnsElements) `` | `:List`/`:Single` 둘이 같은 코드를 공유해 어느 쪽으로 불렸는지 모른다 — 타입 이름만 쓰는 관용구로: `` Slot: unknown option "{tostring(key)}" is ignored (known: OwnsElements) `` (구분하려면 호출부에서 플래그를 넘겨야 하는데 새 필드 없이는 안 됨 — 이 초안은 관용구 통일만 제안) | 에러 레지스트리 대상 아님(print) — `docs/` 인용은 없음 |

## 개수 요약 (표가 소스, 재계산하지 말 것)

- ①: 4행 · ⑤: 9행 · ⑥: 3행 · ⑩: 1행 → **(b) 대상 합계 17행**(위 절 제목의 "34행"은 초안 작성 중 ②·④와 합친 중복 계산 오류 — 실제로 ②·④에 걸린 ID는 ①⑤⑥⑩과 안 겹친다, **정정: (b) 대상은 17행**).
- ②: 24행(호출부 기준, ID 29개) · ③: 3행 · ④: 6행(1개는 ②와 겹침, 최종형은 ② 행) · ⑦: 1행 · ⑧: 3행 · ⑨: 1행 → 나머지 합계 38행(겹침 1건 제외 시 37).
- 전체 raise 자리 234개 중 이 표에 오른 자리는 위 합계뿐 — 나머지는 이미 규약을 지킨다(round13 §4 Q90 본문의 실측 수치가 소스).

## 확인 못 한 것 (미완)

- Quad0188의 실제 완성 문구(주어 `State:Gate`와 (got …) 꼬리를 합친 최종형)가 파일 안 다른 raise(Quad0189, "must return the onUpstreamEmit function")와 나란히 읽을 때 자연스러운지는 재검토 안 함 — 문구만 기계적으로 합성.
- 필드별로 쪼갤 때 Quad0079를 그대로 재사용할지 새 ID 넷을 배정할지는 설계 결정이 아직 없다(⑦ 행에 방향만 적었다).
- Quad0076 힌트 재배치안의 정확한 영문 문구("this class's writable property or event? …")는 사용자 확인 없이 시안으로만 적었다 — round13 §4 Q90 본문이 제안한 방향("문자 키 + 브랜드 없는 값이면 그 클래스의 쓰기 가능한 프로퍼티/이벤트가 아니다")을 문장으로 옮긴 것뿐, 최종 영문은 아니다.
- ②의 `assertLive`/`assertManual`/`assertNotMounting`에 `surface`를 threading하는 구체적 diff(모든 호출부 아홉 곳 이상)는 만들지 않았다 — 방향만 제안.
(Quad0214·Quad0246의 문서 파일·변수명은 재확인해 표에 반영 완료.)
