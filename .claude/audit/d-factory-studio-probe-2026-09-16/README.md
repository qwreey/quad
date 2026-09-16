# D 팩토리화 Studio 실측 팩 (2026-09-16)

생성 `Declaration`(5250줄, 340KB)을 **Luau 타입 함수로 대체**할 수 있는지 판정하기 위한 Studio 쪽
실측 묶음. 리눅스(luau-lsp 1.69.0 + `scripts/roblox-defs/globalTypes.d.luau`)에서 나온 결과는 각
파일 주석과 아래 표에 적어 뒀고, **Studio가 같은 답을 주는지**가 이 팩의 질문이다. 사용자 결정
사항(2026-09-16): Roblox 타입을 모르는 체커는 애초에 지원 범위가 아니다(`UDim2` 같은 기본 타입부터
막힌다) — 그래서 대조 축은 "Roblox를 아는 두 구현", 즉 luau-lsp와 Studio 내장 분석기다.

## 준비

1. Studio에서 **새 타입 솔버(Luau Type Solver V2) 베타**를 켤 것 — 안 켜면 `type function` 문법
   자체가 "syntax not supported"로 죽는다(01번에서 바로 드러난다).
2. 이 폴더에서 `rojo serve probe.project.json` → Studio 플러그인으로 연결(스크립트는 `src/` 아래 — 프로젝트 파일이 든 폴더를 `$path`로 잡으면 rojo가 중첩 프로젝트로 무한 재귀해 stack overflow로 죽는다, 2026-09-16 실측).
   - `ServerScriptService/dprobe/` 아래에 `src/`의 01~06이 들어간다.
   - `ReplicatedStorage/quad-roblox/`도 같이 싱크된다(05번 대조군이 쓴다).
   - rojo 없이 스크립트 편집기에 그대로 붙여 넣어도 된다(02·05만 경로에 의존).
3. 스크립트 분석 창(보기 → 스크립트 분석)을 열어 둘 것 — 타입 함수의 `print`는 **출력 창이 아니라
   진단**으로 나온다.

## 무엇을 봐 달라는 것인가

| 파일 | 묻는 것 | 리눅스 luau-lsp 결과 |
|---|---|---|
| `01-basics.luau` | type function을 아는가, 같은 파일에서 평가하는가 | 평가함(`[P1] ran` + 잘못된 값에 에러) |
| `02*-*.luau` | **다른 모듈**의 type function을 평가하는가, 정의 모듈이 자기 인스턴스화를 해 둬야 하는가 | 프라임됨=평가함 / 프라임 안 됨=**조용히 무진단**(2-c) |
| `03-classdump.luau` | Studio의 클래스 타입 데이터가 luau-lsp의 defs와 **같은 것**을 주는가 | Frame=1>GuiObject=50>GuiBase2d=15>…, **전부 rw**(읽기 전용 표시 없음), 이벤트는 `Connect`를 가진 테이블 |
| `04-factory.luau` | 타입 함수가 만든 props/Modifier 테이블에서 **진단과 자동완성**이 나오는가 | 진단 전부 정상, 체이닝 정상, 한도 플래그 없이 클린 |
| `06-events.luau` | Studio의 `extern:RBXScriptSignal`에서 type function이 콜백 시그니처를 꺼낼 수 있는가(03 후속) | 테이블 경로: `Connect` 파라미터 2개(self, 콜백); Studio 재실행 결과는 `REPORT.md` |
| `05-current-d.luau` | 오늘의 생성 D는 Studio에서 어떤가(대조군) | 한도 플래그(`LuauTarjanChildLimit` 등) 없이는 100군데쯤에서 "too complex" |

가장 중요한 두 가지:

- **(A) 03번의 `[P3-b]` 줄** — Studio가 `AbsoluteSize`/`ClassName`을 **읽기 전용(`r`만)**으로 주는지.
  luau-lsp의 defs에는 읽기 전용 표시가 아예 없어서 전부 `rw`로 나온다. 여기서 두 환경이 갈리면
  "타입 함수가 엔진 타입에서 직접 프로퍼티 집합을 만든다"가 환경마다 다른 표면을 만든다는 뜻이고,
  그러면 읽기 전용·NotScriptable 목록은 지금처럼 **덤프에서 생성한 데이터**로 따로 넘겨야 한다.
- **(B) 04번과 05번의 자동완성 비교** — 중괄호 안에서 `Back`까지 쳤을 때 목록이 뜨는지, 그리고
  05번(오늘의 D)이 Studio에서 "too complex" 없이 도는지. 05번이 Studio에서 이미 한계에 닿아 있다면
  팩토리화는 성능 이유만으로도 값이 있다.

## 보고 형식

파일 번호 + 항목 번호로 짧게 적어 주면 된다(예: `2-c 에러 안 뜸`, `4-b 자동완성 뜸, 05보다 빠름`).
스크립트 분석 창은 내용을 통째로 복사해 주는 게 가장 좋다 — `[P3-a]`/`[P3-b]` 줄이 판정의 핵심이다.
