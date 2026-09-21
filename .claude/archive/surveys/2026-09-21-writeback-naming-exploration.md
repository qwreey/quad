# 되쓰기 슈거 이름·걸러내기 탐사 원문 (2026-09-21 밤, sonnet 둘)

> 판정 요약과 사용자 결정은 `research/upward-flow-plan.md` 8절. 여기는 두 탐사자의 보고 원문(외부자: Fusion/Vide를 써 본 Roblox 개발자 시점 / 내부자: 코퍼스 규약·충돌 실측).

---

# A. 외부자

# 이름 후보 판정 — Fusion/Vide를 써본 외부자 시점

먼저 제가 읽은 근거를 밝힙니다. quad의 `docs/getting-started/03-flowing-values.md`와 `04-reacting.md`,
`docs/reference/roblox/02-d.md`, `docs/reference/roblox/05-onchange.md`를 읽었고, 비교 대상으로 Fusion의
`Out.luau`·`OnChange.luau`, Vide의 `changed.luau`를 읽었습니다. 아래 판단은 전부 이 문서들에 실제로 적힌
문장에 근거합니다 — 추측이 들어간 자리는 그렇다고 표시했습니다.

## (1) 그 코드 블록에서 각 후보를 보면 무엇을 기대하는가

```
TextBox {
    Text = textSrc,
    Bind("Text", textSrc),
}
```

이 모양을 처음 보면 저는 `Bind`가 가장 위험한 이름이라고 느낍니다. Fusion을 오래 쓴 사람에게 "bind"는
WPF나 Avalonia의 `Binding`처럼 기본적으로 양방향이거나 최소한 모드를 고를 수 있는 일반 명사이고, React
생태계에서도 "bind"는 어느 한쪽이 아니라 "연결한다"는 중립적 어감을 갖습니다. 그래서 같은 테이블 안에
`Text = textSrc`라는 줄이 이미 있는데 바로 아래 줄에 `Bind("Text", textSrc)`가 또 있으면, 저라면 반사적으로
"이 두 줄이 겹치는 일을 하는 건 아닌가, `Bind` 한 줄이면 양방향이 다 되고 `Text = textSrc`는 필요 없어지는
게 아닌가"라고 의심하게 됩니다. 실제로는 문서가 "아래 방향은 그대로 평범한 프로퍼티 바인딩"이라고 정해
놓았다는 걸 알지만, 그건 사용자가 미리 설명을 듣고 왔을 때 얘기고 코드 블록만 보고 판단하면 `Bind`라는
이름 자체가 그 오해를 유도합니다. 이름이 불러일으키는 첫인상과 실제 동작(단방향, 그리고 두 줄이 다 필요함)
사이의 거리가 후보들 중 가장 멉니다.

`Out`은 반대로 방향을 즉시 알려줍니다. "이 값이 인스턴스 밖으로 나온다"는 뜻이 단어 자체에 있어서, 저는
`Out("Text", textSrc)`를 보자마자 "이건 읽기 방향이고, 위의 `Text = textSrc`는 쓰기 방향이니 둘이 다른
일을 한다"고 바로 이해할 것 같습니다. 양방향이라는 오해는 거의 안 생깁니다.

`Sync`는 오히려 `Bind`보다 더 양방향처럼 들립니다 — "동기화"는 두 값을 서로 맞춘다는 뜻이 강해서, 이
후보를 보면 저는 `Text = textSrc` 줄이 필요 없어졌다고 더 강하게 착각할 것 같습니다. `Writeback`과
`Feed`는 방향이 뚜렷합니다. `Writeback`은 "엔진이 바꾼 값을 다시 써 넣는다"는 뜻이 이름에 그대로 있어서
가장 오해가 적고, `Feed`도 "원천에 값을 먹인다"는 방향성이 있어 나쁘지 않습니다. 다만 `Feed`는 quad
어휘에서 "파이프에 값을 흘려보낸다"는 04장의 은유(원천→파이프→프로퍼티)와 miscue가 날 수 있어서
살짝 걸립니다. `Into`는 방향은 맞지만 무엇이 무엇 "안으로" 들어가는지 문맥 없이는 모호합니다(값이
Source 안으로 들어가는 건지, 프로퍼티 안으로 들어가는 건지 이름만 보고는 반반입니다). `OnChangeSet`은
아래 (3)에서 다루겠지만 동작은 정확히 알려주는 대신 이름이 길고 이미 있는 `q.OnChange`와 시각적으로
겹쳐서, 그 자리에 있는 두 심볼(`OnChange`와 `OnChangeSet`)이 남매인지 한쪽이 다른 쪽을 대체하는지 헷갈릴
여지가 있습니다.

