# HUMAN_TODO — 사용자(사람)만 할 수 있는 일

에이전트가 못 하거나(로컬 GUI 조작, 외부 계정/기기 필요) 사용자의 결정이 필요해서
멈춰둔 것만 여기 모음. 설계 질문은 대체로 `.claude/question.md`에 따로 있고 디폴트를
잡아둔 채 진행 중이라 급하지 않음 — **단 2026-08-13부터는 예외가 생겨 아래 4번에
올렸었음**(0-Z) — **[2026-08-13 열네 번째 세션] 그 0-Z도 해소되어 지금은
사람이 결정해야 M0가 열리는 항목이 없음**(0-Y는 열세 번째 세션에 해소).

미해소 항목이 먼저 오고, 해소된 항목은 아래 해소됨 절에 모아 둔다 — 뷰어에서 그 절을 접어 두면 남은 일만 보인다.

## 미해소

### 18. [2026-09-11 신설] 사람 몫 모음 — 도식·눈 검토·실기기·결정·배포 (사용자: "몰아서 넣어줘 … 양 많아도 좋아 천천히 처리")

페이지는 **파일명 슬러그**로 가리킨다(시작하기 번호가 같은 날 두 번 바뀌었다 — `ls docs/getting-started`). 에이전트가 할 수 있는 뒷정리(SVG를 `<picture>`로 심기, 실측 결과로 문장 확정, 결정 반영)는 결과만 알려 주면 된다.

#### A. 도식 — 그리면 좋아질 자리 (Slot 세 그림처럼 SVG 라이트·다크 두 벌, `docs/assets/`)

각 항목은 "어디에 / 무엇을 / 왜". 그림 안 라벨은 draw.io에서 **텍스트를 도형으로 변환(또는 plain text로 내보내기)**해 주면 GitHub `<img>`에서도 글자가 보인다(foreignObject 라벨은 GitHub가 안 그린다 — 사이트는 무관).

1. **`*-ref.md`(+ `*-lifecycle-hooks.md`, 레퍼런스 `core/07-ref.md`) — Ref 셋이 채워지는 시점 타임라인.** 가로축이 한 인스턴스의 drive: `PreRef 전부` → `숫자 키를 순서대로(자식·Ref·Observer…)` → `문자 키(프로퍼티·이벤트)` → `PostRef 전부`. 축 끝에 "여기서 `Parent`는 아직 모름 — 리터럴이면 nil, Claim이면 이미 있음"을 표시. 지금은 산문 세 문단이 이 순서를 설명하고 있어 그림 하나면 셋이 준다.
2. **`*-observer-effect.md`(+ `*-laziness.md`) — 핸들이 살아나는 두 길.** 만들어진 Observer/Effect(아직 자격 없음) → (a) 숫자 키 자리에 놓여 인스턴스에 매달림 / (b) `:Subscribe()` 전역 구독. 옆에 "살아나기 전 도착한 변경은 보류 → 살아나는 순간 최신값으로 한 번 재생" 화살표. 게으름 페이지의 접힘 둘이 말로 하는 것.
3. **`*-laziness.md` — 다이아몬드 그래프.** 원천 하나 → 두 갈래 → 한 노드로 합류. 왼쪽 "신호(push)"는 두 번 도착, 오른쪽 "계산(pull, `:Get()` 시점)"은 한 번. 오버뷰 §3(Vide 대비)이 같은 그림을 쓸 수 있다.
4. **`*-blocker.md` — 게이트 스위치.** 상류 → [게이트: 모아 둠] → 하류, 옆에 Blocker `On`/`Off` 스위치와 "Off 때 한 번에 흘려보냄 / OffWithoutEmit은 버림". `Debounce`/`Throttle`이 같은 게이트 위의 시간 정책이라는 것도 같은 그림의 변주로.
5. **`*-modifier.md` — 우선순위 둘.** 배열 자리 Modifier A, B(뒤가 이김)와 인라인 문자 키(무조건 이김)가 한 프로퍼티에 겹치는 모습. 접힘 안 규칙 셋이 그림 하나로 준다.
6. **`*-lists.md` — `:List` 재조정 한 사이클.** 데이터 배열 → 키 계산(중복·누락 검사) → 항목마다 `updateFn`(prev 재사용 / 새로 / nil·None 파괴 / Detach 보관) → 사라진 키에 `KeyGone`. 반환 네 갈래 표와 짝.
7. **`*-components.md`·`how-to/01-component-conventions.md` — 컴포넌트 경계.** 함수 상자 하나에 들어오는 props(문자 키: 값·State / 숫자 키: `Children` Slot·`Ref`·`Modifier`)와 나가는 인스턴스. "마법은 없다"를 그림으로.
8. **`*-context.md` — 가방 넘기기.** 진입점(가방에 담음) → 중간 컴포넌트(가방만 통과, 안을 모름) → 말단(자기 열쇠로 엶). React식 "거슬러 올라가 조회"와 대비되는 화살표 방향.
9. **`*-setup.md` — 파일 배치.** `ReplicatedStorage/roblox_packages/…`, 설정 모듈 `Client/UI/Quad`, 진입점 `StarterPlayerScripts/Main.client` 트리 한 장(지금은 코드 주석으로만).
10. **`how-to/07-studio-ui-binding-and-claim.md` — 템플릿 → `:Clone()` → `Claim` → `D.Mapper` 매핑.** 정적 프로퍼티는 템플릿에 구워 두고 동적 바인딩만 Claim이 심는다는 그림(C 실측 2번과 같이).
11. **`overview/01-why-quad.md` §1·§6 — 전파 모델 셋 나란히.** Fusion(push 무효화+pull, eager 표시) / Vide(순수 push, 깊이우선) / Quad(신호만 push, 계산은 pull). 3번 그림의 확장판이라 같이 그리면 된다.
12. ~~**`docs/README.md` Diátaxis 사분면** — 17번 그대로.~~ **[2026-09-11 해소 — 17번과 함께 스킵]**
13. **[2026-09-11 밤 신설] `*-observer-effect.md` §4 게임패드 선택 예제** — `GuiService.SelectedObject`를 `Effect`에서 걸고 cleanup에서 푸는 것이 실기기에서 그대로 되는지(mock은 `{ SelectedObject = nil }` 셰임으로만 확인). 파괴 때 cleanup이 선택을 풀어 죽은 버튼이 선택된 채 남지 않는지.
14. **[2026-09-11 밤 신설] `*-tag-attr.md` §4 `Instance:QueryDescendants`가 Studio 밖 실제 클라이언트에서도 되는지** — 문서는 Studio 0.738 실측만 근거로 답니다(열린 탐사 리뷰어 지적).

