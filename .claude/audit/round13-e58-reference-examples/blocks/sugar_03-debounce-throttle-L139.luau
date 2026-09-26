export type GateHandle = {
    Flush: (self: GateHandle) -> (),
    Cancel: (self: GateHandle) -> (),
}
