# 2026-09-26-01 — 자율 수집 루프(2026-09-26 20:50 KST → 2026-09-28 05:00 KST)

사용자 지시(2026-09-26 저녁): *"크론잡 하나 돌려줄래? KST 기준 28일 5시 까지 일 할 수 있어. 루프나 크론잡으로 계속 수집할 수 있는 부분이 있는지 감사를 해줘. 이번 주간 예산이 남아서, 충분히 오래 돌아도 좋고 서브에이전트가 평균 4개 5개 까지는 괜찮아. opus5.5 나 sonnet 을 자유롭게 쓸 수 있는 정도야. 지금 시작해도 괜찮아. 평균적으론 3개 정도를 돌리는걸 추천해"*

## 규칙(이 구간에만)

- 동시 서브에이전트 평균 3(상한 5). 탐사(코드 실행 근거)는 opus, 문서 사실 감사·측정 스크립트는 sonnet. `quad-doc-auditor`(코퍼스 정합)는 여전히 한 턴 하나.
- 세 갈래(M2 자율 규약 그대로): **문서·코드가 이미 답을 가진 결함**은 고치고 `H-nnn`(round13 원장)으로 기록 / **새 필드·인자·이름·메커니즘·확정 역전**은 코드에 넣지 않고 원장 §4 문항으로 / **큰 규모**면 멈추고 보고. 문서 사실 오류(틀린 사실·참조·링크)는 바로 고친다.
- 커밋 게이트: doc-check ERROR 0 + test.sh exit 0. 로컬 커밋만, 푸시 없음. 사용자에게 묻지 않는다(문항은 원장에).
- 실측(Studio)은 없다 — 사용자 기기 없음. CLI mock·luau-analyze만.
- 종료: 2026-09-28 05:00 KST가 되면 도는 에이전트를 기다렸다 마감 기록을 쓰고 루프를 멈춘다(도는 에이전트를 TaskStop하지 않는다).

## 각도 목록(회차마다 하나씩 소진 — 상태는 아래 로그가 소스)

문서 사실 감사(sonnet): D1 시작하기 00~11 / D2 시작하기 12~21 / D3 how-to 01~10 / D4 레퍼런스 core / D5 레퍼런스 roblox·sugar·extend / D6 오버뷰·Quadnomicon / D7 `docs/reference/errors/` 절 ↔ 소스 메시지 전수 / D8 skills·agents 트랙 / D9 CHANGELOG `[Unreleased]` ↔ 코드.
결함 탐사(opus, mock 실행 근거): E1 Slot/List/Single/Bookkeeping / E2 Dispatch·Modifier·Property/Event/OnChange/Out / E3 State/Source/Compute/Gate/Blocker/Debounce / E4 Tween·Animate 콜백·Destroy(mock) / E5 Ref/Observer/Effect/훅/Fallback/Context / E6 Claim/Mapper/Tag/Attr / E7 타입(신 솔버 프로브) / E8 에러 코드·blame 레벨 정합.
측정(sonnet, CLI 산술): P3 Compute 전파 / P2 List 갱신 / P1-CLI 마운트 호출 수 / P6 mock GC 잔존 — `audit/perf-cli-2026-09-26/`.
수집(sonnet): V1 `/code/Projects/quad-v1/src` 공개 표면 ↔ `research/v1-compat-plan.md` §2 대조.

## 로그

