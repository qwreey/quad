
# 반복되는 속성값을 줄이기

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount,Store = Quad.Class,Quad.Mount,Quad.Store

local Frame = Class "Frame"

Frame "mainFrame" {
    Size = UDim2.fromScale(1,1);
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
    };
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
        Position = UDim2.fromOffset(30,0);
    };
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
        Position = UDim2.fromOffset(60,0);
    };
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
        Position = UDim2.fromOffset(90,0);
    };
}

Mount(ScreenGUI,Store.GetObject("mainFrame"))
```
