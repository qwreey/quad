export type RobloxExtension = {
	Declaration: DeclarationModule.Declaration,
	OnChange: OnChangeFn,
	Out: OutFn,
	Animate: AnimateFn,
	Tween: Types.TweenConstructor,
	isTween: (x: any) -> boolean,
}
