--!strict
-- 테이블 리터럴 컨텍스트에서는 무주석 함수 파라미터가 추론되는가? (call-arg와 다른 경로인지 확인)
type Handlers = { fn: (number) -> string }
local t: Handlers = { fn = function(a) return tostring(a) end }
