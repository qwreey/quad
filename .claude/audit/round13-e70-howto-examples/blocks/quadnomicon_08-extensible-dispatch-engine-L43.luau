export type Handler = {
	name: string?,                                     -- 진단 표시용(선택)
	keyType: ("number" | "string")?,                   -- 이 핸들러가 볼 수 있는 키 타입(선택)
	isHandlable: (inst: any, key: any, value: any) -> boolean,
	priority: number,
	process: (inst: any, key: any, value: any, index: number)
		-> (nextValue: any?, retracting: boolean) -> (),
}
