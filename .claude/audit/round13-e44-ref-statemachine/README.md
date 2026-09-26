# round13 E44 — Ref / PreRef / PostRef 상태 기계 차등 검사

HEAD `86523a1d`, 2026-09-27. 레포 파일 무변경. 하네스는 `round13-s10-snippet-recheck/`의
`harness.luau`·`engine-globals.luau` 사본(quad-roblox `luau_packages` 한 벌 — `typing-limits.md` 8.34).
`./scripts/relink.sh` 뒤 이 폴더에서 `luau <파일>`.

| 파일 | 무엇 |
|---|---|
| `STATE-TABLE.md` | 문서 계약 → 상태표 69칸(근거 파일:줄, 실측, 판정) |
| `fuzz.luau` | 참조 모델 + 이벤트 시퀀스 퍼저(길이 5~25). `luau fuzz.luau -a <첫 시드> <개수> [v]` |
| `fuzz-5000.txt`, `fuzz-5001-10000.txt` | 시드 1~10000 결과(각 5000 시드, 약 7.5만 op, 차등 0) |
| `axis-b-reentry-order.luau` | (a) 콜백 순서, (b) 재진입 `Set`, 순회 중 해제+재등록, 같은 값·None·false |
| `axis-c-wait-thread.luau` | (c) `Wait(thread)` 다섯 상태, `Quad0130`/`0133`/`0134`, 두 Ref 등록, 다른 Ref 대기자 가로채기 |
| `axis-de-postref-hooks.luau` | (d) PostRef 발화 없는 소진 조건 11가지, (e) 훅 셋 |
| `axis-f-misc.luau` | (f) 비 Instance 값, 퍼저가 건너뛴 자리 칸(State 자리 충돌·파괴 뒤 State 자리·동적 재진입) |
| `probe-stringkeys.luau` | 문자 키 × 셋 종류 × 키 부류(반영 프로퍼티·이벤트·Parent·임의) |
| `probe-basic.luau` | Destroy/dispose 뒤 재놓기 기초 |
| `out-*.txt` | 위 스크립트 출력 |

퍼저 모델: Ref 둘 × 콜백 풀 여섯(평범 셋, 순회 중 재등록 `cX`, 순회 중 해제 `cU`, 재진입 `cR`) × 대기자 셋 종류
(`Wait()` 1회·2회 재대기, `Wait(parked thread)`) + 숫자 키 놓기/두 자리/pre·ref·post 혼합/dispose/Destroy/State 자리 교체/
자리 인스턴스 Destroy + 일회용 둘. 순서가 문서상 미정인 곳(콜백 순서, 재진입 바깥 순회, `Quad0130`·죽은 스레드로 끊긴 순회)은
개수 범위·값 집합으로만 비교하고, 끊긴 순회 뒤엔 실제 등록 집합을 채택한다. 변이 셋(대기자 소진 제거·`Quad0232`↔`0233`·
dispose가 값 지움)으로 검출력 확인 — 500 시드에서 차등 7·114·131.

결과와 발견 세 갈래는 원장(round13) 반영 몫 — 이 폴더는 근거만.
