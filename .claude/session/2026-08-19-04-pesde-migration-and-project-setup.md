# 2026-08-19, 네 번째 세션 — M0/M1 스캐폴딩 첫 시도, wally→pesde 전환, `@self` require 함정

**요약**: 사용자 요청으로 M0(스파이크)/M1(스캐폴딩)을 revert 가능한
상태로 실제로 짜보며 문제를 찾는 시도. 그 과정에서 진짜 문제(require
경로 버그)를 하나 찾았는데 원인 진단이 틀렸었고, 사용자가 직접 정답
(`@self`)을 지목해 정정. 이어서 사용자가 패키지 매니저를 wally에서
pesde로 바꾸자고 결정, tbox 참고 후 실제 pesde를 설치해 워크스페이스
전체를 검증. 산출물은 `.claude/base/project-setup-plan.md`(신설)와
`architecture.md`의 "패키징 방식" 절 정정.

## 1. M0/M1 첫 실제 시도

`ROADMAP.md` M0(스파이크 3종)/M1(스캐폴딩)을 실제로 Luau로 짜봄:
- M0 항목 3(재귀 재-dispatch)은 기존 스파이크 `03`을 재실행해 여전히
  유효함만 확인(재작성 불필요).
- M0 항목 1(다이아몬드 전파)은 `05-store-state-diamond-propagation.luau`를
  "emit은 항상 전파 + `:Get()` 시점 캐시로만 dedup" 현행 모델로 재작성,
  통과 후 `done/`으로 이동.
- `todos.md`가 M0 항목으로 요구하던 "Store 미선언 키가 타입 에러 나는가"도
  새 스파이크 `21`로 확인 — `luau-analyze`가 정확히 2건의 `TypeError`로
  거부함을 확인(사용자의 "아마 그럴 것" 추측이 맞았음).
- M1: `quad-base/`, `quad-roblox/` 폴더, `Relate.luau`(전량 구현),
  `Debug/init.luau` + 최상위 `init.luau`(`New()`/`InitXxx` 팩토리
  체이닝 + `Relate` 기반 멱등 가드), `quad-base/test/mock.luau`(최소
  mock) + 스모크 테스트까지 작성.

## 2. require 버그 — 원인을 잘못 짚었다가 사용자가 정정

`quad-base/src/init.luau`(`require("./Debug")`)가 크로스파일 require
전부 실패. 여러 각도로 재현하다 "standalone `luau` CLI가 relative
require를 **process CWD** 기준으로 푼다"는 결론을 냈고, 이 결론으로
첫 보고를 마쳤음(**틀린 진단**).

사용자가 바로잡음: *"init.luau 는 상위 폴더를 자신으로 만들어낸다는
의미라, @self 로 주변 요소를 접근해야해"* + Luau 공식 문서 링크 제공.
`rfcs.luau.org/abstract-module-paths-and-init-dot-luau`를 확인한 결과:
`init.luau`는 require-by-string 상 **자기가 든 폴더 자체**를 가리키는
특수 케이스라, 그 안의 `./X`는 그 폴더의 형제를 가리키고, 폴더
**안의** 형제 파일을 가리키려면 예약 alias `@self/X`가 필요함 — CWD와는
무관한 문제였음. `quad-base/src/init.luau`의 `require("./Debug")`→
`require("@self/Debug")`, `Debug/init.luau`의 `require("../Relate")`→
`require("./Relate")`로 고치자 즉시 정상화(런타임 clean, `luau-analyze`
0 진단). 부수로 `Relate.luau`의 진짜 타입 내로잉 버그 2건도 이때 처음
드러나 같이 고침(전에는 require가 안 뚫려 그 부분이 타입체크 자체를 안
받고 있었음).

**교훈**: CWD 기반이라는 첫 결론은 "여러 재현 케이스가 다 맞아떨어졌다"는
확신 때문에 유지했는데, 실제로는 초기 가설(구조적 require 특수 케이스)을
검증 안 하고 다른 잘못된 가설로 건너뛴 것 — 사용자가 정확한 1차 소스
(공식 문서)를 제시해줘서 빠르게 정정됨.

