# 이름표 검토 2026-10-16 — `research/declaration-naming-table.md` 초안의 체계 검토와 값 쪽 `Elem` 토론

Gemini(`gemini.md`, 과제 `prompt.md` — 표 전체 체계·Elem 판정·빠진 축)와 sonnet 둘의 토론(찬성·반대, 표 파일 하나만 읽음 — 아래 요약). 결정이 아니라 재료다.

**토론 — 찬성(sonnet)**: 가장 강한 주장은 "Elem은 최선이 아니라 가장 덜 나쁜 이름" — 원칙 4(값·타입 같은 이름)와 Modifier·Spread·Mapper와 같은 커리 꼴, `Class`·`New` 기각.
스스로 인정한 재반박 불가 지점: `Elem<Frame>`이 인스턴스가 아니라 생성자 함수 타입을 가리키는 비대칭(사용자가 4절 '차이'에 적은 것), "요소"와 "요소 생성자"가 같은 이름이 되는 의미 중복.
보조 장치: 별칭 주석·표 비고 한 줄, 프로브 이름 `Ctor`는 내부로만.

**토론 — 반대(sonnet)**: "Elem은 틀렸다"까지는 안 밀고 "필연이 아니다"로 — `Elem` 어간이 코퍼스에서 이미 "배열 자리 원소"(옛 `<C>Elem`, `SlotElement`)를 뜻하고, 4절 '차이'가 구조 불일치를
이미 인정, 꺼내기는 드물어 짧을 이유가 없음. 대안 `Template`(드문 이름은 길어도 정확)·`Maker`(`Marker`와 한 글자 차)·`Builder`(`Build`와 접두 충돌 — 비추천).
인정한 지점: 타입 쪽 `Elem<C>`은 가끔 쓰여 길면 부담, 새 낱말은 평행 구조의 학습 공짜를 깸. 결론: 토론은 "값 이름과 타입 이름을 갈라도 되는가"로 좁혀진다.

**Gemini**: Elem은 바꾸는 쪽 — `Modifier "Frame"`은 팩토리를 돌려주고 그 산물이 `Modifier<Frame>`, `Elem "Frame"`은 생성자를 돌려주고 그 산물은 `Frame`이지 `Elem`이 아님(원칙 4를 엄밀히 대면 깸).
대안 `Ctor "Frame": Ctor<Frame>`(프로브 `Lib.luau`의 `Ctor<C>`), 또는 값 `Elem` 유지 + 타입 `ElemCtor<C>`. 표 행: `Into<C>` → `ModifierInto<C>`(무엇으로 into인지 + 부모 접두),
`SpreadMarker<C>` → `Spread<C>`(`:Add`가 붙은 값에 `Marker`는 quad 마커 정의와 어긋남 — 마커는 입력 자리 전용·메소드 없음, `quad-types/src/init.luau` 42행대 주석),
`Field<T>` → `ModifierField<T>` 지지, `PropTypes`/`PropTypesRead` → `PropertyMap`(`EventMap`과 짝), `PropsArrayItem<C>`는 고차 팩토리 작성자 때문에 내보내기 유지 권고. 빠진 축: Field 변형 열(`FieldP`·`FieldN`·`FieldPN`·
`FieldV`…), 공용 모듈 레코드 타입(`Declaration`·`DeclarationMapper`·`DeclarationModifier`), `OnChangeFn`·`OutFn`(·`OnEventFn`), 동적 탈출구 `D.New(name)`(프로브 `NewLoose`), `MapperRoot` 타입.

**메인 검증**: Field 변형 열·`Declaration`/`DeclarationMapper`/`DeclarationModifier`(생성 D 4841·4875·4924행)·마커 정의 주석은 사실. **Gemini 오류 하나**: "OnEvent가 커리 꼴로 확정"이라 썼으나
OnEvent 모양(커리 여부)은 미정(`research/declaration-naming-table.md` 3.1). Roblox 충돌 실측(`Content` 7845·19014행 충돌, `Spread`는 UIShadow·SunRaysEffect 프로퍼티일 뿐 전역 타입 아님)은 메인 grep과 일치.
