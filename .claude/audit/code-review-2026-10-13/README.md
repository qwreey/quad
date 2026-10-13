# code-review 2026-10-13 — material·devui 두 킷 전체

사용자: *"material ui 쪽이나 devui 쪽은 코드리뷰 더 받아봄직 한것 같은데. 전부 진행 이후 해볼래? 아마 거의 안했던것 같아서."*
구성: 파인더 sonnet 셋(devui 전체 / material의 그날 새 코드 / material의 전날 안 본 영역) + Gemini 둘(`agy`, 격리 worktree — devui 전체, material 미리뷰 영역)
→ opus 하나가 합쳐 사본에서 검증·분류하고 고침(diff + 스펙)을 준비 → 메인이 적용·게이트·판정. 판정과 사용자 문항은 `research/consumer-kits-plan.md` 5절의
"code-review 2026-10-13" 문단이 소스 — 여기는 원문이다.

| 파일 | 내용 |
|---|---|
| `finder-devui-sonnet.md` | devui 킷 전체(약 6천 5백 줄) — 발견 열셋, 프로브 여섯 |
| `finder-devui-gemini.md` | 같은 범위를 Gemini가 — 발견 스물(추림이 여섯은 기각, 하나는 그 묶음에서 가장 큰 실기기 항목 V-C1로) |
| `finder-mat-new-sonnet.md` | material의 2026-10-13 새 코드(버튼 그룹·순서 바꾸는 목록·노치·`NumberField`·`Unit`·대화 상자 등) — `NumberField`·`Unit` 결함 일곱은 메인이 먼저 고침(`405ce844`) |
| `finder-mat-rest-sonnet.md` | material의 날짜·색 선택기, 메뉴, 선택 상자, 탭, 칩, 체크박스류, 진행 표시, 툴팁, 테마 |
| `triage-opus.md` | 합본·검증·분류 — material A 5·B 2·C 1·D 1, devui A 4·B 4·C 5·D 3, 기각 목록. A·D의 고침은 레포에 적용됨 |

`finder-mat-rest-gemini.md` — Gemini의 material 미리뷰 영역 보고(추림이 끝난 뒤 도착 — 메인 판정). 앞의 둘(앵커 파괴 뒤 남는 메뉴, 끄는 도중 `Disabled`인 스위치)은 sonnet 발견과 같아 이미 반영. 받은 것 하나: 갤러리가 `Checkbox`의 `Label` prop 대신 `Common.Labeled`로 감싸 글자를 눌러도 토글되지 않던 것과 그 조각의 틀린 주석. 기록만: `Progress/Loop`가 `Parent = nil`로 내려 둔 ScreenGui를 못 알아보는 것(머리 주석이 이미 밝힌 한계 — 고치면 부모 없는 ScreenGui를 쓰는 스펙들이 바뀐다), 날짜 칸 하나에 State 18개쯤(한 달 약 750 — 재지 않은 주장), Docked ↔ RangeDocked·색 선택기 두 모양·Checkbox ↔ Radio 라벨 배선의 중복, `MonthView.new`의 길이, 색 선택기 끌기의 연쇄 갱신(재지 않음).
