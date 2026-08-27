# 9라운드 손 트레이싱 발견 — **사용자 결정과 반영 결과**

**무엇인가**: `.claude/qa-request/pre-implementation-handtrace-round9.md`의 발견
(`H-124`~)을 사용자와 대화형으로 처리한 결과. **결정의 소스는 이 문서**이고,
발견 원문·값 트레이스·실측 전사·"이상 없다고 확인한 것" 목록은 그 파일이
소스다(여기서 다시 서술하지 않음).

**진행 방식**: 그 문서 §4가 배치 회신용으로 묶어둔 **결정 문항 Q1~Q10** 순서를
따른다. 8라운드와 같다.

**✅ [2026-08-27] Q1~Q10·`H-138`·`H-139`·`H-142`까지 전량 처리·반영됐다.** 아래
표가 항목별 상태의 소스다. (경위: 처음엔 "문항을 다 처리한 뒤 일괄 반영"으로
잡았으나, Q1~Q3가 같은 `slot-plan.md` 구간에 몰려 있고 서로 얽혀(Q2의 생성자
이동이 Q3의 `_elemIndex` 삭제와 같은 줄) 사용자 지시로 Q3까지 먼저 반영하고
체크포인트 커밋했고, Q4 이후는 같은 날 이어진 세션이 결정 뒤 반영했다.)

| 문항 | 발견 | 상태 |
|---|---|---|
| Q1 | `H-124` `recompute` 루프 순서 | ✅ **확정** — (a), `continue` 형태 |
| Q2 | `H-125` 재마운트 캐시 | ✅ **확정** — 생성자 이동 + (c) 순서 + `_destroyed` |
| Q3 | `H-126` splice 빈자리 (+ `H-137` 소멸, `H-141` 신설) | ✅ **확정** — `element → index`는 `bk`가 소유, 토큰 폐기 |
| Q4 | `H-127` `EffectHandle:Unsubscribe` 순서 | ✅ **확정·반영** — (a) 의사코드, Observer 게이트 먼저 |
| Q5 | `H-128` M2×M8 `Ref` | ✅ **확정·반영** — (a) M2 공통 기반에 `Ref` 최소형 |
| Q6 | `H-133` `WeakUnsubscribe` 비대칭 | ✅ **확정·반영** — (a) 의도된 관대함 |
| Q7 | `H-130` 폐기 블록 편집 | ✅ **확정·반영** — (b) `archive/`로 이전 |
| Q8 | `H-134` `InstanceChildHandler` 부기 | ✅ **확정·반영** — (a) |
| Q9 | `H-135` 숏핸드 retractor | ✅ **확정·반영** — 문항 전제 정정, Tween 절 스케치 한 줄이 복사 오류(🟡→🟢) |
| Q10 | `H-136` reconcile 배치 Blocker | ✅ **확정·반영** — (a) |
| — | `H-129`/`H-131` | ✅ 정정 반영(판단 불필요) |
| — | `H-138` 숏핸드 우선순위 | ✅ **확정·반영** — 숏핸드가 높다, 충돌 방지는 `UI` 접두어 |
| — | `H-139` `New`/`D` 파이프라인 | ✅ **의사코드 신설** — 쓰면서 `H-142` 발견 |
| — | `H-132`/`H-137`/`H-140` | ✅ Q1~Q3 처리 때 닫힘 |
| — | `H-142` 해시 파트 `Parent` 순서 | ✅ **확정·반영** — props에 `Parent` 금지(순서 문제 소멸) |
| — | `H-143`~`H-146` (`/code-review high` 발견 중 새 메커니즘 넷) | ✅ **확정·반영 (전부 권고 (a))** — `Rerun` 꼬리 실행 중 사망이면 즉시 소진(`wasAlive`) / 재구독 꼬리(`Refresh` 먼저; 감사 4라운드로 진입점 소유권 (b) — `EffectHandle` 자기 것 — 추가 확정) / `indexOfElement` weak-key / 루트는 금지 범위 밖 + 전용 문구 |

**[2026-08-27] Q1~Q3는 `base/`·`ROADMAP.md`에 반영했다** — 반영 중 드러난 것과
열어둔 확인은 아래 "반영 기록" 절. **같은 날 이어서 Q4~Q8·Q10·`H-138`·`H-139`를
확정·반영했다**(아래 Q4 이하 절). **[같은 날 마지막] Q9 확인과 `H-142` 판단도
닫혀 9라운드 발견은 전량 처리됐다** — 그 뒤 감사 8라운드와 `/code-review high`를
돌렸고, 리뷰가 낸 새 메커니즘 넷(`H-143`~`H-146`)은 **[2026-08-27 다음 세션]
전량 확정·반영**(아래 "`H-143`~`H-146`" 절).

**사용자 회신 원문(Q4~Q10 일괄, 2026-08-27)**: *"Q5 까지는 권고에 전부 동의함.
WeakSubscribed 자체가 사라질 수 있는 요소라서, 그 사라지는걸 유저가 정하게 하는
요소라서 에러를 내야할지 말아야할지 애매한 부분이긴 한듯. 다만 weak 에 대한
홀드를 유저가 유지하는게 강제라면 b가 되긴 해야하나, 그럴 이유가 없어서 a가
되는게 맞는듯. 7번은 프로젝트 컨벤션대로, 권고 b적용. 8번도 권고대로. 9는 뭔가
이상한데? nil은 파괴가 맞고 파괴 자체가 트윈을 지움. 메니지드를 지우는 스케치가
왜 트윈에 있는지도 모르겠는 부분..? 트윈은 inst 를 바꾸어 재프로세싱 하는거라
연관이 없는 부분인데. 다시 생각하고 말해볼래? Q10 은 이제 그래도 되어보임.
이전에는 native* 가 없어 모두 dom 식 elem 입출력이 강제가 아니였는데, 이젠
그렇기 때문에 최초 방식으로 recompute 되는것 처럼 처리되어도 되는 지점.
부작용으론, offset 이 먼저 설정되어진 다음 후행 요소들이 밀리거나 당겨진 다음
후행으로 넘어가느냐가 차이가 나는데, 이미 우린 set upto 와 valid upto 가 나뉜
지점이고, 싱크라서 괜찮아보임. 권고대로 진입해도 된다 보는데 어떻게 생각하는지?
H138은 당연히 숏핸드 우선순위가 높음. 안 그러면 프로퍼티 핸들러가 숏핸드 계층을
인지하고 준비한다는 말이 돼. 그리고 프로퍼티에 UI를 붙인 이유도 우연히 겹치는걸
막기 위함임. UI 프리픽스는 로블록스 프로퍼티에 발견되진 않거든. H139 은 실 구현
전에 의사코드를 써보자. 그걸로 인해서 감추어졌던 설계 결함이나 폭탄이 발견된
경우가 많아서, 커지기 전에 확인해볼 필요가 있음. 중요 계층이라서"*

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

