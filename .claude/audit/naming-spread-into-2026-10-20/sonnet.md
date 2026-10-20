## Spread 입력 이름 검토 (sonnet, 2026-10-20 — 서브에이전트 최종 보고 요지)

1. `SpreadInto<C>` — keep. `ModifierInto<C>`와 쌍이라 새로 배울 개념이 없다. 대안 `SpreadFor<C>`(쌍이 깨짐), `SpreadSlot<C>`(Slot 어휘 충돌 추정). 위험 낮음 — "C 또는 조상"은 이름에 안 드러나지만 `ModifierInto`와 같이 문서 한 번.
2. `FieldSpread`/`TrackSpread` — change(구조 지적). 둘 다 받으면 어느 쪽에 넣을지 고민하게 된다. 추천 `FieldExtras`/`TrackExtras`(Modifier로 못 하는 것을 얹는 자리 — "기본값 vs 추가 부착"이 이름에 드러남). 대안 `FieldSpread` 유지(타입과 일치, 혼란은 문서로), `FieldProps`(`Props<C>`와 겹침). 위험 중간: 병존 혼란, 둘을 같이 줄 때 우선순위가 이름에 안 보임.
3. `:Add` — keep, `:Append` 고려. `Add`는 덮어쓰기 연상(`Set`/`Merge`/`Override`)이 약하다. `Append`는 "뒤에 붙인다"에서 "키는 뒤에 오는 쪽이 진다"가 자연스럽게 나온다. `Include`는 덮어쓰기 연상이 가장 약하나 변형 동작과 어색(추정).

세트 전체: Modifier "나중이 이김" vs Spread "먼저가 이김"이 가장 큰 혼란 지점 — 이름이 아니라 문서의 우선순위 표(인라인 > Spread(앞 > 뒤) > Modifier(뒤 > 앞))로. `FieldSpread`를 `FieldModifier` 옆에 두면 prop 수가 두 배 — 장기적으로 하나가 포함하는 쪽이 일관(추정). `Spread<C>`/`SpreadInto<C>` 쌍은 건드리지 말 것.
