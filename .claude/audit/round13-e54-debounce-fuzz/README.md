# round13 E54 — Debounce/Throttle 가상 시계 참조 모델 차등 퍼저 (2026-09-27)

실행(레포 루트, `./scripts/relink.sh` 뒤): `luau .claude/audit/round13-e54-debounce-fuzz/fuzz.luau -a <seed0> <n> [v] [mut]`, `luau .claude/audit/round13-e54-debounce-fuzz/probes.luau`.
quad는 `mock.newQuad()` 한 벌만 require(`typing-limits.md` 8.34).

- `fuzz.luau` — 참조 모델(규칙 R1~R15, 파일 머리 주석에 sugar/03 줄 번호) + GateNode 에포크 규칙(`State.luau` GateImpl `_receive`/`_flush`, gate-plan 규칙 3). 토폴로지 넷(T0 Source→게이트, T1 Source→Blocker→게이트, T2 게이트→Blocker, T3 게이트→게이트), 옵션 무작위(Time 3/64~2·5% 0, Leading/Trailing nil 포함 셋×셋, MaxTime 비율 0~4, Time/MaxTime State), 신호 열 다섯 패턴, Flush/Cancel(핸들·팩토리), Time/MaxTime `:Set`(무효값 포함), Blocker On/Off/OffWithoutEmit, 하류 throw, 호스트 Destroy, 관찰자가 값을 읽는/안 읽는 두 모드. 시드마다 coarse(이벤트 사이 advance 한 번)·fine(무작위 분할) 두 번 구동. 모든 시각은 1/1024 격자라 부동소수 오차 없음. 이벤트마다 기록 열·pending 타이머 수·게이트별 보류/창/캡 유무·`:Get()` 최신성 비교. `pure` 시드(신호만)는 모델과 독립인 문서 불변식 INV-A~F + 2×Time 수거 상한 검사.
- `probes.luau` — 축 (a)~(f)·미정 칸 U1~U7·X1(게이트 뒤 게이트의 읽기 의존 삼킴).
- `out/` — 실행 결과(80,000 시드 차등 0, 모델 결함 주입 6종 전부 검출, 프로브 출력).
