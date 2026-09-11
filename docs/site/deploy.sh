#!/usr/bin/env bash
# docs/ 정본 → 사이트 빌드 → Cloudflare Pages 업로드 (Wrangler 직접 업로드, CI 없음)
# 선행: `npx wrangler login`(1회) + `npx wrangler pages project create quad-docs --production-branch main`(1회) — DEPLOY.md
# 사용: ./deploy.sh            (production = main 브랜치 배포)
#       ./deploy.sh preview    (현재 git 브랜치 이름으로 프리뷰 배포 — <branch>.quad-docs.pages.dev)
set -euo pipefail
cd "$(dirname "$0")"
# ⚠️ [2026-09-10 실측] astro dev가 도는 동안 build를 돌리면 dev의 콘텐츠 레이어가 굳어 옛 렌더를 계속 낸다(둘이 .astro 저장소를 공유).
# [2026-09-11 사용자 실측] `astro dev status`는 서버가 없어도 exit 0("No dev server is running.")이라 exit code로는 못 가른다 — 메시지로 판정.
if npx astro dev status 2>/dev/null | grep -qv "No dev server is running"; then
	echo "[deploy.sh] astro dev가 떠 있습니다 — 빌드 뒤 dev.sh를 다시 띄우세요(옛 렌더가 굳습니다)" >&2
fi
python3 sync-docs.py
node check-mermaid.mjs   # ```mermaid 문법 — 클라이언트 렌더라 빌드가 못 잡는다(2026-09-10)
npm run build
branch="main"
if [ "${1:-}" = "preview" ]; then branch="$(git rev-parse --abbrev-ref HEAD)"; fi
# --commit-dirty: 워킹 트리가 더러워도 묻지 않는다(로컬 업로드 전용)
npx wrangler pages deploy dist --project-name quad-docs --branch "$branch" --commit-dirty=true
