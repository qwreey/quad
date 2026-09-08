# .claude/ — quad-v2 계획/설계 문서 색인

이 레포 전체가 quad-v2(재작성) 프로젝트이므로, webmanager류 서브프로젝트 구분 없이
`.claude/` 바로 아래에 전부 있음. **루트 `CLAUDE.md`가 진입점** — 먼저 그걸 보고,
특정 결정의 자세한 근거/논의가 필요할 때만 아래 개별 문서를 열어볼 것.

**[2026-08-16 재구조화]** `CLAUDE.md`가 1537줄까지 불어나 사람이 검토할 수
없고 지침 준수도도 떨어져서, 주제별로 쪼개고 `@import`로 다시 합침. 지금
`CLAUDE.md`는 짧은 진입점일 뿐이고 실제 내용은 아래 파일들에 있음(앞 셋은
매 세션 자동 로드, `session-summary.md`/`question.md`는 온디맨드):

| 파일 | 무엇이 들어있나 |
|---|---|
| `conventions.md` | 언어/모델 관례 + **설계 원칙** + **작업 방식**(핸드오버 체크리스트, `doc-check.py`, `quad-doc-auditor`, SAFETY 준수 등 에이전트가 따라야 할 절차 전부) |
| `project-context.md` | 이 프로젝트가 뭔지 + 계획 문서 구조(폴더별 성격 요약 — 상세 색인은 이 README가 소스) |
| `todos.md` | 지금 할 일(우선순위순). 가장 자주 바뀜 |
| `session-summary.md` | 세션별 2~4줄 요약 색인. **`@import` 안 됨(의도적)** — 이만한 분량을 매 세션 컨텍스트에 올릴 이유가 없어 온디맨드로 둠, 선행 맥락이 필요할 때 grep해서 열 것. 자동생성 전환 예정(`research/doc-include-plan.md`) |
| `question.md` | 사용자가 답해야 할 열린 질문(우선순위순) |

## 폴더 기준

**[2026-09-08 분리 — round7 Q39 사용자 결정]** 파일 색인과 폴더 기준 전문은 **각 폴더의 `README.md`**가 소스이고(`base/`·`reference/`·`research/`·`archive/`·`qa-request/`·`audit/`·`session/`; `luau-test/`는 원래부터), 이 표는 폴더당 한 줄로 가리키기만 한다 — 옛 표는 한 셀이 17,005자까지 자라 도구 호출에서 잘렸다. `doc-check.py`의 색인 검사(base/research/archive/reference의 모든 `.md`가 색인에 있는가)는 루트와 폴더 README를 함께 본다.


