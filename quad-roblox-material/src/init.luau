--!strict
--[[
	Material 3 kit for quad (Roblox). The public entry: everything the kit exports is in the table at the end, and the
	component types are re-exported above it (`Material.ButtonProps`, `Material.Hooks`, ...).

	Contents (one line per module; the file header of each module is its documentation)
	  Foundation
	    Tokens        static M3 tokens: Color (baseline light/dark), Typography, Shape, Elevation, Motion, State
	    Theme         `Theme.new{ Scheme, Overrides }` / `Theme.default`: animated reactive color roles
	    Text          type-scale text Modifiers (`Text.Label("BodyLarge")`)
	    Interaction   hover/pressed/focused States + drag tracker (hook-based)
	    Ripple        CanvasGroup-clipped pressed ripple (4 transient instances per press)
	    StateLayer    the hover/focus/pressed overlay Frame
	    Interactive   Interaction + StateLayer + Ripple + focus ring in one call (what components use)
	    Elevation     `Elevation.Shadow{ Level }` (UIShadow) + `Elevation.Backdrop` (9-slice image fallback)
	    Overlay       the layer for menus / dialogs / snackbars / tooltips (Escape/B, selection trap, layer death)
	    Icons         the built-in glyph table + `Icons.override` for image assets
	    GlyphButton   the small round glyph / image button (date picker, Snackbar close, Chip remove)
	    KeyNav        key / D-pad delivery for focusable controls (Slider, day cells, hue slider, SV area)
	    Util          asState / negate / interactable / visible / hooks / preHook / postHook helpers, the `Hooks` type
	  Components
	    Button, IconButton, FAB                       actions
	    Checkbox, Radio, RadioGroup, Switch, Slider   selection controls
	    TextField, Select, Menu                       text input and menus
	    Card, Divider, List, ListItem, ListData       surfaces
	    Dialog, Snackbar, Tooltip                     things that float (opened through an Overlay)
	    Chip, Tabs, LinearProgress, CircularProgress  chips, tabs, progress
	    DatePicker, ColorPicker                       pickers (docked / modal / panel, the pure Calendar / ColorModel math)
	  (Gallery is NOT exported from here — require `Gallery` directly; see its header.)

	API CONVENTIONS (the same everywhere; a new component follows them, a reviewer checks them)
	  Value and callbacks
	    * Form controls — Checkbox, Switch, Radio, Slider, TextField, Select, DatePicker (Docked / Range), ColorPicker —
	      take `Value` (a `Source`, two-way: the component reads it and a USER action writes it) and fire
	      `OnChange(new)` after a user-originated change only (never for a programmatic write). Checkbox and Switch ALSO
	      accept the controlled form `Checked: State<boolean>` + `OnChange` (nothing is written; the owner decides);
	      giving both `Value` and `Checked` is an error.
	    * Choice / indicator components — Chip.Filter, Tabs, ListItem, IconButton (toggle), Menu.Item — use `Selected`.
	      Their change callback is also `OnChange` (Chip.Filter, Tabs).
	    * Text: action / button text is `Label` everywhere (Button, Chip, Tabs' tab, Menu.Item, Snackbar action, Dialog
	      action). The only plain `Text` is the message of a Snackbar (and display text of read-only labels).
	    * `Disabled: boolean | State<boolean>` on everything that can be disabled (including list/menu items and radio options).
	  Hosts
	    * `Theme: Theme?` (default `Theme.default`), `Modifier: q.<Class>Modifier?` (the host's class — `q.TextButtonModifier`,
	      `q.FrameModifier`, ... from `Quad.luau`; never a local `typeof(D.Modifier.X())` alias), `Hooks: Hooks?` on every
	      component that returns a host instance. `Hooks = { any }` is the one exported alias: values placed in the host's
	      ARRAY part (a `Tooltip.hook(...).Hook`, `q.OnChange`, a ref, ...). Use `table.unpack(Util.hooks(props.Hooks))` as
	      the LAST entry of the host constructor (a multi-value call is truncated anywhere else).
	  Opened things
	    * Everything that is opened — an Overlay entry, Menu.open, Dialog.open, DatePicker.Modal.open, ColorPicker.Modal.open,
	      a Snackbar item, a Tooltip hook — returns ONE handle shape: closures WITHOUT self, `handle.Close(result?)` and
	      `handle.IsOpen: State<boolean>` (Overlay handles also have `Closing`, Dialog `Result`, Snackbar `Visible` / `Done` /
	      the `Dismiss` alias). `result` is `unknown`.
	  Types
	    * Props types are exported `read`-field tables; optional inputs are `T?`; reactive inputs are `T | State<T>`. A
	      generic component needs its type argument spelled out where an invariant `Source<K>` is passed (`Tabs<<string>>`).

	HOW TO WRITE A MATERIAL COMPONENT (the checklist every component of this kit follows)
	1. Plain function `Component(props: Props)` returning the host instance. `Props` is an exported type with
	   `read` fields; optional inputs are `T?`. Reactive inputs are `T | State<T>` (convert once with
	   `Util.asState(props.Disabled)` — never branch on State vs plain per use).
	2. Theme: `local theme = Theme.resolve(props.Theme)`. Plug `theme.Color.<Role>` (animated State<Color3>)
	   straight into properties. For color MATH or choosing between roles use `theme.Raw.<Role>` inside a
	   `:Compute`, then `:Apply(q.Animate(...))` once on the result (see Button/Style.luau `disabledPick`).
	3. Typography: `Text.Label("LabelLarge")` Modifier in the label's array part; sizes/shapes/motion/state
	   opacities come from `Tokens.*` — never hard-code a number a token already names.
	4. Interaction visuals: `local fx = Interactive.new({ Theme, Disabled, OnColor, Corner })` and place
	   `fx.Hook` (array part of the host), then `fx.Layer` (array part, BEFORE the content). Use
	   `fx.Hovered/Pressed/Focused` for extra logic. Disabled hosts also get `Interactable = Util.interactable(disabled)`.
	5. Elevation: `Elevation.Shadow({ Level = <number | State<number>>, Theme })` as a child of the host.
	6. Shape: ONE `UICorner = Tokens.Shape.corner(role)` on the host and the SAME value to `Interactive`.
	7. Optional caller styling: `props.Modifier` goes in the array part AFTER the component's base Modifier
	   (later wins), never `or nil` — `props.Modifier or q.None`. Keep Size/AutomaticSize in the base Modifier
	   (not inline) so callers can override them. `props.Hooks` goes last (`table.unpack(Util.hooks(props.Hooks))`).
	8. Overlays (menus, dialogs, snackbars, tooltips): do not parent them yourself — `Overlay.default():Open({
	   Content = ..., Scrim = ..., DismissOnEscape = ..., TrapSelection = ... })` (or the app's own `Overlay.new()`);
	   the content mounts snapped and animates from a `Util.postHook`. Escape/B, selection trapping and layer-death
	   finalization belong to the Overlay — a component does not wire its own.
	9. Instance budget: a component is ONE host GuiObject + UICorner (+UIStroke/UIPadding) + the interaction
	   layer (3). Anything that appears/moves goes in a Slot; static children are bound to the host.
	10. Spec per component: mount, interaction, Source round trip, dispose, `H.assertNoDebugOutput`.
	Style notes: `const` and `<<T>>` explicit type arguments are fine (test/run.sh runs specs on a rewritten mirror
	because Lune 0.10.5 cannot parse them). For lifecycle hooks `Util.preHook`/`postHook` wrap
	`q.PreRef(nil :: GuiObject?):Callback(fn)` (`q.OnCreated<<Class>>` works too).
]]

local ThemeModule = require("@self/Theme")
local Interaction = require("@self/Interaction")
local Ripple = require("@self/Ripple")
local Overlay = require("@self/Overlay")
local Icons = require("@self/Icons")
local Button = require("@self/Button")
local IconButton = require("@self/Button/IconButton")
local FAB = require("@self/Button/FAB")
local Checkbox = require("@self/Checkbox")
local RadioModule = require("@self/Radio")
local Switch = require("@self/Switch")
local Slider = require("@self/Slider")
local TextField = require("@self/TextField")
local Menu = require("@self/Menu")
local Select = require("@self/Select")
local Card = require("@self/Card")
local Divider = require("@self/Divider")
local ListModule = require("@self/List")
local Dialog = require("@self/Dialog")
local Snackbar = require("@self/Snackbar")
local Tooltip = require("@self/Tooltip")
local Chip = require("@self/Chip")
local Tabs = require("@self/Tabs")
local Progress = require("@self/Progress")
local DatePicker = require("@self/DatePicker")
local ColorPickerModule = require("@self/ColorPicker")
local ClassicColorPicker = require("@self/ColorPicker/Classic")
local Util = require("@self/Util")

export type Theme = ThemeModule.Theme
export type SchemeName = ThemeModule.SchemeName
export type Role = ThemeModule.Role
export type Hooks = Util.Hooks
export type ThemeOverrides = ThemeModule.Overrides
export type ThemeOptions = ThemeModule.Options
-- Overlay
export type Handle = Overlay.Handle
export type OverlayHandle = Overlay.Handle
export type OverlayType = Overlay.Overlay
export type OverlayOptions = Overlay.Options
export type OverlayOpenOptions = Overlay.OpenOptions
export type OverlayCloseReason = Overlay.CloseReason
export type OverlayOnCloseFn = Overlay.OnCloseFn
-- variants
export type ButtonVariant = Button.Variant
export type IconButtonVariant = IconButton.Variant
export type CardVariant = Card.Variant
export type TabsVariant = Tabs.Variant
export type TextFieldVariant = TextField.Variant
export type ButtonProps = Button.Props
export type IconButtonProps = IconButton.Props
export type FABProps = FAB.Props
export type CheckboxProps = Checkbox.Props
export type RadioProps<T> = RadioModule.Props<T>
export type RadioGroupProps<T> = RadioModule.GroupProps<T>
export type SwitchProps = Switch.Props
export type SliderProps = Slider.Props
export type TextFieldProps = TextField.Props
export type MenuItem = Menu.Item
export type MenuEntry = Menu.Entry
export type MenuOpenOptions = Menu.OpenOptions
export type MenuButtonProps = Menu.ButtonProps
export type SelectProps<T> = Select.Props<T>
export type CardProps = Card.Props
export type DividerProps = Divider.Props
export type ListItemProps = ListModule.ItemProps
export type ListProps = ListModule.Props
export type ListDataProps<T> = ListModule.DataProps<T>
export type DialogOptions = Dialog.OpenOptions
export type DialogHandle = Dialog.Handle
export type DialogAction = Dialog.Action
export type DialogConfirmOptions = Dialog.ConfirmOptions
export type SnackbarShowOptions = Snackbar.ShowOptions
export type SnackbarOptions = Snackbar.Options
export type SnackbarItem = Snackbar.Item
export type SnackbarHost = Snackbar.Host
export type SnackbarAction = Snackbar.Action
export type SnackbarDismissReason = Snackbar.DismissReason
export type TooltipOptions = Tooltip.Options
export type TooltipHandle = Tooltip.Handle
export type TooltipPlainProps = Tooltip.PlainProps
export type ChipAssistProps = Chip.AssistProps
export type ChipFilterProps = Chip.FilterProps
export type ChipInputProps = Chip.InputProps
export type ChipSetProps<T> = Chip.ChipSetProps<T>
export type TabsProps<K> = Tabs.Props<K>
export type Tab<K> = Tabs.Tab<K>
export type LinearProgressProps = Progress.LinearProps
export type CircularProgressProps = Progress.CircularProps
export type Date = DatePicker.Date
export type DatePickerDockedProps = DatePicker.DockedProps
export type DatePickerRangeProps = DatePicker.RangeDockedProps
export type DatePickerModalOptions = DatePicker.ModalOptions
export type DatePickerLocale = DatePicker.Locale
export type ClassicColorPickerProps = ClassicColorPicker.Props
export type ColorPickerProps = ColorPickerModule.PanelProps
export type ColorPickerModalOptions = ColorPickerModule.ModalOptions
export type HSV = ColorPickerModule.HSV
export type ColorPickerMode = ColorPickerModule.Mode

return {
	Tokens = require("@self/Tokens"),
	Theme = ThemeModule,
	Text = require("@self/Text"),
	Interaction = Interaction,
	Ripple = Ripple,
	StateLayer = require("@self/StateLayer"),
	Interactive = require("@self/Interactive"),
	Elevation = require("@self/Elevation"),
	Overlay = Overlay,
	Icons = Icons,
	Util = Util,
	GlyphButton = require("@self/GlyphButton"),
	KeyNav = require("@self/KeyNav"),
	Button = Button,
	IconButton = IconButton,
	FAB = FAB,
	-- selection
	Checkbox = Checkbox,
	Radio = RadioModule.Radio,
	RadioGroup = RadioModule.RadioGroup,
	Switch = Switch,
	Slider = Slider,
	-- text input & menus
	TextField = TextField,
	Menu = Menu,
	Select = Select,
	-- surfaces & overlays
	Card = Card,
	Divider = Divider,
	List = ListModule.List,
	ListItem = ListModule.ListItem,
	ListData = ListModule.ListData,
	Dialog = Dialog,
	Snackbar = Snackbar,
	Tooltip = Tooltip,
	-- chips, tabs, progress
	Chip = Chip,
	Tabs = Tabs,
	LinearProgress = Progress.LinearProgress,
	CircularProgress = Progress.CircularProgress,
	-- pickers
	DatePicker = DatePicker,
	ColorPicker = ColorPickerModule, -- .Panel / .Modal.open / .ColorModel / .Classic
}