## (2) `Out` 재사용 — 도움인가 혼란인가

Fusion의 `Out`을 실제로 읽어 보면, 이것은 해시 키 자리에 쓰는 특수 키입니다. `keyCache`에 프로퍼티
이름별로 캐시된 `SpecialKey` 객체를 돌려주고, 실제 쓰임은 `[Out "Text"] = someValueObject`처럼 **해시
키 자리에 `Out("Text")`를 놓고 값 자리에 State(정확히는 쓸 수 있는 `Value`)를 놓는** 모양입니다. 반면
quad가 정한 모양은 배열부(숫자 키) 자리에 놓는 값 하나, 즉 `Out("Text", textSrc)`처럼 이름과 Source를
한 호출에 같이 넘기는 형태입니다. 이 구조적 차이 때문에 Fusion을 써 본 사람이 quad에서 `Out`을 처음
보면 순간적으로 `[Out("Text")] = textSrc`처럼 손이 먼저 나갈 수 있습니다 — 실제로 quad의 `q.OnChange`
문서를 보면 quad는 이미 이 "숫자 키 자리에 놓는 디스크립터" 패턴을 `OnChange`로 쓰고 있고(`q.OnChange(name,
fn)`이 배열부 값), 그 옆에 새로 생기는 것도 같은 패턴을 따를 것이므로, Fusion 출신이라도 quad의 D 문서
(`02-d.md`)를 한 번 훑으면 "여기서는 특수 키가 아니라 배열부 값으로 다 통일돼 있구나"를 금방 알아챌
것입니다. 즉 혼란은 있지만 **얕고 짧은** 혼란입니다 — 첫 시도에서 타입 에러나 문법 에러로 바로 드러나서
정정되지, 잘못된 의미론을 오래 믿고 가는 종류의 혼란은 아닙니다.

의미 쪽으로 보면 오히려 `Out`을 재사용하는 게 **더 정확합니다**. Fusion에서 `Out`이 하는 일은 프로퍼티가
바뀔 때마다 그 값을 미리 준 `Value` 객체에 `:set()`으로 밀어 넣는 것이고, 이것은 quad가 지금 만들려는
새 슈거(엔진이 바꾼 프로퍼티 → Source에 쓴다)와 정확히 같은 일입니다. Fusion에서 `OnChange`는 임의
콜백을 받는 별개의 저수준 프리미티브이고, quad의 `q.OnChange(name, fn)`도 그 자리에 정확히 대응합니다.
그러니 이름의 짝을 Fusion과 맞추면 `OnChange`는 `OnChange`끼리, "Source에 써 넣는" 쪽은 `Out`끼리
대응해서 오히려 Fusion 경험이 그대로 옮겨집니다. 결론적으로 저는 구조(해시 키 대 배열부 값)의 차이는
한 번 코드를 써 보면 바로 풀리는 얕은 마찰이고, 의미(방향과 "Source에 값을 밀어 넣는다"는 동작)의
일치는 그보다 오래가는 이득이라고 봅니다 — 그래서 `Out` 재사용은 순혼란보다 도움 쪽에 더 가깝다고
판단합니다.

## (3) 이름이 "OnChange"라는 사실을 담아야 하는가

