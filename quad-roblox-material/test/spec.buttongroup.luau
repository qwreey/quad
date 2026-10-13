--!strict
-- ButtonGroup (M3 Expressive connected button group — src/Button/Group.luau, drawn by src/Button/Segment.luau).
-- The mock has no layout or rendering: structure, tokens, state and input logic are asserted here; what the corners,
-- the selection morph and the Elevated shadows LOOK like is a Studio matter.
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")
local ButtonGroup = require("../src/Button/Group")
local Icons = require("../src/Icons")
local Util = require("../src/Util")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local baseConns = uisConns()
local L, Dk = Tokens.Color.Light, Tokens.Color.Dark

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end
local function cellsOf(g: any): { any }
	return H.findAll(g, function(c: any)
		return c.Name == "Cell"
	end)
end
local function face(cell: any, clipName: string): any
	return H.find(H.find(cell, clipName), "Face")
end
local function cornerOf(inst: any): UDim
	return H.find(inst, "_quad_round").CornerRadius
end
-- every face of a cell (two for an end cell, one for a middle cell)
local function facesOf(cell: any): { any }
	return H.findAll(cell, function(c: any)
		return c.Name == "Face"
	end)
end
-- lays the cells out: their content frames measured `widths[i]` local px wide (no UIScale in the mock)
local function layout(g: any, widths: { number })
	for i, cell in cellsOf(g) do
		H.setAbs(H.find(cell, "Content"), 0, 0, widths[i], 40)
	end
end
local function click(cell: any)
	H.fire(cell, "Activated", H.input({}), 1)
end
local function press(cell: any)
	H.fire(cell, "InputBegan", H.input({ Position = Vector3.new(10, 10, 0) }))
end
local function release(cell: any)
	H.fire(cell, "InputEnded", H.input({}))
end

local THREE: { ButtonGroup.Item } = {
	{ Key = "day", Label = "Day" },
	{ Key = "week", Label = "Week" },
	{ Key = "month", Label = "Month" },
}

