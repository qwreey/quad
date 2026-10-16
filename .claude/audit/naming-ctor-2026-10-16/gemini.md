# quad 이름 탐색 보고서: 요소 생성자 꺼내기 함수(X), 모듈 인스턴스 생성(q.New), 네임스페이스 구조

> **안내 및 전제**: 본 보고서의 모든 내용은 라이브러리 저자(사용자)의 최종 결정을 돕기 위한 **"제안"**과 **"분석 재료"**이며, 어떠한 항목도 단정적인 결정이 아닙니다. 직접 실행하여 확인한 사실은 **[실측]**, 코드를 읽고 논리적으로 도출한 내용은 **[추정]**으로 명시합니다.

---

## 1. 실측 및 배경 데이터 분석

### 1.1 현재 모듈 및 생성 구조 [실측]
- **`q.New()`의 현재 위치 및 성격**:
  - 파일: `quad-base/src/init.luau:8-9, 63`
  - 내용: `require(quad-base)`는 이미 인스턴스화된 모듈 자체를 반환하며, `New()`는 격리된 새 `Quad` 인스턴스를 만드는 용도입니다.
  - 문서: `docs/site/src/content/docs/reference/core/01-quad-module.md:5` — *"여러 개의 독립 인스턴스가 필요한 드문 경우에만 `q.New()`를 씁니다."*
  - 실제 호출 빈도: 전체 코드베이스에서 `Quad.New()`는 테스트 스펙(`quad-roblox/test/spec.d.luau:13`, `spec.robloxfactory.luau`) 등 극소수에서만 호출됩니다.
- **기존 `Declaration` 내부의 `New`**:
  - 파일: `quad-roblox/src/Declaration/init.luau:4965, 4983`
  - 내용: `local function New<T>(className: string): (props: any) -> T`가 이미 존재하며, `D.New("Frame")` 꼴로 일반 생성자 접근이 노출되어 있었습니다(`quad-roblox/test/spec.d.luau:19, 85`).
- **형제 API의 명명 규칙**:
  - 파스칼 케이스, 단일 명사/동사/수식어: `q.Source`, `q.Store`, `q.Slot`, `q.Modifier`, `q.Spread`, `q.Claim`, `q.Tween`, `q.Ref`, `q.Context`, `q.Effect`, `q.Out`.
  - 커링(Currying) 꼴:
    - `q.Spread "GuiObject" { ... }` (`.claude/audit/decl-typefn-probe-2026-10-16/REPORT.md:50-52` [실측] — 두 인자 꼴은 가짜 에러, 커리 꼴만 정상 동작)
    - `q.Modifier "Frame"`

### 1.2 Roblox 전체 클래스 및 타입과의 충돌 전수 조사 [실측]
- **실행 명령**:
  `scripts/roblox-defs/globalTypes.d.luau`(19,111행) 및 메타데이터를 파이썬 스크립트로 전수 조사.
  - 생성 가능 인스턴스(`CREATABLE_INSTANCES`): 356개
  - 서비스(`SERVICES`): 324개
  - 전체 선언된 Luau 타입: 2,236개
- **충돌 조사 결과 [실측]**:
  - 현재 quad의 공개 심볼(`New`, `Version`, `Source`, `Store`, `Observer`, `Effect`, `Modifier`, `Spread`, `Claim`, `Slot`, `Tween`, `OnChange`, `Out`, `Animate`, `Tag`, `Attr`, `Context` 등) 중 Roblox 클래스/타입과 이름이 겹치는 것은 오직 **`Tween`** 하나뿐입니다.
  - `quad-roblox/src/init.luau:217`에서 `q.Tween`은 `Types.TweenConstructor`로 주입되며, Roblox의 `Tween` 클래스(`TweenService:Create`의 반환 타입)와 완벽히 동음이의어입니다.

### 1.3 타입 함수 기반 표면의 성능 및 사용 패턴 [실측]
- **출처**: `.claude/audit/decl-typefn-probe-2026-10-16/REPORT.md:53-56`
- **측정 결과**:
  - 인라인으로 매번 호출(`X "Frame" { ... }`)할 경우: 약 300 호출 부근에서 Luau 타입 체커가 `too complex to typecheck 1 + 가짜 에러 402`로 무너집니다.
  - 파일 상단에 한 번 꺼내둘 경우(`local Frame = X "Frame"` 후 `Frame { ... }`): 50~600 호출 구간에서 0.52~0.62 s, 92~113 MiB로 완벽하게 평평하게 유지됩니다.
