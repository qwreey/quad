--!strict
-- lifecycle-hooks-plan.md: "Luau 함수 타입은 파라미터에 반변이라 인자를 덜 받는 함수가 대입 가능"
type Ref = { Value: number }
local function OnCreated(fn: (inst: string, ref: Ref) -> ()): () return end
OnCreated(function(inst) print(inst) end)          -- 1-인자 람다
OnCreated(function(inst: string) print(inst) end)  -- 주석 붙은 1-인자
OnCreated(function(inst, ref) print(inst, ref.Value) end)
local f: (number, string) -> () = function(x: number) end
local g: (number) -> () = function(x: number, y: string) end   -- 더 받는 쪽: 에러여야 정상
