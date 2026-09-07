# 소스 구조 재편 계획 — 사용자 의견 여덟의 확인·이득·비용 (2026-09-07)

**상태 [2026-09-07 밤 갱신]**: 사용자 회신 도착(루트 `layout-usernote-ignoreme.md`, 커밋 제외) —
**결정·반영 상태는 각 절 머리의 `[결정]` 줄이 소스**, 후속 제안 넷(Brand→quad-types·마커 전면화·
quad-types 재배치·D 정적 굽기)은 10절. 사용자 원문(2026-09-07 낮): *"내 말을 전부 정답이다
생각하진 말고, 확인하고 이득을 따져볼것"*. 사실 조사는 opus 단일 에이전트(읽기 전용)가 했고
판단은 메인이 붙였다. 반영은 `base/architecture.md` 소스 트리 절과 코드를 항목별로 고친다.
**의견 원문 여덟**:

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
   pre-pass, `Dispatch/Modifier/Handler.luau`), 또는 값 모듈 자체가 `Init` 없는 잎(`Dispatch/Modifier/init.luau` — flatten을
   `Dispatch/init:45`가 역방향으로 당김, `Tween.luau`).
3. **사적 내부 표면 관용구가 이미 셋** — `module._slotInternal`(Slot → Dispatch/Slot),
   `module._bookkeeping`(Bookkeeping → Dispatch/Slot 소비), `module._impl`. 파일을 쪼개 상호 재귀를
   끊을 때 쓸 도구가 이것이다. `_slotInternal` 조립(`Slot/init.luau:1112`) → `register`(`:1123`) 순서가
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

**[결정 2026-09-07 밤]** 채택 — 사용자: *"권고대로 가도 될것 같아."* Q9/Q14는 회신 3차로 이미
반영됐으므로 순수 이동 단위(9절 4번)로 간다. 반영 상태는 9절.

**사실**: `Slot/init.luau` 1142줄 전부가 하나의 `Init(module)` 본문. 여섯 묶음 — (a) 소유권 레지스트리
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
`Slot/init.luau` 인용 3곳·`architecture.md` 트리.

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

## 2. Tween의 위치 — **결정: (b) 통째 이동(사용자) — 원 권고 (c) 엔진 어휘 검증만 이동은 기각**

**[결정 2026-09-07 밤 — (b) 통째 이동, 권고 (c) 기각]** 사용자: *"Tween 자체가 워낙 엔진의
지식인지라, 엔진 자체로 옮기고 싶어. 처음 생각했던 부분 자체가 그거였음 … 이미 Animate 가 온전히
roblox 에 있다는 점으로 미루어 볼 때, 슈거의 실 구현체인 Tween 도 quad-roblox 에 있지 말아야할
이유가 없어 … 웹은 Transition 으로 이름도 다른데다가 … 한 css 프롭에 다른 프롭의 애니메이션을
담는거라 완전 다름. 공개 표면을 같이 두는 이점이 적어보여 — 웹은 Value 의 필요 부터 없거든. 전부
엔진 어휘가 되어야한다는 생각인데, 어떻게 보는지?"* **아래 "사실"·"선택지"·"권고 (c)" 블록은 결정 전 분석(보존용) — 지금 배치는
`base/tween-plan.md` "패키지 경계" 절이 소스.** 메인 판단: 동의 — (c)를 권한 근거였던 "타입
표면 재배선이 크다"는 실측에서 작았다(생성 D는 이미 quad-roblox `types.luau`의 `Tween<T>`를
별칭하고 있어 D 재생성 없이 정의만 옮겨졌고, quad-types에 남는 건 `FieldOut<X>` 하나). **반영
완료**(같은 날): `quad-roblox/src/Tween.luau`(install)·`Brand.luau`·`types.luau` 정본(엔진 타입
필드 정밀)·`test/spec.tween.luau`, quad-base엔 `BRAND_PROBES`의 문자열 `"isTween"`만(round3 §4
Q27). 부수 발견: D 안에서 `FieldOut` 전개는 제약 한도 초과 → `typing-limits.md` 8.12.

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

