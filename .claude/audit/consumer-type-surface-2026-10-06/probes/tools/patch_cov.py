import sys,re
p=sys.argv[1]; t=open(p).read(); o=t
t=t.replace('export type StateData<T> = { read __quadState: true, read __quadStateValue: T, Get: (self: StateData<T>) -> T }',
            'export type StateData<T> = { read __quadState: true, read __quadStateValue: T, read Get: (self: any) -> T }')
t=t.replace('\tCompute: <U>(self: StateData<T>, fn:','\tread Compute: <U>(self: any, fn:')
t=t.replace('\tDepend: (self: StateData<T>, ...any) -> State<T>,','\tread Depend: (self: any, ...any) -> State<T>,')
t=t.replace('\tApply: (<U>(self: StateData<T>, factory: (State<T>) -> U) -> U) & ((self: StateData<T>, factory:','\tread Apply: (<U>(self: any, factory: (State<T>) -> U) -> U) & ((self: any, factory:')
t=t.replace('\tObserver: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer,','\tread Observer: (self: any, fn: ObserverFn<T>?) -> Observer,')
t=t.replace('\tGate: (self: StateData<T>, setup: GateSetup) -> State<T>,','\tread Gate: (self: any, setup: GateSetup) -> State<T>,')
for m in ['Set','SetIfChanged','SetAndDispose']:
    t=t.replace(f'\t{m}: (self: Source<T>, v: T) -> Source<T>,',f'\tread {m}: (self: any, v: T) -> Source<T>,')
t=t.replace('\tEmit: (self: Source<T>) -> Source<T>,','\tread Emit: (self: any) -> Source<T>,')
n=sum(1 for a,b in zip(o.split('\n'),t.split('\n')) if a!=b)
open(p,'w').write(t); print(p,'changed lines',n)
