# quad-v2 전체 아키텍처 (현재 상태 요약)

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
4. **PA님 스타일 DI 키 계속 지원**: `[Attribute "Name"]`, `[Tag ""] = true` 같은
   특수 바인드 키. Tag는 `retract`(구 cleanup, `base/lifecycle-pattern.md` 참고)가
   내장되어 store 컴퓨티드 바인드도 가능해야 함.
5. **id 기반 전역 조회 폐지, Tag 시스템으로 대체.** v1의 `Store.GetObject(id)`/
   `Frame "id" {}`류는 더 이상 없음 — "id 매핑이 비현실적"이라는 게 이유.
   네임스페이싱 문제는 있지만 별도 네임스페이스 개념을 추가하면 라이브러리
   복잡도가 너무 올라간다고 판단 — 당장은 TagService 그대로 사용. **대신
   Ref가 도입됨** — 단 Ref의 용도는 "id로 조회"가 아니라 "외부에서 이미
   관리되고 있는 instance를 quad로 점진적으로 마이그레이션/래핑하기 위해
   직접 참조를 얻는 것"(`base/bind-system-plan.md`의 Ref 절 참고) — 둘을
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
   구현(`base/bind-system-plan.md`).
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
13. **모듈은 기본 싱글톤, `New()`는 나중에.** 한 Lua 스레드에서 Roblox/비-Roblox
    프로바이더를 동시에 쓸 일이 거의 없을 거라 판단 — 필요해지면 그때 `New()`
    추가.
14. **pluggable 초기화는 팩토리 함수로.** rbvm처럼 네임스페이스 하나하나 수동
    init 하는 방식(`base/lifecycle-pattern.md` 5번 항목 참고)은 피하고,
    `InitRoblox(Module)` 같은 팩토리 함수가 생성된 모듈을 뮤테이션하는 도구를
    주는 방식.

## 구현 착수: 소스 트리 구조 확정 (2026-08-04, 5차 라운드)

**상태**: 소스 트리 레이아웃과 `quad-base`/`quad-roblox` 패키지 경계 확정 —
아래가 다음 세션에서 실제로 만들 구조. 지금은 문서 확정까지만, 실제
폴더/`wally.toml`/`project.json` 스캐폴딩은 다음 세션.

**패키징 방식(모노레포, RbxUtil 선례 채택)**: 최종적으로는 여러 개의 독립
wally 패키지로 나누고 싶지만, 지금 Luau 툴링(특히 wally로 설치된 패키지의
타입 정보 단절·`luau-lsp`의 심볼릭 링크 해석 문제 — 최근 `luau-lsp 1.63.0`
에서야 수정됨)이 아직 불안정해서 **당장은 모놀리식**으로 감. `Sleitnick/
RbxUtil`이 정확히 이 패턴(루트 하나로 통합 개발/테스트, 서브폴더마다 자체
`wally.toml`로 독립 퍼블리시)을 쓰는 선례라 그대로 채택. `.luaurc`의
`aliases`는 **런타임 require에서 아직 엔진이 지원 안 함**(Roblox 스태프가
지원 예정이라고만 밝힌 상태, 2026-01 기준) — 그래서 alias는 편집기
자동완성/타입체크용으로만 곁들이고, 실제 크로스패키지 require는 상대경로로
쓴다. 나중에 실제로 레포를 쪼갤 때는 Rojo `project.json`의 트리 매핑 규칙만
유지하면 되고, require는 그 시점에 한 번 기계적으로 바꾸는 정도로 감수.

**패키지 경계**: `quad-base`는 다른 렌더 백엔드(GTK 등, 항목 12 참고)에서도
재사용 가능해야 한다는 전제 — Store/State/Source 온톨로지+전파뿐 아니라
**pluggable 디스패치 엔진 자체도 "인터페이스"로 base가 소유**한다(엔진마다
큰 구현을 중복하지 않기 위함 — rbvm이 relation을 하나로 통합하려 했던 것과
같은 동기). `quad-roblox`는 그 인터페이스의 **실제 구현체**만 제공.

