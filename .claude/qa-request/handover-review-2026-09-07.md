# 핸드오버 전체 코드 리뷰 원장 — 2026-09-07 (`H-344`~`H-356`)

> **이 파일이 무엇인가**: 마일스톤 M0~M11 완료 뒤 핸드오버 시점에 돌린 **전체 코드
> 리뷰**(마일스톤 단위 원장이 아니라 코퍼스 전체 — 그래서 `mN-implementation-roundNN`
> 이름을 안 쓴다)의 발견 원장. 사용자 요청(2026-09-06): *"세션 로그와 전반 구조를
> audit 하고 코드리뷰 해줘, 전체 코드 리뷰를 해도 좋아 … 여럿 코드리뷰를 돌려보기
> 좋은 상황이야"*. 발견 번호는 round21(`H-341`)·round19 리뷰(`H-343`)에 이어
> **`H-344`부터**. 세 갈래·처리 규약은 round11 brief 준용. 상태의 소스는 이 파일.
>
> **경위(중요 — 규약 `conventions.md` 2026-09-06 항목의 두 번째 사례)**: 2026-09-06
> 밤에 띄운 리뷰 9개(R1~R3 opus + `/code-review high` 포크와 앵글 5)가 사용자의
> `/compact` 인자 편집 중 **전부 중단**됐다. 2026-09-07 새벽에 (1) 중단된
> 트랜스크립트에서 sonnet 서브에이전트가 발견 후보를 추출하고, (2) 같은 지시로
> R1~R3·`/code-review high`를 **다시** 띄웠다. 아래 표는 둘을 합친 것 — "출처" 열의
> `구R*`/`구A*`는 중단분 추출, `R*`는 재실행분. 중단분의 실측 로그(`tmp.*`/`zz_probe*`
> 스크래치)는 판정 근거로만 쓰고 삭제했다(측정치는 표에 전사).

## §1 반영한 것 (갈래 ① — 이 커밋)

| ID | 출처 | 자리 | 무엇 | 처리 |
|---|---|---|---|---|
| **`H-344`** | R2-3 / 구R2 / 구Simplification / 판정 보조자 — **셋이 독립 발견** | `quad-base/src/Tag.luau` `Removed` | `Added`는 `flattenInto`로 비문자열을 거부하는데 `Removed`는 검증 없이 조용한 no-op, `nil`은 VM "table index is nil"(실측)로 `Tag.luau`를 blame | `Removed`도 `flattenInto`를 태운 뒤 제거(본문 재사용). `spec.tag` 음성 둘 |
| **`H-345`** | R2-1 | `quad-base/src/Attribute.luau` `flattenArg` 셋째 분기 | `type(arg) == "table"`만 보고 "plain"을 강제하지 않아 `Attribute(source)`가 `_value`/`Revision`/`_subs`를 속성 이름으로 펼친다 — Modifier가 `H-310`으로 이미 닫은 사고(`isPlainFieldTable`) | `getmetatable(arg) == nil` 조건 추가 → 나머지는 기존 else 메시지("plain tables"). `spec.attribute` 1b절 |
| **`H-346`** | R1-2 / R2-2 | `quad-base/src/Dispatch/init.luau` `BRAND_PROBES` | 모듈 표면 술어 중 `isMapperDescriptor`만 누락 — 체크리스트 0-b(`H-338`/`H-342`의 마지막 잔여) | 목록 머리에 추가. `spec.claim` 7절이 `brand: MapperDescriptor`를 단언 |
| **`H-347`** | R1-3 | `quad-base/src/Store.luau` 생성자 | `Of`는 `H-201`로 키 타입을 검사하는데 생성자 문은 열려 `Store({ Source(1) })`가 통과, `Names()`가 `{ 1 }` | `type(name) ~= "string"` → `errorBeforeNearest`. `spec.store` 음성 |
| **`H-348`** | R1-4 | `quad-base/src/LifetimeHandle.luau` 미설치 스텁 | 지배적 발화 지점이 디스패치 깊이(`process` → `bindLifetime`)인데 `errorBeforeNearest` — 체크리스트 0의 실패 모드. 실 백엔드(`quad-roblox/src/LifetimeHandle.luau`)는 `errorBefore` | `errorBefore`로 통일 → **§7 `H-370`으로 정정**(`canBound`/`canExecute`는 직접 호출 프리미티브라 `errorBeforeNearest`, 나머지 셋만 `errorBefore`) |
| **`H-349`** | 구Conventions-1 | `quad-base/src/init.luau` `UseProvider` 중복 설치 에러 | 직접 호출 표면인데 `errorBefore` — 체크리스트 0의 판별대로면 `errorBeforeNearest`(단일 태그 프레임이라 관측상 동일, 일관성) | 교체. `spec.robloxfactory` `assertBlamesUser` 그대로 통과 |
| **`H-350`** | R1-1 | `quad-base/src/Bookkeeping.luau` `getOffsetAt` | 루프 중 재시작이 `math.max(cursor, 1)`로 클램프해 커서가 0으로 내려간 경우(M6 splice `j-1 = 0`·owner base 이동)에 **옛 `offsetCache[1]` 위에** 캐시를 다시 쌓는다 — 그 자리 주석의 전제("M3에선 1 밑으로 안 내려간다, M6가 base를 다시 읽어야")가 M6 착지 후 미이행 | 부트스트랩을 `ensureBase()`로 빼서 재시작 직전에도 호출. **in-tree 재현 경로 없음**(`setLength` 호출부 전수가 상수/`slot.Length`) — spec 없이 정본 의사코드만 갱신(`dispatch-core-plan.md`) |
| **`H-351`** | R3-1 | `quad-roblox/src/types.luau` `NewChild` | children 값 유니언에 `Slot`이 없다 — `bind-system-plan.md`가 M5에 예고한 "M6 Slot" 확장 팔이 fork 슬라이스에서 실행되지 않았다(M7/M8/M10은 마커 있음). 런타임 `SlotHandler`는 받는다. strict spec 7개 중 children에 Slot을 넣는 것이 없어 살아남음 | `\| QuadTypes.Slot<Instance>` 합류(생성 `<Class>Elem` 전량 — "too complex" 없음, CLI 49/49). `spec.componenttypes` `_slotChild`. **`State<Slot<…>>` 팔은 §4 Q1** |
| **`H-352`** | R3-4 / 구A3(실측: 활성 트윈에 `None` → 취소 0, 끝까지 재생) | `quad-roblox/src/Handlers/Property.luau` 헤더 | 헤더의 "마지막 쓰인 값이 남는다"가 활성 트윈 분기에선 참이 아니다 — 동작은 **의도된 것**(`spec.tweenproperty` 5절 "None → nil: skip-defense, active tween untouched") | 헤더에 예외 한 줄. 코드 변경 없음 — 버그로 재개봉 방지 |
| **`H-353`** | R3-2(추정) → **메인 실측 확정** | `scripts/gen-d.py` `PVn`·Modifier setter | 유일한 유니언 프로퍼티 타입 `UICorner: number \| UDim`의 `PV73 = … \| State<number \| UDim> \| …`가 `Source(8)`/`Source(UDim)`을 **둘 다 거부**(`State<X>` 불변, `H-326`/`H-327`) — 인라인 리터럴·로컬 바인딩·Modifier `:UICorner(radius)` 전부 실측 거부. `spec.shorthandtypes`는 `UICorner`에 State를 한 번도 안 넣어 우회 | 유니언 타입은 **멤버마다** `State<m>`/`TweenData<m>`/`State<Tween<m>>` 팔을 나열(`PV73` 9팔), setter는 `Field<number> \| Field<UDim>`. `LuauSolverConstraintLimit=1000000` 그대로 통과. `spec.shorthandtypes` 양성 넷. `typing-limits.md` 8.9절 → **§6 `H-362`/`H-363`으로 정정**(setter는 `SHF0`, `PV73`은 전체 팔 유지 + 멤버별 팔 = 11팔) |
| — | R3-5 | `spec.tweentypes` 헤더 | `H-324` 교집합 서술이 `H-343` 이후 stale | 문장 정정 |

