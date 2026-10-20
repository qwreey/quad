# `feedback/` — 실사용 피드백

> **[2026-10-05 신설]** quad를 실제로 소비해 보며 겪은 문제(타입 마찰·문서 공백·API 불편·성능·놓친 관용구·버그
> 의심)를 모으는 폴더. 정적 검사만으로는 실 소비자가 겪는 문제를 모른다는 사용자 판단에서 시작했다. 항목은
> 평문 한 문단씩(상황 → 재현 → quad 쪽 원인 위치 → 우회 → 제안), mock으로 재현한 것만 "버그"라 부른다.
> 여기 적힌 제안 중 새 API·이름은 사용자 결정 전까지 제안일 뿐이다.

| 문서 | 내용 |
|---|---|
| `consumer-kits-2026-10-05.md` | 첫 소비자 둘(디버그 UI 킷·Material 3 킷, 계획은 `research/consumer-kits-plan.md`)을 만들며 겪은 quad 마찰 |
| `consumer-kits-studio-qa-2026-10-07.md` | 사용자가 Studio에서 본 material 킷 시각·상호작용 QA 열한 항목과 처리 상태(원인 파악된 것은 고침, 아닌 것은 QA 대기) |
| `table-sim-2026-10-12.md` | 레포 밖 첫 실제 소비자(table-sim 게임)의 마찰 기록을 quad 쪽에서 판정한 것 — 이미 답이 있던 것, 고친 문서 공백, 사용자 결정으로 올린 것(문항은 `research/consumer-kits-plan.md` 5절), 관측으로만 받은 것. 원문은 레포 밖 `/code/Projects/table-sim/.claude/feedback/` |
| `table-sim-2026-10-16.md` | table-sim 클라이언트 UI의 quad 사용 리뷰(opus, 코드 읽기) — 스킬에 넣을 것 A1~A8(문안 초안), table-sim에 전할 코드 메모(【UB】 셋·`hand[2]` nil 우선), quad 빈칸(Spread 누적 근거 다섯·distinct 파생). 스킬 사본이 10-11에 멈춘 배포 공백 |
| `devplorer-2026-10-20.md` | devui 세 번째 소비자 devplorer(사용자 프로젝트, Dex 재구현)의 상향 보고서 판정 — quad 코어 한계 0, 문서 공백 13은 "있는데 못 찾음"(devui README·위젯 주석에서 quad 스킬로 가는 길이 없음), devui 결핍을 장치별 묶음 여섯으로(포인터 아래 맨 위 판정은 10-16 코드 리뷰 5·6·8과 같은 장치). 원문은 레포 밖 devplorer `.claude/feedback/quad-upstream-2026-10-20.md` |
| `consumer-kits-uilabs-2026-10-16.md` | 사용자가 UI Labs로 두 킷 스토리 전부를 확인한 결과 — 거의 전부 정상(HUMAN_TODO J 닫힘), 남은 지적 셋(placeholder 전환·큰 스토리 둘의 스크롤) |
