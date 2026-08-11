<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-11 여섯 번째 세션 — `Slot:Single` 확정, Slot-in-Slot 중첩 확정,
Length/Offset `recompute` off-by-one 버그 발견·수정

`Slot():Single(state, updateFn?)` 백로그(2026-08-09 여섯 번째 세션,
"`State<Frame?>`가 offset을 못 받아서 위쪽 Slot의 offset/length를 써야
했다"는 동기)를 실제로 설계하다가, 더 큰 질문(Slot을 다른 Slot 안에
넣을 수 있는가)까지 라이브로 풀어낸 긴 세션. 다섯 갈래로 정리:

**1. `Slot:Single(state, updateFn)` — `:List` 위의 순수 sugar로 확정.**
`state`를 0/1개짜리 배열로 감싸(`:Compute`) `:List`에 위임, 고정
key(`true`)로 `prev` 재사용을 보장, `index`는 상수라 안 넘김. 원래
동기(offset 접근)를 이걸로 완전히 해결 — "offset을 얻으려고 컴포넌트가
Slot을 리턴하는" 우회가 필요 없어짐. `base/slot-plan.md`
"`Slot:Single(...)`" 절.

**2. Slot-in-Slot 중첩 확정 — 동기는 카테고리 헤더가 아니라 컴포넌트
결합의 균일성.** 사용자가 직접 짚은 진짜 이유: `SomeComponent(props)`가
`Instance`를 리턴하든 `Slot`(멀티루트 워크어라운드)을 리턴하든
`outerSlot:Add(result)`가 분기 없이 동작해야 함 — 지금까지 "요소 타입
제약"이 `Slot`을 암묵적으로 배제하고 있어서 정확히 이 케이스가 막혀
있었음. **핵심 발견 — 메커니즘은 그대로 재사용, 새 프리미티브 불필요:**
`Dispatch.setLength`/`setOffsetSource`의 첫 인자(`inst`)가 물리
Instance일 필요가 없다는 것(`Relate`가 아무 테이블이나 weak 키로 받음)을
재사용해, **Slot 자신을 owner 키로 같은 두 함수를 한 번 더 부르면
최상위 마운트와 중첩 마운트가 완전히 같은 함수 호출**이 됨 — 재귀
`attachSlot(slot, physicalTarget, ownerKey, position)` 하나로 통합.
`Slot.Length`는 raw 개수에서 "요소별 기여도의 합"(plain=1, nested
Slot=그 `.Length`)으로 의미 변경.
- **타입 레벨로 확장하려던 "모든 instance 처리를 Slot에 위임"은 기각** —
  리터럴 배열(`Dispatch.drive`)의 요소 타입 규칙(Ref/PreRef/Observer
  허용)이 Slot의 요소 타입 규칙(같은 값들 금지)과 정반대라, 타입을
  진짜로 통합하면 "만들어진 방식에 따라 행동이 다른 Slot"이라는 숨은
  분기가 생김 — **메커니즘(setLength/setOffsetSource/recompute)만
  공유하고 타입/CRUD 표면은 분리 유지**로 스케일 확정(사용자 확인:
  "그게 더 엔지니어링 비용이 싸고 좋은 구현").
