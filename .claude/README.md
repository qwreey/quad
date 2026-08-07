# .claude/ — quad-v2 계획/설계 문서 색인

이 레포 전체가 quad-v2(재작성) 프로젝트이므로, webmanager류 서브프로젝트 구분 없이
`.claude/` 바로 아래에 전부 있음. **루트 `CLAUDE.md`가 현재 상태+TODO 색인의
최종 소스** — 먼저 그걸 보고, 특정 결정의 자세한 근거/논의가 필요할 때만 아래
개별 문서를 열어볼 것.

## 폴더 기준

| 폴더 | 기준 |
|---|---|
| `base/` | 결정 완료 + 프로젝트 전체에 걸치는 컨텍스트 — plan/done 개념 없음, 계속 참조되는 배경지식. **항상 읽어야 하는** 배경지식만 여기 둠(다른 문서를 이해하는 데 전제되는 것) |
| `reference/` | **[2026-08-07 신설]** 결정 자체가 아니라 다른 문서가 근거로 인용하는 온디맨드 참고 자료(v1 스냅샷, 프레임워크 비교 리서치) — "완료" 개념 없는 건 `base/`와 같지만, 항상 읽을 필요는 없고 해당 문서가 인용될 때만 열어보면 됨. `quadnomicon` 소재 후보가 많음 |
| `research/` | 아직 착수 전, 사용자와 스코프/설계를 더 상의해야 함 |
| `qa-request/` | 구현 완료(코드/에이전트 검증까지 끝남) + 사용자 본인의 실기기(Roblox Studio) QA만 남음 — 지금은 구현 자체가 시작 전이라 비어있음 |
| `archive/` | 완료 + 사용자가 실사용/실기기로 직접 검증까지 마침 (구현 대상). **[2026-08-06 확장]** 완전히 뒤집힌 설계 결정을 원문+역전 이유+diff와 함께 보존하는 용도로도 사용(제목 `[역전됨]` — 한 번 확정했다가 뒤집힌 것) — 더 이상 능동적으로 참고 안 해도 되지만(토큰 낭비 방지 위해 `base/`/`research/`에서 뺌) `quadnomicon` 소재로는 나중에 쓸 수 있음. **[2026-08-07 확장]** 후보였다가 채택 안 된 것(확정한 적 없이 검토 후 기각)도 같은 방식으로 보존, 제목은 구분을 위해 `[기각됨]` — `[역전됨]`과 의미가 다르므로 혼동하지 말 것 |
| `feedback/` | 실사용 피드백을 정리한 긴 로그 — 지금은 비어있음(구현 시작 전) |
| `initreq/` | 프로젝트 착수 시 클론해둔 참고 레포(quad v1, fusion, vide, rbvm, tbox, code-docker) + PA님 실 코드(`artworks/`, 4차 라운드 교차검증 근거) + 원본 요청(`req.md`, `raw-userinput.md`) + `quad2-try`(이전에 시도했다 폐기한 v2 재작성 시도 — 리서치 완료, 결론은 `base/bind-system-plan.md`) — 읽기 전용 리서치 소스, 여기 내용을 옮기지 말고 항상 원본 그대로 유지 |

`research/`의 문서가 설계 확정되면 `base/`로 승격(또는 구현 착수 시
`qa-request/`행). 지금은 구현 라운드 전(설계 단계)이라 전부 `base/`/`research/`에만
있음.

## `base/` — 결정된 것, 프로젝트 전체 컨텍스트

