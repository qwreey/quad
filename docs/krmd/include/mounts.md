`#!ts :Unmount()`  
> 이렇게 하면 마운트된 Instance 를 지워버립니다. Quad 는 안전한 메모리 관리를 위해 gc 의 기능에 의존하므로, gc 시간차로 인해 `#!ts Store.GetObject` 에서 오브젝트가 사라지는데 시간이 걸릴 수 있습니다.  

```lua
-- 용법
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount = Quad.Class,Quad.Mount

local Frame = Class "Frame"

local mainFrame = Frame {}
Mount(ScreenGui,mainFrame)

local childFrame = Frame {}
local childFrameMount = Mount(mainFrame,childFrame)
childFrameMount:Unmount()
-- childFrame 은 단순히 .Parent = nil 되는 것을 넘어 메모리에서 사라집니다
-- 즉, Destroy() 가 호출됩니다
```

---

`#!ts :Add(item:any)`  
> Mount 에 오브젝트를 추가합니다. 처음 설정한 `to` 값을 따라 부모가 결정됩니다.  

이 동작은 리스트를 만들 때 유용할 수 있습니다. *다시로드 동작시 직접 제거가 필요하지 않습니다*

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount = Quad.Class,Quad.Mount

local Frame = Class "Frame"

local mainFrame = Frame {}
Mount(ScreenGui, mainFrame)

local lastListMount = Mount(mainFrame)
local function refreshList()
    lastListMount:Unmount() -- 이전 children 을 알아서 제거합니다
    for i = 1,10 do
        lastListMount:Add(Frame { Name = tostring(i) })
    end
end

task.spawn(function()
    while true do
        refreshList()
        task.wait(2)
    end
end)
```

다음과 같이 이전 children 을 간접적으로 제거하고 새로운 오브젝트를 추가합니다. 단 `ScrollFrame` 의 경우 `CanvasPosition`이 초기화 되어버리므로 자식들을 `#!ts :Unmount()` 하기 전에 위치를 저장하고 다시 불러와야 합니다  

