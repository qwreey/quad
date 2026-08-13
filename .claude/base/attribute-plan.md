# Attribute — 단일 키(`AttributeKey`)와 그룹(`Attribute(...)`) 두 프리미티브

> **⚠️ [2026-08-13 여섯 번째 세션] 이 문서의 `hintValue`/`retractFrom` 선행
> 호출 서술은 곧 교체될 예정 — 아직 반영 안 됨.** 힌트가 `None` 센티널이나
> `State`/`Tween` 래퍼로 오염돼 말단 핸들러의 `isX(hint)` 가드를 거짓으로
> 만들고 깜빡임/재생성 방지를 조용히 끄는 결함이 확인됐고, 대체 모델
> (**래핑 핸들러의 `retractFrom` 선행 호출 폐기 + `Dispatch.process`가
> 핸들러를 먼저 비교**)까지 거의 확정됐음 — 다만 `question.md` **0-Z**
> (Attribute 이름 소유권) 하나가 남아 아직 옮기지 않음. **여기 적힌 대로
> 구현하면 옛 모델로 짜게 됨** — 반드시
> `research/dispatch-redispatch-diff-plan.md`를 먼저 읽을 것.

**상태**: base — 단일 키 메커니즘/`None`/`retract` 동작과 타입 파라미터화는
전부 확정(2026-08-09 열한 번째 세션, **2026-08-12 세션 후속에서
`retract` 완전 no-op화 + 그룹 청소 정책 전면 재정정 — 아래 "메커니즘"/
"그룹 `Attribute(...)`" 절이 최신**). **[2026-08-13 세션, 하루 안에서
두 차례 재설계]** 그룹/직접 쓰기 이름 충돌 방지 방식이 `rawNew`+`owners`
수동 레지스트리 → `AttributeGroupKeyHandler` 체크포인트(`Dispatch.
processAs`/`retractSelfAndUnder`) → **최종적으로 `Dispatch` 자체의
인덱스 기반 재설계(`base/bind-system-plan.md` "Dispatch 체인" 절)에
올라타 체크포인트도 필요 없어짐**(공개 `AttributeKey(name)`으로 항상
인덱스 1에 직접 위임, 점유 체크가 소유권 충돌 감지를 대신함) — 아래
"이름 소유권"/"메커니즘" 절이 최신, 중간 버전은 `archive/
checkpoint-handler-pattern-reversed.md`에 보존. **[2026-08-11 아홉 번째 세션 추가]**
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

- `process(inst, k, v, index)` — `inst:SetAttribute(name, v)`가 사실상
  전부, **`v`가 뭐든(실제 값이든 `nil`이든) 무조건 그대로 호출** — 일반
  프로퍼티 핸들러와 완전히 동일한 무조건 set. **Attribute는 `None`의
  가장 깔끔한 사례** — Roblox API 자체가 `SetAttribute(name, nil)`을
  "그 Attribute 엔트리를 지운다"는 뜻으로 네이티브 지원하므로, `None →
  nil` 재디스패치(`base/bind-system-plan.md`의 `None` 센티널 절)가
  도착했을 때 handler가 **아무 특별 처리도 없이** `inst:SetAttribute(name,
  nil)`을 그대로 호출하면 끝 — UICorner 숏핸드처럼 "만들어둔 자식을
  수동으로 찾아 지우는" 로직조차 필요 없음.
