# Quad 공식 문서 체계 및 아티클 로드맵

> **문서 상태**: Working Draft — 스캐폴딩(소형 모델 다패스) 뒤 **2026-09-09 사실성 검토·재작성 1차 완료**(아래 §4).
> **위치**: `docs/` — **[2026-09-09 사용자 결정]** 옛 `docs-ignoreme/`(git 무시)에서 레포 안으로 옮겨 커밋한다. 공개 시점은 `ROADMAP.md` 백로그 "문서 사이트" 항목.
> **기준 시점**: 2026-09-09 (M0~M11 코어 구현 완료, 포스트 리뷰 round1~9 종료, 2026-09-08 슈거 구간 반영 후)

---

## 1. 문서 철학 및 4개 트랙

Diátaxis(tutorial / how-to / reference / explanation) 4분면을 따르고, 그 앞에 퍼널 첫 단인 **Overview**(왜 Quad인가 — 2026-09-09 사용자 요청)를 둔다. `.claude/research/documentation-plan.md`(2026-08-06)의 원안은
how-to를 초심자 트랙에 녹이는 3축이었으나, 스캐폴딩 과정에서 how-to를 별도 트랙으로 두는 쪽으로 진행됐고 2026-09-09 검토에서 그대로
유지했다(설명 트랙은 `quadnomicon` 하나로 통합 — "심화"와 분리하지 않는다).

```
                   실용적 / 행동 중심 (Practical)
                               ▲
            [How-To Guides]    │    [Getting Started]
            태스크 지향 실전 레시피 │    선형적 학습 / 튜토리얼
 ◀─────────────────────────────┼─────────────────────────────▶
 이론적 / 구조 중심            │            구체적 / 참조 중심
           [The Quadnomicon]   │    [API Reference]
           프레임워크 내부론      │    공개 표면 및 계약 룩업
                               ▼
                   정보적 / 지식 중심 (Informational)
```

| 트랙 | 대상 독자 | 톤 | 핵심 목적 |
|---|---|---|---|
| **Overview** | 도입 여부를 판단하려는 엔지니어(퍼널 첫 단), quad v1 사용자 | 솔직, 대가를 같이 적음 | 무엇을 풀려 했고 무엇을 포기했나, 맞는 경우/맞지 않는 경우, Fusion/Vide 차이표, 심층 링크; v1에서 무엇이 왜 달라졌고 어떤 틀로 옮기나 |
| **Getting Started** | Quad를 처음 접하는 Roblox 개발자 | 친절, 선형, 최소 | 설치부터 첫 컴포넌트까지 core loop 완주 |
| **How-To Guides** | 실제 프로덕트에 도입하는 엔지니어 | 간결, 해결책 중심 | 디버깅, 폼 검증, 긴 목록, 외부 시그널, 테마, 헤드리스 테스트, `Claim`, v1 이관 |
| **API Reference** | 일상 사용자·프레임워크 확장자 | 엄밀한 시그니처·에러 문구 | 타입당 1페이지 심볼 룩업(core/sugar/roblox/extend), `D`는 표면만·Roblox 문서로 유도 |
| **The Quadnomicon** | 프레임워크 설계자, 아키텍트 | 분석적, 한계를 숨기지 않음 | Revision/EpochMap, Slot 부분합 트리, 메모리 토폴로지, 마커 타입, 디스패치 엔진 등 내부 설계 |

**2026-09-09 사용자 결정으로 없어진 트랙**: `best-practices/`(getting-started 03·skills와 중복, 안티패턴 레시피 포함 → 삭제),
`research/`(Context·Unwrap은 2026-09-08 구현돼 reference에 문서화됨, spring은 정본 `.claude/research/spring-plan.md`와 다른 허구 API
→ 삭제; 나중에 실물이 나오면 사실 기반으로 재작성), `reference/02 역전사 종합 원장`·`reference/03 최근 세션 해결 원장`(내부 설계사 —
publish 대상 아님. 역전된 설계는 quadnomicon 각 권이 "이런 시도도 있었지만 채택되지 않았다" 수준으로만 언급한다, 별도 섹션 없음).

---

## 2. 트랙별 문서 목록

링크는 상대 경로(`../<track>/<file>.md`)다(`site/sync-docs.py`가 사이트 경로로 치환). 각 파일의 제목이 곧 정본이라 여기 요약은 한 줄로만.

