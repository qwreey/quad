# 2026-08-14 열한 번째 세션 — 코퍼스 전체 감사(서브에이전트 6개 병렬) + `canBound`/`canExecute` 재분리, `question.md` 0-W 해소

## 코퍼스 감사

사용자 요청으로 `.claude/` 전체를 감사 — 먼저 `python3 .claude/tools/doc-check.py`로
기계 점검(ERROR 0 확인)한 뒤, `base/`(3분할)·`research/`+`reference/`·
`luau-test/`+`audit/`+`archive/`·루트 인덱스 파일(CLAUDE.md/ROADMAP.md/
HUMAN_TODO.md/question.md/`.claude/README.md`) 6개 영역을 서브에이전트로
병렬 감사, 보고된 항목을 직접 재확인 후 실제 사실 오류만 반영. 총 15개
파일 수정:

- `modifier-plan.md` 2곳 — `Brand`/`isState` 정의 인용이 9차 세션 문서
  분할 후 옛 경로(`bind-system-plan.md`)를 계속 가리킴 → `brand-plan.md`로
  정정
- `tag-plan.md` — `TagHandler.priority` 의사코드가 `HANDLER_PRIORITY_FALLBACK`
  이어야 하는데 `<일반>`으로 남아 같은 문서의 "패키지 배치" 절과 자기모순
- `typing-limits.md` — 스파이크 경로가 `review-required/08`로 stale(13차
  세션에 `done/08`로 이동)
- `store-plan.md` — `store.key` 타입함수 접근을 "실측 확인"처럼 과장
  서술해 `typing-limits.md`(스파이크 `16`은 여전히 `rewrite-required/`,
  미검증)와 모순 → caveat 추가
- `additional-primitives-plan.md` — "새로 열린 질문 없음" 배너가 이후
  세션에 추가된 열린 질문 2개(Attribute unset 유틸, `State<State<T>>`
  평탄화)와 자기모순
- `comparison-charm.md`+`.claude/README.md` — "quad가 미결로 남긴 previous
  값 비교 문제"라며 존재하지 않는 문서(`additional-primitives-plan.md`)를
  잘못 인용 — 실제로는 `source-state-plan.md`에 이미 확정된 `:Compute`의
  `previous` 인자
- `luau-test/STATUS.md`/`README.md` — `canExecute` 재정정 세션 번호가
  "세 번째"(STATUS.md 헤더 1곳, README.md 2곳)와 "다섯 번째"(같은 파일
  본문, archive, CLAUDE.md)로 갈라짐 — archive 3곳 교차확인 결과
  "다섯 번째"가 맞음, `05`(8차 세션 이동)도 README 테이블에 누락돼 있어
  보강
- `question.md`/`HUMAN_TODO.md` — 0-W가 "M4 구현 세부만 막음"이라
  서술했는데 실제 `Ref` 구현은 M8 — 정정, `ROADMAP.md` M8에 포인터 추가
- `question.md` — Debounce/Throttle "남은 열린 질문 4개"가 실제
  `debounce-throttle-plan.md` 12절엔 6개(항목 3/7 누락) → 개수 서술
  제거하고 소스 문서로 위임
- `CLAUDE.md` 자기 자신 2곳 — `luau-test/rewrite-required` 나열이
  `05`(8차 세션 합류)/`04`/`19`(14차 세션 합류)를 빠뜨려 stale, "지금
  할 일" 절엔 "더 이상 대기 항목 아님"이 바로 위 문단과 자기모순 →
  나열 자체를 걷어내고 `STATUS.md`로 위임

