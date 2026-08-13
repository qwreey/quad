# 2026-08-14 아홉 번째 세션 — `PostRef` 확정, `OnRendered` 채택, 계열 안 순서는 미보장으로 갔다가 철회(보장 유지), `lifecycle-hooks-plan.md` base 승격

## 사용자 지시 (원문 그대로)

> PostRef 확정. PreRef 랑 PostRef(lifecycle-hooks-plan.md 에서 스케치됨)
> 을 이제 완전 ref 에 반영 가능할듯. PostRef 는 child 전부 마운트 된 후에
> 처리됨 - 중간 for문에서 모든 Slot, State<Frame>, Frame 등 요소의 마운트가
> 처리될것이므로, Slot 의 실 확정이 바로 요소를 주입해주므로, 바로 뒤에서
> 실행하면 모든 트리가 완성된 이후가 됨. '착수 시점에 판단할 선택지' 는
> (a) 택해도 될듯 하고, Pre-Post 둘을 지원 안 할 이유가 없고, 구현 난이도가
> 아주 낮아서 괜찮다는게 내 결론. ChildAdded 를 나중에 들어오는것만 처리하고
> 싶어서, boolean 으로 flag 지정해둔다던가 뭐, 아에 쓸모 없을 만한건 아니라
> 봄. Ref 는 그냥 설정해주고, 언제 설정할진 모름. PreRef 는 프로퍼티/자식
> 들어오기 전에 설정됨. 각 PreRef 간의 순서는 보장 안함. PostRef 는
> 프로퍼티/자식 들어온 후 설정됨, PostRef간 순서는 보장 안함(실제로 하더라도,
> 안 한다고 두는게 버그를 차라리 덜 만든다고 생각함. 같은 계열 내 Ref 등록
> 순서에 의존하는 무언가가 생겨선 안된다는 생각, 그건 구조부터 잘못된거니까)
> OnRendered 도 채택. ref 문서 업데이트와 lifecycle-hooks-plan.md 의 승격을
> 시키고, 핸드오버/세션기록 준비하고 커밋해줘, 뭔가 걸리는게 있으면 말 해

세션 도중 사용자 추가 메시지 둘: (1) 다른 에이전트가 `session/`에 파일을
export 중이니 커밋 시 예외하라 → (2) 곧이어 "이제 너 말고 다른 에이전트
없어, 무엇을 바꾸든 상관 없어"로 해제.

## 확정된 것

### 1. `PostRef` — base 프리미티브로 확정

여섯 번째 세션이 백로그 후보로만 남겨뒀던 스케치(그 뒤 네 번째 세션이
`ProcessedPreRef` 선례를 반영해 갱신)를 그대로 채택. 선택지 (a)/(b)/(c)
중 **(a)** — pre-pass 공동 수집 + 두 패스 뒤 `postRefList` 소비.

메커니즘(정본은 `base/ref-plan.md`의 "`PostRef`" 절):

1. 기존 `PreRef` pre-pass **한 스윕**에 분기 하나 추가 — `isPostRef(v)`면
   fire하지 않고 로컬 배열 `postRefList`에 push, 즉시
   `flattened[i] = ProcessedPostRef`로 소진(+`_fired` 세팅).
2. 정상 두 패스가 `ProcessedPostRefHandler`로 그 자리를 매치해
   `setLength(0)`/`setOffsetSource(None)` 등록(= `ProcessedPreRefHandler`의
   완전한 거울상, 코드 한 글자 차이).
3. 두 패스가 끝난 뒤 `Dispatch.drive`가 `postRefList`를 순회하며 fire.

새 전체 순회 없음 — 추가 비용은 실제 `PostRef` 개수만큼의 짧은 루프뿐.
동적 경로 가드 Handler, 1회용 `_fired`, Modifier/Store 타입 차단, `isRef`
포함 관계까지 전부 `PreRef`의 거울상으로 그대로 복제됨.

### 2. 스코프 — 원래 문서의 (a)/(b) 구분이 애초에 잘못된 축이었음

