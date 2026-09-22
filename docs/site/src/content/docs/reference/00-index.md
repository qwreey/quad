---
title: 심볼 색인
description: quad 공개 표면 전체를 심볼 이름으로 찾아가는 색인
---
공개 표면의 심볼을 이름으로 찾는 자리입니다. 각 행의 링크가 그 심볼을 **자세히 설명하는 페이지**를 가리킵니다 — 같은 심볼이 두 페이지에 나오면(예: `Slot`의 센티널) 둘 다 적었습니다.

읽는 순서가 필요하면 색인이 아니라 트랙을 따라가세요: [시작하기](/getting-started/00-installation/) → [실전 레시피](/how-to/01-component-conventions/) → 여기.

표기 규약은 이렇습니다. 모듈 인스턴스는 `q`, 백엔드 표면은 `q.Declaration`을 `D`로 받아 씁니다. `q.X`는 모듈 표면의 값, `x:Method()`는 그 값의 메소드, `x.Field`는 필드입니다. `<<T>>`는 명시 타입 인자입니다.

## 에러 코드

quad가 던지는 모든 에러는 `QuadNNNN`으로 시작합니다 — 번호로 찾는 설명은 [에러 코드 색인](/reference/errors/00-index/).

## 모듈과 설치

quad 모듈 인스턴스를 만들고, 초기화 함수·플러그인·백엔드 프로바이더를 붙이는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.New()` | [core/01 — Quad 모듈](/reference/core/01-quad-module/#qnew) |
| `q:RunInit(initFn)` | [core/01](/reference/core/01-quad-module/#qruninitinitfn) |
| `q:AddPlugin(pluginFn)` | [core/01](/reference/core/01-quad-module/#qaddpluginpluginfn) |
| `q:UseProvider(providerFn)` | [core/01](/reference/core/01-quad-module/#quseproviderproviderfn) · [roblox/01 — 설치](/reference/roblox/01-install/) |
| `q.Version` | [core/01](/reference/core/01-quad-module/#qversion) |
| `q.debug` | [core/01](/reference/core/01-quad-module/#qdebug) |
| `q.errorNamespace` | [core/01](/reference/core/01-quad-module/#qerrornamespace) · [extend/01](/reference/extend/01-backend-provider-contract/) |
| `q.Relate()` | [core/01](/reference/core/01-quad-module/#qrelate) |
| `QuadRoblox` | [roblox/01 — 설치](/reference/roblox/01-install/) |
| `RobloxExtension` | [roblox/01](/reference/roblox/01-install/) |

## 반응형 코어

값이 흐르는 그래프를 만드는 심볼들 — 값을 쓰는 원천, 거기서 파생되는 노드, 이름 붙은 원천 묶음.

| 심볼 | 페이지 |
|---|---|
| `q.Source(value)` | [core/02 — Source](/reference/core/02-source/) |
| `source:Set(v)` | [core/02](/reference/core/02-source/) |
| `source:Emit()` | [core/02](/reference/core/02-source/) |
| `source.Revision` | [core/02](/reference/core/02-source/) |
| `state:Get()` | [core/03 — State](/reference/core/03-state/) |
| `state:Compute(fn, ...deps)` | [core/03](/reference/core/03-state/) |
| `state:Depend(...)` | [core/03](/reference/core/03-state/) |
| `state:Apply(factory)` | [core/03](/reference/core/03-state/) · [sugar/06](/reference/sugar/06-blocker/) |
| `state:Observer(fn)` | [core/05 — Observer·Effect](/reference/core/05-observer-effect/) · [core/03](/reference/core/03-state/) |
| `state:Gate(setup)` | [core/03](/reference/core/03-state/) |
| `q.Store(defaults)` | [core/04 — Store](/reference/core/04-store/) |
| `store.key`(선언된 필드) | [core/04](/reference/core/04-store/) |
| `store:Of<<U>>(name)` | [core/04](/reference/core/04-store/) |
| `store:Names()` | [core/04](/reference/core/04-store/) |

## 구독 핸들

값이 바뀔 때 부를 콜백을 그래프의 잎에 다는 핸들 둘과, 그 구독을 켜고 끄는 메소드들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Effect(fn, ...deps)` | [core/05 — Observer·Effect](/reference/core/05-observer-effect/) |
| `observer.Subscribed` | [core/05](/reference/core/05-observer-effect/) |
| `observer:Subscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `observer:WeakSubscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `observer:Unsubscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `observer:WeakUnsubscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `effect:Rerun()` | [core/05](/reference/core/05-observer-effect/) |
| `effect:Subscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `effect:WeakSubscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `effect:Unsubscribe()` | [core/05](/reference/core/05-observer-effect/) |
| `effect:WeakUnsubscribe()` | [core/05](/reference/core/05-observer-effect/) |

