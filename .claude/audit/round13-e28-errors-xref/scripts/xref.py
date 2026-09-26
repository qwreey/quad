import re,os,sys,json,importlib.util
ROOT='/code/Projects/quad'
S=sys.argv[1]; capfiles=sys.argv[2:]
spec=importlib.util.spec_from_file_location('ec',ROOT+'/scripts/error-codes.py'); ec=importlib.util.module_from_spec(spec); spec.loader.exec_module(ec)
sites,ids=ec.scan()
d=ROOT+'/docs/reference/errors'
docs={}
for f in sorted(os.listdir(d)):
    L=open(os.path.join(d,f)).read().split('\n')
    for i,l in enumerate(L):
        m=re.match(r'^### (Quad\d{4})(.*)',l)
        if not m: continue
        j=i+1
        while not L[j].strip(): j+=1
        msgline=L[j]
        body=[]
        k=j+1
        while k<len(L) and not L[k].startswith('### ') and not L[k].startswith('## '):
            body.append(L[k]); k+=1
        # message = first backtick span; file = last backtick span after ' — '
        mm=re.match(r'^`(.+?)`(.*)$',msgline)
        msg=mm.group(1); rest=mm.group(2)
        fm=re.findall(r'`(quad-[^`]+\.luau)`',rest)
        docs[m.group(1)]=dict(file=f,line=i+1,msg=msg,rest=rest,srcfile=fm,body='\n'.join(body),dep='폐기' in m.group(2))
cap={}
for cf in capfiles:
    for l in open(cf):
        parts=l.rstrip('\n').split('\t')
        m=parts[-1]
        mm=re.match(r'(Quad\d{4}) (.*)',m)
        if mm: cap.setdefault(mm.group(1),[]).append((parts[0],mm.group(2).replace('\\n','\n')))
def tre(t):
    out='';i=0
    while i<len(t):
        if t[i]=='{':
            j=t.index('}',i); out+='(.+?)'; i=j+1
        else: out+=re.escape(t[i]); i+=1
    return out
rows=[]
for k in sorted(set(ids)|set(docs)):
    r=dict(id=k,src=ids.get(k,[]),doc=docs.get(k))
    if k in docs:
        dd=docs[k]
        srcfiles=sorted(set(s.split(':')[0] for s in ids.get(k,[])))
        r['fileok']=all(s in dd['srcfile'] for s in srcfiles)
        rx=tre(dd['msg'])
        msgs=cap.get(k,[])
        r['n']=len(msgs)
        st='NOTRIG'
        if msgs:
            st='NONE'
            for _,m in msgs:
                if re.fullmatch(rx,m,re.S): st='FULL';break
            if st=='NONE':
                for _,m in msgs:
                    if re.match(rx,m,re.S): st='PREFIX';r['tail']=m;break
            if st=='NONE': r['sample']=msgs[0][1]
            elif st=='FULL' and False: pass
        r['st']=st
        r['samples']=sorted(set(m for _,m in msgs))[:4]
    rows.append(r)
json.dump(rows,open(S+'/rows.json','w'),ensure_ascii=False,indent=1)
from collections import Counter
print(Counter(r.get('st','NODOC') for r in rows))
print('fileok false:',[ (r['id'],r['src'],r['doc']['srcfile']) for r in rows if r.get('doc') and not r['fileok']])
print('doc-only:',[r['id'] for r in rows if not r['src']])
