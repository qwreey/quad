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
| **`H-431`** (HIGH) | `quad-roblox/src/types.luau` `NewChild` | 첫 마커 팔 `StateMarker<(Instance \| SlotMarker<Instance> \| Tag \| Attr \| None)?>`가 `Observer`/`EffectHandle`을 뺐고 주석이 "정본에 없다"고 적었는데 **틀렸다** — `slot-plan.md`가 leaf 종료 관용구로 `State<Observer?>`(nil emit으로 구독 해제)를 지시하고 런타임(StoreBind 언랩 → leaf 핸들러/NilHandler)도 받는다. `q.D.Frame({ q.Source(nil :: Observer?) })`가 strict 거부(재현) | 안쪽 유니언에 `Observer \| EffectHandle` 합류, 주석 정정. `spec.componenttypes` `_markerChildren`에 둘. 타입 검사 시간 2.95s(늘지 않음) |
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
State/Slot을 제외, `State.luau`·`Slot/init.luau`의 태그 루프는 명시 목록) / `TweenData`·`Tween`은 전부 `read`라 gen-d가 버린 멤버별
팔로 잃는 것 없음 / `gen-d.py check` 통과 / 트레일러 정상. 기각(리뷰어): `reserved` 수확 정규식의 열 0 앵커(미래 문제 —
`{Apply,Peek,Overridden,As} <= reserved` 단언이 지금 코드를 지킴), 음성 프로브가 tmp에만 있던 것(strict spec은 must-fail을
못 담는다 — 인정된 한계), `StateData`/`Slot`이 마커 필드를 교집합 대신 복제한 것(어긋나면 시끄럽게 깨짐).

## §4 사용자 문항 (갈래 ②)

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **Q22** (`H-432`, MED-HIGH) | **Slot 요소 자리의 공변 마커 + 가변 출력의 건전성.** `SlotElement<T>`의 `SlotMarker<T>` 팔은 공변이라 `outer: Slot<Instance>`에 `frames: Slot<Frame>`을 `Add`할 수 있는데, `outer:Get(1)`의 출력 `SlotItem<Instance>`는 그 값을 전체형 **`Slot<Instance>`**라 말한다 — 그 핸들로 `inner:Add(folder)`가 strict를 통과하고(런타임 요소 게이트는 `isInst`뿐, 클래스 검사 없음) 나중 `frames:ExtractAll()[1] :: Frame`이 거짓이 된다. State는 `Set`이 `Source`에만 있어 출력 전체형이 건전하지만 Slot은 `Add`가 `Slot<T>` 자신에 있어 **입력 공변 + 가변 출력**이 만나는 유일한 자리. 8.11의 `read` 논거·§16 음성 아홉이 이 도달 경로를 안 봤다(회신 2차의 승인 범위는 방향이지 이 결과가 아님) | (a) 유지 + typing-limits 캐비엇으로 명시(중첩 Slot의 출력 타입은 상한 `Slot<T>`이고 실제 요소 타입은 사용자가 지킨다 — 런타임은 원래 클래스를 안 가렸다) / (b) Slot 팔만 불변으로 되돌림(`SlotElement`의 Slot 팔을 전체형 `Slot<T>`로 — `Slot<Frame>`을 `Slot<Instance>`에 중첩하려면 캐스트) / (c) 출력 `SlotItem<T>`의 Slot 팔을 `SlotMarker<T>`(읽기 핸들 — 변형하려면 캐스트) | **(a)** — 런타임이 처음부터 요소 클래스를 안 가리므로 타입만 "상한"으로 정직하게 서술하면 되고, (b)는 중첩 관용구를 되돌리며 (c)는 출력을 못 쓰게 만든다. 단 새 사고 경로라 사용자 판단 **[2026-09-07 회신 4차] 닫힘 — (a) 그대로 — *"타입을 아는 유저가 처리하도록 두길 바람"*; typing-limits 8.11 캐비엇**(§7) |
| **Q23** (`H-432` 짝, MED) | **변환 함수 `old`의 타입 `FieldOut<T>` 모양.** 지금 `T \| Tween<T> \| State<T> \| State<Tween<T>> \| None`인데 입력 `FieldV`가 마커로 받는 정직한 `State<T \| Tween<T>>`·유니언 T의 멤버 State(`Field<number \| UDim>`에 `State<number>`)를 서술하지 못하고, State 팔이 둘이라 `old:Get()`이 유니언 호출로 거부돼 "old:Get()을 부를 수 있게"라는 자기 목적을 못 이룬다(`Dispatch/Modifier/init.luau`는 나중 변환을 `old:Compute`로 태워 `old`가 저장된 핸들 그대로) | (a) `FieldOut<T> = T \| Tween<T> \| State<T \| Tween<T>> \| None`(State 팔 하나 — 출력이라 상한으로 정직, `(old :: State<T \| Tween<T>>):Get()`이 `T \| Tween<T>`) / (b) `old: FieldV<T>?`(마커 — 메소드는 캐스트) / (c) 그대로 | **(a)** — 출력 자리의 State는 "저장된 것의 상한"이면 되고 `Set`이 없어 건전. 새 타입 모양이라 문항 **[2026-09-07 회신 4차] 닫힘 — (a) — *"권고 동의, 처음 내 생각도 그랬음"*; gen-d `FieldOut` State 팔 하나, spec**(§7) |
| **Q25** (round3 §8 리뷰, 높음) | **숏핸드 키에서는 Q12의 dedup이 안 선다.** 상황: `UICorner`나 `UIPaddingOffset`에 `Animate`를 건 값을 같은 값으로 다시 발행하면, `Animate`는 이전 Tween 객체를 그대로 돌려주지만 숏핸드 핸들러가 그 Tween을 자식 프로퍼티 값으로 바꾸려고 `Mapped`를 부르는 순간 **새 Tween 객체**가 만들어집니다. Property 핸들러의 dedup은 "같은 객체인가"로 판단하므로 매번 다른 객체가 도착해 활성 트윈이 취소되고 처음부터 다시 시작됩니다(`H-391` 증상이 이 두 키에만 남음). `UIPadding`/`UIScale`은 값을 그대로 넘기므로 무사합니다. | (a) 숏핸드 핸들러가 (inst, 키)마다 "마지막 원본 Tween → 변환된 Tween" 한 쌍을 기억해 원본이 같으면 같은 변환 결과를 재사용한다(작은 캐시 하나) / (b) 변환된 Tween이 원본을 기억하고 Property 핸들러가 원본을 신원으로 본다(Tween에 필드 하나 추가) / (c) 두 키는 예외로 문서화 | **(a)** — 핸들러 안에서 닫히고 Tween 값 타입은 안 건드린다. 새 부기라 사용자 결정 |
| **Q26** (round3 §8 리뷰, 중간) | **트윈 슬롯이 "처음 스냅한 뒤"에는 dedup 정보가 없다.** 상황: 애니메이트된 프로퍼티의 첫 값은 애니메이션 없이 바로 대입되고 슬롯에는 "한 번 썼다"는 표시(`true`)만 남습니다. 그 직후 같은 값이 다시 발행되면 `Animate`는 이전 Tween 객체를 돌려주지만 슬롯에 비교할 대상이 없어 "같은 값에서 같은 값으로" 가는 의미 없는 엔진 트윈이 하나 만들어집니다(두 번째 재발행부터는 접힙니다). 또 하나: 프로퍼티를 None으로 껐다가 같은 캐시된 Tween으로 다시 켜면 슬롯에 남은 옛 정보와 같은 객체라 "이미 반영됨"으로 보고 아무것도 쓰지 않습니다 — 그 사이 프로퍼티가 밖에서 바뀌었으면 값이 단언되지 않습니다. | (a) 첫 스냅도 `{ Value, Source }`(엔진 트윈 없음)를 저장해 첫 재발행부터 접고, 재설치 경로에서는 값이 같은지 한 번 확인한 뒤 쓴다 — 3-상태 표(`tween-plan.md`)가 4-상태가 됨 / (b) 지금대로 두고 두 예외를 문서화 | **(a)** — 표 한 줄 바뀌는 정도. 정본 변경이라 사용자 결정 |
| **Q24** (`H-437`, 규약) | **회신 2차 승인의 범위를 갈라 적기.** 사용자가 승인한 것은 방향(*"공변성/불변성 문제를 해결하기 위한 작업"*)과 순수 팬텀(*"런타임 값에 없는 팬텀 괜찮아"*)이고, 메인이 정한 것은 **이름 둘**(`SlotItem<T>`, `FieldOut<T>` — 입력/출력 별칭 분리), `NewChild` 팔 모양(`StateMarker<(… \| None)?>` 하나, nil 포함), `LuauSolverConstraintLimit` 제거다. `base/` 배너 "[2026-09-07 마커 — 사용자 결정]"이 넷을 승인된 것처럼 읽히게 한다(규약: 새 이름·메커니즘은 문항, 인용 옆엔 갈라 적을 것) | (a) 넷 그대로 승인 / (b) 이름을 바꾼다(제안: `SlotElement`/`SlotItem` → `SlotInput`/`SlotOutput`, `FieldV`/`FieldOut` → `FieldIn`/`FieldOld` 등) / (c) 팔 모양·플래그만 승인, 이름은 보류 | **(a)** — 이름은 기존 `FieldV`·`SlotElement`와 짝이 맞고 8.11이 역할별 별칭을 규칙으로 적었다. 8.11 배너에 "승인 = 방향·팬텀, 제안 = 이름·팔 모양·플래그"를 갈라 적어 둠(이 커밋) **[2026-09-07 회신 4차] 닫힘 — (a) 넷 그대로**(*"괜찮네. 확인했어"*, §7). 후속 질문 *"FieldOut<T> 는 그럼 Peek 에도 사용되는걸까?"* → 지금은 아니었다(Tween 팔 없는 옛 유니언) → `Peek` 반환을 `FieldOut<T>?`로 통일, 별칭 정의를 quad-types로 |

