# 사후 구현 감사 원장 (Round 12)

> **[2026-09-21 저녁 메인 판정 — 이 배너가 판정의 소스, 아래 원문은 그대로 보존]** 사용자가 반입한 Gemini 3.1 Pro **여러 에이전트의 결과 합본**이라 절 번호가 겹치고(`## 1.`·`## 2.`·`## 3.`이 두 번씩) "사용자 회신 대기 문항" 절 아래에 G-24~G-31이 놓여 있다 — 절 제목이 아니라 항목 번호로 읽을 것. 판정은 `external-review-entry.md` 7절의 세 갈래. 반영 원문은 `session/2026-09-21-03-round12-gemini-judgment.md`.
>
> **① 자율 반영(`H-589`~`H-593`)**
> - **`H-589`** (G-23·G-26, Gemini는 High·Medium) — 콜백 안에서 같은 프로퍼티를 다시 쓰는 재진입. 증상은 둘 다 실재한다: branch 3의 `Cancelled`는 이 호출이 자기 슬롯을 쓰기 **전에** 불리므로 그 안의 `:Set`이 만든 안쪽 레코드를 바깥이 덮고(G-23), 스냅의 `Completed`는 `Started` 뒤에 따라오므로 `Started` 안의 `:Set`이 시작한 새 트윈보다 옛 `Completed`가 늦게 난다(G-26). 그러나 이건 `dispatch-core-plan.md`의 "같은 `(inst, k)`의 간접 재진입도 UB"(2026-09-07 Q5 (a), 사용자: *"재진입 게이트는 허용 안한다가 내 생각"*)에 정확히 해당하므로 Gemini가 제안한 재진입 가드(콜백 반환·`GetStrong` 재확인·abort)는 넣지 않고 **UB로 문서화**했다 — `Handlers/Property.luau` 머리, 레퍼런스 roblox/06 콜백 절 한 문단, `tween-plan.md` 판정 문단. 같은 프로퍼티에 다음 트윈을 잇는 자리는 `Completed`다(엔진 경로에선 `process` 밖에서, 스냅에선 슬롯을 쓴 뒤에 불리므로 연쇄가 안전 — 손 트레이싱으로 확인).
> - **`H-590`** (G-28) — yield 중 파괴된 Effect의 cleanup이 `dying = false`를 받는 창. 실재하되 좁다: Deferred에서 `Destroy`는 gcconn을 동기로 끊고 `Destroying`은 다음 재개점에 보내므로, 파괴한 청크가 멈춰 있던 fn을 **직접 재개**할 때만(`task.wait` 재개는 통지 뒤) 꼬리 소진이 통지를 앞선다. `dying`의 정의가 "Destroying 콜백만 올린다"(Q57 사용자 원문)이고 fn 안 yield 자체가 UB라 코드는 그대로, `effect-plan.md` Q68 블록에 확인 기록 한 문단.
> - **`H-591`** (G-24·G-30) — `docs/skills/quad-ui-dev/` 스킬 문서 현행화(sonnet 반영, 메인 검토): 6.1 Tween 콜백 셋, 6.3 cleanup `dying` 인자·약한 구독 쌍, 이중 Claim 문구(`Claim: … is already claimed by quad`가 1패스에서 먼저), 7장 해시 키 행(`<Kind>: must be an array item …`), 그리고 네 파일의 백틱 에러 문구 전수 대조. `external-review-entry.md` §0 A가 이미 "stale"로 지목했던 자리.
> - **`H-592`** (G-31) — 15장 신설 재번호의 누락 둘: GS 18 머리 표의 `Animate(15)`·`Blocker(16)` → 16·17, GS 19의 `[19장](./20-wrap-up.md)` → 20장. 링크 번호와 파일 번호가 다른 곳을 docs/·base/ 전수 스캔해 이 둘뿐임을 확인.
> - **`H-593`** (G-25의 문서 부분) — `tween-plan.md` 철거 문단의 *"파괴된 인스턴스에서 트윈이 끝까지 돌아 `Completed`를 내는 엔진 동작은 연결이 먼저 끊겨 콜백에 닿지 않는다"*는 **틀린 문장**이었다 — 파괴 경로(`Destroy`/`q.dispose`/Slot 트리 파괴)는 프로퍼티 체인의 retractor를 돌리지 않는다(Dispatch·Bookkeeping에 `Destroying` 훅 없음, GS 19 그대로). 취소선 + 정정. 처방은 아래 `Q71`.
>
> **② 사용자 문항(§4 — `question.md` 2절에도 포인터)**
> - **Q71 (G-25, Gemini는 High).** 상황: 콜백을 실은 트윈이 도는 동안 인스턴스가 파괴되면(`Destroy`, `q.dispose`, 자리를 담은 Slot 트리 파괴) 프로퍼티 체인의 retractor는 돌지 않으므로 엔진 트윈은 파괴된 인스턴스 위에서 끝까지 돌고(실측 REPORT 5·6 — 연결도 그대로), `Completed`가 자연 완료 때 그대로 불립니다. `Cancelled`는 오지 않습니다(숏핸드 자식을 `nil`로 갈아 파괴하는 경로만 `H-218`대로 `retractFrom`을 먼저 돌려 `Cancelled`가 옵니다). 무엇이 막히나: 사용자가 `Completed`에서 "닫힘 뒤 처리"(소리 재생, 다른 State 갱신)를 하면 이미 내려간 UI에 대해 한 번 더 돕니다 — 콜백이 인자를 안 받아 인스턴스 고정은 없고, 파괴된 인스턴스에 프로퍼티를 쓰는 것 자체는 무해합니다. 갈래: (a) 문서만 — 레퍼런스 roblox/06 콜백 절에 "파괴는 되돌리기를 거치지 않으므로 도는 트윈은 끝까지 돌고 `Completed`가 그대로 온다, `Cancelled`는 교체·철거에서만"을 한 문단(GS 19의 `Destroy()` 답과 같은 결). (b) 콜백이 있는 레코드마다 `Backend.onDestroying(inst, …)`을 하나 더 걸어 파괴 때 `Cancel` + `Cancelled` — 새 메커니즘이고 연결 하나가 더 늘며, Deferred에선 그 통지도 다음 재개점이라 "즉시"는 아닙니다. (c) `Completed` 연결 안에서 인스턴스 생존을 검사해 죽었으면 안 부름 — 인스턴스를 클로저에 잡아야 해서 인자 없음 결정의 근거(고정)를 다시 엽니다. **권고 (a)** — "파괴는 자리별 되돌리기를 거치지 않는다"는 이미 세워둔 규칙이고 Effect cleanup만이 자기 수명 훅으로 예외인데, 트윈 콜백에 같은 예외를 하나 더 만들 실측된 필요가 아직 없습니다.
> - **Q72 (G-29, Gemini는 Medium).** 상황: `effect:Unsubscribe()`는 강한 레지스트리에서 자기를 지운 뒤 마지막 cleanup을 한 번 소비합니다. 그 cleanup 안에서 다시 `self:Unsubscribe()`를 부르면 레지스트리가 이미 비어 있어 `Effect: not subscribed strongly; use :WeakUnsubscribe()`로 던집니다 — 같은 cleanup이 재실행 전·죽음·자리 교체 소진에서 불렸다면(레지스트리가 아직 있어) 통과했을 호출입니다. 무엇이 막히나: cleanup은 자기가 왜 소비되는지 `dying` 말고는 모르므로 "확실히 하려고" 해제를 넣은 cleanup이 사용자 자신의 `Unsubscribe` 경로에서만 터집니다. 갈래: (a) 문서만 — core/05 Effect 절에 "cleanup 안의 `:Unsubscribe()`는 `fn` 실행 전·죽음·자리 교체 소진에서만 뜻이 있고, `:Unsubscribe()`가 소비한 cleanup 안에서 다시 부르면 이중 해제 에러"를 한 줄(이중 `Unsubscribe`는 원래 에러라는 기존 계약 그대로). (b) `_cleanupRunning`이 참인 동안의 두 번째 `Unsubscribe`를 no-op으로 — 기존 플래그 재사용이라 새 필드는 없지만, 약하게만 구독된 핸들의 cleanup(죽음 소진)에서 강한 해제를 불러도 조용히 통과하는 부수 효과가 생깁니다. (c) cleanup에 소비 이유 인자를 더함 — 새 표면. **권고 (a)** — 해당 모양이 "소비 중인 cleanup이 자기 소비의 원인을 다시 부르는" 순환이라 계약 쪽이 맞고, Q63 (b)가 연 것은 "fn 안에서 자기 해제"였지 이 모양이 아닙니다.
>
> **③ 확인 기록** — G-27(던지는 `Cancelled`로 `process` 중단): Gemini 스스로 기각한 대로 `architecture.md`의 "예외 안전성 계약" 그대로 UB. 다만 *"슬롯이 영구 고착"*은 틀렸다 — `Done`이 콜백 전에 서므로 다음 쓰기의 `stopRunning(prev)`는 그냥 돌아오고 새 값이 정상 진행한다(`H-582`). 기보고 확인 표의 `H-293` 시체 UB 제외는 맞다. S-17(`bindLifetime` 게이트 순서·`isHeldBy`)·S-18(yield 중 파괴 뒤 cleanup 1회 소진)·S-19(던진 뒤 해제 가능)·S-20(Claim 1패스 게이트)·S-21(`_owned == false` 파괴 분기)·S-22(시체 UB)·S-23(mock deferred 창 재현)·S-24(`Mapped` 콜백 복사)·S-25(11·13장 스냅샷) 전부 정본과 일치 — 새로 적을 것 없음. G-25·G-26·G-28·G-29의 "증상 확정, 처방 미정" 표기는 정확했고 처방은 위 배너가 정했다.


