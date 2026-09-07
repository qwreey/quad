# M10 잔여(InstanceShorthand) 자율 구현 규약 — 20라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-06 신설]** M10의 유일한 잔여 항목
> `quad-roblox/src/Handlers/InstanceShorthand.luau`(UI 편의 숏핸드
> `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale`) 구현 구간의 규약이자
> 착수 문항지. M11의 `m11-implementation-round19-brief.md`와 같은 지위. 산출물
> (발견 문서)은 `m10-shorthand-implementation-round20.md`. 사용자 결정
> (2026-09-06)으로 순서는 **M11 → InstanceShorthand → M9**이고 §0은 권고
> (a)로 착수·새 표면 문항만 멈춘다(원문 `session/2026-09-06-01-*.md` 2절).
>
> **명명**: `mN-implementation-roundNN` 규약 — M10 잔여의 라운드가 **round20**
> (M10의 첫 라운드 round16과 구분해 파일명에 `shorthand`를 넣는다), 발견 번호는
> 메인 직렬 라인이 round19에서 `H-334`까지 썼으므로 **`H-335`부터**.
>
> **전제(이미 충족)**:
> - 정본 `base/ui-shorthand-plan.md`엔 열린 질문이 사실상 없다 — 이름
>   (`UI` 접두어, `H-138`), 메커니즘(특수 키 핸들러가 관리 자식을 찾거나 만들고
>   **자식 프로퍼티 세팅은 `Dispatch.process(child, prop, v, 1)`로 위임**),
>   우선순위(`PropertyHandler`보다 높다 — `H-138`), 관리 자식 매칭(quad가 만든
>   고정 이름만, 조회는 `Relate` — `FindFirstChild` 금지), 자식 생성 경로
>   (일반 인스턴스 생성과 같은 gcconn/gchold 셋업 — `UI-5`), `v == nil`이면
>   `process`가 자식 파괴(반환은 `Void`, `H-135`), 파괴 전 `retractFrom(child,
>   prop, 1)` **의무**(`H-218`), Tween은 `:Mapped`로 `.Value`에만 변환(`UI-8`),
>   패키지는 quad-roblox 코어. "남은 열린 질문"은 파일 하나로 합칠지뿐(사소 —
>   §0 Q2).
> - **M11이 끝나 있다**(2026-09-06) — `Tween<T>:Mapped`·PropertyHandler의 3-상태
>   슬롯·`isTween`이 실물이라 "Tween 지원" 절의 위임 경로가 그대로 성립한다.
>   ROADMAP M10 배너가 *"M11(Tween) 이후에 하면 (c)~(d)를 바로 검증 가능"*이라
>   적어 둔 그 시점.
> - D의 인스턴스 생성 경로는 `Instance.new(className)` → `quad.nativeClaim(inst)`
>   → `Dispatch.drive(inst, props)`(생성 `D/init.luau`의 `New`) — 관리 자식도
>   `quad.D.New(className)({ Name = … })`로 만들면 `UI-5`가 자동 충족된다.
> - v1 의미(`.claude/initreq/quad/src/class.lua` 47~104행 — 읽기 전용 확인):
>   `Corner = n` → `CornerRadius = UDim.new(0, n)`; `PaddingAll = UDim` → 네
>   Padding 전부 그 UDim; `PaddingAllOffset = n` → 네 Padding = `UDim.new(0, n)`;
>   `Scale = n` → `Scale = n`. 관리 자식 이름 `_quad_round`/`_quad_padding`/
>   `_quad_scale`.
> - **범위 밖**: `RoundSize`(드롭 확정 — `archive/ui-shorthand-roundsize-dropped.md`),
>   `UIListLayout`류 전용 숏핸드(v1에도 없음), `initValue`류.
>
> §2~§5는 M11 규약(= M8 = M7 = M5 = M4 = M3 준용본)을 준용하고, 다른 자리에만
> `[round20 변경]` 표시.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 | (a) M11 골격 그대로(세 갈래 / 커밋 게이트 두 층 / 단위 끝 절차 = 감사 루프 → `/code-review medium` 1회 → 탐사자(작으면 생략·기록) → doc-check ERROR 0 → 커밋 / Studio 실측은 엔진 대면 델타가 있는 단위에만) / (b) 다른 | **(a)** | 검증된 골격. 이 구간은 작다(핸들러 하나 + 생성기 키 넷) |
| **Q2** | 파일 구성·단위 절단 | (a) **정본의 "단순화 후보" 채택 — 룩업 테이블 하나로 구동되는 단일 `Handlers/InstanceShorthand.luau`**(`{ key → { class, childName, props, wrap } }` 넷) + **두 단위**: ① 핸들러 + CLI spec(mock — `D.New`·Relate·위임·nil 파괴·`retractFrom`·Tween `Mapped`·재사용) → ② 생성기(`<Class>Param`·`<Class>Modifier` setter에 숏핸드 키 넷 — GuiObject 계열에만, `PropTypes`/OnChange엔 넣지 않음) + strict spec + **Studio**(Q6) / (b) 키마다 핸들러 파일 셋 / (c) 한 단위 | **(a)** | 세 핸들러의 본문이 글자 그대로 같고(정본이 이미 지적) 다른 건 표 한 줄뿐 — "하나가 두 일"이 아니라 "한 일을 데이터로 네 번". ②는 타입 표면이라 M7 ③·M8 ③ 선례대로 분리 |
| **Q3** | **값 모양(타입) 확정** — 정본은 "리터럴 하나(숫자/UDim)"까지만 | (a) v1 그대로 + 하나 완화: `UICorner: number \| UDim`(number → `UDim.new(0, n)`, UDim은 그대로), `UIPadding: UDim`(넷 전부), `UIPaddingOffset: number`(넷 = `UDim.new(0, n)`), `UIScale: number`; 전부 `T \| Tween<T> \| State<…>`(생성기 `PVn` 규칙) / (b) v1 문자 그대로(`UICorner`는 number만) / (c) 다른 | **(a)** | `CornerRadius`가 UDim이라 UDim을 막을 이유가 없고 wrap은 `type(v) == "number"` 분기 하나. 나머지는 v1이 이미 갈라 둔 의미(`UIPadding` = UDim, `UIPaddingOffset` = 숫자)를 이름으로 드러낸 것 |
| **Q4** | **우선순위 상수** — 정본: "`PropertyHandler`보다 높은 밴드면 된다, 구체 상수는 구현 시" | (a) **`HANDLER_PRIORITY_NORMAL + 1`**(같은 밴드 안의 오프셋 — `Dispatch`가 허용하는 형태, 동률 금지 문구가 그 자리를 위한 것) — `NoneHandler`(HIGH)보다 낮아 `UICorner = None`은 여전히 NoneHandler → nil 재귀로 이 핸들러에 닿는다 / (b) `HANDLER_PRIORITY_HIGH - 1` / (c) 새 밴드 상수 | **(a)** | 밴드 상수를 새로 만들지 않고(새 표면 아님), HIGH 밴드(센티널·재귀 전용)를 침범하지 않는다 |
| **Q5** | **관리 자식 매칭 실패의 처리** — Relate에 저장된 자식이 있는데 그 자식이 (사용자 손으로) 파괴됐거나 `.Parent`가 바뀐 경우 | (a) **Relate 참조가 있으면 그대로 쓴다**(파괴됐으면 `Dispatch.process(child, …)`가 엔진 에러 — `H-103` NOOP 캐비엇 부류; 사용자가 quad 관리 자식을 손댄 것은 계약 밖 — `Claim` 소유 규칙과 같은 결) / (b) `child.Parent ~= inst`면 새로 만든다 / (c) 다른 | **(a)** | 정본 "사용자가 만든 `UICorner`를 quad가 건드리지 않는다"의 거울상 — quad가 만든 자식은 quad 것. (b)는 방어 구조 |
| **Q6** | 단위 ② Studio 실측 항목 | (a) **다섯**: `Frame{ UICorner = 8 }`가 `_quad_round` 자식을 만들고 `CornerRadius.Offset == 8` / `State<number>` 변경이 자식 프로퍼티만 갱신(자식 재생성 없음) / `Tween{Value = 8}`이 `(child, CornerRadius)`에서 애니메이션(`:Mapped` 경로) / `nil`로 내리면 자식 파괴 + 다시 숫자면 재생성 + 첫 값은 스냅(정본 캐비엇) / `UIPadding = UDim.new(0, 4)`·`UIPaddingOffset = 4`·`UIScale = 1.5` 각각 자식·프로퍼티 / (b) 줄임 | **(a)** | 전부 엔진 대면(실제 자식 부착·트윈) |

