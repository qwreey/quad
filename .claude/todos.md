# 지금 할 일 (우선순위순)

루트 `CLAUDE.md`가 `@import` 하는 파일. **가장 자주 바뀜** — 해소된 항목은
미루지 말고 그 자리에서 지우고, 개수·목록은 여기 적지 말고 소스를 가리킬 것
(`.claude/question.md`, `luau-test/STATUS.md` 등).


0. **⭐ M0 착수를 막는 결정은 이제 없음 (2026-08-14 열한 번째 세션 기준).**
   `question.md`의 최우선 항목이 **전부 비었음** — `0-Y`(`:Compute` lazy
   핸들 계약)는 13차 세션에, `0-Z`(Attribute 이름 소유권)와 `0-A`(재디스패치
   하강 diff)는 14차 세션에, `0-B`(`dispose` 시그니처/범위)는 2026-08-14
   열 번째 세션에 확정·`base/` 반영 완료. **`0-W`(같은 `Ref` 이중 배치,
   M8 구현 세부만 막던 항목)도 2026-08-14 열한 번째 세션에 해소** —
   선택지 (a) 채택(즉시 error), 메커니즘은 새 `Relate` 없이
   `bindLifetime`/`unbindLifetime` 재사용(`base/ref-plan.md` "이중 배치
   방지" 절). 부수 결정으로 **`canBound`가 `canExecute`와 별도 진입점으로
   재도입**됨(2026-08-14 다섯 번째 세션에 하나로 합쳤던 걸 부분적으로
   되짚음 — "이미 묶여 있는가"(bound 문맥)와 "지금 발화해도 되는가"
   (execute 문맥)는 판정 로직은 공유해도 호출부의 질문이 다르다는 사용자
   지적, `base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절).
   `question.md`엔 이제 "결정 대기" 절 자체가 없음(비어서 헤딩째로 삭제).

   **M0 착수 전 반드시 읽을 것 — 이 두 개는 "결정"이 아니라 "구현 규약"이라
   여전히 유효**:
   - **`base/typing-limits.md`**(0-Y의 산물) — 핵심은 "파생 State를 만드는
     자리마다 결과 타입을 명시 주석으로 바인딩" + 7번 설계 체크리스트.
     재귀 제네릭이 자기를 다른 타입 인자로 반환하면 Luau가 타입 안전성을
     **에러 없이 조용히** 잃는 상위 한계라 quad 쪽에서 우회하지 않기로
     확정(RFC `relax-recursive-type-restriction` 수혜 대기, 추적
     `luau-lang/luau#2380`). 실측 근거는 `audit/type-recursion-issue/`.
   - **`base/dispatch-core-plan.md`**(0-A/0-Z의 산물, 14차 세션에
     `bind-system-plan.md`에서 분리 신설) — 재디스패치가 "철거 후 재구축"이
     아니라 **하강 diff**임, `retractFrom`은 3-인자, 클로저 인자는
     `nil`이거나 같은 핸들러가 처리할 값(타입 보장), `HANDLER_PRIORITY_FALLBACK`,
     "base가 소유하는 핸들러와 주입되는 엔진 op"(`addTag`/`removeTag`/
     `setAttribute`). **Handler 작성 체크리스트 8개**를 새 핸들러 짜기 전에
     훑을 것 — 지난 세션들에서 실제로 반복된 실수 목록임.

   해소 전 원문은 `archive/question-resolved.md`(0-Y/0-Z/0-A 절), 뒤집힌 옛
   재디스패치 모델 전문은 `archive/dispatch-hintvalue-model-reversed.md`.

1. **구현 시작 — 루트 `ROADMAP.md`의 M0부터.** 설계 단계는 2026-08-04 로드맵
   인수인계 라운드로 종료. `research/pre-implementation-audit.md` 우선순위1은
   2026-08-12 열일곱 번째 세션에 마지막 넷(1-3/1-4/1-10/1-11)까지 전부
   해소되어 **11개 전원 완료**. **[14차 세션 기준] 0-Y/0-Z/0-A까지 전부
   해소돼 설계 게이트는 남아있지 않음** — 착수 전 읽을 것은 위 0번의 두
   문서(`typing-limits.md`/`dispatch-core-plan.md`)뿐이고, 스파이크 상태는
   아래 그대로:
   - **`.claude/luau-test/`(2026-08-09 신설) 스파이크 결과 — [2026-08-13
     여섯 번째 세션에 첫 실측 완료, 대부분 닫힘].**
     **상태의 소스는 항상 `.claude/luau-test/STATUS.md`**(pass / 사람 결정
     필요 / 스파이크 깨짐 / 미실행, 폴더 구조 자체가 상태) — 총 몇 개인지도,
     지금 몇 개가 어느 폴더에 있는지도 여기서 세거나 나열 안
     함(04/05/10/13/15/16/19가 여러
     세션에 걸쳐 재설계로 `rewrite-required/`에 들고나며 이 문단의 나열이
     매번 stale해지는 패턴이 반복됐음, 최근엔 8차 세션의 "emit은 항상
     전파" 정정으로 `05`도 합류). 실행 결과 상세는
     `.claude/audit/luau-test-first-run-2026-08-13.md`. 첫 실측 요지만
     (역사적 사실 — 이후 변동은 위처럼 `STATUS.md`가 소스):
     - **런타임 12개 전원 통과**(01~07/11/17/18/19/20, crash 0 / FAIL 0) —
       특히 `07`이 연쇄 GC를, `18`이 두-`Relate` 상호 순환 미해제를 실측
       확정해 GC-native 아키텍처의 핵심 전제가 검증됨. `04`는 같은 세션
       감사가 찾은 `chains:SetStrong` 순서 버그를 음성 대조군으로 재현.
     - **타입 쪽에서 하나가 걸렸었음** → 그게 구 **0-Y**, **[13차 세션]
       해소**(Luau 현 한계로 확정, `base/typing-limits.md`). 나머지 타입
       스파이크는 판정 완료(`08`/`09` 통과, `12`는 실패지만 문서가 이미
       fallback으로 예비해둔 결과라 설계 영향 없음, `14`는 부분).
     지금 M0 착수를 막는 설계 결정은 없고, 0-Y/0-A가 남긴 규약
     (`base/typing-limits.md`/`base/dispatch-core-plan.md`)은 착수 전 필독.
2. **용어 정리 — 1차 제안 이후 대부분 확정, 소수만 남음.** 최신 소스는
   `.claude/question.md` 1번(개수 반복 안 함, 항목 추가/해소될 때마다 여기가
   stale해지는 패턴이 반복됐어서). **[2026-08-13 정정]** `State`는
   2026-08-12 스무 번째 세션에 현재 이름 그대로 유지로 이미 확정됐음(이
   목록이 "위험도 높음, 1순위 open"으로 stale하게 남아있던 걸 발견해 수정)
   — 아직 진짜로 열려있는 것만 짚으면: `DI`→`D`(1순위), `Slot`(2순위),
   `canExecute`(3순위 — `isAlive`는 검토 후 기각, `can` 계열 접두 유지
   방향으로 기울었으나 구체 대안 미정), `Brand`(3순위), `Tag`/`Added`/
   `Removed`/`Merged`(3순위), `Attribute`/`AttributeKey`(3순위).
3. **[2026-08-14 세션에 해소]** 오래 열려 있던 "이미 생성된 인스턴스
   재바인드"는 **기각**되어 `archive/existing-instance-bind-rejected.md`로
   이전됨 — 더 이상 상의할 스코프 항목이 아님.
4. **[백로그]** 범용 렌더 디버깅 도구 `quad-mock`(Tween mock 등 동적 동작
   지원, M0 mock 테스트 하네스와는 별개), 런타임 디버깅 플러그인
   `quad-debug`(Studio 플러그인, 실물 Instance→코드 위치 역추적 — 채널
   실현 가능성은 실측 검증 완료, 세부 API 이름만 남음), 문서 사이트 전체
   구조(초심자/api/심화/`quadnomicon` 4축 + 콘텐츠 맵), `Operator` 콤비네이터
   슈가(`Sum`/`Product`/`Not`/비트연산 등 `:Compute`/`:Apply`용 — 메커니즘은
   확정, 네임스페이스 이름만 미정, 구현은 순수 슈가라 맨 마지막), 컴포넌트
   에러 격리 유틸 `Fallback`/`Traceback`(**[2026-08-14 세션, 설계 확정 —
   `research/`에서 `base/fallback-plan.md`로 승격]** `pcall` 기반
   `Fallback`과 `xpcall`+`debug.traceback` 기반 `Traceback`으로 분리,
   `err: any` 확정, 패키지·이름 전부 확정 — **설계만 끝났을 뿐 구현
   우선순위는 그대로 맨 뒤**), 생명주기 훅
   `OnCreated`/`OnRendered`/`OnDestroyed`(**[2026-08-14 아홉 번째 세션,
   `research/`에서 `base/lifecycle-hooks-plan.md`로 승격]** 각각
   `PreRef`/`PostRef`/`Effect`를 반환하는 순수 팩토리 함수 슈가 —
   `OnRendered`도 **채택 확정**, 그게 얹히는 `PostRef` 프리미티브 자체는
   슈가가 아니라 디스패치 코어라 **ROADMAP M8에서 `PreRef`와 같이 구현됨**
   (백로그가 아님, `base/ref-plan.md`의 "`PostRef`" 절). 훅 슈가 셋만
   후순위) — 전부
   "quad 개발 상당 부분 끝난 뒤"로 사용자가 못박은 후순위. 상세는
   `.claude/README.md`의 `base/` 표(`fallback-plan.md`/
   `lifecycle-hooks-plan.md`)와 `research/` 표
   (`debug-tooling-plan.md`/`documentation-plan.md`/
   `documentation-content-map.md`/`framework-comparison-findings.md`/
   `operator-sugar-plan.md`).
   **[2026-08-14 추가, 성격이 다름]** 시간 기반 전파 게이트
   `Debounce`/`Throttle`(`research/debounce-throttle-plan.md`)도 백로그이긴
   하나 위 항목들과 달리 **사용자가 직접 요청한 실제 기능 갭**이고 순수
   슈가가 아님 — M0/M3를 막지는 않지만, **M3에서 `Blocker`를 구현할 때
   게이티드 노드를 공용 `Gate`로 빼두는 것만은 그 시점에 해야 함**(따로
   하면 같은 설계를 두 번 함). 주입 op 2개(`setTimeout`/`clearTimeout`)가
   백엔드 팩토리 표면에 추가될 예정이라는 것도 M1 설계 시 인지. 설계는
   네 라운드로 대부분 확정됐고 남은 열린 질문은 `question.md` 3번(개수는
   거기도 반복 안 함 — 소스는 `research/debounce-throttle-plan.md` 12절).
5. 자율 작업 루프/스케줄 설정 여부는 사용자 결정 대기 중
   (`HUMAN_TODO.md` 2번 항목).
6. **[신규 백로그, 2026-08-14 열네 번째 세션]** 문서 stale 감소용 include
   도구 `doc-include.py`(가칭, `doc-check.py`와 짝) — `research/
   doc-include-plan.md` 참고(상태의 소스는 그 문서). **[2026-08-16 기준]**
   같은 날 CLAUDE.md 분할로 파일럿이 "`session-summary.md`를 통째로
   생성"하는 **단방향** 설계로 단순화돼 플랜이 갱신됨(목적지 마커 불필요).
   여전히 **구현 착수 전**. M0/설계 게이트와 무관.
7. **[2026-08-16 신설, 대부분 닫힘 — 남은 건 (d) 하나]** 감사 툴링 검증.
   (a) `@import` 3개(`conventions.md`/`project-context.md`/`todos.md`)
   실제 로드 — **확인됨**, (b) `quad-doc-auditor` 레지스트리 등록 —
   **확인됨**(첫 실측 때 전원 `agentType not found`였던 건 `.claude/agents/`가
   세션 도중 생긴 디렉토리였기 때문, 재시작으로 해소), (c) frontmatter
   `model: sonnet` 반영 — **확인됨**(서브에이전트 트랜스크립트에
   `claude-sonnet-5` 기록), (d) **미해소** — 읽기 전용인데 Write/Edit이
   주어지는 원인. `memory: project`를 뺐지만 그 뒤 재시작 없이 돌린
   관찰뿐이라 진단 미확정이고, **다음 세션 시작 직후에 한 번 확인하면 됨**.
   결론 날 때까지 읽기 전용은 도구 유무가 아니라 프롬프트의 행동 규약으로
   지킨다.

   **부수 확정 — 워크플로는 `name`으로 부르면 세션 시작 스냅샷, `scriptPath`로
   부르면 디스크 실시간**(둘 다 1차 증거 있음). **워크플로 정의를 고쳤으면
   재시작하지 말고 `scriptPath`로 호출할 것** — 이름으로 부르면 옛 정의로
   돌면서 새 정의로 돈 것처럼 보인다. 에이전트 정의도 stale하게 로드된 정황이
   있으나 그건 자기 보고뿐이라 근거 등급이 낮고, 우회 수단도 없어 재시작이
   보수적 해법. 상세는 `.claude/agents/quad-doc-auditor.md` 상단 배너가 소스.

   **⚠️ [2026-08-16] 코퍼스에 재감사 안 된 수정이 들어있음** — 첫 실동이
   수렴하지 못하고 최대 라운드로 끊겨서, 마지막 라운드의 새 발견 6건은
   반영만 되고 다시 감사되지 않았다(diff는 사람이 손으로 검토했고 핵심
   주장은 1차 근거로 확인했지만 dry 라운드와 같지는 않음). **다음
   `quad-handover-audit` 실동의 첫 임무가 이걸 재확인하는 것.** 겸해서
   `MAX_ROUNDS`/"연속 dry 2회" 조건도 재검토 대상(새 발견이 단조 감소하지
   않았음: 28→15→16→7→11→6). M0/설계 게이트와 무관.