**[결정 2026-09-07 밤 — (b) 채택, 반영 완료]** 사용자: *"권고대로, flattenInto 와 타입을 고치면
되므로, 비용도 크지 않은편. 특히 이런 곳에서는 타입 체크 비용을 아끼기 위해 마커만 두는것도
괜찮아보임."* 반영: `Tag.luau` `flattenInto` 한 문(재귀 — `string | Tag | { names }`), quad-types
`TagNames`/`TagMarker`(입력 자리는 마커 — 사용자 지적대로), `TagImpl.__quadTag`, `spec.tag` 2절,
`base/tag-plan.md` "값 모양" 배너. `Merged`는 Tag만 받는 엄격형으로 남김(제거는 결정 대상).

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

**[결정 2026-09-07 밤 — (a) 채택]** 사용자: *"동의. 다른 부분은 보기 힘들어져 아플 때 처리하는게
나아보임. 최종 export 표면은 달라짐이 없고 관리 편의성 부분이라, 급하지도 않음. — 각각 필요가 나올
때 마다."* 5·6·7절은 (a)의 구성 요소라 함께 채택으로 읽는다(사용자가 따로 언급하지 않음 — 반영 뒤
확인 요청). 8절 `Attr` 축약은 **미답**(열림). 반영 상태는 9절.

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

**[결정 2026-09-07 밤 — 4절 (a)의 구성 요소로 채택, 반영 완료]** 규칙은 `base/architecture.md` 소스 트리 아래
문단에 명문화됐고, 옛 `Dispatch/Slot.luau` → `Slot/Handler.luau`, 옛 `Modifier.luau`+`Dispatch/Modifier.luau` →
`Dispatch/Modifier/{init,Handler}.luau` 이동도 끝났다(9절 4번). 아래 "규칙(제안)"·"이동"·"권고: 한다"는 결정 전
서술(보존용).

**사실**: `Dispatch/`엔 코어(`init`·`Handler` 타입)와 **drive 자신의 단계**(`None`·`StoreBind`
언랩·`Modifier`의 ProcessedModifier·`Ref` pre-pass)가 있고, 이들은 `Dispatch/init`이 직접 등록한다.
반면 `H-278`(사용자 지시) 이후 값 모듈은 자기 핸들러를 자기 파일에서 등록한다(Tag/AttributeKey/
Attribute/Observer/Effect/Ref). **유일한 혼종이 `Slot/Handler.luau`** — 파일은 Dispatch 아래,
등록자는 `Slot/init.luau:1123`, 소비는 `_slotInternal`. 사용자 원문 *"dispatch 가 각 계층의
slot/storebind.luau 같은게 있는게 이상함"* 중 `StoreBind`는 값 모듈이 아니라 **디스패치 자체의
언랩 단계**(Brand만 require, `Dispatch/init:396`이 등록)라 Dispatch 아래가 맞다.

**규칙(제안, `architecture.md`에 명문화)**: *"핸들러는 그 값 타입을 소유하는 모듈 안에 산다
(`H-278`). `Dispatch/` 아래엔 코어와 `drive`의 자기 단계(None/StoreBind/Modifier/Ref pre-pass)만
— 값 모듈이 `Dispatch/init`을 require하므로 그 반대 방향은 구조적으로 불가."*
**이동**: `Dispatch/Slot.luau` → `Slot/Handler.luau`(1절 폴더 안). 그러면 혼종 0.

**Modifier(사용자: "예외적으로 dispatch 안에서 정의되는 객체")**: 사실 — `Dispatch/Modifier/init.luau`는 src
루트의 잎(Init 없음)이고 flatten은 `drive`의 첫 단계(round17 Q4 (a) "flatten은 drive 소유"),
`Dispatch/Modifier/Handler.luau`는 ProcessedModifier 핸들러 38줄. 사용자 판단은 근거가 있다 — Modifier는
값이라기보다 **drive의 입력 형식**이다. 이동: `Modifier.luau` → `Dispatch/Modifier/init.luau`,
`Dispatch/Modifier.luau` → `Dispatch/Modifier/Handler.luau`(또는 init에 흡수 — 38줄). 순환 없음
(Modifier는 Brand/ErrorNamespace/Dispatch/None만 require). 비용: `init.luau` require 경로 하나,
md 인용 10곳(`Dispatch/Modifier/init.luau`가 두 번째로 많이 인용됨), `modifier-plan.md` 트리 서술.
**권고: 한다** — 규칙(위)이 "Dispatch/ = drive의 자기 단계"인데 flatten이 정확히 그것.

