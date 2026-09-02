# quad-v2 전체 아키텍처 (현재 상태 요약)

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델(0-A)/Attribute 이름
> 소유권(0-Z) 확정·반영 완료 — 아래 소스 트리도 갱신됨.** 이전 ⚠️ 배너가
> 경고하던 "옛 모델로 짜게 됨" 위험은 해소. 디스패치 코어는
> `base/bind-system-plan.md`에서 **`base/dispatch-core-plan.md`로
> 분리**됐고, `Tag`/`Attribute`는 알고리즘까지 quad-base로 재배치됐음
> (엔진 op만 주입). 뒤집힌 옛 모델은
> `archive/dispatch-hintvalue-model-reversed.md`.

**상태**: base — 횡단 결정의 최종 상태 요약. 특정 기능 plan이 아니라 프로젝트
전체에 걸친 결정이라 완료 개념 없음. 근거가 된 원본 브레인스토밍은
`.claude/initreq/raw-userinput.md`(안 옮기고 그대로 둠 — 이 문서들로 나누기 전의
raw chain-of-thought 백업 역할). 현재 v1 구조는 `reference/quad-v1-architecture.md`,
비교 리서치는 `reference/comparison-fusion-vide.md`, `base/lifecycle-pattern.md` 참고.

## 한 줄 요약

quad는 이제 "스크립트"가 아니라 **라이브러리**다. DOMless Roblox UI 렌더러라는
정체성은 유지하되, 내부를 확장 가능하게 재구현한다. 프로덕트 하나를 빨리 내는 게
목표가 아니라 코드 퀄리티/지속 가능성이 목표 — 빠른 이터레이션보다 정확성이
우선.

## 확정된 결정

1. **DOMless 유지, 하지만 pluggable 하게.** 가상 DOM 없이 즉시 Roblox Instance를
   만드는 기존 방식은 유지. 대신 key/value 바인드 디스패치, 렌더 백엔드를
   pluggable하게 만들어 확장성 확보(아래 4, 5번).
2. **Class는 이제 "특정 상태의 store를 받는 함수"** — v1의 `Class.Extend()`류
   OOP 스타일(메서드 체이닝, Getter/Setter) 대신 함수형이 기본. 체이닝은 store
   바인드처럼 정말 체인이 자연스러운 곳에만(`:` 문법) 남김. 타입 작성 난이도가
   OOP 스타일에서 너무 커진다는 게 이유.
3. **복사(clone) 구현 지양, 팩토리 함수로 대체.** v1의 metatable 체이닝(1-필드
   테이블을 계속 쌓는 방식, `reference/quad-v1-architecture.md` 참고)은 폐기.
   store 바인드에 대한 변경은 "전체 변경"으로 간주(UB 아님, 문서화된 의미론) —
   부분 복사/오버레이가 필요하면 팩토리 함수로 필요한 곳만 명시적으로 복사.
4. **PA님 스타일 특수 키 계속 지원**: `[AttributeKey "Name"]`(구 `Attribute`,
   2026-08-11 아홉 번째 세션에 그룹 `Attribute(...)`와 이름 충돌 방지로
   리네임) 같은 특수 바인드 키, store 컴퓨티드 바인드도 가능해야 함
   (`retract`, 구 cleanup, `base/lifecycle-pattern.md` 참고). **[정정,
   2026-08-08 세 번째 세션]** `Tag`는 더 이상 `[Tag ""] = true` 해시 파트
   특수 키가 아님 — array-part 값 객체(`Tag(...)`)로 재설계됨,
   `base/tag-plan.md` 참고(`archive/tag-hash-key-model-reversed.md`에 구
   모델 보존). **[2026-08-11 아홉 번째 세션]** `Attribute(...)`도 여러
   Store를 한 번에 attribute로 묶는 array-part 값 객체로 신설(`Tag`와
   동형), `base/attribute-plan.md` 참고.
5. **id 기반 전역 조회 폐지, Tag 시스템으로 대체.** v1의 `Store.GetObject(id)`/
   `Frame "id" {}`류는 더 이상 없음 — "id 매핑이 비현실적"이라는 게 이유.
   네임스페이싱 문제는 있지만 별도 네임스페이스 개념을 추가하면 라이브러리
   복잡도가 너무 올라간다고 판단 — 당장은 `CollectionService` 그대로 사용. **대신
   Ref가 도입됨** — 단 Ref의 용도는 "id로 조회"가 아니라 "외부에서 이미
   관리되고 있는 instance를 quad로 점진적으로 마이그레이션/래핑하기 위해
   직접 참조를 얻는 것"(`base/ref-plan.md`의 Ref 절 참고) — 둘을
   혼동하지 말 것.
   - **2026-08-04 6차: 네임스페이싱 충돌을 심각하게 안 보는 이유 확정.**
     충돌을 피해야 하는 단위는 보통 컴포넌트 단위로 나오고, 그 경우는 Ref로
     직접 참조를 얻으면 되므로 태그 자체의 전역 네임스페이스가 굳이 필요
     없음. 태그는 원래 주로 스타일링(스타일시트 셀렉터) 용도인데, 스타일시트는
     적용 위치가 트리 상위에 존재해야 하고 사용자가 직접 그 위치에 심어야
     하는 등 스크립팅으로 구성하기 어려워 quad 같은 UI 라이브러리에서는 잘
     안 쓰는 접근 — 그래서 스타일시트 대신 modifier kit을 제공하는 것(아래
     7번 항목의 modifier 우선순위 규칙 참고).
6. **함수지향 디폴트, `:` 체이닝은 예외적으로만.** 스토어 바인드처럼 체인이 정말
   편한 경우만 `:` 사용, 나머지는 외부 함수가 인스턴스를 인자로 받는 모양.
7. **Style(Default) 시스템 폐기.** 대신 modifier(spread되는 값, `...`으로
   풀리는 것)를 지향 — 함수형 modifier가 store 바인드를 받을 수도 있음.
   (초기 근거였던 "Roblox 자체 스타일시트를 쓰는 게 낫다"는 6차 라운드에서
   갱신됨 — 위 5번 항목의 6차 추가분 참고: 스타일시트는 적용 위치 제약과
   스크립팅 난이도 때문에 오히려 안 쓰기로 하고 modifier kit으로 대체함.)
   - **2026-08-04 세션: modifier 메커니즘 전체 확정, 상세는
     `base/modifier-plan.md`로 분리.**[정정: `research/`에서 `base/`로
     승격됨] 요지만: 런타임 pluggable 핸들러가
     아니라 디스패치 이전에 정적으로 flatten되는 값(핸들러 레지스트리 미참여,
     CSS cascade 문제 회피). Merge 우선순위는 "배열 순서상 나중 modifier가
     우선"과 "인라인 키는 modifier보다 무조건 우선"이라는 독립된 두 규칙(Lua
     테이블 리터럴이 배열/해시 파트 간 소스 순서를 보존 안 하므로 하나로 합칠
     수 없음). 값은 immutable — 체이닝 메소드(`:FontSize(...)`류)는 항상
     `table.clone` 후 반환, 원본 mutate 금지(형제 서브트리 오염/재렌더 드리프트
     방지, 비용은 무시 가능한 수준으로 확인됨).
8. **특수 이벤트는 특수 플러깅으로.** `PropertyChangedSignal`, `PropertyChangedEvent ""`
   같은 것들은 일반 이벤트 바인드가 아니라 pluggable 바인드 핸들러 중 하나로
   구현(`base/dispatch-core-plan.md`).
