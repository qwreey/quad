# 추가 프리미티브 필요성 조사 — 다른 프레임워크 대비 갭 분석

**상태**: research — 사용자와 라이브 논의로 수렴(2026-08-06~07). Context/
Batch(lexical)는 **기각 확정**. **Blocker**(새 primitive, Batch의 대안으로
채택)는 핵심 메커니즘+이름 확정, 문서화만 남음. 키 기반 동적 컬렉션
재조정은 설계 진행 중(사용자가 "작업 전에 모든 정의를 마치고 싶다"고
명시 — M0 전 완전 확정이 목표). Effect는 거의 수렴, 시그니처만 남음.

## 배경

사용자 질문: "다른 독립 프리미티브나 종속 파생 데이터는 뭐가 더 필요할 것
같나요. 이것만으로 이 프로젝트는 충분하다 생각해요?" — 지금까지 확정된
독립 프리미티브(`Source`/`State`/`Store`/`Ref`/`Observer`/`Modifier`/`Slot`/
`DI`)만으로 충분한지, 웹 프레임워크나 실제 Roblox 개발 관점에서 솔직하게
재검토해달라는 요청.

## 조사 방법

서브에이전트 여러 개를 병렬/순차로 띄워 조사(웹 프레임워크 서베이, Fusion/
Vide/v1/artworks 소스 근거 조사, Context 구현 난이도 판정) + 그 결과를
사용자와 라이브로 검증/반박/재조정. `research/framework-comparison-findings.md`
(quad vs Fusion/Vide/react-lua 강점/약점 비교)와는 다른 질문 — 그 문서는
"같은 개념을 quad가 얼마나 잘 구현했는가", 이 문서는 "개념 자체가 통째로
없는 게 있는가/필요한가".

## 결론 요약

| 후보 | 판정 | 상태 |
|---|---|---|
| 키 기반 동적 컬렉션 재조정 | **진짜 빈 자리, 최우선** | 설계 진행 중 |
| Effect(leaf 죽음에 확정 정리) | 진짜 빈 자리 | 거의 수렴, 시그니처만 남음 |
| **Blocker(값 기반 emit 지연/합치기)** | **채택** — Batch의 대안 | 핵심 메커니즘+이름 확정, 문서화만 남음 |
| Batch(함수/코루틴 스코프 lexical block) | **기각** | 결정 완료 |
| Context(트리 하위 암묵 전파) | **기각** — 대안(레이어드 Store)도 철회 | 결정 완료 |
| Observer에 cleanup 반환 계약 추가 | **기각** — 클로저 업밸류로 이미 충분 | 결정 완료 |
| Untrack/Peek | 빈 자리 아님 | - |
| Suspense/비동기 경계 | 빈 자리 아님(문서화 문제로 재분류) | - |
| Error Boundary | 빈 자리 아님 | - |
| Readonly wrapper | 빈 자리 아님 | - |

## 1. 키 기반 동적 컬렉션 재조정 — 최우선, 설계 진행 중

**무엇인가**: 데이터 배열(인벤토리, 리더보드, 채팅로그처럼 삽입/삭제/
재정렬되는 목록)을 UI로 렌더링할 때, 이전 렌더 결과와 새 데이터를
**정체성(key) 기준으로 diff**해서 변경분만 생성/갱신/파괴하는 프리미티브.
React `key` prop, Vue `v-for :key`, Solid `<For>`, Fusion `ForPairs`/
`ForKeys`/`ForValues`, Vide `indexes()`/`values()`가 이 층위. `base/
slot-plan.md`의 `Slot`은 CRUD 껍데기일 뿐 diff 엔진이 아니라서 이 프리미티브가
quad엔 없음(확인 완료, 근거는 문서 하단 소스 목록 참고).

### 왜 "매핑 함수" 직관이 안 통하는가

