#!/usr/bin/env bash
# 로컬 미리보기 — 정본 감시(sync) + astro dev를 함께 띄운다(2026-09-10).
#
#   ./dev.sh                     # 0.0.0.0:4321
#   PORT=8080 ./dev.sh           # 포트 바꾸기
#   HOST=127.0.0.1 ./dev.sh      # 로컬만
#   DOCS_ALLOWED_HOSTS=all ./dev.sh   # 프록시 호스트 제한 해제(기본 허용: quad.selene.yaeji.moe)
#   ./dev.sh stop                # 서버 내리기(= npx astro dev stop)
#
# docs/<track>/*.md를 고치면 watch-docs.py가 sync-docs.py를 다시 돌리고,
# astro dev가 src/content/ 변경을 감지해 브라우저를 갱신한다.
#
# ⚠️ 이 astro는 `dev`를 백그라운드 데몬으로 띄운다(로그: `npx astro dev logs`,
# 종료: `npx astro dev stop`). 그래서 이 스크립트는 데몬을 먼저 띄우고 **감시자를
# 포그라운드로** 잡고 있는다 — Ctrl-C면 감시자와 데몬을 같이 정리한다.
set -euo pipefail
cd "$(dirname "$0")"

PORT="${PORT:-4321}"
HOST="${HOST:-0.0.0.0}"

if [ "${1:-}" = "stop" ]; then
	pkill -f "$PWD/watch-docs.py" 2>/dev/null || true
	exec npx astro dev stop
fi

# 이미 떠 있으면 내리고 다시(포트/호스트가 바뀌었을 수 있다)
npx astro dev stop >/dev/null 2>&1 || true

# 허용 호스트는 astro.config.mjs의 vite.server.allowedHosts(기본 quad.selene.yaeji.moe) — 더 열려면
#   DOCS_ALLOWED_HOSTS=a.example,b.example ./dev.sh   또는   DOCS_ALLOWED_HOSTS=all ./dev.sh
npx astro dev --host "$HOST" --port "$PORT"

cleanup() { npx astro dev stop >/dev/null 2>&1 || true; }
trap cleanup EXIT INT TERM

echo "[dev.sh] http://${HOST}:${PORT}/ — 감시자 실행 중(Ctrl-C로 둘 다 종료)"
python3 "$PWD/watch-docs.py"   # 절대 경로로 띄운다 — `stop`의 pkill 패턴이 이 경로를 본다(상대 경로면 못 잡아 감시자가 쌓인다)
