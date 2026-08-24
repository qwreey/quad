# Blocker — 여러 Source를 한꺼번에 바꿔도 파생값 재계산이 한 번만 되게

**상태**: base — `research/additional-primitives-plan.md`(다른 프레임워크
대비 갭 분석)에서 갈라져 나온 확정 프리미티브. lexical `Batch(fn)`으로
풀려던 대안은 기각되어 `archive/batch-rejected.md`로 분리됨 — 이 문서는
**확정된 Blocker만** 다룬다. `base/effect-plan.md`(같은 조사에서 나온
다른 확정 프리미티브)와는 서로 무관 — Blocker는 State/Store 작업과
밀접히 얽혀 있고 Effect는 완전히 독립된 요소라 원래도 별개 파일이었어야
했음(2026-08-07 문서 정리에서 한 파일로 합쳤던 걸 다시 분리).

**왜 필요한가**: `state1, state2 -> state3`처럼 여러 소스가 한 파생값에
합류할 때, 둘을 한 번에 바꾸면 소비자에게 두 번 전파(재계산+재대입)되는
문제. lexical `Batch(fn)`(Solid `batch()`/MobX `runInAction()`류)으로
풀려던 접근은 코루틴 yield 위에서 구조적으로 위험해 기각됨 — 상세 근거는
`archive/batch-rejected.md` 참고, 여기서 반복하지 않음. **Blocker는 그
문제를 콜스택/코루틴이 아니라 사용자가 들고 있는 "값"으로 표현**해서 이
위험을 구조적으로 우회한다.

**store 개발(M2)과 밀접하게 연관됨** — `state:Block(blocker)`가 State
위에 얹히는 메소드이므로 `base/source-state-plan.md`의 Source/State
온톨로지, 특히 push-invalidate/pull-recompute 전파 모델(`base/source-state-plan.md` "전파 모델 확정" 절)을 전제로 함.
**[2026-08-24 재확정] 구현 마일스톤은 다시 M2다 — "State와 같은
마일스톤에서 함께 구현"이라는 원래 서술이 맞다.** 2026-08-22엔 "게이팅
먼저"(`Dispatch.drive`의 배치 등록이 `Blocker`를 호출한다) 결정에 따라
`Blocker.luau` 체크박스를 디스패치 쪽으로 앞당겼었는데, 2026-08-24에
마일스톤 순서 자체가 교체되어(반응형이 M2, 디스패치가 M3) 앞당길 이유가
사라졌다 — 게이팅은 여전히 디스패치보다 먼저 지어진다. 별도 파일로 두는
것은 그대로.
**그리고 이제 `Blocker`는 바닥부터 짜는 게 아니라 공용 `GateNode`
(`base/gate-plan.md`) 위에 얹는 정책이다** — 노드를 다시 만들지 말 것.

**[2026-08-14 위치 명문화]** `Blocker`는 **quad에서 emit(무효화 신호) 전파를
지연시킬 수 있는 유일한 요소**임. 평범한 State는 신호를 받으면 자기
`invalid` 상태를 이유로는 **절대 전파를 접지 않고**(`base/source-state-plan.md`
"전파 모델 확정" 절), 그 흐름을 붙잡아둘 수 있는 건 명시적으로 배선된
게이트뿐 — 지금은 `Blocker`가 유일하고, 시간 기반 게이트(`base/
debounce-throttle-plan.md`, 설계 확정·구현은 아직)가 추가되면 같은 자리에
들어옴. 이걸 못 박아
두는 이유: 과거에 "이미 `invalid`면 전파를 멈춘다"는 서술이 base에
있었고, 그건 사실상 `Blocker`가 하는 일을 모든 State에 암묵적으로 심는
것이라 `Blocker`의 존재 의의를 반쯤 지워버렸음(역전 경위는
`archive/invalidate-dedup-propagation-reversed.md`).

## 메커니즘 (확정)

