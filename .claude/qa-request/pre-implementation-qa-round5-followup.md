# 구현 전 QA **5라운드 followup** — 회신 처리 결과 + 재질문

**상태**: **[2026-08-21] 4차까지 처리. 열린 항목은 `Gate` 하나뿐.**
A~E절은 1차 처리(문항지 회신), F절은 2차, G절은 3차(`mountInst` 삽입 위치 질문),
**최신은 H절**(그 결론 — `getOffsetAt` 신설로 확정, `base/` 반영 완료). 회신 원문은
`pre-implementation-qa-round5-response.md`, 문항지 원본은
`pre-implementation-qa-round5.md`. **처리 결과의 소스는 이 파일**이고,
지금 유효한 설계는 언제나 `base/`가 소스다(4라운드에서 이 구분이 실제로
어긋난 사례가 있었다 — 아래 `A-8` 참고).

**이번 라운드에서 언급 안 된 문항은 전부 "예"로 간주**했다(4라운드와 같은
규약 — 회신은 아니오/보류만).

---

## A. 반영 완료 — 바로 고친 것

전부 이번에 `base/`(+`ROADMAP.md`/`question.md`/`README.md`)에 반영했고
`doc-check.py` ERROR 0을 유지했다.

| # | 항목 | 무엇을 고쳤나 | 대상 |
|---|---|---|---|
| A-1 | `DE-7` | **`slot._detached`를 lazy(nilable)로** — 모든 Slot이 빈 테이블을 미리 갖지 않는다. 읽기는 `if slot._detached then`, 쓰기는 `getDetached(slot)`(getOrCreate). `settle`/`destroySlotTree`/`_detachCleanup` 세 자리 전부 nil 가드 | `slot-plan.md` |
| A-2 | `DE-7`(추가 질문) | **`prev`가 없는데 `Detach`를 반환해도 nop** — 사용자가 "지금 prev가 있는지"를 추적할 의무가 없다는 걸 계약으로 명시 | `slot-plan.md` |
| A-3 | `DE-9` | **`KeyGone`에 `nil`/`None`/`Detach` 외 반환은 전부 `error`** — `prev`뿐 아니라 **새 값도** 거부. 그래서 소멸 루프의 `settle` 호출은 항상 `result == nil`이고 교체 분기에 도달할 경로가 없어졌다(옛 코드는 `pos = 0`으로 `rawAdd`를 불러 범위 밖 인덱스로 터졌을 것) | `slot-plan.md` |
| A-4 | `DE-13` | **`Owned = false`에서 `Detach`는 `_detached`에 안 들어간다** — `rawDetach`가 아니라 `rawUnmount`(언마운트+소유권 반납)로 처리, 다음 사이클 `prev`는 `nil`. `Owned` 대조표에 `Detach` 행 추가, `_detachCleanup`의 `_owned` 분기는 **삭제**(도달 불가가 됨) | `slot-plan.md` |
| A-5 | `DE-11` | "홀드된 요소는 owner가 죽을 때까지 쌓인다 / 삽입·삭제 최적화일 뿐 그 이상을 돕지 않는다"를 **문서화 유의사항으로 명시**, 잘라내기 정책은 안 만든다 | `slot-plan.md` |
| A-6 | 회신 마지막 "+" | **조상이 죽으면 `Owned = false` 요소도 엔진 재귀 파괴로 같이 죽는다**를 신설 — "`Owned = false`가 약속하는 건 quad가 안 죽인다는 것뿐"이라는 경계까지 | `slot-plan.md` |
| A-7 | `AT-1`/`AT-2` | `groupClaimKeys`의 키를 **`(inst, groupValue) → k`로 확정**, `nameClaims`보다 **위치 claim을 먼저** 본다는 순서까지. `Frame { a, a }` 갭도 같이 닫힘 | `attribute-plan.md`, `question.md` |
| A-8 | `EF-3` | 4라운드가 반영했다고 적고 실제로는 누락됐던 **`E-10` dedup 대칭 결론을 실제로 반영** + `EF-5`(내부 Observer cascade도 dedup 분기 **안**) 명시. "미해결" 표시 제거 | `effect-plan.md` |
| A-9 | `TW-2`/`CR-2` | **`Tween<T>:Mapped(fn)`으로 확정** — 문서 전체 표기 통일(`tween-plan.md`/`ui-shorthand-plan.md`) | `tween-plan.md`, `ui-shorthand-plan.md` |
| A-10 | `DC-6` | `Offset` Source의 identity를 유지하는 진짜 이유를 사용자 서술로 정밀화 — "언마운트 때 이미 렌더된 요소들이 그 Source를 **구독한 채 함께 딸려 나간다**" | `dispatch-core-plan.md` |
| A-11 | `DC-11` | 배치 끝 `recompute`가 실제로 하는 일을 명시 — offset은 즉시 계산이 이미 채웠고, **(a) Slot owner의 `.Length` 확정**(사용자 추측대로 이게 주 목적)과 (b) 등록 후 바뀐 길이 교정이 역할 | `dispatch-core-plan.md` |
| A-12 | `DC-14` | 재진입 경로가 **정상 API로는 아예 만들 수 없다**를 명시(`_crudUsed` ↔ `_listed` 가드 때문) | `dispatch-core-plan.md` |
| A-13 | `CR-3`/`DT-4` | **"게이팅 먼저" 결정 반영** — M2 각주를 해소로 갱신하되, 앞당기는 대상이 `Blocker`가 아니라 공용 `Gate` 노드라는 것과 표면이 미정이라는 것까지 | `ROADMAP.md`, `question.md` |
| A-14 | 새 문서 2개 | `research/gate-primitive.md`, `research/state-epoch-validation.md` 신설(아래 D절) + `README.md` 색인 | `research/`, `README.md` |

---

## B. 답변 — 물어보신 것

### B-1. `DE-13` — `_detachCleanup`이 뭔가, 그리고 unowned 판단이 맞나

**먼저 `_detachCleanup`이 뭔지**: **"detach해둔 요소들을 나중에 청소하는 쪽"**이
맞다. 정확히는 — `activateList`가 Slot마다 하나 설치하는 **`Effect`이고, 그
cleanup이 `slot._detached`를 전부 비운다.** 언제 도느냐가 핵심인데,
`bindLifetime(physicalTarget, self._detachCleanup)`으로 **물리 target에
앵커**돼 있어서 **그 물리 Instance가 죽을 때** cleanup이 돈다.

왜 `Effect`가 유일한 도구냐면, `bindLifetime`은 "지금 실행해도 되는가"만
게이팅할 뿐 **죽는 순간의 콜백을 안 준다** — 죽을 때 뭔가를 하려면 `Effect`의
cleanup 계약이 필요하다(`base/effect-plan.md`).

**그리고 unowned에 대한 판단 — 맞다. 잘못 흐른 게 아니다.** 검토 결과:

- `Owned = false`는 "이 요소는 애초에 내 게 아니다"이므로, **"잠깐 빼두고
  내가 계속 들고 있는다"(= `Detach`)가 성립할 수 없다.** 들고 있으려면
  소유권을 유지해야 하는데(`rawDetach`가 `releaseOwner`를 안 부르는 게
  그 핵심), 남의 것에 소유권을 유지하는 건 모순이다.
- 그래서 `Owned = false` + `Detach`는 **`rawUnmount`(언마운트 + 소유권
  반납)**로 처리하고 `_detached`에 안 넣는다 → 다음 사이클 `prev`는 `nil`.
  **말씀하신 그대로 반영했다.**
- **부수 결과 둘**: (1) unowned `:List`에서는 `Detach`와 `nil` 반환이
  **완전히 같은 동작**이 된다(둘 다 언마운트+반납). (2) unowned Slot은
  `_detached`가 영원히 비어 있으므로 `_detachCleanup`의 `_owned ~= false`
  분기가 **도달 불가**가 된다 — 그래서 그 분기를 지웠다(이제 cleanup에
  오는 건 전부 내 것).
- **`state<Frame>` 의미론과의 정합도 그대로 지켜진다** — 값 교체 시
  `releaseElement`가 `_owned == false`를 보고 `rawUnmount`로 빠지므로 이전
  요소는 파괴되지 않는다. 말씀하신 논거와 같다.

### B-2. `DE-7` 추가 질문 두 개

**(a) 아무것도 없는데 `Detach`를 보내면?** → **무시(nop)한다.** 지금
의사코드가 이미 `if wasMounted ~= nil then ... end`로 감싸고 있어서 `prev`가
없으면 아무 일도 안 일어난다. **사용자가 "지금 prev가 있는지"를 추적할 의무가
없다**는 걸 계약으로 명시해뒀다(A-2) — `if not shouldShow(item) then return
Detach end`처럼 조건만 보고 반환해도 안전하다. 이렇게 둔 이유는 "이미 detach
중이면 nop"과 같은 결이기 때문이다(둘 다 "이 자리를 비워라"인데 이미 비어
있는 상태).

**(b) 마운트 상태의 `prev`를 다시 반환하는 건 여전히 잘 도는가?** → **그렇다.**
`settle`의 `result == prev` 분기가 `wasDetached == nil`이므로 재마운트 쪽으로
안 가고, `keyIndex[key] ~= pos`일 때만 `rawMove`를 부른다. 값도 위치도 그대로인
가장 흔한 경로는 **테이블 조회 몇 번이 전부**이고 물리 트리에 손을 안 댄다.
이번 변경(lazy `_detached`, unowned 분기)은 전부 `detach == true` 경로나
`wasDetached ~= nil` 경로만 건드려서 이 경로에는 닿지 않는다.

