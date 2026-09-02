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
| `H-299` | ① | 🟡 | (단위 ②) **`D`의 획득 경로가 코퍼스에 미지정** — 사용법 예시는 전부 bare `D`인데 어디서 오는지 안 정해져 있었다(claim-plan은 "정의는 D 안에 산다"까지만) | ✅ 반영 — 백엔드가 모듈 필드를 설치하는 기존 채널 그대로 **`RobloxFactory`가 `module.D = InitD(module)`**(op 필드들과 같은 자리 — 새 채널이 아니라 같은 뮤테이션 경로라 ①). 사용법 `local D = quad.D`. 이 배치가 틀렸다면 사용자가 뒤집을 것. `<Class>Param` 재익스포트 표면은 단위 ⑤ `H-25` 몫으로 유보(손 나열은 "전량 생성" 계약과 충돌) |
| `H-300` | ② | 🟡 | (단위 ②) **`None`을 D 값 유니언에 타입으로 실을 수 없다** — `None`은 frozen 빈 테이블의 **신원** 센티널이라 구조 타입 표현 불가(빈 테이블 타입은 모든 테이블에 매치), quad-base 사본별 신원이라 quad-roblox가 typeof로 집지도 못함. `H-298` (a)의 "None 포함"을 문자 그대로는 이행 불가한 기술 사실 — 유니언은 일단 None 없이 좁게 냄(넓히기는 호환) | ✅ **(a) [2026-09-02 사용자 확정 — "300 a 확인 완료, 권고대로 진행해도 될것 같아"]** 센티널에 `__quadNone = true` 마커 필드(`Brand.luau`의 Brand 아님 — 타입 조언층 전용; `Dispatch/None.luau` — 신원 판정·frozen 그대로) + `QuadTypes.None` 타입 신설, 생성 유니언 전부(스칼라·이벤트·`NewChild`)에 None 합류, 재생성·전 스위트 exit 0 |
| `H-301` | ① | 🟢 | (Studio 실측) **클래스 수준 제외 규칙 보강** — 1차 스모크에서 `RelativeGui`가 태그론 안 드러나는 RobloxScript capability 게이트로 생성 불가. 함께 정리: `Deprecated`(GuiMain)/`NotBrowsable`(TextChannelWindow·VideoDisplay)/`MemoryCategory: Internal`(AdGui)은 사용자 표면 아님 | ✅ 반영 — 생성기 클래스 제외 규칙 + 실측 denylist, 재스모크 **31/31 전량 생성 성공**. `H-296` (a) "creatable" 취지의 실측 구체화(①) — 정본은 bind-system-plan 유니언 절 |

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
| `H-293` | (탐사자 🟡-1, **실기기 실측**) **파괴된 Instance에 `nativeClaim`하면 영구 좀비가 된다** — Destroy된 inst의 `GetPropertyChangedSignal("ClassName"):Connect()`가 성공하고 `Connected`가 영원히 true(Studio 실측). 죽은 inst에 묶인 값이 영구 발화 가능 판정 + 절단면 없는 캡처 누수. mock은 `H-171` 가드(`destroyed`면 Disconnect)로 막았지만 그 근거("생성 시 1회라 경로 없음")는 `New` 경로만 참 — 공개 `quad.nativeClaim` 직접 호출과 단위 ④ `Claim`(사용자 제공 트리)에는 거짓. **실물 Roblox엔 깨끗한 destroyed 술어가 없다** — 증상 확정, 처방 미정 | (a) `Claim`이 DFS 시점에 트리 소속(예: `inst:IsDescendantOf(game)` 또는 사용자 제공 루트) 검사 — 직접 `nativeClaim` 호출은 UB 문서화 / (b) claim 직후 `gcconn.Connected`를 되읽어 false면 즉시 error(파괴된 inst의 신규 커넥션이 정말 Connected true로 남는지의 역 — **실측상 true로 남아 이 검출은 안 됨**, 후보 기각 근거로 기재) / (c) UB로만 문서화(가드 없음) / (d) 다른 방식 | ~~(a)~~ → **✅ [2026-09-02 사용자 기각 — (c)류 UB 확정·문서화]** *"이건 무조건 UB 영역이다. :Clone() 을 하게 된다면 기본적으로 Parent 가 없는 상태인데 … 방어하지 못할 부분을 방어하려고 애매한 방법을 택할 이유가 없다"* — 가드 없음, `claim-plan.md` §7-13 신설 + `documentation-content-map.md` §4 등재 + 코드 주석 정정 | 권고 (a)의 트리 소속 검사는 정당한 parentless claim(Clone)을 막는 부작용이 커서 기각 — "생성부터 소유" 개념상 Destroy된 객체 투입 자체가 의도된 입력이 아님 |
| `H-294` | (탐사자 🟡-3, 스파이크 실측) **mock `installLifetime`이 `_initializedBy`를 세우지도 검사하지도 않는다** — `QuadRoblox(q)` 후 mock 설치가 조용히 성공(혼합 백엔드), mock 선설치 후 `QuadRoblox(q)`도 무사통과하며 기존 바인딩이 조용히 전량 침묵. 테스트 인프라 한정이지만 실패 모드가 "조용한 침묵"이라 최악 유형 | (a) mock도 `_initializedBy = "mock"`을 세우고 같은 3분기 가드(다른 백엔드 점유면 error) / (b) 현상 유지 + 헤더 경고만 / (c) 다른 방식 | **✅ (a) [2026-09-02 사용자 확정 — "권고대로. mock 또한 하나의 백엔드이다"]** mock이 `_initializedBy = "mock"` 3분기 가드(옛 `installed` weak 테이블 대체), `spec.robloxfactory` 1절에 양방향 거부 단언 추가 — 전 스위트 exit 0 | 실 계약을 테스트 대역도 지켜야 spec이 그 계약 자체를 검증할 수 있다 | 
| `H-292` | (감사 1라운드) `EngineOps.luau`의 `isInst`(`typeof(value) == "Instance"`)가 `luau-analyze`에 `UnknownType: Unknown type 'Instance'` 진단을 남긴다 — CLI엔 Roblox 타입 정의가 없어 typeof-narrowing이 이름을 못 푸는 것. **`UnknownType`은 strict에서도 exit 0**이라(감사자 실측) 스위트는 안 깨지지만, "analyze가 조용히 통과" 패턴을 반복 경계해온 레포에서 상시 진단 1줄이 섞인 채 도는 게 맞는가 | (a) 문서화만(무해 — Roblox 글로벌은 CLI에서 원래 못 푸는 게 정상) / (b) 판정식을 바꿔 진단 자체를 제거(예: `(typeof(value) :: string) == "Instance"` — 동작 동일, narrowing 경로만 우회) / (c) `test.sh`가 analyze **출력**까지 fail 조건으로 강화 | **(b)** | 한 줄 캐스트로 "출력 클린 = 이상 없음" 관측 관례가 유지된다 — (a)는 다음 진단이 이 1줄에 섞여 묻히는 자리를 만들고, (c)는 UnknownType류 환경 한계 전부를 화이트리스트해야 해서 비쌈. **✅ (b) [2026-09-02 사용자 확정 — "권고대로"]** `(typeof(value) :: string)` 캐스트 반영, `luau-analyze quad-roblox/src` 출력 0줄 실측 확인 |
| `H-295` | (단위 ② 착수 조사) **⭐ `D` 생성기의 입력 소스가 코퍼스에 미결정** — `bind-system-plan.md`는 API 덤프를 *전제*만 하고 무엇을 쓸지 안 정했다. 가용 실측: (i) `setup.rbxcdn.com` **JSON API Dump**(현행 버전 7.2MB 취득 성공 — `Superclass` 계층·`Tags`(Deprecated/NotScriptable/ReadOnly/NotCreatable)·`Security` 보유, 단 엔진 타입명→Luau 표기 매핑 필요) / (ii) luau-lsp `globalTypes.d.luau`(837KB — Luau 타입명·이벤트 시그널 파라미터 팩 그대로, mise가 luau-lsp 1.69.0 핀, **단 태그·보안 정보 없음**) / (iii) Studio MCP `ReflectionService`(런타임 핸들러와 동일 소스라는 정합성, 단 타입 정보 빈약) | (a) **JSON API Dump 주 소스** + 타입명 매핑은 유한 수동 테이블(int/float→number 등), 버전은 clientsettings 조회로 취득해 산출물 헤더에 기록 / (b) globalTypes 주 소스 + 태그 필터 포기 / (c) 둘 병합(JSON으로 범위·필터, globalTypes로 타입명) / (d) 다른 방식 | **✅ (a) [2026-09-02 사용자 확정]** | 필터·범위 판정(H-296/H-297)이 태그·계층 정보를 요구하는데 그건 JSON에만 있다. 타입명 매핑은 유한하고(수십 개) 한 번 만들면 안정적. (c)는 두 소스의 버전 불일치 축이 하나 더 생긴다 |
| `H-296` | (단위 ② 착수 조사) **"GUI에 쓰이는 모든 인스턴스"의 판정식 미확정** — base 후보(`GuiObject` 하위+`UIComponent` 하위+`LayerCollector`류)는 *예시*로만 적혔고("생성기 구현 시점에 정한다"), **vide의 손 목록이 반례를 준다**: `Folder`(GUI 트리 그룹핑)·`Camera`·`WorldModel`(`ViewportFrame` 안 필수)은 그 계층 밖인데 실사용 GUI 트리에 온다 | (a) **계층식 + 명시 화이트리스트** — `NotCreatable` 제외 ∧ (`GuiObject`∪`UIBase`(UIComponent/Layout/Constraint)∪`LayerCollector` 하위) + 명시 추가 `{Folder, Camera, WorldModel}`(ViewportFrame·그룹핑 실수요; 목록은 실사용 요구 시 추가 — 범위 밖은 어차피 `New<<X>>` 폴백) / (b) 계층식만(셋 제외) / (c) 다른 방식 | **✅ (a) [2026-09-02 사용자 확정]** | 사용자 확정("GUI에 쓰이는")의 실질을 계층식만으로는 못 담는다는 게 vide 반례로 실증 — 화이트리스트는 짧고, 빠진 클래스는 `any` 폴백이 있어 실수 비용이 낮다 |
| `H-297` | (단위 ② 착수 조사) **프로퍼티 필터 정책 미확정** — 코퍼스에 언급 자체가 없다. ReadOnly/`Deprecated`/`NotScriptable`/`Hidden` 태그와 `Security ≠ None` 프로퍼티를 D props 타입에 실을지 | (a) **전부 제외**(쓰기 표면만 생성 — ReadOnly·NotScriptable은 대입 불가라 타입에 있으면 거짓 표면, Deprecated는 새 코드 표면에 안 실음, Security는 일반 스크립트가 못 씀) / (b) Deprecated는 포함 / (c) 다른 방식 | **✅ (a) [2026-09-02 사용자 확정]** | D는 **쓰기**(대입) 표면이라 대입 불가능한 프로퍼티가 타입에 있으면 통과되는 오용을 만든다. Deprecated 포함(b)은 구계약 이식 편의가 있지만 "새로 짜는 라이브러리" 방향과 어긋남 | 
| `H-298` | (단위 ② 착수 조사) **props 값 유니언과 `NewChild`의 정본 정의 부재** — 이벤트 필드는 확정(`콜백 \| None \| nil \| State<...>`, event-plan)인데, **스칼라 프로퍼티** 유니언과 **children 원소**(`NewChild` — claim-plan이 이름만 씀) 정의가 어디에도 없다. 스파이크 `28`은 자리표시자로 메커니즘만 통과시킴 | (a) **M5 최소 정본**: 스칼라 = `T \| State<T> \| Tween<T> \| None`(Tween은 PropertyHandler 소비 값 — tween-plan의 `T'` 치환과 정합), children 원소 `NewChild` = `Instance \| State<...> \| Ref류` **M5 시점 유니언**으로 정의하고 이후 마일스톤(M6 Slot 등)이 유니언을 **확장**한다는 규칙을 같이 명문화(정의 자리는 `bind-system-plan.md` 인스턴스 생성 절) / (b) 지금 전 마일스톤 표면을 미리 다 싣기 / (c) 다른 방식 | **✅ (a) [2026-09-02 사용자 확정]** | (b)는 아직 안 만든 표면(Slot 팩토리 등)의 타입을 선제 발명하게 돼 "발견은 결정이 아니다" 규약과 충돌. (a)의 "확장 규칙 명문화"가 각 마일스톤이 자기 몫을 더할 자리를 만든다 |
| `H-300` | (단위 ②) `None`을 D 값 유니언에 어떻게 실을지 — 신원 센티널이라 구조 타입 표현 불가(요약 표 `H-300` 참조). 현재 생성 유니언은 None 없이 좁게 나감(넓히기는 호환) | (a) **`None` 값에 브랜드 필드를 부여**(`__quadNone: true` — frozen 테이블에 필드 하나, `v == None` 신원 판정은 그대로) + 그 구조 타입을 유니언에 실음 — M3 산출물(`Dispatch/None.luau`)의 경미 수정 / (b) 유니언에서 영구 제외 — None을 쓰는 자리는 `:: any` 캐스트(사용자 문서에 명시) / (c) 다른 방식 | **✅ (a) [2026-09-02 사용자 확정]** | (b)는 정당한 None 사용(명시적 nil 세팅)마다 캐스트를 강제해 표면이 거칠어진다. (a)의 비용은 센티널 테이블 필드 하나 — 신원 판정·frozen·기존 spec 전부 무영향(타입은 조언층이고 런타임은 여전히 `v == None`) — 반영 상태는 요약 표 행이 소스 |