```
Blocker() -> blocker                -- 생성자
blocker:On() -> self                -- IsBlocked = true로만 설정, 그 외 아무것도 안 함
blocker:Off() -> self               -- IsBlocked = false로 먼저 설정, 그 다음 등록된
                                     -- onunblock 핸들 전부 실행(emit=true로, 순서 무관, idempotent)
blocker:OffWithoutEmit() -> self    -- [2026-08-18 신설] IsBlocked = false로 먼저 설정, 그 다음
                                     -- 등록된 onunblock 핸들 전부 실행(emit=false로) — 각 핸들이
                                     -- 자기 HasBlockedEmit은 그대로 리셋하되 실제 emit은 건너뜀.
                                     -- `Off()`와 내부 로직을 공유(아래 "onunblock 핸들" 참고),
                                     -- 차이는 넘기는 emit 플래그 하나뿐.
blocker:IsOn() -> boolean           -- [2026-08-18 신설] `self.IsBlocked`를 그대로 반환하는
                                     -- 얇은 조회 메소드 — 필드 `IsBlocked`는 그대로 유지(아래
                                     -- "이름 확정" 참고), 호출부 가독성만을 위한 추가.

state:Block(blocker) -> state       -- 새 gated state 반환. **호출되는 즉시**(나중에
                                     -- 처음 블록될 때가 아니라) onunblock 핸들을
                                     -- blocker의 weak 배열에 등록.
blocker:Policy(emit) -> onUpstreamEmit
                                    -- [2026-08-24 신설] 이 blocker의 게이트 정책을
                                     -- **값으로** 돌려준다. `state:Block(b)`가
                                     -- 내부에서 쓰는 바로 그것:
                                     --   state:Block(b)
                                     --     == state:Gate(function(emit) return b:Policy(emit) end)
                                     -- **[2026-08-24 정정]** 여기 `state:Gate(b.Policy)`라
                                     -- 적었었는데 그건 언바운드 메소드라 `emit`이 `self`
                                     -- 자리에 들어가 게이트가 영원히 안 열린다.
```

gated state의 동작:
- 원본 state가 emit(무효화)될 때, 이 gated state로 전파를 시도.
- `blocker.IsBlocked`이면: 전파 안 하고 `HasBlockedEmit = true`만 세팅.
- `blocker.IsBlocked`가 아니면: 평소처럼 그냥 전파(투명하게 통과).
- **onunblock 핸들은 이제 `emit: boolean` 인자를 받는다**(`blocker:Off()`/
  `:OffWithoutEmit()`가 공유하는 내부 실행 경로, 2026-08-18 신설) —
  `HasBlockedEmit`을 확인해 true면 `emit`이 참일 때만 그제서야 정확히
  1회 전파(emit)하고, `emit`이 거짓이면 전파 없이 플래그만 리셋. 이미
  `HasBlockedEmit`이 false면 `emit` 값과 무관하게 아무 것도 안 함
  (idempotent). 즉 `Off()`는 "밀린 전파를 흘려보내며 끈다",
  `OffWithoutEmit()`은 "밀린 전파를 버리며 끈다" — 어느 쪽이든 대기
  상태(`HasBlockedEmit`)는 항상 깨끗하게 리셋됨.

**⭐ [2026-08-21] `HasBlockedEmit`은 게이트 흡수 집합의 특수형이다.**
`GateNode`가 드는 `withheld`(이번에 유보한 소스들)에 대해
`HasBlockedEmit == (next(withheld) ~= nil)`이고, 아래 "밀린 전파가 없으면
아무 것도 안 함(idempotent)"이 게이트 층위에서는 **"빈 배치면 통지 자체를
안 한다"**로 일반화된다(`base/gate-plan.md`의 8번). 구현 시 두 개를 따로
들지 말 것.

**⭐ [2026-08-21 신설] `state:Block(blocker)`는 `state:Gate(setup)` 위에
얹힌다.** 위 "gated state의 동작"은 `Blocker`만의 특수 노드가 아니라
`base/gate-plan.md`가 확정한 **`GateNode`**(`ComputeNode`와 같은 층위)의
정책 하나다 — `Block`이 내부에서 `self:Gate(policy)`를 부르고, 그 `policy`가
`blocker.IsBlocked`를 보고 `emit()`을 부를지 `HasBlockedEmit`만 세울지
정한다. `Debounce`/`Throttle`도 같은 자리에 다른 정책으로 들어간다.

**⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-33`/`H-49`] 그 정책을 값으로
꺼내는 표면 `blocker:Policy(emit)`을 추가한다** — 표면이 하나 늘고,
`Blocker()` 생성자와 `state:Block`은 그대로다.

- **왜 필요한가**: `Debounce`/`Throttle`이 "언제 통과시킬지"를 정하면서
  실제 emit/보류 배선은 Blocker에 위임할 수 있어야 한다. 정책을 값으로 낼 수
  있으면 그게 그냥 함수 합성이 된다 — `setup`이 곧
  `(emit) -> onUpstreamEmit`이라 타입이 이미 맞는다.
- **정책이 하는 일은 안 바뀐다** — `Policy(emit)`을 부르는 시점에 onunblock
  핸들이 등록되므로(지금 `state:Block`이 하던 것과 같은 자리), `Off()`가
  풀 때 그 `emit`이 정확히 1회 불린다.
- **`Debounce`/`Throttle`은 Blocker를 사적으로 하나 갖는다** — 적용 핸들당
  하나(커링 결과가 여러 곳에 적용될 수 있으므로 `Apply` 시점 생성).
  `pending` 같은 상태는 별도로 안 들고 `HasBlockedEmit`으로 흡수한다.
  상세와 의사코드는 `base/gate-plan.md`의 5번 항목이 소스.

**`:Get()`엔 영향 없음** — 블록은 emit **전파**만 지연시킨다. 블록 중이라도
누군가 명시적으로 `:Get()`하면 그 순간의 실제 값을 정상적으로 계산해서
준다 — `base/source-state-plan.md`의 "Source 값을 직접 mutate한 뒤 전파 — `:Emit()`" 절("`Get()`은 라이브 레퍼런스를 준다" 캐비엇)과 일치.
**[2026-08-21] 이 계약은 `base/state-epoch-plan.md`가 의존하는 전제다** — 그
문서 §5의 3번이 "게이트를 에포크 경계로 만드는" 대안을 기각한 이유가 정확히
이걸 뒤집지 않기 위해서다. 바꾸려면 그쪽도 같이 봐야 한다.

## 사용 예시

`state1`/`state2` 각각이 아니라 **결합된 결과(`state3`) 하나에만** `:Block`을
건다:

```lua
local blocker = Blocker()
local gated3 = state3:Block(blocker)  -- 소비자는 gated3를 구독