### B-3. `AS-5` — `activateList`가 상위에 `setLength`를 하는가

**안 한다. 상위 등록(`Dispatch.setLength(ownerKey, position, slot.Length)`)은
`materializeSlotTree`의 마지막 줄이 유일한 자리**이고, 그건 Blocker를 이미
`OffWithoutEmit()`한 뒤다. `activateList`는 자기 `:List`를 실체화하면서
`rawAdd`만 부른다.

**그럼 그 `rawAdd`가 부기를 건드리지 않는다는 보장은 어디서 오는가** — 그
Slot이 아직 `_mounted == false`이기 때문이다. 이 상태의 `rawAdd`는
"`_elements`에만 넣고 끝"이라 `setLength`/`setOffsetSource`/`recompute`를
아예 안 부르므로, **게이팅할 대상 자체가 없다.** 초기 population이 만든
요소들의 부기는 그 직후 `materializeSlotTree`의 `_elements` 등록 루프가
(이번엔 Blocker를 켜고) 한꺼번에 처리한다.

**⚠️ 다만 확인 중에 실제 갭을 하나 찾았다 — 그 보장을 담은 `rawAdd` 의사코드가
문서에 없다.** `rawRemove`/`rawUnmount`/`rawDetach`/`releaseElement`는 전부
코드 블록이 있는데 **가장 많이 참조되는 `rawAdd`만 정의가 없고**, `_mounted`
분기는 다른 함수의 주석에만 흩어져 있다. 아래 `C-1`에서 초안을 제안한다.

### B-4. `DC-11` — 배치 끝 `recompute`가 왜 필요한가

**추측하신 대로 `Length` 때문이 맞다.** 정리하면:

- **offset은 이미 채워져 있다** — `setOffsetSource`의 즉시 계산이 등록 시점마다
  `1..i-1` 길이 합을 넣어두고, 그것들은 `i`보다 먼저 등록되므로 항상 정확하다.
  그래서 이 마지막 `recompute`는 offset에 대해선 `Get() ~= sum` 가드에 걸려
  대부분 아무것도 안 쓴다.
- **실제 역할은 (a) `ownerKey`가 Slot이면 `ownerKey.Length`(= 기여도 합) 확정,
  (b) 등록된 뒤에 값이 바뀐 길이가 있으면 그 뒤 형제 offset 교정.**
- `ownerKey`가 물리 `inst`인 `Dispatch.drive` 경로에선 (a)가 없어 사실상
  검증 패스지만, `Set`이 거의 없는 O(N) 순회라 분기해서 빼지 않고 그냥 항상
  부른다. **문서에 이대로 반영했다**(A-11).

### B-5. `+` — `state<Slot>` → `Slot:Single { Slot }`에서 부모가 Length를 따라가는가

**따라간다.** 한 단계씩 트레이싱하면:

1. `Slot:Add(state)`가 래퍼 `sub = Slot(); sub:Single(state)`를 만들어
   부모 `_elements[i]`에 넣는다.
2. 부모의 `materializeSlotTree` 루프가 `isSlot(sub)`을 보고 재귀 →
   `sub`가 자기 실체화를 끝내고 **마지막에
   `Dispatch.setLength(parent, i, sub.Length)`** 를 부른다. 여기서 넘기는 건
   **값이 아니라 `Source` 객체 자신**이라, 부모는 그 객체를 구독해둔다.
3. 나중에 state가 다른 Slot을 emit하면 `sub`의 reconcile이 교체를 수행하고,
   그 안에서 `recompute(sub, bk)`가 `sub.Length`를 새 합으로 `Set`한다.
4. 부모가 2번에서 걸어둔 Observer가 그 `Set`을 받아 `gatedRecompute(parent)` →
   부모 `recompute`가 자기 `Length`와 뒤 형제 offset을 갱신한다.

**한 가지 캐비엇**: 3번에서 교체는 `rawUnmount`(→ `spliceArraysDown` +
`recompute`) **다음** `rawAdd`(→ 등록 + `recompute`) 순서라, `sub.Length`가
**잠깐 줄었다가 다시 늘어난다.** 부모 쪽 `recompute`도 그만큼 두 번 돈다.
크래시나 오작동은 아니고(그 사이에 프레임 경계가 없다 — yield 금지 계약),
뒤 형제 offset이 두 번 계산되는 낭비다. `:Single`처럼 항상 0/1개인 경우엔
`Detach`/재마운트 경로가 아니라면 피하기 어렵다 — **지금은 그대로 두는 게
맞다고 보는데, 아니면 알려주시라**(교체를 "먼저 넣고 나중에 빼는" 순서로
바꾸면 없앨 수 있으나 `C-7`("빼기는 물리 먼저")과 부딪힌다).

### B-6. `+` — 조상이 죽을 때 안에 있던 요소도 같이 죽는 것

**언급이 없었다 — 이번에 신설했다**(A-6). 요지는 문서에 이렇게 적었다:
`Owned = false`가 약속하는 건 **"quad가 안 죽인다"뿐**이지 "무슨 일이 있어도
살아남는다"가 아니고, 언마운트가 조상 파괴보다 **먼저** 일어난 요소만
살아남는다. 그래서 조상이 이미 죽은 뒤에 `state:Get()`으로 꺼낸 값은 **이미
죽은 Instance**이고, 재마운트를 시도하면 `bindLifetime`/`canExecute` 게이트에
걸린다. `_detached`는 이미 `Parent = nil`이라 이 경우에 해당하지 않는다(그쪽
정리는 `_detachCleanup`).

### B-7. `SS-2`/`SS-3` — 에포크 제안에 대한 답

**"선제 최적화가 아니라 확정 동작으로의 승격"이라는 판단에 동의한다.**
길어서 `research/state-epoch-validation.md`로 뺐고(D절), 요지만:

- **지목하신 glitch는 실재한다.** 지금 `base/source-state-plan.md`의 다이아몬드
  절은 "중복 재계산이 없다"만 말하는데, 그 논증은 *`Get()`이 전파 파동이 끝난
  뒤에 온다*고 암묵 가정한다 — Observer가 전파 도중 발화한다는 사실과 겹치면
  그 가정이 깨진다. **문서 어디에도 이 현상이 서술돼 있지 않다.**
- **제안한 방식이 고치는 것**: 섞인 값(정확성)과 중복 재계산. 아직 신호를 못
  받은 가지도 `Get()` 때 자기 `sourceList`의 카운트 불일치를 보고 스스로
  재계산하므로, `Get()`이 "지금 이 순간의 일관된 값"을 준다는 보장이 **처음으로**
  성립한다.
- **안 고쳐지는 것**: 중복 **통지**. Observer는 여전히 두 번 운다(값은 두 번 다
  옳다). "에포크를 넣으면 다이아몬드가 완전히 해결된다"고 적으면 틀린 서술이 된다.
- **선례가 있다** — 값이 아니라 **버전/에포크를 비교해 lazy하게 검증**하는 건
  MobX·Adapton류가 쓰는 표준 기법이고, quad가 이미 택한 pull 모델과 결이 같다
  (Fusion식 eager 위상정렬의 대안).
- **비용 추산에 동의**한다(`rawInvalid`가 false면 훑지도 않으므로 흔한 경로는
  지금과 같은 비용).
- **⭐ 채택한다면 같이 못 박아야 하는 것 하나** — `sourceList`는 `:With`/trailing
  deps로 **선언된** 상류에서만 합성되므로, `:Compute` 콜백이 클로저로 잡은
  **선언 안 한 Source**를 `Get()`하면 에포크 비교가 못 잡는다. 지금도 stale이지만
  새 모델은 "`Get`은 항상 일관"이라는 **더 강한 약속**을 하므로, 그 예외를
  UB로 명문화해야 한다.

**`Get`이 최신을 준다는 말이 무력화되는 것 아니냐**는 우려에 대해선 방향이
반대라고 본다 — **지금 모델이 그 약속을 못 지키고 있었고**, 이 제안이 지키게
만든다.

---

## C. 사용자 판단 필요 — 임의로 처리하지 않은 것

### C-1. ⭐ `rawAdd` 의사코드가 문서에 없다 — 초안 승인 요청 (`AS-5`에서 발견)

`rawAdd`는 이 문서에서 가장 많이 참조되는 함수인데 **정의 블록이 없고**,
`_mounted` 분기·부기 순서·nested 재귀가 전부 다른 함수의 주석에 흩어져 있다.
`AS-5`의 보장("게이트 없이 `recompute`가 돌 일이 없다")이 정확히 그 분기에
달려 있으므로 명시적으로 적어두는 게 맞다고 본다. 초안:

```lua
-- [초안, 5라운드 C-1] 기존 서술을 모은 것 — 새 결정은 없음.
function rawAdd(self, element, index, fromDetached)
    claimOwner(element, self, fromDetached)   -- 이미 누가 갖고 있으면 error(detach 재마운트만 예외)
    index = index or (#self._elements + 1)
    table.insert(self._elements, index, element)

    if not self._mounted then
        return index      -- 아직 마운트 전: 부기도 물리도 없음. attachSlot이 나중에 통째로 처리
    end

    local bk = getBookkeeping(self)
    spliceArraysUp(self, index)               -- _elements 외 배열들을 한 칸씩 밀고 bk.N 증가

    if isSlot(element) then
        -- 자식 Slot은 자기 부기를 자기가 등록한다(setOffsetSource → setLength 순서 포함)
        attachSlot(element, self._mountedInst, self, index)
    else
        Dispatch.setOffsetSource(self, index, None)   -- 순서: 항상 offsetSource 먼저(C4)
        Dispatch.setLength(self, index, 1)
        recompute(self, bk)                            -- 부기 완결(C7: 물리보다 먼저)
        element.Parent = self._mountedInst             -- 그 다음에야 물리 마운트
    end
    return index
end
```

