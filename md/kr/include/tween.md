`#!ts Tween.RunTween(Item:any, Option:tweenOptions, Properties:{[string]:Lerpable}, Ended?, OnStepped?, Setter?, Getter?)->TweenHandler`  
> 트윈을 실행합니다. 트윈 옵션에 대한 정보는 [TweenOptions](./tweenOptions.md) 문서에서 찾을 수 있습니다.
> `Ended`, `OnStepped`, `Setter`, `Getter` 값이 설정되면 `Option` 안의 값보다 우선적으로 사용됩니다. 기능은 [TweenOptions](./tweenOptions.md)의 내용과 같습니다.
> 나중에 트윈을 중단시킬 수 있도록 `TweenHandler` 가 제공됩니다.
> 다른 트윈이 변경중인 속성이 다시 트윈하도록 호출되면, 이전 트윈에서 해당 속성은 트윈이 중단되며 새로운 트윈으로 덮어쓰기 됩니다.
```lua
Tween.RunTween(myFrame,{
    Time = 1;
},{
    Position = UDim2.new(1,0,1,0);
})
```

---

`#!ts Tween.RunTweens(Items:{[number]:any}, Option:tweenOptions, Properties:{[string]:Lerpable}, Ended?, OnStepped?, Setter?, Getter?)`  
> `#!ts Tween.RunTween` 와 같으나 여러 오브젝트를 한꺼번에 트윈합니다. 아무것도 반환하지 않습니다  
```lua
Tween.RunTween({myFrame1, myFrame2, myFrame3},{
    Time = 1;
},{
    Position = UDim2.new(1,0,1,0);
})
```

---

`#!ts Tween.StopTween(ItemOrHandler:TweenHandler|any)`  
<blockquote markdown>

트윈을 멈춥니다. `TweenHandler` 또는 오브젝트를 넣어 멈출 수 있습니다. 오브젝트를 넣으면 그 오브젝트에 실행중인 모든 트윈을 멈춥니다.

=== "TweenHandler 이용"

    ```lua
    local Handler = Tween.RunTween(myFrame,{
        Time = 1;
    },{
        Position = UDim2.new(1,0,1,0);
    })

    Tween.StopTween(Handler)
    ```

=== "오브젝트 이용"

    ```lua
    local Handler = Tween.RunTween(myFrame,{
        Time = 1;
    },{
        Position = UDim2.new(1,0,1,0);
    })

    Tween.StopTween(myFrame)
    ```
</blockquote>

---

`#!ts Tween.StopPropertyTween(Item:any, PropertyName:string)`  
> 오브젝트에 특정 프로퍼티의 트윈을 중단시킵니다. `TweenHandler` 는 사용할 수 없습니다.

---

`#!ts Tween.StopPropertyTween(ItemOrHandler:IsTweening|any)->boolean`  
> 해당 오브젝트 또는 `TweenHandler` 로 트윈이 진행중인지 여부를 판단합니다.

---

`#!ts Tween.IsPropertyTweening(Item:any, PropertyName:string)`  
> 해당 오브젝트의 프로퍼티가 트윈중이지 여부를 판단합니다. `TweenHandler` 는 사용할 수 없습니다.

---

`Tween.Easings: { [string]: EasingFunction }`  
> 이징 함수들이 담겨있습니다.  
{!include/typeEasings.md!}
> 그래프와 미리보기는 [Easings](./easings.md) 에서 확인할 수 있습니다

---

`Tween.Easings: { [string]: EasingFunction }`  
> 이징 함수들이 담겨있습니다.  
{!include/typeDirections.md!}
> 자세한 정보는 [Easings](./directions.md) 에서 확인할 수 있습니다
