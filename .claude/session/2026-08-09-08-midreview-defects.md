<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-09 여덟 번째 세션 — `.claude/base/` 전체 중간검토(질문 모드),
실제 설계 결함 다수 발견·수정

사용자가 "이 프로젝트의 계획을 중간검토합니다. 각 요소들에 대해서 함수나
클래스 등의 동작을 제가 확인 가능하게 리스팅해요... 질문 모드를 쓰면
좋겠습니다"라고 요청 — 2026-08-04 6차 라운드 때 예고해뒀던 "다음 세션
검증 패스"를 실제로 실행한 세션. 서브에이전트 6개를 병렬로 띄워
`.claude/base/` 전체(15개 파일, 5296줄)를 클러스터별로 정독시켜 확정된
API/동작을 file:line 인용과 함께 그라운딩된 리스팅으로 뽑아낸 뒤, 6개
배치(Store/State/Source+Dispatch, Ref/PreRef+Brand+Length-Offset+생명주기,
Modifier, Slot, Tag/Attribute/UI shorthand+Blocker/Effect, 컴포넌트
경계+아키텍처)로 나눠 각 배치를 텍스트로 보여주고 바로 `AskUserQuestion`
(문제없음/문제있음)으로 확인받는 방식으로 진행 — 문제 제기된 건 그
자리에서 바로 문서에 반영(끝까지 미루지 않음). 총 24개 확인 질문 중
약 1/3에서 실제 설계 결함이 나옴 — 전부 사용자가 구체적인 반례/Luau
시맨틱스를 근거로 지적한 것이라 전부 그대로 수용, 방어하지 않고 수정.

**발견·수정된 것 (파일별)**:

- **`base/bind-system-plan.md`** (가장 많이 고침):
  - `Source(default)`/`Ref(default)`의 `default` 생략이 "선택"이라는
    서술에 "`T`가 nilable일 때만 안전하다"는 캐비엇 누락 — 추가.
    `Ref`는 `:Callback`이 등록 즉시 발화해서 이 문제가 더 잘 드러남.
  - Dispatch 체인 절에 "`handler.process`를 `Dispatch.process` 없이
    직접 호출하면 UB(체인 bookkeeping이 깨져 `retract`가 영영 안
    불리거나 정합성이 무너짐)"라는 불변식이 안 적혀 있었음 — 추가.
  - **Ref 콜백/대기자 배열의 소진 슬롯을 `None`에서 `nil`로 되돌림** —
    2026-08-07 열 번째 세션에 "구멍 있는 정수 키는 순회 순서가 깨진다"는
    이유로 `None`으로 바꿨던 게 이 배열엔 안 맞는 처방이었음(사용자
    지적): 이 배열은 순서가 안 중요해서 일반화 `for`가 구멍이 있어도
    전부 방문하고, 오히려 `None`을 쓰면 슬롯이 영원히 안 비어서
    `:Wait()`마다 배열이 끝없이 길어지는 새 문제가 생김 — `nil`로
    지우고 빈 슬롯을 재사용하는 등록 함수로 바꿈. PreRef pre-pass/
    Length-Offset의 `sourceList`는 순서가 실제로 중요해서 계속 `None`이
    맞음 — 두 사례를 헷갈리지 않게 교차 참조로 명확히 구분.
  - `.Value`가 평범한 hash 필드가 아니라 `__index`로 구현돼야 하는
    이유(콜백 배열과 같은 테이블에 있으면 `T`가 함수/스레드일 때 콜백
    처리 루프에 오분류될 위험) 추가.
  - **`isRef`/`isPreRef`를 `isState`/`isSource`와 같은 상위-하위 합성
    패턴으로 재정정** — 원래 "서로 배타적인 형제 브랜드"였는데, `Source`가
    `State`를 만족하듯 `PreRef`도 `Ref` 런타임을 재사용하는 관계라
    같은 방향(하위=PreRef가 상위=Ref에 포함)으로 다뤄야 일관적이라는
    지적 — `isPreRef`가 가장 구체적인 항등, `isRef`는 그 위에 얹힌
    상위 개념. `(v=Ref)` children leaf 매치 핸들러는 이제
    `isRef(v) and not isPreRef(v)`로 명시적으로 좁혀야 함.
  - `NoneHandler`가 `k` 타입을 안 가리는데 왜 배열 파트 `None`(숫자
    키)에 실제로 안 걸리는지 명확화(배열 파트 `None`은 애초에
    `Dispatch.process`를 안 타서 `NoneHandler`가 볼 기회 자체가 없음).
  - `setLength`/`setOffsetSource`의 `None` 페어링 대상을 "Ref/PreRef
    등" 예시 목록에서 "그 배열 위치의 값 자체가 `None`인 모든 경우"로
    명시적으로 확장, 둘이 항상 짝을 맞춰야 한다는 점도 재강조.
  - `:Subscribe()`가 quad 전역 GC-native 원칙의 의도적 예외(참조를
    다 놓아도 GC 안 되고 계속 실행됨)라는 경고가 없었음 — 추가, 용도도
    "완전히 top-level" 케이스로 좁혀 문서화.
- **`base/modifier-plan.md`**: 핸들러 계층 값 → error 체크가 `State<Ref>`류
  "State/Source가 감싼 내부 값"까지는 못 잡는다는 한계 — 명시적 UB로
  문서화(오버엔지니어링 방지, 실사용 위험 낮음).
