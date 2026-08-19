# 구현 전 QA **4라운드 followup** — 회신 처리 결과 + 재질문

**상태**: **[2026-08-20] 1차 처리 완료, 아래 B/C절 회신 대기.**

**입력**: `pre-implementation-qa-round4-response.md`(사용자 회신 원문 — 그
파일이 소스이고 여기서 전문을 반복하지 않음). 이 문서는 그 회신을 (a) 바로
반영한 것, (b) 설명이 부족해 다시 풀어 쓴 것, (c) 사용자 판단이 더 필요한 것,
(d) 조사해서 답이 나온 것으로 갈라 정리한 것이다.

**같이 일어난 일 — 업스트림 스캐폴딩 병합.** 문항지를 쓰는 동안 업스트림에
M0 스파이크 검증 + M1 스캐폴딩이 12커밋 올라와 있었고, 이 세션에서 `pull` 후
문항지 커밋을 그 위로 rebase했다. **그래서 문항지 일부가 이미 stale하다** —
어느 문항이 그런지는 아래 E절.

---

## A. 반영 완료 — 바로 고친 것

전부 이번 세션에 `base/`(+`HUMAN_TODO.md`/`question.md`/`todos.md`)에
반영했고 `doc-check.py` ERROR 0을 유지했다. **회신에서 판단이 명확했던 것만**
손댔고, 조금이라도 애매하면 아래 B/C로 뺐다.

| 항목 | 무엇을 고쳤나 | 대상 |
|---|---|---|
| `LP-1` | `Connected`는 "계산된 속성"이 아니라 그냥 `RBXScriptConnection`의 네이티브 필드. 실제 판정은 "gcconn 없음" / "있는데 `Connected==false`" 두 상태뿐이고, quad가 참조를 `nil`로 끊는 자리는 없음. rbvm에서 가져오는 건 gcconn 관용구뿐이고 `__index` 계산 속성 구현은 **안 가져옴** | `lifecycle-pattern.md` |
| `LP-2` | "예상보다 적을 수 있다"가 아니라 **지금은 정확히 `Effect` 하나뿐** | `lifecycle-pattern.md` |
| `LP-4` | 커스텀 Destroy-time 처리의 정상 경로는 `[Event "Destroying"]` 직접 바인드가 아니라 **`Effect`(+슈가 `OnDestroyed`)** | `lifecycle-pattern.md` |
| `D-56` | **`bindLifetime`의 첫 인자가 물리 Instance가 아닐 수 있다**(Slot-in-Slot의 `ownerKey`)를 백엔드 요구사항으로 신설. gcconn 트릭이 안 통하는 이유와, `isBoundAlive`에 세 번째 분기가 필요하다는 것까지 명시 | `lifecycle-pattern.md` |
| `D-8`/`ML-9` | `Dispatch.listHandlers()`는 `Quad.debug`와 무관하게 **항상 호출 가능**(목록을 반환만 하고 스스로 출력 안 함). 게이팅 대상은 "라이브러리가 스스로 콘솔에 쓰는" 동작뿐 | `dispatch-core-plan.md`, `module-lifecycle-plan.md` |
| `D-60`/`SL-75` | `Slot.Offset`은 마운트 전에도 `nil`이 아니라 **`0`**, 언마운트해도 **`nil`로 되돌리지 않음**. `nil`로 갈아치우면 그 Source를 이미 구독 중인 다운스트림이 영구히 끊겨 **포탈이 깨짐** | `slot-plan.md`, `dispatch-core-plan.md` |
| `SL-74` | `SetAndDispose`는 **`source:SetAndDispose(value)` 콜론 메서드로 확정**(`:Set`과 한 세트). `Apply` 오버라이딩은 `Source`→`State` 단방향 때문에 타입이 안 성립해서 애초에 불가 → `state:Apply` 시그니처 영향 없음, 열린 항목에서 제거 | `slot-plan.md`, `question.md`, `todos.md` |
| `SL-4` | 예시를 `slot:Add(Frame { Ref = myRef })` → **`MyComponent { Ref = myRef }`** 로. `Frame`은 코퍼스에서 인스턴스 리터럴을 가리키는 이름이라 정반대 오해를 부름 | `slot-plan.md` |
| `SL-72` | 조기 해제의 사용자 경로는 `unbindLifetime`이 **아님**(그건 Handler 작성자용 내부 배관) — `State<Observer?>`에 `nil`을 emit하는 게 정상 경로 | `slot-plan.md` |
| `E-10` | dedup 대칭 **확인 완료** — `relate`로 이전 값을 들고 `old ~= v` / `nextValue ~= v` 두 분기 **안**에서만 bind/unbind(+내부 Observer cascade)가 일어나므로 성립. 남은 건 구현 시 회귀 확인뿐 | `effect-plan.md` |
| `E-11` | leaf 바인딩된 `EffectHandle`엔 `:Unsubscribe()`가 **아예 안 먹는 것**으로 Observer와 통일. 옛 "(3) 이후 leaf가 죽어도 중복 호출 안 됨"은 이중 바인딩 게이트상 **성립할 수 없는 문장**이라 삭제 | `effect-plan.md` |
| `M-5` | **`None`만이 명시적 unsetter** — `mod:X(nil)`은 "그 필드가 없는 새 Modifier", `mod:X(None)`은 "`None`으로 채워진 Modifier". 차이가 `Overridden`/`Peek`에서 관측된다는 것까지 예시로 | `modifier-plan.md` |
| `M-9` | "Getter는 안 만든다"와 `:Peek`의 관계 명시(전자는 **필드별 setter 짝 getter**, `:Peek`은 키를 받는 범용 접근자라 모순 아님) | `modifier-plan.md` |
| `BK-9` | `HasBlocked`는 "영원히 안 만듦"이 아니라 **백로그** — 신설된다면 이름은 `HasBlockedState` 쪽 | `blocker-plan.md` |
| `R-11` | 등록은 선형 탐색 함수가 아니라 그냥 **`table.insert`**(구멍을 알아서 되찾아 씀). 단 "`#t`가 항상 첫 `nil` 자리"는 Lua 명세상 보장이 아니므로 **실측 스파이크 항목 추가** | `ref-plan.md` |
| `AT-11` | 위치별 claim 레지스트리 이름 **`groupClaimKeys`로 확정**(키 설계는 여전히 미정) | `attribute-plan.md`, `question.md` |
| `AT-20` | 생존 이름 최적화는 "부품이 늘어나서 안 하는" 게 아니라 **원리적으로 불가능** — 이름이 같아도 값이 바뀌었을 수 있고, 값을 비교하려면 `:Get()`이 필요한데 그건 State 계약 위반 | `attribute-plan.md` |
| Attribute 생성자 | `Attribute(a, b, ...)` **자신의 이름 겹침 정책이 어디에도 없었음** — `Merged`(error)/`Overridden`(뒤가 이김)만 적혀 있었다. 생성자는 **뒤가 이김**으로 명시 | `attribute-plan.md` |
| `TW-16` | `initValue`가 "에이전트 범위 밖"인데 `HUMAN_TODO.md`에 항목이 없던 것 — **10번으로 신설** | `HUMAN_TODO.md` |
| `UI-5` | **해소** — `process` 위임을 하는 이상 gcconn/gchold 없으면 옵저버 바인딩부터 실패하므로 "조용히 미아"가 아니라 **즉시 드러나는 전제 조건**. `ensureManagedChild`가 일반 인스턴스 생성과 같은 경로를 타야 한다는 계약으로 승격 | `ui-shorthand-plan.md` |
| `UI-8` | `mapTweenValue` 로컬 헬퍼를 **`Tween<T>:Map(fn)` 공개 메소드로 승격** | `tween-plan.md`, `ui-shorthand-plan.md` |
| `UI-11` | 자식 파괴 시 `retractFrom(child, prop, 1)`은 **"정석"이 아님** — 엔진이 Tween을 알아서 정리하고 PropertyHandler의 retractor는 애초에 no-op이라 두 겹으로 무의미 | `ui-shorthand-plan.md` |
| `LH` 백로그 | 진짜 `componentDidMount`(조상 체인까지 이어진 뒤)는 **백로그로 신설** — 자기 위를 알아야 해서 `drive` 한 콜스택 안에서 표현 불가, 사용 사례가 나오면 재검토 | `lifecycle-hooks-plan.md` |
| `D-3`/`D-10`/`LH-8` | 설명이 어렵다는 지적을 받아 **코드/다이어그램으로 풀어 씀**(아래 B절에 같은 설명 재수록) | 각 문서 |

