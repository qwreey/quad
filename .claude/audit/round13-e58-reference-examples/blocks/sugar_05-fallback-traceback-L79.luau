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
