# M3 구현 **12라운드** — 발견 원문 + 배치 문항지

> **이 파일이 무엇인가**: **[2026-08-31 신설]** M3 자율 구현 구간
> (`m3-implementation-round12-brief.md`가 규약, 같은 날 §0·§6 확정)에서 나온
> 발견 전부. 실제 코드를 옮기고 돌리다 나온 것이다. 번호는 **`H-212`부터**
> (11라운드가 `H-211`까지 썼다).
>
> **갈래 표기**(규약 §2): **①** 자율로 고침(같은 커밋에서 `base/`+코드) /
> **②** §4 표에 쌓아 배치 회신 대기 / **③** 즉시 중단·보고. M2 하자는
> 규약 §0 Q3 (a) — 경미하면 여기 ①, 설계 결정 규모면 그때
> `m2-implementation-round13`을 새로 연다.
>
> **상태의 소스는 이 파일 자신** — 요약 표의 상태 열이 최신.

## 요약 표

| 번호 | 갈래 | 단위 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|---|
| `H-212` | ① | 1 | 🟢 | `dispatch-core-plan.md` "Dispatch 체인" 의사코드의 error 세 자리가 한국어·`level` 없음 — 그 절(2026-08-13)보다 늦게 확정된 `architecture.md` error 계약(영어, level 이분, 2026-08-25)이 미반영 | ✅ 반영(`dispatch-core-plan.md` 의사코드 영어+level, `H-212` 문단). **[감사 3라운드 확장]** 같은 문서의 Length/Offset 절 두 자리(`getOffsetAt` 한국어 혼용 / `recompute` 한국어·level 없음)와 주입 op 스텁·가로채기 예시 메시지도 같은 부류라 같이 정정 — 스텁의 `level` 숫자만은 구현 시점(M5/M10) 몫으로 남김(도착지까지의 프레임 수를 문서 시점에 못 셈) |
| `H-213` | ① | 1 | 🟢 | `HANDLER_PRIORITY_*` 상수의 실제 숫자값을 어느 문서도 안 정했다 — 문서가 정한 건 이름·순서(HIGH > NORMAL > LOW > FALLBACK)·열린 공간(± 오프셋)뿐 | ✅ 구현이 채움: 1000 / 0 / -1000 / -1000000 (밴드 간 ± 오프셋 여유, `Dispatch/init.luau` 주석) |
| `H-214` | **②** | 1 | 🟡 | `listHandlers`가 "이름/priority를 반환"이고 동률 경고·`quad-debug` 체인 덤프도 핸들러 이름을 원하는데, Handler 계약(3종)엔 `name` 필드가 없다 — 새 필드라 자율 반영 불가 | ✅ **(a) 사용자 확정**(2026-08-31 §4 회신) — 계약에 선택 필드 `name: string?`(진단 전용). `quad-types`·`Dispatch/init.luau`(동률 경고에 이름, `TODO` 마커 제거)·`dispatch-core-plan.md` "핸들러 계약" 절·`spec.dispatch` 11번 반영 |
| `H-215` | **②** | 1 | 🟢 | 스파이크 `04`(Dispatch 체인 retractFrom) 처분 — `spec.dispatch.luau`가 검증 대상 대부분을 실측했는데 재귀 재발행 경로는 로컬 wrapping 핸들러 근사라 실제 `StoreBind`(M4) 몫이 남는다. 폐기는 `01`처럼 사용자 승인 사안(감사 2라운드 발견) | ✅ **(a) 사용자 확정**(2026-08-31 §4 회신) — 폐기·`done/` 이동, 잔여 몫(실제 `StoreBind` 경유 재발행)은 ROADMAP M4 mock 테스트 항목에 명시. `STATUS.md`·`README.md`·ROADMAP 재검증 대기 절 `[x]` |
| `H-216` | ① | 1 | 🟢 | `slot-plan.md`의 옛 error 예시 11곳(감사 5라운드가 계수 정정 — 처음 12로 잘못 셌다)이 한국어·`level` 없음(대표: `Slot:Add` 범위 검증, 요소 타입 3종, `dispose` 둘) — `H-212`와 같은 부류로, 그 문서 자신이 별도 절에서 "level 2, 영어" 규칙을 알고 있으면서 예시가 안 따라온 자리. M3 단위 2~4·M6이 옮겨 적기 전에 정리(감사 4라운드 발견) | ✅ 반영(`slot-plan.md` — 사용자 입력 검증은 level 2, `releaseOwner` 소유권 추적 파손만 내부 불변식 level 1) |
| `H-217` | ① | 1 | 🟢 | 같은 부류 마지막 4곳 — `attribute-plan.md`(그룹 이중 배치)/`debounce-throttle-plan.md`(Leading·Trailing 둘 다 false)/`ref-plan.md`(`PreRef` 재사용 — 파이프라인 의사코드의 `"PreRef instance reused"`와 다른 문구로 갈라져 있던 것도 통일)/`source-state-plan.md`(`bindLifetime` 이중 바인드 — mock 실구현 문구에 맞춤)가 한국어·`level` 없음(감사 5라운드 전수 스윕) | ✅ 반영 — 전부 영어+level 2. **base/ 코드 리터럴의 한국어 error는 이제 0**(잔여는 산문·옛 모델 인용·주석뿐) |

