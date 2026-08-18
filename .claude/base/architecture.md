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
13. **모듈은 기본 싱글톤, `Quad()`는 나중에.** 한 Lua 스레드에서 Roblox/비-Roblox
    프로바이더를 동시에 쓸 일이 거의 없을 거라 판단 — 필요해지면 그때 `Quad()`
    추가(**[정정, 2026-08-18 `/code-review high`] 이름은 아래 배너대로
    `New()`가 아니라 `Quad()`가 확정 — 이 문장도 그 이름으로 통일**).
    **메커니즘도 이미 정해짐(2026-08-08 두 번째 세션, 새 설계 아니라
    기존 패턴의 자연스러운 연장)**: v1처럼 `require`를 감싸 `Init(QuadId?)`로
    격리 인스턴스를 만드는 방식은 안 씀 — 대신 지금 있는 "팩토리가
    `BaseModule`을 뮤테이션" 패턴(14번) 그대로, 매번 새 `BaseModule`
    테이블을 만들어 팩토리로 채우는 것뿐. 상세 근거는
    `base/dispatch-core-plan.md`의 "Dispatch는 프리미티브가 아니다" 절.
    **[정정, 2026-08-18 구현 전 QA]** 옛 서술은 그렇게만 하면 지금
    module-level state로 사는 모든 것(`_initializedBy` 마커, Dispatch
    레지스트리 등)이 **"자동으로" 테이블별 스코핑된다**고 했는데, 사용자
    판정은 다르다 — *"모듈이 하나의 인스턴스(dispatch 레지스트리 하나,
    canExecute 등 계약 필드 하나) 만 가지고 있다면 예. 단, 나중에 …
    require 를 감싸지는 않고 단순히 InitModule(module) 등을 받도록 각
    코드들을 약간 고쳐서 이것을 해결함."* 즉 **코드 변경 없이 자동으로**
    되는 게 아니라, module-level state를 참조하는 코드들이 모듈 인스턴스를
    인자로 받도록 **손을 대야** 한다. 미래 API 이름도 `New()`가 아니라
    **`Quad()`**(`Quad()`를 부르면 새 quad 인스턴스가 나오는 식)이고,
    **지금은 단순 싱글톤이라 `Quad()` 없이 `Quad.Dispatch`로 바로 접근**한다.
    - **M0 스캐폴딩에 주는 함의**: 레지스트리를 module-level upvalue로
      직접 잡아두면 나중에 다중 인스턴스화할 때 전면 수정이 된다. 지금
      싱글톤으로 가되, **그 참조 형태를 나중에 인자 하나 받는 걸로 바꾸기
      쉬운 모양으로 둘지**를 M0에서 정할 것.
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
├── .luaurc                      # @quad-base, @quad-roblox alias (편집기 경험용, 런타임 비의존)
├── default.project.json         # 루트 통합 개발/테스트용 Rojo 프로젝트
├── quad-base/
│   ├── wally.toml
│   └── src/
│       ├── Source.luau           # 값의 근원, 단일 지점. Source가 State를 구조적으로 만족(`__index` 델리게이션)
│       ├── State.luau            # 캐시만 하는 non-owning 핸들, state(state) 분기, `:With`/`:Compute`/`:Observer`(등록 즉시 1회 실행) 전부 여기 소속
│       ├── Store.luau            # source 집합체, dot-access로 Source 그대로 반환
│       ├── Blocker.luau          # 값 기반 emit 지연/합치기(`base/blocker-plan.md`), State/Source와 밀접 연관돼 같은 위치
│       ├── Modifier.luau         # flatten-before-dispatch, immutable 체이닝, 제네릭 `__index` 필드 setter 합성 + `:Apply`/`:Peek`/`Overridden`(`base/modifier-plan.md`)
│       ├── Tag.luau              # 값 타입+immutable clone 체이닝(`Tag(...)`/`:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`/`:Names`) — 참조 카운트 Handler는 Dispatch/Tag.luau(아래), 엔진 호출은 주입된 addTag/removeTag(`base/tag-plan.md`)
│       ├── Attribute.luau        # 그룹 값 타입+API(`Attribute(store1, store2, ...)`/`Merged`/`:NameMap`, `Tag`와 동형) — Handler는 Dispatch/Attribute.luau(아래) (`base/attribute-plan.md`)
│       ├── AttributeKey.luau     # 단일 키 `AttributeKey<<T>>(name)` + 이름별 weak 캐시(동등성 보장) + 스칼라 편의 패밀리(String/Number/BooleanAttribute) — 엔진 고유 타입 패밀리(Color3Attribute류)만 백엔드 소속(`base/attribute-plan.md` "패키지 배치" 절, 2026-08-13 열네 번째 세션 재배치)
│       ├── Tween.luau            # 값 타입만(`Tween(opts)` 팩토리, `isTween`/`TweenTag`) — 엔진 무관, 독립 Dispatch 핸들러 아님. 실제 애니메이션 처리는 quad-roblox Handlers/Property.luau 내부 분기(`base/tween-plan.md`, 2026-08-10 세션 재설계)
│       ├── Effect.luau           # `Effect(fn, state?)` — state 없으면 설치1회+leaf사망시 정리, 있으면 State.Observer를 조합해 재실행(`base/effect-plan.md`)
│       ├── Dispatch/
│       │   ├── init.luau          # process 엔진 — `chains`(inst,k별 인덱스 배열, 슬롯마다 {handler, retractor}) + 하강 diff(핸들러가 같으면 그 자리 클로저에 새 값을 넘기고 재process, 다르면 그 자리부터 retractFrom) + 3-인자 `retractFrom(inst,k,index)` (`dispatch-core-plan.md` "Dispatch 체인" 절, 2026-08-08 신설 → 2026-08-13 다섯 번째 세션 인덱스화 → 같은 날 열네 번째 세션 하강 diff)
│       │   ├── Handler.luau        # 핸들러 계약 타입(isHandlable/priority/process — process가 자기 retract 클로저를 반환)
│       │   ├── StoreBind.luau      # store 값 재귀 재실행 로직(범용, 엔진 무관)
│       │   ├── None.luau           # NoneHandler(`v==None`을 `nil`로 바꿔 재귀만 — 배열/해시 구분 없음) + NilHandler(`k=number and v==nil` 전용 말단, `setLength(0)`/`setOffsetSource(None)` 등록) (`base/dispatch-core-plan.md`의 "`None` 센티널"/"`NilHandler`" 절, 2026-08-18 재설계 — `drive`의 `None` 스킵 분기 폐기)
│       │   ├── Leaf.luau           # (i:number, v=Ref/Observer/Effect/PreRef/PostRef) children-array leaf 매칭 Handler(일반 Ref 매치는 `isRef(v) and not isPreRef(v) and not isPostRef(v)`, Observer/Effect는 `ObserverEffectLeafHandler` 하나가 `type(k)=="number" and (isObserver(v) or isEffect(v))`로 같이 매치 — `base/source-state-plan.md` "Observer/Effect Leaf dedup" 절, 2026-08-14 열두 번째 세션), StoreBind와 같은 층위(범용/엔진무관, 2026-08-08 두 번째 세션 확정)
│       │   ├── Tag.luau            # TagHandler — 이름별 참조 카운트(`tagNameMap`), 실제 호출은 주입된 addTag/removeTag(inst, {string}). `HANDLER_PRIORITY_FALLBACK`에는 이걸 감싸는 `TagFallbackHandler`가 quad-base 자신에 의해 등록됨(**[재역전, 2026-08-18]** 백엔드 팩토리가 아님)(`base/tag-plan.md`, 2026-08-13 열네 번째 세션 base로 이동)
│       │   ├── AttributeKey.luau   # AttributeKeyHandler — 이름 claim(`nameClaims`, 소유권 충돌 즉시 error) + 주입된 setAttribute(inst,name,v) 호출, `None`→nil은 재디스패치로 자동(`base/attribute-plan.md` "이름 소유권" 절). `HANDLER_PRIORITY_FALLBACK`에는 이걸 감싸는 `AttributeKeyFallbackHandler`가 quad-base 자신에 의해 등록됨(**[재역전, 2026-08-18]**)
│       │   ├── Attribute.luau      # AttributeGroupHandler — 그룹 전용 키(비공개 GetKey)로 이름마다 AttributeKey 경로에 인덱스 1 위임, 클로저가 자기 키 전부 retractFrom(`base/attribute-plan.md` "메커니즘" 절). `AttributeGroupFallbackHandler`가 같은 방식으로 감쌈
│       │   └── Slot.luau           # add/remove/clear 재조정 로직(추상 자식 참조 기준)
│       ├── Relate.luau            # inst를 weak 키로 하는 범용 릴레이션(`SetWeak`/`GetWeak`/`SetStrong`/`GetStrong`), 비싱글톤 생성자(`base/relate-plan.md`) — 구 PerInstanceState/perInstanceState 대체
│       ├── LifetimeHandle.luau    # `bindLifetime(inst,value)`/`unbindLifetime(value)`/`canBound(value)`/`canExecute(value)` 탑레벨 함수 "인터페이스"(타입/계약만), 내부는 Relate 사용(`base/lifecycle-pattern.md`)
│       ├── Ref.luau               # 범용 값 박스(.Value 읽기 + :Set()/:Callback()/:Wait() 셋), `Ref(default)`를 children 배열 숫자 슬롯에 직접 놓으면 (v=Ref) 매치 핸들러가 바인드 — 별도 CreatedRef 래퍼 없음
│       ├── PreRef.luau            # Ref 런타임 재사용 + children 배열 전용, Modifier/Store 타입 차단, 호이스팅되는 pre-pass 특수화(별도 파일, `ref-plan.md` "PreRef 신설" 절, 2026-08-07 여섯 번째 세션에서 분리)
│       ├── PostRef.luau           # PreRef의 거울상 — 같은 Ref 런타임/제약, 같은 pre-pass가 수집만 하고 두 패스가 전부 끝난 뒤 fire(`ref-plan.md` "`PostRef`" 절, 2026-08-14 아홉 번째 세션 확정)
│       ├── LifecycleHooks.luau    # OnCreated/OnRendered/OnDestroyed — PreRef/PostRef/Effect를 반환하는 순수 팩토리 슈가(`base/lifecycle-hooks-plan.md`), 새 타입/Dispatch 개념 없음
│       └── init.luau
└── quad-roblox/
    ├── wally.toml
    └── src/
        ├── RobloxFactory.luau     # BaseModule 뮤테이션, 재호출 가드(같은 팩토리=무시/다른=에러) — 주입 대상엔 bindLifetime/canBound/canExecute 외에 addTag/removeTag/setAttribute도 포함(2026-08-13 열네 번째 세션)
        ├── EngineOps.luau         # 주입되는 엔진 op 구현: addTag(inst,{string})/removeTag(inst,{string})=CollectionService, setAttribute(inst,name,v)=inst:SetAttribute(v==nil이면 삭제), disposeInst(inst)=inst:Destroy()(`dispose(value)`가 `isSlot`이 아닐 때 위임, `base/slot-plan.md`) (`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op" 절)
        ├── LifetimeHandle.luau    # bindLifetime/canBound/canExecute 실제 구현 — GetPropertyChangedSignal("ClassName") 연결 트릭으로 gcconn 확보, Relate:SetWeak으로 gcconn/gchold 저장(**[정정, 2026-08-18] `SetStrong`이 아님 — 생존은 클로저 upvalue와 `gchold[1]`이 이미 보장, strong으로 잡으면 상호 강참조 누수**, `base/lifecycle-pattern.md`). `canBound`/`canExecute`는 비공개 헬퍼 하나를 공유하는 얇은 진입점(2026-08-14 열한 번째 세션). Relate 자체는 순수 Lua라 quad-roblox 쪽 재구현 없음(quad-base 그대로 재사용)
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