- **20:56** 시작(사용자 `mise upgrade claude` 뒤 재개 — Claude Code 2.1.283, `model: "opus"` 서브에이전트 = `claude-opus-5-5` 확인). 1회차: D1(sonnet) · E1(opus) · P3+P2(sonnet). 원장 `qa-request/post-implementation-review-round13.md` 신설(H-595부터).
- **21:10** D1 완료(사실 정확도 높음; 발견 2 → `H-595` 에러 인용 ID 접두 누락(체계적) · `H-596` 09장 장 번호). H-596 즉시 고침. H-595는 sonnet 배치(문서 트랙 전체 인용에 ID 부착)로 띄움. E1·P3+P2 진행 중.
- **21:25** P3+P2 완료(`audit/perf-cli-2026-09-26/REPORT.md` — 서브에이전트는 REPORT 쓰기가 하네스에 막혀 메인이 저장). Compute 전파는 d·f·다이아몬드 전부 기대대로. **Slot:List 전체 역순·전체 교체가 N=5000에서 ~2s로 거의 이차적**(단일 삽입·삭제는 선형) — 가설 `reindexFrom` 전범위 재인덱싱. 후속 P2-trace(opus) 띄움: 실행 트레이스로 원인 확정 + 중첩 Slot 선형 증가 원인. E1·H-595 배치 진행 중.
- **21:40** E1 완료(opus, 퍼저 넷 5000시드) — 결함 셋 전부 처방이 새 메커니즘/UB 선언이라 **§4 Q73(설치 발화 창 길이 변경 유실 → 형제 Offset stale, MED)·Q74(`_materializing`이 조부모를 안 덮음 → 파괴된 서브트리 유령 마운트, MED)·Q75(배치 중 native op stale offset, LOW)**. 확인만 §2. 재현 `audit/round13-e1-probe*`. 다음: P2-trace(opus)·D2(sonnet) 띄움; H-595 배치 진행 중.
- **22:05** P2-trace 완료(opus) — O(N²) 확정, 원인 함수 표를 REPORT에 추가. full-replace는 reconcile 순서(KeyGone 뒤) 탓, full-reverse는 no-op `nativeMove`에 넘길 offset 계산이 62%. 처방은 updateFn 순서/백엔드 계약을 건드려 **§4 Q76·Q77**. 중첩 Slot 선형은 설계대로(고칠 근거 없음). E2(opus) 띄움; H-595 배치·D2 진행 중.
- **22:15** D2 완료(12~21 사실 정확도 높음; 발견 1 → `H-597` 20장 Tag 힌트 문구 — H-595 배치 종료 뒤 고침). D3(sonnet) 띄움; H-595 배치·E2 진행 중.
- **22:30** H-595 배치 완료(24파일 52곳) + 부산물 `H-598`(how-to 10 예시 ID 오기)·`H-599`(how-to 08 조용히 잘린 인용)·`H-600`(함정 3 Modifier ID 둘 중 생성자 경로) + `H-597` 반영. 게이트 뒤 커밋. 도는 중: E2·D3.
- **22:45** 1회차 커밋 `6f3da255`. E2 완료(opus, E1~E17) — `H-601`(Out+Animate 캐비엇)·`H-602`(listHandlers 문구)·`H-603`(getHandler 게이트) 반영 배치(sonnet) 띄움, **§4 Q78·Q79**. 확인만 §2에 추가. E3(opus) 띄움. 도는 중: D3·E3·fix 배치.
- **22:55** D3 완료(how-to 01~10 사실 정확도 높음 — 발견 2: `H-599` 중복, `H-604` how-to 10 frontmatter 번호). 즉시 고침. 도는 중: fix 배치(H-601~603)·E3. 다음 sonnet 슬롯은 D4(레퍼런스 core).
- **23:10** D4 완료(레퍼런스 core 전수 일치, 발견 2 → `H-605`·`H-606` 즉시 고침). 도는 중: fix 배치·E3. 다음 sonnet: D5(레퍼런스 roblox·sugar·extend — fix 배치가 extend/02·roblox/05를 만지므로 배치 종료 뒤).
- (시각은 `date` 기준으로 다시 맞춤) fix 배치 완료 — H-601 캐비엇(roblox/05·GS 06 §6·onchange-plan), H-602 문구, H-603 nil 게이트+spec 2건; 잔여 `{}` 갭은 **Q80**. 커밋. 도는 중: E3·V1. D5 띄움.
- **21:55** E3 완료(opus, P1~P21 + 퍼저 6만 시드) — 새 결함은 Q73의 일반형 하나(공개 `state:Observer` 설치 발화 창) → Q73에 보강, 코어 산술은 전 축 0. E4(opus) 띄움. 도는 중: V1·D5·E4.
- **22:05** V1 완료(sonnet) — compat §9.5 사실 다섯(CLI 로드 불가 확정·`Destroying` 미청취·체이닝 여섯·`self("이름")` 경로 죽음·Lang 스코프), 오버뷰 02 `H-607`. D6(sonnet) 띄움. 도는 중: D5·E4·D6.
- **22:15** E4 완료(opus) — **§4 Q81**(Dedup이 기록 Value를 믿음 — Reverses·외부 쓰기, MED)·**Q82**(시체 위 retractFrom 콜백, LOW), round11 `H-582` 확인 기록 정정, 확인만 §2. E5(opus) 띄움. 도는 중: D5·D6·E5.
- **22:25** D5 완료(레퍼런스 roblox·sugar·extend 전수 일치, 발견 3 + 덤 1 → `H-608`~`H-610`; 메인 grep으로 레퍼런스 접두 잔여 다섯 `H-611`). 전부 고침. D7(에러 레지스트리 ↔ 소스 전수, sonnet) 띄움. 도는 중: D6·E5·D7.
