### 1. q별 결과 캐시

**추천: `GetOrCreate`**  
순위: `GetOrCreate` > `Memo` > `Cached`

`GetOrCreate`는 없으면 만들고 있으면 가져온다는 동작을 잘 설명합니다. `Memo`는 익숙하지만, 문자열 키로 여러 키트를 공유하는 용도까지는 이름만으로 드러나지 않습니다.

**인자 형태:** `q:GetOrCreate(key, build)`처럼 키를 항상 별도 첫 인자로 받는 편을 추천합니다. `q:GetOrCreate(build)`도 허용하면 함수 키와 명시적 키의 규칙을 함께 기억해야 합니다.

`Once`는 캐시된 결과를 돌려준다는 점을 놓치게 하고, `Singleton`은 키마다 하나라는 동작과 어긋날 수 있습니다.

### 2. 백엔드 설치 확인

**추천: `AssertBackend`**  
순위: `AssertBackend` > `AssertProvider` > `AssertProviderVersion`

`AssertBackend`는 게임 사용자가 설치해야 하는 Roblox 표면을 확인한다는 뜻이 비교적 분명합니다. `AssertProvider`는 `Context.Provider`의 값 제공자와 혼동될 여지가 있습니다. `AssertProviderVersion`은 이름과 버전 확인 중 버전만 강조합니다.

### 3. provider가 선언할 메타데이터

**추천: `Provider = { Name, Version }`**  
순위: `Provider = { Name, Version }` > `ProviderName` / `ProviderVersion` > `Name` / `Version`

중첩된 `Provider` 항목은 이 메타데이터가 provider 자체를 가리킨다는 점을 분명히 합니다. `q.Version`과도 충돌하지 않습니다. `Name`과 `Version`을 확장 테이블 최상위에 두면 의미가 모호해지고, 특히 `Version`은 라이브러리 버전으로 오해할 수 있습니다.