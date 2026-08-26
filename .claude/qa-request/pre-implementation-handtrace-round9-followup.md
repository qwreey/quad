# 9라운드 손 트레이싱 발견 — **사용자 결정과 반영 결과**

**무엇인가**: `.claude/qa-request/pre-implementation-handtrace-round9.md`의 발견
(`H-124`~)을 사용자와 대화형으로 처리한 결과. **결정의 소스는 이 문서**이고,
발견 원문·값 트레이스·실측 전사·"이상 없다고 확인한 것" 목록은 그 파일이
소스다(여기서 다시 서술하지 않음).

**진행 방식**: 그 문서 §4가 배치 회신용으로 묶어둔 **결정 문항 Q1~Q10** 순서를
따른다. 8라운드와 같다.

**⚠️ [2026-08-27 기준] 진행 중이다.** 아래 표가 어디까지 왔는지의 소스다.
처음엔 "문항을 다 처리한 뒤 일괄 반영"으로 잡았으나, Q1~Q3가 같은 `slot-plan.md`
구간에 몰려 있고 서로 얽혀(Q2의 생성자 이동이 Q3의 `_elemIndex` 삭제와 같은
줄) 사용자 지시로 **Q3까지 먼저 반영**했다. Q4 이후는 결정 뒤 반영한다.

| 문항 | 발견 | 상태 |
|---|---|---|
| Q1 | `H-124` `recompute` 루프 순서 | ✅ **확정** — (a), `continue` 형태 |
| Q2 | `H-125` 재마운트 캐시 | ✅ **확정** — 생성자 이동 + (c) 순서 + `_destroyed` |
| Q3 | `H-126` splice 빈자리 (+ `H-137` 소멸, `H-141` 신설) | ✅ **확정** — `element → index`는 `bk`가 소유, 토큰 폐기 |
| Q4~Q10 | `H-127`~`H-133` | ⏳ 대기 |
| — | `H-134`~`H-140` | ⏳ 대기(레인 B·부수 발견) |

**[2026-08-27] Q1~Q3는 `base/`·`ROADMAP.md`에 반영했다** — 반영 중 드러난 것과
열어둔 확인은 아래 "반영 기록" 절.

---

## Q1 — `recompute`의 되감기 판정을 `lengthList[i]` 읽기 **앞**으로 (`H-124`, 확정)

**결정: (a).** 되감기 판정이 먼저 오고, `local v = bk.lengthList[i]`와 `sum`
누적은 되감기가 **없을 때만** 돈다. 형태는 `continue`.

**사용자 논거** — 갈래 (a)를 고르면서 코드 모양까지 정정했다:

> *"단순히 sum 을 안 만들어도 되는게, 되감는다면 sum 이 이전걸로 구해져서 새로
> 계산한 sum 자체를 안 씀. v 얻고 sum 계산하는걸 else 아래 두는것도
> 괜찮아보이는듯. 컨티뉴나 else 아래나 둘 다 괜찮은데, 맥락 상 컨티뉴를 두고
> 아래 두는게 좋아보임."*

확정된 모양:

```lua
        local abs = Dispatch.getOffsetAt(ownerKey, i)
        bk.offsetSetUpTo = i
        if offset ~= None and offset:Get() ~= abs then
            offset:Set(abs)                    -- ← 사용자 코드가 돌 수 있는 자리
        end
        if bk.offsetSetUpTo < i then           -- ⭐ 되감기 판정이 **먼저**
            i = math.max(bk.offsetSetUpTo, 1)
            sum = prefix[i]
            continue
        end
        local v = bk.lengthList[i]             -- 되감지 않을 때만 읽는다
        sum += (if isState(v) then v:Get() else v)
        i += 1
```

- **무엇이 깨져 있었나**: 옛 순서는 `lengthList[i]` 읽기·누적이 되감기 판정보다
  **한 줄 앞**이었다. `offset:Set(abs)` 안의 사용자 코드가 요소를 제거해
  `i > bk.N`이 되면(커서가 마지막 자리일 때 아무 자리나 제거, 또는 `rawSplice`/
  `rawClear`의 다중 제거) `sum += nil`로 죽고, 그 `error`가
  `recomputeBlocker:On()`과 `OffWithoutEmit()` 사이에서 나므로 **그 owner의
  차단기가 영원히 켜진 채 남는다**(그 Slot의 레이아웃이 영구 동결 — `H-87`의
  "독 든 Blocker"와 같은 부류).