**확인이 필요한 지점 둘**:
1. **`element.Parent` 대입이 `attachSlot` 쪽 분기엔 없다** — 자식이 Slot이면
   `mountSlotTree`가 대신 해주기 때문. 맞나?
2. **`recompute` 호출 위치** — plain 요소는 위처럼 `setLength` 직후 1회면
   충분하지만, Slot 자식은 `attachSlot`(정확히는 그 안의 `materializeSlotTree`)이
   자기 끝에서 `setLength(self, index, ...)`를 부르고 그게 `gatedRecompute`를
   태우므로 여기서 또 부를 필요가 없다고 봤다. 맞나?

### C-2. ⭐⭐ `DC-19` — `rawAdd`가 `Length`를 직접 `Set`하는 서술이 지금 계약과 충돌한다

말씀하신 "목적이 다르지 않나"를 파고들다 더 큰 걸 찾았다.
`dispatch-core-plan.md`는 두 자리에서 **`rawAdd`가 `self.Length:Set(newCount)`를
부른다**고 적어두는데:

1. **`newCount`(개수)는 이제 `Length`의 정의가 아니다** — `Length`는
   "요소별 기여도의 합"(plain=1, nested Slot=그 `.Length`)으로 바뀌었다.
   개수로 `Set`하면 중첩이 있는 순간 틀린 값이 된다.
2. **쓰는 주체가 둘이 된다** — `recompute`가 이미
   `ownerKey.Length:Set(sum)`으로 확정 기록을 한다. 같은 Source에 두 곳이
   쓰면 어느 쪽이 진실인지가 갈린다.
3. 지적하신 "가드가 필요한가"도 여기서 답이 나온다 — `rawAdd` 자리에서는
   카운트가 **항상** 달라지므로 `Get() ~= sum` 가드가 아무것도 안 걸러서
   실제로 무의미하다(가드가 값을 하는 건 `recompute`의 전체 순회 쪽뿐).

**제안**: `rawAdd`에서 `Length:Set`를 **빼고**, `Length`는 `recompute`만 쓴다
(위 `C-1` 초안이 그렇게 돼 있다). "부기가 물리보다 먼저"(C-7)는 `recompute`가
`Parent` 대입 앞에 오는 것으로 그대로 지켜진다. **이대로 정정할까?**

### C-3. ⭐⭐ `DE-17` — `updateFn`이 State를 반환할 때의 래핑/`prev` 규칙이 지금 문서엔 없다

말씀하신 *"updateFn 이 state 를 던져도 싱글 slot화 된다"*를 확인하러 갔더니
**지금 문서는 그렇게 안 돼 있다**:

- State → nested Slot 래핑은 **공개 `Slot:Add`에만** 있다
  (`if isState(element) then sub = Slot(); sub:Single(element); element = sub end`).
- 그런데 `:List`의 reconcile은 공개 `Add`가 아니라 **`rawAdd`를 직접** 부른다
  (가드/에러 체크가 중복이라 의도적으로 그렇게 확정돼 있다).
- 그래서 지금 문서대로면 **`updateFn`이 State를 반환하면 래핑 없이 `_elements`에
  raw State가 들어간다** — 요소 타입 제약 위반.

그리고 래핑을 하기로 하면 **`prev` identity 문제가 따라온다.** 말씀하신
*"prev 는 이전에 던진 그대로"* + *"이전과 같은 state 를 던지면 멱등으로써
새로운 slot 을 만들지 않고 그대로 두는것"*을 둘 다 만족시키려면, `settle`의
`result == prev` 비교가 **래퍼가 아니라 사용자가 반환한 값**을 봐야 한다.

**선택지**:

1. **(권고) 래핑을 `rawAdd`로 내리고, `:List`는 "반환값"과 "물리 요소"를 따로
   기억한다.** `mounted[key]`엔 사용자가 반환한 값(raw State)을 넣고, 래퍼 Slot은
   `wrappers[key]`(또는 `mounted[key] = {returned, element}`)에 둔다.
   `rawMove`/`rawDetach`/`releaseElement`는 래퍼에, `prev`/멱등 비교는 반환값에
   적용. → 사용자가 원하는 의미론 그대로, 대신 `:List` 내부 상태가 하나 는다.
2. **래핑을 `settle`에서 한다** — 효과는 (1)과 같고 `rawAdd`는 안 건드린다.
   대신 `Slot:Add`와 `:List` 두 곳에 같은 래핑 코드가 생긴다.
3. **`:List`의 `updateFn`이 State를 반환하는 걸 금지(error)** — 사용자가 직접
   `Slot():Single(state)`을 만들어 반환하게 한다. 가장 단순하지만 말씀하신
   방향과 반대다.

**부수 확인**: 그 래퍼의 `:Single` 설치가 `Owned = false`가 되는 것
(*"owned = false 가 되는건 이 싱글 슬롯 안 1번째 객체에 대해서 적용"*)은
맞다고 보고, 래퍼 Slot **자신**은 quad가 만든 것이라 부모가 파괴할 수 있다
(`destroySlotTree(wrapper)` → `_owned == false`라 안쪽은 언마운트만) —
이 조합도 확인 부탁드린다.

### C-4. ⭐⭐ `LC-3`/`LC-4` — `setLength`의 Observer를 Slot에 앵커하는 걸 되돌리자는 제안

지적이 맞다고 본다. 지금 확정(4라운드 `D-56`)은 *"`bindLifetime`의 첫 인자가
Slot일 수 있으니 백엔드가 그 경우를 핸들링하라 + `isBoundAlive`에 세 번째
분기를 둬라"*인데, 물으신 대로 **왜 Slot이 소유자여야 하는지**가 실제로는
근거가 약하다:

- `Dispatch.setLength(ownerKey, i, len)`이 만드는 Observer는 `ownerKey`가
  **부기 키**라는 이유로 `bindLifetime(ownerKey, observer)`를 부르고 있는데,
  **부기 키와 생명주기 앵커는 별개 개념**이다.
- 실제로 그 Observer가 살아야 하는 기간은 "이 Slot이 그 물리 트리에 마운트돼
  있는 동안"이고, 그건 **`physicalTarget`이 정확히 표현한다.** Slot 자신의
  생존은 부모의 `_elements` 강참조가 이미 보장한다(말씀하신 그대로).
- 그리고 `setLength`가 불리는 모든 자리에서 **물리 target을 이미 알고 있다** —
  `Dispatch.drive`(=`inst`), `materializeSlotTree`(=`physicalTarget`), 런타임
  단건 `rawAdd`(=`self._mountedInst`).

**제안**: `setLength`가 **부기 키(`ownerKey`)와 앵커(`physicalTarget`)를 따로
받게** 하고, `bindLifetime`은 **항상 물리 Instance만** 받는다.

- `base/lifecycle-pattern.md`의 `(1-1)` 절(첫 인자가 Instance가 아닐 수 있다는
  백엔드 요구사항)이 **통째로 불필요**해진다.
- `isBoundAlive`의 **세 번째 분기도 필요 없어진다**(지금 ⚠️ 미정으로 열려 있는 것).
- 포탈(언마운트→재마운트)에서도 앵커가 자연히 새 target으로 옮겨간다 —
  `unmountSlotTree`가 `bk.observers`를 `unbindLifetime`하고 재마운트 시
  `materializeSlotTree`가 다시 등록하는 지금 흐름 그대로.
- `getBlocker(slot)`/`getBookkeeping(slot)`은 그대로 Slot을 `Relate` 키로
  쓴다(그건 weak 키일 뿐 생명주기 앵커가 아니라 문제없다).

**이 방향으로 `D-56`을 되돌릴까?** 되돌린다면 `base/lifecycle-pattern.md`,
`base/dispatch-core-plan.md`(`setLength` 시그니처), `base/slot-plan.md`를 같이
고쳐야 한다.

### C-5. `Gate` — 이름과 표면 (`CR-3`/`DT-4`)

`research/gate-primitive.md`로 정리했고(D절), 결정이 필요한 건 넷:
**(a) 이름**(권고: `Gate` 그대로 — `blocker`/`modifier`와 달리 `gate`는 이미
행위자가 아니라 **장치**를 가리키는 명사라 `-er`가 필요 없다. 대안:
`Valve`/`Relay`), **(b) `:Apply` 팩토리인지 독립 생성자인지**, **(c) `Blocker`가
그 위에 어떻게 얹히는지**(공유 외부 객체라 모양이 다름), **(d) M2에 `Gate`만
넣을지 `Blocker`까지 넣을지**.

### C-6. `+` — `Effect`가 여러 의존성(특히 `Ref`)을 직접 받는 안

제안하신 방향(`:With`로 합치지 말고 `Effect(fn, ...)`가 여러 요소를 각각
Observe/Callback하고, 최초 발화는 `Blocker`의 다른 사용법으로 억제)은
**타당해 보이고, 지금 실제로 갭이 맞다** — `Ref`는 State가 아니라
(`:Callback`만 있고 emit이 없다) `:With`로 합칠 수가 없어서 **오늘은 Effect의
의존성이 될 방법이 아예 없다.**

정하고 갈 것들:
1. **`fn`이 받는 인자 모양** — `:Compute(fn, ...deps)`가 이미
   `fn(self, previous?, ...deps)`로 **trailing deps를 lazy 핸들로 위치 인자화**
   하는 선례가 있으니 그대로 따르는 게 맞아 보인다(새 규칙 없음).
