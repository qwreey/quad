Store: (() -> Store<{}>) & (<T>(defaults: T) -> Store<T>)

export type Store<T> = T & {
	Of: <U>(self: any, name: string) -> Source<U>,
	Names: (self: any) -> { string },
	__reservedCheck: CheckReservedKeys<keyof<T>>,
}
