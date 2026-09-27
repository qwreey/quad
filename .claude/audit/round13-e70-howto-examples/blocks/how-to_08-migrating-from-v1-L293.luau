-- v1: [Event "Activated"] = function(self, ...) end  — self는 오지 않는다
-- v1: self "_button" 링커  → PreRef
local buttonRef = q.PreRef<<TextButton?>>(nil)
local pressed = q.Source(0)

local button = D.TextButton {
	buttonRef,
	Text = "누르기",

	-- Frame에는 Activated가 없다: GuiButton 계열을 쓴다
	Activated = function(_input: InputObject, _clickCount: number)
		pressed:Set(pressed:Get() + 1)
		buttonRef:Unwrap().BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end,

	-- v1: [Event.Prop "Text"] = fn
	q.OnChange("Text", function(newText: string)
		print(newText)
	end),

	-- v1: Event.Created / AfterRender / Extend의 :Unload
	q.OnCreated<<TextButton>>(function(inst)
		inst.AutoButtonColor = false
	end),
	q.OnRendered<<TextButton>>(function(inst)
		print(inst.Name)
	end),
	q.OnDestroyed(function()
		print("bye")
	end),
}
