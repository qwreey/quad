# `bindLifetime`의 타입 지식 분리 — 수명 훅 브랜드 (계획, 결정 대기)

**[2026-10-01 신설 — 사용자 제안]** 상태: **[2026-10-01 결정]** 내부 정리만 지금(사용자: *"bindableTarget 는 우선은 내부 정리로 하자. 공개 관해서는 나중 해볼 일로 잡아두면 될것 같고. 이름은 셋 다 괜찮은것 같음. 훅이 던지는건 UB 맞아."*) — 내부 `BindableBrand` + `_assertBindable`/`_afterBind`/`_beforeUnbind`, 생존 판정은 데이터(브랜드 + `Subscribed`), 묶은 뒤 훅 throw는 UB. **공개 등록 표면은 백로그**(5절 1번의 "공개까지"는 나중 할 일). 아래 5절은 결정 전 기록.

## 1. 제안 (사용자 원문)

*"bindlifetime 에서, 즉 코어에서 코어의 다른 부분을 알고 작업하는 부분이 있는데, 그건 확장 시 거기를 건들여야해서 나는 bindableTargetBrand 같은걸 만들어서, binelifetime 을 들어갈 때 assert 나 바인드 전후 처리나 바인드 끊기는 처리를 할 수 있게 도와주는게 어떤지 싶어. bindableTargetBrand(가칭) 에 있으면 메서드들이 있는지 보고, nil이면 안 하고, 함수면 수행해주는것. 그렇게 effect 처리나 observer 처리 등을 빼두면 확장성이 오를 표면으로 보여."* — 이어서 *"이것도 네이밍에서 잘 먹었던 외부자 내부자 시선에서 조언을 받아보자."* (`session/2026-09-28-01-round13-batch-reply.md` 2026-10-01 절)

## 2. 지금 코어가 Observer/Effect를 아는 자리 (`quad-base/src/LifetimeHandle.luau`, 내부자 전수)

| 기호 | 자리 | 내용 |
|---|---|---|
| (A) | `bindLifetime` 묶기 전 | `type(value)=="table" and value._assertBindable ~= nil`이면 호출 — 유일한 덕 타이핑(`H-184`: 커밋 전이라 던져도 아무것도 안 남음) |
| (B) | 묶은 뒤 | `isObserver`면 `_catchUp()`(`H-159`) |
| (C) | 묶은 뒤 | `isEffect`면 `_bindDestroying(inst)` |
| (D) | `unbindLifetime` | `isEffect`면 `_unbindDestroying()` (훅 → `releaseLifetime` 순) |
| (E) | `isBoundAlive`(= `canExecute`, 매 통지 — 핫 패스) | `isObserver or isEffect`면 `value.Subscribed == true`(`H-111` 공용 플래그) |
| (F) | `bindLifetime` 거부 메시지 | `Quad0104` 대 `0232`/`0233` 고를 때 같은 `.Subscribed` 지식 |

이력: 이 지식이 base에 있는 것은 Q59(2026-09-18, 백엔드 사본 통합 — *"base 가 아는 경계랑 각 백엔드가 아는 경계가 섞여있다는 점이 문제"*)의 부수 결과이고, "Observer/Effect 모듈 밖에 둔다"를 택한 기록은 없다. 제안은 `H-278`(*각 객체를 아는 곳은 각 객체가 선언된 곳*, `architecture.md`)·`H-229`(모르는 타입은 훅 없음, `lifecycle-pattern.md` (0.5))의 연장이고 Q106 `q.BrandPredicates`가 선례. bindLifetime 밖에서 O/E를 아는 자리(`Slot/Elements.luau` 요소 허용 목록, `Dispatch/Modifier` 목록, `BRAND_PROBES`, `init.luau` 재노출)는 성격이 달라 범위 밖.

## 3. 두 검토의 수렴과 갈림