| **Q27** (구조 재편 회신 반영, 낮음) | **프로바이더 브랜드의 진단 프로브 등록.** 상황: Tween이 quad-roblox로 옮겨가면서 `isTween`도 백엔드 것이 됐는데, quad-base `Dispatch/init.luau`의 `BRAND_PROBES`(무매치 진단이 값의 브랜드 이름을 붙이려고 훑는 술어 이름 목록)는 여전히 문자열 `"isTween"`을 적어 둡니다. 목록은 진단 시점에 모듈에서 이름으로 찾으므로 프로바이더가 설치한 술어도 보이긴 하지만, base가 백엔드의 이름을 알고 있는 마지막 흔적이고, 사용자가 예고한 quad-spring의 `SpringBrand` 같은 다른 프로바이더 브랜드는 목록에 없어 무매치 진단에 `value: table`로만 찍힙니다(M11 리뷰가 Tween에서 결함으로 잡았던 그 증상). 무엇이 막히나: base가 모르는 이름을 base 목록에 적을 수 없으니, 프로바이더가 자기 프로브를 *등록*하는 길이 있어야 하는데 그건 새 Dispatch 표면입니다. | (a) `Dispatch.addBrandProbe(name, predicate)` 같은 등록 op를 두고 quad-roblox가 `Tween` 설치 때 등록, base 목록에서 `"isTween"` 삭제 (b) 지금처럼 base 목록에 문자열만 두기(메커니즘 0, 확장성 없음 — 새 프로바이더 브랜드마다 base 수정) (c) 목록에서 빼고 `value: table`을 감수 | (a) — 다만 이름은 제안이고 순서 규칙(most-specific-first 목록의 앞에 붙일지)도 같이 정할 것. 지금 코드는 (b)에 `TODO(Q27)` |
| **Q33** (§10 탐사 B-1, 중간 — **닫힘 §11 (a)**) | **`None`으로는 오브젝트 참조 프로퍼티를 해제할 수 없다.** 상황: Property 핸들러는 `v == nil`이면 쓰기를 무조건 건너뜁니다(skip-defense). 그 근거는 정본의 "nil을 못 받는 타입(Color3/number)에 `inst[k] = nil`은 엔진 에러"인데, 생성 D의 쓰기 표면엔 nil이 정상 값이자 유일한 해제 수단인 오브젝트 참조 프로퍼티가 75개 있습니다(`Adornee`·`NextSelectionUp`류·`SelectionImageObject`·`CameraSubject` 등). 타입은 그 자리에 `None` 팔을 열어 두었는데 런타임은 그 `None`을 삼키므로, 닫힌 다이얼로그의 `BillboardGui.Adornee`가 죽은 파트를 영구히 가리키는 식으로 마지막 참조가 남습니다. 무엇이 막히나: 어느 프로퍼티가 nil을 받는지 런타임이 알아야 하는데, 지금 Reflection 심 디스크립터에서 그 정보(`ValueType.Category == "Class"`)를 읽는 자리가 없고, 엔진에서 Instance 타입 프로퍼티에 nil 대입이 합법인지(통상 그렇다)는 Studio 실측 대상입니다. | (a) Reflection이 클래스 참조 타입을 표시하고 그 프로퍼티에 한해 `None`을 `inst[k] = nil`로 쓴다 (b) 지금처럼 전부 skip(타입의 `None` 팔이 거짓 약속으로 남음) (c) 그 75개 슬롯에서 `None` 팔을 타입에서만 빼서 정직하게 | (a) — Studio 실측(디스크립터의 `ValueType` 노출 + nil 대입) 뒤 |
| **Q34** (§10 탐사 B-3, 중간 — **닫힘 §11 (a)**) | **생성 D가 모든 프로퍼티 타입에 `Tween` 팔을 붙인다.** 상황: 생성기의 `pv_arms`가 타입을 가리지 않고 `T | TweenData<T> | State<...> | None` 네 팔을 찍어 `Text`(string)·`Adornee`(Instance)·`ImageContent`(Content)·`FontFace`(Font)도 `Tween{...}`을 strict에서 받습니다. TweenService는 그 타입을 보간하지 못하므로 `TweenService:Create`가 `process` 한가운데서 던지고 `H-103` NOOP 마커가 그 키에 고착됩니다. 정본 "타입 대수" 절은 `T' = T | Tween<T>`를 일률로 서술하고 보간 가능성을 말하지 않습니다. 무엇이 막히나: 생성기에 "보간 가능한 DataType 집합"이라는 새 판정 표가 생기고, 그 집합의 정확한 경계(공식 문서는 number·boolean·CFrame·Rect·Color3·UDim·UDim2·Vector2·Vector2int16·Vector3)는 실측으로 확정해야 합니다. | (a) 생성기에 보간 가능 집합을 두고 그 타입에만 Tween 팔(정본 "타입 대수" 절에 각주) (b) 지금대로(런타임 에러 + NOOP 마커) | (a) — 집합은 공식 문서 열 개로 시작, Studio에서 하나씩 음성 확인 |
| **Q35** (§10 탐사 B-4, 낮음 — **닫힘 §11 (a)**) | **`OnChange("Parent", fn)`이 정적으로 거부된다.** 상황: Q19 (a)의 읽기 표면 `PropTypesRead`는 "쓰기 프로퍼티 + ReadOnly"인데, 생성기의 `Parent` 제외(`H-142` — 부모 관계는 quad가 소유한다는 *쓰기* 쪽 근거)가 읽기/쓰기 분기보다 앞에 있어 `Parent`가 두 목록 어디에도 없습니다. 런타임 OnChange 핸들러는 `GetPropertyChangedSignal("Parent")`를 문제없이 연결하므로 타입만 막는 상태입니다(`AncestryChanged` 이벤트 키가 대체 수단). 무엇이 막히나: Q19가 정의한 읽기 표면의 문자 그대로는 `Parent`를 포함하지 않으므로, 넣는 건 그 정의를 넓히는 결정입니다. | (a) 읽기 표면에 `Parent`를 넣는다(쓰기 표면은 그대로 제외) (b) 지금대로, `AncestryChanged`를 안내 | (a) — 생성기 한 줄 |
| **Q36** (§10 탐사 A-4, 낮음 — 옛 문항의 재부상 — **닫힘 §11 보관 — 사용자 재량**) | **`:List`의 KeyGone에서 non-nil `ud`를 돌려주면 `userdata[key]`가 영구히 남는다.** 상황: 소멸 루프는 `updateFn(KeyGone, ...)`의 반환을 `userdata[key]`에 그대로 저장한 뒤 `prevKeys[key]`만 지우므로, 그 키는 다시 물어볼 기회가 없는데 엔트리는 남습니다. `archive/v2-initial-implementation/pre-implementation-qa-round4-followup.md`의 열린 문항 2번("`userdata` 엔트리는 언제 지워지나")이 답 없이 남은 자리이고, 코드는 "누출"로 답한 상태입니다. 무엇이 막히나: KeyGone 반환값의 계약(버리는가, 보관하는가)이 정본에 없습니다. | (a) KeyGone 반환 `ud`는 버리고 엔트리를 항상 지운다(정본에 한 줄) (b) 보관을 계약으로 명문화(재등장 키가 옛 ud를 받음) | (a) |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0, quad-roblox 타입 검사 2.95s.

