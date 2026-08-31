# Effect — 설치 + 확정 정리, `state` 있으면 Observer를 감싸 재실행도 지원

**상태**: base — `research/additional-primitives-plan.md`(다른 프레임워크
대비 갭 분석)에서 갈라져 나온 확정 프리미티브. `base/blocker-plan.md`(같은
조사에서 나온 다른 확정 프리미티브)와는 서로 무관 — Store/State 작업이나
Ref/PreRef와 파생 관계는 아니라 별도 파일로 둔다(2026-08-07 문서 정리에서
한 파일로 합쳤던 걸 다시 분리). 단 `state` 인자를 받는 형태는 내부적으로
Observer를 조합해서 만들어짐(아래 참고, 2026-08-07 여섯 번째 세션 확정) —
"Observer와 무관한 완전 독립 프리미티브"였던 이전 서술은 정정됨.

**Effect와 Observer의 관계 확정(2026-08-07 여섯 번째 세션)**: 별개의
독립 프리미티브이되, `state`를 받는 형태의 Effect는 내부적으로 Observer를
**조합(compose)**해서 만들어짐 — Ref/PreRef처럼 브랜드 태그만 다른 재사용이
아니라, Observer(재실행 신호) 위에 자동 cleanup 배선을 얹은 한 단계 위
계층. **자유 함수인 이유는 여전히 유효**: `state` 없이도 성립하는
mount/unmount 전용 유스케이스가 있고, 실제 leaf 생명주기 바인딩은 (Observer와
마찬가지로) children 배열 위치에 거는 것이라 `state`가 그 바인딩을 소유하지
않음 — Roblox엔 `task.spawn`으로 코루틴에 반복문/타이머를 돌리는 패턴이
흔하고, Luau 테이블엔 `__gc` 같은 GC 시점 훅이 없어서 "이게 진짜 사라지는
순간"을 아는 유일한 방법은 `Instance.Destroying`류 명시적 신호뿐 — 이런
케이스(타이머 시작 → leaf가 죽을 때 반드시 정지)를 위한 별도 primitive로
합의됨.

```
Effect(fn, ...deps) -> EffectHandle
```
**[2026-08-21 5라운드 `C-6`]** 옛 시그니처는 `Effect(fn, state?)`(의존성 하나)였다 —
아래 "`Effect(fn, ...deps)`" 절이 소스.

**`state` 생략 시**: `fn()`을 즉시 1회 실행, 리턴값(`nil | () -> ()`)은
이 Effect가 바인드된 leaf가 죽을 때 정확히 1회 호출. 재실행 없음
(mount/unmount 전용, React `useEffect(fn, [])`와 동형).

**dep 지정 시(2026-08-07 여섯 번째 세션 확정, 2026-08-21 `C-6`으로 N-deps 확장)**:
Effect는 내부적으로 각 dep에 구독을 거는 걸로 구현 — State/Source면
`state:Observer(...)`, `Ref`면 `:Callback`.
**⚠️ [표기 정정, 2026-08-24 6라운드 `H-14`] 여기 원래 *"`fn`은 포지셔널 인자로
`state`를 받고(`fn(state)`)"*라고 적혀 있었는데 그건 폐기된 단수 시절
표기다** — 확정 시그니처는 **`fn(self: EffectHandle) -> ...(() -> ())`**이고
(**[2026-08-25 `H-95`]** 가변 반환 팩 — 옛 `-> (() -> ())?`는 콜백이 "선언보다
적게 반환"할 때 strict에서 막혀 `Effect(function() print("x") end, s)` 같은
정상 용례가 안 통과했다)
**deps는 `fn`에 안 넘어간다**(아래 "`Effect(fn, ...deps)`" 절이 소스,
dep 값은 사용자가 클로저로 직접 읽는다).
같이 붙어 있던 *"이 `fn(state)`가 lazy `State` 핸들을 받는다는 전제는 확정
유지"*(2026-08-13 13차 세션)도 그 표기에 묶인 서술이라 함께 폐기된다 —
다만 그 항목이 실제로 확인한 것(**`Effect`는 재귀 제네릭 타입 누수와
애초에 무관**하다, 자유 함수라 "재귀 타입의 필드 + 로컬 제네릭" 조건에 안
걸림 — `base/typing-limits.md` 1번의 영향 범위 표)은 시그니처와 무관하게
그대로 유효하다.
Observer가 이제 등록 즉시 1회 실행되므로(아래 Observer 절 참고) 그 첫
실행이 "설치"를 겸함. 이후 `state`가 무효화될 때마다 **직전 `fn` 호출이
리턴한 cleanup을 먼저 호출한 뒤 `fn`을 재호출**, 그리고 Effect가 바인드된
leaf가 죽을 때 **마지막 cleanup을 한 번 더 호출**. 결과적으로 React
`useEffect(fn, [dep])`와 동형(설치+재실행 사이/최종 cleanup 전부 같은
반환 계약 하나로 처리).

