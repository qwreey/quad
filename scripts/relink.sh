#!/usr/bin/env bash
# pesde 워크스페이스 링크를 **실제 복사**로 교체한다. 여러 번 돌려도 최신을 따라간다.
#
# 왜 필요한가: **`luau` CLI가 심볼릭 링크를 못 탄다.** 디렉토리 링크도 파일
# 링크도 안 되고, `luau-analyze`는 더 나쁘게 **조용히 통과**한다(모듈을 `any`로
# 떨어뜨리고 진단 0건 — "거짓 클린"). pesde의 워크스페이스 링크는 전부 디렉토리
# 심볼릭이라, `quad-base/src/init.luau`의 `require("./roblox_packages/quad_types")`가
# 그 링크에 닿는 순간 죽는다. 근거와 최소 재현은
# `.claude/qa-request/pre-implementation-handtrace-round7-followup.md`의 🅛 절.
#
# ⚠️ 이 스크립트가 지켜야 하는 것 셋(전부 `/code-review high`가 실제로 잡은 것):
#   1. **`cp -rL`** — 평범한 `cp -r`는 심볼릭을 **심볼릭 그대로** 복사한다.
#      중첩 패키지(quad_types 안의 type_version_check 링크)가 그대로 살아남아
#      같은 "거짓 클린"이 재발한다.
#   2. **스킵은 치명적으로** — 원본이 없어 건너뛴 채 성공으로 끝나면 테스트가
#      얼어붙은 스냅샷을 돈다. 이 스크립트가 막으려던 실패 모드 그 자체다.
#   3. **깊이 고정 글롭** — `find -path '*/.pesde/...'`의 `*`는 `/`를 넘어가
#      중첩 `.pesde`와 `src`까지 잡는다. 셸 글롭은 `/`를 안 넘으므로 그걸 쓴다.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
MANIFEST=".relink-manifest"

fail=0
note_fail() { echo "relink: $*" >&2; fail=1; }

# 0) 매니페스트가 없는데 이미 복사돼 있으면(도입 전에 한 번 돌린 트리 등)
#    pesde 레이아웃에서 원본 매핑을 되살린다.
#    구조: <member>/{luau,roblox}_packages/.pesde/<owner>+<pkg>/<ver>/<pkg>/<entry>
if [ ! -f "$MANIFEST" ]; then
	for d in */luau_packages/.pesde/*/*/* */roblox_packages/.pesde/*/*/*; do
		[ -d "$d" ] || continue
		pkg="$(basename "$d")"
		member="${pkg//_/-}"
		[ -d "$member" ] || continue
		for e in "$d"/*; do
			n="$(basename "$e")"
			[ -e "$member/$n" ] || continue
			printf '%s\t%s\n' "$e" "$(readlink -f "$member/$n")" >> "$MANIFEST"
		done
	done
fi

replaced=0
refreshed=0

# 1) 아직 심볼릭인 것 — 원본을 기록하고 복사로 교체. 중첩 링크가 남지 않도록
#    `cp -rL`로 역참조하고, 남은 게 없을 때까지 반복한다.
while :; do
	found=0
	while IFS= read -r link; do
		found=1
		target="$(readlink -f "$link")"
		if [ ! -e "$target" ]; then note_fail "dangling symlink: $link"; continue; fi
		printf '%s\t%s\n' "$link" "$target" >> "$MANIFEST"
		rm "$link"
		cp -rL "$target" "$link"
		replaced=$((replaced + 1))
	done < <(find . -path ./.git -prune -o -type l -print | grep '/\.pesde/' || true)
	[ "$found" -eq 0 ] && break
done

# 2) 이미 복사된 것 — 매니페스트를 보고 원본에서 다시 복사(워크스페이스 멤버를
#    고쳤을 때 테스트가 옛 스냅샷을 돌지 않게).
if [ -f "$MANIFEST" ]; then
	sort -u "$MANIFEST" -o "$MANIFEST"
	while IFS=$'\t' read -r link target; do
		[ -n "$link" ] || continue
		[ -L "$link" ] && continue                       # 방금 1)에서 처리됨
		if [ ! -e "$target" ]; then note_fail "missing source: $target (for $link)"; continue; fi
		parent="$(dirname "$link")"
		if [ ! -d "$parent" ]; then note_fail "missing link parent: $parent — 매니페스트가 낡았다, $MANIFEST 를 지우고 pesde install 후 다시 돌릴 것"; continue; fi
		rm -rf "$link"
		cp -rL "$target" "$link"
		refreshed=$((refreshed + 1))
	done < "$MANIFEST"
fi

echo "relink: $replaced symlink(s) replaced, $refreshed copy/copies refreshed"
if [ "$fail" -ne 0 ]; then
	echo "relink: 위 스킵 때문에 트리가 최신이 아니다 — 테스트를 신뢰하지 말 것" >&2
	exit 1
fi

# 3) 최종 확인 — .pesde 아래에 심볼릭이 하나도 남으면 안 된다.
leftover="$(find . -path ./.git -prune -o -type l -print | grep '/\.pesde/' || true)"
if [ -n "$leftover" ]; then
	echo "relink: 심볼릭이 남았다 (luau가 못 탄다):" >&2
	echo "$leftover" >&2
	exit 1
fi

# 4) IDE 타입 링킹용 sourcemap 재생성(사용자 결정, 2026-08-31 — round12 `H-234`).
#    luau-lsp가 rojo 트리를 알아야 크로스 패키지 require의 타입이 IDE에서 안
#    깨진다. rojo가 없으면(비-mise 환경) 조용히 건너뛴다 — 테스트 자체는 무관.
if command -v rojo >/dev/null 2>&1; then
	rojo sourcemap default.project.json --output sourcemap.json
fi