- **귀결 [추정]**:
  - quad v2에서 요소 생성자는 **"파일 상단 또는 공용 모듈에서 미리 꺼내두고 쓰는 스타일"**이 표준 권장 패턴으로 정립되어야 합니다.
  - 따라서 X의 이름은 인라인 즉시 생성뿐만 아니라, **"변수에 생성자 함수를 바인딩하는 줄(`local Frame = X "Frame"`)"**에서 얼마나 의미론적으로 자연스러운지가 핵심 평가 기준이 됩니다.

---

## 2. 과제 1: X 이름 후보 (5개) 심층 분석

X는 `<K>(name: K) -> (props: Props<K>) -> K` 시그니처를 갖는 고차 함수(생성자를 돌려주는 팩토리)입니다.

### 후보 1: `New` (`q.New`)

- **장점**:
  1. **압도적인 생태계 친숙도**: Roblox 기본 빌트인 `Instance.new("Frame")` 및 Fusion의 `New "Frame"`과 직결되어 Luau UI 개발자에게 설명이 필요 없을 정도로 직관적입니다.
  2. **간결성과 파스칼 케이스 일관성**: 3글자의 대문자 단어로 `q.Source`, `q.Spread`, `q.Modifier` 등 기존 quad 핵심 API와 완벽한 조화를 이룹니다.
  3. **인라인 사용 시의 자연스러움**: 드물게 1회성 인라인으로 쓸 때 `New "Frame" { ... }`는 가장 읽기 편한 형태입니다.
- **약점 (오독·충돌·의미 차이)**:
  1. **"생성자 반환" vs "인스턴스 생성" 오독 위험**: `local Frame = New "Frame"`을 처음 보면 "새 Frame 인스턴스를 하나 만들어 변수에 넣었나?"라고 오독할 소지가 있습니다. (`Instance.new`가 인스턴스를 즉시 반환하기 때문).
  2. **Fusion과의 멘탈 모델 차이**: Fusion에서 `New "Frame" { ... }`는 인라인 인스턴스 생성이 주된 사용법인 반면, quad는 타입 예산 문제로 인해 "상단에 꺼내두는 생성자 바인딩"을 권장하므로 "New가 인스턴스가 아니라 생성자를 만든다"는 개념을 문서로 인지시켜야 합니다.
  3. **기존 `q.New()`와의 충돌**: 기존 quad에서 `q.New()`는 독립 모듈 인스턴스를 만드는 함수였습니다 (과제 2에서 `NewModule`로 변경한다는 전제가 필요).
- **코드 상에서의 가독성**:
  - *파일 상단*: `local Frame = q.New "Frame"`
    - 읽히는 느낌: "Frame 클래스의 New 함수를 로컬 변수 `Frame`에 바인딩한다." (익숙해지면 매우 자연스러움)
  - *공용 모듈*:
    ```luau
    q.UI = {
        Frame = q.New "Frame",
        TextLabel = q.New "TextLabel",
    }
    ```
    - 읽히는 느낌: "UI 테이블에 각 클래스의 New 생성자를 채운다." 간결하고 직관적입니다.

---

### 후보 2: `Elem` (또는 `Element`) (`q.Elem`)

- **장점**:
  1. **내부 코드베이스와의 놀라운 용어 일치 [실측]**: `quad-roblox/src/init.luau:145-175`를 보면 이미 `FrameElem`, `TextLabelElem`, `BillboardGuiElem` 등 31개 클래스의 요소 타입이 `*Elem`으로 정의되어 있습니다. 내부 개념(`Elem`)이 공개 함수 이름으로 자연스럽게 연결됩니다.
  2. **선언형(Declarative) UI 철학 부합**: "명령형으로 새 인스턴스를 찍어낸다(New/Create)"가 아니라 "이것은 Frame 요소를 선언하는 명세다"라는 선언형 UI의 본질을 전달합니다.
  3. **오독 방지**: `local Frame = Elem "Frame"`은 인스턴스 그 자체가 아니라 "Frame Element 정의/생성기"를 가져온다는 뉘앙스를 주어 오독 위험이 낮습니다.
  4. **형제 API와의 대칭성**:
     - `q.Spread "GuiObject" { ... }` (스프레드 마커)
     - `q.Modifier "Frame"` (모디파이어)
     - `q.Elem "Frame"` (엘리먼트 생성자)
