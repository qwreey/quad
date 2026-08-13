# Tag — array-part 값 객체, 참조 카운트는 base / 엔진 호출은 주입 op

> **✅ [2026-08-13 열네 번째 세션] 하강 diff 재디스패치 반영 + 패키지
> 재배치 완료.** 이전 ⚠️ 배너가 예고하던 교체가 끝났음: (1) 클로저가 받는
> 값의 **타입이 계약으로 보장**되어 `isTag(hintValue)` 방어 가드가
> 불필요해졌고 깜빡임 방지가 **깊은 체인에서도 유지**됨
> (`base/dispatch-core-plan.md` "Dispatch 체인" 절), (2) **참조 카운트
> 알고리즘 전체가 quad-base 소속**이 되고 `addTag`/`removeTag` op만
> 백엔드가 주입(아래 "패키지 배치" 절). 옛 모델 원문은
> `archive/dispatch-hintvalue-model-reversed.md`.

**상태**: base — 값 모양/이름은 확정. 2026-08-08 세 번째 세션에서 값
모양을 전면 재설계(구 모델은 `archive/tag-hash-key-model-reversed.md`에
원문·역전 이유 보존). 2026-08-12 열한 번째 세션에 `TagHandler`의
`process`/`retract` 메커니즘을 참조 카운트 기반으로 전면 정정(옛 버전은
`archive/retract-always-fires-reversed.md`). 2026-08-12 열다섯 번째
세션에 `Added`/`Removed`를 단일 이름에서 `string | {string}`으로
정정(아래 값 모양 절). **[2026-08-13 열네 번째 세션] 재디스패치 모델
(0-A)과 패키지 배치까지 반영 완료 — 이 문서에 남은 열린 질문은 이름
자체(용어 정리 대기열)뿐.**

## 왜 재설계됐나

구 모델(`[Tag "Name"] = boolean`, 태그 하나당 해시 파트 키 하나)은 상호
배타적인 스타일 상태(`btn1`/`btn2`/`btn3`류, 실사용에서 20개까지도 가능)를
표현하려면 태그 이름 개수만큼 키를 각각 갱신해야 해서 끔찍함, 스타일
조합(여러 태그를 합쳐 쓰는 것)도 구조적으로 안 됨 — 상세 경위는
`archive/tag-hash-key-model-reversed.md`.

## 값 모양 — `Modifier`와 같은 immutable clone 체이닝

```
Tag(name1, name2, ...)                  -- 생성자, 가변인자. Tag() 빈 값도 유효
tag:Added(name: string | {string}): Tag   -- clone 후 이름(들) 추가, 원본 안 건드림
tag:Removed(name: string | {string}): Tag -- clone 후 이름(들) 제거
tag:Contains(name): boolean -- 멤버십 확인
tag:Names(): iterator<string> -- 담고 있는 이름 순회(아래 "메커니즘" 절이 쓰는 것)
tag:Apply(factory): U        -- factory(self) 체이닝 설탕(Modifier와 동일 패턴)
Tag.Merged(tag1, tag2, ...): Tag  -- 여러 Tag의 합집합(무손실). Modifier의
                                     Overridden(필드 단위 덮어쓰기, 손실 있음)와
                                     다른 연산이라 이름도 다름 — Overridden은
                                     "이미 계산된 걸 합침", Merged는 "집합을
                                     합침"
```

`Added`/`Removed`가 `-ed` 어미인 이유는 **`Add`/`Remove`로 쓰면 뮤테이션
API처럼 보이기 때문** — 실제로는 항상 `table.clone` 후 반환(Modifier
3번 절과 동일한 immutable 확정 이유: 형제 서브트리 오염 방지).

