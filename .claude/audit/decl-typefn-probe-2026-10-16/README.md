# Declaration 타입 함수 조립 실측 팩 (2026-10-16)

`research/declaration-surface-plan.md`(생성 `Declaration`을 클래스별 타입 복제 대신 타입 함수로 조립)의 첫 실측.
**결정이 아니라 재료**다 — 표면 결정은 사용자. 9월 16일 팩(`audit/d-factory-studio-probe-2026-09-16/`)이 "타입 함수로 props·Modifier
테이블을 만들 수 있다"까지 봤다면, 이번엔 사용자 원문 꼴(`local Frame = New<<Frame>>("Frame")`)·`Modifier<Frame>`·`Spread<<C>>`·
`OnEvent(name, fn)`를 한 라이브러리 모듈(`src/Lib.luau`)에 실제 모양으로 올리고, 체커 간 데이터 차이를 타입 함수 안의 예외 데이터
(`Policy`)로 메울 수 있는지, 비용이 생성 D와 어떤지를 본다. 리눅스 쪽(CLI·LSP 하네스) 결과는 각 파일의 `-- CLI(...)` 주석과 `out/`에 있다.
**Studio·VSCode 관측은 비어 있다** — 아래 "사람 몫"이 채울 자리다.

## 파일

| 파일 | 묻는 것 | 리눅스 결과 한 줄 |
|---|---|---|
| `src/Lib.luau` | 라이브러리 대역 — 디스패처 타입 함수 `Build<Mode, C, Policy>` 하나와 공개 별칭(`Props<C>`·`Modifier<C>`·`Elem<C>`·`SpreadMarker<C>`·`EventMap`…), 값 스텁(`New`·`Spread`·`Modifier`·`OnEvent` 넷) | 단독 검사 클린, 정의 모듈 프라이밍(8.22) 포함 |
| `src/01-new.luau` | `New<<Frame>>("Frame")` 생성자 — props 자동완성·값 진단·읽기 전용·상위 클래스 | 전부 동작. 주석만으로는 C가 안 채워짐, hover가 구조 전개 |
| `src/02-modifier.luau` | `Modifier<Frame>`가 생성 `<Class>Modifier`를 대신하는가 | 체인 자동완성·진단·태그·제네릭 메소드 동작, detail·hover가 재귀 전개 |
| `src/03-spread.luau` | `Spread<<C>>({...})` → `SpreadMarker<C>`, 배열부·안쪽 Spread | 만드는 자리 자동완성·진단, 클래스 소속 대조 동작 |
| `src/04-onevent.luau` | `OnEvent(name, fn)` 이름 자동완성·콜백 인자 추론·클래스 소속 | 이름 자동완성·소속 대조 동작, **무주석 콜백 인자는 unknown** — 커리 꼴만 문맥 타입이 흐름 |
| `src/05-checker-diff.luau` | 체커 간 클래스 데이터 차이를 `Policy`(Deny/DenyIn/Inject)로 흡수 | 두 defs에서 개수 일치, 31 클래스 중 28~29가 생성 D와 키 집합 동일(나머지는 API 버전 차이) |
| `src/06a/06b/06c-*-k20m5.luau` | 비용(생성 파일 — `harness/gen-cost.py 20 5 src --studio`) | 06b(생성 D)는 Studio 전용 경로 |
| `harness/extern-shim/` | Studio처럼 이벤트가 extern 시그널일 때의 경로(CLI 전용 defs shim) | 프로퍼티 꼴 shim 통과, `function` 메소드 꼴 shim은 `Build` 전체가 런타임 에러 |
| `harness/compare/` | 같은 자리를 생성 D로(`gend-lsp.luau`), 두 Modifier의 공존(`coexist.luau`), VSCode용 경로 require 비용 파일(`cost/`) | — |

## Studio 최소 확인 [2026-10-16 추가 — 진단을 한꺼번에 복사할 방법이 없어서]

Studio에는 스크립트 분석 진단을 한꺼번에 읽거나 복사하는 길이 없다(공식 API는 플러그인이 진단을 **넣는** `RegisterScriptAnalysisCallback`뿐, Script Analysis 창에도 전체 복사가 없음 — 메인·sonnet 조사).
그래서 Studio만 답할 수 있는 셋만 최소로 본다: (1) **`00-studio-brief.luau`의 `[BRIEF]` 진단 하나**를 hover해서 복사(05번 전체를 209자 한 줄로 모음 — 리눅스 기대값과 비교),
(2) 06b에 "too complex"가 뜨는지와 맨 끝 NEG 두 줄에 빨간 줄이 있는지(예/아니오), (3) 01~04는 자동완성·hover가 눈으로 쓸 만한지 인상만. 파일별 진단 수 대조가 필요하면
리눅스 vsc 기준 01=14, 02=7, 03=7, 04=18, 05=24, 06a=2, 06c=2(`out/cli-vsc.txt`) — Script Analysis 창의 스크립트별 개수와 비교.

## 사람 몫 — Studio (대상 플레이스 `quad-test`, PlaceId 105962699098904)

준비(싱크는 메인이 한다 — 방법만): 이 폴더의 `probe.project.json`을 `rojo serve`로 띄워 Studio 플러그인으로 연결한다. 프로젝트 파일이 든 폴더를
`$path`로 잡으면 rojo가 중첩 프로젝트로 무한 재귀하므로(9/16 실측) 스크립트는 `src/`만 `ServerScriptService/declprobe`로 들어가고,
`ReplicatedStorage/quad-roblox/{src,luau_packages}`가 06b 대조군용으로 같이 들어간다(9/16 팩과 같은 배치). 새 타입 솔버가 꺼져 있으면
`type function` 문법부터 죽는다. **스크립트 분석 창을 열어 둘 것** — 타입 함수의 `print`(05번의 `[R]`/`[N]` 줄)는 출력 창이 아니라 진단으로 뜬다.

