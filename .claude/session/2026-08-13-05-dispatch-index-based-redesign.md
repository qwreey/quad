# 2026-08-13 다섯 번째 세션 — `Dispatch` 인덱스 기반 전면 재설계, `State<State<T>>` UB 해제

## 배경

직전 세션(04)에서 Attribute 그룹의 이름 소유권 충돌 버그를 고치려고
`Dispatch.processAs`/`Dispatch.retractSelfAndUnder`("체크포인트 핸들러")
패턴을 신설했음. 사용자가 이 설계에 대해 솔직한 평가를 요청 — Claude가
`retractSelfAndUnder`가 사실 `retractUnder(keep=nil)`과 동치라 불필요할
수 있다는 것과, "공짜 충돌 감지"가 실은 도메인 특화가 아닌 저수준 에러
메시지라는 비용을 감춘다는 두 가지를 솔직히 지적.

## 1부 — 체크포인트 패턴 자체에 대한 사용자의 근본적 문제 제기

사용자가 "최상단에서 뭔가 지우는 일은 하기 싫다 — 그걸 제공한다는 것부터
'어떤 핸들러가 최상단에 프로세싱을 넣어야 했다'는 가정이 생기고, 가정이
많아지는 건 안 좋다"고 지적. 대신 "명시적으로 자신이 만들어낸 처리"를
기입하는 편이 버그를 내기 어렵고 엔지니어링 비용도 거의 공짜라며, 각
`process`/`processAs` 호출이 자신이 push했던 체인 인덱스를 제공하고, 각
`process` 함수 자신이 retract 클로저를 반환하는 커링 방식을 제안. 재귀는
`index+1`, 새 키로 위임하면 `1`부터 — `retractUnder`/`retractSelfAndUnder`도
인덱스를 받게 하면 `State<State<T>>` 같은 복합 처리도 깨끗이 지원되면서
전체 구조가 훨씬 단순해질 거라는 통찰.

Claude가 이 통찰을 검증: 기존 `chains`가 핸들러 **객체 identity**로
포지션을 추적하던 것 자체가 `State<State<T>>`를 UB로 만들었던 근본
원인(같은 싱글톤이 재귀로 자신과 매치되면 identity로 구분 불가)이었고,
인덱스 기반으로 바꾸면 각 재귀 단계가 서로 다른 슬롯을 쓰므로 그 모호성
자체가 사라짐 — 순환 참조만 여전히 UB로 남음(기존 "순환은 UB" 원칙과
같은 급).

## 2부 — 세부 메커니즘 확정

사용자와 왕복하며 세 가지를 확정:

1. **`Dispatch.process`가 핸들러 호출 *전에* 점유 체크, 핸들러 부르고
   나서가 아님** — 부작용(SetAttribute, Observer 구독 등)이 실제로
   일어나기 전에 걸러야 낭비/깜빡임이 없음. 에러 메시지가 도메인 특화로
   상세하지 않은 것에 대해 사용자가 "이미 에러가 나면 패닉 상태고 그
   이후 정합성은 관리 대상이 아니다"라고 스스로 정리 — 상세 설명을 위해
   먼저 실행해보는 비용을 들일 이유가 없다는 데 동의.
2. **시작 인덱스는 0이 아니라 1** — Luau `ipairs`/`#`은 1부터 연속된
   정수 키를 전제하므로(quad가 "props 순회 순서" 절에서 이미 이 관례에
   의존), 0을 쓰면 `ipairs` 순회에서 그 항목이 조용히 빠지고
   `quad-debug`가 `chains`를 그대로 순회해 보여주려는 계획과도 부딪힘.
   사용자 확인.
3. **`retractUnder`/`retractSelfAndUnder`를 `Dispatch.retractFrom(inst,k,
   index,v)` 하나로 통합** — "자기 포함이냐 미만이냐"는 순전히 호출자가
   어느 인덱스를 넘기느냐의 문제가 됨(`myIndex` vs `myIndex+1`). 이걸로
   전날 세션에서 지적됐던 "retractSelfAndUnder가 사실 불필요할 수 있다"는
   비판이 자연스럽게 해소됨.
4. 사용자가 추가로 "이러면 store 바인드가 이전 것을 retract할 필요도
   없다"고 지적 — `retractFrom`의 순회 구조(항상 깊은 인덱스부터 정리)가
   각 핸들러의 하위 위임 cascade를 자동으로 대신해준다는 걸 재확인. 이
   원칙을 손으로 검증하는 과정에서 SlotHandler의 "claimOwner가 false를
   반환하는(spurious 재발행) 분기"가 순진하게 no-op 클로저를 반환하면
   실제 자원의 cleanup 책임이 유실되는 사각지대를 발견 — 모든 process
   호출이 항상 동일한(slotValue/inst를 캡처하는) 대칭적 클로저를
   반환하도록 고쳐 해결(Ref는 이 문제가 없음 — 클로저의 동작이 `v`
   identity에만 의존해 어느 호출의 클로저든 동치이기 때문, Slot은
   `attachSlot`이라는 진짜 1회성 부작용이 있어서 달랐던 것).

## 반영 완료

- `base/bind-system-plan.md`: 핸들러 계약(3필드로 축소, `process`가
  retractor 반환), "확정된 디스패치 모델"/"None 센티널"/"Dispatch 체인"
  섹션 전면 재작성, `Dispatch.processAs`/`retractSelfAndUnder` 섹션
  삭제(→ archive), Store 바인드/Ref retract 예시 pseudocode 전부 새
  계약으로 갱신 — 여러 곳에서 private `Relate`가 클로저 캡처로 대체되며
  불필요해짐(StoreBind의 observer 저장, Ref의 언바인딩용 relate 일부).
- `archive/checkpoint-handler-pattern-reversed.md` 신설 — 전날 만든
  체크포인트 패턴 원문+역전 이유 보존.
- `base/attribute-plan.md`: `AttributeGroupKeyHandler`/`processAs`/
  `retractSelfAndUnder` 전부 제거, 그룹이 공개 `AttributeKey(name)`으로
  항상 인덱스 1에 직접 위임하도록 재작성. `groupState` Relate도 제거
  (반환 클로저가 이름 집합을 직접 캡처).
- `base/tag-plan.md`: `TagHandler.process`가 retractor 반환, `kTagMap`
  제거(클로저가 `v` 직접 캡처), `tagNameMap`만 유지(여러 위치를
  가로지르는 진짜 누적 상태).
- `base/slot-plan.md`: `SlotHandler.process`가 retractor 반환, `kSlotMap`
  제거 — 위 2부 4번 항목의 대칭성 수정 포함.
- `architecture.md`/`store-semantics.md`/`modifier-plan.md`: 4필드
  Handler 계약 언급을 3필드로 정정.
- 코퍼스 전체 grep sweep으로 `retractUnder`/`processAs`/
  `retractSelfAndUnder`/`.retract(inst` 잔존 참조 확인 — 의도된 역사
  서술 외 전부 반영 완료.

## 남는 것

- 오늘 신설한 인덱스 기반 모델(`Dispatch.process`의 점유 체크,
  `retractFrom`)을 검증할 `luau-test/` 스파이크가 아직 없음 — 기존
  `04`(다단 체인 스트레스 테스트)가 가장 가까운 후보라 다음 세션에
  그 파일을 새 모델에 맞춰 재작성하는 게 자연스러움.
- `.claude/luau-test/`는 여전히 사용자가 `luau`로 안 돌려봄 — M0 착수
  전 최우선 게이트 그대로 유지, 이번 세션의 재설계도 손 트레이싱으로만
  검증됨.
