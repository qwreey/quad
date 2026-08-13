# 2026-08-13 열네 번째 세션 — 0-Z(`Attribute:GetKey`) 확정, 하강 diff 재디스패치 전면 반영, Tag/Attribute를 quad-base로 재배치

**한 줄 요약**: 사용자가 `Attribute:GetKey(name)` 아이디어를 제시하며 0-Z를
다시 열었고, 트레이싱으로 검증한 뒤 **그룹 전용 키 + 이름 claim**으로
확정 → 그 김에 **0-A(하강 diff 재디스패치)까지 base 전면 반영 + 디스패치
코어 분리(`dispatch-core-plan.md` 신설) + Tag/Attribute 패키지 재배치**를
한 패스로 처리하고 커밋. **M0 착수를 막는 결정이 이제 하나도 없음.**

---

## 1. 시작 — 사용자 문제 제기

> "Attribute 에 대해서 말이지, 우린 이전의 결정을 다시 돌아봐야할 필요가
> 있는듯. `Attribute:GetKey(name)` 구현으로써 '조용한 문제 없음' 을
> 해결할 수 있을것으로 보이는데. 한번 확인해볼래?"

`question.md` 0-Z(Attribute 이름 소유권)는 여섯 번째 세션에 사용자가
"다음 세션에 직접 물리적으로 스케치하며 심층 분석"으로 명시 이관해둔
최우선 항목이었고, 그때의 잠정 방향은 **(a) 이름별 claimant `Relate`를
Attribute 안에 두기**였음.

## 2. 검증 — 문제를 두 갈래로 분해

| | 증상 | 하강 diff 모델에서 |
|---|---|---|
| **C1 그룹 A ↔ 그룹 B** | 같은 이름 | 둘 다 `StoreBind` → "같은 핸들러"로 조용히 인계 + A 클로저가 B 걸 철거(교차 오염) |
| **C2 그룹 ↔ 직접 쓰기** | 같은 이름 | 핸들러가 다름 → `retractFrom` 후 조용히 교체 |
| **C3 같은 그룹 객체 두 자리** | 같은 이름 | 키가 같아 수렴 → C1과 동일 |

**핵심 발견 — 권고안 (a)는 C2를 못 잡음.** 직접 쓰기는 그룹 코드를 아예
안 지나가서 그룹 쪽 레지스트리에 등록될 자리가 없고, 두 경로가 실제로
만나는 유일한 지점인 `AttributeKeyHandler`에서는 공개 캐시 키를 쓰는 한
`k`가 **같은 객체**라 소유자를 구분할 방법이 원천적으로 없음. 옛 모델에선
Dispatch의 점유 체크가 이걸 대신 잡아줬는데, 하강 diff에선 점유가 정상
상태라 그 체크 자체가 성립하지 않음.

**그래서 `GetKey`가 필요한 이유가 분명해짐**: 전용 키를 쓰면
- 체인이 소유자별로 갈려 **교차 오염이 구조적으로 불가능**해지고,
- 소유권이 **키 identity**로 표현되므로 말단 핸들러가 "이 이름을 지금
  누가 잡고 있나"를 단방향 맵 하나로 판정할 수 있음(그룹인지 직접
  쓰기인지 알 필요조차 없음).

즉 정확히는 **`GetKey`(교차 오염 제거) + 이름 claim(감지)** 두 조각이
한 세트. `GetKey`만으로는 두 소유자가 각자 `setAttribute`를 쏘는
flip-flop이 조용히 남음.

**순서 검증**(하강 diff에서 "해제 → 재클레임"이 항상 보장되는가):
같은 핸들러 재프로세스는 `slot.retractor(v)` → `h.process(...)`,
핸들러 교체는 `retractFrom`(꼬리부터) → `process` — 어느 경로든 옛 claim
반납이 먼저. `5 → None → 5`처럼 체인 깊이가 오가는 경우도 인덱스가
바뀌는 자리에서 `retractFrom`이 먼저 돌아 동일. `State<Modifier>`가 이미
차단돼 있고 배열 위치는 정적이라, 위치를 가로지르는 "새 소유자 먼저
claim" 경로도 없음.

