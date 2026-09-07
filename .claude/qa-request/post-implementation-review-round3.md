# 구현 뒤 코드 리뷰 원장 round3 — 2026-09-07 (`H-431`~, 문항 `Q22`~)

> **이 파일이 무엇인가**: 구현 뒤 리뷰의 세 번째 라운드 파일(라운드 번호는 사용자 결정으로 1부터 —
> round1 = 순회 0~7 + 회신 §15·§16, round2 = Gemini 외부 리뷰 원문). 이 라운드의 대상은 **회신 1차·2차
> 반영 커밋 둘**(`0659a4d` Q2/Q3 반영, `8b4748a` 입력 자리의 State/Slot 타입을 공변 마커로) — 단위 끝
> 절차(감사자 1패스 → `/code-review high`, 파인더·검증자 opus 지정, 미완 0). 세 갈래·처리 규약은 round1
> 준용. 발견 번호는 round1의 `H-430`에 이어 **`H-431`부터**, 사용자 문항은 round1 §4의 `Q21`에 이어
> **`Q22`부터**(round1 §4 표는 Q1~Q21의 소스로 남고, 이 파일 §4가 Q22~의 소스).

## §1 반영한 것 (갈래 ① — 이 커밋)

| ID | 자리 | 무엇 | 처리 |
|---|---|---|---|
| **`H-431`** (HIGH) | `quad-roblox/src/types.luau` `NewChild` | 첫 마커 팔 `StateMarker<(Instance \| SlotMarker<Instance> \| Tag \| Attribute \| None)?>`가 `Observer`/`EffectHandle`을 뺐고 주석이 "정본에 없다"고 적었는데 **틀렸다** — `slot-plan.md`가 leaf 종료 관용구로 `State<Observer?>`(nil emit으로 구독 해제)를 지시하고 런타임(StoreBind 언랩 → leaf 핸들러/NilHandler)도 받는다. `q.D.Frame({ q.Source(nil :: Observer?) })`가 strict 거부(재현) | 안쪽 유니언에 `Observer \| EffectHandle` 합류, 주석 정정. `spec.componenttypes` `_markerChildren`에 둘. 타입 검사 시간 2.95s(늘지 않음) |
| **`H-433`** (LOW-MED) | `types.luau` `AnimateInfo.Override` | 형제 여덟은 `StateMarker`인데 `Override`만 전체형 `State<TweenOverride>`로 남았다(누락 — 근거 없음). 문자열 싱글톤 유니언이라 정확히 8.11의 불변 케이스 | 마커로. 헤더 주석 "각 필드는 `T \| State<T>`"에 배너 |
| **`H-434`** (LOW) | `Bookkeeping.luau` `setEmpty` | Dispatch 표면이라 `H-242` 루프가 SURFACE로 태그하는데 본문이 지역 `setOffsetSource`(같은 함수 객체 — 역시 태그됨)를 부른다 → `checkPosition`이 안쪽에서 던지면 nearest+1이 `setEmpty` 본문(quad 내부)을 blame(옛 `registerEmptySlot`은 무태그였다). `H-250` 인라이닝 의존 | `setEmpty`가 자기 앞에서 `checkPosition("setEmpty", i)`. `spec.lengthoffset` 9절에 `setEmpty` 케이스 + `assertBlamesUser` |
| **`H-435`** (LOW, 문서) | `typing-limits.md` 8.5·8.9 (3) | `LuauSolverConstraintLimit`이 "test.sh 넷째 플래그"라고 현재형 — 같은 커밋이 제거했고 8.11이 그렇게 적었다(배너가 부정하는 문장을 같은 커밋에서 안 고침) | 두 자리 정정 |
| **`H-436`** (LOW, 주석) | `spec.shorthandtypes` 헤더·`spec.tweentypes` 헤더·`spec.modifiertypes` 41행·`None.luau` 묘비 | 옛 다섯 팔·멤버별 팔·`SHF0`·"각각 나열"을 현재형으로; `None.luau`는 사라진 `registerEmptySlot`을 서술 | 넷 정정(묘비는 한 줄 포인터로) |
| **`H-438`** (LOW, 재사용) | `gen-d.py` `qt` | `strip_comments()`를 정의해 놓고 두 줄 위 `qt`는 같은 정규식 리터럴 인라인 — `H-388`의 "한 번만 벗긴다" 논거가 두 리터럴로 갈라짐 | `qt = strip_comments(...)`, 정의를 위로 |
| **`H-439`** (LOW, 개수) | `architecture.md` Bookkeeping 행·round1 §15 Q3 ③ | `_bookkeeping` 목록에 `setEmpty` 없음; "quad-base 호출 10곳"은 실제 9곳(반영 뒤 8곳 — Ref/Modifier 사본이 `addProcessedHandler`로 접힘) | 행에 `setEmpty` 추가, §15 개수 정정 |
| — | `gen-d.py` 주석 둘 | `FieldOut`이 "Peek 반환과 같은 층"(Peek엔 Tween 팔이 없다), "세 팔이 같은 유니언 — 별칭 하나로"(마커로 깨진 옛 규칙) | 정정 — 모양 자체는 **§4 Q23** |

