-- 백엔드 (quad-roblox / mock): holdLifetime
gchold[value] = true                                   -- 강참조: value는 최소한 inst만큼 산다
BindData:SetWeak(value, "gchold", gchold)              -- 둘 다 weak — 섬은 위 클로저가 살린다
BindData:SetWeak(value, "gcconn", InstData:GetWeak(inst, "gcconn"))
