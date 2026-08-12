# 2026-08-12 열세 번째 세션 — `Slot`의 두-`Relate` 상호 GC 순환 수정

## 배경

직전 세션(열두 번째, `slot→inst` 소유권 relate 신설)에서 사용자가
자신이 방금 확인한 설계에 GC 위험을 지적: `slotOwner`(slot→inst)와
`kSlotMap`(inst→slot)이 둘 다 `SetStrong`이면 서로가 서로를 살려주는
순환이 생겨 GC가 안 됨. `attachSlot`에서 slot을 `gchold`(=`bindLifetime`)에
넣는 부분이 필요한데 적용이 안 됐다고 지적, 다른 곳에도 같은 패턴이
있는지 감사 요청, 마지막엔 slot을 `SetWeak`로 두라는 결론.

## 진단 — 위험도가 다른 두 패턴 구분

`bindLifetime`이 이미 광범위하게 쓰는 "값이 자기 키를 다시 참조"
패턴(`Dispatch.setLength`의 `observer` 클로저가 `inst`를 캡처, `Ref.Value
=inst`)은 **단일 테이블 자기참조** — 그 테이블의 키(`inst`)가 테이블
바깥에서 독립적으로 reachable한지만 판별하면 되므로 표준 weak-key GC로
안전하게 풀림(둘 다 외부 참조 없이 죽으면 함께 정리됨, 순환이 이
판별을 방해 안 함).

반면 `kSlotMap`(inst 키, slot 값, 강)과 `slotOwner`(slot 키, inst 값,
강)는 **서로 다른 두 `Relate`가 서로의 키를 상대방 값으로 제공하는
상호 순환** — `inst`의 reachability 판별이 `slot`의 reachability에
의존하고, 그 반대도 마찬가지라 판별 자체가 서로에게 순환 의존함. 이건
Lua 5.2+가 ephemeron을 도입해서 풀려던 바로 그 사례라 표준 weak-key
GC(특히 ephemeron 미지원 구현)로 한 번에 안 풀릴 위험이 있음 — Luau의
실제 동작이 검증된 바 없으니 설계로 아예 피함.

## 전체 corpus 감사

`grep -n "Relate()"`로 base/ 전체의 모든 `Relate` 인스턴스 나열 —
`inst`가 아닌 다른 값을 바깥 키로 쓰는 건 이번에 새로 만든 `slotOwner`가
유일했음. 나머지(`chains`/`owners`/`kTagMap`/`tagNameMap`/Ref의 `relate`
등)는 전부 `inst`만 바깥 키로 쓰고, 안에 담기는 값(Tag/AttributeKey/
Handler)이 `inst`로 되돌아가는 back-reference를 안 가짐(Tag는 순수
데이터, AttributeKey도 `{Name=name}`뿐) — 두 테이블 상호순환 위험
없음 확인. `Ref.Value=inst`는 back-reference가 있지만 단일 테이블 자기참조
형태라 안전한 쪽으로 분류.

## 반영

- `base/slot-plan.md` "Slot과 Store 바인드의 관계" 절 — `kSlotMap`/
  `slotOwner` 둘 다 `SetStrong`→`SetWeak`로 낮춤(순수 조회 전용).
- `attachSlot`에 `bindLifetime(physicalTarget, slot)` 추가(Slot 자신의
  GC 앵커 — 기존엔 이게 없어서 아무도 slot을 강하게 안 붙잡는 상태였음).
- `destroySlotTree`에 짝인 `unbindLifetime(slot._mountedInst, slot)`
  추가(기존엔 자식 observer들의 unbindLifetime만 있고 slot 자신의
  해제가 빠져 있었음).
