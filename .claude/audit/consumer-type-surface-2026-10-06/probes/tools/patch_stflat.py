import sys
p=sys.argv[1]; t=open(p).read()
hdr='export type State<T> = StateData<T> & {'
i=t.index(hdr); j=t.index('\n}\n',i); body=t[i+len(hdr):j]
OV='read Apply: (<U>(self: any, factory: (State<T>) -> U) -> U) & ((self: any, factory: { __apply: (self: any, state: any) -> any }) -> any),'
assert OV in body
body=body.replace(OV,'read Apply: <U>(self: any, factory: ((State<T>) -> U) | { __apply: (self: any, state: any) -> any }) -> U,')
t=t[:i]+'export type State<T> = {\n\tread __quadState: true,\n\tread __quadStateValue: T,\n\tread Get: (self: any) -> T,'+body+t[j:]
open(p,'w').write(t)
