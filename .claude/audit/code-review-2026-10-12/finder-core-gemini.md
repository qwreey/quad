# quad 코어 2026-10-12 변경 리뷰 보고서

> **작업 환경 및 검토 기준 준수 안내**
> - 본 보고서는 git worktree `/code/Projects/quad-agy/review-core` (브랜치 `agy/review-core`) 환경에서 작성되었습니다.
> - 검토 범위: `git diff 26932869..HEAD -- quad-base/src quad-roblox/src quad-types/src scripts` 및 관련 테스트 스펙.
> - 커밋: `911d8987` (Slot 가드 창 + `slot:WhenIdle`), `e955cbde` (Property 재확인), `e19f8066` (debug 구멍 검사), `8bae8bad` (릴리즈 도구), `1dd458f0` (`Apply` 타입).
> - 주장마다 근거(파일:줄 번호, 실행 명령 및 출력)를 명시하고 직접 실행 확인한 것은 **[실측]**, 코드 분석을 통한 추론은 **[추정]**으로 구분 표기했습니다.
> - 제시된 모든 개선안은 **제안**이며 최종 결정은 사용자에게 있습니다.

---

## 1. `settle`/`WhenIdle`의 구멍 분석

### 1-1. `_materializing` 플래그를 올리는 자리 vs `settle` 호출 진입점 대조표

| 구분 | 위치 (파일:행) | 연산 및 맥락 | 대응되는 `settle()` 호출 위치 |
| :--- | :--- | :--- | :--- |
| **플래그 올림 ①** | `quad-base/src/Slot/Raw.luau:118` | `raiseChain(slot)`: 슬롯 및 조상 체인 전체 `_materializing = true`<br>- `rawAdd:157` (Slot 마운트)<br>- `rawReplace:259` (미마운트 Slot)<br>- `rawReplace:281` (마운트 Slot) | - `Slot_mt.Add` (`init.luau:328`)<br>- `Slot_mt.Replace` (`init.luau:348`)<br>- `Slot_mt.Extract` (`init.luau:366`) |
| **플래그 올림 ②** | `quad-base/src/Slot/Raw.luau:164` | `rawAdd`: 일반 인스턴스 백엔드 삽입 (`nativeInsert`) 전후 가드 창 | `Slot_mt.Add` (`init.luau:328`) |
| **플래그 올림 ③** | `quad-base/src/Slot/Raw.luau:192` | `rawRemove`: 요소 파괴/제거 (`nativeRemove`, `destroySlotTree`, `nativeDispose`) 전후 가드 창 | `Slot_mt.Remove` (`init.luau:337`) |
| **플래그 올림 ④** | `quad-base/src/Slot/Raw.luau:209` | `rawUnmount`: 요소 언마운트 (`nativeExtract`, `leaveAsElement`) 전후 가드 창 | `Slot_mt.Extract` (`init.luau:366`) |
| **플래그 올림 ⑤** | `quad-base/src/Slot/Raw.luau:245` | `rawReplace` (미마운트): 옛 요소 파괴/정리 전후 가드 창 | `Slot_mt.Replace` (`init.luau:348`), `Slot_mt.Extract` (`init.luau:366`) |
| **플래그 올림 ⑥** | `quad-base/src/Slot/Raw.luau:271` | `rawReplace` (마운트): 요소 교체 백엔드 호출 전후 가드 창 | `Slot_mt.Replace` (`init.luau:348`), `Slot_mt.Extract` (`init.luau:366`) |
| **플래그 올림 ⑦** | `quad-base/src/Slot/Raw.luau:421` | `rawSplice`: 일괄 물리 삽입/추출 (`nativeExtract`, `nativeInsert`) 전후 가드 창 | - `Slot_mt.Splice` (`init.luau:387`)<br>- `Slot_mt.Clear` (`init.luau:453`)<br>- `Slot_mt.ExtractRange` (`init.luau:387`)<br>- `Slot_mt.ExtractAll` (`init.luau:465`) |
| **플래그 올림 ⑧** | `quad-base/src/Slot/Tree.luau:44` | `materializeSlotTree`: 마운트 워크 스택 보호 | `Handler.luau:44` (`internal.settleIdle()`) |
| **플래그 올림 ⑨** | `quad-base/src/Slot/Tree.luau:88` | `raiseTree(slot)`: 물리 삽입 직전 서브트리 Slot 전원 플래그 올림 | `mountSlotTree`를 호출한 상위 진입점 (`Handler.luau:44` 또는 각 CRUD 끝) |
| **플래그 올림 ⑩** | `quad-base/src/Slot/Tree.luau:178` | `destroySlotTree`: 슬롯 소멸 중 CRUD 차단 | `init.luau:558` (`disposeValue` / `dispose` 끝), 상위 `rawRemove`의 끝 |
| **진입점 끝 ⑪** | `quad-base/src/Slot/List.luau:263` | `:List` observer: 데이터 변경으로 인한 `reconcile` 완료 시점 | `if S.pending ~= nil then S.settle() end` |
| **진입점 끝 ⑫** | `quad-base/src/Slot/List.luau:332` | 마운트된 Slot에 `:List` 설치 (`_activateList`) 완료 시점 | `if S.pending ~= nil then S.settle() end` |

