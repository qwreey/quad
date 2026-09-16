--!strict
-- [P2] 보고할 것: 아래 네 줄 각각에 빨간 밑줄이 뜨는지(뜨면 평가된 것, 안 뜨면 조용히 꺼진 것).
-- local Primed = require(script.Parent["02a-lib-primed"])
-- local Bare = require(script.Parent["02b-lib-bare"])
-- Vscode:
-- TypeError: Unknown require: unsupported path
-- TypeError: Value of type 'Instance?' could be nil
-- TypeError: Key '02a-lib-primed' not found in external type 'Instance'
-- Studio:
-- 안정적으로 임포트 됨.
-- 문자열은 두 플랫폼 모두 안정인데, script.Parent 는 문제가 있는듯. sourcemap 없으면 터짐.

local Primed = require("./02a-lib-primed")
local Bare = require("./02b-lib-bare")

-- * Vscode 붙은건 오염된 관측이다. 괄호 안 텍스트 (5) 같은건, 에러가 나는 부분, 언더라인 부분
-- 위 require 로 고치고, Studio 와 Vscode 의 관측은 동일해진다.

-- (2-a) 프라임된 모듈, 소비자가 새 인자로 호출 — 에러가 떠야 정상
-- Studio(5): Type Error: Expected this to be '"q"', but got 'number'
-- * Vscode(Primed.Echo<"q">): TypeError: Unknown type 'Primed.Echo'
-- Vscode(5): TypeError: Expected this to be '"q"', but got 'number'
local a: Primed.Echo<"q"> = 5
-- (2-b) 프라임된 모듈이 만들어 둔 별칭 — 에러가 떠야 정상
-- Studio(Primed.Primed): Type Error: Expected this to be '"seed"', but got 'number'
-- * Vscode(Primed.Primed): TypeError: Unknown type 'Primed.Primed'
-- Vscode(5): TypeError: Expected this to be '"seed"', but got 'number'
local b: Primed.Primed = 5
-- (2-c) 프라임 안 된 모듈 — 리눅스에서는 여기가 조용했다. Studio는?
-- Studio(Bare.Echo2<"q">): Type Error: Expected this to be '"q"', but got 'number'
-- * Vscode(Bare.Echo2<"q">): TypeError: Unknown type 'Bare.Echo2'
-- Studio(5): TypeError: Expected this to be '"q"', but got 'number'
local c: Bare.Echo2<"q"> = 5
-- (2-d) 대조군(타입 함수 아님) — 에러가 떠야 정상
-- Studio(5): Type Error: Expected this to be 'string', but got 'number'
-- * Vscode(5): TypeError: Expected this to be 'string', but got 'number'
-- Vscode(5): TypeError: Expected this to be 'string', but got 'number'
local d: string = 5

return { a, b, c, d }
