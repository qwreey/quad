<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-06 세션 — quad-debug(런타임 디버깅 플러그인) 설계, 실측 검증까지 완료

팀원이 "실물 Frame에서 그걸 만든 코드 위치를 역추적하는 Studio 플러그인이
있으면 좋겠다"는 피드백을 줬고, 사용자가 이걸 `quad-debug`/
`quad-debug-roblox-plugin`으로 후순위 설계해두자고 판단해 시작된 세션.
착수는 여전히 "quad 개발이 상당 부분 끝난 뒤"로 못박혀 있음(구현 우선순위는
안 바뀜) — 대신 base 설계(디스패치/Source/DI 생성자) 시점에 훅 확장
지점만 고려해두면 나중이 훨씬 싸진다는 문제의식으로 지금 미리 설계만
해둠. 전체 내용은 `research/debug-tooling-plan.md`, 요지만 요약:

- **설계를 막던 유일한 기술적 불확실성이 실측으로 해소됨**: Roblox Studio
  플러그인과 Play 중인 게임(LocalScript)이 별도 Luau VM/스크립트
  컨텍스트라 `BindableEvent`/`BindableFunction`이 그 경계를 실제로
  넘는지가 문서만으로는 안 갈렸음(공식 문서는 언급 없음, DevForum엔
  실패 사례도 있었음) — 사용자가 테스트용 플러그인/스크립트
  (`plugin-ignoreme.luau`/`game-ignoreme.luau`, 레포 루트, `*-ignoreme*`
  패턴이라 자동 gitignore)를 직접 Studio에서 돌려 **Fire/Connect,
  Invoke/OnInvoke 왕복 둘 다 안정적으로 작동함을 확인**. 원리는 "Play
  진입 시 DataModel이 복제되는 게 아니라 script identity/보안 컨텍스트만
  분리되고, Instance 자체(C++ userdata)는 어느 컨텍스트에서든 같은
  참조를 가리킨다"는 것 — 사용자가 실측 도중 직접 정리한 설명.
- **채널은 확인됐지만 처음 구상(quad-debug-roblox가 `ReplicatedStorage`에
  Bindable을 자동 생성)은 기각** — 개발자가 의도 안 한 Instance를 게임
  트리에 주입하는 부작용이 크다는 사용자 지적. 대신 quad 모듈 자신의
  Instance 트리 안에 두고 `CollectionService` 태그로 노출, 플러그인은
  `GetTagged`로 찾음(`GetDescendants` 전체 순회 불필요).
