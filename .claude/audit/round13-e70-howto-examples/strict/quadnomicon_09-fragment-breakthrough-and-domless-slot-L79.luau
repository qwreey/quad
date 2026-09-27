--!strict
-- E70 strict (generated) — quadnomicon_09-fragment-breakthrough-and-domless-slot-L79
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== doc block quadnomicon/09-fragment-breakthrough-and-domless-slot.md:79 ====
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