- **약점 (오독·충돌·의미 차이)**:
  1. **React 사용자의 미묘한 개념 차이**: React에서 `Element`는 컴포넌트를 호출한 결과 객체(VNode)를 의미하지만, 여기서는 "생성자 함수"를 의미합니다.
  2. **축약어 호불호**: `Elem`은 4글자로 짧고 관례적이지만 축약어이고, 풀네임 `Element`는 7글자로 다소 깁니다.
- **코드 상에서의 가독성**:
  - *파일 상단*: `local Frame = q.Elem "Frame"`
    - 읽히는 느낌: "Frame Element 생성기를 꺼내둔다."
  - *공용 모듈*:
    ```luau
    q.UI = {
        Frame = q.Elem "Frame",
        TextLabel = q.Elem "TextLabel",
    }
    ```
    - 읽히는 느낌: "Frame Element 생성자를 등록한다." 매우 체계적인 빌더 느낌을 줍니다.

---

### 후보 3: `Ctor` (또는 `Constructor`) (`q.Ctor`)

- **장점**:
  1. **100% 정직한 기술적 정확성**: 함수의 실제 역할이 "해당 클래스의 생성자(Constructor) 함수를 반환하는 것"이므로 기능과 이름 사이에 어떠한 은유나 왜곡도 없습니다.
  2. **오독 가능성 완전 배제**: `local Frame = Ctor "Frame"`은 "Frame의 생성자를 꺼낸다"는 뜻이 너무나 명확하여 인스턴스가 생성되었다고 착각할 여지가 전혀 없습니다.
- **약점 (오독·충돌·의미 차이)**:
  1. **지나치게 기술적이고 건조한 어조**: `Ctor`는 C++, C# 등 컴파일러/메타프로그래밍 계열에서 자주 쓰이는 축약어로, 일반적인 Roblox 스크립터나 프론트엔드 UI 개발자에게는 다소 딱딱하고 낯선 느낌을 줍니다.
  2. **인라인 가독성 저하**: 인라인으로 `Ctor "Frame" { ... }`를 쓰면 "생성자 Frame에게 속성 테이블을 준다"처럼 읽혀 UI 계층 구조를 시각화하기에 부자연스럽습니다.
  3. `Constructor`는 11글자로 너무 깁니다.
- **코드 상에서의 가독성**:
  - *파일 상단*: `local Frame = q.Ctor "Frame"`
    - 읽히는 느낌: "Frame 클래스의 생성자 함수를 가져온다." (기계적으로 완벽함)
  - *공용 모듈*:
    ```luau
    q.UI = {
        Frame = q.Ctor "Frame",
        TextLabel = q.Ctor "TextLabel",
    }
    ```
    - 읽히는 느낌: 클래스 생성자 맵을 구축하는 정석적인 패턴.

---

### 후보 4: `Create` (`q.Create`)

- **장점**:
  1. Vide의 `create "Frame" { ... }` 및 Roblox의 `TweenService:Create`와 동일한 친숙한 단어입니다.
  2. 인라인 호출 시 `Create "Frame" { ... }`는 영어 문장처럼 읽힙니다.
- **약점 (오독·충돌·의미 차이)**:
  1. **꺼내두기 시 가장 심각한 오독 유발**: `local Frame = Create "Frame"`은 "Frame을 지금 즉시 생성하여 Frame 변수에 할당했다"는 명령형 과거/현재 동작으로 읽힙니다. 변수 `Frame`이 함수가 아니라 인스턴스라고 오해하기 가장 쉽습니다.
  2. **quad 명명 스타일과의 괴리**: quad의 핵심 API는 대부분 명사이거나 마커/상태(`Source`, `Store`, `Spread`, `Modifier`, `Slot`, `Ref`) 중심입니다. 순수 동사 `Create`는 이들과의 통일성이 떨어집니다.
- **코드 상에서의 가독성**:
  - *파일 상단*: `local Frame = q.Create "Frame"` (의미 불일치: Create 했는데 왜 아직 안 만들어졌는가?)
  - *공용 모듈*: `Frame = q.Create "Frame"` (어색함)

---

### 후보 5: `Decl` (또는 `Declare`) (`q.Decl`)

- **장점**:
  1. quad의 기존 대표 표면인 `q.Declaration`(`D`)의 직계 후속으로 브랜드 연속성이 유지됩니다.
  2. 명령형 생성이 아닌 선언형 스펙을 정의한다는 정체성을 보존합니다.
