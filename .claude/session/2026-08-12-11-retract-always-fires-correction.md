# 2026-08-12 열한 번째 세션 — "retract는 항상 불림" 전면 정정, Tag 참조 카운트 재설계

## 배경

열 번째 세션(Attribute 이름 소유권)에 이어, 사용자가 같은 클래스의 문제가
`Tag`에도 있을 수 있다고 지적: 서로 다른 배열 위치의 `Tag(...)`가 같은
이름을 겹쳐 가질 수 있는데(`Frame { Tag("a"), Tag("a","b") }`, 웹
`className="a a a"`와 같은 합집합 시맨틱), 한 위치의 diff만으로 다른
위치가 아직 쓰는 이름을 지워버리는 참조 카운트 버그가 날 수 있다는
문제 제기.

## 논의 전개 — 근본 오류 발견까지

1. Claude가 처음 위치별 `{[k]: true}` set(참조 카운트)을 제안 → 사용자
   동의.
2. 사용자가 후속 질문: "retract에서 새롭게 들어온 v가 Tag라면 Contains를
   확인해서 재사용될 거면 RemoveTag 안 함" — 이게 성립하려면 `retract`가
   `v=Tag`(nil 아닌 값)를 받는 경우가 있어야 함. Claude가 처음엔 이걸
   기존 `assert(v==nil)`과 모순된다고 판단해 "메커니즘을 바꾸자는
   거냐"고 되물음.
3. 사용자가 재확인: "정확히 저는 어떤 값이든 덮여 쓰여지는 즉시 retract를
   실행하는 거로 두기로 했었어요 — 전체 process 트랙을 retract하고
   리빌드한다는 맥락이었어요."
4. Claude가 `bind-system-plan.md`의 "확정된 디스패치 모델" 절(2026-08-04
   원문)을 재확인 — `Dispatch/StoreBind.luau`는 재-dispatch 전에
   **무조건** `Dispatch.retractUnder`를 부른다고 이미 명시돼 있었음.
   "핸들러 타입이 안 바뀌면 생략"이라는 조건은 어디에도 없었음 — 2026-08-07
   여덟 번째 세션에 추가된 "retract가 의미 있는 유일한 패턴" 서술이
   자기 문서 다른 절과 처음부터 모순돼 있었고, `Tag`의
   `assert(v==nil)`을 액면 그대로 믿고 거꾸로 일반 규칙을 잘못 추론한 게
   오류의 실제 출처였음이 드러남.

## 파급 효과 확인

이 오류가 **이번 대화에서 만든 `Ref`(여덟 번째 세션)/`Slot`(아홉 번째
세션)/`Attribute`(열 번째 세션) 설계 전부에 그대로 이어받아져 있었음** —
셋 다 `assert(v==nil)`을 두고 "같은 핸들러 타입이면 process가 diff"라는
전제로 설계돼 있었기 때문. 사용자의 지적("retract는 v가 다른 값일 수
있는데, diff하는 모든 곳에서 is로 잘 테스트하고 있는지 봐야할듯")대로
전수 감사·수정 진행.

## 정정된 일반 원칙

`retract(inst,k,v)`는 store 재발행마다(핸들러 타입이 안 바뀌어도) 항상
불림 — `v`는 `nil`일 수도 대체하는 새 값 자체일 수도 있음, `retract`
안에서 `v==nil`을 가정하면 안 됨. 대부분의 핸들러(PropertyHandler,
`NoneHandler`, UICorner 숏핸드)는 이 반복 호출에서 실제로 할 일이 없어
no-op이면 충분 — "타입 안 바뀌면 아예 안 불린다"가 아니라 "불리지만
몸체가 비어 있어도 된다"가 정확한 표현. 여러 위치가 하나의 실제
리소스(엔진 attribute/tag/mounted 서브트리 등)를 공유하는 핸들러는
`retract`가 이전 기여 제거(엔진 호출은 `v` 힌트로 skip 가능),
`process`가 새 기여 등록을 전담하는 분업이 자연히 나옴 — `process` 쪽에
별도 old-vs-new diff가 더 이상 필요 없어짐(그 일을 `retract`가 매번
정확히 대신 해줌).

## 각 파일 정정 내역

- **`base/tag-plan.md`**: `TagHandler` 메커니즘 전면 재작성 — 단일
  `relate`(이름 집합)를 `kTagMap`(위치→Tag)+`tagNameMap`(이름→Tag
  set) 두 릴레이션으로 분리. `retract`가 이전 Tag의 이름들을 무조건
  `tagNameMap`에서 빼되, 실제 `RemoveTag`는 "새로 들어올 Tag가 그
  이름을 여전히 Contains하는가" 힌트로 skip. `process`는 새 Tag의
  이름을 무조건 등록(집합이 비어있던 경우만 실제 `AddTag`) — 자기
  diff 불필요. `AddTag`는 온전히 `process`, `RemoveTag`는 온전히
  `retract`로 완전히 분업. 여러 위치가 같은 이름을 겹쳐 가지는 경우도
  공유 `tagNameMap` 집합으로 자동 해결.
- **`base/bind-system-plan.md`**: 일반 retract 계약 절 전면 재작성(위
  "정정된 일반 원칙" 그대로). `Ref`의 retract 절 — `assert(v==nil)`
  제거, "언바인딩은 retract 전담, 바인딩은 process 전담"으로 재설계(둘
  다 `old==v`/`old~=v` identity 체크로 spurious 재발행 시 콜백 이중
  발화 방지). `NoneHandler` 절의 "retract와 무관" 근거도 정정(불리긴
  하지만 할 일이 없어서 no-op).
- **`base/slot-plan.md`**: "Slot과 Store 바인드의 관계" 절 — `destroySlotTree`
  호출이 `process`에서 `retract`로 이동(`old~=v`면 폐기), `process`는
  마운트만 전담(`old==slotValue`면 no-op).
- **`base/attribute-plan.md`**: `AttributeKeyHandler.retract`에
  `v==nil` 가드 추가(그렇지 않으면 매 store 재발행마다 attribute가
  잠깐 nil로 flicker). 그룹의 "남아있는 이름" 위임도 `retractUnder`
  없이 `Dispatch.process`만 반복 호출하면 체인이 매번 새 항목을
  쌓기만 해서(팝은 `retractUnder`의 일) 누적 누수가 생기는 걸 발견 —
  남아있는 이름도 먼저 `retractUnder`(같은 캐싱된 키로) 부른 뒤에만
  `process`하도록 정정.
- **`base/ui-shorthand-plan.md`, `base/tween-plan.md`**: 결론(해당
  핸들러의 `retract`는 no-op)은 안 바뀌었으나 "retract가 아예 안
  불린다"는 근거 서술만 정정.
- **`archive/retract-always-fires-reversed.md`** 신설 — 원문·역전
  이유·영향받은 문서 전부 보존.
- **`README.md`** — 위 파일들 요약 라인 + 아카이브 표에 새 항목 추가.

## 남은 것

전수 감사는 base/ 전체 `retract` 언급 파일(관련 없는 `relate-plan.md`/
`module-lifecycle-plan.md`/`lifecycle-pattern.md`/`onchange-plan.md`
등)까지 훑었으나, `onchange-plan.md`의 `OnChangeHandler`(Connection
disconnect/reconnect 패턴)는 애초에 공유 리소스가 없어 이 문제에
해당 안 됨 — 정정 불필요 확인만 하고 넘어감.
