# 반응형 코어 원칙 감사 (2026-10-01, opus 읽기 전용, HEAD `a7858e9c`) — 요지

범위: `quad-base/src/` Source·State·Observer·Effect·EpochMap·Blocker·Debounce·LifecycleHooks·Operator·Store·Context·Ref(init/PreRef/PostRef)·StoreBind·LifetimeHandle·Fallback(약 3,600줄) + base 문서 + spec. 스크래치 사본 mock 프로브 하나. (라) 약 130(입구 한 줄 검사·브랜드 등록·스냅샷·`_running`/`isRunning` 게이트·Q63·`_dying`·`H-574`/`H-707`·Q51/Q57/Q68/Q109/Q110·`Quad0263`·`H-575`·Blocker `H-203`·Operator 검사·Store/Context/Fallback/LifecycleHooks 전부).

## 1. (가) 사용자가 UB로 정한 "flush 도중 Cancel"을 탐사 반영이 정의된 동작으로 굳힘 — 가장 강함(A3·D1·B1, 확신 높음)
`Debounce.luau` 216~218 `commitIdle`이 `emit()` 뒤 `b.Blocking`이 거짓이면 창을 다시 열지 않음(`H-570`). 고정: `spec.debounce` 13, CHANGELOG `[Unreleased]` Fixed 141("창 끝 통과 도중 하류가 `handle:Cancel()`을 부르면 … 다시 열려" 고침), `gate-plan.md` 6번(2026-10-01 고쳐 씀 — "제어 호출(`handle:Cancel()` 재진입, spec.debounce 13)은 … 정의된다"). 출처: 2026-09-08 round9 문항 (h)가 정확히 이 장면 — 사용자 UB *"flush 중 cancel 자체가 의미가 안 맞아서"*(`post-implementation-review-round9.md` 72~73). `H-570`은 2026-09-17 round11 탐사 K′ ① — (h)를 인용하지 않고 같은 장면을 고침. 그래서 `debounce-throttle-plan.md` 18("(h) flush 중 Cancel은 UB")과 1303(`H-570`)이 부딪힘. round13 E12(원장 452)는 "창 끝 Cancel은 H-570대로 idle, leading 중 Flush+Cancel은 (h) UB"로 갈라 읽음. 비용 세 줄(타이머 경로). 걷으면 창이 한 번 더 열리고 다음 leading이 한 Time 늦게 저절로 회복(`H-570` 전 동작); spec 13 삭제·"관측", CHANGELOG 141 삭제, gate-plan 6번 정정. **메인 메모**: 2026-10-01 메인이 "13(`handle:Cancel()` 재진입)은 제어 호출이라 정의"라고 반응형 반영 에이전트에 지시한 것이 이 고정을 한 번 더 굳혔다 — round9 (h)와 대조하지 않은 메인 사고.

## 2. (가)→메인 정정: StoreBind Observer의 `_internal`이 debug 되먹임 감지기를 사용자 되먹임 장면에서 끈다(실측)
`StoreBind.luau` 103 `observer._internal = true` + `Observer.luau` 67·88 제외. 실측: Ref 자리에 놓인 State를 그 Ref 콜백이 다시 `:Set`(dispatch-core-plan 같은 키 재진입 UB, Q5) — `_internal`을 뺀 사본에선 경고 1줄, HEAD는 0줄; 결과는 옛 Ref도 인스턴스를 쥔 채(r1·r2 둘 다 채워짐 — UB 관측). 감사자는 "사용자 원문 없음"이라 했으나 **메인 정정**: 사용자는 내부 Observer 제외에 동의했다(*"내부 옵저버같은 경우엔 동의해"* — 메인이 제시한 넷: Slot/Tree Offset·Bookkeeping len·List data·StoreBind). 남는 쟁점은 범위 — StoreBind의 Observer는 사용자 State를 대신 보는 핸들이라, 그걸 빼면 그 State를 되먹이는 사용자 장면(같은 키 재진입)까지 debug에서 숨는다. 같은 날 사용자가 승인한 "부기 거친 배달 무시"(`fedBackDirectly`의 `recompute` 프레임 건너뛰기)와 `_internal` 넷이 두 장치로 겹치는지도 확인 대상. 걷으면 그 장면에서 경고 — 문구 "the fn fed its own upstream"의 fn이 quad 내부 것이라 문구 손질 필요.