- **약점 (오독·충돌·의미 차이)**:
  1. 기존 `D = q.Declaration`의 무거운 테이블 이미지가 연상되어, "새로운 가벼운 타입 함수 표면"이라는 인상을 주기 어렵습니다.
  2. `local Frame = Decl "Frame"`: 다소 모호하며 함수 팩토리라는 직관성이 떨어집니다.
- **코드 상에서의 가독성**:
  - *파일 상단*: `local Frame = q.Decl "Frame"`
  - *공용 모듈*: `Frame = q.Decl "Frame"`

---

### X 이름 후보 비교 요약

| 후보 | 간결성 | 인스턴스 오독 방지 | 인라인 가독성 | 기존 quad API 통일감 | 타 라이브러리 친숙도 |
|---|---|---|---|---|---|
| **`New`** | ★★★★★ (3자) | ★★☆☆☆ | ★★★★★ | ★★★★★ | ★★★★★ (Roblox, Fusion) |
| **`Elem`** | ★★★★☆ (4자) | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★★☆ (선언형 표준, 내부 Elem) |
| **`Ctor`** | ★★★★☆ (4자) | ★★★★★ | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ (C++/엔지니어링) |
| **`Create`** | ★★★☆☆ (6자) | ★☆☆☆☆ | ★★★★★ | ★★☆☆☆ | ★★★★☆ (Vide) |
| **`Decl`** | ★★★★☆ (4자) | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★☆☆☆ (quad 구버전) |

### 🏆 X 이름 1순위 제안: **`New`** (조건부) / 차선책: **`Elem`**
- **제안 근거 [추정]**:
  - Roblox 생태계에서 요소를 생성하는 행위의 기본값은 단연 `New`입니다.
  - 저자가 언급했듯 기존 `q.New()`를 `NewModule`로 승격/정리할 수 있다면, 가장 가치 있고 직관적인 이름인 `New`를 요소 생성자 팩토리에 부여하는 것이 개발자 경험(DX)과 진입 장벽 측면에서 압도적으로 유리합니다.
  - 만약 "인스턴스를 즉시 반환하지 않고 생성자를 반환한다"는 개념적 오독이 가장 크게 우려된다면, 그 대안으로는 내부 타입(`FrameElem`)과 완벽히 부합하고 선언형 정체성을 살리는 **`Elem`**을 강력한 2순위로 추천합니다.

---

## 3. 과제 2: `q.New()` (모듈 인스턴스 생성) 변경 여부 및 후보

### 3.1 변경하는 것이 맞는가? — **"반드시 바꾸는 것을 권고 (적극 제안)"**

- **근거 1: 호출 빈도와 이름 가치(Name Value)의 극심한 불균형 [실측]**
  - `quad-base/src/init.luau:8-9`에 명시되어 있듯이 `require(quad-base)` 자체가 기본 모듈 인스턴스를 반환합니다.
  - 사용자는 99.9%의 경우 `Quad:UseProvider(QuadRoblox)`로 백엔드를 설치하여 바로 사용하며, `New()`는 일반적인 게임/UI 개발에서 거의 부를 일이 없습니다.
  - 실제로 전체 레포지토리에서 `q.New()`는 격리 테스트 스펙(`spec.d.luau:13` 등)에서만 쓰입니다.
  - 1년에 한 번 호출될까 말까 한 인프라 함수가 Luau 생태계에서 가장 귀중한 단어인 `New`를 독점하는 것은 심각한 비효율입니다.
- **근거 2: 사용자 오독과 진입 장벽 제거 [추정]**
  - quad를 처음 접한 사용자가 `q.New`를 보면 자연스럽게 `q.New("Frame")`을 떠올립니다. 하지만 실제 `q.New()`는 아무 인자 없이 빈 모듈 사본을 돌려주므로 심각한 인지 부조화를 낳습니다.
- **근거 3: 버전 타이밍 (v2 3.x 안정화 구간)**
  - 지금은 v2 3.x 구간으로 BREAKING 변경이 공식 허용된 시점입니다. 이 타이밍을 놓치면 영구히 레거시 이름 부채로 남게 됩니다.

### 3.2 변경 후보 분석

1. **`NewModule` (1순위 제안)**
   - **장점**: 저자의 직관과 정확히 일치하며, "새로운 Quad 모듈 인스턴스를 생성한다"는 사실을 가장 군더더기 없이 설명합니다.
   - **사용 예시**: `local isolated = quad.NewModule()`
   - **평가**: 기존 `New`의 뉘앙스를 유지하면서도 대상을 `Module`로 한정하여 오독이 불가능합니다.
