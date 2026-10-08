--!strict
--[[
	Gallery — the kit's showcase: every component with live state, one section per group, a Tabs bar to switch.

		local Gallery = require("<kit>/gallery")
		Gallery.mount()                       -- a ScreenGui in LocalPlayer.PlayerGui: the panel + its OWN overlay layer
		Gallery.mount(someParent)             -- or into a given parent (the spec uses a Folder)
		Gallery.GalleryPanel(props?)          -- just the page (a Frame, size 100 % of its parent) to host yourself

	GalleryPanel props (all optional, all `read`):
	  Theme     Theme?                the Theme every demo gets (default `Theme.default`; the Theme tab's switch flips it)
	  Overlay   Overlay.Overlay?      the layer menus / dialogs / snackbars / tooltips open in. NOT given: the panel creates
	                                  its own `Overlay.new()` and seats the layer as its last child. `Gallery.mount` creates
	                                  one for its ScreenGui and passes it. The gallery never uses `Overlay.default()`:
	                                  it owns its layer, so the demo is independent of whatever the host app mounted as the
	                                  shared default (which self-heals but is the app's to mount, not the demo's).
	  Selected  Source<string>?       the tab key ("Buttons" | "Selection" | "Text" | "Surfaces" | "Overlays" | "Chips" |
	                                  "Pickers" | "Theme"); two-way, default "Buttons"
	  Icon      string?               image asset id used by the icon demos (the kit ships no art). The default is a
	                                  placeholder id that is NOT verified on a device — pass your own to see real icons
	  Modifier  FrameModifier?        applied to the root after the base style

	Layout: root Frame (Surface) > Tabs (48 px) + ScrollingFrame "Scroller" (AutomaticCanvasSize Y, below the tabs) >
	"Page" Frame (AutomaticSize Y) holding ONE section at a time.

	Lazy vs mounted (decision): sections are built when their tab is selected and destroyed when it is left
	(`Slot:Single`), not kept mounted and hidden. The Pickers section alone is several hundred instances (two 42-cell
	calendars + the color panel) and the indeterminate progress bars run a Heartbeat loop; hidden-but-mounted sections
	would pay both all the time. State the user typed or toggled lives in a per-panel Memo (`Common.Ctx.Memo`) of Sources,
	so it survives a section being rebuilt. Per-tab instance counts: see test/spec.gallery.luau output.

	`Gallery.mount` ScreenGui: `ResetOnSpawn = false` (a respawn does not rebuild the UI), `IgnoreGuiInset = false` (the
	tabs start BELOW the Roblox top bar instead of under its icons), `DisplayOrder = 10`, `ZIndexBehavior = Sibling`.

	Why it lives in `<kit>/gallery`, outside `src`: the gallery is a consumer of the kit, not part of it. Kept in `src` it
	would be published with the kit and sit on every consumer's install while no normal usage path loads it. Out here it
	uses the kit the way a game does — ONE root export table (`require("./src")`, the `Material.*` values and re-exported
	types) plus its own setup module for quad (`Quad.luau`) — so it also checks that the root table is enough to build a
	real screen. The Studio entry `MaterialGallery.client.luau` sits next to it (consumer-kits.project.json maps it into
	StarterPlayerScripts and keeps it out of the ReplicatedStorage copy).
]]

local q = require("@self/Quad")
local Material = require("./src")
local Common = require("@self/Common")
local Buttons = require("@self/Buttons")
local Selection = require("@self/Selection")
local TextInput = require("@self/TextInput")
local Surfaces = require("@self/Surfaces")
local Overlays = require("@self/Overlays")
local ChipsTabsProgress = require("@self/ChipsTabsProgress")
local Pickers = require("@self/Pickers")
local ThemeSection = require("@self/Theme")
local D = q.Declaration

export type Props = {
	read Theme: Material.Theme?,
	read Overlay: Material.OverlayType?,
	read Selected: q.Source<string>?,
	read Icon: string?,
	read Modifier: q.FrameModifier?,
}

local PLACEHOLDER_ICON = "rbxassetid://6031094678"

local TABS: { Material.Tab<string> } = {
	{ Key = "Buttons", Label = "Buttons" },
	{ Key = "Selection", Label = "Selection" },
	{ Key = "Text", Label = "Text" },
	{ Key = "Surfaces", Label = "Surfaces" },
	{ Key = "Overlays", Label = "Overlays" },
	{ Key = "Chips", Label = "Chips" },
	{ Key = "Pickers", Label = "Pickers" },
	{ Key = "Theme", Label = "Theme" },
}

local BUILDERS: { [string]: (ctx: Common.Ctx) -> Instance } = {
	Buttons = Buttons,
	Selection = Selection,
	Text = TextInput,
	Surfaces = Surfaces,
	Overlays = Overlays,
	Chips = ChipsTabsProgress,
	Pickers = Pickers,
	Theme = ThemeSection,
}

local tabsPosition = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, 48))

local Gallery = {}

function Gallery.GalleryPanel(props: Props?): Frame
	local p: Props = props or {}
	local theme = Material.Theme.resolve(p.Theme)
	local selected = p.Selected or q.Source("Buttons")
	local ownLayer: Frame? = nil
	local overlay = p.Overlay
	if overlay == nil then
		local own = Material.Overlay.new({ Theme = theme })
		overlay = own
		ownLayer = own.Layer
	end
	local bar = Material.Snackbar.new({ Overlay = overlay, Theme = theme })
	local ctx: Common.Ctx = {
		Theme = theme,
		Overlay = overlay :: Material.OverlayType,
		Snackbar = bar,
		Memo = Common.newMemo(),
		Icon = p.Icon or PLACEHOLDER_ICON,
	}

	local page = q.Slot<<Instance>>()
	page:Single<<string, nil>>(selected, function(c): (Instance?, nil)
		local build = BUILDERS[c.Item :: string]
		if build == nil then
			return nil, nil
		end
		return build(ctx), nil
	end)

	return D.Frame {
		Name = "Gallery",
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = theme.Color.Surface,
		p.Modifier or q.None,
		Material.Util.preHook(function(inst: GuiObject)
			inst.Destroying:Connect(function()
				bar:Destroy()
			end)
		end),
		Material.Tabs<<string>>({
			Theme = theme,
			Selected = selected,
			Tabs = TABS,
			Modifier = tabsPosition,
		}),
		D.ScrollingFrame {
			Name = "Scroller",
			Position = UDim2.fromOffset(0, 48),
			Size = UDim2.new(1, 0, 1, -48),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = theme.Color.OnSurface,
			ScrollBarImageTransparency = 1 - Material.Tokens.State.Opacity.ScrollBar,
			D.Frame {
				Name = "Page",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				page,
			},
		},
		ownLayer or q.None,
	}
end

-- A ScreenGui with the panel and its own overlay layer. Returns the ScreenGui.
function Gallery.mount(parent: Instance?): ScreenGui
	local overlay = Material.Overlay.new()
	local gui = D.ScreenGui {
		Name = "MaterialGallery",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Gallery.GalleryPanel({ Overlay = overlay }),
		overlay.Layer,
	}
	gui.Parent = parent or (game:GetService("Players").LocalPlayer :: any):WaitForChild("PlayerGui")
	return gui
end

return Gallery
