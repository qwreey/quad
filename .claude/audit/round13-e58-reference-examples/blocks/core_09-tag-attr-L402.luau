StringAttr: AttrSugar<string>
type AttrSugar<T> = (name: string, value: T | StateMarker<T> | None) -> Attr
