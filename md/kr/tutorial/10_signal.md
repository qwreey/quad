
# Signal - 이벤트 생성과 연결

???+ info "읽기 전..."
    모듈 설정시 `#!ts .Init()` 처럼 QuadId 란을 비워두는 경우 `Bindable`, `Disconnecter` 기능이 코드를 넘어 공유되지 않습니다  
    하지만 `#!ts .Init("Project1")` 처럼 아이디를 부여하는 경우 **다른 모듈, 로컬스크립트가 접근하더라도 같은 QuadId 를 가졌다면 `Bindable`, `Disconnecter` 는 공유됩니다**  

Quad 에는 편의상의 이유로 로블록스의 `RBXScriptSignal` 의 유사품과, 한번에 시그널을 끊어주는 `Disconnecter` 를 제공합니다.  
이는 내부적으로 `Extend` 의 `GetPropertyChangedSignal` 같은 곳에서 사용되기도 합니다.  

## Bindable

Bindable 은 `RBXScriptSignal` 과 유사한 객체입니다. `#!ts Signal.Bindable.New(id:string?)` 으로 생성할 수 있습니다.  
로블록스의 기본 `BindableEvent` 와는 다르게 `:Fire` 가 한곳에 합쳐져 있습니다.  
???+ note
    만약 `id` 를 지정한 경우, 같은 `id` 를 가진 `Bindable` 이 있으면 이전것을 반환합니다.  

```lua
local Quad = require(path.to.module).Init()
local Signal = Quad.Signal

local mySignal = Signal.Bindable.New()

local connection = mySignal:Connect(function(v)
    print(v)
end)
mySignal:Fire("이 메시지는 출력되어야 합니다.")
connection:Disconnect()
mySignal:Fire("이 메시지는 출력되면 안됩니다.")

task.spawn(function()
    task.wait(5)
    mySignal:Fire("이 메시지는 지연된 후 출력되어야 합니다.")
end)
print(mySignal:Wait())

mySignal:Once(function(v)
    print(v)
end)
mySignal:Fire("이 메시지는 출력되어야 합니다.")
mySignal:Fire("이 메시지는 출력되면 안됩니다.")

mySignal:Once(function(v)
    print(v)
end):Disconnect()
mySignal:Fire("이 메시지는 출력되면 안됩니다.")
```

### Bindable 메소드

`Bindable` 에는 다음과 같은 메소드들이 제공됩니다.  

{!include/bindable.md!}

### Connection 메소드

Bindable:Connect 와 Bindable:Once 는 `Connection` 을 반환합니다. `Connection` 에는 다음과 같은 메소드들이 제공됩니다.  

{!include/connection.md!}

---

## Disconnecter

`Disconnecter` 는 일종의 `Maid` 모듈과 비슷한 객체입니다. 이 객체에는 `Connection` (로블록스, Quad 모두 호환) 을 추가할 수 있으며, 나중에 추가된 `Connection` 을 한꺼번에 `Disconnect` 할 수 있습니다. `#!ts Signal.Disconnecter.New(id:string?)` 으로 생성할 수 있습니다.
???+ note
    만약 `id` 를 지정한 경우, 같은 `id` 를 가진 `Bindable` 이 있으면 이전것을 반환합니다.  

{!include/disconnecter.md!}
