# 2026-08-15 — `typeof(named fn)` 간접참조로 0-Y 우회 실측, `luau-test/16` 복구

## 배경

사용자가 Luau 설계자와 가까운 사람과의 대화에서 힌트를 얻어
`test-ignoreme.luau`를 직접 작성 — `Compute`류 재귀 제네릭 메소드를
타입 안에 인라인으로 쓰지 않고 이름 붙은 top-level 함수로 선언한 뒤
`typeof(그함수)`로 필드 타입만 참조하면 `base/typing-limits.md` 1번
(0-Y, 재귀 제네릭이 다른 타입 인자로 자기를 반환하면 조용히
`Unifiable<Error>`로 새는 문제)이 안 생기는 것 같다는 관찰을 가져옴.
"모든 typeof를 flatten하려면 비용이 많이 들어 사용 시점에야 계산하는
것 같다 — 이걸로 재귀를 분리하고 지연 확장할 수 있지 않을까"라는
가설. 사용자가 이후 `test2`/`test3-ignoreme.luau`로 `Modifier`의
`__index`+`table.clone` 체이닝(이미 확정된 패턴, `typing-limits.md`
§6)과 같은 계열인 `setmetatable<{...}, {__index: typeof(fn<<T>>())}>`
확장도 직접 시도해봄("내 실험으론 여기까지").

같은 세션에 사용자가 advisor(Opus)를 조언자로 추가 — "차근차근
typing-limits를 풀어보자, 오래 걸려도 되니까 정확하게 처리해줘"라는
요청으로 본격적인 다단계 실측을 진행.

## 방법론

`audit/type-recursion-issue/`(0-Y 원래 실측)와 동일한 3단 교차검증을
매 formulation에 적용: (1) `luau-analyze --annotate`로 실제 추론된
타입을 눈으로 확인(진단 0건 ≠ 안전), (2) 양성 대조군(정상 사용이
진짜 통과하는지), (3) 음성 대조군(명백히 틀린 사용이 진짜 에러
나는지). 여기에 이번 세션에서 추가한 것: 체이닝 깊이 1/3/5/8/50 스윕
+ 각 단계 negative control, `--solver=old` 대조, 실제 quad `Compute`
계약(콜백이 lazy self 핸들을 받음 — raw 값이 아님)으로 정합성 재확인.

## 진행 과정 (시행착오 포함)

1. **1차 확인**: `test-ignoreme.luau`를 `--annotate`로 돌려보니 사용자
   가설이 맞았음 — `Compute` 결과가 `Unifiable<Error>`가 아니라 진짜
   구조 타입으로 잡힘, `const`는 무관(`local function`도 동일).
2. advisor 호출 — "체이닝 깊이가 관건, 매트릭스로 통제 변수 실험하라"는
   조언. 4-스타일 매트릭스(인라인/typeof/분리+인라인/분리+typeof) 작성,
   `read` 일관성 통제.
3. **체이닝 깊이 결정적 테스트**: depth 1~50, 각 체크포인트 negative
   control — **전부 통과, hover 타입 크기도 깊이와 무관하게 일정**(진짜
   지연/공유 평가, eager 재료화 아님). 이 시점에 advisor의 "체이닝이
   전부를 결정한다"는 우려는 해소.
4. 인터넷 재연결로 세션 재개, 사용자가 만든 `test2`/`test3` 확인 —
   `setmetatable` + 명시 제네릭 인스턴스화(`<<T>>()`) 패턴이 **콜백
   파라미터까지 무주석 자동 추론**되는 걸 발견(raw 값 파라미터 한정).
   이걸 진짜 재귀 `Compute<U>: Box<U>`로 확장해보니 처음엔 완벽해
   보였음(체이닝 50단, 무주석 파라미터, 즉시 LHS 오타입 검출까지 전부
   통과 — **[2026-08-15 정정, `/code-review` 지적] 이 raw-값·50단
   버전은 파일로 저장되지 않아 지금은 재현 불가**, 사용자와 직접
   대화하며 확인한 중간 관찰일 뿐 — 최종 결론은 이 서술이 아니라
   `REPORT.md` §5-1/`typing-limits.md`가 소스) — 그러나 quad의
   **실제 계약**(콜백이 raw 값이 아니라 self
   핸들을 받음)으로 정정하자 두 가지 문제가 연쇄로 드러남: (a) 파라미터
   무주석 시 duck-typing으로 새서 존재하지 않는 메소드도 안 잡히는
   불건전, (b) 파라미터를 명시 주석해도 **콜백 반환 타입이 self의
   원래 T와 다르면(=Compute가 존재하는 이유 그 자체) 올바른 대입에도
   모순되는 진단 두 개가 동시에 남는 솔버 버그**.