React류는 매 렌더마다 새 가상 트리를 통째로 새로 만들고 reconciler가
old/new를 diff한다 — 그래서 "그냥 다시 매핑"이 성립한다. quad는 컴포넌트가
**한 번만 실행**되므로 그 "매 렌더"가 아예 없다. 그래서 이건 매핑 함수가
아니라 **한 번 설치되면 스스로 diff-and-patch를 도는 Observer 변형**이다 —
전달한 `renderFn`은 새 key가 나타났을 때 딱 한 번만 불리고, 그 이후로는
값이 바뀌어도 절대 다시 안 불린다.

### 메커니즘 스케치

```
key가 새로 나타남     → renderFn(key, itemState) 호출, itemSource:Set(초기값), Slot에 삽입
key가 사라짐          → Slot에서 제거(파괴)
key가 유지, 값만 변경  → renderFn 재호출 없음, itemSource:Set(새값)만 → itemState 구독한 리프만 갱신
key가 유지, 순서만 변경 → renderFn 재호출 없음, Slot 위치만 조정(파괴/재생성 없음)
```

`itemState`는 이 프리미티브 내부 소유의 Source이고, `renderFn`엔 그 State
뷰만 노출한다(Source 자체를 주면 renderFn이 실수로 `:Set()`해서 diff
엔진과 경쟁할 수 있음).

### 폼 팩터 — 자유 함수로 정정 (State 메소드 프레이밍 철회)

이전 라운드에서 "독립 프리미티브 vs 원천 종속 파생 데이터" 원칙을 적용해
`state:Keyed(...)`처럼 **State의 메소드**로 두자고 제안했는데, 사용자가
정확한 반례를 지적함: **Source를 안 쓰는 컴포넌트는 이 메소드 자체에
접근을 못 한다.** 정적 데이터(한 번만 렌더되고 다시는 안 바뀌는 리스트)를
키 기반으로 렌더링하고 싶을 뿐인데 굳이 `Source(정적데이터)`로 감싸야
한다면 불필요한 강제다.

재검토 결과 — quad는 이미 **leaf 프로퍼티가 "리터럴 값 또는 State" 둘 다
받는 폴리모픽 컨벤션**을 갖고 있다(`BackgroundColor3 = someColor`도
`BackgroundColor3 = someState`도 같은 자리에서 됨, 정적이면 한 번만 세팅,
State면 구독). 이 프리미티브도 같은 컨벤션을 따르는 게 자연스럽다 —
**자유 함수**로 두고 `data` 인자가 plain array/table이든 `State<array>`/
`Source<array>`든 둘 다 받게 한다. Plain이면 diff 로직 자체가 발동 안 하고
(다시는 안 바뀌므로 최초 1회 배치만 하면 끝), State/Source면 위 메커니즘이
동작한다. 이름은 아직 미정이지만 시그니처 형태:

```
<이름>(data: {[K]: V} | State<{[K]: V}>, keyFn: (V, K) -> Key, renderFn: (Key, State<V>) -> Child) -> Slot
```

### Slot 확장 — `Extract`, 그리고 확정해야 할 소유권 모델

순서 변경(파괴 없이 위치만 옮기기)을 처리하려면 Slot에 **"파괴하지 않고
빼내기"** 연산이 필요하다. 기존 확정 사항(`slot-plan.md`):

> retract되는 slot은 옮겨지지 않고 그냥 폐기된다 ... React의 portal류로
> 나중에 옮길 수 있게 하는 것도 검토됐으나 이번 마일스톤에서는
> 오버엔지니어링으로 판단, 하지 않음.

이건 **"다른 Slot으로 옮기기"(portal)를 안 한다**는 결정이지 **"같은 Slot
안에서 위치만 바꾸기"**를 막는 결정이 아니다 — 순서 재조정은 후자만
필요하므로 이 결정과 충돌하지 않는다.

**사용자가 명확히 한 최종 소유권 모델(확정)**:
- **Slot 자체의 바인딩은 귀속·불가역** — 한 번 마운트되면 그 Slot 컨테이너
  자체를 다른 곳에 다시 바인드할 수 없음(기존 "재마운트 시 throw"와 동일).
