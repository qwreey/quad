type Modifier = {
    read __quadModifier: true, -- 무타입 Modifier의 클래스 태그. 타입드면 클래스 이름 문자열
    Peek: <T>(self: Modifier, key: string) -> FieldOut<T>?,
    Apply: <U>(self: any, factory: (any) -> U) -> U,
    Overridden: (self: Modifier, ...any) -> any,
    As: <T>(self: Modifier, name: string?) -> T,
}

-- 필드에 "저장된 그대로"의 값: 리터럴 | State 핸들 자체 | None(명시 해제)
type FieldOut<T> = T | State<T> | None
