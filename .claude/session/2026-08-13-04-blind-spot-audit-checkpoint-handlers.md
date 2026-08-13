# 2026-08-13 네 번째 세션 — 사각지대 손 트레이싱 라운드, `Dispatch.processAs`/`retractSelfAndUnder` 체크포인트 핸들러 신설

## 배경

직전 세션(02)에서 `State<State<T>>`가 UB인데 "가능하다"로 문서에 낙관적으로
적혀 있던 문제를 발견·수정한 것을 계기로, 사용자가 같은 방식(합성
시나리오를 pseudocode에 손으로 대입)으로 다른 사각지대가 더 있는지
찾아달라고 요청. 서브에이전트 4개(Tag/Attribute/Slot/Ref+교차훑기)를
병렬로 띄워 `.claude/base/` 전체를 훑음.

## 1부 — 서브에이전트 발견 (실제 버그 3건)

1. **Tag 참조 카운트 붕괴**: `tagNameMap`의 holders가 `Tag` 객체 identity로
   키잉돼 있어서, 같은 Tag 객체(immutable이라 재사용이 흔한 관례,
   `local SELECTED = Tag("selected")`류)를 두 위치에 걸면 한 위치만
   retract돼도 다른 위치가 쓰는 태그가 지워지는 버그.
2. **Attribute 그룹 자기충돌**: 그룹이 이름을 놓았다(retract, 로컬 캐시
   초기화) 나중에 같은 그룹이 같은 이름을 다시 포함하면(`rawNew`로 새
   키 생성), 전역 `owners` 레지스트리엔 옛 키가 안 지워진 채 남아있어
   "이미 다른 AttributeKey가 관리 중" 에러 — 그룹이 자기 자신과 충돌.
3. **Slot `rawAdd`의 이중 State 언랩 실패**: `Slot:Add(State<State<T>>)`류
   이중 래핑에서 `reconcile`이 부르는 `rawAdd`가 `isState` 재검사를 안
   해서 State 객체가 그대로 `_elements`에 박힘 — **[정정, 2부에서 사용자
   확인] 실제로는 버그가 아니라 이미 확정된 `State<State<T>>` UB 범위의
   당연한 사례**, 최초 보고가 과다 보고였음.

문제 없음으로 확인된 것: `State<State<Ref>>`/`State<State<Tag>>`(StoreBind
재진입 가드가 먼저 걸림), `PreRef` 재사용 가드, Slot의 owner-키 Relate ↔
`chains` 네임스페이스 분리, `elementOwner`의 다단 Slot-in-Slot GC 안전성.

## 2부 — 사용자의 직접 기술 리뷰, 세 번째 설계로 수렴

사용자가 서브에이전트 보고에 대해 직접 pseudocode 레벨로 반박/재설계를
제시(이 세션의 핵심):

- **Tag**: 위치(`k`) 기준 재키잉에 동의. 추가로 "Tag는 immutable이니
  `oldv==newv`면 retract 스킵 가능" 최적화 제안 — 채택.
- **Attribute**: `AttributeGroupHandler.process`가 `retractUnder`에 `self`를
  안 넣는 이유를 질문하다, `retractUnder`가 `process` 안에 있는 것 자체가
  구조적으로 틀렸다고 재지적(`process`가 다시 안 불리는 상황이면
  `retractUnder`도 안 일어남) — 결론적으로 `owners`/`rawNew` 레지스트리를
  통째로 버리고, `isHandlable`이 없는(스캔에 안 걸리는) 순수 체크포인트
  핸들러 `AttributeGroupKeyHandler`를 새로 만들어 `Dispatch.processAs`로
  명시 push하고, 나중에 `Dispatch.retractSelfAndUnder`(신설 — 기존
  `retractUnder`가 `keep` **미만**만 지우는 것과 달리 `target` **이하**까지
  지움)로 체크포인트+그 아래 전부를 한 번에 철거하는 설계 제안. 손
  트레이싱으로 검증: 이 설계는 소유권 충돌 감지를 별도 레지스트리 없이
  기존 "같은 (inst,k)에 같은 핸들러 재사용 시 error" 가드(`State<State<T>>`
  가드와 동일 메커니즘)로 공짜로 얻음 — 채택, `AttributeKeyHandler`는
  완전 무상태로 단순화됨.
