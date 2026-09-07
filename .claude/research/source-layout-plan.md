# 소스 구조 재편 계획 — 사용자 의견 여덟의 확인·이득·비용 (2026-09-07)

**상태**: research — 사용자 결정 대기. 사용자 원문(2026-09-07 낮): *"내 말을 전부 정답이다
생각하진 말고, 확인하고 이득을 따져볼것"*. 사실 조사는 opus 단일 에이전트(읽기 전용)가 했고
판단은 메인이 붙였다. 결정되면 항목별로 `base/architecture.md` 소스 트리 절을 고치고 코드를
옮긴다. **의견 원문 여덟**:

> - 슬롯 파일 너무 길어서 유지보수성 조금 복잡해짐. Slot_mt 구현과 간단 유틸, 마운트나, raw 들을 적절히 유지관리 가능한 정도로 Slot/... 로 쪼갤 수 없는지
> - Tween 은 roblox 에만 있어야할텐데, tween 자체가 가지는 인자(repeat 나 등등) 같은게 엔진마다 다 다를 수 있어, 근데 베이스에 있네
> - Tag초기화자는 다른 tag 나 테이블 받는지 확인 필요함 … Tag() 로 초기 부터 잡는게 유리한데 … flattenInto 를 약간 건들고 타입이 변경되어야하는것 아닌지?
> - src 안에 뭐가 너무 많은데 파일 구조를 어떻게 정리할지 리서치좀 해보고싶음
> - dispatch 가 각 계층의 slot/storebind.luau 같은게 있는게 이상함. Slot/... 같은걸 만들어야하지 않나
> - Modifier 는 예외적으로 dispatch 안에서 정의되는 객체일 필요가 있는듯
> - PreRef/PostRef 같은건 사실상 Ref/... 안에 들어가게 되는게 어떤지?
> - Attribute 도 마찬가지. AttributeKey 를 합칠 수 있고 … Attr 로 줄이는것도 괜찮을지도

## 0. 재편 전체에 걸리는 제약(조사 결과 — 어느 항목이든 이걸 밟는다)

1. **`X.luau` → `X/init.luau` 접기는 공짜다.** `init.luau` 안에서 `./`는 부모 폴더, `@self/`는
   자기 폴더(`Dispatch/init.luau:38` `require("./Relate")` = `src/Relate.luau`,
   `:42` `require("@self/None")`). 그래서 파일을 폴더로 접으면 그 안의 `require("./Brand")`도
   바깥의 `require("./X")`도 그대로 유효하고, 새 형제 파일만 `@self/`로 부르면 된다. **`X.luau`와
   `X/`를 동시에 두지 말 것**(해석 우선순위 미검증).
2. **값 모듈 → `Dispatch/init` 단방향.** `H-278`(자기 등록) 때문에 Tag/AttributeKey/Attribute/Ref/
   Slot/Observer/Effect가 `Dispatch/init`을 require한다 → **`Dispatch/init`은 값 모듈을 절대
   require하면 안 된다.** drive가 필요로 하는 조각은 `Dispatch/` 아래 잎으로(`Dispatch/Ref.luau`
   pre-pass, `Dispatch/Modifier.luau`), 또는 값 모듈 자체가 `Init` 없는 잎(`Modifier.luau` — flatten을
   `Dispatch/init:45`가 역방향으로 당김, `Tween.luau`).
3. **사적 내부 표면 관용구가 이미 셋** — `module._slotInternal`(Slot → Dispatch/Slot),
   `module._bookkeeping`(Bookkeeping → Dispatch/Slot 소비), `module._impl`. 파일을 쪼개 상호 재귀를
   끊을 때 쓸 도구가 이것이다. `_slotInternal` 조립(`Slot.luau:1112`) → `register`(`:1123`) 순서가
   load-bearing.
4. **전방 선언 여덟 + `GlobalUsedAsLocal` 게이트**(`H-404`). 전방 선언은 파일 경계를 못 넘는다 —
   Slot을 쪼개면 상호 재귀를 (3)의 내부 표면(늦은 조회)이나 명시 인자로 바꿔야 한다.
