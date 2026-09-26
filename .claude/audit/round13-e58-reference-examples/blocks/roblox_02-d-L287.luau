local frameRef = q.Ref<<Frame?>>(nil)
local labelRef = q.Ref<<TextLabel?>>(nil)

D.Frame({ frameRef })  -- OK
D.Frame({ labelRef })  -- 타입 에러: 형제 클래스의 Ref는 거부된다
