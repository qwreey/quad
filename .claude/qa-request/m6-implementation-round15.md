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
| `H6-5` | 🟢 | — | (슬라이스 3·4 관측) 정본 의사코드가 대부분 **수정 없이 조립됐다** — **무수정 확인**: attach 3형제(materialize/mount/attachSlot 재귀, Length=기여도 합, 언마운트 재귀+포탈), reconcile/settle(추가/갱신/재사용/제거/필터/dup-key error), wrap/unwrap, `:Single`+`Add(state)`, Detach 재사용, 상호배타 가드, **`:List` Slot 언마운트→재마운트 상태 보존+캐치업 1회(H-163)**. **정본 축약 이식(무수정 아님)**: `rawMove`는 정본에 의사코드가 없어 규약대로 짰고 H6-6를 냈다. **간접 검증만**: `rawReplace`/`rawDetach`는 spec 직접 단언 없이 reconcile 경유로만 밟힘 | 🟢 기록만 — slot-plan.md 정본 검증됨(mock 축, 위 갈래대로). 실기기·잔여 공개 CRUD·`KeyGone` 파괴 분기는 §4 밖 참고 |
| `H6-6` | ① | 🔴 | (슬라이스 4, advisor 지적으로 재현) `rawMove`가 `_elements`·`bk.indexOfElement`만 순열하고 **`bk.sourceList`/`lengthList`/`observers`를 안 옮겼다** — 정본 raw* 규약 1번("넷 다 같은 순열")을 어겨, 리오더 후 `recompute`가 **옛 점유자의 Offset Source에** offset을 쓴다(State 요소 리오더 시 자리가 어긋남). plain-element인 test 10은 sourceList가 전부 None이라 이 결함을 못 봄 | ✅ 반영 — 래퍼 Slot(=비-None sourceList) 리오더 테스트(spec 14)로 재현 확인 후, `rotateInPlace`(nil 구멍 있는 `observers`도 안전한 인덱스 대입 회전)로 세 배열을 `_elements`와 같은 순열로 이동 + 캐시 무효화 + recompute. `nativeMove` 미호출은 mock/Roblox no-op이라 무해(§4에 백엔드 주의로 기록) |

## §4 배치 문항 (회신 대기)

(없음 — 현재까지 열린 문항 0. 아래 "이 fork 슬라이스 밖"은 문항이 아니라
범위 표시다.)

## 이 fork 슬라이스 밖 (통합 시 메인/후속 몫)

- **공개 CRUD 잔여** — `Move`/`Swap`/`Extract`/`Splice`/`Replace`(+`collectLeaves`).
  `raw*` 절반(`rawReplace`/`rawMove`/`rawDetach`)은 `:List` reconcile용으로
  이미 구현됐고(`rawMove`는 spec 14로 직접 검증, 나머지 둘은 reconcile 경유
  간접), 공개 얇은 래퍼와 `collectLeaves`(중첩 Slot을 native*에 넘길 배열
  평탄화)만 남았다.
- **`nativeMove`/`nativeSwap` 백엔드 계약** — `rawMove`가 지금 물리 op을 아예
  안 부른다(mock/Roblox는 LayoutOrder 기반이라 no-op — 무해). offset을 실제
  물리 자리로 쓰는 백엔드(웹 DOM 등)에선 `collectLeaves`로 배열을 만들어
  `nativeMove`를 불러야 한다(정본 raw* 규약 5·6번). base 계약이라 통합 시 확인.
- **`KeyGone`의 파괴 분기** — Detach 재사용 경로는 검증했으나, 키가 사라진
  뒤 `nil` 반환(파괴)/`Detach`(계속 홀드)/error(새 값) 세 갈래 자체의 spec은
  안 썼다(reconcile 코드엔 있음).
- **실기기 검증** — Deferred 시그널 배달(`H-291`)이 `_detachCleanup`/leaf 사망
  타이밍에 주는 영향, userdata 동일성. mock은 동기라 이 축을 못 본다 —
  Studio는 메인이 독점하므로 통합 후.
- **quad-roblox `Handlers/Slot.luau`** — ROADMAP M6 마지막 체크박스가 base
  `Dispatch/Slot.luau`와 한 줄에 묶은 백엔드 절반. quad-roblox는 브리프 §2가
  쓰기 금지(메인이 단위 ③ 진행 중)라 base 절반만 했다.
- **round12 §6 `H-286` ②(unbind-relate)** — M6 몫으로 남아 있던 것. 이 fork는
  Slot 코어를 우선해 아직 안 봤다.
