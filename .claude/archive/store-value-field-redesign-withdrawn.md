# [검토 후 철회] Store를 "값 필드 + 타입 함수 합성"으로 바꾸려던 시도

**상태**: archive — **2026-08-25 오전에 도입했다가 같은 날 철회됨.**
지금 유효한 설계는 `base/store-plan.md`가 소스. 이 문서는 그 시도의 원문과
**왜 되돌렸는지**를 보존한다(히스토리 전용, **여기 적힌 것을 현재 설계로
읽지 말 것**).

## 무엇을 시도했나

`WrapStore`/`ProcessStoreType` 타입 함수로 결과 타입을 **합성**하는 옛
접근이 7라운드 `H-75`/`H-76`으로 무너지자, 그 자리를 다음으로 채우려 했다:

| 시도한 것 | 지금(철회 후) |
|---|---|
| 타입 인자가 **평범한 값 타입**(`Store<<{hp: number}>>`) | 타입 인자에 **`Source<T>`를 직접**(`Store<<{hp: Source<number>}>>`) |
| `store.key` → **값**(`__index`가 `Of(k):Get()`) | `store.key` → **`Source<T>`**(평범한 레코드 필드) |
| `store.key = v` **부활**(`__newindex`) | **폐기 유지** — `store.key:Set(v)` |
| `store:Of(k)`가 **프리미티브** | `store:Of<<T>>(name)`은 **동적 키 전용**(옛 `GetDynamic` 흡수) |
| 팬텀 필드 `__store` + `index<>`/`keyof<>` | **타입 함수 안 씀** — 평범한 레코드 |
| 선언만 하고 값을 안 주는 키를 `?`로 표현 | **명시적 초기화**(이건 **살아남았다**) |

**살아남은 것은 명시적 초기화 하나**다 — eager/lazy 이중 모델 폐기,
`store:Names()` 신설, `WrapStore` 폐기. 나머지는 전부 되돌렸다.

## 왜 철회했나

**사용자 지적**(2026-08-25): *"우리가 너무 '필드셋' 으로 처리하고싶다에
너무 몰두해버린것 같네요. 필드의 read write 의 실질적 의미론이 어떤지도
정의하지 못해버린채요. 이러면, `.Value = 1` 이 정적 쓰기처럼 보일텐데,
여기서 error 터지는 trace 가 나오면 당황스럽기도 하고요, 약간 마법적
동작이기도 해요. … 왜 우리가 `Source()` 를 직접 넣는걸 거부하고, 이렇게
까지 하려 했죠? 단순히, `Store<{ a: Source }>` 로 두고, `store.a:Set,Get`
하지 말아야할 이유가 있을까요?"*

되짚어보니 **비용이 이득보다 컸다**:

1. **읽기/쓰기 의미론을 정의하지 못한 채로 문법만 도입했다.**
   `store.key = v`가 정적 쓰기처럼 보이는데 실제로는 `Set`을 트리거하고,
   실패하면 그 자리에서 error trace가 난다 — 2026-08-06이 대입 문법을
   폐기한 논거 2번(*"`=`가 암시하는 즉시 커밋이 lazy와 안 맞는다"*)이
   그대로 되살아난 셈이다.
2. **`index<>`/`keyof<>`도 타입 함수다.** **사용자 지적**: *"사실 keyof 와
   index 도 타입함수입니다(구현을 뜯어보면, 루아우에서 프리디파이닝한
   타입함수임). 타입함수가 가지는 고질적 문제를 그대로 가져요."*
   실제로 `H-76`이 지적한 부류의 문제가 새로 하나 생겼다 — `Of`의
   **`Self` 제네릭을 거치면 콜백 파라미터 추론이 깨져** `s`가 `unknown`으로
   떨어졌다(평범한 레코드 필드에선 정상 추론된다, 실측 대조).
3. **`store:Names()`가 런타임에 구현 불가능했다.** Luau가 타입 인자를
   런타임에 지우므로 `Store<<{hp: number, name: string?}>>({hp = 100})`에서
   `name`이 선언됐다는 사실을 런타임이 알 방법이 없다. 그런데
   `attr:NameMap()`은 선언된 전체 키를 요구한다 — 즉 `H-79`가 "닫혔다"고
   한 문제가 옵셔널 미설정 키에 대해 그대로 재발한다(감사 4패스 발견).