## 전파 게이트

값은 항상 최신으로 두고 **아래로의 통지만** 묶었다가 한 번에 내보내는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Blocker()` | [sugar/06 — Blocker](/reference/sugar/06-blocker/) |
| `blocker.Blocking` | [sugar/06](/reference/sugar/06-blocker/) |
| `blocker:On()` | [sugar/06](/reference/sugar/06-blocker/) |
| `blocker:Off()` | [sugar/06](/reference/sugar/06-blocker/) |
| `blocker:OffWithoutEmit()` | [sugar/06](/reference/sugar/06-blocker/) |
| `blocker:Policy(emit)` | [sugar/06](/reference/sugar/06-blocker/) |

## Slot

자식이 들어갈 자리를 잡고, 수동 CRUD나 데이터 기반 목록으로 그 안을 채우는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Slot<<T>>(initial?)` | [core/06 — Slot](/reference/core/06-slot/) |
| `slot.Length` | [core/06](/reference/core/06-slot/) |
| `slot.Offset` | [core/06](/reference/core/06-slot/) |
| `slot:Add(element, index?)` | [core/06](/reference/core/06-slot/) |
| `slot:Remove(index)` | [core/06](/reference/core/06-slot/) |
| `slot:Replace(index, newElement)` | [core/06](/reference/core/06-slot/) |
| `slot:Extract(index, newElement?)` | [core/06](/reference/core/06-slot/) |
| `slot:ExtractAll()` | [core/06](/reference/core/06-slot/) |
| `slot:Splice(index, removeCount, ...)` | [core/06](/reference/core/06-slot/) |
| `slot:Clear()` | [core/06](/reference/core/06-slot/) |
| `slot:Move(oldIndex, newIndex)` | [core/06](/reference/core/06-slot/) |
| `slot:Swap(indexA, indexB)` | [core/06](/reference/core/06-slot/) |
| `slot:Get(index)` | [core/06](/reference/core/06-slot/) |
| `slot:IndexOf(element)` | [core/06](/reference/core/06-slot/) |
| `slot:List(data, updateFn, keyFn?, opts?)` | [core/06](/reference/core/06-slot/) |
| `slot:Single(state, updateFn?, opts?)` | [core/06](/reference/core/06-slot/) |

## Ref