H.section("mount: cells 2 px apart, ends Full outside / 8 inside, middle 8 all round, selected = pill; instance count", function()
	local value = q.Source(nil :: string?)
	local g = ButtonGroup({ Items = THREE, Value = value })
	assert(g.ClassName == "Frame" and g.Name == "ButtonGroup" and g.AutomaticSize == Enum.AutomaticSize.X and g.Size == UDim2.fromOffset(0, 40))
	local lay = class(g, "UIListLayout")[1]
	assert(lay.Parent == g and lay.Padding == UDim.new(0, 2) and lay.FillDirection == Enum.FillDirection.Horizontal, "ConnectedSpaceBetween 2")
	assert(lay.SortOrder == Enum.SortOrder.LayoutOrder)
	local cells = cellsOf(g)
	assert(#cells == 3, "one cell per item")
	for i, cell in cells do
		assert(cell.ClassName == "TextButton" and cell.Parent == g and cell.LayoutOrder == i, "TextButtons in Items order")
		assert(cell.Size == UDim2.fromOffset(0, 40), "unmeasured: no minimum width (ToggleButton has none)")
	end
	local n = H.countDescendants(g)
	print("ButtonGroup (Filled, 3 cells, no icon) descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	-- an end cell: TextButton 1 + 2 sides x (clip + face + UICorner + StateLayer + its UICorner) = 10 + ring 3 + Content +
	-- UIPadding 2 + Label 1 = 17; a middle cell: TextButton 1 + face + UICorner + StateLayer + its UICorner = 4 + ring 3 +
	-- Content + UIPadding 2 + Label 1 = 11; the host's UIListLayout 1 -> 17 + 11 + 17 + 1
	assert(n == 46, "46 descendants, got " .. n)
	layout(g, { 57.4, 64, 70 })
	assert(cells[1].Size == UDim2.fromOffset(58, 40) and cells[2].Size == UDim2.fromOffset(64, 40) and cells[3].Size == UDim2.fromOffset(70, 40), "W = ceil(content)")
	H.finishTweens()
	-- leading: outer side [0, 29] rounded 20, inner side [29, 58] rounded 8; both faces are the full 58 x 40
	local lead, mid, trail = cells[1], cells[2], cells[3]
	local lo, li = H.find(lead, "OuterClip"), H.find(lead, "InnerClip")
	assert(lo.ClipsDescendants and li.ClipsDescendants and lo.Position == UDim2.fromOffset(0, 0) and lo.Size == UDim2.fromOffset(29, 40))
	assert(li.Position == UDim2.fromOffset(29, 0) and li.Size == UDim2.fromOffset(29, 40))
	assert(face(lead, "OuterClip").Size == UDim2.fromOffset(58, 40) and face(lead, "InnerClip").Position == UDim2.fromOffset(-29, 0))
	assert(cornerOf(face(lead, "OuterClip")) == UDim.new(0, 20) and cornerOf(face(lead, "InnerClip")) == UDim.new(0, 8), "Full outside, Small (8) inside")
	-- trailing: inner side first
	local ti, to = H.find(trail, "InnerClip"), H.find(trail, "OuterClip")
	assert(ti.Position == UDim2.fromOffset(0, 0) and ti.Size == UDim2.fromOffset(35, 40) and to.Position == UDim2.fromOffset(35, 0))
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 8) and cornerOf(face(trail, "OuterClip")) == UDim.new(0, 20))
	-- middle: ONE face, a direct child of the cell, no clip
	assert(H.find(mid, "OuterClip") == nil and H.find(mid, "InnerClip") == nil and H.find(mid, "Clip") == nil, "no clip in a middle cell")
	local mf = facesOf(mid)
	assert(#mf == 1 and mf[1].Parent == mid and mf[1].Position == UDim2.fromOffset(0, 0) and mf[1].Size == UDim2.fromOffset(64, 40))
	assert(cornerOf(mf[1]) == UDim.new(0, 8), "middle: 8 on all four corners")
	-- content: 16 / 16, LabelLarge, at the cell's origin (the cell is exactly as wide as its content)
	for i, cell in cells do
		local pad = class(H.find(cell, "Content"), "UIPadding")[1]
		assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 16), "ButtonSmallTokens 16 / 16")
		local label = H.find(cell, "Label")
		assert(label.Text == THREE[i].Label and label.TextSize == 14, "LabelLarge")
		assert(H.find(cell, "Content").Position == UDim2.fromOffset(0, 0), "no optical shift, no centering offset")
		-- unselected Filled: SurfaceContainer / OnSurfaceVariant
		for _, f in facesOf(cell) do
			assert(f.BackgroundColor3 == L.SurfaceContainer and f.BackgroundTransparency == 0)
		end
		assert(label.TextColor3 == L.OnSurfaceVariant and label.TextTransparency == 0)
	end
	-- selecting a cell: every inner corner of it goes Full (a pill), in Primary / OnPrimary; the others stay
	value:Set("day")
	H.finishTweens()
	assert(cornerOf(face(lead, "InnerClip")) == UDim.new(0, 20) and cornerOf(face(lead, "OuterClip")) == UDim.new(0, 20), "selected leading: pill")
	assert(face(lead, "InnerClip").BackgroundColor3 == L.Primary and face(lead, "OuterClip").BackgroundColor3 == L.Primary)
	assert(H.find(lead, "Label").TextColor3 == L.OnPrimary)
	assert(cornerOf(mf[1]) == UDim.new(0, 8) and mf[1].BackgroundColor3 == L.SurfaceContainer, "the neighbour does not change")
	value:Set("week")
	H.finishTweens()
	assert(cornerOf(mf[1]) == UDim.new(0, 20) and mf[1].BackgroundColor3 == L.Primary and H.find(mid, "Label").TextColor3 == L.OnPrimary, "selected middle: pill")
	assert(cornerOf(face(lead, "InnerClip")) == UDim.new(0, 8) and face(lead, "InnerClip").BackgroundColor3 == L.SurfaceContainer, "the old one goes back")
	value:Set("month")
	H.finishTweens()
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 20) and face(trail, "OuterClip").BackgroundColor3 == L.Primary)
	value:Set("nothing-like-this")
	H.finishTweens()
	for _, cell in cells do
		for _, f in facesOf(cell) do
			assert(f.BackgroundColor3 == L.SurfaceContainer, "a key that is not in Items selects nothing")
		end
	end
	q.dispose(g)
	H.assertNoDebugOutput("group mount")