## §2 기각·확인만 한 것 (재발견 금지)

| 출처 | 무엇 | 판정 |
|---|---|---|
| 구A1(실측: `tmp.b1`) | `Effect`의 `fn`이 함수가 아닌 값을 cleanup으로 반환하면 rerun에서 `attempt to call a table value`, 이후 `_running`/`_cleanupRunning`이 stuck돼 `Unsubscribe` 거부 | **기각 — 문서화된 계약**. `Effect.luau` 헤더 *"errors leave `_running` / `_cleanupRunning` set — that Effect is dead, by contract"*(no-pcall 규칙). 1차 방어는 타입(`fn: () -> (() -> ())?`). 비함수 검사 추가는 "드문 오용 방어" 원칙 위반 |
| 구A2(실측: `zz_probe3` EXP B) | `Splice(2,1,X,Y)` 뒤 mock의 물리 자식 순서 `a,c,X,Y` vs 논리 `a@0 X@1 Y@2 c@3` | **기각 — 물리 순서는 계약 밖**. `dispatch-core-plan.md` 1498행: Roblox는 `LayoutOrder`/`ZIndex`가 `Parent` 배열 물리 순서와 분리, Slot은 `LayoutOrder`를 건드리지 않는다(같은 문서 1562행 폐기 기록). 논리 순서·Offset은 정확 |
| 구R2(실측: `tmp.r2leak`/`r2bisect`, 원인 미특정 채 중단) | Attribute 그룹을 같은 이름으로 churn하면 사이클당 30~75 B 누적 | **기각 — 누수 아님(메인 재실측)**. (1) `AK._newUncachedKey` 생성만 해도 30.72 B/cycle, (2) 순수 Luau `setmetatable({}, {__mode="k"})`에 삽입만 해도 **동일 32 B/cycle**(N=128000까지 선형), (3) 100사이클마다 `collectgarbage("collect")`를 끼우면 Tag/Attribute 1·3이름/사설 키 churn **전부 0 B/cycle**. 즉 Luau CLI의 GC 페이싱 아래서 약참조 **키** 테이블(Brand 레지스트리·Relate 버킷)의 노드 배열이 고수위까지 커진 채 남는 것 — quad 코드의 강참조 잔여가 아니다 |
| R2·구R2·판정 보조자 | `Ref:Wait(thread)`에 죽은 thread → `:Set`이 `coroutine.resume` 실패로 에러, 남은 콜백 미발화 | 기결정 `H-170`/`H-339` |
| 구R1(실측: `tmp.r1h`) | 핸들러 `process` 안에서 자기 키를 `retractFrom` → 반환한 retractor 미호출 | 체크리스트 5 "재진입/자기 재정의 무방어" 계약 범위(R1 재실행도 같은 판정) |
| 구R1(`tmp.r1i` — 하네스 오류로 미완주) | `Compute` 안에서 `slot.Offset:Set()` 재진입의 오프셋 캐시 | **`H-350`이 닫은 자리**와 같은 축(base 이동 → 커서 0). 별도 항목 없음 |
| 구Conventions-2 | `Claim.luau` `isMapperDescriptor` 검사의 `errorBefore` | 유지 — 리뷰어 본인이 "근거 약함". `Claim`은 DFS 경로에서 자기 하위 에러의 최외곽 blame 자리이기도 해 outermost가 맞다 |
| 구Conventions-3 | `type-version-check`의 `pcall` | 오탐(컴파일타임 type function — "no-pcall" 규칙은 런타임 계약) |
| R1(번호 없음) | `drive`의 recompute 호출부가 `bk.recomputeBlocker`만 보고 배치 `blocker:IsOn()`은 안 봄(`H-119` 문구는 둘 다) | 확인 항목 — `_handles`가 in-tree에서 비어 검사가 공허. 공개 `getBlocker`를 게이트 정책으로 쓰는 제3자가 생기면 실효. 코드 변경 없음(§4 Q3에 묶음) |
| 구A1 퍼저 | 반응형 그래프 정합성 300 trial·게이트/블로커 400 trial | 실패 0 — `audit/fable-exploration-2026-09-06.md`와 같은 결론 |
| R3 | `OnChange` `setLength` anchor·초기값 발화 순서·`UseProvider` 락·`Animate` 의사코드·Property 3-상태·InstanceShorthand·연결 해제·mock↔실 프로바이더 계약 | 전부 정본 일치(원장 R3 본문에 근거 기록) |