5. advisor 재호출 — "chaining depth가 아니라 self-handle 파라미터 여부
   × U≠T 여부가 진짜 축이었다. quad 계약은 정확히 깨진 사분면에 있다.
   `setmetatable` 없이도 재현되는지부터 싸게 확인하라"는 조언.
6. 확인 결과 **`setmetatable`을 빼면 모순 버그가 사라짐** — 순수
   `typeof`(분리 없음) + self-핸들 파라미터 명시 주석만으로 타입이
   바뀌는 3단 체이닝, 콜백 안 재귀 self 호출, 존재하지 않는 메소드
   거부까지 전부 완전히 깨끗하게 통과. **이게 최종 승자 formulation.**
7. 최소 재현(9줄)으로 `setmetatable` 버그를 격리해서 남김(quad와
   무관한 Luau 0.733 솔버 이슈로 판단, 업스트림 제보는 사용자 판단).

같은 세션에 병행: `luau-test/rewrite-required/16-type-store-key-
typefunction.luau`(0-A/1-10 관련, `types.newfunction` 시그니처
불일치로 깨져있던 스파이크)를 `luau.org/types-library` 실제 문서
대조로 복구 — 원인은 설계 문제가 아니라 API 버전 드리프트(두 번째
인자가 배열이 아니라 `{head=..., tail=...}` 레코드)였음. 별도로
type function으로 0-Y 자체(재귀 `Compute`)를 우회하는 시도는
`stack overflow`로 막다른 길임을 확인.

## 결과 — base 반영

- `base/typing-limits.md` §1에 **③ 선언 스타일 규약**(인라인 대신
  이름 붙은 함수 + `typeof`) 추가 — ①(명시 바인딩 강제)을 대체하지
  않는 보강. `setmetatable` 확장은 "시도했지만 채택 안 함"으로 명시,
  이유와 최소 재현 경로 남김.
- `base/typing-limits.md` §5를 "미검증" → **"검증 완료"**로 승격.
- `luau-test/rewrite-required/16-...` → `luau-test/done/16-...`
  (복구 완료), `STATUS.md`/`README.md` 동기화(rewrite-required 7→6,
  done 13→14).
- `research/pre-implementation-audit.md` 1-10에 실측 완료 포인터 추가.
- 전체 실측 원문+스파이크 15개: `audit/type-recursive-issue-with-typeof/`
  (`REPORT.md` + `spikes/`, 사용자가 만든 `test-ignoreme`/`test2`/`test3`도
  `00`대 파일로 보존).

## 교훈

- **"체이닝 깊이가 관건"이라는 최초 가설은 틀렸음** — 실제 결정 축은
  "콜백 파라미터가 self 핸들인가 raw 값인가" × "콜백이 T와 다른 타입을
  반환하는가"였음. 겉보기에 그럴듯한 축(깊이)을 먼저 실측으로 배제한
  뒤에야 진짜 축이 드러남 — 매 formulation을 실제 API 계약(quad의
  lazy self 핸들 계약)으로 재확인하지 않았다면 "완벽한 해법을 찾았다"고
  잘못 결론 내릴 뻔했음.
- **진단 0건이 안전을 뜻하지 않는다는 원칙(1번의 원래 교훈)이 이번엔
  반대 방향으로도 함정이었음** — `setmetatable` 무주석 파라미터
  케이스는 진단 0건이었지만 duck-typing으로 새서 존재하지 않는
  메소드도 안 잡는 **불건전**이었음. "에러가 안 남 = 좋음"이 아니라
  매번 "존재하지 않는 메소드 호출" 같은 건전성 음성 대조군을 같이
  둬야 함.
- advisor를 두 번 불러 각각 "다음에 뭘 확인해야 최소 비용으로 결론이
  뒤집힐 수 있는지"를 물은 게 결정적 — 혼자였다면 `setmetatable`
  formulation을 "완전한 해법"으로 그대로 base에 반영했을 가능성이 높음.