**⭐ [2026-09-02 배치 회신 — 전량 종결, 열린 문항 0]** 사용자 원문:
*"H293: 이건 무조건 UB 영역이다. … 권고는 기각하며 해당 부분은 고치지
않고, 문서화 대상. / H294: 권고대로. mock 또한 하나의 백엔드이다. /
H292: 권고대로. / 열린 문항은 295, 296, 297, 298 권고대로."* — 일곱 전부
확정(H-293만 권고 기각·UB 문서화, 나머지 여섯 권고 (a)/(b) 그대로).
반영 상태는 각 행 ✅가 소스. **단위 ② 착수 게이트 해제.**

**[2026-09-02 단위 ② 종결 시점]** ~~열린 문항 1 — `H-300`~~ → **같은 날
사용자 확정·반영 완료로 열린 문항 0.** 부수 확인 하나: 워크스페이스
dev-dep 사본(`quad-roblox/luau_packages`)은 설치 시점 스냅샷이라
quad-types/quad-base를 고치면 **`pesde install` 재실행이 필요**하다
(relink는 심볼릭→실복사만 담당 — `H-300` 반영 중 실측).

| `H-302` | ① | 🟡 | (단위 ③ 리뷰) **읽기 전용 프로퍼티가 Property 핸들러에 매치**돼 `inst[k]=v`가 h.process 한가운데서 엔진 원시 에러를 내고 `H-103` NOOP 마커가 고착될 수 있었다(예: `AbsoluteSize`). 처방 실측: 디스크립터의 **`Permits.Write` 키가 쓰기 가능 프로퍼티에만 존재**(Studio — Size/Visible엔 있고 AbsoluteSize엔 없음) | ✅ 반영 — 멤버십 캐시가 `Permits.Write ~= nil`만 싣는다. `H-297` (a)("쓰기 표면만 — 대입 불가 프로퍼티는 거짓 표면")의 **런타임판**이라 승인된 논거의 확장으로 ① 처리(`H-290` 선례) — 틀렸다면 사용자가 뒤집을 것. spec에 읽기 전용 대조군 추가 |
**[2026-09-02 단위 ③ 시점] 확인만 하고 문제 없던 것**:

