# 10라운드 참고 구현 — `H-107`~`H-149` 계약으로 갱신한 스파이크 모음

**[2026-08-28 신설]** `audit/handtrace-round7-reference-impl/`(7라운드)와 9라운드
스크래치(`core9.luau`/`dispatch9.luau`, 지금은 여기 같이 둠)를 **커밋 `0ec22fb`
시점의 `base/`**(8·9라운드 반영 + `H-143`~`H-146`)로 옮긴 것.
발견 보고는 `qa-request/pre-implementation-handtrace-round10.md`(§5/§7이 이 폴더를
가리킨다). 이 README는 **무엇을 갱신했고 어디서 결과가 나왔는지**만 적는다 —
결정의 소스가 아니다.

실행: `cd spikes && luau <파일>.luau` (타입 스파이크 `ty*`는 `luau-analyze`).
`luau`는 `~/.local/share/mise/installs/luau/latest`(mise). 저장소 코드는 전혀
`require`하지 않는다 — 참고 구현은 `base/`의 의사코드를 손으로 옮긴 것이다.

## 폴더 구성

| 파일 | 무엇 |
|---|---|
| `spikes/core10.luau` | **반응형 코어 참고 구현(이번 라운드)** — 아래 "계약 갱신" 표 |
| `spikes/dispatch10.luau` | **디스패치 부기 + Slot 참고 구현(이번 라운드)** |
| `spikes/core.luau` / `dispatch.luau` / `chain.luau` | 7라운드 원본(그대로 복사, `cp -n`). `chain.luau`(하강 diff 체인)는 `d23`이 그대로 재사용 |
| `spikes/core9.luau` / `dispatch9.luau` | 9라운드 스크래치 원본(그대로) |
| `spikes/t14`~`t24`, `d20`~`d23`, `ty11` | **이번 라운드 신규** — 아래 결과 표 |
| `spikes/d10`/`d11`/`d13`/`d14` `_r10` | 9라운드 `H-124` 스파이크를 `sed`로 `dispatch10`/`core10`에 물린 사본 |
| 그 외 `t1`~`t13`, `d1`~`d18`, `g*`, `e1`, `ty1`~`ty10` | 7·9라운드 원본 그대로(옛 `core`/`dispatch`/`core9`를 `require`함 — 이번에 다시 돌리지 않았고 결과도 그쪽 README/파일이 소스) |

## 계약 갱신 — round7 `core.luau`/ref9 `core9.luau` 대비 `core10.luau`가 바꾼 것

| 항목 | 옛 참고 구현 | `core10.luau` (근거) |
|---|---|---|
| `EpochMap` | `Update`/`Refresh`/`Sync`/`TrackFrom` | + **`Peek`**(`GateNode:_receive`의 emit 판정, `H-124` 이전 7라운드 확정) |
| Observer `fn` | 2-인자 | **3-인자 `fn(targetState, self, emitFrom)`** + `observer._state` 강참조(`H-109`/`H-110`) |
| Observer 진입점 | `Subscribe`/`Unsubscribe` | 넷 — `WeakSubscribe`(프리미티브, `.Subscribed = true`, `H-111`)/`Subscribe`(위임 — `H-149` 그대로 재현하려고 **일부러** 안 고침)/`WeakUnsubscribe`(관대, `H-133`)/`Unsubscribe`(엄격) |
| `Ref` | `Callbacks` 배열 | 해시맵 셋 + **`WeakCallbacks`**(weak-키) + `Uncallback`, `:Set` 순서 값 → 리비전 → 콜백(스냅샷, 교차 dedup), 콜백 `k(value, self)`(`H-107`/`H-108`) |
| `Effect` 생성자 | dep마다 바인드 시 등록 | **생성자에서 한 번**, `_blocker:On()` … `OffWithoutEmit()`, dep 종류별 클로저 둘(`onRefFire(_, ref)` / `onStateFire(_, _, from)`), 공통 `fire`: `canExecute` → `_blocker:IsOn` → `_epochs:Update` → `Rerun`. `M.effectTrace` 훅으로 가드 판정을 기록할 수 있다(`t18`) |
| `_bindDestroying` | 없음/부분 | `_unbindDestroying()` 선행 → `onDestroying` 연결 → **`Refresh()` 먼저** → `not _installed or depsChanged → Rerun` |
| `Rerun` | 단순 | 루프 머리 `_consumeCleanup` → `fn` → 꼬리 `wasAlive and not canExecute` 즉시 소진 + `_pending` 드롭(`H-143`) |
| `Effect` 진입점 | 없음 | 네 개 + `resubscribeTail`(`H-144` (b)) |
| `GateNode` | `_receive` `Update`만 | `Update` + `Peek`, 배치 **unfold**해서 `_withheld`에, `_flush(commit) -> boolean`, 빈 배치 무시 |
| `Blocker` | 강한 핸들 목록 | weak 핸들 집합(`H-63`), 강한 주인은 `onUpstreamEmit` 클로저(`Policy(emit)`가 돌려준 핸들을 업밸류로) |
| `state:Block` | 별도 노드 | `Gate(self, function(emit) return blocker:Policy(emit) end)` |
| 생명주기 mock | `bindLifetime`만 | `isEffect(value)`면 `_bindDestroying(inst)`/`_unbindDestroying()`, `onDestroying(inst, fn) -> {Connected, Disconnect}`, `destroyInst`는 **Immediate** 모드(콜백 동기 실행 후 `conn.Connected = false`) |

