local seen = {}
D.TextLabel({
	Text = "a", -- 문자 키: 아래 바인딩이 연결된 뒤에 쓰인다
	q.OnChange("Text", function(v)
		table.insert(seen, v) -- seen[1] == "a"
	end),
})
