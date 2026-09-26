# 묶음 1(Q91 b-OLD·Q92 b·Q99 c·Q82 a) 채택 시 문서 재작성 초안 (2026-09-27)

> **상태: 초안, 채택 결정 아님.** `qa-request/post-implementation-review-round13.md` §4 Q91·Q92·Q99·Q82와 §4 끝 "묶음 1·2 조합 검증"(`audit/round13-tween-bundle/`)이 이 초안의 소스 — 실기기 전제(같은 프레임 완료 통지 순서·`PlaybackState` 선행)는 그 문단이 이미 "미실측"이라고 적어 둔 그대로다. 이 초안은 **문서 문구만** 만들고 코드·스펙은 건드리지 않았다.

## 요약 — 무엇이 바뀌는가 (문서에 새로 들어갈 동작)

- **Q91 (b)-OLD-FIRST**: 같은 프레임에 옛 트윈 A가 이미 목표에 닿았지만 완료 통지가 아직 안 온 사이 새 값 B가 그 자리를 대체하는 "창"에서는, 지금까지 없던 문서 서술이 필요하다 — 순서가 **B 기록 → `Completed`(A) → `Started`(B)**로 일반 순서(이전 `Cancelled` → 새 `Started` → 새 `Completed`)와 달라지고, `Completed`(A) 안에서 같은 자리를 다시 잇는 연쇄가 B 자체를 대체하면 B는 `Started` 없이 `Cancelled`만 받는다(스냅 B는 콜백 자체가 안 뜬다).
- **Q92 (b)**: 패딩 숏핸드(`UIPadding`/`UIPaddingOffset`)의 콜백이 네 번(H-630)에서 **한 번**으로 준다.
- **Q99 (c)**: 자리가 철거되는 순간 A가 이미 끝났어도 `Completed`가 아니라 `Cancelled`로 통일해 부른다(기존 문서 "완료됐어도 아직 통지가 안 왔으면 그 자리에서 `Completed`"라는 서술이 없었으므로, 이건 문서에 처음 들어가는 캐비엇이자 동시에 통일 규칙이다).
- **Q82 (a)**: 인스턴스가 이미 파괴된 뒤 `retractFrom`을 직접 부르는 드문 경로에서 나던 `Cancelled`(그리고 창 경로의 `Completed`)가 조용해진다.

## 1. `docs/reference/roblox/06-tween-animate.md` (257~274행)

### Before (지금 문구, 그대로)

