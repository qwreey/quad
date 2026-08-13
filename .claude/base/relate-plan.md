# Relate — inst와 임의의 값을 weak하게 엮는 범용 릴레이션 프리미티브

**상태**: base — 2026-08-08 세션에서 신설, 확정. `base/dispatch-core-plan.md`의
"핸들러 내부 상태 저장"과 `base/lifecycle-pattern.md`의 `bindLifetime`/
`canExecute` 양쪽이 필요로 했던 "`inst`를 weak 키로 하는 저장소"가 지금까지
`base.perInstanceState(inst)`라는 이름만 있고 인터페이스가 미정인 placeholder로
남아있던 것 — 이번에 독립 프리미티브로 정식 승격, `perInstanceState`라는
이름/모양은 폐기.

## 왜 필요한가

Store-bind 핸들러(Tween 등)가 "이전에 만든 것"(실행 중인 Tween, gchold
Connection, gchold 배열 등)에 `retract`/`bindLifetime` 시점에 다시 접근하려면
그 값들을 `inst`에 매달아 저장해야 함. `inst`가 죽으면 이 저장물도 자동으로
같이 죽어야(GC-native, `base/lifecycle-pattern.md` 원칙) 하므로 바깥 키(`inst`)는
weak여야 함 — 그런데 그 안에 담기는 값은 경우에 따라 **강하게 붙잡아야
하는 것**(실행 중인 Tween 인스턴스, gcconn — 안 붙잡으면 존재 이유가 없어짐)과
**약하게만 참조해도 되는 것**(캐시성 값)이 둘 다 있음 — 이 둘을 하나의 테이블
`__mode`로는 표현 못 함(Luau/Lua 테이블의 weak 모드는 테이블 전체 단위).

## 왜 자동으로 강하게 들지 않는가 — 엔진이 결정할 일

**Relate 자신은 `inst`도 `value`도 자동으로 홀드하지 않는다** — 어느 쪽을
얼마나 강하게 들지는 호출부(주로 `quad-roblox`)가 명시적으로 결정해야
함(2026-08-08 세션, 사용자 확정). 자동으로 결정해버리면 weak 키가 참조하는
값이 그 키를 다시 강하게 참조하는 사이클(예: 프로퍼티 핸들러가 만든 클로저가
`inst`를 업밸류로 캡쳐한 채로 그 클로저 자신이 `inst`에 매달린 strong 저장소에
들어가는 경우)이 너무 쉽게 생김 — 엔진 객체의 실제 생명주기를 아는 쪽
(`quad-roblox`)만이 "이 값은 strong으로 둬도 안전하다"를 판단할 수 있음.
그래서 `Relate`는 판단을 안 하고 **`SetWeak`/`SetStrong`으로 호출부가 매번
명시**하게 만드는 얇은 표면만 제공.

## 위험한 패턴 — 서로 다른 두 `Relate`의 상호 강참조 순환 (2026-08-12 열세/열네 번째 세션, `Slot` 설계 중 발견)

위 26-28행이 말하는 "값이 자기 키를 다시 참조하는" 자기참조(예:
`Dispatch.setLength`의 `observer` 클로저가 `inst`를 캡처, `Ref.Value=inst`,
**[확인, 2026-08-12 세션 후속] `slot._mountedInst = physicalTarget`도
같은 패턴** — `bindLifetime(physicalTarget, slot)`이 내부적으로
`physicalTarget`을 키로 `slot`을 강하게 붙잡는 단일 `relate`고,
`slot._mountedInst`는 그 값(`slot`)이 자기 키(`physicalTarget`)를 다시
참조하는 필드일 뿐이라 GC 안전 — `base/slot-plan.md` "재귀 메커니즘"
절)는 **단일 `Relate` 안에서** 일어나는 한 안전함 — 그 `Relate`의 키(`inst`)가
테이블 *바깥에서* 독립적으로 reachable한지만 판별하면 되기 때문. 하지만
**서로 다른 두 `Relate`가 서로의 키를 상대방 값으로 강하게 제공하는
상호 순환**(예: `RelateA[inst]=value`(강)와 `RelateB[value]=inst`(강)가
동시에 존재)은 완전히 다른, 더 위험한 모양 — `inst`의 reachability
판별이 `value`의 reachability에 의존하고 그 반대도 마찬가지라 판별
자체가 순환됨.

**[확인, 2026-08-12 열네 번째 세션] Luau는 이 순환을 못 풂 — ephemeron
테이블이 없음, 복잡성 때문에 Lua 5.2 기능을 도입 안 한 것으로 공식
문서에 명시됨(출처: https://luau.org/compatibility/ "Lua 5.2" 섹션의
"Ephemeron tables" 항목).** 이건 Lua 5.2+가 ephemeron을 도입해서 풀려던
바로 그 사례라, Luau에서 위와 같은 두-`Relate` 상호 순환을 만들면
**둘 다 GC가 안 되는 실제 메모리 누수**가 됨 — "혹시 몰라서 피한다"가
아니라 확정된 필수 규칙.

