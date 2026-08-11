<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-09 세션 — `canBound` 이름 확정, `:Compute`의 `previous` 방어/스코핑
명확화, Modifier 핸들러 계층 값 UB→error 전환, Tween `initValue`/`useTween`
논의 신설

사용자가 `.claude/question.md`를 훑다 나온 여러 짧은 질문/제안을 한 번에
처리. 전부 `base/`/`research/`에 반영 완료:

1. **`Bound` → `canBound(handle): boolean` 탑레벨 함수로 확정** — 사용자
   제안("canExecute 같은 게 있으니 canBound로 넣어도 되지 않나"), raw
   불리언 필드를 직접 노출하는 대신 `canExecute`와 같은 결의 predicate
   함수로 감쌈. 동작 자체(leaf 부착과 `:Subscribe()`는 상호 배타, 위반
   시 즉시 에러)는 안 바뀜 — `base/bind-system-plan.md` "이중 바인딩
   금지" 절, `base/effect-plan.md`, `.claude/question.md` 반영.
2. **`:Compute(fn)`의 `previous` 인자 — 오버엔지니어링 의심 기각, 현재
   설계 유지.** `pre-implementation-audit.md` 3-1이 "클로저 업밸류로
   이미 되는 걸 별도 API로 만든 것 아니냐"고 의심했던 데 대해 사용자가
   직접 반박 — 클로저 업밸류 대안은 IIFE로 감싸는 준비 비용이 오히려
   `previous`라는 인자 하나보다 무겁고 번거로움. **부수적으로 스코핑도
   명확화**: 처음엔 `self.Cache`처럼 `previous`를 `self`(입력) 쪽에
   얹는 모양이 제안됐으나, `self`는 `:Compute`의 입력(receiver)이라
   같은 `self`에서 여러 `:Compute`가 갈라지는 팬아웃(`w:Compute(g1)`,
   `w:Compute(g2)`)이 있으면 `self.Cache` 슬롯이 충돌한다는 문제를
   검토 중 발견 — `previous`는 그 대신 "이 `:Compute` 호출 하나가 만든
   결과 State 노드" 자신에 귀속되는 것으로 정리(State가 호출마다 새
   노드를 만든다는 기존 온톨로지의 당연한 귀결이라 새 결정은 아님).
   `base/bind-system-plan.md`의 "previous" 절, `pre-implementation-audit.md`
   3-1 반영.
3. **Modifier 필드에 핸들러 계층 값(Ref/PreRef/Observer/Effect/Slot/
   Modifier)이 들어오면 UB 대신 즉시 `error`로 확정.** 기존
   "권장 사용법은 아니지만 막을 이유도 없음 — 방어 로직 없는 UB"였던
   것을, 이런 값의 실사용 case가 없다는 게 확인된 이상 조용한 UB보다
   그 자리에서 막는 쪽이 낫다는 사용자 판단으로 전환 — 이미 있는
   `Brand` 기반 predicate(`isRef`/`isPreRef`/`isObserver`/`isEffect`/
   `isSlot`/`isModifier`)를 제네릭 `__index` setter가 최종 저장 직전에
   확인하기만 하면 되므로 구현 비용 거의 0. `isSlot`/`isEffect`
   predicate가 `Brand` 절에 명시적으로 없던 갭도 같이 보강.
   `pre-implementation-audit.md`가 지적했던 "`State<Modifier>`는 방어,
   Ref/Slot은 무방비"라는 비일관성이 이걸로 절반 해소(메커니즘 차이는
   남지만 "막을 가치가 있다"는 판단은 통일) — `base/modifier-plan.md`
   "핸들러 계층을 모름" 절, `base/bind-system-plan.md`의 `Brand` 절,
   `pre-implementation-audit.md` 문서모순 절 반영.
4. **UI shorthand(UICorner/UIPadding/UIScale)가 Modifier 체이닝에서도
   되는지 — 이미 확정돼 있던 것 재확인, 새 결정 없음.** `mod:UICorner(8)`은
   그냥 제네릭 `__index` setter가 `UICorner` 필드를 채우는 것뿐이고,
   그 필드가 Modifier flatten을 거쳐 최종 props 테이블에 얹히든
   `Frame { UICorner = 8 }`처럼 순수 인라인으로 들어가든 UICorner
   Handler 입장에선 구분이 없음 — `base/ui-shorthand-plan.md`에 이미
   명시돼 있던 내용이라 문서 변경 없음.
5. **Tween `initValue`/`useTween` — 새 열린 논의 신설, 확정 아님.**
   사용자가 두 실사용 시나리오(다이얼로그 진입 애니메이션, 트윈 우회)를
   제기 — `initValue`(첫 마운트 시 시작값을 세팅 후 목표값으로 트윈)는
   재검토 끝에 필요성이 낮은 쪽으로 기움(재process 시 "최초 1회" 판별
   문제가 있어 보임), `useTween = state<boolean>`(트윈을 끄고 즉시
   스냅)은 필요성은 확인됐으나 정확한 모양/문서화 방식이 전혀 안
   정해짐 — `research/tween-plan.md`에 신규 절로 반영, M11 착수 전
   나중 세션에서 마저 정리하기로 함.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정/보강이라 M0 착수 우선순위 자체는 그대로.

**같은 세션 후속 — `State<Modifier>`도 UB 대신 명시적 `error`로 확정,
"핸들러 계층 값 → error" 원칙을 State/Source 쪽까지 완전히 통일.**
사용자 질문: "Modifier 필드"뿐 아니라 "State/Source 자체의 값이
Modifier인 경우"(`State<Modifier>`, `modifier-plan.md` 7번)도 같은
방식으로 막아도 되는지 — 확정. `isModifier` predicate를
`Source:Set()`/Store 생성 시 eager `Source(default)`/State의
`:Compute` 결과 캐싱 지점에서 확인해 런타임 `error`, 타입 차단(Luau
가능 여부 미검증)은 필수 방어선이 아니라 되면 좋은 보너스로 격하.
**Slot은 대조적으로 계속 허용** — 사용자 확인("slot은 당연히 가능함,
retract도 되는 애고 런타임 값이라"): Slot/Tag/Attribute/Tween 등은
정상적으로 process/retract 재귀 경로를 타는 진짜 dispatch 참가자라
State/Source 값으로 담겨도 기존 재귀 재-dispatch가 그대로 처리해줌 —
Modifier만 예외인 건 Modifier가 애초에 dispatch 경로 자체를 안 타는
유일한 존재라서. `base/modifier-plan.md` 7번, `base/store-semantics.md`
"따름정리" 절, `research/pre-implementation-audit.md` 2-2/문서모순 절
(완전 해소로 갱신), `.claude/question.md`, `ROADMAP.md` M7 반영 완료 —
이걸로 `pre-implementation-audit.md`가 지적했던 "State<Modifier>는
방어, Ref/Slot은 무방비"라는 비일관성이 완전히 해소됨.

**핸드오버 준비 완료** — 이번 대화(2026-08-08~09에 걸친 세션)에서 나온
결정은 전부 `base/`/`research/`/`question.md`/`ROADMAP.md`에 반영,
문서 간 참조도 동기화 완료. **다음 세션 예고(사용자 지정)**: Slot과
"State에서 Slot을 뽑아내는" 키 기반 동적 컬렉션 재조정(가칭 `Keyed`는
탈락, 최종 이름 미정) — `.claude/question.md` 0번 "키 기반 동적
컬렉션 재조정"이 이미 최우선 항목으로 잡혀있으니 그걸 이어서 보면 됨.