## Q4 — `EffectHandle:Unsubscribe()`는 Observer 게이트를 **먼저** 통과한 뒤 cleanup (`H-127`, 확정 (a))

- `effect-plan.md`의 "`EffectHandle:Subscribe()`" 절에 의사코드 한 블록 신설 —
  `Subscribe`/`WeakSubscribe`/`WeakUnsubscribe`는 **Observer의 함수를 메소드
  테이블에 그대로 배정**(같은 레지스트리·같은 `canBound` 게이트·같은
  `.Subscribed`), `Unsubscribe`만 `Observer.Unsubscribe(self)` 통과 뒤
  `self:_consumeCleanup()`. **⚠️ [2026-08-27 같은 날 정정] 함수 배정은 (b)로
  뒤집혔다** — 네 진입점은 `EffectHandle` 자기 것, 공유는 레지스트리·게이트뿐
  (아래 `H-144` 절의 감사 4라운드 항목). 게이트가 먼저라는 이 문항의 결정
  자체는 그대로다. `WeakUnsubscribe`는 cleanup을 안 건드린다(약한
  구독은 GC에 맡기는 경로라 해제가 종료 신호가 아니다).
- 산문의 번호 목록(플래그 → cleanup → fail-fast)은 **의미 목록이지 실행 순서가
  아니라고** 그 자리에 적었다. `lifecycle-pattern.md`의 *"아래가 네 진입점
  전량이고 소스다"*는 *"Observer의 네 진입점 … `EffectHandle`은 같은 넷을 그대로
  재사용"*으로.

## Q5 — M2 공통 기반에 `Ref` 최소형 체크박스 (`H-128`, 확정 (a))

- `ROADMAP.md` M2 "공통 기반" 절에 체크박스 신설 — `.Value`/`.Revision`/`:Set`/
  `:WeakCallback`/`:Callback`/`:Uncallback`/`isRef` + `EpochBrand:register`.
  M8 `Ref.luau` 체크박스는 *"최소형은 M2로 앞당겨졌다 — 여기 남는 건 `:Wait`,
  `PreRef`/`PostRef`, 디스패치 핸들러"*로. 절 머리의 *"셋 다 State-free"*는
  개수 없이 *"여기 있는 것 전부"*로.

## Q6 — `WeakUnsubscribe`의 관대함은 의도된 것 (`H-133`, 확정 (a))

- `lifecycle-pattern.md` (2) 의사코드 주석 + 산문 bullet 신설. **사용자 논거**
  (위 원문): 약한 등록의 생존은 사용자가 쥔 참조에 달린 것이고 quad가 그 홀드를
  강제하지 않으므로 "없는 항목의 약한 해제"를 오류로 볼 근거가 없다 — 홀드
  유지가 강제였다면 (b)여야 했다. 강한 등록은 quad가 살려두는 것이라 "없음"이
  곧 호출부 실수라 엄격. leaf 바인딩된 값에 `WeakUnsubscribe`도 같은 이유로
  통과(무해).

## Q7 — 폐기 블록을 `archive/`로 (`H-130`, 확정 (b))

