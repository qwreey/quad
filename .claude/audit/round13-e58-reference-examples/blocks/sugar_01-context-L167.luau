type Theme = { ButtonBg: Color3 }
local ThemeProvider = q.Context.Provider<<Theme>>("Theme")
local UserProvider = q.Context.Provider<<{ Name: string }>>("User")

-- 리프 컴포넌트 — 필요한 키만 꺼내 쓴다
local function ThemedButton(props: { Context: q.Context }): TextButton
    local theme = props.Context:Get(ThemeProvider)
    return D.TextButton { BackgroundColor3 = theme.ButtonBg }
end

-- 중간 셸 — Theme/User가 뭔지 모른 채 가방만 내려보낸다
local function AppShell(props: { Context: q.Context, Content: Instance }): Frame
    return D.Frame {
        ThemedButton({ Context = props.Context }),
        props.Content,
    }
end

local rootCtx = q.Context()
    :Set(ThemeProvider, { ButtonBg = Color3.fromRGB(40, 40, 40) })
    :Set(UserProvider, { Name = "q" })

local maybeUser: { Name: string }? = rootCtx:Peek(UserProvider) -- 없으면 nil
local shell = AppShell({ Context = rootCtx, Content = D.Frame {} })
