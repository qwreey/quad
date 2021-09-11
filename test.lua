local quad = require(script.quad) if false then quad = require("src"); end
local render = quad.init();
local gui = script.Parent;

local class = render.class;
local mount = render.mount;
local store = render.store;
local style = render.style;

local frame = class "Frame";
local text = class "TextLabel";

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

do local this = store.getObjects("testFrame")[1];
    spawn(function ()
        local flip = false;
        while wait(0.5) do
            flip = not flip;
            this.BackgroundTransparency = flip and 1 or 0;
        end
    end);
end
