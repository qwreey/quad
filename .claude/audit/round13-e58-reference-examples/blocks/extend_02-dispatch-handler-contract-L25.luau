export type Handler = {
	name: string?,
	keyType: ("number" | "string")?,
	isHandlable: (inst: any, key: any, value: any) -> boolean,
	priority: number,
	process: (inst: any, key: any, value: any, index: number) -> (nextValue: any?, retracting: boolean) -> (),
}
