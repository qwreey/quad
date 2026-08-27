# 구현 전 손 트레이싱 **10라운드** 감사 지시서

> **이 파일이 무엇인가**: 10라운드 탐사자에게 그대로 주는 지시서다. 산출물은
> `pre-implementation-handtrace-round10.md`(§6). **[2026-08-28 신설]** 9라운드
> 지시서(`-round9-brief.md`)와 같은 관례.
>
> **왜 10라운드인가**: 9라운드 후속(`H-143`~`H-146`, 2026-08-27)을 반영하고
> 감사 8라운드 + `/code-review high`를 돌렸더니 **판단이 필요한 것 셋**이 또
> 나왔다(`-round10.md` §4의 `H-147`~`H-149`). 사용자 판단(2026-08-28): *"인간을
> 기다리는거 엄청 비효율이라서 … 늘 해오던것 처럼 batch 로 처리될 필요가 있는듯.
> 지금 결정해야할 분 10 으로 올리자. 커밋하고 정리한 다음 깔끔한 컨텍스트의
> fable 탐사자 하나 띄워서 광범위한 핸드트레이싱, 테스팅, 문제 검사를
> 하도록 해줘."* — 즉 이 라운드는 **한 번에 넓게 훑어 사용자가 한 자리에서
> 전부 결정할 문항지**를 만드는 것이 목적이다. 발견을 하나씩 물으러 오지
> 말 것.

당신은 Roblox 엔진용 DOMless UI 렌더러 **quad**의 설계 코퍼스를 감사한다.
저장소 루트가 작업 디렉토리다. **구현(M2 = 반응형 코어) 착수 직전**이고,
여기서 놓친 설계 결함은 구현 한참 뒤에 터져 M2/M3를 다시 짜는 비용이 된다.
당신은 신선한 컨텍스트에서 시작한다 — 앞선 세션의 가정을 물려받지 않는 것이
당신의 가치다.

---

## §0 먼저 읽을 것 (이 순서로)

1. `CLAUDE.md` → `.claude/conventions.md` / `.claude/project-context.md` /
   `.claude/todos.md`. **특히 `conventions.md`의 두 규칙**: (1) "리뷰·감사가
   내놓는 새 필드·인자·이름·메커니즘은 발견이지 결정이 아니다"(2026-08-27),
   (2) "하나의 무언가가 두 일을 하고 있지 않은지 유의한다"(2026-08-27).
2. `.claude/qa-request/pre-implementation-handtrace-round9.md` — 9라운드 발견
   원문(`H-124`~`H-146`). §5(이상 없음)·§6(남은 의심)은 다시 파지 않아도 되는
   자리와 파야 할 자리다.
3. `.claude/qa-request/pre-implementation-handtrace-round9-followup.md` —
   **이 라운드의 출발점.** 9라운드 결정 전량과, `H-143`~`H-146` 반영 뒤의 감사
   8라운드 표·`/code-review high` 기록. 거기 적힌 **실패 모드**(반영분 자체가
   결함을 만든다 / 판정식을 단순화하다 생성자 케이스를 죽인다 / 함수 본문
   공유 + 콜론 위임)가 당신의 사냥 목록이다(§3).
4. `.claude/qa-request/pre-implementation-handtrace-round10.md` — **이미 `H-147`
   ~`H-149`가 들어 있다.** 당신의 발견은 `H-150`부터 이어 매긴다. 그 셋을
   재검토해도 좋다(전제가 틀렸으면 그렇게 적을 것).
5. `ROADMAP.md`(M2/M3 체크리스트), `.claude/question.md`,
   `.claude/luau-test/STATUS.md`, `.claude/audit/handtrace-round7-reference-impl/README.md`.
6. `base/`는 **전량 완독**을 요구한다 — 이 라운드는 "델타"가 아니라 "광범위"가
   전제다(사용자 요청). 먼저 `base/architecture.md`.

---

## §1 이 라운드의 전제

- **스코프는 광범위다.** 9라운드까지의 델타 스코프와 달리 M2~M8 전 표면을 본다.
  다만 우선순위는 §2대로 — M2/M3가 먼저다.