---

### 1-2. 대기 요청 누락·중복·순서 위반 경로 검토

1. **대기 요청이 실행되지 않고 남는 경로 (진입점 누락)** [추정]
   - 공개 CRUD 일곱(`Add`, `Remove`, `Replace`, `Extract`, `Splice`, `Clear`, `ExtractAll`), `:List` 설치 및 옵저버 reconcile, Roblox 디스패치 마운트(`Handler.luau`), `dispose`(`disposeValue`)의 11개 진입점 끝에 `settle()`이 정확히 배치되어 있습니다.
   - `Slot_mt.Move`와 `Slot_mt.Swap` (`init.luau:394-408`)에는 끝에 `settle()`이 없습니다. 그러나 [실측] `rawMove`와 `rawSwap`은 Roblox 백엔드에서 `nativeMove`/`nativeSwap`이 no-op이며 내부에서 `_materializing`을 전혀 올리지 않으므로, 이 안에서 Immediate 신호가 동기로 발생하거나 `WhenIdle` 요청이 큐에 들어갈 가능성이 없습니다.
   - **유의 경로**: `Slot/List.luau:245`의 `_detachCleanup` (Effect 클린업)에서 `host` 인스턴스 수명 종료에 따라 detached 슬롯의 `destroyElement` -> `destroySlotTree`가 불릴 때, 이 경로는 백엔드의 인스턴스 파괴 생명주기에서 구동되므로 quad의 진입점 끝(`settle`)을 거치지 않습니다. 다만 [실측](`leaf.Destroying` 시점 프로브) 인스턴스 엔진 소멸 시점에는 quad의 소멸 워크가 이미 끝나 있거나 unmount 논리가 선행되어 있어 `_materializing`이 `false`인 상태에서 `WhenIdle`이 등록되므로 대기 큐에 남지 않고 즉시 실행되었습니다.

2. **두 번 실행되는 경로** [실측 / 코드 검증]
   - `Slot/init.luau:297`에서 `table.remove(pending, i)`로 요청 항목을 큐에서 **완전히 제거한 후** `item.fn(slot)`을 호출합니다.
   - 따라서 `item.fn` 내부에서 추가적인 연산이 발생하여 내부 재진입 `settle()`이 돌더라도, 이미 꺼내진 항목은 큐에 존재하지 않으므로 동일 요청이 2회 실행되는 경로는 존재하지 않습니다.

3. **연산의 꼬리(`vacate`·`setLength`)가 끝나기 전에 실행되는 경로** [실측 / 코드 검증]
   - `settle()`은 `Raw.luau` 내부(플래그를 내리는 지점)에서 불리지 않고, `raw*` 함수가 완전히 반환되어 `vacate` 및 `setLength`가 종료된 `Slot_mt.*` 메소드의 **최외곽 출구**에서만 불립니다.
   - 따라서 `fn`이 실행될 때 슬롯의 배열 및 부기 상태는 이미 최신으로 정산 완료된 상태임이 보장됩니다.

