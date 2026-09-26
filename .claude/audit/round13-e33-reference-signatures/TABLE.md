| 페이지:줄 심볼 | 문서 시그니처(앞 90자) | 타입 소스 | 판정 |
|---|---|---|---|
| core/01-quad-module.md:26 `New` | `() -> Quad` | quad-types/src/init.luau:645 | 일치 |
| core/01-quad-module.md:49 `RunInit` | `(self: Quad, initFn: (Quad) -> any) -> ()` | quad-types/src/init.luau:646 | 일치 |
| core/01-quad-module.md:81 `AddPlugin` | `<Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P` | quad-types/src/init.luau:647 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/01-quad-module.md:122 `UseProvider` | `<Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P` | quad-types/src/init.luau:653 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/01-quad-module.md:164 `Version` | `"3.2.0"` | quad-types/src/init.luau:643 | 일치 |
| core/01-quad-module.md:176 `debug` | `boolean` | quad-types/src/init.luau:644 | 일치 |
| core/01-quad-module.md:197 `errorNamespace` | `ErrorNamespace` | quad-types/src/init.luau:704 | 일치 |
| core/01-quad-module.md:197 `Namespace` | `{ setFuncLevel: (level: number, ...any) -> (), getFuncLevel: (func: any) -> number, getFir` | quad-error/src/init.luau:86 | 일치 |
| core/01-quad-module.md:223 `moduleIdentity` | `{}` | quad-types/src/init.luau:708 | 일치 |
| core/01-quad-module.md:252 `Relate` | `() -> Relate` | quad-types/src/init.luau:118 | 일치 |
| core/01-quad-module.md:252 `Relate` | `{ SetStrong: (self: Relate, inst: any, key: any, value: any) -> (), GetStrong: (self: Rela` | quad-types/src/init.luau:118 | 일치 |
| core/02-source.md:25 `Source` | `<T>(v: T) -> Source<T>` | quad-types/src/init.luau:219 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/02-source.md:25 `Source` | `State<T> & { read Revision: number, Set: (self: Source<T>, v: T) -> Source<T>, Emit: (self` | quad-types/src/init.luau:219 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/02-source.md:65 `Set` | `(self: Source<T>, v: T) -> Source<T>` | quad-types/src/init.luau:221 | 일치 |
| core/02-source.md:98 `Emit` | `(self: Source<T>) -> Source<T>` | quad-types/src/init.luau:222 | 일치 |
| core/02-source.md:123 `Revision` | `number` | quad-types/src/init.luau:220 | 일치 |
| core/03-state.md:41 `Get` | `(self: StateData<T>) -> T` | quad-types/src/init.luau:186 | 일치 (기계) |
| core/03-state.md:60 `Compute` | `<U>(self: StateData<T>, fn: (self: StateData<T>, previous: U?, ...any) -> U, ...any) -> St` | quad-types/src/init.luau:204 | 일치 |
| core/03-state.md:109 `Depend` | `(self: StateData<T>, ...any) -> State<T>` | quad-types/src/init.luau:206 | 일치 |
| core/03-state.md:141 `Apply` | `(<U>(self: StateData<T>, factory: (State<T>) -> U) -> U) & ((self: StateData<T>, factory: ` | quad-types/src/init.luau:212 | 일치 |
| core/03-state.md:177 `Observer` | `(self: StateData<T>, fn: ObserverFn<T>?) -> Observer` | quad-types/src/init.luau:214 | 일치 |
| core/03-state.md:177 `ObserverFn` | `(targetState: StateData<T>, self: Observer, emitFrom: (Epoch \| EpochSet)?) -> ()` | quad-types/src/init.luau:239 | 일치 |
| core/03-state.md:192 `Gate` | `(self: StateData<T>, setup: GateSetup) -> State<T>` | quad-types/src/init.luau:216 | 일치 |
| core/03-state.md:192 `GateEmit` | `(commit: boolean?) -> boolean` | quad-types/src/init.luau:260 | 일치 |
| core/03-state.md:192 `GateSetup` | `(emit: GateEmit) -> () -> ()` | quad-types/src/init.luau:261 | 일치 |
| core/04-store.md:23 `Store` | `(() -> Store<{}>) & (<T>(defaults: T) -> Store<T>)` | quad-types/src/init.luau:498 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/04-store.md:23 `Store` | `T & { Of: <U>(self: any, name: string) -> Source<U>, Names: (self: any) -> { string }, __r` | quad-types/src/init.luau:498 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/04-store.md:94 `Of` | `<U>(self: any, name: string) -> Source<U>` | quad-types/src/init.luau:499 | 일치 |
| core/04-store.md:130 `Names` | `(self: any) -> { string }` | quad-types/src/init.luau:500 | 일치 |
| core/05-observer-effect.md:70 `Observer` | `(self: StateData<T>, fn: ObserverFn<T>?) -> Observer` | quad-types/src/init.luau:231 | 일치 |
| core/05-observer-effect.md:70 `ObserverFn` | `(targetState: StateData<T>, self: Observer, emitFrom: (Epoch \| EpochSet)?) -> ()` | quad-types/src/init.luau:239 | 일치 |
| core/05-observer-effect.md:70 `Observer` | `{ read __quadObserver: true, read Subscribed: boolean, Subscribe: (self: Observer) -> Obse` | quad-types/src/init.luau:231 | 일치 |
| core/05-observer-effect.md:151 `Subscribe` | `(self: Observer) -> Observer` | quad-types/src/init.luau:234 | 일치 |
| core/05-observer-effect.md:161 `WeakSubscribe` | `(self: Observer) -> Observer` | quad-types/src/init.luau:235 | 일치 |
| core/05-observer-effect.md:171 `Unsubscribe` | `(self: Observer) -> Observer` | quad-types/src/init.luau:236 | 일치 |
| core/05-observer-effect.md:181 `WeakUnsubscribe` | `(self: Observer) -> Observer` | quad-types/src/init.luau:237 | 일치 |
| core/05-observer-effect.md:193 `Effect` | `(fn: EffectFn, ...any) -> Effect` | quad-types/src/init.luau:243 | 일치 |
| core/05-observer-effect.md:193 `EffectFn` | `(self: Effect) -> ...((dying: boolean) -> ())` | quad-types/src/init.luau:256 | 일치 |
| core/05-observer-effect.md:193 `Effect` | `{ read __quadEffect: true, read Subscribed: boolean, Rerun: (self: Effect) -> Effect, Subs` | quad-types/src/init.luau:243 | 일치 |
| core/05-observer-effect.md:260 `Rerun` | `(self: Effect) -> Effect` | quad-types/src/init.luau:246 | 일치 |
| core/05-observer-effect.md:268 `Subscribe` | `(self: Effect) -> Effect` | quad-types/src/init.luau:247 | 일치 |
| core/05-observer-effect.md:278 `WeakSubscribe` | `(self: Effect) -> Effect` | quad-types/src/init.luau:248 | 일치 |
| core/05-observer-effect.md:288 `Unsubscribe` | `(self: Effect) -> Effect` | quad-types/src/init.luau:249 | 일치 |
| core/05-observer-effect.md:298 `WeakUnsubscribe` | `(self: Effect) -> Effect` | quad-types/src/init.luau:250 | 일치 |
| core/06-slot.md:58 `Slot` | `<T>(initial: { read [number]: SlotElement<T> }?) -> Slot<T>` | quad-types/src/init.luau:720 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/06-slot.md:99 `Length` | `State<number>` | quad-types/src/init.luau:528 | 일치 |
| core/06-slot.md:125 `Offset` | `State<number>` | quad-types/src/init.luau:529 | 일치 |
| core/06-slot.md:143 `Add` | `(self: Slot<T>, element: SlotElement<T>, index: number?) -> number` | quad-types/src/init.luau:530 | 일치 |
| core/06-slot.md:183 `Remove` | `(self: Slot<T>, index: number) -> ()` | quad-types/src/init.luau:531 | 일치 |
| core/06-slot.md:193 `Replace` | `(self: Slot<T>, index: number, newElement: SlotElement<T>) -> ()` | quad-types/src/init.luau:532 | 일치 |
| core/06-slot.md:203 `Extract` | `(self: Slot<T>, index: number, newElement: SlotElement<T>?) -> SlotItem<T>` | quad-types/src/init.luau:533 | 일치 |
| core/06-slot.md:233 `ExtractAll` | `(self: Slot<T>) -> { SlotItem<T> }` | quad-types/src/init.luau:534 | 일치 |
| core/06-slot.md:245 `Splice` | `(self: Slot<T>, index: number, removeCount: number, ...SlotElement<T>) -> { SlotItem<T> }` | quad-types/src/init.luau:535 | 일치 |
| core/06-slot.md:273 `Clear` | `(self: Slot<T>) -> ()` | quad-types/src/init.luau:536 | 일치 |
| core/06-slot.md:285 `Move` | `(self: Slot<T>, oldIndex: number, newIndex: number) -> ()` | quad-types/src/init.luau:537 | 일치 |
| core/06-slot.md:297 `Swap` | `(self: Slot<T>, indexA: number, indexB: number) -> ()` | quad-types/src/init.luau:538 | 일치 |
| core/06-slot.md:309 `Get` | `(self: Slot<T>, index: number) -> SlotItem<T>?` | quad-types/src/init.luau:539 | 일치 |
| core/06-slot.md:321 `IndexOf` | `(self: Slot<T>, element: SlotElement<T>) -> number?` | quad-types/src/init.luau:540 | 일치 |
| core/06-slot.md:333 `List` | `<Item, UD>( self: Slot<T>, data: { Item } \| StateMarker<{ Item }>, updateFn: (ctx: { Item:` | quad-types/src/init.luau:541 | 일치 |
| core/06-slot.md:333 `SlotListOpts` | `{ read OwnsElements: boolean? }` | quad-types/src/init.luau:517 | 일치 |
| core/06-slot.md:447 `Single` | `<Item, UD>( self: Slot<T>, state: Item? \| StateMarker<Item?>, updateFn: ((ctx: { Item: Ite` | quad-types/src/init.luau:555 | 일치(텍스트) — 단 (b) 추론 결함, 문서의 '그대로 통과' 주장 과장 |
| core/06-slot.md:498 `Detach` | `Detach` | quad-types/src/init.luau:721 | 일치 |
| core/06-slot.md:539 `KeyGone` | `KeyGone` | quad-types/src/init.luau:722 | 일치 |
| core/06-slot.md:559 `dispose` | `(value: any) -> ()` | quad-types/src/init.luau:723 | 일치 |
| core/07-ref.md:77 `Ref` | `<T>(default: T) -> Ref<T>` | quad-types/src/init.luau:659 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/07-ref.md:112 `PreRef` | `<T>(default: T) -> PreRef<T>` | quad-types/src/init.luau:660 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/07-ref.md:143 `PostRef` | `<T>(default: T) -> PostRef<T>` | quad-types/src/init.luau:661 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/07-ref.md:173 `Value` | `T` | quad-types/src/init.luau:159 | 일치 |
| core/07-ref.md:187 `Revision` | `number` | quad-types/src/init.luau:160 | 일치 |
| core/07-ref.md:199 `Callbacks` | `{ [RefCallback<T> \| thread]: true }` | quad-types/src/init.luau:161 | 일치 |
| core/07-ref.md:213 `WeakCallbacks` | `{ [RefCallback<T>]: true }` | quad-types/src/init.luau:162 | 일치 |
| core/07-ref.md:225 `Set` | `<Self>(self: Self, value: T) -> Self` | quad-types/src/init.luau:167 | 일치 |
| core/07-ref.md:263 `Callback` | `<Self>(self: Self, fn: RefCallback<T>) -> Self` | quad-types/src/init.luau:168 | 일치 |
| core/07-ref.md:285 `WeakCallback` | `<Self>(self: Self, fn: RefCallback<T>) -> Self` | quad-types/src/init.luau:169 | 일치 |
| core/07-ref.md:297 `Uncallback` | `<Self>(self: Self, fn: RefCallback<T>) -> Self` | quad-types/src/init.luau:170 | 일치 |
| core/07-ref.md:309 `Wait` | `<Self>(self: Self, thread: thread?) -> Self` | quad-types/src/init.luau:173 | 일치 |
| core/07-ref.md:351 `Unwrap` | `(self: Ref<T>) -> StripNil<T>` | quad-types/src/init.luau:176 | 일치 |
| core/08-modifier.md:67 `Modifier` | `setmetatable<{ Overridden: (...any) -> any, TypedFactory: <T>(name: string) -> (...(Modifi` | quad-types/src/init.luau:425 | 일치 (기계) |
| core/08-modifier.md:178 `Peek` | `<T>(self: Modifier, key: string) -> FieldOut<T>?` | quad-types/src/init.luau:406 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| core/08-modifier.md:178 `FieldOut` | `T \| State<T> \| None` | quad-types/src/init.luau:198 | 일치 (기계) |
| core/08-modifier.md:214 `Apply` | `<U>(self: any, factory: (any) -> U) -> U` | quad-types/src/init.luau:412 | 일치 |
| core/08-modifier.md:244 `Overridden` | `(self: Modifier, ...any) -> any` | quad-types/src/init.luau:413 | 일치 |
| core/08-modifier.md:258 `As` | `<T>(self: Modifier, name: string?) -> T` | quad-types/src/init.luau:416 | 일치 |
| core/08-modifier.md:284 `As<Class>` | `(self: <Ancestor>Modifier) -> <Class>Modifier` | quad-roblox/src/Declaration/init.luau:2454 (AsFrame 예) | 부분 대조(생략형) — 드러난 부분 일치 |
| core/08-modifier.md:313 `Overridden` | `(...any) -> any` | quad-types/src/init.luau:426 | 일치 (기계) |
| core/08-modifier.md:350 `TypedFactory` | `<T>(name: string) -> (...(Modifier \| { [string]: any })) -> T` | quad-types/src/init.luau:427 | 일치 (기계) |
| core/08-modifier.md:390 `DefineSubtype` | `(parent: string, subtype: string) -> ()` | quad-types/src/init.luau:428 | 일치 (기계) |
| core/09-tag-attr.md:63 `Tag` | `setmetatable<{ Merged: (...TagMarker) -> Tag }, { __call: (self: any, ...TagNames) -> Tag ` | quad-types/src/init.luau:370 | 불일치 (a) — `...TagMarker?`/`...TagNames?`(nil 슬롯) 누락 |
| core/09-tag-attr.md:104 `Added` | `(self: Tag, names: TagNames?) -> Tag` | quad-types/src/init.luau:362 | 일치 (기계) |
| core/09-tag-attr.md:125 `Removed` | `(self: Tag, names: TagNames?) -> Tag` | quad-types/src/init.luau:363 | 일치 (기계) |
| core/09-tag-attr.md:137 `Contains` | `(self: Tag, ...string) -> boolean` | quad-types/src/init.luau:364 | 일치 (기계) |
| core/09-tag-attr.md:166 `Tag` | `setmetatable<{ …메소드… }, { __iter: TagIter }>` | quad-types/src/init.luau:360 | 부분 대조(생략형) — 드러난 부분 일치 |
| core/09-tag-attr.md:188 `Apply` | `<U>(self: Tag, factory: (Tag) -> U) -> U` | quad-types/src/init.luau:365 | 일치 (기계) |
| core/09-tag-attr.md:202 `Merged` | `(...TagMarker) -> Tag` | quad-types/src/init.luau:370 | 불일치 (a) — `(...TagMarker?) -> Tag` |
| core/09-tag-attr.md:256 `__call` | `(self: any, ...any) -> Attr` | quad-types/src/init.luau:384 | 일치 (기계) |
| core/09-tag-attr.md:303 `NameMap` | `(self: Attr) -> { [string]: any }` | quad-types/src/init.luau:379 | 일치 |
| core/09-tag-attr.md:324 `Merged` | `(...Attr) -> Attr` | quad-types/src/init.luau:382 | 일치 (기계) |
| core/09-tag-attr.md:339 `Overridden` | `(...Attr) -> Attr` | quad-types/src/init.luau:383 | 일치 (기계) |
| core/09-tag-attr.md:363 `AttrKey` | `(name: string) -> AttrKeyObject` | quad-types/src/init.luau:389 | 일치 (기계) |
| core/09-tag-attr.md:363 `AttrKeyObject` | `{ Name: string }` | quad-types/src/init.luau:386 | 불일치 (a) — 실제 `{ read Name: string }` |
| core/09-tag-attr.md:403 `StringAttr` | `AttrSugar<string>` | quad-types/src/init.luau:766 | 일치 |
| core/09-tag-attr.md:403 `AttrSugar` | `(name: string, value: T \| StateMarker<T> \| None) -> Attr` | quad-types/src/init.luau:392 | 일치 |
| core/09-tag-attr.md:443 `NumberAttr` | `AttrSugar<number>` | quad-types/src/init.luau:767 | 일치 |
| core/09-tag-attr.md:455 `BooleanAttr` | `AttrSugar<boolean>` | quad-types/src/init.luau:768 | 일치 |
| core/10-lifetime-sentinels.md:24 `None` | `None` | quad-types/src/init.luau:97 | 일치 |
| core/10-lifetime-sentinels.md:24 `None` | `{ read __quadNone: true }` | quad-types/src/init.luau:97 | 일치 |
| core/10-lifetime-sentinels.md:53 `Detach` | `Detach` | quad-types/src/init.luau:89 | 일치 |
| core/10-lifetime-sentinels.md:53 `Detach` | `{ read __quadDetach: true }` | quad-types/src/init.luau:89 | 일치 |
| core/10-lifetime-sentinels.md:68 `KeyGone` | `KeyGone` | quad-types/src/init.luau:90 | 일치 |
| core/10-lifetime-sentinels.md:68 `KeyGone` | `{ read __quadKeyGone: true }` | quad-types/src/init.luau:90 | 일치 |
| core/10-lifetime-sentinels.md:87 `Void` | `(...any) -> ()` | quad-types/src/init.luau:658 | 일치 |
| core/10-lifetime-sentinels.md:99 `dispose` | `(value: any) -> ()` | quad-types/src/init.luau:723 | 일치 |
| core/10-lifetime-sentinels.md:140 `MapperRoot` | `MapperRoot` | quad-types/src/init.luau:103 | 일치 |
| core/10-lifetime-sentinels.md:140 `MapperRoot` | `{ read __quadMapperRoot: true }` | quad-types/src/init.luau:103 | 일치 |
| core/10-lifetime-sentinels.md:151 `newMapperClass` | `(className: string) -> (key: any) -> (props: any) -> MapperDescriptor` | quad-types/src/init.luau:751 | 일치 |
| core/10-lifetime-sentinels.md:161 `bindLifetime` | `(inst: any, value: any) -> ()` | quad-types/src/init.luau:593 | 일치 |
| core/10-lifetime-sentinels.md:179 `unbindLifetime` | `(value: any) -> ()` | quad-types/src/init.luau:594 | 일치 |
| core/10-lifetime-sentinels.md:189 `canBound` | `(value: any) -> boolean` | quad-types/src/init.luau:595 | 일치 |
| core/10-lifetime-sentinels.md:199 `canExecute` | `(value: any) -> boolean` | quad-types/src/init.luau:596 | 일치 |
| extend/02-dispatch-handler-contract.md:26 `Handler` | `{ name: string?, keyType: ("number" \| "string")?, isHandlable: (inst: any, key: any, value` | quad-types/src/init.luau:448 | 일치 |
| extend/02-dispatch-handler-contract.md:52 `(retractor)` | `(nextValue: any?, retracting: boolean) -> ()` | quad-types/src/init.luau:457 | 일치(정적 — `Handler.process` 반환형과 같음) |
| extend/02-dispatch-handler-contract.md:81 `HANDLER_PRIORITY_HIGH` | `number` | quad-types/src/init.luau:472 | 일치 |
| extend/02-dispatch-handler-contract.md:81 `HANDLER_PRIORITY_NORMAL` | `number` | quad-types/src/init.luau:473 | 일치 |
| extend/02-dispatch-handler-contract.md:81 `HANDLER_PRIORITY_LOW` | `number` | quad-types/src/init.luau:474 | 일치 |
| extend/02-dispatch-handler-contract.md:81 `HANDLER_PRIORITY_FALLBACK` | `number` | quad-types/src/init.luau:475 | 일치 |
| extend/02-dispatch-handler-contract.md:103 `addHandler` | `(handler: Handler) -> ()` | quad-types/src/init.luau:469 | 일치 |
| extend/02-dispatch-handler-contract.md:121 `listHandlers` | `() -> { Handler }` | quad-types/src/init.luau:470 | 일치 |
| extend/02-dispatch-handler-contract.md:133 `getHandler` | `(inst: any, key: any, value: any) -> Handler?` | quad-types/src/init.luau:466 | 일치 |
| extend/02-dispatch-handler-contract.md:147 `process` | `(inst: any, key: any, value: any, index: number) -> ()` | quad-types/src/init.luau:467 | 일치 |
| extend/02-dispatch-handler-contract.md:180 `retractFrom` | `(inst: any, key: any, index: number) -> ()` | quad-types/src/init.luau:468 | 일치 |
| extend/02-dispatch-handler-contract.md:192 `drive` | `(inst: any, flattened: { [any]: any }) -> ()` | quad-types/src/init.luau:471 | 일치 |
| extend/02-dispatch-handler-contract.md:237 `setLength` | `(ownerKey: any, i: number, len: number \| StateMarker<number>, anchor: any?, element: any?)` | quad-types/src/init.luau:571 | 일치 |
| extend/02-dispatch-handler-contract.md:257 `setOffsetSource` | `(ownerKey: any, i: number, source: any) -> ()` | quad-types/src/init.luau:572 | 일치 |
| extend/02-dispatch-handler-contract.md:273 `setEmpty` | `(ownerKey: any, i: number, anchor: any?) -> ()` | quad-types/src/init.luau:575 | 일치 |
| extend/02-dispatch-handler-contract.md:283 `getOffsetAt` | `(ownerKey: any, at: number) -> number` | quad-types/src/init.luau:576 | 일치 |
| extend/02-dispatch-handler-contract.md:302 `getBlocker` | `(ownerKey: any) -> Blocker` | quad-types/src/init.luau:577 | 일치 |
| extend/02-dispatch-handler-contract.md:312 `getBookkeeping` | `(ownerKey: any) -> any` | quad-types/src/init.luau:578 | 일치 |
| extend/02-dispatch-handler-contract.md:324 `claimOwnerAt` | `(element: any, inst: any, k: any) -> boolean` | quad-types/src/init.luau:584 | 일치 |
| extend/02-dispatch-handler-contract.md:340 `releaseOwner` | `(element: any, ownerKey: any) -> ()` | quad-types/src/init.luau:585 | 일치 |
| roblox/01-install.md:35 `QuadRoblox` | `<T>(quad: T) -> RobloxExtension` | quad-roblox/src/init.luau:221 | 일치 (기계) |
| roblox/01-install.md:88 `UseProvider` | `<Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P` | quad-types/src/init.luau:653 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| roblox/02-d.md:39 `D.Frame` | `(FrameParam<FrameElem>) -> Frame` | quad-roblox/src/Declaration/init.luau:4926 | 일치 |
| roblox/02-d.md:39 `FrameParam` | `{ [number]: E, Size: PV8?, Visible: PV0?, MouseEnter: (((x: number, y: number) -> ()) \| St` | quad-roblox/src/Declaration/init.luau:299 | 일치 (기계) |
| roblox/02-d.md:333 `New` | `<T>(className: string) -> (props: any) -> T` | quad-roblox/src/Declaration/init.luau:4919 | 일치 |
| roblox/03-d-modifier.md:36 `D.Modifier.Frame` | `(...(FrameModifier \| { [string]: any })) -> FrameModifier` | quad-roblox/src/Declaration/init.luau:4874 | 일치 |
| roblox/03-d-modifier.md:86 `Size` | `(self: FrameModifier, value: Field<UDim2>) -> FrameModifier` | quad-roblox/src/Declaration/init.luau:2428 | 일치 |
| roblox/03-d-modifier.md:86 `FieldV` | `T \| Tween<T> \| StateMarker<T \| Tween<T>> \| None` | quad-roblox/src/Declaration/init.luau:52 | 일치 |
| roblox/03-d-modifier.md:86 `Field` | `FieldV<T> \| ((old: FieldOut<T>?) -> FieldV<T>?)` | quad-roblox/src/Declaration/init.luau:54 | 일치(텍스트) — (c) 이 페이지의 `FieldOut`은 core/08과 다른 별칭(Tween 포함) |
| roblox/03-d-modifier.md:173 `AsFrame` | `(self: GuiObjectModifier) -> FrameModifier` | quad-roblox/src/Declaration/init.luau:2639 | 일치 |
| roblox/03-d-modifier.md:173 `AsTextLabel` | `(self: GuiObjectModifier) -> TextLabelModifier` | quad-roblox/src/Declaration/init.luau:2647 | 일치 |
| roblox/03-d-modifier.md:173 `AsGuiObject` | `(self: GuiObjectModifier) -> GuiObjectModifier` | quad-roblox/src/Declaration/init.luau:2637 | 일치 |
| roblox/04-claim-mapper.md:34 `Claim` | `<T>(inst: T, desc: MapperDescriptor) -> T` | quad-types/src/init.luau:746 | 일치 |
| roblox/04-claim-mapper.md:144 `D.Mapper.Frame` | `(key: string \| MapperRoot) -> (FrameParam<FrameMapperElem>) -> MapperDescriptor` | quad-roblox/src/Declaration/init.luau:4841 | 일치 |
| roblox/04-claim-mapper.md:209 `newMapperClass` | `(className: string) -> (key: any) -> (props: any) -> MapperDescriptor` | quad-types/src/init.luau:751 | 일치 |
| roblox/04-claim-mapper.md:209 `MapperRoot` | `MapperRoot` | quad-types/src/init.luau:750 | 일치 |
| roblox/05-onchange.md:31 `OnChangeFn` | `<K>( name: K & keyof<PropTypesRead>, fn: (index<PropTypesRead, K>) -> () ) -> OnChangeDesc` | quad-roblox/src/Declaration/init.luau:2089 | 일치(텍스트) |
| roblox/05-onchange.md:31 `OnChangeDescriptor` | `{ Name: K, Callback: (index<PropTypesRead, K>) -> () }` | quad-roblox/src/Declaration/init.luau:2088 | 일치(생성 모듈) — (c) 패키지 재수출 `OnChangeDescriptor`는 다른 비제네릭 타입 |
| roblox/05-onchange.md:135 `OutFn` | `<K>( name: K & keyof<PropTypesRead>, src: Source<index<PropTypesRead, K>> ) -> OnChangeDes` | quad-roblox/src/init.luau:197 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| roblox/06-tween-animate.md:34 `TweenConstructor` | `<T>(opts: TweenOptions<T>) -> Tween<T>` | quad-roblox/src/types.luau:104 | 일치 (기계) |
| roblox/06-tween-animate.md:34 `TweenOverride` | `"Cancel" \| "Finish"` | quad-roblox/src/types.luau:56 | 일치 (기계) |
| roblox/06-tween-animate.md:34 `TweenOptions` | `{ read Value: T, read Info: TweenInfo?, read Time: number?, read Style: Enum.EasingStyle?,` | quad-roblox/src/types.luau:59 | 일치 (기계) |
| roblox/06-tween-animate.md:117 `Mapped` | `<T, U>(self: TweenData<T>, fn: (T) -> U) -> Tween<U>` | quad-roblox/src/types.luau:96 | 일치 (기계) |
| roblox/06-tween-animate.md:141 `isTween` | `(x: any) -> boolean` | quad-roblox/src/init.luau:218 | 일치 |
| roblox/06-tween-animate.md:155 `AnimateFn` | `(info: AnimateInfo) -> (self: any) -> State<Tween<any>>` | quad-roblox/src/types.luau:145 | 일치 (기계) |
| roblox/06-tween-animate.md:155 `AnimateInfo` | `{ read Info: (TweenInfo \| StateMarker<TweenInfo>)?, read Time: (number \| StateMarker<numbe` | quad-roblox/src/types.luau:129 | 일치 (기계) |
| sugar/01-context.md:26 `Context` | `ContextConstructor` | quad-types/src/init.luau:690 | 일치 |
| sugar/01-context.md:26 `ContextConstructor` | `setmetatable<{ Provider: <T>(name: string?) -> Provider<T> }, { __call: (self: any) -> Con` | quad-types/src/init.luau:328 | 일치 |
| sugar/01-context.md:44 `Provider` | `<T>(name: string?) -> Provider<T>` | quad-types/src/init.luau:328 | 일치 (기계) |
| sugar/01-context.md:44 `Provider` | `{ read __quadProvider: true, read __quadProviderValue: T, read __quadProviderAccepts: (T) ` | quad-types/src/init.luau:328 | 일치 (기계) |
| sugar/01-context.md:84 `Set` | `<T>(self: Context, provider: Provider<T>, value: T) -> Context` | quad-types/src/init.luau:324 | 일치 |
| sugar/01-context.md:117 `Get` | `<T>(self: Context, provider: Provider<T>) -> T` | quad-types/src/init.luau:325 | 일치 |
| sugar/01-context.md:135 `Peek` | `<T>(self: Context, provider: Provider<T>) -> T?` | quad-types/src/init.luau:326 | 일치 |
| sugar/01-context.md:147 `Name` | `string?` | quad-types/src/init.luau:320 | 일치 |
| sugar/02-operator.md:94 `Not` | `(self: any) -> State<boolean>` | quad-types/src/init.luau:335 | 일치 |
| sugar/02-operator.md:109 `Sum` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:336 | 일치 |
| sugar/02-operator.md:125 `Product` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:337 | 일치 |
| sugar/02-operator.md:135 `Min` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:338 | 일치 |
| sugar/02-operator.md:145 `Max` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:339 | 일치 |
| sugar/02-operator.md:155 `Clamp` | `(lo: NumArg, hi: NumArg) -> NumOp` | quad-types/src/init.luau:346 | 일치 |
| sugar/02-operator.md:170 `Band` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:340 | 일치 |
| sugar/02-operator.md:187 `Bor` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:341 | 일치 |
| sugar/02-operator.md:197 `Bxor` | `(...NumArg) -> NumOp` | quad-types/src/init.luau:342 | 일치 |
| sugar/02-operator.md:207 `Bnot` | `NumOp` | quad-types/src/init.luau:343 | 일치 |
| sugar/02-operator.md:217 `Shl` | `(n: NumArg) -> NumOp` | quad-types/src/init.luau:344 | 일치 |
| sugar/02-operator.md:232 `Shr` | `(n: NumArg) -> NumOp` | quad-types/src/init.luau:345 | 일치 |
| sugar/02-operator.md:242 `Alternative` | `<T>(default: T \| StateData<T>) -> (self: StateData<T?>) -> State<T>` | quad-types/src/init.luau:347 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| sugar/02-operator.md:261 `Indexed` | `<V>(key: any) -> (self: any) -> State<V>` | quad-types/src/init.luau:350 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| sugar/03-debounce-throttle.md:53 `Debounce` | `(opts: DebounceOptions) -> TimedGate` | quad-types/src/init.luau:674 | 일치 |
| sugar/03-debounce-throttle.md:53 `DebounceOptions` | `{ read Time: number \| StateMarker<number>, read Leading: boolean?, read Trailing: boolean?` | quad-types/src/init.luau:288 | 일치 |
| sugar/03-debounce-throttle.md:71 `Throttle` | `(opts: ThrottleOptions) -> TimedGate` | quad-types/src/init.luau:675 | 일치 |
| sugar/03-debounce-throttle.md:71 `ThrottleOptions` | `{ read Time: number \| StateMarker<number>, read Leading: boolean?, read Trailing: boolean?` | quad-types/src/init.luau:295 | 일치 |
| sugar/03-debounce-throttle.md:152 `Flush` | `(self: GateHandle) -> ()` | quad-types/src/init.luau:285 | 일치 |
| sugar/03-debounce-throttle.md:158 `Cancel` | `(self: GateHandle) -> ()` | quad-types/src/init.luau:286 | 일치 |
| sugar/04-lifecycle-hooks.md:49 `OnCreated` | `<I>(fn: (inst: I, ref: PreRef<I?>) -> ()) -> PreRef<I?>` | quad-types/src/init.luau:682 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| sugar/04-lifecycle-hooks.md:67 `OnRendered` | `<I>(fn: (inst: I, ref: PostRef<I?>) -> ()) -> PostRef<I?>` | quad-types/src/init.luau:683 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| sugar/04-lifecycle-hooks.md:85 `OnDestroyed` | `(fn: () -> ()) -> Effect` | quad-types/src/init.luau:684 | 일치 |
| sugar/05-fallback-traceback.md:49 `Fallback` | `<Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any) -> Err) -> (A...) -> Ok \| Err` | quad-types/src/init.luau:687 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| sugar/05-fallback-traceback.md:68 `Traceback` | `<Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any, trace: string) -> Err) -> (A...) -` | quad-types/src/init.luau:688 | 일치(정적) — 기계: 제네릭 함수 동일 출력(솔버 한계), 호출 프로브로 보강 |
| sugar/06-blocker.md:25 `Blocker` | `() -> Blocker` | quad-types/src/init.luau:264 | 일치 |
| sugar/06-blocker.md:25 `Blocker` | `{ read Blocking: boolean, On: (self: Blocker) -> Blocker, Off: (self: Blocker) -> Blocker,` | quad-types/src/init.luau:264 | 일치 |
| sugar/06-blocker.md:81 `On` | `(self: Blocker) -> Blocker` | quad-types/src/init.luau:268 | 일치 |
| sugar/06-blocker.md:89 `Off` | `(self: Blocker) -> Blocker` | quad-types/src/init.luau:269 | 일치 |
| sugar/06-blocker.md:101 `OffWithoutEmit` | `(self: Blocker) -> Blocker` | quad-types/src/init.luau:270 | 일치 |
| sugar/06-blocker.md:127 `Policy` | `(self: Blocker, emit: GateEmit) -> () -> ()` | quad-types/src/init.luau:271 | 일치 |
| sugar/06-blocker.md:127 `GateEmit` | `(commit: boolean?) -> boolean` | quad-types/src/init.luau:260 | 일치 |
