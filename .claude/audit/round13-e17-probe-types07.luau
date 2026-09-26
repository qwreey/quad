--!strict
-- round13 E17 (d) — how-to 07 snippets verbatim (require paths changed; Templates folder shape assumed).
-- mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" .claude/audit/round13-e17-probe-types07.luau
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local M = D.Mapper
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- §1
local function s1()
	local template = script.Parent:WaitForChild("ItemCard")
	local clicks = q.Source(0)
	local clickText: q.State<string> = clicks:Compute(function(c)
		return `클릭 횟수: {c:Get()}`
	end)
	q.Claim(template, M.Frame(M.Root)({
		M.TextLabel("ItemName")({ Text = "검" }),
		M.ImageLabel("ItemIcon")({ Image = "rbxassetid://1" }),
		M.TextButton("ActionButton")({
			Text = clickText,
			Activated = function()
				clicks:Set(clicks:Get() + 1)
			end,
		}),
		Visible = true,
	}))
end

-- §2
local ItemTemplate = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ItemCard")
local function ItemCard(item: { id: string, label: string }, label: q.Source<string>)
	local card = ItemTemplate:Clone()
	return q.Claim(card, M.Frame(M.Root)({
		M.TextLabel("ItemName")({ Text = label }),
		M.ImageLabel("ItemIcon")({ Image = "rbxassetid://2" }),
		M.TextButton("ActionButton")({
			Text = "사용",
			Activated = function()
				print("Selected:", item.id)
			end,
		}),
	}))
end
local itemsState = q.Source({ { id = "sword", label = "검" }, { id = "shield", label = "방패" } })
local rows = q.Slot<<Instance>>():List(itemsState, function(ctx: any): (any, any)
	local item, prev, ud = ctx.Item, ctx.Prev, ctx.UserData
	if item == q.KeyGone then
		return nil, ud
	end
	if prev then
		ud.label:Set(item.label)
		return prev, ud
	end
	local label = q.Source(item.label)
	return ItemCard(item, label), { label = label }
end, function(item)
	return item.id
end)

-- §2 code template
local ItemTemplate2 = D.Frame {
	Name = "ItemCard",
	Size = UDim2.fromOffset(240, 64),
	BackgroundColor3 = Color3.fromRGB(35, 35, 42),
	BorderSizePixel = 0,
	UICorner = UDim.new(0, 8),
	D.TextLabel { Name = "ItemName", Text = "-", TextSize = 14 },
	D.TextButton { Name = "ActionButton", Text = "사용" },
}
local function ItemCard2(item: { id: string, label: string }, label: q.Source<string>)
	local card = ItemTemplate2:Clone()
	return q.Claim(card, M.Frame(M.Root)({
		M.TextLabel("ItemName")({ Text = label }),
		M.TextButton("ActionButton")({
			Activated = function()
				print("Selected:", item.id)
			end,
		}),
	}))
end

-- §3 3)
local function s3(existingScreenGui: ScreenGui, player: Player)
	local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({ rows }))
	screen.Parent = player:WaitForChild("PlayerGui")
end

-- §4
local function ShopWindow(isOpen: q.Source<boolean>, rows2: q.Slot<Instance>)
	local window = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("ShopWindow"):Clone()
	q.Claim(window, M.Frame(M.Root)({
		M.TextButton("CloseButton")({
			Activated = function()
				isOpen:Set(false)
			end,
		}),
		M.TextLabel("TitleText")({}),
		M.Frame("ContentArea")({ rows2 }),
		Visible = isOpen,
	}))
	return window
end

-- combined: hooks / Out / Context / Animate inside a claimed tree
local Theme = q.Context.Provider<<{ Accent: Color3 }>>("Theme")
local function Hud(ctx: q.Context, gold: q.Source<number>, name: q.Source<string>)
	local theme = ctx:Get(Theme)
	local ratio: q.State<number> = gold:Compute(function(g) return math.clamp(g:Get() / 100, 0, 1) end)
	local animated: q.State<number> = ratio:Apply(q.Animate({ Time = 0.5 }))
	local tree = ReplicatedStorage:WaitForChild("Hud"):Clone()
	return q.Claim(tree, M.Frame(M.Root)({
		M.TextLabel("Gold")({ TextColor3 = theme.Accent }),
		M.Frame("Bar")({ BackgroundTransparency = animated }),
		M.TextBox("NameBox")({ Text = name, q.Out("Text", name) }),
		q.OnCreated(function(inst) print(inst) end),
		q.OnRendered<<Frame>>(function(inst) print(inst.AbsoluteSize) end),
		q.OnDestroyed(function() end),
	}))
end

return { s1, rows, ItemCard2, s3, ShopWindow, Hud }
