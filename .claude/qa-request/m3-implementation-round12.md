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
| `H-217` | ① | 1 | 🟢 | 같은 부류 마지막 4곳 — `attribute-plan.md`(그룹 이중 배치)/`debounce-throttle-plan.md`(Leading·Trailing 둘 다 false)/`ref-plan.md`(`PreRef` 재사용 — 파이프라인 의사코드의 `"PreRef instance reused"`와 다른 문구로 갈라져 있던 것도 통일)/`source-state-plan.md`(`bindLifetime` 이중 바인드 — mock 실구현이 던지는 두 분기 메시지의 공통 접두를 딴 **근사**, 실분기는 그 절의 게이트 스케치 몫)가 한국어·`level` 없음(감사 5라운드 전수 스윕) | ✅ 반영 — 전부 영어+level 2. **base/ 코드 리터럴의 한국어 error는 이제 0**(잔여는 산문·옛 모델 인용·주석뿐) |
| `H-218` | **②** | 1 | 🟡 | (`/code-review high`) `chains` 리스트의 retractor 클로저가 `inst`를 캡처해 **weak 키를 버킷 값이 되참조** — `H-71`이 실측한 "100% 새는" 패턴이라, `dispatch-core-plan.md`의 *"자식을 버리면 결국 GC되지만"* 주장과 그 위에 선 `ui-shorthand-plan.md` `UI-11`의 GC 근거가 **거짓**. 반응형 숏핸드 자식을 파괴/재생성하는 사이클마다 구독·gchold가 누적. 구현은 확정 의사코드에 충실 — 처방(위임 자식 철거 시 `retractFrom` 의무화 여부)이 계약 변경 | ✅ **(a) 사용자 확정**(2026-08-31 회신 2, *"a 로 가면 될것 같아"*) — 위임 핸들러는 자식을 버릴 때 무조건 `retractFrom(child, prop, 1)`(`UI-11` 부분 역전). `dispatch-core-plan.md`·`ui-shorthand-plan.md`(스케치 포함) 반영. **사용자 되물음(Destroy 경로도 같은 문제 아닌가)은 검증 결과 맞았다 — `H-229`로 분리** |
| `H-219` | **②** | 1 | 🟡 | (`/code-review high`) 매치 실패 `error(…, 2)`의 도착지가 `drive` 경로(가장 흔한 사용자 경로)에선 사용자 코드가 아니라 quad 내부 프레임 — *"프레임 수가 아니라 도착지가 계약"* 위반. 단 `process`는 핸들러 재귀도 받는 공개 진입점이라 level 하나로 두 경로를 다 못 맞춤 — 증상 확정, 처방(재상승 등)은 새 메커니즘 | ✅ **(a) 사용자 확정**(2026-08-31 회신 2) — 현행 유지 + 한계 명시(`dispatch-core-plan.md` "우선순위 동률/매치 실패 처리" 절), M5 파이프라인 완성 시 재평가 |
| `H-220` | ① | 1 | 🟡 | (`/code-review high`) `BRAND_PROBES`가 상위 술어 `isRef`를 `isPreRef`/`isPostRef`보다 앞에 둬 둘이 도달 불능 — `brand-plan.md`의 술어 합성(`isRef` = PreRef∪PostRef∪RefBrand)이 소스라 specific-first가 답 | ✅ 반영 — 순서 재배열 + "손 복사 목록이라 새 브랜드 마일스톤마다 확장" 주석 |
| `H-221` | ① | 1 | 🟢 | (`/code-review high`) ROADMAP 우선순위 체크박스 주석이 `H-214`를 여전히 "§4 대기·임시 반환"으로 서술 — 같은 커밋에서 종결됐는데 배너가 부정하는 문장을 안 고친 자리 | ✅ 반영 — "(a) 확정으로 닫힘"으로 갱신 |
| `H-222` | **②** | 1 | 🟢 | (`/code-review high`) `H-212` 문단이 *"제공자 계약 위반 → 2"*라는 **계약 표에 없는 제3 분류**를 확정 서술처럼 `base/`에 넣었다 — 표는 "사용자 입력 검증(2)/내부 불변식(1)" 두 행뿐 | ✅ **(a) 사용자 확정**(2026-08-31 회신 2) — `architecture.md` 표에 제3 행("제공자 계약 위반 = 2, 가장 가까운 호출 구조") 신설, `H-212` 문단의 잠정 표시 해제 |
| `H-223` | ① | 1 | 🟢 | (`/code-review high`) retractor 생략 error가 위반 핸들러를 특정할 정보(방금 확정된 `name`·priority·k·index)를 하나도 안 실음 — `h.process` 프레임은 이미 반환돼 어떤 level로도 도달 불가라 메시지가 유일한 단서 | ✅ 반영 — `noRetractorMessage(h, k, index)`(코드+의사코드 동기), 동률 경고도 같은 `describeHandler` 사용 |
| `H-224` | ① | 1 | 🟢 | (`/code-review high`) `H-215`가 M4로 넘긴 잔여 몫 문구가 순서 단언만 요구해, 스파이크 `04`의 존재 이유였던 **효과 수준 검증**(retractor가 실제로 구독을 끊는다)을 떨어뜨림 | ✅ 반영 — ROADMAP M4 mock 항목에 효과 단언(옛 구독 0, stale Set 불전파) 보강 |
| `H-225` | ① | 1 | 🟢 | (`/code-review high`) 세션 파일이 감사 루프를 5라운드에서 멈춘 것처럼 서술(6라운드 수렴·리뷰 반영 미기재) | ✅ 반영 — 세션 파일·summary에 6라운드 수렴과 리뷰 결과까지 기록 |
| `H-226` | 기각 | 1 | 🟢 | (`/code-review high`) `process` (A)/(B) 꼬리 병합·(B) 이중 할당 제거·`retractFrom` 재조회 제거 리팩터 제안 | ❌ 반영 안 함 — 확정 의사코드와의 1:1 유지가 우선이고 실측 병목 아님("실제로 관측된 문제에만 구조"). 메시지 drift 우려는 `H-223`의 공용 `noRetractorMessage`로 소멸 |
| `H-227` | ① | 1 | 🟡 | (`/code-review high`) `local Dispatch = {} :: any`가 생산자 표면을 `quad-types` 선언과 대조 불능으로 만듦 — `H-25`가 막으려던 드리프트가 생산자 쪽에서 무검사 | ✅ 반영 — 로컬 함수 정의 후 `local Dispatch: Dispatch = { … }` 타입 주석 조립(analyze가 표면 검사) |
| `H-228` | ① | 1 | 🟢 | (탐사자) `describeHandler`가 `name` 부재 시 `"?"`를 이름 자리에 찍는다 — `dispatch-core-plan.md` "핸들러 계약" 절의 `H-214` 블록은 *"없으면 priority만 보인다"*. 실측: `handler priority tie between "?" (priority 5) and "?" (priority 5)` | ✅ 반영 — 코드를 문서에 맞춤: 이름 부재 시 `(priority N)`만 |
| `H-229` | **②** | 1 | 🔴 | (사용자 되물음 → 검증 확인) **`H-218`의 누수는 위임 경로만의 문제가 아니다 — 일반 `Destroy` 경로 전체가 같은 패턴으로 샌다.** Destroy 시 retract를 안 부르는 건 계약("오직 같은 key에 새 값" 시나리오만)인데, gchold 섬은 Destroy로 무너져도 **`chains`의 강한 버킷 값이 retractor→`inst`를 별도 루트로 붙잡아** weak 항목이 영영 안 비워진다 — 반응형 바인딩이 하나라도 있던 모든 파괴 인스턴스가 소량 부기+`inst` userdata를 영구 잔존시키고, 죽은 Observer가 상류 State의 전파 순회에 계속 남는다(회당 `canExecute` 스킵 비용) | ✅ **사용자 확정**(2026-08-31 회신 4, *"bindLifetime이 할 일 같은데, 아무 타입과도 일치하지 않으면 단순히 GC 릴레이션만 해주는 건 어때?"*) — `bindLifetime`의 확장 계약(모르는 타입 = 순수 GC 릴레이션, `lifecycle-pattern.md` (0.5) 절 신설) + Dispatch가 리스트 생성 시 `bindLifetime(inst, list)` 앵커, chains는 `SetWeak`. spec 전부 mock Instance 전환 + 13번(Destroy 후 통째 회수) 실측 통과. 분석 상세는 아래 `H-229` 절 |
| `H-230` | **②** | 1 | 🟢 | (사용자 제안) 공유 상수의 배치 — `HANDLER_PRIORITY_*`를 quad-base 밖(백엔드)에서도 의미 있게 쓰려면 `quad-const` 신설 또는 `quad-types` 승격이 필요하다는 제안. ~~error `level` 넘버 Enum화~~는 회신 3의 워커 설계로 **`H-231`에 흡수**(리터럴 전제의 "프레임 수라 Enum 불가" 반론은 워커가 소멸시킴) | ✅ **(a) 사용자 확정**(2026-08-31 회신 5, *"상수 위치는 quad-types에 넣는 거 동의"*) — `HANDLER_PRIORITY_*` 넷 + `ERROR_LEVEL_SURFACE`가 quad-types 반환 테이블로 승격(로직은 여전히 0, 머리말 갱신), `Dispatch`는 require해 재노출(단일 소스) |
| `H-232` | **②** | 2 | 🟡 | **`bk`/체인의 gchold 앵커는 Slot owner에서 성립하지 않는다** — `H-229` 패턴(weak 값 + `bindLifetime` 앵커)을 단위 2가 `bk`에도 적용했는데(observers의 `gatedRecompute`가 `ownerKey`를 캡처해 `H-71` 역참조 — chains와 같은 모양), `bindLifetime`의 첫 인자는 claim 가능한 물리 Instance여야 해서 **Slot을 ownerKey로 쓰는 M6 경로가 그대로는 error**. 단위 2는 inst owner만 커버 | ✅ **(a) 사용자 확정**(2026-08-31 회신 8, *"권고안 확인했고, 괜찮아보임. (slot._bk 로써 bk 순환 문제를 해결하는 부분)"*) — Slot 생성자가 `slot._bk` 강한 사적 필드로 소유, `getBookkeeping`은 owner가 Slot이면 그 필드. `slot-plan.md` 생성자 절·`dispatch-core-plan.md` `H-232` 문단 반영(코드는 M6 몫) |
| `H-233` | ① | 2 | 🟢 | `None` 센티널이 규약 §1에선 단위 3 몫인데 **단위 2가 먼저 요구**한다(`sourceList`의 자리 채움·`setOffsetSource(None)` 얼리 리턴) — 단위 절단이 의존을 놓친 자리 | ✅ `Dispatch/None.luau`에 **값만** 선행 생성(frozen 센티널 + `__tostring`, 최상위 `None` 재export·`Quad.None` 타입) — `NoneHandler`/`NilHandler`는 예정대로 단위 3 |
| `H-234` | ① | 2 | 🟡 | (사용자 발견·결정, 회신 7) `luau_packages`가 rojo 트리·sourcemap에 안 들어가 IDE 타입에러·rojo 빌드 오류 — 근본 원인은 quad-base가 roblox target인 것(*"처음부터 quad-base 자체가 roblox package는 아니라서 luau로 바꿔야 … 어떤 백엔드이더라도 무관히 돌아가니까"*) | ✅ 반영 — quad-base·quad-types target `luau` 전환(build_files 제거, 의존 target 오버라이드 정리), require 전부 `luau_packages/quad_types`로, `default.project.json`이 각 패키지의 `luau_packages` 매핑, `relink.sh` 꼬리에 `rojo sourcemap --output` 재생성(사용자 요청). `rojo build`·전체 테스트 클린. `project-setup-plan.md` `H-234` 문단·`architecture.md` 갱신 |
| `H-235` | ① | 2 | 🟢 | (감사 1라운드, 단위 2 범위) 문서 4곳이 같은 커밋 범위의 결정을 안 따라옴 — `dispatch-core-plan.md` `H-219` 문단이 "M5 재평가"로 열림 유지 / 같은 문서 의사코드 retractor 생략 error 두 줄이 이관 전 리터럴 / `architecture.md` error 계약 예시 첫 줄이 이관 전 형태 / `ui-shorthand-plan.md` `UI-11` 주제문이 15줄 아래 역전과 정반대 | ✅ 전부 반영(같은 커밋) — H-219 조기 해소 표시, 의사코드 `Err.errorBeforeNearest`로 동기, 예시에 개념 예시 주석, UI-11 주제문 취소선+포인터. 의심 1(quad-types-plan "런타임 구현 사실상 없음")도 상수 언급으로 정밀화 |
| `H-236` | ① | 2 | 🟢 | (감사 2라운드) `H-234`/`H-231` 여파 4곳 — `architecture.md` quad-error export 나열이 Nearest 쌍·`new()` 누락 / quad-types 트리 주석에 `quad_error` 의존 누락 / `relink.sh` 머리 예시가 옛 `roblox_packages` 경로 / `project-setup-plan.md` 심볼릭 링크 절의 현재형 지침·`H-165` shim 경로가 옛 디렉토리 | ✅ 반영 — export 나열·의존 주석 갱신, relink 예시 경로 갱신, 심볼릭 링크 절 머리에 `H-234` 경로 배너(히스토리는 보존, 현재형만 갱신) |
| `H-237` | ① | 2 | 🟢 | (감사 3라운드) 셋 — `H-232` 문단의 "배치 Blocker 등도 같은 원칙" 일반화가 사용자 확정 범위(`bk` 하나)를 벗어남(Blocker는 owner 되참조가 없어 분기 대상 아님) / `project-setup-plan.md`의 "의존 대상의" 절이 옛 target 배치를 현재형으로 / "Length/Offset" 절의 "새 함수를 만들 필요 없음"이 `H-232` 분기와 반대 인상 | ✅ 반영 — 일반화를 조건("값이 owner를 되참조하는가")으로 좁힘, 그 절에 `H-234` 배너, Length/Offset 절에 `H-232` 각주. **[감사 4라운드 회귀 정정]** 3라운드가 그 배너를 볼드 태그 **안**에 밀어넣어 태그가 80자를 넘겨 절이 통째로 인용 불가가 됐었다(doc-check ERROR) — 태그를 짧게 되돌리고 설명은 본문으로, 이 행의 인용도 실제 제목으로 교정 |
| `H-238` | ① | 2 | 🟡 | (`/code-review high`) mock 백엔드가 설치한 생명주기 4종+`onDestroying`을 공유 에러 네임스페이스에 태그하지 않음 — `LifetimeHandle.luau` 계약("백엔드가 자기 교체분을 태그") 위반, 그 경로 아래 `errorBeforeNearest`의 blame이 엉뚱한 프레임으로 | ✅ 반영 — `installLifetime` 꼬리에서 5종 태깅(quad-roblox도 M5에서 같은 의무) |
| `H-239` | ① | 2 | 🟢 | (`/code-review high`) `spec.lengthoffset` 4번의 "final recompute wrote nothing extra" 단언이 vacuous — 프로브를 drive 종료 **후**에 달아 카운터가 0일 수밖에 없었다 | ✅ 반영 — 프로브를 핸들러 안(등록 전)에 설치, 배치 전 과정에서 Source당 Set 정확히 1회를 실단언 |
| `H-240` | **②** | 2 | 🔴 | (`/code-review high`, **CONFIRMED**) `recompute`의 무조건 커서 쓰기가 **`Get` 창에서 올라온 되감기 신호를 지운다** — 되감기 검사는 `offset:Set` 자리만 가드하는데, 길이가 Compute State면 `getOffsetAt`/`sum += :Get()`의 재계산 중 사용자 코드가 같은 owner를 낮출 수 있고, 그 신호가 다음 줄 `offsetSetUpTo = i`·꼬리 `= bk.N`·`getOffsetAt` 꼬리 `= at`에 덮인다 — 두 커서 분리(`H-124`)가 막으려던 그 실패 부류. 확정 의사코드 자체의 갭이라 자율 수정 불가 | ✅ [2026-09-01 확정 — 분석 답변 후 *"H240 도 이해해서 수행하면 될것 같아"*] 쓰기 직전 검사 셋(진입 스냅샷 ①/기존/② — ②는 뮤테이션 실측으로 load-bearing 확인) + `getOffsetAt` 자가 치유(증분 커서·재시작), 인지된 UB 경계(자기 자리 mid-read 교체) 문서화. `spec.lengthoffset` 10이 원 재현을 회귀로 고정 |
| `H-241` | **②** | 2 | 🟡 | (`/code-review high`, PLAUSIBLE) `drive`가 owner당 Blocker 하나를 배치마다 재사용 — 같은 inst에 재진입 drive가 오면 안쪽 `OffWithoutEmit()`이 바깥 배치를 조기 개방(O(N²)). `Blocker` 문서의 "네스팅 미지원, 겹치면 새로 만들 것"과 긴장. 단 재진입 drive는 정상 API로 만들기 어렵고 크래시는 아님 | ✅ [2026-09-01 (a) 확정] UB 문서화 — `dispatch-core-plan.md` 두 UB 문단 + `blocker-plan.md` 각주 |
| `H-242` | ① | 2 | 🟢 | (`/code-review high`) SURFACE 태깅이 9개 모듈의 손 목록 — Dispatch 것은 15줄 위 테이블을 문자 그대로 재열거, 누락은 조용한 blame 저하 | ✅ 반영 — Dispatch는 조립된 테이블 자체를 순회(함수 값만). 각 모듈의 소규모 목록은 유지(지역적·소량) |
| `H-243` | ① | 2 | 🟡 | (`/code-review high`) `H-234`의 외부 소비자 갭 — 표준 pesde-Roblox 스캐폴딩은 `roblox_packages`만 매핑하므로 luau target인 quad-base/quad-types가 외부 소비 시 트리에서 빠질 수 있음(지금은 레포 내 손 매핑이라 무증상, M5 이후 게시 시점에 드러남) | ✅ 문서화 — `project-setup-plan.md` `H-234` 문단에 게시 시점 숙제로 명시 |
| `H-244` | ① | 2 | 🟢 | (`/code-review high`) `recompute`의 길이 강제가 `contribution()`과 인라인 사본 둘 — M6에서 강제에 케이스가 늘면 Length와 offset이 갈라질 드리프트 채널 | ✅ 반영 — 코드·의사코드 둘 다 `contribution(bk, i)` 하나로 |
| `H-245` | ① | 2 | 🟢 | (`/code-review high`) `H-231` 이관에서 살아남은 손 세기 시절 주석들("-- 3: past Compute…", "Level 3: …") — 이 코퍼스에선 주석이 설계 참조라 다음 편집자가 손 세기 계약으로 오독 | ✅ 반영 — State/Observer/Effect 다섯 자리를 워커 서술로 |
| `H-246` | ① | 2 | 🟡 | (`/code-review high`) 이 구간의 사용자 확정 여덟(`H-218`~`H-234`)이 round12 §4 셀에만 있고 `session/` 원문이 없음 — `conventions.md`의 세션 원문 규율 위반 | ✅ 반영 — `session/2026-08-31-02-*`에 단위 2·회신 4~8 절 증보, summary 갱신 |
| `H-247` | ① | 2 | 🟢 | (`/code-review high`) `158c354`가 doc-check ERROR를 품은 채 커밋됨(같은 커밋 안의 두 편집 사이에만 검사를 돌렸음) — 매 커밋 ERROR 0 게이트 위반, 다음 커밋(`0f59de4`)이 정정 | ✅ 기록 — 재발 방지 습관: doc-check는 **스테이징 직전** 마지막 편집 후에 1회 더 |
| `H-253` | ① | 3 | 🟢 | (단위 3 구현) 코드 배치 둘 — `Dispatch/None.luau`의 반환이 센티널 단일값에서 `{ None, register }` 테이블로(핸들러 둘이 인스턴스별 `dispatch`를 클로저로 받아야 해서 — `H-174` 팩토리형과 같은 이유, `InitDispatch` 꼬리가 `register(Dispatch)` 호출) / 내장 둘이 항상 선등록되면서 `spec.dispatch` 11번의 개수·순서 단언을 내장 감안형으로 조정(동률 간 순서는 계약상 미정이라 상대 순서만 단언) | ✅ 반영 — 우선순위는 둘 다 `HANDLER_PRIORITY_HIGH`(문서의 "매우 높음" 그대로; 술어가 안 겹쳐 동률 무해, debug 동률 경고는 알려진 출력) |
| `H-254` | ① | 3 | 🟢 | (감사 1라운드, 단위 3 범위) 넷 — brief §1의 "탑레벨 `None.luau` 트리 줄 추가" 예고가 `H-253` 실물과 어긋남(옛 예고가 `slot-plan.md` 재노출 선례와 애초에 어긋났던 것) / ROADMAP의 "M3 구현 시 트리도 같이 채울 것" 미이행 지시문이 배너와 모순 / 스파이크 `03` 처분 미판정(spec들이 절반 대체 — M4에서 `04` 잔여와 함께) / `spec.dispatch` 11번의 내장 총 개수 하드코딩(단위 4에 깨질 자리) | ✅ 반영 — 브리프·ROADMAP 정정, STATUS 03 판정 메모, 개수 단언 제거, 세션 파일 단위 3 절 증보 |
| `H-255` | ① | 3 | 🟢 | (`/code-review high`, 소급) `b872b6e`(감사 2라운드 반영 — spec 11 단언 검출력 복원, STATUS 03 문구 분리)가 규약 §2의 ① 원장 기록 없이 커밋됨 — 부수로 `H-254` 셀의 "✅ 개수 단언 제거"는 그 교정이 결함(vacuous)이라 한 커밋 뒤 고쳐진 사실을 안 담고 있었다 | ✅ 이 행이 소급 기록 — `H-254`의 개수 단언 제거 1차본은 vacuous였고(`#listed >= 3` — ours만으로 항상 참) `b872b6e`가 `#listed > #ours`로 교정, 이후 `H-260`이 이름 검출로 재강화 |
| `H-256` | **②** | 3 | 🔴 | (`/code-review high`, 런타임 재현) `NilHandler`의 `type(k) == "number"` 술어가 **희소·소수·음수 키를 부기 산술에 들여보낸다** — `drive(inst, {[3] = None})`이면 `bk.N = 3`인데 `sourceList[1..2]`가 미등록이라 `recompute`가 level 1 error로 죽고, 그 자리가 `recomputeBlocker:On()`과 `Off` 사이라 **그 owner의 offset 산술이 영구 동결**(이후 setLength가 아무것도 안 움직임 — 재현 확인). `[1.5]`도 같은 크래시, `[-1]`은 `offsetCacheValidUpTo = -1` 오염 후 익명 산술 에러. 단위 3 전엔 같은 입력이 깨끗한 매치 실패 error였다 — 항상 등록된 NilHandler가 이 입력을 부기로 라우팅하게 된 것. 가드는 새 검증 로직이라 자율 반영 불가 | ✅ [2026-09-01 (a) 확정 — *">0 %1==0 확인은 비싸지 않아"*] `checkPosition` 게이트(코드+의사코드), `spec.lengthoffset` 9 |
| `H-257` | ① | 3 | 🟢 | (`/code-review high`) 해시 키 `None`이 그 키를 받을 핸들러가 없으면 `value: nil`로 에러 — `NoneHandler` 재귀가 출처를 지워, 사용자가 안 쓴 값(nil)을 썼다고 말한다(None의 존재 이유가 바로 그 구별인데) | ✅ 반영 — 매치 실패 메시지에 nil 한정 힌트("이 깊이의 nil은 벗겨진 None이거나 반응형 nil일 수 있음 — 그 키의 핸들러가 nil을 받아야") |
| `H-258` | **②** | 3 | 🟡 | (`/code-review high`) `NoneHandler`가 nil을 최초의 "디스패치되는 값"으로 만들면서 retractor 계약의 두 신호 — 인자 nil = 단순 철거 vs 인자 = 재처리될 새 값 — 가 **nil 값 자리에서 구별 불능**이 됐다. 지금은 nil 수용 핸들러가 전부 Void 반환이라 무증상이지만, M4/M9 핸들러(Property 복원, Event nil-disconnect)가 문서 계약대로 짜이면 None 재발행마다 전량 철거+재마운트 churn(또는 오동작) | ✅ [2026-09-01 **사용자 설계로 확정** — 권고 (a) 대신 (b) 계열] retractor **2번째 인자 `retracting: boolean`**(retractFrom 경유=true / (A) 재처리=false — quad-types 계약·코드·의사코드·`spec.dispatch` 14) |
| `H-259` | ① | 3 | 🟢 | (`/code-review high`) `register(dispatch: any)` — 레포의 유일한 실핸들러 둘이 유일하게 무타입(H-227이 닫은 생산자 드리프트 구멍의 재개방) | ✅ 반영 — `dispatch: QuadTypes.Dispatch`로(리터럴은 addHandler 문맥 타이핑이 검사) |
| `H-260` | ① | 3 | 🟢 | (`/code-review high`) spec 11 둘 — name 단언이 로컬 테이블을 다시 읽어 vacuous / `#listed > #ours`는 내장 하나만 있어도 통과(None 쌍 절반 삭제를 못 잡음) | ✅ 반영 — name 단언을 `ours[i]`(반환 목록 원소) 경유로, 쌍 검출을 이름 스캔(`NoneHandler`·`NilHandler` 둘 다)으로 |
| `H-261` | ① | 3 | 🟢 | (`/code-review high`) `newQuad()`가 세 spec에 바이트 동일 복사 — `H-206` 선례(3벌 복사 = 추출 트리거), install 표면의 소유자는 mock | ✅ 반영 — `mock.newQuad` 신설, 세 spec이 참조 |
| `H-262` | ① | 3 | 🟢 | (`/code-review high`) spec 11 주석 "내장 둘은 HIGH라"가 산문으로 내장 개수를 하드코딩(방금 기계 검사를 없앤 자리 옆에서) | ✅ 반영 — 개수 안 세는 문구로(원장 행들의 "둘"은 단위 3 시점 기록이라 유지) |
| `H-263` | ① | 3 | 🟢 | (`/code-review high`) `spec.nonenil` 3·4번의 SpecLeaf가 근사 복사 — leaf 등록 계약이 drift 가능한 두 자리에 | ✅ 반영 — 공용 `addSpecLeaf(q, sources, log?)` 팩토리 |
| `H-231` | **②** | 1 | 🟡 | (사용자 설계, 회신 3) **error 유틸 모듈** — `setLevel(fn, tag)` 등록 맵 + `debug.info(i, "f")` 스택 워커로 "원하는 계층까지 올려서" error를 내는 유틸(type-version-check처럼 독립 패키지). 프레임 수 손 세기(2·3 갈림, `H-219`의 drive 도착지 한계, `H-212` 스텁 level 미정)가 전부 자연 해소되고 level이 진짜 의미 Enum이 된다. 에러는 cold path라 `debug.info` 비용 무시 가능(사용자 논거, 동의) | ✅ 설계 확정(2026-08-31 회신 4, *"에러 유틸은 error-util-ignoreme.luau를 보면 될 것 같아"* — 실험 파일이 워커 방향(최상단 하강)·API(`setFuncLevel`/`getFirstMatch`/`errorAt`/`errorBefore`/`ERROR_LEVEL_DEFAULT`)·프레임 산술까지 확정) — **`quad-error` 워크스페이스 패키지로 구현**(이름은 가칭 통보 — 게시 전 개명 쌈), `spec.errorutil` 5절 실측 통과(실험 파일의 단언 + weak 맵 + 샌드위치 강건성). 잔여였던 태그 체계·이관은 회신 5·6으로 종결(§4 "H-231 잔여" 행) |
| `H-248` | ① | 2 | 🟢 | (탐사자) `mock.luau`의 생명주기 5종 태깅 루프 주석이 `H-239`를 인용 — 그 수정의 발견 번호는 **`H-238`**이다(`H-239`는 `spec.lengthoffset` 4번의 vacuous 프로브). 이 코퍼스에선 주석이 설계 참조라 grep이 엉뚱한 발견에 닿는다 | ✅ 반영 — 주석 번호 `H-238`로 교정 |
| `H-249` | ① | 2 | 🟢 | (탐사자) `H-245`(손 세기 시절 주석 정리)가 놓친 두 자리 — `Store.luau` 헤더의 *"Both are user input → `error(..., 2)`, English"*와 `Effect.luau` `isRunning` 옆 *"`error` stays in each body (level 2)"*. 두 경로의 실제 raise는 이미 `errorBeforeNearest(..., SURFACE)`인데 주석만 이관 전 리터럴 계약을 서술 | ✅ 반영 — 두 주석을 워커 서술로 |
| `H-250` | **②** | 2 | 🟢 | (탐사자) `H-231` 절이 *"추론으로 확정하지 않는다"*로 명시한 선행 스파이크 셋 중 **(c) 프레임 산술만** `spec.errorutil`로 닫혔다(luau CLI 기본 O1에서) — **(a) `-O2` 인라이닝·네이티브 코드젠에서의 `debug.info` 프레임 가시성, (b) 코루틴 경계**는 실측도 명시 기각 기록도 없이 넘어갔다. 실패 모드는 크래시가 아니라 blame 열화(태그 프레임이 안 보이면 워커가 한 겹 밖/raise 자리로 폴백). 실측/기각은 사용자 판단이라 ② | ✅ [2026-09-01 (a) 확정] 스파이크 `27` 신설, 4플래그 조합 실측 ALL PASS — **발견 하나**: 로컬 직접 호출 태그 함수는 `-O2` 인라인으로 태그 소실(테이블 경유 규칙 명문화, `STATUS.md` 27 행·`architecture.md`) |
| `H-251` | ① | 2 | 🟢 | (탐사자) `spec.drive.luau` 헤더가 *"M3 unit-1 scope: pipeline stage (b) only"*로 stale — 단위 2가 `drive`에 ⓪/⓪' 배치 게이팅을 배선했다(`Dispatch/init.luau` 헤더는 갱신됨). 부수로 그 spec-로컬 핸들러는 배열 자리의 `setLength`/`setOffsetSource` 등록 계약(생략 UB)을 안 지킨 채 `drive`를 태운다 — F-4-1 측정 목적이라 무해하지만(빈 `bk`로 `recompute`가 no-op) 의도임을 주석으로 밝힐 자리 | ✅ 반영 — 헤더를 ⓪(b)⓪' 현행으로 + 등록 생략이 의도(순회 측정 전용)임을 명시 |
| `H-252` | ① | 2 | 🟢 | (탐사자) `test.sh`의 `luau-analyze` 대상에 단위 2가 신설한 **`quad-error/src`가 없다**(require 경유 트랜지티브 타입만 읽힘) — 그 스크립트 자신의 주석이 "거짓 클린이 없다"를 목적으로 말하는 자리인데, 새 런타임 패키지의 strict 진단이 게이트 밖이다. `quad-types/src`도 같은 상태(전부터). 지금 직접 돌리면 둘 다 클린(실측 — `luau-analyze quad-error/src`·`quad-types/src` 각각 무출력 exit 0) | ✅ 반영 — `test.sh` analyze 대상에 `quad-types/src`·`quad-error/src` 추가(전체 그린 재확인) |
| `H-264` | ① | 3 | 🟢 | (탐사자) `H-257`의 nil 한정 힌트가 **코드에만 있다** — 정본 `dispatch-core-plan.md` "우선순위 동률/매치 실패 처리" 절은 여전히 *"그 이상의 특수 분기는 두지 않음"*이라 그 커밋(`4c01be2`)이 넣은 nil 조건 분기 문구를 정면 부정한다(그 커밋은 `base/` 파일을 하나도 안 건드림 — ①의 "`base/`+코드 같은 커밋" 규약이 안 지켜진 자리) | ✅ 반영 — 매치 실패 절에 `H-257` 예외 명시(분기 로직 아닌 진단 문구 보강) |
| `H-277` | ② | 회신 | 🟡 | (사용자 제기) **Dispatch가 두 일을 한다** — process/handler 대응이 본령인데 Length/Offset 부기(setLength/setOffsetSource/getOffsetAt/getBookkeeping)가 같이 껴 있고, M6에서 Slot이 엮이면 복잡해진다. 사용자 제안: `{Slot, Dispatch} → Bookkeeping` 의존 방향의 서브시스템 분리(*"당장 잘 작동하나 … 분리처리가 나아보이는데"*) | ✅ [2026-09-01 확정 — *"확인했어"*] `src/Bookkeeping.luau` 신설(`InitBookkeeping(module)` → 사적 `module._bookkeeping`), 공개 호출 표면은 `quad.Dispatch.*` 유지(같은 함수 객체 재노출) — `dispatch-core-plan.md` "Length/Offset" 절 배너·`architecture.md` 트리 행이 정본 |
| `H-278` | ② | 회신 | 🟡 | (사용자 제기) **Leaf.luau가 Observer/Effect를 안다** — 각 객체를 아는 곳은 각 객체가 선언된 곳이라는 원칙 위반. 제안: `Observer.luau`/`Effect.luau`가 자기 `Init`에서 Dispatch를 받아 `addHandler`(*"각 객체의 Observer.luau 등지에서 … addHandler 하는게 맞다고 보는데"*) | ✅ [2026-09-01 확정 — *"확인했어"*, 2026-08-08 배치 확정 역전] `Dispatch/Leaf.luau` 해체 — `Observer.luau`/`Effect.luau`의 `registerDispatchHandlers`가 자기 Init에서 leaf+가드 등록(결합 핸들러가 `ObserverLeafHandler`/`EffectLeafHandler` 둘로 — 값 공간 배타라 동등, dedup relate 각자), M8 Ref 몫은 `Ref.luau`로 예약. Init 순서는 RunInit 멱등 당김(`H-174` 관용구)으로 해결 |
| `H-279` | 리서치 | 회신 | 🟢 | (사용자 제기) **drive pre-hook** — `Processed*`로 바꾸고 처리하는 요소가 많아 drive가 서브시스템들을 알게 되는 결합 문제. 사용자 지시: *"이건 단순 리서치 요소로 두어요"* | ✅ `research/drive-hook-plan.md` 신설(아이디어 단계, M8 전 재론) |
| `H-272` | ① | 4 | 🟡 | (탐사자 F-1) 이중 배치 designed error의 blame이 quad 내부(`Leaf.luau:60`)에 떨어짐 — 단위 4로 `bindLifetime`의 주 호출부가 디스패치 깊이가 되면서 리터럴 level 2가 어긋남(`H-231` 일괄 이관이 백엔드 교체 함수를 못 본 사각; `lifecycle-pattern.md` 스케치엔 한국어 리터럴도 잔존 — `H-216` 부류) | ✅ 반영 — mock `bindLifetime`/`onDestroying`의 오용 error 셋과 스케치를 `errorBefore(…, SURFACE)`로(직접 호출·디스패치 경유 양쪽에서 사용자 blame — 논증은 스케치 주석), `spec.leaf` 8 신설 + `spec.lifetime` 단언 명의 갱신 |
| `H-273` | ① | 4 | 🟡 | (탐사자 F-2) `pcall(q.Dispatch.drive, …)` **직전달**이면 outermost 목표가 C 프레임에 얹혀 파일:줄 접두가 통째로 사라짐(메시지는 생존; 태그 프레임이 최상단일 때 `+1`도 같은 결과 — 크래시 없음, 실측) | ✅ 반영 — 알려진 한계로 문서화(`quad-error` 헤더 Known limits + `architecture.md` error 계약 절), 방어선은 `H-219` (a)의 "메시지 자기설명" 논거. 메커니즘 안 만듦 |
| `H-274` | ① | 4 | 🟡 | (탐사자 F-3) 재진입 진입(observer `fn` 안 `drive`)에서 매치 실패의 최외곽 스캔이 실수 자리(안쪽 호출)가 아니라 **바깥 진입 줄**(`s:Set`)을 blame — 확정 방향(최외곽)의 내재 한계, `H-231` 회신의 Nearest 배정은 재진입 가드만 다뤘음 | ✅ 반영 — 같은 두 자리에 한계로 문서화(안쪽 지목이 필요한 자리는 Nearest 쌍의 몫). 메커니즘 안 만듦 |
| `H-275` | ② | 4 | 🟡 | (탐사자 F-4) **형상이 바뀌는 배열 재`drive`의 지원 여부가 미명시** — 축소(`{o1,o2,o3}`→`{o1,o2}`)는 자리 3을 아무도 철거 안 해 조용한 잔존(o3 발화 지속, `bk.N=3`), 교환(`{oA,oB}`→`{oB,oA}`)은 (A) 분기가 아직 자리 2에 묶인 oB를 bind하다 already-bound 크래시 + slot 1 `H-103` NOOP 잔존. 같은 형상 재drive는 sanctioned(spec.leaf 3), 재진입 drive는 `H-241`로 별도 — 이건 **순차 재호출** 축 | §4 — 권고 (a) |
| `H-276` | ① | 4 | 🟢 | (탐사자 F-5) `spec.leaf` 5의 "NilHandler re-registered" 단언이 vacuous — NilHandler 등록 제거 뮤테이션에도 통과(leaf 잔존값과 동일해 구별 불능; 실회귀는 `spec.nonenil` 3이 잡음) | ✅ 반영 — 단언 명의를 "자리가 등록된 채 남는다"로 정정 + 커버리지 소재 주석 |
| `H-269` | ① | 4 | 🟡 | (리뷰) quad-error no-match 폴백 `error(content, 1)`이 헤더 계약(*"No match falls back to the raise site"*)과 달리 `errorAt`/`errorAtNearest` **자신의 줄**(quad-error 내부)을 blame — `errorBefore` 쌍만 `+1` 덕에 우연히 맞았다 | ✅ 반영 — 네 wrapper가 센티널(1)을 raise 자리(level 2)로 번역, `spec.errorutil` 4에 "quad-error를 blame하지 않는다" 단언 추가 |
| `H-270` | ① | 4 | 🟡 | (리뷰) `getFirstMatch`의 스캔 시작이 진짜 최상단보다 1 위 — `getToplevel`이 자기 프레임이 살아있는 관점으로 세므로, 첫 프로브가 항상 유령 nil 프레임이고 `getFuncLevel(nil) == 0`이라 **layer 0(`ERROR_LEVEL_DEFAULT`) 요청이 유령 프레임에 오매치**(현재 유일 사용 태그 SURFACE=1엔 무해한 잠복 엣지) | ✅ 반영 — 시작을 `getToplevel() - 1`로(관점 시프트 주석), `spec.errorutil` 4에 layer 0 실프레임 매치 단언 |
| `H-271` | ① | 4 | 🟢 | (리뷰) 같은 diff가 닫은 드리프트 채널 둘이 곧바로 재개방 — `spec.drive`가 `H-261`이 접은 `Quad.New()`+`installLifetime` 쌍을 인라인 유지 / `spec.integration`의 `SpecElement`가 `H-263`이 접은 leaf 등록 본문의 세 번째 사본 | ✅ 반영 — `addSpecLeaf`를 mock으로 승격(공유 헬퍼 소유자, `H-261` 근거 재사용), `spec.drive`는 `mock.newQuad`로. `spec.lengthoffset` 4의 프로브 변형은 프로브 자체가 테스트 대상이라 잔류 |
| `H-268` | ① | 4 | 🟢 | (감사 2라운드) `H-266`의 마지막 미전파 — `.claude/README.md` 색인의 두 행(`source-state-plan.md` 행 *"성능 최적화, correctness엔 불필요"* / `dispatch-core-plan.md` 행 *"dedup 채택(성능 최적화)"*)이 정확히 `H-266`이 뒤집은 문장 그대로; 부수로 bare `Err`/`SURFACE` 표기가 정의 포인터 없이 세 문서로 확장된 것(기존 관례이긴 함) | ✅ 반영 — 두 색인 행에 load-bearing 승격 표시, 세 문서 첫 사용 자리에 `architecture.md` "error 계약" 절 포인터 |
| `H-267` | ① | 4 | 🟢 | (감사 1라운드) 단위 4 diff의 미전파 다섯 — `ref-plan.md` RefLeafHandler SetWeak 주석의 *"순수 성능 최적화라 … 한 번 놓침"*이 `H-266`과 모순(같은 canBound 가드라 Ref도 동일하게 load-bearing) / `source-state-plan.md` dedup 절이 배너만 달리고 절 제목·의사코드 주석·SetWeak 문단이 옛 프레이밍 그대로(배너가 부정하는 문장을 같은 커밋에서 안 고친 전형) / 가드 등록 "M3에서 미룬다" 미래형 서술 둘(`source-state-plan.md`·`effect-plan.md`)이 완료 미반영 / ROADMAP `Dispatch/Leaf.luau` 체크박스가 무주석 `[ ]`라 "파일이 아직 없다"로 오독 여지 / 가드 의사코드 넷이 이관 전 리터럴 `error(...)`(`H-249` 부류 잔존 — PreRef/PostRef 포함) | ✅ 반영 — 정정 배너·완료 표시·`[ ]` 유지 주석·`Err.errorBefore(…, SURFACE)` 갱신. SetWeak 안전성의 실근거(미스 창 부재 — bound 동안 gchold 강참조)를 두 문서에 명문화 |
| `H-266` | ① | 4 | 🟢 | Leaf dedup의 채택 근거(*"correctness 문제는 아님 — `old ~= v`를 안 넣어도 안 깨짐"*, 2026-08-14)가 현행 계약과 모순 — 이후 확정된 `bindLifetime`의 `canBound` 가드(이중 배치 방지, 재바인드 즉시 error)와 바인드 부수효과(Observer `_catchUp`/Effect `_bindDestroying` 실제 `Destroying` 연결) 때문에 retractor만 dedup하고 process 쪽을 빼면 (A) spurious 재발행이 크래시한다 — dedup은 순수 성능 최적화가 아니라 load-bearing | ✅ 반영 — 결론(dedup 유지)은 그대로, 근거만 승격: `source-state-plan.md` dedup 절에 정정 배너, `dispatch-core-plan.md` 체크리스트 4번 요약 갱신. `spec.leaf.luau` 3이 "통과 자체가 dedup의 증거"로 실측 |
| `H-265` | ① | 3 | 🟢 | (탐사자) None 쌍의 분업·배치 서술이 어긋난 자리 셋 — `dispatch-core-plan.md` "Length/Offset" 절 `setLength` 의사코드 주석의 *"길이가 상수인 자리(`NilHandler`/`NoneHandler`의 `0`)"*(NoneHandler는 등록을 안 한다 — 재귀만) / `source-state-plan.md` "세 번째 카테고리" 절의 *"`Dispatch/StoreBind.luau`의 `NoneHandler`"*(실물 배치는 `Dispatch/None.luau` — `H-253`·`architecture.md` 트리) / ROADMAP 단위 3 체크박스의 `setLength(0)` + `setOffsetSource(None)` 나열 순서(계약 순서와 반대로 읽힘 — 상세 절 참고) | ✅ 반영 — `NilHandler`만으로 정정 둘(`dispatch-core-plan.md` 두 자리), `Dispatch/None.luau` 소속 정정(`source-state-plan.md`), ROADMAP 나열 순서를 해제 계약대로 |

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

