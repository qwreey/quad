# Luau 업스트림 보고 초안 — 옵셔널/유니언 자리의 자기 재귀 메소드 제네릭 테이블이 타입 인자를 검사하지 않음 (2026-09-27)

> **상태: 초안, 보고 안 함.** `question.md`의 Q86이 열려 있고, 갈래 (a)는 "이 보고서를 사용자가 읽고 업스트림에 올릴지 판단"이다. 이 초안은 그 판단 재료일 뿐 제출 여부·문구 확정은 사용자 몫이다. 근거는 `.claude/base/typing-limits.md` 8.26(2026-09-26 E7 실측), 재현 원본은 `.claude/audit/round13-e7-types-probe.luau`의 `box2.luau` 블록(490~503행). 아래 실측은 이 초안 작성 시점(2026-09-27)에 같은 파일을 다시 돌려 재확인한 것이다.

## 0. 다시 돌려 재확인한 것 (실행 로그)

재현 파일(스크래치에 그대로 복사, 원본과 바이트 동일):

```lua
--!strict
type Box<T> = { read V: T, Put: (self: Box<T>, v: T) -> () }
type Other = { Put: (self: Other, v: boolean) -> () }
local function G1(b: Box<number>?) end
local function G2(b: Box<number> | string) end
local x = (nil :: any) :: Box<string>
G1(x)        -- L7 Box<string>
G1(5)        -- L8 number
G1({})       -- L9 empty table
G1((nil :: any) :: Other) -- L10 unrelated recursive-method table
G2(x)        -- L11 union with string
local z: Box<number>? = x -- L12
return z
```

버전(직접 확인, `mise ls`/`--version`):
- `luau-analyze`: **0.734**(신 솔버가 기본값 — `--solver=old`를 안 주면 이거)
- `luau-lsp`: **1.69.0**(Luau release 729 동봉)

**`mise exec -- luau-analyze box2.luau`(기본 = 신 솔버) 실제 출력**:
```
./box2.luau(8,4): TypeError: Expected this to be 'Box<number>?', but got 'number'
./box2.luau(9,4): TypeError: Table type '{  }' not compatible with type 'Box<number>' because the former is missing fields 'V', and 'Put'
```
→ L8(숫자를 통째로 넘김)·L9(빈 테이블)만 잡힌다. **L7(`Box<string>`을 `Box<number>?`에)·L10(전혀 무관한 자기 재귀 테이블 `Other`)·L11(문자열과의 유니언)·L12(로컬 변수 타입 주석)에 진단이 0이다.**

**`mise exec -- luau-lsp analyze --flag:LuauSolverV2=true box2.luau` 실제 출력**(신 솔버 명시):
```
box2.luau(8,4): TypeError: Expected this to be 'Box<number>?', but got 'number'
box2.luau(9,4): TypeError: Table type '{  }' not compatible with type 'Box<number>' because the former is missing fields 'Put', and 'V'
```
→ `luau-analyze`와 동일하게 L8/L9만.

**대조 — `mise exec -- luau-analyze --solver=old box2.luau`**: `read` 키워드 자체를 구 솔버가 거부하는 별개 한계(`typing-limits.md` 8.21에 이미 기록)로 2행에서 에러가 나지만, 그 에러를 무시하고 읽으면 **L7·L8·L9·L10·L11·L12 여섯 자리 전부**를 정확한 원인(`Property 'Put' is not compatible` 등)과 함께 거부한다. 즉 신 솔버로 오면서 여섯 자리 중 넷의 진단이 조용히 사라졌다.

이걸로 typing-limits.md 8.26의 서술("`Box<T>?`가 `Box<string>`을 받는다")과 선례 문서(`luau-upstream-order-leak-report.md`)가 이 문제를 "L8/L9만 잡힌다"고 적어둔 것이 그대로 재현됨을 확인했다. 8.26이 이미 실측해 둔 "조건은 자기 재귀 메소드 + 옵셔널/유니언 자리 동시일 때만"(비재귀 `Box4`나 비옵셔널 직접 매개변수는 정상 거부)이라는 판별 조건은 이 초안에서 다시 돌리지 않았다 — 그 표는 8.26 본문이 소스다.

