# M9 자율 구현 규약 — 21라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-06 신설]** M9(컴포넌트 합성 레이어 — 플레인
> 함수 컴포넌트 관례의 문서화·예제 + `props.Modifier`/`props.Ref` 전달 관례를
> 정식 컴포넌트로 검증) 구간의 규약이자 착수 문항지. round20과 같은 지위.
> 산출물(발견 문서)은 `m9-implementation-round21.md`, 발견 번호는 **`H-340`부터**(`H-338`/`H-339`는 round19 리뷰 몫).
> 사용자 결정(2026-09-06)으로 순서는 M11 → InstanceShorthand → **M9**, §0은
> 권고 (a)로 착수하되 **새 표면·이름을 정하는 문항만 멈춘다**.
>
> **전제(이미 충족)**:
> - 정본 `base/component-composition-plan.md` "최종 결론" 절(2026-08-04 확정):
>   컴포넌트 = 플레인 함수(래퍼·매직 없음), 경계는 **named parameter**
>   (`props.Modifier`/`props.Ref` — **가칭**), 저작자가 `return Frame {
>   props.Modifier or None, props.Ref or None, … }`로 되꽂음(`or None` 필수 관용구
>   — nil-hole), 다중 루트 폐기(Slot 반환은 별개 메커니즘), 여러 modifier는
>   `Modifier.Overridden`. "남은 열린 질문"은 **이름뿐**(`Component` 래퍼 —
>   *"아마 불필요"*, `props.Modifier`/`props.Ref` 필드명).
> - 재료가 전부 실물이다: M7 Modifier(클래스 태그·`TypedFactory`/`DefineSubtype`·
>   `As`/`Into` — 커스텀 컴포넌트 Modifier의 정본 경로, `modifier-plan.md` 11절),
>   M8 Ref(`<Class>RefMarker`, `PreRef`/`PostRef`), M6 Slot, M11 Tween/Animate,
>   숏핸드. ROADMAP M9 항목 둘: 관례 문서화/예제, 관례를 정식 컴포넌트로 검증
>   (M0 스파이크 `06-component-boundary-nil-hole-props`의 정식화).
> - **문서화 자체(사이트·quadnomicon)는 M9가 아니다** — `research/documentation-plan.md`
>   백로그. M9의 "문서화"는 **정본에 관례를 확정 서술 + 실물 예제(spec)**까지.
>
> §2~§5는 round20 규약(= M11 = M8 = … = M3 준용본) 준용.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 | (a) round20 골격 그대로 / (b) 다른 | **(a)** | 코드가 거의 없는 구간(spec + 정본 서술) |
| **Q2** | **경계 필드 이름(새 표면 — 사용자 문항)** — 정본이 가칭으로 쓰는 `props.Modifier`/`props.Ref` | (a) **가칭 그대로 확정** `Modifier`/`Ref`(quad 값 이름과 1:1, 자동완성에서 곧바로 읽힘) / (b) 소문자 `modifier`/`ref` / (c) 다른 | **(a)** | 코퍼스 전체가 이미 이 표기로 서술해 왔고, 컴포넌트 저작자가 `props.Modifier or None`을 그대로 옮겨 적는 관용구가 한 글자도 안 바뀐다. **회신 전엔 spec·예제를 가칭으로 쓴다**(이름 교체는 치환 한 번) |
| **Q3** | `Component` 래퍼 | (a) **만들지 않는다** — 컴포넌트는 함수, 타입은 `(props: P) -> Instance`(또는 `-> Slot<T>`) 그대로 / (b) 식별용 슈가 | **(a)** | 정본 *"아마 불필요"* + "마법 안 쓴다" 사용자 확정. 필요가 관측되면 그때 |
| **Q4** | 검증 범위(ROADMAP 항목 2) | (a) **`quad-roblox/test/spec.component.luau`** — 플레인 함수 컴포넌트 예제 셋을 mock으로 실주행: ① 단일 루트(`MaterialButton(props)` — `props.Modifier or None`·`props.Ref or None`·`Overridden`·자식 전달·Tween/숏핸드 조합) ② Slot 반환 컴포넌트(`ItemList(props)` — Modifier/Ref 파라미터 없음, 형제 레벨 펼침) ③ nil-hole 회귀(스파이크 `06` 정식화 — `or None` 없이 꽂으면 실제로 무엇이 깨지는지 관측) + strict 타입 spec(`spec.componenttypes` — props 타입 `{ Modifier: DModule.FrameModifier?, Ref: QuadTypes.Ref<Frame?>?, … }`, `TypedFactory<<MaterialButtonModifier>>`/`DefineSubtype`/`Into<TextButton>` 경유) / (b) 런타임만 | **(a)** | M7 ④가 "컴포넌트 Modifier"를 이미 사용자 시나리오(`MaterialButton`)로 실측했으니 그 예제를 정식화하면 된다 |
| **Q5** | 정본 갱신 범위 | (a) `component-composition-plan.md`에 "구현 확정" 배너 + 예제 코드 블록(spec과 동일 소스) + "남은 열린 질문" 닫힘, `research/documentation-content-map.md`에 관례 항목(이미 등재돼 있으면 포인터만) / (b) 예제 파일을 별도 디렉터리(`examples/`)로 | **(a)** | 예제의 소스는 하나(spec) — 사이트용 예제는 문서화 마일스톤 몫 |
| **Q6** | Studio | (a) **생략** — 엔진 대면 델타 없음(전부 기존 핸들러 조합); 발견 문서에 기록 / (b) 한 번 | **(a)** | Q1 규약 |

## §1 범위 — 한 단위

`spec.component`(런타임 셋) + `spec.componenttypes`(strict) + 정본 배너/예제 + ROADMAP
M9 둘 `[x]`. Q2 회신이 오면 이름 치환(필요 시)만.

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

round20 규약 준용. 발견 문서 `m9-implementation-round21.md`(`H-340`부터). Studio 생략(Q6).

## §6 단위 작업 계획 (착수 시 채운다)

**[2026-09-06 완료 — `H-340`/`H-341`]** `spec.component`(5절: 단일 루트·생략·`Overridden`·Slot 반환·커스텀 클래스 상향)·`spec.componenttypes`(strict — `IntoTextButton`·`Ref<TextButton?>`·`TypedFactory<<T>>`), 정본 배너, ROADMAP M9 둘 `[x]`. Studio 생략(Q6 (a)). §4 문항 둘(Q2 이름·`H-340`).

Q5 (a)의 "예제 코드 블록"은 넣지 않았다 — 예제의 소스는 spec 하나(같은 코드를 정본에 복제하면 갈라진다, 감사 마감 라운드 판단); `documentation-content-map.md`엔 포인터만.