```markdown
**시작·완료·취소를 알립니다 — `Started` / `Completed` / `Cancelled`**

세 콜백은 전부 인자가 없고, 부르는 쪽은 프로퍼티 핸들러입니다.

| 콜백 | 불리는 때 |
|---|---|
| `Started` | 엔진 트윈을 재생한 **직후, 동기로**. 스냅(첫 세팅, 또는 `Info` 없는 `Time = 0`)에서는 값을 찍은 뒤 `Completed` 바로 앞에 |
| `Completed` | 트윈이 **자연히 끝났을 때만**(엔진 `Completed` 시그널의 `PlaybackState.Completed`) — 엔진이 그 시그널을 미루는 만큼 뒤에 옵니다. 스냅에서는 동기로. 도는 사이 인스턴스가 **파괴됐으면 불리지 않습니다**(아래) |
| `Cancelled` | quad가 **돌고 있던** 트윈을 끊는 그 자리에서 **동기로** — 새 값이 들어와 교체될 때와 자리가 철거될 때. 이미 끝난 트윈에는 불리지 않습니다(엔진이 목표에 닿았지만 통지가 아직 안 온 사이에 교체·철거가 오면 `Completed`가 그 자리에서 불립니다) |

그래서 교체 순서는 항상 **이전 `Cancelled` → 새 `Started` → (나중에) 새 `Completed`**입니다. 엔진의 취소 통지는 미뤄져서(다음 yield) 동기 교체에서는 새 트윈이 시작된 **뒤에** 도착하고, 이미 끝난 트윈에 `Cancel`을 해도 한 번 더 납니다 — quad는 그 통지를 쓰지 않고 자기 `Cancel` 호출 자리에서 직접 부르며, `Completed` 연결은 한 번 불린 뒤 스스로 끊습니다. 같은 목표라 건너뛴 `Tween`(`Dedup`)은 아무것도 부르지 않습니다.

**인스턴스가 먼저 파괴되면** — 파괴는 자리별 되돌리기를 거치지 않으므로([20장](../../getting-started/20-handlers.md)) 돌던 트윈은 끊기지 않고 파괴된 인스턴스 위에서 끝까지 돕니다. `Cancelled`는 오지 않고, 그 뒤 엔진이 보내는 완료 통지는 인스턴스가 더는 quad의 것이 아니므로 **무시됩니다** — `Completed`도 불리지 않습니다. 새 값으로 교체하거나 자리를 철거할 때만 `Cancelled`입니다. 콜백과 그 클로저가 잡은 값은 트윈이 끝나거나 끊기는 순간 놓입니다 — 다만 **끝나지 않는 트윈**(`RepeatCount = -1`)은 파괴로는 끊기지 않으니, 파괴 전에 값을 바꾸거나 자리를 철거해 끊으세요.

**같은 프로퍼티를 `Started`·`Cancelled` 안에서 다시 쓰지 마세요** — 두 콜백은 프로퍼티 핸들러가 그 자리를 처리하는 **도중에** 불리므로, 거기서 같은 자리에 묶인 State를 `:Set`하면 같은 자리의 재진입이고 정의되지 않은 동작입니다(다른 프로퍼티나 다른 State를 바꾸는 것은 괜찮습니다 — 위 `flash` 모양이 그것입니다). 다음 트윈을 같은 프로퍼티에 잇는 자리는 `Completed`입니다.

**숏핸드 `UIPadding`/`UIPaddingOffset`([02장](./02-d.md#숏핸드-키-넷))에 건 Tween 하나의 콜백은 값 하나에 네 번씩 불립니다** — 그 숏핸드가 관리 자식의 프로퍼티 넷(`PaddingLeft`/`Right`/`Top`/`Bottom`)에 같은 Tween을 각각 적용하기 때문입니다(mock 확인). 같은 Tween/State를 프로퍼티 둘 이상에 걸었을 때도 각각 불립니다 — `Completed` 안에서 같은 State를 `:Set`해 다음 트윈을 잇는 관용구는 이런 자리에서 네 통지가 같은 프레임에 겹쳐 위 재진입 캐비엇에 걸립니다(검토 중).
```

### After (초안)

