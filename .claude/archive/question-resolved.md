# [해소 아카이브] `question.md`에서 걷어낸 결정 완료 항목

**분리 시점**: 2026-08-13 아홉 번째 세션. 사용자 지적 —

> "question.md 또한, 사람이 봐야하는 문서인데 해결된 것이 많아서 필터해서
> 필요한 부분만 읽어보기 힘듦. archive 되어야할 요소는 archive 에
> 옮겨주는게 맞아보입니다."

`question.md`는 **사용자가 답해야 할 것만** 남기는 문서로 좁혔고, 이미
결정이 끝난 항목(당시 32개 `[해소됨]` 마커)은 근거와 함께 여기로 옮김.
**결정 내용은 하나도 안 바뀜 — 읽는 자리만 옮긴 것.**

찾는 법: 지금 유효한 설계는 항상 `base/`가 소스이고, 이 문서는 "그 결정이
왜/언제 그렇게 났는가"를 되짚을 때만 볼 것. 아래는 분리 직전의 전문
그대로이며, 당시 열려 있던 항목(0-Y/0-Z/0-A/0-B와 용어·낮은 우선순위의
미확정 건)은 `question.md`에도 있어 중복됨.

> **[2026-08-13 열세 번째 세션 갱신] `0-Y`는 그 뒤 해소됐음** — 해당
> 절 머리에 해소 배너를 달아뒀고, `question.md`에서는 제거됨. 지금
> 유효한 규약은 `base/typing-limits.md`. 나머지(0-Z/0-A/0-B 등)는
> 여전히 `question.md`가 소스.

## [해소됨, 2026-08-18 구현 전 QA] `DI` → `D`(Declarative) 리네임 확정

2026-08-08 용어 정리 라운드부터 `question.md` **1순위**로 열려 있던 항목.
사용자가 구현 전 QA 라운드 중 직접 확정("이거 하면서 DI => D 확정하자").

- **확정 내용 두 갈래**: (1) 네임스페이스/모듈 자체는 `DI` → **`D`**
  (`D.Frame` / `D/init.luau` / `D.InstSlot` / `D.FrameModifier`),
  (2) "특수 DI 키"라는 **설명용 표현**은 `D`로 바꾸지 않고 **"특수 키"로
  단순화**(수식어를 빼도 문맥상 통한다는 판단).
- **`D`로 가는 근거**: (1) "Instance" 전용 개념이 아니라 quad-* 전반의
  declare 요소로 확장 가능한 이름, (2) 엔진 종속 없이 다른 백엔드에서도
  재사용 가능, (3) `D.FrameModifier`류 타입 프리픽스가 짧아야 한다는 실용적
  제약. 원래 이름 `DI`의 문제는 **"Dependency Injection"과 완전히 겹쳐 실제로
  오해가 있었던 전례**.
