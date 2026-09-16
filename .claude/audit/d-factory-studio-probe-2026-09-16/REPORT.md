# 결과 — D 팩토리화 Studio·VSCode·CLI 실측 (2026-09-16)

사용자가 Studio와 code-server VSCode(luau-lsp 확장 1.69.0)에서 01~06을 돌리고 관측을 각 파일 주석에 적었다(원문은 `src/*.luau`의 `-- Studio(...)`/`-- Vscode(...)` 줄). 리눅스 CLI 쪽은 메인 세션이 같은 파일을 `luau-lsp analyze`와 LSP 하네스(스크래치 `dprobe/lspc.py`)로 돌렸다. 결정과 승격은 `base/typing-limits.md` 8.18 정정·8.22, 원문은 `session/2026-09-16-01-d-typefunction-measurement.md`.

## 한눈에

| 항목 | Studio | 사용자 VSCode | 리눅스 CLI/하네스 |
|---|---|---|---|
| 01 type function 평가·`print` 진단 | 됨 | 됨 | 됨 |
| 02 프라이밍 없는 모듈의 함수(2-c) | 평가됨 | 평가됨 | **무진단** → 플래그 원인(아래) |
| 03 `Frame` 체인 프로퍼티 수 | 1>55>16>0>58>6 | 1>45>11>0>53>5 | 1>50>15>0>55>5 |
| 03 읽기 전용 표시 | 없음(전부 rw) | 없음 | 없음 |
| 03 이벤트 표현 | `extern:RBXScriptSignal` | `Connect` 가진 테이블 | 테이블 |
| 03 `Transparency`(Hidden) | 있음 | **없음** | 있음 |
| 03 `keyof<Frame>`에 deprecated 이름 | `BackgroundColor`·`DataCost` 있음 | 없음 | 없음 |
| 04 팩토리 진단·자동완성·체이닝 | 전부 정상 | 전부 정상(문구 동일) | 전부 정상, 한도 플래그 불필요 |
| 05 생성 D 진단·자동완성·체이닝 | 정상, **too complex 없음** | 정상(워크스페이스 한도 override 있음) | 100군데에서 한도 플래그 없이는 too complex |
| 06 `index<Frame,"MouseEnter">`의 `Connect` | 콜백 인자 검사 정직(`(string)->()` 거부) | — | 정직 |
| 06 `[P6-2]`~`[P6-5]`(extern에서 콜백 꺼내기) | **미보고** | — | 테이블 경로로 됨 |

## 2-c의 원인 — `LuauDoNotExportBrokenTypeFunction`

opus 서브에이전트가 확장이 서버에 보내는 플래그 집합(확장 `dist/extension.js`의 동기 로직: `clientsettingscdn.roblox.com` `PCStudioApp`에서 `FFlag|FInt|DFFlag|DFInt`+`Luau` 접두 키 590개 + 워크스페이스 override, `--no-flags-enabled`로 기동)을 재구성해 하네스로 재현(33행 진단 나타남 — 라이브 서버 로그의 `Unknown FFlag` 498줄과 집합 일치)한 뒤, bool 플래그 96개를 이분탐색해 하나로 좁혔다.

| 기준 | 값 | 프라이밍 없는 함수 |
|---|---|---|
| `luau-lsp analyze` 기본(전 FFlag 켬 — `--help`: "do not enable all Luau FFlags by default") | `true` | 수출 안 됨(무진단) |
| Luau 컴파일 기본(`--no-flags-enabled`) | `false` | 평가됨 |
| Roblox 동기값(2026-09-16) / Studio | `"False"` | 평가됨 |

재현 한 줄: `cd src && mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauDoNotExportBrokenTypeFunction=false --platform=standard 02c-consumer.luau` → 4건(기본은 3건). 실코드 `type-version-check`의 `CheckVersion`도 같은 플래그로 pesde 링크 경로 그대로 정상 진단 — `typing-limits.md` 8.18의 "모듈 경계를 넘으면 평가 안 됨"은 이 플래그가 만든 관측이었다. 처방은 프라이밍(정의 모듈 안 인스턴스화 한 번 — 인자는 달라도 함수 전체가 열린다, 메인 실측) — `type-version-check`에 적용.

## 부수 실측(리눅스)

- 20클래스 × 호출 100군데: 팩토리 0.77s(기본 한도) vs 생성 D 1.12s(한도 플래그 셋 필요, 없으면 too complex).
- 덤프 스코프 31클래스: 살아남은 프로퍼티 이름 242, 드롭 46(ReadOnly 포함 14), 클래스 간 이름 충돌 `Scale` 하나 → 전역 deny 목록으로 정책을 넘길 수 있다.
- LSP completion 하네스: type function이 만든 테이블에서 키 자동완성 79필드(이벤트·상속 메소드 포함 — 필터 더 좁혀야 함), hover는 필드 목록으로 전개.
- rojo: 프로젝트 파일이 든 폴더를 `$path`로 잡으면 중첩 프로젝트 무한 재귀로 stack overflow(→ `src/` 분리).

## 결정(사용자, 2026-09-16)

생성 `Declaration` = **stable** 표면(릴리즈). 클래스 매개 type function 경로 = **unstable**(언제든 변경 가능), 목적은 gen을 필수가 아니게·필요한 표면만·줄 수 감소 — 1급 대상 아님(ROADMAP 백로그). 우선순위를 높였던 이유(사용자 쪽 BREAKING 조기 제거)는 unstable 표시로 해소.