### `H-212` — base 의사코드 error가 error 계약 이전 표기로 남아 있었다 (①)

`process`의 retractor 생략 error 두 자리와 `retractFrom`의 배열 구멍 error가
한국어 메시지에 `level` 인자 없음 — `base/architecture.md`의 "error 계약 —
`level` 이분과 메시지 언어" 절(*"`base/`의 예시 메시지도 영어로 쓴다"*)이 그
의사코드보다 늦게 확정되며 반영이 안 된 자리다. 문서가 이미 답(영어 + level
이분)을 갖고 있어 ①: retractor 생략은 핸들러(제공자) 계약 위반이라 호출부를
가리키는 `2`, 배열 구멍은 내부 부기 파손이라 그 자리를 가리키는 `1`.
`base/`와 코드를 같은 커밋에서 맞췄다.

### `H-213` — 우선순위 밴드 상수의 리터럴 값 (①)

"우선순위 동률/매치 실패 처리" 절은 상수 **이름 넷**과 순서, "열린 숫자 공간
위의 편의 상수"(`HANDLER_PRIORITY_HIGH + 1`식 미세 조정)만 정하고 값은 안
정했다. 구현 선택: `HIGH = 1000` / `NORMAL = 0` / `LOW = -1000` /
`FALLBACK = -1000000`. 근거 — 밴드 사이 간격이 커서 ± 오프셋이 이웃 밴드를
침범하기 어렵고, `FALLBACK + 1`(base Fallback을 가로채는 관례 자리)이 `LOW`
보다 한참 아래에 남는다. 계약 의미(순서·밴드)는 값과 무관해 사용자 결정
대상이 아니라고 판단 — 다른 값을 원하면 §4 회신에 얹으면 된다.

### `H-214` — `listHandlers`/동률 경고가 원하는 핸들러 "이름"이 계약에 없다 (②)

`dispatch-core-plan.md` "우선순위 동률/매치 실패 처리" 절: *"`Dispatch.listHandlers()`는
현재 등록된 전체 핸들러(이름/priority)를 **반환**"*. **[감사 3라운드 정정]**
"체인 슬롯을 이름으로 바로 덤프" 서술도 **같은 문서**의 "부수 효과 —
quad-debug에 유리" 항목에 있다(처음엔 `research/debug-tooling-plan.md`로 잘못
적었었다 — 그 파일엔 그 구절이 없고, 대신 핸들러가 **선택적으로** 구현하는
`describe` 훅(가칭, 미정)이 이름 관련 전례로 있다). 그런데 핸들러
계약은 `isHandlable`/`priority`/`process` **3종으로 못 박혀** 있고(같은 문서
"핸들러 계약" 절: *"다음 3개를 제공하는"*), `name`을 붙이는 건 **새 필드**라
규약 §2의 ② 갈래다. 기각 이력 grep: Handler에 이름 필드를 검토·기각한 기록
없음(등록 엔티티 이름 논의(`TagFallbackHandler` 등)는 **변수명** 이야기지
계약 필드가 아님). 임시 구현: 등록된 핸들러 객체 배열(우선순위순 사본)을
그대로 반환 — 정의된 정보(priority, 함수들)는 다 담기고 새 개념이 없다.
동률 경고 print는 priority 값만 찍는다. 코드 마커 `TODO(H-214)` 1곳
(`Dispatch/init.luau`의 `listHandlers`).

**[2026-08-31 종결 — (a) 사용자 확정]** 계약에 선택 필드 `name: string?`
(진단 전용 — 동률 경고·`listHandlers`·나중의 `quad-debug` 덤프, 스캔·매치
무영향). 반영: `quad-types` `Handler` 타입 / `Dispatch/init.luau`(동률 경고에
양쪽 이름, 마커 제거) / `dispatch-core-plan.md` "핸들러 계약" 절 신설 항목 /
`spec.dispatch` 11번(이름 왕복·부재 시 nil). 코드 마커 0.

## §4 배치 문항지 (사용자가 읽을 유일한 자리)

**⭐ [2026-08-31 회신 — 단위 1 몫 전량 종결]** 사용자: *"배치 문항은 중간확인
완료했어. 전부 권고안에 동의해. 나중에 천천히 반영해줘"* — `H-214`·`H-215`
둘 다 **권고 (a) 채택**, 같은 날 반영 완료(각 행 상태 참고). 열린 문항 0.

