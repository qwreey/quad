# Store — 이름 붙은 Source 모음, 그 이상 아님

> **📄 [2026-08-14 신설] `bind-system-plan.md` 3단계 분할 + store-semantics.md
> 흡수.** Store가 "Source들을 담고, 없으면 만들어주는 도구"로 좁혀지고 나서도
> 관련 서술이 store-semantics.md(부작용 허용, 값 설정 문법)와
> `bind-system-plan.md`(dot-access 타이핑, Store가 Store를 담는가)에 반씩
> 흩어져 있었음 — 한 군데로 합쳤고 **내용/결정은 이동·병합 자체로는 안
> 바뀜**. 반응형 코어(Source/State 자체)는 짝 문서
> **`base/source-state-plan.md`**.

**상태**: base — Store가 부작용을 허용한다는 핵심 결정, "이름 붙은 Source
모음"이라는 정의, eager+lazy 생성, `store.key` dot-access 타이핑, `:Set()`
문법 전환까지 전부 확정. 원본: `.claude/initreq/raw-userinput.md`
"store는 부작용을 허용함" / "스토어는 스토어를 저장 가능한가" 절.

## Store는 부작용을 허용하는 게 기본 디자인

부작용 없이(파라메터 패싱만으로) 쓰는 것도 물론 가능하지만, 라이브러리 차원에서
막지 않는다. 부작용 유무는 **사용자가 직접 문서화**하는 관례로 둔다 — 라이브러리가
순수성을 강제하지 않음.

다만 한 가지는 명확히 구분: **렌더 리턴 위에서 무언가를 observe하는 것은 그냥
부작용**이다 (`useEffect`와 유사한 것으로 문서화). 이건 "허용되는 부작용"이 아니라
"당연히 부작용"이라는 뜻 — 문서화 시 이 경계를 분명히 할 것 (`base/
purity-and-effects-plan.md`와 연결됨).

**보강(2026-08-04 검증 라운드): 부작용은 심각도가 다른 두 갈래로 나뉜다.**

1. **국소적 부작용** — 입력으로 받았거나 자신이 만들어 소유한 대상에 대한
   부작용(예: 렌더 리턴 아래에서 옵저빙해서 자기 slot을 갱신). 이건 편의성이
   커서 적극 환영하는 영역.
2. **경계를 넘는 부작용** — globalStore처럼 컴포넌트 바깥의 전역 상태를
   다루는 경우. 게임 UI 특성상(스킬/주변 환경에 영향받는 UI 등) 완전히
   막을 수는 없지만, 라이브러리로 재사용하려는 컴포넌트가 이런 부작용을
   가지면 이식성이 떨어짐(`base/purity-and-effects-plan.md`와 연결).

**해소됨(2026-08-04 2차 라운드)**: "state를 옵저빙해서 나온 결과로 slot에
`clear`/`add` 같은 연산을 할 때, 그 시점에 대상 slot이 이미 죽어있으면
어떻게 되는가"는 별도 메커니즘 없이 `canExecute` 재사용으로 해결됨 —
`base/source-state-plan.md`의 "Slot 생존 확인" 절이 소스.

## Store = Source들의 이름 붙은 모음 (eager + lazy 생성)