9. **Tracker 미구현.** v1의 소스 변경 감지 자동 재렌더 기능(hot-reload watcher,
   실제로는 `.claude/initreq/quad/src/tracker.lua` — v1에서도 이미 `exports.lua`에
   연결 안 된 죽은 코드였음, `reference/quad-v1-architecture.md` 참고)은 렌더
   라이브러리 범위 밖으로 판단. 스토리북 구현체(https://ui-labs.luau.page/docs/getstarted)가
   이미 존재하므로 대체.
10. **lang 모듈 미구현, 분리.** 로케일/문자열 처리는 리액터블 라이브러리와
    별개 라이브러리로 존재해야 함(v1 `lang.lua`의 전역 스코프 버그 등은
    `reference/quad-v1-architecture.md` 참고 — 애초에 반면교사).
11. **커스텀 Signal 클래스 미구현.** 콜백 정도로 이벤트 바인드 뒤에 함수를
    넣는 것만으로 충분하다고 판단. (이전 초안엔 "rbvm의 Signal이 재사용
    가능해 보여 상충한다"는 메모가 있었으나 2026-08-04 검증 라운드에서 최종
    확정으로 재확인 — 더 이상 열린 질문 아님.)
12. **멀티 타겟(pluggable 백엔드) — 특히 GTK 지원까지 염두.** Roblox 전용 렌더
    기술(react.lua, Fusion)은 결국 외부 개발자 유인이 없어 발전이 더딜 거라는
    문제의식. 결과적으로 `quad-base`/`quad-roblox`로 나뉨(5차 라운드에서 확정된
    정확한 패키지 이름, 아래 "구현 착수" 절 참고) — base가 가상돔 없이도
    프로바이더 패턴으로 백엔드를 받는 인터페이스만 정의하고, 실제 Roblox 구현은
    `quad-roblox`가 담당.
13. **모듈은 기본 싱글톤, `New()`는 추가 인스턴스가 필요할 때만.**
    **[재정정, 2026-08-19 — 이전 정정(`New()`→`Quad()` 전면 치환)이
    부정확했음, `/code-review high` 이후 사용자가 직접 바로잡음]** `New`와
    `Quad`가 이름이 다투는 게 아니다 — 이전 정정이 "미래 API 이름은
    `Quad()`"라고 단정하며 `New()`를 전부 `Quad()`로 바꿨던 게 틀렸다.
    사용자 원문: *"내가 말한건 Quad() 만 제공하면 항상 모든 Quad 요구처에서
    각각의 Quad() 를 수행해서 새로운 모듈 스코프가 나온다는게 문제였어.
    그래서 Quad 는 기본적으로 생성된걸 리턴하긴 하는데, Quad.New() 도
    제공하는거 어떻냐는거였음, 즉 New() 는 존재하고 기본 리턴은 New() 해서
    주는건데, 리턴 안에 New 필드가 있고 그 함수를 쓰면 하나의 새로운 Quad
    네임스페이스가 만들어지는식. 안 그러면 모든 컴포넌트를 나눈 모델
    등에서 Quad() 를 해서 새로운 모듈 스코프가 나와서, 래핑된 Quad() 를
    수행하는 부분을 따로 작성해두어야한다던가 해질꺼임."*
    - **`Quad`(`require`의 반환값, 호출 아님)는 이미 만들어진 기본
      인스턴스 자체다** — 모듈 로드 시점에 그 모듈 자신이 내부적으로
      `New()`를 한 번 불러 만든 결과를 그대로 top-level 반환값으로 내보냄.
      그래서 평범한 소비자는 아무것도 호출할 필요 없이 `require(quad)`가
      돌려준 걸 바로 `Quad.Dispatch`처럼 씀(지금 싱글톤 단계와 동일한
      접근 방식 — 달라지는 게 없음).
    - **`Quad.New()`가 명시적 opt-in으로 설계됨**(**구현은 아직 미착수** —
      지금은 싱글톤 단계라 `New` 필드 자체가 아직 안 노출됨, 바로 아래
      "M0 스캐폴딩에 주는 함의" 참고) — 다중 인스턴스화가 실제로 붙는
      시점엔 반환된 기본 인스턴스 **안에** `New` 필드(함수)가 생기고,
      이걸 실제로 호출하면 완전히 **별도의 새 Quad 네임스페이스**
      (자기만의 Dispatch 레지스트리 등)가 나오는 모양으로 짠다. Roblox +
      비-Roblox 프로바이더를 진짜로 동시에 써야 하는 드문 경우에만 이걸
      쓰게 될 것.
    - **왜 "그냥 `Quad()`를 부르면 새 인스턴스"로 안 하는가** — 컴포넌트를
      여러 파일/모듈로 쪼갠 실제 앱에서는 각 파일이 독립적으로 "Quad
      인스턴스 하나 줘"를 요청하게 되는데, 그 요청 방법 자체가 "새로
      만들기"라면 **파일마다 서로 다른, 서로 공유 안 되는 인스턴스**를
      만들게 되는 사고가 난다(Dispatch 레지스트리가 안 공유되는 등) —
      그러면 앱 전체가 하나의 공유 부트스트랩을 따로 작성해서 그걸 통해서만
      Quad를 얻도록 강제해야 함. `require`가 이미 인스턴스화된 기본값을
      주면 이 위험 자체가 원천적으로 없음 — 새 인스턴스가 필요한 그 드문
      경우만 명시적으로 `.New()`를 부르면 되므로 실수로 스코프가 갈라질
      일이 없다.
    한 Lua 스레드에서 Roblox/비-Roblox 프로바이더를 동시에 쓸 일이 거의
    없을 거라 판단해 지금은 `New()` 없이 싱글톤만 두고, 필요해지면 그때
    `New()`를 노출한다. **메커니즘도 이미 정해짐(2026-08-08 두 번째 세션,
    새 설계 아니라 기존 패턴의 자연스러운 연장)**: v1처럼 `require`를 감싸
    `Init(QuadId?)`로 격리 인스턴스를 만드는 방식은 안 씀 — 대신 지금 있는
    "팩토리가 `BaseModule`을 뮤테이션" 패턴(14번) 그대로, 매번 새
    `BaseModule` 테이블을 만들어 팩토리로 채우는 것뿐. 상세 근거는
    `base/dispatch-core-plan.md`의 "Dispatch는 프리미티브가 아니다" 절.
    **[정정, 2026-08-18 구현 전 QA]** 옛 서술은 그렇게만 하면 지금
    module-level state로 사는 모든 것(`_initializedBy` 마커, Dispatch
    레지스트리 등)이 **"자동으로" 테이블별 스코핑된다**고 했는데, 사용자
    판정은 다르다 — *"모듈이 하나의 인스턴스(dispatch 레지스트리 하나,
    canExecute 등 계약 필드 하나) 만 가지고 있다면 예. 단, 나중에 …
    require 를 감싸지는 않고 단순히 InitModule(module) 등을 받도록 각
    코드들을 약간 고쳐서 이것을 해결함."* 즉 **코드 변경 없이 자동으로**
    되는 게 아니라, module-level state를 참조하는 코드들이 모듈 인스턴스를
    인자로 받도록 **손을 대야** 한다 — `New()`가 실제로 호출되면(위 opt-in
    경로) 그 순간 만들어지는 새 `BaseModule` 테이블에 대해 이 손질이 필요.
    **지금은 `New()` 자체가 노출 안 된 싱글톤 단계라 `Quad.Dispatch`로
    바로 접근**한다. `New()` 자신이 내부적으로 어떤 형태로 조립되는지(v1
    스타일 `InitXxx(module)` 팩토리 체이닝, 타입 재익스포트)는
    `module-lifecycle-plan.md`의 "New()의 내부 구성" 절 참고.
    - **⭐ [2026-08-31 `H-186`, 사용자 확정] 다중 `New()` 지원은 "같은
      인스턴스 안"이 전제다 — 인스턴스를 **가로지르는** 값 혼용(`A`의
      `Effect`에 `B`의 `Source`를 dep으로, `A`의 핸들을 `B`의
      `bindLifetime`에)은 **UB**. 막는 가드를 일부러 안 둔다 — dep 쪽
      가드는 절반만 막고(교차 `bindLifetime`은 base가 못 봄), 완전히
      막으려면 주입 op 계약까지 번진다. 문서화 대상
      (`research/documentation-content-map.md` §4 — `H-116` 두 벌 공존
      항목의 이웃), M5에서 실 백엔드가 둘이 되면 재검토("추후 생각해볼 점").
    - **M0 스캐폴딩에 주는 함의 — [2026-08-19] 정해짐, 실제로는 M0가 아니라
      `ROADMAP.md` M1(실제 스캐폴딩)에 적용됨.** 레지스트리를 module-level
      upvalue로 직접 잡아두면 나중에 다중 인스턴스화할 때 전면 수정이
      된다는 우려가 있었는데, 바로 위에서 가리키는 InitXxx 패턴(각
      `InitXxx(module)`가 `module`을 upvalue가 아니라 **파라미터로 받아**
      뮤테이션)이 처음부터 그 형태다 — 나중에 바꿀 일 자체가 없게 M1
      스캐폴딩부터 이 모양으로 짠다. M0는 독립 스파이크 파일로 개별
      가설만 검증하는 단계라 이 구조 자체를 아직 안 씀(`ROADMAP.md`의
      "M0 — 스켈레톤 + 기술검증" 절 참고).
14. **pluggable 초기화는 팩토리 함수로.** rbvm처럼 네임스페이스 하나하나 수동
    init 하는 방식(`base/lifecycle-pattern.md` 5번 항목 참고)은 피하고,
    `InitRoblox(Module)` 같은 팩토리 함수가 생성된 모듈을 뮤테이션하는 도구를
    주는 방식.

## 구현 착수: 소스 트리 구조 확정 (2026-08-04, 5차 라운드)

**상태**: 소스 트리 레이아웃과 `quad-base`/`quad-roblox` 패키지 경계 확정 —
아래가 다음 세션에서 실제로 만들 구조. 지금은 문서 확정까지만, 실제
폴더/`wally.toml`/`project.json` 스캐폴딩은 다음 세션.

