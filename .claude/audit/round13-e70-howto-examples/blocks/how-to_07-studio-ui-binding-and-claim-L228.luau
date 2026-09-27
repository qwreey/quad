local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({ rows }))
screen.Parent = player:WaitForChild("PlayerGui") -- 허용: 루트의 Parent는 부기 밖
