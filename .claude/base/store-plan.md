# Store — 이름 붙은 Source 모음, 그 이상 아님

> **📄 [2026-08-14 신설] `bind-system-plan.md` 3단계 분할 + store-semantics.md
> 흡수.** Store가 "Source들을 담고, 없으면 만들어주는 도구"로 좁혀지고 나서도
> 관련 서술이 store-semantics.md(부작용 허용, 값 설정 문법)와
> `bind-system-plan.md`(dot-access 타이핑, Store가 Store를 담는가)에 반씩
> 흩어져 있었음 — 한 군데로 합쳤고 **내용/결정은 이동·병합 자체로는 안
> 바뀜**. 반응형 코어(Source/State 자체)는 짝 문서
> **`base/source-state-plan.md`**.

**상태**: base — Store가 부작용을 허용한다는 핵심 결정, "이름 붙은 Source
모음"이라는 정의, `store.key` dot-access 타이핑까지 전부 확정.
**⭐ [2026-08-25] 두 가지가 바뀌었다** — (1) 생성이 **명시적 초기화**로
확정되고 옛 lazy `__index`가 폐기됐다, (2) 타입은 **타입 함수를 안 쓰고**
평범한 레코드로 짓는다(`WrapStore`/`ProcessStoreType` 폐기). 같은 날
"`store.key`를 값으로" 재설계를 넣었다가 철회한 경위는
`archive/store-value-field-redesign-withdrawn.md`. 원본:
`.claude/initreq/raw-userinput.md`
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

## Store = Source들의 이름 붙은 모음 (명시적 초기화)

> **⭐⭐ [2026-08-25] 같은 날 두 번 바뀌었다 — 최종은 이 절이다.**
> 오전에 "`store.key`가 값이고 `store:Of(k)`가 프리미티브"라는 재설계를
> 넣었다가 **같은 날 철회**했다. 철회된 시도의 원문과 이유는
> `archive/store-value-field-redesign-withdrawn.md`. 그 시도가 남긴 것은
> **명시적 초기화**(eager/lazy 이중 모델 폐기) 하나이고, 나머지(값 필드,
> `__index`/`__newindex` 슈가, 팬텀 필드, `index<>`/`keyof<>`)는 전부
> 되돌렸다.

**Store의 타입 인자에는 `Source<T>`를 직접 쓰고, `defaults`에도 `Source(v)`를
직접 넣는다.**

```lua
local store = quad.Store<<{
    hp:   Source<number>,
    name: Source<string>,
}>>({
    hp   = Source(100),
    name = Source(""),
})

store.hp:Get()                 -- 평범한 레코드 필드 접근 → Source<number>
store.hp:Set(5)
store.hp:Compute(function(s) ... end)
```

- **`store.key`는 평범한 레코드 필드다** — `Store<T>`가 `T`(그 자체로
  `{hp: Source<number>, ...}`)를 그대로 포함하므로 **타입 함수가 하나도
  안 든다.** 마법이 없고, 읽기/쓰기 의미론이 `Source`의 기존 계약
  (`:Get()`/`:Set()`) 그대로다.
- **⭐ 명시적 초기화가 기본** — 선언한 키는 생성 시 `Source`를 준다.
  `defaults`에 없는 키는 **필드 자체가 없어** 타입에서 걸리고, 런타임에도
  `nil` 역참조로 즉시 드러난다. 옛 lazy `__index`(없는 키를 그 자리에서
  만들어 저장)는 **폐기**됐다 — **사용자 근거**: *"lazy 로 만들어낸다는
  발상 자체가 약간 문제가 있어요. Set 을 안 해주면, 초기 값이 타입에
  어긋날 수 있거든요. 애초에, `Source<number>` 인데, nil을 조용히 가지고
  있을수도 있고, 타입으로 못 막네요."*
  - **부수 효과**: 선언 키 집합의 **런타임 소스가 `defaults` 하나**로
    확정된다. 그래서 `store:Names()`가 `pairs`로 성립한다 — 옛 lazy
    모델에선 키 집합이 접근 이력에 좌우돼 0개/1개/2개로 갈렸다
    (7라운드 `H-79`).
