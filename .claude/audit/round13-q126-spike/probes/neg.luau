--!strict
-- Q126 spike — NEGATIVE rows: every labelled line must STILL error after the change.
local q = require("./config")
local QT = require("../quad-types/src")
local D = q.Declaration
type None = QT.None

local _n1 = D.TextLabel { Text = q.Source(nil :: string?) } -- N1 engine refuses nil: State<string?> into Text
local _n2 = D.TextLabel { Text = q.Source<<string | None>>("a") } -- N2 State<string|None> into Text
local _n3 = D.Frame { BackgroundTransparency = q.Source(nil :: number?) } -- N3 tweenable non-nil prop
local _n4 = D.Frame { BackgroundColor3 = q.Source<<Color3 | None>>(Color3.new()) } -- N4
local _n5 = D.Frame { NextSelectionUp = q.Source(nil :: BasePart?) } -- N5 wrong class into object ref
local _n6 = D.Frame { NextSelectionUp = q.Source(nil :: number?) } -- N6 wrong type into object ref
local _n7 = D.Frame { NextSelectionUp = 5 } -- N7 wrong literal
local _n8 = D.TextButton { Activated = q.Source(nil :: number?) } -- N8 wrong type into event
local _n9 = D.TextButton { Activated = q.Source(nil :: ((x: string) -> ())?) } -- N9 wrong callback signature
local _n10 = D.Frame { UICorner = q.Source(nil :: string?) } -- N10 wrong type into shorthand
local _n11 = q.NumberAttr("N", q.Source(nil :: string?)) -- N11 wrong type into Attr sugar
local _n12 = q.Slot<<Frame>>():Add(q.Source(nil :: TextLabel?)) -- N12 wrong class into Slot
local _n13 = q.Slot<<Frame>>():Add(q.Source(nil :: Instance?)) -- N13 supertype into Slot<Frame>
local _n14 = D.Modifier.Frame():BackgroundTransparency(q.Source(nil :: number?)) -- N14 setter of non-nil prop
local _n15 = D.Modifier.TextLabel():Text(q.Source(nil :: string?)) -- N15
local _n16 = D.Modifier.Frame():NextSelectionUp(q.Source(nil :: BasePart?)) -- N16 wrong class setter
local _n17 = D.Modifier.Frame():UICorner(q.Source(nil :: string?)) -- N17 wrong type shorthand setter
local plain = q.Source(true)
plain:Set(q.None) -- N18 Set(None) on a State not declared wide (option (ii) would silence this)
local _n19 = D.TextLabel { Text = q.Source(nil :: GuiObject?) } -- N19 object type into string prop
local _n20 = q.StringAttr("S", nil) -- N20 literal nil into Attr sugar (runtime Quad0014)
local rl = q.Ref(nil :: TextLabel?)
local _n21 = D.TextBox { q.Source(rl :: typeof(rl)?) } -- N21 State<sibling-class Ref?> into TextBox children
local di = q.OnChange("Image", function(_v: string) end)
local _n22 = D.TextBox { q.Source(di :: typeof(di)?) } -- N22 State<OnChange of a prop TextBox lacks?>
