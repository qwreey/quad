Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer
export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()
