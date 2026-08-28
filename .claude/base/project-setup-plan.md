# 프로젝트 셋업 — pesde 워크스페이스, `.luaurc`, require 구조

**상태**: base — `architecture.md`의 "구현 착수: 소스 트리 구조 확정" 절이
정한 소스 트리를 **실제로 pesde/luau CLI로 셋업해보고 검증한 결과**. 그
절은 "무엇을 어디에 두는가"까지만 다루고 "그걸 실제로 어떻게 굴리는가"는
비워뒀는데, 이 문서가 그 나머지 — 패키지 매니저 조작, require 문법,
현재 환경에서 확인된 한계까지. **[2026-08-19 신설, 같은 날 pesde 실제
설치·`pesde install` 실행으로 검증]**

**전제**: 이 문서가 서술하는 건 **M0/M1 스캐폴딩 단계에서 확인된 사실**이지
M2 이후 실제 구현이 아님 — `quad-base/src`는 아직 `Relate.luau`/골격
`New()`/`Debug` 서브시스템뿐이고 `quad-roblox/src`는 비어 있음
(`.claude/todos.md`가 여전히 진행 상황의 소스). 여기 적힌 require/pesde
규칙은 실제 소스가 늘어나도 안 바뀔 구조적 사실이라 base로 승격했지만,
"무엇이 구현됐는가"는 이 문서가 아니라 `todos.md`/`ROADMAP.md`를 볼 것.

## 왜 wally가 아니라 pesde인가

**사용자 결정(2026-08-19)**: dev-dependency를 1급으로 지원하는 등 wally보다
툴링이 낫다는 판단. 상세 배경/재검토는 `architecture.md`의 "구현 착수:
소스 트리 구조 확정" 절 "패키징 방식" 문단이 소스 — 여기서 반복하지
않음. 요지만: 모노레포 모양(루트 통합 개발, 서브패키지마다 독립 게시)
자체는 안 바뀌고, pesde의 네이티브 workspace 기능이 그 모양에 그대로
들어맞는다.

## pesde 워크스페이스 구조

**전체 멤버 목록·최신 트리는 `architecture.md`의 "구현 착수: 소스 트리
구조 확정" 절이 소스** — 새 워크스페이스 멤버가 늘 때마다 그쪽만 갱신하면
되게 하기 위해 여기서 다시 나열/개수 세지 않는다(멤버 수가 실제로 2→3→4로
늘어난 이력에서 이 문서의 구식 트리가 갱신을 놓쳤던 게 계기). 아래는 그
구조가 실제로 동작하는 **pesde 메커니즘 자체**(문법/함정)만 다룬다 —
예시엔 최소 2-멤버 형태만 남겨두고 서술 부담을 줄임:

```
quad/
├── pesde.toml          # 워크스페이스 루트, private = true, workspace_members
├── mise.toml            # pesde/rojo/luau-lsp/selene 버전 핀
├── quad-base/
│   ├── pesde.toml       # name = "qwreey/quad_base"
│   └── selene.toml
└── quad-roblox/
    ├── pesde.toml       # name = "qwreey/quad_roblox", quad_base에 workspace 의존
    └── selene.toml
```

- **루트 `pesde.toml`**: `private = true`(게시 안 됨) + `workspace_members`
  (멤버 목록은 `architecture.md`가 소스). `[target] environment = "roblox"`도
  필요(공식 workspace 가이드 예제가 루트에도 `[target]`을 요구함 — 이
  세션엔 `roblox` 하나만 있어 실제로 검증 안 됨, 필요 여부/의미는 M5 이후
  재확인 후보).
- **서브패키지 `pesde.toml`**: `[target] environment = "roblox"` +
  `build_files = ["src"]` + `lib = "src/init.luau"`. `quad-roblox`는
  `[dependencies] quad_base = { workspace = "qwreey/quad_base", version =
  "^" }`.