#### B. 눈으로 볼 것 — 사람 시각 검토 각도 (밀도·흐름·큰 틀·레이아웃)

**밀도(한 화면에 너무 많은가)**: `*-tag-attr.md`(리뷰어가 GS 중 가장 밀도 높다고 — 접힘 반영 뒤 다시), `*-functions.md`(225줄 — 다섯 절이 한 페이지에 맞는지, 커링 절을 둘로 가를지), `*-ref.md`(211줄 — PreRef 절과 Callback/Wait 절 중 하나를 접힘으로 더 줄일지), 새 `*-lifecycle-hooks.md`(바텀업 구성이 "손으로 짠 것 → 이름 → 구현" 세 번 반복이라 지루하지 않은지).

**흐름(순서가 맞는가)**: `*-reacting.md`가 이벤트만 남아 얇아졌는데 한 페이지로 성립하는지(아니면 03과 합칠지); 06 Ref → 07 Observer·Effect → 08 훅 세 페이지 연속이 리듬으로 읽히는지(에이전트 판단으로 Ref를 앞에 뒀다 — Effect가 Ref를 의존성으로 거는 예 때문); `*-functions.md`가 컴포넌트 **뒤**인 것이 맞는지(앞에 두면 컴포넌트를 "팩토리의 한 종류"로 소개할 수 있다 — 에이전트가 뒤를 골랐다); `*-lists.md` §5 `:Single`이 `:List` 뒤에 오는 것과 `*-slot.md` §6(State를 자리에)의 분담; `*-blocker.md` → `*-laziness.md` → `*-wrap-up.md` 마무리 세 장의 호기심 훅이 실제로 동작하는지.

**큰 틀**: 시작하기 20페이지가 너무 긴지 — 얇은 페이지(04 이벤트, 09 Modifier)를 이웃에 합칠지; 오버뷰 §7의 새 라벨 셋("치른 대가 / 알아 둘 것 / 다른 관점")이 첫 독자에게 자연스러운지, §8 "오늘의 성숙도 / 구조상 안 메워지는 것"이 방어적으로 읽히지 않는지, (4)·(8) 문단이 길어졌는데 줄일 곳; 레퍼런스 사이드바에서 Sugar가 Core **하위 그룹 맨 뒤**에 있는 배치가 의도와 맞는지(Core 항목 사이에 끼울 수도 있다); 레퍼런스 색인 페이지(`reference/00-index.md`) 길이와 표 폭.

**레이아웃(사이트·GitHub 둘 다)**: Slot 세 그림의 데스크탑 50% / 좁은 창 90% 규칙이 실제 폰 화면에서 좋은지; 다크 모드에서 `-dark.svg` 대비; GitHub에서 draw.io 라벨이 보이는지(위 A 머리); `<details>` 안에 코드 블록이 들어갈 때 여백(custom.css); 레퍼런스의 넓은 표가 가로 스크롤로 잘리는 곳; 랜딩 페이지의 첫 액션·카드; mermaid 그림(03·quadnomicon)의 다크 모드 색.

**문장·톤**: 오버뷰 존댓말 전환 뒤 어색한 문장("~하시면", "~드립니다" 과다); GS 06·07·08의 "실행하면" 뒤 문장이 실제 Studio 출력과 같은 어투인지; 사용자 노트가 아닌 에이전트 판단으로 들어간 문구(11 "Lua의 함수는 값입니다" 도입, 오버뷰 (4)(a)의 userdata 설명)가 과하지 않은지.

#### C. 실기기(Studio, 별도 계정) 실측 — 결과만 알려 주면 문장 확정은 에이전트가

1. **`*-slot.md` 새 배치 스크린샷** — card / panel / host 예시(사용자 SVG와 같은 구조)를 실제로 띄운 화면. 문서 그림과 실물이 맞는지, 라벨 치우침 없는지.
2. **템플릿 → `:Clone()` → `Claim` 패턴 실측**(how-to 07) — 정적 프로퍼티가 템플릿에서 그대로 오고 동적 바인딩만 Claim이 심는지, `D.Mapper` 매핑이 직계 자식만 보는지.
3. **StyleRule vs quad 프로퍼티 직접 대입의 우선순위** — `q.Tag("Card")`에 StyleRule로 `BackgroundColor3`를 걸고 같은 프로퍼티를 quad가 `State`로 바인딩할 때 누가 이기는지(정적/동적 각각). 오버뷰 (6)과 `*-tag-attr.md`가 지금 이 사실을 **어느 쪽으로도 안 적는다** — 결과에 따라 한 문장 추가.
4. **PostRef/`OnRendered` 시점의 `Parent`** — 리터럴 중첩(예상 nil)과 `Claim`한 인스턴스(예상 이미 있음) 둘에서 실제 값. 문서 캐비엇의 근거.
5. **`State<Instance?>`를 자리에 놓고 갈아 끼울 때 옛 원소가 파괴되지 않고 `Parent = nil`로 남는지**(mock 실측만 있음) — `*-slot.md` §6 서술의 실기기 확인.
6. **Deferred 시그널 플레이스에서 `Effect` cleanup이 `Destroy` 직후로 지연되는지** — 오버뷰 (4) "알아 둘 것"의 근거는 설계 실측(`lifecycle-pattern.md`)뿐이라 현 빌드에서 한 번 더.
7. **14.2** `roblox_sync_config_generator` 없이 Studio 싱크(그대로).
8. **[2026-09-11 열린 탐사]** **리스폰과 quad 트리** — `PlayerGui`에 스크립트가 직접 붙인 `ScreenGui`가 `ResetOnSpawn = true`일 때 리스폰에서 지워지는지(GS 01은 `false`로 두고 한 줄 주석만 달았다), `StarterPlayerScripts`의 LocalScript 재실행과 겹치면 어떤 증상인지. 실측이 오면 how-to에 "리스폰·플레이어 생명주기" 절을 쓴다(지금 문서엔 respawn 서술이 0건).
9. **[2026-09-11 열린 탐사]** **최소 요구 버전** — GS 01이 `const`와 문자열 `require("@game/…")`를 쓰는데 어느 Studio/luau 버전부터 되는지 문서 어디에도 없다. Studio에서 `const`가 도는 것은 확인됐지만(8번 해소) 하한 버전은 미확인 — 알려 주면 00 설치에 한 줄.

#### D. 결정 — `.claude/question.md`와 계획서의 열린 문항

