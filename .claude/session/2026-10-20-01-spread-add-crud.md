# 2026-10-20-01 — Spread Add·CRUD 정의 (새 세션, 핸드오버 이어받음)

`session/2026-10-19-01-decl-3-4-decisions.md` §11 핸드오버를 이어받은 세션. 첫 일은 Spread 정의 확장 결정 재료.

## 1. 메인 재료 → 사용자 회신

메인 재료(채팅): `:Add`는 만드는 자리와 같은 테이블을 받고 반환 없음 / 생성자 안 겹침은 직접 쓴 키, `:Add`끼리는 뒤가 이김 / 잠금은 다른 Spread에 펴질 때도 / 읽기·지우기는 안 둠(늦게 넣어도 순수 추가 — `__index` 세터 없음) / 문자 키 함수 값은 Spread에서 거부하고 `OnEvent`로 안내(Modifier Quad0063과 같은 결) / 키트 안쪽 자리(`FieldModifier` 셋·`TrackModifier` 하나)는 Spread 하나로 바꾸고 루트 `Modifier`는 유지, 입력 마커 `SpreadInto<C>`.

사용자 회신(원문 요지는 `research/component-flatten-sugar-plan.md` 5절 끝 2026-10-20 문단): 반환 없음·직접 쓴 키 이김·펴질 때 잠금·읽기 지우기 없음 동의. 문자 키 거부는 기각 — *"진짜 bindable function 처럼 prop 이 함수인 경우가 없는게 아니고. 표현성을 저해"*, debug 경고로. `:Add` 인자는 props 테이블 대신 `s:Add(Spread "…" {…})` 대안 제시(Add에 큰 타입 함수 결과가 들어가는 건 어디에도 없던 일). 키트 자리는 동의하되 별도 필드(Modifier와 Spread 둘)가 낫지 않나, 타입 무게·넓은 사용자 쪽 길이·몇천 줄 파일 too complex·백엔드 무관 표면 부재를 우려. `SpreadInto` 동의, 검토는 해 본다.

## 2. 두 번째 재료 → 회신

메인: `:Add`는 Spread만(사용자 대안 채택, hover 근거), 그에 따라 "`:Add`는 배열부 끝에 Spread를 놓는 것"이 되어 생성자 직접 키가 이김; debug 경고는 함수가 다른 Spread에 밀려날 때만; 키트 안쪽은 앞 권고를 바꿔 필드를 따로(`FieldModifier` 유지 + `FieldSpread`) — 비용·타입 무게·커스텀 Modifier 경로 근거, 몇천 줄 섞인 파일은 미측정이라 실측 할 일로.

사용자: 셋 다 확인. 대신 깊이 1 유지(생성자·`:Add`가 만난 Spread를 그 자리에서 펴 항상 한 겹)와 "먼저 자리 잡은 것이 이긴다"를 제안 — 인라인 키는 맨 앞 Spread처럼, `Frame { s }`도 이미 있으면 안 넣는 같은 이치. 5절 (1)을 뒤집는 것이라 메인이 확인 중. 이름 검토 세 계열 착수(`audit/naming-spread-into-2026-10-20/prompt.md` — `SpreadInto<C>`·`FieldSpread`/`TrackSpread`·`:Add`의 읽힘).

사용자: "확인. 그렇게 확정." — 깊이 1·먼저가 이김 확정, 5절 (1)에 뒤집힘 배너.

## 3. 이름 확정

세 계열(`audit/naming-spread-into-2026-10-20/`): `SpreadInto` 셋 다 유지, `:Add`는 codex `Merge`·sonnet 유지(대안 `Append`)·Gemini `Append`, 키트 필드는 codex·Gemini 유지·sonnet `FieldExtras`. 메인 권고 `Append`·나머지 유지 → 사용자 확정. 사용자가 "먼저가 이김"의 근거를 보충(Luau 테이블은 인라인 키와 배열 값 사이 순서를 남기지 않음 — research 5절 끝).

## 4. 3.4.0 이름 정리 — 읽기 쪽 맵·탈출구

메인이 이름 전에 모양을 쟀다(REPORT 끝 절): 읽기는 클래스 타입 `index<>`로 충분(차이는 Q127뿐), 탈출구는 클래스 타입 직접(`ElemOf<<Part>>`)과 사용자 맵(`With<<{…}>>()`) 둘 다 큰 클래스에서 깨끗 — 사용자 맵은 이름 하나·오타 거름·모듈 경계 OK. 권고: 읽기 맵 비노출, 사용자 맵, 타입 없는 탈출구 없음. 사용자: 셋 다 동의. `With` 자리 이름은 세 계열 검토.