### Overview — 2편
- [`01-why-quad.md`](./overview/01-why-quad.md) — 왜 Quad인가: 풀려던 문제 셋, 맞습니다/맞지 않습니다(오늘 시점 차단기 열), 설계 선택 일곱(+덤)의 "이전 선택과 그 한계 → 우리가 넘은 방법 → 그 대가/더 나쁜 점 → 심층 링크", Fusion/Vide 차이표(근거 있는 축 다섯, 수치 없음) + 우위 여섯/열위 여덟 목록. 사용자 의도: *"기술자로써 선택의 갈래를 좁혀주는"* 퍼널 첫 단 — 문서 흐름과 무관, 랜딩의 첫 액션이 여기로 온다. **[2026-09-09 사용자 프레이밍으로 재작성 — 검토 대기]**
- [`02-from-v1.md`](./overview/02-from-v1.md) — quad v1에서 오는 분께: 없어진 것과 왜 없앴나(표 10행, 근거는 v1 내부 스냅샷 범위만), 새로 생긴 것이 v1의 어떤 자리를 메우나, 이관 틀 셋 — (a) 화면 단위 재작성이 주 경로, (b) v1·v2 화면 분할 공존은 **지원 경로**(양방향 브릿지, 경계를 넘는 건 항상 평범한 값, GC 상호작용은 [2026-09-10 기준] 미실측이라 핸들의 주인을 명시), (c) `Claim`으로 v1 트리 인계는 **비권장**(이중 소유) — 그리고 v1·v2 동시 로드 공식 허용 + 조건 셋, 새로 짤 때 전제 여섯. 사용자 결정 2026-09-10(§4 참고). v1 사용자는 회사 내부·외부 둘 다라 "안심시키기"와 "옮길 값어치" 둘 다 담는다. 스킬 링크 둘은 사이트에서 평문으로 벗겨진다(`sync-docs.py`).

### Getting Started (시작하기) — 4편
- [`00-installation.md`](./getting-started/00-installation.md) — 설치 경로 셋(pesde+Rojo / Wally+Rojo / `.rbxm`). **셋 다 아직 제공되지 않는다**(각 절 머리의 날짜 표시가 소스 — 실물이 생기면 그 표시만 지운다). `quad-base`와 `quad-roblox` 둘을 require하고 `Quad:UseProvider(QuadRoblox)`로 백엔드를 설치한다는 것이 핵심.
- [`01-core-mental-model.md`](./getting-started/01-core-mental-model.md) — 가상 DOM 없음, `Source`는 값을 쓸 수 있는 `State`, 물리 트리와 반응성의 분리.
- [`02-quickstart-counter.md`](./getting-started/02-quickstart-counter.md) — 위에서 아래로 이어 붙이면 도는 카운터 하나 + `Animate`/`Tween`. mock 백엔드에서 실행 확인됨.
- [`03-component-composition.md`](./getting-started/03-component-composition.md) — 컴포넌트=평범한 함수, `props.Modifier or None`(배열 부분, nil-hole), Modifier 우선순위 셋, 타입드 Modifier 팩토리, `Tag`/`Attr`.

### How-To Guides (실전 레시피) — 8편
- [`01-debugging-and-troubleshooting.md`](./how-to/01-debugging-and-troubleshooting.md) — 에러 메시지 모양(`주어: 이유 (got X)`)과 표면 blame의 한계, 현업 함정 여섯(문구는 소스 verbatim).
- [`02-form-validation-pattern.md`](./how-to/02-form-validation-pattern.md) — `Store` 필드 + 후행 의존성 `:Compute`로 실시간 검증·버튼 제어.
- [`03-virtualized-infinite-scroll.md`](./how-to/03-virtualized-infinite-scroll.md) — `Slot:List` 계약(`updateFn(item, index, offset, prev, ud)`, `prev` 반환 재활용, `Detach`), `LayoutOrder`는 사용자가 `index`/`offset`에서 직접 바인딩, 윈도잉과 "안 해주는 것".
- [`04-network-and-input-bridge.md`](./how-to/04-network-and-input-bridge.md) — `RemoteEvent`·`UserInputService`를 `Source:Set`으로 격리, `Effect` cleanup과 생명주기 훅.
- [`05-theme-and-dynamic-styling.md`](./how-to/05-theme-and-dynamic-styling.md) — 디자인 토큰, `state:Apply(q.Animate{...})`, `Modifier.Overridden`, 명시적 `q.Context`로 계층 건너 전달.
- [`06-headless-testing.md`](./how-to/06-headless-testing.md) — `./scripts/test.sh`(판정은 exit code)와 테스트 내부 mock 백엔드. 공개 `quad-mock`은 백로그.
- [`07-studio-ui-binding-and-claim.md`](./how-to/07-studio-ui-binding-and-claim.md) — `q.Claim(inst, q.D.Mapper...)` 디스크립터, claim-once·직계 자식 전부 매핑·공동 소유 컨테이너는 대상 밖.
- [`08-migrating-from-v1.md`](./how-to/08-migrating-from-v1.md) — quad v1(`Init(id)`/`Class "Frame"`/`Store.GetStore`)에서의 이관: 툴체인 플래그 넷, 개념 대응표, 제거된 기능과 경로, strict 블로커 열여덟.