4. **`settle()` 내부 루프의 커서 불변식과 재진입 상호작용** [추정]
   - `Slot/init.luau:293`의 `i += 1`은 아직 연산 중인(바깥 프레임의) 슬롯을 스킵하는 로직입니다. 주석에는 *"Everything left of `i` is a skipped, still-flagged request, so nothing runnable can end up behind the cursor"*라고 설명되어 있습니다.
   - 만약 `item.fn(slot)` 안에서 다른 슬롯을 `dispose`하여 앞서 스킵되었던 슬롯(`pending[1]`)이 파괴되거나 unflag될 경우, 그 내부 연산 끝에서 재진입 `settle()`이 호출되어 `i = 1`부터 다시 순회하면서 처리합니다.
   - 단, 재진입 `settle`이 앞선 항목들을 제거하면 리스트가 당겨지므로 바깥 `settle`의 `i` 인덱스가 비동기적으로 당겨진 리스트를 보게 됩니다. 이 경우 바깥 루프는 `#pending` 끝을 만나 자연스럽게 종료하므로 오류는 발생하지 않으나, 커서 공유가 단일 전역 리스트(`S.pending`)에 의존하고 있어 추론 복잡도가 높습니다.

---

## 2. 가드 창의 저장·복원 (`was` 패턴 및 중첩 순서)

### 2-1. `local was = self._materializing` 일곱 자리 및 복원 순서 검토

`Raw.luau`와 `Tree.luau`에서 `_materializing`을 올리고 복원하는 위치는 다음과 같습니다:
1. `Raw.luau:163` (`rawAdd` - 일반 인스턴스 `nativeInsert` 전후)
2. `Raw.luau:191` (`rawRemove` - 소멸/추출 전후)
3. `Raw.luau:208` (`rawUnmount` - 언마운트 전후)
4. `Raw.luau:243` (`rawReplace` - 미마운트 분기 소멸 전후)
5. `Raw.luau:271` (`rawReplace` - 마운트 분기 대체 전후)
6. `Raw.luau:420` (`rawSplice` - 물리 일괄 추출/삽입 전후)
7. `Tree.luau:44, 74` (`materializeSlotTree` - walk 시작/종료)

### 2-2. 특수 경로 상세 분석

1. **`rawReplace`의 세 출구** [실측 / 코드 검증]
   - **출구 1 (미마운트 분기, `Raw.luau:267`)**:
     - L256에서 `self._materializing = was`로 복원합니다.
     - 이후 새 원소가 Slot인 경우(`S.isSlot(newElement)`), L259에서 `raiseChain(self)`를 통해 체인을 올리고 `attachSlot` 수행 후 L261에서 `restoreChain(chainSlots, chainOlds)`로 복원한 뒤 반환합니다.
     - 플래그 복원이 누락 없이 정상 동작합니다.
   - **출구 2 (마운트 상태 + 새 원소가 Slot인 경우, `Raw.luau:284`)**:
     - L271에서 `self._materializing = true`로 설정된 상태에서 옛 원소를 제거/파괴합니다.
     - L279의 `if S.isSlot(newElement) then` 분기에서:
       **L280 `self._materializing = was`로 먼저 복원한 후**, L281 `raiseChain(self)`를 호출합니다.
     - [핵심 발견] 만약 L280에서 `was`로 내리지 않고 곧바로 `raiseChain(self)`를 호출했다면, `raiseChain`의 `olds[1]`에 `true`가 캡처되어 `restoreChain` 이후에도 플래그가 `true`로 영구 고착되는 버그가 발생했을 것입니다. 작성자가 이를 정확히 인식하고 `was`로 되돌린 뒤 체인을 올렸으므로 정상적으로 복원됩니다.
   - **출구 3 (마운트 상태 + 일반 원소 대체, `Raw.luau:292-294`)**:
     - L292에서 `self._materializing = was` 복원 후 `setLength`를 부르고 자연 반환합니다. 정상 동작합니다.

