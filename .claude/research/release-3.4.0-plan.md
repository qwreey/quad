# 3.4.0 실행 계획 — Declaration을 타입 함수로 (BREAKING)

> **[2026-10-20 신설 — 사용자 요청 "계획 잡기부터 천천히", 결정 아님]** 설계 결정은 전부 다른 문서가 소스다 — 표면은
> `research/declaration-surface-plan.md` 5절, 이름은 `research/declaration-naming-table.md` 5절, Spread는
> `research/component-flatten-sugar-plan.md` 5절, 스텁 표·주석 규약은 `qa-request/code-quality-review-round15.md`(H-929·Q188),
> 실측은 `audit/decl-typefn-probe-2026-10-16/REPORT.md`. 이 문서는 **순서·단위·게이트·남은 결정**만 쥔다. 바뀌는 자리 전수 조사는
> 2026-10-20 sonnet 인벤토리(아래 1절에 요지).

## 1. 범위 — 바뀌는 자리 (2026-10-20 인벤토리 요지)

- **quad-types** (`src/init.luau` 한 파일): `Quad` 타입의 `New`→`NewModule`, `Modifier`(→ `Raw.Modifier`), `newMapperClass`(→ `Raw.Mapper`), 새 `Raw`, 이름 정리(`FieldOut`→`ModifierFieldOut` 등). `Quad`에는 원래 `Declaration`·`OnChange`·`Out`이 없다 — `RobloxExtension` 교집합으로 실린다.
- **quad-base**: 모듈 테이블의 `New`·`Modifier`(init.luau), `newMapperClass`(Claim.luau가 심음) 자리 이동, 스텁 표(H-929) + 최상위 일곱 스텁, `Raw.Spread` 런타임과 펴기 단계 확장(`Dispatch/Modifier/init.luau` flatten). 문구에 옛 이름이 든 에러 일곱(Quad0026·0029·0034·0106·0108·0241, quad-roblox의 0219) — 번호는 그대로, 문구와 `docs/reference/errors/` 절만.
- **quad-roblox**: 생성 모듈 `src/Declaration/init.luau`(5145줄 — 런타임은 끝 180줄: `Instance.new`+`nativeClaim`+`drive`, `TypedFactory`·`DefineSubtype`·`newMapperClass` 등록)와 `init.luau`의 GENERATED ROOT EXPORTS 블록(약 128줄)·손 재수출(`Declaration`·`DeclarationMapper`·`PropTypes`·`OnChangeFn`·`OutFn`) 삭제, `RobloxFactory.luau` 반환 테이블 교체, `Handlers/OnChange.luau`의 `OnChange`/`Out`을 클래스 먼저 커리로(Quad0221~0224), 새 `OnEvent` 디스크립터 핸들러(`OnChange`와 같은 모양), 새 `ForClasses`, 타입 함수 본체와 정책 데이터.
- **scripts·게이트**: `gen-d.py`(emit → 데이터만), `test.sh` 17·22·29행(생성 파일 검사)과 luau-lsp 한도 플래그 셋, `type-surface-check.py`의 파일 목록, `publish.py` 스테이징의 `gen-d.py emit`, `doc-coverage.py`(새 `q.*` 이름마다 reference 헤딩 필요), 새 변환 스크립트.
- **스펙**: quad-base 테스트의 `q.New()` 17파일·`q.Modifier` 6파일, quad-roblox 테스트 20파일(Declaration 226 히트, `spec.rootexports`·`spec.d`는 성격이 바뀜).
- **킷 둘**: devui `D.` 293 히트/49파일, material 966/157, 클래스별 타입 이름 300여, 설정 모듈 다섯(`Quad.luau`). 킷 반사 데이터(`test/support/gen-reflection.py`)는 덤프를 계속 읽으므로 그대로.
- **문서**: `docs/` 정본 `D.` 585/67파일, `Declaration` 136/51, `q.New(` 48/21, `OnChange(` 49/18 등(사이트 사본은 `sync-docs.py`가 복사). reference/roblox 02~05·core/01·core/08·extend/01·errors 다섯이 다시 쓰이고, 나머지는 코드 블록 변환. CHANGELOG·README 다섯·skills/agents.
- **`.claude/`**: 확정된 트랙을 `base/`로 승격(새 base 문서), `base/typing-limits.md` 8.22·`base/modifier-plan.md` 11절·`base/architecture.md` 소스 트리·`base/docs-handover-registry.md`.

## 2. 진행 원칙

