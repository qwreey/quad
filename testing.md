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