import sys,re
p=sys.argv[1]; mode=sys.argv[2] if len(sys.argv)>2 else 'union'
t=open(p).read()
hdr='export type State<T> = StateData<T> & {'
i=t.index(hdr); j=t.index('\n}\n',i)
body=t[i+len(hdr):j]
OV='read Apply: (<U>(self: any, factory: (State<T>) -> U) -> U) & ((self: any, factory: { __apply: (self: any, state: any) -> any }) -> any),'
assert OV in body
if mode=='union':
    body=body.replace(OV,'read Apply: <U>(self: any, factory: ((State<T>) -> U) | { __apply: (self: any, state: any) -> any }) -> U,')
dataf='\n\tread __quadState: true,\n\tread __quadStateValue: T,\n\tread Get: (self: any) -> T,'
t=t[:i]+'export type State<T> = {'+dataf+body+t[j:]
sh='export type Source<T> = State<T> & {'
k=t.index(sh); l=t.index('\n}\n',k)
sbody=t[k+len(sh):l]
t=t[:k]+'export type Source<T> = {'+dataf+body+sbody+t[l:]
open(p,'w').write(t); print('ok',p)