- **Slot 안에 있는 개별 요소의 입출력은 자유** — 넣고 빼고 다시 넣는 것에
  제약 없음.
- **단, 요소의 `.Parent`를 Slot API를 거치지 않고 직접 만지는 건 UB.**

제안:

```
Slot:Extract(key) -> element   -- 파괴 없이 빼냄
Slot:Add(element, index?)      -- 기존 그대로, Extract로 뺀 것도 다시 넣을 수 있음
```

리오더는 `Extract` + `Add(index)` 조합으로 구현(별도 `Move`/`Swap` 원시
연산은 새로 안 만듦 — 원시 개수를 최소화). 덤으로 이게
`pre-implementation-audit.md` 1-8번("isMounted가 element 단위와 Slot
컨테이너 단위를 뭉뚱그려 서술됨")을 자연스럽게 푼다 — `Extract`가 있으면
"element의 mounted 여부는 가변, Slot 컨테이너 자체의 mounted 여부는
불변"으로 두 개념이 명확히 분리된다.

### 이름 후보 (확정 아님, 용어 정리 라운드 대상)

`Keyed`는 탈락 — 타이핑이 어색하고 "Slot을 렌더한다"는 느낌과도 안 맞는다는
사용자 피드백. 후보:
- `Render(data, keyFn, renderFn) -> Slot` — 가장 직접적("슬롯을 렌더한다").
  단, quad는 "렌더 주기가 없다"를 아키텍처 원칙으로 강조해왔는데 이 이름만
  "Render"를 쓰면 혼동 가능성 있음.
- `Draw(data, keyFn, renderFn) -> Slot` — 짧음, "Render"와의 충돌은 피하지만
  즉시모드 GUI(Dear ImGui류) 뉘앙스를 가져올 수 있어 quad의 유지형(retained)
  모델과 어긋나 보일 수 있음.
- `List(data, keyFn, renderFn) -> Slot` — 중립적, 결과가 "리스트"라는 것만
  전달, 메커니즘을 과다 암시 안 함.

세 후보 다 트레이드오프가 있어 확정 안 함 — `.claude/question.md`의 용어
정리 라운드에 후보로 올려둠.

### 남은 열린 질문

- 최종 이름(위 후보 중 또는 새 후보).
- `Extract`/`Add(index)` 조합의 정확한 시그니처(에러 조건: 이미 다른 Slot에
  있는 요소를 Add하면? 존재 안 하는 key를 Extract하면?).
- Fusion의 `ForPairs`/`ForKeys`/`ForValues` 3종 분리를 안 따르고
  `renderFn(key, itemState)` 1종으로 통합하는 안이 여전히 유력(단순화
  후보, `pre-implementation-audit.md`의 "단순화 후보" 렌즈와 같은 결) —
  최종 확정 아님.
- **목표: M6(Slot) 착수 전, 가급적 M0 스파이크 이전에 이 전체를 완전히
  정의**(사용자 명시적 요청) — 이 프리미티브가 Slot 자체의 CRUD 시맨틱
  (`pre-implementation-audit.md` 1-7, 지금 미정)과 얽혀 있어서, Slot을
  먼저 정하고 나중에 여기를 끼워맞추면 재작업이 날 가능성이 높음. Slot
  CRUD 시맨틱을 정의할 때 이 프리미티브의 요구사항을 같이 고려할 것.

## 2. Effect — 거의 수렴, 시그니처만 남음

### Observer에 cleanup 반환 계약을 추가하는 안 — 기각

React `useEffect`류처럼 "`fn`이 `nil | () -> ()`를 반환하면 다음 재실행
직전에 그걸 불러준다"를 `state:Observer(fn)`에 얹는 안을 검토했으나
**사용자가 기각** — 클로저 업밸류로 이미 쉽게 되고 잘 작동하는데
(`local lastConn; state:Observer(function() if lastConn then
lastConn:Disconnect() end; lastConn = ... end)`), 프레임워크가 이걸
대신해줄 이유가 약하다는 판단. 이건 `pre-implementation-audit.md`
3-1번("`:Compute(fn)`의 `previous` 인자 — 클로저 업밸류로 이미 되는 걸
별도 API로 만든 것일 수 있음")과 **정확히 같은 논리** — 일관성 있는
판단으로 보임(3-1 자체도 같은 이유로 재검토 대상일 수 있음, 별도 항목).

### Effect — 별도의 단순한 primitive로, "leaf 죽음에 확정 정리"만 담당

Roblox엔 `task.spawn`으로 코루틴에 반복문/타이머를 돌리는 패턴이 흔하고,
Luau 테이블엔 `__gc` 같은 GC 시점 훅이 없어서 "이게 진짜 사라지는 순간"을
아는 유일한 방법은 `Instance.Destroying`류 명시적 신호뿐이다. 이런
케이스(타이머 시작 → leaf가 죽을 때 반드시 정지)를 위한 별도 primitive는
필요하다는 데 합의:

```
Effect(fn) -> EffectHandle   -- fn을 즉시 1회 실행, 리턴값(nil | () -> ())은
                              -- 이 Effect가 바인드된 leaf가 죽을 때 정확히 1회 호출
```

Observer와 달리 **재실행 개념이 없다** — 값 변화에 반응해 다시 도는 건
Observer(+클로저로 직접 짠 cleanup)의 영역이고, Effect는 순수하게 "설치 +
확정 정리" 페어 하나만 담당한다. children 배열에 leaf로 놓는 기존 Observer
바인딩 패턴을 그대로 재사용(그 leaf가 살아있는 동안만 유효, leaf가 죽으면
정리 콜백 호출). 비용은 leaf당 실제 Destroying 바인딩 하나(공유 weak
table로 되는 Observer보다 비쌈) — 사용자가 필요할 때만 쓰는 걸로 충분.

**상태**: 사실상 수렴 — 시그니처(`fn`의 인자 유무, `EffectHandle`의 모양)만
다듬으면 `base/`로 승격 가능해 보임. 계속 논의 원하면 이어감.

## 3. Batch(함수/코루틴 스코프 lexical block) — 기각 확정

**중요**: 아래는 "값 기반 지연/합치기"라는 문제 자체를 기각한 게 아니라,
**그 문제를 lexical block(Solid `batch()`/MobX `runInAction()`류)으로
풀려는 접근만** 기각한 것이다. 실제 해법은 완전히 다른 별개 primitive인
**Blocker**(아래 3-1번)로 채택됨 — 이 절은 "왜 lexical 접근은 안 되는가"만
다루는 순수 반면교사 기록으로 남긴다.

### "즉시 pull"이 뭔지 (참고용 예시)

store-bind 핸들러(예: `Frame { BackgroundColor3 = total }`)는 lazy가
아니다 — 화면에 실제로 반영하는 "누군가"가 바로 이 핸들러 자신이라,
무효화 신호를 받자마자 스스로 `Get()`하고 바로 대입한다:

```lua
local total = a:With(b):Compute(function(av, bv) return av + bv end)
Frame { BackgroundColor3 = total }

a:Set(1) -- total 무효화 → 핸들러가 즉시 (av=1, bv=이전b)로 재계산+대입
b:Set(2) -- total 무효화 → 핸들러가 즉시 (av=1, bv=2)로 다시 재계산+대입
-- BackgroundColor3가 중간값을 한 번 거쳐가고, 두 번 대입됨
```

### 왜 lexical block 방식을 안 쓰는가

`Batch(fn)`을 "플래그 세우고 fn 실행, 끝나면 flush"로 구현하면 **fn이
yield하는 순간 위험해진다**(사용자 지적, 정확함):

1. 플래그가 전역이면, yield 중 스케줄러가 돌리는 무관한 코루틴의 `Set()`이
   이 Batch에 잘못 휘말릴 수 있음.
2. 플래그를 코루틴 스코프로 만들어도(Fusion `Contextual`류 코루틴 키 weak
   table), `fn` 안에서 새 코루틴을 스폰하는 API(Promise, `task.spawn`)를
   부르면 그 새 코루틴은 배치 스코프를 상속 못 받아 일부 Set이 새어나감.
3. `fn`이 영원히 재개 안 되면(장시간 대기, 리크된 코루틴) flush가 영영 안
   일어나 store-bind 핸들러들이 화면을 무기한 stale 상태로 방치 — 즉시
   pull보다 더 나쁜 실패 모드.

이건 구현을 잘 짜서 피할 수 있는 버그가 아니라 **lexical block 모델
자체가 협조적 스케줄링 환경과 구조적으로 안 맞는 것**으로 판단, 기각.

## 3-1. Blocker — 채택된 새 primitive (Batch의 대안, 2026-08-06~07 세션)

### 핵심 아이디어 — 콜스택/코루틴이 아니라 값으로 지연 구간을 표현

Batch가 실패하는 근본 이유는 "지연 구간"을 콜스택/코루틴 스코프로
표현하려 했기 때문이다. `Blocker`는 그 구간을 **그냥 사용자가 들고 있는
값**으로 표현한다 — `On()`/`Off()`를 부르는 두 시점 사이에 얼마나 많은
yield/코루틴 전환이 끼어도, 심지어 완전히 다른 코루틴에서 `Off()`를
불러도 아무 문제가 없다. Batch를 무너뜨렸던 세 가지 실패 모드(전역 플래그
오염, 새 코루틴 미상속, 영구 yield로 인한 무기한 방치)가 구조적으로 전부
해당 안 됨.

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
  아무 것도 안 함(이미 언블록 상태에서 다시 Off를 불러도 안전 —
  idempotent).

**`:Get()`엔 영향 없음** — 블록은 emit **전파**(eager 소비자에게 "바뀌었다"
알리는 신호)만 지연시킨다. 블록 중이라도 누군가 명시적으로 `:Get()`하면
그 순간의 실제 값을 정상적으로 계산해서 준다 — `store-semantics.md`의
"Get()은 라이브 레퍼런스를 준다" 원칙과 일치.

### 사용 예시 — `state1, state2 -> state3` 케이스의 정답

처음 문제 제기("state1, state2 -> state3로 갈 때 둘 다 업데이트하면 state3가
두 번 계산됨, 한번에 할 방법이 없다")에 대한 답: **`state3`(결합된 결과)
하나에만 `:Block`을 걸면 된다** — `state1`/`state2` 각각에 걸 필요 없음:

```lua
local blocker = Blocker()
local gated3 = state3:Block(blocker)  -- 소비자는 gated3를 구독

blocker:On()
state1:Set(1)  -- state3 무효화 → gated3로 전파 시도 → 블록됨 → HasBlockedEmit=true
state2:Set(2)  -- state3 무효화 → gated3로 전파 시도 → 이미 true, 그대로
blocker:Off()  -- onunblock 핸들 실행 → HasBlockedEmit 확인 → 딱 한 번 emit
```

**일반 사용 가이드(확정, 문서화 필수)**: Block은 **파이프라인의 최종
연산 지점**(실제로 무거운 계산이 일어나는 derived state, eager 소비자에
가장 가까운 지점)에 거는 게 원칙 — 소스가 여러 개든, 하나가 한 주기에
여러 번 바뀌든 상관없이 이 지점 하나만 지키면 됨. 소스 쪽에 각각 거는 게
아니다.

### 이름 확정

- 클래스: `Blocker` — `Observer`/`Modifier`/`Ref`와 같은 명사-행위자
  네이밍 관례와 일치.
- Blocker 자신의 토글: **`On()`/`Off()` -> self** (`Block()`/`Unblock()`
  아님) — `state:Block(blocker)`가 이미 "배선(wiring)" 동작의 동사로
  "Block"을 쓰고 있어서, Blocker 자신의 토글까지 같은 단어를 쓰면
  `blocker:Block()`(블로커를 켠다)과 `state:Block(blocker)`(state를 이
  블로커에 배선한다)가 같은 단어로 다른 두 동작을 가리키게 됨 — 자체
  API 안에서 `register`→`State` 리네임 때 겪었던 "모호함은 풀었는데
  충돌이 새로 생긴" 패턴이 반복될 뻔한 걸 미리 피함.
- 필드: **`IsBlocked`**(Blocker 자신의 On/Off 상태) — `Enabled`보다
  명확(enabled는 "정상 작동 중"으로도 읽혀 헷갈릴 수 있음).
- 필드: **`HasBlockedEmit`**(gated state의 대기 플래그) — `Is`/`Has`
  접두어로 불리언임을 바로 알려줌.
- 메소드: `state:Block(blocker) -> state`.

### 재진입(네스팅) — 의도적으로 미지원, 강한 문서화 필수

`IsBlocked`는 카운터가 아니라 단순 불리언이고, **의도적으로 그렇게
둔다.** 레퍼런스 카운팅으로 네스팅을 지원할 수도 있었지만, 그러면
"`On()` 여러 번, `Off()` 실수로 적게" 같은 버그가 **영구 블록으로 조용히
새는** 더 위험한 실패 모드를 만든다. 언어 차원에서 "On~Off 사이 코드가
죽었는지, 스레드가 죽었는지"를 추적하는 것도 해키해서 하지 않기로 함(Rust의
"poisoned mutex" — 락 구간 안에서 패닉이 나면 락이 오염 상태가 되는 것과
유사한 문제의식, 그 트래킹 자체를 만들지 않기로 함).

**대신 확정된 규칙**: 겹치는 배치가 필요하면 **각자 새 `Blocker` 인스턴스를
만들 것** — 하나의 Blocker를 여러 컨텍스트에서 재사용/중첩하지 않는다.
`Off()`는 스태킹 없이 즉시 그 자리에서 꺼진다. **이 제약은 반드시 사용자
문서(API 레퍼런스 수준)에 명시적으로 강조할 것** — 네스팅을 시도하면
조용히 잘못된 시점에 조기 해제되는, 원인 추적이 어려운 버그로 이어짐.

### 상태: 핵심 메커니즘+이름 확정. 남은 건 문서화뿐

`Extract`/`Add`처럼 세부 시그니처가 더 필요한 다른 항목들과 달리, Blocker는
설계 질문이 남아있지 않음 — `base/`로 승격 가능한 수준. quadnomicon에서
"Batch를 기각하고 왜 Blocker로 갔는가"를 비교 설명하는 게 좋은 소재(아래
"문서화 백로그" 참고).

## 4. Context — 기각 확정, 레이어드 Store 대안도 철회 (결정 완료)

### 난이도 판정 요약

서브에이전트 조사 결과: 동기적 저작 트리에 한정한 얕은 버전(Fusion
`Contextual`류 코루틴 키 weak table push-pop)은 구현 난이도 **낮음**이지만,
quad가 정상 패턴으로 확정한 "Slot에 이벤트 핸들러/코루틴에서 비동기로
자식이 추가되는 경우"엔 **에러 없이 조용히 기본값으로 폴백**하는 함정이
있음. 완전 자동(비동기 추가까지 자동 전파)은 Roblox Luau에
thread-local/async-context-propagation 훅이 없어 **사실상 불가**(플랫폼
한계, Node `AsyncLocalStorage`/Python `contextvars`도 "자동"이 아니라
"async 경계마다 명시적 캡처+재진입"으로 같은 문제를 품).

### 기각 이유

얕은 버전조차: (1) `base/slot-plan.md`가 정상 패턴으로 명시한 Slot 비동기
추가에서 가장 먼저, 가장 조용히 깨짐. (2) `research/debug-tooling-plan.md`의
"모든 연결은 선언된 그래프여야 한다"는 quad-debug 철학과 충돌하는 안 보이는
채널을 만듦.

### 레이어드 Store 대안도 철회 (사용자 반박 수용)

이전 라운드에서 대안으로 "레이어드 Store"(자식 Source 모음이 없는 키는
부모로 `__index` 폴백)를 권고했는데, 사용자 반박으로 철회함:

- quad는 이미 **타입으로 강제되는 명시적 Store 전달**을 갖고 있고, 이건
  Context의 "Provider 안 넣으면 조용히 기본값/에러"보다 **더 안전**하다
  (컴파일타임에 걸림 vs 런타임에 조용히 새는 값) — Context보다 나은 지점.
- "필드 일부만 오버라이드, 나머지는 부모 값 그대로"가 필요하면, 오버라이드
  지점에서 `Store({...부모값, 변경필드=새값})`을 **한 번 명시적으로**
  만들어서 그 지점부터 평소처럼 prop으로 넘기면 끝 — Modifier가 이미 쓰는
  "merge, 나중 게 이김" 패턴 재사용 가능, 새 primitive 불필요. 레이어드
  Store(읽는 시점에 몇 단계를 거슬러 올라가는지 안 보이는 자동 폴백)는
  정확히 Context와 같은 이유(디버깅 어려움 — "이 값이 왜 이거지?"를
  추적하려면 부모 체인을 다 훑어야 함)로 얻는 것보다 잃는 게 크다.
- 서드파티 라이브러리가 뭔가 필요하면, 타입이 강제하는 명시적 요구
  (`props.Theme: Store<Theme>`)가 "몰래 안 줘서 죽는다"보다 나은 실패
  모드 — Slot 기반 저작 모델(부모가 자손을 직접 구성)에서도 이런 요청은
  자연스럽게 props로 흐름.

### 결론

Context, 레이어드 Store 둘 다 프리미티브로 만들지 않음. "왜 Context가
없는가"(명시적 Store 전달이 이미 그 역할을 하고, 타입 강제가 Context의
실패 모드보다 안전하다는 논증)도 quadnomicon 에세이 후보로 등록(아래
"문서화 백로그" 참고).

## 빈 자리 아닌 것으로 확인된 것들

- **Untrack/Peek**(Solid `untrack()`, Vue `toRaw`): quad는 Vide식 암묵
  추적을 기각하고 `:With(...)` 명시적 의존성 선언을 택함 — "읽었지만
  추적 안 하고 싶다"는 필요 자체가 안 생김(`:With`에 안 넣으면 그게 곧
  untracked read). Vide `untrack()`은 암묵 추적 전용 문제라 quad엔 애초에
  적용 안 됨.
