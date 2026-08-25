# 구현 전 감사 8라운드 — 7라운드 반영분 재트레이싱 + 실측 (발견 `H-107`~`H-123`)

> **[2차 패스]** 1차 패스(`H-107`~`H-117`) 직후 사용자 요청("못 본
> 것이 있는지 한 번만 더")으로 1차가 §6에 "못 본 범위"로 선언했던 곳을
> 마저 돌았다 — `slot-plan.md` 본체(소유권/CRUD/`raw*`/reconcile/teardown/
> attach 3형제), `dispatch-core-plan.md`의 체인 절,
> `debounce-throttle-plan.md` 전량, `lifecycle-hooks-plan.md`,
> `component-composition-plan.md`, `quad-types-plan.md`, `attribute-plan.md`
> 그룹 절, `tween-plan.md`의 `Animate`, `StoreBind` 배선. 신규 발견
> **`H-118`~`H-120`**(요약 표에 병합), 그리고 1차의 "남은 의심" 중 둘이
> **실측/전수로 해소**됐다(§5·§6 갱신됨).
>
> **[3차 패스]** 사용자 지시("다른 경로들 전부 보고 3차도 진행")로 남아
> 있던 `base/` 전 문서를 **전량 완독**했다 — `slot-plan.md` 나머지 전 구간
> (개념/요소 타입/CRUD 표/`:List` 전문/`:Single`/래핑·언래핑/`State<Slot>`
> 교체/`dispose`/nested index), `dispatch-core-plan.md` 나머지(핸들러
> 계약/디스패치 모델/Length·Offset 전문/배치 게이팅/`getOffsetAt`),
> `modifier-plan.md`/`tag-plan.md`/`attribute-plan.md`/`tween-plan.md`
> 전량, `bind-system-plan.md`/`ui-shorthand-plan.md`/`event-plan.md`/
> `onchange-plan.md`/`module-lifecycle-plan.md`/`project-setup-plan.md`/
> `fallback-plan.md`/`purity-and-effects-plan.md`. **이로써 `base/` 전
> 문서를 라운드 전체에 걸쳐 전부 읽었다**(개수는 폴더가 소스 — 각 패스의
> 문서 나열이 커버리지의 근거다). 신규 발견 **`H-121`~`H-123`**
> (셋 다 🟡/🟢 — 3차 범위에서 🔴는 안 나왔다), §5에 "3차에서 확인한
> 이상 없음" 목록 추가, §6의 "못 본 것"이 그만큼 더 줄었다.

**무엇인가**: 구현 착수 직전 마지막 감사 라운드. 7라운드 발견 52건이
2026-08-25에 `base/` 전체에 반영됐고(커밋 `eb321e1`), **그 새로 쓰인 서술을
아무도 트레이싱한 적이 없다**는 것이 이 라운드의 전제였다 — 그래서 개별
함수의 버그가 아니라 **"반영된 결정들이 서로 겹칠 때 성립하는가"**를 봤다.

**쓴 각도**(감사 지시서 §2 기준):

- **A. 7라운드 반영분 재트레이싱**(최우선) — 결정 묶음(🅐~🅜)이 `base/`에
  내려앉은 모양을 서로 겹쳐서 읽음. 이번 라운드 발견의 대부분이 여기서 나왔다.
- **C. 확정 의사코드/타입 실측** — `luau`/`luau-analyze`로 직접 실행.
  스파이크 6개(아래 각 항목에 인라인), 저장소 테스트(`./scripts/test.sh`)는
  시작 시점에 전부 PASS임을 확인.
- **D. 구현 순서 시뮬레이션** — `ROADMAP.md` M2 체크박스를 위에서부터 짜는
  시뮬레이션(결과는 §5 "이상 없다고 확인한 것").
- **B(부분). M2 내부 + M2→M3 경계의 엔드투엔드** — Store→State→Observer/
  Effect→Gate/Blocker→(M3) `setLength`/`recompute`까지의 체인. M5 이후
  구간은 못 봄(§6).
- **E/F/G/H(부분)** — 공개 API 오용 진단 여부, 코퍼스 미다룸 영역(두 버전
  공존), Luau 사실 주장 재확인(실측), 비용 서술 점검.

**실제로 본 범위**: `base/` 중 M2 직결 문서 전량(`source-state-plan` /
`state-epoch-plan` / `effect-plan` / `gate-plan` / `blocker-plan` /
`store-plan` / `ref-plan` / `lifecycle-pattern` / `relate-plan` /
`brand-plan` / `typing-limits` / `architecture`), `dispatch-core-plan`의
Length/Offset·`recompute`·`setLength` 절, `ROADMAP.md` M2 절 전체,
`question.md`, `luau-test/STATUS.md`, 커밋된 코드 전량(`quad-base/src/`,
`quad-types/src/` 표면, 테스트), `audit/type-store-index-keyof/`,
`audit/handtrace-round7-reference-impl/`(참조용으로만 — 규칙 6 준수).
**안 본 범위는 §6.**

**읽는 순서**: 요약 표 → 🔴 다섯(`H-107`~`H-109`, `H-112`, `H-119`) →
§4(사용자 결정 문항, Q1~Q10 — Q9/Q10은 2·3차 패스에서 추가) → 나머지.

---

## 요약 표

| 번호 | 심각도 | 한 줄 | 주 대상 | 성격 | 실측 |
|---|---|---|---|---|---|
| `H-107` | 🔴 | `Effect`의 `Ref` dep 발화 — `onDepFire`가 `from`을 못 받아 `_epochs:Update(nil)` | `effect-plan` × `ref-plan` | **M2 착수 전** 계약 결정 | ✅ 런타임 크래시 재현 |
| `H-108` | 🔴 | `Ref:Set` 확정 의사코드가 7라운드 반영(Revision 갱신·Weak 테이블 순회)을 못 받음 + 갱신 순서 미계약 | `ref-plan` | **M2 착수 전** 문서/계약 | — (트레이스) |
| `H-109` | 🔴 | 전파 루프가 `fn`의 self로 **Observer 자신**을 넘김 — 계약(self=리시버 State)과 충돌, `H-61` 내부 콜백이 크래시 | `source-state-plan` | **M2 착수 전** 계약 결정 | — (트레이스) |
| `H-110` | 🟡 | Observer→리시버 강참조가 어디에도 없음 — `_hold` 반영이 파생 노드만 커버, `H-98` 계약이 다시 열림 | `source-state-plan` | 계약 결정 (`H-109`와 한 몸) | — |
| `H-111` | 🟡 | `WeakSubscribe`가 `.Subscribed`를 세우는지 미정의 — 한쪽으로 구현하면 `Effect`의 State dep 전량 침묵 | `source-state-plan` × `lifecycle-pattern` | **M2 착수 전** 정의 공백 | — |
| `H-112` | 🔴 | `CheckReserved<T>`가 실사용 `T`(Source 필드 포함)에서 `*error-type*`으로 실패 — 유효한 Store 전부에 스퓨리어스 에러 | `store-plan` × `typing-limits` | **M2 착수 전** 계약 결정 | ✅ 실패 재현 + 대안 배선 통과 |
| `H-113` | 🟡 | `recompute` 되감기 — 커서 위치(j==i) splice가 "변경 없음"과 구분 불가, 밀려 들어온 요소의 offset이 조용히 낡음 | `dispatch-core-plan` | 계약 결정 (M3) | — (트레이스) |
| `H-114` | 🟢 | 문서 정합 둘 — `effect-plan`의 `H-11` 목록 2번이 `H-58` 이전 모델을 "확정"으로 유지 / `state-epoch-plan` §4 상단 `rawInvalid` 표기 | `effect-plan` / `state-epoch-plan` | 문서 정합 | — |
| `H-115` | 🟢 | `store-plan` 최종형 실측 표의 소스 폴더에 최종형 스파이크가 없음(전부 철회된 설계 대상) — 재현 불가 인용 | `store-plan` × `audit/` | 문서 정합 | ✅ 폴더 확인 |
| `H-116` | 🟢 | 같은 게임에 quad 두 벌 공존 시 `Brand`/`None` 상호 불인식 — 코퍼스 미다룸 | (전역) | 구현 시 정하면/문서화 | — |
| `H-117` | 🟢 | `store:Of` 무인스턴스화 호출의 `Source<unknown>`이 틀린 주석에도 조용히 통과 — 문서화 한 줄 | `store-plan` | 문서화 | ✅ |
| `H-118` | 🟡 | `Debounce`/`Throttle` 정책 모양 — "`emit`을 아예 안 쥔다"(`H-33`)와 "`emit` 반환값/`emit(false)`를 정책이 쓴다"(`H-55`/`H-86`)가 미조정 충돌 | `gate-plan` × `debounce-throttle-plan` | 계약 결정 | — |
| `H-119` | 🔴 | `recompute` 재진입 차단이 진입점 절반에서 우회됨 — `raw*` 삭제 3형제·`_baseObserver`의 직접 `recompute` 호출이 `recomputeBlocker`를 안 봄 | `slot-plan` × `dispatch-core-plan` | 계약 결정 (M3/M6) | — (트레이스) |
| `H-120` | 🟡 | `Ref():Callback(fn)` 관용구·`OnCreated`/`OnRendered` 슈가가 "등록 즉시 nil 1회 호출" 계약과 충돌 — 모든 훅 콜백이 생성 시점에 `nil`로 한 번 불림 | `ref-plan` × `lifecycle-hooks-plan` | 계약 결정 (M8) | — |
| `H-121` | 🟡 | `slot-plan`의 대표 `updateFn` 예시가 확정 콜백 계약과 불일치 — `:With(offset):Compute(function(i, o))`의 `o`는 offset이 아니라 `previous`(첫 사이클 `nil` 크래시) | `slot-plan` × `source-state-plan` | 문서 정합 (예시 교정) | ✅ grep 전수(유일 사례) |
| `H-122` | 🟢 | `isModifier` 가드 적용 지점 목록이 명시적 초기화 이전 서술("Store 생성 시 `Source(v)`로 만드는 시점")을 세 문서에서 유지 + Store 생성자의 defaults 런타임 검증 여부 미정의 | `modifier-plan` × `source-state-plan` × `ROADMAP` | 정의 공백 (소형) | — |
| `H-123` | 🟢 | 문서 정합 묶음 — `project-setup-plan`의 수동 리링크 서술이 `H-78`의 `scripts/relink.sh` 신설 미반영 / `pesde.lock` 커밋 여부가 "사용자 판단 필요"인 채 어느 인덱스에도 미취합(실태는 이미 커밋됨) / `:Single` 헤딩의 2-인자 표기 vs 확정 3-인자(`opts`) | `project-setup-plan` 외 | 문서 정합 | ✅ 파일 확인 |

**성격 열의 뜻**: "M2 착수 전" = 그 마일스톤 첫 파일들(`Source`/`State`/
`Store`/`Effect`)을 짜는 순간 바로 부딪히므로 착수 전에 답이 있어야 함.

---

## 상세

### `H-107` 🔴 — `Effect`의 `Ref` dep 발화 경로에서 `onDepFire`가 `from`을 못 받는다

- **어디**:
  - `base/effect-plan.md`의 "확정 구조 — 강한 주인은 항상 `Effect`" 절과
    생성자 의사코드 — dep 등록이 `d:WeakCallback(onDepFire)` 한 줄이고,
    그 클로저는 *"⭐ 클로저는 **하나**로 통일한다"*라는 주석과 함께
    `onDepFire(_, from)` 시그니처로 확정돼 있다. 본문은
    `if self._epochs:Update(from) then self:Rerun() end`.
  - `base/ref-plan.md`의 `H-53` 확정 의사코드(`Ref:Set`) — 일반 콜백은
    **`k(value)`로 호출**된다(*"일반 콜백은 원래 값을 받고, 소진 안 함"*).
- **무엇이 어긋나나**: 두 확정을 그대로 조립하면 `ref:Set(v)` 시
  `onDepFire`는 `(_ = v, from = nil)`을 받는다. `EpochMap:Update`의 인자
  계약은 `Epoch | EpochSet`(`base/state-epoch-plan.md` §3)이라 `nil`이 올
  자리가 없다 — `isEpoch(nil)`이 거짓이니 집합 순회로 떨어져 **`nil` 순회
  크래시**, 가드를 넣으면 `false` 반환 → **`Rerun`이 영영 안 돈다**.
  effect-plan이 약속한 *"`Ref`가 반복 재설정마다 도는 계약 … `Update`가
  매번 `true`다"*는 `Update`가 그 `Ref`를 **받았을 때** 얘기인데, 받을
  통로가 없다. `Observer` 경로만 `from`이 전파 루프를 타고 온다 — `Ref`엔
  전파 루프가 없고 `.Callbacks` 푸시뿐이다.
- **실제로 어떻게 터지나** — 확정 의사코드 3개(`Ref:Set`의 `k(value)` /
  `onDepFire(_, from)` / `EpochMap:Update`의 §3 분기)를 그대로 전사해
  실행했다(스파이크 전문은
  `/tmp/…/scratchpad/r8-spike-05-ref-dep-from-nil.luau`, 요지 인라인):

  ```lua
  local function onDepFire(_, from)
      if handle._epochs:Update(from) then rerunCount += 1 end
  end
  local r = Ref(nil)
  handle._epochs:Sync(r)      -- §4 시딩(dep이 Epoch면 :Sync)
  r:WeakCallback(onDepFire)
  r:Set("someInstance")       -- 사용자 관점: ref가 채워짐 → Effect가 돌아야 함
  ```
  ```
  before Set: rerunCount = 0
  Set ok = false  err = ...: attempt to iterate over a nil value   ← Update(nil)
  after Set: rerunCount = 0 (기대: 1)
  ```
  즉 `Effect(fn, someRef)`는 **`ref:Set`마다 크래시하거나(가드 없음),
  가드를 넣으면 `Ref` dep이 통째로 죽는다.** 7라운드 참조 구현은 이 경로를
  안 돌렸다(`audit/handtrace-round7-reference-impl/`의 Effect 스파이크는
  전부 State dep — `Ref` dep 케이스 0건, 직접 확인).
- **갈래**:
  - **(a) `Ref` 콜백 계약을 `k(value, self)`로 확장** — 두 번째 인자로
    `Ref` 자신(=`Epoch`)을 준다. 기존 사용자 콜백(`function(inst) ... end`)은
    두 번째 인자를 무시하면 그대로이고, `onDepFire`는 **한 글자도 안 바꾸고**
    성립한다(`from = ref`, `Update(ref)`가 리비전을 라이브로 읽음 — Observer
    경로와 정확히 대칭). 비용: `k(value)` → `k(value, self)` 한 자리.
  - **(b) `Effect`가 `Ref` dep에만 래퍼 클로저** —
    `d:WeakCallback(function() onDepFire(nil, d) end)`. `Ref` 계약은 안
    건드리지만 dep당 클로저가 하나 늘고, *"클로저는 하나로 통일"* 주석과
    표면상 어긋난다(실제로 공유해야 하는 건 클로저 identity가 아니라
    `_epochs` 맵이므로 **의미론 훼손은 없다** — dedup은 맵이 한다).
  - **(c) `onDepFire`가 `from == nil`을 `Ref` 발화로 해석** — **기각 권고**:
    설치 발화(등록 즉시 1회)도 `from == nil`이라 구분 불가
    (`base/source-state-plan.md`의 "`state:Observer(fn)`" 절).
- **M2 착수 전 필요한가**: **예.** `Effect` 생성자를 짜는 순간 정해야 한다.
- **인접**: `H-108`이 같은 조립의 나머지 절반(Revision 쪽). (a)를 고르면
  `H-108`의 순서 계약이 더 절실해진다(아래).

### `H-108` 🔴 — `Ref:Set` 확정 의사코드가 7라운드의 자기 반영을 못 받았다

- **어디**: `base/ref-plan.md`의 `H-53` 확정 의사코드(`function Ref:Set(value)`
  블록). 같은 파일의 "`Ref`는 `Epoch`를 만족한다" 절과 `:WeakCallback`
  항목.
- **무엇이 어긋나나** — 셋:
  1. **`Revision` 갱신 줄이 없다.** 산문은 *"`:Set()`이 `Source`와 같은 한
     줄로 갱신한다"*고 확정했는데, `:Set`의 유일한 확정 코드 블록(H-53,
     2026-08-24 작성)엔 그 줄이 없다 — 하루 뒤(2026-08-25) 결정이 의사코드에
     소급 반영되지 않았다. 이 블록만 보고 짜면 `Effect`의 캐치업
     (`_epochs:Refresh()`)과 `Update(ref)` 판정이 전부 죽는다.
  2. **Weak 콜백 테이블 순회가 없다.** `:WeakCallback` 항목은 *"발화 순회는
     두 테이블을 다 훑고(각각 스냅샷)"*이라 확정했는데, H-53 블록은
     `self.Callbacks`(강한 셋) 하나만 돈다. 이 블록대로면 `Effect`가 건
     Weak 콜백은 **한 번도 발화하지 않는다.**
  3. **갱신 순서가 계약에 없다.** `H-107`을 (a)/(b) 어느 쪽으로 고쳐도,
     `Revision` 갱신이 **콜백 순회보다 뒤**면 콜백 안의 `Update(ref)`가
     옛 리비전을 읽어 `false` → 그 `Set`의 `Rerun`이 접히고, 다음
     `Refresh()` 때에야 뒤늦게 돈다(간헐 지연 — 잡기 어려운 종류).
     `.Value`는 "콜백 순회 전에" 순서가 계약으로 못박혀 있는데(H-53의
     존재 이유) `Revision`은 아니다.