- **2026-08-08에 확정을 미룬 유일한 사유였던 "한 글자 식별자의 검색성/
  자기설명력"은 표기 규약으로 보완** — 문서에서 `D`가 처음 나오는 자리에서는
  항상 `D`(Declarative)로 풀어쓴다(`base/architecture.md`의 "코드 스타일 —
  네이밍 케이싱" 절).
- 지금 유효한 설계는 `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트
  네이밍 인체공학" 절이 소스.

## [해소됨, 2026-08-18 구현 전 QA 2라운드 후속] `RC-1` — `recompute` 트리거 모델 재설계

`base/dispatch-core-plan.md`의 `recompute`가 배열 위치를 순차 등록하는
동안(`Frame{A,B}`처럼 정적 자식 2개짜리도) 아직 등록 안 된 자리를 `nil`로
읽어 산술 에러를 내던 크래시(`qa-request/pre-implementation-qa-round2.md`의
"RC-1" 절에서 손 트레이싱으로 발견) — 같은 날 후속 세션에서 사용자가
Blocker 재사용 설계를 직접 제시해 해결됨.

- **핵심**: owner(물리 `inst` 또는 Slot)마다 `Relate`로 들고 있는 전용
  `Blocker`를 배치(`Dispatch.drive`의 배열 파트 순회, `attachSlot`의 자기
  `_elements` flush) 시작 시 `On`, `setLength`의 Observer 콜백(등록 즉시
  1회 실행 포함)이 `blocker:IsOn()`이면 `recompute`를 건너뜀. 배치가
  끝나면 `blocker:OffWithoutEmit()` + 명시적 `recompute` 딱 1회.
  `setOffsetSource`는 등록되는 그 자리에서 앞선 형제들의 길이 합을 직접
  계산해 즉시 `:Set`해서(recompute를 안 기다림) 배치 도중 `:List`가
  실체화되며 옛 offset을 읽는 문제도 같이 없앰.
- **Blocker에 신설된 API**: `IsOn()`(`IsBlocked` 조회 얇은 래퍼),
  `OffWithoutEmit()`(끄되 gated state의 대기 emit은 흘려보내지 않음,
  `HasBlockedEmit`은 그대로 리셋) — `state:Block()`을 거치지 않고 직접
  쓰는 첫 사례. 처음 요청됐던 `HasBlocked`(Blocker 자신의 새 최상위
  플래그)는 논의 중 불필요함이 확인돼 신설 안 함.
- **중첩 Slot마다 별도 Blocker**(부모와 공유 금지, `blocker-plan.md`의
  재진입 미지원 규칙 그대로), **런타임 단건 `slot:Add()`는 게이팅 불필요**
  (이미 안정된 앞선 position만 참조하므로 무관) — 둘 다 사용자가 직접
  확인.
- **후속 정정 — `attachSlot` 호출 순서**: 기존 의사코드는 `setLength`를
  먼저 불렀는데, "호출 순서는 `setOffsetSource` → `setLength`" 일반
  규칙과 어긋나 있었음이 드러남(RC-1로 `setOffsetSource`가 즉시 계산을
  하게 되며 순서가 겉으로 드러났기 때문) — Slot의 진짜 `.Length`는
  `activateList` 실체화 뒤에야 확정되므로 `setOffsetSource` → 실체화 →
  `setLength` → 물리 마운트 순으로 바로잡음. 같은 논의에서 **코루틴 yield
  금지 불변식**도 확정(`Dispatch.process`/`attachSlot` 호출 체인 도중
  yield는 UB).
- 지금 유효한 설계는 `base/dispatch-core-plan.md`의 "배치 등록을 안전하게
  만드는 Blocker 게이팅" 절, `base/slot-plan.md`의 "재귀 메커니즘" 절,
  `base/blocker-plan.md`의 "`state:Block()` 없이 직접 쓰는 두 번째 용례"
  절이 소스. 논의 원문(설계 제안 전문, 확인 질문 3개와 답변)은
  `qa-request/pre-implementation-qa-round2.md`의 "RC-1" 절.

## [해소됨, 2026-08-18 구현 전 QA 3라운드] `bk.N`의 수명주기 + `RC-3`/`RC-4`(`attachSlot`의 `:List` 초기 population 중복 처리)

`recompute`가 순회 상한으로 쓰는 `bk.N`이 Slot을 ownerKey로 재사용할 때
무엇이고 언제 갱신되는지 문서에 없던 갭(`qa-request/
pre-implementation-qa-round3.md`가 원본) — 트레이싱 중 `attachSlot`이
`:List`의 최초 population을 이중 처리하는 결함(`RC-3`/`RC-4`)도 같이
발견됐고, 셋 다 같은 세션에 사용자가 직접 해법을 제시해 해결됨.

- **`bk.N` = 그때그때 실제 개수**, `inst`/Slot 두 owner 타입 동일 규칙 —
  `Dispatch.setLength`(항상 뒤에 불림, `setOffsetSource`는 안 건드림)가
  이전에 없던 더 큰 position을
  등록할 때마다 늘고, `spliceArraysDown`(Slot의 `rawRemove`/`rawUnmount`)이
  위치를 구조적으로 지울 때 줄어듦. **최초 분석 오류를 사용자가 직접
  정정**: 필자는 "그때그때 실제 개수"면 배치 등록 중 `RC-1`과 같은
  크래시가 되돌아온다고 판단했으나, Blocker 게이팅은 `bk.N`이 아니라
  `blocker:IsOn()`만 확인하므로 배치 중엔 `recompute` 자체가 안 돌아
  `bk.N`이 무엇이든 무관함 — `RC-1`의 원래 크래시는 "`bk.N`이 배치 전에
  이미 최종 크기로 고정"이라는, 이제는 사라진 전제의 부산물이었을 뿐.
  Blocker 게이팅이 여전히 필요한 이유는 크래시 방지가 아니라 배치 비용
  (O(N²)→O(N)).
- **`RC-3`/`RC-4`**: `attachSlot`이 `slot._mounted = true`를 맨 위에서
  세팅해뒀던 탓에, `:List`의 최초 reconcile(`activateList`, 아직
  flush 루프의 Blocker가 켜지기 전)이 부르는 `rawAdd`가 "이미 마운트됨"
  경로를 타 항목마다 무게이팅 `recompute`가 돌고(`RC-3`), nested Slot
  요소는 그 자리에서 이미 `attachSlot`된 뒤 뒤이은 flush 루프가 같은
  요소를 또 `attachSlot`해 이중 실행됐다(`RC-4`). **해법(사용자 제시)**:
  `slot._mounted = true`를 `activateList` 호출 **뒤**로 옮기면 끝 —
  `activateList` 도중엔 `rawAdd`가 "아직 마운트 전" 경로(그냥
  `_elements`에만 push)를 타고, flush 루프가 `:List`/수동 CRUD 구분 없이
  모든 요소를 처음이자 한 번만 물리 마운트한다. `rawAdd`의 "이미
  마운트됨" 즉시-`attachSlot` 분기 자체는 그대로 남음 — 최초 flush
  이후의 런타임 갱신(예: `:List`의 `data`가 나중에 바뀌어 nested Slot이
  새로 추가되는 경우)엔 여전히 필요한 경로이기 때문.
- **부수 발견**: `spliceArraysDown`이 밀어야 할 배열 목록에
  `bk.observers`가 빠져 있었음(`_elements`/`lengthList`/`sourceList`
  셋만 서술돼 있었음) — 같이 반영.
- **`ROADMAP.md` 마일스톤 정합성**: `RC-1`의 Blocker 게이팅으로 M2
  (`Dispatch.setLength`/`setOffsetSource`)가 M3 체크박스에 있는
  `Blocker.luau`에 구조적으로 의존하게 됐는데 로드맵 어디에도 이 순서
  의존이 명시가 안 돼 있던 것도 발견 — 가장 보수적인 조치(마일스톤
  재편 없이 M2 체크박스에 각주만 추가)로 우선 반영, 재편 여부는 열려
  있음.
- 지금 유효한 설계는 `base/dispatch-core-plan.md`의 "저장 위치"/"배치
  등록을 안전하게 만드는 Blocker 게이팅" 절, `base/slot-plan.md`의
  "재귀 메커니즘"/"파괴" 절, `base/blocker-plan.md`의 "두 번째 용례"
  절이 소스. 논의 원문(최초 분석·사용자 정정·확인 질문과 답변 전문)은
  `qa-request/pre-implementation-qa-round3.md`.

---

# 확인/결정 필요 목록

**2026-08-04 세션 말미에 전체 재정리함.** 예전엔 라운드(1차~6차)별로 문서가
계속 쌓이면서 순서가 시간순도 우선순위순도 아니게 됐고, 이미 해소된 라운드
기록이 새로 열린 질문보다 위에 있는 등 혼동을 유발했음(문서 감사에서 발견).
그 상세 히스토리는 지우지 않았음 — git log로 이 파일의 이전 버전을 보거나,
각 `base/`/`research/` 문서 안의 라운드 표시("2026-08-04 3차 라운드" 등)를
따라가면 그대로 남아있음. 이 문서는 이제 **"지금 열려있는 것" 우선으로만**
구성.

## 지금 열려있는 것 (우선순위순)

### 0-E. ~~무효화 dedup 문장이 `Observer` 계약과 모순~~ **[해소됨, 2026-08-14 — 같은 날 신설·해소]**

> **[해소됨] 결론: 사용자 확정 — "emit은 항상 전파함. `Blocker`나 emit
> 전파 지연요소만 이를 지연할 수 있음. 재계산 막아지는 건 맞음 — 한
> 곳에서 `Get`이 되면, `invalid`하다면 위로 올라가서 받아와서 계산
> 처리된 게 들어오고 cache가 쓰인 다음 `invalid`가 꺼짐."**
>
> 즉 `invalid`는 **캐시 낡음 표시**일 뿐 전파 제어 장치가 아니고,
> 중복 재계산은 pull-recompute + 캐시가 막으며, 중복 통지는 접지 않음.
> 사용자가 "다 다시 써야 한다"고 지시해 **같은 세션에 코퍼스 전체
> 정정 완료** — `base/source-state-plan.md`(전파 규칙 재작성 + "다이아몬드
> 의존성은 무엇이 푸는가" 절 신설 + `Observer` 절 상호 참조),
> `base/architecture.md`, `base/blocker-plan.md`,
> `reference/comparison-fusion-vide.md`,
> `research/framework-comparison-findings.md`, `ROADMAP.md` M0 체크리스트,
> 스파이크 `05`(→`rewrite-required/`), `audit/luau-test-first-run-2026-08-13.md`.
>
> 원문·역전 근거·영향 범위 전체: `archive/invalidate-dedup-propagation-reversed.md`.
> 발견 경위: `research/debounce-throttle-plan.md` 3절.

**아래는 해소 전 원문(2026-08-14 신설 시점).**

**사용자 지적에서 시작**: "emit은 항상 재전파된다. 저 동작(한 번만 접어
뒀다 나중에 1회)은 정확히 `Blocker`가 하는 것." 확인 결과 맞고,
`base/source-state-plan.md`의 "전파 모델 확정" 절에 있는
아래 문장이 **과잉 일반화**로 보임:

> 신호를 받은 State는 자기 `invalid` 플래그만 세우고, **이미 `invalid`였다면
> 그 아래로 더 전파하지 않는다** — 다이아몬드 의존성에서 중복 워크를 막는 장치

**왜 문제인가 — 확정된 계약과 실제로 충돌함**:

1. **`Observer`가 깨짐(가장 심각).** 같은 파일의 "`state:Observer(fn)`"
   절이 **`fn`이 `:Get()`을 안 불러도 되는 것을 명시적으로 허용**함
   ("`Get()` 호출 여부를 작성자가 직접 결정하게 열어둔 것"). 그런데 위
   문장을 액면대로 적용하면 `:Get()`을 안 하는 Observer는 상태가 invalid로
   남아, **두 번째 변경부터 영원히 안 울림**:
   ```
   source:Set(1) → invalid 세팅 → Observer 발화 → fn이 :Get() 안 함
   source:Set(2) → 이미 invalid → 전파 없음 → Observer 침묵 ❌ (이후 계속)
   ```
2. **`base/architecture.md`와 어긋남.** 그쪽은 같은 다이아몬드 문제를
   "**pull-recompute(`Get()` 시점) — Fusion식 eager 노드 없이도 다이아몬드
   의존성 중복 재계산 문제가 풀림**"이라고 서술 — 즉 중복 *평가*를 막는
   주체는 pull-recompute 자체지 `invalid` 플래그가 아님. 플래그 dedup이
   절약하는 건 재계산이 아니라 **플래그 세팅 순회 비용**뿐인데,
   `source-state-plan.md`(분할 전 `bind-system-plan.md`)가 이걸 다이아몬드의
   해결책으로 승격시켜 서술함.
3. **범위 오류.** 다이아몬드가 요구하는 건 **한 번의 전파 파동 안에서의**
   중복 방지인데, 문장은 `invalid`를 시간에 걸쳐 유지되는 상태로 써서
   **이후의 모든 변경**까지 삼킴. 두 범위가 한 문장에 뭉뚱그려짐.
   그리고 "여러 emit을 하나로 접어뒀다 1회 방출"은 사용자 지적대로
   `Blocker`의 `HasBlockedEmit`이 **opt-in으로** 제공하는 동작이라,
   모든 State에 암묵적으로 심으면 `Blocker`의 존재 의의가 절반 사라짐.

**정정안 두 갈래(사용자 선택 필요)**:
- **(a)** 문장을 삭제하고 "emit은 구독자에게 항상 전파된다"만 남김.
- **(b, 권장)** 범위를 못 박아 다시 씀 — "**한 번의 전파 파동 안에서만**
  같은 노드를 두 번 방문하지 않는다(구현 최적화, 의미론에 영향 없음)".
  원 문장이 담으려던 의도(순회 절약)를 살리면서 시간축으로 새는 걸 막음.

**같이 확인할 것**: `source-state-plan.md`의 "`:With`도 새 State 노드로 확정" 절의 근거
2번("빌더면 다이아몬드 dedup을 못 타고 특수 케이스가 생김")이 **약해짐** —
그 장치가 정확성이 아니라 순회 최적화가 되므로. 근거 1·3번이 그대로
유효해 **결론(빌더 기각)은 안 바뀌고**, 근거 2번의 강도만 조정하면 됨.

상세 트레이싱과 배경은 `research/debounce-throttle-plan.md` 3절.
**확정 문서 수정이라 이 세션에선 안 건드림.**

### 0-Y. ~~⭐ 최우선~~ **[해소됨, 2026-08-13 열세 번째 세션]** — `:Compute(fn)`의 lazy 핸들 계약을 유지할 것인가 (2026-08-13 여섯 번째 세션, 첫 실측에서 발견)

> **[해소됨] 결론: 계약은 그대로 유지, 이건 quad가 풀 문제가 아니라
> Luau의 현 한계.** 44개 스파이크로 재실측한 결과 0-Y가 사실 **독립된
> 두 문제**였음이 드러남 — (A) 콜백 파라미터 추론은 타입 선언을
> "데이터부/메소드부"로 쪼개면 **진짜로 풀림**(코드 생성 불필요),
> (B) `Compute`가 `State<U>`를 반환하는 것 자체는 **어떤 방법으로도
> 안 풀림**(아래 선택지 1/2/3 전부 무효 — 특히 "raw 값이면 완전 클린"이라던
> 아래 표의 판정이 실측으로 **뒤집힘**, raw 값 계약도 똑같이 불안전함).
> (B)는 Luau RFC `relax-recursive-type-restriction`이 `Promise<T>.andThen`으로
> 예시 든 바로 그 패턴이라, 지금 선언을 그대로 두면 Luau 쪽 수정만으로
> 코드 변경 없이 풀림. **당장의 대응은 "파생 State를 만드는 자리마다
> 결과 타입을 명시 주석으로 바인딩"** — 그 한 줄만 검증이 안 되고
> 다운스트림 전체는 정상 체크됨(실측 확인).
>
> - 지금 유효한 규약: **`base/typing-limits.md`**(신설)
> - 실측 근거 전문: `audit/type-recursion-issue/`(REPORT.md + spikes 44개)
> - 추적: [`luau-lang/luau#2380`](https://github.com/luau-lang/luau/issues/2380)
>
> 아래는 해소 전 원문(선택지 1/2/3 프레이밍과 "구울 때 인라이닝" 방향
> 포함) — **그 프레이밍 자체가 실측으로 범위를 벗어난 것으로 판명**됐으니
> 히스토리로만 볼 것.

**실측 결과**: 콜백이 lazy `State<T>` 핸들을 받는 quad의 커링 계약이
**Luau 양방향 타입 추론과 충돌**함. 가장 흔한 관용구가 그대로 실패:

```lua
state:Compute(function(s) return s:Get() * 2 end)   -- ❌ TypeError 2건
```

최소 재현으로 원인을 좁힘(`audit/luau-test-first-run-2026-08-13.md`):

| 형태 | 결과 |
|---|---|
| lazy 핸들 + 무주석 인라인 람다 | ❌ |
| 위 + `read Get` 선언 | ❌ |
| 위 + `Get: (self: State<T>) -> T` | ❌ |
| 콜백 파라미터에 타입 주석 | ✅ |
| **콜백이 raw 값 `T`를 받으면** | ✅ **완전 클린** |

즉 표기 조정으로는 안 풀리고, **계약 자체가 원인**. `:Compute`만이
아니라 `Effect`/`Observer`/`Animate`/`Operator` 등 같은 계약을 공유하는
API 전부에 걸리며, 2026-08-07 일곱 번째 세션(커링 스타일 확정)과
2026-08-12 네 번째 세션(`:Get()` 누락 버그 전역 감사)이 전부 이 계약
위에 서 있음.

**선택지**:
1. **계약 유지 + 파라미터 주석 필수** — 설계 변경 없음, 대신 가장 흔한
   자리에 매번 `function(s: State<number>)`를 써야 하는 인체공학 손해.
2. **콜백이 raw 값을 받도록 전환** — 타입 추론은 완벽해지지만 lazy
   평가/trailing deps/`previous` 설계 전반과 충돌. **구조 변경 규모가 큼**
   (사용자가 이번 라운드에서 미리 잡고 싶다고 한 바로 그 종류).
3. **혼합** — 기본은 raw, lazy가 실제로 필요한 자리만 별도 API.

**M0 착수 전에 정하는 게 맞음** — 2번을 고르면 base 문서 다수가 영향받음.

**[사용자 방향, 2026-08-13]** 순환 타입을 만드는 것보다 **`State` 타입
자체를 구울 때(코드 생성 시점) 인라이닝**해주는 쪽이 맞아 보인다는 의견 —
즉 `State<T>`가 자기 자신을 재귀 참조하는 선언을 피하고, 타입 생성기가
각 `T`에 대해 평탄한 타입을 뽑아주는 방향(`Modifier`의 클래스별 flat 타입을
생성기로 뽑는 이미 확정된 패턴과 같은 결). 이러면 `08`에서 걸린
`Recursive type being used with different parameters` 제약도 같이 비켜감.
**다만 이건 사람이 직접 확인해야 할 부분으로 사용자가 보류** — 0-Z(Attribute)와
함께 사용자가 직접 스케치하며 판단할 목록.

**관련 실측 근거**: `08`(재귀 타입 제약), `15`(read-only/read-write `Get`
불일치 — 파싱 실패로 검증불가 상태라 재작성 필요), `14`(Ref 생성자 오버로드가
정상 nilable 사용례까지 막음), `16`(`type function` API 불일치). 전부
`audit/luau-test-first-run-2026-08-13.md`.

### 0-Z. ~~⭐ 최우선~~ **[해소됨, 2026-08-13 열네 번째 세션]** — Attribute 이름 소유권을 무엇으로 판정할 것인가 (2026-08-13 여섯 번째 세션 신설)

> **결론**: 후보 (a)가 아니라 그 변형 — **그룹 전용 키(비공개 `GetKey`)
> + `AttributeKeyHandler`의 이름 claim**. 사용자가 `Attribute:GetKey(name)`
> 아이디어를 제시했고, 트레이싱 결과 (a)만으로는 **그룹↔직접 쓰기 충돌을
> 못 잡는다**는 게 드러나(두 경로가 만나는 말단 핸들러에서 공개 키는
> 같은 객체라 소유자 구분 불가) 전용 키가 필요함이 확인됨. 전용 키가
> 교차 오염을 구조적으로 없애고, claim이 남은 충돌을 즉시 error로
> 드러냄. `GetKey`는 공개 API로 내지 않음(같은 키가 두 자리에 놓이는
> 0-W류 갭을 원천 차단). 정본은 `base/attribute-plan.md` "이름 소유권"
> 절. **아래는 해소 전 원문.**

**이게 지금 유일하게 `base/` 반영을 막고 있는 결정.** 아래 0-A의
재디스패치 모델은 나머지가 전부 확정됐고, 이 항목 하나만 정해지면
⚠️ 배너를 단 **6개 문서**(`bind-system-plan.md`/`tag-plan.md`/
`slot-plan.md`/`attribute-plan.md`/`architecture.md`/`ROADMAP.md`)를
한 번에 옮기면 됨.

**문제**: 새 모델(핸들러 선비교)에서는 그룹 A가 잡아둔
`AttributeKey("foo")` 인덱스 1에 그룹 B가 들어와도 **양쪽 다 `StoreBind`에
매치되므로 "같은 핸들러"로 판정돼 조용히 갈아탐.** 그리고 나중에 A의
클로저가 자기 이름들을 `retractFrom`할 때 B의 바인딩을 대신 철거함
(교차 오염). 예전 "조용한 last-write-wins"가 그대로 돌아옴 — 이번 감사에서
고쳤던 바로 그 증상. 즉 **Dispatch의 점유 체크가 대신 잡아주던 걸 이제
Attribute가 직접 해야 함.**

**사용자 방향(2026-08-13, 심층 분석은 다음 세션)**:
> "Attribute 소유권은 아마 이전 결정을 다시 가져오는게 맞아보이긴 하네요.
> 막 깊게 Key -> Group 필요한것 같지는 않고, 본인 retract 처리를 수행할 때
> 무언가 하면 될듯 한데. 이 부분은 나중에 제가 물리적으로 스케치 해보며
> 심층 분석해보겠습니다."

- **"이전 결정을 다시 가져온다"** = 2026-08-13 네 번째 세션의 이름별
  claimant `Relate`(당시 이름 `owners`). **당시 기각 사유는 새 모델에서
  구조적으로 소멸함** — 그때 버그는 "소유권 반납이 `process`의 `v==nil`
  분기에만 있어서, 그룹이 이름을 통째로 놓는 경로가 그 분기를 안 타
  옛 소유권이 안 지워짐"이었는데, 지금은 **클로저가 항상 불리므로 거기서
  반납**하면 그 구멍이 안 생김. 사용자의 "본인 retract 처리를 수행할 때
  무언가 하면 될듯"이 정확히 이 지점.
- **"막 깊게 Key → Group 필요한 것 같지는 않다"** — 키에서 그룹으로
  거슬러 올라가는 양방향 레지스트리까지는 필요 없고, 이름 → 현재
  claimant 단방향이면 충분할 것이라는 방향.
- 원문 맥락과 기각된 두 중간안(`rawNew` 전용 키, `AttributeGroupKeyHandler`
  체크포인트)은 `archive/checkpoint-handler-pattern-reversed.md`,
  분석은 `archive/dispatch-hintvalue-model-reversed.md` 5절.

**대안 후보(정리해둠)**: (a) 이름별 claimant `Relate`를 Attribute에
국소적으로 — 권고, (b) UB로 두고 문서로만 금지 — 증상이 "조용한 오작동 +
교차 오염"이라 다른 UB들(즉시 스택오버플로/즉시 error)보다 나빠서 비권장,
(c) `Dispatch`에 claimant 개념 일반화 — 이번에 걷어낸 방향이라 반대.

### 0-A. ~~`hintValue` 폐기 → process 하강 중 핸들러 비교~~ **[해소됨, 2026-08-13 열네 번째 세션 — base 반영 완료]** (2026-08-13 여섯 번째 세션)

> **결론**: 모델 그대로 채택되어 `base/dispatch-core-plan.md`(같은 세션에
> `bind-system-plan.md`에서 분리 신설)로 전면 반영. 부수적으로
> `Dispatch.retractFrom`이 4-인자에서 **3-인자**가 됐음(값을 넘기는 경로가
> `Dispatch.process`의 "같은 핸들러" 분기 하나로 통일되어, 외부가 힌트를
> 만들어 넣을 자리 자체가 사라짐). 배너를 달고 있던 7개 문서 전부 갱신
> 완료. 뒤집힌 옛 모델 원문은 `archive/dispatch-hintvalue-model-reversed.md`.
> **아래는 해소 전 원문.**

**검토 결과 사용자 지적이 맞음 — 현행 `hintValue`엔 실제 결함이 있음.**
힌트가 "그 자리에 곧 디스패치될 raw 값"이라 `None` 센티널이나 `State`/
`Tween` 같은 래퍼가 그대로 넘어갈 수 있고, 그러면 말단 핸들러의
`isTag(hint)` 가드가 거짓이 되어 **깜빡임/재생성 방지가 조용히 꺼짐**
(정확성은 유지돼서 지금까지 안 드러났음). 상세 재현·분석·제안은
`archive/dispatch-hintvalue-model-reversed.md`.

**후속 라운드에서 모델은 거의 확정됨** — 래핑 핸들러가 `retractFrom`을
선행 호출하는 걸 폐기하고, `Dispatch.process` 안에서 **핸들러를 먼저
비교**해 (같으면 그 자리 클로저에 새 값을 넘기고 자기 `process` 재호출,
다르면 그 자리부터 아래를 전량 철거). 이걸로 (a) 힌트의 타입이
구조적으로 보장되고(같은 핸들러일 때만 값이 넘어가므로), (b) 깊은 체인의
힌트 유실도 사라지며(각 레벨이 자기 재프로세스에서 자기 힌트를 받음),
(c) `oldValue`를 따로 넘기자던 보완안은 불필요해짐(사용자 지적:
"클로저라 이미 본인이 알지 않아요?" — 맞음, `chains`에 추가로 저장할 건
비교용 `handler` 하나뿐), (d) `HandlerChanged` 마커도 불필요(핸들러가
바뀌었다는 건 retractor가 `nil` 힌트로 불린다는 사실로 이미 표현됨).

**남은 열린 항목은 Attribute 이름 소유권 하나뿐 — 위 0-Z로 분리해
최우선 배치**(사용자가 다음 세션에 직접 스케치하며 심층 분석하기로).
그 하나 외에는 이 항목에 결정할 게 없음.

**실행 규모**: `base/`의 `bind-system-plan.md`/`tag-plan.md`/`slot-plan.md`/
`attribute-plan.md` 의사코드 재작성 + `architecture.md` 소스트리 서술과
`ROADMAP.md` M2/M4/M6/M10 체크리스트 — 0-Z 하나만 정해지면 한 번에 옮기면
됨(어디를 어떻게 고칠지는 `archive/dispatch-hintvalue-model-reversed.md` 6절에
파일별로 적어둠 — 뒤 둘은 2026-08-13 7차 감사에서 그 목록에 빠져 있던 걸
발견해 추가). **그때까지 `base/`의 현행 `hintValue` 서술이 유효** —
아직 안 옮겼다는 걸 잊고 base만 읽으면 옛 모델로 구현하게 되니 주의.

### 0-B. `dispose(any)` — 시그니처/범위 (2026-08-13 여섯 번째 세션 신설, 사용자 제안)

`State<Slot>` 교체를 파괴가 아니라 **언마운트**로 확정하면서(`state<Frame>`와
동일, `base/slot-plan.md`), 명시적 파괴 수단으로 base 탑레벨 `dispose(value)`를
제공하기로 방향 확정. "이 값이 지금 어디 마운트돼 있는가"는 이미
`elementOwner`가 들고 있어(다중 마운트 error 판정용) 새 부기가 필요 없음.

**[확정, 사용자] 시맨틱은 "거부"** — 대상이 아직 어느 트리에 의해
살아있길 요구되고 있으면 **파괴를 거부하고 즉시 error**. 떼어내주지
않음(떼어내는 건 `Set`=언마운트의 몫, `dispose`는 그 뒤). 근거: 엔진은
`Destroy`/`Clear`에 에러를 안 내지만 quad의 `_elements`/`lengthList`/
`sourceList`/`elementOwner`는 그 순간 어긋나므로, **quad가 관리 중인 값을
안전하게 지우는 유일한 경로**가 이것이고 "지금 지우면 안 되는 상태"를
잡아주는 게 존재 이유. 이걸로 "`Set` 전에 직접 `Destroy()`"가 UB에서
명확한 에러로 바뀜.

**미확정**: 시그니처(`dispose(any)`가 맞는지, 타입을 어떻게 좁힐지),
대상 범위(Slot 외에 Instance/Observer/Effect까지 커버하는지),
`unbindLifetime`과의 역할 분담.

### 0-C. 포탈 — `Extract` 비파괴 경로로 해결되는가 (2026-08-13 여섯 번째 세션 신설, 사용자 제안 — **해결됨**)

**질문(사용자)**: `stateSlot:Get()`으로 Slot을 뽑아두고 → `Set()`으로 다른
Slot을 넣고 → 뽑아둔 Slot을 다른 곳에 넣는 게 되는가. 되면 "포탈"이
이걸로 해결됨.

**조사 결과**: 지금은 **안 됨** — `:List`의 `reconcile`이 교체 시
`rawRemove`(제거 **+ 파괴**)를 부르므로 뽑아둔 레퍼런스가 이미 파괴된
Slot이 됨. 막는 게 소유권 규칙이 아니라 "제거 = 파괴"라는 reconcile의
선택 하나뿐이라는 게 핵심.

**그런데 나머지 부품은 이미 다 있음**: `Extract`/`ExtractAll`/`Splice`가
이미 비파괴로 확정돼 있고, `claimOwner`/`releaseOwner`가 소유권을 정확히
이양하며, `attachSlot`은 재마운트를 구조적으로 이미 지원함(자식이 파괴만
안 됐다면 새 물리 부모로 그대로 flush). 즉 **"포탈은 별도 메커니즘이
필요하다"는 기존 전제가 틀렸을 가능성이 큼.**

**[해결, 사용자 결정]** opt-in이 아니라 **기본 동작**으로 확정 —
`State<Slot>` 교체는 원래부터 `state<Frame>`와 같이 언마운트여야 했다는
판단이라, 포탈은 별도 기능이 아니라 그 결정의 귀결. 안 지운 Slot은
아무도 안 들고 있으면 GC되고, 지금 죽이려면 `dispose`(위 0-B).
**[해소, 사용자 지적] "해제 짝"이라는 새 API는 필요 없음** — 옛 owner에
대해 그냥 `setOffsetSource(ownerKey, position, None)` **다음에**
`setLength(ownerKey, position, 0)`을 부르면 됨(이미 확정된 "마운트 안 하는
위치는 `0`/`None` 등록" 관용구 그대로). 즉 **해제 = `None`/0으로 재등록**.
**순서가 중요** — `setLength`가 끝에서 `recompute`를 돌리므로 먼저 부르면
아직 남아있는 옛 `Source`(죽는 중인 서브트리의 것)에 헛된 `:Set()`이 날아감
(`base/slot-plan.md`의 ⚠️ 절). 이 줄이 한때 순서를 거꾸로 적어놔서 같은 날
리뷰에서 지적됨.
`state<state<Frame>>`류로 offset이 밀리는 문제는 `state<state<Tag>>`와
같은 범주로 **"그냥 확인된 것"으로 수용**(평탄화 도구가 처리, 케이스 드묾).
상세는 `base/slot-plan.md` "`State<Slot>` 교체는 파괴가 아니라 언마운트" 절.

**관련(같은 절, 위 결정으로 함께 해소)**: `State<Slot?>`를
`nil`↔`slotA`로 왕복시키는 코드가 두 번째 등장부터 깨진 서브트리를 내던
문제도 언마운트 전환으로 사라짐. 대신 **`Set`으로 덮어쓰기 *전에*
이전 값을 직접 `Destroy()`하는 건 UB**(`state<Frame>`에서 먼저
`frame:Destroy()`하고 `Set`하는 것과 같은 문제) — 순서는 항상
`Set`(언마운트) → 그 다음 정리.

### 0-W. ~~같은 `Ref` 객체가 두 자리에 놓이는 걸 막을 것인가~~ **[해소됨, 2026-08-14 열한 번째 세션]** (2026-08-13 열세 번째 세션 신설, 0-Z 확인 중 발견)

**결정: 선택지 (a) — `Slot`/`PreRef`와 같이 즉시 error.** 메커니즘은
사용자 제안대로 새 전용 `Relate`를 만들지 않고 `bindLifetime`/
`unbindLifetime`을 재사용 — `bindLifetime`이 이미 내부에 "이 value가
다른 곳에 이미 살아있는 바인딩을 갖고 있으면 즉시 error"라는 가드를
갖고 있어서(`base/lifecycle-pattern.md`의 `canBound` 게이트),
`RefLeafHandler.process`가 실제 바인딩 분기에서 `bindLifetime(inst, v)`를,
실제 언바인딩 분기에서 `unbindLifetime(v)`를 부르기만 하면 이중 배치가
저절로 막힘. 상세 메커니즘/코드는 `base/ref-plan.md`의 "이중 배치 방지"
절.

**부수 결정 — `canBound`가 `canExecute`와 별도 진입점으로 재도입됨**
(2026-08-14 다섯 번째 세션에 "canBound 폐기, canExecute로 통합"됐던 걸
부분적으로 되짚음, 시그니처 정정 자체는 안 바뀜). 사용자 지적: "이중
바인딩 여부"(bound 문맥)와 "지금 발화해도 되는가"(execute 문맥)는 오늘
판정값이 같아도 서로 다른 질문 — `Ref`처럼 emit 전파에 참여하지 않는
값에 `canExecute`를 묻는 건 개념이 안 맞음. 판정 로직(`isBoundAlive`)은
공유하는 비공개 헬퍼 하나로 유지하고, `canBound`/`canExecute`는 그
헬퍼를 부르는 얇은 진입점으로 분리 — 중복 구현 없이 호출부 의미만
나뉨. `bindLifetime`/`Observer:Subscribe()`의 가드는 `canBound`로,
State emit 전파 루프만 `canExecute`로. 상세는
`base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절, 역전
경위는 `archive/canexecute-inst-arg-reversed.md`의 추가된 절 참고.

원 손 트레이싱/형제 프리미티브 대조표는 아래 보존(**[표기 정정, 2026-08-14
열한 번째 세션 후속]** 아래 `Frame1 { Ref = r }`/`process(inst1,"Ref",r)`의
`"Ref"`는 설명 편의상 쓴 표기일 뿐, 실제로는 `Ref`가 항상 children
배열 리터럴 아이템으로 놓여 `k`가 문자열 `"Ref"`가 아니라 그 자리의 배열
인덱스(숫자)임 — 정확한 표기는 `base/ref-plan.md` "이중 배치 방지" 절
참고, 트레이싱의 논리 자체는 `k`가 뭐든 안 바뀜):

**손 트레이싱** (`base/ref-plan.md`의 `RefLeafHandler` 의사코드에 대입,
`Frame1 { Ref = r }` / `Frame2 { Ref = r }`):

1. `process(inst1,"Ref",r)` → `relate[inst1]["Ref"]`가 nil → `r:Set(inst1)`
2. `process(inst2,"Ref",r)` → `relate[inst2]["Ref"]`도 nil(**다른 키**) →
   `r:Set(inst2)` — inst1 바인딩이 **조용히 유실, 에러 없음**
3. inst1 자리가 retract → 클로저 인자 `nil ~= v(r)` → **`r:Set(nil)`** —
   inst2가 정당하게 들고 있던 값을 지움(교차 오염)

**형제 프리미티브 대조 — 해소 전 `Ref`만 비어 있었음**:

| | 공유 자원 | 방어 | 상태 |
|---|---|---|---|
| `Slot` | element | `claimOwner`/`claimOwnerAt` → 즉시 error(`Slot{a,a}`/`Frame{slot,slot}`) | 막힘 |
| `PreRef`/`PostRef` | 자기 자신 | `_fired` → 재사용 시 error | 막힘 |
| `Tag` | 태그 이름 | 위치별 참조 카운트 — 겹침이 **의도된 동작**(합집합) | 설계상 정상 |
| `Attribute` | 이름 | 그룹 전용 키 + 이름 claim → 즉시 error | 막힘 |
| `Ref` | 자기 자신 | `bindLifetime`/`canBound` 재사용 → 즉시 error | **막힘(해소)** |

### 0. 추가 프리미티브 필요성 — 사용자 요청, 대부분 수렴(2026-08-06~07)

사용자 질문: "다른 독립 프리미티브나 종속 파생 데이터는 뭐가 더 필요할 것
같나요. 이것만으로 이 프로젝트는 충분하다 생각해요?" — 여러 서브에이전트
조사 + 사용자와 라이브 논의로 계속 수렴 중. **2026-08-07 문서 정리에서
확정/기각된 항목은 `research/additional-primitives-plan.md`에서
분리됨**: Blocker → `base/blocker-plan.md`, Effect → `base/effect-plan.md`, Batch →
`archive/batch-rejected.md`, Context(+레이어드 Store) → `archive/
context-rejected.md`. 아래는 그중 **아직 실제로 열려있는 것만** 남김.

- **[해소됨, 2026-08-09 세 번째 세션]** 키 기반 동적 컬렉션 재조정 —
  `Slot:List(data, updateFn, keyFn?) -> Slot` 콜론 메소드로 완전히 확정
  (자유 함수/새 타입 둘 다 기각, "Slot이 이미 가진 것 위에 새 공개
  메소드를 안 얹으니 별도 타입일 이유가 없다"는 게 근거). Slot의
  `Extract`/`Add(index)` CRUD와 같이 확정됨, 상세는 `base/slot-plan.md`
  "`Slot:List(...)`" 절.
- **[해소됨, 2026-08-07 여섯 번째 세션]** Effect/Observer 관계 — Effect는
  자유 함수로 확정(`state` 인자를 받으면 내부적으로 `state:Observer(...)`를
  조합해 재실행+자동 cleanup 배선, React `useEffect`와 동형). `state:Observer(fn)`도
  등록 즉시 1회 실행되는 것으로 확정. 상세는 `base/effect-plan.md`의
  "해결됨" 절과 `base/bind-system-plan.md`의 Observer 절.
- Untrack/Suspense/Error Boundary/Readonly는 조사 결과 새 프리미티브 없이
  기존 설계·Lua 자체 기능으로 이미 충분한 것으로 판단(`research/
  additional-primitives-plan.md` "빈 자리 아닌 것" 절).
- **[해소됨, 2026-08-11 세션]** `Slot:Single(state, updateFn)` — `:List`를
  0/1개짜리 배열로 감싸는 순수 sugar로 확정(`index` 없이 `offset`/
  `prev`/`userdata`만 전달, 고정 key로 `prev` 재사용 보장). `base/
  slot-plan.md`의 "`Slot:Single(...)`" 절. 같은 세션에 **Slot-in-Slot
  중첩도 확정**(요소 타입 제약에서 `Slot` 배제 해제, `Dispatch.setLength`/
  `setOffsetSource`를 Slot 자신을 owner 키로 재사용하는 재귀 `attachSlot`) —
  `base/slot-plan.md`의 "Slot-in-Slot 중첩" 절. **[해소됨, 2026-08-11
  일곱 번째 세션]** `Slot:Add`가 `State<T>`/`Source<T>`도 요소로 받음 —
  새 메커니즘 아니라 내부적으로 `Slot():Single(element)`(updateFn 생략
  시 identity)를 대신 삽입하는 순수 sugar로 확정(`updateFn`도 이때
  `Slot:Single(state, updateFn?)`로 선택 인자화). `base/slot-plan.md`의
  "반응형 raw 요소" 절.

### 1. 용어 정리 (사용자 요청, 진행 중)

사용자 원 메모: "quad는 register라던가 좀 부정확하거나 느낌이 바로 와닿지
않던 용어들이 많음 — 전체적 용어를 보고 생각해볼래? 제안을 줘, 나도 같이
볼게." 1차 제안 완료, 아래는 우선순위순 요약 — 최종 판단은 사용자와 계속
논의 필요:

- **[해소됨, 2026-08-12 세션, 같은 날 후속 세션에서 근거 보강]** `State` —
  사용자가 현재 이름 그대로 유지로 확정("그걸로 충분한듯"). 검토했던
  대안과 기각 근거:
  - `Computed`/`Derived`(Vue `computed()`, Svelte `$derived`) — 리네임
    안 함. 후속 논의로 근거가 하나 더 붙음: quad 코퍼스 안에서 `-ed` 어미는
    이미 `Tag.Added`/`Removed`, `Modifier.Overridden`이 "clone 후 즉시
    확정된 값"이라는 뜻으로 선점해둔 관례(`tag-plan.md` 참고)라, `State`
    노드가 실제로는 lazy(`fn`을 등록만 해두고 `:Get()`이 pull할 때
    계산됨)인데 `Computed`라는 이름을 쓰면 quad 자기 관례와 충돌해 "이미
    계산 끝난 값"으로 오해하기 쉬움 — Vue/Svelte 생태계에서는 lazy와
    `computed`라는 이름이 공존해도 문제없지만, quad 안에서는 다름. 같은
    이유로 `:Compute`(동사 원형) 메소드 이름도 `Computed`가 아니라
    `Compute`인 게 맞다고 재확인(`base/source-state-plan.md` "네이밍 —
    `Compute`가 `-ed`가 아닌 이유" 절).
  - `Pipe` — 검토했으나 기각. (1) "캐시한다"는 동작이 파이프라는 비유와
    안 맞음(파이프는 통과시키는 채널 이미지라 값을 들고 있다/캐시한다는
    느낌이 잘 안 붙음), (2) 파이프는 흐름/연결의 이미지라 State가 실제로는
    각각 주소를 가진 독립된 그래프 노드 단위라는 것과 안 맞음(단위를
    "노드"로 보기 애매해짐).
- **`DI`(Declarative Instance, 1순위)**: "Dependency Injection"의 업계
  표준 축약어와 완전히 겹침 — 4차 라운드에서 이미 한 번 실제로 오해가
  있었던 전례(`base/bind-system-plan.md`의 "인스턴스 생성" 절 참고).
  **파급 효과(2026-08-06 추가)**: `DI`가 리네임되면 `DI.FrameModifier`류
  Modifier 클래스별 타입 프리픽스도 같이 바뀌어야 함 — `DI` 리네임 논의
  때 이 연쇄까지 같이 고려할 것. **(2026-08-08 추가)** 사용자가 `D`(Declarative
  만 남김)로 축약하는 안을 제안 — 근거: (1) "Instance" 전용 개념이 아니라
  quad-* 전반의 declare 요소로 확장해도 되는 이름, (2) 엔진 종속 없이 다른
  백엔드에서도 재사용 가능, (3) 어차피 `D.FrameModifier`류 타입 프리픽스가
  길면 못 쓰므로 짧아야 한다는 실용적 제약. 아직 최종 확정 아님 — 다음
  세션에서 마저 논의(한 글자 식별자의 검색성/자기설명력 트레이드오프를
  문서에서 어떻게 보완할지도 같이).
- **[해소됨, 2026-08-08 세션]** `PerInstanceState` — 이름 문제 자체가 없어짐.
  `State`와 이름이 겹쳐 혼동 유발하던 그 유틸은 `Relate`로 대체·정식
  승격됨(`base/relate-plan.md`) — 이름도 이미 사용자 확정("Relate 괜찮아요"),
  `State`와 안 겹침.
- **`Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **`canExecute`(3순위, 사소함)**: 실제로 "이 핸들이 아직 살아있나" 확인인데
  이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적이라는 제안이
  있었으나, **(2026-08-08 재검토)** `isAlive`는 top-level `isX` 계열
  (`isState`/`isRef`/`isPreRef`/`isModifier`/`isObserver`류 — 전부 타입
  판별자)과 접두어가 겹쳐 "이것도 타입 체크인가" 오해를 유발할 수 있다는
  점이 지적됨. `canExecute`는 타입이 아니라 liveness(생존 여부)를 묻는
  질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽이 낫다는 방향으로 사용자가
  기욺 — 여전히 미확정, 다음에 `can`으로 시작하는 구체 대안(예: `canRun`)을
  같이 검토할 것.
- **[해소됨, 2026-08-09 세 번째 세션]** 키 기반 동적 컬렉션 재조정 이름 —
  `List`로 확정(`Slot:List(...)` 메소드, `Render`/`Draw`는 기각). 상세는
  `base/slot-plan.md` "`Slot:List(...)`" 절.
- **[해소됨, 2026-08-09 세션]** `Bound` — **`canBound(handle): boolean`
  탑레벨 함수로 확정**, `canExecute`와 같은 결(raw 필드를 직접 노출하는
  대신 predicate 함수로 감쌈). `base/source-state-plan.md` "이중 바인딩
  금지" 절 참고.
- **`Brand`(3순위, 사소함, 2026-08-07 여덟 번째 세션 추가)**: 런타임
  nominal 타입 판별 통합 메커니즘(`Brand.set`/`Brand.get`, `isState`를
  10종 branded 타입 전부로 일반화) — `brand-plan.md`의 `Brand`
  절에서 동작/구현 방식은 확정, "OOP 인스턴스의 클래스명을 얻는 느낌"을
  전달할 더 나은 이름이 있는지가 열린 질문(사용자가 직접 제기) — `Tag`는
  이미 quad-roblox의 `CollectionService` 래퍼로 쓰여서 이름 충돌, 후보로
  "type namespace"류를 사용자가 검토했으나 미확정. **(2026-08-08 재확인)**
  사용자가 다시 짚었지만 여전히 미정.
- **[해소됨, 2026-08-08 세션]** `Ref`/`PreRef`/`Peek`/`isState`(구
  `Override`는 이미 `Overridden`으로 별도 확정) — 전부 현재 이름 그대로
  유지로 확정. `Ref`는 "지연 없는 확정된 값 박스"라는 정의를 재확인(leaf
  노드를 담는 용도로도, leaf 노드에 바인딩하는 용도로도 쓰임 — 넓어진
  정의에도 여전히 맞음), `PreRef`는 더 나은 대안이 안 보여 그대로,
  `Peek`/`isState`는 이미 잘 맞는다고 재확인.
- **[해소됨, 2026-08-08 세션]** `None`/`NoneHandler` — `Undefined`/`Null`/
  `Nothing`도 검토했으나 기각(`Null`은 보통 "포인터가 비어있음"을 뜻해
  "값이 없음"이라는 의도와 안 맞는다는 게 이유), `None`/`NoneHandler`
  그대로 확정.
- **[해소됨, 2026-08-08 세션]** "프로바이더" → **`Handler`로 확정** —
  `base/module-lifecycle-plan.md`가 이미 [해소됨]으로 표시해뒀던 걸
  이 목록에 반영 안 하고 있던 stale 항목. `Processor`는 계약 메소드 이름
  자체가 `process`라 "그 안에 또 process가 있어" 눈에 걸리고, `Provider`는
  `canProvide`처럼 "뭔가를 공급한다"는 늬앙스라 실제로는 값을 처리/반응하는
  Handler의 동작과 안 맞으며 React `Context.Provider`류 맥락 패턴과도 헷갈릴
  수 있고, `Plug`는 "꽂힌다"는 늬앙스는 맞지만 "값을 처리한다"는 의미가
  없어 기각 — `Handler`가 계약(`isHandlable`/`process`/`retract`) 전체를
  가장 정확히 담는다는 사용자 재확인. 근거를 `base/module-lifecycle-plan.md`
  "프로바이더" 절에 보강 완료.
- **이미 지나간 사례로 참고**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`Ref`/`PreRef`/`Peek`/`isState`/`Handler`/
  `None`/`NoneHandler`/`process`/`retract`/`isHandlable`은 업계 선례와
  잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.
- **`Tag`/`Added`/`Removed`/`Merged`(3순위, 사소함, 2026-08-08 세 번째
  세션 array-part 값 객체 재설계 때 확정된 API 표면)**: `base/tag-plan.md`가
  "열린 질문 없음, 값 모양/메커니즘/retract/패키지 배치 전부 확정, 이름
  자체만 용어 정리 대상"이라고 명시해뒀으나 이 목록에 반영이 안 돼 있던
  누락 — 이번에 추가. `Tag`는 Roblox `CollectionService`가 쓰는 용어와
  1:1 대응이라 그 자체로는 무난해 보이지만, 위 `Brand` 항목(97-99행)에서
  "`Tag`가 이미 이 뜻으로 쓰이고 있어서 충돌"이라는 이유로 `Brand`의
  대안 이름 후보에서 제외됐다는 점은 참고할 것 — 두 이름이 같은 코퍼스
  안에서 공존 가능한지도 같이 검토 대상.
- **`Attribute`/`AttributeKey`(3순위, 사소함, 2026-08-11 아홉 번째 세션
  추가)**: 여러 Store를 한 번에 attribute로 묶는 그룹 프리미티브
  (`Attribute(store1, store2, ...)`, `Tag`와 동형)가 신설되면서, 기존
  단일 키 생성자 `Attribute<<T>>("name")`를 이름 충돌 방지를 위해
  `AttributeKey<<T>>`로 잠정 리네임함(`OnChange`/`OnChangeKey`처럼 함수
  이름과 반환 타입 이름이 분리된 기존 전례와 대칭) — 해석 모호성 자체는
  이미 없앴으니 급하지 않지만, 최종 이름은 여전히 이 목록의 다른
  가칭들과 함께 검토 대상. `base/attribute-plan.md` "그룹 `Attribute(...)`"
  절 참고.

### 2. 구현 착수 직전 감사 결과 (2026-08-06 신설, M0 착수 전 확인 권장)

`research/pre-implementation-audit.md` — `base/` 전체를 M0 착수 직전
시점에서 모호성/지연결정리스크/단순화후보 세 렌즈로 재감사한 결과. 총
11개 우선순위1(구현 중 바로 부딪힐 가능성 높음) + 11개 우선순위2(지금
정해두면 싼 지연리스크) + 2개 단순화후보. 전체는 그 문서 참고, 특히
사용자 판단이 필요한 것 위주로 요약:

- **[해소됨, 2026-08-10 세션]** Tween.luau가 "범용 store-bind 캐치올
  핸들러"의 유일한 예시로 서술됨 — Tween을 독립 Dispatch 핸들러에서
  값-레벨 래퍼(`Tween<T>`, PropertyHandler가 소비)로 재설계해 해소.
  범용 State/Source 언랩은 `Dispatch/StoreBind.luau` 하나뿐, Tween 여부
  판단은 완전히 별개(`research/tween-plan.md` 전면 재작성, 우선순위1-1
  해소).
- **[해소됨, 2026-08-09 세션]** `State<Modifier>`와 Ref/Slot이 Modifier
  필드에 들어가는 것 — 이제 둘 다 `isX` predicate 기반 명시적 `error`로
  통일(`base/modifier-plan.md` 4번/7번 절, `base/source-state-plan.md`
  "따름정리" 절). Luau 타입 차단은 "되면 좋은 보너스"로 격하되어 더
  이상 필수 검증 항목 아님 — 문서모순 절 + 우선순위2-2도 갱신 완료.
- ~~`props.Modifier`/`props.Ref` forwarding 관례가 Lua 배열 리터럴
  nil-hole 함정에 그대로 노출됨~~ — **반영 완료(2026-08-07 열 번째
  세션)**. `props.Modifier or None`/`props.Ref or None` 관용구를 필수로
  확정(`base/component-composition-plan.md` "필수 관용구" 절) — M0에선
  이 관용구 자체가 타입/런타임 양쪽에서 문제없이 동작하는지만 검증.
- **~~`canExecute`/`Connected`의 실제 구현 방식이 미확정~~ — 반영 완료
  (2026-08-08 세션)** — 우선순위1-6 해소. `bindLifetime(inst,value)`/
  `canExecute(inst,value)` 탑레벨 함수로 확정(네임스페이스 안 씀,
  `LifetimeHandle.luau`는 이 둘의 인터페이스만 갖고 quad-roblox가 구현
  주입), 시그니처는 `(handle)`이 아니라 `(inst, value)` 2-인자로 재정정
  (Observer 자신의 `Subscribed` 상태를 먼저 보고, 그 다음 `inst`의 공유
  gcconn을 봄 — 두 조건이 독립적이라 하나로 못 뭉침). gchold 저장소는
  새 프리미티브 `Relate`(`base/relate-plan.md`) 위에 구현 — `base/
  lifecycle-pattern.md`의 "`bindLifetime`/`canExecute` — 확정" 절 참고.
- **~~`LifetimeHandle` 인터페이스가 M8에 배치돼 있지만 M4/M6이 이미 그걸
  필요로 함(로드맵 순서 역전)~~ — 반영 완료(2026-08-07 세 번째 세션)**:
  `LifetimeHandle`/`Relate` 인터페이스(타입만)를 `ROADMAP.md`
  M2로 옮기고, quad-roblox 실 구현만 M8에 남김 — 우선순위1-9 해소.
- **[해소됨]** retract 시 "이전 핸들러" 추적 책임 소재 — Dispatch 체인
  (`chains`)+`Dispatch.retractFrom`(2026-08-08 세 번째 세션엔 `retractUnder`라는
  이름이었음, 2026-08-13 다섯 번째 세션에 인덱스 기반으로 재설계되며 개명)로 이미
  해소(`pre-implementation-audit.md` 1-2, `bind-system-plan.md` "Dispatch
  체인" 절). **[해소됨, 2026-08-09 세션]** `:Compute`의 `previous` 인자
  오버엔지니어링 의심도 기각(`source-state-plan.md` "previous" 절,
  `pre-implementation-audit.md` 3-1). **[해소됨]** UI shorthand의 기존
  UICorner 매칭 기준도 `base/ui-shorthand-plan.md`에 이미 확정 반영돼
  있던 것을 이번에 `pre-implementation-audit.md` 2-11에도 해소 표시로
  동기화. **[해소됨, 2026-08-09 세 번째 세션]** Slot CRUD 의미론
  (`add`/`remove`/`clear`) 미정의(1-7)/`isMounted` 이중 추적 혼용(1-8) —
  `base/slot-plan.md` 참고. **[해소됨, 2026-08-12 열일곱 번째 세션]**
  나머지 넷도 전부 확정 — 우선순위 스캔 동률/매치실패 처리(1-3, tiebreak
  강제 없이 `HANDLER_PRIORITY_*` 상수+디버그 print/목록 함수, 매치실패는
  즉시 error), provider 미주입 상태 dispatch 처리(1-4, 매치실패 규칙에
  자연 흡수), `store.key`의 레코드 필드 타이핑(1-10, Luau `type function`으로
  가능함 확인), Modifier `__index`+`table.clone` 트릭 검증(1-11, 메타테이블
  참조 공유 방식 확인) — 상세는 `pre-implementation-audit.md` 해당 항목,
  `base/bind-system-plan.md`/`base/modifier-plan.md` 참고. **우선순위1
  11개 전부 해소됨.** **[2026-08-13 갱신]** 그 다음 게이트였던
  `.claude/luau-test/` 스파이크는 **여섯 번째 세션에 첫 실측이 돌아
  런타임 12개 전원 통과**했고(`audit/luau-test-first-run-2026-08-13.md`,
  상태판은 `luau-test/STATUS.md`), 남은 건 Studio 전용 `10`과 코드가
  깨져 재작성이 필요한 `13`/`15`/`16`뿐. **대신 그 실측이 위 0-Y를 새로
  열었으므로 M0 착수 전 게이트는 이제 0-Y/0-Z** — "실측 확인만 남았다"는
  옛 서술이니 주의.
- **[해소됨, 2026-08-08 두 번째 세션]** `Frame { ref }`/`Frame { observer }`처럼
  children 배열 숫자 슬롯에 직접 놓는 leaf 값을 매칭·바인드하는 Handler
  (`(i:number, v=Ref/Observer/PreRef)`)의 패키지 배치 — 원래 제안대로
  `quad-base`, `Dispatch/Leaf.luau`(이미 있던 `Dispatch/StoreBind.luau`와
  같은 층위)로 확정. Dispatch 자체가 프리미티브가 아니라 탑레벨 싱글톤이고
  base 기본 핸들러와 quad-roblox 백엔드 핸들러가 같은 `Dispatch.addHandler`
  레지스트리를 공유한다는 결론과 함께 나온 것 — `base/bind-system-plan.md`
  "Dispatch는 프리미티브가 아니다" 절, `base/architecture.md` 소스트리 참고.

### 3. 낮은 우선순위

- **`Operator` 콤비네이터 슈가 네임스페이스 이름+포함 범위(2026-08-12 신설,
  같은 날 후속으로 외부 리서치 완료)** — `Sum`/`Product`/`Not`/비트연산 등
  `:Compute`/`:Apply`용 슈가 함수 모음의 이름. 흔한 단어라 top-level
  노출은 위험, 후보는 `Operator`/`Op`/`Ops`(`Combinator`는 코퍼스 전반에서
  이미 일반명사로 쓰여서 제외) — **서브 에이전트 외부 리서치 결과 `Operator`가
  가장 선례가 강함**(Python `operator` 모듈)이나 최종 확정은 여전히 사용자
  몫. 같은 리서치에서 포함 범위도 새로 갈렸음 — 비트/비교 연산자 그룹과
  `Sub`/`Div`는 리액티브 콤비네이터로서 선례가 전혀 없어 드랍 후보로,
  `Clamp`/`Min`/`Max`는 선례가 강해 추가 후보로, Debounce/Throttle은
  업계에 흔하지만 `Blocker`와는 다른 시간 기반 메커니즘이라 이 카탈로그가
  아니라 quad-roblox 쪽 별도 프리미티브로 다룰지 판단이 필요한 별개 질문으로
  분리됨. **[2026-08-13 세션 신설]** `Alternative`(nil 대체값, coalesce/`??`/
  엘비스 연산자류) 후보 추가 — Haskell 비교 리서치 중 나옴, 카탈로그 확정
  규칙에 그대로 맞아 포함 근거는 있음. 상세는 `research/operator-sugar-plan.md`.
  구현 자체는 맨 마지막 우선순위(순수 슈가, 없어도 무방) — 여전함.
- **[해소됨(기각), 2026-08-14 세션]** 이미 생성된 인스턴스 재바인드 —
  "스코프 논의만 필요"로 오래 열려 있었으나 사용자 확정으로 **기각**,
  `archive/existing-instance-bind-rejected.md`로 이전(사유: Length/Offset
  등 quad가 만든 트리를 전제한 부기를 바깥에서 밀고 당기는 버그 표면이
  치명적으로 넓어짐).
- **[해소됨, 2026-08-13 세 번째 세션]** v1 `objectListClass.__newIndex` 오타
  기능(재현 테스트 필요했던 항목) — 사용자가 당시 실수였음을 확인. v2는 이제
  오브젝트에 id를 주입하고 id로 조회하는 개념(`GetObjects`류) 자체가 없어져
  이 기능이 실제로 동작했든 안 했든 v2 마이그레이션 가이드에서 논의할 대상이
  아님(있었다 해도 v1 전용 기능) — 더 이상 확인/논의 불필요.
- **[해소됨, 2026-08-09 여섯 번째 세션]** 여러 Slot이 형제로 섞일 때
  순서 보장 — `Dispatch.setLength`/`Dispatch.setOffsetSource` + 형제별
  개수 누적합을 `LayoutOrder`에 리액티브 바인딩하는 메커니즘으로 확정,
  DOM류 물리 순서 백엔드에도 같은 base 로직이 재사용됨(backend Handler의
  "offset 변경 시 할 일"만 no-op으로 갈림). 상세는 `base/
  bind-system-plan.md` "Length/Offset" 절, `base/slot-plan.md` "여러
  Slot이 섞일 때 순서 보장" 절. **같은 구현 시점에 같이 확인할 것
  (2026-08-06 추가, 아직 안 풀림)**: Slot이 quad 밖(v1 compat 등)에서
  만들어진 임의 Instance를 동적 배열 원소로 받을 수 있는지, retract 시
  foreign Instance를 어떻게 다루는지 — `research/v1-compat-plan.md` 7-3
  참고.
- **`quad-debug` 세부 API 이름** — `research/debug-tooling-plan.md` 참고.
  채널 실현 가능성(BindableEvent/Function이 플러그인↔Play 중 게임 경계를
  넘는지)까지 사용자가 Studio에서 직접 실측 검증 완료 — 기술적 불확실성은
  다 해소됨, 남은 건 세부 API 이름뿐("이벤트 함수가 self로 instance를
  읽는 게 quad 관습"이라는 언급은 2026-08-06 후속 세션에서 해소 —
  채택 안 함으로 확정, `base/bind-system-plan.md` "이벤트 핸들러는
  self(Instance)를 받지 않는다" 절 참고). 사용자가 "quad 개발 완료 전엔
  착수 못 함"으로 직접 후순위 지정한 건 여전함 — base 설계(M2 Dispatch/
  M3 Source/M5 DI 생성자) 시점에 훅 확장 지점만 고려해두면 됨.
- **문서화 전략(UI 네이밍 컨벤션, Store 부작용을 게임 시스템에서 쓰는
  패턴)** — `research/documentation-plan.md`(뼈대만). 정식 백로그 항목으로
  올릴지, 착수 시점을 언제로 볼지 사용자 판단 필요.
- **[해소됨, 2026-08-09 열한 번째 세션]** Attribute 특수 키 타입
  파라미터화 — `[AttributeKey<<boolean>> "name"]`(구 `Attribute<<boolean>>`,
  2026-08-11 아홉 번째 세션에 그룹 `Attribute(...)`와의 이름 충돌 방지로
  리네임) 제네릭 스타일과 `[BooleanAttribute "name"]` 타입별 정적 생성자
  패밀리 **둘 다 채택으로 확정**(내부 구현 동일, 호출부 표기만 다름).
  `base/attribute-plan.md` 참고 — 제네릭 파라미터가 `=` 뒤 값 타입까지
  좁혀주는지는 M0/M10에서 실측 필요(안 돼도 런타임엔 영향 없음).
- **v1 하위호환(compat) 레이어 — `quad-roblox-v1-compat`** —
  `research/v1-compat-plan.md`(신규, 2026-08-06, 두 차례 후속 논의로 수렴).
  방향 확정: v1을 그대로 병행 실행 + 경계에서만 `state:Observer()`(lazy
  포기)로 값을 리졸브해 v1 프로퍼티에 재대입하는 브리지, v2→v1 단방향만
  (양방향 불필요로 확정), 패키지명 `quad-roblox-v1-compat`으로 확정(소스
  트리에 세 번째 패키지로 추가될 예정). v2-in-v1/v1-in-v2 두 임베딩 방향
  모두 기술적 근거와 안전 규칙까지 정리됐으나(문서 7번), **Slot이 foreign
  Instance를 어떻게 다루는지만 Slot 코어 구현 시점까지 결정 불가로 남음**
  (위 "여러 Slot이 형제로 섞일 때 순서 보장" 항목과 같은 시점에 확인).
  그 외 §8의 세부 항목(v1 자기 루트의 `Destroying` 자기청소 여부,
  `registerClass` 체이닝 기능 브릿징 필요성)은 문서 자체가 "지금 결정
  불필요"로 표시해둠 — 위 Slot 항목과 별도로, 실제 compat 레이어 구현
  시점에 `research/v1-compat-plan.md` §8을 다시 열어 확인.
- **[해소됨, 2026-08-12 열여덟 번째 세션]** `framework-comparison-findings.md`의
  두 남은 개선 후보 — 둘 다 "고칠 필요 없음, 의도된 설계"로 사용자가 최종
  판단해 문서 3번 절(못 고치는 트레이드오프)로 이전. use-after-destroy 검증
  안전망은 `bindLifetime`/`Effect`로 이미 커버되는 영역에 별도 장치를 얹는
  게 오히려 GC-native 아키텍처(수동 Destroy 강제 없이 GC가 치우게 두는 것)와
  모순되어 완전한 UB로 남기고 문서화로만 대응. `:With`의 동적 의존성도
  State immutable 가정과 정면 모순(실사용 사례도 거의 없음, React
  `useMemo` deps도 대부분 정적) — 의도적 비지원으로 확정. 상세는
  `research/framework-comparison-findings.md` 3번 절.

- **[해소됨, 2026-08-14 열 번째 세션]** 0-B. `dispose(any)` — 시그니처/범위.
  **결론**: 범위를 `Slot`+엔진 객체(Instance)로만 좁히고 **Observer/Effect는
  명시적으로 제외** — 시그니처는 `dispose(value: Slot | Instance)`,
  내부적으로 `if isSlot(value) then <Slot 자체 소유권 판정 재사용> else
  disposeInst(value) end`로 분기. `unbindLifetime`과의 역할 분담도 이걸로
  해소: `dispose`는 **트리 소유권 부기(elementOwner/lengthList 등)가 있는
  대상**이 아직 요구되는데 강제로 죽이려는 경우를 막는 게 목적이고,
  `unbindLifetime`은 Observer/Effect류의 GC 앵커(gcconn)를 조기 해제하는
  것 — 서로 다른 축이라 대체 불가.
  - **Observer/Effect가 빠지는 이유**: 이 둘은 children 배열 leaf 위치에서
    `Dispatch/Leaf.luau`가 매치해 내부적으로 `bindLifetime`/`canExecute`/
    `unbindLifetime`(GC-native, gcconn 기반)로만 관리됨(`base/
    source-state-plan.md` "이중 바인딩 금지" 절) — Slot의 `elementOwner`/
    `lengthList`/`sourceList` 같은 "죽으면 offset/length가 깨지는" 트리
    부기 자체가 없어서, 도중에 GC되거나 `unbindLifetime`으로 조기 해제돼도
    구조적으로 안전함. 즉 dispose가 막아야 하는 문제(트리 부기 붕괴)가
    Observer/Effect에는 원천적으로 발생하지 않음. `State<Observer>`/
    `State<Slot>` 등 반응형 leaf 값은 이미 확정된 일반 원칙("모든
    `(inst,k)`는 `T`든 `State<T>`든 `StoreBind`가 균일하게 재귀 처리")의
    자연스러운 귀결일 뿐 별도 설계가 필요 없었음 — Modifier 필드/Slot
    원소 금지 규칙(핸들러 계층 값 즉시 error)은 **다른 컨텍스트**(Modifier
    필드, `Slot:Add`/`:List`의 원소)라 여기 적용 안 됨, 혼동하지 말 것.
  - **base/backend 분리**: `dispose`가 `isSlot`이 아닐 때 위임하는
    `disposeInst(inst: any): ()`는 `addTag`/`removeTag`/`setAttribute`와
    같은 "base가 소유하는 핸들러와 주입되는 엔진 op" 패턴(`base/
    dispatch-core-plan.md`) — quad-roblox는 `inst:Destroy()`로 구현.
  - **네이밍**: `free()`는 GC 언어 맥락과 안 맞아 기각, `Destroy`는 엔진
    `:Destroy()` 메소드와 동명이라 사용자가 착각할 위험이 있어 기각 —
    `dispose` 유지.
  - 정본은 `base/slot-plan.md` "`dispose(any)`" 절 +
    `base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op"
    절. 이 해소로 `base/lifecycle-hooks-plan.md`의 `OnDestroyed` 이름
    재검토 조건("0-B가 'quad가 만드는 모든 것의 유일한 파괴 경로'로
    풀리면")도 **발동하지 않는 쪽으로 영구 종결** — `OnDestroyed`가
    최종 이름.

## 참고: 지금까지 확정된 것 (요약)

전부 `base/`에 문서화되어 더 이상 열려있지 않음 — 상세 근거/논의 과정이
필요하면 아래 문서를 열어볼 것(라운드별 세부 히스토리는 각 문서 안에
"2026-08-04 O차 라운드" 식으로 표시돼 있음):

| 주제 | 문서 |
|---|---|
| 전체 아키텍처 결정(디스패치 모델, DOMless, 태그/Ref, Signal 미채택 등) | `base/architecture.md` |
| Store/State/Source 온톨로지, 인스턴스 생성/이벤트 인체공학, Ref, 남은 API 이름 | `base/bind-system-plan.md` |
| Store 부작용 허용, `:With`+`:Compute`, dot-access 문법 | `base/store-plan.md` |
| 프로바이더 패턴, bind/store 구현 책임 분리 | `base/module-lifecycle-plan.md` |
| Slot 재조정, 재마운트 시 throw, **[2026-08-13 6번째 세션 역전] retract=언마운트**(파괴 아님, portal이 그 귀결 — 옛 "retract=폐기"는 뒤집힘) | `base/slot-plan.md` |
| `Connected`+GC 라이프사이클 패턴 | `base/lifecycle-pattern.md` |
| Modifier(정적 merge, immutable 체이닝, State 필드 지원, `Apply`/`Overridden`/`Peek`/`isState`) | `base/modifier-plan.md` |
| 컴포넌트화(플레인 함수, State/Source 경계, 컴포넌트 경계 modifier/Ref는 named parameter로 전달, multi-root 개념 폐기, `Modifier.Overridden`) | `base/component-composition-plan.md` |
| 컴포넌트 이식성(전역 store 참조 시 재사용성 문제) | `base/purity-and-effects-plan.md` |
| Blocker(값 기반 emit 지연/합치기) | `base/blocker-plan.md` |
| Effect(설치+확정 정리, `state` 있으면 Observer 조합해 재실행도 지원 — 확정) | `base/effect-plan.md` |
| `Relate`(inst-weak 릴레이션 프리미티브, `SetWeak`/`GetWeak`/`SetStrong`/`GetStrong`), `bindLifetime`/`canExecute`(inst,value) 탑레벨 함수 | `base/relate-plan.md`, `base/lifecycle-pattern.md` |
| **[2026-08-13 3차 감사에서 정정]** retract 생략 불가(no-op 허용, 누락 시 핸들러 교체 순간 크래시) — 2026-08-13 다섯 번째 세션부터 별도 `retract` 필드가 아니라 `process`가 반환하는 클로저, 자리만 옮겨왔을 뿐 원칙은 동일. store-bind 재실행은 `state:Observer(fn):Subscribe()` 재사용 | `base/bind-system-plan.md` |
| UICorner/UIPadding/UIScale 인라인 편의 키 — 이름·메커니즘·store-bind 가능성까지 확정 | `base/ui-shorthand-plan.md` |
| Batch(lexical) 기각, Context(+레이어드 Store) 기각 | `archive/batch-rejected.md`, `archive/context-rejected.md` |
| Fusion/Vide 비교 리서치(주의: 일부 서술은 이후 라운드에서 뒤집힘, 문서 내 정정 표시 참고) | `reference/comparison-fusion-vide.md` |
| v1 내부 동작 스냅샷 | `reference/quad-v1-architecture.md` |
| 트윈 — 값-레벨 `Tween<T>` 래퍼(2026-08-10)+옵션 값 모양·override 정책·`Animate` 콤비네이터·자연완료 북키핑(2026-08-12) 전부 확정, `base/`로 승격 | `base/tween-plan.md` |
| quad2-try(폐기된 이전 시도) 리서치 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` COW 전부 죽은 접근으로 확인, 반복 조사 금지 | `base/bind-system-plan.md` |
| `Fallback`/`Traceback`(2026-08-14) — 컴포넌트 에러 격리 유틸, `pcall`(가벼움)과 `xpcall`+`debug.traceback`(trace 항상 있음)으로 분리, `err: any` 확정(테이블 에러 등), 패키지·이름 전부 확정, `research/`에서 승격 | `base/fallback-plan.md` |

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스 — 위 표는 힌트일 뿐 그쪽이
바뀌면 이 문서도 갱신할 것.



## 인용 출처 없는 원칙 — "드문 오용/가상 미래 요구까지 방어/최적화하려고 구조를 복잡하게 만들지 않는다" (2026-08-16 신설 → 같은 날 해소)

**결론: 선택지 (a) 채택 — `.claude/conventions.md`의 "설계 원칙" 절에 정식
명문화.** `base/modifier-plan.md`의 인용은 그쪽을 가리키도록 바꿨고, 대기
배너는 제거됨.

**경위**: `modifier-plan.md`의 "미검토로 남긴 것" 문단이 이 원칙을
`CLAUDE.md`의 것으로 인용해왔으나, 코퍼스 전체 grep과 `git log -S`
(CLAUDE.md 전 히스토리) 어디에도 그런 서술이 없었음 — 존재한 적 없는
출처였다. 같이 발견된 다른 두 건은 인용 대상만 틀린 것이라 실제 소스로
재조준 완료(`research/v1-compat-plan.md`→`base/component-composition-plan.md`+
`base/store-plan.md`, `research/pre-implementation-audit.md`→`ROADMAP.md`).

**사용자 논거**: "(a) 하면 될 것 같아. 그리고 추측하건데, 내가 세션 중
했던 말을 옮겨적지 않은 경우로 보이기도 함." — 즉 원칙 자체는 실제로
사용자가 구두로 세운 것인데 문서화가 누락됐다는 판단. 이 추정에서
**"사용자 발언을 인용할 때는 논거까지 남긴다"는 새 관례**가 같이 나왔음
(`conventions.md` "작업 방식" 절).


## `const` 바인딩 미채택 판단의 재검토 트리거 (2026-08-16 신설 → 같은 날 해소)

**결론: 에이전트가 정할 문제가 아님 — 사용자가 확인된 정보로 제공하고,
추적은 `HUMAN_TODO.md` 8번이 소스.**

감사가 `base/architecture.md`의 `const` 미채택 사유에 날짜가 없다고 지적해
"(a) 날짜만 / (b) 구체적 트리거 명시" 중 고르는 질문으로 올렸으나, 사용자가
**전제 자체를 정정**했다.

**사용자 논거 원문**: "const 건은 생각보다 더 컴플랙스함. 예를 들어 pesde 의
타입추출화 해서 d.ts 같이 types emit 하는 류가 있음. 아직 툴링이 미성숙한
상태라 const 를 제공 못하는 상황이고, 언제 다시 사용가능해지는지 명확치가
않음. 따라서 이는 사용자가 확인된 정보로 제공하는게 맞다고 보고 있음."

즉 (b)의 "구체적 트리거"를 에이전트가 적어둘 수 없는 종류의 문제다 —
툴링 체인(pesde types emit 등)의 지원 시점은 외부 사정이고 관측 수단이
에이전트에 없다. 그래서 질문을 닫고 `HUMAN_TODO.md` 8번(사용자가 시점을
파악하거나, 가능해질 때 에이전트에 알림)으로 옮겼다.
