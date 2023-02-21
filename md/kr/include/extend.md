
`self(name:string)->linker`  
> Extend 메소드 전역에서 사용가능합니다. 링커를 만들며, `PropertyChangedSignal` 를 이어주거나, self 에 원하는 오브젝트를 넣는 용도로 사용됩니다. 자세한 정보는 Render 를 확인해주세요.  

---

==Overwite== ==**REQUIRED**== `#!ts :Render(props:valueStore)`  
<blockquote markdown>

화면에 그려지는 UI 를 만들어지게 하는 함수입니다. `Extend` 가 그려지려면 무조건 있어야합니다.  
이 오브젝트를 만드는데 들어간 프로퍼티 목록을 첫번째 인자로 줍니다. 레지스터 문법이 사용될 수 있습니다.  

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Event = Quad.Event
local Mount = Quad.Mount

local TextButton = Class "TextButton"

local myClass = Class.Extend()
function myClass:Render(props)
    return TextButton {
        [Event "MouseButton1Click"] = function (self,x,y)
            print(("버튼이 %d,%d 에서 눌렸습니다"):format(x,y))
        end;
        Size = props "Size";
        Text = props "Text"; -- 레지스터를 이용합니다
    }
end

local myImported = Class(myClass)
myImported.Size = UDim2.fromOffset(200,200)

local test = myImported {
    Text = "wow"
}
Mount(ScreenGUI, test)

