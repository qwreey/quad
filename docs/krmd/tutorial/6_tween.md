
# 트위닝

Quad에는 트윈을 도와주는 모듈이 내장되어 있습니다. 이 트윈 모듈은 단순한 Instance들을 넘어서 table 형식도 트윈을 수행할 수 있습니다. 이는 나중에 커스텀 오브젝트를 트윈할 때 유용합니다.  

트윈은 일반적으로 다음과 같이 수행합니다.  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Mount = Quad.Mount
local Tween = Quad.Tween

local Frame = Class "Frame"
Frame "mainFrame" {
    Frame "Child" {
        Position = UDim2.fromOffset(0,0);
        Size = UDim2.fromOffset(20,20)
    };
}

Mount(ScreenGUI, Store.GetObejct("mainFrame"))

local Child = Store.GetObject()
```

트윈 옵션에서 사용할 수 있는 `EasingFunction` 은 다음과 같습니다

{!include/easings.md!}
