# 코드 품질 리뷰 round15 — 코드 분리·응집과 안 판 DX 표면 (2026-10-16)

> **[2026-10-16 신설 — 사용자 요청]** 사용자 요청: *"지금까지 정확성, 문제점, 외부에서 읽힘만 보았고, 코드리뷰의 각도가 코드 퀄리티였던 적은 잘 없음. 코드 분리나 등등 … API 표면 자체는 완고하고 DX를 따져왔기에 괜찮다고 봐. 그러나 안 판 표면이 DX가 좀더 많이 있긴 한 것 같음 … sonnet/gemini 섞어서 토론 붙이는게 좋을거야 … breaking 이 나는 방향은 아닐 것이고. 3.4 이 나온 다음에 할 일이 쌓여 있도록 하는 그런 장치"*. 사용자도 이 영역은 불확실성이 높다고 했다.
>
> **진행 방식.** 리뷰어는 넷이고 서로의 결과를 모른 채 독립으로 봤다.
> - A: sonnet, quad-base·quad-types
> - B: sonnet, quad-roblox와 킷 둘
> - C: Gemini 3.8 Flash(`agy`), 레포 전체를 구조 각도로
> - D: Gemini 3.8 Flash(`agy`), 레포 전체를 안 판 DX 각도로
>
> 판정자(opus 서브에이전트)는 네 보고를 묶고 파일:줄을 직접 열어 사실을 확인한 뒤 선 거르기를 했다. 남은 후보는 네 리뷰어에게 돌려 토론 1라운드를 거쳤고, 판정자가 항목마다 판정을 붙였다. 범위에서 생성 `quad-roblox/src/Declaration/`과 `scripts/gen-d.py`는 뺐다(3.4.0에서 대체 예정). 판정 기준은 `audit/round14-principle-audit/PRINCIPLES.md`의 B1·B2·B3과 `conventions.md` "설계 원칙" 절이다.
>
> **[2026-10-18 추가]** §6에 opus 독립 한 패스(H-927~H-939)와 모델별 수렴 대조를 붙였다.
>
> **이 문서는 결정이 아니다 — 3.4.0 뒤에 고를 후보 목록이다.** "채택 권고"도 판정자 권고일 뿐이다. 새 이름·필드·메커니즘이 걸린 것은 §4 문항으로 올렸다. BREAKING인 후보는 없다.

## §1 진행 기록

**리뷰어별 범위와 발견 수.**
- A(sonnet, quad-base·quad-types): 15건. Observer 본문 중간·LifetimeHandle·Claim·Operator·Context·Slot/Raw·Tree는 머리와 함수 크기만 봤다고 스스로 밝혔다.
- B(sonnet, quad-roblox·material·devui): 15건. 킷은 정독하지 않고 구조·중복·관용구 위주로 봤다. `Animate.luau`·`Tween.luau` 후반·devui `Window/`·`Table`·`Plot`·`Tree`·`Combo`, material `Menu`·`Slider/Behavior`·`Dialog` 본문은 보지 못했다.
- C(Gemini, 구조): 20건.
- D(Gemini, DX): 22건.

원시 발견은 합쳐 72건이다. 같은 것끼리 묶으니 후보 28개(품질 T1~T16, DX X1~X12)와 선 거르기 탈락 묶음 열다섯이 됐다.

**선 거르기에서 떨어진 것과 이유 요약**(한 줄씩은 §5).
- 이미 사용자가 결정했거나 기각한 것: 공변 뷰 타입, Effect `return nil`, 죽은 호스트 Slot 평소 경로 에러·`q.isAlive`, `Parent` 전용 문구.
- 사실과 다른 것: Slot `S`가 `any`로 소거됐다는 주장.
- 문서에 이미 있는 것: 제네릭 컴포넌트 레시피, Modifier 순서.
- B1·B2·B3에 걸리는 것: `q.Not`, `Toggle`/`Update`, flatten 분리, 핸들러 계층 값 목록 합치기.
- 기존 문서가 이미 추적하는 것: `distinct` 파생, 한 컴포넌트가 루트 여럿을 돌려주기, 인라인 `:Compute` strict 거부.

토론에서 네 리뷰어 모두 이 탈락 목록에 이의를 달지 않았다. 자기 발견이 떨어진 C·D도 근거를 다시 확인하고 수용했다.

**Gemini 인용 정확도.** 두 보고 모두 파일:줄은 대체로 맞았다. 다만 주장이 과장된 곳이 있었다.
- C는 Slot `S` 필드 "대부분이 `(any, any) -> any`"라고 했다. 실제로는 인자 이름·개수가 적힌 시그니처다.
- C·D는 Effect `return nil`을 다시 제안했다. 이미 실측으로 반증된 제안이다.
- D는 "`ToState`를 파일마다 만들었다"고 했다. 실제로는 material `Util.luau` 한 곳에 타입별 셋이다.
- 판정자 쪽에도 인용 실수가 하나 있었다. 후보 목록에 `quad-base/src/init.luau:30`이라고 적었는데 실제는 20행이다(C·D가 바로잡음, 아래 H-904에 반영).

**토론 라운드 요약.** 1라운드에서 네 리뷰어가 28개 후보에 찬성·반대·수정을 달았다. 결과는 대부분 수렴했다.
- 품질 후보 중 셋(T7 파일 이름, T8 태깅 spec, T16 상태표)과 DX 후보 둘(X3 함수 값 꼬리, X12 `:Set` 문장)은 만장일치 찬성이었다.
- 넷 모두 "새 공개 표면은 반대, 킷 내부나 문서까지만"으로 수렴했다: T12 Overlay 승격, X9 오타 검사, X11 `ToState`, T10 번들 진입점. 처음 승격·신설을 낸 C·D도 토론에서 자기 제안을 철회했다.
- 갈린 것은 둘이다.
  - T5(`_reentryFrames` 타입화)는 A·C 찬성, B·D 반대로 2대 2였다. 판정 중 판정자가 이 집합이 사용자 결정(round14 Q174 보강 (b), `Observer.luau` 83행 주석과 `architecture.md` 621행: "debug-only — read nowhere else, no public surface")으로 일부러 비공개로 둔 것임을 찾았다. 그래서 2라운드 없이 기각했다(§5).
  - T3(Dispatch `Init` 분리)는 범위와 시기만 갈렸다. A는 진단·레지스트리만, B는 drive-hook-plan 결정 뒤로, C·D는 찬성이었다. 판정자가 두 조건을 합쳐 판정했다(H-902).
- 그래서 2라운드는 열지 않았다.

**실행 수.** 리뷰 넷(sonnet 둘, agy 둘) + 토론 1라운드 넷(sonnet은 같은 에이전트 이어 쓰기, agy는 새 실행) = 여덟이다. agy는 한 번에 하나씩 순차로 돌렸다.

## §2 발견 원장 — 코드 품질

**H-899. 끝난 일을 미래형·마일스톤 시점으로 적은 소스 주석.**

상황: 구현이 끝난 기능을 아직 올 일처럼 적은 주석이 남아 있다. 확인한 자리는 아래와 같다.
- `quad-base/src/Dispatch/init.luau` 23~24행과 598~600행: "(a) PreRef/PostRef 선행 패스와 (c) postRefList는 M8과 함께 온다". 같은 파일 48행과 624~636행에 이미 구현돼 있다.
- `quad-base/src/Bookkeeping.luau` 70~71행: "M6이 오면 SlotBrand로 분기한다, 그때까지는 claim 가능한 inst만". 138행이 이미 분기하고, 135행은 "그 예언이 이것"이라고 덧붙여 놓았다.
- `quad-roblox/src/EngineOps.luau` 3~5행: "M5에서 구현하는 op … 이 파일은 M5 몫만".
- `quad-roblox/src/Handlers/InstanceChild.luau` 6행: "ROADMAP M5 체크박스 두 줄의 1:1 전사다". 그 뒤 결정이 여럿 붙어 더는 1:1이 아니다.
- `quad-roblox/src/Handlers/Property.luau` 19행: "process is one line (`inst[k] = v`)". 실제 `process`(311행부터)는 Tween 갈래를 포함해 약 150줄이다.

문제: 독자가 코드와 주석 중 어느 쪽이 맞는지 따로 확인해야 한다. `doc-check.py`의 시한부 서술 검사는 `.luau` 주석에 걸리지 않으므로 이런 주석은 기계로도 안 잡힌다.

제안: 위 자리를 현재형으로 고친다.

비용: 작음(주석만).

토론 요지: 네 리뷰어 모두 찬성했다. A·B는 Property 헤더 교정을 T1(분리)과 떼어 먼저 하자고 했다.

판정: **채택 권고**. BREAKING 아님.

**H-900. 게시되는 소스 주석의 원장 번호.**

상황: `H-nnn` 원장 번호가 든 주석 줄이 quad-base 614줄, quad-roblox 122줄, quad-types 54줄이다(생성 Declaration 제외). 킷 둘은 0줄이다. 많은 주석은 "왜"를 담은 좋은 주석이다. 그러나 번호만 남고 이유가 원장에만 있는 곳이 섞여 있다. 예: `quad-base/src/Fallback.luau` 63행 `-- H-231`, `quad-base/src/EpochMap.luau` 13행 `(H-72)`. 이 소스는 pesde로 게시되고 upstream도 공개다. 공개 문서에는 원장 번호를 금지하는 규약이 있지만(`base/docs-handover-registry.md`, round13 Q138·`H-722`) 소스 주석에는 규약이 없다.

문제: 외부 기여자에게는 번호가 아무 뜻을 주지 못한다. 반대로 내부 작업에는 grep 앵커로 값이 있다.