## §5 외부 리뷰 round4 검증 — Gemini 4차 (`post-implementation-review-round4.md`, 사용자 반입 2026-09-07)

round2와 같은 절차(실재현 뒤 판정). 다섯 전부 실존 — `H-417`/`H-421` 계열(빈 문자열)과 `H-418`/`H-419` 계열(nil·비테이블
인자가 내부 VM 에러로 죽어 quad 줄을 blame)의 남은 구멍이었다.

| ID | 출처 | 자리 | 무엇 | 처리 |
|---|---|---|---|---|
| **`H-440`** | G-10 (HIGH) | `Handlers/OnChange.luau` 생성자 | `OnChange("", fn)`이 통과해 `GetPropertyChangedSignal("")` 엔진 예외가 디스패치 깊이에서(부기 등록 뒤) | `name == ""` 거부(nearest). `spec.events` 7절 |
| **`H-441`** | G-11 (MED) | `Slot/List.luau` `List`/`reconcile` | `updateFn` 타입 무검사, `items`가 nil/비테이블이면 `#items` VM 에러가 `Slot/List.luau:950`을 blame | `List` 머리에 둘 다 게이트(nearest) + `reconcile` 머리(State 값 경로, outermost). `spec.slot` 24절 |
| **`H-442`** | G-12 (LOW) | `Dispatch/init.luau` `drive` | `drive(nil, props)`가 Relate `table index is nil` | `inst == nil` 게이트(`H-419` 옆). `spec.dispatch` 17절 |
| **`H-443`** | G-13 (HIGH) | `Store.luau` `checkKey`·`Attr/init.luau` `isStore` 분기 | `Store({ [""] = … })`/`Of("")` 통과 → `Attr(store)`가 `setAttr("")`에 디스패치 깊이로 | 두 자리 모두 `""` 거부(`H-421` 자매). `spec.store` 9절(기존 단언 문구 둘 정정) |
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
| **Q9** | (b) — *"해당 좀비는 진짜 죽은게 맞음 … Instance 와 같은 동형으로 두어도 되는 부분. 메시지를 잘 정리하고 UB부분을 문서화만 하면"* | `Slot/init.luau` "already mounted" 셋·`dispose` 메시지에 "quad 밖에서 파괴됐으면 함께 죽은 것 — 미리 뽑아라" 문구; `slot-plan.md` "부수 효과" 문단 철회 + UB. `spec.slot` 24절 |
| **Q10** | (c) — *"오용 표면을 막을 이유를 모르겠음. UB로 두어도 되는 부분"* | `module-lifecycle-plan.md`·`RobloxFactory.luau` 헤더 UB 문장 |
| **Q11** | (a)+(c) — *"런타임 에러 추가가 무료급이고 … 문서도 같이"* | `Dispatch/Modifier/init.luau` `__index`에 문자열 키 게이트(+ `__index` SURFACE 태그 — 메타메소드 자체가 raise); `modifier-plan.md`; `spec.modifier` 14절 |
| **Q12** | 사용자 설계 — *"Animate 자체가 이전 Tween 값 비교와 이전 Tween 을 그대로 리턴하여 dedup … Dedup: boolean 형태 하나"* | `Animate.luau` `sameTween` + `Dedup` 옵션(기본 true), `Property.luau` 슬롯에 `Source = v`(필드 이름 `Source`는 메인이 붙인 것 — 사용자 사후 확인) + 같은 객체 재발행 skip, `types.luau` `AnimateInfo.Dedup`; `tween-plan.md`; `spec.tweenproperty` 7절(Dedup=false 재트리거 포함) |
| **Q13** | (b) | `Bookkeeping.luau` `setOffsetSource` 게이트(Source \| None, nearest); `spec.lengthoffset` 12절 |
| **Q14** | (a) — *"동의. a로 가도 돼"* | `destroySlotTree` 두 루프 `releaseOwner`; `slot-plan.md` C-4 면제 철회; `spec.slot` 24절 |
| **Q15** | (a) | `setLength` 상수 도메인(비음수 정수, 등록 시) + State 값은 ~~`contribution`에서~~ → **§8 `H-445`로 Observer 콜백 안**(차단기 창 밖, nearest); `dispatch-core-plan.md` 계약 줄; `spec.lengthoffset` 12절 |
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

