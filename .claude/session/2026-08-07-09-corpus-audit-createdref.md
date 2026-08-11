<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 아홉 번째 세션 — 코퍼스 전체 정합성 감사·수정, `agent-mistake.md`
신설, `CreatedRef` 이름 완전 폐기

여러 세션에 걸쳐 쌓인 stale 참조/자기모순을 서브에이전트 5개 병렬 감사로
찾아내 전부 수정하고(커밋 `98bd46a`), 이어서 사용자가 직접 발견한 남은
문제(`CreatedRef` 이름 자체가 더 이상 존재할 이유가 없다는 지적)까지 처리한
세션. 세 부분으로 나눠 요약:

**1. 코퍼스 정합성 감사·수정 (커밋 `98bd46a`)**: `CreatedRef`의 `phase`
옵션 폐기가 `bind-system-plan.md` 안에서 세 곳 중 두 곳에 방치돼 있던 것,
`question.md`의 `Ref` 재검토 대상 여부 자기모순, UICorner 숏핸드 개명이
5개 문서에 전파 안 된 것, `canExecute(handle)` 시그니처 정정이 막 확정된
직후라 두 곳에 전파 안 된 것, `architecture.md`/`ROADMAP.md`/`CLAUDE.md`의
stale 문구·누락 참조 등 12개 항목을 수정. `store-semantics.md` 제목도
"State는 **Store** 위의 캐시 레이어"에서 "State는 **Source** 위의 캐시
레이어"로 정정(사용자 확인: Source 단독 존재 가능 + Store는 Source들의
집합이라는 온톨로지가 맞음). `slot-plan.md`의 CRUD 의미론 갭 하나만
사용자가 다음 세션에서 직접 다루기로 보류.

**2. `archive/agent-mistake.md` 신설** — 설계 반전(`*-reversed.md`)/기각
후보(`*-rejected.md`)와 구분되는 세 번째 archive 카테고리: 에이전트가
문서 작성 중 스스로 낸 개념 혼동을 같은 세션 안에서 정정한 사례 전용
(`canExecute`/`isHandlable` 혼동, `isSource` 불필요 오판 2건). CLAUDE.md
세션 로그에 전체 경위가 장황하게 남아있던 것 중 최종 결론이 이미 `base/`
문서에 반영돼 중복이던 걸 옮기고 포인터만 남김 — 앞으로도 비슷한 사례가
생기면 여기로 옮길 것(사용자 확인).

**3. `CreatedRef` 이름 완전 폐기 — 사용자가 직접 발견.** "Ref가 이미 다
정해진 것 같은데 `CreatedRef`는 이제 없는 말 아니냐"는 지적: `Source(default)`/
`Ref(default)`/`Store({defaults})`가 이미 Kotlin Compose식 "타입 이름
자체가 팩토리 함수" 생성자 스타일로 확정돼 있었는데(2026-08-06 네 번째
세션), `CreatedRef(fn)`라는 별도 래퍼 이름만 그 확정 이전(2026-08-04,
Ref가 아직 "instance 얻는 통로"로 좁게 정의됐던 시절)의 잔재로 계속
남아있었던 것 — 실제로는 `Ref(default)`(또는 `PreRef(default)`)
인스턴스 자체를 children 배열 숫자 슬롯에 그대로 놓으면 `(v=Ref)` 매치
핸들러가 처리하므로, 별도 래퍼 함수가 있을 이유 자체가 없었음. `base/
bind-system-plan.md`(바인드 방법 절 재작성, "CreatedRef와의 관계" 절
삭제, "phase 옵션 폐기" 절/열린질문 절 정리) · `ROADMAP.md`(M0/M8 체크
박스) · `question.md`(용어 재검토 목록에서 제거, 해소로 표시) ·
`architecture.md`(소스트리 주석) · `research/documentation-content-map.md`
전부 동기화 완료. `archive/ref-phase-option-reversed.md`(phase 옵션
자체의 역전 이력)와 CLAUDE.md 이전 세션 로그의 `CreatedRef` 언급은
당시 기록으로서 정확하므로 그대로 둠 — 역사적 서술과 현재 유효한 설계를
헷갈리지 않도록 "phase 옵션 폐기" 절 제목에 "이 절이 당시 쓰던 이름
자체도 이후 폐기됨" 포인터만 추가.