제안: 정책 하나를 정한다 — §4 Q188.

비용: 점진 갈래는 파일마다 작다. 일괄 갈래는 중간이고 blame을 흔든다.

토론 요지: 넷 모두 일괄 정리는 반대하고 "파일을 만질 때 번호만 남은 주석을 이유 문장으로"를 권했다. B는 킷에 번호가 0인 것이 번호 없이도 되는 증거라고 했고, D는 일괄 정리가 git blame을 오염시킨다고 했다.

판정: **사용자 판단**(Q188). BREAKING 아님.

**H-901. `quad-roblox/src/Handlers/Property.luau`가 속성 쓰기와 Tween 재생 상태기계를 한 클로저에 담는다.**

상황: `install`(91행부터) 안에 평범한 쓰기와 Tween 재생이 함께 있다. Tween 재생은 `tweenSlots`, `fire`(138), `settle`(178), `announce`(207), `snap`(222), `tweenRetractor`(229), `buildInfo`(277)이다. `process`(311행부터)는 `isTween` 갈래로 둘을 오간다. B는 "쓰고 → 재진입 양보 → settle → 기록 → 콜백" 모양이 세 경로에서 반복된다고 짚었다.

문제: 하나가 두 일을 한다(B2). Tween 콜백 구조를 다시 팔 때(`research/tween-callback-structure.md`) 평범한 쓰기 경로까지 함께 흔들린다.

제안: Tween 재생을 형제 파일로 뗀다.

비용: 중간. spec 여럿이 `getfenv(installProperty).game/TweenInfo/Enum` 이음매에 묶여 있다(C·D 실측: `quad-roblox/test/spec.tweenproperty.luau` 30행 근처, `spec.handlers.luau` 56행 근처 등).

토론 요지:
- A·B: 수정. 헤더 교정(H-899)을 먼저 하고, 분리는 이음매를 풀 수 있을 때.
- C: 수정. 3.4 뒤 quad-mock과 연계.
- D: 반대. Tween은 Property의 값 갈래이고, 이음매를 흔드는 비용이 크다.

판정: **보류**. 헤더 교정은 H-899가 맡는다. 분리는 quad-mock(H-906)이나 spec 이음매 정리와 함께 다시 본다. BREAKING 아님.

**H-902. `quad-base/src/Dispatch/init.luau`의 `Init`(159~704행)이 서로 다른 일 넷을 한 클로저에 담는다.**

상황: 한 클로저 안에 넷이 있다.
- 핸들러 레지스트리와 버킷(175~228, 485~565)
- 진단 메시지 생성(`brandNamesOf`/`noMatchMessage`, 242~298)
- 체인 부기(`process`/`retractRange`)
- `drive`(573~646)

진단과 레지스트리는 `module.debug`·`module.BrandPredicates` 말고는 클로저 상태에 거의 기대지 않는다.

문제: 707줄 파일에서 응집 단위를 찾기 어렵다. 순수 조각도 클로저 안에 있어 따로 시험할 수 없다.

제안: `Slot/init.luau`가 이미 쓰는 "형제 파일에 `(S, module)`로 설치" 패턴으로 진단과 레지스트리를 파일로 나눈다. 본문을 합치는 게 아니라 나누는 것이라 B2와 충돌하지 않는다. `drive`는 나누지 않는다. "drive가 Ref 등 서브시스템을 모르게" 하는 구조 변경이 이미 `research/drive-hook-plan.md`(사용자 결정: 백로그)에 있어서, 지금 나누면 그 계획이 다시 나눈다(B의 지적).

비용: 중간.

토론 요지:
- A: 조건부 찬성. 진단·레지스트리만, 그리고 그 조각에 단독 spec을 쓸 구체적 후보가 있을 때.
- B: drive-hook-plan 결정 뒤로.
- C·D: 찬성. C는 새 가변 공유 테이블보다 명시적 인자 전달을 권했다.

판정: **채택 권고(범위 한정)**. 3.4 뒤 진단·레지스트리만 나눈다. `drive`는 drive-hook-plan 결정에 붙인다. BREAKING 아님.

**H-903. Bookkeeping 머리가 말하는 계층과 실제가 어긋난다.**

상황: `quad-base/src/Bookkeeping.luau` 8~10행은 "의존 방향은 {Slot, Dispatch} -> Bookkeeping, 이 모듈은 둘 다 모른다(SlotBrand 프로브는 브랜드 판별일 뿐)"라고 쓴다. 그런데 본문은 Slot 필드를 직접 다룬다: `ownerKey._bk`(139·142), `ownerKey.Offset:Get()`(190), `ownerKey.Length:Get()`/`:Set(sum)`(295~296). 거꾸로 `quad-base/src/Slot/init.luau` 592~594행은 `module.Bookkeeping.claimOwnerAt = S.claimOwnerAt`처럼 Bookkeeping 공개 네임스페이스에 함수를 사후에 꽂고 따로 태깅한다. 그래서 공개 표면 `QuadTypes.Bookkeeping`의 멤버가 두 파일에서 생긴다.

문제: 주석이 계층을 잘못 알려 준다.

제안:
- (a) 머리 주석을 실제에 맞춘다. Slot 소유자를 위한 자리 셋과, Slot이 꽂는 둘을 적는다.
- (b) Slot이 주입하는 어댑터로 옮기는 것은 새 메커니즘이다.

비용: (a)는 작음.

토론 요지: 넷 모두 (a) 찬성. (b)는 C·D가 B1 위반(관측된 장애 없음)으로 반대했고 A·B는 사용자 결정 거리로 남겼다.

판정: (a) **채택 권고**, (b) **기각**(관측된 문제 없음). BREAKING 아님.

**H-904. 같은 `@self/Ref` 문자열이 두 모듈을 가리킨다.**

상황: `quad-base/src/init.luau` 20행의 `RefModule = require("@self/Ref")`는 `Ref/init.luau`(값 타입)이다. `quad-base/src/Dispatch/init.luau` 48행의 `RefPrePass = require("@self/Ref")`는 `Dispatch/Ref.luau`(drive 선행 패스)다.

문제: grep과 코드 탐색에서 같은 모듈처럼 읽힌다. `Dispatch/Ref.luau` 머리가 "왜 Dispatch 밑에 사나"를 따로 설명해야 했다는 것 자체가 그 혼란의 방증이다.

제안: `Dispatch/RefPrePass.luau`로 파일 이름만 바꾼다(내부 경로). 옛 이름 인용은 conventions의 `옛 \`X.luau\`` 표기를 따른다.

비용: 작음.

토론 요지: 넷 모두 찬성.

판정: **채택 권고**. BREAKING 아님.

**H-905. 공개 표면 태깅(`Err.setFuncLevel`) 누락을 잡는 검사가 없다.**

상황: Dispatch만 조립된 표면 테이블을 순회해 태깅한다(`quad-base/src/Dispatch/init.luau` 664~672행). 그 주석은 스스로 "손으로 쓴 목록은 조용히 어긋나고, 빠진 항목은 아무것도 실패시키지 않은 채 blame을 떨어뜨린다"고 적는다. 나머지 quad-base는 `setFuncLevel` 호출 40곳이 손 나열이다(예: `Slot/init.luau` 606~625). 공개 메소드를 새로 넣고 태그를 빠뜨리면 blame이 quad 내부 파일로 가는데 아무 검사도 실패하지 않는다. `getFuncLevel`은 이미 있지만 쓰는 spec은 `spec.errorutil`뿐이다.

제안: 제품 코드는 바꾸지 않는다. spec 하나가 각 공개 테이블·메타테이블의 밑줄 없는 함수 필드를 순회하며 SURFACE 레벨인지 단언한다. B의 단서대로, spec이 공개 목록을 다시 손으로 들면 의미가 없으니 테이블 순회여야 한다. 일부러 태깅하지 않는 함수가 있으면 spec 안에 예외 목록으로 적는다.

비용: 작음.

토론 요지: 넷 모두 찬성. A는 3.4 전에 해도 된다고 했다.

판정: **채택 권고**. BREAKING 아님.

**H-906. 두 킷의 `test/support`가 사실상 같은 사본이고, quad-roblox·킷 테스트가 quad-base의 테스트 내부를 상대 경로로 끌어온다.**

상황:
- `quad-roblox-material/test/support`와 `quad-roblox-devui/test/support`의 `gen-reflection.py`·`mirror.py`·`reflection.luau`는 diff가 없다. `harness.luau`는 몇 줄만 다르다. material만 `IsMouseButtonPressed` mock을 갖는다.
- `quad-roblox/test/spec.events.luau` 20행 등과 킷 하네스는 `../../quad-base/test/mock`을 직접 require한다.
- 근거 문서: `feedback/consumer-kits-2026-10-05.md` B1·B2. ROADMAP 백로그 `quad-mock`이 이미 있다.

문제: 하네스를 고칠 때 두 사본을 손으로 맞춰야 하고 이미 갈라지기 시작했다. 그리고 레포 밖 사용자에게는 자기 컴포넌트를 시험할 길이 사실상 없다.

제안: 새 발견이 아니라 우선순위 근거다 — 소비자 둘이 같은 하네스 약 700줄을 따로 유지하고 있다. quad-mock 착수 시기와, 그 전까지의 정본 지정은 §4 Q193.

비용: 정본 지정은 작음. quad-mock은 중간~큼.

토론 요지: 넷 모두 찬성. A는 새 패키지 신설 없이 정본 지정까지만 하자고 했다.

판정: **사용자 판단**(Q193). BREAKING 아님.

