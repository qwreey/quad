--!strict
--[[
	quad devui — a developer/debug UI kit in quad's reactive, retained-mode idiom (the widget SET of Iris / Dear ImGui,
	not its immediate-mode API). Look: Dear ImGui dark style — compact text, flat frames, blue accents (Style tokens).

	READ FIRST FOR APP CODE: this header covers the kit only. quad's own idioms — module-level subscriptions
	(`:Subscribe()`), echo-free write-back (`q.Out`), `q.Debounce`/`q.Throttle`, `q.OnDestroyed` and Effect cleanup,
	`q.OnChange`, Slot rules — are in the quad repo's `docs/skills/quad-ui-dev/SKILL.md` and `docs/how-to/`
	(README "앱 코드를 짤 때 먼저 볼 것" lists them by need).

	QUICK START
		local Devui = require("<path to this folder>")
		local q = require("<path>/Quad")                    -- the kit's setup module (installs the Roblox provider)
		local Kids = Devui.Kids                              -- Kids(a, b) = q.Slot({ a, b })

		local overlay = Devui.Overlay.new()                  -- one popup layer per ScreenGui (see "OVERLAY" below)
		local open = q.Source(true)
		local screen = q.Elem "ScreenGui" {
			ResetOnSpawn = false,                            -- the layer is a quad-made instance: no respawn rebuilds
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,    -- REQUIRED: a code-made ScreenGui is Global, and windows /
			                                                 -- popups are layered by sibling ZIndex (Window/Manager)
			Devui.Window {
				Title = "Debug", Open = open,
				Children = Kids(
					Devui.Text { Text = "hello" },
					Devui.SameLine { Children = Kids(
						Devui.Button { Text = "Go", OnClick = function() print("go") end,
							Hooks = { Devui.Tooltip({ Text = "Runs it", Overlay = overlay }).Hook } },
						Devui.SmallButton { Text = "x" }
					) }
				),
			},
			overlay.Layer,                                   -- popups (Combo/Menu/Tooltip) are drawn here
		}
		-- widgets that open popups take `Overlay = overlay`; without it they use Devui.Overlay.getDefault(), whose
		-- `.Layer` you must then put in the ONE ScreenGui that shows it (two live ScreenGuis cannot both hold the default
		-- layer — Quad0160; a fresh default is made when the old layer died)
		Devui.Style.default:SetScheme("Light")               -- repaints everything live

	OVERLAY. `Overlay.new()` per ScreenGui is the explicit form; `Overlay.getDefault()` is the shared lazy one (created on
	first use, recreated after its layer was destroyed — never a dead layer; its Layer belongs in ONE ScreenGui). There is no `Overlay.default` value.

	NAMING (kit-wide, Iris convention): the TRAILING LABEL of an input / combo / checkbox-like widget is the `Text` prop
	(`InputNum { Text = "speed", Value = ... }`). `Value` is the Source the widget reads and writes, `Option` is what a
	choice widget selects (RadioButton / SelectableOption: `Value: Source<T>` + `Option: T`), `OnChange` reports a USER
	change, `Disabled` greys a widget out, `Hooks` is the escape hatch for hooks a leaf widget has no prop for.

	HOW TO WRITE A DEVUI WIDGET (follow this so the kit stays uniform)
	1. A widget is a plain function `Widget(props: WidgetProps): Frame | TextButton | ...` returning ONE instance
	   (or a Slot when it produces siblings). Props type: `read` fields, optional ones `?`. A bad prop raises with
	   `Util.fail("Widget", "what is wrong")` — never `error(msg, n)`; exports are tagged below, a method of a built
	   object is tagged by its constructor (`Util.tagSurface(obj)`).
	2. Standard props, in this order of appearance in the type: the widget's own data (`Text`, `Value`, ...), callbacks
	   (`OnClick`, `OnChange` — plain functions, called from engine events), then `Style: Style?` and
	   `Modifier: ModifierInto<Class>?` (`Quad.ModifierInto<Frame>` etc. — the generic re-exports in `src/Quad.luau`;
	   an inner element's slot is `FieldModifier`/`TrackModifier` beside `FieldSpread`/`TrackSpread: SpreadInto<Class>?`).
	   The host's `Name` lives in a module-level base Modifier (`local fooName = q.Modifier "Frame" ():Name("Foo")`), first in the
	   array part and BEFORE `props.Modifier` (later wins) — never `Name = "Foo"` inline on the host: an inline key always beats
	   a Modifier, so the caller's `q.Modifier "Frame" ():Name("X")` could not rename it. Inner children keep inline names; a
	   name that is an argument (Choice, Tree, NumberField) goes through a small per-name Modifier cache.
	   Display values that can change take `T | State<T>`. Values a widget WRITES BACK are `Source<T>` props (e.g.
	   Window `Open`/`Position`): the widget creates an internal Source when the caller passes none, so it works both
	   controlled and uncontrolled. Write back with `:Set`/`:SetIfChanged` from event handlers, never from a Compute.
	3. Styling: `local style = props.Style or Style.default`, then bind tokens directly as props
	   (`BackgroundColor3 = style.Color.Button`, `TextSize = style.Metrics.TextSize`). Never hard-code a colour/size.
	   Hover/active looks: `Style.interactive(style, "Button", hover.Hovered, hover.Pressed)` (uses Name / NameHovered /
	   NameActive tokens). Padding/spacing tokens are Vector2 States: turn them into UDim States with Util.pxX/pxY.
	4. Interaction: `local hover = Interaction.hover()` / `Interaction.drag{...}` / `Interaction.pointerDown(fn)` return a
	   handle whose `Hook` goes in the ARRAY PART of the element (`hover.Hook,`). One handle per element. Global
	   connections (drag tracking) are opened only while dragging and closed on release, focus loss and destroy — never
	   open your own `UserInputService` connection at construction (and always reach the service via `Input.service()`).
	5. Popups (Combo list, Menu, Tooltip): `local popup = (props.Overlay or Overlay.getDefault()):Open{ Content = ..., Position
	   = absoluteScreenPos, Anchor = ..., CloseOnClickOutside = true }` (resolve the overlay when the popup OPENS, and bail
	   when `not overlay.Alive:Get()`); close with `popup:Close()` (idempotent; the overlay also closes every open popup
	   when its layer dies, so put cleanup in `OnClose`). The overlay owns the Content element: build a fresh one per open.
	6. Children: containers take `Children: Slot<Instance>?` and place it in the array part: `props.Children or q.None`.
	   Every optional array-part entry ends in `or q.None` (a nil hole breaks the drive).
	7. Layout: children flow top-down in a UIListLayout (the Window content, Group, Indent); rows use Layout.SameLine.
	   Containers use AutomaticSize Y with full width; leaf widgets size themselves (AutomaticSize XY + padding tokens).
	8. Instance budget: one GuiObject per visual part (+ UICorner / UIStroke / UIPadding helpers), no decorative frames.
	9. Reactive rules: a Compute only reads (annotate the result: `local s: State<X> = src:Compute(...)`), Observers are
	   final consumers, engine -> state write-back goes through `q.Out` / `q.OnChange` or Interaction callbacks.
	10. Tests: `test/spec.<widget>.luau` under Lune (test/support/harness.luau) — mount, interact (`H.fire`, `H.input`),
	   state round trip, `q.dispose(root)`, connection counts back to baseline, `H.assertNoDebugOutput`.
	`const` and explicit instantiation `f<<T>>(x)` are fine: test/run.sh runs specs on a rewritten mirror because
	Lune 0.10.5 cannot parse them (test/support/mirror.py).

	ADDING AN EXPORT: one line in the table below (`Name = Module.Name`).
]]