## §8 회신 3차 묶음 리뷰 — `/code-review high` `bbab11f..6f090b0` (파인더 8·검증자 3 opus, 미완 0)

리뷰가 평문으로 보고했다(사용자 지적 반영). 확인만 한 것: Q14 `releaseOwner`의 owner == slot 불변식(sugar wrapper·detached 경로), Q13 게이트의 유일한 호출부(`slot.Offset`), Modifier `__index` 게이트와 내부 경로, Gemini 게이트 다섯의 blame·spec, gen-d `PropTypes` 바이트 동일·`PropTypesRead`에 `any` 승격 0. 열 건 중 둘은 문항(Q25·Q26), 여덟은 반영.

| ID | 자리 | 무엇(평문) | 처리 |
|---|---|---|---|
| **`H-445`** (높음) | `Bookkeeping.luau` `contribution` | Q15의 State 값 검사를 recompute **안**(차단기가 켜진 창)에서 던지게 넣어서, 사용자가 pcall로 잡으면 차단기가 영원히 켜진 채 남아 그 owner의 길이·오프셋 갱신이 조용히 멈춘다 — 고치려던 바로 그 결과가 메시지만 좋아진 채 남았다 | 검사를 길이 State의 **Observer 안**(recompute 진입 전)으로 옮김 — nearest가 사용자의 `:Set` 줄, 차단기 창 밖. `contribution`은 읽기만. `spec.lengthoffset` 12절이 거부 뒤에도 오프셋이 흐르는지 단언 |
| — (높음) | `InstanceShorthand.luau` `Mapped` | 숏핸드 키에서 Q12 dedup 불성립 | **§4 Q25** |
| — (중간) | `Property.luau` 3-상태 | 첫 스냅 뒤 첫 재발행·재설치 경로 | **§4 Q26** |
| **`H-446`** (중간-낮음) | `Slot/List.luau` `List`/`Single` | `H-441` 게이트가 세 군데 샌다 — `Single`의 `updateFn`은 래퍼로 감싸져 통과, `keyFn`은 무검사, "배열" 게이트가 `type == "table"`뿐이라 None/Store/Tween 같은 브랜드 테이블이 빈 리스트로 통과 | `Single` 머리 게이트, `keyFn` 게이트, 데이터는 메타테이블 없는 테이블만(`reconcile`도). `spec.slot` 24절 |
| **`H-447`** (낮음-중간) | `LifetimeHandle.luau`(roblox·mock) | `H-444`가 nil 문 넷 중 셋만 막았다 — `bindLifetime(inst, nil)`은 `gchold[nil]`에서 VM 에러; nil inst는 "Claim it first" 안내로 흘렀다 | 둘 다 전용 메시지. `spec.lifetime` 10절 |
| **`H-448`** (낮음-중간) | `Dispatch/Modifier/init.luau` `construct` | Q11 주석 "생성자의 거울"이 반쪽 — 생성자는 `As`+대문자 키(헤더가 에러난다고 약속한 오타 `AsTextLabl`)·예약 메소드명·빈 문자열을 필드로 받아들였다 | 셋 거부(setter 경로가 만들 수 없는 키). `spec.modifier` 14절 |
| **`H-449`** (낮음) | `InstanceShorthand.luau` | Q17 주석("최종 대입이 raise")이 `UIPaddingOffset`엔 거짓 — 관리 자식을 만든 **뒤** `UDim.new`가 quad 프레임에서 raise; 헤더의 "Validation raises" 문장 stale | 변환을 자식 생성 앞으로(부수효과 없이 raise), 주석·헤더 정정 |
| **`H-450`** (문서) | `slot-plan.md` C-4 문단·`modifier-plan.md` 271행 | 철회된 면제가 여전히 볼드 첫 문장이고 옛 근거 인용이 현재형; Q11 문장 삽입으로 앞 문장의 주어가 끊김 | 문단 재구성(철회가 머리, 옛 근거는 "철회된 근거"로), 문장 복원 |
| **`H-451`** (낮음) | `Slot/Elements.luau` 메시지·사본 | Q9 안내문이 상수 셋 + 손 변형 하나로 이미 갈라졌고 그 변형만 "(Q9)" 내부 태그를 노출; 상수가 "a Slot cannot be reused"라 Instance 이중 마운트에도 붙음; "releaseOwner + isSlot ? destroy : dispose" 사본 넷 | 값 중립 문구 하나(`ZOMBIE_NOTE`)를 네 자리 전부에, `destroyElement` 한 본문 |
| **`H-452`** (낮음, 검사 공백) | `spec.state` 12절 | Q7 셋째의 outermost 전환에 그 이유가 된 경로(`H-416`) spec이 없고 기존 주석이 반대 사실 | `spec.dispatch` 18절(Store 키에 Modifier를 돌려주는 Compute를 drive) + 주석 정정 |
| — (정리) | `Bookkeeping` 술어 두 벌 / gen-d 루프 사본·이중 부정 / README research 표 구분행 | 리뷰 "순위 밖" | 술어 하나로(`H-445`와 함께), `emit_prop_map`·`other_excluded`, 표 복구. `<Class>OnChange` 유니언 70멤버(8.7 한계 근접)는 관측만 |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0.
다음 순회는 이 파일 §9부터, `H-453`부터.

## §9 이동 뒤 순회 — 구조 재편 다섯 커밋 `e9c7ffd..4ddb9c5`의 `/code-review high`(파인더 8·검증자 4 opus, 미완 1 — 줄 단위 파인더 A, 영역은 B·C가 덮음) + 감사자 3라운드

세 갈래 판정. 반영 ①은 이 절과 같은 커밋.

