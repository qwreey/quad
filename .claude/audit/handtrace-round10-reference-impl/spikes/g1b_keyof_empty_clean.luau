--!strict
type function CheckReservedKeys(keys: type)
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
type Store<T> = T & { Of: <U>(self: any, name: string) -> Source<U>, Names: (self: any) -> { string }, __reservedCheck: CheckReservedKeys<keyof<T>> }
local function Store<T>(defaults: T?): Store<T> return (nil :: any) end
local empty = Store({} :: {})
local _n1: { string } = empty:Names()
local _d: Source<number> = empty:Of("dyn")