- **⚠️ 패키지 이름은 `a-z`/`0-9`/`_`만 허용 — 하이픈 금지**(`pesde
  install` 실측: `qwreey/quad-base`는 파싱 단계에서 바로 거부됨, 에러
  메시지가 "did not match any variant of untagged enum
  DependencySpecifiers"로 나와서 원인 파악에 혼동을 줌 — 실제 원인은 이름
  문자 제약이지 의존성 선언 문법이 아니었음). **`quad_base`/`quad_roblox`로
  확정** — 폴더 이름(`quad-base`/`quad-roblox`)은 `architecture.md`가
  이미 확정해둔 것이라 그대로 두고, `pesde.toml`의 `name` 필드만 언더스코어로
  다르게 쓴다. 둘이 다르다는 걸 헷갈리지 말 것.
- **`pesde add`는 워크스페이스 멤버를 자동으로 못 찾는다** — 레지스트리
  검색 전용 커맨드라 로컬 워크스페이스 형제를 이름으로 넘기면
  "package not found"로 실패한다. `[dependencies]`의 `workspace = "scope/name"`
  줄은 **직접 손으로 쓸 것**(위 표기 그대로 — 실제로 `pesde install`이
  받아들이는 걸 확인함).
- **`pesde install`은 워크스페이스 루트에서 한 번**만 돌리면 **모든
  워크스페이스 멤버**가 스캔·링크됨(개수는 `architecture.md`의
  `workspace_members`가 소스 — 새 멤버가 늘어도 이 동작은 안 바뀜).
- **[2026-08-19 후속, `type-version-check` 신설 때 실측] 의존하는
  워크스페이스 멤버의 `target`이 자기 자신의 기본 target과 다르면
  `workspace = "..."` 의존 선언에 `target = "..."`를 명시해야 한다.**
  `quad-types`(기본 target `roblox`)가 `type-version-check`(자기
  `[target] environment = "luau"`)에 의존할 때, `target` 없이 `{
  workspace = "qwreey/type_version_check", version = "^" }`만 쓰면
  `pesde install`이 `no workspace member found with name
  qwreey/type_version_check and target roblox`로 실패한다 — `target =
  "luau"`를 추가해야 해소됨.

## 툴체인 — `rokit.toml`에서 `mise.toml`로 전환 (2026-08-19)

