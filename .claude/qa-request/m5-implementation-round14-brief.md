# M5 자율 구현 규약 — 14라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-01 신설 — §0 회신 대기]** M5(quad-roblox
> 최소 프로바이더) 구현 구간의 규약이자 착수 문항지다. M4의
> `m4-implementation-round13-brief.md`와 같은 지위 — §0이 확정되면 이 파일이
> M5 규약 소스다. 산출물(발견 문서)은 `m5-implementation-round14.md`.
>
> **명명**: `mN-implementation-roundNN` 규약 그대로 — M5의 첫 라운드가
> **round14**, 발견 번호는 round13이 `H-289`까지 썼으므로 **`H-290`부터**.
>
> **전제(이미 충족)**: Studio MCP 연결(`HUMAN_TODO.md` 1번)과 스파이크 `10`
> 완주(`audit/spike10-full-run-2026-09-01.md`)로 **gcconn/`nativeClaim`의
> 실기기 전제가 전부 실측 확인**됐고(무claim inst의 userdata 1 GC 사이클
> 수거 = claim의 존재 이유 실증), 에이전트가 Studio에서 직접 검증을 돌릴 수
> 있다. M5는 M2~M4와 달리 **실기기 축이 절차 안에 들어오는 첫 마일스톤**이다.
>
> §2~§5는 M4 규약(= M3 준용본)을 준용하고, 다른 자리에만 `[M5 변경]` 표시.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 + 실기기 절차 확장 | (a) M3·M4 골격 그대로(세 갈래 / 커밋 게이트 두 층 / 단위 끝 절차 / 새 핸들러 전 "Handler 작성 체크리스트" 필독 게이트 / 운용 규약 — 유한 절차·리뷰 흐름당 1회·강도는 diff 규모) + **[M5 확장] 단위 끝 절차에 Studio MCP 실측 추가** — CLI spec이 못 닿는 실기기 검증(userdata·복제·렌더)은 `execute_luau`로 에이전트가 직접, 판정은 스파이크 `10` 관례(PASS/FAIL 계수 + 최종 마커 — grep 계수 단독 금지, `H-287` 교훈)와 Studio 운용 주의(죽으면 위험 명령 반복 금지·대기) 준수 / (b) 실기기 검증은 사용자 수동으로 분리 / (c) 다른 방식 | **(a)** | 골격은 세 구간 실측으로 검증됐고, 실기기 축은 스파이크 `10` 완주로 에이전트 단독 실행이 실증됐다(GC 대기까지 청크 분할로 완주). 사용자 수동 분리는 이제 병목만 만든다 |
| **Q2** | 단위 절단 — M5는 체크박스 6개·새 패키지 전체·코드 생성기 포함으로 M2~M4보다 크다 | (a) **다섯 단위**: ① `RobloxFactory`+`EngineOps`+`LifetimeHandle` 실구현(주입 op 전량 — `nativeClaim`/`nativeFindChild` 포함, `_initializedBy`, `H-238` 태그 의무) + Studio 스모크 → ② `D/init.luau` 생성기(+`<Class>Param<E>` 타입 스파이크) → ③ `Handlers/Property`+`InstanceChild` → ④ `Claim`+`D.Mapper` → ⑤ 첫 `Frame{...}` 렌더 실측+종합 / (b) 셋으로 굵게(팩토리+op / D+Handlers / Claim+렌더) / (c) 다른 절단 | **(a)** | 각 단위가 서로 다른 정본 절에 대응하고(모듈 주입 / 생성기 / 핸들러 / Claim), 단위 끝 절차가 "직전 수정이 새 결함을 만든다"를 반복 잡아온 실측상 절단면이 많은 쪽이 안전하다. ⑤를 따로 두는 건 ROADMAP 마지막 체크박스가 통합 검증 성격이라서다 |
| **Q3** | `quad-roblox`의 `quad_base` 의존 — **base 두 문서가 어긋나 있다**: `architecture.md` 소스 트리는 *"quad-base가 아니라 quad-types에만 workspace 의존"*, `project-setup-plan.md`는 `[dependencies] quad_base = { workspace = … }`라 적고 "M5+에서 `quad_base`를 쓰면 `luau` CLI로 직접 못 돈다"는 실무 영향까지 예고 | (a) **dev deps 분리(사용자 제안, 2026-09-02)** — `[dependencies]`는 `quad_types`만 유지(architecture 정본 — `RobloxFactory(module)`는 모듈 인스턴스를 **인자로 받아 뮤테이션**하므로 런타임 require 불필요), **`[dev_dependencies]`에 `quad_base`**(workspace, `target = "luau"` — 같은 파일의 `quad_types` 의존에 선례)를 넣어 spec은 `quad-roblox/test/`에 둔다. `relink.sh` 글롭이 전 멤버의 `*_packages`를 커버해 CLI 심볼릭 문제는 기존 장치로 해소, `project-setup-plan.md` 서술은 이 모양으로 정정 / (b) 런타임 의존 없음 + spec을 quad-base 쪽 test 트리에(구 권고 — 패키지 응집이 깨지는 차선) / (c) 런타임 `quad_base` 의존 추가 | **(a)** | 사용자 제안(*"dev deps 로 처리 못하니? 실제 런타임에는 직접 주입이라 타입만 필요한건 맞긴 하거든"*)이 두 문서의 참인 절반을 다 살린다 — architecture의 런타임 무의존과 project-setup-plan의 "테스트는 quad_base를 쓴다"는 실무. pesde는 dev_dependencies를 지원하나 워크스페이스+`target` 조합의 실동은 M5 첫 install에서 검증(어긋나면 발견으로) |
| **Q4** | `EngineOps.luau`의 M5/M10 분할 — 한 파일을 두 마일스톤이 나눠 채우는데(M5 `native*`/M10 Tag·Attribute) M5에서 어디까지 쓸지 미지정 | (a) **M5는 자기 몫만** — `native*` 전량 + `isInst`/`onDestroying`/`nativeClaim`/`nativeFindChild` + 생명주기 4종. `addTag`/`removeTag`/`setAttribute`/`setTimeout`은 스텁 유지(M10·백로그 몫 그대로 — 미주입 에러가 명확해 혼란 없음) / (b) 파일 여는 김에 Tag/Attribute 셋도(각 한 줄 구현) / (c) 다른 방식 | **(a)** | "최소 프로바이더"라는 마일스톤 정의 그대로 — 첫 렌더(Frame+프로퍼티+자식)에 Tag/Attribute가 필요 없고, M10 체크박스가 소유한 몫을 앞당기면 진행 소스가 둘이 된다. 구현 한 줄짜리라 (b)의 이득도 작다 |
| **Q5** | 클래스별 typed Modifier 생성자(`FrameModifier` 등)의 마일스톤 — `research/pre-implementation-audit.md` 2-8이 "M5 또는 M7에 명시적으로 추가하라"고 제안한 채 방치돼 있고, `bind-system-plan.md`는 두 목록(props의 `Parent` 제외 / Modifier 메소드의 `Parent` 제외)이 **같은 API 덤프에서 따로 생성**된다고 적음 | (a) **M7로 명시 이관** — M7 체크박스에 항목 추가, M5의 `D` 생성기는 산출 구조만 대비(API 덤프를 재사용 가능한 형태로 두고 `Parent` 제외를 덤프 층에서) / (b) M5 `D` 생성기에 포함 / (c) 다른 방식 | **(a)** | Modifier 프리미티브 자체가 M7이라 생성자만 앞당기면 검증 대상 없이 코드만 생긴다. 2-8의 요구는 "어느 쪽인지 명시"이므로 (a)로 닫힌다 — 단 덤프 층 `Parent` 제외를 M5가 해두면 M7이 한쪽만 빼먹는 사고(`bind-system-plan.md` 경고)가 구조적으로 막힌다 |
| **Q6** | 스파이크 `10` B 발견(Attribute Instance 참조는 `InstanceHandle` 언랩 경유 — 미문서화 Studio Beta)의 등록 위치 — 감사가 "실행 가능한 곳에 등록 안 됨"을 지적 | (a) **ROADMAP M10(Attribute op 몫) 체크박스에 각주 등록** — "읽기 소비자(`InstanceAttribute` 읽기 타입, quad-debug)는 `:Get()` 언랩·nil·죽은 참조 위에서 설계" + `audit/spike10-full-run-2026-09-01.md` 포인터(attribute-plan 배너는 이미 있음) / (b) `question.md`에 올려 지금 설계 결정 / (c) audit 산문 유지 | **(a)** | quad의 Attribute **쓰기 경로는 무영향**(엔진이 자동 랩)이라 지금 정할 설계가 없고, 읽기 소비자가 생기는 마일스톤(M10·quad-debug)의 체크리스트에 걸어두는 게 발견이 잊히지 않는 유일한 실행 가능 자리다. Beta라 그 시점 재실측도 어차피 필요 |