5. **`Slot_mt`는 module 인스턴스별**(`H6-3`) — 메소드를 여러 파일이 나눠 가지면 `Slot_mt`를
   Init 인자로 넘긴다. 늦게 읽는 주입 값(`bindLifetime`/`isInst`/`native*`, `H-174`)도 캡처 금지.
6. **`doc-check.py`는 `.luau` 경로를 검사하지 않는다**(`interesting()` — "미래 소스 트리" 예외).
   라이브 md 42개가 `quad-base/src/<이름>.luau`를 인용한다(`init.luau` 47회, `Relate` 10, `Modifier`
   10, `Ref` 6 …). 옮기면 **조용히 stale**. 재편 커밋엔 (a) 그 인용 전수 치환과 (b) `doc-check.py`를
   "지금 존재하는 src 경로는 검사"로 넓히는 것을 같이 넣어야 한다.
7. **빌드·테스트 설정은 디렉토리 단위**(`default.project.json`·`.luaurc`·`test.sh` — 하드코딩은
   `quad-roblox/src/D/init.luau` 하나)라 투명. `pesde.toml`의 `includes = ["src/*"]`가 중첩 폴더를
   게시에 포함하는지는 **미검증**(이미 `Dispatch/`·`Debug/`가 같은 조건 — 새 문제는 아님).
8. **`BRAND_PROBES`**(`Dispatch/init.luau:79`)는 손 유지 술어 목록 — 값 타입을 옮겨도 술어는
   `Brand.luau`에 남아야 한다(`H-403`이 `isSlot`을 이미 그리로).

## 1. Slot 분할 — **권고: 한다, 다만 Q9/Q14 결정·반영 뒤 별도 단위로**

**사실**: `Slot.luau` 1142줄 전부가 하나의 `Init(module)` 본문. 여섯 묶음 — (a) 소유권 레지스트리
(`claimOwner`/`claimOwnerAt`/`releaseOwner`/`occupantOf`, ~40줄) / (b) 요소 게이트(`wrapElement`/
`unwrapElement`/`prepareElements`, ~60) / (c) 트리 마운트·해체(`materializeSlotTree`…`destroySlotTree`,
`collectLeaves`, `releaseSugarWrapper`, ~250) / (d) raw* 물리 조작 + 부기(`rawAdd`…`rawSplice`,
`spliceArrays*`, `vacate`, `releaseElement`, ~350) / (e) `:List`/`Single`/`_activateList`의 로컬
클로저 `settle`·`reconcile`(~200) / (f) 공개 `Slot_mt` CRUD·생성자·`dispose`·노출(~250).
**(b)(c)(d)(e)(f)가 하나의 강연결 성분**이다 — (b)`wrapElement`→(f)`Slot()`·(e)`Single`,
(c)`materializeSlotTree`→(e)`_activateList`, (e)`settle`→(d)raw*·(b), (d)→(c)`destroySlotTree`.
그래서 전방 선언 여덟이 있다.