## §2 확인만 한 것 (검증자 음성 — 재발견 금지)

`setEmpty` 12곳의 `anchor` 인자 동일·`setLength`를 감시하는 spec 없음 / `NotInstalled` 메시지 셋이 옛 본문과 바이트
동일(spec 매치 `spec.lifetime` 54·59, `spec.tag` 60, `spec.attribute` 217) / `getfenv(install*).game` seam 유지(`Reflection.luau`는
`game`을 이름조차 안 씀) / `Impl.__quadState`·`Slot_mt.__quadSlot`은 어떤 게이트와도 충돌 없음(`getmetatable == nil` 게이트는
State/Slot을 제외, `State.luau`·`Slot.luau`의 태그 루프는 명시 목록) / `TweenData`·`Tween`은 전부 `read`라 gen-d가 버린 멤버별
팔로 잃는 것 없음 / `gen-d.py check` 통과 / 트레일러 정상. 기각(리뷰어): `reserved` 수확 정규식의 열 0 앵커(미래 문제 —
`{Apply,Peek,Overridden,As} <= reserved` 단언이 지금 코드를 지킴), 음성 프로브가 tmp에만 있던 것(strict spec은 must-fail을
못 담는다 — 인정된 한계), `StateData`/`Slot`이 마커 필드를 교집합 대신 복제한 것(어긋나면 시끄럽게 깨짐).

