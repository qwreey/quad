# E72 — Slot을 부기 ownerKey로 쓰는 경로의 중첩 트리 참조 모델 차등 퍼저 (2026-09-27)

E65가 물리 owner만 퍼즈하고 남긴 "Slot을 ownerKey로 하는 부기 경로"(`ensureBase`의 Slot `Offset` 베이스, `recompute` 끝의
`Length:Set(sum)`, `_baseObserver`의 두 커서 초기화, `H-240`/`H-350` 되감기)를 물리 호스트 아래 2~4단(무작위 생성은 최대 5단까지 도달)
Slot 트리로 퍼즈했다. 하네스는 E65 `env.luau`를 복사하되(설치본 하나 — `quad-roblox/luau_packages/quad_base`, typing-limits 8.34)
native op를 **순서를 지키는 오라클**로 덮었다(E19 아이디어: 삽입은 받은 offset에 엄격히, 제거는 블록을 찾아 다른 자리에 연속으로 있으면
"stale offset"으로 기록). 레포 파일 무변경, 판정은 전부 CLI mock 실행 결과(Roblox 엔진 미측정).
`./scripts/relink.sh` 뒤 레포 루트에서 `mise exec -- luau <파일> -a …`.

| 파일 | 내용 |
|---|---|
| `env.luau` | `Quad.New()` + mock 프로바이더 + 순서 오라클 native op + 최상위 문자열 자리용 `E72ProbeLeaf` 핸들러 |
| `rng.luau` | E65와 같은 결정적 xorshift |
| `fuzz.luau` | 트리 참조 모델 T1~T8(머리 주석이 문서 줄). `-a <seeds> <start> [mutant] [flags] [steps]`, flags `reent`(시드 1 자리 sink Slot + 감시 Slot `Offset` Observer가 스텝당 한 번 sink에 잎 추가)·`trace` |
| `out-fuzz-plain-1-20000.txt` | 기본 2만 시드 × 30스텝 |
| `out-fuzz-reent-1-20000.txt` | 재진입 2만 시드 × 30스텝 |
| `out-fuzz-long80-50001-55000.txt` / `out-fuzz-reent-long80-60001-65000.txt` | 80스텝 5천 시드 둘 |
| `out-mutants.txt` | 모델 변이 여섯의 검출 |
| `probe0.luau` / `probe1.luau` (+`out-`) | 하네스 스모크, 모델 가정 넷(좌석에 쥔 Slot `0160`, 언마운트 중 data Set 따라잡기, Detach된 중첩 Slot CRUD 뒤 재부착, 언마운트 동결) |
| `probe-q75.luau` / `out-probe-q75.txt` | 발견 1·2·3 최소 재현 |
| `axes.luau` / `out-axes.txt` | 표적 축 `cyc`(Length 되먹임)·`det`(Detach 중 관찰자)·`q52`(updateFn 조상 CRUD)·`own`(Slot owner 공개 부기 op) |
| `perf.luau` / `out-perf.txt`, `perf-width.luau` / `out-perf-width.txt` | 깊이·폭·잎 수에 대한 비용 모양 |
| `probe-leak.luau` / `out-probe-leak.txt` | 하네스 위생: 파괴 안 한 mock 호스트가 Slot을 쥔 quad 인스턴스를 붙잡는지 |

## 퍼저 결과

| 실행 | 시드 | 스텝 | 논리 차등 | 비고 |
|---|---|---|---|---|
| 기본 | 20,000 | 60만 | **0** | 생성 4.4만·Detach 8.6천·재부착 9백·따라잡기 1.6천·좌석 교체 3.3만·dispose 1만·GC 1.2만·최대 깊이 5 |
| 재진입(`reent`) | 20,000 | 60만 | **0** | 재진입 발화 2.6만 — 물리 순서만 48스텝 어긋남(발견 1), 좌석 교체 순간 발화 173(발견 3) |
| 기본 80스텝 | 5,000 | 40만 | 0 | |
| 재진입 80스텝 | 5,000 | 40만 | 0 | 물리 순서 20스텝(발견 1) |

매 스텝 대조: 호스트 아래 물리 순서(오라클) + mock `GetChildren` 수, 살아 있는 모든 Slot의 `Length:Get()`/`Offset:Get()`(마운트면 참값,
언마운트면 마지막 마운트 값 — core/06 104), `Get(i)` 전부와 `Get(n+1) == nil`, Slot `_destroyed`, 잎의 `isDestroyed`·`isClaimed`·`Parent`,
`:List` updateFn의 원소 생성 횟수·순서, 정의된 에러 ID. 예상 에러는 전부 모델이 먼저 말한 ID로 났다(기본 실행 기준 `0140` 3천·`0160` 6천·
`0165` 3.4천·`0166` 4.5천·`0168` 2.2천·`0170` 6.9천·`0172` 6.7천·`0173` 3.6천·`0179` 9.5천·`0236` 6.4천·`0241` 5.5천·`0242` 1.1천), 에러 뒤 상태 무변경.