## 6. Ref 패밀리 — **권고: `Ref/{init,PreRef,PostRef}.luau`, `Dispatch/Ref.luau`는 그대로**

**[결정 2026-09-07 밤 — 4절 (a)의 구성 요소로 채택, 반영 완료]** (a) 폴더 그대로 이동됐다(9절 4번). 아래는 결정 전
서술(보존용).

**사실**: `Ref/PreRef.luau`(34)·`Ref/PostRef.luau`(35)는 각각 **한 줄 함수** — `Ref._tagged(default, Brand,
marker)`. 의존은 PreRef/PostRef → Ref 단방향, Ref는 `Brand.isPreRef`만 본다. `Dispatch/Ref.luau`
(pre-pass + Processed 센티널 둘)는 헤더가 밝히듯 drive의 단계라 Dispatch 아래가 맞다(5절 규칙).
**선택지**: (a) 폴더 `Ref/`(init 256 + PreRef 34 + PostRef 35) / (b) 둘을 `Ref/init.luau`에 흡수(한
파일 ~300줄, `_tagged` 사유 주석 *"one factory so the marker/_fired conventions cannot drift
between the two files"*가 오히려 한 파일을 가리킨다). **권고 (a)** — 사용자 원문대로 폴더가 "각자로
보기 좋게"; 흡수는 `PreRef`/`PostRef`가 공개 이름이라 찾기 어려워진다. 비용 최소(md 인용 `Ref` 6·
`PreRef` 1).

## 7. Attribute 패밀리 — **권고: `Attribute/{init,Key}.luau`, 핸들러는 각자 안에**

**[결정 2026-09-07 밤 — 4절 (a)의 구성 요소로 채택, 반영 완료]** `Attribute/{init,Key}.luau`로 이동됐다(9절 4번);
`Attribute/Handler.luau` 분리는 하지 않았다(급하지 않음). 아래는 결정 전 서술(보존용).

