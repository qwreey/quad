# 첫 실사용 소비자 — 디버그 UI 킷과 Material 킷 계획

> **[2026-10-05 신설 — 사용자 요청, 메인 세션이 오케스트레이터 에이전트에 위임]** quad를 실제로 소비하는
> 라이브러리 둘(디버그 UI 킷·Material 3 킷)을 레포 루트에 만들고, 만드는 동안 quad 쪽에서 겪은 마찰을
> `.claude/feedback/consumer-kits-2026-10-05.md`에 쌓는다. 이 문서는 범위·구조·검증 방식의 계획이고, 실제로
> 만든 것과 결과는 각 킷의 `README.md`와 최종 보고가 소스다.
>
> **이름은 가칭 — 도그푸딩 뒤 결정**(사용자 결정 2026-10-05: 사내 리서치·도그푸딩 단계라 바로 게시하지 않고,
> 써 보고 다듬어진 뒤 이름을 정해 게시). 작업 이름은 `quad-roblox-devui`·`quad-roblox-material`. 나중에 쉽게
> 바꿀 수 있게 이름은 폴더 이름과 각 킷 README에만 두고, 코드의 require는 전부 폴더 상대 경로다.

> **[2026-10-05 기준] 1~4파 실행 완료.** 디버그 UI 킷(src 48파일 7,375줄, 스펙 24파일 143섹션)·Material 킷(src 95파일
> 16,808줄, 스펙 33파일 264섹션 + 순수 스펙 둘) 모두 `test/run.sh` exit 0(strict 진단 0, `q.debug` 출력 0), 기존
> `./scripts/test.sh` exit 0 유지. 리뷰는 킷마다 각도별 3~4명 → 반영 → 재리뷰 → 반영을 돌렸다. 실기기(Studio) 확인은
> 하나도 못 했다(아래 3절의 한계와 각 킷 README "알려진 한계"가 소스).

## 1. 타당성 판단

사용자 질문은 "정의된 정상 경로만 탄다면 소비자(UI 컴포넌트 킷, 라이브러리)를 만들 수 있는 상태인가"였다.
착수 전에 공개 표면을 훑은 판단은 **가능**이다. 컴포넌트 킷이 쓰는 표면 — `Source`/`State`/`Compute`/`Apply`,
`Observer`/`Effect`와 cleanup, `Slot`(`:List`/`:Single`/수동 CRUD), 생성 `Declaration`(31클래스 — `CanvasGroup`,
`UICorner`, `UIStroke`, `UIShadow`, `UIGradient`, `UIDragDetector`, `UIFlexItem` 포함), `q.Out`/`OnChange`,
`Tween`/`Animate`, `PreRef`/`PostRef`/생명주기 훅, `Context`, `Operator` — 이 전부 정의돼 있고 문서화돼 있다.
round14 탐사에서 정상 경로 결함이 0이었고 열린 결정은 UB·문서 경계라 정상 경로를 막지 않는다.

착수 전 확인에서 미리 보인 마찰 둘은 막는 것이 아니라 우회 가능한 것이라 피드백으로 기록한다:
(1) 소비자용 공개 mock이 없다(how-to 06이 인정) — 이 레포의 `quad-base/test/mock.luau`를 테스트에서 직접 쓴다.
(2) `luau` CLI는 모듈마다 읽기 전용 전역을 바탕으로 한 env를 주므로, 모듈 최상위에서 `Color3.new` 같은 엔진
전역을 쓰는 UI 킷 모듈은 `getfenv` 심으로 고칠 수 없다(quad 자신의 spec은 모듈 로드 시점에 엔진 전역을 안
써서 이 문제를 안 겪는다). 그래서 킷의 컴포넌트 스펙은 **Lune**(0.10.5, 실 Roblox 데이터 타입 제공, 모듈 간
전역 공유)에서 돈다. Lune 0.10.5는 `const`를 못 읽으므로 킷 코드는 `const`를 쓰지 않는다.

## 2. 구조

- 두 폴더 모두 레포 루트(`quad-roblox-devui/`, `quad-roblox-material/`) — 나중에 다른 레포로 나갈 수 있다.
  게시 파이프라인(`scripts/publish.py`·`check-version.py`)과 pesde 워크스페이스에는 넣지 않는다.