## §1 범위 — 두 단위 (제안, Q2)

소스는 `ROADMAP.md` M10 배너의 InstanceShorthand 항목((a)~(f))과
`base/ui-shorthand-plan.md` 전 절. 정본 절: "메커니즘" 절(핸들러 계약·우선순위·
매칭 기준·Relate 조회·`UI-5`·위임 요구), "`v`가 `nil`인 경우" 절, "Tween 지원"
절(의사코드·`H-135`·`H-218`·`:Mapped`), "패키지 배치" 절.

**미리 알려진 주의**: ① 위임 체인은 `(child, prop)`으로 인덱스 **1**부터 —
새 체인. ② `v == nil` 경로: `retractFrom(child, prop, 1)` **먼저**(넷이면 넷 다)
→ 자식 `Destroy` → Relate 항목 제거 → `Void`. ③ 자식 생성은 `quad.D.New(cls)({
Name = childName })`(nativeClaim 포함) 뒤 `child.Parent = inst`(핸들러가 물리
부착 — InstanceChildHandler와 같은 자리). ④ `H-39` 부기는 해시 키라 없음.
⑤ 값이 Tween이면 `v:Mapped(wrap)`, 아니면 `wrap(v)` — Tween 해석은 여전히
PropertyHandler만. ⑥ 자식 재생성 직후 첫 값은 스냅(정본 캐비엇 — 문서화 대상,
버그 아님). ⑦ error 계약(영어, 값 타입 검증은 `errorBefore` — 디스패치 깊이,
체크리스트 0번).

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

