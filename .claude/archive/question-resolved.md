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
읽어 산술 에러를 내던 크래시(`archive/v2-initial-implementation/pre-implementation-qa-round2.md`의
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
  `archive/v2-initial-implementation/pre-implementation-qa-round2.md`의 "RC-1" 절.

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
  `archive/v2-initial-implementation/pre-implementation-qa-round3.md`.

## [해소됨, 2026-08-19] `PopOnly` → `Detach` 리네임 + 공개 표면 위치 확정

`:List` reconcile의 "파괴하지 말고 자리만 비우라" 반환 센티널은 2026-08-18
가칭 `PopOnly`로 도입되며 사용자가 "이름은 변경될 수 있음, 더 생각해봐야함"
이라 남긴 채 `question.md` 용어 정리 항목에 열려 있었음. 사용자가 후속
세션에서 이름 아이디어를 요청 → 여러 후보(`Bench`/`Stash`/`Hold`/`Detach`
등)를 검토한 뒤 `Detach`로 좁혔고, 이어서 "이걸 어디에 던져줘야 하나"(공개
표면 위치)까지 같이 확정됨. 원문은
`session/2026-08-19-02-detach-naming-and-placement.md`.

- **이름 — `Detach`.** 근거 둘: (1) 이미 있는 `Extract`(호출자가 직접
  부르는 명령형 추출)와 동사가 겹치면 헷갈리는데, `Detach`는 "화면(부모
  계층)에서만 떼어낼 뿐 관리 주체는 여전히 reconcile"이라는 뜻이라
  `Extract`의 "소유권을 통째로 호출자에게 넘긴다"와 자연스럽게 구분됨.
  (2) `nil`(파괴)과의 대비도 더 직접적으로 드러남.
- **공개 표면 위치 — 패키지 최상위 export.** `Slot`이 함수(팩토리)라
  `Slot.Detach`처럼 붙이려면 callable-table+메타테이블이 새로 필요한데,
  sentinel 상수 하나 때문에 그 구조를 들이는 건 "실제로 관측된 문제에만
  구조를 쓴다" 원칙에 안 맞음(사용자 지적). 대신 `None`이 이미 쓰는 패턴을
  그대로 따름 — `None`도 여러 곳(Slot 요소, Attribute, offsetSource)에서
  쓰이지만 공개 표면은 패키지 최상위(`quad-base/src/init.luau` 재노출)이고
  실제 정의는 관련 로직 옆(`Dispatch/None.luau`)에 있음. `Detach`도 같은
  패턴 — 정의는 Slot 관련 파일 옆에 두고 `init.luau`에서 최상위로 재노출.
