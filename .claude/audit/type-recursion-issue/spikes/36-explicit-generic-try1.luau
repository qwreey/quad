--!strict
type StateA<T> = {
    __inner: T,
    Compute: <Target,Self>( self: Self, func: (self: Self)->any ) -> Target,
}
local t = (nil :: any) :: StateA<number>
local a = t:Compute<StateA<boolean>>(function(self)
    return nil
end)
