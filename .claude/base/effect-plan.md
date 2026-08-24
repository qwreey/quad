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
표기다** — 확정 시그니처는 **`fn(self: EffectHandle) -> (() -> ())?`**이고
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
   나아보입니다."* — `bindLifetime`은 이미 `handle._observers`로 cascade하며
   값을 들여다보는 자리이므로, 그 옆에 `Destroying` 배선을 두는 게 새 층을
   만드는 것보다 낫다.
   - **한때 근거로 든 *"게이트는 값 타입을 안 가린다"*는 이 자리에 안 맞는
     인용이었다** — `base/source-state-plan.md`의 그 절이 말하는 건
     **`canBound` 판정**이 `:Subscribe()`/`bindLifetime` 두 진입점에서 같다는
     것이지, `bindLifetime`의 **부수 배선**이 값 종류를 못 본다는 게 아니다.
     실제로 그 함수는 이미 `Effect`면 내부 Observer로 cascade한다.
2. **`unbindLifetime`은 cleanup을 부르지 않는다.** `Destroying` 커넥션을 끊고
   **`Ref` 콜백도 같이 해제**하되(아래 `H-7` 절과 대칭), cleanup은 그대로
   남긴다 — `destroySlotTree`가 `_detachCleanup`을 `unbindLifetime`하며 달아둔
   주석(*"이미 손으로 비웠으니 Effect는 할 일 없음"*)과 `E-11`(leaf 바인딩엔
   `:Unsubscribe()`가 안 먹는다)이 그 전제 위에 서 있다. **이 계약을 명시한다** —
   지금까진 어느 쪽도 안 적혀 있었다.
   - **bind/unbind가 대칭이라 포탈이 자연히 성립한다** — 언마운트가 콜백을
     떼고 재마운트의 `bindLifetime`이 다시 건다(`_observers` cascade와 같은 결).
3. **cleanup은 `handle._cleanup` 필드에 보관한다.** `Rerun`이 이미 직전
   cleanup을 필요로 하므로 필드 쪽이 자연스럽고, `Destroying` 클로저와
   `Rerun`이 같은 자리를 읽게 된다.

**의사코드 — `bindLifetime`이 부르는 두 훅**(**[2026-08-24 신설]** 감사 3라운드가
*"호출부만 있고 정의가 없다"*고 지적해 보강. 다른 신설 헬퍼는 전부 바디가
있는데 이 둘만 산문뿐이었다):

```lua
-- quad-base, Effect.luau — `base/lifecycle-pattern.md`의 bindLifetime에서만 불린다.
-- 비공개(`_` 접두사): 사용자 표면이 아니라 배관이다.
function EffectHandle:_bindDestroying(inst)
    -- 재바인드(포탈 재마운트)면 옛 연결부터 끊는다 — 멱등.
    self:_unbindDestroying()

    -- (1) leaf가 죽는 순간 cleanup을 정확히 1회. `LP-2`가 확정한 유일한 훅 지점.
    self._destroyConn = onDestroying(inst, function()
        self:_unbindDestroying()          -- 자기 연결/콜백을 먼저 정리(재진입 방지)
        local cleanup = self._cleanup
        self._cleanup = nil               -- 두 번 안 불리게
        if cleanup then cleanup() end
    end)

    -- (2) `Ref` dep 콜백 (재)등록 — State/Source dep의 `_observers` cascade와 대칭.
    --     `unbind`가 뗐던 걸 여기서 다시 건다(그래서 포탈이 성립한다).
    for _, ref in ipairs(self._refDeps) do
        local cb = function(value)
            -- ⭐ 발화 게이트 — State dep이 전파 루프에서 `canExecute(observer)`로
            -- 걸러지는 것과 같은 자리(아래 `H-7` 절). 해제가 늦거나 누락되는
            -- 창을 이게 덮는다.
            if not canExecute(self) then return end
            self:Rerun()
        end
        self._refCallbacks[ref] = cb      -- 해제 때 정확히 이 클로저를 떼려면 보관해야 함
        ref:Callback(cb)
    end
end

function EffectHandle:_unbindDestroying()
    if self._destroyConn then
        self._destroyConn:Disconnect()
        self._destroyConn = nil
    end
    for ref, cb in pairs(self._refCallbacks) do
        ref:Uncallback(cb)                -- `base/ref-plan.md`의 신설 표면(`H-7`)
        self._refCallbacks[ref] = nil
    end
    -- **`_cleanup`은 안 부른다** — 위 2번 계약. 여기서 부르면 `destroySlotTree`가
    -- `_detachCleanup`을 손으로 비운 뒤 unbind하는 경로에서 이중 호출이 된다.
end
```

