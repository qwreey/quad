# quad 배열부 이벤트 디스크립터 이름 탐색 보고서

> **안내**: 본 보고서의 분석과 제안은 에이전트의 "제안"이며, 최종 결정은 사용자가 합니다.  
> 근거 표기 안내: 직접 명령을 실행해 확인한 것은 **[실측]**, 코드와 문서를 읽고 추론한 것은 **[추정]**으로 표기했습니다.

---

## 1. 배경 및 문제 정의

### 1.1 현황과 문제점 [실측 및 추정]
- **현행 문자 키 이벤트**: quad의 선언형 요소에서 Roblox 엔진 이벤트는 현재 문자 키로 연결됩니다(`D.TextButton { Activated = fn }`). 이는 `quad-roblox/src/Handlers/Event.luau:63-86`에 정의된 `Event` 핸들러(`keyType = "string"`, `priority = NORMAL - 1`)가 처리합니다. **[실측]**
- **키 경쟁(충돌) 문제**: Lua 테이블 리터럴 특성상 동일한 문자 키는 단 하나만 남고 마지막 값으로 덮어써집니다. 따라서 `Hoverable`, `Draggable` 같은 재사용 행동 팩토리를 만들어 한 요소에 나열하거나 `q.Spread`로 펼쳐 넣을 때 동일 이벤트(`MouseEnter` 등)를 두고 키 충돌이 발생하여 앞선 핸들러가 유실됩니다. **[추정]**
- **엔진과의 불일치**: Roblox 엔진의 `RBXScriptSignal`은 원래 여러 번 `:Connect`를 호출하여 다수의 콜백을 등록할 수 있으나, 단일 문자 키 형태의 API로는 이 다중 연결을 표현할 수 없습니다. **[추정]**

### 1.2 해결책과 선례 [실측]
- **처방**: `OnChange`의 짝이 되는 **배열부 이벤트 디스크립터** `q.X(eventName, fn)`를 도입하여, 배열 자리에 여러 개를 나열하면 각각 `:Connect`되도록 합니다. (문자 키 이벤트는 단독 사용 편의를 위해 그대로 유지)
- **선례 (`OnChange`의 역전)**: 과거 quad의 `OnChange` 역시 처음에는 Fusion 스타일의 특수 키 객체 `[OnChange "Text"] = fn` 형태였으나, 2026-09-03 세션에서 "배열부 값 `q.OnChange("Text", fn)`"으로 전면 역전되었습니다 (`.claude/archive/onchange-hash-key-reversed.md:1-67`). 당시 역전 사유 중 하나가 바로 "같은 프로퍼티에 여러 콜백을 지정할 수 있게 함"이었습니다. 이번 배열부 이벤트 디스크립터 도입은 그 설계 철학과 완전히 일치합니다. **[실측]**

---

## 2. 판단 기준 4가지 요약

1. **`OnChange`와의 대칭성**: `OnChange("Text", fn)`과 나란히 놓였을 때 자연스러운 쌍으로 읽히는가 (프로퍼티 변화 vs 엔진 이벤트).
2. **Roblox/Luau 개발자의 직관성 및 타 생태계(Fusion 등)와의 정합성**: "이벤트에 함수를 연결하며, 여럿이면 각각 연결된다"는 멘탈 모델이 바로 떠오르는가. Fusion의 `OnEvent`(키 객체)와 혼동되지 않는가.
3. **생명주기 훅과의 변별성**: `OnCreated`, `OnRendered`, `OnDestroyed`와 섞여 "특정 시점 훅"으로 오해되지 않는가.
4. **간결성 및 배열부 가독성**: 팩토리 내부 및 컴포넌트 선언부에서 간결하고 읽기 좋은가.

---

## 3. 후보군 비교 분석 (최소 5개 후보)

### 후보 1: `OnEvent` (사용자 1안) — `q.OnEvent(eventName, fn)`

```luau
D.TextButton {
    Text = "Save",
    q.OnChange("Text", function(txt) ... end),
    q.OnEvent("Activated", function() save() end),
    q.OnEvent("MouseEnter", function() onHover() end),
}
```

- **(1) `OnChange`와의 대칭성**: **최상 (★★★★★)**  
  `q.OnChange`와 `q.OnEvent`는 `On + 대상범주` 구조로 완벽한 문법적·시각적 대칭을 이룹니다. quad 문서에서 "배열부 신호 바인딩 쌍"으로 설명하기에 가장 깔끔합니다. **[추정]**
