# 2026-09-25-01 — docs-review 2-4: 떠 있는 것 열고 닫기(how-to 09 신설)

이어지는 세션(`session/2026-09-21-03-round12-gemini-judgment.md` 2026-09-22 절 뒤). 컨텍스트 압축 뒤 재개 — 사용자 *"다음 작업을 시작해, 물어봐야 할 부분이 있다면 물어봐도 좋아"*.

## 범위 결정(사용자, 2026-09-22~25 대화)

`research/docs-review-2026-09-14.md` 2-4의 원안은 "`ZIndex`·`DisplayOrder`·`ClipsDescendants` 레시피 + `Fallback` 예제". 사용자가 좁혔다:

- 엔진 지식은 뺀다 — *"zindex 나 displayOrder 같은건 quad의 기능이 특수성이 있어서 구현에 대해서 알려줘야하거나 하는건 아닌것 같다는 느낌. roblox ui 에 대한 부분은 문서로 읽고 온다고 가정 하에 문제가 안 나"*. 남기는 것은 *"'열고 닫고' 인터랙션 처리 하고, 그걸 컴포넌트화 하고 실사용을 해보도록 돕는다"*.
- `Fallback` 갭 지적은 동의하되 *"지적의 넓이를 줄여보는게 어떤지"* → 모달을 Fallback 대상으로: *"모달로써 오류가 발생했습니다를 띄우는게 어떤지? 안에 오류 내용을 보낼 수 있는 prop 에, 오류 보고하기, 확인/취소 클릭 callback 같은거 실어도 되고 모달이 내용을 던진다가 나은지, 아니면 던진 내용을 모달이 받는다가 좋은지 … 난 후자는 실제 사례 어떤 곳에서도 붙이기 좋아서 문서화에선 좋은 대상으로 보이긴 해"*. 메인도 후자 — "모달 안 내용이 던진다"는 모달에서만 나는 좁은 사례, "던진 것을 모달이 받는다"는 어디에나 붙는 모양이고 `onError`가 대체 값을 돌려줘야 하는 계약과도 갈라 보이기 좋다.
- 실측 없음 — *"roblox studio 를 켜야하는데 내가 지금 가진 기기로는 그걸 처리할 수 없어"* → mock만.

## 반영

sonnet 작성자 하나(브리프 스크래치 `howto-modal-brief.md`): 새 `docs/how-to/09-overlays-modal-toast.md`(§1 문제 셋 / §2 `open` Source — `Visible` 유지 vs 조건부 자식 `<details>`, `Modal { Open, Title, OnConfirm, OnCancel, Children }` / §3 `q.Context` 가방 `{ Open }`으로 깊은 버튼이 뿌리 모달을 연다 / §4 토스트 `Source<{Toast}>` + `Slot:List` + `task.delay` 만료, `Id` 카운터 / §5 `q.Fallback(Card, onError)` — `onError`는 `errorState:Set(err)` 뒤 빈 `D.Frame {}` 반환, `ErrorModal { Error, OnReport, OnConfirm }`이 `:Compute`로 열림·본문, `QuadNNNN`으로 에러 페이지 찾기, `Traceback` 한 줄, 레퍼런스 caution 요약 / §6 체크리스트 + 퀴즈 셋 + 관련). 옛 부록 09 → `10-debugging-and-troubleshooting.md`(제목 번호만), 링크 전수 갱신(docs 12파일 + `base/error-id-plan.md`의 "how-to 09" 다섯 → "how-to 10 부록"), `docs/README.md` 10편, how-to 01 §7 체크리스트 한 줄. 메인 검토에서 §5의 `Card`가 정의 없이 쓰여 예시 정의(빈 Text면 던짐)를 보탰다.

mock 검증 `audit/howto-overlays-mock-2026-09-25/`(REPORT + probe): (a) `open`→`Visible`, (b) 조건부 자식 nil↔인스턴스(옛 원소는 떼어질 뿐 파괴 안 됨 — 시작하기 11 §6 그대로), (c) `Slot:List` 토스트 큐 가상 시계 만료, (d) Context로 깊은 곳에서 열기, (e) `Fallback`이 던진 `Card`를 잡아 `errorState` 채움·자리표시 반환 — 다섯 PASS. 엔진 몫(겹침 순서·실제 타이머·레이아웃)은 미확인으로 명시.

부산물: 사이트 앵커(`#6-하나만-갈아-끼우기--state를-자리에-놓기` 꼴)는 github-slugger 규칙으로 손으로 만들었고 빌드로 확인하지 않았다(doc-check의 링크 검사는 fragment를 안 본다). 작성자는 sandbox가 `git mv`를 막아 `mv`로 옮겼다 — 커밋 시 rename으로 잡힌다.

게이트: sync-docs, doc-check ERROR 0, test.sh exit 0(스펙 62, error-codes 248/242/0), `09-debugging` 잔여 참조 0(생성물·archive 제외).

감사 1라운드(diff 범위, sonnet): 발견 셋 반영 — `docs/skills/quad-ui-dev/SKILL.md`의 how-to 지도(`01`…`09`, 부록 `09`)가 이번 재번호를 못 따라와 에이전트가 부록 대신 오버레이 페이지를 받을 자리였던 것, `docs/README.md` 트랙 표 요약 행에 오버레이 누락, 열린 문항 3-8의 "how-to 09 퀴즈"(옛 부록 지칭)를 "how-to 10(부록)"으로. quad 사실 정합성 각도는 발견 0(레퍼런스 원문 대조). 각도 소진으로 닫음.
