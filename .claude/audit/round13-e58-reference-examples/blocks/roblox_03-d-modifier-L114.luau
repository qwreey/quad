-- 값 부분에서 Tween 팔이 빠진다(변환 함수의 old도 Tween 없는 전체형)
export type FieldPV<T> = T | StateMarker<T> | None
export type FieldP<T> = FieldPV<T> | ((old: FieldOutP<T>?) -> FieldPV<T>?)

-- 예: Enum.Font는 보간 불가라 FieldP
Font: (self: TextBoxModifier, value: FieldP<Enum.Font>) -> TextBoxModifier