- **검토 일시**: 2026-09-21
- **검토 범위**: `quad-base`, `quad-roblox`, `quad-types`, `quad-error`, `scripts/` 등
- **진입 및 규약**: `.claude/qa-request/external-review-entry.md` 절차 준수, 외부 리뷰 번호 체계(`G-23`~, `S-17`~) 승계

---

## 1. 발견된 결함 및 개선 사항 (G-nn)

## 1. 기보고 확인 표 (3절)
| 항목 / 주제 | 기존 위치 및 결정 | 대조 결과 |
| :--- | :--- | :--- |
| 파괴된 인스턴스의 1패스 통과/2패스 실패 및 `holdLifetime` GC 의존 | `H-293`, `H-548`, `claim-plan.md` | **발견 제외**. 파괴된 인스턴스(시체)를 넘기는 것 자체가 의도된 UB(시스템 붕괴)이므로, 이에 따른 게이트 모순은 설계 명세에 부합함. (아래 S-22로 갈음) |

## 2. 신규 발견 (G-nn)

### [G-23] Tween 콜백 안에서 재진입(re-entrancy) 발생 시 `tweenSlots`가 덮어씌워져 엔진 트윈이 유실(Leak)되는 결함
- **위치**: `quad-roblox/src/Handlers/Property.luau` (92~157행 인근 `stopRunning` 및 호출부)
- **심각도**: High
- **설명**: 
  `Property.process` (값 교체) 또는 `tweenRetractor` (teardown)에서 기존 실행 중이던 트윈을 정리하기 위해 `stopRunning(prev)`를 호출합니다. 이 함수는 `Cancel()`을 부른 뒤 사용자 제공 콜백(`Started`, `Completed`, `Cancelled`)을 동기적으로 발화(`fire`)합니다. 이 콜백 내에서 사용자가 프로퍼티에 연결된 `State`를 변경(`:Set()`)하면, 동기적인 Quad 특성상 `process`에 다시 진입하게 됩니다.
  내부 재진입된 `process`가 새 트윈을 정상적으로 생성하고 `tweenSlots`에 최신 레코드를 기록하고 반환되지만, 실행이 일시 중지되었던 원래의 외부 `process`가 실행을 재개하면서 **내부 `process`가 만들어 둔 최신 `tweenSlots`를 자신이 애초에 기록하려던 낡은 값(`rec` 또는 `true` 등)으로 덮어씌워 버립니다.**
  결과적으로 내부 재진입에서 시작된 최신 엔진 트윈이 Quad의 추적망(`tweenSlots`)에서 유실되며(Leak), 이후 해당 프로퍼티에 대한 추가적인 덮어쓰기나 취소가 불가능해져 두 트윈이 겹쳐서 실행되는 치명적인 상태 불일치가 발생합니다.
