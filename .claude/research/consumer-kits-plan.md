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
7. round14 뒤 같이 볼 것(사용자 2026-10-08) — 두 킷이 훅·인터랙션으로 만든 부분(`Interaction`의 hover/pressed/focused State·드래그 추적, `Util.hooks`/`preHook`/`postHook`, `Interactive` 묶음)에서 **quad 상위에서 생각해 볼 것**이 있는지. 사용자: *"내가 잊고 있었다 … round14 이후 같이 보도록 하자"*.

관련 계획: 아이콘 팩 `research/icon-pack-plan.md`(사용자 결정 다섯 대기), material 킷·아이콘 팩은 게시 때 quad 레포 밖으로 분리(메인 권고 — 사용자 미확정).