세 계열(`audit/naming-classmap-escape-2026-10-20/`): 셋 다 `With` 변경, 1순위 codex `For`·sonnet `Classes`·Gemini `ForClasses`. 메인 권고 `ForClasses`(한 번만 적는 드문 이름 — 원칙 1·2)와 문서 주의 셋(합쳐지지 않음·거짓 맵·130 한도) → 사용자 "확인. 전부 동의해".

## 5. round15 Q188·H-929 (3.4.0 코드 쓰기에 걸린 둘)

메인: Q188 (나) + "새 주석은 처음부터 번호만 남기지 않는다", H-929는 3.4.0에서 스텁 표를 만들어 새 최상위 일곱부터 넣기. 사용자: Q188 만질 때 확인 — 다만 안정 파일은 영영 안 잡히니 여유 날 때(주말 등) 말해 주겠다, 번호는 지우지 말고 `-- Ref: Hnnn Qnnn`처럼 남기자(정정 때 추적 불가는 파괴적). H-929 동의, 기존 op 이전은 미뤄도 됨. 반영: 원장 §4 Q188 닫힘·H-929 회신 문단, conventions 새 항목, question.md·todos.

## 6. 3.4.0 실행 계획

사용자 "계획 잡기부터 천천히". sonnet 인벤토리(바뀌는 자리 전수 — 코드·스펙·문서·스크립트·게이트·킷) 뒤 `research/release-3.4.0-plan.md` 작성: 공존 후 제거, 타입 함수 본체는 quad-roblox, 단위 0(섞인 대형 파일 실측)~8, 남은 결정 둘(커리 첫 인자 런타임 검사·릴리즈 시점).
사용자: 커리 첫 인자 런타임 검사는 문자열만 — 동의(안 맞는 new가 확실히 에러). 단위 0 착수.
사용자: 릴리즈 시점(문서까지 끝낸 뒤 한 번에) 동의, 작업 진행.

## 7. 단위 0 실측

섞인 대형 파일: 지금 꼴은 약 2300줄(호출 약 1500)에서 too complex — 원인 `LuauSolverConstraintLimit=1500`(Studio 동기화 값), 호출마다 줄지 않은 타입 함수 제약. 처방: 생성자·Spread·Modifier 팩토리 함수 타입을 통째 타입 함수로(`ctor` 모드) — 5730줄 깨끗, 자동완성·hover 같음 → 단위 2 구현 꼴로. 이벤트 디스크립터는 모듈당 약 1200 문턱. pin 1.69.0만 테이블 안 OnEvent 콜백 문맥 타입 없음 → 핀 올리기 사용자 문항.

## 8. 단위 1 완료(정책 데이터와 생성기)

gen-d.py: LEGACY_KEEP(정의 클래스 기준, 태그 무관 — Transparency 드리프트 해소), HIDDEN_CORE_KEEP(비GUI), normalize `policy`(만들 수 있는 클래스 사슬), emit → `quad-roblox/src/Surface/Data.luau`(데이터만), check 게이트 포함. 지금 덤프에서 옛 D·api-surface 클래스 부분 변화 0. 체커 차이 관측: 확장 defs는 `GuiObject.Transparency`가 없고 핀 defs는 있음 → Inject는 되살린 멤버 전부를 넣고 타입 함수가 덮어쓴다(단위 2).

## 9. 단위 2 완료(타입 함수 본체)

`quad-roblox/src/Surface/init.luau` + 게이트 `scripts/surface-gate.py`(NEG 23/23, 클래스 47개). 프로브와 다른 점: 전역 이름 Deny 없음, 입력 마커는 조상 사슬 전체(ForClasses 때문 — GUI 맵으로 거르면 `W.Modifier "BasePart"`가 `Part`에서 거부), 팩토리 함수 타입 통째. 공개 별칭은 루트 미노출(단위 6).

## 10. 단위 3 완료(base 런타임)

