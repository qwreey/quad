--!strict
-- E58 strict (generated) — sugar_05-fallback-traceback-L79
-- ==== page prologue sugar/05-fallback-traceback.md (sugar_05-fallback-traceback-L13.luau) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block sugar/05-fallback-traceback.md:79 (line offset marker) ====
local function ProfileCard(props: { Name: string }): Instance
    return D.TextLabel { Text = props.Name }
end

local SafeProfileCard = q.Traceback(ProfileCard, function(err: any, trace: string): Instance
    warn("ProfileCard 렌더링 실패:", err, "\n", trace)
    return D.Frame {
        BackgroundColor3 = Color3.fromRGB(80, 20, 20),
        D.TextLabel {
            Text = "프로필을 불러올 수 없습니다.",
            TextColor3 = Color3.fromRGB(255, 100, 100),
        },
    }
end)

local card: Instance = SafeProfileCard({ Name = "q" })
