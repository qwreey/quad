# 2026-08-14 일곱 번째 세션 — UI 숏핸드 Tween 지원, existing-instance-bind 기각, `bind-system-plan.md` 3단계 분할

사용자가 한 메시지에 세 건을 지시했고, 세 번째(문서 분할)에 대해서는
"이 분리가 합당한가"를 먼저 판단해 달라고 요청함.

## 1. `ui-shorthand-plan.md`에 Tween 지원 추가

**사용자 제안 원문 요지**: "ui-shorthand-plan 은 이제 Tween 을 지원하게
되어야할듯. 이건 process 상 똑같이 활용하면 되는 부분으로 보임 → 프로세스
중 inst 를 바꾸는것이 UB 는 아님. 키도 바뀔 수 있는거 처럼, 따라서
인스턴스 메니징 생성 후 이것을 process 처리하는것으로 해결."

확인 결과 지적이 정확했고, 오히려 **기존 서술이 stale**이었음:
`ui-shorthand-plan.md`의 store-bind 절이 "트윈처럼 애니메이션까지 지원할
필요는 없음(API 표면만 복잡해짐)"이라고 못박아뒀는데, 그 판단의 전제는
Tween이 **독립 Dispatch 핸들러**(우선순위를 다투는 특수 bind key)였던
시절이었음. 2026-08-10 세션에 Tween이 값-레벨 래퍼 `Tween<T>` +
`PropertyHandler` 내부 분기로 재설계되면서(`base/tween-plan.md`,
`archive/tween-special-bind-key-reversed.md`) 그 비용이 통째로 사라졌는데
이 문서만 안 따라와 있었던 것 — 즉 "새 기능 추가"가 아니라 **역전 반영**.

확정된 메커니즘:

- 숏핸드 Handler의 `process`가 자식(`_quad_corner`류)을 찾거나 만든 뒤,
  프로퍼티를 **직접 대입하지 않고** `Dispatch.process(child, "CornerRadius",
  ..., 1)`로 되돌려줌.
- `chains`가 `(inst,k)` 쌍으로 인덱싱되므로 "다른 `inst`로 위임"은 Dispatch
  입장에서 "다른 `k`로 위임"(Attribute 그룹이 이미 하는 것)과 **구조적으로
  완전히 같은 일** — 사용자가 말한 "키도 바뀔 수 있는 것처럼"이 정확히
  이것. 이 일반 규칙을 `base/dispatch-core-plan.md`의 "인덱스의 의미" 절에
  새 불릿으로 명문화(위임 대상 자식의 **수명 책임은 위임한 핸들러**에
  있다는 단서 포함).
- 이걸로 Tween 해석 코드가 `PropertyHandler` 하나에만 존재한다는
  `tween-plan.md`의 불변식이 유지됨 — 3-상태 릴레이션 슬롯, `Tween.Cancel`/
  `Tween.Finish` override 정책, "첫 세팅은 애니메이션 없이 즉시"가 전부
  `(child, prop)` 자리에서 그대로 재사용.

**이 세션에 새로 발견해 채운 부품 하나** — 숏핸드는 스칼라를 자식 프로퍼티
타입으로 감싸는 `wrap`(`UICorner = 8` → `CornerRadius = UDim.new(0,8)`)을
갖고 있는데, `v`가 `Tween<number>`면 그 변환을 **`Tween`을 벗기지 않고
`.Value`에만** 적용해야 함. `table.clone` 후 `Value`만 갈아끼워 `Tween(opts)`로
재브랜딩하는 `mapTweenValue(v, wrap)` 헬퍼로 해결(그 자체가 새 메커니즘은
아니고, `Tween<T>`가 immutable 값 객체라는 기존 성질의 사용).

부수적으로 정리한 것:
- `UIPadding`처럼 자식 프로퍼티 **여러 개**에 같은 값을 쓰는 키는 프로퍼티마다
  `Dispatch.process`를 따로 부름 → 각자 독립 체인, 트윈 슬롯도 따로.
  열린 질문 절의 룩업 테이블 스케치도 `Property` → `Properties`(목록)로 정정.
- 캐비엇: 자식이 파괴/재생성되는 사이클에서는 `prev == nil`(첫 세팅) 규칙
  때문에 트윈이 안 걸리고 스냅됨 — 버그가 아니라 그 규칙이 막으려는 진입
  애니메이션과 정확히 같은 상황이라 의도된 동작으로 문서화.
- **ROADMAP에 UI 숏핸드 항목 자체가 없던 갭 발견** — `ui-shorthand-plan.md`는
  "M10 전후로 구현" 이라고 이미 지정해뒀는데 체크리스트엔 한 줄도 없었음.
  M10 끝에 구현 포인트 6개와 함께 신규 추가.

## 2. `existing-instance-bind-plan.md` 기각 → `archive/`

**사용자 판단**: "이게 가능하다 하면 offset source 나 length source 등을
밀고 당기고 하는 많은 부가적 작용을 가능케 하고, 버그를 일으키기에 치명적
표면을 많이 노출시킴."

오래 "미지원으로 확정하지는 않고 열린 가능성으로 유지"였던 항목 —
`archive/existing-instance-bind-rejected.md`로 이전하고 기각 사유 배너를
달았음. 배너에 같이 적어둔 것: quad가 만들지 않은 Instance의 자식 구성
변화까지 추적하려면 Instance 가상화가 필요한데, 그건
`research/framework-comparison-findings.md`가 use-after-destroy 안전망을
기각할 때 쓴 것과 같은 이유(rbvm 같은 전문 라이브러리의 영역)로 스코프 밖.