**H-907. 두 킷의 `src/Quad.luau`가 같고 재수출 40여 줄을 손으로 유지한다.**

상황: `quad-roblox-material/src/Quad.luau`와 `quad-roblox-devui/src/Quad.luau`는 diff가 없다(65줄). `<C>Modifier`·`Into<C>` 재수출을 손으로 적는다.

판정자 확인: 3.4.0 Declaration 트랙이 클래스별 재수출 125개를 타입 함수 제네릭으로 대체하기로 이미 정했다(`research/declaration-surface-plan.md` 96~98행). 그러니 목록 자체는 그 트랙이 줄인다. 남는 빈칸은 "quad 위에 라이브러리를 얹는 법" how-to다(`feedback/consumer-kits-2026-10-05.md` C1). 라이브러리도 자기 설정 모듈에서 `UseProvider`를 거는지, require 경로를 어떻게 바깥에 맡기는지, 설치본이 다르면 값이 안 섞인다는 것을 어떻게 알리는지 — 아직 문서가 없다.

제안: 3.4 뒤 how-to 한 절을 쓴다.

비용: 작음.

토론 요지: C가 처음 낸 "quad-roblox가 프로바이더가 설치된 번들 진입점을 낸다"는 넷 모두 반대했다(설정 모듈 관례를 바꾸는 새 표면). C도 철회했다.

판정: **채택 권고(문서만)**. BREAKING 아님.

**H-908. `quad-roblox-material/src/ListReorder.luau`의 `new`(220~907행)가 687줄 클로저 하나다.**

상황: 한 클로저 안에 드래그, 엣지 오토스크롤, 키 탐색, 높이 기반 배치, 대기·취소 상태가 상위값을 공유한다. 같은 킷은 `DatePicker/Calendar`·`TimePicker/Clock`·`ColorModel`을 순수 모듈 + `spec.pure.*`로 이미 나눠 둔다.

제안: 기하(대상 인덱스·배치)부터 순수 모듈로 뗀다(B안). 드래그·스크롤·키 탐색 분리(C안)는 그다음 단계다.

비용: 중간(상위값이 얽혀 한 번에 못 뗀다). 킷 내부다.

토론 요지: 넷 모두 찬성. 기하부터 단계적으로 하자는 데 수렴했다.

판정: **채택 권고(킷 내부, 3.4 뒤)**. BREAKING 아님.

**H-909. 두 킷이 Overlay·Interaction·바깥 클릭 처리를 각자 구현했다.**

상황: 두 킷이 같은 관용구를 각자 만들었다.
- "죽지 않는 기본 레이어": devui `Overlay.getDefault()` 대 material `Overlay.default()`
- 포인터·호버·누름 추적: material은 PreRef 기반 `Interaction.new{…}`, devui는 PostRef 기반 `Interaction.hover()`/`drag{…}`
- 바깥 클릭 처리: material `Util.clickSink`, devui `PopupHits.covers`

계약과 이름도 갈렸다(`Disabled` 대 `Enabled`, `OnPressBegan` 대 `OnBegin`, `Content`가 Instance인지 builder인지). `docs/how-to/09-overlays-modal-toast.md`에는 열림 상태·트리거·토스트·에러 모달은 있다. 그러나 모듈 싱글턴 레이어가 첫 호스트와 함께 죽는 문제(`feedback/consumer-kits-2026-10-05.md` C2), 바깥 클릭, Escape 스택은 없다.

갈래:
- (가) quad-roblox나 별 패키지로 공통 메커니즘을 올린다 — 새 공개 표면.
- (나) 킷마다 두고 how-to 09에 레시피를 보탠다.
- (다) 그대로.

토론 요지: 넷 모두 (나)로 수렴했다. B는 디자인 언어가 다른 별 패키지라 B2상 합치지 말자고 했고, C·D는 처음 낸 승격 제안을 토론에서 철회했다. A는 승격은 사용 사례가 더 모인 뒤에 보자고 했다.

판정: **(나) 채택 권고**. (가)를 열지 여부는 §4 Q189. 킷 사이 이름 통일(`Enabled`/`Disabled`)은 킷 이름 결정과 같은 자리라 여기서 정하지 않는다. BREAKING 아님.

**H-910. 파일 중간의 require.**

상황: `quad-base/src/Tag.luau` 250행 `local InitDispatch = require("./Dispatch")`, `quad-base/src/Attr/init.luau` 62행·227행이 파일 중간에 require한다. 그리고 `quad-base/src/Ref/init.luau`는 `Init = registerDispatchHandlers`로 내보내 다른 모듈의 `Init` 관례와 이름이 다르다.

판정자 확인: `Dispatch/init.luau`는 Tag를 직접 require하지 않는다. 그래서 순환 회피인지는 확인하지 못했다.

제안: 의도를 확인해서, 맞으면 한 줄 주석을 달고 아니면 위로 모은다.

비용: 작음.

토론 요지: B·C·D는 찬성 또는 수정, A는 이름 불일치는 빼도 된다고 했다.

판정: **채택 권고(낮음)**. BREAKING 아님.

**H-911. Effect의 상태 플래그 군에 전이 표가 없다.**

상황: `quad-base/src/Effect.luau`가 `_running`·`_pending`·`_cleanupRunning`·`_dying`·`_rerunRequired`의 조합으로 상태기계를 표현한다. 재실행 경로는 한 함수가 여러 조건으로 갈린다. 줄마다 주석은 정확하지만 불변식을 한눈에 보여 주는 표가 없다.

제안: 머리 주석에 "상태 × 사건 → 동작" 표 하나. A의 단서대로, 표가 코드와 어긋나지 않게 칸마다 그 동작을 고정하는 spec 케이스를 같이 적는다. 본문을 합치는 게 아니라 문서화다.

비용: 작음.

토론 요지: 넷 모두 찬성.

판정: **채택 권고**. BREAKING 아님.

**H-912. 코어 모듈 인스턴스가 `module: any`로 흐른다.**

상황: `Init(module: any)`가 38곳이고 `Impl` 메소드의 `self: any`가 거의 전부다. `Slot/types.luau`는 `S`에 이름 있는 타입을 줘서 오타·인자 수를 타입 에러로 만들었는데, 같은 처방이 모듈 인스턴스에는 없다.

문제: `module.Backend.canExecut` 같은 오타가 런타임 nil 호출이 된다.

제안: 내부 모듈 타입 하나.

비용: 중간~큼. 신 솔버 복잡도 한도 위험이 있다(`base/typing-limits.md`).

토론 요지: 넷 모두 반대 또는 보류. 공개 표면은 quad-types가 이미 통제한다.

판정: **보류**. 한 파일에서 한도 실측이 나오기 전에는 후보로 올리지 않는다. BREAKING 아님.

**H-913. 킷의 큰 컴포넌트 함수와 devui `Style.luau`.**

상황: 큰 함수와 파일이 여럿이다. `Dialog.open` 329줄, `Slider(props)` 301줄, `Overlay.new` 298줄, devui `Style.luau` 653줄. 킷은 `Switch/Behavior.luau`·`Slider/Behavior.luau` 분리 관례를 일부에만 적용했다.

토론 요지: A·B·D는 반대했다(관측된 문제 없음, 억지 분리는 인자 전달만 늘림). C는 우선순위 낮은 찬성이었다.

판정: **기각**(B1). 컴포넌트를 새로 만들거나 크게 고칠 때 그 관례를 따르는 정도로 충분하다. BREAKING 아님.

**H-914. spec 하네스의 공용 헬퍼 복제와 비공개 필드 직접 읽기.**

상황: `probe`가 quad-base/test 다섯 파일에 복제돼 있다. spec이 `._elements`·`._materializing`·`._subs` 등을 직접 읽는다.

토론 요지: B·C·D는 반대했다. A는 `probe`만 mock으로 올리자고 줄였다.

판정: **기각**. 비공개 필드 읽기는 H-902가 나뉜 뒤에야 의미 있게 바뀐다. 헬퍼 복제는 quad-mock(H-906) 때 함께 흡수된다. BREAKING 아님.

## §3 DX 빈칸

**H-915. `q.debug` 진단이 맨 `print` 열여덟 곳으로 흩어져 있다.**

상황: 진단은 quad-base 열넷과 quad-roblox 넷이다.
- quad-base: `Source.luau` 53, `State.luau` 112, `Observer.luau` 129, `Slot/init.luau` 102, `Slot/List.luau` 362, `Dispatch/init.luau` 117·532, `Debounce.luau` 141·366, `Claim.luau` 144·204, `DebugKeyFilter.luau` 53, `init.luau` 193
- quad-roblox: `Tween.luau` 112·114·123, `Animate.luau` 63

기존 결정: `base/error-id-plan.md` 91행은 "debug print 경고엔 ID를 안 붙인다 — 필요가 드러나면 그때"다.

그 뒤 생긴 증거: quad-base·quad-roblox spec 열 개와 킷 하네스 둘이 전역 `print`를 갈아 끼워 진단을 잡는다(`quad-roblox-material/test/support/harness.luau` 21행 "`print` captured (quad's `q.debug` diagnostics are prints)"). Studio에서는 print라 경고색도 아니다.

갈래:
- (a) 내부 헬퍼 하나로 출력을 모은다. 공개 표면이 없고, 출력 채널을 한 자리에서 바꿀 수 있다.
- (b) 진단에도 번호를 준다(기존 결정 재개).
- (c) 진단을 받는 공개 훅.

비용: (a)는 작음.

토론 요지: 넷 모두 (a)로 수렴했다. 번호를 먼저 냈던 A는 기존 결정을 못 보고 낸 것이라며 철회했다. 네 리뷰어 모두 "(a)는 '필요가 드러난' 경우"라고 봤다.