원 문서는 "(a) 자기 프로퍼티/이벤트만 vs (b) 자식 서브트리까지"를 열어두고
"(a) 메커니즘은 (b)를 못 준다"고 적어놨었는데, **사용자 지적으로 그게
틀렸음이 드러남** — 배열 파트 루프가 각 자식의 마운트를 동기적으로 끝내고
넘어가고(`Slot`은 실 확정 시 요소를 그 자리에서 주입, `State<Frame>`도
최초 값을 그 자리에서 처리) 해시 파트는 그 뒤이므로, (a) 메커니즘이 사실상
(b) 스코프를 공짜로 줌.

**대신 진짜 경계는 "자기 아래 vs 자기 위"였음** — Claude가 추가로 짚은
캐비엇: `PostRef`는 자기 서브트리 완성은 보장하지만 **이 인스턴스가
부모에 붙는 것(`.Parent` 대입)보다는 여전히 먼저** 불림. `Frame{ Frame{...} }`
처럼 리터럴로 중첩하면 안쪽 `Frame` 호출이 먼저 완결되어야 바깥 `Frame`의
props 테이블이 완성되기 때문. React `componentDidMount`(DOM 삽입 **후**)와
다르므로 `OnRendered` 이름과 함께 반드시 문서화하기로 함.

### 3. `PreRef`/`PostRef` 계열 안 fire 순서 — 미보장으로 갔다가 같은 세션에 철회, **보장 유지**

지시 원문대로 처음엔 뒤집었음 — 2026-08-07 아홉 번째 세션이 "복수 `PreRef`
간 순서 = 배열 index 순서 **그대로 보장**"으로 확정해뒀던 걸 미보장으로
바꾸고(`구현이 아니라 계약만` — pre-pass는 여전히 index 순서로 훑음),
역전 기록까지 만들어 커밋(`bcd02f1`).

**그 뒤 사용자가 "그냥 순서 보장된다 하면 부작용 크겠음?"이라고 되물어
재검토** — Claude 답변 요지: 기술적 부작용은 사실상 0(pre-pass가 어차피
index 순서, `dispatch-core-plan.md`가 배열 파트 index 순서를 백엔드
이식성 때문에 이미 명시적 계약으로 못박아 둬서 새로 약속하는 게 없음),
오히려 미보장 쪽이 (a) 결정론적이라 위반이 테스트에 안 걸리고 (b) 계약
표면에 예외를 하나 더 만드는 비용이 있음.

**사용자가 결정적 반례를 제시하며 보장으로 확정**:

> 솔찍히 이런게 가능해서: FastQuery(...) -> PreRef, 같은걸 만든다 쳐,
> 아래 다른 oncreated 에서 fastquery 를 완료해냈다면 할 수 있는것들을
> 수행해버릴 수도 있겠긴함. 그냥 완전 보장한다고 해버리자.

