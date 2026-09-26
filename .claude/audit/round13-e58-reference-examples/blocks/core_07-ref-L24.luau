type RefCallback<T> = (value: T, ref: Ref<T>) -> ()

type Ref<T> = {
    read __quadRefAccepts: (T) -> (), -- 타입 전용 반공변 팬텀 필드(children 자리의 클래스 검사용)
    read Value: T,
    read Revision: number,
    read Callbacks: { [RefCallback<T> | thread]: true },
    read WeakCallbacks: { [RefCallback<T>]: true },
    Set: <Self>(self: Self, value: T) -> Self,
    Callback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
    WeakCallback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
    Uncallback: <Self>(self: Self, fn: RefCallback<T>) -> Self,
    Wait: <Self>(self: Self, thread: thread?) -> Self,
    Unwrap: (self: Ref<T>) -> StripNil<T>,
}

type PreRef<T> = Ref<T> & { read __quadPreRef: true }
type PostRef<T> = Ref<T> & { read __quadPostRef: true }
