# 공개 약속·spec·결정 이력 원칙 감사 (2026-10-01, opus 읽기 전용, HEAD `a7858e9c`) — 요지

건수: (1) 공개 레퍼런스 약속 — 걸림 10(체계 문제 1 포함)·문제없음 7, (2) spec이 UB 결과를 계약처럼 — 걸림 4·확인 9절, (3) 결정 이력 표류 — 6(1은 회고 2차 기존 지적), (4) CHANGELOG — 게시 절 자체 원칙 초과 0, `[Unreleased]` 안 철회·정정과 어긋난 문장 3.

## 1. 공개 레퍼런스가 사용자 결정 없이 약속한 것
- 1-1 Debounce/Throttle 하류 throw 뒤 "그 한 번뿐이고 이후는 정상"(`sugar/03-debounce-throttle.md` 51)·"던진 신호의 출처는 … 다음 통과에 실려"(125) — round13 E12 `H-662`·`H-664` mock 관측을 문장으로; plan(`debounce-throttle-plan.md` 90)은 "예외 안전성 계약 범위라 동작은 두고 주석·문서만". D2·D1, 문서 표시. 높음.
- 1-2 Blocker flush 중 하류 throw 뒤 유보분이 다음에 실림(`sugar/06-blocker.md` 95) — 자율 관측. D2. 높음.
- 1-3 Slot `Length` 구독 콜백이 던져도 다음 변경에서 회복(`core/06-slot.md` 129) — 같은 문장이 `architecture.md` 529 "예외 안전성 계약" 절 안에도("code-review 실측 — 던져도 다음 변경에서 회복"). `H-555` code-review, 원문 없음. D2·A2(원칙 절 안에 리뷰의 회복 약속이 같은 무게로). 두 곳 "관측". 높음.
- 1-4 `:List` keyFn이 이후 사이클에서 던지면 다음 `data:Set`에서 회복(`core/06` 401) — 자율. D2. 중.
- 1-5 Tween 콜백 던진 뒤 "정상으로 이어지지만"(`roblox/06-tween-animate.md` 322) — round12 G-27·묶음 1 code-review (b). D2. 짝 spec 2-3. 중.
- 1-6 Ref 던진 고아 인스턴스를 `q.dispose`하면 재사용(`core/07-ref.md` 70, `sugar/05-fallback-traceback.md` 39) — `H-612`/E5-2 자율; 2026-10-01 Q83은 *"문구만 사실대로"*로 복구 절차 승격을 안 한다고 했는데(근거 `fallback-plan.md` *"죽은 이후 어떻게 되냐는 우리가 손 안 본다"*) 이미 있던 문장이 남음. D2·A3, 사용자 한 줄 확인. 중.
- 1-7 `State<Ref>` 자리 `Quad0233` 뒤 "자리는 정상으로 다시 쓸 수 있습니다"(`core/07` 94) — 자율. D2. 중.
- 1-8 Tween 콜백 안 같은 프로퍼티 재쓰기 지원(`roblox/06` 320, CHANGELOG 13 Added "어느 콜백 안에서 같은 원천을 `:Set`해 다음 트윈을 이어도 됩니다") — round12 `H-589`는 UB로 둠(근거 `dispatch-core-plan.md` 1426 Q5 (a) "같은 `(inst, k)` 간접 재진입도 UB", 사용자 *"재진입 게이트는 허용 안한다가 내 생각"*); 2026-09-28 묶음 1 사용자 결정은 "모으고→쓰고→부른다" 프로토타입 채택(*"1. 확인. 2. … 3. 확인"*), "Property 층 재진입 UB는 풀렸다"는 메인이 끌어낸 서술(`tween-plan.md` 696 배너) — 재진입을 계약으로 올린다는 사용자 원문 없음, Q5 (a) 쪽엔 예외 미기재. A3·A2, 결정 필요(지원이면 Q5 (a)에 예외 한 줄, 아니면 문서·CHANGELOG "관측"). 중.
- 1-9 Slot 고리 예외 문장(`core/05` 103)의 "Effect의 무한 재실행처럼 끝나지 않습니다" — Effect엔 같은 날 1만 회 한도가 생겨 비유가 낡음; 부기 되감기 루프(`Bookkeeping.luau` 238 `while`, 262·278·294 되감기)엔 상한이 없음 — 사용자가 Effect 한도를 둔 논거(*"while 문 자체에 카운트를 정의할 수 있으니까 … stack overflow 같은 것에 의해 터지는 표면도 아니라서"*)가 이 루프에도 맞음. A3. 비유는 문서만, 되감기 한도는 결정 필요. 낡음 확신 높음, 발산 시 무에러 정지는 추측(미실행).
- 1-10 체계 문제 — `docs/reference/**`의 `[2026-09-2x mock 실측/관측]` 태그 71개(대부분 2026-09-27 자율 루프), 그중 약 30곳이 UB·던진 뒤 상태 안에서 결과를 단정형으로, "관측 — 계약 아님" 표시는 레퍼런스 전체 10곳뿐. 대표: core/05 235, core/06 390·405·621, core/07 123·355, core/09 380, extend/02 254·378·383, errors/02 47, errors/05 23. D1. 방향: (가) 규약 한 줄(docs-handover-registry 또는 레퍼런스 색인 — "UB·던진 뒤 문장 안의 날짜 붙은 mock 태그는 관측이지 계약 아님") 또는 (나) 자리마다 표시 — 규약이 쌈. 높음.
- 1-11 약함 — 정의된 경로의 통지 횟수를 표의 계약으로(core/06 132 Offset "두 번 통지 … 같은 길이여도", core/05 220 게이트 사본 "0회", sugar/03 46 수거 "최대 2×Time"). 문서 표시. 낮음.
- 문제없음 7: Compute 던진 뒤 회복(Q50 (a)), Observer 자가 치유(3′ 원문), Tween 콜백 순서 "항상"(docs-review 1-5), Q68 (b), `_seenRevision`(Q109), Slot 고리(2026-10-01 원문), 게이트 flush 중 하류 Effect 되쓰기.