- 각 킷의 `src/Quad.luau`가 "설정 모듈"이다 — 시작하기 01의 권장 구조 그대로 싱글턴에 `UseProvider`를 걸고
  타입을 재수출한다. quad가 어디 있는지 아는 곳은 이 파일의 require 세 줄뿐이다(레포 안에서는 quad-roblox
  spec과 같은 워크스페이스 사본을 가리킨다).
- 테마는 Context 대신 **명시적 객체 + 모듈 기본값**: `Style.new()`/`Theme.new()`가 반응형 토큰(State)을 가진
  객체를 만들고, 컴포넌트는 `props.Style`/`props.Theme`이 없으면 모듈 기본값을 쓴다(트리 탐색 없음 — how-to 05).
- 팝업(콤보·메뉴·툴팁·다이얼로그·스낵바)은 킷마다 `Overlay` 객체(전체 화면 레이어 + `Slot`)를 두고 앱이 그
  레이어를 자기 ScreenGui에 한 번 놓는다(how-to 09).
- 입력은 킷마다 `Interaction` 모듈의 팩토리(hover/pressed/focus `State<boolean>`, 드래그 추적 — 드래그 중에만
  `UserInputService` 연결을 열고 끝·인스턴스 사망 때 닫는다).

### 디버그 UI 킷(Iris에서 영감 — `SirMallard/Iris@801973f`, MIT)

즉시 모드 API를 베끼지 않고 같은 위젯 셋을 quad 관용구(보유 모드·반응형)로 만든다. 우선순위:
- 1순위: Window(드래그·접기·닫기·크기 조절·스크롤), Text류, Button/SmallButton, SameLine/Group/Indent/Separator/
  SeparatorText, Checkbox, RadioButton, InputText, InputNum, SliderNum, DragNum, Tree/CollapsingHeader, Combo,
  Tooltip, Table, TabBar/Tab, MenuBar/Menu/MenuItem/MenuToggle, ProgressBar.
- 2순위: InputVector2/UDim2·InputColor3, Selectable, PlotLines/PlotHistogram, 데모 창(Iris `ShowDemoWindow` 대응).

### Material 3 킷(RoStrapUI `RoStrap/RoStrapUI@792da9d`(MIT)·사용자 MaterialUI `qwreey/qwreey.roblox.plugins@7b6552a:libs/MaterialUI`(MIT) 참고)

- 토대: 토큰(색 역할 light/dark·타입 스케일·셰이프·엘리베이션·모션·상태 레이어 불투명도), 테마 객체,
  상태 레이어 + 리플(둥근 모서리 클리핑은 `CanvasGroup`/둥근 자식으로 — 프레임 수백 금지), 엘리베이션(`UIShadow`).
- 컴포넌트: Button 다섯 변형·IconButton·FAB, Checkbox·Radio·Switch·Slider, TextField(filled/outlined), Card·Dialog·
  Snackbar·Divider·List·Tooltip·Menu, Chips·Tabs·Progress, **DatePicker**(달력 계산은 순수 모듈 `Calendar`로 분리해
  CLI 단위 테스트), **ColorPicker**.

### Color picker

사용자의 `colorPicker-ignoreme.rbxm`(MIT 재게시 허용)는 LocalScript 하나(2348줄)가 UI 전부를 코드로 만든다.
순서: (1) 원본 구조 분석 + 순수 색 모델(`ColorModel` — 상태는 HSV 삼중 하나, `Color3`는 파생, 바깥 쓰기는
무채색일 때 hue를 보존하는 변환을 거친다) → (2) 거의 같은 모양·애니메이션·인터랙션의 quad 시연판 → (3) Material
셋에 맞춘 다듬은 판 → (4) 원본 vs quad판 비교 문서(줄 수·책임 분리·상태 흐름·연결 수동 관리 수·인스턴스 수).

## 3. 검증

- 컴포넌트 스펙: `<킷>/test/spec.*.luau`(Lune) — 하네스 `test/support/harness.luau`가 실 데이터 타입, quad mock
  인스턴스(이벤트는 `quad-roblox/dump/api-surface.json`에서 생성한 반사 표), 가짜 서비스, 가상 시계, `print` 포착
  (`q.debug` 진단은 print)을 깐다. 순수 모듈 스펙은 `spec.pure.*.luau`(평범한 `luau`).
- 타입: luau-lsp 신 솔버 strict, `scripts/test.sh`의 한도 플래그 셋 그대로 — 진단 0.
- `<킷>/test/run.sh`가 위 셋을 돌리고 exit code로 판정한다. 기존 `./scripts/test.sh`는 손대지 않고 exit 0 유지를
  확인만 한다(편입은 사용자 결정).