담을 필요는 없다고 봅니다. `04-reacting.md`는 이 슈거를 두고 "엔진이 바꾼 프로퍼티를 Source로 들여오는
것"이라고 설명하면서 그 구현이 `q.OnChange`라는 것도 같이 밝히지만, 사용자가 실제로 신경 쓰는 것은 결과
(그 프로퍼티가 바뀌면 이 Source가 그 값을 갖게 된다)이지 그 결과를 만드는 방법(프로퍼티 변경 신호에
연결한다)이 아닙니다. `q.OnChange` 자신의 문서(`05-onchange.md`)를 보면 그 이름 자체가 이미 "메커니즘을
그대로 옮긴 이름"입니다 — `GetPropertyChangedSignal` 바인딩을 그대로 이름으로 썼고, 그게 맞는 이유는
`OnChange`가 **저수준 프리미티브**라서 사용자가 "무엇에 반응하는가"를 정확히 알아야 하기 때문입니다.
하지만 지금 만드는 것은 "그 프리미티브 위에 얹는 순수 슈거"라고 이미 결정돼 있습니다. 슈거 한 단계
위에서는 이름이 구현 디테일(신호 기반이냐, 매 프레임 폴링이냐, 다른 백엔드에서는 Attribute 감시로 갈리느냐)
을 감추고 사용자가 실제로 얻는 것(엔진이 바꾼 값이 Source에 반영된다)만 말해주는 편이 더 오래 갑니다.
`OnChangeSet`처럼 메커니즘 이름을 그대로 접두어로 박아 넣으면, 나중에 구현이 바뀌거나(예: 다른 백엔드가
신호가 아니라 다른 방식으로 같은 결과를 낸다면) 이름이 거짓말을 하게 될 위험이 있고, 지금 당장도 이미
존재하는 `q.OnChange`와 이름이 겹쳐 보여서 "이 둘이 뭐가 다른가"를 매번 설명해야 하는 부담이 생깁니다.

## (4) "같은 값이면 건너뛴다" — 무엇을 기대하는가

`05-onchange.md`가 이미 실측으로 밝혀 둔 사실이 있습니다. 엔진은 프로퍼티에 같은 값을 다시 대입해도
변경 신호를 쏘지 않습니다(실기기 실측 0회, mock 백엔드만 값 비교 없이 1회 쏩니다). 그리고
`03-flowing-values.md`가 가리키는 `Source` 레퍼런스는 "`:Set`이 같은 값에도 늘 전파하는 이유"를 다룬다고
적혀 있어서, `Source:Set`은 값이 같아도 항상 아래로 전파한다는 것도 짐작할 수 있습니다(문서 제목에서 뜻을
읽은 것이라, 이 문장만은 추정입니다 — 본문은 안 읽었습니다). 이 둘을 합치면 원래 걱정하는 무한 루프
(Source → 프로퍼티 → 신호 → Source → 프로퍼티 → …)는 애초에 안 생깁니다: 엔진이 같은 값 재대입에
신호를 안 쏘는 지점에서 고리가 저절로 끊기기 때문입니다. 그러니 새 슈거가 "같은 값이면 건너뛴다"고
해도 그건 **루프를 막기 위해 필요한 안전장치가 아니라**, 그 루프가 어차피 안 도는데도 `Source:Set`이
무조건 전파하는 성질 때문에 발생하는 **불필요한 재계산**(그 Source를 구독하는 `:Compute` 체인이 다시
돌고, `Observer`가 다시 불리는 것)을 막기 위한 최적화로 읽힙니다.

