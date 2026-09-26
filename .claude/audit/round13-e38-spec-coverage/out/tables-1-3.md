### 표 1 — 멤버(모듈 키 68 + 멤버 134 = doc-coverage 202)

dyn = 구현 함수의 런타임 실행 횟수(luau --coverage FNDA, 호출자 무관; 필드·값은 "-"), stat = spec/smoke 소스의 직접 언급 수(주석 제외), specs = 실행한 spec 수.

| 심볼 | dyn | specs | stat | 판정 |
|---|---|---|---|---|
| q.Version | - | 0 | 1 | OK |
| q.debug | - | 0 | 5 | OK |
| q.New | 247 | 61 | 72 | OK |
| q.RunInit | 7173 | 61 | 10 | OK |
| q.AddPlugin | 12 | 2 | 10 | OK |
| q.UseProvider | 161 | 44 | 4 | OK |
| q.Relate | 3327 | 61 | 4 | OK |
| q.Void | - | 0 | 20 | OK |
| q.Ref | 77 | 12 | 41 | OK |
| q.PreRef | 17 | 5 | 14 | OK |
| q.PostRef | 14 | 4 | 12 | OK |
| q.Source | 825 | 43 | 302 | OK |
| q.Store | 31 | 5 | 12 | OK |
| q.Effect | 94 | 10 | 19 | OK |
| q.Blocker | 648 | 30 | 8 | OK |
| q.Debounce | 24 | 3 | 7 | OK |
| q.Throttle | 13 | 2 | 2 | OK |
| q.OnCreated | 6 | 1 | 1 | OK |
| q.OnRendered | 5 | 1 | 1 | OK |
| q.OnDestroyed | 7 | 1 | 1 | OK |
| q.Fallback | 6 | 2 | 2 | OK |
| q.Traceback | 4 | 1 | 1 | OK |
| q.Context | 5 | 2 | 5 | OK |
| q.Operator | - | 0 | 1 | OK |
| q.Dispatch | - | 0 | 347 | OK |
| q.Bookkeeping | - | 0 | 143 | OK |
| q.Backend | - | 0 | 211 | OK |
| q.errorNamespace | - | 0 | 7 | OK |
| q.moduleIdentity | - | 0 | 4 | OK |
| q.None | - | 0 | 65 | OK |
| q.Slot | 191 | 11 | 76 | OK |
| q.Detach | - | 0 | 5 | OK |
| q.KeyGone | - | 0 | 19 | OK |
| q.dispose | 21 | 5 | 21 | OK |
| q.isSlot | 7399 | 30 | 4 | OK |
| q.isEpoch | 1614 | 44 | 8 | OK |
| q.isSource | 11337 | 45 | 10 | OK |
| q.isState | 10789 | 44 | 17 | OK |
| q.isStore | 394 | 33 | 4 | OK |
| q.isObserver | 13974 | 34 | 4 | OK |
| q.isEffect | 18640 | 33 | 4 | OK |
| q.isBlocker | 357 | 32 | 2 | OK |
| q.isContext | 355 | 30 | 3 | OK |
| q.isProvider | 376 | 30 | 3 | OK |
| q.isModifier | 3112 | 46 | 5 | OK |
| q.isRef | 1139 | 36 | 13 | OK |
| q.isPreRef | 2392 | 36 | 12 | OK |
| q.isPostRef | 2389 | 36 | 12 | OK |
| q.isMapperDescriptor | 1266 | 32 | 0 | 간접만(spec 직접 호출 0) |
| q.Claim | 34 | 2 | 34 | OK |
| q.MapperRoot | - | 0 | 5 | OK |
| q.newMapperClass | 875 | 22 | 3 | OK |
| q.isTag | 1132 | 29 | 3 | OK |
| q.isAttr | 429 | 29 | 4 | OK |
| q.isAttrKey | 1296 | 32 | 1 | OK |
| q.Tag | 247 | 6 | 50 | OK |
| q.Modifier | 58 | 8 | 55 | OK |
| q.Attr | 27 | 3 | 29 | OK |
| q.AttrKey | 21 | 7 | 21 | OK |
| q.StringAttr | - | 0 | 13 | OK |
| q.NumberAttr | - | 0 | 4 | OK |
| q.BooleanAttr | - | 0 | 3 | OK |
| q.Declaration | - | 0 | 154 | OK |
| q.OnChange | 12 | 2 | 12 | OK |
| q.Out | 5 | 1 | 7 | OK |
| q.Animate | 22 | 3 | 10 | OK |
| q.Tween | 88 | 5 | 31 | OK |
| q.isTween | 562 | 11 | 12 | OK |
| State.Compute | 122 | 19 | 51 | OK |
| State.Depend | 6 | 3 | 7 | OK |
| State.Apply | 90 | 11 | 110 | OK |
| State.Observer | 510 | 31 | 52 | OK |
| State.Gate | 55 | 6 | 18 | OK |
| Source.Revision | - | 0 | 23 | OK |
| Source.Set | 647 | 35 | 419 | OK |
| Source.Emit | 2 | 2 | 3 | OK |
| Store.Of | 13 | 1 | 12 | OK |
| Store.Names | 13 | 3 | 11 | OK |
| Slot.Length | - | 0 | 54 | OK |
| Slot.Offset | - | 0 | 38 | OK |
| Slot.Add | 174 | 7 | 136 | OK |
| Slot.Remove | 7 | 2 | 7 | OK |
| Slot.Replace | 5 | 2 | 5 | OK |
| Slot.Extract | 10 | 2 | 10 | OK |
| Slot.ExtractAll | 2 | 1 | 2 | OK |
| Slot.Splice | 22 | 2 | 23 | OK |
| Slot.Clear | 5 | 2 | 5 | OK |
| Slot.Move | 12 | 1 | 12 | OK |
| Slot.Swap | 6 | 1 | 6 | OK |
| Slot.Get | 95 | 1 | 369 | OK |
| Slot.IndexOf | 128 | 1 | 21 | OK |
| Slot.List | 71 | 4 | 60 | OK |
| Slot.Single | 39 | 3 | 23 | OK |
| Ref.Value | - | 0 | 56 | OK |
| Ref.Revision | - | 0 | 23 | OK |
| Ref.Callbacks | - | 0 | 12 | OK |
| Ref.WeakCallbacks | - | 0 | 4 | OK |
| Ref.Set | 163 | 9 | 419 | OK |
| Ref.Callback | 34 | 4 | 29 | OK |
| Ref.WeakCallback | 9 | 2 | 4 | OK |
| Ref.Uncallback | 6 | 1 | 6 | OK |
| Ref.Wait | 10 | 2 | 13 | OK |
| Ref.Unwrap | 4 | 1 | 6 | OK |
| Observer.Subscribed | - | 0 | 15 | OK |
| Observer.Subscribe | 24 | 6 | 50 | OK |
| Observer.WeakSubscribe | 44 | 8 | 8 | OK |
| Observer.Unsubscribe | 7 | 2 | 27 | OK |
| Observer.WeakUnsubscribe | 5 | 2 | 9 | OK |
| Effect.Subscribed | - | 0 | 15 | OK |
| Effect.Rerun | 40 | 5 | 0 | 간접만(spec 직접 호출 0) |
| Effect.Subscribe | 26 | 4 | 50 | OK |
| Effect.WeakSubscribe | 2 | 1 | 8 | OK |
| Effect.Unsubscribe | 20 | 3 | 27 | OK |
| Effect.WeakUnsubscribe | 4 | 1 | 9 | OK |
| Blocker.Blocking | - | 0 | 9 | OK |
| Blocker.On | 917 | 30 | 11 | OK |
| Blocker.Off | 9 | 2 | 9 | OK |
| Blocker.OffWithoutEmit | 807 | 27 | 2 | OK |
| Blocker.Policy | 41 | 4 | 3 | OK |
| Modifier.Peek | 9 | 1 | 20 | OK |
| Modifier.Apply | 5 | 2 | 110 | OK |
| Modifier.Overridden | 9 | 2 | 17 | OK |
| Modifier.As | 6 | 2 | 8 | OK |
| Tag.Added | 17 | 1 | 13 | OK |
| Tag.Removed | 11 | 1 | 7 | OK |
| Tag.Contains | 251 | 3 | 39 | OK |
| Tag.Apply | 3 | 1 | 110 | OK |
| Brand.Register | 4207 | 47 | 14 | OK |
| Brand.Is | 78110 | 47 | 12 | OK |
| Operator.Not | - | 0 | 1 | OK |
| Operator.Sum | - | 0 | 9 | OK |
| Operator.Product | - | 0 | 1 | OK |
| Operator.Min | - | 0 | 1 | OK |
| Operator.Max | - | 0 | 1 | OK |
| Operator.Band | - | 0 | 3 | OK |
| Operator.Bor | - | 0 | 1 | OK |
| Operator.Bxor | - | 0 | 1 | OK |
| Operator.Bnot | - | 0 | 2 | OK |
| Operator.Shl | - | 0 | 2 | OK |
| Operator.Shr | - | 0 | 1 | OK |
| Operator.Clamp | 4 | 1 | 7 | OK |
| Operator.Alternative | 4 | 1 | 5 | OK |
| Operator.Indexed | 6 | 1 | 8 | OK |
| Relate.SetStrong | 5003 | 61 | 5 | OK |
| Relate.GetStrong | 8866 | 61 | 6 | OK |
| Relate.SetWeak | 35307 | 31 | 5 | OK |
| Relate.GetWeak | 49802 | 33 | 4 | OK |
| Backend.bindLifetime | 6211 | 29 | 54 | OK |
| Backend.unbindLifetime | 5159 | 18 | 14 | OK |
| Backend.canBound | 6315 | 30 | 19 | OK |
| Backend.canExecute | 474 | 24 | 40 | OK |
| Backend.holdLifetime | 6194 | 29 | 0 | 간접만(spec 직접 호출 0) |
| Backend.releaseLifetime | 5157 | 18 | 0 | 간접만(spec 직접 호출 0) |
| Backend.isHeld | 6782 | 31 | 0 | 간접만(spec 직접 호출 0) |
| Backend.isHeldBy | 7 | 4 | 0 | 간접만(spec 직접 호출 0) |
| Backend.onDestroying | 71 | 7 | 5 | OK |
| Backend.setTimeout | 79 | 2 | 5 | OK |
| Backend.clearTimeout | 31 | 2 | 3 | OK |
| Backend.nativeInsert | 91 | 6 | 1 | OK |
| Backend.nativeExtract | 28 | 3 | 2 | OK |
| Backend.nativeRemove | 13 | 2 | 1 | OK |
| Backend.nativeMove | - | 0 | 1 | OK |
| Backend.nativeSwap | - | 0 | 1 | OK |
| Backend.nativeDispose | 19 | 3 | 1 | OK |
| Backend.isInst | 527 | 7 | 10 | OK |
| Backend.nativeClaim | 193 | 10 | 33 | OK |
| Backend.isClaimed | 626 | 10 | 5 | OK |
| Backend.nativeFindChild | 30 | 3 | 4 | OK |
| Backend.addTag | 8 | 2 | 5 | OK |
| Backend.removeTag | 6 | 2 | 2 | OK |
| Backend.setAttr | 34 | 2 | 4 | OK |
| Attr.NameMap | 36 | 2 | 7 | OK |
| Context.Set | 9 | 1 | 419 | OK |
| Context.Get | 8 | 1 | 369 | OK |
| Context.Peek | 5 | 1 | 20 | OK |
| TimedGate.Flush | 8 | 1 | 8 | OK |
| TimedGate.Cancel | 5 | 1 | 5 | OK |
| GateHandle.Flush | 8 | 1 | 8 | OK |
| GateHandle.Cancel | 5 | 1 | 5 | OK |
| Handler.name | - | 0 | 11 | OK |
| Handler.keyType | - | 0 | 4 | OK |
| Handler.isHandlable | - | 0 | 2 | OK |
| Handler.priority | - | 0 | 1 | OK |
| Handler.process | - | 0 | 93 | OK |
| Dispatch.getHandler | 5800 | 27 | 14 | OK |
| Dispatch.process | 5790 | 28 | 93 | OK |
| Dispatch.retractFrom | 5036 | 11 | 31 | OK |
| Dispatch.addHandler | 4903 | 61 | 48 | OK |
| Dispatch.listHandlers | 5 | 3 | 5 | OK |
| Dispatch.drive | 350 | 29 | 185 | OK |
| Dispatch.HANDLER_PRIORITY_HIGH | - | 0 | 7 | OK |
| Dispatch.HANDLER_PRIORITY_NORMAL | - | 0 | 31 | OK |
| Dispatch.HANDLER_PRIORITY_LOW | - | 0 | 9 | OK |
| Dispatch.HANDLER_PRIORITY_FALLBACK | - | 0 | 1 | OK |
| Bookkeeping.setLength | 530 | 25 | 36 | OK |
| Bookkeeping.setOffsetSource | 530 | 25 | 32 | OK |
| Bookkeeping.setEmpty | 165 | 23 | 1 | OK |
| Bookkeeping.getOffsetAt | 618 | 18 | 45 | OK |
| Bookkeeping.getBlocker | 1137 | 27 | 8 | OK |
| Bookkeeping.getBookkeeping | 2963 | 26 | 17 | OK |
| Bookkeeping.claimOwnerAt | 135 | 9 | 7 | OK |
| Bookkeeping.releaseOwner | 85 | 4 | 4 | OK |