**[정정, 2026-08-12 열다섯 번째 세션, 같은 세션 후속 재정정] `Added`/
`Removed`는 vararg가 아니라 `string | {string}` — 단일 이름 또는
이름 배열을 받고 내부에서 `type(v) == "table"`이면 순회(flatten)해서
처리.** 처음엔 이름 여러 개를 한 clone으로 처리하려고 vararg
(`Added(name, ...)`)로 정정했으나, 사용자가 실사용 패턴을 지적하며
재검토됨 — 단순히 "번거로움" 정도가 아니라 **Lua 문법상 실제로 못 하는
경우가 생김**: `table.unpack(t)`는 그 호출식이 인자 목록의 **맨 끝(tail)
위치일 때만** 여러 값으로 펼쳐지고, 그 뒤에 다른 인자가 오면(또는 다른
`table.unpack` 호출이 뒤따르면) 첫 값 하나로 잘림 — 그래서 조건절로 여러
개의 독립된 동적 이름 테이블을 만든 뒤(`namesA`, `namesB`, ...) 그걸 한
`Added` 호출로 합쳐 넘기는 건 vararg로는 애초에 표현이 안 됨(마지막
테이블만 완전히 펼쳐지고 나머지는 각각 첫 이름만 반영됨) — 결국 호출부가
먼저 테이블 하나로 합친 뒤 `table.unpack`을 딱 한 번만 쓰거나, 아예
테이블을 그대로 넘기게 해야 함. 반면 `string | {string}`은 그 테이블을
그대로 넘기면 끝(여러 동적 테이블도 `table.move`/`table.insert`로 먼저
합치기만 하면 그대로 통과) — 호출부가
단일 이름이든 이미 조립해둔 배열이든 분기 없이 통일해서 부를 수 있고,
구현도 `table.unpack` 없이 단순 `type(v) == "table"` 분기 후 `for`
순회만 있으면 됨. **부작용 걱정 없음** — 받는 값이 전부 이미 확정된
plain string이라(핸들러 계층 값처럼 identity/생명주기가 얽힌 값이
아님) 테이블로 감싸 넘기든 아니든 의미가 완전히 동일, 오버로드가
모호해질 여지가 없음. `Tag(name1, name2, ...)` 생성자는 그대로 vararg
유지(정적 리터럴 호출 자리라 동적 조립 문제가 없음) — 내부적으로
`{...}`로 한 번 패킹해 `self:Added(packed)`(단일 clone, 테이블 인자
경로 재사용)를 호출하는 것으로 구현.

**children 배열 슬롯(array-part)에 직접 놓임** — `Frame { Tag("selected") }`.
정적으로 여러 개 놓아도(`Frame { Tag("a"), Tag("b") }`) 각자 독립적으로
자기 태그만 추가하면 되므로 `Merged` 없이도 됨(`Merged`/`Added`/`Removed`는
"하나의 Tag 값을 프로그래밍적으로 조립"하는 용도).

**동적 토글은 `Source`/`State`로, `None` 불필요** — 상호배타 상태 전환은
`store.activeTag:Compute(function(name) return (if name:Get() == "btn1"
then Tag("selected") else nil) end)`처럼 그냥 `nil`을 리턴하면 됨. `None`
센티널은 "정적 테이블 리터럴에서 `키 = nil`이 키 없음과 구별 안 되는"
문제의 해법이지(`dispatch-core-plan.md` "`None` 센티널" 절), 이건 함수
리턴값이 동적으로 흘러가는 경우라 그 문제 자체가 없음 — `nil`을 인자로
넘기는 건 아무 문제 없음. (단, `Frame { (if cond then Tag("a") else
nil), sibling }`처럼 **정적 리터럴**에서 조건부로 Tag를 넣거나 빼고
싶은 경우엔 다른 array-part 값들과 마찬가지로 `(if cond then Tag("a")
else None)` 관용구가 여전히 유효 — 이건 nil-hole 문제라 Tag만의 특수
규칙이 아니라 `props.Modifier`/`props.Ref`와 같은 일반 array-part
관용구. **[2026-08-12 세션 후속]** 예전엔 `cond and Tag("a") or
nil`/`or None`(and/or 삼항)으로 적었으나, `Tag(...)`가 항상-truthy라
당장은 안전해도 `if-then-else` 전면 금지 규칙(`base/architecture.md`
"코드 스타일" 절)에 예외를 안 두기로 하며 여기도 통일.)

