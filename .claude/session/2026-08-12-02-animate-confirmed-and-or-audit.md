<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션에서 확립된 관례를 따름). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-12 두 번째 세션 — `Animate` 콤비네이터 확정(다음 세션 연기 철회), `.claude/` 전체 and/or 삼항 관용구 감사

앞선 세션(`session/2026-08-12-01-tween-shape-finalized.md`)에서 `Animate`
시그니처를 "단순 슈거라 다음 세션에서" 미뤘으나, 사용자가 곧바로 "생각해보니
엄청 간단하다"며 구체안을 들고 와서 같은 세션 안에 바로 확정.

**`Animate` 최종 확정**: `Tween`의 옵션(`Value` 제외 전부)을 그대로 받되
각 필드가 `T | State<T>`를 받을 수 있는 `Animate(info)`. 반환하는
`function(self) return Tween{Value = self:Get(), ...(각 필드 resolve)} end`가
`:Compute(fn)`의 콜백 시그니처(`fn(self, ...)`, `self`는 lazy State 핸들 —
`bind-system-plan.md`가 이미 확정해둔 계약)와 정확히 일치한다는 걸 사용자가
직접 확인해서, `state:Compute(Animate{Style=...})`처럼 **바로** 넘길 수
있음(예전 `useTween` 스케치가 필요로 했던 `:Apply` 경유 불필요 —
`Animate`가 스스로 `state:Compute(...)`를 감싸던 이전 모양에서, `:Compute`가
직접 받는 `fn` 그 자체가 되는 모양으로 바뀜). `Style`/`Override` 등이
State여도 값 변경 자체가 재애니메이션을 트리거하지 않는다는 것도 사용자가
의도적으로 확정 — `resolve`가 `fn` 본문 안에서 클로저로만 읽고 `:With`/
trailing-deps로 구독 등록을 안 하므로, `Value`가 실제로 바뀌는 다음
재계산 때만 그 시점의 최신 옵션이 자연히 반영됨. 근거(사용자 표현):
"style 같은 게 바뀐다고 다시 애니메이션을 수행하는 경우는 없다."

구 `useTween`(reduceMotion 조건부 우회) 2-인자 스케치(`Animate(cond,
opts)`)는 폐기 — 새 `Animate(info)`는 조건 분기를 안 가지므로, 우회가
필요하면 `Animate{...}(self)`를 감싸는 평범한 `:Compute` 클로저로 여전히
표현 가능(새 프리미티브 불필요, 코드 예시로 문서화).

**and/or 삼항 관용구 감사(사용자 요청)** — 사용자가 Luau의 `if-then-else`
표현식(2021년 정식 도입, 링크 제공)을 언급하며 `.claude/` 전체에서
`cond and truthyOnly or fallback` 패턴이 falsy-값 함정(가운데 값이
`nil`/`false`일 수 있으면 `cond`가 참이어도 `fallback`으로 새는 버그)에
해당하는 곳이 있는지 확인 요청. `grep -rn " and .* or "`로 `.claude/base`
전역 스캔, 히트 8곳 검토:

- `tag-plan.md`(`cond and Tag("a") or nil/None`), `slot-plan.md`
  (`isSlot(result) and result.Length:Get() or 1`, `v == nil and {} or
  {v}`) — 전부 가운데 값이 테이블이거나 숫자(Lua에서 0도 truthy)라 안전,
  수정 불필요.
- **`bind-system-plan.md:380`(`Dispatch.retractUnder`) — 실제 버그로
  확인.** `list[i].retract(inst, k, i == cutoff + 1 and v or nil)`에서
  `v`가 `false`(정당한 boolean 프로퍼티 값)일 때 `i == cutoff+1`이 참이어도
  `and`가 falsy가 되어 `or nil`로 새서 `v` 대신 `nil`이 전달되는 조용한
  버그. `if i == cutoff + 1 then v else nil`로 교체, 문서에 일반 규칙("가운데
  값이 임의 `T`(boolean 포함)일 수 있으면 반드시 if-then-else, 테이블/숫자처럼
  항상-truthy로 보장되는 값일 때만 and/or 안전")까지 정정 노트로 남김.
- `.claude/research`/`.claude/archive`/`.claude/reference`/`ROADMAP.md`/
  `CLAUDE.md`/`HUMAN_TODO.md`에는 해당 패턴 자체가 없음(전부 `.claude/base`에만
  존재).

새 `Animate` 예시 코드(`resolve` 헬퍼)도 이 원칙을 바로 실천 — `and`/`or`
대신 `if isState(v) then v:Get() else v`로 작성, 같은 세션의 정정 노트를
직접 참조.

**반영된 파일**: `research/tween-plan.md`(`Animate` 콤비네이터 절 전면
확정, `useTween` 절 삭제·흡수, 헤더/열린질문 갱신), `base/bind-system-plan.md`
(`Dispatch.retractUnder` 버그 수정+일반 규칙 정정 노트), `.claude/README.md`/
`.claude/question.md`(트윈 요약 행 갱신).

**여전히 열려있는 것**: 자연 완료(Completed) 시 per-instance 북키핑 정리
여부 하나뿐(`research/pre-implementation-audit.md` 2-10번, M11 착수 시).
`research/tween-plan.md`는 이걸로 사실상 마감 상태.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, `.claude/luau-test/`
결과 확인 우선).