- **Suspense/비동기 경계**: `Ref:Wait()`(coroutine 대기) + 처음엔 nil인
  Source로 부분 커버되지만, **quad 컴포넌트가 한 번만 실행된다**는 전제와
  부딪히는 함정이 있음 — 렌더 함수 최상단의 `if loading then return
  Spinner end`류는 마운트 시점 단 한 번만 평가되고 데이터 도착 후
  재평가 안 됨. Slot + Observer 조합으로 실제 구현은 가능하나 1급 패턴이
  아니라서, 새 코어 프리미티브보다는 **"render-once 함정" 문서화
  우선순위 문제**로 재분류(`research/documentation-plan.md`의 권장 패턴
  문서 부류에 속함, React 습관 개발자가 특히 잘 빠질 실수).
- **Error Boundary**: quad 컴포넌트는 평범한 Lua 함수 호출이라, 리스트
  개별 아이템 생성 주변에 `pcall(MyComp, props)`를 감싸는 것만으로 React
  Error Boundary와 같은 격리 효과를 프레임워크 지원 없이 얻음.
- **Readonly wrapper**: `component-composition-plan.md`가 이미 "Source
  직접 전달은 좁은 케이스에 한정, 일반적으론 State + callback이 기본"으로
  못박아둬서 캡슐화 깨짐 문제 자체가 대부분 상황에서 안 생김.