- **해결 방향 (Re-entry Guard)**: 
  콜백 발화를 `tweenSlots` 갱신 이후로 단순히 미루게 되면 `이전 Cancelled → 새 Started`라는 필수 콜백 순서 불변식이 깨집니다. 이를 해결하기 위해 `stopRunning`이 직접 `fire`를 호출하는 대신 추출된 콜백을 호출자에게 반환하게 하고, 호출자는 새로운 값을 반영(`SetStrong`)하기 직전에 콜백을 먼저 실행해야 합니다. 단, 콜백 실행 직후 `tweenSlots:GetStrong(inst, k)` 값을 다시 읽어 자신이 처음에 쥔 `prev`와 달라졌다면, 더 최신의 업데이트가 재진입을 통해 이미 반영된 것이므로 외부 `process`는 즉각 자신의 값 갱신을 중단(abort)하고 빠져나와야 합니다.

## 2. 건전성 증명 (S-nn)

## 3. 사용자 회신 대기 문항 (평문)

### [G-24] `quad-ui-dev` 스킬 문서의 최신 구현 명세(Stale) 누락 및 에러 메시지 불일치
- **위치**: `docs/skills/quad-ui-dev/SKILL.md`, `docs/skills/quad-ui-dev/references/rules-and-invariants.md`
- **심각도**: Low
- **설명**: 
  최근 갱신된 엔진 명세가 에이전트 스킬 문서에 반영되지 않아, 에이전트가 낡은 문법이나 틀린 에러 메시지를 기준으로 코드를 작성하고 진단할 위험이 있습니다.
  1. **Tween 콜백 누락**: `SKILL.md`의 `6.1 Tween and Animate` 절에 최근 확정된 `Tween` 객체의 상태 콜백(`Started`, `Completed`, `Cancelled`) 사용법이 누락되어 있습니다.
  2. **Effect cleanup의 `dying` 인자 누락**: 메인 세션 Q57 결정에 따라 `Effect`의 정리(cleanup) 함수는 인스턴스가 파괴될 때만 `true`로 들어오는 `dying: boolean` 인자를 받도록 변경되었으나, `6.3 Refs and Lifecycle Hooks` 절에는 여전히 인자가 없는 것으로 묘사되어 있습니다. 또한 `WeakSubscribe`에 대한 설명도 없습니다.
  3. **이중 Claim 에러 메시지 갱신 지연**: `rules-and-invariants.md`와 `SKILL.md`는 이중 Claim 시 발화되는 에러를 `nativeClaim: Instance is already claimed by quad`로 안내합니다. 하지만 현재 `Claim` 로직은 1패스(`resolve`)에서 `isClaimed`를 먼저 검사하여 `Claim: {tostring(inst)} is already claimed by quad...` 표면 에러를 던지므로, 사용자와 에이전트가 실측 에러를 매핑하지 못할 수 있습니다.