2. **`CreateModule`**
   - **장점**: 동사형 팩토리로서 `New`와의 어휘 겹침을 원천 차단합니다.
   - **약점**: quad의 다른 최상위 팩토리들이 대부분 명사형(`Source`, `Store`, `Slot`)인 점과 대비됩니다.
3. **`NewEnvironment` (또는 `NewEnv`)**
   - **장점**: 독립된 디스패치 레지스트리와 브랜드 셋을 가진 "실행 환경"을 분리한다는 아키텍처적 본질을 정확히 반영합니다.
   - **약점**: 다소 무겁고 학술적인 느낌을 줍니다.

### 🏆 모듈 생성자 1순위 제안: **`NewModule`**
- 가장 자기설명적이며, 저자의 기존 문제의식과 완벽히 부합합니다.

---

## 4. 과제 3: 네임스페이스 구조 분석 (Flat vs Namespaced)

프로젝트 공용 모듈(`quad.luau`)에서 클래스 생성자를 export할 때, `q` 멤버와 한 테이블에 섞는 것(Flat)과 서브테이블로 나누는 것(Namespaced)에 대한 분석입니다.

### 4.1 단일 테이블 병합 (Flat: `q.Frame`)의 문제점

1. **충돌 문제 (`Tween` 및 잠재적 충돌) [실측]**
   - 실측에서 확인되었듯 Roblox에는 실제로 **`Tween`** 클래스가 존재합니다.
   - quad의 `q.Tween`은 애니메이션 선언자(`Types.TweenConstructor`, `quad-roblox/src/init.luau:217`)입니다.
   - Flat 구조를 사용할 경우, 사용자가 `X "Tween"`으로 Roblox Tween 인스턴스 생성자를 꺼내면 `q.Tween`과 정면 충돌하여 둘 중 하나가 파괴됩니다.
   - 또한 Roblox 엔진이 업데이트되면서 `State`, `Observer`, `Marker`, `Context`, `Scope`, `Action` 등의 이름으로 신규 클래스를 추가할 경우 잠재적 충돌 위험이 상존합니다.
2. **IDE 자동완성(IntelliSense) 공해 [추정]**
   - `q.`을 입력했을 때, 30여 개 이상의 Roblox UI 클래스(`Frame`, `TextLabel`, `ScrollingFrame`...)와 quad의 코어 반응형 API(`Source`, `Store`, `Effect`, `Slot`, `Ref`...)가 알파벳 순으로 뒤섞입니다.
   - 개발자가 반응형 원시값을 찾는지, UI 레이아웃 요소를 찾는지에 따라 시각적 노이즈가 극심해집니다.
3. **타입 인터섹션의 부하 전이 [추정]**
   - 단일 `q` 테이블에 수십 개의 클래스 생성자를 직접 병합하면, `q` 모듈 자체의 타입 정의가 무거워져 파일마다 `q`를 require할 때 타입 체커 예산을 불필요하게 소모하게 됩니다.

### 4.2 서브테이블 분리 (Namespaced: `q.UI.Frame`)의 장점

1. **완벽한 충돌 격리**:
   - `q.Tween`은 quad의 반응형 트윈 래퍼로 안전하게 유지됩니다.
   - 필요하다면 `q.UI.Tween`으로 Roblox Tween 인스턴스 생성자를 공존시킬 수 있습니다.
2. **정돈된 자동완성 (도메인 분리)**:
   - `q.` -> 리액티브 및 코어 도구들만 노출 (`Source`, `Store`, `Effect`, `Modifier`, `Spread`, `Slot`, `Tween`, `UI`)
   - `q.UI.` -> Roblox UI 생성자들만 노출 (`Frame`, `TextLabel`, `UIListLayout`...)
3. **타이핑 비용의 실질적 상쇄**:
   - 인라인으로 쓸 때 `q.UI.Frame { ... }`는 기존 `D.Frame { ... }`에 비해 단 2글자 차이입니다.
   - 파일 상단에서 Destructuring을 사용할 경우:
     ```luau
     local Frame, TextLabel = q.UI.Frame, q.UI.TextLabel
     ```
     컴포넌트 본문에서는 `Frame { ... }`로 작성할 수 있어 오히려 `D.` 접두사조차 없는 최상의 타이핑 효율과 가독성을 얻습니다.

### 🏆 네임스페이스 권고: **"서브테이블 `q.UI` 분리 강력 제안"**

