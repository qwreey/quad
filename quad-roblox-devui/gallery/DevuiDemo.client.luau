--!strict
--[[
	Play-test entry for the devui kit. consumer-kits.project.json maps THIS file alone into StarterPlayerScripts (a
	LocalScript does not run in ReplicatedStorage) and ignores it in the `gallery` copy under ReplicatedStorage.
	Press Play in Studio: the Demo window mounts into PlayerGui with its own overlay layer. The on-device checklist
	(things the Lune mock cannot show) is in the kit README "실기기 체크리스트".
]]
local Demo = require("@game/ReplicatedStorage/quad-roblox-devui/gallery")

Demo.mount()
