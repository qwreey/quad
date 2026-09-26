local function Card(props)
	return D.Frame {
		props.Modifier or q.None, -- 숫자 키 자리: nil을 넣으면 뒤 항목이 사라진다
		D.TextLabel { Text = props.Title },
	}
end