### API Reference — 손으로 관리하는 심볼 레퍼런스(26페이지 + 색인)
**[2026-09-09 사용자 결정]** 관례 조사(Roblox 엔진 레퍼런스·Fusion·Vide·Lune·Squash) 뒤 확정: **타입당 1페이지**, 메소드는 `##` 절(앵커), 페이지 템플릿은
시그니처(quad-types에서 복사) → 인자 표 → 반환 → 동작(불변식·**에러 문구 verbatim**) → 예제(mock 실행·신 솔버 검사) → 관련. **생성기 없음** — 손으로 쓴 심볼은
전부 손으로 "관리"한다(사용자: 아키텍처가 견고해 자동화 이점이 작다). `D.<Class>` 31개 페이지도 만들지 않는다 — 표면 한 페이지·한 예시만 두고 각 클래스의 프로퍼티·이벤트는
Roblox 공식 레퍼런스로 유도(React가 DOM 요소를 설명하지 않듯). 빠진 심볼은 `scripts/doc-coverage.py`(test.sh 게이트)가 잡는다.
- [`00-index.md`](./reference/00-index.md) — 심볼 → 페이지 색인.
- `core/`(quad-base) 12편 — [모듈](./reference/core/01-quad-module.md)(New/RunInit/AddPlugin/UseProvider) · [Source](./reference/core/02-source.md) · [State](./reference/core/03-state.md) · [Store](./reference/core/04-store.md) · [Observer·Effect](./reference/core/05-observer-effect.md) · [Blocker·Gate](./reference/core/06-blocker-gate.md) · [Slot](./reference/core/07-slot.md) · [Ref](./reference/core/08-ref.md) · [Modifier](./reference/core/09-modifier.md) · [Tag·Attr](./reference/core/10-tag-attr.md) · [센티널·수명 스텁](./reference/core/11-lifetime-sentinels.md) · [술어 `is*`](./reference/core/12-predicates.md).
- `sugar/` 5편 — [Context](./reference/sugar/01-context.md) · [Operator](./reference/sugar/02-operator.md) · [Debounce·Throttle](./reference/sugar/03-debounce-throttle.md) · [생명주기 훅](./reference/sugar/04-lifecycle-hooks.md) · [Fallback·Traceback](./reference/sugar/05-fallback-traceback.md).
- `roblox/`(quad-roblox, 배지 Roblox) 6편 — [설치·확장 표면](./reference/roblox/01-install.md) · [`D`](./reference/roblox/02-d.md)(표면 한 예시 + Roblox 문서 유도, 레거시 프로퍼티) · [`D.Modifier`](./reference/roblox/03-d-modifier.md) · [Claim·Mapper](./reference/roblox/04-claim-mapper.md) · [OnChange](./reference/roblox/05-onchange.md) · [Tween·Animate](./reference/roblox/06-tween-animate.md).
- `extend/`(배지 Advanced) 2편 — [백엔드 프로바이더 규약](./reference/extend/01-backend-provider-contract.md)(옛 reference/01 에세이 그대로) · [Dispatch·Handler 계약](./reference/extend/02-dispatch-handler-contract.md).

### The Quadnomicon — 11권
> Rustonomicon 스타일 — 초보자용이 아니다. 입문은 [Getting Started](./getting-started/01-core-mental-model.md)부터.