`store.a`처럼 키로 접근하면 **이미 만들어진 Source가 있으면 그대로 반환,
없으면 그 자리에서 만들어 저장한 뒤 반환** — 더 이상 별도 State wrapper를
매번 만들거나 따로 캐싱하지 않음(Source 자체가 이미 State를 만족하므로
wrapper 계층 자체가 불필요해짐, `base/source-state-plan.md`의 "Source가
State를 만족함" 절).

- **`defaults`는 선택**(안 줘도 됨, 순수 편의용 초기값 템플릿) —
  `Store({defaults})`가 내부적으로 `{[key] = Source(default), ...}`나
  다름없게 됨.
- **[정정, 2026-08-07] "Store 생성 시 전부 eager하게만 만들어진다"는 이전
  서술은 부정확 — eager와 lazy가 둘 다 필요하다.** Luau 타입은 런타임에
  강제되지 않으므로 `Store<<SomeType>>()`처럼 `defaults` 없이 만든 뒤
  `.Key:Set(v)`를 부르는 경우, `__index`가 "없으면 그 자리에서 만들어
  저장"까지 해주지 않으면 `.Key`가 `nil`이라 크래시남. 그래서 **Store
  생성 시점의 eager 생성**(각 `defaults` 키마다 미리 만들어둠)과
  **`store.key` 접근 시점의 lazy 생성**(아직 없는 키를 그 자리에서 만들어
  저장, 이후 재접근은 재생성 없이 그대로 반환)이 **둘 다** 필요함.
- **[확인 요구, 2026-08-18 구현 전 QA] lazy 생성이 오타/동적 키로 Source를
  무한정 누적하는 트레이드오프는 그대로 수용하고, 방어선은 런타임이 아니라
  타입에 둔다.** 사용자 판정: *"Store<{ field: type }> 상 없는 네임에는
  타입 시간에 Source 가 없는것으로 나와 타입 에러만 나면 됩니다. 아마 지금
  설계가 그럴것이예요"* — 즉 `Store<{field: T}>`로 선언된 Store에 없는
  이름을 쓰면 `type function`이 합성한 결과 타입에 그 프로퍼티가 없어 **타입
  에러**가 나야 한다. **다만 사용자도 "아마"라고 했으므로 M0에서 실제로
  확인할 것** — `type function`으로 합성한 테이블 타입이 (인덱서를 안 붙인
  상태에서) 미선언 프로퍼티 접근을 실제로 거부하는지.
  `luau-test/done/16-*`(type function으로 `Store<T>` 레코드 필드 합성)에
  이 음성 대조군이 있는지도 같이 볼 것. 런타임에 굳이 이름을 받아야 하는
  경우는 `:GetDynamic`(아래 "타입 추론 문제" 절)이 정식 창구.
- **`defaults` 테이블 원본을 나중에 mutate해도 UB가 아님** — 라이브 백킹
  스토리지가 아니라 "아직 안 만들어진 Source를 만들 때 참고하는 초기값
  템플릿"으로만 반복 참조되기 때문(`bind-system-plan.md`에 남아있던
  "defaults 테이블 직접 mutate는 UB"라는 옛 서술은 2026-08-07에 정정됨).
  별도 `__values`류 그림자 실값 저장소도 불필요 — Source 객체 자체가
  저장소 역할을 함.
- **구현 스케치(2026-08-07, 성능 근거): eager 생성은 `table.clone(defaults)`
  후 그 결과를 순회하며 각 슬롯을 `Source(v)`로 교체하는 모양이어야 함**
  (`local sources = table.clone(defaults); for k, v in sources do
  sources[k] = Source(v) end` 류) — 빈 테이블을 새로 만들어 키를 하나씩
  넣는 것보다, `table.clone`으로 원본의 해시/배열 슬롯 구조를 그대로
  재사용하는 쪽이 Luau VM 입장에서 더 쌈(직접 해시 슬롯을 처음부터
  구성하는 것보다 기존 슬롯을 복제하는 게 저렴). `Source()`(인자 없이
  호출)는 `Source(nil)`과 동치 — `defaults`에 값이 없는 키를 `store.key`
  접근 시점에 lazy 생성할 때 이 무인자 형태를 씀.

