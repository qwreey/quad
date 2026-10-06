--!strict
type Epoch = { read Revision: number }
type EpochSet = { [Epoch]: true }
export type StateData<T> = { read __quadState: true, read __quadStateValue: T, Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
}
export type Source<T> = State<T> & {
	read Revision: number,
	Set: (self: Source<T>, v: T) -> Source<T>,
	SetIfChanged: (self: Source<T>, v: T) -> Source<T>,
	SetAndDispose: (self: Source<T>, v: T) -> Source<T>,
	Emit: (self: Source<T>) -> Source<T>,
}
export type Observer = { read __quadObserver: true, read Subscribed: boolean, Subscribe: (self: Observer) -> Observer }
export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()
export type GateEmit = (commit: boolean?) -> boolean
export type GateSetup = (emit: GateEmit) -> () -> ()

local mk: <T>(v: T) -> Source<T> = (nil :: any)
local c1: State<number> = mk(1)
local function id<T>(x: State<T>): State<T> return x end
local _r1 = id(c1)
local function idS<T>(x: Source<T>): Source<T> return x end
local _r3 = idS(mk(1))