- **반환하는 클로저는 완전 no-op — [재정정, 2026-08-12 세션 후속] "매번
  불리지만 대부분 no-op"이라던 직전 서술도 틀렸음, "대부분"이 아니라
  "항상"** — 일반 프로퍼티 핸들러(반환 클로저가 완전 무조건 no-op,
  `bind-system-plan.md` "일반 프로퍼티는 애초에 'unset' 개념이 없음")와
  완전히 같은 성격으로 재정정. **`AttributeKeyHandler`가 반환하는
  클로저는 `SetAttribute`를 절대 호출하지 않음** — attribute를 지우는
  유일한 경로는 `process(inst,k,nil,index)`(`None`이든, State가 스스로
  `nil`로 바뀌든) 뿐. 이전 버전("이름이 사라질 때(`v==nil`)만 retract가
  `SetAttribute(name,nil)`을 호출")은 두 가지 문제가 있었음 — (1)
  이 클로저 안에 관측 가능한 부작용이 생겨 `bind-system-plan.md`의
  "이 클로저는 구조적 팝만, process 트리거 금지" 일반 규칙과 어긋나는
  성격의 코드가 됨, (2) 그룹이 survivor 이름에 재위임할 때 그 시점에
  `SetAttribute`가 잘못 끼어들 수 있는 경로가 생겨 `a→nil→b` 깜빡임
  위험(사용자 지적) — 클로저가 완전 no-op이면 이 경로 자체가 물리적으로
  없어짐.
- store-bind 가능(일반 프로퍼티와 동일하게 취급, `Store<T>`/`State<T>`
  값도 받음).

### 이름 소유권 — 그룹/직접 쓰기 충돌 방지 (2026-08-12 열 번째 세션, 2026-08-13 다섯 번째 세션 전면 재정정)

**문제**: `AttributeKey(name)`이 이름별 weak 캐시로 항상 같은 객체를
리턴하고, 그룹 `Attribute(...)`가 그 경로를 그대로 재사용(아래 "메커니즘"
절)하다 보니, **서로 다른 원래 위치(해시파트 직접 쓰기 `[AttributeKey
"name"]=value` vs 배열파트 `Attribute(store)`, 또는 서로 다른 두
`Attribute(...)` 그룹)가 같은 이름을 동시에 관리하려 하면 정확히 같은
`(inst, k=AttributeKey(name))` 자리로 수렴해 조용히 마지막 쓰기가
이기는 충돌이 생김.** Modifier 필드는 정적이라 override로 이미 해소되지만
(같은 해시 키는 한 Modifier 안에 하나뿐), 그룹의 이름 집합은 런타임에
동적이라 이 해소망 밖에 있음.

**[역사, 2026-08-13 세션 안에서 두 번 뒤집힘]** 첫 버전(`rawNew`로 그룹
전용 키를 만들고 `owners` Relate로 이름별 소유권을 수동 추적)은 "그룹이
이름을 놓았다 나중에 같은 그룹이 그 이름을 다시 포함하면 자기 자신과
충돌"하는 실제 버그가 있었음(소유권 반납이 `process`의 `v==nil` 분기에만
있어서, 그룹이 이름을 통째로 놓는 경로는 그 분기를 안 타서 옛 소유권
기록이 안 지워짐). 두 번째 버전(`AttributeGroupKeyHandler`라는 스캔
불가 체크포인트 핸들러를 `Dispatch.processAs`로 명시 push, 소유권 충돌을
Dispatch의 재진입 가드에 얹어 감지)은 이 버그를 고치긴 했으나, 같은 날
다섯 번째 세션에 `Dispatch` 자체가 `chains`를 핸들러 identity가 아니라
**인덱스**로 추적하도록 재설계되며(`base/bind-system-plan.md` "Dispatch
체인" 절) 체크포인트가 하던 일 자체가 통째로 불필요해짐 — 원문·역전
이유는 `archive/checkpoint-handler-pattern-reversed.md`.

**최종(세 번째 버전) — 체크포인트도 `owners`도 없이, 항상 인덱스 1부터
직접 위임.** **[캐비엇, 2026-08-13 여섯 번째 세션] 여기서 "최종"은 *현행
`hintValue` 모델 기준*이고, 이 주제 자체가 `question.md` **0-Z**로 다시
열려 있음** — 문서 상단 ⚠️ 배너가 예고하는 "하강 diff" 재디스패치 모델에선
그룹 A/B가 둘 다 `StoreBind`로 보여 "같은 핸들러"로 판정되므로 **아래 점유
체크만으로는 그룹↔그룹 충돌을 못 잡음**(`research/dispatch-redispatch-diff-plan.md`
5절). 0-Z가 정해지면 이 절이 네 번째 버전으로 다시 갱신됨. 그룹이 이름마다 공개 `AttributeKey(name)`으로 그냥
`Dispatch.process(inst, key, source, 1)`를 부르면 끝 — **"인덱스 1이 이미
점유돼 있는가"라는 `Dispatch.process` 자신의 점유 체크가 소유권 충돌
감지를 그대로 대신함**: 다른 그룹이나 직접 쓰기가 이미 그 이름을
점유했다면, 이 호출은(체크포인트를 거칠 필요도 없이) 곧바로 "이미
점유됨" error를 냄. `AttributeKeyHandler`도 다시 완전 무상태로 되돌아감:

```lua
-- AttributeKeyHandler(quad-roblox) — 완전 무상태, 소유권 추적 없음
function AttributeKeyHandler.process(inst, k, v, index)
    inst:SetAttribute(k.Name, v)  -- v가 nil이든 아니든 무조건 — 일반 프로퍼티와 완전히 동일
    return function() end        -- 지울 게 없음 — SetAttribute는 오직 process(inst,k,nil)로만
end
```

- **직접 리터럴 쓰기**(`[AttributeKey<<T>> "name"] = value`)는 공개
  `AttributeKey(name)`을 그대로 씀, 정상 스캔으로 바로
  `AttributeKeyHandler`에 도달(인덱스 1) — 한 Modifier 안에 같은 해시
  키가 중복될 수 없어 이 경로 자체의 claimant는 항상 유일. 그룹이
  이미 그 이름의 인덱스 1을 점유 중이면, 이 직접 쓰기의
  `Dispatch.process(inst,key,value,1)`가 그 자리에서 곧바로 점유 error —
  그룹↔직접 쓰기 충돌도 같은 점유 체크 하나로 잡힘.
- **그룹**은 아래 "메커니즘" 절에서 이름마다 `Dispatch.process`만으로
  위임하고(철거는 반환 클로저가 전담) — 전용 키 객체도, 소유권 레지스트리도
  필요 없음(항상 공개 `AttributeKey(name)`, 항상 인덱스 1). **`process`가
  위임 직전에 `retractFrom`을 부르면 안 된다는 게 이 절이 성립하는
  전제** — 그러면 점유 여부와 무관하게 인덱스 1이 비워져 아래 점유
  체크가 무력화됨(2026-08-13 감사에서 실제 그렇게 적혀 있던 걸 정정,
  "메커니즘" 절 참고).
- **패키지 경계**: `AttributeKey`는 이미 quad-roblox 소속(Tag와 달리
  base/roblox로 안 쪼갬, 아래 "패키지 배치" 절) — base쪽
  `Attribute(...)` 값 객체 자신은 이 메커니즘을 전혀 모름.

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

### 메커니즘 — 항상 인덱스 1부터 기존 단일 키 경로에 직접 위임

**[2026-08-11 아홉 번째 세션 후속, 개정]** 최초안은 "자기 완결형 Handler,
Dispatch 재진입 없이 직접 `SetAttribute`+수동 per-field StoreBind 구독"
이었으나, 위 "동등성" 절의 이름별 weak 캐시가 확정되며 그 회피 이유
자체가 없어짐 — 그래서 그룹 Handler는 **자기만의 SetAttribute/구독 로직을
새로 만들지 않고, 각 필드를 기존 단일 키 `AttributeKey` 경로에 그대로
재귀 위임** — `None`/store-bind 전부 이미 확정된 단일 키 메커니즘을
100% 재사용, 중복 구현 없음. **[전면 재정정, 2026-08-13 다섯 번째 세션]
`rawNew(name)` 그룹 전용 키 → `AttributeGroupKeyHandler` 체크포인트로
두 번 거쳐온 위임 메커니즘이, `Dispatch`의 인덱스 기반 재설계로 다시
한번 단순화됨 — 이제 그냥 공개 `AttributeKey(name)`으로 인덱스 1에
직접 위임**(경위는 위 "이름 소유권" 절, 원문은 `archive/
checkpoint-handler-pattern-reversed.md`):

**그룹의 `process`** — 다른 모든 핸들러와 똑같은 4-인자 계약
`process(inst, k, v, index)`를 따름(`k`는 이 그룹 값이 놓인 array-part
위치, `index`는 그 `(inst,k)` 체인 안에서의 재귀 깊이 — **둘은 완전히
다른 것이라 헷갈리지 말 것**. 2026-08-13 감사 전까지 이 자리 시그니처가
`process(inst, index, v)` 3-인자로 적혀 있었고 배열 위치를 하필 `index`로
부르고 있어서, 코퍼스에서 유일하게 계약과 안 맞는 핸들러였음). 반환하는
클로저가 "이 호출이 등록한 이름 집합"을 직접 캡처 — **별도 `Relate`
불필요**(2026-08-13 다섯 번째 세션, 클로저가 매 호출마다 자기 자신의
이름 집합을 새로 만들어 캡처하므로 사이클을 가로질러 저장해둘 이유가
없어짐):

**[정정, 2026-08-13 감사] `process`는 `retractFrom`을 부르지 않는다 —
철거는 전적으로 반환 클로저 몫.** 최초 작성본은 `process` 안에서 이름마다
`Dispatch.retractFrom(inst, key, 1, source)`를 먼저 부른 뒤 `process`를
불렀는데, 이러면 **인덱스 1을 누가 점유했든 무조건 비워버리므로 뒤따르는
`Dispatch.process`가 점유 error를 낼 수가 없음** — 위 "이름 소유권" 절이
이 재설계의 핵심 근거로 내세운 "점유 체크가 소유권 충돌 감지를 그대로
대신함"이 그룹↔그룹 사이에서 전혀 작동하지 않았음(그룹 B가 그룹 A의
바인딩을 조용히 파괴하고 이김 — 이 절이 없앴다고 선언한 바로 그
last-write-wins). 클로저가 자기가 등록한 이름 전부를 책임지고 걷어내면
`process`는 순수하게 `Dispatch.process`만 부르면 되고, 점유 체크가 다시
살아남:

