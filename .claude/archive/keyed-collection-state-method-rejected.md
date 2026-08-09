# [기각됨] 키 기반 동적 컬렉션 재조정 프리미티브를 `state:Keyed(...)` State 메소드로 두는 안

**기각 일시**: `research/additional-primitives-plan.md` 논의 도중(날짜 미상,
"이전 라운드"로만 기록). **현재 유효한 설계**: `research/
additional-primitives-plan.md` "폼 팩터" 절 — 이 프리미티브는 자유 함수로
두고, `data` 인자가 plain array/table이든 `State<array>`/`Source<array>`든
둘 다 받는 폴리모픽 컨벤션(quad의 leaf 프로퍼티가 이미 쓰는 "리터럴 또는
State 둘 다" 관례와 동일)을 따름. 이름 자체는 아직 미정 — 이 프리미티브의
최종 설계는 여전히 열려있는 질문이라 `question.md`/`additional-primitives-plan.md`
본문을 계속 참고할 것, 이 파일은 "왜 State 메소드가 아닌가"라는 기각
사유만 보존.

## 무엇을 검토했었나

"독립 프리미티브 vs 원천 종속 파생 데이터" 원칙(Source/Ref/Store/Modifier=
독립 프리미티브, State/Observer=원천에 종속된 파생 데이터)을 그대로 적용해,
이 재조정 프리미티브도 `state:Keyed(...)`처럼 **State의 메소드**로 두자는
제안.

## 기각 이유

Source를 안 쓰는 컴포넌트는 이 메소드 자체에 접근을 못 함 — 정적 데이터
(한 번만 렌더되고 다시는 안 바뀌는 리스트)를 키 기반으로 렌더링하고 싶을
뿐인데, 굳이 `Source(정적데이터)`로 감싸야 접근 가능하다면 불필요한 강제.
"독립 프리미티브 vs 파생 데이터" 원칙 자체가 틀린 게 아니라, 이 프리미티브가
그 분류 어디에도 깔끔히 안 맞는 케이스였다는 게 재검토 결과.
