--!strict
-- E70 strict (generated) — quadnomicon_09-fragment-breakthrough-and-domless-slot-L139
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== with quadnomicon/09-fragment-breakthrough-and-domless-slot.md:79 ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local Slot = q.Slot

local function ButtonGroup()
	return q.Slot<<Instance>>({
		D.TextButton { Name = "SaveButton", Text = "Save" },
		D.TextButton { Name = "CancelButton", Text = "Cancel" },
	})
end

local root = D.Frame {
	D.Frame { Name = "Header" },
	ButtonGroup(),
	D.Frame { Name = "Footer" },
}
-- root의 실제 자식은 넷: Header, SaveButton, CancelButton, Footer
-- ==== doc block quadnomicon/09-fragment-breakthrough-and-domless-slot.md:139 ====
local data = q.Source({ "a", "b", "c" })
local list = q.Slot<<Instance>>()
list:List(data, function(ctx)
	if ctx.Item == q.KeyGone then
		return nil, ctx.UserData -- 키가 빠진 사이클: 파괴(nil/None) 또는 홀드(Detach)만 허용
	end
	if ctx.Prev and ctx.UserData then
		ctx.UserData.order:Set(ctx.Index) -- 재활용: 자리 값만 갱신하고 요소는 그대로
		return ctx.Prev, ctx.UserData
	end
	local order = q.Source(ctx.Index)
	local layoutOrder = order:Depend(ctx.Offset):Compute(function(i: q.StateData<number>): number
		return i:Get() + ctx.Offset:Get()
	end)
	return D.TextButton { Text = ctx.Item :: string, LayoutOrder = layoutOrder }, { order = order }
end, function(item) return item end) -- keyFn: 문자열 자신이 키(생략하면 배열 index가 키)
