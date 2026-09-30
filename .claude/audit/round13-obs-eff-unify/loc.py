import re, os
D = os.path.dirname(os.path.abspath(__file__)) + '/'
A = '/code/Projects/quad/.claude/audit/round13-obs-eff-root/'
files = {
    'HEAD': (D + 'Observer.HEAD.luau', D + 'Effect.HEAD.luau'),
    'D1+D2+D3': (A + 'Observer.D2.luau', A + 'Effect.P3Ea.luau'),
    'U': (D + 'Observer.U2.luau', D + 'Effect.U2.luau'),
    "U'": (D + 'Observer.Unest2.luau', D + 'Effect.Unest2.luau'),
}


def code(p):
    s = open(p).read()
    s = re.sub(r'--\[(=*)\[.*?\]\1\]', '', s, flags=re.S)
    n = 0
    for line in s.split('\n'):
        line = re.sub(r'--.*', '', line).strip()
        if line:
            n += 1
    return n


for k, pair in files.items():
    o, e = pair
    print(f"{k:10s} Observer {code(o):4d}  Effect {code(e):4d}  sum {code(o) + code(e):4d}")
