# 지금 할 일 (우선순위순)

루트 `CLAUDE.md`가 `@import` 하는 파일. **가장 자주 바뀜** — 해소된 항목은
미루지 말고 그 자리에서 지우고, 개수·목록은 여기 적지 말고 소스를 가리킬 것
(`.claude/question.md`, `luau-test/STATUS.md` 등).


00. **⭐⭐⭐ [2026-09-06 기준] 마일스톤 M0~M11 전부 완료 — 열린 마일스톤 없음.**
   진행의 소스는 루트 `ROADMAP.md`(상단 배너·완료 표), 결정 이력은 `session-summary.md`,
   각 마일스톤의 규약·발견 원장은 **[2026-09-07 재편]** `archive/v2-initial-implementation/`
   (`mN-implementation-roundNN(-brief).md`, round11~21 + pre-implementation 1~10 + 옛 ROADMAP
   본문 `roadmap.md`). 종결 기록은 여기 쌓지 않는다 — 이 파일 규약(맨 위) 그대로.
   **지금 사용자 몫**(답을 주면 반영한다):
   - **[2026-09-07]** `qa-request/post-implementation-review-round1.md` §4 Q1~Q17(핸드오버 전체
     코드 리뷰 — `NewChild` 팔 둘·품질 제안 묶음 `H-356`·Property 핸들 오용 진단·같은 키
     재진입 UB 명시·**Q6** native* 조합 폴백 약속 철회·**Q7** 미설치 스텁 무태그 여부·**Q8**
     `Animate` nil/None 통과 팔·**Q9** 부모 Destroy 뒤 Slot 좀비(유일한 동작 결함 문항)·**Q10**
     `AddPlugin` 락 우회·**Q11** Modifier setter 키·**Q12** Tween 동일값 재발행·**Q13~Q17**(5순회 —
     `setOffsetSource` 게이트·`destroySlotTree` `releaseOwner`·`setLength` 도메인·`Tween.validate` State·
     `numberOnly`)·**Q7 둘째** `_assertBindable` 방향). §1·§5~§11의 ① 갈래(`H-344`~`H-402`; 야간 0~3 +
     주간 4·5순회)는 반영·커밋됨(CLI 49/49) — 순회는 사용자 지시로 계속(batch 쌓는 중). §12에 `H-403`(`isSlot` → Brand)·`H-404`(전역
     게이트)·`H-405`(exit code)·6순회 `H-406`~`H-416`(Property 트윈 Create 선행·SlotHandler 파괴 값
     pre-pass·`getOffsetAt` 범위 에러 복원 등; **Q18~Q20·Q7 셋째** 추가), §13 Gemini 검증(`H-417`~`H-419`),
     §14 7순회 `H-420`~`H-430`(**HIGH** 생성기 `ContentId`→`Content` 오매핑으로 `Image` 등 10슬롯이 문자열을
     거부하던 것 — 재정규화·재생성; gen-d `check`·모듈 스코프 전역 게이트가 test.sh에; **Q21** 툴체인 핀·selene).
     **§15 사용자 회신 1차(2026-09-07 오후)** — Q2 (a) 반영(`NewChild`에 `Observer`/`EffectHandle`), Q3 ②③④⑤⑥⑦
     반영(`NotInstalled.luau`·`Dispatch.setEmpty`·`Reflection.luau`·`addProcessedHandler`·`assertMutable`·gen-d
     소스 읽기)·①⑧⑨ 보류(ROADMAP 백로그 최적화 후보 목록). 라운드 번호 1부터(round2 = Gemini). **§16 회신 2차 — Q1
     닫힘: 입력 자리의 State/Slot 팔을 공변 마커로**(`StateMarker`/`SlotMarker`, quad-types·gen-d·`NewChild`·spec; `PV73`
     11팔 → 4팔, 타입 검사 4.96s → 3.41s, `LuauSolverConstraintLimit` 제거; `typing-limits.md` 8.11). 순수 팬텀 필드
     `__quadStateValue`/`__quadSlotValue`는 사용자 확정(*"런타임 값에 없는 팬텀 괜찮아 … 값이 싸다면 그래도 좋아"*).
     **round3**(`qa-request/post-implementation-review-round3.md`, 마커 커밋 리뷰): ① `H-431`(NewChild State 팔에
     Observer/EffectHandle — `State<Observer?>` 종료 관용구)·`H-433`~`H-439` 반영, ② **Q22**(Slot 공변 + 가변 출력)·**Q23**
     (`FieldOut` 모양)·**Q24**(승인 범위 — 이름·팔 모양·플래그).
     **회신 3차(2026-09-07 저녁, 대화형)**: Q4~Q19·Q7 둘째·셋째 전부 닫힘(round3 §6 — Animate `Dedup`·nil/None 통과, Slot 좀비
     메시지+UB, `releaseOwner`, setter 키·`setOffsetSource`·`setLength` 게이트, `numberOnly` 제거, `PropTypesRead`, Compute 순수성
     원칙); Gemini 4차 → round4 파일·`H-440`~`H-444` 반영; `research/deferred-hardening-plan.md` 신설. **회신 4차**: Q6(약속 철회+백로그)·Q20(메시지 확장)·Q21(luau 핀·selene 폐기)·Q22(그대로)·Q23(FieldOut 한 팔) 닫힘(round3 §7).
     Q24도 설명 뒤 (a) 확정(+`Peek` 반환을 `FieldOut<T>?`로 통일).
     회신 3차 묶음 리뷰(round3 §8, `H-445`~`H-452` 반영 — `H-445`는 Q15 검사가 차단기 창 안에서 던져 owner를 동결시키던 회귀).
     **[2026-09-07 밤] 구조 재편 회신 반영 완료**(`session/2026-09-07-04-source-layout-reply.md`, 결정은
     `research/source-layout-plan.md` 각 절 `[결정]`·9절 상태·10절): Tag 유니언, **Brand→quad-types**, **Tween→quad-roblox
     통째**(`typing-limits.md` 8.12 부수 발견), 마커 전면화 + quad-types 재배치, 패밀리 폴더(`Ref/`·`Attr/`·
     `Dispatch/Modifier/`·`Slot/`), `doc-check.py` `.luau` 경로 검사. 외부 모델 감사 진입점 `qa-request/external-review-entry.md`.
     **[2026-09-08 아침 회신 반영 — round3 §12]** Gemini 코드 품질 자문(`qa-request/post-implementation-review-round6.md` — 옛 무시 파일, 2026-09-08 정식 편입;
     커밋 안 됨) 권고 셋 — `__tostring`(목록 고정, `spec.tostring` 스펙 50)·`setFuncLevel(level, ...fns)`(옛 시그니처 폐기, `H-475`)·
     메시지 헬퍼 기각 → `architecture.md` "메시지 모양" 규약 + 열 곳 손질(`H-477`); 옛 `Attribute` → **`Attr`**(+`AttrKey`·`setAttr`, 폴더
     `Attr/`); 10-4는 리서치 대상으로; Q26 (a) 축소판(`H-476`), Q27 등록 op 기각(모듈 `is<Brand>` 필드가 계약, 진단 스캔).
     같은 날 아침 후속: **Q25 닫힘 — 값 비교 모델**(`H-478`: Property 핸들러가 목표 `Value`만 비교, `Dedup`은 Tween 필드,
     옛 Q12 신원 모델·슬롯 `Source` 폐기, `InstanceShorthand` 무변경). **[2026-09-08 오전 후속]** 사용자 반입 RFC 다섯(무시 파일) 판정 — `qa-request/post-implementation-review-round7.md`: 적용 `H-479`~`H-483`(Clear/ExtractAll O(N²) → 배치 1회, 실측 1000개 130ms → 1~3ms; List `prevKeys` 스왑; `IndexOf` 역맵; setter 클로저 캐시; recompute abs 온디맨드 — 사용자 판정), 문항 Q37~Q39는 **같은 날 오후 회신으로 닫힘**(round7 §6 — Q37 (a) `keyType` 반영 `H-484`, Q38 백로그, Q39 폴더별 README 분리만·루트 README 백로그). **남은 사용자 몫: flatten 슈거 일곱(+named 자리 축,
     사용자 "내일") — `question.md` 2절.** [2026-09-07 밤 탐사 순회] opus 탐사자 둘(전체 스코프) + Gemini 5차(`round5.md` §1~§6, 사용자 회신 Q30~Q32 포함) → round3 §10 `H-463`~`H-474` 반영(전부 메인 실측; Gemini 다섯 건의 "nil 키 읽기 VM 에러" 전제는 틀림 — 읽기는 nil, 쓰기만 에러). **[2026-09-08 새벽 회신 5차]** Q33~Q36 닫힘(round3 §11 — Property nil 쓰기(M10 skip-defense 역전)·보간 가능 타입만 Tween 팔·`Parent` 읽기 표면·KeyGone `ud`는 사용자 재량), Q30~Q32는 사용자 본인 회신 확인. 다음 순회는 round3 §12·`H-475`부터. 문항은 앞으로 평문 한 문단으로(사용자: 기호·압축 서술이 읽기 어려움).
   - **[2026-09-07]** Gemini 외부 리뷰(`qa-request/post-implementation-review-round2.md`, G-01~G-09·S-01~S-06)는
     메인이 판정해 원장 **§13**에 반영 — 실존 셋(`H-417`~`H-419`) 반영·커밋, 나머지는 확인 기록. 사용자 몫 없음
     (G-03/G-09는 기존 Q18/Q3 ⑨에 논거만 추가).
   - **[2026-09-07 밤 반영, 2026-09-08 닫힘]** 소스 구조 재편 — `research/source-layout-plan.md`. 여덟 중 일곱 +
     후속 셋은 07 밤에, 8절 `Attr` 축약은 08 아침에 반영(`66281ab`), 10-4는 리서치 대상으로 — 남은 사용자 몫 없음.
   - `research/component-flatten-sugar-plan.md` 2절 "정해야 할 것" 일곱(컴포넌트 경계
     flatten 슈거 — round21 Q2·`H-340`의 후속, 백로그; `question.md` 2절).
   - 백로그 착수 순서(ROADMAP 백로그 절 — `quad-mock`/`quad-debug`/문서 사이트/
     `Operator` 슈가/`Fallback`·`Traceback`/생명주기 훅 슈가/`Debounce`·`Throttle`/
     `fastscroll`/`spring`/`quad-roblox-types`).
   **다음 세션이 먼저 볼 것**: `conventions.md` 2026-09-06·09-07 항목(백그라운드 에이전트
   종료 판정 — 알림 `status: completed`가 종료 / test.sh 판정은 exit code / 문항·발견은 평문),
   `question.md` 2절(flatten 슈거 일곱 — 사용자 "내일"), 루트의 사용자 메모 파일 둘(`-ignoreme`
   접미, 커밋 제외 — Bookkeeping abs 온디맨드 RFC·Vide/Fusion 전환 가이드 초안, 착수는 사용자 지시 뒤).
   **직전 구간 요약**(원문 `session/2026-09-08-01-advisory-and-user-items.md`): Gemini 자문
   권고 셋 판정(`__tostring` 목록 고정·`setFuncLevel(level, ...fns)`·메시지 헬퍼 기각) → `Attr`
   축약 → Q26·Q27 → Q25 값 비교 dedup(`H-478`) → 신원 잔재 탐사 → 2026-09-08 감사 스윕(sonnet
   넷 병렬, 사용자 지시). test.sh exit 0(스펙 50), doc-check ERROR 0.
   **[2026-09-08 오후 누적 감사 — round8]** 감사자 다섯 병렬(사용자 지시) → 동작 회귀 0·옛 결정 역전 0, 반영 `H-486`~`H-491`;
   Q40(`Slot:Clear` 창 안 파괴 → 던지면 그 Slot 동결)은 **같은 날 회신으로 (a) 닫힘**(round8 §6). **2차(실행 기반 탐사 다섯, round8 §7)**: 동작 결함은 Slot 순환 하나(`H-500`), 나머지는 게이트·blame·메시지·의사코드(`H-492`~`H-503`). **사용자 몫 Q41·Q42**(round8 §8) **+ Q43~Q46**(round8 §11 — 타입 표면: 무인자 `Store()` strict 에러·`{ Instance }` 변수 인덱서 불변·컴포넌트 경계 타입 재노출·`Of` 무주석 `any`; 8.13) (round8 §8 — `D.New` 클래스 이름 오타의 blame·Instance 매개 Slot 순환, 둘 다 실기기 실측 필요; 권고 (a) HUMAN_TODO 실측 항목). 3차(K 커밋 리뷰·N 문서 감사) 반영 `H-504`(nil owner 게이트 전수) + 정본 정정(K-1 J-4 오독 되돌림 등)은 round8 §9. 원문 `session/2026-09-08-03-cumulative-audit.md`.


