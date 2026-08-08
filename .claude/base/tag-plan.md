# Tag — array-part 값 객체, `CollectionService` 얇은 래퍼

**상태**: base — 2026-08-08 세 번째 세션에서 값 모양을 전면 재설계(구
모델은 `archive/tag-hash-key-model-reversed.md`에 원문·역전 이유 보존).
새 결정만 반영, 열린 질문 없음.

## 왜 재설계됐나

구 모델(`[Tag "Name"] = boolean`, 태그 하나당 해시 파트 키 하나)은 상호
배타적인 스타일 상태(`btn1`/`btn2`/`btn3`류, 실사용에서 20개까지도 가능)를
표현하려면 태그 이름 개수만큼 키를 각각 갱신해야 해서 끔찍함, 스타일
조합(여러 태그를 합쳐 쓰는 것)도 구조적으로 안 됨 — 상세 경위는
`archive/tag-hash-key-model-reversed.md`.

## 값 모양 — `Modifier`와 같은 immutable clone 체이닝

```
Tag(name1, name2, ...)      -- 생성자, 가변인자. Tag() 빈 값도 유효
tag:Added(name): Tag        -- clone 후 이름 추가, 원본 안 건드림
tag:Removed(name): Tag      -- clone 후 이름 제거
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
3번 절과 동일한 immutable 확정 이유: 형제 서브트리 오염 방지). `Tag(a,b)`
자체가 `Tag():Added(a):Added(b)`의 sugar라고 생각하면 됨 — 별도 런타임
경로 아님.

**children 배열 슬롯(array-part)에 직접 놓임** — `Frame { Tag("selected") }`.
정적으로 여러 개 놓아도(`Frame { Tag("a"), Tag("b") }`) 각자 독립적으로
자기 태그만 추가하면 되므로 `Merged` 없이도 됨(`Merged`/`Added`/`Removed`는
"하나의 Tag 값을 프로그래밍적으로 조립"하는 용도).

**동적 토글은 `Source`/`State`로, `None` 불필요** — 상호배타 상태 전환은
`store.activeTag:Compute(function(name) return name == "btn1" and
Tag("selected") or nil end)`처럼 그냥 `nil`을 리턴하면 됨. `None` 센티널은
"정적 테이블 리터럴에서 `키 = nil`이 키 없음과 구별 안 되는" 문제의
해법이지(`bind-system-plan.md` "`None` 센티널" 절), 이건 함수 리턴값이
동적으로 흘러가는 경우라 그 문제 자체가 없음 — `nil`을 인자로 넘기는 건
아무 문제 없음. (단, `Frame { cond and Tag("a") or nil, sibling }`처럼
**정적 리터럴**에서 조건부로 Tag를 넣거나 빼고 싶은 경우엔 다른 array-part
값들과 마찬가지로 `cond and Tag("a") or None` 관용구가 여전히 유효 —
이건 nil-hole 문제라 Tag만의 특수 규칙이 아니라 `props.Modifier`/
`props.Ref`와 같은 일반 array-part 관용구.)

## 메커니즘 — `TagHandler`, retract가 이제 의미 있어짐

구 모델과 달리 **핸들러 타입이 사이클마다 바뀔 수 있음**(`Tag(...)` ↔
`nil`, 값이 `Tag`가 아니게 되면 `TagHandler.isHandlable`이 더 이상 안
맞음) — 그래서 `retract`가 실제로 필요해짐(`bind-system-plan.md` "확정된
디스패치 모델" 절의 일반 원칙 그대로).

```lua
local relate = Relate()  -- TagHandler 전용, 이전에 반영한 Tag 값 저장

TagHandler.priority = <일반>
TagHandler.isHandlable(inst, k, v) = isTag(v)  -- Brand 기반, array-part 전용

function TagHandler.process(inst, k, v)
    local old = relate:GetStrong(inst, k)
    -- diff: old에 있고 v에 없는 이름만 RemoveTag, v에 있고 old에 없는 이름만 AddTag
    -- (모두 지웠다 다시 붙이지 않음 — 랙/스타일 깜빡임 방지가 이 diff의 존재 이유)
    relate:SetStrong(inst, k, v)
end

function TagHandler.retract(inst, k, v)
    local old = relate:GetStrong(inst, k)
    if old then for name in old:Names() do CollectionService:RemoveTag(inst, name) end end
    relate:SetStrong(inst, k, nil)
end
```

- **`Tag(A) → Tag(B)`(같은 핸들러, 타입 안 바뀜)**: `retract`는 아예 안
  불림 — `Dispatch`의 "핸들러가 안 바뀌면 retract 없이 process만 다시"
  원칙 그대로(`bind-system-plan.md` "Dispatch 체인" 절). **diff는 여기,
  `process` 안에서만** 일어남 — 전체 삭제 후 재생성하면 스타일이 순간
  전부 사라졌다 다시 붙어 랙/깜빡임을 유발하므로(사용자 지적), 반드시
  이전 값과 diff.
- **`Tag(A) → nil`(핸들러가 TagHandler → 없음으로 바뀜)**: `retract`가
  불림 — **`v`를 굳이 안 봐도 됨**: retract는 구조상 "더 이상 Tag가
  아니게 됐을 때만" 불리므로, 뭐가 새로 들어왔든 전체 삭제가 항상 맞는
  동작. `Handler.retract`가 여전히 `(inst,k,v)` 3-인자를 받는 건 계약
  일관성 때문이지(다른 핸들러는 `v`를 실제로 씀) Tag가 그걸 필수로
  요구해서가 아님.
- **`retract`가 자기 위임 대상까지 수동으로 안 쫓아가도 됨** —
  `Dispatch.retractUnder`가 체인 전체를 알아서 훑어주므로 TagHandler는
  자기 자원(위 `relate` 저장분)만 정리하면 됨. 상세 메커니즘은
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