`Dispatch/Spread.luau`(깊이 1·먼저가 이김·`:Append`·잠금·debug 경고), drive 선처리 `expand`(flatten 앞), 에러 Quad0273~0277, `BackendStubs.luau`(H-929 스텁 표 — 일곱 중 Modifier는 단위 6), `q.NewModule`·`q.Raw`(+ 01-quad-module 헤딩, CHANGELOG Added), `ModifierField`/`ModifierFieldOut` 옆 이름. 남은 것: Surface 변환 함수 `old` 타입(단위 6). test.sh·devui·material exit 0.

## 11. 단위 4 완료(quad-roblox 런타임)

`Surface/Runtime.luau`·`Handlers/OnEvent.luau`, Quad0278~0280, gen-d `Superclass` 런타임 표. 공존: OnChange·Out은 인자 개수로, Modifier는 base `__call`의 임시 한 문자열 갈래(래퍼는 옛 꼴 에러 blame을 깨서 버림 — spec.claim). 태그된 함수끼리 부르면 blame이 quad 줄로 간다는 것을 다시 밟아 공개 단계 → 태그 없는 본체 구조로. test.sh·킷 둘 exit 0.

## 12. 단위 5 완료(변환 스크립트)

`scripts/migrate-3.4.py`. 레포 사본 적용: 킷 Lune 스펙 원본과 동일 통과(184·507), 못 정함 1·캐스트 D 1(시제품과 같은 자리). 스펙 쪽 손 몫과 `InstanceShorthand`의 `Declaration.New` 내부 의존은 단위 6.

## 13. 단위 6 완료(갈아타기 — BREAKING)

옛 표면(생성 `Declaration`·`q.New`·base `q.Modifier`·`newMapperClass`·3.3 OnChange/Out 꼴·클래스별 타입 이름) 제거, 루트가 일반 이름과 `RobloxExtension`(표면 일곱 + ForClasses)을 내보냄. 스크립트를 레포 스펙·킷에 실제로 적용, 손 몫은 스펙 열둘 남짓과 킷 셋(Sheet hostHook·Elevation `ShowBehindParent` 체커 차이·textfield). devui `FieldSpread`/`TrackSpread`.

계획에서 벗어난 것 둘 — 사용자에게 보고: 변환 함수 `old`·`Peek`의 State·Tween 팔이 읽기 뷰(`StateView`·`TweenView`)다. 타입 함수 안에 전체 `QuadTypes.State<T>`를 넣으면 "*error-type*"으로 깨져서다(실측). round3 Q23 (a)는 전체형이었다. 둘째, 커스텀 클래스 Modifier가 `ModifierInto<C>` 마커에 바로 들어가지 않는다(3.3 `Into<Class>`는 메소드 인터페이스였다). 새 에러 `Quad0281`(클래스 단계에 인자 둘 이상 — 3.3 `q.OnChange("Text", fn)`이 조용히 단계 함수가 되어 요소에 놓이던 것).

doc-coverage가 새 표면 헤딩을 요구해 단위 7 일부를 당겼다: reference/roblox 01~05 다시 씀(파일 이름 `02-elem.md`·`03-modifier-spread.md`), core/01·core/10·errors·00-index·CHANGELOG BREAKING. 문서 쓰며 확인한 것(신 솔버·한도 플래그 셋): `q.Out "UIStroke" "Color"`가 올바른 `Source<Color3>`를 받는다(3.3의 충돌 이름 거짓 양성 해소), `q.Out "BillboardGui" "Adornee"`가 `Source<Instance?>`를 받는다, `q.OnChange "UIStroke" "Color" (function(v: number))`·`"Parent"` 콜백에 `Instance` 주석·`Source(5)`를 `Size`에 — 전부 거부.

## 14. 단위 7 완료(사용자 문서)

코드 블록은 일회용 변환 스크립트로, 산문은 손으로. how-to 01에 Spread 절(우선순위 표, JS 펼치기와 반대인 이유)과 Store·Context·Modifier·Spread·토큰 다섯 비교(사용자 2026-10-20 요청 — `research/design-token-plan.md` 3절의 사용자 정리를 문서로). 입력 자리 예제는 `ModifierInto<C>`로(3.3 `Into<Class>` + `:AsTextButton()` 관용구는 필요 없어짐 — 마커가 조상 클래스를 받는다). 킷 소스 주석·README도 같이.

