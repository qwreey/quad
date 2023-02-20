```ts
export type TweenOptions = {
	Easing: "Linear"
			|"Quint"
			|"Quart"
			|"Cubic"
			|"Quad"
			|"Sin"
			|"Circle"
			|"Expo"
			|"Elastic"
			|"Bounce"
			|"Exp2"
			|"Exp4"
			|EasingFunction?;
	Direction: "Out"|"InOut"|"In"|EasingDirection?;
	CallBack: {[number|"*"|string]:(Item:DOM|any,Alpha:number,AbsolutePercent:number)->()}?;
	OnStepped: TweenOnStepped?;
		// 일반적으로 CallBack 에 ['*']=()->() 를
		// 등록하는것과 같으나 성능상의 이점이 있습니다
	Ended: TweenEnded?;
	Getter: TweenGetter?;
	Setter: TweenSetter?;
	Time: number?;
}
```