**남은 구멍으로 보고한 것**: (1) `GetKey`를 공개 API로 내면 사용자가 그
키를 다른 자리에 다시 놓아 수렴시킬 수 있고 그건 claim(키 identity 기준)
으로도 못 잡음 → **사용자가 "비공개로 안 내도 될듯"으로 확정**, (2)
base/roblox 패키지 경계, (3) `Attribute.Merged`의 이름 중복이 dispatch
이전 단계라 claim이 못 잡음(→ 새 열린 질문으로 등록).

## 3. 사용자의 두 번째 제기 — 패키지 배치가 이상하다

> "Attribute 는 왜 quad-base 인지 모르겠습니다. 사실, Attribute 랑 Tag
> 모두 다른 곳에서도 사용할 수 있거나 없거나 해서, 그냥 quad-base 에 있고,
> set 메커니즘(최종 inst:Set... 와 Tag 제거 추가) 부분만 quad-roblox 에
> 작성하는게 좋을수도 있어보여요. 왜냐하면 웹에도 className, data-
> attribute 가 있습니다. (...) 안 그럼 다시 재구현 될 부분이 너무 많은것
> 같은 느낌."

동의. 당시 배치는 **알고리즘 전체가 quad-roblox, 값 타입만 base**였는데
실제로 엔진에 종속된 건 마지막 한 줄뿐:

| 층 | 내용 | 엔진 종속? |
|---|---|---|
| 값 타입/API | `Tag(...)`, `Attribute(...)`, `AttributeKey(name)`+weak 캐시 | ✗ |
| 알고리즘 | Tag 참조 카운트, 그룹 위임, **이름 claim**, `None` 처리 | ✗ |
| 실행 | `AddTag`/`RemoveTag` / `SetAttribute` | **✓ 3줄** |

`architecture.md`가 이미 *"pluggable 디스패치 엔진 자체도 인터페이스로
base가 소유 — 엔진마다 큰 구현을 중복하지 않기 위함"*이라고 못박아뒀는데
Tag/Attribute만 그 원칙 밖에 있었음. 선례도 있음 — `LifetimeHandle`이
base엔 인터페이스, quad-roblox엔 gcconn 구현으로 갈려 있고 주입은
`RobloxFactory(BaseModule)` 뮤테이션. **`addTag`/`removeTag`/`setAttribute`는
그 목록에 3개를 더하는 것뿐, 새 메커니즘이 아님.**

세부 합의:
- **`addTag(inst, names: {string})`** — vararg가 아니라 테이블. 근거는
  열다섯 번째 세션에 `Tag:Added`가 vararg → `string | {string}`으로
  되돌아갔던 것과 같음(`table.unpack`이 tail 위치에서만 완전히 펼쳐짐 +
  대량 이름에서 unpack 한계). 웹 `className` 배치 갱신 요구도 테이블로
  충족됨. **사용자 동의**.
- **타입 패밀리는 갈림** — 제네릭 `AttributeKey<<T>>`와 스칼라 3종은
  base, `Color3Attribute`류는 백엔드. 사용자: "그건 D/DI 쪽에서 각자
  구현임. 타입 쪽은 그쪽에서 처리하면 되는것 같고".
- **미주입 백엔드 실패 모드** → 사용자가 더 나은 안을 제시:

> "그렇다면 failback... 이름의 아주 낮은 우선순위의 요소,
> PRIORITY_FAILBACK 정도를 잡아두는게 좋겠네요. 그건 base 에서
> 주입해버려도 되고, 위에서 처리되면 상관 없게 잘 처리되니까요."