실측: 한도 플래그 없이 킷 둘은 깨끗, quad-roblox 스펙 두 자리만 too complex — 조상 클래스 Modifier 타입을 주석으로 비교하는 자리(`Modifier<GuiObject>`·`Modifier<GuiButton>` 주석). 구체 클래스·마커·무주석은 깨끗. 설치 문서를 "새 솔버 필수, 한도 셋 권장"으로. 사용자 보고 항목: Studio에서는 플래그를 못 바꾸므로 그 한 자리는 피하라고 문서에 적었다 — 처방(예: 조상 클래스 `Modifier<C>`의 As 트리를 줄이는 것)은 새 메커니즘이라 사용자 몫.

`Quad0224` 메시지 "second argument" → `"{name}" needs a Source to write back into`(커리 꼴에서 둘째 인자가 아님).

## 15. 3.4.0 단위 8 — base 승격·Studio 확인

**승격.** 새 `base/surface-plan.md`(지금 유효한 결정과 이유 한 줄 — 모양, 타입 원천·공개 이름·비노출, Spread, 런타임 배치). `typing-limits.md`에 8.39(타입 함수 안의 전체 `State<T>` → 읽기 뷰)·8.40(3.4.0은 한도 플래그 없이 검사됨, 조상 클래스 `Modifier<C>` 주석 비교만 예외), 8.22·8.28에 뒤집힘 배너. `architecture.md` 소스 트리(Surface/·BackendStubs·Dispatch/Spread·Handlers/OnEvent, Declaration/ 제거)와 대문자 규칙 4번. claim·modifier·onchange·event·bind-system·dispatch-core 머리에 3.4.0 배너, `docs-handover-registry.md` §4 표기. research 세 문서·README 행에 "구현됨 — 정본 base" 표시. todos·ROADMAP·session-summary.

**한도 플래그 재기.** 단위 7 실측 그대로 — 킷은 플래그 없이 깨끗, quad-roblox 스펙 두 자리가 의도적으로 조상 클래스 Modifier 주석을 써서 test.sh·킷 run.sh의 셋은 유지(8.40).

**Studio(quad-test, HEAD `ae26f291` + 문서 변경 싱크).** Script Analysis 처음 읽기는 경고 992건이었는데 거의 전부 ServerScriptService의 옛 `declprobe`(2026-10-16 프로브 사본 — 생성 D 시절) 잔재였다. 그것과 패키지 사본의 `test/`를 Studio에서 지우고 다시 읽으니 8건 — 전부 material `gallery/Buttons`의 `table.insert(list, Material.Button(...))`에서 "`*error-type*` is ambiguous". 프로브로 좁혀 보니 같은 호출이 다른 스크립트·같은 폴더 모듈·Buttons 안에 줄을 더한 사본에서 모두 `TextButton`으로 추론되었고, 다시 싱크해 원본으로 되돌리자 Buttons도 0건 — 싱크 직후 분석 상태의 일시적 잔상으로 판단(재현 안 됨). 최종: 킷 둘(src·gallery·stories)·quad-base·quad-roblox src 진단 0, 남은 8건은 패키지 사본 `quad_base/test/spec.versioncheck`의 require 경로(3.4.0 전부터, 무관). Play: 두 갤러리 마운트, material 탭 아홉 순회, 출력에 quad 에러·경고 0(로블록스 코어 UIBlox 경고만), 화면 정상.

**감사 1라운드(`base/` 정합성) 반영.** 에러 번호·클래스 맵 개수·우선순위·스텁 여덟은 코드와 일치. 고친 것: `NewChild`가 결정(2026-10-16 "내보내지 않는다")과 달리 루트에서 재수출되고 있어 지웠다(3.3 공개였으므로 CHANGELOG BREAKING 줄에 합류, reference 00-index·roblox/01-install 목록에서 뺌, `types.luau` 머리 주석에 내부라고 명시). base 문서 배너 여덟(ui-shorthand·module-lifecycle·slot·tween·ref·attribute·lifecycle-pattern·source-state, typing-limits 8.5), slot-plan의 Quad0241 인용 문구를 코드대로, ui-shorthand의 `quad.Declaration.New` → `quad.Elem`, architecture 대문자 규칙 4번에 "지금은 유효하지 않다", base/README에 3.4.0 읽기 안내(옛 이름 → 새 이름 대응), release 계획 4절 luau-lsp 핀 닫힘, research/README 두 행, todos 낡은 "M1~M4 진행 중". 게이트: test.sh·devui·material exit 0, doc-check ERROR 0.