2. **`rawSplice` 안에서 부르는 `rawAdd` / `rawUnmount`** [실측 / 코드 검증]
   - `rawSplice` (`Raw.luau:390`)는 내부 루프 시작 시점에는 `_materializing`을 올리지 않습니다.
   - `rawUnmount(self, i, true)`와 `rawAdd(self, element, ..., true)`는 `deferPhysical = true`로 호출됩니다.
   - 일반 원소의 경우 `deferPhysical = true`이므로 `rawAdd`와 `rawUnmount` 내부의 물리 백엔드 호출(`nativeInsert`, `nativeExtract`) 구간에 진입하지 않으며, 따라서 내부에서 `_materializing`이 올라가지 않습니다.
   - Slot 원소의 경우 `rawAdd` 내부에서 `raiseChain`/`restoreChain`이 완결적으로 돌아 `self`의 원래 상태(`was`)를 유지합니다.
   - 이후 L420에서 물리 연산 일괄 처리 구간에서 비로소 `was = self._materializing; self._materializing = true; raiseTree; ... markMountedTree; self._materializing = was`로 감싸므로, 중첩 간섭 없이 올바르게 보호되고 복원됩니다.

3. **`destroySlotTree`의 두 갈래** [실측 / 코드 검증]
   - **갈래 1 (`slot._owned == false`, `Tree.luau:179-217`)**:
     - `OwnsElements = false` 슬롯은 소멸 요청 시 원소를 릴리즈하고 비워진 채로 살아남아 재사용됩니다.
     - 따라서 L216에서 반드시 `slot._materializing = false`로 플래그를 내려줍니다. (이 줄이 없으면 슬롯이 영구 동결됨).
   - **갈래 2 (`slot._owned ~= false`, `Tree.luau:219-247`)**:
     - L178에서 `slot._materializing = true`로 올라간 뒤, L246에서 `slot._destroyed = true`로 설정되고 `_materializing = false`를 별도로 호출하지 않습니다.
     - [실측 확인] `WhenIdle` (`init.luau:309`)과 `settle` (`init.luau:292`)의 조건문은 `slot._materializing and not slot._destroyed`입니다. 즉, `_destroyed == true`인 슬롯은 `_materializing` 값과 무관하게 한가한 것(idle)으로 처리됩니다. 또한 이후 CRUD 호출 시 `assertMutable` 내부의 `assertLive`가 `Quad0157`로 먼저 차단하므로 정상 동작에 부정적 영향이 없습니다.

4. **`:List` 재조정이 부르는 raw 연산** [실측 / 코드 검증]
   - `:List` 슬롯은 `_listed = true`이므로 공개 수동 CRUD가 `Quad0146`으로 원천 차단되어 있습니다.
   - `reconcile`이 부르는 `rawUnmount`, `rawDetach`, `rawReplace`, `rawAdd`, `rawMove`는 각각 독립적으로 가드 창을 열고 닫으며, 전체 reconcile 종료 시점(`List.luau:263`)에 `S.settle()`을 호출하여 대기된 `WhenIdle` 요청을 일괄 정산합니다.

---

## 3. Property 재확인 (`quad-roblox/src/Handlers/Property.luau`)

### 3-1. 물러나는 조건 (`tweenSlots:GetStrong(inst, k) ~= prev`)의 정상 경로 검토 [실측]
- `Property.luau:360, 373, 392` 세 곳에서 `inst[k] = ...` 쓰기 직후 `tweenSlots:GetStrong(inst, k) ~= prev`를 검사합니다.
- 정상 경로(재진입 없는 경로): `prev`는 핸들러 진입 시점(`L317`)에 strong 테이블인 `tweenSlots`에서 읽은 값입니다. 대입 직후에도 `tweenSlots`의 내용은 변경되지 않았으므로 조건식은 항상 `false`가 됩니다.
- `tweenSlots`는 weak 테이블이 아닌 strong 테이블이므로 GC로 인한 false positive가 발생하지 않습니다. 정상 경로가 오인되어 물러나는 경우는 없습니다.

### 3-2. retractor 반환값의 정합성 [실측 / 코드 검증]
- 재진입 감지 시 물러나는 세 지점 모두 `return tweenRetractor(inst, k)`를 반환합니다.
- `Property.luau`의 정상 반환 지점(L323, L335, L369, L383, L444) 역시 모두 `tweenRetractor(inst, k)`를 반환합니다.
- [실측] `tweenRetractor(inst, k)`는 해당 `(inst, k)` 쌍에 대해 캐시된 동일한 retractor 클로저를 반환하므로 핸들러 반환값 시그니처 및 동작 계약과 완전히 일치합니다.