**(§0 회신 대기 — 확정되면 이 자리에 회신 기록)**

## §1 범위 — 다섯 단위 (제안, Q2)

소스는 `ROADMAP.md` M5 체크박스(여섯, 상세는 거기가 소스)와
`base/claim-plan.md` §9 구현 체크리스트. 정본 절:

1. **단위 ①** — `RobloxFactory.luau`(`_initializedBy` 문자열 마커, 재호출
   가드 — `module-lifecycle-plan.md`의 "New()의 내부 구성" 절과 그 아래
   `InitRoblox` 예시가 정본) + `EngineOps.luau`(**주입 op 전체 목록의 단일
   소스는 `architecture.md`의 그 줄** — Q4 (a)면 M5 몫만 구현, 나머지 스텁
   유지) + `LifetimeHandle` 4종+`onDestroying` 실구현(`lifecycle-pattern.md`
   (0)/(1) 스케치가 정본, **mock `installLifetime`과의 의도적 발산 하나** —
   mock은 lazy claim, 실물은 생성 시점 `nativeClaim` 1회). **`H-238` 의무**:
   주입하는 모든 함수를 `errorNamespace.setFuncLevel(fn, SURFACE)`로 태그.
   Studio 스모크: `nativeClaim` 후 userdata 고정·Destroy 후 `canExecute`
   false를 실기기에서(스파이크 `10` A와 같은 모양).