**부수로 확인한 것 — `TW-12`는 이미 맞게 적혀 있었음.** 문항이
`CanAnimate`를 "단순 boolean"으로 축약한 게 문제였고, `tween-plan.md`는
처음부터 `CanAnimate: State<boolean> | boolean | nil`로 적어두고 `resolve`로
`:Get()`한다 — **문서 정정 불필요, 문항만 부정확**했다.

---

## B. 재질문 — 설명이 부족했던 것 (풀어 쓴 답 + 재확인)

전부 base 문서에도 같은 설명을 반영해뒀다. **아래 설명이 맞는지만
확인해주면 되고**, 어긋나면 그 지점을 알려주면 문서까지 같이 고친다.

### B-1. `D-3` — "깊은 인덱스"가 뭔지, 그리고 철거 방향

**질문**: *"방향이 그게 맞나? … 실제 process 에선 retract 가 인덱스 1 부터
5, 6, ... 순으로 작동함. 그런데 달라질 때 5, 4, 3, 2 ... 순이 되는건 아니지?
'깊은 인덱스' 라는게 무슨 의미?"*

**답**: **"깊다" = 인덱스 숫자가 크다**는 뜻이다(트리 깊이가 아니라 **같은
`(inst,k)` 체인 안에서의 재귀 깊이**). 그리고 **"5,4,3,2 순이 되는 게
맞다."**

```
(inst, k) 체인 — State<State<Tag>> 예시
  index 1 : StoreBind   ← 바깥 State 구독.   "얕음"
  index 2 : StoreBind   ← 안쪽 State 구독(1이 재귀로 만든 것)
  index 3 : TagHandler  ← 최종 Tag를 실제 반영. "깊음"
```

- **설치(`Dispatch.process`)는 1 → 2 → 3** — 사용자가 짚은 그대로. 각
  레벨이 값을 한 겹 벗겨 `index + 1`로 재귀하므로 **인덱스가 커지는 방향**.
- **철거(`Dispatch.retractFrom`)는 그 반대인 3 → 2 → 1** — 의사코드가
  `for i = #list, index, -1`로 **꼬리부터 역순**으로 돈다.
- **왜 반대여야 하나**: index 2가 index 3을 *만들어낸* 주체다. 만든 쪽을
  먼저 지우면 만들어진 쪽을 정리할 주체가 사라진다 — 스택을 쌓은 역순으로
  푸는 것(LIFO)과 같은 이유. 그래서 각 retractor는 자기가 만든 하위 인덱스를
  쫓아갈 필요가 없다(자기 차례엔 아래가 이미 비어 있음).
- **주의**: 이건 **한 `(inst,k)` 체인 안**의 이야기다. 서로 다른 키는 완전히
  별개 배열이고 서로의 순서와 무관하다.

→ **이 이해가 맞나?**

### B-2. `D-10` — Luau 일반화 `for`는 이미 지원하는데 뭘 검증한 건가

**질문**: *"루아우의 일반화된 반복 for 이 이를 그냥 지원함. 어떻게 실제로
이해했는지 확인 필요"*

**답**: **맞다 — Luau가 배열 파트를 먼저 훑는다는 걸 의심한 적은 없다.**
문항이 "M0에서 순회 동작을 검증한다"고 적어 마치 언어 동작을 의심하는
것처럼 읽힌 게 문제였다. 실제 구분은 이렇다:

- **언어가 주는 것**: 일반화 `for`가 배열 → 해시 순으로 돈다. 2026-08-07에
  사용자가 REPL로 직접 확인한 관찰.
- **그런데도 드라이버가 두 패스를 명시하는 이유는 순서를 못 믿어서가 아니라**
  (1) **이식성** — 다른 백엔드가 props를 Lua 테이블이 아닌 자료구조로
  표현하면 그 근거 자체가 없어짐, (2) 어차피 숫자 키/문자열 키를 다른
  의미로 처리해야 해서 **구분 비용이 이미 들고**, 순서 고정이 거의 공짜.
- **스파이크 `01`이 검증한 것**: 언어 동작이 아니라 **"우리가 짠 두 패스
  드라이버가 계약대로 도는가"**. 그 스파이크 주석도 "사용자가 이미 REPL로
  확인했었지만(우연한 관찰), base는 이 우연한 동작에 기대지 않고 … 명시적으로
  강제하기로 확정함"이라고 같은 구분을 적어두고 있다.
- **[업스트림 반영] 이미 통과했다** — `luau-test/done/01-two-pass-array-hash-order.luau`.
  문항의 "M0에서 검증할 항목이다"는 **stale**이라 base 문서에서 닫았다.
