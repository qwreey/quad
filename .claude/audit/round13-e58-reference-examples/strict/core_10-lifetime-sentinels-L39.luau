--!strict
-- E58 strict (generated) — core_10-lifetime-sentinels-L39
-- ==== page prologue core/10-lifetime-sentinels.md (core_10-lifetime-sentinels-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block core/10-lifetime-sentinels.md:39 (line offset marker) ====
local function Card(props)
	return D.Frame {
		props.Modifier or q.None, -- 숫자 키 자리: nil을 넣으면 뒤 항목이 사라진다
		D.TextLabel { Text = props.Title },
	}
end