- **해결 방향 (제안)**: 에이전트가 정확한 진단과 코드 생성을 할 수 있도록, 스킬 문서의 해당 절에 Tween 콜백 예제를 추가하고, Effect cleanup의 `dying` 시그니처를 반영하며, 진단 시트의 에러 메시지를 현행화해야 합니다.

### [G-25] `q.dispose(inst)` 등 인스턴스 파괴 시 진행 중인 엔진 Tween 미취소 및 파괴 후 `Completed` 발화
- **위치**: `quad-roblox/src/Handlers/Property.luau` 159~188줄, 300~317줄
- **심각도**: High
- **설명**: 
  `Property.luau`는 트윈을 취소(`Cancel()`)하는 로직이 `tweenRetractor`에만 구현되어 있으며, 인스턴스의 `Destroying` 이벤트를 구독하지 않습니다. `Dispatch`나 `q.dispose`가 인스턴스를 파괴할 때 프로퍼티의 `retractor`를 순회 호출하지 않고 약한 참조 수거에 맡기므로, 인스턴스가 파괴되어도 백그라운드 엔진 트윈은 멈추지 않습니다. 이후 트윈 시간이 만료되면 파괴된 인스턴스임에도 `Completed` 콜백이 그대로 발화되는 결함이 있습니다.
