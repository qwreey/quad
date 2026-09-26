local text = q.Source("")

local box = D.TextBox({
	Text = text,          -- in: Source → 프로퍼티
	q.Out("Text", text),  -- out: 프로퍼티 → Source
})
-- 사용자가 타이핑하면 text:Get()이 따라오고, text:Set("…")하면 입력창이 따라간다