- `question.md` 3절 **D5**(14.2와 같은 것).
- `research/rfc-docs-section-plan.md` 8절 **Q1~Q6**(공개 범위·형태·기존 결정 둘의 역전·사전 정리 방식·번역·갱신 자동화).
- `research/roadmap-changelog-docs-plan.md` 7절 **Q1~Q8**(CHANGELOG 임베딩 여부·frontmatter 위치·사이드바·오버뷰 §8 확장 vs 새 페이지·내부 ROADMAP 공개 절 메커니즘·약속 수위·v1 원문 절·번역). 같은 조사의 부수 문항 `question.md` 3절 **D11**(`quad-mock` 이름).
- ~~**다음 릴리즈 번호**~~ **[2026-09-11 해소 — 사용자 결정 3.1.0]** `check-version.py bump 3.1.0` 완료(매니페스트 여섯·소스·테스트·CHANGELOG `[3.1.0] - 2026-09-11`, 문서의 버전 문구, publish dry-run). BREAKING(`Index → Indexed`)이 마이너에 실린 것은 사용자 판단.
- 시작하기의 **함수형 페이지 위치**(B 흐름 항목)와 **얇은 페이지 합치기 여부** — 에이전트가 고른 배치라 한 번 봐 달라.
- ~~**[2026-09-11 열린 탐사 — 급함] 문서가 게시된 3.0.0이 아니라 HEAD를 서술한다.**~~ **[같은 날 해소 — 3.1.0 bump]** 게시(E 절)만 남았다. 문서의 `Indexed` 표시는 "3.0.0에서는 `Index`, 3.1.0부터 `Indexed`"로 바꿔 게시 시점과 무관하게 참.
- **범위 밖 안내 절을 둘지** — 시니어가 첫날 묻는데 문서가 침묵하는 넷: 서버 사이드·`SurfaceGui`/`BillboardGui`, `StreamingEnabled`와 바인딩, Roact/Fusion 화면과의 공존, 핫 리로드(스토리북 도구는 예정). 답을 만들지 않더라도 how-to에 "아직 답이 없는 것" 절로 경계를 그어 두자는 제안(열린 탐사) — 둘지, 어느 항목을 넣을지.
- **"현재 상태" 단락** — 오버뷰나 랜딩에 트랙 레코드(언제부터, 어디서 쓰이는지, 어느 규모까지 굴려 봤는지, 성능 수치) 한 단락을 둘지. 내용은 사용자만 안다.
- **클래스별 `Modifier`/`OnChange` 타입의 공개 경로** — 레퍼런스 roblox/03·05, how-to 01·05의 예제가 `require(<quad-roblox D 모듈 경로>)`로 `TextButtonModifier` 같은 클래스별 타입을 가져오는데, pesde 설치에서 `quad_roblox`는 링크 파일이라 `/D` 하위가 없고 그 타입들은 `.pesde/…/quad_roblox/src/D` 아래에만 있다(루트가 재수출하는 건 `D`·`Tween`·`PropTypes` 같은 네임스페이스 타입뿐). `.pesde` 경로를 문서에 적는 건 버전 고정 관용구를 새로 발명하는 것이라 안 했다 — quad_roblox 루트가 클래스별 타입도 재수출하게 할지(소스 변경), 아니면 `typeof(q.D.Modifier.TextButton)` 같은 우회를 문서화할지 결정.
- **레퍼런스·how-to 예제의 `local` vs GS의 `const`** — 프롤로그는 통일했지만(01장 설정 모듈) 본문 `local`은 그대로 뒀다. 예제 전부를 `const`로 바꿀지(툴체인 하한과 같이).

#### E. 밖에서 할 것

- **[2026-09-11] 3.1.0 게시** — `python3 scripts/publish.py --real`(사용자만; dry-run 9건은 에이전트가 통과시킴). **[같은 날 밤 게시 완료, 리모트 싱크 완료 — 사용자]** 태그 `3.0.0`(7a080e0)·`3.1.0`(01818b5)은 에이전트가 만들어 origin에 올렸다. **남은 것: 태그는 브랜치 싱크에 안 따라가므로 github/upstream에 `git push github --tags`·`git push upstream --tags`를 사용자가 한 번.**
- 사이트 재배포: 게시 뒤 dev 서버를 내리고(`docs/site/dev.sh stop`) `npm run deploy`, 끝나면 `./dev.sh`로 다시(dev 중 build 금지 규약). 2026-09-11 커밋 스무여 개가 배포 전이다 — 헤더 배지가 3.1.0으로 바뀌므로 게시 **뒤에** 배포할 것.
- draw.io SVG 내보내기 설정(위 A 머리) 확인.


### 14. [2026-09-10 신설] 3.0.0 게시 전 사람 몫 넷 — **남은 건 2(Studio 싱크 실측)뿐 [2026-09-10 기준]**

pesde 첫 게시(사용자 결정 2026-09-10: 레지스트리는 `3.0.0`부터, 메이저에 프리릴리즈 없음, `master`는 v1 그대로) 전에 사람만 할 수 있는 것.

1. ✅ **[2026-09-10 완료 — 사용자 실게시 9건 OK(넷 luau·roblox + quad_roblox), 빈 roblox 프로젝트 `^3.0.0` 설치로 다섯 패키지 해소 확인]** **공식 인덱스에 `qwreey` 스코프 등록과 게시 토큰**(`pesde auth login`) — 실게시는 `python3 scripts/publish.py --real`(사용자 전용; 의존 순 9건, 확인 프롬프트). 그 전에 `python3 scripts/check-version.py bump 3.0.0` → docs 잔여 `0.0.0` 손질 → `sync-docs.py` → 커밋 → dry-run 재확인(3.0.0 기준 표는 미확인) — 매니페스트 다섯에 `[indices] default = "https://github.com/pesde-pkg/index"`를 넣어 뒀다(dry-run 통과). 실제 게시 권한은 사용자 계정이 필요하다. 다른 인덱스를 쓸 거면 그 URL로 다섯 곳을 바꿀 것.
2. **`roblox_sync_config_generator` 없이 Studio 싱크가 되는지 실측** — 소비자 프로젝트 설치에서 pesde가 경고를 낸다(설치 문서 2단계에 [2026-09-10 기준] 미확인으로 적어 둠). 결과로 그 문장을 확정/삭제.
3. ~~**pesde 0.7.4로 dry-run 재확인**~~ **[2026-09-10 해소 — 핀 0.7.4 적용, `scripts/publish.py` dry-run 9건 OK(넷 양 타깃) + 스테이징 test.sh exit 0]** — `mise.toml` 핀이 0.7.3이고 0.7.4가 나와 있다. 게시 검사(includes 글롭·타깃 규칙)가 바뀌었을 수 있으니 핀을 올린 뒤 `pesde publish --dry-run`을 다섯 패키지에 다시 돌릴 것(에이전트가 해도 되지만 핀 변경은 사용자 결정).
4. ~~**v1 회수 버전 목록 확인**~~ **[2026-09-10 닫힘 — 사용자: 보이는 건 2.10·2.16 둘이고 그 전 기록은 없음("소스 매니지먼트가 잘 되던게 아니라서")]**

