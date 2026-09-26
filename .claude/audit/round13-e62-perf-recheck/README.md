# E62 — CLI 성능 P1~P6 재측정: 기준선 vs HEAD (2026-09-27, round13 자율 루프)

기준선 `audit/perf-cli-2026-09-26/REPORT.md`의 프로브 다섯(p1-mount·p2-slotlist·p2-trace·p3-compute·p6-gc, 이 폴더에 사본)을
**같은 하네스·같은 명령**(`luau <probe>` — REPORT가 적은 대로 `-O2` 없음, 프로브 안에서 3회 중앙값)으로 두 트리에서 번갈아 돌렸다.
**결론: 회귀 없음, 개선 없음. 호출·스캔 수는 전 항목 바이트 단위 동일, 시간은 전 항목 ±10% 안.**

## 방법

- 트리 셋(스크래치, `cp -rL` 한 워킹트리에 `git archive <sha>`의 `*/src`·`quad-base/test`·`quad-roblox/test`를 덮고,
  `luau_packages/.pesde/*/{quad_base,quad_types,quad_error,type_version_check}/src`도 같은 sha로 덮음 — 세 트리 모두 `relink.sh` 뒤의 같은 모양):
  - **base** = `85383454`(P1/P6/p2-trace가 커밋된 커밋. REPORT에 sha가 없어 커밋 시점으로 추정 — 아래 (a)1),
  - **base0** = `6f3da255`(P2/P3가 커밋된 커밋, `9afd271e`·`a38f4a00`의 Dispatch 변경 전 — p2/p3만),
  - **head** = `36db81c6`.
  `base..head`의 런타임 차이는 `Effect.luau`(`H-707`)·`Ref/init.luau`(`H-681`)·`Store.luau`(`H-671`)·`Debounce.luau`(주석)·`Claim.luau`(주석)·
  `quad-roblox/src/EngineOps.luau`·`init.luau`(주석)·`quad-base/test/mock.luau`(`H-658`·`H-659`·`H-748`).
- 하네스: 기준선 프로브 그대로 — p2/p3은 `quad-base/test/mock`(→ `quad-base/src`), p1/p6은 `quad-roblox/luau_packages/quad_base` +
  `quad-roblox/src` + mock의 Instance 배관(기준선과 같은 혼합 — 런타임만 쓰므로 `typing-limits.md` 8.34의 타입 신원 문제는 해당 없음). 양쪽 동일.
- 반복: `run.sh` — base/head를 번갈아 5라운드(p2-trace는 2라운드), 라운드마다 `round13-slot-bundle/bench.slot-bundle.luau`(`-O2`, 7빌드 최솟값)도.
  base0은 p3 5회·p2 3회. 추가로 B9·B10·B13·B14만 뽑은 `bench.e62focus.luau`를 15회 교대.
- 집계: `agg.py` → `agg.out.txt`(칸마다 라운드 중앙값·최솟값·비율). 원출력 `raw/<tree>-<probe>-r<i>.txt`, 벽시계 `raw/wall.log`.
- 머신: 4코어, load ≈0.7, luau 0.734.

## 표 (시간 = 라운드 중앙값, 괄호는 최솟값; 비율 = head/재측정 기준선 중앙값)