## 1. 문제 정의 (한국어)

**무엇이 일어나나.** Luau 신 솔버(`luau-analyze` 0.734 기본값, `luau-lsp` 1.69.0 + `LuauSolverV2=true`)에서, 자기 자신을 받는 메소드를 가진 제네릭 테이블 타입(`Box<T> = { read V: T, Put: (self: Box<T>, v: T) -> () }`)을 **옵셔널 자리**(`Box<number>?`)나 **유니언 자리**(`Box<number> | string`)에서 받으면, 타입 인자가 안 맞는 값(`Box<string>`)을 넘겨도 진단이 0이다. 같은 테이블을 **비옵셔널 직접 매개변수**로 받으면 정상 거부된다.

**왜 문제인가.**
- **조용한 건전성 손실**: 진단이 없어 사용자는 검사가 꺼진 줄 모른다. quad에서는 `Slot<Instance>?`·`Modifier?`·`Ref<T?>?`·(Debounce/Throttle) `Handle: Ref<GateHandle?>?` 같은 공개 표면 자리가 전부 이 구멍을 그대로 노출한다 — 다른 컴포넌트의 `Slot<TextLabel>`을 `Children: q.Slot<Instance>?`에 넘겨도 통과한다.
- **직관과 반대**: 같은 값을 비옵셔널 매개변수로 넘기면 거부되므로, "옵셔널로 받으면 검사가 느슨해진다"는 게 사용자가 예상할 수 있는 동작이 아니다.
- **구 솔버 회귀로 볼 수 있음**: 구 솔버(`--solver=old`)는 (별개 한계인 `read` 거부를 빼면) 여섯 자리 전부를 정확히 거부한다.

**영향 범위(추정, 미확정).** 자기 재귀 메소드를 가진 제네릭 테이블 타입을 옵셔널·유니언 자리에서 쓰는 라이브러리 전반 — quad류의 반응형 상태/참조 컨테이너가 전형적인 예. 8.26이 이미 적어둔 대로 원인은 좁히지 않았다(왜 `State<number>?`/`Source<number>?`는 정상 거부되는지는 미확인 — 8.26 "대조" 절).

**메인의 심각도 판단(참고용).** 중간. 조용한 무검사이고 조건도 좁지 않다(제네릭 테이블 + 자기 재귀 메소드 + 옵셔널/유니언 자리는 라이브러리 설계에서 흔한 조합) — 다만 quad 쪽 우회는 없다(비옵셔널로 바꾸면 API 모양이 달라짐), 그래서 지금 quad는 문서 캐비엇으로만 덮어두고 있다.

## 2. 이슈 본문 초안 (영어 — 게시용)

**Title:** New solver: optional/union parameter position silently skips type-argument checking for a generic table with a self-recursive method

**Versions:** `luau-analyze` 0.734 (default new solver). `luau-lsp` 1.69.0 (Luau release 729) with `--flag:LuauSolverV2=true` — identical result. Old solver (`--solver=old`) rejects all six cases correctly (module-level `read` keyword usage triggers its own, unrelated "read keyword is illegal here" error on the type alias itself; ignore that one diagnostic and the remaining six repro lines are all flagged).

**Repro (single file):**
```lua
--!strict
type Box<T> = { read V: T, Put: (self: Box<T>, v: T) -> () }
type Other = { Put: (self: Other, v: boolean) -> () }
local function G1(b: Box<number>?) end
local function G2(b: Box<number> | string) end
local x = (nil :: any) :: Box<string>
G1(x)        -- expected: type error (Box<string> into Box<number>?); actual: no diagnostic
G1(5)        -- type error (ok, still caught)
G1({})       -- type error (ok, still caught)
G1((nil :: any) :: Other) -- expected: type error (unrelated table into Box<number>?); actual: no diagnostic
G2(x)        -- expected: type error (Box<string> into Box<number> | string); actual: no diagnostic
local z: Box<number>? = x -- expected: type error; actual: no diagnostic
return z
```