**패키징 방식(모노레포, RbxUtil 선례 채택) — [2026-08-19 정정] 패키지
매니저를 wally에서 pesde로 전환.** 원래는 wally 툴링 불안정(설치된 패키지의
타입 정보 단절·`luau-lsp` 심볼릭 링크 해석 문제)을 이유로 "최종적으론 독립
패키지로 쪼개고 싶지만 당장은 모놀리식"으로 타협했었는데, **사용자 결정
(2026-08-19): pesde로 간다** — dev-dependency를 1급으로 지원하는 등 wally보다
툴링이 낫다는 판단. **모노레포 자체의 모양(루트 통합 개발, 서브패키지마다
독립 게시)은 안 바뀜** — `Sleitnick/RbxUtil`이 wally로 하던 바로 그 패턴을
pesde는 **네이티브 workspace**(Cargo 워크스페이스와 동형: 루트
`workspace_members` + 멤버 간 `{ workspace = "scope/name", version = "^" }`
의존)로 처음부터 1급 지원하므로, wally가 안고 있던 타입 정보 단절 문제
자체도 이 전환으로 같이 해소됨 — **[2026-08-19 같은 날 후속 세션]**
pesde/rojo 바이너리를 이 샌드박스에 직접 설치해 `pesde install`/`rojo
build`까지 실제로 돌려 링크 결과를 확인 완료(`base/project-setup-plan.md`가
소스, 워크스페이스 의존성이 symlink로 연결되고 Rojo는 이를 투명하게
따라감).
실제 구현: 루트 `pesde.toml`(`private = true`,
`workspace_members = ["quad-base", "quad-roblox", "quad-types",
"type-version-check", "quad-error"]` — 다섯째 멤버는 **[2026-08-31 `H-231`]**) +
`quad-base/pesde.toml`/`quad-roblox/pesde.toml`/`quad-types/pesde.toml`
(**[2026-08-31 `H-234` 사용자 결정]** quad-base·quad-types는 `[target]
environment = "luau"`다 — 엔진 무관 코어·타입 계약이라 처음부터 roblox일
이유가 없었고, luau 의존(`quad-error` 등)이 `luau_packages`로 들어와 rojo
트리에서 빠지는 문제의 근본 해법. `roblox`로 남는 건 `quad-roblox`뿐,
경위는 `base/project-setup-plan.md`의 `H-234` 문단) + `type-version-check/pesde.toml`
(`[target] environment = "luau"`, 아래 참고), 툴체인은 `mise.toml`로 핀
(`rokit.toml`에서 전환, 2026-08-19 사용자 결정 — 더 범용적인 도구라는
판단, `base/project-setup-plan.md`의 "툴체인" 절 참고). **[2026-08-19 같은
날 후속]** `type-version-check`(`[target] environment = "luau"` — quad에
종속되지 않은 범용 패키지라 다른 멤버와 달리 roblox가 아님)는 워크스페이스
네 번째 멤버로 추가됐고, `quad-types`가 이것에 workspace 의존(자기 target이
roblox라 명시적으로 `target = "luau"` 지정 필요) — `base/quad-types-plan.md`의
"`type-version-check`" 절이 소스. 사용자가 나중에 독립 저장소로 분리할
예정(`HUMAN_TODO.md` 9번).
**[2026-08-19 같은 날 셋째 후속 세션]** `quad-roblox`는 `quad-base`가
아니라 **`quad-types`(구현 없는 타입 계약 전용 패키지)에만 workspace
의존** — `quad-base`는 `QuadRoblox(Quad): QuadRoblox` 패턴으로 **런타임
주입**받으므로 pesde 의존 선언이 필요 없고, 오히려 무거운 quad-base
전체를 dev-dependency로 두면 게시 후 소비자 환경에서 그 타입 전용
require가 크래시하는 문제가 있어 별도 패키지로 뽑음 —
`base/quad-types-plan.md`가 소스.
pesde는 "패키지 안에 `default.project.json`을 두지 말 것"이 컨벤션(그
파일은 소비자가 직접 만드는 sync 설정 몫) — 루트의 `default.project.json`은
이 규칙의 예외가 아니라 애초에 그 규칙이 가리키는 대상이 아님(워크스페이스
루트 자신의 통합 개발/테스트용, 게시되는 패키지 안이 아니므로).
`.luaurc`의 `aliases`는 여전히 **런타임 require에서 엔진이 지원 안 함**
(2026-08-19 이 세션에 커스텀 alias로 직접 재확인 — `require("@alias/x")`가
"could not jump to alias"로 실패) — 그래서 alias는 편집기 자동완성/타입체크용으로만
곁들이고, 실제 크로스패키지 require는 상대경로로 쓴다(단, `init.luau`
안에서는 평범한 상대경로가 아니라 **예약 alias `@self`**를 써야 함 —
`init.luau`는 require-by-string 상 "자기 폴더 자체"를 가리키므로 `./`가
아니라 `@self/`로 그 폴더 안의 형제 파일에 접근한다, 2026-08-19 사용자 지적
+ Luau RFC `abstract-module-paths-and-init-dot-luau`로 확인 — 실제로 이
세션의 `quad-base/src/init.luau`가 이 착오로 크로스파일 require가 전부
깨졌다가 `@self`로 고치고 나서야 정상화됨). 나중에 실제로 레포를 쪼갤 때는
Rojo `project.json`의 트리 매핑 규칙만 유지하면 되고, require는 그 시점에
한 번 기계적으로 바꾸는 정도로 감수.

