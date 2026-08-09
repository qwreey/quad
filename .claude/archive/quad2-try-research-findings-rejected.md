# [기각됨] quad2-try 리서치 — 죽은 접근 4가지 + Unix 파이프 영감의 최종 정리

**기각/해소 일시**: 2026-08-04(2차 라운드). **현재 유효한 설계**:
`base/bind-system-plan.md`의 "Store/State/Source 온톨로지" 절 — `state(state)`로
기존 state의 결과를 받아 새 state를 만드는 조합 모델이 최종 결론, Slot은
`base/slot-plan.md`의 from-scratch 설계, `:With` 이름은 이미 확정. 이 파일은
더 이상 능동적으로 참고할 필요 없음(구현에 안 씀, "OOP 상속/커스텀 파서/Slot
스텁/Pipe copy-on-write는 확인된 죽은 접근이라 반복 조사 금지"라는 결론
한 줄만 `CLAUDE.md`/`base/bind-system-plan.md`에 포인터로 남으면 충분) —
"이전 시도에서 뭘 배웠는가"가 `quadnomicon`(프레임워크 설계자용 심화 콘텐츠)
소재로 가치 있어서 조사 과정과 근거를 통째로 보존해둔 것.

## 배경 — quad는 원래 Unix 파이프에서 영감을 받아 설계됨

quad는 원래 파이프라인/스트림 개념에서 영감을 받아 만들어짐. 이상적으로는
store에서 한 값을 추적(track)하면 "State"가 나오고, 거기에 `compute`를
적용하면 또 다른 "State"가 나오는 식 — Unix의 `(cat a; cat b) | while
read ...`처럼 State끼리 자유롭게 합성/파이핑 가능한 것이 최종 목표.
`:With`의 두 번째 인자도 다른 `:Compute`의 결과물(State)을 그대로 받을 수
있어야 이상적이었음.

이 목표를 실제로 어떻게 구현할지에 두 갈래 긴장이 있었음: (1) Compute
체인이 자기 자신을 mutable하게 바꾸는 방식(엔지니어링 비용 낮지만
공유/합성이 깨짐) vs (2) 명시적 `State:fromState(state)`류 비-mutating
생성자(합성은 안전, 비용 미확정). `.claude/initreq/quad2-try/out/quad-core`에
정확히 이 문제를 다뤘던 이전 재작성 시도가 있어서 그걸 조사해 답을 찾으려
했음.

## 조사 결과 — 확인된 죽은 접근, 절대 반복하지 말 것

- **OOP 상속(`Base:Extends`) 구조**가 `Source`/`State`/`Pipe`/`Store`/
  `Event`/`Action`+8개 서브타입 전체에 퍼져 있었음 — 모든 서브클래스
  생성자마다 `self._super._constructor(self, ...)`를 수동으로 호출해야
  하고(빼먹기 쉬움, 컴파일러가 검증 안 함), private/protected는 `_` 접두사
  관례일 뿐 실제 캡슐화가 전혀 없었으며, `Base:IsInstance`가 수동 유지되는
  `_proto`/`_super` 연결 리스트를 순회하는 런타임 전용 타입 체크라 Luau
  정적 타입 시스템이 전혀 못 봄. 사용자가 우려한 그대로 확인됨 — 상속
  기반 설계 금지.
- **`--&` 커스텀 파서 시도**는 완전히 죽은 코드였음 — 6개 파일에 156줄의
  주석 기반 타입/가시성 어노테이션이 있었지만, 이걸 실제로 소비할 도구
  (`quad-gen`, `quad-lang`)는 둘 다 완전히 빈 디렉토리였음. 오타(`@clsas`를
  `@class`로 못 고침)가 안 잡힌 채 남아있었고, 같은 주석 마커 아래 전혀 다른
  Lua5.1-호환 트랜스파일러 지시어까지 섞여 있었음 — 파서가 한 번도 제대로
  동작한 적 없다는 명백한 증거.