2. **단위 ②** — `D/init.luau` 생성기("GUI에 쓰이는 모든 인스턴스" + 이벤트
   필드 콜백 타입, **props에서 `Parent` 제외**(`H-142`) — 덤프 층에서 빼서
   M7 Modifier 목록과 공유(Q5)). `<Class>Param<E>` 타입 스파이크
   (`claim-plan.md` §7-12·§9 — `luau-analyze`) 선행 또는 동반.
3. **단위 ③** — `Handlers/Property.luau`(`"Parent"` 키 거부 — 배선은
   에이전트 선택, `bind-system-plan.md`) + `Handlers/InstanceChild.luau`
   (**부기 순서 `H-134`**: `setOffsetSource(inst,k,None)` → `v.Parent=inst` →
   `setLength(inst,k,1,inst)`, retractor 첫 줄 `H-154`). 착수 전 "Handler
   작성 체크리스트" 절 필독 게이트.
4. **단위 ④** — `Claim(inst, desc) -> inst` + `D.Mapper` 생성기 + 루트 키
   센티널 + `MapperDescriptor` 브랜드 + `nativeFindChild` 소비(정본은
   `claim-plan.md` §7·§9 전체 — 가칭·에이전트 재량 마커가 붙은 자리는 §2
   갈래 ①로 정하고 발견 기록, 정의 파일 위치 확정 시 `architecture.md` 소스
   트리 반영).
