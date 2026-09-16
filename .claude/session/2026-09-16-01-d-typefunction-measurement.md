# 2026-09-16 (1) — 생성 `Declaration` 팩토리화 실측과 결정(stable D / unstable type function 경로)

사용자 요청: *"더 할 일 특히, D부분 타입 조절에 대해 의논 시작해볼래? 우선 lsp 실측부터 보고, 내가 자동완성으로 보고해야할 studio 에 대해 돌릴 코드도 준비해야해."* 2026-09-15에 "급한 다음 작업"으로 지정됐던 D 타입 함수 팩토리화의 착수 전 실측 세션. 실측 팩과 결과는 `audit/d-factory-studio-probe-2026-09-16/`(`REPORT.md`), 승격은 `base/typing-limits.md` 8.18 정정·8.22.

## 1. 전제 좁히기(사용자, 세션 초반)

*"로블록스 타입이 없는 lsp/checker 같은 경우 UDim2 같은것 부터 에러 나서 그건 범위에 못 둘듯. … 사실상 roblox 를 아는 체커/lsp 만 지원 가능함. 큰 문제는 그 엔진/lsp/체커들이 어떻게 달라지느냐, 같은 구현을 보느냐야. 직접 만들더라도 외부의 UDim 타입이랑 다른 뭔가로 크래시 나면, 의미가 없거든."* → 대조 축을 "Roblox를 아는 두 구현"(luau-lsp+defs / Studio 내장)으로 잡고, 실측의 질문을 "체커가 같은가"와 "정의가 같은가"로 나눴다.

## 2. 리눅스 실측(메인 + opus 하네스)

`keyof`/`index`는 extern 타입에 정상이나 `keyof`엔 메소드·이벤트·읽기 전용·소문자 별칭이 다 든다. 사용자 정의 type function은 `properties()`/`readparent()`/`tostring`으로 클래스를 걸어 올라갈 수 있고(`:name()`·`:parent()` 없음), props 테이블(Tween/State/None 팔·이벤트 콜백은 `Connect` 2번 인자·자식 인덱서)과 재귀 Modifier 테이블(체이닝·`__quadModifier` 리터럴) 시제품이 양성·음성 전부 통과. 20클래스×100호출 0.77s(기본 한도) vs 생성 D 1.12s(한도 플래그 셋 필요). LSP completion 하네스(`dprobe/lspc.py`)로 type function 테이블의 키 자동완성 79필드 확인. 덤프 스코프 31클래스에서 드롭 이름 46·충돌 `Scale` 하나.

가장 큰 부산물: **8.18이 틀렸다.** 처음엔 "정의 모듈이 한 번 인스턴스화하면(프라이밍) 소비자가 임의 인자로 써도 된다"까지 좁혔고(Echo 실험 — `Echo<"z">` 프라이밍 뒤 소비자 `Echo<"q">` 정상), 실코드 `type-version-check`에 한 줄 넣어 편집기 게이트가 살아나는 것도 확인했다. 그런데 사용자 VSCode·Studio는 프라이밍 없이도 2-c를 잡았다(사용자 주석: *"2-c 생략 이유는 같은 출력이라 그랬음"*). 사용자가 *"여기에 깔린 code server 에 LSP 가 살아있어. 인자를 딸 수 있는지 볼래?"* — `ps`로 확장 서버 인자를 땄더니 `--no-flags-enabled` + `globalTypes.PluginSecurity.d.luau`. opus 서브에이전트가 확장이 보내는 플래그 집합(동기 590개)을 재구성해 재현하고 bool 96개를 이분탐색 → **`LuauDoNotExportBrokenTypeFunction`** 하나. CLI `analyze`는 전 FFlag 켬(`--help` 원문 "do not enable all Luau FFlags by default")이라 `true`, Luau 기본·Roblox 동기값은 `false`. 메인이 실코드 `CheckVersion`(pesde 링크 경로)으로 재확인.

## 3. Studio·VSCode 실측(사용자 — 주석으로 회신)