## 2. spec이 UB 결과를 계약처럼
- 2-1 `spec.refhandlers` 4절(97, 단언 110 "re-entrant same-v re-dispatch is a no-op") — 2026-09-04 M8 brief §0 Q4 (a) 사용자 *"Q4: 동의"*(`ref-plan.md` 587·607); 사흘 뒤 2026-09-07 Q5 (a)가 같은 `(inst, k)` 간접 재진입 UB로 정하면서 Q4 (a)를 인용 안 함 — 이 장면이 정확히 그 모양. D1·A3, (나), 결정 필요(예외면 Q5 (a)에 한 줄, 아니면 spec "관측"). 순서 교체는 비용 0.
- 2-2 `spec.ref` 17(378, 단언 397) `H-569` round11 자율 — 던진 뒤 되꽂기 채워짐; CHANGELOG `[Unreleased]` Fixed에도. D2·D1, spec "관측", CHANGELOG 계약 여부 사용자 확인.
- 2-3 `spec.tweenproperty` 12(363~372) code-review (b) — 던진 `Cancelled` 뒤 상태. D2, spec 표시. (roblox 감사 (가)-1과 같은 건.)
- 2-4 `spec.tweenproperty` 12 머리(411) "Cancelled 안 재진입도 순서대로 한 트윈" — 1-8 결정 따름.
- 2-5 참고 `spec.effect` 12(538) — Q68 (b) 사용자 결정이나 절 머리가 yield 장면을 계약처럼(주석 546에만 "UB by contract") — yield 절반에 "관측" 손질.
- 확인: `spec.state` 6·14·15·16, `spec.gate` 10, `spec.observer` 9a·11·14, `spec.events` 9 — 이미 표시·정의 장면; `spec.lengthoffset` 5·14 — 되감기는 정의 경로(다만 장면이 Slot CRUD가 아니라 Offset Observer의 날 `Bookkeeping.setLength` — 사용자 논거가 핸들러 작성자 API에도 걸리는지 미확인, 낮음); `spec.debounce` 7·7d·10·10b·13; `spec.slot` Q52/Q74.

