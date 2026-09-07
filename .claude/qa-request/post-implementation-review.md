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
| **`H-348`** | R1-4 | `quad-base/src/LifetimeHandle.luau` 미설치 스텁 | 지배적 발화 지점이 디스패치 깊이(`process` → `bindLifetime`)인데 `errorBeforeNearest` — 체크리스트 0의 실패 모드. 실 백엔드(`quad-roblox/src/LifetimeHandle.luau`)는 `errorBefore` | `errorBefore`로 통일 → §7 `H-370`이 둘을 nearest로 정정 → **§9 `H-378`이 `errorBefore` 통일로 복원**(이 행이 최종) |
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
| **Q7** (3순회 `H-378`) | 미설치 스텁의 blame — 스텁이 자기를 SURFACE로 태그(`H-231`)해 `errorBeforeNearest`면 항상 스텁의 직접 호출자(in-tree = quad 내부)를 찍는다. 지금은 전부 `errorBefore`(최외곽)로 복원 — 핸들러 작성자가 자기 핸들러 안에서 `canBound(v)`를 부른 경우만 `drive` 호출 줄을 blame | (a) 그대로(`errorBefore`, 관측된 in-tree 경로 전부 사용자 줄) / (b) 스텁을 **무태그**로 두고 nearest — 공개 메소드 안이면 그 메소드의 호출자, 핸들러 안이면 핸들러 자기 줄(이상적) — 단 태그 프레임이 하나도 없는 직접 호출에서 quad-error의 폴백 동작 확인 필요·`H-231` "스텁은 표면" 규약 수정 | **(a)** — 셋업 1회성 에러, "드문 오용에 구조 안 씀" |
| **Q8** (3순회 `H-379`) | `quad-roblox/src/Animate.luau` Compute에 nil/None 팔이 없어 **애니메이트된 프로퍼티를 해제할 수 없다**: `:Set(None)` → `Tween{ Value = None }`(validate는 `== nil`만) → `NoneHandler` 불발 → 활성 트윈 취소 뒤 `TweenService:Create(inst, info, { [k] = None })` 엔진 에러(`H-103` NOOP 잔존) 또는 첫 분기면 `inst[k] = None` 센티널 직접 기록; `:Set(nil)` → `Animate.luau:73 "Tween: Value is required"`(recompute 깊이). 실재현 셋(spec.tweenproperty 심). `tween-plan.md` "`Animate` 콤비네이터 — 확정" 의사코드에 None 팔 없음(침묵) — Property 헤더 계약 "`v == nil` … SKIPS the write"와 어긋남 | (a) Compute에 통과 팔 `if v == nil or v == None then return v end`(`CanAnimate = false` 평문 반환 선례 — 정본 의사코드에 한 줄 추가) / (b) 문서화 UB(Animate 아래 값은 해제 불가) | **(a)** — 정본 의사코드 변경이라 사용자 확인; 코드 변경 없음 |
| **Q9** (4순회 `H-382`) | 물리 마운트 대상이 `Destroy`된 Slot의 **좀비**: `s._mounted = true`·`_mountedInst`가 시체를 강참조한 채 `dispose(s)` → "still requires its tree to be alive — Remove/Extract it first", 다른 곳에 `Add(s)` → "already mounted elsewhere"(둘 다 사실과 반대인 메시지). 반대 방향: 부모 Destroy 뒤 nested `Extract`/`retractFrom`으로 풀려난 시체 요소가 산 부모에 조용히 마운트(mock), 실물은 `nativeInsert`의 `Parent =`가 `claimOwnerAt`·`bindLifetime`·`materializeSlotTree` 커밋 뒤 raise → 반쯤 마운트 + `H-103` NOOP 잔존. `slot-plan.md` "부수 효과 — 이미 파괴된 대상에 재마운트하려는 시도가 자연히 막힘" 절이 현재형으로 단언한 요소 단위 `bindLifetime`+`canExecute` 게이트가 구현된 적 없음(`Slot.luau`의 `canExecute` 호출 0) — 검증자 mock 재현 3경로. 실물 `nativeExtract`가 파괴 요소에 raise하는지는 Studio 미실측 | (a) 정본대로 요소까지 `bindLifetime` + 물리 op 직전 `canExecute`(새 부기, `elementOwner`와 이원화) / (b) 정본 두 문장 철회 + "막히는 게 정상이다" UB를 부모 Destroy 방향으로 확장 + 반사실 메시지 둘 정정 / (c) 최상위 Slot에 이미 걸린 `canExecute`만 `dispose`·재마운트 게이트가 소비(새 부기 0, 좀비 탈출만 닫음) + (b)의 문서·메시지 정정 | **(c)+(b)** — 리뷰어 권고 그대로; (a)는 "관측된 문제에만 구조" 위반 |
| **Q10** (4순회 `H-383`) | `AddPlugin`이 `UseProvider`와 시그니처·`mergeExtension`을 공유하면서 락이 없어 프로바이더 팩토리를 두 번째로 적용할 수 있다 — `q:UseProvider(QuadRoblox); q:AddPlugin(QuadRoblox)` 에러 0, quad-roblox `LifetimeHandle`이 `InstData`/`BindData` Relate를 새로 만들어 이미 claim/bind된 것이 전부 안 보임(`canBound` 뒤집힘·이중 claim 가드 무력·핸들러 22→27 중복). `H-305` (d′)가 락을 base로 옮긴 이유였던 `H-294` 구멍의 재개봉. `RobloxFactory.luau` 헤더는 직접 호출 경로만 UB로 서술 | (a) 프로바이더 팩토리 자기 마커 + `AddPlugin` 거부(새 표면) / (b) `AddPlugin`이 `providerRelate`를 봐서 프로바이더가 이미 있으면 거부(`UseProvider` 선행 순서만 잡음, 역순 `AddPlugin(provider); UseProvider(foreign)`은 못 잡음) / (c) 정본·헤더에 `AddPlugin(provider)` UB 명시(문서만) | **(c)** 우선 — 관측된 오용 없음; 같은 뿌리의 둘째 증상(부분 변경 뒤 throw한 팩토리의 재시도 중복)은 ① 문서로 닫음(`module-lifecycle-plan.md` `H-307` 문단, `spec.robloxfactory` 주석) |
| **Q11** (4순회 `H-387`) | Modifier `construct`는 초기 필드 테이블의 비문자열 키를 거부하는데(`H-310` 규칙) 제네릭 `__index` setter는 키 타입을 안 봐 `m[AttributeKey](m, v)`가 통과·flatten·drive까지 된다(실재현: drive 뒤 attribute Hp=5) — `H-310`이 함수 값을 거부한 근거("두 생성 경로가 조용히 갈린다")가 키에 그대로 성립. `H-310` 규칙 자체가 뒤집기 가능한 에이전트 추가 | (a) setter에도 같은 키 검사(문자열만; 비문자열 키는 `[AttributeKey] = v` 원시 경로로 안내) / (b) `construct`가 AttributeKey 키를 받아들임 + 타입 표면 확장 / (c) 문서만(두 경로가 다름을 명시) | **(a)+(c)** 문구 — 리뷰어 권고 |
| **Q12** (4순회 `H-391`) | Property Tween 분기(3-상태 분기 3)는 값 동등성을 안 봐 `H-68` 동일값 재발행이 활성 트윈을 Cancel하고 보간 현재 위치에서 `Time` 전량으로 재시작(mock 재현: creates=2, cancels=1). 소스가 `Time`보다 잦게 재발행하면 영원히 수렴만 하고 미도달. `Animate`의 `:Compute`가 recompute마다 새 `Tween{}` 테이블을 만들어 신원 dedup 무용. 정본은 이 경우에 침묵(`tween-plan.md` "3-상태 저장" 분기 3 동일값 언급 0; `source-state-plan.md`는 접는 책임을 "하류"로) | (a) 그대로 + 분기 3에 "동일값 재발행도 취소+재시작" 한 줄(코드 0) / (b) `v.Value == prev.Value`면 재시작 생략 — 완료 후 같은 목표 재트리거가 죽어 "Completed 미구독 확정"과 충돌 / (c) 접는 책임을 `state:Gate`/사용자로 명시(문서) | **(a)** — 리뷰어 권고. `Reverses = true` 캐비엇은 ① 한 줄로 반영(tween-plan) |
| **Q13** (5순회 `H-392`) | `Dispatch.setOffsetSource(owner, i, source)`의 `source` 타입 게이트 — 지금은 None이 아니면 `:Get()`을 부를 뿐(잘못된 값은 nearest가 아니라 `Bookkeeping.luau` 내부 줄을 blame). 쓰기 순서(읽기 → 쓰기)는 `H-392`로 닫힘 | (a) 그대로(제3자 말단 핸들러 표면, in-tree 도달 불가) / (b) `Brand.isSource(source) or source == None` 게이트 + nearest(`checkPosition` 형제) | **(b)** — 한 줄, `H-256` 게이트 셋과 같은 결 |
| **Q14** (5순회 `H-393`) | `destroySlotTree`의 두 루프(`_elements`·`_detached`)가 `releaseOwner` 없이 요소를 버린다 — 요소가 `Owned = false` Slot이면 `destroySlotTree`가 조기 반환해 `_destroyed`도 안 찍히므로 살아 있는 사용자 Slot이 죽은 `elementOwner`를 영구히 단다(`releaseElement` 쪽은 `H-393`으로 닫음). 정본 C-4 면제 "단, `destroySlotTree`는 이 규칙의 대상이 아니다"(사용자 확정)의 전제 "요소가 어차피 죽는다"가 Owned=false 요소엔 불성립 | (a) 두 루프에도 `releaseOwner`(C-4 면제 문장 정정) / (b) 면제 유지 + `dispose(list)`/`Remove` 뒤 Owned=false 자식은 재마운트 불가를 UB로 문서화 | **(a)** — 관측된 결함(mock 재현), 한 줄씩 |
| **Q15** (5순회 `H-394`) | `setLength`의 `len` 도메인 무검사 — 음수·소수 상수/State는 오프셋 산술로 조용히 흘러 `nativeInsert(target, 음수)`, 비숫자 State는 recompute 안 산술 에러로 `recomputeBlocker` 영구 잠김(`H-256`이 막으려던 조용한 UB). 정본에 도메인 서술 0, 합법 도메인은 0 포함 비음수 정수(`checkPosition` 복사 불가), State 팔은 등록 시점엔 못 잡음(`:Get()` 값 검사 자리 = `contribution`) | (a) 상수는 등록 시 검사 + State는 `contribution`에서 검사(핫패스 한 비교) / (b) 상수만 / (c) UB 문서화 | **(a)** — round12 `H-256` 선례 |
| **Q16** (5순회 `H-398`) | `Tween.validate`가 `Value`를 `== nil`로만 봐 State/Source 값을 거부 안 함 — 정본 "`Tween{...}`의 모든 필드는 plain 값만 받음" 불변식이 Tween 경계에서 미집행(타입드 문 `Mapped`로도 통과). 엔진 도달은 무타입 문 필요 → Property가 State 테이블을 엔진에 씀 → `H-103` NOOP 잔존 | (a) 그대로(Q4 (a) 결) / (b) `validate`에 `isState(opts.Value)` 거부 한 줄(`H-122` 화이트리스트 선례) | **(b)** — 생성 시점 한 줄, 엔진 무관 |
| **Q17** (5순회 `H-402`) | `InstanceShorthand.luau`의 다섯째 필드 `numberOnly`가 정본 `ui-shorthand-plan.md` "메커니즘 — 새 아키텍처 개념 불필요" 절의 네 필드 표에 없고 round20 원장에도 없다 — `UIPaddingOffset`/`UIScale`만 게이트, `UIPadding = 5`/`UICorner = "abc"`는 무검사 통과(mock). 에이전트 추가 메커니즘이 승인된 것처럼 앉은 모양(2026-08-27 규약) | (a) `numberOnly` 제거(Q4 (a) 결 — 타입이 1차 방어) / (b) 유지 + 정본 표 등재 + 나머지 두 키도 결정 | **(a)** — 관측된 필요 없음 |
| **Q7 둘째**(5순회 `H-394`… 정정: `H-399`) | `_assertBindable`(Observer/Effect)의 방향 — 4순회 `H-384`가 `errorBefore`로 바꿨는데 이 가드는 `_running`일 때만 발화하는 **재진입 가드**라 quad-error 헤더("reentry guards → Nearest")·effect-plan "level 3"·lifecycle-pattern과 어긋남. 합성 실측: 디스패치 깊이에선 어느 방향도 정확하지 않고(nearest = `process` 줄, outermost = 바깥 공개 메소드 줄), 직접 `bindLifetime` 경로에선 nearest 정확·outermost 회귀. 형제 가드(`Subscribe`류)는 nearest라 같은 오용이 진입점마다 다른 blame | (a) 지금(outermost) 유지 + 정본 두 문장 정정 / (b) nearest 복원(정본대로; 디스패치 깊이에선 `process` blame) / (c) `H-370`식 raise 인자 — 호출자(`bindLifetime`)가 깊이를 알 수 없어 실질 불가 | **(a)** — 사용자 코드 줄이기는 하다(오용 콜백을 돌린 호출); 정본은 배너로 보류 표시 완료 |
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
| **`H-368`** (HIGH) | `Attribute.luau` `flattenArg` plain 분기 | `H-345` 가드가 `getmetatable == nil`만 봐서 **브랜드는 메타테이블이 아니라** 메타테이블 없는 quad 값이 여전히 필드 단위로 펼쳐졌다 — 메인 실측: `Attribute(AttributeKey("Selected"))` → `{ Name = "Selected" }`, `Attribute({ Foo = function })` 통과(엔진 `setAttribute` 안 디스패치 깊이에서 에러). 주석이 닫았다고 주장한 사고의 절반 | quad-base가 이름 아는 메타테이블 없는 브랜드 둘(`isAttributeKey`/`isMapperDescriptor`)을 분기 조건에서 제외 + 값이 함수면 `errorBeforeNearest`(attribute-plan: 값은 raw T \| State). 리뷰어가 ②로 본 "quad-roblox 브랜드(OnChange 디스크립터)까지 아는 교차 패키지 술어"는 **불필요** — 그 디스크립터는 `{ Name, Callback }`이라 함수 값 검사에 걸린다; 새 술어를 만들지 않는다(메타테이블 없는 quad-roblox 값이 늘면 그때 재개봉). `spec.attribute` 1b 음성 둘 + 양성. `attribute-plan.md` 주석 → **§9 `H-377`**: 같은 구멍이 Modifier `isPlainFieldTable`에도 있었다 — 술어를 `Brand.isPlainBranded`로 공유 |
| **`H-369`** (MEDIUM) | `gen-d.py` setter 충돌 게이트 | `H-364` 정규식이 `re.M` 없이 돌아 `^`가 본문 시작만 매칭 — 주석 줄 뒤 필드는 수확 안 됨. 메인 재현: `State<T>`에서 `With`만 수확(+ 파라미터 오탐 `factory`/`fn`/`__apply`), `Compute`/`Observer`/`Gate`/`Apply` 누락 — 8.9가 말하는 재귀 함수 필드 그 자체. 옛 정규식부터 같은 앵커였던 잠복 결함 | `re.M` 추가(`(?:^\|[{,])` 앵커는 유지 — 한 줄에 둘 이상도 수확). 재수확: +`Compute`/`Gate`/`Observer`(오탐 `factory`/`fn`/`__apply`는 `re.M`으로는 **안 빠진다** — 매치 추가만; **§9 `H-381`** depth-0 스캐너가 실제로 제거). 재생성 diff 0, 충돌 0. `typing-limits.md` 8.9 처방 2를 생성기와 동형으로(`H-372`) |
| **`H-370`** (LOW) | `LifetimeHandle.luau` 스텁 다섯 | `H-348`이 일괄 `errorBefore`로 바꿨는데 근거(디스패치 깊이)는 `bindLifetime`류에만 성립 — `canBound`/`canExecute`는 이 파일 헤더가 "handler authors call directly, like isState"로 규정한 직접 호출 프리미티브고 실 백엔드는 raise 자체가 없다. 스텁은 스스로 SURFACE 태그라 `errorBefore`면 최외곽 태그 프레임(핸들러) 바깥의 `drive` 호출 줄을 blame | `notInstalled(name, raise)` — `canBound`/`canExecute`는 `errorBeforeNearest`(핸들러 작성자 자기 줄), `bindLifetime`/`unbindLifetime`/`onDestroying`은 `errorBefore`. 정본은 `ErrorNamespace.luau` 헤더(직접 호출·계약 에러 = nearest / 래퍼를 타넘어야 하는 에러 = outermost). `spec.lifetime` 1b — SURFACE 태그 래퍼로 둘을 구분 단언. 원장 `H-348` 행에 포인터 → **§9 `H-378`로 되돌림**(스텁이 자기를 태그하므로 nearest = 스텁의 직접 호출자 = in-tree에선 quad 내부 — `Observer.luau:139`/`Slot.luau:52` blame 회귀; 전부 `errorBefore` 복원, "핸들러 작성자 자기 줄"은 §4 Q7) |
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
| **`H-373`** (MED) | `LifetimeHandle.luau` 스텁 | 정본이 "조합 불가 → 미주입이면 명확한 에러"로 분류한 넷(`architecture.md` EngineOps 줄, `slot-plan.md` "기본 구현(조합 폴백) — 미주입이 에러가 아니다" 절: `isInst`/`onDestroying`/`nativeFindChild`/`nativeClaim`) 중 **`onDestroying`만 스텁이 있었다** — 프로바이더 없는 `Quad.New()`에서 `Slot:Add` → `Slot.luau:52 attempt to call a nil value`(quad 내부 blame), `Claim` → `Claim.luau:80` 같은 꼴. `addTag`/`setAttribute`는 같은 계약을 스텁으로 지키는 중 | 셋을 `notInstalled`로 — 깊이는 처음 `isInst`만 nearest였으나 **§9 `H-378`**로 셋 다 `errorBefore`(스텁 자기 태그 문제, 위 `H-370` 행). `if nil` 가드(프로바이더가 먼저 심었을 수 있음). `spec.lifetime` 1절 목록 여덟·1b 깊이 구분에 합류 |
| **`H-374`** (MED) | `mock.luau` `mockProvider` | 자기 주석이 인용한 계약(`H-305` (d′) "전부 같은 형태", `H-294` "mock 또한 하나의 백엔드")을 어김 — 실 프로바이더가 심는 `nativeClaim`/`nativeFindChild` 둘을 안 심어 mock 백엔드에선 `q.Claim`이 불가(위 nil-call). 커버리지는 `spec.claim`(실 프로바이더)이 채우고 있어 결함은 mock↔실 불일치 자체 | `installNative`에 `nativeFindChild = inst:FindFirstChild(key)`(EngineOps와 동형), `mockProvider`에 명시 `nativeClaim`(mock 인스턴스 검사 + **이중 claim 에러** — 실 프로바이더 §7-10 계약과 동형; 내부 lazy `claim`은 멱등 그대로). `setFuncLevel` 합류. `spec.lifetime` 9절 — FindFirstChild 동형·이중 claim blame·mock 아래 `Claim`(루트 claim). 3순회 주: "already claimed" 마커가 lazy claim과 공유라 `bindLifetime` 뒤 `Claim`은 실 프로바이더의 "not claimed" 대신 "already claimed" — 유효 프로그램 무영향, 주석으로 명기 |
| **`H-375`** (MED) | `Slot.luau` `wrapElement` | 요소 타입 게이트 넷이 전부 `errorBefore`(최외곽)인데 호출부 둘의 깊이가 다르다 — `prepareElements`(직접 공개 CRUD·`Slot{}`)와 `settle`(reconcile 깊이). 반응형 콜백 안에서 직접 CRUD를 부르면 `Slot_mt.Add`를 타넘어 **에러 없는 `:Set`/`:Subscribe` 줄을 blame**(실재현: 실수 33행, blame 40행). 두 줄 아래 형제 검증("appears twice"/"already mounted")은 `errorBeforeNearest`라 같은 상황에서 정확 — 같은 함수, 같은 입력 클래스, 다른 blame. spec은 최상위 직접 호출(`spec.slot` 427·689)과 dispatch 깊이(151)만 봐서 두 층이 같은 파일에 떨어져 안 보였다 | `wrapElement(v, raise)` — `H-370`과 같은 모양: `prepareElements` → `errorBeforeNearest`, `settle` → `errorBefore` 유지(둘 다 바꾸면 `spec.slot` 151의 reconcile 깊이 단언이 깨진다). `spec.slot` 22절 (e) — Observer 콜백 안 `Add(nil)`이 자기 줄을 blame |
| **`H-376`** (LOW, ②) | `Slot.luau` native* 호출부 / `slot-plan.md`·`architecture.md` | 정본이 약속한 native* 조합 폴백 부재(잠복) | **§4 Q6** — 권고 (a) 정본 문장 철회 + 스텁 여섯. 코드 변경 없음 |