`doc-check.py` ERROR 0 유지 확인. 발견 없음으로 보고된 영역:
`architecture`/`attribute`/`bind-system`/`blocker`/`brand`/
`component-composition`/`dispatch-core`/`effect`/`event`/`fallback`/
`lifecycle-hooks`/`lifecycle-pattern`(*아래 별도 발견 있었음, 감사 라운드
자체는 통과 보고했으나 이후 논의 중 직접 발견*)/`module-lifecycle`/
`onchange`/`purity-and-effects`/`ref`/`relate`/`source-state`/`tween`/
`ui-shorthand-plan`, `debounce-throttle`/`debug-tooling`/
`documentation-*`/`framework-comparison`/`operator-sugar`/
`pre-implementation-audit`/`v1-compat-plan`, `comparison-fusion-vide`,
`quad-v1-architecture`, `archive/` 23개 전체, `audit/` 나머지.

## `canBound`/`canExecute` 재분리, `question.md` 0-W 해소

감사 완료 후 사용자가 `question.md` 0-W(같은 `Ref`가 두 자리에 동시에
놓이는 걸 막을지)에 대해 이미 마음속으로 결정해뒀던 것을 풀어놓음 — 선택지
(a)(즉시 error) 확정, 메커니즘은 `RefLeafHandler`가 `bindLifetime`/
`unbindLifetime`을 재사용(새 전용 `Relate` 불필요 — `bindLifetime`이 이미
내장한 이중 바인딩 가드를 그대로 타면 됨). 그런데 이 가드가 지금
`canExecute`라는 이름으로 되어 있는 게 이상하다는 지적 — `canExecute`는
"emit 처리로 State 전파 루프가 Effect/Observer를 발화시켜도 되는가"를
묻는 함수인데, `Ref`는 emit 전파에 참여조차 안 하니 그 이름을 쓰는 게
개념적으로 안 맞음. "bound 문맥"(이미 묶여 있는가 — `bindLifetime`/
`Observer:Subscribe()`의 이중 등록 가드가 묻는 것)과 "execute 문맥"(지금
발화해도 되는가 — State 전파 루프만 묻는 것)은 오늘 판정값이 같아도
서로 다른 질문이라는 게 사용자 논거.

**해법(사용자 제안) — 이름은 둘, 판정 로직은 하나.** 2026-08-14 다섯
번째 세션이 "canBound 폐기, canExecute로 통합"했던 걸 부분적으로 되짚어
`canBound`를 별도 진입점으로 재도입하되, 실제 gcconn/`.Subscribed` 체크는
비공개 헬퍼 `isBoundAlive(value)` 하나에만 두고 `canBound`/`canExecute`
둘 다 그 헬퍼를 부르는 얇은 래퍼로 — 코드 중복 없이 호출부 의미만 분리.
**다섯 번째 세션이 고친 것(2-인자 `canExecute(inst,value)`가 오염이었다는
것, `unbindLifetime`/`canExecute`가 `inst`를 안 받아야 한다는 것)은 전부
그대로 유효** — 되짚은 건 "합칠지 나눌지"라는 좁은 하위 결정뿐.

