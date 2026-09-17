# post-implementation review round11 — 결함 탐사 3차(브리프 + 원장)

> **입력**: 2026-09-17 체크포인트 HEAD(round10 배치 회신 `Q48`~`Q58` 열하나 반영 + code-review 12건 + 감사 4라운드 뒤). 사용자 지시(2026-09-17): *"다음 지시는 여전히 감사야. 이전 감사에서 결론이 '결론: 소진되지 않았습니다' 였으니까, 또 이 감사에서 나온 것으로 breaking changes 가 나왔어. 11 round 를 준비하는 편이 가장 필요한 부분으로 보여 … 수렴 확인이 된다면 범프를 하고, 다음 갈래를 보고싶어."* round10의 라운드별 새 발견은 14 → 7 → 4(→ 리뷰 10, 절반이 수정분의 산물)로 줄었지만 0이 아니었고, 회신 반영 자체가 큰 diff(커밋 18개, BREAKING 넷)를 만들었다 — **round11의 1차 목적은 그 새 코드의 결함**, 2차는 아직 안 본 각도. 3.3.0 bump는 이 라운드가 수렴한 뒤(사용자 합의 — BREAKING 허용 주간 안에 한 번에).

## §0 규약(round10 그대로)

- 갈래는 **근거가 코드 실행인 조각**만 팬아웃(conventions 2026-09-01) — 각 탐사자 `model: opus`(문서 대조·타입 프로브는 sonnet), 지시문에 "마지막 메시지 하나에 최종 목록 전부, 미완은 '미완' 표시, 후속 송신 약속 금지"(conventions 2026-09-06). 스크래치는 세션 scratchpad `hunt-{갈래}/`, 레포 안에 임시 파일을 만들면 이름에 `-ignoreme` 접미 + 끝나면 삭제(round10 체크포인트 사고: 검증자 임시 파일이 메인의 `git add -A`에 딸려 커밋됨 → **메인은 파일 지정 커밋**).
- 발견은 전부 **메인이 재실행·판정**하고 세 갈래로 — 문서가 이미 답을 가진 것은 `H-538`부터 번호를 받아 자율 반영(같은 커밋에 base+코드+스펙+CHANGELOG), 새 필드·인자·이름·메커니즘·확정 역전은 §4 사용자 문항 `Q59`부터(평문 한 문단: 상황 → 무엇이 막히나 → 갈래 → 권고), 짠 코드 상당 부분을 무효화할 규모면 즉시 중단·보고.
- 라운드 끝: 감사 루프(한 턴 하나, 각도 교대, 0까지) → `/code-review high`(인자에 opus 서브에이전트·검증자 ≤4·평문·단일 최종 메시지·pcall 처방 금지·새 메커니즘 처방 금지) → 반영분 감사 1라운드 → 체크포인트 커밋 → 사용자에게 "§4를 보라" 한 줄. 판정은 `./scripts/test.sh; echo $?`의 0.
- **소진 판정**: 갈래마다 새 발견 수를 §1에 적고, 두 라운드 연속 0이거나 남은 발견이 전부 "실기기 전용"이면 수렴 — 그때 사용자에게 bump 제안.

## §1 결론 한 줄

(탐사 뒤 채운다 — 갈래별 새 발견 수, HIGH 유무, 소진 여부.)

## §2 갈래(제안 — 메인이 조정 가능)

