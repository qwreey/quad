
# Register - 값 변경 연동

???+ info "읽기 전..."
    모듈 설정시 `#!ts .Init()` 처럼 QuadId 란을 비워두는 경우 `#!ts Store.GetStore` 가 코드를 넘어 공유되지 않습니다  
    하지만 `#!ts .Init("Project1")` 처럼 아이디를 부여하는 경우 **다른 모듈, 로컬스크립트가 접근하더라도 같은 QuadId 를 가졌다면 `#!ts Store.GetStore` 는 공유됩니다**  

---

## 레지스터

레지스터는 한 값이 변경될 때, 그 값을 사용한 곳이 업데이트 될 수 있도록 만들어주는 ==Quad 의 주요 기술입니다.== 추후 설명될 `Class.Extend` 와도 같이 사용됩니다.  

레지스터는 이러한 시나리오에서 사용될 수 있습니다.  

> 1. UI 의 여러 오브젝트를 한번에 페이드 아웃 혹은 페이드 인 시키는 경우.  
> 2. 가변 크기의 UI 를 업데이트 시키는 경우.  
> 3. 여러 오브젝트들을 한꺼번에 트윈시키는 경우.  
> 4. 다크테마/화이트테마 변경할 수 있게 만드는 경우.  

이외에도 레지스터의 활용 방법은 무궁무진합니다. 레지스터의 사용법은 다음과 같습니다.  

```lua
local myStore = Store.GetStore("myStore")
myStore.color = Color3.fromRGB(255,255,255)
Frame { BackgroundColor3 = myStore "color" }
-- 연동된 프레임도 업데이트 됩니다
myStore.color = Color3.fromRGB(0,0,0)
```

???+ Warning "주의"

    구현의 복잡성의 이유로 레지스터는 오브젝트 생성시에만 등록할 수 있습니다.

    ```lua
    local myFrame = Frame{}
    Frame.BackgroundColor3 = myStore "color"
    ```
    위처럼 사용할 수 없습니다.

    ```lua
    local myFrame = Frame{}
    Apply (myFrame) {
        BackgroundColor3 = myStore "color";
    }
    ```

> 1. 스토어를 생성함.  
> 2. 기본 값을 설정함.  
> 3. 스토어를 호출해 레지스터를 얻어 등록함.  

예시 코드로 정확하게 확인해 볼 수 있습니다  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Store = Quad.Store
local Class = Quad.Class
local Mount = Quad.Mount

-- 레지스터를 만들 수 있는 테이블을 만듭니다.
-- 여기에 담아내는 값을 업데이트 하는 경우 레지스터로 연결된
-- 오브젝트들도 같이 업데이트됩니다.
local myStore = Store.GetStore("myStore")
local TextLabel = Class "TextLabel"

myStore.Text = "0 초 지남"
myStore.Color = Color3.fromRGB(255,100,255)

TextLabel "mainLabel" {
    Size = UDim2.fromOffset(100,200);
    -- myStore 의 Text 값이 변경됨을 추적하고, Text 값을
    -- 업데이트 시킵니다.
    Text = myStore "Text";

    -- 이것은 레지스터를 사용하는것이 아니라 단순히 값만
    -- 불러와 넣어주는 것입니다. 자동 업데이트가 가능하지 않습니다.
    BackgroundColor3 = myStore.Color;
}

Mount(ScreenGUI, Store.GetObject("mainLabel"))

-- 바꾸더라도 레지스터를 사용하지 않아 반영되지 않습니다
myStore.Color = Color3.fromRGB(255,255,255)

local Count = 1
while task.wait(1) do
    -- 값을 업데이트 합니다. 텍스트 라벨도
    -- 자동적으로 업데이트 됩니다.
    myStore.Text = Count .. " 초 지남"
    Count = Count + 1
end
```

---

## 레지스터 메소드

레지스터에는 여러가지 메소드가 담겨있습니다. 이 메소드를 사용하면 레지스터를 보다 더 다양하게 활용할 수 있습니다.  

{!include/register.md!}
