local function CardDescriptor(text: string)
	return M.Frame(M.Root)({ M.TextLabel("Title")({ Text = text }) })
end

local function bindAll(cards: { Frame })
	for _, card in cards do
		q.Claim(card, CardDescriptor("항목")) -- 매번 새 디스크립터
	end
end
