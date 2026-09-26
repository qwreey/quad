Debounce: (opts: DebounceOptions) -> TimedGate

export type DebounceOptions = {
    read Time: number | StateMarker<number>,
    read Leading: boolean?, -- 기본 false
    read Trailing: boolean?, -- 기본 true
    read MaxTime: (number | StateMarker<number>)?,
    read Handle: Ref<GateHandle?>?,
}
