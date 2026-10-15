# code-review 2026-10-15 — 리뷰 안 된 코어 커밋 둘(`b1f301e1`, `99c2d7a1` Q186)

3.3.0 전 재검사 셋 중 하나(나머지 둘: 공개 표면 수렴 opus, 3.2.0 이후 라운드 사이 상호작용 Gemini — 결정과 경위는
`research/consumer-kits-plan.md` 5절 "남은 결정 닫힘" 문단). 파인더 sonnet 하나, 사본에서 프로브, 메인 판정.

**결과: 동작 결함 0.** 확인한 것 — 중첩 창에서 `restoreChain`이 바깥 올림을 지우지 않음, 조상의 `WhenIdle` 요청은 자식 연산의 진입점 끝에서
건 순서대로, 오프셋은 꼬리 전에 내림, 던진 콜백은 사슬 전체를 동결(문서화된 범위), 창 안에서 `:Single`이 주인 Slot을 사슬에서 빼면 `Quad0023`이고
플래그는 남지 않음(Q187 UB 범위), 형제·무관한 Slot 통과.

발견 둘의 메인 판정:
1. `rawUnmount`가 엔진 호출이 없는 지연 경로(`Splice`·`ExtractAll`의 논리 단계)에서도 사슬을 올린다 — 원소 3000개·깊이 20에서 `ExtractAll` 5.7 → 18 ms(mock).
   파인더는 "엔진 호출이 있을 때만 올리면 된다"고 했으나 **기각**: 그 경로의 `teardownTree`가 `unbindLifetime`으로 사용자 cleanup을 부르고, `Splice` 도중에는
   부기가 이미 화면 배치와 어긋나 있어(물리 일괄 처리는 루프 뒤) cleanup이 조상 CRUD를 하면 틀린 오프셋을 쓴다. 동작은 그대로, 이유를 `Raw.luau` 주석에.
   비용이 실제로 문제가 되면 `rawSplice` 전체를 한 번 올리는 쪽이 정답(관측 전이라 안 함).
2. `Slot/init.luau`의 "Unmount raises no flag" 주석이 Q185 이후 낡음 — 고침.

`probes/`: `q186_a.luau`(중첩 창·`WhenIdle` 순서·던짐·`:Single` 뒤집기), 비용 프로브(`_G.DEPTH`), `q186_cycle.luau`(owner 순환 — 재현 안 됨).
사본 `quad-base/test/`에서 `mise exec -- luau test/<파일>`.
