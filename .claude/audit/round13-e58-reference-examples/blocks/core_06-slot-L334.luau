List: <Item, UD>(
    self: Slot<T>,
    data: { Item } | StateMarker<{ Item }>,
    updateFn: (ctx: { Item: Item | KeyGone, Index: number, Offset: State<number>, Prev: SlotItem<T>?, UserData: UD? }) -> (any, UD?),
    keyFn: ((item: Item, index: number) -> any)?,
    opts: SlotListOpts?
) -> Slot<T>

type SlotListOpts = { read OwnsElements: boolean? }
