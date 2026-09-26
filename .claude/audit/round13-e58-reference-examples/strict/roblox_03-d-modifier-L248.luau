--!strict
-- E58 strict (generated) — roblox_03-d-modifier-L248
-- ==== page prologue roblox/03-d-modifier.md (roblox_03-d-modifier-L22.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local RobloxModule = require("../../../../quad-roblox/src") --[[E58: 문서의 자리표시 <quad-roblox 모듈>]] -- 클래스별 Modifier 타입의 유일한 공개 경로(루트 재수출 — 생성 모듈 자체는 require 경로가 없습니다)
local D = q.Declaration
-- ==== doc block roblox/03-d-modifier.md:248 (line offset marker) ====
type ThemedProps = {
	read Modifier: RobloxModule.IntoTextButton?,
	read Text: string?,
}

local function Themed(props: ThemedProps): TextButton
	return D.TextButton({
		if props.Modifier then props.Modifier:AsTextButton() else q.None,
		Text = props.Text or "",
	})
end

Themed({ Modifier = D.Modifier.GuiObject():ZIndex(2), Text = "a" }) -- 조상 클래스도 OK
Themed({ Modifier = D.Modifier.TextButton():TextSize(18) })          -- 자기 클래스(항등 캐스트)