- **제안 갈래의 뜻**: 증상 확정, 처방 미정. (엔진 트윈 등록 시 `onDestroying`에 트윈 Cancel을 엮거나, `Completed` 리스너에서 인스턴스 생존 여부를 확인해야 함)

### [G-26] `Property.snap`의 `Started` 콜백 재진입 시 `Completed` 이벤트 조기/모순 발화
- **위치**: `quad-roblox/src/Handlers/Property.luau:152-157`
- **심각도**: Medium
- **설명**: 
  첫 세팅이나 `Time == 0` 트윈을 처리하는 `snap` 함수는 값 대입 후 `Started`와 `Completed`를 동기로 연달아 발화합니다. 만약 사용자가 `Started` 콜백 안에서 반응형 상태를 변경해 같은 프로퍼티에 새 트윈(예: 2초짜리 애니메이션)을 시작하면, 중첩된 처리가 끝난 직후 바깥 `snap`이 (이제 막 시작된 새 트윈이 도는 중에) 과거의 `Completed` 이벤트를 발화하는 논리적 모순이 발생합니다.
- **제안 갈래의 뜻**: 증상 확정, 처방 미정.

### [G-27] 던지는 콜백(`Cancelled`)에 의한 `Property.process` 중단 (예외 안전성 계약에 의해 기각 예정)
- **위치**: `quad-roblox/src/Handlers/Property.luau:148`
- **심각도**: Medium
- **설명**: 
  `process` 내에서 `stopRunning`이 `Cancelled` 콜백을 불렀을 때 이 콜백이 에러를 던지면 `process` 실행이 중단됩니다. 이로 인해 새 값 대입이나 새 트윈 시작, `tweenSlots` 갱신이 누락되어 프로퍼티 값은 중간에 멈추고 슬롯 상태는 영구적으로 취소된 트윈 레코드에 고착됩니다.
- **제안 갈래의 뜻**: **발견 기각 (의도된 동작)**. `architecture.md`의 "예외 안전성 계약" 조항에 따라, 콜백 내 예외(throw)로 인한 파동 중단은 의도된 UB(시스템 붕괴)이므로 결함이 아닙니다.

### [G-28] Yield 중 파괴된 Effect의 cleanup이 `dying=false`를 받는 결함
- **위치**: `quad-base/src/Effect.luau:160`
- **심각도**: Medium
- **설명**: 
  `Effect` 콜백(`fn`)이 yield하는 도중 인스턴스가 파괴되면 `gcconn`이 끊겨 `canExecute`는 즉시 `false`가 됩니다. `fn`이 깨어나면 `rawRerun`이 `not canExecute(self)`를 보고 즉시 `_consumeCleanup`을 부릅니다. 하지만 인스턴스의 `Destroying` 이벤트 발화가 다음 프레임으로 지연(deferred)되어 아직 도달하지 않았다면 `_dying` 플래그는 여전히 `false`입니다. 파괴된 인스턴스임에도 cleanup이 `dying=false` 인자를 받게 됩니다.
- **제안 갈래의 뜻**: 증상 확정, 처방 미정.

### [G-29] Effect cleanup 내부에서 `Unsubscribe` 호출 시 멱등성 파괴 및 에러
- **위치**: `quad-base/src/Effect.luau:268`
- **심각도**: Medium
- **설명**: 
  사용자가 명시적으로 `effect:Unsubscribe()`를 부르면 `Subscribed[self] = nil` 처리 후 `_consumeCleanup()`이 실행됩니다. 만약 `cleanup` 로직 안에서 확실한 정리를 위해 다시 `self:Unsubscribe()`를 부른다면, 이미 `Subscribed` 맵에서 지워진 상태이므로 "not subscribed strongly; use :WeakUnsubscribe()" 에러가 발화됩니다.
- **제안 갈래의 뜻**: 증상 확정, 처방 미정.

### [G-30] 에이전트 스킬 문서 내 추가 stale 에러 문구 (`Ref`/`Slot` 해시 키 에러)
- **위치**: `docs/skills/quad-ui-dev/SKILL.md:473`
- **심각도**: Low
- **설명**: 
  `H-566`에서 `Ref`나 `Slot`을 해시 키 자리에 넘길 경우 전용 가드(`Ref: must be an array item...`)가 도입되었으나, 스킬 문서의 7장 안티패턴 표에는 여전히 옛 에러 문구(`Dispatch: no handler matched key <K>...`)로 설명되어 있습니다.