**Expected:** every line rejects `x: Box<string>` (or the unrelated table `Other`) the same way a non-optional direct parameter does — see the control below.

**Control (rejects correctly, for contrast):**
```lua
local function R1(b: Box<number>) end
R1(x) -- correctly flagged: Box<string> is not Box<number>
```

**Actual:** with the parameter/annotation position changed to optional (`Box<number>?`) or union (`Box<number> | string`), the whole check is skipped for a mismatched same-shape generic instantiation (`Box<string>`) or an unrelated table with the same recursive-method shape (`Other`). Only arguments of an obviously wrong *kind* (a bare number, an empty table) are still caught.

**Condition (confirmed by contrast, from `.claude/base/typing-limits.md` §8.26 in the reporting project):** the self-recursive method (`Put: (self: Box<T>, v: T) -> ()`, referring to the table's own generic type) must be present, **and** the position must be optional/union. Removing either — a non-self-recursive method (`Put: (v: T) -> ()`), or a non-optional direct parameter — restores correct rejection.

**Analysis:** not investigated at the C++ level for this report (unlike the companion order-dependency report below, this one has not been traced through `ConstraintGenerator`/`ConstraintSolver`). Flagging this as an open gap rather than guessing.

**Possibly related (not confirmed as duplicates — a light search only, not exhaustive):**
- [#2380 "Allow recursive generic types to differ"](https://github.com/luau-lang/luau/issues/2380) and [#1438 "Recursive type error occurring when it doesn't in the old solver"](https://github.com/luau-lang/luau/issues/1438) — already cited as related by this project's earlier order-dependency report (`.claude/research/luau-upstream-order-leak-report.md`); about recursive-type handling differences between solvers, but not specifically about optional/union positions suppressing the check.
- [#1499 "Optional field in table type containing type parameters is inferred incorrectly in new solver strict mode"](https://github.com/luau-lang/luau/issues/1499) — opposite symptom (false *positive* on an optional generic field with no value present), not the same bug.
- No exact duplicate found in this quick pass; a maintainer-side search before filing is still advisable.

## 3. 보고 전에 사용자가 볼 것
- 최신 Luau 릴리즈로 한 번 더 돌려 재현되는지(이 초안은 luau-analyze 0.734 / luau-lsp 1.69.0 기준 — 프로젝트가 지금 핀 고정한 버전).
- 근본 원인 분석(C++ 소스 추적)을 넣을지 — 이번 초안엔 없음. 넣으려면 `Analysis/src/ConstraintGenerator.cpp`·`ConstraintSolver.cpp`의 옵셔널/유니언 인스턴스화 경로를 따로 조사해야 한다(선례 문서가 비균일 재귀 케이스에서 한 것과 같은 방식).
- 8.26의 "대조" 절 미확정 사항(`State<number>?`/`Source<number>?`는 왜 정상 거부되는가)을 먼저 좁혀서 이슈 본문에 넣을지, 아니면 지금처럼 열어 둔 채 보고할지.
- 이 문제와 이미 열려 있는 `.claude/research/luau-upstream-order-leak-report.md`(별개 결함, 비균일 재귀 + 선언 순서)를 같은 이슈로 묶어 보고할지 따로 보고할지 — 증상과 조건이 달라(이건 자기 재귀 + 옵셔널/유니언, 그건 비균일 재귀 + 선언 순서) 메인은 별도 이슈를 권고하되 확정은 사용자 몫.
- 게시 계정·저장소(`luau-lang/luau` Issues)는 사용자 몫(선례와 동일 관례).
