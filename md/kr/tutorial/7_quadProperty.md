
# QuadProperty - 특수 프로퍼티

???+ Failure "주의사항"
    특수 프로퍼티는 `Tween` 이 지원되지 않습니다. 그러나 `register`의 `#!ts :Tween()`의 경우 호환되므로, 특수 프로퍼티 값을 트윈하려면 향후 설명되는 `register` 와 함깨 사용해야합니다.
    > `#!ts Tween.RunTween`, `#!ts Tween.RunTweens` 와는 같이 사용할 수 없습니다.

---

## 특수한 프로퍼티

Quad 에서는 편리성을 위해 일부 특수 프로퍼티를 사용할 수 있습니다.  
*이 모든 특수 프로퍼티는 향후 소개되는 `register`와 함깨 사용할 수 있습니다*  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Mount = Quad.Mount

local Frame = Class "Frame"
local ImageFrame = Class "ImageFrame"
ImageFrame.BackgroundTransparency = 1

Frame "mainFrame" {
    Size = UDim2.fromOffset(200,200);
    PaddingAllOffset = 50; -- Padding 을 50 씩 모든 방향으로 줍니다
    BackgroundColor3 = Color3.fromRGB(40,40,40);
    ImageFrame {
        ImageColor3 = Color3.fromRGB(60,60,60);
        RoundSize = 16; -- 이미지로 라운드 프레임을 만듭니다
        Size = UDim2.fromScale(1,1);
        ImageFrame {
            BackgroundColor3 = Color3.fromRGB(80,80,80);
        };
    };
}
Mount(ScreenGUI, Store.GetObject("mainFrame"))
```

사용할 수 있는 프로퍼티는 다음과 같습니다.  

{!include/quadProperty.md!}
