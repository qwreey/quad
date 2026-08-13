# 2026-08-13 첫 번째 세션 — gcconn 트릭 부분 실측, `Relate` 상호 순환 스파이크 신규, README 동기화

## 배경

사용자가 `base/lifecycle-pattern.md`의 `bindLifetime`/`canExecute`가 기대는
"gcconn 트릭"의 핵심 가정 둘(ClassName PropertyChangedSignal 미발화,
`Connection.Connected`가 `Destroy()` 시 GC 없이 동기적으로 `false`가 됨)을
Roblox Studio에서 직접 실측하는 저수준 스크립트를 짜서 돌려봄 —
`luau-test/10-roblox-studio-checks.server.luau`의 공식 스크립트는 아니고,
같은 두 가정만 따로 떼어 검증한 자작 스크립트. 출력 로그를 보여주며 "이걸로
`luau-test/README.md`가 '심각한 발견'이라고 못 박아둔 위험이 해소됐다고 볼
수 있는지" 확인 요청.

## 1단계 — 읽기 전용 검토(쓰기 금지 지시)

당시 다른 에이전트가 작업 중이라는 안내가 있어 쓰기 없이 결론만 냄:
스크립트/로직 자체는 정확했고, 두 핵심 가정(신호 미발화, Connected 즉시
전환) 모두 확인됨 — 하지만 공식 `10` 파일이 커버하는 나머지(A-1/A-2
`canBound`/`unbindLifetime` 이중 바인딩 게이트, Part B Attribute Instance
참조, Part C CollectionService 왕복)는 이 자작 스크립트가 아예 안 건드려서
"완전 해소"로 볼 수 없다는 게 결론 — 부분 확인.

## 2단계 — 문서화 요청

사용자가 이어서: (1) 해소된 부분만 정리해 `.claude/audit/` 같은 폴더에
남기고, (2) 실측에 쓴 "GC 강제 트리거" 기법(canary weak table + 할당 압력
+ `task.wait` 폴링)도 재사용 가능하게 문서화하고, (3) 그 김에 코퍼스 전체를
훑어 luau-test에 더 필요한 게 있는지/stale한 게 있는지 보고 적절히
갱신해달라고 요청.

## 한 일

**`.claude/audit/` 신설** — `gcconn-trick-verification.md` 작성: 확인된
것 4개(신호 미발화, 연결 살아있는 동안 클로저 캡처값 GC 안 됨, Destroy 직후
`Connected` 동기적 전환, Destroy+GC 후 클로저 캡처값 실제 수거), 아직 확인
안 된 것(A-1/A-2, Part B/C, `inst` 자체를 `__mode="k"` weak key로 쓰는
경로) 명확히 구분.

**GC 트리거 기법 문서화** — `luau-test/gc-trigger-helper.server.luau`
신설(`waitForGC()` 복붙용 스니펫). 부수적으로 `07-relate-weak-table-gc.luau`의
"Studio에서는 GC 타이밍 검증 자체가 불가능"이라던 서술이 이번 발견으로
틀렸음을 확인 — `collectgarbage()` API가 없다는 것만 맞고, 간접 관찰은
가능하다고 정정.

**`18-relate-mutual-cycle-gc.luau` 신규** — 코퍼스를 다시 훑던 중,
`relate-plan.md`의 "두 `Relate` 상호 강참조 순환은 ephemeron 없이는 GC가
안 풂"이라는 주장(Slot의 `kSlotMap`/`slotOwner` GC 수정 사례 전체의 유일한
근거)이 지금까지 **공식 문서 인용으로만** 뒷받침돼 있었고 실제 Luau로
재현해본 적이 없었던 갭을 발견 — 음성 대조군(순환 재현)/양성 대조군(한쪽을
weak-value로 낮추면 풀리는지) 둘 다 넣은 순수 luau CLI 스파이크로 작성.