- **`nil`-hole로 배열 파트가 통째로 해시 취급이 되는 문제**는 이것과 별개이고
  `02`/`06` 스파이크가 담당한다.

→ **이 구분이 맞나?**

### B-3. `D-32` — "재위임 핸들러는 (A) 분기에서도 반드시 다시 재위임"이 무슨 말인가

**질문**: *"무슨말인지 확인 필요"*

**답**: **"조건부로만 재위임하는 핸들러를 새로 만들면 고아 체인이 생긴다"**는
경고다. 지금 존재하는 핸들러엔 위반 사례가 없어서 추상적으로만 적혀 있었다.

가상의 위반 예시로 설명하면:

```lua
-- ⚠️ 이런 핸들러를 새로 만들면 위험하다는 뜻
function MaybeWrapHandler.process(inst, k, v, index)
    if v.enabled then
        Dispatch.process(inst, k, v.inner, index + 1)  -- 재위임함
    end
    -- enabled가 false면 아무것도 안 함 ← 여기가 문제
    return function() end
end
```

- 1차 사이클에 `v.enabled == true` → index 2에 하위 체인이 설치됨.
- 2차 사이클에 같은 핸들러로 `v.enabled == false`가 오면 **(A) 분기**를 탄다
  (핸들러가 같으므로 `retractFrom`이 안 불림 — (A)는 **아래를 안 건드리는 게
  핵심**).
- 그런데 이번엔 재위임을 안 했으므로 **index 2에 옛 하위 체인이 그대로
  남는다.** 아무도 그걸 지우지 않고, 옛 값에 대한 구독/부작용이 계속 산다.
- **해법**: 재위임을 건너뛰는 그 자리에서
  `Dispatch.retractFrom(inst, k, index + 1)`을 직접 불러 아래를 비운다.

`StoreBind`/`NoneHandler`는 **항상** 재위임하므로 이 함정에 안 걸린다 —
그래서 "지금 위반 사례는 없다"고 적혀 있는 것이다.

→ **이 설명이 의도한 내용이 맞나?** (맞다면 base 문서에도 이 예시를 넣겠다 —
지금은 규칙만 있고 예시가 없어서 읽고 이해가 안 되는 게 정상이다.)

### B-4. `BR-7` — duck-typing 기각 근거를 더

**질문**: *"더 설명좀 필요"*

**답**: `Brand` 대신 `type(x) == "table" and x.Compute ~= nil` 같은 모양으로
판별하지 않는 이유가 두 가지다.

1. **false positive** — `Modifier` 필드나 `:Peek`가 돌려주는 `T`는 **사용자가
   넣은 임의의 값**이다. 사용자가 우연히 `Compute`라는 필드를 가진 테이블을
   넣으면 quad가 그걸 `State`로 오인한다. 브랜드는 quad가 만든 값에만 찍히므로
   이 오인이 원천적으로 없다.
2. **인덱싱 자체가 터질 수 있음** — 일부 Roblox userdata는 **정의되지 않은 키를
   인덱싱하는 것만으로 에러를 던진다**(`x.Compute`를 읽는 순간 throw). 그래서
   duck-typing을 하려면 판별 코드를 전부 `pcall`로 감싸야 하고, 그건
   "판별은 부작용 없이 빠르게"라는 `isHandlable` 계약(`base/dispatch-core-plan.md`)과
   정면으로 부딪힌다. 최악의 경우엔 엔진 자체가 죽는 상황도 있다.

즉 (1)은 **정확성** 문제, (2)는 **안전성+비용** 문제라 서로 독립된 두 근거다.
weak-key 레지스트리 조회는 포인터 해싱 한 번이라 `pcall`도, 오인도 없다.

→ **이 두 근거로 충분한가? 빠진 게 있나?**

### B-5. `SL-5` — `_mounted` 트리거 시점을 더 풀어서

**질문**: *"더 풀어 서술해주길 바람. 판단 보류"*

**답**: 요지는 **"`_mounted`를 언제 `true`로 세우는가"**이고, 후보가 둘
있었다.

```lua
-- 후보 A (채택): Dispatch가 이 Slot을 실제로 처리하기 시작한 시점
function SlotHandler.process(inst, k, slotValue, index)
    ...
    attachSlot(slotValue, inst, inst, k)   -- 이 안에서 _mounted = true
end

-- 후보 B (기각): 물리 Parent 대입이 끝난 시점
element.Parent = physicalTarget
slot._mounted = true   -- ← 여기서 세우는 모양
```

- **왜 A인가**: quad의 다른 "마운트됐다" 판정이 **전부 dispatch-process
  시점 기준**이다 — `PreRef`가 소진되는 시점, `Ref` 콜백이 fire되는 시점,
  `claimOwnerAt`이 소유권을 잡는 시점이 전부 그렇다. 여기 하나만 "물리
  Parent 대입 이후"로 두면 **같은 사이클 안에서 어떤 판정은 이미 마운트됨,
  어떤 판정은 아직 아님**인 구간이 생긴다.
- **오탐 걱정이 없는 이유**: "컴포넌트가 Slot을 prop으로 받아 저장만 하고
  실제 트리에 안 놓는" 경로에서는 `Dispatch.process`가 애초에 안 불린다 —
  A 기준으로도 `_mounted`가 안 켜진다.
- **⚠️ 단, 이 서술은 그 뒤에 한 번 더 정밀해졌다**(`SL-55`) — 지금
  `attachSlot`은 `_mounted = true`를 **함수 맨 위가 아니라 `activateList`
  뒤**에 둔다. `activateList`가 도는 동안 `_mounted`가 `false`여야
  reconcile의 `rawAdd`가 "아직 마운트 전"(= `_elements`에만 넣고 끝) 경로를
  타기 때문. **즉 "`process`가 불린 순간"이 아니라 "`process`가 불려 들어간
  `attachSlot` 안에서, `activateList`가 끝난 직후"가 정확한 시점**이다.
  원칙(dispatch-process 시점 기준, 물리 Parent 기준 아님)은 그대로.

→ **이 정리가 맞나?** 특히 마지막 ⚠️(정확한 시점이 `activateList` 직후)까지
포함해서 확인 부탁.

### B-6. `SL-59` — 재귀적 `Clear()` 금지가 어떤 상황인가

**질문**: *"실 상황에 대한 설명 더 필요함. 이 글만 보아서는 어떤 상황인지
정확히 판단 어려워보임. 판단 보류."*

**답**: **중첩 Slot을 파괴할 때 "각 요소를 `Remove`로 하나씩 지우는" 순진한
구현을 하면 O(n²)가 된다**는 얘기다.