4. **`?`(nilable) 선언을 떠받칠 sentinel이 없었다.** `None`은 **핸들러
   배열의 nil hole** 때문에 생긴 물건이라 "값이 없다"가 아니고,
   `Source<None|T|nil>`을 정의한 적도 없어 `Compute`가 뭘 받을지부터
   안 정해진다(**사용자 분석**). 그렇다고 `nil`과 `None`을 가르는 새
   도구를 두기엔 의미론이 부딪힌다.
5. **표면이 늘었다** — `Of` + `Names` + `GetDynamic` 셋이었는데, 철회 후엔
   `Of`가 `GetDynamic`을 흡수해 둘이 된다.

**여기서 나온 원칙 하나가 `base/typing-limits.md` §0으로 승격됐다** —
*"타입 함수는 타입이 못 잡는 문제를 **에러로 띄우는** 정도 이상으로 가지
않는다."* 이 시도가 정확히 그 선을 넘은 사례다.

경위 원문은 `qa-request/pre-implementation-handtrace-round7-followup.md`의
🅖🅗 절, 발견 원문은 `qa-request/pre-implementation-handtrace-round7.md`의
`H-73`~`H-76`.

---

## 철회된 시도의 원문 (보존)

아래는 **2026-08-25 오전에 `base/store-plan.md`에 실제로 들어갔던 네 절**을
그대로 옮긴 것이다. 같은 날 철회돼 지금은 `base/store-plan.md`에 없다.
**여기 적힌 것을 현재 설계로 읽지 말 것** — 특히 `store.key`가 값이라는
서술, `__index`/`__newindex` 슈가, 팬텀 필드 `__store`,
`index<>`/`keyof<>`, `?` nilable 선언, `store.key = v` 부활은 **전부 철회**됐다.

---

## Store = Source들의 이름 붙은 모음 (명시적 선언, 2026-08-25 재설계)

> **⭐⭐ [2026-08-25 재설계] 이 절은 통째로 다시 쓰였다.** 옛 모델
> (`store.key`가 `Source<T>`를 직접 반환하는 레코드 필드 + eager/lazy
> 이중 생성 + `WrapStore` 타입 함수)은 **역전**됐고 원문은
> 이 파일(당시 이름은 store-source-record-model-reversed.md였다)에 있다. 경위는
> `qa-request/pre-implementation-handtrace-round7-followup.md`.

**Store는 키를 타입 인자로 명시해서 만든다.** 타입 인자에 담는 것은
`Source<T>`가 아니라 **평범한 값 타입**이다.

```lua
local store = quad.Store<<{
    hp: number,
    name: string?,        -- 안 넘겨도 되는 값은 `?`로 선언
}>>({ hp = 100 })
```

- **`store.key`는 값**이고 **`store.key = v`는 대입**이다 —
  `__index`/`__newindex`가 아래 `Of`를 대신 불러준다. 읽기에 계산이 끼지
  않는다(Store가 담는 건 `Source`뿐이므로 `Get`이 곧 현재 값이다).
  사용자: *"`__index` 는 이제 `:Get` 해주어도 될것 같다. (연산이 안
  일어난다. 진짜 현 값이 맞음)"*
