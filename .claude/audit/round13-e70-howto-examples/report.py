#!/usr/bin/env python3
"""E70: out/table.md(블록 표) + 폴더별 집계. strict TypeError는 블록 본문 줄 범위 안의 것만 그 블록에 센다(with로 이어 붙인 앞 블록 줄은 제외)."""
import re, pathlib, collections
here = pathlib.Path(__file__).parent
exec(open(here / "spec.py").read())
idx = [l.rstrip("\n").split("\t") for l in open(here / "index.tsv")]
mock = {l.split("\t")[0]: l.split("\t")[2].strip() for l in open(here / "out/mock-summary.tsv")}
offs = {}
for l in open(here / "strict-offsets.tsv"):
    k, fn, a, b = l.rstrip("\n").split("\t"); offs[k] = (fn, int(a), int(b))
diag = collections.defaultdict(list); lint = 0
for l in open(here / "out/strict.txt"):
    m = re.match(r"strict/(\S+)\.luau\((\d+),\d+\): (\w+):", l)
    if m:
        if m.group(3) == "TypeError": diag[m.group(1)].append(int(m.group(2)))
        else: lint += 1
MATCH = {"how-to_10-debugging-and-troubleshooting-L205": "불일치 → 발견 1(✅ 줄이 Quad0076)",
         "how-to_01-component-conventions-L93": "부분 불일치 → 발견 2(둘 다 nil이면 에러 없음)",
         "how-to_10-debugging-and-troubleshooting-L64": "부분 불일치 → 발견 2(둘 다 nil이면 에러 없음)",
         "how-to_09-overlays-modal-toast-L114": "일치(떼기만 — 다음 문단이 말함) → 발견 4(예제가 dispose 안 함)"}
NOTE = {"how-to_01-component-conventions-L34": "8.13 인라인 무주석 Compute — 문서 옆 주석이 안내(E56 기지)",
        "overview_01-why-quad-L31": "8.13 인라인 무주석 Compute — 문서 옆 주석이 안내(how-to 01 §1과 같은 모양)",
        "how-to_01-component-conventions-L93": "의도 — ❌ 줄(구멍 두 자리)을 strict가 잡음",
        "how-to_10-debugging-and-troubleshooting-L64": "의도 — ❌ 줄(구멍 두 자리)을 strict가 잡음",
        "how-to_06-headless-testing-L149": "**새로움** → 발견 3(myProvider: any → q가 error-type 유니언)",
        "how-to_06-headless-testing-L180": "**새로움** → 발견 3(같은 뿌리)",
        "how-to_07-studio-ui-binding-and-claim-L26": "E17 F4 기지(`script.Parent` nil 가능)",
        "how-to_10-debugging-and-troubleshooting-L205": "발견 1(Frame에 Text 없음) — ❌·✅ 두 줄 다",
        "quadnomicon_05-non-destructive-portal-and-ownership-L92": "보강 타입 의존(`Source<Instance?>`만 거부 — 확인만 참고)",
        "quadnomicon_09-fragment-breakthrough-and-domless-slot-L139": "Q121/E45 기지(무주석 `ctx` 람다, KeyGone `return nil` 먼저)"}
rows = []; agg = collections.defaultdict(collections.Counter); te_rows = {}
for f, s, n, name in idx:
    k = name[:-5]; sp = S[k]; folder = f.split("/")[0] if not f.startswith("site") else "landing"
    agg[folder]["blocks"] += 1; agg[folder][sp["cls"]] += 1
    if sp["cls"] in ("P", "b"):
        continue
    agg[folder]["run"] += 1
    ok = mock.get(k) == "END"
    if ok: agg[folder]["mockpass"] += 1
    fn, a, b = offs[k]
    te = [x for x in diag[fn] if a < x <= b + 1]
    agg[folder]["strict"] += 1
    if not te: agg[folder]["strictclean"] += 1
    st = "0" if not te else f"{len(te)} TypeError"
    if k in NOTE and te: st += " — " + NOTE[k]
    mcol = "통과" if ok else ("실패 → 발견 1" if k in MATCH else "실패")
    rows.append(f"| {f} | {s} | {sp['cls']} | {mcol} | {MATCH.get(k, '일치')} | {st} | {sp.get('note', '')} |")
out = ["| 파일 | 블록(줄) | 분류 | mock | 출력 일치 | strict | 비고 |", "|---|---|---|---|---|---|---|"] + rows
out += ["", "| 폴더 | 블록 | P | b | a | c | d | 실행 | mock 통과 | strict 대상 | strict 클린 |", "|---|---|---|---|---|---|---|---|---|---|---|"]
for fo in ["how-to", "overview", "quadnomicon", "landing"]:
    c = agg[fo]
    out.append(f"| {fo} | {c['blocks']} | {c['P']} | {c['b']} | {c['a']} | {c['c']} | {c['d']} | {c['run']} | {c['mockpass']} | {c['strict']} | {c['strictclean']} |")
(here / "out/table.md").write_text("\n".join(out) + "\n")
print("\n".join(out[-6:])); print("lint lines", lint)
