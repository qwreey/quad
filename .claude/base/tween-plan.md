# Tween / 애니메이션 플러깅 (전부 확정 — `base/`로 승격)

**상태**: base — **2026-08-10 세션에서 구조 전체가 재설계됨.** 기존
"`v`가 Store인 아무 `k`나 잡는 우선순위 최상위 Dispatch 핸들러" 모델은
`research/pre-implementation-audit.md` 1-1이 지적한 구조적 모호함("애니메이션
없는 일반 반응형 프로퍼티 바인딩도 결국 이름이 Tween인 파일을 거쳐가는가")을
명확히 답하지 못했음 — 대체된 새 모델(`Tween<T>`를 PropertyHandler가
소비하는 값-레벨 래퍼로 두는 것)이 이 모호함을 구조적으로 해소함, 아래
"새 모델" 절부터가 최종 소스. **구 모델(특수 bind key `[Tween(key,
tweenData...)] = storeValue`)은 `archive/tween-special-bind-key-reversed.md`로
이전됨** — 원문/역전 사유는 거기 보존, 이 문서는 새 모델만 서술.

**2026-08-12 세션에서 옵션 값 모양+override 정책 이름+`Animate` 콤비네이터
시그니처까지 전부 확정됨**(아래 "확정: `Tween{...}` 최종 모양"/"`Animate`
콤비네이터" 절), **같은 날 후속 논의에서 `Animate`의 호출 경로가
`:Compute` 직결 → `:Apply`로 정정됨**(아래 "왜 `:Apply`로 정정됐는가" 절,
`research/operator-sugar-plan.md`와 같은 근거). **같은 날 다섯 번째 후속
논의에서 마지막 남은 질문(자연완료 시 북키핑 정리 여부)도 "정리 안 해도
됨"으로 확정**(아래 "열린 질문" 절) — 이걸로 열린 설계 질문이 없어져
`research/`에서 `base/`로 승격.
`initValue`는 사용자가 필요해지면 직접 처리하기로 확정(에이전트 작업
범위에서 제외, 아래 해당 절 참고). 원본:
`.claude/initreq/raw-userinput.md` "트윈은 어떻게 할 것이냐" / "스토어 값은
항상 먼저 캐치한다" / "네임스페이스드 객체" 절. Fusion의 Tween/Spring이
반응 그래프 안에 있는 설계는 명시적 반면교사 — `reference/
comparison-fusion-vide.md`의 "Fusion" 절 마지막 불릿("Tween/Spring이
State그래프 안의 1급 노드") 참고.

## 확정된 방향: 트윈을 Store/반응 그래프 밖에 둔다 (변경 없음)

렌더 라이브러리가 트윈을 직접 구현하는 건 처음부터 디자인이 잘못된 접근 —
렌더링 엔진(Roblox `TweenService`)의 애니메이션 관리를 전혀 안 따르게 되기
때문. quad는 트윈을 반응 그래프에 1급 노드로 편입시키지 않고, 트윈 대상
값을 감싸는 얇은 값-레벨 래퍼(아래)로만 취급한다.

**왜 이게 중요한가(Fusion 리서치에서 확인된 근거)**: Fusion은 Tween/Spring을
`GraphObject`(1급 반응 노드, `timeliness="eager"`)로 만들어서 Computed의 입력으로
자유롭게 합성 가능하게 했지만, 그 대가로 (1) 매 프레임 틱하는 외부 클럭
소스(Stopwatch/ExternalTime)를 반응 그래프에 통합해야 했고, (2) eager 재계산
노드가 무효화/전파 로직과 경쟁하게 됐고, (3) 트윈-입력 간 별도의 교차 lifetime
체크 기계장치가 필요해졌다. quad가 트윈을 값-레벨 래퍼로 빼면 이 세 가지
복잡도를 전부 피할 수 있다 — 대신 트윈된 값이 Computed류의 추가 입력으로
자유롭게 합성되진 못한다는 걸 감수(Fusion 대비 유일한 손해, 아래 새 모델에서도
그대로 유지됨 — `Tween.Value`는 plain `T`만 받고 자체 반응 경로를 안 둠).

## 새 모델: `Tween<T>` 값-레벨 래퍼, PropertyHandler가 소비 (2026-08-10 세션, 핵심 재설계)

**동기**: 기존 모델("`k`는 무엇이든, `v`가 Store인 경우를 잡는 우선순위
매우 높은 핸들러")은 State/Source 언랩(범용 StoreBind)과 Tween(실제
애니메이션, 좁고 별개인 기능)을 같은 Dispatch 핸들러 하나로 뭉쳐서,
"`Frame { BackgroundColor3 = store.color }`처럼 애니메이션 없이 그냥
반응형으로만 바뀌길 원하는 흔한 케이스가 결국 이름은 Tween인 파일을
거쳐가는지"가 문서로 답이 안 됐음.

**해소**: State/Source 언랩(`Dispatch/StoreBind.luau`, 범용·엔진무관 —
`k`/`v`의 실제 타입과 무관하게 그냥 `isState(v)`만 보고 `realv`까지
재귀적으로 풀어냄)은 완전히 별개로 유지하고, **"이 값이 트윈 대상인가"는
최종 소비자(PropertyHandler)가 `realv`를 다 풀어낸 뒤 직접 판단**한다 —
별도 Dispatch 핸들러/우선순위 경쟁이 아니라, PropertyHandler 함수 내부의
평범한 분기.

```lua
Tween(opts: {Value: T, Time: number?, Style: Enum.EasingStyle?, ...}) -> Tween<T>
```

`Store({...})`와 같은 "`Type(args)`가 테이블 인자를 받는 팩토리" 컨벤션 —
Lua 문법상 `Tween{Value=target, Time=0.3}`처럼 괄호를 생략해 호출. 정확한
필드 목록은 아래 "확정: `Tween{...}` 최종 모양" 절 참고.

**PropertyHandler.process(inst,k,realv,index)의 새 로직** — `realv`는 이미
StoreBind가 State/Source 레이어를 전부 풀어낸 뒤의 값(그리고 이 함수는
계약대로 마지막에 no-op 클로저 `Void`(**[2026-08-28 `H-162`]**)를 반환 — 아래 "왜
`retract`가 더 이상 필요 없는가" 절):

1. `isTween(realv)`가 거짓이면 — 기존과 동일하게(아래 "3-상태 저장" 참고,
   `hasBeenSet` 여부만 갱신하고) 즉시 세팅.
2. `isTween(realv)`가 참이면 — 아래 "3-상태 저장" 절의 분기를 따름.

### `Tween{...}`의 모든 필드는 plain 값만 받음 — 내부에 별도 반응 경로를 안 둠

처음엔 `Tween.Value`도 `T | State<T>`를 받아야 하나(내부에 자체 Observer를
걸어 값이 바뀔 때마다 트윈을 재시작) 검토했으나 **불필요로 확정** — 이미
바깥 `:Compute`가 소스 State 변경마다 새 `Tween{Value=v,...}` 테이블을
통째로 재생성해 StoreBind 재귀 재-dispatch 경로를 타므로, `Tween` 값
내부에 또 다른 반응 경로를 만들 이유가 없음. "같은 일 하는 두 번째 경로를
만들지 않는다"는 이 프로젝트가 Effect의 deps/Ref의 대기 경로 등에서 이미
여러 번 적용한 원칙과 정확히 같은 결.

**2026-08-12 세션에서 이 원칙을 `Value` 하나가 아니라 `Tween{...}`의
모든 필드(`Time`/`Style`/`Direction`/`Info`/`Override` 등)로 확장** — 동적으로
바꾸고 싶은 필드가 있으면 `Value`와 동일하게 바깥 `:Compute`가 `Tween{...}`
테이블 자체를 새로 만들면 되므로, 개별 필드마다 `T | State<T>`를 받아주는
길을 열어줄 이유가 없음(일관성+"두 번째 경로 없음" 원칙 재적용). 이 논의
중 "`Blocker`로 감싼 State를 옵션 필드로 읽다가 블록 중이면 어떻게 되는가"도
검토됐으나, `base/blocker-plan.md`가 이미 **"`Blocker`는 emit 전파만
지연시키고 `:Get()`엔 전혀 영향 없음 — 블록 도중이라도 `:Get()`하면 항상
그 순간 다시 계산된 최신 값을 준다"**는 걸 크로스컷팅 원칙으로 확정해뒀으므로,
설령 다른 이유로 나중에 옵션 필드가 State를 받게 되더라도 이 문제 자체가
성립하지 않음(그 원칙 자체는 안 바뀜) — 지금은 옵션 필드가 plain만 받으므로
어차피 무관한 논의.

**`Tween<T>`의 정확한 필드 목록은 아래 "확정: `Tween{...}` 최종 모양" 절
참고.**

### 3-상태 저장 — `{Tween, Value} | true | nil` (릴레이션 슬롯 하나로 `hasBeenSet` 통합)

처음엔 "첫 세팅 여부(`hasBeenSet: boolean`)"와 "실행 중인 엔진 Tween
객체"를 별도 필드로 저장하려 했으나, **하나의 릴레이션 슬롯으로 통합** —
`relate:GetStrong(inst,k)`가 돌려주는 값의 3가지 상태:

- **`nil`** — 이 `(inst,k)`가 이번 `inst`에서 한 번도 process된 적 없음
  (첫 세팅).
- **`true`** — 최소 한 번 세팅된 적 있음(직전 값이 plain이었든 `Tween<T>`
  였든 무관), 지금은 활성 엔진 Tween 없음.
- **`{Tween: TweenBase, Value: T}` 테이블** — 지금 애니메이션이 진행 중, 새
  값을 처리하기 전에 먼저 정리해야 함. **2026-08-12 세션에서 정정**: 처음엔
  엔진 `TweenBase` 인스턴스 하나만 저장하면 된다고 봤으나, 아래 "확정:
  `Tween{...}` 최종 모양" 절의 `Tween.Finish` override 옵션(트윈을 목표값으로
  스냅 후 재시작)을 구현하려면 그 목표값을 알아야 하는데 로블록스
  `TweenBase`는 자신의 목표 PropertyTable을 역으로 노출하는 공식 API가 없음
  (`:Cancel()`이 값을 되돌리지 않는 것과 같은 이유) — 그래서 세팅 시점의
  `Value`도 같이 릴레이션 슬롯에 저장해야 함. `Value`는 로블록스 프로퍼티에
  쓰이는, lerp 가능한 원시값(테이블 aliasing 걱정 없음)이라 그대로 저장해도
  안전.

**분기**:

1. **`prev == nil`(첫 세팅)** — `realv`가 `Tween<T>`든 plain이든 무관하게
   **애니메이션 없이 즉시 `Value`(또는 plain 값)로 세팅**, 슬롯엔 `true`
   저장. 엔진 기본값(예: Frame 기본 `Position`)에서 목표값으로 날아오는
   "첫 마운트 진입 애니메이션" 버그를 이걸로 방지.
2. **`prev == true`(세팅된 적 있음, 활성 트윈 없음)**:
   - `realv`가 plain 값 → 즉시 세팅, 슬롯은 `true` 유지.
   - `realv`가 `Tween<T>` → 이제 정상적으로 애니메이션 시작(현재 인스턴스
     프로퍼티 값에서 자연스럽게 출발), 슬롯에 새
     `{Tween=<새 엔진 객체>, Value=realv.Value}` 저장.
3. **`prev`가 `{Tween, Value}` 테이블(활성 트윈 있음)**:
   - **먼저 override 정책(기본 `Tween.Cancel`, 아래 절)에 따라 이전 트윈을
     정리 — 반드시 그 정리가 끝난 뒤에 새 값을 세팅한다.** 순서가 뒤바뀌면
     이전 트윈의 다음 인터폴레이션 프레임이 방금 세팅한 값을 덮어쓸
     위험이 있음(엔진 트윈은 비동기로 계속 프로퍼티를 갱신 중이므로).
   - `Tween.Cancel`(기본)이면: `:Cancel()`만 호출 — 프로퍼티는 현재
     보간되던 값에 그대로 멈춰있음, 그 값 위에서 아래 이어감.
   - `Tween.Finish`면: `:Cancel()` 후 저장해뒀던 `prev.Value`로 즉시
     스냅(로블록스 `TweenBase`가 목표값을 역으로 안 알려주므로 우리가
     들고 있던 값 사용) — 이후 아래는 이 스냅된 값 위에서 이어감.
   - 정리 후: `realv`가 plain 값이면 즉시 덮어쓰기 + 슬롯 `true`. `realv`가
     `Tween<T>`면 (정리 결과 값에서) 새 트윈 시작 + 슬롯을 새
     `{Tween=<새 엔진 객체>, Value=realv.Value}`로 갱신.
   - Tween→plain 전환은 두 옵션 모두 "정리 후 즉시 덮어쓰기"로 수렴 —
     별도 5번째 옵션 불필요로 확정(2026-08-12 세션).

**GC-안전성은 기존과 동일** — `Relate`가 `inst`로 weak-keyed되어 있어
`inst`가 죽으면 이 슬롯(엔진 Tween 객체+`Value` 포함)도 별도 정리 로직
없이 같이 GC됨. **[정정, 2026-08-12 열한 번째 세션, 2026-08-13 다섯 번째
세션에 클로저 반환 계약으로 서술 갱신]** `process`가 반환한 클로저는 store
재발행마다 항상 불리지만(`dispatch-core-plan.md` 일반 retract 계약 절
정정분 — "거의 안 불림"이었던 원 서술은 틀렸음), PropertyHandler의
그 클로저는 몸체가 no-op이라 실질적으로 하는 일이 없음 — 아래 절 참고.

### 왜 `retract`가 더 이상 필요 없는가 — Dispatch 체인 관점의 결과적 단순화

기존 모델에선 "Tween 핸들러가 매치되어 애니메이션이 실행 중이었는데,
다음 값이 더 이상 Tween 대상이 아니게 되어 일반 PropertyHandler로
핸들러 *타입*이 바뀌는" 경우가 이 문제의 대표 예시였음. 새 모델에선
**매치되는 Dispatch 핸들러가 항상 PropertyHandler 하나뿐**(Tween 여부는
값 내부 분기일 뿐 핸들러 매치 자체엔 영향 없음) — "핸들러 *타입*이
바뀌는" 시나리오 자체가 Dispatch 레벨에서 사라짐. 트윈 취소/전환은 위
3-상태 저장 로직으로 PropertyHandler 내부에서 처리. (PropertyHandler의
`process`도 **반환값(retractor 클로저) 자체는 여전히 내놔야 함** —
"반환 생략 불가"는 예외 없는 일반 규칙 — **매번 불리긴 하지만** 몸체가
no-op이라 실질적 동작이 없음, 일반 프로퍼티는 애초에 "unset" 개념이
없어서. **[2026-08-13 다섯 번째 세션]** 예전엔 별도 `retract` 필드에
대한 규칙이었던 것이 반환값 규칙으로 자리만 옮겨온 것.)

### 타입 대수: `T' = T | Tween<T>` — Modifier/State/Source에 새 타입 기계 불필요

지금 프로퍼티류 필드가 열려 있는 자리(Modifier setter, Ref, Store/Source
필드)는 전부 `T | State<T>` 모양 하나로 통일돼 있음. 여기서 "이 필드의
`T`" 자체를 `T' = T | Tween<T>`로 치환하면 자동으로 `T | Tween<T> |
State<T | Tween<T>>`가 나옴 — Modifier/State/Source/StoreBind 코드엔
`Tween` 인지 로직을 전혀 안 넣어도 됨(StoreBind는 원래도 페이로드 타입에
무관하게 `isState`만 보고 언랩하는 opaque한 구조였음). `Tween<T>`를 실제로
해석하는 코드는 여전히 PropertyHandler 하나에만 존재.

**핸들러 계층 UB 체크와도 안 부딪힘** — `Tween<T>`는 `Ref`/`Observer`/
`Slot`류처럼 dispatch 참가자(`process`를 가진 Handler에 매칭되는 값)가 아니라 `None`/
`Tag`처럼 순수 raw 데이터 값(별도 `TweenBrand`)이라, Modifier 필드/
`State<Modifier>`가 막는 "핸들러 계층 값" 규칙(`base/modifier-plan.md`)에
안 걸림 — 그 문서가 원래 Tween을 Slot/Tag/Attribute와 같은 "dispatch
참가자" 그룹으로 분류해뒀던 건 부정확했던 것으로 이번에 정정(아래
"패키지 경계" 절 참고).

## `Animate` 콤비네이터 — 확정 (2026-08-12 세션)

**동기**: `Tween{Value=..., Style=..., ...}`을 매번 손으로 `:Compute` 안에서
조립하는 건, 값(`Value`)만 바뀔 뿐 옵션(`Style`/`Time`/`Override`...)은
거의 고정인 흔한 케이스에서 번거로움. `Animate`는 이 흔한 케이스만 감싸는
얇은 sugar — 다시 보니 매우 단순해서(사용자 표현: "생각해보니 엄청
간단하다") 다음 세션으로 미룰 이유가 없어 이번 세션에 바로 확정.

**모양**: `Tween`의 옵션(`Value` 제외 전부) + `Animate` 전용 필드
`CanAnimate`(아래 절) 하나를 더해서 받되, **각 필드가 `T | State<T>`를
받을 수 있음** — `Tween{...}` 자신의 필드는 plain만 받는 것과 대조적(위
"`Tween{...}`의 모든 필드는 plain 값만 받음" 절). 모순이 아님: `Animate`가
반환하는 함수 안에서 각 필드를 **`:Get()`으로 한 번 풀어 plain 값으로
만든 뒤에만** `Tween{...}`에 넘기므로, `Tween` 쪽 불변식(plain-only)은
그대로 유지됨.

```lua
local function resolve(v)
  if isState(v) then
    return v:Get()
  else
    return v
  end
end

-- Animate(info)는 factory(self) -> State를 반환 — :Apply 전용
-- (2026-08-12 세션 후속 논의로 :Compute 직결에서 정정됨, 아래
-- "왜 `:Apply`로 정정됐는가" 절 참고)
-- [2026-08-13 13차 세션] 아래 selfH:Get()이 의존하는 :Compute의
-- self-lazy-핸들 계약은 그대로 유지로 확정됨(구 question.md 0-Y 해소)
-- — 이 구현 그대로 유효. base/typing-limits.md 참고.
local function Animate(info)
  return function(self)
    return self:Compute(function(selfH)
      local v = selfH:Get()

      local canAnimate = resolve(info.CanAnimate)
      if canAnimate == nil then
        canAnimate = true   -- CanAnimate 생략 시 기본 애니메이션 활성
      end
      if not canAnimate then
        return v   -- Tween로 안 감쌈 — 그대로 plain 값 반환(애니메이션 우회)
      end

      return Tween{
        Value = v,
        Info = resolve(info.Info),
        Time = resolve(info.Time),
        Style = resolve(info.Style),
        Direction = resolve(info.Direction),
        RepeatCount = resolve(info.RepeatCount),
        Reverses = resolve(info.Reverses),
        DelayTime = resolve(info.DelayTime),
        Override = resolve(info.Override),
      }
    end)
  end
end
```

`resolve`가 `and`/`or` 삼항 관용구가 아니라 `if-then-else`인 이유는
`base/architecture.md`의 "코드 스타일 — Luau 문법 관례" 절과 같음 —
`Override`/`CanAnimate` 등 필드가 `false`일 수 있는 값이면
`isState(v) and v:Get() or v` 식은 `v:Get()`이 falsy일 때 조용히
`v`(State 객체 자신)로 새는 버그가 됨.

**`CanAnimate: State<boolean> | boolean | nil`** — 애니메이션 자체를 켜고
끄는 필드, **생략(`nil`)이면 기본 `true`**(항상 애니메이션). `false`로
resolve되면 `Tween{...}`으로 안 감싸고 `self:Get()`을 그대로 반환 —
reduceMotion류 접근성 우회가 이 필드 하나로 바로 표현됨:

```lua
-- reduceMotion: State<boolean>
Position = mySource:Apply(Animate{
  Style = Enum.EasingStyle.Bounce,
  CanAnimate = reduceMotion:Compute(function(r) return not r:Get() end),
})
```

이 필드도 다른 옵션들과 동일하게 값 자체가 State로 바뀌는 것만으로는
재계산을 트리거하지 않음(`Value`가 실제로 바뀌는 다음 재계산 때 그
시점의 최신 `CanAnimate`가 자연히 반영) — 위 "`Style`/`Override` 등이
State여도..." 절과 같은 이유.

**필드 이름 케이싱 메모**: 대화 중엔 `canAnimate`(소문자 시작)로
나왔으나, 같은 옵션 테이블의 나머지 필드가 전부 `Value`/`Style`/`Time`
같은 PascalCase(Roblox 프로퍼티/`Tween` opts 관례를 그대로 따름)라 여기선
`CanAnimate`로 통일 — 이 필드 하나만 다른 케이싱을 쓸 특별한 이유가
없다고 판단(확정은 아님, 다음 세션에 뒤집혀도 비용 낮음).

**왜 `:Apply`로 정정됐는가(2026-08-12 세션 후속 논의)**: 처음엔 `Animate(info)`가
`:Compute(fn)`의 콜백 시그니처(`fn(self, previous?, ...deps)`)와 모양이
정확히 일치한다는 이유로 `state:Compute(Animate{...})`처럼 바로 넘기고
`:Apply` 경유를 "불필요한 한 겹"으로 보고 피했음. 이후 `research/
operator-sugar-plan.md`의 비슷한 콤비네이터(`Sum`/`Not` 등) 논의에서
재검토됨 — 결론은 반대: **재사용 가능한 이름 붙은 콤비네이터는 스타일이
아니라 정합성 때문에 `:Apply`가 맞음.**

- `Animate(info)` 자체는 옵션이 deps로 등록되지 않아(아래 절) 이 특정
  사례에서 `:Compute` 직결이 실제로 깨지진 않았지만, 같은 패밀리인
  `Sum(a,b,c)`류는 `local addTax = Sum(tax, shipping)`처럼 만들어서
  재사용하려는 순간 `:Compute` 직결이 실제로 깨짐(quad는 Vide식 암묵적
  자동 추적을 이미 기각해서, `tax`/`shipping`을 클로저로만 읽으면 그
  값이 바뀌어도 재계산이 안 트리거됨 — `:Compute`의 구독 목록은 오직
  그 호출문 자체의 trailing args로만 채워짐). `:Apply`는 factory가
  내부에서 `self:Compute(fn, tax, shipping)`을 스스로 다시 전달하므로
  이 문제가 없음. 상세 근거는 `research/operator-sugar-plan.md` "왜
  `:Apply`인가" 절 참고.
- **일관성**: "이 라이브러리가 제공하는 이름 붙은 콤비네이터는 항상
  `:Apply`로 붙인다"는 단일 규칙이, "`Animate`만 예외적으로 `:Compute`
  직결"보다 기억하기 쉬움 — `bind-system-plan.md`가 이미 `:Apply` 절에서
  `state:Apply(makeFormatter("ko-KR"))`를 커링 팩토리의 정석 예시로
  들어둔 것과도 맞음(오히려 원래 `Animate`의 `:Compute` 선택이 이
  기존 관용구에서 벗어난 예외였음).

**결론 — `Animate(info)`는 `factory(self) -> State`를 반환하고 항상
`:Apply`로 붙인다**(위 구현 코드 블록도 이렇게 갱신됨 — 내부에서
`self:Compute(...)`를 직접 호출):

```lua
-- 슈거로 충분한 흔한 케이스
Position = mySource:Apply(Animate{Style = Enum.EasingStyle.Bounce, Time = 0.3})
```

**`Style`/`Override` 등이 State여도 값 변경 자체가 재애니메이션을
트리거하지 않음 — 의도된 동작(이 부분은 `:Apply`로 바뀌어도 동일).**
`Animate{...}`가 반환한 factory 내부의 `self:Compute(fn)` 호출은
`selfH`(= `mySource`, `Value`가 될 State)가 바뀔 때만 다시 불림 —
`info.Style`이 State여도 이 내부 `:Compute`의 trailing deps로 안
넘어가므로 구독 목록에 안 걸림(`resolve`가 그냥 `fn` 본문 안에서
클로저로 읽을 뿐). 그래서 `Style`이 바뀌어도 그 자체로는 아무 일도 안
일어나고, 다음에 `Value`가 실제로 바뀔 때 그 시점의 최신 `Style`이
자연히 반영됨. 사용자가 직접 짚은 근거: "style 같은 게 바뀐다고 다시
애니메이션을 수행하는 경우는 없다" — 실사용 요구와 정확히 일치하는
동작이라 별도 트리거 배선이 오히려 불필요한 복잡도였을 것.

**구 `useTween`(reduceMotion 우회) 스케치는 `CanAnimate` 필드로 대체됨**
(위 "`CanAnimate`" 절) — 흔한 단순 토글은 그걸로 충분. 이전에 검토했던
전용 2-인자 시그니처(`Animate(cond, opts)`)는 안 씀 — `Animate(info)`는
조건 인자를 별도로 안 가지는 단일 진입점 유지. `CanAnimate`로 못 담는
더 복잡한 조건(값 자체를 다른 값으로 바꿔치기하는 등)이 생기면, `Animate`를
감싸는 평범한 `:Compute` 클로저로도 여전히 표현 가능 — 새 프리미티브
불필요:

```lua
Position = mySource:Apply(function(self)
  if someComplexCondition() then
    return self:Compute(function(h) return someOtherValue end)
  end
  return Animate{Style = Enum.EasingStyle.Bounce}(self)
end)
```

(`Animate{...}(self)`가 이제 plain 값이 아니라 `State`를 반환하므로,
탈출 분기도 똑같이 `self:Compute(...)`로 감싸 타입을 맞춰야 함 —
`:Apply`로 붙이는 factory는 항상 `State`를 반환해야 한다는 불변식.)

**base 프리미티브 아님 — 여전히 quad-roblox 유틸**(아래 "패키지 경계"
절) — `Tween<T>` 값 타입만 base(`quad-base/Tween.luau`, `isTween`은
**[2026-08-28]** 다른 술어와 같이 `Brand.luau`)에 있고, `Animate`는 이미 있는 `:Compute`/`Tween{...}`/`isState`를 조합한
quad-roblox 레벨 편의 함수라 base 계약에 영향 없음.

## 초기 진입 애니메이션(`initValue`) — **에이전트 작업 범위 제외로 확정, 사용자가 직접 처리**

`initValue`는 여전히 미확정(2026-08-09 세션 결론 유지: "필요성 낮은
쪽으로 기움", 완전 폐기는 아님). "3-상태 저장"의 1번 분기(`hasBeenSet`)가
"첫 세팅은 무조건 애니메이션 없이 스냅"을 기본 동작으로 확정했으므로,
나중에 `initValue`(다이얼로그가 아래에서 위로 슬라이드-인하는 것처럼 첫
마운트에도 애니메이션을 원하는 경우)가 실제로 필요해지면 이 억제 동작을
어떻게 명시적으로 우회할지(예: 릴레이션 슬롯에 `nil` 대신 다른 초기
상태를 미리 심어두는 옵션)까지 같이 설계해야 함.

**2026-08-12 세션에서 확정**: 필요해지는 시점이 오면 **사용자가 직접
코드베이스+문서를 만짐** — Tween 정보가 부족한 에이전트가 다루기엔
`hasBeenSet` 억제 동작과의 상충 판단이 미묘하고, 반대로 Tween 자체가
다른 base 요소와 깊게 안 얽혀 있어(거의 전부 `Handlers/Property.luau`
한 파일 + 릴레이션 슬롯) 사용자가 직접 처리하는 데 범위상 문제가 없음.
에이전트는 이 항목을 임의로 착수하지 말 것.

## 패키지 경계 — `Tag`가 이미 밟은 것과 같은 분리 (2026-08-10 세션 확정)

- **quad-base**: `Tween.luau` — 값 타입(`Tween(opts)` 팩토리)만. 엔진 무관.
  **[2026-08-28]** `TweenBrand` 인스턴스와 `isTween` 술어는 다른 브랜드와 같이
  `Brand.luau`에 산다(`base/architecture.md` 소스 트리) — 이 파일은 거기 등록만.
- **quad-roblox**: `Handlers/Property.luau`(기존 프로퍼티 세팅 로직에
  `isTween` 분기 + 3-상태 릴레이션 저장 + override 정책 추가) +
  `Animate.luau`(편의 콤비네이터, 신규).
- **기존 `Handlers/Tween.luau`(독립 Dispatch 핸들러 파일) 자체는 더
  이상 필요 없음** — `base/architecture.md` 소스트리 갱신 완료.

## 확정: `Tween{...}` 최종 모양 (2026-08-12 세션)

### 옵션 값 모양 — `Info` 우선, 없으면 편의 필드로 폴백 (확정)

Roblox의 `TweenInfo.new(time, easingStyle, easingDirection, repeatCount,
reverses, delayTime)`는 순수 포지셔널 생성자인데, Luau엔 named call
문법이 없어서 직접 쓰면 `TweenInfo.new(0.3, Enum.EasingStyle.Quad,
Enum.EasingDirection.Out)`처럼 각 인자가 뭘 뜻하는지 호출부만 보고 알기
어렵다. **두 경로를 동시에 지원하는 걸로 확정** — 비용 근거: 이미 만들어
재사용하려는 `TweenInfo`가 있으면 매번 새로 조립하지 않고 그대로 쓰는 게
더 싸고(재사용 최적화), 반대로 매번 값이 바뀌는 인라인 케이스는 개별
필드가 훨씬 편함(계속 바뀌는 `TweenInfo` 구조도 자연스럽게 허용됨):

- **`Info: TweenInfo?`** — 있으면 **그대로 사용**, 나머지 편의 필드는
  전부 무시.
- **`Info`가 없으면** 아래 편의 필드로 `TweenInfo.new(...)`를 조립.

편의 필드의 기본값은 **로블록스 `TweenInfo.new()` 자신의 기본값을 그대로
물려받음** — 별도 기본값 상수를 새로 정의할 필요 없음:

```lua
Time: number?             -- default 1
Style: Enum.EasingStyle?  -- default Enum.EasingStyle.Quad
Direction: Enum.EasingDirection?  -- default Enum.EasingDirection.Out
RepeatCount: number?      -- default 0
Reverses: boolean?        -- default false
DelayTime: number?        -- default 0
```

### override 정책 — `Tween.Cancel` / `Tween.Finish` 두 값으로 압축 (확정)

기존엔 4가지 옵션(멈춤/오버라이드/삭제후재시작/끝점이동후재시작)을 열어뒀으나,
다시 보니 로블록스 `TweenBase`가 애초에 진행 중인 트윈의 목표를 바꿔치기할
API가 없음(`:Play`/`:Pause`/`:Cancel`뿐, 인스턴스 재사용 불가) — 그래서
"오버라이드"와 "삭제 후 재시작"은 관찰 가능한 결과가 "현재 보간값에서
새로 시작"으로 멈춤(Cancel)과 완전히 동일, 구분할 실익이 없었음이 드러남.
실질적으로 구별되는 건 딱 두 갈래뿐:

- **`Tween.Cancel`(기본값)** — 새 트윈은 **현재 보간된 값**에서 자연스럽게
  이어감. 근거: Roblox `TweenService`의 `:Cancel()`은 프로퍼티를 되돌리지
  않고 그 자리에서 멈추기만 하므로, 대부분의 UI 애니메이션이 기대하는
  동작과 일치.
- **`Tween.Finish`** — 이전 트윈을 **목표값(`Value`)으로 스냅**시킨 뒤 그
  자리에서 새 트윈을 시작(기존 "끝점 이동 후 재시작"에 해당). 목표값은
  로블록스 API로 역산 불가능하므로 릴레이션 슬롯에 `{Tween, Value}`로
  같이 저장해뒀던 `Value`를 사용(위 "3-상태 저장" 절 참고).

필드 이름은 `Override`(기존 문서에서 계속 써온 "override 정책" 용어와
일치) — `Tween.Cancel`/`Tween.Finish`는 `Tween` 네임스페이스에 노출되는
sentinel 상수(구현 세부는 M11 착수 시, 문자열이든 전용 테이블이든 상관없이
동등성 비교만 되면 됨). Tween→plain 전환도 두 옵션 모두 "정리 후 즉시
덮어쓰기"로 수렴하므로 별도 5번째 옵션 불필요로 확정.

### 최종 타입

```lua
Tween(opts: {
  Value: T,
  Info: TweenInfo?,
  Time: number?,
  Style: Enum.EasingStyle?,
  Direction: Enum.EasingDirection?,
  RepeatCount: number?,
  Reverses: boolean?,
  DelayTime: number?,
  Override: (typeof(Tween.Cancel) | typeof(Tween.Finish))?,  -- default Tween.Cancel
}) -> Tween<T>
```

## `Tween<T>:Mapped(fn)` — 값만 갈아끼운 새 `Tween`을 반환 (2026-08-20 구현 전 QA 4라운드 `UI-8` 신설, 이름은 2026-08-21 5라운드 확정)

**동기**: `base/ui-shorthand-plan.md`의 숏핸드가 스칼라를 자식 프로퍼티 타입으로
감싸야 하는데(`UICorner = 8` → `CornerRadius = UDim.new(0, 8)`), 값이
`Tween<number>`면 그 변환을 **`Tween`을 벗기지 않고 `.Value`에만** 적용해야 한다.
그 문서가 `mapTweenValue(v, wrap)`라는 로컬 헬퍼로 적어뒀던 것을, 사용자 판정으로
**`Tween` 자신의 공개 메소드로 승격**한다: *"그냥 펑터 구조를 그대로 줘도
무방한듯. :Map 정도로써 새 Tween 을 새 관측된 Value 로 형성."*(이름은 이후
`Mapped`로 확정 — 아래 마지막 항목)

```lua
tween:Mapped(fn: (T) -> U): Tween<U>   -- opts를 clone하고 Value만 fn(Value)로 교체해 새 Tween 반환
```

- **타입이 안전하게 성립한다** — `Tween<T>`는 immutable raw 값이고 `Value` 외의
  필드는 값 타입과 무관한 옵션(`Time`/`Style`/…)이라, `Value`만 `U`로 바꾼
  `Tween<U>`를 만드는 건 타입 레벨에서 깨끗하다.
  - **⚠️ [단서, 2026-08-24 6라운드 손 트레이싱 `H-24` — 실측] 단 선언 방식이
    갈린다.** 이 시그니처는 `base/typing-limits.md` 1번이 지적한 재귀 제네릭
    누수(`Foo<T>` 안에서 `-> Foo<U>`)와 **글자 그대로 같은 모양**이라,
    인라인 제네릭 메소드로 선언하면 `luau-analyze`가 **진단 없이 조용히
    통과**시킨다(`Tween<string>`의 `.Value`를 `number`에 넣어도 안 잡힘).
    **구현 시 `typeof(named function)` 스타일(③)로 선언할 것** — 그러면 정상적으로
    잡힌다. 위 "타입이 안전하게 성립한다"는 *의미론상* 맞지만 *체커가 지켜준다*는
    뜻은 아니다.
- **`Tween<T>`가 immutable이라는 기존 확정과 일관** — `:Mapped`는 원본을 안 건드리고
  `table.clone` 후 `Value`만 교체해 `Tween(opts)`로 다시 만든다(`Tag`/`Modifier`의
  clone 체이닝과 같은 계열).
- **부수 효과 — 기본 `Tween` 정의를 만들어두고 재사용하는 패턴이 열린다.**
  `local FAST = Tween{Value = 0, Time = 0.15}` 같은 상수를 두고
  `FAST:Mapped(function() return targetPos end)`처럼 옵션만 재사용할 수 있다. 다만
  **사용 케이스가 넓지는 않을 것**으로 봄 — 어차피 내부 구현에 필요해서 만드는
  것이고, 외부에 보이는 게 무해하니 같이 공개하는 것뿐(사용자 판단).
- **✅ 이름 — `Mapped`로 확정(2026-08-21 구현 전 QA 5라운드 `TW-2`).**
  코퍼스의 `-ed` 관례("clone 후 즉시 확정된 값"은 `Added`/`Removed`/`Overridden`처럼
  과거분사, `base/source-state-plan.md`의 "네이밍 — `Compute`가 `-ed`가 아닌 이유"
  절)를 그대로 적용한 결과 — `Tween`은 lazy가 아니라 즉시 확정되는 raw 값이므로
  `Mapped`가 맞다(**사용자 확정**: *"Mapped 로 확정"*).

## 네임스페이스드 객체 (더 이상 유효한 관심사 아님)

기존 모델(핸들러가 대상을 이름으로 찾아야 하는 가능성)을 염두에 두고
열어뒀던 절 — 새 모델에서는 PropertyHandler가 `inst`를 항상 직접
받으므로(다른 모든 핸들러와 동일) 이 문제 자체가 성립하지 않음. 절 자체는
과거 기록으로만 남김, 실행할 내용 없음.

## 열린 질문 — 전부 해소됨

**2026-08-12 세션에서 옵션 값 모양/override 정책 이름/릴레이션 슬롯 저장
모양/`Animate` 콤비네이터 시그니처까지 전부 확정됨**, 마지막 남았던 아래
질문도 같은 날 다섯 번째 후속 논의로 확정됨.

> **[2026-08-13 열세 번째 세션, 해소]** 한때 여기 "0-Y는 예외"라는
> 캐비엇이 있었음 — `Animate`가 얹혀 있는 `factory(self)`의 lazy 핸들
> 계약이 열려 있다는 것이었는데, **그 계약이 그대로 유지로 확정**되어
> `Animate`의 시그니처/옵션 resolve 방식 모두 안 바뀜. 남은 Luau 쪽
> 한계(파생 State의 반환 타입 명시 바인딩 필요)는 `Animate`만의 문제가
> 아니라 전역 규약이므로 `base/typing-limits.md`가 담당.

### 자연 완료(Completed) 시 per-instance 북키핑 — 정리 안 해도 됨 (확정)

`research/pre-implementation-audit.md` 2-10번이 제기했던 질문. **결론:
Completed 이벤트를 구독해 3-상태 릴레이션 슬롯을 `true`로 되돌리는 등의
정리 로직은 만들지 않는다.**

**근거**: 이 정리를 하고 싶어지는 동기는 "인스턴스 초기 생성 시 프로퍼티가
유저가 원치 않는 값(예: `Position`이 기본 `UDim2.new(0,0,0,0)`)일 수 있어,
거기서 트윈이 시작되면 툭 튀어 보인다"는 문제인데 — 이건 이미 **"첫 세팅"
분기**(위 "3-상태 저장" 절의 `prev == nil` 케이스, 애니메이션 없이 즉시
세팅)가 처리하는 문제지, 자연완료와는 무관하다. 자연완료 상태는 반대로
**유저가 원한 목표값에 정확히 도달한 상태**이므로, 그 상태를 나타내는
북키핑(`{Tween, Value}`)을 안 지우고 남겨둬도 다음에 이 `(inst,k)`가 다시
process될 때 위 "3-상태 저장"의 `prev`가 `{Tween, Value}` 테이블 분기를
타는 것뿐 — override 정책(`Cancel`/`Finish`)이 정확히 이 케이스를 위해
이미 정의돼 있어 별다른 부작용이 없다. 게다가 `Value`는 항상 lerp 가능한
프리미티브(number/UDim/Vector 등, 테이블 aliasing 걱정이 있는 타입이
아님)라 참조를 계속 들고 있어도 메모리/정합성 문제가 없다. 이 상태에서
굳이 Completed 이벤트를 구독해 슬롯을 되돌리는 별도 장치를 추가하는 건
실질적 이득 없이 복잡도만 늘리는 오버엔지니어링으로 판단.

`initValue`(진입 애니메이션)는 별도 취급 — 위 해당 절 참고, **에이전트
작업 범위에서 제외, 필요해지면 사용자가 직접 처리**하기로 확정(질문
목록이 아님).