→ **`HANDLER_PRIORITY_FALLBACK`** 신설(기존 `HANDLER_PRIORITY_*` 패밀리에
추가, 철자는 영어 표준형 FALLBACK으로 정규화). base 제공 핸들러는 이
밴드에 등록하므로 백엔드가 평범한 우선순위로 자기 핸들러를 등록하면
언제나 이김 — 비활성화나 등록 순서 조정이 필요 없음. op 자체가 없는
백엔드에서는 base 스텁이 명확한 에러를 냄.

## 4. 반영 — 한 패스로

사용자 지시: *"모두 제 생각과 같으니까, 그렇게 처리해도 좋아요. 다만
이전처럼 많은 루프를 돌며 문서를 안 고치게, 유의해가며 정리해줘요.
(그걸 위해서 상위 모델로 올리기도 했고.) 처리 후 핸드오버 할거예요.
clear 하게 준비해두고, 커밋하세요."*

### 4-1. `bind-system-plan.md` 2단계 분할 + 재작성

9차 세션이 *"디스패치 코어는 0-Z 확정 시 어차피 전면 재작성 대상이라,
재작성하는 그 패스에서 파일을 가르는 게 총 변경량·실수 위험이 모두
작음"*이라며 의도적으로 미뤄둔 계획을 그대로 실행 — `문제`/`핸들러 계약`/
`확정된 디스패치 모델`/`None 센티널`/`Dispatch는 프리미티브가 아니다`/
`Dispatch 체인`/`Handler 작성 체크리스트`/`Length·Offset`/`store 바인드는
래핑` 블록(1074줄)을 **`base/dispatch-core-plan.md`**로 옮기고 새 모델로
재작성. `bind-system-plan.md`는 **2291 → 1213줄**(반응형 코어 + 인체공학).
(커밋 `69466ab` 메시지엔 이 숫자가 "2263→1219"로 잘못 적혀 있음 —
분할 직전/직후가 아니라 어림한 값이었음. 히스토리 재작성 대신 여기 정정.)

인바운드 참조는 `doc-check.py` 출력을 그대로 입력으로 삼아 기계적으로
고침(파일별 라인 지정 치환) — 15개 파일 30여 곳.

### 4-2. 하강 diff 모델의 실제 내용

```lua
-- chains[inst][k][index] = { handler = h, retractor = fn }
function Dispatch.process(inst, k, v, index)
    local list = <확보 + chains 등록>          -- 순서 규칙 그대로(h.process 前)
    local slot, h = list[index], Dispatch.getHandler(inst, k, v)
    if slot ~= nil and slot.handler == h then  -- (A) 같은 핸들러
        slot.retractor(v)                      -- v는 isHandlable(v) 보장됨
        slot.retractor = h.process(inst, k, v, index)
    else                                       -- (B) 다른 핸들러/빈 자리
        Dispatch.retractFrom(inst, k, index)
        list[index] = { handler = h, retractor = NOOP }
        list[index] = { handler = h, retractor = h.process(inst, k, v, index) }
    end
end
```

**이 세션에서 새로 도출한 귀결 — `retractFrom`이 3-인자가 됨.** 값을
넘기는 경로가 (A) 분기 하나로 통일되면서 외부가 힌트를 만들어 넣을 자리
자체가 사라짐 → 옛 결함(래퍼/센티널이 힌트로 새는 것)이 **구조적으로
재발 불가**. 설계안 원문(6절)엔 4-인자 `retractFrom(inst,k,index,nil)`이
그대로 남아 있었는데, 모델의 필연적 귀결이라 판단해 3-인자로 정리하고
핸드오버에 명시.

같이 폐기/갱신된 것:
- `isX(hintValue)` 방어 가드 **일반 규칙 폐지**(타입이 계약으로 보장됨)
- "`hintValue`는 직속 1단계에만, 깊은 인덱스는 `nil`" 캐비엇 **삭제** →
  각 레벨이 자기 값을 받으므로 `State<State<Tag>>`에서도 깜빡임 방지 유효
