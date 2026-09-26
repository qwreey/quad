-- source: references/rules-and-invariants.md:60-64
local base = D.Modifier.GuiObject():Visible(true)
local checked = base:AsTextButton():Text("go")                    -- CHECKED (one method per subclass)
local forced  = base:As<<DeclarationModule.TextLabelModifier>>()            -- UNCHECKED, caller asserts
