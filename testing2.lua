---@module "src.init"
local quad = require(script.Parent.quad);
local render = quad.init();
local class = render.class;
local mount = render.mount;
local store = render.store;

local text = class "TextLabel";
local con_TEXT = "Hello world!";
local con_LEN_TEXT = #con_TEXT;

local gui = script.Parent;
local app = mount(gui,
    text "#text" {
        Text = "";
    }
);

local index = 0;
spawn (function ()
    while true do
        local this = store.getOject("#text");
        this.Text = con_TEXT:sub(1,index);
        index = index + 1;
        if index > con_LEN_TEXT then
            index = 0;
        end
        wait(1);
    end
end);
