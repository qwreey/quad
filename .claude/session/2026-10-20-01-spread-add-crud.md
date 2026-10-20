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