세 선택지 중 제가 가장 안 놀랄 것은 "들어오는 값이 `src`의 현재 값과 같으면 `:Set`을 하지 않는다"입니다.
"같은 값을 건너뛴다"는 표현 자체가 이미 값 비교를 전제하고 있고, 다른 양방향 바인딩 라이브러리들(WPF나
Avalonia류)도 흔히 이런 값 동등성 검사를 두는 관행이 있어서 낯설지 않습니다. 다만 quad 자신의 문서가
"Source는 같은 값에도 항상 전파한다"는 것을 이미 하나의 확정된 성질로 갖고 있다는 점은 짚어 둘 만합니다
— 그 말은 이 dedup이 `Source` 자체의 성질에 기댈 수 없고, 슈거의 쓰기 호출 안에서 **직접** 비교해서
`:Set` 호출 여부를 결정해야 한다는 뜻이라, "슈거만 아는 예외"가 하나 생기는 셈입니다. 이게 비교적
자연스럽긴 해도 완전히 무마찰은 아닙니다. 반대로 "아무 dedup도 없음"도 놀랍지 않은 선택지입니다 — 어차피
루프 안전에는 필요 없으니, 순수 슈거라는 프레이밍을 지키려면 아무것도 안 하는 쪽이 더 단순합니다. 가장
놀라운 건 "타이핑/포커스에 관한 무언가"입니다. `TextBox`가 편집 중일 때 되받아쓰기를 막는 건 실용적으로
유용할 수 있지만, 그건 값 동등성 문제가 아니라 완전히 다른 범주의 정책(포커스 상태를 관찰하고 조건부로
쓰기를 유예하는 것)이라서, "이름과 모양은 확정, dedup 세부만 미정"이라는 지금 단계의 프레이밍에 비해
스코프가 훨씬 큽니다. 그런 기능이 필요하다면 그건 이 슈거의 dedup 옵션이 아니라 완전히 별도로 설계돼야
할 것 같고, 지금 그 논의 없이 이 슈거 안에 슬쩍 들어와 있다면 저는 그게 제일 놀랍고 제일 우려스럽습니다.

## (5) 한 줄 판정

제 1순위는 `Out`입니다 — 방향을 이름만 보고 즉시 알 수 있고(양방향이라는 오해가 거의 없고), Fusion에서
같은 역할을 하던 이름과 의미가 정확히 대응해서(모양은 다르지만 뜻은 같아서) 전이 학습이 됩니다; 구조가
해시 키가 아니라 배열부 값이라는 차이는 한 번 코드를 써 보면 바로 풀리는 얕은 마찰이라 감수할 만합니다.
2순위는 `Writeback`입니다 — 어떤 사전 지식도 없이 이름만 읽어도 "바뀐 값을 다시 써 넣는다"는 동작이
그대로 드러나서 오해의 여지가 가장 적지만, 기존 프레임워크에 기댈 관용어가 아니라 처음 보는 사람에게는
`Out`보다 즉각적인 인식 속도가 떨어집니다. `Bind`는 제가 가장 권하지 않는 후보입니다 — 그 자리에서
"아래 프로퍼티 줄이 필요 없어지는 게 아닌가"라는, 실제 동작과 반대되는 첫인상을 준다는 게 다른 후보들과
달리 단순한 낯섦이 아니라 **틀린 멘탈 모델**을 심는 종류의 문제이기 때문입니다.

---

# B. 내부자

# "엔진 변경 → Source로 되쓰기" 슈거 이름·타입·동작 조사 (판단용 자료, 결정은 사용자 몫)

## 1. 이름