local Style = require("@self/Style")
local Interaction = require("@self/Interaction")
local Overlay = require("@self/Overlay")
local Layout = require("@self/Layout")
local Text = require("@self/Text")
local Button = require("@self/Button")
local WindowModule = require("@self/Window")
local Util = require("@self/Util")
local Types = require("@self/Types")
local Checkbox = require("@self/Checkbox")
local RadioButton = require("@self/RadioButton")
local Inputs = require("@self/Inputs")
local InputService = require("@self/Input")
local TreeModule = require("@self/Tree")
local TabModule = require("@self/Tab")
local TableModule = require("@self/Table")
local SelectableModule = require("@self/Selectable")
local ProgressModule = require("@self/Progress")
local PlotModule = require("@self/Plot")
local Combo = require("@self/Combo")
local Menu = require("@self/Menu")
local Dialog = require("@self/Dialog")
local Selection = require("@self/Selection")
local Tooltip = require("@self/Tooltip")
local VirtualRows = require("@self/VirtualRows")

export type Style = Style.Style
export type Overlay = Overlay.Overlay
export type Popup = Overlay.Popup
export type PopupOptions = Overlay.PopupOptions
export type Manager = WindowModule.Manager
export type ManagerSlot = WindowModule.ManagerSlot
export type WindowLayout = WindowModule.WindowLayout
export type WindowState = WindowModule.WindowState
export type TableColumn = TableModule.Column
export type TabDef<K> = TabModule.TabDef<K>
export type MenuScope = Menu.MenuScope
export type GuiHook = Types.GuiHook