**CLAUDE.md stale 항목 발견·수정** — "지금 할 일" 2번(용어 정리)이 여전히
`State`를 "1순위, 위험도 높음, open"으로 나열하고 있었는데, `question.md`
확인 결과 `State`는 이미 2026-08-12 스무 번째 세션에 확정(현재 이름 유지)돼
있었음 — `question.md`는 정확했고 CLAUDE.md의 압축 요약만 안 따라감. 실제
열려있는 항목 목록(`DI`→`D`, `Slot`, `canExecute`, `Brand`, `Tag`류,
`Attribute`/`AttributeKey`)으로 정정.

**서브에이전트에 위임한 코퍼스 전체 스윕** — 세션 8~21(전부 2026-08-12,
`retract는 항상 불림` 정정부터 `Compute` 네이밍 근거까지)이 지난 마지막
전체 감사(세션 16) 이후 `.claude/README.md`의 요약 테이블에 제대로
반영됐는지, 그리고 이 기간에 생긴 새 메커니즘 중 luau-test 커버리지가
빠진 게 있는지 조사 위임. 결과:

- `base/`/`research/` 문서 **본문 자체는 이미 전부 최신**이었음 — 갭은
  전적으로 `.claude/README.md`의 요약 테이블(색인 레이어)에만 있었음.
  `bind-system-plan.md`/`slot-plan.md`/`tag-plan.md`/`modifier-plan.md`/
  `architecture.md`/`framework-comparison-findings.md`/
  `operator-sugar-plan.md`/`pre-implementation-audit.md` 8개 행에
  세션 12~21 변경사항을 인용 마커로 보강.
- `attribute-plan.md` 행은 단순 append가 아니라 실제 오류 수정 — 세션 11의
  중간 단계(`v==nil` 가드)를 "현재 상태"인 것처럼 적어뒀는데, 세션 16이
  이미 이걸 완전히 뒤집어(retract 완전 no-op) 낡은 서술이 됐던 것.
- **`19-ownership-refcount-relate-patterns.luau`**,
  **`20-slot-splice-index-arithmetic.luau`** 신규 추가 — 세션 8~21에서
  생긴 세 소유권/참조카운트 알고리즘(Tag `kTagMap`/`tagNameMap`, Attribute
  `rawNew`+`owners`, Slot `elementOwner`)과 `Slot:Splice`의 시프트 산술이
  03/04/11/18과는 다른 새 알고리즘 모양이라 실측 가치가 있다고 판단해
  작성. Ref/Slot의 retract-via-`Relate`-diff(세션 8/9)는 기존 03/04와 같은
  메커니즘 급이라 스파이크 불필요로 판단, 추가 안 함.
- Part C(세션 17~21의 `pre-implementation-audit.md`/
  `framework-comparison-findings.md`/`operator-sugar-plan.md`/
  `question.md`/`ROADMAP.md` 개별 파일 스팟체크)는 전부 이미 정확해서
  추가 수정 없음.

## 결과물

- 신규: `.claude/audit/gcconn-trick-verification.md`,
  `luau-test/gc-trigger-helper.server.luau`,
  `luau-test/18-relate-mutual-cycle-gc.luau`,
  `luau-test/19-ownership-refcount-relate-patterns.luau`,
  `luau-test/20-slot-splice-index-arithmetic.luau`
- 수정: `luau-test/07-relate-weak-table-gc.luau`(docstring 정정),
  `luau-test/README.md`(테이블/공통 유틸리티 절/갱신이력 8~9차/결과 확인
  체크리스트), `base/lifecycle-pattern.md`(gcconn 구현 스케치에 실측 각주),
  `.claude/README.md`(`audit/` 행 신설, `base`/`research` 테이블 9개 행
  동기화), `CLAUDE.md`("지금 할 일" 1/2번)

## 남은 것

- 공식 `luau-test/10` 파일로 A-1/A-2/Part B/Part C 마저 확인 필요(`10`의
  A 섹션 앞부분만 부분 확인된 상태).
- `01`~`06`, `08`, `09`, `11`~`20`(총 18개 중 `10` 제외 전부) — 여전히
  사용자가 실제로 안 돌려봄, M0 착수 전 최우선 게이트.