**부수 작업 — `PreRef`/`Modifier`의 "pre-hook" 태깅 요청 처리.** 같은
세션 앞부분에서 사용자가 "PreRef와 Modifier는 문서화 시 pre-hook 태그가
필요해 보인다, hook과 pre-hook의 차이(취소 가능/순서 등록 가능)도 적어
두면 좋겠다"고 제안 — 이건 런타임 설계가 아니라 문서 사이트 콘텐츠
분류 아이디어라 base/에 "확정"으로 못박지 않고 `research/
documentation-content-map.md`(심화 콘텐츠 후보 6번 + "문서화 아직 보류"
목록)에 사용자 원문 프레이밍 그대로 미확정 표시로 남겨둠 — `PreRef`가
"인스턴스에 뭐가 일어나기 전에 채워진다"는 사실 자체는 이미 확정
서술돼 있었지만(재확인 후 "메모에서 지워도 됨"으로 답변), "hook"/
"pre-hook" 용어 채택 여부·`PreRef`의 취소 가능성·복수 `PreRef` 간 순서는
다음에 사용자가 직접 정해야 base/로 승격 가능. **[정정, 2026-08-07 열
번째 세션]** 같은 대화에서 "Ref 콜백/대기자 배열은 압축 없이 `self[i]
= nil`로만 지워도 된다"는 설계가 이미 정확히 반영돼 있다고 여기 적었던
건 틀림 — 실제로는 `nil`이 아니라 `None`으로 지워야 함(아래 열 번째
세션 절 참고), 이때는 아직 발견 전이었음.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). `slot-plan.md` CRUD
의미론과 "hook/pre-hook" 프레이밍 확정만 사용자가 직접 다룰 후보로 남음.

**같은 세션 후속 — `PreRef` pre-pass 구현 위치·복수 `PreRef` 순서·동적
경로 가드 확정.** 사용자가 구체적인 구현 방안 세 개를 직접 제시:

1. **복수 `PreRef` 간 순서는 배열 index 순서 그대로** — 별도 규칙 발명
   불필요, 위 "props 순회 순서" 절이 이미 확정한 "배열 파트는 index
   순서대로" 계약을 그냥 재사용하면 됨. 호이스팅은 "PreRef 대 나머지"
   에만 적용되는 규칙이지 "PreRef끼리"엔 적용될 게 없음.
2. **pre-pass가 사는 곳 — 새 `Dispatch.*` 함수 대신 이미 확정된
   `Dispatch.drive(inst, flattened)` 자신.** 사용자가 두 대안을 직접
   제시(`Dispatch.process(inst, flatten, prerefs)`류 신설 함수 vs
   `flatten(inst, nonFlatten)` 함수 자체에 얹기) — 검토 결과 둘 다
   불필요/위험함이 드러남. 전자는 이미 `Handler.process`/`Dispatch.process`
   이름이 다른 뜻으로 확정돼 있어 겹침. 후자(flatten에 얹기)는 사용자가
   "가장 간단해 보인다"고 제안했지만, `research/existing-instance-bind-plan.md`가
   다루는 "이미 마운트된 Instance 재바인드 시 flatten을 다시 해야
   하는가"라는 열린 질문이 실제로 flatten이 한 인스턴스 생애주기 동안
   여러 번 재호출될 가능성을 열어두고 있어서, 거기 PreRef fire를 얹으면
   재바인드마다 PreRef가 또 fire되어 "이 인스턴스 하나의 construction
   훅"이라는 정의 자체가 깨짐 — 기각. `Dispatch.drive`는 최초 마운트
   시 한 번만 불리는 게 이미 전제라 이 위험이 없어서 그대로 거기 좁은
   pre-pass 한 줄만 얹으면 충분.
3. **동적 경로로 도착한 `PreRef`는 런타임에도 명시적으로 error —
   지금까지 타입 차단만 문서화돼 있던 빈틈을 채움.** 사용자 제안
   그대로 채택: `{isHandlable = v is PreRef, process = error(...)}`
   전용 Handler를 정상 우선순위 레지스트리에 등록(`NoneHandler`와 같은
   "한 값 종류 전담" 패턴, 새 메커니즘 아님). 리터럴 배열의 `PreRef`는
   pre-pass가 fire와 동시에 슬롯을 소진시켜 정상 두 패스에 다시
   노출되지 않으므로, 이 Handler가 실제로 매치되는 경우는 타입 차단을
   어떻게든 우회한 버그 케이스뿐 — no-op이 아니라 즉시 `error`가 맞음.

전부 `base/bind-system-plan.md` "PreRef" 절에 반영, `ROADMAP.md` M8
체크박스 갱신, `research/documentation-content-map.md`의 "복수 PreRef
순서" 미정 표시 제거(해소됨, "취소 가능성"만 계속 미정으로 남김).

**같은 세션 두 번째 후속 — "호이스팅이 물리적 재배치가 아니라 별도
선행 스캔"이라는 것과 소진 방식을 명시화(뒤이은 세 번째 후속에서
`nil`→`None`으로 다시 정정됨, 아래 참고).** 사용자가 "drive에서도
결국 PreRef를 목록에서 뽑아내야 하는데, 호이스팅 안 되면 PreRef
의미가 사라지는 거 아니냐"고 재질문 — 이전 답변이 `Dispatch.drive`가
pre-pass를 갖는다고만 하고 정확한 알고리즘을 안 써서 나온 질문.
`Dispatch.drive`가 같은 `flattened` 테이블을 **두 번** 순회한다는
것으로 답변: (1) pre-pass가 배열 전체를 index 순으로 훑어 `PreRef`를
fire하며 그 자리에서 슬롯을 소진, (2) 그 다음 평소 두 패스가 같은
테이블을 다시 순회하되 소진된 슬롯은 자연히 건너뜀. "호이스팅"은
PreRef를 배열 앞으로 물리적으로 옮기는 게 아니라 "PreRef 전용 선행
루프가 통째로 먼저 끝난 뒤에야 나머지가 시작된다"는 뜻이라 소스 위치와
무관하게 항상 먼저 fire됨. **소진이 최적화가 아니라 정확성 요건인 이유도
명시**: 안 지우면 두 번째 패스가 이미 처리된 PreRef를 `Dispatch.process`로
다시 넘겨서, 바로 위에서 신설한 "동적 경로 가드" Handler(`(v=PreRef)`→
`error`)가 정상 사용에도 오탐 에러를 던지게 됨.

