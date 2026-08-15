# 2026-08-15 두 번째 세션 — 콜백 파라미터 무주석 추론 전방위 재시도, `/code-review` 2회전 정합성 수정

## 배경

직전 세션(`2026-08-15-01`)이 `typeof(named fn)` 간접참조로 0-Y(반환
타입 leak)를 우회했지만, "콜백 파라미터는 여전히 명시 주석 필요"라는
캐비엇은 그대로 남겨뒀음. 사용자가 이 캐비엇에 대해 "제 손으로도
안 된다는 결론이 나오긴 했지만, 확실하다고 보기는 어려워 보인다"며
type function/메타테이블/제네릭 등 전방위 재시도를 요청 —
"확장 시도가 지금 설계에 영향 안 미치더라도 좋다"는 전제로 순수
탐색적 리서치 성격임을 명시.

## 1차 조사 — `type-recursive-issue-try-callback/` 신설 (에이전트 위임, spikes 00~19)

general-purpose 에이전트에 위임(luau 스파이크 다수 작성/실행이라
메인 컨텍스트 보호 목적). 결과:

- **근본 원인 재정정**: 재귀 자기참조 특유의 문제가 아니라 "제네릭이
  관여하는 함수 호출 인자로 넘긴 함수 리터럴엔 Luau가 컨텍스트 타입을
  전파하지 않는다"는 더 일반적 한계(재귀 없는 `Map<T,U>(arr,fn)`도
  똑같이 샘, 00번).
- **near-miss 두 개 발견, 둘 다 채택 안 함**: (a) `T`를 명시 중간
  변수로 먼저 고정하면 재귀형에서도 콜백 파라미터가 정확히 추론됨
  (09번), (b) 재사용 가능한 monomorphize 헬퍼 함수를 거치면 T별로
  손으로 다시 쓸 필요 없이 같은 효과(18번, 이번 조사의 가장 흥미로운
  발견). 둘 다 `state:Compute(fn)` 단일 호출을 2단계 체인으로 바꿔야만
  작동해 `typing-limits.md` §0 대전제(API를 타입 사정으로 비틀지
  않음) 위반으로 기각.
- `type function`으로 재귀 반환 자체를 지연 평가하는 시도는 여전히
  `stack overflow` 막다른 길(직전 리서치와 같은 결론 재확인).

`base/typing-limits.md` §1에 각주로 반영, `.claude/README.md` audit
색인에 신설 행 추가.

## `/code-review high` 1회전 — 문서 정합성 9건 + 미검증 각도 1건

