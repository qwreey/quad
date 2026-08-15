--!strict
type function MakeComputeField(T)
    error("marker: reached field builder")
end
type Box<T> = {
    value: T,
    Compute: MakeComputeField<T>,
}
local b: Box<number> = (nil :: any) :: Box<number>