판정: (a) **채택 권고**. (b)·(c)는 §4 Q190. BREAKING 아님(메시지는 API가 아님, D3).

**H-916. 배열 자리의 함수 값에 `Quad0076` 꼬리가 엉뚱한 곳을 가리킨다.**

상황: `D.Frame { D.TextLabel }`처럼 괄호를 빠뜨리거나, 호출하지 않은 컴포넌트를 숫자 키 자리에 넣으면 이렇게 된다. 브랜드가 없고 키가 숫자라 `quad-base/src/Dispatch/init.luau` 289~290행 갈래를 탄다. 그 꼬리는 "check that the provider for this value (e.g. quad-roblox) is initialized"라서 사용자는 프로바이더 설정을 의심하게 된다. 그 위치에 함수를 받는 핸들러는 없다(판정자가 `isHandlable` 전수 확인).

제안: `noMatchMessage`에 `type(v) == "function"` 갈래 하나를 둔다 — 컴포넌트나 선언자를 호출하지 않았는지 묻는 문구. base는 엔진 어휘를 모르므로 문구는 중립으로 쓴다. 에러를 만들 때만 도는 차가운 경로라 평소 비용은 0이다.

비용: 작음. 같은 커밋에서 `docs/reference/errors/02-dispatch-bookkeeping.md`의 Quad0076 "고치려면"에 한 줄.

토론 요지: 넷 모두 찬성.

판정: **채택 권고**. BREAKING 아님.

**H-917. `Quad0076`이 실패한 요소(클래스·이름)를 말하지 않는다.**

상황: D는 깊은 트리에서 어느 요소인지 모른다고 제기했다.

판정자 확인: 요소 생성은 즉시이고 오류는 SURFACE 태깅으로 사용자 호출 줄을 가리킨다(`Dispatch/init.luau` 432행). 그러니 blame 줄이 곧 그 요소다.

토론 요지: 넷 모두 반대했다. C·D는 엔진 중립 base가 `ClassName`을 읽는 것도 B3와 어긋난다고 덧붙였다.

판정: **기각**. BREAKING 아님.

**H-918. 프레임 구동 애니메이션을 material 킷이 손으로 일곱 번 짰다.**

상황: `RunService.Heartbeat:Connect`가 일곱 곳이다: `Radio.luau` 148, `Checkbox.luau` 122, `Ripple.luau` 317, `Navigation/Motion.luau` 63, `AppBar/Scroll.luau` 209, `Progress/Loop.luau` 59, `ListReorder.luau` 561. 정작 `Tokens/Motion.luau` 18행은 "per-frame Heartbeat driver — not worth it"이라 적는다. "보일 때만 연결"을 제대로 한 것은 `Progress/Loop.luau`뿐이다.

이미 있는 자리: ROADMAP 백로그의 렌더 스텝 op(`onStep`), `research/spring-plan.md`, 연결 cleanup 슈거 `Disconnector`(가칭), 레퍼런스 core/10의 Heartbeat 예제(216행 근처). 수명에 묶는 기본형은 있지만 "보일 때만"은 없다.

제안:
- (a) 킷 안에서 `Navigation/Motion.luau`의 드라이버를 공용으로 올린다. B의 단서: "목표까지 보간하고 도착하면 끊는" 좁은 형태(Radio·Checkbox·Motion)만 모으고, Loop·Ripple은 정지 조건이 달라 따로 둔다.
- (b) `onStep` 백로그에 "소비자 킷 하나에서 일곱 번"을 근거로 적는다.

비용: (a) 중간(킷 내부), (b) 작음.

토론 요지: 넷 모두 찬성. 새 공개 표면은 아무도 제안하지 않았다.

판정: **채택 권고**. BREAKING 아님.

**H-919. "불린 State로 두 값 중 고르기" Compute가 킷 둘에 43번.**

상황: 패턴은 `x:Compute(function(self, _prev, a, b) return if self:Get() then a:Get() else b:Get() end, A, B)`다. 한 줄짜리로 센 것만 43건이고 여러 줄 변형은 더 있다. `backlog/additional-operator-sugar.md`의 `IfElse`가 이미 "타입 표면 결정 필요"로 백로그다.

제안: 새 항목이 아니라 그 문서에 실측 근거를 더한다.

비용: 작음.

토론 요지: 넷 모두 찬성.

판정: **채택 권고(근거 기록)**. BREAKING 아님.

**H-920. `table.unpack(Util.hooks(props.Hooks))` 43번과 "마지막 자리여야 한다" 함정.**

상황: material 킷의 숫자 키 끝에 이 꼴이 43번 나온다. `quad-roblox-material/src/Button/Group.luau` 447행 주석은 "두 번째 `table.unpack`은 잘린다"며 배열을 하나로 합치는 우회를 적는다.

이미 있는 자리: `research/component-flatten-sugar-plan.md`(`q.Spread`, 5절 대부분 닫힘)와 `feedback/consumer-kits-2026-10-05.md` C7.

제안: 그 계획에 근거로 더한다.

비용: 작음.

토론 요지: 넷 모두 찬성.

판정: **채택 권고(근거 기록)**. BREAKING 아님.

**H-921. 킷 prop 검증 에러가 형식 없는 문자열이다.**

상황: 킷 둘의 `error(...)` 호출은 70여 곳이다. 레벨이 2(41)·3(20)·4(3)로 섞였는데, 일부는 헬퍼 깊이 때문에 의도적일 수 있다. 예: `Checkbox.luau` 94, `NumberField.luau` 93·96, `ColorPicker/Material/Model.luau` 113. 문구에 컴포넌트 이름 형식이 없고 번호도 없다. 입구 한 줄 검사 자체는 B1 보정상 평소 경로에 둬도 된다.

제안: 킷 내부 `Util.fail(component, msg)` 하나로 형식과 레벨을 모은다.

비용: 작음.

토론 요지: 넷 모두 찬성. 킷 에러에 번호를 줄지는 사용자 결정으로 남겼다.

판정: **채택 권고(킷 내부)**. 번호는 §4 Q191. BREAKING 아님.

**H-922. 컴포넌트 prop 오타가 조용히 무시된다.**

상황: `Button({ Text = "x", OnClik = fn })`이 strict를 통과한다(Luau에 초과 프로퍼티 검사가 없다). 선택 prop 오타는 그냥 사라진다(`feedback/consumer-kits-2026-10-05.md` A6, 그 뒤 해법 없음).

제안: 킷 내부 `Util.checkProps(props, { … })`를 `q.debug`일 때만, 생성 시 한 번 부른다(핫 패스 아님).

비용: 컴포넌트마다 키 목록을 유지해야 해서 중간. 그래서 새 컴포넌트부터.

토론 요지: 넷 모두 킷 내부로 수렴했다. quad 쪽 공개 헬퍼는 새 표면이라 넷 다 반대했다.

판정: **채택 권고(킷 내부, 새 컴포넌트부터)**. BREAKING 아님.

**H-923. `Slot:List`의 `ctx` 타입에 공개 이름이 없어 킷이 `RowCtx`를 네 번 다시 선언한다.**

상황: 재선언 자리는 `quad-roblox-material/src/List.luau` 358, `ListReorder.luau` 204, `quad-roblox-devui/src/Combo.luau` 109, `Table.luau` 72다. quad-types도 `:List`(561행)와 `:Single`(575행) 시그니처에 같은 모양을 인라인으로 두 번 적는다.

판정자 확인: `quad-types/src/init.luau` 535~536행이 **일부러** 별칭을 빼지 않았다. `Slot<T>`↔`SlotElement<T>` 재귀 그룹 안에서 메소드 제네릭을 받는 별칭은 "다른 파라미터의 재귀"로 거부된다. 재귀 그룹 **밖**에 소비자용 별칭을 따로 두는 건 될 수도 있지만 실측 전이다. 레퍼런스 core/06(452행 근처)은 "ctx 타입이 길면 파일 안에 별칭을 두라"고 안내한다.

문제: 새 공개 이름이고, 안 되는 이유가 이미 한 번 확인된 자리다.

제안: 신 솔버(test.sh 한도 플래그 셋 그대로)로 그룹 밖 별칭을 먼저 실측한다. 되면 이름을 사용자가 정한다.

비용: 실측은 작음.

토론 요지: 넷 모두 "실측 대기"로 수렴했다.

판정: **보류(실측 대기)**. 실측 뒤 §4 Q192. BREAKING 아님.

**H-924. `T | State<T>` prop을 State로 정규화하는 관용구가 문서에 없다.**

상황: material `Util.luau` 27~50행이 `asState`(불린)·`asNumberState`·`asStringState`를 두고 54곳에서 쓴다. 타입별로 나뉜 것은 제네릭 판이 하한 문제(`feedback/consumer-kits-2026-10-05.md` A1, 2026-10-06 사용자 결정 정본 `StateMarker<T>` + 캐스트)에 걸리기 때문이다. `docs/how-to/01-component-conventions.md`에는 "값이나 State를 받는 prop"의 정규화 레시피가 없다.

갈래:
- (a) how-to 01에 타입별 헬퍼 레시피.
- (b) `q.ToState` 공개 슈거 — 새 표면이고 제네릭 하한 문제가 있다.

비용: (a)는 작음.

토론 요지: 넷 모두 (a)만 찬성하고 (b)는 반대했다.

판정: (a) **채택 권고**, (b) **기각**. BREAKING 아님.

**H-925. 엔진 값을 "같은 값"으로 되돌릴 땐 `:Set`이어야 한다는 문장이 레퍼런스에 없다.**

