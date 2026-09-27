local themeColor = q.Source(Color3.fromRGB(255, 0, 0))

-- 빌더 체인
local dynamicStyle = D.Modifier.Frame():BackgroundColor3(themeColor)

-- 초기 필드 테이블도 같은 값
local dynamicStyle2 = D.Modifier.Frame { BackgroundColor3 = themeColor }
