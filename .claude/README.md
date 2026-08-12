# .claude/ — quad-v2 계획/설계 문서 색인

이 레포 전체가 quad-v2(재작성) 프로젝트이므로, webmanager류 서브프로젝트 구분 없이
`.claude/` 바로 아래에 전부 있음. **루트 `CLAUDE.md`가 현재 상태+TODO 색인의
최종 소스** — 먼저 그걸 보고, 특정 결정의 자세한 근거/논의가 필요할 때만 아래
개별 문서를 열어볼 것.

## 폴더 기준

| 폴더 | 기준 |
|---|---|
| `base/` | 결정 완료 + 프로젝트 전체에 걸치는 컨텍스트 — plan/done 개념 없음, 계속 참조되는 배경지식. **항상 읽어야 하는** 배경지식만 여기 둠(다른 문서를 이해하는 데 전제되는 것) |
| `reference/` | **[2026-08-07 신설]** 결정 자체가 아니라 다른 문서가 근거로 인용하는 온디맨드 참고 자료(v1 스냅샷, 프레임워크 비교 리서치) — "완료" 개념 없는 건 `base/`와 같지만, 항상 읽을 필요는 없고 해당 문서가 인용될 때만 열어보면 됨. `quadnomicon` 소재 후보가 많음 |
| `research/` | 아직 착수 전, 사용자와 스코프/설계를 더 상의해야 함 |
| `qa-request/` | 구현 완료(코드/에이전트 검증까지 끝남) + 사용자 본인의 실기기(Roblox Studio) QA만 남음 — 지금은 구현 자체가 시작 전이라 비어있음 |
| `archive/` | 완료 + 사용자가 실사용/실기기로 직접 검증까지 마침 (구현 대상). **[2026-08-06 확장]** 완전히 뒤집힌 설계 결정을 원문+역전 이유+diff와 함께 보존하는 용도로도 사용(제목 `[역전됨]` — 한 번 확정했다가 뒤집힌 것) — 더 이상 능동적으로 참고 안 해도 되지만(토큰 낭비 방지 위해 `base/`/`research/`에서 뺌) `quadnomicon` 소재로는 나중에 쓸 수 있음. **[2026-08-07 확장]** 후보였다가 채택 안 된 것(확정한 적 없이 검토 후 기각)도 같은 방식으로 보존, 제목은 구분을 위해 `[기각됨]` — `[역전됨]`과 의미가 다르므로 혼동하지 말 것. **[2026-08-07 세 번째 확장]** 설계 반전/기각과 별개로, 에이전트가 문서 작성 중 스스로 낸 개념 혼동을 정정한 이력은 `[에이전트 실수]` 태그로 `agent-mistake.md` 하나에 모음(CLAUDE.md 세션 로그 중복 방지) |
| `feedback/` | 실사용 피드백을 정리한 긴 로그 — 지금은 비어있음(구현 시작 전) |
| `luau-test/` | **[2026-08-09 신설]** `base/` 확정 사항 중 "추론만으로 확정하고 실제 Luau로 부딪혀본 적 없는 것"(M0 스파이크 대상)을 `luau`/`luau-analyze`/`luau-lsp`/Roblox Studio로 사용자가 직접 돌려볼 독립 실행 스크립트 모음. 아직 결과 미확인 — `luau-test/README.md`가 색인 |
| `session/` | **[2026-08-11 신설]** 세션별 상세 로그 원문(시행착오·정정 전 서술 포함, `quadnomicon` 개발로그 소재용) — 루트 `CLAUDE.md`가 3196줄까지 불어나 성능 저하를 유발해서 분리함. 파일명 `YYYY-MM-DD-NN-slug.md`, CLAUDE.md의 "세션 히스토리" 절에서 각 항목이 여기로 링크. 항상 읽을 필요 없음 — 결정의 논의 과정이 궁금할 때만 |
| `initreq/` | 프로젝트 착수 시 클론해둔 참고 레포(quad v1, fusion, vide, rbvm, tbox, code-docker) + PA님 실 코드(`artworks/`, 4차 라운드 교차검증 근거) + 원본 요청(`req.md`, `raw-userinput.md`) + `quad2-try`(이전에 시도했다 폐기한 v2 재작성 시도 — 리서치 완료, 결론은 `base/bind-system-plan.md`) — 읽기 전용 리서치 소스, 여기 내용을 옮기지 말고 항상 원본 그대로 유지 |