- 지금 유효한 설계는 `base/slot-plan.md`의 "`nil` 리턴은 파괴가 기본" 절이
  소스.

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
> `archive/surveys/2026-08-06-framework-comparison-findings.md`, `ROADMAP.md` M0 체크리스트,
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
확정/기각된 항목은 `archive/surveys/2026-08-06-additional-primitives-plan.md`에서
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
  archive/surveys/2026-08-06-additional-primitives-plan.md` "빈 자리 아닌 것" 절).
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

`archive/surveys/2026-08-06-pre-implementation-audit.md` — `base/` 전체를 M0 착수 직전
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
  해소(`archive/surveys/2026-08-06-pre-implementation-audit.md` 1-2, `bind-system-plan.md` "Dispatch
  체인" 절). **[해소됨, 2026-08-09 세션]** `:Compute`의 `previous` 인자
  오버엔지니어링 의심도 기각(`source-state-plan.md` "previous" 절,
  `archive/surveys/2026-08-06-pre-implementation-audit.md` 3-1). **[해소됨]** UI shorthand의 기존
  UICorner 매칭 기준도 `base/ui-shorthand-plan.md`에 이미 확정 반영돼
  있던 것을 이번에 `archive/surveys/2026-08-06-pre-implementation-audit.md` 2-11에도 해소 표시로
  동기화. **[해소됨, 2026-08-09 세 번째 세션]** Slot CRUD 의미론
  (`add`/`remove`/`clear`) 미정의(1-7)/`isMounted` 이중 추적 혼용(1-8) —
  `base/slot-plan.md` 참고. **[해소됨, 2026-08-12 열일곱 번째 세션]**
  나머지 넷도 전부 확정 — 우선순위 스캔 동률/매치실패 처리(1-3, tiebreak
  강제 없이 `HANDLER_PRIORITY_*` 상수+디버그 print/목록 함수, 매치실패는
  즉시 error), provider 미주입 상태 dispatch 처리(1-4, 매치실패 규칙에
  자연 흡수), `store.key`의 레코드 필드 타이핑(1-10, Luau `type function`으로
  가능함 확인), Modifier `__index`+`table.clone` 트릭 검증(1-11, 메타테이블
  참조 공유 방식 확인) — 상세는 `archive/surveys/2026-08-06-pre-implementation-audit.md` 해당 항목,
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
  패턴)** — `archive/surveys/2026-08-06-documentation-plan.md`(뼈대만). 정식 백로그 항목으로
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
- **[해소됨, 2026-08-12 열여덟 번째 세션]** `archive/surveys/2026-08-06-framework-comparison-findings.md`의
  두 남은 개선 후보 — 둘 다 "고칠 필요 없음, 의도된 설계"로 사용자가 최종
  판단해 문서 3번 절(못 고치는 트레이드오프)로 이전. use-after-destroy 검증
  안전망은 `bindLifetime`/`Effect`로 이미 커버되는 영역에 별도 장치를 얹는
  게 오히려 GC-native 아키텍처(수동 Destroy 강제 없이 GC가 치우게 두는 것)와
  모순되어 완전한 UB로 남기고 문서화로만 대응. `:With`의 동적 의존성도
  State immutable 가정과 정면 모순(실사용 사례도 거의 없음, React
  `useMemo` deps도 대부분 정적) — 의도적 비지원으로 확정. 상세는
  `archive/surveys/2026-08-06-framework-comparison-findings.md` 3번 절.

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
`base/store-plan.md`, `archive/surveys/2026-08-06-pre-implementation-audit.md`→`ROADMAP.md`).

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


---

## [해소 배치 이관, 2026-08-21] `question.md`가 들고 있던 해소 항목 16건

**왜 옮겼나**: `question.md`는 스스로 *"항목을 해소하면 여기서 지우고
`archive/question-resolved.md`에 근거와 함께 옮길 것 — 다시 쌓이면 같은
문제가 반복됨"*이라고 규정해뒀는데, 2026-08-21 기준 파일의 절반이 다시
`[해소]` 마커로 차 있었다(2026-08-21 하루에만 여러 건이 닫힌 결과). 예고된
그대로 "필터해서 읽기 힘듦"이 재발한 것이라 이 규칙대로 일괄 이관한다.
**결정 내용은 하나도 안 바뀜 — 읽는 자리만 옮긴 것**이고, 지금 유효한
설계는 언제나 `base/`가 소스다.

**⚠️ 아래 항목 중 `Epoch`/`EpochMap` 관련 서술은 이관 시점 표현 그대로다** —
같은 날 `Epoch`/`EpochMap`/`Brand` 승격으로 **필드 이름이 바뀌었다**
(`sourceCountMap` → `valueEpochMap`, `sourceEmitMap` → `emitEpochMap`,
"소스"/"count" → "`Epoch`"/"리비전"). 결정 자체는 그대로이고 표현만
바뀌었으니, 현재형 규칙은 `base/state-epoch-plan.md`를 볼 것.

- **[해소됨, 2026-08-18] `DI` → `D`(Declarative) 확정** — 원문과 근거는
  `archive/question-resolved.md`. 요지: `DI`가 "Dependency Injection"과
  완전히 겹쳐 실제 오해 전례가 있었고, `D`는 Instance 전용이 아닌 declare
  요소 전반으로 확장 가능하며 `D.FrameModifier`류 타입 프리픽스도 짧게
  유지된다. 미뤄뒀던 유일한 사유(한 글자 식별자의 검색성/자기설명력)는
  "문서에서 처음 나올 때 항상 `D`(Declarative)로 풀어쓴다"는 표기 규약으로
  보완하기로 같이 확정. 코퍼스 반영 완료 —
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절.

- **[해소됨, 2026-08-19] `PopOnly` → `Detach` 확정** — 원문과 근거는
  `archive/question-resolved.md`. 요지: 이미 있는
  `Extract`(호출자가 직접 부르는 명령형 추출)와 동사가 겹치면 헷갈리는데,
  `Detach`는 "화면(부모 계층)에서만 떼어낼 뿐 관리 주체는 여전히
  reconcile"이라는 뜻이라 `Extract`의 "소유권을 통째로 넘긴다"와 자연스럽게
  구분되고, `nil`(파괴)과의 대비도 더 직접적으로 드러남. 공개 표면 위치도
  같이 확정 — `Slot`이 함수(팩토리)라 `Slot.Detach`처럼 붙이려면
  callable-table+메타테이블이 새로 필요해서 과함, `None`과 같은 선례를 따라
  **패키지 최상위 export**로. 코퍼스 반영 완료 — `base/slot-plan.md`의
  "`nil` 리턴은 파괴가 기본" 절.

- **[해소, 2026-08-21 구현 전 QA 5라운드 `CR-3`] M2가 M3의 `Blocker.luau`에
  구조적으로 의존하던 순서 문제 — "게이팅 먼저"로 결정.** 사용자 판정:
  *"게이팅 먼저. 게이팅을 base 에 만들 준비를 해야한다. 실질적 모양 정의가
  필요함."* 즉 로드맵 순서를 유지하지 않고 게이팅을 M2로 앞당긴다. **다만
  앞당기는 대상이 `Blocker` 그 자체가 아니라 그 아래의 공용 `Gate` 노드로
  바뀌었고**(같은 라운드 `DT-4`), 그 표면/이름이 미정이라 **새 열린 항목으로
  이어진다 — 바로 아래 `Gate` 항목.** 아래는 해소 전 서술: 이대로 각주만 두고
  로드맵 순서를 유지할지,
  `Blocker.luau`(또는 최소 표면 `On`/`Off`/`IsOn`/`OffWithoutEmit`)를 M2로
  앞당길지, M2/M3 경계 자체를 재검토할지.** `RC-1`의 Blocker 게이팅 해법
  때문에 `ROADMAP.md` M2의 `Dispatch.setLength`/`setOffsetSource` 체크박스가
  `getBlocker`/`:On()`/`:IsOn()`/`:OffWithoutEmit()`을 호출하는데, 정작
  `Blocker.luau` 자체는 M3 체크박스에 있다 — 로드맵 순서대로면 M2가 아직
  없는 걸 참조하게 된다. 지금은 M2 체크박스에 이 사실만 각주로 남겨둔
  임시 조치(가장 보수적인 선택, 마일스톤 재편은 안 함) — **M2 착수 전
  필요**. 상세는 `archive/v2-initial-implementation/pre-implementation-qa-round3.md`의
  "ROADMAP.md 마일스톤 정합성" 절.

- **[해소, 2026-08-21 구현 전 QA 5라운드 H절] `mountInst`의 삽입 위치 + 중첩
  offset 결함 — `Dispatch.getOffsetAt(ownerKey, i)` 신설로 확정.**
  `setOffsetSource(None)`은 얼리 리턴하고, 숫자가 필요한 쪽이 `getOffsetAt`을
  직접 부른다(사용자안 — 병렬 배열을 안 늘리는 pull 방식). 베이스는 `isSlot`
  분기의 정체가 "베이스가 있나"임을 명확히 했고(베이스는 따로 저장하지 않고
  Slot의 `.Offset`을 그대로 읽는다 — 최상위 물리 inst는 항상 0), 중첩 Slot은
  자기 `Offset`을 관측해 깊은 전파를 한다. 반영하다 **재마운트가 `Offset` Source를 새로 만들던 결함**도
  같이 잡았다(identity 재사용). 상세는
  `archive/v2-initial-implementation/pre-implementation-qa-round5-followup.md`의 H절.
  아래는 열려 있던 시점의 서술: 둘이 한 덩어리다:
  (a) `setOffsetSource`의 `None`이 "아무것도 안 차지함"과 "발행 채널 없음"
  두 뜻을 겸하고 있어 **plain 요소의 offset 숫자가 계산조차 안 된다**(그래서
  DOM류 백엔드가 삽입 위치를 알 방법이 없다 — 사용자 지적), (b) `recompute`가
  `sum = 0`에서 시작해 `ownerKey.Offset`을 안 읽으므로 **depth ≥ 2에서 중첩
  Slot의 자식 offset이 부모 베이스만큼 어긋난다**(이번에 발견, 지금까지 depth 1만
  써서 안 드러났음). 제안은 `bk.offsetList` 신설(항상 숫자 계산) +
  `mountInst(target, element, index)` + `recompute`의 `base` 시드 + 중첩 Slot이
  자기 `Offset`을 관측해 재계산하는 구독 하나 —
  `archive/v2-initial-implementation/pre-implementation-qa-round5-followup.md`의 G절이 소스.

- **[해소, 2026-08-21] offset이 바뀌면 이미 배치된 물리 노드를 옮겨야 하는가 —
  아니오.** **사용자 확정**: *"애초에 offset 바뀌여도 상관 없는게 위에서 넣고
  빼면 insert 같은거로 일어나서 뒤로 밀린다는거였긴함"* — DOM류는 삽입/삭제
  자체가 뒤 형제를 물리적으로 밀고 당기므로, **이미 놓인 노드를 다시 옮길 일이
  없다.** offset 숫자는 그 자리가 **다음에** insert/remove할 때 쓰는 것뿐이라는
  기존 서술이 그대로 맞다. 이게 성립하려면 백엔드 op이 **아토믹한 최소 단위**
  (`mountInst`/`unmountInst`/reposition)여야 한다는 게 같이 확인된 요구사항.
  아래는 열려 있던 시점의 서술: `mountInst(target, element,
  index)`가 **삽입 시점의 위치만** 받는 일회성 호출이라, 이미 마운트된 요소의
  물리 위치는 offset이 바뀌어도 갱신되지 않는다. Roblox는 `LayoutOrder`가
  프로퍼티라 `updateFn`이 반응형으로 처리하면 되지만 **DOM은 물리 순서 자체가
  배치**다. `dispatch-core-plan.md`는 "quad-web의 offset 핸들러는 no-op이고 숫자는
  *다음에* 스스로 insert/remove할 때만 쓴다"고 적어뒀는데, 앞 형제의 길이가 변해
  뒤 형제들의 offset이 밀리는 흔한 경우에 **이미 놓인 노드를 옮길지**가 그 서술만
  으론 안 갈린다. 선택지는 (a) 옮긴다(백엔드가 offset 변경을 관측해 재배치),
  (b) 안 옮긴다(그러면 DOM에선 순서가 실제로 어긋남), (c) `:List`가 재조정 때
  필요한 것만 명시적으로 다시 `mountInst`. quad-web이 실제로 생길 때까지 미룰 수
  있으나, **계약을 지금 정해두지 않으면 M6 구현이 (b)를 전제로 굳는다.**

- **[해소, 2026-08-21] `:List` 재조정의 `getOffsetAt` 비용 — 접두합 캐시로.**
  **사용자 제안 채택**: *"getOffsetAt 은 compute 된걸 캐시해도 될듯. length
  변경되는 뒤는 캐시가 무효화되도록 shouldRecomputeAfter 등을 둬서 특정 인덱스
  초과부는 offset 다시 계산하고, 해당 값 위치 자체는 유효하므로 그것을 통해 더
  length 를 이어붙이면 될듯."* → `bk.offsetCache` + **`bk.invalidAfter`**("여기까지는 유효")로 반영
  (`base/dispatch-core-plan.md`). **무효화 규칙은 하나** —
  `invalidAfter = min(invalidAfter, i)`(`setLength`도 splice도 자기 인덱스까지,
  베이스 변경만 `0`). `recompute`도 이 캐시 위에 얹혀 O(N)이라
  **"캐시를 누가 채우나"라는 갈래가 없어졌다**(사용자 정정: 함수를 나눌 이유가
  없다). 아래는 열려 있던 시점의 서술:
  `settle`이 키마다 `rawAdd`/`rawReplace`를 부르고 그 각각이 `getOffsetAt`(O(i))을
  부르므로, 이미 마운트된 리스트의 데이터가 통째로 바뀌면 **O(N²)**다(최초 마운트는
  `_mounted == false`라 얼리 리턴이 막아준다). `DC-9`에서 `setOffsetSource`의 즉시
  계산이 O(N²)인 걸 "배치 등록 1회니 감수"로 판단했지만 **이건 매 reconcile이라
  빈도가 다르다.** 해법은 있다 — reconcile이 `pos`처럼 **절대 offset도 러닝
  누적**으로 들고 다니면 O(n)(그게 `mountSlotTree`가 이미 하는 방식). 그렇게
  할지, 아니면 실측 전엔 그냥 둘지 판단 필요.

- **[해소, 2026-08-21 같은 날] 게이트가 유보했다 내보내는 emit이 싣는 출처 —
  `emit(self)` + 흡수 집합.** `GateNode`가 흡수한 소스를 `withheld` 집합에
  들고 있다가, 풀 때(=flush) **집합을 그 자리에서 떼어내 새 테이블로 스왑하고**
  자기를 출처로 그 배치를 하류에 넘긴다. 하류는 출처가 게이트면 그 집합의 소스들에 평소 규칙을
  적용한다. **`setup` 시그니처는 안 바뀐다** — 집합을 채우는 건 정책이 아니라
  노드이기 때문. `base/gate-plan.md`의 4번, `base/state-epoch-plan.md` §4
  (이관 당시엔 §2였으나 그 문서가 §1~§8로 재편됨).

- **[해소, 2026-08-21 같은 날] State 에포크 — 새 노드의 두 맵 초기값과
  `:With` 병합.** `sourceEmitMap`은 **비우고**(어떤 emit이 와도 "처음 보는
  것"으로 걸리는 게 맞다 — 새 노드는 개념적으로 emit을 받아본 적이 없다),
  `sourceCountMap`은 **전부 끌어와 실제 count로 채운 뒤 `rawInvalid = true`**
  (비워두면 순회가 훑을 목록 자체가 없어 "유효하다"로 오판한다 — *"'내가 뭘
  추적하고 있나' 가 필요하죠"*). 그래서 `:With` 병합 규칙은 **필요 없어졌다.**
  재계산 시 갱신 범위(전부 갱신)도 확정. `base/state-epoch-plan.md`의 §2·§5 7번.

- **[해소, 2026-08-21 같은 날] `Gate` — 소스 없는 emit(빈 배치)은 **아무것도
  안 한다**.** 에이전트 권고("빈 배치 = 무조건 통지")는 **사용자 기각** —
  *"쌓아둔것 자체가 없는데 뒤로 넘긴다는건 이상합니다 … 표면적으로 보면 State
  중간에 Emit 을 추가하는 격"*. 새 규칙도 아니다: `blocker-plan.md`가 이미
  "`HasBlockedEmit`이 false면 아무 것도 안 함(idempotent)"으로 확정해뒀고,
  `withheld`는 그 플래그의 일반화다. **따름정리로 `Effect(fn, ...deps)`의 설치
  구간 억제는 `Gate` 소비자가 아니게 됐다** — `Effect` 내부 플래그로 처리하고,
  `effect-plan.md`에 있던 "`Gate`보다 뒤" 순서 제약도 사라졌다.
  `base/gate-plan.md`의 7·8번.
  - **같이 제기됐던 "재진입 계약"은 열린 항목이 아니었다**(사용자 지적으로
    2026-08-21 정리) — `blocker-plan.md`의 재진입은 **같은 인스턴스 중첩**을
    말하는 것이지 정책의 `emit()` 호출과 무관하고, 끝나지 않는 되먹임은
    2026-08-04 확정 원칙대로 **UB**이며, 유한한 재진입은 flush 진입 시 스왑으로
    이미 안전하다. `gate-plan.md`의 6번.

- **[해소, 2026-08-21] 공용 게이트 노드의 이름과 표면 — `state:Gate(setup)`
  메소드 + `GateNode`로 확정.** 탑레벨 프리미티브는 안 만들고, `Blocker`는
  `state:Block(blocker)` 안에서 그 배선을 쓴다(사용자: *"Gate 는 따로
  프리미티브 없이 state:Gate( (emit) -> ()->() ) 처럼 선언되고 마치 Compute
  처럼 GateNode(ComputeNode 처럼) 생성된다"*). `Get()`엔 영향 없음(통지만
  막음)까지 확정. **[2026-08-21 정정]** 여기 "남은 것은 사용자 판단이 아니라
  구현 시 정할 것들"이라 적었으나, 두 번째 `/code-review high`가 빈 배치
  emit을 잠시 사용자 판단 항목으로 되돌렸다 — **같은 날 해소돼(바로 위 항목)
  원래 서술로 돌아왔다.** 구현 시
  정하면 되는 건 생명주기와 M2 범위뿐 — `base/gate-plan.md`가
  소스. 아래는 열려 있던 시점의 서술: 위 항목의 결정("게이팅 먼저")에 따라 base에 만들 것이
  `Blocker`가 아니라 **상류 emit을 가로채 정책이 통과 여부를 정하는 공용 게이트
  노드**로 확정됐다(`Blocker`/`Debounce`/`Throttle`이 그 위의 정책). 사용자
  스케치는 `Gate(function(emit) return function() ... end end)` 2단 구조이고,
  **공개 API로 낸다**(사용자: *"이 API가 비공개일 이유는 없어보인다"*). 남은 것 —
  (a) **이름**(사용자: *"프리미티브 명을 Gater? 뭔가 이상하게 들어간다는게 약간의
  문제"*, 에이전트 권고는 `Gate` 그대로 — `gate`는 이미 장치를 가리키는 명사),
  (b) M2에 `Gate`만 넣을지 `Blocker`까지 넣을지, 그리고 생명주기 계약.
  **[2026-08-21 해소]** 여기 있던 "`:Apply` 팩토리인가"와 "`Blocker`가 그 위에
  어떻게 얹히는가"는 닫혔다 — **사용자 확정으로 `Gate`는 `:Apply`가 아니라
  `:With`류 State 메소드**(*"state 의 전파를 손대는 작업이라 with 처럼 다른
  노드가 나는게 맞음"*)이고, 그러면 `Blocker`는 이미 확정된
  `state:Block(blocker)` 메소드가 내부에서 그걸 부르면 되므로 배선 문제 자체가
  없어진다. 상세는 `base/gate-plan.md`.

- **[해소, 2026-08-21] State 재계산/전파 판정을 "소스 에포크 비교"로 바꿀지 —
  채택 확정**(사용자: *"gate 와 epoch 가 제가 만족할만한 정도로 올라왔습니다.
  채택하면 될것 같아요."*). 규칙 전량은 `base/state-epoch-plan.md`, 구현은 M3.
  아래는 열려 있던 시점의 서술: 사용자 제안: 각 State가 자기 상류 루트
  `Source`들의 카운트를 들고 있다가 `Get()` 때 비교해 재계산 여부를 정한다.
  동기는 성능이 아니라 **정확성** — DFS 전파 도중 Observer가 `Get()`을 부르면
  아직 신호를 못 받은 다른 가지의 옛 캐시가 섞여 들어가는 glitch가 지금 모델에
  실재한다. 에이전트 분석 결과 진단·방향 모두 타당하고 선례도 있다
  (MobX/Adapton류 버전 검증). **[2026-08-21 갱신 — 여기 있던 "중복 통지는 안
  고쳐지고 선언 안 된 의존성을 UB로 명문화해야 한다"는 서술은 같은 날 둘 다
  뒤집혔다]**: 중복 통지도 **같은 장치로 접고**, UB 조항은 사용자 기각으로
  빠졌다. 이어진 3·4차 정정으로 **기제는 사실상 다 정해졌다** — 순회는
  `rawInvalid`가 **false**일 때만 돌고(목적은 "못 받은 emit 받기"), emit은
  count 없이 **발행 source만** 싣고, 순회가 발견한 변경은 **테이블 둘**로
  처분한다(`sourceCountMap`은 순회가 앞당겨 올리고, `sourceEmitMap`은 상류의
  진짜 emit을 기다림 — *"emit 바로 안하고 상류가 emit 해줄 때 까지
  기다립니다"*). 그래서 통지가 죽지도 게이트를 새지도 않아 `source = nil`
  규약도 필요 없어졌다. **남은 판단은 채택 여부 자체 하나**이고, State 내부 표현을
  바꾸는 결정이라 M3 뒤로 미루면 되돌리는 비용이 크다. 상세는
  `base/state-epoch-plan.md`.

- **[해소, 2026-08-21 구현 전 QA 5라운드 `C-4`] `Dispatch.setLength`의 Observer
  앵커 — 물리 target으로 확정(4라운드 `D-56` 역전).** `setLength`가
  `(ownerKey, i, len, anchor)`로 4번째 인자를 받아 **부기 키와 생명주기 앵커를
  분리**한다. 그래서 `bindLifetime`은 항상 물리 Instance만 상대하고,
  `isBoundAlive`의 세 번째 분기(형태 미정으로 열려 있던 것)도 **필요 자체가
  없어졌다.** 역전 원문은 `archive/bindlifetime-slot-owner-reversed.md`, 지금
  결론은 `base/dispatch-core-plan.md`의 "`setLength` 구현" 절 뒤 문단. 아래는
  열려 있던 시점의 서술: 그때 확정(4라운드 `D-56`)은
  "`bindLifetime`의 첫 인자가 Slot일 수 있으니 백엔드가 그 경우를 핸들링하라"인데,
  사용자가 그 전제 자체에 의문을 제기했다: *"애초에 Slot 이 effect 나 다른
  요소들을 소유할 수가 없다 … 실제 observer/effect 는 실제 inst 에 불림 …
  우리가 왜 slot 을 소유 대상으로 둘 수 있게 한거였는지 다시 생각해봐야할
  부분."* 대안은 **부기 키(`ownerKey`)와 생명주기 앵커(물리 `physicalTarget`)를
  분리**하는 것 — 그러면 `bindLifetime`은 항상 Instance만 받고,
  `isBoundAlive`의 세 번째 분기(지금 ⚠️ 미정)도 통째로 불필요해진다. 상세와
  트레이싱은 `archive/v2-initial-implementation/pre-implementation-qa-round5-followup.md`.

- **[해소, 2026-08-21] `Detach` 홀드 중 키가 사라졌을 때의 처분** —
  선택지 (c)로 확정: `updateFn`을 **`KeyGone`으로 한 번 더 불러 처분을
  묻는다**. 같이 확정된 것 — detach된 요소는 `userdata`가 아니라
  **`slot._detached` 필드**가 보유하고(그래야 `destroySlotTree` walk가
  닿고 소유권도 유지됨), owner가 죽으면 `activateList`가 설치한 `Effect`가
  정리한다. 원래 갭이
  치명적이었던 이유는 gcconn 트릭 때문에 detach된 quad-제작 Instance가
  **GC 폴백조차 없이 영구히 남기** 때문. 상세는 `base/slot-plan.md`의
  "Detach된 요소는 `slot._detached`가 보유한다"/"`KeyGone`" 절.

- **[해소, 2026-08-21] `attachSlot` 책임 분해** — **(B) 분해 채택으로 확정**,
  `base/slot-plan.md`에 반영 완료(`materializeSlotTree`/`mountSlotTree`/얇은
  `attachSlot`). 근거 기록은 `reference/slot-attach-decomposition.md`.
  아래는 그 열려 있던 시점의 서술: 한
  함수가 부모 등록(offset/length) / `:List` 실체화 / 마운트 상태 전이 / 배치
  게이팅 / 자식 배치 / 재귀를 다 지고 있어서, **"부모에게 알리는 길이의
  최종값은 flush가 끝나야 정해진다"와 "부기가 물리 조작보다 먼저"가 동시에
  만족되지 않는다**(지금은 후자를 지키고 전자를 포기 — 부모 `recompute`가
  1회 헛돎). 사용자 판단으로 확장 논의 대기 — 책임 목록/순서 제약 출처/분해
  후보 넷은 `reference/slot-attach-decomposition.md`. **M6(`:List`) 착수 전
  필요**, 선행으로 아래 `Detach` 보관 위치가 먼저 닫히는 게 나음.

- **[해소됨, 2026-08-18] `Attribute.Merged`의 이름 중복** — `Merged`(겹치면
  error)와 `Overridden`(겹치면 뒤가 이김)을 **둘 다 제공**하는 것으로 확정
  (제3안). 근거·파급은 `base/attribute-plan.md`의 "채택안 — `Tag`와 동형인
  array-part 값 객체" 절.

- **[신설, 2026-08-18 구현 전 QA] 그룹 `Attribute`의 위치별 claim 설계** —
  같은 그룹 객체를 두 위치에 놓는 경우(`Frame { a, a }`)를 잡으려면 위치별
  claim 레지스트리가 하나 필요하다는 **방향은 확정**됐고(`Ref`처럼
  `bindLifetime`을 재사용할 수는 없음 — 그룹 값은 여러 곳에서 쓸 수 있어야
  하므로), **[2026-08-20 QA 4라운드] 이름도 `groupClaimKeys`로 확정**.
  **[해소, 2026-08-21 QA 5라운드 `AT-1`] 키도 `(inst, groupValue) → k`로 확정**
  (사용자: *"group 에 따라 key 가 따로 생성되므로 다른 그룹에 대해서는 잡을
  필요가 없고, 그건 key->name 이 유일성을 검증해준다"*), `nameClaims`보다
  **위치 claim을 먼저** 본다 — `base/attribute-plan.md`의 "이름 소유권" 절.
  **이 항목은 닫혔다.**

- **`Gate`(2순위, 2026-08-21 신설)**: `Blocker`/`Debounce`/`Throttle` 아래의
  공용 게이트 노드 이름. 사용자 지적 — *"프리미티브 명을 Gater? 뭔가 이상하게
  들어간다는게 약간의 문제"* — 코퍼스가 `Blocker`/`Modifier`/`Observer`처럼
  `-er`를 많이 쓰는데 `Gater`는 영어로 어색하다. 에이전트 권고는 **`Gate`
  그대로**(`gate`는 이미 행위자가 아니라 **장치**를 가리키는 명사라 `-er`가
  불필요 — `Source`/`Ref`/`Slot`/`Tween`도 같은 계열), 대안 후보는
  `Valve`/`Relay`. **[2026-08-21 해소] `Gate`로 확정**(탑레벨 생성자를 안
  만들고 `state:Gate(setup)` 메소드로 가면서 `Gater` 문제 자체가 사라짐 —
  메소드 자리에서는 `:With`/`:Compute`와 나란히 자연스럽다). 노드 타입 이름은
  `GateNode`. `base/gate-plan.md`의 1번이 소스.

## [해소됨, 2026-08-21] `Epoch`의 리비전 증가 방식 — `bit32` 랩으로 확정

**결론**: `self.Revision = bit32.bnot(-self.Revision)`.
리비전은 uint32 안에 머문다. 정본은 `base/state-epoch-plan.md` §2.
**[2026-08-22 정정]** 이 항목을 처음 적을 때 에이전트가 형태를
`bit32.band(rev + 1, 0xFFFFFFFF)`로 잘못 옮겼다 — 사용자가 말한 건 처음부터
`bit32.bnot(-a)`였고(*"제가 말한건, bit32.bnot(-a) 입니다"*), 그건 랩어라운드
**감소**를 **연산 하나로** 한다(`a > 0`이면 `a - 1`, `0`이면 `4294967295`).

**사용자 논거**: *"그건 luau 에서 native call 이라 아주 빨라요. 반면 double 의
연산이 느린편인데, 희소 수준이 아니라, 사실상 만나는걸 수년간 보기 어려운
라운드되어 동일해 무시되는 경우를 막기 위해 double 까지 올려야할 이유를
모르겠어요. 매번 도는 코드인지라, 값 싸게 native call + num 연산으로 가볍게
가고 싶어요."* — `2^53` 포화는 어차피 도달 불가능한 시나리오인데 그걸
피하겠다고 값을 double 영역까지 키울 이유가 없다는 것. 매 `Set`마다 도는
hot path다.

**에이전트가 달았다가 철회한 단서**: "`bit32`라서 더 싸다는 건 아니다 —
`n + 1`은 어느 쪽이든 double 덧셈이고 `bit32`는 fastcall을 하나 더 얹는다"고
적었으나, **이건 `band(rev + 1, mask)`라는 다른 형태를 놓고 한 비교라
틀렸다**(2026-08-22 정정). `bit32.bnot(-a)`는 덧셈 위에 얹히는 게 아니라
**갱신 자체를 대체**하는 단일 FASTCALL이므로, "native call이라 아주 빠르다"는
사용자 서술이 맞다.

**따름정리**: 이 방식은 **단조 증가가 아니라 랩어라운드 감소**다. 지금 규칙이
`==`/`~=`만 쓰기 때문에 무해하지만, 순서 비교를 넣고 싶어지면 이 결정부터
되짚어야 한다.

아래는 열려 있던 시점의 서술:

- **`Epoch`의 리비전 필드 증가 방식(3순위, 2026-08-21 신설)**: `bit32` 랩
  (uint32 랩어라운드라 double 포화가 없음, 사용자가 염두에 둔 쪽) vs 평이한
  `+1`(할당·연산 더 쌈, 포화가 `2^53`이라 `bit32`의 `2^32` 랩보다 충돌 거리가
  오히려 넓음). **둘 다 도달 불가능이라 실질 위험은 없고 취향 문제다.**
  **이게 `Epoch`/`EpochMap` 승격 후 남은 유일한 미정 항목이다** —
  `base/state-epoch-plan.md` §2, 근거 기록은
  `reference/epoch-brand-composition.md` §4의 4번.
  (필드 이름 `Revision`과 타입 `Epoch`는 확정, 승격 시 `base/`에 반영됨.)

## [해소됨, 2026-08-24] M2/M3 마일스톤 경계 — 순서 교체로 확정

2026-08-22 `ROADMAP.md` 전반 점검에서 드러난 항목. **설계 결정이 아니라
마일스톤 *순서* 문제**라 당시 `question.md`의 최우선 절이 아니라 2번
항목으로 따로 뒀었다. 2026-08-24에 사용자가 **(a) 순서 교체**를 선택해
같은 날 전량 반영됐다.

**발단** — 옛 M2(디스패치 엔진)와 옛 M3(Store/State/Source)의 의존이
양방향이라 그 순서로는 M2를 끝까지 짤 수 없었다.

- **디스패치 → 반응형 (본체 의존)**: `Dispatch.setLength`가
  `len: number | State<number>`를, `Dispatch.setOffsetSource`가
  `Source<number>`를 받고, `recompute`가 `offset:Set()`을 부른다
  (`base/dispatch-core-plan.md`의 "Length/Offset" 절). 2026-08-22에
  디스패치 쪽으로 앞당겼던 `GateNode`/`Blocker`도 State 위에 얹힌다.
- **반응형 → 디스패치 (얕은 의존)**: `state:Observer`/`Effect`의 동적 경로
  가드가 `Dispatch.addHandler` + `Handler.luau` 계약을 쓴다 — 레지스트리
  등록 표면만 있으면 되므로 디스패치 **전체**를 요구하지 않는다.

**선택지와 판단** — (a) 순서 교체 / (b) 디스패치를 둘로 분할 / (c) 지금
구조를 두고 구현 시 알아서 오간다. **사용자 선택은 (a)**("(a) M2와 M3의
순서를 바꾸는게 맞겠던데"). 그 자리에서 같이 확인된 근거:

1. **의존의 비대칭**이 명확하다 — 무거운 쪽(본체 의존)을 아래에 깔고
   가벼운 쪽(핸들러 등록)을 뒤로 미루는 게 맞다.
2. 옛 순서로는 **디스패치 마일스톤의 `mock 대상 테스트` 체크박스가
   원리적으로 불가능**했다(`setLength`/`recompute`를 State 없이 테스트할
   수 없음). 반대로 반응형 코어는 순수 Lua라 `luau`만으로 단독 테스트가
   된다.
3. 2026-08-22의 `EpochMap`/`GateNode`/`Blocker` 앞당김이 **불필요해진다**
   — 그 이동은 "디스패치가 먼저인데 디스패치가 쟤들을 호출한다"는 이유로
   한 것이었다. 순서를 바꾸면 마일스톤 내용이 의존 계층과 그대로 일치하고
   끌어온 항목이 0개가 된다. "게이팅 먼저"는 그대로 지켜진다.

**(b)를 안 고른 이유**: 참조 비용이 오히려 더 크다 — 기존 `M2` 참조 전부가
"M2a인가 M2b인가"로 애매해지는데 이건 순서 교체처럼 기계적으로 못 푼다.
게다가 `Brand`를 앞으로 빼는 일은 (b)에서도 똑같이 해야 하고, 얻는 건
"디스패치 코어를 조금 일찍 짠다"뿐인데 M4 전까지 그걸 소비하는 게 없다.
**(c)를 안 고른 이유**: `project-context.md`가 못박은 *"어떤 순서로
만드는가"*의 소스가 `ROADMAP.md`라는 원칙을 스스로 무효화한다.

**같이 확정된 것 — 순서만 바꿔서는 안 끝났다.** 옛 M2 안에 반응형보다
먼저 와야 하는 항목이 셋 섞여 있었고, 이들은 새 M2 앞머리의
`### 공통 기반` 절로 옮겨졌다(State-free이자 dispatch-free):

