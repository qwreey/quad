# `backlog/` — 근거는 이미 있고 아직 안 한 일

> **[2026-10-16 신설 — 사용자 결정]** *"이건 리서치라기보단 백로깅 폴더를 만드는게 나아보임. 이미 근거는 다 있고, 새로 찾는게 아니게 되었음."*
> `research/`는 아직 조사·설계 상의가 필요한 것, `backlog/`는 **조사가 끝나 근거가 있고 착수만 남은 것**이다. 구현되면 그 부분은 `base/`로 가고 여기선 지운다.
> 착수 순서·우선순위의 소스는 루트 `ROADMAP.md` 백로그 절이다(여기서 다시 매기지 않는다).

| 문서 | 내용 |
|---|---|
| `additional-operator-sugar.md` | 아직 넣지 않은 `Operator` 슈거 — 분기 `IfElse`·비교, 컬렉션 계열(`Concat`/`Sorted`/`Filtered`), Attr 그룹 unset 유틸, 중첩 State 평탄화, 중첩 결합 flatten 최적화(옛 operator-sugar-plan.md에서 분리; 구현분은 `base/operator-plan.md`) |
| `bindable-brand-publication.md` | 내부 `BindableBrand`(2026-10-01 구현)를 다듬어 문서화하고 공개 등록 표면을 어떻게 낼지(옛 bindable-hooks-plan.md; 근거는 `base/lifecycle-pattern.md`·`base/brand-plan.md`) |
