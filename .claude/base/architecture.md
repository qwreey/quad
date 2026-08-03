# quad-v2 전체 아키텍처 (현재 상태 요약)

**상태**: base — 횡단 결정의 최종 상태 요약. 특정 기능 plan이 아니라 프로젝트
전체에 걸친 결정이라 완료 개념 없음. 근거가 된 원본 브레인스토밍은
`.claude/initreq/raw-userinput.md`(안 옮기고 그대로 둠 — 이 문서들로 나누기 전의
raw chain-of-thought 백업 역할). 현재 v1 구조는 `base/quad-v1-architecture.md`,
비교 리서치는 `base/comparison-fusion-vide.md`, `base/lifecycle-pattern.md` 참고.

## 한 줄 요약

quad는 이제 "스크립트"가 아니라 **라이브러리**다. DOMless Roblox UI 렌더러라는
정체성은 유지하되, 내부를 확장 가능하게 재구현한다. 프로덕트 하나를 빨리 내는 게
목표가 아니라 코드 퀄리티/지속 가능성이 목표 — 빠른 이터레이션보다 정확성이
우선.

## 확정된 결정

1. **DOMless 유지, 하지만 pluggable 하게.** 가상 DOM 없이 즉시 Roblox Instance를
   만드는 기존 방식은 유지. 대신 key/value 바인드 디스패치, 렌더 백엔드를
   pluggable하게 만들어 확장성 확보(아래 4, 5번).
2. **Class는 이제 "특정 상태의 store를 받는 함수"** — v1의 `Class.Extend()`류
   OOP 스타일(메서드 체이닝, Getter/Setter) 대신 함수형이 기본. 체이닝은 store
   바인드처럼 정말 체인이 자연스러운 곳에만(`:` 문법) 남김. 타입 작성 난이도가
   OOP 스타일에서 너무 커진다는 게 이유.
3. **복사(clone) 구현 지양, 팩토리 함수로 대체.** v1의 metatable 체이닝(1-필드
   테이블을 계속 쌓는 방식, `base/quad-v1-architecture.md` 참고)은 폐기.
   store 바인드에 대한 변경은 "전체 변경"으로 간주(UB 아님, 문서화된 의미론) —
   부분 복사/오버레이가 필요하면 팩토리 함수로 필요한 곳만 명시적으로 복사.
4. **PA님 스타일 DI 키 계속 지원**: `[Attribute "Name"]`, `[Tag ""] = true` 같은
   특수 바인드 키. Tag는 `retract`(구 cleanup, `base/lifecycle-pattern.md` 참고)가
   내장되어 store 컴퓨티드 바인드도 가능해야 함.
5. **id 기반 전역 조회 폐지, Tag 시스템으로 대체.** v1의 `Store.GetObject(id)`/
   `Frame "id" {}`류는 더 이상 없음 — "id 매핑이 비현실적"이라는 게 이유.
   네임스페이싱 문제는 있지만(`.claude/question.md` 참고) 별도 네임스페이스
   개념을 추가하면 라이브러리 복잡도가 너무 올라간다고 판단 — 당장은
   TagService 그대로 사용. **대신 Ref가 도입됨** — 단 Ref의 용도는 "id로 조회"가
   아니라 "외부에서 이미 관리되고 있는 instance를 quad로 점진적으로 마이그레이션/
   래핑하기 위해 직접 참조를 얻는 것"(`research/bind-system-plan.md`의 Ref 절
   참고) — 둘을 혼동하지 말 것.
6. **함수지향 디폴트, `:` 체이닝은 예외적으로만.** 스토어 바인드처럼 체인이 정말
   편한 경우만 `:` 사용, 나머지는 외부 함수가 인스턴스를 인자로 받는 모양.
7. **Style(Default) 시스템 폐기.** Roblox 자체 스타일시트를 쓰는 게 낫다고 판단.
   대신 modifier(spread되는 값, `...`으로 풀리는 것)를 지향 — 함수형 modifier가
   store 바인드를 받을 수도 있음.
8. **특수 이벤트는 특수 플러깅으로.** `PropertyChangedSignal`, `PropertyChangedEvent ""`
   같은 것들은 일반 이벤트 바인드가 아니라 pluggable 바인드 핸들러 중 하나로
   구현(`research/bind-system-plan.md`).
9. **Tracker 미구현.** v1의 소스 변경 감지 자동 재렌더 기능(hot-reload watcher,
   실제로는 `.claude/initreq/quad/src/tracker.lua` — v1에서도 이미 `exports.lua`에
   연결 안 된 죽은 코드였음, `base/quad-v1-architecture.md` 참고)은 렌더
   라이브러리 범위 밖으로 판단. 스토리북 구현체(https://ui-labs.luau.page/docs/getstarted)가
   이미 존재하므로 대체.
10. **lang 모듈 미구현, 분리.** 로케일/문자열 처리는 리액터블 라이브러리와
    별개 라이브러리로 존재해야 함(v1 `lang.lua`의 전역 스코프 버그 등은
    `base/quad-v1-architecture.md` 참고 — 애초에 반면교사).
11. **커스텀 Signal 클래스 미구현.** 콜백 정도로 이벤트 바인드 뒤에 함수를
    넣는 것만으로 충분하다고 판단(단, `base/lifecycle-pattern.md`의 rbvm 리서치
    결과 rbvm의 커스텀 Signal이 실제로는 재사용 가능해 보여서 상충 — 열린 질문으로
    `.claude/question.md`에 있음).
12. **멀티 타겟(pluggable 백엔드) — 특히 GTK 지원까지 염두.** Roblox 전용 렌더
    기술(react.lua, Fusion)은 결국 외부 개발자 유인이 없어 발전이 더딜 거라는
    문제의식. 결과적으로 `plug/roblox`, `plug/base` 정도로 나뉠 전망 — base가
    가상돔 없이도 프로바이더 패턴으로 백엔드를 받는 인터페이스만 정의하고,
    실제 Roblox 구현은 `quad-roblox` 격 서브패키지가 담당.
13. **모듈은 기본 싱글톤, `New()`는 나중에.** 한 Lua 스레드에서 Roblox/비-Roblox
    프로바이더를 동시에 쓸 일이 거의 없을 거라 판단 — 필요해지면 그때 `New()`
    추가.
14. **pluggable 초기화는 팩토리 함수로.** rbvm처럼 네임스페이스 하나하나 수동
    init 하는 방식(`base/lifecycle-pattern.md` 5번 항목 참고)은 피하고,
    `InitRoblox(Module)` 같은 팩토리 함수가 생성된 모듈을 뮤테이션하는 도구를
    주는 방식.

## 아직 미정 (research/로 분리됨)

바인드 시스템 디스패치, Slot 설계 세부, Tween 플러깅, 모듈 라이프사이클/누가
Store를 구현하는가, 순수함수 범위, 이미 생성된 인스턴스에 대한 바인드 —
`.claude/research/` 각 문서 참고, 전체 색인은 `.claude/README.md`.
