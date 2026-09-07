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
| **Q22** (`H-432`, MED-HIGH) | **Slot 요소 자리의 공변 마커 + 가변 출력의 건전성.** `SlotElement<T>`의 `SlotMarker<T>` 팔은 공변이라 `outer: Slot<Instance>`에 `frames: Slot<Frame>`을 `Add`할 수 있는데, `outer:Get(1)`의 출력 `SlotItem<Instance>`는 그 값을 전체형 **`Slot<Instance>`**라 말한다 — 그 핸들로 `inner:Add(folder)`가 strict를 통과하고(런타임 요소 게이트는 `isInst`뿐, 클래스 검사 없음) 나중 `frames:ExtractAll()[1] :: Frame`이 거짓이 된다. State는 `Set`이 `Source`에만 있어 출력 전체형이 건전하지만 Slot은 `Add`가 `Slot<T>` 자신에 있어 **입력 공변 + 가변 출력**이 만나는 유일한 자리. 8.11의 `read` 논거·§16 음성 아홉이 이 도달 경로를 안 봤다(회신 2차의 승인 범위는 방향이지 이 결과가 아님) | (a) 유지 + typing-limits 캐비엇으로 명시(중첩 Slot의 출력 타입은 상한 `Slot<T>`이고 실제 요소 타입은 사용자가 지킨다 — 런타임은 원래 클래스를 안 가렸다) / (b) Slot 팔만 불변으로 되돌림(`SlotElement`의 Slot 팔을 전체형 `Slot<T>`로 — `Slot<Frame>`을 `Slot<Instance>`에 중첩하려면 캐스트) / (c) 출력 `SlotItem<T>`의 Slot 팔을 `SlotMarker<T>`(읽기 핸들 — 변형하려면 캐스트) | **(a)** — 런타임이 처음부터 요소 클래스를 안 가리므로 타입만 "상한"으로 정직하게 서술하면 되고, (b)는 중첩 관용구를 되돌리며 (c)는 출력을 못 쓰게 만든다. 단 새 사고 경로라 사용자 판단 |
| **Q23** (`H-432` 짝, MED) | **변환 함수 `old`의 타입 `FieldOut<T>` 모양.** 지금 `T \| Tween<T> \| State<T> \| State<Tween<T>> \| None`인데 입력 `FieldV`가 마커로 받는 정직한 `State<T \| Tween<T>>`·유니언 T의 멤버 State(`Field<number \| UDim>`에 `State<number>`)를 서술하지 못하고, State 팔이 둘이라 `old:Get()`이 유니언 호출로 거부돼 "old:Get()을 부를 수 있게"라는 자기 목적을 못 이룬다(`Modifier.luau`는 나중 변환을 `old:Compute`로 태워 `old`가 저장된 핸들 그대로) | (a) `FieldOut<T> = T \| Tween<T> \| State<T \| Tween<T>> \| None`(State 팔 하나 — 출력이라 상한으로 정직, `(old :: State<T \| Tween<T>>):Get()`이 `T \| Tween<T>`) / (b) `old: FieldV<T>?`(마커 — 메소드는 캐스트) / (c) 그대로 | **(a)** — 출력 자리의 State는 "저장된 것의 상한"이면 되고 `Set`이 없어 건전. 새 타입 모양이라 문항 |
| **Q24** (`H-437`, 규약) | **회신 2차 승인의 범위를 갈라 적기.** 사용자가 승인한 것은 방향(*"공변성/불변성 문제를 해결하기 위한 작업"*)과 순수 팬텀(*"런타임 값에 없는 팬텀 괜찮아"*)이고, 메인이 정한 것은 **이름 둘**(`SlotItem<T>`, `FieldOut<T>` — 입력/출력 별칭 분리), `NewChild` 팔 모양(`StateMarker<(… \| None)?>` 하나, nil 포함), `LuauSolverConstraintLimit` 제거다. `base/` 배너 "[2026-09-07 마커 — 사용자 결정]"이 넷을 승인된 것처럼 읽히게 한다(규약: 새 이름·메커니즘은 문항, 인용 옆엔 갈라 적을 것) | (a) 넷 그대로 승인 / (b) 이름을 바꾼다(제안: `SlotElement`/`SlotItem` → `SlotInput`/`SlotOutput`, `FieldV`/`FieldOut` → `FieldIn`/`FieldOld` 등) / (c) 팔 모양·플래그만 승인, 이름은 보류 | **(a)** — 이름은 기존 `FieldV`·`SlotElement`와 짝이 맞고 8.11이 역할별 별칭을 규칙으로 적었다. 8.11 배너에 "승인 = 방향·팬텀, 제안 = 이름·팔 모양·플래그"를 갈라 적어 둠(이 커밋) |

**검증**: `./scripts/test.sh` exit 0(스펙 49, gen-d check 통과), doc-check ERROR 0, quad-roblox 타입 검사 2.95s.
다음 순회는 이 파일 §5부터, `H-440`부터.