코퍼스의 케이싱 규칙(`architecture.md` "코드 스타일 — 네이밍 케이싱" 절, 2026-09-15 정정판)은 대문자 시작을 "앱 코드가 값을 만들거나
감싸는 함수(생성자·팩토리·슈거)"에 준다. 그 절이 직접 대문자 부류로 꼽는 목록에 `OnCreated`/`OnRendered`/`OnDestroyed`가 이미
들어 있다 — `Fallback`/`Traceback`/`Debounce`/`Throttle`/`Claim`과 나란히. 그리고 `base/lifecycle-hooks-plan.md`의 "이름
컨벤션" 절이 이 계열의 근거를 명시적으로 적어뒀다: *"`On` 접두 자체는 이미 선례가 있음 — `base/onchange-plan.md`의
`OnChange(name, fn)`(`GetPropertyChangedSignal` 바인딩)"*, 그리고 *"둘 다 배열 파트에 놓이는 값을 만드는 팩토리"*. 즉 이
코퍼스에서 `On*`는 "숫자 키(배열부) 자리에 놓는, 값(디스크립터/PreRef/PostRef/EffectHandle)을 만드는 팩토리"를 가리키는
확립된 관용구다 — 가장 최근에는 2026-09-21 세션(`session/2026-09-21-02-docs-review-batch.md` 흐름 5번)이 Tween 완료
콜백 이름을 정할 때 이 규칙을 실제 판정 근거로 썼다: 내부자 검토자가 *"`On*`는 이 코퍼스에서 숫자 키 자리 팩토리 관용구"*라고
지적했고, Tween 콜백(`Started`/`Completed`/`Cancelled`)은 옵션 테이블의 **해시 키**(`Tween{ Started = fn }`)라서 `On*`를
안 붙이기로 확정됐다 — 반대로 읽으면, **숫자 키 자리에 놓이는 팩토리라면 `On*`가 코퍼스 관례에 맞는다**는 뜻이다.
사용자가 준 스케치의 `Bind("Text", textSrc)`는 정확히 그 자리(배열부, `Tag`/`OnChange`/생명주기 훅과 같은 위치)에 놓이고
`q.OnChange` 디스크립터를 반환하는 팩토리이므로, 이 축만 보면 `On*` 계열이 자연스러운 후보다.

다만 후보 이름 각각의 충돌을 실측하면:

- **`Bind`**: `quad-base/src`에서 `Bind`/`bind`류 매치가 110건, `quad-roblox/src`에서 13건 나온다. 핵심은 양이 아니라
  이게 **이미 핵심 생명주기 어휘**라는 것 — `Backend.bindLifetime`/`unbindLifetime`은 `base/lifecycle-pattern.md`가
  확정한, Ref/Effect/Observer/Slot/Bookkeeping 전체가 쓰는 "값의 GC 수명을 한 Instance에 묶는다"는 뜻의 핵심 계약 함수이고
  (`quad-base/src/LifetimeHandle.luau`가 정의, `Effect.luau`/`Observer.luau`/`Bookkeeping.luau`/`Slot/*.luau`/`Ref/init.luau`/
  `Dispatch/*.luau`가 호출), `quad-roblox/src/LifetimeHandle.luau`엔 실제로 `local BindData = Relate()`라는 변수까지 있다
  (홀드/커넥션을 값別로 저장하는 테이블). 즉 "Bind"라는 어휘는 **이미 "이 값을 이 Instance의 수명에 묶는다"는 뜻으로
  코드 전역에 박혀 있다** — 새 슈거가 `q.Bind(name, src)`로 "프로퍼티를 Source에 되쓴다"는 전혀 다른 뜻을 그 옆에 놓으면,
  `question.md` 1번이 이미 경계하는 패턴("다른 뜻으로 이미 쓰이는 단어" — v1 `register`→`State` 리네임의 교훈, 그리고
  `Tag`/`Brand` 충돌 선례)과 같은 종류의 충돌이 난다. 문서 쪽에서도 "바인딩"이 이미 여러 뜻(프로퍼티 대입, 이벤트 연결,
  `const` 변수 바인딩, Ref/Effect 생명주기 결합)으로 느슨하게 쓰이고 있어(`docs/`에 97개 파일이 "바인딩"을 언급), 정확한
  이름을 중시하는 이 코퍼스 성격상 `Bind`는 **가장 충돌이 큰 후보**로 보인다.
- **`Out`**: 코드베이스에 의미 있는 충돌은 `FieldOut<T>`(Modifier `Peek`/setter의 "저장된 그대로" 반환 타입, 완전히 다른
  개념 — "이 필드에 지금 뭐가 들어있나") 정도이고, 함수 이름·네임스페이스 충돌은 없다. `FieldOut`과 나란히 두면 오히려
  "Out"이 "무언가를 밖으로 꺼낸다"는 일관된 어감을 공유해서 부정적 충돌은 약하다.