- **부모가 값을 다 안 넘겨도 되게 하려면 컴포넌트가 자기 `DEFAULTS`로
  채운다** — 타입에 `?`를 다는 게 아니라 **호출 규약**으로 표현한다
  (**사용자 아이디어**: *"기본 값인 소스는 한 곳에 `Defaults = {}` 해두고
  쓰는거죠"*). 그래야 생성자가 항상 완전한 테이블을 받는다.
- **외부에서 만든 `Source`를 나중에 끼워 넣는 표면은 없다** — 생성 시점에
  넣는 게 전부다(**사용자 판단**: *"다른곳에서 생성된 Source 를 다시
  넣는다는게, 가능하게 해야할 표면적 이유가 없습니다"*).
- **값이 없는 상태가 필요하면 `None`이 이미 그 자리다** — attribute를
  실제로 지우는 것도 `Source<None> → None → nil`로 핸들러 계열을 타고
  말단에서 set nil 된다. Store 키를 nilable로 만들 이유가 아니다.
- **구현 스케치**: 생성 시 `table.clone(defaults or {})`로 그림자 테이블을
  만든다(`table.clone`이 원본의 해시/배열 슬롯 구조를 재사용해 빈 테이블에
  키를 하나씩 넣는 것보다 쌈 — 2026-08-07 성능 근거 그대로). 값이 이미
  `Source`이므로 **슬롯 교체 순회가 없다**. **`or {}`가 필수다** — 무인자
  `Store<<{}>>()`도 유효한데 `table.clone(nil)`은
  `table expected, got nil`로 죽는다(**[2026-08-25]** 7라운드 `H-83` 실측).
- **`store:Names()`** — 그 시점의 키 집합을 준다(그림자 테이블의 키). 그룹
  `Attribute(...)`/`attr:NameMap()`이 이걸 요구한다
  (`base/attribute-plan.md`, 7라운드 `H-79`).
  **⚠️ "선언된 키"와 정확히 같지는 않다** — `defaults`의 키에 **동적 키
  창구 `store:Of(name)`이 만든 것**이 더해진다(아래 "타입 추론 문제" 절).
  둘의 차이는 `Of`를 쓴 Store에서만 생기고, `Of`는 "타입 보장을 포기했다"가
  호출부에 드러나는 명시적 자리다. **그룹 `Attribute`에 미치는 영향**:
  이미 배치된 `Attribute(store)` 바인딩은 그 시점의 `NameMap()` 스냅샷으로
  구성되므로, 나중에 `Of`로 늘어난 키는 **다음 재디스패치 때** 반영된다
  (`base/attribute-plan.md`의 그룹 절).

v1이 모든 값을 Store 하나에 몰아넣던 습관은 "당시 정적 타입이 없어 단순하게
쓰는 게 편해서"였다는 게 사용자의 회고적 재평가 — 지금은 타입이 핵심
제약이라 그 전제 자체가 더 이상 안 맞고, 2026-08-06 후속 세션의 정리로
Store는 "이름 붙은 Source 모음, 그 이상 아님"으로 더 단순해짐. 값 하나만
반응형으로 다루고 싶으면 Store를 통째로 만들지 말고 독립
`Source(default)`를 쓸 것(`base/source-state-plan.md`의 "Source는 독립
공개 프리미티브로 격상" 절).

## Store 값 설정 문법 — `myStore.key = value` 폐기, `store.key:Set(value)` (2026-08-06 후속 세션, 확정 유지)

> **[2026-08-25] 이 결정은 유지된다.** 같은 날 오전에 한 번 뒤집었다가
> (`store.key`를 값으로 만들면서 대입이 되살아났었다) **같은 날 철회**했다 —
> `archive/store-value-field-redesign-withdrawn.md`. `store.key`가 다시
> `Source<T>`이므로 아래 근거 셋이 전부 그대로 성립한다.

**`store.key = value`는 안 쓴다.** 값을 쓰는 경로는 `store.key:Set(value)`다.

1. **타입 대칭성**: `store.key`가 `Source<T>`를 직접 반환하는 평범한 레코드
   필드(`{key: Source<number>}`)로 타이핑되는데, 레코드 필드는 읽기/쓰기
   타입이 같아야 Luau 구조적 타이핑이 깨끗하게 성립한다.
   `store.key = value`(raw `T` 대입)를 유지하면 읽기(`Source<T>`)/쓰기(`T`)
   타입이 갈려 mismatch가 남는다 — `:Set(value)`로 통일하면 필드 타입이 항상
   `Source<T>`로 대칭적이라 문제 자체가 안 생긴다(사용자 지적).
2. **의미론적 정직성**: `=` 대입 문법은 관례상 "그 자리에서 즉시 확정되는
   부작용 없는 값 쓰기"를 암시하는데, quad의 실제 동작은 **lazy** —
   `Set`은 무효화 신호만 쏘고, 실제 재계산은 나중에 누군가 관측(`Get()`)할
   때만 일어난다. 메소드 호출(`:Set()`)이 "이건 프로세스를 트리거하는
   연산"이라는 걸 더 정직하게 신호한다(사용자 확정 논거).
   **[2026-08-25 보강]** 철회된 재설계가 이 논거를 실제로 검증해줬다 —
   `store.key = v`를 되살리자 *"`.Value = 1`이 정적 쓰기처럼 보이는데
   거기서 error trace가 나오면 당황스럽고 약간 마법적"*(사용자)이라는
   문제가 바로 드러났다.
3. `:Set()`은 이미 확정된 "값을 바꾸는 연산엔 `:` 체이닝 허용" 원칙
   (`base/architecture.md`)에도 자연스럽게 들어맞는다.

**`myStore "key"`(문자열 커링)는 기각**이다(2026-08-18 사용자 판정) —
*"저러면 "a" 가 string 으로 들어가서, Source<T> 의 타입을 모르기도 하고,
우린 더이상 필요하지 않게 된 요소임."* 동적 키는 아래 `:Of`로 간다.

`base/architecture.md`의 "복사(clone) 구현 지양, 팩토리 함수로 대체" 원칙과 함께
읽을 것 — v1의 문제는 metatable 체이닝으로 매번 새 테이블을 할당하며
"불변 빌더"를 흉내낸 것이었지, `:` 체이닝 문법 자체나 커링 문법 자체가
아니었음.

## 타입 추론 문제 — `store.key`(dot-access)를 1급 경로로 확정 (2026-08-04 3차 라운드)

- `store "key"`(문자열 커링)로 `state<T>`를 오버로드 함수 타입으로 정확히
  추론하려는 시도는 포기하고(그 문자열 커링 자체도 **[2026-08-18] 기각**,
  위 절), **`store.key`(dot-access)를 1급 경로로 확정**. Store 타입을
  `{key: Source<number>, other: Source<string>}`류 **평범한 레코드 타입**으로
  지으면 일반 구조적 필드 타이핑으로 자동 해결되고, 문자열 리터럴 narrowing
  문제 자체가 안 생긴다.
- **⭐ [2026-08-25] 동적 키는 `store:Of<<T>>(name): Source<T>` 하나다** —
  옛 이름 `GetDynamic`을 **흡수**했다(표면 둘을 유지할 이유가 없다).
  선언되지 않은 이름은 레코드 타입에 없어서 dot-access는 타입 에러가
  난다(그게 방어선이라는 게 사용자 확정). 그래서 "런타임에 이름이 정해지는"
  정당한 용도를 위해 **타입을 호출자가 직접 주는 명시적 창구**를 둔다 —
  사용자 판정:
  *"이는 GetDynamic<T>(name): Source<T> 로 제공하는게 최선으로 보임."*
  이름이 명시적이라 "여기서 타입 보장을 포기했다"가 호출부에 드러나는 것도
  문자열 커링보다 나은 점.
  - **⭐⭐ [2026-08-25 신설] `Of`는 없는 이름이면 그 자리에서 만들어 저장한다 —
    여기가 lazy 생성이 남는 유일한 자리다.** 명시적 초기화로 dot-access 쪽
    lazy `__index`는 폐기됐지만(위 절), **동적 키 창구는 그 위에 서 있었다**
    (`/code-review high` 발견) — `defaults`에 없는 이름을 `Of`가 그냥
    조회하면 `nil`을 `Source<U>` 타입으로 돌려주고 호출부가 `:Get()`에서
    타입 에러 없이 nil 역참조한다.
    ```lua
    function Store:Of(name)          -- 동적 키 전용
        local src = shadow[name]
        if src == nil then
            src = Source()           -- == Source(nil)
            shadow[name] = src
        end
        return src
    end
    ```
    - **`__index` lazy와 다른 점**: 그건 **암묵**이었고(오타가 조용히 새
      Source를 만들었다) 이건 **명시**다 — 이름을 문자열로 넘기고 타입을
      `<<T>>`로 직접 주는 자리라 "여기서 타입 보장을 포기했다"가 호출부에
      드러난다. 그게 애초에 이 창구를 둔 이유다.
    - **`store:Names()`는 그대로 성립한다** — 선언 키(`defaults`)에 `Of`가
      만든 동적 키가 더해진 것이 그 시점의 실제 키 집합이고, `Names()`가
      돌려주는 것도 그것이다.
    - **오타 방어는 여전히 타입이 한다** — dot-access는 레코드 타입에 없는
      이름을 거부한다. `Of`는 그 방어를 **의도적으로** 우회하는 창구다.
  - **⭐ [2026-08-25 실측] `<<T>>`는 값 호출부에서 동작한다.**
    7라운드 `H-73`이 *"Luau엔 호출부 명시 타입 인자 문법이 없다"*고
    단정했으나 **틀렸다** — Luau의 **generic type instantiation**
    (`luau.org/types/generics/#generic-type-instantiation`)이 값 호출부에서도,
    콜론 메소드에서도 `T`를 실제로 묶는다. `luau-analyze` 실측:
    ```lua
    local ok:   Source<number> = store:Of<<number>>("x")   -- 진단 없음
    local bad:  Source<string> = store:Of<<number>>("y")   -- 정확히 걸림
    local none: Source<number> = store:Of("z")             -- Source<unknown>
    ```
    원문은 **인스턴스화를 생략한 호출만** 돌려보고 단정했다. 따라서
    `base/quad-types-plan.md`의 이중 꺾쇠 관례는 타입 자리 전용이 아니다.
- **⭐ [2026-08-25] 예약 키는 `Of`/`Names` 둘뿐이고, 충돌은 조용히 죽는다.**
  실측: 사용자 키가 예약 이름과 겹치면 교집합이 뭉개져 **그 필드의 타입
  검사가 통째로 꺼진다**(음성 대조군이 진단 0건으로 통과했다). 시끄럽게
  막히는 게 아니라 그냥 지나간다.
  - **그래서 `T`를 검증만 하고 그대로 통과시키는 작은 `type function`을
    둔다.** 겹치면 사용 지점에
    `TypeError: quad.Store: "Of" is a reserved key`가 뜬다.
    **`error()`는 못 쓴다** — `type function` 자체가 실패한 걸로 판정돼
    버려진다. `print(...)` + `return types.never` 조합만 된다
    (`luau-test/rewrite-required/23-...`가 기록해둔 사실이고
    `type-version-check`가 이미 쓰는 패턴).
  - **이건 아래 §0 원칙의 허용 범위 안이다** — 타입 함수를 **진단을 띄우는
    데만** 쓰고 접근 타입을 합성하는 데는 안 쓴다
    (`base/typing-limits.md`).
- 이 패턴은 Store에만 국한되지 않고 **인스턴스 생성까지 관통하는 프로젝트
  전역 관습으로 확정**됨 — 단 이벤트는 이후 4차 라운드에서 이 관습의
  **유일한 예외**로 빠졌음(PA님 방식인 문자열 키+런타임 리플렉션으로 전환).
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학"
  절이 최신 확정 내용.

### `store.key` 레코드 필드 타이핑 — 타입 함수가 필요 없다 (2026-08-25 재확정)

> **⭐⭐ [2026-08-25] 타입 함수로 접근 타입을 짓는 접근은 **두 번** 시도됐고
> **두 번 다 폐기**됐다.** (1) `WrapStore`/`ProcessStoreType`로 결과 타입을
> **합성**하는 안(2026-08-12~2026-08-15) — 7라운드 `H-75`/`H-76`이 두
> 한계를 실측해 폐기. (2) `index<>`/`keyof<>` + 팬텀 필드로 짓는 안
> (2026-08-25 오전) — 같은 날 철회
> (`archive/store-value-field-redesign-withdrawn.md`).

**지금은 타입 함수를 안 쓴다.** `Store<T>`의 `T`가 이미
`{hp: Source<number>, ...}`이므로 `store.hp`는 **평범한 레코드 필드
접근**이고, Luau가 그냥 해준다.

```lua
type Store<T> = T & {
    Of:    <U>(self: any, name: string) -> Source<U>,   -- 동적 키 전용
    Names: (self: any) -> { string },
}
```

**`luau-analyze` 실측**(양성 + 음성 대조군):

| 검사 | 결과 |
|---|---|
| `store.hp` | `Source<number>` ✅ (`Source<string>` 대조군 걸림) |
| `store.hp:Get()` / `:Set(5)` | ✅ (틀린 타입 대조군 둘 다 걸림) |
| `store.nope` | **거부** ✅ |
| `store:Of<<boolean>>("dyn")` | `Source<boolean>` ✅ (대조군 걸림) |
| 콜백 파라미터 추론(`store.hp:Compute(function(s) ... end)`) | ✅ `s`가 `StateData<number>`로 잡힘(`s:NoSuchField()`가 정확히 걸림) |

- **⚠️ `Compute`/`Apply`의 반환 타입은 여전히 명시 주석이 필요하다** —
  이건 Store와 무관한 `base/typing-limits.md` §1의 **문제 B**이고,
  `store.hp`든 독립 `Source`든 **똑같이** 조용히 안전성을 잃는다(실측:
  틀린 주석 `local x: State<string> = src:Compute(...)`이 양쪽 다 안 걸림).
  `audit/type-recursion-issue/REPORT.md` 3-1절이 확정한 대로 **명시 주석
  이후 다운스트림 전체는 정상 체크**되고 구멍은 그 한 줄뿐이다.
  살아나는 건 **콜백 파라미터** 쪽이다 — 그리고 철회된 재설계의
  `Self` 제네릭을 거치면 **그것마저 깨졌다**(`s`가 `unknown`으로 떨어짐).
- **`__call` 경로는 죽었다** — 타입 레벨 `__call`은 `self`를 못 받고,
  `typeof(f<<T>>)`로 타입 인자를 넘기는 것도 실패한다(실측). 같은 사실이
  `base/source-state-plan.md`의 `:Apply`에도 적용된다(7라운드 `H-94`).

실측 전량은 `audit/type-store-index-keyof/`가 소스.

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
발생해도 State/Source 그래프 구독에 **명시적 `dispose()` 호출이 아예 없어서**
(`base/lifecycle-pattern.md`의 GC 위임 원칙 재사용) "같은 걸 두 번 해제"할
행위 자체가 존재하지 않음(GC는 멱등).

> **⚠️ [근거 정정, 2026-08-24 6라운드 손 트레이싱 `H-36`]** 위 (2)번은 원래
> *"그래프 구독이 **전부** weak-keyed GC-native"*라고 적혀 있었다. 그 명제는
> `base/source-state-plan.md`가 **스스로 미확정이라고 선언한 항목**(중간
> State가 살아남는가 — 구독 엣지의 방향성, 상류가 strong인지 weak인지)이라
> 근거로 쓸 수 없다. 사용자가 지목한 해법 방향("하류로 weak, 상류로 strong")
> 으로 닫히면 그래프는 더 이상 "전부 weak"가 아니게 된다.
> **결론(이중 해제 불가)은 안 뒤집힌다** — (1)번만으로도 성립하고, (2)번도
> "해제 호출 자체가 없다"로 다시 쓰면 방향성과 무관하게 참이다. 그 미해결이
> 닫힐 때 이 문단을 같이 훑을 것.

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