```lua
function AttributeGroupHandler.process(inst, k, v, index)
    local names = {}
    for name, source in pairs(v:NameMap()) do  -- isHandlable이 이미 isAttribute(v)를 보장
        -- 공개 캐시 키 그대로(그룹 전용 키 불필요), 항상 인덱스 1부터 위임 —
        -- 이미 다른 그룹/직접 쓰기가 그 이름을 점유 중이면 여기서 즉시 점유 error
        Dispatch.process(inst, AttributeKey(name), source, 1)
        names[name] = true
    end
    return function()
        -- 이 그룹이 등록했던 이름 전부를 철거 — 생존/소멸 구분 없이 균일.
        -- hintValue를 안 봄: 생존 이름도 일단 철거하고 다음 process가 다시
        -- 등록하는 순서라(StoreBind가 retractFrom → process 순서를 보장),
        -- "다음 값에 이 이름이 있나"를 미리 알 필요가 없음.
        for name in pairs(names) do
            Dispatch.retractFrom(inst, AttributeKey(name), 1, nil)  -- SetAttribute는 안 일어남(아래 원칙)
        end
    end
end
```

- **생존 이름도 매 사이클 철거→재등록됨(의도된 트레이드오프)** — 비용은
  그 이름의 `StoreBind` 구독 해제+재구독, 그리고 재구독의 "등록 즉시 1회
  실행"이 같은 값으로 `SetAttribute`를 한 번 더 쏘는 것뿐. 이 문서가 이미
  "값 비교(`:Get()`으로 old/new 비교)는 안 함"을 확정해뒀으므로(아래 항목)
  결이 같고, `SetAttribute`는 같은 값 재기록이 관측상 무해함. **`Tag`식
  `hintValue == v` 조기 반환을 여기에 넣으면 안 됨** — 클로저가 아무것도
  안 걷어낸 상태로 다음 `process`가 같은 이름에 다시 인덱스 1을 잡으려
  들어 자기 자신에게 점유 error를 냄.