- **실제로 어떻게 터지나**: 1·2는 "블록대로 짜면 `Ref` dep 무동작", 3은
  "고쳐도 발화가 한 박자 늦는 창"이다.
- **갈래**: 갈래랄 게 없다 — H-53 블록에 `self.Revision = bit32.bnot(-self.Revision)`을
  `.Value` 대입 **직후, 순회 전**에 넣고, 순회를 두 테이블(각각 스냅샷)로
  넓히고, "값 → 리비전 → 콜백" 순서를 계약 문장으로 명시하면 된다.
  결정이 필요한 건 `H-107`의 (a)/(b)뿐.
- **M2 착수 전 필요한가**: **예**(M2의 `Effect`가 이 계약 위에 선다 —
  `Ref.luau` 본체는 M8이지만 계약은 지금 적어야 M2 의사코드가 안 흔들린다).
- **인접**: `H-107`과 한 묶음. `H-114`(같은 "하루 차 미반영" 클래스)와
  성격이 같다.

### `H-109` 🔴 — 전파 루프의 `sub.fn(sub, from)` vs "self는 리시버 State" 계약

- **어디**:
  - `base/source-state-plan.md`의 "전파 루프 — 확정 의사코드" 절:
    `elseif canExecute(sub) then sub.fn(sub, from)` — **첫 인자가 `sub`
    (Observer 값 자신)이다.**
  - 같은 문서의 "`state:Observer(fn)`" 절: *"`self`는 이 Observer가 붙은
    State의 **lazy 핸들**"* — `base/state-epoch-plan.md` §6도 같은 계약을
    반복한다(*"`:Compute`의 `fn(self, ...)`와 같은 모양"* — `:Compute`의
    self는 리시버다).
- **무엇이 어긋나나**: 두 확정이 정면 충돌한다. Observer는 State가 아니고
  `:Get()`이 정의돼 있지 않으므로(`Subscribe`/`WeakSubscribe` 계열만 있음),
  루프를 글자 그대로 짜면 **계약대로 `self:Get()`을 부르는 모든 `fn`이
  "attempt to call missing method Get"으로 죽는다.** 죽는 목록에 quad
  자신의 확정 코드가 포함된다 — `H-61`이 확정한 무인자 `state:Observer()`의
  내부 콜백이 정확히 `function(self) self:Get() end`다. `Effect`의
  `onDepFire`는 첫 인자를 `_`로 버려서 **이 충돌을 못 봤다** — 7라운드
  트레이싱이 Effect 경로로만 이 루프를 돌린 흔적과 정합한다.
- **실제로 어떻게 터지나**: `A:Set()` → `_emitDown` → 무인자 Observer의
  내부 콜백 → `sub:Get()` → 크래시. 또는 사용자 `fn(self)`가 계약을 믿고
  `self:Get()` → 크래시.
- **갈래**:
  - **(a) Observer가 리시버를 필드로 강하게 들고, 루프가 그걸 넘긴다** —
    `state:Observer(fn)` 생성 시 `observer._state = state`(강참조), 루프는
    `sub.fn(sub._state, from)`. **`H-110`이 공짜로 같이 닫힌다**(아래).
    권고.
  - **(b) Observer에 `:Get()` 델리게이션을 얹어 self=Observer를 정본으로**
    — 계약 문장을 고치는 쪽. 표면이 늘고(`Observer:Get`), Observer가
    "State처럼 보이는" 새 혼동을 만든다. 기각 권고.
- **M2 착수 전 필요한가**: **예** — 전파 루프는 M2의 심장이다.
- **인접**: `H-110`(같은 결정으로 닫힘), `H-107`(같은 루프의 다른 팔).

### `H-110` 🟡 — Observer→리시버 강참조가 base 어디에도 명시돼 있지 않다

- **어디**: `base/source-state-plan.md`의 `_hold` 불변식 절 — *"**모든 파생
  노드**(`:With`/`:Compute`/`:Gate`/`:Block`)가 자기 상류를 `_hold`에
  강하게 담는다"*. **Observer가 이 목록에 없다.** 반면 결정의 소스인
  `qa-request/pre-implementation-handtrace-round7-followup.md` 🅚 절은
  *"`:Subscribe()`가 전역 강 레지스트리에 핸들을 넣고, **핸들이 `_hold`로
  상류를 잡는다**"*라고 적었다 — **핸들(Observer/Effect)까지 포함한
  서술이 base 반영에서 파생 노드로만 좁혀졌다.**
