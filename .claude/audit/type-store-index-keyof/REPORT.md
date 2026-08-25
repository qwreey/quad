# 실측 — Store 타이핑을 `index<>`/`keyof<>`로 다시 짜기 (2026-08-25)

> **⛔⛔ [2026-08-25, 같은 날] 이 실측이 뒷받침하던 설계는 철회됐다.**
> 여기 기록된 **측정값 자체는 전부 유효**하다(재현 가능). 다만 그 위에
> 세웠던 결론 — "`index<>`/`keyof<>` + 팬텀 필드로 Store를 짓는다" — 은
> 같은 날 철회됐고, 지금 Store는 **타입 함수를 안 쓰고** 타입 인자에
> `Source<T>`를 직접 써서 평범한 레코드로 짓는다(`base/store-plan.md`).
> 철회 이유는 `archive/store-value-field-redesign-withdrawn.md`,
> 원칙은 `base/typing-limits.md` §0(*"타입 함수는 진단까지만"*).
>
> **그래도 이 문서를 남기는 이유**: (1) `H-73` 반증(`f<<T>>()`가 값
> 호출부에서 동작)은 지금도 유효한 확정 사실이고, (2) 실패한 formulation
> 표는 "다시 시도하지 말 것" 목록으로 계속 값을 하며, (3) 싱글톤 보존
> 규칙과 `__call`이 죽은 경로라는 것도 Luau 자체의 성질이라 그대로다.
> (4) `spikes/07`이 잰 **`Self` 제네릭이 콜백 파라미터 추론을 깬다**는
> 것이 철회의 직접 근거 중 하나였다.

**무엇인가**: `WrapStore`/`ProcessStoreType` 타입 함수로 결과 타입을
**합성**하던 Store 타이핑을 폐기하고 `index<>`/`keyof<>` + 팬텀 필드로
다시 지을 수 있는지를 `luau-analyze`로 판정한 기록. **계획이 아니라
실측 결과**다 — 지금 유효한 설계는 `base/store-plan.md`가 소스이고,
뒤집힌 옛 모델은 `archive/store-value-field-redesign-withdrawn.md`.

**발단**: 7라운드 손 트레이싱 `H-75`/`H-76`이 `WrapStore` 접근의 두 한계를
실측했고(평평한 합성이면 `store.key:Compute(무주석 콜백)`이 깨짐 /
`type function`이 바깥 타입 별칭을 참조 못 해 구조를 통째로 중복 작성해야
하고 self 파라미터 불변성 때문에 필드 하나만 어긋나도 대입 실패),
**사용자가 직접 `test.luau`로 대안을 탐색**했다.

**⚠️ 스크립트를 같이 두는 예외적 구성** — 판정이 "여러 formulation 대조"라
개별 파일을 직접 돌려야 재현된다(`audit/type-recursion-issue/`와 같은 이유).
전부 `luau-analyze <파일>`로 돌린다. **[2026-08-25 기준] `.luaurc`가
`languageMode: strict`이므로 진단이 이 프로젝트에 그대로 적용된다.**

| 파일 | 무엇을 보나 |
|---|---|
| `spikes/01-exploration.luau` | **사용자 탐색 원본**(루트 `test.luau`). `const` → `local`만 고쳤다. 주석에 적힌 기대 진단이 곧 판정이고, 아래 "실패한 formulation" 절이 이 파일을 읽는 지도다 |
| `spikes/02-toplevel-form.luau` | 조작 표면을 **탑레벨 함수**로 뺀 형태 — 예약 키가 팬텀 하나로 줄어드는지 |
| `spikes/03-value-index-form.luau` | **확정된 형태** — 타입 인자가 평범한 값 타입이고 `Of`가 `Source<>`를 씌움 |
| `spikes/04-reserved-key-silent.luau` | 예약 키 충돌 시 **타입 검사가 조용히 죽는지** |
| `spikes/05-checkreserved.luau` | `CheckReserved` 타입 함수가 그 침묵을 **시끄럽게** 만드는지 |
| `spikes/06-generic-instantiation.luau` | `f<<T>>()`가 값 호출부·콜론 메소드에서 `T`를 실제로 묶는지(`H-73` 반증) |
| `spikes/07-self-generic-inference.luau` | **[2026-08-25 추가]** 무주석 콜백 추론이 어느 구성에서 깨지는지 — `Self` 제네릭만 걸리고 `index<>`/`keyof<>`/`K` 제네릭은 안 걸린다 |

---

## 결론

### ✅ 성립 — 마법 타입 함수 없이 Store 전체가 타이핑된다

```lua
type StoreOf<T> = {
    __store: T,                                    -- 팬텀. 사용은 UB.
    Of: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
         -> Source<index<index<Self, "__store">, K>>,
    Names: <Self>(self: Self) -> { keyof<index<Self, "__store">> },
} & T
type Store<T> = StoreOf<CheckReserved<T>>
```