**검출력**(시드 2000): `unmountZero`(언마운트 값을 0으로) 1406시드 / `detachCounts`(보관분을 길이에 셈) 272 / `leafSeatFree`(최상위 잎 자리를
오프셋에서 뺌) 697 / `noCatchUp`(언마운트 중 data Set을 재마운트에서 무시) 109 / `cycleAs0172` 303 / `extractDestroys` 1626.

모델 정정 둘은 전부 모델 쪽이었다: (1) 재마운트 따라잡기는 **깊은 `:List`부터** 돈다 — 재마운트가 옛 원소를 먼저 materialize하면서 그 안의
`:List`가 활성화·따라잡기를 끝내고, 바깥 `:List`는 자기 Observer가 다시 묶일 때 따라잡는다; (2) 따라잡기에서 빠지는 원소는 잠깐 다시 붙었다가
떨어지므로 그 Slot의 동결 값은 "직전 스텝의 마운트 값"이 아니라 그 순간 값이다(아래 확인만 첫 항목).

## 발견

1. **[LOW — Q75 보강, 지금 백엔드에서는 무해] `Splice`의 물리 op base는 변경 전에 한 번 잡히는데, 그 사이 attach 창에서 사용자 Observer가 앞쪽을
   바꾸면 새 잎이 옛 위치에 들어간다.** `rawSplice`는 `base = getOffsetAt(self, index)`를 변경 전에 읽고(`Slot/Raw.luau:356`) 끝에
   `nativeExtract`/`nativeInsert`를 그 값으로 부른다(375·377). 새 원소가 Slot이면 그 사이 `attachSlot` → `setOffsetSource`가 그 Slot의
   `Offset:Set`을 부르고, 거기 걸린 사용자 Observer가 앞쪽 형제를 키우면(재진입 퍼저의 sink `Add`) base가 낡는다. 최소 재현(`probe-q75` B):
   `sink, T{t1,t2}` 마운트, 미마운트 Slot `N{n1}`의 `Offset` Observer가 `sink:Add`, `T:Splice(2, 1, N)` → 물리 `sink,n1,t1`(기대 `sink,t1,n1`),
   논리 `Length`/`Offset`은 맞음. 같은 모양을 `T:Add(N, 2)`로 하면 맞다(Add는 `getOffsetAt`을 그 자리에서 다시 읽음). 퍼저: 재진입 2만 시드에서
   48스텝(Splice 대부분, ListSet 하나), 80스텝 5천 시드에서 20스텝 — 어긋난 순서는 이후 스텝에서도 복구되지 않는다(오라클 재동기화 전까지).
   정본은 `slot-plan.md` 87행 "`offset`은 전부 0-based 절대 offset(`getOffsetAt`이 주는 그 값)". mock·Roblox는 offset을 무시하므로 관측 불가.
   Q75 (c)("재진입 Observer 안 CRUD가 파동 도중 오프셋으로 native op")의 한 입구로, 갈래는 Q75와 같다.

2. **[LOW — Q75 보강, 지금 백엔드에서는 무해] `mountSlotTree`의 삽입 위치 `slot.Offset:Get()`이 `drive` 배치 안에서 낡는다.** `drive`가 배치를
   켠 동안 앞 자리가 커지면(예: 앞 좌석 `:List`의 data가 뒤 좌석 Slot `Offset`의 Compute) 호스트 재계산이 배치 끝까지 밀려, 뒤 좌석 Slot의
   `nativeInsert(physicalTarget, slot.Offset:Get(), …)`(`Slot/Tree.luau:89`)가 옛 오프셋을 쓴다. 최소 재현(`probe-q75` A, 수렴하는 되먹임
   `n = min(Offset+1, 3)`): 물리 `k1,s2,k3,k2`(기대 `k1,k2,k3,s2`), 논리 `L.Length 3`·`S2.Offset 3`은 맞음, 오라클에 stale 제거 기록도 없다(삽입
   쪽이라 순서 비교로만 보임). Q75 (a)는 `unmountSlotTree`의 같은 읽기, E5 보강은 `firePostRefs` 경로 — 이것은 마운트 쪽 짝이다. 갈래는 Q75와 같다.

