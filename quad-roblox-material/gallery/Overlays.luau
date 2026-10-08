--!strict
--[[
	Gallery section "Overlays": the triggers for everything that floats — Dialog (alert / confirm / custom actions),
	Snackbar (plain / action / persistent with a close button / several queued), Menu (a Menu.Button and one with
	icons, a disabled item and a divider) and Tooltip (a hook per target; Tooltip.Plain for the static look) — and the
	sheets: the modal bottom / side sheets (buttons) and the standard ones docked in mock screens (`Common.Screen`, which
	clips like a phone screen; the standard sheets are layout pieces, not overlay entries).
	Everything opens through `ctx.Overlay`, the overlay the panel owns — nothing here touches `Overlay.default()`.
	The last dialog result and the last snackbar dismiss reason are written to Memo Sources and shown below.
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")
local D = q.Declaration

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
		Material.Button({
			Theme = theme,
			Label = "Alert",
			OnClick = function()
				Material.Dialog.alert({ Headline = "Saved", Body = "Your changes were saved.", Overlay = overlay, Theme = theme })
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "Confirm",
			OnClick = function()
				Material.Dialog.confirm({
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
		Material.Button({
			Theme = theme,
			Variant = "Outlined",
			Label = "Custom actions",
			OnClick = function()
				Material.Dialog.open({
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
		Material.Button({
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
		Material.Button({
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
		Material.Button({
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
		Material.Button({
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
		Material.Menu.Button({
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
		Material.Menu.Button({
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
		local tip = Material.Tooltip.hook({ Text = text, Overlay = overlay, Theme = theme })
		return Material.Button({ Theme = theme, Variant = "Tonal", Label = label, Hooks = { tip.Hook } })
	end
	local tooltips: { Instance } = {
		tipped("Hover me", "A plain tooltip"),
		tipped("Or focus me", "Gamepad and keyboard selection show it too"),
		Material.Tooltip.Plain({ Theme = theme, Text = "Tooltip.Plain, the bare visual" }),
	}

	-- sheets
	local lastSheet = ctx.Memo("ov.sheet", function()
		return q.Source("(none yet)")
	end)
	local function sheetRows(count: number, onPick: (string) -> ()): q.Slot<Instance>
		local rows: { Instance } = {}
		for i = 1, count do
			local label = `Option {i}`
			table.insert(
				rows,
				Material.ListItem({
					Theme = theme,
					Headline = label,
					Supporting = if i == 1 then "Picks it and closes the sheet" else nil,
					LayoutOrder = i,
					OnClick = function()
						onPick(label)
					end,
				})
			)
		end
		return q.Slot<<Instance>>(rows)
	end
	local function openBottom(count: number)
		local handle: Material.ModalBottomSheetHandle
		handle = Material.ModalBottomSheet.open({
			Overlay = overlay,
			Theme = theme,
			Children = sheetRows(count, function(label: string)
				lastSheet:Set(label)
				handle.Close(label)
			end),
			OnClose = function(result: unknown?)
				if result == nil then
					lastSheet:Set("dismissed")
				end
			end,
		})
	end
	local bottomState = Material.SheetState({ InitialValue = "PartiallyExpanded", EnabledValues = { "PartiallyExpanded", "Expanded" } })
	local bottomSheets: { Instance } = {
		Material.Button({
			Theme = theme,
			Label = "Modal bottom sheet",
			OnClick = function()
				openBottom(3)
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "Tall (half, then drag up)",
			OnClick = function()
				openBottom(14)
			end,
		}),
		Common.Caption(ctx, lastSheet:Compute(function(self)
			return `Last sheet pick: {self:Get()}`
		end), false),
		Common.Screen(ctx, "BottomSheetScreen", 360, 420, {
			Material.BottomSheetScaffold({
				Theme = theme,
				SheetState = bottomState,
				Content = q.Slot<<Instance>>({
					Common.Caption(ctx, Common.text<<Material.SheetValue>>(bottomState.CurrentValue, function(v: Material.SheetValue): string
						return `Standard bottom sheet (BottomSheetScaffold) — {v}. Drag the sheet or tap its handle.`
					end)),
				}),
				SheetContent = sheetRows(4, function(label: string)
					lastSheet:Set(label .. " (standard)")
				end),
			}),
		}),
	}

	local sideState = Material.SheetState({ InitialValue = "Expanded", EnabledValues = { "Hidden", "Expanded" } })
	local sideSheets: { Instance } = {
		Material.Button({
			Theme = theme,
			Label = "Modal side sheet",
			OnClick = function()
				Material.ModalSideSheet.open({
					Overlay = overlay,
					Theme = theme,
					Headline = "Filters",
					Children = q.Slot<<Instance>>({
						Common.Labeled(ctx, Material.Checkbox({ Theme = theme, Value = q.Source(true) }), "Unread only"),
						Common.Labeled(ctx, Material.Checkbox({ Theme = theme, Value = q.Source(false) }), "With attachments"),
					}),
				})
			end,
		}),
		Common.Screen(ctx, "SideSheetScreen", 520, 300, {
			Material.Button({
				Theme = theme,
				Variant = "Outlined",
				Label = "Toggle side sheet",
				Modifier = D.Modifier.TextButton():Position(UDim2.fromOffset(16, 16)),
				OnClick = function()
					if sideState.TargetValue:Get() == "Hidden" then
						sideState.Expand()
					else
						sideState.Hide()
					end
				end,
			}),
			Material.SideSheet({
				Theme = theme,
				SheetState = sideState,
				Headline = "Details",
				Children = q.Slot<<Instance>>({
					Common.Caption(ctx, "A standard side sheet (MDC SideSheetBehavior): beside the content, no scrim. Drag it right to hide."),
				}),
			}),
		}),
	}

	return Common.Section(ctx, "Overlays", "Overlays", {
		Common.Group(ctx, "Dialog", dialogs, "A scrim, a 28 px surface that fades and scales in; Escape and the scrim dismiss."),
		Common.Group(ctx, "Snackbar", snacks, "One at a time; the rest wait in the queue."),
		Common.Group(ctx, "Menu", menus),
		Common.Group(ctx, "Tooltip", tooltips),
		Common.Group(ctx, "Bottom sheet", bottomSheets, "Modal: a scrim, rises from the bottom; drag it, tap the scrim or press Escape / B (an expanded sheet steps down to half first)."),
		Common.Group(ctx, "Side sheet", sideSheets, "Modal: slides in from the right over a scrim, 256 px wide, inner corners 16."),
	})
end
