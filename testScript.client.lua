-- 이렇게 모듈을 부를 수 있다, 뒤에 if 가 붇은것은 자동완성이 뜨도록 하기 위해서 사용된다
local quad = require(script.Parent.quad) if false then quad = require("src"); end
local render = quad.init();
-- init 함수를 이용해 여러 스크립트가 이 모듈을 호출해도 완전히 별계의
-- 환경에서 실행될 수 있도록 만든다, init 를 호출하면 완전히 새로운 store 와 style
-- 등을 가진 모듈을 새로 생성한다

-- 하위 모듈을 이렇게 부른다
local class = render.class;
local mount = render.mount;
local store = render.store;

-- 오브젝트를 이렇게 불러온다
local frame = class "Frame"; -- 이렇게 원하는 오브젝트를 불러올 수 있다
local text = class "TextLabel";
text.TextSize = 17; -- 이렇게 오브젝트의 기본값도 정할 수 있다
text.Size = UDim2.new(1,0,0,30);
local titleText = class "TextLabel";
-- 당연 이렇게 똑같은 className 을 가진 오브젝트를 여러번 import 도 된다
-- 다른 임포트에서 설정한 기본값은 여기에 적용되지 않는다

local gui = script.Parent;
local app = mount(gui,frame "testFrame" { -- mount 로 트리를 마운트한다, 이후 app 에서 unmount 호출가능
    Size = UDim2.fromOffset(120,60);
    Position = UDim2.fromScale(0.5,0.5);
    AnchorPoint = Vector2.new(0.5,0.5);
    text "texts" { -- 이렇게 단순히 child 개체를 만들 수 있다
        Text = "We can make ui like this";
    };
    text "texts" {
        Position = UDim2.fromOffset(0,30);
        Text = "qweiufnwlqef";
    };
    titleText { -- 아이디를 명명하지 않아도 오브젝트를 바로 만들 수 있다
        Text = "test";
    };
});

print(store.getObject("texts"));
-- getObject 를 호출하면 해당 id 로 명명된 오브젝트중
-- 가장 처음으로 생성된 객체를 반환한다
store.getObjects("texts"):each(function(index,this)
    this.Text = "이렇게 모든 택스트를 한꺼번에 바꿀 수도 있습니다";
end);
-- getObjects 를 이용하면 해당 id 로 명명된 오브젝트가 담긴 array 를 가져온다
-- for 을 돌릴 수 있지만 each 를 이용해 async 된 작업을 수행할 수 있다
store.getObjects("texts"):eachSync(function(index,this)
    this.Text = "또한, 기본적으로 Aync 를 이용하기 때문에 순차적인 실행이 필요한 경우 Sync 를 붇여야합니다";
end);
-- sync 를 하면 일반 스크립트를 실행하는것 처럼 순차적으로 실행되도록 만들 수도 있다
-- 이 때 순서는 먼저 생생된 순서이다, 항상 같음을 유지한다는 보장이 없으므로 순서가 중요한경우
-- 직접 for 을 이용해 순서 검증을 한 뒤 task 를 수행해야한다

-- 이렇게 어떤 오브젝트를 가지고 task 수행하는 thread 를 만들 수 있다
do local this = store.getObject("testFrame");
    spawn(function ()
        local flip = false;
        while wait(0.5) do
            flip = not flip;
            this.BackgroundTransparency = flip and 1 or 0;
        end
    end);
end

app.unmount(); -- 트리의 객체들을 모두 파기한다, 플러그인에서 unload 같은곳에 쓰는 함수
return app;