- 리뷰 여러 라운드: 권장 경로 위반·파일 크기·타입·Material 충실도/접근성·성능(인스턴스 수) 각도.

## 4. 작업 순서

- 1파: 두 킷의 토대(테마·Interaction·Overlay·Window/Button), 순수 모듈 둘(Calendar·ColorModel) + 원본 분석.
- 2파: 위젯 묶음별 병렬(같은 파일을 두 에이전트가 동시에 고치지 않게 파일 단위로 나눈다).
- 3파: 데모(디버그 창·Material 갤러리), Color picker 시연판·다듬은 판, 비교 문서.
- 4파: 리뷰 → 반영 → 재리뷰.

## 5. 2026-10-08 이후 순서 (사용자 지시)

Studio QA 1~9차(`feedback/consumer-kits-studio-qa-2026-10-07.md`)를 거친 뒤 사용자가 정한 다음 순서. 원칙: **의견을 보태지 말고 구글 M3 정본 그대로**(사용자 *"오피네이션 빼고 구글의 favor 를 그대로"*), 근거는 구글 구현 원문(Compose material3·material-components-android·material-web). 킷 작업은 서브에이전트(opus 하나씩, 순서대로 — 갤러리·README·`src/init.luau`가 겹쳐 병렬 금지), 메인이 게이트(`quad-roblox-material/test/run.sh` exit 0 && doc-check ERROR 0)·커밋.

1. **(진행 중)** 10차 — 슬라이더 변형(`Centered` 정중앙 고정·`Orientation` 세로 기본 아래 = 최소·`Size` XS~XL·inset icon; 경고 구간은 정본에 없어 안 넣음) + 버튼 아이콘 prop + Split button + DatePicker ▼▲ 이미지화.
2. **갤러리를 `src/` 밖으로**(사용자 2026-10-08, 두 킷 다 — devui `src/Demo`도 같은 구조) — 사용자: *"보통 사용 경로에서 안 쓰는 데드코드임. 그게 src 에 있고 배포된다는건 약간 문제"*. `play/`를 킷 최상위 `gallery/`로 바꿔 갤러리 모듈과 실행 진입점을 같이 두고, 갤러리는 파일별 상대 require 대신 **루트 내보내기 표**(`src/init.luau`)를 소비자처럼 쓴다 — 사용자: 루트에서 다 로드돼 봐야 modifier 객체·클로저·proto 정도라 하나로 내놓고 골라 쓰는 쪽이 DX가 낫다. (킷 루트 표는 이미 있고, 지금 갤러리만 순환을 피하려 폴더 경로로 require한다 — `src/` 밖으로 나가면 그 순환 걱정이 없어진다.) spec·stories·`test/run.sh`·`consumer-kits.project.json` 매핑을 같이 옮긴다. 10차가 끝난 뒤, Time picker 전에(새 데모가 새 자리에 들어가게). **[2026-10-08 반영]** 두 킷 다 `gallery/`(devui `Demo`도 같은 이름) — 갤러리 모듈 + 자기 설정 모듈 `gallery/Quad.luau` + 진입 `gallery/*.client.luau`. 갤러리는 루트 표만 쓰고(`require("../src")`, 루트에 없는 것을 경로로 당긴 자리 0), `consumer-kits.project.json`이 `gallery`를 ReplicatedStorage의 `src` 옆에 놓고 진입 파일 하나만 StarterPlayerScripts에 매핑한다(`globIgnorePaths`로 ReplicatedStorage 사본에서는 진입 파일을 뺀다). `test/run.sh`가 `gallery/`를 strict로 보고, 진입은 rojo 소스맵 패스로 본다.
3. Time picker — dial과 input 둘 다(Compose `TimePicker`·`TimeInput`, MDC).
4. 레이아웃·내비게이션 — 사용자: *"실제로 플러그인 작성하게 되면 레이아웃도 필요해질거야"*. Sheets(bottom·side), Navigation bar(세로로 긴 레이아웃), Navigation drawer(요소 많을 때), Navigation rail(데스크톱), Toolbars(내비게이션 아닌 액션), App bars(사용자: 쉽지만 여기저기서 따로 구현될 바엔 제공하는 게 맞아 보임). 이것으로 정본 요소 전부. **레이아웃이 살짝 만들어지면 사용자가 전체 확인.**
5. 그 뒤 `/code-review` 한 번 — Gemini(agy, 격리 worktree) + sonnet/opus, opus가 추림 → 메인 판정. 초점: 순수 구현의 비효율·더 나은 구현법·가독성·버그. fork가 fork를 내지 않게(서브에이전트 모델 지정·검증자 상한).
6. 그다음 round14 재검토로 복귀 — 원장 §2 사용자 몫(릴리즈 절차 Q119·Q124 (4)·Q131, Q125, Q154)·§6 Q184·Q185(엔진 확답은 rojo/새 MCP 뒤), 계획표 P6 반영 묶음.
7. round14 뒤 같이 볼 것(사용자 2026-10-08) — 두 킷이 훅·인터랙션으로 만든 부분(`Interaction`의 hover/pressed/focused State·드래그 추적, `Util.hooks`/`preHook`/`postHook`, `Interactive` 묶음)에서 **quad 상위에서 생각해 볼 것**이 있는지. 사용자: *"내가 잊고 있었다 … round14 이후 같이 보도록 하자"*. 같은 자리에서 볼 것 하나 더(사용자 2026-10-08): material 갤러리가 만든 `Ctx`(`gallery/Common.luau` — 패널마다 Source를 담아 두는 Memo; 탭을 다시 만들어도 입력 상태가 남게)가 왜 quad `Context`로 안 됐는지, 그리고 `make`를 받는 Memo 꼴(없으면 만들어 넣고 있으면 돌려주는 것)이 quad로 올라갈 니즈인지 — 사용자: *"Context 로 안되던 이유가 있을까? make 를 받는 Memo 식은 필요한것 같긴한데 … 나중에 관찰해줘"*.

