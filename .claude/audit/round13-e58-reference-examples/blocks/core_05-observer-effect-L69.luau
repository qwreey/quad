Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer

export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()
export type Observer = {
	read __quadObserver: true,
	read Subscribed: boolean,
	Subscribe: (self: Observer) -> Observer,
	WeakSubscribe: (self: Observer) -> Observer,
	Unsubscribe: (self: Observer) -> Observer,
	WeakUnsubscribe: (self: Observer) -> Observer,
}