상황: TextField `MaxLength`는 `OnChange`에서 잘라 원천에 되쓴다. 원천이 이미 한도 값이면 잘린 문자열이 원천과 같아 `SetIfChanged`는 아무 일도 안 하고, TextBox엔 넘친 글자가 남는다. `:Set`(같은 값도 전파 — C5 원칙)이라야 `Text = value` 바인딩이 엔진 쪽을 되돌린다(`feedback/consumer-kits-2026-10-05.md` C5).

`docs/reference/roblox/05-onchange.md` 167행은 되쓰기가 `SetIfChanged`라는 것과 그 이유만 적는다. `docs/how-to/02-form-validation-pattern.md`에도 이 경우가 없다.

제안: onchange 레퍼런스에 한 문장, how-to 02에 예 하나.

비용: 작음.

토론 요지: 넷 모두 찬성.

판정: **채택 권고**. BREAKING 아님.

**H-926. 반응형 그래프 내성 도구(누가 구독하나, 왜 다시 돌았나)가 없다.**

상황: 구독자는 비공개 `_subs`이고 공개 질의가 없다. spec이 `._subs`를 직접 읽는다.

판정자 확인: `research/debug-tooling-plan.md` "핵심 설계 방향" 1절이 "무엇이 무엇에 연결됐는가"(사용자 확정)를 quad-debug UX로 이미 갖고 있다. 그 문서의 우선순위는 사용자가 정한 "quad 개발 완료 전엔 착수 못 함"이다.

토론 요지: A는 코드 수준 읽기 질의를 그 계획의 첫 단계로 앞당길지만 묻자고 했다. B·C·D는 반대했다(이미 계획이 쥐고 있고, 앞당길 근거가 없음).

판정: **기각(새 항목으로는)**. 필요하면 그 계획서에 "코드 수준 질의를 첫 단계 후보로"라는 한 줄만 더한다. BREAKING 아님.

## §4 사용자 문항

**Q188. 게시되는 소스 주석의 원장 번호를 어떻게 할까**(H-900).

이 레포의 `.luau` 주석에는 `H-nnn`·`Q`·`round`·마일스톤 번호가 800줄 가까이 있다. 소스는 pesde로 게시되고 upstream도 공개라 외부 기여자도 읽는다. 공개 문서에서는 같은 번호를 이미 금지했다.

- **(가) 지금대로 둔다.** 번호는 내부 grep 앵커로 값이 있고 바깥 독자에겐 무해한 잡음이라는 판단이다.
- **(나) 파일을 만질 때 번호만 남은 주석을 이유 문장으로 바꾼다.** 이유가 이미 적힌 주석의 번호는 둬도 된다. 일괄 작업이 아니라 규약 한 줄이다. 네 리뷰어 모두 이쪽을 권했다.
- **(다) 한 번에 일괄 정리한다.** 가장 깨끗하지만 blame이 흔들리고 작업량이 크다.

판정자 권고는 (나)다.

**Q189. 두 킷의 Overlay·Interaction을 공통 층으로 올릴 길을 열어 둘까**(H-909).

두 킷이 "죽지 않는 기본 레이어", 호버·누름 추적, 바깥 클릭을 각자 구현했고 계약과 이름이 갈렸다.

- **(가) quad-roblox나 별 패키지에 공통 메커니즘을 둔다.** 새 공개 표면이다. 소비자마다 같은 바퀴를 다시 만들지 않게 된다.
- **(나) 킷마다 두고 how-to 09에 레시피(죽지 않는 레이어·바깥 클릭·Escape 스택)만 보탠다.** 승격은 세 번째 소비자가 같은 모양을 원할 때 다시 본다. 네 리뷰어 모두 수렴했고 판정자 권고도 이것이다.
- **(다) 그대로.**

**Q190. `q.debug` 진단 출력에 번호나 공개 수신 훅을 줄까**(H-915).

내부 헬퍼로 출력을 모으는 것(H-915 (a))은 공개 표면이 없어 채택 권고다. 그 위에 얹을 것을 고르는 문항이다.

- **(가) 헬퍼까지만.** `base/error-id-plan.md` 91행의 "경고엔 ID 없음"을 유지한다.
- **(나) 진단에도 번호를 주고 `docs/reference/errors/`에 절을 둔다.** 2026-09-22 결정을 다시 여는 것이다. 근거는 spec·하네스 열둘이 print를 가로채고 있다는 것과, 사용자가 진단 문구로 문서를 찾을 수 없다는 것이다. "경고 코드"라는 두 번째 체계가 생긴다.
- **(다) 진단을 받는 공개 훅**(가칭 `q.debug`의 출력 지정). 테스트와 devui 패널이 print를 갈아 끼우지 않고 진단을 받는다. 새 공개 이름이다.

판정자 권고는 (가)다. 리뷰어 넷 모두 (나)·(다)를 지금 열지 말자는 쪽이었다.

**Q191. 킷 에러에 번호를 줄까**(H-921).

킷 내부 `Util.fail`로 형식과 레벨을 모으는 것은 채택 권고다.

- **(가) 형식만 통일한다**(`Kit:Component: …`).
- **(나) 킷마다 자기 번호 체계와 문서 절을 둔다.** quad의 `QuadNNNN`과 대역이 겹치지 않게 접두를 따로 둔다. 소비자가 에러 문구로 킷 문서를 찾을 수 있게 되지만, 킷 문서와 검사 스크립트가 늘어난다.

판정자 권고는 (가)다. 킷은 아직 도그푸딩 단계다.

**Q192. `Slot:List`/`:Single`의 `ctx`에 공개 타입 이름을 줄까**(H-923, 실측 뒤).

`quad-types`는 재귀 그룹 제약 때문에 일부러 별칭을 빼 두었다.

- **(가) 그룹 밖 소비자용 별칭이 신 솔버에서 통과하는지 실측하고, 되면 공개 이름을 붙인다.** 킷 네 곳의 재선언이 사라진다. 이름은 사용자가 정한다.
- **(나) 지금처럼 "파일 안에 별칭을 두라"는 core/06 안내만 유지한다.**

실측은 싸다. 판정자는 (가)의 실측까지는 권하고, 이름은 결과를 본 뒤에 정하자고 권한다.

**Q193. quad-mock 착수 시기와 그 전까지의 하네스 사본**(H-906).

두 킷이 같은 테스트 하네스(약 700줄)를 따로 들고 있고 이미 갈라지기 시작했다. 레포 밖 사용자에게는 자기 컴포넌트를 시험할 길이 없다.

- **(가) 3.4.0 직후 quad-mock을 착수 1순위 근처로 올린다.**
- **(나) quad-mock은 백로그 순서대로 두되, 그 전까지 material 쪽 `test/support`를 정본으로 정하고 devui는 사본임을 표시한다**(드리프트만 막는다).
- **(다) 그대로.**

판정자 권고는 (나)를 지금, (가)는 3.4 뒤 우선순위 회의 때 다시 보는 것이다.

## §5 떨어뜨린 것

- **OnChange.luau 모듈 전역 `errNS`**(B): 의도가 주석(54~56행)에 있고 관측된 사고가 없다. 리뷰어 본인도 구조 변경을 권하지 않았다.
- **Slot `S` 테이블이 `any`로 소거됐다**(C): 사실과 다르다. `quad-base/src/Slot/types.luau`의 함수 필드는 인자 이름·개수가 적힌 시그니처이고 `any`는 원소 값 자리다. 머리가 사용자 결정(round3 Q29)을 인용한다.
- **Modifier `flatten`을 별 파일로**(C): flatten은 Modifier 내부를 아는 코드라 B3("객체를 아는 곳은 그 객체가 선언된 곳")상 지금 자리가 맞다.
- **공변 읽기 전용 뷰 타입 `ReadState<T>`**(C): 2026-10-06 사용자 기각. 정본은 `StateMarker<T>`로 받고 본문에서 캐스트하는 것이다(`feedback/consumer-kits-2026-10-05.md` 머리 회신).
- **Effect cleanup `return nil` 허용**(C·D): round13 Q145가 닫혔다. 옵셔널 반환은 반환문 없는 함수를 거부하는 맞바꿈이라는 것이 실측으로 반증됐다(round14 원장 77행).
- **죽은 호스트 Slot CRUD를 평소 경로 에러로**(C·D)·**`q.isAlive`/`q.isClaimed` 탑레벨**(C): 2026-10-06 사용자 결정 — debug에서만 claim을 확인하고, 공개 "호스트 생존" 질의는 안 한다.
- **`Parent` 키 전용 에러 문구**(D): `H-148`이 특별 문구 없음으로 정했다. `docs/reference/errors/02-dispatch-bookkeeping.md` Quad0076 "고치려면"이 `Parent`를 이미 다룬다.
- **`q.Not` 탑레벨**(D): `Operator.Not`이 있어 같은 일 하는 두 번째 경로가 된다. 킷의 `negate`는 4곳이다.
- **`Source:Toggle()`/`:Update(fn)`**(D): 킷 전체에 3곳뿐이고 코어 값에 새 메소드다(B1).
- **제네릭 `State<T>` 컴포넌트 문서**(D): `docs/how-to/01-component-conventions.md` 314행에 레시피가 이미 있다.
- **`:Apply` 반환 `any`**(D): 솔버 한계로 `base/typing-limits.md`가 이미 추적한다.
- **기본 Modifier와 `props.Modifier` 순서 문서**(D): how-to 01의 61행·114행에 이미 있다.
- **핸들러 계층 값 목록 둘을 합치기**(A): Modifier 필드 자리와 Slot 원소 자리는 허용 집합이 다른 질문이다(Slot은 Slot을 받는다). B2상 합치지 않는다.
- **Effect 에러 쌍 문서 묶기·배열 전용 가드 팩토리**(A): 리뷰어 본인이 코드 후보가 아니라 했다. 가드 셋은 문구와 코드가 각자다.
- **`distinct` 파생·한 컴포넌트가 루트 여럿과 Effect를 돌려주기·인라인 `:Compute` strict 거부**(B): 각각 `feedback/table-sim-2026-10-16.md` C2, `research/component-flatten-sugar-plan.md` 5절, `base/typing-limits.md` 8.13이 이미 추적한다.
- **`_reentryFrames`를 공급자 계약으로 타입에 올리기**(A, 토론 2대 2): 사용자 결정 round14 Q174 보강 (b)로 일부러 비공개다. `quad-base/src/Observer.luau` 83행 "debug-only — read nowhere else, no public surface", `base/architecture.md` 621행.
- **quad-roblox 번들 진입점**(C): 설정 모듈 관례를 바꾸는 새 표면이다. 재수출 문제는 Declaration 트랙이 줄인다. C도 토론에서 철회했다(H-907).