**사실**: `Attribute/init.luau`(279) → `Attribute/Key.luau`(136) 단방향(`_newUncachedKey` 사적 경로 —
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

## 9. 실행 순서(결정 뒤) — 상태 [2026-09-07 밤]

1. §4 Q9·Q14 답 → 동작 수정 커밋(작음). **완료**(회신 3차).
2. 3절 Tag 유니언(코드 20줄 + 타입 + 정본) — 독립, 먼저 해도 됨. **완료**(`02adb01`).
3. 2절 Tween — 결정은 (b) 통째 이동. **완료**(Brand→quad-types와 같은 커밋).
4. 순수 이동 단위 하나: 1·5·6·7절(8절 이름은 미답이라 제외) — 동작 diff 0, `spec.*` 전량 +
   `doc-check.py` `.luau` 경로 검사 확장 + md 인용 치환 + `architecture.md` 트리·5절 규칙 명문화 +
   `README`. **완료(2026-09-07 밤)** — `Ref/{init,PreRef,PostRef}`·`Attribute/{init,Key}`·`Dispatch/Modifier/
   {init,Handler}`는 메인이(비-init 파일만 `./`→`../`; `Dispatch/Modifier/init.luau`는 `./`가 `Dispatch/`라
   `./None`), `Slot/{init,Owner,Elements,Raw,Tree,List,Handler}`는 opus 서브에이전트가 내부 표 `S`(늦은 조회
   `S.fn(...)` — 전방 선언의 파일 판, 프렐류드 값 18개는 설치 전 `S`에)로 분할 — 함수 목록 동일·본문 다중집합
   diff는 의도한 네 줄(`ExtractAll`의 `(S.unwrapElement(…))` 괄호, 태깅 루프의 `S.List/S.Single`, `Slot` 전방
   선언, `Handler` require)뿐. `doc-check.py`는 `.luau` 참조를 소스 색인 접미 일치로 검사(패키지 루트부터 적은
   경로는 ERROR, 이름·부분 경로는 WARN, `initreq` 외부 소스는 이름 폴백); 옛 경로 인용 143줄+4줄 치환. 잔여
   WARN 17건은 애초에 없던 파일 이름을 "없다"고 서술한 자리(`Handlers/Tween.luau`·`Dispatch/Leaf.luau` 등).
5. 이동 뒤 순회 1회(직전 수정분 회귀 관측이 규칙이므로).
6. **[추가]** 10절의 후속 제안 — Brand→quad-types(완료, 3번과 같은 커밋), 마커 전면화 +
   quad-types 재배치(**완료**, 한 커밋), D 정적 굽기(리서치 — 사용자 문항).

## 10. 후속 제안 넷 — 사용자 회신(2026-09-07 밤)의 "+" 항목

### 10-1. `Brand` 팩토리를 quad-types로 — **채택·반영 완료**

사용자: *"Brand 에 대한 구현은 types 로 빼고싶어. 실제로 타이핑을 하는데 있어서 필요한 요소이고,
노미널타이핑을 돕는다 이외의 동작이 없어서 enum 과 비슷하게 특수 런타임 객체로 types 안에 실어두는게
좋아보여. 실제로 20줄도 되지 않거든. isTween 가 base 안에 있어서 tween 을 못 옮긴것 같은데, Brand 들은
각각 quad-base 안에 Brand 들을 정의하는게 따로 있으면 될것 같아. 같은 방식으로 quad-roblox 에서도
하는거지. 이건 중요한게 quad-spring 같은 곳에서도 SpringBrand 를 만들려면 선재로 미리 처놔야하는
것으로 보여"*. 반영: `QuadTypes.Brand`(런타임 값 + 타입), quad-base `Brand.luau`는 인스턴스·술어만,
quad-roblox `Brand.luau` 신설(`TweenBrand`/`isTween`). 정본은 `base/brand-plan.md` 구현 절 배너.
남은 한 조각: base `BRAND_PROBES`가 여전히 `"isTween"` 문자열을 적어 둔다(진단 이름 조회) —
프로바이더 등록 메커니즘은 새 표면이라 round3 §4 Q27.

### 10-2. `None`·`Tag`·`Attribute`·`Observer`·`EffectHandle`도 마커로 — **채택(사용자 제안), 반영 완료(2026-09-07 밤)**

사용자: *"None, Tag, Attribute, Observer, EffectHandle 들도 전부 사실 marker 구조로 가도 될것 같아."*
사실: `None`은 이미 마커(`__quadNone`, `H-300`), `Tag`는 3절 반영에서 `__quadTag`를 얻었다. 남은 셋은
`AttrImpl.__quadAttribute`/`Observer Impl.__quadObserver`/`Effect Impl.__quadEffect`(H-300 관례 —
`__index`로 읽히는 무비용 필드)와 quad-types `AttributeMarker`/`ObserverMarker`/`EffectHandleMarker`,
그리고 입력 자리(`NewChild`와 그 안의 `StateMarker<…>` 팔, gen-d의 8.9 게이트 수확 목록)를 마커로
바꾸는 것. 필드·별칭 이름은 기존 `__quad<Type>`/`<Type>Marker` 패턴을 따른 메인 작명 — 사후 확인.

### 10-3. quad-types 단일 파일 재배치 — **채택, 반영 완료(10-2와 같은 커밋 — 순수 재배치, 줄 다중집합 diff 0 + 절 머리 주석 9줄)**

사용자: *"quad-types 도 다듬을 필요가 있어보임 — 사람이 보기에 복잡하고, 부분 부분 검토해보기 어려운
구조임 … 모든 마커 타입을 위쪽에 올려서 표현하고, 중간엔 구현타입만 넣고, 맨 아래 실제 Quad 익스포팅
타입을 넣는 구조로 단일 파일로 유지해도 좋을듯. — 단일 파일로 두는게 배포 상 ModuleScript 가 덜 들고,
lsp 가 덜 힘들어 하기 때문임."* 반영 모양: (1) 마커·센티널(`None`/`Detach`/`KeyGone`/`MapperRoot`/
`MapperDescriptor`/`StateMarker`/`SlotMarker`/`TagMarker`/`AttributeMarker`/`ObserverMarker`/
`EffectHandleMarker`/`ModifierMarker`) → (2) 값·핸들 타입(Epoch/Relate/Ref/State/Source/Store/Observer/
Effect/Blocker/Tag/Attribute/Modifier/Slot/Dispatch/Handler) → (3) `Quad`·`CheckedQuad`·`Brand`·상수.
주석·결정 이력은 옮기되 지우지 않는다(순수 재배치, diff는 이동뿐).