- **(2) 직관성 및 타 생태계**: **최상 (★★★★★)**  
  Fusion(0.2/0.3)에서 `[OnEvent "Activated"] = fn`을 써본 개발자에게 `OnEvent`는 이미 "Roblox 이벤트를 연결하는 API"로 깊게 각인되어 있어 인지 부하가 거의 없습니다. Fusion은 키 객체였고 quad는 값 호출(`(name, fn)`)이라는 차이가 있지만, 역할(이벤트 연결)이 100% 같으므로 오해의 소지가 없으며, 배열부에 나열되는 형태상 "각각 연결된다"는 점도 자연스럽게 받아들여집니다. **[추정]**
- **(3) 생명주기 훅과의 변별성**: **우수 (★★★★☆)**  
  생명주기 훅 3종(`OnCreated`, `OnRendered`, `OnDestroyed`)은 모두 인자가 `(fn)` 단 하나뿐이며 과거분사형(`-ed`)입니다 (`docs/reference/sugar/04-lifecycle-hooks.md:23-28`). 반면 `OnEvent`는 명사형이며 `(name, fn)` 2인자를 받으므로 형태상 즉시 구분됩니다. 이미 `q.OnChange(name, fn)`이 생명주기 훅과 혼동 없이 공존하고 있는 것과 같습니다. **[실측 및 추정]**
- **(4) 간결성 및 가독성**: **우수 (★★★★☆)**  
  7글자로 `OnChange`와 길이가 정확히 같아 코드 정렬과 시각적 리듬이 좋습니다. **[실측]**
- **단점**: "다중 연결"이라는 동작 메커니즘 자체는 이름만으로 드러나지 않고 배열부의 공통 규칙에 기댑니다.

---

### 후보 2: `Connect` — `q.Connect(eventName, fn)`

```luau
D.TextButton {
    Text = "Save",
    q.OnChange("Text", function(txt) ... end),
    q.Connect("Activated", function() save() end),
    q.Connect("MouseEnter", function() onHover() end),
}
```

- **(1) `OnChange`와의 대칭성**: **미흡 (★★☆☆☆)**  
  `OnChange`(상태 기술/전치사구)와 `Connect`(명령형 동사)는 문법적 축이 맞지 않습니다. API 세트로서의 통일감이 떨어집니다. **[추정]**
- **(2) 직관성 및 타 생태계**: **최상 (★★★★★)**  
  Roblox 엔진의 공식 메서드가 `RBXScriptSignal:Connect(fn)`이므로, Roblox 개발자에게 가장 본능적이고 친숙한 단어입니다. 또한 Roblox에서 `:Connect`를 여러 번 호출하면 각각 연결된다는 것이 기본 상식이므로, "다중 연결, 경쟁 없음"이라는 멘탈 모델을 단어 자체로 가장 완벽하게 전달합니다. Fusion 키 객체와의 혼동 여지도 0%입니다. **[추정]**
- **(3) 생명주기 훅과의 변별성**: **최상 (★★★★★)**  
  `On-` 접두사가 전혀 없으므로 생명주기 훅과 시각적으로 완전히 격리됩니다. 훅으로 오해될 가능성이 0%입니다. **[추정]**
- **(4) 간결성 및 가독성**: **우수 (★★★★☆)**  
  7글자로 깔끔하며 행동이 명확히 드러납니다.
- **단점**: quad의 D(`Declaration`)는 선언형(declarative) 렌더러인데, 요소 테이블 안에 명령형 동사(`Connect`)가 들어가는 것은 선언적 어조와 다소 어긋납니다. 또한 `OnChange`의 짝으로 읽히지 않습니다. **[추정]**

---

### 후보 3: `Event` — `q.Event(eventName, fn)`

```luau
D.TextButton {
    Text = "Save",
    q.OnChange("Text", function(txt) ... end),
    q.Event("Activated", function() save() end),
    q.Event("MouseEnter", function() onHover() end),
}
```

- **(1) `OnChange`와의 대칭성**: **보통 (★★★☆☆)**  
  `OnChange`와는 짝으로 읽히지 않지만, quad의 다른 명사 디스크립터들(`q.Tag`, `q.Attr`, `q.Slot`)과는 어울립니다. **[추정]**
- **(2) 직관성 및 타 생태계**: **보통 (★★★☆☆)**  
  Roblox 개발자에게 `Event`는 친숙하지만, 단독 명사 `Event`는 "이벤트를 연결하는 디스크립터"라기보다는 "새 이벤트를 정의하거나 발행하는 객체(BindableEvent, EventEmitter)"로 오해될 소지가 있습니다. 또한 이미 문자 키 `Activated = fn`이 있는데 굳이 `q.Event`를 쓰는 이유가 드러나지 않습니다. **[추정]**
- **(3) 생명주기 훅과의 변별성**: **우수 (★★★★☆)**  
  `On-` 접두사가 없어 훅과 섞이지 않습니다.
