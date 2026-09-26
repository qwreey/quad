-- template: Studio에서 만들어 둔(또는 Clone한) 트리
local function bindCard(template: Frame): Frame
	local title = q.Source("안녕")

	local root = q.Claim(template, M.Frame(M.Root)({
		BackgroundTransparency = 0.25,               -- 루트 자신의 props
		M.TextLabel("Title")({ Text = title }),      -- 이름이 "Title"인 직계 자식
		M.Frame("List")({                            -- 중첩도 된다
			M.TextLabel("Inner")({ Text = "깊은 자식" }),
		}),
	}))

	title:Set("반가워") -- claim한 트리도 반응형: 그대로 프로퍼티가 따라간다
	return root
end
