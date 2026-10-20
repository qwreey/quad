--!strict
--[[
	Demo — the kit's showcase (Iris: ShowDemoWindow), one window with a section per widget group plus two tool windows.

		local Demo = require("<kit>/gallery")
		Demo.mount()                              -- a ScreenGui in LocalPlayer.PlayerGui with all three windows + the popup layer
		Demo.mount(someParentGui)                 -- or into a given parent

		Demo.DemoWindow(props?)                   -- just the main window (you host it yourself; the Overlay it uses —
		                                             `props.Overlay`, else `Overlay.getDefault()` — must have its `.Layer` in
		                                             your ScreenGui for Combo / Menu / Tooltip popups)
		Demo.StyleEditorWindow({ Context = ... }) / Demo.RuntimeInfoWindow({ Context = ..., Target = ... })

	DemoWindow props (all optional): Style, Overlay, Open, StyleEditorOpen, RuntimeInfoOpen (the menu's "Windows" toggles
	write these two Sources — a host that owns those windows passes the same Sources), Position, Size, Manager, Context
	(gallery/Context.luau, the shared Sources the sections read).

	The sections are separate files (Basic / Inputs / Trees / Tables / Popups / Plots), each `function(ctx) -> Instance`.
	Heartbeat is touched by `Clock.ticker` only (plots, runtime info); a ticker is gated on its window's Open AND NOT Collapsed (no
	connection while the window is closed or collapsed; a closed Plots header keeps its sampler running) and disconnects with its element.

	Why it lives in `<kit>/gallery`, outside `src`: the demo is a consumer of the kit, not part of it. Kept in `src` it
	would be published with the kit and sit on every consumer's install while no normal usage path loads it. Out here it
	uses the kit the way a game does — ONE root export table (`require("./src")`, `Devui.*` values and re-exported
	types) plus its own setup module for quad (`Quad.luau`) — so it also checks that the root table is enough to build a
	real screen. The Studio entry `DevuiDemo.client.luau` sits next to it (consumer-kits.project.json maps it into
	StarterPlayerScripts and keeps it out of the ReplicatedStorage copy).
]]

local Devui = require("./src")
local Context = require("@self/Context")
local Basic = require("@self/Basic")
local Inputs = require("@self/Inputs")
local Trees = require("@self/Trees")
local Tables = require("@self/Tables")
local Popups = require("@self/Popups")
local Plots = require("@self/Plots")
local StyleEditorWindow = require("@self/StyleEditor")
local RuntimeInfoWindow = require("@self/RuntimeInfo")
local q = require("@self/Quad")

local ScreenGui = q.Elem "ScreenGui"
local Kids = Devui.Kids

export type DemoProps = {
	read Style: Devui.Style?,
	read Overlay: Devui.Overlay?,
	read Context: Context.Context?,
	read Open: q.Source<boolean>?,
	read StyleEditorOpen: q.Source<boolean>?,
	read RuntimeInfoOpen: q.Source<boolean>?,
	read Position: q.Source<UDim2>?,
	read Size: q.Source<Vector2>?,
	read Manager: Devui.Manager?,
}

local Demo = {}
Demo.StyleEditorWindow = StyleEditorWindow
Demo.RuntimeInfoWindow = RuntimeInfoWindow
Demo.Context = Context

function Demo.DemoWindow(props: DemoProps?): Frame
	local p: DemoProps = props or {}
	local ctx = p.Context or Context.new(p.Style, p.Overlay)
	local style = ctx.Style
	local styleEditorOpen = p.StyleEditorOpen or q.Source(false)
	local runtimeOpen = p.RuntimeInfoOpen or q.Source(false)

	local open: q.Source<boolean> = p.Open or q.Source(true)
	local collapsed: q.Source<boolean> = q.Source(false)
	-- the plot sampler runs only while the window is open AND not collapsed (a collapsed window shows no plots)
	local active: q.State<boolean> = open:Compute(function(self, _prev, isCollapsed)
		return self:Get() and not isCollapsed:Get()
	end, collapsed)
	-- the scheme / density menu toggles are CONTROLLED: they show a Compute of the Style's own Sources and report the
	-- click, the demo writes it back (no bridge Effects, nothing to settle)
	local isLight: q.State<boolean> = style.Scheme:Compute(function(self)
		return self:Get() == "Light"
	end)
	local isClear: q.State<boolean> = style.Density:Compute(function(self)
		return self:Get() == "Clear"
	end)

	local menu = Devui.MenuBar({
		Style = style,
		Children = Kids(
			Devui.Menu({
				Text = "Style",
				Overlay = ctx.Overlay,
				Style = style,
				Children = function(scope)
					return Kids(
						Devui.MenuToggle({
							Text = "Light scheme",
							Checked = isLight,
							OnToggle = function(on: boolean)
								style:SetScheme(if on then "Light" else "Dark")
							end,
							Scope = scope,
							Style = style,
						}),
						Devui.MenuToggle({
							Text = "Clear density",
							Checked = isClear,
							OnToggle = function(on: boolean)
								style:SetDensity(if on then "Clear" else "Default")
							end,
							Scope = scope,
							Style = style,
						})
					)
				end,
			}),
			Devui.Menu({
				Text = "Windows",
				Overlay = ctx.Overlay,
				Style = style,
				Children = function(scope)
					return Kids(
						Devui.MenuToggle({ Text = "Style Editor", Value = styleEditorOpen, Scope = scope, Style = style }),
						Devui.MenuToggle({ Text = "Runtime Info", Value = runtimeOpen, Scope = scope, Style = style })
					)
				end,
			})
		),
	})

	return Devui.Window({
		Title = "quad devui — Demo",
		Style = style,
		Open = open,
		Collapsed = collapsed,
		Position = p.Position or q.Source(UDim2.fromOffset(40, 40)),
		Size = p.Size or q.Source(Vector2.new(460, 560)),
		Manager = p.Manager,
		Children = Kids(
			menu,
			Devui.TextWrapped({
				Text = "A retained, reactive take on Iris: every widget is bound to a Source; nothing runs per frame except the plot sampler.",
				Style = style,
			}),
			Basic(ctx),
			Inputs(ctx),
			Trees(ctx),
			Tables(ctx),
			Popups(ctx),
			Plots(ctx, active)
		),
	})
end

-- A ScreenGui holding the demo window, the two tool windows and the popup layer. Returns the ScreenGui.
function Demo.mount(parent: Instance?): ScreenGui
	local ctx = Context.new(nil, Devui.Overlay.new())
	local styleEditorOpen = q.Source(false)
	local runtimeOpen = q.Source(false)
	local manager = Devui.WindowManager.new()
	local gui: ScreenGui
	gui = ScreenGui({
		Name = "QuadDevuiDemo",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Demo.DemoWindow({
			Context = ctx,
			StyleEditorOpen = styleEditorOpen,
			RuntimeInfoOpen = runtimeOpen,
			Manager = manager,
		}),
		StyleEditorWindow({ Context = ctx, Open = styleEditorOpen, Manager = manager }),
		RuntimeInfoWindow({
			Context = ctx,
			Open = runtimeOpen,
			Manager = manager,
			Target = function(): Instance?
				return gui
			end,
		}),
		ctx.Overlay.Layer,
	})
	gui.Parent = parent or (game:GetService("Players").LocalPlayer :: any):WaitForChild("PlayerGui")
	return gui
end

return Demo