- **(4) 간결성 및 가독성**: **우수 (★★★★★)**  
  5글자로 짧고 깔끔합니다.
- **단점**: quad 내부 아키텍처에서 이미 문자 키 핸들러 이름으로 `"Event"`가 선점되어 있습니다 (`quad-roblox/src/Handlers/Event.luau:63`). **[실측]**

---

### 후보 4: `On` — `q.On(eventName, fn)`

```luau
D.TextButton {
    Text = "Save",
    q.OnChange("Text", function(txt) ... end),
    q.On("Activated", function() save() end),
    q.On("MouseEnter", function() onHover() end),
}
```

- **(1) `OnChange`와의 대칭성**: **미흡 (★★☆☆☆)**  
  `On`과 `OnChange`를 나란히 두면 `On`이 일반적인 이벤트 바인딩이고 `OnChange`는 특수한 변경 바인딩처럼 보여 개념적 계층이 엇갈립니다. **[추정]**
- **(2) 직관성 및 타 생태계**: **보통 (★★★☆☆)**  
  Node.js `emitter.on(event, fn)`, Svelte `on:click`, Vue `v-on` 등 웹 생태계 경험자에게는 친숙하나, Roblox 고유의 관례와는 거리가 있습니다. 또한 quad는 과거에 `On.EventName` 도트 접근 네이밍을 검토했다가 기각한 바 있습니다 (`.claude/base/event-plan.md:17`). **[실측 및 추정]**
- **(3) 생명주기 훅과의 변별성**: **미흡 (★★☆☆☆)**  
  단어가 너무 짧고 추상적이어서 훅인지, 리스너인지, 제어 연산자인지 정체성이 흐릿합니다.
- **(4) 간결성 및 가독성**: **최상 (★★★★★)**  
  단 2글자로 가장 짧습니다.
- **단점**: 과도한 축약으로 인해 quad의 다른 어휘들과 어울리지 않고 부유하는 느낌을 줍니다.

---

### 후보 5: `OnSignal` — `q.OnSignal(eventName, fn)`

```luau
D.TextButton {
    Text = "Save",
    q.OnChange("Text", function(txt) ... end),
    q.OnSignal("Activated", function() save() end),
    q.OnSignal("MouseEnter", function() onHover() end),
}
```

- **(1) `OnChange`와의 대칭성**: **우수 (★★★★☆)**  
  `On-` 접두사로 대칭을 이룹니다.
- **(2) 직관성 및 타 생태계**: **미흡 (★★☆☆☆)**  
  Roblox 엔진 타입이 `RBXScriptSignal`이므로 기술적으로는 맞지만, **역설적이게도 `OnChange`가 사용하는 `GetPropertyChangedSignal` 역시 Signal입니다.** 따라서 하나는 `OnChange`이고 다른 하나는 `OnSignal`이라고 하면 "OnChange도 Signal인데 왜 OnSignal은 일반 이벤트만 받는가?"라는 개념적 중의성과 혼란이 생깁니다. 또한 Roblox GUI 개발자들은 클릭이나 호버를 보통 "Signal"이 아니라 "Event"라고 부릅니다. **[추정]**
- **(3) 생명주기 훅과의 변별성**: **우수 (★★★★☆)**  
  `Signal`이라는 기술 명사로 훅과 구분됩니다.
- **(4) 간결성 및 가독성**: **보통 (★★★☆☆)**  
  8글자로 후보 중 가장 깁니다.

---

### 후보 6: `Listen` — `q.Listen(eventName, fn)`

```luau
D.TextButton {
    Text = "Save",
    q.OnChange("Text", function(txt) ... end),
    q.Listen("Activated", function() save() end),
    q.Listen("MouseEnter", function() onHover() end),
}
```

- **(1) `OnChange`와의 대칭성**: **미흡 (★★☆☆☆)**  
  대칭성이 없습니다.
- **(2) 직관성 및 타 생태계**: **보통 (★★★☆☆)**  
  이벤트 리스너라는 개념은 보편적이나, Roblox의 표준 어휘는 `Connect`이지 `Listen`이 아니므로 Roblox 생태계 관점에서 이질적입니다. **[추정]**
- **(3) 생명주기 훅과의 변별성**: **우수 (★★★★☆)**  
  훅과 섞이지 않습니다.
- **(4) 간결성 및 가독성**: **우수 (★★★★☆)**  
  6글자.

---

## 4. 종합 비교표

