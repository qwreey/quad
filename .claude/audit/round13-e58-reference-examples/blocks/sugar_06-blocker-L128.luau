Policy: (self: Blocker, emit: GateEmit) -> () -> ()
export type GateEmit = (commit: boolean?) -> boolean
