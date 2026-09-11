# Quad 문서 안내

문서 사이트: <https://quad.qwreey.moe/>

스니펫은 mock 백엔드 위에서 실제로 실행하고, 신 솔버 strict로 타입 검사한다.

---

## 1. 문서 철학 및 4개 트랙

Diátaxis(tutorial / how-to / reference / explanation) 4분면을 따르고, **Overview**(왜 Quad인가)는 퍼널 첫 단이 아니라 시작하기 뒤에 오는 **다른 도구와의 비교 문서**(Docusaurus "Comparison with other tools" 방식)다 — 사이드바·랜딩 첫 액션은 시작하기. how-to는 별도 트랙으로 두고, 설명 트랙은 `quadnomicon` 하나로 통합한다 — "심화"와 분리하지 않는다.

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
| **Overview** | 이미 Fusion·Vide·react-lua를 쓰며 "넘어올 값이 있나"를 판단하려는 엔지니어, quad v1 사용자 | 솔직, 대가를 같이 적음, 예정된 것은 예정으로 | 도구별 "잘하는 것 → 겪는 문제 → Quad의 풀이 → 넘어올/안 넘어올 이유", 차이표, 설계 선택과 대가, 없는 것의 이유(일부러/계획/한계); v1에서 무엇이 왜 달라졌고 어떤 틀로 옮기나 |
| **Getting Started** | Quad를 처음 접하는 Roblox 개발자 | 친절, 선형, 최소 | 설치·설정부터 목록·애니메이션까지 카운터 하나를 키우며 완주 |
| **How-To Guides** | 실제 프로덕트에 도입하는 엔지니어 | 간결, 해결책 중심 | 컴포넌트 경계 규약, 폼 검증, 긴 목록, 외부 시그널, 테마, 헤드리스 테스트, `Claim`, v1 이관, 그리고 부록인 디버깅 |
| **API Reference** | 일상 사용자·프레임워크 확장자 | 엄밀한 시그니처·에러 문구 | 타입당 1페이지 심볼 룩업(core/sugar/roblox/extend), `D`는 표면만·Roblox 문서로 유도 |
| **The Quadnomicon** | 프레임워크 설계자, 아키텍트 | 분석적, 한계를 숨기지 않음 | Revision/EpochMap, Slot 부분합 트리, 메모리 토폴로지, 마커 타입, 디스패치 엔진 등 내부 설계 |

---

## 2. 트랙별 문서 목록

링크는 상대 경로(`../<track>/<file>.md`)다(`site/sync-docs.py`가 사이트 경로로 치환). 각 파일의 제목이 곧 정본이라 여기 요약은 한 줄로만.

### Overview — 2편
- [`01-why-quad.md`](./overview/01-why-quad.md) — 왜 Quad인가: **다른 도구와의 비교 문서**(2026-09-10 사용자 결정 — 시작하기가 앞에 서고 이 페이지는 후행). Docusaurus "Comparison with other tools" 방식으로 Vide/Fusion/react-lua마다 "그 도구가 잘하는 것 → 거기서 겪는 문제 → Quad는 어떻게 풀었나 → 넘어올 이유/넘어오지 않을 이유"를 한 절씩, 뒤에 축별 차이표와 설계 선택(이전 선택 → 우리 선택 → 그 대가), 그리고 "없는 것과 그 이유"를 일부러 안 했다/아직 없지만 계획이 있다/오늘의 성숙도/구조상 안 메워지는 것으로 갈라 적고, 설계 선택의 마지막 칸은 치른 대가/알아 둘 것/다른 관점으로 라벨을 가른다(2026-09-11 재평가). 수치·창작 인용 없음, 예정 항목에 날짜·버전 약속 없음.
- [`02-from-v1.md`](./overview/02-from-v1.md) — quad v1에서 오는 분께: 없어진 것과 왜 없앴나(표 10행, 근거는 v1 내부 스냅샷 범위만), 새로 생긴 것이 v1의 어떤 자리를 메우나, 이관 틀 셋 — (a) 화면 단위 재작성이 주 경로, (b) v1·v2 화면 분할 공존은 **지원 경로**(양방향 브릿지, 경계를 넘는 건 항상 평범한 값, GC 상호작용은 [2026-09-10 기준] 미실측이라 핸들의 주인을 명시), (c) `Claim`으로 v1 트리 인계는 **비권장**(이중 소유) — 그리고 v1·v2 동시 로드 공식 허용 + 조건 셋, 새로 짤 때 전제 여섯. 사용자 결정 2026-09-10. v1 사용자는 회사 내부·외부 둘 다라 "안심시키기"와 "옮길 값어치" 둘 다 담는다. 스킬 링크 둘은 사이트에서 평문으로 벗겨진다(`sync-docs.py`).