- **공존 후 제거.** 새 표면을 옛 표면 옆에 먼저 세우고(교집합에 둘 다), 스펙·킷·문서를 옮긴 뒤 마지막 단위에서 옛 것을 뗀다. 그래야 단위마다 `./scripts/test.sh` exit 0과 킷 `test/run.sh` exit 0을 지킨 채 커밋할 수 있다(옛 것을 먼저 떼면 킷 둘이 변환 전까지 빨갛다). 공존은 미게시 중간 상태라 공개 계약이 아니다.
- **타입 함수 본체는 quad-roblox에** — 2026-10-16 "백엔드가 런타임과 타입을 함께 채운다"(백엔드 계약)의 귀결. quad-types는 엔진 무관한 것만(`Raw` 쪽 무검사 타입, 마커 정의 규칙).
- 매 커밋: doc-check ERROR 0, 공개 표면이 바뀌면 `CHANGELOG.md` `[Unreleased]` 한 줄, 새 raise는 `QuadNNNN`(`error-codes.py --next`)과 errors 문서 절, 새 주석은 이유 문장 + `Ref:` 꼬리(Q188).
- 무거운 실측은 conventions의 choom·예산 규칙, Studio는 quad-test만.

## 3. 단위 (순서대로)

**단위 0 — 사전 실측.** 섞인 대형 파일(꺼내 둔 Elem·Modifier·Spread·`:Append`·OnChange·OnEvent를 섞은 수천 줄)의 too complex를 sync·vsc·pin으로 잰다(2026-10-20 할 일). 무너지면 계획 전체가 멈추므로 맨 앞. Lib4·Ext4 위에서 프로브로.
**[2026-10-20 결과]** 지금 꼴은 한 모듈 약 2300줄(호출 약 1500)에서 무너졌다 — 원인은 Studio 동기화 값 `LuauSolverConstraintLimit=1500`, 꺼내 둔 생성자의 인자 타입이 줄지 않은 타입 함수 적용이라 호출마다 제약이 쌓임. **생성자·Spread·Modifier 팩토리의 함수 타입을 통째 타입 함수로 만들면**(꺼내 두는 자리에서 한 번 줆) 5730줄도 깨끗하고 자동완성·hover는 같다 → 단위 2의 구현 꼴로 채택(공개 이름 변화 없음 — `ElemCtor<C>`가 그 타입). 이벤트·변화 디스크립터는 한 모듈 약 1200개가 문턱(문서에 적을 것). pin(luau-lsp 1.69.0)만 테이블 안 `OnEvent` 콜백에 문맥 타입이 안 흐른다 — 아래 4절. 근거 `audit/decl-typefn-probe-2026-10-16/REPORT.md` 끝 절.

**단위 1 — 정책 데이터와 생성기.** `gen-d.py`를 데이터 전용으로: 클래스 맵 둘(만들 수 있는 것 / 추상 포함), 정의 클래스 기준 Policy(Deny·DenyIn·DenyWrite·Inject·Child), Hidden·Deprecated 허용목록(비GUI `Position` 등, `GuiObject.Transparency` 드리프트 대응 — M4 발견 셋). `check` 게이트는 새 데이터 파일을 본다. 아직 아무도 안 쓰는 새 모듈이라 공존에 해가 없다. **[2026-10-20 완료]** `gen-d.py`: 되살리기 허용목록을 정의 클래스 기준 `LEGACY_KEEP`(어느 태그든 유지 — 새 덤프에서 `GuiObject.Transparency` 유지 확인)과 비GUI `HIDDEN_CORE_KEEP`(BasePart·Attachment 위치·방향)로, normalize에 `policy`(만들 수 있는 클래스 사슬 전부 — owner 138·이름 588 / 쓰기 owner 74·이름 153), emit이 `quad-roblox/src/Surface/Data.luau`(CreatableMap 31·ModClassMap·DenyIn·DenyWriteIn·Inject·Shorthand)를 찍고 `check`가 함께 본다. 덤프는 지금 판(268c) 그대로 — 새 덤프로 올리는 것은 공존 기간 잡음을 피해 뒤로.

**단위 2 — 타입 함수 본체.** Lib4를 quad-roblox로 옮겨 다듬는다(보강 셋 — 진짜 `NewChild`, Ref 마커 팔, `StateMarker<T | Tween<T>>` — 포함), 결정된 타입 이름 전부(`Modifier<C>`·`ModifierInto<C>`·`Spread<C>`·`SpreadInto<C>`·`Props<C>`·`PropsArrayItem<C>`·`PropsHashPart<C>`·`MapperProps<C>`·`ElemCtor<C>`·`ModifierField<T>`/`ModifierFieldOut<T>`·`PropertyMap<C>`·`OnChangeDescriptor<K>`·`OnEventDescriptor<K>`). 게이트 하나 추가: 레포 핀 defs로 맵의 모든 클래스 표면이 never가 아닌지(타입 함수엔 pcall이 없다 — 2026-10-19 위험 문단).

