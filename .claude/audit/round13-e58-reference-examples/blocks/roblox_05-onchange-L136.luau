export type OutFn = <K>(
	name: K & keyof<PropTypesRead>,
	src: Source<index<PropTypesRead, K>> -- 쓸 수 있는 값(Source)만 — :Compute 결과는 여기서 거부된다
) -> OnChangeDescriptor<K>
