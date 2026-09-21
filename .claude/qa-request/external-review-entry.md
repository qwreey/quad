# 외부 모델 감사 진입점 — 클린 컨텍스트에서 이 파일부터 읽을 것 (2026-09-07 신설, 2026-09-21 초점 갱신)

**누가 읽나**: 이 저장소를 처음 보는 모델(Gemini 등 Claude가 아닌 모델, 또는 기억이 없는 새 Claude 세션)이
"프로젝트 전반을 감사해 달라"는 요청을 받았을 때. 사용자 판단(2026-09-07): *"gemini 는 완전 다른 시각을
가지고 있어. 그 이외 다른 모델도 그래. 그래서 틀린 결과를 낼 수도 있지만 값이 싼 편이라 돌려보기 좋아"* —
그래서 시각이 다른 것은 환영이고, 대신 **이미 알려진 것을 다시 찾는 비용**만 이 문서가 막는다.

**사용자가 붙여 넣을 요청문(그대로 써도 된다)**:

> `.claude/qa-request/external-review-entry.md`를 먼저 읽고 그 절차대로 감사해줘. 0절의 초점(찔러볼 곳)을 먼저 보고,
> 남는 시간에 자유롭게 넓혀도 좋아. 천천히 오래 걸려도 좋아. 결과 파일은 그 문서 5절 규칙대로 `.claude/qa-request/`
> 안에 만들되, **파일을 쓰기 전에 발견 목록을 먼저 나에게 보여줘.**

## 0. [2026-09-21 기준] 이번 감사의 초점 — 찔러볼 곳과 자유롭게 볼 곳

이 절만 시점에 묶여 있다(다음 갱신 때 통째로 바꾼다). 나머지 절은 절차 규칙이라 그대로 유효하다.

**지금 상태 한 줄**: 게시된 최신은 `3.2.0`(2026-09-14). 그 뒤 일주일의 변경은 전부 루트 `CHANGELOG.md` `[Unreleased]`에 있고
아직 bump하지 않았다 — BREAKING이 일곱(Slot 미claim 거부, 소유권 규칙, Compute 재진입, `Effect` 타입 이름, `q.Backend`/`q.Bookkeeping`
네임스페이스, 프로바이더 hold op, `Instance?` 타입·Deprecated 허용목록). **그 절이 곧 "무엇이 바뀌었나"의 소스**다 — 감사 대상을 고를 때
먼저 읽을 것. 최신 리뷰 원장은 `post-implementation-review-round11.md`(발견 번호 `H-588`까지, 열린 사용자 문항 `Q70`).

**A. 찔러볼 곳 — 최근 열흘에 쓰였고 외부 시선이 아직 안 닿은 코드** (각각 "정본 절 ↔ 코드 ↔ spec" 셋을 같이 읽을 것)

1. **Tween 콜백 `Started`/`Completed`/`Cancelled`(2026-09-21, 가장 신선함)** — `quad-roblox/src/Handlers/Property.luau`(머리 주석이 발화 계약의
   소스: `stopRunning`·`snap`·`zeroTime`·완료 연결), `quad-roblox/src/Animate.luau`(`CanAnimate = false` + 콜백 → `Time = 0` Tween),
   `quad-roblox/src/Tween.luau`(함수 타입 검증·`Mapped` 승계), mock `quad-base/test/mock.luau`의 가짜 트윈 `Completed` 시그널(엔진과 달리
   `Cancel`이 **동기** 발화). 정본 `base/tween-plan.md` 끝 두 절, 엔진 실측 `audit/tween-completed-2026-09-21/REPORT.md`(사실 1~8 — 여기 적힌
   엔진 동작은 실측이니 반박하려면 근거를 댈 것). 각도: 순서 불변식(이전 Cancelled → 새 Started → 새 Completed)이 깨지는 경로, 콜백 안에서
   같은 프로퍼티·다른 프로퍼티에 `:Set`하는 재진입, 던지는 콜백 뒤 레코드 상태, 연결 클로저의 GC 포획, deferred 완료 창(`H-581`)의 mock
   재현이 엔진과 같은가. **실기기 배선은 아직 미실측**(Studio에서 돌린 적 없음) — 코드 읽기로 잡을 수 있는 것이 값지다.