3. **[LOW — 문서 미정] 최상위 `State<Slot>` 좌석 교체는 뒤 형제의 `Offset`을 길이가 같아도 두 번 발행한다(a→b→a).** SlotHandler retractor가
   옛 Slot을 떼고 `setEmpty`로 자리를 0으로 등록해 재계산을 한 번 돌린 뒤(`Slot/Handler.luau:47-48`), 새 Slot의 `process`가 다시 올린다.
   재현(`probe-q75` C): 길이 2 ↔ 2 교체에서 뒤 좌석 `tail.Offset` 알림 `0,2`(최종 2), 같은 모양의 수동 `Replace`는 알림 0. 재진입 퍼저에서 173스텝
   (좌석 교체만). 무엇이 막히나: `Offset`으로 `LayoutOrder`를 매기는 Observer가 교체마다 한 번 헛돌고, 그 사이 값으로 사용자 코드가 돈다(E19의
   "순간 발화 0"은 수동 CRUD 기준이라 이 경로는 밖). core/06 132행은 `Offset`이 "형제가 앞에서 길이를 바꾸면 따라 움직인다"고만 적는다.
   갈래: (가) core/06 `Offset` 절에 "숫자 키 State 교체는 철거→처리 두 단계라 뒤 형제 `Offset`이 잠깐 앞으로 당겨졌다 돌아올 수 있다" 한 줄;
   (나) 그대로. 동작을 바꾸려면 retractor↔process 사이 배치(새 메커니즘)가 필요해 권고 대상 아님.

## 확인만 한 것

- **재마운트 따라잡기의 순서**(E19 관찰의 `:List` 판): 언마운트 중 data가 바뀐 `:List`를 다시 붙이면 옛 원소 서브트리가 먼저 materialize되고
  (안의 `:List`는 그 walk 안에서 활성화·따라잡기 — 원소를 **새로 만들기도** 한다), 그 뒤 바깥 `:List`가 따라잡으며 사라진 키의 원소를 떼거나
  파괴한다. 떼인 원소의 `Length`/`Offset`은 그 짧은 재마운트의 값에 멈춘다(퍼저 `catchUpTransient` 135/2만 시드). core/06 104의 "마지막 마운트
  값"을 문자 그대로 읽으면 이 짧은 재마운트도 마운트이므로 모순은 아니다. 떼인 쪽의 제거는 stale offset으로 들어온다(기본 실행 `ListSet/extract`
  687스텝 — Q75 (a) 그대로, 최종 순서는 맞음).
- **Q52 게이트**(`axes q52`): 첫 마운트(`drive`, 깊이 1·3, 직접 부모·루트) 중 `:List` updateFn의 조상 CRUD는 `Quad0167`로 거부되고 blame은
  updateFn 안의 사용자 줄, 이후 `_materializing = false`·부기 정상·그 조상 CRUD 가능. 런타임 `Add`의 attach 창에서 직접 부모도 `Quad0167`
  (조부모는 Q74). 마운트 walk 밖(이후 data `:Set` 재조정)의 조상 CRUD는 게이트가 없고(설계대로) 이번 표본(깊이 3 루트·부모)에선 물리·Length 모두
  정확 — core/06 380은 이것도 "하면 안 됩니다"로 둔다.
- **Length 되먹임 순환**(`axes cyc`): 수렴하는 되먹임(앞 좌석 `:List` data = 뒤 좌석 `Offset`의 함수, 또는 `P{ L }`에서 L data = `P.Length`의
  함수)은 고정점에 도달(논리 정확, 물리 순서는 발견 2). 발산하는 되먹임은 가드 없이 `LifetimeHandle.luau:118: stack overflow`(ID 없는 RAW,
  1177회·730ms)로 끝나고 그 Slot은 `_materializing`이 켜진 채 남아 이후 CRUD가 `Quad0167`("or an earlier mount into this Slot threw mid-way")로
  막힌다. `Quad0184`는 걸리지 않는다(Compute 자기 읽기가 아니라 Slot 부기를 거친 순환). 정본의 "일반적인 무한루프 방어 안 함"
  (`dispatch-core-plan.md` 432행, `slot-plan.md` "재진입성" 절 — `recompute` 재진입 UB) 범위라 발견으로 올리지 않는다. 사용자 문서 core/06엔
  이 되먹임 문장이 없다(core/03 77의 순환 문장은 Compute 자기 읽기만 다룸).
