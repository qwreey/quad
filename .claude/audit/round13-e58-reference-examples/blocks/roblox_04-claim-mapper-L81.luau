-- 새로 만든 자식과 매핑 자식을 한 배열에 섞어도 된다
local function bindMixed(template: Frame)
	return q.Claim(template, M.Frame(M.Root)({
		M.TextLabel("Title")({ Text = "매핑" }),
		D.TextLabel({ Text = "새로 만든 것" }),
		D.Modifier.Frame():BackgroundTransparency(0.5),
		q.None,
	}))
end