- **ReflectionService 반환 모양 실측**(Property 매치의 전제) — 디스크립터
  배열(`.Name`/`Owner`/`Permits`…) + 상속 포함(Frame 60개에 GuiObject 소유
  `Size` 포함), 이벤트는 별도 API(`GetEventsOfClass`)라 프로퍼티 목록과
  안 섞임 — 이벤트 키는 M10 전까지 자연스럽게 매치 실패 error.
- **`v == nil` 방어·`isTween` 분기 부재는 발견이 아니라 정본의 명시 유예**
  (dispatch-core "M9/M10로 미룸" / tween 런타임 M11) — 두 파일 헤더에
  포인터.
- **getfenv 주입면 셋**(Instance/game/isInst)이 전부 기설계 주입 경계와
  일치 — isInst는 `H-40`이 "주입 술어"로 만든 그 자리라 spec의 교체가
  계약 위반이 아니라 계약 사용.

**[2026-09-02 단위 ③ 끝 절차 기록]** 감사 1라운드(정본 전 대조 클린, 확실
1 — todos stale)로 수렴(유한 종결, M4 선례) → `/code-review medium` 1회 —
생존 3건 전부 반영: ① spec 심이 "Parent"를 빼둬 `H-142` 가드 한 줄이
미검증이던 것(실증 — 가드를 지워도 통과했음; 심에 Parent 포함 + 읽기 전용
대조군) ② `H-302` 쓰기 필터(위 행) ③ `getOffsetAt(f,1)==0` 공허 단언(위치
2 오프셋으로 교체 — 철거 후 0까지 핀). 반영 후 전 스위트 exit 0.

