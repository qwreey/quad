---
title: 심볼 색인
description: quad 공개 표면 전체를 심볼 이름으로 찾아가는 색인
---
# 심볼 색인

공개 표면의 심볼을 이름으로 찾는 자리입니다. 각 행의 링크가 그 심볼을 **자세히 설명하는 페이지**를 가리킵니다 — 같은 심볼이 두 페이지에 나오면(예: `Slot`의 센티널) 둘 다 적었습니다.

읽는 순서가 필요하면 색인이 아니라 트랙을 따라가세요: [시작하기](../getting-started/00-installation.md) → [실전 레시피](../how-to/01-component-conventions.md) → 여기.

표기 규약은 이렇습니다. 모듈 인스턴스는 `q`이고, 백엔드 표면은 `q.Elem "Frame"`처럼 클래스 이름을 먼저 받는 꼴로 씁니다. `q.X`는 모듈 표면의 값, `x:Method()`는 그 값의 메소드, `x.Field`는 필드입니다. `<<T>>`는 명시 타입 인자입니다.

## 관측과 계약

**정의되지 않은 동작**이나 **콜백이 던진 뒤의 상태**를 다루는 문장은 약속이 아니라 관측입니다. 그런 문장에는 "관측 — 계약 아님"을 붙여 두었습니다 — 지금의 동작을 기록한 것이고, 결과를 단정형으로 적었어도 다음 버전에서 예고 없이 바뀔 수 있으니 기대어 코드를 짜지 마세요. 던진 뒤에 대해 quad가 약속하는 것은 둘뿐입니다. 약속하는 회복은 하나 — 던진 [`Observer`](./core/05-observer-effect.md#stateobserverfn) 콜백은 다음 변경에 다시 돕니다. 약속하는 비회복도 하나 — `fn`이 던진 [`Effect`](./core/05-observer-effect.md#qeffectfn-deps)는 죽어서 다시 돌지 않습니다. 둘이 왜 다른지는 [Quadnomicon 12 — 파동을 받는 두 방식](../quadnomicon/12-two-ways-to-receive-a-wave.md)에서 풀어 봅니다.

## 에러 코드

quad가 던지는 모든 에러는 `QuadNNNN`으로 시작합니다 — 번호로 찾는 설명은 [에러 코드 색인](./errors/00-index.md).

## 모듈과 설치

quad 모듈 인스턴스를 만들고, 초기화 함수·플러그인·백엔드 프로바이더를 붙이는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.NewModule()`(3.3까지 `q.New()`) | [core/01 — Quad 모듈](./core/01-quad-module.md#qnewmodule) |
| `q.Raw` | [core/01](./core/01-quad-module.md#qraw) |
| `q:RunInit(initFn)` | [core/01](./core/01-quad-module.md#qruninitinitfn) |
| `q:AddPlugin(pluginFn)` | [core/01](./core/01-quad-module.md#qaddpluginpluginfn) |
| `q:UseProvider(providerFn)` | [core/01](./core/01-quad-module.md#quseproviderproviderfn) · [roblox/01 — 설치](./roblox/01-install.md) |
| `q.Version` | [core/01](./core/01-quad-module.md#qversion) |
| `q:GetOrCreate(key, build)` | [core/01](./core/01-quad-module.md#qgetorcreatekey-build) |
| `q:AssertProvider(name, versionPattern)` | [core/01](./core/01-quad-module.md#qassertprovidername-versionpattern) |
| `q.debug` | [core/01](./core/01-quad-module.md#qdebug) |
| `q.errorNamespace` | [core/01](./core/01-quad-module.md#qerrornamespace) · [extend/01](./extend/01-backend-provider-contract.md) |
| `q.Relate()` | [core/01](./core/01-quad-module.md#qrelate) |
| `q.moduleIdentity` | [core/01](./core/01-quad-module.md#qmoduleidentity) |
| `QuadRoblox` | [roblox/01 — 설치](./roblox/01-install.md) |
| `RobloxExtension` | [roblox/01](./roblox/01-install.md) |

## 반응형 코어

값이 흐르는 그래프를 만드는 심볼들 — 값을 쓰는 원천, 거기서 파생되는 노드, 이름 붙은 원천 묶음.

| 심볼 | 페이지 |
|---|---|
| `q.Source(value)` | [core/02 — Source](./core/02-source.md) |
| `source:Set(v)` | [core/02](./core/02-source.md) |
| `source:SetIfChanged(v)` | [core/02](./core/02-source.md) |
| `source:SetAndDispose(v)` | [core/02](./core/02-source.md) |
| `source:Emit()` | [core/02](./core/02-source.md) |
| `source.Revision` | [core/02](./core/02-source.md) |
| `state:Get()` | [core/03 — State](./core/03-state.md) |
| `state:Compute(fn, ...deps)` | [core/03](./core/03-state.md) |
| `state:Depend(...)` | [core/03](./core/03-state.md) |
| `state:Apply(factory)` | [core/03](./core/03-state.md) · [sugar/06](./sugar/06-blocker.md) |
| `state:Observer(fn)` | [core/05 — Observer·Effect](./core/05-observer-effect.md) · [core/03](./core/03-state.md) |
| `state:Gate(setup)` | [core/03](./core/03-state.md) |
| `q.Store(defaults)` | [core/04 — Store](./core/04-store.md) |
| `store.key`(선언된 필드) | [core/04](./core/04-store.md) |
| `store:Of<<U>>(name)` | [core/04](./core/04-store.md) |
| `store:Names()` | [core/04](./core/04-store.md) |

## 구독 핸들

값이 바뀔 때 부를 콜백을 그래프의 잎에 다는 핸들 둘과, 그 구독을 켜고 끄는 메소드들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Effect(fn, ...deps)` | [core/05 — Observer·Effect](./core/05-observer-effect.md) |
| `observer.Subscribed` | [core/05](./core/05-observer-effect.md) |
| `observer:Subscribe()` | [core/05](./core/05-observer-effect.md) |
| `observer:WeakSubscribe()` | [core/05](./core/05-observer-effect.md) |
| `observer:Unsubscribe()` | [core/05](./core/05-observer-effect.md) |
| `observer:WeakUnsubscribe()` | [core/05](./core/05-observer-effect.md) |
| `effect:Rerun()` | [core/05](./core/05-observer-effect.md) |
| `effect:Subscribe()` | [core/05](./core/05-observer-effect.md) |
| `effect:WeakSubscribe()` | [core/05](./core/05-observer-effect.md) |
| `effect:Unsubscribe()` | [core/05](./core/05-observer-effect.md) |
| `effect:WeakUnsubscribe()` | [core/05](./core/05-observer-effect.md) |

## 전파 게이트

값은 항상 최신으로 두고 **아래로의 통지만** 묶었다가 한 번에 내보내는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Blocker()` | [sugar/06 — Blocker](./sugar/06-blocker.md) |
| `blocker.Blocking` | [sugar/06](./sugar/06-blocker.md) |
| `blocker:On()` | [sugar/06](./sugar/06-blocker.md) |
| `blocker:Off()` | [sugar/06](./sugar/06-blocker.md) |
| `blocker:OffWithoutEmit()` | [sugar/06](./sugar/06-blocker.md) |
| `blocker:Policy(emit)` | [sugar/06](./sugar/06-blocker.md) |

## Slot

자식이 들어갈 자리를 잡고, 수동 CRUD나 데이터 기반 목록으로 그 안을 채우는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Slot<<T>>(initial?)` | [core/06 — Slot](./core/06-slot.md) |
| `slot.Length` | [core/06](./core/06-slot.md) |
| `slot.Offset` | [core/06](./core/06-slot.md) |
| `slot:Add(element, index?)` | [core/06](./core/06-slot.md) |
| `slot:Remove(index)` | [core/06](./core/06-slot.md) |
| `slot:Replace(index, newElement)` | [core/06](./core/06-slot.md) |
| `slot:Extract(index, newElement?)` | [core/06](./core/06-slot.md) |
| `slot:ExtractAll()` | [core/06](./core/06-slot.md) |
| `slot:Splice(index, removeCount, ...)` | [core/06](./core/06-slot.md) |
| `slot:Clear()` | [core/06](./core/06-slot.md) |
| `slot:Move(oldIndex, newIndex)` | [core/06](./core/06-slot.md) |
| `slot:Swap(indexA, indexB)` | [core/06](./core/06-slot.md) |
| `slot:Get(index)` | [core/06](./core/06-slot.md) |
| `slot:IndexOf(element)` | [core/06](./core/06-slot.md) |
| `slot:WhenIdle(fn)` | [core/06](./core/06-slot.md) |
| `slot:List(data, updateFn, keyFn?, opts?)` | [core/06](./core/06-slot.md) |
| `slot:Single(state, updateFn?, opts?)` | [core/06](./core/06-slot.md) |

## Ref

quad가 만든 인스턴스를 손에 쥐는 세 종류의 참조와, 채워질 때를 기다리거나 받아 보는 방법들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Ref<<T>>(default)` | [core/07 — Ref](./core/07-ref.md) |
| `q.PreRef<<T>>(default)` | [core/07](./core/07-ref.md) |
| `q.PostRef<<T>>(default)` | [core/07](./core/07-ref.md) |
| `ref.Value` | [core/07](./core/07-ref.md) |
| `ref.Revision` | [core/07](./core/07-ref.md) |
| `ref.Callbacks` | [core/07](./core/07-ref.md) |
| `ref.WeakCallbacks` | [core/07](./core/07-ref.md) |
| `ref:Set(value)` | [core/07](./core/07-ref.md) |
| `ref:Callback(fn)` | [core/07](./core/07-ref.md) |
| `ref:WeakCallback(fn)` | [core/07](./core/07-ref.md) |
| `ref:Uncallback(fn)` | [core/07](./core/07-ref.md) |
| `ref:Wait(thread?)` | [core/07](./core/07-ref.md) |
| `ref:Unwrap()` | [core/07](./core/07-ref.md) |

## Modifier

프로퍼티 묶음을 불변 값으로 들고 다니며 합성·오버라이드·다운캐스트하는 심볼들입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Raw.Modifier(...)`(3.3까지 `q.Modifier(...)`) | [core/08 — Modifier](./core/08-modifier.md) |
| `mod:<Field>(value)` | [core/08](./core/08-modifier.md) · [roblox/03](./roblox/03-modifier-spread.md#modfieldvalue) |
| `mod:Peek<<T>>(key)` | [core/08](./core/08-modifier.md) |
| `mod:Apply(factory)` | [core/08](./core/08-modifier.md) |
| `mod:Overridden(...)` | [core/08](./core/08-modifier.md) |
| `mod:As(name)` | [core/08](./core/08-modifier.md) |
| `mod:As<Class>()` | [core/08](./core/08-modifier.md) · [roblox/03](./roblox/03-modifier-spread.md#modasclass) |
| `q.Raw.Modifier.Overridden(...)` | [core/08](./core/08-modifier.md) |
| `q.Raw.Modifier.TypedFactory<<T>>(name)` | [core/08](./core/08-modifier.md) |
| `q.Raw.Modifier.DefineSubtype(parent, subtype)` | [core/08](./core/08-modifier.md) |
| `q.Modifier "Class" (...)`(3.3까지 `D.Modifier.<Class>(...)`) | [roblox/03 — Modifier와 Spread](./roblox/03-modifier-spread.md#qmodifier-class-) |
| `mod:As()` / `mod:As<<T>>()` | [roblox/03](./roblox/03-modifier-spread.md#modas--modasname--modast) · [core/08](./core/08-modifier.md) |
| `Modifier<C>` / `ModifierInto<C>`(3.3까지 `<Class>Modifier` / `Into<Class>`) | [roblox/03](./roblox/03-modifier-spread.md#modifierc--modifierintoc--spreadc--spreadintoc) |
| `q.Spread "Class" (props)` / `spread:Append(other)` | [roblox/03](./roblox/03-modifier-spread.md#qspread-class-props) |
| `Spread<C>` / `SpreadInto<C>` | [roblox/03](./roblox/03-modifier-spread.md#modifierc--modifierintoc--spreadc--spreadintoc) |
| `q.Raw.Spread(t)` | [core/01](./core/01-quad-module.md#qraw) |

## Tag / Attr

인스턴스에 `CollectionService` 태그와 어트리뷰트를 선언적으로 붙이는, 숫자 키 자리의 값 객체 둘입니다.

| 심볼 | 페이지 |
|---|---|
| `q.Tag(...names)` | [core/09 — Tag·Attr](./core/09-tag-attr.md) |
| `tag:Added(names)` | [core/09](./core/09-tag-attr.md) |
| `tag:Removed(names)` | [core/09](./core/09-tag-attr.md) |
| `tag:Contains(...names)` | [core/09](./core/09-tag-attr.md) |
| `for name in tag` | [core/09](./core/09-tag-attr.md) |
| `tag:Apply(factory)` | [core/09](./core/09-tag-attr.md) |
| `q.Tag.Merged(...tags)` | [core/09](./core/09-tag-attr.md) |
| `q.Attr(...)` | [core/09](./core/09-tag-attr.md) |
| `attr:NameMap()` | [core/09](./core/09-tag-attr.md) |
| `q.Attr.Merged(...)` | [core/09](./core/09-tag-attr.md) |
| `q.Attr.Overridden(...)` | [core/09](./core/09-tag-attr.md) |
| `q.AttrKey(name)` | [core/09](./core/09-tag-attr.md) |
| `q.StringAttr(name, value)` | [core/09](./core/09-tag-attr.md) |
| `q.NumberAttr(name, value)` | [core/09](./core/09-tag-attr.md) |
| `q.BooleanAttr(name, value)` | [core/09](./core/09-tag-attr.md) |

## 센티널과 생명주기

자리를 비우거나 원소를 떼어 두는 특수 값들과, 값의 수명을 인스턴스에 묶는 백엔드 표면입니다.

| 심볼 | 페이지 |
|---|---|
| `q.None` | [core/10 — 생명주기와 센티널](./core/10-lifetime-sentinels.md#qnone) |
| `q.Detach` | [core/10](./core/10-lifetime-sentinels.md#qdetach) · [core/06](./core/06-slot.md) |
| `q.KeyGone` | [core/10](./core/10-lifetime-sentinels.md#qkeygone) · [core/06](./core/06-slot.md) |
| `q.Void` | [core/10](./core/10-lifetime-sentinels.md#qvoid) |
| `q.dispose(value)` | [core/10](./core/10-lifetime-sentinels.md#qdisposevalue) · [core/06](./core/06-slot.md) |
| `q.MapperRoot` | [core/10](./core/10-lifetime-sentinels.md#qmapperroot) · [roblox/04](./roblox/04-claim-mapper.md) |
| `q.Raw.Mapper(className)`(3.3까지 `q.newMapperClass`) | [core/01](./core/01-quad-module.md#qraw) |
| `q.Backend.bindLifetime(inst, value)` | [core/10](./core/10-lifetime-sentinels.md#qbackendbindlifetimeinst-value) · [extend/01](./extend/01-backend-provider-contract.md) |
| `q.Backend.unbindLifetime(value)` | [core/10](./core/10-lifetime-sentinels.md#qbackendunbindlifetimevalue) · [extend/01](./extend/01-backend-provider-contract.md) |
| `q.Backend.canBound(value)` | [core/10](./core/10-lifetime-sentinels.md#qbackendcanboundvalue) · [extend/01](./extend/01-backend-provider-contract.md) |
| `q.Backend.canExecute(value)` | [core/10](./core/10-lifetime-sentinels.md#qbackendcanexecutevalue) · [extend/01](./extend/01-backend-provider-contract.md) |
| `q.Backend.isClaimed(inst)` | [core/10](./core/10-lifetime-sentinels.md#qbackendisclaimedinst) · [extend/01](./extend/01-backend-provider-contract.md#3-판정훅조회-op) |

## 브랜드 술어

받은 값이 quad의 어떤 종류인지 되묻는 술어 묶음입니다.

`q.isEpoch` · `q.isSource` · `q.isState` · `q.isStore` · `q.isObserver` · `q.isEffect` · `q.isBlocker` · `q.isContext` · `q.isProvider` · `q.isModifier` · `q.isRef` · `q.isPreRef` · `q.isPostRef` · `q.isMapperDescriptor` · `q.isSlot` · `q.isTag` · `q.isAttr` · `q.isAttrKey` — 전부 [core/11 — 브랜드 술어](./core/11-predicates.md)의 한 표에 있습니다.

| 심볼 | 페이지 |
|---|---|
| `q.Backend.isInst(value)` | [core/11](./core/11-predicates.md) · [extend/01](./extend/01-backend-provider-contract.md) |
| `q.Backend.provider` | [extend/01](./extend/01-backend-provider-contract.md#qbackendprovider) · [core/01](./core/01-quad-module.md#qassertprovidername-versionpattern) |
| `q.isTween(x)` | [core/11](./core/11-predicates.md) · [roblox/06](./roblox/06-tween-animate.md) |

## 슈거

코어 위에 순수하게 얹힌 것들 — 값 가방, 연산 콤비네이터, 시간 게이트, 생명주기 훅, 에러 격리.

| 심볼 | 페이지 |
|---|---|
| `q.Context()` | [sugar/01 — Context](./sugar/01-context.md) |
| `q.Context.Provider(name?)` | [sugar/01](./sugar/01-context.md) |
| `ctx:Set(provider, value)` | [sugar/01](./sugar/01-context.md) |
| `ctx:Get(provider)` | [sugar/01](./sugar/01-context.md) |
| `ctx:Peek(provider)` | [sugar/01](./sugar/01-context.md) |
| `provider.Name` | [sugar/01](./sugar/01-context.md) |
| `q.Operator.Not` | [sugar/02 — Operator](./sugar/02-operator.md) |
| `q.Operator.Sum(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Product(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Min(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Max(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Clamp(lo, hi)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Band(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Bor(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Bxor(...)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Bnot` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Shl(n)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Shr(n)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Alternative(default)` | [sugar/02](./sugar/02-operator.md) |
| `q.Operator.Indexed<<V>>(key)`(3.0.0에서는 `Index`, 3.1.0부터 `Indexed`) | [sugar/02](./sugar/02-operator.md) |
| `q.Debounce{...}` | [sugar/03 — Debounce·Throttle](./sugar/03-debounce-throttle.md) |
| `q.Throttle{...}` | [sugar/03](./sugar/03-debounce-throttle.md) |
| `handle:Flush()` / `handle:Cancel()` | [sugar/03](./sugar/03-debounce-throttle.md) |
| `factory:Flush()` / `factory:Cancel()`(`TimedGate` 브로드캐스트) | [sugar/03](./sugar/03-debounce-throttle.md) |
| `q.OnCreated<<I>>(fn)` | [sugar/04 — 생명주기 훅](./sugar/04-lifecycle-hooks.md) |
| `q.OnRendered<<I>>(fn)` | [sugar/04](./sugar/04-lifecycle-hooks.md) |
| `q.OnDestroyed(fn)` | [sugar/04](./sugar/04-lifecycle-hooks.md) |
| `q.Fallback(base, onError)` | [sugar/05 — Fallback·Traceback](./sugar/05-fallback-traceback.md) |
| `q.Traceback(base, onError)` | [sugar/05](./sugar/05-fallback-traceback.md) |

## Roblox 백엔드

`quad-roblox`가 얹는 표면 — 인스턴스 선언, 이미 있는 트리의 `Claim`, 프로퍼티 감시, 트윈.

| 심볼 | 페이지 |
|---|---|
| `q.Elem "Class" (props)`(3.3까지 `q.Declaration` — `D.<Class>(props)`·`D.New`) | [roblox/02 — Elem](./roblox/02-elem.md#qelem-class-props) |
| 숏핸드 키 `UICorner` / `UIPadding` / `UIPaddingOffset` / `UIScale` | [roblox/02](./roblox/02-elem.md#숏핸드-키-넷) |
| `q.ForClasses<<Map>>()` | [roblox/02](./roblox/02-elem.md#qforclassesmap) |
| `Props<C>` / `PropsHashPart<C>` / `PropsArrayItem<C>` / `MapperProps<C>` / `ElemCtor<C>` / `PropertyMap<C>` | [roblox/02](./roblox/02-elem.md#타입-이름--propsc--elemctorc--propertymapc) |
| `Modifier<C>` / `ModifierInto<C>` / `Spread<C>` / `SpreadInto<C>` / `ModifierField<T>` / `ModifierFieldOut<T>` | [roblox/03](./roblox/03-modifier-spread.md#modifierc--modifierintoc--spreadc--spreadintoc) |
| `OnChangeDescriptor<K>` / `OnEventDescriptor<K>` | [roblox/05](./roblox/05-onchange.md#qonchange-class-name-fn) |
| `q.Claim(inst, descriptor)` | [roblox/04 — Claim·Mapper](./roblox/04-claim-mapper.md) |
| `q.Mapper "Class" (key)(props)`(3.3까지 `D.Mapper.<Class>`) | [roblox/04](./roblox/04-claim-mapper.md#qmapper-class-keyprops) |
| `q.MapperRoot`(3.3까지 `D.Mapper.Root`도) | [roblox/04](./roblox/04-claim-mapper.md#qmapperroot) |
| `q.OnChange "Class" "Name" (fn)` | [roblox/05 — OnChange·OnEvent·Out](./roblox/05-onchange.md#qonchange-class-name-fn) |
| `q.OnEvent "Class" "Name" (fn)` | [roblox/05](./roblox/05-onchange.md#qonevent-class-name-fn) |
| `q.Out "Class" "Name" (src)` | [roblox/05](./roblox/05-onchange.md#qout-class-name-src) |
| `q.Tween(opts)` | [roblox/06 — Tween·Animate](./roblox/06-tween-animate.md) |
| `tween:Mapped(fn)` | [roblox/06](./roblox/06-tween-animate.md) |
| `q.Animate(info)` | [roblox/06](./roblox/06-tween-animate.md) |

## 확장 계약

자기 백엔드나 핸들러를 직접 붙일 때 쓰는 계약 — 주입 op, 핸들러 레코드, 디스패치와 부기 표면.

| 심볼 | 페이지 |
|---|---|
| 주입 슬롯 전체(`holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`, `native*`, `onDestroying`, `nativeClaim`, `isClaimed`, `nativeFindChild`, `addTag`, `removeTag`, `setAttr`, `setTimeout`, `clearTimeout`) | [extend/01 — 백엔드 프로바이더 규약](./extend/01-backend-provider-contract.md) |
| `Brand()`(`quad_types` 런타임 값) · `brand:Register(v)` · `brand:Is(v)` | [extend/01 §3.1](./extend/01-backend-provider-contract.md#31-자기-값-타입에-브랜드-붙이기--brand) |
| `Handler` 레코드(`isHandlable`/`priority`/`process`/`name`/`keyType`/`debugOnly`) | [extend/02 — 디스패치 핸들러 계약](./extend/02-dispatch-handler-contract.md#handler-레코드) |
| retractor `(nextValue, retracting)` | [extend/02](./extend/02-dispatch-handler-contract.md#retractor) |
| `q.Dispatch.HANDLER_PRIORITY_HIGH` / `_NORMAL` / `_LOW` / `_FALLBACK` | [extend/02](./extend/02-dispatch-handler-contract.md#우선순위-밴드) |
| `q.Dispatch.addHandler(handler)` | [extend/02](./extend/02-dispatch-handler-contract.md#qdispatchaddhandlerhandler) |
| `q.Dispatch.listHandlers()` | [extend/02](./extend/02-dispatch-handler-contract.md#qdispatchlisthandlers) |
| `q.Dispatch.getHandler(inst, key, value)` | [extend/02](./extend/02-dispatch-handler-contract.md#qdispatchgethandlerinst-key-value) |
| `q.Dispatch.process(inst, key, value, index)` | [extend/02](./extend/02-dispatch-handler-contract.md#qdispatchprocessinst-key-value-index) |
| `q.Dispatch.retractFrom(inst, key, index)` | [extend/02](./extend/02-dispatch-handler-contract.md#qdispatchretractfrominst-key-index) |
| `q.Dispatch.drive(inst, flattened)` | [extend/02](./extend/02-dispatch-handler-contract.md#qdispatchdriveinst-flattened) |
| `q.Bookkeeping.setLength(ownerKey, i, len, anchor?, element?)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepingsetlengthownerkey-i-len-anchor-element) |
| `q.Bookkeeping.setOffsetSource(ownerKey, i, source)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepingsetoffsetsourceownerkey-i-source) |
| `q.Bookkeeping.setEmpty(ownerKey, i, anchor?)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepingsetemptyownerkey-i-anchor) |
| `q.Bookkeeping.getOffsetAt(ownerKey, at)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepinggetoffsetatownerkey-at) |
| `q.Bookkeeping.getBookkeeping(ownerKey)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepinggetbookkeepingownerkey) |
| `q.Bookkeeping.claimOwnerAt(element, inst, k)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepingclaimowneratelement-inst-k) |
| `q.Bookkeeping.releaseOwner(element, ownerKey)` | [extend/02](./extend/02-dispatch-handler-contract.md#qbookkeepingreleaseownerelement-ownerkey) |

## 타입

타입 계약의 정본은 `quad-types/src/init.luau` 한 파일입니다 — `State<T>`/`Source<T>`/`Slot<T>`/`Ref<T>`/`Store<T>`/`Handler`/`Dispatch` 같은 값 타입, 입력 자리용 마커(`StateMarker<T>`/`SlotMarker<T>`), 출력 자리의 `ModifierFieldOut<T>`, 센티널 타입(`None`/`Detach`/`KeyGone`/`MapperRoot`)이 전부 거기 선언돼 있습니다.

**예외는 백엔드가 소유한 타입입니다.** `Tween<T>`/`TweenData<T>`/`TweenOptions<T>`/`TweenOverride`/`TweenConstructor`/`AnimateInfo`/`AnimateFn`과 백엔드 확장 모양 `RobloxExtension`은 `quad-roblox/src/types.luau`(와 `quad-roblox/src/init.luau`)가 정본이고, 클래스를 인자로 받는 표면 타입(`Props<C>`/`Modifier<C>`/`ModifierInto<C>`/`Spread<C>`/`OnChangeDescriptor<K>` 등)은 타입 함수 모듈 `quad-roblox/src/Surface/init.luau`가 정본입니다 — 엔진 지식이 들어간 타입은 코어가 아니라 그 백엔드에 삽니다. 각 타입이 왜 그 모양인지는 [Quadnomicon 4권 — 공변 마커](../quadnomicon/04-covariant-markers.md)가 다룹니다.
