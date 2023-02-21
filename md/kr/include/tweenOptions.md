
==OPTION== `#!ts Time:number?`  
> 트윈의 총 길이를 정합니다. *아무 값도 지정하지 않으면 `#!ts 1`이 사용됩니다.*  

---

==OPTION== `#!ts Easing:string|(index:number)->number?`  
> 트윈의 가감속 정도를 결정합니다. 문자열 그대로 사용하거나, `#!ts Tween.Easings.Linear`와 같이 열거형 방식으로 사용할 수 있습니다.  
> 혹은 필요에 따라 함수를 지정할 수도 있습니다. 함수를 Easing 으로 사용하는 경우 첫번째 인자로 1차 진행도 (Linear, 0 에서 1 사이의 값) 값이 주어지며, 계산 결과로 실제 적용될 위치를 반환해야합니다. 반환값은 음수이거나 1 보다 클 수 있습니다.  
> *아무 값도 지정하지 않으면 `Exp2`가 사용됩니다.*  
{!include/typeEasings.md!}
> 함수에 관한 자세한 설명과 미리보기는 [여기에서](../reference/tween/easings) 확인하세요  

---

==OPTION== `#!ts Direction:string?`  
> 트윈이 진행되는 방향입니다. 문자열 그대로 사용하거나, `#!ts Tween.Directions.Out`과 같이 열거형 방식으로 사용할 수 있습니다.  
> *아무 값도 지정하지 않으면 `Out`이 사용됩니다.*
{!include/typeDirection.md!}
> 방향에 관한 자세한 설명과 미리보기는 [여기에서](../reference/tween/directions) 확인하세요  

---

==OPTION== `#!ts CallBack:{[number|"*"|string]:(Item:any, Alpha:number, AbsolutePercent:number)->()}?`  
> 선택적인 필드이며, 트윈이 실행중인 도중에 함수를 실행시킬 수 있습니다. 트윈의 진행 정도에 따라서 한번 함수가 실행되거나 트윈 진행중 계속해서 실행되도록 만들 수 있습니다.  
> 인덱스가 숫자인 경우 해당 지점을 넘을 때 함수가 실행되도록 만들 수 있으며, `#!lua "*"` 를 인덱스로 사용하면 모든 부분에서 함수가 실행됩니다.  
> 함수에는 편의상 트윈을 하고있는 오브젝트, 위치값, 시간만을 고려한 1차 위치값이 제공됩니다.  

---

==OPTION== `#!ts OnStepped:(Item:any, Alpha:number, AbsolutePercent:number)->()?`  
> CallBack 에 `#!lua "*"` 를 넣은것과 동일한 효과를 가지는 별칭입니다  

---

==OPTION== `#!ts Ended:(Item:any, Alpha:number, AbsolutePercent:number)->()?`  
> CallBack 에 `#!lua 1`을 넣은것과 동일한 효과를 가지는 별칭입니다  

---

==OPTION== `#!ts Getter:(Item:any, Property:string)->any?`  
> 선택적인 필드이며, 트윈이 값을 얻으려 할 때 사용할 함수입니다.  
> 함수에 트윈하고 있는 오브젝트, 프로퍼티 이름이 제공됩니다.  
> ???+ warning
	`#!ts register:Tween()` 와 호환되지 않습니다.  

---

==OPTION== `#!ts Getter:(Item:any, Property:string, Value:Lerpable)->any?`
> 선택적인 필드이며, 트윈이 값을 설정하려 할 때 사용할 함수입니다.
> 함수에 트윈하고 있는 오브젝트, 프로퍼티 이름, 설정할 값이 제공됩니다.  
> ???+ warning
	`#!ts register:Tween()` 와 호환되지 않습니다.  