## 3. 결정 이력 표류
- 3-1 = 2-1(Ref Q4 (a) vs Q5 (a)).
- 3-2 = 1-8(Tween 재진입 UB 결정 vs 지원 서술 — 사용자 인용 옆에 메인 해석이 승인처럼).
- 3-3 `architecture.md` 517 "예외 안전성 계약" 절에 **사용자가 정한 회복 예외 목록이 없음**(Compute 세대 재실행 Q50 (a), Observer 자가 치유) — 대신 같은 절 529에 code-review 회복 문장(1-3)이 앉아 있어 레퍼런스가 회복 약속의 출처를 가릴 근거가 없고 1-1~1-7이 계속 생김. A2·D2. 방향: "사용자가 정한 회복은 이 둘뿐, 나머지 던진 뒤 서술은 관측" 목록. 높음.
- 3-4 `architecture.md` 548 "무엇이 debug 층인가" 첫 문장 "평소 경로에 검사 비용을 더하거나, 조이는 변경(돌던 코드를 에러로 깨는 것)이 되는 blame" — 같은 절 2026-10-01 사용자 결정 "싼 입구 검사(`Quad0259`·`0253`/`0254`·`0255` 류)는 평소 경로"와 어긋남(그 게이트들은 회고 1차 A9가 "조이는 게이트"로 분류), `conventions.md` 2026-09-30 보정과도. 문서만 — 첫 문장을 "평소 경로 비용"으로 좁히고 조이는 변경은 입구 검사 여부로. 높음.
- 3-5 = 1-9(부기 되감기 루프 상한 없음 — 결정 필요).
- 3-6 `H-240` Get 창 검사 ①②·`getOffsetAt` 재시작(`dispatch-core-plan.md` 2057·2270 "[2026-09-01 `H-240` (a) 사용자 확정] 채우기 루프가 자가 치유", 코드 `Bookkeeping.luau` 208·227·260·291) — 근거 장면(길이 Compute fn이 자기 owner를 `setLength`)이 Compute 순수성(UB) → Q50 이후 `Quad0184` 에러(`spec.lengthoffset` 10 제목). 회고 2차 A(8) "UB 전용, 고정 spec 없음, 사실상 죽은 코드"; 사용자 회신은 Get 루프·설치 루프만 걷었고 이 항목은 결정 기록 없음(round13 Q156 (b)는 메인 판정으로 "방어로 남김"). (나), 결정 필요(걷어낼 후보). 중.
- 3-7 미완 — `.claude/base/*.md`의 "사용자 확정/결정" 406줄 중 241줄이 같은 줄에 사용자 인용 없음(대부분 "`H-nnn` (a) 사용자 확정" 배치 회신 묶음 승인으로 보임) — 원장 대조 못 함(목록은 세션 스크래치에만, 세션 종료와 함께 사라짐).

## 4. CHANGELOG
- 4-1 게시 3.0.0~3.2.0 절 자체에 원칙 초과 없음(3.1.0·3.2.0 전부 사용자 결정; 3.0.0은 표면 전체 목록이라 M0~M11 자율 메커니즘 쪽 — 반응형 코어는 회고 2차가 덮었고 남은 건 3-6; 3.0.0 기준선 API 출처는 표본 둘만, 미완).
- 4-2 `CHANGELOG.md` 156(`[Unreleased]` Fixed) "yield하는 `:Compute` … 이제 그 두 경우는 피합니다" — Q93/Q98 가드 서술인데 2026-10-01 철거; 같은 `[Unreleased]` 39 "멈췄다 돌아온 계산을 따로 다루던 장치를 걷어냈습니다"와 반대. 게시 전이라 삭제. 높음.
- 4-3 `CHANGELOG.md` 150(Debounce `Time`) — "(타이머 콜백 안에서는 사용자 코드가 돌지 않습니다)"는 `H-662`가 틀렸다고 정정한 주장(`debounce-throttle-plan.md` 90), "잘못된 값이면 그 `:Set` 줄에서 던지고 게이트는 그 전 상태 그대로"는 `H-664`가 정정(`spec.debounce` 7 241 "the signal stays merged in the gate's set"과 반대) — plan·레퍼런스는 고쳤는데 CHANGELOG 미반영. 문서만. 높음.
- 4-4 = 1-8(CHANGELOG 13 Tween 콜백 재진입 지원 — 결정 필요).

## 미완
`getting-started`·`how-to`·`overview` 약속 문장(범위를 레퍼런스로만), 3-7 원문 대조, 4-1 3.0.0 기준선 API 전수, 1-9 발산 시 실제 정지 방식 실행 확인, spec 541절 중 키워드(throw·재진입·yield·되먹임·회복) 걸린 절만 본문.
