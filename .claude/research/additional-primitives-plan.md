# 추가 프리미티브 필요성 조사 — 다른 프레임워크 대비 갭 분석

**상태**: research — 조사 완료(2026-08-06), 사용자 판단 대기. 설계/구현 결정은
전혀 안 됨, 이 문서는 "뭐가 빠졌을 수 있는지" 후보를 정리한 것뿐.

## 배경

사용자 질문: "다른 독립 프리미티브나 종속 파생 데이터는 뭐가 더 필요할 것
같나요. 이것만으로 이 프로젝트는 충분하다 생각해요?" — 지금까지 확정된
독립 프리미티브(`Source`/`State`/`Store`/`Ref`/`Observer`/`Modifier`/`Slot`/
`DI`)만으로 충분한지, 웹 프레임워크나 실제 Roblox 개발 관점에서 솔직하게
재검토해달라는 요청.

## 조사 방법

서브에이전트 2개를 병렬로 띄워 서로 다른 각도로 조사:
1. **웹 프레임워크 서베이** — React/Vue 3/Solid/Svelte 5/MobX 등 주류
   반응형 프레임워크 기준, quad 프리미티브 집합에 빠진 개념이 있는지 일반
   지식 기반 평가.
2. **Roblox 생태계 소스 기반 조사** — Fusion(`initreq/fusion/src`),
   Vide(`initreq/vide/src`), quad v1(`initreq/quad/src`), PA님 실 프로덕션
   코드(`initreq/artworks`)를 직접 읽고 파일:라인 근거로 검증.

두 조사 모두 이미 있는 `research/framework-comparison-findings.md`(quad vs
Fusion/Vide/react-lua 강점/약점 비교)와는 다른 질문 — 그 문서는 "같은
개념을 quad가 얼마나 잘 구현했는가"를 다뤘고, 이 문서는 "개념 자체가
통째로 없는 게 있는가"를 다룸.

## 결론 요약

| 후보 | 판정 | 심각도 |
|---|---|---|
| 키 기반 동적 컬렉션 재조정 | **진짜 빈 자리** | 높음 — 가장 시급 |
| Effect/Watch(자동 cleanup 포함 사이드이펙트) | 진짜 빈 자리 | 중간 |
| Batch/Transaction | 부분적 빈 자리(이미 문서화된 churn 문제와 직결) | 중~낮 |
| Context(트리 하위 암묵 전파) | **기각 권고**(난이도 판정 완료, 2026-08-06) — 레이어드 Store로 대체 | - |
| Untrack/Peek | 빈 자리 아님 | - |
| Suspense/비동기 경계 | 빈 자리 아님(문서화 문제로 재분류) | - |
| Error Boundary | 빈 자리 아님 | - |
| Readonly wrapper | 빈 자리 아님 | - |

두 에이전트가 서로 독립적으로 **키 기반 리스트/컬렉션 재조정**을 가장 크고
명확한 빈 자리로 지목했다는 점이 이 조사에서 가장 신뢰도 높은 결론.

## 1. 키 기반 동적 컬렉션 재조정 — 진짜 빈 자리, 최우선 검토 대상

**무엇인가**: 데이터 배열(인벤토리, 리더보드, 채팅로그처럼 삽입/삭제/
재정렬되는 목록)을 UI로 렌더링할 때, 이전 렌더 결과와 새 데이터를
**정체성(key) 기준으로 diff**해서 변경분만 생성/갱신/파괴하는 프리미티브.
React `key` prop, Vue `v-for :key`, Solid `<For>`가 이 층위.

**Roblox 선례에 명확히 존재함**:
- Fusion `State/ForPairs.luau:46-89` — key/value 쌍마다 독립 `SubObject`를
  만들어 안 바뀐 키는 재계산을 건너뜀. `ForKeys.luau`도 같은 `For` 코어
  위에서 파라미터만 바꿔 변형.
- Vide `indexes.luau:11-119`, `values.luau:11-131` — 매 effect마다
  `scopes` 맵을 순회, 새 항목은 `branch()` 생성, 사라진 항목은
  `present(false)` 후 `destroy()`, 남은 항목은 값만 갱신(재생성 없음).