- **🔄 [역전됨, 2026-08-21 구현 전 QA 5라운드 `C-6`] "다수 의존성은 `:With`로
  묶어서 넘길 것 / trailing args sugar는 안 만듦"(2026-08-11 세션) — 뒤집혔다.**
  지금은 `Effect(fn, ...deps)`가 의존성을 **여러 개 직접 받고 각각에 구독을
  건다**(아래 "`Effect(fn, ...deps)`" 절이 소스). 옛 근거("의존성이 둘 이상이면
  합칠 새 노드가 실제로 필요하니 그 비용을 sugar로 감추지 말자")가 무너진
  이유는 둘 — (1) **`Ref`는 State가 아니라 `:With`로 합칠 수가 없어서**, 그
  모델에선 `Ref`가 Effect의 의존성이 될 방법이 **아예 없었다**(실제 갭),
  (2) 각 의존성에 구독을 따로 걸면 **합치는 노드 자체가 안 생긴다** — 감출
  비용이 애초에 없다. 옛 서술이 인용하던
  `source-state-plan.md`의 "`:Compute(fn, ...)`" 선례는 이제 **따르는 쪽**의
  근거가 됐다(인자 모양을 그 관용구 그대로 맞춤).
- **`fn`은 커링 스타일도 권장(2026-08-07 여섯 번째 세션, 사용자 제안)** —
  `Effect(makeLogger("mount"), state)`처럼 팩토리 함수가 실제 `fn`을
  만들어 반환하는 패턴(**[2026-08-24 표기 정정]** 그 `fn`은 `fn(state)`가
  아니라 `fn(self)`다 — 위 배너), `Modifier`의 `Boldify(10)` 커링 관용구(`modifier-plan.md`
  8번)와 같은 결. `state:Observer(fn)`도 동일하게 커링 스타일을 권장 대상으로
  같이 문서화(아래 Observer 절 참고) — 모듈화가 필요하면 둘 다 이 패턴을 쓸 것.
- **재실행이 필요 없는 케이스와 혼동하지 말 것**: 값 변화와 무관하게 설치+최종
  정리만 필요하면 `state` 없이 `Effect(fn)`을 씀 — `state`를 굳이 넘겨서
  재실행을 유발할 필요 없음.

children 배열에 leaf로 놓는 기존 Observer 바인딩 패턴을 그대로 재사용(그
leaf가 살아있는 동안만 유효, leaf가 죽으면 최종 정리 콜백 호출). 비용은
leaf당 실제 Destroying 바인딩 하나(공유 weak table로 되는 Observer보다
비쌈) — 필요할 때만 쓰는 걸로 충분.

### ⭐⭐ 그 `Destroying` 바인딩을 **누가 거는가** (2026-08-24 확정, 6라운드 손 트레이싱 `H-11`)

**갭이 실재했다 — cleanup을 발화시키는 코드가 코퍼스 어디에도 없었다.**
세 문서가 `Destroying`을 **전제로만** 쓰고 아무도 연결하지 않았다:
`base/lifecycle-pattern.md`는 *"인스턴스 라이프사이클 훅 지점은 `Destroying`
하나로 통일"*이라 못박고 `LP-2`가 **`Effect`가 그 훅을 쓰는 유일한 소비자**라
확정했으며, 위 문단은 비용까지 적어뒀다. 그런데 leaf가 실제로 붙는 유일한
경로는 `ObserverEffectLeafHandler.process`의 `bindLifetime(inst, v)` 한 줄이고,
`bindLifetime`의 실 구현 스케치는 `gchold[value] = true` + `BindData`에
gcconn/gchold 복사가 전부다 — **`Destroying`도, cleanup 저장도, 그걸 부를
주체도 없었다.** 그래서 leaf가 죽으면 `canExecute`가 거짓이 되어 *"앞으로
발화하지 마라"*는 성립하지만 **cleanup은 영원히 안 불린다.**

**파급이 국소적이지 않았다** — 이 한 줄이 없으면 `slot._detachCleanup`
(`Detach`로 홀드된 요소를 파괴하는 **유일한** 경로,
`base/slot-plan.md`가 *"GC 폴백이 아예 없으므로 명시적 정리 경로가 필수"*라고
적어둔 그것)과 `OnDestroyed`(`base/lifecycle-hooks-plan.md`, `Effect` 위의 순수
슈가라 통째로 무동작)가 같이 죽는다.

**확정(사용자, 2026-08-24)**:

1. **`bindLifetime`/`unbindLifetime`이 `isEffect(value)`를 보고 직접 처리한다.**
   **[2026-08-24 재결정, `/code-review high` 지적]** 여기 한때 *"`EffectHandle`
   쪽이 자기 `bindLifetime` 직후에 건다"*고 적었는데 **그 호출부가 실재하지
   않는다** — 핸들은 남이 자기를 `bindLifetime`하는 걸 관측할 수 없다. 게다가
   `Effect`가 바인드되는 경로는 **둘**이고(`ObserverEffectLeafHandler.process`의
   children 배열 leaf, 그리고 `activateList`가 `_detachCleanup`을 직접 바인드하는
   내부 경로 — `base/slot-plan.md`) **`Destroying`이 가장 절실한 쪽이 후자**라,
   핸들러 층에 분기를 둬도 안 덮인다.
   **사용자 판단(2026-08-24)**: *"`Destroying` 자체가 엔진이 아는 요소이기
   때문에, 엔진이 처리하는 곳에 두긴 해야합니다. 옵져버는 바로 생성되기 때문에,
   bind 상 옵져버 목록을 가져와 자신이 재귀하고, `bindLifetime` 이 처리하는게
   나아보입니다."* — `bindLifetime`은 이미 값 종류를 들여다보는 자리이므로,
   그 옆에 `Destroying` 배선을 두는 게 새 층을 만드는 것보다 낫다.
   > **⚠️⚠️ [2026-08-26 정정, `/code-review high`] 이 항목이 근거로 들던
   > *"`bindLifetime`은 이미 핸들의 내부 Observer로 cascade한다"*는 **거짓이다.**
   > `H-58`(2026-08-25)이 그 cascade를 폐기했다 —
   > `base/lifecycle-pattern.md`의 `bindLifetime` 의사코드가 *"내부 Observer로
   > **cascade하지 않는다**"*고 명시하고, 그대로 두면 **바인드마다 `Rerun`이
   > 도는 `H-58`이 되살아난다**(dep 등록은 생성자에서 한 번만, 발화 게이팅은
   > 전부 `canExecute(handle)`). 8라운드 `H-114` 반영 때 옛 필드명
   > `handle._observers`를 `_deps`로 **이름만** 고치는 바람에, 폐기된 동작
   > 주장이 오히려 갓 정비된 것처럼 보이게 됐다. **결론(`Destroying` 배선을
   > `bindLifetime` 옆에 둔다)은 그대로 유효하다** — 근거만 바뀐다: 그 함수가
   > `isEffect`를 보고 `_bindDestroying`을 부르는 훅 자리이기 때문이다(`H-11`).
   - **한때 근거로 든 *"게이트는 값 타입을 안 가린다"*는 이 자리에 안 맞는
     인용이었다** — `base/source-state-plan.md`의 그 절이 말하는 건
     **`canBound` 판정**이 `:Subscribe()`/`bindLifetime` 두 진입점에서 같다는
     것이지, `bindLifetime`의 **부수 배선**이 값 종류를 못 본다는 게 아니다.
     실제로 그 함수는 `isEffect(value)`를 보고 `_bindDestroying`을 부른다
     (**[2026-08-26 재정정, `/code-review high`]** 여기 한때 *"`Effect`면 내부
     Observer로 cascade한다"*고 적혀 있었으나 그 cascade는 `H-58`이 폐기했다 —
     위 ⚠️⚠️ 배너가 소스. 이 항목이 말하려는 것(그 함수가 값 종류를 본다)은
     `isEffect` 분기로 그대로 성립한다).
2. **`unbindLifetime`은 cleanup을 부르지 않는다.**
   > **⚠️ [2026-08-26 정정, 8라운드 `H-114`] 아래 두 문장 중 "`Ref` 콜백도
   > 같이 해제" / "언마운트가 콜백을 떼고 재마운트가 다시 건다"는 **폐기됐다.**
   > 하루 뒤(2026-08-25) `H-58`이 정반대로 확정했다 — 같은 파일의
   > `_unbindDestroying` 의사코드가 소스이고, 거기선 **`Ref` 콜백도 Observer도
   > 안 뗀다**(그래야 바인드마다 `Rerun`이 도는 걸 막는다). 살아 있는 것은
   > "cleanup을 안 부른다"는 이 항목의 제목뿐이다.
   `Destroying` 커넥션을 끊고
   ~~**`Ref` 콜백도 같이 해제**하되(아래 `H-7` 절과 대칭)~~, cleanup은 그대로
   남긴다 — `destroySlotTree`가 `_detachCleanup`을 `unbindLifetime`하며 달아둔
   주석(*"이미 손으로 비웠으니 Effect는 할 일 없음"*)과 `E-11`(leaf 바인딩엔
   `:Unsubscribe()`가 안 먹는다)이 그 전제 위에 서 있다. **이 계약을 명시한다** —
   지금까진 어느 쪽도 안 적혀 있었다.
   - ~~**bind/unbind가 대칭이라 포탈이 자연히 성립한다** — 언마운트가 콜백을
     떼고 재마운트의 `bindLifetime`이 다시 건다.~~ **[2026-08-26 폐기,
     `H-114`]** 위 배너대로 `H-58`이 뒤집었다. 포탈이 성립하는 실제 근거는
     **dep 등록이 생성자에 고정돼 언바인드가 아무것도 안 뗀다**는 것 — 재마운트는
     `Destroying` 연결만 다시 건다(`_bindDestroying`). 포탈 사이에 놓친 emit의
     캐치업은 **홀드 플래그로**(**[2026-08-28 `H-151`/`H-159`]** 옛 `_epochs:Refresh()`
     폐기 — 대신 언마운트~재마운트 사이에 온 emit은 `rawRerun`이 `_rerunRequired`로
     잡아 두고 재마운트의 `_bindDestroying`이 1회 돌린다).
3. **cleanup은 `handle._cleanup` 필드에 보관한다.** `Rerun`이 이미 직전
   cleanup을 필요로 하므로 필드 쪽이 자연스럽고, `Destroying` 클로저와
   `Rerun`이 같은 자리를 읽게 된다.

**⭐⭐ [2026-08-25 재설계, 7라운드 `H-58`/`H-59`/`H-64`/`H-70`] dep 등록은
`bindLifetime`이 아니라 생성자에서 한 번만 한다.** 옛 의사코드는 `Ref` 콜백을
`_bindDestroying`에서 (재)등록했는데, `ref-plan.md`가 확정한 *"등록 즉시 그
값으로 1회 호출됨"*과 겹쳐 **바인드마다 `Rerun`이 `Ref` dep 수만큼 돌았다**.
같은 문제가 State dep에도 있다 — `source-state-plan.md`가 확정한
*"`fn`은 등록 시점에 즉시 1회 실행된다"* 때문이다.

### 확정 구조 — 강한 주인은 항상 `Effect`, 발화 게이트는 `canExecute` 하나

```
Effect ──강──▶ _deps = { [Ref | State] = fn | Observer }   ← 강한 주인은 언제나 Effect
Ref.WeakCallbacks        ──약──▶ fn        (`ref:WeakCallback(fn)`)
  ⚠️ [2026-08-26 `/code-review high` 7차] 한때 여기 `Ref.Callbacks`(강한 셋)라
     적혀 있었다 — 그대로 읽으면 `Effect`의 클로저가 강한 셋에 들어가
     **`Ref`가 그 `Effect`를 영원히 붙들어** `H-58`의 약한 설계가 통째로 죽는다.
Observer 전역 레지스트리 ──약──▶ Observer  (`observer:WeakSubscribe()`)
발화 게이트: 전부 `canExecute(handle)` 하나로
```

**사용자 확정(2026-08-25)**: *"그냥 간단하게 저 강한 map 을 Effect 가 가지고,
WeakSub/WeakUnsub 를 WeakCallback 처럼 넣어줍시다. 의미론은 같습니다.
callback 을 잡고 있지 않거나, sub 대상인 observer 를 잡고 있지 않으면 gc 될
수 있다. **그러면 bindLifetime 은 effect 하나 구현을 한 이후 canExecute 로
모두 처리한다. 간단해집니다.**"*

- **dep마다 바인드/언바인드에서 등록·해제하던 춤이 통째로 사라진다.**
  `bindLifetime`/`unbindLifetime`은 **`Effect` 핸들 하나**에만 적용되고,
  내부 Observer와 `Ref` 콜백의 발화 여부는 `canExecute(handle)`이 전담한다.
- 그래서 아래 `H-7` 절이 확정한 *"`unbindLifetime`과 `:Unsubscribe()`에서
  `:Uncallback`한다"*는 **더 이상 필요 없다** — `ref-plan.md`의
  *"해제는 누수를, 게이팅은 발화를 막는다"* 중 **앞쪽 절반을 `Weak*`가
  대신한다**.
- **왜 `WeakRef`가 아니라 `WeakCallback`인가**(사용자 지적): *"Ref 안에
  항상 콜백이 쌓인다는것도 문제가 됨."* 클로저가 핸들을 약하게 잡는
  `WeakRef`는 "`Ref`가 `Effect`를 붙든다"만 풀고 "`Ref.Callbacks`에 죽은
  클로저가 쌓인다"는 못 푼다. `WeakCallback`은 둘 다 푼다 —
  `Effect ↔ cb` 순환이 자기완결이라 Luau GC가 통째로 수거하고 `Ref` 쪽
  항목도 같이 사라진다. **`WeakRef`는 만들지 않는다.**
- 이건 `blocker-plan.md`의 onunblock 핸들 보관과 **같은 패턴**이다 —
  강한 주인은 소비자 쪽, 등록처는 weak.

### 의사코드 — 생성자 / `bindLifetime`이 부르는 두 훅 / `Rerun`

```lua
-- quad-base, Effect.luau
function Effect(fn, ...)
    local self = setmetatable({ fn = fn, _deps = {}, _epochs = EpochMap() }, EffectHandle)

    -- (0) deps 검증 — 생성자에서 한 번만 도는 검사라 hot path가 아니다.
    --     `select("#", ...)`로 순회해야 `nil` 구멍이 조용히 배열을 자르지 않는다.
    local seen = {}
    for i = 1, select("#", ...) do
        local d = select(i, ...)
        if d == nil then error("Effect: dep #" .. i .. " is nil", 2) end
        if not (isState(d) or isSource(d) or isRef(d)) then
            error("Effect: dep #" .. i .. " is not a State/Source/Ref", 2)
        end
        if not seen[d] then seen[d] = true end   -- 중복 dep은 조용히 무시(error 아님)
    end

    -- (1) dep 등록 — **여기서 한 번만**. 즉시-1회 호출(설치 발화)은 `fire`의 `from == nil`
    --     가드가 거른다(**[2026-08-28]** 옛 `Blocker`/`canExecute` 억제 서술은 폐기).
    --     ⭐⭐ [2026-08-26 재확정, 8라운드 `H-107`] dep 종류마다 **클로저를
    --     따로** 단다. 여기 한때 "클로저는 하나로 통일한다"고 적혀 있었으나,
    --     그 통일을 시도할 근거 자체가 없었다 — **사용자 확정**:
    --     *"Ref 의 callback 과 observer 의 콜백이 아주 헤테로지니어스한
    --     개념이라, 둘을 전혀 합치고자 한 적 없고 … observer 에는 epoch 란게
    --     존재하지 않음. emit 으로 온 epoch 를 넘겨줄 뿐, 그러나 ref 는 그
    --     자체로 epoch임."* 실제로 두 계약은 자리 수부터 다르다 —
    --     `Ref` 콜백은 `fn(value, ref)`(2번째가 곧 출처 `Epoch`),
    --     Observer는 `fn(targetState, self, emitFrom)`(3번째가 출처).
    --     ⚠️ dedup을 클로저 identity가 하는 게 아니다 — `_deps`(중복 dep 무시)와
    --     `_epochs`(다이아몬드 판정)가 한다. 그래서 클로저를 나눠도
    --     "공통 상류를 공유해도 한 파동에 fn은 한 번만"이 그대로 성립한다
    --     (그게 아니었으면 `A → b`, `A → c`, `Effect(fn, b, c)`에서
    --     `A:Set()` 한 번에 `fn`이 두 번 돈다 — 2026-08-21에 닫은 그 버그).
    -- ⭐ [2026-08-28 확정, 10라운드 `H-150`] 사적 `Blocker`(`_blocker:On()` …
    --   `OffWithoutEmit()`)는 **제거** — 실측(10라운드 `t18`)상 어떤 경로에서도 판정에
    --   닿지 않는 죽은 부품이었다(사용자 확정: *"Effect 의 canExecute 를 보겠다는거지?
    --   그럼 그건 맞는것 같아"*). 설치 발화의 억제는 아래 `from == nil` 가드가, 실행
    --   가능 여부는 `rawRerun`이 한 곳에서 본다(**[같은 날 `H-159`]** `fire` 자신은
    --   상태를 판정하지 않는다 — 사용자: *"fire 는 그냥 rerun 을 호출해도 될것"*).
    local function fire(from)                          -- 공통 본문
        if from == nil then return end                 -- 내부 Observer의 **설치 발화**(등록 즉시 1회,
                                                       --   `emitFrom == nil` — `source-state-plan.md`)는
                                                       --   출처가 없어 `Update(nil)`을 못 한다. ⚠️ `Ref`
                                                       --   값이 `nil`인 것과 무관 — `Ref` 경로의 `from`은
                                                       --   항상 그 `ref` 객체다(`onRefFire`).
        if self._epochs:Update(from) then              -- ⭐ [`H-151`] `_epochs`가 갱신되는 **유일한** 자리 —
            self:Rerun()                               --   묶여 있든 아니든 항상. 실행 불가면 `rawRerun`이
                                                       --   `_rerunRequired`로 홀드한다(`H-159`).
        end
    end
    local function onRefFire(_, ref) fire(ref) end            -- Ref: 2번째가 출처
    local function onStateFire(_, _, from) fire(from) end     -- Observer: 3번째가 출처
    for d in pairs(seen) do    -- 스타일 통일(`pairs` 명시). **[2026-08-27 9라운드
                               --   `H-131`]** 옛 근거 *"`for d in seen`은 테이블을
                               --   호출하려 들어 죽는다"*는 **거짓** — Luau의 일반화
                               --   반복은 런타임·`--!strict` 둘 다 통과한다(실측).
        if isRef(d) then
            self._deps[d] = onRefFire                  -- ⭐ 강한 주인 = Effect
            d:WeakCallback(onRefFire)                  -- Ref 쪽은 약함
        else
            local o = d:Observer(onStateFire)
            self._deps[d] = o                          -- ⭐ 강한 주인 = Effect
            o:WeakSubscribe()                          -- 전역 레지스트리는 약함
        end
        -- ⭐ dep이 `Epoch`인지로 갈린다 — `state-epoch-plan.md` §4의 시딩 규칙
        --   그대로다. **`Source`/`Ref`는 `Epoch`지만 `State`는 아니다**(§2·§8) —
        --   무조건 `Sync`하면 State dep이 `.Revision` 없는 키로 들어가
        --   `Update(from)`이 그 원천의 리비전을 영영 못 본다.
        if isEpoch(d) then
            self._epochs:Sync(d)
        else
            self._epochs:TrackFrom(d.valueEpochMap)
        end
    end

    -- (2) 설치 — 생성 즉시 1회. **바인드로 미룰 수 없다**(아래 캐비엇).
    --     ⭐ [2026-08-28 `H-147`/`H-159`] "한 번도 안 돌았다"는 `_rerunRequired`로
    --     표시하고(초기 실행과 "실행 못 하던 중의 변경"은 같은 요구 — 사용자),
    --     본체를 `force`로 부른다. `force`의 뜻은 **하나** — *"canExecute 를 무시하고도
    --     호출할 수 있냐. 오직 그게 전부야."*(사용자). 초기 실행을 바인드로 미룰 수
    --     없다는 결정(순차 처리) 때문에 이 시점 예외 하나가 남는다.
    self._rerunRequired = true
    rawRerun(self, true)
    return self
end
```

- **`_installing` 플래그도, 그 뒤를 이은 사적 `_blocker`도 폐기됐다** —
  `_installing`은 생성자 구간만 덮어 바인드 구간을 놓쳤고(7라운드 `H-58`),
  `_blocker`는 그 자리에 들어왔지만 **[2026-08-28 10라운드 `H-150`]** `canExecute`(당시
  `fire` 첫 줄, `H-159` 뒤엔 `rawRerun` 진입)가 이미 같은 억제를 하고 있어 한 번도 판정에 닿지 않았다
  (실측 `t18`: `drop:canExecute` 3 / `drop:blocker` 0). `H-58`의 사용자 지시
  (*"해당 맥락의 도구인 Blocker 가 존재함 … 모든 옵저버와 callback 등록에 있어서
  이를 수행해야할 것임."*)는 그 전제("등록 즉시 1회가 `Rerun`에 닿는다")가
  성립하지 않았던 것으로 정정 — 억제 주체는 Effect 핸들의 `canExecute`다.
- **⚠️ 생성 즉시 1회 실행은 바인드로 미룰 수 없다.** **사용자 판단**:
  *"Effect 가 바운딩 될 때 실행되는건 문제가 있습니다. 그 이팩트 실행
  결과를 바로 받아서 처리하는 아래쪽 요소가 있으면, 순차 처리가 전혀 안
  되거든요. 초기 값이 못 쓰게 되는거죠."* 그 따름정리로 **바운딩 없이
  버려지는 `Effect`는 UB**다 — cleanup이 안 불린다. `Observer`와 달리
  `Effect`는 "죽기 전에 처리해주겠다"가 계약이라 성격이 다르다.

```lua
-- ⭐ [2026-08-31 `H-184`, 사용자 확정] `bindLifetime`이 부기를 커밋하기 **전에**
--   이 훅을 먼저 묻는다 — 가드가 거부해도 반쯤 묶인 핸들(묶였는데 `Destroying`
--   연결 없음)이 남지 않는다. `H-147` (A)의 가드는 `_bindDestroying` 첫 줄에서
--   여기로 이동했다(그쪽의 유일한 호출자인 `bindLifetime`이 이미 물었으므로).
--   level 3: 이 메소드와 `bindLifetime`을 지나 사용자 호출부. Observer도 같은
--   이름의 훅을 가진다(`H-183` — 자기 `_running`을 본다). 값이 훅을 안 가지면
--   (평범한 클로저 등) `bindLifetime`은 물을 것이 없다.
function EffectHandle:_assertBindable()
    if isRunning(self) then
        error("cannot bind an Effect from inside its own fn or cleanup", 3)
    end
end

function EffectHandle:_bindDestroying(inst)
    self:_unbindDestroying()          -- 재바인드(포탈 재마운트)면 옛 연결부터 — 멱등
    self._dying = false               -- ⭐ [2026-08-31 `H-182`] Destroy 파동의 생존자를 재무장

    -- (1) leaf가 죽는 순간 cleanup을 정확히 1회. `LP-2`가 확정한 유일한 훅 지점.
    self._destroyConn = onDestroying(inst, function()
        -- ⭐ [2026-08-31 `H-182`, 사용자 확정] 이 콜백 뒤에도 같은 Destroy 파동
        --   안에선 `canExecute`가 참(gcconn은 마지막에 끊김) — `_dying`이 그 창을
        --   닫아 파동 후반의 dep 변경이 죽는 leaf 위에서 `fn`을 다시 돌리는 대신
        --   **홀드**된다(`rawRerun`이 `canExecute`와 같이 본다). 이름이 Slot의
        --   `_destroyed`와 다른 건 의도다 — Slot은 죽으면 재바인딩 못 하지만 Effect
        --   핸들은 다시 bind될 수 있어 "죽는 도중"만 뜻한다(사용자: *"네이밍의 다른
        --   이유가 확실함"*). 재무장 자리는 위 bind와 `Subscribe`/`WeakSubscribe`.
        self._dying = true
        self:_unbindDestroying()
        self:_consumeCleanup()
    end)

    -- (2) 캐치업 — **`_rerunRequired`가 서 있으면 1회**. dep 등록은 이미 생성자에서
    --     끝났다. ⭐ [2026-08-28 `H-151`→`H-159`] `_epochs:Refresh()`는 폐기(`_epochs`는
    --     `fire`의 `Update(from)`에서만 갱신 — 사용자: *"우린 애초에 Refersh 를 할
    --     필요가 없는거야"*), 대신 **실행 불가 상태(안 묶임·죽음·cleanup 중)에 온
    --     변경은 `rawRerun`이 `_rerunRequired`로 홀드**해 두고 여기서 한 번 돌린다
    --     (Gate의 유보와 같은 그림 — Effect는 "한 번 다시 돌면 된다"라 불리언 하나).
    --     소진된 뒤의 재바인드도 같은 플래그(`_consumeCleanup`이 세운다). 사용자:
    --     *"'초기실행' 과 '실행 안하던 중에 바뀐것' 이 사실 같은 요소"* — 옛
    --     `_installed`는 이 플래그의 부정형이라 통합했다. gcconn 연결 **뒤**라 공개
    --     `Rerun`의 게이트를 통과한다.
    if self._rerunRequired then
        self:Rerun()
    end
end

-- ⚠️ [2026-08-28 확정, 10라운드 감사 2라운드] **`fn` 안에서 자기 leaf `inst`를
--   파괴하는 것은 UB.** `Workspace.SignalBehavior`가 `Deferred`(현재 기본)면
--   `Destroying` 콜백이 다음 리줌으로 늦춰져 경합이 없지만, `Immediate`(레거시)면
--   `fn` 실행 도중 위 콜백이 동기 발화해 `_consumeCleanup`(이미 비어 있음 — no-op)과
--   `_destroyConn` 해제만 일어나고, `fn`이 돌려준 cleanup은 저장되지만 소진할 연결이
--   사라져 **영구 미소진**이다. `fn`이 자기 생명주기를 못 바꾼다(`H-147` (A))는
--   계약의 물리판 — 사용자: *"bind/unbind 에 간접 영향을 주는건데, UB 인게 맞다는 생각"*.
--   `SignalBehavior` 구분 자체는 `base/ref-plan.md`가 소스.
function EffectHandle:_unbindDestroying()
    if self._destroyConn then
        self._destroyConn:Disconnect()
        self._destroyConn = nil
    end
    -- **`Ref` 콜백도 Observer도 안 뗀다** — `Weak*`로 걸려 있고 발화는
    -- `canExecute`가 막는다. **`_cleanup`도 안 부른다**(아래 2번 계약).
end

-- cleanup 소진: 읽고 → 지우고 → 실행. 이 순서라야 이중 호출이 없다
-- ("설치돼 있는가"는 `_cleanup`의 유무가 아니라 아래 `_rerunRequired` — `H-195`로 옛 뒷절 삭제).
function EffectHandle:_consumeCleanup()
    local c = self._cleanup
    self._cleanup = nil
    self._rerunRequired = true     -- ⭐ 소진됐다 = 다음 기회에 다시 설치해야 한다(아래 캐비엇)
    if c then
        -- ⭐ [2026-08-28 확정, 10라운드 감사 2라운드] cleanup은 **세 자리**에서 돈다 —
        --   `rawRerun` 루프 머리 / `Unsubscribe()` / leaf `Destroying` 콜백. 뒤의 둘은
        --   `_running` 밖이라 cleanup 안의 `self:Subscribe()`가 가드를 지나
        --   `Unsubscribe()`가 끝나기도 전에 `fn`이 재진입했다. `_running`에 뜻을
        --   얹지 않고 **별도 플래그**로 잡는다(사용자: *"_running 으로 묶어 보는건
        --   여전히 별로 괜찮은 이유가 없음. _cleanupRunning 같은걸 넣지 말아야할
        --   이유가 없는것"*).
        self._cleanupRunning = true
        c()
        self._cleanupRunning = false
    end
end
```

**⚠️ [2026-08-25 `/code-review high` 정정; 2026-08-28 `H-159`로 플래그 통합] "설치돼
있는가"를 `_cleanup`의 유무로 판정하면 안 된다 — 별도 플래그가 필요하다.** 여기
한때 `if self._cleanup == nil or ...`라고 적어뒀는데, **`fn`의 cleanup 반환은
선택**이라(`Effect(function() print("x") end, s)`처럼 아무것도 안 돌려주는
게 흔한 정상 용례) `_cleanup`이 **항상 `nil`**인 Effect가 존재한다. 그러면
바인드/포탈 재마운트마다 조건이 참이 되어 `fn`이 다시 돌고 — 이 재설계가
없애려던 `H-58`(바인드마다 `Rerun`)이 **그대로 되살아난다.** 그 플래그는
2026-08-25~28엔 `_installed`(설치됨)였고, **[2026-08-28 `H-159`]** 지금은
**`_rerunRequired`**("`fn`이 돌아야 하는데 아직 안 돌았다") 하나다 — 세워지는 곳은
생성자·`_consumeCleanup`·`rawRerun`의 홀드 셋, 내려가는 곳은 `rawRerun`이 `fn`을
실제로 돌리는 자리 하나. `_installed`는 이 플래그의 부정형이라 통합했다.

**⭐ [2026-08-25 신설, 7라운드 `H-60`; 2026-08-28 10라운드 `H-147`로 재정의]
`rawRerun(self, force)` 본체 + 공개 `EffectHandle:Rerun()`.**
지금까지 호출부만 다섯 곳이고 정의가 없었다. **[2026-08-28]** 사용자 지적으로
둘로 갈랐다 — *"처음부터 rerun 이 're'-run 인데도 초기 실행까지 담당하고 있잖아
… rawRerun(force: boolean) 을 만들어 생성 시점과 실행 시점에서 이를 명시하는게
맞지 않아?"* — 초기 설치는 아직 안 묶인 상태라 공개 진입의 게이트를 못 지나므로
호출자가 그 사실을 인자로 말한다(`raw*` = 검사 없는 내부 본체, Slot의 `raw*`
관용구와 같다).

```lua
-- 본체. force = 초기 설치(생성자) — 아직 안 묶였으니 게이트를 안 본다.
-- (이 문서의 절 순서는 개념 순서다 — 실제 파일에선 `rawRerun`·`isRunning`·
--  `resubscribeTail` 같은 `local function`이 사용처(생성자·`_bindDestroying`·네
--  진입점)보다 **앞에** 선언돼야 한다. Luau의 `local function`은 앞선 호출에서 안 보인다.)
local function rawRerun(self, force: boolean)
    if self._running then
        self._pending = true           -- 실행 중 재진입 → 지연
        return
    end
    if self._cleanupRunning or self._dying or (not force and not canExecute(self)) then
        self._rerunRequired = true     -- ⭐ [2026-08-28 `H-159`/`H-160`] 실행 불가 상태(cleanup 중 /
        return                         --   안 묶임 / 죽음)에 온 요청은 **버리지 않고 홀드** — 다음에
    end                                --   묶이는 순간 1회 돈다. 버리면 "변경을 아예 보고 안 함" 경로가
                                       --   생긴다(사용자: `State<Effect>` 포탈의 언마운트 cleanup 도중
                                       --   dep이 바뀌면 재마운트가 최신값을 못 본다). leaf `Destroying`
                                       --   cleanup 안의 `self:Rerun()`/`dep:Set()`도 여기 — gcconn이 아직
                                       --   연결돼 `canExecute`만으론 못 막는다(`H-160`). `Unsubscribe` 뒤
                                       --   늦게 오는 타이머의 `Rerun()`도 홀드(재구독하면 돈다).
                                       --   ⭐ [2026-08-31 `H-182`] `_dying`(자기 `Destroying` 콜백이 소진한
                                       --   뒤, 같은 파동의 잔여 구간)도 같은 홀드 — `H-160`의 연장이다.
    self._running = true
    repeat
        self._pending = false
        self:_consumeCleanup()         -- 안에서 `_rerunRequired = true`
        self._rerunRequired = false    -- ⭐ 실제로 돈다 — 이 플래그가 내려가는 **유일한** 자리
        self._cleanup = self.fn(self)  -- ⭐ [2026-08-31 `H-185`, 사용자 확정] cleanup은 **첫 반환 하나뿐** —
                                       --   여러 정리는 `function() a() b() end`로 묶는 게 계약. 반환 전부를
                                       --   목록으로 소진하는 안은 기각(재진입·`_rerunRequired`·`_pending`과
                                       --   엮이는 표면만 늘고, 클로저로 묶는 데 아무 문제가 없음). 타입의
                                       --   팩 표기는 "반환 안 해도 됨"(`H-95`)을 위한 것이지 목록 계약이 아니다.
    until not self._pending            -- 재요청이 또 오면 또 돈다(`_pending` = 실행 **중**에 온 요청)
    self._running = false
end

function EffectHandle:Rerun()          -- 공개 메소드, 무인자 — 항상 게이트
    rawRerun(self, false)
    return self
end
```

- **⭐⭐ [2026-08-28 확정, 10라운드 `H-147`] `fn`도 cleanup도 자기 생명주기를 바꿀
  수 없다 — 그래서 이 루프 안에는 사망 판정이 없다.** 2026-08-27에 `H-143`으로
  "`fn` 안 `self:Unsubscribe()`(원샷 Effect)"를 지원하기로 하고 `Rerun` 꼬리에
  `wasAlive and not canExecute` 판정을 넣었는데, 하루 만에 그 허용 하나에서
  파생된 결함이 넷(감사 2·4라운드, `H-147`) 나왔고 사용자가 뿌리를 짚었다:
  *"유저 함수가 본인을 죽이고 살린다는점 자체가 모순이였다는 문제가 나와. 처음
  실행해 unsub 했는데, 아래에서 sub 해버릴 수도 있지. 이건 의도 동작일까? 게다가
  unbind/bind 는 본인이 못 해. 같은 계층으로 sub/unsub 가 본인이 할 수 있어야할
  이유 제공 자체가 큰 그림에서 무언가 잘못된거 아닐까?"* → **(A) 확정**: Effect의
  생애는 **묶은 쪽**(leaf면 Instance, `:Subscribe()`면 그 호출자)이 소유하고, `fn`은
  dep을 읽고 부작용을 내고 cleanup을 돌려주는 것까지다. leaf가 `fn` 안에서
  unbind/bind를 못 하는 것과 **대칭**. (*"나는 지원 안 할 이유가 안 보였었는데,
  지금 보면 엄청난 모순이네."*) 강제는 네 진입점의 `_running` 가드(아래
  `EffectHandle:Subscribe()` 절). **원샷**은 소유자가 밖에서 `Unsubscribe`하거나
  나중에 `Once`류 슈가로 — 코어엔 없다. `H-143`은 소멸.

- **재진입은 지연 재실행**이다. **사용자 판단**: *"Effect 의 실행 안에서
  뭔가 수행되어 rerun 해야할 상황이 발생하면, 지연해 두었다 나중에 재실행
  하는건 어떤지(실행이 끝나고 나서). 실제로 Effect 안에서 state 등을 바꾸는
  상황은 react 등지에서 흔함."*
- **`canExecute` 확인은 `rawRerun` 진입에서 한 번** — **[2026-08-28 `H-159`]** `fire`는
  판정하지 않고 `Update → Rerun`만 하며, 실행 불가(안 묶임·죽음·cleanup 중)면
  `rawRerun`이 `_rerunRequired`로 **홀드**한다(no-op이 아니다 — 다음 바인드에서 1회).
  그래서 루프 안엔 판정이 없다. (한때 "`fire` 첫 줄에서 보고 죽은 핸들은 no-op"
  이었는데 그 문장은 `H-159` 이전 것.)
- **error 시 UB — 그 Effect는 죽는다.** 전파되고 복구하지 않는다: `fn`이 error하면
  `_running`이, cleanup이 error하면 `_cleanupRunning`이 참으로 남아 **이후 모든
  재진입(`Rerun`·네 진입점·재바인드)이 막힌다**. **[2026-08-28 `H-160` 사용자 확정]**
  *"한번 죽는게 나오면 Effect 가 전부 죽는다가 계약으로 상향되어도 문제는 없는듯.
  이미 _running 도 그러한 제약을 받으니까."* — 계약으로 명문화. *"에러가 난 이후 데이터의 무결이 깨져도 별 책임 안 진다는 quad의
  일반 동작"*(사용자). 수렴 책임은 사용자 `fn`에 있고 무한 루프도 UB다.

**⭐ [2026-08-25 신설, 7라운드 `H-65`] 재바인드는 재설치, 재사용은 팩토리
패턴.** 파괴로 cleanup이 소진된 `Effect`를 다시 바인드하면 위 (2)의
`_rerunRequired`가 참이라(**[2026-08-28 `H-159`]** 옛 `not _installed`) **재설치**된다. 죽음을 표시하는 별도 부기는
만들지 않는다 — **사용자 지적**: *"파괴 클린업은 결국 inst.Destroying 에
이벤트 바인딩인데 이 바인딩도 파괴 이후 자동 삭제된다 … gchold 나 gcconn 도
알아서 잘 풀린 상태라, 그냥 가만히 두면 삭제 이후 다시 사용에 있어 다시
실행해줘야한다는 것 이외엔 아무 문제가 없어요."*

같은 `fn`을 **여러 인스턴스로** 쓰고 싶으면 `Effect`를 넘기지 말고
**팩토리를 넘긴다**:

```lua
local function TimerEffectFactory(data: { timerSource: Source<number> }): Effect
    return Effect(function(self)
        ...
        return function() ... end
    end, data.timerSource)   -- 주입받은 것을 그대로 deps로도 쓸 수 있다
end
```

- **사용자 결론**: *"차라리 Effect 를 만들어내는 팩토리를 넘기는 패턴을
  권장해야할듯 해요 … Clone 도, Userdata 도, 템플릿도 필요하지 않다."*
  초기 1회 실행 문제가 자연히 해결되고, 템플릿이 실행되어 찌꺼기로 남는 걸
  막으려 따로 뭘 할 필요도 없다. 자식의 계약은 `({...}) -> Effect` 하나이고
  부모가 더 큰 타입을 넘겨도 **부분 성립**으로 해결된다. 무엇보다 **주입받은
  `Source`/`Ref`를 그대로 deps로 넣을 수 있다** — userdata로는 안 되던 것이다
  (*"이건 ud 가 deps 에 대해서는 아무 처리가 못 했던것과 비교해 더 간단하면서도,
  기능적임"*). modifier에서 이미 권해온 패턴이기도 하다.
- 부수로 *"이팩트를 여러곳에 바인딩하면?"*도 자연히 해결된다(매번 새 인스턴스).
- **검토 후 안 만들기로 한 것**: `Effect:Clone()`, `Effect<UD>:Userdata()` /
  `SetUserdata`·`GetUserdata`, `Effect.Template`, `WeakRef`.

- **`onDestroying(inst, fn)`은 백엔드 주입 op이다** — base는 `Instance`를
  모른다(`base/slot-plan.md`의 `native*` 절과 같은 이유). quad-roblox 구현은
  `inst.Destroying:Connect(fn)` 한 줄. 주입 op 전체 목록의 단일 소스는
  `base/architecture.md`의 `EngineOps.luau` 줄이다.
- **필드 목록**: `_destroyConn`(연결 핸들), **`_deps`**(`Ref|State` → 내가 건
  `fn|Observer`, **강참조**), `_epochs`(`EpochMap` — `Ref`도 `Epoch`라 균일),
  `_cleanup`, **`_rerunRequired`**(`fn`이 돌아야 하는데 아직 안 돌았다 — 생성 직후 /
  소진 뒤 / 실행 불가 상태에 온 변경. cleanup 반환이 선택이라 `_cleanup`으로는 판정
  못 한다; **[2026-08-28 `H-159`]** 옛 `_installed`의 부정형을 흡수),
  `_running`/`_pending`(재진입 — `_pending`은 실행 **중**에 온 요청, `_rerunRequired`는
  실행 **불가 상태**에 온 요청), **`_cleanupRunning`**(cleanup 실행 중 — `_running`과
  별개, 네 진입점 가드가 둘 다 본다, **[2026-08-28]**), **`_dying`**(**[2026-08-31
  `H-182`]** Destroy 파동에서 자기 `Destroying` 콜백이 소진한 뒤의 잔여 구간 —
  `rawRerun`이 홀드 조건으로 보고, 재바인드·`Subscribe`류가 내린다),
  **`.Subscribed`**(공개 플래그 — `canExecute`가
  읽는 그것, 네 진입점이 세우고 내린다, 아래 "`EffectHandle:Subscribe()`" 절).
  **옛 `_refDeps`/`_refCallbacks`/`_observers`/`_installing`은 `_deps` 하나로
  대체됐고, `_installing` 자리에 잠깐 있던 `_blocker`도 [2026-08-28 `H-150`]
  제거됐다 — 억제는 `canExecute`.**

### ⭐ `Ref` 의존성의 해제 경로 (2026-08-24 확정, 6라운드 손 트레이싱 `H-7`)

> **⭐⭐ [2026-08-25 갱신, 7라운드 `H-58`/`H-59`] 해제 경로 대신 `Weak*`
> 등록으로 바뀌었다.** 아래가 진단한 누수(*"leaf가 죽어도 `ref.Callbacks`에
> 클로저가 영원히 남는다"*)는 그대로 유효하지만, **해법이 바뀌었다** —
> `unbindLifetime`/`:Unsubscribe()`에서 `:Uncallback`하는 대신
> `ref:WeakCallback(cb)`로 걸고 **강한 주인을 `Effect._deps`에 둔다**.
> 그러면 `Effect`가 죽을 때 콜백도 같이 죽어 항목이 자연히 사라지고,
> 바인드/언바인드마다 떼었다 붙이는 춤이 없어진다(그 춤이 `H-58`의
> 중복 `Rerun`을 만들던 원인이다). 위 "확정 구조" 절이 소스.
> **아래 `canExecute` 게이팅은 그대로 유효하다** — *"해제는 누수를,
> 게이팅은 발화를 막는다"* 중 **뒤쪽 절반**이 여전히 이 절의 결론이다.
> **[2026-08-29 `H-191`]** 다만 그 게이팅의 자리는 콜백 본문이 아니라 `rawRerun` 진입이고,
> 거짓이면 버리는 게 아니라 **홀드**(`_rerunRequired`, `H-159`)다 — 아래 문단의 "본문 맨
> 앞에서 … 거짓이면 그대로 리턴"은 `H-159` 이전 모양. 소스는 위 생성자 블록.

`Effect(fn, someRef)`의 leaf가 죽어도 **`ref.Callbacks`에 클로저가 영원히
남았다** — `Ref`엔 콜백 해제 API가 없었고(`:Uncallback` 류 없음)
`canExecute` 게이팅도 안 걸린다(그건 Observer 쪽 배관이다). 그 클로저가
`EffectHandle`을 강참조하므로 누수이고, 이후 `ref:Set`마다 **이미 죽은 leaf의
직전 cleanup + `fn`을 계속 실행**한다. 같은 절이 *"leaf dedup/cascade가 전부를
덮어야 한다"*고 요구하는데 `Ref` 쪽엔 그걸 만족시킬 수단 자체가 없었다.

**확정: `Ref`에 콜백 해제 경로를 추가한다**(`base/ref-plan.md`가 소스).
`EffectHandle`은 자기가 건 `Ref` 콜백 핸들을 들고 있다가, `unbindLifetime`과
`:Unsubscribe()`에서 같이 해제한다 — State/Source dep 쪽과 대칭이다
(**[2026-08-26 표기 정정, `H-114`]** 옛 `_observers` 표기를 지웠다 — 지금은
`_deps` 하나다. **⚠️ 다만 이 문단의 "`unbindLifetime`에서 해제"는 `H-58`이
뒤집었다** — 언바인드는 아무것도 안 떼고, 억제는 `canExecute`가 한다(`H-150`). 살아
있는 것은 "`Ref`에 콜백 해제 경로(`:Uncallback`)를 둔다"는 결론뿐이다).

**⭐ [2026-08-24 추가, 사용자 지적] 해제 경로만으로는 부족하다 — `Ref` 콜백도
발화 시점에 `canExecute`를 확인한다.** State/Source dep은 Observer 자신의 `_receive`가
`canExecute(observer)`를 보고 죽은 것을 건너뛰는데(**[2026-08-28 `EmitReceive`]** 옛 표현은
"전파 루프가" — `base/source-state-plan.md`),
`Ref` 경로엔 그 게이트가 아예 없었다. 해제가 늦거나 누락되는 창이 실재한다 —
예컨대 `unbindLifetime`으로 조용히 끊긴 상태(포탈 언마운트)는 `Destroying`이
안 도는데도 `canExecute`가 거짓이다. **확정된 형태(`H-159`로 갱신)**: `Effect`가 거는
`Ref` 콜백(`onRefFire`)은 판정하지 않고 `fire → _epochs:Update → Rerun`만 하며,
**`rawRerun` 진입**이 자기 핸들에 대해 `canExecute(handle)`를 보고 거짓이면 **홀드**
(`_rerunRequired`, 다음 바인드/구독 때 1회)한다 — 한때 여기 *"콜백 본문 맨 앞에서 확인하고
거짓이면 그대로 리턴"*이라 적혀 있었다(`H-191`; 버리기와 홀드는 관측이 다르다 —
안 묶인 채 온 `ref:Set`이 바인드 때 재생된다, `spec.effect.luau` 2). 그러면 두 dep 경로가
같은 게이트를 공유하게 되어 `Effect`의 발화 조건이 dep 종류와 무관해진다.

### 동적 경로 가드 — `k` 무관 매치, `HANDLER_PRIORITY_FALLBACK`

(2026-08-14 열한 번째 세션, `PreRef`/`Observer`와 같은 패턴, `base/
source-state-plan.md`의 "동적 경로 가드" 절 참고.)
**⚠️ [2026-08-24] 이 가드를 실제로 `Dispatch.addHandler`로 등록하는 것은
M3(디스패치)다.** `HANDLER_PRIORITY_FALLBACK` 상수도 `Dispatch.addHandler`도
M3에서 처음 생기므로, M2(반응형 코어)에서 본체를 짤 때는 **핸들러 정의만
준비해두고 등록 호출은 미룬다** — `ROADMAP.md` M3의 "Observer/Effect 동적
경로 가드 등록" 체크박스가 그 자리다(2026-08-24 마일스톤 순서 교체의 산물,
M2가 M3에 개념상 지던 유일한 의존이라 이쪽으로 미뤄졌다).
**[2026-08-31 M3 단위 4] 그 등록은 완료됐다** — `Dispatch/Leaf.luau`가
등록하며(`spec.leaf.luau` 6이 메시지·blame 실측), 해당 체크박스는 `[x]`다.
 `EffectHandle`도
children 배열 리터럴 전용이라, 해시 파트 named 자리 등으로 동적으로
흘러들어오면 명확히 에러내야 함 — `{ priority = HANDLER_PRIORITY_FALLBACK,
isHandlable = function(inst,k,v) return isEffect(v) end, process =
function(inst,k,v) Err.errorBefore(`Effect binding should be array index
item, but got {typeof(k)}`, SURFACE) end }`(**[2026-08-18]** 에러 메시지에
실제 `k` 타입을 실을 것 — `base/source-state-plan.md`의 "동적 경로 가드"
절; **[2026-08-31 단위 4]** error 발화는 `H-231` 워커의 최외곽 스캔 —
같은 절의 논증 참고, `Err`/`SURFACE` 표기의 정의는 `base/architecture.md`의
"error 계약" 절).
`FALLBACK`인 이유도 동일 — 하드 블록이 아니라 나중에
named 자리 바인드 같은 실제 기능이 확정되면 평범한 우선순위의 Handler로
값싸게 override 가능한 자리로 열어둠.

**보강 — `EffectHandle`의 내부 Observer 바인딩 세부** — **⛔ [2026-08-25
폐기, 7라운드 `H-58`/`H-59`; 2026-08-27 `archive/`로 이전, 9라운드 `H-130`]**
옛 모델(`_observers` 배열 + `bindLifetime`/`:Subscribe()` cascade)의 원문은
`archive/effect-internal-observer-cascade-reversed.md`. 위 "확정 구조 — 강한
주인은 항상 `Effect`" 절이 정반대로 확정했고, 배너 아래 죽은 문단이 두 번
살아 있는 문장처럼 편집되는 사고가 나서(그 파일 머리) 본문에서 뺐다.

**Observer 자체에 cleanup 반환 계약을 추가하는 안은 여전히 기각** — React
`useEffect`식으로 `fn`의 반환값을 자동으로 배선해주는 안을 검토했으나,
클로저 업밸류로 이미 충분해 채택 안 함. 이 기각은 위 Effect 설계와
상충하지 않음(그때 기각한 건 "Observer 자체에 이 복잡도를 넣지 말자"였지
패턴 자체의 무용함이 아니었고, `Effect`가 opt-in 상위 계층으로 정확히
이 패턴을 제공함) — 상세 경위는 `archive/observer-cleanup-contract-rejected.md`
참고.

## `EffectHandle:Subscribe()`/`:Unsubscribe()` — leaf 없이 쓰는 독립 Effect (2026-08-07 일곱 번째 세션)

**동기**: 지금까지 Effect의 유일한 생애주기 경로는 children 배열의 leaf
부착뿐이었음 — leaf 없이 `Effect(fn)`/`Effect(fn, state)`를 호출하면
설치(1회 실행)는 되지만 반환된 `EffectHandle`엔 아무 인터페이스도 없어서
cleanup을 트리거할 방법이 없는 막다른 길이었음. `state:Observer(fn)`가
이미 `:Subscribe()`/`:Unsubscribe()`(위 bind-system-plan.md 절)로 "children
배열 밖, 모듈/스크립트 레벨에서 독립적으로 켜고 끄는" 경로를 갖고 있는데,
Effect도 모듈/스크립트 사이드 이펙트(백그라운드 시스템, non-UI 코드가
quad의 반응형 그래프/cleanup 인체공학만 재사용하는 경우)로 쓰일 수 있어서
같은 결로 필요 — `Effect`도 leaf 없이 독립적으로 켜고 끌 수 있어야 함.

**확정**: `EffectHandle`에도 `:Subscribe()`/`:Unsubscribe()` 추가, 둘 다
`self` 반환(Observer와 동일한 fluent 대칭).

**⭐ [2026-08-27 확정, 9라운드 `H-127` → 같은 날 (b)로 정정] 의사코드 — 네
진입점은 `EffectHandle` 자기 것**(Observer와 같은 레지스트리·같은 `canBound`
게이트를 쓰되 함수 본문은 공유하지 않는다 — 아래 블록 머리 주석), **`Unsubscribe`는
게이트를 *통과한 뒤* cleanup을 덧붙인다.** 아래 산문(번호 목록)은 이 블록을 풀어
쓴 것이고, **순서는 이 블록이 정본**이다.
산문의 번호 순서(플래그 → cleanup → fail-fast)대로 짜면 leaf 바인딩된 핸들에
`:Unsubscribe()`를 불렀을 때 **cleanup을 소진한 뒤에야 error**가 나서 `E-11`이
막으려던 피해(cleanup 앞당김, `_rerunRequired = true`)가 이미 일어난 뒤다 —
Observer 쪽 의사코드는 가드가 첫 줄이라 이 문제가 없었다.

```lua
-- ⭐ [2026-08-29 `H-174`/`H-194`] 이 블록은 `Effect.Init(module)`이 만드는 **인스턴스별 임플 팩토리
-- 안**이다 — `Subscribed`/`WeakSubscribed`는 `Observer.implFor(module)`에서 받은 그 인스턴스의
-- 레지스트리이고, `canBound`는 `module.canBound`(인스턴스 필드, 발화 시점에 읽음)다.
-- ⭐⭐ [2026-08-27 확정 (b), 9라운드 `H-144` 후속 — 감사 4라운드] **`EffectHandle`은
-- 네 진입점을 자기 것으로 가진다 — Observer의 함수 본문을 배정하지 않는다.**
-- 공유하는 건 **레지스트리 두 개**(`Subscribed`/`WeakSubscribed`, 소유 모듈은
-- `Observer.luau` — `H-99`)와 **`canBound` 게이트**(quad 인스턴스의 필드 —
-- `module.canBound`, `H-174`; 한때 "`LifetimeHandle.luau`의 탑레벨 함수"라 적었다)뿐이고,
-- `.Subscribed` 플래그의 뜻도 같다. 여기 한때(Q4/`H-127`)
-- `EffectHandle.Subscribe = Observer.Subscribe`처럼 **함수 객체를 그대로 배정**해
-- 뒀는데, `Observer:Subscribe`의 본문이 `self:WeakSubscribe()`로 **콜론 위임**하는
-- 탓에 `self`가 `EffectHandle`이면 그 조회가 `EffectHandle`의 오버라이드로 가서
-- 재구독 꼬리가 두 번 돌고, 첫 번째는 강한 킵이 서기 **전에** `Rerun`했다
-- (로컬 `luau`로 재현; 당시엔 `fn` 안 `self:Unsubscribe()`가 허용돼 그 자리에서
-- error까지 났다 — 그 허용은 `H-147`로 폐기). **사용자 확정**: *"b가 맞아. 내 머리에서 나왔던
-- 처음 구조는 그것이였어. … '하나의 무언가가 두 일을 동작하지 않는가에
-- 유의하자' — 이것도 마찬가지야. 버그를 유발하기 좋은 포인트였고"* —
-- Observer와 Effect는 이질적 타입이라(생성 방법부터 다르다) 본문을 섞지 않는다
-- (`conventions.md`의 "설계 원칙" 절에 원칙으로 승격). 등록되는 건 **핸들
-- 자신뿐**(내부 Observer·`Ref` 콜백은 생성자에서 이미 `Weak*`로 걸려 있다,
-- `H-59`). 레지스트리 두 테이블을 `Effect.luau`가 어떻게 받는지(모듈 내부
-- export, 공개 API 아님)는 구현 세부 — 이름은 구현 시.

-- ⭐ [2026-08-27 확정, 9라운드 `H-144`] 구독 둘은 등록 뒤 leaf 재바인드
-- (`_bindDestroying`, `H-65`)와 **정확히 같은 꼬리**를 붙인다. `Unsubscribe`로
-- cleanup을 소진한 핸들을 다시 `Subscribe`하면 `.Subscribed = true`만 서고 `fn`이
-- 안 돌아, deps 없는 Effect는 레지스트리가 살려두는 죽은 핸들(누수)이 되고
-- deps 있는 것은 다음 emit까지 죽어 있었다. **[2026-08-28 `H-151`]** 한때 여기
-- `_epochs:Refresh()`를 먼저 불러 "dep이 변했으면"까지 재실행했는데 폐기 —
-- `_epochs`는 emit을 받을 때만 갱신한다(`_bindDestroying`의 같은 주석). 재구독 뒤
-- 게이트 유보가 풀리며 같은 값으로 `fn`이 한 번 더 도는 것은 **정상 재실행**
-- (사용자: *"처음 생성할 때에도 Block 되어있던게 나중에 다시 들어오는 경로가
-- 있어. 그 경우도 그냥 재실행 해주지."*). Blocker는 안 쓴다 — dep을 다시
-- 등록하지 않으므로(생성자에서 한 번, `_deps` 강참조 유지) 억제할 발화가 없다.
local function resubscribeTail(self)
    if self._rerunRequired then        -- 소진됐거나 죽어 있는 동안 변경이 홀드됐으면 1회(`H-159`).
        self:Rerun()                   --   등록 뒤라 공개 `Rerun`의 게이트를 통과한다
    end
end

-- ⭐⭐ [2026-08-28 확정, 10라운드 `H-147`] **네 진입점(과 `_bindDestroying`) 첫 줄에
-- 가드** — `fn`/cleanup은 자기 구독을 바꿀 수 없다(위 `Rerun` 정의의 (A)). 보는
-- 플래그는 둘: `_running`(`fn` 실행 중)과 **`_cleanupRunning`**(cleanup 실행 중 —
-- 감사 2라운드에서 신설, `_consumeCleanup` 참고). **`error`는 헬퍼가 아니라 각
-- 본문에서 던진다** — 헬퍼 안의 `error(…, 2)`는 헬퍼의 호출 줄(quad 내부)을
-- 가리켜 `H-104` level 계약을 어긴다(`/code-review` 지적, `H-149`와 같은 이유).
local function isRunning(self)         -- 술어만 헬퍼로 — `error`는 각 본문에서(`level 2`)
    return self._running or self._cleanupRunning
end

-- 꼬리는 항상 **등록이 전부 끝난 뒤** 한 번 — `Subscribe`는 `WeakSubscribe`를
-- 부르지 않고 등록 세 줄을 자기 안에 펼쳐 쓴다. 위임하면(콜론이든 dot이든)
-- 꼬리가 강한 킵 **앞**에서 돌거나 두 번 돈다 — 감사 4라운드가 잡은 바로 그
-- 모양이다. 게이트·메시지 분기는 Observer의 것과 같다(`lifecycle-pattern.md` (2) —
-- **[2026-08-28 `H-149`]** Observer 쪽도 같은 이유로 위임을 풀고 인라인했다).
function EffectHandle:WeakSubscribe()
    if isRunning(self) then error("cannot change subscription from inside fn or cleanup", 2) end  -- `H-147`
    if not module.canBound(self) then
        error(if self.Subscribed then "already subscribed" else "already bound to an Instance", 2)
    end
    self.Subscribed = true
    self._dying = false                        -- ⭐ [2026-08-31 `H-182`] 실행 가능성을 재무장하는 모든 자리가 내린다
    WeakSubscribed[self] = true
    resubscribeTail(self)
    return self
end

function EffectHandle:Subscribe()
    if isRunning(self) then error("cannot change subscription from inside fn or cleanup", 2) end  -- `H-147`
    if not module.canBound(self) then
        error(if self.Subscribed then "already subscribed" else "already bound to an Instance", 2)
    end
    self.Subscribed = true
    self._dying = false                        -- `H-182`
    WeakSubscribed[self] = true
    Subscribed[self] = true                    -- 강한 킵이 선 **뒤에** 꼬리 한 번
    resubscribeTail(self)
    return self
end

function EffectHandle:WeakUnsubscribe()        -- 관대(`H-133`) — cleanup 안 건드림
    if isRunning(self) then error("cannot change subscription from inside fn or cleanup", 2) end  -- `H-147`
    if Subscribed[self] ~= nil then
        error("subscribed strongly; use :Unsubscribe()", 2)
    end
    WeakSubscribed[self] = nil
    self.Subscribed = false
    return self
end

function EffectHandle:Unsubscribe()
    if isRunning(self) then error("cannot change subscription from inside fn or cleanup", 2) end  -- `H-147`
    if Subscribed[self] == nil then            -- ⭐ 게이트가 **먼저** — 강하게 구독된 적 없으면
        error("not subscribed strongly; use :WeakUnsubscribe()", 2)  --   (leaf 바인딩·약한
    end                                        --   구독·미구독) 여기서 error, cleanup엔 손도
    Subscribed[self] = nil                     --   안 댄다(`E-11`).
    WeakSubscribed[self] = nil
    self.Subscribed = false                    -- 향후 재실행 차단
    self:_consumeCleanup()                     -- 통과했을 때만: 직전 cleanup 정확히 1회, `_rerunRequired = true`
    return self
end
```

- **`WeakUnsubscribe`는 cleanup을 소진하지 않는다** — 약한 구독은 "GC에
  맡기는" 경로라 해제가 곧 종료 신호가 아니다. 종료 신호는 강한 구독의
  `Unsubscribe`와 leaf 사망(`unbindLifetime`의 훅) **둘뿐**(**[2026-08-28
  `H-147`]** 2026-08-27에 잠깐 "`fn` 안 자기 해제"가 셋째로 있었으나 그 허용
  자체가 폐기됐다).
- **`fn` 안에서 허용되는 핸들 호출은 `self:Rerun()`뿐이다** — 자기 구독을 바꾸는
  넷(`Subscribe`/`WeakSubscribe`/`Unsubscribe`/`WeakUnsubscribe`)은 `_running`
  가드가 error로 막는다(**[2026-08-28 `H-147`]** 위 `Rerun` 정의 (A)). cleanup
  안에서도 같다 — 어느 자리(`Rerun` 루프·`Unsubscribe`·leaf `Destroying`)에서 돌든
  `_cleanupRunning`이 서 있어 같은 가드가 먼저 걸린다.
- 실측(9라운드 `core9.luau`, `t12` 매트릭스 — **당시 함수 배정 형태에서의 실측**이고
  (b) 재작성 뒤 재실행하지는 않았다[2026-08-27 기준]; 게이트 순서는 그대로라
  같은 결과가 나올 것으로 추정할 뿐, 확정 근거는 M2 구현 테스트가 될 것): leaf 바인딩된
  핸들의 `:Unsubscribe()`가 cleanup을 건드리지 않고 error, `:Subscribe()`
  후 `:Unsubscribe()`는 cleanup 1회 — 전부 기대대로.

- **`:Subscribe()`** — Observer가 쓰는 것과 같은 강참조 레지스트리에
  **핸들 자신**을 등록 — 새 메커니즘 아님, 기존 레지스트리 재사용. 이후
  로컬 변수로 참조를 안 들고 있어도 계속 살아있음(Observer와 동일 관용구).
  - **⭐ [2026-08-25 확정, 7라운드 `H-59`] "핸들 자신이냐 내부 Observer냐"는
    더 이상 구현 세부가 아니다 — 핸들 자신이다.** 옛 서술은
    *"자신(또는 `state` 있는 경우 내부 Observer)"*, *"`handle._observers`만으로
    충분한지는 구현 세부"*였는데, `H-7`/`H-11`이 **핸들 자신의 생존 판정**에
    의존하는 배선을 추가하면서 그 선택이 계약이 됐다. 내부 Observer만
    등록하면 (a) `handle.Subscribed`가 안 세워져 `canExecute(handle)`이
    영원히 거짓이고, (b) deps 없는 `Effect(fn):Subscribe()`는 등록할 게
    아예 없어 핸들이 GC되고 cleanup이 유실된다.
  - **`:Subscribe()`가 등록하는 것은 그것 하나뿐이다** — 내부 Observer와 `Ref`
    콜백은 **생성자에서 이미 `Weak*`로 걸려 있다**(위 "확정 구조" 절).
    `Subscribed = true`가 서는 순간 `canExecute(handle)`이 참이 되어 그
    경로들이 살아난다. **[2026-08-27 `H-144`]** 등록 뒤 꼬리로 `_rerunRequired →
    Rerun`이 붙는다(위 의사코드) — 소진된 뒤의 재구독은 재설치, **[2026-08-28
    `H-159`]** 생성과 `Subscribe()` 사이에 온 변경도 `rawRerun`이 홀드해 뒀다가
    여기서 1회 따라잡는다(첫 구독이라도 그 사이 변경이 없었으면 no-op).
  - **⚠️ 용도는 완전히 top-level(모듈/스크립트 레벨, 어떤 Instance
    생명주기에도 안 묶인) 사이드 이펙트로 한정할 것 — 특정 `inst`에
    묶인 경우엔 leaf 부착(`bindLifetime`)을 쓰지 `:Subscribe()`를 쓰지
    않는 게 정상 경로.** `:Subscribe()`를 쓰기로 했다면(top-level이든
    의도적으로 다른 경우든) **반드시 `:Unsubscribe()`로 짝을 맞춰야
    함** — 강참조 레지스트리는 quad 전역의 "정리는 기본적으로 GC에
    위임" 원칙의 **의도적 예외**라, 로컬 변수 참조를 다 놓아도(스코프를
    벗어나도) **GC되지 않고 계속 실행됨**. 이건 quad의 다른 프리미티브
    대부분이 GC-native인 것과 정반대라 혼동하기 쉬운 지점 — 사용자
    문서에 명시적으로 경고할 것(`:Subscribe()`를 부르는 순간부터 그
    핸들의 생애주기는 전적으로 수동 관리 대상이 됨).
- **⚠️ [축소, 2026-08-18 구현 전 QA] `:Unsubscribe()`는 `:Subscribe()`의
  짝이다 — leaf 바인딩된 핸들에는 적용되지 않는다.** 아래 확장된 의미는
  **`:Subscribe()`로 등록한 핸들에 대해서만** 성립한다. `:Subscribe()`를
  부른 적 없는(=leaf 바인딩된) 핸들에 `:Unsubscribe()`를 지원하면 안 되거나,
  최소한 그 경로에서 cleanup을 앞당기면 안 된다.
  **[강화, 2026-08-20 구현 전 QA 4라운드 `E-11`] "안 되거나/최소한"이 아니라
  Observer와 정확히 같은 규칙으로 통일한다 — leaf 바인딩된 핸들에는
  `:Unsubscribe()`가 아예 안 먹는다.** 사용자 지적: *"옵저버에선 leaf
  바인딩에 Unsubscribe 못 하는것 처럼, Effect 또한 리프 바인딩에 있어서는
  Unsubscribe 안 먹어야 하는거 아님?"* — 맞다. `Observer`의
  `:Unsubscribe()`가 전역 경로 전용이고 leaf 해제는 `unbindLifetime`이
  담당한다는 게 이미 확정된 규칙인데(`base/source-state-plan.md`의 "이중
  바인딩 금지" 절), `Effect`만 애매하게 열어두면 두 프리미티브의 규칙이
  갈린다. **`State<Effect>` 재-dispatch와의 상호작용도 이 통일로 같이
  닫힌다** — leaf 바인딩된 핸들엔 `:Unsubscribe()`가 아예 안 먹으므로,
  아래 dedup 시나리오(값이 안 바뀌어 retract가 no-op인데 cleanup만
  앞당겨져 Effect가 조용히 죽는 것)가 발생할 경로 자체가 없어진다. 사용자 판정: *"subscribe
  한게 아니면 unsubscribe 는 지원하면 안 되거나, 적어도 리프 바운딩에선
  그래선 안 됨 … subscribe 는 unsubscribe 의 짝이라고 생각함."*
  - **왜 위험한가**: leaf 바인딩 + `State<Effect>`/`State<Observer>`
    조합에서, 값이 실제로 안 바뀌면 **dedup 최적화 때문에 retract가 아무
    일도 안 한다**(`base/source-state-plan.md`의 "Observer/Effect Leaf
    dedup" 절의 `old ~= v`). 그런데 `:Unsubscribe()`가 cleanup을 미리
    실행해버리면 뒤이은 재-dispatch에서 **dedup 때문에 재바인딩이 안
    일어나** 그 Effect가 조용히 죽은 채로 남는다 — 의도한 동작이 아님.
  - **✅ [해소, 2026-08-21 — 구현 전 QA 4라운드 `E-10` 결론을 5라운드 `EF-3`에서
    실제로 반영] dedup 경로의 process/retract 대칭은 성립한다.** 4라운드에
    결론이 났는데 **이 문서에 반영이 누락돼 "미해결"로 남아 있던 것**을
    5라운드가 잡아냈다(그 자체가 followup의 "반영 완료" 표를 신뢰 소스로
    쓰면 안 된다는 사례 — 소스는 항상 `base/` 본문).
    - **성립하는 이유**: 핸들러가 **이전 값(`old`)을 `Relate`로 직접 들고
      있고**, `process`의 `if old ~= v then ... end`와 클로저의
      `if nextValue ~= v then ... end` **두 분기 안에서만** bind/unbind가
      일어난다. 값이 같으면 retract도 아무것도 안 하고(= `old`를 지우지
      않는다) `process`도 조회해서 같으면 그대로 넘어간다 — 양쪽이 같은
      비교식을 쓰므로 한쪽만 도는 상태가 안 생긴다. **사용자 서술**(2026-08-20):
      *"relate 로 effect 핸들러 쪽에서 old 값을 직접 들고 있어야 하고 dedup
      이면 retract 에서 old 를 안 지워주고 process 로 조회해보고 같으면
      dedup 되어야하는듯."*
    - **⛔ [2026-08-25 폐기, 7라운드 `H-58`/`H-59`] `EF-5`의 "내부 Observer
      cascade도 그 분기 안에" 요구는 사라졌다.** 원문은 *"`EffectHandle`은
      자기 자신뿐 아니라 `handle._observers`까지 같이 bind/unbind해야 하는데,
      그 cascade가 dedup 분기 밖에 있으면 handle과 내부 Observer의 바인딩
      상태가 갈린다"*였는데, **`bindLifetime`/`unbindLifetime`이 이제 핸들
      하나에만 적용되고 cascade 자체가 없다**(위 "확정 구조" 절,
      `_observers` 필드도 `_deps`로 통합돼 폐기). 갈릴 상태가 없으므로
      이 요구는 성립하지 않는다 — **그대로 구현하면 `nil`을 순회한다.**
    - **[2026-08-21 기준]** 남은 건 **구현 시 회귀 확인**뿐이고, 설계상 열린
      항목이 아니다.
- **`:Subscribe()`한 핸들에서는 `:Unsubscribe()`가 Observer와 같은 게이트·레지스트리
  조작을 한 뒤 cleanup 하나를 덧붙인다 — Effect 계층에서 의미가 확장됨.** Observer의
  `:Unsubscribe()`는 "미래 재실행만
  끊는다"(Observer 자체엔 정리할 상태가 없음)로 충분하지만, Effect의
  계약은 "생애주기가 끝나는 시점에 마지막 cleanup이 정확히 1회 호출된다"
  이고 leaf 사망은 그 "끝"의 신호 중 하나일 뿐이라, `:Unsubscribe()`도
  동일하게 "지금 끝났다"는 신호로 취급해야 계약이 일관됨. **순서는 위
  의사코드가 정본이고 아래 번호는 그 순서 그대로다**(**[2026-08-27
  `/code-review high` 재정렬]** 옛 목록은 플래그 → cleanup → fail-fast 순이라
  leaf 바인딩된 핸들에서 cleanup을 소진한 뒤 error가 났다):
  1. **게이트 — fail-fast.** 강하게 구독된 적 없는 값(leaf 바인딩·약한
     구독·미구독)이면 여기서 error, cleanup엔 손도 안 댄다(`E-11`).
     **[2026-08-26 정정, `/code-review high` 7차]** 옛 "idempotent"는 폐기됐다
     (`base/lifecycle-pattern.md`의 "(2) 전역 경로" 절 — 6차가 같은 문장을 두
     문서에서 지웠는데 이 세 번째 사본을 놓쳤었다).
  2. **강한 킵 해제 + `handle.Subscribed = false`.** 이것만으로 향후 재실행이
     끊긴다 — `canExecute(handle)` 게이트가 곧바로 거짓이 되므로. **[2026-08-25
     정정, 7라운드 `H-58`/`H-59`]** 옛 문장 *"`state`가 있으면 내부 Observer도
     `:Unsubscribe()`해서"*는 틀렸다 — 내부 Observer는 생성자에서
     `:WeakSubscribe()`로 걸리고 **해제하지 않는다**(위 "확정 구조" 절), 단수
     `state` 전제도 `...deps`로 대체됐다.
  3. **직전(또는 유일한) cleanup을 정확히 1회 호출** — leaf가 죽을 때
     하던 것과 정확히 같은 이벤트를 수동으로 앞당기는 것. **이후 leaf가 실제로
     죽어도 cleanup이 중복 호출되면 안 됨** — 새 메커니즘 불필요,
     `canExecute(value)` liveness 체크가 자동(리프=gcconn 참조)/수동(전역=
     `Subscribed` 필드) 두 경로를 하나의 게이트로 OR 묶어주므로 여기 그대로
     얹힘.
- **`state` 없는 mount-only Effect엔 특별한 분기 불필요** — install은 이미
  `Effect(fn)` 호출 시점에 끝나 있으므로, `:Unsubscribe()`는 그냥 "지금
  leaf-사망 cleanup을 수동으로 트리거"하는 것과 완전히 동치.
- **leaf 부착과 `:Subscribe()`를 동시에 쓰는 건 UB — 정정(2026-08-07
  일곱 번째 세션 후속)**: 처음엔 "같은 liveness 게이트를 공유하니
  동시에 써도 안전"으로 적었으나, 애초에 한 핸들은 라이프사이클 바인딩
  경로를 하나만 가져야 한다는 게 맞는 방향이라 판단이 뒤집힘 — 상세
  규칙과 `canBound(value)` 기반 즉시-에러 메커니즘(구 가칭 `Bound`
  플래그 → 2026-08-09 세션에 `canBound`로 명명 → 2026-08-14 다섯 번째
  세션에 `canBound` 폐기, `canExecute`로 통합 → **같은 날 열한 번째
  세션에 `canBound`가 별도 진입점으로 재도입**, 판정 로직은
  `canExecute`와 공유)은 `base/source-state-plan.md`의 "이중 바인딩
  금지" 절 참고. **[정정,
  2026-08-09 여섯 번째 세션] leaf 부착 후 조기 해제는 `:Unsubscribe()`가
  아니라 `unbindLifetime(value)`** — leaf 부착 자체가 내부적으로
  `bindLifetime(inst, value)` 호출이라, 그 해제도 짝인 `unbindLifetime`
  전용(`:Unsubscribe()`는 `inst`를 몰라 대신 처리 못 함) — 금지되는 건
  여전히 `:Subscribe()`(전역 경로)와 `bindLifetime`(leaf 부착 포함,
  inst-scoped 경로)을 **같이** 쓰는 것뿐.

## ⭐ `Effect(fn, ...deps)` — 여러 의존성을 직접 받는다, `Ref`도 포함 (2026-08-21 구현 전 QA 5라운드 `C-6` 확정)

**갭이 실재했다**: 지금 `Effect`는 `state` 하나만 받고, 여럿을 엮으려면
`:With`로 합쳐 하나의 State로 만들어야 한다. 그런데 **`Ref`는 State가 아니라**
(`:Callback`만 있고 emit이 없다) `:With`로 합칠 수가 없어서, **오늘은 `Ref`가
Effect의 의존성이 될 방법이 아예 없다.** 사용자 제기: *"Effect 가 지금은 Ref에
대해서 수행될 수가 없다. 단순히 Effect(, ...) 를 만들고 ... 요소를 With 으로
합치는게 아니라 여러 요소에 대해서 Observe/Callback 하는게 어떻겠냐."*

**확정된 계약**(전부 사용자 확인, 2026-08-21):

- **`Effect(fn, ...deps)`가 의존성을 여러 개 받고, 각각에 맞는 구독을 건다** —
  State/Source면 `Observer`, `Ref`면 `:Callback`. `:With`로 합치지 않는다.
  **[2026-08-25 정정]** 각각 `:WeakSubscribe()` / `:WeakCallback()`으로
  걸고, 강한 주인은 `Effect._deps`다(위 "확정 구조" 절).
- **⭐ [2026-08-25 확정, 7라운드 `H-70`] deps 검증** — 지금까지
  비어 있던 세 자리를 정한다.
  - **`nil` dep은 error.** `{...}` + `ipairs`로 순회하면 `nil` 구멍 뒤가
    조용히 잘리므로 **`select("#", ...)`로 돌아야** 한다.
  - **State/Source/`Ref`가 아닌 값은 error.** `H-40`이 `:List`의 요소
    검증을 블랙리스트에서 화이트리스트로 뒤집은 것과 같은 성격이다 —
    이물 dep은 전파할 것이 없으므로 조용히 무시하면 "왜 안 발화하지"만
    남는다.
  - **중복 dep은 조용히 무시**(error 아님). **사용자 근거**: *":With 이나
    시소한 연산으로 다른 State 가 된다던가 하면 deps 가 겹쳐도, 근원
    source 가 겹쳐도 에러를 안 냄. Ref 도 유사한 부분."* `Ref`가 `Epoch`로
    승격돼(`base/ref-plan.md`) `EpochMap`이 키로 dedup하므로 **공짜로**
    처리된다 — 옛 `_refCallbacks[ref] = cb` 덮어쓰기로 먼저 건 클로저가
    `Ref.Callbacks`에 남던 버그도 같이 사라진다.
  - 검증은 전부 **생성자에서 한 번만** 도므로 hot path가 아니다.
    error `level`은 **2**(사용자 입력 검증) — `base/architecture.md`의
    error 계약 절.
- **⭐ [확정, 2026-08-24 6라운드 손 트레이싱 `H-14`] `fn`의 시그니처는
  `fn(self: EffectHandle) -> ...(() -> ())` 이고(**[2026-08-25 `H-95`]** 가변
  반환 팩으로 정정 — 옛 `-> (() -> ())?`는 정상 용례를 막았다), `...deps`는 의존성 선언일 뿐
  `fn`에 넘어가지 않는다.**
  **사용자 확정**: *"`Effect( fn(self: Effect)->()->(), ...deps )` 가 맞는듯.
  Observer 처럼 바로 상위 state 가 있는게 아니라 Effect 를 주는게 맞아보이고,
  Compute 랑은 완전 다름. 난 그냥 `...deps` 넣는게 compute 처럼 그냥 넣을 수
  있게 하자는거였을 뿐임."*
  - **여기 원래 적혀 있던 *"인자 모양은 `:Compute(fn, ...deps)`의 선례 그대로 —
    trailing deps를 lazy 위치 인자로 콜백에 넘긴다"*는 삭제한다.** 그 선례의
    확정 시그니처는 `fn(self, previous?, ...deps)`인데 `Effect`엔 **셋 다 안
    맞는다**: `self` 자리에 올 리시버 State가 없고(자유 함수), `previous`가
    담길 캐시 슬롯이 없으며(파생값을 안 만드는 leaf), 오히려 **반환값이
    cleanup이라 의미가 정반대**다. 위쪽에 남아 있던 옛 단수 시절 표기
    `fn(state)`도 같이 폐기된다.
  - **그 따름정리로 dep 읽는 법의 비대칭 문제가 사라진다** — State/Source dep은
    `:Get()`이고 `Ref` dep은 `.Value`(`:Get()`이 없다)라, 넘겨줬다면 사용자가
    인자마다 다른 규칙을 위치로 기억해야 했다. 아무것도 안 넘기므로 그 질문
    자체가 없어지고, dep 값은 사용자가 클로저로 직접 읽는다.
  - `self`를 주는 덕에 `fn` 안에서 `self:Rerun()`에 바로 닿는다. **[2026-08-28
    `H-147`]** 단 **구독 표면 넷은 `fn` 안에서 error** — 2026-08-27에 `H-143`으로
    "`fn` 안 `Unsubscribe`(원샷)"를 잠깐 지원 대상으로 뒀으나 하루 만에 뒤집었다
    (위 `Rerun` 정의의 (A)).
- **최소 1회는 실행된다 — React `useEffect`와 동일.** 아직 안 채워진 `Ref`가
  섞여 있어도 그대로 돈다(사용자: *"최초 1회에서 어차피 if 로 확인해내게
  될것이므로 괜찮음"*). "전부 채워질 때까지 대기"는 안 한다.
- **`Ref` 의존성의 발화 시점은 `Set`될 때뿐**이다(Ref는 반복 재설정이
  가능하므로 그때마다). 채워지지 않은 상태는 발화가 아니다.
- **최초 1회를 한 번만 돌리는 장치**: 의존성마다 구독을 걸면 각 구독의 "등록
  즉시 1회 실행"이 N번 발화하므로, 등록 구간 동안 발화를 눌러뒀다가 마지막에
  한 번만 실행한다.
  **⭐⭐ [2026-08-25 정정, 7라운드 `H-58`; 2026-08-28 10라운드 `H-150` 재정정] 그
  억제는 `Effect` 내부 플래그(`_installing`)도 사적 `Blocker`도 아니라 Effect
  핸들의 `canExecute`가 한다.** 여기 한때 *"[2026-08-21 확정] 이건 `Effect` 내부
  플래그로 한다"*고 적혀 있었고 그 플래그는 생성자 구간만 덮어 바인드 구간을
  놓쳤다(`H-58`). 그 자리에 `self._blocker:On()` … `:OffWithoutEmit()`이 들어왔는데,
  생성자 안의 핸들은 아직 어디에도 안 묶여 있어 설치 발화가 전부 떨어지므로(**[2026-08-29
  `H-192` 정정]** 떨어뜨리는 건 `fire`의 `from == nil` 가드다 — `canExecute`는 `H-159` 뒤
  버리지 않고 홀드하므로 그리로 갔다면 `H-58`이 되살아난다; 실측 `Effect(fn, s1, s2, s3)`
  생성 직후 `runs == 1`·`_rerunRequired == false`) `_blocker`는 **한 번도 판정에 닿지 않았다**
  (실측 `t18`). 위 생성자 의사코드가 소스다. **`_installing`도 `_blocker`도 폐기된
  필드다.**
  (2026-08-21에 `Gate` 재사용을 접었던 근거 — *"설치 구간엔 어떤 `Set`도 안
  일어나 게이트에 쌓이는 소스가 없다"*, `base/gate-plan.md`의 8번 — 는 그대로
  유효하다 — 그래서 게이트도, 결국은 `Blocker`도 아닌 `canExecute` 하나로 족하다.)
- **⭐ [2026-08-21 해소] 의존성들이 공통 상류를 공유해도 한 파동에 `fn`은 한 번만
  돈다 — `Effect`가 자기 `EpochMap`을 하나 든다.** 갭은 실재했다: `A → b`,
  `A → c`, `Effect(fn, b, c)`에서 `A:Set()` 한 번에 `b`가 자기 observer를,
  `c`가 자기 observer를 **각각 정당하게** 깨워 `fn`이 두 번 돌았다. State 층
  dedup으론 안 접힌다 — `b`와 `c`는 서로 다른 노드라 접어줄 **공통 하류가
  없고**, 둘 다 §4의 1번 규칙에 정당하게 걸린다(`base/state-epoch-plan.md`).
  위의 "설치 구간 억제"도 이건 안 덮는다(그건 등록 시점만).
  - **확정된 해법**: `EffectHandle`이 `EpochMap`을 **하나** 들고, 각 내부
    Observer의 클로저가 받은 `from`으로 그걸 `Update`한다. **`true`일 때만
    `fn`을 부른다.** `Effect`가 곧 그 dep들의 **공통 하류**가 되므로, 한
    파동에 몇 개가 깨우든 첫 번째만 통과한다.
    > **⛔⛔ [2026-08-26 폐기, 8라운드 `H-107`/Q2-후속] 아래 "공통으로 거는
    > 클로저" 한 벌은 옛 모델이다.** dep 종류마다 콜백 계약의 **자리 수가
    > 다르므로**(`Ref`는 `fn(value, ref)`로 출처가 2번째, Observer는
    > `fn(targetState, self, emitFrom)`로 3번째) 하나로 못 합친다 —
    > `onRefFire(_, ref)` / `onStateFire(_, _, from)` 둘로 갈라졌다. 확정
    > 의사코드는 위 "확정 구조 — 강한 주인은 항상 `Effect`" 절의 생성자
    > 블록이 소스. **이 절이 확정한 것 중 살아 있는 것은 `EpochMap` 하나로
    > 다이아몬드를 접는다는 결론과, 바로 아래 ⚠️의 순서 제약뿐이다**(그
    > 본문은 지금 `fire(from)` 공통 함수 안에 그대로 들어가 있다).
    ```lua
    -- ⛔ 옛 모델(2026-08-21). 지금은 dep 종류별로 클로저가 둘이다.
    function(self, from)
        if not canExecute(handle) then return end   -- 발화 게이트
        if handle._blocker:IsOn() then return end   -- 등록 구간 억제 (⛔ `_blocker`는 `H-150`으로 제거)
        if handle._epochs:Update(from) then
            handle:Rerun()   -- 직전 cleanup 호출 후 fn 재실행
        end
    end
    ```
    **⚠️ 억제 확인이 `Update`보다 먼저여야 한다** — 등록 시점의 즉시 1회
    실행에는 `from`이 없어서(`nil`, `base/source-state-plan.md`의
    "`state:Observer(fn)`" 절) `Update(nil)`이 들어가게 된다. 순서를 뒤집으면
    설치 발화가 맵을 건드려 **그 파동의 첫 진짜 emit이 접힐** 수 있다
    (2026-08-21 커밋 전 `/code-review high` 발견). **[2026-08-25]** 플래그가
    `_blocker:IsOn()`으로 바뀌었을 뿐 순서 제약은 그대로였고, **[2026-08-28
    `H-150`→`H-159`]** 지금은 `fire`가 `Update`를 **먼저** 하므로 설치 발화는
    명시적 `from == nil` 가드가 `Update` 앞에서 거른다(같은 제약, 자리만 바뀜).
  - **⭐ [2026-08-25 정정, 7라운드 `H-58`] `Ref` 의존성도 이 맵에 낀다** —
    여기 한때 *"`Ref`는 `Epoch`가 아니고 `:Callback`으로 발화하므로 `from`이
    없다"*고 적혀 있었는데, **`Ref`가 `Epoch`로 승격**되며(`base/ref-plan.md`)
    공개 `.Revision`을 갖게 됐다. 그래서 `_epochs`가 State/Source/`Ref`를
    **같은 방식으로** 담고(**⚠️ [2026-08-25 정정]** 한때 여기 "State/Source/
    `Ref`를 균일하게"라 적었는데 **`State`는 `Epoch`가 아니다** — 등록이
    `isEpoch`로 갈려 `Source`/`Ref`는 `:Sync`, `State`는 `:TrackFrom`이다,
    `base/state-epoch-plan.md` §4·§8), 같은 `Ref`를 두 번 dep으로 넣어도 키 dedup으로 접힌다
    (`H-70`). `Ref`가 반복 재설정마다 도는 계약 자체는 안 바뀐다 — 리비전이
    매번 갱신되므로 `Update`가 매번 `true`다.
  - **검토했다 접은 대안**: deps를 하나의 파생 노드로 수렴시켜 다이아몬드
    dedup에 태우기 — 노드가 늘고 "N deps → N observers" 구조를 바꿔야 해서
    위 안보다 못하다. `useEffect`처럼 "N번 돌아도 무방"으로 계약을 느슨하게
    두는 선택지도 있었으나, 접는 비용이 맵 하나뿐이라 채택 안 함.
  - 근거 기록은 `reference/epoch-brand-composition.md`(이 갭이 `EpochMap`
    분리의 직접 발단이었다).
- **leaf dedup/cascade가 전부를 덮어야 한다** — 의존성이 N개면 내부 Observer도
  N개다(위 `E-10`/`EF-5`와 같은 함정). 사용자 확인: *"어차피 모든 옵져버들이
  내부에 들어가 있을것이므로 가능하다."*
  **⭐ [2026-08-25 정정, 7라운드 `H-58`/`H-59`] 다만 그 "전부"를 덮는 주체는
  bind/unbind cascade가 아니다** — `bindLifetime`/`unbindLifetime`은 이제
  **핸들 하나에만** 적용되고, N개 dep의 발화 여부는 `canExecute(handle)`
  하나가 전담한다(위 "확정 구조" 절). 등록도 생성자 한 곳에서 끝난다.

**우선순위**: 새 코어 메커니즘이 아니라 `Effect` 표면 확장이므로 M2의
`Effect` 구현과 같이 간다. **[2026-08-21]** 여기 있던 "억제 장치 때문에
`Gate`보다 뒤"라는 순서 제약은 **없어졌다** — 억제가 `Gate`에 안 걸린다.
**[2026-08-25 정정]** 억제 수단이 내부 플래그에서 **사적 `Blocker`**로
바뀌었으므로 선행은 `Blocker`의 기본 메커니즘(`On`/`Off`/`IsOn`/
`OffWithoutEmit`)이다 — 그건 `GateNode`/`:Policy`와 무관하게 독립 완결이라
`Gate`보다 뒤일 필요는 여전히 없다(`ROADMAP.md` M2의 그 각주).

## 해결됨 — Effect/Observer 관계 (2026-08-07 여섯 번째 세션, 이전 미해결 절 대체)

**과거 미해결이었던 두 질문 모두 확정**:
1. Effect는 자유 함수로 확정(`state:Effect(fn)` 메소드 아님) — 위 "Effect와
   Observer의 관계 확정" 절 참고. `state` 인자가 있어도 실제 leaf 생명주기
   바인딩을 `state`가 소유하지 않아서 메소드로 만들 필연성이 없었음.
2. `state:Observer(fn)`는 등록 즉시 1회 실행되는 것으로 확정(`base/
   bind-system-plan.md`의 Observer 절 참고) — 이 덕에 Effect가 `state`를
   받을 때 Observer를 그대로 조합해 재사용할 수 있게 됨(별도 "설치 시
   1회 실행" 로직을 Effect가 따로 만들 필요 없음).

`.claude/question.md`의 관련 항목도 해소됨으로 갱신 완료(그 항목은
이후 `archive/question-resolved.md`로 이전).
