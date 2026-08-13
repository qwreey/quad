# 2026-08-14 세 번째 세션 — `Fallback`/`Traceback` 승격

`research/component-fallback-plan.md`를 `base/fallback-plan.md`로 승격.
해소된 내용:

- **`Fallback`/`Traceback`으로 분리** — `pcall` 기반 `Fallback`(trace
  없음)과 `xpcall`+`debug.traceback` 기반 `Traceback`(trace 항상 있음)을
  플래그 하나 대신 별도 함수 둘로 확정(`Ref`/`PreRef`와 같은 패턴).
- **정확한 시그니처 확정**:
  `Fallback<OkComp, ErrComp, Args...>(base: (Args...) -> OkComp, onError: (err: any) -> ErrComp) -> (Args...) -> (OkComp | ErrComp)`,
  `Traceback`은 `onError`가 `(err: any, trace: string)`을 받는 것만 다름.
- **`err: any` 확정** — Lua `error()`가 임의 값(테이블 등)을 던질 수 있음을
  사용자 REPL 확인과 스파이크 결과로 재확인, `error(msg)` 기본 호출의
  위치 접두("파일:줄: ") 캐비엇도 같이 문서화.
- **패키지는 `quad-base`**(사용자 확정), **이름은 `Fallback`/`Traceback`으로
  점유**(사용자 확정, 용어 정리 대기열 안 올림).
- 열려있던 질문 전부 해소 — 남은 건 구현 자체뿐(우선순위는 그대로 맨 뒤).

## 반영

- `base/fallback-plan.md` 신설(승격), `research/component-fallback-plan.md`
  삭제.
- 스파이크 스크립트를 `research/`에서 `audit/fallback-xpcall-spike.luau`로
  이동, 내부 함수명도 `Fallback`→`Traceback`으로 정정(실제 검증 대상과
  일치시킴), 재실행으로 통과 재확인.
- `audit/fallback-xpcall-verification.md` 신설(실측 결과 기록).
- `README.md`(base/research/audit 표), `question.md`(해소 항목 제거),
  `archive/question-resolved.md`(요약 테이블에 추가), `CLAUDE.md`(4번
  백로그 목록), `research/lifecycle-hooks-plan.md`(경로 참조 정정)
  전부 동기화.
