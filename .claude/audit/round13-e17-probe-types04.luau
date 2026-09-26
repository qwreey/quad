--!strict
-- round13 E17 (d) — how-to 04 snippets verbatim (only the require paths and RemoteEvent/SomeSignal stand-ins changed).
-- mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" .claude/audit/round13-e17-probe-types04.luau
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- §2 state layer
local ProfileStore = q.Store({
	Gold = q.Source(0),
	Level = q.Source(1),
})
local ProfileUpdated = ReplicatedStorage:WaitForChild("ProfileUpdated") :: RemoteEvent
ProfileUpdated.OnClientEvent:Connect(function(newData)
	if newData.Gold ~= nil then
		ProfileStore.Gold:Set(newData.Gold)
	end
	if newData.Level ~= nil then
		ProfileStore.Level:Set(newData.Level)
	end
end)

-- §2 UI layer
local function withCommas(n: number): string
	local s = tostring(math.floor(n))
	local replaced = 1
	while replaced > 0 do
		s, replaced = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	end
	return s
end
local function GoldDisplay()
	local goldText: q.State<string> = ProfileStore.Gold:Compute(function(gold)
		return `보유 골드: {withCommas(gold:Get())} G`
	end)
	return D.TextLabel {
		Text = goldText,
		TextColor3 = Color3.fromRGB(255, 215, 0),
		FontFace = Font.fromEnum(Enum.Font.GothamBold),
	}
end

-- §3
local isInventoryOpen = q.Source(false)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Tab then
		isInventoryOpen:Set(not isInventoryOpen:Get())
	end
end)
local function InventoryModal()
	return D.Frame {
		Size = UDim2.fromOffset(500, 400),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Visible = isInventoryOpen,
		D.TextButton {
			Text = "X",
			MouseButton1Click = function()
				isInventoryOpen:Set(false)
			end,
		},
	}
end

-- §4
local function CrosshairOverlay()
	local mousePos = q.Source(Vector2.zero)
	local dotPosition: q.State<UDim2> = mousePos:Compute(function(pos)
		local p = pos:Get()
		return UDim2.fromOffset(p.X, p.Y)
	end)
	return D.Frame {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		q.Effect(function()
			local conn = UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					mousePos:Set(Vector2.new(input.Position.X, input.Position.Y))
				end
			end)
			return function()
				conn:Disconnect()
			end
		end),
		D.Frame {
			Size = UDim2.fromOffset(8, 8),
			Position = dotPosition,
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		},
	}
end

local SomeSignal = (Instance.new("BindableEvent")).Event
local function StatusPanel()
	local conn = SomeSignal:Connect(function(...) end)
	return D.Frame {
		q.OnDestroyed(function()
			conn:Disconnect()
		end),
	}
end

-- §4 last paragraph: Ref at a numeric seat
local function WithRef()
	local ref = q.Ref<<Frame?>>(nil)
	local f = D.Frame { ref }
	local _v: Frame? = ref.Value
	local bad = D.Frame { q.Ref(nil) } -- doc: rejected at the numeric seat (expect an error on this line)
	return f, bad
end

-- round trip (not in the doc): Store → Debounce → FireServer, TextBox Out
local SubmitName = ReplicatedStorage:WaitForChild("SubmitName") :: RemoteEvent
local function NameForm()
	local store = q.Store({ Name = q.Source("") })
	local valid = store.Name:Compute(function(s) return #s:Get() >= 3 end)
	local debounced: q.State<string> = store.Name:Apply(q.Debounce { Time = 0.3 })
	return D.Frame {
		debounced:Observer(function(t)
			if valid:Get() then
				SubmitName:FireServer(t:Get())
			end
		end),
		D.TextBox { Text = store.Name, q.Out("Text", store.Name) },
	}
end

return { GoldDisplay, InventoryModal, CrosshairOverlay, StatusPanel, WithRef, NameForm }