2. **생명주기 분할(2026-09-18, Q59)** — quad-base가 `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`를 구현하고(`quad-base/src/LifetimeHandle.luau`),
   백엔드는 hold op 넷 `holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`만 준다(`quad-roblox/src/LifetimeHandle.luau`, mock). 정본
   `base/lifecycle-pattern.md`·`docs/reference/extend/01-backend-provider-contract.md`. 각도: 게이트 순서(값 게이트가 인스턴스 게이트보다
   먼저 — `H-578`), roblox 구현과 mock 구현의 의미 차이, `isHeldBy`가 다른 인스턴스에 이미 묶인 값에 주는 답.
3. **Effect/Observer 해제 경로(2026-09-18, Q63·Q68·`H-575`)** — `quad-base/src/Effect.luau`의 `rawRerun`(루프 머리·꼬리의 실행 가능성 재검사),
   `_consumeCleanup`의 `_cleanupRunning` 저장·복원, cleanup 인자 `dying`; `quad-base/src/Observer.luau`(던진 Observer는 계속 발화, 재구독만 차단).
   정본 `base/effect-plan.md`. 각도: yield하는 fn 도중 인스턴스 파괴, cleanup 안에서 자기 해제, 던진 뒤 강한 킵 해제 순서.
4. **Claim 1패스 `isClaimed` 게이트(2026-09-18, Q64)** — `quad-base/src/Claim.luau` resolve, mock의 통일 `claimed` 플래그(`Instance.new`는
   claimed로 태어나고 `Instance.foreign`만 아님). 각도: 부분 실패 뒤 상태(루트·앞선 형제가 claim된 채 남는가 — 게이트가 그걸 막는 것이
   목적), roblox 실구현(`quad-roblox/src/LifetimeHandle.luau`의 `isClaimed`)과 mock의 차이.
5. **Slot 폐기 경로(2026-09-18, Q61)** — `quad-base/src/Slot/Tree.luau` `destroySlotTree`의 `_owned == false` 분기(release + 배열 비움 +
   슈거 래퍼 해제). 정본 `base/slot-plan.md`. 각도: `Extract`/`Remove`와 파괴 경로의 대칭, 중첩 Slot에서 순서.
6. **생성기(2026-09-21)** — `scripts/gen-d.py`의 `DEPRECATED_NAME_KEEP`(`FontSize`/`TextWrap`만)·`ENGINE_NIL_EVENT_PARAMS`·`Parent` 읽기 `Instance?`,
   생성물 `quad-roblox/src/Declaration/init.luau`. 각도: `python3 scripts/gen-d.py check`가 맞다고 하는 것과 실제 덤프의 차이, 타입에서 빠진
   프로퍼티가 런타임엔 여전히 통과하는가(의도됨 — 타입만 BREAKING).
7. **에이전트 스킬 `docs/skills/quad-ui-dev/`** — 2026-09-09 무렵 쓰인 뒤 표면이 여러 번 바뀌었다(`q.D`→`q.Declaration`, `:With`→`:Depend`,
   `Owned`→`OwnsElements`, `EffectHandle`→`Effect`, Brand `:Register`/`:Is`, 생명주기 hold op, Tween 콜백). **stale 문장이 있을 가능성이 높다** —
   `SKILL.md`와 `references/*.md`의 심볼·에러 문구를 현 코드와 대조하는 것은 값싸고 확실한 각도다.

**B. 문서 — 자유롭게, 다만 "코드가 실제로 그렇게 도는가"로** (`docs/`가 공개 문서, 사이트는 그 미러)

