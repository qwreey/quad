<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-08 세션 — `Relate` 신규 프리미티브, `bindLifetime`/`canExecute`
탑레벨 함수로 확정, store-bind 재실행=Observer 재사용 명문화, `retract`
필드 생략 불가 확정

사용자가 store-bind/라이프사이클 관련 문서 갭 두 개를 질문하며 시작된 세션
— 답을 찾는 과정에서 지금까지 이름만 있던 placeholder(`base.perInstanceState`)가
실제로는 제대로 설계된 적 없는 프리미티브였다는 게 드러나 그 자리에서
설계까지 확정까지 감. 네 가지로 정리:

**1. store-bind의 "값이 바뀔 때마다 재귀 process" 구독 메커니즘 =
`state:Observer(fn):Subscribe()` 재사용으로 확정.** 기존 "확정된 디스패치
모델"/"재실행 래핑" 절이 구독을 추상적으로만 서술해서 마치 새 구독
프리미티브가 필요한 것처럼 읽혔는데, 실제로는 이미 확정된 Observer(등록
즉시 1회 실행이라 "최초 적용"과 "이후 갱신"이 공짜로 통일됨, 자기 `Subscribed`
liveness도 이미 있음)를 그대로 쓰면 됨 — `retract`는 `observer:Unsubscribe()`
호출 하나로 끝. 새 구독 메커니즘 발명 없음. `base/bind-system-plan.md`
"Store 바인드는 특수 경우인가" 절 반영.

**2. `retract` 필드는 no-op이라도 항상 정의해야 함 — 생략 불가로 확정.**
"모든 핸들러가 의미 있게 구현할 필요는 없음(보통 no-op)"이라는 기존 서술이
"필드 자체를 생략해도 된다"로 오독될 수 있는 갭이었음 — `Dispatch.process`는
담당 핸들러 타입이 바뀔 때 이전 핸들러의 `retract`를 nil 체크 없이 무조건
호출하므로, 필드를 생략한 핸들러가 실제로 교체되는 드문 순간(Tween↔프로퍼티
등)에 `attempt to call a nil value`로 크래시함. `base/bind-system-plan.md`
"핸들러 계약" 절에 명시, M2 체크리스트에 린트 대상으로 추가.

**3. `Relate` 신규 프리미티브 — `bindLifetime`/`canExecute`(가 의존하는
per-inst weak 저장소)를 제대로 설계.** 사용자 질문 경위: `Frame { observer }`처럼
children 배열에 직접 놓는 leaf 케이스와, property store-bind 핸들러가
**내부에서** 만드는 Observer(배열에 안 들어가므로 그 leaf 부착 경로를 안 탐)를
처음에 잘못 섞어서 답했다가 사용자가 "state 바인딩은 결국 k,inner v를
호출하니 i=number,v=observer로 다시 실행 안 된다"고 정정 — 후자는
`bindLifetime(inst, observer)` 같은 별도 배관이 필요하다는 걸로 이어짐.
이게 `base/lifecycle-pattern.md`가 이미 원 사용자 메모(2026-08-04)로
갖고 있던 "함수 안에서 만든 옵저버도 GC 대상 되어야 함" 절과 정확히
같은 문제였음이 드러남 — 그 절이 "범용 유틸이 있어야 한다"까지만 말하고
실제 인터페이스/이름이 없던 것.

- **탑레벨 평범한 함수로 확정, 네임스페이스 뒤에 안 숨김** — `bindLifetime(inst,value)`/
  `canExecute(inst,value)`. `Dispatch.process`류는 "시스템 배관"이라
  네임스페이스가 맞지만 이 둘은 `isState`/`isObserver`처럼 핸들러 작성자가
  직접 부르는 1급 프리미티브 연산이라 `LifetimeHandle.bind(...)`식으로
  감싸면 안 된다는 사용자 지적(정확함, 처음 제 제안이 틀렸었음).