blocker:On()
state1:Set(1)  -- state3 무효화 → gated3로 전파 시도 → 블록됨 → HasBlockedEmit=true
state2:Set(2)  -- state3 무효화 → gated3로 전파 시도 → 이미 true, 그대로
blocker:Off()  -- onunblock 핸들 실행 → HasBlockedEmit 확인 → 딱 한 번 emit
```

**일반 사용 가이드(확정, 문서화 필수)**: Block은 **파이프라인의 최종 연산
지점**(실제로 무거운 계산이 일어나는 derived state, eager 소비자에 가장
가까운 지점)에 거는 게 원칙 — 소스가 여러 개든, 하나가 한 주기에 여러 번
바뀌든 상관없이 이 지점 하나만 지키면 됨. 소스 쪽에 각각 거는 게 아니다.

## `state:Block()` 없이 직접 쓰는 두 번째 용례 — base 내부 부기 게이팅 (2026-08-18 신설)

지금까지 위 예시는 전부 `state:Block(blocker)`로 만든 **gated state**를
경유하는 사용자 대상 패턴이었다. `base/dispatch-core-plan.md`의
"Length/Offset" 절이 `recompute`의 크래시(`RC-1`, 배열 위치가 하나씩
순차 등록되는 동안 아직 등록 안 된 자리를 읽어 산술 에러가 나는 경로)를
고치며 **Blocker를 gated state 없이 직접 쓰는 두 번째 용례**를 만들었다
— **[정정, 2026-08-18 구현 전 QA 3라운드]** 그 크래시 자체는 이후
`bk.N`(순회 상한)의 정의를 고치며 사라졌지만(`base/dispatch-core-plan.md`
"저장 위치" 절), 이 용례는 그대로 유효하다 — 이유가 크래시 방지에서
배치 등록 비용(O(N²)→O(N)) 절감으로 바뀌었을 뿐. 콜백 안에서
`blocker:IsOn()`을 직접 확인하고 스스로 전파를 건너뛰는
방식(`Length` State의 Observer가 `if not blocker:IsOn() then recompute(...) end`
형태로 자기 자신을 게이팅). 이 용례는 `state:Block()`을 전혀 호출하지
않으므로 gated state도, 그 위에 걸리는 onunblock 핸들도 생기지 않는다 —
`blocker:Off()`/`:OffWithoutEmit()`을 불러도 실행할 핸들이 없어 두
메소드가 이 용례에서는 사실상 동일하게 동작하지만, **의도를 코드에 남기기
위해 `OffWithoutEmit()`을 쓴다**("이 배치가 끝나면 무엇이든 자동으로
흘려보내지 말고, 호출자가 직접 정확히 한 번 후속 작업을 한다"는 의도
표현). 상세 메커니즘·`Dispatch.setLength`/`setOffsetSource`가 이 Blocker를
어떻게 만들고 어디에 저장하는지는 `base/dispatch-core-plan.md`의 "배치
등록을 안전하게 만드는 Blocker 게이팅" 절이 소스 — 여기서 반복하지 않음.
**재진입(네스팅) 미지원 규칙은 이 용례에도 그대로 적용** — 중첩된 owner
(예: 부모 Slot 안의 자식 Slot)마다 각자 자기 owner 키로 별도 Blocker를
새로 만들어야 하고, 부모 Blocker를 재사용/전달하면 안 됨(아래 "재진입" 절).

## 이름 확정

- 클래스: `Blocker` — `Observer`/`Modifier`/`Ref`와 같은 명사-행위자
  네이밍 관례와 일치.
- Blocker 자신의 토글: **`On()`/`Off()` -> self** (`Block()`/`Unblock()`
  아님) — `state:Block(blocker)`가 이미 "배선(wiring)" 동작의 동사로
  "Block"을 쓰고 있어서, Blocker 자신의 토글까지 같은 단어를 쓰면
  `blocker:Block()`(블로커를 켠다)과 `state:Block(blocker)`(state를 이
  블로커에 배선한다)가 같은 단어로 다른 두 동작을 가리키게 됨.
- 필드: **`IsBlocked`**(Blocker 자신의 On/Off 상태), **`HasBlockedEmit`**
  (gated state의 대기 플래그, `Is`/`Has` 접두어로 불리언임을 바로 알려줌).
- 메소드: `state:Block(blocker) -> state`.
- **[2026-08-18 신설] `IsOn() -> boolean`**(`IsBlocked` 필드를 그대로 읽는
  얇은 조회 메소드), **`OffWithoutEmit() -> self`**(위 "onunblock 핸들"
  참고) — 사용자 확정: *"IsBlocked가 있다면 그냥 두어도 될듯 함.
  HasBlockedEmit 만 처리된다면 괜찮다 생각"* — 즉 `IsBlocked`/
  `HasBlockedEmit` 필드는 그대로 유지하고, 별도 `HasBlocked`(Blocker
  자신의 새 최상위 플래그)는 **신설하지 않는다** — `OffWithoutEmit()`이
  각 gated state의 기존 `HasBlockedEmit`을 그대로 리셋해주는 것으로
  충분하다고 판단됐기 때문(처음 제안됐던 "`HasBlocked`"는 이 논의
  과정에서 자연스럽게 불필요해짐 — `qa-request/pre-implementation-qa-round2.md`
  "RC-1" 절에 논의 경위 기록).
  **[보강, 2026-08-20 구현 전 QA 4라운드 `BK-9`] "영원히 안 만든다"로 못박은
  건 아니다 — 지금 사용 케이스가 없을 뿐인 백로그다.** 사용자 판정: *"있는게
  어렵지 않다고 보긴 하나, 사용 케이스가 없었을 뿐임 … 나중에 사용 필요 요구가
  나오면 그 때 구현하여도 될 요소로 보임. 아마 HasBlockedState 로 하나가
  신설될 가능성이 존재하지 않는다고 못 박기는 이름."* 즉 (a) 구현 난이도가
  낮고, (b) 신설된다면 이름은 `HasBlocked`가 아니라 **`HasBlockedState`**
  쪽이 될 가능성이 높으며(그 Blocker에 걸린 gated state 중 대기 중인 게
  있는가 = "블록된 state가 있는가"라 이름이 더 정직함), (c) 실제 요구가
  나오기 전엔 안 만든다 — `conventions.md`의 "드문 오용이나 가상의 미래
  요구까지 방어/최적화하려고 구조를 복잡하게 만들지 않는다" 원칙 그대로.

## 재진입(네스팅) — 의도적으로 미지원, 강한 문서화 필수

`IsBlocked`는 카운터가 아니라 단순 불리언이고, **의도적으로 그렇게 둔다.**
레퍼런스 카운팅으로 네스팅을 지원할 수도 있었지만, 그러면 "`On()` 여러
번, `Off()` 실수로 적게" 같은 버그가 **영구 블록으로 조용히 새는** 더
위험한 실패 모드를 만든다("poisoned mutex" 트래킹류 해키함도 만들지
않기로 함).

**대신 확정된 규칙**: 겹치는 배치가 필요하면 **각자 새 `Blocker` 인스턴스를
만들 것** — 하나의 Blocker를 여러 컨텍스트에서 재사용/중첩하지 않는다.
`Off()`는 스태킹 없이 즉시 그 자리에서 꺼진다. **이 제약은 반드시 사용자
문서(API 레퍼런스 수준)에 명시적으로 강조할 것** — 네스팅을 시도하면
조용히 잘못된 시점에 조기 해제되는, 원인 추적이 어려운 버그로 이어짐.

**base 내부 용례에도 이 규칙이 그대로 적용된 실제 사례(2026-08-18)** —
위 "`state:Block()` 없이 직접 쓰는 두 번째 용례" 절의 Length/Offset
배치 게이팅에서, 중첩된 Slot(부모 Slot 안의 자식 Slot)이 `attachSlot`을
재귀할 때마다(**[2026-08-21] 분해 후 정확히는 그 안의
`materializeSlotTree`** — 물리 마운트 쪽은 Blocker가 필요 없다)
**그 자식 Slot 자신의 owner 키로 새 `Blocker`를 만든다** —
부모 Slot의 Blocker를 재사용하지 않음(사용자 확정: *"중첩마다 별도
Blocker (권장)"*). 부모/자식이 같은 Blocker를 공유했다면, 자식의
`OffWithoutEmit()`이 부모가 아직 배치 중인데도 그 자리에서 즉시 꺼버려
부모의 나머지 등록이 게이팅을 잃는 사고가 났을 것 — 바로 위 문단이
경고하는 실패 모드의 구체 사례.

## 상태: 핵심 메커니즘+이름 확정. [2026-08-18 기준] 남은 건 문서화뿐

**[2026-08-18 갱신]** `IsOn()`/`OffWithoutEmit()`(위 "메커니즘" 절)과
`state:Block()` 없이 직접 쓰는 두 번째 용례는 이 날짜에 추가된 실제 API
확장 — "남은 건 문서화뿐"이라는 결론 자체는 안 바뀌었지만(API 표면과
메커니즘은 이 확장을 포함해 다시 확정 완료), 기준 날짜만 갱신.

`quadnomicon`에서 "Batch를 기각하고 왜 Blocker로 갔는가"를 비교 설명하는
게 좋은 소재(`archive/batch-rejected.md`와 나란히 인용).
