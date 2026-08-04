# 확인/결정 필요 목록 (전체 취합)

각 plan 문서에 흩어진 "사용자 확인 필요" 절의 취합본. **막고 있는 항목은
거의 없음** — 대부분 합리적 기본값/방향을 잡아두고 research 단계에 머물러
있음. 사용자가 Lua/Roblox 엔진에 대해 깊이 아는 사람이라는 전제로, 우선순위
높은 것부터 정렬.

## 2026-08-04 검증 라운드 완료

아래 "확정됨" 절 전체(architecture.md 14개 항목, lifecycle-pattern.md,
store-semantics.md, bind-system-plan.md, module-lifecycle-plan.md,
slot-plan.md, tween-plan.md)를 `AskUserQuestion`으로 하나씩 예/아니오 재검증
완료 — 대부분 그대로 확인됐지만, 아래는 검증 과정에서 실제로 문서가 수정된
항목:

- **`State` 프리미티브는 "안 만든다"가 아니라 실제로 필요함** — 정정 완료,
  `base/store-semantics.md` 참고. **이 결과로 Store/State/Source 온톨로지
  전체가 새로운 열린 설계 스레드로 떠올랐음** — 아래 "최우선 새 열린 질문"
  참고.
- Slot의 `retract` 동작이 "부모 위임" 잠정안에서 "폐기(옮기지 않음)"로 확정
  — `research/slot-plan.md`.
- quad2-try의 `Pipe` copy-on-write 후보는 사실상 폐기, `state(state)` 조합
  모델로 대체 — `research/bind-system-plan.md`.
- `Connected` 체크/GC 위임/`Destroying` 훅 관련 뉘앙스 보강(엔진별 인터페이스
  주입, quad는 rbvm보다 즉시정리 필요성이 낮음) — `base/lifecycle-pattern.md`.
- base 유틸(per-instance 저장소, 생명 바인드)은 인터페이스만, 실제 구현은
  `RobloxFactory(BaseModule)`류 백엔드 팩토리가 주입 — `research/
  bind-system-plan.md`.

## 최우선 새 열린 질문 (검증 라운드에서 새로 터져나옴)

- **Store/State/Source 온톨로지 전체** — store는 source 집합체, state는
  source를 감싸는 조합 가능한 캐시(자기 고유 value 없음), `state(state)`로
  분기. `:Compute`의 캐싱/무효화 전략(dirty-flag 등), `emit` 필요 여부, Luau
  타입 시스템에서 `store "key"` 커링 호출의 `state<T>` 추론 문제까지 전부
  미정 — 다음 세션 최우선 논의 대상. → `research/bind-system-plan.md`의
  "Store/State/Source 온톨로지" 절.
- **부작용이 slot 생존 여부와 어떻게 연관되는가** — state 옵저빙 결과로
  slot을 조작할 때, 그 시점에 대상 slot이 죽어있으면 어떻게 처리할지 사용자도
  아직 명확한 답이 없다고 명시. → `base/store-semantics.md`.
- **인스턴스 생성/이벤트 네이밍 인체공학** — `Quad "Frame"` 문자열 방식 vs
  `DI.Frame` 필드 접근 방식(자동완성/타입추론 트레이드오프). → `research/
  bind-system-plan.md`.
- `RobloxFactory` 같은 백엔드 팩토리를 같은 base에 중복 호출했을 때의 가드
  동작, 모듈 스코핑(`New()`)과의 관계. → `research/bind-system-plan.md`.

## 확정됨 (2026-08-03 질의응답 라운드, 더 이상 열려있지 않음)

- **Store 책임 분리**: base가 `LifetimeHandle` 추상화 + store-bind의 재실행
  로직(`process(inst,k,realv)` 재귀)을 소유, provider는 "언제 죽었다고
  판단할지"(Roblox `Destroying` 등)만 결정. → `research/module-lifecycle-plan.md`,
  `research/bind-system-plan.md`
- **Signal 클래스**: 안 만듦 — 콜백 + `Connected` 계산 속성만. → `base/
  lifecycle-pattern.md`
- **핸들러 계약**: `isHandlable`+`priority`+`process`+`retract` 4종 유지,
  tbox식 세분화는 지금 안 함. → `research/bind-system-plan.md`
- **Ref**: 도입하되 용도는 "id 조회 대체"가 아니라 "외부 관리 instance를
  점진적으로 마이그레이션/래핑하기 위한 직접 참조 획득". Tween 등 어떤
  핸들러도 대상 획득에 Ref가 필요하지 않음(항상 `inst`를 직접 받음).
  → `research/bind-system-plan.md`
