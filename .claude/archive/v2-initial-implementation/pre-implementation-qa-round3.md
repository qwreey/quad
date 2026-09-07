# 구현 전 QA **3라운드** — Blocker/`attachSlot`/`recompute` 손 트레이싱

**상태**: **완료 — `RC-3`/`RC-4`/`bk.N` 전부 사용자 확정을 거쳐 `base/`
반영 완료.** 2라운드가 발견·해결한 `RC-1`(Blocker 게이팅) 반영분을
대상으로, 이번엔 `attachSlot`이 그 게이팅을 실제로 어떻게 쓰는지와
`recompute`가 의존하는 `bk.N`의 수명주기를 손으로 실행해봤다. 부수로
`ROADMAP.md` 마일스톤 분할이 이번 라운드 발견과 맞는지도 검토했다
(1라운드가 미룬 항목).

**⚠️ 이 문서를 읽을 때 주의 — 아래 문제 서술 중 일부는 최초 작성 당시의
분석 오류를 포함한 채 그대로 남아 있다(의도적으로 안 고침, 논의 과정
보존).** 특히 `bk.N` 절의 "(a)/(b) 두 갈래 다 깨진다"는 최초 분석은
**틀렸다** — 사용자가 직접 지적해 정정됐다("해결 — `bk.N`" 절 참고).
지금 유효한 결론은 각 절의 "해결" 소제목 아래만 — 그 위 문제 서술은
"당시엔 이렇게 봤다"는 트레이싱 원문으로만 읽을 것.

**이 문서의 용도**: 2라운드와 같은 톤 — 트레이싱 결과 자체가 산출물이고,
버그는 그 자리에서 기록, 방향이 갈리는 것만 사용자에게 물었다.

---

## RC-3 — `activateList`가 자기 Slot의 Blocker보다 먼저 실행됨

**대상**: `base/slot-plan.md` "재귀 메커니즘" 절의 `attachSlot` 의사코드.

**순서를 그대로 읽으면**:
```lua
slot._mounted = true              -- (1) 이 시점부터 이미 "마운트됨"
...
if slot._listed then
    activateList(slot, physicalTarget)   -- (2) reconcile 실행 — 아직 Blocker 없음
end
Dispatch.setLength(ownerKey, position, slot.Length)   -- (3)
local blocker = getBlocker(slot)   -- (4) Blocker가 여기서야 생성됨
blocker:On()
for i, element in ipairs(slot._elements) do ... end   -- (5)
blocker:OffWithoutEmit()
```

**문제**: (1)에서 `slot._mounted = true`가 이미 세팅된 채로 (2)의
`activateList`가 실행된다. `activateList`의 `reconcile`은 새 항목마다
`rawAdd(self, result, pos)`를 부르는데(`slot-plan.md`의 `:List` "구현"
절), "이미 마운트된 outer에 나중에 `Add`" 절이 명시하듯 `self._mounted`가
참이면 `rawAdd`는 그 자리에서 즉시 물리 마운트 경로를 탄다 —
`isSlot(element)`면 `attachSlot(element, ...)` 재귀, 아니면(대칭적으로)
`Dispatch.setOffsetSource(self,index,None)` + `Dispatch.setLength(self,index,1)`
+ `element.Parent = physicalTarget`. `Dispatch.setLength`는 끝에서
`gatedRecompute`를 부르고, `gatedRecompute`는 `getBlocker(ownerKey=self)`의
`IsOn()`을 확인하는데 — **(4)의 `getBlocker(slot):On()`이 아직 실행되기
전이므로, 새로 생성된 Blocker는 기본 off 상태고 게이트가 그냥 통과된다.**

