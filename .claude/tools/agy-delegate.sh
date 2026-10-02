#!/usr/bin/env bash
# agy-delegate.sh — run a Gemini (Antigravity CLI `agy`) task in an isolated git worktree.
#
#   agy-delegate.sh run <name> <prompt-file> [--model M] [--timeout SEC]
#   agy-delegate.sh remove <name>          # after the main session has read the result
#   agy-delegate.sh list
#
# Why (user, 2026-10-03): a model from another family looks at the corpus differently (root causes,
# creative jumps, merging findings that share a mechanism) — but flash makes far more operational
# mistakes and agy's harness is loose, so EVERY run (read-only too) happens in its own worktree.
#
# Isolation (measured 2026-10-03 — `agy --sandbox` does NOT block writes outside the cwd, and
# `unshare -m` is not permitted in this container):
#   - the worktree lives at /code/Projects/quad-agy/<name> on branch agy/<name> (from HEAD);
#   - agy runs as an unprivileged uid (61000) via `setpriv`; only the worktree and its
#     .git/worktrees/<name> admin dir are chowned to it, so the main working tree, other
#     worktrees and .git/objects are read-only to it: no writes to the main repo, no commits
#     (no object writes), therefore nothing new to push; a pre-push hook (via GIT_CONFIG_*)
#     refuses pushes as a second line;
#   - HOME is /code/Projects/quad-agy/.home with a copy of /code/.gemini (agy's OAuth).
#   - the whole agy tree runs under `choom -n 1000` (OOM victim before claude — conventions 2026-10-02 heavy-process
#     rule; agy's own Bash is invisible to the PreToolUse guard hook, so this is the only lever there);
#   - a before/after snapshot of the main repo's HEAD + `git status` is compared and reported.
set -euo pipefail

ROOT=/code/Projects/quad
BASE=/code/Projects/quad-agy
AGY_HOME=$BASE/.home
HOOKS=$BASE/.hooks
AGY_UID=61000
AGY=/code/.local/share/mise/installs/antigravity-cli/latest/agy
DEFAULT_MODEL=gemini-3.8-flash-high

die() { echo "agy-delegate: $*" >&2; exit 2; }

cmd=${1:-}; shift || true
case "$cmd" in
list)
	git -C "$ROOT" worktree list | grep "$BASE/" || echo "(none)"
	exit 0
	;;
remove)
	name=${1:?name}
	[[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "bad name"
	git -C "$ROOT" worktree remove --force "$BASE/$name"
	git -C "$ROOT" branch -D "agy/$name"
	exit 0
	;;
run) ;;
*) die "usage: run <name> <prompt-file> [--model M] [--timeout SEC] | remove <name> | list" ;;
esac

name=${1:?name}; promptFile=${2:?prompt-file}; shift 2
model=$DEFAULT_MODEL; timeoutSec=3600
while [[ $# -gt 0 ]]; do
	case "$1" in
	--model) model=$2; shift 2 ;;
	--timeout) timeoutSec=$2; shift 2 ;;
	*) die "unknown option $1" ;;
	esac
