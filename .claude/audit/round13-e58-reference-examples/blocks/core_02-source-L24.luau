Source: <T>(v: T) -> Source<T>

export type Source<T> = State<T> & {
	read Revision: number,
	Set: (self: Source<T>, v: T) -> Source<T>,
	Emit: (self: Source<T>) -> Source<T>,
}