## §3 확인 항목 (코드 변경 없음, 기록)

- **`H-354`** — strict에서 타입드 Slot을 만드는 관용구는 **`q.Slot() :: QuadTypes.Slot<Instance>` 캐스트뿐**. `q.Slot(nil :: { SlotElement<Instance> }?)`·`q.Slot({} :: {…})`·`local s: Slot<Instance> = q.Slot()`는 전부 "too complex" 또는 불일치(생성자 `<T>(initial: { SlotElement<T> }?)`에서 `T`가 `T | State<T> | Slot<T>` 안쪽이라 추론이 안 되고, 배열 타입은 불변). M6 fork가 strict spec을 안 남겨 드러나지 않았던 것. `typing-limits.md` 8.9절에 기록. 생성자 시그니처를 바꾸는 건 새 표면 — 필요가 관측되면 문항.

## §4 사용자 문항 (갈래 ②)

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **Q1** (`H-351` 후속) | `NewChild`에 `State<Slot<Instance>>` 팔도 넣을지 — 런타임은 StoreBind 언랩으로 도착하고 `isHandlable`이 `isSlot`만 보므로 동작은 이미 된다. 타입만의 문제 | (a) 넣는다(`State<Slot<Instance>>` 한 팔 — `State<X>` 불변이라 그 글자 그대로만) / (b) 안 넣는다(`State<Slot>`은 slot-plan의 "교체는 언마운트" 의미론이 있는 드문 관용구 — 필요가 관측되면) | **(b)** — 관측된 필요 없음, 팔 하나가 "too complex" 예산을 먹는다 |
| **Q2** (R3-3, **`H-355`**) | children 유니언에 `Observer`/`EffectHandle`도 없다 — `state:Observer(fn)`을 children에 놓는 관용구는 `source-state-plan.md`가 정본화했고 leaf 핸들러가 받는데 strict는 거부 | (a) 둘 다 넣는다 / (b) `Observer`만 / (c) 안 넣는다 | **(a)** — 정본화된 관용구가 strict에서 막히는 건 `H-351`과 같은 모양. 다만 M5 확장 목록에 이름이 없었으니 사용자 확인 |
| **Q3** (구 앵글 Efficiency/Simplification/Reuse/Altitude, **`H-356`**) | 코드 품질 제안 묶음 — 결함이 아니라 판단 대상이라 반영 안 함: ① `Slot:List` 재정렬 O(N²)(N=1000에 19.6ms 실측)·reconcile마다 `table.clone(prevKeys)`·`prepareElements` 전체 재스캔 / ② `notInstalled` 스텁 팩토리가 `Tag.luau`·`AttributeKey.luau`에 바이트 동일 / ③ `registerEmptySlot` 관용구를 quad-roblox `OnChange`·`InstanceChild`가 패키지 경계 때문에 인라인 복제(`None.luau` 주석은 `OnChange`만 승인) / ④ `Property.luau`·`Event.luau`의 Reflection 캐시 손코딩 중복 / ⑤ `Dispatch/Modifier.luau`가 `Ref.luau`의 `addProcessed` 팩토리를 안 쓰고 세 번째 사본 / ⑥ Slot CRUD 9곳 `assertLive; assertManual` 복붙 / ⑦ `gen-d.py`의 `reserved`·`union_member_functions`·`SHORTHAND` 목록이 런타임 소스(`Modifier.luau`·`types.luau`·`InstanceShorthand.luau`)를 안 읽고 손 복제 / ⑧ `drive`의 배치 Blocker 검사(§2 마지막 행) | 항목별 (a) 반영 / (b) 보류 | ①은 **(b)**("관측된 병목에만" — 실측이 벤치지 실사용이 아님), ②③⑤⑥은 **(a)** 후보(본문 공유가 아니라 데이터·순수 헬퍼 공유라 "하나가 두 일" 위반 아님)지만 리뷰 제안이라 사용자 결정, ④는 `H-302`가 갈라 둔 자리라 **(b)**, ⑦은 **(a)**(조용히 어긋나는 손 복제 — `SHORTHAND`는 `InstanceShorthand.luau` `TABLE`에서 읽게), ⑧ **(b)** |

