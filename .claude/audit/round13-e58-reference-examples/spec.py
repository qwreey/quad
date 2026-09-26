# E58 block classification. key = block file stem (blocks/<key>.luau)
# cls: P=프롤로그, b=시그니처/타입(실행 안 함), a=실행, c=조각(보강), d=Roblox 전용(셔임)
# pre: 블록 앞에 덧대는 정의(strict에도 들어감). post: 블록 뒤 mock 전용 확인. skip_strict: 조각이라 strict 제외 사유
S = {}
def a(k, **kw): S[k] = dict(cls="a", **kw)
def c(k, **kw): S[k] = dict(cls="c", **kw)
def d(k, **kw): S[k] = dict(cls="d", **kw)

# core/01
a("core_01-quad-module-L40")
a("core_01-quad-module-L64")
a("core_01-quad-module-L104")
a("core_01-quad-module-L153")
a("core_01-quad-module-L188", post="q.debug = false")
c("core_01-quad-module-L233", post='local ok = pcall(assertOwn, setmetatable({}, Impl)); print("own:", ok)\nlocal ok2 = pcall(assertOwn, { _moduleIdentity = {} }); print("foreign:", ok2)', note="보강: assertOwn 호출 둘")
a("core_01-quad-module-L267")
# core/02
a("core_02-source-L51"); a("core_02-source-L85")
a("core_02-source-L110", pre='local __n = 0', post='print("len", #items:Get())', note="보강: 길이 출력")
a("core_02-source-L151", post='print(label:Get())')
# core/03
a("core_03-state-L87"); a("core_03-state-L125")
a("core_03-state-L162", post='raw:Set(1); print(gated:Get())')
a("core_03-state-L216")
# core/04
a("core_04-store-L60", post='print(store.hp:Get())')
a("core_04-store-L81"); a("core_04-store-L115"); a("core_04-store-L143")
# core/05
a("core_05-observer-effect-L39", post='hp:Set(90)\nprint("Text", label.Text)')
a("core_05-observer-effect-L116")
a("core_05-observer-effect-L237")
# core/06
a("core_06-slot-L82", post='print(#panel:GetChildren())')
a("core_06-slot-L110", post='print(empty:Get(), #view:GetChildren())\nslot:Add(D.Frame {})\nprint(empty:Get())')
a("core_06-slot-L171", post='for _, ch in root:GetChildren() do print(ch.Text) end')
a("core_06-slot-L219", post='print(slot.Length:Get(), other.Length:Get(), taken.Parent)')
a("core_06-slot-L262", post='print(#removed, slot.Length:Get(), removed[1].Parent)')
a("core_06-slot-L413", sub=[('rows:Set(', 'local aInst = view:GetChildren()[1]\nrows:Set(')], post='for _, ch in view:GetChildren() do print(ch.Text, ch == aInst) end\nprint("len", slot.Length:Get(), H.mock.isDestroyed(aInst))', note="보강: a 인스턴스 신원 비교(Roblox 백엔드는 물리 순서를 안 바꿈 — GetChildren 순서는 판정 안 함)")
a("core_06-slot-L485", post='print(#host:GetChildren())')
c("core_06-slot-L514", post='local host = D.Frame { slot }\nlocal first = host:GetChildren()[1]\nprint("shown", #host:GetChildren())\nvisible:Set(false); rows:Emit()\nprint("hidden", #host:GetChildren(), H.mock.isDestroyed(first))\nvisible:Set(true); rows:Emit()\nprint("back", #host:GetChildren(), host:GetChildren()[1] == first)', note="보강: host 마운트 + 숨김/복귀 확인(rows:Emit으로 재조정)")
c("core_06-slot-L552", skip="조각(`ctx` 미정의 — updateFn 안 줄) · L413이 같은 모양을 덮음")
a("core_06-slot-L595", post='print(H.mock.isDestroyed(taken))')
# core/07
a("core_07-ref-L97", post='print(boxRef.Value == panel)')
a("core_07-ref-L123", post='local box = form:GetChildren()[1]; box.Text = "x"\nform:GetChildren()[2].Activated:Fire()\nprint("[" .. box.Text .. "]")', note="보강: Activated 발화")
a("core_07-ref-L154", pre='', post='print(doneRef.Value == card, #card:GetChildren())')
a("core_07-ref-L252")
d("core_07-ref-L331", note="task.spawn 셔임(코루틴)")
a("core_07-ref-L366", post='button.Activated:Fire(); print(button.BackgroundTransparency)', note="보강: Activated 발화")
# core/08
a("core_08-modifier-L56", post='print(box.BackgroundTransparency, box.Name)')
d("core_08-modifier-L103", post='print(panel.BackgroundTransparency, panel.BorderSizePixel, panel.Size.X.Scale, panel.Size.Y.Scale)')
a("core_08-modifier-L153", post='print(base:Peek("BackgroundTransparency"), dimmed:Peek("BackgroundTransparency"), live:Peek("LayoutOrder") == scale, cleared:Peek("BackgroundTransparency") == q.None, bumped:Peek("LayoutOrder"), doubled:Peek("LayoutOrder"):Get())')
d("core_08-modifier-L200", post='print(storedSize == size, visible, missing)')
a("core_08-modifier-L231", post='print(styled:Peek("BorderSizePixel"), styled:Peek("BackgroundTransparency"))')
a("core_08-modifier-L303", post='print(button:Peek("Visible"))')
a("core_08-modifier-L335", post='print(merged:Peek("BackgroundTransparency"), same:Peek("BackgroundTransparency"))')
a("core_08-modifier-L373", post='print(raised:Peek("Elevation"))')
a("core_08-modifier-L418")
# core/09
a("core_09-tag-attr-L88", post='local t = H.CollectionService:GetTags(button); table.sort(t); print(table.concat(t, ","))')
c("core_09-tag-attr-L113", pre='local isSelected = true', post='print(selected:Contains("card","selected"), both:Contains("hovered"), maybe:Contains("selected"))', note="보강: isSelected 정의")
a("core_09-tag-attr-L154")
a("core_09-tag-attr-L176")
a("core_09-tag-attr-L213", post='print(merged:Contains("x","y"), same:Contains("x","y"))')
a("core_09-tag-attr-L286", post='print(stats:GetAttribute("Hp"), stats:GetAttribute("Name"))')
a("core_09-tag-attr-L312")
a("core_09-tag-attr-L350", post='print(final:NameMap().Accent, final:NameMap().Size)\nprint(pcall(q.Attr.Merged, theme, override))')
d("core_09-tag-attr-L392", post='print(marker:GetAttribute("SpawnColor").R)')
a("core_09-tag-attr-L428", post='print(card:GetAttribute("Label"), card:GetAttribute("Kind"), blank:GetAttribute("Label"))')
a("core_09-tag-attr-L464", post='print(alive:GetAttribute("Hp"), alive:GetAttribute("Friendly"))')
# core/10
c("core_10-lifetime-sentinels-L39", post='local c1 = Card({ Title = "t" }); print(#c1:GetChildren(), c1:GetChildren()[1].Text)\nlocal c2 = Card({ Title = "t", Modifier = q.Modifier { BackgroundTransparency = 0.3 } }); print(c2.BackgroundTransparency)', note="보강: Card 호출 둘")
a("core_10-lifetime-sentinels-L124", post='print(H.mock.isDestroyed(child), slot.Length:Get())')
# extend
a("extend_01-backend-provider-contract-L192", post='print(q.Widget ~= nil)')
a("extend_02-dispatch-handler-contract-L353", post='local f = D.Frame { Foo = LogValue("hi") }\nf:Destroy()', note="보강: 핸들러를 실제로 태워 봄")
# roblox/01
a("roblox_01-install-L95", post='print(D ~= nil, Quad.Declaration == D)')
a("roblox_01-install-L153", post='print(q.isTween(fade))')
c("roblox_01-install-L161", skip="조각(함수 머리 한 줄 — 본문 없음, 구문 불완전)")
# roblox/02
d("roblox_02-d-L59", post='print(button.Text, button.TextSize, #button:GetChildren())\nbutton.MouseEnter:Fire(); print(hovered:Get())\nlabel:Set("OK")', note="script 셔임")
d("roblox_02-d-L130")
c("roblox_02-d-L261", pre='local props: { Modifier: any?, Child: Instance? } = {}', post='', note="보강: props 정의")
a("roblox_02-d-L287", note="둘째 줄은 문서가 '타입 에러'라 말함")
a("roblox_02-d-L310", post='')
d("roblox_02-d-L339", post='print(part.ClassName, part.Name, part.Anchored)')
# roblox/03
a("roblox_03-d-modifier-L48", post='print(card.BackgroundTransparency, card.Visible, card.ZIndex)')
a("roblox_03-d-modifier-L130", post='print(bumped:Peek("ZIndex"), D.Frame { bumped }.ZIndex)')
d("roblox_03-d-modifier-L187", post='print(label:Peek("Text"), frame:Peek("Style"))')
a("roblox_03-d-modifier-L222", post='print(forced.__quadModifier, retagged.__quadModifier)')
a("roblox_03-d-modifier-L248")
a("roblox_03-d-modifier-L284", post='print(bold:Peek("TextSize"), bold:Peek("Text"))')
# roblox/04
TPL = '''local function tpl(class, name, kids) local i = H.mock.Instance.foreign(class); if name then i.Name = name end; for _, k in kids or {} do k.Parent = i end; return i end
'''
d("roblox_04-claim-mapper-L50", post=TPL+'local t = tpl("Frame", "Card", { tpl("TextLabel", "Title"), tpl("Frame", "List", { tpl("TextLabel", "Inner") }) })\nlocal r = bindCard(t)\nprint(r == t, t.BackgroundTransparency, t:FindFirstChild("Title").Text, t:FindFirstChild("List"):FindFirstChild("Inner").Text)', note="보강: foreign 템플릿")
d("roblox_04-claim-mapper-L81", post=TPL+'local t = tpl("Frame", "Card", { tpl("TextLabel", "Title") })\nbindMixed(t)\nprint(#t:GetChildren(), t.BackgroundTransparency, t:FindFirstChild("Title").Text)', note="보강: foreign 템플릿")
d("roblox_04-claim-mapper-L132", post=TPL+'local g = tpl("ScreenGui"); local pg = tpl("Frame", "PlayerGui")\nmount(g, pg)\nprint(g.Parent == pg)', note="보강: foreign 템플릿")
d("roblox_04-claim-mapper-L168", post=TPL+'local cs = { tpl("Frame", "A", { tpl("TextLabel", "Title") }), tpl("Frame", "B", { tpl("TextLabel", "Title") }) }\nbindAll(cs)\nprint(cs[1]:FindFirstChild("Title").Text, cs[2]:FindFirstChild("Title").Text)', note="보강: foreign 템플릿")
c("roblox_04-claim-mapper-L189", skip="조각(`{ … }` 자리표시 — 구문 아님)")
a("roblox_04-claim-mapper-L202", post='print("assert ok")')
d("roblox_04-claim-mapper-L221", post=TPL+'local m = tpl("Model", "M", { tpl("Part", "Body") })\nbindModel(m)\nprint(m:FindFirstChild("Body").Anchored)', note="보강: foreign 템플릿")
# roblox/05
d("roblox_05-onchange-L56", post='box.AbsoluteSize = Vector2.new(3, 4)\nbox.Visible = false', note="AbsoluteSize는 mock에서 엔진 쪽 대입으로 흉내")
a("roblox_05-onchange-L79", post='print(#seen, seen[1])')
a("roblox_05-onchange-L95", post='print(#box:GetChildren())')
a("roblox_05-onchange-L109", post='print("ok")')
a("roblox_05-onchange-L146", post='box.Text = "typed"; print(text:Get())\ntext:Set("set"); print(box.Text)', note="보강: 엔진 쪽 대입으로 타이핑 흉내")
# roblox/06
d("roblox_06-tween-animate-L61", post='print(#H.mock.tweenLog)\nopen:Set(true); print(#H.mock.tweenLog)')
a("roblox_06-tween-animate-L127", post='print(q.isTween(a), q.isTween(b))')
a("roblox_06-tween-animate-L182", post='print(box.BackgroundTransparency)\nalpha:Set(1); print(#H.mock.tweenLog)')
a("roblox_06-tween-animate-L226", post='print(box.BackgroundTransparency, #H.mock.tweenLog)')
# sugar/01
a("sugar_01-context-L66", post='print(ThemeProvider.Name, UserProvider.Name)')
d("sugar_01-context-L167", post='print(#shell:GetChildren(), maybeUser and maybeUser.Name)')
# sugar/02
a("sugar_02-operator-L35", pre='', post='print(a:Get(), b:Get())', note="보강: 값 출력(주석의 15/105→18/108)")
a("sugar_02-operator-L99", post='print(isHidden:Get())')
a("sugar_02-operator-L114", post='print(total:Get())')
a("sugar_02-operator-L160", post='print(boundX:Get())')
a("sugar_02-operator-L177", post='print(masked:Get())')
a("sugar_02-operator-L222", post='print(shifted:Get())')
a("sugar_02-operator-L251", post='print(safeName:Get())')
a("sugar_02-operator-L270", post='print(primary:Get(), size:Get(), missing:Get())')
# sugar/03
d("sugar_03-debounce-throttle-L190", note="가상 시계(H.runTask) — 문서 그대로는 시간 안 흐름")
a("sugar_03-debounce-throttle-L214", post='scrollRaw:Set(5); print(scrollPos:Get())')
# sugar/04
c("sugar_04-lifecycle-hooks-L98", post='local box = AnimatedBox()\nbox:Destroy()', note="보강: 호출·Destroy")
# sugar/05
d("sugar_05-fallback-traceback-L79", pre='', post='print(card.ClassName, card.Text)', note="warn 셔임")
# sugar/06
a("sugar_06-blocker-L47", pre='local __log = {}', post='', note="보강: 관측자는 아래 별도 파일")
a("sugar_06-blocker-L111")
a("sugar_06-blocker-L150", post='hp:Set(1); print(gated:Get())')
c("sugar_06-blocker-L166", pre='local state = q.Source(0)\nlocal blocker = q.Blocker()', note="보강: state·blocker 정의")
c("sugar_06-blocker-L176", pre='local hp = q.Source(0)\nlocal blocker = q.Blocker()', note="보강: hp·blocker 정의")
# mock 전용 치환(보강): (old, new)
S["sugar_06-blocker-L47"]["sub"] = [("blocker:On()", 'local nHp, nMp = 0, 0\nshownHp:Observer(function() nHp += 1 end):Subscribe()\nshownMp:Observer(function() nMp += 1 end):Subscribe()\nblocker:On()'),
                                   ("blocker:Off() --", 'print("before Off", nHp, nMp)\nblocker:Off() --')]
S["sugar_06-blocker-L47"]["post"] = 'print("after Off", nHp, nMp)'
S["sugar_06-blocker-L47"]["note"] = "보강: 관측자 둘로 통지 수 확인"
S["sugar_03-debounce-throttle-L190"]["sub"] = [("-- 0.3초 뒤", 'print("t=0 get", debounced:Get())\nH.runTask(0.31)\n-- 0.3초 뒤'),
    ("handle:Unwrap():Flush()", 'searchInput:Set("abc")\nhandle:Unwrap():Flush()')]
S["sugar_03-debounce-throttle-L190"]["note"] = "d: 가상 시계 H.runTask(0.31) 삽입 + Flush 앞 Set(\"abc\") 보강(보류분 있는 Flush 확인)"
S["core_05-observer-effect-L237"]["post"] = 'print("done")'