### 3-3. Finish 스냅을 `settle` 앞으로 옮긴 영향 분석 [실측 / 추정]
- **콜백 순서에 주는 영향** [실측]:
  - 이전 코드: 바깥이 `settle(prev)`를 먼저 호출하여 연결을 끊고 `oldCb`를 로컬에 보관한 뒤 `Finish` 스냅을 대입했습니다. 이로 인해 스냅 쓰기에서 Immediate 신호 재진입이 발생하면, 안쪽 처리가 완료된 후 바깥으로 복귀하여 옛 트윈의 콜백을 다시 부르거나 트윈 두 개가 동시에 재생되는 결함(`H-895`)이 있었습니다.
  - 현재 코드: `inst[k] = prev.Value`를 먼저 쓰므로, 재진입 발생 시 안쪽 처리가 아직 settle되지 않은 `prev`를 직접 인계받아 정상적인 상태 전이와 콜백 순서를 수행하고, 바깥 처리는 즉시 물러나 콜백을 일체 발화하지 않습니다.
- **Dedup과의 상호작용 엣지 케이스** [추정 / 주의 발견]:
  - Finish 스냅 대입 시점에 `prev`는 아직 `settle`되지 않은 채 `tweenSlots`에 남아 있습니다.
  - 만약 Finish 스냅 쓰기로 인해 발화된 동기 리스너(예: `OnChange`)에서 **이전 트윈과 완전히 동일한 목표 값(`v.Value == prev.Value`)을 가진 새 Tween**을 넣는다면:
    1. 안쪽 `process`는 `prev.Value == v.Value`이므로 L319의 Dedup 로직(`if tweenIn and ... prev.Value == v.Value then return tweenRetractor(...)`)에 걸려 `tweenSlots`를 전혀 수정하지 않고 무동작 반환합니다.
    2. 바깥 `process`로 복귀했을 때, `tweenSlots:GetStrong(inst, k)`는 여전히 `prev`와 일치합니다!
    3. 따라서 바깥 `process`는 재진입이 있었다는 사실을 감지하지 못하고, 원래 진입했던 새 트윈을 그대로 재생(`Play`)하게 됩니다.
  - (평가: 안쪽의 동일 값 재요청이 Dedup으로 흡수되고 원래 목표였던 바깥 전이가 유지되는 것이므로 치명적 파괴는 아니나, "재진입 시 무조건 바깥이 포기한다"는 원칙과 비교할 때 Dedup이 개입하는 특수 엣지 케이스입니다.)

---

## 4. debug 구멍 검사 (`checkDataKeys`, Slot 생성자)

### 4-1. 키 개수 ≠ 가장 큰 키 (`count ~= highest`) 판정 검증 [실측]

`Slot/List.luau:38-48` (`checkDataKeys`) 및 `Slot/init.luau:496-513` (생성자)의 판정 알고리즘:
```luau
local count, highest = 0, 0
for k in pairs(items) do
    if notArrayKey(k) then S.Err.errorBefore(...) end
    count += 1
    if k > highest then highest = k end
end
if count ~= highest then -- hole check
```

- **수학적 무결성 검증**:
  - `notArrayKey(k)` (`type(k) ~= "number" or k % 1 ~= 0 or k < 1`)에 의해 0, 음수, 소수, 문자열 키는 사전에 `Quad0143` / `Quad0177`로 걸러집니다.
  - 따라서 루프를 통과하는 키 집합 $K$는 항상 양의 정수의 부분집합($K \subseteq \mathbb{N}^+$)입니다.
  - 양의 정수 집합에서 $|K| = \max(K)$가 성립할 필요충분조건은 $K = \{1, 2, \dots, \max(K)\}$입니다.
  - $1$부터 $\max(K)$ 사이에 단 하나의 nil이라도 존재하면 $|K| < \max(K)$가 되므로 `count ~= highest`는 참이 됩니다.
  - 반대로 nil 구멍이 전혀 없다면 $|K| = \max(K)$이므로 `count == highest`가 됩니다.
  - 빈 테이블(`{}`)의 경우 `count = 0, highest = 0`이므로 `count == highest`로 정상 통과합니다.

### 4-2. 실측 프로브 실행 결과 [실측]