2. **`Ref` 의존성의 발화 시점** — Ref는 "한 번 채워지는" 값이라 State처럼
   반복 emit이 없다. 채워질 때 1회 발화 + 이후 재설정 시 발화(Ref는 반복
   재설정 가능)로 보면 되나?
3. **최초 1회 실행** — 지금 `Effect`는 설치 시 1회 실행이 계약인데, 의존성이
   여럿이면 "아직 안 채워진 Ref"가 있는 채로 도는 게 정상인가(=`nil`을 보고
   각자 판단), 아니면 전부 채워질 때까지 미루나? 제안하신 Blocker 억제는
   전자에 가깝게 들린다.
4. **leaf dedup/cascade와의 관계** — 의존성이 N개면 내부 Observer도 N개라,
   `EffectHandle`의 bind/unbind cascade가 전부를 덮어야 한다(`EF-5`와 같은 함정).

**방향에 동의하시면 `research/`에 문서를 하나 만들어 위 넷을 정리하겠다** —
지금은 이 항목만 남기고 아무것도 안 만들었다.

### C-7. `B-5`의 캐비엇 — `:Single` 교체 시 Length가 잠깐 줄었다 느는 것

위 B-5 마지막 문단. 낭비만 있고 오작동은 아니라 **그대로 두는 쪽**을 권하는데,
확인 부탁드린다.

---

## D. 새로 만든 research 문서 둘

| 문서 | 무엇 | 왜 base가 아니라 research인가 |
|---|---|---|
| `research/gate-primitive.md` | `Blocker`/`Debounce`/`Throttle` 아래의 공용 게이트 노드. 사용자 스케치(2단 `setup(emit) -> onUpstreamEmit`), `DT-4`의 "Blocker+Observer로는 순서를 못 지킨다" 논거, 열린 질문 6개 | **방향은 확정, 표면·이름이 미정** — M2 착수 전에 닫아야 함 |
| `research/state-epoch-validation.md` | 소스 에포크 비교로 재계산을 판정하는 안. 문제(glitch) 재현 시나리오, 제안 정리, 에이전트 분석(고쳐지는 것/안 고쳐지는 것/선례), 비용, 열린 질문 6개, 권고 | **아무것도 확정 안 함** — `base/source-state-plan.md`가 여전히 정본, M3 전에 결론 필요 |

---

## E. 회신 방법

- **B절** — "이 이해가 맞나"만 봐주시면 된다. 어긋나는 지점만 알려주시면
  base까지 같이 고친다.
- **C절** — `C-2`(`rawAdd`의 `Length:Set` 제거), `C-3`(State 반환 래핑/`prev`),
  `C-4`(`setLength` 앵커 되돌리기)가 **파급이 가장 크고 나머지를 막는다.**
  `C-1`은 초안 승인, `C-5`/`C-6`은 방향 확인.
- 언급 안 하신 문항은 전부 "예"로 간주하고 넘어간다.


---

# F. 2차 회신 처리 (2026-08-21) — C절 전량 확정, `Gate`만 다음 세션으로

**입력**: `B-5`/`B-7`/`C-1`~`C-7`에 대한 사용자 회신(원문은
`-response.md`에 이어붙이지 않고 이 절에 인용). **`C-5`(`Gate`)를 뺀 전부가
확정됐고 `base/`에 반영 완료.**

## F-1. 반영 완료

| 항목 | 회신 | 반영 |
|---|---|---|
| `B-5` | *"차라리, replace 를 제공하는게 나아보임. 해당 요소 자리에 교체분을 넣고, 이전건 파기해주는 것."* | **`Slot:Replace(index, newElement)` 공개 CRUD 신설**(O(1), `Extract`의 파괴 짝) + **`rawReplace` 의사코드 신설**. `:List`의 `settle` 교체 분기가 `releaseElement`+`rawAdd`(시프트 2회·`recompute` 2회)에서 **`rawReplace` 하나**(시프트 0)로 바뀜 — `C-7`의 "Length가 잠깐 줄었다 느는 것"도 이걸로 사라진다 |
| `B-7` (1) | *"중복 통지는 … 이미 모든 소스가 최신이면 무시하는게 맞아보인다 … emit 은 자신 소스를 주게 되므로 자신 소스 카운트만 빠르게 비교가 쉽다"* | `state-epoch-validation.md`에 **중복 통지도 접는다**로 반영. 판정이 O(1)이라는 것, **2026-08-14에 폐기된 옛 dedup과 다른 장치**라는 것(영구 침묵 모드가 없는 이유), 그리고 **노드가 `seen`/`computedAt` 두 카운트를 따로 들어야 한다**는 구현 요구까지 |
| `B-7` (2) | *"그건 아니다 … 상류의 상태를 물어보므로 … 이전과 다른게 없다"* | 에이전트가 붙였던 "선언 안 된 의존성을 UB로 명문화" 조건 **철회**, 같은 문서 §5·§7에 기각 사유와 함께 기록 |
| `C-1` | 확인 + *"element.Parent … 는 실제 엔진이 구현하게 되는 crud 셋을 사용하게 되어야 … slot 의 해당 동작은 base 이므로 parent 를 모른다"* | **`rawAdd` 의사코드 확정 반영** + **"물리 조작은 주입 op다" 절 신설** — 이 문서 의사코드 전체의 `element.Parent = ...`/`element:Destroy()`를 `mountInst`/`unmountInst`/`disposeInst` 호출로 정정(9곳) |
| `C-2` | *"확인. recompute 가 length 를 잘 처리해놓고 나서 빈 공간에 들어가므로 해당 동작은 완결하다"* | `dispatch-core-plan.md`의 **`rawAdd`가 `Length:Set(newCount)`를 부른다는 서술 2곳 전면 정정** — `Length`는 이제 `recompute`만 쓴다(개수 ≠ 기여도 합 / 이중 기록 방지 / 그 자리 가드는 무의미) |
| `C-3` | *"권고를 따르고자 한다 … 래핑이 하나의 함수로 나와야한다 … IndexOf 와 Get 등은 래핑 전 객체를 주어야"* | **"래핑/언래핑은 Slot 전체에 걸린 연산" 절 신설** — `wrapElement`/`unwrapElement` 비공개 헬퍼 한 쌍, 래퍼에 `_wrapped` 역참조(언래핑 O(1)), `_elements`는 물리 요소·사용자에게 나가는 값은 전부 언래핑, `IndexOf`도 언래핑 기준. **예상하신 대로 `wrappers[key]`/`mounted[key]` 분리가 불필요해졌다** |
| `C-4` | *"제안에 동의한다"* | **`Dispatch.setLength(ownerKey, i, len, anchor)`로 시그니처 변경** — 부기 키와 생명주기 앵커 분리. `bindLifetime`은 다시 물리 Instance 전용이 되고, `lifecycle-pattern.md`의 `(1-1)` 절은 **`archive/bindlifetime-slot-owner-reversed.md`로 이전**(포인터만 남김). **`isBoundAlive`의 세 번째 분기 항목도 같이 닫힘** |
| `C-6` | *"최소 1회 실행이 맞음 useEffect 와 동일. 인자 모양도 동의하고, 의존성 발화도 set 될때만임 … 전부 동의"* | `effect-plan.md`에 **`Effect(fn, ...deps)` 절 신설**(확정) — `Ref`도 의존성이 될 수 있음, trailing lazy 위치 인자, 최소 1회 실행, `Ref`는 `Set`될 때만 발화, cascade/dedup이 N개 Observer 전부를 덮어야 함. 최초 1회 억제 장치만 `Gate`에 딸려 있어 ⚠️로 표시 |
| `C-7` | *"위 응답에서 해소되었다 생각함"* | `B-5`의 `rawReplace`로 해소 — 별도 조치 없음 |

## F-2. 다음 세션으로 넘긴 것 — `Gate` 하나

**회신**: *"고칠것이 많으므로 Gate 는 다음 세션에 다루겠음. 해당 부분은 정정이
아니고 추가이고, 새 인터페이스를 고민해야하므로 해결해야할 일로 남겨두길 바람.
단지 지금 세션 상 지식만 이전될 수 있게 두세요."*

→ `research/gate-primitive.md` 상단에 그 지시를 명시하고 **"다음 세션이 바로
이어받을 수 있게 재료만 모아둔 상태"**로 표시했다. `question.md` 3번과
`todos.md`에도 **M2 착수를 막는 유일한 항목**으로 남겼다. 이 세션에서
`Gate`에 대해 새로 정한 건 없다.

## F-3. 이번 처리로 파생된 것 (확인 부탁)

1. **`mountInst`/`unmountInst`는 가칭이다** — `disposeInst` 선례를 따라 붙였고,
   `base/dispatch-core-plan.md`의 주입 op 목록에 정식 등록할 때 이름을 확정해야
   한다(`slot-plan.md`의 그 절에 ⚠️로 표시해둠). `mountInst`에 **index를 안
   넘기는** 것도 같이 확정된 셈인데(형제 순서는 `Offset` 부기가 담당), 이건
   맞다고 보고 그렇게 적었다.
2. **`rawReplace`가 `indexOfRaw(self, oldElement)`로 자리를 찾는다** — 지금
   `raw*`가 index 기준과 element 기준으로 섞여 있는 알려진 불일치
   (`slot-plan.md`의 "raw* 내부 호출 규약" 캐비엇)를 그대로 따랐다. M6 구현 때
   둘 중 하나로 통일할 것.
3. **공개 `Replace`는 항상 파괴, `:List` 경로만 `_owned`를 본다** —
   `rawReplace(self, old, new, destroyOld)`의 4번째 인자로 갈린다. `_listed`
   Slot은 공개 CRUD가 막혀 있어 두 경로가 섞이지 않는다.