| 번호 | 갈래 | 내용 |
|---|---|---|
| **`H-453`** | ① | `doc-check.py`의 새 `.luau` 검사가 폴백에 뚫렸다. 상황: 접미 일치가 실패하면 옛 이름 폴백이 `.claude/` 전체(`initreq/` 클론 포함)를 이름으로 뒤져, 지워진 `quad-base/src/Tween.luau`가 Fusion의 `Tween.luau`로, 없는 `Dispatch/Ref/init.luau`가 charm 테스트의 `init.luau`로 통과했다(라이브 문서 927건 중 58건이 이 폴백으로만 통과, 이 범위가 만든 stale 둘 포함). 반영: 패키지 루트부터 적은 경로는 폴백 없이 판정, 패키지 목록은 `pesde.toml` `workspace_members`에서 읽음(`_SRC_ROOTS` 되풀이 제거), `luau_packages/` 최상위 shim은 실존으로 색인. 이름만 적은 인용이 같은 이름의 다른 파일(`Ref.luau` → `Dispatch/Ref.luau`)에 걸리는 것은 접미 일치의 본질이라 남긴다(이름 인용은 WARN 층). |
| **`H-454`** | ① | `architecture.md` 트리의 옛 이름 문구·중첩 노드 이름이 기계 치환에 덮인 것 — 감사자 1라운드가 같은 것을 먼저 잡아 수정됐고, 리뷰가 추가로 잡은 5절 문단의 동어반복(`Slot/Handler.luau`가 … `Slot/Handler.luau`로)과 "`Dispatch/init`은 값 모듈을 절대 require하지 않는다"의 어구(`@self/Modifier`를 require하므로 문자 그대로는 거짓 — 값 모듈의 정의를 "자기 핸들러를 등록하는 Tag/Attr/Ref/Slot/Observer/Effect"로 명시, Modifier는 drive 단계라 예외임을 같은 문장에)를 반영. |
| **`H-455`** | ① | `tween-plan.md` "`Animate` 콤비네이터" 절 아래 문단이 배너 없이 "`Tween<T>` 값 타입만 base(옛 `quad-base/Tween.luau`…)"라 적혀 있었다 — 배너만 달고 본문을 안 고친 실패 모드(`H-453`의 폴백 구멍이 그 인용을 통과시켜 ERROR 0이었다). 취소선+정정. 코드 헤더의 옛 경로 인용 열 곳(`LifetimeHandle`·`NotInstalled`·`Brand`·`Dispatch/None`·`Dispatch/init`·`Dispatch/Modifier/init`의 Peek 유니언·quad-types의 `FieldOut` 귀속·spec 넷)도 같이 — doc-check는 `.luau` 헤더를 안 보므로 grep 전수. |
| **`H-456`** | ① | `Slot/init.luau`의 내부 표 `S`가 모놀리스의 로컬을 통째로 복사해 과잉 공개됐다 — 다른 파일이 읽지 않는 이름 열둘(`reindexFrom`·`spliceArrays*`·`vacate`·`identityUpdateFn`·`materializeSlotTree` 등)과 프렐류드 키 둘(`Dispatch`·`Brand`). `S`는 `any`라 죽은 공개도 오타 읽기도 분석이 못 잡고 nil 호출로만 드러난다. 반영: 다른 파일이 읽는 이름만 공개, 설치 뒤에 공개되는 둘(`S.assertLive`·`S.Slot`)은 파일 머리에서 캡처하지 말라고 헤더에 명시, `Slot/Handler.luau`의 로컬 `S`(다섯 키 `_slotInternal`)를 `internal`로 개명(같은 폴더의 `S`와 이름 충돌). `_slotInternal` 자체는 핸들러의 공개 계약이라 유지. 타입 있는 내부 표 모양은 새 메커니즘 — **Q29**. |
| **`H-457`** | ② | `Tag.luau` `flattenInto`의 재귀에 순환 가드가 없어 자기 참조 리스트(`t[1] = t`)가 VM 스택 오버플로로 죽고 blame이 `Brand.luau:95`(내부)다 — `Tag(t)`·`Added(t)`·`Removed(t)` 셋, `Merged`는 `isTag` 게이트가 먼저라 안전. 3절 (b) 전엔 문자열만 받아 도달 불가였다. 깊이 500~10000의 정직한 중첩은 전부 생성된다 — 순환(또는 10만 깊이)만 터진다. 처방(방문 집합·깊이 상한·UB 선언)이 새 메커니즘 또는 정본 결정이라 **Q28**. 코드는 그대로. |
| **`H-458`** | ① | 정밀해진 엔진 타입 필드의 음성이 어디에도 없었다 — `spec.tween.luau` 3절의 잘못된 엔진 값은 `:: any`로 캐스트돼 아무것도 단언하지 않고, `spec.tweentypes.luau`의 양성 `local info: TweenInfo? = t.Info`는 `any`여도 통과한다. 스펙 그룹은 분석이 클린해야 해 음성을 둘 수 없으므로 스파이크 `luau-test/done/36`(defs 필수, 음성 셋 실측)으로. 같은 김에 STATUS.md에 빠져 있던 34·35 행도 추가. |
| **`H-459`** | ① | quad-types `FieldOut<T> = T \| State<T> \| None`으로 일반화하면서 프로바이더 아래의 base `Modifier()` `Peek<<UDim2>>`엔 Tween 팔이 없어졌다(생성 `<Class>Modifier`의 `Peek`는 D의 `FieldOut`이라 그대로). 정의상 결함이 아니라(T는 값 대수 전부 — `Peek<<UDim2 \| Tween<UDim2>>>`가 옛 타입과 같음, 실측) 캐비엇: quad-types `FieldOut` 주석과 `modifier-plan.md` `Peek` 절에 그 관용구를 적음. |
| **`H-460`** | ① | `doc-check.py`가 못 찾은 참조마다 `.claude/` 전체(2110파일)를 다시 걸었다 — 한 실행에 2529번, 게이트 시간의 40%. 이름→경로 색인을 한 번만 만든다. 실측 2.94s → 0.39s. |
| **`H-461`** | ① | `Tag.Merged`가 `flattenInto`의 Tag 팔과 같은 합집합을 `:Names()` 이터레이터로 두 번째 철자하고 있었다(한쪽은 사적 `_names`, 한쪽은 공개 이터레이터 — 표현이 바뀌면 한 문만 조용히 깨진다). `Merged`는 `isTag` 게이트 뒤 `flattenInto`를 부른다. 같은 파일 `addName` 주석 갱신. `Slot/Tree.luau`의 일곱 이름 전방 선언은 분할 뒤 아무것도 앞서 참조하지 않아(모두 정의 뒤 사용) `local function`으로 — `H-404` 규칙 주석은 남김. |
| **`H-462`** | ① | `external-review-entry.md`의 인라인 카운터(`G-14`·`S-10`)와 패키지 목록 사본 — 감사자 2라운드와 겹쳐 먼저 수정됨(포인터만). |

**Q28**(`H-457`) — **자기 참조 이름 리스트의 처분.** 상황: Tag의 이름 자리가 리스트를 재귀로 펼치므로 리스트가 자기 자신을 품으면(`t[1] = t`) 스택이 넘칠 때까지 내려가 VM 에러가 나고, 그 에러는 사용자 줄이 아니라 quad 내부(`Brand.luau`)를 가리킵니다. 무엇이 막히나: 이건 실수로 만들기 어려운 모양(정직한 중첩은 1만 깊이까지 멀쩡)이라 "관측된 문제에만 구조" 원칙상 가드를 넣을 근거가 약하지만, `H-441`/`H-446`처럼 "VM 에러가 내부를 blame하는" 부류를 형제 도어들이 전부 표면 에러로 바꿔 온 흐름과는 어긋납니다. 갈래: (a) `base/tag-plan.md`에 UB로 선언하고 코드는 그대로 (b) 방문 집합 하나로 순환을 잡아 표면 에러(할당 하나가 `flattenInto` 호출마다 늘어난다 — 리스트 인자일 때만 만들면 문자열 경로는 무비용) (c) 깊이 상한(예: 64) — 순환과 비정상 깊이를 한 번에, 정직한 깊은 중첩은 거부. 권고 (a) — 실사용에서 이름 리스트는 손으로 적거나 `table.move`로 합친 평평한 배열이고 순환은 만들 이유가 없다; 원칙대로 관측되면 (b).