사용자 요약: *"보이는 바로는 LSP 는 같다, - 근데 정의가 다르다."* 진단 문구 글자까지 동일(*"에러 규격이 완전히 동일 하다 … 내부적으로 쓰는 lsp 는 같은 가능성이 보임"*), 자동완성·체이닝 둘 다 됨. 갈리는 것: `Frame` 체인 개수(Studio 1>55>16>0>58>6 / VSCode 1>45>11>0>53>5 / 핀 defs 1>50>15>0>55>5), Hidden `Transparency`가 VSCode defs엔 없음, Studio `keyof`에 deprecated `BackgroundColor`·`DataCost`, 이벤트가 Studio에선 `extern:RBXScriptSignal`(*"Event 부분만 따로 리스트업 해서 Name -> Func 하는 조합기를 만들어야할 가능성"*), `FontFace`가 Studio는 테이블. 읽기 전용 표시는 셋 다 없음. `script.Parent` require는 VSCode에서 sourcemap 없이 깨져 문자열 require로 통일. 05: *"컴플랙스 같은건 안떠."* 06: `index<Frame,"MouseEnter">`의 `Connect`가 Studio에서도 콜백 인자를 정직하게 검사(`(string)->()` 거부), 추가 실측 `index<Te,"Connect">` → `(func: (x: number, y: number) -> ()) -> RBXScriptConnection`. rojo가 프로젝트 파일이 든 폴더를 `$path`로 잡으면 stack overflow(*"project 파일이 바로 옆에 있어서 터지는건가?"* — 맞음, `src/` 분리).

## 4. 결정(사용자)

메인 권고는 "생성 D 유지"(체커는 같고 정의가 갈리므로 순수 팩토리는 표면을 defs 버전에 맡기게 되고, Studio에선 한도 문제도 없음). 사용자: *"확인. 그 경로는 unstable 경로로 두고, 언제든 변경될 수 있다로 둬줘. 지금 쓰는 일반적인 표면을 릴리즈에 stable 로 둬야겠음. 다만 타입 함수로 만들어낸다는건 gen 을 필수가 아니게 둘 수 있고 fallback 으로 gen 이 굴러가고, 각각 필요한 표면만 생성할 수도 있게돼. 그리고 타입 함수를 넣으면 D의 줄 수가 확실하게 줄어들어. - 그게 목적이였음. 엄청 큰게 있으면 사람들은 경계하고, 파일 크기를 보고 라이브러리 크기를 측정하려 들어서 … 이 역시 이점 trade-off 에 비해 크지 않다면 고려되지 않더라도 돼. 1급 대상은 아니야. 다만 user side 에서 breaking changes 가 나오는걸 먼저 쳐내고 싶었어서 우선순위를 높게 둔거야. 다만 그건 unstable 으로 두는 경로가 존재해."*

반영: `typing-limits.md` 8.18 정정 + 8.22 신설, `type-version-check` 프라이밍(`_Prime`, 패키지 CHANGELOG Fixed), ROADMAP 백로그 항목(unstable 경로 + 만들 때 규칙), HUMAN_TODO D 방향 확정, `research/public-surface-pre-adoption-review.md` (28) 닫힘, `audit/README.md`·`REPORT.md`. test.sh는 "전부 켬" 그대로(프라이밍 누락 조기 경보).

후속(같은 날): 사용자가 `06-events.luau`를 다시 돌려 `[P6-2]`~`[P6-5]` 회신 — extern 시그널은 `readproperty` 불가(테이블 전용)라 `properties()`로 `Connect`를 찾아야 하고, 그 파라미터는 `(self: RBXScriptSignal, 콜백)`으로 콜백이 2번째(리눅스와 같음). `readparent()`는 같은 이름의 원형을 돌려준다. 사용자 자체 프로브(TextButton `properties()` 29개)로 Studio 목록에 메소드·Deprecated/Hidden·읽기 전용이 혼재함도 확인. 미완 없음.

## 5. 같은 날 후속 — 시한 있는 결정 문항 대화형 처리(F·2-6·§1 용어)