- **`retract`(구 cleanup) 호출 시점**: 값 교체 시에만 호출, Destroy 시엔
  호출 안 함(quad는 자신이 만든 instance의 생명주기 중간에 있지 않으므로
  destroy-time 정리 자체가 불필요/불가능). → `base/lifecycle-pattern.md`
- **핸들러 내부 상태 저장**: base가 범용 weak-keyed per-instance 저장 유틸
  제공(모든 핸들러 재사용). → `research/bind-system-plan.md`,
  `base/lifecycle-pattern.md`
- **Store 값 설정 문법**: `__newindex`(`myStore.key = v`) 유지, 괄호 생략
  커링/`:` 체이닝 인체공학도 유지 — 바뀌는 건 내부 구현(팩토리 함수)뿐.
  → `base/store-semantics.md`
- **Store의 named modifier(`:Add`/`:Mul` 등)**: 안 만듦 — 일반 함수를 받는
  형태로 통일. → `base/store-semantics.md`

## 추가 확정됨 (2번째 라운드)

- **트윈 오버라이드 기본값**: 멈춤(Cancel), 새 트윈은 현재 보간된 값에서 시작.
  나머지 세 동작(오버라이드/삭제후재시작/끝점이동후재시작)은 옵션으로 선택
  가능. → `research/tween-plan.md`
- **Slot 재마운트 에러**: 즉시 throw. → `research/slot-plan.md`
- **`CreatedRef` 콜백 타이밍**: 생성 시점/마운트 시점 둘 다 옵션으로 지원.
  → `research/bind-system-plan.md`
- **여러 store 값 묶기**: `Store.Combine`류 포지셔널 인자 방식과 Vide식 암묵적
  추적 둘 다 기각 — `:With(...)` + `:Compute(fn)`(fn은 with한 값을 포지셔널
  인자가 아니라 클로저로 읽음) 방식으로 확정. Unix 파이프에서 영감받은 완전
  합성 가능한 State 스트림이 이상향이나 기술적 난이도 미확정 — 과거 시도
  (`quad2-try/quad-core`) 리서치 진행 중. → `research/bind-system-plan.md`

## quad2-try(이전 폐기된 시도) 리서치 완료 — 추가 확정

- **OOP 상속/`--&` 커스텀 파서/Slot 스텁은 확인대로 죽은 접근** — 절대 반복
  금지, Slot은 from-scratch 설계 그대로 진행(재조사 불필요).
- **mutate-vs-`fromState` 긴장 관계**: quad2-try의 `Pipe` copy-on-write
  절충안(유일한 tip일 때만 뮤테이션, 아니면 복사)이 한때 유력 후보였으나
  **2026-08-04 검증 라운드에서 사실상 폐기로 재평가됨** — 별도 `Pipe` 타입
  대신 State 자체가 파이핑 결합체이고 `state(state)`로 분기하는 쪽이 더
  간단하다는 판단(위 "최우선 새 열린 질문"의 Store/State/Source 온톨로지
  절로 흡수됨).
- **`Depend(...)` 액션, `:With` 네이밍**은 이전 시도에서도 지향했던 것과 일치
  — 그대로 채택. → `research/bind-system-plan.md`

## 순수성/이식성, 기존 인스턴스 바인드 — 확인 완료, 낮은 우선순위로 유지

- **"순수함수" 문제는 실제로는 "이식성" 문제였음** — 재사용 의도 컴포넌트가
  전역 store를 직접 참조하면 이식성이 깨짐(단일 페이지용 컴포넌트나 라이브러리
  내부 전용 공유 상태는 문제 없음). 기술적 강제 안 함, 문서 경고 수준으로
  확정. → `research/purity-and-effects-plan.md`
- **이미 생성된 인스턴스 재바인드**: 실제 요청한 사용자를 본 적 없지만
  `retract` 인프라가 이미 있어 미래에 자연스럽게 가능해질 여지가 있음 —
  "미지원" 확정도, 착수도 안 함, 진짜 열린 가능성으로만 유지. → `research/
  existing-instance-bind-plan.md`

## 급하지 않음, 여유 있을 때만

- 태그 시스템의 네임스페이싱 부재(라이브러리 간 충돌 가능성)를 얼마나
  심각하게 볼지 — 지금은 "별도 네임스페이스 개념은 복잡도 대비 이득이 적다"는
  판단으로 보류 중. → `base/architecture.md` 5번 항목.
- Store가 Store를 담는 경우 이중 해제(double-dispose) 방지가 실제로 필요한
  상황이 있는지 — 구현 단계에서 실사례로 재검증. → `research/bind-system-plan.md`

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스 — 위 표는 힌트일 뿐 그쪽이
바뀌면 이 문서도 갱신할 것.
