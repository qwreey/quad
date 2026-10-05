--!strict
--[[
	Gallery section "Overlays": the triggers for everything that floats — Dialog (alert / confirm / custom actions),
	Snackbar (plain / action / persistent with a close button / several queued), Menu (a Menu.Button and one with
	icons, a disabled item and a divider) and Tooltip (a hook per target; Tooltip.Plain for the static look).
	Everything opens through `ctx.Overlay`, the overlay the panel owns — nothing here touches `Overlay.default()`.
	The last dialog result and the last snackbar dismiss reason are written to Memo Sources and shown below.
]]

local q = require("../Quad")
local Common = require("./Common")
local Button = require("../Button")
local Dialog = require("../Dialog")
local Menu = require("../Menu")
local Tooltip = require("../Tooltip")

type Ctx = Common.Ctx

return function(ctx: Ctx): Instance
	local theme = ctx.Theme
	local overlay = ctx.Overlay
	local lastDialog = ctx.Memo("ov.dialog", function()
		return q.Source("(none yet)")
	end)
	local lastSnack = ctx.Memo("ov.snack", function()
		return q.Source("(none yet)")
	end)
	local lastMenu = ctx.Memo("ov.menu", function()
		return q.Source("(none yet)")
	end)
	local snackCount = ctx.Memo("ov.count", function()
		return { value = 0 }
	end)

	local function say(target: q.Source<string>, text: string): () -> ()
		return function()
			target:Set(text)
		end
	end

	local dialogs: { Instance } = {
		Button({
			Theme = theme,
			Label = "Alert",
			OnClick = function()
				Dialog.alert({ Headline = "Saved", Body = "Your changes were saved.", Overlay = overlay, Theme = theme })
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "Confirm",
			OnClick = function()
				Dialog.confirm({
					Headline = "Delete the draft?",
					Body = "This cannot be undone.",
					Overlay = overlay,
					Theme = theme,
					OnClose = function(ok: any?)
						lastDialog:Set(if ok == true then "confirmed" elseif ok == false then "cancelled" else "dismissed")
					end,
				})
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Outlined",
			Label = "Custom actions",
			OnClick = function()
				Dialog.open({
					Icon = ctx.Icon,
					Headline = "Discard changes?",
					Body = "Three actions, the last one disabled.",
					Overlay = overlay,
					Theme = theme,
					Actions = {
						{ Label = "Keep", Result = "keep" },
						{ Label = "Discard", Result = "discard", Variant = "Filled" },
						{ Label = "Later", Result = "later", Disabled = true },
					},
					DismissResult = "dismissed",
					OnClose = function(result: any?)
						lastDialog:Set(tostring(result))
					end,
				})
			end,
		}),
		Common.Caption(ctx, lastDialog:Compute(function(self)
			return `Last dialog result: {self:Get()}`
		end), false),
	}

	local bar = ctx.Snackbar
	local snacks: { Instance } = {
		Button({
			Theme = theme,
			Label = "Show",
			OnClick = function()
				bar:Show({
					Text = "Message archived",
					OnDismiss = function(reason)
						lastSnack:Set(reason)
					end,
				})
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "With action",
			OnClick = function()
				bar:Show({
					Text = "Conversation deleted",
					Action = { Label = "Undo", OnClick = say(lastSnack, "undo pressed") },
					OnDismiss = function(reason)
						if reason ~= "Action" then
							lastSnack:Set(reason)
						end
					end,
				})
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Outlined",
			Label = "Persistent + close",
			OnClick = function()
				bar:Show({
					Text = "Connection lost. Retrying keeps this message until you close it.",
					Close = true,
					Duration = math.huge,
					OnDismiss = function(reason)
						lastSnack:Set(reason)
					end,
				})
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Text",
			Label = "Queue three",
			OnClick = function()
				for _ = 1, 3 do
					snackCount.value += 1
					bar:Show({ Text = `Queued message {snackCount.value}`, Duration = 2 })
				end
			end,
		}),
		Common.Caption(ctx, lastSnack:Compute(function(self)
			return `Last snackbar: {self:Get()}`
		end), false),
	}

	local menus: { Instance } = {
		Menu.Button({
			Theme = theme,
			Overlay = overlay,
			Label = "Actions",
			Items = {
				{ Label = "Rename", OnClick = say(lastMenu, "rename") },
				{ Label = "Duplicate", Trailing = "Ctrl+D", OnClick = say(lastMenu, "duplicate") },
				"divider",
				{ Label = "Delete", OnClick = say(lastMenu, "delete") },
			},
		}),
		Menu.Button({
			Theme = theme,
			Overlay = overlay,
			Variant = "Outlined",
			Label = "With icons",
			Items = {
				{ Label = "Open", Leading = ctx.Icon, OnClick = say(lastMenu, "open") },
				{ Label = "Share", Leading = ctx.Icon, Selected = true, OnClick = say(lastMenu, "share") },
				{ Label = "Locked", Leading = ctx.Icon, Disabled = true },
			},
		}),
		Common.Caption(ctx, lastMenu:Compute(function(self)
			return `Last menu item: {self:Get()}`
		end), false),
	}

	local function tipped(label: string, text: string): Instance
		local tip = Tooltip.hook({ Text = text, Overlay = overlay, Theme = theme })
		return Button({ Theme = theme, Variant = "Tonal", Label = label, Hooks = { tip.Hook } })
	end
	local tooltips: { Instance } = {
		tipped("Hover me", "A plain tooltip"),
		tipped("Or focus me", "Gamepad and keyboard selection show it too"),
		Tooltip.Plain({ Theme = theme, Text = "Tooltip.Plain, the bare visual" }),
	}

	return Common.Section(ctx, "Overlays", "Overlays", {
		Common.Group(ctx, "Dialog", dialogs, "A scrim, a 28 px surface that fades and scales in; Escape and the scrim dismiss."),
		Common.Group(ctx, "Snackbar", snacks, "One at a time; the rest wait in the queue."),
		Common.Group(ctx, "Menu", menus),
		Common.Group(ctx, "Tooltip", tooltips),
	})
end