```
outer(position 3에 마운트됨)
  └ inner Slot (요소 500개)
```

`outer`가 파괴될 때 두 가지 방식:

- **순진한 방식(금지)** — `inner:Clear()`가 요소마다 `rawRemove`를 부른다.
  `rawRemove` 하나당 (a) `spliceArraysDown`으로 뒤 배열을 한 칸씩 당기고
  (b) `recompute(inner, bk)`로 전체 순회를 돈다. 500개면 **당기기 500번 ×
  평균 250칸 + recompute 500번 × 500칸**. 어차피 통째로 죽을 서브트리인데
  그 안에서 위치 계산을 500번 다시 하는 셈.
- **채택한 방식** — `destroySlotTree`는 **부기를 전혀 안 건드리고** 요소를
  훑으며 파괴만 한다(`spliceArraysDown`도, `recompute`도 안 부름). 어차피
  이 Slot 자체가 사라지므로 그 안의 위치 계산은 의미가 없다. **바깥에서
  딱 한 번** — `outer`가 차지하던 position 3에 대해
  `setOffsetSource(None)` → `setLength(0)`을 부르고, 그때 `recompute`가
  한 번 돈다.

즉 "재귀적 `Clear()` 금지"는 **API를 금지한다는 게 아니라, 파괴 경로가
CRUD를 재사용하면 안 된다**는 구현 지침이다.

→ **이 이해가 맞나?**

### B-7. `SL-63` — `recompute`가 owner의 Length를 직접 Set하는 게 이상하다

**질문**: *"(b) 가 뭔가 이상함. 오너의 length 를 직접 설정하지는 않을것임.
자신 length 를 변경하면, 자동으로 observer 에 등록된것으로 인해 length 가
업데이트 되는 방식일텐데 … 최종 리컴퓨팅 결과가 length 가 되는거 아니였음?"*

**답**: **사용자 이해가 맞고, 문항의 표현이 나빴다.** "owner"라는 말이 두 가지로
읽혀서 생긴 혼동이다.

```lua
local function recompute(ownerKey, bk)
    ...
    if isSlot(ownerKey) and ownerKey.Length:Get() ~= sum then
        ownerKey.Length:Set(sum)
    end
end
```

- 여기서 `ownerKey`는 **부모가 아니라, 지금 자식들의 합을 구하고 있는 그 Slot
  자신**이다. 즉 `recompute(innerSlot, bk)`가 `innerSlot.Length`를 세운다 —
  **"최종 리컴퓨팅 결과가 자기 Length가 된다"는 사용자 이해 그대로.**
- **부모는 이 값을 직접 안 받는다** — 부모는 `attachSlot`에서
  `Dispatch.setLength(부모ownerKey, position, innerSlot.Length)`로 그 **State
  객체 자체**를 등록해뒀고, 값이 바뀌면 **Observer로 통지받아** 자기
  `recompute`를 돈다.
- 그래서 실제 흐름은 `innerSlot.Length:Set(sum)` → 부모의 observer 발화 →
  `recompute(부모, ...)` → 부모의 뒤 형제 offset 갱신, 이고 **"부모 length를
  직접 설정"하는 코드는 어디에도 없다.**

문항(그리고 base 문서의 "(b) owner가 Slot이면 그 `.Length`")이 `ownerKey`를
그냥 "owner"로 줄여 써서 부모로 읽히게 만든 게 원인이다.

→ **이 정리가 맞나?** 맞다면 base 문서의 그 표현도 "그 recompute의 `ownerKey`
자신"으로 명확히 고치겠다(아직 안 고쳤음 — 확인 후 반영 예정).

### B-8. `SL-76` — `recompute`가 `nil`을 관대하게 넘기는 게 왜 필요한가

**질문**: *"애초에 해제에서 nil이 관측 될 일이 없다고 생각하는데, 그게
아니라면 다시 더 자세히 말을 해주길 바람."*

**답**: **지금 설계에서 도달 가능한 경로를 저도 못 찾았다.** 그 방어 조항은
2026-08-13(`bk.N` 정의가 확정되기 전, Blocker 게이팅이 생기기 전)에 들어간
것이고, 그 뒤 두 변경으로 전제가 바뀌었다:

- `bk.N`이 "그때그때 실제 개수"로 확정돼(2026-08-18), `lengthList`/`sourceList`가
  아직 안 채워진 위치를 `recompute`가 읽을 일 자체가 없어짐.
- 배치 등록 중엔 Blocker 게이팅으로 `recompute`가 아예 안 돎.
- 해제는 `setOffsetSource(None)` → `setLength(0)`이라 `None`이지 `nil`이 아님.
- `spliceArraysDown`은 배열을 **압축**하므로 중간에 구멍을 안 남김.

**→ 그래서 선택지 셋 중 하나를 골라야 한다(사용자 판단 필요, C절 `C-6`으로
옮김).** 지금은 문서를 안 고치고 그대로 뒀다.

### B-9. `SL-78` — nested Slot의 Length만큼 건너뛰는 얘기가 뭘 섞고 있나

**질문**: *"애초에 slot 내의 index 와, length 로 구해진 offset 은 다른
개념인데, 너무 섞어 말하는것 아닌지 … Length 업데이트는 상위 slot 이
observe 하기에 형제 slot 갱신에 무관한데, 그 이야기가 아닌것임?"*

**답**: **섞어 말한 게 맞다. 두 얘기를 분리하면 이렇다.**

1. **형제 Slot 사이의 offset** — 사용자 말대로 **자동이고 이 캐비엇과
   무관하다.** nested Slot의 `Length`가 바뀌면 부모가 observe해서 `recompute`가
   돌고 뒤 형제 offset이 갱신된다. 여기엔 문제가 없다.
2. **같은 `:List` 안에서 `updateFn`에 넘어가는 `index`** — 이쪽이 캐비엇의
   대상이다. `reconcile`은 `pos`를 훑으며 각 아이템의 `index`를 계산하는데,
   어떤 아이템이 nested Slot(Length=3)을 반환하면 다음 아이템의 `index`는
   1이 아니라 3만큼 건너뛴다. **그런데 `index`는 그 사이클의 raw 스냅샷이라**,
   `:List`가 다시 reconcile되지 않은 채 그 nested Slot의 Length가 3→5로
   바뀌면 **뒤 아이템들의 `index`는 3 기준으로 멈춰 있다.**

즉 캐비엇은 **offset이 아니라 `index`에 대한 것**이고, "형제 Slot 갱신"이
아니라 **"한 `:List` 안 아이템들끼리"**의 얘기다. 그리고 이건 이미 확정된
"`index`는 State가 아니라 raw number"의 당연한 연장이라 새 문제가 아니다 —
실시간 정확성이 필요하면 `updateFn`이 `result.Length`를 직접 구독해야 한다.

