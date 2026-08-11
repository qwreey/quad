<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 여섯 번째 세션 — Ref/PreRef 메소드 API 확정, 파일 분리, Tween GC 저장 구조 확인, Effect/Observer 관계 해소

사용자가 메모 형태로 두 가지를 던짐: (1) Tween 인스턴스를 per-instance
저장소에 담는 구조가 실제로 GC-안전한지, (2) Ref가 이제 충분히 완결된
프리미티브이니 PreRef와 파일을 분리하고, `:Set`/`:Callback`/`:Wait`
세 메소드로 API를 굳히자는 제안(전부 mutation 패턴이라 자기 자신을
반환). 둘 다 검증 후 반영 완료:

- **Tween per-instance 저장소는 이미 확정된 구조 그대로 GC-안전함** —
  `inst`로 weak-keyed된 바깥 릴레이션 안에 `k`별 안쪽 릴레이션이 중첩된
  모양이라(`base.perInstanceState(inst)`), `inst`가 죽으면 중첩된 Tween
  인스턴스 릴레이션도 별도 정리 없이 같이 GC됨 — 새 결정 아니라 기존
  설계(`bind-system-plan.md` "핸들러 내부 상태 저장" 절)의 확인, "왜
  GC-안전한가" 설명만 명시적으로 추가.
- **Ref API가 `.Value`(읽기 전용) + `:Set(value)`/`:Callback(fn)`/
  `:Wait(thread?)`(전부 self 반환)로 확정.** self-반환 덕에
  `if ref.Value then ref.Value else ref:Wait().Value` 관용구가 성립 —
  이걸 성립시키려고 `:Set()`이 `coroutine.resume`할 때 넘기는 인자를
  기존 문서(세 번째 세션 원안)의 `value`에서 **`self`**로 정정함(안
  그러면 `:Wait()`의 yield 리턴값에 `.Value`를 체이닝할 방법이 없었음).
  `:Wait(thread?)`의 `thread` 인자는 생략 시 `coroutine.running()`을
  캡처해 진짜로 yield하고, 명시적으로 넘기면 그 thread를 등록만 하고
  yield 없이 즉시 `self` 반환(코루틴 역학상 남의 thread를 여기서 대신
  정지시킬 수 없어서) — 사용자가 직접 관리하는 스케줄러가 이미 어딘가서
  정지시켜 둔 thread를 등록만 해두고 호출부는 안 블록되고 싶은 유스케이스.
  콜백은 여전히 raw 값을 받음(Ref 자신이 아니라).
- **파일 분리**: `Ref`는 그 자체로 완결된 프리미티브, `PreRef`도 "children
  배열 전용, 위치 무관 호이스팅"이라는 특이한 제약을 가진 별개
  프리미티브라 기존 1프리미티브-1파일 컨벤션(Blocker/Effect 분리와
  같은 이유)을 따라 `Ref.luau`/`PreRef.luau`로 쪼갬 — 런타임은 여전히
  공유(`PreRef`가 `Ref`를 재사용, 브랜드 태그만 다름), `base/architecture.md`
  소스트리에 반영 완료.
- 전부 `base/bind-system-plan.md`(Ref/PreRef 절)와 `research/tween-plan.md`에
  반영 완료. `.claude/question.md`엔 이미 반영돼 있던 "Ref 이름 자체는
  용어 정리 대상" 항목과 모순 없음(이번 세션은 메소드 이름만 확정, Ref라는
  타입 이름 자체는 여전히 가칭).

**같은 세션 후반 — `.claude/question.md` 0번의 마지막 미해결 항목(Effect가
`state:Effect()`인지 자유 함수인지) 해소.** 사용자가 직접 "정해볼까" 하고
제기해 라이브로 논의, 다음으로 확정(전부 `base/effect-plan.md`/
`base/bind-system-plan.md`에 반영):

- **`state:Observer(fn)`는 등록 즉시 1회 실행되는 것으로 확정** — 근거:
  (1) 이미 채워진 State를 나중에 구독하면 반영 연산이 아예 한 번도 안
  일어나는 초기화-순서 디버깅 문제, (2) 초회 실행을 안 해야 할 구체적
  근거가 약함, (3) 이러면 Observer 하나로 "초기값 적용"과 "이후 변경
  반영"이 같은 코드 경로로 통일됨(store-bind 프로퍼티 핸들러가 최초
  적용용 코드를 별도로 안 짜도 됨).
- **`Effect(fn, state?) -> EffectHandle`로 확정** — `state` 생략 시 기존
  스펙 그대로(설치 1회 + leaf 죽을 때 확정 정리, 재실행 없음). `state`
  지정 시 **내부적으로 `state:Observer(...)`를 조합** — Observer가 이제
  즉시 1회 실행되므로 그 첫 실행이 설치를 겸하고, 이후 무효화마다
  직전 cleanup 호출 후 `fn` 재호출, leaf 사망 시 마지막 cleanup 1회 —
  React `useEffect(fn, [dep])`와 동형. 다수 의존성은 `:With(...)`로 먼저
  하나의 State로 묶어서 넘기는 쪽으로 확정(React식 별도 deps 배열
  안 만듦 — 같은 일 하는 두 번째 경로 방지 원칙). Effect는 여전히
  자유 함수(메소드 아님) — `state` 없이도 성립하는 유스케이스가 있고,
  있어도 leaf 생명주기 바인딩을 `state`가 소유하지 않아서.
- **예전에 기각했던 "Observer에 cleanup 반환 계약 추가"와 안 부딪힘** —
  그때 기각한 건 "Observer 자체에 이 복잡도를 넣지 말자"였지 패턴 자체가
  무용하다는 게 아니었음. Effect가 opt-in 상위 계층으로 이 패턴을 제공하는
  지금 구조가 그 기각과 정확히 양립함.
- **`fn`을 커링 스타일(팩토리가 실제 fn을 만들어 반환)로 짜는 것도 Effect/
  Observer 둘 다 모듈화 관용구로 권장** — `Modifier`의 `Boldify(10)` 커링과
  같은 결.
- **백로그로만 기록, 결정 안 함**: `state:Apply(...)`처럼 여러 개를 커링으로
  받아 `:With`/`:Compute` 등록을 자동화하는 조합기 아이디어(사용자 제안,
  `Modifier:Apply`의 State판 대응물) — `base/bind-system-plan.md`에 백로그
  절로만 남김, 시그니처/필요성 미검증. **(2026-08-07 일곱 번째 세션에서
  이 방향 자체가 기각되고 훨씬 단순한 형태로 확정됨 — 아래 참고.)**
- 이걸로 `question.md` 0번(추가 프리미티브 논의)의 열린 항목은 "키 기반
  동적 컬렉션 재조정" 하나만 남음.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 이미
설계된 것의 세부 마무리라 M0 착수 우선순위 자체는 그대로.