---

# G. 3차 — `mountInst`의 삽입 위치 (그리고 그 과정에 발견한 중첩 offset 결함)

**입력**: *"mountInst/unmountInst 가 인덱스를 안 받는다는 문제가 있을수도.
웹에서는 어떻게 되냐가 모호함. 어디 둘지 어떻게 아느냐는것. 문제는
`Dispatch.setOffsetSource(self, index, None)` 가 실제 오프셋을 안 주는데, 그냥
None 이면 number 로 넘겨주는게 어떻겠냐는 생각."*

**결론부터: 지적이 맞고, 제안 방향도 맞다. 그리고 그 자리를 파다 별개 결함을
하나 더 찾았다.** 아직 `base/`를 고치지 않았고(⚠️ 마커만 달아둠), 아래 셋에
대한 판단을 받고 싶다.

## G-1. 지금 뭐가 문제인가 — `None`이 두 뜻을 겸하고 있다

`base/dispatch-core-plan.md`는 `setOffsetSource`의 `None`을 **"실제 마운트를
하지 않는 위치"**로 정의하고, **"`setLength`도 같은 위치엔 짝을 맞춰 `0`으로
등록해야 한다(둘 중 하나만 반영되면 어긋남)"**는 규칙까지 못 박아뒀다.

그런데 **plain 요소는 `None` + `setLength(1)`로 등록된다**(`materializeSlotTree`의
등록 루프, 그리고 이번에 쓴 `rawAdd`/`rawReplace`). 즉 **마운트는 하는데
`None`을 쓰는** 자리라 위 규칙과 정면으로 어긋나 있었고, 아무도 못 보고
있었다. 실제로 `None`이 뜻하는 건 두 가지가 섞여 있다:

1. **아무것도 안 차지한다**(`Ref` 자리, `nil`/`None` 값) — 길이 `0`.
2. **차지는 하는데 아무도 그 offset을 안 읽는다**(plain 요소) — 길이 `1`.

지적하신 문제는 정확히 2번에서 나온다 — **`None`이라 숫자가 계산조차 안 되니,
DOM 백엔드가 "이걸 어디에 넣어야 하나"를 물을 곳이 없다.**

## G-2. ⭐⭐ 파다가 나온 별개 결함 — 중첩 Slot의 offset이 부모 베이스를 못 받는다

`recompute`는 `local sum = 0`으로 시작하고, **`ownerKey.Offset`을 읽는 자리가
한 군데도 없다.** 그래서 각 offset은 **그 owner 안에서의 로컬 누적합**이다.
depth 1(물리 inst 바로 아래)에선 로컬 == 절대라 아무 문제가 없어서 지금까지
안 드러났는데, **depth 2부터 어긋난다**:

```
Frame {
    header,              -- 정적 1개
    Slot {               -- A
        plainX,
        Slot { :List 3개 },   -- B
    },
}
```

| 계산 | 값 | 맞는 값 |
|---|---|---|
| `recompute(Frame)`: `A.Offset` | `1`(header 기여) | 1 ✓ |
| `recompute(A)`: `B.Offset` | **`1`**(plainX 기여만) | **`2`**(= `A.Offset` 1 + plainX 1) |
| B의 `updateFn`이 쓰는 `index + offset` | 2,3,4 | 3,4,5 |

즉 **`A.Offset`만큼 통째로 밀려 있다.** `updateFn`에 넘기는 `offset`을
"형제로 섞인 다른 Slot/정적 자식이 기여한 개수의 누적합"이라고 서술해온 것과도
안 맞는다(그 서술은 절대값을 뜻한다).

이게 지금 질문과 한 덩어리인 이유: **DOM에 넘길 삽입 위치는 절대값이어야
하므로, 숫자를 주기로 하면 이 결함부터 고쳐야 한다.**

## G-3. 제안 (셋 다 같이 가야 함)

### P1 — `sourceList`의 의미를 "참여 여부"에서 "발행 채널"로 좁힌다

`recompute`가 **모든 position에 대해 숫자를 계산해 `bk.offsetList[i]`에
기록**하고, `sourceList[i]`에 Source가 있을 때만 거기에 `:Set`한다.

- **참여 여부는 이미 `lengthList[i]`가 표현한다**(0이면 아무것도 안 차지).
  그래서 `None`은 이제 **"발행 채널 없음"** 하나만 뜻하게 되고, plain 요소가
  `None` + `setLength(1)`을 등록하던 모순이 그대로 해소된다.
- **`None` ↔ `setLength(0)` 페어링 규칙은 "값이 없는 자리"에만 남는다** —
  그건 여전히 유효하지만, 이유가 "짝을 맞춰야 어긋나지 않아서"가 아니라
  그냥 그 자리가 정말 0개를 기여해서다.
- 비용은 배열 하나에 숫자 쓰기뿐이고, Source가 없는 자리엔 다운스트림
  캐스케이드가 없으니 `Get()` 가드도 필요 없다.
- **⚠️ `bk.offsetList`는 네 번째 병렬 배열이 되므로 `spliceArraysUp`/
  `spliceArraysDown`이 같이 밀고 당겨야 한다**(그 목록에 빠진 게 있어서
  3라운드에 이미 한 번 물린 적 있음 — `bk.observers`).

### P2 — `mountInst(target, element, index)`

`index`는 **그 자리의 절대 offset(0-based)**. Roblox 백엔드는 그냥 무시하고,
DOM류는 그 숫자로 삽입 위치를 정한다. `unmountInst(element)`는 그대로 인자
없음(뺄 때는 자기 자신만 알면 된다).

- 부수 효과로 `slot-plan.md`의 **"위치 이전 기억은 base 책임 아님 — backend가
  필요하면 `Relate`로"** 절이 완화된다: 백엔드가 "직전 형제가 누구였는지"를
  따로 기억할 필요 없이 **base가 숫자를 준다.** (그 절의 결론 자체는 유지 —
  base는 여전히 백엔드 종속 위치 정보를 안 들고 있다.)

### P3 — `recompute`가 절대값을 계산하도록 베이스를 넣는다 (G-2 수정)

```lua
local function recompute(ownerKey, bk)
    local base = if isSlot(ownerKey) then ownerKey.Offset:Get() else 0
    local sum = 0
    for i = 1, bk.N do
        bk.offsetList[i] = base + sum                 -- P1: 항상 숫자로 기록
        local src = bk.sourceList[i]
        if src ~= None and src:Get() ~= base + sum then
            src:Set(base + sum)                      -- 발행 채널이 있을 때만
        end
        sum += contribution(i)
    end
    if isSlot(ownerKey) then ownerKey.Length:Set(sum) end   -- Length는 base를 안 더한 로컬 합
end
```

- **`Length`에는 `base`를 안 더한다** — 길이는 "내가 몇 개를 차지하나"라
  위치와 무관하다. 이 둘이 갈리는 게 `base`를 별도 변수로 두는 이유.
- **추가로 구독 하나가 필요하다** — 중첩 Slot은 **자기 `Offset`이 바뀌면 자기
  `recompute`를 다시 돌려야** 한다(앞 형제의 길이가 변해 베이스가 밀리는 경우).
  `materializeSlotTree`에서 `slot.Offset`에 Observer 하나를 걸고
  `gatedRecompute(slot)`을 연결, 앵커는 `physicalTarget`(`C-4` 규칙 그대로).
- **순환은 안 생긴다** — offset은 top-down, length는 bottom-up으로 방향이
  갈린다. offset 변경이 자식 offset을 밀 뿐 길이를 바꾸지 않고, 길이 변경이
  부모 recompute를 태울 뿐 자기 offset을 안 바꾼다.

## G-4. 판단이 필요한 것

1. **P1~P3을 이대로 반영할까?**(셋이 한 덩어리다 — P2만 하면 숫자가 틀리고,
   P3만 하면 plain 요소 숫자가 여전히 없다.)
2. **`mountInst`의 `index`를 0-based 절대 offset으로 두는 게 맞나** —
   `offset`/`sum`이 이미 "0-based 개수"라 그쪽과는 일관된다. 1-based로 주면
   `updateFn`의 `index`(1-based 지역 위치)와 헷갈릴 수 있어 0-based를 권한다.
3. **`bk.offsetList`를 새로 두는 대신 `sourceList`가 `Source | number`를
   담게 하는 안**도 가능하다(사용자 표현에 더 가까움). 다만 그러면 "이 자리에
   발행 채널이 있나"와 "지금 값이 얼마인가"가 한 슬롯에 섞이고, 등록 시점에
   `None`이던 자리가 계산 후 숫자로 덮이면 **등록 정보가 사라진다**(해제 시
   `None` 재등록으로 판정하는 지금 계약과 충돌). 그래서 **배열을 하나 더 두는
   쪽을 권한다.**


---

# H. 4차 — `getOffsetAt`으로 확정 (G절 결론, `base/` 반영 완료)

**입력**: *"isSlot 인지 아닌지와 상관 없이 부모에서의 Offset 을 알아야하는거
아님? … 아. 구독 이유는 알겠음, 자식 slot 의 offset 을 다시 설정해주기
위함이구나. offset의 깊은 전파를 위한거군. 단순 그러고선 setOffsetSource(None)
은 그냥 리턴해버리고, getOffsetAt 같은걸 넣어서 length 추적을 그냥 뽑아놓자.
setOffsetSource 에선 source 를 받으면 그건 set 해주지만, 아니면 그냥 얼리리턴에
None 으로만 둬주고, getOffsetAt 은 직접 호출하는걸로?"*

**에이전트 제안(G-3의 P1)보다 이쪽이 낫다** — 채택하고 반영했다.

