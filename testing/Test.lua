-- 모듈 위치로 알맞게 변경해주세요
local Quad = script.Parent.Quad
local tracker = require(Quad.tracker)

local module = {}
local function reload()
    if module.unload then pcall(module.unload) end
    if module.testingModule then pcall(module.testingModule.Destroy,module.testingModule) end
    module.testingModule = script.Parent:Clone()
    module.testingModule.Parent = script.Parent.Parent
    module.testingModule.Archivable = false
    module.testingModule.Name = module.testingModule.Name .. "_TESTING"
    module.unload = require(module.testingModule)
end

-- 자동 리로드를 켭니다. 이미 켜져있으면 다시 로드합니다
function module.load()
    reload()
    if not module.autoreload then
        module.autoreload = tracker.new(script.Parent)
        module.autoreload:init(); wait()
        module.autoreload:connect("updated",reload)
    end
end

-- 자동 리로드를 끄고 테스트로 생긴것을 지웁니다
function module.unload()
    if module.autoreload then pcall(module.autoreload.deinit,module.autoreload) end
    if module.unload then pcall(module.unload) end
    if module.testingModule then pcall(module.testingModule.Destroy,module.testingModule) end
    module.autoreload = nil
    module.unload = nil
    module.testingModule = nil
end

return module