```markdown
**시작·완료·취소를 알립니다 — `Started` / `Completed` / `Cancelled`**

세 콜백은 전부 인자가 없고, 부르는 쪽은 프로퍼티 핸들러입니다.

| 콜백 | 불리는 때 |
|---|---|
| `Started` | 엔진 트윈을 재생한 **직후, 동기로**. 스냅(첫 세팅, 또는 `Info` 없는 `Time = 0`)에서는 값을 찍은 뒤 `Completed` 바로 앞에. 아래 "같은 프레임에 겹치면" 창 안에서는 새 레코드를 먼저 적은 뒤에 옵니다(그 창에서 다시 대체되면 안 불릴 수도 있습니다) |
| `Completed` | 트윈이 **자연히 끝났을 때만**(엔진 `Completed` 시그널의 `PlaybackState.Completed`) — 엔진이 그 시그널을 미루는 만큼 뒤에 옵니다. 스냅에서는 동기로. 도는 사이 인스턴스가 **파괴됐으면 불리지 않습니다**(아래). 자리가 철거될 때는 이미 끝났어도 이 콜백이 아니라 `Cancelled`로 통일해 부릅니다(아래 "철거" 절) |
| `Cancelled` | quad가 **돌고 있던** 트윈을 끊는 그 자리에서 **동기로** — 새 값이 들어와 교체될 때와 자리가 철거될 때(철거 때는 이미 끝난 트윈도 이걸로 통일). 교체 창을 벗어난, 이미 끝난 트윈에는 불리지 않습니다 |

일반적인 교체 순서는 **이전 `Cancelled` → 새 `Started` → (나중에) 새 `Completed`**입니다. 엔진의 취소 통지는 미뤄져서(다음 yield) 동기 교체에서는 새 트윈이 시작된 **뒤에** 도착하고, 이미 끝난 트윈에 `Cancel`을 해도 한 번 더 납니다 — quad는 그 통지를 쓰지 않고 자기 `Cancel` 호출 자리에서 직접 부르며, `Completed` 연결은 한 번 불린 뒤 스스로 끊습니다. 같은 목표라 건너뛴 `Tween`(`Dedup`)은 아무것도 부르지 않습니다.

**같은 프레임에 옛 트윈의 완료와 새 값이 겹치면(교체 "창") 순서가 다릅니다.** 옛 트윈 A가 목표에 이미 닿았지만 엔진의 완료 통지가 아직 안 온 사이에 새 값 B가 그 자리에 오면, quad는 B를 자리에 먼저 적은 뒤 A의 `Completed`를 부르고, 그다음(B가 그사이 다른 값으로 대체되지 않았을 때만) B를 실제로 재생하며 `Started`를 부릅니다 — 순서는 **B 기록 → `Completed`(A) → `Started`(B)** 로, 위 일반 순서와 다릅니다. `Completed`(A) 안에서 같은 자리에 다음 트윈을 잇는 관용구(아래)를 이 창에서 써도 안전하지만, 그 연쇄가 B 자체를 다른 값으로 다시 바꾸면 B는 **`Started` 없이 `Cancelled`만** 받고(재생되지 못한 채 넘어갔으므로), B가 스냅(`Time = 0`)이었다면 그 스냅의 `Started`·`Completed`조차 불리지 않습니다(대체되어 재생되지 않음). 이 창은 숏핸드 `UIPadding`/`UIPaddingOffset`(아래) 하나에 콜백을 건 경우와, 한 값을 프로퍼티 둘 이상에 직접 건 경우에서 반드시 밟습니다. 같은 프레임에 끝나는 트윈들의 통지가 실제로 이 순서로 오는지는 mock으로만 확인했고, 실기기는 미확인입니다.

**자리가 철거될 때는 진행 중인 트윈만 끊습니다 — 기록은 남고, 통지는 항상 `Cancelled`입니다**

트윈이 흐르던 자리 자체가 철거되면(숏핸드 `UICorner = …`를 `nil`로 내려 관리 자식이 파괴될 때, `q.Dispatch.retractFrom`) 돌고 있던 엔진 트윈을 **취소**합니다 — 파괴된 인스턴스를 향해 트윈이 계속 돌지 않습니다. 이때는 들어오는 값이 없으므로 `Override`는 보지 않습니다(값이 그 자리에서 멈춥니다). 트윈이 이미 목표에 닿았지만 완료 통지가 아직 안 온 채로 철거되는 경우에도 `Completed`가 아니라 `Cancelled`로 통일해 부릅니다 — 자리가 사라지는 순간엔 "자연히 끝났는가"가 사용자에게 의미 있는 구분이 아니기 때문입니다. "첫 세팅은 스냅"의 기준은 **quad가 그 인스턴스의 그 프로퍼티를 처음 쓰는가**라서, 철거해도 "쓴 적 있음"은 남고 나중에 같은 자리에 오는 `Tween`은 애니메이션합니다. 취소 순간 프로퍼티가 목표값에 못 미쳤으면 그 목표만 잊어(같은 목표를 다시 선언해도 재생됨), 이미 목표값을 쥐고 있었으면(트윈이 끝난 뒤) 그 기록은 그대로라 같은 목표는 무동작입니다. **인스턴스가 이미 파괴된 뒤에** `q.Dispatch.retractFrom`을 직접 부르는 드문 경로에서는 이 `Cancelled`조차 조용해집니다(바로 아래 "인스턴스가 먼저 파괴되면"과 같은 이유 — 그 인스턴스는 더는 quad의 것이 아닙니다).

**인스턴스가 먼저 파괴되면** — 파괴는 자리별 되돌리기를 거치지 않으므로([20장](../../getting-started/20-handlers.md)) 돌던 트윈은 끊기지 않고 파괴된 인스턴스 위에서 끝까지 돕니다. `Cancelled`는 오지 않고, 그 뒤 엔진이 보내는 완료 통지는 인스턴스가 더는 quad의 것이 아니므로 **무시됩니다** — `Completed`도 불리지 않습니다. 새 값으로 교체하거나 자리를 철거할 때만 `Cancelled`입니다(위 캐비엇 참고). 콜백과 그 클로저가 잡은 값은 트윈이 끝나거나 끊기는 순간 놓입니다 — 다만 **끝나지 않는 트윈**(`RepeatCount = -1`)은 파괴로는 끊기지 않으니, 파괴 전에 값을 바꾸거나 자리를 철거해 끊으세요.

**같은 프로퍼티를 `Started` 안에서 다시 쓰지 마세요** — `Started`는 프로퍼티 핸들러가 그 자리를 처리하는 **도중에** 불리므로, 거기서 같은 자리에 묶인 State를 `:Set`하면 같은 자리의 재진입이고 정의되지 않은 동작입니다(다른 프로퍼티나 다른 State를 바꾸는 것은 괜찮습니다 — 위 `flash` 모양이 그것입니다). **다음 트윈을 같은 프로퍼티에 잇는 자리는 `Completed`입니다** — 위 "같은 프레임에 겹치면" 창을 포함해 이제 안전합니다(그 창에서 이어받은 트윈이 `Started` 없이 바로 `Cancelled`될 수 있다는 것만 위 캐비엇대로 알아두세요).

**숏핸드 `UIPadding`/`UIPaddingOffset`([02장](./02-d.md#숏핸드-키-넷))에 건 Tween 하나는 콜백을 한 번만 받습니다** — 관리 자식의 프로퍼티 넷(`PaddingLeft`/`Right`/`Top`/`Bottom`) 중 하나에만 콜백이 남고 나머지 셋은 값만 이어받기 때문입니다(mock 확인 — 완료 시점이 넷 다 같으므로 의미 손실은 없습니다). 같은 Tween/State를 프로퍼티 **둘 이상에 직접** 걸었을 때는(숏핸드가 아니라 사용자가 직접 건 경우) 여전히 각각 콜백을 받습니다 — 그 경우가 위 "같은 프레임에 겹치면" 창을 밟습니다.
```

