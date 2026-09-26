# E48 — `q.Claim` × `D.Mapper` 트리 모양 차등 퍼저 (2026-09-27, round13 자율 루프)

레포 파일 무변경. CLI `luau` + quad-base mock, 설치본 한 벌(`quad-roblox/luau_packages` — `typing-limits.md` 8.34), 프로바이더는 실물
QuadRoblox(`EngineOps.nativeFindChild` = `FindFirstChild` + `IsA`, `LifetimeHandle.nativeClaim`/`isClaimed`)를 mock 인스턴스 위에서.
`relink.sh` 뒤 `quad-roblox/luau_packages/.pesde/…/quad_base/src`가 작업 트리 `quad-base/src`와 `diff -r` 동일함을 확인.

## 파일

| 파일 | 역할 |
|---|---|
| `harness.luau` | 프롤로그(spec.claim과 같은 심 + TweenInfo/Enum). `newQ()` = `Quad.New():UseProvider(QuadRoblox)` — 모듈 인스턴스마다 claim 레지스트리가 따로 |
| `model.luau` | 참조 모델(아래 규칙 R3~R8의 1패스) |
| `rng.luau` | 결정적 PRNG(CLI에 `Random` 없음) |
| `fuzz.luau` | 메인 차등 퍼저 — `luau fuzz.luau -a <seeds> <start> [debug] [modelPath]` |
| `mut-*.luau` | 모델 결함 주입(퍼저 검출력 확인용) |
| `axes.luau` | 별도 축 (a)~(h) |
| `perf-split.luau` | (h) 1패스 단독 vs 전체 시간 |
| `out-*.txt` | 실행 결과 |

## mock 한계(표시)

- `IsA`는 `ClassName` 등치(상속 없음 — E29, `mock.luau:370-374`) → 하위/추상 클래스 매퍼(R20)는 판정 불가.
- `FindFirstChild`는 children 삽입 순서의 첫 일치, 이름 비교는 `==`(숫자 키 `1`을 `"1"`로 강제 변환하지 않음 — `mock.luau:377-384`).
- mock `Parent =` 재대입은 같은 부모여도 형제 순서 끝으로 옮긴다(물리 순서는 비교 대상에서 뺐다 — Roblox는 의미 없음).
- `Instance.new`(mock)는 QuadRoblox 레지스트리 기준 미claim(= Studio/Clone 템플릿 대역). 선소유 자식은 `q.Backend.nativeClaim` 또는 `D.New`로 만들었다.

## 규칙 (모델이 옮긴 것)

| # | 규칙 | 정본 | 코드 |
|---|---|---|---|
| R1 | 첫 인자가 Instance 아님 → `Quad0033` | roblox/04:97 | Claim.luau:188 |
| R2 | 둘째 인자가 디스크립터 아님 → `Quad0034` | roblox/04:98 | Claim.luau:191 |
| R3 | 디스크립터 재사용(다른 Claim·한 트리 두 자리) → `Quad0027` | roblox/04:99·157, errors/06:22 | Claim.luau:98-99 |
| R4 | 서로 다른 두 디스크립터가 같은 Instance → `Quad0028` | errors/06:30 (roblox/04 표엔 없음 — 발견 A1) | Claim.luau:102-105 |
| R5 | 루트든 자식이든 이미 소유 → `Quad0029` | roblox/04:101·107·111-112 | Claim.luau:114-115 |
| R6 | props 비테이블 → `Quad0030` | roblox/04:100 | Claim.luau:120-121 |
| R7 | 디스크립터가 든 숫자 키가 양의 정수 아님 → `Quad0031` | errors/06:54, roblox/04:107("배열 키 검사") | Claim.luau:133-134 |
| R8 | 자식 부재·클래스 불일치 → `Quad0032` | roblox/04:102·124 | Claim.luau:146-148 |
| R9 | 1패스 실패는 아무것도 claim·소진·변경하지 않고, 고친 재시도가 된다 | roblox/04:107, how-to 07:187 | Claim.luau:198-200 |
| R10 | 성공: 해석된 Instance 전부 소유, 안쪽부터 props 적용, 숫자 자리가 Instance로 제자리 치환, 반환은 `inst` | roblox/04:46·71-78 | Claim.luau:163-178 |
| R11 | 성공 뒤 디스크립터는 소진(재사용 `Quad0027`) | roblox/04:157 | Claim.luau:168 |
| R12 | 매핑 자식·`D.<Class>` 새 자식·`q.None` 혼합이 `D`와 같은 경로(오프셋 = 앞 자리 길이 합) | roblox/04:78-90 | Claim.luau:178 |
| R13 | 이름 중복은 UB(`FindFirstChild`가 고르는 쪽) | roblox/04:124, how-to 07:217 | — |
| R14 | 루트 디스크립터의 키는 무시(debug 한 줄) | roblox/04:31, core/01:184 | Claim.luau:195-197 |
| R15 | 적용 단계(drive) throw는 claim이 남는 UB | roblox/04:107 | — |
| R16 | 매핑 안 한 자식은 건드리지 않음(부기 어긋남은 사용자 책임) | roblox/04:114-118 | — |
| R17 | 여러 quad 인스턴스의 claim·파괴된 Instance claim은 UB | roblox/04:112-113 | — |
| R18 | `props.Parent` 금지 | roblox/04:137 | — |
| R19 | 루트 클래스 대조 — **정본 없음**(round13 Q84) | — | — |
| R20 | 하위 클래스 자식은 통과(`IsA`) — mock 판정 불가 | roblox/04:124 | EngineOps.luau:101-106 |

