local box = {}

const ApplyImpl = (nil :: any) :: <ImplT>()->(
    <U>(self: Box<ImplT>, mapper: (Box<ImplT>)->U)->U
)

box.BoxMethod = (nil :: any) :: <MethodT>()->(
    {
        Apply: typeof(ApplyImpl<<MethodT>>())
    }
)

type function BoxFactory(t: type): type
    return types.newtable({
        [types.singleton "Value"] = t,
    })
end

type Box<T> = setmetatable<BoxFactory<T>, {
    __index: typeof(box.BoxMethod<<T>>())
}>

const t = (nil::any)::Box<number>
t:Apply(function(a0) -- 언노운
    
end)

