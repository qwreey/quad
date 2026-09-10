# Changelog

이 파일은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 형식을 따르고, 버전은 [SemVer](https://semver.org/lang/ko/)입니다.
소비자가 겪는 변화만 적습니다 — 항목은 **Added / Changed / Deprecated / Removed / Fixed** 다섯으로 나누고, 호환이 깨지는 항목은 앞에 **BREAKING**을 붙이고 옮기는 법을 한 줄로 답니다. 내부 원장 번호는 쓰지 않습니다.
공개 표면이나 동작을 바꾸는 변경은 그 커밋에서 `[Unreleased]`에 한 줄을 넣고, 릴리즈 때 `scripts/check-version.py bump <version>`이 그 절을 버전 헤딩으로 자릅니다.

## [Unreleased]

### Changed

- `slot:Single`의 타입이 `:List`와 같은 `<Item, UD>`가 됐습니다 — 구동 `state`가 데이터(`Item`)라 원소 타입에 묶이지 않습니다. `Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 코드가 이제 strict를 통과합니다(런타임 변화 없음).
- **BREAKING — `q.Operator.Index`가 `q.Operator.Indexed`로 이름이 바뀌었습니다.** 동작·시그니처는 그대로(`state:Apply(q.Operator.Indexed<<V>>("Key"))`, `V`는 인덱스된 값의 타입) — 호출부의 이름만 바꾸면 됩니다. 픽 함수를 직접 받는 일반형(`Indexer`)은 타입 추론이 가능해지면 따로 추가할 예정이라 이름을 미리 갈라 두었습니다.

### Fixed

- `type_version_check`의 `CheckVersion` type function에서 `pcall`을 없앴습니다. luau-lsp(신 솔버)가 `Unknown global 'pcall'` 진단을 내던 것이 사라집니다. 값 여부는 `tag == "singleton"`으로 봅니다(판정 규칙은 그대로).

## [3.0.0] - 2026-09-10

### Changed

- **BREAKING — 처음부터 다시 쓴 별개 라이브러리입니다.** 3.x는 quad v1(2.x)과 API 호환이 없고 패키지 이름도 다릅니다(`qwreey/quad_base` + `qwreey/quad_roblox`, pesde). 무엇이 왜 없어졌고 어떤 틀로 옮기는지는 [quad v1에서 오는 분께](./docs/overview/02-from-v1.md), 절차는 [quad v1에서 v2로 옮기기](./docs/how-to/08-migrating-from-v1.md). v1은 `master` 브랜치와 GitHub 릴리즈(rbxmx)에 그대로 남습니다.

---

## 2.x (quad v1) — 원문 보존

아래는 v1 저장소(`master` 브랜치 `md/kr/changelogs.md`)의 변경 이력을 **한 글자도 고치지 않고** 옮긴 것입니다. 세 가지만 덧붙입니다.

1. **이 목록에 없는 번호(2.10, 2.16)는 배포 뒤 결함이 발견되어 회수한 릴리즈입니다.** 사용을 막기 위해 번호째 지웠습니다.
2. **2.25는 배포되지 않았습니다.** 소스의 버전 문자열이 테스트 표시(`2.25B`)로 남아 있고, 마지막 릴리즈는 2.24입니다.
3. **날짜는 복원하지 않았습니다.** 태그는 `2.24` 하나뿐이고, 소스의 버전 상수는 2.18(2023-02-18)에 처음 생겨 2.24(2023-02-21)까지 이어집니다. 그 앞 번호의 시점은 기록이 없습니다.

### 2.25
실험적 API 로써 GetChildren() 과 ChildAdded::Bindable 이 추가되었습니다.

### 2.24
모든 문서가 정리되었습니다.

### 2.23
객체 생성시 일어나는 오류를 해결했습니다.  
이제 Extend 객체 내부 자식이 Unmount 되는 경우 __child 에서 제거됩니다.  
types 의 오타를 고쳤습니다.  

### 2.22
더이상 Event.Prop 가 처음 생성시 실행되는 일이 일어나지 않습니다.

### 2.21
Linker 가 이제 클래스 안 클래스에서 사용될 수 있도록 변경되었습니다.

### 2.20
Docments 가 업데이트되었습니다. 많은양의 새로운 튜토리얼이 제공됩니다.  
Mkdocs 테마와 여러가지 설정이 변경되었습니다.  
이제 Makefile 을 통해서 rojo build 와 mkdocs build 를 사용할 수 있습니다.  

### 2.19
Linker 객체가 추가되었습니다. 이제 GetPropertyChangedSignal 와, self 에 특정 오브젝트 혹은 이벤트를 연결할 수 있습니다

### 2.18
이제 더이상 GC 에 의해 Store 의 Instance 값이 손실되지 않습니다

### 2.17
Tween 의 CallBack 등록 시 주언지는 파라메터가 변경되었습니다.  
이제 더이상 ~ 문이 사용되지 않습니다.  

### 2.15 BREAKING CHANGES
이제 Lang 에서 CurrentLocale, FailedMessage 을 변경하면 자동으로 변경사항이 업데이트됩니다. 또한 일부 필드의 네이밍이 변경되었습니다

### 2.14
Lang 모듈이 추가되었습니다. register 를 사용해 사용자 지정 다중언어 지원을 추가할 수 있습니다

### 2.13
Signal 모듈이 추가되었습니다. 이제 Class.Extend 에서 GetPropertyChangedSignal 과 EmitPropertyChangedSignal 를 사용할 수 있습니다

### 2.12
Mount 반환 객체에 Add 를 사용할 수 있도록 Mount 객체가 변경되었습니다

### 2.11
Store.GetObjects 에 이제 & 문법을 사용할 수 있습니다.

### 2.9
PreloadAsync 를 통해 이제 round.lua 에서 라운드 이미지를 미리 로드합니다.

### 2.8
반환 관련 코드가 exports 로 이주되었으며. init.lua 에서는 자동적으로 types 를 반환합니다.

### 2.7
이제 types 를 완전히 지원합니다. 직접 불러와 사용할 수 있습니다

### 2.1~2.6 BREAKING CHANGES
모든 모듈의 필드의 이름이 변경되었으며, 모든 클래스들이 기본적으로 대문자 시작 네이밍을 사용하도록 명명규칙을 변경했습니다.

### 2.0
버전 판올림, BREAKING CHANGES 를 위해 버전을 판올림 하였습니다.