### 진행 상태 [2026-10-12 기준]

5절의 1~4번은 끝났다(커밋 `ec6079f1`~`1cc4a833`, 내용은 git log와 `feedback/consumer-kits-studio-qa-2026-10-07.md`의 날짜별 절이 소스 — 여기 되풀이하지 않는다). 계획에 없던 것도 같이 들어갔다: Compose `Scaffold`(사용자 승인 — 앱 바 스크롤 레이아웃의 DX), Classic 컬러 피커 제거(사용자: 프로젝트에서 빼자), 스토리를 갤러리처럼 소비자 방식으로, UI Labs 스토리 드래그 수정(두 킷), 스크림 관통 막이 `ClickSink`. Studio는 이제 컨테이너에서 `studio-sync consumer-kits.project.json`으로 한 번 싱크해 MCP로 직접 실측한다(요령은 메모리 `reference-studio-mcp-input`).

**남은 순서**: 사용자 전체 확인(레이아웃 그룹 + README 실기기 체크리스트 41~72) → 5번 code-review → 6번 round14 → 7번 상위 검토. 그 사이에 **table-sim 소비 피드백**이 돌아온다(사용자 2026-10-12: table-sim 게임이 material 킷과 quad를 실제로 소비 중) — 원문은 레포 밖 `/code/Projects/table-sim/.claude/feedback/`(색인 `README.md`; `material-kit-2026-10-11.md`·`material-kit-2026-10-12.md`·`quad-2026-10-11.md`·`report-for-quad-2026-10-11.md`·`toolchain-2026-10-12.md`·`upstream-candidates.md`), 그쪽 규약상 quad 저장소엔 직접 쓰지 않고 사용자가 넘긴다.

**사용자 결정 대기**(메인 의견 포함): (1) 킷 `docs/colorpicker-original-analysis.md`와 `ColorModel.Scale.Legacy`(255 눈금) — Classic을 뺀 이유와 같아 둘 다 지우기를 권함. (2) 그날 생긴 새 공개 이름의 확인 — `Material.Time`, `IconButton`의 `ContentColor`, `NavigationDrawerHeadline`·`NavigationDrawerDivider`(정본에 없는 둘), `Util.clickSink`. (3) 넣지 않은 동작 둘 — 내용 위에서 끌어 드로어 열기, 목록 행·버튼 위에서 시작한 누름으로 시트 끌기(둘 다 UserInputService 전역 판정 + 클릭 억제라는 새 장치가 필요). (4) 정본 차이로 기록만 한 것 — 범위 날짜 선택기에서 시작보다 앞 날짜를 탭하면 맞바꿈(Compose는 새 시작), 단일 날짜 선택기의 선택 해제 페이드(Compose는 스냅). (5) 사용자만 볼 수 있는 것 — UI Labs 창에서 실제 드래그, Scaffold 스토리, 터치에서 앱 바 정착. 닫힌 것: 범위 슬라이더 끝 조각은 지금처럼 줄어듦(사용자: 사이트 정본과 같음), 슬라이더 이동·끝 점은 고정 6(m3.material.io Measurements 우선).

