-- 입력 자리(생성자 initial, Add/Replace/Extract의 새 원소, Splice, IndexOf)
type SlotElement<T> = T | StateMarker<T> | SlotMarker<T>
-- 출력 자리(Get/Extract/ExtractAll/Splice의 반환, updateFn의 ctx.Prev)
type SlotItem<T> = T | State<T> | Slot<T>