- **`Brand.luau`** — `Source`가 `SourceBrand`+`EpochBrand`에 등록돼야 함
  (`base/source-state-plan.md`), `isState`/`isObserver`/`isEffect`가 전부
  여기 얹힘.
- **`Relate.luau`** — `bindLifetime`/`unbindLifetime`이 그 위에 구현됨
  (`base/lifecycle-pattern.md`의 `InstData`/`BindData`).
- **`LifetimeHandle.luau` 인터페이스** — State 전파 루프가 발화마다
  `canExecute`를, 이중 바인딩 게이트가 `canBound`를 부름. 이미 M8→디스패치로
  한 번 앞당긴 전례가 있던 항목이라 한 칸 더 앞당긴 것뿐.

반대로 새 M3로 넘어간 것은 둘 — Observer/Effect **동적 경로 가드 등록**과
**`ObserverEffectLeafHandler`**(`H-39`). 둘 다 "핸들러를 등록한다"뿐이라
본체와 잘라내기 쉽고, **이것이 M2가 M3에 개념상 지던 유일한 의존**이었다 —
그 둘을 M3로 미뤘으므로 **빌드 순서상 역방향 간선은 남지 않는다**:

```
L0 공통 기반   Brand · Relate · LifetimeHandle(인터페이스)      ┐
L1 반응형      Source/State/Store · EpochMap · Gate/GateNode ·  ├ M2
               Blocker · :Compute/:Apply · Observer · Effect    ┘
L2 디스패치    Handler · Dispatch 코어 · chains · None ·          ┐
               setLength/setOffsetSource/getOffsetAt ·           ├ M3
               Leaf · 가드 등록 · ObserverEffectLeafHandler      ┘
```