**table-sim 피드백 [2026-10-12] — 판정과 사용자 결정 문항.** 판정 전체는 `feedback/table-sim-2026-10-12.md`(이미 답이 있던 것, 고친 문서 공백, 관측)이고, 여기는 결정이 필요한 일곱과 메인 의견이다. (가) **복제된 속성·자식 목록을 State로 읽어 올리는 표면**(보고서 1번) — 서버 권위 게임의 거의 모든 화면 입구라 실제로 관측된 필요다. table-sim은 폴더의 `ChildAdded`·`ChildRemoved`·`AttributeChanged`를 손으로 이어 목록을 통째로 다시 만들었고, 대상이 계속 바뀌는 자리(커서를 올린 파트)는 신호를 붙였다 떼기가 번거로워 0.1초 폴링으로 갔다. 메인 의견: 폴링으로 간 자리는 지금 있는 것(`Effect`가 대상 State를 dep으로 받고 cleanup에서 연결을 끊는 모양)으로 짤 수 있어 보이므로(코드 읽기 기준, 돌려 보지 않음) 먼저 how-to 한 편("엔진이 복제한 것을 상태로 올리기" — 속성 하나, 자식 목록, 대상이 바뀌는 경우)을 쓰고, 슈거를 quad-roblox에 둘지 별도 유틸 패키지로 둘지는 그 레시피가 소비자마다 그대로 반복되는지를 본 뒤 상위 검토(훅·인터랙션, Ctx/Memo와 같은 묶음)에서 정하기를 권한다. 2026-08-14에 기각된 "이미 있는 인스턴스에 재바인드"와는 방향이 다르다(읽기만 하고 소유·부기를 건드리지 않는다). (나) **고르는 부품의 제어 형태**(킷 10-12 1번) — `Checkbox`·`Switch`는 이미 `Checked: State<boolean>` + `OnChange`를 받고 `Select`·`Radio`·`Slider`·`TextField`·`Chip.Filter`는 `Source`만 받는다. Compose 정본은 전부 제어 형태(값 + 콜백)라 넓히는 쪽이 정본에 가깝지만 부품마다 키 이름이 새로 필요하다. 지금도 "서버 상태가 올 때마다 그 Source에 다시 `:Set`"(프로그램 쓰기는 `OnChange`를 안 부르므로 되돌이 없음)으로 풀리고 README에 적었다 — 차이는 서버 응답 전까지 고른 값이 먼저 보인다는 것(낙관적 표시)뿐이다. 메인 의견: 낙관적 표시가 곤란한 실제 화면이 나오기 전에는 넓히지 않는다. (다) **킷 호스트의 `Name`을 소비자 Modifier가 덮게**(보고서 4번, 킷 10-12 8번) — 킷이 `Name = "Button"`을 인라인으로 적어 quad 규칙("인라인 문자 키가 이긴다")대로 소비자의 `:Name(...)`이 무시된다. 한 패널에 버튼이 둘이면 경로로 가리킬 수 없어 자동 실측이 좌표로 간다(우리 Studio MCP 실측도 같은 불편). 메인 의견: 호스트의 `Name`만 기본 Modifier로 옮긴다(기본값은 그대로, 안쪽 자식 이름은 그대로) — 관례 한 줄과 기계적 변경이다. (라) **`TextField` 글자 수 표시 끄기**(킷 10-12 7번) — 지금은 `MaxLength`가 제한과 "n/max" 표시를 같이 켠다. 정본은 갈린다: MDC-Android는 표시(`counterEnabled`·`counterMaxLength`)와 입력 제한(`maxLength`)이 별개이고, Material Web은 `maxlength`만으로 표시가 켜지고, Compose는 둘 다 없이 호출자가 supportingText에 직접 쓴다. 메인 의견: 표시를 끄는 선택지를 넣는다(기본은 지금대로 켬) — 이름은 사용자 결정(후보 `Counter: boolean?`). (마) **월드 클래스의 타입 생성 범위**(보고서 3번) — `D.New`의 props가 `any`라 `Part` 등은 무검사다. 생성 별칭은 지금 31개(GUI 계열 + `Folder`·`Camera`·`WorldModel`·`BillboardGui`·`SurfaceGui`)이고 생성 `Declaration`은 이미 솔버 한도 플래그 셋이 있어야 무너지지 않는다(`typing-limits.md` 8.28). table-sim 스스로 구조가 바뀌어 무게가 줄었다고 정정했다. 메인 의견: 지금은 넣지 않고(우회는 타입 건 얇은 생성 함수), 넣자는 결정이 서면 `Part`·`Highlight` 둘로 타입 검사 시간과 한도를 먼저 잰다. (바) **작업 트리의 버전 식별**(보고서 5번) — `q.Version`이 `3.2.0`인데 실제로는 그 뒤 수백 커밋이다. 새 장치보다 3.3.0 릴리즈가 답이고(사용자 지시 대기 — `[Unreleased]`에 BREAKING 여럿), 그 전까지는 table-sim처럼 커밋 해시 고정이 맞다. 킷은 미게시라 어차피 해시로만 가리킬 수 있다. (사) **`D.New` 절에 GUI 밖 클래스 서술**(보고서 6번) — Part·DragDetector·Highlight에 State 묶기·이벤트·`Slot:List` 2,000개가 Studio에서 돌았다는 관측을 "동작한다, 단 props 무검사·지원 범위로 약속하지는 않음"으로 한 문단 적을지. 루트 `HUMAN_TODO.md`가 열어 둔 범위 밖 안내 절 문항(서버 사이드·`SurfaceGui`/`BillboardGui` 등 문서가 침묵하는 넷)과 같은 결정이다. 메인 의견: 사실로 적는다(약속 문구 없이).

