# sonnet 답 (대화에서 받은 최종 보고, 원문 그대로 옮김 — 목록 서식만 정리)

## 1. 결과 캐시 메서드 (`q:X(key, build)`)

**1순위: `q:Memo(key, build)`** — 2순위 `GetOrCreate`, 3순위 `Shared`, 4순위 `Once`.

- Memo는 "같은 입력이면 같은 결과를 돌려준다"는 뜻이어서 이 동작과 맞고, 사용자도 이미 아는 용어다.
- 단점: Fusion/Vide 같은 반응형 라이브러리에서 Memo가 "의존성이 바뀌면 다시 계산하는 파생 값"을 가리킨다. 여기서는 다시 계산하지 않으므로 오해 여지가 있다. 그 오해가 걱정되면 `GetOrCreate`가 안전하다(의미가 가장 정확하지만 길다).
- `Once`는 오해를 부른다 — RunInit과 같은 "한 번만 실행하고 값은 없다"로 읽힌다. `Cached`는 형용사라 메서드 이름으로 어색, `Singleton`은 무겁다, `Lazy`는 키의 의미가 빠진다, `Shared`는 동작(실행 후 저장)을 드러내지 않는다.

**인자 모양은 항상 `q:Memo(key, build)`로 고정.** 키 생략을 허용하면 오버로드가 생겨 읽는 사람이 문자열 키와 함수 키를 구별해야 한다. `q:Memo(build, build)`는 장황하지만 킷 모듈마다 한 줄이고 의도가 명시적이라 감수할 만하다. `(build, key)`면 build가 길 때 key가 뒤로 밀려 가려진다.

## 2. 백엔드 설치 단언 (`q:Y(name, versionPattern)`)

**1순위: `AssertProvider`** — 2순위 `AssertBackend`, 3순위 `AssertProviderVersion`.

- `UseProvider`와 짝이 되어 에러 메시지("UseProvider를 먼저 호출하라")와 낱말이 일치한다.
- `AssertBackend`는 용어 이중화 — 공개 API가 `UseProvider`인데 backend라고 부르면 두 말을 외워야 한다(설명 문장에서만 backend).
- `AssertProviderVersion`은 길고 이름 검사가 빠진 것처럼 읽힌다. `AssertProvided`·`AssertUsing`은 무엇을 단언하는지 불분명.
- 반환은 q보다 아무것도 반환하지 않는 쪽 — Assert류는 보통 체이닝하지 않는다.
- Context.Provider와 겹치지만 UseProvider가 이미 이 뜻으로 확립돼 있어 위험은 작다 — 문서에 한 줄 주의.

## 3. provider의 이름·버전 선언

**1순위: `Provider = { Name = "quad-roblox", Version = "3.4.0" }`** — 2순위 `ProviderName`/`ProviderVersion`, 3순위 최상위 `Name`/`Version`.

- 최상위 `Version`은 쓰면 안 된다 — 확장 표가 q에 병합되므로 `q.Version`을 덮거나 충돌한다. `Name`도 일반 낱말이라 병합 때 부딪힐 수 있다.
- 한 항목으로 묶으면 q에 필드 하나만 늘어 충돌 면적이 가장 작고, `q.Provider.Name`으로 자연스럽다.
- 버전 형식은 `q.Version`과 같은 "3.4.0" 문자열로 — 패턴 `"3.4^"` 비교가 쉽다.
