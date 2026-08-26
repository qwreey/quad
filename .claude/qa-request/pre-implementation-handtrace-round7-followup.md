# 7라운드 손 트레이싱 발견 — **사용자 결정과 반영 결과**

**무엇인가**: `.claude/qa-request/pre-implementation-handtrace-round7.md`의
발견 52건(`H-55`~`H-106`)과 그 검증 패스
(`qa-request/pre-implementation-handtrace-round7-verification.md`)를 사용자와 대화형으로 처리한 결과. **결정의 소스는
이 문서**이고, 발견 원문은 위 두 파일이 소스다(여기서 다시 서술하지 않음).

**진행 방식**: 검증 패스가 재편성한 **결정 단위 12묶음(🅐~🅜)** 순서를
따랐다. 같은 묶음 안의 항목은 결론이 서로를 규정하므로 같이 물었다.

**[2026-08-25] 결정·반영 전부 완료.** 12묶음을 순서대로 처리했고 `base/`
반영까지 끝났다(`doc-check.py` ERROR 0). 처분 요약:

| 처분 | 건수 | 번호 |
|---|---|---|
| 확정 — `base/` 반영 | 39 | `H-55`~`H-72`, `H-79`~`H-82`, `H-84`~`H-92`, `H-94`~`H-99`, `H-101`~`H-106` |
| **무효/소멸** | 4 | `H-73`(`<<T>>`가 값 호출부에서 동작함) · `H-74`·`H-75`·`H-76`(Store 재설계로 `WrapStore` 폐기) |
| **기각** | 1 | `H-77`(`RunInit` 사례 — 성립 안 하는 사용법) |
| 범위 축소 | 2 | `H-87`(🔴→🟡) · `H-105`(수치 정정) |
| 다른 항목으로 흡수 | 6 | `H-64`/`H-70`(`Ref`=`Epoch`) · `H-102`(역참조 조회) · `H-93`/`H-98`(`_hold`) · `H-83` |

**부수로 닫힌 것 둘** — `question.md` 최우선의 **중간 State GC**(`_hold`
불변식)와 **`GetDynamic` 위치**(콜론 + `CheckReserved`). **M2 착수를 막는
항목이 하나도 남아 있지 않다.**

**새 표면**: `Ref.Revision`(=`Epoch`) · `Ref:WeakCallback` ·
`Observer:WeakSubscribe`/`:WeakUnsubscribe` · `EpochMap:Peek` ·
`store:Of`/`:Names` + `CheckReserved` · `emit(commit) -> boolean` ·
`bk.recomputeBlocker` · `EffectHandle:Rerun`(정의) · `_consumeCleanup`
**폐기**: `WrapStore`/`ProcessStoreType` · `_installing` · `rawInvalid` ·
`_refDeps`/`_refCallbacks`/`_observers`(→ `_deps` 하나) · Store의 lazy 우선 모델
**역전 없음** (**⚠️ [2026-08-26 정정, 8라운드 처리 중 발견]** 여기 한때
*"역전: `store.key = value` 부활"*이라고 적혀 있었는데 **그건 같은 날 오전에
넣었다 철회한 Store 재설계의 서술이 요약 머리에 남은 것**이다 —
`archive/store-value-field-redesign-withdrawn.md`의 대조표가
*"`store.key = v` 부활 → **폐기 유지**"*라고 명시하고 `todos.md` 00번도
"역전 없음"이라고 적는다. `store.key = value` 폐기(2026-08-06)는 유지된다)
**툴체인**: `scripts/relink.sh` + `scripts/test.sh` 신설 — `luau` CLI가
심볼릭 링크를 못 탄다는 것이 최소 재현으로 밝혀졌다(`H-78`).

---

## 🅐 게이트 정책의 상태 접근 통로 — `H-55` · `H-86` · `H-72` · `H-63`

### `H-55` + `H-86` — `emit`에 인자와 반환값을 준다 **(확정)**

`setup: (emit: (commit: boolean?) -> boolean) -> (onUpstreamEmit: () -> ())`

- `emit()` / `emit(true)` — 평소대로 흡수 집합을 flush하고 전파.
- `emit(false)` — **흡수 집합을 버리고** 전파하지 않는다(`Trailing = false`,
  `Cancel`, `OffWithoutEmit`이 요구하던 "버리기").
- **반환값** — "실제로 내보내거나 버릴 게 있었는가"(= 흡수 집합이
  비어 있지 않았는가). 정책이 `pending`을 따로 안 들고도 "지금 쌓인 게
  있나"를 읽는 유일한 통로.

`H-55`의 갈래 (b)와 `H-86`의 갈래 (a)를 그대로 합성한 것. `H-49`의
*"`setup` 시그니처는 안 바뀐다"*는 **인자 목록은 유지한 채** 최소로만
되짚는다(인자가 늘지 않고 기존 인자에 선택 파라미터와 반환값이 붙는다).

`Throttle`의 `onWindowEnd`가 이걸로 닫힌다:

```lua
if not emit() then   -- 보류분 없었음
  window = nil       -- 완전 idle 복귀 → 타이머 체인 종료
else
  rearm()
end
```

### `H-72` — `EpochMap:Peek(from) -> boolean` 추가 **(확정)**

갈래 (a). 읽기 전용 비교(저장된 리비전과 비교만 하고 덮지 않음).
`Update`가 이미 `{읽기, 비교, 쓰기}`라 `Peek`은 그 앞 두 개만 쓰는 것이고
내부 코드 공유가 쉽다. `GateNode:_receive`가 이걸 쓴다:

```lua
local valueChanged = self.valueEpochMap:Update(from)
local emitChanged  = self.emitEpochMap:Peek(from)   -- 갱신 안 함
```

### `H-63` — 세 자리 모두 선례대로 **(확정)**

1. onunblock 핸들 보관은 **weak-키 해시맵 셋** `{[handle] = true}`
   (`__mode = "k"`) — `H-7`이 `Ref.Callbacks`에 한 것과 동일. 배열의
   구멍/`ipairs` 조기 종료 문제가 소멸한다.
2. **강한 주인은 정책이 반환하는 `onUpstreamEmit` 클로저다** — 그 클로저가
   onunblock 핸들을 upvalue로 잡는다. 체인은
   `GateNode → onUpstreamEmit → onunblock 핸들`이고, Blocker 쪽은 weak이라
   **게이트 노드가 죽을 때만** 수거된다. Blocker가 핸들을 강하게 드는 안은
   기각 — 오래 사는 Blocker 하나가 거기 걸렸던 모든 gated state와 상류
   체인을 영원히 살려두므로(`:List` 항목마다 게이트를 무는 패턴에서 직행
   누수).
3. `Off()`/`OffWithoutEmit()`은 **스냅샷을 뜬 뒤 순회**한다(`H-23`과 동일).

---

## 🅑 전파 루프를 코드로 확정 — `H-56` · `H-62` · `H-61`

### `H-56` — 한 집합 + 구독자 종류별 분기 **(확정)**

구독자 집합은 **하나**(`{[subscriber] = true}`, weak-키)이고, 원소는
**Observer 값**이다 — emit 클로저가 아니다(`bindLifetime`이 그 identity를
쓰므로 필수). `lifecycle-pattern.md` (4)의 *"Observer의 emit 클로저"* 표현을
고친다.

```lua
function State:_emitDown(from)
  local snap = {}                     -- H-23 스냅샷
  for sub in self._subs do snap[#snap+1] = sub end
  for _, sub in ipairs(snap) do
    if isState(sub) then              -- 자식 노드
      sub:_receive(from)              -- §4 규칙 1~3, canExecute 안 봄
    elseif canExecute(sub) then       -- Observer / Effect
      sub.fn(sub, from)
    end                               -- 거짓이면 조용히 건너뜀
  end
end
```

두 집합(`_childNodes`/`_observers`)으로 나누는 안은 기각 — emit마다 스냅샷이
두 번이 되고(`H-92`의 할당 비용 두 배), 등록/해제 경로도 둘로 갈린다.

