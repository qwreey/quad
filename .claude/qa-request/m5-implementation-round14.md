# M5 구현 **14라운드** — 발견 원문 + 배치 문항지

> **이 파일이 무엇인가**: **[2026-09-02 신설]** M5 자율 구현 구간
> (`m5-implementation-round14-brief.md`가 규약, 2026-09-02 §0 확정 — Q1~Q6
> 전부 (a))에서 나온 발견 전부. 실제 코드를 옮기고 돌리다 나온 것이다.
> 번호는 **`H-290`부터**(round13이 `H-289`까지 썼다).
>
> **갈래 표기**(규약 §2, M3·M4 준용): **①** 자율로 고침(같은 커밋에서
> `base/`+코드) / **②** §4 표에 쌓아 배치 회신 대기(코드엔 `-- TODO(H-nnn)`
> 마커만) / **③** 즉시 중단·보고. M2~M4 하자는 동형 규칙 — 경미하면 여기
> ①, 설계 결정 규모면 그 시점 다음 번호로 해당 마일스톤 라운드를 새로 연다.
>
> **상태의 소스는 이 파일 자신** — 요약 표의 상태 열이 최신.

## 요약 표

| 번호 | 갈래 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|
| `H-290` | ① | 🟡 | (단위 ①) **미claim inst에 대한 `bindLifetime`은 실 구현에서 error다** — 정본 (1) 스케치는 `InstData:GetWeak(inst,"gchold")`를 nil 검사 없이 인덱싱해, claim 안 된 inst를 건네면 원인 불명 nil-index로 죽는다. mock은 lazy claim으로 이 경로를 가렸지만 실물은 (0) 불변식("생성 시 1회")상 lazy가 금지(스파이크 `10` A-6이 실증한 userdata 구멍) | ✅ 반영 — `quad-roblox/src/LifetimeHandle.luau`가 명확한 가드로 fail-fast(`"Instance is not claimed by quad"`, `errorBefore`). 새 메커니즘이 아니라 (0) 불변식의 따름 가드라 ①로 처리 — 메시지·판정은 에이전트 재량, 틀렸다면 사용자가 뒤집을 것. mock과의 의도적 발산 목록에 등재(파일 헤더) |
| `H-291` | ① | 🟡 | (Studio 스모크) **Deferred 시그널 동작 실측** — 이 플레이스(신형 기본값)에서 `Destroying`·`GetPropertyChangedSignal` 콜백은 동기 발화하지 않고 다음 재개 지점에 지연 배달된다(Destroy가 연결을 끊어도 큐잉분은 돎, 정확히 1회). **`gcconn.Connected` 전환은 동기**라 `canBound`/`canExecute` 판정은 무영향 — 영향 범위는 시그널 *배달*에 기대는 소비자(`onDestroying` → `Effect` cleanup 타이밍, 이후 `OnChange`/`Event` 핸들러)뿐 | ✅ 반영 — `lifecycle-pattern.md` "2." 절에 실측 배너(cleanup은 "죽음과 같은 줄기"가 아니라 "죽음 이후 지연"일 수 있음 — 동기 실행에 기대는 설계 금지), 스모크 단언도 지연 기대로 고정. 설정(Immediate/Deferred)은 플레이스별이라 quad는 양쪽 다 견뎌야 한다 |

**[2026-09-02 단위 ① 시점] 확인만 하고 문제 없던 것**:

- **pesde `dev_dependencies` 실동**(Q3 (a)의 검증 조건) — `pesde install`이
  `quad_base`를 `quad-roblox/luau_packages`에 정상 실체화, `relink.sh` 글롭이
  중첩까지 커버해 전 스위트 exit 0(파일 수는 `scripts/test.sh` glob이 소스). 루트 `pesde.toml`이 wally→pesde 전환
  사유로 적어둔 기능의 첫 실사용.
