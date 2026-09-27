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