**quad엔 없음(확인 완료)**: `base/slot-plan.md`의 `Slot`은 `add`/`remove`/
`clear`/`get`/`set` CRUD를 지원하는 **뮤터블 배열**일 뿐, "입력 데이터를
주면 알아서 diff해서 CRUD를 호출해주는" 계층이 없음. `base/*.md` 전체를
grep해도 `ForPairs`/`ForKeys`/`keyed`/`diffing`류 언급 전무. quad v1에도
`diff`/`reconcile`류 헬퍼는 없었음(grep 확인) — v1 사용자도 이 문제를
프레임워크 밖에서 손으로 풀어왔다는 정황.

**실전 영향**: 지금 구조로 동적 리스트를 만들려면 "이전 렌더된 항목을
어딘가 들고 있다가 새 데이터와 직접 비교해 Slot의 add/remove를 손으로
호출"하는 로직을 화면마다 재발명해야 함 — Fusion/Vide가 라이브러리
차원에서 없애준 보일러플레이트(어떤 항목이 "같은 항목"인지, 순서가 바뀐
항목을 삭제+재생성할지 in-place로 옮길지)가 quad엔 그대로 남음. Slot
자체는 "부모는 데이터 테이블만 다루면 됨"이라는 좋은 저수준 기반이라,
그 위에 diff 알고리즘 한 겹만 얹으면 되는 구조적으로 자연스러운 확장으로
보임.

**PA님 코드 정황 증거**: artworks엔 실제 UI 화면 코드가 없어(백엔드/OOP/
데이터스토어 패턴 위주) 직접 증거는 못 찾았지만, `Utility/Array.luau`가
`map`/`filter`/`insert`/`isEqual` 같은 범용 배열 유틸을 팀이 별도로
만들어 쓰고 있었다는 점 자체가 "배열 반복 작업을 프리미티브로 뽑아내는"
습관이 있는 팀이라는 간접 방증.

**열린 질문**: Slot의 확장 옵션으로 넣을지, 별도 최상위 프리미티브(가칭
`Keyed`/`ForEach`/`List`)로 분리할지 — 설계 자체가 전혀 없는 상태. quad의
"명시적 의존성" 철학(`:With`)과는 직교하는 문제라 `:With`/`:Compute` 확장이
아니라 Slot 쪽 확장이 자연스러워 보인다는 게 조사 에이전트 소견이지만
확정 아님.

## 2. Effect/Watch(자동 cleanup 포함) — 진짜 빈 자리, 중간 심각도

React `useEffect`/Vue `watchEffect`/Solid `createEffect`는 "이펙트
재실행 전/dispose 시 이전 cleanup을 프레임워크가 자동으로 불러준다"는
계약을 가짐. quad `state:Observer(fn)`는 무효화 신호만 주고 cleanup 자동
관리가 없음 — `fn`이 매번 뭔가를 새로 구독/생성한다면 이전 것을 정리하는
책임이 전적으로 사용자 코드에 있음.

`process`/`retract` 쌍이 정확히 이 문제(이전 처리를 무르고 새로 처리)를
풀지만, 이건 base가 소유한 KV 핸들러 계층에 갇힌 내부 메커니즘이지 사용자가
임의의 부수효과(`RunService.Heartbeat` 구독, 폴링 타이머 등)에 쓸 수 있는
공개 API가 아님. 이미 증명된 내부 패턴을 사용자 레벨 `Effect(fn)`(반환값을
다음 실행 전 cleanup으로 호출)로 얇게 노출하는 정도로, 큰 설계 변경 없이
채울 수 있는 자리로 보임.

*참고*: Fusion `Cleanup`/`doCleanup`, Vide `cleanup()`은 "명시적 dispose
콜백 등록 리스트" 모델이라 quad의 GC-native 철학과 정면 충돌하고 이미
`base/comparison-fusion-vide.md`에서 반면교사로 다뤄짐 — 여기서 제안하는
건 그것과 달리 *cleanup 콜백을 자동으로 호출해주는 것*(dispose 리스트
직접 관리가 아님)이라 같은 문제가 아님, 혼동하지 말 것.

## 3. Batch/Transaction — 부분적 빈 자리, 이미 문서화된 문제와 직결

