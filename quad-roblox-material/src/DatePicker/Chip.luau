--!strict
--[[
	Chip: one selectable round "date chip" — a day cell or a year chip of the date picker — as THREE instances
	(TextButton host + UICorner + UIStroke). Everything it shows is derived from ONE `Status` State, so a day cell
	never has to be rebuilt: the picker changes what the status State says.

	    Chip.new({ Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(4, 4), Text = textState,
	               Status = statusState, OnActivated = pick })

	Status
	  Hidden    Visible = false (out-of-month day; M3 hides them)
	  Disabled  text at onSurface 38 %, not clickable / selectable (`Interactable = false`)
	  Normal    onSurface text, transparent
	  Today     primary text + 1 px outline
	  Selected  primary fill, onPrimary text
	  InRange   (Band chips only) secondaryContainer band, onSecondaryContainer text
	  RangeStart / RangeEnd   drawn exactly like Selected; they only tell the month grid to lay the half band that joins
	            the end circle to the in-range strip (MonthView `BandEnds`)
	Hover / pressed / keyboard-focus feedback is the M3 state layer expressed as the host's own background
	transparency (onSurface at .08 / .10 — no separate layer Frame, that is what keeps a cell at 3 instances);
	a focused chip also gets a 2 px `Secondary` ring (the UIStroke). A Selected chip does not change on hover
	(M3 would lay an onPrimary layer on it — dropped to save instances).

	Options
	  Name, Size, Position       Position is a UDim2 (cells are placed absolutely — no UIGridLayout)
	  Text                       string | State<string>
	  Status                     State<Status>
	  Theme                      Theme?
	  Corner                     UDim?   default full (circle for a square size)
	  Role                       Text role, default "BodyLarge"
	  Band                       boolean? range band: an InRange chip is widened by `BandExtra` px on both sides
	                             and squared so neighbouring in-range chips form one continuous strip
	  OnActivated                () -> ()     mouse / touch / gamepad A (skipped while Hidden / Disabled)
	  OnFocused / OnBlurred      (() -> ())?  engine selection (gamepad / keyboard focus) entered / left
	  Hooks                      Hooks?       extra array-part values on the host (the month grid seats a KeyNav hook here)
	Cost: 3 instances, 10 status-derived States, 3 of them animated (Short2).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Interaction = require("../Interaction")
local Interactive = require("../Interactive")
local Util = require("../Util")
local Text = require("../Text")
local D = q.Declaration

export type Status = "Hidden" | "Disabled" | "Normal" | "Today" | "Selected" | "InRange" | "RangeStart" | "RangeEnd"

export type Options = {
	Name: string?,
	Size: UDim2,
	Position: UDim2,
	Text: string | q.State<string>,
	Status: q.State<Status>,
	Theme: Theme.Theme?,
	Corner: UDim?,
	Role: Text.Role?,
	Band: boolean?,
	BandExtra: number?,
	OnActivated: () -> (),
	OnFocused: (() -> ())?,
	OnBlurred: (() -> ())?,
	Hooks: Util.Hooks?,
}

local DisabledText = 1 - Tokens.State.Opacity.DisabledContent
local HoverT = 1 - Tokens.State.Opacity.Hover
local PressT = 1 - Tokens.State.Opacity.Pressed

-- a range end draws as the selected circle (the joining half band is the month grid's, under the chip)
local function selectedLook(s: Status): boolean
	return s == "Selected" or s == "RangeStart" or s == "RangeEnd"
end

local function animation()
	return q.Animate(Tokens.Motion.options("Short2", "Standard"))
end

local function new(o: Options): TextButton
	local theme = Theme.resolve(o.Theme)
	local raw = theme.Raw
	local status = o.Status
	local ix = Interaction.new({
		OnHost = function(inst: GuiObject)
			inst.SelectionImageObject = Interactive.noSelectionImage()
		end,
	})

	local visible: q.State<boolean> = status:Compute(function(self)
		return self:Get() ~= "Hidden"
	end)
	local interactable: q.State<boolean> = status:Compute(function(self)
		local s = self:Get()
		return s ~= "Hidden" and s ~= "Disabled"
	end)

	-- container: filled primary (Selected) / band (InRange) / onSurface state layer
	local bgColor: q.State<Color3> = status:Compute(function(self, _prev, primary, onSurface, band)
		local s = self:Get()
		if selectedLook(s) then
			return primary:Get()
		elseif s == "InRange" then
			return band:Get()
		end
		return onSurface:Get()
	end, raw.Primary, raw.OnSurface, raw.SecondaryContainer)
	local bgTransparency: q.State<number> = status:Compute(function(self, _prev, hovered, pressed, focused)
		local s = self:Get()
		if selectedLook(s) or s == "InRange" then
			return 0
		elseif s == "Hidden" or s == "Disabled" then
			return 1
		elseif pressed:Get() or focused:Get() then
			return PressT
		elseif hovered:Get() then
			return HoverT
		end
		return 1
	end, ix.Hovered, ix.Pressed, ix.Focused)

	local textColor: q.State<Color3> = status:Compute(function(self, _prev, onPrimary, primary, onSurface, onBand)
		local s = self:Get()
		if selectedLook(s) then
			return onPrimary:Get()
		elseif s == "InRange" then
			return onBand:Get()
		elseif s == "Today" then
			return primary:Get()
		end
		return onSurface:Get()
	end, raw.OnPrimary, raw.Primary, raw.OnSurface, raw.OnSecondaryContainer)
	local textTransparency: q.State<number> = status:Compute(function(self)
		return if self:Get() == "Disabled" then DisabledText else 0
	end)

	-- ring: 0 none, 1 today outline, 2 focus ring
	local ring: q.State<number> = status:Compute(function(self, _prev, focused)
		local s = self:Get()
		if focused:Get() and s ~= "Hidden" and s ~= "Disabled" then
			return 2
		elseif s == "Today" then
			return 1
		end
		return 0
	end, ix.Focused)
	local ringColor: q.State<Color3> = ring:Compute(function(self, _prev, outline, secondary)
		return if self:Get() == 2 then secondary:Get() else outline:Get()
	end, raw.Outline, raw.Secondary)
	local ringTransparency: q.State<number> = ring:Compute(function(self)
		return if self:Get() == 0 then 1 else 0
	end)
	local ringThickness: q.State<number> = ring:Compute(function(self)
		return if self:Get() == 2 then 2 else 1
	end)

	local selectable: q.State<boolean> = status:Compute(function(self)
		return self:Get() ~= "Hidden"
	end)

	local size: UDim2 | q.State<UDim2> = o.Size
	local position: UDim2 | q.State<UDim2> = o.Position
	local corner: UDim | q.State<UDim> = o.Corner or Tokens.Shape.corner("Full")
	if o.Band then
		local extra = o.BandExtra or 4
		local base, basePos = o.Size, o.Position
		local wide = UDim2.new(base.X.Scale, base.X.Offset + 2 * extra, base.Y.Scale, base.Y.Offset)
		local widePos = UDim2.new(basePos.X.Scale, basePos.X.Offset - extra, basePos.Y.Scale, basePos.Y.Offset)
		size = status:Compute(function(self)
			return if self:Get() == "InRange" then wide else base
		end)
		position = status:Compute(function(self)
			return if self:Get() == "InRange" then widePos else basePos
		end)
		local round = o.Corner or Tokens.Shape.corner("Full")
		local square = Tokens.Shape.corner("None")
		corner = status:Compute(function(self)
			return if self:Get() == "InRange" then square else round
		end)
	end

	return D.TextButton {
		Name = o.Name or "Chip",
		Text.Button(o.Role or "BodyLarge"),
		ix.Hook,
		-- band chips sit above the month grid's half-band frames (MonthView `BandEnds`)
		ZIndex = if o.Band then 2 else nil,
		Size = size,
		Position = position,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = o.Text,
		Visible = visible,
		Interactable = interactable,
		-- a hidden (out-of-month) cell is never a gamepad selection target (device-unverified)
		Selectable = selectable,
		BackgroundColor3 = bgColor:Apply(animation()),
		BackgroundTransparency = bgTransparency:Apply(animation()),
		TextColor3 = textColor:Apply(animation()),
		TextTransparency = textTransparency,
		UICorner = corner,
		Activated = function()
			local s = status:Get()
			if s == "Hidden" or s == "Disabled" then
				return
			end
			o.OnActivated()
		end,
		SelectionGained = function()
			if o.OnFocused then
				o.OnFocused()
			end
		end,
		SelectionLost = function()
			if o.OnBlurred then
				o.OnBlurred()
			end
		end,
		D.UIStroke {
			Name = "Ring",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = ringColor,
			Transparency = ringTransparency,
			Thickness = ringThickness,
		},
		table.unpack(Util.hooks(o.Hooks)),
	}
end

return { new = new }