**Q29**(`H-456`) — **Slot 내부 표 `S`의 타입.** 상황: `Slot/` 여섯 파일이 서로를 `S.fn(...)`으로 늦게 부르는데 `S`가 `any`라 죽은 공개·오타 읽기·설치 전 캡처를 분석기가 못 잡고 실행 때 nil 호출로만 드러납니다(이번에 죽은 공개 열넷을 손으로 걷어냈습니다). 무엇이 막히나: 고치려면 `S`의 모양을 타입으로 적어야 하는데(`Slot/init.luau`에 `SlotInternal` 같은 export type — 함수 마흔 개의 시그니처 나열, 또는 각 파일이 자기 몫만 `& { … }`로 더하는 교집합), 그건 새 이름·구조입니다. 갈래: (a) 지금처럼 `any` + 헤더 규칙(설치 뒤 공개 둘은 파일 머리에서 캡처 금지) + 스펙 커버(`spec.slot`이 raw*/List 경로 대부분을 지난다) (b) `S`의 타입을 한 곳에 적는다(비용: 시그니처 나열, 이후 함수 추가마다 두 곳) (c) 파일별 교집합 조립(8.6/8.12의 교집합 함정을 재야 함). 권고 (a) — 관측된 문제가 아니고, 오타는 `spec.slot`(가장 큰 스펙)이 잡는다.

**회신(2026-09-07 밤, 대화형)**: **Q28 (a)** — *"스택 오버는 다른 곳에서도 방어 안 했음. 정직히 UB 로 두고 안 고쳐도 되는
부분"* → `tag-plan.md` "값 모양" 배너에 UB 문장, 코드 그대로. **Q29 — (b)의 사용자 판**: 처음 생각은 `S`를 풀어내는 게
아니라 *"모든 곳에서 그냥 S. ... 해서 타입을 구현하는것"*이었고, *"내부 구현 타입에 관한 부분이라서 Slot 안에 types 를
넣거나 해서 각자 참조해 쓰는걸 원했음 — 내부 구현은 quad-base 에 두고, 외부로 나가는 구현만 types 에 있는거 끌어다
쓰는게 내 생각"*. 반영: `Slot/types.luau`의 `SlotInternal`(프렐류드 값 + 공개 함수 시그니처 전부), `S :: SlotInternal`,
형제는 파일 머리 재캡처 없이 `S.x`를 직접 읽는다(`function S.Slot_mt.List(...)` 포함). 같은 회신의 지적 — *"S.bindLifetime 도
왜? … 다른곳과 똑같이 module.bindLifetime 을 계속 읽어도 좋음. 정적 해시가 된 필드 읽기는 luau 에서 충분히 빠른 부분이라
미리 local 로 빼두는게 이득이 없음"* — 조사: 그 래퍼 셋은 M6 fork가 `Slot.luau`에 남긴 스타일이고(코퍼스에 그것뿐, 성능
이유 없음) 다른 모듈은 전부 인라인 `module.x(...)`(스무 곳); 래퍼를 지우고 인라인으로, 규칙은 `architecture.md` 코드
스타일 절에 명문화.

**검증**: `./scripts/test.sh` exit 0(스펙 49), doc-check ERROR 0(0.39s), 스파이크 36 실측; Q28/Q29 반영 뒤 다시 exit 0.


## §10 탐사 순회 — opus 탐사자 둘(A: quad-base 코어 / B: quad-roblox·타입·생성기, 각 단일 맥락·읽기 전용) + Gemini 5차(`post-implementation-review-round5.md`) 메인 판정 (2026-09-07 밤)

사용자 지시(*"작은 모델로 여러패스를 굴려 자잘한 버그를 실측하는게 맞아보이는데 … 실측은 메인인 너가"*). 탐사자 발견 14건(B 9·A 5)과 Gemini 7건(`G-15`~`G-21`)을 메인이 전부 스크래치 프로브로 실측한 뒤 세 갈래로 판정했다. 반영 ①은 이 절과 같은 커밋(test.sh exit 0, 스펙 49).

**전제 정정 하나.** Gemini 5차의 `G-15`/`G-18`/`G-19`/`G-20`/`G-21`은 전부 "nil 키로 테이블을 *읽으면* `table index is nil` VM 에러"를 전제했는데, Luau는 읽기(`t[nil]`)는 nil을 돌려주고 *쓰기*(`t[nil] = v`)만 에러다(스크래치 실측). 그래서 다섯 중 셋은 이미 표면 에러였고(`mod[nil]` → "setter keys must be strings (got nil)", `dispose(nil)` → "cannot dispose this value", `setEmpty(nil, 1)` → `H-447`의 "bindLifetime: inst must not be nil"), 둘은 크래시가 아니라 **조용한 nil/false 반환**이었다(`slot:Get(nil)`·`tag:Contains(nil)`·`mod:Peek(nil)`). 다만 사용자 회신 Q32(*"nil 허용 불가 … 처음부터 요소나 인자가 nil로 들어가 조용히 성공하는 케이스가 발생하는 것은 방지되어야 한다"*)는 그 조용한 반환에 더 정확히 맞으므로 가드는 넣었다. 외부 리뷰 진입점 §6에 "Luau 언어 사실은 실측 뒤에" 규칙을 추가했다.