- **Fusion `Observer`/`Attribute`**: quad `state:Observer(fn)` +
  `bind-system-plan.md`의 Attribute 논의로 이미 커버 중, 신규 아님.
- **디바운스/스로틀**: Fusion/Vide/v1 어디에도 공개 프리미티브로 없음 —
  세 레포 모두 없다는 것 자체가 "quad도 굳이 안 만들어도 된다"는 정황.

## 문서화 백로그 (2026-08-06~07, `documentation-content-map.md`에도 반영)

- **quadnomicon 에세이**:
  - "왜 lexical Batch를 기각하고 대신 값 기반 Blocker를 택했는가" — 코루틴
    yield 위험 분석(Batch 절)과 Blocker의 설계(3-1절)를 나란히 비교.
  - "왜 Context가 없는가"(명시적 타입 강제 Store 전달이 이미 그 역할을 함).
  - "왜 push-invalidate/pull-recompute 설계가 laziness와 재계산 방지를
    최우선 목표로 뒀는가" — Blocker 같은 파생 프리미티브가 이 목표 위에서
    자연스럽게 나온 이유까지 포함해 기존 심화 콘텐츠 후보 3번(`왜
    push-invalidate/pull-recompute인가`)을 더 깊게 확장.
- **심화 문서**:
  - "State 파생 체인 동작 원리" — emit이 아래로 전파되고, `Get()` 요청이
    위로 거슬러 올라가 재계산된 뒤 다시 아래로 내려오는 흐름을 명확히
    설명(Blocker/Effect 둘 다 이 흐름 위에서 동작하므로 선행 이해로 필요).
  - "`:Compute` 함수 안에서 `if` 등으로 일부 의존값만 조건부로 사용하는
    유연한 구조" — 명시적 의존성 선언(`:With`) 위에서도 실제 계산은
    조건부로 일부만 쓸 수 있다는 팁.
  - "Blocker 사용 가이드" — 파이프라인 최종 연산 지점에 배치, **네스팅
    금지를 강하게 명시**(위 3-1절 "재진입" 참고, 문서화 시 최우선 강조
    항목).
  - "여러 Source를 한꺼번에 바꿀 때 Blocker 없이도 중복 재계산을 피하는
    파이프라인/업데이트 순서 팁"(Blocker를 안 쓰는 단순 케이스용 보조 팁,
    기존 "심화 최적화 팁" 항목을 Blocker 존재를 전제로 재조정).

