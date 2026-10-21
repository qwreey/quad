# 이름 검토 — devui 팝업 다섯 (2026-10-21)

`research/devui-popup-model-plan.md` 1·2단계의 이름. 같은 프롬프트(`prompt.md`)를 세 계열에 물었고 답 원문은 `codex-gpt-6-luna.md`·`gemini-3.8-flash-high.md`. sonnet 답은 서브에이전트 보고로 받아 아래에 요지만 둔다.

| 항목 | sonnet | luna | Gemini | 구현 |
|---|---|---|---|---|
| `Overlay:Open` 앵커 사각형 | `AnchorRect` | `AnchorRect` | `AttachTo` | `AnchorRect` |
| 팝업 몸통 | `PopupPanel` | `PopupPanel` | `PopupPanel` | `PopupPanel` |
| 좌표에서 메뉴 열기 | `ContextMenu`(둘째 `OpenMenu`) | `OpenMenu` | `OpenMenu` | `OpenMenu` |
| 메뉴 달린 단추 | `MenuButton` | `MenuButton` | `MenuButton` | `MenuButton` |
| 그 팩토리 prop | `Children` | `Children` | `Menu` | `Children` |
| 메뉴 유지 | `KeepOpen` | `KeepOpen` | `KeepOpen` | `KeepOpen` |

sonnet 요지: `AnchorRect`는 `Anchor`와 접두가 같아 관련 옵션으로 읽히지만 문서에 "Anchor = 내용의 기준점, AnchorRect = 붙는 대상"을 적을 것; `ContextMenu`는 업계 관용어지만 위젯처럼 보여 "호출하면 즉시 열린다"를 밝혀야 함; `Children`은 `Menu`와 같은 규약; `NoClose`는 Window의 "닫기 단추 없음"과 충돌.
