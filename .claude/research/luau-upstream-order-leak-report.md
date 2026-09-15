# Luau 업스트림 보고 초안 — 신 솔버의 선언 순서 의존 무진단 에러 타입 (2026-09-15)

> **상태: 초안, 보고 안 함.** 사용자가 읽고 심각도를 판단해 보고 여부를 정한다(사용자: *"보고에 대한 초안이나 문제 정의를 작성해주면 내가 읽어볼게. 심각도 따라 보고할지 내가 결정할게"*). 근거 조사와 코드 위치는 `.claude/base/typing-limits.md` 8.21, 재현 파일은 레포 밖 스크래치 `/code/Projects/quad-scratch/luau-order-probe/`.

## 1. 문제 정의 (한국어)

**무엇이 일어나나.** 신 솔버에서, **비균일 재귀** 제네릭 타입 별칭(메소드가 다른 타입 인자로 자기를 반환 — `Compute: <U>(self: S<T>, …) -> S<U>`)을 그 **정의보다 파일에서 먼저** 인스턴스화하면(앞선 별칭 필드든 함수 매개변수 주석이든), 그 인스턴스화 전체가 에러 타입으로 해소된다. 에러 타입은 무엇이든 받으므로 그 자리의 타입 검사가 **꺼지고, 진단은 하나도 나오지 않는다.** 같은 코드를 정의 뒤로 옮기면 정상 검사된다.

**왜 문제인가.**
- **조용한 건전성 손실**: 진단이 없어 사용자는 검사가 꺼진 줄 모른다. 우리는 공개 라이브러리의 옵션 타입(`Time: number | State<number>`)과 연산자 반환 타입에서 몇 주 동안 몰랐다 — 다른 조사 중 우연히 발견.
- **순서 의존**: 타입 선언의 파일 내 위치가 의미를 바꾼다. 구 솔버는 문장을 의존성 순으로 재정렬해 이 의존이 없었다(구→신 이관 회귀로 볼 여지).
- **발견이 어렵다**: 같은 파일 뒤쪽에서 같은 `S<number>`를 쓰면 정상이라(실패가 캐시되지 않음), 한 곳만 새고 나머지는 멀쩡해 보인다.

**영향 범위(추정).** 비균일 재귀 제네릭(반응형 상태 컨테이너의 `map`/`compute`류가 전형)을 정의하는 라이브러리. 비균일 재귀 자체가 Luau의 기존 제한(§1 — 해당 메소드 반환은 원래 에러 타입) 대상이라, 메인테이너가 "이미 제한된 모양"으로 볼 가능성이 있다. 다만 **제한이 메소드 반환 한 곳을 넘어 다른 선언으로 번지고, 진단이 사라지는 것**은 별개 결함으로 주장할 수 있다.

**메인의 심각도 판단(참고용).** 중간. 조용한 무검사라 발견 비용이 크지만, 우회가 쉽고(정의를 앞으로), 조건이 좁다(비균일 재귀 + 앞선 인스턴스화). 보고 가치: 진단이 사라지는 부분 하나만으로도 버그 리포트로 성립한다고 본다.

**우회(우리가 한 것).** 비균일 재귀 제네릭 정의를 그걸 참조하는 모든 선언보다 앞으로 둔다. 입력 자리는 재귀 구조가 없는 마커 타입(`{ read __quadState: true, read __quadStateValue: T }`)으로 받는다.

## 2. 이슈 본문 초안 (영어 — 게시용)

**Title:** New solver: instantiating a non-uniformly recursive type alias before its declaration silently resolves to an error type (no diagnostic)

**Versions:** `luau-analyze` 0.734 (default new solver), `luau-lsp` 1.69.0 (Luau release 729) with `LuauSolverV2=true`. Old solver (`--solver=old`) does not exhibit the order dependence.

**Repro (single file):**
```lua
--!strict
local function f(_o: { read Time: number | SC<number> }) end
export type SC<T> = { read __quadState: true, Get: (self: SC<T>) -> T, Compute: <U>(self: SC<T>, fn: (T) -> U) -> SC<U> }
f({ Time = "x" }) -- expected: type error; actual: no diagnostic
return {}
```

**Repro (module + consumer, shows the order dependence and uniform-recursion control):**
```lua
-- nrmod.luau
--!strict
export type OptsC = { read Time: number | SC<number> }   -- declared before SC (non-uniform recursion)
export type OptsD = { read Time: number | SD<number> }   -- declared before SD (uniform recursion)
export type SC<T> = { read __quadState: true, Get: (self: SC<T>) -> T, Compute: <U>(self: SC<T>, fn: (T) -> U) -> SC<U> }
export type SD<T> = { read __quadState: true, Get: (self: SD<T>) -> T, Depend: (self: SD<T>) -> SD<T> }
export type OptsCAfter = { read Time: number | SC<number> } -- declared after SC
return {}

-- consumer.luau
--!strict
local M = require("./nrmod")
local function c(_o: M.OptsC) end
local function d(_o: M.OptsD) end
local function a(_o: M.OptsCAfter) end
c({ Time = "x" }) -- no diagnostic   (expected: error)
d({ Time = "x" }) -- error           (ok)
a({ Time = "x" }) -- error           (ok)
local _p: boolean = ((nil :: any) :: M.OptsC).Time -- no diagnostic (field is *error-type*)
```
`nrmod.luau` itself reports nothing either.

**Expected:** `SC<number>` in `OptsC` behaves like in `OptsCAfter` (at most, the known recursive-type restriction applies to the `Compute` return with a visible diagnostic, as the old solver does).

**Actual:** the whole `SC<number>` instantiation becomes an error type, depending only on declaration order, with no diagnostic.

**Analysis (from reading `luau-lang/luau@3fc82b1`, same logic in release 729):**
- ConstraintGenerator emits a `TypeAliasExpansionConstraint` per generic reference in statement order (`Analysis/src/ConstraintGenerator.cpp:4232`, `:4238`), so the expansion of `SC<number>` inside `OptsC` is queued before the expansions inside `SC`'s own body; the solver processes the vector front to back (`ConstraintSolver.cpp:538`).
- When dispatching it, the infinite-expansion guard (`InfiniteTypeFinder`, `ConstraintSolver.cpp:1448-1454`, check at `:376-378`) finds the still-pending `SC<U>` in the body, whose argument differs from the alias parameter, and binds the *outer* expansion to `errorType`. Declared after `SC`, the body's pending expansions are already bound and skipped (`skipBoundTypes`, `:339`), so it is fine; the failure is not cached (`:1559`), so later uses are fine too.
- The finding is only recorded in `invalidTypeAliases` (`:1454`); TypeChecker2 reports it by walking parent scopes from the alias statement (`TypeChecker2.cpp:1315`, `Scope.cpp:253`), but the scopes where it was recorded (the referencing alias's definition scope / the `<U>` signature scope) are not on that path, so nothing is reported.

**Related:** #921 (old solver order-dependent recursive error, icebox), #1438, #2380, RFC "Relax the recursive type restriction".

## 3. 보고 전에 사용자가 볼 것
- 최신 Luau(0.734 이후)에서도 재현되는지 — 보고 직전 최신 릴리즈로 한 번 더 돌릴 것(메인이 해도 됨).
- 제목·재현 최소화 수준, 분석 절을 넣을지(메인테이너가 선호하면 재현만).
- 게시 계정·저장소(`luau-lang/luau` Issues)는 사용자 몫.
