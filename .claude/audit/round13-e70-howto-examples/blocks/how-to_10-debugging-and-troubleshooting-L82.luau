-- ✅ 이미 있으면 즉시, 없으면 다음 채워짐을 대기
local inst = if myRef.Value then myRef.Value else myRef:Wait().Value
