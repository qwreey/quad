-- source: SKILL.md:214-225
-- both forms exist: builder chain and table call. Only the CHAIN form is type-checked
-- (field names + value types); the table form only carries the class tag — `{ Sise = 1 }`,
-- `{ Size = "x" }`, `{ Activated = fn }` all pass strict and fail at runtime drive
-- (Quad0076/Quad0063). Prefer the chain form in generated code.
local buttonMod = D.Modifier.TextButton():BackgroundTransparency(0.5):Text("Go")
local sameRuntimeValue = D.Modifier.TextButton{ BackgroundTransparency = 0.5, Text = "Go" }

local base = D.Modifier.GuiObject():Visible(true)
local checked   = base:AsTextButton():Text("ok")            -- CHECKED: one method per subclass
local unchecked = base:As<<DeclarationModule.TextLabelModifier>>()     -- UNCHECKED: caller asserts the type
