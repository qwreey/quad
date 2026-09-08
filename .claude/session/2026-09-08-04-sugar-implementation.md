# 2026-09-08-04 — 순수 슈거 셋 구현(Debounce/Throttle · 생명주기 훅 · Fallback/Traceback), 시간 op 배선

**배경**: round8 누적 감사가 열린 문항 0으로 닫힌 뒤(`session/2026-09-08-03-cumulative-audit.md`), 다음 구간을 "문서화·타입
정형화"로 잡자는 메인의 제안에 사용자가 이렇게 답했다 — *"솔찍히, 문서화는 이동하기 뭐함. Debounce 나 Throttle 이랑 슈거 몇몇은
진짜 base 에 올릴건데, 나중에 또 문서를 다시 생각해야함. 이거 전반에 대해서 처리 가능하게 간단한 슈거라 만들어 놓고 다듬기 하는게
맞아보이는데 어떻게 봐? 타입 정형화는 앞당길 수 있다 쳐도, 문서화는 진짜 뒤야."* 메인 동의(문서는 릴리즈 표면을 서술하므로 표면이
먼저). 같은 메시지에서 시간·스텝 op의 자리를 물었다 — 순수 슈거이므로 플러그인으로 빼도 되지만 그러면 `quad-roblox-…`식 프로바이더가
하나 더 늘어 spring처럼 두 짝을 들고 다녀야 하고, 수요는 spring과 달리 아주 일반적이며, *"quad-base 안에서 엔진이 step 을 제공하는
경로를 넣어도 된다고 봐. 만일 타이머 구현인 setTimeout 같은걸 base 상 두고, 심을 수 있는 구조로 둔다면 렌더 스탭/애니메이션 리퀘스트는
같은 경로로 두는게 맞아. 아니면 엔진 경로를 심히 타므로 … 분리해야한다면 spring 처럼 분리되어야할듯."* 메인 의견(채팅으로 회신): 시간·
스텝 op는 base 주입 op 경로가 맞다 — 이미 `architecture.md`가 시간 op 둘을 그 목록에 올려 두었고 미주입 스텁 계약도 `native*`와
같다; 분리 프로바이더는 패키지만 늘리고 얻는 게 없다; 렌더 스텝은 같은 경로가 맞되 지금 쓰는 곳이 없으니 이름·계약만 예약 슬롯으로
정본에 두고 spring이 그 위에 얹히게 하자. 사용자: *"다음 작업을 수행해보자. 필요한 실측을 수행하고, 결정이 필요한 부분이 있다면
나에게 물어도 좋음."* 그래서 이 세션.

## 1. 무엇을 만들었나

정본이 이미 닫혀 있는 셋만 — `Operator`는 네임스페이스 이름·포함 범위가 미정(`research/operator-sugar-plan.md`)이라 뺐다(문항 (f)).

- **`quad-base/src/Debounce.luau`** — `Debounce{}`/`Throttle{}` 애플리커티브 팩토리(`__apply` 메소드형, `H-158`). 구현은 하나,
  `reset` 한 비트(정본 1-1절). `state:Gate(setup)` 안에서 게이트당 사적 `Blocker`를 만들어 `pass = b:Policy(emit)`로 상류 emit
  경로를 위임하고, 타이머·핸들 경로는 `emit()`/`emit(false)`를 직접 불러 반환값("보류분이 있었나")으로 창 재개방을 판정한다
  (gate-plan 5번 두 경로 표). 창 상태(`_window`/`_cap` 타이머 핸들)는 업밸류가 아니라 핸들 테이블 `h`의 필드 — `onUpstreamEmit`
  클로저가 `h`를 강하게 쥐어 게이트 노드만큼 살고, 팩토리의 weak 레지스트리(`_instances`)는 그 `h`를 키로 브로드캐스트한다
  (`H-63` 소유권 관용구 그대로). `opts.Handle`(Ref)엔 Apply 시점에 `h`를 `:Set`.
- **시간 op 둘** — quad-base `LifetimeHandle.luau`에 `notInstalled` 스텁(`bindLifetime` 그룹), quad-roblox `EngineOps.luau`에
  `task.delay(delay, func)`/`task.cancel`(인자 순서 뒤집음, `task`는 호출 시점 읽기라 spec이 `getfenv`로 심는다), mock에
  **가상 시계**(`advanceTime(dt)`가 (at, seq) 순으로 due 타이머를 발화 — 콜백이 같은 advance 안에 예약한 타이머도 그 호출에서
  돈다; `now`/`pendingTimers`/`resetTimers`/`timerLog`).
- **`quad-base/src/LifecycleHooks.luau`** — 정본 스케치 그대로(`guard` nil 가드, 2-인자 흘림, `Effect(function() return fn end)`).
  인스턴스별 `Init`(`Effect`가 인스턴스별).