- **그룹이 이름을 아예 놓는 경우도 같은 코드로 자연히 처리됨** — 클로저가
  `names` 전부를 걷어내고, 새 `process`가 새 이름 집합만 등록하므로 사라진
  이름은 그냥 재등록이 안 될 뿐. 별도 diff 분기가 없어짐(이전 버전이
  `newNames`를 계산하던 로직 자체가 불필요).
- **값 비교(`:Get()`으로 old/new 비교)는 안 함** — State
  계약("값은 항상 선언된 Compute 재실행 결과, 캐시 비교 금지",
  `store-semantics.md` "하드 경계" 절)과 어긋나고, `source`가
  `State`/`Source`면 `Dispatch/StoreBind`가 알아서 언랩+구독까지 다
  해줌(그룹 Handler가 따로 구독 관리 안 함)이라 굳이 비교할 이유가 없음.
- **[확정, 2026-08-12 세션 후속, 사용자 결정] `retract`는 `SetAttribute`를
  절대 안 부름 — Attribute는 오직 명시적 `None`/`nil`로만 지워진다.**
  그룹에서 이름이 조용히 빠지든(diff로 사라짐), 그룹 바인딩 자체가
  통째로 사라지든(컴포넌트 언마운트 등, `v`가 더 이상 Attribute가 아님)
  프레임워크가 자동으로 `SetAttribute(name,nil)`을 대신 불러주지
  않음 — 값이 이전 것 그대로 남는 게 정상 동작. `Ref`가 Destroy와
  무관하게 동작하는 것과 같은 철학("지울 거면 명시적으로 지우라",
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
- **다만 *구독*은 반드시 끊음 — 값은 안 지워도 자원은 새면
  안 됨.** 위 "값은 안 지운다" 원칙과 별개로, 그룹이 더 이상 관리하지
  않는 이름의 `(inst,key)` 체인을 그대로 두면 그 키에 걸려있던
  `StoreBind` 구독이 인스턴스가 살아있는 동안 영원히 남아 원본
  `Source`가 바뀔 때마다 계속 `SetAttribute`를 쏘는 실제 리소스 누수가
  됨(이건 "마지막 값이 남는다"는 것과 다른 문제 — 안 죽는 구독 자체가
  문제). 그래서 반환하는 클로저는 **자기가 등록했던 이름 전부**에 대해
  `Dispatch.retractFrom(inst, AttributeKey(name), 1, nil)`을 부름
  (**[정정, 2026-08-13 감사]** 원래는 "사라진 이름에 한해"였으나, 그
  선별을 하려면 `process` 쪽이 생존 이름을 `retractFrom`으로 강제
  회수해야 해서 점유 체크가 무력화됐음 — 위 "메커니즘" 절 참고. 전부
  걷어내고 새 `process`가 다시 등록하는 쪽이 점유 체크를 살리면서
  코드도 더 단순함) —
  **`Dispatch.process`는 절대 안 부르므로**(이 클로저 안에서 새 등록을
  트리거하는 건 체인 추적을 꼬는 UB, `bind-system-plan.md` 일반 규칙)
  그 이름 아래가 전부 자기 자신의 클로저만 타고 끝나 `SetAttribute`는
  여기서도 절대 안 일어남 — 위 "명시적 None으로만 지운다" 원칙과 안
  부딪힘.
- **필드 하나만 바뀌는 흔한 경우**(`storeA.foo:Set(v)`, 그룹 자체는
  안 바뀜)는 위 그룹 재처리를 아예 거치지 않음 — 마운트 시 이미 걸린
  단일 키 `AttributeKeyHandler`의 store-bind 구독이 바로
  `SetAttribute("foo", v)`를 호출(그룹 재진입 없이 그 경로 스스로).
  **`AttributeChanged`/`GetAttributeChangedSignal` 남발 걱정 없음** —
  키 집합이 안 바뀌는 한 diff 로직 자체가 안 돎.

**그룹 Handler에 남는 자기 로직은 사실상 "이름 집합을 순회하며 위임하고,
클로저가 같은 집합을 걷어내는 것"뿐**(**[정정, 2026-08-13 감사]** 예전엔
"이름 집합 diff"라고 적었으나, 위 재정정으로 diff 자체가 없어짐 —
`process`는 새 집합을 전부 등록, 클로저는 옛 집합을 전부 철거) — 실제
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

