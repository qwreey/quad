# E70 block classification (E58 spec.py 형식 + with/module/ssub 확장).
# cls: P=프롤로그, b=시그니처/타입/내부 발췌(실행 안 함 — 소스 대조만), a=실행, c=조각(보강), d=Roblox 전용(셔임)
# pre: 블록 앞 정의(strict에도 들어감). spre: strict 전용 pre(pre 대신). post: mock 전용 확인.
# sub: mock 전용 치환. ssub: mock·strict 둘 다 치환. with: 같은 페이지 앞 블록을 먼저 붙임(키 또는 (키, 모듈명)).
# module: 이 블록이 모듈 파일(최상위 return) — mock은 함수로 감싸 __mod_<이름>, strict는 strict/<이름>.luau로도 씀.
# skip: strict 제외 사유. mockpro="base": how-to 06용(Roblox 프로바이더 없는 quad_base).
S = {}
def a(k, **kw): S[k] = dict(cls="a", **kw)
def c(k, **kw): S[k] = dict(cls="c", **kw)
def d(k, **kw): S[k] = dict(cls="d", **kw)
def P(k, **kw): S[k] = dict(cls="P", **kw)
def b(k, **kw): S[k] = dict(cls="b", **kw)

# 페이지 프롤로그(strict에 붙임). 없는 페이지는 DEFAULT_PROLOG(GS 01 설정 모듈 관용구).
PROLOG = {
 "how-to/01-component-conventions.md": "how-to_01-component-conventions-L14",
 "how-to/02-form-validation-pattern.md": "how-to_02-form-validation-pattern-L27",
 "how-to/03-long-lists-and-windowing.md": "how-to_03-long-lists-and-windowing-L24",
 "how-to/04-network-and-input-bridge.md": "how-to_04-network-and-input-bridge-L22",
 "how-to/05-theme-and-dynamic-styling.md": "how-to_05-theme-and-dynamic-styling-L11",
 "how-to/06-headless-testing.md": None,  # 06은 L77이 require를 품은 실행 블록 — with로 잇는다
 "how-to/07-studio-ui-binding-and-claim.md": "how-to_07-studio-ui-binding-and-claim-L11",
 "how-to/08-migrating-from-v1.md": "how-to_08-migrating-from-v1-L40",
 "how-to/09-overlays-modal-toast.md": "how-to_09-overlays-modal-toast-L10",
 "how-to/10-debugging-and-troubleshooting.md": "how-to_10-debugging-and-troubleshooting-L10",
 "quadnomicon/05-non-destructive-portal-and-ownership.md": "quadnomicon_05-non-destructive-portal-and-ownership-L34",
 "quadnomicon/09-fragment-breakthrough-and-domless-slot.md": None,
 "quadnomicon/07-instance-identity-and-gc-philosophy.md": None,
 "site/src/content/docs/index.mdx": None,
}
DEFAULT_PROLOG = '-- [E70 기본 프롤로그 — GS 01 설정 모듈 관용구]\nlocal q = require("@game/ReplicatedStorage/Client/UI/Quad")\nlocal D = q.Declaration\n'

# 공통 mock 보강 조각
TPL = 'local function tpl(class, name, kids) local i = H.mock.Instance.foreign(class); if name then i.Name = name end; for _, k in kids or {} do k.Parent = i end; return i end\n'
CLONE = ('local function __clone(src) local c = H.mock.Instance.foreign(src.ClassName); c.Name = src.Name\n'
         '  for _, p in { "Size", "BackgroundColor3", "BorderSizePixel", "Text", "TextSize", "CornerRadius" } do local ok, v = pcall(function() return src[p] end); if ok and v ~= nil then pcall(function() c[p] = v end) end end\n'
         '  for _, ch in src:GetChildren() do __clone(ch).Parent = c end; return c end\n')
def RS(tree):  # ReplicatedStorage 셔임: WaitForChild 체인이 tree를 따라간다
    return ('local function __wfc(node) return { WaitForChild = function(_, n) local v = node[n]; if type(v) == "table" and v.__inst then return v.__inst end; return __wfc(v) end } end\n'
            f'local ReplicatedStorage = __wfc({tree})\n')

# ---------------- how-to 01 ----------------
P("how-to_01-component-conventions-L14")
a("how-to_01-component-conventions-L34", sub=[("D.Frame {", "local __f = D.Frame {")],
  post='print("kids", #__f:GetChildren(), "border", __f.BorderSizePixel, "R", __f.BackgroundColor3.R)\n__f.MouseEnter:Fire(); print("hoverR", __f.BackgroundColor3.R)\n__f.MouseLeave:Fire(); print("leaveR", __f.BackgroundColor3.R)')
