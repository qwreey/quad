# Extend - 확장과 재사용

## Extend 란?

Quad 에서는 로블록스의 `Frame` 이나 `TextButton` 같은 기본 오브젝트만 만들 수 있는것이 아닙니다. Quad 는 자신만의 버튼, 혹은 여러 컴포넌트들을 추상적으로 만들고. 다시 활용할 수 있도록 `Extend` 를 지원합니다.

`Extend` 는 `Register` 와 더불어 Quad 의 가장 중요한 기능으로써, 다음과 같은 장점을 지닙니다.

> 1. 재사용 가능합니다. 나만의 버튼을 만들고, 고치고 싶은 마음이 생겨 고치면 자동으로 사용된 곳들이 업데이트됩니다.  
> 2. 긴 코드를 나누어 코드마다 확실한 목적을 부여해 더 명확한 코드 작성이 가능해집니다.  
> 3. 자신만의 프로퍼티를 만들거나 완전히 원하는대로 오브젝트를 커스터마이징 할 수 있습니다.  
> 4. 함수나 생성기를 직접 만드는 것 보다 일관된 방법을 제공합니다.  

---

## 나만의 클래스를 만들어보자

`Extend` 객체는 다음과 같이 생성합니다.  
```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

-- extend 객체를 만듭니다
local myClass = Class.Extend()
```
일반적으로 Extend 는 한 모듈에 하나씩 넣습니다.  

다음과 같은 코드 구조를 만들어보세요.  
```
 - ScreenGUI
 |-- localscript
    |-- myClass (ModuleScript)
```

=== "localscript"

    ```lua
    local ScreenGUI = script.Parent
    local Quad = require(path.to.module).Init()
    local Mount = Quad.Mount
    local Class = Quad.Class
    local Store = Quad.Store

    local myStore = Store.GetStore("myStore")
    myStore.bgColor = Color3.fromRGB(0,0,0)

    -- Class(require(script.myClass)) 와 같습니다.
    -- 줄여서 Class(script.myClass) 로 쓸 수도 있습니다.
    local myClass = Class(script.myClass)

    -- 프레임에 넣거나 하여도 무방합니다
    -- 일반 오브젝트와 똑같이 id 를 넣고 GetObject 로
    -- 가져올 수도 있습니다
    local main = myClass "main" {
        Testing = 1;
        Text = "Test";
        -- 레지스터 값을 넘겨줄 수도 있습니다.
        -- 받는쪽도 레지스터인 경우 값이 연동됩니다.
        BackgroundColor3 = myStore "bgColor";
    }

    Mount(ScreenGUI,main)
    print(Store.GetObject("main") == main) -- true

    -- 이 값을 바꾸면 연동된 BackgroundColor3 도 바뀔것입니다
    myStore.bgColor = Color3.fromRGB(255,255,255)

    -- 값 변경됨을 연결하기
    main
        :GetPropertyChangedSignal("AbsolutePosition")
        :Connect(function()
            print("AbsolutePosition",main.AbsolutePosition)
        end)
    
    -- main:Update()
    -- 강제로 다시 Render 를 실행하도록 만듭니다.
    ```

=== "localscript.myClass"

    ```lua
    local Quad = require(path.to.module).Init()
    local Class = Quad.Class
    local Event = Quad.Event

    local TextLabel = Class "TextLabel"

    local myClass = Class.Extend()

    -- Init 에는 프로퍼티 리스트가 제공됩니다.
    -- Init 는 없더라도 무방합니다.
    function myClass:Init(props)
        -- 생성된 오브젝트에 프라이빗 값을 만듭니다.
        -- 이름 앞에 _ 가 붇으면 외부에서 사용되는 목적이 아닌
        -- 내부에서 사용되는 목적으로만 사용할 수 있습니다
        -- 이 경우 안전성을 위해 register 를 사용할 수
        -- 없습니다.
        self._testValue = 2

        -- 프로퍼티의 기본값을 정해줄 수 있습니다.
        -- 생성 시 값이 누락된 경우 사용할 값을 정해줄 수 있습니다
        -- 키, 값 으로 구성합니다
        props:Default("Text","Testing Label")
    end

    -- myClass 가 진짜 그려지는 부분입니다.
    -- Render 도 Init 처럼 프로퍼티 리스트가 제공됩니다.
    function myClass:Render(props)
        return TextLabel {
            -- self 에 _label 로 이 TextLabel 을 넣습니다.
            -- 자식 오브젝트에도 사용할 수 있는 문법입니다.
            self "_label";

            -- GetPropertyChangedSignal 가 작동할 수 있도록
            -- 프로퍼티 변경 이벤트를 연결해줍니다
            -- 이 또한 자식 오브젝트에도 사용할 수 있는 문법입니다.
            [Event.Prop "AbsolutePosition"] = self "AbsolutePosition";
            -- 마우스 클릭같은 다른 이벤트를 GetPropertyChangedSignal 에
            -- 연결하려면 :EmitPropertyChangedSignal() 를 호출해주면 됩니다.
            [Event "MouseEnter"] = function (this,x,y)
                -- 키, 값이 들어갑니다. 값이 없으면 self[key] 로 대신합니다.
                self:EmitPropertyChangedSignal("Testing2",1)
            end;

            -- 받은 레지스터를 연동합니다.
            -- 만약 props.BackgroundColor3 만 사용하면
            -- 처음에만 레지스터에서 값을 읽어옵니다.
            -- 따라서 값을 변경해도 변경사항이 적용되지 않습니다.
            BackgroundColor3 = props "BackgroundColor3";

            -- 입력 값과 상관없이 레지스터를 쓸 수 있습니다.
            -- 이 경우 main.Text = "New" 처럼 직접 변경하면
            -- 그 변경이 적용됩니다.
            Text = props "Text";

            -- ... 자식을 넣어도 무방합니다.
        }
    end

    -- function myClass:Unload(object)
    -- :Destroy 가 호출될 때 사용됩니다. 따로 선언하지 않아도
    -- 연결을 모두 끊고 없에주지만 필요한 경우 직접 없에줄 수 있습니다
    -- object 는 :Render 가 반환한 값입니다

    -- AbsolutePosition 값을 반환할 수 있도록 만듭니다
    function myClass.Getter.AbsolutePosition(self)
        return self._label.AbsolutePosition
    end

    -- AbsolutePosition 값을 설정할 수 없도록 만듭니다
    function myClass.Setter.AbsolutePosition(self,newValue)
        -- 필요한 경우 값을 설정하도록 만들 수 있습니다
        error("AbsolutePosition 값은 설정할 수 없습니다")
    end

    -- main.Testing = 2 다음과 같이 값을 변경하면 오브젝트가
    -- 완전히 다시 그려집니다. 즉 업데이트 트리거로 사용합니다.
    myClass.UpdateTriggers.Testing = true

    -- 만든 클래스를 반환해줍시다.
    return myClass
    ```