- **한 번에 문항지를 만든다.** 사용자는 다음 세션에 이 파일 하나를 열어 §4의
  표를 위에서 아래로 읽고 갈래만 골라 회신한다. 그러므로 모든 발견은
  **갈래 + 권고 + 권고 근거**를 갖춰야 하고, 판단이 필요 없는 것(오타·stale·
  개수)은 🟢로 분리해 §4에 넣지 않는다.
- **새 메커니즘은 승인이 아니다.** 당신이 처방으로 제안하는 필드·인자·이름·
  표면은 전부 "권고"다. `base/`에 이미 기각된 모양인지(`archive/`, 각 문서의
  "검토 후 안 만들기로 한 것"류 목록) 먼저 grep하고, 기각된 것을 다시 제안할
  땐 그 사실을 적을 것.
- **실측이 가능한 주장은 실측한다.** 로컬에 `luau`/`luau-analyze`가 있다.
  테스트는 반드시 `./scripts/test.sh`로(`luau` CLI가 심볼릭 링크를 못 타서
  그냥 돌리면 거짓 클린이 난다 — `project-context.md`). 참조 구현
  `audit/handtrace-round7-reference-impl/spikes/`는 **7라운드 시점 계약**이라
  지금 계약(`H-107`~`H-149`)과 다르다 — 갱신해 돌리는 것이 레인 C다.

---

## §2 레인 — 우선순위 A > C > B > D

### 레인 A (최우선) — M2 반응형 코어 전체를 지금 계약으로 손 트레이싱

`base/source-state-plan.md` / `store-plan.md` / `state-epoch-plan.md` /
`effect-plan.md` / `gate-plan.md` / `blocker-plan.md` / `lifecycle-pattern.md` /
`ref-plan.md`(최소형) / `relate-plan.md` / `epoch-brand` 관련. 특히 **2026-08-27에
바뀐 것끼리 겹쳐서**:
- `EffectHandle` 네 진입점 자기 것(`H-144` (b)) × `Rerun` 꼬리 `wasAlive and
  not canExecute`(`H-143`) × `_bindDestroying` 캐치업 × 생성자 `_blocker` ×
  `fire` 가드 순서. 상태 기계 전체를 표로 그려 **모든 진입점 × 모든 상태**에서
  `_installed`/`_cleanup`/`.Subscribed`/레지스트리 전이를 확인. `H-147`의
  "이미 죽은 핸들에서 `Rerun`"도 그 표 안에서 다시 보라.
- `state:Gate` 유보 × Effect 재구독 × `EpochMap:Refresh` — `H-144` 재트레이싱이
  한 케이스만 봤다. 다이아몬드·게이트 배치·`Peek`/`Update` 조합을 넓혀라.
- Store 명시적 초기화 × `Of<<T>>` × `CheckReservedKeys<keyof<T>>` — 타입을
  `luau-analyze`에 실제로 걸어라(레인 D와 겹침).
- `Source:Set` 동일값 emit(`H-68`) × `Blocker` × `_hold` 불변식 × 중간 State GC.

### 레인 C — 참조 구현을 지금 계약으로 갱신해 실제로 돌리기

`audit/handtrace-round7-reference-impl/spikes/`를 복사해
`audit/handtrace-round10-reference-impl/`를 만들고(원본은 건드리지 말 것 —
실측 시점 기록), `H-107`~`H-149`의 계약으로 갱신한 뒤 `luau`로 돌린다.
최소 목표: Effect 네 진입점 + `Rerun` 꼬리 + 재구독 + 게이트 유보 케이스,
`bk.indexOfElement` weak-key(Instance 키를 흉내낼 수 없으면 테이블 키로 —
그 한계를 적을 것), `reconcile` 배치 Blocker, `recompute` 되감기(`H-124`).
문서와 다르게 도는 자리가 발견이다. `README.md`에 무엇을 어떻게 갱신했는지
남길 것.

### 레인 B — M3 디스패치 / Slot 값 단위 트레이싱

`base/dispatch-core-plan.md` / `slot-plan.md` / `bind-system-plan.md`(`New`·
`drive` 파이프라인) / `handler-*`. 9라운드 레인 B의 연장 — `InstanceChildHandler`
부기, 숏핸드 우선순위, `H-142` `Parent` 금지와 `H-146` 루트 예외, `H-148`의
에러 문구 자리, 최상위 Slot 교체 × weak-key, 포탈/`Detach`/`KeyGone` 조합.

### 레인 D — 타입 계약과 실제 커밋된 M1 코드

