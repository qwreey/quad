--!strict
-- 08 스파이크가 낸 "Recursive type being used with different parameters" 에러를
-- Compute/self-application 문제와 분리해서 최소 재현. State<T>가 자기 자신을
-- *다른* 타입 인자(State<any>)로 자기 선언 안에서 참조하는 것 자체가
-- 문제인지 확인 (Compute 없이, With 하나만으로).

export type State<T> = {
	Get: (self: State<T>) -> T,
	With: (self: State<T>, ...State<any>) -> State<any>,
}

print("15 done")
