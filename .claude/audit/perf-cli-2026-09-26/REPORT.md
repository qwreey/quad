# CLI 산술 성능 측정 — P3(Compute 전파) · P2(Slot:List 갱신) — 2026-09-26

`research/perf-measurement-plan.md` §2의 P3·P2 첫 회차(sonnet, 자율 루프 1회차 — `session/2026-09-26-01-autonomous-loop.md`). **CLI mock 산술**이다 — 호출 수·할당·상대 비용만 믿고, `os.clock()`은 3회 반복 중앙값 참고치일 뿐 프레임 시간 주장이 아니다. 재현: 레포 루트에서 `./scripts/relink.sh` 뒤 `luau .claude/audit/perf-cli-2026-09-26/p3-compute.luau`, `luau .claude/audit/perf-cli-2026-09-26/p2-slotlist.luau`.

측정 과정의 교훈 둘(프로브 머리에도 적음): Observer 콜백이 `target:Get()`을 안 하면 리프 Compute는 재계산되지 않는다(게으름 계약 — 1차 초안이 recompute 0으로 나온 원인); 타이밍 반복과 카운팅을 같은 그래프·카운터로 하면 카운트가 반복 수만큼 불린다 — 최종 스크립트는 둘을 분리했다.

## P3 — Compute 전파

Source 1 → 선형 Compute 사슬 깊이 d → 리프에 Observer f개(살아 있는 mock Instance에 `bindLifetime`, 콜백에서 `target:Get()`). 원천 `:Set` 1회당:

| d | f | recompute | 발화 | t(중앙값) | gcΔ KB(그래프 빌드) |
|---|---|---|---|---|---|
| 1 | 1 | 1 | 1 | 0.000001s | 4 |
| 1 | 10 | 1 | 10 | 0.000004s | 14 |
| 1 | 100 | 1 | 100 | 0.000027s | 272 |
| 10 | 1 | 10 | 1 | 0.000006s | 15 |
| 10 | 10 | 10 | 10 | 0.000009s | 39 |
| 10 | 100 | 10 | 100 | 0.000032s | 246 |
| 50 | 1 | 50 | 1 | 0.000028s | 54 |
| 50 | 10 | 50 | 10 | 0.000029s | 78 |
| 50 | 100 | 50 | 100 | 0.000061s | 322 |

recompute는 정확히 d(f 무관), 발화는 정확히 f(d 무관) — d×f가 아니다(사슬 노드는 팬아웃과 무관하게 한 번만 재계산, 공유 캐시). f=1000(d=1)까지 0.000353s — f에 대략 선형. 다이아몬드(Source → a,b → 합류): `aRuns=1 bRuns=1 joinRuns=1 fires=1`, 값 일치 — 합류 노드 중복 재계산 없음.

## P2 — Slot:List 갱신

N=100/1000/5000 키드 리스트, 뮤테이션 1회당 `updateFn` 호출 수·mock 백엔드 `native*` 호출 수(Backend 함수 래핑)·시간.

호출 수(N에 비례, 세 N에서 같은 패턴):

| op | updateFn | insert | remove | move |
|---|---|---|---|---|
| end-insert-1 / front-insert-1 | N+1 | 1 | 0 | 0 |
| middle-delete-1 | N | 0 | 1 | N/2 |
| full-reverse | N | 0 | 0 | N-1 |
| full-replace(전 키 교체) | 2N | N | N | 0 |

삽입에서 move가 0인 것은 상대 순서가 안 바뀌면 물리 재배치가 없기 때문(`Slot/Raw.luau` rawMove 주석 — Roblox는 LayoutOrder 순서).

시간(중앙값 3회, 매회 새 리스트) / gcΔ KB:

| op | N=100 | N=1000 | N=5000 |
|---|---|---|---|
| end-insert-1 | 0.000105s / 42 | 0.000939s / 364 | 0.005496s / 1951 |
| front-insert-1 | 0.000115s / 42 | 0.001124s / 364 | 0.006388s / 1951 |
| middle-delete-1 | 0.000166s / 44 | 0.001603s / 394 | 0.009938s / 2106 |
| full-reverse | 0.000992s / 44 | 0.083319s / 423 | **1.989941s** / 2259 |
| full-replace | 0.001587s / 266 | 0.089468s / 2584 | **2.054708s** / 13691 |

