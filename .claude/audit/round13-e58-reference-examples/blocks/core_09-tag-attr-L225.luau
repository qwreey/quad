type Attr = {
    read __quadAttr: true,
    NameMap: (self: Attr) -> { [string]: any },
}

type AttrConstructor = setmetatable<{
    Merged: (...Attr) -> Attr,
    Overridden: (...Attr) -> Attr,
}, { __call: (self: any, ...any) -> Attr }>