-- 텍스트를 업데이트합니다
while task.wait(1) do
    test.Text = "w"..("o"):rep(#test.Text-1).."w"
end
```

</blockquote>

---

==Overwite== ==Option== `#!ts :Init(props:valueStore)`  
<blockquote markdown>

선택적인 메소드로, Render 가 수행 되기 전에 미리 props 값을 설정할 수 있습니다.

```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local TextButton = Class "TextButton"

local myClass = Class.Extend()
function myClass:Init(props)
    -- Size 값이 없다면 기본값을 사용하도록 합니다.
    props:Default("Size", UDim2.fromOffset(100,100))

    -- 앞에 _ 를 붇여 내부 변수를 만듭니다.
    -- 어디에서나 쓰일 수 있으며 register 에 영향주지 않습니다.
    self._asdf = true
end
function myClass:Render(props)
    return TextButton {
        props "Size"
    }
end

local myImported = Class(myClass)
local myButton = myImported() -- 옵션 없음
print(myButton.Size)
```
</blockquote>

---

==Overwite== ==Option== `#!ts :AfterRender(object:any)`  
<blockquote markdown>

선택적인 메소드로, Render 가 수행 된 후 할 작업을 만들 수 있습니다. 첫번째 인자로 Render 가 반환한 값이 주어집니다.  

```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local TextButton = Class "TextButton"

local myClass = Class.Extend()
function myClass:Render(props)
    return TextButton {
        self "_button"; -- 자기 자신에 이 버튼을 넣습니다
    }
end
function myClass:AfterRender(object)
    print(self._button == object) -- true
end

local myImported = Class(myClass)
myImported() -- 옵션 없음
```
</blockquote>

---

==Overwite== ==Option== `#!ts :Update()`  
<blockquote markdown>

`:Render` 와 `:AfterRender` 를 다시 실행하고, 이전에 있던 자식들을 다시 끌어옵니다.  
이전의 Render 결과는 제거됩니다
```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local TextButton = Class "TextButton"
local count = 0

local myClass = Class.Extend()
function myClass:Render(props)
    print("Rendering!")
    count = count + 1
    return TextButton {
        self "_button";
        Name = tostring(count);
    }
end
function myClass:AfterRender(object)
    print(self._button.Name)
end

local myImported = Class(myClass)
local myButton = myImported()
myButton:Update() -- update
myButton:Update() -- update
myButton:Update() -- update
```
</blockquote>

---

==Overwite== ==Option== `#!ts .Getter.<PropertyName>(self)`  
<blockquote markdown>

값을 얻는데 사용됩니다.
```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local TextButton = Class "TextButton"

local myClass = Class.Extend()
function myClass:Render(props)
    return TextButton {}
end
-- 값을 읽는데 사용할 함수를 등록합니다
function myClass.Getter.Test(self)
    return "Hello World"
end

local myImported = Class(myClass)
print(myImported().Test)
```
</blockquote>

---

==Overwite== ==Option== `#!ts .Setter.<PropertyName>(self,newValue:any)`  
<blockquote markdown>

값을 설정하는데 사용됩니다.
```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local TextButton = Class "TextButton"

local myClass = Class.Extend()
function myClass:Render(props)
    return TextButton {
        self "_button";
        Text = "wow";
    }
end
-- 값을 지정하는데 사용할 함수를 등록합니다
function myClass.Setter.Test(self,newValue)
    self._button.Text = newValue
end
function myClass.Getter.Test(self)
    return self._button.Text
end

local myImported = Class(myClass)
local myButton = myImported()
print(myButton.Test)
myButton.Test = "Hello World"
print(myButton.Test)
```
</blockquote>

---

==Overwite== ==Option== `#!ts .UpdateTriggers.<PropertyName> = boolean?`  
<blockquote markdown>

해당 값을 변경하면 Update 가 수행될지 여부를 지정합니다.
```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local TextButton = Class "TextButton"
local count = 0

local myClass = Class.Extend()
function myClass:Render(props)
    print("Rendering!")
    count = count + 1
    return TextButton {
        self "_button";
        Name = tostring(count);
    }
end
function myClass:AfterRender(object)
    print(self._button.Name)
end
-- 값 변경시 업데이트 여부를 지정합니다
myClass.UpdateTriggers.Test = true

local myImported = Class(myClass)
local myButton = myImported()
myButton.Test = 1 -- update
myButton.Test = 1 -- update
myButton.Test = 1 -- update
```
</blockquote>

---

==Overwite== ==Option== `#!ts :Unload(object)`  
> :Destroy 가 호출될 때 사용됩니다. 따로 선언하지 않아도 연결을 모두 끊고 없에주지만 필요한 경우 직접 없에줄 수 있습니다. object 는 :Render 가 반환한 값입니다

---

`#!ts :GetPropertyChangedSignal(propertyName:string)->Bindable`  
> 값 변경을 연결할 수 있는 `Bindable`을 반환합니다. `:EmitPropertyChangedSignal` 으로 이 시그널을 작동시킬 수 있습니다. 편의상 이 시그널이 작동할 때, 새로운 값이 첫번째 인자로 주어집니다.

---

`#!ts :EmitPropertyChangedSignal(propertyName:string,changedValue:any?)`  
<blockquote markdown>

프로퍼티 변경시 `:GetPropertyChangedSignal` 에 등록된 함수가 실행되도록 이 함수를 호출해 주어야 합니다. 일반적으로 `#!ts self.a = 1` 과 같은 방식으로 바로 값을 설정하는 경우 자동적으로 이 함수가 실행되지만, 텍스트 박스의 텍스트 처럼 객체의 변경사항을 연동해야 하는 경우 이 함수를 사용할 수 있습니다. `changedValue` 는 선택사항이며, 주어지지 않으면 `#!ts self[propertyName]`을 반환합니다.
```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class = Quad.Class
local Mount = Quad.Mount
local Evnet = Quad.Event

local TextBox = Class "TextButton"

local myClass = Class.Extend()
function myClass:Render(props)
    return TextButton {
        self "_box";
        Text = "test";
        Size = UDim2.fromOffset(200,200);
        [Evnet.Prop "Text"] = function (this,newValue)
            self:EmitPropertyChangedSignal("Text",newValue)
        end;
        -- [Evnet.Prop "Text"] = self "Text" 와 동일합니다.
        -- self(name:string) 문법으로 변경 이벤트 역시 링크
        -- 할 수 있습니다.
    }
end
function myClass.Getter.Text(self)
    return self._box.Text
end

local myImported = Class(myClass)
local myButton = myImported()
myButton:GetPropertyChangedSignal("Text"):Connect(function()
    print(myButton.Text)
end)
Mount(ScreenGUI, myButton)
```
</blockquote>
