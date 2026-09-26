# round13 E60 — q.Store 참조 모델 차등 퍼저 (2026-09-27)

재실행(레포 루트, `./scripts/relink.sh` 뒤):

- `luau .claude/audit/round13-e60-store-fuzz/fuzz.luau -a 20000 1` → `out-fuzz-1-20000.txt` (차등 0)
- 변이 검출력: `fuzz.luau -a 300 1 x <iter|of|tostr|ctor>` → `out-mutants.txt` (넷 다 검출)
- 표적 축: `axes.luau` → `out-axes.txt` (X1~X9)
- 성능·GC: `perf-gc.luau` → `out-perf-gc.txt`
- 타입(신 솔버): `mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --platform=standard --ignore '**/luau_packages/**' <types-probe*.luau>` → `out-types*.txt`

한 벌 설치: `quad-base/test/mock.luau`(→ `quad-base/src` + `quad-base/luau_packages/quad_types`). 모델 규칙은 `docs/reference/core/04-store.md` 36·42·48~53·56·79·103·108~111·137~139·156~161행과 core/09 267행.
