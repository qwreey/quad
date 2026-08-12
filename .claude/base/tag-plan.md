# Tag — array-part 값 객체, `CollectionService` 얇은 래퍼

**상태**: base — 2026-08-08 세 번째 세션에서 값 모양을 전면 재설계(구
모델은 `archive/tag-hash-key-model-reversed.md`에 원문·역전 이유 보존).
2026-08-12 열한 번째 세션에 `TagHandler`의 `process`/`retract` 메커니즘을
참조 카운트 기반으로 전면 정정(옛 버전은 `archive/
retract-always-fires-reversed.md`). 2026-08-12 열다섯 번째 세션에
`Added`/`Removed`를 단일 이름에서 vararg로 정정(아래 값 모양 절). 새
결정만 반영, 열린 질문 없음.

## 왜 재설계됐나

구 모델(`[Tag "Name"] = boolean`, 태그 하나당 해시 파트 키 하나)은 상호
배타적인 스타일 상태(`btn1`/`btn2`/`btn3`류, 실사용에서 20개까지도 가능)를
표현하려면 태그 이름 개수만큼 키를 각각 갱신해야 해서 끔찍함, 스타일
조합(여러 태그를 합쳐 쓰는 것)도 구조적으로 안 됨 — 상세 경위는
`archive/tag-hash-key-model-reversed.md`.

## 값 모양 — `Modifier`와 같은 immutable clone 체이닝

