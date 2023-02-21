
# Event - 이벤트 핸들링

## 이벤트 등록하기

`MouseButton1Click` 혹은 `GetPropertyChangedSignal` 같은 로블 기본 이벤트를 간단하게 등록하고 싶으신가요? Event 를 이용해보세요.  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Mount = Quad.Mount
local Event = Quad.Event
local Store = Quad.Store

local TextButton = Class "TextButton"
local Count = 0

TextButton "mainButton" {
    Text = "0 번 클릭했습니다";
    [Event "MouseButton1Click"] = function(self,x,y)
        Count = Count + 1
        self.Text = Count .. " 번 클릭했습니다"
    end;
}
Mount(ScreenGUI, Store.GetObject("mainButton"))
```

---

## 이밴트 리스트

적용가능한 Event 들은 다음과 같습니다  

{!include/events.md!}
