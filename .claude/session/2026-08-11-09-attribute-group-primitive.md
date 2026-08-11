<!-- quad-v2 세션 로그 원문. -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 논의(시행착오 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-11 아홉 번째 세션 — 그룹 `Attribute(...)` 프리미티브 신설, 단일 키
`AttributeKey`로 리네임

사용자가 "attribute를 store로 설정 가능하게 두면 어떨까"라는 아이디어를
자유 서술 메모로 제기하며 시작. 이미 확정된 단일 키
`[Attribute<<T>> "name"] = value`(`base/attribute-plan.md`) 모델은 필드
하나하나를 개별 DI 키로 나열해야 해서, Store 전체를 한 번에 attribute로
투영하고 싶은 요구를 못 채움 — 사용자가 스스로 네 가지 형태
(`[Attribute] = Store{...}` 해시파트 단일슬롯 / `Attribute`를 Store
서브타입으로 / `Attribute(Store)` 프리미티브 / Slot처럼 제공)를 트레이드오프와
함께 나열하고 의견을 구함.

### 1라운드 — 형태 결정

- **`[Attribute] = Store {...}` 해시파트 단일슬롯 기각**: 인스턴스당
  슬롯이 하나뿐이라, 헤테로지니어스 Store 여러 개(스타일 Store + 상태
  Store 등)를 합칠 방법이 구조적으로 없음.
- **Attribute가 Store를 상속(IS-A) — 기각**: `Store<T>`의 `T`가 다시
  Attribute(=Store)일 수 있게 되어, 이미 확정된 "핸들러 계층 값은
  Source에 못 들어감"(`Store<T>`의 `T`는 Modifier 불가와 같은 이유) 제약과
  부딪히는 "Store 안에 Store"를 실제로 만들어냄.
- **채택 — `Tag`와 동형인 array-part 값 객체**: `Attribute(store1, store2,
  ..., {plain=1})` 생성자 + `Attribute.Merged(a,b,...)`. 여러 개를 그냥
  나란히 놔도(`Frame { Attribute(a), Attribute(b) }`) 각자 자기 키만
  반영하므로 헤테로지니어스 합성 문제가 `Tag`처럼 자연히 풀림.

### 2라운드 — 메커니즘: AttributeChanged 남발 방지, 자기 완결형 Handler

사용자가 직접 지적: `State<Attribute>`(그룹 값 자체가 `:Compute`로
스왑되는 경우)까지 오면, 재처리 때마다 전부 지웠다 다시 set하면
`GetAttributeChangedSignal` 남발. 해법으로 사용자가 `Tag`의 diff 패턴을
그대로 재사용하자고 제안 — `(inst, index)` 릴레이션에 이전 키 이름 집합을
저장해두고, 사라진 키만 지우고 남은/새 키는 값 비교 없이 그냥 다 set(값
비교까지 하려면 `:Get()`이 필요한데 그 부작용을 감수할 이유가 없다고
판단, "단순히 nil 했다 새 값으로 덮는다만 줄이기").

이어서 이게 "그룹 재처리"에서만 의미 있고, 필드 하나만 바뀌는 흔한
경우(그룹 자체는 안 바뀜)는 그 키 전용 구독이 직접 `SetAttribute` 호출로
끝나 이 diff 경로를 아예 안 거친다는 점을 정리(어시스턴트).

추가로 어시스턴트가 제안: 내부에서 단일 키 `AttributeKey<<T>>(name)` DI
키 객체를 재합성해서 Dispatch에 재진입시키면, 매 처리마다 새로 만들어지는
키 객체의 참조 동등성 때문에 Dispatch의 `(inst,k)`별 핸들러 체인 추적이
깨질 위험 — 그룹 핸들러는 `TagHandler`처럼 자기 완결형으로(직접
`SetAttribute` 호출 + `Dispatch/StoreBind`로 개별 필드 구독) 가는 게
낫다고 제안. 사용자 확인: "내부적으로 SetAttribute 실행 하나뿐이라 자기
완결이 아주 쉬움, 그걸 위해 모듈화 할 것도 없고" — 동의, 별도 재진입
경로 자체를 안 만드는 걸로 확정.

retract는 Tag와 동일하게 자기가 쓴 키 전부 `SetAttribute(name, nil)`로
정리하는 걸로 확정(어시스턴트 제안, "소진돼도 방치해도 부작용 없다"는
사용자의 최초 메모와는 다른 방향 — Roblox Instance 풀링/재사용 시 이전
값이 새는 게 실제 버그라는 근거로 제시, 사용자 동의: "5는 네 말이
맞아보여").

### 3라운드 — `Attribute.Merged`가 "레이어드 Store 기각"과 충돌 안 하는지

사용자가 스스로 짚음: `Attribute.Merged`가 여러 Store의 Source 슬롯을
가져와 자기 맵에 넣는 구조인데, 예전에 `Context` 대안으로 나왔던 "레이어드
Store"(`archive/context-rejected.md`)를 기각한 적이 있어서 이것도 같은
문제 아닌지. 사용자 자체 결론: "값을 넣기 위한 것이 레이어된다 보긴
애매하고, 목적성이 있는 객체의 레이어라서 문제는 안 보임" — 이건 `Modifier`의
`Overridden`과 유사한 사례라는 판단. 어시스턴트가 검증: 기각됐던 레이어드
Store는 **읽는 시점의 암묵적 부모 체인 자동 폴백**(디버깅 불투명성)이
문제였지, `Attribute.Merged`는 **작성 시점에 명시적으로 한 번** Source
참조를 평탄한 맵으로 모으는 것뿐이라 그 기각 사유(범용 컨테이너의 암묵
런타임 폴백)가 적용 안 됨 — 확인 완료.

### 4라운드 — 이름 충돌: 단일 키를 `AttributeKey`로 리네임

기존 단일 키 생성자 이름이 `Attribute<<T>>`였는데, 그룹 프리미티브도
`Attribute(...)`라는 같은 이름을 쓰면 "Store 받는 애인지 단일 키인지"
해석이 갈림. 사용자가 명시: "지금 그대로 두면 Attribute가 스토어 받는
애인지 단일키인지 해석 여지가 갈리니, 임시 네이밍으로 AttributeKey로
둬야할듯" — `OnChange`/`OnChangeKey`(함수 이름과 반환 타입 이름이 분리된
기존 전례)와 대칭되는 이름이라 어시스턴트도 동의. **다른 용어 정리
항목들과 달리 이건 "임시"가 아니라 지금 바로 코드/문서 전체에 적용** —
최종 이름 확정만 대기열(`question.md`)에 남김, 표기 자체의 모호성은
지금 없앰. `[BooleanAttribute "name"]`류 정적 패밀리는 `Attribute`라는
이름을 쓰지 않으므로 리네임 대상 아님.

### 5라운드 — 이름별 weak 캐시로 동등성 보장, 메커니즘 재개정

문서 반영 직후 사용자가 새 아이디어 제기: `AttributeKey "aaa"`가 GC
전까지 이름별 weak 캐시로 항상 같은 객체를 리턴하게 만들면 어떤가 —
구현은 `cache[name]` 조회 후 없으면 생성+저장하는 단순한 엔지니어링,
비용도 크지 않음. 이러면 `AttributeKey "aaa" == AttributeKey "aaa"`가
보장되고, 사용 중엔 항상 같은 게 리턴됨. 사용자 스스로 `Tag`와 대조:
Tag는 내부 이름 목록 자체가 매번 달라지는 게 핵심이라 동등성 비교가
의미 없지만, `AttributeKey`는 이름 외 다른 가변 정보가 없는 순수 매핑이라
캐싱/동등성 비교가 말이 됨.

**확정**: `AttributeKey(name)`(및 `BooleanAttribute` 등 정적 패밀리 —
캐시 키는 순수 문자열 `name`뿐, 제네릭 `T`는 런타임 무영향이라 무시)이
값만 weak인 캐시(`setmetatable(cache, {__mode="v"})`)를 거치도록 확정.
GC 타이밍: 뭔가(Dispatch의 체인 저장 등)가 강하게 붙들고 있는 동안은
캐시도 살아있어 동일 이름 재호출 시 항상 같은 객체, 아무도 안 붙들면
자연히 풀리는데 그 시점엔 이전 identity를 참조하는 곳이 없어 문제 없음.

**이게 4라운드에서 정한 "그룹 Handler는 자기 완결형, Dispatch 재진입
없음" 결정 자체를 뒤집음** — 그 결정의 근거였던 "매번 새 키 객체라
Dispatch의 (inst,k) 체인 추적이 깨질 위험"이 캐시로 사라지므로,
어시스턴트가 메커니즘을 재개정: 그룹 Handler는 이제 자기만의
`SetAttribute`/구독 로직을 만들지 않고, 메모이즈된 `AttributeKey(name)`로
`Dispatch.process`/`Dispatch.retractUnder`에 각 필드를 그대로 재귀
위임 — 작성자가 직접 `[AttributeKey<<T>> name] = source`를 쓴 것과
완전히 같은 경로를 태워 단일 키의 `None`/`retract`/store-bind 로직을
100% 재사용(중복 구현 제거). 그룹 Handler에 남는 자기 로직은 사실상
"이전 이름 집합과의 diff"뿐. `OnChangeKey`도 같은 모양(이름→키, 다른
가변 정보 없음)이라 같은 기법이 그대로 적용 가능하다는 점도 기록(급하지
않음, 지금 뭘 풀어주는 캐치는 아직 없음).

### 6라운드 — `OnChangeKey`에도 같은 캐시 적용

5라운드 문서화에서 "OnChangeKey도 같은 기법 적용 가능하나 급하지 않음"으로
남겨뒀던 걸 사용자가 바로 확정지음: `OnChange`가 `State<function>`이
되더라도(캐시는 키 객체 identity만 다루지 바인딩된 콜백/값과는 무관이라)
문제없이 작동할 것이고, `OnChangeKey "a" == OnChangeKey "a"`가 외부에
관찰 가능해지는 것도 의도적으로 허용해도 되는 동작이라 문제 없다고 직접
판단 — 같이 반영. `base/onchange-plan.md`에 `AttributeKey`와 동일한
이름별 weak 캐시 적용을 확정 절로 추가.

### 반영된 파일

`base/attribute-plan.md`(그룹 `Attribute(...)` 절 신규, 단일 키 전체
`AttributeKey`로 리네임)/`base/architecture.md`(소스 트리에 base
`Attribute.luau` + roblox `AttributeKey.luau`/`Attribute.luau` 추가,
4번 항목 갱신)/`base/onchange-plan.md`/`base/bind-system-plan.md`/
`base/ui-shorthand-plan.md`(전부 `Attribute<<T>>` 언급을 `AttributeKey<<T>>`로
치환)/`.claude/README.md`/`.claude/question.md`(용어정리 대기열에
`Attribute`/`AttributeKey` 항목 추가, 기존 "해소됨" 타입파라미터화
항목에도 리네임 각주).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, `luau-test` 결과
확인 우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는
그대로.
