
local mySignal = Signal.Bindable.New()

local connection = mySignal:Connect(function(v)
    print(v)
end)
mySignal:Fire("우왕")
connection:Disconnect()
mySignal:Fire("이거뜨면안된다")

task.spawn(function()
    task.wait(5)
    mySignal:Fire("우와왕")
end)
print(mySignal:Wait())

mySignal:Once(function(v)
    print(v)
end)
mySignal:Fire("우와와왕")
mySignal:Fire("이것도 뜨면안된다")

mySignal:Once(function(v)
    print(v)
end):Disconnect()
mySignal:Fire("이것도 뜨면안된다*2")

local myClass = Class.Extend()
function myClass:Render(props)
    return Class "TextBox" {
        [Event.Prop "Text"] = function(this,value)
            self:EmitPropertyChangedSignal("Text",value)
        end;
        Size = UDim2.new()
    }
end
