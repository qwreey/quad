#!/usr/bin/env python3
"""Compare out-fuzz-<name>-HEAD.txt with out-fuzz-<name>-proto.txt, ignoring the `time=` field."""
import re, sys, os
d = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
for n in ['e64-base', 'e64-prov', 'e66']:
    a = re.sub(r'time=[0-9.]+s', '', open(f'{d}/out-fuzz-{n}-HEAD.txt').read())
    b = re.sub(r'time=[0-9.]+s', '', open(f'{d}/out-fuzz-{n}-proto.txt').read())
    print(f'{n}: {"identical" if a == b else "DIFFERENT"} ({len(a.splitlines())} lines)')
    for l in b.splitlines()[:2]:
        print('   ', l[:220])
