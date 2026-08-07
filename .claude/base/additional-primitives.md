# 추가 확정 프리미티브 — Blocker / Effect

**상태**: base — `research/additional-primitives-plan.md`(다른 프레임워크 대비
갭 분석)에서 갈라져 나온 두 확정 프리미티브. Batch(lexical block)/Context는
기각되어 각각 `archive/batch-rejected.md`/`archive/context-rejected.md`로,
아직 미확정인 키 기반 동적 컬렉션 재조정은 `research/additional-primitives-plan.md`에
그대로 남아있음 — 이 문서는 **확정된 것만** 다룬다.

## Blocker — 여러 Source를 한꺼번에 바꿔도 파생값 재계산이 한 번만 되게

**왜 필요한가**: `state1, state2 -> state3`처럼 여러 소스가 한 파생값에
합류할 때, 둘을 한 번에 바꾸면 소비자에게 두 번 전파(재계산+재대입)되는
문제. lexical `Batch(fn)`(Solid `batch()`/MobX `runInAction()`류)으로
풀려던 접근은 코루틴 yield 위에서 구조적으로 위험해 기각됨 — 상세 근거는
`archive/batch-rejected.md` 참고, 여기서 반복하지 않음. **Blocker는 그
문제를 콜스택/코루틴이 아니라 사용자가 들고 있는 "값"으로 표현**해서 이
위험을 구조적으로 우회한다.

**store 개발(M3)과 밀접하게 연관됨** — `state:Block(blocker)`가 State
위에 얹히는 메소드이므로 `base/store-semantics.md`의 Store/State/Source
온톨로지, 특히 push-invalidate/pull-recompute 전파 모델(`base/
bind-system-plan.md` "전파 모델 확정" 절)을 전제로 함. 별도 파일로 두되
State와 같은 마일스톤(`ROADMAP.md` M3)에서 함께 구현할 것.

### 메커니즘 (확정)

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
준다 — `store-semantics.md`의 "`Get()`은 라이브 레퍼런스를 준다" 원칙과 일치.

### 사용 예시

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

### 이름 확정

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

### 재진입(네스팅) — 의도적으로 미지원, 강한 문서화 필수

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

### 상태: 핵심 메커니즘+이름 확정. 남은 건 문서화뿐

`quadnomicon`에서 "Batch를 기각하고 왜 Blocker로 갔는가"를 비교 설명하는
게 좋은 소재(`archive/batch-rejected.md`와 나란히 인용).

---

## Effect — leaf 죽음에 확정 정리, 재실행 개념 없음

**Observer와는 별개의, 완전히 새로운 요소로 확정** — Ref/PreRef 같은
서로 파생된 관계가 아니라 독립적으로 존재하는 primitive. Roblox엔
`task.spawn`으로 코루틴에 반복문/타이머를 돌리는 패턴이 흔하고, Luau
테이블엔 `__gc` 같은 GC 시점 훅이 없어서 "이게 진짜 사라지는 순간"을 아는
유일한 방법은 `Instance.Destroying`류 명시적 신호뿐 — 이런 케이스(타이머
시작 → leaf가 죽을 때 반드시 정지)를 위한 별도 primitive로 합의됨.

```
Effect(fn) -> EffectHandle   -- fn을 즉시 1회 실행, 리턴값(nil | () -> ())은
                              -- 이 Effect가 바인드된 leaf가 죽을 때 정확히 1회 호출
```

**재실행 개념이 없다** — 값 변화에 반응해 다시 도는 건 Observer(+클로저로
직접 짠 cleanup)의 영역이고, Effect는 순수하게 "설치 + 확정 정리" 페어
하나만 담당한다. children 배열에 leaf로 놓는 기존 Observer 바인딩 패턴을
그대로 재사용(그 leaf가 살아있는 동안만 유효, leaf가 죽으면 정리 콜백
호출). 비용은 leaf당 실제 Destroying 바인딩 하나(공유 weak table로 되는
Observer보다 비쌈) — 필요할 때만 쓰는 걸로 충분.

**Observer에 cleanup 반환 계약을 추가하는 안은 기각됨** — React `useEffect`류로
`fn`이 `nil | () -> ()`를 반환하면 다음 재실행 직전에 그걸 불러주는 안을
검토했으나, 클로저 업밸류로 이미 쉽게 되고 잘 작동해서(`local lastConn;
state:Observer(function() if lastConn then lastConn:Disconnect() end;
lastConn = ... end)`) 프레임워크가 이걸 대신해줄 이유가 약하다는 판단 —
`state:Observer(fn)` 자체는 여전히 재실행 계약만 갖고, Effect가 별도로
"1회 설치 + 확정 정리"를 담당하는 이 분리 구조가 유지됨.

### ⚠️ 미해결 — Effect와 Observer의 관계, 사용자 확인 필요

**임의로 결론내지 않고 열어둠(2026-08-07 문서 정리 세션)**: 위 스펙은
`Effect(fn)`를 State에 종속되지 않는 완전한 자유 함수로 서술하지만, 아래
두 가지가 문서상 명확히 확인되지 않음:

1. **`Effect`가 실제로는 `state:Effect(fn)`처럼 State의 메소드(=Observer의
   변형, "재실행 없음 + 확정 정리 추가"만 다른 버전)로 구현/노출되어야
   하는 것 아닌가?** — 그렇다면 "독립 존재 가능한 프리미티브 vs 원천에
   종속된 파생 데이터"(`base/store-semantics.md`) 분류상 Effect도
   Observer처럼 후자(자유 함수 생성자 없음, 항상 `:` 메소드)로 재분류해야
   함. 지금 이 문서는 이전 조사(`research/additional-primitives-plan.md`)를
   따라 자유 함수로 서술했지만, 이게 최종 확정인지는 불명확.
2. **`state:Observer(fn)`가 생성 시점에 `fn`을 즉시 1회 실행하는지가 문서
   어디에도 명시돼 있지 않음** — `base/bind-system-plan.md`의 Observer
   절은 "값을 안 실어줌, `fn` 본문에서 `Get()`을 다시 읽어야 함"만
   명시할 뿐 "생성 즉시 1회 호출되는지"는 다루지 않는다. Effect는
   "즉시 1회 실행"이 스펙에 명시돼 있어 이 부분만 보면 둘이 겹쳐
   보인다.

이 두 질문이 풀리면 Effect가 (a) 완전히 별개인 자유 함수 primitive로
남는지, (b) `state:Effect(fn)`로 Observer 계열에 합류하는지가 갈린다.
**확인 전까지는 위에 적은 자유 함수 스펙을 잠정 스펙으로 두되, 구현
착수(M3~M4 전후) 전에 반드시 사용자와 다시 확인할 것** — `.claude/
question.md`에 같은 항목 등재됨.
