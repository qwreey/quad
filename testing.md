# 개채에 대해서 어떻게 저장하고 다시 불러오는가

글로벌 스토리지 계념이 있습니다  
```lua
local quad = require(script.Parent.quad);
local render = quad.init();
local class = render.class;
local mount = render.mount;
local store = render.store;

local frame = class "Frame";
mount(script.Parent,
    frame "PutIdHere" {
        Size = UDim2.fromOffset(45,45);
        frame "Child" {
            Size = UDim2.fromOffset(45,45);
        };
        frame "Child" {
            Size = UDim2.fromOffset(45,45);
        };
        frame "Child" {
            Size = UDim2.fromOffset(45,45);
        };
    }
);

-- you can get first object by store.get Object
print(store.getObject "PutIdHere");
-- you can set objects properties like this
store.getObjects "Child".BackgroundColor = Color3.fromRGB(255,0,0);
-- you can get each child with forEach method
store.getObjects "Child":forEach(function (this)
    print(this);
end);
```

# 클래서
```lua
-- 새로운 클래스를 확장한다
local myButton = class.extend();

-- 클래스를 초기화합니다, 메타 테이블에 영향을 받지 않습니다
-- 선택적입니다
function myButton:init(prop)
    prop.Text = prop.Text or "Hello world"; -- 기본 값을 설정합니다
end

-- 실제 그려질 때 이다
function myButton:render(prop)
    -- if you make value in self, you must be use
    -- prefix '_', if you missing that, it will make
    -- overflow on meta method!!
    self._someValue = 2;
    return textButton {
        frame {
            [event.created] = function (this)
                self._holder = this; -- set holder for child instance
            end;
        };
        --Text = prop.Text; -- 이렇게 하면 업데이트 될 때 다시 그려짐
        Text = prop "Text":default("Hello world"); -- 이렇게 하면 업데이트 될 때 프로퍼티만 고침
        [event "MouseButton1Click"] = {
            self = self;
            func = prop[event "MouseButton1Click"];
        };
        [event.created] = function (this)
            self._button;
        end;
    };
end
myButton.ignore.Text = true;

function myButton.getter:MouseButton1Click(object)
    return (self._button or object).MouseButton1Click;
    --      ^ this is same  ^
end

function myButton.setter:Count(v,object)
    self._someValue = v;
end
function myButton.getter:Count(object)
    return self._someValue;
end

-- this is option, you can set destroy functions
function myButton:unload(object)
    print("remove myButton",object,self);
    object:Destroy();
end

-- DONT MAKE THIS! this is will broken class system
-- function myButton.new()
-- end

```