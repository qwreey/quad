--!strict
-- RFC(relax-recursive-type-restriction.html)가 예시로 든 Promise<T>.andThen과
-- 정확히 같은 모양: Compute: <U>(self: State<T>, fn: (T) -> U) -> State<U>
-- 만 단독으로 선언했을 때 그 자체로 "Recursive type being used with different
-- parameters"가 나는지 확인 (08 스파이크는 With 줄과 섞여 있어 Compute 단독
-- 원인인지 불명확했음).

export type State<T> = {
	Get: (self: State<T>) -> T,
	Compute: <U>(self: State<T>, fn: (T) -> U) -> State<U>,
}

print("17 done")
