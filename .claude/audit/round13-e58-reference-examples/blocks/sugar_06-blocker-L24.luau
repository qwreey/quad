Blocker: () -> Blocker

export type Blocker = {
	read Blocking: boolean,
	On: (self: Blocker) -> Blocker,
	Off: (self: Blocker) -> Blocker,
	OffWithoutEmit: (self: Blocker) -> Blocker,
	Policy: (self: Blocker, emit: GateEmit) -> () -> (),
	__apply: (self: any, state: any) -> any,
}
