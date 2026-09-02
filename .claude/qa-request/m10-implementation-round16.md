# M10 병렬 탐사 **16라운드** — 발견 원장 (fork/worktree, `spike/m10-tag-attribute`)

> **이 파일이 무엇인가**: **[2026-09-02 신설]** M10(Tag/Attribute) 병렬 탐사
> fork의 발견 전부 — 규약은 `m10-implementation-round16-brief.md`(M6 브리프
> §2·§3 준용). 번호는 **`H10-1`부터**(접두형 — 메인 `H-nnn`·M6 `H6-nnn`과
> 구분, ID 영구). **산출물은 관측용 후보** — 통합·문서 반영·판정은 메인 몫.
>
> **상태의 소스는 이 파일 자신.** 갈래: ① fork 자율(코드+이 원장만) /
> ② 통합 시 메인·사용자 판정 대기 / ③ 즉시 중단감.

## 요약 표

| 번호 | 갈래 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|
| `H10-1` | ① | 🟡 | **ROADMAP M10의 파일 분할(6파일 — `Dispatch/Tag.luau`+`TagFallback.luau` 등)은 `H-278` 이전 서술이다** — M3 회신 라운드가 확정한 "각 값 선언 모듈이 자기 Init에서 등록"(Observer/Effect 실선례)과 충돌. Tag/Attribute Fallback 핸들러는 정확히 "한 값 타입의 핸들러"라 `H-278` 부류 | ✅ fork 반영 — `Tag.luau`/`AttributeKey.luau`/`Attribute.luau` 각 1파일(값+핸들러+등록, `InitXxx`가 `RunInit(InitDispatch)` 당김). "FallbackHandler"는 별도 파일이 아니라 **등록 엔티티 이름**으로 유지(`TagFallbackHandler` 등 — 문서의 별도-엔티티 요구의 실질은 이름·priority 분리라고 판단). ROADMAP 문서 정리는 통합 시 메인 몫 — 이 판단이 틀렸다면 뒤집을 것 |
| `H10-2` | ① | 🟡 | **op 스텁은 `errorBefore`(최외곽)여야 한다** — `LifetimeHandle.luau`의 스텁은 `errorBeforeNearest`인데 그건 사용자가 직접 부르는 표면이라 성립하고, tag/attr op 스텁은 **디스패치 깊이(핸들러 process)에서 호출**되므로 Nearest가 quad 내부(`Tag.luau`)를 blame(실측 — spec 2절이 잡음). `H-272`와 같은 사정 | ✅ 반영 — 두 스텁 팩토리 `errorBefore`로, 사유 주석. spec이 blame을 상시 회귀로 고정 |
| `H10-3` | ② | 🔴 | **quad-types `Quad`에 교집합 콜러블 타입(`TagConstructor = ((...string) -> Tag) & {Merged…}`)을 필드로 실으면 하류 제네릭 추론이 오염된다** — `QuadRoblox<T>` 경유 `q`가 `Type 'nil' does not have key` 류로 무너짐(luau-lsp 새 솔버, **A/B 실측**: HEAD quad-types 클린 / 필드 추가 시 재현 / 필드만 `any`로 되돌리면 해소) | ✅ **(d) [2026-09-02 사용자 지시 실험 → 채택, 통합(2026-09-03)에서 반영]** 원장 갈래 (a)~(c) 밖에서 사용자가 `setmetatable<{}, {__call}>` 실험을 지시, 서브에이전트 오버레이 A/B로 성립 실측(제네릭 오염·값 캐스트 붕괴 동시 해소, 잔여는 `__call` 인자 무검사 하나) — *"우선 권고대로 채택하고자 해"*. 통합 머지에서 quad-types를 `setmetatable<A,B>` 표기로 교체·`Quad` 필드 풀 타입 복원, 경위는 `session/2026-09-02-03-h10-3-setmetatable-decision.md`, 등재는 typing-limits 8.6절 |
| `H10-4` | ① | 🟡 | `__call` 콜러블 테이블 **값**도 함수∩테이블 교집합 타입을 구조적으로 불만족 — quad-base `init.luau` 리터럴의 `:: Quad` 캐스트가 "unrelated"로 붕괴(H10-3과 같은 뿌리의 값-측 증상) | ✅ 반영 — 리터럴에서 두 네임스페이스만 `:: any`(사유 주석). **[2026-09-03 통합]** H10-3 (d) 채택으로 그 캐스트도 제거 — 리터럴 `:: Quad`가 그대로 통과(오버레이 실측) |
| `H10-5` | ② | 🟡 | **M5 `spec.robloxfactory.luau` 6절과의 통합 지점** — 그 절은 "M5 스코프 밖 op == nil"을 단언했는데, M10 확정 설계(재역전 2026-08-18: quad-base가 안내 스텁+Fallback을 **항상** 자기 등록)가 들어오면 실질이 "nil"→"미채움 스텁"으로 바뀐다. fork가 그 절을 스텁 단언(호출 시 "not available" + setTimeout/clearTimeout은 여전히 nil)으로 재작성했다 — **M5 산출물 수정이라 통합 시 메인이 M5 원장과 대조해 판정할 것**(Q4 (a)의 본뜻 "quad-roblox가 M5에서 안 채움"은 그대로 검증됨) | ✅ **[2026-09-03 통합 — 메인 판정 승인]** 재작성이 Q4 (a) 본뜻 + 2026-08-18 재역전(quad-base 상시 자기 등록) 둘 다 보존 — 그대로 편입, 전 스위트 exit 0 |
| `H10-6` | ① | 🟢 | mock 확장(브리프 몫) — `installTagAttributeOps(quad, log?)`(addTag/removeTag/setAttribute + `H-238` 태그) + 관측 헬퍼 `getTags`/`getAttributes`. 로그는 이름 정렬(집합 순회 비결정) — "배치 호출"·"진짜 바뀐 이름에만" 계약을 spec이 직접 관측 | ✅ 반영 |
| `H10-7` | ① | 🟡 | **[2026-09-03 통합 감사 2라운드 — 메인 발견]** fork 산출물의 **공개 생성자·메소드가 `H-238` 태깅에서 빠져 있었다** — `Tag(...)`(`__call`)·`Tag.Merged`·`TagImpl` 메소드·`AttributeKey(...)`·`Attribute(...)`·`Merged`/`Overridden`에 `setFuncLevel`이 없어(스텁만 태그) 사용자 인자 오류가 raise-site 폴백으로 quad 내부 줄을 blame. spec은 메시지만 확인해 못 잡았다 | ✅ 반영 — 전부 SURFACE 태깅(파일 스코프 1회 — 공유 네임스페이스) + 인자 검증은 quad-error 헤더 규약대로 `errorBeforeNearest`(콜백 안 호출도 그 줄을 blame; 핸들러 process·op 스텁의 `errorBefore`는 `H10-2` 그대로), `spec.tag`/`spec.attribute`에 blame 음성 대조군 추가. 전 스위트 exit 0 |

