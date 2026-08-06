# .claude/ — quad-v2 계획/설계 문서 색인

이 레포 전체가 quad-v2(재작성) 프로젝트이므로, webmanager류 서브프로젝트 구분 없이
`.claude/` 바로 아래에 전부 있음. **루트 `CLAUDE.md`가 현재 상태+TODO 색인의
최종 소스** — 먼저 그걸 보고, 특정 결정의 자세한 근거/논의가 필요할 때만 아래
개별 문서를 열어볼 것.

## 폴더 기준

| 폴더 | 기준 |
|---|---|
| `base/` | 결정 완료 + 프로젝트 전체에 걸치는 컨텍스트 — plan/done 개념 없음, 계속 참조되는 배경지식 |
| `research/` | 아직 착수 전, 사용자와 스코프/설계를 더 상의해야 함 |
| `qa-request/` | 구현 완료(코드/에이전트 검증까지 끝남) + 사용자 본인의 실기기(Roblox Studio) QA만 남음 — 지금은 구현 자체가 시작 전이라 비어있음 |
| `archive/` | 완료 + 사용자가 실사용/실기기로 직접 검증까지 마침 (구현 대상). **[2026-08-06 확장]** 완전히 뒤집힌 설계 결정을 원문+역전 이유+diff와 함께 보존하는 용도로도 사용 — 더 이상 능동적으로 참고 안 해도 되지만(토큰 낭비 방지 위해 `base/`/`research/`에서 뺌) `quadnomicon` 소재로는 나중에 쓸 수 있음 |
| `feedback/` | 실사용 피드백을 정리한 긴 로그 — 지금은 비어있음(구현 시작 전) |
| `initreq/` | 프로젝트 착수 시 클론해둔 참고 레포(quad v1, fusion, vide, rbvm, tbox, code-docker) + PA님 실 코드(`artworks/`, 4차 라운드 교차검증 근거) + 원본 요청(`req.md`, `raw-userinput.md`) + `quad2-try`(이전에 시도했다 폐기한 v2 재작성 시도 — 리서치 완료, 결론은 `base/bind-system-plan.md`) — 읽기 전용 리서치 소스, 여기 내용을 옮기지 말고 항상 원본 그대로 유지 |

`research/`의 문서가 설계 확정되면 `base/`로 승격(또는 구현 착수 시
`qa-request/`행). 지금은 구현 라운드 전(설계 단계)이라 전부 `base/`/`research/`에만
있음.

## `base/` — 결정된 것, 프로젝트 전체 컨텍스트

| 문서 | 내용 |
|---|---|
| `architecture.md` | quad-v2 전체 아키텍처 확정 사항 요약(제일 먼저 볼 문서) |
| `quad-v1-architecture.md` | v1(`initreq/quad`) 내부 동작 스냅샷 — "이 문제를 안 반복하려면"의 기준선 |
| `comparison-fusion-vide.md` | Fusion/Vide 아키텍처 비교 리서치 — 설계 결정 근거 자료(전파 모델 등 일부 서술은 이후 라운드에서 뒤집혔으니 `bind-system-plan.md` 쪽을 최신으로 볼 것) |
| `lifecycle-pattern.md` | rbvm의 `Connected`+GC 관용구를 quad-v2가 채택하는 방식 |
| `store-semantics.md` | Store는 부작용 허용이 기본. State는 Store 위의 조합 가능한 캐시 레이어로 실제로 필요함(2026-08-04 정정) — 온톨로지 핵심 메커니즘은 2026-08-04 2차 라운드에서 확정, 최신 상세는 `base/bind-system-plan.md` |
| `bind-system-plan.md` | pluggable key/value 핸들러 레지스트리 — `process`/`retract` 디스패치 모델, Ref, Store/State/Source 온톨로지 + 인체공학 질문 전부 확정. 디스패치 엔진은 `quad-base`가 인터페이스로 소유(2026-08-04 5차 라운드) |
| `module-lifecycle-plan.md` | 프로바이더 패턴, bind/store 구현 책임 분리 — 확정 |
| `slot-plan.md` | 뮤터블 자식 배열, 엄격한 단일 마운트 소유권, 재마운트 시 throw, base/roblox 패키지 경계까지 확정 |
| `modifier-plan.md` | Modifier는 런타임 plug 아닌 정적 merge, immutable+clone 기반 체이닝 — 메커니즘 확정, getter 이름만 남음 |
| `purity-and-effects-plan.md` | 컴포넌트 "순수성"이 아니라 "이식성" 문제로 재정의 — 문서 경고 수준으로 확정 |
| `component-composition-plan.md` | 컴포넌트=플레인 함수, State/Source 읽기·쓰기 경계, Source가 State를 구조적으로 만족(`StoreSource`/`RefSource` 중간안은 전부 폐기됨) — modifier/Ref 컴포넌트 경계 통과까지 전부 확정, 남은 건 API 이름뿐 [정정: 2026-08-04 승격됐으나 이 표에 반영이 안 돼있던 걸 2026-08-06 뒤늦게 수정] |