## §5 `/code-review high` 재실행분 (2026-09-07 새벽 도착 — 앵글 10 + 검증자, 최종 10건)

리뷰어가 스스로 뺀 것: 위 §1의 커밋이 이미 닫은 여섯(`H-344`/`H-347`/`H-348`/`H-350`/`H-351`/`H-352`)과
정본 인용으로 반박한 일곱(Tween 자연 완료 슬롯 유지·비트윈 타입에 TweenData NOOP·Effect 루프
사망 판정 `H-147`/`H-182`·`prePass` `#flattened`·detach 요소 `releaseOwner`·Modifier setter
`error(msg, 2)` `H-309`·`bindLifetime`의 `isObserver`/`isEffect` 훅).

| ID | 자리 | 무엇 | 판정·처리 |
|---|---|---|---|
| **`H-357`** | `Effect.luau` leaf retractor 경로 | `fn` 실행 중 자기 leaf가 철거되면(값 교체·Slot 요소 제거) `_consumeCleanup`이 빈 채 돌고, `fn`이 돌려준 cleanup은 영구 미소진 | **① 문서** — 이미 있는 UB(`fn` 안에서 자기 inst 파괴, `effect-plan.md` 2026-08-28 배너)의 두 번째 트리거. `H-147` (A) "`fn`은 자기 생명주기를 못 바꾼다"의 물리판이라 배너 확장. 가드 안 넣음(unbind에 `isRunning` 가드를 두면 철거가 실패한다) |
| **`H-358`** | `Slot.luau` `Init` | `module.Dispatch`/`_bookkeeping`을 `RunInit(InitDispatch)` 없이 직접 읽는 유일한 Init — `init.luau`의 "순서 무관" 불변식 위반(지금은 순서가 맞아 잠복) | **①** `module:RunInit(InitDispatch)`(`H-174` 관용구) |
| **`H-359`** | `scripts/gen-d.py` `defs_knows` | Enum 분기가 `"<Name>:" in defs` 부분문자열이라 핀 고정 defs보다 새 Enum이 필드 이름 우연 일치로 게이트를 통과 → 생성 D가 미선언 타입 참조로 통째로 실패("조용한 절단 금지" 계약의 반대 방향 위반) | **①** `declare extern type Enum<Name> extends EnumItem` 정확 형(defs의 596 Enum 전부 이 형) — 재생성 결과 diff 0 |
| **`H-360`** | `dispatch-core-plan.md` 무효화 표 3행 vs `rawReplace` | 표는 `Extract(index, new)` 교체 형태도 `minPos - 1`로 규정하는데 코드·slot-plan 의사코드·`Bookkeeping.luau` UB 주석은 `setLength(i)`의 `i`뿐 — 정본 내부 불일치 | **① 문서** — 셋 대 하나. 교체는 옮겨오는 요소가 없어 `i` 자리 offset이 안 바뀐다(첫 행의 논리). 리뷰어 시나리오(recompute 커서 `i`에서 사용자 Observer가 `Replace(i)`)는 `Bookkeeping.luau`가 명시한 UB 경계("커서와 정확히 같은 자리로의 하강은 무변경과 구분 불가 — 재진입 family") |
| **`H-361`** | `Handlers/Property.luau` `isHandlable` vs 동적 경로 가드 | NORMAL 키 전용 매치가 FALLBACK 가드(Observer/Effect)보다 먼저라 실프로퍼티 키에 핸들 값을 넣으면 정본의 가드 메시지 대신 엔진 에러 + `H-103` NOOP 잔존; `Ref`는 가드 자체가 없음 | **② §4 Q4** — 가드를 살리려면 `isHandlable`이 값 브랜드를 봐야(핫패스 비용) 하거나 가드 우선순위를 올려야(정본 설계 역전). `source-state-plan.md` 가드 근거 문장에 정정 배너 |
| — | `Dispatch/init.luau` `process` (A)/(B) | 같은 `(inst, k, index)`로 `h.process` 도중 재진입(예: `Slot.Offset` Observer가 같은 키 State를 `:Set`) → 바깥 retractor 고아 | **② §4 Q5** — 체크리스트 5는 클로저 안 `Dispatch.process`·같은 키 `retractFrom`을 금지하고 `Bookkeeping.luau`는 "재진입 family"를 UB로 두는데, *간접* 재디스패치(`:Set` → StoreBind)가 그 문장에 없다. 권고: 게이트를 넣지 않고 UB family에 명시 |
| — | `Handlers/Property.luau` retractor `Void` | 순수 철거(`retracting = true`)가 활성 엔진 트윈을 Cancel하지 않는다(숏핸드 자식 `retractFrom` → `Destroy`, Slot 요소 extract) | **기각** — `tween-plan.md` "왜 `retract`가 더 이상 필요 없는가" 절이 Property retractor `Void`를 확정, "Destroy 무해"는 Studio 실측 항목(같은 문서 111행). extract된 요소의 잔여 트윈은 재마운트 시 분기 3이 Cancel |
| — | `Slot.luau` `Clear`/`ExtractAll` | 요소마다 recompute·native op(게이트 없음), `ExtractAll`의 `table.insert(out, 1, …)` O(n²) | **§4 Q3 ⑨**로 묶음(효율 — 관측된 병목 아님) |
| — | `Slot.luau` `prepareElements`, `gen-d.py` `SHORTHAND`·`reserved` | 구 앵글과 동일 발견 | 이미 `H-356` ①·⑦ |

