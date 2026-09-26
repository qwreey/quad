Gate: (self: StateData<T>, setup: GateSetup) -> State<T>
export type GateEmit = (commit: boolean?) -> boolean
export type GateSetup = (emit: GateEmit) -> () -> ()