반영: `base/lifecycle-pattern.md`(정본, `isBoundAlive`/`canBound`/
`canExecute` 코드 전면 재작성 + "canBound vs canExecute" 절 신설),
`base/ref-plan.md`("이중 배치 방지" 절 신설, `RefLeafHandler` 의사코드에
`bindLifetime`/`unbindLifetime` 호출 추가), `archive/
canexecute-inst-arg-reversed.md`(재분리 경위 addendum), `question.md`
0-W 항목을 `archive/question-resolved.md`로 이전, `ROADMAP.md`
M2/M3/M8 체크리스트, `base/source-state-plan.md`의 "이중 바인딩 금지"
절(게이트를 `canBound`로 교체), `base/effect-plan.md`(UB 절 갱신 +
"세 번째 세션" 오표기를 "다섯 번째"로 같이 정정 — lifecycle-pattern.md에서
도 같은 오표기 발견해 정정), `base/architecture.md`(소스 트리 주석),
`base/dispatch-core-plan.md`/`research/pre-implementation-audit.md`
(절 제목 인용 갱신), `luau-test/README.md`/`audit/
gcconn-trick-verification.md`(스파이크 `10` 재작성 시 반영할 새 게이트
이름 갱신), CLAUDE.md 자신("지금 할 일" 0번 — `question.md`의 "결정
대기" 절이 이제 완전히 빔).

`doc-check.py` ERROR 0 유지. 새로 연 설계 질문 없음 — `Slot`의
`claimOwner`/`Attribute`의 이름 claim처럼 `Ref`도 기존 프리미티브
(`bindLifetime`)를 재사용하는 것으로 끝남.

## 후속 — `Frame1{Ref=r}` 표기 정정, `PreRef`/`PostRef`/`Observer`/`Effect`
동적 경로 가드를 `HANDLER_PRIORITY_FALLBACK`으로 통일

사용자가 0-W 손 트레이싱의 `Frame1 { Ref = r }` 표기를 질문 — `Ref`는
항상 children **배열** 리터럴로만 놓이므로 `k`가 문자열 `"Ref"`일 리
없고(실제로는 배열 인덱스, 숫자), 순수 설명 편의 표기였음을 확인.
`base/ref-plan.md`의 새 절과 `archive/question-resolved.md`에 보존된
원본 트레이싱에 정정 각주 추가(원본 자체는 역사 보존 목적으로 안 지움).

이어서 사용자가 `PreRef`/`PostRef`/`Observer`/`Effect`가 non-number
키(해시 파트 등 동적 경로)로 들어오면 어떻게 할지 질문 — 처음엔 "`k`
무관하게 매치해서 `process`에서 에러"(Attribute처럼 process 도중
에러내는 기존 패턴)를 제안했다가, 곧바로 스스로 "가장 아래(FALLBACK)에
까는 게 맞다"고 정정. 결론: `PreRef`의 기존 "동적 경로 가드" Handler가
이미 `k` 무관 매치+에러였지만 우선순위가 명시돼 있지 않았던 걸
`HANDLER_PRIORITY_FALLBACK`으로 확정 — 하드 블록이 아니라 `Tag`/
`Attribute`와 같은 "base가 소유하되 평범한 우선순위의 다른 Handler가
있으면 그쪽이 이기는" 자리로 만들어, 지금은 항상 에러가 나지만 나중에
named 자리 바인드 같은 실제 기능이 확정되면 base 가드를 안 건드리고
그 기능의 Handler만 등록하면 자동으로 우선하게 됨. 같은 패턴을 `PostRef`
(기존 거울상 가드에 우선순위 추가)와 `Observer`/`Effect`(기존엔 전용
가드가 없어 범용 "매치 실패=에러" 경로로 우연히 같은 결과를 내고
있었음 — 이번에 전용 `HANDLER_PRIORITY_FALLBACK` 가드를 신설해 넷 다
명시적으로 통일, 동작 자체는 안 바뀌고 에러 메시지만 명확해짐)에도
적용. `base/ref-plan.md`/`base/source-state-plan.md`/`base/effect-plan.md`/
`ROADMAP.md` M8/M3 반영, `doc-check.py` ERROR 0 유지.

이어서 사용자가 Tag/Attribute의 미주입 백엔드 실패 모드(base 기본
스텁이 명확한 에러를 낸다는 것)를 확인한 뒤, "미지원"과 "미등록"을
구분 안 하는 게 맞는지 질문 — 확정 원칙(`pre-implementation-audit.md`
1-4, 스텁 입장에선 원천적으로 구별 불가) 그대로 재확인. 사용자가
"정말로 미지원인 백엔드는 FALLBACK보다 높은 우선순위로 자기 Handler를
등록해 명시적으로 에러내면 된다"는 관례를 문서에 말로만 적어두자고
제안(강제 메커니즘 아님, 대부분 백엔드가 결국 지원할 거라 실익은
크지 않지만 opt-in 옵션으로) — `base/dispatch-core-plan.md`의 "base가
소유하는 핸들러와 주입되는 엔진 op" 절에 관례 bullet 추가.

