local size = q.Source(UDim2.fromOffset(100, 40))
local mod = q.Modifier { Size = size, Visible = true }

local storedSize = mod:Peek<<UDim2>>("Size")   -- Source 핸들 자체가 나온다
local visible = mod:Peek<<boolean>>("Visible") -- true
local missing = mod:Peek<<string>>("Text")     -- nil