### 12. **[2026-09-02 신설, 사용자 확정 — 재발 시 사람 몫]** Studio 프로세스 재기동 (rojo 라이브 싱크의 자율 운영 한계)

**[2026-09-06 추가 관측]** Studio를 재시작하면 rojo 플러그인의 autoReconnect가 붙지 않았다(콘솔 *"Couldn't connect to the Rojo server"* → WebSocket 400; 이 쪽 `rojo serve`는 살아 있음). 다음 Studio 세션에서 **플러그인 Connect를 한 번 눌러 줄 것** — 그 전까지 에이전트는 바뀐 모듈의 `.Source`를 직접 패치해 실측했다(`audit/m11-unit2-studio-2026-09-06.md` 경위). **[2026-09-06 아침 해소]** 사용자가 Connect → 전체 재싱크 확인(패치본은 정본 파일로 덮임). rojo serve 자체는 `pesde install` 중 패키지 경로가 잠시 사라지면 죽는다(에이전트가 재기동).

M5 단위 ⑤에서 확립한 반입 경로(rojo serve + 공식 플러그인)는 **Studio
프로세스가 살아 있는 동안은** 사람 손이 필요 없다 — `autoReconnect`가
켜져 있어 플러그인 로드 시 자동 재연결되고, 변경 컨펌도 꺼둠(설정은
사용자가 2026-09-02에 1회 수행, `.claude/audit/m5-unit5-first-render-2026-09-02.md`가
소스). serve 프로세스 생존은 개발 머신 쪽이라 에이전트 몫.

**남는 사람 몫 하나**: **Studio 프로세스 자체가 죽으면**(잘 죽는 편 —
`.claude/conventions.md`의 Studio 운용 주의) 재기동 → 플레이스 열기까지는
GUI 작업이라 에이전트가 못 한다. 사용자 확정(2026-09-02): *"결국
스튜디오를 열고 플레이스를 여는 작업은 인간이 할 수 있는 부분이라, 자율
운영이 안 돼. 따라서 사람 몫으로 등재하는건 한계를 인정해야하는 부분으로써,
옳은 방향이야"* — 심각 항목은 아니고, 밤샘 자율 구간에 Studio가 죽으면
에이전트는 위험한 복구 시도 없이 CLI로 가능한 작업만 하거나 대기하고,
사람이 깨어나 Studio를 다시 열면(플레이스 진입까지) 그 뒤는 자동으로
이어진다.

### 10. **[2026-08-20 신설, 안 막음]** Tween 초기 진입 애니메이션(`initValue`) — 에이전트 작업 범위 밖