- Roblox Luau의 `debug` 라이브러리엔 `sethook`류가 없어(확인됨) 엔진이
  공짜로 주는 동적 트레이싱 방법이 없음 — 대신 Fusion `src/External.luau`에
  이미 있던 "no-op 업밸류를 나중에 실제 구현으로 통째로 교체" 패턴을
  재사용하기로 함(quad가 이미 쓰는 "base는 인터페이스, 구현은 팩토리가
  주입" 원칙과 같은 모양이라 새로 발명할 필요 없음).
- React DevTools 아키텍처도 서브에이전트로 조사 — 그대로 못 베끼는 것도
  있지만(전역 훅 주입은 프로세스 경계 문제로 안 됨), **컴파일타임 소스
  위치 주입**(Babel처럼 darklua로 흉내낼 후보)과 **얇은 스트림+on-demand
  상세조회** 원칙은 그대로 채택.
- UX 방향은 사용자가 여러 번 직접 정정: "존재하는 State 목록"이 아니라
  "무엇이 무엇에 연결됐는가" 그래프 중심, flash-on-update는 전체 상시
  적용이 아니라 마운트/언마운트만 상시+개별 프로퍼티 변경은 현재 열어본
  Instance 한정, PropertyChangedSignal 기반 "외부 변경 감지"는 핵심
  채널이 아니라 보조 신호일 뿐(어디서/왜 바뀌었는지가 quad-debug의 진짜
  가치라 순수 관찰만으론 부족). **Element Inspector**(화면 클릭으로 UI
  요소 피킹)가 사용자가 실제로 가장 크게 느낀 pain point로 새로 부상 —
  Roblox가 Play 중 라이브 UI 편집 도구를 꺼버려서 Explorer만으로 요소
  찾기가 힘들다는 실사용 불만.
- 부수적으로 파생된 두 가지(quad-debug 범위 밖) 문서화 아이디어 —
  UI 네이밍 컨벤션 문서, 스킬/쿨타임/재화 같은 게임 시스템에서 Store의
  부작용 허용을 깔끔한 패턴으로 쓰는 법 문서 — 를 `research/
  documentation-plan.md`에 뼈대만 분리해서 남김(위 "지금 할 일" 4번).
- **이벤트 self 관습 확인 필요했던 항목 — 같은 날 후속 세션에서 해소됨.**
  아래 "2026-08-06 후속 세션" 절 참고.

**같은 세션 후반, 별개 주제 두 개 추가**(quad-debug와 무관, 사용자가
"적어는 뒀는데 안 줬는건가" 하며 새로 떠올린 것들):
- **Attribute 특수 키 타입 파라미터화** — `[Attribute<<boolean>> "name"]`
  제네릭 스타일 vs `[BooleanAttribute "name"]` 타입별 정적 생성자 패밀리.
  기존 문서 어디에도 없던 신규 논의로 확인(`bind-system-plan.md`
  "Attribute 특수 키" 절에 새로 추가) — 소견은 DI 인스턴스 생성 때 이미
  쓴 "제네릭 하나 + 자주 쓰는 타입만 정적 지름길" 패턴 재사용, 확정은 아님.
  Roblox Attribute가 이제 Instance 참조 타입도 지원해서 `ObjectValue`
  없이 Ref 용도로도 쓸 수 있다는 점도 확인 — quad-debug 논의의 "Value
  오브젝트 기각, Attribute 우선" 결정을 보강함.
- **UICorner/UIPadding/UIScale 인라인 편의 키** — 사용자가 v1에서 "Frame
  안에 인라인으로 넣기만 해도 CSS처럼 적용됐다"고 기억한 기능, 서브에이전트로
  v1 소스(`class.lua`) 조사해 실체 확인: `Corner`/`PaddingAll(Offset)`/
  `Scale` 3종(+ 별개 메커니즘인 `RoundSize`)이 실제로 있었음(리터럴 값 하나
  → 이름 붙은 UICorner/UIPadding/UIScale 자식을 찾거나 생성). `UIListLayout`/
  Grid/Flex 전용 숏핸드는 없었음 — 그건 이미 quad-v2에 있는 범용
  children-array 메커니즘으로 충분히 커버되므로 새로 설계할 것 없음.
  **한 차례 "지금은 UICorner가 네이티브라 포팅 불필요"로 잘못 정리했다가
  사용자가 재정정**: `RoundSize`(이미지 9-slice 라운드 트릭)만 UICorner
  없던 시절의 워크어라운드라 포팅 불필요고, `Corner`/`PaddingAll`/`Scale`
  자체는 "UIScale 등이 여전히 별도 Instance라 부모에 붙여야 하는 구조는
  안 바뀌었다"는 이유로 **여전히 필요한 기능으로 재확정**. `research/
  ui-shorthand-plan.md`에 최종 정리 — 메커니즘은 기존 pluggable Handler로
  그대로 커버(새 아키텍처 개념 불필요), 패키지 배치는 `quad-roblox` 코어에
  직접 포함으로 확정(별도 `quad-roblox-util` 불필요 — "트윈도 하나로 묶어
  코어에 넣은 선례처럼, 작고 opt-in 아닌 건 분리 안 한다"는 사용자 판단).
- **quad-debug 플러그인 UI 구조 확정** — Explorer에서 quad 내부 자동
  생성물(예: 위 UICorner 숏핸드가 만든 것)을 직접 선택했을 때 플러그인
  트리에 대응 노드가 없으면 부모로 대신 선택, 있으면(사용자가 직접
  bind한 경우 등, UB 아님) 정확히 그 노드 선택. 내부 자동 생성물은
  `_`/`QUAD_` 접두어로 네이밍(v1 `_quad_round`류 재사용,
  `documentation-plan.md` 네이밍 컨벤션과 연결). 플러그인 UI는 세
  상호작용면(자기 트리 뷰/리프 클릭→상세 패널/실제 Explorer 선택과 연동,
  Explorer와 플러그인 트리는 별도 도킹 위젯)으로 구성된다는 것도 사용자
  질문에 확인 응답 — `debug-tooling-plan.md` "핵심 설계 방향" 9번.