### `H-62` — eager(생성 즉시 등록) **(확정)**

**사용자 판단**: *"생성 즉시 밖에 없다. 옵져버가 실행 안 된다면 get 자체가
안 되므로, lazy 하면 아예 등록 될 기회가 없다."* — lazy가 성립하려면
"먼저 `Get()`이 일어난다"가 전제인데, `Get()`을 부르는 주체가 바로 그
등록되지 못한 Observer라 순환이다.

`:With`/`:Compute`/`:Gate`/`:Block`은 **만들어지는 그 자리에서** 상위의
구독자 집합에 들어간다. `state-epoch-plan.md` §4의 생성 시점 시딩,
`blocker-plan.md`의 *"호출되는 즉시 … 등록"*, `source-state-plan.md`의
":With도 새 State 노드로 확정" 절과 이미 일치한다. lazy를 논거로 쓰는
"왜 State 체인을 Modifier처럼 플래튼하지 않는가" 절을 고친다.

⚠️ eager이므로 `question.md` 최우선의 **"중간 State GC"** 미해결이 더
절실해진다(엣지가 있어도 상위가 하위를 weak로만 들면 노드가 사라진다).

### `H-61` — 무인자 `state:Observer()`의 내부 콜백은 `self:Get()` **(확정)**

`state:Observer() == state:Observer(function(self) self:Get() end)`.
no-op 콜백은 `Get()`을 안 부르므로 문서가 적은 용도(`previous` 패턴의
mutate 로직을 계속 돌게 하기)를 못 한다. 호출부 서술은 그대로 두고 내부
콜백만 못박는다.

---

## 🅔 `Effect` 배선 — `H-57`~`H-60` · `H-64` · `H-65` · `H-70`

이 묶음은 대화 중에 **원문의 갈래 어느 것도 아닌 구조**로 수렴했다. 사용자가
두 도구를 제안했고(`Ref`의 `Epoch` 승격, `Weak*` 등록 표면), 그 둘이
`H-58`/`H-64`/`H-70`/`H-59`를 **한 번에** 닫았다.

### 확정된 구조 — 강한 주인은 항상 `Effect`, 발화 게이트는 `canExecute` 하나

```
Effect ──강──▶ { [Ref | State] = fn | Observer }    ← 강한 주인은 언제나 Effect
Ref.Callbacks       ──약──▶ fn         (:WeakCallback)
Observer 전역 레지스트리 ──약──▶ Observer  (:WeakSubscribe)
발화 게이트: 전부 canExecute(handle) 하나로
```

**사용자 결론**: *"그냥 간단하게 저 강한 map 을 Effect 가 가지고,
WeakSub/WeakUnsub 를 WeakCallback 처럼 넣어줍시다. 의미론은 같습니다.
callback 을 잡고 있지 않거나, sub 대상인 observer 를 잡고 있지 않으면 gc 될
수 있다. **그러면 bindLifetime 은 effect 하나 구현을 한 이후 canExecute 로
모두 처리한다. 간단해집니다.**"*

- dep마다 바인드/언바인드에서 등록·해제하던 춤이 **통째로 사라진다**.
  `bindLifetime`/`unbindLifetime`은 `Effect` 핸들 하나에만 적용되고,
  내부 Observer와 `Ref` 콜백의 발화 여부는 `canExecute(handle)`이 전담한다.
- 그래서 `H-7`의 *"`unbindLifetime`과 `:Unsubscribe()`에서 `:Uncallback`한다"*는
  **필요 없어진다**(`ref-plan.md`의 *"해제는 누수를, 게이팅은 발화를 막는다"*
  중 앞쪽 절반을 `Weak*`가 대신한다).

### 새 표면 — `Ref:WeakCallback` / `Observer:WeakSubscribe`·`:WeakUnsubscribe`

- **`Weak*`가 프리미티브이고 강한 쪽이 그 위에 얹힌다.** **사용자 확정**:
  *"동작 자체는 Weak 아닌것과 동일하게 가고, 가드도 동일하나 단순히 gc 안
  되도록 킵 해주는 부분만 제거된 함수가 됩니다. 따라서 내부적으론 Weak 를
  구현해 두고, Weak 아닌 곳에서 Weak 를 수행하고 gc 처리만 두면 돼요."*
  → `Callback(fn) = WeakCallback(fn) + 강한 셋에 킵`,
    `Subscribe() = WeakSubscribe() + 강한 레지스트리에 킵`. 구현이 한 벌.
- 왜 `WeakRef`가 아니라 이것인가: **사용자 지적** — *"Ref 안에 항상 콜백이
  쌓인다는것도 문제가 됨."* `WeakRef`는 "`Ref`가 `Effect`를 붙든다"만 풀고
  "`Ref.Callbacks`에 죽은 클로저가 쌓인다"는 못 푼다. `WeakCallback`은 둘 다
  푼다 — `Effect ↔ cb` 순환이 자기완결이라 Luau GC가 통째로 수거하고,
  `Ref` 쪽 항목도 같이 사라진다.