- Dispatch의 **점유 체크(소유권 감지) 폐지** → 필요한 도메인(Attribute)이
  직접
- Handler 작성 체크리스트 2·3번 전면 교체, 8번(중간 노드는 `inst`에
  손대지 않는다 + 항상 재위임) 신설

### 4-3. 반영 대상 문서 (배너 7개 + 인덱스 레이어)

`base/`: `dispatch-core-plan.md`(신설) / `bind-system-plan.md` /
`attribute-plan.md` / `tag-plan.md` / `slot-plan.md` / `ref-plan.md` /
`architecture.md`(소스 트리 포함) / `module-lifecycle-plan.md`(주입 op
목록) / `onchange-plan.md`(AttributeKey 위치 정정) / `relate-plan.md`
문구.
루트: `ROADMAP.md`(M0/M2/M4/M6/M10 배너·체크리스트) / `CLAUDE.md` /
`HUMAN_TODO.md`.
인덱스/질문: `.claude/README.md`(행 5개 갱신 + 신설 2행) /
`question.md`(최우선 칸 비움) / `archive/question-resolved.md`(0-Z/0-A
해소 마킹).
아카이브: `research/dispatch-redispatch-diff-plan.md` →
`archive/dispatch-hintvalue-model-reversed.md`(옛 모델 골자 + 폐기된
규칙 목록을 머리에 추가).

### 4-4. 스파이크 상태 갱신

`04`(체인/`retractFrom`)와 `19`(소유권/참조카운트)가 **옛 모델을 검증
중**이라 `done/` → `rewrite-required/`로 이동. "코드가 깨진" 게 아니라
"설계가 바뀐" 경우라 STATUS.md에 그 구분을 명시하고, 각각 무엇을
살리고 무엇을 바꿔야 하는지 적음(`04`의 `chains:SetStrong` 순서 음성
대조군은 새 모델에서도 유효 → 살릴 것).

## 5. 새로 연 것 / 남은 것

- **새 열린 질문 1개(사소)**: `Attribute.Merged`의 이름 중복 —
  `:NameMap()` 평탄화가 dispatch 이전이라 이름 claim이 못 잡음.
  error로 갈지 "뒤가 이긴다"를 의도된 override로 볼지 사용자 확인
  대기(`question.md` 3번).
- **용어 대기열 1개**: 클로저 인자 이름 `hintValue` — 이제 "힌트"가
  아니므로 `nextValue`류가 정확함. 코퍼스 전반에 퍼진 이름이라 이번엔
  안 바꾸고 대기열에만 올림(새로 쓴 의사코드는 `nextValue` 사용).
- **0-W**(같은 `Ref` 객체 이중 배치)는 그대로 열림 — 0-Z가 닫히면서
  형제 프리미티브 표에서 `Ref`만 유일하게 비게 됐고, Attribute가 간
  "국소 레지스트리 + 즉시 error" 모양이 자연스러운 선택지라는 점을
  질문 문서에 덧붙임.
- `doc-check.py` **ERROR 0** 유지 확인.

---

## 6. 후속 리뷰 라운드 (2026-08-14, 다른 에이전트 감사 + 사용자 트레이싱)

커밋 `69466ab`를 다른 에이전트 셋이 감사하고 사용자가 직접 트레이싱한
결과를 받음. **핵심 알고리즘(하강 diff, 인덱스 체인)에는 버그 없음**으로
확인됐고, 의사코드/문서 정합성에서 **실제 결함 3건 + stale 참조 다수**가
나와 전부 수정:

**1. `nameClaims`가 `Relate`의 3-인자 계약을 위반** (실제 버그)
`GetStrong(inst)`/`SetStrong(inst, claims)`로 1·2-인자를 쓰고 있었음 —
`relate-plan.md`가 확정한 API는 항상 `(inst, key[, value])`. 같은 커밋의
`tagNameMap`은 정확히 3-인자를 쓰고 있어 대조로 바로 드러남.
→ `GetStrong(inst, k.Name)`/`SetStrong(inst, k.Name, k)`로 정정(중간
`claims` 테이블 자체가 없어져 코드도 짧아짐).

**2. `TagHandler`의 서술과 의사코드 불일치** (실제 버그)
`Tag(A)→Tag(B)`에서 생존 이름("selected")을 손 트레이싱하면: 클로저가
`holders[k]=nil`로 홀더를 **비운 뒤** `removeTag` 호출만 skip → 곧이은
`process`가 빈 홀더를 보고 **`addTag`를 다시 호출**함. 문서는 정반대로
"이미 걸려있던 이름은 소유 목록이 안 비어 있어 `addTag` 자체가 안 불림"
이라고 적고 있었음. 엔진이 멱등이라 눈에 안 보였을 뿐, "실제 호출은 진짜
바뀐 이름에만"이라는 이 절의 설계 목표와 어긋남.
→ **생존 이름은 홀더 등록 자체를 유지**하도록 정정(`nextValue`가 그
이름을 `Contains`하면 `continue`). 덤으로 `addTag`도 `removeTag`처럼
**배치 호출**로 바꿈 — `{string}` 시그니처를 도입한 근거(웹 `className`
일괄 갱신)와 코드가 안 맞던 것도 같이 해소.

**3. 그룹 `process`의 부분 실패 경로가 문서에 없었음** (문서 갭)
이름 순회 도중 소유권 충돌 `error`가 나면 클로저가 안 만들어져 앞서
등록된 이름들이 그 사이클에 회수되지 않음. **다만 감사가 말한 "영구
누수"보다는 좁음** — `nameClaims`/`chains`가 `inst`에 weak라 인스턴스
GC와 함께 사라지고, 재프로세스 시 이미 claim된 이름은 `cur == k`라
에러 없이 통과해 **같은 자리에서 같은 error로 반복 재현**됨(조용한
오작동이 아님). 그래서 롤백 장치는 안 넣고 그 경로를 명시적으로
문서화, 원자적 롤백 여부는 `question.md` 3번에 열어둠.

**4. 문서 분할 후 stale 절 참조 20여 곳** — `doc-check.py`의 사각지대였음
`REF` 정규식이 **줄 단위**로 돌아서 파일명과 "절 제목"이 줄바꿈에 걸친
자연스러운 인용(`` `base/\nbind-system-plan.md`의 "Length/Offset" ``)을
통째로 놓치고 있었음. 이번 분할뿐 아니라 **9차 세션의 1단계 분할 stale도
같은 이유로 계속 숨어 있었음**(`event-plan`/`ref-plan`/`typing-limits`로
간 절들).
→ 검사기를 **파일 전체 스캔 + 개행 허용**으로 고치고(줄 번호는 매치
오프셋에서 역산), 새로 드러난 WARN을 기준으로 30여 곳을 기계적으로
정정. WARN 56 → 120건으로 늘었다가 정정 후 101건(남은 건 의역 인용 등
판단이 필요한 것들).

**5. 사소한 것**: 커밋 메시지의 줄수(2263→1219)가 실제(2291→1213)와 다름
(히스토리 재작성 대신 위 4-1에 정정 기록), `CLAUDE.md`가 `04`만 언급하고
`19` 이동을 빠뜨린 것, `luau-test/README.md` 상단 요약표가 STATUS.md와
어긋난 것 — 전부 수정.

**교훈**: 문서 분할 시 stale 참조는 "검사기가 ERROR 0이면 됐다"로 끝나지
않음 — **검사기 자신의 사각지대**를 먼저 의심할 것. 이번엔 감사가 그
사각지대를 짚어줬고, 고치자마자 1단계 분할의 오래된 stale까지 같이
드러났다.