5. **단위 ⑤** — 실제 Roblox 첫 `Frame{...}` 렌더 확인(Studio MCP) + 종합
   spec + `quad-types`의 `Quad` 갱신 몫 확인(`H-25` — 이번엔 "갱신 있음"이
   기본 기대: `QuadRoblox` 진입점·`CheckedQuad` 배선).

**미리 알려진 주의**: ① Roblox 백엔드는 `nativeMove`/`nativeSwap`을 **no-op으로
반드시 덮어쓴다**(ROADMAP M5 배너 — 조합 폴백은 detach+reattach 깜빡임).
② error 계약 — 메시지 영어, `errorBeforeNearest`/`errorBefore`/`error(msg,1)`
삼분, **태그는 테이블 경유 호출 함수에만**(`H-250`), 미주입 스텁의 level
도착지는 구현 시 도착지 계약대로. ③ Fallback 핸들러 등록 주체는 quad-base
자신이다 — 백엔드 팩토리가 등록하지 않는다(`dispatch-core-plan.md` 재역전).
④ 공개 타입은 단일 파일에 몰아둔다(ROADMAP M5 배너). ⑤ `PlayerGui`류 공동
소유 컨테이너는 claim·매퍼 범위 밖(§7-11).

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

M4 규약(`m4-implementation-round13-brief.md` §2~§5 = M3 준용본) 준용. 치환:
발견 문서는 `m5-implementation-round14.md`(`H-290`부터), 머리말 문구는
"M5 진행 중", 탐사자의 대조 중심 절은 `claim-plan.md` §9 /
`architecture.md` 소스 트리·주입 op 줄 / `lifecycle-pattern.md` (0)(1) /
`module-lifecycle-plan.md`의 "New()의 내부 구성" 절. M2~M4 하자는 동형
규칙(경미하면 round14에 ①, 설계 결정 규모면 그 시점 다음 번호로 해당
마일스톤 라운드 신설). **[M5 변경]** §4 단위 끝 절차에 Q1 (a)의 Studio MCP
실측이 들어간다 — 실기기 판정도 발견 문서에 기록하고, 실측 결과가 `base/`
서술과 어긋나면 그 자체가 발견이다(스파이크 `10` B가 선례).

## §6 단위 작업 계획 (승인 대상 — Q2 (a) 기준, 단위 ① 상세만 먼저)

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-roblox/src/RobloxFactory.luau` | `QuadRoblox(module)` — `_initializedBy` 가드 → op·생명주기 주입 → `H-238` 태그 → return | `module-lifecycle-plan.md` `InitRoblox` 예시 + `architecture.md` 소스 트리 |
| `quad-roblox/src/EngineOps.luau` | Q4 (a) 범위의 op 본체(`nativeClaim`은 `lifecycle-pattern.md` (0) 그대로 — 클로저가 gchold+**inst** 캡처) | `architecture.md` 주입 op 줄(단일 소스) |
| `quad-roblox/src/LifetimeHandle.luau` | (1) 스케치의 실물 — `InstData`/`BindData` Relate, `isBoundAlive` 공유, `_assertBindable`·`_catchUp`·`_bindDestroying` 후처리 포함 | `lifecycle-pattern.md` (1) + mock 대조(의도적 발산은 lazy claim 하나뿐이어야 함) |
| `quad-roblox/src/init.luau` | 진입점 — `CheckedQuad<T, Pattern>` 버전 확인 배선 | `quad-types-plan.md` |
| spec + Studio 스모크 | 배치는 Q3 결정 따름 | — |

**커밋 단위**: 단위당 커밋 하나 + 단위 끝 절차(M2~M4 관례). 단위 ②~⑤의
상세 표는 각 단위 착수 시점에 §6에 이어 쓴다(M3 관례 — 첫 단위만 승인
대상으로 먼저).
