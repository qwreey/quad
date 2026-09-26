# 성능 실측 계획 — BREAKING 허용 주간 안에 구조를 바꿀 일이 있는지 알아내기

**상태**: research — **[2026-09-26 신설, 사용자 결정으로 착수]** → **[같은 날 밤 CLI 산술 회차 완료]** P1-CLI·P2·P2-trace·P3·P6이 `audit/perf-cli-2026-09-26/REPORT.md`로 완결(결과가 낳은 문항은 `qa-request/post-implementation-review-round13.md` §4 Q76·Q77; 프로토타입 `audit/round13-q76-proto/`). Studio 실기기 회차(P1·P4·P5·P6 실물)와 §4 문항 다섯은 사용자 기기·답 대기. 계기는 docs-review 3-1 (2)(실사용·성능 근거가 문서에 없다)의 사용자 답: *"실 사용 여부와 성능 같은건 특히 이 변경 가능 주간에 더 실측해보고 싶어. 나중에 최적화를 위해 구조적 변경이 필요해지면, 만일 그게 breaking changes 를 내야한다면 그 땐 포기해야할 수도 있게 되니까, 한번 여러 실측 구간을 내보고 싶어."* ROADMAP 백로그의 "벤치마크 스위트" 항목(2026-09-09)이 이 계획으로 착수한다. 오버뷰 01 §8은 실측이 생길 때까지 벤치마크 표를 싣지 않는다고 적었다.

## 1. 목적

두 가지를 4.0.0 전에 알아야 한다.

1. **구조를 바꿔야 하는 병목이 있는가.** 예: Slot 부기(`recompute`·오프셋 캐시), Dispatch 핸들러 탐색, Compute 전파(Revision 카운트다운·EpochMap), Property 핸들러의 값 비교. 이 중 무언가가 실기기에서 화면 프레임을 잡아먹으면 고치는 방법이 공개 표면을 건드릴 수 있다 — 그건 이 주간 안에만 싸다.
2. **문서에 실을 수 있는 근거 수치.** 오버뷰가 "싣지 않는다"로 끝나는 자리를 채운다. 비교 대상 없이 절대치만 실어도 된다(사용자 판단 — §4).

## 2. 측정 후보(우선순위순, 메인 초안)

| # | 무엇 | 왜 이게 먼저인가 | 어디서 |
|---|---|---|---|
| P1 | **대량 마운트** — `D.Frame`+`TextLabel` N개(1k/5k/10k)를 한 번에 만들어 붙이기, 프레임 시간·메모리 | 첫 화면 비용. Dispatch·Property 핸들러·Claim 경로가 다 걸린다 | Studio(실기기) + CLI mock(산술만) |
| P2 | **`Slot:List` 갱신** — N개 목록에서 1개 삽입/삭제/재정렬, 전체 교체 | 부기 O(N) 의심 지점(`recompute`, `prevKeys` 스왑은 round7에서 한 번 손봤다) | CLI mock(정확한 호출 수) + Studio |
| P3 | **Compute 전파** — 깊이 d·팬아웃 f 그래프에서 원천 하나 `:Set` | Revision/EpochMap 설계의 실비용 | CLI mock |
| P4 | **프로퍼티 갱신 폭주** — 원천 하나에 묶인 프로퍼티 M개를 프레임마다 `:Set` | 스크롤·드래그 같은 매 프레임 쓰기 | Studio |
| P5 | **Tween/Animate 다수** — 동시 트윈 N개 시작·교체(`Override`) | `Completed`/`Cancelled` 배선·gcconn 비용 | Studio |
| P6 | **GC 잔존** — 위 시나리오 뒤 `Destroy`·`collectgarbage("count")` 수렴 | 수명을 GC에 위임한 설계의 실제 회수 | Studio(mock은 `gc-probe.luau` 관용구) |

CLI mock 수치는 **산술(호출 수·할당)**만 믿고, 프레임 시간·렌더는 Studio 실기기만 믿는다(`conventions.md` — Luau 사실은 실측 뒤 주장).

## 3. 도구

- 반복 가능한 스위트 `bench/`(가칭, 레포 루트 — 이름·위치는 §4 문항): 시나리오 하나가 파일 하나, CLI에서 `luau bench/<x>.luau`, Studio에서는 rojo로 `ServerScriptService`/`StarterPlayerScripts`에 싱크해 같은 파일을 돈다(`audit/d-factory-studio-probe-2026-09-16/probe.project.json` 관용구).
- 결과는 `audit/perf-<날짜>/REPORT.md`에 회차별로(기기·버전·수치). 표로 정리되면 오버뷰 01 §8과 레퍼런스 어딘가에 링크.
- 비교 대상(v1 2.x 같은 화면, Fusion/Vide)은 §4에서 정한 뒤에만. v1은 `/code/Projects/quad-v1` worktree에 있다.

## 4. 사용자가 정할 것

1. **첫 실측 화면**: 위 P1~P6 합성 시나리오만으로 시작할지, 사내에서 v2로 옮길 첫 실제 화면(있다면)을 벤치 대상에 넣을지.
2. **비교 대상**: 절대치만 / v1 2.x 같은 화면 병기 / Fusion·Vide까지. 비교를 넣으면 공개 문서에 남의 프레임워크 수치를 싣는 것이라 정확성 부담이 커진다 — 메인 권고는 첫 회차는 절대치만, v1 병기는 이관 판단 재료로 두 번째 회차부터.
3. **기기**: 어느 기기에서 도는가(데스크톱 Studio Play만인지, 실기기 모바일까지). 사용자 기기가 지금 없으니 첫 회차 시점도.
4. **스위트 이름·위치**: `bench/`(루트) / `quad-roblox/bench/` / `.claude/luau-test/` 아래. 게시 패키지에 안 들어가야 하므로 루트 `bench/`가 무난하다는 것이 메인 권고.
5. **임계값**: "여기 넘으면 구조를 본다"의 기준 — 예: 1k 마운트 16ms(한 프레임), List 삽입 1개에 O(N) 호출이면 주의. 정하지 않으면 회차 결과를 보고 그때 정한다.

## 5. 착수 순서(사용자 답 뒤)

CLI 산술 시나리오(P2·P3)는 기기 없이 지금 만들 수 있다 → 스위트 골격 + P2·P3 첫 수치 → 사용자 기기가 생기면 P1·P4·P5·P6 Studio 회차 → REPORT → 오버뷰 §8 갱신.
