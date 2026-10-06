import sys,re,collections
off=int(sys.argv[1]); body=open(sys.argv[2]).read().split('\n'); txt=open(sys.argv[3]).read()
errs=collections.OrderedDict()
hdr=[]
for m in re.finditer(r'\((\d+),(\d+)\): (\w+): ([^\n]*)',txt):
    ln=int(m.group(1)); kind=m.group(3)
    if kind in ('LocalUnused','FunctionUnused','UnknownType') and kind!='UnknownType': continue
    if ln<=off: hdr.append((ln,kind,m.group(4)[:100])); continue
    errs.setdefault(ln-off,[]).append(m.group(4)[:110])
bad=0
for i,l in enumerate(body,1):
    exp='EXPECT' in l
    got=i in errs
    if exp!=got:
        bad+=1
        print(f'  MISMATCH L{i} exp={"err" if exp else "ok"} got={"err x%d"%len(errs.get(i,[])) if got else "ok"} :: {l.strip()[:80]}')
        if got: print('      ->',errs[i][0])
for h in hdr[:5]: print('  HDR',h)
print(f'  mismatches={bad} outbytes={len(txt)}')