볼 순서와 적을 것(각 파일의 `-- Studio(...)` 자리에, 9/16처럼 괄호 안엔 빨간 줄이 걸린 텍스트):

1. **05번 먼저** — `[R]`·`[N]` 줄 전부를 스크립트 분석 창에서 복사. 판정 셋: Frame·TextLabel·TextButton·ImageButton의 `props=`/`events=`가
   리눅스(38/26, 57/26, 63/34, 58/34)와 같은가, `injected={…}`가 비는가(Studio는 Transparency·FontSize·TextWrap을 원래 가졌다 — 9/16),
   `MouseEnter=event:(number, number) -> ()`인가(extern 경로가 Studio에서 도는가). 여기서 `Build`가 런타임 에러를 내면 나머지 파일도 전부
   죽으니 그 메시지를 먼저 적을 것.
2. **01번** — `Frame({ ` 뒤에서 `Back`·`Mouse`를 쳤을 때 목록, "에러여야 정상" 줄들의 빨간 줄, `Frame` hover 모양.
3. **02번** — `m:` 뒤 `Back`, 체인 중간 `):` 뒤 `Vis` 자동완성, peeked/applied hover.
4. **03번** — `Spread<<Frame>>({ ` 안의 자동완성, e3·nestedBad 빨간 줄.
5. **04번** — `OnEvent("` 따옴표 안 자동완성(몇 개 뜨는가), `function(x, y)`의 x hover — 비커리(ev2b)와 커리(c1)를 비교, `input.` 자동완성 두 자리.
6. **06a·06b·06c** — 파일을 열고 빨간 줄·자동완성이 뜨기까지의 체감, "too complex" 여부, 맨 끝 NEG 두 줄이 잡히는가. **06b가 핵심** —
   리눅스에선 Roblox 동기 플래그 그대로(override 없음)면 생성 D가 too complex로 무너져 NEG가 사라졌다. 9/16 Studio는 too complex가 없었는데
   지금 D(5145줄)로도 그런지.

## 사람 몫 — VSCode (code-server, luau-lsp 확장 1.70.1)

레포를 연 그대로(워크스페이스 `.vscode/settings.json`의 한도 override 셋이 켜진 상태) `src/01~06`을 위 순서대로 열고 `-- Vscode(...)` 자리에 적는다.
06b는 VSCode에서 `Unknown require`가 정상(Studio 경로) — 대신 `harness/compare/cost/costb-gend-k20m5.luau`와 `harness/compare/gend-lsp.luau`를
열면 같은 비교가 된다. **선택 확인 하나**: 워크스페이스 override를 잠시 지우고(사용자 설정에도 같은 블록이 있으니 둘 다) 서버를 재시작한 뒤
`harness/compare/gend-lsp.luau`를 열어 `D.Frame({ ` 자동완성이 사라지는지 — 리눅스 하네스의 sync 모드가 본 것(자동완성 0, hover `*error-type*`)이
실제 편집기에서도 그런지다. 같은 상태에서 `src/01-new.luau`의 자동완성이 그대로인지도.

## 리눅스 실행(에이전트 몫 — 재현 방법)

- `harness/flags.py fetch flags/roblox-sync-2026-10-16.json` — 확장(`dist/extension.js`)이 서버에 보내는 동기 FFlag 재구성(PCStudioApp에서
  `FFlag|FInt|DFFlag|DFInt` + `Luau` 접두 키, 접두 제거; 2026-10-16 633개, `LuauDoNotExportBrokenTypeFunction=False`). 서버는 `--no-flags-enabled`.
- `harness/run-cli.sh <mode> <파일…>` — `luau-lsp analyze`. 모드: `vsc`(확장 번들 1.70.1 + 확장이 받은 globalTypes.PluginSecurity.d.luau(레포 밖, 확장 globalStorage) +
  동기 플래그 + 워크스페이스 override 셋 = 사용자 VSCode), `sync`(같은데 override 없음), `pin`/`pinsync`(레포 핀 1.69.0 + `scripts/roblox-defs`).
  `choom -n 1000` + `prlimit --data=3 GiB`로 감싼다.
- `harness/lspc.py --mode <vsc|sync|pin> <파일…>` — `luau-lsp lsp` stdio 하네스. 파일 안 `-- @c(이름) at='부분문자열' ins='삽입'`(자동완성)·
  `-- @h(이름) at='부분문자열'`(hover) 표식 자리에서 요청하고 pushed diagnostics·응답 시간을 적는다(9/16 스크래치 하네스는 지워져 다시 짬).
- `harness/compare-gen.py <mode>` — 31 클래스의 `Names<C>`를 생성 D의 `<Class>Param` 키와 대조.
- `harness/gen-cost.py <K> <M> <dir> [--studio]` + `harness/cost-run.py <dir> <mode…>` — 비용 파일 생성·순차 측정(wall, 프로세스별 max RSS, NEG 검출).
- `harness/extern-shim/` — `run-cli.sh vsc --definitions=@shim=harness/extern-shim/shim.d.luau harness/extern-shim/05b-extern-events.luau`.

산출물: `out/cli-{vsc,sync,pin}.txt`(01~05 CLI), `out/lsp-{vsc,sync,pin}.txt`(하네스), `out/lsp-gend-compare.txt`(생성 D 같은 자리),
`out/compare-gen-{vsc,pin}.txt`, `out/cost-cli.txt`, `out/cli-05b.txt`, `out/cli-vsc-coexist.txt`.
