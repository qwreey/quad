# 재디스패치 = 하강 diff — `retractFrom` 선행 폐기, 핸들러 비교를 클로저 호출 앞에 (설계안)

**상태**: research — 2026-08-13 여섯 번째 세션에 사용자가 제기하고 방향을
제시, 같은 세션 후속 라운드에서 모델이 거의 확정됨. **`base/` 반영 전
남은 열린 항목은 아래 5절의 하나뿐**(Attribute 이름 소유권). 그 하나만
정해지면 `bind-system-plan.md`/`tag-plan.md`/`slot-plan.md`/
`attribute-plan.md`를 한 번에 옮기면 됨.

> **문서 이력**: 최초엔 `dispatch-hint-to-oldvalue-plan.md`라는 이름으로
> "힌트 대신 `oldValue`를 넘기자"는 보완안을 담고 있었으나, 사용자가
> **"이전 값인 oldValue는 처음부터 클로저라 이미 본인이 알지 않아요?"**
> 라고 지적해 그 보완안이 통째로 불필요함이 드러남(아래 3-2) — 파일명도
> 바꿈.

## 1. 현행 `hintValue`의 실제 결함 (사용자 지적, 확인됨)

현행 계약: `Dispatch.retractFrom(inst,k,index,v)`가 `index` 자리 retractor에
`v`를 넘김. 그 `v`는 **"그 자리에 곧 디스패치될 raw 값"**이다.

**문제: 그 raw 값이 핸들러가 이해하는 의미 값이라는 보장이 전혀 없음.**

### 1-1. 힌트로 `None` 센티널이 그대로 넘어감 (사용자 제기, 재현됨)

`[AttributeKey "foo"] = state`, state가 `5` ↔ `None`을 오갈 때:

| 사이클 | 체인 |
|---|---|
| `None` | `StoreBind@1` → `NoneHandler@2` → `AttributeKeyHandler@3` |
| `5` | `StoreBind@1` → `AttributeKeyHandler@2` |

`5` → `None`으로 갈 때 StoreBind는 `retractFrom(inst,k,2,None)`을 부르고,
인덱스 2의 `AttributeKeyHandler` retractor가 **`hintValue = None`** 을 받음.
Attribute는 클로저가 no-op이라 무해하지만, `TagHandler`였다면
`isTag(None)`이 거짓이라 "이 자리가 Tag이길 그만둔다"로 오판해 이름 전부를
`RemoveTag`함.

### 1-2. 래핑이 한 겹만 끼어도 힌트가 무의미해짐

같은 이유로 힌트가 `State`, `Tween`, 그 외 미래에 추가될 어떤 래퍼여도
말단 핸들러는 그걸 해석 못 함. 앞서 문서화했던 "깊이 2 이상에선 `nil`"
문제는 이 결함의 **한 특수 케이스**였을 뿐 — 진짜 문제는 깊이가 아니라
**"힌트의 타입이 계약으로 정해져 있지 않다"**는 것.

### 1-3. 그래서 힌트 기반 최적화가 "가끔 조용히 꺼진다"

`Tag`의 `Contains` skip, `Ref`/`Slot`의 identity 비교는 전부 힌트가
자기 타입일 때만 동작 — 위 경로들에선 소리 없이 전량 정리로 퇴화함.
**정확성은 유지되지만(그래서 지금까지 안 드러남) 깜빡임/재생성 방지라는
존재 이유가 무너짐.** 특히 `Slot`은 "가드가 없으면 마운트된 서브트리
전체가 **[정정, 2026-08-13 4차 감사]** 언마운트됐다 재마운트"(작성 당시
아직 destroy 모델 — 파괴가 아니라는 것만 정정, 파급이 크다는 결론은 그대로)라
파급이 큼.

## 2. 채택 모델 — 재디스패치는 "철거 후 재구축"이 아니라 "하강 diff"

사용자 정리:

> "차라리 process 를 쭉 진행해, 이전거랑 자신 것이랑 다르면 nil 또는,
> 그걸 나타내는 HandlerChanged 등의 무언가로 아래를 전부 죽이고, 같으면
> 값을 계속 넣어가며 전파해야할듯, 같은것이면 본인 인덱스에 대해서만
> 후처리를 해."
>
> "retract 계약이 지금 보면, 일단 시도해보는데, 이전이 내 핸들러면 내가
> 처리, 아니고 다르면 아래쪽을 그냥 retract 처리해서 전부 제거"

