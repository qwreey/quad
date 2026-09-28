# round13 Tween 콜백 구조 스파이크 — "모으고 → 쓰고 → 부른다" (2026-09-28, mock만)

`research/tween-callback-structure.md` §3·§7-1의 스파이크. 격리 worktree에서 `quad-roblox/src/Handlers/Property.luau`만 고쳐 돌렸다
(원 레포 `src` 무변경). 실기기 없음 — 엔진 사실이 필요한 판단은 "실기기 전제"로 표시.

## 파일

| 파일 | 뭔가 |
|---|---|
| `Property.collect-write-call.diff` | 변형 구현(HEAD `d5d25406` 기준). 스위치 둘: `TEARDOWN_WINDOW_AS`(`"Completed"` = 오늘 / `"Cancelled"` = Q99 c), `ARM_AT_STARTED`(false = 과제 그대로 / true = 곁가지 관찰용) |
| `probe.cbs.luau` | 프로브(절 2~6, 4b·4c·5b). `quad-roblox/test/`에 두고 `luau test/probe.cbs.luau` |
| `run.sh` | `run.sh <worktree> base\|variant [TEARDOWN_WINDOW_AS] [ARM_AT_STARTED] [spec]` — 스크립트 옆에 둔 `Property.base.luau`(= HEAD 본)·`Property.variant.luau`(= diff 적용본)를 갈아 끼우고 프로브(+`spec`이면 test.sh) |
| `out-base.txt` | HEAD 그대로 |
| `out-v-C-false.txt` | 변형, 철거 창 = Completed(Q99 c 없음) |
| `out-v-X-false.txt` | 변형 + Q99 c |
| `out-v-C-true.txt`·`out-v-X-true.txt` | 위 둘 + `ARM_AT_STARTED` |

재현: worktree에서 `mise exec -- pesde install` → diff 적용 → 프로브 복사 → `./scripts/test.sh; echo $?`, `cd quad-roblox && luau test/probe.cbs.luau`.

## 구현 요지

- `stopRunning` → `settle(rec): (cb?, finished)` — Cancel·Disconnect·`Done`만 하고 사용자 콜백은 부르지 않고 돌려준다.
- `process`: 옛 정산 콜백을 들고 있다가 슬롯 쓰기(엔진 경로면 `Play`까지) 뒤 `announce`가 옛 정산 → 새 `Started` → (스냅) 새 `Completed` 순으로 부른다.
  새 값의 콜백마다 그 앞에서 `tweenSlots:GetStrong(inst, k) == rec`를 보고, 앞선 콜백이 같은 자리를 다시 처리해 레코드가 바뀌었으면 멈춘다.
  plain 값 경로는 `true` 기록 뒤 옛 정산만. 첫 쓰기 스냅도 같은 `announce`(옛 것 없음).
- retractor: 슬롯 강등(`{ Value }`/`true`) 뒤에 콜백. 창이면 `TEARDOWN_WINDOW_AS`.
- 새 필드·새 공개 이름 없음(`ARM_AT_STARTED`는 기존 `rec.Cb`를 다는 시점만 옮김 — 관찰용 스위치).

## 결과 요약 (수치는 out-*.txt; 이 절이 요약의 소스)

1. test.sh: 네 설정 전부 exit 0(스펙 62). 기존 순서 단정(spec.tweenproperty 11절 293·301·341·360행)과 던지는 `Cancelled` 단정(364~374행)이 그대로 성립.
2. Q91: 고아 0(베이스: 패딩 1라운드 뒤 2, T5 1, T6 엔진 교체 1). 단 패딩 숏핸드의 최종 값은 베이스와 똑같이 `103/103/101/101`(s=103) —
   숏핸드가 한 값을 네 변에 차례로 넘기는 루프가 안쪽 재진입 뒤 옛 값으로 나머지 변을 덮는다(Property 층 밖의 같은 결).
3. `H-589` 재진입(Started·Cancelled·스냅 Started): 전부 고아 0·최종 값 = 마지막 `:Set`·순서 일관. 첫 쓰기(마운트 중) 스냅 `Started` 안 `:Set`만
   State와 화면이 어긋남(베이스와 동일 — StoreBind 등록 발화 안의 재진입).
4. Q146: `Started`·스냅 콜백 throw는 베이스와 동일. 옛 `Cancelled`/창 `Completed` throw는 베이스 "새 트윈 미재생·값 유실·옛 목표 재선언이 dedup에 막힘"
   → 변형 "새 트윈 재생·기록, 새 `Started`만 유실, 철거가 먼저 오면 그 트윈은 안 끊김(NOOP 표식)".
5. 비재진입 순서는 베이스와 전 행 동일. 달라지는 것: Q99 c의 철거 창 행, 재진입 행, 옛 콜백 안에서 읽는 프로퍼티 값(5b — 이제 새 값).
6. 논리 줄(주석·빈 줄 제외) 222 → 243(스위치 둘 포함, 빼면 약 +17).