## 3. tbox 확인 → pesde 결정 → 실제 설치·검증

사용자 요청: `tbox`(`initreq/tbox`) 확인 후 "pesde로 가야 할 것 같다"
(dev-dependency 등 더 나은 툴링). `tbox`엔 pesde/wally 설정 자체가 없었지만
(독립 스키마 라이브러리, 패키지 매니저 미사용), `src/init.luau`가
`require("@self/...")` 패턴을 실제로 쓰고 있어 위 2번 정정을 교차
확인해줬고, `.vscode/settings.json`이 `enableNewSolver: true`를 이미
켜둔 것도 `HUMAN_TODO.md` 6번(에디터 솔버 확인)에 참고 근거로 남음.

pesde 실물 설정은 `initreq/vide`(`pesde.toml`+`rokit.toml` 보유)를
템플릿으로 씀. 이어서 사용자가 직접 pesde 공식 설치 문서 링크를 주고
`/code/.local/bin`(이미 PATH)에 설치해보라고 요청 — GitHub 릴리스에서
`pesde-0.7.3-linux-x86_64.zip`을 받아 압축 해제 후 그 경로에 배치,
`pesde 0.7.3` 확인(`rokit.toml`의 핀과 정확히 일치).

**실제 `pesde install`을 워크스페이스 루트에서 돌려서 나온 것들**(전부
`.claude/base/project-setup-plan.md`에 정리):
1. 패키지 이름에 하이픈 불가(`a-z`/`0-9`/`_`만) — `qwreey/quad-base`가
   파싱 단계에서 거부됨(에러 메시지가 원인을 안 알려줘서 처음엔 의존성
   선언 문법이 잘못된 줄 알았음). `quad_base`/`quad_roblox`로 고침.
2. `workspace = "scope/name"` 의존성 문법은 원래 손으로 쓴 그대로
   맞았음(이름만 고치니 바로 통과) — `pesde add`는 워크스페이스 멤버를
   못 찾는다는 것도 같이 확인(레지스트리 전용 커맨드).
3. `pesde.lock`은 워크스페이스 루트에 딱 하나만 생김.
4. **가장 중요한 발견** — 워크스페이스 의존성은 **심볼릭 링크**로
   연결됨(`roblox_packages/.pesde/scope+pkg/version/pkg/src` →
   실제 형제 패키지 경로). 실제로 `quad_base`를 `quad-roblox`에서
   `require`하는 스모크 테스트를 짜보니 "could not resolve child
   component 'src'"로 깨짐 — 직접 격리 재현(`/tmp`에 symlink 하나만
   만들어 `require`) 후 원인이 **Luau의 require-by-string이 symlink를
   의도적으로 안 따라간다**(보안상의 이유, RFC 검색으로 확인, 향후
   `.luaurc` opt-in 토글 가능성만 언급되고 아직 없음)로 확정.
   `quad-roblox`가 실제로 `quad_base`를 쓰게 될 M5부터 이 문제가
   현실화됨 — Rojo/Studio는 아마 무관(파일시스템 워크라 symlink를 그냥
   따라갈 가능성이 높음)이지만 이 세션엔 Rojo가 없어 미검증.

## 4. 산출물

- `.claude/base/project-setup-plan.md` 신설 — 위 내용 전부 정리,
  "확인 완료/아직 확인 안 된 것" 절로 후속 검증 항목 명시.
- `.claude/base/architecture.md` "패키징 방식" 절 — wally→pesde 전환 반영.
- `.gitignore` — `roblox_packages/`/`luau_packages/`/`.pesde/` 추가.
- `pesde.toml`(루트+quad-base+quad-roblox), `rokit.toml`, `.luaurc`,
  `default.project.json` 신설.
- `quad-base/src/{Relate.luau,init.luau,Debug/init.luau}`,
  `quad-base/test/{mock.luau,smoke.mock.luau}` 신설.