a("how-to_01-component-conventions-L74", post='local b1 = MaterialButton { Text = "x" }; print(b1.Text)\nlocal r = q.PreRef<<TextButton?>>(nil); local b2 = MaterialButton { Ref = r, Modifier = D.Modifier.TextButton { TextSize = 20 } }; print(r.Value == b2, b2.TextSize, "[" .. b2.Text .. "]")')
c("how-to_01-component-conventions-L93", pre='local props: { Modifier: RobloxModule.TextButtonModifier?, Ref: q.Ref<TextButton?>? } = {}',
  sub=[('D.TextButton { props.Modifier, props.Ref, Text = "x" }', 'print("both-nil ❌ line:", pcall(function() return D.TextButton { props.Modifier, props.Ref, Text = "x" } end))\nlocal __r = q.PreRef<<TextButton?>>(nil)\nprint("mod-nil+ref ❌ shape:", (select(2, pcall(function() return D.TextButton { props.Modifier, __r, Text = "x" } end))))')],
  post='print("✅ ok")', note="보강: props 정의 + ❌ 줄을 pcall로(둘 다 nil / 앞만 nil)")
a("how-to_01-component-conventions-L126", post='local b = CustomButton { Text = "t", OnClick = function() print("clicked") end }\nprint(b.TextSize, b.Text, #b:GetChildren(), b:GetChildren()[1].ClassName)\nb.MouseButton1Click:Fire()')
a("how-to_01-component-conventions-L161", **{"with": ["how-to_01-component-conventions-L126"]},
  post='print(btn1.Size.X.Offset, btn2.Size.X.Offset, btn2.BackgroundColor3.R, btn2.TextSize)\nbtn2.MouseButton1Click:Fire()')
a("how-to_01-component-conventions-L186", post='local s = q.Slot<<Instance>>()\nlocal m = ModalDialog { Title = "T", Children = s }\ns:Add(D.Frame {}); s:Add(D.Frame {})\nlocal n = 0; for _, ch in m:GetChildren() do if ch.ClassName == "Frame" then n = #ch:GetChildren() end end\nprint("content kids", n)\nlocal m2 = ModalDialog { Title = "T" }; print("no children ok", #m2:GetChildren())')
a("how-to_01-component-conventions-L228", post='print("kids", #list:GetChildren())')
a("how-to_01-component-conventions-L250", post='local lv = q.Source(3)\nlocal bdg = CharacterBadge { Name = "n", Level = lv }\nlocal t = H.CollectionService:GetTags(bdg); table.sort(t); print(table.concat(t, ","), bdg:GetAttribute("Level"), bdg:GetAttribute("Guild"), bdg:GetAttribute("CharacterName"))\nlv:Set(4); print(bdg:GetAttribute("Level"))')
a("how-to_01-component-conventions-L290", post='left.increment(); print(left.count:Get(), left.isEven:Get(), right.count:Get(), right.isEven:Get())')

# ---------------- how-to 02 ----------------
P("how-to_02-form-validation-pattern-L27")
a("how-to_02-form-validation-pattern-L39", post='local v = q.Source(false); local cb = Checkbox { Value = v, Label = "L" }\nprint(cb.Text); cb.Activated:Fire(); print(v:Get(), cb.Text)')
a("how-to_02-form-validation-pattern-L65", **{"with": ["how-to_02-form-validation-pattern-L39"]},
  post='local btn; for _, ch in panel:GetChildren() do if ch.ClassName == "TextButton" and ch.Text == "가입하기" then btn = ch end end\nprint("kids", #panel:GetChildren(), btn.Interactable, btn.BackgroundColor3.R)\nagreed:Set(true); print(btn.Interactable, btn.BackgroundColor3.B)')
a("how-to_02-form-validation-pattern-L112", post='local f = makeFormState(); print(f.CanSubmit:Get())\nf.Store.Username:Set("abcd"); f.Store.Password:Set("abcdefgh"); print(f.CanSubmit:Get())\nf.Store.Password:Set("abcdefg1"); print(f.CanSubmit:Get())')
c("how-to_02-form-validation-pattern-L179", pre='local __u, __p = q.Source(""), q.Source("")\nlocal isUsernameValid: q.State<boolean> = __u:Compute(function(s: q.StateData<string>): boolean return #s:Get() >= 4 end)\nlocal isPasswordValid: q.State<boolean> = __p:Compute(function(s: q.StateData<string>): boolean return #s:Get() >= 8 end)',
  post='local n = 0; canSubmit:Observer(function() n += 1 end)\n__u:Set("abcd"); print(canSubmit:Get()); __p:Set("12345678"); print(canSubmit:Get(), "recompute-on-dep-change")', note="보강: makeFormState 안 두 판정 대역")