### 10-4. `...Param`을 prop 모음에서 조립하는 타입 함수 / 정적으로 더 굽기 — **리서치(사용자 문항)**

사용자: *"우리의 거대한 ...Param 파일들을 각 prop를 모아두고 필요한 부분을 뽑아 조립하는 타입함수의
가능성이 열릴것으로 보임. D 파일의 크기를 크게 줄일 수 있을듯 해보이는데 어떻게 보는지? 정적으로
구워낼 수 있는 부분을 크게 늘려서 처리하는것에 대해서 생각해볼래? 사실 이미 마우스를 올리면 [호버가
마커 유니언 전개형으로 나오므로] 프롭들이 저런식으로 나와서 잃을것은 크게 없다고 보여."*

메인 판단(결정 아님): 두 갈래를 갈라 봐야 한다.
- **(가) 타입 함수로 Param 조립** — `typing-limits.md` §0의 사용자 확정 *"타입 함수는 진단을 띄우는
  데까지만"*(2026-08-25)과 정면으로 충돌한다. 그 결정의 근거는 §6(타입 함수를 거친 값은 이후 제네릭
  self 체이닝이 조용히 깨짐)과 §5(바깥 별칭 참조 불가, `Self` 제네릭 경유 시 콜백 파라미터 추론이
  깨짐 — `WrapStore` 철회)의 실측이다. Param 자리는 `D.Frame({...})`의 인자 — 콜백(이벤트 핸들러)
  파라미터 추론이 정확히 §5가 깨진 그 자리라, 다시 하려면 **스파이크로 그 두 함정을 먼저 재야 한다**
  (호버 표시가 아니라 이벤트 콜백 인자 추론·`Modifier` setter 체이닝·`UseProvider` 교집합 통과).
  또 하나: 타입 함수는 매 인스턴스화마다 *실행*되므로(캐시는 솔버 몫) 31클래스 × 수백 prop을
  조립하면 8.5/8.9/8.12의 예산 문제가 다른 모양으로 돌아올 수 있다 — 지금 D는 4800줄이지만 전부
  "미리 구워진" 리터럴 타입이라 솔버가 하는 일이 적다.
- **(나) 정적으로 더 굽기** — 지금도 D는 전량 생성물이다. 줄일 수 있는 건 *중복 텍스트*(클래스별
  Param이 조상 prop을 다시 나열하는 것 — `GuiObject` 계열 10클래스가 같은 수십 줄을 반복)이고, 이건
  타입 함수 없이 **교집합 별칭**(`FrameParam<E> = GuiObjectProps & FrameOwnProps<E>`)으로도 줄어든다 —
  단 교집합은 8.6/8.8이 실측한 "무거주·캐스트 붕괴" 계열이라 이것도 스파이크가 필요하다(호버·자동완성·
  `too complex` 예산). 마커 전면화(10-2)로 유니언 팔이 줄어드는 건 이것과 독립적으로 이득.
- 정리하면: **10-2·10-3을 먼저 반영하고 그 크기에서 (나)의 교집합 별칭 스파이크 → 그래도 부족하면
  (가)를 §0 재검토 문항으로.** 사용자 결정 필요: (가)를 열어 볼 것인가(§0 확정의 예외), 아니면
  (나)까지만인가. `question.md` 2절에 올려 둔다.