미완: 없음. 단, 리뷰어 A·B가 스스로 밝힌 미독 범위(§1)는 이번 라운드가 보지 않은 곳이다.

## §6 opus 독립 한 패스와 모델별 수렴 (2026-10-18)

> **[2026-10-18 추가 — 사용자 요청]** 사용자: *"opus 로 한 패스만 돌아보자. 목적은 거의 gemini 모델 시점으로만 보았는데, opus 시점에선 어떤지 보고자 함과 동시에 어느정도 의견이 수렴되는지 보고싶음(모델별 의견 수렴?)"*. 이 절도 결정이 아니라 3.4.0 뒤에 고를 후보다.

**진행 방식.** opus 리뷰어 하나(E)를 두 단계로 돌렸다.
- 1단계: 이 원장과 `audit/code-review-2026-10-16/`을 열지 않은 채로 독립 리뷰. 범위는 §1의 A·B와 같다(생성 Declaration과 `gen-d.py` 제외). A·B가 못 봤다고 밝힌 파일을 우선해서 정독하게 했다.
- 2단계: 같은 에이전트에 이 원장을 보여 주고 대조하게 했다. 순서를 거꾸로 하면 opus가 앞선 결론에 끌려 수렴 정도를 잴 수 없어서 이 순서로 했다.

E는 1단계에서 발견 20건(O1~O20)을 냈다. 2단계에서 기존 결정과 부딪히는 것 하나를 철회했고 하나는 범위를 줄였다. 메인이 파일:줄을 직접 열어 확인한 것은 O1·O2·O6·O7·O8·O9·O10 (d)·O11·O16이다. 인용은 전부 맞았다. 나머지는 E의 확인에 기댄다.

E가 스스로 밝힌 미독 범위가 있다.
- quad-base: `Ref/*`, Store, Blocker, Debounce 본문, `Dispatch/Ref.luau`, StateHandler, `Slot/List`·Owner·Elements 본문, Bookkeeping 본문
- quad-roblox: `Handlers/Property.luau` 본문, InstanceChild, InstanceShorthand, Event
- devui: Menu, Overlay, Style, Inputs, `Window/Manager`, TitleBar
- material: 대부분(Overlay, ListReorder, TextField, Snackbar 등)

**수렴 결과.**

E의 발견 20건을 이 원장과 맞대면 이렇다.
- 같음 3건: O3·O17은 H-906, O14는 H-923.
- 부분 5건: 같은 대상인데 자리나 처방이 다르다. O8↔H-899, O9↔H-913, O13↔H-921, O15↔H-924, O19↔H-915.
- 새것 12건: 이 가운데 O12는 철회했다.

반대로 이 원장의 H 28건을 E의 1단계와 맞대면 이렇다.
- 같게 찾음: 2건.
- 다르게 찾음: 5건.
- E가 본 범위 안이었는데 놓침: 10건. H-900·H-905·H-907·H-909·H-910·H-911·H-912·H-919·H-920·H-922다. 2단계에서 근거를 다시 열어 본 뒤 전부 동의했다. H-911·H-922는 단서를 달았다(아래).
- E의 범위 밖: 11건.

판정이 갈린 곳은 셋이다. H-913 기각, H-921 처방, H-924 (b)이고, 아래에 한 문단씩 적었다. 탈락 목록 §5에는 이의가 없었다.

E 자신의 소감은 이렇다. 수렴이 높았던 것은 두 종류다.
- grep으로 셀 수 있는 파일 사이 중복: 하네스 사본, `ctx` 재선언, 킷 에러, 디버그 print.
- "새 공개 표면은 열지 말고 킷 내부나 문서까지"라는 설계 판단. 세 모델 계열이 같은 쪽으로 모였다.

수렴이 낮았던 것은 한 파일 안을 정독해야 보이는 국소 중복과 틀린 주석이다. 다만 이건 모델 차이보다 범위 차이로 보인다. E의 새것 대부분이 A·B가 못 봤다고 밝힌 파일에서 나왔기 때문이다.

반대로 코퍼스 전체를 세거나 피드백과 대조해야 얻는 DX 근거는 round15 쪽만 냈다. Heartbeat 일곱, IfElse 꼴 마흔셋, `table.unpack` 마흔셋, H-925의 `:Set` 문장이 그렇다. E의 정리는 이렇다. 단일 맥락 정독은 파일 안의 결함에 강하고, 여럿에 판정자를 붙인 구성은 횡단 세기와 문서 대조에 강해서 둘이 보완적이다.

메인이 덧붙이면, E가 범위 안에서 놓친 열 건에는 두 꼴이 있다.
- 봤지만 기존 관례나 의도로 여겨 넘긴 것.
- 봤지만 패턴으로 세지 않은 것.

같은 계열 안의 sonnet A·B도 비슷한 놓침을 자기 보고에 적었다. 그래서 이 차이를 모델 계열 탓으로 돌릴 근거는 이번 한 번으로는 약하다.

### 새 후보

번호는 이 원장의 H 순번을 잇는다. 판정은 메인 판정이다. E의 1단계 근거와 메인 확인을 합쳤고, 토론 라운드는 없었다.

**H-927. Tween·Animate 옵션 이름 목록이 다섯 자리에 손으로 적혀 있다**(O1).

상황: 같은 옵션 이름이 여러 자리에 따로 적혀 있다.
- `quad-roblox/src/Animate.luau` 43행 `FIELDS`와 44행 `CALLBACK_FIELDS`(집합 모양).
- `quad-roblox/src/Tween.luau`의 72행 `NUMBER_FIELDS`, 78행 `CALLBACK_FIELDS`(리스트 모양), 84~88행 `KNOWN_OPTIONS`, 96행 `INFO_FIELDS`.
- 같은 파일 123행의 debug 메시지. 알려진 옵션 열세 개가 문자열 리터럴로 박혀 있다.

round14 확인 패스가 `warnInfoOverlap`을 Tween 쪽 하나로 모으면서 "필드 목록과 줄이 복사돼 있었다"는 문제를 한 번 고쳤다(`Tween.luau` 92~93행). 그러나 목록 자체는 여전히 따로 산다.

문제: 옵션을 하나 늘리면 다섯 자리를 다 고쳐야 한다. 하나를 빠뜨리면 `q.debug`가 정상 옵션을 "unknown option"으로 알리는 쪽으로 조용히 어긋난다.

제안: 둘 중 하나다.
- (가) Tween이 어휘 표 하나를 쥐고, 메시지는 그 표에서 `table.concat`으로 만든다. Animate에는 `install`이 이미 넘기는 반환 테이블(`RobloxFactory.luau` 60행)에 실어 보낸다.
- (나) 메시지 문자열만 표에서 만든다.

비용: 작음. 내부 정리다.

판정: **채택 권고**(가). BREAKING 아님.

**H-928. 키별 재활용 `:List` 본문이 킷 여러 자리에 손으로 다시 쓰였고, 공용 헬퍼가 이미 있다**(O2).

상황: `quad-roblox-material/src/Chip/KeyedSlot.luau`가 "키별 재활용 `:List`" 모양을 이미 헬퍼로 갖고 있다. 모양은 이렇다.
- KeyGone이면 nil을 돌려준다.
- 앞 UserData가 있으면 `SetIfChanged` 두 번 하고 그대로 돌려준다.
- 없으면 Source 둘을 만들어 render한다.

그런데 이 헬퍼를 쓰는 곳은 Chip과 Tabs뿐이다. 같은 본문을 손으로 다시 쓴 자리가 있다. material `List.luau` 381~399행(ListData), devui `Table.luau` 206~252행, devui `Combo.luau` 141~172행이다. Swatches, YearView, ListReorder, devui Plot은 변형이다.

KeyGone 갈래의 반환이 이미 세 모양으로 갈렸다(메인 확인).
- `List.luau` 388행: `return nil, ctx.UserData`
- `KeyedSlot.luau` 35행: `return nil`
- `Table.luau` 208행: `return nil, nil`

셋 다 정의된 동작이지만 같은 일을 하는 본문이 갈라진 것이다.

문제: 이 관용구를 고칠 때 여러 자리를 따로 손봐야 하고, 이미 그 갈라짐이 시작됐다.

제안: 둘 중 하나다.
- (가) `KeyedSlot`을 킷 공용 자리(material `Util` 옆)로 올리고 ListData와 Table에서 쓴다.
- (나) devui에도 같은 헬퍼를 하나 둔다.

