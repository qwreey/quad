<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-10 두 번째 세션 — Tween 구조 전면 재설계: 독립 Dispatch 핸들러 →
값-레벨 `Tween<T>` 래퍼, `pre-implementation-audit.md` 1-1 완전 해소

사용자가 "트윈도 타입 문제가 있다 — 키 타입을 어떻게 하냐, Property
setter가 더 분발해서 `V`가 `isTween`이면 트윈 넣는 게 낫지 않냐"고
제기하며 시작된 긴 단일 스레드. 기존 확정 모델(`[Tween(key,
tweenData...)] = storeValue`, `v`가 Store인 아무 `k`나 잡는 우선순위
최상위 Dispatch 핸들러, 2026-08-04부터 확정)이 실은
`research/pre-implementation-audit.md` 우선순위1-1이 이미 지적해뒀던
구조적 모호함("애니메이션 없는 일반 반응형 프로퍼티 바인딩도 결국
이름이 Tween인 파일을 거쳐가는가")을 안고 있었다는 걸 사용자 제안이
정확히 겨냥한 것으로 드러나, 세션 내내 살을 붙여 완전히 재설계까지
감. 구 모델은 `archive/tween-special-bind-key-reversed.md`로 이전,
`research/tween-plan.md`는 전면 재작성됨 — 상세 근거는 그 두 문서가
최종 소스, 여기는 결정 흐름만 요약.

**핵심 재설계**: State/Source 언랩(범용 `Dispatch/StoreBind.luau`, `k`/`v`
타입 무관)과 "이 값이 트윈 대상인가" 판단을 완전히 분리 — 후자는 별도
Dispatch 핸들러/우선순위 경쟁이 아니라, **PropertyHandler가 `realv`를
다 풀어낸 뒤 직접 하는 값-레벨 분기**(`isTween(realv)`)로 옮김. `Tween(opts:
{Value: T, ease...}) -> Tween<T>`는 `Store({...})`와 같은 `Type(args)`
테이블 팩토리. 이 전환 하나로 우선순위1-1이 구조적으로 성립 불가능해짐
— 범용 반응형 바인딩과 Tween이 애초에 같은 핸들러를 놓고 경쟁할 지점
자체가 없어짐.

**세션 중 순서대로 다듬어진 세부 결정들**(전부 최종적으로 `research/
tween-plan.md`에 반영):

1. **`Tween.Value`는 plain `T`만, 자체 반응 경로 없음** — 처음엔 `Value`도
   `T|State<T>`를 받아 내부에 별도 Observer를 걸어야 하나 검토했으나,
   바깥 `:Compute`가 소스 변경마다 `Tween{Value=v,...}`를 통째로 재생성해
   StoreBind 재귀를 타므로 불필요함을 확인 — "같은 일 하는 두 번째 경로를
   안 만든다" 원칙 재적용, `Tween<T> = {Value: T, ease...}`로 확정.
2. **3-상태 릴레이션 슬롯으로 `hasBeenSet`과 활성 엔진 트윈 저장을 통합** —
   `relate:GetStrong(inst,k)`가 `RobloxTween | true | nil` 중 하나:
   `nil`=이 키 첫 세팅(애니메이션 없이 즉시 스냅, 기본값→목표값으로
   날아오는 진입 애니메이션 버그 방지), `true`=세팅된 적 있음/활성 트윈
   없음(정상 애니메이션 시작 가능), 엔진 객체=활성 트윈 있음(override
   정책대로 정리 먼저). 사용자가 직접 "hasBeenSet은 어차피 트윈에만
   쓰이니 트윈 저장 슬롯 하나로 합치자"고 제안해 확정.
3. **활성 트윈이 있는데 plain 값이 들어오는 경우의 순서 규칙 신설** —
   먼저 override 정책대로 이전 트윈을 정리(멈추거나 끝냄)하고, **그
   정리가 끝난 뒤에만** 새 값을 세팅. 순서가 뒤바뀌면 이전 트윈의 다음
   인터폴레이션 프레임이 방금 세팅한 값을 덮어쓸 위험이 있어서 — 사용자가
   직접 짚은 시퀀싱 버그.
4. **타입 대수: `T' = T | Tween<T>` 치환만으로 해결, 새 타입 기계 불필요** —
   지금 프로퍼티류 필드가 전부 `T | State<T>` 모양으로 통일돼 있는데,
   여기서 "이 필드의 `T`" 자체를 `T' = T | Tween<T>`로 치환하면 자동으로
   `T | Tween<T> | State<T | Tween<T>>`가 나옴 — Modifier/State/Source/
   StoreBind 코드엔 `Tween` 인지 로직이 전혀 안 들어감(StoreBind는 원래도
   페이로드 타입에 무관하게 `isState`만 봄), 타입 생성 스크립트가 필드
   타입 문자열만 바꾸면 끝. 사용자가 직접 대수적으로 도출.
5. **`useTween` 우회 — 새 옵션 필드 없이 해소.** 이전엔
   `Tween{useTween=state<boolean>}`처럼 별도 필드가 필요하다고 열어뒀으나,
   2026-08-07 일곱 번째 세션에 확정된 `state:Apply(factory)` sugar 위에
   `someState:Apply(Animate(reduceMotion, opts))`처럼 조건부로 `Tween{...}`를
   씌우거나 안 씌우는 `:Compute` 팩토리 하나로 공짜로 풀림 — 새 base
   메커니즘 불필요.
6. **`Animate` 콤비네이터는 quad-roblox 유틸, base 프리미티브 아님** —
   `Tween<T>` 값 타입/`isTween`만 base(`quad-base/Tween.luau`)에 있고,
   `Animate`는 이미 있는 `:Apply`/`:Compute`/`Tween{...}`를 조합한 편의
   함수라 나중에 이름/모양을 자유롭게 바꿔도 base 계약에 영향 없음 —
   사용자 표현으로 "저비용 고효율 엔지니어링".
7. **패키지 경계는 Tag가 이미 밟은 분리를 그대로 재사용** — quad-base:
   `Tween.luau`(값 타입만). quad-roblox: `Handlers/Property.luau`(isTween
   분기+3-상태 저장+override 정책 흡수, 기존 독립 `Handlers/Tween.luau`
   폐기) + `Animate.luau`(신규).
8. **부수 발견 — `retract`가 Tween 경로에서 사실상 필요 없어짐.** 기존
   모델에서 "Tween↔프로퍼티 핸들러 타입 교체"가 `retract`가 실제로
   의미를 갖는 유일한 대표 예시였는데, 새 모델에선 매치되는 Dispatch
   핸들러가 항상 PropertyHandler 하나뿐이라 이 케이스 자체가 사라짐 —
   트윈 취소/전환은 PropertyHandler 내부의 3-상태 슬롯 로직으로 대체(Tag가
   이미 하는 "diff는 process 자신이 담당" 패턴과 같은 모양). `retract`
   필드 자체는 "생략 불가" 일반 규칙이라 여전히 정의는 해두되, 실제
   호출은 거의 없어짐. Tag(핸들러 타입이 실제로 바뀌게 재설계되어
   `retract`가 필요해진 사례)와 Tween(핸들러 타입이 안 바뀌게 재설계되어
   `retract` 필요성이 사라진 사례)을 서로 반대 방향 사례로 archive 문서에
   대비해둠 — quadnomicon 소재.
9. **`Tween<T>`의 핸들러 계층 분류 정정** — `base/modifier-plan.md`가
   원래 Tween을 Slot/Tag/Attribute와 같은 "dispatch 참가자"(State/Source에
   담겨도 재귀 재-dispatch가 그대로 처리해주는 부류)로 묶어뒀는데, 이제
   `Tween<T>`는 `process`/`retract`가 없는 순수 raw 데이터 값이라 `None`과
   같은 분류로 정정 — Modifier 필드/`State<Modifier>`가 막는 "핸들러
   계층 값 → error" 규칙에 안 걸린다는 결론은 안 바뀜(그냥 raw 값이라서로
   근거가 바뀜).