## 코드 스타일 — 네이밍 케이싱 (2026-08-08 두 번째 세션 신설)

지금까지 각 문서가 예시 코드를 쓰며 암묵적으로 따라온 패턴을 사용자가
명시적 규칙으로 정리해달라고 요청 — 실제로 지금까지 나온 모든 이름이
예외 없이 따르는 규칙이라 새로 뭘 바꿀 필요는 없고, 그냥 문서화만:

- **대문자 시작(PascalCase)** — 다음 세 가지, 공통점은 전부 **어떤
  프리미티브 타입 자신의 공개 어휘**라는 것:
  1. 프리미티브 타입 생성자, `Type(args)` 스타일: `Source(default)`/
     `Ref(default)`/`Store({defaults})`/`Modifier()`/`Relate()`/
     `Effect(fn, state?)`/`PreRef(default)`/`PostRef(default)`.
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
  `getHandler`/`addHandler`/`drive`, `Brand.set`/`get`) — 이 셋은 "타입
  고유의 어휘"가 아니라 여러 타입에 걸쳐 쓰이거나(`isX`류) 프리미티브
  자체가 아닌 것(Dispatch/Brand는 `Type(args)` 생성자가 없는 내부 엔진)의
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
접근하면 이미 만들어져 있는 Source 객체를 그대로 반환하거나(defaults로
Store 생성 시 미리 만들어둔 경우), 아직 없으면 그 자리에서 만들어 저장한
뒤 반환한다(별도 wrapper 없음 — **[2026-08-06 후속 세션 정정, 2026-08-07
추가 정정]** 원래 "매번 새 State를 감싸 반환"이었으나, `Source`가 구조적으로
`State`를 만족하도록 재구성되며 wrapper 계층 자체가 불필요해짐. 이후
"Store 생성 시 전부 eager하게만 만들어진다"로 한 차례 더 정리됐다가, Luau
타입이 런타임에 강제되지 않아 defaults 없이 만든 키를 나중에 `:Set()`하면
크래시난다는 점이 지적돼 lazy `__index`+저장 생성도 같이 필요함이 확인됨 —
상세는 `base/source-state-plan.md` "Source가 State를 만족함" 절). 전파는
push-invalidate(신호만)/
pull-recompute(`Get()` 시점) — Fusion식 eager 노드 없이도 다이아몬드
의존성 중복 재계산 문제가 풀림(**[2026-08-14 보강]** 푸는 주체는
**노드별 캐시**임을 명시 — `invalid`는 "내 캐시가 낡았다" 표시일 뿐이고
**emit 전파는 자기 `invalid` 상태와 무관하게 항상 일어남**. 전파를 늦추는
건 `Blocker` 같은 명시적 게이트뿐. 한때 `source-state-plan.md`가 "이미
`invalid`면 전파 중단"으로 서술했으나 `Observer` 계약과 모순돼 역전됨 —
`archive/invalidate-dedup-propagation-reversed.md`). State는 쓰기 대상이 아니고, 값을 쓰는
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
