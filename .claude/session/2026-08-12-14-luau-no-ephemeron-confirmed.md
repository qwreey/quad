# 2026-08-12 열네 번째 세션 — Luau에 ephemeron 없음, 공식 확인·문서화

## 배경

직전 세션(열세 번째)에서 `Slot`의 `kSlotMap`/`slotOwner` 상호 GC 순환을
고치며 "Luau가 이걸 실제로 올바르게 처리하는지 검증된 바 없으니 설계로
아예 피함"이라고 방어적으로 서술했었음. 이번 세션에서 사용자가 공식
출처를 제시: Luau는 복잡성 때문에 Lua 5.2의 ephemeron 테이블을 도입하지
않았음 — https://luau.org/compatibility/ "Lua 5.2" 섹션의 "Ephemeron
tables" 항목에 명시.

## 반영

- `base/slot-plan.md` "Slot과 Store 바인드의 관계" 절의 GC 주의 문단 —
  "검증된 바 없으니 피함"(추측성 방어)을 "공식 문서로 확인된 필수
  조치"(확정 사실)로 정정, 출처 URL 명시.
- `base/relate-plan.md`에 새 절 "위험한 패턴 — 서로 다른 두 `Relate`의
  상호 강참조 순환" 신설 — 단일 `Relate` 자기참조(안전, 기존에 이미
  서술돼 있던 것)와 두-`Relate` 상호 순환(위험, Luau가 ephemeron 없어
  실제로 안 풀림)을 명확히 구분하고, 출처+일반 규칙("`inst` 아닌 값을
  다른 `Relate`의 바깥 키로 쓰려면 그 값이 `inst`로 되돌아가는
  back-reference를 갖는지 먼저 확인, 있으면 최소 한쪽은 `SetWeak`+
  `bindLifetime`으로 앵커 통일")을 명문화 — 앞으로 비슷한 설계를 할 때
  Slot 사례를 매번 재발굴하지 않아도 되도록.
- `README.md` — `relate-plan.md` 요약 라인에 이 신설 절 포인터 추가.

이걸로 열한~열네 번째 세션에 걸친 "retract는 항상 불림" 정정과 그
파생 GC 이슈(Slot 소유권 relate, 두-Relate 순환) 시리즈가 마무리됨.