## §4 사용자 문항 (갈래 ②)

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **Q22** (`H-432`, MED-HIGH) | **Slot 요소 자리의 공변 마커 + 가변 출력의 건전성.** `SlotElement<T>`의 `SlotMarker<T>` 팔은 공변이라 `outer: Slot<Instance>`에 `frames: Slot<Frame>`을 `Add`할 수 있는데, `outer:Get(1)`의 출력 `SlotItem<Instance>`는 그 값을 전체형 **`Slot<Instance>`**라 말한다 — 그 핸들로 `inner:Add(folder)`가 strict를 통과하고(런타임 요소 게이트는 `isInst`뿐, 클래스 검사 없음) 나중 `frames:ExtractAll()[1] :: Frame`이 거짓이 된다. State는 `Set`이 `Source`에만 있어 출력 전체형이 건전하지만 Slot은 `Add`가 `Slot<T>` 자신에 있어 **입력 공변 + 가변 출력**이 만나는 유일한 자리. 8.11의 `read` 논거·§16 음성 아홉이 이 도달 경로를 안 봤다(회신 2차의 승인 범위는 방향이지 이 결과가 아님) | (a) 유지 + typing-limits 캐비엇으로 명시(중첩 Slot의 출력 타입은 상한 `Slot<T>`이고 실제 요소 타입은 사용자가 지킨다 — 런타임은 원래 클래스를 안 가렸다) / (b) Slot 팔만 불변으로 되돌림(`SlotElement`의 Slot 팔을 전체형 `Slot<T>`로 — `Slot<Frame>`을 `Slot<Instance>`에 중첩하려면 캐스트) / (c) 출력 `SlotItem<T>`의 Slot 팔을 `SlotMarker<T>`(읽기 핸들 — 변형하려면 캐스트) | **(a)** — 런타임이 처음부터 요소 클래스를 안 가리므로 타입만 "상한"으로 정직하게 서술하면 되고, (b)는 중첩 관용구를 되돌리며 (c)는 출력을 못 쓰게 만든다. 단 새 사고 경로라 사용자 판단 **[2026-09-07 회신 4차] 닫힘 — (a) 그대로 — *"타입을 아는 유저가 처리하도록 두길 바람"*; typing-limits 8.11 캐비엇**(§7) |
| **Q23** (`H-432` 짝, MED) | **변환 함수 `old`의 타입 `FieldOut<T>` 모양.** 지금 `T \| Tween<T> \| State<T> \| State<Tween<T>> \| None`인데 입력 `FieldV`가 마커로 받는 정직한 `State<T \| Tween<T>>`·유니언 T의 멤버 State(`Field<number \| UDim>`에 `State<number>`)를 서술하지 못하고, State 팔이 둘이라 `old:Get()`이 유니언 호출로 거부돼 "old:Get()을 부를 수 있게"라는 자기 목적을 못 이룬다(`Modifier.luau`는 나중 변환을 `old:Compute`로 태워 `old`가 저장된 핸들 그대로) | (a) `FieldOut<T> = T \| Tween<T> \| State<T \| Tween<T>> \| None`(State 팔 하나 — 출력이라 상한으로 정직, `(old :: State<T \| Tween<T>>):Get()`이 `T \| Tween<T>`) / (b) `old: FieldV<T>?`(마커 — 메소드는 캐스트) / (c) 그대로 | **(a)** — 출력 자리의 State는 "저장된 것의 상한"이면 되고 `Set`이 없어 건전. 새 타입 모양이라 문항 **[2026-09-07 회신 4차] 닫힘 — (a) — *"권고 동의, 처음 내 생각도 그랬음"*; gen-d `FieldOut` State 팔 하나, spec**(§7) |
| **Q24** (`H-437`, 규약) | **회신 2차 승인의 범위를 갈라 적기.** 사용자가 승인한 것은 방향(*"공변성/불변성 문제를 해결하기 위한 작업"*)과 순수 팬텀(*"런타임 값에 없는 팬텀 괜찮아"*)이고, 메인이 정한 것은 **이름 둘**(`SlotItem<T>`, `FieldOut<T>` — 입력/출력 별칭 분리), `NewChild` 팔 모양(`StateMarker<(… \| None)?>` 하나, nil 포함), `LuauSolverConstraintLimit` 제거다. `base/` 배너 "[2026-09-07 마커 — 사용자 결정]"이 넷을 승인된 것처럼 읽히게 한다(규약: 새 이름·메커니즘은 문항, 인용 옆엔 갈라 적을 것) | (a) 넷 그대로 승인 / (b) 이름을 바꾼다(제안: `SlotElement`/`SlotItem` → `SlotInput`/`SlotOutput`, `FieldV`/`FieldOut` → `FieldIn`/`FieldOld` 등) / (c) 팔 모양·플래그만 승인, 이름은 보류 | **(a)** — 이름은 기존 `FieldV`·`SlotElement`와 짝이 맞고 8.11이 역할별 별칭을 규칙으로 적었다. 8.11 배너에 "승인 = 방향·팬텀, 제안 = 이름·팔 모양·플래그"를 갈라 적어 둠(이 커밋) **[2026-09-07 회신 4차] 닫힘 — (a) 넷 그대로**(*"괜찮네. 확인했어"*, §7). 후속 질문 *"FieldOut<T> 는 그럼 Peek 에도 사용되는걸까?"* → 지금은 아니었다(Tween 팔 없는 옛 유니언) → `Peek` 반환을 `FieldOut<T>?`로 통일, 별칭 정의를 quad-types로 |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0, quad-roblox 타입 검사 2.95s.