## 제안 우선순위

1. **키 기반 컬렉션 재조정** — 여전히 최우선, 설계 진행 중. M0 이전 완전
   확정이 목표.
2. **Effect** — 거의 수렴, 시그니처만 다듬으면 됨.
3. **Blocker** — 핵심 메커니즘+이름 확정, `base/`로 승격 가능한 수준.
   문서화(특히 네스팅 금지 강조)만 남음.
4. **Batch(lexical)/Context** — 둘 다 결정 완료(기각), 더 이상 검토 대상
   아님.

## 참고: 조사에 사용한 소스 근거

- Fusion: `State/ForPairs.luau`, `State/ForKeys.luau`,
  `Utility/Contextual.luau`, `Graph/Observer.luau`, `Instances/Attribute.luau`,
  `Memory/doCleanup.luau`
- Vide: `indexes.luau`, `values.luau`, `context.luau`, `batch.luau`,
  `action.luau`, `untrack.luau`, `cleanup.luau`
- quad v1: `store.lua`, `tracker.lua`, `class.lua`(diff/reconcile/keyed
  계열 헬퍼 없음, grep 확인)
- artworks: `EventDrivenProgramming/Observable.luau`, `Utility/Array.luau`,
  `GlobalDataStorage/request.luau`, `DeclarativeProgramming/DeclarativeInstance.luau`

경로는 모두 `.claude/initreq/<repo>/...` 기준(읽기 전용 참고 레포).
