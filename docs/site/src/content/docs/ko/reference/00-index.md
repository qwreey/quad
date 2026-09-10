---
title: 심볼 색인
description: quad 공개 표면 전체를 심볼 이름으로 찾아가는 색인
---
공개 표면의 심볼을 이름으로 찾는 자리다. 각 행의 링크가 그 심볼을 **자세히 설명하는 페이지**를 가리킨다 — 같은 심볼이 두 페이지에 나오면(예: `Slot`의 센티널) 둘 다 적었다.

읽는 순서가 필요하면 색인이 아니라 트랙을 따라갈 것: [시작하기](/ko/getting-started/00-installation/) → [실전 레시피](/ko/how-to/01-debugging-and-troubleshooting/) → 여기.

표기 규약: 모듈 인스턴스는 `q`, 백엔드 표면은 `q.D`를 `D`로 받아 쓴다. `q.X`는 모듈 표면의 값, `x:Method()`는 그 값의 메소드, `x.Field`는 필드다. `<<T>>`는 명시 타입 인자다.

## 모듈과 설치

| 심볼 | 페이지 |
|---|---|
| `q.New()` | [core/01 — Quad 모듈](/ko/reference/core/01-quad-module/#qnew) |
| `q:RunInit(initFn)` | [core/01](/ko/reference/core/01-quad-module/#qruninitinitfn) |
| `q:AddPlugin(pluginFn)` | [core/01](/ko/reference/core/01-quad-module/#qaddpluginpluginfn) |
| `q:UseProvider(providerFn)` | [core/01](/ko/reference/core/01-quad-module/#quseproviderproviderfn) · [roblox/01 — 설치](/ko/reference/roblox/01-install/) |
| `q.Version` | [core/01](/ko/reference/core/01-quad-module/#qversion) |
| `q.debug` | [core/01](/ko/reference/core/01-quad-module/#qdebug) |
| `q.errorNamespace` | [core/01](/ko/reference/core/01-quad-module/#qerrornamespace) · [extend/01](/ko/reference/extend/01-backend-provider-contract/) |
| `q.Relate()` | [core/01](/ko/reference/core/01-quad-module/#qrelate) |
| `QuadRoblox` | [roblox/01 — 설치](/ko/reference/roblox/01-install/) |
| `RobloxExtension` | [roblox/01](/ko/reference/roblox/01-install/) |

## 반응형 코어

| 심볼 | 페이지 |
|---|---|
| `q.Source(value)` | [core/02 — Source](/ko/reference/core/02-source/) |
| `source:Set(v)` | [core/02](/ko/reference/core/02-source/) |
| `source:Emit()` | [core/02](/ko/reference/core/02-source/) |
| `source.Revision` | [core/02](/ko/reference/core/02-source/) |
| `state:Get()` | [core/03 — State](/ko/reference/core/03-state/) |
| `state:Compute(fn, ...deps)` | [core/03](/ko/reference/core/03-state/) |
| `state:With(...)` | [core/03](/ko/reference/core/03-state/) |
| `state:Apply(factory)` | [core/03](/ko/reference/core/03-state/) · [core/06](/ko/reference/core/06-blocker-gate/) |
| `state:Observer(fn)` | [core/05 — Observer·Effect](/ko/reference/core/05-observer-effect/) · [core/03](/ko/reference/core/03-state/) |
| `state:Gate(setup)` | [core/03](/ko/reference/core/03-state/) |
| `q.Store(defaults)` | [core/04 — Store](/ko/reference/core/04-store/) |
| `store.key`(선언된 필드) | [core/04](/ko/reference/core/04-store/) |
| `store:Of<<U>>(name)` | [core/04](/ko/reference/core/04-store/) |
| `store:Names()` | [core/04](/ko/reference/core/04-store/) |

## 구독 핸들

| 심볼 | 페이지 |
|---|---|
| `q.Effect(fn, ...deps)` | [core/05 — Observer·Effect](/ko/reference/core/05-observer-effect/) |
| `observer.Subscribed` | [core/05](/ko/reference/core/05-observer-effect/) |
| `observer:Subscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `observer:WeakSubscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `observer:Unsubscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `observer:WeakUnsubscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `effect:Rerun()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `effect:Subscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `effect:WeakSubscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `effect:Unsubscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |
| `effect:WeakUnsubscribe()` | [core/05](/ko/reference/core/05-observer-effect/) |

## 전파 게이트

| 심볼 | 페이지 |
|---|---|
| `q.Blocker()` | [core/06 — Blocker·Gate](/ko/reference/core/06-blocker-gate/) |
| `blocker.IsBlocked` | [core/06](/ko/reference/core/06-blocker-gate/) |
| `blocker:IsOn()` | [core/06](/ko/reference/core/06-blocker-gate/) |
| `blocker:On()` | [core/06](/ko/reference/core/06-blocker-gate/) |
| `blocker:Off()` | [core/06](/ko/reference/core/06-blocker-gate/) |
| `blocker:OffWithoutEmit()` | [core/06](/ko/reference/core/06-blocker-gate/) |
| `blocker:Policy(emit)` | [core/06](/ko/reference/core/06-blocker-gate/) |

## Slot

| 심볼 | 페이지 |
|---|---|
| `q.Slot<<T>>(initial?)` | [core/07 — Slot](/ko/reference/core/07-slot/) |
| `slot.Length` | [core/07](/ko/reference/core/07-slot/) |
| `slot.Offset` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Add(element, index?)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Remove(index)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Replace(index, newElement)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Extract(index, newElement?)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:ExtractAll()` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Splice(index, removeCount, ...)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Clear()` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Move(oldIndex, newIndex)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Swap(indexA, indexB)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Get(index)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:IndexOf(element)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:List(data, updateFn, keyFn?, opts?)` | [core/07](/ko/reference/core/07-slot/) |
| `slot:Single(state, updateFn?, opts?)` | [core/07](/ko/reference/core/07-slot/) |

## Ref

| 심볼 | 페이지 |
|---|---|
| `q.Ref<<T>>(default)` | [core/08 — Ref](/ko/reference/core/08-ref/) |
| `q.PreRef<<T>>(default)` | [core/08](/ko/reference/core/08-ref/) |
| `q.PostRef<<T>>(default)` | [core/08](/ko/reference/core/08-ref/) |
| `ref.Value` | [core/08](/ko/reference/core/08-ref/) |
| `ref.Revision` | [core/08](/ko/reference/core/08-ref/) |
| `ref.Callbacks` | [core/08](/ko/reference/core/08-ref/) |
| `ref.WeakCallbacks` | [core/08](/ko/reference/core/08-ref/) |
| `ref:Set(value)` | [core/08](/ko/reference/core/08-ref/) |
| `ref:Callback(fn)` | [core/08](/ko/reference/core/08-ref/) |
| `ref:WeakCallback(fn)` | [core/08](/ko/reference/core/08-ref/) |
| `ref:Uncallback(fn)` | [core/08](/ko/reference/core/08-ref/) |
| `ref:Wait(thread?)` | [core/08](/ko/reference/core/08-ref/) |
| `ref:Unwrap()` | [core/08](/ko/reference/core/08-ref/) |

## Modifier

| 심볼 | 페이지 |
|---|---|
| `q.Modifier(...)` | [core/09 — Modifier](/ko/reference/core/09-modifier/) |
| `mod:<Field>(value)` | [core/09](/ko/reference/core/09-modifier/) · [roblox/03](/ko/reference/roblox/03-d-modifier/) |
| `mod:Peek<<T>>(key)` | [core/09](/ko/reference/core/09-modifier/) |
| `mod:Apply(factory)` | [core/09](/ko/reference/core/09-modifier/) |
| `mod:Overridden(...)` | [core/09](/ko/reference/core/09-modifier/) |
| `mod:As(name)` | [core/09](/ko/reference/core/09-modifier/) |
| `mod:As<Class>()` | [core/09](/ko/reference/core/09-modifier/) · [roblox/03](/ko/reference/roblox/03-d-modifier/) |
| `q.Modifier.Overridden(...)` | [core/09](/ko/reference/core/09-modifier/) |
| `q.Modifier.TypedFactory<<T>>(name)` | [core/09](/ko/reference/core/09-modifier/) |
| `q.Modifier.DefineSubtype(parent, subtype)` | [core/09](/ko/reference/core/09-modifier/) |
| `D.Modifier.<Class>(...)` | [roblox/03 — D.Modifier](/ko/reference/roblox/03-d-modifier/) |
| `mod:As()` / `mod:As<<T>>()` | [roblox/03](/ko/reference/roblox/03-d-modifier/#modas--modasname--modast) · [core/09](/ko/reference/core/09-modifier/) |
| `Into<Class>` / `<Class>Modifier` | [roblox/03](/ko/reference/roblox/03-d-modifier/#intoclass--classmodifier) |

## Tag / Attr

| 심볼 | 페이지 |
|---|---|
| `q.Tag(...names)` | [core/10 — Tag·Attr](/ko/reference/core/10-tag-attr/) |
| `tag:Added(names)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `tag:Removed(names)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `tag:Contains(...names)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `tag:Names()` | [core/10](/ko/reference/core/10-tag-attr/) |
| `tag:Apply(factory)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.Tag.Merged(...tags)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.Attr(...)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `attr:NameMap()` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.Attr.Merged(...)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.Attr.Overridden(...)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.AttrKey(name)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.StringAttr(name, value)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.NumberAttr(name, value)` | [core/10](/ko/reference/core/10-tag-attr/) |
| `q.BooleanAttr(name, value)` | [core/10](/ko/reference/core/10-tag-attr/) |

## 센티널과 생명주기

| 심볼 | 페이지 |
|---|---|
| `q.None` | [core/11 — 생명주기와 센티널](/ko/reference/core/11-lifetime-sentinels/#qnone) |
| `q.Detach` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qdetach) · [core/07](/ko/reference/core/07-slot/) |
| `q.KeyGone` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qkeygone) · [core/07](/ko/reference/core/07-slot/) |
| `q.Void` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qvoid) |
| `q.dispose(value)` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qdisposevalue) · [core/07](/ko/reference/core/07-slot/) |
| `q.MapperRoot` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qmapperroot) · [roblox/04](/ko/reference/roblox/04-claim-mapper/) |
| `q.newMapperClass(className)` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qnewmapperclassclassname) |
| `q.bindLifetime(inst, value)` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qbindlifetimeinst-value) · [extend/01](/ko/reference/extend/01-backend-provider-contract/) |
| `q.unbindLifetime(value)` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qunbindlifetimevalue) · [extend/01](/ko/reference/extend/01-backend-provider-contract/) |
| `q.canBound(value)` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qcanboundvalue) · [extend/01](/ko/reference/extend/01-backend-provider-contract/) |
| `q.canExecute(value)` | [core/11](/ko/reference/core/11-lifetime-sentinels/#qcanexecutevalue) · [extend/01](/ko/reference/extend/01-backend-provider-contract/) |

## 브랜드 술어

`q.isEpoch` · `q.isSource` · `q.isState` · `q.isStore` · `q.isObserver` · `q.isEffect` · `q.isBlocker` · `q.isContext` · `q.isProvider` · `q.isModifier` · `q.isRef` · `q.isPreRef` · `q.isPostRef` · `q.isMapperDescriptor` · `q.isSlot` · `q.isTag` · `q.isAttr` · `q.isAttrKey` — 전부 [core/12 — 브랜드 술어](/ko/reference/core/12-predicates/)의 한 표에 있다.

| 심볼 | 페이지 |
|---|---|
| `q.isInst(value)` | [core/12](/ko/reference/core/12-predicates/) · [extend/01](/ko/reference/extend/01-backend-provider-contract/) |
| `q.isTween(x)` | [core/12](/ko/reference/core/12-predicates/) · [roblox/06](/ko/reference/roblox/06-tween-animate/) |

## 슈거

| 심볼 | 페이지 |
|---|---|
| `q.Context()` | [sugar/01 — Context](/ko/reference/sugar/01-context/) |
| `q.Context.Provider(name?)` | [sugar/01](/ko/reference/sugar/01-context/) |
| `ctx:Set(provider, value)` | [sugar/01](/ko/reference/sugar/01-context/) |
| `ctx:Get(provider)` | [sugar/01](/ko/reference/sugar/01-context/) |
| `ctx:Peek(provider)` | [sugar/01](/ko/reference/sugar/01-context/) |
| `provider.Name` | [sugar/01](/ko/reference/sugar/01-context/) |
| `q.Operator.Not` | [sugar/02 — Operator](/ko/reference/sugar/02-operator/) |
| `q.Operator.Sum(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Product(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Min(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Max(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Clamp(lo, hi)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Band(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Bor(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Bxor(...)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Bnot` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Shl(n)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Shr(n)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Alternative(default)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Operator.Index<<V>>(key)` | [sugar/02](/ko/reference/sugar/02-operator/) |
| `q.Debounce{...}` | [sugar/03 — Debounce·Throttle](/ko/reference/sugar/03-debounce-throttle/) |
| `q.Throttle{...}` | [sugar/03](/ko/reference/sugar/03-debounce-throttle/) |
| `handle:Flush()` / `handle:Cancel()` | [sugar/03](/ko/reference/sugar/03-debounce-throttle/) |
| `factory:Flush()` / `factory:Cancel()`(`TimedGate` 브로드캐스트) | [sugar/03](/ko/reference/sugar/03-debounce-throttle/) |
| `q.OnCreated<<I>>(fn)` | [sugar/04 — 생명주기 훅](/ko/reference/sugar/04-lifecycle-hooks/) |
| `q.OnRendered<<I>>(fn)` | [sugar/04](/ko/reference/sugar/04-lifecycle-hooks/) |
| `q.OnDestroyed(fn)` | [sugar/04](/ko/reference/sugar/04-lifecycle-hooks/) |
| `q.Fallback(base, onError)` | [sugar/05 — Fallback·Traceback](/ko/reference/sugar/05-fallback-traceback/) |
| `q.Traceback(base, onError)` | [sugar/05](/ko/reference/sugar/05-fallback-traceback/) |

## Roblox 백엔드

| 심볼 | 페이지 |
|---|---|
| `q.D` | [roblox/01 — 설치](/ko/reference/roblox/01-install/) · [roblox/02](/ko/reference/roblox/02-d/#qd--네임스페이스와-생성되는-클래스) |
| `D.<Class>(props)` | [roblox/02 — D](/ko/reference/roblox/02-d/) |
| `D.New<<T>>(className)(props)` | [roblox/02](/ko/reference/roblox/02-d/) |
| 숏핸드 키 `UICorner` / `UIPadding` / `UIPaddingOffset` / `UIScale` | [roblox/02](/ko/reference/roblox/02-d/#숏핸드-키-넷) |
| `q.Claim(inst, descriptor)` | [roblox/04 — Claim·D.Mapper](/ko/reference/roblox/04-claim-mapper/) |
| `D.Mapper.<Class>(key)(props)` | [roblox/04](/ko/reference/roblox/04-claim-mapper/) |
| `D.Mapper.Root` | [roblox/04](/ko/reference/roblox/04-claim-mapper/) |
| `q.OnChange(name, fn)` | [roblox/05 — OnChange](/ko/reference/roblox/05-onchange/) |
| `q.Tween(opts)` | [roblox/06 — Tween·Animate](/ko/reference/roblox/06-tween-animate/) |
| `tween:Mapped(fn)` | [roblox/06](/ko/reference/roblox/06-tween-animate/) |
| `q.Animate(info)` | [roblox/06](/ko/reference/roblox/06-tween-animate/) |

## 확장 계약

| 심볼 | 페이지 |
|---|---|
| 주입 슬롯 전체(`native*`, `onDestroying`, `nativeClaim`, `nativeFindChild`, `addTag`, `removeTag`, `setAttr`, `setTimeout`, `clearTimeout`) | [extend/01 — 백엔드 프로바이더 규약](/ko/reference/extend/01-backend-provider-contract/) |
| `Handler` 레코드(`isHandlable`/`priority`/`process`/`name`/`keyType`) | [extend/02 — 디스패치 핸들러 계약](/ko/reference/extend/02-dispatch-handler-contract/#handler-레코드) |
| retractor `(nextValue, retracting)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#retractor) |
| `q.Dispatch.HANDLER_PRIORITY_HIGH` / `_NORMAL` / `_LOW` / `_FALLBACK` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#우선순위-밴드) |
| `q.Dispatch.addHandler(handler)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler) |
| `q.Dispatch.listHandlers()` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchlisthandlers) |
| `q.Dispatch.getHandler(inst, key, value)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchgethandlerinst-key-value) |
| `q.Dispatch.process(inst, key, value, index)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index) |
| `q.Dispatch.retractFrom(inst, key, index)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchretractfrominst-key-index) |
| `q.Dispatch.drive(inst, flattened)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchdriveinst-flattened) |
| `q.Dispatch.setLength(ownerKey, i, len, anchor?, element?)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchsetlengthownerkey-i-len-anchor-element) |
| `q.Dispatch.setOffsetSource(ownerKey, i, source)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchsetoffsetsourceownerkey-i-source) |
| `q.Dispatch.setEmpty(ownerKey, i, anchor?)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchsetemptyownerkey-i-anchor) |
| `q.Dispatch.getOffsetAt(ownerKey, at)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchgetoffsetatownerkey-at) |
| `q.Dispatch.getBlocker(ownerKey)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchgetblockerownerkey) |
| `q.Dispatch.getBookkeeping(ownerKey)` | [extend/02](/ko/reference/extend/02-dispatch-handler-contract/#qdispatchgetbookkeepingownerkey) |

## 타입

타입 계약의 정본은 `quad-types/src/init.luau` 한 파일이다 — `State<T>`/`Source<T>`/`Slot<T>`/`Ref<T>`/`Store<T>`/`Handler`/`Dispatch` 같은 값 타입, 입력 자리용 마커(`StateMarker<T>`/`SlotMarker<T>`), 출력 자리의 `FieldOut<T>`, 센티널 타입(`None`/`Detach`/`KeyGone`/`MapperRoot`)이 전부 거기 선언돼 있다.

**예외는 백엔드가 소유한 타입이다.** `Tween<T>`/`TweenData<T>`/`TweenOptions<T>`/`TweenOverride`/`TweenConstructor`/`AnimateInfo`/`AnimateFn`/`NewChild`/`OnChangeDescriptor`와 백엔드 확장 모양 `RobloxExtension`은 `quad-roblox/src/types.luau`(와 `quad-roblox/src/init.luau`)가 정본이고, 클래스별 생성 타입(`FrameParam<E>`/`FrameModifier`/`IntoFrame`/`PropTypes`/`PropTypesRead` 등)은 생성 모듈 `quad-roblox/src/D`가 정본이다 — 엔진 지식이 들어간 타입은 코어가 아니라 그 백엔드에 산다. 각 타입이 왜 그 모양인지는 [Quadnomicon 4권 — 공변 마커](/ko/quadnomicon/04-covariant-markers/)가 다룬다.