```
Tag(name1, name2, ...)      -- 생성자, 가변인자. Tag() 빈 값도 유효
tag:Added(name, ...): Tag   -- clone 후 이름(들) 추가, 원본 안 건드림
tag:Removed(name, ...): Tag -- clone 후 이름(들) 제거
tag:Contains(name): boolean -- 멤버십 확인
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

**[정정, 2026-08-12 열다섯 번째 세션] `Added`/`Removed`도 vararg —
`Tag(a,b)`는 `Tag():Added(a,b)` 한 번의 clone sugar, `Tag():Added(a):Added(b)`
처럼 반복 clone하는 게 아님.** 처음엔 단일 `name`만 받고 생성자의
vararg는 반복 `Added` 호출의 sugar로 서술했으나, 이러면 이름 여러 개를
한 번에 걸 때(`Tag(a,b,c)`도 결국 clone 1회면 충분한데) 이름 개수만큼
`table.clone`+해싱이 반복되는 손해가 남 — 태그가 이미 걸려있는 경우 self를
그냥 리턴하는 최적화도 검토했으나(2026-08-12 열다섯 번째 세션) 그러려면
매번 먼저 멤버십을 읽어야 해서 오히려 전반적으로 더 비쌈(해싱이 한 번
더 나고 Set에서도 한 번 더 남) — **기각, `Added`는 항상 새 clone을
반환하는 현재 동작 유지**. 대신 여러 이름을 한 번의 clone으로 처리하는
vararg만 추가해 흔한 다중 추가 케이스의 비용을 줄임. `Tag(name1, name2,
...)` 생성자도 이제 정확히 `Tag():Added(name1, name2, ...)`(단일 clone)와
동치.

**children 배열 슬롯(array-part)에 직접 놓임** — `Frame { Tag("selected") }`.
정적으로 여러 개 놓아도(`Frame { Tag("a"), Tag("b") }`) 각자 독립적으로
자기 태그만 추가하면 되므로 `Merged` 없이도 됨(`Merged`/`Added`/`Removed`는
"하나의 Tag 값을 프로그래밍적으로 조립"하는 용도).

**동적 토글은 `Source`/`State`로, `None` 불필요** — 상호배타 상태 전환은
`store.activeTag:Compute(function(name) return name:Get() == "btn1" and
Tag("selected") or nil end)`처럼 그냥 `nil`을 리턴하면 됨. `None` 센티널은
"정적 테이블 리터럴에서 `키 = nil`이 키 없음과 구별 안 되는" 문제의
해법이지(`bind-system-plan.md` "`None` 센티널" 절), 이건 함수 리턴값이
동적으로 흘러가는 경우라 그 문제 자체가 없음 — `nil`을 인자로 넘기는 건
아무 문제 없음. (단, `Frame { cond and Tag("a") or nil, sibling }`처럼
**정적 리터럴**에서 조건부로 Tag를 넣거나 빼고 싶은 경우엔 다른 array-part
값들과 마찬가지로 `cond and Tag("a") or None` 관용구가 여전히 유효 —
이건 nil-hole 문제라 Tag만의 특수 규칙이 아니라 `props.Modifier`/
`props.Ref`와 같은 일반 array-part 관용구.)

## 메커니즘 — `TagHandler`, `retract`가 이제 의미 있어짐

구 모델과 달리 **핸들러 타입이 사이클마다 바뀔 수 있음**(`Tag(...)` ↔
`nil`, 값이 `Tag`가 아니게 되면 `TagHandler.isHandlable`이 더 이상 안
맞음) — 그래서 `retract`가 실제로 필요해짐(`bind-system-plan.md` "확정된
디스패치 모델" 절의 일반 원칙 그대로).

**[전면 정정, 2026-08-12 열한 번째 세션] 아래는 이전 버전(단일 `relate`,
`assert(v==nil)`, "Tag(A)→Tag(B)는 retract 안 불림")을 대체함 — 그 버전은
두 가지를 놓쳤음:**

1. **`retract`는 실제로 store 재발행마다(핸들러 타입이 안 바뀌어도) 항상
   불림** — `bind-system-plan.md`의 "확정된 디스패치 모델" 절이 처음부터
   말해온 대로 `StoreBind`가 재-dispatch 전에 무조건 `Dispatch.retractUnder`를
   부르기 때문. "Tag(A)→Tag(B)는 retract 안 불림"이라는 옛 서술은 틀렸음
   (상세 근거는 `bind-system-plan.md` 일반 retract 계약 절, `archive/
   retract-always-fires-reversed.md`).
2. **서로 다른 배열 위치의 두 `Tag(...)`가 같은 이름을 겹쳐 가질 수
   있음**(`Frame { Tag("a"), Tag("a","b") }`류, 웹 `className="a a a"`와
   같은 합집합 시맨틱) — 한 위치의 diff만 보고 `RemoveTag`를 부르면 다른
   위치가 아직 그 이름을 쓰고 있어도 지워버리는 참조 카운트 버그가
   생김(사용자 지적, 2026-08-12 열한 번째 세션).

**둘 다 같은 해법으로 풀림**: `Tag`는 **immutable**이고(모든 연산이
clone을 반환) 내부에 State 같은 걸 담지도 않는 **항상 확정 상태인 말단
값**(Tween과 같은 결) — 그래서 `State<Tag>`가 진짜로 다른 내용을 내놓을
때마다 **항상 물리적으로 다른 `Tag` 객체**가 나옴. 이 사실 덕분에, 이름별로
"어떤 `Tag` 객체들이 지금 이 이름을 걸고 있는가"를 집합으로 추적하면
`retract`(이전 객체가 이 이름을 놓음)/`process`(새 객체가 이 이름을 걺)가
겹치는 이름/겹치는 위치 양쪽 다 자동으로 올바르게 처리됨:

```lua
local kTagMap = Relate()      -- {[inst(weak)] = {[k]: Tag}} — 위치별 마지막으로 반영한 Tag
local tagNameMap = Relate()   -- {[inst(weak)] = {[tagName]: {[Tag]: true}}} — 이름별 현재 걸고 있는 Tag들

TagHandler.priority = <일반>
TagHandler.isHandlable(inst, k, v) = isTag(v)  -- Brand 기반, array-part 전용

function TagHandler.retract(inst, k, newv)
    local oldv = kTagMap:GetStrong(inst, k)
    if not oldv then return end
    local newvIsTag = isTag(newv)  -- newv는 nil일 수도, 대체하는 새 Tag 자체일 수도 있음
    for name in oldv:Names() do
        local holders = tagNameMap:GetStrong(inst, name)  -- 이미 등록됐으므로 항상 있음
        holders[oldv] = nil
        if next(holders) == nil and not (newvIsTag and newv:Contains(name)) then
            inst:RemoveTag(name)  -- 곧 process가 재확정할 이름이면 실제 호출은 skip(깜빡임 방지)
        end
    end
end

function TagHandler.process(inst, k, v)
    for name in v:Names() do
        local holders = tagNameMap:GetStrong(inst, name)
        if not holders then
            holders = {}  -- strong map — Tag가 살아있는 동안 소유 목록도 살아있어야 함
            tagNameMap:SetStrong(inst, name, holders)
        end
        if next(holders) == nil then
            inst:AddTag(name)
        end
        holders[v] = true
    end
    kTagMap:SetStrong(inst, k, v)
