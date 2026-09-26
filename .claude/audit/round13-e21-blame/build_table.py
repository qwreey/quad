#!/usr/bin/env python3
# E21: merge harness output (e21.out.txt R-lines, e21-multiline.out.txt M-lines) with the skeleton and the docs.
import os, re, json, collections
D = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(D, '../../..'))
sk = {e['id']: e for e in json.load(open(os.path.join(D, 'skeleton.json')))}
md = {r['id']: r for r in json.load(open(os.path.join(D, 'msgdiff.json')))}

rows = collections.defaultdict(list)   # gotId -> [(label, mode, verdict, where, msg)]
unreach = {}
wrong = []                              # (intended, got, label, mode, verdict, where)
for line in open(os.path.join(D, 'e21.out.txt'), encoding='utf-8'):
    if not line.startswith('R|'): continue
    _, iid, label, mode, verdict, where, got, msg = line.rstrip('\n').split('|', 7)
    if verdict == 'UNREACHABLE': unreach[iid] = label; continue
    if verdict == 'NO-RAISE': wrong.append((iid, '-', label, mode, verdict, where)); continue
    if got != iid: wrong.append((iid, got, label, mode, verdict, where))
    if got.startswith('Quad'): rows[got].append((label, mode, verdict, where, msg))
for line in open(os.path.join(D, 'e21-multiline.out.txt'), encoding='utf-8'):
    if not line.startswith('M|'): continue
    _, iid, label, verdict, got, pt, msg = line.rstrip('\n').split('|', 6)
    if got.startswith('Quad'):
        v = {'PRODUCER': 'USER-P', 'TRIGGER': 'USER-T'}.get(verdict, verdict.split(':')[0])
        w = verdict.split(':', 1)[1] if verdict.startswith('LEAF') else '-'
        rows[got].append((label + ' [2줄]', 'ml', v, w, msg))

