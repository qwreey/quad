# round13 E55: 예외 안전성 주입 퍼저 — 사용자 콜백 자리마다 한 번 던지게 하기

HEAD `314ee177`, 2026-09-27. 레포 파일은 바꾸지 않았다. 하네스는 E50의 `harness.luau`·`engine-globals.luau` 사본(quad-roblox `luau_packages` 한 벌, `typing-limits.md` 8.34). `./scripts/relink.sh` 뒤 이 폴더에서 `luau <파일>`.

| 파일 | 내용 |
|---|---|
| `fuzz.luau` | 한 트리·한 연산 열을 두 번 돌린다(대조군 / 콜백 하나가 한 번 던짐). 끝에 고정 "치유" 입력을 넣고 모델 불변식으로 대조. 실패마다 "던진 예외가 지나간 사용자 프레임"을 기록해 문서 계약(`RULES`)으로 설명되는지 가른다. `luau fuzz.luau -a <첫 시드> <개수> [v\|q] [iso\|raw] [자리\|-] [noRecover\|obsStops]` |
| `out-fuzz-iso-1-10000.txt`, `out-fuzz-iso-10001-20000.txt` | 엔진식 핸들러 격리. 시드 2만, 발화 11648, 실패 시드 4381 — 전부 문서 계약으로 설명됨(UNEX 0) |
| `out-fuzz-raw-1-3000.txt` | mock 원형(시그널 핸들러 격리 없음). 시드 3000, UNEX는 cleanup 12·onDestroyed 18뿐 — 던지는 Destroying 핸들러가 mock `Destroy`를 끊는 E50 한계(Destroying 경로만) |
| `out-mutant-*.txt` | 검출력: `noRecover`(던진 Compute가 회복 안 함)·`obsStops`(던진 Observer가 발화 중단) 둘 다 UNEX로 잡힘 |
| `axes.luau` → `out-axes.txt` | P1 Compute 던짐을 누가 흡수하나 · P2 던지기 전 부작용 · P3 한 파동 둘 · P4 Traceback 줄 · P5 GC · P6 attach 창 · P7 Tween 콜백 · P8 Debounce · P9 Blocker:Off · P10 모듈 설치 · P11 Claim · P12 cleanup 출구 |
| `gc.luau` → `out-gc.txt` | 축 (d): 자리별 무-던짐 대조군과 나란히 수거 여부 |
| `deb.luau` → `out-deb.txt` | sugar/03:47 "leading 하나 유실" 대조군 비교 |

## 자리(27, 퍼저) — 문서 약속과 실측

| 자리 | 문서의 던진 뒤 상태 | 실측(2만 시드) |
|---|---|---|
| Compute fn(compute1/2/Tag/Tween) | 같은 세대 재읽기 Quad0184, 상류 바뀌면 회복 (core/03:77, errors/01:263) | 즉시 Quad0184 100%; 노드는 회복. **읽던 쪽이 자기 계약대로 굳음**(Effect 죽음·updateFn Length 동결) — 발견 A1 |
| Observer fn | 굳음(재구독 Quad0110), 발화는 계속 (core/05:108) | 일치, 값 회복 |
| Effect fn / cleanup | 죽음, Quad0088 (core/05:232) | 일치; 매단 호스트 파괴 때 dying cleanup 없음 |
| `:List` updateFn(후속 사이클) | Length 발행 정지, 재조정은 계속 (core/06:400) — UB | 일치(형제 Offset 어긋남) |
| updateFn/keyFn 첫 사이클 | 구독 없음, 영구 무반응 (core/06:400, Q132) — UB | 일치. 단 "첫 사이클 = `:List` 호출 안"은 미마운트 Slot엔 틀림 — 발견 A2 |
| keyFn(후속) | 문서 없음 | 무변경·다음 data Set에서 완전 회복(0/517 실패) — C2 |
| Offset 구독 | 부모 부기 영구 정지 (core/06:129) — UB | 일치(576/576) |
| Length 구독 | 다음 변경에서 회복 (core/06:129) | 일치 |
| PreRef/PostRef/Ref:Callback/OnCreated/OnRendered | Declaration 반쯤 (sugar/05:34·37, core/07:70) | 일치; List 안이면 updateFn 계약으로 전이 |
| Modifier 함수 필드(State 갈래) | 마운트/Set 줄에서 드러남 (core/08:130) | Compute와 같음 |
| Tween Started/Cancelled | **문서 없음**(extend/02:381 일반 규칙만) | 다음 값에서 회복 — C1 |
| Tween Completed(엔진) / OnChange / Out 하류 / OnDestroyed | 엔진 핸들러 격리 | 다른 자리 무결 |
| Debounce 타이머 통과 하류 | leading 하나 유실 (sugar/03:47) | 대조군 비교로 일치 |
| Blocker:Off 하류 | **sugar/06에 없음** (architecture는 "각 문서가 적는다") | 뒤 게이트 유보 → 다음 Off/신호로 회복 — A3 |
| RunInit/AddPlugin/UseProvider | core/01:58·92·140 | 일치 |
| Claim 적용 단계 | claim 잔존 (roblox/04:109) | 일치(재Claim Quad0029) |
| Context·Store | 사용자 콜백 자리 없음 | — |

발견 본문은 round13 원장에 반영할 몫이다.
