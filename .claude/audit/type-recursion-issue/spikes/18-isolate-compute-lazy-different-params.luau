--!strict
-- 17과 같은데 fn이 raw T가 아니라 lazy self 핸들을 받는 버전(0-Y 원래
-- 계약)도 "다른 파라미터로 재귀 참조" 자체로는 독립적으로 통과/실패하는지.
-- (bidirectional inference 문제와 별개로, 타입 "선언" 자체가 성립하는지만 봄
-- -- 호출부 없음)

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (self: State<T>) -> U) -> State<U>,
}

print("18 done")