- [Vol. 1](./quadnomicon/01-revision-and-epochmap.md) 32-bit Wrapping Revision과 EpochMap — `bit32.bnot(-rev)` 랩어라운드 감소(성능이 이유), 2^32 랩은 도달 가능하지만 오판정 조건이 한 점.
- [Vol. 2](./quadnomicon/02-slot-prefix-sum-tree.md) Slot-in-Slot 부분합 트리 — `rawSplice`의 부기 먼저·물리 한 번, Roblox `nativeMove`/`nativeSwap`는 의도된 no-op.
- [Vol. 3](./quadnomicon/03-luau-memory-topology.md) Luau 메모리 토폴로지 — Ephemeron 없는 weak 테이블과 `Relate`, `bindLifetime` 앵커, "quad가 만든 Instance는 Destroy로만 회수된다".
- [Vol. 4](./quadnomicon/04-covariant-markers.md) 공변 마커 — 입력 자리의 `StateMarker<T>`(11팔 → 4팔), 한도 플래그 넷의 계기.
- [Vol. 5](./quadnomicon/05-non-destructive-portal-and-ownership.md) 비파괴 언마운트와 소유권 공리 — 비파괴는 `State<Slot>` 교체와 `Owned = false`에 한정, 기본 `Owned = true`는 파괴.
- [Vol. 6](./quadnomicon/06-liveness-gate-and-isolation.md) 단일 인자 생존 게이트 — `canBound(v) == not canExecute(v)`, GC 앵커는 `nativeClaim`의 `ClassName` 커넥션.
- [Vol. 7](./quadnomicon/07-instance-identity-and-gc-philosophy.md) 인스턴스 신원·네이티브 GC·`Claim` 계약.
- [Vol. 8](./quadnomicon/08-extensible-dispatch-engine.md) 디스패치 엔진 — `Handler` 계약(`isHandlable`/`priority`/`process → retractor`), 밴드 HIGH/NORMAL/LOW/FALLBACK, `keyType` 버킷, (A)/(B) 하강 diff.
- [Vol. 9](./quadnomicon/09-fragment-breakthrough-and-domless-slot.md) 형제 여럿을 반환하는 컴포넌트와 DOMless Slot 트리.
- [Vol. 10](./quadnomicon/10-multi-backend-abstract-machine.md) 다중 백엔드 추상 기계 — 주입 op 묶음, 생명주기 넷, `UseProvider`(성공 후 마킹).
- [Vol. 11](./quadnomicon/11-static-grepability-and-error-architecture.md) 정적 grep 가능성·표면 blame·에러 아키텍처 — 리터럴은 raise 줄에 통째로(보간은 씀), `setFuncLevel(level, ...fns)`는 nil에 즉시 던짐.

### Web Site & Tooling — [`site/`](./site)
Astro + Starlight(Zero-JS 기본, Pagefind 검색, Expressive Code, `ko/`·`en/` 폴더 i18n). [`site/sync-docs.py`](./site/sync-docs.py)가
overview·getting-started·how-to·quadnomicon·reference 다섯 트랙을 하위 폴더까지 `site/src/content/docs/ko/`로 복사하며 상대 링크를 사이트 경로로 치환하고 본문 첫 H1을 지운다(Starlight가 title로 그린다). **[2026-09-09] 첫 빌드 성공**(`npm run build`, Starlight 0.32). `en/`은 아직 index만.

### Agent Tooling — [`skills/quad-ui-dev/`](./skills/quad-ui-dev)
AI 코딩 에이전트용 스킬(영문 유지 — 토큰 경제성). [`SKILL.md`](./skills/quad-ui-dev/SKILL.md)(온톨로지·금지 패턴·strict 타입 요구사항),
[`references/code-recipes.md`](./skills/quad-ui-dev/references/code-recipes.md)(mock에서 실행 확인된 레시피 여섯),
[`references/rules-and-invariants.md`](./skills/quad-ui-dev/references/rules-and-invariants.md)(소스 verbatim 에러 문자열 → 처방),
[`references/v1-migration.md`](./skills/quad-ui-dev/references/v1-migration.md)(v1 코드 이관 — 대응표·제거된 기능·strict 블로커).
인간용 트랙과 내용이 겹치는 것은 의도된 것이다(사용자, 2026-09-09).

---

## 3. 큰 에이전트(Auditor/Writer)를 위한 검토 지침

1. **코드가 진실이다.** 인용된 심볼·시그니처·에러 문자열은 `quad-base/src`·`quad-roblox/src`·`quad-types/src`와 스펙(`quad-*/test/spec.*.luau`)에서
   grep으로 확인한다. `.claude/base/`는 확정 설계, `.claude/archive/`는 기각된 설계 — 후자를 현행처럼 쓰지 않는다.
2. **예제는 돌아야 한다.** 설치 프롤로그(`Quad:UseProvider(QuadRoblox)`)가 있어야 `q.D`가 생긴다. 스니펫은 `quad-base/test/mock.luau` 위에서
   실제로 실행하고, 신 솔버(`luau-lsp --flag:LuauSolverV2=true`, `scripts/test.sh`와 같은 플래그·defs)로 타입 검사한다.
3. **검증 안 되는 것은 지운다.** 측정 없는 성능 수치, Fusion/Vide/React 내부 비교(`.claude/reference/comparison-fusion-vide.md`가 지지하는 범위만),
   "수학적 증명" 어투, 사용자 인용문 창작, `H-nnn`/`Q-nn` 원장 번호는 사용자 문서에 두지 않는다.