즉 앞자리 항목이 뒤 항목의 전제를 만들어주는 **정당한 합성**이 실제로
가능하고, 이건 children 마운트 선후가 배열 위치로 정해지는 것(=`phase`
옵션을 없앨 수 있었던 바로 그 이유)과 같은 성격임. 양쪽 논거는
`archive/preref-order-unguaranteed-withdrawn.md`(파일명도 "역전"에서
"철회"로 바꿔 `git mv`), 문서엔 보장 + 스타일 권고("이런 명시적 합성이
아니면 기대지 말 것")를 같이 남김.

### 4. `OnRendered` 채택 + `lifecycle-hooks-plan.md` base 승격

`OnRendered(fn) = PostRef():Callback(fn)`. 이걸로 그 문서의 마지막 열린
항목(채택 여부/메커니즘/스코프)이 전부 닫혀 `research/` → `base/` 승격
(`git mv`). 패키지는 quad-base 확정. 남은 건 `OnDestroyed` 이름 재검토
여지 하나뿐이라 `question.md` 용어 정리 대기열에 3순위로 올림 —
`Slot`/`Brand`처럼 "base 확정, 이름만 재검토 대상"인 기존 항목들과 같은
취급.

**우선순위는 두 층위로 갈림**: `PostRef` 프리미티브는 디스패치 코어라
ROADMAP M8에서 `PreRef`와 같이 구현되고, 훅 슈가 셋만 형제 백로그
(`quad-mock`/`quad-debug`/`Operator`/`Fallback`)와 동급으로 맨 뒤.

### 5. 대표 유스케이스 (사용자 제시)

`ChildAdded` 같은 이벤트에서 **나중에 들어오는 것만** 처리하고 싶을 때,
`PostRef` 콜백이 `mounted = true` 플래그를 세우고 핸들러가 그걸 먼저 보는
패턴. 초기 construction 중 발생한 이벤트와 그 이후 동적으로 들어온 것을
사용자 코드가 스스로 구분할 수 있게 해줌 — `PreRef`만으론 표현이 안 되던
자리.

## 반영한 파일

- `base/ref-plan.md` — 제목 `Ref / PreRef / PostRef`, 승격 배너,
  "`PostRef`" 절 신설(타이밍 대조표/보장 범위/메커니즘/Handler/가드/
  유스케이스), `PreRef` 순서 bullet에 "왜 보장까지 하는가"(`FastQuery`
  사례) 추가, pre-pass 서술에 `postRefList` 반영.
- `base/lifecycle-hooks-plan.md` — `research/`에서 `git mv`, 상태를 base
  확정으로, `OnRendered` 절 신설, ② 절을 "보류"에서 "채택 확정"으로
  (역전 배너 + 근거 보존), 스코프/선택지/이름/패키지/우선순위/열린 질문 절
  전면 갱신.
- `base/dispatch-core-plan.md` — `Dispatch.drive` 정의에 pre-pass/후행
  `postRefList` 소비 명시, `None` 센티널 절과 Length/Offset 절에
  `ProcessedPostRef` 대칭 반영.
- `base/brand-plan.md` — `PostRefTag`/`isPostRef` 추가, `isRef` 포함
  관계를 셋으로 확장, Leaf 핸들러 predicate 갱신.
- `base/architecture.md` — 소스 트리에 `PostRef.luau`/`LifecycleHooks.luau`,
  `Leaf.luau` 주석, 생성자/유틸 목록.
- `base/slot-plan.md`/`base/modifier-plan.md` — 핸들러 계층 값 금지
  목록에 `PostRef` 추가(4곳+4곳).
- `base/typing-limits.md` — `PostRef<T>`도 `PreRef<T>`와 같은 서브타입
  관계, 스파이크 `13` 재작성 시 같이 커버할 것.
- `archive/preref-order-unguaranteed-withdrawn.md` — 신설(미보장 안의
  제안·철회 왕복 기록).
- `.claude/README.md` — lifecycle-hooks 행을 research→base 표로 이동·전면
  갱신, `ref-plan.md`/`brand-plan.md` 행 갱신, archive 새 행.
- `ROADMAP.md` — M8 체크리스트에 `PostRef.luau`/`postRefList` 소비/
  `ProcessedPostRefHandler`/동적 경로 가드 추가, pre-pass 항목의 순서
  보장 문구 갱신, Brand/Leaf 항목 갱신, 백로그에 훅 슈가 셋 추가.
- `question.md` — 용어 대기열에 `OnDestroyed` 항목, `Brand` 항목의
  "10종" 표현 정리.
- `CLAUDE.md` — 백로그 항목 갱신 + 이 세션 요약.

`python3 .claude/tools/doc-check.py` ERROR 0 유지 확인.

## Claude가 걸린다고 보고한 것

1. **`OnRendered`가 "부모에 붙기 전"에 불린다는 캐비엇** — 위 2번.
   이름이 React 관용어라 오해를 부를 수 있다고 보고했고, **사용자 답변은
   "OnRendered는 부모에 들어가기 전이라고 명시만 해줘"** — 이름은 그대로
   두고 문서에 캐비엇을 명시하는 것으로 확정
   (`base/ref-plan.md` "보장 범위" 항목 + `base/lifecycle-hooks-plan.md`
   `OnRendered` 절의 ⚠️ 항목).
2. **순서 미보장은 계약 변경이지 구현 변경이 아니라 실효가 없음** —
   실제로는 여전히 index 순서로 fire될 것이라 위반이 절대 안 드러남.
   이 지적이 위 3번의 재검토·철회로 이어졌음.
