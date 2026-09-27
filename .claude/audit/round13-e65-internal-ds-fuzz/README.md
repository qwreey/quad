# E65 — 내부 자료구조(EpochMap·Relate·ImplRegistry·Void·Bookkeeping) 참조 모델 차등 퍼저 (2026-09-27)

하네스 한 벌: `quad-roblox/luau_packages/quad_base`(typing-limits 8.34) + mock 백엔드(`quad-base/test/mock.luau`).
내부 모듈(`EpochMap`·`Relate`·`ImplRegistry`·`Void`)은 **같은 설치본의** `.pesde/.../quad_base/src/<모듈>`을 직접 require
(Brand 신원이 `Quad.New()`와 같다). `relink.sh` 뒤 레포 루트에서 `mise exec -- luau <파일> -a …`. 레포 파일 무변경.
판정은 전부 실행 결과이고, 엔진(Roblox) 동작은 하나도 재지 않았다.

| 파일 | 내용 |
|---|---|
| `env.luau` | `Quad.New()` + mock 프로바이더(시드마다 새 인스턴스) |
| `rng.luau` | E64와 같은 결정적 xorshift |
| `fuzz-leaf.luau` | `epoch`/`relate`/`impl` 세 모드 — EpochMap 규칙 EM1~EM6, Relate R1~R5, ImplRegistry I1~I2(머리 주석이 문서 줄) |
| `fuzz-bk.luau` | `q.Bookkeeping` 참조 모델 B1~B10(접두합·오류 ID·동결·배치·State 길이·캐시 정확성) |
| `fuzz-owner.luau` | `claimOwnerAt`/`releaseOwner` + `q.dispose` 보유 게이트, 규칙 O1~O5 |
| `out-fuzz-*.txt` | 기본 모델 실행 결과(아래 표) |
| `out-mutants.txt` | 모델 변이 16개의 검출 |
| `axes.luau` / `out-axes.txt` | 표적 축 (a)~(j) — `-a <축>`으로 하나만 |
| `probe0.luau` / `out-probe0.txt` | 교체된 State 길이의 옵서버가 정말 끊기는가 |
| `probe-blame.luau` / `out-probe-blame.txt` | Relate nil 인자 blame 줄 |
| `probe-owner-kinds.luau` / `out-probe-owner-kinds.txt` | 부기 ownerKey로 평범한 테이블·문자열·NaN·미claim 인스턴스(mock / 실 quad-roblox 프로바이더 두 쪽) |
| `probe-batch-close.luau` / `out-probe-batch-close.txt` | 공개 `getBlocker`로 연 배치를 공개 표면만으로 닫을 수 있는가 |
| `perf.luau` / `out-perf.txt` | 성능 모양 |

## 퍼저 결과

| 대상 | 시드 | 연산 | 차등 | 비고 |
|---|---|---|---|---|
| Bookkeeping | 20,000 | 65만 | 0 | 캐시 칸 대조 175만, State `:Set` 8.4만, 배치 2.9만, 예상 에러 7.6만(`0019`·`0020`·`0021`·`0022`·`0023`·`0024`·`0025`·`0229` 모두 모델이 먼저 말한 ID) |
| EpochMap | 20,000 | 80만 | 0 | 연산마다 맵 내용 전체 대조, GC 드롭 3.3만(약한 키 수거 확인) |
| Relate | 20,000 | 80만 | 0 | GC 드롭 4만(약한 값·약한 바깥 키), `Get`이 버킷을 만들지 않음 |
| ImplRegistry | 5,000 | 10만 | 0 | `__index`/`__newindex` 가진 모듈도 raw 저장 |
| 소유권 | 10,000 | 25만 | 0 | `0157`~`0163`·`0179` 전부 일치 |

Bookkeeping 시드 절반은 "구멍을 만들지 않는" 시드라 owner가 끝까지 안 얼고 모든 오프셋이 대조된다. 나머지 절반은 구멍·빠진 등록을
섞어 `Quad0023`/`0024`로 owner를 얼린다 — 언 owner는 문서가 UB로 둔 상태라 N과 동결 여부만 대조하고 오프셋 불일치는 세기만 했다
(`frozenStaleObs` 2,220 — 원인은 아래 (c)).

**검출력**(시드 2000): Bookkeeping `offBy1` 1842 시드 / `noFreeze` 511 / `nilSkip` 491 / `rangeMsg` 222 / `batchEager` 1053,
EpochMap `updEarly`·`peekWrites`·`trackCopies` 차등 28만·4.8만·2.2만 줄, Relate `sharedMap`·`setNilNoop`·`weakFallback` 2690·55·1224 줄,
ImplRegistry `freshEach` 전 연산, 소유권 `posIgnored` 1756 시드 / `releaseChecksNothing` 1952 / `disposeIgnoresHold` 1692.