v1이 모든 값을 Store 하나에 몰아넣던 습관은 "당시 정적 타입이 없어 단순하게
쓰는 게 편해서"였다는 게 사용자의 회고적 재평가 — 지금은 타입이 핵심
제약이라 그 전제 자체가 더 이상 안 맞고, 2026-08-06 후속 세션의 정리로
Store는 "이름 붙은 Source 모음, 그 이상 아님"으로 더 단순해짐. 값 하나만
반응형으로 다루고 싶으면 Store를 통째로 만들지 말고 독립
`Source(default)`를 쓸 것(`base/source-state-plan.md`의 "Source는 독립
공개 프리미티브로 격상" 절).

## Store 값 설정 문법 — `myStore.key = value` 폐기, `source:Set(value)`로 전환 (2026-08-06 후속 세션, 정정)

**이전 버전("v1 인체공학 유지, `__newindex` 기반 `myStore.key = value`
그대로")은 폐기됨.** `base/source-state-plan.md`의 "Source가 State를
만족함" 절 타입 설계와 맞물려 재검토된 결과:

1. **타입 대칭성**: `store.key`가 이제 `Source<T>`를 직접 반환하는
   평범한 레코드 필드(`{key: Source<number>}`)로 타이핑되는데, 레코드
   필드는 읽기/쓰기 타입이 같아야 Luau 구조적 타이핑이 깨끗하게 성립함.
   `store.key = value`(raw `T` 대입)를 유지하면 읽기(`Source<T>`)/쓰기(`T`)
   타입이 갈려 mismatch가 남음 — `store.key:Set(value)`로 통일하면 필드
   타입이 항상 `Source<T>`로 대칭적이라 문제 자체가 안 생김(사용자 지적).
2. **의미론적 정직성**: `=` 대입 문법은 관례상 "그 자리에서 즉시 확정되는
   부작용 없는 값 쓰기"를 암시하는데, quad의 실제 동작은 **lazy** —
   `Set`은 무효화 신호만 쏘고, 실제 재계산은 나중에 누군가 관측(`Get()`)할
   때만 일어남("Emit으로 필요한 사람 있어? 하고 물어보고, 있어야 진짜
   계산 시작"). 이건 `=`가 암시하는 "즉시 커밋"과 정서가 안 맞고, 메소드
   호출(`:Set()`)이 "이건 프로세스를 트리거하는 연산"이라는 걸 더 정직하게
   신호함(사용자 확정 논거).
3. `:Set()`은 이미 확정된 "값을 바꾸는 연산엔 `:` 체이닝 허용" 원칙(`base/
   architecture.md`)에도 자연스럽게 들어맞음 — 문법 자체가 새로 생기는 게
   아니라 기존 원칙의 정상적인 적용.

**남는 것**: `:` 체이닝 원칙은 `:Set()` 자체가 그 사례라 유지.
**[정정, 2026-08-18 구현 전 QA] `myStore "key"`(문자열 커링)는 기각됐다** —
여기엔 "동적 키 전용 미타입 폴백으로 격하돼 그대로 유지"로 적혀 있었으나,
사용자 판정은 폐기다: *"store "a" 식으로 문자열 호출하는것 또한 기각된
바임. 저러면 "a" 가 string 으로 들어가서, Source<T> 의 타입을 모르기도
하고, 우린 더이상 필요하지 않게 된 요소임."* 근거는 (a) `"a"`가 그냥
`string`으로 들어가 `Source<T>`의 `T`를 알 수 없고, (b) dot-access +
`type function` 타이핑이 자리잡아 더 이상 필요 없어졌다는 것. 동적 키는
아래 `:GetDynamic` 항목으로 간다.

`base/architecture.md`의 "복사(clone) 구현 지양, 팩토리 함수로 대체" 원칙과 함께
읽을 것 — v1의 문제는 metatable 체이닝으로 매번 새 테이블을 할당하며
"불변 빌더"를 흉내낸 것이었지, `:` 체이닝 문법 자체나 커링 문법 자체가
아니었음.

## 타입 추론 문제 — `store.key`(dot-access)를 1급 경로로 확정 (2026-08-04 3차 라운드)

- `store "key"`(문자열 커링)로 `state<T>`를 오버로드 함수 타입으로 정확히
  추론하려는 시도는 포기하고(그 문자열 커링 자체도 **[2026-08-18] 기각**,
  위 절), **`store.key`(dot-access)를 1급 경로로 확정**
  — Store 타입을 `{key: Source<number>, other: Source<string>}`류 평범한
  레코드 타입으로 지으면 일반 구조적 필드 타이핑으로 자동 해결되고, 문자열
  리터럴 narrowing 문제 자체가 안 생김([정정, 2026-08-06] 원래 `State<T>`
  필드로 적혀있었으나 Source가 State를 만족하는 구조로 바뀌며 `Source<T>`로
  갱신 — `store.key = value` 쓰기 문법이 `:Set()`으로 옮겨가 이 필드가
  더 이상 `__newindex`로 쓰이지 않으므로 읽기/쓰기 타입 대칭 문제도 같이
  해소됨, 위 "Store 값 설정 문법" 절 참고).
  **[정정, 2026-08-18] 동적 키 경로는 문자열 커링이 아니라 명시적 메소드다** —
  `store:GetDynamic<<T>>(name): Source<T>`. 런타임 동작 자체는 원래도
  dot-access와 같았고(lazy `__index`가 없는 이름을 만들면 그 자리에서
  Source를 만들어줌 — 아래 "없는 키" 항목) 문제는 **타입**뿐이었다:
  선언되지 않은 이름은 `type function`이 합성한 레코드 타입에 없어서 타입
  에러가 난다(그게 방어선이라는 게 사용자 확정). 그래서 "런타임에 이름이
  정해지는" 정당한 용도를 위해 **타입을 호출자가 직접 주는 명시적 창구**를
  둔다 — 사용자 판정: *"동적히는 여전히 그냥 Store.Name 하면 얻어는 짐.
  타입 애러가 난다는 점인데, 이는 GetDynamic<T>(name): Source<T> 로
  제공하는게 최선으로 보임."* 이름이 명시적이라 "여기서 타입 보장을
  포기했다"가 호출부에 드러나는 것도 문자열 커링보다 나은 점.
  - **⚠️ [구현 주의, 2026-08-18 감사에서 발견] 콜론 메소드는 Store의
    lazy `__index`와 정면으로 부딪힌다.** 위 "Store = Source들의 이름 붙은
    모음" 절이 확정한 대로 **없는 키를 인덱싱하면 그 자리에서 `Source`를
    만들어 저장**하므로, 아무 장치 없이 `store:GetDynamic("x")`를 부르면
    `store.GetDynamic`이 **`"GetDynamic"`이라는 이름의 새 `Source`를
    만들어 반환**하고 그걸 함수로 호출해 런타임 에러가 난다. 따라서
    **`__index`가 고정 메소드 테이블을 먼저 확인하고, 없을 때만 lazy
    `Source` 생성으로 폴백**해야 하며, 그 결과 **`GetDynamic`은 Store의
    예약 키 이름이 된다**(그 이름의 Source는 dot-access로 못 만듦).
    `Modifier`가 `Apply`/`Peek`/`Overridden`을 같은 이유로 예약하는 것과
    정확히 같은 구조(`base/modifier-plan.md`의 "구현 시 주의") — 다만
    Store의 키 이름은 **사용자 도메인 데이터 이름**이라 Modifier(스타일
    프로퍼티 이름)보다 충돌 확률이 높다는 게 차이.
  - **대안(미결, 사용자 판단 필요)**: 예약 키를 하나도 만들고 싶지 않으면
    **탑레벨 함수**(`getDynamic(store, name)`)로 두면 된다 — `isState`/
    `bindLifetime`처럼 "특정 프리미티브에 안 묶인 범용 유틸은 소문자
    탑레벨"이라는 기존 네이밍 규칙(`base/architecture.md`의 "코드 스타일 —
    네이밍 케이싱")에도 오히려 더 맞는다. 사용자가 지정한 표기는
    `GetDynamic<T>(name)`이므로 **일단 콜론 메소드 + 예약 키로 적어두되,
    M3/M4 구현 전에 어느 쪽인지 확인할 것**(`question.md` 3번).
- 이 패턴은 Store에만 국한되지 않고 **인스턴스 생성까지 관통하는 프로젝트
  전역 관습으로 확정**됨 — 단 이벤트는 이후 4차 라운드에서 이 관습의
  **유일한 예외**로 빠졌음(PA님 방식인 문자열 키+런타임 리플렉션으로 전환).
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학"
  절이 최신 확정 내용.

### `store.key` 레코드 필드 타이핑 — Luau 타입함수로 해결 확인 (2026-08-12 열일곱 번째 세션, `pre-implementation-audit.md` 1-10 해소)

위 절이 "`store.key`를 평범한 레코드 필드 타이핑으로 자동 해결"이라
서술했지만, `Store<T>`가 입력 `T`(예: `{ty: string}`)를 받아
`{ty: Source<string>}`류 결과 타입을 실제로 어떻게 합성하는지는 미검증으로
남아있었음. **Luau의 `type function`**(컴파일타임에 타입을 인자로 받아 새
타입을 조립하는 기능, https://luau.org/types/type-functions/ ,
https://luau.org/types-library/ — tbox에서도 이미 쓰이는 검증된 패턴)으로
정확히 풀림:

```luau
type function WrapStore(ty: type): type
    -- Source<T> 형태를 그대로 조립(:Get/:Set/:Compute/:With 등)
    local result = types.newtable()
    result:setproperty(types.singleton("Get"), types.newfunction(...))
    return result
end

type function ProcessStoreType(ty: type): type
    local props = ty:properties() :: { [type]: { read: type?, write: type? } }
    local result = types.newtable()
    for i, v in props do
        -- i는 프로퍼티 이름을 담은 singleton 타입, i:value()로 실제 문자열
        result:setproperty(i, WrapStore(v))
    end
    return result
end
```

`ProcessStoreType<{ty: string}>` → `{ty: Source<string>}`가 나옴 — 결과는
선언 시점에 이름 붙은 `Source<string>` 그 자체가 아니라 구조를 그대로 풀어낸
(flatten) 익명 타입이지만, **Luau는 이름이 아니라 "만족하는가"로 구조적
일치를 검사**하므로 문제없이 `Source<string>` 자리에 대입 가능 — 오히려 이
방식과 정확히 맞는 조합. 이걸로 `store.key`가 실제로 타입 명시 가능함이
확인돼 M0/M3 어느 시점에 검증해도 기술적으로 막힐 위험은 없음 —
`ROADMAP.md`의 M0/M3 배치를 강제로 바꿀 필요는 없어짐, 설계 레벨의 검증
난이도 문제였던 것만 해소. **[2026-08-15] 이 `type function` 접근 자체의
실측도 완료** — 스파이크(`luau-test/done/16-type-store-key-
typefunction.luau`)는 원래 `types.newfunction` 시그니처 불일치로 깨져
있었으나 원인이 설계 문제가 아니라 API 버전 드리프트였음이 드러나 수정
후 통과(음성 대조군 4건 포함), `base/typing-limits.md` §5로 승격.
상세는 `audit/type-recursive-issue-with-typeof/REPORT.md` 6-1절.

## Store가 Store를 저장 가능한가

사용자 원 메모: "슬롯을 스토어처럼 생각 가능하다면 이건 가능하다고 봐야하는가?
아니면 아예 다른 값으로 둬야 하는가? table/number 같은 프리미티브 타입이나
ref 타입처럼 생각하는 게 맞는 거 같음 — 그걸 처리하는 플러그를 만드는 걸로."

**2026-08-04 6차 확정: 그런 경우는 없다고 본다.** "재실행 래핑으로
기계적으로는 커버 가능하다"는 제안은 메커니즘상 틀리지 않지만, 실제 설계
의도와 안 맞음 — Store는 Source에 준하는 존재로 모든 반응형 값의 "시작점"
역할만 함. 시작점은 다른 변화하는 무언가에 연결되는 것을 제공하고자 하지
않음(= Store가 다른 Store/State를 값으로 담아 자동으로 따라가게 하는 용도로
쓰지 않음). Store에서 값을 꺼내 State를 옵저빙하다가 콜백으로 다른 Store 값을
바꾸는 식의 수동 연결은 있을 수 있지만, 잘 짜인 UI에서 실사용 사례를 거의
보지 못했다는 게 사용자 판단 — 그래서 이 케이스를 위해 별도로 신경 쓰지 않음.

**[2026-08-13 세션, 스코프 명확화, 같은 날 다섯 번째 세션에 결론 갱신]**
이 절은 "Store *필드*가 Store/State를 담는가"(예: `store.a = otherStore`)
얘기이고, "State가 *emit하는 값*이 State/Source인가"(`State<State<T>>`,
예: `store.key`에 대입된 값 자체가 State)는 다른 축. 이 절의 "별도로
신경 쓰지 않음"(Store 필드 얘기)은 그대로 유지 — 후자(`State<State<T>>`)는
한때 실제 체인 파손 버그로 확인돼 `Dispatch.process`가 명시적으로 error
하도록 막았었으나, 같은 날 다섯 번째 세션에 `chains`의 인덱스 기반
재설계로 그 버그의 근본 원인이 없어져 **지금은 정상 지원 대상**
(`base/dispatch-core-plan.md`의 "Dispatch 체인" 절 참고 — 열네 번째
세션의 하강 diff로 깜빡임 방지 힌트까지 깊은 체인에서 유지됨) — "신경 안 씀"의
의미가 "조용히 UB"도 "즉시 실패"도 아니라 "그냥 정상적으로 동작함"으로
다시 한번 바뀜.

**따라서 "Store가 Store를 담는 경우 이중 해제(double-dispose) 방지가
필요한가"라는 질문도 성립 안 함으로 종결** — 두 가지 독립적인 이유로
이중 해소됨. (1) 애초에 그런 경우를 만들지 않기로 확정(위 문단). (2) 설령
발생해도 State/Source 그래프 구독이 전부 weak-keyed GC-native(명시적
`dispose()` 호출이 아예 없음, `base/lifecycle-pattern.md`의 GC 위임 원칙
재사용)라 "같은 걸 두 번 해제"할 행위 자체가 존재하지 않음(GC는 멱등).

## Store가 담을 수 없는 값 — Modifier

`Store<T>`/`Source<T>`의 `T`는 Modifier가 될 수 없음(런타임 `error`) —
근거와 검사 지점은 `base/source-state-plan.md`의 "따름정리" 절이 소스.

## 여러 스토어 값을 묶어 처리하는 것 (dependency array) — 확정

`useEffect`처럼 여러 store 값을 디펜던시로 묶어 파생값을 계산하고 싶다는
요구는 `:With(...)`로 의존성을 모으고 `:Compute(fn)`으로 파생 State를
만드는 것으로 확정 — `Store.Combine({a,b}, fn)`류 포지셔널 인자 방식은
기각됨. 정확한 lazy 인자 규칙(self/with 값 둘 다 State 핸들로 넘기고
`:Get()`을 실제로 읽을 때만 계산), v1 `myStore "a,b"` 콤마-조인 문자열
방식의 폐기, 여러 값을 한 번에 바꿀 때 재계산을 한 번으로 묶는 `Blocker`
연결은 전부 `base/source-state-plan.md`의 "여러 값을 묶어 파생값 만들기"
절이 소스.