**갤러리 `Ctx`·Memo 관찰 [2026-10-12] — 위 7번의 둘째 물음에 대한 메인 관찰(결정 아님, 상위 검토 때 재료).** 둘은 따로 봐야 한다. (1) `Ctx` 자체(`gallery/Common.luau` — `Theme`·`Overlay`·`Snackbar`·`Icon`·`Memo` 다섯 필드의 레코드)가 quad `Context`가 아닌 것은 결함이 아니라 자리가 달라서다. `Context`가 노리는 자리는 스키마를 모르는 중간 계층이 가방 하나만 아래로 넘기는 것인데(`docs/reference/sugar/01-context.md` 머리), 갤러리에는 그런 중간 계층이 없고 구획 함수 전부가 다섯 필드를 안다. 그 경우 타입 붙은 레코드가 더 싸다 — 필드 접근이 `ctx:Get(Provider)`보다 짧고, 빠진 필드는 런타임 `Quad0038`이 아니라 타입 에러로 잡힌다. 두 킷의 `src`·갤러리·스토리에 `q.Context` 사용은 0건이다(킷 컴포넌트는 `Theme`·`Overlay`를 props로 직접 받는다). (2) Memo(`Memo(key, make)` — 탭을 떠나면 구획이 파괴되고 돌아오면 다시 지어지므로, 사용자가 입력한 값의 Source를 패널 수명의 캐시에 두는 일곱 줄)는 `Context`로는 어색하다: 키가 모듈 수준에서 선언하는 Provider 신원이라 값마다 선언 한 줄이 필요하고, "없으면 만들어 넣기"가 없어 `:Peek` 뒤 `:Set`을 손으로 써야 한다. 더 가까운 기존 표면은 `Context`가 아니라 **`store:Of<<T>>(name)`**이다 — 이름으로 Source를 게으르게 만들고 같은 이름엔 같은 객체를 돌려준다. Memo가 그것으로 안 되는 차이는 둘: 새로 만들어진 Source의 값이 `nil`이라 초기값을 줄 자리가 없고(매번 `:Set(초기값)`하면 보존하려던 값을 덮는다), Source가 아닌 값(갤러리는 `Theme` 객체와 Source 묶음 표도 Memo에 둔다)은 담지 못한다. (3) 니즈가 quad로 올라가는가 — 밑바닥 필요는 "하위 트리가 파괴됐다 다시 지어져도 남는 상태"다. Compose에는 이름이 있다(`rememberSaveable` + `SaveableStateHolder` — 키로 화면별 상태를 보관). quad에서 지금 길은 셋: 상태를 전환 지점 위로 끌어올리기(부모가 자식의 상태 스키마를 알아야 함), 파괴하지 않고 `Visible`로 숨기기(table-sim이 고른 길 — 그 저장소에 Memo·`store:Of`·`Context` 사용 0건, 2026-10-12 grep), 키로 캐시하기(갤러리의 Memo). 두 번째 소비자가 Memo를 다시 만들지 않았으므로 지금 근거는 갤러리 하나다. 메인 의견: 새 표면을 올릴 근거는 아직 부족하고, 올린다면 후보는 Memo라는 새 개념이 아니라 `store:Of`에 "처음 만들 때의 값"을 주는 길(새 인자 — 사용자 결정)이다. 그 전에 how-to에 "파괴됐다 다시 지어지는 화면의 상태" 레시피(세 길과 고르는 기준)를 두는 것으로 충분해 보인다.

