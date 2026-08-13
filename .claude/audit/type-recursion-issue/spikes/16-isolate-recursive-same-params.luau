--!strict
-- 대조군: With의 가변인자를 State<any>가 아니라 State<T>(같은 파라미터)로
-- 맞추면 통과하는지 -- "다른 파라미터로 재귀 참조"가 진짜 원인인지 확정.

export type State<T> = {
	Get: (self: State<T>) -> T,
	With: (self: State<T>, ...State<T>) -> State<T>,
}

print("16 done")
