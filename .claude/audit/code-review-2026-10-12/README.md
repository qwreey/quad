# code-review 2026-10-12 — 코어의 그날 변경과 material 킷(10-08 이후)

**구성**(`research/consumer-kits-plan.md` 5절 5번): 파인더 sonnet 셋(코어 하나, 킷 둘 — 한 번에 둘까지) + Gemini 둘(`agy`, 격리 worktree) →
킷 발견은 opus 하나가 합쳐 사본에서 검증·분류 → 메인 판정. 코어 발견은 메인이 직접 재현·판정했다(설계 이력이 필요한 자리라 쪼개지 않음).
판정과 사용자 문항은 `qa-request/post-implementation-review-round14.md` §7이 소스 — 여기는 원문과 재현 재료다.

| 파일 | 내용 |
|---|---|
| `finder-core-sonnet.md` | 코어(`26932869..1dd458f0` — Slot 가드 창·`WhenIdle`·Property 재확인·debug 구멍 검사·릴리즈 도구·`Apply` 타입). 플래그 대조표, 프로브 열 |
| `finder-core-gemini.md` | 같은 범위를 Gemini가. 4.0.0 경계 게시 누락을 독립적으로 확인; 플래그 회귀는 못 봄 |
| `finder-kit1-sonnet.md` | 킷 — 시트·드로어·레일·앱 바·공용 입력 층 |
| `finder-kit2-sonnet.md` | 킷 — 슬라이더·시간 선택기·대화 상자·텍스트 필드·호스트 `Name` |
| `finder-kit-gemini.md` | 킷 전체를 Gemini가(틀린 주장 둘 — 없는 이벤트 `InputCancelled`, 누수가 아닌 Heartbeat — 은 추림이 기각) |
| `triage-kit-opus.md` | 킷 발견의 합본·검증·분류(A 확정·국소 고침 7 / B 결정 사항 4 / C 실기기 4 / D 개선 4 / E 기각 10) |
| `probes/probe_h.luau` | 오프셋을 따르는 화면 시뮬레이터를 얹은 mock 도우미(`lay(host)`가 화면 순서) |
| `probes/probe9.luau` | 삽입 도중 빠져나간 Slot의 플래그가 남던 회귀(고침 전 트리에서 `U flag: true`) |
| `probes/probe3.luau` | 자식의 원소 연산 창에서 조상에 자식 뒤 자리로 `Add` — 부기와 화면 순서가 갈린다(Q186) |
| `probes/chain-window-prototype.diff` | Q186 (a) 시제품 — raw 창 넷을 `raiseChain`/`restoreChain`으로(사본 기준; 깨지는 스펙은 spec.slot Q185 절 (8) 하나) |
| `probes/costM.luau` | 그 시제품의 비용 — 원소 2000개 Slot의 `Add`/`Extract`, 깊이 1·4·8(둘 다 건당 약 125 µs, 차이는 잡음 안) |
| `probes/probeM1.luau` | `:List` 재조정의 엔진 호출 안에서 같은 목록의 데이터를 다시 `Set`(Q187 — 스택 오버플로·`Quad0163`, 변경 전 트리도 같음) |

프로브는 레포 사본의 `quad-base/test/`에 복사해 `mise exec -- luau test/<파일>`로 돈다(`probe_h.luau`가 `./mock`을 require한다).
킷 쪽 고침을 잡는 스펙은 레포의 `quad-roblox-material/test/spec.reviewfix.luau`로 들어갔다.