## H-1. 무엇이 바뀌었나

| | 에이전트 제안(P1) | **채택된 것(사용자안)** |
|---|---|---|
| 숫자를 어떻게 얻나 | `recompute`가 **모든 자리에 push**해 `bk.offsetList[i]`에 기록 | **`Dispatch.getOffsetAt(ownerKey, i)`로 pull** |
| 병렬 배열 | 네 번째(`offsetList`) 신설 → `spliceArraysUp/Down`이 같이 밀어야 함 | **안 늘어남** |
| `setOffsetSource(None)` | 등록만 하고 계산은 recompute가 | **얼리 리턴**(계산할 이유 자체가 없음) |

**pull이 나은 이유 세 가지**(반영하며 확인):

1. **부기 배열이 안 는다** — 3라운드에 `spliceArraysDown`이 밀어야 할 배열
   목록에서 `bk.observers`가 빠져 있던 게 실제 결함이었는데, 배열을 하나 더
   만들면 그 실수 표면이 또 넓어진다.
2. **"관측해야 실체화된다"와 같은 결** — 아무도 안 물어보는 자리의 숫자를
   미리 계산해 들고 있을 이유가 없다.
3. **중복이 사라진다** — `setOffsetSource`의 즉시 계산이 하던 합산 루프가
   그대로 `getOffsetAt`이 되어, 두 곳에 있던 같은 로직이 한 곳으로 합쳐졌다.

## H-2. 베이스는 어디서 오나 — `slot.Offset` 그대로 (`bk.base`는 폐기)

**1차 반영 때 `bk.base` 필드에 복사해뒀다가, 같은 세션에 사용자 지적으로
걷어냈다**: *"bk.base 가 왜 필요한거임? … 이건 slot 안의 slot.offset 이랑 기능이
겹칠텐데, 부모 slot 의 offset 읽는게 이미 정확해. 미리 offset을 받아 설정해두니까.
최상위에선 애초에 base자체가 없지 않아? 항상 0 일텐데."* 맞다 —

- **Slot의 베이스 = 자기 `.Offset`**이고, 그 값은 **부모가 먼저 설정해준다**
  (`materializeSlotTree`의 첫 줄이 `setOffsetSource(ownerKey, position, ...)`).
  즉 이미 정확한 값이 있는데 `bk.base`는 그걸 한 번 더 들고 있는 **중복
  상태**였다 — 같은 값을 두 곳에 두면 갈라진다는, 이 코퍼스가 반복해서 물린
  패턴 그대로다.
- **최상위(물리 inst)는 베이스라는 개념 자체가 없어 항상 0.**

```lua
local base = if isSlot(ownerKey) then ownerKey.Offset:Get() else 0
```

- **`isSlot` 분기가 남는 건 타입 분기여서가 아니라 다른 방법이 없어서다** —
  `ownerKey.Offset`을 그냥 인덱싱해 있나 보는 duck-typing은 **Roblox userdata에서
  정의 안 된 키 인덱싱이 에러를 던질 수 있어** 코퍼스가 이미 금지한 방식이다
  (`base/brand-plan.md`의 duck-typing 기각 근거 (b)).
- `Length`에는 베이스를 안 더한다(길이는 위치와 무관) — 그래서 `base`와 `sum`이
  별도 변수로 남는다.

## H-3. 깊은 전파 — 자기 `Offset` 관측 (짚으신 그대로)

앞 형제의 길이가 변해 내 베이스가 밀리면 **내 자식들의 offset도 다시 계산돼야
한다.** 그래서 중첩 Slot은 자기 `Offset`에 Observer 하나를 걸고
`recompute(self)`를 태운다. `_listObserver`/`_detachCleanup`과 **완전히 같은
취급**으로 뒀다 — 생성 1회, 언마운트 시 앵커만 해제, 재마운트 시 새
`physicalTarget`에 재앵커, 파괴 시 핸들까지 `nil`.

## H-4. ⭐ 반영하다 발견한 결함 하나 더 — 재마운트가 `Offset` Source를 새로 만들고 있었다

`materializeSlotTree`가 `local offsetSource = Source(0)`으로 **매 마운트마다 새
Source를 만들어** `slot.Offset`에 넣고 있었다. 그런데 언마운트 쪽은
`slot.Offset`을 **일부러 보존**한다(`SL-75`) — 그 이유가 *"이미 렌더된 요소들이
그 Source를 구독한 채 함께 딸려 나가기 때문"*(`DC-6`에서 사용자가 정밀화)인데,
재마운트가 객체를 갈아치우면 **그 구독자들이 옛 객체에 남아 새 위치를 영원히
못 받는다.** 포탈이 정확히 그 지점에서 깨진다.