## §5 외부 리뷰 round4 검증 — Gemini 4차 (`post-implementation-review-round4.md`, 사용자 반입 2026-09-07)

round2와 같은 절차(실재현 뒤 판정). 다섯 전부 실존 — `H-417`/`H-421` 계열(빈 문자열)과 `H-418`/`H-419` 계열(nil·비테이블
인자가 내부 VM 에러로 죽어 quad 줄을 blame)의 남은 구멍이었다.

| ID | 출처 | 자리 | 무엇 | 처리 |
|---|---|---|---|---|
| **`H-440`** | G-10 (HIGH) | `Handlers/OnChange.luau` 생성자 | `OnChange("", fn)`이 통과해 `GetPropertyChangedSignal("")` 엔진 예외가 디스패치 깊이에서(부기 등록 뒤) | `name == ""` 거부(nearest). `spec.events` 7절 |
| **`H-441`** | G-11 (MED) | `Slot.luau` `List`/`reconcile` | `updateFn` 타입 무검사, `items`가 nil/비테이블이면 `#items` VM 에러가 `Slot.luau:950`을 blame | `List` 머리에 둘 다 게이트(nearest) + `reconcile` 머리(State 값 경로, outermost). `spec.slot` 24절 |
| **`H-442`** | G-12 (LOW) | `Dispatch/init.luau` `drive` | `drive(nil, props)`가 Relate `table index is nil` | `inst == nil` 게이트(`H-419` 옆). `spec.dispatch` 17절 |
| **`H-443`** | G-13 (HIGH) | `Store.luau` `checkKey`·`Attribute.luau` `isStore` 분기 | `Store({ [""] = … })`/`Of("")` 통과 → `Attribute(store)`가 `setAttribute("")`에 디스패치 깊이로 | 두 자리 모두 `""` 거부(`H-421` 자매). `spec.store` 9절(기존 단언 문구 둘 정정) |
| **`H-444`** | G-14 (MED) | `LifetimeHandle.luau`(roblox·mock) | `unbindLifetime(nil)`이 헤더 계약("no-op if unbound")과 달리 Relate VM 에러, `canExecute(nil)`/`canBound(nil)`/`bindLifetime(nil, v)`도 | `isBoundAlive`/`unbindLifetime` nil 조기 반환, `bindLifetime` nil inst는 미claim 메시지. Relate 자체는 안 건드림(관측된 문제에만). `spec.lifetime` 10절 |
| — | S-07~S-10 | `destroySlotTree` Owned=false 생존 / `Overridden()` 0인자 비대칭 / 중첩 Slot `occupantOf` / `UIPadding` 공유 자식 | 건전 판정 — 정본 인용이 정확 | 확인 기록 |

## §6 사용자 회신 3차 — Q4~Q19 + Q7 둘째·셋째 (2026-09-07 저녁, 대화형)

사용자 지적: 원장의 문항이 *"기호가 많고, 압축서술이 너무 많아서 맥락을 모르겠음"* — Q3/Q5/Q7/Q9/Q14/Q18/Q19는 채팅에서
평문으로 다시 설명한 뒤 결정을 받았다. **앞으로 문항은 평문 한 문단(상황 → 무엇이 막히나 → 갈래의 뜻)으로 쓴다.**
Q3은 회신 1차에서 이미 닫힌 것을 다시 짚음(항목별 결과 §15). 열린 것: **Q6·Q20·Q21**(미답), Q22~Q24(round3 §4).