- 오늘 신설·재편: 시작하기 **15장 `q.Store`**(새 장 — 15~19가 16~20으로 밀렸다: 옛 번호가 남은 문장·링크가 있으면 발견), 09장 §4(테마·`mod:Apply`),
  11·13장 "지금까지의 코드" 스냅샷(그 앞 장들의 코드를 그대로 합친 것이어야 한다 — 어긋나면 발견), 16장 §1 "끝났을 때 알기", 02·07장 각주,
  용어 치환(물러나다→빠지다, 부기→장부 등 — 시작하기 안에 옛 말이 남았으면 발견), `docs/agents/` 트랙.
- 각도: 문서의 사실 문장 ↔ 코드(에러 문구는 소스 verbatim이어야 한다), 스니펫이 mock 백엔드에서 실제로 도는가(스크래치 spec을 만들어 돌려도
  된다 — 6절 규칙), 레퍼런스 페이지의 시그니처 ↔ `quad-types/src/init.luau`·`quad-roblox/src/types.luau`.

**C. 자유 탐색** — 코어 산술(Dispatch·Bookkeeping·List)은 round11 3차 탐사에서 여섯 축 모두 발견 0이었다(`round11.md` §6). 거기를 다시
파는 것보다 **경계**가 낫다: quad-base ↔ quad-roblox 사이(백엔드 op 계약 `docs/reference/extend/01`이 약속한 것과 roblox 구현), 타입 표면 ↔
런타임 값(`H-300` 관례), 생성 D ↔ 런타임 핸들러(`isHandlable`이 받는 키와 타입이 허용하는 키), 스펙이 안 짚는 계약 문장.

**D. 열려 있어 다시 올리지 말 것** — `question.md` 2절 `Q70`(`const` 규칙과 src 불일치), `research/docs-review-2026-09-14.md`의 남은 문항
(1-4·2-1·2-3·2-4·2-5·3-1~3-6·3-8 — 사용자 결정 대기), 루트 `HUMAN_TODO.md`의 실기기 항목, 3.3.0 bump 시점(사용자 지시 뒤).

## 1. 무엇을 감사하나 — 이 프로젝트가 뭔지

Roblox 엔진용 DOMless 반응형 UI 렌더러 `quad`의 v2 재작성. 루트 `CLAUDE.md`가 진입 문서이고, 코드보다 문서가
먼저인 프로젝트다 — 설계 결정은 전부 `.claude/base/`에 산문으로 확정돼 있고 코드는 그 정본을 구현한다.
워크스페이스 패키지 구성과 각 파일의 몫은 **`base/architecture.md`의 소스 트리가 유일한 소스**다(여기 다시 나열하지
않는다 — 나열은 갈라진다). 생성기는 `scripts/gen-d.py`, 테스트는 `./scripts/test.sh`.

## 2. 읽는 순서 — 지식이 어디 있나

1. `CLAUDE.md` → 그것이 `@import`하는 `.claude/conventions.md`(설계 원칙·작업 규약), `.claude/project-context.md`,
   `.claude/todos.md`(지금 상태). `.claude/README.md`가 문서 전체 색인이다.
2. `.claude/base/architecture.md`(소스 트리와 한 줄 요약) → 감사하려는 부품의 `base/<부품>-plan.md`. **정본 우선순위는
   `base/` > 나머지 전부** — `session/`·`session-summary.md`·`archive/`는 과거 시점 서술이라 최신 결정이 안 반영돼
   있을 수 있다.
3. 코드. 파일마다 머리의 `--[[ ]]` 헤더가 어느 정본 절을 구현하는지 적어 둔다 — 코드와 정본을 **같이** 읽을 것.
4. 리뷰 원장 — `.claude/qa-request/README.md`가 최신 라운드 목록의 소스다(루트 `.claude/README.md`는 폴더당 한 줄)(라운드 번호는 메인 리뷰와
   외부 리뷰가 하나의 열을 공유하며 계속 는다). 각 라운드 파일의 `§4`가 사용자에게 열린 문항, `H-nnn`이 발견
   번호(메인 판정 뒤 부여), `G-nn`/`S-nn`이 외부 리뷰의 발견/건전성 확인 번호다.