**규칙**: 어떤 값(`inst` 아닌 임의 객체, 예: `Slot`)을 다른 `Relate`의
바깥 키로 쓰고 싶어지면(예: "이 값이 지금 어느 `inst`에 묶여있는가"
역조회), 그 값 자체가 `inst`로 되돌아가는 강한 back-reference를 갖고
있는지 먼저 확인할 것 — 갖고 있다면 **두 `Relate` 중 최소 한쪽은
`SetWeak`로 낮추고, 실제 GC 앵커는 `bindLifetime`/`unbindLifetime`
하나로 통일**할 것(구체 사례는 `base/slot-plan.md` "Slot과 Store
바인드의 관계" 절 참고 — `kSlotMap`(`(inst,k)`별 마지막 Slot)/`slotOwner`(slot→inst)가
정확히 이 패턴이었음. **[2026-08-13 다섯 번째 세션 이후]** 그 두 `Relate`는
지금은 존재하지 않음 — `kSlotMap`은 Handler 계약이 클로저 반환으로 바뀌며
불필요해져 삭제됐고 `slotOwner`는 `elementOwner`(전부 `SetWeak`)로
일반화됐으므로, Slot 쪽엔 이 위험 패턴이 더 이상 남아있지 않음. 이 절은
**일반 규칙**으로 계속 유효하고, Slot은 그 규칙이 실제로 적용됐던
역사적 사례로만 인용).

## API (확정)

```lua
Relate() -> relate                                  -- 생성자, 싱글톤 아님

relate:SetStrong(inst: any, key: any, value: any)   -- value를 강하게 보관
relate:GetStrong(inst: any, key: any): any?

relate:SetWeak(inst: any, key: any, value: any)     -- value를 약하게만 참조
relate:GetWeak(inst: any, key: any): any?
```

- **`inst`(첫 인자)는 항상 weak** — 이 자유도는 아예 안 열어둠. 지금까지
  나온 어떤 유스케이스도 "`inst` 쪽을 strong으로 두고 싶다"가 없었고, 열어두면
  "`Relate`가 실수로 엔진 객체를 영구히 붙잡는" 사고 가능성만 늘어남.
  `Weak`/`Strong`은 오직 **`value`의 보관 방식**을 가리킴.
- **비싱글톤 — 생성 가능한 값(`Ref`/`Store`/`Modifier`와 같은 프리미티브
  컨벤션)**. 각 핸들러 모듈이 자기 톱레벨에 `local relate = Relate()`를
  하나씩 두고 재사용 — 서로 다른 `Relate` 인스턴스라 `key` 네이밍이 모듈
  간에 겹칠 걱정이 없음(모듈 하나가 감당할 key 개수는 보통 한두 개뿐이라
  `Relate()`를 여러 개 만드는 비용은 무시할 만함).

## 언제 `Relate`를 쓰고 언제 쓰면 안 되는가 — 체크리스트 (2026-08-13 여섯 번째 세션 신설)

Handler 계약이 "`process`가 자기 retract 클로저를 반환"으로 바뀌면서
(`base/dispatch-core-plan.md` "핸들러 계약" 절) **`Relate`가 필요한 범위가
크게 줄었음** — 이 전환기에 양방향으로 실수가 나왔어서 기준을 못박아 둠.

**쓰지 말 것 — 클로저 캡처로 충분한 경우**: 이 `process` 호출이 만든
것을 **그 호출이 반환한 클로저가** 나중에 정리하는 단발성 handoff.
`local observer = ...` / `local connection = ...`를 로컬로 두고 반환
클로저가 upvalue로 캡처하면 끝 — `relate:SetStrong(inst,k,x)` 후
`relate:GetStrong(inst,k)`로 되찾아오는 왕복이 통째로 불필요.
2026-08-13 다섯 번째 세션에 `kSlotMap`(위치별 마지막 Slot),
`kTagMap`(위치별 마지막 Tag), Attribute의 `groupState`가 전부 이 이유로
삭제됨. 새로 `Relate`를 하나 만들고 싶어지면 **먼저 "이거 그냥 클로저가
캡처하면 되는 것 아닌가?"를 물어볼 것.**

**써야 할 것 — 하나의 클로저 수명을 넘어서는 상태**:
- **여러 위치가 하나의 자원을 공유**할 때의 참조 카운트 — `Tag`의
  `tagNameMap`(이름 → 그 이름을 걸고 있는 위치 집합).
