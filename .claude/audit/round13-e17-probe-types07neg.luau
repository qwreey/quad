--!strict
-- round13 E17 (d) negatives — each line below should be a type error
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local M = D.Mapper
local inst = Instance.new("Frame")
local n = q.Source(0)
q.Claim(inst, { Visible = true })                                   -- L8: plain props table
q.Claim(inst, M.Frame(M.Root)({ M.TextLabel("A")({ Image = "x" }) })) -- L9: TextLabel has no Image
q.Claim(inst, M.Frame(M.Root)({ M.TextBox("B")({ q.Out("Text", n) }) })) -- L10: Out Text with Source<number>
q.Claim(inst, M.Frame(M.Root)({ M.TextLabel("C")({ Text = n }) }))  -- L11: Text = State<number>
q.Claim(inst, M.Frame("Root")({}))                                  -- L12: string root key (allowed by type — only debug print)
q.Claim(inst, M.Frame(M.Root)({ M.Frame(M.Root)({}) }))             -- L13: M.Root at a child seat (type allows?)
q.Claim(inst, M.Frame(M.Root)({ Parent = inst }))                   -- L14: Parent in props