## 2. `docs/getting-started/17-animation.md` (77행 근방)

### Before

```markdown
규칙은 셋입니다. `Started`는 트윈이 실제로 시작되는 순간, `Completed`는 **자연히 끝났을 때만**, `Cancelled`는 새 값이나 철거가 **돌고 있던** 트윈을 끊을 때만 불립니다. 교체될 때의 순서는 항상 이전 `Cancelled` → 새 `Started` → (나중에) 새 `Completed`입니다. 첫 세팅처럼 트윈 없이 바로 찍히는 경우에는 `Started`와 `Completed`가 그 자리에서 이어서 불리고, 같은 목표라 건너뛴 경우에는 아무것도 불리지 않습니다. 인스턴스를 직접 쥐지 않고 **원천을 거쳐 프로퍼티로 흘리는** 이 모양을 권합니다 — `Ref`로 인스턴스를 잡아 콜백 안에서 프로퍼티를 직접 쓰면 흐름이 두 방향이 됩니다.
```

### After (초안 — 튜토리얼 수준은 유지하고 예외는 심화 레퍼런스로 미룸)

```markdown
규칙은 셋입니다. `Started`는 트윈이 실제로 시작되는 순간, `Completed`는 **자연히 끝났을 때만**, `Cancelled`는 새 값이나 철거가 **돌고 있던** 트윈을 끊을 때만 불립니다. 교체될 때의 순서는 보통 이전 `Cancelled` → 새 `Started` → (나중에) 새 `Completed`입니다(같은 프레임에 트윈 여럿의 완료가 겹치는 드문 창에서는 순서가 달라집니다 — [레퍼런스 roblox 06장의 "프로퍼티에서의 동작"](../reference/roblox/06-tween-animate.md#프로퍼티에서의-동작)). 첫 세팅처럼 트윈 없이 바로 찍히는 경우에는 `Started`와 `Completed`가 그 자리에서 이어서 불리고, 같은 목표라 건너뛴 경우에는 아무것도 불리지 않습니다. 인스턴스를 직접 쥐지 않고 **원천을 거쳐 프로퍼티로 흘리는** 이 모양을 권합니다 — `Ref`로 인스턴스를 잡아 콜백 안에서 프로퍼티를 직접 쓰면 흐름이 두 방향이 됩니다.
```

(앵커는 `#프로퍼티에서의-동작` — 위 1절 인용 문단은 그 절 안의 **볼드** 하위 서술이라 자기 앵커가 없다, 실제로 그 파일 안 다른 곳(13·80·82행)도 전부 이 상위 헤딩 앵커로 링크한다 — grep으로 확인.)

## 3. `docs/skills/quad-ui-dev/SKILL.md` (397~421행)

### Before

