---
name: recurring-failure-pattern
description: The specific bug class this corpus keeps producing — check for it every audit round
metadata:
  type: feedback
---

**규칙**: 결정이 뒤집히면(예: `X 폐기` → `X 재도입`), 그 사실을 언급하는
문서/문단이 코퍼스 전체에 흩어져 여러 곳 있다. 대부분은 정정 배너가
붙지만, **정확히 같은 클레임의 다른 인스턴스 하나가 파일 안에(다른 섹션에)
빠지는 경우가 실제로 반복된다** — 배너가 붙은 곳만 보고 "됐다"고 판단하지
말고, 같은 키워드로 파일 전체 재검색해서 두 번째/세 번째 인스턴스를 찾을
것.

**실제 사례(2026-08-16 핸드오버 감사)**: `canBound`가 2026-08-14 다섯
번째 세션에 폐기됐다가 열한 번째 세션에 재도입됨. 코퍼스 대부분(README.md,
todos.md, base/lifecycle-pattern.md, base/source-state-plan.md,
base/effect-plan.md, luau-test/STATUS.md 등)은 정정을 반영했는데,
**`.claude/question.md` 한 파일 안에서도** 3번 항목(`canExecute` 이름
정리, line 55-71)은 정정 배너가 있는데 1번 섹션 인트로(line 36-38, "이미
확정된 이름" 목록 옆 괄호 설명)는 옛 "canBound 폐기" 주장을 그대로 갖고
있었음. **Why**: 같은 파일 안에서도 같은 사실이 두 곳에 서술되면 한쪽만
고쳐지는 게 실제로 일어난다 — "이 파일은 이미 정정됐다"고 파일 단위로
판단하지 말 것.

**How to apply**: 뒤집힌 결정의 키워드(용어명, 함수명 등)를 코퍼스 전체
`grep -rn`으로 훑을 때, 결과가 여러 건이면 각 파일 안에서도 발견이 하나가
아닐 수 있다는 전제로 그 파일 전체를 다시 훑을 것 — 첫 매치에 정정 배너가
있다고 같은 파일의 다른 매치도 안전하다고 가정하지 말 것. `question.md`처럼
자주 편집되고 섹션이 여러 개인 파일(용어 정리 목록 + 낮은 우선순위 질문
목록 등)이 특히 취약.

**변형 — 형제 파일 간에도 같은 일이 난다(2026-08-16 두 번째 라운드
발견)**: "N개"류 self-referential 카운트를 없애는 라운드에서, 같은
카운트를 인용하던 형제 문서 5곳(`luau-test/STATUS.md`,
`base/typing-limits.md`, `README.md`, `audit/type-recursion-issue/REPORT.md`
자신, `base/source-state-plan.md`)은 전부 "개수는 `spikes/` 폴더가
소스"로 고쳐졌는데, 같은 값을 인용하던 `audit/luau-test-first-run-
2026-08-13.md:19`(스파이크 44개) 하나만 그대로 남아 있었음 — 심지어
같은 파일 안 line 201엔 "개수의 소스는 항상 STATUS.md"라는 정확히 같은
교훈이 다른 카운트에 대해 이미 적용돼 있었는데도. **적용**: 카운트/목록을
탈-하드코딩하는 라운드에서는 "그 폴더/그 개념을 언급하는 모든 파일"을
grep으로 찾아 전수 확인할 것 — 수정된 파일 목록에 없는 형제 인용이
꼭 하나는 남아 있다.