10. **`initValue`(진입 애니메이션)와 hasBeenSet의 긴장 관계를 기록만
    해둠** — hasBeenSet이 "첫 세팅은 무조건 스냅"을 기본 동작으로
    확정했으므로, 나중에 `initValue`(다이얼로그 슬라이드-인 등)가 실제로
    필요해지면 이 억제 동작을 명시적으로 우회하는 방법까지 같이 설계해야
    함 — 새 결정 없이 상충 관계만 `research/tween-plan.md`에 남김.

**여전히 열려있는 것**(M11 착수 시 확정): override 정책 4가지 중 기본값
Cancel 외 세 옵션의 정확한 키 이름/시그니처, Tween→plain 전환에 5번째
옵션이 필요한지, 트윈 옵션 값 모양(`TweenInfo` 그대로 vs 편의 필드 — 소견은
후자), `Animate`의 정확한 시그니처(조건/옵션 분리 vs 통합).

**반영된 파일**: `research/tween-plan.md`(전면 재작성, 최종 소스),
`archive/tween-special-bind-key-reversed.md`(신규, 구 모델 원문+역전
사유), `base/bind-system-plan.md`(9곳 — "확정된 디스패치 모델"의 대표
예시를 Tween에서 StoreBind로, `retract` 필요 패턴 예시를 Tag로 교체,
"Dispatch는 프리미티브가 아니다"/"Dispatch 체인" 절의 핸들러 목록에서
Tween 제거, `None` 센티널 절 예시 갱신, Ref/Brand 절 문구 정정),
`base/architecture.md`(소스트리 — `quad-base/Tween.luau` 신설,
`quad-roblox/Handlers/Tween.luau` 삭제하고 `Handlers/Property.luau`
설명에 흡수, `Animate.luau` 신설), `base/modifier-plan.md`(핸들러 계층
분류에서 Tween 제외 + 신규 "10. `Tween<T>`와의 타입 합성" 절),
`research/pre-implementation-audit.md`(우선순위1-1 해소 표시),
`ROADMAP.md`(M11 전면 재작성, M2/M7 체크박스 갱신), `.claude/question.md`/
`.claude/README.md`(참조 동기화).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정/문서 정리라 M0 착수 우선순위 자체는
그대로. M11 착수 시점이 오면 위 "여전히 열려있는 것" 목록부터 확인.

