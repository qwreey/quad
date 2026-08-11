<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-06 세 번째 세션 — 문서 사이트 구조, 프레임워크 정직 비교, Source가 State를 만족하는 서브타입 재구성

같은 날 이어진 세 번째 세션. 셋으로 갈리는 주제라 순서대로 요약 — **다음
세션이 새로 알아야 할 건 4번(Source/State 재구성)뿐**, 1~3번은 배경/참고용.

**1. 문서 사이트 구조 확정 — 초심자/api/심화 3축 + `quadnomicon` 4번째 축.**
`research/documentation-plan.md` 0번 항목에 전부 반영. 초심자는 "core loop
완주에 필요한 최소 집합만, 백엔드 구체적(quad-roblox), quad-base/roblox
분리 노출 안 함, 다른 백엔드 생기면 그때 별도 트랙 추가"로 스코프 확정.
api는 간략 설명 + 심화로 "더 알아보기" 링크 패턴. `quadnomicon`(Rustonomicon
패러디, 사용자 확정 이름)은 quad 사용자가 아니라 "비슷한 프레임워크를
설계/포크하려는 엔지니어"용 4번째 축 — Fusion/Vide 내부 비교 같은 콘텐츠가
여기 해당, 세션 정정 이력 같은 순수 내부 리서치 원자료는 이 축에도 안
들어가고 그냥 `.claude/` 내부에만 영구히 남음(RFC 저장소 성격). GC처럼
quad 밖 배경지식이 깊은 주제는 새 티어 없이 "quad 활용법만 심화에, 일반
개념은 외부 링크"로 처리. 실제 콘텐츠 분류(초심자 core loop 목차 초안,
파일별 분류, 심화 에세이 후보 15개)는 `research/documentation-content-map.md`.

**2. quad vs Fusion/Vide/react-lua 정직 비교 — 3개 에이전트가 실제
소스/웹 리서치로 검증.** `research/framework-comparison-findings.md`.
요지: quad의 Slot 단일 마운트 가드·열린 우선순위 축·명시적 의존성·다이아몬드
dedup은 실 소스 근거로 확인된 진짜 강점(Fusion `Children.luau`의 TODO
주석, Vide `mount.luau`의 중복 체크 부재, Vide 자신이 `todo.md`에 미해결로
남긴 diamond 문제 등). 반대로 use-after-destroy 검증 안전망 부재·`:With`
정적 의존성·Store dot-access 할당 비용 3가지는 고칠 만한 약점으로 식별(3번은
이후 4번 논의로 이미 해소됨). GC-native 리스크·암묵 추적 대비 보일러플레이트·
Tween 비합성성·"지금 트리 상태" 파악 어려움은 의도된 트레이드오프로 "고친다"
개념 자체가 안 맞음. 성숙도 격차(quad 구현 0줄)는 정직하게 명시.

**3. 위 1·2번에서 파생된 실행 항목**: 아직 결정 아님, `research/
documentation-plan.md`/`framework-comparison-findings.md`의 "다음 단계"에
남겨둔 사용자 판단 대기 항목들(문서화 착수 시점, 프레임워크 비교에서 나온
개선안 반영 여부/시점) 그대로 참고.

**4. Source가 State를 구조적으로 만족 — Store/State/Source 핵심 메커니즘
재구성, base 문서 전부 반영 완료.** `store.key`의 타입 문제(레코드 타입
`{key: State<number>}`가 읽기/쓰기 비대칭이라 Luau 타이핑이 안 맞음)를
풀다가 나온 더 근본적인 재구성:
- **`Source<T>`가 구조적으로 `State<T>`를 만족**(단방향 호환, Svelte
  `Writable<T> extends Readable<T>`와 같은 모양) — `.value`/`:Get()`/
  `:With`/`:Compute` 전부 지원 위에 `:Set(value)`/`:Emit()` 추가. `:With`/
  `:Compute`는 Source에서도 항상 `State<U>` 반환(구현은 metatable `__index`
  델리게이션, `Modifier`의 제네릭 `__index` 트릭과 같은 패턴이라 로직
  중복 없음). 이 서브타입 관계는 `quad2-try`에서 기각한 컴포넌트/클래스
  OOP 상속과 다른 층위(프리미티브 타입 간 구조적 서브타이핑일 뿐, 사용자가
  짜는 클래스 계층 구조가 아님)라 그 금지와 안 부딪힘.
- **`RefSource`(store 슬롯 전용 타입 중간안)와 그 전신인 `StoreSource`
  프록시(2026-08-04 세션에서 confirmed였던 것)는 전부 폐기.** Store는
  이제 "이름 붙은 Source 모음, 그 이상 아님" — `store.key`는 Store 생성
  시 이미 만들어둔 진짜 Source 객체를 그대로 반환(별도 wrapper 생성/캐싱
  단계 자체가 사라짐, 이전에 검토한 "State를 weak table로 캐싱"보다도
  쌈). v1이 타입 없던 시절 습관으로 모든 값을 Store에 몰아넣은 건 "당시엔
  편해서"였지 지금 그대로 가져올 이유가 아니라는 게 사용자의 회고적
  재평가 — 그 재검토가 이번 단순화로 이어짐.
- **`store.key = value`(`__newindex`) 폐기, `store.key:Set(value)`로
  전환** — 이유 둘: (a) 레코드 타입 `{key: Source<number>}`가 읽기/쓰기
  둘 다 같은 타입이어야 Luau 타이핑이 깨끗한데 대입 문법을 유지하면
  비대칭이 남음, (b) `=`는 관례상 "즉시 커밋되는 부작용 없는 쓰기"를
  암시하는데 quad는 실제로 lazy(무효화 신호만 쏘고 재계산은 관측 시점에)라
  대입 문법이 실제 동작과 정서적으로 안 맞음(사용자 논거). `Store:Emit(key)`도
  같은 이유로 `source:Emit()`(key 인자 불필요)로 이동 — 같은 일 하는
  두 번째 경로를 안 남긴다는 원칙과 일치.
- **검증 필요, M0 스파이크에 항목 추가됨(`ROADMAP.md`)**: Source의
  `:Compute` 시그니처가 자기 자신과 `State<U>`를 동시 참조하는 제네릭
  메소드라 Luau 솔버가 재귀 타입 조합에서 안 막히는지 확인 필요. 자기
  참조 self 타이핑 자체는 흔하고 안전하나, `State<T>`가 거꾸로 `Source`를
  참조하는 **상호 재귀**는 Luau의 알려진 취약 패턴이라 피해야 함 —
  `State<T>`를 `Source` 참조 없이 독립적으로 먼저 정의하고 `Source<T>`만
  단방향으로 `State<T>`를 참조하게 두면 이 위험을 피할 수 있어 보이나
  확정 아님. 타입은 `&`(교차) 조합 대신 손으로 펼쳐 쓰는 쪽으로(사용자
  선호, 솔버 안정성 우선) — 이건 런타임 구현 델리게이션과 다른 축이라
  서로 안 부딪힘(타입은 펼치고 구현은 공유 가능).
- **반영된 파일**: `base/store-semantics.md`(신규 "Source가 State를
  만족함" 절이 최종 소스), `base/bind-system-plan.md`(온톨로지·타입 추론
  절 정정), `base/component-composition-plan.md`(`StoreSource`/타입
  유니온 절 재작성), `ROADMAP.md`(M0 항목 추가), `research/
  documentation-content-map.md`/`.claude/README.md`(참조 갱신). 이름
  자체(`Source`/`State`)는 여느 때처럼 "지금 할 일" 2번 용어 정리
  라운드까지 가칭.