`research/`의 문서가 설계 확정되면 `base/`로 승격(또는 구현 착수 시
`qa-request/`행). 지금은 구현 라운드 전(설계 단계)이라 전부 `base/`/`research/`에만
있음.

## `base/` — 결정된 것, 프로젝트 전체 컨텍스트

| 문서 | 내용 |
|---|---|
| `architecture.md` | quad-v2 전체 아키텍처 확정 사항 요약(제일 먼저 볼 문서) |
| `lifecycle-pattern.md` | rbvm의 `Connected`+GC 관용구를 quad-v2가 채택하는 방식 |
| `store-semantics.md` | Store는 부작용 허용이 기본. State는 Store 위의 조합 가능한 캐시 레이어로 실제로 필요함(2026-08-04 정정) — 온톨로지 핵심 메커니즘은 2026-08-04 2차 라운드에서 확정, 최신 상세는 `base/bind-system-plan.md` |
| `bind-system-plan.md` | pluggable key/value 핸들러 레지스트리 — `process`/`retract` 디스패치 모델, Ref, Store/State/Source 온톨로지 + 인체공학 질문 전부 확정. 디스패치 엔진은 `quad-base`가 인터페이스로 소유(2026-08-04 5차 라운드). **[2026-08-11 세션, 여섯 번째]** `Dispatch.setLength`/`setOffsetSource`의 owner 키가 물리 Instance로 한정될 필요 없음을 명시(Slot-in-Slot 재귀의 근거) — 같은 절 `recompute`의 off-by-one 버그 발견·수정(`offset`이 자기 자신을 포함해 누적되던 것), 재진입 방지 가드는 검토 후 기각(`Source⊇State` 단방향 원칙과 같은 카테고리의 UB로 명명, 각 Slot이 독립 `bk`를 가져 nesting만으로는 재진입 경로 자체가 없음을 확인). **[2026-08-12 열한 번째 세션, 전면 정정]** "핸들러 타입이 안 바뀌면 retract 없이 process가 diff"는 틀렸음 — `retract`는 store 재발행마다(핸들러 타입 무관) 항상 불림, `v`는 대체 값 자체일 수 있어 `nil`로 가정 금지. `Tag`/`Ref`/`Slot`/`Attribute` 전부 이 오류로 설계돼 있었음이 드러나 한 세션에 전부 정정(`archive/retract-always-fires-reversed.md`) |
| `module-lifecycle-plan.md` | 프로바이더 패턴, bind/store 구현 책임 분리 — 확정 |
| `slot-plan.md` | 뮤터블 자식 배열, 엄격한 단일 마운트 소유권, 재마운트 시 throw, base/roblox 패키지 경계까지 확정. **[2026-08-09 세 번째 세션]** `Add`/`Remove`/`Extract`/`Clear`/`Move`/`Swap` CRUD(복잡도 표기 포함), `isMounted` 이중 추적 분리, 요소 타입 제약(`nil`/`None`/핸들러 계층 값 금지, `Slot<T>()` 제네릭), 키 기반 동적 컬렉션 재조정(`Slot:List(data, updateFn, keyFn?)`)까지 전부 확정 통합, base/roblox 경계에 reposition 훅 추가. **[2026-08-09 열한 번째 세션, 중간검토]** CRUD 식별 기준을 element 레퍼런스에서 인덱스 기준으로 재정정(`Remove(index)`/`Extract(index, newElement?)`/`Move(oldIndex, newIndex)`), `ExtractAll`/`Get`/`IndexOf` 신설. **[2026-08-11 세션]** `updateFn<UD>(item, index: number, offset: Source<number>, prev: T?, userdata: UD?): (T|nil, UD?)`로 시그니처 확정(`Slot.Offset`도 `Length`처럼 공개 필드로 신설) — `LayoutOrder` 등은 Slot이 자동으로 안 세팅, `index`/`offset` raw 값만 전달하고 실제 반영은 `updateFn`이 "버림/다시 그림/source만 갱신" 세 갈래로 직접 처리(재사용 Source에 미리 `Set` 후 결국 다시 그리면 무의미한 연산이 되므로). **[2026-08-11 세션, 여섯 번째]** `Slot:Single(state, updateFn)` 확정(`:List` 위의 순수 sugar) — Slot-in-Slot 중첩도 확정, 요소 타입 제약에서 `Slot` 배제 해제(`T = Instance | Slot<Instance>`), `Dispatch.setLength`/`setOffsetSource`를 Slot 자신을 owner 키로 재사용하는 재귀 `attachSlot`(새 프리미티브 없음), 파괴는 재귀 `Clear()` 대신 flat `destroySlotTree`+명시적 `unbindLifetime`. `Slot(initial?: {T})` 생성자 부활(순수 `:Add` sugar) + `_crudUsed`↔`_listed` 상호 배타 가드 신설. `base/bind-system-plan.md`의 `recompute` off-by-one 버그도 이 세션에 같이 수정됨. **[2026-08-11 세션, 일곱 번째]** 반응형 raw 요소(`Slot:Add`가 `State<T>`/`Source<T>`도 받음) 확정 — 새 메커니즘 아니라 `isState(element)`면 내부적으로 `Slot():Single(element)`(nested Slot)를 대신 삽입하는 순수 sugar(최초 검토했던 별도 position-keyed StoreBind 구독 안은 `None`/Length/Move-Swap 문제로 기각). `Slot:Single(state, updateFn?)`도 `updateFn` 선택 인자화(기본값 identity)로 이 sugar를 지지. `:List`의 `reconcile`도 nested-Slot을 반환하는 아이템의 `.Length`만큼 다음 형제 `index`가 건너뛰도록 `pos` 커밋 공식 수정 |
| `modifier-plan.md` | Modifier는 런타임 plug 아닌 정적 merge, immutable+clone 기반 체이닝 — 메커니즘 확정. **[2026-08-07 다섯 번째 세션 추가]** `:Apply(factory)` 팩토리 체이닝, `Overridden`(구 `Merge`→`Override`, 2026-08-08 세션에서 이름까지 확정) 값 결합+성능 기준, `:Peek`/`isState` 필드 읽기까지 전부 확정(`Peek`/`isState`는 이름만 용어 정리 라운드까지 잠정) |
| `purity-and-effects-plan.md` | 컴포넌트 "순수성"이 아니라 "이식성" 문제로 재정의 — 문서 경고 수준으로 확정 |
| `component-composition-plan.md` | 컴포넌트=플레인 함수, State/Source 읽기·쓰기 경계, Source가 State를 구조적으로 만족 — modifier/Ref 컴포넌트 경계 통과까지 전부 확정, 남은 건 API 이름뿐. **[2026-08-07 정리]** 폐기된 `StoreSource` 프록시 설계로의 역전 이력은 본문에서 빼고 `archive/store-source-proxy-reversed.md` 포인터로 압축 |
| `blocker-plan.md` | **[2026-08-07 신설]** `Blocker` — 여러 Source를 한꺼번에 바꿔도 파생값 재계산이 한 번만 되게, State 마일스톤(M3)과 함께 개발. 메커니즘+이름 확정 |
| `effect-plan.md` | **[2026-08-07 신설, 여섯 번째 세션에 확정]** `Effect(fn, state?)` — `state` 없으면 설치 1회+leaf 사망 시 확정 정리, 있으면 내부적으로 `state:Observer(...)`를 조합해 재실행+cleanup 체이닝(React `useEffect` 동형). Observer와의 관계 해소 완료 |
| `ui-shorthand-plan.md` | **[2026-08-07 `research/`에서 승격]** `UICorner`/`UIPadding`/`UIScale` 인라인 편의 키 — 이름(v1 `Corner`/`PaddingAll`/`Scale`에서 Modifier 필드명과 안 겹치게 `UI` 프리픽스로 확정)·메커니즘(Handler)·패키지 배치(quad-roblox 코어)·store-bind 가능성까지 전부 확정. 이미지 라운드 트릭(`RoundSize`)은 드롭 — `archive/ui-shorthand-roundsize-dropped.md` 참고. `v=nil`이면 `process` 자신이 만든 자식 제거(`retract` 아님) |
| `tag-plan.md` | **[2026-08-08 세 번째 세션 재설계, 2026-08-12 열한 번째 세션 메커니즘 정정]** `Tag(...)` — array-part 값 객체, `Modifier`와 같은 immutable clone 체이닝(`:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`), `CollectionService` 글루만 quad-roblox. `retract`가 이전 Tag가 걸었던 이름을 이름별 참조 카운트 맵에서 빼고(다른 위치가 겹쳐 쓰면 실제 `RemoveTag`는 skip), `process`가 새 Tag의 이름을 등록 — 여러 위치가 같은 이름을 겹쳐 가져도(웹 `className`류 합집합) 안전. 구 해시 파트 boolean 모델은 `archive/tag-hash-key-model-reversed.md`, 구 `assert(v==nil)` 메커니즘은 `archive/retract-always-fires-reversed.md` |
| `attribute-plan.md` | **[2026-08-07 여덟 번째 세션 신설]** 단일 키 `[AttributeKey<T> "Name"]`(구 `Attribute<T>`) — `SetAttribute(name, nil)`이 네이티브 지우기라 `None` 센티널과 가장 깔끔하게 맞아떨어짐. **[2026-08-11 아홉 번째 세션]** 여러 Store를 한 번에 attribute로 묶는 그룹 `Attribute(...)` 프리미티브 신설(`Tag`와 동형 array-part 값 객체, `Merged`로 헤테로지니어스 Store 합성), 이름 충돌 방지로 단일 키를 `AttributeKey`로 리네임(잠정). **[같은 세션 후속]** `AttributeKey(name)`이 이름별 weak 캐시로 동등성 보장하도록 확정되며, 그룹 Handler는 자기 완결형 재구현 대신 메모이즈된 키로 기존 단일 키 경로에 재귀 위임하는 걸로 개정(중복 구현 제거). **[2026-08-12 열 번째 세션]** 그룹/직접 쓰기가 같은 이름을 동시에 관리하는 충돌을 막기 위해 그룹은 공개 캐시 대신 `rawNew(name)` 전용 키+소유권 `Relate`로 전환. **[열한 번째 세션]** `retract`가 store 재발행마다 항상 불린다는 정정에 맞춰 `AttributeKeyHandler.retract`에 `v==nil` 가드 추가(더 이상 "retract 불필요" 아님, no-op일 뿐), 그룹의 "남아있는 이름" 위임도 매번 `retractUnder`를 먼저 부르도록 정정(체인 누수 방지) |
| `onchange-plan.md` | **[2026-08-10 세션 신설]** `OnChange(name)` — `GetPropertyChangedSignal` 바인딩 전용 DI 키, `Attribute`와 달리 제네릭 타입 파라미터 없음(콜백 타입은 인라인 명시, 이벤트 바인딩과 같은 급 트레이드오프). 전부 quad-roblox(`Handlers/OnChange.luau`), `State<function>`은 기존 이벤트 store-bind 메커니즘 재사용. **[2026-08-11 아홉 번째 세션 후속]** `AttributeKey`와 동일한 이름별 weak 캐시로 `OnChange(a) == OnChange(a)` 동등성 보장 |
| `relate-plan.md` | **[2026-08-08 신설]** `Relate` — `inst`를 weak 키로 하는 범용 릴레이션 프리미티브(`SetWeak`/`GetWeak`/`SetStrong`/`GetStrong`, 비싱글톤 생성자). 구 `base.perInstanceState(inst)` placeholder를 대체·정식 승격, `lifecycle-pattern.md`의 `bindLifetime`/`canExecute`가 그 위에 얹힘 |
| `tween-plan.md` | **[2026-08-12 세션, `research/`에서 승격]** 값-레벨 `Tween<T>` 래퍼(PropertyHandler가 소비, 구 특수 bind key 모델은 `archive/tween-special-bind-key-reversed.md`). 3-상태 릴레이션 슬롯(`{Tween,Value}\|true\|nil`), `T'=T\|Tween<T>` 타입 치환. 옵션 값 모양은 `Info: TweenInfo?` 우선+편의 필드 폴백, override는 `Tween.Cancel`(기본)/`Tween.Finish` 2값. `Animate(info)`는 `Tween` opts를 `T\|State<T>`로 받아 `:Apply`로 꽂는 sugar. 자연완료 시 per-instance 북키핑은 정리 안 해도 됨으로 확정(목표값 도달 상태라 부작용 없음, Completed 이벤트 구독 장치는 오버엔지니어링으로 판단). `initValue`는 사용자가 직접 처리(에이전트 범위 제외) |

