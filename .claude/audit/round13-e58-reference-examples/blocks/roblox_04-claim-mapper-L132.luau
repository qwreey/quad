local function mount(existingScreenGui: ScreenGui, playerGui: Instance)
	local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({}))
	screen.Parent = playerGui -- 허용: 루트의 Parent는 부기 밖
end