- **Slot**: `releaseOwner`의 소유권 불일치를 조용히 무시하던 걸 즉시
  error로 바꿔야 한다는 지적(그 상황 자체가 이미 버그라는 판단) — 채택.
  `bindLifetime`이 `attachSlot`의 조건 분기에 묻혀있는 게 `unbindLifetime`이
  Handler 층위(`SlotHandler.retract`)에 있는 것과 비대칭이라는 지적 —
  `bindLifetime`을 `SlotHandler.process`로 이동, `attachSlot`은 순수
  구조적 mount 로직으로 단순화. 채택.
- **Brand**: `isXX` 판별 함수들이 `nil`을 안전하게 처리하는지 서브에이전트로
  확인 요청 — 결과 **안전함**(weak registry lookup 방식이라 `nil` 키
  조회도 항상 안전하게 `false`로 귀결, 에러 나는 경로 없음). 문서 수정
  불필요, M0 스파이크 목록에 `isXX(nil)` 명시적 실측 케이스 추가는 선택
  사항으로 남김(안 함).

## 반영 완료

- `base/bind-system-plan.md`: 핸들러 계약에 `isHandlable` 선택적 필드로
  확장(생략 시 스캔 불가), "Dispatch 체인" 절에 `Dispatch.processAs`/
  `Dispatch.retractSelfAndUnder` 신설 + 체크포인트 패턴 설명, `handler.process`
  직접 호출 UB 경고에 `processAs`도 정식 진입점으로 포함.
- `base/tag-plan.md`: holders를 Tag 객체 identity에서 위치(`k`) 기준으로
  재키잉, `TagHandler.retract`에 `oldv==newv` 조기 반환 추가.
- `base/attribute-plan.md`: "이름 소유권"/"메커니즘" 두 절 전면 재작성 —
  `rawNew`/`owners` 제거, `AttributeGroupKeyHandler` 체크포인트+
  `processAs`/`retractSelfAndUnder` 페어로 교체, `AttributeKeyHandler`
  무상태화, `groupState`를 "이름→키 객체 맵"에서 "이름 집합"으로 단순화.
- `base/slot-plan.md`: `releaseOwner` 불일치 시 error로 강화, `bindLifetime`
  호출을 `attachSlot`에서 `SlotHandler.process`로 이동.
- `.claude/README.md`: 4개 파일 행에 이 세션 요약 append.

## 서브에이전트 조사(문서 수정 없음, 결과만)

- Relate `GetStrong`/`SetStrong` 키 누락 + const-키 비효율 패턴 코퍼스
  전수조사 — `attribute-plan.md`의 `owners:GetStrong(inst)` 1건(이미 이
  세션에서 재설계로 해소됨) 외 추가 발견 없음, 나머지 전부 정상 사용.
- Brand/`isXX` nil 처리 전수조사 — 안전함 확인(위 2부 참고).

## 남는 것

- `Slot:ExtractAll()`/`:Splice(...)`의 반환값을 `Slot(...)` 생성자에 바로
  넣을 수 있다는 조합 예시를 문서에 추가하면 좋겠다는 사용자 코멘트 —
  버그 아님, 착수 안 함(원하면 다음 세션에).
- `luau-test/` 스파이크(20개, 이 세션에서 다룬 새 메커니즘은 아직 스파이크
  파일 없음 — `Dispatch.processAs`/`retractSelfAndUnder`/`AttributeGroupKeyHandler`
  재설계를 검증할 스파이크 추가 여지가 있음, 필요시 다음 세션) — 여전히
  사용자가 `luau`로 안 돌려봄, M0 착수 전 최우선 게이트 그대로.