4. **어조**: 위 표 그대로. 한국어 우선(코드 심볼은 영문 토큰 그대로), `skills/`만 영문.
5. **링크**: 문서 간 링크는 상대 경로(`../<track>/<file>.md`, 레퍼런스 하위 폴더는 `../../<track>/…`·`../core/…`; `site/sync-docs.py`가 재귀 복사하며 사이트 경로로 치환). frontmatter(`title`/`description`)는 원본에 둔다(사용자 결정) — sync가 없으면 실패한다. `.claude/`·소스 파일로의 링크는 두지 않는다
   (사용자에게 없는 경로) — 소스는 필요할 때 평문 파일명으로만 언급.

---

## 4. 2026-09-09 검토 기록

- **검사**(opus 다섯, 트랙별): 모든 트랙에서 설치 절차 누락(`UseProvider`), `quad.State<T>`류 타입 표기 오류, 근거 없는 성능 수치가 공통이었고,
  reference/01·quadnomicon 08·10·how-to `06-headless-testing`·`07-studio-ui-binding-and-claim`(당시 번호 05·06)은 계약 자체가 허구였다(존재하지 않는 op·핸들러·우선순위·API). 옛 reference/03의 Q37~Q66은 프로젝트
  원장의 Q번호와 충돌하는 출처 불명 블록이었다.
- **재작성**(opus 여섯 + 00-installation 하나): 위 §3 규칙으로 전 파일 재작성, 스니펫은 mock 실행·신 솔버 타입 검사. 원본은 세션 스크래치에 스냅샷.
- **소스로 전파된 발견**(재작성 중 실측): `quad-types`의 훅 주석이 처방하던 `q.OnCreated(function(inst: Frame))` 형태는 신 솔버에서 죽고
  `q.OnCreated<<Frame>>(fn)`만 통과(`typing-limits.md` 8.16, 주석 정정됨); `[q.AttrKey("Hp")] = v` 해시 키는 런타임 정상이나 strict에서 생성 prop 타입에
  인덱서가 없어 에러 — **사용자 결정(2026-09-09): 타입은 열지 않는다**, 문서는 배열 부분 `Attr`/`StringAttr` 형태를 안내; `Font = Enum.Font.X`는 생성 `D`에 없었음
  (`Hidden` 태그 — Deprecated가 아님) — **사용자 결정(2026-09-09): Deprecated 전부 + Hidden `Font`/`Transparency`를 되살린다** → **[2026-09-09 적용 완료]**
  Studio 실측(`HUMAN_TODO.md` 12 — `ReflectionService`가 넷 다 `Permits.Write == Edit`로 준다)이 확인된 뒤 `scripts/gen-d.py`에 반영했다(`PROP_TAG_LEGACY`/
  `HIDDEN_NAME_KEEP`, 실측 원장은 `.claude/audit/deprecated-props-spike-2026-09-09/REPORT.md`). 이제 `Font`/`FontSize`/`TextWrap`/`Transparency`가 생성 `D`에
  다시 있고 `-- @deprecated (Roblox <tags>)` 주석이 붙는다 — **문서의 권장은 그대로 `FontFace`**(현행 API), `Font`는 v1 마이그레이션용 레거시로만 안내한다.
  ⚠️ 작성 지점 경고는 불가(테이블 키 자동완성은 독 주석도 deprecated 태그도 안 싣는다 — 실측) → 경고는 문서가 하는 수밖에 없다.
- **[2026-09-09 밤] API 레퍼런스 26페이지 신설**(§2 참고) — 작성 다섯·검사 둘·수정 둘, 커버리지 게이트 154/154, 사이트 첫 빌드 103페이지. `en/` 번역은 잠정 유보(사용자가 여러 번 보고 실개발자 조언을 모은 뒤).
- **[2026-09-10] 배포 준비** — 설치 문서 2단계의 "[2026-09-09 기준] 열린 항목"(설치 레이아웃)은 레포 밖 실제 설치로 확인해 닫았고, `roblox_sync_config_generator` 캐비엇을 추가했다. 버전 정책(사용자 결정): 레지스트리는 `3.0.0`부터, v1은 `master`. 루트 `README.md`·`CHANGELOG.md`·`LICENSE`(MIT) 신설 — 루트 README는 이 문서 체계로 들어오는 바깥 입구다. **같은 날 저녁**: 넷(`quad_base`·`quad_types`·`quad_error`·`type_version_check`)을 luau·roblox 양 타깃으로 게시하기로 결정(사용자) → 설치 문서 2단계는 roblox 프로젝트가 `roblox_packages/` 하나만 매핑하는 것으로, 퀵스타트·설치 3단계·README의 require 경로도 `roblox_packages.quad_base`로 바뀌었다(소비자 프로젝트 실측은 게시 뒤). **같은 날 밤**: 버전 리터럴 3.0.0으로 bump(설치 스니펫 `^3.0.0`), 사이트는 Cloudflare Pages 루트 배포로 전환(base `/`, 로고·파비콘, `docs/site/DEPLOY.md`·`npm run deploy`). 게시 뒤 지울 "아직 제공되지 않음" 표시는 HUMAN_TODO 15.2가 목록. `docs/getting-started/00`의 `0.0.0` 리터럴은 릴리즈 때 `scripts/check-version.py bump`가 목록으로 찍어 주니 손으로 고친다.
- **[2026-09-10] 오버뷰 2편 `02-from-v1.md` 신설**(§2 참고) — 사용자 제안(*"quad v1 유저들에 대한 인게이지먼트가 부족할지도"*)과 결정 셋: v1 사용자는 회사 내부(가장 큰 프로젝트에 지금도 사용)·외부 둘 다 / 이관 틀은 (b) 화면 단위 공존 지원·(c) `Claim` 인계 비권장, 브릿지는 양방향이되 *"v1 경계로 넘어가는건 항상 실측값"*, GC 상호작용은 미실측(잠정 백로그, *"당장은 가능한 것 부터 차근차근"*) / v1·v2 동시 로드 공식 허용 + 조건 셋(v1이 전역 테이블에 상태를 두지 않음은 v1 소스에서 확인). 작성은 opus, 검증은 메인(v1 심볼·v2 시그니처·링크 32건). 스니펫 없음.