### Getting Started (시작하기) — 20편(선형 튜토리얼)
**[2026-09-10 재구성, 2026-09-11 재편]** 사용자 피드백으로 "설정을 앞으로 / 정리 페이지 해체 / Slot을 컴포넌트 앞으로"를 반영해 7편에서 16편으로 늘렸고(`13-blocker.md`와 `05-tag-attr.md`는 같은 날 추가), 2026-09-11에 `Ref`와 `Observer`/`Effect`를 갈라 두 장으로(옛 06 `ref-and-effect` 해체, 옛 04 §2 Observer가 07로) + 함수형 패턴 장(11) 신설로 18편이 됐다. 같은 날 생명주기 훅 장(08)이 더해져 19편, 같은 날 밤 핸들러 맛보기 장(18)이 더해져 20편이다. 페이지 구조는 목표 한 줄 → 지금까지의 코드 → 이번에 바꾸는 몇 줄 → 실행하면 보이는 것 → 개념 한 문단 → 더 알고 싶다면이고, 곁가지는 **질문 제목의 `<details>`를 그 궁금증이 생기는 문장 바로 뒤**에 둔다(사용자 결정: "안 궁금한 지식을 마구 주입받을 필요는 없거든"). `## 다음 단계` 절은 전 페이지에서 뺐다(사이트가 이전/다음 버튼을 단다).
- [`00-installation.md`](./getting-started/00-installation.md) — 까는 것만: 배포 경로 표(**[2026-09-10 기준] pesde만 제공**), pesde 의존성 **셋**(`quad_types`도 직접 — 01의 타입 재수출이 그 링커를 쓴다), Rojo 매핑(rojo sourcemap으로 검증), 타입 검사 플래그 넷. Wally·`.rbxm`은 `<details>` 하나로 접었다.
- [`01-setup.md`](./getting-started/01-setup.md) — 프레임워크 설정하기: 설정 모듈 `ReplicatedStorage/Client/UI/Quad`(문자열 `@game/…` require + 타입 재수출 + `UseProvider`)와 진입점 `StarterPlayerScripts/Main`(첫 `ScreenGui`·확인용 라벨). quad-base/quad-roblox가 왜 나뉘는지가 여기서 나온다.
- [`02-first-screen.md`](./getting-started/02-first-screen.md) — 첫 화면: `D.Frame` 카드 + 라벨 자식. 문자 키=프로퍼티, 숫자 키=자식, `Parent`는 밖에서, 숏핸드 `UICorner`.
- [`03-flowing-values.md`](./getting-started/03-flowing-values.md) — 값이 흐르게 하기: 원천(`q.Source`) → 프로퍼티에 그대로 꽂기 → 중간에 값을 **처리하는** 파이프(`:Compute`) → `Source`/`State` 이름 붙이기. 게으름은 암시 한 문단만(본문은 17편).
- [`04-reacting.md`](./getting-started/04-reacting.md) — 반응하기(이벤트만): `Activated`로 `count:Set`, 이벤트는 문자 키 부분·엔진 인자만. 관측은 07로 넘긴다.
- [`05-tag-attr.md`](./getting-started/05-tag-attr.md) — 이름표와 속성: 숫자 키 부분의 `q.Tag`(자리별 참조 계수·State에서 나오는 태그)와 `q.Attr`/`q.BooleanAttr`, 붙인 것을 `Instance:QueryDescendants`로 찾기(선택자 표는 Studio 실측), 스타일시트는 공식 문서로.
- [`06-ref.md`](./getting-started/06-ref.md) — 인스턴스를 손에 쥐기: `q.Ref`(`<<T>>` 타입 인자 소개), 같은 props 안에서 쓰는 `q.PreRef`+`:Unwrap`, 채워질 때 받는 `:Callback`/`:Wait`, 인스턴스마다 새로 만드는 이유(Destroy해도 안 비워진다), `q.PostRef`.
- [`07-observer-effect.md`](./getting-started/07-observer-effect.md) — 관측하기: `:Observer`(인스턴스가 파괴되면 관측이 멈춘다·보류와 재생)와 `q.Effect`(의존 여럿·cleanup), §3 화면 안쪽은 `Effect`가 아니라 값으로(프로퍼티 직접 쓰기 안티패턴), §4 `Ref`를 의존성으로(게임패드 선택 — cleanup이 실제로 필요한 예). 접힘으로 핸들을 State에 담아 끄는 법.
- [`08-lifecycle-hooks.md`](./getting-started/08-lifecycle-hooks.md) — 생성만 보고 싶다면: `PreRef`+`:Callback`/`PostRef`+`:Callback`/cleanup만 있는 `Effect`를 손으로 짠 뒤, 그것과 **정확히 같은 것**이 `q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`임을 실제 구현 열 줄로 보인다(바텀업).
- [`09-modifier.md`](./getting-started/09-modifier.md) — 스타일을 값으로: 평범한 잎에 `D.Modifier.Frame {…}`, 필드에 State가 흐른다, 팩토리 + 스타일 모듈 하나.
- [`10-slot.md`](./getting-started/10-slot.md) — 자식이 들어갈 자리: `Slot`을 숫자 키 부분에, CRUD, `Offset`/`Length`를 print로 확인, Slot in Slot, 자리 하나를 `State`로 갈아 끼우기(내부적으로 `Owned=false` `:Single`). `:List`는 암시만.
- [`11-components.md`](./getting-started/11-components.md) — 컴포넌트로 쪼개기: 평범한 함수·props·둘 나란히, 자식은 10의 `Slot`을 `props.Children or q.None`으로 받는다.
- [`12-functions.md`](./getting-started/12-functions.md) — 함수로 묶기: 콜백·클로저·팩토리·커링에 이름 붙이기(새 API 없음). 값을 돌려주는 팩토리(`highlightColor`)와 컴포넌트에 팩토리를 넘기는 패턴(`props.Watch` → Effect), 손으로 만든 `Sum`에서 `q.Operator.Sum`+`:Apply`로, `:Apply`의 `__apply` 객체 팔 예고(16의 Blocker), Hook 규칙이 없는 이유.
- [`13-lists.md`](./getting-started/13-lists.md) — 목록 만들기: 데이터 원천 → 부모 컴포넌트가 `Slot():List` → 항목마다 컴포넌트. `updateFn` 계약 표, 재사용/파괴, 원소 하나짜리 `:Single`(Offset이 필요할 때).
- [`14-context.md`](./getting-started/14-context.md) — 층을 건너 값 넘기기: `q.Context` 가방(트리 조회 없음), `Provider` 키, `Get`/`Peek`.
- [`15-animation.md`](./getting-started/15-animation.md) — 움직이게 하기(바텀업): §1 `:Compute` 안에서 `q.Tween{…}`을 직접 만들고, §2에서 그 반복을 줄이는 `:Apply(q.Animate{…})`.
- [`16-blocker.md`](./getting-started/16-blocker.md) — 흐름을 잠시 막기: 값 여럿을 한 번에 바꿀 때 중간 상태가 새지 않게 `q.Blocker`로 통지를 모았다가 한 번에 — 게이트는 **파이프 뒤**(통지가 한 줄로 모인 자리)에 하나(2026-09-11 사용자 지적·mock 실측: 원천마다 두면 통지가 게이트 수만큼). 접힘 셋(원천마다 게이트를 두면 / 게이트가 실제 메커니즘 / 시간 정책은 레퍼런스로).
- [`17-laziness.md`](./getting-started/17-laziness.md) — 값은 언제 흐르나: 파이프·Observer·Effect·`Slot:List`·`Animate` 옵션·`Blocker` 여섯 자리를 한 표로 대조(컨베이어 벨트 비유는 여기). 사용자 결정 2026-09-10 — lazy는 라이브러리 전체에 드러나므로 뒤에서 한 번에.
- [`18-handlers.md`](./getting-started/18-handlers.md) — 자리에 놓인 값은 누가 처리하나(핸들러 맛보기): 자리마다 핸들러 목록에서 첫 승낙자가 맡는다(`q.Dispatch.listHandlers`/`getHandler`로 들여다보기), `State`는 벗겨서 한 칸 아래로(`State<X>`가 되는가 = `X`가 되는가), 갈아 끼우면 이전 것이 빠지는 방식 여섯(Tag 차이만·Attr 이름 전부·Ref 비움·Observer 정지·Effect cleanup·Instance 떼기 — mock 실측), 심층은 레퍼런스 extend/02·Quadnomicon 08로. 사용자 요청 2026-09-11(남의 코드를 읽을 수 있는 정도가 목표).
- [`19-wrap-up.md`](./getting-started/19-wrap-up.md) — 정리: 만든 것 요약 열여덟, 다음 읽을 곳, v1 콜아웃 `<details>`.