→ `local offsetSource = slot.Offset or Source(0)`으로 **identity 재사용**하도록
정정했다. `SL-75`/`DC-6`이 세운 불변식("`Offset`은 객체를 유지하고 값만
갱신한다")이 이제 마운트/언마운트 양쪽에서 일관된다.

## H-5. 반영 목록

| 대상 | 내용 |
|---|---|
| `dispatch-core-plan.md` | `Dispatch.getOffsetAt(ownerKey, i)` 신설, `recompute`에 `bk.base` 시드(+`Length`는 base 제외), `setOffsetSource`의 `None` 얼리 리턴, `None` 의미를 "발행 채널 없음"으로 정정(plain 요소가 `None`+`setLength(1)`인 게 정상임을 명시) |
| `slot-plan.md` | `materializeSlotTree`의 `Offset` identity 재사용 + `_baseObserver`(생성 1회/재앵커/파괴 시 정리), `mountSlotTree`가 러닝 누적으로 `mountInst(target, element, acc)` 호출(O(n)), `rawAdd`/`rawReplace`는 `getOffsetAt`으로 위치 전달, `mountInst` 절을 확정으로 갱신(0-based 절대 offset, `unmountInst`는 인자 없음) |
| `question.md` | G절 항목을 **해소**로 갱신 |

## H-6. 남은 확인 (작음)

- **`getOffsetAt`은 O(i)**라 배치에서 자리마다 부르면 O(N²)다. 그래서
  `mountSlotTree`는 러닝 누적으로 O(n)을 유지하고, 단건 경로(`rawAdd`/
  `rawReplace`)만 직접 부른다. 이 구분이 맞다고 보고 그렇게 적었다.
- **`getOffsetAt`이 공개 표면인지** — 지금은 `Dispatch.*`로 뒀다(백엔드가
  자기 핸들러에서 부를 수 있어야 하므로). 비공개로 두고 싶으면 알려주시라.


---

# I. 반영 후 자체 트레이싱 (2026-08-21, 커밋 전)

H절 반영을 커밋하기 전에 새 의사코드를 손으로 실행해보다 **실제로 터지는 경로
둘**을 찾아 같이 고쳤다.

## I-1. ⭐ 빈 Slot이 `recompute`에서 크래시 (`bk.N`이 `nil`)

`bk.N`은 `setLength`가 처음 불릴 때 생긴다(`bk.N = math.max(bk.N or 0, i)`).
그래서 **요소가 하나도 없는 Slot**(`Slot()` 직후, 데이터가 빈 `:List`,
전부 필터로 걸러진 리스트)은 `N`이 `nil`인 채로 `materializeSlotTree` 끝의
`recompute(slot, bk)`에 도달하고, `for i = 1, nil`이 그 자리에서 터진다.

**이건 이번 변경이 만든 게 아니라 원래 있던 갭**이다(`recompute`의 루프 상한이
처음부터 `bk.N`이었음). 빈 Slot은 완전히 정상적인 상태라 방어가 아니라 계약으로
보고 `for i = 1, bk.N or 0`으로 고쳤다.

## I-2. ⭐ `_baseObserver`의 "등록 즉시 1회 실행"이 미완성 부기를 훑음

G절에서 신설한 `_baseObserver`(자기 `Offset`을 관측해 자식 offset을 다시 미는
구독)를 처음엔 `blocker:On()` **앞**에 만들었는데, Observer는 **등록 즉시 1회
실행**되므로 그 자리에서 곧바로 `recompute(slot, ...)`이 돈다 — **자식 등록이
하나도 안 된 상태**를 훑는다(위 `I-1`과 겹치면 그대로 크래시).

→ **생성을 `blocker:On()` 뒤로 옮겼다.** 게이트 안에서 만들면 그 1회가 그냥
삼켜지고, 배치 끝의 명시적 `recompute`가 어차피 정확한 값을 계산한다. 재마운트
분기(앵커만 다시 거는 쪽)는 Observer를 새로 안 만드니 이 문제가 없다.

**패턴 메모**: "등록 즉시 1회 실행"이 배치 게이팅과 부딪히는 건
`setLength`의 Observer에서 이미 한 번 정리된 적이 있다(`gatedRecompute`가 그
1회도 게이트에 통과시킨다는 규칙) — **새로 만드는 Observer는 그 규칙을 자동으로
물려받지 않으므로, 배치 구간에서 Observer를 만들 때마다 "이 1회가 게이트를
지나는가"를 확인해야 한다.**


## I-3. `setLength`의 `anchor`를 선택 인자로 (핸드오버 정리 중 보강)

`C-4`로 신설한 4번째 인자를 "항상 넘긴다"로 적어뒀는데, 그러면 `inst`를 owner로
쓰는 **기존 3-인자 호출부가 전부 stale**해진다(`ref-plan.md`의
`ProcessedPreRefHandler`/`ProcessedPostRefHandler`, `modifier-plan.md`의
`ProcessedModifierHandler`, `lifecycle-hooks-plan.md`, `component-composition-plan.md`
등). 그런데 그 자리들은 **`ownerKey`가 곧 물리 target**이라 앵커를 따로 줄 이유가
없다.

→ **`anchor`를 생략하면 `ownerKey`로 폴백**하도록 정리했다. 실제로 넘겨야 하는
건 **`ownerKey`가 Slot인 자리**(`materializeSlotTree`의 등록 루프, 런타임
`rawAdd`/`rawReplace`)뿐이고, 나머지 문서의 호출 예시는 손댈 필요가 없다.


---

# J. 커밋 전 감사 (2026-08-21) — `quad-doc-auditor` 1라운드

핸드오버 준비로 감사를 돌렸다(각도: **이번 diff와 그걸 인용하는 자리의 base
정합성**). **실제 결함 6건 + 판단 필요 2건**이 나와 전부 처리했다.

## J-1. 실제 결함 (전부 반영 완료)

| # | 발견 | 왜 문제였나 | 반영 |
|---|---|---|---|
| 1 | **`Owned`가 코드에 도달하지 못하고 있었다** | `settle`/`destroySlotTree`/`releaseElement`가 `self._owned`를 9곳 넘게 읽는데, 정작 `Slot:List`/`Slot:Single` 의사코드가 **`opts` 인자를 안 받고** `_owned`를 세우는 줄이 없었다. `wrapElement`도 산문은 "`Owned = false`로 설치된다"면서 코드는 `sub:Single(v)`뿐 | `Slot:List(data, updateFn, keyFn, opts)` / `Slot:Single(state, updateFn, opts)`로 시그니처 보강 + `opts.Owned == false`일 때만 필드 세팅, `wrapElement`는 `sub:Single(v, nil, { Owned = false })` |
| 2 | **`effect-plan.md`가 자기 자신과 모순** | 문서 최상단 시그니처가 `Effect(fn, state?)`이고 "**`Effect(fn, a, b, c)`처럼 trailing args로 받는 sugar는 의도적으로 안 만듦**"이라는 확정 문단이 그대로 남은 채, 같은 파일 아래에 `C-6`의 `Effect(fn, ...deps)` 절이 추가돼 있었다 — **역전 배너 없이 정반대 두 서술이 공존** | 시그니처를 `Effect(fn, ...deps)`로 갱신, 옛 문단에 🔄 역전 배너 + **옛 근거가 무너진 이유 둘**(`Ref`는 `:With`로 합칠 수 없어 애초에 의존성이 될 방법이 없었다 / 구독을 따로 걸면 합치는 노드 자체가 안 생겨 "감출 비용"이 없다) |
| 3 | **`indexOfRaw`가 어디에도 정의돼 있지 않음** | 신설 `rawReplace`가 쓰는데 문서에 없었다. 구현자가 공개 `IndexOf`를 그대로 쓰면 **래핑된 자리에서 어긋난다**(그건 언래핑 기준 비교) | `indexOfRaw` 한 줄 정의 + `IndexOf`와의 차이 명시 |
| 4 | **index/element 혼용 캐비엇 목록이 안 늘어남** | 기존 캐비엇이 `rawRemove`/`rawUnmount`만 나열하는데, 이번에 같은 불일치를 물려받은 `rawDetach`/`releaseElement`/`rawReplace`가 빠져 있었다 | 캐비엇에 셋 추가 |
| 5 | **`mountSlotTree`의 전제가 코드에 없었다** | `acc = slot.Offset:Get()`이 정확하려면 **`materializeSlotTree`가 먼저 돌아야** 하는데, 분해된 함수의 계약이 주석에 없었다(`research/slot-attach-decomposition.md`에 "중간 상태 처리"가 열린 항목이라 더 위험) | ⚠️ 전제 주석 추가 |
| 6 | **`Replace`의 `destroyOld`가 base 본문에 없었다** | `rawReplace`에 인자가 있는데 CRUD 표/산문이 그 존재를 설명 안 함. followup은 처리 기록이지 소스가 아니다(이번 라운드 `CR-1`의 교훈 그대로) | 공개 `Replace`는 항상 파괴 / `:List`만 `_owned`를 넘긴다를 산문에 명시 |

부수로 인덱스도 같이 정리했다 — **`Gate` 이름이 `question.md` 1번(용어
대기열)에 없던 것**(5라운드 `CR-2`가 지적한 패턴이 같은 라운드에서 재발),
`todos.md` 00번 헤더의 "열린 항목 없음"(5라운드/`Gate`와 모순),
`architecture.md`/`dispatch-core-plan.md`의 주입 op 목록에 `mountInst`/`unmountInst`
가칭 표시, `setLength` narrative 스텁의 `anchor?`/`getOffsetAt` 반영,
`research/gate-primitive.md`에 **소비자 `Effect(fn, ...deps)`** 추가.

## J-2. 판단 필요 — `question.md` 3번에 올림

1. **offset이 바뀌면 이미 배치된 물리 노드를 옮겨야 하는가**(웹 백엔드 계약).
   `mountInst`가 삽입 시점 위치만 받는 일회성이라, 앞 형제 길이가 변해 뒤
   형제 offset이 밀리는 흔한 경우 DOM에선 순서가 실제로 어긋난다. quad-web이
   생길 때까지 미룰 수는 있지만 **지금 안 정하면 M6가 "안 옮긴다"를 전제로
   굳는다.**
2. **`:List` 재조정의 `getOffsetAt` 비용** — `settle`이 키마다 부르므로 이미
   마운트된 리스트가 통째로 바뀌면 O(N²)(최초 마운트는 `_mounted == false`
   얼리 리턴이 막아준다). `DC-9`의 "배치 1회니 감수"와 달리 **매 reconcile**이라
   빈도가 다르다. reconcile이 `pos`처럼 절대 offset도 러닝 누적으로 들면 O(n)
   — `mountSlotTree`가 이미 그 방식이다.

## J-3. 감사가 확인만 하고 넘어간 것 (회귀 없음)

`Tween:Mapped` 표기 통일 / `bk.base` 제거(남은 건 "왜 안 두는지" 서술뿐) /
`D-56` 역전 4곳 정합(포인터·archive 원문·README 색인·question 해소) /
`KeyGone` 의사코드↔산문 / `Owned=false`+`Detach` 3곳 / 물리 op 치환 9곳
(`element.Parent`/`:Destroy()` 잔존 0) / 5라운드 파일 3개 색인.


---

# K. 감사 2라운드 + 그 자리에서 받은 회신 (2026-08-21)

## K-1. 감사 2라운드(각도: 인덱스 레이어·히스토리 문서) — 전부 반영

| 발견 | 반영 |
|---|---|
| **`ROADMAP.md` 백로그 문단과 `debounce-throttle-plan.md`가 아직 "Gate 추출은 M3에서"라고 서술** — 이번 세션에 M2로 앞당겨졌는데, **손대지 않은 문서라 diff에 안 잡히는 사각지대** | 두 곳 다 "M2로 앞당겨졌다"로 정정 |
| `question.md`/`README.md`의 State-에포크 서술이 **옛 결론**(중복 통지 안 고쳐짐 / UB 명문화 필요)을 담고 있었음 — 같은 날 후속으로 정반대로 확정됐는데 인덱스만 안 따라옴 | 둘 다 갱신(중복 통지도 접음 / UB 조항 기각 / `seen`·`computedAt` 두 카운트) |
| `README.md`가 5라운드 문항지를 "회신 대기"로 태그한 채 바로 옆에 회신·처리 파일을 등재 | "신설·처리 완료"로 |
| 5라운드 문항지 자신의 상태 줄이 "회신 대기"에 멈춰 있음(4라운드는 종결로 갱신한 선례 있음) | "완료·종결" + followup 포인터 |
| `ROADMAP.md` M2 체크박스의 문장이 접합부에서 깨져 있었음 | 문장 정리 |
| M3의 `Blocker.luau` 체크박스에 "게이트 노드는 M2에 이미 있다"는 표시가 없음 | M3에 순서 주의 항목 + **State 에포크 미결이 `Source.luau`/`State.luau`보다 먼저 닫혀야 한다**는 착수 전 확인 항목 신설 |
| `slot-plan.md`의 주입 op 표가 `mountInst(target, element)` 2-인자로 남음(바로 아래 문단은 3-인자로 확정) | 표를 3-인자로 |
| `todos.md`가 처리 상태를 `1차 처리 완료`로 적어 실제(4차까지 진행)와 갈림 | 라운드 수를 빼고 `처리 완료`로 |

## K-2. 같은 자리에서 받은 회신 — 셋 다 확정

### (1) `raw*`는 **index로 전부 통일** (오래 열려 있던 캐비엇 종결)

**사용자 확정**: *"index 로 전부 처리되면 될듯. 애초에 안에서 다시 element ->
index 를 찾아야하던걸로 앎."*

- `rawRemove`/`rawUnmount`/`rawDetach`/`rawMove`/`rawSwap`/`rawExtract`/
  `rawSplice`/**`rawReplace`** 전부 index를 받는다. 예외는 `rawAdd` 하나
  (새로 넣는 대상이라 element가 인자인 게 당연).
- `settle`이 element만 쥐고 있어 index를 구해야 하는 문제는 — **`keyIndex`가
  이미 그 값을 들고 있다**(그 키가 지금 차지한 압축 위치 = `_elements` 인덱스).
  그래서 `indexOfRaw`(O(n))는 **폴백이지 기본 경로가 아니다.**
- `releaseElement(self, index, element, wasDetached)`로 시그니처 조정
  (detach 중이던 요소만 자리가 없어 `index = nil`).
- **M6 구현 세부로 열어뒀던 항목이 이걸로 닫혔다.**

### (2) 래핑은 `raw*` **바깥**에서 (`raw*`는 물리 요소만)

**사용자 확인**: *"raw들은 모두 래핑된거 그대로 넣고 빼도록 할까?"* — 그렇다.
래핑 지점은 **공개 표면 + `settle`** 둘뿐이고, `raw*`의 세계는 물리 요소 하나로
균일하다. 그래야 방금 통일한 index 규약이 다시 흐려지지 않는다.

### (3) `B-1` 해소 / `B-2` 해소

- **`B-1`(offset이 바뀌면 이미 놓인 노드를 옮겨야 하나) → 아니오.**
  *"위에서 넣고 빼면 insert 같은거로 일어나서 뒤로 밀린다"* — DOM은 삽입/삭제
  자체가 뒤를 밀고 당긴다. 단 **백엔드 op이 아토믹한 최소 단위**여야 한다는 게
  같이 확인된 요구사항.
- **`B-2`(`getOffsetAt` O(N²)) → 접두합 캐시로.** `bk.offsetCache` +
  **`bk.invalidAfter`**("여기까지는 유효"). **[같은 자리에서 사용자가 의사코드로
  정정]** 함수를 둘로 나누지 않고 **단일 `getOffsetAt`이 필요한 만큼만 이어붙인다**
  — 순차 호출이면 한 칸씩 늘어나 전체 O(N)이고, `recompute`도 그 위에 얹힌다.
  무효화 규칙도 하나로 줄었다: `invalidAfter = min(invalidAfter, i)`
  (`setLength`도 splice도 **자기 인덱스까지**만 당긴다 — `i` 자리의 offset은
  `1..i-1`의 합이라 안 바뀌므로. 베이스 변경만 `0`).


---

# L. `native*` 물리 조작 계층 확정 (2026-08-21, 대화 마지막 라운드)

`mountInst`/`unmountInst`/`disposeInst` 셋으로는 **`Move`/`Swap`을 아예 표현할
수 없다**는 지적에서 시작해, 물리 조작 계층 전체가 재설계됐다.

## L-1. 층위 정의 (사용자)

> **`raw*`는 그 Slot 스코프 안의 연산**(평탄화 전, `_elements` 인덱스),
> **`native*`는 확정된 offset/length로 표현되는 물리 트리 연산**(평탄화 후, 절대 좌표).

## L-2. 확정된 표면

```lua
nativeInsert (target, offset, elements)                          -- 삽입(자신이 밀어냄)
nativeExtract(target, offset, elements, newElements?)            -- 빼되 살림 (+교체 삽입)
nativeRemove (target, offset, elements, newElements?)            -- 빼면서 파괴 (+교체 삽입)
nativeMove   (target, fromOffset, elements, toOffset)
nativeSwap   (target, offsetA, elementsA, offsetB, elementsB)
nativeDispose(element)                                           -- 트리 밖 값 파괴
```

정해진 것들:

- **`Replace`는 별도 op이 아니다** — `newElements`가 있는 `Remove`/`Extract`.
  `Splice`도 이 둘로 표현된다(사용자: *"count 만큼 공간을 축소 newElements
  길이만큼 공간을 확장할 수 있게 한번에 처리. 안 그러면 splice 가 무거워짐"*).
- **파괴/비파괴를 불리언이 아니라 이름으로 가른다** — 공개 CRUD의
  `Remove`↔`Extract` 어휘를 물려받고, **백엔드 융합**을 연다(Roblox에서
  `Parent = nil` 후 `Destroy()`가 그냥 `Destroy()`보다 비싸다는 사용자 지적).
- **⭐ 빠지는 요소는 반드시 배열로 넘긴다** — 에이전트가 "count면 충분하지
  않나"는 질문에 답하다 확인: `(target, offset, count)`로 대상을 찾을 수 있는 건
  **DOM뿐**(`childNodes[offset]`)이고, **Roblox는 자식이 순서 없는 집합**이라
  offset으로 인스턴스를 역으로 못 찾는다.
- **`nativeSwap`은 별도** — `Move`는 사이를 전부 밀지만 `Swap`은 가운데를 고정한
  채 양끝만 교환이라 다른 연산(사용자 지적).
- **`nativeInsert`는 흡수하지 않는다** — 최빈 경로가 "0개를 빼는 extract"가 되는
  모양을 피하고 일괄 삽입 최적화를 그 안에 숨기지 않기 위해.
- **미주입이면 에러가 아니라 조합 폴백** — `addTag` 계열과 갈리는 지점.
- **⚠️ 전제**: 한 Slot의 물리 자식은 부모 안에서 **연속 구간**을 차지한다(범위
  op이 성립하는 근거 전부).

## L-3. ⭐ 그 결과 `C-7` 일반 계약이 역전됐다

*"부기가 물리보다 항상 먼저"*는 **"`Length`를 먼저 올려 밀어내고 그 공간에
넣는다"**는 그림 위에 서 있었는데, **base에는 물리적으로 자리를 비워둘 수단이
없다**(사용자: *"밀어내고 null을 넣어둘 수도 없는데, nativeInsert 라는것 자체가
밀어내기 동작을 강제"*). 미는 주체는 언제나 백엔드의 삽입 연산 자신이다.

**새 계약** — 순서 규칙이 "두 얼굴"에서 하나로 줄었다:

> **자기 자리를 정하는 것(`setOffsetSource`)은 먼저 / 뒤를 미는 것
> (`setLength` → `recompute`)은 나중.**

`setOffsetSource`가 먼저여야 하는 이유는 그 자리의 offset이 `1..i-1`의 합이라
**자기 삽입으로 안 변하고**, 삽입 위치 계산과 `activateList`(C1)가 그 값을 쓰기
때문이다. 그래서 `rawAdd`는 `spliceArraysUp` → `setOffsetSource` →
`nativeInsert` → `setLength` → `recompute`.

**배치 경로(`materializeSlotTree` → `mountSlotTree`)는 그대로 부기 전량이
먼저** — 그건 C6가 요구하는 별개 사안이고 새 규칙과 모순되지 않는다.

역전 원문은 `archive/bookkeeping-before-physical-reversed.md`.

## L-4. 반영 파일

`slot-plan.md`(op 절 전면 재작성, `rawAdd`/`rawReplace`/`rawRemove`/`rawUnmount`/
`rawDetach`/`mountSlotTree`/`unmountSlotTree` 의사코드), `dispatch-core-plan.md`
(C-7 재정의 + 주입 op 목록), `architecture.md`(`EngineOps.luau`), `ROADMAP.md`(M5
주입 표면), `archive/`(역전 원문), `README.md` 색인.

---

# M절 — State 에포크 안: 사용자 3차 정정 (2026-08-21)

`research/state-epoch-validation.md`를 사용자가 직접 읽고 **기제 서술의
오류 세 건**을 정정했다. **채택 여부 자체는 여전히 미정**이지만, 채택하면
어떤 모양이 되는지는 이제 거의 확정형이다. 반영은 그 문서(§2가 소스) +
`README.md`/`question.md`/`ROADMAP.md` 인덱스.

| # | 문서가 적고 있던 것 | 사용자 정정 |
|---|---|---|
| M-1 | `sourceList` 순회는 **`rawInvalid == true`일 때만** 돈다 | **반대.** `rawInvalid == false`일 때만 돈다. `true`면 이미 재계산이 확정이라 훑을 이유가 없고, 순회의 목적은 오직 **"못 받은 emit을 여기서 먼저 받는 것"**이다 |
| M-2 | `emit`은 `(source, count)`를 실어 보낸다 | **source만** 보내면 된다 — 받는 쪽이 `source`의 count 필드를 그냥 읽는다 |
| M-3 | 노드가 `seen`(전파 dedup)/`computedAt`(캐시 검증) **두 카운트**를 따로 들어야 한다 | **철회.** count 갱신과 `rawInvalid = true`가 **같은 스텝**에서 일어나므로 "전파 때 갱신된 count가 캐시를 신선한 것으로 오인시키는" 실패 모드가 없다. 캐시 유효성은 `rawInvalid`가 들고 count는 "이 에포크를 봤는가"만 답한다 — *"그냥 지금 순수 count 와 source 를 ref해두는 구현은 문제가 없어보인다"* |

**emit 수신 규약(확정형)**: `sourceList[source] == source.count`면 삼키고,
다르면 **count를 먼저 갱신** → `rawInvalid = true` → **그 다음** 뒤로 emit.
다른 소스 항목은 건드리지 않는다(그 소스는 자기가 직접 emit 하므로).

**부수로 열린 채 남은 것 — 순회로 발견한 변경을 뒤로 emit 할 것인가.**
사용자가 `A → {B, C} → D` 다이아몬드로 (b) 즉시 emit의 위험을 의심했다가
**스스로 안전하다고 정정**했다(*"D조차도 count를 업데이트 하기 때문에 중복을
무시한다"*). **[2026-08-21 기준]** 그래서 걸리는 곳은 게이트 하나 — 앞에서 막아둔 emit이 뒤의 `Get()`이 촉발한
순회로 새어나갈 수 있으므로 **block이 풀린 뒤의 emit까지 기다려야** 하고,
게이트 해제 emit은 여러 소스가 섞여 있어 **`source = nil`을 싣고 받는 쪽이
전체를 확인**하는 규약이 필요하다. 다만 사용자 판단은 *"중간에 blocker 낀건
이전에도 있던 문제다. 이미 최종장에 쓰는게 일반적이므로 의미 없어보인다"* —
**채택을 막는 요소가 아니고**, `nil` 규약만 `Gate` 설계와 같이 확정하면 된다.