→ **이 분리가 맞나?** 맞다면 base 문서의 그 캐비엇 문단도 "offset이 아니라
`index` 얘기"임이 드러나게 고치겠다.

### B-10. `LH-8` — "자기 아래 vs 자기 위"를 그림으로

**질문**: *"사람이 너무 이해하기 어려운 표현임 … 풀어 보여줘야함."*

**답**: `Frame { Frame { TextLabel {}, OnRendered(fn) } }`에서 안쪽 `Frame`의
`fn`이 불릴 때:

```
바깥 Frame { ... }          ← ⑤ 이 호출은 아직 시작도 안 함
  └ 안쪽 Frame { ... }      ← ④ 이 drive가 지금 끝나는 중
      ├ TextLabel {}        ← ① 이미 완성돼 안쪽 Frame에 붙어 있음
      └ OnRendered(fn)      ← ③ fn이 여기서 불림
      (프로퍼티/이벤트)       ← ② 이미 전부 세팅됨
```

- **①② = "자기 아래"** — 자식(과 그 서브트리 전체) + 자기 프로퍼티/이벤트.
  `fn`이 불릴 때 **전부 끝나 있다.**
- **⑤ = "자기 위"** — 안쪽 `Frame`이 바깥 `Frame`의 자식이 되는 일. Lua
  표현식 평가 순서상 **안쪽 `Frame{...}` 호출이 끝나야** 바깥 `Frame`의 props
  테이블이 완성되므로, `fn`이 불릴 때 바깥 `Frame`은 **존재하지도 않는다.**
- **그래서 "화면에 올라간 뒤"가 아니다** — 화면에 올라가려면 루트까지 이어져야
  하는데 그건 ⑤ 이후 일이다.
- **원래 뭐가 헷갈렸나**: 경계를 "이 인스턴스의 프로퍼티만이냐(a) / 자식
  서브트리까지냐(b)"로 놓았는데, 배열 파트 루프가 각 자식을 **동기적으로
  끝내고** 넘어가므로 ①이 공짜로 따라온다 — (a)/(b)는 갈리는 지점이 아니었고
  실제로 갈리는 건 ①②(자기 아래)와 ⑤(자기 위)였다.

→ **이 그림이 맞나?** (base 문서에도 이 그림을 넣어뒀다.)

---

## C. 사용자 판단 필요 — 임의로 처리하지 않은 것

**전부 아직 문서를 안 고쳤다.** 판단이 갈리거나 파급이 커서 임의 결정이
위험한 것들이다.

### C-1. ⭐ `SL-40`/`SL-43`/`SL-45` — `KeyGone` 센티널 신설

**사용자 제안**: 키가 데이터에서 사라지면 `updateFn`을 `KeyGone`으로 한 번 더
불러 처분을 묻고(`T | KeyGone`), `userdata`를 지울지도 사용자가 정하게 위임.
이걸로 `SL-45`(Detach 홀드 중 키 소멸)가 닫힌다.

**방향은 좋아 보인다** — `SL-45`가 "파괴도 반환도 안 되고 참조만 끊긴다"는
어정쩡한 상태였던 근본 원인이 "키가 사라지는 순간엔 `updateFn`에게 물어볼
방법이 없다"였고, `KeyGone`이 정확히 그 구멍을 메운다. 다만 **정하지 않으면
구현이 못 나가는 세부가 넷** 있다:

1. **`updateFn`이 `KeyGone`을 받았을 때 반환값의 의미**는?
   제안: `nil` → 파괴(기본), `Detach` → 언마운트만(사용자가 `ud`로 홀드),
   `prev` 그대로 반환 → ? (키가 없는데 계속 마운트해두는 건 모순으로 보임 —
   **error가 맞나, 아니면 파괴로 취급하나?**)
2. **`userdata` 엔트리는 언제 지워지나?** "유저가 결정"이면 `updateFn`이
   `(result, nil)`을 반환할 때만 지운다는 뜻인데, 그러면 **사용자가 `ud`를
   계속 반환하는 한 `userdata[key]` 엔트리가 영원히 남는다**(키는 이미
   사라졌으므로 다시 물어볼 기회도 없음). 의도된 것인가, 아니면 "한 번
   물어본 뒤엔 무조건 지운다"인가?
3. **다음 사이클의 소멸 루프가 무엇을 순회하나?** 지금은 직전
   `keyIndex`를 순회하는데, `ud`만 남은 키는 `keyIndex`에 없다. `userdata`
   키까지 합집합으로 순회해야 하나(그러면 매 사이클 그 키를 계속 `KeyGone`으로
   다시 물어보게 됨), 아니면 한 번 물어본 키는 목록에서 빼나?
4. **`index`/`offset` 인자는 뭘 넘기나?** 사라진 키엔 위치가 없다.
   `nil`? 마지막으로 알던 값? (`updateFn` 시그니처가 `index: number`로
   확정돼 있어서 `nil`을 넘기면 타입이 바뀐다.)

**추가로 이름/배치**: `Detach`와 같은 급의 sentinel이므로 **패키지 최상위
export**가 일관적이다(`None`/`Detach` 선례). 이름은 `KeyGone`이 의미는
명확한데, 코퍼스가 "이 자리에서 무엇을 하라"는 지시형(`None`=세팅 안 함,
`Detach`=떼되 죽이지 마라)을 쓰는 것과 달리 **`KeyGone`은 상태 서술형**이라
결이 조금 다르다 — 그게 오히려 맞을 수도 있다(이건 지시가 아니라 통지이므로).
**그대로 갈지 확인 부탁.**

### C-2. ⭐⭐ `SL-43` vs `SL-51` — "밀려난 `prev`는 dispose"와 `state<Frame>` 의미론이 충돌한다

**이번 회신에서 나온 것 중 파급이 가장 크다.** 두 답변이 서로 반대 방향을
가리킨다:

- **`SL-43` 답변**: *"'updateFn이 새 값을 반환하면 밀려난 prev는 언마운트만'
  는 이상한듯. 새 값으로 밀려난 prev 는 dispose 되는게 맞음. updateFn 은 직접
  destroy 를 호출 못함 … 그래서 지울 방법이 존재하지 않고, 지워주는게 맞다고 봄."*
- **`SL-51` 답변**: *"state<Frame> -> slot {frame} 형태가 될 때 이전 state 에서
  변경으로 다른게 와도, slot 이 이전 frame 을 destroy 해버리면 안 됨."*