```
quad/
├── .luaurc                      # @quad-base, @quad-roblox alias (편집기 경험용, 런타임 비의존)
├── default.project.json         # 루트 통합 개발/테스트용 Rojo 프로젝트
├── quad-base/
│   ├── wally.toml
│   └── src/
│       ├── Source.luau           # 값의 근원, 단일 지점. Source가 State를 구조적으로 만족(`__index` 델리게이션)
│       ├── State.luau            # 캐시만 하는 non-owning 핸들, state(state) 분기, `:With`/`:Compute`/`:Observer`(등록 즉시 1회 실행) 전부 여기 소속
│       ├── Store.luau            # source 집합체, dot-access로 Source 그대로 반환
│       ├── Blocker.luau          # 값 기반 emit 지연/합치기(`base/blocker-plan.md`), State/Source와 밀접 연관돼 같은 위치
│       ├── Modifier.luau         # flatten-before-dispatch, immutable 체이닝, 제네릭 `__index` 필드 setter 합성 + `:Apply`/`:Peek`/`Override`(`base/modifier-plan.md`)
│       ├── Effect.luau           # `Effect(fn, state?)` — state 없으면 설치1회+leaf사망시 정리, 있으면 State.Observer를 조합해 재실행(`base/effect-plan.md`)
│       ├── Dispatch/
│       │   ├── init.luau          # process/retract 엔진, isHandlable 우선순위 스캔
│       │   ├── Handler.luau        # 핸들러 계약 타입(isHandlable/priority/process/retract)
│       │   ├── StoreBind.luau      # store 값 재귀 재실행 로직(범용, 엔진 무관)
│       │   └── Slot.luau           # add/remove/clear 재조정 로직(추상 자식 참조 기준)
│       ├── Relate.luau            # inst를 weak 키로 하는 범용 릴레이션(`SetWeak`/`GetWeak`/`SetStrong`/`GetStrong`), 비싱글톤 생성자(`base/relate-plan.md`) — 구 PerInstanceState/perInstanceState 대체
│       ├── LifetimeHandle.luau    # `bindLifetime(inst,value)`/`canExecute(inst,value)` 탑레벨 함수 "인터페이스"(타입/계약만), 내부는 Relate 사용(`base/lifecycle-pattern.md`)
│       ├── Ref.luau               # 범용 값 박스(.Value 읽기 + :Set()/:Callback()/:Wait() 셋), `Ref(default)`를 children 배열 숫자 슬롯에 직접 놓으면 (v=Ref) 매치 핸들러가 바인드 — 별도 CreatedRef 래퍼 없음
│       ├── PreRef.luau            # Ref 런타임 재사용 + children 배열 전용, Modifier/Store 타입 차단, 호이스팅되는 pre-pass 특수화(별도 파일, `bind-system-plan.md` "PreRef 신설" 절, 2026-08-07 여섯 번째 세션에서 분리)
│       └── init.luau
└── quad-roblox/
    ├── wally.toml
    └── src/
        ├── RobloxFactory.luau     # BaseModule 뮤테이션, 재호출 가드(같은 팩토리=무시/다른=에러)
        ├── LifetimeHandle.luau    # bindLifetime/canExecute 실제 구현 — GetPropertyChangedSignal("ClassName") 연결 트릭으로 gcconn 확보, Relate:SetStrong으로 gcconn/gchold 저장(`base/lifecycle-pattern.md`). Relate 자체는 순수 Lua라 quad-roblox 쪽 재구현 없음(quad-base 그대로 재사용)
        ├── Handlers/
        │   ├── Property.luau
        │   ├── Event.luau         # ReflectionService 기반 자동 판별
        │   ├── Attribute.luau
        │   ├── Tag.luau           # CollectionService
        │   ├── Tween.luau         # 높은 우선순위 store-bind 핸들러
        │   ├── Slot.luau          # base Slot 재조정 로직의 실제 적용/해제(Instance Parent 조작)
        │   └── InstanceChild.luau # k:number, v:Instance — 중첩 인스턴스 자식(예: Frame { Frame {} })
        ├── DI/
        │   └── init.luau          # 제네릭 생성자 + ~25개 정적 필드(UIInstances)
        └── init.luau
```