`dispatch10.luau`가 `dispatch9.luau` 대비 바꾼 것: `bk.indexOfElement`를 **weak-키**로
(`H-145`), `recompute`의 되감기 판정을 `lengthList[i]` 읽기 **앞**으로(`H-124`,
`continue`), Slot 생성자에서 `Length`/`Offset`/`_baseObserver` 생성 + `_destroyed`
(9라운드 Q2), `materializeSlotTree` 순서(blocker On → `_baseObserver` bind →
`setOffsetSource`), `reconcile`의 `ownsGate` 배치(`H-136`), `mountTop`의 retractor가
`setLength(inst, k, 0)`을 **요소 없이** 부름(`H-145`의 해제 경로), `rawMove`는
`H-29` 규약(배열 permute, `N` 불변, `minPos - 1` 무효화, 이동 범위 `setLength`
재등록)을 탐사자가 옮긴 것(base에 의사코드 없음 — 검증 대상이 아니라 도구).

## 옮기며 고친 것 (참고 구현 자체의 오류 — 발견 번호 없음)

1. **`_recompute`의 첫 인자.** round7 `core.luau`/ref9 `core9.luau`는
   `fn(resultNode, cache, deps…)`처럼 **결과 노드**를 첫 인자로 넘겼다. base
   (`source-state-plan.md`)는 `fn(self, previous?, ...deps)`의 `self`가 **리시버의
   lazy 핸들**이다. 옛 스파이크들은 첫 인자를 안 써서 무해했으나, `t16`/`t17`처럼
   `fn` 안에서 `s:Get()`을 부르면 결과 노드 자신을 다시 계산해 **스택 오버플로**.
   `core10.luau`는 `self.fn(self._hold[1], self.cache, table.unpack(self._hold, 2))`.
2. **`elementOwner`의 값 모드.** 처음 옮긴 `dispatch10`은 값을 강하게 잡아
   weak-키 → 값 → 키 순환(Luau엔 ephemeron이 없다, `relate-plan.md`)으로 옛
   Slot이 GC되지 않았다(`d20` 첫 실행). `slot-plan.md`가 요소 소유권 절에서 전부 `SetWeak`이라 못박은 대로
   `__mode = "kv"`로 고쳤다.
3. **`isState`에 `GateNode` 포함.** `core10.luau`의 `isState`는 `Source`/`State`/
   `GateNode` 메타테이블을 직접 나열한다 — base엔 그 등록이 없다. 그게
   `H-152`다(`t24`가 빼면 어떻게 되는지 재현).
4. 브랜드는 `Brand` 대신 **메타테이블 identity**로 판별한다(스파이크 단순화) —
   `t24`는 이 단순화를 이용해 "브랜드 누락"을 흉내낸다.

## 결과 (2026-08-28, 전부 종료 코드 0)

| 스파이크 | 확인 대상 | 결과 → 발견 |
|---|---|---|
| `t14_effect_state_matrix` | 네 진입점 × 상태 전이표 | 문서 표와 일치 |
| `t15_rerun_dead_handle` | `H-147` 케이스 1·2·3 | 재현. 케이스 3만 `BindData` 죽은 gcconn으로 `wasAlive` 참 |
| `t16_gate_resub_refresh` | 게이트 × 재구독/재바인드 × `Refresh`/`Peek` 7건 | 1·2(캐치업 우회)·4(형제 dep) → `H-151`; 나머지 확정대로 |
| `t17_hold_gc` | `_hold` 불변식 | 양성/음성 확정대로 |
| `t18_blocker_vestigial_and_set_same` | `Effect._blocker` / 같은 값 `Set` | `drop:canExecute` 3, `drop:blocker` **0** → `H-150` |
| `t19_observer_level2` | `H-149` | `Subscribe`만 내부 줄 blame — 재현 |
| `t22_fn_destroys_inst` | `H-143` 동기 자기 파괴 | cleanup 즉시 1회 |
| `t23_store_reserved_runtime` | `Of("Of")`/`defaults.Of` × 구현 (I)/(II) | 둘 다 깨짐 → `H-153` |
| `t24_gate_brand_missing` | 브랜드 누락 | 발화 2 → 0, `Get` 정상 → `H-152` |
| `ty11_store_final`(analyze) | 최종형 Store 타입 + 빈 Store | 진단: 56행 예약 키(H), 43/45/46/52행 음성; 나머지 0 → `H-157` |
| `d10`/`d11`/`d13`/`d14` `_r10` | `H-124` | 통과 |
| `d20_indexOfElement_weak` | `H-145` | 키 수거 확인(테이블 키 한정 — `Instance`는 CLI 밖) |
| `d21_reconcile_batch` | `H-136` + 중첩 Slot | 사이클당 `recompute(L)` 1, 물리 op 최소 |
| `d22_detach_keygone` | `Detach`/`KeyGone` | 확정대로 |
| `d23_instancechild_spurious` | `InstanceChildHandler` 같은 값 | `Parent` nil→inst 2회, `recompute` 2 → `H-154` |

## 한계

- 물리 층은 전부 mock(`D.native` 로그) — Roblox `Instance`의 weak 키 거동,
  `SignalBehavior = Deferred`, `ChildAdded`류 이벤트 횟수는 여기서 볼 수 없다
  (발견 보고 §6).
- `Debounce`/`Throttle`은 옮기지 않았다(7절이 무효화 배너 아래라 확정 의사코드가
  없음). 게이트 정책은 `Blocker:Policy`까지만.
- `Dispatch.drive`/`New` 파이프라인(`H-139`)은 옮기지 않았다 — `d23`은 round7
  `chain.luau`의 체인만 쓴다.