- **`Sync`**: `quad-base`에 `EpochMap:Sync(from)`이라는 내부 의존성 등록 메소드(`state-epoch-plan.md`류 계약, "write only, no
  read, no return")가 이미 있고 `Source.luau`/`Effect.luau`/`State.luau`가 이 이름을 쓴다. 사용자 표면은 아니지만(`EpochMap`은
  내부 구현), 같은 코퍼스 안에서 "Sync"가 이미 "의존 관계를 등록한다"는 별개 뜻으로 쓰이고 있어 약한 충돌.
- **`Into`**: `<Class>` 계열 타입 네이밍에 이미 `Into<Frame>`/`Into<Camera>`류(컴포넌트 경계 인터페이스, `AsFrame`/`AsCamera`
  메소드가 구현) 패턴이 쓰이고 있다. 함수 이름 `Into`가 이 타입 이름 패턴과 동음이의로 헷갈릴 수 있다.
- **`Feed`/`Writeback`/`OnChangeSet`**: 코드베이스 전수 검색에 의미 있는 충돌 없음(`Writeback`은 매치 0건).

## 2. 타입

`quad-types/src/init.luau`에 `State<T>`와 `Source<T>`가 명확히 위계가 있다 — `Source<T> = State<T> & { read Revision:
number, Set: (self, T) -> Source<T>, Emit: (self) -> Source<T> }`(219행 부근). 즉 `Source<T>`는 `State<T>`를 구조적으로
**포함하며 `Set`/`Emit`/`Revision`을 추가로 요구**하는 상위집합이다. `:Compute(...)` 같은 파생 연산의 반환 타입은
`State<U>`(219행 이전 `Compute: <U>(...) -> State<U>`)로, `Set`/`Emit`이 없다. 그래서 슈거의 시그니처를 그냥
`<K>(name: K & keyof<PropTypesRead>, src: Source<index<PropTypesRead, K>>) -> OnChangeDescriptor<K>`로 선언하면(제네릭
`K`를 `OnChangeFn`과 똑같은 패턴으로), `:Compute()`가 만든 `State`를 넘기는 자리는 구조적으로 `Set`/`Emit`이 없어
`--!strict`가 width subtyping으로 자연스럽게 거부한다 — 별도의 `SourceMarker`/브랜드 태그가 없어도 이 거부가 성립한다
(참고로 `SourceMarker`라는 타입은 코퍼스에 없다 — 마커 계열은 `StateMarker<T>`뿐이고, 이건 D의 props/children 테이블
"공변 입력 자리"의 solver 문제를 우회하려고 만든 것이지 함수 인자 타입엔 필요 없다, `typing-limits.md` 8.11).