- **A′ 소유권 자리 퍼즈(opus)** — round10 Q48로 생긴 새 코드: `elementOwner`를 Slot 원소·top-level Slot·정적 자식(`InstanceChild`)·숏핸드 관리 자식 넷이 공유한다. 랜덤 연산(정적 자식 State 스왑·`{c, c}`·Slot↔정적 교차·`Claim` props 재사용·`q.dispose`·관리 자식 파괴·재구동·`H-154` dedup 재발행)을 섞어 부기(`elementOwner`·Length/Offset·물리 트리)가 항상 일치하는지, 에러 뒤 남는 상태가 문서 UB 범주 안인지. quad-roblox 스펙 환경(실 핸들러 + mock 인스턴스, `spec.handlers` 12 참고).
- **B′ 반응형 코어 차등 퍼즈 재실행(opus)** — Q50 세대 스탬프·Q51 `_pending` 순서·Q57 `dying`·Q52 `_materializing`이 들어간 뒤의 랜덤 DAG(round10 B의 시드 1,100 재사용 + 재진입·throw·cleanup 안 Set·Gate 노드·`Refresh` 드리프트 조합). 특히 세대 스탬프와 `_invalidate`의 bnot 순환, Gate 노드의 `_recompute` 경로, 던진 fn 뒤 새 세대 회복.
- **C′ Debounce/Throttle 가상 시계 퍼즈(opus)** — Q55 Time 캐시·MaxTime 진입 읽기·`Flush`의 `_time` nil 가드: 랜덤 신호/Set(Time·MaxTime 잘못된 값 포함)/Flush/Cancel/타이머 발화 순열로 "Blocker On인데 타이머 없음"·배치 유실·이중 통과가 없는지(mock 가상 시계, `spec.debounce` 9 참고).
- **D′ GC·weak 테이블 모양 전수(opus, 정적 + 실행)** — round10 리뷰가 잡은 `H-71` 모양(weak 키 버킷의 값이 키를 되참조)을 코퍼스 전체에서 찾는다: `Relate:SetStrong` 값이 클로저/엔진 객체로 키를 잡는 자리, `setmetatable({}, {__mode="k"})`의 값이 키를 잡는 자리. 실행: mock에서 N개 인스턴스 Destroy 뒤 `collectgarbage()` 2회로 잔존 수 측정(round10 리뷰 파인더의 50/50 기법). ROADMAP 백로그의 `tweenSlots` `{ Tween }` 항목은 mock 심이 inst를 안 잡아 CLI로 못 재고 — 심에 `Instance` 필드를 넣어 모양만이라도 재는 것을 시도.
- **E′ 프로바이더 계약 음성 프로브(sonnet)** — `isClaimed`·`nativeFindChild(…, className?)`·`Bookkeeping.claimOwnerAt/releaseOwner`·cleanup `dying`·우선순위 오프셋을 **문서(extend/01·02)대로만** 구현한 가짜 프로바이더를 짜서 quad-base 위에 얹어 돌린다 — 문서에 없는 암묵 계약(호출 순서·nil 처리·반환값)이 있으면 그게 발견.
- **F′ 앱 시나리오 재실행 + 회귀(opus)** — round10 H의 앱 시나리오(폼·목록·테마·Claim 이관)를 새 코드 위에서 다시 돌리고, 시작하기 20편·how-to 스니펫을 mock으로 전수 실행(`gs.*` 스펙 관례) — 오늘 바뀐 동작(정적 자식 이중 배치, `OnDestroyed` State 자리, Compute 던짐, `dispose` 자리 거부)을 문서 예제가 밟는지.
- **(보류) Studio 전용** — Q53의 "파괴된 인스턴스의 Tween"은 사용자가 실기기 사실을 줬고(삭제됨, 코너가 사라짐), 남은 실기기 항목은 HUMAN_TODO C. 이 라운드에서는 안 띄운다.

## §3 참고 — 오늘 반영으로 새로 생긴 표면(탐사자에게 줄 목록)

`q.Bookkeeping.claimOwnerAt/releaseOwner`, `Backend.nativeFindChild(inst, key, className?)`, Effect cleanup `dying: boolean`, `State._computing`(세대 스탬프), `Slot._materializing`(walk + raw* attach 창), `Debounce h._time`(+ MaxTime 로컬), `Property tweenRetractors`(SetWeak, Tween을 거친 체인은 유지), `Event`/`OnChange` NORMAL − 1, `InstanceChild`/`SlotHandler` isHandlable 양의 정수 키. 결정 원문: `base/claim-plan.md` 16~18번, `state-epoch-plan.md`·`effect-plan.md`·`slot-plan.md`·`debounce-throttle-plan.md`·`lifecycle-hooks-plan.md`·`tween-plan.md` 끝 절, `session/2026-09-17-01-round10-batch-reply.md`.

## §4 사용자 문항

(비어 있음 — 탐사 뒤 `Q59`부터.)