### How-To Guides (실전 레시피) — 9편
**[2026-09-10]** 사용자 결정으로 `01`↔`09`를 맞바꿨다 — 컴포넌트 경계 규약이 첫 장, 디버깅은 순서 없는 부록으로 맨 뒤.
- [`01-component-conventions.md`](./how-to/01-component-conventions.md) — 컴포넌트 경계 규약과 스타일 합성: props 두 부분의 규칙 넷, `props.X or None`(nil-hole), 우선순위 불변식 셋, 타입드 Modifier 팩토리, 자식은 `Slot`으로 받기, `Tag`/`Attr`, Hook 규칙 없는 팩토리와 `--!strict` 주석 안내, 체크리스트.
- [`02-form-validation-pattern.md`](./how-to/02-form-validation-pattern.md) — `Store` 필드 + 후행 의존성 `:Compute`로 실시간 검증·버튼 제어.
- [`03-virtualized-infinite-scroll.md`](./how-to/03-virtualized-infinite-scroll.md) — 긴 목록: 기본 계약은 [시작하기 13](./getting-started/13-lists.md)로 보내고, `LayoutOrder`/`Position` 바인딩·윈도잉·`Blocker`·"안 해주는 것"만 다룬다.
- [`04-network-and-input-bridge.md`](./how-to/04-network-and-input-bridge.md) — `RemoteEvent`·`UserInputService`를 `Source:Set`으로 격리, `Effect` cleanup과 생명주기 훅.
- [`05-theme-and-dynamic-styling.md`](./how-to/05-theme-and-dynamic-styling.md) — 디자인 토큰, `state:Apply(q.Animate{...})`, `Modifier.Overridden`, 명시적 `q.Context`로 계층 건너 전달.
- [`06-headless-testing.md`](./how-to/06-headless-testing.md) — `./scripts/test.sh`(판정은 exit code)와 테스트 내부 mock 백엔드. 공개 `quad-mock`은 백로그.
- [`07-studio-ui-binding-and-claim.md`](./how-to/07-studio-ui-binding-and-claim.md) — `q.Claim(inst, q.D.Mapper...)` 디스크립터, claim-once·직계 자식 전부 매핑·공동 소유 컨테이너는 대상 밖.
- [`08-migrating-from-v1.md`](./how-to/08-migrating-from-v1.md) — quad v1(`Init(id)`/`Class "Frame"`/`Store.GetStore`)에서의 이관: 툴체인 플래그 넷, 개념 대응표, 제거된 기능과 경로, strict 블로커 열여덟.
- [`09-debugging-and-troubleshooting.md`](./how-to/09-debugging-and-troubleshooting.md) — **부록**(순서 없음): 에러 메시지 모양(`주어: 이유`, 받은 값을 말할 땐 `(got X)`)과 표면 blame의 한계, 현업 함정 여섯(문구는 소스 verbatim).