def doc_regex(t):
    out, i = '', 0
    for m in re.finditer(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', t):
        out += re.escape(t[i:m.start()]) + '.*?'; i = m.end()
    return '^' + out + re.escape(t[i:]) + '$'

def msg_body(msg):
    m = re.match(r'^[^\n]*?:\d+: (Quad\d{4}) (.*)$', msg) or re.match(r'^(Quad\d{4}) (.*)$', msg)
    return m.group(2) if m else msg

LV = {'errorBefore': 'Before(outermost)', 'errorBeforeNearest': 'BeforeNearest', 'error': 'error(…,1/2)', 'raise': 'raise→Nearest(기본)', 'fail': 'fail→Nearest(기본)/Before(Animate)', '(helper/string)': 'helper→errorBefore'}

NOTES = json.load(open(os.path.join(D, 'notes.json'), encoding='utf-8')) if os.path.exists(os.path.join(D, 'notes.json')) else {}

def short(w):
    return w.replace('quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/', '')

out = []
stats = collections.Counter()
leafsites = collections.defaultdict(set)
msgdiff = []
for k in sorted(sk):
    e = sk[k]
    lvl = LV.get(e['call'], e['call'])
    if e['call'] == 'error':
        txt = e['text']
        m = re.search(r',\s*(\d)\)\s*(--.*)?$', txt)
    rs = rows.get(k, [])
    if not rs:
        why = unreach.get(k, '도달 못함(다른 ID가 먼저 — 비고)')
        stats['unreached'] += 1
        out.append(f"| {k} | — | {lvl} | 도달 불가/내부 | — | {NOTES.get(k, {}).get('when', '—')} | {md[k]['same'] and '소스=문서' or '소스≠문서(정적)'} | {why}; {NOTES.get(k, {}).get('note', '')} |")
        continue
    stats['reached'] += 1
    labels = sorted({r[0] for r in rs if r[1] in ('direct', 'ml')})
    dv = collections.Counter(); cv = collections.Counter()
    for label, mode, v, w, msg in rs:
        tag = v if v not in ('LEAF',) else 'LEAF ' + short(w)
        if mode == 'cb': cv[tag] += 1
        else: dv[tag] += 1
        if v == 'LEAF': leafsites[k].add(short(w) + ' ← ' + label)
    anyleaf = any(r[2] == 'LEAF' for r in rs)
    stats['leaf' if anyleaf else 'user'] += 1
    # message vs doc template
    d = md[k]['doc'] or ''
    bodies = {msg_body(r[4]) for r in rs}
    rx = doc_regex(d)
    bad = [b for b in bodies if not re.match(rx, b, re.S)]
    if k == 'Quad0076':
        bad = [b for b in bodies if not b.startswith('Dispatch: no handler matched key ')]
    mcell = '일치' if not bad else '**불일치**'
    if bad:
        msgdiff.append((k, d, sorted(bad)[0]))
    fmt = lambda c: ', '.join(f'{t}×{n}' if n > 1 else t for t, n in sorted(c.items()))
    nt = NOTES.get(k, {})
    out.append(f"| {k} | {'; '.join(labels)[:140]} | {lvl} | {fmt(dv)} | {fmt(cv) or '—'} | {nt.get('when', '일치')} | {mcell} | {nt.get('note', '')} |")

hdr = "| ID | 호출 표면(최소 호출) | 레벨 | 관측 blame — 직접/2줄 | 관측 blame — 콜백(Observer fn 안) | 문서 \"언제\" | 메시지 vs 문서 | 비고 |\n|---|---|---|---|---|---|---|---|"
with open(os.path.join(D, 'TABLE.md'), 'w', encoding='utf-8') as f:
    f.write('# E21 blame 매트릭스 (자동 생성 — build_table.py)\n\n')
    f.write('판정 기호: USER = 사용자 호출 줄 / USER-INNER = 콜백 안 호출 줄 / OUTER = 콜백을 일으킨 바깥 `s:Set` 줄(outermost) / USER-P·USER-T = 2줄 변형에서 값을 만든 줄·마운트/Set 줄 / LEAF 파일:줄 = quad 잎.\n\n')
    f.write(hdr + '\n' + '\n'.join(out) + '\n\n')
    f.write('## 잎 blame 자리(ID별)\n\n')
    for k in sorted(leafsites):
        f.write(f'- {k}: ' + '; '.join(sorted(leafsites[k])) + '\n')
    f.write('\n## 메시지 ≠ 문서 템플릿(런타임 문구 기준)\n\n')
    for k, d, b in msgdiff:
        f.write(f'- {k}\n  - 문서: `{d}`\n  - 실제: `{b}`\n')
    f.write('\n## 의도한 ID와 다른 ID가 난 시도(참고)\n\n')
    for w in wrong:
        f.write(f'- 의도 {w[0]} → {w[1]} [{w[2]}] {w[3]} {w[4]} {w[5]}\n')
with open(os.path.join(D, 'TABLE.md'), 'a', encoding='utf-8') as f:
    f.write('\n## VM·비ID 스윕(e21-vm.luau — 공개 표면에 틀린 타입, 번호 없는 에러·잎)\n\n')
    for line in open(os.path.join(D, 'e21-vm.out.txt'), encoding='utf-8'):
        if line.startswith('V|'):
            _, label, v, got, msg = line.rstrip('\n').split('|', 4)
            if v.startswith('LEAF') or got == '-' and v != 'NO-RAISE':
                f.write(f'- {label}: {v} {got} — `{msg[-120:]}`\n')
    f.write('\n참고: msgdiff.raw.txt(소스 리터럴 정적 비교)는 파서 잡음(`\\{` 이스케이프·연결 식)이 섞여 있다 — 글자 비교의 소스는 위 런타임 절.\n')
print(dict(stats), 'leafIDs', len(leafsites), 'msgdiff', len(msgdiff))
