
# 언어관리

???+ info "읽기 전..."
    모듈 설정시 `#!ts .Init()` 처럼 QuadId 란을 비워두는 경우 `Lang` 기능이 코드를 넘어 공유되지 않습니다  
    하지만 `#!ts .Init("Project1")` 처럼 아이디를 부여하는 경우 **다른 모듈, 로컬스크립트가 접근하더라도 같은 QuadId 를 가졌다면 `Lang` 은 공유됩니다**  

---

## 언어관리

Quad 에는 귀찮은 언어관리를 자동으로 해주는 기능이 내장되어 있습니다.  
이 기능은 register 와 연동해 적은 줄의 코드로 변하는 텍스트도 언어에 맞게 출력되도록 만들 수 있습니다.  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Store = Quad.Store
local Mount = Quad.Mount
local Event = Quad.Event
local Lang = Quad.Lang
local Class = Quad.Class

local TextButton = Class "TextButton"

local myStore = Store.GetStore("myStore")
myStore.count = 0

Lang.New("TimePassed",{
    [Lang.Locales.Korean] = "{count}초 지났어요";
    [Lang.Locales.Default] = function (options)
        -- 함수 또한 등록할 수 있습니다.
        if options.count > 1 then
            return ("%d seconds passed"):format(options.count)
        else
            return ("%d second passed"):format(options.count)
        end
    end;
})

TextButton "mainButton" {
    Size = UDim2.fromOffset(100,100);
    Text = Lang "TimePassed" {
        -- count = 1 일반적인 값도 사용가능합니다
        count = myStore "count";
    };
    [Event "MouseButton1Click"] = function()
        -- 클릭시 언어가 변경됩니다
        if Lang.CurrentLocale == Lang.Locales.Default then
            Lang.CurrentLocale = Lang.Locales.Korean
        else
            Lang.CurrentLocale = Lang.Locales.Default
        end
    end
}
Mount(ScreenGUIk,Store.GetObject("mainButton"))

while task.wait(1) do
    myStore.count = myStore.count + 1
end
```

---

## Locale 목록

로케일 값들은 `#!ts Lang.Locales`에서 가져올 수 있으며, 사용가능한 로케일 목록은 다음과 같습니다.  

> {!include/locales.md!}