## 메커니즘 — `TagHandler`, `retract`가 이제 의미 있어짐

구 모델과 달리 **핸들러 타입이 사이클마다 바뀔 수 있음**(`Tag(...)` ↔
`nil`, 값이 `Tag`가 아니게 되면 `TagHandler.isHandlable`이 더 이상 안
맞음) — 그래서 `retract`가 실제로 필요해짐(`dispatch-core-plan.md` "확정된
디스패치 모델" 절의 일반 원칙 그대로).

**[전면 정정, 2026-08-12 열한 번째 세션] 아래는 이전 버전(단일 `relate`,
`assert(v==nil)`, "Tag(A)→Tag(B)는 retract 안 불림")을 대체함 — 그 버전은
두 가지를 놓쳤음:**

1. **반환하는 클로저는 store 재발행마다(핸들러 타입이 안 바뀌어도) 항상
   불림** — "Tag(A)→Tag(B)는 retract 안 불림"이라는 옛 서술은 틀렸음
   (`archive/retract-always-fires-reversed.md`). **[갱신, 2026-08-13
   열네 번째 세션]** 부르는 주체는 이제 `StoreBind`의 선행 `retractFrom`이
   아니라 `Dispatch.process` 자신임 — 같은 핸들러면 그 자리 클로저에 새
   값을 넘기고 곧바로 `process`를 다시 부름(`dispatch-core-plan.md`
   "Dispatch 체인" 절 (A) 분기). 호출 빈도는 그대로.
2. **서로 다른 배열 위치의 두 `Tag(...)`가 같은 이름을 겹쳐 가질 수
   있음**(`Frame { Tag("a"), Tag("a","b") }`류, 웹 `className="a a a"`와
   같은 합집합 시맨틱) — 한 위치의 diff만 보고 `RemoveTag`를 부르면 다른
   위치가 아직 그 이름을 쓰고 있어도 지워버리는 참조 카운트 버그가
   생김(사용자 지적, 2026-08-12 열한 번째 세션).

**둘 다 같은 해법으로 풀림**: `Tag`는 **immutable**이고(모든 연산이
clone을 반환) 내부에 State 같은 걸 담지도 않는 **항상 확정 상태인 말단
값**(Tween과 같은 결) — 그래서 `State<Tag>`가 진짜로 다른 내용을 내놓을
때마다 **항상 물리적으로 다른 `Tag` 객체**가 나옴. 이 사실 덕분에, 이름별로
**"지금 이 이름을 걸고 있는 위치(`k`)가 몇 개인가"를 집합으로 추적**하면
`retract`(이전 위치가 이 이름을 놓음)/`process`(그 위치가 새 이름을 걺)가
겹치는 이름/겹치는 위치 양쪽 다 자동으로 올바르게 처리됨:

**[정정, 2026-08-13 네 번째 세션] holders는 `Tag` 객체가 아니라 위치(`k`)로
키잉함.** 최초안은 `holders[Tag객체] = true`(객체 identity 기준)이었으나,
`Tag`는 immutable이라 **재사용이 자연스러운 관례**(예: `local SELECTED =
Tag("selected")`를 모듈 상수로 만들어 여러 위치에서 재사용)인데, 객체
identity로 홀더를 추적하면 같은 객체를 두 위치(`k1`, `k2`)에 걸었을 때
`tagNameMap`엔 **단일 엔트리**만 생겨 두 위치가 구분이 안 됨 — `k1`만
`retract`돼도 그 하나뿐인 엔트리가 지워져 `holders`가 비고, `k2`가 여전히
그 이름을 쓰고 있는데도 `RemoveTag`가 불려버리는 실제 참조 카운트 버그로
손 트레이싱에서 재현됨(하단 "여러 위치가 같은 이름을 겹쳐 가지는 경우"
절이 암묵적으로 "서로 다른 객체"만 가정하고 있었던 게 원인). "여러 위치가
같은 이름을 겹칠 수 있다"는 이 절의 원래 취지 자체가 **위치 기준
집합**이어야 성립하므로, 홀더를 `k`로 바꾸는 게 원 의도와도 더 맞음:

**[정정, 2026-08-13 다섯 번째 세션] `process`가 자기 retract 클로저를
반환하는 계약으로 전환되며 `kTagMap`(위치별 마지막 Tag)이 완전히
불필요해짐** — `retract`가 필요로 했던 "이 위치에 걸려 있던 Tag가
뭐였는가"는 이제 그 `process` 호출이 반환하는 클로저가 `v`를 upvalue로
직접 캡처하므로, 별도 저장소에서 다시 조회할 이유가 없음(위
`base/dispatch-core-plan.md` "핸들러 내부 상태 저장" 절 — 단발성 handoff는
클로저로 충분). **`tagNameMap`(이름별 현재 걸고 있는 위치 집합)은 여전히
필요** — 이건 서로 다른 여러 위치를 가로지르는, `process`/클로저 하나의
호출 수명을 넘어서는 누적 상태라 `Relate`가 맞는 경우:

```lua
local tagNameMap = Relate()   -- {[inst(weak)] = {[tagName]: {[k]: true}}} — 이름별 현재 걸고 있는 위치들

TagHandler.priority = <일반>
TagHandler.isHandlable(inst, k, v) = isTag(v)  -- Brand 기반, array-part 전용

function TagHandler.process(inst, k, v, index)
    local added = {}
    for name in v:Names() do
        local holders = tagNameMap:GetStrong(inst, name)
        if not holders then
            holders = {}  -- strong map — 이 이름을 거는 위치가 하나라도 있는 동안 소유 목록도 살아있어야 함
            tagNameMap:SetStrong(inst, name, holders)
        end
        if next(holders) == nil then
            table.insert(added, name)  -- 이 이름을 처음 거는 위치일 때만 실제 호출 대상
        end
        holders[k] = true  -- 이 "위치"가 이 이름을 걺(Tag 객체가 다른 위치와 같아도 무관)
    end
    if #added > 0 then
        addTag(inst, added)   -- 한 번에 — 웹 className 일괄 갱신을 위한 배치 계약
    end
    return function(nextValue)
        -- nextValue는 nil(단순 철거)이거나 같은 핸들러가 곧 처리할 새 Tag —
        -- 타입이 계약으로 보장되므로 isTag 가드가 필요 없음(2026-08-13 열네 번째 세션).
        if v == nextValue then return end  -- Tag는 immutable이라 객체가 안 바뀌면
                                           -- 이름 집합도 절대 안 바뀜 — holders 순회 자체가 불필요한 순수 최적화
        local removed = {}
        for name in v:Names() do
            -- [정정, 2026-08-14 리뷰] 생존 이름은 **홀더 등록 자체를 유지**한다.
            -- 예전엔 홀더를 일단 빼고 removeTag 호출만 skip했는데, 그러면 곧
            -- 이어지는 process가 빈 holders를 보고 `addTag`를 **다시** 부름
            -- (엔진이 멱등이라 안 보였을 뿐, "진짜 바뀐 이름에만 호출"이라는
            -- 이 절의 설계 목표와 어긋났고 아래 서술과도 모순이었음).
            if nextValue ~= nil and nextValue:Contains(name) then continue end
            local holders = tagNameMap:GetStrong(inst, name)  -- 이미 등록됐으므로 항상 있음
            holders[k] = nil  -- 이 "위치"가 이 이름을 놓음(같은 Tag 객체를 다른 위치도 쓰고 있어도 무관)
            if next(holders) == nil then
                table.insert(removed, name)
            end
        end
        if #removed > 0 then
            removeTag(inst, removed)   -- 한 번에
        end
    end
end
```

- **`addTag`는 온전히 `process`, `removeTag`는 온전히 반환하는 클로저**
  — 서로 겹치는 diff 계산이 없음. 클로저는 이전 `Tag`(`v`, 자기 자신이
  캡처)가 걸었던 이름 중 **새 값이 더 이상 안 거는 것만** 소유 목록에서
  빼고, 그 결과 목록이 빈 이름들을 모아 `removeTag`를 **한 번** 호출함.
  생존 이름은 소유 목록을 그대로 두므로(**[정정, 2026-08-14 리뷰]** 예전엔
  일단 뺐다가 호출만 skip했는데 그러면 곧이은 `process`가 빈 목록을 보고
  `addTag`를 다시 불렀음) 뒤이은 `process`에서 `addTag` 자체가 안 불림 —
  "실제 엔진 호출은 진짜 바뀐 이름에만"이 코드 수준에서도 성립.
  `process`는 `v`가 새로 거는 이름 전부를 무조건 등록(소유 목록이
  비어있던 경우에만 실제 `addTag`) — 자기 나름의 old-vs-new diff가 전혀
  필요 없음(그 일을 클로저가 매번 정확히 해줌).
- **`Tag(A)→Tag(B)`(같은 위치, 내용만 바뀜)**: `A`를 처리했던 `process`가
  반환한 클로저가 `nextValue=B`로 먼저 불려 `A`가 걸었던 이름 중 `B`에
  없는 것만 실제로 `removeTag`, 남은 건 skip — 그 다음
  `process(inst,k,B,index)`가 `B`의 이름 전부를 등록(이미 걸려있던
  이름은 소유 목록이 안 비어 있어 `addTag` 자체가 안 불림, 소유 목록엔
  `B`의 위치가 그대로 유지).
  결과적으로 실제 `removeTag`/`addTag` 호출은 진짜 변경된 이름에만
  일어남 — 스타일 깜빡임 방지라는 원래 목적은 그대로 달성.
  **[범위 확대, 2026-08-13 열네 번째 세션] 이 깜빡임 방지는 이제 깊은
  체인에서도 성립함** — 옛 모델에선 힌트가 `retractFrom`이 지목한 한
  자리에만 전달돼서 `State<State<Tag>>`의 바깥이 재발행하면 TagHandler가
  `nil`을 받아 전량 `RemoveTag` 후 재`AddTag`했으나, 하강 diff에선 **각
  레벨이 자기 재프로세스에서 자기 값을 받으므로** 인덱스가 얼마나 깊든
  TagHandler는 진짜 `Tag` 객체를 받음(`dispatch-core-plan.md` "Dispatch
  체인" 절의 "깊은 체인에서도 힌트가 안 사라짐").
- **`Tag(A)→nil`**: `A`의 클로저가 `nextValue=nil`로만 불림(값이 `Tag`가
  아니게 돼 핸들러가 바뀌므로 `Dispatch.retractFrom` 경로) — `Contains`
  검사가 항상 거짓이 되어 `A`가 걸었던 이름 전부가 무조건 실제로 `removeTag`됨
  (다른 위치가 그 이름을 계속 쓰고 있지 않다면).
- **여러 위치가 같은 이름을 겹쳐 가지는 경우**(`Frame { Tag("a"), Tag("a","b") }`):
  두 위치가 서로 다른 `k`로 각자 독립적으로 `process`/자기 클로저를
  타지만, `tagNameMap["a"]`는 **양쪽 위치(`k`)를 모두 담는 하나의 공유
  집합** — 한쪽이 "a"를 잃어도 다른 쪽 위치가 집합에 남아있으면 실제
  `removeTag`가 안 불림. 웹 `className`처럼 손실 없는 합집합이 정확히
  나옴. **위치 기준이므로 두 위치가 물리적으로 같은 `Tag` 객체를
  재사용해도(흔한 관례) 정확히 같은 방식으로 안전 — 이게 바로 위 "정정"
  절에서 객체 identity 기준을 버린 이유.**
- **클로저가 자기 위임 대상까지 수동으로 안 쫓아가도 됨** —
  `Dispatch.retractFrom`이 체인 전체를 알아서 훑어주므로 TagHandler는
  자기 자원(위 `tagNameMap` 하나)만 정리하면 됨. 상세 메커니즘은
  `dispatch-core-plan.md` "Dispatch 체인" 절.

## 패키지 배치 — 값도 알고리즘도 quad-base, 주입되는 건 `addTag`/`removeTag` (2026-08-13 열네 번째 세션 재배치)

**Tag의 값 타입/clone 체이닝 API(`Tag(...)`/`:Added`/`:Removed`/
`:Contains`/`:Apply`/`Merged`/`:Names`)가 quad-base인 건 처음부터 그대로**
(`Modifier`와 같은 층위 — 엔진 무관, 순수 데이터+연산). **[재배치,
2026-08-13 열네 번째 세션] 여기에 더해 `TagHandler`(위 참조 카운트
알고리즘 전체)도 quad-base로 옮김** — 예전엔 `CollectionService` 실제
호출이 있다는 이유로 핸들러 통째로 quad-roblox였으나, 엔진에 종속된 건
`AddTag`/`RemoveTag` 두 줄뿐이고 `tagNameMap` 참조 카운트는 순수 부기임.
웹에도 대응물이 있으므로(`className` 합집합) 그 배치대로면 **같은 참조
카운트 알고리즘을 백엔드마다 재구현**하게 됨.

```lua
addTag(inst: any, names: {string}): ()      -- 백엔드가 주입
removeTag(inst: any, names: {string}): ()
```

- **`{string}`을 받는 이유**: 호출자는 항상 quad 자신이고 넘기는 것도
  "이번 사이클에 실제로 추가/제거된 이름 집합"이라 테이블이 자연 단위임.
  vararg면 `table.unpack(t)`가 **인자 목록 tail 위치일 때만** 완전히
  펼쳐진다는 Lua 문법 제약에 걸리는데, 이건 이미 `Tag:Added`가
  vararg → `string | {string}`으로 되돌아갔던 것과 **같은 이유**(위 "값
  모양" 절). 배치 호출 자체는 테이블로도 되므로 웹 `className` 일괄
  갱신 요구도 그대로 충족됨.
- **등록 우선순위는 `HANDLER_PRIORITY_FALLBACK`** — 특정 백엔드가 태그
  처리를 통째로 다르게 하고 싶으면 평범한 우선순위로 자기 핸들러를
  등록하면 자동으로 이김. 주입 op이 없는 백엔드에서는 base 스텁이
  명확한 에러를 냄. 일반 원칙과 근거는 `base/dispatch-core-plan.md`의
  "base가 소유하는 핸들러와 주입되는 엔진 op" 절 — `Attribute`도 정확히
  같은 구조(`base/attribute-plan.md`).
- 이건 새 아키텍처 개념이 아니라 이미 확정된 "base는 인터페이스/값,
  backend는 구현"(`LifetimeHandle`의 `bindLifetime`/`canExecute`,
  `Dispatch.addHandler` 자체가 그 패턴)을 핸들러 층까지 밀어붙인 것.

## 열린 질문

값 모양/메커니즘/패키지 배치엔 **[2026-08-13 열네 번째 세션 기준] 없음** —
재디스패치 모델(`question.md` 0-A)과 패키지 재배치까지 전부 반영 완료.
남은 건 이름 자체(`Tag`/`Added`/`Removed`/`Merged`)가 용어 정리
대기열(`.claude/question.md` 1번)에 있다는 것뿐.