**파생 정리(체크리스트 2번 — 배너가 부정하는 본문을 같은 커밋에서 고칠 것)**:
경로만 바꾸면 되는 게 아니라 "열려 있음"을 전제로 쓰인 문장이 여러 곳에
있었음.
- `base/architecture.md` — "아직 미정(research/로 분리됨)" 절에 남아있던
  **유일한 항목**이 이거였음 → 절 자체를 "이제 아키텍처를 미정으로 남기는
  항목은 없음"으로 갱신. 소스 트리 절의 "여전히 research/에 남아있고"도 정정.
- `base/ref-plan.md` — PreRef fire를 `flatten`에 얹지 않기로 한 근거가 "재바인드
  때문에 flatten이 여러 번 재호출될 수 있어서"였음 → 그 위험은 사라졌지만
  결론(기각)은 유지되므로 근거를 "flatten은 `inst`를 모르는 순수 변환이라"로
  교체.
- `base/relate-plan.md` — "quad 밖 Instance를 `Relate` 키로 쓰는 건 UB" 따름
  정리는 유지하되, 그 UB를 실제로 건드릴 뻔한 유일한 경로가 닫혔음을 명시.
- `base/modifier-plan.md`(Default→실값 flatten 미정 문제), `base/dispatch-core-plan.md`
  (인덱스 체인의 "미래 재바인드에 유리" 부수 효과 서술 — quad-debug/자기
  인스턴스 재발행 근거만 남기고 재프레이밍), `research/pre-implementation-audit.md`
  2-4(Slot 단일 마운트 소유권과의 긴장 → "기능이 기각되어 해소"),
  `question.md`(항목 제거) + `archive/question-resolved.md`(해소 기록),
  `ROADMAP.md` 백로그(항목 제거), `CLAUDE.md` 2곳.

## 3. `bind-system-plan.md` 3단계 분할 + `store-semantics.md` 흡수

**사용자 지시**: "bind 쪽에서 state 를 분리해야한다고 생각함.
store-semantics.md bind-system-plan.md 둘에서 정보를 추합해서 문서정리를
수행해. Store가 Store를 저장 가능한가 → 이런것 같은건, store-plan.md
문서로 합쳐 신설. 이젠 Store 는 source 를 여럿 담고, 없으면 만들어주는
도구일 뿐이라, 쉽게 분리가능. state/source 는 아주 가까운 요소라
source-state-plan.md 로 저장하면 될것 같음. 이 분리가 합당한거 같아?"

**판단: 합당함.** 근거 셋 —
1. 두 문서가 실제로 같은 주제를 반씩 나눠 갖고 **서로를 "상세는 저쪽 참고"로
   가리키는 핑퐁**이 여러 곳에 있었음(온톨로지, `store.key`가 Source를 반환,
   `:Set()` 전환, Slot 생존 확인이 각각 양쪽에 반씩). 어느 쪽이 정본인지
   문장마다 달라서 읽는 사람이 매번 두 파일을 왕복해야 했음.
2. Store가 "이름 붙은 Source 모음, 그 이상 아님"으로 좁혀진 게 2026-08-06에
   이미 확정 — 사용자 말대로 **분리 가능해진 지 오래**였고, 남은 Store 고유
   내용(부작용 정책, `defaults` 템플릿, eager/lazy 생성, dot-access 타이핑,
   `type function`, "Store가 Store를 담는가")은 반응형 코어와 의존 관계가 거의
   없음.
3. `Source`⊇`State`는 구조적 서브타입이라 **한 파일이 맞음** — 쪼개면
   `:With`/`:Compute` 반환 타입 설명이 두 파일에 중복됨.

**한 가지 캐비엇을 같이 보고함**: 분할 후 `bind-system-plan.md`에 남는 건
인스턴스 생성/이벤트 네이밍 인체공학 + 팩토리 주입 + 색인뿐이라(1238줄 →
203줄) 파일 이름이 내용보다 넓어짐. 리네임은 참조 churn이 커서 **이번엔 안
하고** 제목만 "인스턴스 생성·이벤트 네이밍 인체공학 + 분할 색인"으로 바꿔둠.

결과 줄 수: `bind-system-plan.md` 1238→203, `store-semantics.md` 346→삭제,
`source-state-plan.md` 1148 신설, `store-plan.md` 224 신설(합 1584→1575,
사실상 순수 이동).

### 참조 스윕

`store-semantics.md`가 **`doc-check.py`의 `OURS` 패턴에 안 걸리는 이름**
(`-plan`/`-reversed` 등으로 안 끝남)이라, 삭제해도 ERROR가 아니라
"외부 문서명일 수 있음" WARN으로만 잡히는 걸 발견 — 그래서 ERROR 목록만
믿지 말고 `grep`으로 전수(라이브 문서 40여 곳)를 직접 훑어 고침. 절 참조는
스크립트를 하나 짜서 "옛 파일에 없고 새 파일에 있는 절 제목"을 자동으로
재지정하고, 의역 인용 9건만 손으로 정리.

최종 `doc-check.py`: **ERROR 0, WARN 85**(작업 전 101 — 분할로 새로 생긴
것을 다 닫고, 겸사겸사 기존 의역 WARN 몇 개도 같이 정리해서 오히려 줄었음).

### 동시 세션 주의

`.claude/worktrees/debounce-throttle-plan/`에 다른 세션의 워크트리가
`.claude/` 전체 복사본을 갖고 있음 — 이번 분할이 그쪽 사본에는 반영되지
않았으므로, 그 세션이 메인에 병합할 때 `store-semantics.md`/
`bind-system-plan.md`를 가리키는 참조가 되살아날 수 있음. 병합 시
`doc-check.py`를 반드시 다시 돌릴 것.