**패키지 경계**: `quad-base`는 다른 렌더 백엔드(GTK 등, 항목 12 참고)에서도
재사용 가능해야 한다는 전제 — Store/State/Source 온톨로지+전파뿐 아니라
**pluggable 디스패치 엔진 자체도 "인터페이스"로 base가 소유**한다(엔진마다
큰 구현을 중복하지 않기 위함 — rbvm이 relation을 하나로 통합하려 했던 것과
같은 동기). `quad-roblox`는 그 인터페이스의 **실제 구현체**만 제공.
**[2026-08-13 열네 번째 세션 확장] 이 원칙은 "값 타입"이 아니라 "부기가
엔진 지식을 요구하는가"로 가른다** — `Tag`의 참조 카운트와 `Attribute`의
이름 claim/그룹 위임은 엔진과 무관한 순수 부기라 **핸들러째로 quad-base**,
백엔드는 `addTag`/`removeTag`/`setAttribute` 세 op만 주입한다(웹에도
`className`/`data-*`라는 대응물이 있어서, 그러지 않으면 같은 알고리즘이
백엔드마다 복제됨). 반대로 Property/Event/OnChange는 Reflection·시그널
자체가 로직이라 그대로 백엔드 소속 — 상세 기준과 op 시그니처는
`base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진
op" 절.

```
quad/
├── .luaurc                      # 편집기 경험용 alias(런타임 비의존, `base/project-setup-plan.md` 참고)
├── mise.toml                     # pesde/rojo/luau-lsp/selene 버전 핀
├── pesde.toml                    # 워크스페이스 루트(private, workspace_members)
├── default.project.json         # 루트 통합 개발/테스트용 Rojo 프로젝트
├── quad-types/                   # 구현 없는 Quad 타입 계약 + CheckedQuad<T,Pattern> 버전체크(`base/quad-types-plan.md`)
│   ├── pesde.toml                 # type_version_check + quad_error workspace 의존(`ErrorNamespace` 타입 재export용 — `H-231`)
│   └── src/init.luau
├── type-version-check/           # quad에 종속되지 않은 범용 버전 패턴 매칭(`base/quad-types-plan.md` "`type-version-check`" 절) — 사용자가 나중에 독립 저장소로 분리 예정(HUMAN_TODO 9번)
│   ├── pesde.toml                 # [target] environment = "luau"
│   └── src/init.luau              # matchesPattern(런타임) + export type function CheckVersion
├── quad-error/                   # [2026-08-31 `H-231`, 사용자 설계] 레벨 태그 에러 유틸 — setFuncLevel(fn, layer) 맵 + debug.info 스택 워크(최상단 하강)로 errorAt/errorBefore가 프레임 수 손 세기 없이 원하는 계층에 blame. type-version-check와 같은 지위(quad 비종속 범용, [target] environment = "luau"), quad-base가 workspace 의존(target="luau"). 태그 체계·기존 error 자리 이관은 round12 `H-231` §4가 소스
│   ├── pesde.toml                 # [target] environment = "luau"
│   └── src/init.luau              # 상태 없는 new(): Namespace(사본 분리 해법) + getToplevel. Namespace: setFuncLevel/getFuncLevel/getFirstMatch/getNearestMatch/errorAt/errorBefore/errorAtNearest/errorBeforeNearest(안쪽 스캔 쌍은 사용자 확정 이름)
├── quad-base/
│   ├── pesde.toml
│   └── src/
│       ├── Source.luau           # 값의 근원, 단일 지점. Source가 State를 구조적으로 만족(`__index` 델리게이션)
│       ├── State.luau            # 캐시만 하는 non-owning 핸들, state(state) 분기, `:With`/`:Compute`/`:Observer`(등록 즉시 1회 실행)/`:Gate`(`GateNode`, `ComputeNode`와 같은 층위 — `base/gate-plan.md`) 전부 여기 소속
│       ├── Observer.luau        # ⭐ [2026-08-25 신설, 7라운드 `H-99`] `Observer` 객체와 **`:Subscribe()`/`:WeakSubscribe()` 전역 레지스트리의 소유 모듈** — `EpochMap.luau`와 같은 이유로 `State.luau`에 묻지 않는다(`Effect`/`Gate`/leaf 핸들러가 전부 이 레지스트리를 본다 — **[2026-08-27 `H-144` (b)]** `Effect.luau`는 이 두 테이블과 `canBound`만 공유하고 네 진입점 본문은 자기 것)
│       ├── EpochMap.luau         # 재사용 가능한 Epoch 부기 객체(`:Update`/`:Refresh`/`:Sync`/`:TrackFrom`) — `State.luau`에 묻지 않고 별도 모듈, `GateNode`/`State`/`Effect`가 전부 씀(`base/state-epoch-plan.md`)
│       ├── Store.luau            # source 집합체, dot-access로 Source 그대로 반환(**평범한 레코드 필드** — 타입 함수 안 씀). **[2026-08-25]** 생성은 **명시적 초기화**(타입 인자에 `Source<T>` 직접, `defaults`에도 `Source(v)` 직접 — 옛 lazy `__index` 폐기), 동적 키는 `:Of<<T>>(name)` 하나(옛 `GetDynamic` 흡수), `:Names()`, 예약 키 진단용 `CheckReservedKeys<keyof<T>>`(**[2026-08-26 `H-112`]** 옛 이름 `CheckReserved`는 `T`를 통째로 받아 실사용 `T`에서 안 돌았다 — `base/store-plan.md`)
│       ├── Blocker.luau          # 값 기반 emit 지연/합치기(`base/blocker-plan.md`) — 위 `state:Gate`의 `GateNode` 위에 얹히는 **정책**, 바닥부터 짜지 않음
│       ├── Modifier.luau         # flatten-before-dispatch, immutable 체이닝, 제네릭 `__index` 필드 setter 합성 + `:Apply`/`:Peek`/`Overridden`(`base/modifier-plan.md`)
│       ├── Tag.luau              # 값 타입+immutable clone 체이닝(`Tag(...)`/`:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`/`:Names`) — 참조 카운트 Handler는 Dispatch/Tag.luau(아래), 엔진 호출은 주입된 addTag/removeTag(`base/tag-plan.md`)
│       ├── Attribute.luau        # 그룹 값 타입+API(`Attribute(store1, store2, ...)`/`Merged`/`:NameMap`, `Tag`와 동형) — Handler는 Dispatch/Attribute.luau(아래) (`base/attribute-plan.md`)
│       ├── AttributeKey.luau     # 단일 키 `AttributeKey<<T>>(name)` + 이름별 weak 캐시(동등성 보장) + 스칼라 편의 패밀리(String/Number/BooleanAttribute) — 엔진 고유 타입 패밀리(Color3Attribute류)만 백엔드 소속(`base/attribute-plan.md` "패키지 배치" 절, 2026-08-13 열네 번째 세션 재배치)
│       ├── Tween.luau            # 값 타입만(`Tween(opts)` 팩토리 — `TweenBrand`에 등록, 인스턴스와 `isTween`은 위 `Brand.luau`) — 엔진 무관, 독립 Dispatch 핸들러 아님. 실제 애니메이션 처리는 quad-roblox Handlers/Property.luau 내부 분기(`base/tween-plan.md`, 2026-08-10 세션 재설계)
│       ├── Effect.luau           # `Effect(fn, ...deps)` — deps 없으면 설치1회+leaf사망시 정리, 있으면 dep마다 약하게 등록(State/Source면 `:WeakSubscribe`, `Ref`면 `:WeakCallback`)해 재실행. **[2026-08-26 `H-107`]** 등록 클로저는 dep 종류별로 **둘**(`onRefFire`/`onStateFire` — 두 콜백 계약의 자리 수가 다르다), 강한 주인은 항상 `_deps`(`base/effect-plan.md`)
│       ├── Slot.luau             # [2026-08-24 `H-46`] 값 타입 본체 — 생성자(**[2026-08-27 Q2]** `Length`·`Offset`·`_baseObserver`를 여기서 만든다, 파괴는 `_destroyed`), 공개 CRUD, `:List`/`:Single`, `raw*` 세트, `wrapElement`/`unwrapElement`, `attachSlot` 3형제, `elementOwner`/`claimOwner`/`releaseOwner`, `dispose`, `Detach`/`KeyGone`(`base/slot-plan.md`). 다른 값 타입과 같은 대칭 — 아래 `Dispatch/Slot.luau`는 핸들러/부기만
│       ├── Debug/init.luau       # [2026-08-24 `H-47`] M1에서 **이미 커밋됨** — `InitDebug(module)`, `module.debug = false`(`base/project-setup-plan.md`)
│       ├── Dispatch/
│       │   ├── init.luau          # process 엔진 — `chains`(inst,k별 인덱스 배열, 슬롯마다 {handler, retractor}) + 하강 diff(핸들러가 같으면 그 자리 클로저에 새 값을 넘기고 재process, 다르면 그 자리부터 retractFrom) + 3-인자 `retractFrom(inst,k,index)` (`dispatch-core-plan.md` "Dispatch 체인" 절, 2026-08-08 신설 → 2026-08-13 다섯 번째 세션 인덱스화 → 같은 날 열네 번째 세션 하강 diff)
│       │   ├── Handler.luau        # 핸들러 계약 타입(isHandlable/priority/process — process가 자기 retract 클로저를 반환)
│       │   ├── StoreBind.luau      # store 값 재귀 재실행 로직(범용, 엔진 무관)
│       │   ├── None.luau           # (**[2026-08-28 `H-162`]** 센티널 `None`과 같은 급으로 quad-base가 export하는 단일 no-op 함수 **`Void`**는 의존 없는 잎 모듈 `Void.luau`(아래)에 정의하고 최상위 `init.luau`가 재export한다 — `Dispatch/init.luau`가 파일 스코프 `local NOOP = Void`로 쓰므로 최상위에 두면 순환 require(`/code-review` 지적); 핸들러 retractor·cleanup 자리의 `function() end`를 전부 대체) NoneHandler(`v==None`을 `nil`로 바꿔 재귀만 — 배열/해시 구분 없음) + NilHandler(`k=number and v==nil` 전용 말단, `setLength(0)`/`setOffsetSource(None)` 등록) (`base/dispatch-core-plan.md`의 "`None` 센티널"/"`NilHandler`" 절, 2026-08-18 재설계 — `drive`의 `None` 스킵 분기 폐기)
│       │   ├── (Leaf.luau 없음)    # ⚠️ [2026-09-01 `H-278` 사용자 확정 — 2026-08-08 배치 확정 역전] leaf 매칭 Handler와 동적 경로 가드는 **값을 선언한 모듈이 자기 Init에서 등록**한다("각 객체를 아는 곳은 각 객체가 선언된 곳"): Observer/Effect 몫은 `Observer.luau`/`Effect.luau`의 `registerDispatchHandlers`(결합 핸들러가 `ObserverLeafHandler`/`EffectLeafHandler` 둘로 갈라짐 — 값 공간 배타라 동등), M8의 Ref/PreRef/PostRef 몫은 `Ref.luau`로 감. None 쌍만 `None.luau`에 남는 이유는 None이 Dispatch 자신의 개념이라서
│       │   ├── Tag.luau            # TagHandler — 이름별 참조 카운트(`tagNameMap`), 실제 호출은 주입된 addTag/removeTag(inst, {string}). `HANDLER_PRIORITY_FALLBACK`에는 이걸 감싸는 `TagFallbackHandler`가 quad-base 자신에 의해 등록됨(**[재역전, 2026-08-18]** 백엔드 팩토리가 아님)(`base/tag-plan.md`, 2026-08-13 열네 번째 세션 base로 이동)
│       │   ├── AttributeKey.luau   # AttributeKeyHandler — 이름 claim(`nameClaims`, 소유권 충돌 즉시 error) + 주입된 setAttribute(inst,name,v) 호출, `None`→nil은 재디스패치로 자동(`base/attribute-plan.md` "이름 소유권" 절). `HANDLER_PRIORITY_FALLBACK`에는 이걸 감싸는 `AttributeKeyFallbackHandler`가 quad-base 자신에 의해 등록됨(**[재역전, 2026-08-18]**)
│       │   ├── Attribute.luau      # AttributeGroupHandler — 그룹 전용 키(비공개 GetKey)로 이름마다 AttributeKey 경로에 인덱스 1 위임, 클로저가 자기 키 전부 retractFrom(`base/attribute-plan.md` "메커니즘" 절). `AttributeGroupFallbackHandler`가 같은 방식으로 감쌈
│       │   ├── Slot.luau           # SlotHandler — 마운트/언마운트 + 그 자리 Length/Offset 부기(값 타입 본체는 위 top-level `Slot.luau`)
│       │   └── Modifier.luau       # [2026-08-24 `H-35`] ProcessedModifierHandler — flatten이 소진한 자리를 캐치해 `setOffsetSource(None)`/`setLength(0)`만 등록하는 nop 핸들러(`base/modifier-plan.md`)
│       ├── Bookkeeping.luau       # ⭐ [2026-09-01 `H-277` 사용자 확정 — Dispatch에서 분리] Length/Offset 부기 서브시스템 — `InitBookkeeping(module)`이 사적 `module._bookkeeping`(getBookkeeping/getBlocker/getOffsetAt/recompute/setLength/setOffsetSource + `H-256` checkPosition)을 설치. 의존 방향 {Slot, Dispatch} → Bookkeeping(부기는 둘 다 모름 — SlotBrand 프로브는 브랜드 잎 판별). 공개 호출 표면은 `quad.Dispatch.*` 그대로(같은 함수 객체 재노출, 래퍼 없음 — `H-39`/`H-25` 계약 유지), M6의 Slot은 `_bookkeeping`을 직접 씀
│       ├── Void.luau              # **[2026-08-28 `H-162`]** `return function() end` 한 줄 — 단일 no-op. 의존 없는 잎(`None`/`Brand`/`Relate`와 같은 급), `Dispatch/*`·핸들러·최상위 `init.luau`가 require
│       ├── Brand.luau             # **[2026-08-28 M2 첫 단위]** `Brand()` 생성자 + **브랜드 인스턴스 전부**(`EpochBrand`를 `Source`/`Ref`/`GateNode`가 공유하므로 타입 모듈마다 두면 순환 require) + `is*` 술어(타입이 생길 때 그 술어를 여기 추가, 최상위 `init.luau`가 재export). 의존 없는 잎(`base/brand-plan.md`)
│       ├── Relate.luau            # inst를 weak 키로 하는 범용 릴레이션(`SetWeak`/`GetWeak`/`SetStrong`/`GetStrong`), 비싱글톤 생성자(`base/relate-plan.md`) — 구 PerInstanceState/perInstanceState 대체
│       ├── ImplRegistry.luau      # **[2026-08-31 `H-206`]** 인스턴스별 임플 저장 접근 `implsOf(module)`(`module._impl`, `H-181`) 한 벌 — State/Observer/Effect에 verbatim 세 벌이던 것을 잎으로 추출(순수 데이터 접근, 내부 전용 — `init.luau` 재export 없음)
│       ├── LifetimeHandle.luau    # `bindLifetime(inst,value)`/`unbindLifetime(value)`/`canBound(value)`/`canExecute(value)` 탑레벨 함수 "인터페이스"(타입/계약만) — **[2026-08-28 M2 첫 단위]** `InitLifetimeHandle(module)`이 모듈 인스턴스에 영어 `level 2` 에러 스텁 4종을 설치하고 백엔드가 덮어쓴다, `Relate`는 안 쓴다(그건 아래 quad-roblox 실 구현 몫 — `base/lifecycle-pattern.md`)
│       ├── Ref.luau               # 범용 값 박스(.Value/.Revision 읽기 + :Set()/:WeakCallback()/:Callback()/:Uncallback()/:Wait(); `Epoch`를 만족 — `base/ref-plan.md`. **[2026-08-27 `H-128`]** `:Wait`·핸들러 뺀 최소형은 M2 공통 기반), `Ref(default)`를 children 배열 숫자 슬롯에 직접 놓으면 (v=Ref) 매치 핸들러가 바인드 — 별도 CreatedRef 래퍼 없음
│       ├── PreRef.luau            # Ref 런타임 재사용 + children 배열 전용, Modifier/Store 타입 차단, 호이스팅되는 pre-pass 특수화(별도 파일, `ref-plan.md` "PreRef 신설" 절, 2026-08-07 여섯 번째 세션에서 분리)
│       ├── PostRef.luau           # PreRef의 거울상 — 같은 Ref 런타임/제약, 같은 pre-pass가 수집만 하고 두 패스가 전부 끝난 뒤 fire(`ref-plan.md` "`PostRef`" 절, 2026-08-14 아홉 번째 세션 확정)
│       ├── LifecycleHooks.luau    # OnCreated/OnRendered/OnDestroyed — PreRef/PostRef/Effect를 반환하는 순수 팩토리 슈가(`base/lifecycle-hooks-plan.md`), 새 타입/Dispatch 개념 없음
│       ├── Claim.luau             # **[2026-09-02 M5 단위 ④]** `Claim(inst, desc)` + `newMapperClass`/`MapperRoot`(본체는 quad-base — 순회·부기 전반, 프로바이더는 `nativeClaim`/`nativeFindChild` 핸들만; `base/claim-plan.md` §9의 "위치 반영은 M5 착수 때" 이행)
│       └── init.luau          # 패키지 최상위 export — `Quad` 값 테이블(`New`/`Source`/…/`None`/**`Void`**(재export — 정의는 위 `Void.luau`, `H-162`))
└── quad-roblox/
    ├── pesde.toml                 # quad-base가 아니라 quad-types에만 workspace 의존(런타임). **[2026-09-02 M5 Q3 (a)]** `[dev_dependencies]`에만 quad_base — spec 전용, 소비자 비전파(`base/project-setup-plan.md` 정정 참고)
    └── src/
        ├── RobloxFactory.luau     # BaseModule 뮤테이션, 재호출 가드(같은 팩토리=무시/다른=에러) — 주입 대상 목록은 아래 EngineOps.luau 줄이 소스 — 여기서 다시 나열하지 않는다(**[2026-08-22]** 예전엔 addTag/removeTag/setAttribute까지만 적혀 있어 native*/setTimeout이 빠져 있었음). bindLifetime/canBound/canExecute도 같은 경로로 주입됨
        ├── EngineOps.luau         # 주입되는 엔진 op 구현: addTag(inst,{string})/removeTag(inst,{string})=CollectionService, setAttribute(inst,name,v)=inst:SetAttribute(v==nil이면 삭제), nativeDispose(inst)=inst:Destroy()(`dispose(value)`가 `isSlot`이 아닐 때 위임, `base/slot-plan.md`), **[2026-08-21 5라운드 신설, 이름 확정] `native*` 물리 트리 조작 계층** — nativeInsert/nativeExtract/nativeRemove/nativeMove/nativeSwap(0-based 절대 offset + 대상 요소 배열을 받음; Roblox는 offset을 무시하고 배열을 쓰고 DOM은 둘 다 씀). 미주입이면 에러가 아니라 **조합 폴백**. **[2026-08-22 추가] 시간 op 둘** — setTimeout(func, delay) -> Timeout / clearTimeout(t), Roblox는 task.delay/task.cancel로 배선(**인자 순서가 반대라 주의**); `Debounce`/`Throttle`이 얹힐 때 필요하고 그 전엔 미주입이어도 무방(`base/debounce-throttle-plan.md`). **이 줄이 주입 op 전체 목록의 단일 소스다** — 다른 문서는 개수를 세지 말고 여기를 가리킬 것 (`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op" 절). **[2026-09-02 M5/M10 분할 — round14 Q4 (a)]** 이 목록 중 M5(단위 ①)가 심는 것은 native* 여섯 + `isInst`/`onDestroying`/`nativeClaim`/`nativeFindChild` + 생명주기 4종이고, `addTag`/`removeTag`/`setAttribute`(M10)·`setTimeout`/`clearTimeout`(백로그)은 그 마일스톤 몫으로 미설치 — 분할의 소스도 이 문장 하나다(ROADMAP·spec은 여길 가리킬 것). **[2026-08-24 6라운드 신설] `isInst(value): boolean`**(`H-40` — 요소 타입 검증을 화이트리스트로 뒤집으면서 생긴 판정 술어, quad-roblox는 `typeof(value) == "Instance"`)**와 `onDestroying(inst, fn): Connection`**(`H-11` — `Effect`의 leaf 사망 cleanup을 발화시키는 훅, `bindLifetime`이 `isEffect`일 때 부른다, quad-roblox는 `inst.Destroying:Connect(fn)`). **⚠️ 이 둘은 `native*`의 "미주입이면 조합 폴백" 규칙의 예외다 — 조작이 아니라 판정/훅이라 조합으로 만들 수 없어 미주입이면 명확한 에러**(`addTag`/`setAttribute`와 같은 취급) **[2026-08-28 `Claim`, M5 — `base/claim-plan.md` §7-9] `nativeClaim(inst)`** — `lifecycle-pattern.md` (0)의 gcconn/gchold 셋업(userdata 동일성 고정 + `InstData:SetWeak`)의 **유일한 자리**. `New`의 ②단계와 `Claim`(해석한 inst마다) 둘 다 이걸 부른다. 사용자 확정은 op 신설과 "경로를 여기에 전부"까지(*"nativeClaim 을 만들고 gchold/gcconn 경로를 여기에 전부"*); "셋업이라 조합 불가 → 조합 폴백의 예외"는 `nativeFindChild`와 같이 에이전트 분류. **`nativeFindChild(inst, key): inst?`** — 매퍼 디스크립터의 키(Roblox는 `Name`, web은 id/selector)로 직계 자식을 찾는 조회 op, quad-roblox는 `inst:FindFirstChild(key)`. 조회라 조합으로 만들 수 없어 `isInst`/`onDestroying`처럼 **조합 폴백의 예외**(미주입이면 명확한 에러 — 이 분류는 에이전트 판단, 사용자 확정은 "필요 핸들을 프로바이더에 남긴다"까지)
        ├── LifetimeHandle.luau    # bindLifetime/canBound/canExecute 실제 구현 — GetPropertyChangedSignal("ClassName") 연결 트릭으로 gcconn 확보, Relate:SetWeak으로 gcconn/gchold 저장. **[2026-09-02 M5 단위 ①]** `nativeClaim` 본체도 이 파일(op 목록의 소스는 위 EngineOps 줄 그대로 — 본체만 `InstData`를 공유하는 여기, §7-9 "경로를 여기에 전부")(**[정정, 2026-08-18] `SetStrong`이 아님 — 생존은 클로저 upvalue와 `gchold[1]`이 이미 보장, strong으로 잡으면 상호 강참조 누수**, `base/lifecycle-pattern.md`). `canBound`/`canExecute`는 비공개 헬퍼 하나를 공유하는 얇은 진입점(2026-08-14 열한 번째 세션). Relate 자체는 순수 Lua라 quad-roblox 쪽 재구현 없음(quad-base 그대로 재사용)
        ├── Handlers/
        │   ├── Property.luau      # 일반 프로퍼티 세팅 + `isTween(realv)` 분기(3-상태 릴레이션 슬롯 `RobloxTween|true|nil`, hasBeenSet 억제, override 정책) — 구 `Handlers/Tween.luau`(높은 우선순위 store-bind 핸들러)는 폐기(`archive/tween-special-bind-key-reversed.md`)
        │   ├── Event.luau         # ReflectionService 기반 자동 판별
        │   ├── OnChange.luau      # `OnChange(name)` 특수 키 팩토리+Handler, `GetPropertyChangedSignal` 바인딩 + 이름별 weak 캐시(`AttributeKey`와 동일 기법, `base/onchange-plan.md`, 2026-08-10 세션)
        │   ├── Slot.luau          # base Slot 재조정 로직의 실제 적용/해제(Instance Parent 조작)
        │   └── InstanceChild.luau # k:number, v:Instance — 중첩 인스턴스 자식(예: Frame { Frame {} })
        ├── Animate.luau           # `Animate(info)` 편의 콤비네이터 — `factory(self)->State`, `:Apply`로 붙임(내부는 `:Compute`/`Tween{...}` 조합), base 프리미티브 아님(`base/tween-plan.md`)
        ├── D/
        │   └── init.luau          # **전량 코드 생성 산출물** — 제네릭 생성자 `New`(커링: `New "Frame" {...}`) + 클래스별 정적 별칭 필드(`D.Frame = New<<Frame>> "Frame" :: (({...}) -> Frame)`). 생성 범위는 "GUI에 쓰이는 모든 인스턴스", 이벤트 필드의 콜백 타입/`State<T>`/`None`까지 타입으로 찍음(**[2026-08-18 확정]** `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절)
        └── init.luau