### `H-228` — 진단 라벨의 이름 부재 표기가 문서와 다르다 (①, 탐사자)

`Dispatch/init.luau`의 `describeHandler(h)`는 `` `"{h.name or "?"}" (priority {h.priority})` ``
— `name`이 없으면 `"?"`라는 자리표시자를 이름처럼 찍는다. 그런데
`dispatch-core-plan.md` "핸들러 계약" 절의 `H-214` 확정 블록은 **"없으면
priority만 보인다"** — 문서가 이미 답을 가진 자리라 ①이다(동률 경고와
`H-223`의 retractor 생략 메시지 양쪽이 이 라벨을 쓴다). 실측(무이름 동률
경고, 탐사자 프로브):

```
quad.Dispatch: handler priority tie between "?" (priority 5) and "?" (priority 5) — ties have no defined order; offset from a HANDLER_PRIORITY_* band
```

수정은 메인 세션 몫(탐사자는 round12.md만 편집) — 코드가 문서를 따라
이름 부분을 생략하든(`(priority 5)`만), 문서에 자리표시자 표기를 명시하든
어느 쪽이든 한 줄이다. 순수 진단 문자열이라 계약·부기 영향 없음.

### `H-229` — Destroy 경로 검증: 사용자 되물음이 맞았다 (②, 🔴)