end)

H.section("shape: pressed inner corners 8 -> 4 (outer stays Full), pressed wins over selected; no width change on press", function()
	local value = q.Source("week" :: string?)
	local g = ButtonGroup({ Items = THREE, Value = value })
	layout(g, { 58, 64, 70 })
	local cells = cellsOf(g)
	local lead, mid, trail = cells[1], cells[2], cells[3]
	H.finishTweens()
	press(lead)
	H.finishTweens()
	assert(cornerOf(face(lead, "InnerClip")) == UDim.new(0, 4), "pressed: CornerValueExtraSmall 4")
	assert(cornerOf(face(lead, "OuterClip")) == UDim.new(0, 20), "the outer corners stay Full while pressed")
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 8), "only the pressed cell morphs")
	assert(lead.Size == UDim2.fromOffset(58, 40) and mid.Size == UDim2.fromOffset(64, 40), "a connected group does not widen the pressed cell")
	release(lead)
	H.finishTweens()
	assert(cornerOf(face(lead, "InnerClip")) == UDim.new(0, 8))
	-- the selected middle cell is a pill; pressed it takes the pressed shape (shapeByInteraction: pressed first)
	assert(cornerOf(facesOf(mid)[1]) == UDim.new(0, 20))
	press(mid)
	H.finishTweens()
	assert(cornerOf(facesOf(mid)[1]) == UDim.new(0, 4), "pressed wins over selected")
	release(mid)
	H.finishTweens()
	assert(cornerOf(facesOf(mid)[1]) == UDim.new(0, 20), "back to the selected pill")
	-- the focus ring: an end cell's at the outer radius, a middle cell's follows its corners
	assert(cornerOf(H.find(lead, "FocusRing")) == UDim.new(0, 20) and cornerOf(H.find(mid, "FocusRing")) == UDim.new(0, 20))
	value:Set("day")
	H.finishTweens()
	assert(cornerOf(H.find(mid, "FocusRing")) == UDim.new(0, 8), "the middle ring is the cell's own shape")
	local ringStroke = H.find(H.find(mid, "FocusRing"), "Ring")
	assert(ringStroke.Enabled == false)
	H.fire(mid, "SelectionGained")
	assert(ringStroke.Enabled == true and ringStroke.Thickness == 3, "each cell is its own selection stop with the kit ring")
	H.fire(mid, "SelectionLost")
	assert(ringStroke.Enabled == false)
	q.dispose(g)
	H.assertNoDebugOutput("group shape")
end)