- **`WeakRef`는 만들지 않는다**(사용자: *"안 만들어야겠습니다. 아이디어만
  기록."*). 아이디어 원문: `WeakRef:Set(v)`/`:Get()`만 주고
  (`.Value`가 아닌 이유는 내부 값이 항상 있다고 확정된 상태가 아니라서),
  내부는 `setmetatable({}, {__mode = "v"})`의 1-슬롯.
- 이건 🅐-3(`H-63`)에서 `Blocker`의 onunblock 핸들에 내린 결정과 **같은
  패턴**이다 — 강한 주인은 소비자 쪽, 등록처는 weak.

### `H-58` + `H-64` + `H-70`(중복) — `Ref`를 `Epoch`로 승격 **(확정)**

**사용자 제안**: *"혹은 Ref 까지도 Epoch 를 구현해줘도 좋다는 생각.
'바뀌였나?' 보는건 source 에 대한 계약이라, 똑같이 실제 값을 가지는 Ref 도
이를 구현해주는데 문제가 없음."*

`state-epoch-plan.md` §2가 이미 예상해둔 확장이다 — *"`Source`가 아닌
원천(외부 시계 등)이 특수 분기 없이 낀다 … `EpochBrand:register(self)` 한
줄로 끝난다."*

- `Ref`가 공개 필드 `.Revision`을 갖고 `EpochBrand`에 등록된다.
  `:Set()`이 `Source`와 같은 `bit32.bnot(-rev)`로 갱신.
- `.Callbacks`(푸시 경로)는 그대로 — `Epoch`는 부기일 뿐이다.
- 그래서 `EffectHandle._epochs`가 State/Source/`Ref`를 **균일하게** 담고,
  포탈 캐치업이 dep 종류에 따라 갈리던 `H-64`가 **대칭**이 된다.
- `H-70`의 "같은 `Ref` 중복"도 `EpochMap` 키 dedup으로 **공짜로** 닫힌다
  (사용자: *"이미 dedup 해주는 도구는 Epoch 가 있고, 그걸 그대로 적용하는
  사안으로 공짜로 해결됨"*).

### `H-58` — 등록 구간 억제는 `Blocker` **(확정)**

**사용자 지적**: *"해당 맥락의 도구인 Blocker 가 존재함 … 이미 Slot 에서
사용중임. 모든 옵저버와 callback 등록에 있어서 이를 수행해야할 것임.
**옵져버도 처음에 호출하고, 여러 state 를 넣을 수 있음에 유의할것.**"*

이 문제는 `Ref` dep 전용이 아니다 — `source-state-plan.md`가 확정한
*"`fn`은 등록 시점에 즉시 1회 실행된다"* 때문에 **State dep이 여러 개인
`Effect`도 똑같이 중복 실행**된다.

- `Effect`가 사적 `Blocker` 하나를 든다. 등록 구간 동안 `On()`, 끝나면
  `OffWithoutEmit()`. 즉시-1회 호출 경로가 전부 `blocker:IsOn()`이면 조기
  리턴. `materializeSlotTree`가 쓰는 관용구와 같은 모양이다.
- **별도 `_installing` 플래그는 폐기** — 그건 생성자 구간만 덮어 바인드
  구간을 놓쳤다.

### `H-64` — 캐치업은 조건부, 그리고 **미설치면 재설치** (확정)

```lua
if self._cleanup == nil or self._epochs:Refresh() then self:Rerun() end
```

**사용자 판단**: *"cleanup 함수가 있냐 없냐를 보긴 해야겠네요. 기본적으로
cleanup 의 실행은, cleanup 필드를 읽은 다음 그 필드를 제거해버리고 그 다음
cleanup 을 실행해야할 것으로 보입니다. 그러면 cleanup 클로저가 있냐 없냐로
클린 해야하는지 알 수 있어요. 그리고 cleanup 클로저를 지우는건, 이 역시
gc 에 중요한 부분이겠네요."*

- "바인드 때 항상 실행"이 아니라 **"설치돼 있지 않으면 설치"**다. 그래서
  아래 `H-65`가 요구하는 재설치와 포탈 캐치업이 같은 한 줄로 닫힌다.

### `H-57` — retract가 직접 cleanup을 부른다 (확정)

갈래 (a). `Observer/Effect Leaf dedup`의 retract 클로저에서
`nextValue ~= v` 분기가 `unbindLifetime(v)` 뒤에 `isEffect(v)`면 cleanup을
**소진 호출**한다. 소진(필드 읽기 → 필드 제거 → 실행)이 있으므로 파괴
경로와 이중 호출이 없고, `H-11`이 확정한 *"`unbindLifetime`은 cleanup을
부르지 않는다"*는 안 건드린다.

### `H-60` — `Rerun()` 정의: 재진입은 **지연 재실행** (확정)

**사용자 판단**: *"Effect 의 실행 안에서 뭔가 수행되어 rerun 해야할 상황이
발생하면, 지연해 두었다 나중에 재실행 하는건 어떤지(실행이 끝나고 나서).
실제로 Effect 안에서 state 등을 바꾸는 상황은 react 등지에서 흔함. 유일한
문제는 error 발생 시 어떻게 되느냐인데, 그냥 UB로 두는게 맞아보임. 에러가
난 이후 데이터의 무결이 깨져도 별 책임 안 진다는 quad의 일반 동작이라서."*

```lua
function EffectHandle:Rerun()          -- 공개 메소드, 무인자
  if self._running then
    self._pending = true               -- 실행 중 재진입 → 지연
    return
  end
  self._running = true
  repeat
    self._pending = false
    local c = self._cleanup
    self._cleanup = nil                -- 읽고 → 지우고 → 실행 (소진)
    if c then c() end
    self._cleanup = self.fn(self)
  until not self._pending              -- 재요청이 또 오면 또 돈다
  self._running = false
end
```

- `canExecute` 확인은 **호출부**가 한다(`Ref` 콜백·전파 루프가 이미 그렇게
  한다). 사용자가 `fn` 안에서 직접 부르는 경로는 게이트하지 않는다.
- **error 시 UB** — 전파되고 복구하지 않는다. 🅒(예외 안전성) 묶음의 원칙과
  같다.
- 수렴 책임은 사용자 `fn`에 있다 — 무한 루프는 UB.

### `H-59` — `:Subscribe()`는 셋을 다 한다 (확정)

(a) `handle.Subscribed = true` + 전역 레지스트리에 **핸들 자신** 등록
(`_observers`만 등록하는 해석은 폐기 — `Effect(fn)`이 GC돼 cleanup이
유실된다), (b) 내부 Observer 각각 `:WeakSubscribe()`, (c) `Ref`
`:WeakCallback()`. (b)(c)는 위 구조상 **생성자에서 이미 끝나 있고**,
`:Subscribe()`가 새로 하는 일은 (a)뿐이다.

### `H-70` — deps 검증 (확정)

- `nil` dep → **error**. `select("#", ...)`로 순회해 구멍을 실제로 본다.
- 중복 dep → **무시**(error 아님). **사용자 근거**: *":With 이나 시소한
  연산으로 다른 State 가 된다던가 하면 deps 가 겹쳐도, 근원 source 가 겹쳐도
  에러를 안 냄. Ref 도 유사한 부분."* — `EpochMap` 키 dedup이 처리한다.
- State/Source/`Ref`가 아닌 값 → **error**. `H-40`이 요소 검증을
  화이트리스트로 뒤집은 것과 같은 성격.

### `H-65` — 재바인드는 재설치, 재사용은 **팩토리 패턴** (확정)

- **재바인드**: 위 `H-64`의 한 줄이 그대로 답이다 — `_cleanup`이 없으면
  `Rerun`으로 재설치한다. 죽음을 표시하는 별도 부기를 만들지 않는다
  (**사용자 지적**: *"파괴 클린업은 결국 inst.Destroying 에 이벤트 바인딩인데
  이 바인딩도 파괴 이후 자동 삭제된다 … gchold 나 gcconn 도 알아서 잘 풀린
  상태라, 그냥 가만히 두면 삭제 이후 다시 사용에 있어 다시 실행해줘야한다는
  것 이외엔 아무 문제가 없어요. 즉시 에러를 내려면 뭔가 다른 행동을
  해줘야합니다만. 그걸로 얻는게 있느냐? 에 대해서는 의문입니다."*).
- **재사용/다중 인스턴스는 `Effect` 팩토리를 넘기는 패턴으로 안내한다.**
  검토 중에 `Effect:Clone()` / `Effect<UD>:Userdata()` / `Effect.Template`
  안이 차례로 나왔으나 **전부 기각**됐다 — **사용자 결론**: *"차라리 Effect
  를 만들어내는 팩토리를 넘기는 패턴을 권장해야할듯 해요 … Clone 도,
  Userdata 도, 템플릿도 필요하지 않다."*

  ```lua
  local function TimerEffectFactory(data: { timerSource: Source<...> }): Effect
    return Effect(function(self)
      ...
      return function() ... end
    end, data.timerSource)   -- 주입받은 것을 그대로 deps로도 쓸 수 있다
  end
  ```

  - **왜 이게 더 나은가**(사용자): 초기 1회 실행 문제가 자연히 해결되고,
    템플릿이 실행되어 찌꺼기로 남는 것을 막으려 따로 뭘 할 필요가 없다.
    자식의 계약은 `({...}) -> Effect` 하나이고, 부모가 더 큰 타입을 넘겨도
    **부분 성립**으로 해결된다. 무엇보다 **주입받은 `Source`/`Ref`를 그대로
    `deps`로 넣을 수 있다** — userdata로는 절대 안 되던 것이다
    (*"이건 ud 가 deps 에 대해서는 아무 처리가 못 했던것과 비교해 더
    간단하면서도, 기능적임"*).
  - **이미 있는 관례다** — modifier에서 같은 패턴을 권해왔다.
  - 부수로 *"이팩트를 여러곳에 바인딩하면?"*도 자연히 해결된다(매번 새
    인스턴스).

### 이 묶음에서 **안 만들기로 한 것**

`WeakRef`, `Effect:Clone()`, `Effect<UD>:Userdata()` / `SetUserdata`·
`GetUserdata`, `Effect.Template`. 전부 검토 후 기각 — 위 각 절이 근거의
소스다.

---

## 🅓 "긴 연산의 꼬리가 도중 변경을 덮어쓴다" — `H-85` · `H-101` (+ `H-102`)

### `H-85` — `rawInvalid` 불린을 **캐시 카운터 쌍**으로 교체 (확정)

원문의 갈래 (a)(`rawInvalid = false`를 `fn` 앞으로)는 **불충분하다** —
**사용자 지적**: *"이러면 대신, 캐시가 언제 생성된 캐시인지 모르는 이슈가
발생하지 않아? 특히 에러가 난다고 하면, 다시 계산 안하고 이전 결과를 다시
쓰겠네?"* 그리고 *"state 는 epoch 를 구현해선 안 돼. 중간이지, 초기 값
컨테이너 계층은 아니거든. 따라서 cache count 를 넣을것을 추천해."*

```lua
-- 생성 시
self.cacheTargetCount = 1
self.cacheCurrCount   = 0     -- 달라서 "재계산 필요"

-- 무효화(§4 규칙 1) — 옛 `rawInvalid = true` 자리
if valueChanged then
    self.cacheTargetCount = bit32.bnot(-self.cacheTargetCount)
end

-- 재계산
local gen = self.cacheTargetCount          -- fn 직전 스냅샷
self.cache = self.fn(self, self.cache, ...)
for _, d in self.deps do d:_track(self.valueEpochMap) end
self.cacheCurrCount = gen                  -- ← 성공했을 때만

-- 재계산 판정 — 옛 `rawInvalid == true` 자리
if self.cacheCurrCount ~= self.cacheTargetCount then 재계산 end
```

- **재계산 도중 도착한 무효화**는 `cacheTargetCount`를 앞서게 만들어
  다음 `Get`이 반드시 재계산한다(`H-85` 본체).
- **`fn`이 던지면** `cacheCurrCount`가 안 갱신되므로 계산된 적 없는 캐시를
  유효하다고 확신하는 일이 없다(갈래 (a)가 못 막던 것).
- 증가는 **`bit32.bnot(-n)` 랩** — §2가 `Source.Revision`에 확정한 그 한
  줄을 그대로 쓴다. 비교가 `~=`뿐이라 랩이 무해한 것도 똑같고, uint32 안에
  머무르므로 `+1`이 갖는 2^53 포화 지점 자체가 없다.
- **State는 여전히 `Epoch`를 구현하지 않는다** — 이 카운터는 자기 재계산
  부기이지 남이 키로 삼는 리비전이 아니다(§4가 State dep에 대해
  `TrackFrom(dep.valueEpochMap)`을 쓰는 것과 일관).

### `H-101` + `H-102` — 재진입은 Blocker로 막고, 커서는 `invalidAfter`로 되감는다 (확정)

**먼저 원문의 두 서술을 정정한다.**

1. *"`:List`의 `updateFn`이 `offset`을 인자로 받는 사용자 코드라 거기서
   형제 Slot을 조작"* — **틀렸다**. **사용자 정정**: *"updateFn 자체를
   재실행 하는건 아니거든. offset 을 state 로 넘겨주어서 옵져빙 하게
   만들잖아."* 남는 트리거는 그보다 좁은 것 — `slot.Offset` State를
   **관측하는** 사용자 코드.
2. *"바깥 루프의 남은 `sum`이 낡는다"* — **대체로 틀렸다**. **사용자 정정**:
   *"offset:Set 동작 자체가 무언가를 트리거 한다면, 그게 다 끝난 다음
   돌아옴 … sum 이 더해지는 시점, 그러니까 offset 설정 이후라면, 이미
   length 는 확정값임."* 실제로 재현된 오작동은 길이가 더럽혀진 게 아니라
   **`bk.N`이 자란 것**이었다(`for i = 1, bk.N`의 상한이 진입 시 한 번만
   평가됨).

**확정된 구조**:

- **Blocker 두 개.** 기존 배치 게이팅용(`drive`/`materializeSlotTree`가 켜는
  것)과 **재진입 차단용**을 따로 둔다(**사용자 확정**: *"그냥 blocker
  두개 쓰세요."*). 합치면 배치 `Off()`의 onunblock 순회 도중 같은 Blocker가
  다시 꺼져 핸들이 재귀한다 — `blocker-plan.md`가 네스팅을 의도적으로
  미지원한 것과 충돌.
- **길이 변경 경로는 스킵으로 끝난다.** 바깥 루프가 `offset:Set(i)` **직후**에
  `contribution(i)`를 읽으므로 그 Set이 유발한 자식 길이 변경은 이미
  반영된 값이다 — 다시 도는 건 순수 낭비(사용자: *"안 돌아도 되는데"*).
- **⭐ 구조 변경은 되감는다.** **사용자 판단**: *"정말 앞에서 슬롯이
  당겨졌다고 쳐요. 순차 순회로 처리가 안되는게 … `{a,a,a, b,b, c,c}`
  여기서 a,a 두개가 소멸했는데, 이미 c 에 왔다면, b,b 가 c,c 로 덮여지고
  a,a 는 달라지는게 없을 가능성이 생기죠. 따라서 recompute 도중 변경이
  생긴다면, 변경이 생긴 곳으로 위로 올라가야할것 같습니다. 따라서, 지금
  리컴퓨팅 중인 인덱스를 바꿀 방법을 제공하는게 나아보여요. 그러면 bk.N 에
  대한 문제도 알아서 해결될것 같아보입니다."*
- **되감기 신호는 기존 `bk.invalidAfter` 하나로 통일한다** — 새 필드를 안
  만든다. 두 뜻("캐시가 여기까지 유효"와 "여기 다음부터 다시 해야 함")이
  실제로 같은 것이기 때문. **재개 지점은 `invalidAfter + 1`**이다
  (**사용자 지적**: *"length 가 바뀐 쪽에서, 본인의 offset 은 여전히
  유효하다는거죠."* — `getOffsetAt`의 `for i = bk.invalidAfter, at - 1`과
  같은 읽기). **splice는 `j`가 아니라 `j - 1`로 낮춘다** — 밀린 자리는
  자기 offset도 다시 `Set` 해야 하므로.

```lua
function recompute(bk, ownerKey)
    bk.recomputeBlocker:On()
    local prefix, i, sum = {}, 1, 0
    while i <= (bk.N or 0) do            -- 상한 매 반복 재평가 → N 증가 흡수
        prefix[i] = sum
        bk.offsetCache[i] = base + sum
        bk.invalidAfter = i              -- 여기까지 유효해짐
        bk.offsets[i]:Set(base + sum)    -- ← 사용자 코드가 돌 수 있는 자리
        sum += contribution(bk, i)
        if bk.invalidAfter < i then      -- 누군가 낮췄다 → 되감기
            i = bk.invalidAfter + 1
            sum = prefix[i]
        else
            i += 1
        end
    end
    ownerKey.Length:Set(sum)
    bk.invalidAfter = bk.N or 0
    bk.recomputeBlocker:OffWithoutEmit()
end
```

- **`H-102`가 이걸로 같이 닫힌다.** 원문은 "splice가 observer를 옮겨도
  클로저에 박힌 position 인덱스는 안 고쳐진다"였는데, **사용자 지적**대로
  *"이미 `slot._elemIndex`: realElem → index 를 관리중"*이므로
  `gatedRecompute`는 인덱스를 **캡처하지 않고 조회**한다. 그 역참조를
  **Dispatch 층위로 격상**해 `bk`가 소유한다(사용자: *"그것을 dispatch 로
  격상시키는게 더 나아보이는 지점"*) — splice가 배열을 당길 때 같이
  갱신되므로 `slot-plan.md`의 splice 요구 목록에 항목이 늘지 않는다.
- `bk.invalidAfter = 0`으로 뭉개는 안은 **기각**(사용자: *"0 으로 두면,
  모든 부분에 있어 캐시가 무관해져요"*).
- **참고 — `gatedRecompute`가 왜 게이트 앞에서 `invalidAfter`를 낮추나**:
  recompute가 스킵돼도 `getOffsetAt`의 lazy 접두합 캐시는 무효로 표시돼야
  다음 조회가 다시 계산한다(원문 주석 *"나중 emit도 같은 무효화가 필요"*).
  recompute와는 다른 축이다.

---

## 🅕 `Relate` 되참조 — `H-71` · `H-77`

### `H-71` — dedup 기록을 `SetWeak`으로 낮춘다 (확정)

갈래 (b). dedup은 순수 성능 최적화라(그 절이 스스로 *"correctness 문제는
아님"*이라고 못박음) 엔트리가 조기 소실돼도 "dedup을 한 번 놓친다"까지가
최대 손해다. `v`는 gchold가 이미 강하게 잡고 있고, `relate-plan.md`의
**"다른 곳에서 안전하게 유지되는 것은 항상 `SetWeak`"** 규칙에도 그대로
맞는다. 대상은 `RefLeafHandler.process`와
`ObserverEffectLeafHandler.process`.

**같이 할 것**: `luau-test/done/07`에 되참조 케이스를 **음성 대조군**으로
추가한다 — 지금 그 파일은 "GC-native 아키텍처의 핵심 전제를 검증했다"고
여러 문서에 인용되는데 실제로는 안전한 모양만 봤다.

### `H-77` — `RunInit` 사례는 **기각**, `Relate` 규칙만 명문화 (확정)

**사용자 정정**: *"그런 경우 자체가 날 수 없음 … `initFn` 은 모듈을
**인자로 받음**. 그건 클로저 캡쳐가 아님. 게다가 initFn 자체가 항상 하나야.
그래야지 재진입이 방어되거든. 그 의미는, initFn 자체는 프로토에 불과하다는거임.
게다가, 그 안에서 만들어낸 함수들이 module 을 레퍼런싱 해도, 리턴 값이
quad자신에 flatten 되어 뮤테이션 되어 들어가는 구조 상, 그냥 module.fn
수행하는거랑 다른게 없음."*

- 원문의 재현 코드(`q:RunInit(function() q.tagB = true end)`)는 **성립하는
  사용법이 아니다** — 인라인 클로저는 매번 새 identity라 멱등 가드 자체가
  무의미해진다. 발견이 자기 전제를 깨뜨린 경우.
- `quad-base/src/init.luau`와 `runInitRelate` 설계는 **그대로 둔다**(최상위
  `Relate`, quad 인스턴스가 바깥 키, `initFn`이 내부 키). `:23` 주석도
  그대로.
- **다만 `Relate`의 슬롯별 강/약 규칙 자체는 문서에 없으므로**, `H-71`이
  어차피 다시 쓰기로 한 "위험한 패턴" 절에 **세 슬롯 표**를 넣는다:

  | 슬롯 | `SetStrong` | `SetWeak` |
  |---|---|---|
  | 바깥 키(`inst`) | weak | weak |
  | **내부 키(`key`)** | **강함** | **강함** |
  | 값(`value`) | 강함 | weak |

  지금 그 절은 위험을 **값** 기준으로만 서술해 내부 키 슬롯이 아예
  등장하지 않는다.

---

## 🅖🅗 Store 표면 · 확정 타입 vs 확정 관용구 — 진행 중

### ⛔ `H-73` — **무효**. `<<T>>`는 값 호출부에서 동작한다 (실측으로 뒤집힘)

**사용자 지적**으로 재실측했다 — Luau에는 **generic type instantiation**
문법이 있고(`luau.org/types/generics/#generic-type-instantiation`), 값
호출부에서도, **콜론 메소드에서도** 동작한다.

```lua
--!strict
type Source<T> = { Value: T, Revision: number }
type Store = { GetDynamic: <T>(self: Store, name: string) -> Source<T>, [string]: any }
local store = (nil :: any) :: Store

local ok:   Source<number> = store:GetDynamic<<number>>("x")  -- ✅ 진단 없음
local bad:  Source<string> = store:GetDynamic<<number>>("y")  -- ✅ 정확히 걸림 (진짜 묶임)
local none: Source<number> = store:GetDynamic("z")            -- Source<unknown>
```

원문과 검증 패스는 **인스턴스화를 생략한 호출만** 돌려보고
*"Luau엔 호출부 명시 타입 인자 문법이 없다"*로 단정했다(`ident<number>(1)`이
비교 연산자로 오파싱되는 건 맞지만 `<<>>`는 다른 문법이다). 확정 표기
`store:GetDynamic<<T>>(name): Source<T>`는 **그대로 성립한다**.

**따라서**: (1) `question.md` 최우선 항목은 "타입을 묶을 수 있는가"가 아니라
**원래의 예약 키 축**으로 되돌아온다. (2) `H-74`(eager `defaults` 경로가
`__index`를 우회해 예약 키 방어를 무력화)는 **살아 있다**. (3)
`quad-types-plan.md`의 이중 꺾쇠 관례는 타입 자리 전용이 아니다 — 그
서술도 같이 넓혀야 한다.

### ⭐⭐ Store — `WrapStore` 폐기, **명시적 초기화**, 타입 함수 안 씀 (확정)

> **⚠️ 이 항목은 같은 날 두 번 바뀌었다.** 오전에
> "`store.key`가 값이고 `store:Of(k)`가 프리미티브"라는 재설계를 넣었다가
> **같은 날 철회**했다(감사 4패스가 `store:Names()`의 런타임 구현 불가를
> 잡은 게 발단). 철회된 시도의 원문과 이유 다섯은
> `archive/store-value-field-redesign-withdrawn.md`. 아래는 **최종**이다.

**발단**: 사용자가 `test.luau`로 직접 타입 실험을 돌려, `WrapStore`/
`ProcessStoreType`로 결과 타입을 **합성**하는 접근이 `H-75`/`H-76`의 두
한계에 걸린다는 걸 확인하고 대안을 탐색했다.

**최종 확정 형태** — 타입 함수를 **안 쓴다**:

```lua
type Store<T> = T & {
    Of:    <U>(self: any, name: string) -> Source<U>,   -- 동적 키 전용(옛 GetDynamic)
    Names: (self: any) -> { string },
}

local store = quad.Store<<{
    hp:   Source<number>,
    name: Source<string>,
}>>({
    hp   = Source(100),
    name = Source(""),
})

store.hp:Get()                          -- 평범한 레코드 필드 접근
store.hp:Set(5)
store.hp:Compute(function(s) ... end)   -- 콜백 파라미터 추론 살아있음
store:Of<<boolean>>("dynamicName")      -- 동적 키
```

- **타입 인자에 `Source<T>`를 직접 쓴다** — `store.key`가 평범한 레코드
  필드라 타입 함수가 하나도 안 들고, 읽기/쓰기 의미론이 `Source`의 기존
  계약 그대로다. **사용자 지적**: *"왜 우리가 `Source()` 를 직접 넣는걸
  거부하고, 이렇게 까지 하려 했죠? 단순히, `Store<{ a: Source }>` 로 두고,
  `store.a:Set,Get` 하지 말아야할 이유가 있을까요?"*
- **⭐ 명시적 초기화** — 옛 lazy `__index`(없는 키를 그 자리에서 만들어
  저장) **폐기**. 그래서 `defaults`가 곧 선언 키 집합이 되고
  **`store:Names()`가 성립한다**(`H-79`). 부모가 값을 다 안 넘겨도 되게
  하려면 컴포넌트가 자기 `DEFAULTS`로 채워 넘긴다.
- **`store.key = value`는 폐기 유지** — 2026-08-06 결정 그대로.
  오전 재설계에서 되살렸다가 같이 철회했다. **사용자 지적**이 그 논거를
  실측해줬다: *"`.Value = 1` 이 정적 쓰기처럼 보일텐데, 여기서 error
  터지는 trace 가 나오면 당황스럽기도 하고요, 약간 마법적 동작이기도
  해요."*
- **동적 키는 `store:Of<<T>>(name)` 하나** — 옛 `GetDynamic`을 흡수했다
  (표면 둘을 유지할 이유가 없다).
- **예약 키는 `Of`/`Names` 둘뿐**이고, 충돌하면 타입 검사가 **조용히
  꺼진다**(실측). `CheckReserved` 타입 함수가 **진단만** 띄운다 —
  `error()`가 아니라 `print(...)` + `return types.never`.
- **⭐ 여기서 원칙 하나가 나왔다** — *"타입 함수는 타입이 못 잡는 문제를
  **에러로 띄우는** 정도 이상으로 가지 않는다"*(사용자). `index<>`/`keyof<>`도
  Luau가 predefine한 타입 함수라 같은 함정을 갖는다는 지적이 근거다.
  `base/typing-limits.md` §0으로 승격.
- **`Compute`/`Apply`의 반환 타입은 여전히 명시 주석이 필요하다** — Store와
  무관한 §1의 문제 B이고 어느 모양에서든 조용히 unsound다(실측: 틀린
  주석이 `store.hp`든 독립 `Source`든 양쪽 다 안 걸림). 살아나는 건
  **콜백 파라미터** 쪽이고, 철회된 `Self` 제네릭을 거치면 그것마저 깨졌다.

실측 전량은 `audit/type-store-index-keyof/`(측정값은 유효, 결론만 철회됨).

### ⛔ `H-75` · `H-76` — **무효**. `WrapStore`/`ProcessStoreType`이 폐기된다

두 발견은 전부 *"정본 `Source<T>` 선언을 `type function` 안에서 어떻게
합성하는가"*에 대한 것인데, 위 재설계로 **합성 자체를 안 한다**. 남는 타입
함수는 `CheckReserved` 하나뿐이고 그건 `T`를 **검증만 하고 그대로 통과**
시키므로 (a) 바깥 별칭을 반환할 일이 없고(`H-76`의 근거), (b) 메소드 self
파라미터 불변성 문제도 없고(`H-76`), (c) ②쪼개기를 `type function` 안에서
할 일도 없다(`H-75`). `typing-limits.md` §5의 *"✅ 검증 완료"* 서술과
`store-plan.md`의 `WrapStore` 스케치는 **삭제 대상**이다.

### ⛔ `H-74` — **무효** (근거는 lazy `__index` 폐기)

원문은 *"eager `defaults` 경로가 `__index`를 통째로 우회하므로 '고정 메소드
테이블을 먼저 확인'이라는 예약 키 방어가 성립하지 않는다"*였다. **명시적
초기화가 확정되며 lazy `__index` 폴백 자체가 없어졌다** — 우회할 방어가
아예 없으므로 발견이 소멸한다. 지금 예약 키(`Of`/`Names`) 방어는
`__index`가 아니라 **타입 레벨 `CheckReserved`**가 한다.
**[2026-08-25 문구 정정]** 한때 여기 근거로 "그림자 백킹 테이블"을 들었는데,
그건 같은 날 철회된 재설계의 산물이다
(`archive/store-value-field-redesign-withdrawn.md`). 판정(무효)은 안 바뀐다.

### `H-83` — `table.clone(defaults or {})` (확정)

한 글자. **명시적 초기화와 모순되지 않는다** — 선언된 키가 하나도 없는
`Store<<{}>>()`는 여전히 유효하고(줄 키가 없으니 넘길 것도 없다), 그때
`table.clone(nil)`이 `table expected, got nil`로 죽는 걸 막는다.
"선언한 키는 값을 준다"와 "키가 0개면 인자도 없다"는 서로 다른 층위다.

### `H-79` — `store:Names()` 신설 (확정)

갈래 (c). `Tag:Names()`/`attr:NameMap()`과 같은 계열이고, 동적 키 표면
(`store:Of<<T>>(name)`)과 **같은 자리**에 둔다(사용자: *"이것도 GetDynamic
처럼 둡니다"* — 그 `GetDynamic`이 지금의 `Of`다). 그룹 `Attribute`가
요구하던 열거가 이걸로 닫힌다.

**시그니처는 `Names: (self: any) -> { string }`이다.** **[2026-08-25 문구
정정]** 한때 여기 `{ keyof<index<Self,"__store">> }`라 적었는데 그건 같은 날
철회된 재설계의 타입이다. **런타임 성립 근거도 바뀌었다** — 팬텀 필드가
아니라 **명시적 초기화**다: `defaults`가 곧 선언 키 집합이므로 그림자
테이블의 키를 그대로 준다. (감사 4패스가 잡은 것 — 철회 전 모양에선
Luau가 타입 인자를 런타임에 지워 `Names()`가 **구현 불가능**했다.)

### `H-95` — 두 콜백 시그니처를 실측 통과 형태로 고친다 (확정)

갈래 (a).

- **`Effect`의 `fn`** — 가변 반환 팩 `-> ...(() -> ())`. 단일 옵셔널
  반환에 맞고, `function(self) end`와 cleanup 반환이 둘 다 통과한다.
- **`:List`의 `updateFn`** — 함수 타입의 유니온 `Fn2 | Fn1 | Fn0`. 네 모양
  (2개/1개/nil/없음)이 전부 통과하고 **엉뚱한 타입은 여전히 잡힌다**(음성
  대조군 확인).

"항상 명시적으로 반환하라"를 계약으로 두는 안은 기각 — `useEffect` 동형이라는
확정 서술과 인체공학이 어긋나고, `--!nocheck` 코드에선 조용히 지나간다.

### `H-94` — `__call`이 아니라 **지정된 필드**로 받는다 (확정, 필드 이름 미정)

**사용자 판단**: *"그런데 이러면, Blocker 자체도 처음에 슈거로 두지 못했었던
이유가 해결됩니다. 아에 어플리케이티브 펑터로써, `__call` 이 아닌 다른
필드로 들어가는게 맞아보여요. 외부에서 직접 `()` 호출하는건 의미 없게
둬야해요."*

- 원문의 갈래 (a)(함수와 콜러블의 유니온)는 **기각** — 유니온도 캐스트도
  필요 없어진다.
- `:Apply`는 "함수" 또는 "그 필드를 가진 객체"를 받고, `Debounce{...}` /
  `Throttle{...}` / `Blocker`가 전부 같은 계약을 만족한다.
- **실측 뒷받침**: `test.luau`가 `__call` 경로가 죽었음을 확인했다 — 타입
  레벨 `__call`은 `self`를 못 받고(`mock()`이 인자만 남는다),
  `typeof(getter2<<T>>)`로 `T`를 넘기는 것도 실패한다.
- **남은 것**: 그 필드의 이름과 정확한 시그니처(구현 시 정하면 됨).

---

## 🅒 예외 안전성 — `H-88` · `H-89` · `H-87` · `H-103`

### 네 자리 전부 **UB로 명문화**, `pcall`로 감싸지 않는다 (확정)

2026-08-21에 `slot-plan.md`의 `materializeSlotTree`에 대해 내린 판단
(*"마운트 도중 예외는 quad가 복구를 보장하지 않는 상태이고 … 아직 실제로
밟은 적 없는 경로다 — `conventions.md`의 "드문 오용이나 가상의 미래
요구까지" 절이 세운 원칙 그대로. 실제로 물리면 그때 넣는다"*)를 **전
자리로 확장**한다. 🅔의 `Rerun`에 대해 같은 원칙을 이미 확정했다
(*"에러가 난 이후 데이터의 무결이 깨져도 별 책임 안 진다는 quad의 일반
동작"*).

- 전파 루프(`H-88`, 구독자당 hot path), 게이트 flush + `Blocker:Off()`
  순회(`H-89`), 배치 게이팅(`H-87`), Dispatch 체인 슬롯(`H-103`, 자리당
  hot path) — 넷 다 감싸지 않는다.
- **문서에 없던 것을 적는 게 이 항목의 산출물**이다 — 지금
  `state-epoch-plan.md`/`gate-plan.md`/`blocker-plan.md` 셋엔 `error`라는
  단어가 **0건**이다. yield 금지와 같은 톤으로 "예외가 나면 그 파동/그
  자리의 부기는 복구되지 않는다"를 명시한다.
- **`H-87`의 심각도 정정**: 🔴 → 🟡. 원문의 *"코퍼스가 error 경로를 어느
  쪽도 다루지 않는다"*는 거짓이었다(위 선례가 있다). 새 결함 보고가 아니라
  **기존 판단의 적용 범위** 문제였다.
- **`H-88`의 부정 주장 정정**: *"예외 안전성 계약이 코퍼스에 한 줄도
  없다"*는 과했다 — 위 선례가 유일한 선례이고, 그 선례가 고른 방향이 바로
  지금 채택한 쪽이다.

### `H-89`의 나머지 — `:Sync(batch)`는 **전파 전** (확정, 물을 것 없음)

`gate-plan.md` 4번이 *"실제로 전파할 때"*라고만 하고 앞/뒤를 안 정했는데,
참조 구현의 `GateNode:_flush`가 이미 **빈 배치 얼리리턴 → 스왑 → `Sync` →
전파** 순서이고 그게 4·8번과 일치한다. 그 순서를 문서에 명시한다.

---

## 🅙 error 계약 — `H-104` · `H-105`

**⚠️ 두 항목의 수치를 먼저 고칠 것** — 원문의 "42곳"은 산문 언급까지 센
것이다. 실제 quad 자신의 error 코드 자리는 **약 29곳**, 한국어는 17이
아니라 **약 23**, 영어는 6(동적 경로 가드 4형제 + 모듈 초기화 + attribute
이름 충돌)이 맞다.

### `H-104` — 사용자 입력 검증은 `level 2`, 내부 불변식은 `level 1` (확정)

```lua
error("Effect: dep #3 is not a State/Source/Ref", 2)   -- 호출부를 가리킴
error("Dispatch: bookkeeping is broken (bk.N=" .. n .. ")", 1)  -- 그 자리를 가리킴
```

*즉시 error*가 quad의 주 방어선인데 지금은 전부 quad 내부 줄을 가리켜
사용자가 자기 코드 어디서 틀렸는지를 못 본다. 이분은 명확하다 — 사용자가
잘못 넘긴 것(deps 타입, 이중 바인드, 예약 키…)은 호출부를, quad 자신의
부기가 깨진 것은 그 자리를 가리킨다. **29곳을 쓰기 전에 정해야 한 번에
맞는다.**

### `H-105` — error 메시지는 **영어로 통일** (확정)

**사용자 확정**. `conventions.md`의 *"사용자가 보게 될 것은 한국어"*는
**이 프로젝트의 대화·문서** 규칙이고 quad 라이브러리 사용자에게까지
적용된다고 정해진 적이 없다 — 이번에 정한다. 이미 영어인 6곳(동적 경로
가드 4형제 등)이 핵심 경로라는 점도 같은 방향이다. 기존 한국어 메시지
약 23곳은 구현 시 영어로 쓴다(문서의 예시 메시지도 같이).

---

## 그 밖의 개별 확정

### `H-68` — `Source:Set(v)`는 **동일값이어도 항상 갱신하고 emit** (확정)

판정이 값 동등성이 아니라 리비전이라는 `Epoch` 모델과 일관된다. 더
중요한 건 **테이블 값**이다 — mutate한 뒤 같은 테이블을 다시 `Set`하는
것이 `==`로 dedup되면 변경이 조용히 증발한다. dedup은 이미 하류
(`EpochMap`, 게이트)에서 한다.

---

## 🅚 ⭐ "중간 State GC" 미해결이 **닫혔다** — `H-93` · `H-98`

**사용자 확정**: *"단순히, 각 state 들이 상위 State|Source 를 홀드하는
`_hold` 를 놓는것으로 바로 해결된다. 당연히 후행은 선행 요소들이
있어야하기 때문. 선행 state 가 후행 state 를 얻으려 하는건 UB이므로 가능한
일이다.(이건 릴레이션도 아니라 gc되긴 하지만.)"*

불변식이 이걸로 명문화된다:

| 방향 | 강도 |
|---|---|
| 하류 State → 상류 State/Source (`_hold`) | **강함** |
| 상류 → 하류 (구독자 집합) | weak-키 (🅑-1에서 확정) |

- 체인은 **말단(Observer/Effect/leaf)이 살아 있는 동안** 통째로 살아 있고,
  말단이 죽으면 통째로 수거된다. `Relate`가 아니므로 순환도 안 만든다.
- **`H-93` 소멸** — 루트 `Epoch`(Source)가 하류보다 먼저 수거될 수 없으므로
  *"`:Refresh()`가 `false`를 줘 낡은 값을 최신이라고 확신한다"*는 경로가
  생기지 않는다.
- **`H-98` 소멸** — `source-state-plan.md`의 두 문장(*"참조를 아무 데도 안
  담아도 정상"*, *"GC되지 않고 영원히 계속 실행됨"*)이 서로 모순 없이
  성립한다. `:Subscribe()`가 전역 강 레지스트리에 핸들을 넣고, 핸들이
  `_hold`로 상류를 잡는다.
- **🅑-2(eager 등록)의 캐비엇도 해소** — 그 절에 적어둔 *"eager이므로 중간
  State GC 미해결이 더 절실해진다"*는 이제 해당 없음.
- **`question.md` 최우선 절의 첫 항목이 닫힌다**(실측 스파이크는 여전히
  `luau-test`에 하나 두는 게 좋다 — 그 파일은 "상류 strong / 하류 weak
  불변식"을 음성 대조군까지 확인하는 형태로).

---

## 🅛 저장소·로드맵 — `H-78` · `H-97` · `H-80` · `H-81` · `H-99`

### ⭐ `H-78` — 근본 원인은 **`luau` CLI가 심볼릭 링크를 못 탄다**는 것 (확정)

원문은 *"안 돈다"*까지만 짚었는데, 이번에 최소 재현으로 원인을 특정했다:

```
require("./real")     → OK      (진짜 디렉토리 + init.luau)
require("./linked")   → 실패    (같은 디렉토리를 가리키는 심볼릭 링크)
                        could not resolve child component "linked"
진짜 디렉토리 + init.luau 파일 심볼릭 → 실패 (no module present at resolved path)
파일 심볼릭 직접 require            → 실패
```

pesde의 워크스페이스 링크가 전부 디렉토리 심볼릭
(`.pesde/…/quad_types/src -> quad-types/src`)이라, `quad-base/src/init.luau`의
`require("./roblox_packages/quad_types")`가 그 링크에 닿는 순간 죽는다.
`luau` 0.735(현재 최신)에 관련 옵션도 없다.

**거짓 클린도 재현했다** — 같은 경로를 `luau-analyze`에 걸면 진단이 lint
둘뿐이고 `local x: number = m.ok`(실제 `boolean`)를 **안 잡는다**. 모듈을
`any`로 떨어뜨리고 조용히 통과한다.

**해법(확정)**: **개발용 리링크 스크립트** — `.pesde` 아래 디렉토리
심볼릭을 실제 복사로 교체하고, 테스트/분석 스크립트가 그걸 먼저 돌린다.
pesde 설정도 게시 경로도 안 건드린다. 워크스페이스 멤버를 고치면 다시
돌려야 하므로 테스트 스크립트가 매번 선행 실행한다.

**같이 고칠 것**: `ROADMAP.md:198`의 *"전부 PASS"* — 날짜도 전제조건도 없다.
지금 실제로는 `smoke.mock`만 PASS이고 `smoke.init`/`smoke.plugin`은 리링크
없이는 안 돈다. 스파이크 `23`도 같은 이유로 의도한 음성 대조군이 안 뜬다
(`luau-test/STATUS.md`에 반영).

### `H-97` — mock에 생명주기 4종을 M2에서 최소 구현 (확정)

`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`를 mock 백엔드용으로
가장 단순하게 구현한다(커밋된 mock에 signal/Connection이 이미 있다).
M2의 핵심이 전파 루프인데 그걸 한 번도 안 돌려보고 M3로 넘어가는 것이
이번 라운드가 찾은 종류의 결함을 그대로 낳는다.

### `H-80` · `H-81` · `H-99` — 체크박스·소스 트리 갱신 (결정 불필요)

- `H-80`: `ROADMAP.md` M2의 `Quad` 추가 목록이 `Source`/`State`/`Store`뿐 —
  `Effect`/`is*` 전량/`bindLifetime` 4종/`Blocker`/`Relate`를 더한다.
  `State`는 런타임 생성자가 없다는 것도 명시(파생으로만 생긴다).
- `H-81`: `isModifier` 런타임 가드 체크박스가 M7에만 있다 — 적용 지점이
  전부 M2 파일(`Source:Set`/Store 생성/`:Compute` 캐싱)이므로 M2
  체크리스트에 넣고, `modifier-plan.md` 7번과 `source-state-plan.md`의
  적용 지점 목록을 일치시킨다(독립 `Source(someModifier)`가 한쪽에만 있다).
- `H-99`: `architecture.md` 소스 트리에 `Observer.luau` 자리와
  `:Subscribe()` 전역 레지스트리의 소유 모듈을 명시(`EpochMap.luau`가
  *"`State.luau`에 묻지 않고 별도 모듈"*로 명시된 것과 대비를 맞춘다).

---

## 🅜 문서 정합 — 결정 불필요 (`H-66` · `H-67` · `H-82` · `H-91`)

- `H-66`: `typing-limits.md` 영향 범위 표의 `state:Observer(fn)` 행을
  `EffectHandle 반환` → **`Observer` 반환**.
- `H-67`: `gate-plan.md` 4번이 `OffWithoutEmit` 비우기의 근거로 드는 용례가
  gated state를 안 쓴다 — gated state를 쓰는 용례로 교체.
- `H-82`: `:With`를 실노드로 확정한 근거 2번("`w`의 캐시를 c1/c2가 공유")이
  pass-through 노드엔 성립하지 않는다 — **"엣지 수와 에포크 부기"**로 교체.
  결론은 안 바뀐다(근거 1·3이 유효).
- `H-91`: `state-epoch-plan.md` §8의 *"항상 state 는 get 이 최신"*을
  **"선언한 의존성에 대해서는 항상 최신"**으로 좁히고, `Animate`가 미선언
  읽기를 **설계로** 쓰는 의도적 예외임을 가리킨다.

---

## 나머지 개별 — 구현 시 정하면 되는 것

- **`H-69`** 통과 모드 게이트가 emit마다 weak 테이블을 하나씩 할당 —
  정확성 문제 아님. 전파 루프를 코드로 쓸 때(🅑) 같은 자리에서 정한다.
- **`H-92`** 구독자 스냅샷이 emit마다·노드마다 배열 하나를 할당 —
  `state-epoch-plan.md` §2가 테이블 리비전을 기각한 GC 근거, §7 비용 절과
  어긋난다. 정확성 문제 아님, **서술만 실제와 맞춘다**.
- **`H-84`** `:With(...)`/`state:Block(b)`/`Source:Emit()`이 `ROADMAP.md` M2
  체크리스트에 개별 항목으로 없다 — 추가.
- **`H-96`** trailing deps가 붙으면 콜백 파라미터 무주석 추론이 깨진다 —
  결정이 아니라 **`typing-limits.md` §7에 경계 한 줄**(*"단 trailing deps가
  붙으면 dep 파라미터엔 주석이 필요하다"*).
- **`H-100`** `{[Source<T>]: true}`가 `{[Epoch]: true}` 자리에 안 들어간다
  (인덱서 키 불변) — `EpochSet` 리터럴에 캐스트가 필요하다는 것만 적는다.
- **`H-106`** `getOffsetAt`의 `contribution(bk, i)`에 `nil` 가드가 없어
  `C-6`이 승격한 진단이 우회된다 — 한 줄 가드 추가.

---

## 반영 후 검증 — `/code-review high` 1회 + 감사 다패스 (2026-08-25)

`base/` 반영이 끝난 뒤 **각도를 바꿔가며** 검증을 돌렸다. 사용자 지침:
*"여러 각으로 넣으면 다양한 문제들이 해결되거든"*, *"수렴 되기 까지 여러
각으로 한번씩 넣어봐줘. 그게 stale 부채를 막는 길이라서."*

**각 패스가 낸 발견이 서로 거의 안 겹쳤다** — 이게 이 절을 남기는 이유다.
다음에 큰 반영을 할 때도 한 각도로 여러 번이 아니라 **각도를 바꿔가며**
돌릴 것.

| 패스 | 각도 | 발견 | 대표적으로 잡은 것 |
|---|---|---|---|
| `/code-review high` | diff 자체의 결함(사용자만 호출 가능) | 12 | 캐시 카운터 시드 충돌(갱신이 **감소**라 첫 무효화에서 두 값이 같아짐), `_cleanup == nil`로 "설치됨"을 판정해 `H-58` 부활, 되감기 `+1`이 바뀐 길이를 `sum`에서 누락, `bk.indexOf(len)`가 길이 값을 키로 써서 두 자리가 접힘, `relink.sh` 재실행 no-op |
| 감사 1차 | diff 정합성 — 폐기된 이름·인덱스 레이어·색인 행 | 12 | **`ROADMAP.md` M2 전파 루프 체크리스트가 `H-56`이 뒤집은 것을 그대로 들고 있었다**(구현자가 보는 자리), `CLAUDE.md`/`project-context.md`가 닫힌 게이트를 열린 것으로 서술(매 세션 로드됨) |
| 감사 2차 | **새 의사코드를 손으로 실행** | 6 | `lifecycle-pattern.md`의 `bindLifetime`이 폐기된 `_observers` cascade를 **정본 의사코드로** 들고 있었다, `ref-plan.md`가 같은 파일 안에서 `:Uncallback`과 `:WeakCallback` 두 계약을 동시 주장, gate flush 스니펫이 4단계 중 2단계만 |
| 감사 3차 | **소비자 관점**(M2 표면을 쓰는 쪽) | 6 | **Store 재설계가 소비자 예시 12개 파일에 전혀 안 퍼짐** — 특히 `component-composition-plan.md` §3이 배너 없이 옛 모델을 "확정"으로 서술 |
| 감사 4차 | **구현자 관점**(M2를 위에서부터 짜 내려간다면) | 4 | **`store:Names()`가 런타임에 구현 불가능**(Luau가 타입 인자를 지움) — 이게 오전 Store 재설계를 **철회**하게 만든 발단이다. 그 외 `Effect`↔`Blocker` 체크박스 순서, `Observer.luau` 파일명 누락, `GateNode` 조립 의사코드 부재 |
| 감사 5차 | **철회가 완전한가** | 13 | **`architecture.md`를 철회에서 통째로 놓쳤다**(두 자리, 그중 하나는 같은 파일 안에서 모순), `source-state-plan.md`가 한 파일 안에서 대입 부활/폐기를 동시 주장, `GetDynamic`→`Of` 개명이 5곳 누락(**`ROADMAP` 체크박스 제목 포함**), `pre-implementation-audit.md`의 **"이미 고침" 목록**이 철회된 고침을 완료로 기록 |
| 감사 6차 | **최종형 수렴 + `H-74`/`H-79`/`H-83` 재판정** | 3 | `effect-plan.md`가 **같은 문서 안에서** 폐기된 `_installing`을 "확정"으로 서술, `README.md`의 `effect-plan` 색인 행이 하루 전 상태, followup의 `H-74`/`H-79` 판정 문구가 철회된 모델을 근거로 인용. **`base/`는 전부 최종형으로 일관** — 잔재가 인덱스·기록 레이어에만 남았다 |

**교훈 둘** — (1) **각도를 바꾸면 계속 나온다.** 여섯 패스가 12/12/6/6/4/13/3건을
냈고 겹치는 게 거의 없었다. 한 각도로 여러 번 돌리는 것보다 각도를 바꾸는
쪽이 압도적으로 낫다. (2) **하루 안에 두 번 바뀐 것은 인덱스·기록 레이어에
잔재가 남는다.** 6차에서 `base/`는 이미 깨끗했는데 `README.md` 색인 행과
followup 판정 문구가 중간형을 들고 있었다 — "결정을 적는 곳"과 "결정을
가리키는 곳"이 다르기 때문이다.

**교훈 셋** — 같은 결정을 **여러 문서가 각기 다른 역할로** 들고 있으면
한 곳만 고치기 쉽다. `H-56`(전파 루프)은 `lifecycle-pattern.md`(산문) /
`source-state-plan.md`(의사코드) / `ROADMAP.md`(구현 체크리스트) 셋에
흩어져 있었고, 첫 반영은 앞의 둘만 고쳤다 — **구현자가 실제로 보는 건
세 번째**다.
