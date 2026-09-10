#!/usr/bin/env python3
"""docs/ 정본을 감시하며 바뀔 때마다 sync-docs.py를 다시 돌린다(2026-09-10).

`astro dev`는 `src/content/`만 본다 — 정본은 그 바깥(`docs/<track>/*.md`)이라
sync를 다시 돌려야 브라우저가 갱신된다. inotify 계열 도구가 없는 환경이라
mtime 폴링으로 처리한다(기본 1초, `WATCH_INTERVAL`로 조정).

단독으로도 쓸 수 있고(`python3 watch-docs.py`), `dev.sh`가 astro dev 옆에
띄우기도 한다.
"""
import os, subprocess, sys, time

SITE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(SITE)
TRACKS = ['overview', 'getting-started', 'how-to', 'quadnomicon', 'reference']
INTERVAL = float(os.environ.get('WATCH_INTERVAL', '1'))


def snapshot() -> dict:
    """감시 대상(.md)의 경로 → mtime."""
    out = {}
    for track in TRACKS:
        root = os.path.join(DOCS, track)
        for dp, _dn, fn in os.walk(root):
            for f in fn:
                if f.endswith('.md'):
                    p = os.path.join(dp, f)
                    try:
                        out[p] = os.stat(p).st_mtime
                    except OSError:
                        pass
    return out


def sync() -> None:
    r = subprocess.run([sys.executable, os.path.join(SITE, 'sync-docs.py')],
                       capture_output=True, text=True)
    tag = 'sync' if r.returncode == 0 else 'sync FAILED'
    line = (r.stdout.strip().splitlines() or [''])[-1]
    print(f'[watch-docs] {tag}: {line}', flush=True)
    if r.returncode != 0:
        print(r.stdout + r.stderr, flush=True)


def main() -> None:
    print(f'[watch-docs] watching {DOCS}/<{"|".join(TRACKS)}>/**.md (every {INTERVAL}s)', flush=True)
    prev = snapshot()
    sync()
    while True:
        time.sleep(INTERVAL)
        cur = snapshot()
        if cur != prev:
            changed = sorted(set(cur) ^ set(prev)) or \
                sorted(p for p in cur if prev.get(p) != cur[p])
            print(f'[watch-docs] changed: {", ".join(os.path.relpath(p, DOCS) for p in changed[:5])}'
                  + (' …' if len(changed) > 5 else ''), flush=True)
            prev = cur
            sync()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