## `reference/` — 온디맨드 참고 자료 (2026-08-07 신설)

| 문서 | 내용 |
|---|---|
| `quad-v1-architecture.md` | v1(`initreq/quad`) 내부 동작 스냅샷 — "이 문제를 안 반복하려면"의 기준선. **[2026-08-07 `base/`→`reference/` 이동]** v2의 결정 자체가 아니라 다른 문서가 인용하는 온디맨드 자료라 항상 읽을 필요는 없음 |
| `comparison-fusion-vide.md` | Fusion/Vide 아키텍처 비교 리서치 — 설계 결정 근거 자료(전파 모델 등 일부 서술은 이후 라운드에서 뒤집혔으니 `bind-system-plan.md` 쪽을 최신으로 볼 것). **[2026-08-07 `base/`→`reference/` 이동]**, `quadnomicon` 소재 후보 |
| `comparison-charm.md` | **[2026-08-09 신설]** littensy/charm(Roblox Zustand류) 비교 — `batch()`/`atom()`/수동 dispose Effect 3가지는 quad가 이미 기각한 패턴이라 반면교사, `None` 센티널은 독립 재확인, charm-sync의 diff/patch는 quad 미착수 네트워크 복제 영역의 첫 참고자료, Blocker의 "previous 값 비교" 미결 문제엔 정황 증거(생성 시 필수 `equals`, computed의 previous-in-getter) 제공 |

