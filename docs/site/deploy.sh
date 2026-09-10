#!/usr/bin/env bash
# docs/ 정본 → 사이트 빌드 → Cloudflare Pages 업로드 (Wrangler 직접 업로드, CI 없음)
# 선행: `npx wrangler login`(1회) + `npx wrangler pages project create quad-docs --production-branch main`(1회) — DEPLOY.md
# 사용: ./deploy.sh            (production = main 브랜치 배포)
#       ./deploy.sh preview    (현재 git 브랜치 이름으로 프리뷰 배포 — <branch>.quad-docs.pages.dev)
set -euo pipefail
cd "$(dirname "$0")"
python3 sync-docs.py
npm run build
branch="main"
if [ "${1:-}" = "preview" ]; then branch="$(git rev-parse --abbrev-ref HEAD)"; fi
# --commit-dirty: 워킹 트리가 더러워도 묻지 않는다(로컬 업로드 전용)
npx wrangler pages deploy dist --project-name quad-docs --branch "$branch" --commit-dirty=true