- **무엇이 어긋나나**: `Effect`는 `_deps` 강참조가 있어 대체 커버되지만,
  Observer는 **`fn` 클로저가 리시버를 우연히 캡처하는 것** 말고 아무
  근거가 없다. 그리고 그 우연이 없는 확정 사례가 이미 둘이다 —
  `H-61`의 내부 콜백(`function(self) self:Get() end`, 캡처 없음)과
  `Effect`의 `onDepFire`(리시버를 안 캡처). `_hold` 절 자신이 *"우연에
  기대면 안 되고 방향성을 불변식으로 못박아야 한다"*고 말해놓고 Observer만
  우연에 남겨뒀다.
- **실제로 어떻게 터지나**: `local o = someStore.hp:Compute(f):Observer():Subscribe()`
  — 레지스트리가 `o`를 살리지만 `o`→`Compute` 노드 강참조가 없으면 중간
  노드가 수거돼 **전파가 조용히 끊긴다.** `:Subscribe()`의 공개 계약
  (*"GC되지 않고 영원히 계속 실행됨"* — `H-98`이 닫은 그 문장)이 다시
  열린다.
- **갈래**: `H-109` (a)를 채택하면 `observer._state`(강참조)가 곧 이
  불변식이다 — 별도 결정이 필요 없어진다. (a)를 안 하더라도 `_hold` 목록에
  Observer를 추가해야 한다.
- **M2 착수 전 필요한가**: `H-109`와 같이 답하면 자동으로 닫힌다.

### `H-111` 🟡 — `WeakSubscribe`와 `canExecute`의 상호작용이 미정의다