원래는 `initreq/vide`(참고 레포)의 `rokit.toml` 선례를 따랐음(같은 날
`pesde`/`rojo`/`luau-lsp` 셋 다 `/code/.local/bin`에 직접 다운로드해
설치·핀과 버전 일치까지 검증). **같은 날 후속 세션에 `mise.toml`로
재전환** — 사용자 결정("요즘은 rokit 보단 mise로 까는듯 하네. 더
범용적이라 이걸 택하는듯"), 근거는
`Word30210/roblox-project-example`(`initreq/roblox-project-example`로
클론해 확인)의 `mise.toml`. `rokit`은 이 샌드박스에 아예 없어 한 번도
직접 검증 못 했던 반면, **`mise`는 이 샌드박스 자체가 이미 `luau` 설치에
쓰고 있어서 `mise install`을 그 자리에서 실행해 진짜로 검증**함 —
`pesde`/`rojo`/`luau-lsp`/`selene` 넷 다 GitHub artifact attestation +
SLSA provenance 검증까지 거쳐 설치됨(이전 세션이 `curl`로 직접 받던
방식보다 공급망 신뢰도가 높음), `mise exec -- <tool> --version`으로
버전 일치까지 확인. `mise.toml`의 tool 키는 백엔드 접두사가 붙는다
(`github:owner/repo` / `aqua:owner/repo`) — `rokit.toml`의 `owner/repo@ver`
평문 표기와 형태가 다르니 그대로 베끼지 말 것.

**darklua는 검토 후 채택 안 함** — 참고 레포는 `.darklua.json`의
`convert_require` 룰로 경로 기반 require를 빌드 시점에 Rojo sourcemap
기준 `script.Parent`류로 변환하는데, **사용자 판단(2026-08-19)**: "Roblox
안에서도 이미 string require가 적용되긴 하고, `@self`와 `@game`이
먹는다. 같은 동작을 하지만 `./` 등으로 위치를 어떻게 두냐에 유의가
필요할 뿐" — 즉 실제 Roblox 엔진도 이 세션이 확인한 것과 같은
require-by-string 의미론(`@self` 등)을 그대로 지원하므로, darklua로 다른
형태로 변환할 필요성 자체가 낮다는 판단. quad-base는 엔진 무관이어야
하므로 애초에 Roblox 전용 변환의 적용 대상도 아님.

**[2026-08-19 후속 확인 — 정확한 경계]** `darklua` 바이너리(0.19.0)를
직접 설치해 참고 레포에서 실제로 `darklua process`를 돌려 정확히 어디까지
관여하는지 확인:
- **`require("@self/X")`/`require("@game/...")`는 `convert_require`가
  아예 손을 안 댐** — `unable to require resource: unknown source name
  '@self'`로 경고만 찍고 원문 그대로 통과시킴. 즉 예약 alias는 런타임이
  직접 처리한다고 전제하고 있고, 이 세션의 결론과 정합.
- **커스텀 `.luaurc` alias(`@pkg` 등)는 다르다 — `convert_require`가
  실제로 `@pkg/assets`를
  `require(game:GetService('ReplicatedStorage'):WaitForChild('roblox_packages'):WaitForChild('assets'))`
  로 치환함**(`.luaurc`의 alias 매핑 + Rojo sourcemap을 같이 읽어서
  해석 — 대상 파일이 실제로 존재해야 성공, `pesde install` 전엔 실패).
  즉 **커스텀 alias 기반 require를 실제로 쓰려면 darklua(또는 동급
  빌드 스텝) 없이는 배포 시점에 그 문자열이 그대로 남아 동작을 보장할
  근거가 없다** — standalone `luau` CLI가 커스텀 alias를 거부하는 것과
  같은 결(`could not jump to alias`), Roblox 엔진이 예약 alias 밖의
  커스텀 alias까지 자체적으로 푼다는 근거는 없음.
- **결론**: quad는 커스텀 alias를 전혀 안 쓰고 상대경로+`@self`만
  쓰므로 지금은 darklua가 불필요. **나중에 `@pkg/quad_base`류 축약
  alias를 도입하고 싶어지면 그때는 darklua(혹은 동급 변환)가 실질적으로
  필요해진다** — 그 시점에 이 절을 다시 열 것.

## require 구조 — `@self`가 필수인 이유

**[2026-08-19, 사용자 지적 + Luau RFC `abstract-module-paths-and-init-dot-luau`로 확인]**

`init.luau`라는 파일은 require-by-string 상 **자기가 든 폴더 자체**를
가리키는 특수 취급을 받는다 — 그래서 그 파일 **안에서** 쓰는 상대
경로는 일반 파일과 기준점이 다르다:

- **`init.luau` 안에서 `require("./X")`/`require("../X")`** — 이 폴더
  자체가 "자기"이므로, 상대 경로는 **이 폴더의 형제/조상**을 가리킨다.
  즉 `quad-base/src/init.luau` 안의 `./Debug`는 `quad-base/src/Debug`가
  아니라 `quad-base/Debug`를 가리킨다(존재하지 않으면 즉시 에러).
- **`init.luau` 안에서 그 폴더 *안의* 형제 파일에 접근하려면
  `@self/X`를 써야 한다** — `@self`는 예약 alias로, 이 모듈(=이 폴더)
  자신의 경로로 치환된다. `quad-base/src/init.luau`가
  `quad-base/src/Debug`에 접근하려면 `require("@self/Debug")`.
- **일반 파일(`init.luau`가 아닌 `*.luau`)에서는 평범한 파일-상대
  경로**(`./`/`../`)면 충분 — `@self`가 전혀 필요 없다. 예:
  `quad-base/src/Debug/init.luau`(이것도 init.luau라 위 규칙이 적용됨)
  안에서 형제 `Relate.luau`(`quad-base/src/Relate.luau`, `Debug`
  폴더의 부모에 있음)를 가져오려면 — `Debug/init.luau`의 "자기"는
  `Debug` 폴더이므로 그 부모(=`quad-base/src`)에 있는 `Relate.luau`는
  형제 폴더 취급 → `require("./Relate")`(◯), `require("../Relate")`(✕,
  한 단계 더 올라가 `quad-base/Relate`를 찾으려다 실패).

**실측 근거**: `tbox`(`initreq/tbox`, 다른 참고 레포)의 `src/init.luau`가
`require("@self/types")`/`require("@self/schema/string")` 패턴을
실제로 쓰고 있어 교차 확인됨. 이 세션에서 `quad-base/src/init.luau`가
처음에 `require("./Debug")`로 잘못 짜여 크로스파일 require가 전부
깨졌었고(런타임은 크래시, `luau-analyze`는 **조용히** `Unifiable<Error>`로
새며 0 진단으로 통과 — 이것도 `typing-limits.md`의 "실측 방법 주의"
경고("`luau-analyze`가 진단 0건이어도 타입이 제대로 해소됐다는 뜻이
아닙니다")가 가리키는 것과 같은 종류의 함정, 다만 원인은 재귀 제네릭이
아니라 require 경로 오류라 그 문서 1번 항목과는 별개 사례), `@self`로
고치자 즉시 정상화됨(둘 다 clean).

**체크리스트**: 새 `init.luau`를 짤 때마다 "이 파일 안의 `require`가
같은 폴더 안의 형제를 가리키는가, 아니면 이 폴더의 형제/조상을
가리키는가"를 먼저 물을 것 — 전자면 `@self/`, 후자면 `./`나 `../`.

## 워크스페이스 의존성은 심볼릭 링크로 연결된다 — CLI 테스트의 함정

**[2026-08-19 실측]** `pesde install`이 워크스페이스 멤버 간 의존성을
해소하는 방식은 **심볼릭 링크**다 — `quad-roblox/roblox_packages/`
안에 실제로 이렇게 생긴다:

```
quad-roblox/roblox_packages/
├── quad_base.luau              # 얇은 링커: return require("./.pesde/qwreey+quad_base/0.0.0/quad_base/src")
└── .pesde/qwreey+quad_base/0.0.0/quad_base/
    ├── src   -> ../../../../../quad-base/src    (symlink)
    ├── test  -> ../../../../../quad-base/test    (symlink)
    ├── pesde.toml -> ...                          (symlink)
    └── pesde.lock -> ...                          (symlink)
```

**⚠️ 문제**: Luau의 standalone require-by-string 구현은 **심볼릭 링크를
안 따라간다** — 의도된 설계다(Luau RFC 검색 결과: "보안 상의 이유로
symlink는 일반 파일처럼 취급되고 따라가지 않는다", 추후 `.luaurc`에
opt-in 토글이 추가될 수 있다고만 언급됨, 아직 없음). 직접 재현:

```lua
-- entry.luau, ./linked가 실제 폴더로의 symlink일 때
local v = require("./linked")
-- error requiring module "./linked": could not resolve child component "linked"
```

**실무 영향**: `quad-roblox`가 실제로 `quad_base`를 쓰게 되면(M5+),
표준 경로(`require(".../roblox_packages/quad_base")`)는 **`luau` CLI로
직접 못 돌린다** — `could not resolve child component`로 즉시 깨짐.

**[2026-08-19 후속 세션, 확인 완료] Rojo/Studio는 이 문제와 무관함 —
`rojo`를 같은 방식으로 `/code/.local/bin`에 설치해 직접 검증.** `quad-roblox/`
아래 `src`+`roblox_packages`를 매핑하는 임시 project.json으로
`rojo sourcemap`을 돌려보니, symlink를 정확히 따라가 실제 파일까지
해소함을 확인:

```json
{"name":"src","filePaths":["../quad-base/src/init.luau"],
 "children":[
   {"name":"Debug","filePaths":["../quad-base/src/Debug/init.luau"]},
   {"name":"Relate","filePaths":["../quad-base/src/Relate.luau"]}
 ]}
```

`rojo build`(실제 `.rbxm` 생성)도 같은 트리로 에러 없이 성공. 즉 Rojo는
`fs::canonicalize`류 평범한 파일시스템 API로 트리를 만들어서 symlink를
투명하게 통과하고, 위 함정은 **Luau standalone CLI의 require-by-string
전용 문제**로 확정 — Studio 배포 경로엔 영향 없음. Studio 자체(플러그인
연동)까지는 아직 미검증(`HUMAN_TODO.md` 1번, 계정 분리 대기)이지만,
`rojo build`/`sourcemap` 레벨에서 이미 심볼릭 링크 순회가 확인됐으므로
Studio도 같은 파일시스템 계층을 쓰는 이상 다르게 동작할 이유가 없다.

**우회가 필요한 범위는 M0/M1식 CLI 스파이크/mock 테스트로 좁혀짐**:
`roblox_packages/`를 거치지 말고 실제 형제 패키지 경로를 직접 가리킬
것 — 예: `quad-roblox/src`에서 검증용 스크립트를 짤 때
`require("../../quad-base/src")`처럼. **프로덕션 `quad-roblox` 소스
자체는 그대로 표준 pesde 경로(`roblox_packages/quad_base`)를 쓸 것** —
Rojo/Studio가 실제로 소비하는 게 그 경로이고 위에서 확인했듯 문제없이
동작한다.

**[2026-08-19 셋째 후속 세션] 이 함정이 이제 `quad-base` 자기 자신의
프로덕션 진입점에도 실제로 닥침** — `quad-types` 워크스페이스 패키지가
신설되며 `quad-base/src/init.luau`가 `require("./roblox_packages/quad_types")`를
쓰게 됐는데(`quad-types-plan.md` 참고), 이건 M0/M1 스파이크가 아니라
**실제 출하 소스**라 위 "우회는 스파이크에만"이라는 구분이 더 이상
깔끔하게 안 맞음. 이 세션이 실제로 쓴 해법: `pesde install`이 만든
심볼릭 링크를 **로컬 CLI 테스트용으로만** 실제 디렉토리 복사본으로
치환(`find . -type l ... cp -r`류, 저장소 파일은 안 건드리고
`roblox_packages/.pesde/`의 링크만 대상) — Rojo/Studio는 이미 symlink를
투명하게 처리하므로 배포 경로엔 아무 영향 없고, 순수 이 샌드박스의
`luau`/`luau-analyze` 실행을 가능하게 하는 로컬 조치다.
**⭐ [2026-08-26 정정, 8라운드 `H-123`] 이건 이미 스크립트로 정식화됐다** —
여기 한때 *"아직 반복 가능한 스크립트/mise task로 정식화하진 않음 — 매번
`pesde install` 후 수동으로 치환했음"*이라고 적혀 있었으나, 7라운드 `H-78`이
**`scripts/relink.sh` + `scripts/test.sh`를 신설**했고 둘 다 커밋돼 있다
(8라운드에서 실제로 실행해 확인). 지금 규칙은 하나다 — **테스트는
`./scripts/test.sh`로 돌린다**(그 스크립트가 `relink.sh`를 먼저 부른다).
그냥 `luau`로 돌리면 스모크가 죽고 `luau-analyze`는 모듈을 `any`로 떨어뜨려
**조용히 통과**한다("거짓 클린"). **[2026-08-28 M2 첫 단위, `H-165`] 둘째
함정 — `quad-types`에 `export type`을 추가하면 `pesde install`을 다시 돌려야
한다.** pesde가 만드는 링크 파일(`quad-base/roblox_packages/quad_types.luau`)은
`return module` 위에 **그 시점에 존재하던 export 타입만** `export type X =
module.X`로 손으로 나열한 shim이라, `quad-types/src/init.luau`에 타입을 새로
export해도 shim을 재생성하기 전엔 `QuadTypes.Ref` 같은 참조가 "Unknown type"으로
죽는다(`relink.sh`는 복사만 갱신하지 shim은 못 고친다 — 실측). `test.sh`는
**[2026-08-28]** `luau-analyze`도 같이 돌리므로 이 실패는 조용하지 않다. Luau의
`.luaurc` symlink opt-in 토글이 미래에 생기면 이 절 전체가 불필요해짐 —
그때 다시 볼 것.

**[2026-08-19 같은 날 넷째 후속 세션] 의존 대상의 `target`에 따라 링크
디렉토리 이름이 달라진다** — `quad-types`(target `roblox`)가
`type-version-check`(target `luau`)에 의존하면, `quad-base`/`quad-roblox`가
쓰는 `roblox_packages/`와 달리 `quad-types/src/init.luau`는
`require("./luau_packages/type_version_check")`로 **`luau_packages/`**
아래에서 링크를 찾는다 — pesde가 의존 대상 패키지 자신의 target 이름으로
디렉토리를 분리하기 때문(`.gitignore`에 `luau_packages/`도 이미
포함돼 있어 별도 조치 불필요).

같은 워크어라운드가 2단 의존 체인에도 그대로 재적용됨 — `type-version-check` 신설로
`quad-types`→`type-version-check`가 추가되면서 `quad-base`/`quad-roblox`→
`quad-types`→`type-version-check`처럼 깊이 2인 워크스페이스 의존 그래프가
생겼는데, `pesde install` 후 같은 심볼릭 링크 치환을 반복 적용하는 것만으로
`luau-analyze`/`luau` 양쪽 다 문제없이 동작 확인됨 — 이 우회가 단일
깊이에 국한되지 않고 일반화됨이 실측으로 재확인됨.

## `.luaurc` — alias는 여전히 편집기 전용

`.luaurc`의 `aliases`(`@quad-base`/`@quad-roblox`)는 **런타임
require에서 여전히 안 먹는다** — `architecture.md`가 이미 이렇게
서술해뒀던 걸 이 세션에 직접 재확인: `require("@quad-base/Debug")`를
실행하면 `could not jump to alias "quad-base/src"`로 실패(별도 에러
메시지라 위 심볼릭 링크 문제와는 다른 원인 — alias 자체가 런타임
미지원이라는 뜻, `@self`는 **예약 alias**라 이 제약과 무관하게 항상
동작하는 것과 구분할 것). 그래서 alias는 편집기 자동완성/타입체크
용도로만 남기고, 실제 require는 위 규칙대로 상대경로 + `@self`.

## `selene` 린터 — 패키지별 설정, CWD 상대 config 탐색 함정

**[2026-08-19 신설]** 사용자 결정으로 `selene`(참고 레포
`initreq/roblox-project-example`의 `scripts/selene.toml` 그대로 채택)을
도입 — `luau-analyze`(타입체크)와 겹치지 않는 별도 축(정의되지 않은
변수, 사용 안 하는 변수, `assert` 메시지 누락 등 스타일/버그 패턴
린트)이라 같이 씀. `quad-base/selene.toml`/`quad-roblox/selene.toml`
각각 독립 배치(참고 레포도 패키지마다 독립 설정) — 아래 실측 이유 때문에
루트 단일 설정은 안 씀.

**⚠️ `selene`의 `--config` 탐색은 파일 트리를 거슬러 올라가며 찾는 게
아니라 CWD 기준 고정 경로(`./selene.toml`)다.** 루트에 `selene.toml`
하나만 두고 `selene quad-base/`를 저장소 루트에서 실행하면, 그 자리엔
`selene.toml`이 없어(패키지 폴더 안에 있으므로) **Luau 문법 자체를 못
읽는 기본(Lua 5.1) std로 조용히 폴백** — `type Quad = {...}` 같은 평범한
타입 선언까지 전부 "unexpected token" 파싱 에러로 쏟아짐(30여 건, 전부
가짜). 처음엔 이게 "이 selene 빌드가 Luau 타입 문법을 아예 지원 못
한다"는 뜻인 줄 알았으나, `std = "luau"`가 든 `selene.toml`을 CWD에
두면 정확히 같은 파일이 0 에러로 통과함 — 즉 **문제는 selene의 Luau
지원이 아니라 config 탐색 방식**이었다.

**규칙**: 항상 **패키지 디렉토리 안에서** 실행할 것 —
`cd quad-base && selene .`(참고 레포의 Justfile도 정확히 이 패턴으로
각 패키지를 순회함, `refresh`/`clean` 레시피). 저장소 루트에서
`--config quad-base/selene.toml quad-base/`처럼 명시적으로 경로를
지정해도 되지만, 그럴 거면 그냥 `cd`가 더 안전(설정 파일 지정을
빠뜨리기 쉬움).

## `pesde.lock` — 커밋한다 (2026-08-26 확정)

**[2026-08-19 실측, 최초 서술 정정]** 처음엔 "워크스페이스 루트에 딱
하나만 생긴다"고 적었으나 **틀렸음** — 실제로는 `pesde install`이
**워크스페이스 멤버마다 각자의 `pesde.lock`도 같이 만든다**(루트
`pesde.lock` 1개 + 멤버마다 1개씩, 개수는 `architecture.md`의
`workspace_members`를 따라간다 — 2026-08-19 이 세션 안에서만 2개
멤버(2+1개 lock)에서 4개 멤버(4+1개 lock)로 늘어난 전례가 있어 여기 숫자를
고정하지 않는다). 루트 것은 `[workspace."qwreey/quad_base"]`류 멤버 매핑만
담고, 멤버 것들은 각자의 실제 의존성 그래프를 담는다(`quad_roblox`의
lock엔 `[graph."qwreey/quad_base@0.0.0 roblox"]` + `pkg_ref.ref_ty =
"workspace"`가 있음, `quad_base`는 의존성이 없어 메타데이터만).

**이 세션의 잠정 권고는 셋 다 커밋**: Cargo 생태계의 "라이브러리는
lockfile을 커밋하지 않는다" 관행이 여기 그대로 적용 안 되는 이유는, 이
lockfile들이 **게시되는 대상이 아니기** 때문 — 루트는 `private = true`,
`quad-base`/`quad-roblox`의 `pesde.toml`도 `includes = ["src/*"]`뿐이라
`pesde.lock`은 애초에 게시물에 안 들어감(외부 소비자는 이 파일들을 절대
못 봄 — 자기 프로젝트에서 새로 resolve함). 그래서 "라이브러리 lockfile
딜레마" 자체가 성립하지 않고, 그냥 "이 모노레포를 체크아웃한 개발자/CI가
재현 가능한 빌드를 얻는가" 문제로 좁혀지는데 그건 커밋하는 쪽이 유리 —
**⭐ [2026-08-26 확정, 8라운드 `H-123`] 사용자 확정 — 전부 커밋한다.**
여기 한때 *"이건 이 세션의 판단이고 최종 확정 아님, `todos.md`에 확인 필요
항목으로 반영"*이라고 적혀 있었으나 **그 반영이 실제로는 어디에도 없었고**
(`question.md`/`todos.md`/`HUMAN_TODO.md` grep 0건), 실태는 lockfile이 이미
전부 커밋돼 있어 위 잠정 권고와 일치했다. 현 실태 그대로 확정하고 열린
항목에서 뺀다.

## 확인 완료 / 아직 확인 안 된 것

**확인 완료(이 세션, 실제 pesde/luau 실행 근거)**:
- pesde 워크스페이스 설치가 당시 워크스페이스 멤버 전부(그때는
  루트+2서브)에 대해 성공(**[2026-08-19 후속]** 이후 `quad-types`/
  `type-version-check` 추가로 멤버가 늘어난 뒤에도 같은 절차로 계속 성공 —
  아래 후속 문단들 참고)
- 패키지 이름 문자 제약(하이픈 금지)
- `workspace = "scope/name"` 의존성 선언 문법
- `@self`가 `init.luau`의 형제 파일 접근에 필수라는 것(런타임+
  `luau-analyze` 양쪽)
- `.luaurc` alias가 런타임에서 여전히 안 먹는다는 것(재확인)
- 워크스페이스 의존성이 symlink로 연결되고, 그게 `luau` CLI의
  require-by-string과 충돌한다는 것(직접 재현 + Luau RFC로 원인 확인)
- **[2026-08-19 후속 세션]** Rojo(`/code/.local/bin`에 직접 설치,
  `7.7.0`, 툴체인 핀과 일치)는 위 symlink 문제와 무관 — `rojo
  sourcemap`/`rojo build` 둘 다 `roblox_packages`의 symlink를 실제
  파일까지 투명하게 따라감을 확인. 위 심볼릭 링크 함정은 Luau standalone
  CLI의 require-by-string 전용 문제로 범위가 좁혀짐
- **덤 확인** — `rojo`가 PATH에 잡히자 `luau-lsp`(에디터)가 자동으로
  `rojo sourcemap default.project.json --output sourcemap.json --watch`를
  백그라운드로 띄움(루트 `default.project.json` 기준). 즉 지금 이
  워크스페이스에서 에디터 타입 링킹이 실제로 살아있다는 뜻 — wally가
  안고 있던 "설치된 패키지의 타입 정보 단절" 문제가 이 구성에선 재현
  안 됨(`architecture.md`가 pesde 전환의 배경으로 들었던 문제 자체가
  실제로 해소됐다는 간접 증거). 산출물 `sourcemap.json`은 재생성되는
  빌드 산물이라 `.gitignore`에 추가
- **[2026-08-19 셋째 후속 세션]** `mise.toml`이 `pesde`/`rojo`/`luau-lsp`/
  `selene` 넷 다 정확히 설치·버전 일치함을 `mise install` + `mise exec`로
  직접 확인(attestation/provenance 검증까지 포함) — `rokit`은 끝내
  한 번도 직접 검증 못 했던 것과 대비됨
- `selene`의 `--config` 탐색이 파일 트리를 안 거슬러 올라가고 CWD
  기준 고정 경로라는 것(위 "`selene` 린터" 절)

**아직 확인 안 됨(다음에 도구/환경이 갖춰지면)**:
- 루트 `pesde.toml`의 `[target]` 섹션이 실제로 의미가 있는지(지금은
  workspace 가이드 예제를 그대로 따라 둔 것, 검증 안 됨)
- Roblox Studio 자체(플러그인 연동)까지의 실제 동기화 — `rojo
  build`/`sourcemap` 레벨은 확인됐지만 `HUMAN_TODO.md` 1번(계정 분리)이
  되기 전까진 Studio 실물로는 미확인
- `quad_base` 설치 시 나온 "`roblox_sync_config_generator` 스크립트가
  없으면 linking에 문제가 생길 수 있다"는 WARN의 실제 영향 범위 — 지금은
  install 자체를 막지 않아서 방치, 실제 Rojo 동기화 단계에서 문제가
  드러나면 그때 pesde 문서의 `[target.scripts]` 절을 찾아볼 것
- ~~`pesde.lock` 커밋 여부 최종 확정~~ — **[2026-08-26 해소]** 커밋하는
  것으로 확정(위 절).
