local base = q.Modifier { BackgroundTransparency = 1 }
local accent = q.Modifier { BackgroundTransparency = 0.5 }
local box = D.Frame { base, accent, Name = "Box" } -- accent가 이겨 0.5