`probe.review.luau`를 생성하여 다양한 테이블 형상에 대해 검증한 결과:
```bash
( ulimit -v 4000000; timeout 600 bash -c "./scripts/relink.sh && luau quad-base/test/probe.review.luau" )
```
출력 결과:
```
--- 1. table shape probe (q.debug = true) ---
Slot initial:	normal array	-> ok:	true	err:	none
Slot initial:	hole at 2	-> ok:	false	err:	Quad0270
Slot initial:	sparse hash	-> ok:	false	err:	Quad0270
Slot initial:	zero key	-> ok:	false	err:	Quad0177
Slot initial:	negative key	-> ok:	false	err:	Quad0177
Slot initial:	string key	-> ok:	false	err:	Quad0177
Slot initial:	float key	-> ok:	false	err:	Quad0177
Slot initial:	empty table	-> ok:	true	err:	none

--- :List data probe (mounted, q.debug = true) ---
:List data:	normal array	-> ok:	true	err:	none
:List data:	hole at 2	-> ok:	false	err:	Quad0269
:List data:	sparse hash	-> ok:	false	err:	Quad0269
:List data:	zero key	-> ok:	false	err:	Quad0143
:List data:	negative key	-> ok:	false	err:	Quad0143
:List data:	string key	-> ok:	false	err:	Quad0143
:List data:	float key	-> ok:	false	err:	Quad0143
:List data:	empty table	-> ok:	true	err:	none
```
- **결론**: **거짓 양성(False Positive)과 거짓 음성(False Negative)은 모두 존재하지 않습니다.** 양의 정수 키로 정제된 집합에 대한 `count ~= highest` 판정은 완벽히 성립합니다.
- **참고사항**: `while items[hole] ~= nil do hole += 1 end`는 첫 번째 nil 구멍만 찾아 보고하며, 구멍이 여러 개 있더라도 첫 번째 구멍 인덱스만 에러 문구에 포함됩니다 (사용자 안내 메시지 설계 의도에 부합).

---

## 5. 릴리즈 도구 (`scripts/check-version.py`·`publish.py`)

### 5-1. [중대 결함 실측] 4.0.0 릴리즈 시 lockstep 해제로 인한 패키지 누락 경로

커밋 `8bae8bad`의 사용자 결정:
> *"3.x는 다섯 패키지 모두의 안정화 구간 — quad_error·type_version_check도 4.0.0 전까지 quad와 같은 번호로 같이 올리고 ... bump 4.0.0에서 한 번에 올린 뒤 독립."*

코드 구현:
- `scripts/check-version.py:65, 71`:
  ```python
  def core_tuple(v):
      return tuple(int(x) for x in split_tail(v)[0].split('.'))

  def follows_lockstep(member):
      return core_tuple(manifest_version(read(f'{member}/pesde.toml'))) < INDEPENDENT_FROM  # (4, 0, 0)
  ```
- `scripts/publish.py:120-124`:
  ```python
  def rides_lockstep(member, root):
      text = open(os.path.join(root, member, 'pesde.toml'), encoding='utf-8').read()
      v = re.search(r'(?m)^version = "([^"]+)"$', text)
      core = (v.group(1) if v else '0.0.0').split('+', 1)[0].split('-', 1)[0]
      return tuple(int(x) for x in core.split('.')) < INDEPENDENT_FROM  # (4, 0, 0)
  ```

#### [실측 확인] 결함 재현
```bash
( ulimit -v 4000000; timeout 600 python3 -c '
from publish import rides_lockstep
print("v=3.2.0:", rides_lockstep("quad-error", "."))
core = "4.0.0".split("+", 1)[0].split("-", 1)[0]
print("v=4.0.0 < (4,0,0):", tuple(int(x) for x in core.split(".")) < (4, 0, 0))
core_rc = "4.0.0-rc.1".split("+", 1)[0].split("-", 1)[0]
print("v=4.0.0-rc.1 < (4,0,0):", tuple(int(x) for x in core_rc.split(".")) < (4, 0, 0))
' )
```
출력:
```
v=3.2.0: True
v=4.0.0 < (4,0,0): False
v=4.0.0-rc.1 < (4,0,0): False
```

#### 발생 시나리오 및 위험:
1. 사용자가 `python3 scripts/check-version.py bump 4.0.0`을 실행합니다.
   - `bump` 실행 시점에는 pesde.toml 버전이 3.x이므로 `riding`에 두 독립 패키지가 포함되어, 다섯 패키지의 버전이 모두 `4.0.0`으로 정상 bump됩니다.