| 문서 | 내용 |
|---|---|
| `architecture.md` | quad-v2 전체 아키텍처 확정 사항 요약(제일 먼저 볼 문서) |
| `lifecycle-pattern.md` | rbvm의 `Connected`+GC 관용구를 quad-v2가 채택하는 방식 |
| `store-semantics.md` | Store는 부작용 허용이 기본. State는 Store 위의 조합 가능한 캐시 레이어로 실제로 필요함(2026-08-04 정정) — 온톨로지 핵심 메커니즘은 2026-08-04 2차 라운드에서 확정, 최신 상세는 `base/bind-system-plan.md` |
| `bind-system-plan.md` | pluggable key/value 핸들러 레지스트리 — `process`/`retract` 디스패치 모델, Ref, Store/State/Source 온톨로지 + 인체공학 질문 전부 확정. 디스패치 엔진은 `quad-base`가 인터페이스로 소유(2026-08-04 5차 라운드) |
| `module-lifecycle-plan.md` | 프로바이더 패턴, bind/store 구현 책임 분리 — 확정 |
| `slot-plan.md` | 뮤터블 자식 배열, 엄격한 단일 마운트 소유권, 재마운트 시 throw, base/roblox 패키지 경계까지 확정 |
| `modifier-plan.md` | Modifier는 런타임 plug 아닌 정적 merge, immutable+clone 기반 체이닝 — 메커니즘 확정, getter 이름만 남음 |
| `purity-and-effects-plan.md` | 컴포넌트 "순수성"이 아니라 "이식성" 문제로 재정의 — 문서 경고 수준으로 확정 |
| `component-composition-plan.md` | 컴포넌트=플레인 함수, State/Source 읽기·쓰기 경계, Source가 State를 구조적으로 만족 — modifier/Ref 컴포넌트 경계 통과까지 전부 확정, 남은 건 API 이름뿐. **[2026-08-07 정리]** 폐기된 `StoreSource` 프록시 설계로의 역전 이력은 본문에서 빼고 `archive/store-source-proxy-reversed.md` 포인터로 압축 |
| `additional-primitives.md` | **[2026-08-07 신설]** `Blocker`(여러 Source를 한꺼번에 바꿔도 파생값 재계산이 한 번만 되게, State 마일스톤과 함께 개발)와 `Effect`(leaf 죽음에 확정 정리) — Blocker는 메커니즘+이름 확정, Effect는 Observer와의 관계가 아직 미해결(문서 내 "미해결" 절, `question.md` 0번) |
| `ui-shorthand-plan.md` | **[2026-08-07 `research/`에서 승격]** `UICorner`/`UIPadding`/`UIScale` 인라인 편의 키 — 이름(v1 `Corner`/`PaddingAll`/`Scale`에서 Modifier 필드명과 안 겹치게 `UI` 프리픽스로 확정)·메커니즘(Handler)·패키지 배치(quad-roblox 코어)·store-bind 가능성까지 전부 확정. 이미지 라운드 트릭(`RoundSize`)은 드롭 — `archive/ui-shorthand-roundsize-dropped.md` 참고 |

## `reference/` — 온디맨드 참고 자료 (2026-08-07 신설)

| 문서 | 내용 |
|---|---|
| `quad-v1-architecture.md` | v1(`initreq/quad`) 내부 동작 스냅샷 — "이 문제를 안 반복하려면"의 기준선. **[2026-08-07 `base/`→`reference/` 이동]** v2의 결정 자체가 아니라 다른 문서가 인용하는 온디맨드 자료라 항상 읽을 필요는 없음 |
| `comparison-fusion-vide.md` | Fusion/Vide 아키텍처 비교 리서치 — 설계 결정 근거 자료(전파 모델 등 일부 서술은 이후 라운드에서 뒤집혔으니 `bind-system-plan.md` 쪽을 최신으로 볼 것). **[2026-08-07 `base/`→`reference/` 이동]**, `quadnomicon` 소재 후보 |

## `research/` — 아직 착수 전, 상의 필요

