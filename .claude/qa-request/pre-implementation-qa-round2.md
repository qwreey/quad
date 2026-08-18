# 구현 전 QA **2라운드** — 의사코드 손 트레이싱

**상태**: **완료 — 핵심 발견(`RC-1`)까지 같은 날 후속 세션에서 해결·
`base/` 반영 완료.** 1라운드는 "확정된 주장이 맞는가"를 물었을 뿐 의사코드를
실제로 실행해보진 않았음(`pre-implementation-qa-round1.md` 맨 아래 "진행
로그" 절). 2라운드는 그 갭을 메우는 작업 — `base/slot-plan.md`의 `:List`
`reconcile`과 `base/dispatch-core-plan.md`의 `recompute`를 구체 시나리오로
직접 손으로 실행해보고, 부수로 `reference/` 인용 정확성과 `ROADMAP.md`
마일스톤 정합성도 훑었다.

**이 문서의 용도**: 1라운드와 달리 "예/아니오 판정" 문항이 아니라 트레이싱
결과 자체가 산출물 — 버그를 찾으면 그 자리에서 기록하고, 방향이 갈리는
것만 사용자에게 물었다. 새로 발견된 결함은 `RC-1` 하나뿐이고, 나머지는
"트레이싱했지만 문제 없음 확인"으로 아래 각 절에 남긴다(재작업 방지용
기록 — `conventions.md`의 "작업이 끝나면(또는 방향이 바뀌면) 항상 자기
문서화" 원칙).

---

## RC-1 — `recompute`의 트리거 모델 자체가 재검토 대상 ✅ 해결(2026-08-18 후속 세션)

**판정**: 트레이싱으로 실제 크래시 경로를 확인 — 사용자도 진단은 맞다고
동의했고, 같은 날 후속 대화에서 **Blocker를 재사용하는 배치 게이팅
설계로 확정**됐다(아래 "해결 — Blocker 게이팅" 절). 해법이 실제
반영된 곳은 `base/dispatch-core-plan.md`의 "배치 등록을 안전하게 만드는
Blocker 게이팅" 절, `base/slot-plan.md`의 "재귀 메커니즘" 절,
`base/blocker-plan.md`의 "`state:Block()` 없이 직접 쓰는 두 번째 용례"
절 — 이 문서는 그 결론에 이르는 논의 원문만 보존한다.

### 발견한 크래시 경로

`base/dispatch-core-plan.md`의 "Length/Offset — 여러 Slot이 형제로 섞일 때
순서 보장" 절의 `recompute` 의사코드:

```lua
local function recompute(ownerKey, bk)
    local sum = 0
    for i = 1, bk.N do
        local offset = bk.sourceList[i]
        if offset ~= nil and offset ~= None and offset:Get() ~= sum then
            offset:Set(sum)
        end
        local v = bk.lengthList[i]
        sum += (if isState(v) then v:Get() else v)   -- ← v가 nil이면 여기서 산술 에러
    end
    ...
end
```

**구체 시나리오 — `Frame{A, B}`(정적 자식 2개, 반응형 없음, `N=2`).**

1. `Dispatch.drive(inst, flattened)`가 배열 파트를 순서대로 순회 —
   `bk.N`은 "그 `inst`의 array part 크기" 이므로 순회를 **시작하는 시점에
   이미 `2`로 정해져 있음**(같은 절의 "저장 위치" 문단).
2. position 1(`A`)을 담당하는 말단 Handler가 `Dispatch.setLength(inst,1,1)`을
   부름. `setLength`의 의사코드는 **끝에서 무조건 `recompute(inst,bk)`를
   호출**(같은 절 "`setLength` 구현" 문단 — "등록 즉시 1회(Observer 자체의
   '등록 즉시 1회 실행'과 겹쳐도 무해)").
3. 이 시점의 `recompute` 루프가 `i=1..bk.N(=2)`을 돎 — `i=1`은
   `bk.lengthList[1]=1`이라 정상. `i=2`는 **position 2(`B`)가 아직 처리되기
   전이라 `bk.lengthList[2]`가 `nil`** — `sum += (if isState(v) then
   v:Get() else v)`에서 `sum += nil`이 되어 산술 에러로 크래시.

`sourceList`(offset) 쪽은 같은 절에 이미 nil 가드가 있음(*"[방어,
2026-08-13 여섯 번째 세션] `nil`도 같이 배제"*) — `lengthList` 쪽엔 그
대칭 가드가 없다. 정적 자식 2개짜리 `Frame`처럼 **가장 흔한 경우**에서
바로 재현되는 경로라, 별도 `Slot`/반응형 값 없이도 걸림.

### 왜 지금까지 안 잡혔나

기존 `luau-test/` 스파이크 중 이 함수를 다루는 건
`done/20-slot-splice-index-arithmetic.luau` 하나뿐인데, 이건 `Splice`의
순수 배열 인덱스 산술(제거/삽입 시 뒤 요소가 몇 칸 밀리는지)만 검증하고
**`Dispatch.drive`가 여러 position을 순차 처리하며 `bk.lengthList`를 점진적으로
채우는 과정 자체는 다루지 않음** — 이 경로를 실행해본 스파이크가 없었다.
같은 함수의 다른 버그(offset이 자기 자신을 포함해 누적되던 off-by-one)는
2026-08-11 세션에 이미 한 번 발견·수정됐지만(같은 문서 "recompute — 매번
전체 순회" 문단), 이번 것은 그와 별개의 문제.

### 사용자 답변 원문 — 진단은 맞다고 확인, 그러나 더 큰 재설계 필요

> setLength/setOffset 자체는 리레이아웃을 트리거하진 않아야한다고 생각함.
> 명시 리트리거를 해야하는게, 이러면 첫 실행에서 계속 recompute 비용이
> 쌓임. 옵져버 생성 시 클로저 위쪽에 init = true 두고 처리할 필요가
> 있는듯 하고, 각각의 process 가 setLength 를 나중에 수행했을 때는
> recompute 를 어떻게 할지 생각해봐야할듯. 등록을 배치로 미룸은 맞는데,
> State<None|Slot> 이 오는건 어쩌냐를 잘 모르겠음. 각각 처음에 바운딩
> 할 땐 그럼 offset/length 어떻게 계산할지는 이것도 아직 모르겠음..
> 생각을 더 해

**애초에 열려 있던 세 갈래**(사용자가 처음엔 하나로 안 좁힘) — (1)
`setLength`/`setOffsetSource` 자체는 `recompute`를 트리거하지 않아야
한다(명시적 리트리거 필요), (2) 등록을 배치로 미루는 방향은 맞지만
`State<Slot|None>`처럼 값이 나중에 도착하는 경우를 어떻게 커버할지 불명,
(3) 최초 바인딩 시점의 offset/length 계산 방식 자체가 안 잡힘 — 아래가
같은 날 후속 대화에서 이 세 갈래를 하나로 합친 결과다.

### 해결 — Blocker 게이팅 (2026-08-18, 같은 날 후속 세션)

**사용자가 직접 제시한 설계 원문**:

> 각각의 length 들을 그냥 받아서 바인딩 하는게 아니야. 각 Frame 에 대한
> Blocker 를 릴레이션으로 가지고 있고 이건 드라이빙 함수가 실행될 때
> 생성돼. Offset/Length 소스가 설정 될 때, 특히 Length 에 있어서는 이
> Frame->Blocker 로 있는걸 얻어와서 한번 적용하고 넣어둬. 그리고 Observer
> callback 에서도 Blocker 가 IsOn 상태면 무시해줘. 드라이브 함수가
> 실행되어 Blocker 가 생성될 때 기본으로 On 을 해줘. 이러면 length 가
> 변경되며 계속 recompute 되지 않아. 그런 다음 OffWithoutEmit 을 해.
> 맨 마지막으로 recompute 를 한번 하면 되는식이야.
>
> 다만, 이러면 초기에 레이아웃이 이상해져. 주의할 점은 setOffsetSource
> 를 하게 되면 이건 자기 자신 위쪽으로 있는 요소들의 length 를 합해서
> 설정해줘야할거야. 이건 첫 for 루프에서도 작동한다고 봄. 즉, 사실 첫
> 루프 상 recompute 자체는 필요 없어. 그리고 setOffsetSource 는 여전히
> slot 의 실체화로 List 가 수행되기 전에 설정되어야하고, length 가 확정
> 된 다음에 다음 요소로 넘어가야해.

**요지 두 갈래로 나뉜다**:
1. **`recompute`를 배치가 끝날 때까지 아예 안 돈다** — owner(inst 또는
   Slot)마다 `Relate`로 들고 있는 전용 `Blocker`를 배치 시작 시 `On`,
   `setLength`의 Observer 콜백(등록 즉시 1회 실행 포함)이
   `blocker:IsOn()`이면 `recompute`를 건너뜀. 배치가 끝나면
   `OffWithoutEmit()` + 명시적 `recompute` 딱 1회.
2. **`setOffsetSource`는 그 즉시 앞선 형제들의 길이 합을 직접 계산해
   `:Set`한다** — recompute를 미루는 것만으로는 "초기 레이아웃이
   이상해지는" 문제(배치 도중 `:List`가 실체화되며 옛/기본값 offset을
   읽어버림)가 남기 때문에, offset 자체는 즉시 계산으로 옮겨 recompute를
   기다리지 않게 함.

**뒤이은 확인 질문 3개와 답변**(`AskUserQuestion`, 같은 세션):

- **중첩된 Slot이 `attachSlot`을 재귀할 때도 각자 별도 Blocker가
  필요한가?** → *"예 — 중첩마다 별도 Blocker (권장)"* —
  `base/blocker-plan.md`의 재진입(네스팅) 미지원 규칙 그대로 적용.
- **런타임에 이미 마운트된 Slot에 한 번에 하나씩 `:Add()`하는 경우도
  같은 위험이 있는가?** → *"그건 이미 마운트가 된 이후라서 별 상관
  없음. 가장 큰 문제는 마운트 중간에 후행 nil 이 있는데 recompute 가
  난다는게 문제... 정확한 내 의견은 이래: setLength 는 recompute 를
  직접 수행하진 않고, Observer 에서 recompute 를 수행해. 맨 처음 emit
  에서도 blocker 가 on 이면 무시하는식. 그럼에도 새로운 개체가 뒤에
  붙는 현상에서는 위 요소들로 하여금 위치를 구하면 돼, 뒷 요소를
  밀어내는게 아니라서, setLength 가 emit 되지 않는것에 영향 안 받고
  수행 가능함"* — 크래시는 오직 "N이 미리 정해진 채 배치로 등록"되는
  두 자리(`Dispatch.drive`, `attachSlot`의 flush)에서만 나고, 런타임
  단건 append는 이미 안정된 앞선 position만 참조하므로 무관함이 확정.
  `setLength`가 `recompute`를 직접 안 부르고 Observer 콜백(첫 실행
  포함)만을 경유한다는 것도 이 답변에서 확정됨.
- **`IsOn`/`HasBlocked`를 기존 `IsBlocked`/`HasBlockedEmit`과 어떻게
  관계지을까?** → *"IsBlocked가 있다면 그냥 두어도 될듯 함.
  HasBlockedEmit 만 처리된다면 괜찮다 생각"* — 기존 필드는 그대로 두고,
  `IsOn()`은 `IsBlocked`를 읽는 얇은 조회 메소드로만 추가. 처음 요청했던
  `HasBlocked`(Blocker 자신의 새 최상위 플래그)는 **신설하지 않음** —
  `OffWithoutEmit()`이 각 gated state의 기존 `HasBlockedEmit`을 그대로
  리셋해주는 것으로 충분하다고 판단.

### 후속 정정 — `attachSlot`의 호출 순서가 뒤집혀 있었음 (같은 세션, RC-1 반영 직후)

위 설계를 `attachSlot`에 실제로 반영하는 과정에서 사용자가 직접 짚은
추가 결함: `attachSlot`의 기존 의사코드는 `setLength`를 먼저, `setOffsetSource`를
나중에 불렀는데, 이건 `base/dispatch-core-plan.md`의 "`NilHandler`" 절이
이미 확정해둔 **"호출 순서는 `setOffsetSource` → `setLength`"** 일반
규칙과 어긋나 있었다(RC-1로 `setOffsetSource`가 즉시 계산을 하게 되면서
이 불일치가 드러남 — 그 전엔 둘 다 `recompute`에 얹혀 있어서 순서가
겉으로 안 드러났었다). 사용자 확정 원문:

> length 를 알게되는 시점은 각 요소가 생성된 이후인데, 그럼 setOffset
> 이 먼저 안 되어있으면 offset 전파가 한번 더 일어나게됨. 따라서 위가
> 맞음

즉 Slot의 진짜 `.Length`는 `activateList`가 자기 `:List`를 최초
reconcile한 **뒤에야** 확정되므로, 순서는 **`setOffsetSource`(즉시 계산)
→ (Slot이면) `activateList` 실체화 → `setLength`(그제서야 확정된 값으로
등록) → 물리 마운트**여야 한다 — `setLength`를 실체화 전에 부르면 등록
직후 값이 또 바뀌어 전파가 한 번 낭비된다. 평범한 Instance 요소도 같은
순서(`setOffsetSource(None)` → `setLength(1)` → `Parent` 대입)를 따르며,
이 경로는 기존 의사코드에 아예 안 보이던 것도 이번에 같이 채워짐.

**부수 확정 — 코루틴 yield 금지 불변식.** 사용자가 이 논의 말미에 지적:

> 모든 컴포넌트든 뭐든 yield 되면 안되는 sync 함수이여야 할듯. 안 그럼
> 꼬이는 문제가 발생하지 않나 생각함

이 배치 게이팅 전체가 "position이 항상 순서대로, 끼어드는 코드 없이
동기로 처리된다"는 전제 위에 있어서, `Dispatch.process`/`attachSlot`
호출 체인 도중 코루틴 yield가 끼면 같은 owner의 Blocker를 다른 코드가
그 사이에 건드릴 수 있다 — 명시적 불변식(UB 선언)으로 문서화하기로 확정.

**반영된 곳**:
- `base/blocker-plan.md` — `IsOn()`/`OffWithoutEmit()` 신설, onunblock
  핸들이 `emit: boolean`을 받도록 변경, `state:Block()` 없이 직접 쓰는
  용례 신설, 재진입 규칙에 이 용례의 실제 사례 추가.
- `base/dispatch-core-plan.md` — "Length/Offset" 절에 "배치 등록을
  안전하게 만드는 Blocker 게이팅" 절 신설(`setLength`/`setOffsetSource`
  재작성, `Dispatch.drive`도 자기 Blocker로 배열 파트 순회를 감쌈), 코루틴
  yield 금지 불변식 추가.
- `base/slot-plan.md` — "재귀 메커니즘" 절의 `attachSlot`이 자기 flush
  루프를 자기 자신의 Blocker로 감싸도록, 그리고 `setOffsetSource`→`setLength`
  순서로 재작성(평범한 Instance 요소의 등록도 명시적으로 채움), 런타임
  단건 `Add` 경로는 게이팅 불필요함을 명시.

---

## SL — `base/slot-plan.md`의 `:List` reconcile 트레이싱 — 새 결함 없음, 기존 미해결 갭만 재확인

`base/slot-plan.md`의 "구현" 절(`activateList`/`reconcile` 의사코드)을 아래
시나리오로 손으로 실행:

- **재정렬**(`[A,B,C]` → `[C,A,B]`, 값 동일) — `pos`/`keyIndex` 비교가
  `rawMove`를 정확한 절대 위치로 호출, 정상.
- **키 제거**(`[A,B,C]` → `[A,C]`) — 소멸 루프가 `keyIndex`(직전 사이클 전체
  key 집합)를 순회해 `B`를 `rawRemove`, 나머지 `pos` 압축도 정상.
- **필터 토글**(`updateFn`이 특정 key에 `nil` 반환) — `rawRemove`(파괴)
  경로를 타고, `pos`가 그 키만큼 증가 안 해 뒤 요소가 정상 압축됨.
- **`PopOnly` 반환 후 재등장** — `mounted[key]=nil`이지만 `userdata[key]`가
  `{old=...}`를 강하게 붙잡아 GC를 막고, 다음 사이클에 `prev=nil`로
  받은 `updateFn`이 `ud.old`를 그대로 반환하면 `rawAdd`로 재마운트됨 — 문서
  서술대로 정상 동작.
- **nested Slot 반환**(`isSlot(result)`) — `pos = candidateIndex - 1 +
  result.Length:Get()`으로 다음 형제의 위치가 정확히 밀림, "`:List`의
  `index`도 nested-Slot 결과의 `.Length`만큼 건너뛰어야 함" 절의 결론과
  일치.
- **중복 key** — `seen[key]` 체크가 `updateFn` 호출 *전에* 있어 즉시
  `error`, 상태 오염 없음.

**PopOnly 홀드 중 키가 데이터에서 완전히 사라지는 경우**만 트레이싱으로도
재현됨 — 소멸 루프가 `mounted[key]`(이미 `nil`)만 보고 `rawRemove`를
건너뛰어, 그 요소가 파괴도 반환도 안 되고 참조만 끊겨 GC된다. 이건 **이미
`base/slot-plan.md`의 "`nil` 리턴은 파괴가 기본" 절과 `question.md`
3번(`PopOnly`로 홀드 중이던 요소의 키가 사라지면 어떻게 처분하는가)이
알고 있는 미해결 갭** — 이번 트레이싱은 그 갭이 실제로 재현됨을 손으로
다시 확인했을 뿐, 새 발견이 아니다. 결론은 그대로 `question.md` 3번의
(a)/(b)/(c) 선택지에 맡긴다.

---

## D — `base/dispatch-core-plan.md`의 하강 diff 재디스패치 트레이싱 — 문제 없음

"Dispatch 체인" 절의 `Dispatch.process`/`Dispatch.retractFrom`을 아래
시나리오로 트레이싱:

- **최초 마운트**(`store.key = a`, `a: State<Tag>`) — `StoreBind`가 `index=1`을
  잡고 `a:Get()`을 들고 `Dispatch.process(inst,k,realv,2)`를 재귀, `chains`에
  `[1]=StoreBind`, `[2]=TagHandler`가 순서대로 쌓임. 정상.
- **같은 핸들러로 값 교체**(`a`가 새 `Tag`를 내놓음) — `Dispatch.process`의
  (A) 분기가 인덱스 2 슬롯의 기존 `retractor`에 새 값을 넘기고 클로저를
  교체, 인덱스 1은 안 건드림. `chains` 구조·재귀 깊이 전부 문서 서술과
  일치.
- **`State<State<Tag>>`** — 안쪽 재귀가 `index+1`이라는 별개 슬롯을 쓰므로
  StoreBind 싱글톤이 같은 `(inst,k)`에 두 번 매치돼도 슬롯이 안 겹침 —
  "`State<State<T>>`는 정상 지원 대상" 절의 결론과 일치.

새로 발견된 문제 없음.

---

## `reference/` 인용 정확성 — 표본 점검, 불일치 없음

`base/` 문서가 `reference/quad-v1-architecture.md`/`reference/
comparison-fusion-vide.md`를 인용하는 자리 중 표본 3곳을 원문과 대조:

- `base/lifecycle-pattern.md`가 v1의 GC 방지 핫팩을 인용한 자리 — 원문
  (`PropertyChangedSignal("ClassName")`에 연결해 참조를 붙잡아두는 관용구)과
  일치.
- `base/slot-plan.md`가 v1 `mount.lua`를 분석한 자리("부모/자식 부기까지
  했지만 다중 마운트 방지는 없었음") — 원문(`mount.lua`는 실제로 부모/자식
  부기(bookkeeping) + 라이프사이클 파괴까지 담당하는 무거운 모듈)과
  정합(다중 마운트 방지 부재는 문서 전체 맥락상 타당한 요약).
- `base/tween-plan.md`가 Fusion의 Tween/Spring을 반면교사로 인용한 자리 —
  `reference/comparison-fusion-vide.md`의 해당 문구와 일치.

전수 대조는 아니고(`reference/`를 인용하는 자리 전체는 `base/*.md`에서
`reference/`로 grep한 결과 10여 곳 — 정확한 개수는 grep 결과 자체가
소스), 표본에서 불일치가 안 나와 전수 대조로 확장하지 않음.

## `ROADMAP.md` 마일스톤 정합성 — 1라운드 반영분 확인, 불일치 없음

1라운드에서 뒤집힌 것 중 `ROADMAP.md`가 언급하는 것들이 갱신됐는지 확인:
`NilHandler`/`NoneHandler` 분리(**[정정, 2026-08-18 `/code-review high`]
M2가 아니라 M7 — Modifier 마일스톤에 체크박스가 있음, M2엔 서술 문단
안에서만 이름이 언급될 뿐 별도 체크리스트 항목이 없음**), `PopOnly` 반환
경로(M6), `store:GetDynamic` 탑레벨/콜론 미정 표시(M3), `DI`→`D`
리네임(전역) — 전부 반영 확인됨.
`D-6`(`setLength`/`setOffsetSource` 호출 책임자를 "처음 매치한 Handler"로
서술하던 옛 오류)의 흔적도 `ROADMAP.md`엔 없음(애초에 그 정도 구현
디테일은 `base/`만 갖고 있고 `ROADMAP.md`는 체크박스 수준이라 옮겨붙을
자리가 없었음).

---

## [중간 상태 기록, Blocker 해법 확정 이전] 반영

**⚠️ 이 절은 낡았다 — RC-1이 아직 "미해결"이던 시점(사용자가 "생각을 더
해"라며 방향을 안 정했을 때)에 세워둔 임시 조치 목록이다.** 그 뒤 같은
세션 후속 대화에서 Blocker 게이팅 설계가 확정되며 아래 내용 대부분이
다시 뒤집히거나 대체됐다 — **지금 유효한 반영 목록은 위 "해결 — Blocker
게이팅" 절의 "반영된 곳" 문단이 소스**, 여기서 다시 정리하지 않는다.
`question.md`는 이 중간 단계에서 `RC-1`을 추가했다가 해소 단계에서
다시 뺀 것이라 최종 diff엔 흔적이 안 남는다(2026-08-18 감사에서 확인) —
다음 세션이 "question.md가 바뀌었어야 하는데 안 바뀌었다"고 오해하지
않도록 남겨둠. 아래는 그 시점의 원문 그대로 보존(역사 기록):

- `question.md` 3번에 `RC-1`을 M2 착수 전 결론 필요 항목으로 추가(→ 이후
  해소되며 제거, `archive/question-resolved.md`로).
- `.claude/todos.md` 00번(구현 전 QA 결과 요약)의 미해결 목록에 `RC-1`
  추가, 머리말을 "M2/M3 착수 전 필요"로 갱신(→ 이후 해소 반영으로 다시
  갱신).
- `base/dispatch-core-plan.md`의 "Length/Offset" 절 `recompute`/`setLength`
  **의사코드 자체엔 손대지 않음**(nil 가드 같은 국소 수선도 넣지 않기로
  함) — 대신 그 절 바로 위에 미해결 배너를 추가(→ 이후 의사코드 자체가
  Blocker 게이팅으로 재작성됨).
- `base/slot-plan.md`의 "재귀 메커니즘" 절 서두에 `RC-1` 포인터 추가(→
  이후 `attachSlot` 의사코드 자체가 재작성됨).
- `ROADMAP.md` M2/M6 체크박스 3곳에 `RC-1` 경고/각주 추가(→ 이후 해결
  표시로 갱신).
- `.claude/README.md`/`project-context.md`의 `qa-request/` 서술을 round2
  진행 중 상태로 갱신(→ 이후 완료 상태로 갱신).

---

## 진행 로그

**2라운드(2026-08-18) — `:List` reconcile + `recompute` 손 트레이싱, `reference/`
표본 대조, `ROADMAP.md` 정합성 확인, 그리고 같은 날 후속 세션에서 `RC-1`
해결까지 완료.** 1라운드가 "아직 안 본 것"으로 남겨둔 항목 중:

- `slot-plan.md`의 `:List` 내부 — **트레이싱 완료**(위 "SL" 절).
- `dispatch-core-plan.md`의 `recompute` — **트레이싱 완료, `RC-1` 발견 →
  같은 날 Blocker 게이팅 설계로 해결**(위 "해결 — Blocker 게이팅" 절).
- `reference/` — **표본 점검 완료**(전수는 아님, 위 참고).
- `research/` 13개(1라운드 기록 당시 11개였으나 같은 날 세션 중
  `fastscroll-plan.md`/`spring-plan.md`가 추가돼 지금은 13개 —
  정확한 개수는 `research/` 폴더 자체가 소스) — **이번 라운드에서도 제외**,
  확정 전 문서라 우선순위 낮음(`.claude/README.md`의 `research/` 표 참고).
- 루트 `ROADMAP.md` 마일스톤 분할 — **확인 완료**(위 "ROADMAP.md 마일스톤
  정합성" 절).

**남은 일**: 없음 — `RC-1`까지 닫혀 2라운드 자체가 완료됐다. 3라운드가
필요해지면(예: 이번에 새로 들어간 `attachSlot`/`recompute`/`Blocker`
의사코드를 다시 손으로 트레이싱하는 검증) 새 파일
`pre-implementation-qa-round3.md`를 만들 것.