사용자 되물음(2026-08-31): *"핸들러가 자식을 버릴 때 Destroy가 호출되어
bind들이 자동으로 끊어지고 gchold가 사라질 수 있었다는 건데 … 그냥 Destroy
호출되는 것도 retract가 안 먹어서 문제가 생긴다는 부분 아냐?"*

**검증 결과: 맞다.** 경로를 끝까지 따라가면:

1. `inst:Destroy()` — 엔진이 커넥션을 끊는다. gcconn 클로저↔gchold 상호
   참조 섬은 이 절단으로 무너지고(`lifecycle-pattern.md` (0)의 *"Destroy가
   유일한 절단면"*), gchold가 강하게 쥐던 바인딩 값들이 풀린다. **여기까지는
   설계대로.**
2. 그런데 `chains`는 **두 번째 강한 루트**다 — `buckets[inst(weak)] =
   bucket(강)` 이고 bucket → 리스트 → retractor 클로저 → `inst`(캡처).
   Luau에 ephemeron이 없으므로 "값이 자기 weak 키를 되참조"하는 이 항목은
   **영영 안 비워진다**(`H-71` 실측 패턴 그대로). Destroy가 끊는 것은 엔진
   쪽 참조뿐이고 이 루트는 안 건드린다.
3. Destroy 시 retract를 안 부르는 건 계약이라(*"오직 같은 key에 새 값이
   들어와서 이전 처리를 갈아치우는 시나리오에만"*) 아무도 `list[i] = nil`을
   해주지 않는다 — 즉 **반응형 바인딩이 하나라도 있던(= retractor나 그
   Observer가 `inst`를 캡처한) 모든 파괴 인스턴스**의 버킷·retractor·
   Observer·`inst` userdata가 모듈 `chains`에 영구 잔존한다.
4. 부수 비용: 잔존 Observer는 상류 State의 weak 구독 집합에 살아 있어(강한
   경로가 chains에 있으므로 weak라도 안 걷힘) 상류 emit마다 전파 루프가
   그것들을 방문해 `canExecute` false로 스킵한다 — 메모리에 더해 **전파
   비용이 파괴 누적에 비례해 자란다.**

`H-218` (a)의 의무화가 닫는 것은 **위임 경로**뿐이다(retractFrom 호출 후엔
리스트가 비어 버킷 값이 `inst`를 안 잡으므로 weak 항목이 정상 회수된다).
최상위 인스턴스·Slot 요소처럼 **retract 없이 Destroy로만 죽는 일반 경로**가
이 항목이고, 처방 선택지는 §4 표. 정적 값만 있는 인스턴스는 retractor가
전부 `Void`(캡처 없음)라 새지 않는다 — 새는 것은 반응형 바인딩이 있던
것들이다.

**[2026-08-31 회신 3 — 사용자 별해 검토]** 사용자 제안: *"retract 클로저가
inst를 받으면 될 것 같다는 느낌. retractFrom이나 process에서 이미 inst를
알고 … 온디맨드로 넘겨줄 수 있어. 그러면 retract 자체가 업밸류를 캐치하지
않게 돼"* + 스스로 단 캐비엇: *"어떤 방식으로든 실수가 나게 된다면 Strong
이라서 gc가 안 되는 사고가 날 수 있게 되어 후자(gchold 앵커)를 제공하는 게
안전해보이기는 해"*. **검토 결과 — 인자 전달만으로는 경로가 안 끊긴다**:
retractor가 `inst`를 직접 캡처하지 않아도, StoreBind류 retractor는 자기
Observer를 캡처해야 하고(구독 해제 대상) 그 **Observer의 콜백이 재디스패치를
위해 `inst`를 캡처**한다 — chains → retractor → observer → fn → `inst`
경로가 그대로 남는다. 이걸 끝까지 끊으려면 핸들러 상태를 클로저 밖(weak
셀/Relate 조회)으로 밀어내야 하는데, 그건 확정 설계("단발성 handoff는
upvalue 캡처로 충분" — 옛 `kSlotMap` 삭제, Handler 작성 체크리스트 4번)의
역전이고, **불변식이 모든 핸들러 작성자(서드파티 포함)에게 분산**되며
위반의 증상이 조용한 영구 누수다. gchold 앵커((a))는 캡처 인체공학을
그대로 두고 불변식을 **Dispatch 안의 한 줄**에 중앙화한다 — 사용자의 안전
직감과 같은 결론.

### `H-231` — error 유틸 모듈: 스택 워커로 level 손 세기를 없앤다 (②, 사용자 설계)

사용자 설계(회신 3): *"error 자체를 모듈로써 제공 … `debug.info(2, "f")`를
하면 각 프레임에 대한 함수를 구할 수 있어. 간단하게 함수를 태그해주는 맵만
있다면 에러를 원하는 레벨까지 낮춰서 내준다를 지금처럼 어렵게 세어 가며 처리
안 해도 되고, 여러 래퍼가 들어가도 사용자 지점까지 확실히 올려낼 수 있어 …
type-version-check와 유사하게 외부에 유틸을 파. `setLevel(fn, num)` … 등록 안
된 함수는 level 0 … 그러면 num을 Enum으로 둘 수 있고, 우리가 한계라고 했던
부분이 해소돼"* + 유의점(추가 회신): *"클로저로 입력 받은 것도 입력 받은
측에서 level을 설정해야 할 수도 있어 … (안 그럼 중간에 짤릴 수도 있으니까)
아니면 최상단부터 구한 다음, 거기서 진입하는 게 옳을 수도 있어"*.

**평가 — 채택 권고.** 이 유틸이 있으면: `H-219`의 drive 도착지 한계(현행
유지로 닫았던 것)가 근본 해소되고, `H-212`가 "구현 시점 몫"으로 미룬 주입 op
스텁 level도 답이 생기며, `H-205`류 "헬퍼 프레임 하나에 2→3" 손 세기가
사라진다. 에러는 cold path라 비용 논거도 맞다. 사용자가 짚은 "중간에 짤림"이
정확히 급소다 — 세부 선택지:

- **워커 방향** — **(i) 최상단 하강(권고, 사용자 후자 제안)**: 스택 최상단
  (사용자 루트)에서 내려오다 **처음 만나는 등록(quad) 프레임의 직전**에서
  낸다. 등록이 필요한 건 quad의 정적 표면 + `addHandler`/주입 시점에 받는
  제공자 클로저뿐(1회성) — 런타임에 생기는 익명 클로저(retractor, observer
  콜백)는 경계 아래라 애초에 검사 안 되므로 "중간에 짤림"이 구조적으로 없다.
  blame은 항상 "quad로 들어온 최상위 진입점의 호출부"(drive면 `New` 호출부,
  전파면 `:Set` 호출부) — 일관되고 안전. /
  (ii) 에러 지점 상승(첫 미등록 프레임에 blame): 샌드위치된 사용자
  콜백까지 정밀 blame되지만, quad가 **만들거나 받는 모든** 클로저(retractor
  포함 — 매 `process`마다 생성되는 핫패스!)를 등록해야 하고 누락 하나가
  내부 클로저를 사용자로 오인시킨다. 정밀도 이득 대비 규율 표면이 너무 넓다.
- **배치** — type-version-check처럼 **독립 워크스페이스 패키지**(가칭
  `quad-error`): 백엔드(EngineOps 스텁·핸들러)도 써야 하는데 그쪽은
  quad-base를 의존하지 않는다. 이름은 사용자 확정 대상.
- **Enum 구성** — `H-222`의 표와 1:1로: 예) `Level.User`(사용자 호출부까지) /
  `Level.Provider`(제공자 계약 위반 — 같은 워커, 등록 집합만 다르게 볼지) /
  `Level.Here`(내부 불변식 = 그 자리, 워커 불필요). 멤버 구성은 확정 대상.
- **선행 스파이크(luau-test)** — 추론으로 확정하지 않는다: (a) `debug.info`가
  인라이닝(-O2)·네이티브 코드젠에서 프레임을 어떻게 보이는지(등록 함수가
  인라인되면 걷기가 짧아질 뿐인지), (b) 코루틴 경계(스택 루트가 코루틴
  진입점일 때의 degrade), (c) 걷은 깊이 → `error(msg, n)` 프레임 계산이
  유틸 자신의 프레임을 정확히 보정하는지.
- **이관 시점** — 기존 error 자리(M2 커밋분 + 단위 1)의 리터럴 level을
  유틸 호출로 바꾸는 걸 단위 2 착수 전 일괄로 할지, 마일스톤 진행하며
  점진으로 할지.

`architecture.md`의 error 계약 절(방금 신설한 제3 행 포함)은 채택 시 이
유틸 기준으로 재서술된다 — "도착지가 계약"이라는 원칙 자체는 그대로이고,
도착지를 세는 방법이 손에서 워커로 바뀌는 것.

### `H-264` — `H-257` 힌트의 정본 미갱신 (①, 탐사자)

`Dispatch/init.luau`의 `noMatchMessage`는 `v == nil`일 때 *"(a nil at this
depth may be an unwrapped None or a reactive nil — the key's own handler must
accept nil)"*을 덧붙인다(`H-257` ① 반영, 커밋 `4c01be2`). 그런데 그 메시지의
정본인 `dispatch-core-plan.md` "우선순위 동률/매치 실패 처리" 절은 메시지
내용을 *"`Brand`(있으면)와 `typeof(v)` … provider … 안내만 덧붙임 — 그
이상의 특수 분기는 두지 않음"*으로 못박은 채 그대로다 — 지금 그 문장은
코드가 실제로 하는 일을 부정한다. `4c01be2`의 파일 목록에 `base/`가 0개라
①의 "같은 커밋에서 `base/`+코드" 규약이 이 항목에서 빠진 것. 수정은 한
줄이다 — 그 절에 `H-257` 예외(nil 값 한정 힌트)를 명시하고 "그 이상의 특수
분기는 두지 않음"의 범위를 좁히면 된다.

### `H-265` — None 쌍 분업·배치 서술 어긋남 셋 (①, 탐사자)

셋 다 확정 계약(`NoneHandler`는 재귀만·등록은 `NilHandler` 한 곳,
2026-08-18 사용자 선택 / 배치는 `Dispatch/None.luau`, `H-253`)이 이미 답을
갖고 있어 ①:

1. **`dispatch-core-plan.md` "Length/Offset" 절** — `setLength` 의사코드의
   `element` 인자 주석(2026-08-27 9라운드 Q3)이 *"길이가 상수인 자리
   (`NilHandler`/`NoneHandler`의 `0`)는 지속 클로저가 안 생기므로 생략해도
   된다"* — `NoneHandler`는 `setLength`를 부르지 않는다(같은 문서
   "`None` 센티널" 절: 등록은 `NilHandler` **한 곳에만**). 상수 `0`을 쥔
   말단은 `NilHandler` 하나다.