즉 **래핑 핸들러가 재-dispatch 전에 `retractFrom`을 먼저 때리는 것을
폐기**하고, 그냥 `Dispatch.process`를 아래로 내려보냄. 비교는
`Dispatch.process` 안에서 일어남:

```lua
-- chains[inst][k][index] = { handler = h, retractor = fn }
function Dispatch.process(inst, k, v, index)
    local list = <확보 + chains에 등록>   -- 기존 순서 규칙 그대로(h.process 前)
    local slot = list[index]
    local h = Dispatch.getHandler(inst, k, v)   -- 매치 실패는 기존대로 즉시 error

    if slot ~= nil and slot.handler == h then
        -- 같은 핸들러: 아래를 안 건드리고, 이 자리 클로저에 새 값을 넘겨
        -- 스스로 전이를 처리하게 함. v는 h.isHandlable(v)가 참임이 보장됨.
        slot.retractor(v)
        slot.retractor = h.process(inst, k, v, index)
    else
        -- 다른 핸들러(또는 빈 자리): 이 자리부터 아래를 전부 철거 후 새로 설치
        Dispatch.retractFrom(inst, k, index, nil)
        list[index] = { handler = h, retractor = h.process(inst, k, v, index) }
    end
end
```

`StoreBind`/`NoneHandler`는 이제 그냥:

```lua
Dispatch.process(inst, k, realv, index + 1)   -- retractFrom 선행 호출 없음
```

### 2-1. 이걸로 동시에 풀리는 것들

- **힌트의 타입이 보장됨** — 클로저에 값이 넘어가는 건 **오직 핸들러가
  같을 때뿐**이고, "같다"는 건 `getHandler(inst,k,v) == slot.handler`
  로 판정한 것이므로 `v`는 정의상 그 핸들러의 `isHandlable`을 만족함.
  1-1/1-2의 `None`/래퍼 오염이 **구조적으로 불가능**해짐. 지금의
  "`isX(hintValue)` 가드 필수" 일반 규칙 자체가 힌트의 타입 미보장을
  메우던 임시방편이었음이 드러남 — 그 규칙도 같이 없앨 수 있음.
- **깊은 체인의 힌트 유실도 사라짐** — 힌트를 위에서 아래로 전파하는 게
  아니라, **각 레벨이 자기 재프로세스에서 자기 힌트를 받음**.
  `State<State<Tag>>`에서 바깥이 새 inner State를 내놓아도: index 2는
  StoreBind끼리 같으니 자기 클로저가 구독을 갈아타고, 재위임으로 내려간
  index 3은 TagHandler끼리 같으니 **진짜 `Tag` 객체를 힌트로 받아**
  `Contains` skip이 정상 동작. (앞 라운드에 "구조상 불가피"라고 적었던
  건 틀렸음 — 철거 선행 모델에서만 불가피했던 것.)