- **`H-113`의 *"`sum`은 안 낡는다"* 논증은 유지된다** — 그 논증의 근거는
  "`lengthList[i]` 읽기가 `Set` 뒤"인데, 되감는 경우엔 그 자리를 **재방문**하며
  읽으므로 여전히 `Set` 뒤다. 오히려 옛 요소의 길이를 한 번 더 더했다가 버리는
  낭비가 사라진다.
- **제거가 커서보다 뒤(`p > i`)면 되감기 자체가 안 걸린다** —
  `math.min(offsetSetUpTo, p-1)`에서 `p-1 ≥ i`이므로 판정이 거짓이고,
  그때는 `bk.N ≥ p-1 ≥ i`라 `lengthList[i]`가 살아 있다. 즉 이 재배치가 정상
  경로를 안 바꾼다.
- **실측**(9라운드 참조 구현 `ref9/`): 이 처방 전엔 `d10_remove_at_tail.luau`가
  `attempt to perform arithmetic (add) on number and nil`로 죽었고, 처방 뒤
  **정상 종료 + 최종값 정확**(`s2.Offset 0 / s3.Offset 1 / O.Length 2`).
  `d11_two_ops`(2-연산 경로) · `d13_splice_at_cursor`(커서 자리 splice) ·
  `d14_baseline`(형제 offset 전파) 전부 회귀 없음.

**반영 대상**: `base/dispatch-core-plan.md`의 `recompute` 의사코드(+ 되감기 절의
근거 문장 — "1로 클램프한다" 주석은 그대로 유효하다).

---

## Q2 — 재마운트: **`Offset`/`_baseObserver`를 생성자로 올리고**, 순서는 (c), 파괴는 `_destroyed` (`H-125`, 확정)

**결정: 문항의 (a)/(b)/(c) 중 (c)를 고르되, 사용자가 그보다 나은 형태를
제시해 그쪽으로 확정했다** — `slot.Offset`과 `slot._baseObserver`를 **Slot
생성자에서** 만든다. 그러면 (c)가 고치려던 순서 문제의 **분기 자체**가 없어진다.

### 왜 (a)가 아닌가 — 그리고 문항의 근거 하나는 틀렸다

- 사용자가 (a)를 반대한 근거는 *"`:List`인데 어디선가 이미 그려진 적 있다면 …
  offset 설정 결과가 전파될 방법이 없음. layoutorder 등을 설정하는 유저 함수
  부분에 문제가 있을것"*이었는데, **그 부분은 실측에서 성립하지 않았다.**
  `setOffsetSource`의 `S.Offset:Set(newBase)`는 전파 루프를 정상적으로 돌고,
  유저 체인의 말단 Observer는 **요소 자신의 인스턴스**에 `bindLifetime`돼 있어
  (언마운트는 요소를 파괴하지 않고 `unbindLifetime`도 안 한다) `canExecute`가
  참이다. 건너뛰어지는 건 `_baseObserver` 하나뿐이다.
  → **그래서 `H-125`의 피해 범위는 "자식 서브트리 전체"가 아니라 *부기를
  경유하는 중첩 Slot의 `Offset`*으로 좁혀진다**(발견 문서에 정정 반영).
- **(a)를 기각한 실제 이유는 소스 이원화**다. *"베이스가 바뀌면 1번부터
  무효화"*(`H-3`의 3번)의 코드 경로는 `_baseObserver` 콜백 하나인데, (a)는 같은
  규칙을 `materializeSlotTree` 진입부에 한 벌 더 둔다 — 그 절의 존재 이유가
  정확히 *"표는 산문으로만 있었고 실제 코드 경로가 하나도 없었다"*를 닫는
  것이라, 소스를 둘로 늘리는 건 후퇴다.

### 확정된 것 (넷)

**1. `Slot` 생성자가 `Offset`과 `_baseObserver`를 만든다** — `Length`와 같은 자리.

