Effect: (fn: EffectFn, ...any) -> Effect

export type EffectFn = (self: Effect) -> ...((dying: boolean) -> ())
export type Effect = {
	read __quadEffect: true,
	read Subscribed: boolean,
	Rerun: (self: Effect) -> Effect,
	Subscribe: (self: Effect) -> Effect,
	WeakSubscribe: (self: Effect) -> Effect,
	Unsubscribe: (self: Effect) -> Effect,
	WeakUnsubscribe: (self: Effect) -> Effect,
}
