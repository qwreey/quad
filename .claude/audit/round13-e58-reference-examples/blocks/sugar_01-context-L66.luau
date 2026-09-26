type Theme = { ButtonBg: Color3 }

-- (1) 캐스트
local ThemeProvider = q.Context.Provider("Theme") :: q.Provider<Theme>
-- (2) 명시적 타입 인자
local UserProvider = q.Context.Provider<<{ Name: string }>>("User")
