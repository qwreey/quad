# Tween / 애니메이션 플러깅 (기본값 확정, 옵션 키 이름만 남음)

**상태**: research — 방향은 뚜렷하게 잡혀 있고(라이브러리가 트윈을 직접
구현하지 않는다), `retract` 순서/오버라이드 기본값(Cancel)도 확정됨. 남은 건
기본값 외 나머지 오버라이드 동작을 고르는 옵션 키의 정확한 이름/시그니처와,
트윈 옵션을 어떤 값 모양으로 받을지(아래 "트윈 옵션 값 모양" 절, 신규)
정도. **중요 — 놓치기 쉬운 포인트**: `retract`는 Destroy(완전 소멸) 시엔
호출되지 않는다(아래 "`retract`는 완전 소멸 시엔 호출되지 않는다" 절) —
Tween 오버라이드 로직을 짤 때 "인스턴스가 파괴될 때도 이 코드가 실행될
것"이라고 가정하면 틀림. 원본:
`.claude/initreq/raw-userinput.md` "트윈은 어떻게 할 것이냐" / "스토어 값은
항상 먼저 캐치한다" / "네임스페이스드 객체" 절. Fusion의 Tween/Spring이
반응 그래프 안에 있는 설계는 명시적 반면교사 — [정정: 절 제목이 실제와
달랐음] `reference/comparison-fusion-vide.md`의 "Fusion" 절 마지막 불릿
("Tween/Spring이 State그래프 안의 1급 노드") 참고.

## 확정된 방향: 트윈을 Store/반응 그래프 밖에 둔다

렌더 라이브러리가 트윈을 직접 구현하는 건 처음부터 디자인이 잘못된 접근 —
렌더링 엔진(Roblox `TweenService`)의 애니메이션 관리를 전혀 안 따르게 되기
때문. 대신:

```
[Tween(key, tweenData...)] = storeValue
```

형태의 **특수 bind key**로 제공. 처음 실행될 때는 그냥 바인드로 필드를 쓰지만,
이후에는 store 값을 핸들해서 바뀔 때마다 트윈을 처리. 아니면 사용자가 직접
태그를 얻어 관리하게 둠(둘 다 허용 가능한 경로로 열어둘 것).

**왜 이게 중요한가(Fusion 리서치에서 확인된 근거)**: Fusion은 Tween/Spring을
`GraphObject`(1급 반응 노드, `timeliness="eager"`)로 만들어서 Computed의 입력으로
자유롭게 합성 가능하게 했지만, 그 대가로 (1) 매 프레임 틱하는 외부 클럭
소스(Stopwatch/ExternalTime)를 반응 그래프에 통합해야 했고, (2) eager 재계산
노드가 무효화/전파 로직과 경쟁하게 됐고, (3) 트윈-입력 간 별도의 교차 lifetime
체크 기계장치가 필요해졌다. quad가 트윈을 특수 bind key로 빼면 이 세 가지
복잡도를 전부 피할 수 있다 — 대신 트윈된 값이 Computed류의 추가 입력으로
자유롭게 합성되진 못한다는 걸 감수(Fusion 대비 유일한 손해).

## 정정: Ref 불필요 — 핸들러는 항상 대상 Instance를 직접 받는다

**이전 초안의 전제가 틀렸음.** Tween 핸들러도 `base/bind-system-plan.md`의
"확정된 디스패치 모델"을 그대로 따르는 store-bind 핸들러 중 하나 — `process(inst,
k, v)`가 항상 대상 Instance(`inst`)를 직접 받으므로, 트윈 대상을 얻기 위해
Ref나 네임스페이스드 조회가 필요하지 않음. Tween의 store-bind 핸들러는 "`k`는
무엇이든, `v`가 Store인 것"을 잡아내는 우선순위 매우 높은 핸들러로 등록되고,
`inst`는 이미 파라미터로 주어짐. (Ref 자체는 도입되지만 전혀 다른
용도 — `base/bind-system-plan.md`의 Ref 절 참고.)

## `retract`(구 cleanup)로 확정된 오버라이드 시맨틱

**스토어 값은 항상 먼저 캐치한다** — 그래야 `retract` 호출이 가능(이름 변경
근거는 `base/lifecycle-pattern.md`). 이전 트윈을 취소하고 새 트윈을 만드는 게
맞지만, "취소" 시점의 동작이 여러 갈래로 갈릴 수 있음:

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
라이브러리가 강제하지 않고, `[Tween(key, tweenData, {onOverride=...})]`처럼
키 설정으로 사용자가 고를 수 있게 열어둠 — `retract(inst, k, v)`가 이전
값(v)을 받으므로 여기서 선택된 동작을 구현. `retract`가 접근해야 할 "이전에
생성한 실제 Tween 객체"는 `base/bind-system-plan.md`가 말하는 base 제공
범용 유틸(`inst`를 키로 하는 weak-keyed per-instance 상태 저장소)에 담아두면
됨. **GC 확인(2026-08-07 여섯 번째 세션, 사용자 제안 검증)**: 이 저장소는
`inst`로 weak-keyed된 바깥 릴레이션 안에 `k`별 안쪽 릴레이션이 중첩된
구조라, `inst`가 죽으면 그 안에 담긴 Tween 인스턴스 릴레이션도 별도
정리 로직 없이 같이 GC됨 — `base/bind-system-plan.md`의 "핸들러 내부
상태 저장" 절 "왜 GC-안전한가" 참고.

