# 2026-08-21-02 — 구현 전 QA 5라운드(문항지 → 회신 → 1차 처리), `Gate`/에포크 리서치 신설

**요약**: 사용자 요청으로 **QA 5라운드 문항지(205문항)** 를 만들고, 같은
세션에 회신을 받아 **1차 처리까지** 끝냈다. 즉시 반영 14건, 되물은 것 7건,
그리고 **새 research 문서 둘**(`gate-primitive.md`,
`state-epoch-validation.md`)이 나왔다. 처리 결과의 소스는
`qa-request/pre-implementation-qa-round5-followup.md`.

## 1. 5라운드가 왜 생겼나 — 4라운드 처리 때의 판단을 뒤집음

4라운드 종결 시점엔 사용자 지시(*"이후 stale 만 잡는것으로 끝낼 수
있어보임"*)로 **5라운드를 안 만들기로** 했고 그 문장이 세 곳
(`todos.md` 00번, `README.md` qa-request 행, 4라운드 followup H-7)에
적혀 있었다. 같은 날 사용자가 5라운드를 요청 — *"4차에서 예로 넘어갔던건
스킵하고, 새로운 부분들이나 다른 깊은 부분을 예가 나와야 정상인 질문들을
쌓아보자."* → 세 곳 전부 정정하고 문항지를 신설했다.

**범위를 셋으로 좁힌 게 이번 라운드의 설계**: (1) 4라운드에 문항이 아예
없던 영역(`project-setup-plan.md`/`quad-types-plan.md`, 그리고 **문서가
아니라 실제 커밋된 M1 코드**), (2) 4라운드 회신 **이후** 확정된 것
(`Detach`/`_detached`/`KeyGone`/`Owned`/`attachSlot` 분해), (3) 큰 문서의
심화(예: `debounce-throttle-plan.md`는 1100줄인데 4라운드 문항이 9개뿐이었음).

## 2. 문항지 작성 중 이미 잡힌 것

문항을 쓰는 과정 자체가 감사가 됐다:

- **`EF-3`** — 4라운드 followup이 "반영 완료"로 적은 `E-10`(dedup 대칭)이
  `effect-plan.md`에 **실제로는 안 들어가 있었다**. → 일반 교훈으로
  `CR-1`("followup 표를 신뢰 소스로 쓰면 안 된다, 소스는 `base/` 본문")을
  문항화했고, 사용자가 "예"로 확인해 이번에 실제로 반영했다.
- **`DE-9`** — `KeyGone` 소멸 루프가 새 값을 반환받으면 `settle`의 교체
  분기로 들어가 `rawAdd(self, result, 0)`(범위 밖 인덱스)로 터진다.
- **`IM-1`** — `architecture.md`는 "지금은 `New()` 미노출 싱글톤"이라는데
  실제 코드는 `module.New = New` + `return New()`.
- **`CR-2`/`CR-9`** — `Tween:Map` vs `Mapped` 이름과 `isBoundAlive`의 세 번째
  분기가 **결정이 필요한데 어느 추적 목록에도 없었다.**
- **`DC-9`** — Blocker 게이팅이 `recompute`를 O(N²)→O(N)으로 줄였는데
  `setOffsetSource`의 즉시 계산이 그 자체로 O(N²)라 상쇄된다.

## 3. 회신으로 확정된 것 (즉시 반영)

- **`slot._detached`는 lazy** — 모든 Slot이 빈 테이블을 미리 갖지 않는다
  (사용자: *"테이블 생성 비용을 모든 slot 이 가져야하나는 의문 … if 확인으로
  nil 이면 스킵이 훨씬 싸게 먹히지 않는가?"*). `getDetached(slot)` getOrCreate.
- **`prev` 없이 `Detach`를 반환해도 nop** — 사용자가 prev 유무를 추적할
  의무 없음.
- **`KeyGone`엔 `nil`/`None`/`Detach`만** — prev도 새 값도 error(*"KeyGone 을
  받은 요소는 오직 … 캐싱 이외의 새로운 마운트나 생성을 거부한다"*).
- **⭐ `Owned = false`에서 `Detach`는 `_detached`에 안 들어간다** — 남의 것에
  소유권을 유지하는 건 모순이라 `rawUnmount`로 처리하고 다음 `prev`는 `nil`.
  부수로 unowned에선 `Detach`와 `nil`이 같은 동작이 되고 `_detachCleanup`의
  `_owned` 분기가 도달 불가가 되어 삭제됐다.
- **조상이 죽으면 unowned 요소도 엔진 재귀 파괴로 같이 죽는다** — `Owned=false`가
  약속하는 건 "quad가 안 죽인다"뿐. 이 계약이 코퍼스에 없어서 신설.
- **`groupClaimKeys` 키 = `(inst, groupValue) → k`**, `nameClaims`보다 위치
  claim이 먼저. `Frame { a, a }` 갭이 이걸로 닫힘.
- **`Tween<T>:Mapped`** 확정(`-ed` 관례).
- **⭐ "게이팅 먼저"** — M2가 M3의 `Blocker`에 의존하던 순서 문제를 로드맵
  순서 유지가 아니라 **앞당기는 쪽**으로 결정. 단 앞당기는 대상이 `Blocker`가
  아니라 그 아래 공용 `Gate` 노드로 바뀌었다(아래 4절).

## 4. 새로 열린 것 — research 문서 둘

- **`research/gate-primitive.md`** — `DT-4`에서 사용자가 정리: 시간 기반
  게이트를 공개 `Blocker` API 위에 못 얹는 이유가 **순서 보존**이다
  (*"이 옵저버의 emit 이 먼저이냐 후행 Blocker 로 생성된 요소의 emit 이
  먼저이냐가 문제"*). 그래서 emit을 **가로채는** 공용 노드가 필요하고,
  공개 API로 낸다. 사용자 스케치는 `Gate(function(emit) return function()
  ... end end)`. 남은 건 이름(`Gater`가 어색하다는 지적 — 에이전트 권고는
  `Gate` 그대로), `:Apply` 팩토리 여부, `Blocker`의 얹힘 방식, M2 범위.
- **`research/state-epoch-validation.md`** — `SS-2`/`SS-3`에서 사용자가
  제기한 **glitch**: DFS 전파 중 Observer가 `Get()`을 부르면 아직 신호를 못
  받은 다른 가지의 옛 캐시가 섞여 들어간다. 제안은 각 State가 상류 루트
  Source들의 **에포크(count)** 를 들고 `Get()` 때 비교하는 것. 에이전트
  분석: 진단·방향 타당(MobX/Adapton류 선례), **정확성 결정이지 최적화가
  아님**, 다만 중복 *통지*는 안 고쳐지고 "선언 안 된 의존성"을 UB로 명문화
  해야 함. **M3(State 구현) 전에 결론 필요.**

## 5. 2차 회신 — C절 전량 확정 (같은 세션)

되물은 6건이 그 자리에서 전부 닫혔다(처리 전량은 followup **F절**):

- **`Slot:Replace` 신설**(`B-5`) — 사용자가 "교체는 제거+삽입이 아니라 replace가
  나아 보인다"고 제시. `:List`의 교체가 `spliceArraysDown`+`spliceArraysUp`
  쌍(시프트 2회·`recompute` 2회)에서 **`rawReplace` 한 번(시프트 0)** 으로
  바뀌었고, 그 부수로 `C-7`(`:Single` 교체 시 Length가 잠깐 줄었다 느는 것)이
  같이 사라졌다.
- **에포크 안에서 중복 통지도 접기로**(`B-7`) — emit이 `(source, count)`를
  실어오므로 판정이 O(1). **2026-08-14에 폐기된 옛 dedup과 다른 장치**임을
  문서에 못 박았다(그건 `invalid` 플래그 기반이라 Observer 영구 침묵 모드가
  있었고, 에포크는 매 `Set`마다 새 값이라 그 모드가 없다). 구현 요구로
  **`seen`/`computedAt` 두 카운트 분리**가 추가됐다. 에이전트가 붙였던 "선언
  안 된 의존성을 UB로 명문화" 조건은 **사용자 기각**(*"이전과 다른게 없다"*).
- **물리 조작은 주입 op**(`C-1`) — *"slot 의 해당 동작은 base 이므로 parent 를
  모른다"*. 의사코드 전체의 `element.Parent = ...`/`element:Destroy()`를
  `mountInst`/`unmountInst`/`disposeInst`로 정정(9곳)하고 경계 절을 신설.
  **`rawAdd` 의사코드도 이때 처음으로 문서에 들어갔다.**
- **`rawAdd`의 `Length:Set` 제거**(`C-2`) — `Length`는 `recompute`만 쓴다.
- **래핑/언래핑을 Slot 전체 연산으로**(`C-3`) — `wrapElement`/`unwrapElement`
  한 쌍 + 래퍼의 `_wrapped` 역참조. 사용자가 예상한 대로 `wrappers[key]` /
  `mounted[key]` 분리가 **필요 없어졌다**.
- **`setLength`에 `anchor` 인자 신설**(`C-4`) — 부기 키와 생명주기 앵커 분리.
  4라운드 `D-56`이 역전돼 `archive/bindlifetime-slot-owner-reversed.md`로 갔고,
  형태 미정으로 열려 있던 **`isBoundAlive` 세 번째 분기 항목이 같이 닫혔다.**
- **`Effect(fn, ...deps)` 확정**(`C-6`) — `Ref`도 의존성이 될 수 있고, 최소
  1회 실행(useEffect 동일), trailing lazy 위치 인자, `Ref`는 `Set`될 때만 발화.
- **`Gate`만 다음 세션으로** — *"고칠것이 많으므로 … 지금 세션 상 지식만
  이전될 수 있게 두세요."* 그래서 `research/gate-primitive.md`는 재료만 모아둔
  상태로 두고 `question.md`/`todos.md`에 **M2를 막는 유일한 항목**으로 남겼다.

## 6. (1차 시점 기록) 되물었던 것

파급 큰 순서로: **`rawAdd`의 `Length:Set` 제거**(지금 서술이 "기여도 합"
정의와 충돌하고 `recompute`와 이중 기록), **`updateFn`이 State를 반환할 때의
래핑/`prev` identity**(래핑이 공개 `Slot:Add`에만 있어 reconcile 경로엔
없다는 실제 갭), **`setLength`의 Observer 앵커를 물리 target으로 되돌리기**
(사용자 문제 제기 — *"우리가 왜 slot 을 소유 대상으로 둘 수 있게 한거였는지"*,
되돌리면 4라운드 `D-56`의 백엔드 요구사항과 `isBoundAlive` 세 번째 분기가
통째로 불필요해짐), `rawAdd` 의사코드 초안 승인(문서에 정의가 아예 없었음),
`Gate` 이름·표면, `Effect`의 다중 의존성(`Ref` 포함) 안.

## 6-1. 3·4차 — `mountInst`의 삽입 위치에서 시작해 offset 모델이 정리됨

2차까지 끝난 뒤 사용자가 `mountInst`/`unmountInst`가 index를 안 받는 걸 문제
삼았다(*"웹에서는 어떻게 되냐가 모호함. 어디 둘지 어떻게 아느냐는것"*). 이
질문이 결국 offset 부기 모델 전체를 정리하게 만들었다:

- **`None`이 두 뜻을 겸하고 있었다** — 정의는 "실제 마운트를 하지 않는 위치"인데
  **plain 요소가 `None` + `setLength(1)`로 등록**되고 있었다. 그래서 그 자리의
  offset 숫자가 계산조차 안 됐고, DOM류 백엔드가 삽입 위치를 알 방법이 없었다.
  → `None`의 뜻을 **"발행 채널 없음"**으로 좁히고(참여 여부는 `lengthList`가 답),
  숫자가 필요한 쪽은 **`Dispatch.getOffsetAt(ownerKey, i)`로 pull**한다.
- **⭐⭐ 그 자리를 파다 별개 결함 발견 — 중첩 offset이 부모 베이스를 못 받았다.**
  `recompute`가 `sum = 0`으로 시작하고 `ownerKey.Offset`을 읽는 자리가 없어서,
  **depth ≥ 2에서 자식 offset이 부모 베이스만큼 통째로 밀려 있었다**(depth 1만
  쓰던 동안 로컬==절대라 안 드러남). → `base`를 시드하고, 중첩 Slot이 자기
  `Offset`을 관측해 자식 offset을 다시 미는 구독을 추가.
- **⭐ 반영하다 하나 더 — 재마운트가 `Offset` Source를 새로 만들고 있었다.**
  언마운트가 `slot.Offset`을 일부러 보존하는 이유(`SL-75`/`DC-6`: 이미 렌더된
  요소들이 그 Source를 **구독한 채 딸려 나감**)가 재마운트에서 무너지고 있었음
  → `slot.Offset or Source(0)`으로 identity 재사용.
- **에이전트 제안(`bk.offsetList` push)은 사용자안(pull + `getOffsetAt`)에
  밀려 폐기**됐고, 이어서 **`bk.base` 필드도 사용자 지적으로 걷어냈다**
  (*"이건 slot 안의 slot.offset 이랑 기능이 겹칠텐데"* — 같은 값을 두 곳에 두는
  중복 상태). `isSlot` 분기는 남는데, 그건 타입 분기가 아니라 **duck-typing이
  금지돼 있어서**(Roblox userdata의 미정의 키 인덱싱 에러, `brand-plan.md`)
  브랜드 검사가 유일한 안전 경로이기 때문.

**이 라운드의 패턴**: 세 결함 전부 *"사용자가 표면적인 질문 하나를 던졌더니 그
아래에서 나왔다"* — `mountInst`의 인자 하나가 offset 모델의 두 결함을 끌어냈다.

## 6-2. 커밋 전 감사 2라운드 — 실제 결함 다수

핸드오버 준비로 `quad-doc-auditor`를 각도를 바꿔 두 번 돌렸다(1: diff와 그걸
인용하는 base / 2: 인덱스 레이어·히스토리). **둘 다 실질적인 걸 잡았다.**

- **⭐ `Owned`가 코드에 도달하지 못하고 있었다** — `settle`/`destroySlotTree`/
  `releaseElement`가 `self._owned`를 9곳 넘게 읽는데 `Slot:List`/`Slot:Single`
  의사코드가 **`opts` 인자를 안 받고 있었다.** 확정한 옵션이 **문서 안에서
  배선이 끊긴 채** 있었던 셈.
- **⭐ `effect-plan.md`가 자기 자신과 모순** — 최상단 시그니처와 "trailing args
  sugar는 의도적으로 안 만듦" 확정 문단이 그대로인 채 `Effect(fn, ...deps)`
  절이 추가돼 **역전 배너 없이 정반대 두 서술이 공존**하고 있었다.
- **⭐ 손대지 않은 문서의 사각지대** — `ROADMAP.md` 백로그 문단과
  `debounce-throttle-plan.md`가 "Gate 추출은 M3에서"라고 여전히 말하고 있었다
  (이번에 M2로 앞당겨졌는데 diff에 안 잡히는 파일이라 그대로 남음). 이건
  `conventions.md`가 경고하는 "변경한 세션 자신은 자기가 뭘 안 건드렸는지
  모른다"의 교과서적 사례.
- **⭐ 인덱스에 옛 결론이 남음** — State-에포크의 "중복 통지는 안 고쳐진다 /
  UB 명문화 필요"가 같은 날 정반대로 확정됐는데 `question.md`/`README.md`만
  안 따라왔다.
- 그 외: `indexOfRaw` 미정의, `mountSlotTree`의 전제 미명시, `Replace`의
  `destroyOld` 미서술, `Gate` 이름이 용어 대기열에 없음, 주입 op 목록 미갱신,
  M2 체크박스 문장 깨짐 등.

**그리고 감사 회신 자리에서 결정 셋이 더 확정됐다** — `raw*`를 **index로 통일**
(오래 열려 있던 캐비엇 종결), **래핑은 `raw*` 바깥**, 그리고 `getOffsetAt`의
**접두합 캐시**(`invalidAfter` — 단일 함수가 필요한 만큼만 이어붙임). offset 물리 재배치 질문도 "DOM은 insert가
알아서 밀어낸다"로 닫혔다.

## 6-3. 마지막 라운드 — `native*` 계층 확정, `C-7` 역전

주입 op 셋(`mountInst`/`unmountInst`/`disposeInst`)으로는 **`Move`/`Swap`을 아예
표현할 수 없다**는 사용자 지적에서 시작해 물리 조작 계층이 재설계됐다.

- **층위 정의가 생겼다** — `raw*` = Slot 스코프(평탄화 전), `native*` = 확정된
  offset/length 기반 물리 연산(평탄화 후).
- 표면은 여섯(`nativeInsert`/`Extract`/`Remove`/`Move`/`Swap`/`Dispose`).
  `Replace`는 별도 op이 아니라 **`newElements`가 있는 Remove/Extract**이고,
  파괴/비파괴는 **불리언이 아니라 이름**으로 가른다(Roblox의 "그 자리에서 바로
  Destroy" 융합을 열기 위해).
- **⭐ 대상 요소를 배열로 넘겨야 한다** — `(target, offset, count)`로 찾을 수
  있는 건 DOM뿐이고 **Roblox는 자식이 순서 없는 집합**이라 offset 역조회가 안 된다.
- **⭐ `C-7`("부기가 물리보다 항상 먼저")이 역전됐다** — base엔 물리적으로 자리를
  비워둘 수단이 없고 미는 주체는 백엔드의 삽입 연산 자신이다. 규칙이
  **"자기 자리를 정하는 것 먼저 / 뒤를 미는 것 나중"** 하나로 줄었다.
  원문은 `archive/bookkeeping-before-physical-reversed.md`.
- 같은 라운드에서 `getOffsetAt`의 접두합 캐시도 사용자 의사코드로 정정 —
  **단일 함수 + `invalidAfter`**, 무효화는 `min(invalidAfter, i)` 하나.

## 7. 남긴 파일

- `qa-request/pre-implementation-qa-round5.md` — 문항지(205문항)
- `qa-request/pre-implementation-qa-round5-response.md` — 회신 원문
- `qa-request/pre-implementation-qa-round5-followup.md` — **처리 결과의 소스**
  (절이 라운드마다 쌓임 — **마지막 절이 최신**)
- `archive/bindlifetime-slot-owner-reversed.md` — 역전된 `D-56` 원문
- `research/gate-primitive.md`, `research/state-epoch-validation.md`

## 8. 후속 — State 에포크 안 3차 정정 (같은 날)

사용자가 `research/state-epoch-validation.md`를 직접 읽고 기제 서술 세 건을
정정했다: (1) `sourceList` 순회는 `rawInvalid`가 **false**일 때만 돈다(문서는
반대로 적고 있었다, 목적은 "못 받은 emit 받기"), (2) `emit`은 count 없이
**발행 source만** 싣는다, (3) 에이전트가 요구했던 **`seen`/`computedAt` 두
카운트 분리는 철회** — count 갱신과 `rawInvalid = true`가 같은 스텝이라
캐시 오인 경로가 없다. 부수로 "순회가 발견한 변경을 뒤로 emit 할 것인가"가
열렸는데, 다이아몬드 쪽은 사용자가 스스로 안전으로 정정했고 게이트 쪽만
**해제 emit이 `source = nil`을 싣는 규약**으로 남았다(게이트는 보통 최종단에
쓰므로 채택을 막지 않는다는 판단). 상세는 그 문서의 §2·§5와
`qa-request/pre-implementation-qa-round5-followup.md`의 M절.

## 9. 후속 — 순회의 count 갱신 문제 + `Gate`는 `:Apply`가 아니다 (같은 날)

**(1) 순회가 count를 올리면 통지가 죽는다.** 사용자 지적 — 순회로 발견해
count를 최신으로 올려두면 뒤늦게 온 진짜 emit이 삼켜져 하류가 그 에포크를
영영 못 받는다(2026-08-14에 폐기된 옛 dedup의 "영구 침묵"과 같은 계열).
사용자 해법은 **(b) 순회도 emit 한다**이고, 게이트 경우엔 그 emit을 해제
시점까지 민다는 것. 에이전트는 **(c) 순회는 `rawInvalid`만 세우고 count는
안 올린다**를 대안으로 냈다 — 원인이 정확히 "순회가 count를 올리는 것"이라
그것만 안 하면 통지 죽음도 게이트 누출도 `nil` emit 규약도 안 생긴다.
대가는 emit이 올 때까지 `Get()`마다 재계산, 그리고 `OffWithoutEmit` 경로에서
count가 안 따라잡는 것. 또 (b)에서 "게이트까지 민다"를 실제로 구현하려면
순회하는 노드가 상류 게이트를 알아야 하는데 `sourceList`가 루트로 평탄화돼
있어 불가능하고, 유일하게 깔끔한 기제(게이트를 에포크 경계로)는
`blocker-plan.md`의 "`:Get()`엔 영향 없음" 확정 계약을 뒤집는다는 걸 짚었다.
**미결** — `research/state-epoch-validation.md` §5의 3번이 소스.

**(2) `Gate`는 `:Apply`가 아니라 State 메소드.** 사용자 확정 — *"state 의
전파를 손대는 작업이라 with 처럼 다른 노드가 나는게 맞음."* 경계를 정확히
적어두면, `Apply`가 노드를 못 만드는 게 아니라(확정 예시 `capAt(100)`도
`:With` 노드를 만든다) **프리미티브는 메소드 / 유저랜드 조합 팩토리는
`:Apply`**라는 층위 구분이다. 부수 결론 셋 — `Debounce`/`Throttle`의
`state:Apply(...)` 관용구는 그대로 유효(팩토리가 내부에서 `:Gate`를 부르면
됨), `Blocker` 배선 문제는 이미 확정된 `state:Block(blocker)` 메소드로
자동 해소, `__call`은 안 씀(사용자 선호 + Luau 함수 타입 자리 통과 여부
불확실). `research/gate-primitive.md`의 2번이 해소로 갱신됨.

## 10. 후속 — 순회 처분을 테이블 둘로 확정 (같은 날)

9절에서 열어둔 (b)/(c)를 사용자가 **제3안으로 닫았다**: 판정 기준을 둘로
나눠 `sourceCountMap`(값 유효성, 순회가 앞당겨 올림)과 `sourceEmitMap`(전파
dedup, 상류의 진짜 emit을 기다림)을 따로 둔다. 순회는 emit을 안 하므로
게이트 누출이 아예 안 생기고, 뒤늦은 emit은 "count는 같은데 emit 기록이
다름"으로 걸려 정상 전파된다. (c)의 유일한 약점(`Get()`마다 재계산)도
사라진다 — 순회가 `sourceCountMap`을 실제로 올리기 때문. 같이 나온
`rawEmit`+`nil` 안은 구조 위생(상류 emit과 내부 emit의 진입점 통일)만
살리고 해법으로는 안 쓴다(막는 게이트는 보통 상류에 있어 자기 `rawEmit`을
태워도 누출이 남고, `nil` emit은 하류마다 전체 순회를 강제해 연쇄한다).
M절에서 철회했던 두-카운트 분리가 **다른 근거로 되살아난** 셈이다.
이제 이 안은 기제가 다 정해졌고 **남은 건 채택 여부 자체**다.

## 11. 종결 — `Gate` 표면 확정 + 에포크 채택, 두 문서 `base/` 승격 (같은 날)

사용자가 `Gate`를 **탑레벨 프리미티브 없이 `state:Gate(setup)` 메소드 +
`GateNode`**로 확정하고(*"Blocker 는 해당 내부 배선을 따른다"*), 이어서
State 에포크도 **채택**했다(*"gate 와 epoch 가 제가 만족할만한 정도로
올라왔습니다"*). `research/gate-primitive.md` → `base/gate-plan.md`,
`research/state-epoch-validation.md` → `base/state-epoch-plan.md`로 승격.

에포크 채택으로 `source-state-plan.md`의 두 확정 서술("항상 전파" / "중복
통지는 안 접음")이 역전돼 `archive/always-propagate-no-dedup-superseded.md`로
옮겼다. **2026-08-14의 `invalid` 기반 dedup 금지를 되돌린 게 아니라는 것**을
역전 문서·`source-state-plan.md`·`README.md` 세 곳에 모두 못박았다 — 이
구분이 흐려지면 "영구 침묵" 버그로 되돌아간다.

부수로 스파이크 `05-store-state-diamond-propagation`이 다시
`rewrite-required/`로 갔다(다이아몬드 Observer가 이제 변경당 1회만 울어야
해서 핵심 assert가 정반대). 처리 전량은
`qa-request/pre-implementation-qa-round5-followup.md`의 O절.

## 12. `/code-review high` — 12건 전부 유효, 그중 3건은 실제 설계 구멍

O절 커밋 직후 사용자가 돌린 리뷰에서 12건이 나왔고 전부 유효했다. 특히
**게이트가 유보했다 내보내는 emit이 어느 source를 싣는가**는 M절이 이미
짚어뒀는데(*"`nil` 규약만 Gate 설계와 같이 확정하면 된다"*) 표면 확정 때
같이 안 닫힌 것으로, 그대로 두면 `blocker:Off()`의 배치 통지가 하류에서
삼켜진다 — `setup` 시그니처에 영향이 있어 **M2 착수 전 항목**으로 되돌렸다
(같은 날 "M2를 막는 항목 없음"이라 적었던 `todos.md` 00번도 정정).

교훈이 하나 더 있다: 이번에도 **감사자 각도가 아니라 diff 각도에서만 보이는
것**이 다수였다(개수 하드코딩, 배너 vs 본문, 같은 파일 안의 모순 문장,
방금 옮긴 파일을 가리키는 새 텍스트). `conventions.md`의 "`/code-review`는
감사자를 대체하지 않는다" 항목이 다시 확인된 셈. 전량은
`qa-request/pre-implementation-qa-round5-followup.md`의 P절.

## 13. `/code-review` 3건에 대한 사용자 회신 — 2건 확정, 1건은 근거가 반증됨

게이트 emit의 출처는 **`emit(self)` + 흡수 집합**으로 닫혔다. 에이전트가
권고한 (c)를 사용자가 더 단순화한 형태 — 게이트에 자체 count를 주는 대신
`withheld : {[source]=true}`만 들고 있다가 풀 때 자기를 출처로 emit 하고,
**동기 전파**라 반환 뒤 `table.clear`하면 하류 전원이 집합을 본다. 검토
결과 **`setup` 시그니처는 안 바뀐다** — 집합을 채우는 건 정책이 아니라
노드이기 때문(P절이 "M2 표면에 영향"이라 적은 건 기우였다).

에포크 쪽은 "재계산 때 count 전부 갱신"만 확정되고, 그걸 제기한 에이전트
근거는 **사용자가 반증**했다 — 전파가 동기라 `A:Set()` 파동이 끝난 뒤에야
`Z:Set()`이 시작되므로 통지가 두 번 나는 건 중복이 아니라 맞는 동작이다.
그 과정에서 대원칙 하나가 명문화됐다: **무효화를 결정하는 건 언제나 count
비교지 emit의 도착이 아니다.** 전량은 followup의 Q절.

## 14. 마지막 단순화 두 건 — 게이트 통과/유보 미구분, 새 노드 맵 비대칭 초기화

사용자가 Q절 기제를 한 번 더 줄였다. 게이트는 **정책 실행 전에 무조건**
출처를 `withheld`에 넣고, 통과시킬 때조차 **자기를 출처로** 전파한다 —
"지연과 비지연을 구분할 이유가 없다". 그래서 Q절이 넣었던 "정책이 emit을
불렀는지 노드가 되짚는다"는 감지 로직이 통째로 사라졌다.

새 노드의 두 맵은 **비대칭**으로 초기화한다: `sourceEmitMap`은 비우고
(새 노드는 개념적으로 emit을 받아본 적이 없으므로 `nil`이 곧 "변경"),
`sourceCountMap`은 상류에서 전부 끌어와 실제 count로 채운 뒤
`rawInvalid = true`(순회가 훑을 목록이 곧 이 맵이라 비워두면 "유효"로
오판). 이걸로 `:With` 병합 규칙이 필요 없어지며 `/code-review` Med-3이
닫혔다. 전량은 followup의 R절.