> **사용자**: *"slot 자체를 생성할 때 offset/observer 이 같이 생성되지 말아야할
> 이유가 있음? 우린 stale 한 offset 을 허락하고 기본 생성에 0 이기 때문에, 초기
> 생성에 넣는거로 해줄 순 없는거야?"* / *"baseObserver 자체도, offset 에서
> 나므로, 초기에 생성하니, 같이 생성하면 돼. **단순히 bind/unbind 로 관리해야지
> 그것 자체를 제거/생성 하는건 안 맞아보임.**"*

- **새 결정이 아니라 이미 확정된 것의 반영이다** — `SL-75`/`D-60`이
  *"마운트 전엔 `nil`이 아니라 `0`이고, 언마운트해도 `nil`로 되돌리지 않는다"*로
  확정했는데 의사코드만 lazy(`slot.Offset or Source(0)`)로 남아 산문과 어긋나
  있었다. `Length`와의 대칭도 맞는다(둘 다 공개 필드인데 하나만 생성자에서 나던
  비대칭).
- **`H-125`가 살던 분기가 사라진다**: 옛 `materializeSlotTree`는 첫 마운트(생성
  → "등록 즉시 1회"가 **우연히** 두 필드를 0으로)와 재마운트(`bindLifetime`만 →
  **바인드는 발화가 아니라서** 안 만듦)로 갈렸고, 그 비대칭이 버그의 집이었다.
  이제 갈래가 없다.

**2. `materializeSlotTree`의 순서** — 게이트와 바인드가 emit **위로**:

```lua
slot._physicalTarget = physicalTarget
local blocker = getBlocker(slot)
blocker:On()                                                   -- ← emit 위로
bindLifetime(physicalTarget, slot._baseObserver)               -- ← emit 위로(생성 분기 없음)
Dispatch.setOffsetSource(ownerKey, position, slot.Offset)      -- 여기서 베이스가 바뀐다
```

- `blocker:On()`도 같이 올려야 한다 — 안 그러면 emit이 깨운 콜백이 게이트 없이
  `recompute(slot)`를 완주하는데, 그 시점 `bk(slot)`은 **언마운트 전 옛
  부기**(`Relate(slot)` 위에 살아남는다)라 옛 `N`·옛 자식 목록으로 돈다.
- **간섭 없음**: 이 Blocker는 그 Slot 자신의 것이고 `setOffsetSource`는 **부모
  owner의** blocker를 본다. `getOffsetAt`은 `lengthList`를 직접 읽으므로 게이트와
  무관하다(*"Blocker가 막는 건 `recompute`지 부기 등록이 아니다"*).
- **기존 근거 유지**: *"`_baseObserver` 생성이 `blocker:On()` 뒤인 게
  중요하다"*(등록 즉시 1회가 자식 등록 전에 `recompute`를 태움)는 그대로다 —
  생성이 생성자로 갔고 **바인드도 `blocker:On()` 뒤**다.
- `local offsetSource = slot.Offset or Source(0)`과 `slot.Offset = offsetSource`
  두 줄, 그리고 `if slot._baseObserver then … else … end` 분기가 **전부 삭제**된다.

**3. `_baseObserver` 콜백 머리에 미실체화 가드**:

```lua
if slot._physicalTarget == nil then return end
```

- 없으면 생성자의 "등록 즉시 1회"가 **모든 Slot**에 대해 `getBookkeeping`을
  강제 호출해 `bk` + `recomputeBlocker`(Blocker 객체)를 **eager 생성**한다 — 한
  번도 마운트 안 되는 Slot까지. 가드를 넣으면 실측상 `books`에 항목이 안 생긴다.
- 의미도 맞다 — 미실체화 Slot의 베이스 변경엔 할 일이 없다.

**4. 파괴는 `slot._destroyed` 플래그가 말한다 — 핸들은 안 지운다.**

> **사용자**: *"`slot._baseObserver` 가 두 일을 하는건 위험함. 이전에도
> `invalidAfter` 처럼, 두 일을 겸하는걸 만들다가 사고가 난 적 많아."* /
> (이름) *"`dispose` 는 형질이 다른 엔진 요소를 포함할 수 있는 것에 대한 공동
> 소멸자인 네이밍. 자신이 삭제되고 그 여부는 `destroy` 가 맞아보이고, `dispose`
> 는 슈거로써 `destroy` 와 별도의 맥락에서 해석해야해."*

