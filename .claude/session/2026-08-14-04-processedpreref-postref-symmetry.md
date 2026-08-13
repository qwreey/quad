# 2026-08-14 네 번째 세션 — `ProcessedPreRef` 신설로 Length/Offset 등록 갭 해소, `PostRef` 완전 대칭화

## 배경 — 사용자 질문에서 시작된 읽기 전용 조사

사용자가 "PreRef 처리로 인해 공백이 생기면 Dispatch의 setLength/
setOffsetSource가 안 터지는가"를 물으며 **읽기 전용**을 명시(다른
에이전트가 같은 레포 파일을 편집 중이었음). Explore 에이전트로
`base/ref-plan.md`(PreRef pre-pass)와 `base/dispatch-core-plan.md`
(Length/Offset)를 조사한 결과:

- 설계상으로는 "충돌 없음"으로 다뤄져 있었음 — PreRef pre-pass가 소진시킨
  슬롯은 `Dispatch.setLength(inst,i,0)`/`setOffsetSource(inst,i,None)`으로
  등록돼야 한다고 `dispatch-core-plan.md`가 명시.
- 그런데 **누가 그 등록을 실제로 호출하는지가 어느 문서에도 없는 진짜
  갭**이었음. 소진 값이 `None`이었기 때문에, 정상 두 패스 스캔이 그
  자리를 `Dispatch.process`/핸들러 매칭 자체를 안 거치고 드라이버 루프
  자신이 `if v == None then continue end`로 직접 건너뜀 — 그런데
  Length/Offset 등록 책임은 "이 위치를 처음 매치한 Handler"에게 있다고
  못박혀 있었으니(`dispatch-core-plan.md` "Length/Offset" 절), 애초에
  매치되는 Handler 자체가 없는 그 자리는 등록 주체가 없었음.

## 사용자 제안 1 — `ProcessedPreRef` 전용 센티널 + `ProcessedPreRefHandler`

사용자가 해법 제시: PreRef pre-pass 소진 값을 `None`이 아니라 전용
센티널 `ProcessedPreRef`(단일 `{}`, `None`과 같은 급의 유니크 키)로 바꾸고,
그 값을 매치하는 `ProcessedPreRefHandler`를 정상 우선순위 레지스트리에
등록 — 이 Handler가 `setLength(0)`/`setOffsetSource(None)`을 등록하고
no-op retract를 반환. 기존 "이미 있는 걸 재활용", "매치되는 Handler가
곧 등록자"라는 원칙을 그대로 타서 특수 취급이 없어짐. `PreRefHandler`
(동적 경로 가드, 정상 스캔에 원본 `isPreRef(v)`가 걸리면 error)는 그대로
유지.

### 반영

- `base/ref-plan.md` "PreRef" 절 — `flattened[i] = None` → `= ProcessedPreRef`로
  교체, `ProcessedPreRefHandler` pseudocode 신설. 파생 서술 3곳도 같이
  정정:
  - "동적 경로 가드" Handler 설명의 "정상 두 패스 스캔에 다시 노출 안
    됨" → "이 가드 Handler에는 다시 노출 안 됨(스캔 자체엔 노출됨)"으로
    정확화.
  - "PreRef는 취소 개념이 없다"의 근거를 "체인에 안 올라감"에서
    "체인엔 올라가지만 retract가 하드코딩된 no-op(fire의 부작용을
    되돌릴 방법이 없어서)"로 정정 — `ProcessedPreRefHandler` 신설로
    "체인에 안 올라간다"는 옛 전제 자체가 깨졌기 때문.
  - sparse-table 회피 근거의 "None으로 소진" 표현을 "실재하는 센티널로
    소진"으로 일반화.
- `base/dispatch-core-plan.md` — `None` 센티널 절과 Length/Offset 절
  두 곳에서 "PreRef pre-pass 소진 슬롯도 None 목록에 포함"이라던 서술을
  제거하고, `ProcessedPreRefHandler`가 그 등록을 전담한다고 명시. `
  sourceList`가 `None`을 쓰는 이유 문단의 PreRef 인용도 갱신.
- `ROADMAP.md` M0/M8 체크리스트 — `None` 서술을 정정하고
  `ProcessedPreRefHandler` 구현 항목 신설.
