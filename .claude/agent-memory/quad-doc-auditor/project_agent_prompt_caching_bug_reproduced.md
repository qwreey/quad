---
name: definition-freshness-is-unknown
description: The definition text I receive sometimes lags the file on disk and has matched no commit at all. Mechanism unknown as of 2026-08-16 — do not adopt any of the three refuted explanations.
metadata:
  type: project
---

내가 받는 지시문(`.claude/agents/quad-doc-auditor.md`)이 **디스크의 현재
파일과 다를 수 있고, 어느 커밋과도 일치하지 않을 수도 있다.** 무엇이 갱신을
트리거하는지는 2026-08-16 기준 **모른다**.

**Why:** 같은 날 이 문제에 결론이 세 번 나왔고 앞의 둘이 반증됐다 —
(1) "세션 시작 시점 스냅샷" → 반증, (2) "커밋된 HEAD에서 읽힌다" → 반증.
결정타는 한 라운드가 받은 텍스트가 **배너는 구버전인데 출력 형식 절은
신버전인 하이브리드**였고, 그 조합이 커밋된 적 없는 중간 워킹트리 상태와
일치한 것이다(`git log -S`로 확인). 반면 그 다음 라운드는 디스크 현재
내용과 바이트 단위로 같은 걸 받았다. 즉 **일관되게 낡은 것도 아니다.**
관측표와 지금 유효한 서술은 `.claude/agents/quad-doc-auditor.md` 상단
배너가 소스 — 이 메모리는 그걸 가리키기만 하고 결론을 복제하지 않는다.

**⚠️ 이 파일은 두 번이나 stale 상태로 방치됐다.** 캐시 가설로 썼다가
"커밋된 HEAD"로 고쳤는데(2026-08-16), 바로 다음 커밋이 그 결론을 뒤집었는데도
여기만 안 따라와서 감사 3라운드가 다시 잡아냈다. 라이브 문서를 고치는 세션은
`agent-memory/`가 자기 수정 범위에 있다는 걸 자꾸 잊는다 — **내 메모리도
코퍼스이고 감사 대상이다**([[project_agent_memory_self_reference_risk]]).

**How to apply:** 내 지시문이 최신이 아닌 것 같아도 **코퍼스 정합성 발견으로
올리지 마라** — 코퍼스 문서끼리 모순된 게 아니라 도구 쪽 현상이다. 대신
**대조 가능한 형태로 관찰만 보고해라**: `git rev-parse HEAD:.claude/agents/quad-doc-auditor.md`,
디스크 파일, 내가 받은 텍스트 셋을 비교해 어느 것과 일치하는지(또는 어느
것과도 불일치하는지) 말할 것. 추측으로 메커니즘을 단정하지 마라 — 그렇게
해서 두 번 틀렸다. 반영 여부가 중요한 상황이면 메인 세션이 정의에 마커
문구를 넣고 나에게 그 문구가 보이는지 묻는 방식이 실제로 작동했다.
See [[project_quad_corpus_structure]].
