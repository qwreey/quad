<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션에서 확립된 관례를 따름). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-12 네 번째 세션 — `:Compute` 콜백 인자 `:Get()` 누락 버그 전역 감사

앞선 세션(`2026-08-12-03`)에서 추가한 `Animate`의 `CanAnimate` 예시가
`reduceMotion:Compute(function(r) return not r end)`으로 돼 있었는데,
`r`이 raw boolean이 아니라 lazy State 핸들(`bind-system-plan.md`의
"self/with 값 둘 다 lazy State 핸들로 통일" 확정 계약)이라 `not r`은 항상
`false`(State 객체는 절대 nil/false가 아니므로)로 새는 버그라고 사용자가
직접 지적. 같은 클래스의 실수가 다른 곳에도 있는지 `.claude/` 전체를
`:Compute(function(`/`:Observer(function(`/`:Apply(function(` 그렙으로
감사.

**발견된 버그(전부 수정)**:
- `research/tween-plan.md` — `not r` → `not r:Get()`(사용자가 직접 지적).
- `base/slot-plan.md:578` — `layoutOrder:With(offset):Compute(function(i, o)
  return i + o end)` → `i:Get() + o:Get()`(`LayoutOrder` 계산 예시).
- `base/slot-plan.md:966` — `Slot:Single`의 `state:Compute(function(v)
  return v == nil and {} or { v } end)` → `v:Get() == nil and {} or
  { v:Get() }`. 프로즈로 같은 패턴을 다시 언급하는 1218행도 동기화.
- `base/tag-plan.md:42` — `store.activeTag:Compute(function(name) return
  name == "btn1" and ...)` → `name:Get() == "btn1"`.

**감사 방법과 스코프**: `grep -rn ":Compute(function("` 등으로 `.claude/`
전역(`initreq/` 제외)을 훑고, 히트마다 콜백 파라미터가 비교/연산/테이블
삽입 등 "raw 값이어야 말이 되는" 방식으로 쓰였는지 확인. `:Observer`/
`:Apply` 콜백은 전부 인자 없이 외부 변수를 클로저로 캡처하는 관용구라
(`function() state:Get() ... end`) 이 클래스의 버그 자체가 성립하지
않음 — 확인만 하고 수정 없음. `archive/batch-rejected.md:29`(`function(av,
bv) return av + bv end`)는 self/with-lazy-핸들 확정 이전의 기각된
초안이라 원문 그대로 보존(archive는 원문을 안 고치는 게 원칙).
`bind-system-plan.md:1993`의 예시는 이미 올바르게 `key1:Get()`을 쓰고
있어 수정 불필요.

**일반 규칙 문서화**: `base/bind-system-plan.md`의 "self/with 값 둘 다
lazy State 핸들로 통일" 절 바로 뒤에 "이 실수가 반복되기 쉬움 —
`.claude/` 문서에서만도 4곳 발견"이라는 감사 결과+주의 노트 추가 —
`:Compute`/`:With` 콜백 인자를 비교/연산/테이블 삽입에 쓰기 전엔 항상
`:Get()`부터 거칠 것.

**반영된 파일**: `research/tween-plan.md`, `base/slot-plan.md`(2곳+프로즈
1곳), `base/tag-plan.md`, `base/bind-system-plan.md`(감사 결과 노트).

**여전히 열려있는 것**: 안 바뀜 — 자연 완료(Completed) 시 per-instance
북키핑 정리 여부 하나(`research/pre-implementation-audit.md` 2-10번).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, `.claude/luau-test/`
결과 확인 우선).