a("how-to_02-form-validation-pattern-L196", **{"with": ["how-to_02-form-validation-pattern-L112"]},
  post=('local f = makeFormState(); local fr = RegistrationForm { Form = f }\n'
        'local boxes, lbl, btn = {}, nil, nil\nfor _, ch in fr:GetChildren() do if ch.ClassName == "TextBox" then table.insert(boxes, ch) elseif ch.ClassName == "TextLabel" then lbl = ch elseif ch.ClassName == "TextButton" then btn = ch end end\n'
        'print("boxes", #boxes, "errVisible", lbl.Visible, "btn", btn.Interactable)\n'
        'boxes[1].Text = "abcd"; print(f.Store.Username:Get(), lbl.Visible)\n'
        'boxes[2].Text = "abcdefg1"; print(f.Store.Password:Get(), btn.Interactable)\n'
        'btn.MouseButton1Click:Fire(); print(f.Submitted:Get() and f.Submitted:Get().Username)'), note="보강: 엔진 쪽 대입으로 타이핑 흉내(TextBox.Text 순서는 GetChildren 순서에 의존하지 않게 클래스로 모음)")
a("how-to_02-form-validation-pattern-L283", **{"with": ["how-to_02-form-validation-pattern-L112", "how-to_02-form-validation-pattern-L196"]},
  post='form.Store.Username:Set("abcd"); form.Store.Password:Set("abcdefg1")\nform.Submitted:Set({ Username = "abcd", Password = "abcdefg1" })')
c("how-to_02-form-validation-pattern-L324", **{"with": ["how-to_02-form-validation-pattern-L112"]},
  post='local f = makeFormState(); submit({ Form = f, OnSubmit = function(s) print("sub", s.Username) end }); print("blocked-while-invalid")\nf.Store.Username:Set("abcd"); f.Store.Password:Set("abcdefg1"); submit({ Form = f, OnSubmit = function(s) print("sub", s.Username) end })', note="보강: makeFormState 이어 붙임")

# ---------------- how-to 03 ----------------
P("how-to_03-long-lists-and-windowing-L24")
a("how-to_03-long-lists-and-windowing-L59", post=('local data = q.Source({ "a", "b" })\nlocal s = q.Slot<<Instance>>():List(data, updateFn)\nlocal host = D.Frame { D.Frame {}, s }\n'
   'local function lo() local t = {} for _, ch in host:GetChildren() do table.insert(t, ch.LayoutOrder) end table.sort(t) return table.concat(t, ",") end\nprint("orders", lo())\ndata:Set({ "a", "b", "c" }); print("orders", lo())'))
a("how-to_03-long-lists-and-windowing-L110", post=('local items = {} for i = 1, 100 do items[i] = { id = "i" .. i, label = "row " .. i } end\nlocal sf = VirtualList { Items = items }\nprint("rows@0", #sf:GetChildren())\n'
   'sf.CanvasPosition = Vector2.new(0, 1000); print("rows@1000", #sf:GetChildren())\nlocal minY = math.huge; for _, ch in sf:GetChildren() do minY = math.min(minY, ch.Position.Y.Offset) end; print("minY", minY)\n'
   'sf.AbsoluteWindowSize = Vector2.new(0, 100); print("rows@h100", #sf:GetChildren())'), note="보강: 엔진 쪽 대입으로 스크롤·창 크기 흉내")
c("how-to_03-long-lists-and-windowing-L194", pre='local viewportHeight = q.Source(600)', post='scrollY:Set(1); scrollY:Set(2); print(gatedScrollY:Get())\nH.runTask(0.11); print(gatedScrollY:Get())', note="보강: viewportHeight 정의(§4 본문 생략 자리는 그대로)")

# ---------------- how-to 04 ----------------
P("how-to_04-network-and-input-bridge-L22")
GAME04 = ('local __RE = { OnClientEvent = H.mock.newSignal() }\nlocal __UIS = { InputBegan = H.mock.newSignal(), InputChanged = H.mock.newSignal() }\n'
          'local game = { GetService = function(_, n) if n == "ReplicatedStorage" then return { WaitForChild = function() return __RE end } elseif n == "UserInputService" then return __UIS end; return H.game:GetService(n) end }\n')
d("how-to_04-network-and-input-bridge-L37", module="PlayerProfileState", mpre=GAME04,
  post='__RE.OnClientEvent:Fire({ Gold = 1234 }); print(__mod_PlayerProfileState.Gold:Get(), __mod_PlayerProfileState.Level:Get())', note="RemoteEvent·game 셔임")
d("how-to_04-network-and-input-bridge-L63", mpre=GAME04, **{"with": [("how-to_04-network-and-input-bridge-L37", "PlayerProfileState")]},
  post='local l = GoldDisplay(); print(l.Text)\n__RE.OnClientEvent:Fire({ Gold = -1234.9 }); print(l.Text)\n__RE.OnClientEvent:Fire({ Gold = 1234567 }); print(l.Text)', note="RemoteEvent 셔임")
