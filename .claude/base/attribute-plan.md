# Attribute — 단일 키(`AttributeKey`)와 그룹(`Attribute(...)`) 두 프리미티브

**상태**: base — 단일 키 메커니즘/`None`/`retract` 동작과 타입 파라미터화는
전부 확정(2026-08-09 열한 번째 세션). **[2026-08-11 아홉 번째 세션 추가]**
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

### 메커니즘, `None`, `retract` — 전부 확정 (2026-08-07 여덟 번째 세션)

타입 파라미터화 이름과 무관하게 런타임 동작은 확정:

- `process(inst, k, v)` — `inst:SetAttribute(name, v)`가 사실상 전부.
  **Attribute는 `None`의 가장 깔끔한 사례** — Roblox API 자체가
  `SetAttribute(name, nil)`을 "그 Attribute 엔트리를 지운다"는 뜻으로
  네이티브 지원하므로, `None → nil` 재디스패치(`base/bind-system-plan.md`의
  `None` 센티널 절)가 도착했을 때 handler가 **아무 특별 처리도 없이**
  `inst:SetAttribute(name, nil)`을 그대로 호출하면 끝 — UICorner 숏핸드처럼
  "만들어둔 자식을 수동으로 찾아 지우는" 로직조차 필요 없음.
- **`retract` 불필요** — Tag와 같은 이유: 값이 뭐든(실제 값/`nil`) 항상
  같은 `AttributeKeyHandler`가 이 키를 계속 담당(핸들러 *타입*이 안 바뀜).
  `retract`가 의미 있는 유일한 패턴("매치되는 핸들러 타입 자체가 바뀜",
  `Tag(...)`↔`nil`이 실사례 — 2026-08-10 세션부터 Tween은 더 이상 이
  패턴의 예시가 아님, `base/tween-plan.md`)에 해당 안 함 —
  `bind-system-plan.md` "확정된 디스패치 모델" 절이 한때 Attribute도
  retract 필요 예시로 들었던 걸 여기서 바로잡음.