모델의 판정 순서(정본에 없음 — 미정 칸 U1): DFS 전위, 노드마다 0027 → 0028 → 0029 → 0030, 그다음 자식 자리를 배열부 순서로(자리마다 조회 0032 → 재귀), 해시부(0·음수·소수 키)는 배열부 뒤라 0031은 형제들의 0032 뒤.

## 메인 퍼저 결과

프리팹: 깊이 1~4, 자식 루트 0~6·그 아래 0~4, 이름 풀(루트 아래 7개·그 아래 4개 — 중복 잦음), 클래스 7종(Frame·TextLabel·ImageLabel·TextButton·
ScrollingFrame·Folder·Part(`newMapperClass`)), 노드 4% 선소유(`nativeClaim`)·루트 3%·템플릿에 꽂힌 `D.New` 자식 10%.
디스크립터: 자식 부분집합을 무작위 순서로, 키 누락 4%·클래스 교체 5%, `D.New` 새 자식 15%·`q.None` 8% 섞음, 같은 디스크립터 두 자리 3%·같은 키 두 번째 디스크립터 3%·
옛 Claim에서 소진된 디스크립터 1%·비정수 키 2%·props 비테이블 1%·루트 소진 2%·루트에 키 5%.
실패마다: ID 대조 + 전 노드 claim/props/Parent 무변경 + 디스크립터 미소진 + 같은 호출 재시도 동일 ID + 깨끗한 디스크립터로 재Claim 성공.
성공마다: claim 집합 = 해석 집합 ∪ 선소유, 매핑 노드 props 값, 숫자 자리 Instance 치환, 새 자식 Parent, `getOffsetAt` 전 자리, 소진, 재사용 `0027`, 같은 루트 재Claim `0029`.

| 실행 | 시드 | 성공 | 실패 ID 분포 | 차등 |
|---|---|---|---|---|
| `out-fuzz-1.txt` | 1~20000 | 9523 | 0027 293·0028 376·0029 1321·0030 375·0031 296·0032 7816 | 0 |
| `out-fuzz-2.txt` | 20001~40000 | 9384 | 0027 309·0028 399·0029 1295·0030 418·0031 366·0032 7829 | 0 |
| `out-fuzz-debug.txt`(`q.debug = true`) | 50001~55000 | 2397 | 0027 91·0028 104·0029 310·0030 110·0031 76·0032 1912 | 0 |

이름 중복을 밟은 시드(R13 UB — mock 첫 일치로 모델링) 약 37%, 차등은 그쪽도 0.
결함 주입(`out-mutants.txt`, 3000 시드): 클래스 대조 제거 630 차등, 0028 제거 63, claim 집합 누락 170 — 검출. 0029↔0030 순서 교환은 0(두 결함이 한 노드에 겹치는 생성이 드묾 — 순서 축의 검출력은 낮다).

## 별도 축 (`out-axes.txt`)