d("how-to_04-network-and-input-bridge-L111", mpre=GAME04,
  post='local m = InventoryModal(); print(m.Visible)\n__UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.Tab }, false); print(m.Visible)\n__UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.Tab }, true); print(m.Visible, "gameProcessed ignored")\nm:GetChildren()[1].MouseButton1Click:Fire(); print(m.Visible)', note="UserInputService 셔임")
d("how-to_04-network-and-input-bridge-L151", mpre=GAME04, **{"with": ["how-to_04-network-and-input-bridge-L111"]},
  post='local o = CrosshairOverlay(); print("conns", #__UIS.InputChanged.connections)\n__UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = { X = 10, Y = 20 } })\nprint(o:GetChildren()[1].Position.X.Offset, o:GetChildren()[1].Position.Y.Offset)\no:Destroy(); print("conns after destroy", #__UIS.InputChanged.connections)', note="UserInputService 셔임, UserInputService는 §3 블록에서")
c("how-to_04-network-and-input-bridge-L197", pre='local SomeSignal: RBXScriptSignal = (H and H.mock.newSignal() or nil) :: any', spre='local SomeSignal: RBXScriptSignal = nil :: any',
  post='local p = StatusPanel(); print("conns", #SomeSignal.connections); p:Destroy(); print("after destroy", #SomeSignal.connections)', note="보강: SomeSignal 정의")

# ---------------- how-to 05 ----------------
P("how-to_05-theme-and-dynamic-styling-L11")
T5 = ("how-to_05-theme-and-dynamic-styling-L62", "Theme")
c("how-to_05-theme-and-dynamic-styling-L36", **{"with": [T5]},
  post='print(theme == __mod_Theme, maybe == __mod_Theme)\nprint("empty Get:", pcall(function() return q.Context():Get(ThemeProvider) end))\nprint("empty Peek:", q.Context():Peek(ThemeProvider))', note="보강: Theme 모듈 이어 붙임")
a("how-to_05-theme-and-dynamic-styling-L62", module="Theme", post='print(__mod_Theme.Tokens.Accent:Get() ~= nil)')
a("how-to_05-theme-and-dynamic-styling-L166", module="Styles", **{"with": [T5]}, post='print(__mod_Styles.Button:Peek("BorderSizePixel"))')
a("how-to_05-theme-and-dynamic-styling-L180", module="ThemedButton", **{"with": [T5, ("how-to_05-theme-and-dynamic-styling-L166", "Styles")]},
  post='local tb = __mod_ThemedButton { Text = "a", OnClick = function() print("click") end }\nprint(tb.Size.X.Offset, tb.BorderSizePixel)\nlocal tb2 = __mod_ThemedButton { Text = "b", OnClick = function() end, Modifier = D.Modifier.TextButton { BorderSizePixel = 3 } }\nprint(tb2.Size.X.Offset, tb2.BorderSizePixel)\ntb.Activated:Fire()')
a("how-to_05-theme-and-dynamic-styling-L227", **{"with": [T5, ("how-to_05-theme-and-dynamic-styling-L166", "Styles"), ("how-to_05-theme-and-dynamic-styling-L180", "ThemedButton")]},
  post='local card = SettingsCard(); local btn; for _, ch in card:GetChildren() do if ch.ClassName == "TextButton" then btn = ch end end\nprint("kids", #card:GetChildren(), btn.Size.X.Offset, btn.Position.Y.Offset)\nlocal before = card.BackgroundColor3.R\nbtn.Activated:Fire(); H.runTask(0.3); print("dark->light", before, __mod_Theme.IsDark:Get())')

# ---------------- how-to 06 ----------------
a("how-to_06-headless-testing-L77", mockpro="base", post='print("L77 asserts ok")')
a("how-to_06-headless-testing-L96", mockpro="base", **{"with": ["how-to_06-headless-testing-L77"]},
  post='print("L96 asserts ok", gated:Get())')
c("how-to_06-headless-testing-L134", mockpro="base", **{"with": ["how-to_06-headless-testing-L77"]}, pre='local myProvider: any = (H and H.mock.mockProvider) or nil', post='print(q.Backend.bindLifetime ~= nil)\nprint("same provider again:", pcall(function() return q:UseProvider(myProvider) end))\nprint("other provider:", (select(2, pcall(function() return q:UseProvider(function() return {} end) end))))', note="보강: myProvider = mock.mockProvider")
c("how-to_06-headless-testing-L149", mockpro="base", **{"with": ["how-to_06-headless-testing-L77", "how-to_06-headless-testing-L134"]},
  pre='local myProvider: any = (H and H.mock.mockProvider) or nil', mpre2='local host = H.mock.Instance.new("Frame")', spre2='local host: any = nil',
  post='print("L149 asserts ok", runs)', note="보강: host = mock Instance.new")