end
```

- **`AddTag`는 온전히 `process`, `RemoveTag`는 온전히 `retract`** — 서로
  겹치는 diff 계산이 없음. `retract`가 이전 `Tag`(`oldv`)가 걸었던 이름
  전부를 소유 목록에서 빼되(항상 실행), 그 결과 목록이 비었을 때 **실제
  `RemoveTag` 호출만** "새로 들어올 `newv`가 그 이름을 여전히 Contains하는가"로
  힌트를 줘서 skip — 소유 목록 자체는 항상 최신 객체로 갱신되므로(정확히
  `oldv`를 빼고 `v`를 넣는 두 단계), 이름이 살아남는 경우에도 stale
  레퍼런스가 안 남음. `process`는 `v`가 새로 거는 이름 전부를 무조건
  등록(소유 목록이 비어있던 경우에만 실제 `AddTag`) — 자기 나름의 old-vs-new
  diff가 전혀 필요 없음(그 일을 `retract`가 매번 정확히 해줌).
- **`Tag(A)→Tag(B)`(같은 위치, 내용만 바뀜)**: `retract(inst,k,B)`가 먼저
  불려 `A`가 걸었던 이름 중 `B`에 없는 것만 실제로 `RemoveTag`, 남은 건
  힌트로 skip — 그 다음 `process(inst,k,B)`가 `B`의 이름 전부를 등록(이미
  걸려있던 이름은 `AddTag`가 no-op으로 재확인만 됨, 소유 목록엔 `B`가 새로
  등록). 결과적으로 실제 `RemoveTag`/`AddTag` 호출은 진짜 변경된 이름에만
  일어남 — 스타일 깜빡임 방지라는 원래 목적은 그대로 달성.
- **`Tag(A)→nil`**: `retract(inst,k,nil)`만 불림(값이 `Tag`가 아니게 돼
  `process`는 매치 자체가 안 됨) — `newvIsTag=false`라 힌트가 항상
  거짓이 되어 `A`가 걸었던 이름 전부가 무조건 실제로 `RemoveTag`됨(다른
  위치가 그 이름을 계속 쓰고 있지 않다면).
- **여러 위치가 같은 이름을 겹쳐 가지는 경우**(`Frame { Tag("a"), Tag("a","b") }`):
  두 위치가 서로 다른 `k`로 각자 독립적으로 `process`/`retract`를 타지만,
  `tagNameMap["a"]`는 **양쪽 위치의 `Tag` 객체를 모두 담는 하나의 공유
  집합** — 한쪽이 "a"를 잃어도 다른 쪽 객체가 집합에 남아있으면 실제
  `RemoveTag`가 안 불림. 웹 `className`처럼 손실 없는 합집합이 정확히
  나옴.
- **`retract`가 자기 위임 대상까지 수동으로 안 쫓아가도 됨** —
  `Dispatch.retractUnder`가 체인 전체를 알아서 훑어주므로 TagHandler는
  자기 자원(위 두 릴레이션)만 정리하면 됨. 상세 메커니즘은
  `bind-system-plan.md` "Dispatch 체인" 절.

## 패키지 배치 — base는 값+API, roblox는 process/retract 글루

**Tag의 "값 타입과 clone 체이닝 API"(`Tag(...)`/`:Added`/`:Removed`/
`:Contains`/`:Apply`/`Merged`)는 quad-base 소속** — `Modifier`와 정확히
같은 층위(엔진 무관, 순수 데이터+연산). `CollectionService` 실제 호출
(`TagHandler.process`/`retract`)만 quad-roblox 소속 — 이미 확정된 "base는
인터페이스/값, backend는 process·retract 글루" 패턴(`LifetimeHandle`,
`Dispatch.addHandler` 자체가 이 패턴)을 값 타입 수준까지 그대로 확장한
것뿐, 새 아키텍처 개념 아님.

## 열린 질문

없음 — 값 모양/메커니즘/retract/패키지 배치 전부 확정. 이름 자체
(`Tag`/`Added`/`Removed`/`Merged`)는 다른 가칭들과 같이 용어 정리 대상
(`.claude/question.md`).