코어 쪽 슈거(Fusion ForKeys류)는 `base/slot-plan.md`가 `:List` 하나로 통합한다고 정했으므로 제안하지 않는다.

비용: 작음. 킷 내부다.

판정: **채택 권고**. BREAKING 아님. H-923(공개 `ctx` 타입 실측)과 같이 보면 재선언과 본문 사본이 한 번에 준다.

**H-929. 백엔드 op 스텁이 세 파일에 흩어져 있고, `LifetimeHandle.luau`가 무관한 스텁 창고를 겸한다**(O4).

상황: 스텁 설치 자리가 셋이다.
- `quad-base/src/LifetimeHandle.luau` 116~121행과 244~277행. hold op 넷 말고도 `onDestroying`·`isInst`·`nativeClaim`·`isClaimed`·`nativeFindChild`·native 계열·`setTimeout`/`clearTimeout`의 스텁을 함께 설치한다.
- `Tag.luau` 254~259행: `addTag`/`removeTag`.
- `Attr/Key.luau` 95~97행: `setAttr`.

이 셋을 합한 것이 `docs/reference/extend/01-backend-provider-contract.md` 32행의 "전부 20개"다. 관용구도 갈린다. 다른 스텁은 `if Backend.x == nil then` 가드 아래 설치되는데(245~246행 주석 "a provider may already be there"), `onDestroying`만 244행에서 무조건 덮어쓴다. 지금은 Init이 늘 프로바이더보다 먼저 돌아서 무해하다.

문제: 생명주기 원시 넷을 구현하는 파일이 Slot 물리 op와 시간 op의 스텁 창고를 겸한다. B2의 파일 수준판이다. 또 문서의 "20개"를 대조할 원장이 코드에 없다.

제안: op 인벤토리 표 하나(이름 → 묶음 → 안내 문구)를 base에 비공개로 두고, 한 루프로 스텁을 설치한다. 표가 있으면 문서 개수를 스크립트로 대조할 수 있고, H-938 진단의 바탕도 된다.

비용: 중간. 스텁 설치 순서를 그대로 지켜야 한다.

판정: **채택 권고(낮은 우선)**. 새 공개 이름 없음, BREAKING 아님. `LifetimeHandle.luau` 머리의 `H-373`은 스텁이 거기 놓인 경위일 뿐 분리를 막는 결정이 아니다(E 확인).

**H-930. `Slot/Tree.luau`의 해체 두 갈래가 같은 해제 순서를 각자 적는다**(O5).

상황 1: `teardownTree`(149~172행)와 `destroySlotTree`의 owned 갈래(245~256행)가 같은 해제 순서를 따로 쓴다. 순서는 "observers 전부 unbind → `_listObserver`·`_detachCleanup`·`_baseObserver` unbind → `_mounted`·`_mountedInst`·`_physicalTarget` 내림"이다. 그런데 `_detachCleanup`과 `_listObserver` 중 무엇이 앞인지가 두 갈래에서 다르다.

상황 2: `destroySlotTree` 안에서 "`_elements` 순회 + `_detached` 순회" 쌍이 두 번 나온다.
- 208~220행: `releaseOwner`와 래퍼 해제.
- 234~244행: `releaseOwner`와 `destroyElement`.

문제: 이 구역은 Q14·Q61·H6-19가 차례로 한 루프씩 고쳐 온 곳이고, 한쪽만 고친 실패가 이미 한 번 있었다. 주석 "The two destroySlotTree loops got the same line"이 그 흔적이다.

제안: 둘 중 하나다.
- (가) "이 Slot이 쥔 원소 전부에 fn" 헬퍼와 "생명주기 핸들 전부 unbind" 헬퍼, 지역 헬퍼 둘로 접는다.
- (나) 해제 순서만 헬퍼 하나로 모은다.

비용: 중간. 순서 차이가 의도인지 먼저 확인해야 한다. E도 메인도 아직 확인하지 않았다.

판정: **채택 권고(순서 차이 확인이 선행)**. BREAKING 아님.

**H-931. 커서 둘을 당기는 두 줄이 `Slot/Raw.luau`에 세 벌 있다**(O6).

상황: 같은 두 줄이 세 자리에 있다. 두 줄은 `offsetCacheValidUpTo = math.min(…, index - 1)`과 `offsetSetUpTo = math.min(…, index - 1)`이다. 자리는 `spliceArraysUp` 49~50행, `spliceArraysDown` 65~66행, `invalidateFrom` 319~320행이다(메인 확인).

`invalidateFrom`의 주석은 `H-113`이 반증한 공식("위치 자체와 `math.min`")을 경고한다. 그 경고가 지키려는 공식이 위 두 함수에는 헬퍼 없이 손으로 적혀 있다.

문제: 이 공식의 정본이 한 곳이 아니다.

제안: `invalidateFrom`을 파일 위쪽으로 올리고 두 splice가 그것을 부른다. 단 `Bookkeeping.luau` 312~313행과 353~354행은 `cur`/`i` 기준이라 공식이 다르다. 묶지 않는다.

비용: 거의 0.

판정: **채택 권고**. BREAKING 아님.

**H-932. 센티널 생성자 `sentinel`을 세 값이 우회한다**(O7).

상황: `quad-base/src/Dispatch/Handler.luau` 39~56행의 `sentinel(name)`은 머리 주석에서 스스로를 "every frozen marker sentinel"의 유일한 생성자라고 정의한다. 주석이 꼽는 사용처는 `None`, `ProcessedModifier`, `ProcessedPreRef`·`PostRef`이고, 이유는 "the sentinel convention cannot drift between copies"다. 그런데 같은 모양을 손으로 만드는 값이 셋 있다(메인 확인).
- `Slot/init.luau` 51~52행: `Detach`, `KeyGone`.
- `Claim.luau` 50~54행: `MapperRoot`.

문제: 주석이 막으려던 사본이 셋 있다.

제안: 둘 중 하나다.
- (가) 셋을 `sentinel`로 바꾼다.
- (나) 그대로 두고 `sentinel` 주석의 "every"를 사실에 맞게 고친다.

`sentinel`은 `any`를 돌려주고 공개 타입은 quad-types가 따로 주므로 타입 쪽 이유는 아마 없다. 다만 확인은 안 했다. `H6-16` (a)는 표식 모양에 대한 결정이지 생성 경로에 대한 결정이 아니다(E 확인).

비용: 거의 0.

판정: **채택 권고**((가)가 안 되면 (나)). BREAKING 아님.

**H-933. 코드와 어긋난 주석 넷 — H-899와 같은 부류, 다른 자리**(O8).

H-899가 "끝난 일을 미래형으로 적은 주석"이라면, 이것은 사실과 틀린 주석이다. 자리는 하나도 겹치지 않는다(메인이 넷 다 확인).
- `quad-base/src/Context.luau` 26~28행: "an immutable-clone `With` is an open item (`question.md`)". 그러나 `base/context-plan.md`는 `:With`류를 두지 않는다고 확정했고, `question.md`에 그 항목이 없다.
- `quad-base/src/Slot/init.luau` 151~153행: "except the three wrappers above". 같은 파일 30~32행은 그 셋이 없어졌다고 말한다("the old wrapper trio was a leftover").
- devui `Combo.luau` 373행: "same reason as ComboEnum's SelectedKey cast". ComboEnum에는 그 캐스트가 없고 `Combo.Combo`에 위임만 한다. 설명이 있는 곳은 334행이다.
- material `Slider/Behavior.luau` 177행: "(`level` 3: the caller of the look's constructor)". 바로 아래 192·196·204행의 `error`는 레벨 4다.

제안: 주석만 고친다. 마지막 자리는 레벨이 실제로 맞는지 한 번 실행해 보고 고친다.

비용: 거의 0.

판정: **채택 권고**. H-899와 같은 커밋에서 하면 좋다. BREAKING 아님.

**H-934. material 모달 셋이 "레이어에 맞추는 배율" 공식을 따로 갖는다**(O9, H-913과 부분 대응).

상황: 같은 공식 `max(하한, min(1, (W−m)/w, (H−m)/h))`가 세 자리에 있다(메인 확인).
- `Dialog.luau` 446~457행: 여백 `2*LayerMargin`, 하한 `FitMin`.
- `DatePicker/Modal.luau` 189~192행: 여백 32, 하한 0.25 리터럴.
- `TimePicker/Modal.luau` 196~202행: 여백 32, 하한 0.25 리터럴.

하한 0.25는 `Dialog.luau` 165행이 "the DatePicker modal's floor"라고 다른 파일을 가리키는 주석으로 맞춰 두었을 뿐이다.

문제: H-913은 "크기만으로 나누는 것"이라 기각됐다. E는 그 기각 이유를 받아들였다. 그러나 이것은 크기가 아니라 이미 존재하는 공식 세 벌이라 B1의 "가상의 미래 요구"에 걸리지 않는다는 것이 E의 의견이다. 메인도 같은 판단이다.

제안: 킷 `Util`에 `fitScale(layerSize, contentSize, margin)`과 공용 하한 상수를 둔다. 여백 48과 32가 M3 정본상 일부러 다른 것인지는 확인하지 않았다. 다르면 여백은 인자로 남긴다.

비용: 작음. 킷 내부다.

판정: **채택 권고**. BREAKING 아님.

