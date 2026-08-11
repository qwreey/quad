<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-09 두 번째 세션 — `.claude/` 코퍼스 전체 stale 마커 감사·수정,
무효화된 인라인 서사 archive 이전

새 설계 결정 없음, 순수 문서 정리 세션. 서브에이전트 4개를 병렬로 띄워
`.claude/` 전체(30여 개 문서 + `ROADMAP.md`/`HUMAN_TODO.md`/`SAFETY.md`/
`archive/`)를 클러스터별로 감사, "이미 해소됐는데 미해결로 표시된 것"과
"문서 간 모순"을 찾아 전부 직접 수정(커밋 전 상태 기준). 이어서 사용자
요청으로 두 번째 라운드 — 뒤집혔거나 무효화된 설계가 정정 표시만 붙은 채
본문에 전체 서술로 남아있는 곳을 찾아 기존 `archive/*-reversed.md`/
`*-rejected.md` 컨벤션대로 이전(본문엔 결론+포인터만 남김), 컨텍스트
낭비 방지 목적. 이것도 서브에이전트 3개 병렬 감사로 후보를 찾은 뒤 직접
판단해 적용.

**1차 라운드 — stale 마커/모순 수정 (7개 파일)**:
- `bind-system-plan.md`: `Ref` 이름이 "용어 정리 재검토 대상"으로 남아있던
  것 — 2026-08-08 다섯 번째 세션에서 이미 확정됐는데 반영 안 됨 → 해소
  표시로 정정. `component-composition-plan.md` §4-2 인용 오류(그 절은
  실제로 다른 내용을 다룸 — Ref 필드 충돌 없음의 근거를 잘못 인용)와
  폐기된 `StoreSource` 프록시와 혼동될 수 있는 "Source 양방향 프록시"
  표현도 정정.
- `documentation-content-map.md`: 폐기된 `myStore.key = value` 대입
  문법이 예시로 남아있던 것(같은 파일 바로 다음 줄은 `:Set()`으로 옳게
  써서 자기모순) → 정정.
- `ROADMAP.md`: 세션 인용 오류 2건(`git blame`으로 실제 커밋 시점 확인해
  정정 — M0의 Source/State 서브타입 항목은 "세 번째 세션", M2의
  `LifetimeHandle` 순서 역전 항목은 "네 번째 세션"이 맞음), `Bound`/
  `None` "가칭" 표기가 이미 이름 확정됐는데 안 지워진 것 2건 정정, M6에
  Slot CRUD 의미론 확정 체크박스 누락돼 있던 것 추가(`pre-implementation-audit.md`
  우선순위1이 이미 지적했던 갭).
- `question.md`: `Tag`/`Added`/`Removed`/`Merged`가 `tag-plan.md`에서
  "여기서 추적 중"이라 주장했지만 실제로 빠져있던 것 추가.
- `archive/context-rejected.md`: 다른 archive 문서와 달리 base/ 포인터가
  없던 것 보강.
- `additional-primitives-plan.md`: State/Observer를 "독립 프리미티브"로
  잘못 묶은 표현 정정(확정된 분류는 Source/Store/Ref/Modifier/Slot/DI=
  독립 프리미티브, State/Observer=파생 데이터, 2026-08-08 두 번째 세션
  "Handler는 세 번째 카테고리" 절 참고).

**2차 라운드 — 무효화된 인라인 서사를 archive로 이전 (신규 archive 4개)**:
- `archive/quad2-try-research-findings-rejected.md` — `bind-system-plan.md`에
  60줄 넘게 남아있던 quad2-try(폐기된 이전 재작성 시도) 리서치 전문(OOP
  상속/커스텀 파서/Slot 빈 스텁/`Pipe` copy-on-write 4가지 확인된 죽은
  접근 + Unix 파이프 영감이라는 원래 동기 서사)을 통째로 이전 — "반복
  조사 금지" 결론과 `state(state)` 조합 모델 포인터만 본문에 남김.
- `archive/observer-cleanup-contract-rejected.md` — `effect-plan.md`의
  "Observer 자체에 React `useEffect`식 cleanup 반환 계약을 추가하는 안"
  기각 서술(코드 예시 포함) 이전.
- `archive/keyed-collection-state-method-rejected.md` — `additional-primitives-plan.md`의
  "키 기반 동적 컬렉션 재조정을 `state:Keyed(...)` State 메소드로 두려던"
  초안 기각 서술 이전(이 프리미티브 자체는 여전히 열린 질문 — 폼 팩터
  결정 부분만 이전됨).
- `archive/debug-channel-replicatedstorage-rejected.md` — `debug-tooling-plan.md`의
  "`ReplicatedStorage` 자동 생성" 초안 기각 서술 이전.

각 archive 파일은 기존 컨벤션(`[기각됨]` 제목, "현재 유효한 설계" 포인터,
`quadnomicon` 소재 메모)을 그대로 따름, `README.md`의 archive 인덱스도
4개 항목 추가로 동기화 완료.

**의도적으로 손 안 댄 것들**: `bind-system-plan.md`의 PreRef pre-pass
위치 관련 기각 서술, `lifecycle-pattern.md`의 `canExecute` 시그니처
재정정 단락, `modifier-plan.md` 9-1(b)의 "동질적/이질적" 초안 — 전부
현재 설계를 정당화하는 근거로 너무 밀착돼 있어서, 분리하면 "왜 이렇게
안 했는지"가 같이 잘려나가 다음 에이전트가 같은 대안을 또 검토할
위험이 있다고 판단해 그대로 둠. `documentation-content-map.md`가 최근
추가된 5개 base 문서(`relate`/`blocker`/`effect`/`tag`/`attribute`-plan.md)의
초심자/api/심화 분류를 아직 안 갖고 있는 것도 실제 설계 판단(콘텐츠
분류)이 필요해 손 안 댐 — 문서 자신도 이미 "지금 당장 안 급함"이라고
인정하고 있음.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, 위 "다음 세션 예고"
Slot/키 기반 컬렉션 재조정도 그대로) — 이번 세션은 순수 문서 위생
작업이라 설계 우선순위엔 영향 없음.

