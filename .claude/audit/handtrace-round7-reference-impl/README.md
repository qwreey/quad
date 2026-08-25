# 7라운드 손 트레이싱 — 참조 구현과 스파이크 (2026-08-25 실측)

**무엇인가**: `.claude/qa-request/pre-implementation-handtrace-round7.md`의
**4·5·6차 패스**가 발견을 재현하는 데 쓴 코드 전량. `audit/`의 다른 폴더와
같은 성격이고(계획이 아니라 **실측 결과 기록**), `type-recursion-issue/`처럼
**스크립트를 같이 두는 구성**이다 — 판정이 "문서대로 짠 것을 돌려본 결과"라
개별 파일을 직접 돌려야 재현된다.

**⚠️⚠️ 이 코드는 문서가 아니라 문서의 *전사물*이다.** `spikes/core.luau` ·
`spikes/dispatch.luau` · `spikes/chain.luau`는 `base/`의 확정 의사코드를
**손으로 옮긴 것**이고, 옮기는 과정에서 틀렸을 수 있다. 그래서 여기서 나온
발견을 검증할 때 **재실행은 검증이 아니다** — 재실행은 "전사물이 그렇게
동작한다"만 말해준다. **반드시 아래 "대조표"를 따라 원문 의사코드와 줄 단위로
대조할 것.** 대조에서 전사 오류가 나오면 그 발견은 quad의 결함이 아니라 이
폴더의 결함이다.

**환경**: `luau` / `luau-analyze`
(`~/.local/share/mise/installs/luau/latest`). 저장소 루트에서
`cd .claude/audit/handtrace-round7-reference-impl/spikes && luau <파일>`.
런타임 스파이크는 `luau`, `ty*`는 `luau-analyze`로 돌린다.

**실행 결과 스냅샷**: `RUN-runtime.txt`(런타임 18개), `RUN-typecheck.txt`
(타입 11개). 2026-08-25 실행분 그대로이고, 재실행이 이와 달라지면 그 자체가
조사 대상이다.

---

## 참조 구현 3개 — 원문 대조표

각 파일이 어느 절을 옮긴 것인지. **검증 패스는 이 표의 왼쪽(전사물)과
오른쪽(원문)을 대조해야 한다.**

| 파일 | 옮긴 대상 |
|---|---|
| `spikes/core.luau` | `base/state-epoch-plan.md` §2(`Epoch`/리비전 갱신) · §3(`EpochMap`의 `Update`/`Refresh`/`Sync`/`TrackFrom`) · §4(수신 규칙 1~3, 재계산 판정, 재계산 후 처리) · §5(emit 페이로드) / `base/source-state-plan.md`의 전파 모델과 `:With`/`:Compute` 노드 / `base/gate-plan.md` 4·8번(`withheld`, flush 시 스왑, 빈 배치 무통지, 게이트-게이트 unfold) / `base/blocker-plan.md`(`On`/`Off`/`OffWithoutEmit`/`IsOn`/`Policy`) / `ROADMAP.md` M2의 `H-23`(구독자 스냅샷) |
| `spikes/dispatch.luau` | `base/dispatch-core-plan.md`의 `Dispatch.getOffsetAt`(접두합 캐시) · `recompute` · `Dispatch.setLength` · `Dispatch.setOffsetSource` · 배치 게이팅(`getBlocker`) |
| `spikes/chain.luau` | `base/dispatch-core-plan.md`의 `Dispatch.process`(하강 diff (A)/(B) 분기) · `Dispatch.retractFrom` |

### 문서와 **의도적으로 다른** 곳 (전사 오류가 아님)

대조할 때 이 셋은 차이로 세지 말 것. 그 외의 모든 차이는 전사 오류 후보다.

1. **`core.luau`의 `EpochMap:PeekDiffers`** — 문서에 없는 연산이다.
   `GateNode`가 §4의 규칙 1~3을 돌려면 `emitEpochMap`을 **갱신하지 않고
   비교만** 해야 하는데 그 연산이 표면에 없다는 게 **`H-72` 그 자체**라,
   게이트를 돌려보려면 임시로 하나 둘 수밖에 없었다. 이 함수를 쓰는 자리마다
   주석으로 표시해뒀다.
2. **`dispatch.luau`의 `local box = { pos = i }`** — 확정 의사코드는
   `gatedRecompute`가 `i`를 직접 캡처한다. 여기선 `box.pos`를 읽는데,
   **`box.pos`를 아무도 안 고치면 동작이 완전히 동일**하고(초기값이 `i`),
   `d7_splice_fix.luau`가 A/B 대조를 하려고 그 필드를 고친다. 즉 기본 동작은
   문서 그대로고, 이 우회가 없으면 `H-102`의 대조군을 만들 수 없다.
3. **주입 op·`bindLifetime`/`canExecute`가 없다** — 순수 `luau`엔 엔진이
   없으므로 생명주기 게이팅을 뺐다(그 공백 자체가 `H-97`이다). 그래서 이
   전사물은 **"구독자가 살아있는가" 판정을 하지 않는다** — 그 판정이 결과를
   바꿀 수 있는 발견(`H-98` 등)은 그 점을 감안해 읽을 것.

---

## 스파이크 → 발견 대조표

**"기대"는 그 발견이 주장하는 결과**다. 재실행 결과가 이와 다르면 발견 쪽을
의심할 것.

### 4차 패스 — 반응형 코어와 예외 경로