- **[2026-08-13 3차 감사에서 보강] `hintValue`/`retractFrom` 재-dispatch
  메커니즘은 `question.md` **0-Z**(이 문서 자신의 이름 소유권 결정)
  해소 대기 중** — 이 문서 최상단 배너와 "이름 소유권" 절에 이미
  명시돼 있지만, 이 목록에는 빠져 있어서 여기만 훑는 독자가 놓치기
  쉬움. `research/dispatch-redispatch-diff-plan.md` 먼저 읽을 것.
- **이름은 잠정 확정, 최종 확정은 대기열**: 겹침 방지를 위해 그룹 값은
  `Attribute`, 단일 키는 `AttributeKey<<T>>`로 코드/문서 전체 통일해서
  당장의 해석 모호성은 없앴음 — 그래도 최종 이름은 다른 가칭들(`State`/
  `DI`→`D`/`Slot`/`canExecute`/`Brand`)과 함께 `.claude/question.md` 용어정리
  대기열에 있음, 나중에 한꺼번에 재검토.
- **[백로그, 2026-08-12 세션 후속]** 그룹이 이름을 조용히 놓아도
  `SetAttribute(name,nil)`을 자동으로 안 해준다는 위 "그룹 `Attribute(...)`"
  절의 결정 — 그래도 명시적 자동 unset이 갖고 싶으면 `Animate`와 같은
  모양의 `:Apply` opt-in 유틸(이전 이름 집합과 비교해 사라진 이름을
  `None`으로 채워주는 콤비네이터)을 나중에 추가할 수 있음, 착수 안 함 —
  `research/operator-sugar-plan.md` "Attribute 그룹 명시적 unset 유틸"
  절 참고.