- **Detach 중 관찰자**(`axes det`): `:List` 원소인 수동 Slot을 숨기면(Detach) 부모 길이 옵서버가 풀리고, 보관 중 `Add`/`Remove`해도 그 Slot의
  `Length`/`Offset`과 사용자 Observer는 조용함(동결), 바깥 `Length`도 불변, 형제 재정렬도 보관분 `Offset`을 안 움직임; 보관 중 다른 곳 `Add`
  `Quad0172`·`dispose` `Quad0179`; 다시 보이면 CRUD 결과가 반영되고 알림은 값당 한 번. 원소가 `:List` Slot이면 보관 중 data `:Set`이 재부착 때
  따라잡힌다(KeyGone→Detach→키 복귀 경로 포함, 최종 정확·제거 쪽 stale 1건은 Q75 (a)).
- **Slot owner 공개 부기 op**(`axes own`): 마운트된 Slot `S`의 `getOffsetAt(S, i)`는 `S.Offset`부터 센 절대값, N+1까지 허용·그 뒤 `Quad0022`;
  언마운트(철거)된 Slot은 `getOffsetAt(T, 1)` = 동결된 `Offset`, 2부터 `Quad0022`(부기가 비워짐 — 원소가 있어도), 한 번도 안 붙은 Slot은 0.
  서드파티가 마운트된 Slot owner에 `setOffsetSource` 없이 `setLength`를 부르면 `Quad0023`이 재계산 창 안에서 나 그 Slot이 얼어붙는다(이후
  `Add`의 `Length` 불변) — 핸들러 계약 위반(메시지가 그 가능성을 적음), 내장 경로에 없음.
- **성능**(mock CLI, `out-perf*.txt`): 깊이 D 사슬(층당 잎 2)에서 맨 앞 좌석 삽입 = D개 `Offset` 알림, 가장 깊은 곳 삽입 = D개 `Length` 알림, 시간
  D=2→128에서 15→344µs·10→256µs(선형), 레벨 2 서브트리 Extract+재Add 26→1338µs(선형). 스택: D=800까지 마운트·가장 깊은 삽입 모두 성공
  (8ms/1.6ms). 가장 깊은 Slot 잎 수 N=100→3200에서 가장 깊은 삽입 57→1164µs(선형 — 재계산이 늘 1부터, E65 확인과 같음). 폭(W 사슬 × D=6):
  맨 앞 삽입이 W·D개 `Offset`을 옮기며 Slot당 약 2~5µs로 W=2048(Slot 12,288)까지 평탄(오라클 없는 mock에서 60ms). 이차 모양 없음.
- **하네스 위생**: 파괴하지 않은 mock 호스트가 마운트된 Slot을 쥐고 있으면 quad 인스턴스 전체가 수거되지 않는다(인스턴스당 약 50KB,
  `probe-leak` — 빈 Slot 하나로도 같음, 호스트 `Destroy` 뒤엔 수거). 부모 nil + 연결이 남은 Roblox 인스턴스의 알려진 모양을 mock이 그대로
  흉내낸 것이라 결함으로 보지 않는다 — 첫 실행에서 퍼저가 한 프로세스 안에서 초선형으로 느려진 원인이었고, 시드 끝 `host:Destroy()`로 고쳤다.

## 미완

- `OwnsElements = false` `:List`, `:Single`, State 원소(래퍼 Slot)는 이 퍼저의 생성기에 없다(E19·Q76b가 다룬 영역) — 트리의 Slot 종류는 수동과
  소유 `:List`(원소는 잎 또는 수동 Slot 하나짜리) 둘뿐.
- `:List` 중첩은 생성기상 "`:List` 원소 = 수동 Slot"까지이고 `:List` 안의 `:List`는 표적 축(`det2`)에서만 봤다.
- 재진입은 "감시 Slot의 `Offset` Observer가 맨 앞 sink에 잎 하나 추가" 한 모양뿐 — 조상·형제 CRUD, `Length` Observer 재진입, 한 스텝 여러 번 발화는
  무작위로 생성하지 않았다. 발견 1의 순서 어긋남은 오라클을 모델 기대값으로 재동기화한 뒤 이어 대조했다(그 스텝의 논리 대조는 유지).
- 한 호스트뿐 — 호스트 사이 이동, 호스트 `Destroy`·`dispose` 파동 중의 중첩 Slot은 없음(E50 영역).
- 순간 발화(a→b→a)는 재진입 모드의 감시 Slot 하나에서만 셌다 — 기본 모드의 알림 수 대조는 없다(E19가 수동 CRUD에서 함).
- 발산 되먹임의 첫 좌석 변형(`cyc1 diverge`)은 가드(200회)를 걸고만 돌렸다 — 가드 없는 끝(스택 오버플로 위치)은 `cyc2`에서만 측정.
- 실 quad-roblox 프로바이더·Studio 없음.