- **파괴는 재귀적 `Clear()`가 아니라 flat `destroySlotTree`** — 사용자가
  직접 비용 문제 지적("clear된 다음 length 바뀌고 위치변경 전파되는
  구조는 안 됨"): 재귀 `Clear()`(요소별 Remove 반복)는 죽는 서브트리
  내부에서 불필요한 shift+recompute가 요소 수만큼 반복됨 — 대신 순수
  파괴 walk(`.Destroy()`만)+`unbindLifetime` walk로 바꾸고, outer 쪽
  recompute는 자기 위치 하나에 대해서만 1회. `unbindLifetime`이 왜 꼭
  필요한지도 새로 드러남 — `bindLifetime`은 물리 target 생명주기에
  걸려있어 target이 살아있는 채로 논리 서브트리만 죽는 경우(카테고리
  삭제 등) GC가 자동으로 안 치워줌, 명시적 호출 필요(물리 target 자체가
  죽는 경우는 기존처럼 GC가 전부 처리).
- **`Slot(initial?: {T})` 생성자로 확장** — "인자 없는 빈 생성자로
  확정"을 뒤집음(2026-08-09 세 번째 세션 결정 정정), 단 새 마운트
  로직이 아니라 `:Add` 반복 호출 sugar(`ipairs`의 "첫 nil에서 멈춤"
  동작이 "중간 nil UB, 그 뒤 무시"를 공짜로 구현). **`initial ~= nil`이면
  빈 테이블이어도 즉시 `_crudUsed = true`**(사용자 지적: `Slot({})`은
  상태상 `add():remove(1)`과 동일이라 결과가 비어있어도 "CRUD를 썼다"는
  의도는 이미 커밋됨) — `Slot()`(진짜 `nil`)만 나중에 `:List`/`:Single`
  설치 가능. **`_crudUsed` ↔ `_listed` 상호 배타 가드도 신설** — 기존엔
  `:List` 설치 후 수동 CRUD만 막았지 반대(수동 CRUD 후 `:List` 설치)는
  안 막아서, `:List`의 reconcile이 기존 요소를 모른 채 충돌하는 gap이
  있었음(사용자 발견).
- **DOM 백엔드가 nested Slot을 실제 `<div>` 중첩으로 매핑하는 안은
  기각** — 제가 처음 낸 "web은 물리 nesting을 지원하니 이 메커니즘이
  아예 필요 없을 수도"라는 제안을 사용자가 직접 반박: React `<></>`가
  존재하는 이유와 정확히 같은 이유로 Slot도 의도적으로 wrapper 없는
  그룹핑 도구라, div 매핑은 그 원칙 자체를 깨버림. 숫자 기반 메커니즘은
  web에도 그대로 필요하되, `insertBefore`/`removeChild`가 물리적으로
  밀고/당겨주므로 이미 배치된 형제 프로퍼티 재작성은 불필요(기존
  2026-08-09 여섯 번째 세션 확정과 정합적, 사용자가 세션 도중 직접
  재확인). "물리적으로 이전에 어디 있었는지" 같은 backend 종속 위치
  정보는 base 책임이 아니라 필요한 backend가 자기 `Relate`로 저장할
  몫 — 새 설계 불필요, 이미 확정된 base/backend 경계 그대로.

**3. `Dispatch.setLength`/`setOffsetSource`/`recompute`의 owner 키가
물리 Instance로 한정될 필요 없다는 걸 `base/bind-system-plan.md`에
명시.** "Length/Offset" 절에 짧은 절 신설 — 이게 위 재귀 메커니즘 전체의
근거.

**4. `recompute`의 off-by-one 버그 발견·수정 — 중첩과 무관한, 기존
Length/Offset 메커니즘 자체의 버그.** 구체 숫자로 흐름을 검증하려다
발견: 원래 코드가 `sum += lengthList[i]`를 먼저 하고 `offset:Set(sum)`을
나중에 해서, `offset[i]`가 "자기 앞의 형제들이 기여한 개수"가 아니라
**자기 자신을 포함한** 누적합이 되고 있었음(예: `Frame{Slot1}` 하나뿐이어도
`Slot1.Offset`이 `Slot1.Length`가 되어버림) — 순서를 뒤집어(offset 먼저
Set, 그 다음 sum에 자기 기여도 누적) 수정. 지금까지 실제 Luau로 돌려본
적이 없어 아무도 못 잡았던 버그. 카테고리 헤더 예시(7개 리프)로 수정된
공식을 검증, 정확히 저작 순서대로 LayoutOrder 1..7이 나옴을 확인.
**`offset`/`sum`은 0-based 개수, `index`는 1-based Lua 관례**라는
점도 명시적으로 콜아웃(둘을 섞는 `index+offset` 공식이 의도된 것이지
인덱싱 불일치가 아님).

**5. Reentrancy 가드 검토 후 기각 — 제가 처음 제안한 `_recomputing`/
`_dirty` 플래그가 불필요함을 사용자가 정확히 캐치.** "nested Slot이
있으면 항상 dirty가 켜져서 불필요한 for문이 한 번 더 돈다"는 사용자
지적을 계기로 호출 경로를 다시 추적 — **각 Slot이 `Relate(자기 자신)`으로
독립된 `bk`를 가지므로, 중첩 Slot의 Length 변경이 상위로 전파되는 경로는
항상 서로 다른 `bk`를 거쳐 지나감**, 즉 nesting이 있다는 사실만으로는
같은 `(ownerKey,bk)`가 재진입되는 경로 자체가 없음이 확인됨 — 제가
가드의 동기 자체를 잘못 짚었던 것. 진짜 재진입(부작용이 recompute
도중 같은 Slot에 다시 Add/Remove)은 이미 확정된 "일반적 재진입/무한루프
방어 안 함, 사용자 코드 버그로 간주" 원칙 그대로 두면 되므로, 가드
없이 off-by-one만 고친 순수 버전으로 최종 확정. **같은 세션 후속으로
이 케이스에 명시적 이름을 붙임(사용자 제안)** — `Source⊇State`의
"단방향"(파생값이 자기 upstream Source로 거꾸로 안 쓴다) 원칙과 같은
카테고리 위반으로 프레이밍: recompute가 만드는 `offset`/`Length`는
`lengthList`(upstream 입력)에서 파생된 다운스트림 값인데, 부작용이
자기 자신의 `lengthList`를 다시 mutate하는 게 그 반대 방향 쓰기라
"State가 자기 Source에 Set을 가하는 것"과 동일한 UB로 명명 —
새 원칙이 아니라 이미 있는 단방향 흐름 원칙의 재적용.

**반영된 파일**: `base/slot-plan.md`(요소 타입 제약/`Slot(initial)`/
CRUD 가드/`Slot:Single`/"Slot-in-Slot 중첩" 신규 절/`Slot.Length`),
`base/bind-system-plan.md`(owner 키 일반화/`recompute` 버그 수정),
`ROADMAP.md`(M6 체크박스 다수 추가), `.claude/question.md`(`Slot:Single`
백로그 해소 표시).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는 그대로.
`Slot<T>`의 자기 참조 제네릭 실측이 luau-test 확인 목록에 새로 추가됨.

