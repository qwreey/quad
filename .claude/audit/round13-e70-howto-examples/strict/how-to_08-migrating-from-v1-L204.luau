--!strict
-- E70 strict (generated) — how-to_08-migrating-from-v1-L204
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_08-migrating-from-v1-L40) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block how-to/08-migrating-from-v1.md:204 ====
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local children: { Instance } = { D.TextLabel { Text = "제목" }, D.TextLabel { Text = "본문" } }

-- v1: Mount(screenGui, Frame{...}, another)
local gui = D.ScreenGui {
	D.Frame {
		-- 자식 배열 변수는 테이블 리터럴의 마지막 원소로 펼쳐서만 넘긴다(직역용 임시 모양 — 정리할 때는 Slot으로 받는다, how-to 01)
		table.unpack(children),
	},
}

-- v1의 Mount 자리: 만들어진 뒤 밖에서 .Parent를 대입한다
gui.Parent = playerGui