```

**남은 것**: Slot 코어 로직의 정확한 API(`research`→`base` 승격된
`slot-plan.md` 참고)와 각 파일의 정확한 함수/타입 이름은 구현 단계에서.
existing-instance-bind는 **[2026-08-14 세션] 기각되어 `archive/`로
이전**됐고(`archive/existing-instance-bind-rejected.md`), 애초에 이 구조
확정을 막던 항목도 아니었음(`purity-and-effects-plan.md`/`tween-plan.md`는
이미 `base/`로 승격 완료).

## error 계약 — `level` 이분과 메시지 언어 (2026-08-25 확정, 7라운드 `H-104`/`H-105`)

quad가 던지는 error 자리는 약 29곳이고(`base/` 전수), **쓰기 전에 정해두면
한 번에 맞고 나중에 바꾸면 전수를 다시 훑어야 한다.**

- **⭐ `level` 이분** — *즉시 error*가 quad의 주 방어선인데, 지금까지 **한
  군데도 `level` 인자가 없어** 전부 quad 내부 줄을 가리켰다. 사용자는 자기
  코드 어디서 틀렸는지를 볼 수 없었다.

  | 종류 | `level` | 예 |
  |---|---|---|
  | **사용자 입력 검증** | **2**(호출부를 가리킴) | deps 타입/`nil`, 이중 바인드, 예약 키, 요소 타입 |
  | **내부 불변식 위반** | **1**(그 자리를 가리킴) | 부기가 깨짐(`lengthList[i] == nil` 등) |
  | **제공자(핸들러 작성자) 계약 위반** | **2**(그 계약을 어긴 호출 구조에 가장 가까운 프레임) | retractor 반환 생략(`H-223` 메시지가 핸들러를 특정) |

  세 번째 행은 **[2026-08-31 신설, round12 `H-222` (a) 사용자 확정]** — M3
  단위 1이 "retractor 생략은 어느 행인가"를 §4로 물었고 표 확장으로 닫혔다
  (*"권고 동의"*). 위반한 제공자 코드의 프레임(`h.process`)은 이미 반환된
  뒤라 어떤 `level`로도 직접 가리킬 수 없으므로, 도착지는 가장 가까운 호출
  구조 + **메시지가 핸들러 특정 정보를 싣는 것**이 계약의 나머지 절반이다.

  ```lua
  -- 개념 예시 — level 이분(도착지)을 보여주는 것. [2026-08-31 `H-231`] 실제
  -- 구현에서 첫 줄류(사용자 입력 검증)는 리터럴 2가 아니라
  -- Err.errorBeforeNearest(msg, SURFACE)다(아래 워커 문단). 둘째 줄(내부
  -- 불변식, level 1)은 지금도 리터럴 그대로가 맞다.
  error("Effect: dep #3 is not a State/Source/Ref", 2)
  error("Dispatch.getOffsetAt: lengthList[3] is nil — bookkeeping is broken", 1)
  ```

  내부 불변식 위반은 곧 **quad 자신의 버그**라, 호출부가 아니라 터진 자리를
  가리켜야 리포트가 쓸모 있다. **[2026-08-31 명료화]** 표의 `2`는 리터럴이
  아니라 **"사용자 호출부를 가리킨다"의 기본형**이다 — 검증이 내부 헬퍼
  프레임을 하나 거치면(`newNode`의 dep 검증, `collectDeps`의 nil 검증) 같은
  뜻을 지키기 위해 `3`을 쓴다. 프레임 수가 아니라 도착지가 계약이다.

  **⭐ [2026-08-31 같은 날, `H-231` 사용자 설계로 도착지를 세는 방법이
  바뀌었다 — 계약(도착지) 자체는 그대로.** 리터럴 `2`/`3` 손 세기는
  **`quad-error` 스택 워커**로 대체됐다: 모든 공개 표면 함수(와
  `addHandler`가 수령하는 핸들러 함수)가 공유 네임스페이스
  (`Quad.errorNamespace` — 사본 분리 문제 때문에 quad-base가 만든 하나를
  전원이 받는다)에 `ERROR_LEVEL_SURFACE`(quad-types)로 태그되고,
  - **사용자 입력 검증·제공자 계약 위반**(표의 2행·3행)은
    `errorBeforeNearest(msg, SURFACE)` — 가장 가까운 표면의 호출부. 콜백
    안에서 표면을 재호출한 중첩 진입에서도 진짜 범인 줄을 가리키고, 헬퍼
    프레임 수(2·3 갈림)에 무관하다.
  - **래퍼를 뚫고 사용자 진입점까지 올라가야 하는 것**(디스패치 매치
    실패 — `H-219`의 drive 경로 한계가 이걸로 해소)은
    `errorBefore(msg, SURFACE)` — 최상단 표면 일치.
  - **내부 불변식 위반**(표의 1행)은 그대로 평범한 `error(msg, 1)` —
    워커 불필요.
  기존 자리 전량이 이 형태로 일괄 이관됐다(사용자 확정: *"이관 할 부분을
  이관하고 다음 단위 착수하자"*). 워커 설계·스캔 방향의 경위는
  `qa-request/m3-implementation-round12.md`의 `H-231` 절이 소스.
- **⭐ 메시지는 영어로 통일한다**(**사용자 확정**, 2026-08-25). 지금
  코퍼스는 영어 6 / 한국어 약 23으로 이미 갈려 있고, 공개 표면인데
  정해진 적이 없었다. `.claude/conventions.md`의 *"사용자가 보게 될 것은
  한국어"*는 **이 프로젝트의 대화·문서** 규칙이고 **quad 라이브러리
  사용자**에게까지 적용된다고 정해진 적이 없다 — 여기서 정한다. 이미
  영어인 6곳(동적 경로 가드 4형제, 모듈 초기화, attribute 이름 충돌)이
  핵심 경로라는 것도 같은 방향이다. `base/`의 예시 메시지도 영어로 쓴다.
- **[2026-08-31 M3 단위 4, 탐사자 실측 — 워커의 알려진 한계 둘**
  (`H-273`/`H-274`, 확정 방향의 내재 한계라 메커니즘을 안 만든다)**.**
  (1) 태그 표면을 C 프레임이 직접 부르면(`pcall(drive, …)` 직전달)
  `errorBefore`의 목표가 C 프레임에 얹혀 **파일:줄 접두가 사라진다**
  (메시지는 생존 — `H-219` (a)의 "메시지 자기설명" 논거가 방어선). 접두가
  필요하면 클로저로 감쌀 것. (2) 재진입 진입(observer `fn` 안에서 dispatch
  호출)에서는 최외곽 스캔이 **바깥 진입 줄**을 blame한다 — 안쪽 프레임을
  지목해야 하는 자리는 Nearest 쌍의 몫. 원문은
  `quad-error/src/init.luau` 헤더의 Known limits.
- **⭐ [2026-09-01 스파이크 `27` 실측, `H-250` (a)] 태그는 테이블 경유로
  호출되는 함수에만 둔다.** `-O2`가 **로컬 직접 호출** 함수를 인라인하면
  그 프레임의 태그가 걷기에서 사라져 폴백(raise 자리)으로 강등된다 —
  반면 테이블 필드 경유 호출(`q.Dispatch.*`/`h.process`/`quad.bindLifetime`/
  ns.error* 자신)은 callee가 동적이라 인라인되지 않고, 4개 플래그 조합
  전부에서 태그가 보임이 실측됐다(quad의 전 태그 자리가 이미 이 모양).
  코루틴 경계는 문서 예상 그대로(자기 스택만 걷고, 리주머 태그는 폴백).
  사용자 예측(*"코드 복잡도로 인해서 네이티브 코드젠이 되지는 않을꺼야"*)
  도 codegen 축에서 그대로 확인 — 결과 상세는 `luau-test/STATUS.md`의
  `27` 행.

## 예외 안전성 계약 — 감싸지 않는다 (2026-08-25 확정, 7라운드 🅒)

**예외가 나면 그 파동/그 자리의 부기는 복구되지 않는다.** `pcall`로
감싸는 자리는 하나도 두지 않는다.

- 2026-08-21에 `base/slot-plan.md`의 `materializeSlotTree`에 대해 내린
  판단(*"마운트 도중 예외는 quad가 복구를 보장하지 않는 상태이고 … 아직
  실제로 밟은 적 없는 경로다 … 실제로 물리면 그때 넣는다"*)을 **전 자리로
  확장**한 것이다. `.claude/conventions.md`의 *"드문 오용이나 가상의 미래
  요구까지 방어/최적화하려고 구조를 복잡하게 만들지 않는다"* 원칙 그대로.
- **적용 자리 넷**(7라운드가 찾은 것): State 전파 루프(구독자당 hot path),
  게이트 flush + `Blocker:Off()` 순회, `Dispatch.drive`의 배치 게이팅,
  Dispatch 체인 슬롯. 각각의 실패 모드는 그 문서들이 적는다.
- **같은 원칙이 `EffectHandle:Rerun()`에도 적용된다** — `fn`이 던지면
  `_running`이 참으로 남는 것까지 포함해 복구하지 않는다(사용자: *"에러가
  난 이후 데이터의 무결이 깨져도 별 책임 안 진다는 quad의 일반 동작"*).
- **yield 금지와 같은 톤으로 사용자 문서에 명시할 것.**

## 코드 스타일 — 네이밍 케이싱 (2026-08-08 두 번째 세션 신설)

지금까지 각 문서가 예시 코드를 쓰며 암묵적으로 따라온 패턴을 사용자가
명시적 규칙으로 정리해달라고 요청 — 실제로 지금까지 나온 모든 이름이
예외 없이 따르는 규칙이라 새로 뭘 바꿀 필요는 없고, 그냥 문서화만:

- **대문자 시작(PascalCase)** — 다음 세 가지, 공통점은 전부 **어떤
  프리미티브 타입 자신의 공개 어휘**라는 것:
  1. 프리미티브 타입 생성자, `Type(args)` 스타일: `Source(default)`/
     `Ref(default)`/`Store({defaults})`/`Modifier()`/`Relate()`/
     `Effect(fn, ...deps)`/`PreRef(default)`/`PostRef(default)`.
  2. 그 인스턴스의 콜론 메서드: `state:Get()`/`:With(...)`/`:Compute(fn)`/
     `:Observer(fn)`/`:Apply(factory)`/`:Peek(key)`, `source:Set(v)`/`:Emit()`,
     `ref:Set(v)`/`:Callback(fn)`/`:Wait(thread?)`, `observer:Subscribe()`/
     `:Unsubscribe()`, `relate:SetWeak(...)`/`:GetWeak(...)`/`:SetStrong(...)`/
     `:GetStrong(...)`, `mod:FontSize(...)`(필드 setter 체이닝).
  3. 프리미티브 타입 자신의 네임스페이스에 달린 정적 결합 함수 —
     `Modifier.Overridden(mod1, mod2, ...)`, `Attribute.Merged(...)`/
     `Attribute.Overridden(...)`. **그 프리미티브 타입 고유의 공개 연산**
     이라는 점에서 1/2과 같은 부류 — `Modifier()`/`Attribute()` 생성자와
     같은 이유로 대문자.
     **[정정, 2026-08-18 구현 전 QA]** 옛 서술은 이 분류를 만든 근거로
     *"콜론 메서드는 아니지만 (여러 Modifier를 동등한 인자로 받아야 해서
     self 하나로 안 됨)"* 을 들었는데 **그 근거는 성립하지 않는다** —
     `Overridden`은 **콜론 체이닝(`a:Overridden(b)`)으로도 제공**된다
     (사용자 확정: *"Overridden 도 편의 상 A: 체인으로 제공 가능함. 밖에서
     직접 (A, B) 해주어도 좋고. 콜론과 닷 둘다 가능함"*). 분류 자체는
     "닷 접근으로도 부를 수 있는 정적 결합 함수"라는 표면 차이로 유지하되,
     2번(콜론 메서드)과 배타적이지 않다는 점에 유의.
  4. **`D`(Declarative) 네임스페이스와 그 필드**(`D.Frame`/`D.InstSlot`/
     `D.FrameModifier`) 및 생성자 `New` — **[2026-08-18 신설]** 프리미티브
     타입은 아니지만 사용자가 직접 쓰는 선언형 표면이라 대문자.
     **표기 규약: 문서에서 `D`가 처음 나오는 자리에서는 항상
     `D`(Declarative)로 풀어쓸 것** — 한 글자 식별자라 grep이 어렵고
     이름만으로 뜻이 안 드러난다는 게 2026-08-08부터 개명을 미뤄온 유일한
     사유였고, 이 표기 규약이 그 보완책으로 같이 확정됐다
     (`base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절).