2. 사용자가 지침대로 `mise exec -- pesde install`을 돌려 lock 파일들을 갱신합니다.
3. 이제 릴리즈를 위해 `python3 scripts/publish.py`를 실행합니다 (4.0.0 전까지 항상 하던 대로 `--with` 없이 실행).
4. `publish.py`의 `rides_lockstep`은 stage 트리의 `pesde.toml` 버전(`4.0.0`)을 읽습니다.
   - 판정식: `(4, 0, 0) < (4, 0, 0)` -> **`False`**!
5. `--with` 인자가 없으므로 `selected(m)`은 `False`가 됩니다.
6. 결과: `publish.py`는 `quad-error`와 `type-version-check`를 **게시하지 않고(누락) 성공 종료**합니다!
   - 출력: `quad_error 4.0.0 — 게시 안 함(이미 올라간 번호여야 한다 — 새 번호면 --with)`
7. **결과적 결함**: quad 4.0.0 릴리즈는 배포되었으나, quad 4.0.0이 의존하는 `quad_error 4.0.0`과 `type_version_check 4.0.0`은 레지스트리에 배포되지 않아 사용자의 설치가 실패합니다.
8. [추가 결함] 프리릴리즈(`4.0.0-rc.1`) 역시 `split('-')`에 의해 `core`가 `"4.0.0"`으로 평가되어 `< (4, 0, 0)`이 `False`가 되므로 프리릴리즈 단계에서도 누락됩니다.

### 5-2. lock 대조 게이트의 예외 및 검사 회피 경로 [실측 / 코드 검증]
- `check-version.py:144`:
  ```python
  if not os.path.exists(os.path.join(ROOT, lock)):
      continue  # a tree that was never installed ... has nothing to compare
  ```
  - 디스크에서 lock 파일이 삭제되었거나 누락된 경우, 에러 없이 `continue`하여 성공(exit 0)합니다.
- `check-version.py:115` (`collect()`):
  ```python
  for m in MANIFESTS + [f'{p}/pesde.toml' for p in INDEPENDENT if follows_lockstep(p)]:
  ```
  - 만약 아직 3.x 구간인데 작업자가 수동으로 `quad-error/pesde.toml`의 버전만 `4.1.0`으로 올려두고 `pesde install`을 했다면:
  - `follows_lockstep('quad-error')`가 `False`가 되어 `collect()` 목록에서 빠집니다.
  - 그 결과 `check-version.py`는 quad-base(`3.2.0`)와 quad-error(`4.1.0`)의 버전 불일치를 감지하지 못하고 **성공(exit 0)**합니다.

---

## 6. 틀 밖에서 (공유하는 가정과 대안 고찰)

### 6-1. 공유하는 가정 가운데 재검토할 지점

1. **가정: "엔진 호출 한가운데서 동기 리스너가 호출될 수 있고, pcall 없이 플래그만으로 거부해야 한다"**
   - Roblox의 기본 런타임 신호 모드는 **Deferred**입니다. Immediate 모드는 레거시 호환 모드입니다.
   - Deferred 모드에서는 부모 변경이나 인스턴스 파괴 신호가 엔진 호출 도중 동기로 불리지 않고 태스크 스케줄러 큐로 지연됩니다.
   - quad가 Immediate 신호 모드와 mock 환경을 철저히 방어하는 것은 훌륭한 안정성 추구이지만, "사용자 콜백을 pcall로 감싸지 않는다"는 원칙과 결합되면서 극단적인 비대칭(엔진 호출 안에서 예외가 발생하면 플래그가 영구 고착되어 해당 슬롯이 영구 불능 상태가 됨)을 낳았습니다.
   - 특히 `commit 911d8987`에 명시된 대로 Studio 실기기에서 Roblox 엔진이 이벤트 리스너 내부의 에러를 상위 호출 스택으로 전파하는지 여부는 검증되지 않은 가정이므로, 실기기 동작에 따라 영구 고착 위험이 현실화될 수 있습니다.

