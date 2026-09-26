--!strict
-- E26: OnChange("Parent") unannotated callback — what is `p` inferred as at HEAD?
local q = require("./t-settings")
local D = q.Declaration
local function _x()
	local _a = D.Frame { q.OnChange("Parent", function(p) local _n: number = p end) } -- probe: reveals p's type
	local _b = D.Frame { q.OnChange("Parent", function(p) if p ~= nil then print(p.Name) end end) } -- ?
	local _c = D.Frame { q.OnChange("Parent", function(p) if p and p:IsA("Frame") then end end) } -- ?
	local _d = D.TextLabel { q.OnChange("Text", function(t) print(t:upper()) end) } -- control: non-optional
	local _e = D.Frame { q.OnChange("Parent", function(p: Instance?) if p then print(p.Name) end end) } -- control annotated
end