## `research/` — 아직 착수 전, 상의 필요

| 문서 | 내용 | 우선순위 |
|---|---|---|
| `tween-plan.md` | 트윈을 Store 밖 특수 bind key로 처리, 기본 오버라이드는 Cancel | 중 — 세부 옵션만 남음 |
| `existing-instance-bind-plan.md` | 이미 생성된 인스턴스 재바인드 — 착수 안 하되 "미지원" 확정도 안 함, 열린 가능성 유지 | 하 — v2 초기 스코프 제외 |
| `debug-tooling-plan.md` | 실물 Instance→코드 위치 역추적 Studio 플러그인(`quad-debug`) — 채널 실현 가능성(BindableEvent/Function 크로스 컨텍스트)까지 실측 검증 완료, 세부 API 이름·구현만 남음 | 하 — 사용자가 "quad 개발 완료 전엔 착수 못 함"으로 직접 후순위 지정, base 설계 시 훅 확장 지점만 고려 |
| `documentation-plan.md` | 문서 사이트 구조(초심자/api/심화/`quadnomicon` 4축, 백엔드별 트랙 분리) + UI 네이밍 컨벤션·Store 부작용 패턴·권장 이벤트 핸들링 3개 세부 문서 뼈대 | 하 — 착수 시점 미정, 구조/스코프만 합의된 상태 |
| `documentation-content-map.md` | 위 4축에 실제로 뭘 채울지 `base/` 전체를 초심자/api/심화/skip으로 서베이한 콘텐츠 맵 — 초심자 core loop 목차 초안 포함 | 하 — 문서화 착수 시점의 목차/우선순위표로 쓸 것 |
| `framework-comparison-findings.md` | quad vs Fusion/Vide/react-lua 정직한 비교(실 소스 근거) — quad 강점, 진짜 불리한 점 중 고칠 만한 것 3개, 못 고치는 트레이드오프 정리 | 하 — 사용자 검토 후 반영 여부 결정 대기 |
| `ui-shorthand-plan.md` | UICorner/UIPadding/UIScale 인라인 편의 키(v1 `Corner`/`PaddingAll`/`Scale` 선례) — 여전히 필요한 기능으로 재확정(RoundSize만 네이티브 UICorner로 대체돼 불필요), 메커니즘(Handler)·패키지 배치(quad-roblox 코어) 확정 | 하 — 결론 남, M10 전후 구현하면 됨 |
| `additional-primitives-plan.md` | 확정 프리미티브(Source/State/Store/Ref/Observer/Modifier/Slot/DI)만으로 충분한지 웹 프레임워크·Fusion/Vide/v1 소스 근거로 조사 — 키 기반 동적 컬렉션 재조정(Fusion `ForPairs`/Vide `indexes()`류)이 가장 명확한 빈 자리로 확인, Effect/Batch/Context는 부차적 후보 | 상 — 사용자 판단 대기, 착수 전 M0/M1 스코프에 영향 줄 수 있음 |
| `pre-implementation-audit.md` | M0 착수 직전 크리티컬 감사(2026-08-06 신설) — `base/` 전체를 모호성/지연결정리스크/단순화후보 세 렌즈로 재검토, 11개 우선순위1(M0~M4 착수 전 확인 권장) + 11개 우선순위2 + 2개 단순화후보 | 상 — M0 착수 전 최소 우선순위1 항목 확인 권장 |

## `archive/` — 완료됐거나 완전히 뒤집힌 것, 능동 참고 불필요

| 문서 | 내용 |
|---|---|
| `store-source-proxy-reversed.md` | 2026-08-04에 확정했던 `StoreSource` 프록시 설계(Store가 Source를 감춘 별도 프록시로 감쌈) — 2026-08-06 세 번째 세션에서 "Source가 State를 구조적으로 만족" 재구성으로 완전히 대체됨. 원문·역전 이유·신구 비교표 보존, `quadnomicon` 소재 후보 |

## 참고

- **저장소 소유자가 답해야 할 질문 전체 취합**: `.claude/question.md`
- **사람만 할 수 있는 일(로컬 조작/결정)**: 루트 `HUMAN_TODO.md`
- **원본 브레인스토밍(raw chain-of-thought)**: `.claude/initreq/raw-userinput.md`,
  `.claude/initreq/req.md` — 위 문서들로 나누기 전의 원본, 참고용 백업이니 그대로 둘 것
