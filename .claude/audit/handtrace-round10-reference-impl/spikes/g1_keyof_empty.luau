--!strict
type function CheckReservedKeys(keys: type)
    if keys:is("never") then print("keys is never") return types.singleton(true) end
    local list = if keys:is("union") then keys:components() else {keys}
    for _, k in list do
        if k:is("singleton") and (k:value() == "Of" or k:value() == "Names" or k:value() == "__reservedCheck") then
            print(`quad.Store: "{k:value()}" is a reserved key`)
            return types.never
        end
    end
    return types.singleton(true)
end
type Source<T> = { Get: (self: any) -> T, Set: (self: any, T) -> () }
type Store<T> = T & {
    Of: <U>(self: any, name: string) -> Source<U>,
    Names: (self: any) -> { string },
    __reservedCheck: CheckReservedKeys<keyof<T>>,
}
local function Store<T>(defaults: T?): Store<T> return (nil :: any) end
-- 빈 Store
local empty = Store({} :: {})
local _n1: { string } = empty:Names()
-- 키 있는 Store (양성)
local st = Store({ hp = (nil :: any) :: Source<number> })
local _h: number = st.hp:Get()
-- 음성 대조군
local bad = Store({ Of = (nil :: any) :: Source<number> })
local _o = bad.Names
