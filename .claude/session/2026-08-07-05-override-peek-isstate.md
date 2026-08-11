<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 다섯 번째 세션 — Modifier 결합(`Override`)/읽기 접근자(`Peek`)/`isState` 확정, FuncSource 기각 사유 문서화

**출발점**: `:Apply`(4번째 세션 신설)처럼 Modifier에 더 있으면 좋을 게
있는지 사용자가 제기 — `Merge`류 결합 유틸의 우선순위 문제, 그리고
Modifier 자신이 자기 필드 값을 못 읽는 게 애매하다는 지적(예:
`Boldify`가 폰트별 굵기 보정을 하려면 현재 `Font` 필드를 읽어야 함).
같은 스레드에서 "Source가 항상 정해진 값만 담아야 하는 이유가 확정된
건지, FuncSource(람다로 계산+self-emit하는 Source) 같은 건 왜 없는지"도
같이 물어옴.

**핵심 결론(전부 base 문서에 반영 완료)**:
- **`Modifier.Override(mod1, mod2, ...)`** — `component-composition-plan.md`
  3번 절에 2026-08-04부터 가칭 `Merge`로 이미 확정돼 있던 결합 유틸의
  실제 동작을 확정하고 이름을 `Override`로 개명(중립적 "합침"이 아니라
  명시적 "덮어쓰기"라 이름이 의미를 정직하게 반영해야 함). 뒤 인자가
  필드 단위로 이김(기존 배열 flatten 규칙 재사용), 구현은 단순 필드별
  raw 교체 — setter가 이미 호출 시점에 함수/State를 즉시 처리해 저장하므로
  Modifier 필드는 항상 baked 값이라 특별한 분기 불필요. "baked 값 교체는
  거기서 파생된 다른 필드에 소급 반영 안 됨"(Boldify가 FontWeight를 계산해
  둔 뒤 Font가 Override로 바뀌어도 FontWeight는 예전 값 그대로)과 순서
  의존성(`A:Override(B)` ≠ `B:Override(A)`) 둘 다 문서 경고 대상으로 확정.
  **`Apply`로 전부 대체해 `Override`를 없애는 방안도 검토했으나 기각** —
  컴포넌트 경계(`props.Modifier`는 단일 named parameter라 배열 flatten이
  안 닿음)라는 이미 확정된 실사용 니즈를 `Apply`만으로는 못 풀어서.
  `base/modifier-plan.md` 9번 절.