## 3. 다시 찾지 말 것 — 중복 보고 제외 규칙

다음 어딘가에 이미 적혀 있으면 새 발견이 아니다. 보고하려는 항목마다 아래를 **grep으로 확인**하고, 표로
"기보고 확인" 절에 남길 것(`post-implementation-review-round4.md` 1절이 그 형식의 본보기):

- 리뷰 원장의 `H-nnn`·`G-nn`·`S-nn` 전부, 그리고 각 라운드 `§4`의 열린 문항 `Qn`(사용자가 답할 것이라 다시
  올리지 않는다 — 논거를 보태고 싶으면 "Qn에 논거 추가"로 적는다).
- **의도된 UB**: `base/dispatch-core-plan.md`의 UB 목록, `base/slot-plan.md`의 좀비·재진입 서술, `base/
  source-state-plan.md`의 Compute 순수성 원칙(Compute 안 `:Set`은 UB, 재진입 게이트 없음) 등 — 정본이 "정의되지
  않은 동작"이라 선언한 곳에 가드를 제안하는 것은 발견이 아니다.
- **일부러 미룬 것**: 루트 `ROADMAP.md` 백로그, `research/deferred-hardening-plan.md`(급하지 않은 하드닝을
  쌓아 두는 곳), `research/` 전반, `.claude/question.md`.
- **뒤집힌 설계**: `.claude/archive/`의 `*-reversed.md`/`*-rejected.md` — 거기 있는 모양을 다시 제안하지 말 것.
- 설계 원칙 둘(`conventions.md` "설계 원칙" 절): *드문 오용이나 가상의 미래 요구까지 방어하려고 구조를 늘리지
  않는다*, *하나가 두 일을 하지 않는다*. "가드를 더 넣자"류 제안은 그 오용이 실제로 무엇을 조용히 깨뜨리는지
  (재현 경로)를 못 대면 보고하지 않는다.

## 4. 어떤 각도로 보나

- **코드 ↔ 정본 불일치**: 헤더가 가리키는 절과 실제 동작이 다른가(메시지·순서·에러 깊이 포함).
- **런타임 결함**: 구체 입력 → 잘못된 출력/크래시/조용한 무시. 재현 경로(어느 공개 API를 어떤 인자로)를 반드시.
- **타입 표면**: `quad-types/src/init.luau`, `quad-roblox/src/types.luau`, 생성물 `quad-roblox/src/Declaration/init.luau`와
  생성기 `scripts/gen-d.py` — 약속한 타입이 값에 없거나(`H-300` 관례: 마커 필드는 런타임에도 있다), 유니언 팔이
  실제 값을 거부하는가. 알려진 한계는 `base/typing-limits.md`가 소스라 거기 있는 건 제외.
- **테스트 갭**: 정본의 계약 문장 중 `quad-*/test/spec.*.luau`가 안 짚는 것.
- **문서 내부 모순**: 같은 사실을 두 곳이 다르게 적은 것(정본끼리, 정본과 헤더).

## 5. 결과 파일 — 형식과 규칙

- **파일명**: `.claude/qa-request/post-implementation-review-round<N>.md`, N은 `.claude/qa-request/README.md`에 있는
  최신 라운드 + 1(사용자가 다른 이름을 주면 그 이름). 첫 줄에 검토 시점(날짜·HEAD 커밋 해시)과 검토 범위를 적는다.