c("how-to_06-headless-testing-L180", mockpro="base", **{"with": ["how-to_06-headless-testing-L77", "how-to_06-headless-testing-L134"]},
  pre='local myProvider: any = (H and H.mock.mockProvider) or nil', mpre2='local function makeElement() return H.mock.Instance.new("Frame") end\nlocal parent = H.mock.Instance.new("Frame")', spre2='local function makeElement(): any return nil end\nlocal parent: any = nil',
  post='print("L180 asserts ok")', note="보강: makeElement·parent = mock Instance.new")

# ---------------- how-to 07 ----------------
P("how-to_07-studio-ui-binding-and-claim-L11")
d("how-to_07-studio-ui-binding-and-claim-L26", mpre=TPL+'local __t = tpl("Frame", "ItemCard", { tpl("TextLabel", "ItemName"), tpl("ImageLabel", "ItemIcon"), tpl("TextButton", "ActionButton") })\nlocal script = { Parent = { WaitForChild = function() return __t end } }',
  post='local ab = __t:FindFirstChild("ActionButton"); print(ab.Text); ab.Activated:Fire(); ab.Activated:Fire(); print(ab.Text, __t:FindFirstChild("ItemName").Text, __t:FindFirstChild("ItemIcon").Image, __t.Visible)', note="보강: foreign 템플릿 + script 셔임")
d("how-to_07-studio-ui-binding-and-claim-L75", mpre=TPL+CLONE+RS('{ Templates = { ItemCard = { __inst = tpl("Frame", "ItemCard", { tpl("TextLabel", "ItemName"), tpl("ImageLabel", "ItemIcon"), tpl("TextButton", "ActionButton") }) } } }'),
  spre='local ReplicatedStorage = game:GetService("ReplicatedStorage")', sub=[("ItemTemplate:Clone()", "__clone(ItemTemplate)")],
  post='local host = D.Frame { rows }; print("rows", #host:GetChildren())\nitemsState:Set({ { id = "sword", label = "명검" } }); print("rows", #host:GetChildren(), host:GetChildren()[1]:FindFirstChild("ItemName").Text)\nhost:GetChildren()[1]:FindFirstChild("ActionButton").Activated:Fire()', note="보강: ReplicatedStorage 셔임(블록에 정의 없음) + mock에 :Clone 없어 __clone")
a("how-to_07-studio-ui-binding-and-claim-L121", post='print(ItemTemplate.Name, #ItemTemplate:GetChildren())')
a("how-to_07-studio-ui-binding-and-claim-L138", mpre=TPL+CLONE, **{"with": ["how-to_07-studio-ui-binding-and-claim-L121"]}, sub=[("ItemTemplate:Clone()", "__clone(ItemTemplate)")],
  post='local lb = q.Source("검"); local ok, card = pcall(ItemCard, { id = "s", label = "검" }, lb); print("claim ok", ok, ok and "" or card)\nif ok then print(card:FindFirstChild("ItemName").Text); lb:Set("방패"); print(card:FindFirstChild("ItemName").Text); card:FindFirstChild("ActionButton").Activated:Fire() end', note="보강: mock에 :Clone 없어 __clone(foreign 사본)")
c("how-to_07-studio-ui-binding-and-claim-L201", post='print("descriptor ok")')
d("how-to_07-studio-ui-binding-and-claim-L228", mpre=TPL+'local existingScreenGui = tpl("ScreenGui", "Shop")\nlocal rows = q.Slot<<Instance>>()\nlocal __pg = tpl("Frame", "PlayerGui")\nlocal player = { WaitForChild = function() return __pg end }',
  spre='local existingScreenGui: ScreenGui = nil :: any\nlocal rows = q.Slot<<Instance>>()\nlocal player = game:GetService("Players").LocalPlayer',
  post='rows:Add(D.Frame {}); print(screen.Parent == __pg, #screen:GetChildren())', note="보강: existingScreenGui·rows·player 정의")
d("how-to_07-studio-ui-binding-and-claim-L248", mpre=TPL+CLONE+RS('{ Templates = { ShopWindow = { __inst = tpl("Frame", "ShopWindow", { tpl("TextButton", "CloseButton"), tpl("TextLabel", "TitleText"), tpl("Frame", "ContentArea") }) } } }'),
  spre='local ReplicatedStorage = game:GetService("ReplicatedStorage")', sub=[(":Clone()", "")],
  post='local open = q.Source(true); local rows = q.Slot<<Instance>>(); local w = ShopWindow(open, rows)\nrows:Add(D.Frame {}); print(w.Visible, #w:FindFirstChild("ContentArea"):GetChildren())\nw:FindFirstChild("CloseButton").Activated:Fire(); print(w.Visible)', note="보강: ReplicatedStorage 셔임(블록에 정의 없음), :Clone 제거(foreign 원본을 그대로)")

