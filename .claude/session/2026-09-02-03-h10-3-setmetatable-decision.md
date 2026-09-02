# 2026-09-02-03 — `H10-3` 콜러블 테이블 타입: `setmetatable<A,B>` 형태 실측·채택

M10 병렬 탐사 fork가 올린 `H10-3`(🔴 — quad-types `Quad` 필드에 교집합
콜러블 타입 `((...string) -> Tag) & {Merged…}`를 실으면 `QuadRoblox<T>`
제네릭 추론이 오염됨)과 `H10-4`(같은 뿌리의 값-측 캐스트 붕괴)에 대해,
사용자가 **setmetatable 타입 형태 실험을 직접 지시**했다:

> "M10-3 에 대해서 setmetatable<{}, { __call }> 에 대해서 한번 시도해볼래?
> 서브에이전트에게 시도시켜봐"

## 실험 (서브에이전트, 레포·워크트리 무수정 — 스크래치 오버레이)

도구는 레포 `test.sh`와 동일 인보케이션(`luau-lsp analyze
--flag:LuauSolverV2=true` + defs, `luau-analyze` 교차 확인). 4-formulation
매트릭스:

| formulation | 값 캐스트 | 호출·필드 검사 | 제네릭 통과 |
|---|---|---|---|
| (i) 교집합(원장 형태) | ❌ H10-4 그대로 | ✅ | ❌ H10-3 재현 |
| (ii) `any`(잠정안) | — | ❌ 전부 무검사 | ✅ |
| (iii) `typeof(setmetatable({}::{…}, {}::{__call…}))` | ✅ | ⚠️ 인자만 무검사 | ✅ |
| (iv) `setmetatable<{…}, {__call…}>`(내장 타입 함수 표기) | ✅ (iii)과 완전 동일 | ⚠️ 동일 | ✅ |

핵심 관측:

- **재현 조건이 좁았다** — 축소 rig·중간 충실도 rig로는 (c) 오염이 안
  나오고, 워크트리 4패키지 자립화 오버레이에서만 재현됐다. 트리거는
  `spec.robloxfactory.luau` 1절의 **이중 통과**(`QuadRoblox(Quad.New())`의
  산출을 다시 `QuadRoblox`에 넣는 경로)로, 그 아래 `q.bindLifetime` 접근이
  `Type 'nil' does not have key`로 무너진다. 필드를 (iv)로 토글하면 exit 0
  (A/B 대칭 확인).
- **H10-4도 같이 닫힌다** — (iv) 상태에선 quad-base `init.luau`의
  `Tag = TagModule.Tag :: any` 류 사유 캐스트를 걷어내도 리터럴 `:: Quad`가
  통과한다.
- **유일한 잔여 구멍**: `__call` 메타메소드 경유 호출의 **인자 타입 무검사**
  (`q.Tag(123)` 조용히 통과 — 같은 시그니처의 순수 함수는 잡힌다; luau-lsp
  1.69.0·luau-analyze 판정 일치, `self` 구체화해도 동일). 반환 타입·필드
  오타·필드 접근은 전부 검사되므로 `any` 잠정안보다 엄격히 우월.
- 옛 `@metatable` 표기는 소스 문법이 아니다(SyntaxError — 프린터 전용).
- 런타임 무영향 — (iv)+캐스트 제거 상태에서 `spec.tag`/`spec.attribute`/
  `spec.robloxfactory` 전부 PASS.

재현물은 스크래치 `h10-3-setmetatable/`(오버레이가 판정의 정본)에 남겼고,
세션 스크래치라 세션 종료 후엔 소멸 — 재현 절차 요지는 위와 원장 행에 남는
서술이 전부다.

## 결정 (사용자)

> "우선 권고대로 채택하고자 해."

원장의 처방 후보 (a) any 잠정 유지 / (b) 표면 재설계 / (c) 솔버 추적과
별개로 실험이 연 **새 갈래 (d)를 채택** — 표기는 권고대로 **(iv)
`setmetatable<A, B>`**(판정은 (iii)과 완전 동일, 캐스트 없이 읽힘).
"타입 함수는 진단까지만" 원칙과는 무관하다(진단용 type function이 아니라
내장 타입 함수 **표기**).

## 반영 계획 (M10 통합 시 — 이 세션 파일이 결정의 기록, 반영은 통합 커밋)

1. quad-types의 `TagConstructor`/`AttributeConstructor` 정의를 (iv) 형태로
   교체, `Quad` 필드를 `any`에서 그 타입으로 복원.
2. quad-base `init.luau`의 `Tag`/`Attribute` `:: any` 사유 캐스트 제거.
3. `typing-limits.md` 등재: 교집합 콜러블의 제네릭 오염(H10-3)·값 캐스트
   붕괴(H10-4)와 (iv) 처방, 그리고 `__call` 인자 무검사 구멍.
4. M10 원장 `H10-3` 행을 ✅로 — (d) 채택·사용자 인용 병기, `H10-4` 행의
   "등재 후보" 마무리.
