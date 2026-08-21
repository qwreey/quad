# `Epoch` 인터페이스 + `EpochMap` 컴포지션, 그리고 `Brand` 인스턴스화 (2026-08-21 신설)

**상태**: research — **사용자 제안, 에이전트 평가 완료. 방향에는 동의하나
아래 §4의 결정 항목들이 열려 있어 아직 아무것도 확정 안 함.**
`base/state-epoch-plan.md`/`base/gate-plan.md`/`base/brand-plan.md`가 여전히
정본이다. 발단은 "다중 의존성 `Effect`에서 한 파동에 `fn`이 두 번 도는" 갭
(`base/effect-plan.md`의 다중 deps 절, 2026-08-21 대화에서 에이전트가 제기).

## 1. 제안 (사용자 원문 요지)

1. **에포크 부기를 State에서 떼어내 컴포지션 가능한 객체로.** 가칭
   `EpochMap()`, 표면은 `EpochMap:Update(Epoch|{Epoch}) -> boolean`이고
   그 boolean이 **"뒤로 전파가 필요한가"** 를 뜻한다. *"이건 invalid 랑은
   다른 구현이야."*
2. **`Observer`는 emit의 주체를 클로저 인자로 흘려준다**(값이 아니라 출처).
3. **`Effect`는 자기 `EpochMap`을 하나 갖고**, 각 dep의 observer 등록 함수
   안에서 그걸 `Update` 한다 → 한 파동에 여러 dep가 깨워도 **첫 번째만
   `true`** 라 `fn`이 한 번만 돈다.
4. **emit 페이로드에서 게이트를 뺀다.** `emit(from: Source|{Source})`이면
   충분하다 — *"하류가 Gate 노드를 받을 이유도 없거든."* 런타임 분기는
   `isSource`로.
5. **더 나아가 `Source`가 아니라 `Epoch`로 일반화**한다.
   `type Epoch = { Count: number }`이고 **그 자체로 키로 쓸 수 있는 unique
   테이블**. `emit(Epoch|{Epoch})`, `Update(Epoch|{Epoch})`.
   *"'소스를 전해주는것' 이라고 보기엔 너무 협소하고, 일반화된 형태가 아님."*
6. **그러려면 `Brand`가 다중 태깅을 허용해야 한다** — 나아가 `Brand` 자체를
   **인스턴스화 가능**하게: `Brand()`가 weak `[obj] = true|nil` 하나를 들고,
   `SomeBrand:register(obj)` / `SomeBrand:is(obj)`. *"본인이 거기 속하면,
   본인이 직접 해당 브랜드를 가져와 등록하면 … `isXXXX`에서 각각의 구현을
   넣을 필요가 없어짐. 따라서 외부 확장도 쉬워진다."*

## 2. 에이전트 평가 — 방향은 옳다

- **`EpochMap` 분리는 이미 코퍼스가 발견한 구분을 형식화한다.** 같은 날
  `state-epoch-plan.md`가 맵을 둘로 가른 이유가 정확히 "값 유효성"과 "전파
  dedup"이 **비대칭으로 움직인다**는 것이었다(§2의 "왜 테이블이 둘인가").
  후자만 떼어내 재사용 가능한 객체로 만들면, **노드가 아닌 소비자(leaf)도
  같은 판정을 쓸 수 있다** — 지금 State에만 있어서 못 쓰던 것.
- **다중 dep `Effect` 갭이 이걸로 정확히 닫힌다.** `A → b`, `A → c`,
  `Effect(fn, b, c)`에서 `b`/`c`는 서로 다른 노드라 **접어줄 공통 하류가
  없어** 에포크 dedup이 못 도왔다. `Effect`가 자기 `EpochMap`을 들면
  그 지점이 곧 공통 하류가 된다. 대안으로 검토했던 "deps를 하나의 파생
  노드로 수렴시키기"보다 낫다 — 노드를 더 안 만들고, `effect-plan.md`가
  확정한 "의존성 N개면 내부 Observer도 N개" 구조를 안 건드린다.
- **게이트를 페이로드에서 빼는 것도 맞다.** 하류는 게이트 identity를 **한
  번도 안 쓴다**(에포크 경계로 만드는 안은 `state-epoch-plan.md` §5-3에서
  이미 기각됨). 배치가 "그 전파에만 쓰는 일회성 스냅샷"이라는 성질도
  그대로 유지된다.
- **`Epoch`로의 일반화가 실제로 계약을 정확하게 만든다.** 맵이 `Source`에서
  요구하는 건 **identity + 단조 증가 카운터** 둘뿐이다. 그걸 이름 붙이면
  `state-epoch-plan.md`가 `루트 Source들의 에포크`라 부르던 것이 그냥 `Epoch`들이 되어
  서술도 짧아지고, Source가 아닌 원천(외부 시계 등)도 특수분기 없이 낀다.
