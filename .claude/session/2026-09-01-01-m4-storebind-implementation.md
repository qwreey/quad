# 2026-09-01-01 — M4 착수·완료: StoreBind 구현 + end-to-end spec (round13)

## 세션이 받은 지시

사용자 원문: *"M4 진행 가능해보여? m4-implementation-round13-brief.md 가
.claude/qa-request 안에 있어. 수행 계획인데, 수행 가능하다면, 막는게 없다면
M4 구현 시작해보자. 혹은 구현 전에 먼저 감사를 도는게 더 나아보이면, 구현을
멈추고 이 지점에서 다시 페이서 논의를 시작해도 좋고(의사코드 부족 등, 실
구현에 있어 부딛힐 부분이 많다면)"*

**조건부 승인으로 읽었다** — 개별 문항 반대 없이 "막는 게 없으면 착수"이므로
brief §0의 권고 (a) 넷(Q1 규약 재사용+운용 규약 통합 / Q2 단위 하나 /
Q3 `Dispatch/StoreBind.luau` 유지·`InitDispatch` 꼬리 등록 / Q4 스파이크
`03` 폐기)을 채택하되, 조건(실 구현 가능성)을 착수 전에 검증했다. 회신
기록은 brief §0 아래 블록이 소스.

## 착수 전 검증 — 막는 것이 없음을 확인한 근거

정본 절(`dispatch-core-plan.md`의 "Store 바인드는 특수 경우인가" 절)의
의사코드를 실코드 부품과 하나씩 맞춰봤고 전부 맞물렸다:

- `Dispatch/init.luau`의 (B) 분기가 **점유 마커를 `h.process` 앞에** 세우는
  주석이 StoreBind 재귀를 정상 경로로 명시 — 마운트 재귀(등록 즉시 1회
  발화가 `index+1`로 내려가는 것)가 이미 코어 설계에 접혀 있었다.
- `State:Observer(fn)` 생성자가 등록 즉시 1회 발화(`Observer.luau` — 순서가
  계약: fn once → 플래그 다운 → `_subs` 합류) — "최초 적용과 재실행이 같은
  코드 경로" 서술 그대로.
- mock `installLifetime`의 `bindLifetime`/`canExecute`가 gcconn `.Connected`
  판정을 재현 — 핸들러가 liveness를 재구현할 필요 없음(정본 절 서술)이
  실제로 성립.
- `Brand.isState`가 `isSource`를 합성(Source가 State를 구조적으로 만족) —
  "v가 State/Source인 경우"의 `isHandlable`이 술어 하나로 끝남.
- `_subs`가 weak-key라 "재발행 후 옛 store 구독 0"을 GC 후 계수로 실측 가능.

## 구현 — 커밋 하나 (brief §6 그대로)

- **`quad-base/src/Dispatch/StoreBind.luau`** — 정본 절 의사코드 1:1:
  `state:Observer(fn)` 재사용, fn은 `state:Get()` → 선행 철거 없이
  `dispatch.process(inst, k, realv, index + 1)`, `bindLifetime(inst,
  observer)`, 반환 클로저는 `unbindLifetime(observer)`뿐(`retracting` 무시 —
  brief §1 주의 ②). 우선순위 HIGH 밴드. `register(dispatch, module)` —
  생명주기 넷은 발화 시점 늦은 읽기(`H-174`).
- **`Dispatch/init.luau`** — 꼬리에 `StoreBindModule.register(Dispatch,
  module)`(Q3 (a), `None.luau` 선례).
- **`quad-base/test/spec.storebind.luau`** — 6절: ① 첫 end-to-end(마운트 +
  첫 재발행에서 인덱스 2 retractor 실호출 — `SetStrong` 순서 버그의 증상
  자리) ② 타입 교대의 (nil, true) retract ③ `State<State<T>>` N/N+1
  비충돌(안쪽 재발행은 슬롯 3만, 바깥 재발행은 재구독 갈아타기 — GC 후
  `_subs` 1) ④ 실제 StoreBind 경유 (B)의 깊은 인덱스 우선(스펙이
  `q.unbindLifetime`을 래핑해 unbind 시점을 로그 — 늦은 읽기 계약 덕에
  잡힌다) + 효과 수준(`H-224`: 옛 구독 0, 죽은 store `Set` 불덮임) ⑤
  스파이크 `03` 몫(배열 자리 `None`→`nil` 핸드오프·재귀 종료·
  `getOffsetAt`이 반응형으로 1→0→1 이동) ⑥ 단순 철거 + Destroy 후 발화
  무시(`canExecute` 게이팅).
- ~~전 스위트(24파일) ALL PASS~~ **[같은 날 정정 — `H-287`]** 구현 세션은
  "ALL PASS"로 기록했으나 **틀렸다**: 테스트 파일은 25개고 `spec.dispatch`
  하나가 깨진 채였다(`grep -c "ALL PASS"` = 24를 기대 총수와 대조하지 않았고
  exit code도 안 봤다). 감사 1라운드가 잡았다 — 아래 "단위 끝 절차" 절.

