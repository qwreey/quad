# Attribute — 단일 키(`AttributeKey`)와 그룹(`Attribute(...)`) 두 프리미티브

> **✅ [2026-08-13 열네 번째 세션] `question.md` 0-Z(이름 소유권) 확정 +
> 하강 diff 재디스패치 반영 완료 — 이 문서는 이제 최신 모델을 서술합니다.**
> 이전 ⚠️ 배너가 예고하던 교체가 전부 끝났음: (1) 그룹은 **자기 전용 키**로
> 위임하고(비공개 `GetKey`), 이름 소유권은 **`AttributeKeyHandler`의 이름
> claim**이 판정(아래 "이름 소유권" 절), (2) `retractFrom` 선행 호출은
> 폐기되고 `Dispatch.process`가 핸들러를 먼저 비교
> (`base/dispatch-core-plan.md`), (3) **값 타입·알고리즘 전부 quad-base
> 소속으로 재배치**되고 `setAttribute` op만 백엔드가 주입(아래 "패키지
> 배치" 절). 뒤집힌 옛 모델 원문은
> `archive/dispatch-hintvalue-model-reversed.md`.

**상태**: base — 단일 키 메커니즘/`None`/`retract` 동작과 타입 파라미터화는
전부 확정(2026-08-09 열한 번째 세션, **2026-08-12 세션 후속에서
`retract` 완전 no-op화 + 그룹 청소 정책 전면 재정정 — 아래 "메커니즘"/
"그룹 `Attribute(...)`" 절이 최신**). **[2026-08-13 세션, 하루 안에서
네 차례 재설계 — 지금은 마지막 것이 확정]** 그룹/직접 쓰기 이름 충돌
방지 방식이 `rawNew`+`owners` 수동 레지스트리 → `AttributeGroupKeyHandler`
체크포인트(`Dispatch.processAs`/`retractSelfAndUnder`) → 공개
`AttributeKey(name)`+Dispatch 점유 체크 → **최종적으로 그룹 전용 키
(비공개 `GetKey`) + `AttributeKeyHandler`의 이름 claim**(2026-08-13
열네 번째 세션, `question.md` 0-Z 확정). 세 번째 안이 다시 뒤집힌
이유는 하강 diff 재디스패치에선 **두 그룹이 똑같이 `StoreBind`로 보여
"같은 핸들러"로 판정**되므로 점유 체크가 성립하지 않기 때문 — 아래
"이름 소유권"/"메커니즘" 절이 최신, 중간 버전들은 `archive/
checkpoint-handler-pattern-reversed.md`와
`archive/dispatch-hintvalue-model-reversed.md`에 보존. **[2026-08-11 아홉 번째 세션 추가]**
Store 여러 개를 한 번에 attribute로 묶어 바인드하는 그룹 `Attribute(...)`
프리미티브 신설, 이름 충돌 방지를 위해 기존 단일 키 생성자를
`Attribute<<T>>` → `AttributeKey<<T>>`로 리네임(잠정 확정 — 최종 이름은
여전히 `.claude/question.md` 용어정리 대기열). `[AttributeKey "Name"]`(구
`[Attribute "Name"]`) DI 키의 존재 자체는 `architecture.md` 4번 항목에서
이미 확정. UICorner 숏핸드/Tween처럼
별도 전용 문서가 없던 걸 2026-08-07 여덟 번째 세션에 메꿈("1 프리미티브 1
파일" 관례를 Tag/Attribute에도 적용해야 한다는 사용자 지적) —
`bind-system-plan.md`의 "Attribute 특수 키 — 타입 파라미터화" 절(2026-08-06
신설) 내용을 그대로 옮기고, 논의한 `None`/`process`/`retract` 동작을 추가.

## 단일 키 — `AttributeKey<<T>>` (구 `Attribute<<T>>`)

### 문제 — 타입 있는 값이라 Luau가 좁혀줄 방법이 필요

Roblox Attribute는 Instance/Tag와 달리 실제로 **타입이 있는 값**
(string/boolean/number/Color3/UDim/UDim2/Vector2/Vector3/CFrame/Instance
참조 등 제한된 프리미티브 집합, 테이블 등 복합 타입은 지원 안 함)이라, 그냥
`[AttributeKey "name"] = value`로 두면 `value`의 타입을 Luau가 좁혀줄 방법이
없음. 커스텀/복합 데이터(테이블 등)는 애초에 Attribute가 지원을 안 하므로
Ref(직접 참조 획득) 쪽으로 빠지는 게 맞고, Attribute는 프리미티브 전용으로
남기면 된다는 게 사용자 판단 — Value 오브젝트가 역사적으로 Attribute의
대안(테이블/참조를 담는 용도)으로 나온 배경이지만, 지금은 Roblox Attribute가
Instance 참조 타입도 지원해서 `ObjectValue` 없이도 Ref 용도로 Attribute를
그대로 쓸 수 있다는 점을 사용자가 짚음(`research/debug-tooling-plan.md`의
"Value 오브젝트 기각, Attribute로 확정" 결정과 같은 방향 — Instance 타입
지원까지 감안하면 그 결정의 근거가 한층 더 탄탄해짐).

**확정(2026-08-09 열한 번째 세션) — 둘 다 채택**:
- `[AttributeKey<<boolean>> "name"] = true` (리터럴 또는 store-bind 값) —
  제네릭 파라미터로 타입을 명시하는 제네릭 생성자 스타일. 기본/범용 경로.
- `[BooleanAttribute "name"] = true` — 타입별로 이름이 다른 정적 생성자
  패밀리(`StringAttribute`/`NumberAttribute`/`Color3Attribute`/
  `InstanceAttribute` 등). 실사용 빈도가 높은 몇 개만 지름길로. **이름은
  `Attribute`가 아니라 이미 타입별로 갈라져 있어 아래 그룹 `Attribute(...)`와
  겹치지 않음 — 리네임 대상 아님.**

**근거**: 이미 확정된 DI 인스턴스 생성 패턴(`bind-system-plan.md` "인스턴스
생성 / 이벤트 네이밍 인체공학" 절)과 구조적으로 똑같은 문제라 같은 결론
재사용 — `new<ClassName>(className)` 제네릭 생성자 + 자주 쓰는 ~25개는
정적 필드로 미리 바인딩했던 것과 동일한 절충. **내부 구현은 완전히
동일**(같은 Handler를 타고, 같은 프리미티브) — 둘 사이 차이는 순전히
호출부가 타입을 어떻게 명시하느냐(제네릭 파라미터 vs 이름)뿐이라 어느
쪽을 쓰든 런타임 동작에 차이 없음.

**[실측 필요, M0/M10]** `[AttributeKey<<boolean>> "name"] = value`처럼 DI
키 제네릭 파라미터로 `=` 뒤 `value`의 타입까지 실제로 좁혀지는지는
미검증 — Luau 솔버가 이 조합을 못 풀면 `value`가 `any`로 남을 수 있음.
단, **타입 추론이 안 되더라도 런타임 동작에는 영향 없음**(순수 정적
타입체크 실패일 뿐, `SetAttribute` 호출 자체는 항상 정상 작동) — 안
되면 `BooleanAttribute` 같은 정적 타입 패밀리 쪽이 사실상 유일하게
믿을 수 있는 정적 체크 경로가 됨.

### 동등성 — 이름별 weak 캐시로 `AttributeKey(name) == AttributeKey(name)` 보장 (2026-08-11 아홉 번째 세션 후속)

**확정**: `AttributeKey<<T>>(name)`(및 `BooleanAttribute(name)` 등 정적
패밀리 전부 — 아래 참고)는 내부적으로 이름별 weak 캐시를 거침:

```lua
local cache = setmetatable({}, { __mode = "v" })  -- 값만 weak
local function AttributeKey(name)
    local cached = cache[name]
    if cached then return cached end
    local real = -- 진짜 생성(Brand 부여 등)
    cache[name] = real
    return real
end
```

- **캐시 키는 순수 문자열 `name`뿐, 제네릭 파라미터 `T`는 안 씀** —
  `T`는 런타임에 아무 영향 없는 순수 정적 타입 트릭(위 "근거" 절의
  "내부 구현은 완전히 동일" 그대로)이라, `AttributeKey<<boolean>>("Enabled")`와
  `AttributeKey<<number>>("Enabled")`는 실제로 **완전히 같은 런타임
  객체**를 돌려받음(호출부에서 다른 정적 타입으로 캐스팅될 뿐). 같은
  이유로 `BooleanAttribute("Enabled")`도 같은 캐시를 공유해 동일 객체를
  반환해야 함 — "내부 구현이 완전히 동일하다"는 기존 확정이 객체
  identity 수준까지 이제 실제로 보장됨.
- **값만 weak라서 "쓰는 도중엔 항상 같은 게 리턴, 다 쓰고 나면 자연히
  풀림"**: 어딘가(Dispatch의 `(inst,k)`별 핸들러 체인 등)가 이 키
  객체를 강한 참조로 붙들고 있는 동안은 캐시 엔트리도 계속 살아있어
  같은 이름으로 다시 호출해도 항상 같은 객체가 나옴. 아무도 안 붙들게
  되면(그 이름의 attribute 바인딩이 완전히 retract됨) GC가 캐시 엔트리를
  걷어가고, 그 다음에 같은 이름을 다시 부르면 새 객체가 생기는데 —
  이 시점엔 이전 객체를 참조하는 곳이 아무도 없었으므로 identity가
  달라져도 문제 될 게 없음.
- **`Tag`는 이 기법이 안 맞음**(비교 확인) — `AttributeKey(name)`은
  "이름 → 키" 외에 다른 가변 정보가 없는 순수 매핑이라 이름만으로
  캐시가 성립하지만, `Tag(...)`의 값은 내부 이름 목록 자체가 매번
  달라지는 게 핵심(`:Added`/`:Removed`로 계속 다른 집합을 표현)이라
  "캐시할 안정적인 키"가 애초에 없음 — 동등성 비교/캐싱이 의미가 없는
  이유가 이거.
- **[반영 완료] `OnChange(name)`도 같은 모양**(이름 → 키, 다른 가변
  정보 없음)이라 같은 기법 그대로 적용 — `State<function>`이 되더라도
  캐시는 키 객체 identity만 다루므로 문제 없고, `OnChange "a" == OnChange
  "a"`가 외부에 관찰되는 것도 의도적으로 허용 가능한 동작(사용자 확인).
  `base/onchange-plan.md` "확정" 절 참고.

### 메커니즘, `None`, 반환 클로저 — 전부 확정 (2026-08-07 여덟 번째 세션, 2026-08-13 열네 번째 세션에 이름 claim 추가)

타입 파라미터화 이름과 무관하게 런타임 동작은 확정:

- `process(inst, k, v, index)` — `setAttribute(inst, name, v)`가 사실상
  전부, **`v`가 뭐든(실제 값이든 `nil`이든) 무조건 그대로 호출** — 일반
  프로퍼티 핸들러와 완전히 동일한 무조건 set. **Attribute는 `None`의
  가장 깔끔한 사례** — 주입 op의 계약 자체가 `setAttribute(inst,name,nil)`
  = "그 Attribute 엔트리를 지운다"이므로(Roblox `SetAttribute`의 네이티브
  동작 그대로, `base/dispatch-core-plan.md` "base가 소유하는 핸들러와
  주입되는 엔진 op" 절), `None → nil` 재디스패치(같은 문서의 `None`
  센티널 절)가 도착했을 때 handler가 **아무 특별 처리도 없이** 그대로
  호출하면 끝 — UICorner 숏핸드처럼 "만들어둔 자식을 수동으로 찾아
  지우는" 로직조차 필요 없음.
- **반환하는 클로저는 `setAttribute`를 절대 호출하지 않음** — attribute를
  지우는 유일한 경로는 `process(inst,k,nil,index)`(`None`이든, State가
  스스로 `nil`로 바뀌든) 뿐(2026-08-12 세션 후속 확정, 그대로 유지).
  **[2026-08-13 열네 번째 세션] 다만 "완전 no-op"은 더 이상 아님** — 아래
  "이름 소유권" 절의 이름 claim을 반납하는 한 줄이 들어감. 엔진에 대한
  부작용은 여전히 0이고(관측 가능한 attribute 값은 안 건드림), 반납하는
  건 순수 부기라 아래 "`a→nil→b` 깜빡임" 위험도 그대로 없음. 이전
  버전("이름이 사라질 때(`v==nil`)만 클로저가 `SetAttribute(name,nil)`을
  호출")이 기각된 이유는 그대로 유효: (1) 클로저 안에 관측 가능한
  부작용이 생겨 "이 클로저는 구조적 팝만" 일반 규칙과 어긋남,
  (2) 그룹이 survivor 이름에 재위임할 때 `SetAttribute`가 잘못 끼어들어
  `a→nil→b` 깜빡임이 생길 수 있었음.
- store-bind 가능(일반 프로퍼티와 동일하게 취급, `Store<T>`/`State<T>`
  값도 받음).

### 이름 소유권 — 그룹 전용 키 + 이름 claim (2026-08-12 열 번째 세션 신설, 2026-08-13 열네 번째 세션 확정 = `question.md` 0-Z)

**문제**: 같은 attribute 이름을 **서로 다른 두 자리가 동시에 관리**할 수
있음 — 해시파트 직접 쓰기 `[AttributeKey "name"] = value` vs 배열파트
`Attribute(store)`, 또는 서로 다른 두 `Attribute(...)` 그룹. Modifier
필드는 정적이라 override로 이미 해소되지만(같은 해시 키는 한 Modifier
안에 하나뿐), 그룹의 이름 집합은 런타임에 동적이라 그 해소망 밖에 있음.

**왜 Dispatch가 대신 잡아줄 수 없는가**: 옛 모델에선 그룹이 공개
`AttributeKey(name)`(이름별 weak 캐시라 항상 같은 객체)으로 위임했고,
같은 `(inst,k)` 인덱스 1을 두 소유자가 노리면 `Dispatch.process`의 점유
체크가 error를 냈음. **하강 diff 재디스패치에선 이게 성립하지 않음** —
그룹 A가 등록해둔 인덱스 1의 핸들러는 `StoreBind`이고 그룹 B가 넘기는
`sourceB`도 `StoreBind`에 매치되므로 **"같은 핸들러"로 판정되어 조용히
갈아탐**. 게다가 나중에 A의 클로저가 자기 이름들을 `retractFrom`할 때
**B의 바인딩을 대신 철거**함(교차 오염) — 예전의 "조용한 last-write-wins"가
그대로 돌아옴.

**확정된 해법(2026-08-13 열네 번째 세션) — 두 조각**:

1. **그룹은 이름마다 자기 전용 키를 쓴다(비공개 `GetKey`)**. 그룹 값
   객체별·이름별로 메모이즈된 `AttributeKey`를 만들어 그걸로 위임 →
   그룹 A와 그룹 B와 직접 쓰기가 **서로 다른 체인**을 갖게 되어, 한
   소유자의 철거가 다른 소유자의 바인딩을 건드리는 **교차 오염이
   구조적으로 불가능**해짐.
2. **이름 자체의 소유권은 `AttributeKeyHandler`가 이름 claim으로 판정**.
   `(inst, name) → 지금 그 이름을 잡고 있는 키 객체`를 `Relate` 하나로
   들고, 다른 키 객체가 같은 이름에 들어오면 **즉시 error**.

**왜 이 조합인가 — 대안 (a)(그룹 안에 이름별 claimant `Relate`)로는 부족**:
(a)는 그룹↔그룹은 잡지만 **그룹↔직접 쓰기를 못 잡음**. 직접 쓰기는 그룹
코드를 아예 안 지나가서 그룹 쪽 레지스트리에 등록될 자리가 없고, 두
경로가 실제로 만나는 유일한 지점인 `AttributeKeyHandler`에서는 공개 키를
쓰는 한 `k`가 **같은 객체**라 소유자를 구분할 방법이 원천적으로 없기
때문. 전용 키가 있어야 비로소 "이 이름을 지금 누가 잡고 있나"를 **키
identity 하나로** 판정할 수 있고, 그러면 claim 로직이 그룹을 알 필요도
없어짐(그룹인지 직접 쓰기인지 구분 안 함 — 소유자 종류가 늘어도 그대로
동작). 후보 (b)(UB로 두고 문서화만)는 증상이 "조용한 오작동+교차 오염"이라
비권장으로 기각, (c)(`Dispatch`에 claimant 일반화)는 "Dispatch는 diff만
한다"는 방향과 어긋나 기각.

```lua
-- AttributeKeyHandler(quad-base) — 이름 claim만 자기 상태로 가짐
-- Relate는 항상 (inst, key) 2단 — `base/relate-plan.md` API 참고.
-- 여기선 key = attribute 이름, value = 그 이름을 지금 잡고 있는 키 객체.
local nameClaims = Relate()  -- {[inst(weak)] = {[name] = key(strong)}}

function AttributeKeyHandler.process(inst, k, v, index)
    local cur = nameClaims:GetStrong(inst, k.Name)
    if cur ~= nil and cur ~= k then
        error(`attribute "{k.Name}" is already bound by another owner`)
    end
    nameClaims:SetStrong(inst, k.Name, k)

    setAttribute(inst, k.Name, v)   -- v가 nil이든 아니든 무조건(위 "메커니즘" 절)

    return function()
        -- 엔진 부작용 없음 — claim 반납만. "내가 실제로 물러날 때만" 지움
        -- (`dispatch-core-plan.md` "Handler 작성 체크리스트" 4번).
        if nameClaims:GetStrong(inst, k.Name) == k then
            nameClaims:SetStrong(inst, k.Name, nil)
        end
    end
end
```

- **해제 → 재클레임 순서는 `Dispatch`가 보장함.** 같은 핸들러 재프로세스는
  `slot.retractor(v)` → `h.process(...)` 순서이고, 핸들러가 바뀌는 경우는
  `retractFrom` → `process` 순서(`base/dispatch-core-plan.md` "Dispatch
  체인" 절) — 어느 경로든 **옛 claim 반납이 새 claim보다 먼저**라 자기
  자신과 충돌하는 일이 없음. `5 → None → 5`처럼 체인 깊이가 오가는
  경우도 인덱스가 바뀌는 자리에서 `retractFrom`이 먼저 돌므로 동일.
- **`GetKey`는 공개 API가 아님(사용자 확정)** — 그룹 값 객체 바깥으로
  키를 반출하면, 사용자가 그 키를 다른 자리에 다시 놓아 **같은 키가 두
  자리에서 수렴**할 수 있고 그건 claim(키 identity 기준)으로도 잡히지
  않음(0-W "같은 `Ref` 객체 이중 배치"와 같은 형태의 갭). 비공개로
  두면 이 경로 자체가 없음 — 구현상으로도 그룹 핸들러 안의
  `Relate<그룹 값 → {[name] = key}>` 또는 클로저 캡처면 충분하고, base의
  `Attribute` 값 객체 공개 표면에는 아무것도 안 늘어남.
- **에러 메시지는 도메인 언어로** — 옛 모델의 일반 점유 error("이 인덱스는
  이미 점유돼 있음")와 달리 여기선 이름을 그대로 찍을 수 있음.
  `base/dispatch-core-plan.md`가 "상세 에러가 필요하면 호출부가 도메인
  언어로 다시 던지는 건 자유"라고 남겨둔 자리를 이게 채움.
- **직접 리터럴 쓰기**(`[AttributeKey<<T>> "name"] = value`)는 공개
  `AttributeKey(name)`을 그대로 씀 — 한 Modifier 안에 같은 해시 키가
  중복될 수 없어 이 경로 자체의 소유자는 항상 유일하고, 그룹이 이미 그
  이름을 잡고 있으면 claim이 즉시 error.
- **`Tag`와의 대조** — `Tag`는 같은 이름을 여러 위치가 공유하는 게
  **의도된 동작**(웹 `className` 합집합)이라 참조 카운트로 가고, Attribute는
  값이 하나뿐이라 겹침이 곧 충돌이라 claim으로 감. 두 정책의 차이는
  자원의 성질에서 나옴(`base/tag-plan.md`).

## 그룹 `Attribute(...)` — 여러 Store를 한 번에 attribute로 (2026-08-11 아홉 번째 세션 신설)

### 동기

Store 필드 여러 개를 각각 `[AttributeKey<<T>> "name"] = store.name`으로
나열하는 건, 이미 이름 붙은 typed Source 모음(Store)이 있는 상황에서
번거로움 — Store의 타입 체크/reactive 인프라를 attribute에도 그대로
재활용하고 싶다는 요구에서 출발.

### 검토했다 기각한 대안

- **`[Attribute] = Store {...}` (해시파트 단일 슬롯)**: 인스턴스당 이
  키 슬롯이 하나뿐이라, 헤테로지니어스한 Store 여러 개(예: 스타일
  Store + 상태 Store)를 한 인스턴스에 동시에 반영할 방법이 구조적으로
  없음 — 기각.
- **`Attribute`를 Store의 서브타입/확장으로**: Attribute가 Store를
  상속(IS-A)하면 `Store<T>`의 `T`가 다시 Attribute(=Store)일 수 있게
  되어, 이미 확정된 제약("핸들러 계층 값은 Source에 못 들어감" —
  `store-semantics.md`의 `Store<T>`의 `T`는 Modifier 불가 규칙과 같은
  이유)과 부딪히는 "Store 안에 Store"를 실제로 만들어냄. Attribute는
  Store를 **참조(HAS-A)**만 해야지 **상속(IS-A)**하면 안 됨 — 기각.

### 채택안 — `Tag`와 동형인 array-part 값 객체

```
Attribute(store1, store2, ..., {plain = "table도 됨"})  -- 생성자, 여러 개 받음
Attribute.Merged(a, b, ...): Attribute                   -- Tag.Merged와 동일 이유(헤테로지니어스 합성)
attr:NameMap(): {[string]: Source<any>}                  -- 평탄화된 이름→Source 맵(아래 "메커니즘" 절이 쓰는 것)
Frame { Attribute(styleStore), Attribute(stateStore) }   -- 여러 개 나란히 둬도 각자 자기 키만 반영(Tag와 동일)
```

**[2026-08-13 감사에서 추가] `:NameMap()`은 원래 "메커니즘" 절 의사코드에만
등장하고 이 API 목록엔 빠져 있었음** — Handler가 이름 집합을 순회하려면
반드시 필요한 공개 접근자라 여기 명시(`Tag:Names()`도 `tag-plan.md`에서
같은 누락이었고, 같은 감사에서 함께 추가됨 — 지금은 양쪽 다 문서화돼 있음).

`Attribute.Merged`가 내부적으로 하는 일은 각 Store에서 이름 붙은 `Source`
슬롯을 그대로 가져와 자기 자신의 key→Source 맵에 넣는 것 — 아래 "레이어드
Store 기각과 안 부딪히나" 참고.

### 메커니즘 — 그룹 전용 키로 단일 키 경로에 위임 (2026-08-13 열네 번째 세션 확정)

**[2026-08-11 아홉 번째 세션 후속, 개정]** 최초안은 "자기 완결형 Handler,
Dispatch 재진입 없이 직접 `SetAttribute`+수동 per-field StoreBind 구독"
이었으나, 위 "동등성" 절의 이름별 캐시가 확정되며 그 회피 이유 자체가
없어짐 — 그래서 그룹 Handler는 **자기만의 set/구독 로직을 새로 만들지
않고, 각 필드를 기존 단일 키 `AttributeKey` 경로에 그대로 재귀 위임**한다
(`None`/store-bind 전부 이미 확정된 단일 키 메커니즘을 100% 재사용, 중복
구현 없음). **위임에 쓰는 키만 세 번 바뀌었고 지금은 그룹 전용 키**
(`rawNew(name)` 전용 키 → `AttributeGroupKeyHandler` 체크포인트 → 공개
`AttributeKey(name)`+점유 체크 → **비공개 `GetKey`(그룹 값 객체별·이름별
메모이즈) + 이름 claim**) — 경위와 근거는 위 "이름 소유권" 절.

**그룹의 `process`** — 다른 모든 핸들러와 똑같은 4-인자 계약
`process(inst, k, v, index)`를 따름(`k`는 이 그룹 값이 놓인 array-part
위치, `index`는 그 `(inst,k)` 체인 안에서의 재귀 깊이 — **둘은 완전히
다른 것이라 헷갈리지 말 것**. 2026-08-13 감사 전까지 이 자리 시그니처가
`process(inst, index, v)` 3-인자로 적혀 있었고 배열 위치를 하필 `index`로
부르고 있어서, 코퍼스에서 유일하게 계약과 안 맞는 핸들러였음). 반환하는
클로저가 "이 호출이 등록한 키 목록"을 직접 캡처:

```lua
function AttributeGroupHandler.process(inst, k, v, index)
    local keys = {}
    for name, source in pairs(v:NameMap()) do  -- isHandlable이 이미 isAttribute(v)를 보장
        -- 그룹 전용 키(비공개) — 공개 AttributeKey(name)이 아님.
        -- 같은 그룹 값 객체 + 같은 이름이면 항상 같은 키 객체가 나와야 함.
        local key = groupKey(v, name)
        Dispatch.process(inst, key, source, 1)   -- 다른 키로 위임이므로 항상 인덱스 1
        keys[key] = true
    end
    return function()
        -- 이 그룹이 등록했던 것 전부를 철거 — 생존/소멸 구분 없이 균일.
        -- 인자(새 값)를 안 봄: 생존 이름도 일단 철거하고 다음 process가 다시
        -- 등록하는 순서라(Dispatch가 retractor → process 순서를 보장),
        -- "다음 값에 이 이름이 있나"를 미리 알 필요가 없음.
        for key in pairs(keys) do
            Dispatch.retractFrom(inst, key, 1)
        end
    end
end
```

- **[부분 실패 경로, 2026-08-14 리뷰에서 명시화] 순회 도중 소유권 충돌
  error가 나면, 그 전에 이미 등록된 이름들은 이 사이클의 클로저가 만들어지지
  못해 즉시 회수되지 않는다.** `error`가 `process` 밖으로 전파되므로 `return
  function() ... end`에 도달하지 못하고, `Dispatch`는 성공한 반환값만
  저장하기 때문. 다만 **피해 범위는 그 인스턴스의 수명으로 한정됨**:
  (1) `nameClaims`/`chains`는 `Relate`라 `inst`에 대해 weak — 그 인스턴스가
  GC되면 잔여 claim도 같이 사라짐, (2) 같은 자리가 다시 프로세스되면
  `Dispatch`가 남겨둔 마커 슬롯 덕분에 (A) 분기를 타고, 이미 claim된 이름은
  `cur == k`라 **에러 없이 그대로 통과**해 같은 자리에서 같은 error로 다시
  멈춤 — 조용한 오작동이 아니라 **반복 재현되는 시끄러운 실패**. 그래서
  별도 롤백 장치를 넣지 않음(코퍼스의 "에러=패닉 상태, 그 이후 정합성은
  관리 대상 아님" 원칙과 같은 결). 원자적 롤백이 필요하다고 판단되면
  그때 그룹 `process`에만 국소적으로 넣을 수 있음 — `question.md` 3번에
  열어둠.
- **`groupKey(v, name)`는 그룹 값 객체별·이름별 메모이즈** — 같은 그룹
  값이 재프로세스될 때 같은 키가 나와야 claim이 자기 자신과 안 부딪힘.
  구현은 `Relate<그룹 값 → {[name] = key}>` 하나면 충분하고, **공개
  API로 노출하지 않음**(위 "이름 소유권" 절). 그룹 값 객체 자체가 바뀌면
  (`State<Attribute>`가 새 객체를 emit) 새 키가 나오는데, 그때는 옛
  클로저가 먼저 전부 철거하므로 claim 충돌이 없음.
- **생존 이름도 매 사이클 철거→재등록됨(의도된 트레이드오프)** — 비용은
  그 이름의 `StoreBind` 구독 해제+재구독, 그리고 재구독의 "등록 즉시 1회
  실행"이 같은 값으로 `setAttribute`를 한 번 더 쏘는 것뿐. 이 문서가 이미
  "값 비교(`:Get()`으로 old/new 비교)는 안 함"을 확정해뒀으므로(아래 항목)
  결이 같고, `setAttribute`는 같은 값 재기록이 관측상 무해함. **체인이
  그룹 전용이 된 지금은 이론상 "생존 이름은 그냥 다시 `Dispatch.process`만
  불러 하강 diff에 맡기는" 최적화도 가능하지만**(다른 소유자를 건드릴
  위험이 없어졌으므로), 그러려면 옛 이름 집합을 `(inst,위치)`별로 또
  들고 있어야 해서 부품이 늘어남 — **기본은 균일 철거 유지**, 최적화는
  실제로 비용이 문제될 때 재검토.
- **그룹이 이름을 아예 놓는 경우도 같은 코드로 자연히 처리됨** — 클로저가
  자기 키 전부를 걷어내고, 새 `process`가 새 이름 집합만 등록하므로 사라진
  이름은 그냥 재등록이 안 될 뿐. 별도 diff 분기가 없음.
- **값 비교(`:Get()`으로 old/new 비교)는 안 함** — State
  계약("값은 항상 선언된 Compute 재실행 결과, 캐시 비교 금지",
  `store-semantics.md` "하드 경계" 절)과 어긋나고, `source`가
  `State`/`Source`면 `Dispatch/StoreBind`가 알아서 언랩+구독까지 다
  해줌(그룹 Handler가 따로 구독 관리 안 함)이라 굳이 비교할 이유가 없음.
- **[확정, 2026-08-12 세션 후속, 사용자 결정] 클로저는 `setAttribute`를
  절대 안 부름 — Attribute는 오직 명시적 `None`/`nil`로만 지워진다.**
  그룹에서 이름이 조용히 빠지든, 그룹 바인딩 자체가 통째로 사라지든
  (컴포넌트 언마운트 등) 프레임워크가 자동으로 `setAttribute(inst,name,nil)`을
  대신 불러주지 않음 — 값이 이전 것 그대로 남는 게 정상 동작. `Ref`가
  Destroy와 무관하게 동작하는 것과 같은 철학("지울 거면 명시적으로 지우라",
  `ref-plan.md`의 "`Ref`의 retract" 절)으로 통일. **이전 초안은
  "Tag와 동일하게 확실히 청소"였으나 뒤집힘** — 이유: (1) diff로
  조용히 빠지는 이름은 안 지워주면서 통째 소멸일 땐 지워주면, 두 경우가
  서로 다른 규칙이 되어 오히려 모호해짐(사용자 지적: "diff 쌓인 거랑
  전부 지운 거랑 완전 달라짐"). (2) Attribute 이름은 이미 "겹치면
  error"로 소유 코드가 명확히 갈리는 설계(위 "이름 소유권" 절)라, 그
  이름을 만든 코드가 알아서 지우는 게 맞지 프레임워크가 대신 판단할
  이유가 불투명함. (3) 정말 자동 청소가 필요하면 `Animate`와 같은 모양
  (`State<data> -> State<Attribute>`를 만드는 `:Apply` 팩토리, 이전
  그룹과 비교해 사라진 이름을 `None`으로 명시적으로 채워 넣는 유틸)을
  나중에 opt-in으로 추가하면 됨 — 그건 사용자가 고른 명시적 선택이라
  모호하지 않음, 지금은 범위 밖(백로그).
- **다만 *구독*은 반드시 끊음 — 값은 안 지워도 자원은 새면 안 됨.**
  그룹이 더 이상 관리하지 않는 이름의 체인을 그대로 두면 그 키에 걸려있던
  `StoreBind` 구독이 인스턴스가 살아있는 동안 영원히 남아 원본 `Source`가
  바뀔 때마다 계속 `setAttribute`를 쏘는 실제 리소스 누수가 됨(이건
  "마지막 값이 남는다"는 것과 다른 문제 — 안 죽는 구독 자체가 문제).
  그래서 반환하는 클로저는 자기가 등록했던 키 전부에 대해
  `Dispatch.retractFrom(inst, key, 1)`을 부름 — **`Dispatch.process`는
  절대 안 부르므로**(이 클로저 안에서 새 등록을 트리거하는 건 체인 추적을
  꼬는 UB, `dispatch-core-plan.md` 일반 규칙) 그 키 아래가 전부 자기
  자신의 클로저만 타고 끝나 `setAttribute`는 여기서도 절대 안 일어남 —
  위 "명시적 None으로만 지운다" 원칙과 안 부딪힘.
- **필드 하나만 바뀌는 흔한 경우**(`storeA.foo:Set(v)`, 그룹 자체는
  안 바뀜)는 위 그룹 재처리를 아예 거치지 않음 — 마운트 시 이미 걸린
  단일 키 `AttributeKeyHandler`의 store-bind 구독이 바로
  `setAttribute(inst,"foo",v)`를 호출(그룹 재진입 없이 그 경로 스스로).
  **`AttributeChanged`/`GetAttributeChangedSignal` 남발 걱정 없음** —
  키 집합이 안 바뀌는 한 그룹 로직 자체가 안 돎.

**그룹 Handler에 남는 자기 로직은 사실상 "이름 집합을 순회하며 자기 전용
키로 위임하고, 클로저가 같은 키들을 걷어내는 것"뿐** — 실제
`setAttribute` 호출/`None` 처리/store-bind 구독/이름 claim은 전부 단일 키
경로가 담당. `TagHandler`가 `addTag`/`removeTag`를 직접 호출하는 것과
달리 여기서는 그 실행 자체를 위임한다는 점이 다름(Attribute만 "이미
완성된 재사용 가능한 단일 키 경로"가 있어서 가능한 차이 — Tag는 애초에
이름 하나짜리 단일 키 대응물이 없음).

### `Attribute.Merged`가 레이어드 Store 기각과 안 부딪히나 — 점검, 안 부딪힘

`archive/context-rejected.md`가 기각한 "레이어드 Store"는 **읽는 시점에
부모 체인을 암묵적으로 거슬러 올라가는 자동 폴백**(`__index` 체인, "이
값이 왜 이거지"를 추적하려면 부모 체인을 다 훑어야 하는 디버깅 불투명성)이
문제였음. `Attribute.Merged`는:

- **작성 시점에 명시적으로 한 번** 여러 Store의 `Source` 참조를 평탄한
  자기 맵으로 모으는 것 — 런타임 암묵 폴백 체인이 없음(읽을 때 부모를
  거슬러 올라가지 않음, 그냥 자기 맵을 봄).
- 범용 값 컨테이너의 레이어링이 아니라, `Modifier`의 `Overridden`("이미
  계산된 걸 합침")과 같은 **목적성 있는 값 객체의 조립** — dispatch에
  참여하기 위해 만들어진 전용 값 객체지, "아무 값이나 담는 컨테이너"가
  레이어링되는 게 아님.

기각 사유(범용 컨테이너의 암묵적 런타임 폴백)가 이 케이스엔 적용 안 됨 —
새 primitive 추가에 문제없음.

### 패키지 배치 — 값 타입도 알고리즘도 quad-base, 주입되는 건 `setAttribute` 하나 (2026-08-13 열네 번째 세션 전면 재배치)

**[전면 재배치, 2026-08-13 열네 번째 세션, 사용자 판단]** 예전엔 값
타입/API만 quad-base이고 **단일 키 `AttributeKey`와 두 Handler는 통째로
quad-roblox** 소속이었음 — 그런데 실제로 엔진에 종속된 건 마지막 한 줄
(`inst:SetAttribute`)뿐이고, 이름 claim·그룹 위임·`None` 처리·이름별 weak
캐시는 전부 순수 부기임. 웹에도 대응물이 있으므로(`data-*`) 그 배치대로면
**같은 소유권 알고리즘을 백엔드마다 재구현**하게 됨 — `architecture.md`의
"엔진마다 큰 구현을 중복하지 않기 위해 디스패치 엔진을 base가 인터페이스로
소유한다"는 원칙에 정면으로 어긋남.

**확정된 배치**:

| 무엇 | 어디 |
|---|---|
| 그룹 값 타입+API(`Attribute(...)`/`Merged`/`:NameMap`) | quad-base |
| 단일 키 `AttributeKey<<T>>(name)` + 이름별 weak 캐시 | quad-base |
| 스칼라 편의 패밀리(`StringAttribute`/`NumberAttribute`/`BooleanAttribute`) | quad-base |
| `AttributeKeyHandler`(이름 claim 포함) / `AttributeGroupHandler`(전용 키 위임) | quad-base, `HANDLER_PRIORITY_FALLBACK`으로 등록 |
| 엔진 고유 타입 패밀리(`Color3Attribute`/`UDim2Attribute`/`InstanceAttribute`류) | 백엔드(quad-roblox의 `D`/`DI` 층) |
| **`setAttribute(inst, name, v)`** — `v == nil`이면 그 이름을 지움 | 백엔드가 주입 |

- **왜 타입 패밀리만 갈리는가**: Roblox attribute가 받는 타입 집합
  (`Color3`/`UDim2`/`CFrame`/`Instance` 등)은 엔진 고유 어휘라 base가 알
  수 없음. 반대로 string/number/boolean은 어느 백엔드에나 있으므로 base에
  둔다. "이 값이 이 백엔드에서 표현 가능한가"라는 **검증도 base가 아니라
  주입된 `setAttribute`의 몫** — base는 값을 그대로 흘려보냄.
- **백엔드가 통째로 다르게 하고 싶으면** 평범한 우선순위로 자기 핸들러를
  등록하면 됨(base 것은 최하위 밴드라 자동으로 짐) — 상세는
  `base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진
  op" 절. `Tag`도 정확히 같은 구조(`base/tag-plan.md`).
- 단일 키를 별도 opt-out 패키지로 쪼개지 않는다는 기존 판단은 그대로
  (UICorner 숏핸드/Tween/Tag와 같은 결) — 다만 "어느 패키지의 코어인가"가
  quad-roblox에서 quad-base로 바뀐 것.

## 열린 질문 (`.claude/question.md`에도 취합)

- **[해소, 2026-08-13 열네 번째 세션] 이름 소유권(`question.md` 0-Z)과
  하강 diff 재디스패치(0-A)는 확정·반영 완료** — 위 "이름 소유권"/
  "메커니즘" 절이 정본, 뒤집힌 옛 모델은
  `archive/dispatch-hintvalue-model-reversed.md`.
- **[열림, 사소함, 2026-08-13 열네 번째 세션 신설] `Attribute.Merged`에서
  두 Store가 같은 이름을 가지면 지금은 조용히 하나가 이김** —
  `:NameMap()` 평탄화가 dispatch 이전 단계라 위 이름 claim이 못 잡는
  자리. 이름 겹침을 error로 잡는 게 이 문서의 다른 결정들과 결이 같고
  구현도 싸지만(합성 시점 1회 체크), "Merged는 뒤가 이긴다"를 의도된
  override로 볼 여지도 있어서 사용자 확인 대기 — `question.md` 3번.
- **이름은 잠정 확정, 최종 확정은 대기열**: 겹침 방지를 위해 그룹 값은
  `Attribute`, 단일 키는 `AttributeKey<<T>>`로 코드/문서 전체 통일해서
  당장의 해석 모호성은 없앴음 — 그래도 최종 이름은 다른 가칭들(`DI`→`D`/
  `Slot`/`canExecute`/`Brand`)과 함께 `.claude/question.md` 용어정리
  대기열에 있음, 나중에 한꺼번에 재검토.
- **[백로그, 2026-08-12 세션 후속]** 그룹이 이름을 조용히 놓아도
  `setAttribute(inst,name,nil)`을 자동으로 안 해준다는 위 "그룹 `Attribute(...)`"
  절의 결정 — 그래도 명시적 자동 unset이 갖고 싶으면 `Animate`와 같은
  모양의 `:Apply` opt-in 유틸(이전 이름 집합과 비교해 사라진 이름을
  `None`으로 채워주는 콤비네이터)을 나중에 추가할 수 있음, 착수 안 함 —
  `research/operator-sugar-plan.md` "Attribute 그룹 명시적 unset 유틸"
  절 참고.