2. **`source-state-plan.md` "세 번째 카테고리" 절** — Handler 계약을 채우는
   구현 예시로 *"`Dispatch/StoreBind.luau`의 `NoneHandler`"*를 든다. 파일
   분리(단위 3) 이후 실물은 `Dispatch/None.luau`이고 `StoreBind.luau`는 M4의
   별개 파일이다(`architecture.md` 소스 트리).
3. **ROADMAP M3 단위 3 체크박스** — 등록을 *"`Dispatch.setLength(inst,k,0)` +
   `Dispatch.setOffsetSource(inst,k,None)`"* 순으로 나열한다. `+` 나열이라
   순서 주장은 아니지만, 계약 순서는 그 반대(`setOffsetSource` **먼저** —
   `setLength` 꼬리의 recompute가 죽는 중인 Source에 `:Set`을 날리는 걸 막는
   해제 순서 계약)이고, 같은 부류의 역순 표기가 `ref-plan.md` 의사코드에서
   실제로 정정된 전례가 있다(같은 체크박스의 `H-39` 항목 자신은 올바른
   순서로 적혀 있어 한 문서 안에서 갈린다). 코드·`Dispatch/None.luau`는
   계약 순서 그대로다(실측 — spec·프로브 전부 통과).

### `H-266` — Leaf dedup 근거가 stale: "없어도 안 깨짐"이 이제 거짓 (①, 단위 4)

