# M6 병렬 탐사 구현 — 15라운드 발견 원장 (fork)

> **이 파일이 무엇인가**: **[2026-09-02 신설]** M6(Slot — mock 축) 병렬 탐사
> fork가 실제 코드를 옮기고 돌리다 나온 발견 전부. 규약은
> `m6-implementation-round15-brief.md`. 번호는 **`H6-1`부터**(접두로 메인
> `H-nnn`·M10 `H10-nnn`과 구분, ID 영구).
>
> **갈래 표기**(브리프 §2): **①** 자율 수정(코드+이 원장 같은 커밋) / **②**
> 사용자 결정 필요 — 원장에 문항+권고, 의존 작업 보류(`-- TODO(H6-n)` 마커),
> 막히면 이 fork 채팅에서 사용자 회신 대기 / **③** 대량 무효화 → 즉시 중단.
>
> **상태의 소스는 이 파일 자신** — 요약 표의 상태 열이 최신.

## 요약 표

| 번호 | 갈래 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|
| `H6-1` | ① | 🟡 | (슬라이스 2, `H-232` (a) 예고분) `Bookkeeping.getBookkeeping`이 Slot ownerKey를 못 다뤘다 — 무조건 `module.bindLifetime(ownerKey, bk)`를 부르는데 Slot은 claim 불가라 mock `isMockInstance` 가드(실물은 `H-290`)로 죽는다. 헤더가 "M6에서 `SlotBrand` 분기"라 예고해둔 몫 | ✅ 반영 — `getBookkeeping`이 `SlotBrand:is`면 `slot._bk`(강, lazy)를 쓰고 물리 inst만 weak Relate+bindLifetime. bk 테이블 리터럴은 `newBk()`로 추출 |
| `H6-2` | ① | 🟡 | (슬라이스 2) Slot이 `recompute`를 직접 부르는데(정본 materialize/rawRemove 꼬리) **Dispatch 공개 테이블이 `recompute`를 재노출 안 함** — 5개만(setLength/setOffsetSource/getOffsetAt/getBlocker/getBookkeeping). `H-277` 분리 때 recompute는 `module._bookkeeping`에만 남음 | ✅ 반영 — Bookkeeping 헤더가 *"Slot must reach [it] WITHOUT going through Dispatch, {Slot,Dispatch}→Bookkeeping"*라 명시한 그대로 **Slot이 `module._bookkeeping`을 직접 캡처**해 여섯 op(recompute 포함) 사용. Dispatch 표는 안 건드림(M3 무영향) |
| `H6-3` | ① | 🔴 | (슬라이스 2, GC 계약) `Slot_mt`를 파일 스코프에 두면 `Slot.Init(module)`이 매 인스턴스마다 그 테이블에 `module` 캡처 메소드를 재대입해 **마지막 quad 모듈을 전역으로 붙잡는다** — `spec.init` 2번(`H-181` New() 인스턴스 GC)이 즉시 깨졌다 | ✅ 반영 — `Slot_mt`를 `Init` 안으로 이동(인스턴스별 메타테이블). 반응형 모듈이 `Init` 안에서 임플을 만드는 `H-174` 패턴과 같은 이유 |
| `H6-4` | ① | 🟢 | (슬라이스 2 관측) **마운트 전 `Slot.Length`는 0이다** — `rawAdd`의 미실체화 얼리리턴이 부기·`recompute`를 안 타므로 `Slot{a,b}` 직후 `.Length:Get()`은 0, 마운트돼야 2가 된다. 정본의 "마운트된 요소 개수" 정의와 일관되나 CRUD-후-즉시-읽기 사용자에겐 놀라울 수 있음 | 🟢 기록만 — 결함 아님(설계대로), spec은 마운트 후로 단언. 문서화 후보 |

## §4 배치 문항 (회신 대기)

(없음 — 현재까지 열린 문항 0)
