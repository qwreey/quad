--!strict
-- E70 strict (generated) — how-to_08-migrating-from-v1-L238
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_08-migrating-from-v1-L40) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
--[[E70 보강 pre]]
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- [E70] 같은 페이지 L103 첫 줄
-- ==== doc block how-to/08-migrating-from-v1.md:238 ====
type Row = { Id: string, Title: string }
type RowUD = { title: q.Source<string>, order: q.Source<number> }
type RowCtx = {
	Item: Row | QuadTypes.KeyGone,
	Index: number,
	Offset: q.State<number>,
	Prev: QuadTypes.SlotItem<Instance>?,
	UserData: RowUD?,
}

-- v1: local mounts = Mount(parent); mounts:Add(item); mounts:Unmount()
local rows = q.Source<<{ Row }>>({ { Id = "a", Title = "첫 줄" } })
local slot = q.Slot<<Instance>>()

slot:List(rows, function(ctx: RowCtx): (any, RowUD?)
	if ctx.Item == q.KeyGone then
		return nil -- 키가 사라졌다: 파괴
	end
	local data = ctx.Item :: Row
	local prev, ud = ctx.Prev, ctx.UserData
	if prev and ud then
		ud.title:Set(data.Title)     -- 캐시해둔 Source만 갱신하고 인스턴스는 재활용한다
		ud.order:Set(ctx.Index)      -- 순서도 Source로 들고 있어야 재정렬이 반영된다
		return prev, ud
	end
	local title, order = q.Source(data.Title), q.Source(ctx.Index)
	return D.TextLabel { LayoutOrder = order, Text = title }, { title = title, order = order }
end, function(item: Row): string
	return item.Id
end)

local list = D.Frame { slot }
