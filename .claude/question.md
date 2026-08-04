# 확인/결정 필요 목록 (전체 취합)

각 plan 문서에 흩어진 "사용자 확인 필요" 절의 취합본. **막고 있는 항목은
거의 없음** — 대부분 합리적 기본값/방향을 잡아두고 research 단계에 머물러
있음. 사용자가 Lua/Roblox 엔진에 대해 깊이 아는 사람이라는 전제로, 우선순위
높은 것부터 정렬.

## 2026-08-04 5차 라운드 완료 — 소스 트리 구조 확정

`.claude/base/architecture.md`의 "구현 착수: 소스 트리 구조 확정" 절 참고.
`base/bind-system-plan.md`/`base/module-lifecycle-plan.md`/`base/slot-plan.md`가
이 라운드에서 `research/`에서 승격됨.

- **패키징**: 최종 목표는 다중 wally 패키지지만, 지금 Luau 툴링(wally 타입
  단절, `luau-lsp` 심볼릭 링크 해석 문제)이 불안정해서 당장은 모놀리식 —
  `Sleitnick/RbxUtil` 패턴(루트 통합 개발/테스트, 서브폴더마다 자체
  `wally.toml`) 채택. `.luaurc` alias는 런타임 require에서 아직 엔진 미지원 —
  편집기 경험용으로만 사용, 런타임 require는 상대경로.
- **패키지 경계**: `quad-base` = Store/State/Source 온톨로지+전파 **+**
  pluggable 디스패치 엔진(`process`/`retract`, 핸들러 계약, `LifetimeHandle`/
  `PerInstanceState` 인터페이스, Ref, Slot 코어 재조정 로직) — 전부
  "인터페이스"로, 다른 엔진(GTK 등)에서도 재사용 가능해야 한다는 전제.
  `quad-roblox` = 위 인터페이스의 실제 구현체(`RobloxFactory`, Property/Event/
  Attribute/Tag/Tween/Slot 적용 핸들러, `DI` 인스턴스 생성자) — 이유: 엔진마다
  큰 구현을 중복하지 않기 위함(rbvm의 relation 통합 시도와 같은 동기).
- **Slot 패키지 경계**: 재조정 로직(add/remove/clear)은 base, 실제 Instance
  `Parent`/`Destroy` 조작은 roblox의 핸들러가 담당 — `base/slot-plan.md`
  "base/roblox 패키지 경계" 절.
- **새 핸들러 필요성 확인**: `k:number, v:Instance`(중첩 인스턴스를 직접
  자식으로 넣는 경우, `Frame { Frame {} }`)를 위한 `InstanceChild` 핸들러가
  Slot과 별개로 필요 — `quad-roblox/src/Handlers/InstanceChild.luau`.

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
  — `base/slot-plan.md`.
- quad2-try의 `Pipe` copy-on-write 후보는 사실상 폐기, `state(state)` 조합
  모델로 대체 — `base/bind-system-plan.md`.
- `Connected` 체크/GC 위임/`Destroying` 훅 관련 뉘앙스 보강(엔진별 인터페이스
  주입, quad는 rbvm보다 즉시정리 필요성이 낮음) — `base/lifecycle-pattern.md`.
- base 유틸(per-instance 저장소, 생명 바인드)은 인터페이스만, 실제 구현은
  `RobloxFactory(BaseModule)`류 백엔드 팩토리가 주입 — `base/bind-system-plan.md`.

## 최우선 새 열린 질문 (검증 라운드에서 새로 터져나옴)

**전부 확정됨** — 아래 "2026-08-04 3차 라운드" 절 참고. 이 섹션에 새 항목이
생기면 여기 추가.

## 2026-08-04 4차 라운드 완료 — PA님 실 코드(`initreq/artworks`) 교차검증

사용자가 실제 참고 코드를 공유(`.claude/initreq/artworks/`, PA님 작성) —
아래 두 항목이 3차 라운드 잠정안에서 정정됨, 나머지는 재검토 후 기존 확정
유지:

- **"DI" = Declarative Instance**(Dependency Injection 아님) — 3차 라운드의
  오해 정정.
- **이벤트 바인딩 정정**: `On.EventName` 도트액세스 안 씀 — PA님 방식(평범한
  문자열 키 + `ReflectionService` 기반 자동 판별, `Frame { MouseButton1Click
  = fn }`)으로 전환. Store의 `store.key`는 실질적 타입 이득이 있어 dot-access
  유지, 이벤트만 예외.
- **인스턴스 생성**: 2트랙(`DI.Frame`/`DI.New<<Frame>>`) 대신 PA님 코드처럼
  제네릭 생성자 함수 하나 + 자주 쓰는 클래스만 정적 필드로 미리 바인딩하는
  더 단순한 모양으로 정정.
- **전파 모델(push-invalidate/pull-recompute)·라이프사이클(GC-native)은
  재검토 후 기존 확정 유지** — PA님 코드가 반례처럼 보였으나(전자는 push-값
  단순 pub-sub, 후자는 전부 수동 해제) 대등한 비교가 아니었거나(파생/합성
  개념 자체가 없음) 지금 필요성이 없다는 게 사용자 판단. 라이프사이클은
  나중에 하이브리드로 확장 가능한 여지만 기록.
- OOP 회피 결정은 PA님의 `class.luau`도 같은 체이닝 상속 보일러플레이트를
  보여 오히려 보강됨. Instance 태그는 CollectionService 직접 사용 유지.