**이득**: 파일당 250~350줄이면 리뷰어·감사자가 한 묶음을 한 번에 읽는다(0~6순회에서 Slot 발견이
가장 많았고 — `H-375`/`H-382`/`H-385`/`H-386`/`H-393`/`H-396` — 그 상당수가 "다른 묶음의 호출부를
못 본" 종류였다). 경계가 파일이 되면 "raw*는 이미 래핑된 요소만 본다" 같은 불변식이 import
방향으로 강제된다.

**비용**: (1) 상호 재귀를 끊는 배관 — `Slot/init.luau`가 내부 표면 테이블 `S`를 만들고 각 하위
파일이 `function(S, module)`로 자기 함수를 `S`에 설치·형제는 `S.x(...)`로 늦게 조회(전방 선언의
파일 판). 핫패스(raw*/settle)에 테이블 인덱스 하나가 늘지만 그 경로는 이미 Relate·부기 호출이
지배적이라 관측 불가. (2) 이동 자체의 회귀 위험 — 0~6순회 모두 "직전 수정분이 새 결함을 만든다"를
실증했다. 순수 이동(동작 diff 0)은 `spec.slot`(가장 큰 spec)이 게이트이고, **동작 수정(Q9·Q14·
`H-382`/`H-393` 후속)과 같은 커밋에 섞지 않는다.** (3) `.claude/base/slot-plan.md`(3400줄)의
`Slot.luau` 인용 3곳·`architecture.md` 트리.

**제안 구조**:
```
Slot/init.luau      Init(module): S 조립 → 하위 다섯 설치 → Slot_mt 공개 CRUD·생성자·dispose·module 노출·_slotInternal·Dispatch/Slot register
Slot/Owner.luau     (a) elementOwner Relate + claim/release/occupantOf
Slot/Elements.luau  (b) wrapElement/unwrapElement/prepareElements
Slot/Tree.luau      (c) materialize/mount/attach/destroy/unmount/teardown/collectLeaves/sugar wrapper
Slot/Raw.luau       (d) raw* + spliceArrays + vacate + releaseElement + indexOfRaw/getDetached
Slot/List.luau      (e) _activateList(settle/reconcile)·List/Single·checkListInstall
Slot/Handler.luau   ← 5절 (a)를 택하면 Dispatch/Slot.luau가 여기로
```
**순서**: Q9·Q14 답 → 그 반영(작은 diff) → 순수 이동 단위(리뷰 1회, `spec.slot` 전량) → 이동
뒤 한 순회.

## 2. Tween의 위치 — **권고: 엔진 어휘 검증만 quad-roblox로 (절충 (c))**

**사실**: `Tween.luau`(105줄)는 `Value`·`Override`(엔진 무관)와 `Time`/`RepeatCount`/`DelayTime`
(number)·`Reverses`(boolean)를 검증하고 `Info`/`Style`/`Direction`은 엔진 타입으로 통과시킨다.
tween-plan "패키지 경계 — `Tag`가 이미 밟은 것과 같은 분리" 절은 *"quad-base: `Tween.luau` —
값 타입(`Tween(opts)` 팩토리)만. 엔진 무관."*이라 했고, 같은 문서 "옵션 값 모양" 절은 그 네
필드를 **Roblox `TweenInfo.new`의 포지셔널 인자를 이름으로 푼 것**으로 서술한다(기본값 표도
엔진 값 그대로, `H-333` "값의 소스는 여전히 엔진이고 코드는 그 사본"). 즉 "엔진 무관"은
*Lua 스칼라라서 base가 검사할 수 있다*는 뜻이었고, **어휘 자체가 Roblox 것**이라는 사용자
지적은 맞다. 소비는 전부 quad-roblox(`Handlers/Property.luau` `buildInfo`·3-상태, `Animate.luau`).
quad-base가 Tween을 아는 자리: `Brand.luau`(브랜드·`isTween`), `Dispatch/init.luau`
`BRAND_PROBES`, `init.luau` 노출, quad-types 여섯 타입.

**선택지**:
- (a) 그대로 — 둘째 엔진이 없으니 "관측된 문제에만 구조". 비용 0, 어휘 오염은 남는다.
- (b) 통째 이동 — `Tween`·`TweenOptions` 타입·검증을 quad-roblox로, `q.Tween`은 프로바이더
  설치 표면(`D`와 같은 `Quad & RobloxExtension`). 브랜드는 Brand.luau에 남기거나(`BRAND_PROBES`
  유지) 프로바이더 브랜드로(진단이 `value: table`로 퇴화 — M11 리뷰가 잡았던 것). quad-types의
  `Tween<T>`/`TweenData<T>`가 quad-roblox로 가면 `PVn`(생성 D)·`NewChild`가 참조하는 타입이
  패키지를 바꾼다 — 타입 표면 재배선이 크다.
- (c) **절충** — base `Tween.luau`는 `Value`·`Override`만 검증하는 **엔진 무관 봉투**로 남고
  (`Tween<T>`의 나머지 필드는 `{ [string]: any }` 또는 제네릭 `Opts`), 네 필드의 이름·타입·기본값
  검증은 quad-roblox `Property.buildInfo`(이미 기본값 사본을 갖고 있음)로 이동, 타입은 quad-roblox
  `types.luau`가 `TweenOptions`를 Roblox 어휘로 좁혀 `PVn`에 싣는다(이미 `Tween<T>`를 별칭하는
  자리). 브랜드·`isTween`·`BRAND_PROBES`·`q.Tween` 표면은 그대로 → 코드 이동은 검증 20줄 +
  타입 한 벌. **비용**: quad-types `TweenOptions<T>`의 제네릭화가 typing-limits 8.x(재귀·유니언
  팔)에 걸리는지 스파이크 하나 필요.
**권고 (c)** — 사용자 지적의 실체(어휘)를 닫으면서 타입 표면 재배선을 피한다. (b)는 둘째 엔진이
실제로 생길 때.

## 3. Tag 생성자·합성 — **권고: `string | {string} | Tag` 유니언으로 통일(어제의 `H-389` 역전)**

**사실**: 생성자 `__call`은 문자열만(`H-389`가 어제 런타임을 타입 `...string`에 맞춰 좁힘),
`Added`/`Removed`는 `string | {string}`(`flattenInto`), 다른 Tag는 `Tag.Merged(...)`로만 합치고
`__call`/`Added`/`Removed`에 Tag를 주면 **명시 거부**(`H-380`·`H-389` 메시지가 Merged를 안내).
`table.clone`은 `Added`/`Removed` 두 곳뿐이고 **라이브러리 내부 호출자는 0** — "복사 떠서 추가"의
비용은 사용자 표면에만 있고 핫패스가 아니다. 정본 tag-plan "값 모양" 절은 생성자를 *"`{...}`로
패킹해 `self:Added(packed)`"*로 서술 — 실물(select 루프)과 이미 어긋나 있다.
비교: **`Attribute(store, attr, { plain })` 생성자는 Store·Attribute·plain 테이블을 섞어 받고
평탄화한다**(`flattenArg`) — 같은 "이름 집합 값"인데 Tag만 생성자가 좁다.

**선택지**:
- (a) 그대로(문자열만) — 어제 결정 유지, `Merged`가 합성의 유일한 문.
- (b) **`flattenInto`에 Tag 팔 추가** — `Tag(...)`/`Added`/`Removed` 전부 `string | {string} | Tag`
  (리스트 원소도 같은 유니언 재귀), 타입 `__call: (self, ...(string | {string} | Tag))`,
  `Added/Removed: (self, string | {string} | Tag)`. `Merged`는 `Tag(a, b)`와 같아져 별칭으로 남기거나
  제거. Attribute 생성자와 모양이 같아진다(사용자 원문 *"Tag() 로 초기 부터 잡는게 유리"*).
  비용: `Tag.luau` 20줄, quad-types 2줄, tag-plan 값 모양 절, `spec.tag` 2절의 `H-389` 단언 역전,
  `H-380`/`H-389` 원장 행 포인터.
**권고 (b)** — 어제의 좁힘은 "정본이 문자열만"이라는 근거였는데, 정본 자체가 실물과 어긋나 있고
형제(Attribute)와 비대칭이다. "다른 Tag에서 가져오기"는 사용자가 실제로 원하는 모양.

## 4. src 전체 배치 — **권고: 패밀리 폴더 셋(Slot/·Ref/·Attribute/) + Modifier 이동까지만, 대분류 폴더는 보류**

**사실**: quad-base/src 33파일 6057줄. require 그래프 순환 0. 잎: Brand/Void/Relate/ErrorNamespace/
ImplRegistry/Debug/Dispatch/Handler. 중간: EpochMap/Blocker/Claim/LifetimeHandle/Tween/Modifier/
Bookkeeping/State/Source/Store/Dispatch/*. 상위(Dispatch/init 소비): Observer/Effect/Ref/PreRef/
PostRef/Slot/Tag/AttributeKey/Attribute. `init.luau`는 24개를 전부 require하고 RunInit 순서는
무관(`H-174` 멱등 당김, `H-358`).

**선택지**:
- (a) **패밀리 접기만** — `Slot/`(1절), `Ref/{init,PreRef,PostRef}`(6절), `Attribute/{init,Key}`
  (7절), `Dispatch/Modifier/`(5절). 나머지 20여 파일은 평면 유지. 제약 (1)로 바깥 require 무변경,
  md 인용 치환은 옮긴 파일만.
- (b) 대분류 — `Util/`(Brand·Relate·Void·ErrorNamespace·ImplRegistry·LifetimeHandle), `Reactive/`
  (Source·State·Store·EpochMap·Blocker·Observer·Effect), `Dispatch/`, 패밀리 폴더. 이득은 트리를
  읽을 때의 개념 지도; 비용은 **모든 파일의 `./` 경로 재배선**(잎으로 가는 require가 전 파일에
  있다), md 인용 42파일 전수, `architecture.md` 트리 전면 재작성, 그리고 `Observer`/`Effect`가
  `Reactive/`에 있으면서 `Dispatch/init`을 require하는 층위가 폴더명과 어긋남(제약 2).
**권고 (a)** — "너무 많다"의 실체는 파일 수(33)보다 **한 파일의 크기(Slot)와 패밀리가 흩어진 것**
(Ref 셋, Attribute 둘, Dispatch/Slot)이다. (a)로 최상위가 33 → 25개 전후. (b)는 관측된 필요가
없고 재배선 비용이 크다 — 패밀리 접기 뒤에도 트리가 안 읽히면 그때.

## 5. `Dispatch/`의 핸들러 파일 — **권고: 규칙을 명문화하고 `Dispatch/Slot.luau`만 `Slot/Handler.luau`로**

**사실**: `Dispatch/`엔 코어(`init`·`Handler` 타입)와 **drive 자신의 단계**(`None`·`StoreBind`
언랩·`Modifier`의 ProcessedModifier·`Ref` pre-pass)가 있고, 이들은 `Dispatch/init`이 직접 등록한다.
반면 `H-278`(사용자 지시) 이후 값 모듈은 자기 핸들러를 자기 파일에서 등록한다(Tag/AttributeKey/
Attribute/Observer/Effect/Ref). **유일한 혼종이 `Dispatch/Slot.luau`** — 파일은 Dispatch 아래,
등록자는 `Slot.luau:1123`, 소비는 `_slotInternal`. 사용자 원문 *"dispatch 가 각 계층의
slot/storebind.luau 같은게 있는게 이상함"* 중 `StoreBind`는 값 모듈이 아니라 **디스패치 자체의
언랩 단계**(Brand만 require, `Dispatch/init:396`이 등록)라 Dispatch 아래가 맞다.

**규칙(제안, `architecture.md`에 명문화)**: *"핸들러는 그 값 타입을 소유하는 모듈 안에 산다
(`H-278`). `Dispatch/` 아래엔 코어와 `drive`의 자기 단계(None/StoreBind/Modifier/Ref pre-pass)만
— 값 모듈이 `Dispatch/init`을 require하므로 그 반대 방향은 구조적으로 불가."*
**이동**: `Dispatch/Slot.luau` → `Slot/Handler.luau`(1절 폴더 안). 그러면 혼종 0.

**Modifier(사용자: "예외적으로 dispatch 안에서 정의되는 객체")**: 사실 — `Modifier.luau`는 src
루트의 잎(Init 없음)이고 flatten은 `drive`의 첫 단계(round17 Q4 (a) "flatten은 drive 소유"),
`Dispatch/Modifier.luau`는 ProcessedModifier 핸들러 38줄. 사용자 판단은 근거가 있다 — Modifier는
값이라기보다 **drive의 입력 형식**이다. 이동: `Modifier.luau` → `Dispatch/Modifier/init.luau`,
`Dispatch/Modifier.luau` → `Dispatch/Modifier/Handler.luau`(또는 init에 흡수 — 38줄). 순환 없음
(Modifier는 Brand/ErrorNamespace/Dispatch/None만 require). 비용: `init.luau` require 경로 하나,
md 인용 10곳(`Modifier.luau`가 두 번째로 많이 인용됨), `modifier-plan.md` 트리 서술.
**권고: 한다** — 규칙(위)이 "Dispatch/ = drive의 자기 단계"인데 flatten이 정확히 그것.

## 6. Ref 패밀리 — **권고: `Ref/{init,PreRef,PostRef}.luau`, `Dispatch/Ref.luau`는 그대로**

**사실**: `PreRef.luau`(34)·`PostRef.luau`(35)는 각각 **한 줄 함수** — `Ref._tagged(default, Brand,
marker)`. 의존은 PreRef/PostRef → Ref 단방향, Ref는 `Brand.isPreRef`만 본다. `Dispatch/Ref.luau`
(pre-pass + Processed 센티널 둘)는 헤더가 밝히듯 drive의 단계라 Dispatch 아래가 맞다(5절 규칙).
**선택지**: (a) 폴더 `Ref/`(init 256 + PreRef 34 + PostRef 35) / (b) 둘을 `Ref.luau`에 흡수(한
파일 ~300줄, `_tagged` 사유 주석 *"one factory so the marker/_fired conventions cannot drift
between the two files"*가 오히려 한 파일을 가리킨다). **권고 (a)** — 사용자 원문대로 폴더가 "각자로
보기 좋게"; 흡수는 `PreRef`/`PostRef`가 공개 이름이라 찾기 어려워진다. 비용 최소(md 인용 `Ref` 6·
`PreRef` 1).

## 7. Attribute 패밀리 — **권고: `Attribute/{init,Key}.luau`, 핸들러는 각자 안에**

**사실**: `Attribute.luau`(279) → `AttributeKey.luau`(136) 단방향(`_newUncachedKey` 사적 경로 —
그룹 개인 키가 공개 캐시 키와 **반드시 다른 객체**여야 교차 retraction이 구조적으로 불가). 핸들러
둘(`AttributeKeyFallbackHandler` 키 매칭 / `AttributeGroupFallbackHandler` 배열부 값 매칭, 둘 다
FALLBACK) + Relate 셋. 합치면 415줄 한 파일에 브랜드 둘·핸들러 둘 — 나누는 편이 "하나가 두 일"
규칙에 맞다. **폴더**: `Attribute/init.luau`(그룹 값·그룹 핸들러·스칼라 슈가) +
`Attribute/Key.luau`(단일 키·키 핸들러·`_newUncachedKey`). 사용자의 "핸들러 계약 단위도 쪼갤 수
있을지도"는 `Attribute/Handler.luau`로 그룹 핸들러 60줄을 빼는 것 — 279줄이라 급하지 않음, 1절
Slot처럼 커지면.

## 8. `Attribute` → `Attr` 축약 — **권고: 사용자 판단, 하려면 재편 단위에 같이(지금이 가장 쌈)**

**사실**: 공개 이름 — `Attribute`(콜러블 + `.Merged`/`.Overridden`), `AttributeKey`,
`StringAttribute`/`NumberAttribute`/`BooleanAttribute`, `isAttribute`/`isAttributeKey`, 메소드
`NameMap`, quad-types `Attribute`/`AttributeConstructor`/`AttributeSugar<T>`, 생성 D `NewChild` 팔,
quad-roblox `EngineOps.setAttribute`(엔진 op 이름은 Roblox API 어휘라 그대로). 등장: `.claude/base`
**18파일**, quad-types 9줄, quad-roblox 2파일, spec 5파일. 선례: `Reference` → `Ref`.
**이득**: `D.Frame { Attr { … } }`·`AttrKey "Hp"` — 실사용 타이핑(사용자: *"실제 개발에서 많이 쓰는
줄임"*). 사용자 0명인 지금이 이름 바꾸기의 최저 비용 시점. **비용**: 코드·타입·D·spec 기계 치환 +
base 18파일 문서 스윕(이름은 doc-check가 못 잡는다 — 감사자 한 라운드). 엔진 op `setAttribute`와
Roblox `GetAttribute`는 그대로라 "Attr = quad 값, Attribute = 엔진 개념"으로 읽히는 부수 효과 있음.
**권고 없음(취향 결정)** — 하면 `Attr`/`AttrKey`/`StringAttr`/`NumberAttr`/`BooleanAttr`/`isAttr`/
`isAttrKey`, 7절 폴더는 `Attr/`.

## 9. 실행 순서(결정 뒤)

1. §4 Q9·Q14 답 → 동작 수정 커밋(작음).
2. 3절 Tag 유니언(코드 20줄 + 타입 + 정본) — 독립, 먼저 해도 됨.
3. 2절 Tween (c) — 타입 스파이크 → 이동.
4. 순수 이동 단위 하나: 1·5·6·7절(+8절 이름) — 동작 diff 0, `spec.*` 전량 + `doc-check.py`
   `.luau` 경로 검사 확장 + md 인용 치환 + `architecture.md` 트리·5절 규칙 명문화 + `README`.
5. 이동 뒤 순회 1회(직전 수정분 회귀 관측이 규칙이므로).