- **`:Peek<<T>>(key): T|State<T>|nil`** — Modifier 필드를 확정(pull+recompute)
  하지 않고 raw 그대로 읽는 접근자. `Get`이 아니라 `Peek`인 이유는 이
  프로젝트에서 `State:Get()`이 이미 "확정한다"는 의미로 굳어져 있어서 —
  Modifier의 읽기는 정반대(State면 State 핸들 그대로) 동작이라 같은
  동사를 못 씀. 반환 타입을 `T`로 자동 확정하지 않고 union 그대로
  노출하는 이유는 4-1번 절 함수형 setter의 `old` 인자와 같은 원칙("현재
  저장된 그대로 넘김") 재사용 — 자동 확정하면 타입에 안 드러나는 채로
  반응성이 조용히 끊김. `.RealValue` 같은 별도 인덱싱 표면은 기각(이미
  `__index`가 setter 합성용으로 예약돼 있어 표면이 겹침).
- **`isState(x): boolean`** — `Peek`의 raw union을 분기하려면 필요.
  Source가 State를 구조적으로 만족하므로 이거 하나로 Source도 같이
  잡힘(`isSource` 불필요). duck-typing 대신 weak-key 레지스트리로 구현
  (rbvm 네임스페이스 추적과 같은 패턴 재사용) — `Peek`가 돌려주는 `T`가
  임의의 테이블/userdata일 수 있어 duck-typing은 false positive나 일부
  Roblox userdata의 인덱싱 에러(pcall 필요)로 이어질 위험이 있음. 이
  판별 로직 자체는 새 개념이 아니라 4-1번 setter가 이미 내부적으로
  해야 했던 "필드가 State냐 plain이냐" 판별을 public 유틸로 승격한 것.
  `base/bind-system-plan.md`의 `isState` 절.
- **FuncSource(값이 람다로 계산되고 self-emit하는 Source) 기각** — 사용자가
  스스로 기각 논리를 제시했고("이미 Compute가 커버함"), 검증 결과 이미
  확정된 두 원칙에서 그대로 연역됨: (1) Source는 "시작점"이라 다른
  반응형 값에 자동 연결 안 됨(2026-08-04 6차 라운드, "Store가 Store를
  담지 않는다" 확정 때 나온 원칙) — FuncSource는 다른 반응형 값에 종속된
  계산이면서 겉으로는 origin인 척하는 것이라 이 원칙과 직접 충돌.
  (2) `:With`가 clone 빌더가 아니라 진짜 노드여야 하는 이유(2026-08-07
  세 번째 세션)가 "의존성이 구조적으로 안 보이면 디버그 그래프가
  깨진다"였는데, FuncSource의 람다가 클로저로 캡쳐한 의존성은 정확히
  그 문제를 재현함. 실제로 커버 안 되는 유스케이스도 없음 — "다른
  반응형 값에서 계산"은 `Compute`, "clone 불가능한 값을 밖에서 바꾸고
  알림"은 원천 Source+`Emit`으로 이미 전부 커버됨. 새 결정이 아니라
  기존 확정 사항의 논리적 귀결이라 별도 base 절 신설 없이 여기 세션
  요약으로만 기록(quadnomicon 소재로 재사용 가능하도록).

**같은 세션 바로 후속 — 문서화 톤 보강(사용자 강조)**: `Override`는 범용
조합 도구가 아니라 `Frame{mod1, mod2}`의 컴포넌트 경계판(단일 named
parameter 슬롯에 독립적으로 만들어진 값 두 개 이상을 넣어야 하는 특수
상황)으로 좁게 문서화할 것 — "특정 modifier를 계속 바꿔나간다"는 요구는
항상 `Apply` + 커링/일급 함수 전달을 기본 관용구로 유도. `Apply` 자체도
`factory(self)` 호출 sugar 그 이상이 아니라는 걸 명시 — `factory`가
`Peek`한 값이 기대와 다르면 `error`를 던지든 뭘 하든 전부 `factory`
저작자 책임, `Apply`가 검증/보장을 대신 해준다고 오해하면 안 됨. 둘 다
`base/modifier-plan.md` 8/9번 절에 반영 완료.

**같은 세션 두 번째 후속 — `Apply` vs `Override` 성능 기준 확정.**
"무거운 Modifier를 대량 생성할 때 `Apply`의 clone 비용이 누적되지
않냐"는 우려에서 두 방안 검토 후 결론: **`Apply`를 mutable로 바꾸는
방안은 기각**(3번 절 immutable 확정 이유 — 형제 서브트리 오염 방지 —
가 clone 비용 절감보다 우선순위 높음, 재확인). 대신 **판단 기준을
"이질적/동질적 프로퍼티"가 아니라 "필드 간 계산 의존성 유무"로
명확화** — 한쪽이 `Peek`으로 다른 쪽의 baked 값을 읽어 반영해야 하면
이질적으로 보여도 `Apply`, 서로 완전히 독립이면 동질적으로 보여도
`Override` 가능. 계산 의존성 없는 재사용 조각(배경/텍스트/레이아웃처럼
서로 다른 서브시스템이 한 번만 만드는 값)은 모듈 상수로 만들어두고
인스턴스마다 `Override`로 결합하는 게 실제 최적화 패턴 — 단 이건
"`Override`가 내부적으로 캐싱해준다"가 아니라 사용자가 값을 재사용하는
평범한 패턴일 뿐, 라이브러리에 새 캐싱 레이어가 생기는 게 아님을
문서에 명시하기로 함. `base/modifier-plan.md` 9-1번 절.

**같은 세션 세 번째 후속 — "`Apply` 경계에서만 clone, 안쪽은 mutable"
절충안도 검토 후 기각.** clone 횟수를 체인 길이가 아니라 `Apply` 호출당
1번으로 줄이는 절충을 사용자가 직접 제시했으나, `Apply`를 거치지 않고
setter를 단발로 직접 호출하는 흔한 경로는 여전히 mutable이라 공유
레퍼런스가 그대로 오염될 수 있음(서브트리에서 폰트 두께만 바꿔도 터짐)
— "어디서 터지느냐만 달라지는" 비일관적 절충이라 실익 없다고 판단해
기각. 전부 clone하는 현재 방식 유지 확정. `base/modifier-plan.md`
9-1번 (a-1) 절.

**같은 세션 네 번째 후속(당시 CLAUDE.md에 미기록 — 2026-08-07 여섯 번째
세션에서 뒤늦게 발견/보강) — `Override`가 서브타입 관계인 Modifier끼리
섞일 때의 타입 시그니처는 미검증으로 열어둠.** `FrameModifier`가
`GuiObjectModifier`의 서브타입이어야 자연스러운데, 필드 setter 메소드의
리턴 타입이 각자 자기 자신이라(`self`) 단순 구조적 서브타이핑만으로
`Modifier.Override(guiObjectMod, frameMod)`류가 통과하는지 추론만으로는
결론 못 냄 — 후보안(메소드 필드는 `any`로 뭉개고 데이터 필드만 구조적
체크)을 실 Luau로 검증 필요, 안 되면 `Override(...: any): any`로
느슨하게 열고 이 항목으로 되돌아오는 걸 fallback으로 남김.
`base/modifier-plan.md` 9-2번, `ROADMAP.md` M7에 체크박스 반영 완료.

**다음 세션이 할 일**: 안 바뀜(위 2026-08-06 네 번째 세션 절 참고,
`ROADMAP.md` M0부터) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위
자체는 그대로.

**미해결로 남긴 것 — 임의로 결론내지 않음**: Effect가 `state:Effect()`
형태로 Observer를 확장하는 변형인지, 완전히 독립된 free function인지가
불명확함(사용자가 "확인 필요, 아니라면 논의해야 할 상태로 남겨두라"고
명시). 관련 하위 질문으로 `state:Observer(fn)`가 생성 시 `fn`을 즉시
1회 실행하는지도 문서 어디에도 명시돼 있지 않음이 이번에 드러남(Effect는
"즉시 1회 실행"이 스펙에 명시돼 있어 이 부분만 보면 둘이 겹쳐 보임).
`base/effect-plan.md`의 "미해결" 절과 `.claude/question.md`
0번에 반영 — 구현 착수(M3~M4 전후) 전에 반드시 재확인할 것.

**다음 세션이 할 일**: 안 바뀜(위 2026-08-06 네 번째 세션 절 "다음 세션이
할 일" 참고, `ROADMAP.md` M0부터). 이번 세션은 순수 문서 정리라 설계
결정 자체는 늘지 않았음 — 단, M3 체크리스트에 `Blocker.luau` 항목이
하나 추가된 것과, 위 Effect/Observer 미해결 항목은 M3~M4 착수 전에
확인해야 함.

