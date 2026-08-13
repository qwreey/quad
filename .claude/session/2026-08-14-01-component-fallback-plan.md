# 2026-08-14 첫 번째 세션 — 컴포넌트 에러 격리 유틸 `Fallback` 백로그 신설

## 배경

사용자가 컴포넌트마다 개별적으로 `pcall`을 직접 감싸는 게 실용적이지
않다고 지적 — 매 컴포넌트 호출 자리마다 손으로 `pcall`을 반복해 쓰는
대신, 컴포넌트 함수 하나를 받아 에러 시 자동으로 플레이스홀더를 그려주는
버전으로 바꿔주는 아주 단순한 유틸을 요청. 사용자가 직접 제시한 모양:

```
Fallback((T...)→OriginalComp, (errorMessage)→ErrorComp) → (T…)→OriginalComp|ErrorComp
```

클린업 동작(언마운트/리소스 해제)이 목적이 아니라, 실제 에러가 났을 때
디버깅이나 프로덕션 유저 리포트를 편하게 만드는 게 유일한 목적이라고
명시. `ErrorComp`가 추가 상태/props가 필요하면 `Fallback`이 그걸 신경 쓸
필요 없이 `onError` 자체를 커링해서 만들면 된다는 점도 사용자가 직접
짚음. "이걸 백로그로 작성해봐, 워크트리에서 작업해"라고 요청.

## 확인한 것 — 기존 결론과의 관계

`research/additional-primitives-plan.md`를 확인한 결과, 이미 "Error
Boundary는 빈 자리 아님 — `pcall(MyComp, props)`만으로 React Error
Boundary와 같은 격리 효과를 프레임워크 지원 없이 얻는다"는 결론이 확정돼
있었음(2026-08-06~07 세션, 이 문서는 이후 "새로 열린 설계 질문 없음"으로
배경 자료화됨). 사용자의 `Fallback` 요청은 이 결론을 뒤집는 게 아니라
정확히 그 결론이 지목한 메커니즘(`pcall(MyComp, props)`)을 감싸는 얇은
편의 함수 — `Operator` 콤비네이터가 `:Compute`/`:Apply` 위에 얹힌 것과
같은 관계이므로, `additional-primitives-plan.md`를 다시 열지 않고 새
research 문서로 분리하는 게 맞다고 판단.

`research/debug-tooling-plan.md`가 이미 확인해둔 선례(Vide/Fusion 둘 다
`xpcall`+`debug.traceback`으로 에러 나는 순간에만 스택을 찍는 패턴)도
같이 참고해, 에러 트레이스 캡처 메커니즘을 새로 발명하지 않고 재사용하는
방향으로 스케치.

## 한 일

- `research/component-fallback-plan.md` 신설 — 동기, 제안 API(`Fallback(original, onError)`),
  메커니즘 의사코드(`xpcall`+`debug.traceback`), 커링 관용구, 기존
  "Error Boundary는 빈 자리 아님" 결론과 안 부딪히는 이유, 열린 질문
  (pcall vs xpcall 트레이드오프, `xpcall` 에러 핸들러 배선 실측 필요,
  패키지 배치, 이름, 프로덕션 동작) 정리. **설계 확정 아님 — 순수
  백로그**, 사용자가 어떤 결정도 아직 내리지 않음.
- `.claude/README.md` research 표에 새 행 추가.
- `CLAUDE.md` "지금 할 일" 4번 백로그 목록에 `Fallback`을 형제 항목
  (`quad-mock`/`quad-debug`/문서 사이트/`Operator`)과 나란히 추가, 상세
  링크 목록에도 `component-fallback-plan.md` 추가.

## 반영 상태

새로 연 설계 질문 없음(전부 문서 신설 자체가 목적) — `question.md`에
낮은 우선순위 항목으로 포인터 추가는 이 세션 안에서 같이 처리.
`doc-check.py`는 워크트리에 `.claude/` 전체가 없어(아래 "워크트리 관련
메모" 참고) 메인 체크아웃에 결과 반영 후 그쪽에서 실행.

## 워크트리 관련 메모 (재발 방지용, 코드 리뷰로 정정됨)

**[정정, 같은 세션 후속 `/code-review`]** 최초 기록("`.claude/`와 루트
`CLAUDE.md`/`ROADMAP.md`/`HUMAN_TODO.md`가 git에 커밋돼 있지 않음")은
틀렸음 — `git ls-files`로 재확인한 결과 이 파일들 전부(`.claude/` 208개
포함) 로컬 `main` 브랜치엔 정상적으로 커밋돼 있음. 실제 원인은 따로
있었음: `EnterWorktree`가 기본값(`baseRef: "fresh"`)으로
**`origin/<기본브랜치>`**(이 레포는 `origin/master`)에서 새 브랜치를 침 —
그런데 `origin/master`는 `.claude/` 파일이 **0개**
(`git ls-tree -r origin/master -- .claude`로 확인, `CLAUDE.md`도 없음). 이 레포의 계획
문서(`.claude/`, 루트 `CLAUDE.md`/`ROADMAP.md`/`HUMAN_TODO.md`)는
`SAFETY.md`의 "GitHub 등 외부 git 호스팅에 이 레포를 push하지 말 것"
규칙에 따라 **로컬 `main`에만 있고 `origin`(GitHub)엔 의도적으로 한 번도
push된 적 없음** — 그래서 `origin/master`에서 갈라친 fresh 워크트리는
계획 문서가 원천적으로 빠진 채 시작되는 게 **의도된 안전장치**이지,
문서가 untracked라서가 아님.

**재발 방지 — 다음에 이 레포에서 "워크트리에서 작업해"라는 지시를 받으면**:
계획 문서를 편집해야 하는 작업이면 `EnterWorktree`에 `path`로 로컬
`main`에서 이미 갈라친 워크트리를 쓰거나, 필요한 파일만 메인 체크아웃
(로컬 `main`)에서 복사해 편집 후 다시 복사해 반영하는 이번 방식을 그대로
반복하면 됨 — 다만 "git에 안 올라가 있어서"가 아니라 "`origin/master`
브랜치엔 애초에 이 문서들이 없어서(의도된 것)"라는 정확한 이유로
이해하고 시작할 것.