- `destroySlotTree`가 `_baseObserver`/`_listObserver`/`_listActivated`를 `nil`로
  지우던 것을 **전부 그만둔다 — `unbindLifetime`만 한다.** 그 nil이 들던 근거
  (*"안 풀면 `gchold[physicalTarget]`이 observer를 계속 강하게 붙잡는다"*)는
  실은 **`unbindLifetime`이 하는 일**이고, nil 대입은 slot → observer 참조
  하나를 놓는 것뿐인데 slot 자신이 쓰레기라 그건 공짜다. 사용자가 좀비 slot을
  계속 들고 있어도 observer는 unbind 상태라 `canExecute`가 거짓이라 발화하지
  않는다.
- **세 필드가 겸하던 뜻을 플래그가 가져간다.** `_listObserver == nil`은 원래
  *"`data`가 reactive가 아니다(plain table)"*라는 자기 의미가 있고(그걸 놓쳐서
  `activateList` 재마운트 분기에 `bindLifetime(nil)` 버그가 났었다),
  `_listActivated == nil`은 *"아직 최초 population을 안 했다"*였다. 거기에
  "파괴됨"을 겹쳐 싣던 게 `invalidAfter`와 같은 모양이었다.
- **`_baseObserver`의 불변식이 한 문장이 된다**: 생성자에서 나서 Slot과 함께
  죽는다, **절대 `nil`이 아니다.** `Length`/`Offset`과 같은 층위.
- **파괴된 Slot의 재사용은 error**(`level 2`, 메시지는 영어 —
  `base/architecture.md`의 error 계약). 지금까지 **어디에도 안 적혀 있던
  자리**다 — `slot-plan.md`는 *"언마운트된 Slot은 그대로 재사용 가능"*이라고만
  하고 파괴 쪽은 침묵했으며, `destroySlotTree`가 `_mounted`를 `false`로
  되돌려놔서 *"마운트된 Slot의 재마운트는 즉시 throw"* 가드에도 안 걸렸다.
  실제로 `destroySlotTree`는 **`_elements`를 안 비운다**(요소만 `nativeDispose`)
  — 파괴된 Slot은 파괴된 Instance를 든 좀비이고, 재마운트하면 죽은 Instance를
  다시 `Parent` 대입한다.
  - **`attachSlot`/`materializeSlotTree` 진입**에 가드 — 필수.
  - **공개 CRUD 진입**(`:Add`/`:Remove`/…)에도 가드 — `_elements`가 안
    비워지므로 죽은 Slot에 `Add`하면 **조용히** 좀비 배열이 자란다.
    `_crudUsed`/`_listed` assert 옆에 한 줄.
- **이중 `dispose`는 얼리리턴 no-op** — teardown 경로가 겹치는 건 실재하고
  GC-native 기조와 맞는다. 막는 것은 **마운트/CRUD**뿐이다.
  플래그를 세우는 것도 얼리리턴도 **`destroySlotTree` 쪽**에 두므로 다형
  진입점 `dispose(value)`는 그걸 공짜로 물려받고 별도 가드가 필요 없다.

### 실측

9라운드 참조 구현(`ref9/`)에 `none`/`(a)`/`(c)`/`ctor` 네 변형을 넣고 같은
매트릭스를 돌렸다 — `O = { a, b, S }`, `S = { C(중첩 Slot), plain }`(베이스 2)를
마운트 → 언마운트 → 베이스 0인 다른 owner에 재마운트:

```
[none] 재마운트: S.Offset=0  C.Offset=2 (기대 0)  userLO=1 (기대 1)   ❌
[a]    재마운트: S.Offset=0  C.Offset=0          userLO=1            ✅
[c]    재마운트: S.Offset=0  C.Offset=0          userLO=1            ✅
[ctor] 재마운트: S.Offset=0  C.Offset=0          userLO=1            ✅
(넷 다) 앞에 z 삽입 후: S.Offset=1  C.Offset=1  userLO=2             ✅
```

