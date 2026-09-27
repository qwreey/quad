-- ❌ props.Modifier가 없으면 1번 자리가 구멍이 된다 — 그 자리에서 에러
D.TextButton { props.Modifier, props.Ref, Text = "x" }

-- ✅ None이 자리를 지킨다 — 기여는 0이지만 위치는 그대로
D.TextButton { props.Modifier or None, props.Ref or None, Text = "x" }