즉 `:List`의 초기 reconcile이 채우는 **모든 항목마다** `recompute`가
그 자리에서 즉시(게이팅 없이) 돈다 — 이건 정확히 `RC-1`이 막으려던
"배치 등록 중 매 position마다 recompute가 도는" 모양이다. 사용자가
`RC-1` 논의에서 직접 지적한 문제("이러면 첫 실행에서 계속 recompute
비용이 쌓임")가 `:List`의 초기 population 경로에서는 그 처방이 적용되기
**전** 자리에서 그대로 재현된다.

**크래시로 이어지는지는 `bk.N`에 달려 있다** — 아래 "`bk.N` 수명주기"
절 참고. `bk.N`이 이 시점에 아직 `0`(또는 `nil`)이면 크래시는 안 나고
그냥 매 항목마다 무의미한 `recompute(self,bk)` 호출만 쌓인다(루프가
`for i=1,0`이라 즉시 반환). `bk.N`이 최종 개수로 미리 정해져 있는
모델이면 `RC-1`과 완전히 같은 모양(뒤쪽 `lengthList[i]`가 아직 `nil`)의
크래시가 난다.

---

## RC-4 — flush 루프가 `:List`로 이미 마운트된 요소를 다시 처리함

**같은 `attachSlot`에서 이어지는 문제**: (5)의 flush 루프
(`for i, element in ipairs(slot._elements) do ... end`)는 `slot._listed`
여부를 확인하지 않고 **항상** 돈다. 그런데 `_listed`/`_crudUsed`는 상호
배타(`slot-plan.md`의 "CRUD API 확정" 절 — `_crudUsed`/`_listed` 역방향
가드)이므로, `:List`가 설치된 Slot의
`_elements`는 수동 `:Add()`가 아니라 **오직 (2)의 `activateList`가
채운 것뿐**이다 — 그리고 위 `RC-3`에서 확인했듯 그 채움 과정 자체가
이미 각 항목을 물리적으로 마운트(`element.Parent = physicalTarget`)하고
`Dispatch.setOffsetSource`/`setLength`를 등록까지 마친 상태다.

flush 루프는 이 사실을 모르고 **같은 요소들을 처음 보는 것처럼** 다시
처리한다 — `Dispatch.setOffsetSource(slot, i, None)`/
`Dispatch.setLength(slot, i, 1)`을 중복 호출하고, 이미 부모에 붙어있는
`element`에 `element.Parent = physicalTarget`를 다시 대입한다(Roblox라면
`AncestryChanged`가 불필요하게 한 번 더 발화). 값 자체는(멱등하게) 결국
맞게 수렴하겠지만, `:List`가 nested Slot을 요소로 반환한 경우
(`isSlot(element)`)는 **`attachSlot(element, physicalTarget, slot, i)`가
통째로 두 번 실행**된다 — 이건 멱등하지 않다: `slot._mounted = true`를
다시 세팅하는 정도는 무해해 보여도, "마운트된 Slot의 재마운트는 즉시
throw" 규칙(`slot-plan.md` "마운트된 Slot의 재마운트는 즉시 throw" 절)에
비춰보면 **nested Slot이 자기 자신을 향해 재귀적으로 이미 마운트된
채로 다시 `attachSlot`되는 것 자체가 그 규칙이 막으려는 상황과 같은
모양**이라, 최소한 이 규칙과의 정합성을 다시 검토해야 한다.

**추정 원인**: flush 루프의 주석("attach 전에 이미 들어와있던 요소들
flush")이 밝히듯, 이 루프는 **수동 CRUD로 마운트 전에 `:Add()`된
요소**만 염두에 두고 `RC-1` 해결 과정에서 추가된 것 — `:List` 케이스가
같은 함수를 통과한다는 걸 놓친 것으로 보인다(`RC-1` 자체는
`Dispatch.drive`/`attachSlot`의 flush 두 자리만 위험하다고 확인했고,
`activateList`는 그 확인 대상에 없었다).

**참고**: 이 두 결함(`RC-3`/`RC-4`)은 정확한 크래시/오작동 심각도가
`bk.N`의 수명주기에 좌우되므로, 아래 질문의 답이 나온 뒤 같은 자리에서
같이 고치는 게 맞아 보인다(둘 다 "`_listed`면 flush 루프를 건너뛰고,
`activateList` 자체를 `blocker:On()`/`OffWithoutEmit()`으로 감싼다"는
같은 방향의 수정으로 닫힐 가능성이 높음 — 다만 이건 제안이지 확정
아님, 사용자 확인 필요).

### 해결 — `_mounted`를 `activateList` 뒤로 미룸 (2026-08-18, 같은 세션 후속, 사용자 설계)

위에서 제안했던 "`_listed`면 flush 루프를 건너뛴다"는 **채택 안 됨** —
사용자가 더 단순한 대안을 직접 제시했다:

> if not slot._listed then ... end 로 감싸면 안 되는거 아닌가요? 그냥
> _mounted 를 activateList 아래 두는게 안되는 이유가 있어요? 만일,
> 그렇게 감싼다면 그건 blocker 를 안 타니까요. 그리고 또, attachSlot 은
> 런타임 상 발생할 수 있는게 맞긴 하죠? 왜냐면, 안 그러면 List 에서
> Frame 만 던질 수 있어요. nested slot 을 던지는 컴포넌트는 사용
> 못하게 될텐데요.

**`slot._mounted = true`/`slot._mountedInst = physicalTarget`를
`attachSlot` 맨 위에서 `activateList` 호출 **뒤**(flush 루프 바로 전)로
옮기면 `RC-3`/`RC-4`가 한 번에 닫힌다**:

- `activateList`가 실행되는 동안 `self._mounted`가 계속 `false`이므로,
  `:List`의 reconcile이 부르는 `rawAdd`는 "아직 마운트 전" 경로
  (`_elements`에만 넣고 물리 마운트/Dispatch 등록은 안 함,
  `slot-plan.md`가 이미 "self가 아직 마운트 전이면 _elements에만
  들어가고, self가 나중에 attachSlot될 때 위 flush 루프가 처리"로
  명시해둔 바로 그 경로)를 탄다. → `RC-3`(항목마다 무게이팅
  `recompute`) 자체가 안 생김 — flush 루프 전엔 어떤 Dispatch 등록도
  없으므로.
- flush 루프가 `slot._elements`(이제 `:List`든 수동 CRUD든 항상 여기에만
  쌓여 있음)를 순회하며 **처음이자 유일하게** 각 요소를 물리
  마운트한다 — nested Slot이면 `attachSlot`도 여기서 **딱 한 번만**
  불린다. → `RC-4`(이중 실행) 자체가 안 생김. `_listed` 분기가 필요
  없어짐 — flush 루프가 두 경로(`:List`/수동 CRUD) 모두에 대해 이미
  동일하게 옳은 유일한 마운트 지점이 됨.
- **`rawAdd`의 `self._mounted` 즉시-마운트 분기 자체는 그대로 남는다** —
  사용자가 확인한 대로 이건 삭제 대상이 아니라 **런타임에 실제로 필요한
  경로**다: `attachSlot`으로 최초 마운트가 끝난 **뒤**(예: `data`가
  나중에 바뀌어 `:List`의 reconcile이 다시 실행될 때) `self._mounted`는
  이미 `true`이므로, 그 시점에 새로 추가되는 nested Slot 항목은 이
  분기를 통해 정상적으로 즉시 `attachSlot`된다 — 그래서 `:List`가
  nested Slot을 반환하는 컴포넌트를 계속 지원한다. 이번에 바뀐 건 오직
  "`attachSlot` 자기 자신의 **최초** flush 이전엔 이 분기가 안 타야
  한다"는 타이밍 하나뿐.

**반영**: `base/slot-plan.md` "재귀 메커니즘" 절의 `attachSlot`
의사코드(`_mounted` 위치 이동 + 주석), `base/dispatch-core-plan.md`의
"저장 위치"/"배치 등록을 안전하게 만드는 Blocker 게이팅" 절, `base/
blocker-plan.md`의 "두 번째 용례" 절(아래 `bk.N` 해결과 같이 반영).

---

## `bk.N`의 수명주기가 명세에 없음 — 판단 필요

`recompute`(`base/dispatch-core-plan.md` "Length/Offset" 절)는
`for i = 1, bk.N do`로 순회한다. `bk.N`의 정의는 문서에 **딱 한 곳**뿐:

> **저장 위치**: `lengthList`/`sourceList`(부모 `inst` 하나에 귀속, 그
> `inst`의 array part 크기 `N`으로 같이 저장, `Dispatch.drive`가 최초
> 배열 파트 순회 시점에 이미 알고 있는 값) — `Relate(parentInst)`에
> lazy 생성.

이건 **`Dispatch.drive`가 순회하는 최상위 `inst`** 전용 서술이다 —
그 경우 `N`은 저작 시점에 고정된 배열 리터럴 길이라 정말로 "한 번 알면
끝"이다. 그런데 `base/slot-plan.md`의 "재귀 메커니즘" 절이 **같은
`recompute`/`getBookkeeping`을 Slot 자신을 ownerKey로 재사용**하면서
(`Dispatch.setLength`/`setOffsetSource`가 "owner 키(`inst`)가 물리
Instance일 필요가 없음"을 근거로), Slot의 경우 `bk.N`이 무엇이고 언제
갱신되는지는 **어디에도 안 적혀 있다**. `getBookkeeping`/
`spliceArraysDown` 자체도 이 코퍼스 전체에서 정의된 적이 없는(호출만
되는) 헬퍼다(grep 확인, `bk.N =` 대입 자체가 코퍼스에 0건).

**왜 이게 그냥 구현 디테일이 아니라 지금 결정이 필요한가**: `Dispatch.drive`의
`inst`와 달리, **Slot의 자식 개수는 Slot 전체 생애주기 동안 계속
바뀐다**(그게 Slot의 존재 이유) — "한 번 알면 끝"이라는 `inst` 쪽 전제가
Slot에는 애초에 성립하지 않는다. 두 갈래 다 손으로 트레이싱해보면 각각
다른 방식으로 깨진다:

**(a) `bk.N`이 "고정값"이라면(배치 시작 시 저장, 이후 안 바뀜)**:
`rawRemove`(`slot-plan.md` "파괴" 절)를 트레이싱하면 —
```lua
function rawRemove(self, index)
    ...
    spliceArraysDown(self, index)   -- _elements/lengthList/sourceList 한 칸씩 당김
    recompute(self, bk)             -- bk.N은 그대로(감소 안 함)
end
```
`spliceArraysDown`이 배열을 한 칸씩 당기고(마지막 자리는 비거나 stale
복제값으로 남음, 정의가 없어 어느 쪽인지도 불명) `bk.N` 자체를 줄이지
않으므로, **2개짜리 Slot에서 요소 하나를 `Remove`하기만 해도** 다음
`recompute`의 `for i=1,bk.N(=2)`가 이제 존재하지 않는 위치 2를 읽는다
— `spliceArraysDown`이 그 자리를 `nil`로 비운다면 `RC-1`과 정확히 같은
`sum += nil` 산술 에러, 옛 값을 그대로 둔 복제라면 그 값을 이중으로
합산하는 조용한 오계산이다. 어느 쪽이든 **가장 흔한 조작(2개 이상인
Slot에서 하나 제거)에서 매번 재현**된다 — `RC-1`이 "정적 자식 2개짜리
`Frame`에서도 재현"이라고 짚었던 것과 같은 급의 흔함.

**(b) `bk.N`이 "그때그때 실제 개수"라면(예: `#ownerKey._elements`로 매번
파생, 또는 매 `setLength`/`spliceArraysDown` 호출마다 갱신)**: 위
`rawRemove` 크래시는 없어진다. 대신 마운트 시점 배치(`Dispatch.drive`
최상위, `attachSlot`의 flush)에서 `RC-1`이 막으려던 **바로 그 크래시가
되돌아온다** — 배치 도중 `bk.N`이 이미 등록된 position 개수만큼만
증가한 상태라면 recompute 자체는 안전해지지만(순회 범위가 실제 채워진
자리까지만), 반대로 **Blocker 게이팅이 애초에 막으려던 "배치 끝나기
전엔 recompute 안 돈다"는 전제가 필요 없어진다는 뜻**이라 — `RC-1`의
해법 전체가 어떤 `bk.N` 모델을 전제하는지부터 다시 맞춰야 한다.
(자세히 보면 게이팅으로 `recompute` 호출 자체를 스킵하므로 (b) 모델이어도
크래시는 안 나지만, **배치 종료 후 딱 1회 도는 마지막 `recompute`가 이번엔
반대로 부족한 `N`을 볼 수 있다** — 예: `attachSlot` flush 루프 중간에
어떤 position의 `setLength`가 **State**를 받아 `Observer`의 "등록 즉시
1회 실행"이 배치 밖 시점까지 늦게 도착하는 경합이 있다면.)

**분기점 — 사용자 판단 필요(아래 질문 참고)**: `bk.N`을 그때그때 실제
개수로 둘지, 배치 시작 시 저장해두는 값으로 둘지에 따라 고칠 자리가
갈린다 — 전자면 `rawRemove`/`rawUnmount`/런타임 `rawAdd`가 문제,
후자면 `RC-3`/`RC-4`가 이미 지적한 자리가 문제. 어느 쪽이든 `RC-3`/
`RC-4`는 별도로 고쳐야 하지만, `bk.N` 자체의 수명주기 규칙은 이
문서가 결정하지 않는다 — 아래에서 직접 여쭤본다.

### 해결 — `bk.N` = 그때그때 실제 개수, 위 (b) 분석은 틀렸음 (2026-08-18, 같은 세션 후속, 사용자 지적)

위 (b) 갈래("`bk.N`이 그때그때 실제 개수면 마운트 배치에서 `RC-1`이
막으려던 크래시가 되돌아온다")는 **분석 오류였다.** 사용자가 직접
잡아냄:

> 그때그때 실제 개수를 전부 적용하는건 안 돼? 사실 전부 똑같은
> 방법으로 구현해도 상관 없지 않아? 그리고 drive 중에는 recompute
> 안나지 않아? 계속 후행 붙이기라서 약간 다를텐

**틀렸던 지점**: `Dispatch.drive`/`attachSlot`의 배치 등록 중
`recompute`가 안 도는 이유는 **`bk.N`이 아니라 Blocker 게이팅**
(`blocker:IsOn()`만 확인하는 `gatedRecompute`)이다 — 이 게이트는
`bk.N`이 무엇이든 **전혀 상관하지 않는다**. 그러므로 `bk.N`이 배치
도중 계속 늘어나는 중이어도(아직 최종 크기가 아니어도) 배치 안에서
`recompute` 자체가 안 도니 크래시도, 부정확한 계산도 안 생긴다 —
필자가 (b)를 쓰며 "게이팅이 배치 끝나기 전엔 recompute 안 돈다는
전제가 필요 없어진다"고 적었던 건 스스로 반대 결론(게이팅이 여전히
작동 중이라는 사실)을 옆에 적어두고도 놓친 것.

**결론**: `bk.N` = **그때그때 실제 개수**로 두 owner 타입(`inst`,
Slot 자신) 모두에 동일한 규칙 적용 — `Dispatch.setLength`/
`setOffsetSource`가 이전에 없던 더 큰 position을 등록할 때마다
`bk.N`이 그 값으로 늘어나고, `spliceArraysDown`(Slot의 `rawRemove`/
`rawUnmount`)이 위치를 구조적으로 지울 때 그만큼 줄어든다. `Dispatch.drive`의
`inst`에서는 최상위 배열이 구조적으로 안 바뀌므로 이 규칙이 그냥
"등록 끝나면 고정값처럼 보이는" 특수한 안정 상태가 될 뿐, 별도 모델이
필요 없다 — **두 owner 타입에 정말로 똑같은 구현**(사용자가 지적한
그대로).

**`RC-1`의 원래 크래시가 실제로 뭐였는지 다시 정리하면**: `bk.N`이
"배치가 시작되기도 전에 이미 최종 크기로 고정"돼 있었던 것의 부산물
— 그 전제 자체가 이번에 사라졌다. Blocker 게이팅이 지금도 필요한
이유는 크래시 방지가 아니라 **비용**이다: 게이팅 없이 매 position
등록마다 `recompute`가 한 번씩 돌면 배치당 O(N²), 게이팅으로 배치 끝에
한 번만 돌면 O(N) — `RC-1` 최초 논의에서 사용자가 직접 지적한 "이러면
첫 실행에서 계속 recompute 비용이 쌓임" 문제 그대로.

**추가로 확인된 갭 — `spliceArraysDown`이 미는 배열 목록에 `bk.observers`가
빠져 있었음.** `rawRemove`/`rawUnmount`가 제거되는 위치의
`bk.observers[index]`를 `unbindLifetime`하긴 하지만, `spliceArraysDown`
자신이 밀어야 할 배열로 지금까지 `_elements`/`lengthList`/`sourceList`
셋만 서술돼 있었다 — `observers`도 같이 밀지 않으면 이후 그 위치의
observer가 옛 이웃 것을 계속 가리키게 된다. `base/slot-plan.md`에
반영.

**반영**: `base/dispatch-core-plan.md`의 "저장 위치" 절(`bk.N`
수명주기 정의 신설), "배치 등록을 안전하게 만드는 Blocker 게이팅"
절의 "문제 재확인" 문단(크래시 전제가 바뀌었다는 정정 추가),
`base/slot-plan.md`의 `spliceArraysDown`/`rawRemove`/`rawUnmount`
근처(`bk.observers`/`bk.N` 갱신 명문화), `base/blocker-plan.md`의
"두 번째 용례" 절(같은 정정), `ROADMAP.md` M2 체크박스(같은 정정 +
M2/M3 교차 의존 각주).

---

## 확인만 하고 새 결함 없음 — 재검증

- **중첩 Slot의 `Length:Set`이 부모 Blocker가 켜져 있는 동안 나가는
  경우** — `attachSlot`이 재귀로 `attachSlot(element, physicalTarget,
  slot, i)`를 부를 때, 안쪽 재귀도 자기 자신의 `getBlocker(element)`로
  별도 Blocker를 새로 만들어(부모 Blocker와 무관) 자기 flush를 감싼다.
  안쪽 재귀 끝의 `recompute(element, bk)`가 `element.Length:Set(sum)`을
  호출하면, 이건 **부모 쪽 관점에서 보면 `Dispatch.setLength(parentSlot,
  i, element.Length)`가 이미 등록해둔 그 State 객체의 값이 바뀌는 것** —
  부모의 `gatedRecompute`가 이 변화를 받지만, 부모의 Blocker가 아직
  켜져 있으면(외곽 배치가 안 끝났으면) 정상적으로 스킵되고, 부모 배치가
  끝난 뒤 마지막 `recompute(parentSlot, parentBk)` 한 번에 자연스럽게
  반영된다 — 설계 의도대로 동작, 새 문제 없음.
- **`getBlocker`의 lazy 생성 기본값이 off라는 전제가 런타임 단건 경로를
  성립시킴** — "이미 마운트가 된 이후"의 단건 `:Add()`가 게이팅 없이
  바로 `gatedRecompute`를 태우는 게 안전한 이유는, 그 시점 Blocker가
  (flush 때 만들어져 `OffWithoutEmit()`으로 꺼진 채 남아있으므로) 항상
  off 상태이기 때문 — 트레이싱으로 재확인, 새 발견 아님.
- **⚠️ [신설, 반영 후 자체 재검토] 재정렬로 새로 생긴 좁은 엣지 케이스 —
  배치 밖(steady state)에서 Slot이 단독으로 (재)마운트될 때, 부모의
  `recompute`가 아직 안 굳은 `slot.Length` 값으로 한 번 먼저 돌 수
  있음.** `Dispatch.setLength(ownerKey, position, slot.Length)`(위 해결
  절의 재정렬 뒤 코드)은 `slot.Length`가 `State`라 `Observer` "등록 즉시
  1회 실행"을 그 자리에서 동기로 태운다 — 이게 부모의 `gatedRecompute`를
  부르는데, **이 Slot 마운트가 `Dispatch.drive`의 배치나 부모 Slot의
  flush 루프 **안**이면** 부모의 Blocker가 아직 켜져 있어 안전하게
  스킵되지만(트레이싱 확인, 새 결함 아님), **배치 밖에서 이
  `attachSlot`이 단독으로 불리는 경우**(예: `state<Slot>` 값이 steady
  state에서 반응형으로 교체돼 재-dispatch되는 경우, 부모 owner의
  Blocker는 이미 예전에 `OffWithoutEmit()`으로 꺼진 채)엔 부모의
  `gatedRecompute`가 즉시 실행돼, 아직 flush가 안 끝나 최종값이 아닌
  `slot.Length`로 부모가 한 번 (헛되이) 재계산한다 — 뒤이어 flush가
  끝나고 `slot.Length:Set(최종값)`이 다시 발화하면 부모가 다시 정확하게
  재계산해 값 자체는 스스로 바로잡힌다. **크래시도 영구적으로 틀린
  값도 아니고**, `Get()~=sum` 가드 때문에 실제로 `:Set`이 두 번 나가는
  것도 조건부(첫 번째 계산이 우연히 맞을 수도 있음)라 — Roblox 기준
  최악의 경우 한 프레임짜리 낭비 재계산 정도. 재정렬 이전 코드(`_mounted`가
  `activateList`보다 먼저)에는 이 경로 자체가 없었음(`slot.Length`가
  이미 등록 시점에 확정돼 있었으므로) — 그래서 완전히 새로 생긴 특성.
  **크래시급이 아니라 이 라운드를 다시 열진 않지만, 다음에 이 자리를
  만지는 세션이 알아야 할 사실로 기록.**
- **`Dispatch.drive` 자신은 코드 블록이 없다** — 이 문서 전체에서
  `Dispatch.drive`는 항상 산문으로만 서술되고(`Dispatch.drive(inst,
  flattened)`가 배열→해시 두 패스로 `Dispatch.process`를 부른다는 것),
  Blocker 게이팅을 그 함수 **자신**이 어떻게 여닫는지 보여주는 의사코드는
  없다(`attachSlot`만 실제 코드로 있음). 버그는 아님 — `Dispatch.drive`
  자체가 이 코퍼스 어디에도 전체 코드로 나온 적이 없어서(항상 서술뿐),
  이번에 새로 생긴 갭이 아니라 원래부터 그랬던 문서화 수준의 차이일
  뿐이다. 실제 구현 시(M2) `attachSlot`과 같은 패턴(자기 owner=inst의
  Blocker를 `:On()` → 배열 파트 순회 → `:OffWithoutEmit()` →
  `recompute` 1회)으로 쓰면 될 걸로 보이나, 코드로 명문화돼 있지 않다는
  점만 기록.

---

## `ROADMAP.md` 마일스톤 정합성 — 새 불일치 발견

1라운드가 "다음에 검토"로 미뤄뒀던 항목. 이번 라운드는 `RC-1`의 Blocker
게이팅 해법이 실제로 마일스톤 순서와 맞물리는지를 봤다.

**문제 — M2가 M3의 산출물(`Blocker`)에 구조적으로 의존하게 됐다.**
`ROADMAP.md` M2(디스패치 엔진)의 `Dispatch.setLength`/`setOffsetSource`
체크박스(90번대 줄)는 이렇게 적혀 있다:

> **[2026-08-18 구현 전 QA 2라운드 후속] `bk.N≥2`인 자리가 처음
> 채워지는 동안 크래시하던 경로(`RC-1`)는 owner별 `Blocker` 게이팅으로
> 해결됨** — `setLength`/`setOffsetSource`가 배치 등록 중엔 `recompute`를
> 미루고 배치가 끝나면 명시적으로 한 번만 돎

즉 M2 체크박스 자체가 "`setLength`/`setOffsetSource`를 구현하려면
`Blocker`가 있어야 한다"고 명시한다. 그런데 `Blocker.luau`는 M3
체크박스(`## M3 — Store/State/Source` 절)에 있고, 그 근거는:

> `Blocker.luau`(`base/blocker-plan.md` 참고 — 여러 Source를 한꺼번에
> 바꿔도 파생값 재계산/재대입이 한 번만 되게 하는 primitive, State와
> 밀접히 연관돼 있어 같은 마일스톤에서 개발)

이 근거("State와 밀접히 연관돼 있어서")는 `RC-1` 이전의 오래된 이유
그대로다(`base/blocker-plan.md` 자신도 "store 개발(M3)과 밀접하게
연관됨... 별도 파일로 두되 State와 같은 마일스톤에서 함께 구현할 것"이라고
써 있음, `.claude/todos.md` 4번의 "M3에서 `Blocker`를 구현할 때"도 동일).
`RC-1`로 생긴 **M2 → Blocker** 의존은 그 뒤에 어디에도 반영이 안 됐다 —
M2가 M3보다 먼저 오는 로드맵 순서상, **M2를 그대로 순서대로 구현하면
아직 존재하지 않는 `Blocker.luau`를 참조하게 된다.**

이건 2라운드가 확인한 "`RC-1` 언급이 텍스트로는 반영됐는가"(반영됨,
확인 완료)와는 다른 질문 — **텍스트는 맞는데 그 텍스트가 만드는
마일스톤 간 순서 요구가 로드맵 구조와 어긋난다.**

**참고로 M6(Slot)의 두 자리(368번대 줄 근처)는 이미 "위 M2 항목 참고"로
정확히 교차 참조돼 있어 문제 없음** — M6는 M3보다 뒤라 Blocker가 이미
존재한다는 전제가 깨지지 않는다. 문제는 오직 M2 하나.

**선택지는 여기서 결정하지 않는다** — 가능한 방향만 짚어둔다(사용자
판단 필요):
1. `Blocker.luau`(또는 그 최소 부분집합 — `On`/`Off`/`IsOn`/
   `OffWithoutEmit`만)를 M2로 옮기거나 M2 시작 부분에 선행 항목으로 추가.
2. M2 체크박스에 "M3의 `Blocker.luau`를 먼저(또는 병행) 구현해야 함"이라는
   명시적 순서 각주를 달아, 로드맵 순서 자체는 유지하되 M2 착수 시
   이 사실을 놓치지 않게 한다.
3. M2/M3 마일스톤 경계를 재검토(예: Blocker를 M2로 통째로 승격) —
   가장 큰 변경이라 신중히.

**임시로 2번(각주) 채택** — 마일스톤 경계 자체를 바꾸는 1/3번은
설계·일정에 영향이 가는 결정이라 사용자 확인 없이 고르지 않았다. 2번은
로드맵 구조를 안 바꾸면서 "M2가 M3의 산출물에 기대고 있다"는 사실만
빠짐없이 남기는 가장 보수적인 조치라 우선 적용해뒀음(`ROADMAP.md` M2
체크박스) — 1/3번을 원하면 언제든 다시 정리 가능, 아직 최종 확정
아님.

---

## 진행 로그

**3라운드(2026-08-18) — `attachSlot`/`recompute`/Blocker 게이팅 손
트레이싱, `ROADMAP.md` 마일스톤 정합성 재검토, 같은 세션에 전부 해결·
`base/` 반영까지 완료.** 발견 순서대로:

1. `RC-3`(`activateList`가 자기 Slot의 Blocker보다 먼저 실행돼 항목마다
   무게이팅 `recompute`가 도는 것으로 보였음)와 `RC-4`(flush 루프가
   `:List`로 이미 마운트된 요소를 중복 처리 — nested Slot이면 이중
   `attachSlot`)를 발견.
2. `bk.N`(순회 상한)의 수명주기가 문서 어디에도 없다는 것도 발견, 최초
   분석은 "고정값/그때그때 실제 개수 두 갈래 다 각기 다른 방식으로
   깨진다"고 판단해 사용자에게 물음.
3. **사용자가 그 분석 자체를 정정** — Blocker 게이팅은 `bk.N`이 아니라
   `blocker:IsOn()`만 보므로, "그때그때 실제 개수" 모델이 배치 중
   크래시를 되돌린다는 결론은 틀렸음을 지적("그때그때 실제 개수를 전부
   적용하는건 안 돼? ... 그리고 drive 중에는 recompute 안나지 않아?").
   `bk.N` = 그때그때 실제 개수로 두 owner 타입에 동일 적용 확정.
4. `RC-3`/`RC-4`도 사용자가 더 단순한 해법을 직접 제시 — flush 루프를
   `_listed`로 분기하는 대신, `attachSlot`의 `slot._mounted = true`를
   `activateList` 호출 **뒤**로 옮기는 것 하나로 둘 다 닫힘("_mounted
   를 activateList 아래 두는게 안되는 이유가 있어요?").
5. 부수로 `spliceArraysDown`이 밀어야 할 배열 목록에 `bk.observers`가
   빠져 있던 것도 같이 발견·반영.
6. `ROADMAP.md` M2가 M3의 `Blocker.luau`에 구조적으로 의존하게 된
   불일치는 각주로 반영(가장 보수적인 조치, 마일스톤 재편 여부는 열림).

**반영 완료**: `base/slot-plan.md`(`attachSlot` 의사코드 재작성,
`spliceArraysDown`/`bk.N`/`bk.observers` 명문화), `base/
dispatch-core-plan.md`(`bk.N` 수명주기 신설, 크래시 전제 정정),
`base/blocker-plan.md`(게이팅 존재 이유 정정), `ROADMAP.md`(M2 체크박스
정정 + M2/M3 교차 의존 각주). `python3 .claude/tools/doc-check.py`로
ERROR 0 확인 완료.