#### 권장되는 공용 모듈 구성 (`ReplicatedStorage/quad.luau`) 제안:
```luau
--!strict
local Quad = require("@pkg/quad_base")
local QuadRoblox = require("@pkg/quad_roblox").QuadRoblox

-- 1. 백엔드 설치
local q = Quad:UseProvider(QuadRoblox)

-- 2. 프로젝트에서 자주 쓰는 UI 클래스들을 한 번만 꺼내둔다 (타입 자원 최적화)
local UI = {
    Frame = q.New "Frame",
    TextLabel = q.New "TextLabel",
    TextButton = q.New "TextButton",
    ImageLabel = q.New "ImageLabel",
    ScrollingFrame = q.New "ScrollingFrame",
    UIListLayout = q.New "UIListLayout",
    UIPadding = q.New "UIPadding",
    UICorner = q.New "UICorner",
}

-- 3. 서브테이블로 바인딩하여 export
q.UI = UI
return q
```

#### 컴포넌트 코드에서의 사용 권장 패턴 (Jetpack Compose 스타일):
```luau
local q = require("@common/quad")
-- 파일 상단에서 필요한 클래스만 가져옴
local Frame, TextLabel, UIListLayout = q.UI.Frame, q.UI.TextLabel, q.UI.UIListLayout

local function Card(props)
    return Frame {
        Size = UDim2.fromOffset(200, 100),
        UIListLayout { FillDirection = Enum.FillDirection.Vertical },
        TextLabel { Text = props.Title },
    }
end
```

---

## 5. 과제 4: 가장 일관된 종합 세트 제안

### 🌟 "The Clean Slate" (깨끗한 출발) 조합

| 항목 | 선택된 이름 | 역할 및 문법 |
|---|---|---|
| **1. 요소 생성자 꺼내기 (X)** | **`New`** | `local Frame = q.New "Frame"` |
| **2. 모듈 인스턴스 생성** | **`NewModule`** | `local isolated = quad.NewModule()` |
| **3. 공용 네임스페이스** | **`q.UI`** | `q.UI.Frame` / 상단 `local Frame = q.UI.Frame` |

### 이 조합이 가장 일관된 이유 [추정]:
1. **이름의 제자리 찾기**:
   - 거의 쓰이지 않는 내부 모듈 생성자에서 `New`라는 가장 직관적인 키워드를 회수하여, 사용자가 매일 작성하는 요소 생성 팩토리에 돌려줍니다.
   - 모듈 생성자는 `NewModule`이라는 명확한 이름을 얻어 정체성이 분명해집니다.
2. **도메인 격리와 미래 안전성**:
   - `q.UI`로 분리함으로써 `q.Tween`과의 이름 충돌을 원천 차단하고, 향후 Roblox 엔진이 어떤 클래스를 추가하더라도 quad 코어 API와 충돌할 일이 없습니다.
   - `q.`은 "상태/반응형 엔진 도메인", `q.UI.`는 "렌더링/컴포넌트 도메인"으로 깔끔하게 이원화됩니다.
3. **Jetpack Compose / Kotlin 스타일과의 완벽한 정합**:
   - 파일 상단에서 `local Frame = q.UI.Frame`으로 꺼내두고, 본문에서 `Frame { ... }`로 호출하는 구조는 사용자가 목표로 하는 Kotlin 생성자 스타일 및 타입 체커 예산 한계 극복 패턴과 완벽하게 부합합니다.

---

## 6. 미완 및 추가 고려사항

1. **`q.Spread`와 `q.Modifier`의 위치**:
   - `q.Spread`와 `q.Modifier` 역시 클래스 이름을 첫 번째 인자로 받습니다(`q.Spread "GuiObject" { ... }`, `q.Modifier "Frame"`).
   - 이 둘은 UI 요소 자체를 생성하는 것이 아니라 속성 묶음/수식어이므로 `q.UI` 안이 아닌 최상위 `q.Spread`, `q.Modifier`에 남는 것이 자연스러우나, 저자의 스타일에 따라 `q.UI.Spread`로 함께 모을지 검토가 필요합니다.
2. **`q.New`를 인라인으로 부를 때의 타입 한도 안내**:
   - 실측 보고서(`.claude/audit/decl-typefn-probe-2026-10-16/REPORT.md:53-56`)에 나타났듯, 인라인 `New "Frame" { ... }`를 한 파일에서 300회 이상 호출하면 Luau LSP의 타입 검사가 붕괴합니다. 공식 문서에서 "파일 상단 선언 권장"을 명확한 베스트 프랙티스로 안내해야 합니다.
