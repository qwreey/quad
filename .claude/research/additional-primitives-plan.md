# 추가 프리미티브 필요성 조사 — 다른 프레임워크 대비 갭 분석

**상태**: research — 사용자와 라이브 논의로 대부분 수렴(2026-08-06~07),
**2026-08-07 문서 정리에서 확정/기각된 항목을 분리**: Effect/Blocker →
`base/blocker-plan.md`/`base/effect-plan.md`, Batch(lexical) → `archive/
batch-rejected.md`, Context(+레이어드 Store 대안) → `archive/
context-rejected.md`. 이 문서에는 **아직 완전히 열려있는 것 하나만** 남음
— 키 기반 동적 컬렉션 재조정. 사용자가 "작업 전에 모든 정의를 마치고
싶다"고 명시 — M0 전 완전 확정이 목표.

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

| 후보 | 판정 | 현재 위치 |
|---|---|---|
| 키 기반 동적 컬렉션 재조정 | **진짜 빈 자리, 최우선** — 아직 열려있음 | 이 문서(아래) |
| Effect(leaf 죽음에 확정 정리) | 채택, 단 Observer와의 관계는 미해결 | `base/effect-plan.md` |
| Blocker(값 기반 emit 지연/합치기) | **채택** — Batch의 대안 | `base/blocker-plan.md` |
| Batch(함수/코루틴 스코프 lexical block) | **기각** | `archive/batch-rejected.md` |
| Context(트리 하위 암묵 전파) + 레이어드 Store | **기각** | `archive/context-rejected.md` |
| Observer에 cleanup 반환 계약 추가 | **기각** — 클로저 업밸류로 이미 충분 | `base/effect-plan.md`(근거만 인용) |
| Untrack/Peek | 빈 자리 아님 | 아래 "빈 자리 아닌 것" 절 |
| Suspense/비동기 경계 | 빈 자리 아님(문서화 문제로 재분류) | 아래 "빈 자리 아닌 것" 절 |
| Error Boundary | 빈 자리 아님 | 아래 "빈 자리 아닌 것" 절 |
| Readonly wrapper | 빈 자리 아님 | 아래 "빈 자리 아닌 것" 절 |

## 키 기반 동적 컬렉션 재조정 — 최우선, 설계 진행 중

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
  - "왜 lexical Batch를 기각하고 대신 값 기반 Blocker를 택했는가" —
    `archive/batch-rejected.md`와 `base/blocker-plan.md`의
    Blocker 절을 나란히 비교.
  - "왜 Context가 없는가" — `archive/context-rejected.md` 참고.
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
    금지를 강하게 명시**(`base/blocker-plan.md`의 "재진입" 절
    참고, 문서화 시 최우선 강조 항목).
  - "여러 Source를 한꺼번에 바꿀 때 Blocker 없이도 중복 재계산을 피하는
    파이프라인/업데이트 순서 팁"(Blocker를 안 쓰는 단순 케이스용 보조 팁,
    기존 "심화 최적화 팁" 항목을 Blocker 존재를 전제로 재조정).

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