- **`nativeClaim`의 구현 파일은 `LifetimeHandle.luau`** — op 목록의 소스는
  `architecture.md` EngineOps 줄 그대로이고, 본체만 `InstData`를 공유하는
  파일에 있다(§7-9 *"경로를 여기에 전부"* — 파일 헤더에 사유 명시). 배치
  관례(`H-253`류)라 발견 아님.
- **spec의 blame 단언은 클로저 경유 pcall이어야 한다** — `pcall(taggedFn, …)`
  직접 호출은 태그된 표면의 호출자가 C 프레임이라 위치 접두가 안 붙는다
  (기존 quad-base spec 관례가 이미 클로저형 — 새 규칙 아님).
- **진입점·팩토리도 SURFACE 태그 필요**(`H-238`의 적용 범위 확인) — 안 하면
  `errorBefore`가 raise 자리로 폴백. `QuadRoblox`/`RobloxFactory` 자기 태그로 해소.

## §4 배치 문항 (회신 대기)

| 번호 | 문항 | 갈래 | 권고 | 근거 |
|---|---|---|---|---|
| `H-293` | (탐사자 🟡-1, **실기기 실측**) **파괴된 Instance에 `nativeClaim`하면 영구 좀비가 된다** — Destroy된 inst의 `GetPropertyChangedSignal("ClassName"):Connect()`가 성공하고 `Connected`가 영원히 true(Studio 실측). 죽은 inst에 묶인 값이 영구 발화 가능 판정 + 절단면 없는 캡처 누수. mock은 `H-171` 가드(`destroyed`면 Disconnect)로 막았지만 그 근거("생성 시 1회라 경로 없음")는 `New` 경로만 참 — 공개 `quad.nativeClaim` 직접 호출과 단위 ④ `Claim`(사용자 제공 트리)에는 거짓. **실물 Roblox엔 깨끗한 destroyed 술어가 없다** — 증상 확정, 처방 미정 | (a) `Claim`이 DFS 시점에 트리 소속(예: `inst:IsDescendantOf(game)` 또는 사용자 제공 루트) 검사 — 직접 `nativeClaim` 호출은 UB 문서화 / (b) claim 직후 `gcconn.Connected`를 되읽어 false면 즉시 error(파괴된 inst의 신규 커넥션이 정말 Connected true로 남는지의 역 — **실측상 true로 남아 이 검출은 안 됨**, 후보 기각 근거로 기재) / (c) UB로만 문서화(가드 없음) / (d) 다른 방식 | **(a)** | (b)는 실측이 이미 기각. (c)는 `Claim`이 사용자 입력 표면이라 "즉시 error가 주 방어선" 원칙과 어긋남. (a)는 `Claim` 경로(사용자 트리)만 지키고 내부 `New` 경로엔 검사 비용을 안 얹는다 — 단 판정식(`IsDescendantOf(game)`은 트리 밖 정상 claim까지 막을 수 있음)이 새 메커니즘이라 사용자 결정 필요 |
| `H-294` | (탐사자 🟡-3, 스파이크 실측) **mock `installLifetime`이 `_initializedBy`를 세우지도 검사하지도 않는다** — `QuadRoblox(q)` 후 mock 설치가 조용히 성공(혼합 백엔드), mock 선설치 후 `QuadRoblox(q)`도 무사통과하며 기존 바인딩이 조용히 전량 침묵. 테스트 인프라 한정이지만 실패 모드가 "조용한 침묵"이라 최악 유형 | (a) mock도 `_initializedBy = "mock"`을 세우고 같은 3분기 가드(다른 백엔드 점유면 error) / (b) 현상 유지 + 헤더 경고만 / (c) 다른 방식 | **(a)** | 실 계약("a module cannot serve two backends")을 테스트 대역도 지켜야 spec이 그 계약 자체를 검증할 수 있다 — 비용은 mock 몇 줄. 단 mock은 quad-base 소유 파일이라 M2 산출물 수정 = 사용자 확인 대상 | 
| `H-292` | (감사 1라운드) `EngineOps.luau`의 `isInst`(`typeof(value) == "Instance"`)가 `luau-analyze`에 `UnknownType: Unknown type 'Instance'` 진단을 남긴다 — CLI엔 Roblox 타입 정의가 없어 typeof-narrowing이 이름을 못 푸는 것. **`UnknownType`은 strict에서도 exit 0**이라(감사자 실측) 스위트는 안 깨지지만, "analyze가 조용히 통과" 패턴을 반복 경계해온 레포에서 상시 진단 1줄이 섞인 채 도는 게 맞는가 | (a) 문서화만(무해 — Roblox 글로벌은 CLI에서 원래 못 푸는 게 정상) / (b) 판정식을 바꿔 진단 자체를 제거(예: `(typeof(value) :: string) == "Instance"` — 동작 동일, narrowing 경로만 우회) / (c) `test.sh`가 analyze **출력**까지 fail 조건으로 강화 | **(b)** | 한 줄 캐스트로 "출력 클린 = 이상 없음" 관측 관례가 유지된다 — (a)는 다음 진단이 이 1줄에 섞여 묻히는 자리를 만들고, (c)는 UnknownType류 환경 한계 전부를 화이트리스트해야 해서 비쌈. 단 (b)의 캐스트가 코드를 살짝 흐리는 건 사실이라 취향 판단 — 코드엔 `-- TODO(H-292)` 마커만 두고 대기 |

