--!strict

-- ApplyT 말고 f 쪽에 Box<ApplyT> 를 하려는 순간 문제 발생함
-- 언노운 되어버림.
const applyImpl = (nil :: any) :: <ApplyT>()->(
    <U>(self: Box<ApplyT>, f: (ApplyT) -> U) -> U
)
const boxImpl = (nil :: any) :: <ImplT>() -> {
    Apply: typeof(applyImpl<<ImplT>>())
}

type Box<T> = setmetatable<{
    inner: T,
}, { __index: typeof(boxImpl<<T>>()) }>

const t = (nil::any)::Box<number>
local o = t:Apply(function(a0)
    return 1
end)

