# [역전됨] "핸들러 타입이 안 바뀌면 retract 없이 process가 diff" — `retract`는 store 재발행마다 항상 불림으로 정정

**역전 일시**: 2026-08-12 (열한 번째 세션). **원 확정 일시**: 2026-08-07
(여덟 번째 세션, `bind-system-plan.md`의 일반 retract 계약 절)~2026-08-09
(Tag의 `assert(v==nil)` 명시화).
**현재 유효한 설계**: `base/bind-system-plan.md`의 일반 retract 계약
절(`retract(inst,k,v)` 항목), `base/tag-plan.md`/`base/attribute-plan.md`
"이름 소유권"/"메커니즘" 절, `base/ref-plan.md`의 "`Ref`의 retract"
절, `base/slot-plan.md` "Slot과 Store 바인드의 관계" 절이 최종 소스.

## 역전된 사례 — 원래 무엇을 확정했었나

**"retract가 실제로 의미 있는 유일한 패턴은 같은 키에 대해 매치되는
핸들러 *타입 자체*가 사이클마다 바뀌는 경우"** (2026-08-07 여덟 번째
세션 정정 당시 확정, `bind-system-plan.md`) — 예로 `Tag(...)`↔`nil`을
들며, "같은 Tag끼리 바뀌는 diff는 process가 담당"(즉 `Tag(A)→Tag(B)`
같은 동일 핸들러 타입 전환에서는 `retract`가 아예 안 불린다)고 명시.
`base/tag-plan.md`는 이 전제를 코드에 그대로 반영해 `TagHandler.retract`에
`assert(v == nil, "TagHandler.retract는 v가 nil일 때만 불려야 함")`을
넣었고(2026-08-09 열한 번째 세션 "명시화"), 이후 2026-08-12 여덟/아홉
번째 세션에 `Ref`/`Slot`도 같은 전제("핸들러 타입이 안 바뀌면 retract
없이 process가 diff")를 그대로 이어받아 각자 `assert(v==nil)`을 두고
`process` 안에서 old-vs-new diff를 계산하는 설계로 확정됐었음.

## 역전된 이유

`Attribute`의 이름 소유권 설계를 논의하다 사용자가 지적: `Tag`도 서로
다른 배열 위치의 `Tag(...)`가 같은 이름을 겹쳐 가질 수 있는데
(`Frame { Tag("a"), Tag("a","b") }`, 웹 `className`과 같은 합집합
시맨틱), 한 위치의 diff만으로 다른 위치가 아직 쓰는 이름을 지워버리는
참조 카운트 버그가 날 수 있다는 문제 제기에서 시작. 이를 풀기 위해
retract 쪽에서 "새로 들어올 값이 이 이름을 여전히 필요로 하는가"를
확인하는 설계(`Tag:Contains()` 힌트)를 사용자가 제안했는데, 이게
성립하려면 **`retract`가 `v=Tag`(nil이 아닌 대체 값)를 받는 경우가
실제로 있어야 함** — 기존 `assert(v==nil)`과 정면으로 모순.

`bind-system-plan.md`의 "확정된 디스패치 모델" 절(2026-08-04 원문)을
다시 대조하니, `Dispatch/StoreBind.luau`는 재-dispatch 전에 **무조건**
`Dispatch.retractUnder(inst,k,self,realv)`를 부른다고 이미 명시돼
있었음 — "핸들러 타입이 안 바뀌면 생략"이라는 조건은 그 문서 어디에도
없었음. 즉 2026-08-07 세션의 "retract가 의미 있는 유일한 패턴" 서술이
자기 문서의 다른 절과 처음부터 모순돼 있었고, `Tag`의 `assert(v==nil)`을
액면 그대로 믿고 거꾸로 일반 규칙을 잘못 추론한 게 오류의 실제 출처
(2026-08-09 "명시화" 세션에서도 이 모순이 안 걸림). 사용자가 직접
"어떤 값이든 덮여 쓰여지는 즉시 retract를 실행하는 거로 두기로 했었다 —
전체 process 트랙을 retract하고 리빌드한다는 맥락"이라고 확인하며
확정.

## 정정된 이해

- `retract(inst,k,v)`는 store 바인드가 재발행될 때마다(핸들러 타입이
  안 바뀌어도) 항상 불림. `v`는 `nil`일 수도, 그 자리를 대체하는 새
  값 자체일 수도 있음 — **`retract` 안에서 `v`를 절대 `nil`로
  가정하면 안 됨.**
- 대부분의 핸들러(일반 PropertyHandler, `NoneHandler`, UICorner
  숏핸드 등)는 이 반복 호출에서 실제로 할 일이 없어 `retract`가
  사실상 no-op — "타입이 안 바뀌면 아예 안 불린다"가 아니라 "불리지만
  몸체가 비어 있어도 된다"가 정확한 표현.
- `Tag`/`Ref`/`Slot`/`Attribute`처럼 여러 위치가 하나의 실제 리소스를
  공유하거나 값 자체가 정리가 필요한 상태를 들고 있는 핸들러는, `v`를
  힌트 삼아 "곧 다시 필요해질 것"이면 실제 엔진 호출만 skip하는
  방식으로 대응 — `retract`가 이전 기여 제거(힌트로 skip 가능),
  `process`가 새 기여 등록을 전담하는 분업이 자연히 나옴, `process`
  쪽에 별도 old-vs-new diff가 더 이상 필요 없어짐.

## 영향받은 문서 (이 세션에 모두 정정 완료)

- `base/bind-system-plan.md` — 일반 retract 계약 절, `NoneHandler` 절,
  "`Ref`의 retract" 절.
- `base/tag-plan.md` — `TagHandler` 메커니즘 전면 재작성(`kTagMap`/
  `tagNameMap` 참조 카운트).
- `base/slot-plan.md` — "Slot과 Store 바인드의 관계" 절, `destroySlotTree`
  호출이 `process`에서 `retract`로 이동.
- `base/attribute-plan.md` — `AttributeKeyHandler.retract`에 `v==nil`
  가드 추가, 그룹의 이름 집합 diff가 "남아있는 이름도 먼저
  `retractUnder`" 방식으로 정정(체인 누수 방지).
- `base/ui-shorthand-plan.md`, `base/tween-plan.md` — 결론(해당 핸들러의
  `retract`는 no-op)은 안 바뀌었으나, "retract가 아예 안 불린다"는
  근거 서술만 정정.