`source-state-plan.md` "Observer/Effect Leaf dedup" 절의 채택 근거는
2026-08-14 시점 *"correctness 문제는 아님 — `old ~= v`를 안 넣어도 안 깨짐"*
이었는데, 그 뒤 확정된 계약 둘이 전제를 무너뜨렸다:

1. **`bindLifetime`의 `canBound` 가드** — 이미 묶인 값의 재바인드는 즉시
   error(이중 배치 방지, `ref-plan.md`/`lifecycle-pattern.md`; mock
   `installLifetime`도 그대로 구현). 확정 의사코드의 retractor는
   `nextValue ~= v`일 때만 unbind하므로, process 쪽 `old ~= v`를 빼면 (A)
   분기의 spurious 재발행에서 아직 묶인 `v`에 `bindLifetime`이 불려
   **크래시**한다.
2. **바인드 부수효과** — *"weak 테이블 쓰기 몇 개뿐"*도 이제 아니다:
   Observer는 `_catchUp` 1회, Effect는 `_bindDestroying`(실제 `Destroying`
   연결 + 캐치업)이 붙는다(M2 `H-159` 이후).

결론(dedup 유지)은 안 바뀌고 근거만 "공짜 최적화" → "계약상 필수"로
승격 — 문서가 이미 답을 갖고 있어 ①. 두 문서에 정정 배너, `spec.leaf.luau`
3이 실측(재-drive가 통과하는 것 자체가 dedup의 증거 — 없으면
already-bound error).

## §4 배치 문항지 (사용자가 읽을 유일한 자리)

**⭐ [2026-08-31 회신 1]** 사용자: *"배치 문항은 중간확인 완료했어. 전부
권고안에 동의해. 나중에 천천히 반영해줘"* — `H-214`·`H-215` 둘 다 **권고 (a)
채택**, 같은 날 반영 완료(각 행 상태 참고).

