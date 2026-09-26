import os,sys,re
root=sys.argv[1]
PRE='local __qraw_error = error; local function error(m: any, l: number?): never if type(m) == "string" and string.find(m, "Quad%d%d%d%d") then print("@@QERR\\t" .. string.gsub(m, "\\n", "\\\\n")) end if l == 0 then __qraw_error(m, 0) end __qraw_error(m, (l or 1) + 1) end\n'
n=0
for dp,dn,fn in os.walk(root):
    if '/test' in dp and 'luau_packages' not in dp: continue
    if not ('/src' in dp): continue
    for f in fn:
        if not f.endswith('.luau'): continue
        p=os.path.join(dp,f); t=open(p).read()
        if '__qraw_error' in t: continue
        if not re.search(r'\berror\s*\(', t): continue
        lines=t.split('\n'); i=0
        while i<len(lines) and lines[i].startswith('--!'): i+=1
        lines.insert(i,PRE.rstrip('\n'))
        open(p,'w').write('\n'.join(lines)); n+=1
print(n)