- store-bind 가능(일반 프로퍼티와 동일하게 취급, `Store<T>`/`State<T>`
  값도 받음).

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
Frame { Attribute(styleStore), Attribute(stateStore) }   -- 여러 개 나란히 둬도 각자 자기 키만 반영(Tag와 동일)
```

`Attribute.Merged`가 내부적으로 하는 일은 각 Store에서 이름 붙은 `Source`
슬롯을 그대로 가져와 자기 자신의 key→Source 맵에 넣는 것 — 아래 "레이어드
Store 기각과 안 부딪히나" 참고.

### 메커니즘 — 메모이즈된 키로 기존 단일 키 경로에 재귀 위임

**[2026-08-11 아홉 번째 세션 후속, 개정]** 최초안은 "자기 완결형 Handler,
Dispatch 재진입 없이 직접 `SetAttribute`+수동 per-field StoreBind 구독"
이었으나, 위 "동등성" 절의 이름별 weak 캐시가 확정되며 그 회피 이유
자체가 없어짐 — `AttributeKey(name)`을 몇 번을 다시 불러도 항상 같은
객체가 나오므로, Dispatch의 `(inst, k)`별 핸들러 체인 추적이 깨질
위험이 없음. 그래서 그룹 Handler는 **자기만의 SetAttribute/구독 로직을
새로 만들지 않고, 각 필드를 기존 단일 키 `AttributeKey` 경로에 그대로
재귀 위임** — `None`/`retract`/store-bind 전부 이미 확정된 단일 키
메커니즘을 100% 재사용, 중복 구현 없음:

- **그룹 값이 (재)할당될 때**(마운트 시점, 또는 `:Compute`가 그룹 값
  자체를 교체하는 드문 경우 — 흔한 필드 하나 변경과는 다른 경로, 아래
  참고): `(inst, index)`(array-part 위치, `Tag`의 `relate:GetStrong(inst,k)`와
  동일 키잉 — `k`는 배열 인덱스)로 찾은 릴레이션에 저장된 **"이전에 쓴
  attribute 이름 문자열 집합"**과 새 값의 키 집합을 diff:
  - 사라진 이름만 `Dispatch.retractUnder(inst, AttributeKey(name))` —
    메모이즈된 키라 그 이름이 살아있는 동안 만들어졌던 원래 체인과
    정확히 같은 슬롯을 가리켜 정리됨.
  - 남아있거나 새로 들어온 이름은 **값 비교 없이 전부**
    `Dispatch.process(inst, AttributeKey(name), source)`로 넘김 — 작성자가
    직접 `[AttributeKey<<T>> name] = source`를 쓴 것과 완전히 같은 경로를
    타므로, `source`가 `State`/`Source`면 `Dispatch/StoreBind`가 알아서
    언랩+구독까지 다 해줌(그룹 Handler가 따로 구독 관리 안 함).
  - **값 비교(`:Get()`으로 old/new 비교)는 하지 않음** — State 계약("값은
    항상 선언된 Compute 재실행 결과, 캐시 비교 금지", `store-semantics.md`
    "하드 경계" 절)과 어긋나고, 릴레이션 키를 문자열 이름 집합(존재 여부)만
    들고 있으면 충분해서 굳이 값까지 비교할 이유가 없음.
- **필드 하나만 바뀌는 흔한 경우**(`storeA.foo:Set(v)`, 그룹 자체는
  안 바뀜)는 위 그룹 재처리를 아예 거치지 않음 — 마운트 시 이미 걸린
  단일 키 `AttributeKeyHandler`의 store-bind 구독이 바로
  `SetAttribute("foo", v)`를 호출(그룹 재진입 없이 그 경로 스스로).
  **`AttributeChanged`/`GetAttributeChangedSignal` 남발 걱정 없음** —
  키 집합이 안 바뀌는 한 diff 로직 자체가 안 돎.
- **`retract`**: 자기가 쓴 키 전부 `Dispatch.retractUnder(inst,
  AttributeKey(name))`로 정리 — 단일 키의 `SetAttribute(name, nil)`이
  그대로 실행되므로 결과적으로 `Tag`와 동일하게 확실히 청소됨. Roblox는
  Instance 풀링/재사용이 흔해서, 이전 컴포넌트가 남긴 attribute가
  재사용된 Instance에 방치되면 selector/스타일시트 로직에 실제 버그가
  됨. ("소진돼도 부작용 없으니 방치해도 된다"는 초안은 기각 — Tag의
  확실한 청소 원칙과 통일.)

**그룹 Handler에 남는 자기 로직은 사실상 "이름 집합 diff"뿐** — 실제
`SetAttribute` 호출/`None` 처리/store-bind 구독은 전부 기존 단일 키
경로가 그대로 담당. `TagHandler`가 `CollectionService` 호출을 직접 하는
것과 달리, 여기서는 그 실행 자체를 위임한다는 점이 다름(Attribute만
"이미 완성된 재사용 가능한 단일 키 경로"가 있어서 가능한 차이 — Tag는
애초에 이름 하나짜리 단일 키 대응물이 없음).

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

### 패키지 배치 — Tag와 동일 원칙

값 타입+API(`Attribute(...)`/`Merged`)는 quad-base(엔진 무관, 순수 데이터+
연산). `SetAttribute` 실제 호출 글루만 quad-roblox.

## 패키지 배치 (단일 키 `AttributeKey`)

UICorner 숏핸드/Tween/Tag와 같은 판단 재사용 — `quad-roblox` 코어에 직접
포함, 별도 opt-out 패키지로 안 쪼갬.

## 열린 질문 (`.claude/question.md`에도 취합)

- **이름은 잠정 확정, 최종 확정은 대기열**: 겹침 방지를 위해 그룹 값은
  `Attribute`, 단일 키는 `AttributeKey<<T>>`로 코드/문서 전체 통일해서
  당장의 해석 모호성은 없앴음 — 그래도 최종 이름은 다른 가칭들(`State`/
  `DI`→`D`/`Slot`/`canExecute`/`Brand`)과 함께 `.claude/question.md` 용어정리
  대기열에 있음, 나중에 한꺼번에 재검토.