H.section("single selection: a click writes the Key and calls OnChange; the selected cell stays (Required default); a write is silent", function()
	local value = q.Source(nil :: string?)
	local calls: { string } = {}
	local g = ButtonGroup({
		Items = THREE,
		Value = value,
		OnChange = function(v)
			table.insert(calls, v or "<nil>")
		end,
	})
	local cells = cellsOf(g)
	click(cells[2])
	assert(value:Get() == "week" and #calls == 1 and calls[1] == "week", "click -> Source + OnChange(key)")
	click(cells[2])
	assert(value:Get() == "week" and #calls == 1, "the selected cell clicked again: nothing (one is always selected)")
	click(cells[3])
	assert(value:Get() == "month" and #calls == 2 and calls[2] == "month")
	value:Set("day")
	H.finishTweens()
	assert(#calls == 2, "a programmatic write does not call OnChange")
	assert(face(cells[1], "OuterClip").BackgroundColor3 == L.Primary and face(cells[3], "OuterClip").BackgroundColor3 == L.SurfaceContainer, "the cells follow the Source")
	value:Set(nil)
	H.finishTweens()
	assert(face(cells[1], "OuterClip").BackgroundColor3 == L.SurfaceContainer, "the owner may still clear it")
	q.dispose(g)

	-- Required = false: the selected cell switches off (nil)
	local v2 = q.Source("day" :: string?)
	local seen: { string } = {}
	local g2 = ButtonGroup({
		Items = THREE,
		Value = v2,
		Required = false,
		OnChange = function(v)
			table.insert(seen, v or "<nil>")
		end,
	})
	local c2 = cellsOf(g2)
	click(c2[1])
	assert(v2:Get() == nil and seen[1] == "<nil>", "Required = false: a click on the selected cell clears the selection")
	click(c2[1])
	assert(v2:Get() == "day" and seen[2] == "day")
	q.dispose(g2)
	H.assertNoDebugOutput("group single")
end)

H.section("multiple selection: cells toggle in a NEW table, foreign keys kept, OnValuesChange; Required keeps the last one", function()
	local first: { [string]: boolean } = { week = true, other = true }
	local values = q.Source(first)
	local calls: { { [string]: boolean } } = {}
	local g = ButtonGroup({
		Items = THREE,
		Values = values,
		OnValuesChange = function(v)
			table.insert(calls, v)
		end,
	})
	local cells = cellsOf(g)
	H.finishTweens()
	assert(facesOf(cells[2])[1].BackgroundColor3 == L.Primary and face(cells[1], "OuterClip").BackgroundColor3 == L.SurfaceContainer)
	click(cells[1])
	local second = values:Get()
	assert(second ~= first and first.day == nil, "a new table; the old one is not touched")
	assert(second.day == true and second.week == true and second.other == true, "added, the rest (a key outside Items too) kept")
	assert(#calls == 1 and calls[1] == second, "OnValuesChange(new)")
	click(cells[2])
	local third = values:Get()
	assert(third.week == nil and third.day == true and third.other == true and #calls == 2, "switched off = the key is absent")
	click(cells[1])
	assert(values:Get().day == nil and #calls == 3, "Required defaults to false with Values: the last one switches off too")
	H.finishTweens()
	for _, cell in cells do
		assert(facesOf(cell)[1].BackgroundColor3 == L.SurfaceContainer)
	end
	values:Set({ month = true, day = true })
	H.finishTweens()
	assert(#calls == 3, "a programmatic write does not call OnValuesChange")
	assert(face(cells[3], "OuterClip").BackgroundColor3 == L.Primary and cornerOf(face(cells[1], "InnerClip")) == UDim.new(0, 20), "two pills at once")
	q.dispose(g)

	local v2 = q.Source({ day = true, week = true, other = true } :: { [string]: boolean })
	local n = 0
	local g2 = ButtonGroup({
		Items = THREE,
		Values = v2,
		Required = true,
		OnValuesChange = function()
			n += 1
		end,
	})
	local c2 = cellsOf(g2)
	click(c2[1])
	assert(v2:Get().day == nil and n == 1, "two selected: one may go")
	local before = v2:Get()
	click(c2[2])
	assert(v2:Get() == before and before.week == true and n == 1, "Required: the last selected cell of the group stays (a foreign key does not count)")
	click(c2[3])
	click(c2[2])
	assert(v2:Get().week == nil and v2:Get().month == true and n == 3)
	q.dispose(g2)
	H.assertNoDebugOutput("group multiple")
end)

H.section("variants: toggle button roles; Outlined outline per face that leaves when selected; Elevated shadow per face", function()
	local value = q.Source("week" :: string?)
	local tonal = ButtonGroup({ Items = THREE, Value = value, Variant = "Tonal" })
	H.finishTweens()
	local tc = cellsOf(tonal)
	assert(face(tc[1], "OuterClip").BackgroundColor3 == L.SecondaryContainer and H.find(tc[1], "Label").TextColor3 == L.OnSecondaryContainer)
	assert(facesOf(tc[2])[1].BackgroundColor3 == L.Secondary and H.find(tc[2], "Label").TextColor3 == L.OnSecondary, "Tonal selected: Secondary / OnSecondary")
	assert(#class(tonal, "UIShadow") == 0 and #class(tonal, "UIStroke") == 3, "no shadow; the only strokes are the three focus rings")
	q.dispose(tonal)

	local outlined = ButtonGroup({ Items = THREE, Value = value, Variant = "Outlined" })
	H.finishTweens()
	local oc = cellsOf(outlined)
	local strokes = H.findAll(outlined, function(c: any)
		return c.Name == "Outline"
	end)
	assert(#strokes == 5, "one outline per face (2 + 1 + 2), got " .. #strokes)
	for _, st in strokes do
		assert(st.BorderStrokePosition == Enum.BorderStrokePosition.Inner and st.Thickness == 1 and st.Color == L.OutlineVariant, "1 px OutlineVariant inside the face")
	end
	assert(face(oc[1], "OuterClip").BackgroundTransparency == 1 and H.find(face(oc[1], "OuterClip"), "Outline").Transparency == 0, "unselected: no container, outline shown")
	assert(H.find(oc[1], "Label").TextColor3 == L.OnSurfaceVariant)
	local of = facesOf(oc[2])[1]
	assert(of.BackgroundColor3 == L.InverseSurface and of.BackgroundTransparency == 0 and H.find(oc[2], "Label").TextColor3 == L.InverseOnSurface, "selected: InverseSurface / InverseOnSurface")
	assert(H.find(of, "Outline").Transparency == 1, "selected: no outline (OutlinedToggleButtonDefaults.border)")
	value:Set("day")
	H.finishTweens()
	assert(of.BackgroundTransparency == 1 and H.find(of, "Outline").Transparency == 0 and face(oc[1], "InnerClip").BackgroundTransparency == 0)
	q.dispose(outlined)

	value:Set("week")
	local elevated = ButtonGroup({ Items = THREE, Value = value, Variant = "Elevated" })
	layout(elevated, { 58, 64, 70 })
	H.finishTweens()
	local ec = cellsOf(elevated)
	local shadows = class(elevated, "UIShadow")
	assert(#shadows == 5, "one UIShadow per face, got " .. #shadows)
	-- Filled 46 + 5 UIShadow + the middle cell's Clip
	assert(H.countDescendants(elevated) == 52, "52 descendants, got " .. H.countDescendants(elevated))
	assert(face(ec[1], "OuterClip").BackgroundColor3 == L.SurfaceContainerLow and H.find(ec[1], "Label").TextColor3 == L.Primary)
	assert(facesOf(ec[2])[1].BackgroundColor3 == L.Primary and H.find(ec[2], "Label").TextColor3 == L.OnPrimary)
	local lv = Tokens.Elevation.Levels
	local R = 2 * lv[2].BlurRadius + lv[2].Spread + lv[2].OffsetY
	-- leading: outer side open by the reach, inner side by the 2 px gap; the middle cell: one clip open by the gap on
	-- both sides (its shadow must not be drawn over a neighbour's container); R above and below everywhere
	local lo, li = H.find(ec[1], "OuterClip"), H.find(ec[1], "InnerClip")
	assert(lo.Position == UDim2.fromOffset(-R, -R) and lo.Size == UDim2.fromOffset(29 + R, 40 + 2 * R), `leading outer clip {lo.Position} {lo.Size}`)
	assert(li.Position == UDim2.fromOffset(29, -R) and li.Size == UDim2.fromOffset(29 + 2, 40 + 2 * R), `leading inner clip {li.Position} {li.Size}`)
	local mc = H.find(ec[2], "Clip")
	assert(mc ~= nil and mc.Parent == ec[2] and mc.ClipsDescendants == true, "a shadowed middle cell has one clip")
	assert(mc.Position == UDim2.fromOffset(-2, -R) and mc.Size == UDim2.fromOffset(64 + 4, 40 + 2 * R), `middle clip {mc.Position} {mc.Size}`)
	local mface = facesOf(ec[2])[1]
	assert(mface.Parent == mc and mface.Position == UDim2.fromOffset(2, R) and mface.Size == UDim2.fromOffset(64, 40), "the face stays at the cell's origin")
	local to = H.find(ec[3], "OuterClip")
	assert(to.Position == UDim2.fromOffset(35, -R) and to.Size == UDim2.fromOffset(35 + R, 40 + 2 * R))
	for _, sh in shadows do
		assert(sh.Parent.Name == "Face" and sh.Enabled == true and sh.BlurRadius == UDim.new(0, lv[1].BlurRadius), "level 1 at rest, the shadow follows its face's UICorner")
	end
	H.fire(ec[2], "MouseEnter")
	H.finishTweens()
	assert(class(mface, "UIShadow")[1].BlurRadius == UDim.new(0, lv[2].BlurRadius) and class(face(ec[1], "OuterClip"), "UIShadow")[1].BlurRadius == UDim.new(0, lv[1].BlurRadius), "the hovered cell alone rises to 2")
	H.fire(ec[2], "MouseLeave")
	q.dispose(elevated)

	assert(not pcall(ButtonGroup, { Items = THREE, Value = value, Variant = "Text" :: any }), "no text variant")
	H.assertNoDebugOutput("group variants")
end)

H.section("disabled: the group's State and an item's own; OnSurface @ 10 % / content @ 38 %, no click; Outlined uses OutlineVariant", function()
	local value = q.Source("day" :: string?)
	local disabled = q.Source(false)
	local own = q.Source(true)
	local calls = 0
	local g = ButtonGroup({
		Items = { { Key = "day", Label = "Day" }, { Key = "week", Label = "Week", Disabled = own }, { Key = "month", Label = "Month" } },
		Value = value,
		Disabled = disabled,
		OnChange = function()
			calls += 1
		end,
	})
	H.finishTweens()
	local cells = cellsOf(g)
	local mid = facesOf(cells[2])[1]
	assert(cells[2].Interactable == false and cells[1].Interactable == true and cells[3].Interactable == true, "the item's own Disabled")
	assert(mid.BackgroundColor3 == L.OnSurface and near(mid.BackgroundTransparency, 0.9), "container OnSurface @ 10 % (DisabledContainerOpacity 0.1)")
	assert(H.find(cells[2], "Label").TextColor3 == L.OnSurface and near(H.find(cells[2], "Label").TextTransparency, 0.62))
	click(cells[2])
	assert(value:Get() == "day" and calls == 0, "a disabled cell does not select")
	own:Set(false)
	H.finishTweens()
	assert(cells[2].Interactable == true and mid.BackgroundColor3 == L.SurfaceContainer and mid.BackgroundTransparency == 0)
	click(cells[2])
	assert(value:Get() == "week" and calls == 1)
	disabled:Set(true)
	H.finishTweens()
	for _, cell in cells do
		assert(cell.Interactable == false)
		for _, f in facesOf(cell) do
			assert(f.BackgroundColor3 == L.OnSurface and near(f.BackgroundTransparency, 0.9), "selected or not: the disabled container")
		end
		assert(near(H.find(cell, "Label").TextTransparency, 0.62))
	end
	assert(cornerOf(mid) == UDim.new(0, 20), "a disabled selected cell keeps its shape")
	click(cells[3])
	assert(value:Get() == "week" and calls == 1)
	disabled:Set(false)
	H.finishTweens()
	assert(mid.BackgroundColor3 == L.Primary and cells[1].Interactable == true)
	q.dispose(g)

	local outlined = ButtonGroup({ Items = THREE, Value = value, Variant = "Outlined", Disabled = true })
	H.finishTweens()
	local oc = cellsOf(outlined)
	local f1 = face(oc[1], "OuterClip")
	assert(f1.BackgroundColor3 == L.OutlineVariant and near(f1.BackgroundTransparency, 0.9), "Outlined disabled: OutlineVariant @ 10 %")
	assert(near(H.find(f1, "Outline").Transparency, 0.9), "its outline @ 10 %")
	assert(H.find(facesOf(oc[2])[1], "Outline").Transparency == 1, "a selected cell has no outline, disabled or not")
	q.dispose(outlined)
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("group disabled")
end)

H.section("Width: the cells share a fixed width equally (remainder to the first), labels centered; content width until measured", function()
	local value = q.Source("day" :: string?)
	local g = ButtonGroup({ Items = THREE, Value = value, Width = UDim.new(1, 0) })
	assert(g.Size == UDim2.new(1, 0, 0, 40) and g.AutomaticSize == Enum.AutomaticSize.None, "the host takes the width")
	local cells = cellsOf(g)
	layout(g, { 58, 64, 70 })
	assert(cells[1].Size == UDim2.fromOffset(58, 40), "host not measured yet: content width")
	H.setAbs(g, 0, 0, 305, 40)
	-- 305 - 2 x 2 = 301 = 3 x 100 + 1
	assert(cells[1].Size == UDim2.fromOffset(101, 40) and cells[2].Size == UDim2.fromOffset(100, 40) and cells[3].Size == UDim2.fromOffset(100, 40), `equal shares: {cells[1].Size} {cells[2].Size} {cells[3].Size}`)
	assert(H.find(cells[1], "Content").Position == UDim2.fromOffset(21, 0), "content centered: floor((101 - 58) / 2)")
	assert(H.find(cells[2], "Content").Position == UDim2.fromOffset(18, 0) and H.find(cells[3], "Content").Position == UDim2.fromOffset(15, 0))
	assert(H.find(cells[1], "OuterClip").Size == UDim2.fromOffset(50, 40) and face(cells[1], "InnerClip").Size == UDim2.fromOffset(101, 40), "the faces follow the cell")
	H.setAbs(g, 0, 0, 244, 40)
	assert(cells[1].Size == UDim2.fromOffset(80, 40) and cells[3].Size == UDim2.fromOffset(80, 40), "a resize re-shares")
	assert(H.find(cells[1], "Content").Position == UDim2.fromOffset(11, 0), "placed, not slid (no tween on a container resize)")
	q.dispose(g)
	local px = ButtonGroup({ Items = THREE, Value = value, Width = 240 })
	assert(px.Size == UDim2.fromOffset(240, 40) and px.AutomaticSize == Enum.AutomaticSize.None, "a number is pixels")
	q.dispose(px)
	H.assertNoDebugOutput("group width")
end)

H.section("icons: 20 px, 8 px before the label, in the cell's content color; a State icon follows", function()
	local value = q.Source("a" :: string?)
	local which: Q.State<string> = value:Compute(function(self)
		return if self:Get() == "b" then "check" else "close"
	end)
	local g = ButtonGroup({
		Items = { { Key = "a", Label = "A", Icon = "check" }, { Key = "b", Label = "B", Icon = which }, { Key = "c", Label = "C" } },
		Value = value,
	})
	H.finishTweens()
	local cells = cellsOf(g)
	local icon = H.find(cells[1], "Icon")
	assert(icon.ClassName == "ImageLabel" and icon.Image == Icons.Defaults.check and icon.Size == UDim2.fromOffset(20, 20), "ButtonSmallTokens.IconSize 20")
	assert(icon.ImageColor3 == L.OnPrimary and icon.LayoutOrder < H.find(cells[1], "Label").LayoutOrder, "before the label, in the selected content color")
	local list = class(H.find(cells[1], "Content"), "UIListLayout")[1]
	assert(list.Padding == UDim.new(0, 8) and list.HorizontalAlignment == Enum.HorizontalAlignment.Left, "IconLabelSpace 8; Left under an auto-sized Content")
	assert(H.find(cells[3], "Icon") == nil and #class(H.find(cells[3], "Content"), "UIListLayout") == 0, "no icon: no layout")
	local si = H.find(cells[2], "Icon")
	assert(si.Image == Icons.Defaults.close and si.ImageColor3 == L.OnSurfaceVariant)
	click(cells[2])
	H.finishTweens()
	assert(si.Image == Icons.Defaults.check and si.ImageColor3 == L.OnPrimary, "the Compose samples' convention: the icon changes with the selection (a State icon)")
	q.dispose(g)
	H.assertNoDebugOutput("group icons")
end)

H.section("press: a ripple per face of the same disc (two in an end cell, one in a middle cell); Offsets only below the host", function()
	local value = q.Source("day" :: string?)
	local g = ButtonGroup({ Items = THREE, Value = value })
	layout(g, { 80, 64, 70 })
	local cells = cellsOf(g)
	local lead, mid = cells[1], cells[2]
	local layers = H.findAll(lead, function(c: any)
		return c.Name == "StateLayer"
	end)
	assert(#layers == 2, "a state layer per face")
	for _, layer in layers do
		H.setAbs(layer, 100, 50, 80, 40)
	end
	H.fire(lead, "InputBegan", H.input({ Position = Vector3.new(160, 62, 0) }))
	local circles = H.findAll(lead, function(c: any)
		return c.Name == "RippleCircle"
	end)
	assert(#circles == 2, "two ripples, got " .. #circles)
	for _ = 1, 20 do
		H.advance(1 / 60)
		assert(circles[1].Position == circles[2].Position and circles[1].Size == circles[2].Size, "the two discs coincide")
	end
	H.fire(lead, "InputEnded", H.input({}))
	H.advance(1)
	local midLayers = H.findAll(mid, function(c: any)
		return c.Name == "StateLayer"
	end)
	assert(#midLayers == 1 and midLayers[1].Parent == facesOf(mid)[1], "one face, one state layer")
	H.setAbs(midLayers[1], 182, 50, 64, 40)
	H.fire(mid, "InputBegan", H.input({ Position = Vector3.new(200, 62, 0) }))
	local midCircles = H.findAll(mid, function(c: any)
		return c.Name == "RippleCircle"
	end)
	assert(#midCircles == 1, "one face, one ripple, got " .. #midCircles)
	H.fire(mid, "InputEnded", H.input({}))
	H.advance(1)
	local function ok(u: UDim): boolean
		return u.Scale == 0 or u.Scale == 1
	end
	local function isDrawn(x: any): boolean
		return x.ClassName == "Frame" or x.ClassName == "TextButton" or x.ClassName == "ImageLabel" or x.ClassName == "TextLabel"
	end
	for _, c in H.findAll(g, isDrawn) do
		local p, z = c.Position or UDim2.new(), c.Size or UDim2.new()
		assert(ok(p.X) and ok(p.Y) and ok(z.X) and ok(z.Y), c.Name .. ": no partial Scale: " .. tostring(p) .. " " .. tostring(z))
	end
	q.dispose(g)
	H.assertNoDebugOutput("group ripple")
end)

H.section("host: Modifier renames / reorders, LayoutOrder, Hooks, theme (dark, per-component); two cells; dispose", function()
	local value = q.Source("a" :: string?)
	local hooked = 0
	local theme = Theme.new({ Scheme = "dark" })
	local g = ButtonGroup({
		Items = { { Key = "a", Label = "A" }, { Key = "b", Label = "B" } },
		Value = value,
		Theme = theme,
		LayoutOrder = 7,
		Modifier = D.Modifier.Frame():Name("ViewSwitch"),
		Hooks = { Util.preHook(function()
			hooked += 1
		end) },
	})
	H.finishTweens()
	assert(g.Name == "ViewSwitch" and g.LayoutOrder == 7 and hooked == 1, "the caller's Modifier wins the Name; Hooks ran once")
	local cells = cellsOf(g)
	assert(#cells == 2 and H.find(cells[1], "OuterClip") ~= nil and H.find(cells[2], "OuterClip") ~= nil, "two cells: a leading and a trailing one")
	assert(face(cells[1], "OuterClip").BackgroundColor3 == Dk.Primary and face(cells[2], "OuterClip").BackgroundColor3 == Dk.SurfaceContainer, "the component's theme")
	theme.Scheme:Set("light")
	H.finishTweens()
	assert(face(cells[1], "OuterClip").BackgroundColor3 == L.Primary and H.find(cells[2], "Label").TextColor3 == L.OnSurfaceVariant, "a scheme switch re-colors")
	local held = cells[1]
	q.dispose(g)
	assert(H.isDestroyed(held), "the cells die with the host")
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("group host")
end)

H.section("errors: Value xor Values, at least two items, unique string keys", function()
	local value = q.Source(nil :: string?)
	local values = q.Source({} :: { [string]: boolean })
	assert(not pcall(ButtonGroup, { Items = THREE, Value = value, Values = values }), "both forms")
	assert(not pcall(ButtonGroup, { Items = THREE }), "neither form")
	-- (typed locals: `pcall` gives a table literal no expected type)
	local one: { ButtonGroup.Item } = { { Key = "a", Label = "A" } }
	local twice: { ButtonGroup.Item } = { { Key = "a", Label = "A" }, { Key = "a", Label = "B" } }
	assert(not pcall(ButtonGroup, { Items = one, Value = value }), "one item is not a group")
	assert(not pcall(ButtonGroup, { Items = twice, Value = value }), "a Key used twice")
	local ok, message = pcall(ButtonGroup, { Items = THREE })
	assert(not ok and string.find(tostring(message), "Value %(single selection%) or Values %(multiple selection%)") ~= nil, "the message names both props: " .. tostring(message))
	H.resetOutput()
end)

H.done()
