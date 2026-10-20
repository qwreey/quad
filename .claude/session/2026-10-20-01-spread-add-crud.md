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
