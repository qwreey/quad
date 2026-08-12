# 2026-08-12 스무 번째 세션 — `State` 이름 최종 확정, use-after-destroy 안전망 범위 재검토로 확정 기각

## `State` 이름 확정

사용자가 용어 정리 라운드 1순위였던 `State`를 "그걸로 충분한듯"이라고
확정 — `Computed`/`Derived` 등 대안 검토 종료, 현재 이름 그대로 유지.
`question.md` 1번 절 반영.

## use-after-destroy 검증 안전망 — 재검토 후 최종 기각

**배경**: 직전 세션(열여덟 번째)에서 이미 "고칠 필요 없음"으로 정리했으나,
Claude가 그 문서에 "quad-debug로도 안 커버함"이라고 쓴 문장이 너무 강하게
들려 재확인을 요청했음. 사용자가 이 기회에 "정말 검토할 이유가 있는가"를
근본부터 재검토해달라고 요청, 구체적 근거를 제시.

**사용자 논지**:
1. 제대로 된 use-after-destroy 검증은 (a) 등록된 모든 함수/클로저를
   추적해 `inst` 사용을 전부 조사하거나 (b) `inst`를 래핑해 이후의
   읽기/쓰기를 가로채야 함 — 이건 quad가 손댈 문제가 아니라 Instance
   가상화/추적을 전문으로 하는 rbvm 같은 라이브러리의 영역. quad가
   이걸 재발명하면 그 자체로 오버엔지니어링이고, 필요하면 rbvm 같은
   전문 도구를 병행해야 함 — quad 혼자 모든 `inst`를 추적하는 건
   못 함(Claude 동의).
2. quad-debug는 quad-base/quad-roblox 관점에서 quad 자신이 만들어낸
   효과를 설명하는 유틸일 뿐 — 외부에서 Property를 셋팅하는 것 자체는
   원래부터 관심사가 아님(`research/debug-tooling-plan.md` "외부 변경
   감지" 절이 이미 이 경계를 명시해뒀음을 Claude가 확인).
3. 실제로 use-after-destroy가 발생할 수 있는 자리는, quad가 이미
   케어 안 하기로 확정한 요소들(Ref 등)이 정말로 외부로 반출되는
   경우뿐 — 이미 권장 안 하는 패턴. Ref는 자식으로 넘기거나 본인이
   쓰는 게 관례(React `useRef`와 동급) — **이 관례가 문서에 명시적으로
   적혀있지 않았다면 지금 적어달라는 요청.**
4. quad가 세팅한 `Tag`/`Attribute`/`Tween`에는 더 자세한 전용 디버깅
   유틸을 제공할 수 있음 — 모든 요소에 `Destroying`을 Connect해서
   범용 안전망을 만드는 건 동의 못 함, 그쪽 전용 디버깅에 투자하는 게
   나음.

**Claude 검토 결과 — 전부 동의.** 추가로: `Ref`의 사용 관례("만든
컴포넌트 자신이 쓰거나 자식에게 넘김, 경계를 넘어 반출/전역 보관 안 함")가
`base/bind-system-plan.md`의 Ref 절엔 "얻어진 뒤 어떻게 쓰는지는 라이브러리
책임 범위 밖(사용자 자유)"이라고만 적혀있어 정작 그 관례 자체가 문서에
없었던 실제 갭이었음 — 이번에 명시적으로 추가.

## 반영

- `base/bind-system-plan.md`: "Ref — 도입 확정" 절에 "권장 관례" 문단
  신설 — useRef급 스코프 관례를 명문화, use-after-destroy가 발생 가능한
  유일한 자리로 이 관례 위반을 지목.
- `research/framework-comparison-findings.md`: use-after-destroy 항목을
  위 4가지 근거로 재작성(rbvm 위임, quad-debug 스코프 경계, Ref 관례
  귀결, Tag/Attribute/Tween 전용 디버깅 투자가 낫다는 판단) — 결론(안전망
  안 만듦)은 그대로, 근거가 훨씬 탄탄해짐.
- `.claude/question.md`: `State` 해소 표시 반영.
