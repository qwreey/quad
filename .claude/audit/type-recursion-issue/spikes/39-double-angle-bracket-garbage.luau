--!strict
export type StateB<T> = {
	__inner: T,
	Compute: <U>( self: StateB<T>, func: (self: StateB<T>)->any ) -> U,
}
local t = (nil :: any) :: StateB<number>
local mapped = t:Compute<<ThisTypeDoesNotExist>>(function(self)
	return nil
end)
