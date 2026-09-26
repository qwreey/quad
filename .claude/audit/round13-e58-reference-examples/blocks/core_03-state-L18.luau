export type StateData<T> = { read __quadState: true, read __quadStateValue: T, Get: (self: StateData<T>) -> T }

export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>, previous: U?, ...any) -> U, ...any) -> State<U>,
	Depend: (self: StateData<T>, ...any) -> State<T>,
	Apply: (<U>(self: StateData<T>, factory: (State<T>) -> U) -> U) & ((self: StateData<T>, factory: { __apply: (self: any, state: any) -> any }) -> any),
	Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer,
	Gate: (self: StateData<T>, setup: GateSetup) -> State<T>,
}
