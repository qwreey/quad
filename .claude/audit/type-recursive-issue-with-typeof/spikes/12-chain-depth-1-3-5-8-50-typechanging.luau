--!strict
-- 05-WINNER의 승자 formulation(순수 typeof, self-핸들 콜백 파라미터)을
-- 깊이 1/3/5/8/50까지 실제로 확장 검증. 05는 depth 3까지만 있어서
-- REPORT.md 3절이 주장하는 "50단 체이닝" 자체는 이 파일이 근거임
-- (code-review 지적으로 뒤늦게 분리 — 원래 REPORT는 이 스파이크 없이
-- 그 주장을 함, 05와 혼동하지 말 것).
-- 매 체크포인트(d1/d3/d5/d8/d50)마다 타입이 실제로 바뀌는 3-순환
-- (number→boolean→string→number→...) 체이닝 + 양성/음성 대조군 쌍.
local function Get<T>(self: State<T>): T return nil :: any end
local function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U> return nil :: any end
type State<T> = { Get: typeof(Get), Compute: typeof(Compute) }

local test = (nil :: any) :: State<number>

local d1 = test:Compute(function(a0: State<number>): boolean return true end)
local ok_d1: boolean = d1:Get()
local wrong_d1: number = d1:Get()
local d2 = d1:Compute(function(a0: State<boolean>): string return "x" end)
local d3 = d2:Compute(function(a0: State<string>): number return 1 end)
local ok_d3: number = d3:Get()
local wrong_d3: boolean = d3:Get()
local d4 = d3:Compute(function(a0: State<number>): boolean return true end)
local d5 = d4:Compute(function(a0: State<boolean>): string return "x" end)
local ok_d5: string = d5:Get()
local wrong_d5: boolean = d5:Get()
local d6 = d5:Compute(function(a0: State<string>): number return 1 end)
local d7 = d6:Compute(function(a0: State<number>): boolean return true end)
local d8 = d7:Compute(function(a0: State<boolean>): string return "x" end)
local ok_d8: string = d8:Get()
local wrong_d8: boolean = d8:Get()
local d9 = d8:Compute(function(a0: State<string>): number return 1 end)
local d10 = d9:Compute(function(a0: State<number>): boolean return true end)
local d11 = d10:Compute(function(a0: State<boolean>): string return "x" end)
local d12 = d11:Compute(function(a0: State<string>): number return 1 end)
local d13 = d12:Compute(function(a0: State<number>): boolean return true end)
local d14 = d13:Compute(function(a0: State<boolean>): string return "x" end)
local d15 = d14:Compute(function(a0: State<string>): number return 1 end)
local d16 = d15:Compute(function(a0: State<number>): boolean return true end)
local d17 = d16:Compute(function(a0: State<boolean>): string return "x" end)
local d18 = d17:Compute(function(a0: State<string>): number return 1 end)
local d19 = d18:Compute(function(a0: State<number>): boolean return true end)
local d20 = d19:Compute(function(a0: State<boolean>): string return "x" end)
local d21 = d20:Compute(function(a0: State<string>): number return 1 end)
local d22 = d21:Compute(function(a0: State<number>): boolean return true end)
local d23 = d22:Compute(function(a0: State<boolean>): string return "x" end)
local d24 = d23:Compute(function(a0: State<string>): number return 1 end)
local d25 = d24:Compute(function(a0: State<number>): boolean return true end)
local d26 = d25:Compute(function(a0: State<boolean>): string return "x" end)
local d27 = d26:Compute(function(a0: State<string>): number return 1 end)
local d28 = d27:Compute(function(a0: State<number>): boolean return true end)
local d29 = d28:Compute(function(a0: State<boolean>): string return "x" end)
local d30 = d29:Compute(function(a0: State<string>): number return 1 end)
local d31 = d30:Compute(function(a0: State<number>): boolean return true end)
local d32 = d31:Compute(function(a0: State<boolean>): string return "x" end)
local d33 = d32:Compute(function(a0: State<string>): number return 1 end)
local d34 = d33:Compute(function(a0: State<number>): boolean return true end)
local d35 = d34:Compute(function(a0: State<boolean>): string return "x" end)
local d36 = d35:Compute(function(a0: State<string>): number return 1 end)
local d37 = d36:Compute(function(a0: State<number>): boolean return true end)
local d38 = d37:Compute(function(a0: State<boolean>): string return "x" end)
local d39 = d38:Compute(function(a0: State<string>): number return 1 end)
local d40 = d39:Compute(function(a0: State<number>): boolean return true end)
local d41 = d40:Compute(function(a0: State<boolean>): string return "x" end)
local d42 = d41:Compute(function(a0: State<string>): number return 1 end)
local d43 = d42:Compute(function(a0: State<number>): boolean return true end)
local d44 = d43:Compute(function(a0: State<boolean>): string return "x" end)
local d45 = d44:Compute(function(a0: State<string>): number return 1 end)
local d46 = d45:Compute(function(a0: State<number>): boolean return true end)
local d47 = d46:Compute(function(a0: State<boolean>): string return "x" end)
local d48 = d47:Compute(function(a0: State<string>): number return 1 end)
local d49 = d48:Compute(function(a0: State<number>): boolean return true end)
local d50 = d49:Compute(function(a0: State<boolean>): string return "x" end)
local ok_d50: string = d50:Get()
local wrong_d50: boolean = d50:Get()