**곧바로 더 단순한 안으로 정정**: 사용자가 "그런 환경은 addTag든 뭐든
nop일 수도 있으니, [모든 백엔드가] 이 op들을 다 등록하도록 해야 하고,
대신 [미지원이면] 에러로 '구현 안 되어있다'를 내도록 [팩토리가 직접
작성]하면 된다"고 제시 — 방금 추가한 "Handler 우선순위로 덮어씌우기"
관례를 철회하고, 대신 **op 등록 자체를 필수로** 바꿈: 백엔드 팩토리는
`addTag`/`removeTag`/`setAttribute`를 항상 명시적으로 채워야 하고(빈
자리로 두고 base의 미주입 스텁에 기대지 않음), 지원 안 하는 op은
`nop`(정당한 구현 선택)이든 `function() error("구현 안 됨") end`(명시적
에러)든 팩토리가 직접 등록. Dispatch Handler나 우선순위 조정이 전혀
불필요해서 이전 안보다 훨씬 가벼움 — 부수 효과로 "provider 미주입"과
"미지원"도 자연히 갈라짐: 제대로 된 팩토리는 항상 세 op를 다 채우므로,
base 스텁이 실제로 매치되는 건 "어떤 팩토리도 안 돌았다"는 훨씬 좁은
경우로 좁혀짐. `base/dispatch-core-plan.md`/`base/module-lifecycle-plan.md`
반영, `doc-check.py` ERROR 0 유지.

**다시 한 번 정정 — 사용자가 이번엔 op 필수화만으론 부족하다고 지적.**
`addTag` 에러는 `TagHandler.process` 본문 안, 즉 `tagNameMap` 같은 부기가
이미 일부 mutate된 *뒤*에야 남 — `Tag()`가 "바인드는 됐는데 엔진 반영만
실패"인 반쪽짜리 상태로 남을 수 있어 원자적 실패가 아님. 사용자 결론:
"그래도 여전히 Tag()는 바운드 가능함... 핸들러도 1만큼 높은 우선순위
채워주는 게 가장 안전하고 사실상 무료" — op 필수화(위)는 유지하되,
**추가로** 미지원 백엔드는 `HANDLER_PRIORITY_FALLBACK + 1` 우선순위의
순수 가로채기 Handler(`isHandlable = isTag(v), process = error(...)`)도
등록해 `TagHandler.process` 자체가 아예 안 불리게(부기 mutation 0회) 하는
걸 권장으로 추가 — 매치된 Handler 하나만 실행되는 기존 Dispatch 규칙을
그대로 이용하는 것이라 새 메커니즘 없음. `base/dispatch-core-plan.md`/
`base/module-lifecycle-plan.md` 재반영, `doc-check.py` ERROR 0 유지.

**세 번째 정정 — 사용자가 "철회 아님, 전제 자체가 틀렸다"고 바로잡음.**
어시스턴트가 "`TagHandler`/`AttributeKeyHandler`는 quad-base가 자기
모듈 로드 시점에 스스로 등록한다"고 잘못 전제하고 "+1 Handler" 안을
철회했었는데, 사용자가 정정: **Tag/Attribute는 모든 백엔드의 필수
구현이 아니고, quad-base는 이 Handler들을 완성된 값으로 export만 할
뿐 스스로 Dispatch에 등록하지 않는다.** 백엔드 팩토리가 둘 중 하나를
선택: **(A) 지원함** — quad-base Handler를 그대로 등록 + `addTag`/
`removeTag`/`setAttribute` 실제 구현 주입, **(B) 지원 안 함** — 그
Handler는 등록하지 않고 `HANDLER_PRIORITY_FALLBACK + 1` 우선순위의
얇은 "미지원" 가로채기 Handler만 등록(op 주입 자체가 불필요 — 호출할
주체가 그 백엔드의 레지스트리에 없음). 이 모델이면 "op 에러가 부기
mutation 뒤에 지연 발생"하는 문제 자체가 안 생김 — (B)를 고른 백엔드에서
부기를 mutate하는 `TagHandler.process`가 아예 안 불리기 때문. 앞서
검토했던 "op 필수화"와 "process 재정렬" 두 안은 전부 이 등록-선택
모델로 대체되어 불필요해짐. `base/dispatch-core-plan.md`(정본, 전면
재작성)/`base/module-lifecycle-plan.md`/`base/tag-plan.md`/
`base/attribute-plan.md`/`base/architecture.md` 반영, `doc-check.py`
ERROR 0 유지.

