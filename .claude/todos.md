# 지금 할 일 (우선순위순)

루트 `CLAUDE.md`가 `@import` 하는 파일. **가장 자주 바뀜** — 해소된 항목은
미루지 말고 그 자리에서 지우고, 개수·목록은 여기 적지 말고 소스를 가리킬 것
(`.claude/question.md`, `luau-test/STATUS.md` 등).


00. **⭐⭐ [2026-08-18 신설] 구현 전 QA — 1·2·3라운드는 전부 `base/`에 반영
   완료, [2026-08-19 신설] 4라운드는 문항지 작성만 끝나고 사용자 회신 대기 중.**

   **4라운드(`.claude/qa-request/pre-implementation-qa-round4.md`) — 회신
   대기.** 사용자 요청("모든 확정 부분에 있어서 예가 되어야하는 질문들을
   계속 … 표면적 타입계약부터, 실제 내부 구현 계획과 동작 원리 등")으로
   `base/` 전 문서를 한 맥락에서 읽으며 확정 주장을 전수 문항화한 것.
   **아직 아무것도 정정하지 않았음** — 사용자가 "아니오"인 항목을 회신하면
   그때 `base/`에 반영하고 그 문서를 1라운드처럼 근거 기록으로 재편한다.
   문항 수/분포/읽는 순서는 그 문서 자신이 소스(여기서 세지 않음).

   **1~3라운드(완료)**: 1라운드는 사용자가 `base/` 확정 문서 전체를
   문항으로 재심사한 결과(원본 문답과 사용자 답변 원문은
   `.claude/qa-request/pre-implementation-qa-round1.md`가 소스), 확정으로
   적혀 있는데 실제로는 틀린 항목이 여러 건 나왔고 **같은 날 전부 정정
   반영됐다**(개수는 그 문서가 소스, 여기서 세지 않음). 그대로 구현하면
   반대로 돌던 두 건(`canBound` 게이트 방향, gcconn/gchold 강/약)도 닫혔다.
   2라운드는 `:List`의 `reconcile`/`recompute` 같은 확정 의사코드를 실제로
   손으로 실행해보는 작업(원본과 진행 로그는
   `.claude/qa-request/pre-implementation-qa-round2.md`가 소스) — `recompute`
   트레이싱에서 `Frame{A,B}`처럼 정적 자식 2개짜리도 첫 마운트에 크래시하는
   경로(`RC-1`)를 찾았고, 같은 날 후속 대화에서 사용자가 직접 제시한
   Blocker 재사용 게이팅 설계로 해결·반영까지 완료됐다
   (`archive/question-resolved.md`의 `RC-1` 절).

   **3라운드(완료, `.claude/qa-request/pre-implementation-qa-round3.md`가
   소스) — `RC-1` 해법이 실제로 `attachSlot`에 반영된 걸 트레이싱하다
   새 문제 발견, 같은 세션에 전부 해결·반영까지 완료.** 처음엔 `activateList`가
   자기 Slot의 Blocker가 켜지기 **전에** 실행돼 `:List` 초기 population이
   문제(`RC-3`/`RC-4`)를 낸다고 봤고, `recompute`가 의존하는 `bk.N`(순회
   상한)의 수명주기도 문서에 없어 "고정값/그때그때 실제 개수 둘 다 각기
   다른 방식으로 깨진다"고 판단했으나 — **사용자가 이 분석 자체를
   정정**했다: Blocker 게이팅은 `bk.N`이 아니라 `blocker:IsOn()`만 보므로
   "그때그때 실제 개수" 모델이 배치 크래시를 되돌린다는 결론은 틀렸었다
   (`bk.N` = 그때그때 실제 개수로 확정). `RC-3`/`RC-4`도 사용자가 더
   단순한 해법을 직접 제시 — flush 루프를 분기하는 대신 `attachSlot`의
   `slot._mounted = true`를 `activateList` 호출 뒤로 옮기는 것 하나로
   둘 다 닫힘. 부수로 `spliceArraysDown`이 밀어야 할 배열에
   `bk.observers`가 빠져 있던 것도 발견·반영, `ROADMAP.md` M2가 M3의
   `Blocker.luau`에 구조적으로 의존하게 된 것도 각주로 반영(마일스톤
   재편 여부는 열림 — `pre-implementation-qa-round3.md`의 "ROADMAP.md
   마일스톤 정합성" 절 참고).

   **아래는 M3 착수 전에 결론이 필요한 항목 목록**(M0/M2는 여전히 막혀
   있지 않음, 0번 항목 참고 — **단, M2가 M3의 `Blocker.luau`를 선당겨야
   하는지는 별개로 열려 있음, 바로 아래 첫 항목**) — 대부분 `question.md`
   3번에도 올라가
   있고(**[정정, 2026-08-18 `/code-review high`] 사용자 판단이 필요한
   항목만 그렇다 — 아래 "dedup 경로" 대칭 확인은 판단이 아니라 구현 시
   검증 작업이라 `question.md`엔 없음, 여기 목록이 소스**), 각 `base/`
   문서에도 ⚠️로 표시돼 있다:
   - **M2가 M3의 `Blocker.luau`에 의존하게 된 순서 문제**(`ROADMAP.md`
     M2 체크박스 각주) — 지금은 각주만 달아둔 임시 조치, `Blocker.luau`
     (또는 최소 표면)를 M2로 앞당길지 로드맵 순서를 유지할지 **M2 착수
     전 필요**. `qa-request/pre-implementation-qa-round3.md`의
     "ROADMAP.md 마일스톤 정합성" 절.
   - **중간 State GC 미검증**(`base/source-state-plan.md`) — 상류 strong /
     하류 weak 불변식을 명문화할지 + `luau-test` 실측. **M3 착수 전 필요.**
   - **그룹 `Attribute`의 위치별 claim 설계**(`base/attribute-plan.md`) —
     방향은 확정, 키 설계가 미정. M10 착수 전 필요.
   - **[2026-08-20 해소]** `SetAndDispose` 방향 — **`source:SetAndDispose(value)`
     콜론 메서드로 확정**(`:Set`과 한 세트). `state:Apply` 시그니처엔 영향
     없음(`Apply` 오버라이딩은 `Source`→`State` 단방향 때문에 타입이 안
     성립해서 애초에 불가). `base/slot-plan.md`의 `dispose` 절.
   - **dedup 경로의 process/retract 대칭 확인**(`base/effect-plan.md`
     `:Unsubscribe()` 절) — M3 착수 전 확인.
   - **[2026-08-19 해소]** `PopOnly` 이름 — **`Detach`로 확정**(공개 표면
     위치도 `None`과 같은 최상위 export로 같이 확정). 원문은
     `archive/question-resolved.md`.
   - **`Detach`(구 `PopOnly`) 홀드 중 키가 사라졌을 때의 처분**
     (`base/slot-plan.md`) — 지금 의사코드대로면 파괴도 반환도 안 되고
     참조만 끊김. **[정정, 2026-08-18 `/code-review high` — `ROADMAP.md`의
     M6 `Detach` 체크박스와 대조해 발견] M6(`:List`가 있는 마일스톤) 착수
     전 필요** — M8(`Ref`) 아님, 이전엔 마일스톤을 잘못 적어 M6를 그냥
     지나칠 위험이 있었음.
   - **`store:GetDynamic`을 콜론 메소드로 둘지 탑레벨 함수로 둘지**
     (`base/store-plan.md`) — 콜론이면 `GetDynamic`이 모든 Store의 예약 키가
     됨(lazy `__index`와 충돌). M3/M4 착수 전 필요.
   - **[2026-08-19 해소]** `Store` 미선언 키가 실제로 타입 에러가
     나는지 — **예, 확인됨**(`luau-test/done/21-type-store-undeclared-key-rejected.luau`,
     `ProcessStoreType`이 합성한 레코드 타입은 인덱서가 없어 미선언 키
     접근이 정확히 `TypeError`로 거부됨). `base/store-plan.md`의 "Store =
     Source들의 이름 붙은 모음" 절의 "확인 요구" 표시도 해소로 갱신 필요.

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
   지적, `base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절.
   **[정정, 2026-08-18] 두 predicate는 값이 같은 게 아니라 서로의 부정**이고
   게이트는 항상 `if not canBound(v) then error(...)` 모양이다 — 그 문서의
   같은 절이 소스).
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
     `setAttribute`). **Handler 작성 체크리스트**(개수는 그 문서가 소스)를 새 핸들러 짜기 전에
     훑을 것 — 지난 세션들에서 실제로 반복된 실수 목록임.

   해소 전 원문은 `archive/question-resolved.md`(0-Y/0-Z/0-A 절), 뒤집힌 옛
   재디스패치 모델 전문은 `archive/dispatch-hintvalue-model-reversed.md`.

1. **구현 시작 — 루트 `ROADMAP.md`의 M0부터.** 설계 단계는 2026-08-04 로드맵
   인수인계 라운드로 종료. `research/pre-implementation-audit.md` 우선순위1은
   2026-08-12 열일곱 번째 세션에 마지막 넷(1-3/1-4/1-10/1-11)까지 전부
   해소되어 **전원 완료**(항목 수는 그 문서가 소스). **[14차 세션 기준] 0-Y/0-Z/0-A까지 전부
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
   — 아직 진짜로 열려있는 것만 짚으면(**[2026-08-18] `DI`→`D`는 확정·반영
   완료로 목록에서 빠짐**, **[2026-08-19] `PopOnly`→`Detach`도 확정·반영
   완료로 목록에서 빠짐**): `Slot`(2순위),
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
   **[2026-08-14 추가, 2026-08-19 설계 전부 해소 후 `base/`로 승격]** 시간
   기반 전파 게이트 `Debounce`/`Throttle`(`base/debounce-throttle-plan.md`)도
   백로그이지만 위 항목들과는 발단이 다름 — **사용자가 직접 요청한 실제
   기능 갭**에서 시작됨(그 문서 13절). 다만 제어 핸들 설계까지 닫히고 나니
   실제로 quad-base에 새 코어 메커니즘을 추가하지 않는 **순수 슈가**로
   확인돼(같은 절), 위 항목들과 우선순위는 다시 같아짐 — M0/M3를 막지
   않고, **M3에서 `Blocker`를 구현할 때 게이티드 노드를 공용 `Gate`로
   빼두는 것만은 그 시점에 해야 함**(따로 하면 같은 설계를 두 번 함).
   주입 op 2개(`setTimeout`/`clearTimeout`)가 백엔드 팩토리 표면에
   추가될 예정이라는 것도 M1 설계 시 인지. 남은 열린 질문 없음(구
   `question.md` 3번, 전량 해소로 항목 자체가 빠짐).
   **[2026-08-18 추가]** 사용자 아이디어 메모 두 건도 같은 성격의 백로그로
   신설 — 스크롤 최적화 외부 유틸 `quad-roblox-fastscroll`
   (`research/fastscroll-plan.md`, 선행으로 `Visible=false`일 때
   `AbsoluteSize`/`AbsolutePosition` 갱신 여부 실측 필요)과 스프링 물리
   기반 지속 업데이트 프리미티브 `quad-spring`(`research/spring-plan.md`,
   참고 구현 `qwreey/spring.lua` 사용 가능성 확인 필요) — 둘 다 설계 논의
   전 아이디어 단계이고 사용자가 직접 "아주 나중"으로 후순위 지정, M0/설계
   게이트와 무관.
   **[2026-08-19 추가]** `quad-roblox-types`(가칭, `quad-types`와 같은
   패턴으로 `quad-roblox` 전체 대신 그 타입만 필요한 모듈을 위한 패키지)도
   같은 성격의 백로그로 신설 — 사용자가 지금 만들 필요는 없다고 명시적으로
   후순위 지정, 상세는 `base/quad-types-plan.md`의 "남은 것" 절.
5. 자율 작업 루프/스케줄 설정 여부는 사용자 결정 대기 중
   (`HUMAN_TODO.md` 2번 항목).
6. **[신규 백로그, 2026-08-14 열네 번째 세션]** 문서 stale 감소용 include
   도구 `doc-include.py`(가칭, `doc-check.py`와 짝) — `research/
   doc-include-plan.md` 참고(상태의 소스는 그 문서). **[2026-08-16 기준]**
   같은 날 CLAUDE.md 분할로 파일럿이 "`session-summary.md`를 통째로
   생성"하는 **단방향** 설계로 단순화돼 플랜이 갱신됨(목적지 마커 불필요).
   여전히 **구현 착수 전**. M0/설계 게이트와 무관.
7. **[2026-08-16 신설, (a)~(d) 전부 닫힘 — 다만 아래 두 건이 미해결로 남음]** 감사 툴링 검증.
   (a) `@import` 3개(`conventions.md`/`project-context.md`/`todos.md`)
   실제 로드 — **확인됨**, (b) `quad-doc-auditor` 레지스트리 등록 —
   **확인됨**(첫 실측 때 전원 `agentType not found`였던 건 `.claude/agents/`가
   세션 도중 생긴 디렉토리였기 때문, 재시작으로 해소), (c) frontmatter
   `model: sonnet` 반영 — **확인됨**(서브에이전트 트랜스크립트에
   `claude-sonnet-5` 기록), (d) **해소** — 읽기 전용인데 Write/Edit이
   주어지던 원인은 `memory: project`가 맞았음(근거는 `.claude/agents/quad-doc-auditor.md` 상단 배너). 다만
   `tools:` 필드가 그대로 반영되지 않는 건 **여전히 미해결**이라, 읽기
   전용은 도구 유무가 아니라 프롬프트의 행동 규약으로 계속 지킨다.

   **[2026-08-16] 이번 세션의 감사 루프는 4라운드에서 사용자 결정으로
   중단 — 수렴 조건(무발견 2연속)은 못 채웠다.** 라운드별 새 발견은
   6→5→2→2로 줄었고, 3·4라운드에 나온 것은 **이 세션 변경의 stale이 아니라
   코퍼스에 오래 있던 일반 부채**(개수 하드코딩, 날짜 없는 시한부 주장)라
   계속 돌리면 수렴이 아니라 옛 부채를 끝없이 캐는 쪽이 된다는 판단.
   **이 세션 변경분 자체는 안정적**(4라운드 설계 코퍼스 각도에서 확실
   발견 0건). 다음 세션이 중대 변경을 하면 그때 평소대로 감사 루프를
   돌리면 되고, 이번 미수렴 때문에 따로 이어서 돌릴 필요는 없다.

   **미해결 1 — 정의 파일이 언제 반영되는지 모른다.** 감사자가 실제로 받은
   정의 텍스트가 실행마다 달랐다: 세션 시작 상태 → 그 시점 HEAD 커밋 →
   **어느 커밋과도 일치하지 않는 중간 워킹트리 상태**(커밋된 적 없음,
   `git log -S`로 확인). 이 세션이 "세션 시작 스냅샷", 이어서 "커밋된
   HEAD에서 읽힌다"로 두 번 결론을 냈다가 **두 번 다 반증됐으니 세 번째
   가설을 세우지 말 것.** 실무 규칙은 하나 — **정의를 고쳐도 반영됐다고
   가정하지 말고, 중요하면 마커 문구를 넣어 감사자에게 물어 확인할 것.**
   상세 관측표는 `.claude/agents/quad-doc-auditor.md` 상단 배너가 소스.
   (워크플로 쪽은 `Workflow({scriptPath})`가 디스크에서 실시간으로 읽는 게
   확인돼 있으나, 지금 워크플로를 안 쓰므로 당장 쓸 일은 없음.)

   **미해결 2 — `tools:` 필드가 그대로 반영되지 않는다**: frontmatter에 적힌
   Grep/Glob이 안 주어지고, 적지 않은 `advisor`가 주어진다. 그래서 감사자의
   읽기 전용은 도구 유무가 아니라 프롬프트의 행동 규약으로 지킨다.

   **[2026-08-16 닫힘] 재감사 안 됐던 수정 6건은 확인 완료** — 첫 실동이
   수렴 못 하고 끊겨 마지막 라운드분이 재감사 없이 커밋됐었는데, 새 절차의
   첫 라운드(감사 2개 병렬)가 그 셋(spikes 개수 단일화, `slot-plan.md`
   재역전 배너, `doc-check.py` docstring)을 다시 훑어 **회귀 없음**으로
   확인했다. 한 패스는 구세대 트리(`8aeec76`)와 현재본의 WARN 목록을 직접
   diff해서 대조했고, 그 구간에 오히려 절 참조 오류 2건이 해소된 것도
   확인됨. M0/설계 게이트와 무관.


8. **[2026-08-16 신설, 이미 닫힘 — 다음 세션이 알아야 할 규약]** 절 인용
   규약이 생겼다. 이제 `` `<파일>.md`의 "절 제목" `` 형태로 인용할 땐
   **의역하지 말고 원문에서 잘라 쓸 것**(`#` 헤딩은 부분문자열, `**볼드**`
   절은 줄머리 + 앞부분일치). 규칙 본문은 `.claude/conventions.md`의
   "절 인용 규약"이 소스 — 여기서 반복하지 않음. 지키지 않으면
   `doc-check.py`가 **ERROR**로 잡아 커밋 게이트에 걸린다(WARN이 아님 —
   절 참조 불일치를 78→0으로 정리한 뒤 승격했음). 경위는
   `session/2026-08-16-03-doc-check-section-convention.md`.

9. **[2026-08-16 신설, 이월 — 급하지 않음]** 이번 절 인용 규약 작업에서
   의도적으로 **안 한** 것 둘. 둘 다 다음 세션이 알아야 이중 조사를 안 한다.
   - **`#` 헤딩 검사가 부분문자열이라 느슨하다.** `"확정"` 같은 짧은 인용은
     같은 파일의 무관한 헤딩에 걸려 통과한다(`base/slot-plan.md`엔 "확정"이
     든 헤딩이 여러 개). 커밋 전 감사가 **실제 오매칭 사례를 하나도 못
     찾았고**, `conventions.md`의 "드문 오용이나 가상의 미래 요구까지
     방어/최적화하려고 구조를 복잡하게 만들지 않는다" 원칙에 따라 지금은
     안 고치기로 사용자와 합의. 실제로 물리면 그때 좁힐 것(길이 하한, 후보
     2개 이상이면 WARN 등).
   - **⚠️ 감사자에게 `git stash`를 쓰지 말라고 프롬프트에도 매번 적을 것.**
     커밋 안 된 작업 트리에서 감사자가 HEAD 대조하려고 stash를 걸어 메인
     세션의 스테이지가 반복적으로 풀렸다(2026-08-16 실동, 유실은 없었음).
     금지 규약을 `.claude/agents/quad-doc-auditor.md`에 넣어두긴 했지만
     **정의 파일이 언제 반영되는지 모른다는 게 위 7번의 미해결 1번**이라,
     정의에만 의존하지 말고 감사자를 띄우는 프롬프트에서 직접 금지할 것.
     대안은 `git show HEAD:<경로>` / `git diff HEAD -- <경로>`.