# ---------------- how-to 08 ----------------
P("how-to_08-migrating-from-v1-L40")
a("how-to_08-migrating-from-v1-L82", post='print(label.Text, label.BackgroundColor3.R)\nprint("plain default:", (select(2, pcall(function() return q.Store { Color = 1 } end))))')
a("how-to_08-migrating-from-v1-L103", post='print(frame.Size.X.Offset, frame.Size.Y.Offset); topbar:Set(80); print(frame.Size.Y.Offset)')
a("how-to_08-migrating-from-v1-L130", post='print(total:Get(), shown:Get(), primary:Get().B, moved:Get().Y.Offset)\nnickname:Set("Kim"); price:Set(1); print(shown:Get(), total:Get())')
a("how-to_08-migrating-from-v1-L166", post='print(frame.BackgroundColor3.R)\nlocal n0 = #H.mock.tweenLog; hovered:Set(true); target:Set(UDim2.fromScale(1, 0)); print("tweens", #H.mock.tweenLog - n0)')
d("how-to_08-migrating-from-v1-L204", mpre=TPL+'local __pg = tpl("Frame", "PlayerGui")\nlocal game = { GetService = function(_, n) return { LocalPlayer = { WaitForChild = function() return __pg end } } end }',
  post='print(#gui:GetChildren()[1]:GetChildren(), gui.Parent == __pg)', note="Players 셔임")
a("how-to_08-migrating-from-v1-L238", pre='local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- [E70] 같은 페이지 L103 첫 줄',
  post='local function texts() local t = {} for _, ch in list:GetChildren() do t[ch.LayoutOrder] = ch.Text end return table.concat(t, ",") end\nprint(texts())\nrows:Set({ { Id = "b", Title = "둘" }, { Id = "a", Title = "첫" } }); print(texts())', note="보강: QuadTypes require(L103에 있음)")
a("how-to_08-migrating-from-v1-L293", post='button.Activated:Fire(nil, 1); print(pressed:Get(), button.BackgroundColor3.R, button.AutoButtonColor)\nbutton.Text = "hi"\nH.runTask(0.01)\nbutton:Destroy()')
a("how-to_08-migrating-from-v1-L342", post='print(card.BorderSizePixel, card.BackgroundColor3.B, #card:GetChildren(), card:GetChildren()[1].ClassName)')

# ---------------- how-to 09 ----------------
P("how-to_09-overlays-modal-toast-L10")
M9 = "how-to_09-overlays-modal-toast-L46"
a("how-to_09-overlays-modal-toast-L35", post='print(open:Get())')
a(M9, post='local o = q.Source(true); local m = Modal { Open = o, Title = "t", OnConfirm = function() print("confirm") end, OnCancel = function() print("cancel") end }\nprint(m.Visible, #m:GetChildren())\nfor _, ch in m:GetChildren() do if ch.ClassName == "TextButton" and ch.Text == "확인" then ch.Activated:Fire() end end\nprint(o:Get(), m.Visible)')
a("how-to_09-overlays-modal-toast-L98", **{"with": [M9]}, post='print(confirmDialog.Visible); open:Set(true); print(confirmDialog.Visible)')
a("how-to_09-overlays-modal-toast-L114", **{"with": [M9]}, post='local host = D.Frame { activeModal }\nopenConfirmDialog(); print(activeModal:Get() ~= nil, #host:GetChildren())\nlocal m = activeModal:Get(); for _, ch in m:GetChildren() do if ch.Text == "확인" then ch.Activated:Fire() end end\nprint(activeModal:Get(), #host:GetChildren(), H.mock.isDestroyed(m))', note="보강: activeModal을 자리에 놓는 호스트")
MC = ("how-to_09-overlays-modal-toast-L141", "ModalContext")
a("how-to_09-overlays-modal-toast-L141", module="ModalContext", post='print(__mod_ModalContext.Provider ~= nil)')
c("how-to_09-overlays-modal-toast-L174", **{"with": [MC]}, pre2='const ModalContext = require("@game/ReplicatedStorage/Client/UI/ModalContext")',
  post='local op = q.Source(false); local ctx = q.Context():Set(ModalContext.Provider, { Open = op }); local b = DeleteButton { Ctx = ctx }; b.Activated:Fire(); print(op:Get())', note="보강: ModalContext require(L154에 있음)")