## `research/` — 아직 착수 전, 상의 필요

| 문서 | 내용 | 우선순위 |
|---|---|---|
| `existing-instance-bind-plan.md` | 이미 생성된 인스턴스 재바인드 — 착수 안 하되 "미지원" 확정도 안 함, 열린 가능성 유지 | 하 — v2 초기 스코프 제외 |
| `debug-tooling-plan.md` | 실물 Instance→코드 위치 역추적 Studio 플러그인(`quad-debug`) — 채널 실현 가능성(BindableEvent/Function 크로스 컨텍스트)까지 실측 검증 완료, 세부 API 이름·구현만 남음 | 하 — 사용자가 "quad 개발 완료 전엔 착수 못 함"으로 직접 후순위 지정, base 설계 시 훅 확장 지점만 고려 |
| `documentation-plan.md` | 문서 사이트 구조(초심자/api/심화/`quadnomicon` 4축, 백엔드별 트랙 분리) + UI 네이밍 컨벤션·Store 부작용 패턴·권장 이벤트 핸들링 3개 세부 문서 뼈대 | 하 — 착수 시점 미정, 구조/스코프만 합의된 상태 |
| `documentation-content-map.md` | 위 4축에 실제로 뭘 채울지 `base/` 전체를 초심자/api/심화/skip으로 서베이한 콘텐츠 맵 — 초심자 core loop 목차 초안 포함 | 하 — 문서화 착수 시점의 목차/우선순위표로 쓸 것 |
| `framework-comparison-findings.md` | quad vs Fusion/Vide/react-lua 정직한 비교(실 소스 근거) — quad 강점, 진짜 불리한 점 중 고칠 만한 것 3개, 못 고치는 트레이드오프 정리 | 하 — 사용자 검토 후 반영 여부 결정 대기 |
| `additional-primitives-plan.md` | **[2026-08-09 세 번째 세션, 전부 해소]** 마지막으로 남아있던 키 기반 동적 컬렉션 재조정도 `Slot:List(...)`로 확정되어 `base/slot-plan.md`로 승격 — 이 문서엔 새로 열린 설계 질문 없음, "빈 자리 아닌 것"/"문서화 백로그"/조사 소스 목록만 배경 자료로 유지 | 하 — 배경 리서치 기록용, 열린 결정 없음 |
| `pre-implementation-audit.md` | M0 착수 직전 크리티컬 감사(2026-08-06 신설) — `base/` 전체를 모호성/지연결정리스크/단순화후보 세 렌즈로 재검토, 11개 우선순위1(M0~M4 착수 전 확인 권장) + 11개 우선순위2 + 2개 단순화후보 | 상 — M0 착수 전 최소 우선순위1 항목 확인 권장 |
| `operator-sugar-plan.md` | **[2026-08-12 신설]** `Sum`/`Product`/`Not`/비트연산 등 `:Compute`/`:Apply`용 연산자 콤비네이터 슈가 — 메커니즘은 이미 확정된 계약(`Animate`와 동형 패턴) 재사용이라 확정, 네임스페이스 이름만 미정 | 하 — 구현은 맨 마지막(순수 슈가, 없어도 무방, 함수 간 의존 없음), 사용자가 직접 후순위 지정 |
| `v1-compat-plan.md` | v1 하위호환(compat) 레이어 — `quad-roblox-v1-compat` 패키지, v2→v1 단방향 브리지(`state:Observer()`+v1 프로퍼티 재대입), v2-in-v1/v1-in-v2 두 임베딩 방향의 기술 규칙까지 확정. quad2-try의 `quad-compat`은 빈 폴더로 실제 시도된 적 없었음을 확인 | 하 — Slot이 foreign Instance를 어떻게 다루는지만 Slot 코어 구현 시점까지 미결 |

