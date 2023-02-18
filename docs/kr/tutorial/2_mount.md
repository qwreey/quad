
# 트리를 연결하고 화면에 UI 를 표시하기

일반적으로 *Quad* 모듈에서 모든 Parent 처리는 `Mount` 를 이용합니다. `Mount(to:any,...item:any)->mounts` 함수를 이용하면 다루는 오브젝트가 로블록스 Instance 인지, Quad 확장 클래스인지 상관없이 알아서 Parent 를 처리해 줍니다.

```lua
--- StarterGui 안에 ScreenGui 를 넣고 로컬스크립트로 입력해보세요
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount = Quad.Class,Quad.Mount

local Frame = Class "Frame"

Mount(ScreenGui,
    Frame {
        Name = "Wow!";
    }
    --[[
    , Frame {} , Frame {}
    더많은 오브젝트를 다같이 Mount 할 수 있습니다
    ]]
)
```

편의를 위해서 Mount 함수는 mounts 라는 객체를 반환합니다. 이것을 이용하면 필요에 따라서 Mount 상태를 해제할 수 있습니다.

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount = Quad.Class,Quad.Mount

local Frame = Class "Frame"

local mainFrame = Frame {}
Mount(ScreenGui,mainFrame)

local childFrame = Frame {}
local childFrameMount = Mount(mainFrame,childFrame)
childFrameMount:Unmount()
-- childFrame 은 단순히 .Parent 되는 것을 넘어 메모리에서 사라집니다
-- 즉, Destroy() 가 호출됩니다
```

이 동작은 리스트를 만들 때 유용할 수 있습니다. **다시로드 동작시 직접 제거가 필요하지 않습니다**

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount = Quad.Class,Quad.Mount

local Frame = Class "Frame"

local mainFrame = Frame {}
Mount(ScreenGui,mainFrame)

local lastListMount
local function refreshList()
    if lastListMount then -- 이전 children 을 알아서 제거합니다
        lastListMount:Unmount()
    end

    local children = {}
    for i = 1,10 do
        table.insert(children,Frame { Name = tostring(i) })
    end

    lastListMount = Mount(mainFrame,unpack(children))
end

task.spawn(function()
    while true do
        refreshList()
        task.wait(2)
    end
end)
```

다음과 같이 이전 children 을 간접적으로 제거합니다. 단 ScrollFrame 의 경우 CanvasPosition 이 초기화 되어버리므로 자식들을 `:Unmount()` 하기 전에 위치를 저장하고 `Mount()` 후 불러와야 합니다  
<br>

아직 생성한 오브젝트를 변수에 넣어야하는것이 귀찮아 보이는가요? 이제 `Store.GetObject(id:string)` 에 대해 알아봅시다.  
<br>

[다음 튜토리얼](./3_storeGetObject)