`ctor` 변형으로 `d14`/`d10`/`d11`/`d13` 회귀 없음. 미실체화 Slot 생성 직후
`books`에 항목이 안 생기는 것(3번 가드), 미실체화 `rawAdd`가 그대로 얼리리턴하는
것도 같이 확인.

### 반영 대상

- `base/slot-plan.md` — `Slot(initial)` 생성자(필드 목록에 `Offset`/`_baseObserver`
  추가) · `materializeSlotTree`(순서 + 분기 삭제 + 콜백 가드) ·
  `unmountSlotTree`/`destroySlotTree`(핸들 보존, `_destroyed` 세팅, 이중 호출
  얼리리턴) · 공개 CRUD 가드 · *"언마운트된 Slot은 그대로 재사용 가능"* 절에
  파괴 쪽 계약 신설 · **`rawAdd`의 `_physicalTarget == nil` 얼리리턴은 유지하되
  근거 문장 정정**(*"`slot.Offset`이 아직 nil이라 `getOffsetAt`에서 즉시
  죽는다"*는 이제 거짓 — 남는 근거는 중첩 Slot의
  `attachSlot(element, nil, …)` → `bindLifetime(nil, …)` 하나다).
- `base/dispatch-core-plan.md` — `Slot.Offset` 서술(*"마운트 시점에
  `setOffsetSource`가 등록하는 그 Source를 `self.Offset`으로도 저장"*)을 생성자
  기준으로.
- `ROADMAP.md` — M6의 `Slot.Offset` 체크박스, 그리고 아래 `H-140`.

### 부수 발견 — `H-140`(🟢, 이 대화에서 나옴)

**`ROADMAP.md:1124`가 아직 *"해제 시 `slot.Offset = nil`"***. `SL-75`/`D-60`이
전면 정정한 문장인데(`slot-plan.md:3593`이 *"옛 서술은 … 그러면 포탈이
무너진다"*로 폐기) **구현자가 실제로 보는 체크박스**에 살아남았다. 그대로 짜면
포탈 구독자가 영구히 끊기고 이번 생성자 불변식도 같이 무너진다 — 9라운드
사냥 목록 #7(*"`ROADMAP.md` 체크박스가 `base/`보다 낡음"*) 그대로다. 발견
문서에 `H-140`으로 등록했고 처분은 정정 하나다(판단 불필요).

---

## Q3 — `element → index`는 `bk`가 소유한다; 토큰 폐기 (`H-126` + `H-137` + `H-141`, 확정)

**결정: 문항의 (a)/(b)를 넘어 원인을 닫았다.** Q3의 표면 증상(`spliceArraysUp`이
비운 자리의 `observers`/`tokens`)을 파다가, **같은 뜻의 맵이 두 층에 있고 그
중 하나(`bk.tokens`/`bk.indexOfToken`)는 사용자가 정한 적 없는 것**임이 드러났다.

### 무엇이 있었나 — `token`의 출처

- 7라운드 `H-102`의 사용자 지시는 *"이미 `slot._elemIndex`: realElem → index 를
  관리중"* / *"그것을 dispatch 로 격상시키는게 더 나아보이는 지점"* — **요소 →
  인덱스 맵을 Dispatch로 올리라**는 것이었다.
- `base/`에 내려앉을 때 키가 `len`(그 자리의 길이 State)으로 구현됐고, 8라운드
  직전 `/code-review high`가 *"`len`은 자리마다 유일하지 않다"*를 잡으면서 **그
  자리에서 `token = {}`이 발명됐다**(2026-08-25). 원래 키(요소)로 되돌아가는
  대신 새 신원을 만든 것이고, 사용자 인용문은 그 옆에 그대로 남아 승인된
  메커니즘처럼 읽혔다.
- **사용자**: *"내가 등장시킨 적 없는 token 이 나와서 당황스러움"* / *"난 층위 상
  어떠한 값이든, 마운트된 부기객체 -> index(기여량이 아님) 를 얻고자 했음"*.
  "기여량이 아님"이 정확히 어긋난 지점이다 — 구현은 기여량(`len`)을 키로 잡았다.

### 확정된 것

**1. `element → index` 맵은 `bk`가 소유한다 — `bk.indexOfElement`. owner가 Slot이든
`inst`든 규칙 하나.**

> **사용자**: *"slot 이든 inst 든 elem -> index 는 Dispatch bk 에 있어. 클로저가
> 필요한 지점으로 안 보여. 문제의 elem->index 를 누가 관리하느냐가 어디서
> 관리하느냐가 명확하지 않아서 자꾸 사고가 나는듯 한데."*

- **`slot._elemIndex`는 삭제**한다 — 같은 뜻의 맵을 두 층에 두던 것이 사고의
  원인. `indexOfRaw(self, element)`는 `getBookkeeping(self).indexOfElement[element]`
  조회가 되고, `reindexFrom(self, from)`은 **그 맵을 갱신하는 헬퍼**가 된다
  (시프트하는 자리 전부가 부르는 것은 `H-1` 그대로).
- **`bk.tokens`/`bk.indexOfToken`은 삭제** — `token` 개념 소멸.
- **`None`/진짜 `nil` 자리는 기록하지 않는다** — 길이가 상수 `0`이라 지속
  등록(Observer)이 없고, `nil`은 애초에 키가 못 된다. Slot 안에서 요소는
  유일하다(`_elements`엔 `None`이 안 들어가고 `claimOwner`가 이중 배치를 막는다).

**2. `Dispatch.setLength(ownerKey, i, len, anchor, element)` — 5번째 인자는 그
자리의 `inst|slot`.** `gatedRecompute`는 **요소를 캡처**해 `bk.indexOfElement[element]`를
조회한다.

> **사용자**: *"Dispatch.setLength 가 이제 받아야할 것은 inst|slot 이야. 그거 이외
> 클로저로 저걸 해줄 이유가 없어보이는데. 게다가 슬롯 아니면 nil 이 나오는것도
> 이상해."*

- 요소를 캡처하면 **갱신할 것이 없다** — 요소의 신원은 안 변하고, `요소 → index`는
  `reindexFrom`이 자기 이유로 이미 정확하게 유지한다. 위치를 캡처하던 옛
  모양(splice마다 갱신)과 토큰(배열 + 역방향 맵 둘 다 갱신)이 관리하던 것이
  전부 사라진다.
- `element`를 생략한 호출(상수 길이 자리 — plain 요소 없이 `Nil`/`None` 핸들러)은
  지속 클로저가 안 생기므로 캡처한 `i`가 그대로 유효하다. 실제로 `len`이
  State인 호출은 **중첩 Slot의 `.Length`뿐**이고 그때 `element`는 그 Slot
  자신이다.

**3. Q3 본문 — `spliceArraysUp`이 비운 자리는 세 배열 전부 처리한다.**
`lengthList[index] = 0`(`H-5`) · `sourceList[index] = None` · **`observers[index] = nil`**.
`spliceArraysDown`은 당긴 뒤 꼬리(`N`)의 세 자리를 `nil`로. 근거는 `H-126`
실측 — 복사 루프로 짜 `observers[index]`에 옛 값이 남으면 이어지는
`setLength(self, index, …)`의 `oldObserver` 언바인드가 **밀려난 요소의 관측자를
죽인다**(`vacate=false`에서 `B.Offset`이 2에 멈춤).

### 기각된 것 (전부 이 세션에서 제가 냈다가 철회한 안)

- **`observer.pos` / `observer.inst`** — 프리미티브 인스턴스에 임의 페이로드를
  얹는 것으로, **검토 후 안 만들기로 한 `Effect<UD>:Userdata()`/`SetUserdata`를
  다시 여는 문**(사용자: *"그건 닫은 Effect 의 userdata 허용을 거의 여는
  셈이야"*).
- **`setLength`에 조회 클로저 / `subject` 인자** — 소유 층위를 정하는 대신 우회하는
  새 개념. 사용자가 정한 적 없는 이름.
- **토큰 유지(이름만 변경)** — 맵이 두 층에 남는 원인을 그대로 둔다.

### 소멸·신설

- **`H-137` 소멸** — `rawMove`/`rawSwap` 규약의 토큰 누락은 토큰이 없어지며
  발견 자체가 사라진다(규약 4가 이동 구간 전부에 `setLength`를 다시 태워
  `indexOfElement`를 다시 쓴다).
- **`H-141` 🟡 신설** — *확정의 근거로 인용된 사용자 발언이 실제로는 다른 것을
  승인한 것*(토큰 옆의 격상 인용, 그리고 *"splice 요구 목록에 항목이 늘지
  않는다"*는 명분을 구현이 스스로 깬 것). 9라운드 사냥 목록 #1의 인용문 판.

### 반영에서 열어둔 확인 (판단 요청)

- **`H-1`이 `reindexFrom`을 `spliceArrays*`에서 분리한 근거가 소멸한다** —
  *"`spliceArrays*`는 `bk`를 만지므로 실체화된 뒤에만 부를 수 있다"*였는데,
  `getBookkeeping`은 lazy라 절대 `nil`이 아니다. 대신 **미실체화 Slot에 `:Add`만
  해도 `bk`(+ `recomputeBlocker`)가 생긴다**. Q2의 `_baseObserver` 가드가 막은
  것(*모든* Slot의 eager `bk`)과 범위가 다르다(*요소를 넣은* Slot만). 이 정도는
  괜찮다고 보고 반영했다 — 아니면 알려줄 것.
- **쓰기 지점이 둘이다** — 등록은 `setLength`(`bk.indexOfElement[element] = i`),
  이동은 `reindexFrom`. `lengthList`가 `setLength`(등록)/`spliceArrays*`(이동)로
  갈리는 것과 같은 모양이라 그대로 뒀다.

---

## 반영 기록 — Q1~Q3 (2026-08-27)

**바뀐 파일**: `base/dispatch-core-plan.md`(`recompute` 루프 재배치 / `setLength`
5번째 인자 + `bk.indexOfElement` / `H-102` 문단 정정 + `H-141` 배너 / 저장 위치·
초기화 열거 / `_baseObserver` 즉시 발화 주석 / `Slot.Offset` 생성 자리 / `anchor`
절에 `element` 축 추가) · `base/slot-plan.md`(`Slot(initial)` 생성자 /
"파괴된 Slot은 재사용 불가" 절 신설 / `Slot:Add`·`Slot:List` 가드 /
`makeBaseObserver` + `materializeSlotTree` 순서 재배치 / `unmountSlotTree` 흔적
가드 제거 / `destroySlotTree` 핸들 보존·`_destroyed`·이중 호출 no-op / `H-1` 블록·
`H-29` 규약 1·`raw*` 주석·`rawAdd` 배너 근거·`rawReplace`·`indexOfRaw` 정의 /
splice 요구 목록 재작성 + `H-102` 항목 폐기 배너 + `H-132` 개수 제거) ·
`ROADMAP.md`(M3 `setLength` 시그니처·`getBookkeeping` 초기화 / M6 필드 목록·
`H-140`·`_elemIndex` 언급·`Slot.Offset` 체크박스) · 발견 문서(`H-141` 등록,
`H-137` 소멸 표기, `H-125` 범위 정정).

**반영 중 드러난 것 — 사용자가 바꾼 적 없는데 있던 것** (판단 요청 포함):

1. **`token` 자체**(`H-141`) — 위 Q3 절.
2. **`unmountSlotTree`의 `if slot._baseObserver then` 가드** — 옛 lazy 생성의
   흔적. 생성자 불변식("항상 있다")에 맞춰 무조건 호출로. 동작 차이 없음.
3. **`rawReplace`가 맵을 직접 쓴다** — 옛 `self._elemIndex[old] = nil; [new] = index`
   두 줄이 `bk.indexOfElement`로 그대로 옮겨졌다. `setLength(…, newElement)`도
   등록하지만 **미실체화 분기는 `setLength`를 안 부르므로** 직접 쓰기가 남는다.
   쓰기 지점이 `setLength`/`reindexFrom`/`rawReplace` 셋이 됐다 — 규칙("등록은
   `setLength`, 이동은 `reindexFrom`")에서 `rawReplace`만 예외. 괜찮은지 확인
   요청.
4. **`Owned = false`인 Slot은 `_destroyed`가 안 선다** — `destroySlotTree`가
   그 분기에서 `unmountSlotTree`로 빠져 꼬리(플래그 세팅)에 안 닿는다. "파괴
   대신 언마운트만"이라는 그 분기의 뜻과 정합하고(요소를 만든 적 없으니 좀비도
   없다) 재사용도 그대로 가능하다 — 의도대로라고 보고 그대로 뒀다. 확인 요청.
5. **미실체화 `:Add`가 `bk`를 만든다**(Q3 절의 열어둔 확인) — 그대로 반영.
6. `todos.md`의 6라운드 서술(*"`slot._elemIndex` 신설"*)은 역사 기록이라
   이동 표기만 덧붙였다.

**[2026-08-27 사용자 확인] 위 1~5 전부 의도대로.** 원문: (1) *"length,
elem->index 를 위치를 재설정 해준다면 괜찮아"* — `rawReplace`의 직접 쓰기는
"자리는 그대로, 주인만 교체"라 `lengthList`·`indexOfElement` 둘 다 그 자리를
다시 쓰는 것으로 성립. (2) *"owned = false 은 state<Frame> -> slot(single) 형태가
구현되는 것이라 맞아"* — 그 Slot은 요소를 만든 적이 없으니 파괴가 아니라
언마운트이고 `_destroyed`가 안 서는 게 맞다. (3) *"미실체화 add 가 bk 만드는것도
맞아. 그래야 인덱싱 매핑을 만드니까"*. (4) *"slot._baseObserver 는 unbind 만 했고,
nil 로 지우는것만 안 한다면 맞아"*.

**아직 안 한 것**: `/code-review high`, 커밋 — Q4~Q10 반영 뒤 한 번에. README
색인과 `todos.md` 00번 갱신은 감사 1라운드 지적으로 그 자리에서 했다. 감사
루프는 Q1~Q3 반영분에 대해 돌았고 6라운드에서 수렴했다(아래 "감사 루프" 절).


## 감사 루프 (2026-08-27, Q1~Q3 반영분)

관례대로 `quad-doc-auditor` 한 턴에 하나, diff 범위, 라운드마다 각도 변경.

| 라운드 | 각도 | 새 발견 | 처분 |
|---|---|---|---|
| 1 | `base/` 정합성 | 확실 1 · 판단 1 | `todos.md` 00번이 *"아직 안 돌렸다"*로 남아 있던 것 갱신 / README 색인(미뤄둔 것) 그 자리에서 추가 |
| 2 | 인덱스 레이어 + 새 문단 자기모순 | 확실 1 · 의심 1 | `dispatch-core-plan.md`의 Length/Offset 두 API 요약 선언(1347행)이 4-인자로 남은 것 갱신 / `_destroyed` 가드가 `:Add`·`:List` 의사코드에만 있어 CRUD 표 머리에 "mutate 연산 전부" 일반 규칙 한 줄 신설 |
| 3 | `archive/`·`reference/`·`luau-test/`·`audit/` 인용처 + 인용문 역방향 + 옛 발견 번호 재인용 | 확실 3 | `audit/handtrace-round7-reference-impl/README.md` 대조표에 9라운드 행 셋 + *"토큰 역참조"* 각주 / `ROADMAP.md` 머리 배너에 9라운드 소스 한 줄 / `README.md` `slot-plan` 색인 행의 `_elemIndex`에 통합 표기 |
| 4 | 앞 라운드 수정분 자체 + followup/발견 문서 내부 정합 | 확실 1 | `CLAUDE.md`·`project-context.md`(둘 다 `@import`)가 결정 소스로 8라운드까지만 나열 — 9라운드 한 줄 추가. 그 외 앞 수정분·두 문서 내부 정합은 줄 단위 대조로 이상 없음 |
| 5 | 4라운드 수정분 + 델타 밖 `base/` 문서 | 확실 1 · 판단 1 | `README.md`의 `dispatch-core`/`slot-plan` 색인 행에 Q1/Q2 요약 추가 / `architecture.md`의 `Slot.luau` 한 줄에 생성자 필드·`_destroyed` 표기(판단 항목 — 8라운드 행들이 같은 밀도라 넣음) |
| 6 | 5라운드 수정분 + 신설 규칙 문단 | **확실 0** · 의심 1 | *"`Owned=false`는 `_destroyed`가 안 선다"*가 README 요약과 followup에만 있고 `slot-plan.md` 산문엔 없던 것 — 사용자 확정 인용과 함께 명문화. **수렴**(확실 0) |
