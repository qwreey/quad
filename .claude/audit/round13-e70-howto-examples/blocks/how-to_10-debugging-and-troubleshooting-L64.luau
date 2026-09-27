-- ❌ props.Modifier가 nil이면 배열에 구멍이 생긴다
D.Frame { props.Modifier, props.Ref, Size = UDim2.new() }

-- ✅
D.Frame { props.Modifier or q.None, props.Ref or q.None, Size = UDim2.new() }
