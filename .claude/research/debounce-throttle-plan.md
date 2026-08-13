# Debounce / Throttle — 시간 기반 전파 게이트

**상태**: research — **[2026-08-14 신설]** 사용자 요청("`Blocker`와 유사하게
Debounce/Throttle를 만들어야 한다")으로 신설. 여기 적힌 건 **에이전트가
먼저 전부 정의해본 초안**이고, 확정된 건 하나도 없음 — 사용자가 이 문서를
읽고 판단하는 게 다음 단계. 열린 결정은 맨 아래 "사용자 판단 대기" 절에
번호로 모아뒀음.

> **[2026-08-14 1차 리뷰 반영]** 사용자가 스로틀의 trailing 동작을 짚어준
> 뒤 세 가지가 바뀜: (1) **Q5(패키지 경계) 해소** — quad-base + 엔진별
> 태스크 배선으로 확정(6절), (2) **초안 의사코드의 실제 버그 수정** —
> lodash식 `MaxTime` 공식이 trailing 통과 직후 이중 발화하는 구멍이
> 있었고, "`Reset` 한 비트" 정식화로 대체(1-1/5-3/7절), (3) **3절 발견의
> 범위 축소** — 파생 State 위 퇴화는 `Debounce`만 겪고 `Throttle`은 거의
> 면역임이 드러남.
>
> **[2026-08-14 2차 리뷰 반영]** 사용자가 주입 op의 이름/시그니처를 직접
> 지정: **`setTimeout(func, delay) -> Timeout` / `clearTimeout(handle)`**
> (6절). 같이 확정/정정된 것 — (1) **`os.clock()`은 주입 대상이 아님**
> (Luau 표준 라이브러리이고, Lua 5.x와 달리 일관되게 고정밀 값 —
> 단 **절대 시각이 아니라 차이 계산 전용**, 이 설계는 남은 시간만 재므로
> 무관), 그래서 초안이 "시계가 필요하면 세 번째 op 추가"라고 한 부분은 무효,
> (2) **취소를 제공 안 하는 엔진도 대응 가능**(래핑 + 유효 플래그) —
> `clearTimeout`은 백엔드에 요구해도 되는 계약, (3) `Timeout` 타입은
> **`{ __type_timeout: true, _native: any }`로 확정**(에이전트가 권한
> `any`는 사용자 반론으로 철회 — 6절에 뒤집힌 이유 기록), (4) `MaxTime`을
> 타이머 2개가 아니라 `min()` 하나로 줄이는 구현(6-1절).
>
> **[2026-08-14 3차 리뷰 반영]** 사용자가 **"emit은 항상 재전파된다"**고
> 지적 — 이 문서가 두 라운드 동안 "가장 중요한 발견"으로 들고 있던 3절이
> **전제부터 틀렸던 것으로 드러나 통째로 철회됨**(파생 State 위 퇴화 없음,
> "`Source`에 가깝게" 규칙 폐기, Q6 소멸). 대신 그 확인 과정에서
> **`base/source-state-plan.md`의 무효화 dedup 문장이 확정된 `Observer`
> 계약과 모순**되고 `base/architecture.md`와도 어긋난다는 게 드러나,
> base 정정 항목(Q10)이 새로 생김.

`research/operator-sugar-plan.md`가 "`Operator.*` 카탈로그 밖의 별도
설계 질문"으로 분리해뒀던 항목이 이 문서의 출발점(그 문서 "열린 질문 —
포함 범위" 절의 Debounce/Throttle 항목). `research/additional-primitives-plan.md`가
2026-08-06 조사에서 "Fusion/Vide/v1 어디에도 없으니 quad도 굳이 안
만들어도 된다는 정황"으로 적어둔 판단은 **이 요청으로 뒤집힘**(그
문서에도 포인터를 남겨둠).

---

## 0. 세 줄 요약

1. **Debounce/Throttle은 `Blocker`와 같은 자리(무효화 전파 게이트)에
   놓이고, 다른 건 "언제 열리는가"뿐** — `Blocker`는 사용자가
   `:Off()`로 열고, 이쪽은 타이머가 연다. 새 전파 메커니즘이 아니라
   **`Blocker`가 이미 쓰는 게이트 노드의 릴리스 트리거 교체**. 그리고
   **Debounce와 Throttle의 차이는 "신호가 창 타이머를 리셋하는가" 한
   비트뿐**(1-1절) — 공개 이름은 둘, 구현은 하나.
2. **quad의 lazy 전파(push-invalidate/pull-recompute) 위에서도 laziness가
   깨지지 않음** — 게이트는 무효화 채널만 만지고 `:Get()`을 절대 호출하지
   않기 때문. **[2026-08-14 3차 리뷰]** 여기 있던 "파생 State 위에 얹으면
   퇴화한다"는 발견은 **전제가 틀려 철회됨**(3절) — emit은 항상 재전파되므로
   게이트는 중간에 뭐가 끼든 매 변경마다 신호를 받음. 대신 그 과정에서
   **`base/source-state-plan.md`의 무효화 dedup 문장이 확정된 `Observer`
   계약과 모순된다는 게 드러나** base 정정 항목이 생김(Q10).
3. **타이머는 엔진 종속이지만 부기 알고리즘은 아님** — `Tag`/`Attribute`가
   14차 세션에 밟은 길(알고리즘은 quad-base, 엔진에 손대는 마지막 한 줄만
   주입)을 그대로 따라 **주입 op 2개**(`setTimeout`/`clearTimeout`)만
   추가. `Tween`처럼 통째로 quad-roblox에 두는 건 근거가 다름.
   **[2026-08-14 사용자 확정]** 이 방향으로 확정 — 순수 Luau엔 `task`
   자체가 없어 base가 동작하는 기본 스케줄러를 제공할 수조차 없고,
   `Throttle`도 trailing 때문에 이 배선이 똑같이 필요함(6절). 반대로
   **`os.clock()`은 Luau 표준 라이브러리라 주입 대상이 아님** — 주입이
   필요한 건 "미래에 실행시키는 능력"뿐이고, "얼마나 지났나"는 언어가
   이미 줌(절대 시각이 아니라 **차이 계산 전용**, 6절 주의).

---

## 1. 왜 `Blocker`로는 안 되는가 (그리고 왜 그 옆자리인가)

`base/blocker-plan.md`의 "메커니즘 (확정)"이 정의하는 게이티드 State는
정확히 이렇게 동작함:

- 상류가 emit(무효화)하면 게이티드 노드로 전파를 시도
- 블록 중이면 전파 안 하고 `HasBlockedEmit = true`만 세팅
- 열릴 때 `HasBlockedEmit`이 true면 **정확히 1회** 전파하고 플래그 리셋

이건 debounce/throttle이 필요로 하는 것과 **글자 그대로 같음**. 차이는 딱
하나 — 여는 주체:

| | 닫는 계기 | 여는 계기 | 창의 길이 |
|---|---|---|---|
| `Blocker` | 사용자 `:On()` | 사용자 `:Off()` | 사용자가 정함(코드 구간) |
| `Debounce` | 상류 신호 도착 | 신호가 `Time`동안 없으면 | 조용해질 때까지(가변) |
| `Throttle` | 통과 직후 | `Time` 경과 | 고정 |

**그래서 "중복 프리미티브 아니냐"는 반문에 대한 답**: `Blocker`는 "내가
코드로 구간을 안다"(여러 `:Set()`을 한 트랜잭션으로 묶음), Debounce/Throttle은
"구간을 코드가 모른다"(사용자 입력·고빈도 신호처럼 언제 끝날지 모름).
`Blocker`가 lexical `Batch(fn)`을 기각하면서 얻은 것이 정확히 "콜스택이
아니라 값으로 표현"인데(`archive/batch-rejected.md`), 시간 기반 게이트는
값으로도 표현할 수 없는 나머지 절반임 — 겹치는 게 아니라 상보적.