`spikes/03`의 양성 6건이 전부 진단 0건이고 음성 대조군 5건이 전부 정확히
걸렸다(**[2026-08-25 정정]** 아래 표의 마지막 두 행 — `:Names()`와
`Compute` — 은 `03`이 아니라 각각 `02`/`07`이 근거다):

| 검사 | 결과 |
|---|---|
| `store.hp` | `number` ✅ (음성 대조군 걸림) |
| `store.hp = 5` / `= "five"` | 통과 / **걸림** ✅ |
| `store:Of("hp")` | `Source<number>` ✅ (음성 대조군 걸림) |
| `store:Of("name")`(`string?` 선언) | `Source<string?>` ✅ |
| `store:Of("nope")` | **거부** ✅ |
| `store:Names()` | `{ "hp" \| "name" }` ✅ |
| `store:Of("hp"):Set(3)` / `:Set("3")` | 통과 / **걸림** ✅ |
| `store:Of("hp"):Compute(무주석 콜백)` | ⚠️ **파라미터 주석 필요**(아래 캐비엇) |

**⚠️ [2026-08-25 정정] 이 표에 있던
*"`store.key:Compute(무주석 콜백)` 파라미터 추론 정상 ✅"* 행은 **실측한 적이
없고 거짓이었다**(`/code-review high`가 잡음 — `spikes/03`엔 `Compute`가
아예 없다). 새 모델에서 `store.key`는 **값**이라 `:Compute`가 없고
(`Type 'number' does not have key 'Compute'`), 파생은
`store:Of("hp"):Compute(...)`로 만든다.

**정본 선언으로 다시 재보니 두 축이 갈린다**(`spikes/08`):

| 검사 | 결과 |
|---|---|
| `local hp = store:Of("hp")` → `hp:Get()` | **`number`** ✅ (무주석, `string` 대조군 걸림) |
| `hp:NoSuchMethod()` | ✅ 걸림 |
| `hp:Set(5)` / `hp:Set("5")` | 통과 / **걸림** ✅ |
| `store:Of("name")`(`string?` 선언) | `Source<string?>` ✅ (`number` 대조군 걸림) |
| `hp:Compute(function(s) … end)` | ❌ **콜백 파라미터**만 안 잡힘 |
| `hp:Compute(function(s: StateData<number>) … end)` | ✅ 통과 |

- **반환값 추론은 무주석으로 정확하다** — `store:Of(k)` 자체엔 Store 특유의
  타입 문제가 **없다**.
- **걸리는 건 `:Compute`/`:With`의 콜백 파라미터 하나**이고, 그건 Store가
  만든 게 아니라 `base/typing-limits.md` §1의 **문제 A** 그 자체다.
  해법도 그 문서가 정한 대로 파라미터 주석이고, 실측으로 통과한다.
- §1②쪼개기가 평범한 `Source`에서 이 자리를 덮어주는 것과 달리 `Of`를
  거치면 안 걸린다(`spikes/07` — `Self` 제네릭). `& T` 형태에서 `Self`를
  빼는 건 불가능하다(`self: any`는 `Store4`처럼 통째로 깨진다). §0의
  *"Luau의 한계를 우회하려고 타입/API를 비틀지 않는다"*에 따라 표면을
  비틀지 않는다.
- 파생 결과에 명시 주석을 다는 상시 규약은 그대로다 —
  `audit/type-recursion-issue/REPORT.md` 3-1절(`43`)이 확인한 대로 명시
  주석 이후 다운스트림 전체는 정상 체크된다.

별도로 확인한 것 하나: `:Compute`의 **반환 타입** 음성 대조군은 평범한
`Source`에서도 안 걸리는데, 그건 이 Store 설계와 무관한 `Compute` 시그니처
쪽 성질이다(과잉 주장하지 말 것).

### ⭐ 싱글톤 보존 규칙 — 어떤 형태가 `string`으로 안 뭉개지는가

이 설계 전체가 **`K`가 `"hp"` 같은 싱글톤으로 넘어온다**는 데 기대고 있어서
따로 실측했다(`spikes/01`의 `singletonTest1`~`4`).

| 선언 | `f("bbb")`의 `T` | 진단 |
|---|---|---|
| `f<T>(input: T): T` | `string` ❌ 뭉개짐 | 없음 |
| `f<T>(input: T & string): T` | `unknown` ❌ | 없음 |
| `f<T>(input: T & ""): T` | `"bbb"` ✅ | **에러**(`"bbb"`가 `""`의 서브타입이 아님) |
| **`f<T>(input: T \| "" \| string): T`** | `"bbb"` ✅ | **없음** ✅ |
| **`f<T>(input: T & ("A" \| "B")): T`** | `"B"` ✅ | 없음(범위 밖이면 정확히 걸림) ✅ |

**규칙**: 타입 후보 중에 **싱글톤이 있으면** 추론이 `string`으로 안 뭉개고
있는 그대로 넘긴다. `K & keyof<...>`가 바로 그 형태라(키 이름들의 싱글톤
유니온) 의도대로 동작하고, **범위 밖 키는 교집합이 비어 정확히 거부된다.**
사용자 관찰: *"K& 를 걸고 유니온 스트링을 걸면, K 가 싱글톤으로써, string 으로
뭉개지지 않고 전해진다."*

