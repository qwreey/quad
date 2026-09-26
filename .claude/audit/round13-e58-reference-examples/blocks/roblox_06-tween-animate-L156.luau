export type AnimateFn = (info: AnimateInfo) -> (self: any) -> State<Tween<any>>

export type AnimateInfo = {
	-- Tween의 옵션들과 같되(Value 제외), 각 자리에 State도 올 수 있다
	read Info: (TweenInfo | StateMarker<TweenInfo>)?,
	read Time: (number | StateMarker<number>)?,
	read Style: (Enum.EasingStyle | StateMarker<Enum.EasingStyle>)?,
	read Direction: (Enum.EasingDirection | StateMarker<Enum.EasingDirection>)?,
	read RepeatCount: (number | StateMarker<number>)?,
	read Reverses: (boolean | StateMarker<boolean>)?,
	read DelayTime: (number | StateMarker<number>)?,
	read Override: (TweenOverride | StateMarker<TweenOverride>)?,
	read CanAnimate: (boolean | StateMarker<boolean>)?, -- 기본 true
	read Dedup: (boolean | StateMarker<boolean>)?,
	read Started: (() -> ())?,   -- Tween에 그대로 실린다(State 불가)
	read Completed: (() -> ())?,
	read Cancelled: (() -> ())?,
}
