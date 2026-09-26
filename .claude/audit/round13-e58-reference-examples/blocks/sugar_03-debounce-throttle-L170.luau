export type TimedGate = {
    Flush: (self: TimedGate) -> (),
    Cancel: (self: TimedGate) -> (),
    __apply: (self: any, state: any) -> any,
}