메인 세션이 직접 검증 후 수정. 대부분 카운트/인용 stale(README
audit 개수 7→6, `luau-test/STATUS.md` 헤딩 7→6, `ROADMAP.md` M0
체크리스트 미갱신, `luau-test-first-run` 표의 스파이크 16 결과가
"❌ 실패"로 안 고쳐진 것 등 — 전부 프로젝트 자체 규율인 "배너뿐 아니라
본문도 고칠 것"이 재발한 사례).

**핵심 발견 1건**: 1차 조사 20개 formulation이 전부 **암묵 호출**만
시도했고, 코퍼스에 이미 실사용 중인 **이중 꺾쇠 명시적 제네릭
인스턴스화**(`Foo<<T,U>>(...)`, `base/attribute-plan.md`의
`AttributeKey<<T>>`, `type-recursion-issue/spikes/38/39/41`에 이미
있음)를 단 하나도 시도하지 않았음. 메인 세션이 직접 빠르게 재현해보니
quad 실제 self-핸들 계약에서 **부분 성공**(다운스트림 타입은 정확) +
이전과 다른 spurious 진단(read-only/read-write 불일치)이 섞여 나옴 —
새 각도라 판단해 후속 조사로 위임.

## 후속 조사 — `<<T,U>>` 명시적 인스턴스화 (에이전트 위임, spikes 20~33+21b)

- **spurious 진단 원인 규명**: `08-metatable-BUG`(직전 세션의 solver
  버그)와 다른 문제 — duck-typed 콜백 파라미터가 "읽기만 관측돼
  read-only로 잡히는데 기대 타입은 기본 read-write"인 단순 가변성
  불일치. 쪼개기(②)+`Get` 필드에 명시 `read` modifier로 완전 해소됨.
- **leaf 호출에선 실제로 sound하게 성립**(체이닝 depth 3까지 완전
  클린, 음성 대조군도 정확히 잡힘).
- **partial instantiation은 이름이 아니라 선언 순서로 바인딩** — `U`만
  주려 해도 `T`부터 채워짐, 재귀형에서 Internal error로 깨짐(21/21b).
- **최종 채택 안 함**: 매 호출마다 이미 self로부터 결정되는 `T`까지
  중복 명시 + 콜백을 쓰기도 전에 반환 타입 `U`를 미리 선언해야 하는
  부담이 지금 관례("파라미터에 타입 하나만 주석")보다 크고, `:Apply`
  중첩 자기호출은 여전히 안 풀림 — `typing-limits.md` §0 대전제상
  순손해.
- **함정 하나 추가 발견**: 쪼개기+`read`만 하고 명시 인스턴스화를 뺀
  암묵 호출은 겉보기엔 깨끗해 보이지만 음성 대조군을 전혀 못 잡는
  순수 duck-typing이었음(27 vs 28 대조).

`REPORT.md` §11 신설(TL;DR 갱신 포함), `typing-limits.md` §1엔 각주
포인터만(원칙 자체는 안 바뀜).

## `/code-review`(재사용 high) 2회전 — 정합성 9건

첫 회전이 새로 만든 문서/수정 자체에서 또 발견된 stale — 대부분
"수정하며 새 stale을 만드는" 패턴의 재발:

- `typing-limits.md` §1③의 "바뀌지 않는 것" 목록에 옛 솔버 거부
  캐비엇이 빠져있던 것(①만 그 캐비엇이 있고 ③엔 없었음) — 추가.
- §7 체크리스트 항목 1(무조건 ③ 쓰라는 투)과 항목 2(파라미터 추론엔
  ②도 같이 필요하다는 헤지)가 서로 부딪히던 것 — 항목 1에 "③은
  반환 타입 안전성만 고쳐줌, 파라미터 추론엔 부족" 경고 추가.
- **이 세션 자체의 작업이 세션 히스토리에 아직 안 남아있던 것** — 이
  파일이 그 반영.
- `CLAUDE.md`의 `.claude/audit/` 소개 bullet이 3개 폴더만 나열한 채
  최신 3개(fallback-xpcall/typeof/try-callback)가 안 반영돼 있던 것 —
  luau-test bullet과 같은 패턴으로 "나열 안 하고 README.md로 미룸"으로
  전환.
- `type-recursion-issue/REPORT.md`(0-Y 원래 리서치, 13차 세션 산출물)의
  "06/07/10 자유 함수로 빼면 재귀 유무 무관하게 통과" 서술이 실제로는
  틀렸음 — `06`은 `self: Box<A>`처럼 self 자신이 제네릭이라 실제로는
  duck-typing 오염 + TypeError가 남(직접 `luau-analyze --annotate`로
  재현 확인). `07`/`10`은 self가 모노몰픽이라 통과 — 진짜 분기점은
  "자유 함수인가"가 아니라 "self가 비제네릭인가"였음, 06을 13(self
  완전 자유 제네릭도 안 풀림)과 같은 편으로 재분류.
- 스파이크 개수 off-by-one 2건(README의 try-callback 34→35, 직전
  세션 로그의 typeof 폴더 14→15 — 둘 다 서브레터 파일(`21b`,
  `00b`/`00c`)을 안 세서 생긴 것).
- 직전 세션 로그가 "raw 값 콜백 + 50단 체이닝이 깨끗이 통과"를
  마치 확정 사실처럼 서술한 것 — 그 formulation은 파일로 저장 안 돼
  지금 재현 불가라는 정정 각주 추가(REPORT.md §5-1이 이미 밟은
  것과 같은 조치).

## 남은 것

`.claude/README.md`(audit `현재 6개` 카운트가 커밋 시점 기준으로는
아직 5개였던 것 — 커밋 안 한 현재 작업 트리 기준으로는 이미 6개로
정확해서 별도 조치 없음, 커밋되면 자동 해소), 3건은 code-review가
검증 단계에서 이미 refuted 처리(허위 양성).

## 관련 문서

`.claude/audit/type-recursive-issue-try-callback/`(REPORT.md + spikes
35개), `base/typing-limits.md` §1/§7, `.claude/README.md`,
`CLAUDE.md`, `.claude/audit/type-recursion-issue/REPORT.md`,
`.claude/session/2026-08-15-01-typeof-recursive-generic-workaround.md`.