done
[[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "name must be [a-z0-9-]"
[[ -f "$promptFile" ]] || die "no prompt file $promptFile"
WT=$BASE/$name
[[ -e "$WT" ]] && die "$WT exists — pick another name or remove it"

mkdir -p "$BASE" "$HOOKS"
# home: fresh copy of the OAuth state every run (the user's own agy use may have refreshed it)
mkdir -p "$AGY_HOME"
rm -rf "$AGY_HOME/.gemini"
cp -r /code/.gemini "$AGY_HOME/.gemini"
chown -R $AGY_UID:$AGY_UID "$AGY_HOME"
printf '#!/bin/sh\necho "push refused: agy delegate worktree" >&2\nexit 1\n' > "$HOOKS/pre-push"
chmod 755 "$HOOKS/pre-push"

git -C "$ROOT" worktree add -q -b "agy/$name" "$WT" HEAD
(cd "$WT" && timeout 300 mise exec -- pesde install >/dev/null 2>&1) || echo "agy-delegate: warning — pesde install failed (tests may not run)" >&2
mkdir -p "$WT/.agy"

{
	cat <<EOF
# 작업 환경 (반드시 지킬 것)

- 너는 git worktree \`$WT\`(브랜치 \`agy/$name\`) 안에서 일한다. 이 디렉터리가 quad 레포의 사본이다. **이 디렉터리 밖의 파일을 만들거나 고치지 말 것** — 너는 권한이 낮은 별도 사용자로 돌고 있어 밖에는 어차피 쓸 수 없다. 원본 레포 경로(\`$ROOT\`)는 읽기만 가능하다; 읽을 때도 이 worktree 안의 같은 파일을 읽어라(같은 커밋이다).
- \`git commit\`·\`git push\`·\`git stash\`·\`git reset\`·\`git checkout\`(브랜치 전환)·\`git worktree\` 명령을 쓰지 말 것. 실험으로 파일을 고치는 것은 이 worktree 안에서 허용된다(메인 세션이 diff를 본다) — 고쳤다면 보고서에 무엇을 왜 고쳤는지 적을 것.
- 테스트·Luau 실행은 항상 \`( ulimit -v 4000000; timeout 600 <명령> )\` 꼴로. 전체 테스트는 \`./scripts/test.sh\`이고 판정은 **exit code**(0이 통과) — 출력의 "ALL PASS" 줄 수가 아니다. \`luau\`를 직접 돌리지 말고(심볼릭 링크 문제) 기존 spec 파일(\`quad-base/test/spec.*.luau\`, \`quad-roblox/test/spec.*.luau\`)의 머리 하네스를 본떠 같은 폴더에 프로브 파일을 만들어 test.sh가 relink한 뒤 \`luau\`로 돌리거나, test.sh의 실행 방식을 따라라.
- **최종 보고서는 반드시 \`$WT/AGY_REPORT.md\` 파일에 한국어로 쓴다.** 주장마다 근거(파일:줄, 실행한 명령과 출력)를 붙이고, 직접 실행해 확인한 것은 "실측", 코드를 읽고 추론한 것은 "추정"으로 표시한다. 틀릴 수 있는 주장을 단정하지 말 것. 다 못 한 것은 "미완"으로 적는다.
- 이 프로젝트의 결정은 사용자가 한다. 너의 제안은 "제안"이지 결정이 아니다 — 새 필드·이름·메커니즘을 제안할 때는 그렇다고 적어라.

# 과제

EOF
	cat "$promptFile"
} > "$WT/.agy/prompt.md"

chown -R $AGY_UID:$AGY_UID "$WT" "$ROOT/.git/worktrees/$name"

before_head=$(git -C "$ROOT" rev-parse HEAD)
before_status=$(git -C "$ROOT" status --porcelain=v1 | sha1sum)
echo "agy-delegate: start $name ($model) $(date -Is) — worktree $WT"

set +e
(cd "$WT" && choom -n 1000 -- setpriv --reuid=$AGY_UID --regid=$AGY_UID --clear-groups \
	env HOME="$AGY_HOME" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0="$HOOKS" \
	timeout $((timeoutSec + 60)) "$AGY" --model "$model" --dangerously-skip-permissions \
	--print-timeout "${timeoutSec}s" -p "$(cat "$WT/.agy/prompt.md")") > "$WT/.agy/stdout.txt" 2>&1
rc=$?
set -e

after_head=$(git -C "$ROOT" rev-parse HEAD)
after_status=$(git -C "$ROOT" status --porcelain=v1 | sha1sum)
{
	echo "exit: $rc"
	echo "finished: $(date -Is)"
	if [[ "$before_head" == "$after_head" && "$before_status" == "$after_status" ]]; then
		echo "main repo: unchanged"
	else
		echo "main repo: CHANGED during the run (HEAD $before_head -> $after_head; status hash differs) — check whether the main session or the user did it"
	fi
	echo "worktree changes:"
	git -c safe.directory="$WT" -C "$WT" status --porcelain=v1 | grep -v '^?? .agy/' || true
} > "$WT/.agy/guard.txt"

echo "agy-delegate: done $name — exit $rc"
cat "$WT/.agy/guard.txt"
if [[ -f "$WT/AGY_REPORT.md" ]]; then
	echo "report: $WT/AGY_REPORT.md ($(wc -c < "$WT/AGY_REPORT.md") bytes)"
else
	echo "report: MISSING — see $WT/.agy/stdout.txt"
fi
