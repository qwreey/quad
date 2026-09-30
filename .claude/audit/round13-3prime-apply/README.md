# round13 묶음 3′ 반영 전 조합 재검증 (2026-09-30)

사용자 결정(원장 Q73·Q109·Q110 닫힘 문단)대로 세 패치를 **한 사본에 함께** 얹어 재검증한 기록이다 — 내부자 검토가
"개별 패치 조합은 핵심 시나리오만 검증됨"이라며 반영 전 조건으로 건 것.

- 조합 **C** = `round13-obs-eff-root/D1-observer-install-loop.diff` + `D2-observer-source-revision-stamp.on-D1.diff`
  + `round13-obs-eff-unify/Uprime-effect.diff`, HEAD `bc8c8329` 위(격리 워크트리). 기준선 **H** = 같은 사본의 HEAD 소스.
- 드라이버 `all.sh`(스크래치 경로 그대로 — 재실행하려면 `W`/`SCR` 수정), 프로브 묶음 `runall.sh`(원본은
  `round13-obs-eff-unify/runall.sh`), 큰 퍼저 `bigfuzz.sh`(원본 `round13-obs-eff-root/bigfuzz.sh`), 비교 `cmp.sh`.

## 결과

- `test.sh` exit 0(조합 C).
- `summary.txt` — 큰 퍼저 2만 시드: E3 퍼저 실패 C 0 / H 0, E3 카운터 `pureCoreInstallStale` **C 0 / H 1520**(실패 C 0 / H 1),
  재진입 퍼저 6000(unm) 실패 **C 0 / H 22**(seed 219·555·622 … — Q73 계열), excl은 둘 다 0.
- `cmp.H-C.txt` — 프로브별 H→C 차이. 전부 결정에서 예상한 방향:
  - q109·e20-c·e20-c2b: Source dep의 파동 도중 되살리기·중첩 이중 실행 1x/2x 반반 → **1x200**(Observer·Effect 모두); Compute dep은
    설계상 그대로(파생 State는 자기 emit 맵이 거름).
  - e79: 축 6(F6) `outer.Length` 1 → **2**, Source 직접 Observer 이중 실행 `[A,A,AB,AB]` → `[A,AB]`, mount-sync 되쓰기 고리는
    프로브 자체 한도 300까지 돎(진동 상한 없음 결정의 예상 모양).
  - osc: 수렴 안 하는 설치 fn이 프로브 한도 10만까지 돎(상한 없음 — 사용자 결정). throw: 던지는 설치 뒤 핸들이 `_subs`에 남음(서술 갱신 대상).
  - debounce: `Throttle` 설치 창의 선행 값이 이제 보임(`0` → `0,1`). e3: 설치 창 유실 복구(`seen 0` → `0,1`).
  - e20-h·e20-c order: 해시 순서 잡음(구독 순서 무보장 계약).
- **e1b**: 조합 C에서 C3x(수렴점이 없는 진동 그래프 — 프로브 주석 "no correct fixed point exists")가 **무한히 돈다**(에러 없이 멈추지 않음 —
  상한 없음 결정의 귀결; 앞선 실행은 PROBECAP 한도를 걸거나 건너뜀). C3x만 빼고 돌린 `e1b.C.noc3x.txt`: H에서 LOSS였던 A1~F 전부
  **no-loss**; Q74 GHOST 둘은 그대로(별도 문항).