quad가 만든 인스턴스를 손에 쥐는 세 종류의 참조와, 채워질 때를 기다리거나 받아 보는 방법들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Ref<<T>>(default)` | [core/07 — Ref](/reference/core/07-ref/) |
| `q.PreRef<<T>>(default)` | [core/07](/reference/core/07-ref/) |
| `q.PostRef<<T>>(default)` | [core/07](/reference/core/07-ref/) |
| `ref.Value` | [core/07](/reference/core/07-ref/) |
| `ref.Revision` | [core/07](/reference/core/07-ref/) |
| `ref.Callbacks` | [core/07](/reference/core/07-ref/) |
| `ref.WeakCallbacks` | [core/07](/reference/core/07-ref/) |
| `ref:Set(value)` | [core/07](/reference/core/07-ref/) |
| `ref:Callback(fn)` | [core/07](/reference/core/07-ref/) |
| `ref:WeakCallback(fn)` | [core/07](/reference/core/07-ref/) |
| `ref:Uncallback(fn)` | [core/07](/reference/core/07-ref/) |
| `ref:Wait(thread?)` | [core/07](/reference/core/07-ref/) |
| `ref:Unwrap()` | [core/07](/reference/core/07-ref/) |

## Modifier

프로퍼티 묶음을 불변 값으로 들고 다니며 합성·오버라이드·다운캐스트하는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Modifier(...)` | [core/08 — Modifier](/reference/core/08-modifier/) |
| `mod:<Field>(value)` | [core/08](/reference/core/08-modifier/) · [roblox/03](/reference/roblox/03-d-modifier/) |
| `mod:Peek<<T>>(key)` | [core/08](/reference/core/08-modifier/) |
| `mod:Apply(factory)` | [core/08](/reference/core/08-modifier/) |
| `mod:Overridden(...)` | [core/08](/reference/core/08-modifier/) |
| `mod:As(name)` | [core/08](/reference/core/08-modifier/) |
| `mod:As<Class>()` | [core/08](/reference/core/08-modifier/) · [roblox/03](/reference/roblox/03-d-modifier/) |
| `q.Modifier.Overridden(...)` | [core/08](/reference/core/08-modifier/) |
| `q.Modifier.TypedFactory<<T>>(name)` | [core/08](/reference/core/08-modifier/) |
| `q.Modifier.DefineSubtype(parent, subtype)` | [core/08](/reference/core/08-modifier/) |
| `D.Modifier.<Class>(...)` | [roblox/03 — D.Modifier](/reference/roblox/03-d-modifier/) |
| `mod:As()` / `mod:As<<T>>()` | [roblox/03](/reference/roblox/03-d-modifier/#modas--modasname--modast) · [core/08](/reference/core/08-modifier/) |
| `Into<Class>` / `<Class>Modifier` | [roblox/03](/reference/roblox/03-d-modifier/#intoclass--classmodifier) |

## Tag / Attr

인스턴스에 `CollectionService` 태그와 어트리뷰트를 선언적으로 붙이는, 숫자 키 자리의 값 객체 둘입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Tag(...names)` | [core/09 — Tag·Attr](/reference/core/09-tag-attr/) |
| `tag:Added(names)` | [core/09](/reference/core/09-tag-attr/) |
| `tag:Removed(names)` | [core/09](/reference/core/09-tag-attr/) |
| `tag:Contains(...names)` | [core/09](/reference/core/09-tag-attr/) |
| `for name in tag` | [core/09](/reference/core/09-tag-attr/) |
| `tag:Apply(factory)` | [core/09](/reference/core/09-tag-attr/) |
| `q.Tag.Merged(...tags)` | [core/09](/reference/core/09-tag-attr/) |
| `q.Attr(...)` | [core/09](/reference/core/09-tag-attr/) |
| `attr:NameMap()` | [core/09](/reference/core/09-tag-attr/) |
| `q.Attr.Merged(...)` | [core/09](/reference/core/09-tag-attr/) |
| `q.Attr.Overridden(...)` | [core/09](/reference/core/09-tag-attr/) |
| `q.AttrKey(name)` | [core/09](/reference/core/09-tag-attr/) |
| `q.StringAttr(name, value)` | [core/09](/reference/core/09-tag-attr/) |
| `q.NumberAttr(name, value)` | [core/09](/reference/core/09-tag-attr/) |
| `q.BooleanAttr(name, value)` | [core/09](/reference/core/09-tag-attr/) |

## 센티널과 생명주기

자리를 비우거나 원소를 떼어 두는 특수 값들과, 값의 수명을 인스턴스에 묶는 백엔드 표면입니다.

| 심볼 | 페이지 |
|---|---|
| `q.None` | [core/10 — 생명주기와 센티널](/reference/core/10-lifetime-sentinels/#qnone) |
| `q.Detach` | [core/10](/reference/core/10-lifetime-sentinels/#qdetach) · [core/06](/reference/core/06-slot/) |
| `q.KeyGone` | [core/10](/reference/core/10-lifetime-sentinels/#qkeygone) · [core/06](/reference/core/06-slot/) |
| `q.Void` | [core/10](/reference/core/10-lifetime-sentinels/#qvoid) |
| `q.dispose(value)` | [core/10](/reference/core/10-lifetime-sentinels/#qdisposevalue) · [core/06](/reference/core/06-slot/) |
| `q.MapperRoot` | [core/10](/reference/core/10-lifetime-sentinels/#qmapperroot) · [roblox/04](/reference/roblox/04-claim-mapper/) |
| `q.newMapperClass(className)` | [core/10](/reference/core/10-lifetime-sentinels/#qnewmapperclassclassname) |
| `q.Backend.bindLifetime(inst, value)` | [core/10](/reference/core/10-lifetime-sentinels/#qbackendbindlifetimeinst-value) · [extend/01](/reference/extend/01-backend-provider-contract/) |
| `q.Backend.unbindLifetime(value)` | [core/10](/reference/core/10-lifetime-sentinels/#qbackendunbindlifetimevalue) · [extend/01](/reference/extend/01-backend-provider-contract/) |
| `q.Backend.canBound(value)` | [core/10](/reference/core/10-lifetime-sentinels/#qbackendcanboundvalue) · [extend/01](/reference/extend/01-backend-provider-contract/) |
| `q.Backend.canExecute(value)` | [core/10](/reference/core/10-lifetime-sentinels/#qbackendcanexecutevalue) · [extend/01](/reference/extend/01-backend-provider-contract/) |

## 브랜드 술어

받은 값이 quad의 어떤 종류인지 되묻는 술어 묶음입니다.

`q.isEpoch` · `q.isSource` · `q.isState` · `q.isStore` · `q.isObserver` · `q.isEffect` · `q.isBlocker` · `q.isContext` · `q.isProvider` · `q.isModifier` · `q.isRef` · `q.isPreRef` · `q.isPostRef` · `q.isMapperDescriptor` · `q.isSlot` · `q.isTag` · `q.isAttr` · `q.isAttrKey` — 전부 [core/11 — 브랜드 술어](/reference/core/11-predicates/)의 한 표에 있습니다.

| 심볼 | 페이지 |
|---|---|
| `q.Backend.isInst(value)` | [core/11](/reference/core/11-predicates/) · [extend/01](/reference/extend/01-backend-provider-contract/) |
| `q.isTween(x)` | [core/11](/reference/core/11-predicates/) · [roblox/06](/reference/roblox/06-tween-animate/) |

## 슈거

코어 위에 순수하게 얹힌 것들 — 값 가방, 연산 콤비네이터, 시간 게이트, 생명주기 훅, 에러 격리.

| 심볼 | 페이지 |
|---|---|
| `q.Context()` | [sugar/01 — Context](/reference/sugar/01-context/) |
| `q.Context.Provider(name?)` | [sugar/01](/reference/sugar/01-context/) |
| `ctx:Set(provider, value)` | [sugar/01](/reference/sugar/01-context/) |
| `ctx:Get(provider)` | [sugar/01](/reference/sugar/01-context/) |
| `ctx:Peek(provider)` | [sugar/01](/reference/sugar/01-context/) |
| `provider.Name` | [sugar/01](/reference/sugar/01-context/) |
| `q.Operator.Not` | [sugar/02 — Operator](/reference/sugar/02-operator/) |
| `q.Operator.Sum(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Product(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Min(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Max(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Clamp(lo, hi)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Band(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Bor(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Bxor(...)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Bnot` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Shl(n)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Shr(n)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Alternative(default)` | [sugar/02](/reference/sugar/02-operator/) |
| `q.Operator.Indexed<<V>>(key)`(3.0.0에서는 `Index`, 3.1.0부터 `Indexed`) | [sugar/02](/reference/sugar/02-operator/) |
| `q.Debounce{...}` | [sugar/03 — Debounce·Throttle](/reference/sugar/03-debounce-throttle/) |
| `q.Throttle{...}` | [sugar/03](/reference/sugar/03-debounce-throttle/) |
| `handle:Flush()` / `handle:Cancel()` | [sugar/03](/reference/sugar/03-debounce-throttle/) |
| `factory:Flush()` / `factory:Cancel()`(`TimedGate` 브로드캐스트) | [sugar/03](/reference/sugar/03-debounce-throttle/) |
| `q.OnCreated<<I>>(fn)` | [sugar/04 — 생명주기 훅](/reference/sugar/04-lifecycle-hooks/) |
| `q.OnRendered<<I>>(fn)` | [sugar/04](/reference/sugar/04-lifecycle-hooks/) |
| `q.OnDestroyed(fn)` | [sugar/04](/reference/sugar/04-lifecycle-hooks/) |
| `q.Fallback(base, onError)` | [sugar/05 — Fallback·Traceback](/reference/sugar/05-fallback-traceback/) |
| `q.Traceback(base, onError)` | [sugar/05](/reference/sugar/05-fallback-traceback/) |

## Roblox 백엔드

`quad-roblox`가 얹는 표면 — 인스턴스 선언, 이미 있는 트리의 `Claim`, 프로퍼티 감시, 트윈.

| 심볼 | 페이지 |
|---|---|
| `q.Declaration`(3.1.0까지는 `q.D`) | [roblox/01 — 설치](/reference/roblox/01-install/) · [roblox/02](/reference/roblox/02-d/#qdeclaration--네임스페이스와-생성되는-클래스) |
| `D.<Class>(props)` | [roblox/02 — Declaration](/reference/roblox/02-d/) |
| `D.New<<T>>(className)(props)` | [roblox/02](/reference/roblox/02-d/) |
| 숏핸드 키 `UICorner` / `UIPadding` / `UIPaddingOffset` / `UIScale` | [roblox/02](/reference/roblox/02-d/#숏핸드-키-넷) |
| `q.Claim(inst, descriptor)` | [roblox/04 — Claim·D.Mapper](/reference/roblox/04-claim-mapper/) |
| `D.Mapper.<Class>(key)(props)` | [roblox/04](/reference/roblox/04-claim-mapper/) |
| `D.Mapper.Root` | [roblox/04](/reference/roblox/04-claim-mapper/) |
| `q.OnChange(name, fn)` | [roblox/05 — OnChange](/reference/roblox/05-onchange/) |
| `q.Out(name, src)` | [roblox/05 — OnChange](/reference/roblox/05-onchange/#qoutname-src) |
| `q.Tween(opts)` | [roblox/06 — Tween·Animate](/reference/roblox/06-tween-animate/) |
| `tween:Mapped(fn)` | [roblox/06](/reference/roblox/06-tween-animate/) |
| `q.Animate(info)` | [roblox/06](/reference/roblox/06-tween-animate/) |

## 확장 계약

자기 백엔드나 핸들러를 직접 붙일 때 쓰는 계약 — 주입 op, 핸들러 레코드, 디스패치와 부기 표면.

| 심볼 | 페이지 |
|---|---|
| 주입 슬롯 전체(`native*`, `onDestroying`, `nativeClaim`, `isClaimed`, `nativeFindChild`, `addTag`, `removeTag`, `setAttr`, `setTimeout`, `clearTimeout`) | [extend/01 — 백엔드 프로바이더 규약](/reference/extend/01-backend-provider-contract/) |
| `Handler` 레코드(`isHandlable`/`priority`/`process`/`name`/`keyType`) | [extend/02 — 디스패치 핸들러 계약](/reference/extend/02-dispatch-handler-contract/#handler-레코드) |
| retractor `(nextValue, retracting)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#retractor) |
| `q.Dispatch.HANDLER_PRIORITY_HIGH` / `_NORMAL` / `_LOW` / `_FALLBACK` | [extend/02](/reference/extend/02-dispatch-handler-contract/#우선순위-밴드) |
| `q.Dispatch.addHandler(handler)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qdispatchaddhandlerhandler) |
| `q.Dispatch.listHandlers()` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qdispatchlisthandlers) |
| `q.Dispatch.getHandler(inst, key, value)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qdispatchgethandlerinst-key-value) |
| `q.Dispatch.process(inst, key, value, index)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qdispatchprocessinst-key-value-index) |
| `q.Dispatch.retractFrom(inst, key, index)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qdispatchretractfrominst-key-index) |
| `q.Dispatch.drive(inst, flattened)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qdispatchdriveinst-flattened) |
| `q.Bookkeeping.setLength(ownerKey, i, len, anchor?, element?)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetlengthownerkey-i-len-anchor-element) |
| `q.Bookkeeping.setOffsetSource(ownerKey, i, source)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetoffsetsourceownerkey-i-source) |
| `q.Bookkeeping.setEmpty(ownerKey, i, anchor?)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepingsetemptyownerkey-i-anchor) |
| `q.Bookkeeping.getOffsetAt(ownerKey, at)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetoffsetatownerkey-at) |
| `q.Bookkeeping.getBlocker(ownerKey)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetblockerownerkey) |
| `q.Bookkeeping.getBookkeeping(ownerKey)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepinggetbookkeepingownerkey) |
| `q.Bookkeeping.claimOwnerAt(element, inst, k)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepingclaimowneratelement-inst-k) |
| `q.Bookkeeping.releaseOwner(element, ownerKey)` | [extend/02](/reference/extend/02-dispatch-handler-contract/#qbookkeepingreleaseownerelement-ownerkey) |

## 타입

타입 계약의 정본은 `quad-types/src/init.luau` 한 파일입니다 — `State<T>`/`Source<T>`/`Slot<T>`/`Ref<T>`/`Store<T>`/`Handler`/`Dispatch` 같은 값 타입, 입력 자리용 마커(`StateMarker<T>`/`SlotMarker<T>`), 출력 자리의 `FieldOut<T>`, 센티널 타입(`None`/`Detach`/`KeyGone`/`MapperRoot`)이 전부 거기 선언돼 있습니다.

**예외는 백엔드가 소유한 타입입니다.** `Tween<T>`/`TweenData<T>`/`TweenOptions<T>`/`TweenOverride`/`TweenConstructor`/`AnimateInfo`/`AnimateFn`/`NewChild`/`OnChangeDescriptor`와 백엔드 확장 모양 `RobloxExtension`은 `quad-roblox/src/types.luau`(와 `quad-roblox/src/init.luau`)가 정본이고, 클래스별 생성 타입(`FrameParam<E>`/`FrameModifier`/`IntoFrame`/`PropTypes`/`PropTypesRead` 등)은 생성 모듈 `quad-roblox/src/Declaration`이 정본입니다 — 엔진 지식이 들어간 타입은 코어가 아니라 그 백엔드에 삽니다. 각 타입이 왜 그 모양인지는 [Quadnomicon 4권 — 공변 마커](/quadnomicon/04-covariant-markers/)가 다룹니다.
