type TagNames = string | { read [number]: TagNames } | TagMarker

type Tag = {
    read __quadTag: true,
    Added: (self: Tag, names: TagNames) -> Tag,
    Removed: (self: Tag, names: TagNames) -> Tag,
    Contains: (self: Tag, ...string) -> boolean,
    Apply: <U>(self: Tag, factory: (Tag) -> U) -> U,
}
