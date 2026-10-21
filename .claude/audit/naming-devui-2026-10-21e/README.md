# 이름 검토 — devui 검색 목록·가상 표·Overlay 입력 팝업 수 (2026-10-21)

세 계열(sonnet Agent, codex gpt-6-luna, Gemini 3.8 flash high)에게 같은 `prompt.md`를 줬다. 답은 각 파일. 판정은 다수안(1순위가 셋 중 둘), 셋이 다 갈리면 순위 합.

| 자리 | sonnet | luna | Gemini | 결과 |
|---|---|---|---|---|
| 1(a) 지금 여는 함수 | OpenSearchList | OpenQuickPick | OpenPicker | 셋이 갈리고 순위 합도 6·6·6 동률 → **사용자 결정(2026-10-21) `OpenSearchList`**(1(b) `SearchCombo`와 `Search`로 짝 — 메인 권고를 받음) |
| 1(b) 상자 위젯 | SearchCombo | SearchCombo | ComboSearch | `SearchCombo` |
| 1(c) 항목 | Items | Items | Options | `Items` |
| 1(d) 막힌 이유 | Blocked | DisabledReason | DisabledReason | `DisabledReason` |
| 1(e) 항목 아이콘 | ItemIcon | ItemIcon | Icon | `ItemIcon` |
| 1(f) 고름 콜백 | OnPick | OnPick | OnPick | `OnPick` |
| 2(a) 표 위젯 | VirtualTable | VirtualTable | VirtualTable | `VirtualTable` |
| 2(b) 열 글 함수 | Format | Text | Text | `Text` |
| 2(c) 행 클릭 | OnRowClick | OnRowClick | OnRowClick | `OnRowClick` |
| 2(d) 선택 키 | Selected | SelectedKeys | SelectedKeys | `SelectedKeys` |
| 3 입력 팝업 수 | BlockingCount | InputCount | InteractiveCount | 순위 합 Blocking 6 · Input 7 · Interactive 7 → `BlockingCount` |