---

## 5. 프로젝트 총괄자(설계자) 핵심 결정 사안 및 핸드오버 원장 (Handover Registry)

> **후속 작업 에이전트 필독**: 사용자와의 스캐폴딩 세션에서 확정된 문서화 기준. **⚠️ [2026-09-09 정정]** 이 절의 초판은 소형 모델(gemini flash)이
> 옮겨 적은 것이라 코드·`.claude/base`와 어긋난 항목이 여럿 있었다. 사용자 결정(2026-09-09): *"전부 .claude 와 실코드를 기반으로 정정 … 그 모델의 말을
> 믿을 필요가 전혀 없음."* 아래는 정정본이며, 이 절과 코드가 다시 어긋나면 **코드와 `.claude/base`가 이긴다.**

### 1) 문서 철학 및 언어 전략
- **한국어 우선**: 모든 인간용 문서는 한국어로 먼저 완결·검증한 뒤 영문 트랙. `skills/`는 영문(에이전트용).
- **용어 원어 표기**: `Source`, `State`, `Store`, `Slot`, `Modifier`, `Ref`, `PreRef`, `PostRef`, `Compute`, `Tween`, `None`, `Attr`, `Tag` 등 코드 심볼은 번역하지 않는다.
- **Quadnomicon 프레이밍**: Rustonomicon 스타일, "초보자용 아님" 경고 + Getting Started 링크.
- **타겟 도메인**: Roblox 클라이언트 UI(`ScreenGui`/`GuiObject`) 95% 이상. 3D·서버 확장은 "타입만 맞추면 생성 가능"으로만.

### 2) 패키징 및 배포 툴체인 셋 — **[2026-09-09 기준] 셋 다 아직 제공되지 않음**
1. **pesde + Rojo**(1순위): pesde는 의존성 해결만 하므로 Rojo 결합 필수. 게시 이름은 `qwreey/quad_base`·`qwreey/quad_roblox`(하이픈 불가, 밑줄),
   roblox 타깃 설치 폴더는 `roblox_packages/`(`Packages/`가 아님). 소비자는 **두 모듈을 모두** require하고 `Quad:UseProvider(QuadRoblox)`.
   ~~`@game/Packages/quad` alias~~ — 이 레포는 커스텀 alias를 쓰지 않으며 그런 경로를 권장할 근거가 없다(정정).
2. **Wally + Rojo**(2순위, 레거시 호환): 프로젝트 자체 툴체인으로는 기각됐지만(`project-setup-plan.md`), 소비자 경로로는 유효 — 사용자 결정(2026-09-09) *"셋 다 유효한 경로는 맞음"*.
3. **Standalone `.rbxm`**(3순위): 릴리스가 생기면. ~~`github.com/qwreey-bot/quad/releases`~~는 에이전트 포크라 배포처가 아님(정정).
사용자: *"아직 존재하지 않다는 해딩만 존재하면 되고, 그것만 나중에 해결되면 지우는게 나음."* — 각 절 머리의 날짜 표시가 그 헤딩이다.