**단위 3 — base 런타임.** `q.Raw`(`Modifier`·`Spread`·`Mapper`)와 `q.NewModule`을 옛 이름 옆에 세운다. 스텁 표(H-929) + 최상위 일곱 스텁. `Raw.Spread`: 깊이 1, 먼저 자리 잡은 것이 이김, `:Append`(Spread만·반환 없음), 펴질 때 잠금, debug 경고(Spread가 가져온 함수가 다른 Spread에 밀릴 때). 펴기 단계 Spread 전개 → Modifier → PreRef → 본문(배열 값은 놓인 자리에). quad-types `Quad` 타입에 새 이름.

**단위 4 — quad-roblox 런타임.** `Elem`·`Modifier`·`Spread`·`Mapper`·`OnChange`·`OnEvent`·`Out` 커리와 `ForClasses`를 `RobloxExtension`에 옛 `Declaration`·`OnChange`·`Out` 옆에 세운다(같은 이름인 `OnChange`·`Out`·`Modifier`는 옛 꼴과 새 꼴의 인자 모양이 달라(옛 `OnChange(name, fn)` 대 새 `OnChange "Frame"`, base `Modifier({…})` 대 `Modifier "Frame"`) 공존 기간엔 인자로 갈라 받고 단위 6에서 옛 갈래를 뗀다 — 미게시 내부라 방법은 구현 때 메인이 정한다). `OnEvent` 핸들러. 새 스펙.

**단위 5 — 변환 스크립트.** 시제품(`harness/codemod-proto.py`)을 `scripts/`로 옮기며 고칠 점 열하나(REPORT "킷 규모 시험" 8절)를 반영하고, 기계로 못 바꾼 자리·`any` 캐스트 경유 D를 반드시 목록으로 낸다.

**단위 6 — 갈아타기.** 스크립트로 quad-base·quad-roblox 스펙과 킷 둘을 옮기고, 같은 이름 셋(`Modifier`·`OnChange`·`Out`)을 새 꼴로 바꾼 뒤 옛 표면(생성 모듈·루트 재수출·`New`·`newMapperClass`·base `Modifier` 최상위)을 뗀다. 기계로 못 바꾼 자리(Sheet.luau `HostHook` 등)는 손으로. devui에 `FieldSpread`/`TrackSpread`. test.sh 17·22·29행, `type-surface-check.py`, `publish.py` 스테이징 정리. 이 단위가 BREAKING의 실체라 커밋이 크다.

**단위 7 — 사용자 문서.** reference/roblox 02~05·core/01·core/08·extend/01·errors 다시 쓰기, 나머지는 코드 블록 변환(스크립트 + 산문 손질), 우선순위 표(인라인 > Spread(앞이 이김) > Modifier(뒤가 이김), JS 전개와 다른 이유)와 Store·Context·Modifier·Spread·토큰 다섯 비교(사용자 2026-10-20), 탈출구 레시피(맵은 100개 아래로 분야별로), 3.3→3.4 옮기는 법, CHANGELOG BREAKING, README·skills.

**단위 8 — 설계 문서와 마무리.** `base/` 승격과 갱신(1절 끝 목록), test.sh 한도 플래그 셋을 뗄 수 있는지 재기(생성 D 때문에 들어간 것), Studio(quad-test) 확인, `/code-review`(인자에 서브에이전트 opus·검증자 상한), 감사 루프. 릴리즈(bump·태그·게시)는 사용자 결정.

## 4. 남은 결정 (사용자)

- **레포 핀 luau-lsp를 1.69.0 → 1.70.1로 올릴지.** 단위 0에서 1.69.0만 요소·Spread 테이블 안의 `OnEvent` 콜백 인자를 `unknown`으로 둬 거짓 양성을 낸다(1.70.1은 사용자 VSCode 확장 판). 3.4.0 스펙이 그 꼴을 쓰므로 게이트가 걸린다. 메인 권고: 올린다(`mise.toml` 한 줄 + 게이트 재확인).

- **[2026-10-20 닫힘] 커리 첫 인자의 런타임 검사 — 문자열인가만.** 클래스 존재는 타입과 엔진(`Instance.new`)에 맡긴다. 사용자: *"사용 될 때 애초에 안 맞는 new 가 에러가 확실해서 그렇게 하는거 문제 없다고 보임."* `Modifier "Fraem"`처럼 엔진이 안 부르는 자리는 지금 `TypedFactory`처럼 조용히 통과한다.
- **[2026-10-20 닫힘] 릴리즈 시점 — 문서(단위 7)까지 끝낸 뒤 한 번에.** BREAKING이라 옮기는 법 없이 내지 않는다. 사용자: *"릴리즈 시점도 동의. 작업 진행 하면 될 것 같아."* bump·태그·게시 실행은 그때 다시 확인.