다음 순회(3순회 — `/code-review high` 전체 트리)는 §9부터, `H-377`부터.

## §9 3순회 — `/code-review high` 전체 트리 (2026-09-07 03~04시대 KST, 야간 순회 마지막)

8앵글 후보 27 → 병합 12 → 검증자 9 배정·8 회신(Modifier 건 검증자 1 미회신 — 규약대로 새로 안 띄우고 메인이
앵글 셋의 독립 실재현으로 판정). 마지막 메시지가 중간 상태여서 같은 에이전트를 재개해 최종 목록을 받음(새 리뷰
아님). 8건: ① 여섯, ② 둘(Q7·Q8). 리뷰어 기각 9(Property `tweenSlots` inst 되참조 — C++ 포인터라 Lua 참조 아님
`audit/spike10` A-6·`Slot:List` reconcile raise의 Blocker 영구 On — `H6-21` 문서화 완료·`if nil` 가드 죽은 코드 —
선례 동일·`DModifier` `{[string]: any}` 팔 — modifier-plan 확정·mock `nativeClaim(destroyed)` — `H-293` UB·§9절 단언
비판별 — 주석 명기·lazy claim 비대칭 — 헤더 명문화·브랜드 손복제 드리프트 — `H-377`에 흡수·Bookkeeping/Dispatch/
온톨로지/타입↔런타임/GC 축 위반 0).

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-377`** (HIGH) | `Modifier.luau` `isPlainFieldTable` | `H-368`이 Attribute에만 닫은 "브랜드는 메타테이블이 아니다" 구멍이 Modifier에 그대로 — `Modifier(AttributeKey("Selected"))` → 필드 `{ Name = "Selected" }` → 적용 시 **조용히 rename**(에러 0); `Modifier(mapperDesc)` → `_mapper/_className/…` 병합 → 디스패치 "no handler matched key _className". 모든 `TypedFactory` 생성자가 같은 `construct` 본문. Attribute 주석의 "Modifier already closed"가 사실과 어긋났었다 | `Brand.isPlainBranded(x)`(= `isAttributeKey or isMapperDescriptor`) 하나를 Brand에 두고 Attribute·Modifier·Tag 셋이 공유(순수 술어 공유 — 규약 허용; 손복제 목록 드리프트 예방). `spec.modifier` 13절 음성 둘 + 양성 |
| **`H-378`** (MED) | `LifetimeHandle.luau` 스텁 깊이 | `H-370`/`H-373`의 `errorBeforeNearest`는 스텁이 **자기를 SURFACE로 태그**(`H-231`)해 nearest = 스텁의 직접 호출자 = in-tree에선 quad 내부(`Observer.luau:139` `Subscribe` → `canBound`, `Slot.luau:52` → `isInst`) — `32345eb`(전부 `errorBefore`)가 사용자 줄을 찍던 것의 **회귀**. `spec.lifetime` 1b는 합성 래퍼로만 검사해 통과 | 여덟 전부 `errorBefore`로 복원(`notInstalled(name)` 단일), `spec.lifetime` 1b — 여덟 최외곽 + in-tree 패턴 둘(`Observer:Subscribe`·`Slot:Add`)이 사용자 줄. "핸들러 작성자 자기 줄"은 **§4 Q7**. 교훈: 자기 태그 스텁엔 nearest가 성립하지 않는다 |
| **`H-379`** (MED, ②) | `quad-roblox/src/Animate.luau` Compute | nil/None 팔 없음 — 애니메이트된 프로퍼티 해제 불가(None이 엔진까지, nil은 recompute 깊이 raise) | **§4 Q8** — 권고 (a) 통과 팔. 코드 변경 없음 |
| **`H-380`** (MED) | `Tag.luau` `flattenInto` | table 분기가 `ipairs` 전용이라 Tag 값·Source·AttributeKey·해시 테이블이 **빈 목록으로 조용히 통과** — `Tag(tag)` 빈 Tag, `a:Added(Tag("x"))`/`a:Removed(Tag("x"))` 무변화, 에러 0. `H-344`는 원소 검증만 바꿨다 | `{string}` 리스트만: 메타테이블/`isPlainBranded` 값 거부(메시지가 `Tag.Merged` 안내), `pairs` 순회로 해시 키·비정수 키·비문자열 거부, `count ~= maxIndex`로 nil 구멍 거부. `spec.tag` 2절 다섯 모양 × 셋(Added/Removed/생성자) 음성 + 양성 → **§10 `H-389`**: 생성자는 이름(문자열)만(리스트는 `Added`로), 메타테이블 메시지는 Tag일 때만 `Merged` 힌트 |
| **`H-381`** (LOW, 잠복) | `gen-d.py` 게이트 수확 | 정규식은 중첩을 몰라 다중행 시그니처의 **파라미터 이름**을 필드로 수확(`fn`/`factory`/`__apply`/`keyFn`/`updateFn`) — 소문자 관례 덕에 무해, PascalCase 파라미터가 자기 줄에 오면 허위 충돌 `SystemExit` | 타입 본문의 depth-0 스캐너 `function_fields`(주석 제거 → `->` 건너뜀 → 괄호 깊이 0의 `Name: (`/`Name: <`만). 수확: `State` {Apply, Compute, Gate, Observer, With}, `Slot` 메소드 13 — 오탐 0. 재생성 diff 0. `typing-limits.md` 8.9 처방 2 문구 → **§10 `H-388`**: 주석 제거를 두 스캐너 앞 한 곳으로 + 끝 depth 검사 |
| — | 이 원장 §7 `H-369` 행 | "−오탐 셋"은 거짓(`re.M`은 매치 추가만) — 같은 행 증상란과 자기모순 | 정정 + `H-381` 포인터 |
| — | `mock.luau` `nativeClaim` | "already claimed" 마커를 lazy claim과 공유 — `bindLifetime` 뒤 `Claim`의 에러 궤적이 실 프로바이더("not claimed")와 다름, 유효 프로그램 무영향 | 주석 명기 + `H-374` 행 |
| — | `Attribute.luau` 주석 | "letting it through raised inside setAttribute"가 원시 `[AttributeKey] = fn` 경로(설계상 무타입, Q4 결)까지 닫힌 듯 서술 | 그룹 `Attribute(...)` 한정으로 좁힘 |

**야간 순회 종료** — 0~3순회 누계: 반영 ① 24건(`H-362`~`H-375`, `H-377`/`H-378`/`H-380`/`H-381` + 무번호 정정),
사용자 문항 ② 셋(Q6·Q7·Q8), ③ 없음. 매 순회가 직전 순회의 수정분에서 회귀를 하나씩 잡았다(`H-362`/`H-363` ← `H-353`,
`H-368`의 Modifier 짝 `H-377`, `H-378` ← `H-370`) — 다음 리뷰는 이 §9 커밋의 diff부터 볼 것.

## §10 4순회 — `/code-review high` 전체 트리, 파인더 5 fable + 5 opus·검증자 5 opus (2026-09-07 10~11시 KST, 주간)

사용자: *"지금 세션 한도 비어서 다시 순회 해도 돼. batch 아직 작아서 더 쌓고 있어볼래?"*. 첫 실행은 메인이 규약
지적(팬아웃)에 반응해 **묻지 않고 `TaskStop`**해 파인더 열 개(14만 토큰)를 날렸고 사용자 결정으로 같은 포크를
재개(경위·교훈은 `conventions.md` 2026-09-07 정정 항목 — 스킬 인자로 내부 서브에이전트 모델을 opus로 낮출 수 있음이
이 순회에서 실측됨). 10건: ① 여섯, ② 넷(Q9~Q12), 미완 0. 리뷰어 기각·확인 — `mergeExtension` nil 반환(타입 층이
잡음, 단 테스트 디렉토리 안 `luau-analyze`는 strict를 못 봐 조용히 통과하니 재개봉 주의), mock lazy claim 수용 차이
(헤더·`H-374`·§9 기각행 — 새 데이터: base spec 16파일·`Instance.new` 236곳이 lazy claim 의존), `isOnChange` 미설치
(`Dispatch/init.luau` "backend-added brands fall back to typeof" 설계), `Finish`/`Reverses` 코드 축(축자 구현),
quad-error 워커 (a)~(f)·Observer/Effect 순서·Store(lazy `__index`는 **더 이상 없음** — 지시문 전제 stale)·
UseProvider 버전 게이트·Slot 3단 중첩·Ref `:Wait`·retract 순서·Tween 상태 기계·85d2406 diff 회귀 0.

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-382`** (MED, ②) | `Slot.luau` dispose/재마운트 게이트 | 부모 Destroy 뒤 Slot 좀비 / 시체 요소 재마운트 통과 — 정본 "재마운트가 자연히 막힘"이 미구현 | **§4 Q9** |
| **`H-383`** (MED, ②+①) | `init.luau` `AddPlugin` | 프로바이더 락 우회(두 번째 적용) — `H-294` 재개봉 | **§4 Q10**; 부분 변경 뒤 throw 재시도 중복은 ① 문서(`module-lifecycle-plan.md` `H-307` 문단 — mutate-then-throw UB, `spec.robloxfactory` 주석) |
| **`H-384`** (MED) | `Observer.luau`/`Effect.luau` `_assertBindable` | `errorBeforeNearest`인데 유일한 in-tree 체인이 `process`(태그) → `bindLifetime`(백엔드 태그) → 여기라 nearest가 `bindLifetime`에서 멈춰 `Observer.luau:233`/`Effect.luau:321`을 blame — `H-378`의 일반형(태그된 중간 프레임 뒤의 nearest) | 둘 다 `errorBefore`(정본 의사코드의 도착지 "사용자 호출부"). `spec.observer`·`spec.effect`(둘 다 fn이 생성 시 즉시 돌아 생성 줄) blame 단언 → **§11 `H-399`**: 재진입 가드라 정본은 nearest — 방향은 §4 Q7 둘째 불릿(정본 두 문장에 보류 배너) |
| **`H-385`** (MED) | `Slot.luau` `Single` → `List` | `Single`이 자기 태그 + `self:List` 위임이라 `List`의 게이트 둘이 `Slot.luau:1032`를 blame(같은 입력 클래스가 슈거에 따라 다른 blame — `H-375` 패턴) | 게이트를 `checkListInstall(self)`로 빼 `Single` 진입부에서도 검사. `spec.slot` 13절 둘 → **§11**: 메시지가 `:List`만 지칭하던 것을 `:List/:Single`로 |
| **`H-386`** (MED) | `Slot.luau` 생성자 | `Slot(initial)`이 `_crudUsed` 잠금 뒤 `ipairs`만 돌아 `H-380` 컨테이너 구멍이 형제 진입점에 그대로 — 잊은 `{}`·quad 값·해시가 요소 0개로 통과하고 첫 증상이 나중의 "cannot install :List after manual CRUD"(한 번도 안 쓴 기능) | 컨테이너 모양만 게이트(비테이블·메타테이블·`isPlainBranded`·해시 키), nil 구멍은 slot-plan UB 유지. `spec.slot` 22b절 여섯 음성 + 양성 → **§11 `H-396`**: `[0]`/`[1.5]` 키(해시부)도 거부 |
| **`H-387`** (MED, ②) | `Modifier.luau` `__index` setter | 비문자열 키(AttributeKey)가 setter 경로로 통과 — `construct`와 갈림 | **§4 Q11** |
| **`H-388`** (LOW) | `gen-d.py` 두 스캐너 | `type_body`는 주석을 안 벗기고 `function_fields`는 벗기며 끝 depth 미검사 — 괄호 든 주석·문자열 리터럴 타입이 수확을 조용히 줄임(잠복) | 주석 제거를 `qt` 로드 직후 한 번(블록 \| 줄 alternation 하나), `function_fields`는 끝 `depth ~= 0`이면 `SystemExit`. 재생성 diff 0. `H-356` ⑦ 델타: 게이트 튜플은 `NewChild` 팔(Instance·None·ModifierMarker) 대비 2-홉 커플링 |
| **`H-389`** (LOW) | `Tag.luau` | `H-380` 잔여 셋 — (i) 메타테이블 메시지가 모든 메타테이블 테이블을 "quad value … Tag.Merged"로 오진 (ii) 생성자 varargs가 `{string}` 리스트를 받는데 타입 `...string`·정본 "가변인자"는 문자열만 (iii) `table.pack` 거부(필드 `n`) | (i) Tag일 때만 `Merged` 힌트, 나머지는 모양 메시지 (ii) 생성자는 문자열만(정본이 답) — `spec.tag` 2절 (iii) 무처리(in-tree 생산자 없음, 원장 기록만) |
| **`H-390`** (LOW) | 묶음 | Store 문에 `isPlainBranded` 없음(넷째 문) + Brand 주석 열거·의역 인용 / `isPlainFieldTable`의 죽은 항 둘 / LifetimeHandle 주석·Q7 문구 범위(핸들러 작성자만 → 태그된 공개 메소드 안 모든 사용자 콜백) / 스텁 메시지 꼬리 불일치 / `architecture.md` 도착지 표에 미설치 스텁 행 없음 / `gatedRecompute` 클로저가 상수 길이에서도 요소당 생성(`H-365` 가족) | 전부 반영: Store 게이트 + `spec.store`, Brand 주석(현재 집합은 grep), `isPlainFieldTable` 단순화, 주석·Q7 문구, 메시지 꼬리 통일, 표 행 추가, `gatedRecompute(bk, blocker, ownerKey, element, i)` Init 스코프 |
| **`H-391`** (LOW, ②+①) | `Property.luau` Tween 분기 3 | 동일값 재발행이 활성 트윈을 취소·재시작 — 정본 침묵 | **§4 Q12**; `Reverses = true` 캐비엇은 ① `tween-plan.md` 한 줄 |

다음 순회는 §11부터, `H-392`부터. **순회 방식(사용자 판정)**: `/code-review` 인자에 서브에이전트 `model: "opus"`
지정 + 검증자 상한을 넣는다 — `conventions.md` 2026-09-07 정정 항목.

## §11 5순회 — `/code-review high`, 인자로 파인더 6·검증자 5 전부 opus (2026-09-07 11~12시 KST)

첫 순회에서 규약대로 서브에이전트 모델을 인자로 낮췄다(파인더 6·검증자 5 전부 opus, 나머지 6건은 포크가 단일
맥락 판정). 후보 23 → 병합 → 10 + 표 8, 미완 0. **`0d141be` diff 회귀 넷**(`H-396`/`H-399`/메시지 둘) — 전례 그대로.
기각 6(`[AttributeKey] = v` 타입드 Param 키 거부 = `H10-12`/`H10-15` (c′), 무타입 생성자 팔 vs 런타임 검증 = 설계,
`store.key = Source` rawset = store-plan 폐기 계약, `Animate(info)` 무복제 = 의사코드 지연 읽기, Store 얕은 복제 =
"구현 스케치" `table.clone`, `wrap == identity` 분기 = `H-342` ③).

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-392`** (HIGH) | `Bookkeeping.luau` `setOffsetSource` | `bk.sourceList[i] = source`를 먼저 쓰고 `:Get()`을 불러, 잘못된 인자(빈 테이블)가 부기를 오염시킨 채 남고 다음 무관한 `setLength`가 `recomputeBlocker:On()` 안에서 죽어 그 owner의 오프셋 산술이 **영구 동결**(`q.None` 복구도 무효 — 실측). `dispatch-core-plan.md` `H-256` (a) "부기를 하나라도 만지기 전에 검사한다" 위반 | 읽기(`getOffsetAt`·`source:Get()`) → 쓰기 순서로. `source` 타입 게이트는 **§4 Q13**. `spec.lengthoffset` 11절(내부 `sourceList[1] == nil` 관측) |
| **`H-393`** (MED) | `Slot.luau` `releaseElement` wasDetached 분기 | `releaseOwner` 없이 요소를 버려, `Owned = false` 요소 Slot(부모보다 오래 산다)이 죽은 `elementOwner`를 영구히 담 — 다음 `Add` "already mounted elsewhere"·`dispose` "still requires its tree"(둘 다 반사실). 정본 `_detachCleanup` 의사코드 "`releaseOwner`를 먼저, 두 분기 공통으로"가 예고 | `releaseOwner(element, self)`를 분기 머리에. `destroySlotTree` 두 루프는 C-4 면제(사용자 확정)와 충돌이라 **§4 Q14**. `spec.slot` 12b절 |
| **`H-394`** (MED, ②) | `Bookkeeping.luau` `setLength` `len` | 도메인 무검사(음수·소수·비숫자 State) — 조용한 오프셋 오염 또는 Blocker 영구 잠김 | **§4 Q15** |
| **`H-395`** (MED) | `quad-roblox/src/LifetimeHandle.luau`·`mock.luau` `bindLifetime` | 같은 Instance의 두 위치에 같은 핸들(`D.Frame { eff, eff }`)도 "already bound to **another** Instance" — 존재하지 않는 둘째 인스턴스를 찾게 함(`H-382` 반사실 메시지 클래스) | `BindData:GetWeak(value, "gchold") == gchold`로 같은-inst 팔("this Instance (the same handle at two positions?)"), mock 동형. `spec.lifetime` 4절 |
| **`H-396`** (LOW, diff 회귀) | `Slot.luau` 생성자 게이트 | `type(k) ~= "number"`만 봐 `[0]`/`[-1]`/`[1.5]`(해시부)가 통과 → 요소 0개·잠금 — 형제 `Tag.flattenInto`는 거부 | `k % 1 ~= 0 or k < 1` 미러(nil 구멍 count 검사는 UB라 안 가져옴). `spec.slot` 22b절 둘 |
| — (LOW, diff) | `Slot.luau` `checkListInstall` 메시지 | `:Single` 진입에서도 "…`:List`…"만 지칭 — 안 쓴 기능을 말함(`H-386`이 닫은 클래스) | `:List/:Single` 둘 명기, `spec.slot` 13절 단언 갱신 |
| — (LOW, diff) | `Tag.luau`·`Store.luau` 메시지 | `isPlainBranded` 값(정의상 메타테이블 없음)에 "got a table with a metatable"/"without a metatable" — 코드가 방금 반증한 사실을 메시지가 단언 | 브랜드 팔 메시지 분리("got an AttributeKey/Mapper descriptor"). `spec.tag`·`spec.store` |
| **`H-397`** (LOW) | `Bookkeeping.luau` `getOffsetAt` | `at > N+1`이 내부 불변식 메시지 "bookkeeping is broken"을 level 1로 — 사용자 입력인데 내부 줄 blame | 마지막 등록 자리 너머면 `errorBeforeNearest`(N+1은 합법 — `Slot.luau`·spec 셋), 희소 구멍은 기존 내부 메시지. `spec.lengthoffset` 11절 |
| **`H-398`** (MED, ②) | `Tween.luau` `validate` | `Value`에 State/Source 통과 — 정본 "plain 값만" 미집행 | **§4 Q16** |
| **`H-399`** (MED, ②) | `Observer.luau`/`Effect.luau` `_assertBindable` | `H-384`의 `errorBefore`가 재진입 가드 규약(quad-error 헤더·effect-plan level 3·lifecycle-pattern)과 충돌 — 태그된 `bindLifetime` 뒤에선 어느 방향도 정확하지 않음 | **§4 Q7 둘째 불릿**; 정본 두 문장에 보류 배너(코드 변경 없음) |
| **`H-400`** (LOW, ②+①) | `gen-d.py` `D.Modifier.<Class>` 인자 유니언 | `(<Class>Modifier \| { [string]: any })`가 각 팔 단독 거부 값을 무진단 통과(8.9의 새 자리) — 런타임은 전부 시끄러운 에러 | ① `typing-limits.md` 8.9 "quad에 걸린 자리"에 등재; `{ [string]: any }` 팔 제거는 **갈래로만 기록**(문항 안 올림 — LOW·시끄러움) |
| **`H-402`** (LOW, ②) | `InstanceShorthand.luau` `numberOnly` | 정본 표에 없는 다섯째 필드 — 에이전트 추가 메커니즘 | **§4 Q17** |
| — | `spec.slot` "=== 23." 중복 | `H-386` 신설 절이 H6-24 절과 같은 번호 | 22b로 |
| — | `todos.md` | "§4 Q1~Q8(" 라벨 안에 Q9~Q12 나열 | Q1~Q17 |
| — | `Brand.luau` 헤더 | "`EpochBrand` … `GateNode`" — GateNode는 Epoch가 아니다(`State.luau` 헤더, 등록하면 `EpochMap:Update` 영원히 false) | 주석 정정 |
| — | `dispatch-core-plan.md` 말단 핸들러 표 | `EventHandler`·`OnChangeHandler` 행 없음(2026-09-03부터) | 행 둘 |
| — | `ui-shorthand-plan.md` | "조회 경로 `(inst, 숏핸드키)`" stale(코드는 `childName` 키, `H-335`); "wrap 항등 분기 없이"가 `H-342` ③과 어긋남 | 두 문장 정정 |

**사용자 지시(2026-09-07 낮, 5순회 커밋 직후)** — *"isSlot 은 slot.luau 에 있더라. 이거 다른것과 일치하게 둬야하지
않을까? 나중에 천천히 처리해줘"* → **`H-403`**(①, 다음 순회에서 반영): `isSlot`만 `Slot.luau`(`local function isSlot`
+ `module.isSlot = isSlot`)에 살고 형제 술어 전부는 `Brand.luau`에 산다 — `Brand.isSlot`(`SlotBrand:is`)으로 옮기고
`Slot.luau`·`Dispatch/init.luau`·`Dispatch/Slot.luau`가 그걸 쓰게(`init.luau` 노출 목록 합류).

다음 순회는 §12부터, `H-404`부터.

## §12 — 사용자 지시 반영 + 6순회 (2026-09-07 오후)

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-403`** (①, 사용자 지시) | `Slot.luau` `isSlot` | 형제 술어는 전부 `Brand.luau`에 사는데 `isSlot`만 `Slot.luau`의 로컬 함수 + `module.isSlot` 설치였다(`slot-plan.md`: "`isSlot`은 `Brand`의") | `Brand.isSlot`으로 이동·export, `Slot.luau`는 그걸 재노출(`module.isSlot`·`_slotInternal.isSlot` 동일 함수), `init.luau` 리터럴에 합류, `Modifier`/`Bookkeeping`의 `SlotBrand:is` 직접 호출 셋도 `Brand.isSlot`로 |