| 문항 | 결정(사용자 원문) | 처리 |
|---|---|---|
| **Q4** | 권고대로 (a) | 코드 0. `source-state-plan.md` `H-361` 배너에 확정 표기 |
| **Q5** | (a) UB + *"처음부터 그런 Set이 나는게 UB가 되는게 맞아보여 … compute 의 부작용은 readonly 이고 하류로 내리기만 한다를 크게 잡아두면 … 재진입 게이트는 허용 안한다"* | `dispatch-core-plan.md` UB 목록에 같은 키 간접 재진입; **`source-state-plan.md` 새 절 "Compute 순수성"**(원칙 — 사용자 제안 + 메인 동의); 값싼 가드 후보는 `research/deferred-hardening-plan.md` 1절 |
| **Q7** | (a) 유지 + *"error util 안에 … 살을 더 붙여가며 위로 올리면"*은 추후 | 코드 0. 에러 컨텍스트 래핑 아이디어 → `research/deferred-hardening-plan.md` 2절 |
| **Q7 둘째·셋째** | (a) | 둘째 코드 0(`effect-plan.md` 주석 확정 표기); 셋째 `State.luau` Compute-Modifier 에러 `errorBefore`; `quad-error` 헤더에 예외 문장 |
| **Q8** | (a) | `Animate.luau` Compute 머리 `if v == nil or v == None then return v end`; `tween-plan.md` 의사코드 한 줄; `spec.tweenproperty` 7절 |
| **Q9** | (b) — *"해당 좀비는 진짜 죽은게 맞음 … Instance 와 같은 동형으로 두어도 되는 부분. 메시지를 잘 정리하고 UB부분을 문서화만 하면"* | `Slot.luau` "already mounted" 셋·`dispose` 메시지에 "quad 밖에서 파괴됐으면 함께 죽은 것 — 미리 뽑아라" 문구; `slot-plan.md` "부수 효과" 문단 철회 + UB. `spec.slot` 24절 |
| **Q10** | (c) — *"오용 표면을 막을 이유를 모르겠음. UB로 두어도 되는 부분"* | `module-lifecycle-plan.md`·`RobloxFactory.luau` 헤더 UB 문장 |
| **Q11** | (a)+(c) — *"런타임 에러 추가가 무료급이고 … 문서도 같이"* | `Modifier.luau` `__index`에 문자열 키 게이트(+ `__index` SURFACE 태그 — 메타메소드 자체가 raise); `modifier-plan.md`; `spec.modifier` 14절 |
| **Q12** | 사용자 설계 — *"Animate 자체가 이전 Tween 값 비교와 이전 Tween 을 그대로 리턴하여 dedup … Dedup: boolean 형태 하나"* | `Animate.luau` `sameTween` + `Dedup` 옵션(기본 true), `Property.luau` 슬롯에 `Source = v`(필드 이름 `Source`는 메인이 붙인 것 — 사용자 사후 확인) + 같은 객체 재발행 skip, `types.luau` `AnimateInfo.Dedup`; `tween-plan.md`; `spec.tweenproperty` 7절(Dedup=false 재트리거 포함) |
| **Q13** | (b) | `Bookkeeping.luau` `setOffsetSource` 게이트(Source \| None, nearest); `spec.lengthoffset` 12절 |
| **Q14** | (a) — *"동의. a로 가도 돼"* | `destroySlotTree` 두 루프 `releaseOwner`; `slot-plan.md` C-4 면제 철회; `spec.slot` 24절 |
| **Q15** | (a) | `setLength` 상수 도메인(비음수 정수, 등록 시) + State 값은 `contribution`에서(outermost); `dispatch-core-plan.md` 계약 줄; `spec.lengthoffset` 12절 |
| **Q16** | (b) | `Tween.validate`가 `isState(Value)` 거부; `spec.tween` 6절 |
| **Q17** | (a) — *"필요 없는듯 … 다른 프로퍼티와 같게 되어도 좋음"* | `InstanceShorthand.luau` `numberOnly` 필드·게이트 제거; `spec.shorthand` 6절 정정; `ui-shorthand-plan.md` |
| **Q18** | (c) — *"에러로 죽은 다음 우린 데이터의 무결이 깨져도 상관이 없고 … 당장은 c로 닫고, 리서치 안에서"* | `dispatch-core-plan.md` UB 목록; (a)는 `research/deferred-hardening-plan.md` 3절 |
| **Q19** | (a) — *"읽기 표면을 만드는걸 동의함"* | gen-d 정규화가 ReadOnly 프로퍼티를 `readProps`로 따로 싣고(109개, dropped 575 → 466), `PropTypesRead`·`<Class>OnChange`가 그 표면을 쓴다(`PropTypes`는 쓰기 그대로); 재정규화·재생성; `onchange-plan.md`·typing-limits 8.10; `spec.onchangetypes` 양성(AbsoluteSize/AbsolutePosition/TextBounds) |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0, 타입 검사 3.06s.

