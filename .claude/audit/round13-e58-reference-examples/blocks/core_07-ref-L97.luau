local boxRef = q.Ref<<Frame?>>(nil)
local panel = D.Frame {
    boxRef,                       -- 숫자 키: 만들어진 Frame이 여기 담긴다
    D.TextLabel { Text = "제목" },
}