**H-935. 작은 정리 묶음**(O10). 다섯 갈래 모두 걸리는 결정이 없다(E 확인).
- (a) `quad-base/src/Observer.luau` 205~215행 `_receive`가 두 갈래에서 똑같은 `if module.debug then checkUpstreamFeedback(…) end`를 부른다. 분기 위로 올리면 한 줄이 된다.
- (b) devui `Plot.luau` 161~163행과 246~248행이 `keyFn`으로 `function(_item, i) return i end`를 넘긴다. 생략할 때의 기본값과 같으므로 지워도 된다.
- (c) devui의 호스트 이름 Modifier 캐시 `hostName`이 `Tree.luau`, `Inputs/Choice.luau`, `Inputs/NumberField.luau`에 세 벌 있다. material에는 `Util.frameName`이 있다. 클래스별 타입 때문에 합치기 어려울 수 있어 셋 정도는 둬도 된다.
- (d) `quad-base/src/init.luau`의 `AddPlugin`은 182행에서 `Quad0211`로 반환이 테이블인지 먼저 검사한다. 그 뒤 부르는 `mergeExtension`이 같은 검사를 `Quad0209`로 또 한다(163~164행). 그래서 AddPlugin 경로에서는 0209에 닿지 않고, 0209는 UseProvider 몫만 남는다(메인 확인). 같은 실수를 경로마다 다른 번호로 알리는 것이 의도인지 에러 색인과 맞춰 볼 자리다.
- (e) 디버그 스택 탐색이 `State.luau` 82~96행 `stackHas`, `Observer.luau` 101~119행, Debounce에 따로 있다. 탐색 규칙이 달라 크게 합치기는 어렵다.

판정: (a)·(b)는 **채택 권고**. (c)·(e)는 **보류**(합칠 이득이 작다). (d)는 **확인 뒤 판단**이다.

**H-936. 버전 패턴 매처의 Python 사본을 아무 테스트도 대조하지 않는다**(O11).

상황: `type-version-check/src/init.luau` 52행이 런타임, `type function`, `scripts/check-version.py`의 Python 포트를 같이 고치라고 요구한다. 그런데 `quad-base/test/spec.versioncheck.luau`는 앞의 둘만 본다. `check-version.py`의 `matches_pattern`(98행)에는 자체 벡터가 없다(메인 확인).

문제: 세 번째 사본이 조용히 갈라질 수 있다.

제안: 둘 중 하나다.
- (가) 케이스 표를 데이터 파일 하나로 빼서 Luau spec과 Python이 같이 읽는다.
- (나) Python 쪽에 같은 케이스를 복사한 셀프 테스트를 둔다.

비용: 작음.

판정: **채택 권고**. BREAKING 아님.

**H-937. Observer 에러 문구가 "콜백이 던진 뒤" 상황을 말하지 않는다**(O16).

상황: `quad-base/src/Observer.luau`의 Quad0109(235행), Quad0110(251행), Quad0113(282행)은 "from inside its own fn"만 말한다. 그런데 콜백이 한 번 던지면 `_running`이 내려가지 않아, 콜백 밖에서 불러도 같은 문구가 난다. `docs/reference/errors/04-ref-observer-effect.md`의 Quad0110 절은 이것을 설명한다. 반면 에러 자리의 문구는 "콜백 안"이라고만 해서 오도한다. Effect의 Quad0088·Quad0090(291·309행)은 "or after this Effect's fn or cleanup has thrown"을 문구에 담고 있다(메인 확인).

제안: Observer 셋에 "(or its fn threw earlier)" 정도를 덧붙인다. 다만 round11 Q63이 Observer를 "죽지 않음, 자가 회복"으로 정했다. 그래서 "죽었다"가 아니라 "앞서 던졌을 수 있다"로 써야 한다. 에러 문구는 API가 아니므로 BREAKING이 아니다.

비용: 거의 0. 에러 문서 절도 같은 커밋에서 맞춘다.

판정: **채택 권고**.

**H-938. 프로바이더가 op를 빠뜨려도 처음 그 op를 부를 때까지 모른다**(O18).

상황: op 20개는 전부 필수다. 빠지면 Quad0108 스텁이 그 op를 처음 부를 때 던진다. `setAttr`를 빠뜨린 프로바이더는 첫 AttrKey 사용 때에야 안다.

제안: `UseProvider`가 프로바이더 함수 반환 직후, `q.debug`가 켜져 있으면 아직 스텁인 op 이름을 한 줄로 알린다. H-929의 표가 있으면 몇 줄이다.

함정: 소비자는 보통 `UseProvider` 뒤에 `q.debug = true`를 한다. 그래서 이 진단은 거의 돌지 않을 수 있다(`AddPlugin` 진단과 같은 문제). 디버그 층이 아닌 공개 점검 함수로 하면 새 공개 이름이라 사용자 문항감이다.

판정: **보류**. 효용이 낮다. 서드파티 프로바이더가 실제로 나오면 다시 본다.

**H-939. material README의 내부 문서 포인터**(O20, 2단계에서 축소).

E는 1단계에서 `quad-roblox-material/README.md`의 실기기 체크리스트를 README 밖으로 옮기자고 했다. 2단계에서 그 부분은 철회했다. `consumer-kits-plan.md` 103행과 `feedback/consumer-kits-studio-qa-2026-10-07.md`가 그 체크리스트를 일부러 작업 도구로 쓰기 때문이다.

남은 것은 798행의 `.claude/research/icon-pack-plan.md` 포인터 한 줄이다. 소비자 문서에 `.claude/` 경로를 두지 않는 규약과 결이 다르다.

판정: **킷 게시 전 정리 후보**. 체크리스트를 게시 문서에 둘지는 킷 게시 때 같이 본다.

### 기존 항목에 대한 다른 의견

**H-921(킷 에러 형식)에 다른 구현 갈래.** E는 `Util.fail(component, msg)`가 레벨 인자를 계속 받으면 손으로 세는 문제가 헬퍼 안으로 옮겨질 뿐이라고 본다. H-933의 Slider 주석 3과 코드 4의 불일치가 실제 사례다.

E가 낸 갈래는 이렇다. `Util.fail`의 본문을 quad-error 네임스페이스의 `errorBeforeNearest` 위에 짓고, 킷 공개 생성자를 킷 전용 레벨 값으로 태깅한다. 그러면 레벨 숫자가 사라진다. 새 공개 이름도 없다. 킷이 `quad_error.new()`로 자기 네임스페이스를 만드는 것은 이미 있는 공개 표면이다.

메인 판단: Q191의 (가) "형식만 통일"과 겹치지 않고, 그 구현 방법으로 얹힌다. 채택하면 H-921의 처방이 이것으로 바뀐다.

**H-915(`q.debug` 출력 헬퍼) 위에 공통 접두.** E는 진단 줄이 `Observer:`·`Claim:`·`Slot:`·`Tween:`처럼 접두가 제각각이라 Studio 출력에서 사용자 print와 섞인다고 짚었다(O19). 헬퍼가 생기면 공통 접두(예: `[quad debug]`)는 그 안에서 거의 공짜다. `warn` 전환은 킷 하네스와 spec들의 print 캡처를 같이 고쳐야 하므로 헬퍼 다음 단계로 둔다. E도 Q190 (가)에 동의한다.

**H-924 (b) 기각 수용.** E는 1단계에서 "T 또는 State<T> → State<T>" 헬퍼를 핵심 슈거로 올리는 갈래를 냈다(O15). 2단계에서 `feedback/consumer-kits-2026-10-05.md` A1의 2026-10-06 결정을 보고 철회했다. 그 결정은 정본은 `StateMarker<T>` + 캐스트로 하고, 제네릭 판은 하한 문제가 있다는 것이다. 킷 내부 통합도 타입별 셋이 일부러 그 모양이라 거뒀다. 남은 의견은 how-to 레시피 (a)에 합류한다.

**H-911·H-922 단서.**
- H-911: 전이 표는 좋다. 다만 칸마다 고정 spec을 의무로 하면 표 하나에 spec 수십 개가 따라온다. 그래서 이미 있는 spec 위치를 적는 정도가 적당하다는 의견이다.
- H-922: 키 목록이 props 타입과 이중 원장이 된다. 그래서 "새 컴포넌트부터"와 "debug에서만"이라는 단서가 꼭 필요하다는 의견이다.

**철회 — 킷 spec을 `test.sh` 선택 플래그로**(O12). `consumer-kits-plan.md` 76행의 "기존 `./scripts/test.sh`는 손대지 않고"에 걸린다.

**Q188~Q193.** E는 여섯 문항의 판정자 권고에 모두 동의했다. 덧붙인 의견은 셋이다.
- Q188 (나): 이유 없이 번호만 남은 줄부터 손대는 것이 맞다.
- Q192 (가): 실측할 때 H-928의 `KeyedSlot` 재사용도 같이 보면 좋다.
- Q193 (나): material 쪽 페이크가 상위 집합이므로 정본은 material이 맞다. 하네스 두 벌의 diff는 5줄이고, material만 `UserInputService` 페이크를 더했다.

**잘 돼 있어서 건드리지 말 것**(E의 의견). 메인 판단은 "건드리지 말 것" 목록으로 받는 것이다.
- `quad-error/src/init.luau`가 sentinel 변환 넷을 일부러 헬퍼로 빼지 않은 것(`H-283`, -O2 인라인).
- Observer와 Effect의 본문 분리(`H-144`).
- Source, quad-roblox EngineOps, Operator의 응집.
- Claim의 검증·커밋 두 패스.
- `docs/reference/core/01-quad-module.md`의 `q.debug` 목록.
- Slot 공개 CRUD 층의 `assertMutable` 관문.

**실행 수.** opus 하나, 두 단계(이어 쓰기)다. 미완: 없음. 단 E가 밝힌 미독 범위(이 절 머리)는 이번 패스도 보지 않은 곳이다.