### API Reference — 손으로 관리하는 심볼 레퍼런스(26페이지 + 색인)
**[2026-09-09 사용자 결정]** 관례 조사(Roblox 엔진 레퍼런스·Fusion·Vide·Lune·Squash) 뒤 확정: **타입당 1페이지**, 메소드는 `##` 절(앵커), 페이지 템플릿은
시그니처(quad-types에서 복사) → 인자 표 → 반환 → 동작(불변식·**에러 문구 verbatim**) → 예제(mock 실행·신 솔버 검사) → 관련. **생성기 없음** — 손으로 쓴 심볼은
전부 손으로 "관리"한다(사용자: 아키텍처가 견고해 자동화 이점이 작다). `D.<Class>` 31개 페이지도 만들지 않는다 — 표면 한 페이지·한 예시만 두고 각 클래스의 프로퍼티·이벤트는
Roblox 공식 레퍼런스로 유도(React가 DOM 요소를 설명하지 않듯). 빠진 심볼은 `scripts/doc-coverage.py`(test.sh 게이트)가 잡는다.
- [`00-index.md`](./reference/00-index.md) — 심볼 → 페이지 색인.
- `core/`(quad-base) 11편 — [모듈](./reference/core/01-quad-module.md)(New/RunInit/AddPlugin/UseProvider) · [Source](./reference/core/02-source.md) · [State](./reference/core/03-state.md) · [Store](./reference/core/04-store.md) · [Observer·Effect](./reference/core/05-observer-effect.md) · [Slot](./reference/core/06-slot.md) · [Ref](./reference/core/07-ref.md) · [Modifier](./reference/core/08-modifier.md) · [Tag·Attr](./reference/core/09-tag-attr.md) · [센티널·수명 스텁](./reference/core/10-lifetime-sentinels.md) · [술어 `is*`](./reference/core/11-predicates.md).
- `sugar/` 6편(사이트 사이드바에서는 Core 아래 하위 그룹 — quad-base 안의 순수 슈거) — [Context](./reference/sugar/01-context.md) · [Operator](./reference/sugar/02-operator.md) · [Debounce·Throttle](./reference/sugar/03-debounce-throttle.md) · [생명주기 훅](./reference/sugar/04-lifecycle-hooks.md) · [Fallback·Traceback](./reference/sugar/05-fallback-traceback.md) · [Blocker](./reference/sugar/06-blocker.md)(`state:Gate` 위의 정책 — 2026-09-11 사용자 결정으로 core에서 이동).
- `roblox/`(quad-roblox, 배지 Roblox) 6편 — [설치·확장 표면](./reference/roblox/01-install.md) · [`D`](./reference/roblox/02-d.md)(표면 한 예시 + Roblox 문서 유도, 레거시 프로퍼티) · [`D.Modifier`](./reference/roblox/03-d-modifier.md) · [Claim·Mapper](./reference/roblox/04-claim-mapper.md) · [OnChange](./reference/roblox/05-onchange.md) · [Tween·Animate](./reference/roblox/06-tween-animate.md).
- `extend/`(배지 Advanced) 2편 — [백엔드 프로바이더 규약](./reference/extend/01-backend-provider-contract.md)(옛 reference/01 에세이 그대로) · [Dispatch·Handler 계약](./reference/extend/02-dispatch-handler-contract.md).