- `effect-plan.md`의 ⛔⛔ 배너 아래 블록(`_observers` 배열 + cascade)을
  `archive/effect-internal-observer-cascade-reversed.md`로 옮기고 포인터 한
  문단만 남겼다. 옮긴 원문은 **`9dd8213`이 배너 아래를 편집한 흔적 그대로**이고
  파일 머리에 그 경위를 적었다. 새 규칙은 안 만들었다 — `conventions.md`
  핸드오버 체크리스트 3번이 이미 이 실패 모드를 규정한다(사용자: *"프로젝트
  컨벤션대로"*).

## Q8 — `InstanceChildHandler`도 부기를 등록한다 (`H-134`, 확정 (a))

- `dispatch-core-plan.md` 말단 표에 행 신설 + `H-39` 블록에 "다섯째" 문단:
  `process` 맨 앞에서 `setOffsetSource(inst, k, None)` →
  **`setLength(inst, k, 1, inst, v)`** → `v.Parent = inst`; 반환 클로저는
  `None` → `0` 순서로 해제. `ROADMAP.md` M5 체크박스에 같은 두 줄. 5번째
  인자(요소)는 Q3의 `setLength` 시그니처를 따른 것 — 상수 길이라 지속 클로저는
  안 생기지만 등록 모양을 다른 말단과 맞췄다.

## Q9 — 재고: 두 "확정"이 아니라 Tween 절 스케치의 **복사 오류** (`H-135`, 확정)

사용자가 문항의 전제를 정정했다(*"nil은 파괴가 맞고 파괴 자체가 트윈을 지움.
메니지드를 지우는 스케치가 왜 트윈에 있는지도 모르겠는 부분..? 트윈은 inst 를
바꾸어 재프로세싱 하는거라 연관이 없는 부분인데"*). 다시 본 결과:

- `v == nil` → `process`가 자식을 파괴하는 규칙은 두 절이 **같다**. 이상한 건
  Tween 절 스케치의 마지막 줄 `return function(hint) if hint == nil then
  destroyManagedChild(inst,k) end end` 하나 — 그 절의 주제는 *자식 프로퍼티
  세팅을 `Dispatch.process(child, "CornerRadius", …)`로 되돌려준다*뿐이라
  관리 자식의 생사를 정할 자리가 아닌데, `v == nil`(값)과 `hint == nil`
  (retractor 인자)을 겹쳐 적은 **복사 오류**로 보인다.
- 제가 (B) 분기에서 *"트윈이 끊긴다"*를 피해로 든 것은 틀렸다 — 자식이
  파괴되면 그 위의 트윈이 사라지는 건 당연한 결과지 결함이 아니다. 그 줄을
  지워야 하는 이유는 **파괴 경로가 하나여야 한다**(`process(inst,k,nil)`)는 것
  하나이고, 이중 파괴는 그 중복의 증상이다.
- 트레이스: `(inst,"UICorner")` 체인은 어떤 값이든 `UICornerHandler.process`에
  `number|Tween|nil`로 닿고(`StoreBind`가 State를 풀고 `NoneHandler`가 `nil`로),
  키 자체가 사라지는 건 인스턴스 teardown뿐이라 그때는 자식이 부모와 같이
  죽는다 — retractor가 할 일이 없다.
- **✅ [2026-08-27 확정]** 사용자: *"9 맞음. v == nil 로 신규 들어오면 파괴가 맞고
  retract 는 nop 맞아. 파괴 자체가 사실 inst 바꿔서 넣은 process 를 처리할 필요
  없게 만들어버리고, 우린 파괴에 대해서 retract 안하던게 맞아서, Tween 과 무관한
  것도 맞지."* — `ui-shorthand-plan.md` Tween 절 스케치의 그 줄을
  `return function() end`로 고치고 정정 bullet을 달았다. `H-135`는 🟡→🟢.

## Q10 — `reconcile` 재실행도 배치 Blocker로 (`H-136`, 확정 (a))

- `slot-plan.md`의 `reconcile` 머리(중복 키 선행 패스 뒤)에 `getBlocker(self)`
  획득, 꼬리에 `OffWithoutEmit()` + `recomputeBlocker` 확인 후 `recompute` 1회.
  **Blocker가 네스팅이 안 되므로**(불리언, `blocker-plan.md`) 최초 population
  처럼 바깥 배치 안에서 오면 `IsOn()`으로 알아보고 손대지 않는다(`ownsGate` —
  이 판정은 사용자가 승인한 (a)의 문구 밖에 있는 **구현 세부**다. 같은
  `reconcile` 클로저가 바깥 배치 안(최초 population)과 밖(재실행) 양쪽에서
  불리는데 Blocker에 네스팅이 없어서 필요한 것이고, 함수 지역 변수라 표면엔
  안 드러난다).
- **사용자 논거**(위 원문): `native*` 계층이 생기기 전엔 DOM식 요소 입출력이
  강제가 아니라 raw op마다 `recompute`가 돌아야 했지만, 이제는 물리 위치를
  `native*`가 부기와 무관하게 정확히 넣으므로 최초 population처럼 한 번에
  따라잡아도 된다. 부작용으로 "offset이 먼저 잡힌 뒤 후행 요소가 밀리느냐,
  밀린 뒤 넘어가느냐"가 갈리지만 `offsetSetUpTo`/`offsetCacheValidUpTo`가
  분리돼 있고 동기라 괜찮다. `dispatch-core-plan.md`의 *"한 사이클 … 한 번만"*
  문단에 같은 근거를 적었다.
- 제 판단: 동의 — `raw*`의 명시 호출이 이미 `getBlocker(self):IsOn()`을 보므로
  (`H-119`) 추가 배선이 없고, `getOffsetAt`/`physIndex`는 Blocker와 무관하게
  정확하다(최초 population과 같은 논증). `updateFn`이 던지면 Blocker가 켜진 채
  남는 것도 `materializeSlotTree`와 같은 부류다.

## `H-138` — 숏핸드 핸들러가 `PropertyHandler`보다 우선순위가 높다 (확정)

- `ui-shorthand-plan.md` "메커니즘" 절에 문단 신설, "결론" 절의 접두어 확정에
  두 번째 근거 추가. **사용자 논거**(위 원문): 리플렉션 거부에 기대면 하위
  계층(프로퍼티)이 상위 계층(숏핸드)의 키 집합을 알아야 하는 역방향 의존이
  생긴다; 충돌 방지는 우선순위가 아니라 `UI` 접두어의 몫(Roblox 프로퍼티
  이름엔 `UI` 접두어가 없다). 구체 상수는 구현 시.

## `H-139` — `New(name)(props)` 파이프라인 의사코드 (신설) + 거기서 나온 것

- `bind-system-plan.md` "인스턴스 생성 / 이벤트 네이밍 인체공학" 절에
  `New` ①~④(물리 생성 → gcconn/gchold → `flatten` → `Dispatch.drive`)와
  `drive` (a)~(c)(pre-pass → 단일 일반화 `for` 본체 + 배치 Blocker →
  `postRefList`) 의사코드 신설. 단계 안의 규칙은 각 소스 문서가 정본이고 여기는
  **순서**만 확정. `ROADMAP.md` M3 `Dispatch.drive` 항목에서 가리킨다.
- 이름 충돌(모듈 팩토리 `New()` vs 생성자 `New "Frame"`)은 산문 표기 규칙
  한 줄로 닫았다(패키지가 달라 런타임 충돌은 없다).
- **쓰면서 드러난 것 셋** — 사용자가 예상한 그대로:
  1. ~~**배치를 닫는 자리가 어디에도 없었다.**~~ **⚠️ 이 주장은 틀렸다**(감사
     1라운드) — `dispatch-core-plan.md`의 `H-17` 절이 이미 *"`drive` 전체
     (post-pass 포함)를 감싼다, `PostRef` 콜백은 게이트가 켜진 채 실행된다"*로
     정해뒀는데 제가 그 절을 안 보고 "해시 파트 앞에서 닫는" 의사코드를 썼고,
     사용자 확인 1번은 **그 틀린 전제 위에서** 받은 것이다. 의사코드를 `H-17`대로
     (진입 직후 On, `postRefList` 뒤 Off + `recompute`) 고쳤다 — 확인 1번은
     무효, 계약은 원래 것 그대로. 실제로 낡아 있던 건 같은 문서 "해법의 핵심"
     4번의 옛 문구(*"배열 파트 순회 전체"*) 하나라 같이 정정.
  2. **자식 없는 Instance에도 Blocker/`bk`가 생기는 경로.** `getBlocker(inst)`를
     무조건 부르면 `Frame { Size = … }`마다 Blocker + `bk` + `Relate` 항목이
     eager 생성된다 — Q2/Q3가 Slot 쪽에서 막은 것과 같은 부류.
     `flattened[1] ~= nil` 가드로 막았다. 확인 요청.
  3. **`H-142` 🟡 신설 — 해시 파트 안의 `Parent` 순서가 미정.** `Frame { Parent
     = x, Size = … }`에서 `Parent` 대입이 다른 프로퍼티보다 먼저 올 수 있다
     (Luau 해시 순회 순서는 계약이 아니다). 처방 후보(순서 미루기/문서화/무시)가
     전부 새 메커니즘이라 정하지 않고 올렸다.
     **✅ [2026-08-27 확정 — 순서가 아니라 키 금지]** 사용자: *"Parent대입 자체가
     오면 안 돼. 그건 부모에서 할 일이거든. 자신이 바로 하는 경우는 없어. 그걸
     허용해준다는것 자체가, '외부에서 직접 Parent 설정해주지 말것' 을 해치는
     요인이 되기도 해.(암묵적으고 가능하도록 둬버려서)"* — `slot-plan.md`의
     "동적 자식은 반드시 `Slot` 또는 `state<Frame>`류 store-bind를 통해서만" 원칙의
     정적 리터럴 판. 반영: `bind-system-plan.md` 파이프라인 절에 규칙 + `ROADMAP.md` M5
     (`D` 생성기가 props 타입에서 `Parent` 제외 / `PropertyHandler.isHandlable`이
     `"Parent"` 거부 → 기존 "매치 핸들러 없음 → 즉시 error"에 걸림). **런타임
     배선은 제 선택**(새 메커니즘 없이 기존 계약 재사용)이라 문서에 그렇게
     갈라 적었다.
- **1·2 확인 완료**(사용자: *"1과 2는 확인했어. 2는 특히 생성 이후 다시 process
  를 주는걸 우린 안 하기로 해서 충분히 가능한 일"*). 2에 대해 사용자가 남긴
  의심 — *"Frame{} 으로 나온 bk없는게 Slot 안에 멀쩡히 들어가는데 문제
  없을까"* — 를 코퍼스의 호출부 전수로 확인했다: **문제 없다.**
  - `getBookkeeping`/`getOffsetAt`/`setLength`/`setOffsetSource`의 첫 인자
    (`ownerKey`)는 코퍼스 전체에서 **Slot 자신(`self`/`slot`) 또는 `drive`를
    도는 최상위 `inst`뿐**이다. Slot에 들어간 `Frame{}`은 언제나 **요소**
    (`setLength`의 5번째)나 **앵커/물리 target**(4번째, `bindLifetime`·
    `nativeInsert`의 첫 인자)으로만 나온다 — 앵커는 gchold(②에서 무조건
    생성)를 쓰지 `bk`를 안 본다.
  - 그 Frame이 owner가 되는 경우는 자기 props에 배열 파트가 있을 때뿐이고,
    그땐 `flattened[1] ~= nil`이라 가드가 안 걸린다. `outerSlot:Add(innerSlot)`
    처럼 나중에 중첩 Slot이 그 Frame을 물리 target으로 써도 owner는
    `outerSlot`이다.
  - "`bk.base`"는 이미 걷어낸 필드다(`dispatch-core-plan.md` 3번, 사용자
    지적으로 — 최상위 `inst`의 베이스는 항상 0이라 저장할 게 없다). 설령
    예상 못 한 경로가 `getBookkeeping(frame)`을 불러도 **lazy 생성**이라
    크래시가 아니라 그때 만들어질 뿐이다.

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

**아직 안 한 것**(Q1~Q3 체크포인트 시점 문장 — **[2026-08-27 후속] Q4~Q10도
전량 반영됐고**, 그 반영분의 감사 루프는 아래 "감사 루프 (2026-08-27, Q4~Q10
반영분)" 절; 남은 건 라운드 전체에 대한 `/code-review high`와 커밋뿐):
`/code-review high`, 커밋 — Q4~Q10 반영 뒤 한 번에. README
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

## `/code-review high` (2026-08-27, Q4~Q10 반영분 + 감사 8라운드 뒤)

10건(검증 12 CONFIRMED · 5 PLAUSIBLE · 1 REFUTED). **여섯은 기존 규칙 적용이라
그 자리에서 반영**, **넷은 처방이 새 메커니즘·표면이라 문항으로**(`-round9.md`의
`H-143`~`H-146`, `question.md` 최우선 절).

반영한 여섯:
1. **`InstanceChildHandler` retractor가 옛 자식을 안 내렸다** — `Parent = nil`
   추가(파괴 아님 — `slot-plan.md`의 "`State<Slot>` 교체는 파괴가 아니라
   언마운트" 절 근거 1이 바로 `state<Frame>`의 이 동작). `state:Set(B)`에서 A가
   물리 자식으로 남은 채 `lengthList[k] == 1`이 되던 것.
2. **같은 핸들러의 순서** — `setLength` → `Parent`였던 것을 `Parent` →
   `setLength`로("일반 계약 — 물리와 부기의 순서" 3번과 같게). 단건 경로에서
   `recompute`가 부착 전에 돌았다.
3. **같은 핸들러의 5번째 인자 `v`** — 제가 "모양을 맞추려" 넣은 것인데, 해제
   `setLength(…, 0)`이 옛 키를 안 지워 교체마다 `bk.indexOfElement`에 옛 자식이
   강참조로 쌓였다. Q3 계약대로 상수 길이는 **생략**. (Slot 쪽 같은 구멍은
   `H-145`로.)
4. **`H-17`에 빈 배열 파트 가드가 없었다** — 사용자 확인 2번이 스케치에만 적혀
   정본(`dispatch-core-plan.md`)은 여전히 "무조건 On"이었다. 정본과 "해법의
   핵심" 1번에 반영.
5. **`quad-types`의 `Quad`에 `Ref` 필드** — `H-128`로 최소형이 M2에 왔는데 그
   필드 체크박스는 M8에 남아 `H-25` 공백을 다시 열었다. M2 `H-80` 목록에 `Ref`
   추가, M8 항목은 흡수 표기.
6. **Modifier 메소드 목록의 `Parent`** — props 타입에서만 빼면
   `Modifier():Parent(x)`가 타입을 통과한다. `bind-system-plan.md` `H-142` 타입
   항목 + ROADMAP M7 체크박스.
7. **`effect-plan.md` 번호 목록 재정렬** — "실행 순서가 아니다" 괄호만 달고 옛
   순서를 남겨둔 것이 `H-130`과 같은 모양이라 게이트 → 플래그 → cleanup으로
   다시 씀.

기각 1(REFUTED): "`drive` 의사코드가 `dispatch-core-plan.md`를 중복한다" — 사용자
요청으로 신설한 블록. 캡에 밀린 하위 발견(`Slot:List` 잉여 블록 잔존 등)은 이미
"잉여" 주석으로 처리된 것과 같은 항목.

## `H-143`~`H-146` — 전부 권고 (a) 확정 (2026-08-27)

문항·갈래 원문은 `-round9.md`의 `H-143`~`H-146` 절. 반영 자리는 각 항목에.

**사용자 회신 원문**: *"H-143: 동의. 메니징된 effect 에서 해당 부분을 지원 안
해야할 이유가 딱히 존재하지 않아. 특정 state 에 변경을 딱 한번만 처리하고
cleanup 되는걸 만드는 요구가 존재하지 않을 이유가 딱히 없다고 봐. (a) 갈래를
택하는데 큰 문제가 없어보여. H-144: 재설치 처리는 동의해. 그리고 원래 처음
설치에서도 모든 옵저버와 ref 콜백이 하나하나 실행되지 않도록 blocker 를 통해서
전부 블로킹 하고 명시적으로 실행한다는 점을 생각해야해 이건 그 동작과 유사해. 재
sub 에서도 똑같게, 후행에서는 실행해야하는 부분이지. 그러고 나서는 사실 어떤
것이라도 가만히 둬도 좋아. 그 이후 받는 모든 emit 의 경우는 들어올 때 기준으로
항상 '다시 받는 emit' 에 속할것이거든. … 근데 blocker 로 블록된 다음 나중에
들어오는 것에 대해서 어떻게 처리할지는 갈리는 부분이야. 그걸 생각하면 초기에
epoch 를 전부 잘 설정해주는게 나을수도 있어. 왜냐하면 처음 연산 기준에 있어서도
전부 값은 최신 값이거든. 따라서 다음 emit 을 받아야할 이유가 없을수도 있어. 이건
중간 값이 emit 을 보류하는거랑 다른 이야기인듯. observer 에도 연관되는
이야기일텐데 한번 확인 해볼래? H-145: (A) 의 단점은 slot 자체가 여기저기에
마운트된다면 여러 bk 에서 남아있을 수 있다는건데, 그건 큰 문제가 안 돼. slot
자체가 소수의 생성이 되는 요소인데다가 포탈 경로가 많지 않거든. 아마 그래서
충분히 weak 로 두는건 괜찮은 발상이야. 컴퓨팅 비용이 더 안들고, 복잡하지 않고
깔끔한 경로거든. 다만 다른 inst 들이 삭제 되지 않는게 확실히 보장되어야해.
기본적으로 자신을 gchold 로 잡으니 괜찮아보여. H-146: 나도 (A) 갈래에 동의해.
왜냐하면, 실제로 React 에서도 최상위 경로는 보통 App.tsx 나 main 을 나누고 root
를 돔 api 로 가져오고 거기에 바운딩 하는 처리를 해야하거든. 유사하게 메인
컴포넌트에 대해서 생성 결과를 Parent 를 설정해주는건 옳을 수 있어. 우선 해당
방식은 엔진 마다 다를 수 있다는 점도 생각해야해. Quad 가 제공하는 마운트는
완전히 다른 성격이라서(부기에 대한 처리가 들어가는데 PlayerGUI 등 Quad 가
제공하지 않은 부기가 없는 객체에 대해서 Quad 의 객체를 주입하는 성격의 API 는
아니거든) 해당 부분을 해결하기 위해서 다른 API 를 제공 할 이유가 없기도 해. 해당
부분은 각 엔진을 사용하는 최종 사용자의 몫."*

### `H-143` — `Rerun` 꼬리에서 실행 중 사망(`wasAlive and not canExecute`)이면 반환 cleanup 즉시 소진 (a)

- 하위 결정: 판정은 **"이 실행 중에 죽었는가"(`wasAlive and not canExecute`)**
  — `fn` 안 `WeakUnsubscribe`도 같은 경로로 소진된다.
  - ⚠️ 처음엔 `not canExecute` 하나로 썼는데 **감사 2라운드가 회귀를 잡았다**:
    생성자의 최초 `Rerun()`은 어떤 바인드·구독보다 먼저 돌아 `canExecute`가
    항상 거짓 → 첫 실행 cleanup 즉시 소진 + `_installed` 거짓 → 첫 바인드에서
    `fn`이 또 돈다(`H-58` 재현, "생성 즉시 1회 실행은 바인드로 미룰 수 없다"와
    충돌). 진입 전 상태를 로컬로 잡아 "살아 있다가 죽었다"만 잡는 것으로 정정,
    같은 자리에서 죽은 핸들의 `_pending` 재요청도 버리기로(안 버리면 `fn` 안
    `Unsubscribe()` + `Rerun()` 조합이 죽은 핸들에서 `fn`을 한 번 더 돌린다 —
    감사 2라운드 의심 항목). **사용자 확정**: *"오 그렇네. 실행중 죽으면
    클린업만 하기, 해당 방식 맞아보여"*. `H-133`의 "약한 해제는 cleanup을 안 건드린다"는
  *`WeakUnsubscribe` 자신*의 계약이고, 여기선 `Rerun`이 방금 받은 것을 죽은
  핸들에 매다느냐의 문제라 행위자가 다르다. 강한 해제만 잡으려면 별도 판정이
  필요해 더 든다(a2 기각).
- 반영: `base/effect-plan.md` `Rerun` 의사코드 + "`self`를 주는 덕에" bullet
  (허용 문장이 확정으로), `ROADMAP.md` M2 `Effect` 체크박스.

### `H-144` — `Subscribe`/`WeakSubscribe` 등록 끝에 `Refresh()` 먼저, `not _installed or depsChanged → Rerun` (a) + 진입점은 `EffectHandle` 자기 것 (b, 감사 4라운드)

사용자가 요청한 **재트레이싱** 결과(회신의 두 질문):
1. *재구독 뒤 "다음 emit"이 오면 꼬여도 괜찮은가* — 괜찮다. `fire`의 가드
   순서가 `canExecute → blocker:IsOn → _epochs:Update → Rerun`이라 해제 중
   도착한 emit은 **첫 가드에서 버려져 `_epochs`를 안 건드린다.** 재구독 뒤 첫
   emit은 리비전이 새로우니 정상 `Rerun`, 읽는 값은 항상 최신(State는 lazy,
   수신 시점에 `valueEpochMap` 갱신). 다이아몬드 접힘도 그대로.
2. *재구독 시점에 epoch를 맞춰두는 게 나은가* — 낫고, **leaf 경로가 이미 그
   모양**이다(`_bindDestroying`: `Refresh()` 먼저, 아니면 "다음 emit이 헛되이
   한 번 더 돈다" 캐비엇). 구체 케이스: `state:Gate`가 유보 중일 때 재구독 →
   `Rerun`이 읽는 값은 이미 새 리비전(게이트는 값은 수신 시점에 갱신하고 emit만
   유보, `state-epoch-plan.md` §4 게이트 예외) → 유보가 풀려 `{A@r2}`가 오면
   `Refresh` 안 했으면 같은 값으로 `fn`+cleanup이 한 번 더, 했으면 접힌다.
- Blocker는 재구독에 안 쓴다 — dep 재등록이 없으므로(생성자에서 한 번, `_deps`
  강참조 유지) 억제할 발화가 없고 명시 `Rerun`만 하면 된다.
- Observer: 관련 없음 확인 — epoch가 없고(`H-107`) 구독 시 설치 발화도 없어
  재`Subscribe`는 첫 구독과 동일. 고칠 자리 없음.
- 하위 결정: **`WeakSubscribe`도 같은 꼬리** — `WeakUnsubscribe`(cleanup 미소진,
  `_installed` 유지) 뒤 재`WeakSubscribe`도 한 모양으로 맞는다(dep 안 변했으면
  no-op, 변했으면 옛 cleanup 소진 후 재실행).
- ⚠️ **감사 4라운드가 배선 결함을 잡았다 → (b) 네 진입점을 `EffectHandle` 자기
  것으로.** 처음엔 Q4(`H-127`)의 "Observer 함수를 그대로 배정" 위에 래퍼를
  얹었는데, `Observer:Subscribe`의 본문이 `self:WeakSubscribe()`로 **콜론
  위임**하므로 `self`가 `EffectHandle`이면 그 조회가 새 `EffectHandle:WeakSubscribe`
  래퍼로 가서 꼬리가 **두 번** 돌고, 첫 번째는 `Subscribed[self] = true`(강한 킵)
  **전에** `Rerun`해 `fn` 안 `self:Unsubscribe()`(`H-143`이 지원하는 패턴)가
  *"not subscribed strongly"*로 error(로컬 `luau`로 재현: 콜론 위임은 꼬리
  2회·첫 번째 킵 전, dot 위임은 1회·킵 뒤). 갈래 (a) Observer 본문의 내부 위임을
  dot 호출로 / (b) 함수 공유를 접고 `EffectHandle`이 네 진입점을 따로(공유는
  `Observer.luau`의 레지스트리 둘과 `canBound`뿐). **사용자 확정 (b)**: *"b가
  맞아. 내 머리에서 나왔던 처음 구조는 그것이였어. 항상 언급되는 말이지만,
  '하나의 무언가가 두 일을 동작하지 않는가에 유의하자' - 이것도 마찬가지야.
  버그를 유발하기 좋은 포인트였고, 감사자의 좋은 지적이였어."* 앞서 *"애초에
  observer 랑 effect 랑 헤테로지니어스한 타입인데. effect 가 observer 를
  만족시키진 않아. 생성 방법도 다르고"*라 결함 자체가 진짜인지 물었고, 재현으로
  확인. 원칙은 `conventions.md`의 "설계 원칙" 절로 승격. Q4의 "그대로 배정"은
  이로써 **좁혀졌다**(레지스트리·게이트 공유만 남음).
  `Subscribe`는 `WeakSubscribe`를 부르지 않고 등록 세 줄을 펼쳐 쓴다 — 꼬리가
  강한 킵 뒤에 정확히 한 번 돌아야 하므로.
- 반영: `base/effect-plan.md` `EffectHandle` 의사코드 블록(`resubscribeTail`) +
  "`:Subscribe()`가 등록하는 것은" bullet, `base/lifecycle-pattern.md`의 (2) 절
  머리 문단(`EffectHandle` 재사용 범위 정정), `ROADMAP.md` M2.

### `H-145` — `bk.indexOfElement`를 weak-key로 (a)

- 사용자가 붙인 조건: 요소 `inst`가 마운트 중 GC되지 않는 보장 — (0)의
  gchold(`lifecycle-pattern.md`)가 그것. 값이 정수라 Luau ephemeron 미지원도
  무관.
- (b) 해제에 요소를 넘겨 `setLength`가 지우기(시그니처 의미 확장) / (c) inst
  층 명시 삭제 API 기각.
- 반영: `base/dispatch-core-plan.md` `getBookkeeping` 초기화 + `InstanceChildHandler`
  5번째 인자 근거 정리(weak가 되며 "옛 키 잔존" 근거는 사라지고 "지속 클로저
  없음"만 남음), `ROADMAP.md` M3 `getBookkeeping` 체크박스.

### `H-146` — 루트는 금지 범위 밖, `Mount` 표면 없음, 거부는 전용 문구 (a)

- 인용문 *"외부에서 직접 Parent 설정해주지 말것"*의 범위를 **quad가 관리하는
  자식 자리**로 명문화. 루트 부착은 엔진마다 다른 최종 사용자 코드. (b)
  `Mount(root, parent)` / (c) 루트 전용 props 키 기각.
- 반영: `base/bind-system-plan.md` `H-142` 항목에 루트 bullet + 전용 문구,
  `base/slot-plan.md`의 "동적 자식은 반드시" 절 각주 + "v2는 mount 함수 자체가"
  문구 정정(v1식 `Mount`는 v2에 없다), `ROADMAP.md` M5 `Property.luau`.

## 감사 루프 (2026-08-27, Q4~Q10 반영분)

관례대로 `quad-doc-auditor` 한 턴에 하나, diff 범위, 라운드마다 각도 변경.

| 라운드 | 각도 | 새 발견 | 처분 |
|---|---|---|---|
| 1 | `base/` 정합성 | 확실 3 · 판단 1 · 의심 1 | ⭐ `drive` 의사코드가 `H-17`(*"`drive` 전체를 감싼다, `PostRef` 콜백은 게이트 안"*)을 어김 — 제 *"닫는 자리가 없다"* 주장이 틀렸고 사용자 확인 1번은 무효(`H-139` 절) / `question.md` 최우선 절 "Q4~Q10 대기" 잔재 / README `effect-plan` 행 `:Callback` 잔재 / ROADMAP `Property.luau`에 "거부 배선은 에이전트 선택" caveat / Blocker 시작점 "진입 직후"로 |
| 2 | 인덱스 레이어 + 새 문단 자기모순 | 확실 1 · 의심 2 | ROADMAP M8 `Ref.luau` 체크박스가 자기 `H-128` 노트와 모순 → "나머지(`:Wait`)"로 재작성 / Q9 헤더 "확인 대기" 잔재 / `Slot:List` wrap이 `reconcile` 게이트와 중복 → "잉여" 주석 |
| 3 | 주변 폴더 인용처 + 인용문 역방향 + 수정분 | 확실 2 · 의심 2 | ROADMAP 머리 배너 "Q4~Q10 대기" 잔재 / 이 파일 "아직 안 한 것" 문장 / (의심) `ownsGate`는 승인 문구 밖의 구현 세부 — 지역 변수라 그대로, `H-136` 절에 그렇게 표기 / (의심) M8 체크박스의 *"서술도 같이 갔다"*가 과장 → 문구 정정. 인용문 역방향은 전부 일치 |
| 4 | 1~3라운드 수정분 + 발견/결정 문서 내부 정합 | 확실 3 · 의심 2 | 발견 문서 요약 표에 `H-142` 행 없음 / `H-135` 심각도 표 vs 헤더 / §4 아래 Q9 "확인 대기" 잔재 / (의심) `Slot:List` "잉여" 주석 범위를 블록 전체로 / (의심) M8 체크박스의 표면 목록 반복 → M2 참조로 |
| 5 | 4라운드 수정분 + 델타 밖 `base/` | 확실 1 · 의심 2 | `source-state-plan.md`의 *둘 다 error · 계약은 하나* 문장에 `H-133` 캐비엇 / `blocker-plan.md` 재진입 절에 "`IsOn()` 소유권 판정은 네스팅이 아니다" 한 줄 / `architecture.md` `Ref.luau` 한 줄에 `Epoch` 표면·M2 최소형 |
| 6 | 5라운드 수정분 + 신설 규칙 vs 기존 규정 | 확실 1 · 의심 0 | 이 파일 머리 배너 *"진행 중이다"* 잔재(5라운드 동안 빠졌던 것) → "전량 처리"로. 신설 규칙 여섯 자리(`Parent` 금지 / gcconn 시점 / `New` 표기 / `WeakUnsubscribe` 비소진 / 숏핸드 우선순위 / 다섯째 말단) 전부 기존 규정과 충돌 없음 |
| 7 | 6라운드 수정분 + 세션 기록 사실성 | 확실 3 · 의심 0 | README `bind-system-plan` 행이 "배치 닫는 자리 … `Parent` 순서 미정"으로 1라운드 정정·`H-142` 확정 이전 상태 / `todos.md` 00번에서 "`/code-review high`·커밋 남음" 액션이 사라짐 → 복원 / 이 파일의 "48줄" 개수 주장(실제 47) → 개수 삭제. 세션 파일·summary·todos 본문 서술은 전부 사실과 일치 |
| 8 | 7라운드 수정분만(좁게) | 확실 1 | `project-context.md`의 볼드 마커가 홀수(이번 갱신이 닫는 `**`를 지움) → 짝 맞춤. 지정 세 자리는 회귀 없음. **여기서 멈춤** — 1라운드 이후 설계 내용 발견은 0이고 [2026-08-27 8라운드 시점] 남은 건 기록 문서의 표기뿐이라, 비용 대비 `/code-review high`로 넘어가는 게 낫다고 판단(추이 5→3→4→5→3→1→3→1, 단조 수렴은 아님) |

## 감사 루프 (2026-08-27, `H-143`~`H-146` 반영분)

`quad-doc-auditor` 한 턴에 하나, diff 범위, 라운드마다 각도 교체. 새 발견
1→1→1→1→1→1→1→**0** (8라운드에서 수렴).

| 라운드 | 각도 | 발견 | 처리 |
|---|---|---|---|
| 1 | 인덱스·문구 잔존 | `effect-plan.md`의 *`_installed`는 `Rerun`이 끝날 때 참* 문장이 무조건 서술 | 조건 반영 |
| 2 | `base/` 의미론 | **`H-143` 판정식 `not canExecute`가 생성자 최초 설치를 죽임**(회귀) + `fn` 안 `Unsubscribe`+`Rerun` 재진입 미서술 | 사용자 결정 → `wasAlive and not canExecute` + `_pending` 버림 |
| 3 | audit/archive/reference | `session-summary.md`가 정정 전 판정식을 요약 | 정정 |
| 4 | 수정분 재검토 | **Observer 함수 배정 + 콜론 위임 → 재구독 꼬리 2회, 강한 킵 전 `Rerun`**(설계 결함) | 사용자 결정 → (b) 진입점 자기 것 + 원칙 승격 |
| 5 | (b) 수정분 재검토 | `README.md` 색인 행 미갱신 / Observer `WeakSubscribe` `error` `level` 누락 / 실측 문구 과장 | 셋 다 정정 |
| 6 | 인덱스 레이어 | followup `H-143` 헤딩·진행 표가 정정 전 표현 | 정정 |
| 7 | `effect-plan.md` 통독 | "종료 신호 둘뿐"이 `Rerun` 꼬리와 모순 / 필드 목록에 `.Subscribed` 누락 / `fn` 안 재구독 미서술 | 셋 → 정정·명시 |
| 8 | 전체 diff 재통독 | **0건** | — |

2·4라운드 발견은 둘 다 "권고 (a)의 의도는 맞는데 메인 세션이 고른 판정식·배선이
틀린" 종류 — 1라운드(문구 잔존) 각도로는 안 나왔고, 의미론·수정분 재검토
각도에서만 나왔다.

## `/code-review high` (2026-08-28, `H-143`~`H-146` 반영분 + 감사 8라운드 뒤)

10건(7 CONFIRMED 검증). **일곱은 기존 규칙 적용이라 반영**, **셋은 새 메커니즘·
기존 결정 변경이라 10라운드 문항으로**(`-round10.md` `H-147`~`H-149`).

반영한 일곱:
1. `effect-plan.md` "`EffectHandle:Subscribe()`" 절 머리 볼드가 여전히 "Observer의
   것을 재사용" — (b)로 정정. 717행 "Observer의 것을 위임한 뒤"도.
2. `Refresh()` 먼저의 계약을 세웠는데 `ROADMAP.md`(M2·M6)·`lifecycle-pattern.md`·
   `ref-plan.md`가 단축평가형 `if not _installed or Refresh()` 한 줄을 그대로 —
   전부 두 줄 형태로.
3. "첫 구독에선 no-op"은 거짓(생성~첫 구독 사이 emit은 `fire`가 버려 `Refresh`가
   참) — "그 사이 dep이 안 변했으면 no-op"으로.
4. `fn` 안 자기 해제의 범위 — 건 경로로만(강구독 `Unsubscribe`, 약구독
   `WeakUnsubscribe`), leaf 바인딩 핸들엔 자기 해제 경로 없음(종료는 leaf 사망).
   `Rerun` 주석의 "leaf도 아니라"도 한정.
5. `source-state-plan.md`의 *내부 Observer가 게이트를 갖고 있어 Effect 구현이
   몰라도 자동 커버* 서술 — 틀림(내부 Observer는 `Weak*`, 발화는 `canExecute(handle)`).
   (b)대로 `EffectHandle`이 직접 `canBound`.
6. weak-key `indexOfElement`의 보장자 — 사용자가 든 gchold는 `inst → 값` 홀더라
   `inst` 자신을 안 잡음. 실제 보장자는 `slot._elements` + `gatedRecompute` 캡처로
   정정, Instance weak key 미확인(`audit/gcconn-trick-verification.md`) 포인터.
7. `-round9.md` `H-144` 셀 "둘 다 래퍼"·`ROADMAP.md` 배너 "재구독 래퍼" →
   (b) 표현으로. 캡 아래 넷(`question.md`의 *판단 대기 없음* 과장, "다음 세션" →
   파일 ID, 중복 세 줄, 한국어 자리표시자)도 앞 둘은 정정.

문항으로 올린 셋은 `-round10.md`가 소스.