- **`base/slot-plan.md`** (가장 큰 변경): **CRUD 식별 기준을 element
  레퍼런스에서 인덱스 기준으로 전환** — `Remove(index)`/
  `Extract(index, newElement?)`/`Move(oldIndex, newIndex)`. 원래
  "인덱스는 stale해진다"는 이유로 레퍼런스 기준을 택했는데, 실제로는
  반대(호출부가 `Add` 리턴값을 안 담고 흘려버리는 경우가 흔함)가 더
  큰 문제였음. **`ExtractAll()`/`Get(index)`/`IndexOf(element)` 신설**
  (`Get`은 "YAGNI"로 드롭했던 걸 재추가). **`Extract(index, newElement?)`
  신설** — 교체가 필요하면 기존엔 Extract+Add 이중 O(n) 시프트가
  필요했는데, 이제 O(1) 제자리 교체 가능(이전 element 반환).
- **`base/tag-plan.md`**: `TagHandler.retract`의 전체 삭제 동작이
  정확히 `v == nil`일 때만 맞다는 전제를 `assert`로 명시(기존엔 "v를
  안 봐도 됨"이라고만 서술돼 있어 조건이 암묵적이었음).
- **`base/attribute-plan.md`**, **`.claude/question.md`**: 타입
  파라미터화(`Attribute<<T>>` 제네릭 vs `BooleanAttribute`류 정적
  패밀리) — "미확정"에서 **"둘 다 채택"으로 확정**(내부 구현 동일,
  호출부 표기만 다름). `=` 뒤 값 타입까지 narrowing되는지는 M0/M10
  실측 필요(안 돼도 런타임 무관)로 명시.
- **`base/ui-shorthand-plan.md`**: `UICorner`/`UIPadding`/`UIScale`이
  타입 생성 스크립트가 만드는 `FrameModifier`류 타입의 메소드 목록에도
  포함돼야 한다는 체크리스트 항목 추가(런타임과 무관한 순수 타입
  생성 디테일).
- **`base/effect-plan.md`**: `EffectHandle`이 내부 Observer를 필드로
  강참조한다는 것, `bindLifetime`/`:Subscribe()` 둘 다 `state`가 있으면
  내부 Observer까지 cascade해야 한다는 것(안 그러면 내부 Observer의
  `canExecute` 게이팅이 올바른 `inst`를 못 봄) — 재확인 후 명시화.
- **`base/component-composition-plan.md`** (Length/Offset 다음으로 많이
  고침):
  - **"리프 바인딩엔 Source가 좁은 예외"라는 서술이 틀림 — 정정.**
    `local a = Source(true); Frame { Visible = a }; a:Set(false)`처럼
    Source를 리프에 직접 물리는 건 이미 확정된 "Source가 State를
    구조적으로 만족" 원칙이 그대로 커버하는 정상 경로였음 — "State가
    일반적"이라는 서술은 Source를 못 쓴다는 뜻이 아니라 "여러 값에서
    파생된 계산 결과는 State일 수밖에 없다"는 통계적 경향 서술일
    뿐이라고 재정정.
  - `props.Modifier or None` 관용구의 `None` 근거 포인터가 Ref 콜백
    배열 정정으로 깨질 뻔한 걸 교차 참조로 바로잡음(그 배열은 순서가
    중요한 별개 케이스라 `None`이 계속 맞음).
  - `Frame { Comp{} }`에서 `Comp`가 `Slot`을 반환하는 다중 루트 우회
    경로가 새 배선 없이 그대로 작동함을 재확인(값이 컴포넌트 호출로
    왔든 리터럴이든 디스패치 입장에선 구분 없음).
- **`ROADMAP.md`**: 위 `Ref` `None`→`nil`/`isRef`·`isPreRef` 변경사항
  체크박스 동기화.

**변경 없이 확인만 된 것**: `:With`/`:Compute` 체이닝, `None` 센티널
기본 메커니즘, Length/Offset 전체, 이중 바인딩 금지/`Relate`/생명주기,
Modifier setter/Apply/Overridden 판단 기준, `Peek`/`isState`/`None`
setter 인자, Slot 요소 타입 제약/Extract portal/`Length`, `Slot:List`
시그니처(단, 캐스케이드 성능 이슈는 `keyFn` 명시 유도로 이미 문서화돼
있어 추가 조치 불필요), List 구독 lazy 시점, Tag 값 모양/패키지 배치,
Blocker 전체, 소스트리/네이밍 컨벤션/Handler 3분류/테스트 전략/이식성
원칙.

**부수 기록**: `.claude/memory`(세션 간 영속 기억)의 협업 스타일 메모에
이번 리뷰 진행 방식(에이전트 병렬 추출 → 배치별 텍스트+AskUserQuestion
즉시 확인 → 그 자리에서 바로 문서 반영)을 다음에 재사용할 패턴으로
기록 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션은 설계
확정이 아니라 기존 확정 사항의 결함 수정이었지만, 결과적으로 M0 착수
전 상태가 더 탄탄해졌을 뿐 우선순위 자체는 그대로. 이 중간검토가
마지막 배치(6단계)까지 끝났는지, 사용자가 이어서 더 볼 부분이 있는지는
다음 세션 시작 시 확인.