관측: 단일 삽입·삭제는 N에 대략 선형. **full-reverse·full-replace는 시간이 거의 이차적** — N 10배에 ~84배/~56배, N 5배에 ~24배/~23배(O(N²) 기대치 100배/25배). 호출 수는 선형인데 시간이 그렇지 않으므로 병목은 "호출 1회의 비용이 N에 비례"하는 쪽으로 보인다. **가설(소스 읽기, 실행 트레이스로 확정 안 함)**: `quad-base/src/Slot/Raw.luau`의 `rawAdd`/`vacate`(rawRemove·rawUnmount·rawDetach 공유 꼬리)가 부르는 `reindexFrom(self, index)`가 `index`부터 `_elements` 끝까지 전부 재인덱싱한다. full-replace는 새 키 N개를 추가하는 동안 옛 원소 N개가 아직 배열 끝에 남아(KeyGone 제거 패스가 뒤에 돔) 매 `rawAdd`가 그 시점 배열 크기(~2N)만큼 훑는 것으로 보인다 — N번의 O(N). `rawMove`는 `H-505`(2026-09-08)로 `reindexRange`(건드린 구간만)로 좁혀졌지만 full-reverse는 항목별 이동 거리가 넓어 구간 총합이 여전히 O(N²)에 가깝다. GC 델타도 같은 구간에서 튄다(full-replace N=5000: 13.7MB) — 원인/결과는 이 프로브로 못 가름.

중첩 Slot(바깥 N, 자리1이 안쪽 Slot:List 10개) — 안쪽 삽입 1의 `Bookkeeping.getOffsetAt` 호출 수·시간:

| outerN | getOffsetAt 호출 | t |
|---|---|---|
| 10 | 12 | 0.000023s |
| 100 | 12 | 0.000034s |
| 1000 | 12 | 0.000140s |
| 5000 | 12 | 0.000627s |

호출 수는 outerN과 무관하게 12로 고정인데 시간은 outerN에 대략 선형 — 이유는 이 프로브로 못 갈랐다(후속 조사 후보).

## O(?)로 보이는 것 / 구조를 볼 후보(관측, 단정 아님)

1. 모든 `Slot:List` 뮤테이션은 최소 O(N)(updateFn이 전체를 훑는 reconcile) — 기존 구조 재확인.
2. 단일 삽입/삭제는 선형 — 문제 없어 보임.
3. **전체 역순·전체 교체는 거의 이차적** — 가장 눈에 띄는 신호. 후보 원인은 위 `reindexFrom` 가설. 공개 표면과 무관한 내부 구현이라 고칠 수 있어 보이지만, 먼저 실행 트레이스(`reindexFrom` 호출마다 스캔 길이)로 원인을 확정해야 한다.
4. Compute 전파는 깊이·팬아웃·다이아몬드 dedup 셋 다 기대대로 — 구조를 볼 이유 없음.
5. 중첩 Slot 안쪽 삽입이 바깥 크기에 선형으로 느려지는 것 — 원인 미확인.

## 미완

P1/P4/P5/P6(Studio 몫). 3·5의 원인 확정(→ 자율 루프 후속 탐사 P2-trace).

## P2-trace — 이차 비용의 원인 확정(opus, 같은 날 밤; `p2-trace.luau`, 약 33s)

계측은 전부 런타임(소스 수정 없음): `q.Bookkeeping`의 `getOffsetAt`·`_recompute`·`setLength`·`setOffsetSource`와 `q.Backend.native*` 래핑(스캔 길이 = 캐시 커서 전진량 / 진입 `bk.N`, 호출자는 `debug.info(2,"n")`), `Slot/Raw.luau`의 지역 함수(`reindexFrom`·`reindexRange`·`spliceArraysUp/Down`·`rotateInPlace`)는 마운트 뒤 bk 테이블 다섯을 카운팅 프록시로 바꿔 쓰기 수 = 스캔 수로 셈. 카운트와 시간은 별도 빌드.

**(1) 전체 역순·전체 교체 — O(N²) 확정, 원인 함수가 갈린다.** 뮤테이션 1회 쓰기·스캔 수(오른쫌은 N=5000 값 / N²):