### 표 3 — 에러 ID 248

MSG = spec이 그 id를 실은 메시지에 string.find/match 성공(메시지 단언), FAIL = spec pcall이 false로 받았으나 메시지 대조 없음(실패만 단언), TRIG = 던져졌으나 spec pcall에 그 id로 닿지 않음, NONE = 어느 spec도 안 던짐.

집계: {'FAIL': 34, 'MSG': 189, 'NONE': 25} 

| id | 분류 | 문서 | raise 자리 | spec |
|---|---|---|---|---|
| Quad0001 | FAIL | 05-tag-attr.md:10 | quad-base/src/Attr/Key.luau:58 | spec.attribute |
| Quad0003 | NONE | 05-tag-attr.md:26 | quad-base/src/Attr/init.luau:99 |  |
| Quad0004 | NONE | 05-tag-attr.md:34 | quad-base/src/Attr/init.luau:102 |  |
| Quad0006 | FAIL | 05-tag-attr.md:50 | quad-base/src/Attr/init.luau:128 | spec.attribute |
| Quad0009 | NONE | 05-tag-attr.md:74 | quad-base/src/Attr/init.luau:141 |  |
| Quad0011 | FAIL | 05-tag-attr.md:90 | quad-base/src/Attr/init.luau:167 | spec.attribute |
| Quad0012 | NONE | 05-tag-attr.md:98 | quad-base/src/Attr/init.luau:179 |  |
| Quad0014 | FAIL | 05-tag-attr.md:114 | quad-base/src/Attr/init.luau:198 | spec.attribute |
| Quad0015 | FAIL | 05-tag-attr.md:122 | quad-base/src/Attr/init.luau:201 | spec.attribute |
| Quad0024 | NONE | 02-dispatch-bookkeeping.md:50 | quad-base/src/Bookkeeping.luau:288 |  |
| Quad0034 | FAIL | 06-module-backend.md:74 | quad-base/src/Claim.luau:191 | spec.claim |
| Quad0045 | NONE | 01-core-reactive.md:106 | quad-base/src/Debounce.luau:323 |  |
| Quad0051 | FAIL | 02-dispatch-bookkeeping.md:90 | quad-base/src/Dispatch/Modifier/init.luau:201 | spec.modifier |
| Quad0052 | FAIL | 02-dispatch-bookkeeping.md:98 | quad-base/src/Dispatch/Modifier/init.luau:204 | spec.modifier |
| Quad0053 | FAIL | 02-dispatch-bookkeeping.md:106 | quad-base/src/Dispatch/Modifier/init.luau:216 | spec.modifier |
| Quad0054 | FAIL | 02-dispatch-bookkeeping.md:114 | quad-base/src/Dispatch/Modifier/init.luau:222 | spec.modifier |
| Quad0055 | FAIL | 02-dispatch-bookkeeping.md:122 | quad-base/src/Dispatch/Modifier/init.luau:248 | spec.modifier |
| Quad0056 | FAIL | 02-dispatch-bookkeeping.md:130 | quad-base/src/Dispatch/Modifier/init.luau:252 | spec.component, spec.modifier |
| Quad0057 | FAIL | 02-dispatch-bookkeeping.md:138 | quad-base/src/Dispatch/Modifier/init.luau:293 | spec.modifier, spec.preref |
| Quad0063 | FAIL | 02-dispatch-bookkeeping.md:186 | quad-base/src/Dispatch/Modifier/init.luau:388 | spec.modifier |
| Quad0064 | FAIL | 02-dispatch-bookkeeping.md:194 | quad-base/src/Dispatch/Modifier/init.luau:391 | spec.modifier |
| Quad0066 | FAIL | 02-dispatch-bookkeeping.md:210 | quad-base/src/Dispatch/Modifier/init.luau:404 | spec.modifier |
| Quad0067 | FAIL | 02-dispatch-bookkeeping.md:218 | quad-base/src/Dispatch/Modifier/init.luau:438 | spec.modifier |
| Quad0071 | NONE | 02-dispatch-bookkeeping.md:250 | quad-base/src/Dispatch/init.luau:238 |  |
| Quad0088 | FAIL | 04-ref-observer-effect.md:26 | quad-base/src/Effect.luau:234 | spec.effect |
| Quad0089 | NONE | 04-ref-observer-effect.md:34 | quad-base/src/Effect.luau:237 |  |
| Quad0090 | FAIL | 04-ref-observer-effect.md:50 | quad-base/src/Effect.luau:252 | spec.effect |
| Quad0091 | FAIL | 04-ref-observer-effect.md:58 | quad-base/src/Effect.luau:255 | spec.effect |
| Quad0092 | FAIL | 04-ref-observer-effect.md:74 | quad-base/src/Effect.luau:276 | spec.effect |
| Quad0093 | FAIL | 04-ref-observer-effect.md:82 | quad-base/src/Effect.luau:285 | spec.effect |
| Quad0094 | FAIL | 04-ref-observer-effect.md:90 | quad-base/src/Effect.luau:297 | spec.effect |
| Quad0098 | NONE | 04-ref-observer-effect.md:122 | quad-base/src/Effect.luau:439 |  |
| Quad0117 | NONE | 04-ref-observer-effect.md:202 | quad-base/src/Observer.luau:288 |  |
| Quad0134 | NONE | 04-ref-observer-effect.md:234 | quad-base/src/Ref/init.luau:164 |  |
| Quad0140 | NONE | 03-slot.md:10 | quad-base/src/Slot/Handler.luau:37 |  |
| Quad0142 | NONE | 03-slot.md:26 | quad-base/src/Slot/List.luau:95 |  |
| Quad0145 | NONE | 03-slot.md:50 | quad-base/src/Slot/List.luau:117 |  |
| Quad0147 | FAIL | 03-slot.md:66 | quad-base/src/Slot/List.luau:172 | spec.slot |
| Quad0156 | NONE | 03-slot.md:138 | quad-base/src/Slot/Owner.luau:28 |  |
| Quad0163 | NONE | 03-slot.md:194 | quad-base/src/Slot/Owner.luau:72 |  |
| Quad0164 | NONE | 03-slot.md:202 | quad-base/src/Slot/Tree.luau:34 |  |
| Quad0165 | FAIL | 03-slot.md:211 | quad-base/src/Slot/init.luau:131 | spec.slot |
| Quad0166 | FAIL | 03-slot.md:219 | quad-base/src/Slot/init.luau:137 | spec.slot |
| Quad0168 | FAIL | 03-slot.md:235 | quad-base/src/Slot/init.luau:170 | spec.slot |
| Quad0174 | FAIL | 03-slot.md:291 | quad-base/src/Slot/init.luau:329 | spec.slot |
| Quad0180 | NONE | 03-slot.md:339 | quad-base/src/Slot/init.luau:491 |  |
| Quad0188 | FAIL | 01-core-reactive.md:290 | quad-base/src/State.luau:326 | spec.gate |
| Quad0189 | FAIL | 01-core-reactive.md:298 | quad-base/src/State.luau:339 | spec.gate |
| Quad0190 | NONE | 01-core-reactive.md:306 | quad-base/src/State.luau:350 |  |
| Quad0192 | NONE | 01-core-reactive.md:322 | quad-base/src/State.luau:378 |  |
| Quad0207 | FAIL | 05-tag-attr.md:202 | quad-base/src/Tag.luau:226 | spec.tag |
| Quad0222 | FAIL | 07-roblox.md:66 | quad-roblox/src/Handlers/OnChange.luau:70 | spec.events |
| Quad0223 | FAIL | 07-roblox.md:74 | quad-roblox/src/Handlers/OnChange.luau:91 | spec.events |
| Quad0229 | NONE | 02-dispatch-bookkeeping.md:66 | quad-base/src/Bookkeeping.luau:202 |  |
| Quad0230 | NONE | 04-ref-observer-effect.md:42 | quad-base/src/Effect.luau:237 |  |
| Quad0231 | NONE | 04-ref-observer-effect.md:66 | quad-base/src/Effect.luau:255 |  |
| Quad0234 | NONE | 04-ref-observer-effect.md:266 | quad-base/src/Observer.luau:129 |  |
| Quad0235 | NONE | 04-ref-observer-effect.md:274 | quad-base/src/Observer.luau:162 |  |
| Quad0242 | FAIL | 03-slot.md:379 | quad-base/src/Slot/Elements.luau:68 | spec.slot |

(MSG 189건은 out/errors.json)