**둘 다 맞는데 서로 다른 경우다** — 갈리는 축은 **누가 그 요소를 만들었는가**:

| 경로 | 요소를 만든 주체 | 밀려난 `prev`의 올바른 처분 |
|---|---|---|
| `:List(data, updateFn)` — `updateFn`이 `Frame{...}`을 만들어 반환 | **`updateFn`** | **dispose** — 만든 쪽이 자기 손으로 못 지우니(reconcile 중이라 `dispose`가 거부됨) reconcile이 대신 지워야 함 |
| `Slot:Add(state)` 라 sugar(`:Single` + identity `updateFn`) | **사용자**(state에 담아 넘김) | **언마운트만** — `state<Frame>`가 이전 값을 안 죽인다는 확정 의미론 그대로 |

지금 설계는 **후자를 표현할 방법이 없다.** `Detach`는 "이 자리를 비우되 죽이지
마라"라서 *교체*와 같이 못 쓴다(새 값을 반환하는 순간 `result ~= nil` 경로로
가고, 그 경로가 dispose가 됨).

**선택지 셋**:

- **(a) `:List`/`:Single`에 소유권 옵션을 둔다** — 예:
  `Slot:Single(state, updateFn?, opts?)`의 `opts.Owned = false`. 설치 시점에
  한 번 정하고, `Slot:Add(state)` sugar가 `Owned = false`로 설치한다.
  *장점*: 갈리는 축(누가 만들었나)이 실제로 **설치 단위 속성**이라 의미가
  정확하고, 매 사이클 반환값에 부담을 안 준다. *단점*: 옵션 파라미터가
  하나 늘고, "한 `:List` 안에서 어떤 아이템은 내가 만들고 어떤 건 사용자
  것"인 혼합은 표현 못 함(그런 사례가 있는지는 모르겠음).
- **(b) `Detach`를 호출 가능하게 만들어 `Detach(newValue)`로** — "교체하되 옛
  것은 떼기만" 을 반환값 프로토콜 안에서 표현. *장점*: 국소적이고 per-cycle로
  정확. *단점*: **2026-08-19에 확정한 `Detach` 배치 결정과 부딪힌다** —
  그때 "sentinel 상수 하나 때문에 callable-table+메타테이블 구조를 들이는 건
  과함"이라고 판단해 최상위 순수 sentinel로 뒀다.
- **(c) 새 sentinel 하나 더** — 예: 반환값을 `(newValue, ud, DetachPrev)`처럼
  세 번째 슬롯으로 신호. *단점*: 반환 프로토콜이 복잡해짐.

**추천: (a)**. 갈리는 기준이 per-cycle이 아니라 per-installation이라는 게
분석의 핵심이고, (b)는 방금 내린 결정을 뒤집는 비용이 있다.

**같이 확인 부탁**: `SL-51`에서 *"list 슈거에서 Detach 가 사용중인지 확인이
필요해보임"* 이라 하셨는데 — **지금 `:Single`의 기본 identity `updateFn`은
`Detach`를 전혀 안 쓴다**(그냥 `item`을 반환). 그래서 위 충돌이 실재한다.

### C-3. `M-2` — flatten이 소진한 Modifier 자리에 구멍이 남는다 (⭐ 실제 갭)

**사용자 제안**: *"이것도 이 이후 ProcessedModifier / ProcessedModifierHandler
를 만들면 될듯. Post/Pre Ref 와 유사히 처리 가능하다고 생각함."*

**조사 결과 — 이건 문서의 실제 갭이 맞다.** `modifier-plan.md`는 flatten이
"`isModifier(v)`가 참인 항목만 필드를 뽑아 merge하고 나머지는 안 건드린다"고만
적어두고, **뽑아낸 그 자리를 어떻게 하는지를 한 번도 안 적었다.** 그냥 지우면
배열에 구멍이 생기고, 그건 `PreRef` pre-pass가 `ProcessedPreRef`로 소진하는
바로 그 이유(sparse 테이블이 되면 배열 파트 전체가 순서 보장을 잃음)에 정확히
걸린다.

**선택지 둘**:

- **(a) `ProcessedModifier` 센티널 + 전담 nop Handler** — `Pre`/`PostRef`와
  완전히 대칭. 그 Handler가 `setOffsetSource(None)`/`setLength(0)`을 등록하니
  Length/Offset 계약도 특수 취급 없이 만족된다. **일관성 최고.**
- **(b) flatten이 결과 배열을 압축(compact)** — flatten은 이미 `flatten(nonFlatten)
  -> flattened`라는 **새 테이블을 만드는 순수 변환**이라, Modifier 자리를 아예
  안 넣고 뒤를 당겨 담으면 구멍 자체가 안 생긴다. 센티널도 Handler도 불필요.
  *단, 이러면 배열 위치가 원본과 달라진다* — `flattened`만 보는 `drive`
  입장에선 무해해 보이지만, 확인이 필요하다.

**추천: (b)** — flatten이 어차피 새 테이블을 만드는 이상 가장 부품이 적다.
`Pre`/`PostRef`가 센티널을 써야 했던 이유는 **pre-pass가 `flattened`를
제자리에서 소진**하고 그 뒤 두 패스가 **같은 테이블**을 다시 돌기 때문인데,
flatten은 그 앞 단계라 그 제약이 없다. 다만 사용자가 (a)를 제안하신 만큼
**어느 쪽인지 정해주면 그대로 반영**하겠다.

### C-4. `destroySlotTree`가 자식 소유권을 명시적으로 반납해야 하는가

**사용자 의문**: *"Destroy 된 요소는 다른곳에 원래 마운트 못하는게 보통 엔진
정상이고, 또, 릴리즈 안 되어 다른곳에 마운트 막혀도 상관 없고, 그게 정상 동작일
수 있어보임."*

**분석 — 사용자 쪽이 더 맞아 보인다.** 명시적 `releaseOwner`가 들어간 원래
근거(2026-08-13 감사)는 *"`elementOwner`가 weak라 GC 타이밍에 따라 '이미
마운트돼 있음' error가 **비결정적으로** 터진다"*였는데, 다시 보면:

- **그 error가 나는 상황 자체가 버그다** — 파괴된 요소를 다른 곳에 다시
  넣으려는 코드이기 때문. 즉 "비결정적으로 실패"의 반대는 "성공"이 아니라
  **"항상 실패"**이고, 그게 더 나은 동작이다.
- **명시적 반납은 오히려 그 버그를 통과시킨다** — 파괴된 요소를 재마운트하는
  코드가 조용히 성공하고, 그 다음에 죽은 Instance를 다루다 엉뚱한 데서 터진다.