- **여러 `process` 호출을 가로지르는 dedup 기록** — `Ref`의 "이 자리에
  마지막으로 바인딩한 Ref"(클로저가 받는 인자는 *다음* 값이지 *이전*
  값이 아니라서 캡처로 대체 불가).
- **소유권/멤버십 전역 판정** — `Slot`의 `elementOwner`.
- **"언제까지 실행돼도 되는가"** — `bindLifetime`/`canExecute`
  (`base/lifecycle-pattern.md`). 애초에 클로저 수명과 무관한 질문.

**쓸 때 같이 지킬 것**:
- **정리 조건을 실제 정리와 묶을 것.** `Relate` 엔트리를 지우는 코드가
  "실제로 물러날 때"라는 조건 **밖**에 있으면, spurious 재발행에서
  기록만 날아가 dedup이 조용히 무력화됨 — `RefLeafHandler`가 실제로 이
  버그를 냈음(`ref-plan.md` "`Ref`의 retract" 절).
- **weak하다고 "언젠간 알아서 사라진다"에 기대지 말 것.** 값이 `SetWeak`
  이어도 **언제 사라지는지는 GC 타이밍**이라, 그 전에 같은 키를 다시
  쓰려는 코드가 비결정적으로 실패함 — `Slot`의 `destroySlotTree`가 자식
  소유권을 명시적으로 반납하지 않고 GC에 맡기고 있던 게 이 사례
  (`base/slot-plan.md` "요소 소유권" 절). **명시적으로 만든 기록은
  명시적으로 지울 것.**
- 서로 다른 두 `Relate`의 상호 강참조 순환 금지 — 위 "위험한 패턴" 절.

## 실제 구조 (확정, 2026-08-08 세션)

```
{ [inst(weak)]: { StrongMap: {[key]: value}?, WeakMap: {[key]: value(weak)}? }? }
```

- **바깥 테이블 하나**: `inst`로 weak-keyed(`__mode = "k"`), 값은 `{ StrongMap?, WeakMap? }`
  형태의 서브테이블.
- **`StrongMap`/`WeakMap`은 각각 lazy 생성** — `Relate()` 호출 시점엔 아무
  것도 미리 안 만듦. `inst`당 서브테이블도, 그 안의 `StrongMap`/`WeakMap`도
  **`SetWeak`/`SetStrong`이 처음 불릴 때 인덱싱해보고 없으면 그때 생성**.
  이유(사용자 확정, 성능 근거): Luau가 정적 분석으로 포인터 해싱을 캐싱해서
  같은 자리에서 여러 번 인덱싱하는 건 이미 꽤 싸지지만, **테이블 생성
  자체(array+hash part 초기화)는 상대적으로 비쌈** — 안 쓸 `inst`/모드
  조합에 대해 테이블을 미리 만들어두는 건 순수 낭비.
- **`WeakMap`의 메타테이블은 항상 같은 객체를 재사용**(`{__mode = "v"}`류
  하나를 모듈 로드 시 한 번만 만들어두고, 모든 `WeakMap` 생성에 그 객체를
  그대로 `setmetatable`) — 메타테이블 내용이 매번 똑같으니 매번 새로 만들

  이유가 없음. `StrongMap`은 메타테이블 자체가 필요 없어 그냥 `{}`.
- `GetWeak`/`GetStrong`은 각각 대응하는 서브맵이 아직 안 만들어졌으면(=한
  번도 `Set`된 적 없음) 그냥 `nil` 반환 — 서브맵을 만들 필요 없음(읽기가
  쓰기를 유발하면 안 됨).

**M2 착수 시 실측 확인**: 위 lazy 생성 전략과 `WeakMap` 공유 메타테이블
재사용이 실제 Luau에서 기대한 만큼 이득인지, `SetStrong`/`SetWeak`을 아주
자주 왕복 호출하는 핫패스(예: 매 프레임 store-bind 재실행)에서 서브테이블
존재 체크 자체가 새 비용이 되지는 않는지 — base 설계에는 영향 없는 순수
구현 최적화 문제.

## 대체하는 것

- `base/dispatch-core-plan.md` "핸들러 내부 상태 저장" 절의 `base.perInstanceState(inst)`
  placeholder — Tween 등 핸들러가 `retract` 대상을 저장하는 용도, `SetStrong`으로.
- `base/lifecycle-pattern.md`의 `bindLifetime`/`canExecute` — gcconn/gchold를
  `Relate`의 `SetStrong`으로 저장(둘 다 존재 이유가 "안 죽는 것"이므로
  strong).

## 이름

`Relate` — 사용자 확정("이름은 Relate 괜찮아요? ... 좋습니다", 2026-08-08
세션). 다른 프리미티브(`Source`/`Ref`/`Store`/`Modifier`/`Effect`/`Blocker`)와
같은 "타입 이름이 곧 생성자" 컨벤션 그대로.