타입 표면 자체도 이미 존재한다 — `quad-roblox/src/Declaration/init.luau` 2088~2089행:
`export type OnChangeDescriptor<K> = { Name: K, Callback: (index<PropTypesRead, K>) -> () }`,
`export type OnChangeFn = <K>(name: K & keyof<PropTypesRead>, fn: (index<PropTypesRead, K>) -> ()) -> OnChangeDescriptor<K>`.
`PropTypesRead`는 클래스별로 생성되는 타입이 아니라 **모든 클래스 프로퍼티를 한데 합친 전역 단일 타입**(1826행부터, "쓰기
표면 + ReadOnly 프로퍼티")이므로, 새 슈거도 클래스별 생성 없이 **손으로 쓴 함수 하나**로 같은 패턴을 그대로 재사용할 수
있다 — gen-d 생성기를 건드릴 필요가 없다.

## 3. Dedup("diff까지 가능")

`quad-base/src/Source.luau`의 `Set`은 `H-68` 계약대로 **동일값이어도 항상 Revision을 올리고 emit한다**(주석 원문: *"`Source:Set(v)`는
동일값이어도 항상 갱신하고 emit한다"*, 79행 부근 `bumpAndEmit`). 반면 엔진 프로퍼티 대입은 동일값 재대입에서 `GetPropertyChangedSignal`을
쏘지 않는다(`audit/studio-docs-2026-09-10.md` A절 실측 — quad 층은 엔진 0회/mock 1회로 갈림).

이 두 사실을 스케치의 초기 바인딩 순서와 겹쳐보면 실제 함정이 보인다. `base/onchange-plan.md`의 확정 계약은 "배열부가
해시부보다 먼저 돈다 → Connect가 같은 props의 프로퍼티 대입보다 항상 먼저 산다"이고, `fn`이 발화하는 건 연결 시점의
합성 초기 호출이 아니라 **뒤이은 해시부 대입이 실제로 엔진 시그널을 쏴서**다. 그래서 `TextBox { Text = textSrc, Bind("Text",
textSrc) }`의 실제 처리 순서는: (1) 배열부에서 `Bind`가 만든 `OnChange` 디스크립터가 먼저 `GetPropertyChangedSignal("Text")`에
연결되고, (2) 그다음 해시부에서 `Text = textSrc`(Property 핸들러, StoreBind)가 `textSrc:Get()`(예: `"Hello"`)을 읽어
`inst.Text`에 대입한다. 이 대입이 엔진 기본값과 다르면 시그널이 쏘여 이미 연결된 콜백이 `v = "Hello"`로 실행된다. 이때
콜백이 무조건 `src:Set(v)`를 하면, `textSrc`가 **자기가 방금 흘려보낸 것과 똑같은 값**을 되받아 또 `Set`을 부르게 되고,
`H-68`대로 `Source:Set`은 동일값이라도 항상 Revision을 올리고 emit하므로 — **초기 바인딩 한 번마다 그 Source를 구독하는
모든 Observer/Effect/Compute가 아무 의미 없는 추가 재실행을 한 번씩 더 타는** 결과가 난다(엔진 층은 이후 루프를 안
쏘지만, quad 층의 `Set`은 값 비교 없이 항상 쏜다는 게 함정의 원인).

옵션 (b) `if v ~= src:Get() then src:Set(v) end`는 정확히 이 상황을 막는다 — 콜백이 실행되는 시점에 `src`는 아직
자기가 흘려보낸 그 값을 들고 있으므로(`v == src:Get()`), 되쓰기가 스킵되고 echo `Set`/`Emit`이 아예 안 일어난다. 진짜
"바깥(엔진 UI 조작·다른 코드의 직접 대입)에서 값이 달라진" 경우에만 `v ~= src:Get()`이 성립해 `Set`이 실행된다 — 이게
"diff까지 가능"이 실질적으로 의미하는 바다. `src:Get()`은 `Source.luau`의 `Impl.Get`이 `self._value`를 그냥 읽는
단순 필드 읽기라(58행), quad엔 Vue/Solid류의 앰비언트 의존성 추적이 없고(`:Compute`/`:Observer`/`:Effect`는 전부
명시적 `...deps` 인자로 의존을 받는 모델, `State.luau`) OnChange 콜백처럼 리액티브 컨텍스트 밖에서 `Get()`을 부르는 데
아무 위험이 없다 — Peek/Get 구분은 애초에 State/Source엔 없고(그건 Modifier/Store의 `:Peek(key)` 얘기), 여기선
해당 사항이 없다.

옵션 (c) — "OnChange의 첫 콜백이 프로퍼티의 현재값을 Source에 써넣는가": 위에서 정리한 순서(연결이 먼저, 발화는
그 뒤 실제 대입이 트리거) 때문에, `Bind`만 단독으로(`Text = ...` 없이) 놓이면 초기 발화 자체가 없다(아무도 아직
`Text`를 대입하지 않았으므로 엔진 시그널이 안 남). 반대로 위 스케치처럼 `in`/`out`을 같이 놓으면, `in` 쪽의 초기
대입이 `out` 쪽 콜백을 한 번 발화시키는 게 불가피하다 — 이건 "바람직한가"의 문제라기보다, dedup이 있으면 그 한 번이
무해(스킵됨)하고 dedup이 없으면 그 한 번이 유해(echo emit)하다는 차이로 귀결된다.

## 4. 구현 스케치 (사실만)

`OnChange`는 quad-roblox 전용이고(`Handlers/OnChange.luau` + `Declaration/init.luau`의 타입), 새 슈거의 반환값이
"OnChange 디스크립터"인 이상 이 슈거도 **quad-roblox**에 산다 — `quad-base`가 아니다(quad-roblox가 quad-base를
require하지 않는 경계, `onchange-plan.md` "패키지 경계" 절과 대칭). 새 슈거는 내부적으로 기존 `OnChange(name, fn)`을
그대로 호출해 디스크립터를 만들면 되므로(`fn`이 `if v ~= src:Get() then src:Set(v) end`인 클로저), **`Handlers/OnChange.luau`는
전혀 고칠 필요가 없다** — 그 핸들러는 `type(k) == "number"` ∧ 디스크립터 브랜드(모듈 로컬 weak-key 집합)만 보고 동작하고,
그 디스크립터의 `Callback`이 어떻게 만들어졌는지는 모른다. 새 브랜드·새 핸들러·`Dispatch`쪽 변경 전부 불필요 — 순수하게
"기존 `OnChange`를 감싸는 함수 하나 + 타입 시그니처 하나"로 끝나는 진짜 순수 슈거다.

## 결론 및 권고

이름 후보 중 `Bind`는 "숫자 키 자리 팩토리는 `On*`" 관례 자체엔 맞을 수 있는 위치(배열부 팩토리)에 놓이지만, **이름 그 자체가
이미 핵심 생명주기 어휘(`bindLifetime`/`unbindLifetime`/`BindData`, 값의 GC 수명을 Instance에 묶는다는 전혀 다른 뜻)와
정면으로 충돌**한다 — 이건 이 코퍼스가 `question.md` 1번에서 이미 실패 사례로 못박은 "다른 뜻으로 이미 쓰이는 단어"
패턴(`Tag`/`Brand` 충돌, v1 `register`→`State`)과 같은 종류이고, 게다가 `bindLifetime`은 사용자 표면이 아니라
백엔드-주입 계약 표면이라 더 위험하다(사용자가 백엔드를 직접 다룰 때 두 "Bind"가 한 API 문서 옆에 나란히 나열될 수
있음). 반면 `Out`은 실질적 충돌이 없고(`FieldOut`과는 개념적으로도 어울리는 방향), `On*` 계열로 가고 싶다면
`onchange-plan.md`가 직접 쓴 표현대로 "배열부에 놓이는 값을 만드는 팩토리" 관례에 맞으니 `OnChange`와 짝을 이루는
이름(`OnChangeSet`류)도 관례상 근거는 있으나, `OnChange`와 어근이 겹쳐 "이것도 그냥 OnChange의 변형 설정 옵션"으로
오독될 위험이 있다는 점은 `Bind`와는 다른 축의 약한 리스크로 짚어둔다. 타입 쪽은 실측상 완전히 깨끗하다 —
`Source<T>`가 `State<T>`의 상위집합(추가 `Set`/`Emit`)이라 `Source<...>`를 인자 타입으로 못박기만 해도 `:Compute()`
결과(`State<U>`)는 strict에서 자연히 거부되고, 이미 있는 `OnChangeFn`/`PropTypesRead` 전역 타입을 그대로 재사용할 수
있어 새 생성기 작업이 없다. 동작 쪽은 dedup을 넣지 않으면 in/out을 한 Source에 같이 걸 때마다 초기 바인딩에서 불필요한
echo emit이 한 번씩 나는 게 거의 확실하므로(`H-68`의 "Source:Set은 항상 emit" 계약과 배열→해시 순서 계약이 맞물려
생기는 구조적 결과), `if v ~= src:Get() then src:Set(v) end` 형태의 dedup을 슈거 안에 넣는 편이 "그냥 OnChange를
얇게 감싼 것"보다 실질적 이득이 있다.