2. **[백로그] 용어 정리 — 1차 제안 이후 대부분 확정, 소수만 남음.** 최신 소스는
   `.claude/question.md` 1번(개수 반복 안 함, 항목 추가/해소될 때마다 여기가
   stale해지는 패턴이 반복됐어서). **[2026-08-13 정정]** `State`는
   2026-08-12 스무 번째 세션에 현재 이름 그대로 유지로 이미 확정됐음(이
   목록이 "위험도 높음, 1순위 open"으로 stale하게 남아있던 걸 발견해 수정)
   — **[2026-08-21] 여기 있던 이름 나열은 지웠다.** 바로 위 문장이 이미
   "`question.md` 1번이 최신 소스"라고 선언해놓고 다음 줄에서 목록을 다시
   나열하고 있었고, 예고대로 실제로 갈라졌다(2026-08-21에 추가된 `Owned`와
   그 전부터 있던 `hintValue`가 둘 다 빠져 있었음 — 감사가 발견).
   **열린 항목이 뭔지는 `question.md` 1번을 열어볼 것.**
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
   `.claude/base/README.md` 표(`fallback-plan.md`/
   `lifecycle-hooks-plan.md`)와 `.claude/research/README.md` 표
   (`debug-tooling-plan.md`/`documentation-plan.md`/
   `documentation-content-map.md`/`framework-comparison-findings.md`/
   `operator-sugar-plan.md`).
   **[2026-08-14 추가, 2026-08-19 설계 전부 해소 후 `base/`로 승격]** 시간
   기반 전파 게이트 `Debounce`/`Throttle`(`base/debounce-throttle-plan.md`)도
   백로그이지만 위 항목들과는 발단이 다름 — **사용자가 직접 요청한 실제
   기능 갭**에서 시작됨(그 문서 13절). 다만 제어 핸들 설계까지 닫히고 나니
   실제로 quad-base에 새 코어 메커니즘을 추가하지 않는 **순수 슈가**로
   확인돼(같은 절), 위 항목들과 우선순위는 다시 같아짐 — M0/M2를 막지
   않고, **그 게이티드 노드는 [2026-08-21] `state:Gate`로 확정돼 M2에서
   만들어졌다**(`base/gate-plan.md`, **[2026-08-29]** 단위 4로 완료) — `Debounce`/`Throttle`은 그 위의
   정책으로 얹으면 되고, 같은 설계를 두 번 할 일은 없어졌다.
   주입 op 2개(`setTimeout`/`clearTimeout`)가 백엔드 팩토리 표면에
   추가될 예정이라는 것도 M1 설계 시 인지. 남은 열린 질문 없음(구
   `question.md` 낮은 우선순위 절, 전량 해소로 항목 자체가 빠짐).
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