- **`Brand` 인스턴스화 — 다중 태깅 필요는 지금 실재한다.** `Source`가
  `SourceBrand`이면서 동시에 `EpochBrand`여야 하는데, 현행
  `Brand.get(x) -> tag`는 **객체당 태그 하나**라 표현이 안 된다
  (`base/brand-plan.md`). 게다가 지금 서브타입은 손으로 쓴 OR 체인
  (`isState = isSource(x) or Brand.get(x) == StateTag`)인데, 자기 등록
  방식이면 `StateBrand:is(x)` **한 번**으로 끝나 조회 수도 준다.

## 3. 대가 — 잃는 것 하나는 명시해둘 것

**`Brand.get(x)`의 역조회가 사라진다.** 현행 설계는 *"nil이면 quad가 모르는
값"*이라는 성질과 "이 값이 대체 뭔가"를 한 번에 답하는 능력을 갖는데,
브랜드별 레지스트리로 쪼개면 전 브랜드를 훑기 전엔 답을 못 한다.

또 하나, `base/brand-plan.md`가 2026-08-09에 **의도적으로 설계한 성질**이
흐려진다 — *"어느 predicate가 다른 predicate를 내포하는지(포함 관계의
방향)가 코드 모양 자체에 드러나게 함"*. 자기 등록 방식에서는 그 포함 관계가
각 타입의 **생성자에 흩어진다**(`PreRef` 생성자가 `RefBrand`에도 등록).
"올바른 자리"라고 볼 수도 있지만, 한 곳에서 관계를 읽던 것은 못 하게 된다.

## 4. 결정이 필요한 것 (전부 열림)

1. **`Epoch`를 `Source`가 구조적으로 만족하게 할 것인가, 별도 객체로 들 것인가.**
   전자 권고 — `Source`가 `State`를 구조적으로 만족하는 기존 패턴과 같고,
   후자면 그 Epoch 객체가 Source를 **되참조하면 안 된다**는 weak-key 제약이
   하나 더 생긴다(`base/relate-plan.md`).
2. **`Count`를 공개 필드로 낼 것인가.** `type Epoch = { Count: number }`를
   인터페이스로 두면 `source.Count`가 사실상 공개 표면이 되고, `Source`에
   예약 이름이 하나 는다.
3. **`Epoch` 인터페이스의 계약** — 단조 증가만 요구하는가, 시작값/오버플로는
   무엇으로 하는가. `Source:Set`/`:Emit` 외의 구현자가 지켜야 할 것.
4. **State는 `EpochMap`을 **둘** 컴포지션하는가.** 지금 맵이 둘이므로
   자연스럽게는 `_valueEpochs`/`_emitEpochs` 두 인스턴스다. 그러면
   `Update`만으로는 부족하고 **재계산 후 "읽은 것 전부 최신으로" 동기화하는
   연산**(가칭 `:Sync`)이 하나 더 필요하다(`state-epoch-plan.md` §2의
   재계산 규칙).
5. **`Observer` 클로저 인자 추가** — 지금 계약은 *"값을 안 실어주는 구독"*
   이라 인자가 없다. 출처를 넘기는 건 값이 아니라 메타데이터라 취지에는
   안 어긋나지만, `base/source-state-plan.md`의 그 절과
   `state:Observer()`(인자 없는 "항상 관측" 유틸)까지 같이 손봐야 한다.
6. **`Brand` 전환 범위** — 인스턴스 브랜드로 전면 전환할지, `Brand.get`
   역조회를 남긴 채 다중 태깅만 얹을지. `Brand`는 **이름 자체가 아직 용어
   정리 대기**(`question.md` 1번)라 같이 정하는 게 낫다.
7. **마일스톤** — `EpochMap`/`Epoch`는 M3(State 구현)에 걸리고, `Brand`
   변경은 M2 이전 코드에도 영향이 있다(이미 커밋된 M1 코드가 `Brand`를
   쓰는지 확인 필요).

## 관련 문서

- `base/state-epoch-plan.md` — 지금 확정된 두 맵과 수신 규칙(§2).
- `base/gate-plan.md` — 배치 페이로드(4번), 빈 배치 무통지(8번).
- `base/brand-plan.md` — 현행 단일 레지스트리 설계와 서브타입 OR 합성.
- `base/effect-plan.md` — 다중 deps 절(이 제안이 닫으려는 갭).
- `base/source-state-plan.md` — `state:Observer(fn)` 계약.