## 발견

1. **[MED] State 길이의 초기값이 잘못이면 `Quad0021`은 나지만 부기는 이미 써졌고, 그 자리의 옵서버는 영영 없다.**
   `setLength(owner, i, State)`는 `lengthList[i]`와 `N`을 먼저 쓰고(`Bookkeeping.luau:348-349`) 그 다음 옵서버를 만든다(358-364).
   값 검사는 옵서버의 첫 실행 안(360)이라, 초기값이 -1이면 옵서버 생성자가 던지고 — 생성자 순서가 "fn 한 번 → 구독 합류"라
   (`Observer.luau:184-200`) 그 옵서버는 구독에 끼지 못한다. owner는 얼지 않는다(차단기 창 밖이라 — `H-445`가 노린 대로).
   그런데 결과는 조용한 오염이다: 축 (a)에서 자리 2에 `Source(-1)`을 넣고 던진 뒤, 다음 자리 등록의 재계산이 -1을 그대로 합산해
   오프셋이 `0,0,-1,0`이 되고, 그 State를 5나 2로 바꿔도(GC 전후 둘 다) 오프셋이 영영 안 움직인다(`observers[2] = nil`).
   문서 쪽 약속은 셋 — 레퍼런스 `docs/reference/extend/02-dispatch-handler-contract.md:250`("State 길이의 값 검사는 옵서버 안에서 —
   owner를 얼어붙게 만들지 않기 위해"), `dispatch-core-plan.md` 2469·2700행과 `Bookkeeping.luau:391`이 인용하는 `H-256` (a)
   "부기를 하나라도 만지기 전에 검사한다", 그리고 바로 옆 `setOffsetSource`의 레퍼런스 266행 "부기를 한 글자도 쓰기 전에".
   `spec.lengthoffset` 12절은 "등록된 뒤 `:Set(-4)`"만 단언하고 초기값 경우는 없다. 닿는 길은 공개 `q.Bookkeeping.setLength`에
   State를 넘기는 서드파티 핸들러뿐이다(내장 호출자는 `Slot/Tree.luau:72`의 `slot.Length`뿐이고 그 값은 늘 유효).
   갈래: (가) 등록 전에 `len:Get()`을 한 번 읽어 같은 검사를 하고 나서 쓴다 — 새 이름 없음, 다만 State를 한 번 더 읽는다(Compute면
   계산이 앞당겨짐); (나) 지금 동작을 UB로 레퍼런스에 적는다("초기값이 잘못이면 그 자리는 다시 등록할 때까지 추적되지 않는다");
   (다) 그대로. 사용자 결정 문항 후보.

2. **[MED] 공개 `q.Bookkeeping.getBlocker`로 연 배치를 공개 표면만으로는 제대로 닫을 수 없다.**
   레퍼런스 305행은 getBlocker를 "여러 자리를 한 번에 등록할 때 매 자리마다 전체 재계산이 도는 것을 막는 게이트"로 소개하고
   "`drive`가 … 마지막에 닫으면서 정확히 한 번 재계산"이라 적는다. drive의 닫기는 `OffWithoutEmit` 뒤 내부 `_recompute`
   (`Dispatch/init.luau:535-541`)인데 `_recompute`는 밑줄 비공개(`Bookkeeping.luau:423`)다. 핸들러 작성자가 `:On()` 한 뒤 앞 자리
   길이를 바꾸고 `:Off()`나 `:OffWithoutEmit()`로 닫으면 오프셋 Source가 옛 접두합 그대로 남는다(`probe-batch-close`: 참값 `0,5,7,9`,
   실제 `0,2,4,6`, 두 닫기 모두). 다음에 아무 자리나 `setLength`를 한 번 더 불러야 맞춰진다. 무엇이 막히나: 레퍼런스만 읽은 핸들러
   작성자는 배치를 직접 여는 게 안전하다고 읽는다. 갈래: (가) 레퍼런스에 "직접 열었다면 닫은 뒤 마지막 자리를 다시 `setLength`하라"
   같은 관용구를 적는다 — 새 이름 없음; (나) 닫기+재계산을 하는 공개 op를 둔다 — 새 이름이라 사용자 결정; (다) getBlocker는 "읽기·
   진단용, 여는 건 drive/Slot만"이라고 좁혀 적는다.

3. **[LOW] NaN이 부기·Relate·소유권 표면에서 `QuadNNNN` 없는 VM 에러로 죽는다.** `q.Relate():SetStrong(inst, 0/0, v)`·
   `SetWeak(0/0, …)`은 `Relate.luau:40`/`52`의 "table index is NaN", `q.Bookkeeping.getBlocker(0/0)`도 같은 줄(owner 게이트
   `checkOwner`가 nil만 본다, `Bookkeeping.luau:64-68`), `claimOwnerAt(0/0, inst, 1)`도 같다(`Slot/Owner.luau:40-49`는 nil만).
   반대로 `claimOwnerAt(e, inst, 0/0)`은 통과해 `OWNER_POS = NaN`을 기록하고, 같은 자리 재확인이 `NaN ~= NaN`이라 "정확히 같은
   자리면 false"(레퍼런스 327행) 대신 `Quad0160`을 낸다(`Owner.luau:50`). 읽기(`GetStrong(0/0, …)`)는 nil로 통과. 닿는 길은 공개
   표면을 직접 부르는 코드뿐이다(drive의 숫자 키는 NaN일 수 없다). E11의 Q94 보강(값 쪽 NaN)과 같은 계열 — 갈래는 Q94와 한 묶음으로
   (가) nil 게이트를 "nil 또는 NaN"으로 넓힌다 (나) UB로 적는다.

4. **[LOW] 한 요소를 한 owner의 두 자리에 `element`로 넘기면 앞 자리의 State 길이 변화가 캐시를 무효화하지 못한다.**
   `gatedRecompute`는 커서를 `indexOfElement[element]`로 내린다(`Bookkeeping.luau:320-322`) — 역맵은 마지막 등록 자리만 기억하므로
   자리 1의 길이 State가 바뀌어도 커서가 자리 3까지만 내려가 오프셋이 `0,1,2,3,4`로 남는다(참값 `0,10,11,12,13`, 축 (d)). 얼지도
   않는다. 내장 경로는 단일 마운트 게이트(`claimOwnerAt`)와 Slot의 reindex가 이걸 막으므로 계약 위반일 때만 난다. 문서 쪽은
   레퍼런스 246행이 `element`를 "나중에 자리를 되짚기 위한 역맵에 기록"이라고만 하고, "한 요소는 한 owner에서 한 자리"라는 전제와
   "자리가 옮겨지면 역맵 갱신은 호출자 몫"(`Bookkeeping.luau:351` 주석의 reindexFrom)이 공개 문서에 없다. 갈래: 레퍼런스에 전제
   한 줄 / 그대로.

5. **[LOW] `dispatch-core-plan.md` 1592행 "첫 인자(`inst`)는 물리 Instance일 필요가 없음 — 아무 테이블이나 키로 가능"이 실측과 다르다.**
   Slot이 아닌 평범한 테이블·문자열을 ownerKey로 주면 `getBookkeeping`의 `bindLifetime`(`Bookkeeping.luau:121`)에서 실 프로바이더는
   `Quad0226 bindLifetime: Instance is not claimed by quad`, mock은 ID 없는 "not a mock instance"로 거부된다(`probe-owner-kinds`).
   같은 문단의 `H-232` 각주가 "GC 앵커는 owner 타입으로 분기"라고 덧붙이긴 하지만 "그 밖의 타입은 거부"는 없고, 메시지도 인스턴스가
   아닌 값에 "Instance is not claimed"라 말한다. 공개 레퍼런스(242행 "요소이거나 Slot")는 맞다. 갈래: base 문장 정정 / 메시지에
   "ownerKey는 quad가 만든 Instance 또는 Slot"을 덧붙임(문구 변경 — Q90 계열).

## 확인만 한 것

- EpochMap: `Update`는 한 번 달라지면 나머지를 읽지 않고 쓰기만 해도 전부 쓴다(EM1), `Peek`는 안 쓴다(`H-72`), `Refresh` = 자기 키
  `Update`, `Sync` 반환 없음, `TrackFrom`은 상대의 저장값이 아니라 **라이브** 리비전을 복사하고 상대는 안 건드린다, 약한 키는 GC로 빠진다
  — 80만 연산 차등 0. Revision 0 강제 → `Set` 한 번에 4294967295(랩 감소, state-epoch-plan §2 표 그대로), 같은 리비전 재기록은 false,
  `EpochSet` 안의 비-Epoch(State)는 `Revision` nil이라 조용히 무시(내부 전용 경로), 빈 집합 false.
- Relate: Strong/Weak 독립, `Set(nil)`은 지움, 읽기는 버킷·서브맵을 만들지 않음, 약한 값은 다른 StrongMap이 붙잡지 않는 한 GC로 빠지고
  바깥 키도 빠짐, nil 인자 `Quad0138`(inst 먼저)/`Quad0139`는 **호출 줄** blame(`probe-blame`), `q.Relate`는 같은 생성자. `H-77` 모양
  (내부 키가 바깥 키를 되참조)은 여전히 50/50 샘 — 문서화된 대로.
- ImplRegistry: 모듈마다 테이블 하나·영구, `rawget`/`rawset`이라 `__index`·`__newindex`를 우회, `Quad.New()`는 frozen이 아님. frozen/nil/
  문자열 모듈에 대한 VM 에러는 비공개 모듈이라 사용자 경로 없음.
- Void: `q.Void`가 그 모듈 자체, 반환값 0개. 소스 전수 grep에서 새 `function() end` no-op은 `quad-roblox/src/LifetimeHandle.luau:49`의
  `nop` 하나뿐인데 그건 gcconn 캡처 트릭(의도된 별개 클로저)이다.
- Bookkeeping: 접두합(B1), 오류 ID와 두 문구 갈래(`0022` vs `0229`), `setOffsetSource`는 None이면 조회 없이 기록·Source면 조회가 먼저라
  실패 시 무기록(`H-392`), 등록 뒤 무효화는 두 커서 모두 `i`까지, 재계산 중 에러는 owner 동결(문서화된 UB), 배치 중 재계산 없음·닫을 때
  한 번, 교체된 State 길이의 옵서버는 즉시 끊김(`probe0` — GC 전후 둘 다 반응 없음), `Source:Set` 같은 값도 재계산(`H-68`), 캐시
  `offsetCache[1..offsetCacheValidUpTo]`는 언 owner 밖에서 175만 칸 전부 참 접두합. 등록된 State 길이를 -1로 `:Set`하면 `Quad0021`,
  owner 안 얼고 다음 유효 `:Set`에 회복(축 (b), spec 12절과 일치).
- 재진입 되감기(`H-240`): 오프셋 Source 구독자가 재계산 도중 앞 자리 길이를 바꾸는 세 변형 모두 최종 Source·오프셋이 참값(축 (e1)).
- 순환(오프셋 Source가 더 앞 자리의 길이 State이기도 함)은 재계산이 끝나지 않는다 — 구독자에 2000회 상한을 걸어야 멈췄고 상한 없이는
  20초 타임아웃(축 (e2)). `dispatch-core-plan.md` 432~437·1927행 "일반적인 재진입/무한루프는 방어 안 함" 범위라 발견으로 올리지 않음.
- 언 owner에서 오프셋이 낡는 원인(퍼저 `frozenStaleObs`): 동결을 부른 `Quad0023`이 State 길이 옵서버의 첫 실행 안에서 나면 그 옵서버도
  구독에 못 끼므로 이후 State 변화가 캐시를 무효화하지 않는다(축 (c)) — 동결 UB의 결과.
- 극단 위치: NaN·±inf `Quad0019`, 2^53·1e300은 정수로 통과해 `N`이 그 값이 되지만 첫 구멍에서 `0022`/`0023`으로 곧 끝난다(느려지지 않음).
- 소유권: nil 셋 순서, 같은 (inst, k) 재확인 false, 같은 inst 다른 k는 `Quad0160`, 해제는 k를 비교하지 않음(레퍼런스 222행 그대로),
  보유 중 `q.dispose` `Quad0179`·해제 뒤 통과 — 25만 연산 차등 0.
- 성능(`out-perf.txt`, mock CLI): 배치 등록 N=1000/2000/4000/8000 → 2.0/3.6/7.0/14.6ms(선형), 비배치 157/625/2486ms(제곱 — 문서가
  배치를 두는 이유 그대로, 2613행). 앞 자리 길이 변경 1회는 Source 자리면 N=1000→16000에서 0.51→8.6ms(선형), None 자리면
  0.11→1.8ms. **맨 끝 자리 변경도 선형**(0.30→4.87ms) — 재계산이 늘 1부터 돈다(`Bookkeeping.luau:237`); 2428행 "전체 순회의 O(N)
  비용은 무시 가능"이 이걸 받아들인 결정이라 발견 아님. Relate 쌍당 0.12~0.15µs(평탄), EpochMap `Update`/`Refresh`는 키 수에 선형.

## 미완

- Slot을 ownerKey로 하는 부기 경로(`ensureBase`의 `ownerKey.Offset` 베이스, 끝의 `Length:Set(sum)`)는 퍼저가 돌리지 않았다 — 물리 owner만.
- 재진입 되감기는 표본 셋(축 (e1))뿐이고 무작위 퍼즈가 아니다. 길이 State와 오프셋 Source가 서로 엮인 수렴하는 경우의 무작위 생성 없음.
- 한 오프셋 Source가 두 owner에 걸친 경우(옵서버 순서가 미정)는 모델에서 제외했다.
- 부기 퍼저는 mock 백엔드만 — 실 quad-roblox 프로바이더는 `probe-owner-kinds` 한 파일에서만 썼다. Studio 실기기 없음.
- 초기값이 잘못인 State 길이(발견 1)에서 Compute를 넘기는 경우(계산 앞당김 여부)는 재지 않았다.
