`#!ts Event(name:string)`  
> 모든 로블록스 이벤트들을 나타냅니다, `MouseEnter, MouseLeave, MouseButton1Down, MouseButton1Up` 등이 될 수 있습니다  
> 기본적으로 로블록스의 기본 이벤트들과 다르게, 첫번째 인자로 `self` 를 받을 수 있습니다.  
```lua
-- 용법
Frame {
    [Event "MouseEnter"] = function (self)
        print(self.Name .. "에 마우스가 올라왔습니다")
    end;
}
```

---

`#!ts Event.Created`  
> 오브젝트가 생성되었을 때 실행됩니다. 첫번째 인자로 `self` 를 받을 수 있습니다.  

*주의: Event.Created 가 실행될 때는 Parent 값이 정해지지 않았을 수 있습니다. self.Parent 는 접근해서는 안됩니다. Class.Extend 에서는 AfterRender 를 이용해야 합니다.*
```lua
-- 용법
Frame {
    [Event.Created] = function (self)
        print(self.Name .. "이 생성되었어요")
    end;
}
```

---

`#!ts Event.CreatedAsync`  
> `#!ts Event.Created` 와 비슷하지만, 코루틴 안에서 작동합니다. `#!ts objectList:EachAsync()` 처럼 반환을 기다리지 않습니다.  

*주의: Event.CreatedAsync 가 실행될 때는 Parent 값이 정해지지 않았을 수 있습니다. self.Parent 는 접근해서는 안됩니다.*
```lua
-- 용법
Frame {
    Frame {
        Name = "A";
        [Event.CreatedAsync] = function (self)
            -- 이 함수가 끝나지 않더라도 다음 오브젝트가 생성될 수 있어야합니다
            task.wait(5)
        end;
    };
    Frame {
        Name = "B";
        [Event.Created] = function (self)
            print(self.Name .. "가 생성되었습니다")
        end;
    };
}

```

---

`#!ts Event.Prop(propertyName:string)`  
> 프로퍼티 값이 변경됨을 연결합니다. 

```lua
-- 용법
TextBox {
    Text = "아무거나 입력하세요";
    [Event.Prop "Text"] = function (self,text)
        -- 편의상의 이유로 변경된 값이 제공됩니다
        print(text)
    end;
}
```