- **번호**: 발견은 `G-nn`, 건전성 확인은 `S-nn` — 직전 외부 리뷰 라운드의 마지막 번호 다음부터 이어 센다(마지막 외부
  라운드 파일은 `qa-request/README.md`에서 찾고, 그 파일 끝에서 마지막 번호를 확인 — 여기 숫자를 적어 두지 않는다;
  round6·7은 Gemini 자문·RFC 판정이라 `G`/`S` 번호를 쓰지 않았다). `H-nnn`은 메인 세션이 판정 뒤 붙이므로 **쓰지 말 것**.
- **항목마다 평문 한 문단**(사용자 규약, `conventions.md` 2026-09-07 항목): 상황 → 무엇이 막히나(재현 경로) →
  제안 갈래의 뜻. 기호·약호·번호 나열로 압축하지 말 것. 위치는 `파일:줄`, 심각도는 High/Medium/Low 하나, 근거는
  코드 인용 몇 줄.
- **제안은 발견이지 결정이 아니다**: 새 필드·인자·이름·메커니즘을 제안할 땐 "제안"이라고 갈라 적고, 증상만
  확실하고 처방이 새 개념이면 "증상 확정, 처방 미정"으로 남긴다.
- 절 구성: (1) 기보고 확인 표(3절) → (2) 신규 발견 `G-nn` → (3) 건전성 확인 `S-nn`(의심했으나 정본·코드 대조로
  건전하다고 판단한 것 — 다음 감사가 재의심하지 않게) → (4) 열린 질문(정본이 답을 안 가진 것).
- **파일을 쓰기 전에 발견 목록을 사용자에게 먼저 보여준다**(사용자 요청 원문: *"먼저 파일 쓰기 전에 각 문제를
  나에게 보여줘"*). 언어는 한국어.

## 6. 하지 말 것

- 소스·문서·테스트 파일 수정, git 명령(읽기 전용 `git log`/`git show` 제외), `git stash`.
- Roblox Studio/MCP 실행. 실행 환경이 있으면 `./scripts/test.sh; echo $?`의 **exit code**로 현 상태를 확인해도
  된다("ALL PASS" 줄 수를 세지 말 것 — 진단이 있어도 스펙은 끝까지 돈다). 스크래치 실험은 `quad-*/test/
  tmp.*.luau`에만 만들고 끝나면 지운다(`spec.*.luau` 이름을 쓰면 test.sh가 정식 스펙으로 집어 간다). `luau` CLI는
  심볼릭 링크를 못 타므로 스크래치를 직접 돌리려면 `./scripts/relink.sh`를 먼저 한 번 돌릴 것.
- 문서 안의 날짜 태그·`H-nnn`·`Q-nn`은 결정 이력의 표식이지 감사 대상이 아니다 — "이 날짜가 왜 여기 있나"류는 보고하지 않는다.
- 정본 밖의 설계를 발명해 "이렇게 바꿔라"로 쓰는 것 — 발견은 증상과 정본 인용으로 세운다.

- **Luau 언어 사실은 실측 뒤에 주장할 것.** 5차가 테이블의 nil 키 *읽기*를 VM 에러로 전제해 다섯 건을 냈는데, Luau는 읽기(`t[nil]`)는 nil을 돌려주고 *쓰기*(`t[nil] = v`)만 에러다. 크래시 주장에는 실제로 돌린 재현 스니펫을 붙일 것 — 못 돌리면 "미실측"이라고 적는다.

## 7. 이 결과가 어떻게 처리되나

메인 세션(Claude)이 항목마다 세 갈래로 판정한다 — ① 정본이 이미 답을 가진 결함이면 `H-nnn`을 붙여 코드·정본·
spec을 같은 커밋에서 고치고, ② 새 표면이나 정본과 충돌하면 그 라운드 `§4` 사용자 문항으로 올리며, ③ 정본과
대조해 건전하면 "확인 기록"으로 남긴다. 외부 리뷰 원문 파일은 판정 배너만 머리에 얹고 그대로 보존된다
(`post-implementation-review-round2.md`·`post-implementation-review-round4.md`가 선례).
