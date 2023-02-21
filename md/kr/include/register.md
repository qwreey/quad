
`register` 특수 메소드가 적용되는 순서는 다음과 같습니다.  

`#!ts :Add(value:any)->register`
> 값에 더하기를 취합니다. 음수형태가 제공되는 경우 빼기 처럼 작동합니다.  
> `number`, `Udim`, `UDim2`, `Color3`, `Vector2` 등 더할 수 있는 모든것을 사용할 수 있습니다  
> *주의 : 구조의 복잡성을 피하고자, 여러번 호출시 가장 마지막 호출된 것만 사용됩니다*
```lua
-- 용법
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Store = Quad.Store
local Class = Quad.Class
local Mount = Quad.Mount

local Frame = Class "Frame"
local myStore = Store.GetStore("myStore")

myStore.pos = UDim2.fromOffset(100,0)

Frame "mainFrame" {
    Position = myStore "pos":Add(UDim2.fromOffset(0,100));
}
Mount(ScreenGUI, Store.GetObject("mainFrame"))

while true do
    myStore.pos = myStore.pos + UDim2.fromOffset(10,0)
    task.wait(2)
end
```

---

`#!ts :With((store:valueStore, newValue:any, key:string)->())->register`  
<blockquote markdown>

함수 또는 테이블에서 값을 가져옵니다. Add 보다 나중에 수행됩니다.  
첫번째 값에는 편의상 스토어 값이 제공되며, 새로운 값과, 바뀐 값에 대한 키가 제공됩니다  

=== "간략한 용법"

    ```lua
    myStore "size":With(function (_,value)
        return value * 2
    end)
    ```

=== "예제 - 함수"

    `width` 값에 맞춰 자동으로 UI 가 업데이트되도록 만듭니다.  

    ```lua
    local ScreenGUI = script.Parent
    local Quad = require(path.to.module).Init()
    local Store = Quad.Store
    local Class = Quad.Class
    local Mount = Quad.Mount

    local Frame = Class "Frame"
    local myStore = Store.GetStore("myStore")

    myStore.topbarSize = 60
    myStore.width = 200

    -- 레지스터를 변수로 두고 사용합니다
    local listItemSize = myStore "width":With(function()
        return UDim2.fromOffset(myStore.width,60)
    end)

    Frame "mainFrame" {
        Class "UIListLayout" { SortOrder = Enum.SortOrder.LayoutOrder };

        -- 사이즈가 width 에 맞게 업데이트됩니다
        Size = myStore "width":With(function ()
            return UDim.fromOffset(store.width,400)
        end);

        Frame "Topbar" {
            LayoutOrder = 1;
            BackgroundColor3 = Color3.fromRGB(255,0,0);
            -- 이렇게 여러 값을 묶어서 두 값이 변경됨, 혹은 그이상을
            -- 만들 수 있습니다.
            Size = myStore "topbarSize,width":With(function()
                return UDim2.fromOffset(myStore.width,myStore.topbarSize)
            end);
        }
        Frame "ListItem" {
            LayoutOrder = 2;
            BackgroundColor3 = Color3.fromRGB(0,255,0);
            Size = listItemSize;
        };
        Frame "ListItem" {
            LayoutOrder = 3;
            BackgroundColor3 = Color3.fromRGB(0,0,255);
            Size = listItemSize;
        };
    }

    Mount(ScreenGUI, Store.GetObject("mainFrame"))

    -- width 값을 변경해보세요
    while true do
        myStore.width = myStore.width + 10
        task.wait(1)
    end
    ```

=== "예제 - 테이블"

    `colors` 테이블 안에 있는 색깔들을 돌아가며 보여줍니다.  

    ```lua
    local ScreenGUI = script.Parent
    local Quad = require(path.to.module).Init()
    local Store = Quad.Store
    local Class = Quad.Class
    local Mount = Quad.Mount

    local Frame = Class "Frame"
    local myStore = Store.GetStore("myStore")

    local colors = {
        Color3.fromRGB(255,255,255);
        Color3.fromRGB(255,255,0);
        Color3.fromRGB(0,255,255);
        Color3.fromRGB(255,0,255);
        Color3.fromRGB(255,0,0);
        Color3.fromRGB(0,255,0);
        Color3.fromRGB(0,0,255);
    }
    myStore.color = 1

    Frame "mainFrame" {
        Size = UDim2.fromOffset(200,200);
        -- colors 에서 인덱싱해 값을 가져옵니다
        BackgroundColor3 = myStore "color":With(colors);
    }
    Mount(ScreenGUI, Store.GetObject("mainFrame"))

    -- 인덱스를 순회합니다
    while task.wait(1) do
        myStore.color = (i-1)%(#colors)+2
    end
    ```

???+ Warning "주의"
    구조의 복잡성을 피하고자, 여러번 호출시 가장 마지막 호출된 것만 사용됩니다
</blockquote>

---

`#!ts :Tween(options:TweenOptions)->register`  
<blockquote markdown>

트윈을 이용해 변경사항을 적용합니다(처음 오브젝트 생성시에는 적용되지 않음) 옵션은 Tween 문서에 나와있는 옵션과 같습니다.

