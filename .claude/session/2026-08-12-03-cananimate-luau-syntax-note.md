<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션에서 확립된 관례를 따름). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-12 세 번째 세션 — `Animate`에 `CanAnimate` 필드 추가, Luau 문법(`if-then-else`/`const`) 공식성 문서화

**`Animate(info)`에 `CanAnimate: State<boolean> | boolean | nil` 필드
추가** — 앞선 두 세션(`2026-08-12-01`/`02`)에서 `Animate`를 확정한 직후
사용자가 "아 맞다"며 빠뜨렸던 필드를 짚음. **`nil`이면 기본 `true`**(항상
애니메이션), `false`로 resolve되면 `Tween{...}`으로 안 감싸고 `self:Get()`을
그대로 반환 — reduceMotion류 접근성 우회가 이 필드 하나로 표현됨. 앞선
세션에서 "구 `useTween` 우회는 수동 `:Compute` 클로저로도 여전히
가능하다"고 남겨뒀던 예시가 사실상 `Animate` 안으로 흡수됨 — 수동 클로저는
`CanAnimate`로 못 담는 더 복잡한 조건(값 자체를 다른 값으로 바꿔치기 등)의
탈출구로만 절 문구를 축소. 필드 케이싱은 대화 중 `canAnimate`(소문자)로
나왔으나 같은 옵션 테이블의 나머지 필드가 전부 PascalCase(`Value`/`Style`/
`Time`...)라 `CanAnimate`로 정규화 — 이 필드만 다른 케이싱을 쓸 이유가
없다고 판단, 확정은 아니고 다음 세션에 뒤집혀도 비용 낮음.

**Luau `if-then-else`/`const` 문법의 공식성을 `base/architecture.md`에
명문화** — 사용자가 직접 짚은 우려: 앞선 세션에서 `and`/`or` 삼항
관용구를 `if-then-else`로 고친 게(`bind-system-plan.md`의
`Dispatch.retractUnder` 정정), 나중에 이 문법을 모르는 에이전트가 "이런
문법 없음"이라며 `and`/`or`로 되돌리는 회귀를 부를 수 있음 — 실제로
`if cond then a else b`는 2021년 10월 Luau에 정식 도입된 공식 표현식
문법(사용자가 릴리스 노트 링크 직접 제공:
<https://luau.org/news/2021-10-31-luau-recap-october-2021/#if-then-else-expression>).
`architecture.md`의 "코드 스타일 — 네이밍 케이싱" 절 바로 뒤에 "코드
스타일 — Luau 문법 관례" 절을 신설해 이 사실+이 프로젝트의 기본 삼항
표현 방식이 `if-then-else`라는 것(`and`/`or`는 가운데 값이 항상-truthy로
보장될 때만 예외 허용)을 명문화. 같이 언급된 `const` 바인딩
(<https://luau.org/syntax/#const-bindings>)도 공식 문법이지만 **지금은
채택 보류** — 타입 추출/narrowing 등 주변 툴링이 아직 폭넓게 지원 못 함,
지금 전면 도입하면 나중에 그 간극을 메꾸는 비용이 더 클 수 있음. 원칙:
새 코드는 일단 `local`, 나중 리팩터 시점에 특정 바인딩을 `const`로
바꾸는 비용이 싸 보이면 그때 바꾸고 비싸면 안 바꿔도 됨 — "이 프로젝트가
구식 Luau를 쓴다"는 오해 방지용으로 같이 문서화(툴링 성숙도 문제일 뿐
문법을 모르거나 기각한 게 아님).

**반영된 파일**: `research/tween-plan.md`(`Animate` 절에 `CanAnimate`
필드/예시/케이싱 메모 추가, "구 useTween 스케치" 절 축소), `base/
architecture.md`(신규 "코드 스타일 — Luau 문법 관례" 절).

**여전히 열려있는 것**: 안 바뀜 — 자연 완료(Completed) 시 per-instance
북키핑 정리 여부 하나(`research/pre-implementation-audit.md` 2-10번,
M11 착수 시).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, `.claude/luau-test/`
결과 확인 우선).