- **`onDestroying(inst, fn)`은 백엔드 주입 op이다** — base는 `Instance`를
  모른다(`base/slot-plan.md`의 `native*` 절과 같은 이유). quad-roblox 구현은
  `inst.Destroying:Connect(fn)` 한 줄. **[2026-08-24 반영 완료]** 주입 op
  전체 목록의 단일 소스는 `base/architecture.md`의 `EngineOps.luau` 줄이고
  거기에 등재했다(`ROADMAP.md` M5 배너에도 같이 적었다) — 한때 여기
  *"`ROADMAP.md` M5에 추가할 것"*이라고만 적어 **소스를 잘못 지목**했었다.
- **필드 셋이 새로 생긴다**: `_destroyConn`(연결 핸들), `_refDeps`(생성자가
  `...deps` 중 `isRef`인 것만 모아둔 배열), `_refCallbacks`(`ref → 내가 건
  클로저`). 앞의 둘은 `_observers`와 같은 층이고, 마지막 것은 **해제 시 정확히
  자기 클로저만 떼기 위해** 필요하다(`Ref.Callbacks`가 셋이라 값으로 떼야 한다).

### ⭐ `Ref` 의존성의 해제 경로 (2026-08-24 확정, 6라운드 손 트레이싱 `H-7`)

`Effect(fn, someRef)`의 leaf가 죽어도 **`ref.Callbacks`에 클로저가 영원히
남았다** — `Ref`엔 콜백 해제 API가 없었고(`:Uncallback` 류 없음)
`canExecute` 게이팅도 안 걸린다(그건 Observer 쪽 배관이다). 그 클로저가
`EffectHandle`을 강참조하므로 누수이고, 이후 `ref:Set`마다 **이미 죽은 leaf의
직전 cleanup + `fn`을 계속 실행**한다. 같은 절이 *"leaf dedup/cascade가 전부를
덮어야 한다"*고 요구하는데 `Ref` 쪽엔 그걸 만족시킬 수단 자체가 없었다.

**확정: `Ref`에 콜백 해제 경로를 추가한다**(`base/ref-plan.md`가 소스).
`EffectHandle`은 자기가 건 `Ref` 콜백 핸들을 들고 있다가, `unbindLifetime`과
`:Unsubscribe()`에서 같이 해제한다 — `_observers`(State/Source dep)와 대칭이다.

**⭐ [2026-08-24 추가, 사용자 지적] 해제 경로만으로는 부족하다 — `Ref` 콜백도
발화 시점에 `canExecute`를 확인한다.** State/Source dep은 State의 전파 루프가
구독자마다 `canExecute(observer)`를 보고 죽은 것을 건너뛰는데(`base/source-state-plan.md`),
`Ref` 경로엔 그 게이트가 아예 없었다. 해제가 늦거나 누락되는 창이 실재한다 —
예컨대 `unbindLifetime`으로 조용히 끊긴 상태(포탈 언마운트)는 `Destroying`이
안 도는데도 `canExecute`가 거짓이다. **확정된 형태**: `Effect`가 거는 `Ref`
콜백은 본문 맨 앞에서 **자기 핸들에 대해** `canExecute(handle)`를 확인하고,
거짓이면 그대로 리턴한다. 그러면 두 dep 경로가 같은 게이트를 공유하게 되어
`Effect`의 발화 조건이 dep 종류와 무관해진다.

