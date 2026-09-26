Peek: <T>(self: Modifier, key: string) -> FieldOut<T>?
type FieldOut<T> = T | State<T> | None