## `retract`는 완전 소멸(Destroy) 시엔 호출되지 않는다

`base/lifecycle-pattern.md`의 핵심 원칙: quad는 자신이 만든 Instance를 생명주기
끝까지 그대로 들고 있는 소유자라, Destroy 이후에 실행해야 할 정리 로직이 없다
— 오히려 Destroy된 대상에 `:Cancel()`/`:Stop()` 같은 메서드를 호출하면 에러남
(대상이 죽으면 그 대상에 묶인 Tween도 함께 죽은 상태가 되므로). 따라서
**`retract`는 "같은 key에 새 값이 들어와 이전 트윈을 갈아치울 때"만 호출되고,
Destroy 시점엔 아무 것도 안 함(라이프타임 `Connected` 체크로 처리 자체를
멈추는 것만으로 충분).**

**메모 — `retract`와 `canExecute`는 서로 다른 문제를 다룬다, 나중에 quadnomicon
급에서 제대로 설명 필요.** "그럼 값 교체가 아니라 값을 계속 관측하는 쪽
(예: `state:Observer(fn)`으로 Tween을 건 경우)은 Destroy 시 어떻게
정리되는가?"라는 질문이 자연스럽게 따라오는데, 이건 `retract`의 영역이
아니라 `canExecute`(라이프타임 predicate, `base/lifecycle-pattern.md`의
"생명 바인드 유틸" 절)의 영역이다 — Destroy되면 `retract` 호출 없이 그냥
`canExecute`가 false가 되어 이후 처리 시도 자체가 조용히 no-op된다.
store-bind 일반(Tween 포함)도 같은 결이라 실제로는 이미 일관되게 명시돼
있지만(`base/bind-system-plan.md` "확정된 디스패치 모델" 절), "왜 이
경로엔 retract를 쓰고 저 경로엔 canExecute를 쓰는가"라는 내부 구조상의
이유는 quadnomicon 콘텐츠로 풀어서 설명할 필요가 있음(`research/
documentation-content-map.md` 심화 콘텐츠 후보에 메모) — 지금은 이 메모만
남겨두고 상세 설명은 나중 문서화 단계로 미룸.

## 트윈 옵션 값 모양 — TweenInfo 그대로 vs 편의 필드 (신규, 열린 논의)

**아직 논의 시작 단계 — 나중에 더 다룰 주제로만 남겨둠.** Roblox의
`TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses,
delayTime)`는 순수 포지셔널 생성자인데, Luau엔 named call 문법이 없어서
직접 쓰면 `TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)`
처럼 각 인자가 뭘 뜻하는지 호출부만 보고 알기 어렵다. 후보:

1. **`TweenInfo`를 그대로 받는다** — 사용자가 이미 만들어둔 `TweenInfo`를
   재사용하고 싶은 경우엔 상관없지만, 대부분의 흔한 케이스(길이/이징만
   바꾸고 싶음)에서 매번 포지셔널 생성자를 마주해야 함.
2. **편의 필드로 개별 인자를 받고 기본값을 제공** — 예:
   `{Time=0.3, Style=Enum.EasingStyle.Quad, Reverses=false, ...}`처럼
   이름 붙은 키로 받고 흔한 기본값(예: `Time=0.2`, `Style=Quad`,
   `Direction=Out`)을 채워줌. 명시적으로 `TweenInfo`가 이미 있어서
   재사용하고 싶다는 케이스에도 열어두면(예: `Info = someTweenInfo`
   필드로), 둘 다 지원 가능.

**현재 소견(확정 아님)**: 2번(편의 필드 + 기본값)이 흔한 사용 경험상 더
낫다는 쪽으로 기움 — 대부분의 호출에서 named call이 없는 `TweenInfo.new`의
가독성 문제를 피할 수 있고, 기본값 덕에 짧은 호출도 가능해짐. 다만
구체적인 필드 이름/기본값/`TweenInfo` 재사용 경로의 정확한 문법은 아직
확정 아님 — 나중 논의 대상으로 남김.

## 네임스페이스드 객체 (성능상 이유로 보류)

트윈 대상을 이름으로 찾는 별도 네임스페이스는 성능상 별로라고 판단 —
CollectionService를 쓰는 게 나아 보이지만, 트윈 전용 네임스페이스가 따로 있을
필요가 있는지는 미정(단, 위 정정으로 이 절 자체의 필요성이 낮아짐 — 핸들러가
이미 대상을 직접 받으므로 "나중에 이름으로 찾아서 트윈"할 필요 자체가 잘
없을 수 있음).

## 열린 질문 (`.claude/question.md`에도 취합)

- 기본값(Cancel)은 확정됨. 남은 건 나머지 세 동작(오버라이드/삭제 후 재시작/
  끝점 이동 후 재시작)을 선택하는 옵션 키의 정확한 이름/시그니처 — 구현
  단계에서 확정.
- 트윈 옵션 값 모양(위 "트윈 옵션 값 모양" 절, 신규) — `TweenInfo` 그대로
  받을지 편의 필드+기본값으로 받을지, 소견은 후자 쪽이지만 확정 아님.
- 자연 완료(Completed) 시 per-instance 북키핑 정리 여부 —
  `research/pre-implementation-audit.md` 2-10번 참고, M11 착수 시 확정.