| 문서 | 내용 | 우선순위 |
|---|---|---|
| `tween-plan.md` | 트윈을 Store 밖 특수 bind key로 처리, 기본 오버라이드는 Cancel, 트윈 옵션 값 모양(TweenInfo vs 편의 필드)은 신규 열린 논의 | 중 — 세부 옵션만 남음 |
| `existing-instance-bind-plan.md` | 이미 생성된 인스턴스 재바인드 — 착수 안 하되 "미지원" 확정도 안 함, 열린 가능성 유지 | 하 — v2 초기 스코프 제외 |
| `debug-tooling-plan.md` | 실물 Instance→코드 위치 역추적 Studio 플러그인(`quad-debug`) — 채널 실현 가능성(BindableEvent/Function 크로스 컨텍스트)까지 실측 검증 완료, 세부 API 이름·구현만 남음 | 하 — 사용자가 "quad 개발 완료 전엔 착수 못 함"으로 직접 후순위 지정, base 설계 시 훅 확장 지점만 고려 |
| `documentation-plan.md` | 문서 사이트 구조(초심자/api/심화/`quadnomicon` 4축, 백엔드별 트랙 분리) + UI 네이밍 컨벤션·Store 부작용 패턴·권장 이벤트 핸들링 3개 세부 문서 뼈대 | 하 — 착수 시점 미정, 구조/스코프만 합의된 상태 |
| `documentation-content-map.md` | 위 4축에 실제로 뭘 채울지 `base/` 전체를 초심자/api/심화/skip으로 서베이한 콘텐츠 맵 — 초심자 core loop 목차 초안 포함 | 하 — 문서화 착수 시점의 목차/우선순위표로 쓸 것 |
| `framework-comparison-findings.md` | quad vs Fusion/Vide/react-lua 정직한 비교(실 소스 근거) — quad 강점, 진짜 불리한 점 중 고칠 만한 것 3개, 못 고치는 트레이드오프 정리 | 하 — 사용자 검토 후 반영 여부 결정 대기 |
| `additional-primitives-plan.md` | **[2026-08-07 범위 축소]** 확정/기각된 Effect·Blocker·Batch·Context는 `base/additional-primitives.md`·`archive/`로 분리됨 — 이제 **키 기반 동적 컬렉션 재조정**(Fusion `ForPairs`/Vide `indexes()`류에 대응하는 프리미티브가 quad엔 없음) 하나만 다룸 | 상 — 사용자 판단 대기, 착수 전 M0/M1 스코프에 영향 줄 수 있음 |
| `pre-implementation-audit.md` | M0 착수 직전 크리티컬 감사(2026-08-06 신설) — `base/` 전체를 모호성/지연결정리스크/단순화후보 세 렌즈로 재검토, 11개 우선순위1(M0~M4 착수 전 확인 권장) + 11개 우선순위2 + 2개 단순화후보 | 상 — M0 착수 전 최소 우선순위1 항목 확인 권장 |
| `v1-compat-plan.md` | v1 하위호환(compat) 레이어 — `quad-roblox-v1-compat` 패키지, v2→v1 단방향 브리지(`state:Observer()`+v1 프로퍼티 재대입), v2-in-v1/v1-in-v2 두 임베딩 방향의 기술 규칙까지 확정. quad2-try의 `quad-compat`은 빈 폴더로 실제 시도된 적 없었음을 확인 | 하 — Slot이 foreign Instance를 어떻게 다루는지만 Slot 코어 구현 시점까지 미결 |

## `archive/` — 완료됐거나 완전히 뒤집힌 것, 능동 참고 불필요

| 문서 | 내용 |
|---|---|
| `store-source-proxy-reversed.md` | [역전됨] 2026-08-04에 확정했던 `StoreSource` 프록시 설계(Store가 Source를 감춘 별도 프록시로 감쌈) — 2026-08-06 세 번째 세션에서 "Source가 State를 구조적으로 만족" 재구성으로 완전히 대체됨. 원문·역전 이유·신구 비교표 보존, `quadnomicon` 소재 후보 |
| `ref-phase-option-reversed.md` | [역전됨] `CreatedRef`의 `phase` 옵션 — 위치 기반 순서 + `PreRef` 신설로 대체됨 |
| `ui-shorthand-roundsize-dropped.md` | **[기각됨, 2026-08-07 신설]** v1 `RoundSize`(이미지 9-slice 라운드 트릭) — 네이티브 `UICorner`로 대체되어 포팅 불필요. 이 판단이 한 차례 "Corner/PaddingAll/Scale 숏핸드 전체가 불필요하다"로 과잉일반화됐다가 정정된 이력 포함 |
| `batch-rejected.md` | **[기각됨, 2026-08-07 신설]** lexical `Batch(fn)` — 코루틴 yield 위에서 구조적으로 위험해 기각, 값 기반 `Blocker`(`base/additional-primitives.md`)로 대체 |
| `context-rejected.md` | **[기각됨, 2026-08-07 신설]** `Context`(트리 하위 암묵 전파) + 대안이던 레이어드 Store 둘 다 기각 — 명시적 타입 강제 Store 전달로 충분하다는 판단 |

## 참고

- **저장소 소유자가 답해야 할 질문 전체 취합**: `.claude/question.md`
- **사람만 할 수 있는 일(로컬 조작/결정)**: 루트 `HUMAN_TODO.md`
- **원본 브레인스토밍(raw chain-of-thought)**: `.claude/initreq/raw-userinput.md`,
  `.claude/initreq/req.md` — 위 문서들로 나누기 전의 원본, 참고용 백업이니 그대로 둘 것
