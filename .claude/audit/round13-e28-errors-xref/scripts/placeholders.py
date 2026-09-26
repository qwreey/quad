import re,json,sys
ROOT='/code/Projects/quad'
R=json.load(open(sys.argv[1]))
def lit_at(path,ln,kid):
    t=open(ROOT+'/'+path).read(); L=t.split('\n')
    off=sum(len(x)+1 for x in L[:ln-1]); p=t.index(kid,off)
    # find literal start
    i=p
    while t[i] not in '`"': i-=1
    q=t[i]; j=i+1
    while t[j]!=q: j+= 2 if t[j]=='\\' else 1
    lit=t[i+1:j]
    # follow concatenations: grab rest of statement up to line end of closing paren (rough)
    k=j+1; tail=''
    m=re.match(r'\s*\.\.\s*',t[k:])
    while m:
        k+=m.end()
        if t[k] in '`"':
            q2=t[k]; e=k+1
            while t[e]!=q2: e+= 2 if t[e]=='\\' else 1
            tail+= '<<'+t[k+1:e]+'>>' if q2=='"' else t[k+1:e]; k=e+1
        else:
            mm=re.match(r'[\w.:]+(\([^()]*(\([^()]*\))*[^()]*\))?',t[k:])
            tail+='{'+mm.group(0)+'}'; k+=mm.end()
        m=re.match(r'\s*\.\.\s*',t[k:])
    return q,lit+tail
out={}
for r in R:
    if not r['src']: continue
    path,ln=r['src'][0].rsplit(':',1)
    q,lit=lit_at(path,int(ln),r['id'])
    code=lit.replace('<<','').replace('>>','')
    cph=[re.sub(r'\s','',x) for x in re.findall(r'\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}',code)] if True else []
    dph=[re.sub(r'\s','',x) for x in re.findall(r'\{([^{}]*)\}',r['doc']['msg'])]
    out[r['id']]=dict(code=code,cph=cph,dph=dph)
    if cph!=dph:
        print(r['id'],r.get('st'),'\n  code:',cph,'\n  doc :',dph)
json.dump(out,open(sys.argv[2],'w'),ensure_ascii=False,indent=1)