- **비결정성만 없애면 된다** — 반납을 안 하면 GC 전엔 error, GC 후엔 통과라
  여전히 비결정적이다. 이걸 결정적으로 만들려면 오히려 **파괴된 요소에
  "파괴됨" 표식을 남기는** 쪽이 맞는데, 그건 새 부기다.

**선택지**:
- **(a) 명시적 `releaseOwner` 제거** — 단순해지고, "파괴된 걸 재사용하면
  (대개) 막힌다"는 동작이 남는다. 비결정성은 그대로.
- **(b) 유지** — 지금 문서 그대로.
- **(c) 반납 대신 "파괴됨" 마킹** — 결정적으로 항상 error. 부기가 하나 는다.

**추천: (a)**, 다만 "비결정적"이라는 성질이 남는 걸 문서에 명시. (c)는
`conventions.md`의 "드문 오용이나 가상의 미래 요구까지 방어/최적화하려고 구조를
복잡하게 만들지 않는다" 기준으로 지금은 과해 보인다.

### C-5. `SL-58` — 배치 밖 재마운트의 낭비가 실제로 있나 (+ 개선안)

**사용자 질문**: *"offset 이 전부 같아 set 안 일어나고 가벼운거로 아는데,
아님?"*

**분석 — 뒤에 형제가 없으면 맞고, 있으면 아니다.**

steady state에서 position `k`의 `state<Slot>`이 교체될 때:

1. `attachSlot`이 `setOffsetSource(ownerKey, k, ...)` → `1..k-1` 합이라
   **안 바뀜**(사용자 말대로 여기까진 무해).
2. `Dispatch.setLength(ownerKey, k, slot.Length)` → `slot.Length`는 아직
   **flush 전이라 0**. Observer "등록 즉시 1회 실행" → 부모 blocker가 꺼져
   있으니 `recompute(부모)`가 **즉시 돈다.**
3. 그 `recompute`는 `lengthList[k] = 0`으로 계산하므로 **`k+1..N` 위치의
   offset이 전부 줄어든 값으로 `:Set`된다** → 그 아래 `LayoutOrder` 캐스케이드.
4. flush가 끝나고 `slot.Length:Set(최종)` → 다시 `recompute` → offset 원복.

즉 **`k` 뒤에 형제가 하나도 없으면 낭비가 정말 없고**(offset이 바뀔 대상이
없음), **뒤에 형제가 있으면 그 형제들의 offset이 두 번 `Set`되고 다운스트림도
두 번 돈다.** 값은 결국 맞으므로 크래시나 영구 오류는 아니다.

**개선안(제안)**: `attachSlot`에서 **`Dispatch.setLength`를 flush 루프
*뒤*로 옮기면** 이 왕복이 사라진다 — 그 시점엔 `slot.Length`가 이미 최종
값이라 부모 `recompute`가 한 번만 돈다. 배치 안에서는 어차피 부모 blocker가
켜져 있어 차이가 없고, 배치 밖에서만 이득이다.

- **확인 필요한 것**: `setOffsetSource` → `setLength` **순서 계약**은 유지된다
  (둘 다 flush 앞뒤로 갈릴 뿐 상대 순서는 그대로). `bk.N`을 `setLength`가
  올리는 규칙도 한 position 안에서는 영향이 없어 보인다.
- **판단 부탁**: 이건 확정된 의사코드의 순서를 바꾸는 것이라 임의로 안 고쳤다.
  **옮길지, 지금처럼 두고 "한 프레임 낭비 허용"으로 남길지.**

### C-6. `SL-76` — `recompute`의 `nil` 관대 처리를 어떻게 할지

B-8의 조사 결과, 지금 설계에서 **도달 경로를 못 찾았다.** 선택지:

- **(a) 유지 + 근거 갱신** — "지금은 도달 경로가 확인되지 않지만 전이 구간
  방어로 남긴다"로 문구만 정직하게 고침.
- **(b) 삭제** — `None`만 처리하고 `nil`은 `bk.N` 계약 위반이므로 자연히
  터지게 둠.
- **(c) `error`로 승격** — `nil`이 관측되면 **부기가 깨졌다는 신호**이므로
  조용히 skip하지 말고 즉시 error(코퍼스의 "매치 실패는 즉시 error",
  `releaseOwner` 불일치 error와 같은 톤).

**추천: (c)** — 관대한 skip은 "위치 하나가 조용히 순서 계산에서 빠지는"
디버깅 어려운 오작동이 되고, 지금은 그게 정상 경로로 생기지 않는다는 게
분석 결과이므로 error가 더 안전하다.

### C-7. "Length로 먼저 밀어내고 그 공간에 넣는다"가 다른 CRUD/`:List`에도 통하는가

**사용자 제기**: *"만약 밀어내고 당기지 않은 상태에서 그 공간에 넣는다 하면,
밀어내는걸 구현해야하는 백엔드에서 골치아파짐. 지금 어떤 상황인지 확인해볼것"*

**조사 결과 — `rawAdd`만 순서가 명시돼 있고 나머지는 안 적혀 있다.**

- **`rawAdd`(문서화됨)**: `self.Length:Set(newCount)`(→ 뒤 형제 offset 갱신이
  여기서 동기적으로 끝남) → `element.Parent = target`. 즉 **"밀어낸 뒤 넣는다"**.
- **`rawRemove`/`rawUnmount`(문서화 안 됨)**: 의사코드는
  `unbindLifetime` → `releaseOwner` → 파괴/언마운트 → `spliceArraysDown` →
  `recompute` 순서다. 즉 **"빼고 나서 당긴다"**. `rawAdd`의 거울상이라 일관돼
  보이지만 **명시적으로 계약화돼 있지는 않다.**
- **`Splice`(문서화 안 됨)**: "shift+recompute 1회로 묶는다"만 있고 물리
  detach/attach와 부기의 **선후가 안 적혀 있다.** 제거분과 삽입분이 겹치는
  구간이라 특히 애매하다.
- **`:List`의 `rawMove`(문서화 안 됨)**: "Parent를 안 건드린다"만 확정돼 있어
  물리 이동이 없으니 이 문제에서 빠지는 것으로 보인다.

**판단 부탁**: 이걸 **일반 계약으로 승격**할지 — 예컨대 *"부기(Length/offset)
갱신이 물리 트리 조작보다 항상 먼저 끝난다"* 를 `dispatch-core-plan.md`나
`slot-plan.md`에 한 줄로 못박고 모든 `raw*`가 따르게 할지. 그러면 백엔드
작성자가 "내가 물리적으로 밀어낼 때 부기는 이미 정확하다"를 전제할 수 있다.
**승격에 찬성하시면 문구를 써서 반영하겠다.**

