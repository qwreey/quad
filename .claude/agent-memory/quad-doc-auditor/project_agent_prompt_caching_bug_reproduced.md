---
name: agent-definition-loads-from-committed-head
description: My loaded definition comes from the committed HEAD of quad-doc-auditor.md, not the working tree — uncommitted edits are invisible to me. Resolved 2026-08-16; the earlier "cache" framing was wrong.
metadata:
  type: project
---

내가 받는 지시문은 `.claude/agents/quad-doc-auditor.md`의 **커밋된 HEAD
버전**이다. 워킹트리에만 있는(아직 커밋 안 된) 편집은 나에게 안 보인다.

**Why:** 2026-08-16에 여러 라운드가 "정의 파일이 최신본과 다르다"고
반복 보고했고, 한동안 "세션/워크플로 시작 시점에 캐시된 스냅샷"으로
설명됐다. 그 가설은 **반증됐다** — 한 라운드가 자기가 받은 지시문이
blob `92b9484`, 즉 *그 시점 HEAD 커밋*의 버전과 바이트 단위로 같음을
확인했고, 그 HEAD는 세션 시작 시점이 아니라 세션 도중에 만들어진
커밋이었다(메인 세션이 `git rev-parse`로 독립 확인). 즉 정의는 커밋될
때마다 갱신된다. 같은 정정이 오래 미확정이던 도구 문제도 풀었다:
**`memory: project`가 Write/Edit을 딸려온다는 진단이 맞았고**, "옵션을
뺐는데도 그대로 주어진다"고 보였던 건 그 제거가 아직 커밋 안 됐던
탓이었다.

**여전히 미해결**: `tools:` 필드가 그대로 반영되지는 않는다 —
frontmatter에 적힌 Grep/Glob이 실제로는 안 주어지고, 적혀 있지도 않은
`advisor`가 주어진 라운드가 있었다. 그래서 "파일을 고치지 않는다"는
규칙은 도구 유무가 아니라 **행동 규약**으로 지킨다.

**How to apply:** 내 지시문이 최신이 아닌 것 같으면 그건 코퍼스 정합성
문제가 아니라 **아직 커밋 안 된 편집**이라는 뜻이다 — "corpus contradiction"
발견으로 올리지 말고, 관찰만 한 줄 보고해라. 보고할 땐 추측하지 말고
대조 가능한 형태로 줄 것: `git rev-parse HEAD:.claude/agents/quad-doc-auditor.md`와
내가 받은 텍스트를 비교해 blob 해시로 말하면 메인이 1차 근거로 승격시킬 수
있다(실제로 이 정정이 그렇게 나왔다 — 근거 없는 자기 보고는 깎이고,
대조 가능한 자기 보고는 채택된다). 지금 유효한 규약의 소스는
`.claude/agents/quad-doc-auditor.md` 상단 배너.
See [[project_quad_corpus_structure]], [[project_agent_memory_self_reference_risk]].