- **Slot은 이 시도에서도 사실상 빈 스텁**이었음 — `Insert`의 실제 구현부가
  전부 주석 처리되어 있고, `Notify()`도 빈 함수. 심지어 구 v1(`quad-2`)의
  `DEV_CHANGELOG.txt`에도 "TODO: slot 기능 구현"이 마지막까지 미완료로
  남아있었음 — 가져올 게 전혀 없음, `base/slot-plan.md`의 from-scratch
  설계를 그대로 진행하면 됨(재조사 불필요).
- 다른 서브패키지(`quad-roblox`/`quad-gtk`/`quad-lang`/`quad-gen`/
  `quad-compat`/`quad-debug`/`quad-docs`)는 전부 파일이 0개인 빈 디렉토리
  — `quad-core` 밖엔 참고할 게 없음.
- `Store:Pipe`/`Store:Value` 연동이 담긴 유일한 두 예제 콜사이트
  (`slot.luau:31-41`)조차 존재하지 않는 `Store:Value` 메서드를 호출하는 등
  실제로 동작 검증된 적이 없는 죽은 스크래치 코드였음 — 이 프로토타입은
  끝까지 실사용 검증을 통과한 적이 없음.
- **`Pipe`가 mutate-vs-`fromState` 긴장 관계에 제시했던 절충안** —
  "체이닝된 `Compute`/`Add`/... 호출은 자신이 액션 리스트의 유일한
  '끝(tip)'일 때만 공유 배열에 그대로 append(뮤테이션), 이미 다른 코드가
  그 지점 이후로 체인을 확장해버렸다면 배열을 복사한 뒤 새 `Pipe` 객체를
  반환"하는 copy-on-write 방식 — 한때는 위 (1)/(2) 긴장을 풀어보려 한
  유일한 시도로서 다시 설계해볼 후보였으나, 최종적으로 폐기됨 —
  `state(state)` 조합 모델이 소유권/버전 가드 없이도 같은 문제를 더
  간단히 풀어서 이 절충안 자체가 불필요해짐. 원본이 갖고 있던 진짜 결함
  (소유권/버전 관리 없이 경쟁 상황에 취약, 테스트/실사용 검증도 없었음)도
  기록으로 남김.

## 건질 만한 것 (인체공학/아이디어만, 코드는 아님)

- **`store:Pipe(key):Compute(fn)` 같은 왼쪽에서 오른쪽으로 읽히는 파이프
  문법 자체**는 목표로 유지할 가치가 있다고 판단됐음 — 실제로 이후
  `:With`+`:Compute` 체이닝으로 달성됨.
- **`Depend(...)` 액션** — 계산값에는 관여하지 않고 오직 "이 소스가 바뀌면
  다시 계산하라"는 추가 의존성만 등록하는 값-투명(value-transparent) no-op
  액션. 작지만 깔끔한 아이디어로 기록됐으나, 이후 실제 설계에서 별도
  프리미티브로 채택되지는 않음(`:With(...)` 가변인자로 같은 효과를 얻음).
- **흥미로운 발견**: 스크래치 파일(`out/asdf`)에 남아있던 더 이전 버전의
  파이핑 스케치가 정확히 `Pipe(store.background):With(store.transparency,
  globalStore.test):Compute(fn)` 모양이었음 — 실제 구현으로 넘어가며
  `:Depend()`+포지셔널 인자로 바뀌었지만, `:With(...)` 네이밍은 이후
  라운드에서 다시 요청된 것과 정확히 일치 — 우연이 아니라 원래 지향점이었던
  것으로 보이며, `:With` 이름 채택에 힘을 실어준 방증.

## 결론

이 프로토타입은 사실상 죽은 시도가 맞음(확인됨) — `:With` 네이밍은
quad-v2 설계에 그대로 살아남았지만, Pipe의 copy-on-write 절충안은
2026-08-04 검증 라운드에서 폐기되고 `state(state)` 조합 모델로 대체됨.
Unix 파이프 영감이라는 원래 동기 자체는 `:With`+`:Compute` 체이닝으로
충분히 달성된 것으로 최종 판단.