opus 에이전트가 열린 결정 문항 49건을 추려 온 뒤(시한 있는 것 7) 사용자가 *"시한 있는 것부터 하나씩 대화형으로 보자"*. HUMAN_TODO F: *"기본적으로 연휴 구간 끝나는 10월쯤으로 잡고 있어. 사내 첫 사용 시인데 … breaking 주간은 우리가 '끝내도 되는 정도다' 가 오는 시점까지 릴리즈를 지연할 수 있어 … a 에 가까우면서 동시에 b에도 가까움. c는 전혀 아니야."* → 잠정 2026년 10월, 종료 통보는 사용자. `docs-review` 2-6 여덟 건 일괄 승인(*"전부 맞는 요소고 진행해도 돼"*) → opus 반영, 5번은 `nativeMove`/`nativeSwap`이 의도된 no-op임을 확인해 부기만 바뀐다는 표현으로 좁힘. `question.md` §1 용어 여섯: `Slot`·`Brand`(사용자: *"kind 는 분법적 요소로 보일 수 있고 … Marker 는 *Marker 타입이 존재해서 … 바꿀 이유가 없음"*)·`Tag`류·`Attr`류 유지, `hintValue`→`nextValue`(코드·공개 문서 0건이라 비파괴). `canExecute`: 메인이 `canEmit`을 제안했으나 사용자가 emit/epoch 관계론과 방향이 다르다고 반대 → 사용자 요청으로 sonnet 두 시각 독립 검토(둘 다 `canEmit` 기각, 유지 vs `canRun`) → 사용자 *"나도 유지로 닫는거 동의해. 원래부터 이견이 없었거든."* §1은 이제 열린 항목 없음.

**Slot foreign Instance claim 정책(같은 날, `question.md` §2)** — 메인 권고 (a) 자동 claim에 사용자: *"명시적으로 claim 안 한게 다른 경로로 claim 될 수 있다는거고, 마법 아님? 난 사실 b쪽으로 기우는듯"*. 사실 확인(사용자 질문 *"foreign instance 에 bindlifetime 이 slot 에 넣는것 만으로 자동으로 걸림?"*): 안 걸린다 — `rawAdd`는 `elementOwner` 부기 + `_elements` 삽입 + 물리 op뿐이고 Slot의 `bindLifetime`은 전부 자기 옵저버를 `physicalTarget`에 묶는 것이라, (c)는 "조용히 들어가 밖에서 Destroy되면 stale"이 된다. 결정 **(b)**: 미claim이면 `Add` 에러. 판정은 quad-roblox `InstData`의 gchold 유무(*"gchold 같은게 있는 경우가 claim 된 판정처럼 되는거지?"* — 맞음, `nativeClaim`이 한 번 넣고 이중 claim 에러도 같은 검사)를 op 하나로 노출, mock은 항상 참.

**구현(같은 날)**: `isClaimed(inst): boolean` 계약 op(quad-types `Backend`, quad-base `LifetimeHandle` 스텁, quad-roblox gchold 유무, mock은 mock 인스턴스면 참 — lazy claim이라 게이트 스펙은 슬롯을 덮어써서 검사, `spec.slot` 22), 게이트는 `Slot/Elements.luau` `wrapElement`의 `isInst` 검사 바로 뒤(모든 진입 경로가 지나는 한 자리). 문서: core/06(원소 대수 거부 목록 + Add 규칙), extend/01(슬롯 20개·§3 다섯), CHANGELOG Added(op — 프로바이더 BREAKING)·Changed(Slot BREAKING + 옮기는 법). test.sh exit 0(스펙 60).

**docs-review 2-2(같은 날)**: 사용자 *"권고대로"* → (d) 루트 재수출 블록에 `<Class>Modifier`/`Into<Class>`/`<Class>Elem` 편입(`gen-d.py`, 141 export), how-to 01·05 `RobloxModule.…`, 설치 문서 타입 재익스포트 절, `spec.rootexports` 양성; quad-roblox 검사 3.23s(9/15 시제품과 같음). 시한 있는 결정 문항 일곱 전부 닫힘.

## 6. 체크포인트 — 감사 루프·code-review(같은 날 밤)

사용자: *"관례대로 체크포인트와, code-review 를 진행하고 compact 를 준비하자"*. `quad-doc-auditor` 네 라운드(base 정합성 → 인덱스 레이어 → 코드 주석·공개 문서·audit → 앞 라운드 수정분 재검), 새 발견 1→4→2→0으로 수렴. 반영: `architecture.md` EngineOps 줄에 `isClaimed`(주입 슬롯 스무 개), `HUMAN_TODO.md` F 문장의 "아직 열림" 정정, `session-summary.md` §5 요약 추가, `research/README.md`의 public-surface·v1-compat 행, `question.md` Slot foreign 항목의 옛 본문("권고 (a)")을 요약으로 압축, 스킬 치트시트에 새 Slot 에러 행.

