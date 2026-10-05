--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Tree = require("../src/Tree")
local Text = require("../src/Text")
local Layout = require("../src/Layout")
local Style = require("../src/Style")
local Kids = Layout.Kids

local UIS = H.UserInputService
local function conns(): number
	return #(UIS.InputChanged :: any).connections + #(UIS.InputEnded :: any).connections + #(UIS.WindowFocusReleased :: any).connections
end
local function get(root: Instance, name: string): any
	local found = H.find(root, name)
	assert(found ~= nil, `missing {name}`)
	return found
end
local style = Style.default

H.section("Tree: closed by default, header click toggles, children stay mounted", function()
	local base = conns()
	local tree = Tree.Tree({ Text = "Node", Children = Kids(Text.Text({ Text = "leaf" })) })
	local header, children, arrow = get(tree, "Header"), get(tree, "Children"), get(tree, "Arrow")
	assert(header.Text == "Node" and header.ClassName == "TextButton")
	assert(children.Visible == false, "closed: children hidden")
	assert(children.Parent == tree and #children:GetChildren() >= 1, "closed children stay mounted")
	assert(arrow.Image == style.Icons.RightTriangle)
	local count = H.countDescendants(tree)

	H.fire(header, "Activated", H.input({}), 1)
	assert(children.Visible == true and arrow.Image == style.Icons.DownTriangle)
	H.fire(header, "Activated", H.input({}), 1)
	assert(children.Visible == false and arrow.Image == style.Icons.RightTriangle)
	assert(H.countDescendants(tree) == count, "toggling creates/destroys nothing")
	-- Tree header: Header(1) + Arrow(1) + helpers; root: list + header + children frame(+pad+list+text)
	assert(count == 10, `unexpected instance count {count}`)

	q.dispose(tree)
	assert(H.isDestroyed(tree) and conns() == base)
	H.assertNoDebugOutput("tree toggle")
end)

H.section("Tree: Open Source round trip (external -> UI -> click -> Source)", function()
	local open = q.Source(true)
	local tree = Tree.Tree({ Text = q.Source("A"), Open = open, Children = Kids(Text.Text({ Text = "x" })) })
	local children = get(tree, "Children")
	assert(children.Visible == true, "starts from the Source")
	open:Set(false)
	assert(children.Visible == false)
	H.fire(get(tree, "Header"), "Activated", H.input({}), 1)
	assert(open:Get() == true and children.Visible == true, "click writes back")
	q.dispose(tree)
	H.assertNoDebugOutput("tree open")
end)

H.section("Tree: hover highlight (transparent until hovered), Span / NoIndent flags", function()
	local tree = Tree.Tree({ Text = "n", Children = Kids(Text.Text({ Text = "x" })) })
	local header = get(tree, "Header")
	assert(header.BackgroundTransparency == 1)
	assert(header.AutomaticSize == Enum.AutomaticSize.XY, "default header shrinks to its text")
	H.fire(header, "MouseEnter", 1, 1)
	assert(header.BackgroundTransparency == style.Transparency.HeaderHovered:Get())
	H.fire(header, "MouseLeave")
	assert(header.BackgroundTransparency == 1)
	local indentPad = get(get(tree, "Children"), "UIPadding")
	assert(indentPad.PaddingLeft == UDim.new(0, style.Metrics.IndentSpacing:Get()), "children indented")
	q.dispose(tree)

	local span = Tree.Tree({ Text = "n", SpanAvailWidth = true, NoIndent = true, Children = Kids(Text.Text({ Text = "x" })) })
	assert(get(span, "Header").AutomaticSize == Enum.AutomaticSize.Y and get(span, "Header").Size == UDim2.new(1, 0, 0, 0))
	assert(get(get(span, "Children"), "UIPadding").PaddingLeft == UDim.new(0, 0), "NoIndent")
	q.dispose(span)

	-- a Tree without children is just a header row
	local leaf = Tree.Tree({ Text = "leaf" })
	assert(H.find(leaf, "Children") == nil)
	q.dispose(leaf)
	H.assertNoDebugOutput("tree hover")
end)

H.section("CollapsingHeader: always painted, spans the width, children not indented", function()
	local open = q.Source(false)
	local ch = Tree.CollapsingHeader({ Text = "Section", Open = open, Children = Kids(Text.Text({ Text = "body" })) })
	local header = get(ch, "Header")
	assert(ch.Name == "CollapsingHeader")
	assert(header.BackgroundTransparency == style.Transparency.Header:Get(), "always the Header look")
	assert(header.Size == UDim2.new(1, 0, 0, 0))
	assert(get(get(ch, "Children"), "UIPadding").PaddingLeft == UDim.new(0, 0))
	H.fire(header, "MouseEnter", 1, 1)
	assert(header.BackgroundTransparency == style.Transparency.HeaderHovered:Get())
	H.fire(header, "Activated", H.input({}), 1)
	assert(open:Get() == true and get(ch, "Children").Visible == true)
	-- scheme switch repaints
	style:SetScheme("Light")
	assert(header.BackgroundColor3 == style.Color.HeaderHovered:Get())
	style:SetScheme("Dark")
	q.dispose(ch)
	H.assertNoDebugOutput("collapsing header")
end)

H.section("OnChange reports a user toggle, not an outside :Set", function()
	local open = q.Source(false)
	local log: { boolean } = {}
	local tree = Tree.Tree({ Text = "n", Open = open, Children = Kids(Text.Text({ Text = "leaf" })), OnChange = function(o: boolean)
		table.insert(log, o)
	end })
	H.fire(get(tree, "Header"), "Activated", H.input({}), 1)
	open:Set(false)
	H.fire(get(tree, "Header"), "Activated", H.input({}), 1)
	assert(#log == 2 and log[1] == true and log[2] == true, "two user toggles, the outside write is silent")
	q.dispose(tree)
	local seen = 0
	local ch = Tree.CollapsingHeader({ Text = "c", OnChange = function()
		seen += 1
	end })
	H.fire(get(ch, "Header"), "Activated", H.input({}), 1)
	assert(seen == 1)
	q.dispose(ch)
	H.assertNoDebugOutput("tree onchange")
end)


H.done()
