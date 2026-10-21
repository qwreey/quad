# 이름 검토 — devui 후보 묶음 다섯 (2026-10-21)

devplorer 후보 목록(`feedback/devplorer-handover-2026-10-21.md` "만드는 중")의 복사 대화상자·선택 규칙·트리 평탄화·`VirtualRows` 보강·색 편집기 이름. 같은 프롬프트(`prompt.md`)를 세 계열에 물었고 답 원문은 `codex-gpt-6-luna.md`·`gemini-3.8-flash-high.md`. sonnet 답은 서브에이전트 보고로 받아 아래 표와 요지만 둔다.

| 항목 | sonnet | luna | Gemini | 구현 |
|---|---|---|---|---|
| 복사 대화상자 | `OpenCopyDialog` | `OpenCopyDialog` | `OpenCopyDialog` | `OpenCopyDialog` |
| 선택 규칙 모듈 | `Selection` | `Selection` | `Selection` | `Selection` |
| 그 모드 값 | `Replace`·`Toggle`·`Extend` | `Replace`·`Toggle`·`Extend` | `Single`·`Toggle`·`Range` | `Replace`·`Toggle`·`Extend` |
| 키 읽기 | `modeFromKeys` | `modeFromKeys` | `modeFromKeys` | `modeFromKeys` |
| 트리 평탄화 모듈 | `TreeRows` | `TreeRows` | `TreeRows` | `TreeRows` |
| 접근자: 목록 밖 자식 수 | `Unloaded` (> `MoreCount`) | `Extra` (> `MoreCount`) | `MoreCount` (> `Unloaded`) | `MoreCount` — 셋이 모두 갈려 순위 합(각자 1·2위)으로 |
| 자리표시 행 필드 | `Remaining` | `More` | `More` | `More` |
| 끝 따라가기 prop | `Follow` | `Follow` | `StickToEnd` | `Follow` |
| y → 행 번호 | `RowIndexAt` | `RowIndexAt` | `RowIndexAt` | `RowIndexAt` |
| 색 계산 모듈 | `ColorModel` | `ColorModel` | `ColorModel` | `ColorModel` |
| 피커 패널 | `ColorPicker3` | `ColorPicker` | `ColorPicker3` | `ColorPicker3` |
| 피커 대화상자 | `OpenColorPicker` | `OpenColorPicker` | `OpenColorPicker` | `OpenColorPicker` |
| `InputColor3` 견본 끄기 | `NoPicker` | `NoPicker` | `NoPicker` | `NoPicker` |

sonnet 요지: `Open*`은 지금 열고 핸들을 돌려주는 체계; `OpenClipboard`는 클립보드를 쓰는 API로 오해; `Select`는 동사로 읽힘; `"Single"`은 "단일 선택 모드"로 오독될 수 있음; `TreeView`는 위젯처럼 읽힘; `More`는 불리언처럼 읽힐 수 있다(이 값은 자리표시 행에만 있고 늘 0보다 크다 — 문서에 적음); `Follow`는 무엇을 따라가는지 문서에 한 줄; `ColorPicker3`은 `InputColor3`(ImGui ColorEdit3)와 짝; `NoPopup`은 대화상자라 부정확.
