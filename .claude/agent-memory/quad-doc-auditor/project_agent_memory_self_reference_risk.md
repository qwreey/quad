---
name: agent-memory-self-reference-risk
description: My own agent-memory directory can itself become a stale-claim target when a live doc describes it — check that too
metadata:
  type: project
---

`.claude/agents/quad-doc-auditor.md`(내 정의 파일)가 한때 "`memory: project`
옵션을 뺐으므로 `.claude/agent-memory/quad-doc-auditor/`는 아무도 로드하지
않는 잔여물"이라고 서술한 적이 있었는데, 실제로는 그 세션의 시스템 프롬프트에
"Persistent Agent Memory" 블록으로 이 디렉토리의 `MEMORY.md` 내용이 그대로
주입되고 있었음 — 문서의 주장이 관찰된 동작과 직접 모순(2026-08-16 핸드오버
감사에서 발견, 확실 등급).

**Why**: 이 프로젝트에서 quad-doc-auditor의 정의 파일 자체도 감사 대상
코퍼스에 포함된다는 걸 잊기 쉽다 — "내 얘기니까 예외"로 취급하면 안 됨.
또한 감사는 나를 **병렬로 여러 개** 띄우므로, `MEMORY.md` 인덱스에 각
패스가 동시에 파일을 쓰면서 lost-update가 실제로 발생했음(인덱스에 없는
orphan 메모리 파일 2개 발견). **[2026-08-16 정정]** 원래 여기 "워크플로가
라운드당 3회(`PASSES_PER_ROUND = 3`)"라고 적혀 있었으나 그 상수를 정의하던
워크플로는 폐기·삭제됐다 — 지금 패스 수는 고정이 아니라 최소 2에서 변경
규모에 따라 늘어나고, 소스는 `.claude/conventions.md`다. 동시 쓰기 위험
자체는 그대로 유효(오히려 패스가 늘면 커짐).

**How to apply**: 매 감사 라운드마다 (1) `.claude/agents/quad-doc-auditor.md`
자신의 서술이 지금 관찰되는 동작(도구 권한, 메모리 로드 여부)과 여전히
맞는지 확인할 것, (2) `.claude/agent-memory/quad-doc-auditor/MEMORY.md`가
디렉토리 안 실제 파일 전부를 인덱싱하는지 확인하고 누락되면 직접 보완할
것(이건 코퍼스 발견이 아니라 내 메모리 유지보수이므로 리포트에는 안 올림).
