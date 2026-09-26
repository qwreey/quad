type CardModifier = {
    read __quadModifier: "Card",
    Elevation: (self: CardModifier, value: number) -> CardModifier,
    Peek: <T>(self: CardModifier, key: string) -> QuadTypes.FieldOut<T>?,
    As: <T>(self: CardModifier, name: string?) -> T,
}

local Card = q.Modifier.TypedFactory<<CardModifier>>("Card")
local raised = Card({ Elevation = 2 })