`base/tween-plan.md`가 **"필요해지면 사용자가 직접 코드베이스+문서를 만진다,
에이전트는 임의로 착수하지 말 것"**으로 확정해둔 항목인데, **여기 HUMAN_TODO에는
그 언급이 없어서 사람 쪽 할 일 목록에서 빠져 있었다**(2026-08-20 구현 전 QA
4라운드 `TW-16`에서 사용자가 지적 — *"틀리진 않았는데, Human todo 에 언급이
없음"*). 지금 보강.

- **무엇인가**: 다이얼로그가 아래에서 위로 슬라이드-인하는 것처럼 **첫 마운트에도
  애니메이션을 원하는 경우**. 지금은 "첫 세팅은 무조건 애니메이션 없이 즉시
  스냅"(3-상태 릴레이션 슬롯의 `prev == nil` 분기)이 기본이라 이게 안 된다 —
  그 기본값은 "엔진 기본값에서 목표값으로 날아오는 진입 애니메이션 버그"를
  막으려고 일부러 넣은 것이라, 우회하려면 그 억제 동작과의 상충을 같이 설계해야
  한다.
- **왜 에이전트가 안 하는가**(그 문서의 근거 그대로): Tween 정보가 부족한
  에이전트가 다루기엔 `hasBeenSet` 억제 동작과의 상충 판단이 미묘하고, 반대로
  Tween 자체가 다른 base 요소와 깊게 안 얽혀 있어(거의 전부
  `Handlers/Property.luau` 한 파일 + 릴레이션 슬롯) 사용자가 직접 처리하는 데
  범위상 문제가 없다.
- **지금 상태**: 미확정("필요성 낮은 쪽으로 기움", 완전 폐기는 아님). **M0/M2(**[2026-08-29]** 둘 다 완료)를
  막지 않으므로 급하지 않고**, 실제로 진입 애니메이션이 필요해지는 시점에
  사용자가 착수하면 된다. 설계 맥락은 `base/tween-plan.md`의 "초기 진입
  애니메이션(`initValue`)" 절.

### 9. **[2026-08-19 신설, 안 막음]** `type-version-check` 독립 저장소로 분리

`type-version-check/`(컴파일 타임 버전 패턴 매칭 — 글롭/캐럿, `quad-types`의
`CheckedQuad<T, Pattern>`이 이 위에 얹힘)는 quad에 종속되지 않은 범용
유틸이라 **사용자가 직접 독립 저장소로 분리할 예정**("우선 이 프로젝트
안에 넣어둬줘. 나중에 내가 다른 프로젝트로 분리해줄게.", 2026-08-19).
지금은 quad 워크스페이스의 네 번째 멤버(`workspace_members`)로만 있음 —
에이전트가 먼저 나서서 분리하지 말고 사용자가 하라고 할 때까지 대기.
설계/구현 상세는 `.claude/base/quad-types-plan.md`의
"`type-version-check`" 절.

### 6. ~~에디터의 Luau 솔버 설정 확인~~ **[2026-08-19 설정 완료 — VSCode 재시작만 확인해주면 됨]**

`luau-analyze` CLI는 새 솔버가 기본값이지만 에디터가 쓰는 `luau-lsp`는
**옛 솔버가 기본값**(`LuauSolverV2=false`)이라 같은 코드에 다른 진단이
나옴 — 예전엔 "실제 에디터 환경에서 확인 필요"로 사람에게 넘겨뒀던
항목.

**[2026-08-19] `luau-lsp` 바이너리(1.69.0, `luau-lsp analyze` CLI 모드)를
`/code/.local/bin`에 직접 설치해 `--flag:LuauSolverV2=true/false`
양쪽으로 실측 — 새 솔버가 필요하다는 결론을 재확인**하고
`quad/.vscode/settings.json`을 만들어 `{ "luau-lsp.fflags.enableNewSolver":
true }`를 이미 커밋해뒀음(팀/에디터 전체에 공유됨, 사용자가 손댈 것
없음). `tbox`(다른 참고 레포)도 동일 설정을 이미 쓰고 있어 교차 확인됨.
같이 검토했던 `LuauDoNotExportBrokenTypeFunction` override(tbox가 씀)는
quad의 현재 `type function` 스파이크(`16`/`21`)에서 유무 차이가 없어
**채택 안 함**(불필요한 설정 추가 지양).

**사람이 확인해줄 것 하나만 남음**: 이건 CLI로 시뮬레이션한 것이지
VSCode를 실제로 띄운 게 아님 — 다음에 VSCode를 열면 워크스페이스
설정이 잘 먹었는지(같은 `.luau` 파일에서 CLI 결과와 에디터의 빨간 줄이
일치하는지) 한 번만 눈으로 확인해주면 이 항목은 완전히 닫힘. 배경은
`.claude/base/typing-limits.md` 8번, 실측은
`.claude/audit/type-recursion-issue/REPORT.md` 5절.

### 3. `.claude/question.md`의 **나머지** 항목 검토 (급하지 않음)

디자인 결정 중 Lua/Roblox 엔진에 대한 깊은 경험이 필요한 것들은 합리적 기본값으로
진행하면서 `.claude/question.md`에 모아두는 중. 깨어있을 때 훑어보고 기본값이
마음에 안 드는 것만 답해주면 됨 — **[2026-08-24 갱신] 순수 설계 결정
대기는 여전히 0건**이고 2026-08-22에 열렸던 마일스톤 순서 결정도
**해소됐다**(위 11번 항목). **✅ [2026-08-26 갱신] 그 해소의 부작용으로
한때 올라왔던 항목 둘**(중간 State GC 실측, 동적 키 표면 위치)**도 2026-08-25에
닫혔고, 2026-08-26 8라운드 손 트레이싱까지 처리한 지금 `question.md` 최우선
절은 비어 있다.** 아래는 그 전 서술: **[2026-08-14 열한 번째 세션 기준]
`question.md`엔 이제 "결정 대기" 절 자체가 없음**(비어서 헤딩째로 삭제 —
마지막 남았던 0-W
`Ref` 이중 배치도 이 세션에 해소 — `base/ref-plan.md` "이중 배치 방지"
절, `archive/question-resolved.md`로 이전됨).

## 해소됨

### ✅ 17. ~~[2026-09-10 밤 신설] `docs/README.md`의 Diátaxis 사분면 그림을 SVG로~~ **[2026-09-11 밤 해소 — 사용자 결정: 스킵]** `docs/README.md`는 사이트에 노출되지 않는 GitHub 전용 파일이고(사용자: "페이지 렌더링인 줄 알았는데 … 그냥 딱히 그릴 이유 없는 듯"), 에이전트도 그림을 읽기 어려워 얻는 이점이 없다. 아스키아트는 그대로 둔다.

(원문) 사이트의 박스 문자 아스키아트는 전부 mermaid로 바꿨지만(`docs/README.md`는 사이트 밖이라 남김), 사용자가 *"Diátaxis 사분면 그림은 나중에 내가 직접 그릴게. 비슷하게 svg 로 올려줄게"*. SVG가 오면 `docs/README.md` §1의 아스키아트를 그 이미지로 교체한다(에이전트가 해도 됨).


### ✅ 19. ~~[2026-09-11 신설, 사용자 예고] git 명령을 sandbox 쪽에서 래핑해 커밋 관례를 자동 처리 — 되면 에이전트에게 알려 줄 것~~ **[같은 날 밤 해소 — 사용자가 알려 줌("알아서 qwreey-bot으로 남더라"), 에이전트 실측: `/etc/code-docker/git/hooks/ai-trailer.sh`가 `@anthropic.com` 트레일러를 `codedocker.aitrailer.name/email`로 바꾸고 세션 URL을 뗀다. 이 세션에 `name=qwreey`·`email=me@qwreey.moe` 설정(없으면 `user.name`으로 떨어짐). push 차단은 이 훅의 범위가 아니라 리모트 정책(메모리 `git-remote-push-policy`)은 그대로. `conventions.md` 항목 갱신]**

사용자 원문(2026-09-11): *"git 명령을 sandbox 쪽에서 래핑어라운드해서 컨벤션에 쓰지 않아도 자동 처리되는걸 넣을것이고, 그렇게 될 예정이라고, 된다면 말해줘야한다고 HUMAN_TODO 에 기제해두면 돼."* 지금 `conventions.md`가 세션에 지키게 하는 커밋 규율(`Co-authored-by: qwreey <me@qwreey.moe>` 트레일러, Claude 트레일러 억제, 원격 push 금지)은 그 래핑이 들어오면 문서 규약이 아니라 도구가 보장한다. **래핑이 실제로 켜지면 그 사실과 무엇이 자동인지(트레일러·세션 링크·push 차단 범위)를 알려 주면**, 에이전트가 `conventions.md`의 해당 항목과 메모리 `git-remote-push-policy`를 "도구가 처리 — 세션은 안 함"으로 고친다. 그 전까지는 지금 규약 그대로.

### 0. ~~(SAFETY.md) Git 원격 저장소 계정 마련~~ **[해소됨, 2026-08-18 — `origin`(git.qwreey.moe) 마련·사용 중, 정책은 `SAFETY.md`와 메모리 `git-remote-push-policy`; 2026-09-06 감사가 이 항목의 미갱신을 발견]**

(아래는 해소 전 원문)

`SAFETY.md`에 따라 이 레포는 GitHub 등 외부 호스팅에 올리지 않기로 되어 있음 —
모델(나)의 git 작업 공간은 사용자가 마련해줄 제한 계정 전용이어야 함(예:
git.qwreey.moe에 제한된 계정 생성). 로컬 git 저장소는 이미 초기화 + 초기
커밋까지 해뒀음(원격 없음) — 원격을 추가하고 싶으면 그 계정 정보를 알려줄 것,
그 전까지는 로컬 커밋만 계속 쌓아둠.

### ✅ 1. ~~Roblox Studio에 MCP로 연결~~ **[2026-09-01 해소 — 연결 실측 완료]**

**사용자가 본 계정과 무관한 별도 계정(`qwreey_selene`)을 별도 컨테이너에
준비**했고(다른 사용자 미사용 — `SAFETY.md`의 별도 계정 게이트 충족), MCP
프록시가 `http://studio:8787/mcp`에 떠 있다. 인증 토큰은 **레포가 아니라
전역 Claude 설정(`~/.claude.json`의 `mcpServers.roblox-studio` 헤더)에만**
들어 있음 — 레포 문서에 토큰을 적지 말 것. 연결 실측(2026-09-01):
`list_roblox_studios` → 인스턴스 1개("Place1"), Edit 모드,
`execute_luau`로 Instance 생성·`GetPropertyChangedSignal("ClassName")`
(gcconn 트릭 재료)까지 정상 동작 확인(version 0.736). **이로써 아래 5번
(스파이크 `10` 잔여)을 에이전트가 대신 돌릴 수 있게 됐다** — 단 A 섹션
재작성이 선행. 아래는 해소 전 원문:

### (구 1번 원문) Roblox Studio에 MCP로 연결 (테스트 자동화용)

Roblox가 2026-02부터 Studio에 **MCP 서버를 내장**했음 — 예전처럼 Rust로 직접
`studio-rust-mcp-server`를 빌드할 필요 없이 Studio 자체 베타 기능으로 켜면 됨.

**설정 방법** (사용자가 로컬에서 직접):
1. Roblox Studio → File → Studio Settings → Beta Features → **MCP Server** 활성화
2. 기본적으로 `localhost:3004`에서 리슨 시작함
3. Claude Code의 MCP 클라이언트 설정(`.mcp.json` 등)에 이 로컬 서버를 추가 —
   이 설정 파일 자체는 내가 대신 만들어줄 수 있으니, Studio에서 베타 기능만 켜고
   "여기 프로젝트에 연결해줘"라고 말해주면 이어서 진행함.
4. 노출되는 툴: `create_object`, `set_property`, `set_script_source`,
   `execute_luau` 등 — Undo 히스토리를 존중해서 Ctrl+Z로 되돌릴 수 있음(안전망 있음).

**주의(사용자가 이미 말한 것)**: Roblox Studio는 잘 죽는 편 — 죽었을 때 살리려고
위험한 명령을 반복 시도하지 않을 것이고, 그런 날엔 MCP 없이 할 수 있는 작업만
하거나 대기함. 이 안전 원칙은 `.claude/conventions.md`에도 적어둠.

**해야 할 일**: 테스트용 place 파일(빈 place 하나, 또는 `quad/test.project.json`
기반 rojo 싱크 대상)을 열어서 베타 기능만 켜주면 됨. 이후 MCP 서버 설정 파일
작성/연결 확인은 내가 진행 가능.

**`SAFETY.md` 제약**: Studio는 메인 계정이 아닌 별도 계정으로만 사용하기로
되어 있음 — 계정 전환 여부를 알려주기 전까지는 MCP 연결을 진행하지 않고 대기함.

### 2. ~~자율 작업 루프/스케줄 설정~~ **[해소됨, 2026-08-28]**

**사용자가 M2를 세션 안 자율 구현 구간으로 확정**했다 — 규약은
`.claude/archive/v2-initial-implementation/m2-implementation-round11-brief.md`, 요지는
`.claude/conventions.md`의 "M2 자율 구현 규약" 항목. cron/`/schedule`은 안 쓴다
(사용자 개입 지점은 단위가 끝날 때 `-round11.md` §4 표를 배치로 회신하는 것뿐).
아래는 해소 전 원문.

사용자가 잠들어 있는 동안에도 계획된 TODO를 이어서 진행하길 원한다는 요청이 있었음
(`req.md` 참고). 이건 세션을 넘어 지속되는 자동 실행이라 다음 중 하나를 사용자가
직접 트리거해야 함(에이전트가 임의로 크론/무인 실행을 켜는 건 파급力이 커서 먼저
확인받는 게 맞다고 판단해 보류함):

- `/loop` — 지금 세션 안에서 일정 주기로 스스로 다음 작업을 이어가게 함(사용자
  대화 종료 전까지). 간단한 자율 반복엔 이걸로 충분.
- `/schedule` — 진짜 cron 스케줄로 별도 클라우드 에이전트를 반복 실행(예: 매일
  새벽에 큐에 있는 다음 plan 문서 하나씩 처리). 무인 상태로 더 오래/여러 날에
  걸쳐 진행하고 싶다면 이쪽.

원하는 주기/범위를 알려주면 그에 맞춰 설정해줄 수 있음. 어떤 걸 골라도, 진행한
내용은 항상 `.claude/`에 자기 문서화(완료 표시, 다음 TODO 갱신)해서 다음 세션이나
사람이 바로 이어받을 수 있게 할 것.

### 4. ~~`question.md` 0-Z 결정~~ **[해소됨, 2026-08-13 열네 번째 세션]**

**더 이상 사람이 막고 있는 결정이 아님.** 사용자가 같은 세션에 직접
`Attr:GetKey(name)` 방향을 제시했고, 트레이싱으로 검증한 뒤
**그룹 전용 키(비공개 `GetKey`) + `AttrKeyHandler`의 이름 claim**으로
확정 → `base/attribute-plan.md` "이름 소유권" 절에 반영. 같이 묶여 있던
재디스패치 모델(0-A)도 같은 패스에서 `base/dispatch-core-plan.md`(신설)로
전면 반영됐고, ⚠️ 배너를 달고 있던 7개 문서 전부 갱신 완료.

**같은 세션에 사용자가 추가로 결정한 것** — `Tag`/`Attr`의 알고리즘을
통째로 quad-base로 옮기고 백엔드는 `addTag`/`removeTag`/`setAttr` 세
op만 주입(웹의 `className`/`data-*` 대응 때문). 상세는
`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는 엔진 op" 절.

> **[2026-08-13 열세 번째 세션] 여기 같이 있던 `0-Y`도 해소됨** — 44개
> 스파이크 재실측으로 원인이 콜백 계약이 아니라 **Luau 자체의 한계**임이
> 확정됐고, 대응은 "파생 State를 만드는 자리마다 결과 타입 명시 주석
> 바인딩" 관례 하나. 규약은 `.claude/base/typing-limits.md`, 근거는
> `.claude/audit/type-recursion-issue/`. 거기서 파생된 작은 확인거리
> 하나(에디터의 Luau 솔버 설정)만 아래 6번에 남아 있음 — M0 착수 때
> 확인하면 되고 지금 막고 있진 않음.

### 5. ✅ [2026-09-01 해소 — 에이전트가 MCP로 완주] Studio 전용 스파이크 `10` 마저 돌리기

**1번(MCP 연결) 해소 직후 같은 날, 에이전트가 A 섹션을 현행 모델로
재작성하고 `execute_luau`로 전 구간 완주했다** — "사람만 가능"이라는 제목
전제 자체가 MCP로 사라진 것. 전 항목 PASS, 아래 "남은 확인거리"는 전량
해소(결과 전문은 `.claude/audit/spike10-full-run-2026-09-01.md`, 파일은
`.claude/luau-test/done/`). 아래는 해소 전 원문:

`.claude/luau-test/`는 2026-08-13에 첫 실측이 돌아 **런타임 12개 전원
통과**했으나, `10-roblox-studio-checks.server.luau`만 **Studio 전용이라
`luau` CLI로 못 돌림**. A 섹션 앞부분(ClassName 신호 미발화, Destroy 시
`Connected` 즉시 전환)은 사용자가 자작 스크립트로 이미 확인
(`.claude/audit/gcconn-trick-verification.md`).

**[2026-08-14 다섯 번째 세션] 지금 바로 돌릴 수 있는 상태가 아님 — 먼저
에이전트가 A 섹션을 재작성해야 함.** `bindLifetime`/`canExecute`/
`unbindLifetime` 재정정으로 A가 폐기된 모델(`canBound`, `bindLifetime`의
`.Subscribed` 세팅, 2-인자 `canExecute`)을 검증 중이라 파일이
`.claude/luau-test/rewrite-required/`로 옮겨졌음. **[2026-08-14 열한
번째 세션 재정정]** 이중 바인딩 게이트는 `canExecute` 하나가 아니라
**`canBound`**로 별도 진입점 재도입됨(`canExecute`는 emit 게이팅 전용,
판정 로직은 비공개 헬퍼 하나를 공유 — `base/lifecycle-pattern.md`의
"`canBound` vs `canExecute`" 절). **남은 확인거리**는 이중 바인딩
게이트(`canBound`)와 unbind/Destroy 후 재바인딩 허용, `value` 쪽에
복사된 gcconn만으로의 생존 판정, Instance userdata 동일성, 그리고
B(Attr의 Instance 참조 타입)/C(CollectionService 태그 왕복) —
목록은 `.claude/audit/gcconn-trick-verification.md`의 "아직 확인 안
된 것"이 소스. GC 강제 트리거가 필요하면
`.claude/luau-test/not-run/gc-trigger-helper.server.luau` 참고. 위
1번(MCP 연결)이 되면 에이전트가 대신 돌릴 수도 있음.

### 7. ~~워크트리 `debounce-throttle-plan` 정리~~ **[2026-08-14 완료 — 할 일 없음]**

Debounce/Throttle 작업에 쓴 워크트리는 **사용자 확인 후 정리 완료**입니다
(`git worktree remove` + `git branch -D worktree-debounce-throttle-plan`,
당시 HEAD `5518055`). 지금 `git worktree list`엔 메인 하나만 남아 있고
`.claude/worktrees/`도 비었습니다.

**잃은 정보 없음** — 필요한 변경은 전부 `main`에 이식돼 있습니다
(`623c931` 백로그 신설 + emit 전파 정정, `6dbce6c` 핸드오버 노트).
지우기 전에 (1) 두 커밋이 `main` 조상인지, (2) 워크트리에 미커밋 변경이
없는지, (3) `git worktree list`에 다른 에이전트 워크트리가 없는지를
확인했습니다. 이 항목은 기록용으로만 남겨둡니다.

### ✅ 8. ~~`const` 바인딩 — 툴링이 언제 지원하는지 사용자만 알 수 있음~~ **[2026-09-10 해소 — 사용자가 pesde 0.7.4 릴리즈(full-moon 신 문법)를 알려줌 + Studio에서 `const` 실행 확인; 메인이 핀 툴체인 전부와 pesde 0.7.3/0.7.4 dry-run 대조 실측]** → `architecture.md` 코드 스타일 절 채택, 핀 0.7.4는 14.3과 함께

`base/architecture.md`의 "코드 스타일" 절이 `const` 바인딩을 **[2026-08-12
기준] 채택 안 함**으로 두고 있음. 사유가 "주변 툴링 미성숙"인데, **이건
에이전트가 확인할 수 없는 정보**라 사용자가 알려주는 게 맞다고 사용자
본인이 정리함(2026-08-16).

**사용자가 설명한 구체적 사정**: 예를 들어 **pesde**의 타입 추출 —
`d.ts`처럼 types를 emit하는 류의 툴링이 있는데, 아직 미성숙해서 `const`를
제공하지 못하는 상황. **언제 다시 사용 가능해지는지가 명확하지 않음.**

**사람이 할 일 — 둘 중 하나**:
1. `const`를 쓸 수 있게 되는 시점을 파악해 알려주거나,
2. 사용 가능해지는 순간 에이전트에 알려줄 것.

둘 중 어느 쪽이든 **에이전트는 스스로 판단하지 않고 대기**한다 — 알려주기
전까지는 `architecture.md`의 "`const` 바인딩도 Luau 공식 문법" 절이 정한
"새로 짜는 코드는 일단 `local`로" 원칙을 그대로 따름. 알려주면 그때
`architecture.md`의 해당 절을 갱신하고 기존 코드의
`const` 전환 범위를 같이 상의할 것.

### ✅ 11. **[2026-08-22 신설 → 2026-08-24 해소] 마일스톤 순서 결정**

사용자가 **(a) 순서 교체**를 선택해 닫혔다 — 반응형이 M2, 디스패치가 M3다.
결정과 근거는 `.claude/archive/question-resolved.md`의 "마일스톤 경계" 절,
새 마일스톤 구성은 `archive/v2-initial-implementation/roadmap.md`의 M2 배너가 소스.

**✅ [2026-08-25 해소] 그 교체로 한때 `question.md` 최우선 절에 항목 둘이
올라왔었다** — 중간 State GC 실측과 동적 키 표면(옛 `store:GetDynamic`) 위치.
**둘 다 닫혔다**(GC는 `_hold` 불변식으로, 표면 위치는 콜론 유지 + 예약 키
진단 타입 함수로) — 7라운드 손 트레이싱 후속이 소스이고, 2026-08-26 8라운드도
"M2 착수를 막는 항목이 하나도 없다"로 재확인했다. **`question.md` 최우선
절은 지금 비어 있다.**

---

### ✅ 12. ~~Studio에서 `ReflectionService`가 Hidden/Deprecated 프로퍼티를 Write 권한과 함께 주는지 확인~~ **[2026-09-09 해소 — 사용자 실측: `Font`/`FontSize`/`TextWrap`/`Transparency` 넷 다 `Permits.Write == Edit`("아마 예상된 결과로 보임")]** → 같은 날 gen-d 패치 적용

사용자 결정(2026-09-09): 생성 `D`에 Deprecated 프로퍼티 전부 + Hidden 중 `Font`/`Transparency`를 되살린다(v1 마이그레이션 자동완성용 — 실측·패치는
`.claude/audit/deprecated-props-spike-2026-09-09/REPORT.md`). 그런데 `quad-roblox/src/Handlers/Property.luau`의 런타임 매치가 `ReflectionService:GetPropertiesOfClass`의
`Permits.Write`라, 그 서비스가 Hidden/Deprecated 멤버를 빼면 타입은 광고하는데 런타임이 `Dispatch: no handler matched key Font`로 죽는다. mock 스펙은 이걸 못 본다.
**Studio 커맨드 바에서 한 줄**(에이전트 MCP 호출은 이 세션 분류기에 막혔음):

```lua
for _, d in game:GetService("ReflectionService"):GetPropertiesOfClass("TextLabel") do if d.Name == "Font" or d.Name == "TextWrap" or d.Name == "FontSize" or d.Name == "Transparency" then print(d.Name, d.Permits and d.Permits.Write) end end
```

넷 다 이름과 Write 권한이 찍히면 에이전트가 패치를 적용한다(`todos.md` 00번). 하나라도 안 나오면 그 프로퍼티는 타입에서도 빼야 한다(계약 불일치).

### ✅ 13. ~~[2026-09-07 7순회 `H-429`] Studio 1줄 프로브 — 기본값과 같은 props의 OnChange 초기 발화~~ **[2026-09-10 밤 해소 — 에이전트 MCP 실측: 엔진 0회 / mock 1회, 셋째 헤지 확정(`audit/studio-docs-2026-09-10.md` A절); `onchange-plan.md`·레퍼런스 05-onchange 갱신]**

`Frame { Visible = true, OnChange("Visible", fn) }`(Frame 기본 `Visible = true`)에서 `fn`이 몇 번
도는지. mock은 같은 값 대입에도 `Changed`를 쏘지만 실 엔진은 동일값 대입에 시그널을 안 쏘는
것으로 알려져 있어 CLI 1회 / 엔진 0회로 갈릴 수 있다 — `onchange-plan.md` "초기값 발화 계약"
따름정리에 셋째 헤지(기본값과 같은 값)를 넣어 두었고, 실측 결과로 그 문장을 확정/삭제할 것.

### 15. [2026-09-10 신설] 문서 사이트 Cloudflare Pages 1회 준비 + 게시 뒤 문서 표시 정리

1. ✅ **[2026-09-10 완료 — <https://quad.qwreey.moe/> 확인]** **Cloudflare 인증·프로젝트 생성**(샌드박스 밖): `docs/site/DEPLOY.md`의 "1회 준비" 셋(`npm install` → `npx wrangler login` → `npx wrangler pages project create quad-docs --production-branch main`). 그 뒤부터는 `npm run deploy`. **커스텀 도메인 `quad.qwreey.moe`**(사용자 결정 2026-09-10): `astro.config.mjs`의 `site`는 이미 그 값 — 첫 배포 뒤 대시보드 Custom domains에서 붙이면 끝(순서·외부 DNS 경우·API 경로는 `DEPLOY.md`).
2. ✅ **[2026-09-10 완료 — 게시 확인 뒤 에이전트가 정리, 소비자 레이아웃도 빈 roblox 프로젝트에 `^3.0.0` 설치로 실측]** **3.0.0 실게시 뒤** 설치 문서의 "[2026-09-09 기준] 이 경로는 아직 제공되지 않습니다" 표시(`docs/getting-started/00-installation.md` — pesde 절; Wally·rbxm 절은 여전히 미제공이라 그대로)와 오버뷰 1·2편의 "아직 배포되지 않았습니다" 문장을 지울 것(에이전트가 해도 됨 — 게시 확인만 알려주면 된다). 소비자 프로젝트에서 넷의 roblox 사본이 `roblox_packages/` 한 폴더로 들어오는지도 그때 확인(설치 문서 2단계의 [2026-09-10 기준] 문장).

### ✅ 16. [2026-09-10 밤 신설, 같은 밤 해소 — 대기 한 줄로 결정] 문자열 `require("@game/…")`의 복제 전 동작 실측

**[2026-09-10 밤 MCP 실측(Play Solo)]** `StarterPlayerScripts` 첫 줄의 `require("@game/…")`는 두 번 다 첫 시도 성공(그 시점 `game:IsLoaded() == true`), 없는 대상은 **기다리지 않고 즉시** `could not resolve child component` 에러 — "async" 전제는 틀리고 웹 리서치("즉시 실패")가 맞다. **남은 것**: Play Solo는 서버·클라이언트가 한 프로세스라 복제가 사실상 즉시 끝난다 — 실서버 접속 클라이언트에서 첫 줄이 복제보다 앞설 수 있는지는 미실측(**[2026-09-10 밤 사용자 결정]** 진입점에 `game.Loaded:Wait()` 한 줄을 둔다(실접속 클라이언트는 동적 복제라 순서를 모른다 — 사용자). 실접속 실측은 하지 않아도 된다 — 이 항목 닫힘.)

시작하기 01(설정 모듈·진입점)이 `require("@game/ReplicatedStorage/roblox_packages/quad_base")` 형태를 권한다(사용자 결정 — 타입이 살고, 설정 모듈 재수출까지 strict 통과 실측). 에이전트 웹 리서치(DevForum 발표 스레드 FAQ, 2026-09 기준)는 문자열 require가 대상이 아직 복제되지 않았으면 **기다리지 않고 즉시 실패**하며 `game.Loaded:Wait()`를 권한다고 하고, 이건 사용자 전제("async")와 어긋난다. 실기기에서 확인할 것: `StarterPlayerScripts`의 LocalScript가 첫 줄에서 `require("@game/ReplicatedStorage/…")`를 불렀을 때 (a) 그냥 되는지 (b) 간헐적으로 실패하는지 (c) yield로 기다리는지. 결과로 01의 접힌 캐비엇 한 문장("[2026-09-10 기준] 실기기에서 확인하지 않았습니다")을 확정하고, 필요하면 `game.Loaded:Wait()` 한 줄을 진입점에 넣는다. 문항은 `.claude/question.md` 3절 D9.

---
Sources (MCP 리서치): [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server), [How to Connect Claude Code to Roblox Studio — Clauder Navi](https://www.clauder-navi.com/en/claude-roblox-studio)
