--!strict
--[[
	Slot `:Single`/`:List` 타이핑(2026-09-11 사용자 확정 D10) — `:Single`이 `:List`와 같은
	`<Item, UD>`를 가져, 구동 State가 데이터(`Item`)이고 원소 타입 `T`와 묶이지 않는가.
	양성만 담고 본문은 실행하지 않는다(spec.reftypes 관례). 음성(`updateFn` 없이
	`Source<string?>`로 `Slot<Instance>`를 모는 것 — identity 팔은 `Item = T`라 거부)은
	착수 시 스크래치 실측(session/2026-09-09-01-docs-polish.md 2026-09-11 문단).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local QuadTypes = require("../luau_packages/quad_types")
type State<T> = QuadTypes.State<T>
type SlotItem<T> = QuadTypes.SlotItem<T>
-- 사용자 쪽 별칭 — updateFn 인자 테이블(2026-09-15)을 이름 붙여 주석으로 쓰는 관용구가 strict에서 서는가
type Ctx<Item, UD> = { Item: Item, Index: number, Offset: State<number>, Prev: SlotItem<Instance>?, UserData: UD? }

local q = Quad.New():UseProvider(QuadRoblox)

local function _neverCalled()
	local D = q.Declaration
	-- (1) 매핑 updateFn: Item = string, 원소 = Instance, UD = number
	local cur = q.Source(nil :: string?)
	local mapped = q.Slot<<Instance>>():Single(cur, function(ctx: Ctx<any, number>): (any, number?)
		local item, offset, ud = ctx.Item, ctx.Offset, ctx.UserData
		if item == q.KeyGone then
			return nil, nil
		end
		local text: string = item
		return D.TextLabel({
			Text = text,
			LayoutOrder = offset:Compute(function(o: QuadTypes.StateData<number>): number
				return o:Get() + 1
			end),
		}), (ud or 0) + 1
	end)
	-- (2) updateFn 생략 슈거(identity): Item = T
	local current = q.Source(nil :: Instance?)
	local identity = q.Slot<<Instance>>():Single(current)
	-- (3) 값 직접, opts
	local literal = q.Slot<<Instance>>():Single(D.TextLabel({ Text = "A" }), nil, { Owned = false })
	-- (4) 대조군 :List — 같은 <Item, UD> 모양
	type Row = { Id: string }
	local rows = q.Source({ { Id = "a" } } :: { Row })
	local listed = q.Slot<<Instance>>():List(rows, function(ctx: Ctx<any, number>): (any, number?)
		local item, ud = ctx.Item, ctx.UserData
		if item == q.KeyGone then
			return nil, nil
		end
		return D.TextLabel({ Text = item.Id }), (ud or 0) + 1
	end, function(item: Row)
		return item.Id
	end)
	local host = D.Frame({ mapped, identity, literal, listed })
	return host
end

print("=== ALL PASS ===")
