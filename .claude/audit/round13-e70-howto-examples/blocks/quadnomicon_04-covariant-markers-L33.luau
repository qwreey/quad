-- 마커 이전: 멤버별 팔을 전부 나열해야 했던 모양
type PropValue<T> =
    T
    | TweenData<T>
    | State<T>
    | State<Tween<T>>
    | State<T | Tween<T>>
    | None