## §7 사용자 회신 4차 — Q6·Q20·Q21(round1)·Q22·Q23 (2026-09-07 밤, 대화형)

| 문항 | 결정(사용자 원문) | 처리 |
|---|---|---|
| **Q6** | 약속 철회 + 백로그 — *"문서의 약속을 우선 빼고, 아에 백로깅 … 지금은 코드의 사실로 맞추자. 다만 잠정적으로 볼 땐, 있는게 맞다"* | `slot-plan.md` "기본 구현(조합 폴백)" 배너·`architecture.md` EngineOps 줄·`dispatch-core-plan.md`·`debounce-throttle-plan.md` 언급 정정; ROADMAP 백로그에 "`native*` 조합 기본 구현" 신설. 코드 0 |
| **Q20** | 메시지 확장 — *"죽은것에 시도하거나 quad가 만진게 아니다로 … 파괴 여부를 알아내야하는데, 그런건 없다고 이미 이전에 결론났음 … Clone 직후 … parent 가 nil"* | `LifetimeHandle.luau`(roblox) 미claim 메시지가 둘을 함께 말한다(접두 "Instance is not claimed by quad" 유지 — `spec.robloxfactory` 매치); `claim-plan.md` 13번 앞에 "가를 수 없다" 기록. Studio 실측 불필요 |
| **Q21** | (b)+(c) 폐기 — *"selene 가 의미가 크게 없어보여 … 루아우 버전을 고정하는것도 동의"* | `mise.toml`에 `luau = "0.734"`(설치 확인 — `mise exec -- luau`가 0.734), selene 핀 제거 + 패키지 넷의 `selene.toml` 삭제; `project-setup-plan.md` "`selene` 린터" 절 배너·트리, `architecture.md`, README |
| **Q22** | (a) — *"java 나 다른 곳에서도 결국 진짜 데이터 넣는 방법을 아는 유저가 cast 한다가 일반적 … 마치 Object 같은 개념"* | `typing-limits.md` 8.11 캐비엇 한 문장. 코드 0 |
| **Q23** | (a) — *"권고 동의, 처음 내 생각도 그랬음"* | gen-d `FieldOut<T> = T \| Tween<T> \| State<T \| Tween<T>> \| None`, D 재생성; `spec.shorthandtypes` `_markerUnion`에 캐스트 뒤 `old:Get()` 양성 |
| **Q24** | 설명 뒤 (a) — *"괜찮네. 확인했어."* + *"FieldOut<T> 는 그럼 Peek 에도 사용되는걸까?"* | 넷 그대로 승인. Peek은 옛 `T \| State<T> \| None \| nil`(Tween 팔 없음)이었다 → `FieldOut<T>?`로 통일: `FieldOut` 정의를 quad-types로 올리고 D는 별칭, base `Modifier`·생성 `<Class>Modifier`의 `Peek` 둘 다; `spec.modifiertypes` 단언 갱신; `modifier-plan.md` "`:Peek<<T>>(key)`의 반환 타입" 항목 배너 |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0.
다음 순회는 이 파일 §8부터, `H-445`부터.