`/code-review high`(`f6618c1..HEAD`, 파인더 8·검증자 2 전부 opus) 발견 10, 처리: (1) **확정** — `isClaimed` 게이트가 `State`에 담긴 요소에선 wrapper의 reconcile(뮤테이션 창 안)에서 던져 `rawAdd` 뒤 유령 요소가 남았다 → `prepareElements`가 State의 현재값(occupant)을 pre-pass에서 검사하도록 고침(`spec.slot` 29에 단언). `:List`/`:Single` `updateFn`이 미claim을 돌려주는 경우는 Q40 선례(창 안 예외 → 동결, UB)와 core/06:384의 기존 계약 그대로 — 문구에 "claim되지 않은 Instance"를 더함. (2) **확정** — how-to 03·core/06·quadnomicon 05가 "밖에서 만든 Instance를 `OwnsElements = false`로 태우라"고 권하던 것 → 셋 다 "먼저 `Claim`"을 붙임(파괴 여부와 소유는 다른 축), CHANGELOG 옮기는 법에 `Extract`·List 주의. (3) **사용자 문항** — 정적 자식 자리 `D.Frame { foreign }`엔 같은 게이트가 없다(`InstanceChild.luau`는 `isInst`만) → `question.md` §2 신설, 권고 (a) 대칭 게이트. (4) **확정** — 8.18 정정의 "전부 켬 analyze가 조기 경보"는 거짓(미프라이밍 오용이 exit 0) → 문장 정정 + `type-surface-check.py`에 프라이밍 게이트(소스 폴더의 `export type function F`마다 같은 파일 `F<` 요구, test.sh 경유). (5) **확정** — `_Prime`의 `export`는 불필요하고 공개 이름만 늘림 → `type _Prime`으로, 8.22 관용구·CHANGELOG 문장 수정. (6) 주입 op 손 사본(`doc-coverage.py` INJECTED·`00-index`·core/10·quad-base `LifetimeHandle` 주석·`spec.lifetime` 스텁 목록)에 `isClaimed`. (7) `todos.md` 90행의 8.18 옛 주장 정정. (8) HUMAN_TODO D 본문·public-surface 361/419 취소선. (9) `slot-plan.md` 화이트리스트·의사코드에 `isClaimed`. (10) 프로브 README 06 행·typing-limits 백틱 경로·spec.slot 절 번호 22→29. 4라운드 의심(`init.luau` 헤더의 H-306 "독립" 주장이 재검증된 사실이 아님)은 주석을 "미검증 추정"으로 낮춤.

## 7. 밤 — 대칭 게이트 + 다각 결함 탐사(round10)

사용자: *"권고대로 대칭 게이트 가면 될것 같아. 전부 닫아지고 사용자 안이 안 나오면, 객관적 평가가 되는 subagent 를 fork 해도 좋아. 예산은 충분해 … given enough eyeballs all bugs are shallow. 모든게 다 닫아진걸로 보여도, 계속 뭔가 나오던게 quad 라, 아직 의심을 지우긴 이른것 같아. 체크포인트 찍고, 내일 검토할 요소들을 담는 파일을 만들어줄래?"* 정적 자식 자리 `isClaimed` 게이트(`InstanceChild.luau`, `1bc6d3e`) 뒤 여섯 갈래 탐사(A Slot·소유권 / B 반응형 코어 / C quad-roblox 층 / D 타입 표면 / E 문서 대 코드 / F quad-base 정적 전수)를 병렬로 돌렸다 — 근거가 코드 실행인 조각이라 팬아웃 규약에 맞고, 문서 추론은 메인이 판정했다. 결과는 `qa-request/post-implementation-review-round10.md`: 반영 `H-517`~`H-530`(HIGH `H-517` State 요소 검사가 삽입 뒤; 입구 게이트 여섯; Debounce 호출자 층 `H-509` 재발; 메시지 오도 둘; 문서 사실 열아홉), 사용자 문항 `Q48`~`Q54`(HIGH Q48 정적 자식 소유권 부기 부재 — 새 표면이라 문항). 반응형 코어 차등 퍼즈(시드 1,100)·Slot 퍼즈(6만 연산)는 0건. 내일 검토 파일 = round10 §4.