**§4 추가 문항**

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **Q4** (`H-361`) | 실프로퍼티 키에 Observer/Effect/Ref 핸들을 넣은 오용의 진단 | (a) 그대로 — 타입이 1차 방어, 엔진 에러는 시끄럽다(정본 배너만) / (b) `PropertyHandler.isHandlable`이 핸들 브랜드를 거부해 FALLBACK 가드가 발화(핫패스에 브랜드 검사 셋) / (c) 가드 우선순위를 NORMAL 위로(정본 "FALLBACK" 설계 역전) | **(a)** — "드문 오용 방어에 구조를 쓰지 않는다"; `Ref`에 가드가 없는 것도 같은 결 |
| **Q5** (process 재진입) | 같은 `(inst, k)`의 간접 재디스패치(`h.process` 도중 그 키의 State `:Set`) | (a) UB family에 명시(문서) / (b) `process`에 재진입 게이트(새 메커니즘) | **(a)** |
| **Q3 ⑨** | `Slot:Clear`/`ExtractAll` 게이트 묶음 + `ExtractAll` 역순 insert | (a) 반영 / (b) 보류 | **(b)**, 단 `ExtractAll`의 `out[i] = …` 정순 채움은 한 줄이라 ①급 — 사용자 판단 |
| **Q6** (2순회 `H-376`) | 정본이 약속한 **native* 조합 폴백이 코드에 없다** — `slot-plan.md` "기본 구현(조합 폴백) — 미주입이 에러가 아니다" 절(`nativeRemove` = `nativeExtract` + `nativeDispose` 반복, `nativeMove` = `nativeExtract` + `nativeInsert`, `nativeSwap` = `nativeMove` 2회, "백엔드는 이득 있는 것만 덮어쓴다")과 `architecture.md` EngineOps 줄이 그렇게 서술하는데 `Slot.luau`는 `module.nativeMove`/`nativeSwap`/`nativeRemove`를 직접 부를 뿐 합성이 없다(`Quad.New()` 실측 `nativeDispose: nil`). 잠복 — in-tree 백엔드 둘(roblox·mock)이 여섯 전부를 심는다. `nativeDispose`는 정본 어느 문장도 폴백/명확 에러 어느 쪽으로도 분류 안 함 | (a) 문장이 stale — 폴백 약속을 `slot-plan.md`/`architecture.md`에서 지우고 여섯 전부 "미주입이면 명확한 에러"로 통일(`H-373`이 심은 세 스텁과 한 몸 — `LifetimeHandle.luau` 스텁 여섯 추가) / (b) 약속 유효 — `Init`에서 미주입 op를 정본 공식대로 합성(디스패치 깊이의 새 합성 코드) | **(a)** — 관측된 필요 없음("관측된 문제에만 구조"), 셋째 백엔드가 실제로 나올 때 (b)를 열면 됨. 정본 문장이 걸려 있어 자율로 안 지움 |

## §6 0순회 — `/code-review high`, 반영분(`ba222e9..fb9435a`) diff 중심 (2026-09-07 01시대, 사용자 지시 "하나 더")