2. **가정: "거부된 CRUD를 미뤄주지 않고 사용자에게 `slot:WhenIdle(fn)`이라는 새 탈출구를 제공한다"**
   - quad는 인덱스 기반 API이므로 호출 시점의 인덱스가 지연 시점에는 틀어질 수 있어 내부 큐잉을 하지 않고 `WhenIdle`을 신설했습니다.
   - 그러나 이로 인해 devui `Overlay`와 같은 소비자 코드에서 컴포넌트 닫기/정리 로직을 `slot:WhenIdle`로 직접 감싸야 하는 추상화 누출(Leaky Abstraction)이 발생했습니다.

### 6-2. 더 단순한 구조로 같은 보장을 얻는 길 (제안)

> [!NOTE]
> 아래 항목들은 사용자의 의사결정을 돕기 위한 **제안**이며, 아키텍처 결정이 아닙니다.

1. **[제안 1: 릴리즈 도구 버그 수정] `rides_lockstep` 및 `follows_lockstep` 기준점 정정**
   - **문제**: 4.0.0 릴리즈 당일에 두 패키지가 publish에서 누락됨.
   - **대안**: 4.0.0 릴리즈까지는 lockstep으로 배포되어야 하므로, `rides_lockstep`의 비교를 `<= (4, 0, 0)`으로 변경하거나(4.0.0까지 포함), `old_version < (4, 0, 0)`을 기준으로 판정하도록 수정할 것을 제안합니다.

2. **[제안 2: 플래그 저장·복원 대신 정수 재진입 심도 카운터 검토]**
   - **현재 방식**: Slot마다 `local was = self._materializing; self._materializing = true; ... self._materializing = was`를 7곳에서 개별 관리.
   - **대안**: `self._materializingDepth = (self._materializingDepth or 0) + 1` 형태의 정수 카운터를 사용하면, `was`를 로컬에 보관하고 복원 순서를 정밀하게 맞추는 복잡성(`rawReplace`의 L280 사전 복원 등)을 줄이고 `self._materializingDepth > 0`으로 단순 판정할 수 있는지 검토를 제안합니다. (단, pcall이 없으므로 도중 throw 시 카운터가 남는 것은 현재 boolean 방식과 동일).

3. **[제안 3: `WhenIdle` 대기 큐의 모듈 전역 관리 단순화]**
   - 현재 단일 모듈 레벨 배열 `S.pending`에서 인덱스 `i`를 수동 조작하며 순회하는 방식은 재진입 시 커서 상태 추론이 매우 까다롭습니다.
   - 슬롯별 큐(`slot._pendingIdle`)를 두거나, 현재 프레임에서 실행할 항목들을 로컬 스냅샷으로 복사하여 비우고 순회하는 방식(Snapshot & Swap)을 취하면 커서 스킵 우려를 구조적으로 없앨 수 있습니다.

---

## 7. 결론 요약

1. **`settle`/`WhenIdle`**: 11개 진입점에 누락 없이 배치되어 있으며 연산 꼬리 이전 실행이나 중복 실행은 없습니다. 다만 `settle`의 단일 전역 리스트 커서 순회는 재진입 시 추론 복잡도가 높습니다.
2. **가드 창 저장·복원**: `rawReplace`의 3개 출구, `rawSplice`, `destroySlotTree`의 두 갈래 모두 의도된 대로 플래그가 정확히 복원되며 정상 경로에서 슬롯이 막히는 결함은 없습니다.
3. **Property 재확인**: 정상 경로 오탐이나 retractor 불일치는 없습니다. 다만 Finish 스냅 직후 재진입에서 이전 트윈과 동일한 목표 값의 트윈이 들어올 때 Dedup이 개입하는 특수 엣지 케이스가 존재합니다.
4. **debug 구멍 검사**: 키 집합이 양의 정수로 제한되어 있어 `count ~= highest` 판정은 거짓 양성 및 거짓 음성 없이 무결합니다.
5. **릴리즈 도구 (중대 발견)**: `publish.py`의 `rides_lockstep`이 `< (4, 0, 0)`으로 되어 있어, **`bump 4.0.0` 릴리즈 실행 시 `quad-error`와 `type-version-check`가 `--with` 없이는 게시되지 않고 누락되는 결함이 실측으로 확인**되었습니다. 릴리즈 전 수정이 필요합니다.