### 동적 경로 가드 — `k` 무관 매치, `HANDLER_PRIORITY_FALLBACK`

(2026-08-14 열한 번째 세션, `PreRef`/`Observer`와 같은 패턴, `base/
source-state-plan.md`의 "동적 경로 가드" 절 참고.) `EffectHandle`도
children 배열 리터럴 전용이라, 해시 파트 named 자리 등으로 동적으로
흘러들어오면 명확히 에러내야 함 — `{ priority = HANDLER_PRIORITY_FALLBACK,
isHandlable = function(inst,k,v) return isEffect(v) end, process =
function(inst,k,v) error(`Effect binding should be array index item, but
got {typeof(k)}`) end }`(**[2026-08-18]** 에러 메시지에 실제 `k` 타입을
실을 것 — `base/source-state-plan.md`의 "동적 경로 가드" 절).
`FALLBACK`인 이유도 동일 — 하드 블록이 아니라 나중에
named 자리 바인드 같은 실제 기능이 확정되면 평범한 우선순위의 Handler로
값싸게 override 가능한 자리로 열어둠.

**보강 — `EffectHandle`의 내부 Observer 바인딩 세부(2026-08-09 열한 번째
세션, 재확인 후 명시화)**:

**⚠️ [2026-08-24 6라운드 손 트레이싱 `H-8`] 이 문단 전체가 아직 "Observer 하나"
전제로 쓰여 있었다 — `_observer`(단수)를 `_observers`(배열)로 읽을 것.**
아래 절이 확정한 `Effect(fn, ...deps)`(N-deps)와 정면으로 어긋났고, 그대로
구현하면 **2번째 이후 dep의 Observer엔 `canExecute` 판정 근거가 아예 안 실려**
그 Observer의 재실행이 통째로 죽는다 — 바로 이 문단 자신이 경고하는 실패
모드다. 필드를 배열로 바꾸고 cascade/`Subscribe`/`Unsubscribe`를 전부 순회로
고친다(새 결정 없음, 반영 누락). `Ref` dep은 Observer가 아니라 콜백이라 이
배열에 안 들어간다 — 그쪽 해제는 아래 `H-7` 문단이 소스.

- **`EffectHandle`은 내부 Observer를 필드로 강참조** — `handle._observers[i] =
  observer`(dep이 State/Source인 경우만 존재). 이건 GC 방지가 목적이 아니라
  (그건 아래 `bindLifetime`/`gchold`가 담당) `:Unsubscribe()`/`bindLifetime`
  cascade가 이 필드를 통해 내부 Observer에 접근하기 위한 것.
- **`bindLifetime(inst, handle)`은 `state`가 있는 경우 내부 Observer도
  같은 `inst`로 `handle._observers` **전부**에 대해
  `bindLifetime(inst, observer)`를 cascade해야 함** — `Dispatch/Leaf.luau`가 children 배열의 `EffectHandle`을 매치해
  `bindLifetime(inst, handle)`을 부르는 시점(leaf 부착)과, `:Subscribe()`가
  `handle`을 전역 레지스트리에 등록하는 시점(아래) 둘 다 해당. 이유:
  `canExecute(observer)`가 보는 gcconn 참조는 **그 Observer 자신이
  `bindLifetime(inst, observer)`될 때 그 Observer 쪽 릴레이션에
  복사되는 것**이라, `EffectHandle`만 바인드하고 내부 Observer는 안 하면
  그 Observer에겐 판정 근거가 아예 없어서 `canExecute`가 항상 거짓이 됨
  (=재실행이 통째로 죽음). 같은 이유로 `unbindLifetime(handle)`도 내부
  Observer까지 같이 풀어야 대칭이 맞음.
  **[정정, 2026-08-14 다섯 번째 세션]** 이 항목이 원래 근거로 든
  "`canExecute`가 `Subscribed` 필드 + `inst`의 gcconn을 함께 본다"는
  틀렸음 — `.Subscribed`는 전역 `:Subscribe()` 전용이고 leaf 경로와
  무관(`archive/canexecute-inst-arg-reversed.md`). cascade가 필요하다는
  결론은 그대로이고 오히려 근거가 더 직접적이 됨.