사용자: *"지금은 딱 하나 더 코드리뷰를 굴려도 될것 같아. 저 타이머 그대로 두고 하나 더 돌릴래?"*
(02:30 KST 타이머는 세션 한도 초기화 시점 — 그 뒤 순회는 §7부터). 8앵글 12건 → 생존 10, 기각 2, 미완 0.
검증자가 `luau-lsp`로 실재현. **전부 ①** — 그중 둘은 이 원장 `H-353`(메인이 새벽에 넣은 생성기
변경)의 **회귀**라 "수정분이 새 결함을 만든다" 규약의 실례.

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-362`** | `gen-d.py` 숏핸드 setter | `Field<number> \| Field<UDim>`로 쪼개니 변환 람다가 number 팔로 문맥 타이핑돼 `modifier-plan.md` 4절 `old` 관용구(UDim 반환·`typeof(old) == "UDim"` 분기)가 strict 거부 — `ba222e9`에선 통과하던 것 | 별칭 `SHF0 = FieldV<number> \| FieldV<UDim> \| Field<number \| UDim>`(값 팔 멤버별 + 변환 팔 전체 유니언 하나), 13자리에 실음. `spec.shorthandtypes` 양성. `typing-limits.md` 8.9 (3) 정정 |
| **`H-363`** | `gen-d.py` `PV73` | 멤버별 팔로 *대체*하며 전체 유니언 팔 `TweenData<number \| UDim>`이 빠져 `Tween({ Value = v })`, `v: number \| UDim` 거부(원장 `H-353`은 얻은 쪽만 기록) | 전체 팔 유지 + 멤버별 팔 *추가*(`PV73` 11팔). 팔 계산을 `pv_arms`/`union_members` 헬퍼 하나로(리뷰 8번 — 두 자리 복제 합침). `spec.shorthandtypes` 양성 |
| **`H-364`** | `gen-d.py` setter 이름 충돌 게이트 | `H-351`로 `Slot<T>`가 `NewChild`에 합류했는데 8.9 처방 2의 게이트가 Slot 함수 필드를 안 수확(잠복 — 지금 충돌 0) | 정규식을 함수 필드(`name: (`/`name: <`)로 좁히고 `Slot<T>` 추가. 비교: 잃은 이름은 옛 정규식의 오탐(파라미터 이름 `name`/`setup`/`state` 등) 다섯뿐, Slot 메소드 12개 획득. 데이터 필드 `Offset`은 실제 setter(UIGradient)라 좁힌 정규식이 필수 |
| **`H-365`** | `Bookkeeping.luau` `ensureBase` | `H-350`이 넣은 클로저가 `getOffsetAt` 호출마다 할당(recompute 자리마다 — 길이 변경당 N개) | Init 스코프 `ensureBase(bk, ownerKey)`로(`contribution` 관용구) |
| **`H-366`** | `dispatch-core-plan.md` 배치 4항, `slot-plan.md` raw* 규약 3 범위 문장 둘 | `H-360` 정정이 표 행만 고치고 같은 파일의 "`rawExtract`류"·slot-plan의 "다섯 함수 전부"·"교체 형태 = rawReplace" 문장을 남겨 교체 형태가 여전히 `minPos - 1`로 읽힘 | 세 자리 정정(교체 형태는 규약 3 밖) |
| **`H-367`** | `Store.luau` | `H-347`이 `Of`의 두 검사를 메시지만 바꿔 복제 — `H-347` 자체가 두 문이 갈라져 난 결함 | `checkKey(name, what)` 하나로 두 문 통일(순수 술어 공유 — "하나가 두 일" 규칙이 허용하는 종류) |
| — | `Property.luau` 헤더 | `H-352` 인용 절 번호 5절 → 6절 | 정정 |
| — | `spec.tag`·`spec.attribute` | `H-344` `Removed(nil)`·`H-345` `Attribute(Ref)` 단언이 `not pcall`뿐이라 회귀 커버리지 없음 | 메시지·blame 단언으로 강화 |

기각 둘(리뷰어 자체): `Slot<Instance>` 팔이 `Slot<TextLabel>`을 막는다(실측 반박 — children 자리에선 `T`가
강제되지 않아 통과; 정본 관용구 `Slot<Instance>` 단일), `State<number \| UDim>` 팔 소실(실측 반박 — 통과).
확인: gen-d Enum 정확 형은 596 Enum·생성 D의 53 Enum 전부 통과, `Slot.luau` `require("./Dispatch")` 순환 없음,
`Tag:Removed` 유효 입력 전부 옛 동작 동일, Attribute plain 가드는 브랜드 분기 뒤라 정당 입력 무영향.

## §7 1순회 — `/code-review high`, 오늘 커밋 셋(`ba222e9..32345eb`) diff 중심 (2026-09-07 02:30 KST 타이머 기상)

사용자 지시(*"KST 기준 2시 30분에 다시 코드리뷰 해줄래 … 세번 정도 순회"*)의 첫 순회. 8앵글 후보 21건 → 병합·기각 후
8건(HIGH 1·MEDIUM 1·LOW 6), 미완 0. **전부 ① — 새 문항 없음**(HIGH의 "완전한 교차 패키지 브랜드 술어"는 필요 없어졌다,
아래 `H-368`). 리뷰어 자체 기각 7(전체 유니언 `State<number | UDim>` 팔 죽은 팔 설 — §6가 실측 반박, `checkKey` `what` 인자·
SHF 원시 팔 중복 — 순수 스타일, `ensureBase` 호출·`Tag:Removed` 임시 테이블 — 콜드 경로, 날짜 마커 둘, C3 흡수).

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-368`** (HIGH) | `Attribute.luau` `flattenArg` plain 분기 | `H-345` 가드가 `getmetatable == nil`만 봐서 **브랜드는 메타테이블이 아니라** 메타테이블 없는 quad 값이 여전히 필드 단위로 펼쳐졌다 — 메인 실측: `Attribute(AttributeKey("Selected"))` → `{ Name = "Selected" }`, `Attribute({ Foo = function })` 통과(엔진 `setAttribute` 안 디스패치 깊이에서 에러). 주석이 닫았다고 주장한 사고의 절반 | quad-base가 이름 아는 메타테이블 없는 브랜드 둘(`isAttributeKey`/`isMapperDescriptor`)을 분기 조건에서 제외 + 값이 함수면 `errorBeforeNearest`(attribute-plan: 값은 raw T \| State). 리뷰어가 ②로 본 "quad-roblox 브랜드(OnChange 디스크립터)까지 아는 교차 패키지 술어"는 **불필요** — 그 디스크립터는 `{ Name, Callback }`이라 함수 값 검사에 걸린다; 새 술어를 만들지 않는다(메타테이블 없는 quad-roblox 값이 늘면 그때 재개봉). `spec.attribute` 1b 음성 둘 + 양성. `attribute-plan.md` 주석 |
| **`H-369`** (MEDIUM) | `gen-d.py` setter 충돌 게이트 | `H-364` 정규식이 `re.M` 없이 돌아 `^`가 본문 시작만 매칭 — 주석 줄 뒤 필드는 수확 안 됨. 메인 재현: `State<T>`에서 `With`만 수확(+ 파라미터 오탐 `factory`/`fn`/`__apply`), `Compute`/`Observer`/`Gate`/`Apply` 누락 — 8.9가 말하는 재귀 함수 필드 그 자체. 옛 정규식부터 같은 앵커였던 잠복 결함 | `re.M` 추가(`(?:^\|[{,])` 앵커는 유지 — 한 줄에 둘 이상도 수확). 재수확: +`Compute`/`Gate`/`Observer`, −오탐 셋. 재생성 diff 0, 충돌 0. `typing-limits.md` 8.9 처방 2를 생성기와 동형으로(`H-372`) |
| **`H-370`** (LOW) | `LifetimeHandle.luau` 스텁 다섯 | `H-348`이 일괄 `errorBefore`로 바꿨는데 근거(디스패치 깊이)는 `bindLifetime`류에만 성립 — `canBound`/`canExecute`는 이 파일 헤더가 "handler authors call directly, like isState"로 규정한 직접 호출 프리미티브고 실 백엔드는 raise 자체가 없다. 스텁은 스스로 SURFACE 태그라 `errorBefore`면 최외곽 태그 프레임(핸들러) 바깥의 `drive` 호출 줄을 blame | `notInstalled(name, raise)` — `canBound`/`canExecute`는 `errorBeforeNearest`(핸들러 작성자 자기 줄), `bindLifetime`/`unbindLifetime`/`onDestroying`은 `errorBefore`. 정본은 `ErrorNamespace.luau` 헤더(직접 호출·계약 에러 = nearest / 래퍼를 타넘어야 하는 에러 = outermost). `spec.lifetime` 1b — SURFACE 태그 래퍼로 둘을 구분 단언. 원장 `H-348` 행에 포인터 |
| **`H-371`** (LOW) | `dispatch-core-plan.md` `getOffsetAt` 의사코드 | 재시작 분기가 정의 없는 `ensureBase()`를 부르고 진입부는 인라인 — `H-350`(클로저)·`H-365`(Init 스코프 두 자리) 어느 쪽과도 불일치. `H-350`이 "spec 없이 의사코드만"이라 이게 유일한 검증 산출물 | `local function ensureBase(bk, ownerKey)`를 함수 위에 두고 진입부·재시작 둘 다 그 호출로 — `Bookkeeping.luau`와 동형 |
| **`H-372`** (LOW) | `typing-limits.md` 8.9 처방 2 | 게이트 정의가 `H-364` 이후 생성기와 갈라짐 — `Slot` 없음, "키"라 적혀 함수 필드로 좁힌 것(데이터 필드 `Offset` 제외가 UIGradient setter를 살리는 핵심)이 정본에 없음, "충돌 0"은 날짜 없는 시한부 | `Slot` + 함수 필드 + 날짜 + `H-364`/`H-369` 경위 한 문단, 소스는 생성기 게이트 블록으로 |
| — | `spec.shorthandtypes` 헤더 | `PVn` 5팔 서술이 `H-353`/`H-363` 이후 stale(같은 커밋이 본문만 강화) | 11팔·`SHF0`·8.9 (3) 포인터 |
| — | 이 원장 §1 `H-353` 행 | 처리란이 "9팔·`Field<number> \| Field<UDim>`" 현재형 — §6가 뒤집었는데 포인터 없음(라이브 코퍼스에 9팔 vs 11팔 공존) | "→ §6 `H-362`/`H-363`으로 정정" 구절 |
| — | `todos.md` 00번 | "§1·§5의 ① 갈래(`H-344`~`H-360`)"가 `fb9435a` 시점에 멈춤 — `32345eb`의 §6 미반영 | §1·§5·§6·§7(`H-344`~`H-372`)로 |

다음 순회(2순회 — opus general-purpose 전체 리뷰, 다른 축)는 §8부터, `H-373`부터.

## §8 2순회 — opus general-purpose 전체 트리, 다른 축(spec 커버리지·에러 계약·GC·mock↔실 프로바이더) (2026-09-07 03시대 KST)

4건(MED 3·LOW 1), 미완 0 — ① 셋 반영, ② 하나는 §4 **Q6**. 축 C(GC)는 실재현(`Destroy` → 참조 폐기 → `collect` 2회 →
weak 관측)으로 `H-229` 섬 계약·Bookkeeping "Blocker는 ownerKey를 안 잡는다" 둘 다 성립 확인, 잔존은 테스트 청크 레지스터·
스펙 로컬 클로저 업밸류라 누수 아님. 축 B 전수(`Err.*` 100여 곳)는 `H-348`/`H-349`/`H-370` 뒤라 아래 `H-375` 하나. 축 A
지정 타깃(OnChange 초기값·`Override` 두 값·Claim/Mapper)은 `spec.events` 4·5절·`spec.tweenproperty` 3·4절·`spec.claim`이
이미 단언 — 공백 아님. 리뷰어 자체 기각 6(Modifier.flatten 해시 스캔·Property 3-상태 retract·mock SetAttribute 관용·
InstanceShorthand State 언랩 순서·`Tag:Added` 해시 테이블·`H-229`).

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-373`** (MED) | `LifetimeHandle.luau` 스텁 | 정본이 "조합 불가 → 미주입이면 명확한 에러"로 분류한 넷(`architecture.md` EngineOps 줄, `slot-plan.md` "기본 구현(조합 폴백) — 미주입이 에러가 아니다" 절: `isInst`/`onDestroying`/`nativeFindChild`/`nativeClaim`) 중 **`onDestroying`만 스텁이 있었다** — 프로바이더 없는 `Quad.New()`에서 `Slot:Add` → `Slot.luau:52 attempt to call a nil value`(quad 내부 blame), `Claim` → `Claim.luau:80` 같은 꼴. `addTag`/`setAttribute`는 같은 계약을 스텁으로 지키는 중 | 셋을 `notInstalled(name, raise)`로 — `isInst`는 직접 호출 술어라 `errorBeforeNearest`(`H-370` 기준), `nativeClaim`/`nativeFindChild`는 `Claim.resolve` 깊이라 `errorBefore`. `if nil` 가드(프로바이더가 먼저 심었을 수 있음). `spec.lifetime` 1절 목록 여덟·1b 깊이 구분에 합류 |
| **`H-374`** (MED) | `mock.luau` `mockProvider` | 자기 주석이 인용한 계약(`H-305` (d′) "전부 같은 형태", `H-294` "mock 또한 하나의 백엔드")을 어김 — 실 프로바이더가 심는 `nativeClaim`/`nativeFindChild` 둘을 안 심어 mock 백엔드에선 `q.Claim`이 불가(위 nil-call). 커버리지는 `spec.claim`(실 프로바이더)이 채우고 있어 결함은 mock↔실 불일치 자체 | `installNative`에 `nativeFindChild = inst:FindFirstChild(key)`(EngineOps와 동형), `mockProvider`에 명시 `nativeClaim`(mock 인스턴스 검사 + **이중 claim 에러** — 실 프로바이더 §7-10 계약과 동형; 내부 lazy `claim`은 멱등 그대로). `setFuncLevel` 합류. `spec.lifetime` 9절 — FindFirstChild 동형·이중 claim blame·mock 아래 `Claim` 해석(자식 키 → claim) |
| **`H-375`** (MED) | `Slot.luau` `wrapElement` | 요소 타입 게이트 넷이 전부 `errorBefore`(최외곽)인데 호출부 둘의 깊이가 다르다 — `prepareElements`(직접 공개 CRUD·`Slot{}`)와 `settle`(reconcile 깊이). 반응형 콜백 안에서 직접 CRUD를 부르면 `Slot_mt.Add`를 타넘어 **에러 없는 `:Set`/`:Subscribe` 줄을 blame**(실재현: 실수 33행, blame 40행). 두 줄 아래 형제 검증("appears twice"/"already mounted")은 `errorBeforeNearest`라 같은 상황에서 정확 — 같은 함수, 같은 입력 클래스, 다른 blame. spec은 최상위 직접 호출(`spec.slot` 427·689)과 dispatch 깊이(151)만 봐서 두 층이 같은 파일에 떨어져 안 보였다 | `wrapElement(v, raise)` — `H-370`과 같은 모양: `prepareElements` → `errorBeforeNearest`, `settle` → `errorBefore` 유지(둘 다 바꾸면 `spec.slot` 151의 reconcile 깊이 단언이 깨진다). `spec.slot` 22절 (e) — Observer 콜백 안 `Add(nil)`이 자기 줄을 blame |
| **`H-376`** (LOW, ②) | `Slot.luau` native* 호출부 / `slot-plan.md`·`architecture.md` | 정본이 약속한 native* 조합 폴백 부재(잠복) | **§4 Q6** — 권고 (a) 정본 문장 철회 + 스텁 여섯. 코드 변경 없음 |

다음 순회(3순회 — `/code-review high` 전체 트리)는 §9부터, `H-377`부터.