c("how-to_09-overlays-modal-toast-L154", **{"with": [M9, MC]},
  pre2=('const ModalContext = require("@game/ReplicatedStorage/Client/UI/ModalContext")\n'
       'local function DeepPanel(props: { read Ctx: q.Context }): Frame\n    local modal = props.Ctx:Get(ModalContext.Provider)\n    return D.Frame { D.Frame { D.TextButton { Text = "삭제", Activated = function() modal.Open:Set(true) end } } }\nend'),
  ssub=[('const ModalContext = require("@game/ReplicatedStorage/Client/UI/ModalContext")\n', '')],
  post='local modal; for _, ch in screen:GetChildren() do if ch.ClassName == "Frame" and ch.Visible ~= nil and ch.Size.X.Offset == 360 then modal = ch end end\nprint(modal.Visible)\nscreen:GetChildren()[1]:GetChildren()[1]:GetChildren()[1].Activated:Fire()\nlocal vis; for _, ch in screen:GetChildren() do if ch.Size and ch.Size.X.Offset == 360 then vis = ch.Visible end end; print(vis)', note="보강: DeepPanel 정의(블록이 '몇 층 아래'로 생략), ModalContext require를 앞으로")
a("how-to_09-overlays-modal-toast-L196", post='pushToast("a"); pushToast("b"); print("kids", #toastHost:GetChildren())\nH.runTask(3.01); print("kids", #toastHost:GetChildren())')
a("how-to_09-overlays-modal-toast-L259", post='local c1 = SafeCard { Text = "" }; print(c1.ClassName, #c1:GetChildren(), errorState:Get() ~= nil)\nlocal c2 = SafeCard { Text = "ok" }; print(#c2:GetChildren())')
a("how-to_09-overlays-modal-toast-L282", post='local es = q.Source<<any>>(nil); local m = ErrorModal { Error = es, OnReport = function(e) print("rep", e) end, OnConfirm = function() es:Set(nil) end }\nprint(m.Visible); es:Set("boom"); print(m.Visible, m:GetChildren()[1].Text)')
c("how-to_09-overlays-modal-toast-L324", **{"with": ["how-to_09-overlays-modal-toast-L259", "how-to_09-overlays-modal-toast-L282"]}, pre='local someUnsafeText = ""',
  post='local em; for _, ch in screen:GetChildren() do if #ch:GetChildren() == 3 then em = ch end end\nprint(errorState:Get() ~= nil, em.Visible)\nfor _, ch in em:GetChildren() do if ch.Text == "확인" then ch.Activated:Fire() end end\nprint(errorState:Get(), em.Visible)', note="보강: someUnsafeText 정의")

# ---------------- how-to 10 ----------------
P("how-to_10-debugging-and-troubleshooting-L10")
c("how-to_10-debugging-and-troubleshooting-L64", mpre='local props = {}',
  spre='local RobloxModule = require("@game/ReplicatedStorage/roblox_packages/quad_roblox")\nlocal props: { Modifier: RobloxModule.FrameModifier?, Ref: q.Ref<Frame?>? } = {}',
  sub=[('D.Frame { props.Modifier, props.Ref, Size = UDim2.new() }', 'print("both-nil ❌ line:", pcall(function() return D.Frame { props.Modifier, props.Ref, Size = UDim2.new() } end))\nlocal __r = q.PreRef<<Frame?>>(nil)\nprint("mod-nil+ref ❌ shape:", (select(2, pcall(function() return D.Frame { props.Modifier, __r, Size = UDim2.new() } end))))')],
  post='print("✅ ok")', note="보강: props 정의 + ❌ 줄을 pcall로")
c("how-to_10-debugging-and-troubleshooting-L82", pre='local myRef = q.PreRef<<Frame?>>(nil)\nlocal __host = D.Frame { myRef }', post='print(inst == __host)', note="보강: myRef 정의(값이 이미 있는 갈래만 — Wait 갈래는 probes/)")
a("how-to_10-debugging-and-troubleshooting-L111", post='local r = q.PreRef<<TextBox?>>(nil); local tb = CustomInput { InputRef = r }; print(r.Value == tb, tb.PlaceholderText)\nprint(CustomInput {}.ClassName)')
a("how-to_10-debugging-and-troubleshooting-L141", post='local f1, f2 = D.Frame { dynamicStyle }, D.Frame { dynamicStyle2 }; print(f1.BackgroundColor3.R, f2.BackgroundColor3.R)\nthemeColor:Set(Color3.fromRGB(0, 0, 255)); print(f1.BackgroundColor3.B, f2.BackgroundColor3.B)')
a("how-to_10-debugging-and-troubleshooting-L164", post='print(primary:Get()); theme:Set({ Primary = "blue", Size = 12 }); print(primary:Get())')
c("how-to_10-debugging-and-troubleshooting-L176", post='local st = q.Store { Username = q.Source("x"), Age = q.Source(3), AgreedToTerms = q.Source(true) }; resetForm(st); print(st.Username:Get(), st.Age:Get(), st.AgreedToTerms:Get())', note="보강: 호출")
c("how-to_10-debugging-and-troubleshooting-L205", pre='local items = q.Source({ "a", "b" })',
  sub=[('s:List(items, function(ctx) return D.Frame { Text = ctx.Item } end) -- 에러', 'print("❌ :List after :Add →", (select(2, pcall(function() s:List(items, function(ctx) return D.Frame { Text = ctx.Item } end) end))))')],
  post='local host = D.Frame { s2 }; print("✅ kids", #host:GetChildren(), host:GetChildren()[1].Text)', note="보강: items 정의 + ❌ 줄 pcall")