| 번호 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| `H-214` | `listHandlers`·동률 경고·(나중의) `quad-debug` 덤프가 쓸 핸들러 **이름** — Handler 계약(3종)엔 `name`이 없다 | (a) 계약에 **선택 필드 `name: string?`** 추가 — 있으면 경고·덤프·`listHandlers`가 쓰고 없으면 priority만 / (b) 이름 없이 감 — `listHandlers`는 핸들러 객체 배열만 반환(지금 임시 구현), "이름/priority" 서술을 문서에서 걷어냄 / (c) 다른 방식(별도 등록 인자 `addHandler(h, name)` 등) | **(a)** | `dispatch-core-plan.md` **두 자리**("우선순위 동률/매치 실패 처리"의 `listHandlers` 이름/priority + "부수 효과 — quad-debug에 유리"의 체인 슬롯 이름 덤프)가 이미 "이름"을 전제하고(**[감사 3라운드 정정]** 후자를 처음엔 `research/debug-tooling-plan.md`로 잘못 인용 — 거긴 대신 선택적 `describe` 훅(가칭)이 전례), 선택 필드면 기존 3종 계약을 안 깬다. **(b)를 고르면 두 자리 다 걷어야 한다.** (c)는 이름이 핸들러 자신이 아니라 레지스트리에 살게 돼 체인 슬롯 덤프(슬롯엔 handler 객체만 저장)가 역조회를 또 요구함 |
| `H-215` | 스파이크 `04`(Dispatch 체인 retractFrom, `rewrite-required/`) 처분 — `spec.dispatch.luau`가 체인 깊이·레벨별 힌트·3-인자 `retractFrom`·`SetStrong` 음성 대조군을 이미 실측했으나, 재귀 재발행은 spec-로컬 wrapping 핸들러 **근사**다(실제 `StoreBind`는 M4) | (a) 지금 폐기(`01`처럼 `done/` 이동) — 잔여 몫(실제 `StoreBind` 경유 재발행 경로)은 **M4 StoreBind spec이 진다**고 그 단위 계획에 명시 / (b) M4까지 `rewrite-required/`에 유지(현 ROADMAP 문구 "M3 착수 시 같이 처리"를 "M4에서"로 정정) / (c) 지금 재작성 | **(a)** | 체인 메커니즘 자체는 `spec.dispatch.luau` 12절이 실제 구현에 대고 고정했고(스파이크는 격리 재현이라 오히려 약함), `05`/`15`/`01` 폐기와 같은 근거 구조다. 잔여 몫을 M4 spec 항목으로 옮겨 적으면 잊히지 않는다 |

## §5 이상 없음 확인 (탐사자·구현이 확인만 하고 문제 없었던 자리)

- **[2026-08-31, 단위 1 구현]** "Dispatch 체인" 절 의사코드를 한 줄씩 옮기며
  대조 — (A)/(B) 분기, (A)의 소비 직후 `NOOP` 교체, (B)의 점유 마커 선행,
  `chains:SetStrong`이 `h.process` 앞, retractor 생략 즉시 error 양쪽,
  `retractFrom` 꼬리 역순·항상 소비·구멍 error, `H-103` 주석(pcall 안 감쌈)
  전부 그대로 — 전사 차이는 `H-212`(error 표기)뿐. `spec.dispatch.luau`
  1~12가 각 계약을 실측(같은 핸들러 두 슬롯 = `State<State<T>>` 유사 구조,
  깊은 체인 (A) 연쇄에서 각 레벨이 자기 힌트를 받는 것 포함).
- **[2026-08-31]** `F-4-1`의 언어 동작(일반화 `for`가 배열 파트 전체를
  해시보다 먼저, 배열 안은 index 순서) — `spec.drive.luau` 1번이 실측 통과.
  스파이크 `01` 재작성은 이 spec이 상시 회귀로 대체(§6 계획, `STATUS.md`에
  기록).
- **[2026-08-31]** 매치 실패 메시지의 "브랜드 출력"은 기각된 Brand 역조회
  (`archive/brand-shared-registry-reversed.md`)를 재도입하지 않고 모듈 공개
  술어(`is*`) 프로브로 구현 — 실패 경로에서만 돌고(지연 생성 규칙), 새 표면
  없음.
- **[2026-08-31]** `H-165`(quad-types에 `export type` 추가 시 pesde shim
  재생성 필요)를 예고대로 밟았고 `pesde install` 재실행으로 해소 —
  `Handler`/`Dispatch`가 shim에 올라옴. 새 발견 아님(문서 그대로).

## §6 남은 의심 (발견은 아니지만 다음 라운드가 파볼 자리)

(아직 없음)