**남은 것**: Slot 코어 로직의 정확한 API(`research`→`base` 승격된
`slot-plan.md` 참고)와 각 파일의 정확한 함수/타입 이름은 구현 단계에서.
Tween/existing-instance-bind는 여전히 `research/`에 남아있고 이 구조 확정을
막지 않음(`purity-and-effects-plan.md`는 이미 `base/`로 승격 완료).

## 테스트 전략: quad-base용 최소 mock (2026-08-04)

**결정**: quad-base 테스트는 Vide 선례(`initreq/vide/test/mock.luau`, 약
300줄)를 따라 최소한의 mock으로 감 — parent/children 트리 + 타입 검증 없는
property bag + property별 변경 시그널 정도만 흉내내고, `IsA()`/클래스별
프로퍼티 스키마/`WaitForChild`/`DataModel` 같은 건 안 만듦. 순수 `luau` CLI로
Studio/엔진 없이 테스트(Vide가 실제로 이렇게 CI에 물려놓음) — Fusion처럼
Studio 안에서만 도는 방식은 채택 안 함. 근거: quad-base 코어(Store/State/
Source/Modifier/Slot, 디스패치 엔진)는 이미 `inst`를 `any`로 취급하고
Instance 특정 동작을 전혀 참조하지 않도록 설계돼 있어(`bind-system-plan.md`
"inst가 항상 Roblox Instance일 필요는 없음" 절), mock이 실제 Roblox 충실도를
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
걸로 — 지금은 quad-base 테스트 전용 최소 mock까지만(`CLAUDE.md` 백로그
참고).

## Store/State/Source 온톨로지 — 확정됨 (요약)

Store는 source(실제 값이 존재하는 단일 지점) 집합체이고, `store.key`로
접근하면 이미 만들어져 있는 Source 객체를 그대로 반환하거나(defaults로
Store 생성 시 미리 만들어둔 경우), 아직 없으면 그 자리에서 만들어 저장한
뒤 반환한다(별도 wrapper 없음 — **[2026-08-06 후속 세션 정정, 2026-08-07
추가 정정]** 원래 "매번 새 State를 감싸 반환"이었으나, `Source`가 구조적으로
`State`를 만족하도록 재구성되며 wrapper 계층 자체가 불필요해짐. 이후
"Store 생성 시 전부 eager하게만 만들어진다"로 한 차례 더 정리됐다가, Luau
타입이 런타임에 강제되지 않아 defaults 없이 만든 키를 나중에 `:Set()`하면
크래시난다는 점이 지적돼 lazy `__index`+저장 생성도 같이 필요함이 확인됨 —
상세는 `base/store-semantics.md` "Source가 State를 만족함" 절). 전파는
push-invalidate(신호만)/
pull-recompute(`Get()` 시점) — Fusion식 eager 노드 없이도 다이아몬드
의존성 중복 재계산 문제가 풀림. State는 쓰기 대상이 아니고, 값을 쓰는
경로는 `source:Set(value)`(Source가 State보다 넓은 인터페이스를 가짐 —
`:Get()`/`:With`/`:Compute` 위에 `:Set`/`:Emit` 추가; [정정, 2026-08-07]
읽기는 `:Get()` 하나로 통일 — `.value` 표기는 Ref 전용으로 좁혀짐). 값 하나만
다룰 땐 Store와 별개인 가벼운 `Source` 프리미티브를 독립적으로도 씀.
`store.key` dot-access를 타입 추론 1급 경로로 삼는 것도 3차 라운드에서
정식 확정됨 — **더 이상 열린 질문 아님**, 남은 건 정확한 API 이름뿐.
상세는 `base/store-semantics.md`의 "Source가 State를 만족함" 절과
`base/bind-system-plan.md`의 "Store/State/Source 온톨로지" 절 참고.

## 아직 미정 (research/로 분리됨)

Tween 플러깅, 이미 생성된 인스턴스에 대한 바인드 — `.claude/research/` 각
문서 참고, 전체 색인은 `.claude/README.md`. 바인드 디스패치/Slot/모듈
라이프사이클/Modifier/컴포넌트화(컴포넌트 경계 modifier/Ref 전달 포함)는
위 "구현 착수" 섹션대로 확정되어 `.claude/base/`로 승격됨
(`bind-system-plan.md`/`module-lifecycle-plan.md`/`slot-plan.md`/
`modifier-plan.md`/`component-composition-plan.md`).