# ---------------- overview ----------------
a("overview_01-why-quad-L31", sub=[("D.Frame {", "local __f = D.Frame {")], post='print(#__f:GetChildren(), __f.BorderSizePixel); __f.MouseEnter:Fire(); print(__f.BackgroundColor3.R)')
c("overview_01-why-quad-L116", pre='local count = q.Source(3)', post='print(both:Get()); suffix:Set("번"); print(both:Get()); count:Set(4); print(both:Get())', note="보강: count 정의(앞 블록 문맥)")

# ---------------- quadnomicon ----------------
for k in ["quadnomicon_01-revision-and-epochmap-L61", "quadnomicon_01-revision-and-epochmap-L87", "quadnomicon_01-revision-and-epochmap-L120",
          "quadnomicon_02-slot-prefix-sum-tree-L94", "quadnomicon_03-luau-memory-topology-L34", "quadnomicon_04-covariant-markers-L33",
          "quadnomicon_04-covariant-markers-L76", "quadnomicon_04-covariant-markers-L98", "quadnomicon_05-non-destructive-portal-and-ownership-L111",
          "quadnomicon_06-liveness-gate-and-isolation-L32", "quadnomicon_06-liveness-gate-and-isolation-L74", "quadnomicon_06-liveness-gate-and-isolation-L90",
          "quadnomicon_06-liveness-gate-and-isolation-L99", "quadnomicon_06-liveness-gate-and-isolation-L116", "quadnomicon_06-liveness-gate-and-isolation-L158",
          "quadnomicon_07-instance-identity-and-gc-philosophy-L65", "quadnomicon_08-extensible-dispatch-engine-L43",
          "quadnomicon_10-multi-backend-abstract-machine-L117", "quadnomicon_11-static-grepability-and-error-architecture-L50",
          "quadnomicon_11-static-grepability-and-error-architecture-L152"]:
    b(k)
P("quadnomicon_05-non-destructive-portal-and-ownership-L34")
c("quadnomicon_05-non-destructive-portal-and-ownership-L92", pre='local myInstanceState = q.Source<<Instance?>>(nil)', sub=[("D.Frame {", "local __f = D.Frame {")],
  post='local x = D.TextLabel {}; myInstanceState:Set(x); print(x.Parent == __f)\n__f:Destroy(); print("x destroyed with host?", H.mock.isDestroyed(x))', note="보강: myInstanceState 정의 + OwnsElements=false 확인")
c("quadnomicon_07-instance-identity-and-gc-philosophy-L106", mpre=TPL+CLONE+'local __tplRoot = tpl("Frame", "Card", { tpl("TextLabel", "Title") })', spre='local __tplRoot: Frame = nil :: any',
  ssub=[("<Studio에서 만들어 둔 템플릿 Instance>", "__tplRoot")], sub=[("template:Clone()", "__clone(template)")],
  post='print(root.BackgroundTransparency, root:FindFirstChild("Title").Text, root ~= template, root.Parent)', note="보강: 자리표시 템플릿 → foreign Frame, mock :Clone 없음")
a("quadnomicon_09-fragment-breakthrough-and-domless-slot-L79", post='local names = {}; for _, ch in root:GetChildren() do table.insert(names, ch.Name) end; table.sort(names); print(#names, table.concat(names, ","))')
a("quadnomicon_09-fragment-breakthrough-and-domless-slot-L139", **{"with": ["quadnomicon_09-fragment-breakthrough-and-domless-slot-L79"]},
  post='local host = D.Frame { D.Frame {}, list }\nlocal function lo() local t = {} for _, ch in host:GetChildren() do if ch.ClassName == "TextButton" then t[ch.LayoutOrder] = ch.Text end end local o = {} for k, v in t do table.insert(o, k .. "=" .. v) end table.sort(o) return table.concat(o, " ") end\nprint(lo()); data:Set({ "c", "a" }); print(lo())')
a("quadnomicon_11-static-grepability-and-error-architecture-L19", sub=[("addDep(nil) --", 'print(pcall(addDep, nil)) --')], note="보강: 마지막 호출을 pcall로(주석의 메시지 대조)")

# ---------------- landing ----------------
a("landing_index-L58", post='local lbl, btn; for _, ch in card:GetChildren() do if ch.ClassName == "TextLabel" then lbl = ch elseif ch.ClassName == "TextButton" then btn = ch end end\nprint(lbl.Text); btn.Activated:Fire(); print(lbl.Text, card.BorderSizePixel, #card:GetChildren())')