- **어디**:
  - 전파 루프: `elseif canExecute(sub) then …` — Observer 구독자는
    `canExecute`를 통과해야 발화한다.
  - `base/lifecycle-pattern.md`의 `isBoundAlive` 스케치 — (b) 경로 주석이
    *"전역 경로: `:Subscribe()`가 세운 것"*이라며 `value.Subscribed == true`를
    본다. 같은 파일의 `Observer:Subscribe()` 의사코드만 `.Subscribed`를
    세운다 — **`WeakSubscribe`의 의사코드/시그니처는 이 파일에 없다**
    (토큰 자체는 `lifecycle-pattern.md:346`의 `H-58`/`H-59` 정정 주석에
    한 번 스치듯 등장하지만, `.Subscribed`를 세우는지에 대한 서술은 아니다).
  - `base/source-state-plan.md`의 `:WeakSubscribe()` 절 — *"`Subscribe() =
    WeakSubscribe() + 강한 레지스트리에 킵`이고 구현이 한 벌"*,
    *"동작 자체는 Weak 아닌것과 동일하게 가고, 가드도 동일하나 단순히 gc 안
    되도록 킵 해주는 부분만 제거"*(사용자 원문).
- **무엇이 어긋나나**: `Effect`의 내부 Observer는 **`WeakSubscribe`로만**
  등록된다(생성자에서 한 번, `H-58`/`H-59`). 그 Observer가 전파 루프의
  `canExecute(sub)` 게이트를 통과하려면 `isBoundAlive`가 참이어야 하는데 —
  gcconn 경로는 없고(바인드는 핸들에만), 남는 건 `.Subscribed`뿐이다.
  - `WeakSubscribe`가 `.Subscribed = true`를 세운다고 읽으면(사용자 원문
    *"동작 자체는 동일"*의 자연스러운 해석): 루프 통과 ✅, 실제 게이트는
    `onDepFire` 안의 `canExecute(handle)`이 전담 — effect-plan의 *"발화
    게이트는 전부 `canExecute(handle)` 하나"*와 정합.
  - 안 세운다고 읽으면(`isBoundAlive` 주석 *"`:Subscribe()`가 세운 것"*과
    `H-59`의 *"`:Subscribe()`가 새로 하는 일은 (a)뿐"* — (a)가
    `Subscribed = true`를 포함 — 의 자연스러운 해석): **`canExecute(내부
    Observer)`가 항상 거짓 → `Effect`의 State dep 전량이 조용히 침묵.**
  두 해석이 각각 다른 확정 문장에 뿌리를 두고 있어, 구현자가 어느 쪽을
  골라도 "문서대로 했다"고 말할 수 있다 — 그리고 한쪽은 조용히 죽는다.
- **갈래**:
  - **(a) `WeakSubscribe`가 `.Subscribed = true` + weak 레지스트리 등록,
    `Subscribe`는 그 위에 강한 킵만 추가** — "구현이 한 벌"과 정합, 권고.
    `isBoundAlive`의 (b) 주석과 `H-59` (a)의 서술을 이에 맞게 손봐야 한다
    (`.Subscribed`는 이제 "전역 경로 전용"이 아니라 "구독 경로(강/약) 공용"
    이 된다).
  - **(b) `canExecute`의 전역 경로 판정을 필드가 아니라 레지스트리 멤버십
    (`weakRegistry[value] ~= nil`)으로** — 동작 동일, `Unsubscribe`가 양쪽
    테이블을 지워야 하는 대칭 요구가 생김.
- **M2 착수 전 필요한가**: **예** — `Observer.luau`/`Effect.luau`를 짜는
  순간 정해야 한다.
- **인접**: `H-109`(같은 루프), `H-107`(같은 `Effect` 배선).

### `H-112` 🔴 — `CheckReserved<T>`는 실사용 `T`에서 아예 돌지 않는다 (실측)

- **어디**: `base/store-plan.md`의 "타입 추론 문제" 절(*"`T`를 검증만 하고
  그대로 통과시키는 작은 `type function`"*), `ROADMAP.md` M2의
  `CheckReserved` 체크박스(*"예약 키를 **검증만** 하고 `T`를 그대로
  통과시킨다"*), `base/typing-limits.md` §0(타입 함수는 진단까지만)과
  §6(패스스루도 이력만으로 오염).
- **무엇이 어긋나나**: 최종 Store의 타입 인자는 정의상
  `{hp: Source<number>, …}` — **모든 실사용 `T`에 `Source<T>` 필드가
  들어간다.** 그런데 확정 선언 스타일(§1②의 인라인 쪼개기 — 콜백 파라미터
  무주석 추론이 사는 유일한 스타일)에서 `Source<T>`는 `Compute`의
  `-> State<U>` 재귀 반환 누수(§1) 때문에 내부에 `*error-type*`을 품고,
  **Luau 타입 함수는 `*error-type*`이 든 타입을 받는 순간 실패한다.**
  즉 `CheckReserved<T>`를 어디에 배선하든(접근 경로든 팬텀 필드든) **예약
  키가 없는 완전히 유효한 Store 사용 지점 전부에** `TypeError: Type
  functions do not currently support types of the form '*error-type*'`가
  뜬다. 7라운드가 `CheckReserved`를 실측한 스파이크
  (`audit/type-store-index-keyof/spikes/05-checkreserved.luau`)는 철회된
  재설계의 `T`(`{hp: number}` — **스칼라 필드**)로 돌렸기 때문에 이 함정을
  못 봤다 — 최종형에선 `T`의 필드가 스칼라가 아니라 `Source<T>`다.
- **실측** (스파이크 전문:
  `/tmp/…/scratchpad/r8-spike-01/02/03/04/06-*.luau`):
  1. **원인 분리** — `Compute` 없는 `Source`면 `CheckReserved<T>` 통과,
     인라인 `Compute: <U>(…) -> State<U>`가 든 `Source`면 즉시 실패:
     ```
     r8-spike-06: (A) Compute 없음 → 진단 0건
                  (B) 인라인 Compute → TypeError: Type functions do not
                      currently support types of the form '*error-type*'
     ```
  2. **접근 경로 배선(`Store<T> = CheckReserved<T> & {…}`)은 이중으로
     죽는다** — 타입 함수 실패 + `does not have key 'hp'`(필드 접근 전멸).
  3. **§1③(`typeof`) / 하이브리드 선언으로 갈아타면** 타입 함수는 돌지만
     — ③ 전면: `Get()`이 `unknown`으로 붕괴, 하이브리드: 무주석 `:Compute`
     콜백이 깨짐(둘 다 `CheckReserved` 유무와 무관하게 선언 스타일 자체의
     문제로 재현 — 대조군 확인). 즉 **"콜백 추론 + CheckReserved" 동시
     성립 배선은 `T`를 통째로 넘기는 한 존재하지 않는다.**
  4. **⭐ 통과하는 배선을 찾았다 — `T`가 아니라 `keyof<T>`(키 싱글톤
     유니온)만 넘긴다.** `Source` 타입이 인자에 아예 안 실리므로
     `*error-type*` 직렬화 문제가 원천 소멸:
     ```lua
     type function CheckReservedKeys(keys: type)
         -- keys: "hp" | "name" (싱글톤 유니온) — Of/Names면 print + types.never
         …
         return types.singleton(true)
     end
     type Store<T> = T & {
         Of: <U>(self: any, name: string) -> Source<U>,
         Names: (self: any) -> { string },
         __reservedCheck: CheckReservedKeys<keyof<T>>,   -- 팬텀 필드 격리(§6 규칙 그대로)
     }
     ```
     결과(인라인 ② 선언 그대로, `r8-spike-04`):
     - 예약 키 충돌 → `TypeError: quad.Store: "Of" is a reserved key` ✅
       (캐스트 지점·**생성자 호출 지점 양쪽에서**, 강제 평가 없이)
     - `store.hp:Get()` 양성 통과 / 음성 대조군 정확히 걸림 ✅
     - `store.hp:Compute(function(x) return x:Get() * 2 end)` — **무주석
       콜백 추론 생존** ✅
- **파급 하나 더(미확정)**: `ROADMAP.md` M2의 `H-80` 체크박스가 `Quad`
  타입에 `Source` 등 반응형 표면을 추가하게 하는데, 그 순간
  `type-version-check`의 `CheckVersion<T>`(T=Quad)도 같은 기전으로 죽을 수
  있다 — `Quad` 타입의 선언 스타일이 정해져야 실측 가능. `CheckedQuad`를
  쓰는 스파이크 `23`이 M2 반영 후 다시 돌아야 할 이유가 하나 늘었다.
- **갈래**:
  - **(a) `CheckReserved`가 `T` 대신 `keyof<T>`를 받는다**(팬텀 필드 격리
    유지) — 실측 완료, 권고. `typing-limits.md` §0의 *"`index<>`/`keyof<>`도
    타입 함수다"* 경고와의 관계도 §0 허용 범위 안이다(진단 전용 + 결과가
    접근 타입에 안 섞임 — 팬텀 필드의 값은 `types.singleton(true)`).
  - **(b) `CheckReserved`를 포기**하고 예약 키 충돌의 "조용히 꺼짐"을
    문서 경고로만 남긴다.
  - **(c) 선언 스타일을 §1③으로 바꾼다** — 콜백 무주석 추론을 포기하는
    것이라 최종형 실측 표의 약속과 어긋난다. 기각 권고.
- **M2 착수 전 필요한가**: **예** — `Store.luau`와 `CheckReserved` 체크박스가
  M2 초입이다.
- **인접**: `H-115`(같은 실측 표의 출처 문제).

### `H-113` 🟡 — `recompute` 되감기: 커서 위치(j==i) splice가 "변경 없음"과 구분되지 않는다

- **어디**: `base/dispatch-core-plan.md`의 `recompute` 확정 의사코드
  (1758행 부근)와 그 아래 `H-101`/`H-102` 정리 절. 핵심 줄:
  ```lua
  bk.invalidAfter = i                       -- 매 반복, offset:Set 직전
  if offset ~= None and offset:Get() ~= abs then offset:Set(abs) end
  …
  if bk.invalidAfter < i then i = bk.invalidAfter; sum = prefix[i] else i += 1 end
  ```
  그리고 `/code-review` 정정 문단: *"재개 지점은 `invalidAfter` 자신이다
  (`+1` 아님)"* + *"그래서 splice도 `j - 1`이 아니라 `j`로 낮춘다 — 재개가
  `invalidAfter`니까 `j`가 곧 '그 자리부터 다시'다"*.
- **무엇이 어긋나나**: 그 마지막 문장이 **j == i(커서 위치)에서 거짓이다.**
  루프가 매 반복 `invalidAfter = i`를 쓰므로, `offset:Set(abs)` 도중 사용자
  코드가 **지금 처리 중인 자리 i에서** 요소를 제거/삽입하면 splice의
  무효화는 `math.min(invalidAfter, i) = i` — **아무 일도 없던 것과 같은
  값**이 된다. 되감기 조건 `invalidAfter < i`가 거짓이라 재방문이 없고,
  splice로 i 자리에 **밀려 들어온 요소의 offset `Source`는 이번 패스에서
  `Set`을 못 받는다**(우리가 `Set`한 건 제거된 옛 요소의 Source다). 루프
  끝의 `bk.invalidAfter = bk.N or 0`이 캐시를 "유효"로 마감하므로 다음
  계기가 올 때까지 **그 요소만 옆으로 어긋난 레이아웃**이 남는다 — `H-3`이
  경고한 *"위로는 맞고 옆으로만 틀린다"*와 같은, 알아채기 어려운 부류.
  (`sum`은 안 낡는다 — `lengthList[i]` 읽기가 `Set` 뒤라 새 요소의 길이가
  실린다. 낡는 건 offset 하나다.)
  - j < i(앞자리 splice)는 확정대로 잘 되감긴다 — 트레이싱으로 확인.
  - 재진입 `recompute`는 `recomputeBlocker`에 막혀 자가치유도 없다(설계
    의도 그대로 — 되감기가 유일한 복구 수단인데 그 되감기가 이 경계를
    못 본다).
- **실제로 어떻게 터지나**: `:List` 항목의 `slot.Offset`을 관측하는 사용자
  코드가 그 항목 자신을 동기 제거하는 경우(예: "위치가 확정되는 순간
  조건부로 자신을 리스트에서 빼는" 패턴) — 정확히 `H-101`이 지원하기로 한
  "recompute 도중 구조 변경"의 한 사례다.
- **갈래**:
  - **(a) splice의 무효화만 `j - 1`로 되돌린다**(재개 지점은 `invalidAfter`
    유지). j==i면 `invalidAfter = i-1 < i` → i-1부터 되감고(그 자리 offset
    쓰기는 `~=` 가드로 no-op) i를 재방문 ✅. j<i도 한 자리 여분 재방문만
    생기고 정합 ✅. `/code-review`가 j로 바꾼 동기(재개 +1 폐기에 맞춘
    쌍)는 재개가 `invalidAfter`로 남는 한 j-1로도 깨지지 않는다 —
    `prefix[j-1]`은 `1..j-2`의 합이라 splice와 무관하게 유효.
  - **(b) 되감기 신호를 `invalidAfter`와 분리** — "커서 이하로 무효화가
    내려왔다"는 불리언/최소 인덱스를 따로 둔다. `H-101`의 *"새 필드를 안
    만든다"* 확정을 되짚는 것이라 비용이 더 크다.
- **M2 착수 전 필요한가**: 아니오 — M3(디스패치)다. 다만 계약 결정이라
  구현자가 임의로 정하면 안 되는 자리.
- **인접**: 없음(이번 라운드 유일의 M3 발견).

### `H-114` 🟢 — 하루 차 미반영 문서 정합 둘

1. **`base/effect-plan.md`의 `H-11` 확정 목록 2번** — *"`Destroying` 커넥션을
   끊고 **`Ref` 콜백도 같이 해제**하되"*, *"언마운트가 콜백을 떼고 재마운트의
   `bindLifetime`이 다시 건다"* — 이건 2026-08-24 서술이고, 하루 뒤
   `H-58`이 정반대로 확정했다(같은 파일의 `_unbindDestroying` 의사코드:
   *"**`Ref` 콜백도 Observer도 안 뗀다**"*). 같은 파일 안에서 번호 달린
   "확정" 목록과 의사코드가 서로 반대를 말한다 — 목록 쪽에 정정 배너가
   없어 위에서부터 읽는 구현자가 옛 모델을 먼저 만난다.
   **[code-review 추가]** 같은 클래스가 같은 파일에 둘 더 있다 —
   `effect-plan.md:116`/`:123` 부근의 *"`bindLifetime`은 이미
   `handle._observers`로 cascade하며"* / *"실제로 그 함수는 이미 `Effect`면
   내부 Observer로 cascade한다"*. `H-58` 이후 `Effect`에 `_observers`는
   없고(강한 dep 맵 `_deps`로 대체), cascade 서술 자체가 옛 모델이다 —
   고칠 때 이 두 줄도 같은 커밋에서.
2. **`base/state-epoch-plan.md` §4 상단** — State 컴포지션 구조체와 수신
   규칙 의사코드가 여전히 `rawInvalid: boolean`으로 쓰여 있다. `H-85` 절의
   안내 문장은 *"아래 두 절"*(재계산 판정/재계산이 끝나면)만 카운터로
   읽으라고 하는데, **구조체 선언과 수신 규칙은 그 "아래 두 절"이 아니라
   `H-85` 절보다 위에 있다** — 위에서부터 읽으면 폐기된 필드로 구조체를
   먼저 확정하게 된다.

둘 다 판단 불필요 — 본문 정정만.

### `H-115` 🟢 — 최종형 Store 실측 표의 출처가 재현 불가다

`base/store-plan.md`의 "`store.key` 레코드 필드 타이핑" 절 실측 표는
*"실측 전량은 `audit/type-store-index-keyof/`가 소스"*라고 하는데, 그
폴더의 스파이크 대부분이 **철회된 재설계**(`__store` 팬텀 +
`keyof<index<…>>`, 값 필드 스칼라)를 대상으로 하고 — 최종형
(`Store<T> = T & {Of, Names}`, 필드가 `Source<T>`)을 도는 파일이 없다.
**[code-review 정정]** "전부 철회 대상"은 과대 서술이었다 — `02`는 필드가
스칼라가 아니라 `Source<T>`이고, `06`엔 `__store` 팬텀도 `keyof`/`index`도
없다. 그 둘의 측정(Compute 없는 `Source` 필드 통과, `<<T>>` 값 자리
인스턴스화)은 최종형에서도 여전히 유효하니 **스파이크 재작성 때 버리지 말
것** — 핵심 주장(최종형 결합을 도는 파일이 없다)만 유효하다.
REPORT 상단 배너도 철회를 명시한다. 표의 측정값 자체는 이 라운드 스파이크로
대체 재확인됐지만(위 `H-112` 4번 — 단 `CheckReserved` 결합은 표와 달리
실패), **STATUS.md의 `16`/`21` 재작성 때 최종형 + `H-112` 배선을 함께
넣으면 출처 문제가 같이 닫힌다.** 판단 불필요.

### `H-116` 🟢 — 같은 게임에 quad 두 벌이 공존하면 (코퍼스 미다룸 영역)

패키지 매니저 생태계에서 두 라이브러리가 서로 다른 quad 버전을 끌어오는
경우는 예정된 미래인데, 코퍼스 어디에도 언급이 없다(F각도 전수 사냥의
산물). 이때 `Brand` 레지스트리·`None` 센티널·`Subscribed` 전역 테이블이
**모듈 사본마다 분리**되므로, 한 사본이 만든 `Source`/`Observer`를 다른
사본의 children 배열에 넘기면 `isState`/`isObserver`가 거짓 → 동적 경로
가드나 화이트리스트 검증(`H-40`)이 **정상 값을 이물로 판정**한다. 크래시로
드러나면 다행이고(화이트리스트 error), 값 종류에 따라 조용히 무시될 수도
있다. 지금 결정할 일은 아니고, "quad 값은 만든 사본 안에서만 유효하다"를
문서화 대상 목록에 올려두면 된다(버전 정책은 `type-version-check`가 타입
레벨에서 이미 다루는 축 — 이건 그 런타임 판별 판이다).

### `H-117` 🟢 — `store:Of("k")` 무인스턴스화의 `Source<unknown>`은 틀린 주석도 통과시킨다

`base/store-plan.md`는 `store:Of("z")`가 `Source<unknown>`이 된다고만
적는다. 실측(`r8-spike-04`)에선 `local d: Source<boolean> = s:Of("dyn")`이
**진단 0건**으로 통과했다 — `unknown`이 아무 구체 타입 주석과도 충돌하지
않아, `<<T>>`를 빠뜨린 호출은 조용히 unsound다(§1의 명시 바인딩 구멍과
같은 부류지만 자리가 다르다). *"`Of`는 타입 보장을 포기했다가 호출부에
드러나는 자리"*라는 확정 서술에 "인스턴스화를 생략하면 주석까지도 무력"
한 줄을 보태면 된다. 판단 불필요.

### `H-118` 🟡 — `Debounce`/`Throttle` 정책이 `emit`을 쥐는가 — 두 확정이 미조정 상태다

- **어디**:
  - `base/gate-plan.md` 5번(2026-08-24, `H-33`/`H-49`): *"**`Debounce`/`Throttle`은
    `emit`을 아예 안 쥔다.** 자기 `Blocker`를 사적으로 하나 갖고 **언제
    `On()`/`Off()`할지만** 정하며, 실제 발화/보류 판정은 전부 Blocker에
    위임한다"* — 스케치도 정책 본문이 `pass()`만 부르는 모양.
  - `base/gate-plan.md` 2번(2026-08-25, `H-55`/`H-86`): `Throttle`의
    `onWindowEnd`가 **`emit`을 직접 호출**하고 반환값을 읽는다 —
    `if not emit() then window = nil else rearm() end`.
    `base/debounce-throttle-plan.md`의 7절 재작성 배너도 같은 형태를
    확정으로 인용하고(*"`MaxTime` 재무장 조건도 같은 반환값으로 판정"*),
    동시에 *"버리는 경로도 같은 핸들이다 — `Trailing = false`/`Cancel`은
    `b:OffWithoutEmit()`만으로는 집합이 안 비므로 `emit(false)`가 필요하다"*
    라고 적는다 — 즉 정책이 **`b`와 `emit`을 둘 다** 쥔다.
- **무엇이 어긋나나**: 하루 차이의 두 확정이 각자 유효한 채로 나란히 있다.
  5번의 머리 문장("`emit`을 아예 안 쥔다")은 `H-55`/`H-86` 반영 때 정정
  배너를 못 받았고, 그 결과 **정책과 `Blocker`의 역할 경계가 두 갈래로
  읽힌다**: 타이머 콜백의 flush/버리기/조회가 전부 `emit` 직접 호출이 되면
  `Blocker` 경유(`b:Off()` → onunblock 핸들 → flush)와 **flush 경로가 두
  개**가 되고, 그때 `Blocker`가 실제로 남기는 역할이 무엇인지(창 안 보류
  판정 하나뿐인지)가 어디에도 없다. 구현자가 5번대로 짜면 `H-86`이 실측한
  실패(창이 idle로 못 돌아가 leading 영구 소실 + 타이머 체인 무한 재무장)로
  돌아가고, 2번대로 짜면 5번의 `blocker:Policy` 위임 구조 절반이 장식이
  된다.
- **실제로 어떻게 터지나**: 구현 방향에 따라 갈린다 — (5번 우선 시)
  `H-86` 실측 실패 재현, (2번 우선 시) 이중 flush 경로의 순서/중복 의미가
  미정의(둘 다 부르면 두 번째는 빈 배치 no-op라 아마 무해하지만, 그
  "아마"가 계약에 없다).
- **갈래**:
  - **(a)** 정책은 **`b`와 `emit`을 둘 다 쥔다**로 명문화 — 상류 emit
    도착 경로는 `Blocker` 위임(`pass()`), 타이머/핸들 경로(flush·버리기·
    조회)는 `emit` 직접 호출. 두 flush 경로의 중복은 빈 배치 no-op 계약
    (`gate-plan.md` 8번)이 흡수함을 같이 적는다. 5번 머리 문장에 정정
    배너. **(권고 — `H-55`/`H-86`의 실측이 이 방향을 강제한다)**
  - **(b)** `Blocker` 위임을 폐기하고 정책이 `emit`만 쥔다 — `H-33`이
    Blocker 위임으로 얻으려던 것(보류 판정 재사용)을 되짚어야 하고,
    `blocker:Policy` 표면의 존재 이유가 좁아진다.
- **M2 착수 전 필요한가**: 아니오 — `Debounce`/`Throttle`은 백로그(순수
  슈가)다. 다만 `Gate`/`Blocker`(M2)의 표면 문서가 정본이므로 문장 정리는
  M2 문서 반영 때 같이 하는 게 싸다.
- **인접**: 없음.

### `H-119` 🔴 — `recompute` 재진입 차단(`H-101`)이 진입점 절반에서 우회된다

- **어디**:
  - `base/dispatch-core-plan.md`의 `recompute` 확정 의사코드 — 재진입
    차단의 실체는 `gatedRecompute` 안의 두 검사
    (`blocker:IsOn()` / `bk.recomputeBlocker:IsOn()`)다. `recompute` 자신은
    머리에서 `bk.recomputeBlocker:On()`만 하고 **재진입 검사를 하지
    않는다**(Blocker의 `On()`은 멱등 세팅일 뿐).
  - `base/slot-plan.md`의 `rawUnmount`/`rawDetach` 확정 의사코드 —
    끝에서 **`recompute(self, bk)`를 직접 호출**한다(주석: *"자리가
    없어지는 경로엔 setLength가 없으므로 여기서 명시 호출"* — `H-19`의
    예외 조항). `rawRemove`·`rawSplice`류도 같은 규약이다.
  - 같은 문서 `materializeSlotTree`의 `_baseObserver` 콜백 —
    `if not getBlocker(slot):IsOn() then recompute(slot, getBookkeeping(slot)) end`
    — **배치 Blocker만 보고 `recomputeBlocker`는 안 본다.** 그리고
    `base/dispatch-core-plan.md`의 `H-3`가 명시한 *"3. `slot._baseObserver`
    콜백 — 베이스가 바뀐 경우라 `bk.invalidAfter = 0`"* 줄이 이 의사코드에
    **없다**.
- **무엇이 어긋나나** — 트레이스: `recompute(A)` 도중 `offset:Set(abs)`가
  사용자 offset 관측 코드를 돌리고, 그 코드가 A(수동 CRUD Slot)의 공개
  `Remove`/`Extract`를 부르면:
  1. `rawRemove` → `spliceArraysDown`(여기서 `invalidAfter`가 당겨짐 —
     되감기 신호 ✓) → **직접 `recompute(A, bk)`** — `recomputeBlocker`가
     켜져 있는데도 **중첩 recompute가 완주**한다(`H-101`이 명시적으로
     막기로 한 그 모양).
  2. 중첩 recompute의 꼬리가 `bk.invalidAfter = bk.N`으로 **바깥 루프의
     되감기 신호를 지우고**, `bk.recomputeBlocker:OffWithoutEmit()`으로
     **바깥 루프가 아직 도는 중에 차단기를 꺼버린다**(이후 재진입은 전부
     통과).
  3. 제어가 바깥 루프로 돌아오면, 바깥은 자기 옛 `sum`으로 계속 돌다
     끝에서 `ownerKey.Length:Set(sum_바깥)` — **중첩이 이미 써둔 올바른
     `Length`를 낡은 합으로 덮는다.** `H-101`의 문제 서술(*"바깥 루프의
     꼬리가 자기 옛 `sum`으로 그걸 덮는다"*) 그대로다 — 차단이 있어야 할
     자리에서 차단이 안 되기 때문.
  대칭이 깨진 것이 핵심이다: 같은 재진입 시나리오에서 **`Add`는 안전**하고
  (`rawAdd` → `setLength` → `gatedRecompute` → 두 검사 통과 못 함 → 되감기
  위임 ✓) **`Remove`는 깨진다**. `H-19`(2026-08-24, 명시 호출 예외)와
  `H-101`(2026-08-25, 재진입 차단)이 하루 차이로 확정되며 서로를 못 봤다.
- **실제로 어떻게 터지나**: `slot.Offset`을 관측하는 사용자 코드가 동기로
  같은 Slot의 요소를 제거하는 경우(예: 위치 확정 순간 조건부 자기 제거) —
  `H-101`이 실재한다고 인정한 트리거와 같은 부류. 결과는 잘못된
  `Length`가 상위로 전파 + 재진입 차단기 무력화.
- **갈래**:
  - **(a)** `raw*` 삭제 3형제와 `_baseObserver`의 명시 호출을 전부
    "게이트 확인 후 호출"로 통일 — `blocker:IsOn() or
    bk.recomputeBlocker:IsOn()`이면 건너뛴다(건너뛰어도
    `spliceArraysDown`/`invalidAfter = 0`이 이미 당겨둔 신호로 바깥
    루프의 되감기가 복구한다 — `H-101` 설계 그대로). `_baseObserver`엔
    `bk.invalidAfter = 0`도 같이 넣는다(`H-3`의 3번이 요구하는데 의사코드에
    없다). **(권고 — 새 메커니즘 없이 기존 두 검사를 재사용)**
  - **(b)** `recompute` 자신의 머리에서 재진입을 검사하고 조기 반환 —
    호출부를 안 고쳐도 되지만, "명시 호출은 반드시 돈다"는 `H-19`의
    기대와 표면이 어긋나고 조기 반환 시 되감기 신호 유지가 (a)와 동일하게
    필요하다.
- **M2 착수 전 필요한가**: 아니오 — M3/M6이다. 다만 `H-113`과 같은 자리
  (`recompute` 재진입 계약)라 **같이 답하는 게 싸다.**
- **인접**: `H-113`(같은 함수의 다른 경계), `H-114`류(하루 차 미반영
  클래스).

### `H-120` 🟡 — `Ref():Callback(fn)` 관용구가 생성 시점에 `fn(nil)`을 한 번 부른다

- **어디**:
  - `base/ref-plan.md`의 콜백 계약: *"콜백은 이미 채워져 있으면 등록 즉시
    그 값으로 1회 호출됨 — nil/미설정 상태여도 그 상태 그대로 호출"* —
    무조건 즉시 1회.
  - 같은 문서의 v1 대체 관용구: *"`Ref():Callback(function(inst) end)`를
    children 배열에 넣는 것만으로 완전히 대체됨"* — default 없는 `Ref()`에
    콜백을 미리 건다.
  - `base/lifecycle-hooks-plan.md`의 확정 스케치:
    `OnCreated(fn) = PreRef():Callback(fn)` /
    `OnRendered(fn) = PostRef():Callback(fn)` — `fn`의 선언 타입이
    `(inst: Instance) -> ()`(non-nil).
  - `base/source-state-plan.md`의 보강 항목이 이 조합을 이미 "사용자
    실수"로 분류해뒀다: *"`default`를 생략한 `Ref()`에 콜백을 걸면 그
    콜백이 즉시 `nil`로 한 번 불림 — `T`가 non-nilable이면 이 시점에 이미
    타입 위반"*, *"non-nilable `T`에 `default` 없이 생성하는 건 사용자
    실수"*.
- **무엇이 어긋나나**: 코퍼스가 **자기 관용구와 자기 슈가로** 그 "사용자
  실수"를 확정 패턴으로 배포하고 있다. `OnCreated(fn)`을 글자 그대로
  구현하면 **`Frame { OnCreated(fn) }`을 쓰는 순간, pre-pass가 `inst`로
  fire하기 전에 생성 시점에서 `fn(nil)`이 먼저 한 번 불린다.** 사용자
  `fn`이 계약된 타입(`inst: Instance`)대로 `inst`를 바로 쓰면(속성 대입,
  `:GetChildren()` 등) **모든 `OnCreated` 사용이 생성 시점에 크래시**하고,
  방어적으로 짜면 훅이 "정확히 1회, inst와 함께"라는 기대와 달리 "nil로
  1회 + inst로 1회" 불린다. children 배열의 `Ref(default):Callback(fn)`
  관용구도 default가 nil인 흔한 경우 동일하다. 어느 문서도 이 상호작용을
  언급하지 않는다(`lifecycle-hooks-plan.md`는 즉시-1회 호출 자체를 다루지
  않는다).
- **실제로 어떻게 터지나**: `OnCreated(function(inst) inst.Name = "x" end)`
  → 생성 즉시 `fn(nil)` → "attempt to index nil" — pre-pass에 도달하기도
  전이다.
- **갈래**:
  - **(a)** 슈가(와 문서 관용구)가 nil 가드 래퍼를 끼운다 —
    `PreRef():Callback(function(v) if v ~= nil then fn(v) end end)`.
    `Ref` 계약은 안 건드린다. 훅 셋이 백로그라 비용은 문서 정정 수준.
    **(권고)**
  - **(b)** `:Callback`의 즉시 1회 호출을 "값이 한 번이라도 `Set`된 적이
    있을 때만"으로 좁힌다 — 즉시 호출의 원 근거(*"이미 채워졌는지 확인이
    항상 필요"*)와 오히려 더 정합하지만, `Ref` 계약 자체를 되짚는 것이라
    파급 확인이 필요하다(미설정 상태를 알고 싶어 콜백을 거는 용례가
    있는가).
  - **(c)** 문서 경고만 — "children 배열 콜백은 nil을 항상 처리하라".
    가장 싸지만 훅 슈가의 인체공학 약속과 어긋난다.
- **M2 착수 전 필요한가**: 아니오 — M8(Ref)/백로그(훅 슈가)다.
- **인접**: 없음.

### `H-121` 🟡 — `slot-plan`의 대표 `updateFn` 예시가 확정 콜백 계약으로는 크래시한다

- **어디**: `base/slot-plan.md`의 "왜 `LayoutOrder`를 Slot이 대신 안
  해주는가" 절의 확정 예시 —
  ```lua
  LayoutOrder = layoutOrder:With(offset):Compute(function(i, o) return i:Get() + o:Get() end)
  ```
  이 예시는 `userdata`/`LayoutOrder` 관용구 전체의 **정본 본보기**로 그
  절이 세 갈래 반환 규칙을 설명하는 데 쓰인다(`dispatch-core-plan.md`의
  Length/Offset 절도 축약형으로 같은 관용구를 인용).
- **무엇이 어긋나나**: 확정 콜백 계약은 **`fn(self, previous?, ...deps)`**
  이고(`base/source-state-plan.md` — trailing deps는 `:Compute(fn, ...)`
  호출 자신의 인자로만 들어오며, **`:With`로 모은 값은 포지셔널로 넘어오지
  않는다**: *"`with`한 값을 포지셔널 인자로 받지 않고 클로저로 직접
  읽는다"*가 그 절의 확정 문장이다). 따라서 이 예시의 두 번째 파라미터
  `o`에 실제로 들어오는 값은 `offset`이 아니라 **`previous`**(그 Compute
  노드의 직전 반환값)다 — 첫 재계산에서 `nil`이라 `o:Get()`이
  "attempt to index nil"로 죽고, 두 번째부터는 **직전 결과 숫자**가 와서
  `number:Get()`으로 죽는다. 같은 문서의 올바른 본보기
  (`store.key1:With(store.key2):Compute(function(key1) ... store.key2:Get() ...)`,
  `base/source-state-plan.md`)와 대조하면 명확하다.
- **실측**: 코퍼스 grep — **라이브 문서(`base/`) 안에서는** 이 모양(다중
  파라미터 `:Compute` 콜백, `prev` 이름 아님)이 이 한 곳뿐이다.
  **[code-review 정정]** 밖에는 더 있다 — `archive/batch-rejected.md:29`
  (히스토리 문서라 방치 가능)와 **`audit/type-recursion-issue/spikes/`의
  `23`/`24`**(`23`은 주석으로 slot-plan의 바로 그 줄을 인용). 그 폴더의
  스파이크는 "직접 다시 돌려 판정을 재현"하라고 남겨둔 것이라, slot-plan만
  고치면 나중에 재실행이 옛 콜백 계약을 "재확인"하는 모양이 된다 —
  **고칠 때 셋을 같은 배치로**.
- **갈래**: (a) 클로저 읽기 형태로 교정 —
  `layoutOrder:With(offset):Compute(function(i) return i:Get() + offset:Get() end)`
  (source-state 본보기와 동형, **권고**), (b) trailing deps 형태 —
  `layoutOrder:Compute(function(i, _prev, o) return i:Get() + o:Get() end, offset)`
  (노드 하나 절약, `previous` 자리를 비워야 하는 부담). 어느 쪽이든 계약
  변경은 없다 — 예시 교정만.
- **M2 착수 전 필요한가**: 아니오 — 다만 `:Compute` 표면을 짜는 M2에서
  이 예시를 참조 구현의 기대 출력으로 쓰면 그대로 옮겨질 위험이 있어
  같은 배치에서 고치는 게 싸다.
- **인접**: 없음.

### `H-122` 🟢 — `isModifier` 가드의 적용 지점 목록이 명시적 초기화 이전 서술이다

- **어디**: `base/modifier-plan.md` 7번의 적용 지점(*"`Store({defaults})`
  생성 시 각 `defaults` 키를 `Source(v)`로 만드는 시점"*),
  `base/source-state-plan.md`의 따름정리 절(같은 문구), `ROADMAP.md` M2의
  `H-81` 체크박스(*"Store 생성 시 eager `Source(default)`"*).
- **무엇이 어긋나나**: 명시적 초기화 확정(2026-08-25) 이후 **Store는 더
  이상 `Source`를 만들지 않는다** — `defaults`엔 사용자가 만든
  `Source(v)`가 그대로 들어오고 생성자는 `table.clone`뿐이다. 세 문서가
  지목하는 적용 지점이 코드상 존재하지 않게 됐는데 `H-81` 체크박스까지
  그 문구를 반복하고 있다. 남는 질문 둘: (1) 그 가드의 실제 자리는
  **`Source(default)` 생성자**로 옮기면 defaults 경로가 자동 커버된다
  (독립 `Source(someModifier)`와 한 자리로 수렴 — 목록이 오히려 짧아짐).
  (2) **Store 생성자가 defaults 값을 런타임 검증하는가**는 어디에도 없다 —
  타입은 `Source<T>` 필드를 요구하지만 `--!nocheck`/동적 코드가
  `{hp = 100}`(raw 값)을 넘기면 지금 스케치(`table.clone`)는 조용히 받고,
  첫 `store.hp:Get()`에서 엉뚱한 에러로 죽는다. `H-40`이 `:List` 요소
  검증을 화이트리스트로 뒤집은 것과 같은 성격의 자리다(`isSource` 검사
  한 순회 — 생성 시 1회라 hot path 아님).
- **갈래**: (a) 가드를 `Source` 생성자로 이동 + Store 생성자에 defaults
  `isSource` 화이트리스트 검증 추가(error `level 2`) — **권고**, (b) 검증
  없이 문구만 정정(타입 방어만 신뢰).
- **M2 착수 전 필요한가**: 소형이지만 예 — `Store.luau`/`Source.luau`
  생성자를 짜는 자리다.

### `H-123` 🟢 — 3차 문서 정합 묶음 (판단 대부분 불필요)

1. **`base/project-setup-plan.md`의 리링크 서술이 `H-78` 이전이다** —
   *"아직 반복 가능한 스크립트/mise task로 정식화하진 않음 — 매번
   `pesde install` 후 수동으로 치환했음"*이라고 적혀 있는데, 7라운드
   `H-78`이 `scripts/relink.sh` + `scripts/test.sh`를 신설해 이미
   정식화했다(커밋돼 있고 이 라운드에서도 실행해 확인). 그 문단이
   "다음 세션이 같은 수동 치환을 반복해야 한다"고 안내하는 셈이라 정정
   대상.
2. **`pesde.lock` 커밋 여부가 미취합 상태다** — 같은 문서가 "미확정,
   사용자 판단 필요"로 열어두고 *"`todos.md`에 확인 필요 항목으로
   반영"*이라 주장하는데, `question.md`/`todos.md`/`HUMAN_TODO.md` 어디에도
   없다(grep 0건). 실태는 lockfile 5개가 **이미 전부 커밋돼 있어** 잠정
   권고와 일치한다 — 확정 한 마디면 닫힌다(§4 Q10).
3. **`base/slot-plan.md`의 `:Single` 표기** — 절 제목과 요약이
   `Slot:Single(state, updateFn?)` 2-인자인데, `H-22` 확정 의사코드는
   `opts`(=`Owned`) 3번째 인자를 받아 `:List`로 전달한다.
   **[code-review 정정]** "헤딩만 stale"이 아니다 — 같은 파일
   `slot-plan.md:3125`의 본문에도 2-인자 표기가 한 곳 더 있다(둘 다 같은
   커밋에서). **덧붙여 같은 클래스 하나 더**:
   `luau-test/done/11-modifier-illegal-value-error.luau:213-216`의 Store
   생성자가 eager `Source(v)` 모델(정확히 `H-122`가 stale로 지목한 그
   형태)을 코드로 박제한 채 `done/`에 앉아 "통과" 상태다 — 명시적 초기화
   반영 때 `rewrite-required/` 이동 또는 재작성 대상(처분은 `STATUS.md`
   갱신과 같은 배치로).

---

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

서로를 규정하는 항목은 묶었다. Q1~Q9는 (a)가 권고안이고, Q10만 예/아니오
단답이다(권고는 "예" — 현 실태 추인).

**Q1. [`H-107`+`H-108`] `Effect`의 `Ref` dep은 `from`을 어떻게 얻는가?**
- **(a)** `Ref` 콜백 계약을 `k(value, self)`로 확장 — 두 번째 인자로 `Ref`
  자신(=`Epoch`). 기존 콜백은 두 번째 인자를 무시하면 그대로, `onDepFire`는
  무수정 성립. **(권고)**
- **(b)** `Effect`가 `Ref` dep에만 래퍼 클로저(`function() onDepFire(nil, d) end`).
- 부속(예/아니오 하나): `Ref:Set`의 순서 계약을 **"값 → `Revision` → 콜백
  (강·약 두 테이블, 각각 스냅샷)"**으로 명문화하고 `H-53` 블록에 반영한다.
  (아니오라면 대안 순서를 지정해 주어야 함 — 콜백보다 뒤면 `Update`가 옛
  리비전을 읽는 창이 생김.)

**Q2. [`H-109`+`H-110`] 전파 루프가 Observer `fn`에 넘기는 self는?**
- **(a)** Observer가 생성 시 리시버를 `_state`(강참조)로 들고, 루프는
  `sub.fn(sub._state, from)` — 계약(self=리시버 lazy 핸들) 유지, Observer의
  상류 강참조(`_hold` 상당)도 이걸로 명문화. **(권고)**
- **(b)** self=Observer 자신을 정본으로 하고 `Observer:Get()` 델리게이션
  신설 — 계약 문장을 고치는 쪽.

**Q3. [`H-111`] `WeakSubscribe`는 `.Subscribed = true`를 세우는가?**
- **(a)** 예 — `WeakSubscribe = 가드 + Subscribed=true + weak 등록`,
  `Subscribe`는 그 위에 강한 킵만. `canExecute`의 전역 경로 판정은 지금
  그대로(`.Subscribed`). `lifecycle-pattern.md`의 (b) 주석과 `H-59` (a)
  서술만 이에 맞게 손본다. **(권고)**
- **(b)** 아니오 — 대신 `canExecute`의 전역 경로 판정을 weak 레지스트리
  멤버십으로 바꾼다(`Unsubscribe`가 양쪽을 지우는 대칭 요구 추가).
- (어느 쪽도 아니면 `Effect`의 State dep이 전파 루프에서 걸러진다 — 제3의
  안이 있다면 그 발화 통로를 지정해 주어야 함.)

**Q4. [`H-112`] `CheckReserved`의 인자는?**
- **(a)** `T`가 아니라 **`keyof<T>`**(키 싱글톤 유니온)를 받는
  `CheckReservedKeys` + 팬텀 필드 격리 — 실측 완료(예약 키 진단 + 필드
  접근 + 무주석 콜백 추론 전부 생존, 생성자 호출 경로 포함). **(권고)**
- **(b)** `CheckReserved` 포기 — 예약 키 충돌은 문서 경고만("조용히 타입
  검사가 꺼진다"를 감수).
- **(c)** 선언 스타일을 §1③(`typeof`)으로 전환 — 무주석 콜백 추론 포기.

**Q5. [`H-113`] splice의 접두합 무효화 지점은?**
- **(a)** `j`가 아니라 **`j - 1`**로 낮춘다(재개 지점은 `invalidAfter`
  유지) — 커서 위치 splice도 되감기게 됨, 비용은 한 자리 여분 재방문
  (offset 쓰기는 `~=` 가드로 no-op). **(권고)**
- **(b)** 되감기 신호를 별도 필드로 분리 — `H-101`의 "새 필드 안 만든다"
  확정을 되짚는 쪽.

**Q6. [`H-119`] `recompute`의 명시 호출 경로도 재진입 게이트를 타는가?**
- **(a)** 예 — `raw*` 삭제 3형제(`rawRemove`/`rawUnmount`/`rawDetach`,
  그리고 `rawSplice`류)와 `_baseObserver` 콜백의 직접 `recompute` 호출을
  전부 "`blocker:IsOn() or bk.recomputeBlocker:IsOn()`이면 건너뜀"으로
  통일한다(건너뛴 몫은 splice/`invalidAfter = 0`이 당겨둔 신호로 바깥
  루프의 되감기가 복구 — `H-101` 설계 그대로). `_baseObserver`엔 `H-3`가
  요구하는 `bk.invalidAfter = 0`도 의사코드에 넣는다. **(권고)**
- **(b)** `recompute` 자신의 머리에서 검사해 조기 반환 — 호출부 무수정,
  대신 `H-19`의 "명시 호출" 표면 의미가 바뀜.

**Q7. [`H-118`] `Debounce`/`Throttle` 정책은 `emit`을 쥐는가?**
- **(a)** 예 — 정책이 `b`(사적 Blocker)와 `emit`을 **둘 다** 쥔다. 상류
  emit 도착 경로는 `pass()`(Blocker 위임), 타이머/핸들 경로의 flush·
  버리기·조회는 `emit()`/`emit(false)`/반환값 직접 사용. 두 flush 경로의
  중복은 빈 배치 no-op 계약이 흡수함을 명문화하고, `gate-plan.md` 5번의
  "`emit`을 아예 안 쥔다" 문장에 정정 배너. **(권고 — `H-55`/`H-86`
  실측이 강제하는 방향)**
- **(b)** `Blocker` 위임 폐기, 정책이 `emit`만 쥔다 — `blocker:Policy`
  표면의 존재 이유를 되짚어야 함.

**Q8. [`H-120`] `OnCreated`/`OnRendered`(및 children 배열
`Ref():Callback(fn)` 관용구)의 생성 시점 `fn(nil)` 호출은?**
- **(a)** 슈가/관용구 쪽에 nil 가드 래퍼 — `Ref` 계약 무수정. **(권고)**
- **(b)** `:Callback`의 즉시 1회 호출을 "한 번이라도 `Set`된 뒤"로 좁힘 —
  `Ref` 계약 수정(파급 확인 필요).
- **(c)** 문서 경고만("콜백은 nil을 항상 처리").

**Q9. [`H-122`] `isModifier` 가드 자리와 Store defaults 런타임 검증?**
- **(a)** 가드를 `Source(default)` 생성자로 이동(defaults 경로 자동 커버)
  + Store 생성자가 defaults 값 전량에 `isSource` 화이트리스트 검증
  (error `level 2`, 생성 시 1회). **(권고)**
- **(b)** 문구만 정정하고 런타임 검증은 안 함(타입 방어만).

**Q10. [`H-123`-2] `pesde.lock` 커밋 — 현 실태(5개 전부 커밋됨)대로
확정하는가?** (예/아니오 — 예면 `project-setup-plan.md`의 "미확정" 표기를
닫고 인덱스 취합 불필요.)

---

## §5 이상 없다고 확인한 것 (다음 라운드가 다시 파지 않도록)

**A각도 — 겹쳐 읽었는데 정합했던 조합**:

- **`GateNode` 조립 전체** — `_receive`의 §4 규칙 1~3 + `emitEpochMap`은
  `Peek`(수신)/`Sync`(flush 앞) 분리, flush의 스왑(weak 유지, `H-9`)·빈
  배치 얼리리턴·`emit(false)` 버리기·게이트-게이트 unfold. `gate-plan.md`
  4번·8번, `state-epoch-plan.md` §3~§5, `blocker-plan.md`가 서로 아귀가
  맞는다.
- **`Blocker` onunblock 핸들 세 자리**(`H-63`) — weak-키 해시맵 셋 / 강한
  주인은 `onUpstreamEmit` 클로저 / 스냅샷 순회. 세 문서 일관.
- **캐시 카운터 쌍**(`H-85`) — 시드(`target = 0, curr = nil`)의
  `/code-review` 정정이 `state-epoch-plan.md`에 정확히 반영돼 있고,
  `bit32.bnot(-n)` 랩과의 결합도 정합(감소 방향이라 nil 시드가 맞다는
  논증 포함). §4 상단 표기 잔재만 `H-114`-2.
- **전파 루프의 구조 자체**(`H-56`/`H-23`) — 한 집합 + 스냅샷 + 자식
  State는 `canExecute` 안 봄. 셋의 상호작용은 정합(걸린 건 self 인자
  `H-109`와 `WeakSubscribe` 게이트 `H-111`이라는 다른 축).
- **`_hold` 불변식의 파생 노드 쪽** — `:With`/`:Compute`/`:Gate`/`:Block`
  전부에 대해 일관 서술(`GateNode` 필드 목록에도 `_hold` 존재). 걸린 건
  Observer 누락(`H-110`)뿐.
- **`Effect` 생성자 의사코드의 나머지** — deps 검증(`select("#", …)`/
  화이트리스트/중복 무시), `_blocker` 억제 구간과 `canExecute` 게이트
  순서(억제가 `Update`보다 먼저), `_installed` 플래그, `Rerun`의 지연
  재진입, `_bindDestroying`의 조건부 캐치업(`Refresh()`를 `or` 단축평가
  앞에 두는 정정 포함) — State dep 경로에 한해 정합.
- **`Relate` 슬롯 표와 커밋된 `Relate.luau`** — 문서의 슬롯 표(바깥 키
  weak / 내부 키 강 / 값 강·약)와 코드가 일치, `runInitRelate`의 내부 키
  논증(`H-77`)도 커밋된 `init.luau`와 일치.
- **`RefLeafHandler`/`ObserverEffectLeafHandler`의 `SetWeak` 정정**(`H-71`)
  — 양쪽 의사코드에 읽기(`GetWeak`)까지 맞춰 반영돼 있다.
- **`recompute`의 일반 경로** — 앞자리(j<i) splice 되감기, `sum`
  신선도(길이 읽기가 `Set` 뒤), 캐시 리셋·블로커 해제를 `Length:Set` 앞에
  두는 정정, 토큰 기반 역참조(`gatedRecompute`가 인덱스를 캡처하지 않음,
  `len`이 아니라 토큰 키) — 전부 정합. 걸린 건 j==i 경계(`H-113`)뿐.

**C각도 — 폐기 표면 잔재 grep**: `GetDynamic`/`WrapStore`/
`ProcessStoreType`/`_installing`/`_refDeps`/`_refCallbacks`/
`store.key = v`는 라이브 문서에서 전부 폐기 표시가 붙은 맥락(정정 배너,
사용자 인용, 역사 기록)에서만 등장 — 배너 없는 잔재는 `H-114`-1 하나였다.
소비자 문서(`component-composition-plan.md` 등)의 Store 예시도 최종형과
정합(3·5차 감사가 실제로 잘 쓸어냈다).

**D각도 — M2 체크리스트 시뮬레이션**: 공통 기반(Brand/Relate/
LifetimeHandle 인터페이스) → `EpochMap` → Source/State/Store → Observer →
Effect → Gate → Blocker 순서에 **앞으로 참조 없음**. `Effect`가 요구하는
`Blocker` 기본 4종은 체크박스 주석이 이미 순서 예외를 명시. mock 생명주기
4종(`H-97`)과 "전파 루프를 실제로 돌리는" 테스트가 마일스톤 끝에 있어
**M2 종료 시점에 돌려볼 수 있는 것이 실재한다.** `H-80`(Quad 타입 확장)
체크박스도 자리에 있다 — 단 그 실행이 `H-112`의 파급(아래 §6)과 얽힌다.

**G각도 — 재확인된 Luau 사실**: `<<T>>` 값 호출부 인스턴스화(생성자 호출
경로 포함, `r8-spike-04`), 예약 키 충돌 시 타입 함수 진단이 강제 평가 없이
사용 지점에 뜸, `bit32.bnot(-rev)` 랩(스파이크 5에서 재사용, 문서 실측
표와 일치), 타입 함수 안 `print + types.never` 패턴.

**2차 패스에서 추가로 확인한 "이상 없음"**:

- **⭐ `CheckedQuad<T, Pattern>`은 M2 표면 추가에도 살아남는다(실측,
  `r8-spike-07`)** — 1차 §6의 미확정("`Quad` 타입에 `Source`류가 붙으면
  `CheckVersion`도 `H-112`처럼 죽는가")을 실측으로 닫았다. 배선이 이미
  격리형이라(`CheckVersion`은 `T`가 아니라 `index<T, "Version">` — 싱글톤 —
  만 받는다) §1 누수가 든 `Source` 필드를 `Quad`에 추가해도 **양성 경로
  클린 + 버전 불일치·타입 음성 대조군 정확히 발화**. 내장
  `index<>`/`keyof<>`는 형제 필드의 `*error-type*`에 오염되지 않는다는
  것도 이걸로 재확인 — `H-112` (a)안(`keyof` 경유)의 근거가 하나 더 는다.
- **⭐ 1차 §6의 "제거된 자리의 늦은 발화" 의심 해소** —
  `rawUnmount`/`rawDetach`/`rawRemove` 계열은 splice **전에**
  `bk.observers[index]`를 `unbindLifetime`하고, `spliceArraysDown`의 치환
  목록에 `bk.observers`/`bk.tokens`/`bk.indexOfToken`이 명시돼 있다
  (`base/slot-plan.md`의 `raw*` 규약) — 제거된 자리의 길이 Observer는
  발화 전에 `canExecute`가 걸러 `indexOfToken[token]`이 `nil`인 채로
  `gatedRecompute`가 도는 경로가 정상 흐름엔 없다.
- **`attachSlot` 3형제 분해**(materialize/mount/공개 진입점) — `H-2`
  재작성 이후의 순서(앵커 먼저 → Blocker 안 `activateList` → 마지막
  `recompute` → 부모 `setLength`)와 재마운트 분기(멱등 가드 + 앵커 이전)가
  자기 완결적으로 정합. 다만 `_baseObserver` 콜백의 두 누락은 `H-119`로.
- **`:List`의 `reconcile`/`settle`** — `H-1`/`H-2`/`H-31`/`H-38` 반영분
  (두 좌표계 분리, 선행 중복 키 패스, 증분 키 집합, `getOffsetAt` 기반
  `physIndex`)을 순차 실체화 전제와 겹쳐 트레이싱 — 정합. `KeyGone`
  소멸 루프의 스냅샷 순회, `Detach` 재마운트의 `fromDetached` 예외,
  `Owned = false` 분기 전부 아귀가 맞는다.
- **`Dispatch.process`의 (A)/(B) 분기·`retractFrom`·`NOOP` 마커** —
  하강 diff 체인 절을 전량 읽음, `H-103`의 UB 명문화 포함 정합.
  `StoreBind.process`의 Observer 배선도 `H-109`와 무관한 형태(인자 미사용
  클로저)로 안전.
- **`lifecycle-hooks`의 `OnDestroyed`** — `Effect(function() return fn end)`가
  7라운드 `fn(self) -> ...(() -> ())` 시그니처·"바운딩 없이 버려지면 UB"
  계약과 정합(children 배열에 놓이므로 바인드됨). 걸린 건 `OnCreated`/
  `OnRendered` 쪽 즉시-nil 호출(`H-120`)뿐.
- **`component-composition-plan.md`** — 최종 Store 형태·`or None` 관용구·
  named 경계 전달 전부 최신 상태와 정합(3·5차 감사 반영 확인).
- **`attribute-plan.md`의 `:NameMap()` × `store:Names()`** — 명시적
  초기화 + `Of` 동적 키 위에서 성립하고, "나중에 `Of`로 는 키는 다음
  재디스패치에" 캐비엇도 양쪽에 있음.
- **`debounce-throttle-plan.md`** — `H-33` 무효화 배너·`H-32`·`H-86`·
  `H-94` 반영 확인(걸린 건 `gate-plan.md` 5번과의 미조정 — `H-118`).
  `Timeout` 타입/`os.clock` 차이 계산 전용/취소 없는 엔진 대응은 자기
  완결적으로 정합.

**3차 패스에서 추가로 확인한 "이상 없음"** (`base/` 전 문서 완독 기준):

- **`slot-plan.md` 나머지 전 구간** — 요소 타입 화이트리스트(`H-40`
  `wrapElement` 단일 관문), CRUD 표와 fail-fast 에러 조건,
  `_crudUsed`↔`_listed` 상호 배타, `Slot(initial)` 생성자, `:List`
  전문(선행 중복 키 패스·증분 키 집합·`prevKeys` 소멸 루프·`userdata`
  생명주기 제약), `:Single`의 `KeyGone` 흡수(`H-22`), 래핑/언래핑 한 쌍
  (`C-3` — `_wrapped` 역참조, `isSlot` 가드), `State<Slot>` 교체=언마운트와
  소유권 표, `dispose`의 분기 밖 소유권 가드(`H-28`/`H-43`)와 `GetWeak`
  정정, `unmountSlotTree`/`destroySlotTree` 대칭(관측자 해제·`_detached`
  처분·`Offset` 보존), nested index의 `getOffsetAt` 전환(`H-2`) — 전부
  자기 완결적으로 정합. 걸린 건 예시 하나(`H-121`)와 재진입 게이트
  우회(`H-119`, 2차)뿐.
- **`dispatch-core-plan.md` 전량**(체인 절 포함 완독) — 핸들러 3종
  계약(retractor 반환 생략 불가·`NOOP` 마커·깊은 인덱스 LIFO·(A) 분기는
  교체지 스택다운이 아님), 우선순위 밴드/`HANDLER_PRIORITY_FALLBACK`/매치
  실패 즉시 error, `None`→`NilHandler` 이관 구조와 두 센티널 분리, 싱글톤
  확정 논거(의존 단방향), base 소유 핸들러의 self-등록 재역전과
  `InitNamespace` 비충돌 논거, `H-26` 안전망 주장 삭제 확인, Length/Offset
  전문(등록 책임 말단 원칙 + `H-39` 사후 반영 확인, 해제 순서 계약), 배치
  게이팅(`setOffsetSource` 즉시 계산, 마지막 recompute의 실제 역할
  `DC-11`, `PostRef` 콜백 게이트 계약 `H-17`), yield 금지 불변식 — 정합.
- **`modifier-plan.md` 전량** — flatten 역순 순회 + `ProcessedModifier`
  소진(`M-2`/`H-35`), 내부 저장소 분리(리터럴 키 금지), `None` unsetter
  구분(`M-5`), 4-1 State 분기 표, 핸들러 계층 값 즉시 error와
  `State<Ref>` 안쪽 UB 한정, `Apply`/`Overridden`/`:Peek` 역할 구분 —
  정합. 걸린 건 적용 지점 문구(`H-122`).
- **`tag-plan.md` 전량** — 위치(`k`) 키잉 참조 카운트, 생존 이름 홀더
  유지 정정, `string | {string}` 인자 근거, `H-39`/`H-52` 반영 — 정합.
- **`attribute-plan.md` 전량** — 이름 claim + 그룹 전용 키 이중 구조,
  `groupClaimKeys` 위치 claim(순서: 위치 먼저), 부분 실패 정책(시끄러운
  반복 실패), 이름 이동 UB(`H-18`/`H-45`), `NameMap()`×`store:Names()`
  배선, 값 객체 `inst` 되참조 금지 GC 계약 — 정합.
- **`tween-plan.md` 전량** — 3-상태 슬롯, override 두 값, plain-only 옵션
  원칙, `Animate`의 미선언 읽기(state-epoch `H-91` 예외와 정합),
  `:Mapped`의 ③ 선언 요구(`H-24`) — 정합.
- **`bind-system-plan.md`/`event-plan.md`/`onchange-plan.md`/
  `ui-shorthand-plan.md`** — `D` 생성기 계약(이벤트 콜백 타입 포함),
  `None`/`nil` disconnect와 `NilHandler` 비충돌, `OnChange`의 `v == nil`
  얼리리턴(`H-27`), 숏핸드의 `Dispatch.process(child, …)` 위임과
  gcconn 셋업 전제(`UI-5`) — 정합.
- **`module-lifecycle-plan.md`/`project-setup-plan.md`/`fallback-plan.md`/
  `purity-and-effects-plan.md`** — `RunInit` 함수-키 멱등(커밋된 코드와
  일치), `_initializedBy` 분리, `@self` require 규칙, symlink 함정의 범위
  (Rojo 무관), `Fallback`/`Traceback` 시그니처와 `H-26` 백로그 — 정합.
  걸린 건 리링크 서술 stale(`H-123`).
- **B각도 E2E의 문서 레벨 완결** — 이로써 Store→State→Observer/Effect→
  Gate/Blocker→Dispatch 체인→Slot/List→Tag/Attribute/Tween→컴포넌트
  경계까지 **모든 마일스톤의 계약 문서를 한 라운드 안에서 읽고 이었다.**
  손 트레이싱 수준의 E2E는 M2~M3 구간(1·2차)에 집중됐고 M5+ 구간은 문서
  정독 수준임을 §6에 남긴다.

---

## §6 남은 의심 / 못 본 것

**남은 의심** (확신까지 못 간 것 — 미확정). **[2차 패스 갱신]** 1차의 네
항목 중 둘 — "제거된 자리의 늦은 발화"(`indexOfToken` nil 크래시 의심)와
"`CheckVersion<Quad>` 파급" — 은 각각 `raw*` 규약 전수와 실측
(`r8-spike-07`)으로 **해소돼 §5로 옮겼다.** 남은 것:

- **§1③(`typeof`) 선언과 최종 Store 형태의 결합** — 스파이크 2의
  `unknown` 붕괴가 formulation 특유의 것인지 일반적인지 분리하지 못했다
  (`typing-limits.md` §9의 "③ 개별 실측" 미완 항목과 같은 자리). `H-112`를
  (a)로 닫으면 당장은 안 필요하다.
- **게이트 `emit(false)` 직후 다이아몬드 두 번째 경로 도착** — 버린 출처가
  같은 파동의 두 번째 경로로 `withheld`에 재진입해 다음 flush에 실릴 수
  있어 보인다(수신 판정이 `Peek`이라 규칙 2로 통과). 정책이 파동 도중
  동기적으로 `emit(false)`를 부르는 경우가 실재하는지(타이머 콜백이 아니라)
  판단이 안 서서 발견으로 안 올렸다.
- **`H-119`의 도달 조건 폭** — 재진입 트레이스는 수동 CRUD Slot 기준이다.
  `:List` Slot은 공개 CRUD가 막혀 있어(`_listed` 가드) 그 경로로는 도달이
  좁아지지만, `settle` 내부 경로가 재진입 문맥에서 돌 수 있는지까지는
  전수하지 못했다 — 어느 쪽이든 게이트 통일(Q6의 (a))이면 같이 닫힌다.

**못 본 것** (범위 밖 — "감사 통과"로 읽지 말 것). **[3차 패스 후 목록 —
`base/` 전 문서는 전량 완독됐다(개수는 폴더가 소스)]**:

- **손 트레이싱의 깊이 차이**: M2~M3 구간(반응형·디스패치·recompute)은
  값 단위 트레이싱과 실측까지 했지만, **M5+ 구간(그룹 `Attribute` 위임
  체인, `D` 생성자, 숏핸드→`PropertyHandler` 위임, `:List` reconcile의 실제
  값 대입)은 문서 정독 + 계약 잇기 수준**이다 — 의사코드를 실제 값으로
  돌려보진 않았다. 다음 라운드가 있다면 이 구간의 손 트레이싱이
  최우선이다.
- **`reference/` 폴더**(근거 기록)와 `archive/` 원문들, `research/` 문서
  본문 — 라이브 계약이 아니라서 뺐다(발견 검증에 필요한 곳만 부분 참조).
- **Studio 실측 전부**(이 환경 제약 — `SignalBehavior` 레이스,
  gcconn 트릭의 미발화 재확인 등은 기존 실측 기록에 의존했다).

---

*스파이크 원본: 세션 스크래치패드
(`r8-spike-01`~`07-*.luau`) — 발견 근거는 전부 위 항목에 인라인/결과
전사돼 있어 파일 유실과 무관하게 재현 가능하다. 저장소는 규칙대로 아무것도
수정하지 않았다(이 파일이 유일한 산출물).*
