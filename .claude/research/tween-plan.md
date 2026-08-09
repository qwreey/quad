# Tween / 애니메이션 플러깅 (구조 재확정 — 값-레벨 `Tween<T>` 래퍼, 옵션 값 모양만 남음)

**상태**: research — **2026-08-10 세션에서 구조 전체가 재설계됨.** 기존
"`v`가 Store인 아무 `k`나 잡는 우선순위 최상위 Dispatch 핸들러" 모델은
`research/pre-implementation-audit.md` 1-1이 지적한 구조적 모호함("애니메이션
없는 일반 반응형 프로퍼티 바인딩도 결국 이름이 Tween인 파일을 거쳐가는가")을
명확히 답하지 못했음 — 대체된 새 모델(`Tween<T>`를 PropertyHandler가
소비하는 값-레벨 래퍼로 두는 것)이 이 모호함을 구조적으로 해소함, 아래
"새 모델" 절부터가 최종 소스. **구 모델(특수 bind key `[Tween(key,
tweenData...)] = storeValue`)은 `archive/tween-special-bind-key-reversed.md`로
이전됨** — 원문/역전 사유는 거기 보존, 이 문서는 새 모델만 서술.

남은 건 옵션 값 모양(`TweenInfo` 그대로 vs 편의 필드)과 override 정책
옵션 키의 정확한 이름/시그니처뿐 — M11 착수 시 확정. 원본:
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
Tween(opts: {Value: T, ease..., onOverride?...}) -> Tween<T>
```

`Store({...})`와 같은 "`Type(args)`가 테이블 인자를 받는 팩토리" 컨벤션 —
Lua 문법상 `Tween{Value=target, ease=...}`처럼 괄호를 생략해 호출.

**PropertyHandler.process(inst,k,realv)의 새 로직** — `realv`는 이미
StoreBind가 State/Source 레이어를 전부 풀어낸 뒤의 값:

1. `isTween(realv)`가 거짓이면 — 기존과 동일하게(아래 "3-상태 저장" 참고,
   `hasBeenSet` 여부만 갱신하고) 즉시 세팅.
2. `isTween(realv)`가 참이면 — 아래 "3-상태 저장" 절의 분기를 따름.

### `Tween.Value`는 plain `T`만 받음 — 내부에 별도 반응 경로를 안 둠

처음엔 `Tween.Value`도 `T | State<T>`를 받아야 하나(내부에 자체 Observer를
걸어 값이 바뀔 때마다 트윈을 재시작) 검토했으나 **불필요로 확정** — 이미
바깥 `:Compute`가 소스 State 변경마다 새 `Tween{Value=v,...}` 테이블을
통째로 재생성해 StoreBind 재귀 재-dispatch 경로를 타므로, `Tween` 값
내부에 또 다른 반응 경로를 만들 이유가 없음. "같은 일 하는 두 번째 경로를
만들지 않는다"는 이 프로젝트가 Effect의 deps/Ref의 대기 경로 등에서 이미
여러 번 적용한 원칙과 정확히 같은 결. **`Tween<T> = {Value: T, ease...,
onOverride?...}`로 확정** — `Value` 필드는 항상 plain `T`.

### 3-상태 저장 — `RobloxTween | true | nil` (릴레이션 슬롯 하나로 `hasBeenSet` 통합)

처음엔 "첫 세팅 여부(`hasBeenSet: boolean`)"와 "실행 중인 엔진 Tween
객체"를 별도 필드로 저장하려 했으나, **하나의 릴레이션 슬롯으로 통합** —
`relate:GetStrong(inst,k)`가 돌려주는 값의 3가지 상태:

- **`nil`** — 이 `(inst,k)`가 이번 `inst`에서 한 번도 process된 적 없음
  (첫 세팅).
- **`true`** — 최소 한 번 세팅된 적 있음(직전 값이 plain이었든 `Tween<T>`
  였든 무관), 지금은 활성 엔진 Tween 없음.
- **실제 엔진 `TweenBase` 인스턴스** — 지금 애니메이션이 진행 중, 새 값을
  처리하기 전에 먼저 정리해야 함.

**분기**:

1. **`prev == nil`(첫 세팅)** — `realv`가 `Tween<T>`든 plain이든 무관하게
   **애니메이션 없이 즉시 `Value`(또는 plain 값)로 세팅**, 슬롯엔 `true`
   저장. 엔진 기본값(예: Frame 기본 `Position`)에서 목표값으로 날아오는
   "첫 마운트 진입 애니메이션" 버그를 이걸로 방지.
2. **`prev == true`(세팅된 적 있음, 활성 트윈 없음)**:
   - `realv`가 plain 값 → 즉시 세팅, 슬롯은 `true` 유지.
   - `realv`가 `Tween<T>` → 이제 정상적으로 애니메이션 시작(현재 인스턴스
     프로퍼티 값에서 자연스럽게 출발), 슬롯에 새로 만든 엔진 Tween 객체
     저장.
3. **`prev`가 엔진 Tween 객체(활성 트윈 있음)**:
   - **먼저 override 정책(기본 Cancel, 아래 절)에 따라 이전 트윈을 정리 —
     반드시 그 정리가 끝난 뒤에 새 값을 세팅한다.** 순서가 뒤바뀌면
     이전 트윈의 다음 인터폴레이션 프레임이 방금 세팅한 값을 덮어쓸
     위험이 있음(엔진 트윈은 비동기로 계속 프로퍼티를 갱신 중이므로).
   - 정리 후: `realv`가 plain 값이면 (정리 결과로 프로퍼티에 남은 현재
     값 위에) 즉시 덮어쓰기 + 슬롯 `true`. `realv`가 `Tween<T>`면 (같은
     현재 값에서) 새 트윈 시작 + 슬롯을 새 엔진 Tween 객체로 갱신.
   - plain 값이 들어와 진행 중인 트윈을 끝내는 경우, 기존 override
     정책의 4가지 옵션(Cancel/Override/Delete-restart/Move-to-end-restart,
     아래 절)은 원래 Tween→Tween 전환을 염두에 둔 것이라 Tween→plain
     전환에는 사실상 전부 "멈추고 그 자리에서 즉시 덮어쓴다"로 수렴하는
     것으로 보임 — 별도 5번째 옵션이 필요해 보이진 않으나 **확정은 아님,
     M11 착수 시 재확인**.

**GC-안전성은 기존과 동일** — `Relate`가 `inst`로 weak-keyed되어 있어
`inst`가 죽으면 이 슬롯(엔진 Tween 객체 포함)도 별도 정리 로직 없이 같이
GC됨. `retract`는 이 케이스에서 거의 안 불림 — 아래 절 참고.

### 왜 `retract`가 더 이상 필요 없는가 — Dispatch 체인 관점의 결과적 단순화

기존 모델에선 "Tween 핸들러가 매치되어 애니메이션이 실행 중이었는데,
다음 값이 더 이상 Tween 대상이 아니게 되어 일반 PropertyHandler로
핸들러 *타입*이 바뀌는" 경우가 `base/bind-system-plan.md`가 서술하는
"`retract`가 실제로 의미를 갖는 유일한 패턴"의 대표 예시였음. 새 모델에선
**매치되는 Dispatch 핸들러가 항상 PropertyHandler 하나뿐**(Tween 여부는
값 내부 분기일 뿐 핸들러 매치 자체엔 영향 없음) — 이 시나리오 자체가
Dispatch 레벨에서 사라짐. 트윈 취소/전환은 위 3-상태 저장 로직으로
PropertyHandler 내부에서 처리 — Tag가 이미 하고 있는 "diff는 `process`
자신이 담당" 패턴과 같은 모양이라 새 개념 아님. (PropertyHandler의
`retract` 필드 자체는 여전히 정의해둬야 함 — "필드 생략 불가" 규칙은
예외 없는 일반 규칙 — 다만 실제로 호출될 일이 이 경로에선 사실상 없음.)

### 타입 대수: `T' = T | Tween<T>` — Modifier/State/Source에 새 타입 기계 불필요

지금 프로퍼티류 필드가 열려 있는 자리(Modifier setter, Ref, Store/Source
필드)는 전부 `T | State<T>` 모양 하나로 통일돼 있음. 여기서 "이 필드의
`T`" 자체를 `T' = T | Tween<T>`로 치환하면 자동으로 `T | Tween<T> |
State<T | Tween<T>>`가 나옴 — Modifier/State/Source/StoreBind 코드엔
`Tween` 인지 로직을 전혀 안 넣어도 됨(StoreBind는 원래도 페이로드 타입에
무관하게 `isState`만 보고 언랩하는 opaque한 구조였음). `Tween<T>`를 실제로
해석하는 코드는 여전히 PropertyHandler 하나에만 존재.

**핸들러 계층 UB 체크와도 안 부딪힘** — `Tween<T>`는 `Ref`/`Observer`/
`Slot`류처럼 `process`/`retract`를 가진 dispatch 참가자가 아니라 `None`/
`Tag`처럼 순수 raw 데이터 값(별도 `TweenTag` Brand)이라, Modifier 필드/
`State<Modifier>`가 막는 "핸들러 계층 값" 규칙(`base/modifier-plan.md`)에
안 걸림 — 그 문서가 원래 Tween을 Slot/Tag/Attribute와 같은 "dispatch
참가자" 그룹으로 분류해뒀던 건 부정확했던 것으로 이번에 정정(아래
"패키지 경계" 절 참고).

## `useTween`(트윈 우회) — 해소됨, 새 옵션 필드 불필요

이전엔 `Tween{useTween=state<boolean>}`처럼 `Tween` 생성자 안에 별도
옵션 필드를 두는 방향으로 열려 있었으나, 값-레벨 래퍼 모델에선 **이미
있는 `state:Apply(factory)`/`:Compute`만으로 공짜로 풀림** — 새 필드
불필요:

```lua
-- reduceMotion: State<boolean>
Position = mySource:Apply(Animate(reduceMotion, {ease = ...}))
```

`Animate(reduceMotion, opts)`는 커링 팩토리로, 개념상 다음과 같은 모양:

```lua
return function(state)
  return state:Compute(function(v)
    if reduceMotion:Get() then
      return v
    else
      return Tween{Value = v, ease = opts.ease}
    end
  end)
end
```

`reduceMotion`이 바뀌면 `:Compute`가 재계산되어 StoreBind가 자연히 새
`realv`(plain 또는 Tween-wrapped)로 재-dispatch — PropertyHandler는 평소처럼
그 값만 보고 처리하면 됨, 우회 로직을 따로 알 필요 없음. **`Animate`는
base 프리미티브가 아니라 quad-roblox가 제공하는 자유 함수 조합기**(아래
"패키지 경계" 절) — `Modifier:Apply(Boldify(10))` 커링 패턴과 완전히
같은 모양이라 base에 새로 추가할 게 없음.

## 초기 진입 애니메이션(`initValue`) — 여전히 별개 문제, 위 hasBeenSet과 상충 방향 주의

`initValue`는 여전히 미확정(2026-08-09 세션 결론 유지: "필요성 낮은
쪽으로 기움", 완전 폐기는 아님). 다만 이번 세션에서 **"3-상태 저장"의
1번 분기(`hasBeenSet`)가 "첫 세팅은 무조건 애니메이션 없이 스냅"을
기본 동작으로 확정**했으므로, 나중에 `initValue`(다이얼로그가 아래에서
위로 슬라이드-인하는 것처럼 첫 마운트에도 애니메이션을 원하는 경우)가
실제로 필요해지면 **이 억제 동작을 어떻게 명시적으로 우회할지**(예:
릴레이션 슬롯에 `nil` 대신 다른 초기 상태를 미리 심어두는 옵션)까지
같이 설계해야 함 — 지금은 새 결정 없이 이 긴장 관계만 기록해둠.

## `Animate` 콤비네이터 — quad-roblox 유틸(base 아님)

`Animate(condOrOpts, opts?)`류 팩토리를 quad-roblox가 제공, `:Apply`로
체이닝해서 쓰는 용도. 상세 시그니처는 미확정(예: `Animate({ease=...,
useAnimate=state<boolean>})`처럼 조건과 옵션을 하나의 테이블로 합치는
안도 검토 가치 있음 — 확정 아님, M11에서 정리). 핵심은 **base
프리미티브가 아니라는 것** — `Tween<T>` 값 타입/`isTween`만
base(`quad-base/Tween.luau`)에 있고, `Animate`는 이미 있는 `:Apply`/
`:Compute`/`Tween{...}`를 조합한 quad-roblox 레벨 편의 함수라 나중에
이름/모양을 자유롭게 바꿔도 base 계약에 영향이 없음 — 저비용
고효율(사용자 표현) 엔지니어링으로 판단.

## 패키지 경계 — `Tag`가 이미 밟은 것과 같은 분리 (2026-08-10 세션 확정)

- **quad-base**: `Tween.luau` — 값 타입(`Tween(opts)` 팩토리, `isTween`
  predicate/`TweenTag` Brand)만. 엔진 무관.
- **quad-roblox**: `Handlers/Property.luau`(기존 프로퍼티 세팅 로직에
  `isTween` 분기 + 3-상태 릴레이션 저장 + override 정책 추가) +
  `Animate.luau`(편의 콤비네이터, 신규).
- **기존 `Handlers/Tween.luau`(독립 Dispatch 핸들러 파일) 자체는 더
  이상 필요 없음** — `base/architecture.md` 소스트리 갱신 완료.

## `retract`(구 cleanup)로 확정된 오버라이드 시맨틱 — Tween↔Tween 전환에서는 그대로 유지

**이 절의 4가지 옵션은 안 바뀜 — 다만 "Dispatch의 `retract` 호출"이 아니라
"PropertyHandler 내부 로직이 참고하는 정책"으로 위치만 이동했다는 점에
유의.** 이전 트윈을 취소하고 새 트윈을 만드는 게 맞지만, "취소" 시점의
동작이 여러 갈래로 갈릴 수 있음:

1. 키 밸류를 받으면, 그로 인해 생성된 트윈을 얻어서 **멈춰버리기**.
2. 트윈 뒤에 **삭제하지 않고 오버라이드**(새 트윈이 이전 트윈의 현재 값에서
   시작, 이전 트윈 자체는 그대로 재사용/대체).
3. **삭제** 후 새로 시작.
4. 트윈을 **끝 지점으로 옮기고** 새로운 트윈을 시작.

**확정된 기본값**: **멈춤(Cancel)** — 새 트윈은 현재 보간된 값에서 자연스럽게
시작. 근거: Roblox `TweenService`의 `:Cancel()`은 프로퍼티를 되돌리지 않고
그 자리에서 멈추기만 하므로, 새 트윈이 시작될 때 이미 인스턴스 프로퍼티에
남아있는 현재 값에서 자연스럽게 이어짐 — 대부분의 UI 애니메이션이 기대하는
동작과 일치.

이 기본값 외 나머지 세 동작(오버라이드/삭제 후 재시작/끝점 이동 후 재시작)은
라이브러리가 강제하지 않고, `Tween{Value=..., ease=..., onOverride=...}`처럼
`Tween` 생성 시 넘긴 옵션으로 사용자가 고를 수 있게 열어둠 — PropertyHandler가
위 3-상태 저장의 3번 분기에서 이 옵션을 참고해 구현.

## 트윈 옵션 값 모양 — TweenInfo 그대로 vs 편의 필드 (여전히 열린 논의)

**아직 논의 시작 단계 — 나중에 더 다룰 주제로만 남겨둠.** Roblox의
`TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses,
delayTime)`는 순수 포지셔널 생성자인데, Luau엔 named call 문법이 없어서
직접 쓰면 `TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)`
처럼 각 인자가 뭘 뜻하는지 호출부만 보고 알기 어렵다. 후보:

1. **`TweenInfo`를 그대로 받는다** — 사용자가 이미 만들어둔 `TweenInfo`를
   재사용하고 싶은 경우엔 상관없지만, 대부분의 흔한 케이스(길이/이징만
   바꾸고 싶음)에서 매번 포지셔널 생성자를 마주해야 함.
2. **편의 필드로 개별 인자를 받고 기본값을 제공** — 예:
   `Tween{Value=..., Time=0.3, Style=Enum.EasingStyle.Quad, Reverses=false, ...}`처럼
   이름 붙은 키로 받고 흔한 기본값(예: `Time=0.2`, `Style=Quad`,
   `Direction=Out`)을 채워줌. 명시적으로 `TweenInfo`가 이미 있어서
   재사용하고 싶다는 케이스에도 열어두면(예: `Info = someTweenInfo`
   필드로), 둘 다 지원 가능.

**현재 소견(확정 아님)**: 2번(편의 필드 + 기본값)이 흔한 사용 경험상 더
낫다는 쪽으로 기움 — 이번 세션의 모든 예시(`Tween{Value=..., ease=...}`)도
자연스럽게 이 방향을 가정하고 있음. 다만 구체적인 필드 이름/기본값/
`TweenInfo` 재사용 경로의 정확한 문법은 아직 확정 아님 — 나중 논의 대상으로
남김.

## 네임스페이스드 객체 (더 이상 유효한 관심사 아님)

기존 모델(핸들러가 대상을 이름으로 찾아야 하는 가능성)을 염두에 두고
열어뒀던 절 — 새 모델에서는 PropertyHandler가 `inst`를 항상 직접
받으므로(다른 모든 핸들러와 동일) 이 문제 자체가 성립하지 않음. 절 자체는
과거 기록으로만 남김, 실행할 내용 없음.

## 열린 질문 (`.claude/question.md`에도 취합)

- 기본값(Cancel)은 확정됨. 남은 건 나머지 세 동작(오버라이드/삭제 후 재시작/
  끝점 이동 후 재시작)을 선택하는 옵션 키의 정확한 이름/시그니처, 그리고
  Tween→plain 전환에 5번째 옵션이 필요한지 — 구현 단계에서 확정.
- 트윈 옵션 값 모양(위 절) — `TweenInfo` 그대로 받을지 편의 필드+기본값으로
  받을지, 소견은 후자 쪽이지만 확정 아님.
- `Animate` 콤비네이터의 정확한 시그니처(조건/옵션 분리 vs 통합) — M11에서
  정리.
- 자연 완료(Completed) 시 per-instance 북키핑 정리 여부(3-상태 슬롯을
  `true`로 되돌리는 시점) — `research/pre-implementation-audit.md` 2-10번
  참고, M11 착수 시 확정.
- `initValue`(진입 애니메이션) — 위 절 참고, 필요성 자체가 낮은 쪽으로
  기움, 완전 폐기는 아님. 필요해지면 hasBeenSet 억제 동작과의 상충을
  같이 풀어야 함.