| 후보 | (1) `OnChange`와 짝 | (2) Roblox 직관성 & 타 생태계(Fusion) | (3) 훅 변별성 | (4) 길이 & 가독성 | 종합 순위 |
|---|---|---|---|---|:---:|
| **`OnEvent`** (사용자 1안) | **최상** (`On-` 완전 대칭) | **최상** (Fusion과 동일 어휘, 인지 부하 0) | **우수** (2인자 + 명사형으로 구분) | **우수** (7자, OnChange와 동일) | **1위 (추천)** |
| **`Connect`** | **미흡** (비대칭, 명령형) | **최상** (Roblox 엔진 공식 어휘, 다중성 명확) | **최상** (`On-` 없어 혼동 0%) | **우수** (7자, 명료함) | **2위 (차선)** |
| **`Event`** | **보통** (명사형 디스크립터) | **보통** (이벤트 발생자 오해 가능) | **우수** (`On-` 없음) | **우수** (5자, 짧음) | 3위 |
| **`On`** | **미흡** (계층 불일치) | **보통** (웹 친숙, Roblox 관례 아님) | **미흡** (정체성 모호) | **최상** (2자, 초소형) | 4위 |
| **`OnSignal`** | **우수** (`On-` 대칭) | **미흡** (OnChange도 Signal이라 중의적) | **우수** (기술 명사) | **보통** (8자, 긺) | 5위 |
| **`Listen`** | **미흡** (비대칭) | **보통** (Roblox에서 낯선 어휘) | **우수** (`On-` 없음) | **우수** (6자) | 6위 |

---

## 5. 결론 및 제안: 추천 하나 · 차선 하나

### 💡 추천: `OnEvent` (사용자 1안)

**이유**:
1. **`OnChange`와의 완벽한 대칭 (Criterion 1)**:  
   quad의 선언형 요소에서 배열부 신호 바인딩은 두 축입니다.
   - 프로퍼티가 바뀔 때: `q.OnChange("Text", fn)`
   - 엔진 이벤트가 발생할 때: `q.OnEvent("Activated", fn)`  
   둘은 `On + 대상` 구조로 완벽히 짝을 이루며, quad 문법과 레퍼런스 문서 전체의 일관성을 극대화합니다.
2. **Roblox/Fusion 생태계 멘탈 모델의 연속성 (Criterion 2)**:  
   Fusion의 `OnEvent`로 인해 Roblox 선언형 UI 생태계에서 "이벤트 바인딩 = OnEvent"라는 인식이 이미 확고합니다. quad의 `OnChange`가 과거 Fusion식 키 객체에서 배열부 값으로 발전했듯, `q.OnEvent` 역시 같은 철학적 궤적을 밟아 개발자에게 가장 자연스럽게 받아들여집니다.
3. **생명주기 훅과의 실질적 비혼동 (Criterion 3)**:  
   생명주기 훅(`OnCreated`, `OnRendered`, `OnDestroyed`)은 인자가 `(fn)` 하나뿐인 과거분사형 시점 훅입니다. 반면 `OnEvent`는 `(name, fn)` 2인자를 받는 디스크립터이므로, 호출 형태와 타입 수준에서 완전히 구분됩니다.
4. **선언형(Declarative) 어조 유지**:  
   D 리터럴 안에서 명령형 동사(`Connect`)보다 조건/사건 중심의 선언적 표현(`OnEvent`)이 자연스럽습니다.

---

### 🥈 차선: `Connect`

**이유**:
1. **Roblox 엔진 공식 어휘의 직관성**:  
   Roblox 개발자가 일상적으로 쓰는 `signal:Connect(fn)`을 그대로 사용하여, "이 이벤트에 연결한다"는 의미가 즉각 전달됩니다.
2. **"다중 연결(경쟁 없음)"의 강력한 연상**:  
   Roblox에서 `:Connect`는 여러 번 부르면 여러 번 연결되는 것이 기본 동작이므로, 팩토리나 Spread에서 여러 개를 놓아도 키 경쟁 없이 각각 연결된다는 이번 API의 핵심 존재 이유를 단어 자체로 완벽하게 설명합니다.
3. **생명주기 훅과의 완전한 시각적 격리**:  
   `On-` 접두사를 전혀 쓰지 않으므로 생명주기 훅과의 혼동 가능성을 원천적으로 배제하고 싶을 때 최고의 대안입니다.
4. **차선으로 둔 사유**:  
   `q.OnChange`와의 형태적 대칭성이 완전히 깨지며, 선언형 UI 안에서 명령형 동사가 다소 도드라집니다.

---

## 6. 검증 및 테스트 현황 [실측]

- 실행 명령: `( ulimit -v 4000000; timeout 600 ./scripts/test.sh )`
- 실행 결과: **exit code 0 (전체 테스트 통과 PASS)** **[실측]**
- 작업 환경 규정 준수: 원본 레포 및 worktree 외부 파일 수정 없음, 제한된 git 명령 일절 미사용. **[실측]**