### ⛔ 실패한 formulation — 왜 다른 모양은 안 되는가

`spikes/01`이 순서대로 밟은 막다른 길들. 다시 시도하지 말 것:

| 형태 | 무엇이 막았나 |
|---|---|
| `Store2<T>`: `__call: typeof(getter2<<T>>)` | **완전 실패** — `type function` 밖에서도 타입 별칭 인자를 `typeof`에 실어 나를 수 없다. `H-76`이 관측한 것과 같은 벽 |
| `Store<T>`: `__call: <K>(K & keyof<T>) -> index<T, K>` | `Argument count mismatch. Function expects 1 argument, but 1 is specified` — **타입 레벨 `__call`은 `self`를 못 받는다**(인자 목록만 남음) |
| `Store3<T>`: `Set`/`Peek`을 **점 호출**로 | 동작은 하나 `Set`의 시그니처만 봐선 뭘 넣어야 할지 감이 안 온다(사용자 판정). 값 타입을 알기 어려워 직접 인덱스를 허용해야 함 |
| `Store4<T>`: `{ Peek: <K>(self: any, ...) } & T` | `Property 'any' does not exist on type '{...}'` — `& T`가 `self: any` 자리에 끼어들어 깨진다 |
| `Store5<T>`: `self: Store5<Inner>`로 self를 명시 | `Peek`의 인자가 **에러 타입**이 된다 |
| `Store6<T>`: **`__realtype` 팬텀 + `index<index<Self,"__realtype">, K>`** | ✅ **성립** — 이게 확정 형태의 원형이다 |

**`__call` 경로는 죽었다**는 게 이 표의 요지이고, 그 사실이
`base/source-state-plan.md`의 `:Apply`(7라운드 `H-94`)와
`base/gate-plan.md` 2번에 반영됐다 — 애플리커티브 팩토리는 `__call`이
아니라 **지정된 필드**로 자기를 노출한다.

### ⚠️ 예약 키 충돌은 **조용히** 타입 검사를 끈다

`spikes/04`에서 `Store<{ Peek: number, __store: boolean }>`로 걸었더니
**진단 0건**인데, 그 안엔 걸려야 할 음성 대조군이 있다:

```lua
local g3: string = clash.Peek     -- Peek 은 number 인데 진단 없음 ❌
```

즉 사용자 키가 예약 이름과 겹치면 교집합이 뭉개져 **그 필드에 대한 타입
검사가 통째로 죽는다.** 시끄럽게 막히는 게 아니라 그냥 지나간다.

### ✅ `CheckReserved`가 그 침묵을 없앤다

`spikes/05`에서 확인:

```
TypeError: quad.Store: "Of" is a reserved key
```

**`error()`는 못 쓴다** — `type function` 자체가 실패한 걸로 판정돼 버려진다.
`print(...)` + `return types.never` 조합만 된다
(`luau-test/done/23-type-quadtypes-checkversion-addplugin.luau`가 기록해둔
사실이고 `type-version-check`가 이미 쓰는 패턴). 이 타입 함수는 `T`를
**검증만 하고 그대로 통과**시키므로 `H-75`/`H-76`이 지적한 합성의 두 한계에
아예 안 닿는다.

### ✅ `f<<T>>()`가 값 호출부에서 동작한다 — `H-73` 반증

`spikes/06`:

```lua
local ok:   Source<number> = store:GetDynamic<<number>>("x")  -- 진단 없음 ✅
local bad:  Source<string> = store:GetDynamic<<number>>("y")  -- 정확히 걸림 ✅
local none: Source<number> = store:GetDynamic("z")            -- Source<unknown>
```

7라운드 `H-73`은 **인스턴스화를 생략한 호출만** 돌려보고 *"Luau엔 호출부
명시 타입 인자 문법이 없다"*로 단정했다. 실제로는 Luau의 **generic type
instantiation**(`luau.org/types/generics/#generic-type-instantiation`)이
값 호출부에서도, **콜론 메소드에서도** `T`를 묶는다. 그래서
`base/quad-types-plan.md`의 이중 꺾쇠 관례는 타입 자리 전용이 아니다.

---

## 이 실측이 바꾼 문서

- `base/store-plan.md` — "Store = Source들의 이름 붙은 모음" / "Store 값 설정 문법" /
  "타입 추론 문제" / "`store.key` 레코드 필드 타이핑" 네 절 재작성
- `base/typing-limits.md` — §5가 폐기 배너를 달았고, §7에 싱글톤/인스턴스화 항목 추가
- `base/quad-types-plan.md` — 이중 꺾쇠 관례가 값 호출부까지 확장
- `archive/store-value-field-redesign-withdrawn.md` — 뒤집힌 옛 모델 원문
- `luau-test/STATUS.md` — 스파이크 `16`/`21`이 `rewrite-required/`로
