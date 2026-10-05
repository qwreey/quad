--!strict
--[[
	Demo section "Table" — a keyed table over a Source of rows. Add / remove / damage rows with the buttons: rows are
	recycled by key, so a surviving row keeps its instances and only its cell texts update (the `row` State each Cell
	receives is republished when the row VALUE changes — rows are replaced, never mutated in place).
]]

local Devui = require("./Kit")
local Context = require("./Context")
local q = require("../Quad")

type Context = Context.Context

local Kids = Devui.Kids

export type Row = { Id: number, Name: string, Hp: number }

local NAMES = { "Ada", "Bob", "Cy", "Dee", "Eli", "Fay", "Gus" }

local function Tables(ctx: Context): Instance
	local style = ctx.Style
	local nextId = 4
	local rows = q.Source<<{ Row }>>({
		{ Id = 1, Name = "Ada", Hp = 100 },
		{ Id = 2, Name = "Bob", Hp = 70 },
		{ Id = 3, Name = "Cy", Hp = 40 },
	})

	local function without(id: number): { Row }
		local out: { Row } = {}
		for _, r in rows:Get() do
			if r.Id ~= id then
				table.insert(out, r)
			end
		end
		return out
	end

	local countText: q.State<string> = rows:Compute(function(self)
		return `{#self:Get()} rows`
	end)

	local table_ = Devui.Table<<Row>>({
		Columns = {
			{ Title = "Id", Width = 30 },
			{ Title = "Name" },
			{ Title = "Hp", Width = 50 },
			{ Title = "", Width = 40 },
		},
		Rows = rows,
		Key = function(r: Row)
			return r.Id
		end,
		RowBg = true,
		Borders = true,
		Style = style,
		Cell = function(row: q.State<Row>, col: number): Instance
			if col == 4 then
				return Devui.SmallButton({
					Text = "x",
					Style = style,
					OnClick = function()
						rows:Set(without(row:Get().Id))
					end,
				})
			end
			local text: q.State<string> = row:Compute(function(self)
				local r = self:Get()
				if col == 1 then
					return tostring(r.Id)
				elseif col == 2 then
					return r.Name
				end
				return tostring(r.Hp)
			end)
			return Devui.Text({ Text = text, Style = style })
		end,
	})

	return Devui.CollapsingHeader({
		Text = "Table",
		Style = style,
		Children = Kids(
			Devui.SameLine({
				Style = style,
				Children = Kids(
					Devui.Button({
						Text = "Add row",
						Style = style,
						OnClick = function()
							local list = table.clone(rows:Get())
							table.insert(list, { Id = nextId, Name = NAMES[(nextId - 1) % #NAMES + 1], Hp = 100 })
							nextId += 1
							rows:Set(list)
						end,
					}),
					Devui.Button({
						Text = "Remove last",
						Style = style,
						OnClick = function()
							local list = table.clone(rows:Get())
							table.remove(list)
							rows:Set(list)
						end,
					}),
					Devui.Button({
						Text = "Damage all",
						Style = style,
						OnClick = function()
							local list: { Row } = {}
							for _, r in rows:Get() do
								table.insert(list, { Id = r.Id, Name = r.Name, Hp = math.max(0, r.Hp - 10) })
							end
							rows:Set(list)
						end,
					})
				),
			}),
			Devui.TextDisabled({ Text = countText, Style = style }),
			table_
		),
	})
end

return Tables