- **소문자 시작(camelCase)** — 특정 프리미티브 타입 하나에 안 묶이고 여러
  타입을 넘나드는 범용 유틸(`isState`/`isSource`/`isRef`/`isPreRef`/
  `isPostRef`/`isModifier`/`isObserver`/... `Brand` 절), 생명주기 게이트(`canExecute`/
  `bindLifetime`, `base/lifecycle-pattern.md`), 그리고 **프리미티브가
  아닌** 내부 엔진/레지스트리의 네임스페이스 멤버(`Dispatch.process`/
  `getHandler`/`addHandler`/`drive`, `Brand()`의 `:register`/`:is`) — 이 셋은 "타입
  고유의 어휘"가 아니라 여러 타입에 걸쳐 쓰이거나(`isX`류) 프리미티브
  자체가 아닌 것(Dispatch는 `Type(args)` 생성자가 없는 내부 엔진이고,
  `Brand`는 생성자가 있지만 사용자 표면이 아닌 base 내부 유틸 — 사용자에게
  노출되는 건 `isX` wrapper들이다)의
  구성원이라 PascalCase 대상이 아님. Handler 계약 필드(`isHandlable`/
  `priority`/`process` — 2026-08-13 다섯 번째 세션에 `retract`가 `process`의
  반환값으로 합쳐지기 전엔 4종이었음)도 여기 속함 — 이건 애초에 "함수"라기보다
  구현체가 채워 넣는 구조체 필드.
