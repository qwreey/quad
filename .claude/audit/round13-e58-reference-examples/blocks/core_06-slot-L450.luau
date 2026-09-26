Single: <Item, UD>(
    self: Slot<T>,
    state: Item? | StateMarker<Item?>,
    updateFn: ((ctx: { Item: Item | KeyGone, Index: number, Offset: State<number>, Prev: SlotItem<T>?, UserData: UD? }) -> (any, UD?))?,
    opts: SlotListOpts?
) -> Slot<T>