| 파일 | 발견 | 무엇을 보여주는가 |
|---|---|---|
| `t1_diamond.luau` | (대조군) | 다이아몬드에서 Observer가 **1회**만 울고 섞인 값이 안 나온다 — 전사물이 §1의 glitch 해소를 재현한다는 증거 |
| `t8_reentrant.luau` | (대조군) | 전파 도중 동기 `:Set()` 재진입이 안전하다(`220,330`) |
| `t9_gate_chain.luau` | (대조군) | 게이트 2겹이 어느 순서로 풀려도 1회 발화·배치 2개 |
| `t5_recompute_race.luau` | `H-85` | 재계산 도중 도착한 무효화를 꼬리의 `rawInvalid = false`가 지운다(`2`가 영구히 남음) |
| `t5b_fix.luau` | `H-85` 갈래 (a) | `rawInvalid`를 `fn` 앞으로 옮기면 `198`로 고쳐진다 |
| `t4_throttle.luau` | `H-86` | 정책이 보류분을 못 읽으면 leading이 사라지고(`t=4.00`) 타이머가 안 끝난다. `localpending` 변형은 1-1절 그림과 일치 |
| `t7_poisoned.luau` | `H-87` | 배치 중 error → `Blocker`가 영구 On → 이후 `recompute` 0회 |
| `t2_error.luau` | `H-88` | 전파 중 error → 뒤 구독자 영구 침묵(값만 자가치유) |
| `t3_gate_error.luau` | `H-89` | flush 중 error → 배치 소멸, 재도착도 규칙 3으로 삼켜짐 / `Off()` 순회 중 error → 뒤 게이트가 안 풀림 |
| `t6_effect_gate.luau` | `H-90` | 공용 `EpochMap`이 루트로 접어 게이팅이 무력화(`막혀 있는데 이미 돌았다`) |
| `t10_subscribe_gc.luau` | `H-98` | 중간 State가 수거되면 `:Subscribe()`한 Observer가 살아있는 채로 영영 안 울린다 |

### 5차 패스 — 타입 (`luau-analyze`)

| 파일 | 발견 | 무엇을 보여주는가 |
|---|---|---|
| `ty1_apply_call.luau` / `ty1b.luau` | `H-94` | `__call` 테이블이 `(State<T>) -> U` 자리에 안 들어간다(제네릭·비제네릭 양쪽). 직접 호출은 통과 |
| `ty4_effect_ret.luau` | `H-95` | `Effect`의 `fn`이 아무것도 안 돌려주면 에러. 가변 반환 팩·유니온은 통과 |
| `ty5_updatefn.luau` / `ty6_multiret.luau` | `H-95` | 선언된 다중 반환보다 적게 반환하면 에러(값 하나만/`nil`만/없음 전부) |
| `ty7_fix.luau` | `H-95` 갈래 | 함수 타입 유니온이 네 모양을 다 받고 엉뚱한 반환은 여전히 잡는다 |
| `ty9_mixed_deps.luau` / `ty10_contrast.luau` | `H-96` | deps 0개는 무주석 통과, deps가 붙으면 무주석이 깨진다. dep 주석 시 `Source`/`State` 혼합도 정확히 좁혀진다 |
| `ty3_epoch_effectfn.luau` | `H-100` · (대조군) | `Source`가 `Epoch`를 구조적으로 만족한다(성립). `{[Source<T>]: true}`는 `{[Epoch]: true}` 자리에 안 들어간다 |
| `ty2_effect_deps.luau` | (대조군) | `State<any> | Ref<any>` 가변인자로 이형 deps가 표현된다(`Instance` 미정의 진단 1건은 Roblox 정의가 없어서 나는 것) |
| `ty8_gate_apply.luau` | (대조군) | `state:Gate(function(emit) return b:Policy(emit) end)`가 성립하고, `gate-plan.md`가 정정한 오답 `b.Policy`는 타입이 잡는다 |

### 6차 패스 — Length/Offset 부기와 error 계약

| 파일 | 발견 | 무엇을 보여주는가 |
|---|---|---|
| `d1_basic.luau` / `d2_slots.luau` | (대조군) | 접두합 캐시와 형제 offset 전파가 정확하다(0,1,2 / 1→4→1). 배치 게이팅으로 `recompute` 1회 |
| `d4_reentrant.luau` | `H-101` | `recompute` 재진입 → 꼬리가 `Length`를 낡은 합계로 덮어씀(2 vs 실제 3) |
| `d7_splice_fix.luau` | `H-102` | splice 후 캡처 인덱스가 낡아 뒤 형제 offset이 1로 남음. 위치를 재조정하면 5 |
| `d5_chain_error.luau` | `H-103` | `process`가 던지면 `NOOP` 슬롯이 남아 claim이 영구히 잠기고 명시적 철거로도 회수 안 됨 |
| `e1_errlevel.luau` | `H-104` | `error(msg)`와 `error(msg, 2)`가 가리키는 줄이 다르다 |
| `d9_hole2.luau` | `H-106` | 부기 구멍이 `C-6`의 메시지가 아니라 `getOffsetAt`의 익명 산술 에러로 먼저 터진다 |

---

## 여기 없는 것

- **1~3차 패스의 재현 코드는 없다.** 1차는 문서 대 문서라 코드가 없고,
  2·3차는 최소 재현을 그때그때 짜서 돌린 것이라 그 문서 본문에 인라인으로
  들어 있다(`H-71`의 `Relate` 누수, `H-77`, `H-73`~`H-76`, `H-78`~`H-83`).
  그쪽을 재검증하려면 그 항목 안의 코드 블록을 쓰면 된다.
- **`luau-test/`로 승격한 것은 없다.** 여기 있는 건 "설계가 이렇게 동작하는지"
  본 것이지 "M0/M2가 통과해야 할 스파이크"가 아니다. 발견이 확정 처리되면
  그중 일부가 `luau-test/`로 갈 수 있고, 그건 그때 판단할 일이다.