-- props types of every widget (so a wrapper can name them: `Devui.ButtonProps`)
export type ContainerProps = Layout.ContainerProps
export type SameLineProps = Layout.SameLineProps
export type IndentProps = Layout.IndentProps
export type SeparatorProps = Layout.SeparatorProps
export type SeparatorTextProps = Layout.SeparatorTextProps
export type TextProps = Text.TextProps
export type TextColoredProps = Text.TextColoredProps
export type LabelTextProps = Text.LabelTextProps
export type ButtonProps = Button.ButtonProps
export type WindowProps = WindowModule.WindowProps
export type CheckboxProps = Checkbox.CheckboxProps
export type RadioButtonProps<T> = RadioButton.RadioButtonProps<T>
export type TreeProps = TreeModule.TreeProps
export type CollapsingHeaderProps = TreeModule.CollapsingHeaderProps
export type TabProps<K> = TabModule.TabProps<K>
export type TabBarProps<K> = TabModule.TabBarProps<K>
export type TableProps<T> = TableModule.TableProps<T>
export type SelectableProps = SelectableModule.SelectableProps
export type SelectableOptionProps<T> = SelectableModule.SelectableOptionProps<T>
export type ProgressBarProps = ProgressModule.ProgressBarProps
export type PlotProps = PlotModule.PlotProps
export type ComboProps<T> = Combo.ComboProps<T>
export type ComboArrayProps<T> = Combo.ComboArrayProps<T>
export type ComboEnumProps = Combo.ComboEnumProps
export type MenuBarProps = Menu.MenuBarProps
export type MenuProps = Menu.MenuProps
export type MenuItemProps = Menu.MenuItemProps
export type MenuToggleProps = Menu.MenuToggleProps
export type MenuHandle = Menu.MenuHandle
export type OpenMenuProps = Menu.OpenMenuProps
export type MenuButtonProps = Menu.MenuButtonProps
export type PopupPanelProps = Menu.PopupPanelProps
export type DialogModal = Dialog.DialogModal
export type DialogHandle = Dialog.DialogHandle
export type OpenDialogProps = Dialog.OpenDialogProps
export type OpenConfirmProps = Dialog.OpenConfirmProps
export type OpenCopyDialogProps = Dialog.OpenCopyDialogProps
export type SelectionMode = Selection.Mode
export type TooltipProps = Tooltip.TooltipProps
export type TooltipHandle = Tooltip.TooltipHandle
export type VirtualRowsProps = VirtualRows.VirtualRowsProps
-- [2026-10-20 user decision] every devui type is reachable from this module; quad's own types (State, Source, Ref,
-- Slot, ...) are NOT re-exported here — they come from the kit's Quad module (`src/Quad.luau`), the one door to quad
export type HoverHandle = Interaction.HoverHandle
export type DragOptions = Interaction.DragOptions
export type DragHandle = Interaction.DragHandle
export type InputListener = InputService.Listener
export type InputTextProps = Inputs.InputTextProps
export type InputNumProps = Inputs.InputNumProps
export type DragNumProps = Inputs.DragNumProps
export type SliderNumProps = Inputs.SliderNumProps
export type InputVector2Props = Inputs.InputVector2Props
export type InputUDim2Props = Inputs.InputUDim2Props
export type InputColor3Props = Inputs.InputColor3Props

local Devui = {
	-- infrastructure
	Style = Style,
	Interaction = Interaction,
	Input = InputService,
	Overlay = Overlay,
	Util = Util,
	Types = Types,
	WindowManager = WindowModule.Manager,
	-- layout
	Kids = Layout.Kids,
	SameLine = Layout.SameLine,
	Group = Layout.Group,
	Indent = Layout.Indent,
	Separator = Layout.Separator,
	SeparatorText = Layout.SeparatorText,
	-- text
	Text = Text.Text,
	TextWrapped = Text.TextWrapped,
	TextColored = Text.TextColored,
	TextDisabled = Text.TextDisabled,
	LabelText = Text.LabelText,
	-- widgets
	Button = Button.Button,
	SmallButton = Button.SmallButton,
	Window = WindowModule.Window,
	-- inputs
	Checkbox = Checkbox,
	RadioButton = RadioButton,
	InputText = Inputs.InputText,
	InputNum = Inputs.InputNum,
	DragNum = Inputs.DragNum,
	SliderNum = Inputs.SliderNum,
	InputVector2 = Inputs.InputVector2,
	InputUDim2 = Inputs.InputUDim2,
	InputColor3 = Inputs.InputColor3,
	NumberFormat = Inputs.NumberFormat,
	-- structure
	Tree = TreeModule.Tree,
	CollapsingHeader = TreeModule.CollapsingHeader,
	Tab = TabModule.Tab,
	TabBar = TabModule.TabBar,
	Table = TableModule.Table,
	VirtualRows = VirtualRows,
	Selectable = SelectableModule.Selectable,
	SelectableOption = SelectableModule.SelectableOption,
	ProgressBar = ProgressModule.ProgressBar,
	PlotLines = PlotModule.PlotLines,
	PlotHistogram = PlotModule.PlotHistogram,
	-- popups
	Combo = Combo.Combo,
	ComboArray = Combo.ComboArray,
	ComboEnum = Combo.ComboEnum,
	MenuBar = Menu.MenuBar,
	Menu = Menu.Menu,
	MenuItem = Menu.MenuItem,
	MenuToggle = Menu.MenuToggle,
	OpenMenu = Menu.OpenMenu,
	MenuButton = Menu.MenuButton,
	PopupPanel = Menu.PopupPanel,
	OpenDialog = Dialog.OpenDialog,
	OpenConfirm = Dialog.OpenConfirm,
	OpenCopyDialog = Dialog.OpenCopyDialog,
	Selection = Selection,
	Tooltip = Tooltip.Tooltip,
}

-- every exported function is public surface: tag the table as built, so a usage error (`Util.fail`) blames the
-- caller's line and a new export needs no hand list
Util.tagSurface(Devui)

return Devui
