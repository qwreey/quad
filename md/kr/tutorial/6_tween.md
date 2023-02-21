
# Tween - 트윈효과

## 트위닝

Quad에는 트윈을 도와주는 모듈이 내장되어 있습니다. 이 트윈 모듈은 단순한 Instance들을 넘어서 table 형식도 트윈을 수행할 수 있습니다. 이는 나중에 커스텀 오브젝트를 트윈할 때 유용합니다.  
Quad 에서는 실제로 직접적으로 Tween 을 사용할 일은 적으며 추후 설명되는 `#!ts register:Tween()`로 사용하는것이 권장됩니다.  

트윈은 일반적으로 다음과 같이 수행합니다.  

=== "용법"

    ```lua
    Tween.RunTween(myFrame,{
        -- 트윈 옵션
        Easing = Tween.Easing.Expo;
        Direction = Tween.Directions.Out;
        Time = 1;
        ...
    },{
        -- 프로퍼티 목록
    })
    ```

=== "예제 - 움직이는 버튼"

    ```lua title="클릭시 움직이는 버튼을 구현합니다."
    local ScreenGUI = script.Parent
    local Quad = require(path.to.module).Init()
    local Class = Quad.Class
    local Mount = Quad.Mount
    local Tween = Quad.Tween

    local Frame = Class "Frame"
    local TextButton = Class "TextButton"
    local on = false

    Frame "mainFrame" {
        Size = UDim2.fromOffset(300,300);
        BackgroundColor3 = Color3.fromRGB(255,255,255);
        TextButton "Child" {
            Text = "Click Me!";
            BackgroundColor3 = Color3.fromRGB(255,100,255);
            Position = UDim2.fromOffset(80,100);
            Size = UDim2.fromOffset(20,20);
            [Event "MouseButton1Click"] = function(self,x,y)
                on = not on
                Tween.RunTween(self,{
                    -- 트윈 옵션입니다. 아래에서 설명됩니다
                    Easing = Tween.Easing.Expo;
                    Direction = Tween.Directions.Out;
                    Time = 1;
                },{
                    -- 트윈할 목표 프로퍼티입니다
                    Position = on
                        and UDim2.fromOffset(200,100)
                        or UDim2.fromOffset(80,100);
                })
            end;
        };
    }

    Mount(ScreenGUI, Store.GetObejct("mainFrame"))
    ```

---

## 트윈 옵션

트윈에는 트윈 옵션이 들어가며, 여기에는 트윈의 방향, 가감속, 시간 등을 설정해줄 수 있습니다.  
넣을 수 있는 트윈 옵션은 다음과 같습니다.  

{!include/tweenOptions.md!}

---

## 트윈 함수

Quad 의 트윈에는 트윈을 멈추거나 트윈중인지 확인하는 등의 작업을 할 수 있는 여러 함수들이 제공됩니다.  
Tween 안의 모든 함수와 값들은 다음과 같습니다.  

{!include/tween.md!}
