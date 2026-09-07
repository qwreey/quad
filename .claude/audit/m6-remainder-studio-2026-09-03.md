# M6 잔여 마감 — Studio 실기기 실측 (2026-09-03)

**무엇을**: `archive/v2-initial-implementation/m6-implementation-round15.md` "이 fork 슬라이스 밖" 절의
마지막 항목 — *"실기기 검증: Deferred 시그널 배달(`H-291`)이 `_detachCleanup`/
leaf 사망 타이밍에 주는 영향, userdata 동일성. mock은 동기라 이 축을 못 본다"*
— 와 같은 날 구현한 공개 CRUD 다섯의 실물 Instance 회귀.

**어떻게**: Edit 모드 `execute_luau`, rojo 라이브 싱크로 들어온 `quad-base`/
`quad-roblox`를 `ServerStorage.QuadTestRun`에 폴더째 클론해 `require(clone.src)`
(require 캐시 우회 관용구 — `audit/m5-unit5-first-render-2026-09-02.md`),
`Quad.New():UseProvider(require(qr.src).QuadRoblox)`. 루트는 `q.D.Frame { slot }`로
생성(quad 소유 — 실물에선 `Dispatch.drive(Instance.new(...), …)`가 *"Instance is
not claimed by quad"*로 막힌다, `H-290`/`H-293` 계약 그대로). 요소는 `Instance.new`
Frame(Slot foreign 갈래는 `question.md` 회신 대기 — 현행 허용).

## 결과

| 시나리오 | 단언 | 결과 |
|---|---|---|
| S1 마운트 | `Slot{a,b,c}` → 물리 자식 3, `Length` 3 | PASS |
| S1 `Move(3,1)` | `_elements` 순서·`IndexOf`, 물리 자식 수 불변(Roblox `nativeMove` no-op) | PASS |
| S1 `Swap(1,3)` | 양끝 교환, 가운데 고정(`nativeSwap` no-op) | PASS |
| S1 `Extract(2)` | 반환 = 그 요소, `Parent == nil`, 파괴 안 됨, `Length` 2 | PASS |
| S1 `Splice(1,1,x,y)` | 제거분 반환·생존, 순서 `x,y,c`, `Length`·물리 자식 3 | PASS |
| S1 `Replace(3, a)` | 옛 요소 **파괴**(Parent 대입이 잠김), 새 요소 마운트 | PASS |
| S1 중첩 `Add(inner{i1,i2})` + `Move(4,1)` | `Length` 5·물리 5, `inner.Offset` 0으로 따라옴 | PASS |
| S1 범위 에러 | `Move(0,1)` error | PASS |
| S2 `:List` Detach 홀드 | `Detach` 반환 → `Parent == nil`·생존·`slot._detached.x`에 보관 | PASS |
| **S2 owner `Destroy()` — Deferred 축** | `parent2:Destroy()` **직후(동기)**엔 홀드 요소가 아직 살아 있고(Destroying 배달이 지연됨), **다음 `execute_luau` 호출 시점**(deferred 큐 flush 뒤)엔 파괴돼 있고 `_detached`가 비어 있음 — `_detachCleanup` Effect의 leaf 사망 cleanup이 Deferred 배달에서도 발화 | PASS |

`list._destroyed`는 `nil`로 남는다 — Destroy 경로는 retract를 안 부른다는 확정
계약(`dispatch-core-plan.md`) 그대로이고, 홀드 요소 정리는 위 Effect가 담당하므로
Slot 자체의 파괴 플래그는 필요 없다(Slot은 쓰레기가 되어 GC).

**Deferred 관측의 뜻**: 동기 mock(`spec.slot` 12·20)은 Destroy 직후 바로 정리를
보지만, 실물에선 **한 틱 뒤**다. quad 쪽 계약("owner가 죽으면 `_detachCleanup`이
`_detached`를 전부 정리")은 지켜지고, 타이밍 차이는 `H-291`이 이미 문서화한
Deferred 일반론의 한 사례 — 새 발견 아님. userdata 동일성은 `H-293`/스파이크 `10`
(`audit/spike10-full-run-2026-09-01.md`)이 이미 실측했고 이번엔 `IndexOf`/`Get`
반환값의 `==` 비교가 전부 통과한 것으로 재확인.

최종 마커: 11/11 PASS, FAIL 0 — 11은 스크립트의 `check()` 단언 수(위 표의 S1
아홉 행 + S2 첫 두 행)이고, 마지막 행(Deferred 후속 호출 관측)은 단언이 아니라
두 번째 `execute_luau`의 출력 대조라 그 수에 안 들어간다. `SignalBehavior` 값 자체는 이 Studio 빌드에서
`Workspace` 멤버가 아니라 읽지 못했다(관측된 지연 자체가 Deferred의 증거).

## 잔여

- 없음 — 이걸로 round15 "이 fork 슬라이스 밖" 절의 여섯 항목이 전부 닫혔다
  (상태는 그 절이 소스).
- `ServerStorage.QuadTestRun`은 실측 산출물(다음 실측이 시작 때 지운다).

## 2. 회신 반영 재실측 (같은 날 — `H6-9` (b)·`H6-12` (b))

같은 관용구로 새 `Slot.luau`(싱크 확인: `markMountedTree` 존재) 재실행.

| 시나리오 | 단언 | 결과 |
|---|---|---|
| `Splice(2, 2, inner{i1,i2}, x)` on `[a,b,c,d]` | 제거분 `b,c` 생존·반환, 배치 `a,i1,i2,x,d` 5리프, `inner.Offset` 1, `inner._mounted` | PASS ×3 |
| State 요소 `Add(st)` → `Extract` → **재-`Add`** | 언래핑 반환 뒤 재-Add 성공(래퍼 소유권 반납) | PASS ×3 |
| `Remove(state요소)` → 다른 Slot에 그 Instance `Add` | 파괴 안 됨, 다른 곳에서 claim 성공 | PASS ×2 |
| 포탈(`Source(slot)`) 언마운트/재마운트 — 중첩 포함 | 서브트리당 한 op으로 떼고 붙임, `in3.Offset` 1 복원 | PASS ×3 |

11/11 PASS. 시행착오 하나: 첫 스크립트가 이미 마운트된 Slot을 포탈 루트에도
넣어 "already mounted elsewhere"가 났다 — 계약대로의 거부라 스크립트만 고침.