→ 상세: `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍
인체공학" 절, "Store/State/Source 온톨로지"의 "PA님 코드와의 교차검증" 절,
`base/lifecycle-pattern.md`의 "교차검증" 절.

## 2026-08-04 3차 라운드 완료 — dot-access 관습 확정, RobloxFactory 가드 확정 (일부 4차 라운드에서 정정됨)

- **dot-access를 프로젝트 전역 관습으로 확정**: "정적으로 알려진 것=필드
  접근, 동적인 것=문자열 호출 폴백"이 Store(`store.key`/`store "key"`)와
  인스턴스 생성에 적용됨 — **이벤트는 4차 라운드에서 예외로 정정**(위 참고).
- **`RobloxFactory` 재호출 가드 확정**: 같은 팩토리로 재호출 시 무시
  (no-op, hot-reload 안전), 다른 팩토리로 재호출 시 에러(유일 슬롯 충돌).
  `New()`와는 인스턴스별 테이블 분리로 자연히 공존 — 재설계 불필요. (4차
  라운드에서 변경 없음)

→ 상세: `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍
인체공학" 절, "base 유틸은 인터페이스..." 절의 재호출 가드 부분.

## 2026-08-04 2차 라운드 완료 — Store/State/Source 온톨로지 핵심 메커니즘

위 최우선 질문 중 "Store/State/Source 온톨로지 전체"와 "부작용이 slot 생존
여부와 어떻게 연관되는가"는 `AskUserQuestion`으로 확인 완료, 더 이상 열려있지
않음:

- **전파 모델**: push-invalidate(신호만, 값 안 실음) / pull-recompute(`Get()`
  시점에만 재계산) — Fusion식 eager 노드·생성순 정렬은 안 만듦.
- **`:Compute`의 self 인자**: raw 값이 아니라 State 핸들 자체를 넘겨서 self도
  with한 값과 동일하게 lazy하게(`.value`를 실제로 읽을 때만 계산) 처리 —
  별도 `ComputeWithout` 불필요.
- **State는 쓰기 대상이 아님**: `.value`는 읽기 전용, 값 쓰기는 항상 Store의
  `__newindex`로만. `Source`는 Store 내부 디테일이 아니라 값 하나만 다룰 때
  쓰는 별도의 가벼운 공개 프리미티브로 격상.
- **Slot 생존 확인**: 별도 메커니즘 없이 기존 "생명 바인드 유틸"의
  `canExecute`로 통일 게이트.
- **`store.key` dot-access 타입 추론 제안**: 3차 라운드에서 정식 확정됨(위
  "2026-08-04 3차 라운드 완료" 절 참고).

→ 상세: `base/bind-system-plan.md`의 "Store/State/Source 온톨로지 —
핵심 메커니즘 확정" 절, `base/store-semantics.md`, `base/lifecycle-pattern.md`.

## 확정됨 (2026-08-03 질의응답 라운드, 더 이상 열려있지 않음)

- **Store 책임 분리**: base가 `LifetimeHandle` 추상화 + store-bind의 재실행
  로직(`process(inst,k,realv)` 재귀)을 소유, provider는 "언제 죽었다고
  판단할지"(Roblox `Destroying` 등)만 결정. → `base/module-lifecycle-plan.md`,
  `base/bind-system-plan.md`
- **Signal 클래스**: 안 만듦 — 콜백 + `Connected` 계산 속성만. → `base/
  lifecycle-pattern.md`
- **핸들러 계약**: `isHandlable`+`priority`+`process`+`retract` 4종 유지,
  tbox식 세분화는 지금 안 함. → `base/bind-system-plan.md`
- **Ref**: 도입하되 용도는 "id 조회 대체"가 아니라 "외부 관리 instance를
  점진적으로 마이그레이션/래핑하기 위한 직접 참조 획득". Tween 등 어떤
  핸들러도 대상 획득에 Ref가 필요하지 않음(항상 `inst`를 직접 받음).
  → `base/bind-system-plan.md`
- **`retract`(구 cleanup) 호출 시점**: 값 교체 시에만 호출, Destroy 시엔
  호출 안 함(quad는 자신이 만든 instance의 생명주기 중간에 있지 않으므로
  destroy-time 정리 자체가 불필요/불가능). → `base/lifecycle-pattern.md`
- **핸들러 내부 상태 저장**: base가 범용 weak-keyed per-instance 저장 유틸
  제공(모든 핸들러 재사용). → `base/bind-system-plan.md`,
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
- **Slot 재마운트 에러**: 즉시 throw. → `base/slot-plan.md`
- **`CreatedRef` 콜백 타이밍**: 생성 시점/마운트 시점 둘 다 옵션으로 지원.
  → `base/bind-system-plan.md`
- **여러 store 값 묶기**: `Store.Combine`류 포지셔널 인자 방식과 Vide식 암묵적
  추적 둘 다 기각 — `:With(...)` + `:Compute(fn)`(fn은 with한 값을 포지셔널
  인자가 아니라 클로저로 읽음) 방식으로 확정. Unix 파이프에서 영감받은 완전
  합성 가능한 State 스트림이 이상향이나 기술적 난이도 미확정 — 과거 시도
  (`quad2-try/quad-core`) 리서치 진행 중. → `base/bind-system-plan.md`

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
  — 그대로 채택. → `base/bind-system-plan.md`

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
  상황이 있는지 — 구현 단계에서 실사례로 재검증. → `base/bind-system-plan.md`

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스 — 위 표는 힌트일 뿐 그쪽이
바뀌면 이 문서도 갱신할 것.
