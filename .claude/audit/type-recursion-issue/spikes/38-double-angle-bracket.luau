--!strict
export type StateB<T> = {
	__inner: T,
	Compute: <U>( self: StateB<T>, func: (self: StateB<T>)->any ) -> U,
}
local t = (nil :: any) :: StateB<number>
local mapped = t:Compute<<StateB<boolean>>>(function(self)
	return nil
end)
