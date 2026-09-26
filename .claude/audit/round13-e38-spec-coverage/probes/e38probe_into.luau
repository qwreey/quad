local mock = require("./mock")
local q = mock.newQuad()
local M = q.Modifier
M.TypedFactory("TextButton"); M.TypedFactory("GuiObject"); M.DefineSubtype("GuiObject", "TextButton")
local Material = M.TypedFactory("MaterialButtonSpec"); M.DefineSubtype("TextButton", "MaterialButtonSpec")
local mod = Material({ TextSize = 18 })
local ok, e = pcall(function() return mod:AsTextButton() end); print("custom subtype :AsTextButton()", ok, e)
local ok2, r = pcall(function() return mod:As("TextButton") end); print("custom subtype :As('TextButton')", ok2, r and r.__quadModifier)
local g = M.TypedFactory("GuiObject")({}); print("ancestor :AsTextButton()", pcall(function() return g:AsTextButton().__quadModifier end))