**확인만 하고 문제 없던 것**:

- **정본 의사코드 → 실코드 1:1** — tag-plan의 참조 카운트(위치 키잉·생존
  홀더 유지·배치 호출·`v == nextValue` 스킵), attribute-plan의 이름
  claim·`groupClaimKeys` 선행(`H-41`)·그룹 전용 키 메모이즈·균일
  철거→재등록·"클로저는 setAttribute 절대 안 부름" 전부 spec으로 상시
  회귀화(`spec.tag.luau` 6절 / `spec.attribute.luau` 8절 — 깜빡임 방지·
  참조 카운트·구독 절단·값 잔존·claim 충돌·이중 배치까지 실주행 검증).
- **`H-39`/`H-52` 반영** — 두 배열-자리 핸들러 모두
  `setOffsetSource(None)`+`setLength(0, inst)` 부기와 `type(k) == "number"`
  가드(offset 산술 생존을 spec이 확인).
- **attribute-plan 의사코드의 `error(…, 2)`들은 현행 error 계약으로 이관**
  (`errorBefore(SURFACE)`) — claim-plan §7-10 정정(2026-09-02)과 같은 결.
  통합 시 attribute-plan 본문 정정은 메인 몫.
- **StoreBind 맞물림** — 그룹 위임 `dispatch.process(inst, key, source, 1)`
  이 HIGH의 StoreBind에 잡혀 구독·언랩 후 FALLBACK의 키 핸들러로 내려오는
  경로가 설계 그대로 동작(필드 하나 변경 = 엔진 호출 정확히 1회를 로그로
  단언).
- **워크트리 환경 기저** — `doc-check.py` ERROR 2건은
  `initreq/`(gitignore 비추적)가 워크트리에 존재하지 않아 생기는 참조
  깨짐(`dispatch-core-plan.md:40`/`session-summary.md:1279`)이지 코퍼스
  결함이 아님. 게이트는 "새 ERROR 0"으로 운용했다(이 두 건 외 0 확인).
- **quad-types `Quad` 갱신**(`H-25` 몫) — is 술어 셋 + 값 표면 여섯 필드
  (H10-3 잠정 반영 상태) + `Tag`/`Attribute`/`AttributeKeyObject` 타입.

## 멈춤 판정

②가 둘(H10-3/H10-5) 있으나 **둘 다 잠정 처리로 독립 작업이 계속 가능**했고
(유니언 후퇴는 런타임 무영향, spec 재작성은 본뜻 보존) 상위 설계 문제
냄새(코어 결함·정본 모순)는 아니어서 §2의 즉시-멈춤 조건에 해당하지 않는다
— 스코프 전체(ROADMAP M10의 Tag/Attribute 몫)를 완료하고 종료 보고로
회신을 구한다. Event/OnChange/InstanceShorthand는 브리프 §1이 스코프 밖으로
명시(quad-roblox 엔진 축).