- **경계 판단 기준**: 새 이름을 지을 때 "이게 특정 프리미티브 타입 하나의
  전용 소유물인가?"로 물으면 됨 — 그렇다면 대문자(생성자/메서드/그
  타입의 정적 결합 함수), 아니면(범용 유틸이거나 프리미티브가 아닌 엔진
  소속) 소문자. `Dispatch`/`Brand`가 프리미티브가 아닌 이유는
  `base/dispatch-core-plan.md`의 "Dispatch는 프리미티브가 아니다" 절/
  `base/source-state-plan.md`의 "일반 원칙 — 독립 존재 가능한 프리미티브 vs 원천에 종속된 파생 데이터" 절(세 번째 카테고리 문단) 참고.

## 코드 스타일 — Luau 문법 관례: `if-then-else`/`const` (2026-08-12 세션 신설)

**`if cond then a else b` 표현식은 Luau 공식 문법이다 — 환각/오타로
간주해 `and`/`or`로 "고치지" 말 것.** 2021년 10월 Luau에 정식 도입된
표현식 문법(공식 릴리스 노트: <https://luau.org/news/2021-10-31-luau-recap-october-2021/#if-then-else-expression>)
— `cond and truthyOnly or fallback` 삼항 관용구와 달리 가운데 값이
falsy(`nil`/`false`)여도 정확하게 동작함(`dispatch-core-plan.md`의
`Dispatch.retractUnder`(현 `retractFrom`) 정정 사례가 실제 버그 예시). **[강화, 2026-08-12
세션 후속] `cond and x or y` 삼항 관용구는 전면 금지 — `if-then-else`만
쓸 것, 가운데 값이 항상-truthy임이 보장돼도 예외 없음.** 처음엔 그
경우만 예외적으로 허용했으나, 안전 여부와 무관하게 `if-then-else`가
항상 더 낫다는 게 재확인됨 — `and`/`or`는 진짜 short-circuit이라 각
단계 truthiness를 테스트하는 분기가 최대 2번 들어가는데(`cond` 테스트 +
`and`의 결과 테스트), `if-then-else`는 `cond` 하나만 테스트하고 단일
분기로 끝남 — 방어적이면서 바이트코드상으로도 더 적은 분기. 단순
2항 fallback(`x or y`, "and" 없이 값 하나를 기본값으로 대체하는
`props.Modifier or None`류)은 애초에 이 문제가 없어 그대로 유지 —
금지 대상은 어디까지나 `A and B or C` 3항 조합.

**`const` 바인딩도 Luau 공식 문법**(<https://luau.org/syntax/#const-bindings>)
이지만 **[2026-08-12 기준] 지금은 채택하지 않음** — 그 시점에 타입
추출/narrowing 등 주변 툴링이 `const`를 폭넓게 지원하지 못해서, 전면
도입하면 나중에 그 간극을 메꾸는 비용이 더 클 수 있다는 판단.
**툴링 성숙도에 매인 판단이라 시간이 지나면 거짓이 될 수 있는데, 그
시점은 에이전트가 확인할 수 없음** — 사용자 설명(2026-08-16): pesde의 타입
추출처럼 `d.ts` 식으로 types를 emit하는 툴링이 아직 미성숙해 `const`를
제공하지 못하고, **언제 다시 가능해지는지도 명확하지 않다**. 그래서 이건
사용자가 확인된 정보로 알려주기로 정해졌고, 추적은 루트 `HUMAN_TODO.md`
8번이 소스다. **알려주기 전까지 에이전트는 스스로 판단하지 말 것** —
위 "일단 `local`로" 원칙을 그대로 따른다. **원칙**: 새로 짜는 코드는 일단
`local`로 — 나중 리팩터 시점에 특정 바인딩을 `const`로 바꾸는 비용이
싸 보이면 그때 바꿔도 되고, 비싸 보이면 굳이 지금 손대지 않아도 됨.
지금 `const`가 없다고 "이 프로젝트가 구식 Luau를 쓴다"고 오해하지
말 것 — 툴링 성숙도 문제일 뿐 문법 자체를 모르거나 기각한 게 아님.

## 테스트 전략: quad-base용 최소 mock (2026-08-04)

> **[2026-08-29 포인터]** 아래는 2026-08-04의 mock 범위 결정이고 지금도 유효하다. 실제 테스트
> 체계는 그 위에 얹혔다 — `./scripts/test.sh`(relink → `luau-analyze` → `smoke.*`/`spec.*`,
> `base/project-setup-plan.md`), mock의 `installLifetime`(생명주기 4종 + `onDestroying`, M2 단위 1
> `H-97`), 모듈별 `quad-base/test/spec.<module>.luau` 계약 테스트.

**결정**: quad-base 테스트는 Vide 선례(`initreq/vide/test/mock.luau`, 약
300줄)를 따라 최소한의 mock으로 감 — parent/children 트리 + 타입 검증 없는
property bag + property별 변경 시그널 정도만 흉내내고, `IsA()`/클래스별
프로퍼티 스키마/`WaitForChild`/`DataModel` 같은 건 안 만듦. 순수 `luau` CLI로
Studio/엔진 없이 테스트(Vide가 실제로 이렇게 CI에 물려놓음) — Fusion처럼
Studio 안에서만 도는 방식은 채택 안 함. 근거: quad-base 코어(Store/State/
Source/Modifier/Slot, 디스패치 엔진)는 이미 `inst`를 `any`로 취급하고
Instance 특정 동작을 전혀 참조하지 않도록 설계돼 있어(`dispatch-core-plan.md`
"확정된 디스패치 모델" 절의 "`inst`가 항상 살아있는 엔진 객체일 필요는 없음"), mock이 실제 Roblox 충실도를
가질 이유가 없음.

**스코프는 "정적 디버깅"으로 한정** — **사용자 확정**: mock으로 확인하려는
건 한 시점의 렌더 결과(정적 스냅샷)지, 시간에 따라 변하는 동적 동작(Tween
애니메이션, 타이밍 등)이 아님. 그래서 지금 단계 mock엔 시간 기반 핸들러를
흉내낼 계획이 없음.

**"quad-roblox로 작성한 컴포넌트가 mock에서도 그대로 돌아가야 한다"는 요구는
없음** — **사용자 확정**("이건 꼭 지켜질 필요까지 있진 않아, 단순하게 가도
됨"). mock은 quad-roblox의 실제 핸들러(ReflectionService 기반 이벤트 판별,
CollectionService 태그 등)를 흉내낼 필요가 없고, quad-base 자체 로직(디스패치
엔진, Store/State/Source, Modifier, Slot)만 검증하면 충분 — quad-roblox
개발과는 무관해도 됨.

**백로그**: 나중에 범용 렌더 결과 디버깅 도구로 키우고 싶어지면(정적
스냅샷을 넘어 Tween mock 같은 동적 동작까지 포함) 그때 스코프를 넓히는
걸로 — 지금은 quad-base 테스트 전용 최소 mock까지만(`.claude/todos.md` 백로그
참고).

## Store/State/Source 온톨로지 — 확정됨 (요약)

Store는 source(실제 값이 존재하는 단일 지점) 집합체이고, `store.key`로
접근하면 **그 키의 Source 객체를 그대로 반환한다** — 별도 wrapper도,
프록시도, **타입 함수도** 없다(`Source`가 구조적으로 `State`를 만족하도록
재구성되며 wrapper 계층 자체가 불필요해짐 — `base/source-state-plan.md`의
"Source가 State를 만족함" 절).
**⭐ [2026-08-25] 두 가지가 확정됐다** — (1) 생성은 **명시적 초기화**다:
타입 인자에 `Source<T>`를 직접 쓰고 `defaults`에도 `Source(v)`를 직접
넣는다. 옛 lazy `__index`(없는 키를 그 자리에서 만들어 저장)는 폐기됐고,
그래서 `defaults`가 곧 선언 키 집합이라 `store:Names()`가 성립한다.
(2) 레코드 필드 타이핑에 **타입 함수를 안 쓴다**
(`WrapStore`/`ProcessStoreType` 폐기). 쓰기는 `store.key = v`가 아니라
**`store.key:Set(v)`**이고, 동적 키는 `store:Of<<T>>(name)` 하나다.
상세는 `base/store-plan.md`가 소스 — 같은 날 "`store.key`를 값으로"
재설계를 넣었다가 철회한 경위는
`archive/store-value-field-redesign-withdrawn.md`. 전파는
push-invalidate(신호만)/
pull-recompute(`Get()` 시점) — Fusion식 eager 노드 없이도 다이아몬드
의존성 중복 재계산 문제가 풀림(**[2026-08-14 보강]** 푸는 주체는
**노드별 캐시**임을 명시 — `invalid`는 "내 캐시가 낡았다" 표시일 뿐이고
**emit 전파는 자기 `invalid` 상태와 무관함**. 한때 `source-state-plan.md`가
"이미 `invalid`면 전파 중단"으로 서술했으나 `Observer` 계약과 모순돼 역전됨 —
`archive/invalidate-dedup-propagation-reversed.md`. **[2026-08-21 갱신]**
전파를 접는 판정은 이제 `invalid`가 아니라 **`Epoch` 리비전 비교**가 한다 —
같은 `Epoch`의 같은 리비전이 두 경로로 도착하면 두 번째는 접히고(다이아몬드에서
값도 통지도 한 번), DFS 도중 `Get()`이 섞인 값을 캐시하던 glitch도 같이
사라진다. 그 부기는 재사용 가능한 **`EpochMap`**으로 떼어져 있어 State가 아닌
소비자(`Effect`)도 같은 판정을 쓴다. 규칙 전량은 `base/state-epoch-plan.md`,
명시적 게이트는 `base/gate-plan.md`(`state:Gate`)와 그 위의 `Blocker`). State는 쓰기 대상이 아니고, 값을 쓰는
경로는 `source:Set(value)`(Source가 State보다 넓은 인터페이스를 가짐 —
`:Get()`/`:With`/`:Compute` 위에 `:Set`/`:Emit` 추가; [정정, 2026-08-07]
읽기는 `:Get()` 하나로 통일 — 프로퍼티 읽기 표기는 Ref의 `.Value` 전용으로 좁혀짐. **[표기 정정, 2026-08-18]** 여기 소문자 `.value`로 적혀 있었음). 값 하나만
다룰 땐 Store와 별개인 가벼운 `Source` 프리미티브를 독립적으로도 씀.
`store.key` dot-access를 타입 추론 1급 경로로 삼는 것도 3차 라운드에서
정식 확정됨 — **더 이상 열린 질문 아님**, [2026-08-04 기준] 남은 건 정확한
API 이름뿐.
상세는 `base/source-state-plan.md`의 "Source가 State를 만족함"/"핵심
온톨로지" 절 참고.

## 아직 미정 (research/로 분리됨)

**[2026-08-14 세션] 이 절에 유일하게 남아있던 항목(이미 생성된 인스턴스에
대한 바인드)이 기각되어 `archive/existing-instance-bind-rejected.md`로
이전됨** — 지금 `research/`에 남은 것은 전부 "착수 시점 미정"이지
아키텍처를 미정으로 남기는 항목이 아님. 전체 색인은 `.claude/README.md`.
바인드 디스패치/Slot/모듈
라이프사이클/Modifier/컴포넌트화(컴포넌트 경계 modifier/Ref 전달 포함)는
위 "구현 착수" 섹션대로 확정되어 `.claude/base/`로 승격됨
(`bind-system-plan.md`/`dispatch-core-plan.md`/`source-state-plan.md`/
`store-plan.md`/`module-lifecycle-plan.md`/
`slot-plan.md`/`modifier-plan.md`/`component-composition-plan.md`).