### C-8. `SL-48` — Slot-in-Slot에서도 Destroy 후 정리가 성립하나

**사용자 메모**: *"더 나아가 slot in slot 에서도 유효한가 생각해보아야함.
아마 그런것으로 알고있음. 피지컬 홀더랑 오너가 다르거든."*

**분석 — 성립하지만, `D-56`이 해결돼야 성립한다.** 중첩에서 둘이 갈린다:

- **physicalTarget**(물리 Instance) — `attachSlot`이 자식 요소를 실제로
  `Parent`하는 대상. 최상위든 중첩이든 **같은 물리 부모**다.
- **ownerKey**(부기 소유자) — 최상위는 `inst`, 중첩은 **부모 Slot 자신**.

Destroy 시나리오를 따라가면:

1. physicalTarget이 Destroy → gcconn 끊김 → 그 `inst`에 `bindLifetime`된
   것들은 `canExecute`가 거짓이 되어 발화가 멈춘다. ✅
2. 중첩 Slot의 `setLength` Observer는 `bindLifetime(ownerKey=부모Slot,
   observer)`로 묶여 있다 — **`inst`가 아니다.** 그래서 1번만으론 안 끊기고,
   **부모 Slot이 unreachable해질 때** 같이 죽어야 한다.
3. 부모 Slot은 `gchold`(physicalTarget의)에 강참조로 매달려 있으므로,
   physicalTarget이 GC되면 부모 Slot도 참조가 끊긴다 → 그 아래 `Relate(부모
   Slot)` 부기도 weak-keyed라 같이 사라진다. ✅

**결론: 체인이 성립한다.** 다만 **2번이 성립하려면 `bindLifetime`이 Slot을
첫 인자로 받는 걸 실제로 처리해야 한다** — 그게 A절에서 신설한 `D-56`
요구사항이다. 즉 `SL-48`은 "이미 맞다"가 아니라 **`D-56`이 구현되면 맞다.**

→ **이 분석이 맞나?** 특히 3번(physicalTarget → 부모 Slot → 중첩 부기의
연쇄 GC)이 실제로 그렇게 도는지.

### C-9. `AT-13` — `retractor`를 부르는 주체

**사용자 확인 요청**: *"정확히는 같은 핸들러 재프로세스는 retractor 를
process 에서 굴리고 자기 작업을 함. 따라서 process → calls retractor(v) →
process new one 이 맞는걸로 보이는데 … 실제 구현은 저렇게 알고 있는게 맞음?"*

**답: 맞다.** 의사코드 그대로다:

```lua
function Dispatch.process(inst, k, v, index)   -- ← 오케스트레이터
    ...
    if slot ~= nil and slot.handler == h then
        slot.retractor(v)                       -- ① 여기서 굴림
        slot.retractor = NOOP
        local retractor = h.process(inst, k, v, index)   -- ② 자기 작업
        ...
```

즉 **`Dispatch.process`(오케스트레이터)가 ①과 ②를 둘 다 부른다.** 문항의
"`retractor(v)` → `process`"는 그 둘의 **순서**만 적고 **누가 부르는지**를
생략한 축약이었고, 사용자 이해가 정확하다. `handler.process`(개별 핸들러)는
자기가 retractor를 부르지 않는다 — 그건 오케스트레이터의 일이다.

→ 문서엔 이미 이렇게 적혀 있어 **정정 불필요**. 확인만.

---

## D. 문항지 자체가 stale해진 것 (업스트림 병합 결과)

문항지는 `pull` 전 `base/`를 기준으로 썼다. 업스트림 12커밋이 들어오면서
아래가 이미 달라졌다 — **문항이 틀린 게 아니라 시점이 지났다.**

| 문항 | 무엇이 달라졌나 |
|---|---|
| `ML-5` | 사용자가 회신에서 직접 짚음(*"새로운 커밋에서 이것이 달라짐"*). 파일마다 `Relate()`+`INITED` 센티널을 두는 설계가 **`RunInit` 하나로 통합**됐다 — **함수 자기 자신을 릴레이션 키로** 쓰므로 센티널이 불필요. `quad-base/src/init.luau`에 실제 구현 + `test/smoke.init.luau`로 검증까지 끝. **문항 `ML-5`는 폐기.** |
| `ML-8` | 위 변경에 맞춰 `RunInit`(함수 identity) vs `_initializedBy`(문자열 마커) 구분으로 재서술됨. **결론은 그대로**(둘은 다른 층위, 재사용 안 함)이라 문항 자체는 여전히 유효. |
| `ST-3` | "M0에서 실측 확인할 것"이 **실측 완료**됨 — `luau-test/done/21-type-store-undeclared-key-rejected.luau`가 미선언 키 접근 2건이 정확히 `TypeError`로 거부됨을 확인. **⚠️ 열린 항목이 아니게 됨.** |
| `D-10` | 위 B-2 — 스파이크 `01`이 이미 통과. |
| `A-2` | 패키징이 **wally → pesde**로 바뀌었고 `mise`/`selene`가 도입됨. 문항의 "wally 패키지" 표현이 stale(모놀리식 모노레포라는 **결론 자체는 유지**). |
| 전반 | `M0`/`M1`이 **완료**됐다 — 문항지 여기저기의 "M0 착수 전/M0에서 확인" 표현은 이제 "M2 착수 전"으로 읽어야 맞는 것들이 섞여 있다. |

**신규 문서 2개는 문항이 아예 없다** — `base/project-setup-plan.md`(pesde/mise/
selene/Rojo/darklua 경계)와 `base/quad-types-plan.md`(`AddPlugin<Self,P>`/
`CheckedQuad<T, Pattern>`/`type-version-check`). `architecture.md`와
`typing-limits.md`도 이 라운드에 내용이 늘었다. **원하시면 이 넷만 대상으로
5라운드 문항지를 따로 만들겠다** — 지금 4라운드 회신 처리가 먼저라 착수하지
않았다.

---

## E. 회신 방법

- **B절(재질문)** — 각 항목의 "이 이해가 맞나?"에만 답해주면 된다. 맞으면
  그대로 두고, 어긋나면 그 지점만 알려주면 base까지 같이 고친다.
- **C절(판단 필요)** — 선택지에 번호를 달아뒀으니 고르거나, 더 나은 안을
  주면 된다. **`C-1`(KeyGone)과 `C-2`(dispose vs `state<Frame>` 충돌)가
  가장 파급이 크고 나머지를 막고 있다.**
- **D절** — 5라운드를 만들지만 알려주면 된다.