**[2026-10-12 회신] table-sim 문항 (다)·(라) 닫힘.** (라) `TextField`에 `ShowCounter: boolean?`(기본 `true`) — 사용자: *"글자 수 표기 끄기는 넣는거 동의"*; 이름은 킷의 `ShowTicks`·`ShowLabel`·`ShowChannels` 관례를 따랐다. (다) 호스트 `Name`을 기본 Modifier로 — 사용자: *"그렇게 해줘"*, *"지금은 그렇게 처방"*. 사용자가 같이 짚은 것: 호스트 프로퍼티를 컴포넌트 인자에 인라인으로 받는 길이 없는 것은 flatten 슈거가 아직 없어서이기도 하다 — *"flatten sugar 도 나중에 다뤄보자"*(사례 기록 `research/component-flatten-sugar-plan.md` 1절 끝). (다)의 반영: `props.Modifier`를 받는 호스트 전부(이름 56자리)에서 인라인 `Name`을 모듈 수준 Modifier 상수로 옮겼고 기본 이름은 그대로다; 이름으로 호스트를 찾는 킷 내부 조회는 0건이었다. 형제 킷 devui도 같은 모양이어서 같은 날 같은 관례로 맞췄다(사용자: *"그것도 관례대로 만들어두자"* — 이름 29자리, `FieldModifier`·`TrackModifier`를 받는 안쪽 호스트 포함, 내부 이름 조회 0건). 나머지 (가)·(나)·(마)·(바)·(사)는 열려 있다. Studio는 그날 쓸 수 없었다(샌드박스 환경 패치 대기) — 두 변경 모두 스펙으로만 확인.

**table-sim 피드백 오후 추가분 [2026-10-12] — 결정 문항 넷과 메인 의견.** 판정은 `feedback/table-sim-2026-10-12.md`의 "추가분" 절. (차) **끌어서 순서를 바꾸는 목록** — 사용자 본인이 그쪽에서 요청해도 된다고 한 것. table-sim은 줄마다 ▲▼를 뒀다가 *"하나하나 눌러 순서 반영하려면 엄청 오래걸림"*으로 손으로 짰는데(줄 높이를 상수 72로 가정, 끄는 동안 줄이 움직이지 않음, 터치 없음), 줄의 실제 자리·높이·끄는 모습·가장자리 스크롤·길게 눌러 집기는 킷 안에서만 제대로 된다. 그쪽 제안 모양은 `ListData`에 `OnReorder(from, to)`와 손잡이 자리 — 놓으면 콜백만 부르고 `Items`는 소비자가 고친다(서버 권위와 맞는 계약). 메인 의견: 만든다. M3 목록 지침에 끌기 손잡이가 있고(Compose material3에는 완성 부품이 없어 정본은 지침의 그림과 동작 서술이 된다), 시트 끌기에서 쓴 입력 장치(`Interaction`의 끌기 추적, ClickSink 규칙)를 그대로 쓴다. 이름·props는 사용자 결정. (카) **가장자리에서 떨어진 사이드 시트** — 사용자 본인이 넘기겠다고 한 것(*"create 영역 둥글기 없는게 뭔가 약간 다르네 … 구현이 없다면 quad쪽에 해달라 요청해볼게"*). 표준 `SideSheet`는 가장자리에 붙고 모서리가 없으며, 정본 MDC에는 "시트에 여백이 있으면 붙은 쪽 모서리를 지우지 않는다"는 갈래가 이미 있다(`SideSheet/Surface.luau` 머리 주석이 인용하는 `SideSheetBehavior.java` 176-194) — 킷에 여백을 주는 길이 없을 뿐이다. 메인 의견: 여백 옵션을 넣는다(여백이 있으면 네 모서리가 둥글고 그림자) — 정본에 있는 갈래를 여는 것이라 의견이 아니라 구현 공백에 가깝다. 이름(`Margin` 등)과 기본 모양(모서리 값·그림자 단계)은 사용자 결정. (타) **값을 받아 값을 내는 타입 달린 파생** — `state:Compute`의 콜백은 핸들(`self`)을 받아 `self:Get()`으로 읽는데, 소비자는 "값 → 값" 함수를 쓰고 싶어 헬퍼를 만든다(table-sim `text`·`flag`·`tint`·`tableFlag` 수십 자리, 킷 갤러리 `Common.text`). 헬퍼가 해 주는 것은 둘이다 — 콜백 모양(`(T) -> U`)과 반환 타입 주석을 한 곳에 모으는 것. 인라인 람다의 매개변수 추론 한계(`typing-limits.md` 8.13)는 헬퍼로도 안 풀려 주석은 여전히 필요하다. 메인 의견: 세 번째 사례라 근거는 찼다. 다만 표면은 quad 쪽(`Operator`류 또는 State 메소드)이라 이름과 자리를 사용자와 정해야 하고, 2026-10-06의 "타입은 바꾸지 않고 luau-lsp를 기다린다"와 겹치는지도 같이 봐야 한다 — 상위 검토 묶음(훅·인터랙션, Ctx/Memo, flatten 슈거)에 넣기를 권한다. (파) **`TextField`의 숫자 입력** — 숫자만 받는 변형이나 입력 거르기가 없다(table-sim은 문자열로 받아 `tonumber`). Compose는 `KeyboardOptions`/입력 변환, MDC는 `inputType`. 메인 의견: 한 번 관측이라 보류 — devui 킷에는 `InputNum`이 있다는 것만 그쪽에 알린다.