**네 번째, 최종 정정 — "등록-선택 모델" 자체가 틀렸음, 사용자가 바로잡음.**
사용자: "HANDLER_PRIORITY_FALLBACK까지 등록 안한다 했는데, 개소리 ㄴㄴ
HANDLER_PRIORITY_FALLBACK는 아무 등록 없는데 처리하려 할 때 방어까지
포함하는 애임. 기본 등록은 필요함." **최종 확정 모델**: `TagHandler`/
`AttributeKeyHandler`/`AttributeGroupHandler`는 quad-base가 모듈 로드
시점에 `HANDLER_PRIORITY_FALLBACK`으로 **스스로 등록**(모든 백엔드가
자동으로 부기를 얻음, FALLBACK 밴드의 존재 이유 자체가 이 "기본
안전 동작 제공"임). `addTag`/`removeTag`/`setAttribute`만 백엔드
팩토리가 채우는 타입 계약이고, 안 채운 슬롯의 base 기본값은 "그럴듯한
기본 동작을 추측"하지 않고 **명시적으로 에러내는 스텁**(조용한 no-op은
provider 초기화를 잊은 실수를 가려버려서 기각). 더 명확한 메시지나
진짜 원자적 실패(부기 mutation 0회)를 원하는 백엔드만 **opt-in으로**
`HANDLER_PRIORITY_FALLBACK + 1`짜리 가로채기 Handler를 추가로 등록—
이게 필수 요구사항이 아니라 선택적 업그레이드라는 게 핵심(base 기본
스텁 하나로도 `AttributeGroupHandler`의 "부분 실패 경로" 원칙만으로
충분히 안전). `base/dispatch-core-plan.md`(정본, 다시 전면 재작성)/
`base/module-lifecycle-plan.md`/`base/tag-plan.md`/
`base/attribute-plan.md`/`base/architecture.md` 재반영, `doc-check.py`
ERROR 0 유지.

**교훈**: 이번 라운드는 네 번 연속 정정이 있었음(op 위치 우선순위 →
op 필수화 → 등록-선택 모델(틀림) → base가 스스로 등록(최종)) — 매번
"왜 이게 맞는지"를 서둘러 확정하기 전에 실제 아키텍처 전제(누가
Dispatch.addHandler를 부르는가)부터 정확히 확인했어야 했음. 이 전제
하나가 중간 두 라운드의 결론을 전부 무효화시켰음 — 확신 없는 아키텍처
주장은 재확인 없이 단정하지 말 것.

## 후속 — 세션 전체 자기 감사(사용자 요청 "다른곳에도 실수한거 있는지 찾아봐")

`git diff`로 이 세션에서 건드린 25개 파일 전체를 처음부터 다시 정독 —
`canBound`/`canExecute` 재분리, `Ref` 0-W 해소, PreRef/PostRef/Observer/
Effect 동적 경로 가드, Tag/Attribute 등록 모델, 그리고 최초 코퍼스
감사 15건 전부 논리적 일관성 재확인. 실제 문제 3건 발견·수정:

