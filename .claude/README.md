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
| `archive/` | 완료 + 사용자가 실사용/실기기로 직접 검증까지 마침 — 지금은 비어있음 |
| `feedback/` | 실사용 피드백을 정리한 긴 로그 — 지금은 비어있음(구현 시작 전) |
| `initreq/` | 프로젝트 착수 시 클론해둔 참고 레포(quad v1, fusion, vide, rbvm, tbox, code-docker) + 원본 요청(`req.md`, `raw-userinput.md`) + `quad2-try`(이전에 시도했다 폐기한 v2 재작성 시도 — 리서치 완료, 결론은 `research/bind-system-plan.md`) — 읽기 전용 리서치 소스, 여기 내용을 옮기지 말고 항상 원본 그대로 유지 |

`research/`의 문서가 설계 확정되면 `base/`로 승격(또는 구현 착수 시
`qa-request/`행). 지금은 구현 라운드 전(설계 단계)이라 전부 `base/`/`research/`에만
있음.

## `base/` — 결정된 것, 프로젝트 전체 컨텍스트

| 문서 | 내용 |
|---|---|
| `architecture.md` | quad-v2 전체 아키텍처 확정 사항 요약(제일 먼저 볼 문서) |
| `quad-v1-architecture.md` | v1(`initreq/quad`) 내부 동작 스냅샷 — "이 문제를 안 반복하려면"의 기준선 |
| `comparison-fusion-vide.md` | Fusion/Vide 아키텍처 비교 리서치 — 설계 결정 근거 자료 |
| `lifecycle-pattern.md` | rbvm의 `Connected`+GC 관용구를 quad-v2가 채택하는 방식 |
| `store-semantics.md` | Store는 부작용 허용이 기본, 별도 State 프리미티브는 안 만듦 |

## `research/` — 아직 착수 전, 상의 필요

| 문서 | 내용 | 우선순위 |
|---|---|---|
| `bind-system-plan.md` | pluggable key/value 핸들러 레지스트리 — `process`/`retract` 디스패치 모델, Ref, quad2-try 리서치 결과. 핵심은 확정, 세부 시그니처만 남음 | 최상 — 다른 모든 설계가 이 위에서 조립됨 |
| `module-lifecycle-plan.md` | 프로바이더 패턴, bind/store 구현 책임 분리 — 확정됨 | 최상 — 확정, 구현 착수 시 API 세부만 조정 |
| `slot-plan.md` | 뮤터블 자식 배열, 엄격한 단일 마운트 소유권, 재마운트 시 throw | 상 — bind-system 확정 후 |
| `tween-plan.md` | 트윈을 Store 밖 특수 bind key로 처리, 기본 오버라이드는 Cancel | 중 — 세부 옵션만 남음 |
| `purity-and-effects-plan.md` | 컴포넌트 "순수성"이 아니라 "이식성" 문제로 재정의 — 문서 경고 수준으로 확정 | 하 — 문서화 성격, 급하지 않음 |
| `existing-instance-bind-plan.md` | 이미 생성된 인스턴스 재바인드 — 착수 안 하되 "미지원" 확정도 안 함, 열린 가능성 유지 | 하 — v2 초기 스코프 제외 |

## 참고

- **저장소 소유자가 답해야 할 질문 전체 취합**: `.claude/question.md`
- **사람만 할 수 있는 일(로컬 조작/결정)**: 루트 `HUMAN_TODO.md`
- **원본 브레인스토밍(raw chain-of-thought)**: `.claude/initreq/raw-userinput.md`,
  `.claude/initreq/req.md` — 위 문서들로 나누기 전의 원본, 참고용 백업이니 그대로 둘 것
