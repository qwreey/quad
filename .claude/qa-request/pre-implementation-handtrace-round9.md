# 구현 전 손 트레이싱 **9라운드** — 발견 보고

**무엇인가**: `qa-request/pre-implementation-handtrace-round9-brief.md`(지시서)대로
**커밋 `9dd8213` 하나의 델타**(8라운드 결정 Q1~Q10 반영 + 그 뒤 `/code-review
high` 7패스의 수정)를 처음부터 다시 트레이싱한 결과. 발견 번호는 `H-124`부터.
**저장소는 이 파일 말고 아무것도 수정하지 않았다**(스파이크·참조 구현 갱신본은
세션 스크래치패드 `ref9/`에 있고, 근거는 전부 아래 항목에 인라인 전사돼 있다).

**쓴 각도**(지시서 §4의 문자 유지): **A**(반영분 상호 간섭 재트레이싱, 최우선) ·
**C**(참조 구현을 현재 계약으로 다시 전사해 `luau`로 실행) · **G**(문서가
"확인했다"고 적은 Luau 사실 재확인) · **D**(`ROADMAP.md` M2 체크박스로 실제
짜는 시뮬레이션) · **B**(M5+ 값 단위 트레이싱 — 이 라운드의 첫 시도, 별도 절).
**H**(비용)와 **E**(공개 API 오용)/**F**(미다룸 영역)는 이번 델타에 걸리는
자리만 봤다(§6).

**실제로 본 범위**: `git show 9dd8213 -- .claude/base/ ROADMAP.md` 전량(2180줄)
+ 그 델타가 사는 원문 절 전문 — `dispatch-core-plan.md`(`getBookkeeping`
열거 / `getOffsetAt` / "두 필드" / 무효화 표·배치 목록 / `H-119` 절 /
`recompute` / `setLength` / `setOffsetSource` / 배치 게이팅 / `drive` 꼬리),
`slot-plan.md`(`Slot:List` 꼬리 / `activateList` 머리 / `materializeSlotTree` ·
`mountSlotTree` · `attachSlot` / `unmountSlotTree` · `destroySlotTree` /
`rawUnmount` · `rawDetach` · `rawAdd` · `rawReplace` · `rawRemove` / `H-29` 규약
/ `spliceArrays*` 요구 목록), `effect-plan.md`(생성자·훅·`Rerun`·
`Subscribe`/`Unsubscribe` 절·폐기 블록), `lifecycle-pattern.md`((1)·(2) 절),
`ref-plan.md`(콜백 계약·`WeakCallback`·`:Set` 순서·`Revision`),
`source-state-plan.md`(전파 루프·Observer 절·`WeakSubscribe` 절·이중 바인딩
절), `state-epoch-plan.md` §4, `store-plan.md`(`H-112`/`H-115`/`H-117` 블록),
`typing-limits.md` §0, `lifecycle-hooks-plan.md`(`guard`), `ROADMAP.md` M2
전량 + M8 머리. 8라운드 §5가 "이상 없다"고 닫은 자리는 다시 파지 않았다.

**읽는 순서**: 요약 표 → 🔴 둘(`H-124`/`H-125`, 둘 다 실측 재현) → §4 결정 문항
→ 나머지 상세 → §5(이상 없음 — 특히 **8라운드가 남긴 캐비엇 하나가 실측으로
닫혔다**) → §6.

---

## 요약 표

| 번호 | 심각도 | 한 줄 | 주 대상 | 성격 | 실측 |
|---|---|---|---|---|---|
| `H-124` | 🔴 | `recompute`가 `bk.lengthList[i]`를 **되감기 판정보다 먼저** 읽는다 — 커서 자리 이후로 자리 수가 줄면 `sum += nil` 크래시, 그 뒤 `recomputeBlocker`가 영구 On | `dispatch-core-plan.md` `recompute` | `H-113`×`H-119` 겹침 (A) | ✅ 재현 |
| `H-125` | 🔴 | 재마운트(포탈/Detach 복귀)에서 `setOffsetSource`가 `slot.Offset`을 바꾸는 순간 `_baseObserver`가 **unbind 상태**라 두 필드가 0으로 안 내려가고, 꼬리 `recompute`가 **옛 베이스의 `offsetCache[1]`**을 그대로 쓴다 | `slot-plan.md` `materializeSlotTree`×`unmountSlotTree` | `H-3`×`H-119`×`C-4` 겹침 (A) | ✅ 재현 |
| `H-126` | 🟡 | `spliceArraysUp`이 비운 자리 `index`의 `observers`/`tokens`를 비우라는 요구가 없다 — 복사 루프로 짜면 **같은 Observer·토큰이 두 자리에** 살아 `setLength`가 옆 자리 Observer를 unbind한다 | `slot-plan.md` splice 요구 목록 | `H-5`×`H-102` 겹침 (A) | ✅ 재현(구현 갈래 대조) |
| `H-127` | 🟡 | `EffectHandle:Unsubscribe()`의 서술 순서가 "플래그 → cleanup → fail-fast"라 leaf 바인딩된 Effect에 부르면 **cleanup을 먼저 소진한 뒤 error**한다(`E-11`이 막으려던 그것). Effect 쪽 `Subscribe`/`Unsubscribe` 의사코드가 없고 "네 진입점 전량"이 Observer만 가리킨다 | `effect-plan.md`×`lifecycle-pattern.md` | fail-fast 3종×`Effect` cleanup (A) | — |
| `H-128` | 🟡 | M2 체크리스트대로 `Effect`를 짜면 `isRef`/`Ref:WeakCallback`/`.Revision`이 필요한데 **`Ref`는 M8**이고 M2엔 그 표면의 체크박스가 없다(M8은 "M2가 전제한다"고 인정만) | `ROADMAP.md` M2×M8 | 구현 순서 (D) | — |
| `H-129` | 🟢 | `ROADMAP.md` M2 `Effect` 체크박스가 *"`Ref`는 `:Callback`"* — `H-58` 이후 `:WeakCallback`이 정본(같은 체크박스 몇 줄 아래는 맞게 적혀 있다) | `ROADMAP.md` | 옛 문장 잔존 (사냥 #5) | — |
| `H-130` | 🟢 | `effect-plan.md`의 ⛔ 폐기 블록(`_observers` cascade) **안**을 이 커밋이 편집했다(`.Subscribed`는 구독 경로 전용) — 죽은 문단이 갓 정비된 것처럼 보이고, `H-114`의 "`_observers` 잔재 세 곳 지웠다"와도 어긋난다 | `effect-plan.md` 490~514 | 사냥 #4 | — |
| `H-131` | 🟢 | *"`for d in seen do`는 유효한 Luau가 아니다 — 테이블을 호출하려 든다"*(7차 #3, `effect-plan.md` 주석)는 **거짓** — 일반화 반복은 Luau가 지원하고 `--!strict`도 통과한다. `pairs`로 바꾼 것 자체는 무해, 근거만 틀림 | `effect-plan.md`×followup 7차 | Luau 사실 (G) | ✅ 실측 |
| `H-132` | 🟢 | `slot-plan.md` 2900행의 *"…해야 하는 일이 **셋** 늘었다"* 헤딩 아래 bullet이 넷(`H-102`가 넷째를 더함) | `slot-plan.md` 2900 | 사냥 #3 | — |
| `H-133` | 🟢 | `WeakUnsubscribe`는 **구독한 적 없는 값**에 조용히 통과한다(가드가 "강한 킵 있음"만 본다) — *"해제는 건 경로로 푼다 … 양방향 fail-fast"* 산문과 비대칭. 의도라면 명문화 | `lifecycle-pattern.md` (2) | 계약 정합 (E) | ✅ 실측 |
| `H-134` | 🟡 | `InstanceChildHandler`(`Frame { Frame {} }`의 정적 자식)의 배열 자리 부기(`setOffsetSource`/`setLength(…, 1)`)가 **어디에도 명세돼 있지 않다** — 말단 표에 행이 없고 의사코드도 없어 `H-39`의 "전수"가 못 잡았다. `Frame { Frame{}, Slot() }`이 첫 마운트에 `H-106` 가드로 즉사 | `dispatch-core-plan.md` 말단 표 × `architecture.md` × `ROADMAP.md` M5 | 레인 B (M5) | 값 트레이스 |
| `H-135` | 🟡 | `ui-shorthand-plan.md` 안에 숏핸드 retractor 모양이 **둘** — *"`function() end`이면 충분"*(136행) vs Tween 절 스케치 `function(hint) if hint == nil then destroyManagedChild end`(169행). 후자면 (A)-`nil`에서 이중 파괴, (B)에서 자식 파괴·재생성으로 트윈 스냅 | `ui-shorthand-plan.md` | 레인 B (M5) | 값 트레이스 |
| `H-136` | 🟡 | `:List` **재실행** reconcile은 배치 Blocker 없이 돌아 raw op마다 `recompute` + `Length:Set`이 난다 — *"한 사이클 전체가 끝난 뒤 한 번만"*(`dispatch-core-plan.md` 2344) 서술과 모순, 최초 population만 감싼 O(n²) 논거가 재실행엔 빠져 있다 | `slot-plan.md` `activateList`/`reconcile` × `dispatch-core-plan.md` | 레인 B (M6) | 값 트레이스 |
| `H-137` | 🟢 | `rawMove`/`rawSwap` `H-29` 규약 1의 치환 목록에 `bk.tokens`/`bk.indexOfToken`이 없다(`H-102`가 splice에만 요구) — 규약 4(이동 구간 **전부** `setLength` 재등록)에 암묵 의존, 토큰은 자리 귀속이라 치환하면 안 된다는 것도 미명시 | `slot-plan.md` `H-29` 규약 | 레인 B | — |
| `H-138` | 🟢 | `UICorner`류 숏핸드 핸들러와 `PropertyHandler`의 매치 구분(리플렉션 거부? 우선순위?)이 명세에 없다 — 이름이 우연히 프로퍼티와 겹치면 조용히 `PropertyHandler`가 먹는다 | `ui-shorthand-plan.md` × `bind-system-plan.md` | 레인 B | — |
| `H-141` | 🟡 | **확정의 근거로 인용된 사용자 발언이 실제로는 다른 것을 승인한 것** — `H-102`의 *"dispatch 로 격상"* 인용 옆에 사용자가 정한 적 없는 `bk.tokens`/`indexOfToken`(`token = {}`, 2026-08-25 `/code-review`가 발명)이 확정 메커니즘처럼 앉아 있었고, 같은 문단의 *"splice 요구 목록에 항목이 늘지 않는다"*는 구현이 스스로 깼다(둘 늘렸다). 같은 뜻의 맵(`slot._elemIndex`)이 Slot 층에 따로 살아 두 층 이원화 | `dispatch-core-plan.md` `H-102` 문단 × `slot-plan.md` | 사냥 #1(인용문 판) — Q3 처리 중 발견 | — |
| `H-140` | 🟢 | `ROADMAP.md:1124`가 아직 *"해제 시 `slot.Offset = nil`"* — `SL-75`/`D-60`이 전면 정정한 문장인데 **구현자가 실제로 보는 체크박스**에 살아남았다. 그대로 짜면 포탈 구독자가 영구히 끊긴다 | `ROADMAP.md` M6 | 사냥 #7 | — |
| `H-139` | 🟢 | `New`가 둘(모듈 팩토리 `New(): Quad` / 인스턴스 생성자 `New "Frame" {…}`)이고, `D.Frame {…}`의 파이프라인(생성 → gcconn → flatten → drive)은 네 문서에 흩어져 있어 의사코드가 한 곳에 없다 | `module-lifecycle-plan.md` / `bind-system-plan.md` | 레인 B | — |

---

## 상세

### `H-124` 🔴 — `recompute`의 `lengthList[i]` 읽기가 되감기 판정보다 앞이다 (A×C)

**무엇이 문제인가.** 확정 의사코드(`dispatch-core-plan.md` `recompute`)의 루프
본문 순서는 이렇다:

```lua
local abs = Dispatch.getOffsetAt(ownerKey, i)
bk.offsetSetUpTo = i
if offset ~= None and offset:Get() ~= abs then
    offset:Set(abs)                                     -- ← 사용자 코드가 돌 수 있는 자리
end
local v = bk.lengthList[i]                              -- ← (1) 여기서 읽고
sum += (if isState(v) then v:Get() else v)              -- ← (2) 더한 다음에
if bk.offsetSetUpTo < i then                            -- ← (3) 되감기를 본다
```

`offset:Set(abs)` 안의 사용자 코드가 **같은 owner에서 요소를 제거**하면
(`H-119`가 "실재하는 재진입 경로"로 확정하고 게이트를 세운 바로 그 상황),
`rawRemove` → `spliceArraysDown`이 `bk.N`을 줄이고 두 필드를 `index - 1`로
내린 뒤 **재진입 게이트에 걸려 `recompute`를 건너뛴다**(`H-119` 설계대로).
제어가 (1)로 돌아왔을 때 **`i > bk.N`이면 `lengthList[i]`는 이미 `nil`**이다 —
(2)에서 `attempt to perform arithmetic (add) on number and nil`. (3)의 되감기는
한 줄 늦다.

`i > bk.N`이 되는 조건은 "커서 `i`가 마지막 자리(`i == N`)일 때 어느 자리든
하나 제거" 또는 "`i`보다 앞·같은 자리에서 여러 개 제거(`rawSplice`/`rawClear`)".
`H-113`(커서 자리 splice)은 `j == i < N`만 봤고, `H-119`는 "건너뛴 몫은 되감기가
복구한다"고 했는데 **되감기에 도달하기 전에 죽는다**.

**어떻게 재현했나** — 참조 구현을 현재 계약(두 필드·`-1`·`H-119` 게이트·
클램프)으로 다시 전사한 `dispatch9.luau` 위에서(`recompute`는 위 순서 그대로):

```lua
-- d10_remove_at_tail.luau (요지)
local s1, s2, s3 = L("s1"), L("s2"), L("s3")     -- 각각 평범한 자식 하나(길이 1)
local O = D.newSlot("O", { s1, s2, s3 }); D.mountTop(inst, O)   -- offsets 0,1,2 / O.Length 3
local w = s3.Offset:Observer(function(_, _, from)             -- 마지막 자리(i = N = 3)의 offset을 관측
    if from == nil or fired then return end; fired = true
    D.rawRemove(O, 1)                                         -- 그 통지 도중 O:Remove(1)
end); q.bindLifetime(inst, w)
D.rawAdd(s1, {name="s1_y"})   -- s1 길이 1→2 → O의 setLength Observer → recompute(O) → i=3에서 s3.Offset:Set(3) → watcher
```

출력(전사):

```
초기: s3.Offset 2  O.Length 3
  [watcher] s3.Offset -> 3 → O:Remove(1) 호출
  [watcher] rawRemove 반환. N = 2  offsetSetUpTo = 0
rawAdd(s1, child) → ERROR: ./dispatch9.luau:77: attempt to perform arithmetic (add) on number and nil
O.Length 3 | N 2 | s2.Offset 2 (기대 0) | s3.Offset 3 (기대 1)
```

`rawRemove`는 게이트(`bk.recomputeBlocker:IsOn()` = true)에서 정확히 건너뛰었고
(`spliceArraysDown`이 `offsetSetUpTo`를 `0`으로 당겨둔 것까지 설계대로), 바깥
루프가 `lengthList[3]`(이제 `nil`)을 읽다 죽었다.

**그대로 구현하면.** (a) 사용자가 `slot.Offset`을 관측하는 콜백에서 형제를 지우면
— 코퍼스가 정상 경로로 확정한 재진입 — 익명 산술 에러로 죽고, (b) `error`가
`bk.recomputeBlocker:On()`과 `OffWithoutEmit()` 사이에서 나므로 **그 owner의
`recomputeBlocker`가 영원히 켜진 채 남아** 이후 모든 `gatedRecompute`/명시 호출이
조용히 건너뛰어진다(`H-87`의 "독 든 Blocker"와 같은 부류 — 그 Slot의 레이아웃이
영구 동결). `Length`도 낡은 채(위 출력의 `O.Length 3`, 실제 2).

**처방 갈래**(§4 Q1): (a) 되감기 판정을 `lengthList[i]` 읽기 **앞**으로 —
`if bk.offsetSetUpTo < i then i = math.max(…, 1); sum = prefix[i]; continue end`
뒤에 읽기·누적·`i += 1`. 되감기가 없는 경우엔 지금과 동일하게 "Set 뒤에 읽는다"가
유지되므로 `H-113`의 *"`sum`은 안 낡는다"* 논증도 그대로다. 제거가 `i`보다 **뒤**
자리면 `N ≥ i`라 `nil`이 안 나온다(`p > i` 제거는 `offsetSetUpTo`를 `p-1 ≥ i`로만
내려 되감기 없음, 그러나 `N ≥ p-1 ≥ i`). (b) 읽기 앞에 `if i > (bk.N or 0) then
break end`만 두는 안 — 크래시는 막지만 그 자리부터 되감기 없이 끝나므로 (a)가
필요 없어지지 않는다. **권고 (a).**

### `H-125` 🔴 — 재마운트에서 `_baseObserver`가 잠들어 있는 창 (A×C)

**무엇이 문제인가.** `H-3`이 세운 "베이스가 바뀌면 두 필드를 `0`으로"의 코드
경로는 **`slot._baseObserver` 콜백 하나**다(`H-119`가 그 콜백에 `bk.offsetCacheValidUpTo,
bk.offsetSetUpTo = 0, 0`을 실제로 넣었다). 그런데 재마운트 순서가:

```lua
-- unmountSlotTree(slot)                                              (slot-plan.md)
if slot._baseObserver then unbindLifetime(slot._baseObserver) end   -- ← 관측자가 잠든다
-- … 나중에 attachSlot → materializeSlotTree(slot, newTarget, ownerKey, position)
local offsetSource = slot.Offset or Source(0)
Dispatch.setOffsetSource(ownerKey, position, offsetSource)          -- ← 여기서 slot.Offset:Set(새 베이스)
slot.Offset = offsetSource
local blocker = getBlocker(slot); blocker:On()
if slot._baseObserver then
    bindLifetime(physicalTarget, slot._baseObserver)                -- ← 그 뒤에야 깨어난다(바인드는 발화가 아니다)
```

`setOffsetSource`의 `source:Set(offset)`이 전파 루프를 돌 때 `_baseObserver`는
`canExecute` 거짓(gcconn 없음, `.Subscribed` 없음)이라 **조용히 건너뛰어진다**
(그게 `canExecute` 게이트의 정상 동작이다). 두 필드는 옛 값(`N_old`)에 그대로,
`offsetCache[1]`은 옛 베이스. 이어서 꼬리의 `recompute(slot, bk)`가 `i = 1`에서
`getOffsetAt(slot, 1)` → `1 <= offsetCacheValidUpTo` → **`offsetCache[1]`(옛
베이스) 반환** → 자식 offset이 옛 베이스 + 접두합으로 "이미 맞다"고 판정돼
`Set`이 안 난다. 그 다음 부모의 `setLength(ownerKey, position, slot.Length)`가
부모 `recompute`를 돌려도 `slot.Offset`은 이미 새 값이라 `~=` 가드에 걸려
`_baseObserver`는 **끝내 안 불린다**.

`H-3` 자신이 *"재마운트는 더 나쁘다: `bk`는 `Relate(slot)` 위에 있어 언마운트를
넘어 살아남으므로 `offsetCache[1]`에 옛 베이스가 남는다"*라고 정확히 경고해뒀는데,
그걸 닫는 유일한 경로가 그 순간 잠들어 있다. **파괴(`destroySlotTree`) 뒤
재사용은 무사하다** — 거기선 `_baseObserver = nil`이라 재마운트가 새 Observer를
만들고, 그 "등록 즉시 1회 실행"이 두 필드를 `0`으로 내린다(가드에 걸려
`recompute`는 안 하지만 `0`은 남는다). **깨지는 건 언마운트 보존 경로**
(`rawUnmount`/`rawDetach` → `Detach` 복귀·`State<Slot>` 교체·포탈)뿐이다.

**어떻게 재현했나** (`d12_remount_stale.luau`, 같은 전사물):

```lua
local t1, t2 = D.newSlot("t1", {{name="t1x"}}), D.newSlot("t2", {{name="t2x"}})
local S = D.newSlot("S", { t1, t2 })
local O = D.newSlot("O", { {name="a"}, {name="b"}, S })   -- S의 베이스 2
D.mountTop(inst, O)                                       -- t1.Offset 2, t2.Offset 3
D.rawRemove(O, 3)          -- (전사물에선 unmountSlotTree로 흉내 = rawUnmount 경로)
local O2 = D.newSlot("O2", {}); D.mountTop(inst2, O2)
D.rawAdd(O2, S)            -- → materializeSlotTree(S, inst2, O2, 1): 베이스 0
```

출력(전사):

```
1차 마운트: S.Offset 2 (기대 2) t1 2 (2) t2 3 (3)
  S.bk: cacheValid 2 setUpTo 2 cache[1] 2
언마운트 후: canExecute(S._baseObserver) = false | S.Offset(보존) 2
재마운트: S.Offset 0 (기대 0) | t1.Offset 2 (기대 0) | t2.Offset 3 (기대 1)
  S.bk: cacheValid 2 setUpTo 2 cache[1] 2 (베이스 0이어야)
  ❌ 자식 offset이 옛 베이스 위에 남았다
```

**도달 경로는 넷** — 포탈(언마운트→재마운트), `Detach` 복귀(레인 B가 `:List`의
`settle` → `rawAdd(…, true)`로 실제로 밟는 것을 확인 — `H-139` 꼬리의 교차 항목),
`State<Slot>` 교체(= 언마운트, 같은 `unmountSlotTree`), `rawUnmount`로 꺼낸 Slot의
재배치.

**그대로 구현하면.** 포탈/Detach 복귀/`State<Slot>` 교체로 옮겨진 Slot의
**중첩 Slot 자식**이 옛 베이스 위의 `Offset`을 유지한다 — `H-3`이 경고한
*"위로는 맞고 옆으로만 틀린다"*의 재마운트 판. 그 아래로 재귀하므로 중첩
서브트리가 통째로 옛 좌표계에 남고, 다음 계기(그 자리 앞 형제의 길이 변경)까지
아무도 고치지 않는다.

> **⚠️ [2026-08-26 범위 정정 — Q2 처리 중 실측] 피해 범위는 "자식 전부"가
> 아니라 *부기를 경유하는 중첩 Slot의 `Offset`*이다.** 처음엔 유저 체인
> (`updateFn`이 받은 `offset`으로 `LayoutOrder`를 정하는 것)까지 안 고쳐진다고
> 적었는데 **틀렸다** — `setOffsetSource`의 `Set`은 전파 루프를 정상적으로 돌고,
> 유저 체인의 말단 Observer는 **요소 자신의 인스턴스**에 `bindLifetime`돼 있어
> (언마운트는 요소를 파괴하지도 `unbindLifetime`하지도 않는다) `canExecute`가
> 참이다. 건너뛰어지는 건 `_baseObserver` 하나뿐이다. 실측은
> `-round9-followup.md`의 Q2 절(`d16_remount_variants.luau`, `[none]` 행에서
> `userLO`는 정확하고 `C.Offset`만 어긋난다).

**처방 갈래**(§4 Q2): (a) **`materializeSlotTree` 진입부**(`setOffsetSource`
앞)에서 `bk.offsetCacheValidUpTo, bk.offsetSetUpTo = 0, 0` — "실체화는 항상
1번부터"라는 한 줄 불변식이 되고 첫 마운트엔 무해(이미 0). (b) `unmountSlotTree`
꼬리에서 같은 초기화 — 잠재우는 쪽이 치우는 대칭. (c) `_baseObserver` 바인드와
`blocker:On()`을 `setOffsetSource` **앞**으로 옮겨 그 콜백이 깨어 있게 하는 안 —
콜백이 가드에 걸려 `0`만 남기고 돌아오므로 동작은 되지만, "관측자가 깨어 있어야
초기화된다"는 우연에 계속 기댄다. **권고 (a)** — `_baseObserver`의 `0`은
런타임 베이스 변경용으로 그대로 두고, 실체화 경계엔 명시 초기화를 둔다.

### `H-126` 🟡 — `spliceArraysUp`이 비운 자리의 `observers`/`tokens` (A×C)

**무엇이 문제인가.** `slot-plan.md`의 `spliceArrays*` 요구 목록은 비워지는
자리에 대해 `lengthList[index] = 0`(`H-5`)과 `sourceList[index] = None`
(*"`sourceList`가 `None`으로 채워지는 것과 대칭"*)만 명시한다. `bk.observers`·
`bk.tokens`는 *"다른 배열과 같이 당긴다 / 완전히 같은 처리"*라고만 돼 있다.
`table.insert(t, index, x)` 의미론이면 자리가 자연히 비지만, **7라운드 전사물
`d7_splice_fix.luau`처럼 `for i … do t[i] = t[i+1]` 복사 루프로 짜면**(그 전사물의
Down이 그렇고, Up은 아무도 안 썼다) `observers[index]`와 `tokens[index]`에 옛
값이 **남는다** — 곧 `index`와 `index+1`이 같은 Observer·같은 토큰을 가리킨다.

그 뒤 `setLength(self, index, …)`는 `oldObserver = bk.observers[index]`를 보고
**`unbindLifetime`한다** — 그게 이제 `index+1`(밀려난 요소)의 Observer다. 그리고
`indexOfToken[token]`이 `index`로 덮여 `index+1`의 `gatedRecompute`가 엉뚱한
자리를 무효화한다(`H-102` 그 자체).

**어떻게 재현했나** (`d15_spliceup_vacate.luau` — 두 구현 갈래를 같은 전사물
위에서 대조; `vacate`가 비운 자리를 `nil`로 두느냐):

```
[vacate=true]  A.Length=3 후 B.Offset = 4 (기대 4) | canExecute(observers[2]) = true  | indexOfToken[tokens[2]] = 2
[vacate=false] A.Length=3 후 B.Offset = 2 (기대 4) | canExecute(observers[2]) = false | indexOfToken[tokens[2]] = 1
```

`vacate=false`에선 밀려난 `A`(2번 자리)의 길이 Observer가 unbind돼 **A가
커져도 B가 영영 안 밀린다.**

**그대로 구현하면.** 구현자가 어느 쪽으로 짜든 "문서대로"라고 말할 수 있는
자리에서, 한쪽은 `:Add(x, index)`(중간 삽입) 뒤 그 자리에 있던 요소의 길이
변경이 조용히 무시된다.

**처방**(§4 Q3): 요구 목록에 한 줄 — *"`spliceArraysUp`은 `observers[index]`·
`tokens[index]`를 `nil`로 비운다(`lengthList`/`sourceList` 자리표시자와 같은
자리)"* 또는 *"네 배열 전부 `table.insert`/`table.remove` 의미론"*. 새 결정이
아니라 누락 명시.

### `H-127` 🟡 — `EffectHandle:Unsubscribe()`의 순서와 의사코드 부재 (A)

**무엇이 문제인가.** 이 커밋이 `Subscribe`/`Unsubscribe`/`WeakUnsubscribe`를
전부 fail-fast로 확정하며 `lifecycle-pattern.md` (2)에 **`Observer:` 네 진입점**
의사코드를 새로 썼고 *"아래가 네 진입점 전량이고 소스다"*라고 적었다. 그런데
`Effect`도 같은 레지스트리·같은 `.Subscribed`를 쓰고(`isBoundAlive`가
`isObserver(value) or isEffect(value)`), `effect-plan.md`는 `EffectHandle`의
`:Subscribe()`/`:Unsubscribe()`를 **산문으로만** 규정한다. 그 산문의 순서가:

1. `handle.Subscribed = false` (향후 재실행 끊김)
2. 직전 cleanup을 정확히 1회 호출
3. **[2026-08-26 정정]** fail-fast — 약하게만 구독된/구독 안 한 값이면 error

`E-11`은 *"leaf 바인딩된 핸들에는 `:Unsubscribe()`가 아예 안 먹는다"*를
확정했다(cleanup을 앞당기면 dedup 재디스패치에서 Effect가 조용히 죽는다는
근거). 위 순서대로 짜면 leaf 바인딩된 Effect에 `:Unsubscribe()`를 부를 때
**2번이 cleanup을 소진한 뒤 3번이 error** — 에러는 나지만 `E-11`이 막으려던
피해(cleanup 앞당김, `_installed = false`)는 이미 일어난 뒤다. Observer 쪽
의사코드는 가드가 첫 줄이라 이 문제가 없다.

부수로: `EffectHandle`에 `WeakSubscribe`/`WeakUnsubscribe`가 있는지, `Subscribe`가
Observer의 것을 그대로 쓰는지(`canBound` 게이트 포함) 어디에도 없다 — 전사물은
`Observer.Subscribe` 등을 그대로 물려받는 쪽으로 옮겼고(`core9.luau`), 그렇게
하면 `t12` 매트릭스가 전부 기대대로 돈다(§5).

**처방**(§4 Q4): `effect-plan.md`에 의사코드 한 블록 — `Unsubscribe`는
**Observer의 게이트를 먼저**(`Observer.Unsubscribe(self)` 위임 → 통과해야만)
`_consumeCleanup()`; `Subscribe`/`WeakSubscribe`/`WeakUnsubscribe`는 Observer
것을 그대로 재사용한다고 명시(핸들 자신만, 내부 Observer 무관 — `H-59`).
`lifecycle-pattern.md`의 *"아래가 네 진입점 전량이고 소스다"* 문장은 "Observer의
네 진입점, Effect는 같은 것을 재사용"으로.

### `H-128` 🟡 — M2의 `Effect`가 M8의 `Ref` 표면을 전제한다 (D)

**무엇이 문제인가.** `ROADMAP.md` M2를 위에서부터 짜는 시뮬레이션: `Effect(fn,
...deps)` 체크박스와 그 아래 "구현 시 같이 만들 것"이 `isRef(d)` 분기 →
`d:WeakCallback(onRefFire)` → `self._epochs:Sync(d)`(`d.Revision` 읽기)를
요구한다. 셋 다 **`Ref.luau`의 표면**이고 `Ref.luau`는 **M8**이다. M2 "공통
기반"엔 `Brand`/`Relate`/`LifetimeHandle`만 있고 `Ref`의 최소형 체크박스가 없다.
M8 머리는 *"M2가 이미 이 표면을 전제한다"*라고 **인정만** 하고, M2는 이 앞으로
참조를 어디서도 말하지 않는다. 8라운드 §5 D각도의 *"앞으로 참조 없음"*은 이
자리를 못 봤다(그때 `Effect`의 `Ref` 분기가 `H-107`로 막 다시 쓰이던 중이었다).

**그대로 구현하면.** M2 구현자가 `Effect`의 `Ref` 분기를 (a) `isRef` 스텁으로
비워두거나 (b) M8을 앞당겨 절반쯤 짜게 된다 — 어느 쪽인지 체크박스가 정하지
않으므로 M2의 "mock 대상 테스트"가 `Ref` dep 경로를 안 돌린 채 M2가 끝난다.

**처방 갈래**(§4 Q5): (a) M2 공통 기반에 **`Ref` 최소형 체크박스** 신설 —
`.Value`/`.Revision`/`:Set`/`:WeakCallback`/`:Callback`/`:Uncallback`/`isRef`
(`Epoch`를 만족하는 데 필요한 것만; `PreRef`/`PostRef`/`:Wait`/디스패치 핸들러는
M8 그대로). `Ref`가 `Epoch`인 것 자체가 M2의 결정(`H-58`/`H-64`/`H-70`)이라
자연스럽다. (b) M2에선 `Ref` dep을 **명시적으로 미룬다**고 적고 M8에 "`Effect`의
`Ref` 분기 + 그 테스트"를 체크박스로. **권고 (a)** — `Effect`의 `_epochs`
배선이 `isEpoch` 분기로 갈리는 걸 M2 안에서 한 번은 실제로 돌려봐야 한다.

### `H-129` 🟢 — ROADMAP `Effect` 체크박스의 *"`Ref`는 `:Callback`"*

`ROADMAP.md` M2 `Effect(fn, ...deps)` 체크박스: *"각각에 맞는 구독(State/Source는
`Observer`, `Ref`는 `:Callback`)을 걸어"*. `H-58` 이후 정본은 `:WeakCallback`
(강한 셋에 걸면 `Ref`가 `Effect`를 영원히 붙든다 — 7차 #4가 다이어그램에서 잡은
바로 그것). 같은 체크박스 몇 줄 아래 "구현 시 같이 만들 것"은 `:WeakCallback()`
으로 맞게 적혀 있다. 사냥 #5(고친 사실이 옆 문장에서 되살아남)의 사례.

### `H-130` 🟢 — 폐기 블록 안을 이 커밋이 편집했다

`effect-plan.md` 468~514: ⛔⛔ 배너(*"이 문단 전체는 옛 모델이다 … `_observers`
배열/cascade/`Subscribe` 순회는 전부 `_deps` 하나와 `_blocker`로 대체됐다"*)
아래 죽은 문단인데, 이 커밋의 diff가 그 안 한 줄(`.Subscribed`는 전역 →
**구독 경로** 전용)을 고쳤다. 지시서 §3-4가 경고한 정확히 그 모양이다 — 날짜
마커는 없지만 살아 있는 문장과 같은 표기로 갱신돼 있어 "관리되는 문단"으로 읽힌다.
같은 블록에 `handle._observers[i] = observer` 등 옛 필드가 그대로 살아 있어
followup의 *"같은 파일의 `_observers` 잔재 표기 세 곳도 같이 지웠다"*(`H-114`)와도
안 맞는다(배너 아래라 오독은 안 되지만 "세 곳"이 전수가 아니었다). 처분: 그
한 줄을 되돌리거나(배너만 있고 본문은 안 만진다는 새 규칙), 블록을 `archive/`로.

### `H-131` 🟢 — *"`for d in seen do`는 유효한 Luau가 아니다"*는 거짓 (G)

followup 7차 #3과 `effect-plan.md` 생성자 주석(*"`for d in seen`은 테이블을
호출하려 들어 죽는다"*). 실측:

```lua
--!nocheck   (g3_for_in_table.luau)
local seen = { a = true }
local ok, err = pcall(function() for d in seen do print(d) end end)
print("for d in seen do (일반화 반복):", ok, err)      --> a / true nil
```
```lua
--!strict    (g3b_for_in_strict.luau → luau-analyze exit 0, 진단 0건)
local seen: { [string]: boolean } = { a = true }
for d in seen do print(d) end
```

Luau의 일반화 반복(`__iter`/테이블 직접 순회)은 런타임·`--!strict` 둘 다
통과한다 — 7라운드 전사물 `core.luau` 자신이 `for sub in node.subs do`로 돌고
있었다. `pairs(seen)`로 바꾼 코드는 무해하지만 **근거 문장이 틀렸고**, 그
문장이 `base/`에 Luau 사실로 남아 있으면 다음 구현자가 일반화 반복을 피해
돌아간다. 주석의 근거를 지우거나 "스타일 통일"로 바꿀 것.

### `H-132` 🟢 — "셋 늘었다" 아래 bullet 넷

`slot-plan.md` 2900 *"`spliceArraysUp`/`spliceArraysDown`이 해야 하는 일이 **셋**
늘었다"* — 아래 bullet은 `_elemIndex`(2903) / 자리표시자(2912) / 캐시 당김(2921)
/ **`bk.tokens`·`indexOfToken`(2950, 7라운드 `H-102` 신설)** 넷. 이 커밋이 그
절의 캐시 bullet을 크게 고치면서 헤딩 개수를 안 봤다(사냥 #3, 8라운드 2차/3차와
같은 모양). `H-126`을 반영하면 다섯이 되므로 개수 대신 "아래 목록이 소스"로.

### `H-133` 🟢 — `WeakUnsubscribe`의 비대칭 (E)

`lifecycle-pattern.md` (2) 의사코드의 `WeakUnsubscribe`는 `Subscribed[self] ~= nil`
(강한 킵)만 막는다. 구독한 적 없는 값·이미 `WeakUnsubscribe`된 값에 부르면
**조용히 통과**(`WeakSubscribed[self] = nil; .Subscribed = false`). 실측
(`t12_subscribe_failfast.luau`):

```
구독 안 한 값에 Unsubscribe      → error: not subscribed strongly; use :WeakUnsubscribe()
구독 안 한 값에 WeakUnsubscribe  → 통과(no error)
```

반면 산문은 *"양방향 대칭 가드 … 구독한 적 없는 값에 부르는 것도 error다"*
(`Unsubscribe`에 대해서만 말하지만, "해제는 건 경로로 푼다 **하나**"라는 문장은
약한 쪽도 포함해 읽힌다). leaf 바인딩된 Observer에 `WeakUnsubscribe`를 부르면
`.Subscribed = false` 대입만 하고 지나간다(gcconn 경로는 안 건드려 무해). 의도된
비대칭이면(약한 해제는 GC 대체 수단이라 관대해도 된다) 그렇게 명문화, 아니면
`WeakSubscribed[self] == nil`도 error.

---

## 레인 B — M5+ 값 단위 트레이싱 (첫 시도)

*(별도 패스로 수행 — 지시서 §2 레인 B 네 항목을 실제 값으로 한 사이클씩
돌렸다: 그룹 `Attribute` 위임 체인, `D` 생성자, 숏핸드 → `PropertyHandler`,
`:List` reconcile `{a,b}` → `{b,a,c}` → `{b}` + 중첩 Slot 요소 + `Detach`. 발견은
메인 패스가 원문과 대조해 확인한 뒤 `H-134`부터 번호를 붙였다.)*

### `H-134` 🟡 — `InstanceChildHandler`에 배열 자리 부기 명세가 없다

**무엇이 문제인가.** 말단 핸들러는 *"예외 없이 자기 배열 위치의
`setOffsetSource`/`setLength`를 등록한다"*(`dispatch-core-plan.md`의 `H-39`
블록)인데, `Frame { Frame {} }`의 자식 Instance를 받는 핸들러
(`quad-roblox/src/Handlers/InstanceChild.luau`, `architecture.md` 306행
*"k:number, v:Instance"*)는 (a) `dispatch-core-plan.md`의 말단 핸들러 표에
**행이 없고**, (b) 의사코드가 코퍼스 어디에도 없어 `H-39`의 *"전수 grep"*이 잡을
수 없었으며, (c) `ROADMAP.md` M5 체크박스(903행)는 파일 이름만 적혀 있다.
Length/Offset 절 머리(1365행)가 *"정적 단일 자식은 상수 `1`"*이라고 하지만
**누가** 등록하는지는 안 적혀 있다.

**값 단위 트레이스** — `inst = Frame { Frame{} (k=1), Slot() (k=2) }`,
`Dispatch.drive(inst, {[1]=child, [2]=S})`:

1. `getBlocker(inst):On()`. `k=1`: `getHandler(inst,1,child)` →
   `InstanceChildHandler` → `process`: `child.Parent = inst`(물리) — 부기 호출이
   명세에 없으므로 **없다고 가정**. `bk(inst)` = `{lengthList={}, sourceList={},
   N=nil, offsetCacheValidUpTo=0, offsetSetUpTo=0}` 그대로.
2. `k=2`: `SlotHandler.process` → `attachSlot(S, inst, inst, 2)` →
   `materializeSlotTree(S, inst, inst, 2)` → `Dispatch.setOffsetSource(inst, 2,
   S.Offset)` → `Dispatch.getOffsetAt(inst, 2)`:
   - `offsetCacheValidUpTo == 0` → `offsetCache[1] = 0`, `offsetCacheValidUpTo = 1`
   - `at(2) > 1` → `cur = offsetCache[1] = 0`; `for i = 1, 1`:
     **`bk.lengthList[1] == nil`** → `H-106` 가드가 `error(...)` — 첫 마운트에서 즉사.
3. `Slot()`이 `k=1`이고 `Frame{}`가 `k=2`면 반대로 **안 터진다**(`bk.N`이 1에서
   멈춤) — `H-39`가 서술한 *"가끔 되고 가끔 터지는"* 모양 그대로다.

**그대로 구현하면** — 정적 자식 뒤에 Slot이 오는 가장 흔한 레이아웃이 첫
마운트에서 죽는다. `H-39`가 넷을 고치면서 이 핸들러만 놓친 것은 의사코드가
아예 없어서다.

**처방**(§4 Q8) — 말단 표에 `InstanceChildHandler | 말단 | Parent 대입 (+ 부기 —
`setOffsetSource(inst, k, None)` → `setLength(inst, k, 1, inst)`)` 행을 넣고,
`ROADMAP.md` M5 체크박스에 같은 두 줄을 명시. 반환 클로저는 (B)/단순 철거 시
`setOffsetSource(None)` → `setLength(0)` 순서로 해제(`SlotHandler`의 retractor와
같은 모양). 대안(부기를 `Dispatch.drive`가 `type(k)=="number"` 분기에서 일괄
등록)은 이미 기각된 안(*"모든 핸들러가 `k=number`일 때 처리하도록 두는"*,
1387행)이라 비권고. 갈래는 사실상 없다 — 확인만.

### `H-135` 🟡 — 숏핸드 retractor의 두 모양

**무엇이 문제인가.** `ui-shorthand-plan.md`의 *"`v`가 `nil`인 경우"* 절(136행)은
*"반환 클로저가 할 일이 없어 `function() end`이면 충분"*이라 확정하는데, 같은
문서의 *"Tween 지원"* 절 스케치(169행)는
`return function(hint) if hint == nil then destroyManagedChild(inst, k) end end`다.
하강 diff 계약상 `hint == nil`은 **단순 철거**(`retractFrom`) 또는 **(A) 분기에서
새 값이 `nil`**일 때다.

**값 단위 트레이스** — `Frame { UICorner = cornerState }`, `cornerState:
State<number?>`:

1. `drive`: `(inst,"UICorner")` index 1 = `StoreBind`(관측자 등록) → 즉시 1회 →
   `Dispatch.process(inst,"UICorner",8,2)` → index 2 = `UICornerHandler` →
   `ensureManagedChild` → `child`(`Relate[(inst,"UICorner")] = child`) →
   `Dispatch.process(child,"CornerRadius",UDim.new(0,8),1)` → `PropertyHandler`
   슬롯 `nil` → 즉시 세팅, 슬롯 `true`. 반환 R(hint 버전).
2. `cornerState:Set(Tween{Value=12,Time=0.3})` → (A): `R(tween)` — `hint ~= nil`
   → 아무것도 안 함 ✓ → `process` → 같은 `child` 재사용 →
   `Dispatch.process(child,"CornerRadius",Tween{Value=UDim(0,12)},1)` → PH 슬롯
   `true` → 트윈 시작 ✓.
3. `cornerState:Set(nil)` → `getHandler(inst,"UICorner",nil)` = `UICornerHandler`
   (키 매치) → (A): **`R(nil)` → `destroyManagedChild`** → 이어서
   `process(inst,"UICorner",nil,2)` → `v == nil` → **`destroyManagedChild` 한 번
   더** — 이중 파괴(`Relate` 항목이 이미 `nil`이면 무해하지만 계약상 두 자리가
   같은 일을 한다).
4. `State<State<number>>`에서 안쪽이 `8`(값) ↔ `innerState`로 바뀌면 index 2의
   핸들러가 `UICornerHandler` ↔ `StoreBind`로 바뀌어 **(B) 분기** →
   `retractFrom(inst,"UICorner",2)` → `R(nil)` → 자식 파괴 → 새 핸들러 설치 →
   결국 다시 `UICornerHandler`가 `ensureManagedChild`로 **새 자식 생성** →
   `(child',"CornerRadius")` 슬롯이 `nil`이라 *"첫 세팅은 스냅"* 규칙에 걸려
   진행 중이던 트윈 문맥이 사라진다. `function() end`였다면 자식이 `Relate`에
   남아 재사용되고 슬롯도 이어진다.

**그대로 구현하면** — 어느 스케치를 옮기느냐에 따라 자식 생존 정책이 갈린다.
두 서술이 같은 문서에서 각각 "확정"이다.

**처방 갈래**(§4 Q9) — (a) `function() end`로 통일(자식 제거는 `process(nil)`
한 경로, `Relate`가 `inst` weak라 부모가 죽으면 같이 사라짐 — `UI-11`의 논리와
결이 같다). Tween 절의 스케치를 이에 맞춰 고친다. (b) `hint == nil` 파괴를
유지하고 (A)-`nil` 이중 파괴와 (B) 깜빡임을 문서화. **권고 (a).**

### `H-136` 🟡 — `:List` 재실행 reconcile에 배치 Blocker가 없다

**무엇이 문제인가.** `dispatch-core-plan.md` 2344행: *"`:List` reconcile에서
`Length` 갱신 시점: 한 사이클(여러 항목이 한꺼번에 추가/제거되는 경우 포함)
전체가 끝난 뒤 **한 번만**"*. 그런데 `activateList`의
`data:Observer(function() reconcile(data:Get()) end)`가 **재실행**될 때는 아무도
`getBlocker(self):On()`을 하지 않는다 — Blocker는 최초 population
(`materializeSlotTree` / `Slot:List`의 `_physicalTarget` 분기)만 감싼다
(`slot-plan.md` 1342~1700 구간에 `getBlocker`/`blocker:On` 호출이 없다).

**값 단위 트레이스** — 마운트된 `slot`, `_elements={Fa,Fb}`, `data:Set({b,a,c})`:

1. `i=1 b`: `indexOfRaw(Fb)=2 ~= slotPos 1` → `rawMove(slot,2,1)` → 규약 4대로
   `setLength(slot,1,1,frame)`, `setLength(slot,2,1,frame)` → 각각
   `gatedRecompute` → `blocker:IsOn()` **거짓**, `recomputeBlocker` 거짓 →
   **`recompute` 2회**(sum 2, `Length` 불변이라 `Set`은 없음).
2. `i=3 c`: `rawAdd(slot,Fc,3)` → `nativeInsert(frame, getOffsetAt(slot,3)=2,
   {Fc})` → `setLength(slot,3,1,frame)` → **`recompute` 3회째** → `slot.Length:
   Set(3)` → 부모 `gatedRecompute(frame)` → `recompute(frame)` 1회.
3. `data:Set({b})`: 소멸 루프 `a` → `rawRemove(slot,2)` → `spliceArraysDown` →
   게이트 통과 → `recompute` → `Length:Set(2)` → 부모 `recompute`; `c` → 같은
   경로 → `Length:Set(1)` → 부모 `recompute`. **한 사이클에 `Length:Set` 2회,
   부모 `recompute` 2회.**

정합성은 깨지지 않는다(각 `recompute`가 매번 옳은 값을 쓴다). 문제는 (a)
서술과 의사코드가 어긋나고, (b) n개 아이템 사이클에 `recompute` O(n)회 × O(n)
= O(n²) + 부모 캐스케이드가 아이템 수만큼 난다 — 최초 population을 Blocker로
감싼 이유(*"아이템마다 `recompute`가 돌아 O(n²)"*, `slot-plan.md` 1319행)가
재실행엔 적용되지 않은 채 남아 있다.

**처방 갈래**(§4 Q10) — (a) `reconcile` 본문을 `Slot:List`의 `_physicalTarget`
분기와 똑같이 감싼다 — 진입 시 `getBlocker(self):On()`, 끝에
`blocker:OffWithoutEmit()` + `if not bk.recomputeBlocker:IsOn() then
recompute(self, bk) end`. `raw*`의 명시 호출은 이미 `getBlocker(self):IsOn()`을
보므로(`H-119`) 추가 배선이 없고, `getOffsetAt`/`physIndex`는 Blocker와 무관하게
정확하다(최초 population과 같은 논증). `updateFn`이 도중에 던지면 Blocker가
켜진 채 남는 것은 `materializeSlotTree`가 이미 감수하는 것과 같은 부류(`pcall`
안 씀). (b) 2344행 서술을 "raw op마다"로 고치고 비용을 문서화. **권고 (a).**

### `H-137` 🟢 — `rawMove`/`rawSwap` 규약 1과 `bk.tokens`/`bk.indexOfToken`

`H-29` 규약 1(2697행)은 `_elements`/`_elemIndex`/`lengthList`/`sourceList`/
`observers`만 치환 대상으로 들고, `H-102`가 splice에 요구한 `bk.tokens`/
`bk.indexOfToken` 갱신(2950행)은 언급이 없다. 트레이스하면 **규약 4가 이동 구간
전 위치에 `setLength`를 다시 태우는 한 정합하다**: 이동 구간 `p`마다
`setLength(p)`가 `oldObserver = bk.observers[p]`(치환으로 옮겨온 남의 observer)를
`unbindLifetime`하고, `token = bk.tokens[p]`(자리 귀속, 치환 안 됨)로 새 클로저를
만들어 `indexOfToken[token] = p`를 다시 쓴다 — 구간 안의 옛 observer는 전부
정확히 한 번 풀린다. 즉 규약 1의 `observers` 치환은 **무의미하고**, 토큰은
치환하면 안 된다(치환해도 `setLength`가 되돌리긴 한다). 규약에 *"`bk.tokens`/
`indexOfToken`은 자리 귀속이라 치환하지 않는다 — 규약 4가 재등록한다"*를
명시하면 닫힌다. 규약 4를 "양끝만"으로 읽으면 깨지므로 "이동 구간 전부"도 같이
못박을 것. (`H-126`과 같은 부류 — `tokens`/`observers`의 자리 귀속을 splice/
move 양쪽에서 한 번에 규정하는 게 낫다.)

### `H-138` 🟢 — 숏핸드 핸들러와 `PropertyHandler`의 매치 구분

`Frame { UICorner = 8 }`에서 `getHandler(inst,"UICorner",8)`이 `UICornerHandler`를
고르려면 `PropertyHandler.isHandlable`이 `"UICorner"`를 거부하거나(리플렉션:
Frame의 프로퍼티가 아님) 숏핸드 우선순위가 더 높아야 한다. 어느 쪽인지
`ui-shorthand-plan.md`/`bind-system-plan.md` 어디에도 없다. 리플렉션 거부에
기대면 되긴 하지만, `UIScale`처럼 이름이 우연히 프로퍼티와 겹치는 경우가 생기면
조용히 `PropertyHandler`가 먹는다. 한 줄 명시 권고.

### `H-139` 🟢 — `New` 둘 / `D` 파이프라인 의사코드 부재

`module-lifecycle-plan.md`의 `local function New(): Quad`(모듈 팩토리,
`architecture.md` 확정 13번)와 `bind-system-plan.md`의 `New "Frame" { ... }`
(`D/init.luau`의 인스턴스 생성자)가 같은 이름이다. 패키지가 달라 런타임 충돌은
없지만 문서에서 `New()`/`New "Frame"`이 섞여 나온다. 또 `D.Frame {...}`가
실제로 하는 일의 순서 — `Instance.new` → gcconn/gchold(`lifecycle-pattern.md`
(0)) → `flatten`(`modifier-plan.md`) → `Dispatch.drive`(pre-pass 포함) → 반환 —
는 네 문서에 흩어져 있고 한 곳에 의사코드가 없다(값 트레이스는 §5의 `D` 항목 —
산문대로 이어 붙이면 성립한다).

**교차 — `H-125`의 도달 경로 하나 더.** `updateFn`이 중첩 Slot `S`를 `Detach`한
뒤 다음 사이클에 `prev`를 돌려주면 `settle` → `rawAdd(self, S, slotPos, true)` →
`attachSlot(S, …)` → `materializeSlotTree(S, …)`: 첫 줄 `setOffsetSource(self,
slotPos, S.Offset)`이 `S.Offset:Set(newAbs)`를 내는데, 그 시점 `S._baseObserver`는
`unmountSlotTree`(`rawDetach` 경유)가 `unbindLifetime`해둔 상태 — `H-125`의 창
그대로다. `:List`에선 사용자가 의도한 정상 기능(`Detach` 캐싱)으로 도달한다.

---

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **Q1** | `H-124` `recompute` 루프 순서 | (a) 되감기 판정을 `lengthList[i]` 읽기 앞으로(`continue`) / (b) `i > bk.N` 가드만 | **(a)** — (b)는 되감기 없이 끝나 `H-113`이 닫은 증상을 되살린다 |
| **Q2** | `H-125` 두 필드 초기화 자리 | (a) `materializeSlotTree` 진입부에서 `0, 0` / (b) `unmountSlotTree` 꼬리에서 / (c) `_baseObserver` 바인드·`blocker:On()`을 `setOffsetSource` 앞으로 | **(a)** — 실체화 경계의 명시 불변식. `_baseObserver`의 `0`은 런타임 베이스 변경용으로 유지 |
| **Q3** | `H-126` `spliceArraysUp` 비운 자리 | (a) 요구 목록에 "`observers[index]`/`tokens[index]`를 `nil`로" 명시 / (b) "네 배열 전부 `table.insert`/`remove` 의미론"으로 통일 | **(a)** — 자리표시자 두 줄과 같은 자리에 두 줄 더. 새 결정 아님 |
| **Q4** | `H-127` `EffectHandle:Unsubscribe` | (a) 의사코드 신설: Observer 게이트 위임 **먼저**, 통과 시에만 `_consumeCleanup()`; `Subscribe`/`Weak*`는 Observer 것 재사용 명시 / (b) 산문의 번호 순서만 바꿈 | **(a)** — 네 진입점을 새로 의사코드화한 마당에 Effect만 산문이면 같은 사고가 난다 |
| **Q5** | `H-128` M2×M8 `Ref` | (a) M2 공통 기반에 `Ref` 최소형 체크박스(`.Value`/`.Revision`/`:Set`/`:WeakCallback`/`:Callback`/`:Uncallback`/`isRef`) / (b) M2에선 `Ref` dep을 명시적으로 미루고 M8에 그 테스트 체크박스 | **(a)** — `Effect`의 `isEpoch` 분기를 M2 안에서 한 번은 돌려야 한다 |
| **Q6** | `H-133` `WeakUnsubscribe` 비대칭 | (a) 의도된 관대함으로 명문화 / (b) `WeakSubscribed[self] == nil`도 error | 권고 없음 — 계약 취향. 지금 산문은 (b)처럼 읽히고 코드는 (a)다 |
| **Q7** | `H-130` 폐기 블록 편집 | (a) 그 한 줄을 커밋 전 문구로 되돌리고 "배너 아래는 안 만진다"를 규칙으로 / (b) 블록을 `archive/`로 이동 | **(b)** — 이 블록은 이미 두 번(8라운드 2차 #1·이번) 사고를 냈다 |
| **Q8** | `H-134` `InstanceChildHandler` 부기 | (a) 말단 표에 행 신설 + `setOffsetSource(inst,k,None)`→`setLength(inst,k,1,inst)` + retractor 해제 순서, ROADMAP M5 체크박스에 명시 / (b) `drive`가 `k=number` 일괄 등록(이미 기각된 안) | **(a)** — `H-39`의 "예외 없이" 규칙에 이 핸들러를 넣는 것뿐, 갈래 없음 |
| **Q9** | `H-135` 숏핸드 retractor | (a) `function() end`로 통일, Tween 절 스케치 수정 / (b) `hint == nil` 파괴 유지 + (A)-nil 이중 파괴·(B) 스냅 문서화 | **(a)** — `Relate`가 `inst` weak라 자식 회수는 부모 사망이 맡는다(`UI-11`과 같은 결) |
| **Q10** | `H-136` `:List` 재실행 reconcile | (a) `reconcile` 본문을 배치 Blocker로 감싼다(최초 population과 같은 모양, 끝에 게이트 확인 후 `recompute` 1회) / (b) "한 사이클 한 번만" 서술을 "raw op마다"로 고치고 O(n²) 문서화 | **(a)** — 이미 `raw*` 명시 호출이 `getBlocker(self):IsOn()`을 보므로 추가 배선 없음 |

🟢 `H-129`/`H-131`/`H-132`/`H-137`/`H-138`/`H-139`/`H-140`은 판단 불필요(정정·명시만).

**⚠️ [2026-08-27] Q1~Q3은 이미 확정·반영됐다** — 결정과 근거의 소스는
`-round9-followup.md`이고, 그 처리 중 `H-125`의 피해 범위 정정과 새 발견
`H-140`/`H-141`이 나왔다(위에 반영). Q1은 (a)의 `continue` 형태, Q2는 문항의
(a)/(b)/(c)를 넘어 **`Offset`/`_baseObserver`를 Slot 생성자로 올리고 파괴는
`_destroyed` 플래그가 말하는** 형태로, Q3는 (a)/(b)를 넘어 **`element → index`
맵을 `bk.indexOfElement` 하나로 통일하고 `token`을 폐기**하는 형태로 닫혔다 —
그 결과 **`H-137`은 소멸**했다(토큰이 없어졌으므로).

---

## §5 이상 없다고 확인한 것 (다음 라운드가 다시 파지 않도록)

**A각도 — 겹쳐 읽어 정합했던 조합**:

- **두 필드 분리 × 무효화 4규칙 × `bk.N` 예외 × 2-연산 경로**(4차 HIGH의 그
  모양) — 실측 `d11_two_ops.luau`: 커서 `i=3`의 `offset:Set` 안에서
  `Remove(1)` 뒤 `Add(s5)`. `Remove`가 두 필드를 `0`으로, `Add`의
  `setOffsetSource`→`getOffsetAt`이 **`offsetCacheValidUpTo`만** `4`로 올리고
  `offsetSetUpTo = 0`은 살아남아 되감기가 `1`부터 다시 돌았다. 최종
  `s2 0 / s3 2 / s4 3 / s5 4 / O.Length 5` — 전부 기대값. **분리가 그 버그를
  실제로 닫는다.**
- **`H-113` 커서 자리 splice(`j == i < N`)** — `d13_splice_at_cursor.luau`:
  `i=2`에서 `Remove(2)` → `offsetSetUpTo = 1 < 2` → 되감기 → 밀려 들어온 `s3`이
  `Set`을 받는다. `s3 2 / s4 3 / O.Length 4` 정합. (같은 경로의 `i == N`
  변형만 `H-124`.)
- **되감기 클램프 `math.max(…, 1)`** — `d11`에서 `offsetSetUpTo = 0`으로 떨어진
  뒤 `i = 1, sum = prefix[1] = 0`으로 정확히 재개.
- **`H-119` 재진입 게이트 7자리** — `rawRemove`/`rawUnmount`/`rawDetach`/
  `_baseObserver`/`:List` 활성화 꼬리/`materializeSlotTree` 꼬리/`Dispatch.drive`
  꼬리 전부 `blocker:IsOn() or bk.recomputeBlocker:IsOn()`(꼬리 셋은
  `recomputeBlocker`만 — 배치 Blocker는 방금 껐으므로 정합). `d10`/`d11`/`d13`에서
  `rawRemove`의 건너뛰기가 실제로 걸리고 되감기 신호(`index-1`)가 살아 넘어오는
  것 확인.
- **`getBookkeeping` 초기화 열거** — `offsetCache`/두 필드 `0`/`recomputeBlocker`
  전부 있고 `bk.N`만 `nil` — 전사물이 그대로 돌았다. `if bk then` 흔적 가드
  제거도 `unmountSlotTree`/`destroySlotTree`/`:List` 꼬리/`materialize` 꼬리
  전부 반영돼 있다.
- **`Ref` 2-인자 × `Effect`의 `onRefFire`/`onStateFire` × 훅 `guard`** —
  `t11_effect_deps.luau`: `Ref` dep이 `fire(ref)`로 `Update(ref)`를 통과해
  `Rerun`(미바인드 땐 `canExecute`에 막힘, 바인드 캐치업 `Refresh()`로 1회, 같은
  값 `Set`도 새 리비전이라 1회), 다이아몬드 `A→b, A→c, Effect(fn,b,c)`에서
  `A:Set` 한 번에 `fn` 한 번, 혼합 deps(`Ref`+`State`) 독립 발화, 무인자
  `state:Observer()`가 3-인자 루프에서 생존, `destroy` 뒤 cleanup 1회·이후 `Set`
  무시. 전부 기대값.
- **`Ref:Set` 순서(값→리비전→콜백)·두 테이블 스냅샷·교차 dedup·thread 소진** —
  `t13_ref_dedup.luau`: 같은 `fn`을 `:WeakCallback`+`:Callback`으로 걸어도 `Set`
  1회에 1번, `:Uncallback` 뒤 0번, thread 대기자가 새 리비전을 보고 소진.
- **fail-fast 3종 매트릭스** — `t12_subscribe_failfast.luau`: `Weak→Unsubscribe`
  error / `Subscribe→WeakUnsubscribe` error / `Subscribe` 두 번 error / 미구독
  `Unsubscribe` error / `Subscribe→Unsubscribe→Subscribe` 재구독 통과 /
  `Effect:Subscribe`·`:Unsubscribe`가 내부 Observer를 안 건드리고 dep 발화가
  `.Subscribed`로만 켜지고 꺼짐 / 내부 Observer에 범용 `Unsubscribe` → error
  (5차 #5가 막으려던 침묵 살해가 실제로 막힌다). 걸린 건 `H-133`의 비대칭뿐.
- **`WeakSubscribe`가 `.Subscribed`를 세움 × `canExecute`** — 위 `t11`의 State
  dep 경로가 이걸로 살아 있다(`H-111`의 "전량 침묵"이 실제로 안 난다).
- **사냥 #6 — *idempotent* 네 번째 사본**: `grep -rni idempotent|멱등` 결과
  `Subscribe`/`Unsubscribe` 관련은 정정 배너 셋(`lifecycle-pattern.md` 513·516·520,
  `source-state-plan.md` 1409~1422, `effect-plan.md` 630)뿐. 나머지 idempotent는
  `Blocker`/`Gate`/`RunInit`/`_bindDestroying` 등 다른 대상. **없다.**
- **사냥 #2 — 인용문·절 제목·정정 배너의 옛 이름**: `invalidAfter`가 남은 자리
  전부(`dispatch-core-plan.md` 1714·1763·1771·1777·1948·1953, `slot-plan.md`
  2925·2933·2943, followup `H-113` 절)가 인용문/절 제목/폐기 서술이고, 살아 있는
  코드·표·목록엔 0건. `_observers`도 폐기 배너 안(`effect-plan.md` 476·482·
  490~514, 406)에서만 — 단 그 블록 편집은 `H-130`.
- **사냥 #7 — ROADMAP 체크박스 vs `base/`**: M2 `state:Observer(fn)`(3-자리,
  `_state`, `H-61` 이름), `Effect` "같이 만들 것"(클로저 둘, `_deps`/`_epochs`/
  `_blocker`/`_installed`/`Rerun`), `store:Of`/`CheckReservedKeys<keyof<T>>`/
  `__reservedCheck` 셋, `isModifier` 자리·`defaults` 검증, 훅 `guard` 2-인자,
  전파 루프 사본 주석, M3 (a)/(b)/(c)의 두 필드·`i-1`·`minPos-1`·`H-119` — 전부
  `base/`와 일치. 걸린 건 `H-129`(옛 문장 잔존)와 `H-128`(순서)뿐.
- **`H-118` 재정정 뒤 `gate-plan.md` 5번 × `debounce-throttle-plan.md` 배너** —
  두 경로 표가 양쪽에 같은 내용으로 있고 `pass()`/`emit()` 역할이 서로 맞는다.
  (게이트 본체는 8라운드 §5대로 다시 안 팠다.)
- **`isModifier` 가드 이동 × `defaults` `isSource` 검증 × `store:Of`** — 세 문서
  + ROADMAP이 "`defaults` 경로에선 안 만든다, `Of`는 만든다, `Source` 생성자
  가드가 둘 다 덮는다"로 일치. `component-composition-plan.md`의 `or None`
  관용구는 children 배열용이지 `defaults` 값이 아니라 화이트리스트와 무관.
- **`state-epoch-plan.md` §4 카운터 쌍** — 전사물 `core9.luau`의 `State:Get`이
  그 규칙(`cacheCurrCount ~= cacheTargetCount or Refresh()`)으로 `t11`의
  다이아몬드를 통과시켰다.

**G각도 — 재확인된 Luau 사실**:

- **⭐ `keyof<{}>` + `CheckReservedKeys` — 빈 Store가 깨끗하다**
  (`g1b_keyof_empty_clean.luau`, `luau-analyze` exit 0, 진단 0건). `keyof<{}>`는
  `never`로 타입 함수에 정상 도달하고(`keys:is("never")`로 식별 가능 —
  `g1_keyof_empty.luau`에서 `print`로 확인), 유니온이 아니라 단일 타입으로
  들어오므로 `is("union")` 분기 없이 `{keys}`로 감싸면 `is("singleton")` 검사가
  그냥 거짓 → `types.singleton(true)`. `store-plan.md`의 *"빈 Store는 아직 실측
  안 됐다"* 캐비엇과 `STATUS.md` `16`/`21` 지침의 대조군 항목은 **이 실측으로
  닫을 수 있다**(음성 대조군 `{ Of = … }`도 같은 파일에서 `"Of" is a reserved
  key`로 정확히 걸림). 단, `Source<T>`가 `*error-type*`을 품는 최종형 `T`와의
  결합은 8라운드 실측에 의존했다(§6).
- **Luau 함수 타입은 파라미터에 반변** — `g2_arity.luau`: `(inst: string,
  ref: Ref) -> ()` 자리에 1-인자 람다(무주석/주석 둘 다) 통과, `(number,
  string) -> ()`에 `function(x: number)` 통과, 반대(더 받는 함수)는 정확히
  에러. `lifecycle-hooks-plan.md`의 주장 그대로.
- **일반화 반복 `for d in t do`는 유효** — `H-131`(문서 쪽이 틀림).
- `bit32.bnot(-rev)` 랩은 8라운드 실측에 의존(전사물이 같은 식을 쓰고
  `t11`/`t13`의 리비전 판정이 그 위에서 돌았다).

**B각도 — 레인 B가 값으로 돌려 정합했던 것**:

- **그룹 `Attribute` 체인** — `store = Store<<{hp: Source<number>}>>({hp =
  Source(100)})`, `Frame { Attribute(store) }` 마운트 → `store.hp:Set(50)` →
  철거: `AttributeGroupFallbackHandler`(`setOffsetSource(inst,1,None)`/
  `setLength(inst,1,0,inst)` 게이트에 막힘 → `groupClaimKeys[(inst,attr)] = 1` →
  `attr:NameMap()` = `{hp = Source#1}` → `K1 = groupKey(attr,"hp")` →
  `Dispatch.process(inst, K1, Source#1, 1)` → `StoreBind` → 즉시 1회 →
  `AttributeKeyFallbackHandler` → `nameClaims[(inst,"hp")] = K1` →
  `setAttribute(inst,"hp",100)`). `Set(50)`은 (A) 분기로 `K1` 체인만 돌고 그룹
  로직은 안 돈다(*"필드 하나만 바뀌는 흔한 경우"* 서술과 일치).
  `retractFrom(inst,1,1)` → claim 반납·`unbindLifetime` 대칭. `State<Attribute>`가
  새 그룹 객체를 내면 체인 전량 철거 후 `K1'`로 재위임, `nameClaims` 충돌 없음.
  `Frame { a, a }`는 `claimed(1) ~= 2` error(`NOOP`·길이 0 등록은 `H-103` 서술대로
  남고 무해). plain 필드·`None` 값 경로도 정합.
- **`D` 생성자** — `D.Frame { Name = "x", MouseButton1Click = fn, D.Frame {} }`:
  `New<<Frame>> "Frame"` → `Instance.new` → (0) gcconn/gchold → `flatten`(Modifier
  없음) → `Dispatch.drive`(pre-pass 없음 → Blocker On → 단일 `for`: `k=1`
  `InstanceChildHandler`(`H-134` 제외 정합) / `"Name"` `PropertyHandler` /
  `"MouseButton1Click"` `EventHandler` → `OffWithoutEmit` → `recompute(inst)`)
  → 반환. 단일 `for`의 "배열 먼저"가 Luau `next`의 배열 파트 선순회에 의존하는
  것은 `F-4-1`이 스파이크 `01` 재작성으로 확인하기로 해둔 자리라 새 항목으로 안
  올렸다.
- **숏핸드 → `PropertyHandler`** — `(inst,"UICorner")`와 `(child,"CornerRadius")`가
  **별개 체인**(둘 다 index 1부터), `v:Mapped(toUDim)`이 `Tween` 껍질을 유지한 채
  `Value`만 감싸고, PH의 3-상태 슬롯(`nil` → `true` → `{Tween,Value}`)이
  `(child,"CornerRadius")`에 붙어 트윈이 공짜로 따라온다. `UIPadding`은 4개
  `(child, prop)` 체인. 재디스패치는 (A) 분기라 `child` 재사용(`H-135`는 철거
  쪽 모양만).
- **`:List` reconcile** — `{a,b}` → `{b,a,c}` → `{b}`를 `_elements`/`_elemIndex`/
  `bk.lengthList`/`sourceList`/`N`/두 필드/`mounted`/`prevKeys`/`slotPos`/
  `physIndex` 값으로 전부 적어 돌렸다. `physIndex = getOffsetAt(self,
  candidateSlot) - offset:Get() + 1`은 정착된 `1..slotPos`만 합산(아직 처리 안 된
  옛 요소는 전부 `≥ slotPos+1`) ✓; 최초 population에서 두 필드가 splice로 0까지
  내려가도 `getOffsetAt`이 재부트스트랩 ✓; `rawMove(idx, slotPos)`는 항상
  `idx ≥ slotPos` ✓; 소멸 루프의 `indexOfRaw`가 `reindexFrom` 갱신분을 읽어
  순서 무관 정확 ✓; 중첩 Slot 요소(`spliceArraysUp` placeholder → `attachSlot` →
  S 실체화 → `setLength(self,1,S.Length)` 게이트 → 다음 아이템 `physIndex`가
  `lengthList[1]:Get()`을 라이브로 읽어 2) ✓; `mountSlotTree`의 `acc` 전진 ✓;
  `Detach`(메인 루프 → `rawDetach` → `_detached[key]`, `prevKeys` 유지 → 다음
  사이클 `prev` → 재반환은 nop / `prev` 반환은 `rawAdd(…, true)` 재마운트 /
  소멸 루프 `Detach`는 홀드, `nil`은 `releaseElement(self, nil, prev, true)`) ✓;
  `Owned = false` 래퍼(`sub:Single(v, nil, {Owned=false})`, `data =
  state:Compute(function(v) … v:Get() …)`가 `fn(self, …)` 계약 그대로, 고정 키,
  `identityUpdateFn`의 `KeyGone` 흡수, 값 교체 `rawReplace(idx, new, false)` →
  `nativeExtract`, `nil` 전이 `rawUnmount`) ✓; `settle`의 교체+리오더 겹침 순서와
  `_elemIndex` 갱신 ✓. 걸린 건 `H-136`(Blocker 부재)과 `H-125`의 도달 경로뿐.

**C각도 — 전사물 자체**: `core9.luau`/`dispatch9.luau`(스크래치패드)는 `base/`의
현재 계약을 줄 단위로 옮긴 것이고, 대조군 `d14_baseline.luau`(형제 offset 전파
`O.Length 4 / S.Offset 1 / t2 2`, `t1` 성장 뒤 `t2 4 / O.Length 6`)가 통과한다.
7라운드 전사물의 의도적 차이 셋 중 `PeekDiffers`는 `Peek`으로 표면에 들어왔고,
`box.pos`는 토큰 역참조로 대체됐고, 생명주기 4종은 mock(`{conn = {Connected}}`)
으로 채웠다(`H-97`).

---

## §6 남은 의심 / 못 본 것

**남은 의심**(확신까지 못 간 것):

- **`H-125`의 `State<Slot>` 교체 경로** — 전사물은 `rawUnmount` 상당만 돌렸다.
  `SlotHandler.process`의 교체 분기가 `unmountSlotTree`를 거쳐 같은 창을 만드는지
  원문에서 확인은 했지만(같은 함수) 값으로 돌리진 않았다.
- **`H-124` (a) 처방의 `rawClear` 결합** — `rawClear`가 splice 취급이라
  `index = 1` → 두 필드 `0`이면 되감기 → `i = 1`, `bk.N = 0` → 루프 종료로
  깨끗할 것으로 보이나 `rawClear` 의사코드가 없어 손으로만 확인.
- **`getOffsetAt`의 `nil` 가드(`H-106`)가 `H-124` 뒤에 먼저 터질 수 있는가** —
  되감기 뒤 `getOffsetAt(i-1)`은 캐시 범위라 안 밟는다고 보지만 `rawSplice`
  다중 제거 + 캐시 `index-1`의 조합은 값으로 안 돌렸다.
- **`AttributeGroupHandler`의 (A) 재처리 비용**(H각도) — `State<Attribute>`가
  emit할 때마다 `setLength(inst,k,0,inst)` → `gatedRecompute` → steady state에선
  `recompute(inst)` 전체 순회가 한 번 돈다(길이 0→0 불변). 정합성 문제는 아니고
  `Tag`도 같다 — 비용 서술로만 남긴다.
- **`groupKey` 메모와 `chains[inst][K]`의 빈 배열** — 그룹 값이 살아 있는 동안
  이름별 키 객체가 강하게 남고, 철거 뒤 `chains`에 빈 리스트가 남는다.
  `inst`/그룹 값이 죽으면 같이 사라지므로 누수는 아니지만 `quad-debug`가
  `chains`를 덤프할 때 빈 항목이 보인다.
- **`rawMove`/`rawSwap`의 물리 op 인자** — `nativeMove(target, fromOffset,
  elements, toOffset)`의 `toOffset`이 "제거 전 좌표"인지 "제거 후 좌표"인지가
  `slot-plan.md`에 없다(DOM `insertBefore` 의미론 대비). Roblox 백엔드는 offset을
  무시하므로 지금은 관측되지 않는다 — 웹 백엔드가 생길 때 정해야 한다.
- **재실행 reconcile 중 `updateFn`이 던질 때** — `H-136` (a)를 채택하면 Blocker가
  켜진 채 남는 창이 새로 생긴다(`materializeSlotTree`와 같은 부류). 그 자리가
  이미 "실제로 물리면 그때 넣는다"로 확정돼 있어 발견으로 안 올렸다.
- **`WeakUnsubscribe`를 leaf 바인딩된 Observer에 부르는 경우**(`H-133`) —
  `.Subscribed = false` 대입만 하고 gcconn 경로는 그대로라 무해하다고 판단했지만,
  그 값이 나중에 `:Subscribe()`될 때 `canBound`가 gcconn을 먼저 보므로 여전히
  막힌다 — 정합. 다만 "무해"를 발견으로 안 올린 이유는 이것뿐이다.

**못 본 것**(범위 밖 — "감사 통과"로 읽지 말 것):

- **`Gate`/`Blocker`/`Debounce`·`Throttle` 본체** — 8라운드 §5가 닫았고 이
  델타는 `gate-plan.md` 5번 산문만 바꿨다. 재트레이싱 안 함.
- **`rawMove`/`rawSwap`/`rawExtract`/`rawSplice`/`rawClear`** — 의사코드가 없어
  (`H-29` 규약만) 4번째 무효화 행과 `bk.N` 예외를 **읽기로만** 확인했다. 값
  단위는 `rawRemove`/`rawAdd`뿐.
- **`Dispatch.process`/`retractFrom` 체인, `StoreBind`** — 델타가 안 건드렸다.
- **`CheckReservedKeys` × 최종형 `T`(`Source<T>`가 `*error-type*`을 품는 §1②
  선언)** — 8라운드 `r8-spike` 실측에 의존. 이번 `g1b`는 `Source` 타입을 단순형
  으로 뒀다.
- **`Effect`의 `_bindDestroying` 재바인드(포탈)·`Rerun` 재진입 지연** — `t11`은
  바인드 1회 + destroy만 돌렸다.
- **Studio 실측 전부**(이 환경 제약).
- **레인 B가 못 본 것** — `rawSplice`/`rawClear`/`rawExtract`/`rawSwap` 본체
  (의사코드 자체가 없음 — `H-29` 규약만 대조), `Tag` 핸들러 참조 카운트,
  `OnChange`/`Event`의 `nil` 전이, `Attribute.Merged`/`Overridden` 합성 규칙,
  `D` 생성기의 타입 출력. 전부 문서 정독 수준이고 값을 돌리지 않았다.

---

*스파이크 원본: 세션 스크래치패드 `ref9/`(`core9.luau`·`dispatch9.luau`·
`d10`~`d15`·`t11`~`t13`·`g1`~`g3`). 발견 근거는 위 항목에 코드·출력을 전사해
두어 파일 유실과 무관하게 재현 가능하다. 저장소는 이 파일 말고 아무것도
수정하지 않았다.*