**table-sim에서 올라오지 않은 필요 [2026-10-12 저녁] — 조사 결과와 메인 의견.** 그쪽 feedback 폴더 밖(사용자 평·설계 문서·손으로 짠 부품)에서 찾은 일곱, 목록과 근거는 `feedback/table-sim-2026-10-12.md` 끝 절. 메인 의견만: (1) **세그먼트 버튼** — M3 정본에 있는 부품인데 킷에 없다. 정본 그대로라는 원칙상 빈칸이고 table-sim이 손으로 두 번 짰다. 넣기를 권한다 — 다만 Compose의 `SegmentedButton`과 M3 Expressive의 버튼 그룹(연결된 버튼) 중 어느 쪽을 정본으로 할지는 사용자 결정(킷은 SplitButton·LoadingIndicator처럼 Expressive 쪽 부품을 이미 받았다). (2) **알림의 자리** — 스낵바는 정본이 "아래, 한 번에 하나"다. 자리 자체는 Compose에서 호스트를 놓는 쪽이 정하므로 호스트에 위쪽 배치 옵션을 여는 것은 정본과 어긋나지 않는다 — 넣기를 권한다. 여럿을 쌓는 것은 정본에 없는 다른 부품(토스트 스택)이라 따로 결정. (3) **코어 GUI 인셋·화면 크기** — 사용자가 직접 겪은 것(모달 시트가 코어 GUI에 가림)이고 우회가 세 곳이다. 킷이 `contentWindowInsets`를 뺀 근거("ScreenGui의 `ScreenInsets`가 안전 영역을 맡는다")가 실제로 통하는지부터 Studio에서 봐야 한다 — 통하면 README 한 줄(오버레이를 싣는 ScreenGui 설정), 안 통하면 오버레이·시트에 인셋을 주는 길이 필요하다. Studio가 돌아오면 첫 실측 항목. (4) **터치의 툴팁 길게 누르기** — M3 정본 동작이다(터치에는 호버가 없어 길게 눌러 띄운다). 킷이 미뤄 둔 것이라 터치를 볼 때 같이. 좌표로 여는 컨텍스트 메뉴도 그때. (5) **색 점 줄** — 정본 부품이 아니고 근거가 한 화면이라 보류. (6) **아이콘** — 아이콘 팩 계획의 근거로(table-sim이 실제로 필요했던 이름: visibility, add, drag handle, expand more). (7) **타이포 미사용** — 그쪽에 이유를 묻는다.

관련 계획: 아이콘 팩 `research/icon-pack-plan.md`(사용자 결정 다섯 대기), material 킷·아이콘 팩은 게시 때 quad 레포 밖으로 분리(메인 권고 — 사용자 미확정).