## 3. (나) 하류 Effect가 게이트 상류를 Set하는 경로를 "정의된 경로"로 둔 것은 에이전트 해석(A2, 확신 중)
`spec.gate` 6, `spec.debounce` 10·10b 주석 "Effect의 자기 의존성(상류 포함) Set — 정의된 경로", 공개 `docs/reference/core/03-state.md` 218, `docs/reference/sugar/03-debounce-throttle.md` 42, `gate-plan.md` 6번; 기대는 코드 `Debounce.luau` 212~215(`commitIdle` "이미 열린 창 유지"), 282 `held` 선읽기(`H-510` round9 ①), 296 재개방 가드. 사용자 문장은 *"`Effect`의 자기 의존성 `:Set`만 지연 재실행이 풀어 정의된다"* — 위 spec의 Effect는 의존성이 게이트 출력 `g`이고 Set하는 건 상류 `s`; 지연 재실행은 Effect 자신만 미루고 게이트 정책 재진입은 Debounce 코드가 푼다. 경위: 2026-09-08 사용자 (i) *"재진입 leading 이중 통과는 그대로(스펙 10절이 계약)"*는 당시 하류 Observer 모양 승인 → 2026-10-01 Observer 되먹임 UB 뒤 메인이 spec을 Effect로 바꿔 "정의"로 유지. 사용자에게 "의존성의 상류 Set도 Effect 예외에 드는가" 한 문장 확인 필요. 게이트 `_flush`의 바꿔 끼우기는 원래 설계·비용 0이라 해석과 무관하게 둘 만함.

## 4. (나) Debounce "던져도 상태를 안 남긴다" 묶음(D2·D1, 확신 중하)
`Debounce.luau` 185~193 `openWindow` "예약 먼저 상태 나중"(`H-509` round9 ①, `H-517`), `h._time` 신호 진입 캐시(round10 Q55 (b) — 사용자 *"확인했어"*), `Flush`의 `h._time ~= nil` 가드(251, checkpoint code-review ①), `spec.debounce` 7b·7d(Time 오류 뒤 Blocker·타이머 그대로를 계약으로). Q55의 목적은 던진 뒤 무결; 2026-09-27 E12 `H-662`가 타이머 경로 하류 Observer throw로 같은 반쪽 상태가 남음을 찾고 "예외 안전성 계약 범위라 동작은 두고" 주석만 고침 — 목적은 부분 달성인데 의미 비용(Time State 변경이 신호 하나 늦게 반영, E54 U7 캐비엇)은 남음. 걷으면 창 열 때 Time 읽기로 복귀, Flush 가드 제거, 7b·7d "관측"; `H-509` 순서 자체는 비용 0이라 계약만 아니면 둬도 됨. 사용자 결정 있으니 재검토 여부는 사용자.

## 5. 작은 항목(확신 낮음)
- (가) Ref 철거 dedup 기록 지우기 순서(`Ref/init.luau` 258~264, `H-569` 탐사 K′ ①) — 비용 0, 그러나 `spec.ref` 17이 "대기자가 철거의 `Set(nil)`에서 던져도 같은 Ref를 되꽂으면 채워진다"를 계약으로(D2·D1) → spec "관측" 표시.
- (나) 죽은 대기자 건너뛰기(Q136 ①, 사용자 2026-09-30, `Ref/init.luau` 101~107) — 동기 장면(한 코루틴을 두 Ref에)을 2026-10-01 사용자가 "quad가 정의하지 않는다"로 돌림; `spec.ref` Q136 절 앞 절반이 그 장면 결과를 계약처럼 단언 → 앞 절반 "관측"; `coroutine.close` 뒤 경우는 무관해 건너뛰기는 유지 가능.
- (나) Gate setup 동안 상류에서 떼기(`H-200` (b), 사용자 2026-08-31 — Q18 (c)보다 앞섬)와 `_onUpstreamEmit = Void` 자리표시(`State.luau` 378~390, `spec.gate` 1 throw 경로) — 추론(미실행): 떼기가 있으니 Void 줄은 죽은 줄(쌍둥이).
- (다) StoreBind 순환 사슬 검사 `Quad0070`이 평소 경로(`StoreBind.luau` 63~79·100, `spec.storebind` 7) — 같은 날 `Quad0173`·`Quad0220`은 debug로. Q113 (a) 사용자 승인 있음; 다만 그 문항 본문이 `H-573`(round11 탐사 ①)을 "결정('순환은 거부')"으로 소개 — 원장에 `H-573` 사용자 결정 없음(A3 결의 소개 사고). 비용: 흔한 경우 방출마다 브랜드 조회 하나, `State<State>` 자리는 방출마다 표 할당 + 사슬 걷기.
- (나) `LifetimeHandle.luau` 247~249 `canExecute(nil)` false·`canBound(nil)` true 조용히(`H-444` Gemini ①, `spec.lifetime` 10) — 같은 파일 `unbindLifetime(nil)`은 사용자 규칙 *"특별한 이유가 없다면 에러"*(`H-474`)로 에러인데 이 둘엔 미적용.

## 6. 사용자 결정이라 다시 열지 않음(한 줄)
`State.luau` 226~236 `H-540` 드리프트 가지(던진 Compute 회복 — Q50 "던진 fn은 상류가 바뀌면 다시 돈다"의 일관된 연장), `isHeldBy` 백엔드 op(에러 두 갈래 선택용 — D3 뒤 Q59에서 사용자가 이름 붙임).

## 미완
범위 base 문서 전 문단 D1 전수 스캔 안 함("재진입" 키워드·spec 절 제목·core/03·05·sugar/03만), test.sh 전체 안 돌림, 3·5의 Gate Void 중복·Effect 상류 Set 해석은 실행 미확인. 프로브는 스크래치에만.