## `archive/` — 완료됐거나 완전히 뒤집힌 것, 능동 참고 불필요

| 문서 | 내용 |
|---|---|
| `store-source-proxy-reversed.md` | [역전됨] 2026-08-04에 확정했던 `StoreSource` 프록시 설계(Store가 Source를 감춘 별도 프록시로 감쌈) — 2026-08-06 세 번째 세션에서 "Source가 State를 구조적으로 만족" 재구성으로 완전히 대체됨. 원문·역전 이유·신구 비교표 보존, `quadnomicon` 소재 후보 |
| `ref-phase-option-reversed.md` | [역전됨] `CreatedRef`의 `phase` 옵션 — 위치 기반 순서 + `PreRef` 신설로 대체됨 |
| `ui-shorthand-roundsize-dropped.md` | **[기각됨, 2026-08-07 신설]** v1 `RoundSize`(이미지 9-slice 라운드 트릭) — 네이티브 `UICorner`로 대체되어 포팅 불필요. 이 판단이 한 차례 "Corner/PaddingAll/Scale 숏핸드 전체가 불필요하다"로 과잉일반화됐다가 정정된 이력 포함 |
| `batch-rejected.md` | **[기각됨, 2026-08-07 신설]** lexical `Batch(fn)` — 코루틴 yield 위에서 구조적으로 위험해 기각, 값 기반 `Blocker`(`base/blocker-plan.md`)로 대체 |
| `context-rejected.md` | **[기각됨, 2026-08-07 신설]** `Context`(트리 하위 암묵 전파) + 대안이던 레이어드 Store 둘 다 기각 — 명시적 타입 강제 Store 전달로 충분하다는 판단 |
| `modifier-apply-mutable-rejected.md` | **[기각됨, 2026-08-08 신설]** `Modifier.Apply`/setter를 mutable로 바꾸는 방안(및 "Apply 경계에서만 clone" 절충안) — 둘 다 형제 서브트리 오염 방지가 clone 비용 절감보다 우선이라 기각 |
| `tag-hash-key-model-reversed.md` | [역전됨] 구 `Tag` 모델(해시 파트 boolean 키, 태그 개수만큼 키 갱신) — 2026-08-08 세 번째 세션에서 array-part 값 객체(`Tag(...)`, `:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`) 모델로 완전히 대체됨 |
| `agent-mistake.md` | **[에이전트 실수, 2026-08-07 신설]** 설계 반전이 아니라 에이전트가 문서 작성 중 개념을 혼동했다가 같은 세션 안에서 스스로 정정한 사례 모음(`canExecute`/`isHandlable` 혼동, `isSource` 불필요 오판) — CLAUDE.md 세션 로그의 중복 서술을 여기로 옮기고 포인터만 남김 |
| `quad2-try-research-findings-rejected.md` | **[기각됨, 2026-08-09 코퍼스 정리 신설]** quad2-try 이전 시도 리서치 전문(OOP 상속/커스텀 파서/Slot 스텁/`Pipe` copy-on-write 4가지 죽은 접근 + `:With` 이름 방증) — `base/bind-system-plan.md`에 남아있던 인라인 전체 서술을 이전, 결론 한 줄 포인터만 본문에 남김 |
| `observer-cleanup-contract-rejected.md` | **[기각됨, 2026-08-09 코퍼스 정리 신설]** `Observer` 자체에 React `useEffect`식 cleanup 반환 계약을 추가하는 안 — 클로저로 이미 충분해 기각, `Effect`가 opt-in 상위 계층으로 이 패턴을 제공 |
| `keyed-collection-state-method-rejected.md` | **[기각됨, 2026-08-09 코퍼스 정리 신설]** 키 기반 동적 컬렉션 재조정 프리미티브를 `state:Keyed(...)` State 메소드로 두려던 초안 — Source 미사용 컴포넌트가 접근 못 한다는 반례로 철회, 현재는 자유 함수로 확정 |
| `debug-channel-replicatedstorage-rejected.md` | **[기각됨, 2026-08-09 코퍼스 정리 신설]** quad-debug 채널을 `ReplicatedStorage`에 자동 생성하던 초안 — 게임 트리 오염 부작용으로 기각, quad 모듈 자신의 트리+`CollectionService` 태그로 대체 |
| `tween-special-bind-key-reversed.md` | **[역전됨, 2026-08-10 신설]** 구 Tween 모델(`[Tween(key,tweenData...)] = storeValue` 특수 bind key, 우선순위 최상위 Dispatch 핸들러) — 값-레벨 `Tween<T>` 래퍼 모델로 완전히 대체됨(`base/tween-plan.md`) |
| `onchange-per-property-codegen-rejected.md` | **[기각됨, 2026-08-10 신설]** `OnChange.PropertyName` 프로퍼티별 정적 코드 생성 — Attribute의 정적 지름길과 달리 (클래스 수 × 프로퍼티 수) 규모로 폭발해 기각, `OnChange(name)` 단일 팩토리로 대체 |
| `retract-always-fires-reversed.md` | **[역전됨, 2026-08-12 열한 번째 세션 신설]** "핸들러 타입이 안 바뀌면 retract 없이 process가 diff" — 실제로는 `retract`가 store 재발행마다 항상 불림(핸들러 타입 무관). `Tag`/`Ref`/`Slot`/`Attribute` 전부 이 오류 위에서 설계돼 있었음이 드러나 한 세션에 전부 정정 |

## 참고

- **저장소 소유자가 답해야 할 질문 전체 취합**: `.claude/question.md`
- **사람만 할 수 있는 일(로컬 조작/결정)**: 루트 `HUMAN_TODO.md`
- **원본 브레인스토밍(raw chain-of-thought)**: `.claude/initreq/raw-userinput.md`,
  `.claude/initreq/req.md` — 위 문서들로 나누기 전의 원본, 참고용 백업이니 그대로 둘 것