| 항목 | 기준선 REPORT | 기준선 재측정 (base) | HEAD | 비율 | 판정 |
|---|---|---|---|---|---|
| P3 recompute/발화(9 모양)·다이아몬드 | d / f / 1·1·1·1 | 동일 | 동일 | — | 동일(수 일치) |
| P3 t d=1 f=100 | 27µs | 27µs | 27µs | 1.00 | 동일 |
| P3 t d=10 f=100 | 32µs | 33µs | 33µs | 1.00 | 동일 |
| P3 t d=50 f=100 | 61µs | 57µs (55) | 60µs (59) | 1.05 | 동일 |
| P3 f=1000 (d=1) | 353µs | 361µs (343) | 364µs (348) | 1.01 | 동일 |
| P3 gcΔ d=1 f=10 | **14KB** | 29 (base0도 28~29) | 29 | 1.00 | 동일 — REPORT 값 재현 안 됨, (a)2 |
| P2 호출 수(15행) | 표 그대로 | 동일 | 동일 | — | 동일(바이트 동일) |
| P2 end-insert-1 N=5000 | 5.50ms | 4.90ms | 4.92ms | 1.00 | 동일 |
| P2 middle-delete-1 N=5000 | 9.94ms | 8.55ms | 8.56ms | 1.00 | 동일 |
| P2 full-reverse N=1000 | 83.3ms | 81.3ms | 81.9ms | 1.01 | 동일 |
| P2 full-reverse N=5000 | 1.990s | 1.990s | 2.011s | 1.01 | 동일 |
| P2 full-replace N=1000 | 89.5ms | 87.2ms | 87.9ms | 1.01 | 동일 |
| P2 full-replace N=5000 | 2.055s | 2.066s | 2.054s | 0.99 | 동일 |
| P2 gcΔ(15행) | 표 그대로 | ±2KB | ±2KB | 1.00 | 동일 |
| P2-nested getOffsetAt / t outerN=5000 | 12 / 627µs | 12 / 642µs | 12 / 644µs | 1.00 | 동일 |
| p2-trace 쓰기·스캔 수(세 op × 세 N) | 12,492,502 / 30,960,289 / 5,960,289 / 2,047,809 … | 동일 | 동일 | — | 동일(바이트 동일) |
| p2-trace full-reverse 5000 / getOffsetAt 비중 | 2.00s / 62% | 2.019s / 62% | 2.004s / 62% | 0.99 | 동일 |
| p2-trace full-replace 5000 / getOffsetAt 비중 | 2.09s / 10% | 2.131s / 10% | 2.084s / 10% | 0.98 | 동일 |
| p2-trace micro 단가 | 12ns / 7ns | 12.7 / 7.2ns | 12.7 / 7.3ns | 1.00 | 동일 |
| P1 카운트(정적·list, 세 N) | 표 그대로 | 동일 | 동일 | — | 동일(바이트 동일) |
| P1 props 1/5/10 t | 0.019/0.026/0.041s | 0.0191/0.0259/0.0413 | 0.0187/0.0262/0.0411 | 0.98~1.01 | 동일 |
| P1 static / list N=5000 t | 71.6 / 67.1ms | 73.4 / 68.2ms | 71.7 / 68.9ms | 0.98 / 1.01 | 동일 |
| P1 gcΔ static/list N=5000 | 22913 / 22677KB | 22914 / 22676 | 22913 / 22676 | 1.00 | 동일 |
| P6 residKB static 100/1000/5000 | 36/295/2240 | 37/295/2239 | 37/295/2239 | 1.00 | 동일 |
| P6 residKB list 100/1000/5000 | 24/191/1535 | 24/192/1536 | 24/192/1535 | 1.00 | 동일 |
| P6 weak refs 생존·bkLeft | 없음·0 | 없음·0 | 없음·0 | — | 동일 |
| P6 list baseKB | 1623/1624/1624 | 1632 | 1635~1636 | +3KB | (c)2 |

`bench.slot-bundle`(`-O2`, 7빌드 최솟값) — `round13-slot-bundle/bench.summary.txt` base 열(2026-09-27 새벽, 트리 `5d299c6c`; HEAD와 src 차이는
`Debounce.luau` 주석뿐, mock 차이는 `setAttr` 게이트로 이 벤치가 안 지나감)과 대조. **같은 하네스**(`quad-base`에서 `luau -O2 test/bench.slot-bundle.luau`,
`./mock` → `quad-base/src`); 저쪽은 3회 최솟값, 여기는 5회 최솟값:

| 행 | summary base | 이번 base(`85383454`) min | 이번 HEAD min | HEAD/summary |
|---|---|---|---|---|
| B1 | 88.123 | 88.240 | 88.496 | 1.00 |
| B2 | 207.142 | 206.380 | 204.903 | 0.99 |
| B3 | 47.330 | 48.029 | 48.093 | 1.02 |
| B4 full replace | 90.217 | 90.530 | 89.910 | 1.00 |
| B5 full reverse | 71.991 | 71.731 | 72.063 | 1.00 |
| B6 | 50.282 | 50.279 | 50.312 | 1.00 |
| B7 end-insert | 0.740 | 0.706 | 0.706 | 0.95 |
| B8 middle-delete | 1.292 | 1.235 | 1.243 | 0.96 |
| B9 | 12.377 | 12.308 | 12.229 | 0.99 |
| B10 | 9.183 | 8.542 | 9.487 (focus 15회: 8.007) | 1.03 (focus 0.87) |
| B11 | 7.474 | 7.373 | 7.305 | 0.98 |
| B12 d1/d10/d100 | 13.303/31.527/209.755 | 13.083/31.322/206.0 | 13.197/31.058/210.359 | 0.99/0.99/1.00 |
| B13 | 1.685 | 1.615 | 1.661 | 0.99 |
| B14 | 8.322 | 7.858 | 7.931 | 0.95 |

B10은 전체 벤치 5회에선 HEAD 최솟값이 base보다 11% 높았지만(8.54 → 9.49), 단독 15회 교대(`bench.e62focus.luau`)에선
base min 8.115 / med 8.626, HEAD min 8.007 / med 8.663 — 차이 없음. B13·B14의 중앙값 1.6배는 양쪽 트리 모두에 나오는 이봉(1.6↔2.9ms, 8↔13ms,
GC 시점 모드)이고 최솟값은 같다.

겹치는 항목: P2 full-replace N=1000(87.9ms, `-O` 기본) ↔ B4(89.9ms, `-O2`), P2 full-reverse N=1000(81.9ms) ↔ B5(72.1ms) — N은 같지만 updateFn 몸통·측정 경계(`median of 3` vs `min of 7`)와
최적화 수준(`-O2` 유무)이 달라 비율 비교 대상이 아니다. 둘 다 같은 날 두 측정 모두 안정.

## 발견

**(a) 문서 오류**
1. REPORT는 측정한 커밋 sha를 적지 않았다. P2·P3는 `6f3da255`(21:28)에, P1·P6·p2-trace는 `85383454`(22:28)에 커밋됐고 그 사이
   `9afd271e`·`a38f4a00`이 `Dispatch/init.luau`를 바꿨으므로 두 반쪽의 코드 상태가 다를 수 있다. 이번엔 두 커밋을 다 재측정해 결과가 같음을
   확인했다(p2·p3 수 동일, 시간 ±3%).
2. REPORT P3 표의 d=1·f=10 gcΔ `14`KB는 어느 커밋(`6f3da255`·`85383454`·HEAD)에서도 재현되지 않는다(15회 전부 28~29KB). d=10·f=1이
   14~15KB라 행이 섞였거나 당시 단발 값일 수 있다 — 결론(선형·수 정확)엔 영향 없음.

**(b) 코드 결함(회귀)** — 없음. 네 변경 모두 측정 경로에서 비용이 보이지 않아 이분 탐색은 하지 않았다.

**(c) 판단 필요**
1. 시간 절대값이 REPORT보다 일부 10% 넘게 낮다(P2 end-insert-1 N=5000 5.50 → 4.90ms, middle-delete-1 N=5000 9.94 → 8.55ms). 재측정한
   기준선 트리도 똑같이 낮으므로 코드가 아니라 머신 상태 차이다 — REPORT 절대값은 그날 한 번의 머신 상태로 읽을 것.
2. P6 list baseKB가 REPORT 1623 → 재측정 기준선 1632 → HEAD 1635(+3KB). HEAD의 +3KB는 `Effect`·`Ref`·`Store` 소스가 길어진 만큼의 상주
   바이트코드로 보이며 잔존(residKB)은 같다. 이 영향으로 P3 gcΔ 단발값(d=10·f=100, d=50·f=100)이 두 트리에서 서로 다른 이산 모드
   (282↔234KB, 301↔321KB)에 걸리지만 한 트리 안에서도 모드가 바뀌므로(base 235~282) 잡음으로 판정.
3. 전체 벤치 안의 B10 최솟값 +11%는 단독 15회 교대에서 사라졌다 — 벤치 앞 행이 남긴 힙 상태에 따른 순서 효과로 판정.