| op | writer → 대상 | N=100 | N=1000 | N=5000 | /N² |
|---|---|---|---|---|---|
| full-reverse | `getOffsetAt` 커서 전진, 호출자 **rawMove** | 4,852 | 498,502 | 12,492,502 | 0.50 |
| full-reverse | `reindexRange` → indexOfElement | 5,049 | 500,499 | 12,502,499 | 0.50 |
| full-reverse | `rotateInPlace` → lengthList/sourceList/observers(각) | 5,049 | 500,499 | 12,502,499 | 0.50 |
| full-replace | `reindexFrom` → indexOfElement | 12,395 | 1,244,569 | 30,960,289 | 1.24 |
| full-replace | `spliceArraysUp` → 세 배열(각) | 10,100 | 1,001,000 | 25,005,000 | 1.00 |
| full-replace | `spliceArraysDown` → 세 배열(각) | 2,395 | 244,569 | 5,960,289 | 0.24 |
| full-replace | `getOffsetAt` 커서 전진, 호출자 **rawRemove** | 945 | 81,280 | 2,047,809 | 0.08 |
| (둘 다) `_recompute` 스캔 | | 100 | 1,000 | 5,000 | 선형(1회) |

시간 비중(N=5000, 자기 시간): full-reverse 2.00s = `getOffsetAt` **62%** + 나머지 37%(reindexRange·rotate ×3); full-replace 2.09s = `getOffsetAt` 10% + mock `nativeRemove` 1.8% + 나머지 **87%**(reindexFrom ≈0.37s, splice up/down 세 배열 ≈0.65s — 마이크로벤치 단가 12ns/7ns로 곱한 **추정**; updateFn·Instance 생성·`_elements` memmove 비중은 미분해).

기전 — **full-replace**: reconcile이 새 키를 앞자리에 `rawAdd`하고 KeyGone 패스는 뒤에 도므로 옛 원소 N개가 배열 뒤에 남아 매 `rawAdd`가 `reindexFrom`(끝까지)·`spliceArraysUp`에서 ~N칸을 밈(가설 그대로); 이어 KeyGone 패스가 `pairs` 순서로 지우며 매 `vacate`가 `reindexFrom`·`spliceArraysDown`(0.24N²)을 돌고 `rawRemove`의 `getOffsetAt`이 캐시를 다시 채움(0.08N²). **full-reverse**: 가설과 다르다 — 주범은 `reindexRange`가 아니라 **`rawMove`가 물리 op에 넘길 offset을 얻으려고 부르는 `getOffsetAt(fromIndex)`**(62%): 매 이동이 끝자리에서 slotPos로 끌어오고 직전 rotate가 캐시 커서를 slotPos-1로 내려 놓아 slotPos..N을 다시 채움(합 N²/2). 그런데 출시된 두 백엔드 모두 `nativeMove`가 no-op(`quad-roblox/src/EngineOps.luau:74`, mock)이라 계산한 offset을 받아 놓고 쓰지 않는다. 나머지는 `reindexRange`·`rotateInPlace` ×3이 각각 N²/2 — 이동 거리가 넓어 `H-505` 구간 좁히기의 효과가 없다.

**(2) 중첩 Slot 선형 증가 — 확정: 바깥 Slot 전체 recompute 1회, 설계대로.** 안쪽 recompute가 끝에서 `Length:Set` → 바깥 `setLength`의 Observer 발화 → `gatedRecompute`가 Bookkeeping 내부 지역 `recompute(outer)`를 직접 부름(BK 테이블을 안 거쳐 `_recompute` 래핑에 안 보임 — bk 프록시 읽기 카운트로 확인: outerN=5000에서 sourceList·lengthList 읽기 5000/5000, `_recompute` 자기 시간 93%). 뒤따르는 잎은 None 자리라 `getOffsetAt`을 안 부름(`H-483`) → 호출 수 12 고정. `dispatch-core-plan.md` "recompute — 매번 전체 순회"가 정한 동작, 5000에서 0.6ms(한 칸 ~120ns). 관측된 병목이 아니라 지금 고칠 근거 없음.

**(3) 고치는 갈래(코드 미수정 — 원장 round13 §4 Q76·Q77).** full-replace: A1 KeyGone 패스를 배치 앞으로(O(N)이 되고 가장 단순 — 그러나 updateFn 호출 순서가 바뀌어 사용자 관측 동작, `H-38` prevKeys 증분 기록과 관계 재확인) / A2 연속 추가를 모아 `rawSplice` 한 번(표면 무변경, physIndex 산술·Slot 길이 미지 위험 중간) / A3 reindexFrom 게으르게(불변식 깨짐 — 비권고). full-reverse: B1 백엔드가 이동 offset을 안 쓰면 `getOffsetAt` 둘 건너뜀(~60% — 그러나 offset은 백엔드 op 계약 인자라 계약 변경) / B2 reconcile이 최종 순열을 계산해 한 번에 적용(내부 변경, 복잡도·위험 높음) / B3 Fenwick 트리(비권고). 개선 뒤 실측은 없다(미완).