### The Quadnomicon — 11권
> Rustonomicon 스타일 — 초보자용이 아니다. 입문은 [Getting Started](./getting-started/00-installation.md)부터.

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
overview·getting-started·how-to·quadnomicon·reference 다섯 트랙을 하위 폴더까지 `site/src/content/docs/<track>/`(**[2026-09-10]** 한국어가 root 로케일 — 옛 `ko/`)로 복사하며 상대 링크를 사이트 경로로 치환하고 본문 첫 H1을 지운다(Starlight가 title로 그린다). **[2026-09-10]** 복사는 **in-place**다(옛 `rmtree` 제거) — dev 중 감시 디렉터리가 통째로 사라지면 `astro dev`가 두 번째 변경부터 못 보고 옛 렌더를 준다(실측). 로컬 미리보기는 [`site/dev.sh`](./site/dev.sh)(`npm run dev`) — [`site/watch-docs.py`](./site/watch-docs.py)가 정본 `.md`를 폴링해 sync를 다시 돌리고 astro dev가 갱신한다(`./dev.sh stop`으로 종료, 포트는 `PORT=`). **[2026-09-09] 첫 빌드 성공**(`npm run build`, Starlight 0.32). `en/`은 아직 index만.

### Agent Tooling — [`skills/quad-ui-dev/`](./skills/quad-ui-dev)
AI 코딩 에이전트용 스킬(영문 유지 — 토큰 경제성). [`SKILL.md`](./skills/quad-ui-dev/SKILL.md)(온톨로지·금지 패턴·strict 타입 요구사항),
[`references/code-recipes.md`](./skills/quad-ui-dev/references/code-recipes.md)(mock에서 실행 확인된 레시피 여섯),
[`references/rules-and-invariants.md`](./skills/quad-ui-dev/references/rules-and-invariants.md)(소스 verbatim 에러 문자열 → 처방),
[`references/v1-migration.md`](./skills/quad-ui-dev/references/v1-migration.md)(v1 코드 이관 — 대응표·제거된 기능·strict 블로커).
인간용 트랙과 내용이 겹치는 것은 의도된 것이다(사용자, 2026-09-09).

---

## 3. 이 문서를 고칠 때

아래 **링크** 항목은 저장소의 다른 계획 문서가 `"링크"` 절로 이름을 찍어 인용한다 — 제목을 바꾸거나 지우지 말 것.

- **링크**: 문서 간 링크는 상대 경로(`../<track>/<file>.md`, 레퍼런스 하위 폴더는 `../../<track>/…`·`../core/…`; `site/sync-docs.py`가 재귀 복사하며 사이트 경로로 치환). frontmatter(`title`/`description`)는 원본에 둔다 — sync가 없으면 실패한다. 저장소 내부 설계 문서·소스 파일로의 링크는 두지 않는다(독자에게 없는 경로) — 소스는 필요할 때 평문 파일명으로만 언급.