quad의 push-invalidate/pull-recompute 모델은 batching을 상당 부분 공짜로
줌 — `Get()`이 호출되기 전까진 `Set()`을 연달아 해도 재계산이 안 일어남.
다만 이미 문서에 자기진단된 예외가 있음: **store-bind 이벤트 핸들러는
무효화 신호를 받는 즉시 pull**(`bind-system-plan.md` "자주 재계산되는
State에 이벤트를 직접 물리면... churn 비용"). 즉 여러 Source가 `:With`로
물린 파생 State에 store-bind 핸들러가 붙어 있으면, 여러 `Set()`을 순서대로
실행하는 도중 중간 상태마다 핸들러가 여러 번 재실행되는 게 이미 확인된
시나리오. `Batch(function() ... end)`류 opt-in 유틸은 이론적 완결성이
아니라 **이미 확인된 실제 버그 클래스를 막는 것**이라 가치 있음 — 다만 새
프리미티브라기보다 dispatch 엔진에 얹는 얇은 유틸 수준.

Vide `batch.luau:4-21`가 정확히 이 역할(여러 `source:set()`을 하나의
flush로 묶음).

## 4. Context(트리 하위 암묵 전파) — 난이도 판정 완료, 기각 권고 (2026-08-06)

Fusion `Utility/Contextual.luau:28-88`(코루틴 키 weak table push-pop), Vide
`context.luau:14-72`(scope 그래프 조회)가 대응 개념. 서브에이전트에게 구현
난이도 평가를 위임한 결과(상세 근거는 아래 "진행 중 논의" 절의 Context
서브섹션 참고), **동기적 저작 트리 안에서만 작동하는 얕은 버전은 구현
난이도가 낮지만(Fusion 코드를 사실상 그대로 이식 가능), quad가 이미
정상 패턴으로 확정한 "Slot에 이벤트 핸들러/코루틴에서 비동기로 자식이
추가되는 경우"엔 조용히 기본값으로 폴백하는 함정이 생김**을 확인 —
Roblox Luau에 thread-local/async-context-propagation 훅이 없어 완전
자동화는 사실상 불가능(플랫폼 한계, 구현 노력의 문제가 아님). Node
`AsyncLocalStorage`/Python `contextvars`가 같은 문제를 "자동"이 아니라
"async 경계마다 명시적 캡처+재진입"으로 푸는 것과 동일한 결론.

**기각 권고 근거**: 얕은 버전조차 (a) quad가 스스로 정상 패턴으로 확정한
Slot 비동기 추가에서 가장 먼저 깨지고, (b) `research/debug-tooling-plan.md`의
"모든 연결은 선언된 그래프여야 한다"는 quad-debug 철학과 충돌하는 안 보이는
채널을 만듦. 대신 **레이어드 Store**(자식 Source 모음이 자기한테 없는 키는
부모로 `__index` 폴백 — Modifier/Source가 이미 쓰는 델리게이션 패턴과 동일
계열)가 Context의 핵심 가치(서브트리별 오버라이드)를 명시적 전달 철학과
비동기 안전성을 유지하면서 대부분 재현함 — 오버라이드 Store 참조는 여전히
prop으로 명시 전달해야 하지만, 이건 `component-composition-plan.md`가 이미
확정한 비용이라 새로 감수하는 게 아님. Roblox `require()` 캐싱 싱글톤(단일
전역, 서브트리 오버라이드 불가)은 오버라이드가 필요 없는 단순 케이스에는
여전히 충분.

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

## 제안 우선순위 (결정 아님, 검토 순서 제안)

1. **키 기반 컬렉션 재조정** — 실전 영향이 가장 크고, 설계가 완전히
   빈 상태라 가장 먼저 사용자와 상의할 가치.
2. **Effect 공개 API** — `process`/`retract`가 이미 증명한 패턴을 얇게
   노출하는 정도라 구현 비용 낮음.
3. **Batch** — 이미 문서화된 churn 문제의 직접 해법, opt-in 유틸 수준.
4. **Context** — 기각 권고(2026-08-06 난이도 판정 완료). 서브트리 오버라이드가
   실제로 필요해지면 Context가 아니라 **레이어드 Store**를 검토할 것.

## 진행 중 논의 (2026-08-06 후속 세션)

메인 브랜치에 병합된 `pre-implementation-audit.md`의 1-7번("Slot의
`add`/`remove`/`clear` CRUD 의미론이 정의돼 있지 않음")과 정확히 맞물리는
타이밍이라, 키 기반 컬렉션 재조정을 Slot 설계에 바로 접목해보는 논의 시작.

### 키 기반 컬렉션 재조정 — 설계 스케치 (확정 아님)

사용자가 처음부터 "Slot의 상위 요소"로 만들고 싶다고 명시 — 두 가지 프레이밍을
제시함: (a) Slot을 만들어주는 팩토리 함수, (b) State의 "터미널 연산"(스트림의
`.collect()`류)으로 Slot을 얻는 것(`state:?() -> Slot`).

**두 프레이밍 중 (b)가 quad의 기존 원칙과 더 잘 맞음** — 2026-08-06 세션에서
이미 확정된 "독립 프리미티브 vs 원천 종속 파생 데이터" 원칙(`state:Observer(fn)`가
메소드고 자유 함수가 아닌 이유와 같은 논리, `store-semantics.md`)을 그대로
적용하면: 키 기반 Slot은 그 뒤에 있는 State 없이는 존재 의미가 없는 **파생
데이터**이므로, 자유 함수 팩토리(`Type(args)` 패턴)가 아니라 **State의
메소드**로 두는 게 일관적. 가칭 `state:Keyed(keyFn, renderFn) -> Slot`.

**메커니즘 스케치**(전부 이미 확정된 조각들의 재조합 — 새 마운트/디스패치
장치 불필요):
- 내부적으로 `state:Observer(fn)`과 동형 — `fn`이 무효화 신호를 받을 때마다
  `Get()`으로 새 테이블을 pull하고, 이전에 본 key 집합과 diff.
- 새 key → `renderFn(key, itemState)` 호출 후 `Slot:add(...)`.
- 사라진 key → `Slot:remove(...)`(기존 확정 시맨틱대로 `retract`=폐기, 옮기지
  않음 — `slot-plan.md`와 자동으로 일관됨).
- 유지되는 key → Slot 조작 없이 그 항목의 `itemState`에만 새 값을 반영(재생성
  안 함) — Fusion `SubObject`/Vide `values()`가 하는 "값만 갱신"과 동일 효과를,
  `renderFn`이 `itemState: State<V>`를 받는 것만으로 자연스럽게 얻음(항목 값이
  바뀌어도 renderFn 자체는 재호출 안 되고, `itemState`를 구독한 리프만
  갱신됨).
- 소유권: 반환된 Slot은 기존 "엄격한 단일 마운트" 규칙 그대로 적용 — 새 규칙
  불필요.
- 패키지 경계: diff 알고리즘(순수 데이터 로직)은 `quad-base`, 실제 Instance
  생성/제거는 기존 Slot 핸들러 경로 그대로 재사용 — `slot-plan.md`가 이미
  확정한 base/roblox 분리와 동일 패턴.

**열린 세부**: Fusion은 `ForPairs`/`ForKeys`/`ForValues` 3종으로 나뉘는데,
quad는 `renderFn(key, itemState)`가 항상 key+itemState를 다 주고 안 쓰는
쪽은 그냥 무시하게 하는 **1종 통합안**이 단순화 후보로 보임(3개로 쪼갤
근거가 약해 보임 — `pre-implementation-audit.md`의 "단순화 후보" 렌즈와
같은 결). `keyFn` 생략 시 입력이 이미 맵이면 맵 key를 그대로 identity로
쓰는 것도 자연스러운 기본값 후보. 이름(`Keyed`/`Each`/`List`/`ToSlot`)은
용어 정리 라운드로 이월.

**다음 단계**: 사용자 피드백 반영해 스케치 다듬고, 이견 없으면 M6(Slot)
착수 시점에 `slot-plan.md`/`bind-system-plan.md`에 정식 반영.

### Context — 구현 난이도 판정 완료 (2026-08-06)

사용자 확인: Context는 React `useContext`(Provider가 위에서 값을 심고,
하위 어디서든 prop 없이 읽는 패턴)와 같은 개념 맞음. 구현 난이도가 채택
여부를 사실상 결정한다는 사용자 판단에 따라 서브에이전트에게 난이도 평가를
위임했고, 결과 수렴 완료 — **위 "4. Context" 절이 최종 결론**. 요지만
재정리:

- **난이도 등급**: 동기적 저작 트리에 한정한 얕은 버전 = **낮음**(Fusion
  `Contextual`의 "코루틴을 키로 하는 weak table push-pop"을 그대로 이식
  가능, quad-base 단독으로 완결, quad-roblox 분리조차 불필요). 완전
  자동(비동기 Slot 추가까지 자동 전파) = **매우 높음, 사실상 불가** —
  Roblox Luau에 thread-local/async-context-propagation 훅이 없어서 quad가
  소유하지 않는 임의의 콜백 경계(`Signal:Connect`, `task.spawn`, Promise)를
  가로챌 방법이 없음. 이건 quad 설계의 문제가 아니라 플랫폼 자체의 한계.
- **사용자의 직관이 정확히 맞았음**: 동기 콜스택 부분은 싸지만, Slot에
  나중에(이벤트 핸들러/코루틴에서) 비동기로 자식이 추가되는 케이스에서
  Fusion 방식은 **에러 없이 조용히 `defaultValue`로 폴백**함 — "테마가
  가끔 기본값으로 보인다"는 형태의 원인 추적 어려운 버그를 만듦(Vide
  방식은 폴백 대신 에러를 던지지만, 애초에 이 시나리오를 지원 대상으로
  설계한 적이 없어 참고할 답이 없기는 마찬가지). Node
  `AsyncLocalStorage`/Python `contextvars`도 "자동"이 아니라 "async 경계마다
  명시적으로 값을 캡처해서 재진입"하는 방식으로 같은 문제를 풀고 있어,
  이식해도 결국 "prop drilling 비용"이 "매 async 경계 캡처+재진입 보일러
  플레이트 비용"으로 자리만 옮김.
- **기각 이유(효용 대비 비용)**: 얕은 버전조차 채택할 가치가 낮음 — (1)
  `base/slot-plan.md`가 정상 패턴으로 명시한 Slot 비동기 추가에서 가장
  먼저, 가장 조용히 깨짐, (2) `research/debug-tooling-plan.md`의 "모든
  연결은 선언된 그래프여야 한다"는 quad-debug 철학과 충돌하는 안 보이는
  채널을 만듦.
- **대안 비교 결과**: Store 병합(난이도 매우 낮음, 그러나 drilling 자체는
  안 없앰) < 타입 안전 서브셋 전달(난이도 낮음, 하지만 트리 전파 문제와는
  별개 축이라 해결책이 아님) < **레이어드 Store**(난이도 낮음~중간, Context의
  핵심 가치인 "서브트리별 오버라이드"를 대부분 재현하면서 명시적 전달
  철학·비동기 안전성 둘 다 유지 — Modifier의 제네릭 `__index` 트릭,
  Source가 State를 만족시키는 `__index` 델리게이션과 같은 이미 검증된
  패턴 계열이라 구현 리스크도 낮음) — **레이어드 Store가 최종 권고안.**
  사용자가 스스로 "어려울 것 같다"고 짐작했던 것과 달리, quad2-try에서
  금지한 `Class:Extend()`류 행위(메소드) 상속과는 다른 층위(순수 데이터
  값 조회의 `__index` 폴백일 뿐)라 실제로는 낮은 난이도로 판정됨 — 다만
  Luau 타입 레벨에서 "자식 키 ∪ 부모의 나머지 키"를 구조적으로 표현하는
  부분은 M0가 이미 검증 대상으로 잡은 `Source<T> satisfies State<T>`류
  솔버 위험과 비슷한 급이라, 도입한다면 같은 스파이크에 끼워 검증하는 게
  합리적.
- **결론**: Context라는 이름의 범용 프리미티브는 채택하지 않음. 테마/로케일
  서브트리 오버라이드가 실제로 필요해지는 시점에 레이어드 Store를 별도
  후보로 검토(지금 착수 우선순위 낮음, 키 기반 컬렉션 재조정이 여전히
  더 시급).

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
