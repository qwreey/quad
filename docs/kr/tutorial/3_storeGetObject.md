
# 오브젝트에 아이디 부여하기, 그리고 사용하기

읽기 전...
> **다른 모듈, 로컬스크립트가 접근하더라도 같은 QuadId 를 가졌다면 Store 는 공유됩니다**  
> Quad.Init(QuadId:string?)  
> 필요에 따라 다른 모듈에서의 오브젝트를 가져오는것을 막고싶다면 QuadId 를 모듈마다 다르게 설정하세요.  

**변수에 만들어진 오브젝트를 하나하나 저장해???** 그게 편할리가 없죠. 오브젝트에 아이디를 넣고 사용해봅시다.

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount,Store = Quad.Class,Quad.Mount,Quad.Store

local Frame = Class "Frame"

Frame "mainFrame" {
    Size = UDim2.fromScale(1,1);
}

Mount(ScreenGUI,Store.GetObject("mainFrame"))
```

아이디에 허용되는 글자는 변수명과 같습니다. 일반적으로 대소문자, 숫자, 언더바(_) 를 허용합니다.  
오브젝트 생성시 `Frame "mainFrame" {}` 와 같이 id 값을 지정해 준다면 생성된 오브젝트는 그 아이디를 가지게 됩니다.  
`Store.GetObject(id:string)->Object` 는 생성된 객체중 가장 첫번째의 id 가 일치하는 오브젝트를 반환해 줍니다. 만약 원한다면

```lua
local index = 1
Frame ("mainFrame" .. index) {}
print(Store.GetObject("mainFrame" .. index))
```

처럼 생성이나 가져오기에서 식을 만들어 넣을 수도 있습니다.  

## 다량의 오브젝트를 다루기

또한, Quad 는 다량의 오브젝트를 다루기 편하도록 `Store.GetObjects(id:string)->objectList` 라는 함수를 가지고 있습니다.  

> 주의 : *GetObjects 의 반환값인 objectList 는 캐시해서는 안됩니다. objectList 를 local 에 넣고 계속해서 유지시키지 마십시오, 반환값은 자동으로 업데이트 되지 않습니다. 반환값을 바로바로 사용하는 것이 이상적입니다.*

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount,Store = Quad.Class,Quad.Mount,Quad.Store

local Frame = Class "Frame"

Frame "mainFrame" {
    Size = UDim2.fromScale(1,1);
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
    };
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
        Position = UDim2.fromOffset(30,0);
    };
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
        Position = UDim2.fromOffset(60,0);
    };
    Frame "Child" {
        Size = UDim2.fromOffset(20,20);
        Position = UDim2.fromOffset(90,0);
    };
}

Mount(ScreenGUI,Store.GetObject("mainFrame"))

-- 값을 설정할 수 있습니다. 그러니 값을 읽거나 :Connect 할 수는 없습니다
Store.GetObjects("Child").Size = UDim2.fromOffset(30,30)

-- 필요에 따라 Store.GetObjects("Child") 를 pairs 에 넣어 for 문을 사용하거나
-- :Each , :EachAsync , :IsEmpty 함수를 이용할 수 있습니다
task.spawn(function()
    while true do
        Store.GetObjects("Child"):Each(function (item,index)
            item.BackgroundColor3 = Color3.fromRGB(
                math.random(0,255),
                math.random(0,255),
                math.random(0,255)
            )
        end)
        task.wait(1)
    end)
end
```

`Store.GetObjects()` 의 반환 `objectList` 의 메소드들은 다음과 같습니다.  

:Each((item:any,index:number)->())  
> 일반적인 반복입니다. for 를 사용하는것과 효과가 같으나 함수를 이용합니다  

:EachAsync((item:any,index:number)->())  
> 일반적으로 반환을 기다리지 않고 바로바로 다음 아이템으로 넘어갑니다.  
> 코루틴이 이용됩니다 `wrap()`  

:IsEmpty()  
> 이 ObjectList 가 비어있는지 여부를 반환합니다.  

:Remove(indexOrItem:number|any)  
> objectList 에서 해당하는 오브젝트를 제거합니다.  
> , & 를 사용한 고급 검색에서는 작동하지 않습니다  

## 고급 ID 사용하기

id 기능을 조금더 고급적인 방법으로 사용할 수도 있습니다.

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount,Store = Quad.Class,Quad.Mount,Quad.Store

local Frame = Class "Frame"

--다음과 같이 a 와 b 모두 가진 프레임을 생성할 수도 있습니다.
Frame "a,b" {
    Name = "main";
    Frame "a" {
        Name = "Child1";
    };
    Frame "b" {
        Name = "Child2";
    };
}

-- 다음과 같이 a 와 b 둘다 선택할 수 있습니다
Store.GetObjects("a,b"):Each(function(item,index)
    print(item.Name)
end)
print("----")

-- 다음과 같이 a 와 b 를 동시에 가진 것을 선택할 수 있습니다
Store.GetObjects("a&b"):Each(function(item,index)
    print(item.Name)
end)
print("----")

-- 다음과 같이 a와b 를 동시에 가진것과, b 를 가진것을 선택
-- 할 수 있습니다
Store.GetObjects("a&b,b"):Each(function(item,index)
    print(item.Name)
end)
```

또는(or) 연산 `,` 와 그리고(and) 연산 `&` 연산을 GetObjects 에 사용할 수 있고, 생성시에는 `,` 로 여러 아이디를 부여해줄 수 있습니다. *띄어쓰기는 무시됩니다*  

> 주의 : *고급 ID 사용시 :Remove 연산자는 사용할 수 없습니다*

# id 추가와 제거

경우에 따라 이미 생성한 오브젝트에 id 를 추가 혹은 제거해줄 수 있습니다

```lua
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount,Store = Quad.Class,Quad.Mount,Quad.Store

local Frame = Class "Frame"

Frame "testing" {}

-- 아이디를 추가합니다
Store.AddObject(
    "a,b",Store.GetObject("testing")
)

-- 아이디를 제거합니다
Store.GetObjects("a"):Remove(Store.GetObject("testing"))
```

`Store.AddObject(ids:string,item:any)` 를 이용해 아이디를 추가하고 `:Remote(item:any)` 를 이용해 아이디를 제거합니다  

[다음 튜토리얼](./4_style)