- **제안 갈래의 뜻**: 제안 (문서의 에러 메시지를 최신 가드 메시지로 수정).

### [G-31] 시작하기 문서의 장 번호 참조 오기 (stale link & 번호 밀림)
- **위치**: `docs/getting-started/18-laziness.md:25-26`, `docs/getting-started/19-handlers.md:209` 등
- **심각도**: Low
- **설명**: 
  15장 신설로 장 번호들이 밀렸으나 문서 내 참조 텍스트가 갱신되지 않았습니다. 19장의 `[19장](./20-wrap-up.md)` 링크 오기 및 18장 머리말 표의 `Animate(15)`, `Blocker(16)` 옛 번호 표기 등이 남아있어 혼선을 유발합니다.
- **제안 갈래의 뜻**: 제안 (단순 번호 현행화 수정).

## 3. 건전성 확인 (S-nn)

### [S-17] `bindLifetime` 내부의 게이트 순서 및 `isHeldBy` 동작 건전성
- **위치**: `quad-base/src/LifetimeHandle.luau:121-144`, `quad-roblox/src/LifetimeHandle.luau:112-119`
- **확인 내용**: 
  `quad-base`의 `bindLifetime`에서 값 게이트(`canBound`)가 인스턴스 게이트(`Backend.holdLifetime` 내부)보다 먼저 돌도록 설계된 부분(`H-578` 대응)이 정상적으로 동작함을 확인했습니다. 
  만약 값이 이미 다른 인스턴스에 묶인 상태로 미-claim 인스턴스에 전달되면, 인스턴스 에러보다 "already bound to another Instance" 에러가 우선 발화됩니다. 이때 `Backend.isHeldBy`가 호출되는데, 타겟 인스턴스가 미-claim 상태일 경우 `InstData:GetWeak(inst, "gchold")`가 `nil`이 되어 `held == InstData:GetWeak(...)`가 `false`를 정확히 반환하므로 메시지가 오도되지 않습니다.

### [S-18] `Effect`의 fn yield 중 인스턴스 파괴 및 정리(cleanup) 건전성
- **위치**: `quad-base/src/Effect.luau`의 `rawRerun`, `_consumeCleanup`, `_bindDestroying`
- **확인 내용**: 
  `Effect`의 콜백(`fn`)이 yield(비동기 대기)하는 도중에 인스턴스가 파괴(`Destroying`)될 경우, `_bindDestroying`의 콜백이 발화되어 `_dying = true`를 설정하고 `_consumeCleanup()`을 부릅니다. 이 시점에는 `fn`이 아직 반환 전이라 `_cleanup`이 `nil`이므로 소비할 것이 없습니다. 이후 `fn`이 깨어나 새로운 cleanup을 반환하면, `rawRerun` 루프 끝단에서 `_dying == true`를 확인하고 즉시 다시 `_consumeCleanup()`을 호출하여 새롭게 등록된 cleanup을 정확히 1회 소진함을 확인했습니다.
  또한, cleanup 내부에서 스스로 해제(`Unsubscribe`)를 부르더라도, `_cleanupRunning` 플래그의 save/restore 패턴과 `_cleanup`의 사전 `nil` 초기화 덕분에 무한 루프나 상태 꼬임 없이 안전하게 처리됩니다.

### [S-19] `Effect` / `Observer` fn이 에러를 던진 뒤 강한 참조(Strong Keep) 해제 건전성
- **위치**: `quad-base/src/Effect.luau:278`, `quad-base/src/Observer.luau:173`
- **확인 내용**: 
  `Effect`나 `Observer`의 콜백(`fn`)이 도중 에러를 발생시키면 `_running = true` 상태로 영구 고착됩니다. 그러나 Q63 결정에 따라 `Unsubscribe` 메서드에는 `isRunning` 게이트가 없으므로, 사용자가 에러를 포착(catch)한 뒤 `:Unsubscribe()`를 부르면 정상적으로 `Subscribed[self] = nil` 처리가 이루어져 강한 참조가 해제되고 가비지 컬렉션(GC) 수거 대상이 됨을 확인했습니다. 아울러 `Observer`는 `_running`이 남아 있어도 수신 게이트에는 제약이 없으므로, 신호는 계속 받되 재구독만 막히는 명세대로 동작합니다.