- **`StoreBind` 구독 갈아타기 문제 없음**(사용자 지적: "다만 뭐가 문제인지
  모르겠어요") — "같은 핸들러면 **유지**"가 아니라 "같은 핸들러면 **자기
  클로저 → 자기 process**"라, 옛 구독 해제와 새 구독이 그 안에서 끝남.
  검토 중 제가 문제로 짚었던 것은 "유지"로 잘못 읽은 데서 나온 것.
- **최상위는 애초에 안 돌아감** — 값이 안 바뀌면 Observer가 안 뛰므로
  재프로세스 자체가 없음.

### 2-2. 두 종류의 retract가 계약상 갈림 (사용자 정리)

> "새 프로세싱으로 인한 retract처리와, 단순 retract는 다르다"

- **단순 retract**(언마운트/전체 철거, `retractFrom`): 뒤따르는 `process`가
  없음. 힌트는 항상 `nil`. 핸들러는 자기 기여를 무조건 전부 걷어냄.
- **재프로세싱**: 핸들러가 같으면 그 자리 클로저가 **새 값을 힌트로**
  받고, 다르면 그 자리부터 아래가 단순 retract 됨.

### 2-3. 전제 계약 — `inst` 부작용은 말단 핸들러만 (사용자 명시)

> "inst 에 실질적 처리를 가하는 동작은 항상 말단 핸들러 노드다"
> "중간 노드는 단순 언워랩만 한다"

**기존 핸들러 전부가 이미 만족함**(확인함):

| 핸들러 | 위치 | `inst` 부작용 |
|---|---|---|
| `StoreBind` | 중간 | 없음(구독 + 재위임만) |
| `NoneHandler` | 중간 | 없음(재위임만) |
| `PropertyHandler` | 말단 | 프로퍼티 세팅 |
| `TagHandler` | 말단 | `AddTag`/`RemoveTag` |
| `AttributeKeyHandler` | 말단 | `SetAttribute` |
| `SlotHandler` | 말단 | 마운트 |
| `RefLeafHandler` | 말단 | `Ref:Set` |
| `UICornerHandler` | 말단 | 자식 Instance 생성/제거 |
| `AttributeGroupHandler` | 자기 체인에선 말단 | 없음(다른 키로 위임) |

새 제약을 거는 게 아니라 **이미 성립하는 성질을 계약으로 승격**하는 것.

## 3. 검토 중 정리된 것

### 3-1. `HandlerChanged` 마커는 불필요

"핸들러가 바뀜"은 **그 자리 retractor가 `nil` 힌트로 불린다는 사실 자체**로
이미 표현됨. 별도 마커 값을 만들면 그것도 결국 "힌트로 넘어오는 정체불명의
값"이 되어 1-1과 같은 문제를 되풀이함.

### 3-2. `oldValue`를 넘기자는 보완안 — 철회(사용자 지적)

> "이전 값인 oldValue 는 처음부터 클로저라 이미 본인이 알지 않아요?"

맞음. 클로저는 자기 `process` 호출의 `v`를 upvalue로 캡처하고 있고,
힌트로 새 값을 받으므로 **old/new를 이미 둘 다 갖고 있음.** 문제였던 건
오직 힌트의 타입 보장이고, 그건 2-1의 핸들러 선비교로 해결됨 —
`chains`에 값을 따로 저장할 이유가 없음. (`chains`에 추가로 저장해야
하는 건 **비교용 `handler` 하나뿐**.)

### 3-3. 중간(재위임) 핸들러에 붙는 작은 계약

같은 핸들러로 재프로세스될 때, **재위임하는 핸들러는 반드시 다시
재위임해야 함.** 안 그러면 아래 인덱스가 고아로 남음(아무도 안 지움).
`StoreBind`/`NoneHandler`는 항상 재위임하므로 지금은 위반 사례가 없지만,
"조건부로만 재위임하는" 핸들러를 새로 만들면 그 자리에서
`Dispatch.retractFrom(inst,k,index+1,nil)`을 직접 불러 아래를 정리해야 함.

## 4. 부수 효과 — Slot의 "해제 짝"은 애초에 없어도 됨 (사용자 지적)

`base/slot-plan.md`가 "`attachSlot`이 등록한 `Dispatch.setLength`/
`setOffsetSource`에 대응하는 해제 짝이 없다"를 언마운트 전환의 실제
작업량으로 꼽았는데, **새 함수가 필요 없음**:

> "옛 오너가 setLength/setOffsetSource 를 그냥 실행해도 된다는 생각.
> retract에서 hint 를 보고 Slot이 아니면 그냥 setLength(...0...)
> setOffsetSource(...None...) 될 수 있어요."

이건 이미 확정된 관용구 그대로임 — `bind-system-plan.md`의 "실제 마운트를
하지 않는 위치는 `None`을 등록, `setLength`도 짝을 맞춰 `0`". 즉 **해제 =
0/`None`으로 재등록**이고, 별도 unregister API가 아예 필요 없음.

**`state<state<Frame>>`류로 offset이 밀리고 당겨지는 문제는 "그냥 확인된
것"으로 수용**(사용자 판단) — `state<state<Tag>>`와 같은 범주이고, 평탄화
도구(`research/operator-sugar-plan.md`)로 처리할 요소이며 실사용 케이스가
드묾. Dispatch에 별도 배관을 넣지 않음.

## 5. 남은 열린 항목 — Attribute 이름 소유권 (**하나뿐, 사용자 확인 필요**)

사용자 판단:

> "이 방식으로 가면, 자연히 Attribute 의 소유권 충돌은 처리되네요.
> 이미 처리된 인덱스에 대해 다시 프로세스 되는것 자체가 UB가 아니고,
> 오류 처리가 필요한 곳이면 직접 처리하면 되니까요."

**앞부분(재프로세스가 UB 아님)은 동의 — 뒷부분("자연히 처리됨")은
추적해보니 그렇지 않음.** 구체적으로:

그룹 A가 `Dispatch.process(inst, AttributeKey("foo"), sourceA, 1)`로
등록해둔 상태에서 그룹 B가 같은 이름에 `sourceB`로 들어오면:
인덱스 1의 현재 핸들러는 `StoreBind`이고 `sourceB`도 `StoreBind`에
매치되므로 **"같은 핸들러"로 판정되어 조용히 갈아탐.** 그리고 나중에
그룹 A의 클로저가 자기 이름들을 `retractFrom`할 때 **그룹 B의 바인딩을
대신 철거**함(교차 오염). 즉 예전 "조용한 last-write-wins"가 그대로
돌아옴 — 이번 감사에서 고쳤던 바로 그 증상.

**즉 "직접 처리하면 되니까"가 맞고, 그 '직접 처리'를 실제로 무엇으로
할지가 유일하게 남은 결정.** 후보:

- **(a) 이름별 claimant `Relate`를 Attribute 쪽에 둠** — 2026-08-13
  네 번째 세션에 `owners`라는 이름으로 만들었다가 기각됐던 그것.
  **당시 기각 사유는 지금은 해당 없음**: 그때 버그는 "소유권 반납이
  `process`의 `v==nil` 분기에만 있어서 그룹이 이름을 통째로 놓는 경로가
  그 분기를 안 타 옛 소유권이 안 지워짐"이었는데, 지금은 **클로저가 항상
  불리고 거기서 반납**하면 되므로 그 구멍이 구조적으로 없음. 실질 6줄
  정도.
- **(b) 감지 포기, 문서로만 금지** — 사용자 코드 실수이므로 UB로 두는 것.
  다만 증상이 "조용한 오작동 + 교차 오염"이라 다른 UB들(즉시
  스택오버플로/즉시 error)보다 훨씬 나쁨.
- **(c) `Dispatch`에 claimant 개념을 일반화** — 이번에 걷어낸 방향이라
  다시 넣는 건 반대.

**권고: (a).** 기각 사유가 새 모델에서 소멸했고, 소유권 판정을 필요로
하는 유일한 핸들러에만 국소적으로 두는 게 "Dispatch는 diff만 한다"는
이번 방향과도 맞음.

## 6. 반영 범위 (확정 시)

- `bind-system-plan.md` — `Dispatch.process` 의사코드, "Dispatch 체인" 절,
  "핸들러 계약"(힌트 타입 보장 추가, `isX(hintValue)` 가드 규칙 삭제),
  "Handler 작성 체크리스트" 3번 항목, `StoreBind` 예시(선행 `retractFrom`
  삭제), `NoneHandler` 예시, "hintValue는 직속 1단계에만" 항목 삭제.
- `tag-plan.md` — 힌트가 항상 `Tag`임이 보장되므로 `isTag(hintValue)`
  가드 삭제, 깊은 중첩 캐비엇 삭제.
- `slot-plan.md` — 4절대로 "해제 짝 필요" 서술 정정, 언마운트 경로에
  `setLength(0)`/`setOffsetSource(None)` 명시.
- `attribute-plan.md` — 5절 결정 반영, `process`/클로저 모양 재확정.
- **[2026-08-13 7차 감사에서 누락 발견 — 추가]** `architecture.md` —
  소스 트리의 `Dispatch/init.luau` 항목(`chains`/`retractFrom` 서술)과
  `Attribute.luau` 항목("`retractFrom`에 재귀 위임")이 현행 모델 전제로
  쓰여 있음. **이 파일도 최상단에 0-Z 배너를 달고 있는데 이 목록엔
  빠져 있었음** — 모든 세션이 "먼저 읽으라"고 지목하는 진입점이라
  누락되면 파급이 큼.
- **[같이 추가]** `ROADMAP.md` — M2/M4/M6/M10에 "0-Z 먼저 해소할 것"
  ⚠️ 배너가 달려 있고, 그 배너가 가리키는 체크리스트 항목들(특히
  M6의 "`SlotHandler.process`는 claim 실패 시에도 파괴적 클로저를
  반환해야 함")이 선행 `retractFrom` 전제로 쓰여 있음 — base 4개를
  옮길 때 같이 갱신하고 배너를 걷을 것.

**요약**: 배너를 달고 있는 파일 = 반영 대상. 위 6개(`bind-system-plan`/
`tag-plan`/`slot-plan`/`attribute-plan`/`architecture`/`ROADMAP`)가
전부이고, 반영이 끝나면 각 파일의 ⚠️ 배너도 같이 제거할 것.