- (a) 1패스 실패(깊이 2 부재) → claim 0·`_fired` false, 트리를 고친 뒤 **같은 디스크립터**로 성공. 적용 단계 실패(`Bogus` 키 → `Quad0076`) → 루트·자식 claim·자식 props 적용·소진이 남고, 새 디스크립터 재시도는 `Quad0029`(R15 문서대로). 문자 키 디스크립터는 `Quad0076` + 루트 claim 잔존(Q85 기지 — 재확인만).
- (b) 매핑 자식을 `slot:Add` → `Quad0172`, 정적 자리 `D.Frame{ child }` → `Quad0160`, `q.dispose(child)` → `Quad0179`(Q58), 바인딩 유지. `q.dispose(root)` → 전 트리 파괴·claim 해제·`src:Set` 무해. `root:Destroy()` 연쇄 → 자식 `isClaimed` false, Set 무해. 파괴된 루트 재Claim → `Quad0225`(§7-13 UB 문서대로). Slot 원소를 템플릿으로 옮겨 매핑 → `Quad0029`, 루트 claim 0.
- (c) 다른 Claim 재사용·한 트리 두 자리·소진된 자식 디스크립터를 루트로 → 전부 `Quad0027`. 자기 props에 자기를 넣은 디스크립터 → 조회가 먼저라 `Quad0032`. 1패스 실패한 디스크립터는 고쳐서 재사용 가능. 키 있는 디스크립터를 루트로 쓰면 성공(키 무시), 그 뒤 자식으로 쓰면 `0027`.
- (d) 이름 `"."`·`"a.b"`·`""`·`"1"`·`" "`·`"Title "`·`"a/b"`·`"日本"` 전부 mock 성공. 숫자 키 `1`(자식 `"1"`)·`true`·`nil`·`MapperRoot` 자식 키 → mock `Quad0032`(claim 0). 매핑 자식 props의 `Name` 변경은 적용됨(조회는 1패스에 끝남).
- (e) `newMapperClass("GuiObject")` 자식 → mock `Quad0032`(엔진은 `IsA` 통과 예상 — 실기기). 루트 `M.TextLabel` over Frame → 성공(Q84 기지), 루트 `newMapperClass("GuiObject")` → 성공.
- (f) 매핑 자식의 `q.OnChange`·`q.Out`·Tween(`State<Tween>` 두 번째 값) 전부 붙음(OnChange 발화, Out 소스 갱신, 트윈 1개 대상 = 매핑 자식).
- (g) 두 모듈 인스턴스: A가 claim한 루트를 B가 Claim → **성공, 둘 다 `isClaimed` 참**; A가 `D.New`로 만든 자식을 B의 매퍼가 매핑 → 성공(이중 소유); A의 디스크립터를 B.Claim에 → 성공(브랜드·`MapperRoot` 공유); B.Claim props에 A.Source → claim 뒤 drive에서 `Quad0106`, B 쪽 claim 잔존.
- (h) `out-perf.txt`: 직계 자식 1000을 전부 매핑 16ms(1패스 5ms), 2000 41ms(15), 4000 124ms(60) — 1패스는 키마다 선형 `FindFirstChild`라 직계 자식 수에 대해 제곱(mock 기준). 루트만 매핑(자식 1000 미매핑) ~0ms, 깊이 200 체인 6ms.

## 발견

- **A1 (문서, LOW)** roblox/04 에러 표(95-102행)에 `Quad0028`·`Quad0031` 행이 없다 — 107행은 "배열 키 검사"를 1패스 항목으로 적고 errors/06:26·50은 둘 다 Claim 에러로 싣는다. 재현: `M.Frame(M.Root)({ M.TextLabel("Title")({}), M.TextLabel("Title")({}) })` → `0028`; `{ [0] = M.TextLabel("Title")({}) }` → `0031`(퍼저 775·662건).
- **A2 (문서, LOW)** roblox/04:101·111-112, errors/06 `Quad0029` "언제", how-to 07:159-160·182-183이 "`D.New`로 만든 것은 이미 소유 → already claimed"라 단정하지만 소유 판정은 모듈 인스턴스별이라 다른 `Quad.New()`의 `Claim`은 통과한다(축 g). core/06:50(`Quad0241`)은 이 한정을 이미 적는다.
- **B (코드)** 0건 — 45,000 시드 차등 0.
- **U1 (미정)** 한 호출에 결함이 여럿일 때 어느 ID가 나는지(판정 순서)는 정본에 없다 — 모델의 순서(위)와 100% 일치했을 뿐.
- **U2 (미정, Q85 부류)** 교차 인스턴스 값(`Quad0106`)도 1패스가 안 보는 순수 술어라 적용 단계에서 claim을 남긴다(축 g 넷째 줄).
- **U3 (미정)** 자식 키가 문자열이 아닐 때(숫자·불리언·nil)의 결과는 백엔드 정의(코드 주석 Claim.luau:139-141) — mock은 `0032`, 엔진은 숫자 강제 변환·원시 에러로 갈릴 것(실기기).