- `luau-test/05`(다이아몬드 전파, 재작성 후 `done/`), `luau-test/21`(Store
  미선언 키, 신규) — 둘 다 `STATUS.md` 표 텍스트는 아직 안 고침(스스로
  발견한 것 — 다음에 손댈 것).

## 5. 커밋 후 후속 — 05/21 STATUS.md 반영, Rojo 설치·symlink 검증

사용자가 산출물(문서화+셋업 파일)만 먼저 커밋하길 원해 그렇게 진행(`tooling:`
커밋). 이어서 4가지를 전부 순서대로 진행하기로 함(사용자: "전부 차근차근
진행해보면 될듯 함") — (1) `05`/`21` STATUS.md 텍스트 반영 후 별도 커밋
(`qa:`), (2) Rojo 설치 후 symlink 처리 검증, (3) 스파이크 `13` 재작성,
(4) `HUMAN_TODO` 6번 에디터 솔버 설정.

**(2) 완료** — pesde와 같은 방식으로 `rojo`도 `/code/.local/bin`에 직접
설치(`7.7.0`, `rokit.toml` 핀과 일치). `quad-roblox/`에 `src`+
`roblox_packages`를 매핑하는 임시 project.json으로 `rojo
sourcemap`/`rojo build`를 돌려본 결과, **symlink를 투명하게 따라가
실제 `quad-base/src/init.luau` 등까지 정확히 해소함을 확인** —
`project-setup-plan.md`가 가장 크게 남겨뒀던 미해결 항목이 이걸로
닫힘. 결론: 이전 세션이 발견한 "workspace 의존성 symlink가 require를
깨뜨린다"는 문제는 **Luau standalone CLI 전용**이고 Rojo/Studio 배포
경로엔 영향 없음(Studio 실물 확인은 여전히 계정 분리 대기,
`HUMAN_TODO.md` 1번). 임시 검증 파일(`test-symlink-check.project.json`)은
확인 후 삭제, 결과만 `project-setup-plan.md`에 반영.

**(3) 완료** — `13-type-ref-preref-subtype.luau`를 타입 전용으로 남기고
(`PostRef<T>`도 `Ref<T>`를 만족하는지 추가), 런타임 절반은 신규
`22-runtime-ref-preref-postref-brand.luau`로 분리(A의 더미 스텁이 B
실행을 막던 문제 해결). `isPreRef`/`isPostRef`가 서로 배타적 형제이고
Leaf 핸들러 흉내가 셋을 정확히 갈라냄을 확인. 둘 다 `done/`.

**(4) 완료** — `luau-lsp` 바이너리(1.69.0)도 같은 방식으로
`/code/.local/bin`에 직접 설치. `luau-lsp analyze
--flag:LuauSolverV2=true/false`로 spike `08`(재귀 제네릭 패턴)을
비교한 결과 새 솔버 필요성 재확인(옛 솔버는 같은 패턴에 에러 3건,
새 솔버는 1건). `quad/.vscode/settings.json`에
`enableNewSolver: true` 반영·커밋. 부수로 typing-limits.md §1의 핵심
주장("`local s = n:Compute(fn); local wrong: number = s:Get()`가 0
진단으로 통과") 자체도 Luau 0.734에서 여전히 재현됨을 별도 최소
repro로 재확인(`s`가 `Unifiable<Error>`로 새는 것, `wrong` 줄은 진단
0건 — base 문서 정정 불필요, 그대로 유효함만 재확인). tbox가 쓰던
`LuauDoNotExportBrokenTypeFunction` override는 quad의 현재 type
function 스파이크(`16`/`21`)에서 유무 차이가 없어 채택 안 함.
`HUMAN_TODO.md` 6번/`typing-limits.md` §8 갱신, `rokit.toml`에
`luau-lsp` 핀 추가.

**남은 사람 몫**: VSCode를 실제로 열어 `.vscode/settings.json` 설정이
반영됐는지 육안 확인(HUMAN_TODO 6번), Studio 실물 동기화(HUMAN_TODO
1번, 계정 분리 대기). 이번 라운드로 이번 대화의 4개 후속 검증 항목은
전부 닫힘.