```markdown
- `Started`/`Completed`/`Cancelled` are always **`() -> ()`** — no Instance is passed. A
  callback that captured the Instance would sit in the engine tween's connection and pin it
  alive for as long as that (inst, property) record holds a tween. Route state through a
  `Source` and drive `Visible`/etc. from it as a prop instead of writing the Instance directly
  in the callback.
- `Started` fires synchronously right after the engine tween is played (or, on a snap, right
  before `Completed`).
- `Completed` fires only on a **natural finish** (the engine's `Completed` signal with
  `PlaybackState.Completed`) — never for a cancelled tween, and not when the Instance was
  destroyed while the tween ran (a Destroy does not cancel the tween; its late notice is ignored).
- `Cancelled` fires synchronously at the moment quad cancels a still-running tween — a new
  value replaces it, or the slot is torn down. On replacement the order is always: old
  `Cancelled` → new `Started` → (later) new `Completed`.
- A `Tween` skipped by `Dedup` (same target as the recorded one) fires none of the three.
- A snap — the very first write to that (Instance, property), or an `Info`-less
  `Tween{ Time = 0 }` with no `DelayTime`/`RepeatCount`/`Reverses` — writes the value
  synchronously and fires `Started` then `Completed` back to back.
- Do **not** write the same property again from inside `Started` or `Cancelled` (a `:Set` on
  the State seated there): both fire while the property handler is still processing that
  slot, so it is same-key re-entry — undefined behaviour. Changing other States/properties is
  fine (the `flash` pattern above). Chain the next tween on the same property from `Completed`.
- `q.Animate{...}` accepts the same three fields and passes them through to the `Tween` it
  builds. With `CanAnimate = false` **and** any callback present, the property is still
  written synchronously, and `Started`+`Completed` fire together (so "motion off" does not
  also mean "finished handler never runs").
```

### After (초안)

```markdown
- `Started`/`Completed`/`Cancelled` are always **`() -> ()`** — no Instance is passed. A
  callback that captured the Instance would sit in the engine tween's connection and pin it
  alive for as long as that (inst, property) record holds a tween. Route state through a
  `Source` and drive `Visible`/etc. from it as a prop instead of writing the Instance directly
  in the callback.
- `Started` fires synchronously right after the engine tween is played (or, on a snap, right
  before `Completed`). In the same-frame overlap window below, it fires only after the new
  record has been written, and may not fire at all if that record is replaced again before it
  plays.
- `Completed` fires only on a **natural finish** (the engine's `Completed` signal with
  `PlaybackState.Completed`) — never for a cancelled tween, and not when the Instance was
  destroyed while the tween ran (a Destroy does not cancel the tween; its late notice is
  ignored). At teardown (the slot itself torn down, not replaced), a tween that had already
  reached its target but had no notice yet reports `Cancelled`, not `Completed` — see below.
- `Cancelled` fires synchronously at the moment quad cancels a still-running tween — a new
  value replaces it, or the slot is torn down (including one that had already reached its
  target when the teardown ran — reported as `Cancelled`, never `Completed`, once torn down).
  On an ordinary replacement the order is: old `Cancelled` → new `Started` → (later) new
  `Completed`.
  **Same-frame overlap window**: if the old tween (A) reached its target but the engine's
  `Completed` notice for A had not arrived yet when a new value (B) replaces it, quad instead
  records B first, fires `Completed` for A, and only then plays B and fires `Started` for it —
  order: record B → `Completed`(A) → `Started`(B), reversed from the ordinary case above.
  If a callback chained off `Completed`(A) itself replaces B before it plays, B fires
  `Cancelled` with no `Started` at all; if B was a snap, it fires neither. This window is hit
  whenever several tweens complete in the same frame — in particular the `UIPadding`/
  `UIPaddingOffset` shorthand (one callback per value now, see below) and any value bound
  directly to more than one property. Confirmed in mock only; the real-engine notification
  order for same-frame completions is unconfirmed.
- A `Tween` skipped by `Dedup` (same target as the recorded one) fires none of the three.
- A snap — the very first write to that (Instance, property), or an `Info`-less
  `Tween{ Time = 0 }` with no `DelayTime`/`RepeatCount`/`Reverses` — writes the value
  synchronously and fires `Started` then `Completed` back to back.
- Do **not** write the same property again from inside `Started` (a `:Set` on the State
  seated there): it fires while the property handler is still processing that slot, so it is
  same-key re-entry — undefined behaviour. Changing other States/properties is fine (the
  `flash` pattern above). Chain the next tween on the same property from `Completed` — this is
  now safe even inside the overlap window above (the corner cases noted there — no `Started`
  on B, or a swallowed snap — are the only exceptions).
- The padding/offset shorthand delivers each tween's callbacks **once** (one of the four
  managed properties carries them; the other three share the same tween silently). A value
  bound directly to more than one property still fires once per property.
- `q.Animate{...}` accepts the same three fields and passes them through to the `Tween` it
  builds. With `CanAnimate = false` **and** any callback present, the property is still
  written synchronously, and `Started`+`Completed` fire together (so "motion off" does not
  also mean "finished handler never runs").
```

