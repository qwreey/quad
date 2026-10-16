# 이름 탐색 — quad의 "클래스 이름으로 요소 생성자를 꺼내는 함수"와 quad 인스턴스 생성 함수

결정을 내리는 게 아니라 후보와 근거를 내는 과제다. 결정은 라이브러리 저자(사용자)가 한다.

## 배경

quad는 Roblox Luau용 선언형 UI 라이브러리다(Fusion·Vide와 같은 계열, v1 2.x는 이미 쓰이고 있고 지금은 v2 3.x 안정화 구간이라 BREAKING 허용).
사용자는 보통 `local q = require(...)`로 모듈 인스턴스 `q`를 받아 `q.Source(…)`, `q.Store`, `q.Slot`, `q.Modifier`, `q.OnChange("Visible", fn)`,
`q.OnEvent("MouseEnter", fn)`, `q.Spread`, `q.Claim`, `q.Tween`, `q.Ref`, `q.Context`, `q.Effect`, `q.Out` 같은 이름을 쓴다(파스칼 케이스, 짧은 명사·동사).

지금 요소 생성은 거대한 생성 테이블 `D = q.Declaration`에서 `D.Frame { … }`로 한다. 이것을 타입 함수 기반 표면으로 바꾸기로 했다(타입 검사 비용·자동완성 때문 — 실측으로 확정).
새 표면은 이렇게 쓴다:

```luau
-- 파일 위(또는 프로젝트 공용 모듈)에서 쓸 클래스를 한 번 꺼내 둔다 — Jetpack Compose처럼 위에 나열하는 스타일을 권장
local Frame = X "Frame"          -- X가 이름을 정할 함수. 문자열은 Roblox 클래스 이름, 결과는 생성자
local TextLabel = X "TextLabel"

-- 꺼낸 생성자는 Kotlin 생성자처럼 타입 이름과 같은 이름으로 부르고, 결과 타입도 그 클래스
local label = TextLabel { Text = "hi", TextSize = 18 }

-- 같은 꼴(커리, 이름 먼저)의 형제: 상위 클래스 공통 속성 묶음 / Modifier
local hover = q.Spread "GuiObject" { BackgroundTransparency = 0.2 }
local mod = q.Modifier "Frame"   -- (이름 후보 아님, 참고용 — 이미 있는 이름)
```

X는 런타임에서 "클래스 이름 → 그 클래스 요소를 만드는 함수"를 돌려준다. 인스턴스를 바로 만들지 않는다(생성자를 돌려줄 뿐).
**`q.New`는 이미 쓰이고 있다** — `q.New()`는 quad 모듈 인스턴스를 새로 만드는 함수(같은 라이브러리의 독립 사본; 인스턴스마다 브랜드·레지스트리가 따로).
저자는 *"quad.New 도 이름이 좋진 못했던걸 수도 있겠음. NewModule 이나 명시적으로 자기설명적이여야했는데"*라고 했다 — 즉 `q.New()`를 자기설명적인 이름으로 바꾸고
`New`를 X에 쓰는 길도 열려 있다. 참고로 Fusion은 `New "Frame" { … }`(0.3부터 `scope:New "Frame" { … }`), Vide는 `create "Frame" { … }`을 쓴다.

**네임스페이스 고민(저자)**: 꺼내 두기는 타입 자원을 먹으므로, 파일마다 하지 않고 프로젝트에 공용 `quad.luau` 하나를 두어 거기서 필요한 클래스를 `X "Frame"`으로 꺼낸 뒤
q의 멤버와 같이 export해 다른 코드는 `q.Frame { … }`처럼 쓰는 것을 권장할 수 있다. 그러면 Roblox 클래스 이름과 q 멤버 이름이 한 네임스페이스에서 만난다
— 지금 겹치는 것은 `Tween`(Roblox 클래스이자 q.Tween) 하나뿐이지만 앞으로 늘 수 있다. 같은 네임스페이스에 섞을지, `q.UI.Frame`/별도 테이블처럼 나눌지도 의견을 달라.

## 낼 것

1. **X 이름 후보** 3~6개, 각각: 장점, 약점(오독·충돌·다른 라이브러리와의 의미 차이), `local Frame = X "Frame"` 줄과 공용 모듈 안에서 어떻게 읽히는지. 1순위 하나.
2. **`q.New()`(모듈 인스턴스 생성)를 바꿀지와 후보** — 바꾸는 게 맞는지 자체도 판단. 바꾼다면 후보 2~4개와 1순위.
3. **네임스페이스**: 공용 모듈에서 클래스 생성자를 q 멤버와 한 테이블에 섞는 것 vs 나누는 것 — 충돌 처리(`Tween`)까지 포함한 권고.
4. 이 셋을 한 세트로 묶었을 때 가장 일관된 조합 하나.

평문 한국어로, 마지막 메시지 하나에 전부.