**⚠️ 번호 재부여의 부작용** — 라이브 문서의 `M2`/`M3` 참조는 전부 새 번호로
맞췄지만(코퍼스의 참조가 거의 전부 "그 내용이 사는 마일스톤"을 가리켜서
기계적 맞교환으로 의미가 보존됨), **`session/`·`archive/`·`qa-request/`는
히스토리 문서라 소급 수정하지 않았다.** 2026-08-24 이전에 쓰인 그 문서들의
`M2`/`M3`는 **옛 의미**(M2=디스패치, M3=반응형)로 읽을 것. 이 경고는
`ROADMAP.md`의 M2 배너에도 있다.

## [해소됨, 2026-08-28] `Claim` 갈래 — `research/existing-mount-plan` §5 여덟 항목

**2026-08-28 10라운드 `H-148`에서 신설된 research 문서의 §5 갈래 여덟 개가 같은 날
사용자와 대화형으로 전량 확정돼 `base/claim-plan.md`로 승격됐다** — 결정과 사용자
원문은 그 문서 §7, 대화 원문은 `session/2026-08-28-02-claim-promotion.md`. 요지:
루트 키는 센티널(맨 테이블 + `Claim<<T>>`는 타입 자동완성 손실로 기각) / 디스크립터
순서 정본 / claim된 부모 안 `New` 자식 허용(위치는 프로바이더 몫) / debug 검사 범위는
`research/debug-tooling-plan.md`로 이동 / 이름 `Claim` + `D.Mapper` / M5 /
**§5-7(여러 스크립트가 한 `PlayerGui`)은 `Claim` 1회·전체 소유 유지 + 루트의
`.Parent =`는 밖에서 허용으로 복원**(사용자: *"정확히는 두번 Claim 불가하다는 의미.
필요하다면 Slot 을 안에 만들고 리턴하는 중간 모듈을 만들어야함. 밖에서 .Parent
설정하는건 괜찮아"*) / 매핑된 정적 자식은 같은 `InstanceChildHandler`.

같은 날 저녁 `/code-review high`가 낸 **M5 착수 전 문항 넷**(gcconn/gchold 셋업 자리 /
이중 claim 레지스트리 / `PlayerGui` own-all / `<Class>Param` 배열 파트)도 **몇 시간 안에
답이 와서 닫혔다** — `base/claim-plan.md` §7-9~12: 주입 op `nativeClaim(inst)`에 (0)
경로 전부(`New`도 호출) / 이중 claim은 셋업 유무로 error, 문항의 `elementOwner` 충돌은
"claim은 slot과 무관"이라 틀린 전제 / `PlayerGui`는 *"공동 소유 가능 객체"*라 claim
대상이 아니고 루트는 `ScreenGui`·`SurfaceGui` / `FrameParam<E>` 원소 타입 파라미터.


## `AttributeGroupHandler.process`의 부분 실패 롤백 — 안 한다 (2026-09-03 사용자 확정)

`question.md` 낮은 우선순위 절에 2026-08-14 리뷰로 올라왔던 항목: 그룹
`process`가 이름을 순회하다 소유권 충돌 error가 나면 그 전에 위임된 이름들의
체인은 이미 등록됐는데 그룹 retractor가 안 만들어져 이 사이클엔 회수되지 않는다
(피해는 그 인스턴스 수명으로 한정, 재현은 시끄럽게 반복). 원자적 unwind를 넣을지가
질문이었고, M10 quad-base 절반이 fork 편입(2026-09-03)될 때까지 fork도 롤백
없이 문서화 노선을 유지했다. **사용자 확정**: *"터지더라도, 시끄러운 에러를
내며 그 이후 동작이 깨지는건 괜찮으니, 문서화로 부분 실패를 따로 관리 안
한다는걸 적어두는거라면, 동의"* — 별도 장치 없음, fail-fast 톤 그대로,
`base/attribute-plan.md` 말미에 확정 서술. 원문은
`session/2026-09-03-01-fork-integration.md`의 회신 절.

## [2026-09-08 해소] 탐사 순회 문항 Q33~Q36 (round3 §4·§10, 결정은 §11)

- **Q33** `None`으로 오브젝트 참조 프로퍼티를 해제할 수 없다 → **(a) skip-defense 제거, nil을 쓴다** — 사용자 실측 `Motor6D.Part0`가 nil, nil을 못 받는 타입은 엔진이 에러(M10 캐비엇·`H-352` 역전).
- **Q34** 모든 타입에 Tween 팔 → **(a) 보간 가능 타입만**(생성기 `TWEENABLE`, `FieldP<T>`).
- **Q35** `OnChange("Parent")` 타입 거부 → **(a) 읽기 표면에 `Parent`**.
- **Q36** KeyGone `ud` 잔존 → **열지 않음, 사용자 재량**(캐싱 용도 허용; `userdata`는 수동 제거가 필요한 데이터를 담지 않는 게 계약).
- 부수: round5 §4 Q30~Q32는 사용자 본인 회신임을 확인.

## [2026-09-08 해소] Gemini 자문 권고 셋 + 구조 재편 8절·10-4 + round3 Q26·Q27 (결정은 round3 §12)

- **권고 1 `__tostring`** → **채택**, 대상은 값 프리미티브 목록(브랜드 유무가 기준이 아님 — 사용자: Epoch도 브랜드), `AttrKey` 제외.
- **권고 2 `setFuncLevel(level, ...fns)`** → **채택, 옛 시그니처 폐기**(다른 프로젝트 사용 없음 — 지금이 최적 시기).
- **권고 3 메시지 포맷 헬퍼** → **기각** — 정적 grep 가능해야(Fallback 도입 시 더욱). 컨벤션(`architecture.md` "메시지 모양")으로 대체, 어긋난 열 곳만 손질.
- **구조 재편 8절 옛 `Attribute` → `Attr`** → **한다** + `AttrKey`·엔진 op `setAttr`("quad의 Attr은 엔진 무관, 구현이 Attribute에 바인드됨이 드러난다").
- **10-4 D 정적 굽기** → **지금 안 함, 백로그가 아닌 리서치 대상**(정보 취합·결정이 선행, 런타임·표면 영향 없음).
- **Q26** 트윈 첫 스냅 → **(a) 축소판**(둘째 증상은 Q33으로 이미 소멸).
- **Q27** 프로바이더 브랜드 프로브 등록 op → **기각**, 모듈 최상위 `is<Brand>` 필드가 계약이고 진단은 스캔.
- **Q25** 숏핸드 dedup → **같은 날 아침 닫힘, 값 비교 모델**: 소비자(Property 핸들러)가 목표 `Value`만 비교(옵션은 비교 대상 아님), `Dedup`은 Tween 필드(기본 true), 메커니즘은 핸들러 하나 — 옛 Q12 신원 모델·슬롯 `Source` 폐기, 숏핸드 캐시 불필요(`H-478`).
- 열린 것: flatten 슈거 일곱(+named 자리 축, 내일).

## [2026-09-27 이전 — 항목별 해소 2026-09-15·16] question.md 1절 용어 정리 절 전체 원문

round13 E74가 절 제목만 "진행 중"으로 남은 것을 발견해 2026-09-27에 통째로 옮겼다(각 항목의 `[해소 …]` 태그와 결정 원문 포인터는 원문 그대로).

사용자 원 메모: "quad는 register라던가 좀 부정확하거나 느낌이 바로 와닿지
않던 용어들이 많음 — 전체적 용어를 보고 생각해볼래? 제안을 줘, 나도 같이
볼게." **이미 확정된 이름**(`State`/`Relate`/`List`/`canBound`/`Ref`/
`PreRef`/`Peek`/`isState`/`None`/`NoneHandler`/`Handler`)의 근거는
`archive/question-resolved.md`. (`canBound`는 2026-08-14 다섯 번째 세션에
폐기돼 `canExecute`로 통합됐다가 **같은 날 열한 번째 세션에 별도 진입점으로
재도입**되어 여전히 이 목록에 있음 — 이중 바인딩 가드 전용이고 `canExecute`
(emit 게이팅 전용)와는 판정 로직만 공유. 아래 3번 `canExecute` 항목과
`base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절,
`archive/canexecute-inst-arg-reversed.md` 하단 addendum 참고.)

- **[해소 2026-09-16 — 유지, 사용자 동의("얻는거 없어서 권고:유지 동의")] `Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **[2026-09-15 해소 — `OwnsElements`로 개명, 사용자 결정] `Owned`(3순위, 2026-08-21 신설)**: `:List`/`:Single`의 설치 시점
  플래그(기본 `true`, `false`면 어떤 경로로도 파괴 안 함).
  `elementOwner`/`claimOwner`/`releaseOwner`와 같은 뿌리라 골랐지만
  **잠정 이름**이다 — 형용사라 옵션 테이블 키로는 자연스러운데, 실제로
  묻는 건 "이 Slot이 요소의 수명을 책임지는가"라서 `OwnsElements`처럼
  주어를 드러내는 쪽이 나을 수도 있음. `base/slot-plan.md`의
  "소유권은 설치 시점에 정해진다" 절.
- **[해소 2026-09-16 — 유지, 사용자 결정("원래부터 이견이 없었거든. 의미가 문제되는것 처럼 안 보여")] `canExecute`(3순위, 사소함)**: 메인의 `canEmit` 제안은 사용자 반대("emit 은 이미 있는 epoch/emit 관계론과 의미가 달라짐. canExecute 는 도달된다가 아니라 '실행되는 맥락이냐'에 가까워서, observer/effect 가 메인 콜백이 실행되느냐에 가깝기에 emit 과는 겹치는 문제가 생긴다 봐") → sonnet 두 시각(API 독자 / 구현 의미론)이 독립 검증: `canExecute`는 구독자 콜백 실행 직전에서만 불리는 수신측 게이트(`Observer._receive`·`Effect.rawRerun`), emit은 코퍼스에서 발신자 사건으로 굳어 있어 `canEmit`은 방향이 반대 — 기각. `canRun`은 의미론상 동치이나 `Effect:Rerun`과 겹치고 관측된 오독 사고 없이 백엔드 계약 BREAKING을 만드는 셈이라 유지. 원문 `session/2026-09-16-01-d-typefunction-measurement.md` §5. (옛 서술 ↓) 실제로 "이 값이 아직 살아있나" 확인인데
  이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적이라는 제안이
  있었으나, **(2026-08-08 재검토)** `isAlive`는 top-level `isX` 계열
  (`isState`/`isRef`/`isPreRef`/`isModifier`/`isObserver`류 — 전부 타입
  판별자)과 접두어가 겹쳐 "이것도 타입 체크인가" 오해를 유발할 수 있다는
  점이 지적됨. `canExecute`는 타입이 아니라 liveness(생존 여부)를 묻는
  질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽이 낫다는 방향으로 사용자가
  기욺 — 여전히 미확정, 다음에 `can`으로 시작하는 구체 대안(예: `canRun`)을
  같이 검토할 것. **[2026-08-14 다섯 번째 세션] 시그니처는
  `canExecute(value): boolean` 1-인자로 확정**(옛 `(inst, value)` 2-인자는
  폐기, `base/lifecycle-pattern.md`, `archive/canexecute-inst-arg-reversed.md`).
  **[2026-08-14 열한 번째 세션 정정]** 당시엔 `canBound`가 폐기돼
  `canExecute` 하나가 두 역할을 겸했으나, 이후 `canBound`가 별도
  진입점으로 재도입되며 다시 갈라짐(같은 문서의 "`canBound` vs
  `canExecute`" 절) — 이 이름 정리 항목은 이제 `canExecute`(emit 게이팅
  전용)에만 적용되고, `canBound`(이중 바인딩 가드 전용)는 별개 이름으로
  유지됨. 둘 다 판정 로직은 비공개 헬퍼 하나를 공유.
- **[해소 2026-09-16 — `nextValue`로, 사용자 동의; 코드·공개 문서엔 옛 이름 0건이라 비파괴, `dispatch-core-plan.md` 계약 서술 갱신] 클로저 인자 이름 `hintValue`(3순위, 사소함, 2026-08-13 열네 번째
  세션 신설)**: 하강 diff 재디스패치에서 이 인자는 더 이상 "힌트"가
  아니라 **`nil`이거나 같은 핸들러가 곧 처리할 새 값**임이 계약으로
  보장됨(`base/dispatch-core-plan.md`) — 이름이 옛 모델의 잔재라
  `nextValue`류가 더 정확함. 코퍼스에 이미 널리 쓰인 이름이라 이번엔
  안 바꾸고 대기열에만 올림(의사코드는 새로 쓰는 자리부터 `nextValue`를
  쓰기 시작했음).
- **[해소 2026-09-16 — 유지, 사용자 결정: "kind 는 분법적 요소로 보일 수 있고, 포함 관계를 표현하는 어휘가 아닐 수 있어보이고, Marker 는 *Marker 타입이 존재해서 StateMarker 가 무엇을 의미하는지 모를 수도 있음. 바꿀 이유가 없음"] `Brand`(3순위, 사소함, 2026-08-07 여덟 번째 세션 추가)**: 런타임
  nominal 타입 판별 통합 메커니즘 — `base/brand-plan.md`에서 동작/구현
  방식은 확정, 이름만 열린 질문(사용자가 직접 제기). `Tag`는 이미
  quad-roblox의 `CollectionService` 래퍼로 쓰여서 이름 충돌, 후보로
  "type namespace"류를 사용자가 검토했으나 미확정. **(2026-08-08 재확인)**
  사용자가 다시 짚었지만 여전히 미정.
  - **[2026-08-21 갱신] 표면이 바뀌어서 "OOP 인스턴스의 클래스명을 얻는
    느낌"이라는 원래 요구는 이제 안 맞는다** — 인스턴스 브랜드로 재작성되며
    역조회(`Brand.get`)가 없어졌고, 지금 하는 일은 **집합 멤버십**
    (`SomeBrand:Is(x)`)이다. 이름 후보도 그 방향으로 다시 볼 것.
  - **[해소 2026-09-15] 메소드 케이싱** — `:Register`/`:Is`로 올렸다(사용자 결정,
    `research/public-surface-pre-adoption-review.md` (13)번). 남은 건 `Brand`라는 이름뿐.
- **[해소 2026-09-16 — 유지, 사용자("문제가 없는 부분"); `Brand` 유지로 충돌 문항도 소멸] `Tag`/`Added`/`Removed`/`Merged`(3순위, 사소함, 2026-08-08 세 번째
  세션 array-part 값 객체 재설계 때 확정된 API 표면)**: `base/tag-plan.md`가
  "열린 질문 없음, 값 모양/메커니즘/retract/패키지 배치 전부 확정, 이름
  자체만 용어 정리 대상"이라고 명시해뒀으나 이 목록에 반영이 안 돼 있던
  누락 — 이번에 추가. `Tag`는 Roblox `CollectionService`가 쓰는 용어와
  1:1 대응이라 그 자체로는 무난해 보이지만, 위 `Brand` 항목(97-99행)에서
  "`Tag`가 이미 이 뜻으로 쓰이고 있어서 충돌"이라는 이유로 `Brand`의
  대안 이름 후보에서 제외됐다는 점은 참고할 것 — 두 이름이 같은 코퍼스
  안에서 공존 가능한지도 같이 검토 대상.
- **[해소 2026-09-16 — 유지, 사용자] `Attr`/`AttrKey`(3순위, 사소함, 2026-08-11 아홉 번째 세션
  추가)**: 여러 Store를 한 번에 attribute로 묶는 그룹 프리미티브
  (`Attr(store1, store2, ...)`, `Tag`와 동형)가 신설되면서, 기존
  단일 키 생성자 `Attr<<T>>("name")`를 이름 충돌 방지를 위해
  `AttrKey<<T>>`로 잠정 리네임함(`OnChange`/`OnChangeDescriptor`(구
  `OnChangeKey`, 2026-09-03 배열부 역전)처럼 함수 이름과 반환 타입 이름이
  분리된 기존 전례와 대칭) — 해석 모호성 자체는
  이미 없앴으니 급하지 않지만, 최종 이름은 여전히 이 목록의 다른
  가칭들과 함께 검토 대상. `base/attribute-plan.md` "그룹 `Attr(...)`"
  절 참고. **[2026-09-03]** `AttrKey`는 이제 무타입 프리미티브(제네릭
  없음)이고 일상 경로는 슈가 `StringAttr(name, value)`류라(사용자:
  *"AttributeKey 는 내부적 요소로 놓는거야"*) 이름의 노출 빈도가 낮아졌다 —
  검토 우선순위는 더 내려간다.
- **참고 — 이미 지나간 사례**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`process`/`retract`/`isHandlable`은 업계
  선례와 잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.

## [2026-09-08 해소 — 2026-09-27 옮김] `question.md` 2절 `Operator` 콤비네이터 슈가 이름·범위 항목 원문

이름 `Operator`·범위는 2026-09-08 밤 사용자 확정 뒤 구현됐다(`research/operator-sugar-plan.md` 머리 배너). 아래는 확정 전 서술 원문.

- **`Operator` 콤비네이터 슈가 네임스페이스 이름+포함 범위(2026-08-12 신설,
  같은 날 후속으로 외부 리서치 완료)** — `Sum`/`Product`/`Not`/비트연산 등
  `:Compute`/`:Apply`용 슈가 함수 모음의 이름. 흔한 단어라 top-level
  노출은 위험, 후보는 `Operator`/`Op`/`Ops`(`Combinator`는 코퍼스 전반에서
  이미 일반명사로 쓰여서 제외) — **서브 에이전트 외부 리서치 결과 `Operator`가
  가장 선례가 강함**(Python `operator` 모듈)이나 최종 확정은 여전히 사용자
  몫. 같은 리서치에서 포함 범위도 새로 갈렸음 — 비트/비교 연산자 그룹과
  `Sub`/`Div`는 리액티브 콤비네이터로서 선례가 전혀 없어 드랍 후보로,
  `Clamp`/`Min`/`Max`는 선례가 강해 추가 후보로, Debounce/Throttle은
  업계에 흔하지만 `Blocker`와는 다른 시간 기반 메커니즘이라 이 카탈로그
  밖 별개 질문으로 분리됐었음 — **[2026-08-19 해소]** 그 별개 질문은
  `base/debounce-throttle-plan.md`로 전부 해소·승격 완료, 더 이상 판단
  대기 아님. **[2026-08-13 세션 신설]** `Alternative`(nil 대체값, coalesce/`??`/
  엘비스 연산자류) 후보 추가 — Haskell 비교 리서치 중 나옴, 카탈로그 확정
  규칙에 그대로 맞아 포함 근거는 있음. 상세는 `research/operator-sugar-plan.md`.
  구현 자체는 맨 마지막 우선순위(순수 슈가, 없어도 무방) — 여전함.

## [2026-10-15 옮김] question.md에서 걷어낸 닫힌 항목 원문 (최우선 절·0절·1절 포인터·2절·3절)

문서 정리(Gemini 탐사 → opus 검증 → 메인 적용, `audit/doc-cleanup-2026-10-15/`)에서 question.md 규칙("해소하면 여기서 지우고 archive로")대로 옮겼다. 원문 그대로다.

### 옛 최우선 절 본문

**[2026-08-28] 10라운드 §4 문항 7건과 그 반영분의 후속(`H-158`~`H-164` — `EmitReceive`·
`Observer:_catchUp` 포함)까지 사용자와 대화형으로 전량 결정·반영됐습니다**(소스는
`archive/v2-initial-implementation/pre-implementation-handtrace-round10-followup.md`). 같은 날 마지막으로
남아 있던 **`Claim` 갈래 여덟도 전량 확정**돼 `research/`에서 `base/claim-plan.md`로
승격됐습니다(결정 기록은 그 §7, 원문은 `session/2026-08-28-02-claim-promotion.md`,
해소 요지는 `archive/question-resolved.md`의 "`Claim` 갈래" 절). **M2 착수를 막는
항목은 없습니다.**

**[2026-08-27] 9라운드**(Q1~Q10·`H-138`·`H-139`·`H-142`·`H-143`~`H-146`)는
전량 처리·반영됐습니다 — 소스는 `-round9-followup.md`.

**[2026-08-26] 8라운드 손 트레이싱이 처리 완료됐습니다 — M2(반응형 코어)
착수를 막는 항목이 하나도 없습니다.** 발견 17건(`H-107`~`H-123`)의 결정
문항 Q1~Q10을 사용자와 대화형으로 전부 처리하고 `base/`에 반영했습니다 —
**결정의 소스는
`archive/v2-initial-implementation/pre-implementation-handtrace-round8-followup.md`**(발견 원문은
`-round8.md`, 개수·개별 항목은 여기서 세지 않음). 7라운드 확정 중 뒤집힌
것은 없고, 고쳐진 건 전부 **7라운드가 `base/`에 내려앉을 때 생긴
누락·충돌**입니다. 아래 blockquote는 8라운드 이전(2026-08-25) 시점
서술입니다 — 그때 닫힌 두 항목 자체는 그대로 유효합니다.

> **[2026-08-25] M2(반응형 코어) 착수를 막는 항목이 하나도 없습니다.**
> 2026-08-24에 이 절로 올라왔던 둘이 7라운드 손 트레이싱 후속에서 같이
> 닫혔습니다 — 결정과 근거는
> `archive/v2-initial-implementation/pre-implementation-handtrace-round7-followup.md`가 소스.
>
> - **중간 State GC 미검증** → **닫힘.** 사용자 확정: *"단순히, 각 state
>   들이 상위 State|Source 를 홀드하는 `_hold` 를 놓는것으로 바로
>   해결된다. 당연히 후행은 선행 요소들이 있어야하기 때문."* 불변식은
>   **하류 → 상류 강함(`_hold`) / 상류 → 하류 weak(구독자 집합)**이고
>   `base/source-state-plan.md`에 명문화됐습니다. 실측 스파이크는 여전히
>   `luau-test`에 하나 두는 게 좋지만 **착수 게이트는 아닙니다**.
> - **동적 키 표면(옛 `GetDynamic`) 위치** → **닫힘.** `store:Of<<T>>(name)`
>   하나로 합쳤고(콜론 메소드 유지),
>   예약 키 충돌은 예약 키 진단 타입 함수가 잡습니다(**[2026-08-26]** 그
>   함수는 8라운드 `H-112`로 `CheckReservedKeys<keyof<T>>`가 됐습니다 —
>   `T`를 통째로 넘기는 옛 배선 `CheckReserved<T>`는 실사용 `T`에서 아예
>   안 돕니다). 애초에 이 항목이
>   섰던 근거(lazy `__index`와의 충돌)는 **lazy 생성 자체가 폐기**되며
>   소멸했습니다(명시적 초기화). 이름도 `store:Of<<T>>(name)` 하나로
>   합쳐졌습니다 — `base/store-plan.md`의 "타입 추론 문제" 절.
>
> **[2026-08-24] M2/M3 마일스톤 경계 문제도 닫혀 있습니다** — 사용자가
> **(a) 순서 교체**(반응형이 M2, 디스패치가 M3)를 선택해 전량 반영됐습니다.
> 결정과 근거는 `archive/question-resolved.md`의 "마일스톤 경계" 절, 새
> 마일스톤 구성은 `archive/v2-initial-implementation/roadmap.md`의 M2 배너.

> **M0 착수를 막던 항목이 전부 해소됐습니다.** `0-Y`(`:Compute(fn)`의
> lazy 핸들 계약)는 열세 번째 세션에, `0-Z`(Attr 이름 소유권)와
> `0-A`(재디스패치 하강 diff)는 열네 번째 세션에, **`0-W`(`Ref` 이중
> 배치 방지)는 2026-08-14 열한 번째 세션에 확정·`base/` 반영 완료** —
> 그래서 이 문서의 "결정 대기" 절은 한동안 비어 있었음(위 두 항목이
> 2026-08-24 순서 교체로 올라오기 전까지). 해소 전 원문과 결론은
> `archive/question-resolved.md`, 뒤집힌 옛 재디스패치 모델은
> `archive/dispatch-hintvalue-model-reversed.md`.
>
> **M0 착수 전 읽을 것**: `base/typing-limits.md`(0-Y가 남긴 구현 규약),
> `base/dispatch-core-plan.md`(0-A/0-Z가 반영된 디스패치 코어 — 열네 번째
> 세션에 `bind-system-plan.md`에서 분리 신설).

### 옛 0절 — 슈거 구현 뒤 확인 문항(2026-09-08 밤, 같은 밤 전부 닫힘)

## 0. [2026-09-08 밤 신설, 같은 밤 회신으로 (a)~(j) 전부 닫힘] 슈거 구현 뒤 확인 문항

**회신(2026-09-08 밤)**: (a) 새 마커 OK(다른 것과 맞춤) · (b) 메소드형 OK · (c) 확인 · (d) 동의 · (e) UB(블래스트 범위 억제가
목적, 고아는 처리 안 함 — `fallback-plan.md` "미해결" 절에 원문) · (f) `Operator` 이름·범위 확정 → **구현됨**(`research/
operator-sugar-plan.md` 머리 배너; And/Or·비교 제외) · (g) 당장 안 함 · (h) UB · (i) 그대로 · (j) 에러(구현됨). 같은 회신으로
새 슈거 둘 채택 — `Context`(`base/context-plan.md`)·`ref:Unwrap()`(`ref-plan.md`). **(k)·(l)도 같은 밤 후속 회신으로 닫힘** —
(k) 불변 확장 안 함(진실 원천 하나, `context-plan.md`), (l) `IfElse`는 컬렉션 계열과 함께 별도 백로그(ROADMAP). 같은 회신의
타입드 `Index` 제안은 실측 결과 지금 솔버로 불가(`typing-limits.md` 8.15) — 백로그. **이 절에 남은 문항 없음.**

사용자 결정("문서화는 뒤로, base에 올릴 순수 슈거를 먼저 간단히 만들어 놓고 다듬기")으로 `Debounce`/`Throttle`·생명주기 훅 셋·
`Fallback`/`Traceback`을 구현해 커밋했다(원문 `session/2026-09-08-04-sugar-implementation.md`). 정본이 이미 답을 가진 건 그대로
옮겼고, 아래 일곱은 정본이 비어 있거나 옛 표기라 메인이 임시로 정했거나 열어 둔 것이다 — 답을 주면 코드·정본을 맞춘다.

- **(a) `Timeout` 마커 이름.** 정본 6절은 2026-08-14에 `__type_timeout`으로 적었는데, 그 뒤 코퍼스가 `H-300`으로 마커를 전부
  `__quad*`(`__quadPreRef`·`__quadEffect`·`__quadState`)로 통일했다. 구현은 관례 쪽인 `__quadTimeout`을 썼다. 옛 표기를 지키려면 이름
  하나만 바꾸면 된다. 권고는 그대로 `__quadTimeout`.
- **(b) `GateHandle`의 호출 모양.** 정본 5-4절은 타입을 `Flush: () -> ()`로 적고 예시는 `h.Value:Flush()`(콜론)로 부른다 — 둘이 안
  맞는다. 구현은 예시와 팩토리(`factory:Flush()`)에 맞춰 메소드형으로 했다. 권고는 메소드형 유지.
- **(c) `MaxTime`의 타이머 수.** 정본 6-1절은 `os.clock()` 차이로 `min(Time, 남은 MaxTime)` 한 타이머를 권했고, 7절 의사코드는 타이머
  둘이다. 구현은 둘로 했다 — base가 시계를 읽으면 mock의 가상 시간과 어긋나 스펙이 결정론을 잃는다(정본 11절이 mock 가상 시계를
  quad-base 배치의 근거로 든 것과 같은 결). 6-1 형태로 가려면 시계도 주입 op가 돼야 한다(`now()` — 정본이 "주입 대상 아님"으로
  닫았던 것). 권고는 둘 유지(표면 불변, 실측 병목이 나오면 그때).
- **(d) `Flush`와 `Trailing=false`.** 정본 5-4절 문장은 "보류분이 있으면 즉시 커밋"이고 7절 옛 코드는 `pending and trailing` 가드가
  있었다(그 가드가 `H-32`의 영구 no-op 결함 자리). 구현은 가드 없이 — 사용자가 명시적으로 `Flush`를 불렀으면 `Trailing=false`
  게이트라도 보류분을 통과시킨다. 권고는 무조건 통과 유지.
- **(e) `Fallback`/`Traceback`의 부분 트리 미회수(정본 "미해결" 절, `H-26`).** 실패 지점 앞에 완성된 형제 Instance가 gcconn 때문에
  세션 끝까지 안 죽는 문제. 갈래는 정본 그대로 셋 — (1) `Dispatch.drive`가 이번 construction의 생성물을 쌓고 실패 시 역순
  `Destroy`(정상 경로에도 부기 비용, 중첩 경계 문제), (2) gcconn 자기순환 재설계(규모 큼), (3) UB로 명문화 + "생성 전에 검증부터"
  권고. 권고는 (3) — 지금 실측된 사례가 없고, 관측된 문제에만 구조를 쓴다는 `conventions.md` 설계 원칙에 맞는다. 코드는 아무 갈래도 안 담았다.
- **(f) `Operator` 콤비네이터 — 이 구간에서 뺀 이유.** `research/operator-sugar-plan.md`가 네임스페이스 이름(`Operator`/`Op`/`Ops`,
  외부 리서치는 `Operator` 권고)과 포함 범위(산술·논리는 명확, 비트·비교·`Sub`/`Div`는 선례 없음, `Clamp`/`Min`/`Max`·`Alternative`는
  선례 강함)를 열어 두고 있다. 이름과 범위를 주면 같은 방식으로 얹는다.
- **(g) 렌더 스텝 op 예약.** 사용자 제기(2026-09-08 밤): 시간 op를 base 주입 경로에 두는 이상 렌더 스텝/애니메이션 리퀘스트도 같은
  경로가 맞다는 의견. 메인 동의 — 다만 지금 쓰는 곳이 없어(Debounce/Throttle은 타이머만) 심지 않았고, 이름(`onStep(fn) -> cancel`류)·
  계약(델타 시간 인자 단위, 프레임 안 호출 순서 보장 여부, 취소 뒤 미발화)을 정본에 **예약 슬롯**으로만 적어 두자는 것이 권고.
  `spring`은 그 위의 별도 패키지. 정하면 `architecture.md` EngineOps 줄에 적는다.
- **(h)~(j) [같은 밤 round9 리뷰가 낸 셋 — 평문 전문은 `qa-request/post-implementation-review-round9.md` §4].** (h) 창 끝 flush
  도중 하류가 같은 게이트의 `Cancel`/`Flush`를 부르면 상위 커밋이 그걸 모르고 창을 다시 연다 — 세대 카운터 필드(새 필드) vs UB
  명문화, 권고 UB. (i) idle에서 leading 통과 도중 하류가 상류를 `:Set`하면 같은 파동에서 두 번 통과한다(정본 7절 의사코드도 같은
  순서, 스펙 10절이 고정) — 그대로 vs 창을 먼저 열고 통과, 권고 그대로. (j) 같은 `Handle` Ref로 팩토리를 두 번 `:Apply`하면 둘째가
  조용히 덮어쓴다 — 둘째 Apply에서 에러 vs 문서만 vs 그대로, 권고 에러.

### 옛 1절 포인터

## 1. 용어 정리 — 전부 해소됨(2026-09-15·16) — 원문은 archive

**[2026-09-27 정리 — round13 E74]** 이 절의 항목 일곱(`Slot`·`Owned`/`OwnsElements`·`canExecute`·`hintValue`/`nextValue`·`Brand`·`Tag`/`Added`/`Removed`/`Merged`·`Attr`/`AttrKey`)은 2026-09-15·16에 전부 해소됐는데(결정 원문 `session/2026-09-16-01-d-typefunction-measurement.md` §5, `OwnsElements`는 그 전날) 절 제목만 "진행 중"으로 남아 있었다. 원문은 이 문서 규약대로 `archive/question-resolved.md`의 "용어 정리 절 전체" 절로 옮겼다 — 여기 남은 열린 용어 항목은 없다(`todos.md` 2번이 "열린 항목은 `question.md` 1번"이라 가리키는 것의 답은 "없음").

### 옛 2절의 닫힌 항목

- **[2026-09-07] 핸드오버 전체 코드 리뷰 문항(round1 §4)** — Q1~Q21 **전부 닫힘**(회신 1~4차; 상태는 그 표의 각 행). 여기 남은 것 없음.
- **[2026-09-07 신설] 구현 뒤 리뷰 round3 문항** — `qa-request/post-implementation-review-round3.md` §4가 소스. Q22~Q24는 회신 4차,
  **Q25·Q26·Q27은 2026-09-08 회신으로 전부 닫힘**(§12 — Q25는 값 비교 모델·`Tween.Dedup` 필드, `H-478`). 여기 남은 것 없음.
- **[2026-09-07 신설, 같은 날 밤 회신 반영] 소스 구조 재편** — `archive/surveys/2026-09-07-source-layout-plan.md`가 소스(각 절
  머리 `[결정]` 줄 + 9절 상태). 회신으로 닫힌 것: 1절 Slot 분할·3절 Tag 유니언·4절 패밀리 접기(5·6·7절 포함)·
  2절 Tween(권고 (c) 대신 **통째 이동 (b)**)·10-1 Brand→quad-types·10-2 마커 전면화·10-3 quad-types 재배치.
  **[2026-09-08 회신으로 전부 닫힘]** (1) 8절 옛 `Attribute` → `Attr` 축약 — **한다**(+`AttrKey`·엔진 op `setAttr`),
  반영 `66281ab`. (2) 10-4 D 정적 굽기 — **지금 안 함, 백로그 아닌 리서치 대상**(그 절 `[결정]`). (3) round3 §4 **Q27** — 등록
  op 기각, 모듈 최상위 `is<Brand>` 필드가 계약(round3 §12). 이 항목에 남은 사용자 몫 없음(마커 이름 10-2도 2026-09-07 밤 확인 완료).
- **[2026-09-08 밤 신설, 같은 밤 실기기 실측으로 닫힘 — (c) mock 충실도, round8 §15] Q47 엔진 Tween 슬롯의 Instance 회수.** `Property` 핸들러의 strong 트윈 슬롯이
  mock에선 Instance를 되참조해(Luau weak-key는 에페메론이 아님) `Destroy` 뒤에도 안 회수됨(10,000회 30MB). 실물 Tween userdata는
  Lua 참조가 아닐 가능성이 커 (a) Q41·Q42와 함께 Studio 실측 권고 / (b) `onDestroying`에서 슬롯 비우기 / (c) mock 충실도 문제로 닫기.
- **[2026-09-08 저녁 신설, 같은 밤 회신으로 전부 닫힘 — round8 §17] Q43~Q46.** Q43 스파이크 → `H-508` 오버로드 교집합, Q44 (a) 문서화, Q45 (c) 재노출 안 함(직접 `require(D)`), Q46 (a) `Of` 주석 필수 문서화. Q43 무인자 `Store()`가 strict TypeError(스펙도 `any` 우회 중 —
  (a) 생성자 오버로드 교차 스파이크 권고 / (b) 무인자 폐기 / (c) 그대로); Q44 `{ Instance }` 변수를 `D.Frame(kids)`에 통째로 못 넘김(인덱서
  불변 — (a) 관용구 셋 문서화 권고 / (b) `| { E }` 팔 추가+솔버 비용 재측정); Q45 릴리즈 사용자용 타입 표면 — quad-roblox가 컴포넌트 경계 별칭
  (`Into<Class>`·`<Class>Param`·`<Class>Modifier`·`<Class>RefMarker`·`Field<T>`)을 재노출하지 않음((a) 선별 재노출 + 8.12 실측 권고 / (b)
  `quad-roblox-types` 지금 / (c) 백로그); Q46 `store:Of(name)` 무주석 `Source<any>`((a) 문서화 권고 / (b) 새 인자). 평문 전문은
  `qa-request/post-implementation-review-round8.md` §11; 한계 기록은 `typing-limits.md` 8.13.
- **[2026-09-08 저녁 신설, 같은 밤 실측 뒤 회신으로 닫힘 — UB, round8 §16] Q42 Instance를 매개로 한 Slot 순환.** 실물: 엔진이 "own parent / circular reference"로 raise, 요소는 들어가고 부기는 안 된 반쪽 상태(`Remove(1)`로 복구 가능). `drive(F, { s })` 뒤 `s:Add(F)`는 `H-500`의
  Slot–Slot 체인 검사가 안 돌아 mock에선 통과한다(K-7 실측). 실엔진은 `F.Parent = F`의 "circular reference"를 `EngineOps.luau`
  줄에서 낼 것. 갈래: (a) Q41과 함께 Studio 실측 뒤 판단(권고) / (b) 지금 마운트 타깃 조상 체인 게이트(엔진 순회, 새 경로) / (c) UB.
- **[2026-09-08 저녁 신설, 같은 밤 실측 뒤 회신으로 닫힘 — (c) 그대로·재개봉 금지, round8 §16] Q41 `D.New(className)`의 클래스 이름 오타.** 실물 문구 `Unable to create an Instance of type "Frmae"`(클래스 이름을 말함, 스택은 생성물). `D.New`는 생성기 범위 밖 클래스의 탈출구라
  타입 방어가 없는 유일한 생성 경로다. `D.New("Frmae")` 같은 문자열 오타는 생성된 `D/init.luau`의 `Instance.new`가 엔진 에러를 내며
  생성물 내부 줄을 blame할 것으로 보이는데, CLI mock은 아무 이름이나 받아 실측하지 못했다. 갈래: (a) Studio 실측 뒤 판단(권고 —
  HUMAN_TODO 실측 항목) / (b) 지금 생성기 템플릿에서 `pcall` 재던지기 / (c) 안 함(엔진 메시지가 이름을 말해줌). 평문 전문은
  `qa-request/post-implementation-review-round8.md` §8.
- **[2026-09-08 오후 신설, 같은 날 회신으로 닫힘 — round8 §6, (a)] Q40 `Slot:Clear`의 창 안 파괴.** `H-479`로 `Clear`가 Blocker 창 하나 안에서
  요소를 파괴하게 돼, 파괴 도중 raise(요소 cleanup 던짐·quad 밖 `Destroy`된 타깃의 `nativeRemove`·소유권 불변식 에러 —
  셋 다 UB·내부 버그 범주)면 게이트가 남아 그 Slot의 레이아웃이 동결된다. List의 KeyGone 패스가 이미 같은 모양을 수용하고
  있어 메인 권고는 (a) 그대로 + `slot-plan.md`에 한 줄 명시; (b) 파괴만 창 밖으로(열 줄 패치); (c) 옛 요소별 recompute
  복귀(비권장). 평문 전문은 `qa-request/post-implementation-review-round8.md` §4.
- **[2026-09-08 오전 신설, 같은 날 오후 회신으로 전부 닫힘 — round7 §6]** 사용자 반입 RFC 다섯의 판정 문항(`qa-request/post-implementation-review-round7.md` §4): Q37 (a) `keyType` 반영(`H-484`), Q38 백로그(ROADMAP), Q39는 폴더별 README 분리만 하고 루트 README는 백로그·나머지 둘은 안 함. 여기 남은 것 없음. 원문: **Q37** `getHandler` 키 타입 버킷을 핸들러 계약의 어떤 필드로 선언하나(권고 (a) `keyType: "number" | "string"?`, 없으면 모든 버킷 — 방향은 사용자가 이미 승인, 이름·모양만 남음; 실측 절감은 `D.Frame` 한 번에 5µs 안팎). **Q38** `Slot:List` 대량 재정렬 O(N²)(1000개 역순 82ms, 100개 1ms) — `rawPermute` 설계를 지금 열 것인가 백로그인가(권고 (a) 백로그). **Q39** 문서 거버넌스 넷 — README `qa-request/`·`audit/` 행 비대(한 셀 16,636자, 권고: 한다), `base/` 계약서화(권고: 반대), `session-summary.md` 분할(권고: 안 함), 루트 `README.md` 신설(권고: 지금 안 함). 적용된 다섯(`H-479`~`H-483`)엔 사용자 몫 없음.
- **`Operator` 콤비네이터 슈가 네임스페이스 이름+포함 범위 — [2026-09-08 닫힘, 2026-09-27 정리]** 이름 `Operator`·범위 사용자 확정 뒤 구현됨(`quad-base/src/Operator.luau`, 0절 (f), `research/operator-sugar-plan.md` 머리 배너). 이 항목은 확정 뒤에도 "최종 확정은 사용자 몫"이라 적힌 채 남아 있었다 — 원문은 `archive/question-resolved.md`로.
- **[2026-09-17 저녁 신설 — round11 §4 `Q59`~`Q63`, 원장 `qa-request/post-implementation-review-round11.md` §4가 소스(평문 한 문단씩)]** 결함 탐사 3차 문항 다섯: ~~Q59 `bindLifetime`이 부르는 값 쪽 밑줄 메소드 셋(`_assertBindable`/`_catchUp`/`_bindDestroying`)의 이름 — 예외로 두기(권고 (a)) / 밑줄 없는 이름으로 BREAKING~~ **[2026-09-18 닫힘 — 구조 수정]** 생명주기 넷은 quad-base가 구현, 백엔드는 hold op 넷(`holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`)만(원장 Q59 닫힘 문단); ~~Q60 정적 자식 State가 거부될 값을 받으면 옛 점유자가 거부 **전에** 내려가는 것 — 캐비엇으로 닫기(권고 (a)) / 핸들러 계약에 검증 단계(새 메커니즘)~~ **[2026-09-18 (a) 닫힘]**; ~~Q61 폐기된 `OwnsElements = false` Slot의 원소가 소유권에 갇혀 재사용·dispose 불가 — 그 분기에서도 `releaseOwner`+배열 비움(권고 (가)) / 문서 정정 / 버릴 때 에러~~ **[2026-09-18 닫힘 — 파괴 경로만 release+비움, Extract는 그대로]**; ~~Q62 Slot 원소 경로에 정적 자리(`H-545`)와 같은 순환 가드가 없음 — 백엔드 술어 추가(BREAKING) / 순서 변경 / UB 문서화(권고 (c))~~ **[2026-09-18 (c) 닫힘 — Q42 재확인, core/06 캐비엇]**; ~~Q63 한 번 던진 Effect가 영영 해제 불가(강한 레지스트리 누수)·Observer는 던져도 계속 발화 — 문서만 / `Unsubscribe`만 `_running` 무시하고 통과(권고 (b)) / 세대 스탬프~~ **[2026-09-18 (b) 닫힘]**. **[같은 밤 code-review 추가]** ~~Q64 Claim 1패스의 `isClaimed` 게이트(자식이 이미 quad 소유일 때 루트와 앞선 형제가 claim된 채 남음) — 두고 문서(권고 (a)) / mock isClaimed 의미 변경 + 게이트 / 새 op~~ **[2026-09-18 (b) 닫힘 — blast 실측 뒤 사용자가 권고를 뒤집음]**; ~~Q65 핸들러 교체(plain ↔ State·`None` 경유) 때 Tween 기록이 지워져 다음 Tween이 스냅 — 새 동작 채택·문서화(권고 (a)) / 옛 동작 복원(retractor 계약 BREAKING)~~ **[2026-09-18 닫힘 — 넓은 수정: 기록은 (inst, k)에 인스턴스 수명 동안, 철거는 진행 중 트윈만 Cancel 뒤 true]**. **[같은 밤 3차 탐사 추가]** ~~Q66 `OnChange("Parent")` 콜백·`AncestryChanged.parent` 타입이 `Instance`인데 엔진은 nil — 캐비엇 / `Instance?`(타입 BREAKING, 권고 (b)) / 예외 목록+게이트~~ **[2026-09-18 (b) 닫힘]**; ~~Q67 props 테이블 재사용이 훅을 조용히 소진 — 캐비엇(권고 (a)) / 센티널 재drive 거부~~ **[2026-09-18 (a) 닫힘 — 재사용은 UB]**; ~~Q68 yield하는 Effect fn 중 leaf가 죽으면 그 뒤 cleanup 영구 누수 — 문서만 / fn 반환 뒤 `_dying`이면 즉시 소진(권고 (b)) / 즉시 에러~~ **[2026-09-18 (b) 확장 닫힘 — 실행 불가면 즉시 소진]**; ~~Q69 quad가 붙이지 않은 태그를 마지막 자리가 물러날 때 뗌(입양·사본 트리) — 캐비엇(권고 (a)) / "밖의 이름" 기억 / Claim 때 흡수~~ **[2026-09-18 (a) 닫힘]**. **→ round11 §4 열하나 전부 닫힘(2026-09-18).**
- ~~**[2026-09-21 저녁 신설 — round12 §4 `Q71`·`Q72`, 원장 `qa-request/post-implementation-review-round12.md` 머리 배너가 소스(평문 한 문단씩)]** Gemini 합본 판정에서 나온 문항 둘: Q71 파괴 경로는 프로퍼티 체인의 retractor를 돌리지 않아 콜백을 실은 트윈이 파괴된 인스턴스 위에서 끝까지 돌고 `Completed`가 그대로 불린다(숏핸드 자식 `nil` 교체만 `retractFrom`을 먼저 돌려 `Cancelled`) — (a) 문서만(권고: `Destroy`는 되돌리기를 거치지 않는다는 기존 규칙 그대로, 인자 없는 콜백이라 고정은 없음) / (b) 레코드마다 `Destroying`을 구독해 `Cancel` + `Cancelled`(새 메커니즘) / (c) `Completed` 발화 전 인스턴스 생존 검사(새 게이트). Q72 `effect:Unsubscribe()`가 소비한 cleanup 안에서 다시 `:Unsubscribe()`를 부르면 이중 해제 에러 — (a) 문서만(권고: cleanup 안 해제는 재실행·죽음·자리 교체 소진에서만 뜻이 있다고 core/05에 한 줄) / (b) `_cleanupRunning` 중엔 두 번째 해제를 no-op(기존 플래그 재사용이지만 약한 구독 핸들의 cleanup 안 강한 해제도 조용히 통과하는 부수 효과) / (c) cleanup에 소비 이유 인자(새 표면).~~ **[같은 날 저녁 닫힘 — 사용자 회신]** Q71: 되돌리진 않되 **무시** — 사용자 *"isClaimed 를 통해서 완료 이후 inst 가 gcconn 이 disconnected 상태라면 무시할 수 있다고 봐. claim 이 안 돌면 tween 자체를 못 굴려서, 판정대상으로 쓸 수 있어 … defer 이여도 gcconn 판정 자체는 싱크로 돌거야"* → `Completed` 연결이 `Backend.isClaimed(tween.Instance)`가 거짓이면 콜백을 안 부른다(`H-594`). Q72: (a) 권고대로 core/05 한 줄. 원장 배너 닫힘 문단이 소스.
- **[2026-09-21 밤 신설 — `research/upward-flow-plan.md` 7절이 소스]** 되돌아오는 흐름(엔진이 바꾼 값을 상태로 올리기 — docs-review 1-4 대체) 문항 다섯: (1) ~~같은 값 재대입 무발화 실측~~(닫힘 — 2026-09-10 `audit/studio-docs-2026-09-10.md` A절에 이미 있었다, 감사자 발견) / (2) ~~`Bind` 채택 여부와 모양~~(**닫힘 — 사용자 결정: 순수 슈거, `Text = src`(in) + `Bind("Text", src)`(out, `OnChange` 위 슈거) 나란히; 이름은 탐사 뒤 — research 8절: 외부자·내부자 둘 다 **`Out`** 1순위(`Writeback` 2순위, `Bind`는 `bindLifetime` 어휘 충돌 + 양방향 오해로 비권고), 걸러내기는 `v ~= src:Get()`일 때만 `Set`; **같은 날 밤 닫힘 — 사용자 *"Out 권고대로"*, 구현 커밋**) / (3) ~~문서 위치~~(**닫힘 — 사용자: 분리, 05 뒤 새 06장 `06-flowing-back.md`, 07~21 재번호; 탐사 원문 `archive/surveys/2026-09-21-upward-chapter-placement.md`**) / (4) ~~web-vs-quad 다섯 흡수~~(**닫힘 — 사용자 권고대로 (a) 오버뷰 `03-from-the-web.md`**) / (5) ~~루트 `-ignoreme` 원본 여덟 삭제~~(**닫힘 — 사용자 승인, sonnet 확인 뒤 삭제**). **문항 다섯 전부 닫힘.**
- ~~**[2026-09-22 신설 — `base/error-id-plan.md` 7절이 소스]** 에러 식별자 문항 다섯~~ **[같은 날 닫힘 — 다섯 다 권고대로: (C) 순번·접두·문서 레지스트리·안정 계약·한 번에; 롤아웃 진행 중]**(사용자가 `Quad10000`식 번호 공간을 제안하며 갈래를 요청): (1) 번호 공간 — (A) 카테고리 밴드 `Quad1203` / (B) 문자열 카테고리 `Q-SLOT-012` / (C) 평평한 순번 + 레지스트리 `Quad0042`(권고 — 주어가 이미 층을 말해 주고, 코드 이동에 번호가 안 낡음) / (2) 자리 — 접두(권고) / 접미 / (3) 레지스트리 — 문서 페이지가 곧 레지스트리(권고) / 별도 TSV / (4) ID 계약 — 분기 금지 유지 / ID는 안정 계약·분기 허용(권고) / (5) 롤아웃 — 222곳 한 번에(권고) / 새 코드부터.
- **[2026-09-16 밤 신설 — round10 §4 `Q48`~`Q54`; [2026-09-17 전부 해소 — 원장 §10, `session/2026-09-17-01-round10-batch-reply.md`]** 다각 탐사 문항(§4 일곱 + §7·§8·§9 넷 = 열하나): ~~Q48 정적 자식 자리 소유권 부기 부재~~(**[해소 2026-09-17]** (a) — 레지스트리 하나, `q.Bookkeeping.claimOwnerAt`/`releaseOwner` 공개), ~~Q49 Claim 클래스 불일치 검사~~(**[해소 2026-09-17]** (a) `nativeFindChild` 셋째 인자), ~~Q50 `_recompute` 재진입·순환 가드~~(**[해소 2026-09-17]** (a) `_computing` 플래그), ~~Q51 Effect cleanup 안 `Set`~~(**[해소 2026-09-17]** (a) `_pending` 하강을 fn 직전으로), ~~Q52 마운트 walk 중 조상 CRUD~~(**[해소 2026-09-17]** (a) `_materializing` 가드), ~~Q53 Property Tween 미취소~~(**[해소 2026-09-17]** (a) Tween 체인 retractor), ~~Q54 교차 인스턴스 메시지~~(**[해소 2026-09-17]** 구절 추가), ~~Q55 Debounce 타이머 경로의 Time 읽기 실패 복구~~(**[해소 2026-09-17]** (b) 신호 진입 캐시), **~~Q56 `bindLifetime` 커밋 뒤 사용자 코드 실패로 반쪽 바인딩~~(**[해소 2026-09-17]** (b) UB 문서화), **~~Q57 `OnDestroyed`가 State 자리 교체 때 살아 있는 인스턴스에서 발화~~(**[해소 2026-09-17]** 사용자 제안 — cleanup `dying` 인자), **~~Q58 두 정책~~(**[해소 2026-09-17]** (가) 안 좁힘·캐비엇, (나) `Event`/`OnChange` NORMAL − 1). Q48엔 숏핸드 관리 자식(세 번째 자리), Q53엔 슬롯 미청소 증상이 보강됨(round10 §7). 본문은 `qa-request/post-implementation-review-round10.md` §4.
- **[해소 2026-09-16 — (a) 대칭 게이트, 사용자 "권고대로"; `InstanceChild.luau` process 머리에 `isClaimed` 거부, `spec.handlers` 11, 레퍼런스 roblox/02·CHANGELOG·claim-plan 14번] 정적 자식 자리 `D.Frame { foreign }`에는 같은 게이트가 없다.** 상황: Slot은 이제 미claim 요소를 거부하는데, quad-roblox의 `Handlers/InstanceChild.luau`는 숫자 키 자리의 raw Instance를 `isInst`만 보고 `Parent`를 잡고 길이 부기를 만든다 — `nativeClaim`도 `isClaimed`도 안 부른다(`spec.handlers`가 raw `Instance.new` 자식으로 성공을 단언). 무엇이 막히나: 사용자가 `slot:Add(foreign)`은 에러, `D.Frame { foreign }`은 통과라는 비대칭을 보고 정적 자리로 옮겨 "고치면" 옛 stale 동작(밖에서 Destroy되면 부기가 시체를 가리킴)이 그대로 돌아온다. 갈래: (a) `InstanceChild`에도 `isClaimed` 게이트(정적 자리도 미claim 거부 — 표면 변경, Slot과 대칭) / (b) 정적 자리는 공인 adoption 경로로 두고 문서에 "정적 자리는 소유 검사가 없다, 죽음 추적도 없다"를 명시 / (c) 그대로. 메인 권고 (a) — 오늘 결정의 논거(소유는 명시적, 조용한 stale 금지)가 자리와 무관하게 성립하고 BREAKING 허용 주간 안이다. `v1-compat-plan.md` 7-3이 두 경로를 나란히 물었던 문항이라 Slot만 닫힌 상태.
- **[해소 2026-09-16 — (b) 사용자 결정: 미claim이면 `Add`에서 에러, 자동 claim은 마법("명시적으로 claim 안 한게 다른 경로로 claim 될 수 있다는거고, 마법 아님?"); 판정 술어는 quad-roblox의 gchold 유무("gchold 같은게 있는 경우가 claim 된 판정처럼 되는거지?" — 맞음)를 백엔드 계약 op 하나로 노출, mock은 항상 참(**[2026-09-18 Q64 정정]** 이제 mock은 `Data.claimed` 플래그 — `Instance.new`는 태어날 때 claim, `Instance.foreign`은 아님). 구현 완료 같은 날 — `isClaimed` op(quad-types·quad-base 스텁·quad-roblox·mock)·`Slot/Elements.luau` 게이트·`spec.slot` 22·레퍼런스 core/06·extend/01·CHANGELOG BREAKING; `claim-plan.md` 14번] Slot이 quad 밖에서 만들어진 임의 Instance를 받을 수 있는가**
  (2026-08-06 추가) — v1 compat 등에서 넘어온 foreign
  Instance를 동적 배열 원소로 받을 수 있는지, retract 시 어떻게 다루는지.
  **Slot 코어 구현(M6) 시점에 확인** — `research/v1-compat-plan.md` 7-3.
  **[2026-09-16 정리 — 옛 본문 압축]** 2026-09-03 시점 현황(요소 판정이 `isInst`뿐이라 foreign도 조용히 들어감, 단 미claim 요소엔
  `bindLifetime`이 fail-fast(`H-290`)라 leaf 바인딩 불가)과 갈래 셋((a) `Add` 때 자동 claim — 옛 메인 권고 / (b) 미claim이면 `Add` 에러 /
  (c) 현행)은 **(b)로 닫혔다** — (a)는 마법이라 기각, (c)는 조용히 stale해지는 유일한 갈래. 지금의 사실은 `Slot/Elements.luau`의
  `isClaimed` 게이트와 `claim-plan.md` 14번이 소스, 논의 원문은 `session/2026-09-16-01-d-typefunction-measurement.md` §5.

### 옛 2절 v1 compat 불릿(2026-10-15 정정 전 원문 — v2→v1 단방향 서술은 2026-09-10에 양방향으로 뒤집힘)

- **v1 하위호환(compat) 레이어 — `quad-roblox-v1-compat`** —
  `research/v1-compat-plan.md`(신규, 2026-08-06, 두 차례 후속 논의로 수렴).
  방향 확정: v1을 그대로 병행 실행 + 경계에서만 `state:Observer()`(lazy
  포기)로 값을 리졸브해 v1 프로퍼티에 재대입하는 브리지, v2→v1 단방향만
  (양방향 불필요로 확정), 패키지명 `quad-roblox-v1-compat`으로 확정(소스
  트리에 세 번째 패키지로 추가될 예정). v2-in-v1/v1-in-v2 두 임베딩 방향
  모두 기술적 근거와 안전 규칙까지 정리됐으나(문서 7번), **Slot이 foreign
  Instance를 어떻게 다루는지만 Slot 코어 구현 시점까지 결정 불가로 남음**
  — **[2026-09-03 현황]** Slot 코어가 편입돼 그 시점이 왔다: 사실관계는
  바로 아래 "Slot이 quad 밖에서 만들어진 임의 Instance를 받을 수 있는가"
  항목의 현황 갱신이 소스(**[2026-09-16 닫힘]** `isClaimed` 게이트로 미claim `Add` 거부 — 옛 "받아짐 / `H-293` 안전성 구멍" 요약은 2026-09-03 시점). (옛 괄호 참조
  *"여러 Slot이 형제로 섞일 때 순서 보장 항목과 같은 시점"*은 2026-08-09에
  설계로 닫힌 항목을 가리키던 stale 포인터라 지움 — 감사 3라운드.)
  그 외 §8의 세부 항목(v1 자기 루트의 `Destroying` 자기청소 여부,
  `registerClass` 체이닝 기능 브릿징 필요성)은 문서 자체가 "지금 결정
  불필요"로 표시해둠 — 위 Slot 항목과 별도로, 실제 compat 레이어 구현
  시점에 `research/v1-compat-plan.md` §8을 다시 열어 확인.

### 옛 3절 D10·D9

- **~~D10~~ [2026-09-11 닫힘 — 사용자: "List 와 같이 Item, UD 를 Single 에 두는거 내 처음 목적이 맞았음. 인자 같고 타입 인자 같고 … 빠질것만 빠져야하는데, Item 도 실수로 빠진게 맞는듯"]** → (a) 반영. identity 슈거를 별도 오버로드 팔로 두는 것은 신 솔버가 제네릭 팔을 못 골라 기각(`typing-limits.md` 8.19) — 한 시그니처, 오용은 런타임 가드.
- **~~D9~~ [2026-09-10 밤 닫힘 — 사용자: "기다릴 필요는 있는듯. 아니면 WaitForChild 를 하거나. … 실제 클라이언트는 코드들을 동적으로 네트워크로 복제하고 있는 상황이라, 뭐가 먼저 실행될지 몰라서 진짜 없어서 에러 날 수 있긴 해"] → 진입점에 `game.Loaded:Wait()` 한 줄 + 접힘에 실측 근거(편집자 반영 중). D4(custom.css)도 같은 회신으로 닫힘("확실히 끝났어").

### 옛 4절 — round13 사용자 문항 포인터(2026-10-15 정리 전 원문)

## 4. [2026-09-26 밤 신설] 자율 수집 루프 round13 — 사용자 문항 포인터

**[2026-10-12 저녁 기준 열린 것]** round14 원장의 코어 문항은 2026-10-13에 전부 닫혔다(`Q186`·`Q187`·Q154 불명 셋 — 그 원장 끝 문단들), 그리고 킷 쪽 결정은 `research/consumer-kits-plan.md` 5절.

**[2026-10-01 이관]** round13의 남은 문항은 **`qa-request/post-implementation-review-round14.md`**로 옮겼다(사용자 지시 — round13이 방대해짐). 처리 전에 프로젝트 전체 원칙 감사(`audit/round14-principle-audit/`)와 문항별 재검토를 먼저 돈다. 아래는 round13 시절 서술이다.

문항 본문은 **`qa-request/post-implementation-review-round13.md` §4**(`Q73`부터 — 끝 번호는 그 파일이 소스)에 평문 한 문단씩 있고, **읽기 전에 그 파일 §0을 먼저 볼 것** — 문항마다 한 줄 상황·심각도·메인 권고·프로토타입 유무·실기기 필요 여부·같이 정할 문항을 표로, 그리고 답할 순서 제안인 **결정 묶음**과 문항 사이 충돌·의존을 거기 한 곳에만 둔다(**[2026-09-27 감사 7라운드]** 예전엔 이 절이 묶음 구성과 프로토타입 목록을 복제해 두었다가 §0이 갱신될 때 따라오지 못해 갈라졌다 — 이제 여기엔 포인터만). 결정 재료 실측은 `audit/round13-*`(색인은 `audit/README.md`), 처방 초안은 `audit/round13-drafts-2026-09-27/`. 실기기 확인 후보는 HUMAN_TODO **I**(초안 표 `audit/round13-drafts-2026-09-27/human-todo-realdevice-draft.md`)가 소스. **[2026-09-27 11:05]** 루프는 사용자 지시로 종료됐다 — 탐사 문항은 더 늘지 않고(`Q157`까지 — **[2026-09-30]** 반영 중 실측으로 `Q158` 하나 추가, 끝 번호는 원장이 소스), 다음은 §0 결정 묶음 순서의 대화형 회신.
