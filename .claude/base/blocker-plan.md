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

**store 개발(M3)과 밀접하게 연관됨** — `state:Block(blocker)`가 State
위에 얹히는 메소드이므로 `base/source-state-plan.md`의 Source/State
온톨로지, 특히 push-invalidate/pull-recompute 전파 모델(`base/source-state-plan.md` "전파 모델 확정" 절)을 전제로 함. 별도 파일로 두되
State와 같은 마일스톤(`ROADMAP.md` M3)에서 함께 구현할 것.

## 메커니즘 (확정)

```
Blocker() -> blocker                -- 생성자
blocker:On() -> self                -- IsBlocked = true로만 설정, 그 외 아무것도 안 함
blocker:Off() -> self               -- IsBlocked = false로 먼저 설정, 그 다음 등록된
                                     -- onunblock 핸들 전부 실행(순서 무관, idempotent)

state:Block(blocker) -> state       -- 새 gated state 반환. **호출되는 즉시**(나중에
                                     -- 처음 블록될 때가 아니라) onunblock 핸들을
                                     -- blocker의 weak 배열에 등록.
```

gated state의 동작:
- 원본 state가 emit(무효화)될 때, 이 gated state로 전파를 시도.
- `blocker.IsBlocked`이면: 전파 안 하고 `HasBlockedEmit = true`만 세팅.
- `blocker.IsBlocked`가 아니면: 평소처럼 그냥 전파(투명하게 통과).
- `blocker:Off()`가 실행하는 onunblock 핸들은: `HasBlockedEmit`을 확인해
  true면 그제서야 정확히 1회 전파(emit)하고 플래그를 리셋. 이미 false면
  아무 것도 안 함(idempotent).

**`:Get()`엔 영향 없음** — 블록은 emit **전파**만 지연시킨다. 블록 중이라도
누군가 명시적으로 `:Get()`하면 그 순간의 실제 값을 정상적으로 계산해서
준다 — `base/source-state-plan.md`의 "Source 값을 직접 mutate한 뒤 전파 — `:Emit()`" 절("`Get()`은 라이브 레퍼런스를 준다" 캐비엇)과 일치.

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

## 상태: 핵심 메커니즘+이름 확정. 남은 건 문서화뿐

`quadnomicon`에서 "Batch를 기각하고 왜 Blocker로 갔는가"를 비교 설명하는
게 좋은 소재(`archive/batch-rejected.md`와 나란히 인용).
