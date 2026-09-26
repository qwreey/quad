-- 생성 타입(quad-roblox/src/Declaration). `PropTypesRead`는 D 스코프 전체의 "읽기 가능한
-- 프로퍼티 이름 → 타입" 맵이고, 클래스 간 타입이 충돌하는 이름은 any다.
export type OnChangeFn = <K>(
	name: K & keyof<PropTypesRead>,
	fn: (index<PropTypesRead, K>) -> ()
) -> OnChangeDescriptor<K>

export type OnChangeDescriptor<K> = { Name: K, Callback: (index<PropTypesRead, K>) -> () }