- **`quad-base/src/Fallback.luau`** — 정본 스케치 그대로, 의존 없는 잎, `init.luau` 리터럴 재export.
- quad-types: `Timeout`·`GateHandle`·`DebounceOptions`·`ThrottleOptions`·`TimedGate` + `Quad` 필드 아홉(시간 op 둘, 슈거 일곱).
- 스펙 넷 신설(`spec.debounce` 11절·`spec.hooks`·`spec.fallback`·quad-roblox `spec.timers`), `spec.robloxfactory`의 "시간 op는
  미설치" 단언을 뒤집음. test.sh exit 0(스펙 54).

## 2. 구현하면서 밟은 것

- **`Blocker:OffWithoutEmit()`은 플래그 뒤집기가 아니다.** 첫 구현은 창 끝에 "idle로 먼저 가고(`b:OffWithoutEmit()`) 그 다음
  `emit()`"이라는 `Blocker.Off`의 순서를 흉내 냈는데, `OffWithoutEmit`은 등록된 핸들로 `emit(false)`를 돌려 보류분을 **버린다**
  (`Blocker.luau` 헤더 그대로) — spec 2절이 첫 실행에서 잡았다(0.3초 뒤 발화 0회). 고친 순서: 타이머 경로는 `emit()`으로 먼저
  flush하고, 재진입 emit이 이미 다음 창을 열었으면 그대로 두고, 아니면 통과분이 있었을 때만 창을 다시 열고, 없으면 그때 Off(빈
  집합에서의 `OffWithoutEmit`은 no-op이라 플래그만 남는다). `Flush` 핸들은 `emit()` 뒤 통과분이 있을 때만 창을 지금부터 다시
  연다 — 보류분이 없으면 진행 중인 창을 건드리지 않는 진짜 no-op(첫 구현은 이 경우에도 창을 죽였다, spec 7절).
- **`os.clock()`을 base에서 안 읽기로.** 정본 6-1절은 `MaxTime`을 `min(Time, 남은 MaxTime)` 한 타이머로 접는 걸 권했지만 그러면
  base가 실제 시계를 읽어 mock 가상 시간과 어긋난다 — 스펙이 결정론을 잃는다. 7절 (b) 형태(타이머 둘) 채택, 문항 (c).
- **스펙의 부동소수 누적** — `advance(0.2)` 열 번은 1.9999999999999998이라 2.0의 cap이 안 돈다. 절대 시각으로 전진하는 `advanceTo`.
- **Studio require 캐시** — rojo 싱크된 새 파일이 `require(quad-base.src)`엔 안 보인다(옛 본문 캐시). 폴더 `:Clone()` 뒤 사본을
  `require`하면 된다(`audit/sugar-studio-2026-09-08.md`).
- **`task.cancel`은 dead thread에 무해** — 처음엔 "Studio가 에러 낸다"고 가정하고 `coroutine.status` 가드를 넣었는데 실측은 에러
  없음. 가드·주석 제거.

## 3. 실측(Studio)

`audit/sugar-studio-2026-09-08.md`: Throttle 0.00/0.51/1.01/1.79, Debounce 0.42 — 정본 1-1절 표와 일치.

## 4. 사용자 몫 — `question.md` 0절 (a)~(g)

마커 이름(`__quadTimeout` vs 옛 `__type_timeout`), `GateHandle` 메소드형, `MaxTime` 타이머 둘, `Flush`가 `Trailing`과 무관,
`Fallback` 부분 트리 미회수 갈래(권고 (3) UB), `Operator` 이름·범위, 렌더 스텝 op 예약 슬롯. 코드는 어느 갈래도 선점하지 않았다.

## 5. 절차

opus 단일 맥락 리뷰 1회(발견은 평문, 마지막 메시지 하나) → 반영 → sonnet 감사자 1패스(diff 범위) → doc-check ERROR 0 → 커밋.
결과는 `qa-request/post-implementation-review-round9.md` — opus 리뷰 HIGH 0·MED 3·LOW 여럿(`H-509` `openWindow` 상태 변경 순서
— `H-392`/`H-445` 선례 세 번째, `H-510` `held` 판정, `H-511` `Timeout` 반환 타입, `H-512` gate-plan 5번 옛 문장, `H-513` GC 상한
`2 × Time`·Handle 고정, `H-514` mock 주석, `H-515` 스펙 7b·10b, `H-516` 옛 표기), 감사자 다섯 건(배너가 부정하는 "맨 뒤" 문장).
새 규칙이 드는 셋은 문항 (h)~(j). 반영 뒤 test.sh exit 0(스펙 54), doc-check ERROR 0.

## 6. 사용자 회신과 둘째 단위 (같은 밤)

