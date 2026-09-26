Modifier: setmetatable<{
    Overridden: (...any) -> any,
    TypedFactory: <T>(name: string) -> (...(Modifier | { [string]: any })) -> T,
    DefineSubtype: (parent: string, subtype: string) -> (),
}, { __call: (self: any, ...(Modifier | { [string]: any })) -> Modifier }>