> **참고로 겹치는 지점이 딱 하나 있음**: `Debounce{Time = 0}`은 사실상
> "이번 스텝의 변경을 자동으로 합쳐서 다음 스텝에 한 번만 전파"라
> `Blocker`를 손으로 여닫는 것의 자동판 근사가 됨. 이게 `Blocker`를
> 대체하지는 않음(`Blocker`는 "정확히 이 코드 구간"이라는 결정성을 주고,
> `Time = 0`은 스케줄러 타이밍에 의존) — 다만 문서에서 두 도구를 비교
> 설명할 때 좋은 대조 사례.

### 1-1. 정확히 어떤 동작인가 — 두 도구의 차이는 "한 비트"뿐 (2026-08-14 후속, 초안 정정)

**[초안 정정]** 이 절은 사용자가 스로틀의 trailing 동작("1초 스로틀에서
0.0과 0.1에 입력하면, 1.0에 0.1의 값이 다시 적용되어야 한다")을 짚어준
뒤 검증하다가 **초안 의사코드의 실제 버그를 발견해** 다시 쓴 것. 초안은
lodash식 `MaxTime`(maxWait) 공식을 그대로 옮겼는데, 그 형태는 trailing
통과 직후 타이머를 전부 회수해버려서 **바로 뒤에 온 신호가 "창 밖"으로
판정돼 또 즉시 발화**함(1초 안에 두 번 나감). 아래 정식화는 그 구멍이
구조적으로 없음.

**디바운스** — "조용해질 때까지 기다렸다 한 번". 신호가 올 때마다 타이머를
**처음부터 다시** 시작하고, `Time`동안 아무 신호도 없을 때 1회 발화.

```
Debounce{Time = 1}
0.0  신호 ──┐ 창 마감을 1.0으로
0.1  신호 ──┤ 취소하고 1.1로
0.3  신호 ──┤ 취소하고 1.3으로
     (조용)
1.3        ●  1회 발화 (0.3 시점의 값)
```

**스로틀** — "창 하나당 최대 한 번". 창 길이가 **고정**이라 신호가 창을
밀지 못함. 첫 신호는 즉시 통과(leading), 창 안에 들어온 신호는 눌러뒀다가
창이 끝날 때 최신값으로 1회 통과(trailing).

```
Throttle{Time = 1}
0.0  신호 ──●  즉시 통과(leading), 창 마감 1.0 고정
0.1  신호 ──┘  눌러둠(pending), 창은 그대로 1.0
1.0        ●  0.1 시점의 최신값으로 통과(trailing) — 사용자가 짚은 그 동작
              통과했으니 창을 다시 엶(마감 2.0)
1.05 신호 ──┘  아직 창 안 → 눌러둠 (초안 버그였던 이중 발화가 여기서 막힘)
2.0        ●  통과
```

| | 버스트 중간 | 버스트 끝 | 신호가 끊이지 않을 때 |
|---|---|---|---|
| Debounce | 아무것도 안 함 | 1회 | **영원히 발화 안 함** |
| Throttle | `Time`마다 1회 | 마지막 1회 | `Time`마다 계속 |

"신호가 끊이지 않으면 영원히 안 함"은 버그가 아니라 **디바운스의 정의
그 자체** — lodash에 `maxWait`가 있는 이유가 정확히 이것(아무리 계속
와도 최대 이만큼마다는 한 번 내보내라). 그래서 `MaxTime`은 이 새
정식화에서 **디바운스 전용 안전장치**로 역할이 좁아짐(스로틀은 원래
주기적으로 발화하므로 필요 없음).

**⭐ 결론 — 두 도구의 차이는 딱 한 비트**:

> **신호가 창 타이머를 리셋하는가.** 디바운스는 리셋함(창이 신호를 따라
> 밀림), 스로틀은 리셋 안 함(창 길이 고정).

leading/trailing/통과 후 창 재개방은 **완전히 동일**. 그래서 공용 게이트
하나에 `Reset` 불리언 하나만 있으면 둘 다 나옴(7절 의사코드). lodash처럼
`maxWait`로 스로틀을 흉내 낼 필요가 없고, 그 과정에서 생기던 이중 발화
구멍도 없어짐.

### 공개 `Blocker` API 위에 얹어서 만들 수는 없음

"`Debounce`를 내부적으로 `Blocker` 하나 만들어 타이머로 `:On()`/`:Off()`
치는 걸로 구현하면 안 되나?"는 자연스러운 질문인데, **안 됨** — 공개
`Blocker` API엔 "상류 신호가 지금 도착했다"를 알려주는 통지가 없음.
타이머를 (재)시작하려면 그 순간을 알아야 하는데 알 방법이 없어서, 결국
게이트 노드 내부 훅이 필요함.

**그래서 권하는 구현 방향**: `Blocker`의 게이티드 노드를 내부 공용
`Gate` 노드로 한 겹 일반화하고(= "상류 신호를 받되 전파 여부를 정책이
결정하는 State 노드"), `Blocker`/`Debounce`/`Throttle`이 그 위의 서로 다른
정책으로 얹히는 형태. 새 노드 종류를 하나 더 만드는 게 아니라, 이미 하나
있는 걸 두 번째 사용처가 생겼으니 이름 붙여 꺼내는 것뿐.

---

## 2. laziness는 안 깨진다 (확인)

quad의 전파 모델은 `base/source-state-plan.md`의 "전파 모델 확정" 절에서
확정된 push-invalidate(신호만) / pull-recompute(`:Get()`
시점)이고, 전역 원칙은 "관측해야 실체화된다"임. 시간 기반 게이트가 이걸
깨는지 확인해봤는데 — **안 깨짐**:

- 게이트는 **무효화 신호만** 받고, 자기도 **무효화 신호만** 내려보냄.
  `:Get()`을 스스로 호출하는 지점이 한 군데도 없음.
- 타이머 콜백이 하는 일은 "invalid 세팅 + 아래로 전파" 뿐. 실제 계산은
  여전히 소비자가 `:Get()`할 때만 일어남.
- 즉 게이트는 **eager 노드가 아님**. Fusion의 `timeliness="eager"`류 장치를
  들여올 필요 없음(그건 이미 기각된 방향).

**단, 이 성질을 깨는 변형이 하나 있으니 넣지 말 것**: "값이 실제로
바뀌었을 때만 통과"(distinct-until-changed)를 게이트에 섞으면 게이트가
`:Get()`을 호출해야 하고, 그 순간 상류 체인 전체가 eager가 됨. 필요하면
그건 별도 콤비네이터로, 그리고 그 대가를 명시적으로 문서화한 채로 다룰 것
(이 문서 범위 밖).

---

## 3. ~~파생 State 위에 얹으면 debounce가 throttle로 퇴화한다~~ → **철회됨, 전제가 틀렸음 (2026-08-14 3차 리뷰)**

> **이 절은 이 문서에서 "가장 중요한 발견"으로 두 라운드를 버텼지만,
> 사용자 지적으로 전제가 무너져 통째로 철회됨.** 원래 주장: 무효화
> dedup 때문에 게이트가 버스트 중 두 번째 이후 신호를 못 받아,
> `Debounce`가 "마지막 변경 후 T초"가 아니라 "첫 변경 후 T초"로
> 조용히 퇴화한다 — 그래서 `Source`에 가깝게 걸어야 한다는 규칙과
> 열린 질문 Q6이 여기서 나왔었음. **셋 다 무효.** 원문은
> `session/2026-08-14-08-debounce-throttle-backlog.md`에 보존.

### 무엇이 전제였고 왜 무너졌는가

전제는 `base/source-state-plan.md` "전파 모델 확정" 절(2026-08-14 세 번째
세션의 3단계 분할 전에는 `bind-system-plan.md`)의 이 한 줄이었음:

> 신호를 받은 State는 자기 `invalid` 플래그만 세우고, **이미 `invalid`였다면
> 그 아래로 더 전파하지 않는다** — 다이아몬드 의존성에서 중복 워크를 막는 장치

사용자 지적: **"emit은 항상 재전파된다. 저 동작은 정확히 `Blocker`가
하는 것."** 확인해보니 맞고, 저 문장은 **이전 세션의 과잉 일반화**로
보임. 근거 셋:

1. **다이아몬드 근거가 요구하는 범위를 넘어섬.** 다이아몬드 문제는
   `a → b`, `a → c`, `(b,c) → d`에서 **한 번의 변경**이 여러 경로로
   `d`에 도달하는 것 — 이걸 막으려면 **그 전파 파동(wave) 안에서만**
   중복을 접으면 됨. 그런데 저 문장은 `invalid`를 **시간에 걸쳐 유지되는
   상태**로 써서("이미 `invalid`였다면"), 누가 `:Get()`할 때까지 **이후의
   모든 변경**까지 삼켜버림. 파동 내 dedup과 시간축 dedup은 전혀 다른
   범위인데 한 문장으로 뭉뚱그려짐.
2. **애초에 다이아몬드 중복 *재계산*은 이 장치가 푸는 게 아님.**
   `base/architecture.md`가 같은 주제를 이렇게 서술함 — "전파는
   push-invalidate(신호만)/pull-recompute(`Get()` 시점) — **Fusion식
   eager 노드 없이도 다이아몬드 의존성 중복 재계산 문제가 풀림**". 즉
   중복 평가를 막는 건 **pull-recompute 그 자체**임(값은 `:Get()` 때
   한 번만 계산됨). `invalid` 플래그 dedup이 절약하는 건 재계산이 아니라
   **플래그 세팅 트리 순회 비용**뿐 — 정확성 장치가 아니라 최적화인데,
   `source-state-plan.md`는 이걸 다이아몬드의 해결책으로 승격시켜 서술함.
   **base 안에서 두 문서가 같은 문제의 해결 주체를 다르게 지목하고 있음.**
3. **⭐ 확정된 `Observer` 계약과 정면 충돌.** 같은 파일이
   "`state:Observer(fn)`" 절에서 **`fn`이 `:Get()`을 부르지 않아도 되는
   것을 명시적으로 허용**함 — "재계산이 진짜 필요한지가 다른 `:With`한
   값에 따라 갈리는 경우가 있어서 (…) `Get()` 호출 여부를 작성자가 직접
   결정하게 열어둔 것". 그런데 dedup 문장을 액면대로 적용하면:

   ```
   source:Set(1) → state invalid → Observer 발화 → fn이 :Get() 안 함
                                                  → state는 invalid로 남음
   source:Set(2) → state 이미 invalid → 전파 안 함 → Observer 안 울림 ❌
   source:Set(3) → 마찬가지 ❌ ... 영원히
   ```

   즉 **`:Get()`을 안 하는 Observer는 딱 한 번 울고 영구히 침묵함.**
   문서가 정당한 사용법으로 허용한 것이 문서의 다른 문장 때문에 조용히
   깨지는 것이므로, 취향 문제가 아니라 **base 내부의 실제 모순**임.

사용자의 "저건 `Blocker`가 하는 것" 지적도 정확함 — `HasBlockedEmit`이
바로 "블록 중엔 여러 emit을 하나로 접어뒀다가 열릴 때 1회"이고,
`Blocker`는 그걸 **명시적으로 켜고 끄는 opt-in 게이트**로 제공함. 같은
동작을 모든 State 노드에 암묵적으로 심어두면 `Blocker`의 존재 의의가
절반 사라짐.

### 그래서 정정 후 그림 (권고)

- **emit(무효화 신호)은 구독자에게 항상 전파된다.** State가 이미
  `invalid`인지는 전파 여부와 무관.
- 다이아몬드 중복 *재계산*은 **pull-recompute가 이미 구조적으로**
  막음(`architecture.md`의 서술이 맞음) — 별도 장치 불필요.
- 한 번의 변경이 여러 경로로 같은 노드에 닿는 **파동 내 중복 순회**가
  실측에서 문제가 되면, 그때 **파동 단위**(방문 집합/에포크 카운터)로
  접으면 됨 — 이건 의미론에 안 보이는 **순수 구현 최적화**이고, 지금처럼
  영속 플래그로 하면 안 됨.

### 이 문서에 미치는 영향 — 세 개가 사라짐

1. **"파생 State 위에서 퇴화한다"는 함정 자체가 없음.** 게이트는 중간에
   무엇이 끼어 있든 매 변경마다 신호를 받으므로 `Debounce`가 어디서든
   정상 동작함.
2. **"`Source`에 가깝게 걸어라"는 규칙 불필요.** `Blocker`의 "파이프라인
   끝에 걸어라"와의 "정확한 거울상"이라는 서술도 같이 폐기 — 예쁜
   대칭이었지만 틀린 전제 위에 있었음.
3. **열린 질문 Q6 소멸**(문서 권고 / 경고 / 에러 중 택일할 대상이 없음).

2차 리뷰에서 "이건 `Debounce`만 겪고 `Throttle`은 거의 면역"이라고
범위를 좁혔던 정정도 같이 무의미해짐 — 애초에 둘 다 안 겪음.

### 대신 생긴 것 — base 정정 **완료** (2026-08-14, 사용자 확정)

사용자가 모델을 확정해줌:

> **emit은 항상 전파함. `Blocker`나 emit 전파 지연요소만 이를 지연할 수
> 있음.** 재계산 막아지는 건 맞음 — 한 곳에서 `Get`이 되면, `invalid`하다면
> 위로 올라가서 받아와서 계산 처리된 게 들어오고 cache가 쓰인 다음
> `invalid`가 꺼짐.

그리고 "다 다시 써야 한다"는 지시로 **코퍼스 전체 정정을 같은 세션에
수행함**. 정정된 모델:

- `invalid` 플래그 = **"내 캐시가 낡았다"는 표시 하나뿐**, 전파 제어
  장치가 아님.
- **emit은 자기 `invalid` 상태와 무관하게 항상 아래로 전파됨.**
- 중복 **재계산**은 pull-recompute + 노드별 캐시가 막음. 중복 **통지**는
  안 접음(다이아몬드에서 아래쪽 Observer가 두 번 우는 건 의도된 동작).
- 전파를 지연/흡수할 수 있는 건 **명시적 게이트뿐** — 지금은 `Blocker`,
  앞으로 이 문서의 시간 기반 게이트.

고친 곳(원문·역전 근거·영향 범위 전체는
`archive/invalidate-dedup-propagation-reversed.md`):
`base/source-state-plan.md`(전파 규칙 재작성 + "다이아몬드 의존성은 무엇이
푸는가" 절 신설 + `Observer` 절 상호 참조), `base/architecture.md`,
`base/blocker-plan.md`("전파를 지연시키는 유일한 요소"로 위치 명문화),
`reference/comparison-fusion-vide.md`,
`research/framework-comparison-findings.md`, `ROADMAP.md` M0 체크리스트,
스파이크 `05-store-state-diamond-propagation.luau`(옛 모델을 통과 상태로
검증 중이었음 → `rewrite-required/`), `audit/luau-test-first-run-2026-08-13.md`.

**부수 확인 — `:With` 빌더 기각은 유지됨.** `base/source-state-plan.md`의
"`:With`도 새 State 노드로 확정" 절 근거 2번이 폐기된 dedup 장치를
가리키고 있어 근거를 **캐시 공유**로 다시 씀. 근거 1·3번이 그대로
유효하고 결론(빌더 기각)도 안 바뀜 — 오히려 근거 강도는 올라감(예전
근거는 순회 비용 최적화였지만 지금은 실제 중복 *계산*이라서).
---

## 4. 의미론 — 지연되는 건 "전파"인가 "값"인가

두 갈래가 있고, 이게 이 문서에서 두 번째로 큰 결정.

### (A) emit-gate — `Blocker`와 완전히 동일

게이트는 자기 `invalid`를 즉시 세우되 아래로 전파만 미룸. 창이 열려 있는
동안 누가 `debounced:Get()`하면 **최신값**이 나옴.

### (B) value-hold — 값 자체가 지연됨 (권장)

게이트는 창이 닫혀 있는 동안 **자기를 invalid로 만들지 않음**. 즉 캐시된
직전 값을 계속 들고 있고, `debounced:Get()`은 **지연된 값**을 반환. 타이머가
커밋할 때 비로소 invalid + 전파.

**(B)를 권하는 이유**:

1. **업계 의미론과 일치.** VueUse `useDebounce`는 반환된 ref의 *값 자체*가
   늦게 따라오고, RxJS `debounceTime`도 값의 방출을 미룸. "debounce된
   상태"를 다른 곳에서 읽었을 때 debounce 안 된 값이 나오면 놀람.
2. **`Blocker`와 역할이 깔끔히 갈림.** `Blocker`는 "지금 중간 상태니까
   구독자에게 알리지 않을 뿐, 진실은 이미 새 값"이고, Debounce는 "이
   노드의 값은 정의상 늦게 따라오는 값"임. 후자를 (A)로 만들면 두 도구가
   같은 자리에서 미묘하게만 다른 애매한 물건이 됨.
3. **확정된 원칙과 충돌하지 않음.** `base/blocker-plan.md`가 인용하는
   "`Get()`은 라이브 레퍼런스를 준다" 원칙은 `base/source-state-plan.md`에서
   실제로는 **레퍼런스 의미론**(테이블을 복사본이 아니라 라이브 참조로
   준다, 그래서 `Get()` 결과를 캐시해두고 `==` 비교하면 안 됨)에 대한
   것이지 "항상 상류 최신값"이라는 뜻이 아님. 게이트 노드의 *자기* 값이
   지연된 값이라면 `:Get()`은 여전히 그 노드의 라이브 값을 주는 것.
   → 다만 blocker-plan의 그 한 줄이 후자로 읽힐 여지가 있어, 확정되면
   그 문장에 한 줄 명확화를 넣는 게 좋음(열린 질문 Q7).

**(B)의 캐비엇 하나**: 노드가 아직 한 번도 계산된 적 없으면(캐시 없음)
붙잡고 있을 "이전 값"이 없어서 첫 `:Get()`은 그냥 최신값을 계산함.
"지연은 두 번째 값부터"라는 뜻 — 자연스럽고 무해하지만 문서에 명시할 것.

---

## 5. API 모양

### 5-1. 붙이는 방법 — `:Apply` (`Operator` 관용구와 동일)

`research/operator-sugar-plan.md`의 "왜 `:Apply`인가" 절이 확정한 규칙
("이름 붙여 재사용하는 콤비네이터는 전부 `factory(self)` 모양 + `:Apply`")에
그대로 맞음:

```lua
local debounced = text:Apply(Debounce{Time = 0.3})
local sampled   = mousePos:Apply(Throttle{Time = 1 / 30})
```

- `Debounce{...}`는 **팩토리를 반환**하므로 이름 붙여 재사용 가능:
  `local search = Debounce{Time = 0.3}` 후 여러 state에 `:Apply(search)`.
- **재사용해도 상태를 공유하지 않음** — `:Apply`가 호출될 때마다 팩토리가
  새 게이트 노드(자기 타이머/자기 pending 플래그)를 만듦. `Blocker`가
  "겹치는 배치엔 각자 새 인스턴스를 만들 것"으로 네스팅을 막은 것과 달리,
  여기는 재사용이 원천적으로 안전함(공유되는 가변 상태가 없으므로).

### 5-2. 옵션 필드

```lua
type DebounceOptions = {
    Time: number,        -- 필수. 창 길이(초) — 신호마다 리셋됨
    Leading: boolean?,   -- 기본 false. 버스트의 첫 신호를 즉시 통과시킬지
    Trailing: boolean?,  -- 기본 true.  조용해진 뒤 한 번 통과시킬지
    MaxTime: number?,    -- 기본 nil.   신호가 안 끊겨도 최대 이 간격마다 강제 통과
}

type ThrottleOptions = {
    Time: number,        -- 필수. 창 길이(초) — 신호가 리셋하지 못함
    Leading: boolean?,   -- 기본 true.  창 밖 첫 신호를 즉시 통과시킬지
    Trailing: boolean?,  -- 기본 true.  창 안에 눌러둔 게 있으면 창 끝에 통과시킬지
}
```

- **모든 필드는 plain 값만** — `State`를 못 받음. `base/tween-plan.md`의
  "옵션 값 모양" 절이 `Tween{...}`에 대해 확정한 것과 같은 규칙, 같은
  이유(옵션 안에 두 번째 반응 경로를 만들지 않음). `Time`을 반응형으로
  바꾸고 싶으면 `state:Apply(...)` 자체를 다시 만드는 상위 구조가 필요한데,
  그건 이 프리미티브가 아니라 `State<State<T>>` 영역.
- `Leading = true, Trailing = false` → "버스트 시작에 한 번만"
- `Leading = false, Trailing = true` → 기본값, 일반적인 debounce
- 둘 다 `false`는 아무 일도 안 하는 설정 → **즉시 error** 권장(`Slot:Add`의
  범위 밖 인덱스를 clamp 대신 error로 한 선례와 같은 결).

### 5-3. 공개 이름은 둘, 구현은 하나 — `Reset` 한 비트로 갈림 (2026-08-14 개정)

**[초안 정정]** 초안은 lodash를 따라
`Throttle{Time=t} == Debounce{Time=t, Leading=true, Trailing=true, MaxTime=t}`
("`Throttle`은 `Debounce`의 프리셋")로 적었는데, 1-1절에서 그 형태에
이중 발화 버그가 있다는 게 드러나 폐기. 정정된 관계는 훨씬 단순함:

| | `Reset` | `Leading` | `Trailing` |
|---|---|---|---|
| `Debounce{Time}` | **true**(신호가 창을 민다) | 기본 false | 기본 true |
| `Throttle{Time}` | **false**(창 길이 고정) | 기본 true | 기본 true |

- **공개 표면은 생성자 2개** — 사용자가 이미 아는 이름이고, 각자 다른
  기본값을 갖는 게 자연스러움. "`Throttle`을 쓰려면 `Debounce`의 옵션
  4개를 알아야 한다"는 프리셋 안의 단점이 사라짐.
- **구현은 하나** — 내부 공용 게이트가 `Reset` 불리언 하나로 분기.
  quad가 반복해온 "같은 일 하는 두 번째 경로를 안 만든다"(`Effect`가
  deps 배열 대신 `:With` 재사용, `Slot:List`가 Fusion 3분할을 흡수)를
  그대로 지키면서, 두 이름이 미묘하게 갈라지는 버그도 원천 차단.
- **`Reset`은 공개 옵션으로 노출하지 않음** — 노출하면
  `Debounce{Reset=false}`처럼 "이름과 동작이 어긋난 물건"을 만들 수 있게
  됨. 내부 파라미터로만 둘 것.
- **`MaxTime`은 `Debounce` 전용으로 역할 축소** — 1-1절대로 "신호가
  끊이지 않으면 영원히 발화 안 함"이 디바운스의 정의라 그 안전장치가
  필요하지만, 스로틀은 원래 주기적으로 발화하므로 무의미함.

→ 열린 질문 Q3(이 개정안 확인).

---

## 6. 패키지 경계 — quad-base + 주입 op 2개 (**사용자 확인됨, 2026-08-14**)

> **[2026-08-14] 이 절의 방향은 사용자가 직접 확인함** — "기본 구현은
> quad-base에 있는데, 엔진 따라 해당 태스크 부분만 배선해주면 되도록
> 만들어져야 한다 생각함". 아래는 그 결정의 근거와 구체 형태.
>
> 사용자가 같이 짚은 사실: **`task`는 Roblox 전용 전역이지 Luau 언어의
> 일부가 아님** — 순수 `luau` CLI엔 `task.delay`/`task.wait`가 아예 없고,
> 애초에 이벤트 루프 자체가 없음. 즉 **quad-base는 "동작하는 기본 스케줄러"를
> 제공할 수가 없음**(제공할 원시 재료가 없음). 그래서 base가 갖는 건
> 알고리즘 + 인터페이스이고, 미배선 상태에선 엔진 op 3개와 같은 관례대로
> **명확한 에러를 내는 스텁**이어야 함. `Throttle` 역시 trailing 때문에
> "나중에 처리해준다"가 반드시 필요하므로 **디바운스와 똑같이 이 배선에
> 의존함** — 스로틀만 타이머 없이 되는 게 아님.

### 왜 `Tween`처럼 통째로 quad-roblox에 두지 않는가

`base/tween-plan.md`의 "패키지 경계" 절이 `Tween`을 quad-roblox에 둔 건
`Tween`이 **TweenService라는 엔진 기계 자체**(보간 엔진, easing style,
per-instance Tween 객체)에 의존하기 때문. Debounce/Throttle이 엔진에서
필요로 하는 건 **시계 하나**뿐이고, 나머지(pending 플래그, 타이머 리셋,
leading/trailing 판정, MaxTime 부기)는 전부 순수 로직임.

이건 2026-08-13 열네 번째 세션이 `Tag`/`Attribute`에서 내린 판단과 정확히
같은 상황 — 부기 알고리즘을 백엔드마다 복제하지 않기 위해 알고리즘은
quad-base로 옮기고 엔진에 실제로 손대는 한 줄만 주입받게 했음
(`base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진 op"
절). **같은 논리를 그대로 적용하면 알고리즘은 quad-base.**

### 주입 op — `setTimeout`/`clearTimeout` (2026-08-14 사용자 지정)

`base/bind-system-plan.md`의 "base 유틸은 인터페이스, 실제 구현은 백엔드
팩토리가 주입" 절이 정한 경로에 2개 추가. **핸들러 op 3개
(`addTag`/`removeTag`/`setAttribute`)가 아니라 `bindLifetime`/`canExecute`와
같은 "base 범용 유틸" 그룹**임 — 특정 핸들러가 아니라 아무나 쓰는 배관.

```lua
setTimeout(func: () -> (), delay: number): Timeout
clearTimeout(handle: Timeout): ()
```

- **이름/인자 순서는 사용자 지정** — JS 관례대로 **함수가 먼저**. 케이싱은
  탑레벨 소문자 유틸 관례(`bindLifetime`/`canExecute`/`unbindLifetime`)와
  일치(`base/architecture.md`의 "코드 스타일 — 네이밍 케이싱" 절).
- **왜 `task.delay`/`task.cancel`을 안 따라갔는가 (사용자 근거)** —
  **`task`는 표준이 아니고 Luau의 것도 아닌, 한 엔진의 것**임. base는
  "누가 실제로 그려주는지 모르는" 층이라(`base/module-lifecycle-plan.md`)
  특정 백엔드의 어휘를 그 층에 새기면 그 엔진만 특별대우하는 셈이 됨.
  그래서 **가장 대중적이고 엔진 중립적인 JS 어휘**를 가져옴 — 어느
  백엔드 작성자가 봐도 즉시 알아보는 이름. (14차 세션이 엔진 op를
  `addTag`/`setAttribute`로 정할 때 Roblox `CollectionService`와 웹
  `className`/`data-*` 양쪽에 걸치는 이름을 고른 것과 같은 결.)
- ⚠️ **그 대가로 생기는 구현 함정**: Roblox `task.delay(duration, fn, ...)`는
  **반대로 시간이 먼저**라, 배선할 때 인자가 뒤집힘. 래퍼에서 한 번
  뒤집어주는 게 전부지만 조용히 틀리기 좋은 자리 — 이름을 중립으로 두기로
  한 이상 감수하는 비용이고, 배선 지점이 백엔드당 한 곳뿐이라 감당 가능.
- **가변인자(`...`)는 일부러 안 받음** — `task.delay`는 `fn`에 넘길 추가
  인자를 받지만, 게이트의 콜백은 게이트당 하나씩 만들어져 재사용되는
  안정된 클로저(`onWindowEnd`)라 호출마다 새로 만들 필요가 없음. 즉
  varargs로 아낄 할당이 애초에 없어서 표면만 넓히는 셈.
- **미주입 백엔드에서는 base 스텁이 명확한 에러** — 엔진 op 3개와 동일한
  관례. 순수 Luau엔 `task`도 이벤트 루프도 없어 base가 "적당한 기본값"을
  만들어낼 수 없음.
- **`Debounce`/`Throttle` 둘 다 이 배선이 있어야 동작함** — 스로틀도
  trailing 발화가 "창 끝에 다시 처리"라 태스크가 필수. 배선 안 된
  백엔드에서 `Throttle`만 되는 식의 반쪽 동작은 없음.
- 이 두 op는 **게이트 프리미티브 전용이 아님** — 나중에 타이머가 필요한
  다른 것(예: 10절의 `Sample`, 백엔드 중립 테스트 하네스)이 생기면 같은
  배선을 재사용. 그래서 이름도 `Debounce`에 안 묶고 일반적으로 둠.

#### `Timeout` 핸들의 타입 — **전용 `Timeout` 타입으로 확정 (2026-08-14 사용자 결정)**

**[정정]** 에이전트가 `any`를 권했다가 사용자 반론으로 뒤집힘. 뒤집힌
이유가 명확해서 그대로 기록:

- **에이전트 논거 1(선례)이 틀렸음.** `bindLifetime(inst: any, value: any)`/
  `canExecute(value: any)`가 `any`인 건 **거기엔 진짜로 아무거나 오기
  때문**임(사용자가 바인드하려는 임의의 값). 반면 `setTimeout`/`clearTimeout`은
  **자기가 만들어낸 것만 주고받는 닫힌 루프**라 성격이 정반대 — 같은
  선례로 묶을 수 없음.
- **논거 2(타입 안전이 사줄 게 없음)도 약함.** 닫힌 루프이기 때문에 오히려
  **`clearTimeout(1)` 같은 걸 타입 에러로 잡아줄 수 있음** — `any`로 두면
  그 공짜 검사를 스스로 꺼버리는 셈.
- **논거 3(비용)은 사용자가 더 나은 구현으로 무력화.** `Relate`를 걸 게
  아니라 **네이티브 핸들을 그냥 `Timeout` 테이블의 필드에 넣으면 됨**
  (타입은 캐스트로 맞춤). 그러면 릴레이션 층이 통째로 사라지고 남는 건
  테이블 1개 할당인데, 애초에 `task.delay`가 **코루틴을 하나 만드는**
  호출이라 작은 테이블 하나는 그 옆에서 노이즈 수준임. 즉 핫패스 논거가
  성립 안 함.
- **런타임에 마커 필드를 넣는 것도 무방**(사용자 확인) — 그러면
  analyze/런타임 불일치도 없고 `isTimeout` 판별이 공짜로 따라옴.

**확정 형태** (페이로드 자리를 미리 주는 것까지 사용자 동의):

```lua
export type Timeout = {
    __type_timeout: true,  -- 판별 마커. 런타임에도 실제로 넣음
    _native: any,          -- 백엔드 전용 페이로드. base는 절대 안 읽음
}
```

- **마커 필드가 필요한 이유**는 사용자가 짚은 그대로 — Luau에서
  `type Timeout = {}`는 **구조적으로 모든 테이블과 호환**이라 아무
  테이블이나 통과해버림. `true` 싱글턴 타입이 이걸 사실상 nominal하게
  만들어, `clearTimeout(1)`이나 엉뚱한 테이블을 타입 단계에서 잡아줌.
- **`_native`를 타입에 미리 선언**해두면 백엔드가 `:: any` 캐스트 없이
  그냥 대입할 수 있고, `any` 탈출이 **필드 하나에 갇혀 경계가 문서화됨**.
  호출 지점마다 캐스트를 흩뿌리는 방식은 나중에 누가 다른 필드를 더
  끼워넣어도 아무도 모르는 게 문제였음 — quad가 타입 검사를 조용히 끄는
  걸 싫어해온 것(`base/typing-limits.md`)과 결이 맞는 쪽으로 정리됨.
- `_` 접두사는 코퍼스의 기존 private 필드 관례(`handle._observer`,
  `slot._mountedInst`, `_fired`)와 일치.
- **`_native`에 뭘 담을지는 전적으로 백엔드 자유** — coroutine 하나일
  수도, 취소 플래그를 담은 테이블일 수도 있음(아래 "취소를 제공하지 않는
  엔진" 절). base는 이 필드를 **읽지도 쓰지도 않고** 그저 `setTimeout`이
  준 값을 `clearTimeout`에 되돌려줄 뿐임.

백엔드 구현(quad-roblox):

```lua
function setTimeout(func: () -> (), delay: number): Timeout
    return {
        __type_timeout = true,
        _native = task.delay(delay, func),  -- ⚠️ 인자 순서가 뒤집힘(위 참고)
    }
end

function clearTimeout(timeout: Timeout)
    task.cancel(timeout._native)
end
```

**`Brand` 편입은 불필요해 보임** — `base/brand-plan.md`의 `Brand`는
사용자가 값 종류를 판별하는 용도인데, `Timeout`은 사용자 표면에 안 나오는
배관임. 마커 필드 하나로 `clearTimeout`이 자체 검사하는 걸로 충분.

#### 취소를 제공하지 않는 엔진 (사용자 제기, 답 있음)

**"엔진이 cancel을 안 주면?"에 대한 답은 "그래도 구현 가능"** — 프로바이더가
함수를 래핑하고 유효 플래그를 밖에서 뒤집으면 됨:

```lua
-- 네이티브 취소가 없는 엔진의 프로바이더 구현 스케치
function setTimeout(func: () -> (), delay: number): Timeout
    local cancelled = false
    engineDelay(delay, function()
        if not cancelled then func() end
    end)
    -- _native의 내용물은 백엔드 마음 — 여기선 취소 클로저를 담음
    return { __type_timeout = true, _native = function() cancelled = true end }
end

function clearTimeout(timeout: Timeout) timeout._native() end
```

즉 **`clearTimeout`은 base가 백엔드에 요구해도 되는 계약**임(못 지킬 엔진이
없음). 다만 이 방식은 스레드/타이머가 **실제로는 예정대로 깨어나서 아무
일도 안 하는** 형태라, 8절의 "대기 타이머가 게이트를 붙잡는다"는 성질은
그대로 남음(여전히 유계라 문제는 아님).

#### `os.clock()`은 주입 대상이 아님 (2026-08-14, 사용자 정보로 정정)

초안은 "시계가 필요해지면 `now()`를 세 번째 주입 op로 추가"라고 적어뒀는데,
**그럴 필요가 없음** — 사용자 지적대로 `os.clock()`은 Luau **표준
라이브러리**이지 `task`처럼 Roblox가 얹은 전역이 아님. 게다가 Lua 5.x가
리눅스에서 "프로세스가 소비한 CPU 시간"을 주는 것과 달리 **Luau는 일관되게
고정밀 값**을 주므로, base가 백엔드와 무관하게 그냥 불러 쓸 수 있음.

> **⚠️ 단, `os.clock()`은 "현재 시각"이 아님(사용자 재지적)** — 기준점이
> 정해지지 않은 고정밀 카운터라서 **두 값의 차이(diff)를 재는 용도로만**
> 유효함. 절대 시각으로 해석하거나, 저장해뒀다가 다른 시간 개념(`os.time()`
> 등)과 비교하면 안 됨.
>
> **이 게이트 설계는 이 제약을 원래 안 건드림** — 쓰는 곳이 전부
> `maxDeadline = os.clock() + MaxTime` 잡아두고 나중에
> `maxDeadline - os.clock()`으로 **남은 시간**을 구하는, 순수한 차이
> 계산뿐임. 절대 시각이 필요한 자리가 한 군데도 없음. (부수 효과로
> 벽시계 보정(NTP·사용자 시간 변경)에 영향받지 않는다는 장점도 있음 —
> 타이머엔 오히려 이쪽이 맞음.)

**정리**: 주입이 필요한 건 "미래에 뭔가를 실행시키는 능력"(`setTimeout`/
`clearTimeout`)뿐이고, "얼마나 지났나"(`os.clock` 차이)는 언어가 이미 줌.
그래서 아래 6-1의 최적화들이 **주입 표면을 늘리지 않고** 가능해짐.

### 6-1. 구현 세부 — 취소+재스케줄 vs 지연 타이머

기본안은 신호마다 `clearTimeout` + `setTimeout`(단순, 정확). Roblox에서
이건 신호마다 스레드 하나를 만들고 버리는 것이라, 텍스트 입력(초당 ~10회)
수준에선 무시해도 되지만 **Heartbeat 같은 고빈도 소스에 많은 노드가 붙으면**
스레드 처닝이 될 수 있음.

대안: 타이머를 취소하지 않고, 콜백에서 `os.clock()`으로 "진짜 마감이 더
뒤인가"를 보고 남은 시간만큼 다시 스케줄(고전적인 lazy timer). 위 절대로
`os.clock()`은 주입 없이 그냥 쓸 수 있으므로 **인터페이스 변경이 전혀
없음** — 순수 내부 최적화라 나중에 전환해도 안전함. **지금은 단순한
쪽으로 가고, 실측에서 문제가 드러나면 그때 전환**을 권함.

#### `MaxTime`을 타이머 2개가 아니라 1개로 (사용자 제기)

사용자가 짚은 두 갈래 — (a) 버스트 시작 시각을 `os.clock()`으로 잡아두고
계산, (b) 시작할 때 "리셋되는 타이머"와 "MaxTime 타이머" 둘을 걸기 —
중 7절 의사코드는 (b)를 씀(시계 없이 닫히고 읽기 쉬워서). 다만 `os.clock()`을
그냥 쓸 수 있게 된 이상 **둘을 합쳐 타이머 1개로 줄이는 게 더 나음**:

```
-- 버스트 시작 시: maxDeadline = os.clock() + MaxTime
-- 매 신호마다:   타이머 마감 = min(Time, maxDeadline - os.clock())
--                              ↑ 둘 다 "남은 시간"(차이)이라 os.clock()의
--                                기준점이 무엇이든 무관 — 위 주의 참고
```

한 타이머가 "조용해짐"과 "더 못 기다림" 둘 다를 표현하므로, 어느 쪽으로
깨어나든 그냥 커밋하면 됨. `MaxTime`이 없으면 `maxDeadline`이 무한대라
`min`이 항상 `Time`이 되어 자연히 같은 코드로 흡수됨(분기 없음).

**의사코드를 (b)로 남겨둔 이유**: 두 타이머가 각각 무슨 뜻인지가 눈에
보여서 검토하기 쉬움. 실제 구현은 위 `min` 형태를 권함 — 동작은 동일하고
타이머/스레드 수가 절반.

---

## 7. 의사코드

> **주의**: `Gate` 노드의 내부 훅(`onUpstreamSignal`, `commit`)은 아직
> 이름도 계약도 확정되지 않은 가칭 — `Blocker`의 게이티드 노드가 이미
> 필요로 하는 것과 같은 훅이라(1절), 실제 구현 시엔 그쪽과 같이 정의할 것.

```lua
-- quad-base — 공용 코어. Reset 한 비트가 Debounce/Throttle을 가름(5-3절).

local function makeGate(reset: boolean, opts)
    if opts.Leading == false and opts.Trailing == false then
        error("Leading/Trailing 둘 다 false면 아무것도 통과하지 않음")
    end
    local leading  = if reset then opts.Leading == true else opts.Leading ~= false
    local trailing = opts.Trailing ~= false

    -- 팩토리 — :Apply가 state마다 한 번씩 호출하므로 아래 지역 상태는
    -- 게이트 노드 하나당 하나씩 새로 생김(팩토리 재사용해도 공유 안 됨)
    return function(self)
        local gate    = Gate(self)  -- Blocker가 쓰는 것과 같은 게이트 노드
        local pending = false       -- 창 안에서 상류 신호가 있었는가
        local window  = nil         -- 살아있으면 "창 안", nil이면 idle
        local cap     = nil         -- MaxTime 타이머(Debounce 전용)

        local openWindow, onWindowEnd

        function openWindow()
            window = setTimeout(onWindowEnd, opts.Time)
        end

        function onWindowEnd()
            window = nil
            if pending and trailing then
                -- Blocker와 같은 순서: 상태를 먼저 정리하고 그 다음 전파
                -- (전파 도중 소비자가 동기적으로 상류를 :Set()해서 재진입해도
                --  방금 닫은 창의 잔여 상태를 다시 건드리지 않게)
                pending = false
                if cap then clearTimeout(cap); cap = nil end
                gate:passThrough()  -- invalid 세팅 + 아래로 1회 전파
                openWindow()        -- 통과했으니 창을 다시 엶 = 다음 통과까지 최소 Time
            end
            -- pending이 없으면 창을 안 열고 완전히 idle로 복귀
        end

        gate.onUpstreamSignal = function()
            if window == nil then
                -- 창 밖(idle)
                if leading then gate:passThrough() else pending = true end
                openWindow()
            else
                -- 창 안
                pending = true
                if reset then                  -- ← Debounce만: 창을 뒤로 민다
                    clearTimeout(window)
                    openWindow()
                end
            end

            -- MaxTime: 창과 달리 절대 리셋되지 않는 두 번째 타이머.
            -- "신호가 안 끊기면 영원히 발화 안 함"(1-1절)을 위한 안전장치라
            -- Debounce에서만 의미 있음.
            if opts.MaxTime and cap == nil and pending then
                cap = setTimeout(function()
                    cap = nil
                    if pending and trailing then
                        pending = false
                        if window then clearTimeout(window) end
                        gate:passThrough()
                        openWindow()
                    end
                end, opts.MaxTime)
            end
        end

        return gate
    end
end

function Debounce(opts: DebounceOptions) return makeGate(true,  opts) end
function Throttle(opts: ThrottleOptions) return makeGate(false, opts) end
```

**사용자가 짚은 시나리오 검증** (`Throttle{Time = 1}`, 0.0과 0.1에 입력):

```
0.0  window == nil → leading 통과 ●        openWindow → 마감 1.0
0.1  window 살아있음 → pending = true
     reset == false 라 창을 안 밂 → 마감은 여전히 1.0
1.0  onWindowEnd: pending && trailing
     → pending = false, passThrough ●  ← 0.1 시점의 최신값이 여기서 적용됨 ✅
     → openWindow → 마감 2.0
1.05 window 살아있음 → pending = true (초안이 여기서 이중 발화했음, 이제 막힘 ✅)
2.0  통과 ● → openWindow → 3.0
3.0  pending 없음 → 창 안 엶, idle 복귀
3.5  입력 → window == nil → leading 즉시 통과 ●
```

**(B) value-hold 의미론이 붙는 자리**: `gate`는 `onUpstreamSignal`에서
자기 `invalid`를 세우지 않고, 오직 `passThrough()`에서만 세움 — 그래서
창이 열려 있는 동안 `gate:Get()`은 캐시된 직전 값을 반환. (A)를 택하면
`onUpstreamSignal` 진입 시 invalid만 세우고 전파를 미루는 형태로 바뀜.

---

## 8. 라이프사이클 / GC 분석

`base/lifecycle-pattern.md`의 "정리(`retract`)는 기본적으로 GC에 위임"
원칙 위에서 확인한 것들:

- **대기 중인 타이머는 게이트 노드를 강하게 붙잡음.** Roblox `task.delay`가
  콜백을 들고 있고, 콜백이 게이트를 업밸류로 캡처하므로. 즉 **다운스트림이
  전부 죽어도 최대 `Time`(또는 `MaxTime`)초 동안은 노드와 그 상류 체인,
  그리고 (B)에서는 캐시된 값까지 살아 있음.**
  - **유계이고 자가 치유됨** — 누수가 아니라 "지연된 GC". 문서화 대상.
  - 위험해지는 조합은 **긴 `Time` + 빠른 생성/파괴**(예: `Slot:List` 항목
    하나하나가 `Time = 60`짜리 게이트를 갖는 경우). 이건 문서 경고 +
    (Q4에서 다루는) 제어 핸들의 `:Cancel()`로 대응.
- **타이머 콜백이 죽은 대상을 건드릴 위험은 없음.** 콜백이 하는 건 플래그
  세팅과 무효화 전파뿐이고, 실제로 무언가를 하는 소비자(store-bind
  핸들러/Observer)는 이미 `canExecute` 게이트를 통과해야만 실행되므로
  기존 장치가 그대로 커버함. **Dispatch 쪽 변경 필요 없음.**
- **게이트 노드는 `inst`에 안 묶인 순수 값 계층**이라 `bindLifetime`/
  `unbindLifetime` 배선이 필요 없음 — `Slot`/`Effect`가 겪은 복잡도가
  여기엔 없음.
- **두 `Relate` 상호 순환 위험 없음** — `Relate`를 아예 안 씀(게이트의
  상태는 전부 클로저 업밸류). `base/relate-plan.md`의 "위험한 패턴" 절과
  무관.

---

## 9. 이름

### 9-1. ⚠️ Roblox 커뮤니티의 "debounce"와 충돌함

Roblox 생태계에서 `debounce`는 압도적으로 **재진입 방지 불리언**을
가리킴(`local debounce = false ... if debounce then return end`). 웹
쪽 의미(시간 기반 합치기)와 이름만 같고 완전히 다른 물건임. quad의 주
사용자층이 Roblox 개발자라는 걸 감안하면 이건 실질적인 혼동 위험이고,
이 코퍼스가 `Brand` 후보에서 `Tag`를 뺀 것과 같은 종류의 문제
(`.claude/question.md` 1번의 `Brand` 항목).

후보:

| 이름 | 근거 | 문제 |
|---|---|---|
| `Debounce`/`Throttle` | RxJS/lodash/VueUse 전부 이 이름, 검색성 최고 | 위 충돌 |
| `Settle` / `Settled` | "값이 가라앉을 때까지 기다린다" | 선례 없음, Promise settle과 혼동 |
| `Quiet` / `Idle` | 동작을 직관적으로 서술 | 선례 없음 |
| `Coalesce` | "합친다"는 동작 자체 | nil 병합(`Alternative`)과 어휘 충돌 |
| `RateLimit` (Throttle 자리) | 의미 명확 | 서버 레이트 리밋 뉘앙스 |

**권고**: `Debounce`/`Throttle` 유지 + **사용자 문서 첫 줄에 Roblox 관용
"debounce"와 다르다는 걸 못박기**. 업계 표준 이름을 버리면 검색·이주
비용이 더 큼. 단 이건 사용자 취향이 강하게 걸리는 영역이라 Q1로 넘김.

### 9-2. `-ed`를 안 붙이는 이유 (이건 코퍼스 규칙으로 결정됨)

`Tag.Added`/`Modifier.Overridden`/`Sorted`의 `-ed`는 "clone 후 **즉시
확정된** 값"이라는 관례고, lazy한 것엔 안 붙임(`Compute`가 `Computed`가
아닌 이유 — `base/source-state-plan.md`의 "네이밍" 절). 게이트가 반환하는
건 lazy State 노드이므로 **`Debounce`/`Throttle` 원형이 맞음**, `Debounced`
아님. 이건 열린 질문 아님.

---

## 10. 인접 후보 — 지금은 범위 밖

- **`Delay{Time}`** — 합치기 없이 그냥 미룸. 게이트로 표현 가능하지만
  실사용 근거가 약함.
- **`Sample{Time}`** (RxJS `sampleTime`) — 상류 변경과 무관하게 주기적으로
  최신값을 통과. 이건 상류 신호가 없어도 타이머가 도는 거라 **유일하게
  진짜 eager**가 되는 변형 — 넣는다면 별도 판단 필요.
- **`Audit`** (RxJS) — `Throttle{Leading = false}`와 같음, 프리셋으로 흡수됨.

---

## 11. 다른 결정과의 상호작용 (확인 완료)

- **`Dispatch`**: 변경 없음. 게이트는 순수 값 계층이고 store-bind 핸들러는
  평소처럼 무효화를 받아 `:Get()`할 뿐.
- **`Tween`**: 직교. `debounced:Apply(Animate{...})`처럼 겹쳐 쓸 수 있고,
  둘 다 시간을 다루지만 층이 다름(하나는 값 보간, 하나는 전파 타이밍).
- **`Blocker`**: 직교하게 겹쳐 쓸 수 있음(`state:Apply(Debounce{...}):Block(b)`).
  실사용 사례는 잘 안 떠오르지만 구조적으로 막을 이유도 없음.
- **`Effect`/`Observer`**: 게이트 아래에 붙으면 자동으로 debounce된
  빈도로 재실행됨 — 별도 장치 불필요. `Effect`가 deps 배열을 안 만들고
  `:With`를 재사용한 것과 같은 결로, "debounce된 Effect"라는 별도 API를
  만들 필요가 없다는 뜻.
- **테스트/`quad-mock`**: 주입 op 2개 덕분에 **가상 시계로 결정론적 테스트가
  공짜로 됨**(스케줄 큐를 손으로 진행). 이게 6절의 quad-base 배치를 미는
  또 하나의 근거 — quad-roblox에 `task.delay`를 직접 박아넣으면 base
  테스트 하네스에서 이 프리미티브를 테스트할 방법이 없어짐.
- **`typing-limits.md`**: 게이트는 `State<T> -> State<T>`(타입 인자 불변)라
  0-Y가 걸렸던 "자기를 다른 타입 인자로 감싸 반환"에 해당하지 않음 —
  타입 쪽 추가 위험 없음. 다만 `:Apply` 결과를 받는 자리에 명시 주석
  바인딩을 하라는 일반 관례는 그대로 적용.

---

## 12. 사용자 판단 대기 — 열린 질문

1. **이름** — `Debounce`/`Throttle` 유지(권장) vs 대안. Roblox 관용
   "debounce"(재진입 불리언)와의 충돌을 문서 경고로만 다룰지. (9-1절)
2. **의미론** — (A) emit-gate(`Blocker`와 동일, `:Get()`은 최신값) vs
   **(B) value-hold(권장, `:Get()`도 지연된 값)**. (4절)
3. **[2026-08-14 개정] 공개 생성자 2개 + 내부 구현 1개(`Reset` 한 비트)**
   — 초안의 "`Throttle`은 `Debounce{MaxTime}` 프리셋"은 이중 발화 버그가
   있어 폐기됨. 개정안 확인만 필요. (5-3절, 7절)
4. **제어 핸들(`:Flush()`/`:Cancel()`)을 v1에 넣을지.** 세 가지 모양:
   - **S1(권장, v1)**: `state:Apply(Debounce{...})` — 핸들 없음.
     `Operator` 관용구와 완전 일치, 가장 단순.
   - **S2**: `local d = Debouncer{...}; state:Debounce(d)` + `d:Flush()`/
     `d:Cancel()` — **`Blocker`의 모양과 글자 그대로 같음**(외부 객체를
     들고 `state:Block(blocker)`로 배선). 구조적 추가 비용이 사실상 없고,
     "검색창에서 Enter 누르면 즉시 커밋" 같은 실사용 요구를 커버함.
   - **S3**: `__call`을 가진 객체로 S1/S2를 겸함 — 매직이라 비권장.
   실사용에서 Flush가 자주 필요하다고 보면 처음부터 S2가 나음.
5. ~~**패키지 경계**~~ **[2026-08-14 해소]** — 사용자가 quad-base +
   엔진별 태스크 배선으로 확정. 주입 표면이 3개→5개로 늘어나는 비용은
   수용됨. op 이름/시그니처도 사용자가 지정
   (`setTimeout(func, delay)` / `clearTimeout(handle)`). (6절)
6. ~~**`Debounce`를 파생 State 위에 걸었을 때**~~ **[2026-08-14 소멸]** —
   전제(무효화 dedup이 신호를 삼킴)가 틀린 것으로 드러나 질문 자체가
   없어짐. emit은 항상 재전파되므로 게이트는 어디에 걸든 정상 동작함.
   (3절)
7. **`base/blocker-plan.md` 한 줄 명확화** — 그 문서가 인용하는
   "`Get()`은 라이브 레퍼런스를 준다"는 실제로는 `base/source-state-plan.md`의
   **레퍼런스 의미론** 원칙이지 "항상 상류 최신값"이 아님. Q2에서 (B)를
   택하면 두 문서가 모순돼 보이므로 그 인용에 한 줄 주석을 넣는 게 좋음.
   (확정 문서 수정이라 사용자 승인 후 반영 — 이 세션에선 안 건드림.)
8. **`Time = 0`을 허용할지** — "이번 스텝 합치기" 용도로 유용하지만
   스케줄러 타이밍에 의존하는 준-`Blocker`가 됨. 허용(권장) / 금지 /
   별도 이름 부여 중 선택. (1절 인용문)
9. ~~**`Timeout` 핸들의 타입**~~ **[2026-08-14 완전 해소]** — 사용자 결정으로
   **`type Timeout = { __type_timeout: true, _native: any }`**(마커는
   런타임에도 실제로 넣고, 백엔드 페이로드 자리도 타입에 미리 선언).
   에이전트의 `any` 권고는 철회됨 — `bindLifetime`이 `any`인 건 거기
   진짜로 아무거나 오기 때문이고, `setTimeout`/`clearTimeout`은 자기가
   만든 것만 주고받는 **닫힌 루프**라 성격이 정반대이며 오히려
   `clearTimeout(1)`을 타입 에러로 잡아주는 이득이 있음. 비용 논거도
   무력화 — `Relate` 대신 네이티브 핸들을 필드에 직접 넣으면 되고,
   `task.delay`가 코루틴을 만드는 옆에서 작은 테이블 하나는 노이즈.
   더 판단할 것 없음. (6절)
10. ~~**`base/source-state-plan.md`의 무효화 dedup 문장 정정**~~
    **[2026-08-14 해소·반영 완료]** 사용자가 "emit은 항상 전파함,
    `Blocker`나 emit 전파 지연요소만 이를 지연할 수 있음"으로 확정하고
    전체 정정을 지시 — 같은 세션에 base/reference/research/ROADMAP/
    스파이크/audit까지 전부 반영했고, 역전 기록은
    `archive/invalidate-dedup-propagation-reversed.md`. 상세는 3절.

---

## 13. 우선순위 / 마일스톤

**M0 착수를 막지 않음** — 이 문서의 어떤 결정도 디스패치/State 코어 계약을
바꾸지 않음(11절에서 확인). 다만 `Operator` 슈가와 달리 **순수 슈가가
아니라 실제 기능 갭**이라(타이머 없이는 사용자 코드로 재현하기 번거롭고,
재현하면 laziness를 깨기 쉬움) 우선순위는 그쪽보다 위로 두는 게 맞아 보임.

**의존성**: State 코어(`ROADMAP.md` M3) + 백엔드 주입 표면. 그 둘이
서면 언제든 얹을 수 있고, `Blocker` 구현과 **같은 시점에 하는 게 확실히
쌈** — 1절에서 봤듯 게이트 노드를 공유하므로 따로 하면 같은 걸 두 번
설계하게 됨. **권고: `Blocker` 구현 시점(M3)에 게이트 노드를 공용으로
빼두고, Debounce/Throttle 자체는 그 위에 나중에 얹기.**
