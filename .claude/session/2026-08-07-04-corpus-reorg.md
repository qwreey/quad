<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 네 번째 세션 — `.claude/` 코퍼스 전반 정리(폴더 재편, 승격, 기각 분리)

사용자가 코퍼스 전체를 훑고 "실제 코딩에 필요한가"를 기준으로 남길 것과
분리할 것을 판단해 달라고 요청 — 여러 문서에 쌓인 역전 이력/quad
자체와 무관한 배경자료/이미 기각된 후보가 뒤섞여 있어 컨텍스트 크기와
가독성 둘 다 해치고 있다는 문제의식. 아래 6가지를 처리, 전부 반영 완료:

1. **`reference/` 폴더 신설** — `quad-v1-architecture.md`,
   `comparison-fusion-vide.md`를 `base/`에서 이동. 항상 읽어야 하는
   결정사항(`base/`)과, 다른 문서가 근거로 인용할 때만 열어보면 되는
   온디맨드 스냅샷/비교자료(`reference/`)를 분리 — 전자는 "결정 완료",
   후자는 "결정이 아니라 결정의 근거"라는 차이. 전체 문서의 상호참조
   경로도 전부 갱신함.
2. **`component-composition-plan.md`의 누적 역전 이력 트리밍** —
   `StoreSource` 프록시 폐기 이력이 "원래 이랬다 → 이렇게 뒤집혔다"를
   본문에서 장황하게 반복 서술하고 있었는데, 이미 `archive/
   store-source-proxy-reversed.md`에 원문·이유·비교표가 전부 보존돼
   있으므로 본문은 최종 확정만 남기고 포인터로 압축.
3. **`ui-shorthand-plan.md`를 `research/`→`base/`로 승격, 재작성** —
   (a) 이미지 라운드 트릭 `RoundSize`는 완전히 드롭, 근거는
   `archive/ui-shorthand-roundsize-dropped.md`로 분리(이 판단이 한 차례
   "Corner/PaddingAll/Scale 전체가 불필요하다"로 잘못 일반화됐다가
   정정된 이력도 같이 보존). (b) 이름을 v1 그대로(`Corner`/`PaddingAll`/
   `Scale`)가 아니라 실제 Roblox Instance 이름과 맞춘 `UICorner`/
   `UIPadding`/`UIScale`로 확정 — v1식 짧은 이름은 Modifier 체이닝
   메소드와 겹쳐 "진짜 UICorner 숏핸드인지 그냥 비슷한 이름의 부가
   Modifier인지" 구분이 안 된다는 사용자 지적 반영. (c) store-bind
   가능성 명시 — v1에서도 가능했던 기능이고, Tween처럼 무거운 API
   표면 없이 기존 per-instance weak-table 유틸(`base.perInstanceState`)
   재사용만으로 충분하다는 점을 추가.
4. **`additional-primitives-plan.md`를 4갈래로 분리**: 확정된 `Blocker`/
   `Effect`는 각각 새 `base/blocker-plan.md`/`base/effect-plan.md`로
   승격(Blocker는 State와 같은 마일스톤에서 개발하기로 해서
   `store-semantics.md`에 교차 참조 추가, `ROADMAP.md` M3에도 체크박스
   반영). 기각된 `Batch`(lexical block)와 `Context`(+대안이던 레이어드
   Store)는 각각 `archive/batch-rejected.md`/`archive/context-rejected.md`로
   분리. `research/additional-primitives-plan.md`엔 아직 실제로 열려있는
   것(키 기반 동적 컬렉션 재조정) 하나만 남김. **[같은 날 바로 정정]**
   처음엔 Blocker/Effect를 `base/additional-primitives.md` 한 파일로
   합쳐 승격했으나, 사용자가 "State 볼 때 Effect까지 볼 필요는 없다,
   기존 프리미티브당 1파일 컨벤션(`modifier-plan.md`/`slot-plan.md`류)에
   맞지 않는다"고 지적해 바로 두 파일로 재분리함 — Blocker는
   Store/State와 밀접해 교차 참조가 필요하지만 Effect는 완전히 독립된
   요소라 애초에 같은 파일일 이유가 없었음.
5. **archive 제목 컨벤션을 둘로 분화** — 기존 `[역전됨]`(한 번 확정했다가
   뒤집힌 것, `store-source-proxy-reversed.md`/`ref-phase-option-reversed.md`)과
   새로 생긴 `[기각됨]`(확정한 적 없이 후보였다가 채택 안 된 것,
   `batch-rejected.md`/`context-rejected.md`/`ui-shorthand-roundsize-dropped.md`)을
   구분 — `README.md`의 `archive/` 폴더 기준 설명에 두 컨벤션 차이를
   명시.
6. **`tween-plan.md` 보강** — `retract`가 Destroy 시엔 호출 안 된다는
   사실을 상단 상태 요약에서도 짚도록 가시성 강화, `canExecute`(Destroy
   시 처리)와 `retract`(값 교체 시 처리)가 서로 다른 문제를 다룬다는
   점을 quadnomicon급 문서화 숙제로 메모(지금은 상세 설명 안 하고
   메모만). 트윈 옵션 값 모양(raw `TweenInfo` vs 이름 붙은 편의
   필드+기본값) 논의를 새로 열어둠 — Luau가 named call을 지원 안 해서
   `TweenInfo.new(...)` 포지셔널 생성자가 읽기 어렵다는 문제의식,
   소견은 편의 필드 쪽이지만 확정 아님, 나중 논의 대상으로만 남김.