| 번호 | 갈래 | 내용 |
|---|---|---|
| **`H-463`** | ① | (탐사 B-2) `Tween{ Value = None }`과 중첩 `Tween{ Value = Tween{...} }`이 생성자를 통과했다. Q16 (b)의 게이트가 State 한 팔에만 붙어 있었는데 정본 불변식("모든 필드는 plain 값")은 None과 Tween에도 똑같이 적용된다 — 둘 다 `Property.process`의 Tween 분기를 타고 테이블째 엔진에 닿았다(실측: 둘 다 `pcall` true). 반영: `validate`에 두 팔 추가, 메시지는 "emit None itself to release the property". `spec.tween` 6절. |
| **`H-464`** | ① | (탐사 B-6) `Animate({ Time = "x" })`의 검증 raise가 `Animate.luau:104`를 blame했다(실측). 옵션 검증이 `Animate(info)` 시점이 아니라 첫 `:Get()`의 Compute 안에서 `Tween(opts)`가 대신 하므로 사용자 줄이 스택에 없다 — `spec.animate` 4절이 이 한 케이스만 blame 단언을 비워 둔 것이 방증. 반영: `Tween.luau`의 검증을 `validateFields`(Value 제외)와 `validate`로 나누고 `install`이 전자를 돌려주며, `RobloxFactory`가 `installAnimate(module, tween.validateFields)`로 넘겨 `Animate(info)`가 **리터럴(비-State) 옵션만** 즉시 검증한다(State 옵션은 실행마다 `Tween(opts)`가 검증 — 스펙에 그 케이스도). 내부 배선이지 표면이 아니다. |
| **`H-465`** | ① | (탐사 B-7) `EngineOps.addTag`/`removeTag`가 호출마다 `game:GetService("CollectionService")`를 불렀다 — 같은 심 요구를 가진 `Property.luau`의 `getTweenService`는 호출 시점 lazy + 메모이제이션. 같은 모양으로(`getCollectionService`). 스펙의 `getfenv` 심 시점(인스턴스 생성 전)은 그대로 유효. |
| **`H-466`** | ① | (탐사 B-5) 생성기가 **이벤트**를 조용히 떨어뜨렸다 — 파일 머리 계약("조용한 절단 금지")과 `H-428`의 프로퍼티 쪽 `dropped` 기록이 있는데 이벤트 분기의 두 `continue`(태그·Security)는 기록이 없어 `dropped` 466건에 이벤트 노트가 0건이었다(`GuiObject.DragBegin`/`DragStopped` Deprecated가 표면에서 빠진 이유가 덤프에 안 남음). 반영: 두 자리에 `dropped.append`(`(event)` 표시), normalize → emit → check(생성 D 바이트 동일, 노트 466 → 518). |
| **`H-467`** | ① | (Gemini `G-16`, 사용자 Q30 확정 *"의미론적으로 None == nil이 맞다"*) `Slot:Single`이 `g == nil`만 보고 `None`은 `{ None }` 배열로 방출해 `updateFn`이 `None`을 item으로 받고 KeyGone이 발화하지 않았다(코드 확정). 반영: State·plain 분기 둘 다 `None`을 빈 배열로. `spec.slot` 25절(KeyGone 1회, 재설치, plain None 설치). |
| **`H-468`** | ① | (Gemini `G-20`, 사용자 Q32) `slot:Get(nil)`은 nil, `tag:Contains(nil)`은 false를 **조용히** 돌려줬다(크래시 아님 — 위 전제 정정). 반영: `Get`은 비-number 인덱스에 표면 에러(범위 밖은 여전히 nil — `SlotItem<T>?`와 `spec.slot` "arrays still construct"가 그 계약), `Contains`는 사용자 지시대로 **가변인자**(`...string`, 전부 있으면 true, 0개는 true, nil/비문자열은 인자 번호를 붙인 에러). quad-types `Contains: (self, ...string)`, `tag-plan.md` API 표, `Tag.luau` 헤더. `spec.slot` 25절·`spec.tag` 새 절. |
| **`H-469`** | ① | (Gemini `G-21`, 사용자 Q32) `mod:Peek(nil)`이 "없는 필드"의 nil과 구분 없이 nil을 돌려줬다. 반영: nil/빈 문자열/비문자열 키에 표면 에러(setter 경로 `H-448`과 같은 도메인). `spec.modifier` 15절. |
| **`H-470`** | ① | (탐사 A-1) `Dispatch.drive`의 props 게이트가 `H-419`의 비테이블 팔뿐이라 **중괄호를 빠뜨린 quad 값**(`D.Frame(q.Source(1))`)이 통과해 그 값의 내부 필드가 props로 디스패치됐다 — 실측: Source는 "no handler matched key Revision"이라는 무관한 메시지, `AttrKey("x")`는 frozen `{ Name = "x" }`라 quad-roblox에선 **에러 없이 인스턴스 개명**(`H-377`이 Modifier에서 고친 실패 모드 원문 그대로). 형제 생성자 전부(`H-204`/`H-377`/`H-386`/`H-389`)가 막는 팔이고 정본은 "`flattened`는 항상 평범한 Luau 테이블"이라 못 박았다. 반영: 메타테이블 값과 plain-branded 값을 브랜드 이름을 붙여 거부(`brandNameOf` 헬퍼로 `noMatchMessage`와 공유), 부기·프로퍼티를 건드리기 전. `dispatch-core-plan.md` 그 절에 게이트 명문화. `spec.dispatch` 16절. |
| **`H-471`** | ① | (탐사 A-2) `Claim.resolve`가 `desc._fired = true`를 `nativeClaim` **앞**에 세워, 클레임이 던지면(이미 claim된 root — 실측) 재시도가 진짜 원인 대신 "descriptor was already used"를 냈다 — `H-425`가 한 줄 옆에서 세운 원칙("부기를 만지기 전에 검사")의 잔여. 반영: 성공 뒤로 한 줄 이동. `claim-plan.md` 1회용 절에 한 줄. `spec.lifetime` 9절. |
| **`H-472`** | ① | (탐사 A-3) `recompute`의 `sourceList[i] is nil` 메시지가 형제 `lengthList` 검사(`H-427`: "setOffsetSource without setLength?")와 달리 원인을 안 짚었다(`checkPosition` 헤더가 연속성 책임을 이 검사에 위임). 반영: 거울상 "(setLength without setOffsetSource?)" 추가. `spec.lengthoffset` 13절(절반만 등록하는 말단 핸들러). |
| **`H-473`** | ① | (Gemini 5차 §6 `G-22`, 후행 배치) `ref:Callback(nil)`/`WeakCallback(nil)`/`Uncallback(nil)`이 `Callbacks[nil]` 쓰기에서 VM 에러, `Callback(123)`이 호출 자리에서 "attempt to call a number value" — 둘 다 `Ref/init.luau` 줄을 blame(실측 재현). 반영: 세 문에 `checkCallback` 게이트 하나("callback must be a function (got …)"). `spec.ref` 16절. |
| **`H-474`** | ① | (Gemini 5차 §4 Q31·§6.4, 사용자 *"특별한 이유가 없다면 에러 … 처음부터 nil로 들어가 조용히 성공하는 케이스는 방지"*) `unbindLifetime(nil)`은 `H-444`가 "no-op if unbound" 헤더 계약을 근거로 조용한 no-op으로 만들었는데, nil은 "안 묶인 값"이 아니라 빠진 인자다 — `bindLifetime(nil, v)`(`H-447`)와 같은 문으로 표면 에러(roblox·mock). `dispose(nil)`은 이미 에러였지만 문구가 "cannot dispose this value"라 nil을 안 말했다 → "value must not be nil". `H-444`의 nil 팔은 이걸로 역전(`canExecute(nil)`/`canBound(nil)` 술어는 그대로). `spec.lifetime` 10절. |
| **Q33~Q36** | ② | 위 §4 표. 탐사 B-1(`None`으로 오브젝트 참조 프로퍼티 해제 불가)·B-3(모든 타입에 Tween 팔)·B-4(`OnChange("Parent")` 타입 거부)·A-4(KeyGone `ud` 잔존 — 옛 문항의 재부상). |
| 확인 | ③ | **탐사 B-8** 숏핸드 네 키의 `isHandlable`이 클래스를 안 본다(`D.New("ScreenGui")({ UICorner = 8 })`처럼 타입이 `any`인 경로에서 무의미한 자식) — 타입이 방어하는 오용이라 런타임 가드 없이 둠("드문 오용에 구조를 쓰지 않는다"). **탐사 B-9** Event 순수 철거 Disconnect 스펙 공백 — 오탐, `spec.events` 3절 112~113행에 이미 있다. **탐사 A-4b** `setEmpty`의 셋째 인자 `anchor`를 넘기는 호출부와 안 넘기는 호출부가 갈린다(동작 영향 0 — `setEmpty`는 길이 0 상수라 anchor가 안 쓰임). **Gemini `G-15`/`G-18`/`G-19`** 이미 표면 에러(위 전제 정정; `G-18`의 메시지가 `setEmpty`가 아니라 `bindLifetime`을 말하는 건 정확하진 않아도 사용자 줄 blame). **`G-17`** `ClassName`이 없는 테이블을 inst로 디스패치하면 Reflection 메모 쓰기에서 VM 에러 — inst는 Instance(-like)여야 한다는 디스패치 계약 밖의 오용(UB; Gemini §6.3이 재권고했지만 판정 유지 — `H-470`이 props 쪽을 막은 것과 달리 inst 쪽은 관측된 오용이 없다). **`G-18`** `getBlocker(nil)`은 `module._bookkeeping` 내부 표면이라 사용자 문이 아니고, 공개 문 `setEmpty(nil, …)`은 `H-447`이 이미 표면 에러(§6.3 재권고도 같은 이유로 유지). **`S-11`~`S-15`** 건전 확인 그대로. **탐사 A·B의 "깨끗했던 곳"**(rawMove 오프셋 산술·recompute 되감기·raw 3형제 splice·Tag/Attr 폴백 참조 카운트·Effect/Observer 생성자 순서·EpochMap·Modifier flatten / InstanceChild 순서·RobloxFactory 설치 순서·LifetimeHandle 위상·EngineOps 태깅 카운트·gen-d check 결정론)은 재트레이싱 불필요. |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0. 탐사자 미완: A는 `spec.*` 62개 전수 대조·GC 타이밍 미검토, B는 생성 D 31클래스 setter 전량 대조·`spec.robloxfactory` §7·§8 본문 미검토 — 다음 순회 후보. 다음 순회는 §11·`H-475`부터. 감사자 1패스(sonnet, diff 범위): 확실 4(slot-plan 정본 코드 블록의 `:Single` 잔존, dispatch-core "경로가 없다" 문장 충돌, **Q31 미반영**, **`G-22` 미배정** — 뒤 둘이 `H-473`·`H-474`)·의심 1(todos 볼드) → 전부 반영, 2라운드 대신 잔여 grep으로 닫음.

