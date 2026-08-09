# Attribute 특수 키 — 타입 파라미터화, `SetAttribute(name, nil)` 네이티브 지우기

**상태**: base — 메커니즘/`None`/`retract` 동작뿐 아니라 타입 파라미터화도
**둘 다 채택으로 확정**(2026-08-09 열한 번째 세션, 아래 참고). `[Attribute
"Name"]` DI 키의 존재 자체는 `architecture.md`
4번 항목에서 이미 확정. UICorner 숏핸드/Tween처럼 별도 전용 문서가 없던 걸
2026-08-07 여덟 번째 세션에 메꿈("1 프리미티브 1 파일" 관례를 Tag/Attribute
에도 적용해야 한다는 사용자 지적) — `bind-system-plan.md`의 "Attribute
특수 키 — 타입 파라미터화" 절(2026-08-06 신설) 내용을 그대로 옮기고, 오늘
논의한 `None`/`process`/`retract` 동작을 추가.

## 문제 — 타입 있는 값이라 Luau가 좁혀줄 방법이 필요

Roblox Attribute는 Instance/Tag와 달리 실제로 **타입이 있는 값**
(string/boolean/number/Color3/UDim/UDim2/Vector2/Vector3/CFrame/Instance
참조 등 제한된 프리미티브 집합, 테이블 등 복합 타입은 지원 안 함)이라, 그냥
`[Attribute "name"] = value`로 두면 `value`의 타입을 Luau가 좁혀줄 방법이
없음. 커스텀/복합 데이터(테이블 등)는 애초에 Attribute가 지원을 안 하므로
Ref(직접 참조 획득) 쪽으로 빠지는 게 맞고, Attribute는 프리미티브 전용으로
남기면 된다는 게 사용자 판단 — Value 오브젝트가 역사적으로 Attribute의
대안(테이블/참조를 담는 용도)으로 나온 배경이지만, 지금은 Roblox Attribute가
Instance 참조 타입도 지원해서 `ObjectValue` 없이도 Ref 용도로 Attribute를
그대로 쓸 수 있다는 점을 사용자가 짚음(`research/debug-tooling-plan.md`의
"Value 오브젝트 기각, Attribute로 확정" 결정과 같은 방향 — Instance 타입
지원까지 감안하면 그 결정의 근거가 한층 더 탄탄해짐).

**확정(2026-08-09 열한 번째 세션) — 둘 다 채택**:
- `[Attribute<<boolean>> "name"] = true` (리터럴 또는 store-bind 값) —
  제네릭 파라미터로 타입을 명시하는 제네릭 생성자 스타일. 기본/범용 경로.
- `[BooleanAttribute "name"] = true` — 타입별로 이름이 다른 정적 생성자
  패밀리(`StringAttribute`/`NumberAttribute`/`Color3Attribute`/
  `InstanceAttribute` 등). 실사용 빈도가 높은 몇 개만 지름길로.

**근거**: 이미 확정된 DI 인스턴스 생성 패턴(`bind-system-plan.md` "인스턴스
생성 / 이벤트 네이밍 인체공학" 절)과 구조적으로 똑같은 문제라 같은 결론
재사용 — `new<ClassName>(className)` 제네릭 생성자 + 자주 쓰는 ~25개는
정적 필드로 미리 바인딩했던 것과 동일한 절충. **내부 구현은 완전히
동일**(같은 Handler를 타고, 같은 프리미티브) — 둘 사이 차이는 순전히
호출부가 타입을 어떻게 명시하느냐(제네릭 파라미터 vs 이름)뿐이라 어느
쪽을 쓰든 런타임 동작에 차이 없음.

**[실측 필요, M0/M10]** `[Attribute<<boolean>> "name"] = value`처럼 DI
키 제네릭 파라미터로 `=` 뒤 `value`의 타입까지 실제로 좁혀지는지는
미검증 — Luau 솔버가 이 조합을 못 풀면 `value`가 `any`로 남을 수 있음.
단, **타입 추론이 안 되더라도 런타임 동작에는 영향 없음**(순수 정적
타입체크 실패일 뿐, `SetAttribute` 호출 자체는 항상 정상 작동) — 안
되면 `BooleanAttribute` 같은 정적 타입 패밀리 쪽이 사실상 유일하게
믿을 수 있는 정적 체크 경로가 됨.

## 메커니즘, `None`, `retract` — 전부 확정 (2026-08-07 여덟 번째 세션)

타입 파라미터화 이름과 무관하게 런타임 동작은 확정:

- `process(inst, k, v)` — `inst:SetAttribute(name, v)`가 사실상 전부.
  **Attribute는 `None`의 가장 깔끔한 사례** — Roblox API 자체가
  `SetAttribute(name, nil)`을 "그 Attribute 엔트리를 지운다"는 뜻으로
  네이티브 지원하므로, `None → nil` 재디스패치(`base/bind-system-plan.md`의
  `None` 센티널 절)가 도착했을 때 handler가 **아무 특별 처리도 없이**
  `inst:SetAttribute(name, nil)`을 그대로 호출하면 끝 — UICorner 숏핸드처럼
  "만들어둔 자식을 수동으로 찾아 지우는" 로직조차 필요 없음.
- **`retract` 불필요** — Tag와 같은 이유: 값이 뭐든(실제 값/`nil`) 항상
  같은 `AttributeHandler`가 이 키를 계속 담당(핸들러 *타입*이 안 바뀜).
  `retract`가 의미 있는 유일한 패턴("매치되는 핸들러 타입 자체가 바뀜",
  `Tag(...)`↔`nil`이 실사례 — 2026-08-10 세션부터 Tween은 더 이상 이
  패턴의 예시가 아님, `research/tween-plan.md`)에 해당 안 함 —
  `bind-system-plan.md` "확정된 디스패치 모델" 절이 한때 Attribute도
  retract 필요 예시로 들었던 걸 여기서 바로잡음.
- store-bind 가능(일반 프로퍼티와 동일하게 취급, `Store<T>`/`State<T>`
  값도 받음).

## 패키지 배치

UICorner 숏핸드/Tween/Tag와 같은 판단 재사용 — `quad-roblox` 코어에 직접
포함, 별도 opt-out 패키지로 안 쪼갬.

## 열린 질문 (`.claude/question.md`에도 취합)

- 타입 파라미터화 이름(`Attribute<T>` 제네릭 vs `BooleanAttribute`류 정적
  패밀리 vs 절충) — 위 "문제" 절 참고, 다음 세션 사용자 판단 필요.
