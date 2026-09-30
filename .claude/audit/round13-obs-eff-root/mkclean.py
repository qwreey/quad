import re
S='/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root/'
for src, dst in (('Observer.P1b.luau','Observer.D1.luau'),('Observer.P3.luau','Observer.D2.luau')):
    s=open(S+src).read()
    lines=[l for l in s.split('\n') if 'PROBECAP' not in l]
    open(S+dst,'w').write('\n'.join(lines))
    print(dst, sum(1 for l in s.split('\n') if 'PROBECAP' in l), 'probe lines removed')