M11 규약(`m11-implementation-round19-brief.md` §2~§5 = M8 = M7 = M5 = M4 = M3
준용본) 준용. 치환: 발견 문서는 `m10-shorthand-implementation-round20.md`
(`H-335`부터), 머리말 문구는 "M10 잔여(InstanceShorthand) 진행 중", 탐사자의
대조 중심 절은 `ui-shorthand-plan.md` "Tween 지원" 절 의사코드 / "메커니즘" 절 /
`dispatch-core-plan.md` `H-218` 블록·"인덱스의 의미" 절. §0 회신을 기다리지
않는다(사용자 2026-09-06). Studio 실측은 단위 ②에만(Q6).

## §6 단위 작업 계획 (Q2 (a) 기준 — 착수 시 채운다)

**[2026-09-06 단위 ① 완료 — `H-335`]** `Handlers/InstanceShorthand.luau`(룩업 표 넷·`D.New` 경로 자식·Relate 조회·`retractFrom` 뒤 파괴·`:Mapped`·`errorBefore` 검증, 우선순위 `NORMAL + 1`), `RobloxFactory` 설치, `spec.shorthand` 6절(mock — `UDim` 전역은 테이블 심).

**[같은 날 단위 ② — `H-336`/`H-337`]** 생성기(GuiObject 계열 Param·Modifier setter에 키 넷 — `PVn` 재사용), `spec.shorthandtypes`(양성), 음성 5/5 스크래치, test.sh `LuauSolverConstraintLimit=1000000`. Studio(Q6)는 아래 audit.