## 4. `CHANGELOG.md` `[Unreleased]` — 기존 `Added` 항목 수정 (콜백 셋은 아직 미게시라 새 Changed 줄 대신 그 자리를 고친다)

### Before (지금 `[Unreleased]` → `### Added`의 해당 줄, 그대로)

```markdown
- `q.Tween{…}`(그리고 `q.Animate{…}`)에 콜백 셋 `Started`/`Completed`/`Cancelled`(인자 없음)가 생겼습니다. `Started`는 트윈이 시작된 직후, `Completed`는 **자연히 끝났을 때만**, `Cancelled`는 새 값이나 철거가 돌고 있던 트윈을 끊을 때 불립니다(순서는 이전 `Cancelled` → 새 `Started` → 새 `Completed`). 첫 세팅처럼 스냅되는 자리에서는 `Started`·`Completed`가 바로 이어서 불리고, `CanAnimate = false`여도 콜백이 있으면 그 둘은 불립니다. 트윈이 도는 동안 인스턴스가 파괴되면(파괴는 자리별 되돌리기를 거치지 않으므로 트윈은 끝까지 돕니다) 그 뒤의 `Completed`는 불리지 않습니다.
```

### After (초안 — 소비자 언어로, `H-nnn`/내부 경로 없이)

```markdown
- `q.Tween{…}`(그리고 `q.Animate{…}`)에 콜백 셋 `Started`/`Completed`/`Cancelled`(인자 없음)가 생겼습니다. `Started`는 트윈이 시작된 직후, `Completed`는 **자연히 끝났을 때만**, `Cancelled`는 새 값이나 철거가 돌고 있던 트윈을 끊을 때 불립니다(보통 순서는 이전 `Cancelled` → 새 `Started` → 새 `Completed`). 같은 프레임에 트윈 여럿의 완료가 겹치는 드문 창(패딩 숏핸드, 한 값을 프로퍼티 둘 이상에 직접 건 경우)에서는 순서가 달라집니다(레퍼런스 roblox 06장 참고) — 대신 그 창에서도 `Completed` 안에서 다음 트윈을 잇는 관용구는 안전합니다. 자리가 철거될 때는 트윈이 이미 끝났어도 `Completed`가 아니라 `Cancelled`로 통일해 부릅니다. 첫 세팅처럼 스냅되는 자리에서는 `Started`·`Completed`가 바로 이어서 불리고, `CanAnimate = false`여도 콜백이 있으면 그 둘은 불립니다. 트윈이 도는 동안 인스턴스가 파괴되면(파괴는 자리별 되돌리기를 거치지 않으므로 트윈은 끝까지 돕니다) 그 뒤의 `Completed`도 `Cancelled`도 불리지 않습니다.
- 패딩/오프셋 숏핸드에 건 트윈 하나는 이제 콜백을 값 하나에 **한 번만** 받습니다(전에는 관리 자식 넷이 각각 받아 네 번 — 완료 시점은 원래 넷 다 같았으므로 의미 손실은 없습니다).
```

(둘째 줄은 Q92만 채택하고 Q91은 안 채택하는 경우에도 유효하므로 항목을 나눴다 — 넷 다 같이 채택하면 첫 줄의 "같은 프레임에" 문장과 둘째 줄을 합쳐도 된다, 최종 편집은 사용자 판단.)

## 확인 못 한 것 (미완)

- GS 17장 링크가 가리키는 실제 앵커 슬러그(사이트 빌드에서 한글 헤딩이 어떤 문자열로 슬러그화되는지) — 이 초안은 `06-tween-animate.md`의 소제목 텍스트로 추정만 했다.
- Q91/Q92/Q99/Q82를 **부분만** 채택하는 조합(예: Q99만, Q91 없이)에서 이 초안의 문장들이 서로 안 맞아떨어지는 자리가 있는지 — 이 초안은 "묶음 1 전체 채택"만 가정했다.
- 위 CHANGELOG 초안의 "레퍼런스 roblox 06장 참고"라는 표현이 이 문서의 다른 CHANGELOG 항목들의 관례(내부 경로·문서 인용 자체를 안 쓴다)와 맞는지 — 관례는 "`H-nnn`·`.claude/` 경로 금지"라고만 돼 있어 공개 문서 상호 참조(roblox 06장)는 금지 대상이 아니라고 읽었지만, 지금 CHANGELOG의 다른 줄들은 실제로 문서 경로를 전혀 인용하지 않는다 — 이 표현을 뺄지는 사용자 판단.