### [S-20] `Claim` 1패스 `isClaimed` 게이트 검증의 건전성
- **위치**: `quad-base/src/Claim.luau:113-115`, `quad-base/test/mock.luau:728-735`
- **확인 내용**: 
  이전에는 DFS 트리를 탐색하며 자식들을 먼저 claim한 뒤루트를 claim하여, 중간에 실패 시 반쯤 claim된 트리가 남는 결함이 있었습니다. 현재 `Claim.luau`의 `resolve` 함수(첫 번째 유효성 검사 패스) 내에서 `module.Backend.isClaimed(inst)`를 호출하여, 대상 인스턴스나 자식이 이미 claim된 상태라면 어떠한 상태 변경(commit)도 일어나기 전에 즉시 에러(`Claim: ... is already claimed by quad`)를 내고 중단하도록 설계된 것이 완벽하게 건전하게 동작함을 확인했습니다. 
  Mock 백엔드 역시 `claimed` 플래그 하나로 통일하여 `roblox`와 동일하게 `isClaimed`에 응답하도록 정상적으로 패치되었습니다.

### [S-21] `Slot` 파괴(Destroy) 시 `_owned == false` 분기의 메모리 해제 건전성
- **위치**: `quad-base/src/Slot/Tree.luau:153-193`
- **확인 내용**: 
  `destroySlotTree`에서 대상 Slot이 `_owned == false` 속성을 가질 경우(즉, 래퍼이거나 단일 비소유 Slot인 경우), 단순히 뷰에서만 제거(unmount)되는 것이 아니라 루프를 돌며 자신이 품고 있던 원소들의 소유권(`S.releaseOwner`)을 놔주고 `_elements` 배열을 확실히 비워주는 처리가 추가(Q61 반영)된 것을 확인했습니다. 이를 통해 해당 요소들이 파괴되지 않고 자유 상태가 되어 다른 곳에 재마운트될 수 있으며, `_wrapped ~= nil`인 슈거 래퍼에 대해서도 내부 인스턴스를 정상적으로 놔주어 "already mounted" 상태로 고착되는 메모리 누수(Leak)를 방지하는 설계 명세가 건전하게 구현되어 있음을 검증했습니다.

### [S-22] 파괴된 인스턴스를 넘겼을 때의 오작동은 의도된 UB (H-293)
- **확인 내용**: `holdLifetime`이 시체(corpse)를 GC 이전에 조용히 통과시키는 현상이나, `Claim` 1패스 통과 후 2패스에서 에러가 나는 현상은 버그가 아니라, `H-293` 및 `claim-plan.md` 등에 규정된 "파괴된 인스턴스를 넘기는 것은 UB"라는 설계 의도에 정확히 부합하는 건전한 계약임을 확인했습니다.

### [S-23] `mockTween`의 Deferred 완료 창 재현 건전성
- **확인 내용**: `quad-base/test/mock.luau`의 `simulateCompleted`는 단일 스텝으로 동작하지만, `spec.tweenproperty.luau` 테스트는 `PlaybackState = "Completed"`만 설정하는 방식으로 실제 엔진의 deferred 이벤트를 테스트 갭 없이 흉내 내고 검증합니다.

### [S-24] `Tween:Mapped`의 상태 콜백 보존 건전성
- **확인 내용**: `Mapped`가 트윈 객체를 얕은 복사(`table.clone`)하므로 새롭게 추가된 `Started`, `Completed`, `Cancelled` 콜백 필드들이 소실되지 않고 프로퍼티 핸들러까지 온전히 전달됨을 확인했습니다.

### [S-25] 시작하기 문서 내 "지금까지의 코드" 스냅샷 정합성
- **확인 내용**: 11장, 13장 등에 포함된 이전 챕터 통합 코드 스냅샷이 누락이나 비약 없이 앞 장들의 빌드업 과정을 정확히 반영하고 있음을 대조 확인했습니다.

## 4. 열린 질문

(없음)