- **`:Subscribe()`도 마찬가지로 `state`가 있으면 내부 Observer를 같은
  전역 강참조 레지스트리에 같이 등록**(`handle` 자신 + `handle._observers`
  전부, 또는 `handle._observers`만으로 충분한지는 구현 세부 — 어느 쪽이든
  "`EffectHandle`은 등록됐는데 내부 Observer는 등록 안 됨" 상태가 생기면
  안 됨).

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

- **`:Subscribe()`** — Observer가 쓰는 것과 같은 강참조 레지스트리에
  자신(또는 `state` 있는 경우 내부 Observer)을 등록 — 새 메커니즘 아님,
  기존 레지스트리 재사용. 이후 로컬 변수로 참조를 안 들고 있어도 계속
  살아있음(Observer와 동일 관용구).
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
    - **⭐ 단, 내부 Observer cascade도 그 분기 *안*에 있어야 한다**
      (5라운드 `EF-5`, 확인됨) — `EffectHandle`은 자기 자신뿐 아니라
      `handle._observers`까지 같이 bind/unbind해야 하는데, 그 cascade가 dedup
      분기 **밖**에 있으면 handle과 내부 Observer의 바인딩 상태가 갈린다
      (handle은 그대로인데 Observer만 풀리는 식). 구현 시 이 한 줄을 반드시
      같은 `if` 안에 둘 것.
    - **[2026-08-21 기준]** 남은 건 **구현 시 회귀 확인**뿐이고, 설계상 열린
      항목이 아니다.
- **`:Subscribe()`한 핸들에서는 `:Unsubscribe()`가 Observer의 것을 그냥
  위임하지 않는다 — Effect 계층에서 의미가 확장됨.** Observer의
  `:Unsubscribe()`는 "미래 재실행만
  끊는다"(Observer 자체엔 정리할 상태가 없음)로 충분하지만, Effect의
  계약은 "생애주기가 끝나는 시점에 마지막 cleanup이 정확히 1회 호출된다"
  이고 leaf 사망은 그 "끝"의 신호 중 하나일 뿐이라, `:Unsubscribe()`도
  동일하게 "지금 끝났다"는 신호로 취급해야 계약이 일관됨:
  1. `state`가 있으면 내부 Observer도 `:Unsubscribe()`해서 향후 재실행을
     끊고,
  2. **직전(또는 유일한) cleanup을 정확히 1회 호출** — leaf가 죽을 때
     하던 것과 정확히 같은 이벤트를 수동으로 앞당기는 것.
  3. **idempotent, 그리고 이후 leaf가 실제로 죽어도 cleanup이 중복
     호출되면 안 됨** — 새 메커니즘 불필요, Observer가 이미 확정해둔
     `canExecute(value)` liveness 체크가 자동(리프=gcconn 참조)/수동
     (전역=`Subscribed` 필드) 두 경로를 하나의 게이트로 OR 묶어주므로
     여기 그대로 얹힘.
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
- **⭐ [확정, 2026-08-24 6라운드 손 트레이싱 `H-14`] `fn`의 시그니처는
  `fn(self: EffectHandle) -> (() -> ())?` 이고, `...deps`는 의존성 선언일 뿐
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
  - `self`를 주는 덕에 `fn` 안에서 `self:Rerun()`/`self:Unsubscribe()` 같은
    핸들 표면에 바로 닿는다.
