# 이름 검토 — devui 대화상자 (2026-10-21)

`research/devui-popup-model-plan.md` 3단계의 이름. 같은 프롬프트(`prompt.md`)를 세 계열에 물었고 답 원문은 `codex-gpt-6-luna.md`·`gemini-3.8-flash-high.md`. sonnet 답은 서브에이전트 보고로 받아 아래에 요지만 둔다.

| 항목 | sonnet | luna | Gemini | 구현 |
|---|---|---|---|---|
| 대화상자 열기 | `OpenDialog` | `OpenDialog` | `OpenDialog` | `OpenDialog` |
| 막는 범위 prop | `Modal` | `Modality` | `Modal` | `Modal` |
| 그 값 | `"None" \| "Window" \| "Screen"` | `"None" \| "Window" \| "Global"` | `"None" \| "Window" \| "Global"` | `"None" \| "Window" \| "Global"` |
| 확인 도우미 | `OpenConfirm` | `ConfirmDialog` | `OpenConfirm` | `OpenConfirm` |
| 단추 글 | `ConfirmLabel`/`CancelLabel` | `ConfirmLabel`/`CancelLabel` | `ConfirmText`/`CancelText` | `ConfirmLabel`/`CancelLabel` |
| 결과 콜백 | `OnResult` | `OnResult` | `OnConfirm` + `OnCancel` | `OnResult` |

sonnet 요지: `Open*`은 `OpenMenu`와 같은 "지금 열고 핸들을 돌려준다" 체계; `Dialog`는 선언형 위젯으로 읽힘; `Label`은 본문 `Text`와 갈라 주려고; `OnResult`는 Escape·닫기·핸들 `Close`까지 한 곳에서 받는다(둘로 나누면 어느 쪽도 안 부르는 경로가 생김) — `Close`로 닫히면 `false`라고 문서에 적을 것. `Modal = "None"`이 모달이 아님을 문서에 밝힐 것.