(위 셋 외 없음 — **[2026-09-02 단위 ① 종결 시점]** 열린 문항 3:
`H-292`/`H-293`/`H-294`. 전부 단위 ② 진행을 막지 않는다 — `H-293`은 단위 ④
`Claim` 착수 전까지만 답이 필요.)

**[2026-09-02 탐사자 라운드 — 위 §4 둘 외 확인·기각 기록]**:

- **🟡-4 → 반영**: `claim-plan.md` §7-10의 이중 claim `error(…, 2)` 문구가
  실코드(`errorBefore(SURFACE)`, `H-272` 관례 확장)와 어긋난 채 방치돼
  있었다 — 정본 쪽에 정정 배너. 커밋 시점에 이 편차가 어디에도 기록되지
  않았던 것 자체가 체크리스트 2번 누락(탐사자 발견).
- **🟡-2 → 반영**: `ROADMAP.md` M8의 `LifetimeHandle` 실구현 체크박스가
  미체크로 남아 진행 소스가 이중화 — M5 단위 ①로 앞당겨 완료 표기(`[x]`),
  같은 계열 stale 세 문장(`lifecycle-pattern.md` `H-184` 주석 /
  `quad-base/src/LifetimeHandle.luau` 헤더 / ROADMAP M2 각주)도 정정.
- **🟡-5 → 반영**: roblox 전사본 경유로 안 돌던 경로 셋(Effect
  `_bindDestroying`↔`onDestroying` 실배선 / `_assertBindable` 커밋 전 거부 /
  재바인드 `_catchUp` 1회)을 `spec.robloxfactory.luau` 8절로 보강 — 전
  스위트 exit 0.
- **🟢-6 기각(방치)**: `bindLifetime(inst, 1)`이 `gchold[1]`(gcconn 자리)을
  덮는 극단 오용 — 정본 스케치·mock과 공유하는 결함이라 구현 발산이 아니고,
  "실제로 관측된 문제에만 구조" 원칙상 가드 안 얹음(기록만).
- **🟢-7 → 반영**: brief Q4의 "스텁 유지" 문구에 실상태(nil — 설치 없음,
  spec 6절 단언) 주석.
- **🟢-8 기각(무해)**: `RobloxFactory`가 로컬 직접 호출인데 SURFACE 태그 —
  require 경계라 `-O2` 인라인 불가, blame 실동은 spec 1절이 확인.