- **⭐ `store:Of(key)`가 프리미티브다** — 그 키의 `Source`를 돌려준다.
  `__index`/`__newindex`는 그 위의 슈가다(사용자: *"`__index` 를 통한
  get 에선 `Of()` 결과에서 `:Get` 하도록 합시다. `__newindex` 도
  유사하죠, 그 이후 `Set` 되는 식"*). 반응형으로 묶을 때는 이걸 쓴다.
  ```lua
  store.hp              -- number
  store.hp = 5          -- 대입
  store:Of("hp")        -- Source<number>
  store:Of("name")      -- Source<string?>   ← `?` 선언이 그대로 드러남
  ```
- **이름이 `Peek`이 아니라 `Of`인 이유** — 사용자: *"Peek 자체가, 애초에
  여긴 다 확정된 값들의 무더기라서, Peek 아닌 다른게 좋긴 해보여요.
  `Of` 가 가장 좋아보입니다."* 다른 프레임워크에서 `Peek`은 관례적으로
  "구독 없이 값을 읽는다"인데 여기선 `store.key`가 이미 그 일을 하고
  이 메소드는 **핸들**을 준다.
- **⭐ 선언은 필수, 값은 선택.** 안 넘겨도 되는 것은 타입에서 `?`로
  선언한다 — 그러면 `store:Of("name")`이 `Source<string?>`로 나와
  **타입이 정직해진다**. 옛 lazy 모델이 갖던 구멍(사용자: *"`Set` 을 안
  해주면, 초기 값이 타입에 어긋날 수 있거든요. 애초에,
  `Source<number>` 인데, nil을 조용히 가지고 있을수도 있고, 타입으로 못
  막네요"*)이 이걸로 닫힌다. 부모 컴포넌트가 기본값 있는 것까지 전부
  넘길 필요도 없어진다.
- **`Source` 실체는 그림자 백킹 테이블에 있다** — `store.key`가 값이면
  `__index`/`__newindex`는 그 키가 store 테이블에 **없을 때만** 발동하므로
  실제 `Source`를 store 테이블에 raw로 넣을 수 없다. **[2026-08-25
  정정]** 옛 서술의 *"별도 `__values`류 그림자 실값 저장소도 불필요"*는
  이 재설계로 뒤집혔다.
- **미선언 키의 방어선은 여전히 타입이다.** `Store<{field: T}>`로 선언된
  Store에 없는 이름을 쓰면 타입 에러가 난다 — `luau-analyze` 실측에서
  `store:Of("nope")`이 정확히 거부된다. 런타임에 이름이 정해지는 정당한
  용도는 `:GetDynamic`(아래 "타입 추론 문제" 절)이 정식 창구.
- **`store:Names()`가 선언된 키 집합을 준다** — 타입은
  `{ keyof<...> }`로 정확히 나온다. 그룹 `Attribute(...)`/`attr:NameMap()`이
  이걸 요구한다(`base/attribute-plan.md`). **[2026-08-25 신설, 7라운드
  `H-79`]** 이 표면이 없어서 그룹 `Attribute`의 키 집합이 접근 이력에
  좌우되던 문제를 닫는다.
- **구현 스케치**: 생성 시 `table.clone(defaults or {})` 후 그 결과를
  순회하며 각 슬롯을 `Source(v)`로 교체해 그림자 테이블로 삼는다
  (`table.clone`이 원본의 해시/배열 슬롯 구조를 재사용해 빈 테이블에
  키를 하나씩 넣는 것보다 쌈 — 2026-08-07 성능 근거 그대로).
  **`or {}`가 필수다** — 무인자 `Store<<{}>>()`도 유효한데
  `table.clone(nil)`은 `table expected, got nil`로 죽는다(**[2026-08-25]**
  7라운드 `H-83` 실측).
  `Source()`(인자 없이 호출)는 `Source(nil)`과 동치.
- **⭐ [2026-08-25 신설] 선언은 됐는데 `defaults`에 없는 키는 `Of`가 그
  자리에서 만든다.** "선언은 필수, 값은 선택"이 계약이므로
  `Store<<{hp: number, name: string?}>>({hp = 100})` 뒤
  `store:Of("name")`은 **정상 경로**인데, 위 스케치는 `defaults`에 있는
  키만 그림자 테이블에 넣으므로 그 자리가 비어 있다. `Of`가 비어 있으면
  `Source(nil)`을 만들어 저장하고 반환한다 — 타입이 `Source<string?>`라
  **정직하고**, 옛 lazy 모델이 갖던 구멍(`Source<number>`인데 조용히 `nil`)은
  `?` 선언 강제로 이미 닫혀 있다.
  ```lua
  function Store:Of(key)
      local src = shadow[key]
      if src == nil then
          src = Source()          -- == Source(nil)
          shadow[key] = src
      end
      return src
  end
  -- __index(t, k)    == t:Of(k):Get()
  -- __newindex(t,k,v) == t:Of(k):Set(v)
  ```
  **미선언 키는 여기 안 온다** — 타입에서 이미 거부되고(`store:Of("nope")`
  실측), 런타임에 이름이 정해지는 경로는 `:GetDynamic`이 정식 창구다.

v1이 모든 값을 Store 하나에 몰아넣던 습관은 "당시 정적 타입이 없어 단순하게
쓰는 게 편해서"였다는 게 사용자의 회고적 재평가 — 지금은 타입이 핵심
제약이라 그 전제 자체가 더 이상 안 맞고, 2026-08-06 후속 세션의 정리로
Store는 "이름 붙은 Source 모음, 그 이상 아님"으로 더 단순해짐. 값 하나만
반응형으로 다루고 싶으면 Store를 통째로 만들지 말고 독립
`Source(default)`를 쓸 것(`base/source-state-plan.md`의 "Source는 독립
공개 프리미티브로 격상" 절).

## Store 값 설정 문법 — `store.key = v`와 `store:Of(k):Set(v)`는 같은 것 (2026-08-25 재역전)

> **⭐⭐ [2026-08-25 재역전] 2026-08-06에 확정했던 "`myStore.key = value`
> 폐기, `source:Set(value)`로 전환"은 뒤집혔다.** 원문과 역전 이유는
> 이 파일(당시 이름은 store-source-record-model-reversed.md였다). 여기 옛 결정을 남겨두면
> 앞에서부터 읽는 구현자가 그걸 그대로 믿으므로 포인터만 남긴다.

**둘 다 정식 경로이고 같은 것이다.**

```lua
store.hp = 5              -- __newindex → store:Of("hp"):Set(5)
store:Of("hp"):Set(5)     -- 프리미티브
```

- **왜 되살아났나**: 옛 결정의 첫 근거는 *"읽기(`Source<T>`)/쓰기(`T`)
  타입이 갈려 mismatch가 남음"*이었는데, 위 재설계로 **읽기도 `T`가 되어
  대칭**이다. `luau-analyze` 실측에서 `store.hp = 5`는 통과하고
  `store.hp = "five"`는 정확히 걸린다.
- 옛 결정의 둘째 근거(*"`=`가 암시하는 즉시 커밋이 quad의 lazy와 안
  맞음"*)도 이 자리에선 약하다 — lazy한 것은 **하류 전파**이지 Store 값
  자체가 아니다. 사용자: *"연산이 안 일어난다. 진짜 현 값이 맞음."*
- 옛 결정의 셋째 근거(**"값을 바꾸는 연산엔 `:` 체이닝 허용"** 원칙,
  `base/architecture.md`)는 그대로 유지된다 — `store:Of(k):Set(v)`가
  그 사례다.
- **`myStore "key"`(문자열 커링)는 여전히 기각**이다(2026-08-18 사용자
  판정) — *"저러면 "a" 가 string 으로 들어가서, Source<T> 의 타입을 모르기도
  하고, 우린 더이상 필요하지 않게 된 요소임."* 동적 키는 아래
  `:GetDynamic`으로 간다.

`base/architecture.md`의 "복사(clone) 구현 지양, 팩토리 함수로 대체" 원칙과 함께
읽을 것 — v1의 문제는 metatable 체이닝으로 매번 새 테이블을 할당하며
"불변 빌더"를 흉내낸 것이었지, `:` 체이닝 문법 자체나 대입 문법 자체가
아니었음.

## 타입 추론 문제 — `store.key`(dot-access)를 1급 경로로 확정 (2026-08-04 3차 라운드, 2026-08-25 재작성)

- `store "key"`(문자열 커링)로 `state<T>`를 오버로드 함수 타입으로 정확히
  추론하려는 시도는 포기하고(그 문자열 커링 자체도 **[2026-08-18] 기각**,
  위 절), **`store.key`(dot-access)를 1급 경로로 확정**. Store 타입을
  `index<>`/`keyof<>`로 지으면 일반 구조적 필드 타이핑으로 자동 해결되고,
  문자열 리터럴 narrowing 문제 자체가 안 생김(구체적인 모양은 아래
  "`store.key` 레코드 필드 타이핑" 절).
- **동적 키 경로는 명시적 메소드다** — `store:GetDynamic<<T>>(name): Source<T>`.
  런타임 동작 자체는 dot-access와 같고 문제는 **타입**뿐이었다: 선언되지
  않은 이름은 결과 타입에 없어서 타입 에러가 난다(그게 방어선이라는 게
  사용자 확정). 그래서 "런타임에 이름이 정해지는" 정당한 용도를 위해
  **타입을 호출자가 직접 주는 명시적 창구**를 둔다 — 사용자 판정:
  *"동적히는 여전히 그냥 Store.Name 하면 얻어는 짐. 타입 애러가 난다는
  점인데, 이는 GetDynamic<T>(name): Source<T> 로 제공하는게 최선으로 보임."*
  - **⭐ [2026-08-25 실측 정정] `<<T>>`는 값 호출부에서 동작한다.**
    7라운드 `H-73`이 *"Luau엔 호출부 명시 타입 인자 문법이 없다"*고
    단정했으나 **틀렸다** — Luau의 **generic type instantiation**
    (`luau.org/types/generics/#generic-type-instantiation`)이 값 호출부에서도,
    콜론 메소드에서도 `T`를 실제로 묶는다. `luau-analyze` 실측:
    ```lua
    local ok:   Source<number> = store:GetDynamic<<number>>("x")  -- 진단 없음
    local bad:  Source<string> = store:GetDynamic<<number>>("y")  -- 정확히 걸림
    local none: Source<number> = store:GetDynamic("z")            -- Source<unknown>
    ```
    원문은 **인스턴스화를 생략한 호출만** 돌려보고 단정했다. 따라서
    `base/quad-types-plan.md`의 이중 꺾쇠 관례는 타입 자리 전용이 아니다.
- **⭐ [2026-08-25 확정] 표면은 전부 콜론 메소드이고, 예약 키 충돌은
  타입 함수가 잡는다.** 예약 이름은 `Of`/`Names`/`GetDynamic`/`__store`
  (팬텀 필드)다.
  - **안 잡으면 조용히 죽는다** — 실측에서 사용자 키가 예약 이름과 겹치면
    교집합이 뭉개져 **그 필드의 타입 검사가 통째로 꺼진다**(음성 대조군이
    진단 0건으로 통과했다). 시끄럽게 막히는 게 아니라 그냥 지나간다.
  - 그래서 `T`를 **검증만 하고 그대로 통과시키는** 작은 `type function`을
    둔다. 겹치면 사용 지점에
    `TypeError: quad.Store: "Of" is a reserved key`가 뜬다.
    ```lua
    type function CheckReserved(t: type): type
        -- 겹치면 print(...) + return types.never, 아니면 t를 그대로 반환
    end
    type Store<T> = StoreOf<CheckReserved<T>>
    ```
  - **`error()`는 못 쓴다** — `type function` 자체가 실패한 걸로 판정돼
    버려진다. `print(...)` + `return types.never` 조합만 된다
    (`luau-test/done/23-type-quadtypes-checkversion-addplugin.luau`가
    기록해둔 사실이고 `type-version-check`가 이미 쓰는 패턴).
  - **[2026-08-25 해소] 옛 "탑레벨 함수로 옮길지" 미결은 닫혔다** —
    콜론 유지로 확정했고, 예약 키 문제는 위 타입 함수가 받는다. 팬텀
    필드(`__store`)의 사용은 UB로 둔다.
- 이 패턴은 Store에만 국한되지 않고 **인스턴스 생성까지 관통하는 프로젝트
  전역 관습으로 확정**됨 — 단 이벤트는 이후 4차 라운드에서 이 관습의
  **유일한 예외**로 빠졌음(PA님 방식인 문자열 키+런타임 리플렉션으로 전환).
  `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학"
  절이 최신 확정 내용.

### `store.key` 레코드 필드 타이핑 — `index<>`/`keyof<>`로 해결 (2026-08-25 재작성, `WrapStore` 폐기)

> **⭐⭐ [2026-08-25] 옛 `WrapStore`/`ProcessStoreType` 타입 함수 접근은
> 폐기됐다.** 원문은 이 파일(당시 이름은 store-source-record-model-reversed.md였다).
> 7라운드 `H-75`/`H-76`이 그 접근의 두 한계를 실측했는데(평평한 선언이면
> `store.key:Compute(무주석 콜백)`이 깨짐 / `type function`이 바깥 타입
> 별칭을 참조 못 해 구조를 통째로 중복 작성해야 하고 메소드 self
> 파라미터가 불변이라 필드 하나만 어긋나도 대입 실패), 아래 모양은
> **결과 타입을 합성하지 않으므로** 두 한계에 아예 안 닿는다.

**확정 형태** — 팬텀 필드에 선언 원형을 싣고, `index<>`/`keyof<>`로 꺼낸다.

```lua
type StoreOf<T> = {
    __store: T,                                    -- 팬텀. 사용은 UB.
    Of: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
         -> Source<index<index<Self, "__store">, K>>,
    Names: <Self>(self: Self) -> { keyof<index<Self, "__store">> },
    GetDynamic: <T>(self: any, name: string) -> Source<T>,
} & T
type Store<T> = StoreOf<CheckReserved<T>>
```

- `& T`가 dot-access(`store.hp`)를 그대로 만들어준다 — 타입 인자가
  **평범한 값 타입**이므로 `store.hp`가 `number`다.
- `K & keyof<...>`가 **싱글톤을 보존**한다. 사용자가 실측으로 확인한
  성질이다: 타입 후보 중에 싱글톤이 있으면 `string`으로 뭉개지지 않고
  `"hp"` 그대로 넘어간다. 그래서 `index<T, K>`가 그 키의 실제 타입을
  뽑아낸다.
- **`luau-analyze` 실측**(전부 `--!strict`, 양성 + 음성 대조군):

  | 검사 | 결과 |
  |---|---|
  | `store.hp` | `number` ✅ (음성 대조군 걸림) |
  | `store.hp = 5` / `= "five"` | 통과 / **걸림** ✅ |
  | `store:Of("hp")` | `Source<number>` ✅ (음성 대조군 걸림) |
  | `store:Of("name")`(`string?` 선언) | `Source<string?>` ✅ |
  | `store:Of("nope")` | **거부** ✅ |
  | `store:Names()` | `{ "hp" \| "name" }` ✅ |
  | `store:Of("hp"):Set(3)` / `:Set("3")` | 통과 / **걸림** ✅ |
  | `Store<{ Of: number }>` | **`"Of" is a reserved key`** ✅ |
  | `store:Of("hp"):Compute(무주석 콜백)` | ⚠️ **파라미터 주석 필요**(아래 캐비엇) |

- **⚠️ [2026-08-25 정정] `store.key:Compute(…)`라고 적었던 표 행은 거짓이었다.**
  실측한 적이 없었고(`/code-review high`가 잡음), 애초에 새 모델에서
  `store.key`는 **값**이라 `:Compute`가 없다
  (`Type 'number' does not have key 'Compute'`). 파생은 프리미티브를
  거친다 — `store:Of("hp"):Compute(...)`.
- **⭐ `store:Of(k)`의 반환값 추론은 무주석으로 정확하다 — Store 특유의
  타입 문제는 없다.** 실측(`audit/type-store-index-keyof/spikes/08`):
  ```lua
  local hp = store:Of("hp")     -- 무주석
  local a: number = hp:Get()    -- ✅   (string 대조군은 정확히 걸림)
  hp:NoSuchMethod()             -- ✅ 걸림
  hp:Set(5)                     -- ✅   (`:Set("5")`는 걸림)
  local nm = store:Of("name")   -- Source<string?>  ← `?` 선언이 그대로 드러남
  ```
- **걸리는 자리는 하나 — `:Compute`/`:With`의 콜백 파라미터 무주석 추론**이고,
  그건 Store가 만든 게 아니라 `base/typing-limits.md` §1의 **문제 A** 그
  자체다. 해법도 그 문서가 정한 그대로 — **파라미터에 주석을 단다**(실측
  통과):
  ```lua
  hp:Compute(function(s) return s:Get() * 2 end)                  -- ❌ 진단
  hp:Compute(function(s: StateData<number>) return s:Get() * 2 end) -- ✅
  ```
  §1②쪼개기가 평범한 `Source`에서 이 자리를 덮어주는 것과 달리 `Of`를
  거치면 안 걸린다(`Self` 제네릭 때문 — `spikes/07`). `& T` 형태에서
  `Self`를 빼는 건 불가능하고(`self: any`는 탐색 기록의 `Store4`처럼 통째로
  깨진다), §0의 *"Luau의 한계를 우회하려고 타입/API를 비틀지 않는다"*에
  따라 표면을 비틀지 않는다.
- **파생 결과에 명시 주석을 다는 상시 규약은 그대로 유효하다** —
  `audit/type-recursion-issue/REPORT.md` 3-1절이 실측(`43`)으로 확인한
  대로, 명시 주석 이후 **다운스트림 전체는 정상 체크**되고 구멍은 그 한
  줄(RHS가 실제로 그 타입인지)뿐이다.
- **`__call` 경로는 죽었다** — 타입 레벨 `__call`은 `self`를 못 받고,
  `typeof(f<<T>>)`로 타입 인자를 넘기는 것도 실패한다(사용자 실측).
  그래서 Store를 콜러블로 만드는 안은 성립하지 않는다. 같은 사실이
  `base/source-state-plan.md`의 `:Apply`에도 적용된다(7라운드 `H-94`).

---

## 이 시도 이전의 원문은 archive에 없다

옛 `WrapStore`/`ProcessStoreType` 접근(2026-08-12~2026-08-15)은 `H-75`/`H-76`
실측으로 폐기됐고, 그 폐기는 **철회되지 않았다** — `base/typing-limits.md`
§5의 폐기 배너와 `luau-test/STATUS.md`의 `16`/`21` 항목이 소스다.
`store.key = value` 폐기(2026-08-06)와 dot-access 1급 경로도 **현행**이라
`base/store-plan.md`에 그대로 있다.
