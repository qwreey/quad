import sys,re,collections
txt=open(sys.argv[1]).read().split('\n')
cats=collections.Counter(); ex={}
i=0
while i<len(txt):
    l=txt[i]
    m=re.match(r'seed (\d+) step \d+ (.*)',l)
    if m:
        seed=m.group(1); rest=m.group(2)
        if 'ERROR' in rest:
            c='ERROR '+re.sub(r'.*ERROR: ','',rest)[:70]
        else:
            probs=[]
            j=i+1
            while j<len(txt) and txt[j].startswith('   '):
                probs.append(txt[j].strip()); j+=1
            p=probs[0] if probs else '?'
            opk=re.match(r'op (\w+)',rest).group(1)
            if p.startswith('mock children') and 'extra' in p and re.search(r'extra: \S',p): c=f'ghost-extra-children ({opk})'
            elif p.startswith('mock children'): c='missing children'
            elif 'LOGICAL' in p and 'Length' in p: c='LOGICAL Length'
            elif 'LOGICAL' in p and 'Offset' in p: c='LOGICAL Offset'
            elif 'Offset' in p: c='root Offset'
            elif '_mounted' in p: c='_mounted flag'
            else: c=p[:60]
        cats[c]+=1; ex.setdefault(c,[]).append(seed)
    i+=1
for c,n in cats.most_common(): print(f'{n:4d}  {c}  e.g. {",".join(ex[c][:6])}')