`quad-base/src/`·`quad-types/src/`·`type-version-check/src/`를 `./scripts/test.sh`로
돌리고, `base/typing-limits.md`·`quad-types-plan.md`·`project-setup-plan.md`가
주장하는 것 중 실측 가능한 것을 `luau-analyze`로 확인. 확정 시그니처가 확정
관용구를 통과시키는가(7라운드 5차 패스의 재현, 지금 계약으로).

---

## §3 사냥 목록 — 이 코퍼스에서 **반복 관측된** 실패 모드

1. **반영분이 새 결함을 만든다** — 어제 하루에만 둘(`not canExecute` 판정식이
   생성자 케이스를 죽임 / 함수 본문 공유 + 콜론 위임). 2026-08-27 diff
   (`git log -p 7f58683..HEAD`)를 특히 의심하라.
2. **"두 뜻이 같다"는 확정** — `invalidAfter` 두 필드 분리의 교훈. 한 필드·한
   함수·한 플래그가 두 목적을 쥐고 있는 자리.
3. **판정식 단순화가 경계 케이스(생성자·최초 설치·빈 배열·0번째 자리)를
   죽인다.**
4. **의사코드 산문의 순서가 코드 순서와 다르다**(`H-127`형).
5. **인용문 옆에 인용이 승인하지 않은 메커니즘**(`H-141` `token`형).
6. **정정 배너는 달렸는데 본문 bullet·제목·색인이 옛 서술**(`H-130`형).
7. **개수·목록·상태를 두 곳에 값으로 적어 갈라진 것.**
8. **실측했다고 적혔는데 재작성 뒤 재실행 안 한 것.**

---

## §4 각도 (이전 라운드와 같은 문자 — 상호참조용)

A 겹침(결정 둘 이상이 만나는 자리) · B M5+ 값 단위 · C 참조 구현 실행 ·
D ROADMAP 시뮬레이션(체크박스 순서대로 짜면 막히는 자리) · E fail-fast 3종 ·
F 개수/목록 · G Luau 언어 사실 재확인 · H 타입.

---

## §5 규칙 (엄수)

- **`base/`·`research/`·`reference/`·`archive/`·인덱스 레이어를 고치지 말 것.**
  당신의 출력은 `-round10.md`와 `audit/handtrace-round10-reference-impl/`뿐이다.
  (오타·stale은 발견으로 적되 고치지 않는다.)
- **`git stash`·`git commit`·`git checkout` 금지.** HEAD 대조는 `git show
  HEAD:<경로>`/`git diff HEAD -- <경로>`.
- 발견 번호는 `H-150`부터 연속. 심각도 🔴(그대로 구현하면 크래시/누수/침묵)
  🟡(계약 위반·불일치, 판단 필요) 🟢(정정만).
- 절 인용은 `conventions.md`의 "절 인용 규약"대로 원문에서 잘라 쓸 것 —
  `python3 .claude/tools/doc-check.py`를 마지막에 돌려 **당신 파일이 ERROR를
  만들지 않는지** 확인(기존 WARN 59건은 무시).
- 사용자 원문을 인용할 땐 `followup`/`session/`에 있는 것만, 자르지 말 것.
- 사용자에게 질문하지 말 것 — 당신은 답을 받을 수 없다. 갈래를 적고 넘어간다.
- 토큰·시간 제한은 없다고 생각하되, **레인 A와 C는 반드시 끝내고** B·D는 남은
  만큼. 못 본 것은 §6에 정직하게.

---

## §6 산출물

`pre-implementation-handtrace-round10.md`에 이어 쓴다(이미 §0~§4 골격과
`H-147`~`H-149`가 있다):
- **요약 표**(번호·심각도·한 줄·주 대상·성격·실측) — 기존 표에 행 추가.
- **상세** — 발견마다 트레이스(실제 값으로), 왜 새 메커니즘인지 여부, 갈래,
  권고, 권고 근거, 채택 시 고칠 자리.
- **§4 사용자 결정 표** — 판단 필요 항목만, 갈래를 한 셀에. 기존 `H-147`~`H-149`
  행 아래에 이어서.
- **§5 이상 없다고 확인한 것** / **§6 남은 의심·못 본 것** / **§7 레인 C 실행
  기록**(어떤 스파이크를 어떻게 갱신했고 결과가 뭔지, 파일 경로).
