# round13 E36 — type_version_check 차등 퍼즈 + quad_error blame 실측 (2026-09-27)

자율 수집 루프 탐사 E36. 레포 파일은 바꾸지 않았다 — 이 폴더만 새로 생겼다. 발견과 판정은
`qa-request/post-implementation-review-round13.md`로 옮길 메인 몫이고, 여기엔 재현 도구와 원출력만 둔다.

## 무엇을 돌렸나

| 파일 | 역할 |
|---|---|
| `refs.py` | 문서 문장을 술어로 옮긴 참조 구현. `ext01` = extend/01 232-236행(소스 머리 주석과 같고, README·core/01은 이리로 미룸), `rbx01` = roblox/01 66-69행의 글자 그대로의 읽기(core/꼬리 분리 언급이 없으므로 문자열 전체를 `.`로 자름). 문서가 말하지 않는 자리는 손잡이(`num`: "숫자" = ASCII 숫자열+정수 비교 / Luau `tonumber` 근사, `caret_bad_n`)로 둠 |
| `runner.luau` | 실 구현 `type-version-check/src`의 `matchesPattern`을 fuzz.py가 생성하는 cases 모듈(생성물, 커밋 안 함) 전체에 돌림 |
| `fuzz.py N seed` | 쌍 생성(자리 1~5, `*`/`N^`/정확, 꼬리 `rc.1`·`dev.3`·`*`·`^`, `+build`, 앞자리 0·2^53 넘는 수·빈 자리·`0x10`·`1e2`·`inf`·`nan`·공백·`٣`·`3_0`, `|` 대안 1~3) → 실 구현 vs `ext01`/`rbx01`/`scripts/check-version.py` 파이썬 포트 |
| `analyze.py N seed` | 차등을 원인 토큰별로 묶고 한 건씩 축소 |
| `clean_subset.py` | 자리가 전부 정상 형태(ASCII 숫자 15자리 이하·글자·`*`·`N^`)인 쌍만 골라 다시 비교 |
| `repros.py` → `repros.txt` | 손으로 줄인 재현 31개(문서 예시 포함), 네 판정을 한 표로 |
| `typefn_diff.py K` → `typefn_diff.txt` | `CheckVersion` type function(컴파일 타임 사본) vs 런타임, `luau-analyze` 0.734로 40쌍씩 청크 |
| `quad_error_blame.luau` → `quad_error_blame.txt` | quad_error 네 진입점 blame 줄(중첩 깊이 0~4) + 층 0/-1/미매치 + `setFuncLevel` 인자 처리, `luau` / `-O2` / `-O2 --codegen` |

재현: `cd` 이 폴더 → `python3 fuzz.py 6000 36`, `python3 analyze.py 6000 36`, `python3 clean_subset.py`,
`python3 repros.py`, `python3 typefn_diff.py 1500`, `luau [-O2] quad_error_blame.luau`. 먼저 `./scripts/relink.sh`.

## 숫자

- 퍼즈: 5 시드 × 6000 = **30000쌍**, 실 구현 true 10829, 예외 0 (`fuzz-5seeds.txt`).
- 실 구현 vs `ext01`(문서 규칙): 일치 29018 / 차등 982 — **982건 전부 "숫자" 해석 차이**(Luau `tonumber`가 `0x10`·`1e2`·`inf`·`nan`·앞뒤 공백·부호·`3.`을 숫자로 받고, 2^53을 넘는 자리를 double로 뭉갬). 원인 미상 0.
- 정상 형태 부분집합 5438쌍: 실 구현 vs `ext01` 차등 **0**, vs 파이썬 포트 **0** (`clean_subset.txt`).
- 실 구현 vs 파이썬 포트: 일치 28996 / 차등 1004 — 같은 숫자 해석 차이(파이썬 `int()`는 `٣`·`3_0`을 받고 큰 수를 정확히 비교, `0x10`·`1e2`·`inf`·`nan`은 거부).
- 실 구현 vs `rbx01`(roblox/01 글자 그대로): 차등 3110 — 문서가 core/꼬리 분리를 안 적어서 생기는 것(아래 문서 불일치 표).
- type function vs 런타임: 1530쌍(ASCII만, 재현 31개 포함) 차등 **0** — 두 사본의 로직은 텍스트 diff로도 같다(주석·매개변수 이름만 다름).
- quad_error: 문서대로의 blame 20/20, 세 최적화 모드 모두 동일.

## 문서 사이 대조

| 규칙 | 소스 머리 주석 | extend/01 232-236 | core/01 169 | roblox/01 66-69 | README(type-version-check) |
|---|---|---|---|---|---|
| `\|` 대안 | 있음 | 있음 | 예시로 | 있음 | 있음 |
| `+` 빌드 양쪽 무시 | 있음 | 있음 | 있음 | 있음 | 있음 |
| 첫 `-`에서 꼬리 | 있음 | 있음 | 없음 | **없음** | 없음(소스로 미룸) |
| 꼬리 유무 일치 | 있음 | 있음 | 있음 | 있음 | 있음 |
| core·꼬리 따로, 자리 수 불일치 = false | 있음 | 있음 | 없음(extend/01로 미룸) | **없음 — "대안마다 `.`로 나뉜 자리"** | 없음 |
| `N^` 사전식 하한의 범위 | "그 구간(core 또는 prerelease)의 뒤 자리" | "그 구간의 뒤 자리" | — | **"뒤 자리"(구간 한정 없음)** | "lexicographic-floor" |
| 숫자가 아닌 자리엔 `N^` 안 먹음 | 있음 | 없음 | — | 없음 | 없음 |
| "숫자"의 정의 | 없음(구현은 `tonumber`) | 없음 | — | 없음 | 없음 |
| 에러 문구 `Quad0228` | 소스 `quad-roblox/src/init.luau:229` | — | — | ID 없이 같은 문구 | errors/07-roblox.md 108(ID는 헤딩) — 문구 일치 |