| 폴더 | 기준 |
|---|---|
| `base/` | 결정 완료 + 프로젝트 전체에 걸치는 배경지식(plan/done 개념 없음) — 먼저 `base/architecture.md`. **파일 색인·기준 전문은 `base/README.md`** |
| `reference/` | 결정 자체가 아니라 다른 문서가 근거로 인용하는 온디맨드 참고 자료 + 확정된 결정의 근거 기록 — **`reference/README.md`** |
| `research/` | 아직 착수 전, 사용자와 스코프/설계를 더 상의해야 하는 것 — **`research/README.md`** |
| `qa-request/` | 구현 뒤 코드 리뷰 원장(post-implementation-review-round1 … 라운드는 계속 늘어남 — 최신 목록·각 라운드 요약은 **`qa-request/README.md`**) + 외부 모델 감사 진입점 `external-review-entry.md`. 끝난 v2 초기 구현 라운드는 `archive/v2-initial-implementation/` |
| `archive/` | 완료됐거나 완전히 뒤집힌 것(`[역전됨]`) + 끝난 구현 구간의 원장 원문 — 능동 참고 불필요. **`archive/README.md`** |
| `feedback/` | 실사용 피드백을 정리한 긴 로그 — **[2026-08-19 기준] 폴더 자체가 아직 없음**(M0/M1 스캐폴딩만으론 안 생기고 실제로 렌더링해보고 쓰는 단계부터, 첫 피드백이 생길 때 만들면 됨). `qa-request/`는 **[2026-08-18] 더 이상 비어 있지 않음**(구현 전 QA 1라운드 산출물이 들어감) — 여긴 아직 폴더도 없음 |
| `luau-test/` | 추론만으로 확정한 것을 실제 Luau로 부딪혀보는 독립 스파이크 — 상태의 소스는 `luau-test/STATUS.md`, 각 파일의 목적은 `luau-test/README.md` |
| `audit/` | 스파이크를 실제로 돌린 **실측 결과** 기록(계획 아님, 부분 확인도 그대로) — 폴더 목록·각각 뭘 확인했는지는 **`audit/README.md`** |
| `tools/` | **[2026-08-13 신설, `session/2026-08-13-09-structure-and-guardrails.md`]** 코퍼스 기계 점검 — `doc-check.py`가 깨진 파일/절 참조, README 색인 누락, 날짜 없는 시한부 주장("아직 안 돌려봄" 등), 미반영 ⚠️ 배너를 한 번에 훑음. **[2026-08-16]** 절 참조는 WARN이 아니라 **ERROR** — 판정 규칙은 `conventions.md`의 "절 인용 규약"이 소스. **중대 변경 후 커밋 전에 돌릴 것**(`python3 .claude/tools/doc-check.py`) — 수동 감사에서 나온 발견의 대부분이 이 종류였고, 실제로 문서를 쪼개다 잘못 옮긴 참조를 이게 잡아냄. ERROR는 고치고 WARN은 판단 대상 |
| `agents/` | **[2026-08-16 신설]** 프로젝트 서브에이전트 정의(`.claude/agents/*.md`, Claude Code 표준 위치). 현재 `quad-doc-auditor.md` 하나 — `doc-check.py`가 못 잡는 의미론적 stale/모순(본문 문장이 뒤집힌 결정을 여전히 서술, 개수/목록 이중 소스 드리프트 등)을 신선한 맥락에서 찾는 읽기 전용 감사자. 중대 변경 커밋 전에 위임하는 게 기본 — **[2026-08-18 재설계] 한 턴에 하나씩만 돌리고(병렬 금지) 발견이 0건인 라운드가 나올 때까지 턴을 늘리는 루프**, 수정은 메인 세션이 일괄로 함(라운드 수·범위 좁히기 규칙은 여기 안 적음 — 소스는 conventions.md)이며 절차는 `.claude/conventions.md` "작업 방식" 절이 소스(**[2026-08-16]** 이 루프를 담던 `workflows/quad-handover-audit.js`는 토큰 과다·픽스 에이전트발 부정확 서술·사용자 질의 불가 때문에 폐기됨). `tools/`의 기계 점검과 짝을 이루는 의미론적 점검 계층 |
| `agent-memory/` | **[2026-08-16 신설]** 서브에이전트가 라운드를 넘겨 유지하는 영속 메모리(`agent-memory/<에이전트 이름>/MEMORY.md`가 색인). 지금은 `quad-doc-auditor/` 하나 — 코퍼스 구조, 반복되는 실패 패턴 등을 기억해 감사 라운드마다 처음부터 파악하지 않게 함. **사람이 손으로 채우는 문서가 아니라 에이전트가 스스로 쓰는 것**이지만, `.gitignore` 대상이 아니라 커밋하면 코퍼스 일부가 되고 `doc-check.py` 검사 대상에도 들어감(감사 대상이기도 하다는 뜻 — 여기 적힌 주장도 stale해질 수 있음). **[2026-08-16 확정] 커밋해서 추적함**(사용자 결정). 사용자 논거: "실 기록이고 디펜던시도 아니고, 어차피 `SAFETY.md`에 따라 구현 시점에는 컨테이너에서 개발되며 다른 프라이빗 git에 올라가고 검토 후 머징되는거라, 문제되는 메모리 있으면(환경 노출 등) 사람이 감사처리 마지막으로 함. 결국 프로젝트 사이드 기록이고 같이 올려지는게 맞는게, 개발 환경이 다수라서 필요해보임" — 즉 **개발 환경이 여러 개라 메모리가 따라다녀야 하고**, 노출 위험은 머지 전 사람 검토가 최종 방어선. 커밋하는 쪽이 정해졌으니 여기 내용도 감사 대상이다(에이전트가 자기 메모리에 stale한 결론을 남기는 일이 실제로 있었음 — 2026-08-16에 폐기된 워크플로를 살아있는 것처럼 서술한 2건이 감사로 잡힘) |
| `session/` | 세션별 상세 로그 원문(`YYYY-MM-DD-NN-slug.md`, 시행착오 포함) — 색인은 `session-summary.md`, 폴더 규약은 **`session/README.md`** |
| `initreq/` | 프로젝트 착수 시 클론해둔 참고 레포(quad v1, fusion, vide, rbvm, tbox, code-docker) + PA님 실 코드(`artworks/`, 4차 라운드 교차검증 근거) + 원본 요청(`req.md`, `raw-userinput.md`) + `quad2-try`(이전에 시도했다 폐기한 v2 재작성 시도 — 리서치 완료, 결론은 `base/bind-system-plan.md`) — 읽기 전용 리서치 소스, 여기 내용을 옮기지 말고 항상 원본 그대로 유지 |

`research/`의 문서가 설계 확정되면 `base/`로 승격(또는 구현 착수 시
`qa-request/`행). 지금은 구현 라운드 전(설계 단계)이라 전부 `base/`/`research/`에만
있음.

## 참고

- **저장소 소유자가 답해야 할 질문 전체 취합**: `.claude/question.md`
- **사람만 할 수 있는 일(로컬 조작/결정)**: 루트 `HUMAN_TODO.md`
- **원본 브레인스토밍(raw chain-of-thought)**: `.claude/initreq/raw-userinput.md`,
  `.claude/initreq/req.md` — 위 문서들로 나누기 전의 원본, 참고용 백업이니 그대로 둘 것