## §11 사용자 회신 5차 — Q33~Q36 + Q30~Q32 확인 (2026-09-08 새벽, 대화형)

사용자가 먼저 확인한 것: round5 §4의 회신 Q30~Q32는 *"내가 적은게 맞아 … gemini가 세션 중 나에게 질문해서 답해주었던 실 회신"* — 메인의 읽기가 맞았다. 이어 네 문항.

**Q33 (a) — nil 쓰기는 정상 경로다.** 사용자 실측: *"`print(typeof(workspace.Baseplate.Motor6D.Part0))` 해봐. nil 나옴. nil로 셋 되는건 정상적 경로임 — 무시되면 안되는 것으로, nil을 안 받으면 엔진이 에러를 내줘, 안 받는 값이라고."* 즉 Reflection으로 nillable을 가려낼 것도 없이 Property 핸들러의 skip-defense 자체를 걷어낸다 — nil을 못 받는 타입의 엔진 에러는 사용자가 봐야 할 오류. 반영: `Property.luau` `v == nil → Void` 제거(활성 트윈이 있으면 plain 경로대로 취소 뒤 nil 쓰기), 헤더·`Animate.luau` 주석, `dispatch-core-plan.md` 캐비엇 역전 배너(M10 결정·`H-352` 역전), `tween-plan.md` 두 곳, `spec.handlers` 9절·`spec.tweenproperty` 6절 재작성.

**Q34 (a) — 보간 못 하는 타입엔 Tween 팔을 붙이지 않는다.** 사용자: *"그러면 타입도 엄청 간단해지는게 많아서 타입 무게도 줄어들고, 처음부터 트윈 불가능한건 타입 상 안 되어 오류가 나야하는게 맞아서."* 반영: 생성기 `TWEENABLE`(공식 목록 열 개) + `tweenable(t)`(유니언은 전 멤버), `pv_arms`가 보간 불가 타입엔 `T | StateMarker<T> | None`, Modifier setter는 `FieldP<T>`(`FieldPV`/`FieldOutP` — `QuadTypes.FieldOut<T>` 재별칭, D 안 전개 아님이라 8.12 한도 무해), `tween-plan.md` "타입 대수" 절 머리. 생성 D 재생성(31 클래스, check 통과).

**Q35 (a) — `Parent`를 읽기 표면에 넣는다.** 사용자: *"예외적으로 직접 넣어줘도 될 것 같아. 없을 필요가 없는 부분이야."* 반영: 생성기의 `Parent` 제외를 쓰기 쪽으로 한정하고 `readProps`에 `Instance`로 추가(dropped 노트 문구도 그렇게), `onchange-plan.md` Q19 항목에 한 줄.

**Q36 — 열 이유 없음, 사용자 재량.** 사용자: *"유저가 원할 수도 있지. Slot이 진짜 죽기 전까지 뭔가 캐싱하고 싶을 수도 있고 … 그건 유저 구현 문제라 유저에게 알려주기만 하면 될 뿐 … userdata 자체가 매뉴얼한 제거를 원하는 데이터를 저장하지 않도록 요구하고 있고, 생성되는 객체에 바인드되도록 하는게 일반적 … 분리된 객체들은 지워지도록 Effect가 달려서 괜찮은 부분."* 반영: 코드 변경 없음, `slot-plan.md` `userdata` 절에 불릿(옛 round4-followup 열린 문항 2번도 이걸로 닫힘).

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check), doc-check ERROR 0. ⚠️ 절차 오류 하나: 회신 반영 커밋(`45ded71`)은 test.sh exit 1(`H-142` Parent 게이트가 Q35의 읽기 표면 `Parent`에 걸림 — 스펙은 49/49)인 채로 들어갔다 — 커밋을 exit 판정과 한 명령에 묶어 exit를 안 봤다(`H-405`와 같은 실패 모드). 후속 커밋에서 게이트를 쓰기 표면(`PropTypesRead` 블록 밖)으로 좁혔고 음성 프로브(쓰기 표면에 Parent 주입 → 게이트 발화) 확인. 다음 순회는 §12·`H-475`부터.
