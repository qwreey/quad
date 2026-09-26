-- 클래스의 쓰기 가능한 프로퍼티마다 하나씩 생성된다. FrameModifier의 Size라면:
Size: (self: FrameModifier, value: Field<UDim2>) -> FrameModifier

-- 값의 대수(생성 모듈의 별칭 — 여기의 FieldOut<T>는 Tween을 포함하는 QuadTypes.FieldOut<T | Tween<T>>라,
-- 변환 함수의 old에는 진행 중인 Tween 값이 올 수 있습니다; core/08의 FieldOut<T>(T | State<T> | None)와 이름만 같습니다)
export type FieldV<T> = T | Tween<T> | StateMarker<T | Tween<T>> | None
export type Field<T> = FieldV<T> | ((old: FieldOut<T>?) -> FieldV<T>?)
