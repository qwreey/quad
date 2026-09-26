Throttle: (opts: ThrottleOptions) -> TimedGate

export type ThrottleOptions = {
    read Time: number | StateMarker<number>,
    read Leading: boolean?, -- 기본 true
    read Trailing: boolean?, -- 기본 true
    read Handle: Ref<GateHandle?>?,
}