## 발견

**문서-코드 어긋남 0건, 감사 1라운드 발견 둘**(`H-287` 회귀 + `H-288` 린트 —
소스는 `m4-implementation-round13.md` 요약 표). 확인만 하고 문제 없던 것
넷(quad-types 갱신 없음 / 팩토리형은 `H-253` 관례 / `retracting` 무시 /
`H-275` 재발행 경로)도 같은 파일이 소스.

## 부수 문서 갱신

ROADMAP M4 체크박스 둘 `[x]`, `luau-test/STATUS.md`·`luau-test/README.md`의
`03` 행 폐기 확정(Q4 (a)), `.claude/README.md` `qa-request/` 행에 round13
두 파일 추가, brief 머리말 "회신 대기" → "확정".

## 단위 끝 절차 (M3 §4 준용 + 2026-09-01 운용 규약)

감사 루프(각도 교대, 유한) → `/code-review`(diff 규모 보고 판단 — 파일
하나+spec이라 낮은 강도 후보) → 커밋 → 탐사자 → 보고. 진행 결과는 이 절에
이어서 기록한다.

- **감사 1라운드(diff 정합성 각도) — 발견 둘, 그중 하나가 실제 회귀.**
  `H-287`: StoreBind 등록이 `spec.dispatch` 2번("핸들러 없는 브랜드 값"
  예시가 `q.Source(1)`)을 깨뜨렸는데 구현 세션이 스위트 실패를 놓치고
  "ALL PASS"로 기록했다 — 검증 실수의 모양은 `grep -c` 결과(24)를 기대
  총수(25)와 대조하지 않고 exit code도 안 본 것. 교정: 예시 값을
  `q.Blocker()`로(가로채기 자체는 정본 확정 설계라 재검토 안 엶 — 근거는
  round13 `H-287` 행), 이후 스위트는 **exit code로** 재검증(25/25, exit 0).
  `H-288`: `ImportUnused` 둘(spec.storebind 자신 + spec.lengthoffset 기존
  부채) 제거. 교훈은 `H-247`과 같은 부류 — **스위트 판정은 출력 grep이
  아니라 exit code로.**
- **감사 2라운드(교정분+인덱스 각도) — 발견 하나(경미).** 1라운드 교정
  넷·인덱스 레이어 전부 정합 확인(`H-287` 교정의 기능적 올바름 — Blocker가
  `isState` 불만족·`BRAND_PROBES` 도달 — 을 감사자가 코드로 재검증), 유일
  발견은 `luau-test/STATUS.md` 상단 롤링 배너가 `03` 폐기를 미반영 —
  2026-09-01 절을 배너 맨 앞에 추가로 교정.
- **감사 3라운드(`H-286` 실질 후보 각도 — brief §1 주의 ③ 지정 몫) —
  코퍼스 발견 0건, 판정 산출물 둘.** ①(Effect 드레인 vs cleanup 중
  `Rerun`)·③(`_catchUp` 에포크 랩) **둘 다 기각** — ①은 함수 본문 전사
  스파이크 재현으로(루프 안은 `_pending` 분기, 루프 밖은 HOLD 보존 — 유실
  0), ③은 전제 오류(`_catchUp`은 불리언 홀드 플래그이고 에포크 캐치업은
  `H-151`로 기폐기). round12 §6에 기각 사유 반영 — **②(unbind-relate,
  M6 몫)만 열린 채 남는다.**
- **감사 루프 종결** — 라운드별 새 발견 2 → 1 → 0으로 수렴(각도: diff
  정합성 / 교정분+인덱스 / `H-286` 지정 몫). 잔여 없음 — 3라운드 뒤의
  소규모 편집(round12 §6 기각 반영·STATUS 배너)은 doc-check ERROR 0으로
  게이트, diff 결함은 다음 단계 `/code-review` 몫.
- **`/code-review medium` 1회(운용 규약 — diff가 핸들러 하나+spec이라
  `high` 안 씀) — 발견 둘, 전부 머리말 3층 stale.** 정확성 결함은 0
  (리뷰가 브랜드 검사 상실·동률 순서·bindLifetime 전 Observer 창 후보를
  전부 코드·계약으로 반박했다고 보고). 살아남은 둘: `todos.md` 00번이
  "§0 회신 후 착수" 그대로 / `CLAUDE.md`·`project-context.md` 머리말이
  "규약 문항지 신설 대기" — 알고 있던 마감 몫이지만, 리뷰 지적대로 구현
  커밋에 모순을 실어 보내지 않도록 **M4 마감(머리말 3층)을 같은 커밋에
  접었다**(체크리스트 2번 — 배너가 부정하는 문장을 같은 커밋에서). 다음
  액션은 M5 규약 문항지 신설(단, M5는 Roblox 실기기 축이라 `HUMAN_TODO.md`
  선행 확인 필요 — todos 00번에 기록).