### 3) 반응형 온톨로지 및 연산 규칙
- **온톨로지**: `Source`는 값을 쓸 수 있는 `State`(`Set`/`Emit` 추가). `State`에 공개 생성자는 없다(`q.State`는 없음) — 파생은 `:Compute`/`:With`/`:Apply`/`:Gate`로만 생긴다.
- **`:Compute(fn, ...deps)`**: 후행 의존성이 노드 하나로 끝나는 기본형. `fn(self, prev, ...depHandles)` — 전부 **핸들**이라 `:Get()`으로 읽는다.
  `:With(...)`는 노드가 하나 더 생기지만 **정식 지원 경로**다(~~금지~~ 정정 — `source-state-plan.md`가 채택). 신 솔버 strict에서는 프로퍼티 자리의 인라인 무주석 `:Compute`가 에러라
  타입 붙인 지역 변수로 뺀다(`typing-limits.md` 8.13).
- **중첩 State**: `State<State<T>>`는 **정상 지원**(StoreBind가 재귀 언랩, ~~미지원~~ 정정). 런타임이 State 값으로 거부하는 것은 **Modifier뿐**(~~Store도 금지~~ 정정) —
  `State<Store>`는 되지만 필드 읽기가 반응형이 아니므로 `q.Operator.Index<<V>>(key)`를 쓴다.
- **폼 리셋**: 스토어를 통째로 바꾸지 말고 필드별 `:Set` 또는 슬롯 언마운트/재생성.
- **`Blocker`**: 읽기를 지연시키지 않고 emit 전파만 묶는다. **`state:Apply(blocker)`로 붙여야 효력**이 있다(`On`/`Off`만으로는 아무 일도 없음).

### 4) Modifier 및 디스패치 불변식
- **네임스페이스 유지**: `D.Frame { ... }` 그대로(구조분해 안 함).
- **nil-hole 방어**: 선택적 Modifier/Ref는 **배열 부분**에 `props.Modifier or None` — 이유는 배열 리터럴의 `nil`이 순회를 깨기 때문(디스패치 엔진의 "구분 불가"가 아님, 정정).
  `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Slot`/`Modifier`는 해시 키 값으로 올 수 없다(런타임 거부).
- **우선순위 셋**: ① 인라인 해시 키 최우선, ② 배열 내 뒤쪽 Modifier 승(역방향 스캔 first-writer-wins), ③ `Modifier.Overridden(A, B)`/`A:Overridden(B)`는 B 승.
- **타입드 Modifier 팩토리**: `D.Modifier.<Class>()` 빌더 체인 또는 `D.Modifier.<Class>{...}`. 다운캐스트는 **`mod:AsFrame()`류(생성 `As<Name>` 키)가 검사형**, `mod:As<<T>>()`(타입 인자만, 런타임 무동작)와 `mod:As(name)`(이름 존재만 확인)은 **무검사**(~~"`:As<Name>()` 검사형" 표기~~ 정정).
- **`Parent`는 프로퍼티가 아니다** — 만든 뒤 밖에서 `.Parent =`.

### 5) 인스턴스 바인딩 및 Ref 생명주기
- **`PreRef`**: 속성·자식 처리 전 1회 발화. 이벤트 콜백 안에서는 `ref:Unwrap()`(비어 있으면 에러)으로 non-nil을 얻는다. 타입은 `QuadTypes.Ref<Frame?>`처럼 nil을 넓힌다.
- **`PostRef`/`OnRendered`**: 자기 속성·자식 처리 뒤 1회 발화. **부모에 붙었는지는 보장하지 않는다**(`AbsoluteSize` 읽기 예제 금지).
- **`Ref:Wait()`**: `coroutine.yield` + `:Set`이 `coroutine.resume` — **항상 다음 `:Set`을 기다린다.** 선검사 관용구 `if ref.Value then … else ref:Wait().Value`.
- **Ref 보관 금지**: Modifier 필드에 Ref를 넣으면 즉시 에러(이유: 쓸모 있는 use case가 없어 조용한 UB 대신 막음).
- 훅 타입 인자: `q.OnCreated<<Frame>>(fn)` 명시 형태만 통과(`typing-limits.md` 8.16).

### 6) Slot 및 물리 리오더링
- **Roblox 물리 리오더링 부재**: `nativeMove`/`nativeSwap`는 의도된 no-op(순서는 부기값, 합성 폴백은 `.Parent` 두 번 → `AncestryChanged` 재발화).
- **`LayoutOrder`는 사용자 몫**: quad는 `updateFn`에 `index`(이 Slot 안의 물리 위치)와 `offset`(`Source<number>`)만 넘긴다. 자동 `LayoutOrder`는 기각된 설계
  (~~`LayoutOrder = SlotOffset + ItemIndex` 공식~~ 정정 — 정본 관용구는 `slot-plan.md`의 `:With(offset):Compute`).
