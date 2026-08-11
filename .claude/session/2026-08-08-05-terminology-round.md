<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-08 다섯 번째 세션 — 용어 정리 라운드 정리: `Handler`/`None`·
`NoneHandler`/`Ref`/`PreRef`/`Peek`/`isState` 이름 확정, `DI`→`D`/
`canExecute`→`isAlive`는 계속 미정으로 재확인

사용자가 `.claude/question.md`의 3순위(사소함) 용어 재검토 목록을 훑으며
한 번에 여러 개를 정리 — 전부 `.claude/question.md` "1. 용어 정리" 절과
`base/module-lifecycle-plan.md`에 반영 완료:

- **`Ref`/`PreRef`/`Peek`/`isState` — 전부 현재 이름 그대로 확정(더 나은
  대안 없음).** `Ref`는 "지연 없는 확정된 값 박스"라는 정의를 재확인 —
  leaf 노드를 담는 용도로도, leaf 노드에 바인딩하는 용도로도 쓰인다는 게
  넓어진 정의에도 여전히 맞다는 근거.
- **`None`/`NoneHandler` — 확정.** `Undefined`/`Null`/`Nothing`도 검토했으나
  `Null`은 보통 "포인터가 비어있음"(0)을 뜻해 "값이 없음"이라는 의도와
  미묘하게 안 맞는다는 이유로 기각, `None`이 나음.
- **"프로바이더" → `Handler`로 확정, 기각 이유 보강.** 이미
  `module-lifecycle-plan.md`에 [해소됨]으로 반영은 돼 있었으나
  `question.md` 목록에 stale로 남아있던 걸 정리. `Processor`는 계약
  메소드 자체가 `process`라 이름이 겹쳐 거슬림, `Provider`는
  `canProvide`처럼 "공급한다"는 늬앙스인데 실제로는 처리/반응하는
  쪽이라 안 맞고 React `Context.Provider`류와도 헷갈릴 수 있음, `Plug`는
  "꽂힌다"는 어감은 맞지만 "처리한다"는 의미가 빠져있음 — `Handler`가
  계약(`isHandlable`/`priority`/`process`/`retract`) 전체를 가장 정확히
  담는다는 결론.
- **`DI` → `D`는 아직 미확정.** 사용자가 "Declarative만 남기고 D로
  줄이자"는 안을 제안 — Instance 전용이 아니라 quad-* 전반의 declare
  요소로 확장 가능하고, 엔진 종속 없이 재사용 가능하며, `D.FrameModifier`
  류 타입 프리픽스가 짧아야 한다는 실용적 이유까지 근거로 나쁘지 않은
  제안이나, 한 글자 식별자의 검색성/자기설명력 트레이드오프를 문서에서
  어떻게 보완할지가 남아 다음에 마저 결정하기로 함.
- **`canExecute` → `isAlive`도 계속 미정, 방향만 정리.** `isAlive`가 의미는
  더 정확하지만 top-level `isX` 타입 판별자 계열(`isState`/`isRef`/
  `isPreRef`/`isModifier`/`isObserver`)과 접두어가 겹쳐 "이것도 타입
  체크인가" 오해를 유발할 위험이 지적됨 — `canExecute`는 타입이 아니라
  liveness를 묻는 질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽으로
  사용자가 기욺, 구체 대안(`canRun` 등)은 다음에.
- `Brand`는 이번에도 다시 짚었지만 여전히 미정으로 재확인만 함.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). `DI`/`D`와
`canExecute`/`isAlive` 두 개만 용어 정리 라운드에 계속 남음 —
`question.md` 1순위/3순위 목록 참고.

