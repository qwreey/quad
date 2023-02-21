
# 반복되는 속성값을 줄이기

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Mount = Quad.Mount
local Style = Quad.Style

local Frame = Class "Frame"

-- 새로운 스타일을 하나 만듭니다
local myStyle = Style {
    Size = UDim2.fromOffset(20,20);
    BackgroundColor3 = Color3.fromRGB(255,255,0);
    BackgroundTransparency = 0.5;
}

Frame "mainFrame" {
    Size = UDim2.fromScale(1,1);
    Frame "Child" {
        myStyle; -- 스타일을 적용합니다!
    };
    Frame "Child" {
        Position = UDim2.fromOffset(30,0);
        myStyle;
    };
    Frame "Child" {
        Position = UDim2.fromOffset(60,0);
        myStyle;
    };
    Frame "Child" {
        Position = UDim2.fromOffset(90,0);
        -- 스타일은 덮어써 질 수 있습니다.
        BackgroundColor3 = Color3.fromRGB(255,0,0);
        myStyle;
    };
}

Mount(ScreenGUI,Store.GetObject("mainFrame"))
```

`#!ts Style`을 사용하면 많은 양의 속성을 하나에 변수로 집어넣을 수 있습니다. `#!ts Style`을 사용해서 많은 양의 코드를 줄여보세요  

또, `#!ts Style`에는 타겟 id를 지정해줄 수 있습니다  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Mount = Quad.Mount
local Style = Quad.Style

local Frame = Class "Frame"

-- 여기에는 & 나 , 가 적용되지는 않습니다!
Style "Child" {
    Size = UDim2.fromOffset(20,20);
    BackgroundColor3 = Color3.fromRGB(255,255,0);
    BackgroundTransparency = 0.5;
}

-- 단, Style은 먼저 선언해야합니다, Frame을 먼저 만들고
-- Style을 선언하면 적용되지 않습니다.
Frame "mainFrame" {
    Size = UDim2.fromScale(1,1);
    Frame "Child" {};
    Frame "Child" { Position = UDim2.fromOffset(30,0) };
}

Mount(ScreenGUI,Store.GetObject("mainFrame"))
```

`#!ts Style(id:string){ any }`를 이용해 스타일을 선언해주면 나중에 해당 id를 가진 오브젝트 생성시 해당 스타일이 적용됩니다.