=== "간략한 용법"

    ```lua
    -- Tween 옵션을 넣을 수 있습니다
    myStore "size":Tween{ Time = 2 }
    ```

=== "예제 - 한꺼번에 이동"

    프레임을 한꺼번에 움직입니다.

    ```lua
    local ScreenGUI = script.Parent
    local Quad = require(path.to.module).Init()
    local Store = Quad.Store
    local Class = Quad.Class
    local Mount = Quad.Mount
    local Style = Quad.Style

    local Frame = Class "Frame"
    local myStore = Store.GetStore("myStore")
    myStore.pos = UDim2.fromOffset(50,0)
    Style "TweenFrame" {
        Size = UDim2.fromOffset(50,50);
        BackgroundColor3 = Color3.fromRGB(255,100,255);
    }

    Frame "mainFrame" {
        BackgroundColor3 = Color3.fromRGB(255,255,255);
        Size = UDim2.fromOffset(500,500);
        Frame "TweenFrame" {
            Position = myStore "pos":Tween{Time = 2};
        };
        Frame "TweenFrame" {
            Position = myStore "pos"
                :Add(UDim2.fromOffset(0,100))
                :Tween{Time = 2};
        };
        Frame "TweenFrame" {
            Position = myStore "pos"
                :Add(UDim2.fromOffset(0,200))
                :Tween{Time = 2};
        };
        Frame "TweenFrame" {
            Position = myStore "pos"
                :Add(UDim2.fromOffset(0,300))
                :Tween{Time = 2};
        }
    }

    Mount(ScreenGUI, Store.GetObject("mainFrame"))

    local on = false
    while true do
        on = not on
        myStore.pos = on and UDim2.fromOffset(400,0) or UDim2.fromOffset(50,0)
        task.wait(1.5) -- 트윈은 덮어 쓸 수 있습니다
        -- 따라서 2 초인 길이보다 더 빨리 바꿔도 오류가 일어나지 않습니다
    end
    ```
???+ Warning "주의"
    구조의 복잡성을 피하고자, 여러번 호출시 가장 마지막 호출된 것만 사용됩니다
</blockquote>

---

`#!ts :Default(value:any)->register`  
<blockquote markdown>

기본값을 정합니다. 만약 값이 `#!lua nil` 인 경우 이 값을 사용하게 됩니다. Add 나 With 등 다른것에 영향받지 않습니다.  
```lua
-- 용법
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Store = Quad.Store
local Class = Quad.Class
local Mount = Quad.Mount

local Frame = Class "Frame"
local myStore = Store.GetStore("myStore")

Frame "mainFrame" {
    Size = UDim2.fromOffset(200,200);
    -- color 값이 없으므로 Default 안의 값이 사용됩니다.
    BackgroundColor3 = myStore "color"
        :Default(Color3.fromRGB(255,0,0));
}

Mount(ScreenGUI, Store.GetObject("mainFrame"))

task.wait(5)
myStore.color = Color3.fromRGB(0,255,0)
```
???+ Warning "주의"
    + 처음 오브젝트가 생성될 때에만 이 값이 사용됩니다.
    + 구조의 복잡성을 피하고자, 여러번 호출시 가장 마지막 호출된 것만 사용됩니다.
</blockquote>

---

`#!ts :Register(<INPUT>(store:valueStore, newValue:any, key:string)->())->INPUT`  
<blockquote markdown>

레지스터에 함수를 등록합니다. 값이 변경되면 함수가 실행됩니다. 첫번째 값에는 편의상 스토어 값이 제공되며, 새로운 값과, 바뀐 값에 대한 키가 제공됩니다  

`newValue` 에는 `:Add`, `:With`, `:Tween`, `:Default` 가 따로 계산되지 않으며, 설정된 값을 아무 가공 없이 제공합니다  

=== "간략한 용법"

    ```lua
    myStore.test = 1
    -- 반환 값은 입력으로 넣은 함수입니다. !꼭 저장해야합니다
    -- :Register 는 함수가 사라지지 않도록 값을 유지하지 않습니다
    -- 만약 버릴 경우 일정 시간 뒤 연결이 끊어질 수 있습니다
    local func = myStore "test":Register(function(_,newValue)
        -- 값 변경시 출력됩니다
        print(newValue)
    end)
    myStore.test = 2
    ```


=== "예제 - 여러 변경사항 추적"

    `#!ts myStore.test1`, `#!ts myStore.test2` 가 변화하면 print 함수를 실행합니다.

    ```lua
    local Quad = require(path.to.module).Init()
    local Store = Quad.Store

    local myStore = Store.GetStore("myStore")

    myStore.test1 = 1
    myStore.test2 = "Hello"

    local func = myStore "test1,test2":Register(function()
        print(myStore.test1,myStore.test2)
    end)

    myStore.test1 = 2
    ```
???+ Warning "주의"
    Register 안에 들어간 함수는 GC 안정성을 위해서 약한 참조로 저장됩니다. 따라서 함수를 저장해야합니다.
</blockquote>

