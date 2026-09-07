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
| `H10-8` | ① | 🟡 | **[2026-09-03 통합 `/code-review`]** `AttributeGroupFallbackHandler`에 `H-154` 같은-값 dedup이 없었다 — 같은 그룹 객체 재발행(직접 process·StoreBind 경유)마다 K개 이름을 전부 retract→재claim→`setAttribute`(Tag 핸들러가 명시적으로 막은 그 경우) | ✅ 반영 — retractor `v == nextValue` 스킵 + process는 "이미 이 자리가 claim 중"(retractor 스킵의 흔적)이면 위임 루프 생략(re-emit). 키 집합은 캡처 테이블 대신 메모이즈된 `groupKey(v, name)`로 재계산(단순화). spec.attribute 9절(직접·StoreBind 양쪽 엔진 호출 0 + 진짜 교체는 여전히 동작) |
| `H10-10` | ① | 🟢 | **[2026-09-03 M10 엔진 축 첫 단위 — 메인 자율 구간]** Tag/Attribute 엔진 op 설치(사용자 위임 — 아침 회신 4번 *"어떤 방식으로든 채운다면 괜찮"*): 방향은 (d′) "모든 프로바이더가 같은 형태" | ✅ quad-roblox `EngineOps.luau`에 `addTag`/`removeTag`(CollectionService, `game`은 호출 시점에 읽어 CLI 심 가능)/`setAttribute`(`inst:SetAttribute`, nil 삭제) + `H-238` 태깅; mock은 `mockProvider`가 같은 셋을 심고 `installTagAttributeOps(q, log)`는 **로그 관측용 재설치**로 남김(mock Instance에 `SetAttribute`/`GetAttribute`/`GetAttributes`, `gameShim`에 CollectionService 네 멤버 — 두 경로가 같은 저장소를 본다); quad-base 스텁 안내문을 "프로바이더 설치"로 갱신; quad-types `Quad`에 op 필드 셋; `spec.tagattribute` 4절 + `spec.robloxfactory` 6 재편(스텁 아님 단언) + `spec.tag` 2/`spec.attribute` 8은 모듈 자신의 스텁을 붙잡아 프로바이더 설치 뒤 되돌려 **디스패치 경유** blame 경로를 유지(`H-174` 호출 시점 읽기); Studio 7/7. **끝 절차 `/code-review medium` 4건 반영(전부 mock 테스트 인프라)**: 태그/속성 저장소를 프록시가 아니라 Data 레코드 키로(프록시는 GC 뒤 재생성돼 값이 증발 — 재현됨) / 심·인스턴스 메소드·프로바이더 op이 한 벌의 비공개 헬퍼에 위임(두 경로 드리프트 방지) / 전방 선언 제거 / 위 스텁 spec 되돌리기 방식 |
| `H10-11` | ② | 🟡 | **[2026-09-03 M10 엔진 축 둘째 단위]** `D.TextButton { Text = "a", [OnChange "Text"] = fn }`처럼 **같은 props에 프로퍼티 대입과 `OnChange` 바인딩이 같이 있으면 초기 대입이 콜백을 깨울지가 해시 순서에 달린다** — base 계약은 배열→해시 순서뿐이고 해시 파트 안 순서는 약속 밖(dispatch-core "배열→해시 순서", `H-142`가 `Parent`를 뺀 같은 이유). mock에서 실제로 뒤집혀 spec 4절이 1차에 깨졌다(`Text = "a"` 대입이 Connect 뒤에 와서 콜백 발화) | ✅ **[2026-09-03 사용자 결정 — 갈래 밖 (d)] `OnChange`를 배열부 값으로 역전**(`H10-14`): 배열→해시 순서 계약으로 Connect가 항상 프로퍼티 대입보다 먼저 → 비결정이 **초기값 발화 계약**으로 바뀜(사용자: *"초기값 발화는 계약으로 … 오히려 순서 없던것 보다 훨씬 나아보임"*). 갈래 (a)~(c)는 전부 기각(구조 없이 문제 자체가 사라짐) |
| `H10-12` | ② | 🟡 | **[같은 단위, strict 실측]** 특수 키가 `<Class>Param<E>`에 **타입으로 들어갈 자리가 없다** — `[number]: E` 인덱서라 `{ [q.OnChange "Text"] = fn }`이 strict에서 `Expected 'number', got 'OnChangeKey'`(+ 값도 `E` 유니언에 맞춰야 함). `AttributeKey`/`Tag` 키도 같은 사각(nocheck spec만 있어 드러나지 않았음). 런타임 무영향 | ✅ **OnChange 몫**(`H10-14` 역전 — 배열부 값이라 생성기의 `E` 유니언 확장으로 흡수) / **`AttributeKey` 몫도 ✅ — 사용자 결정 (c′) "한 발 얹기"(`H10-15`)**: `AttributeKey`는 무타입 프리미티브로 남기고(해시부 그대로, 타입 사각은 "타입이 몰라도 되는 존재"로 수용 — 엔진 고유 타입용), 일상 경로는 배열부 슈가 `StringAttribute(name, value)`류(단일 항목 그룹 → `NewChild`로 strict 통과). `Tag`/`Attribute` 그룹의 `E` 누락도 같은 `NewChild` 확장으로 닫힘 |
| `H10-15` | ① | 🟢 | **[2026-09-03 사용자 확정 — 타입드 스칼라 슈가]** 원문 *"StringAttribute 등은 핸들러 상 싱글 attr group 마냥 작동 … AttributeKey 는 내부적 요소 … 내부 타입체크나 그런건 구현 쪽에 부담 … 한 발 더 얹는거야 … AttributeKey 는 타입이 몰라도 되는 존재"* | ✅ `Attribute.luau`에 `StringAttribute/NumberAttribute/BooleanAttribute(name, value)` = `Attribute({ [name] = value })`(자기 핸들러 없음 — 개인 키·위치 claim·dedup·StoreBind 위임 상속), raw 값 Lua 타입 검사·nil 거부·State/None 통과, `H-238`; `AttributeKey.luau`의 옛 별칭 제거; quad-types `AttributeSugar<T>` + `Quad` 필드; quad-roblox `NewChild`에 `Tag`/`Attribute`(+State) 합류; spec.attribute 1절 정정·10절 신설, spec.onchangetypes 양성 추가; Studio 실측(슈가 셋+AttributeKey Color3, 반응형·None 삭제·거부 셋·같은 이름 충돌). 정본은 `attribute-plan.md` 머리 배너(옛 `AttributeKey<<T>>` 서술은 옛 모델로 표시) |
| `H10-14` | ① | 🟢 | **[2026-09-03 사용자 제안·동의 — `OnChange` 배열부 역전]** 원문 *"OnChange("KeyName", func) 형태가 되는게 어쩜 맞을수도. 여기에서 Keyname 은 K&(union) 하면 캐치 가능하고, 오직 컨스트럭터 상 index<> 만 수행해서 func 안 입력타입을 알려주는게 가능하지 않나 … 여러 콜백을 지정도 가능하고, State<...> 으로도 연결이 가능함"* — 키 형태의 결함 셋(해시 순서·strict 타이핑 사각·같은 이름 중복이 리터럴에서 조용히 소실)을 한 번에 닫음 | ✅ `Handlers/OnChange.luau` 재작성(디스크립터 `{ Name, Callback }` + 모듈 로컬 브랜드, 길이 0 말단, 캐시·`H-27` 폐기), `types.luau` `OnChangeDescriptor`, `gen-d.py`가 `PropTypes`(235, 충돌 6은 `any`)·`OnChangeFn`(`K & keyof<PropTypes>`/`index<PropTypes, K>` — 오타·콜백 타입·**무주석 추론**)·클래스별 `<Class>OnChange` 유니언을 `D`/`Mapper` `E`에 합류, `RobloxExtension.OnChange: OnChangeFn`, `spec.events` 4~6절 재작성(초기값 발화·같은 이름 둘·`State<디스크립터>`)+strict `spec.onchangetypes`, test.sh `LuauSubtypingIterationLimit=100000`(typing-limits 8.7), 스파이크 `30`, Studio 실측(audit 3절). 문서: `onchange-plan.md` 전면 재작성 + `archive/onchange-hash-key-reversed.md`. **끝 절차 `/code-review medium` 2건 반영(생성기 위생)**: 프로퍼티 0개 클래스의 우변 없는 별칭 → `never` 가드 / 배열 원소 유니언을 클래스당 `<Class>Elem`·`<Class>MapperElem` 별칭 하나로(D·DMapper 타입과 런타임 캐스트 네 자리가 같은 별칭 참조 — 손 나열 드리프트 방지) |
| `H10-13` | ① | 🟢 | **[같은 단위]** `Handlers/Event.luau`(`GetEventsOfClass` 리플렉션 캐시·키 매치·`v == nil`이면 Connect 안 함·retractor가 Connection 캡처)·`Handlers/OnChange.luau`(`OnChange(name)` 이름별 weak 캐시 + 모듈 로컬 weak-key 브랜드·`H-27` 얼리리턴·`v(inst[name])`)·`RobloxFactory` 설치 + 확장 `{ D, OnChange }`·`types.luau` `OnChangeKey`·mock `declareEvents`(한 레지스트리로 `inst[name]` 시그널과 `GetEventsOfClass` 심)·`spec.events` 6절·Studio 8/8(`audit/m10-events-studio-2026-09-03.md`). 같은-값 dedup은 두지 않음(Connect 비멱등 — 편측 skip은 이중 연결; churn은 event-plan이 허용). **끝 절차 `/code-review medium` 반영 4건**: Property `v == nil` 쓰기 건너뛰기(dispatch-core `None` 캐비엇이 "M9/M10로 미룸"이라 M10이 닫히는 이 단위에서 채움 — `spec.handlers` 9절) / mock `Destroy`가 이벤트 Connection도 끊음 / mock이 선언된 이벤트 이름 대입을 거부(실물 대칭) / spec 헬퍼 단순화; `module-lifecycle-plan.md` 확장 모양 각주 | ✅ 구현 완료(역전 **이전** 시점 기록 — 이 행의 OnChange 서술(이름별 weak 캐시·`H-27`·`OnChangeKey`)은 옛 형태다). **[2026-09-03 후속]** OnChange 몫은 같은 날 `H10-14`로 대체 — `onchange-plan.md` 전면 재작성·`event-plan.md` 갱신, 옛 형태는 `archive/onchange-hash-key-reversed.md`. Event 몫은 그대로 유효 |
| `H10-9` | ① | 🟡 | **[통합 `/code-review`]** `Tag(...)` 생성자가 vararg를 `{...}`+`ipairs`로 돌아 **nil 구멍 뒤 이름이 검증도 없이 조용히 누락**(`Tag("a", nil, "c")` → `{"a"}`) — `Attribute` `__call`은 `select` 순회로 nil을 검증 에러로 올려 비대칭 | ✅ 반영 — `select("#")` 순회로 매 슬롯 방문, nil은 여느 비문자열처럼 검증 에러. spec.tag 대조군 |
| — | 🟢 | — | (통합 `/code-review` 정리 후보 — 반영 안 함) `notInstalled` 스텁 팩토리가 `Tag.luau`/`AttributeKey.luau` 2벌 동일 — **`H-261` 추출 트리거는 3벌**이라 보류(M10 엔진 축에서 `setTimeout` 스텁 등 3번째가 생기면 그때 추출). `LifetimeHandle`의 것은 Nearest·다른 메시지라 3-way 부적합 | 🟢 기록만 |

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