- **`canExecute` 시그니처를 `(handle)` 단일 인자에서 `(inst, value)`
  2-인자로 재정정** — Observer 자신의 바인딩 생존(`Subscribed`)과 `inst`
  자체 생존(gcconn)이 독립된 두 조건이라 opaque `handle` 하나로 못 뭉침.
  구현은 `value`가 Observer/Effect면 자기 `Subscribed`부터 확인, 그 다음
  `inst`의 공유 gcconn `.Connected`를 봄.
- **`Relate` — `inst`를 weak 키로 하는 범용 릴레이션, 신규 프리미티브로
  독립 승격**(`base/relate-plan.md`, 1프리미티브-1파일 컨벤션). `Relate()`
  비싱글톤 생성자 + `:SetWeak`/`:GetWeak`/`:SetStrong`/`:GetStrong`. 핵심
  결정 세 개, 전부 사용자가 직접 제시:
  1. **자동으로 아무것도 홀드 안 함** — `inst`도 `value`도 Relate 자신은
     안 붙잡음, weak/strong 여부는 호출부(엔진을 아는 quad-roblox)가
     매번 명시. 자동으로 정하면 weak 키가 참조하는 값이 그 키로 되돌아
     강참조하는 사이클이 너무 쉽게 생김.
  2. **`inst`(키) 축은 항상 weak로 고정, 자유도를 안 열어둠** — 강한 키가
     필요한 유스케이스가 지금까지 하나도 없어서, 그 자유도 자체가 사고
     가능성만 늘림. `Weak`/`Strong`은 오직 `value` 보관 방식.
  3. **실 구조는 `{ [inst(weak)]: { StrongMap: {[k]:v}?, WeakMap: {[k]:v(weak)}? }? }`,
     둘 다 lazy 생성**(첫 `Set` 호출 시에만 만듦) — Luau가 정적 분석으로
     포인터 해싱을 캐싱해 반복 인덱싱은 이미 싸지지만 테이블 생성(array+hash
     part 초기화) 자체는 비교적 비싸다는 게 이유. `WeakMap`의 메타테이블은
     매번 새로 안 만들고 공유 객체 하나를 재사용.
  - **비싱글톤인 이유**: 각 핸들러 모듈이 자기 톱레벨에 `local relate =
    Relate()`를 하나씩 두면 key 네이밍이 모듈 간에 겹칠 걱정이 원천적으로
    없음(`Ref`/`Store`류와 같은 "생성 가능한 값" 컨벤션).
- **`base.perInstanceState(inst)` 이름/placeholder는 완전히 폐기** —
  `Relate`가 그 자리를 정식으로 대체. `bind-system-plan.md`(핸들러 내부
  상태 저장 절)/`ui-shorthand-plan.md`/`architecture.md`(소스트리,
  `Relate.luau`는 quad-base 전체가 순수 Lua라 quad-roblox 재구현 없음)/
  `question.md`(용어 정리 목록에서 `PerInstanceState` 항목 삭제, 이름
  갈등 자체가 해소됨)/`ROADMAP.md`(M2/M8/병행가능 세 곳) 전부 동기화.

**4. 아직 안 풀린 것 — `(i:number, v=Ref/Observer/PreRef)` children-array
leaf Handler가 quad-base/quad-roblox 중 어디 사는지.** 3번을 풀다가
갈라져 나온 별개 질문(`Frame { ref }` 자체를 매칭하는 Handler, store-bind
내부 Observer와는 무관) — 제 제안(엔진 특정 API가 필요 없으니 quad-base,
`Dispatch/StoreBind.luau`와 같은 층위)은 사용자 확인을 못 받은 채 대화가
3번으로 넘어감. `question.md` 2번에 미확인으로 남김, base에는 반영 안 함
— 다음에 확인 필요. **[해소됨, 같은 날 두 번째 세션]** 아래 절 참고 —
제 원래 제안 그대로 quad-base로 확정.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). M0/M2 스파이크 코드가
검증해야 할 것 목록에 `Relate`의 lazy 서브테이블 생성/공유 메타테이블
전략, `bindLifetime`/`canExecute`의 실제 gcconn 트릭이 새로 추가됨 —
`base/lifecycle-pattern.md`/`base/relate-plan.md`의 "실측 필요" 캐비엇
참고.