- `luau-test/done/02-none-sentinel-vs-nil-holes.luau` — 주석에 센티널
  개명 사실만 추가(스크립트가 검증하는 성질 자체는 "실재하는 non-nil
  값이면 순서/`#t`가 안 깨진다"는 일반 성질이라 어느 센티널을 쓰든
  결과는 유효, 재작성/재실행 불필요).

## 사용자 제안 2 — `PostRef`도 같이, 그런데 더 단순하게

사용자가 `research/lifecycle-hooks-plan.md`의 백로그 `PostRef` 스케치도
같은 방식으로 갱신하자고 제안. 1차로 필자가 "PreRef는 소진 **후**
값이 매치 대상, PostRef는 fire가 뒤로 미뤄지니 소진 **전** 원본 값이
매치 대상이어야 한다"는 비대칭 설계를 초안으로 썼는데, 사용자가 더 나은
배선을 제시: **PreRef pre-pass가 이미 배열 전체를 index 순서로 한 번
훑고 있으니, 같은 스윕에서 `isPostRef(v)`도 같이 잡아 즉시
`ProcessedPostRef`로 소진하고 그 인스턴스를 `postRefList`(그
`Dispatch.drive` 호출 하나에만 로컬인 평범한 배열)에 순서대로 적재해두면
된다.** 그러면:

- `PreRef`/`PostRef`가 **소진 메커니즘 완전 대칭**(둘 다 pre-pass에서
  즉시 `Processed*`로 소진, 둘 다 전담 `Processed*Handler`가
  Length/Offset 등록) — 유일한 차이는 "실제 콜백을 언제 부르는가"뿐.
- 별도 후행 전체 재순회(두 번째 `for i=1,N`)가 필요 없어짐 — 두 패스가
  끝난 뒤 `postRefList`만 순서대로 소비하면 끝.
- 1차 초안이 필요하다고 짚었던 "PostRef 전용 비대칭 규칙"(원본 값이
  매치 대상, `PostRefHandler`가 raw `PostRef`를 정상 스캔에서 잡아
  등록) 자체가 안 생김.

`research/lifecycle-hooks-plan.md`의 ② 절(`OnRendered`/`PostRef`, 여전히
"의도적으로 지금 구현 안 함" 백로그 상태 그대로)을 이 설계로 갱신 — 스코프
논의((a)/(b)/(c) 선택지)도 "후행 스캔" 표현을 "`postRefList` 소비"로
정정.

## 검증

`python3 .claude/tools/doc-check.py` — 편집 전/후 모두 **ERROR 0건**,
WARN 101건(개수 동일, 기존 false-positive 그대로 — `git stash`로 대조
확인). 새로 도입한 문장이 만든 신규 WARN 없음.

## 커밋

사용자가 "지금 커밋해도 될듯"(워크트리 바깥 메인을 아무도 안 만짐)이라고
해서 커밋 `e0ef7ce`(`docs(dispatch): PreRef 소진 센티널을
ProcessedPreRef로 교체, Length/Offset 등록 갭 해소`)로 반영 — 로컬
`main`에만, push 안 함(`SAFETY.md`).

## code-review 두 차례 시도, 결과 미도착

커밋 전에 사용자가 `/code-review high`를 두 번 돌림(첫 번째 실행 도중
"커밋은 바로 하지 마, code-review 돌릴게"라고 지시). 두 번 다 8개(→5개)
관점 파인더 중 마지막 하나가 안 끝난 상태로 세션 안에서 최종 결과가
도착하지 않았음 — 사용자가 두 번째 실행도 "안 온다"며 포기하고 커밋을
바로 지시. **code-review 결과 자체는 이 세션에 반영되지 않음** — 나중에
결과가 도착하면 별도로 검토해 필요하면 후속 커밋으로 반영할 것.

## 반영 상태

새로 연 설계 질문 없음 — `ProcessedPreRef`/`ProcessedPreRefHandler`는
이미 확정된 PreRef 메커니즘의 정제(같은 결론을 특수 취급 없이 만족시키는
재배선)라 `question.md`에 올릴 항목 없음. `PostRef`/`OnRendered`는
여전히 백로그 상태 그대로(우선순위·"착수 여부 미정" 변경 없음) — 착수
시점에 이번에 정리된 대칭 설계를 그대로 가져다 쓰면 됨.