회신: (a) 새 마커 OK · (b) 메소드형 OK · (c) 확인 · (d) Flush 동의 · (e) UB — *"큰 부분 단위의 fallback 을 걸어준다는 목적 자체로
보아, 유저가 버그 신고 하기 편하게 만드는 것이지 … 코드가 죽는걸 권장하는게 아님 … 한 부분이 죽는걸로 모든 부분이 죽는 블레스트
범위가 큰걸 막는 용도일 뿐 … 동적 바운딩 되는 사이드에서 fallback 거는건 의도상 안 맞는 부분 … 고아가 쌓이는건 우리가 처리 안
해줘"* · (f) `Operator` 이름 OK, 비트·산술 OK, 비교는 분기 없이는 뜻이 없고(`IfElse`가 있으면 사용성↑), `And`/`Or` 결합 비추
· (g) 당장 안 함(spring은 잠정 릴리즈 대상일 뿐) · (h)~(j) 확인(flush 중 cancel은 의미가 안 맞아 UB).

추가 채택 둘 — 문서화 스캐폴딩 에이전트가 제기한 무시 파일 `docs-ignoreme/research/preref-unwrap-sugar-plan.md`·
`explicit-context-sugar-plan.md`(같은 폴더의 spring 문서는 무시). `Context`에 대한 사용자 설명: *"우리가 store 등을 모아서 던질
표면을 안 줬다는거 … context 는 어떤 store 든 provider 를 키로써 담아주고 모르는 계층은 그냥 무시하고, 내려 보내기가 가능해지는
구조임 … Get은 nil을 떼고 던지고, 대신 있는지 확인을 위한 peek() 나 has 같은걸 제공"*, 그리고 `context-rejected`와의 경계: *"이건
슈거이고 직접적으로 내려먹이는거라 약간 다름 … react 식 컨텍스트가 아니라, 명시 컨텍스트라서 괜찮아."*

구현: `Context.luau`(`Context()`/`Context.Provider(name?)`/`Set`/`Get`(에러)/`Peek`, 브랜드 둘), `Operator.luau`(Not·Sum·Product·
Min·Max·Clamp·Band·Bor·Bxor·Bnot·Shl·Shr·Alternative), `Ref:Unwrap()`(quad-types `StripNil<T>` 타입 함수 — 스파이크로 구·신 솔버
확인, `typing-limits.md` 8.14), (j) Handle 기충전 에러. 밟은 것: `Operator.Not`의 self는 `any`여야 `Apply` 함수 오버로드에 들어간다
(제네릭 함수 값·`StateData<any>` 둘 다 실패); quad-types를 고치면 `pesde install`로 복사본을 갱신해야 spec이 새 타입을 본다;
`Store` 기본값은 `Source`여야 한다(spec 작성 실수). 스펙 넷 추가·보강(56). 새 정본 `base/context-plan.md`, `ref-plan.md` `:Unwrap()`
절, operator 플랜 머리 배너, 아카이브 경계 배너. 남은 문항 (k) Context 불변 확장, (l) IfElse.

## 7. 후속 회신 — (k)(l) 닫힘, 백로그 분리, 타입드 `Index` 실측

사용자: (k) 불변 확장 불필요 — *"context 는 진실 원천이 하나 … 디버깅 할 때 context 를 찍으면 전부 확인 가능. 분기가 없는게
맞아보여"*(`context-plan.md`에 원문). Attr unset·중첩 평탄화·`IfElse`(+`Concat`/`Sorted`/`Filtered`)는 각각 별도 백로그 —
*"해당 함수는 sum 처럼 아무 복잡한게 없는것과 다르게, 타입 표면 결정이 필요해서 아직 구현 못 해. 그리고 이 구현을 안 한다고
릴리즈가 막히는게 아니고, 이미 있는 슈거 그룹 문서에 더해지는 정도라, 문서 재개편은 없을거야."* 새 제안: 테마 키 조회용
`Apply(Index<<Type>>("key"))` — *"타입 함수상 그게 가능한지? 아마 안 될것 같아보이긴 함."* 스파이크 여섯(사용자가 인터럽트로 준
힌트 `K & (string | "")`·코퍼스의 `K & keyof<T>` 관용구 포함): 필드 경유는 반환 자리 `index<T, K>`가 경계 제네릭을 못 풀고, State
메소드 형태는 `keyof<T>`가 비테이블 `T`의 `State`를 전부 깨뜨린다 — `typing-limits.md` 8.15, 백로그. 남은 사용자 몫 없음.

둘째 단위 리뷰·감사(round9 §7): `H-517`(Handle 게이트를 `state:Gate` 앞·outermost로 — §6 교훈을 그 자리에서 다시 밟았다),
`H-518`(Operator nil 인자 에러, `H-199` 관용구), `H-519`(Context 강참조·사본 신원 서술, 생성자 태그 제거), `H-520`(주석·문서 자리).
test.sh exit 0(스펙 56), doc-check ERROR 0, 신 솔버 스윕 클린.