- **최소 1회는 실행된다 — React `useEffect`와 동일.** 아직 안 채워진 `Ref`가
  섞여 있어도 그대로 돈다(사용자: *"최초 1회에서 어차피 if 로 확인해내게
  될것이므로 괜찮음"*). "전부 채워질 때까지 대기"는 안 한다.
- **`Ref` 의존성의 발화 시점은 `Set`될 때뿐**이다(Ref는 반복 재설정이
  가능하므로 그때마다). 채워지지 않은 상태는 발화가 아니다.
- **최초 1회를 한 번만 돌리는 장치**: 의존성마다 구독을 걸면 각 구독의 "등록
  즉시 1회 실행"이 N번 발화하므로, 설치 구간 동안 발화를 눌러뒀다가 마지막에
  한 번만 실행한다. **[2026-08-21 확정] 이건 `Effect` 내부 플래그로 한다 —
  게이트도 `Blocker`도 안 쓴다.** 한때 *"`Blocker`의 "`state:Block()` 없이
  직접 쓰는" 용례를 그대로 재사용"*이라 적고 정확한 모양을 `Gate` 설계에
  걸어뒀는데, `Gate`가 **빈 배치일 땐 통지를 안 하는 것**으로 확정되면서
  성립하지 않는 게 확인됐다(`base/gate-plan.md`의 8번) — 설치 구간엔 어떤
  `Set`도 안 일어나 게이트에 쌓이는 소스가 없으므로 게이트가 내보낼 것 자체가
  없다. 설치 중 발화를 누르는 플래그 하나면 되고 새 메커니즘이 필요 없다.
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
    ```lua
    -- 각 dep의 내부 Observer가 공통으로 거는 클로저
    function(self, from)
        if handle._installing then return end  -- 설치 구간 억제 (아래)
        if handle._epochs:Update(from) then
            handle:Rerun()   -- 직전 cleanup 호출 후 fn 재실행
        end
    end
    ```
    **⚠️ 억제 플래그가 `Update`보다 먼저여야 한다** — 등록 시점의 즉시 1회
    실행에는 `from`이 없어서(`nil`, `base/source-state-plan.md`의
    "`state:Observer(fn)`" 절) `Update(nil)`이 들어가게 된다. 순서를 뒤집으면
    설치 발화가 맵을 건드려 **그 파동의 첫 진짜 emit이 접힐** 수 있다
    (2026-08-21 커밋 전 `/code-review high` 발견).
  - **`Ref` 의존성은 이 맵에 안 낀다** — `Ref`는 `Epoch`가 아니고
    `:Callback`으로 발화하므로 `from`이 없다. `Ref` 쪽 발화는 그대로 매번
    `fn`을 돌린다(`Ref`는 반복 재설정마다 도는 게 계약이고, 공통 상류 문제
    자체가 없다).
  - **검토했다 접은 대안**: deps를 하나의 파생 노드로 수렴시켜 다이아몬드
    dedup에 태우기 — 노드가 늘고 "N deps → N observers" 구조를 바꿔야 해서
    위 안보다 못하다. `useEffect`처럼 "N번 돌아도 무방"으로 계약을 느슨하게
    두는 선택지도 있었으나, 접는 비용이 맵 하나뿐이라 채택 안 함.
  - 근거 기록은 `reference/epoch-brand-composition.md`(이 갭이 `EpochMap`
    분리의 직접 발단이었다).
- **leaf dedup/cascade가 전부를 덮어야 한다** — 의존성이 N개면 내부 Observer도
  N개라, `EffectHandle`의 bind/unbind cascade와 dedup 분기가 **그 전부**를
  같이 처리해야 한다(위 `E-10`/`EF-5`와 같은 함정). 사용자 확인: *"어차피
  모든 옵져버들이 내부에 들어가 있을것이므로 가능하다."*

**우선순위**: 새 코어 메커니즘이 아니라 `Effect` 표면 확장이므로 M3의
`Effect` 구현과 같이 간다. **[2026-08-21]** 여기 있던 "억제 장치 때문에
`Gate`보다 뒤"라는 순서 제약은 **없어졌다** — 억제가 `Effect` 내부 플래그로
확정돼 `Gate`에 안 걸린다.

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