1. **`HUMAN_TODO.md`가 0-W 해소 이후에도 "남은 건 0-W" 그대로 방치돼
   있었음** — 세션 도중 `question.md`/CLAUDE.md는 0-W 해소를 반영했는데
   `HUMAN_TODO.md`만 그 전 라운드(M4→M8 정정)에서 멈춰 있던 stale 갱신
   누락. "결정 대기 절 자체가 비어있음"으로 정정.
2. `base/ref-plan.md`의 "이중 배치 방지" 절에 편집 중 생긴 어색한 줄바꿈
   (문장 중간에 orphan line) — 순수 포맷 정리.
3. **Tag/Attribute 등록 모델을 재정리하며 `tag-plan.md`/`attribute-plan.md`의
   "백엔드가 통째로 다르게 처리하고 싶으면 override 가능" 문장을 실수로
   빠뜨림** — "미지원 신호" 용도(opt-in `FALLBACK+1` 가로채기)만 남고
   "알고리즘 전체 교체" 용도(그냥 더 높은 우선순위로 자기 Handler 등록)가
   누락돼 있었음. 둘 다 유효한 별개 용도라 양쪽 파일에 복원.

나머지(canBound/canExecute 코드 블록의 순환·호출부 일관성, Ref
bindLifetime/unbindLifetime 배치, FALLBACK 우선순위 값들, 세션 로그·
CLAUDE.md 서술과 실제 base/ 반영 내용의 일치)는 전부 문제 없음 확인.
`doc-check.py` ERROR 0 유지.

## 후속 — `/code-review high`가 잡은 3건 추가 발견·수정

사용자가 백그라운드로 `/code-review high`를 돌림 — 위 자기 감사에서
놓친 진짜 문제 3건을 잡아냄(전부 "canBound 폐기"라는 5차 세션 당시의
서술이 11차 세션 재도입 이후에도 안 고쳐진 곳들, 자기 감사가
`git diff`로 이 세션이 **건드린** 파일만 훑어서 **안 건드린** 파일 속
5차 세션 원본 서술은 놓쳤던 사각지대):

1. `audit/gcconn-trick-verification.md`의 상단 배너(9-14행, 이 세션이
   그 아래 섹션만 고치고 이 배너는 안 건드렸음)가 "canBound는 폐기됐고
   게이트는 canExecute 하나"라고 여전히 서술 — 바로 몇 줄 아래(이번에
   고친 섹션)와 정면 모순. 재정정.
2. `.claude/README.md`의 `lifecycle-pattern.md`/`question-resolved.md`/
   `canexecute-inst-arg-reversed.md`/`audit/` 인덱스 행 4곳 — 전부 이
   세션 동안 한 번도 안 열어봤던 파일이라 5차 세션 서술("canBound
   폐기")이 그대로 남아있었음. 전부 정정.
3. `luau-test/STATUS.md`의 스파이크 `10` 재작성 가이드 — "이중 바인딩
   게이트는 canBound가 아니라 canExecute로 쓸 것"이라고 옛 모델을
   **재작성 지침으로 명시**하고 있었음(가장 심각 — 이대로 따라 재작성하면
   또 틀린 스파이크가 나옴). 재정정.
4. `question.md`의 "용어 정리" 절(canExecute 이름 논의)도 "canBound의
   몫까지 canExecute가 겸함"이라는 5차 세션 전제 위에 서 있어서 같이 정정.

**교훈**: `git diff`만으로 하는 자기 감사는 "이 세션이 건드린 파일"의
내부 일관성만 보고, "이 세션이 안 건드렸지만 이 세션의 결정 때문에
stale해진 파일"은 놓침 — 이번처럼 이름 하나(`canBound`)가 재도입되면
그 이름을 인용하는 **모든** 파일을 grep으로 전수 스캔해야 하는데, 처음
자기 감사 땐 "내가 고친 파일들"만 재확인하고 "canBound"라는 문자열
자체로 전체 코퍼스를 훑지 않았음. `doc-check.py` ERROR 0 유지.