**[2026-09-02 단위 ② 끝 절차 기록]** 감사 3라운드 수렴(3+1 → 1+1 → 확실 0
— 각도: diff 정합성 / 교정분+`H-300` 반영 / 병렬 규약·수렴) 후
`/code-review medium` 1회 — **생존 4건 전부 반영**: ① `D.New(name)`의
스테이지 클로저 미태그(범위 밖 클래스 폴백 경로의 blame 열화 — 스테이지
생성 시 태그로 이동, 별칭 루프는 `New` 단일 태그로 대체) ② spec.d 4절이
계약 이름만 달고 실검증 없던 것(`getFuncLevel` 직접 단언 4개로 교체 —
①을 잡을 수 있는 형태) ③ `test.sh`의 luau-lsp 이중 실행(1회 캡처로) ④
원장 요약 행의 "브랜드 필드" 어휘(마커로 명시 — §4 문항 원문·사용자 인용은
불변). 반영 후 전 스위트 exit 0 재확인.

**[2026-09-02 단위 ② 신선 탐사자(커밋 `2ad2c03` 뒤)]** 🔴 0 / 🟡 5(전부
문서층) / 코드·산출물 결함 0 — **원본 덤프 재취득 후 생성기 재실행이
커밋 산출물과 바이트 동일**(완전 재현), Security 비대칭·범위 회계(37=31+6)·
defs 게이트·상속 오버라이드·산출 샘플 전수 클린. 🟡 반영 다섯: Tween
런타임 마일스톤 오기 M9→**M11**(types.luau 3곳·bind-system-plan 정본 절) /
이벤트 핸들러 마일스톤 오기 M7→**M10**(생성 헤더) / init.luau "37종" 개수
하드코딩 제거 / ROADMAP gcconn 체크박스 자기 기준 충족 후 미체크(→ `[x]` —
탐사자 CLI e2e가 `New` ② 배선을 실증). **신규 관측**: 생성 D의 전역
`Instance` 참조는 `getfenv(D.New).Instance` 주입으로 CLI에서 실주행 가능 —
spec.d 5절(파이프라인 CLI e2e — ① 생성·② claim·범위 밖 폴백)로 반영, 전
스위트 exit 0.

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
