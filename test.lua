local quad = require(script.quad) if false then quad = require("src"); end
local render = quad.init();
local gui = script.Parent;

local class = render.class;
local mount = render.mount;
local store = render.store;

local frame = class "Frame";
local text = class.import "TextLabel";
text.style = {
    
};

mount(gui,frame "testFrame" {
    text "texts" {
        Text = "We can make ui like this";
    };
    text "texts" {
        Text = "asdfasdfasdf";
    };
    text "texts" {
        Text = "qweiufnwlqef";
    };
});

store.getObjects("texts"):each(function(index,this)
    this.Text = "이렇게 모든 택스트를 한꺼번에 바꿀 수도 있습니다";
end);
store.getObject("texts"):eachSync(function(index,this)
    this.Text = "또한, 기본적으로 Aync 를 이용하기 때문에 순차적인 실행이 필요한 경우 Sync 를 붇여야합니다";
end);


do local this = store.getObjects("testFrame")[1];
    spawn(function ()
        local flip = false;
        while wait(0.5) do
            flip = not flip;
            this.BackgroundTransparency = flip and 1 or 0;
        end
    end);
end