**수렴**: 방향은 맞다(외부자: React cleanup·Solid owner `onCleanup`·Fusion Scope·`Symbol.dispose` 모두 "코어는 한 모양만 알고 타입이 자기 정리를 소유"). **지금은 내부 정리만, 공개 등록 표면은 서드파티 수요가 실제로 생길 때** — 수요가 아직 없어 공개는 "가상의 미래 요구"이고, 공개하는 순간 훅 순서·throw·재진입이 영구 계약이 된다; 내부 정리는 동작 변경 0·약 25줄 이동. **(E)는 메소드 훅으로 빼지 않고 데이터로** — 핫 패스에 던질 수 있는 코드를 넣지 않는다. 내부자 구체안: `BindableBrand:Is(v) and v.Subscribed == true` — 지금 `isObserver`·`isEffect` 조회 둘을 브랜드 조회 하나로 바꿔 같거나 싸고, "브랜드 가진 핸들은 `Subscribed` 불리언을 가진다"가 문서화된 계약 필드가 된다. (F)도 같이 옮길 것.

**갈림**:
- 훅을 어디에 두나 — 내부자: 각 타입 `Impl`의 비공개 메소드(지금 `_assertBindable`과 같은 모양; 같은 함수 객체를 두 `Impl`에 배정하지 말 것 — `H-144` 사고). 외부자: 등록 테이블로 받기(`Register(value, hooks)`) — 값에 `_` 필드가 안 남고 덕 타이핑 오타가 등록 때 잡힘. → 내부 정리 단계는 `Impl` 메소드가 자연스럽고, 공개할 때 등록 테이블 모양을 다시 볼 것.
- 묶은 뒤 훅이 던질 때 — 외부자: `releaseLifetime`으로 되감고 다시 던지기. 내부자: 지금처럼 UB(Q56 (b)). **되감기는 사용자 코드를 pcall로 감싸야 하므로 "예외 안전성 계약 — 감싸지 않는다"(`architecture.md`)와 충돌** → 내부자 쪽(UB 유지)이 이 레포 계약에 맞다.
- 훅 수 — 외부자: (B)(C)를 `_onBind` 하나로. 내부자: 기존 `_assertBindable` 유지 + `_afterBind(inst)` + `_beforeUnbind()`(Observer는 `_beforeUnbind` 없음 → 건너뜀).

**함정(두 검토)**: 묶을 때 `assert → hold(커밋) → after`, 풀 때 `before → release` 대칭; 훅 안에서 같은 값 재bind는 `canBound` 거부(문서 한 줄), 다른 값 재진입은 UB; 한 값의 다중 브랜드 소속은 금지로 시작; 생성마다 약한 테이블 쓰기 한 번 — `Slot:List` 대량 생성 경로 퍼프 확인; 브랜드 없는 테이블이 우연히 `_assertBindable`을 가진 경우 더는 안 불림(비공개 `_` 약속이라 BREAKING 아님).

## 4. 이름 후보 (사용자 결정)

| 무엇 | 외부자 추천 | 내부자 추천 | 그 밖 |
|---|---|---|---|
| 브랜드(내부) | `q.Bindable`(공개 시) | `BindableBrand`(`Brand.luau` 내부) | `LifetimeHookedBrand`, `HoldableBrand`(`holdLifetime` 어휘), `LifetimeHandleBrand`; 비추천 `Owned` 계열(`OwnsElements` 개명 이력)·`Lifecycle`(생명주기 훅 슈거와 혼동)·`Disposable`(뜻이 (D)만 덮음) |
| 훅 | `_beforeBind` / `_onBind` / `_onUnbind` | `_assertBindable`(유지) / `_afterBind` / `_beforeUnbind` | 공개 시 표 등록 `LifetimeHooks:Register(brand, { AssertBind, AfterBind, BeforeUnbind })` |

## 5. 정할 것

1. 지금 내부 정리만 할지(권고) / 공개까지 / 보류.
2. 브랜드 이름과 훅 이름.
3. 묶은 뒤 훅이 던질 때 — UB 유지(권고, 감싸지 않는다 계약).