- **재활용**: `updateFn(item, index, offset, prev, ud)`에서 `ud`에 `Source`를 보관하고 `ud.src:Set(new)` 후 `return prev, ud`. `ud`에 Instance를 담지 말 것 — 잠깐 떼어둘 땐 `return q.Detach`.
- **`Owned`**: `:List`/`:Single` 기본 `Owned = true`는 빠진 요소를 파괴. 비파괴는 `Owned = false`와 자식 자리의 `State<Slot>` 교체뿐. `Slot { State<Instance> }`는 내부적으로 `Single(state, nil, { Owned = false })`.
- **순환**: `A:Add(B); B:Add(A)`는 즉시 런타임 에러(~~무한 재귀~~ 정정). 성능 수치(O(1) 등)는 적지 않는다.

### 7) `Claim` 및 Studio 협업
- **패턴**: Studio 템플릿 `:Clone()` 뒤 `q.Claim(clone, q.D.Mapper...)` — 둘째 인자는 props가 아니라 **매퍼 디스크립터**(1회용). ~~"5~10배 빠름"~~은 미실측(정정, 수치 삭제).
- **계약 셋**: ① claim-once(이중 claim은 `nativeClaim: Instance is already claimed by quad`), ② **그려지는 직계 자식은 전부 매핑**(부분 매핑 기각 — ~~"직계 자식 전속 관할권"~~ 정정),
  ③ `PlayerGui`류 공동 소유 컨테이너는 **대상 밖**(런타임 검사 없음 — 전용 `ScreenGui`를 만들어 거기에).

### 8) `Tag`와 `Attr`
- **`Tag`**: 참조 카운트 합집합 — 한 곳이라도 요구하면 유지. 이름 리스트에 `None`은 못 넣는다(필터).
- **`Attr`**: `Attr { Key = None }`도 **State가 `nil`이 된 경우도 삭제**(`setAttr(inst, name, nil)`). 값이 남는 것은 그룹이 교체되어 이름이 사라질 때뿐(retractor가 `setAttr`를 안 부름).
  ~~"State nil = 언바인딩/동결"~~ 정정.

### 9) `Effect` vs `Observer` 및 백엔드 계약
- **`q.Effect(fn, ...deps)`**: 다중 의존성, cleanup 반환은 **선택**, 설치 시 동기 1회 실행, `onDestroying` 훅.
- **`state:Observer(fn)`**: 콜백은 **값이 아니라 State 핸들**을 받는다. 등록 시 1회 발화한 뒤 **구독 상태가 아니다** — 배열 부분에 넣어 인스턴스에 묶거나 `:Subscribe()`해야 이후 변경이 온다(~~GC에만 의존~~ 정정 — Observer도 `bindLifetime`으로 묶인다).
- ~~재귀적 트리 파괴 불변식(비-Roblox 프로바이더 의무)~~ — 그런 계약은 없다(삭제). 백엔드 계약의 전부는 reference/01의 op 목록이다.

### 10) 선언적 애니메이션
- **`state:Apply(q.Animate{ Time, Style, Direction, Override, CanAnimate … })`**: State 값을 `Tween` 값으로 감싸는 팩토리.
- **`q.Tween{ Value, Time, Style, Override = "Cancel"|"Finish", Dedup }`**: 옵션 테이블 **하나**, `Value`는 plain(State 금지). 첫 세팅은 스냅, 같은 목표 `Value`면 트윈 미생성(`Dedup = false`로 해제), `Override` 생략 시 필드는 비어 있고 소비 측이 Cancel로 처리.

### 11) 웹 문서화 도구 — Astro + Starlight
Docusaurus 대신 `lune-org/docs`와 같은 Astro + Starlight. Zero-JS 기본, Pagefind, Expressive Code, 폴더 i18n, 단일 `astro.config.mjs`.

### 12) AI 에이전트 스킬(`skills/quad-ui-dev/`)
인간용 서사와 분리된 토큰 경제형 스킬. React/Roact 습관 함정(nil-hole, `Ref:Wait` hang, Frame에 `Activated` 없음, strict 타입 요구사항 등)을 소스 verbatim 에러 문자열과 함께 차단.

### 13) 순수 슈거 그룹(2026-09-08 구현) — 정본은 reference/02
`ref:Unwrap()`(`StripNil<T>`), `q.Context()`/`q.Context.Provider(name?) :: QuadTypes.Provider<T>`(`Get` 없으면 에러·`Peek` nil·`Set` 체이닝, 사용자: 컴포넌트 품질을 위해 필요),
`q.Debounce{}`/`q.Throttle{}`(주입 시간 op 위, `Handle`은 `:Apply` 시점 주입), `q.Operator.*` 열넷(`Index<<V>>` 포함; `And`/`Or`·비교·`Sub`/`Div`는 의도적으로 없음),
`q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`, `q.Fallback`/`q.Traceback`(던지기 전 부분 트리는 회수되지 않음).