**⭐ [2026-08-31 회신 2]** `/code-review high`가 올린 셋도 확정 —
`H-218` (a)(*"확인함. a 로 가면 될것 같아"*) / `H-219` 동의 / `H-222` 동의,
전부 반영 완료. 같은 회신이 둘을 새로 열었다: `H-218`에 대한 **되물음**
(*"Destroy 호출되는 것도 retract가 안 먹어서 문제가 생긴다는 부분 아냐?
한번만 다시 봐줘"* → 검증 결과 **맞았다**, `H-229`)과 **상수 배치 제안**
(*"quad-const 등을 만드는 게 좋아보임 … 혹은 그러한 Enum 값도 타입으로 보고
quad-types에 할당하는 건 어떤지?"* → `H-230`).

**⭐ [2026-08-31 단위 2 리뷰]** `/code-review high`(범위 `39108ae..HEAD`)가
10건을 냈고 ① 여덟은 반영 완료(`H-238`~`H-247` 요약 표).

**⭐ [2026-08-31 단위 3 리뷰]** `/code-review high`(단위 3 범위)가 10건 —
① 여덟 반영(`H-255`~`H-263` 요약 표), ② 둘 합류. **지금 §4 대기는 다섯:
`H-240`(🔴)·`H-241`·`H-250`·`H-256`(🔴)·`H-258`.**

**⭐ [2026-08-31 회신 3]** `H-229`에 사용자 별해(retractor 인자 전달) 검토
요청 — 검토 결과 Observer 캡처 경로가 남아 불충분, gchold 앵커 쪽이 맞다는
분석을 `H-229` 절에 추가. 그리고 **error 유틸 모듈 설계**(`setLevel` 맵 +
`debug.info` 스택 워커, "중간에 짤림" 유의점과 최상단 하강 대안까지 사용자
제안 → `H-231`). **아래 세 행이 회신 대기.**

**⭐ [2026-08-31 단위 2 탐사자]** 신선한 탐사자가 5건(`H-248`~`H-252`)을
냈다 — ① 넷(주석 번호 오인용 / 손 세기 잔재 주석 둘 / `spec.drive` 헤더
stale / analyze 게이트에 `quad-error/src` 누락)은 반영 대기, ② 하나
(**`H-250`** — 워커의 `-O2`·코드젠·코루틴 미실측 예약)가 이 표에 합류.
실행·프로브 실측에서 동작 결함은 0건(§5) — **§4 대기는
`H-240`(🔴)·`H-241`·`H-250` 셋.**

**⭐ [2026-08-31 단위 3 탐사자]** 신선한 탐사자가 2건(`H-264`~`H-265`, 둘 다
① 문서 — 코드는 정본대로고 문서 쪽이 어긋난 자리)을 냈다. 실행·프로브
실측(같은 자리 None 재발행 / 깊은 체인 index 2+ 도착 / retractFrom 후
재설치 / 해시 재발행 (A) 연쇄 / 숫자 키 nil 재발행)에서 **동작 결함 0건**
(§5), `TODO(H-` 마커 0, `./scripts/test.sh` 전체 그린. **§4 대기는 다섯
그대로**(`H-240`(🔴)·`H-241`·`H-250`·`H-256`(🔴)·`H-258` — 새 ② 없음).

**⭐ [2026-08-31 단위 4 끝]** 감사 3라운드 수렴(5→1→0) → `/code-review high`
7건(셋은 §4 대기의 독립 재발견 — 교차 검증, `H-269`~`H-271` ① 반영) →
탐사자 5건(`H-272`~`H-276`, 스파이크 4본 실측 — ① 넷 반영, ② 하나 합류).
탐사자가 §4 재료도 보탰다: `H-256`은 **leaf 경로로도 재현**(소수·희소 키
크래시+recomputeBlocker 영구 On, 음수 키는 조용한 오염 후 익명 산술 에러 —
권고 (a)의 "(b)는 다른 말단 핸들러로 가면 재발" 논거 실증)되고 designed
error(이중 배치)가 **drive 배치 Blocker를 On 채로 남기는 것**도 같은 가족
(예외 후 부기 무보장 계약 범위이나 (a) 처리 시 함께 볼 것). `H-250`엔
코루틴 폴백이 문서대로 raise 자리로 떨어지는 실측 데이터 확보(스파이크
재료). `H-186`은 교차 quad bind가 문서화된 UB 그대로임을 실측 확인(§5).
**§4 대기는 여섯: `H-240`(🔴)·`H-241`·`H-250`·`H-256`(🔴)·`H-258`·`H-275`.**

**⭐⭐ [2026-09-01 회신 — 대화형] 여섯 중 다섯 확정·반영 완료, `H-240`만
재질문으로 열려 있다.** 개별 결정·인용은 각 행의 ✅ 태그가 소스(여기 반복
안 함). 요지: `H-241`/`H-275` UB 문서화(후자는 사용자가 "형상 불문 drive
1회"로 범위 확장) / `H-250` 스파이크 `27` 신설·실측(발견: `-O2`가 로컬
직접 호출 태그 함수를 인라인 — 테이블 경유 규칙 명문화) / `H-256`
`checkPosition` 게이트 / `H-258`은 권고 (a)가 아니라 **사용자 자신의
설계**(retractor 2번째 인자 `retracting`)로 닫힘. `H-240`은 사용자가 (a)의
구체 모양을 되물었다 — *"아래에서 한번 더 `bk.offsetSetUpTo < i` 를 하게
된다 하자. 그렇게 하면 해결이 돼? … `sum +=` 를 아래로 내리게 될 수 밖에
없었던 문제가 재발생 하지 않아?"* — 분석 답변(요지: 체크 하나로는 부족,
쓰기 직전마다 검사하는 세 체크 + `getOffsetAt` 내부 재시작이 필요하고,
`H-124` 크래시는 재발하지 않음 — M3 범위엔 진짜 제거(splice)가 없어 그
축은 M6에 실체화) 뒤 **[2026-09-01 후속 회신 *"확인했어. H240 도 이해해서
수행하면 될것 같아"*로 확정** — 그 행의 ✅가 반영 소스. **§4 열린 문항 0.**

**같은 회신에서 사용자가 구조 문제 셋을 새로 제기했다**(요약 표
`H-277`~`H-279`): Bookkeeping 서브시스템 분리(`{Slot, Dispatch} →
Bookkeeping` 의존 방향 제안) / Leaf 핸들러 등록 소유권을 각 객체 선언
모듈(`Observer.luau`/`Effect.luau`)로 / drive pre-hook 개념(사용자 지시로
**리서치 등재** — `research/drive-hook-plan.md`). 앞의 둘도 **같은
후속 회신으로 확정·반영 완료**(각 행의 ✅가 소스).

| 번호 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| `H-214` | `listHandlers`·동률 경고·(나중의) `quad-debug` 덤프가 쓸 핸들러 **이름** — Handler 계약(3종)엔 `name`이 없다 | (a) 계약에 **선택 필드 `name: string?`** 추가 — 있으면 경고·덤프·`listHandlers`가 쓰고 없으면 priority만 / (b) 이름 없이 감 — `listHandlers`는 핸들러 객체 배열만 반환(지금 임시 구현), "이름/priority" 서술을 문서에서 걷어냄 / (c) 다른 방식(별도 등록 인자 `addHandler(h, name)` 등) | **(a)** | `dispatch-core-plan.md` **두 자리**("우선순위 동률/매치 실패 처리"의 `listHandlers` 이름/priority + "부수 효과 — quad-debug에 유리"의 체인 슬롯 이름 덤프)가 이미 "이름"을 전제하고(**[감사 3라운드 정정]** 후자를 처음엔 `research/debug-tooling-plan.md`로 잘못 인용 — 거긴 대신 선택적 `describe` 훅(가칭)이 전례), 선택 필드면 기존 3종 계약을 안 깬다. **(b)를 고르면 두 자리 다 걷어야 한다.** (c)는 이름이 핸들러 자신이 아니라 레지스트리에 살게 돼 체인 슬롯 덤프(슬롯엔 handler 객체만 저장)가 역조회를 또 요구함 |
| `H-218` | **위임 자식 철거 시 `retractFrom(child, prop, 1)`을 계약으로 의무화할지** — chains의 retractor 클로저가 `inst`를 캡처해 자식을 버리는 것만으론 회수 안 됨(`H-71` 패턴, 거짓 GC 주장 둘은 이미 정정). 반응형 숏핸드(`UICorner = state`) 자식 파괴/재생성 사이클마다 구독·gchold 누적 | (a) **항상 의무화** — 위임 핸들러는 자식을 버릴 때 무조건 `retractFrom(child, prop, 1)`(정적 값이면 no-op retractor라 비용 ~0; **`UI-11`의 "필요하지 않다" 결론 일부 역전** — 옛 결정 역전 표시) / (b) 반응형 값이 걸린 자식만 의무(정적은 `UI-11` 유지 — 단 폐기 주체가 값의 반응형 여부를 추적해야) / (c) 다른 방식(chains 구조 변경 등 — 단 리스트 `SetWeak` 전환은 살아있는 체인을 잃는 오답) | **(a)** | 계약이 조건 없이 한 줄이라 어기기 어렵고, 정적 경로 비용이 사실상 0이라 `UI-11`의 실익 논거("불러봐야 하는 일이 없다")와 실충돌이 없다 — 그 논거는 "호출 금지"가 아니라 "요구 안 함"이었고, 새로 드러난 누수가 요구할 이유를 만들었다. (b)는 폐기 주체마다 반응형 추적 부기가 하나 더 생긴다 |
| `H-219` | 매치 실패 `error`의 **도착지** — `drive` 경로(리터럴 props의 미지원 값, 가장 흔한 사용자 실수)에서 level 2가 사용자 코드가 아니라 quad 내부 프레임을 가리킨다. `process`는 핸들러 재귀도 받는 공개 진입점이라 level 하나로 두 경로를 다 못 맞춤 | (a) **지금 유지 + 한계 명시** — 메시지가 key·typeof·브랜드·provider 안내로 자기설명적이라 위치 없이도 진단 가능. M5에서 `New` 파이프라인이 완성돼 drive 경유 프레임 수가 고정되면 재평가 / (b) `drive`가 매치 실패를 잡아 사용자 호출부 level로 재상승 — 단 `pcall` 금지 계약(예외 안전성)과 긴장, 새 메커니즘 / (c) 다른 방식 | **(a)** | (b)는 `pcall`을 안 쓰기로 한 전 자리 계약과 정면 충돌하고, 지금 잃는 건 위치 접두뿐 메시지 자체는 원인을 다 싣는다. 재평가 시점(M5)이 자연스럽게 온다 |
| `H-222` | 제공자(핸들러 작성자) 계약 위반 — retractor 생략·매치 실패류 — 의 **`level` 분류**가 `architecture.md` 계약 표(사용자 입력 2 / 내부 불변식 1)에 없다. 지금 코드는 잠정 2 | (a) **표에 세 번째 행 신설** — "제공자 계약 위반 = 2(그 계약을 어긴 호출 구조에 가장 가까운 프레임)" / (b) 표는 안 늘리고 잠정 2 유지(주석만) / (c) 내부 불변식으로 보고 1 | **(a)** | M3 단위 2~4·M5·M10의 provider-facing error 전부가 같은 분류를 반복해서 물을 자리라, 표에 한 줄 넣는 게 자리마다 잠정 표시를 다는 것보다 싸다. (c)는 "quad 자신의 버그"가 아니라 제공자의 버그라 표의 1행 정의와 안 맞다 |
| `H-229` | **일반 `Destroy` 경로의 chains 잔존** — Destroy는 retract를 안 부르는 게 계약이고 gchold 섬은 Destroy로 무너지지만, `chains`의 **강한 버킷 값**(retractor→`inst` 캡처)이 별도 루트로 남아 weak 항목이 영영 안 비워진다. 반응형 바인딩이 있던 모든 파괴 인스턴스가 부기+userdata 영구 잔존, 죽은 Observer가 상류 전파 순회에 잔류(상세는 `H-229` 절) | (a) **체인 리스트의 GC 앵커를 gchold로 통일** — `chains`는 리스트를 `SetWeak`으로만 잡고, 버킷 첫 생성 시 `bindLifetime(inst, list)`로 리스트를 gchold에 앵커(Destroy → gchold 붕괴 → 리스트·retractor·`inst` 전부 회수; retractor는 **호출 안 함** — 계약 유지, 메모리만 해제). 선례: `slot-plan.md` 13차 세션이 두-`Relate` 상호 순환을 정확히 이 약(전부 weak + 앵커는 `bindLifetime` 하나)으로 고침. ⚠️ 결합 캐비엇: Dispatch가 생명주기 주입을 요구하게 돼 순수 디스패치 테스트도 mock 인스턴스가 필요해짐(단위 1 spec의 평범한 테이블 inst 수정) / (b) 버킷 첫 생성 시 `onDestroying(inst, …)` 훅으로 버킷 드롭 — 같은 결합 + Connection 부기 추가 / (c) 수용·문서화(파괴 인스턴스당 소량 영구 잔존 + 상류 emit 순회 비용) | **(a)** | 같은 병(값이 weak 키를 되참조하는 상호 순환)을 같은 약으로 고친 확정 선례가 있고, 새 개념 없이 기존 프리미티브(`bindLifetime`/gchold) 재사용이다. (b)는 앵커 대신 훅이라 Connection 관리가 하나 더 생기고, (c)는 장수명 게임의 동적 UI에서 무한 누적이라 라이브러리 목표(정확성 우선)와 안 맞다 |
| `H-230` | **공유 상수의 배치** — ① `HANDLER_PRIORITY_*`: 백엔드(M5 quad-roblox)가 핸들러 등록 시 필요. 지금도 `InitRoblox(module)`이 받는 인스턴스의 `module.Dispatch.*`로 닿긴 하지만, 사용자 제안대로 의미가 드러나는 단일 소스가 낫다. ② error `level` 넘버(1/2/3)의 Enum화 | (a) **우선순위 상수만 `quad-types`로 승격** — 이미 모든 패키지가 의존하는 의존성-0 계약 패키지고 런타임 테이블을 반환하므로 값 넷을 싣는 비용이 0에 가깝다(`Dispatch`는 require해 재노출, 단일 소스; 머리말의 "런타임 값은 없다시피" 서술 갱신). **level은 Enum화하지 않는다** — `level`은 의미 enum이 아니라 **프레임 수**라 같은 의미("사용자 호출부")가 자리에 따라 2·3으로 갈리고(`architecture.md` *"프레임 수가 아니라 도착지가 계약"*, `H-205`의 level 3이 실사례), `ERROR_LEVEL_USER = 2` 상수는 헬퍼 프레임이 끼는 자리에서 거짓말을 하게 된다 / (b) `quad-const` 패키지 신설(상수 전부 이관) / (c) 현행 유지(모듈 인스턴스 경유) | **(a)** | (b)는 숫자 넷에 워크스페이스 멤버·pesde shim·relink 비용이 과하고(`H-165`류 함정도 하나 더 생김), 지금 상수가 이것뿐이라 "상수 패키지"가 설 자리가 아직 없다 — 상수가 실제로 불어나면 그때 분리해도 늦지 않다("실제로 관측된 문제에만 구조"). level 비권고 근거는 왼쪽 칸 |
| `H-231` 잔여 | 워커·패키지는 확정됐고(회신 4 — 실험 파일 채택, `quad-error` 구현 완료) **잔여 둘**: ① **태그 체계** — quad 표면에 어떤 레이어 번호를 배정하나 ② **기존 error 자리 이관 시점**(M2 커밋분 + 단위 1의 리터럴 level) | ① 제안: 우선 레이어 **하나**만 — `공개 표면 = 1`(모든 `module.*` 공개 함수 + `addHandler`가 수령하는 핸들러 함수들, 각 `InitXxx`·`addHandler`가 등록). 사용자 입력·제공자 계약 위반은 `errorBefore(msg, 표면)`(= 표면 최상단 진입의 호출부 = 사용자 코드), 내부 불변식은 지금처럼 `error(msg, 1)`(워커 불필요). 레이어 상수가 사는 곳은 `H-230`과 합류해 `quad-types`(quad-error 자신은 quad 비종속이라 quad 이름을 안 실음 — 자기 매니페스트 규칙). 필요해지면 레이어를 늘린다("실제로 관측된 문제에만 구조") ② 단위 2 착수 전 일괄 vs 점진 | **① 제안대로(레이어 하나) + ② 일괄** | 레이어 하나로 error 계약 표의 세 행이 전부 표현된다(2행 = errorBefore(표면), 1행 = error 1). 일괄 이관은 자리가 아직 적을 때(M2+단위 1) 끝내야 두 표기가 마일스톤마다 섞이지 않는다. **✅ [2026-08-31 회신 5·6으로 종결]** — 이관 승인(*"이관 할 부분을 이관하고 다음 단위 착수하자"*) + 진행 중 사용자 발견 둘이 설계를 완성: **중첩 진입 blame**(바깥쪽 스캔만으론 재진입 가드가 죄 없는 바깥 호출부를 blame → **둘 다 제공** 확정, 이름 `errorAtNearest`/`errorBeforeNearest` 사용자 선택) + **사본 네임스페이스 분리**(*"quad-error 각각 require 하고 deps로 들어가면 테깅 네임스페이스가 바뀜"* → quad-error는 상태 없는 `new()` 생성자, quad-base가 만든 하나를 `Quad.errorNamespace`로 공유 — 사용자 제안 구조). 반영: 유틸 재구성 + `ErrorNamespace.luau` 잎 + M2·단위 1 error 자리 전량 이관(레벨 1 불변식·`Ref` 재던지기(0)만 리터럴 유지) + 전 공개 표면·수령 핸들러 태깅 + `architecture.md` error 계약 절 재서술. 부수로 `H-219`의 "M5 재평가" 예약 조기 해소(매치 실패가 `errorBefore`로 사용자 진입점까지) |
| `H-256` | **부기 산술에 들어오는 배열 키의 검증** — `NilHandler`(와 그 아래 `setLength`/`setOffsetSource`)가 희소·소수·음수 숫자 키를 그대로 받아, 전제 위반 입력이 깨끗한 에러 대신 **부기 오염 + `recomputeBlocker` 영구 잠김**(재현 확인)이 된다. 배열 계약(1..N 연속 양의 정수)은 문서에 있으나 검증 로직은 없던 것 | (a) **부기 진입점에서 한 번 검증** — `setLength`/`setOffsetSource` 머리에서 `i`가 양의 정수인지 확인, 위반이면 `errorBeforeNearest`(사용자 입력) — 전 핸들러가 한 자리 가드로 커버되고 희소 키(`bk.N` 대비 건너뜀)는 recompute의 기존 error가 그대로 잡되 **블로커 밖으로 옮기는 건 아님**(그건 H-240과 얽힘) / (b) `NilHandler` 술어를 좁힘(`k % 1 == 0 and k >= 1`) — None/nil 경로만 닫히고 다른 핸들러 경로는 그대로 / (c) UB 문서화만 | **(a)** | (b)는 같은 입력이 다른 말단 핸들러로 가면 재발한다(가드가 자리를 잘못 잡음). (c)는 "조용한 영구 동결"이라는 최악 형태의 UB를 남긴다 — 즉시 error가 quad의 주 방어선이라는 기존 원칙 그대로 (a)가 맞다. 희소 키(연속성) 자체는 recompute의 기존 `sourceList[i] is nil` error가 잡으므로 (a)의 검증은 정수·양수만 **✅ [2026-09-01 (a) 확정 — 반영 완료]** |
| `H-258` | **nil 값 자리의 retractor 신호 충돌** — retractor 인자 계약("nil = 단순 철거 / 값 = 같은 핸들러가 재처리할 새 값")이 **핸들러가 nil을 값으로 받는 자리**(NoneHandler 아래, 반응형 nil)에서 구별 불능. 지금은 무증상(전부 Void)이지만 M4/M9의 nil 수용 핸들러가 계약대로 dedup하려면 신호가 필요 | (a) **계약 문서화** — "nil을 값으로 받을 수 있는 핸들러의 retractor는 인자 nil을 항상 단순 철거로 취급해도 정확하도록 짠다(재프로세스 (A)에서 nil이 오면 철거+재설치와 동등해야 하며, dedup 최적화는 nil 값 자리에선 포기)" — 새 메커니즘 없이 계약 한 줄 / (b) 새 신호(별도 센티널 인자 등) — 새 메커니즘 / (c) 다른 방식 | **(a)** | (b)는 실측된 문제 없이 표면을 늘린다(지금 무증상). (a)는 하강 diff의 기존 성질을 명시화하는 것뿐이고, nil 값 자리의 dedup 포기는 비용이 미미하다(그 자리 재설치는 어차피 부기 재등록 수준) **✅ [2026-09-01 사용자 설계로 확정 — (a)/(b) 대신 셋째 길]** retractor에 2번째 인자(사용자: *"retractUnder 로 불렸으면 true … 미리 준비해두는게 나쁠 게 없음 - 인자 하나 추가되는게 다라서"*) — dedup 포기 없이 신호가 생겼다. 이름 `retracting`은 구현 제안(반영 완료) |
| `H-240` | **`recompute`의 `Get` 창 커서 스톰프**(CONFIRMED) — 되감기 신호가 보호되는 창은 `offset:Set`뿐인데, 길이가 파생 State면 `getOffsetAt`·`sum += contribution()`의 `:Get()` 재계산 중에도 사용자 코드(Compute fn이 동기적으로 건드린 Source의 관측자)가 같은 owner의 커서를 낮출 수 있다. 그 직후의 무조건 쓰기 셋(`offsetSetUpTo = i` / 꼬리 `= bk.N` / `getOffsetAt` 꼬리 `= at`)이 신호를 지워 offset Source들이 낡은 값으로 "완료" 표시된다 | (a) **의사코드 보강 — 읽기 뒤 재검사**: `getOffsetAt`+`contribution` 읽기 **이후에도** `offsetSetUpTo < i`를 한 번 더 보고 되감기(그리고 `getOffsetAt` 꼬리·`recompute` 꼬리·매 반복 커서 쓰기를 "신호를 덮지 않는" 형태 — 예: 쓰기 전 낮아짐 감지 — 로 조정). 확정 의사코드 수정이라 사용자 승인 필요 / (b) **트리거를 UB로 문서화** — "recompute의 입력 읽기(`:Get()`) 도중 같은 owner 부기를 바꾸는 것"을 기존 단방향 흐름 UB의 연장으로 명명(단 `offset:Set` 창의 같은 행위는 지원되므로 창별로 갈리는 비대칭 계약이 됨) / (c) 다른 방식 | **(a)** | (b)의 비대칭("Set 콜백에선 되고 Get 재계산에선 UB")은 사용자가 구분할 수 없는 경계라 계약으로 가르치기 어렵다. (a)는 `H-124`가 이미 세운 "판정을 읽기 앞으로" 원칙의 대칭 확장이고 비용은 반복당 비교 한둘 **✅ [2026-09-01 확정 — 재질문 답변 후 승인]** 답의 요지: 체크 하나로는 부족(범인은 체크 전 커서 쓰기) → 쓰기 직전마다 검사(①진입 스냅샷/기존/②contribution 뒤) + `getOffsetAt` 증분 커서·재시작 자가 치유; `H-124` 크래시는 재발 안 함(모든 lengthList 읽기가 검사 뒤 + 오염 `+=`는 prefix 복원이 버림; M3엔 진짜 제거가 없어 그 축은 M6 실체화 — splice와 함께 재점검 예약). 반영 완료(코드는 `Bookkeeping.luau`, 의사코드 동기, 회귀 spec + 뮤테이션 확인) | 
| `H-241` | **`drive` 재진입과 배치 Blocker 공유** — owner당 Blocker 하나를 배치마다 재사용해, 같은 inst에 재진입 drive가 끼면 안쪽 `OffWithoutEmit()`이 바깥 배치를 조기 개방(등록마다 recompute — O(N²), 크래시는 아님). `blocker-plan.md`의 네스팅 미지원(겹치면 새 Blocker) 서술과 긴장 | (a) **UB 문서화** — 재진입 drive(같은 inst를 자기 구성 도중 다시 drive)는 정상 API로 만들 수 없고(파이프라인 동기 + `H-198`류), 기확정 "재진입 무방어" 원칙 그대로 UB로 명명 + Blocker 문서에 이 자리가 예외적 재사용임을 각주 / (b) 배치마다 새 Blocker(단 `gatedRecompute`가 `getBlocker` 결과를 캡처하므로 게이트 조회를 늦게 바꾸는 재설계 필요) / (c) 다른 방식 | **(a)** | (b)는 실측된 문제 없이 구조를 늘린다("실제로 관측된 문제에만"). 성능 저하일 뿐 정합성은 유지되고, 트리거 자체가 비정상 사용 **✅ [2026-09-01 (a) 확정 — *"그런건 지원할 생각이 없었고, UB로 두는게 맞다고 봐"*, 반영 완료]** | 
| `H-232` | M6에서 Slot이 ownerKey일 때 `bk`(와 자기 체인류 부기)의 **GC 앵커** — Slot은 claim 불가라 `bindLifetime(slot, bk)`가 error. `bk`는 언마운트를 넘어 살아야 한다(재마운트 캐시 계약)는 제약도 있음 | (a) **Slot 생성자가 자기 `bk`를 강한 사적 필드로 소유**(예: `slot._bk` — 이름은 그때 확정) — 수명이 정확히 Slot 수명(언마운트 생존 ✓, Slot 버려지면 같이 ✓), Dispatch의 `getBookkeeping`은 owner가 Slot이면 그 필드를 쓰고 아니면 지금의 gchold 앵커 / (b) `bindLifetime` 확장 계약을 한 번 더 넓혀 "claim 불가 owner면 앵커 생략"(Slot owner의 bk는 Relate 강한 값으로 — 역참조 누수가 Slot 쪽에 되살아남) / (c) 다른 방식 | **(a)** | (b)는 `H-229`가 방금 닫은 누수를 Slot 쪽에 그대로 되살린다. (a)는 "다른 곳에서 안전하게 유지되는 것만 weak" 규칙 그대로고, `bk`가 Slot 수명을 정확히 따라간다 — 단 새 사적 필드라 사용자 확정 대상. **M6 착수 전에만 답이 필요**(단위 2·3·4는 inst owner뿐). **✅ [2026-08-31 회신 8로 (a) 확정 — 이름 `slot._bk` 포함, 정본 두 곳 반영]** |
| `H-215` | 스파이크 `04`(Dispatch 체인 retractFrom, `rewrite-required/`) 처분 — `spec.dispatch.luau`가 체인 깊이·레벨별 힌트·3-인자 `retractFrom`·`SetStrong` 음성 대조군을 이미 실측했으나, 재귀 재발행은 spec-로컬 wrapping 핸들러 **근사**다(실제 `StoreBind`는 M4) | (a) 지금 폐기(`01`처럼 `done/` 이동) — 잔여 몫(실제 `StoreBind` 경유 재발행 경로)은 **M4 StoreBind spec이 진다**고 그 단위 계획에 명시 / (b) M4까지 `rewrite-required/`에 유지(현 ROADMAP 문구 "M3 착수 시 같이 처리"를 "M4에서"로 정정) / (c) 지금 재작성 | **(a)** | 체인 메커니즘 자체는 `spec.dispatch.luau` 12절이 실제 구현에 대고 고정했고(스파이크는 격리 재현이라 오히려 약함), `05`/`15`/`01` 폐기와 같은 근거 구조다. 잔여 몫을 M4 spec 항목으로 옮겨 적으면 잊히지 않는다 |
| `H-250` | `quad-error` 워커의 **미실측 전제 둘** — `H-231` 절이 *"추론으로 확정하지 않는다"*며 예약한 선행 스파이크 중 (a) `-O2` 인라이닝·네이티브 코드젠에서 태그 프레임이 `debug.info` 걷기에 계속 보이는지, (b) 코루틴 경계(스택 루트가 코루틴 진입점일 때의 degrade)가 실측 없이 채택·이관까지 끝났다. (c) 프레임 산술만 `spec.errorutil`이 O1에서 실측. 실패 모드는 blame 열화뿐(크래시 아님) — 태그 함수 대부분이 테이블 저장이라 인라인 후보도 아니라는 추론은 있으나, 그게 정확히 "추론" | (a) `luau-test` 스파이크 신설 — luau CLI의 `-O2`/`--codegen` 플래그와 코루틴 래핑으로 3축 실측(비용 작음, 스파이크 관례 그대로) / (b) 명시 기각을 기록 — "진단 열화뿐이고 실물릴 때 스파이크"를 `H-231` 절/`STATUS.md`에 적어 예약을 닫음 / (c) 다른 방식 | **(a)** | 이 코퍼스의 스파이크 관례가 정확히 이 부류("추론만으로 확정하고 실제 Luau로 부딪혀본 적 없는 것")를 위한 것이고, 예약을 세운 문장이 남아 있는 채로 실측도 기각도 없으면 다음 세션이 "확인됨"으로 오독한다. (b)도 유효한 선택 — 열화가 진단 한정임은 분명하므로, 비용 판단은 사용자 몫 **✅ [2026-09-01 (a) 확정 — *"네이티브 코드젠이 되지는 않을꺼야. 그러나 권고대로 스파이크 신설하는건 나쁘지 않다고 봐"* — 스파이크 27 실측 완료, codegen 축은 예측대로·-O2 축에서 발견 하나]** |

| `H-275` | **형상이 바뀌는 배열 재`drive`의 지원 여부**(탐사자 F-4, 실측) — 축소(`{o1,o2,o3}`→`{o1,o2}`)는 자리 3을 아무도 철거 안 해 **조용한 잔존**(o3 bound·발화 지속, `bk.N=3` 유지), 교환(`{oA,oB}`→`{oB,oA}`)은 자리 1의 (A) 분기가 아직 자리 2에 묶인 oB를 bind하다 **already-bound 크래시**(+ slot 1 `H-103` NOOP 잔존). 같은 형상 재drive는 sanctioned(spec.leaf 3이 스스로 사용), 재진입 drive는 `H-241` — 이건 **순차 재호출** 축으로 미명시 | (a) **UB 문서화** — `drive`는 `New` 파이프라인의 1회 진입이고(배열 재구성은 M6 `:List`/Slot 몫), "형상이 바뀌는 재drive"를 `H-241`과 같은 결의 UB로 명명(축소의 조용한 잔존이 crash보다 나쁜 형태임을 명시) / (b) 재drive를 diff 연산으로 지원(잔존 자리 retractFrom + 교환 안전 순서 — 새 메커니즘, `:List`와 책임 중복) / (c) 다른 방식 | **(a)** | drive의 확정 역할은 최초 구성이고 배열의 시간 변화는 `:List`(M6)가 정본 소유자다 — (b)는 그 책임을 drive에 중복 이식하는 새 구조("실제로 관측된 문제에만"). 크래시 축(교환)은 이미 이중 배치 계약(`0-W`)의 자연 결과라 방어 불요, 축소 축만 "조용함"이 함정이라 문서화 가치가 있다 **✅ [2026-09-01 (a) 확정 + 사용자가 범위를 넓힘 — 형상 불문 "drive는 1회"(*"무엇이 되었든 drive 는 한번 뿐임"* — modifier·PreRef 재수행 사고, existing-instance-binding 기각과 혼동 주의까지 원문 그대로 문단에), 반영 완료·`spec.leaf` 3도 process 경유로 정정]** |

## §5 이상 없음 확인 (탐사자·구현이 확인만 하고 문제 없었던 자리)

- **[2026-08-31, 단위 4 탐사자]** 실측 확인만 하고 문제 없던 자리 —
  dedup 제거 뮤테이션에서 `spec.leaf` 3이 실제로 크래시(`H-266`
  load-bearing 주장의 음성 대조 실증) / bound 중 GC 2회 후 재drive 무사
  (dedup weak 엔트리 미스 창 부재 실증) / 값 교체 cleanup 정확히 1회
  (observer→effect→nil 체인 포함) / 가드 문구·`typeof(k)`·override 의미론 /
  `{["1"]=o}` 숫자 문자열 키는 가드가 "got string"으로 정상 처리 / 교차
  quad bind는 `H-186` 문서화된 UB 그대로(조용한 성공 후 Destroying 덮어씀 —
  Effect.luau 자기 서술과 일치) / 코루틴 **안** drive의 blame 정상.
- **[2026-08-31, 단위 4 `/code-review high`]** §4 대기 셋(`H-256` 🔴/`H-240`
  🔴/`H-241`)을 독립 탐색자들이 **재발견** — §4 분류가 교차 검증됐고 새
  등재는 없음. 리뷰가 스스로 기각한 것 셋: 같은 핸들 이중 배치의 두 번째
  `bindLifetime` error는 버그가 아니라 `0-W` (a) 계약 그대로 / `process`·
  `setLength` 꼬리 병합 리팩터는 `H-226` 선례(확정 의사코드 1:1 우선)와
  충돌 / base 내장 우선순위 동률은 무해(§6 비고와 일치).

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
- **[2026-08-31, 단위 1 탐사자]** `./scripts/test.sh` 전체 exit 0
  (`luau-analyze` 무출력 클린 포함), `grep -rn "TODO(H-"` 0건, 작업 트리
  클린. `Dispatch/init.luau`를 "Dispatch 체인" 절 의사코드와 재차 한 줄
  대조 — (A)/(B) 분기·`NOOP` 교체/점유 마커·`SetStrong` 선행·retractor 생략
  error 양쪽·`retractFrom` 꼬리 역순/항상 소비/구멍 error(level 1) 전부
  일치, 전사 차이는 `H-228`(진단 라벨 표기) 하나뿐.
- **[2026-08-31, 단위 1 탐사자] `getHandler`가 매치 실패에 error가 아니라
  `nil`을 돌려주는 건 발견이 아니다** — brief §6 행은 error를 `getHandler`
  괄호 안에 적었지만, 정본인 `dispatch-core-plan.md`의 "`Dispatch.process`/
  `Handler.process` 이름 겹침" 항목이 `getHandler(inst,k,v): Handler?` =
  순수 스캔/부작용 없음, error는 오케스트레이터(`process`)의 일로 이미
  갈라뒀다. 코드·`quad-types`·spec 1번이 전부 정본 쪽이다.
- **[2026-08-31, 단위 1 탐사자] `Handler` 타입의 정의 위치(quad-types 소유,
  `Dispatch/Handler.luau`는 재수출)는 §6 표기("quad-types … `Handler` 타입
  재수출")와 방향이 반대로 읽히지만 구현 방향이 유일하게 가능한 쪽이다** — quad-types는
  quad-base를 require할 수 없고(의존이 base → types 단방향) `Dispatch`
  타입이 `Handler`를 참조하므로 정의는 types 쪽에만 살 수 있다. 잎 유지
  계약("Dispatch를 되참조하지 않는다")은 그대로 성립.
- **[2026-08-31, 단위 1 탐사자] spec이 안 태우던 경로 셋을 프로브로 실측,
  전부 계약대로** (스크립트는 스크래치, 남기지 않음): (1) `H-223` —
  retractor 생략 메시지가 name·priority·k·index를 실제로 싣는다
  (`handler "MyLeaf" (priority 7) returned no retractor at key SomeKey,
  index 1`). (2) `H-103` — `h.process`가 던지면 `NOOP` 마커가 남고, 이후
  `retractFrom`은 조용히 소비(에러 없음, 정리 0회)하며 그 뒤 재설치·철거는
  정상(문서가 말한 "부기 무결성 비보장 + 크래시는 아님" 그대로). (3) 매치
  실패 후 같은 `(inst,k)`에 핸들러를 등록하면 정상 동작 — 실패 경로가
  chains에 빈 리스트 하나를 남기지만 의사코드도 같은 순서(list 확보가
  getHandler보다 앞)라 전사 차이 아님.
- **[2026-08-31, 단위 1 탐사자]** `addHandler`의 `table.sort`는 불안정
  정렬이라 **동률** 핸들러끼리의 스캔 순서가 등록이 추가될 때마다 뒤섞일
  수 있는데, 이는 문서가 이미 확정한 "동률 tiebreak 규칙은 강제하지
  않는다"(우선순위 동률/매치 실패 처리 절) 범위 안이다 — 가드·안정화
  제안 안 함(관측된 문제 없음 원칙).

- **[2026-08-31, 단위 2 구현]** "Length/Offset"·"두 필드"·배치 게이팅 절
  의사코드를 한 줄씩 옮기며 대조 — `getOffsetAt` 부트스트랩/접두 연장,
  `recompute`의 재진입 차단·매 반복 상한 재평가·`H-124` 판정 순서·`H-113`
  되감기·1 클램프·커서 마감 순서, `setLength`의 N 수명주기·두 커서 무효화·
  요소 조회 클로저·anchor 분리, `setOffsetSource` 즉시 계산·`None` 얼리 리턴,
  drive ⓪/⓪'(`H-17` 배열 파트 가드 + `H-119` 게이트) — 전부 정본 그대로.
  `spec.lengthoffset.luau` 8절이 실측(되감기 시나리오는 offset 구독 콜백의
  재진입으로 재현). **`bk`에 `H-229` 패턴을 적용한 것은 확정 설계의 적용**
  (`H-71` 역참조가 chains와 동형) — Slot owner 몫만 `H-232`로 분리.
- **[2026-08-31]** spec 작성 중 실측 둘: `state:Observer(fn)`는 등록 즉시
  1회 실행만 하고 **구독/바인드 전엔 emit에 발화하지 않는다**(canExecute
  게이트 — 계약대로). `setLength` 꼬리의 동기 `recompute`가 캐시를 즉시
  재구축해 무효화 커서의 중간 상태는 밖에서 관측 불가(값으로 검증).
- **[2026-08-31, 단위 2 탐사자] `./scripts/test.sh` 전체 exit 0**
  (`luau-analyze` 무출력 클린 포함), `grep -rn "TODO(H-"` 0건, doc-check
  ERROR 0. 부기 코드(`getOffsetAt`/`recompute`/`setLength`/`setOffsetSource`/
  `drive` ⓪⓪')를 "Length/Offset"·"두 필드"·무효화 표·배치 게이팅 절
  의사코드와 재차 한 줄 대조 — 전사 차이는 확정 계약 둘(영어 error(`H-212`)
  / `Err.*` 워커 이관(`H-231`))뿐. "두 필드" 배타성(올리는 쪽:
  `getOffsetAt`→`offsetCacheValidUpTo`만, `recompute`→`offsetSetUpTo`만)도
  코드에서 그대로 성립.
- **[2026-08-31, 단위 2 탐사자] spec이 안 태우던 경로들을 프로브로 실측,
  전부 계약대로**(스크립트는 스크래치, 남기지 않음):
  1. **`getOffsetAt` 부트스트랩 반복** — fresh owner(`bk.N == nil`)에
     `getOffsetAt(inst, 1)` 연속 호출 둘 다 `0`, 빈 bk에 `getOffsetAt(inst, 2)`는
     `H-106` 가드로 즉시 error(`lengthList[1] is nil — bookkeeping is broken`).
     `getOffsetAt(inst, N+1)`(꼬리 삽입 위치)은 정상 `5` 반환.
  2. **`setLength` 같은 자리 재등록** — State→State 스왑 후 옛 채널
     `oldLen:Set(99)`가 죽어 있고(`s2` 불변) 새 채널만 동작, State→상수
     전환 시 `bk.observers[i]`가 `nil`로 비워지고 옛 State emit 무시.
     해제(`setOffsetSource(None)` → `setLength(0)`)에서 해제된 Source에
     재-`Set` 없음(순서 계약의 목적 그대로).
  3. **drive 배치에 State 길이 + 재-drive** — `drive(inst, {2, len2, 1})` 직후
     offset `0/2/5`, 배치 밖 `len2:Set(10)`에 `0/2/12`, 같은 inst 재-drive((A)
     분기)에서 옛 길이 Observer가 `unbindLifetime`으로 죽고 새 것만 동작,
     블로커·`recomputeBlocker` 둘 다 off로 마감.
  4. **error 도착지(pcall 메시지의 파일:줄)** — drive 경유 매치 실패가
     사용자 함수 안의 `drive` 호출 줄을 정확히 blame:
     `./…/tmp-probe1.luau:19: quad.Dispatch: no handler matched key Size
     (value: number) — …` (`H-219` 조기 해소 실증). retractor 생략
     (`errorBeforeNearest`)은 직접 `process` 호출에선 호출부 줄을, drive
     경유에선 가장 가까운 표면(process)의 호출부인 `Dispatch/init.luau`의
     drive 루프 줄을 blame — `H-222` (a)의 "가장 가까운 호출 구조" 정의
     그대로이고 메시지가 핸들러 특정 정보를 실어 진단 가능(`H-223`).
- **[2026-08-31, 단위 2 탐사자] error 이관 전수 확인** — src 전체에서 남은
  리터럴 `error(`는 level 1 내부 불변식 다섯(`retractFrom` 구멍 /
  `getOffsetAt`·`recompute` 부기 파손 / `Effect.Init` 미실행)과 `Ref`
  재던지기 `error(err, 0)` 하나뿐 — `H-231` 잔여 행의 *"레벨 1 불변식·`Ref`
  재던지기(0)만 리터럴 유지"* 그대로. 표면 태깅도 State/Source/Store/
  Observer/Effect/Ref/Blocker/Dispatch/RunInit/AddPlugin/생명주기 스텁/mock
  5종까지 일관(`module.New`·`Relate`·brand 술어는 미태그이나 그 아래로
  던지는 error 경로 자체가 없어 실질 영향 0 — 발견으로 안 올림).

- **[2026-08-31, 단위 3 탐사자] `./scripts/test.sh` 전체 exit 0**
  (`luau-analyze` 무출력 클린 포함 — `Dispatch/None.luau`도 대상),
  `grep -rn "TODO(H-"` 0건(quad-base/quad-types/quad-error), doc-check
  ERROR 0, 작업 트리 클린. `Dispatch/None.luau`를 "`None` 센티널"/
  "`NilHandler`" 절·`modifier-plan.md` "2-1"절과 재차 한 줄 대조 —
  `isHandlable`(`v == None` 신원 / `type(k) == "number" and v == nil`),
  둘 다 `<매우 높음>`(`HANDLER_PRIORITY_HIGH`, `H-253`), `NoneHandler`
  재귀만(`index + 1`, 배열/해시 무구분, 선행 `retractFrom` 없음),
  `NilHandler` 말단(재귀 없음, `setOffsetSource(None)` → `setLength(0)`
  해제 순서 계약 그대로, 상수 길이라 `anchor`/`element` 생략 — "Length/Offset"
  절 규칙 그대로), 둘 다 retractor `Void`, `drive`에 `None` 스킵 분기 없음 —
  전부 일치. Handler 작성 체크리스트 1~9도 위반 없음(8번: `NoneHandler`는
  항상 재위임, `inst` 무접촉; `H-218` 의무는 같은 키 재귀라 해당 없음).
  전사 차이는 문서 쪽 `H-264`(nil 힌트가 코드에만) 하나.
- **[2026-08-31, 단위 3 탐사자] spec이 안 태우던 경로들을 프로브로 실측,
  전부 계약대로**(스크립트는 임시 파일로 돌리고 지움):
  1. **같은 자리 None 재발행**(`State<X|None>` 재발행 근사 — 같은
     `(inst,1)`에 `process(…, None, 1)` 반복) — (A) 연쇄 두 단
     (`NoneHandler`의 Void가 `None`을, `NilHandler`의 Void가 `nil`을 받음)
     모두 무해, 등록 멱등(`bk.N`·`lengthList[1]=0`·`sourceList[1]=None`
     유지), 뒤 자리 offset·접두합 캐시 안정.
  2. **깊은 체인** — 래퍼(HIGH+1) 아래 `None`이 index 2에 도착:
     `NoneHandler`@2 → `nil`@3 → `NilHandler`@3 등록, 값→None 전환에서 (B)가
     옛 말단을 retract(`hint nil`), 깊은 (A) 연쇄 재발행 멱등, 복원까지 정상.
  3. **`retractFrom` 후 None 자리 재설치** — 슬롯 소비 후 `process(None)`
     재설치 (B) 정상, 부기 그대로(NilHandler retractor가 Void라 등록은 안
     걷힘 — 계약), 값 재설치도 정상.
  4. **해시 None 재발행** — (A)@1 `NoneHandler` → `nil` 재귀 → (A)@2 키
     담당 핸들러가 `retractor(nil)`+`process(nil)`을 받음(이 자리의 nil
     신호 중의성은 기록된 `H-258` 그대로 — 재보고 아님), None→실값 전환은
     (B)@1로 꼬리 철거 후 실값 핸들러@1 신설.
  5. **숫자 키 진짜 nil 재발행** — `NilHandler` (A) 반복 멱등.
- **[2026-08-31, 단위 3 탐사자] 희소 배열 입력은 재보고하지 않음** —
  `drive(inst, {[3]=None})`·`{nil, "a"}` 리터럴류(배치 게이트
  `flattened[1] ~= nil`이 열리지 않는 것 포함)는 전부 `H-256`(§4 대기)의
  희소·비정수 키 가족이라 그 처방에 묶인다.
- **[2026-08-31, 단위 3 탐사자] ROADMAP의 "`isNone`은 `None.luau`(M3) 쪽에
  산다"는 발견으로 안 올림** — 실물엔 `isNone`이라는 함수가 없고
  `Dispatch/None.luau` 헤더가 "`isNone` is `v == None`"(항등 비교 서술)로
  대신하는데, `brand-plan.md`가 *"그런 이름의 함수를 두더라도"*로 함수화
  자체를 허용형으로 열어둔 자리라 어긋남이 아니다(`Brand.luau` 헤더도 같은
  서술).

## §6 남은 의심 (발견은 아니지만 다음 라운드가 파볼 자리)

- **[2026-08-31, 감사 4라운드 비고]** "기존 짧은 선두 태그 안에 새 배너
  설명을 이어붙이는" 패턴이 태그를 80자 넘겨 그 절을 조용히 인용 불가로
  만든다(`doc-check.py`의 태그 벗기기 상한). 이번엔 한 곳을 잡았지만 전
  코퍼스에 같은 부류가 더 있을 수 있다 — 80자 초과 선두 볼드 태그 스윕이
  다음 전 코퍼스 감사 때 파볼 자리.
- **[2026-08-31, 단위 4 비고]** `module.debug`의 동률 경고 print가 base 자기
  등록끼리도 걸린다 — HIGH 밴드에 `NoneHandler`/`NilHandler`/
  `ObserverEffectLeafHandler` 셋, FALLBACK에 가드 둘(전부 `isHandlable`이
  서로 안 겹치는, 문서가 명시적으로 허용한 내장 동률). 확정 서술("동률 감지
  시 print")과 1:1이고 debug 기본값이 `false`라 실해는 없지만, debug를 켠
  사용자가 base 내장 쌍 경고를 노이즈로 볼 수 있다 — 손보려면 새 메커니즘
  (base 등록 면제 등)이라 지금은 안 만든다("실제로 관측된 문제에만 구조"
  원칙). 실제로 불편이 관측되면 그때 문항으로.
- **[2026-08-31, 감사 2라운드 비고 — M8이 확인할 자리]** `RefLeafHandler`의
  dedup 미스 창 논증(`H-267`로 이식)은 **GC 조기소실만** 커버한다 — Ref는
  `v:Set(inst)`가 dedup 기록(`relate:SetWeak`) **전에** 임의 사용자 콜백을
  동기 실행하므로, 그 콜백이 같은 `(inst,k)`를 같은 `v`로 재귀 재-dispatch
  하면 **기록 순서** 미스 → `canBound` 크래시가 가능하다. Observer/Effect의
  바인드 부수효과는 임의 사용자 코드를 동기 호출하지 않아 이 경로가 없다.
  실사용 패턴인지("드문 오용" 원칙 해당 여부) 불명 — 코드가 M8에나 생기므로
  그때 기록 순서(SetWeak을 `v:Set` 앞으로?)를 확인할 것. `ref-plan.md`의
  해당 주석에도 같은 한정을 달아뒀다. **[감사 3라운드 보강]** 판단 시 기존
  확정 원칙 *"일반적인 재진입/무한루프는 방어 안 함"*(2026-08-04 —
  `dispatch-core-plan.md`/`gate-plan.md`/`slot-plan.md`가 인용)과의 관계를
  먼저 볼 것: 이게 그 원칙이 커버하는 "사용자 코드가 만드는 재진입"의 한
  사례라면 조사 없이 UB로 닫힌다. "Handler 작성 체크리스트" 5번(클로저 안
  `Dispatch.process` 금지)은 직접 안 걸린다 — retractor가 아니라 `process`
  자신의 동기 부작용(`v:Set`) 안 재진입이라서.
