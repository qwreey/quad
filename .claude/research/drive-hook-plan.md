# drive pre-hook — 아이디어 단계 (2026-09-01, 사용자 제기)

**상태: 리서치 등재만. 설계 논의 전 — 사용자 지시로 후순위**(*"이건 단순
리서치 요소로 두어요. 아니면 필요성이 높아보이면 지금 의논해볼수도
있습니다"* — round12 `H-279`).

## 문제 인식 (사용자 원문 요지)

`drive` 파이프라인이 특정 값 종류를 **선처리해 `Processed*`로 바꾸는**
자리가 늘고 있다 — M8의 (a) PreRef/PostRef pre-pass가 대표(pre-pass가
`PreRef`를 소진하고 `ProcessedPreRef` 자리표시자를 남김), (c) postRefList도
같은 결. 이 모양이 늘수록 **drive 시스템이 서브시스템들을 알아야 한다**
(*"안 그럼 drive 시스템이 서브시스템들을 알아야해서요"*) — `H-278`(Leaf
등록 소유권을 각 객체 모듈로)과 같은 축의 결합 문제가 파이프라인
스테이지에서도 생긴다.

## 아이디어

drive의 스테이지(선처리/후처리)를 핸들러 레지스트리처럼 **훅으로 등록**하는
개념 — 서브시스템(Ref 등)이 자기 pre-pass를 자기 모듈에서 등록하고, drive는
등록된 훅을 순서대로 돌 뿐 개별 값 종류를 모른다.

## 왜 지금 안 하나

- 알려진 소비자가 M8의 둘(pre-pass, postRefList)뿐 — 둘을 위해 훅 메커니즘을
  미리 세우는 것은 "실제로 관측된 문제에만 구조" 원칙과 긴장.
- M8에서 (a)/(c)를 실제로 짤 때 결합의 실모양이 드러난다 — 그때가 판단
  재료가 가장 싼 시점. **M8 착수 전에 이 문서를 다시 열 것**(그때 훅으로
  갈지, drive가 그 둘만 하드코딩할지 결정).

**[2026-09-06 기록 — 2026-09-04 M8이 실제로 택한 것]** M8 단위 ②는 이
문서를 다시 열지 않은 채 **하드코딩 경로**로 갔다 — `Dispatch/init.luau`의
`drive`가 `Dispatch/Ref.luau`의 `prePass`/`firePostRefs`를 직접 부른다(훅
레지스트리 없음, round18 `H-319`). 그 자리에서 판단 재료로 드러난 것은
둘: (1) pre-pass는 `flatten` 뒤·배치 `On()` 뒤·본체 루프 앞이라는 **위치**가
정본(`H-17`)에 고정돼 있어 "순서대로 도는 훅"이 아니라 "그 자리의 한
호출"이고, (2) `Processed*` 센티널·핸들러 등록은 이미 `Dispatch/Ref.luau`가
소유해 `drive`가 아는 건 함수 둘뿐이다. 그래서 소비자가 둘일 동안은 결합이
함수 호출 두 줄에 그친다 — **이 문서는 닫힌 게 아니라 다음 pre/post-pass
소비자(세 번째)가 생길 때 다시 여는 리서치로 남는다**(그때 훅으로 갈지
결정). M8이 착수 전에 안 연 것 자체는 2026-09-06 감사 1라운드가 잡았다.

## 관련

- `base/bind-system-plan.md`의 `New(name)(props)` 파이프라인 의사코드 —
  (a)~(c) 스테이지 구성이 소스.
- round12 `H-277`(Bookkeeping 분리)·`H-278`(Leaf 등록 소유권) — 같은 회신에서
  같이 제기된 결합 문제 가족.

## [2026-09-13] 사용자 의견 — "실행하는 편이 낫다" — 와 재검토 (opus 분석, 메인 검토; 착수 아님)

**[2026-09-14 사용자 결정 — 백로그, 지금 작업 안 함.]** 원문: *"drive-hook 는 내부적 계약 바뀜이고 표면은 안 바뀌여서 당장 할 이유가 없어. 백로깅 하고 천천히 보며 다각도로 사람과 같이 깊게 검토해는게 이로워서 지금은 작업 시점은 아니라 보고 … 열린 문항으로 둬도 돼."* 아래 §5 문항 넷은 열린 채로 둔다(사람과 같이 검토할 때 답한다).

사용자 원문: *"drive-hook-plan.md 는 실행하는 편이 나아보이는게, 하드코딩된 핸들링 방법이 없다 하는데 지금 있는 상태임. 심지어 drive 가 계층 구조를 알고 있음 - preref 에 대해서 RefPrePass.register 를 dispatch init 에서 넣고(모듈 아님) 'local postRefList = RefPrePass.prePass(inst, flattened)' 로 preref 계층을 앎. dispatch 는 기본적으로 계층을 모르고, NoneModule.register 같은것도 여기서 하면 안 된다고 생각해. 최상위 init.luau 에서 각각 필요한 register 를 하고 … 각각 안쪽에 Init 함수에 둬도 될것 같기도 하고. … 선택 문제로 보임. drive-hook-plan.md 의 재료는 나름 이미 있다보임. prePass 핸들이 약간의 계약처럼 있어서."*

**메인 요약**: 분석은 사용자 문장이 묶은 세 결정(① `register` 호출 위치, ② `drive` 본문의 `flatten`/`prePass`/`firePostRefs` 하드코딩, ③ 훅 레지스트리)을 가른다. ①은 지금 해도 남는 것이 있고(`Dispatch/init.luau`의 값 모듈 require 다섯 → 둘, 시그니처 비대칭 해소, 레포 관례(B)와 일치), ②가 사용자가 말한 "계층을 안다"의 실물이며, ③은 순회 방향(flatten 역순 / prePass 정순)이 반대라 순회를 합칠 수 없고 스테이지 개수·위치는 여전히 drive가 알아야 하므로 실익이 "새 스테이지 추가 때 파일을 안 고침" 하나뿐인데 그 새 스테이지가 백로그에 없다. **권고: ①은 (B) 각 모듈 `Init` + `Ref` 순환은 (b1)로, ②·③은 세 번째 독립 소비자가 생길 때.** 결정 문항 넷은 끝 절. 코드는 손대지 않았다.

## 0. 먼저 갈라야 할 것 — 사용자 원문이 묶어 놓은 세 결정

사용자 메시지는 서로 분리 가능한 세 가지를 한 덩어리로 말하고 있습니다. 이대로 한 번에 답하면 하나를 결정하고 다른 것을 얻게 되니, 먼저 갈라 놓습니다.

첫째는 **`register` 호출이 어디서 불리느냐**입니다(`quad-base/src/Dispatch/init.luau` 498~507행). 이건 호출 자리 문제라 런타임 동작이 하나도 안 바뀝니다. 둘째는 **`drive` 본문이 스테이지 이름을 계속 부르느냐**입니다(427행 `flatten`, 439행 `RefPrePass.prePass`, 450행 `firePostRefs`, 그리고 그걸 위한 43~47행 require). 사용자가 말한 "코어가 계층을 안다"는 위반은 정확히 이쪽이고, **`register`를 옮겨도 이건 1밀리미터도 안 줄어듭니다.** 셋째가 계획서의 원래 아이디어인 **훅 레지스트리를 세우느냐**입니다. 사용자 인용문은 근거로는 첫째를 대고 있고 주장으로는 둘째를 말하고 있습니다 — "drive 가 계층 구조를 알고 있음"의 증거로 든 것이 `RefPrePass.register`를 dispatch init에서 부른다는 사실인데, 그 register 줄은 레지스트리를 채우는 일이라 `drive` 본문의 계층 지식과는 다른 층입니다. 실제 계층 지식의 증거는 바로 그 다음에 사용자가 든 `local postRefList = RefPrePass.prePass(inst, flattened)` 쪽입니다.

---

### 1. 현재 상태 사실

**`drive` 본문**(`quad-base/src/Dispatch/init.luau` 386~461행)이 실제로 아는 것들입니다.

- **422~426행** 숫자 키 도메인 검사(`pairs` 전수 1회). `drive` 자신의 게이트라 서브시스템 지식이 아닙니다(`H-495`).
- **427행 `flatten(flattened)`** — 46행에서 `@self/Modifier`의 `flatten`만 뽑아 옵니다. Modifier 서브시스템의 스테이지를 `drive`가 직접 호출. 구현은 `quad-base/src/Dispatch/Modifier/init.luau:452`, 해시 파트 walk 한 번 + 배열 파트 **역순** 순회 한 번.
- **428~432행** `batching` 판정 → `bookkeeping.getBlocker(inst)` → `blocker:On()`.
- **439행 `RefPrePass.prePass(inst, flattened)`** — 47행 require. 배열 파트 **정순** 순회 한 번, `PreRef`를 발화·소진하고 `PostRef`를 모아 **로컬 리스트를 반환**합니다(`quad-base/src/Dispatch/Ref.luau:57`).
- **440~442행** 본체 루프.
- **449~451행 `RefPrePass.firePostRefs(inst, postRefList)`** — 439행이 만든 상태를 여기서 소비. 즉 (a)와 (c)는 독립 스테이지가 아니라 **상태를 주고받는 한 쌍**입니다.
- **454~460행** `blocker:OffWithoutEmit()` → `getBookkeeping` → `recompute`.

**`register` 묶음**(495~511행)은 넷입니다. `NoneModule.register(Dispatch)`(498), `ProcessedModifierModule.register(Dispatch)`(501), `RefPrePass.register(Dispatch)`(502), `StoreBindModule.register(Dispatch, module)`(507 — 혼자 `module`을 두 번째 인자로 받습니다). 여기서 한 가지 구체적인 소득이 있습니다: **43·44·45행의 require 셋은 각각 오직 그 register 한 줄에서만 쓰입니다**(전수 grep 확인). 그러니 register 넷을 밖으로 빼면 `Dispatch/init.luau`가 값 모듈에 대해 남기는 의존은 정확히 **둘**(`flatten`, `RefPrePass`)로 줄어들고, 그 둘이 곧 진짜 계층 지식입니다. 이건 옮기기의 실익으로 정직하게 셀 수 있는 유일한 항목입니다.

**대비 — 이미 "밖에서 register"하는 것들.** quad-base 안에서 값 모듈은 이미 전부 자기 `Init`에서 등록합니다(`H-278`): `Observer.luau:233`, `Effect.luau:319`, `Ref/init.luau:214~`, `Tag.luau:247`, `Attr/Key.luau:99`, `Attr/init.luau:247`, 그리고 `Slot/init.luau:440`이 `Slot/Handler.luau:16`의 `register(Dispatch, module)`를 부릅니다. 백엔드는 `quad-roblox/src/RobloxFactory.luau:42~46`이 `install(quad)` 모듈 목록을 부르는 모양입니다. **즉 레포에는 이미 "모듈이 등록 본문을 갖고, 최상위가 그 목록을 부른다"는 관례가 서 있고(사용자가 말한 (B) 쪽), Dispatch tail의 넷만 예외로 남아 있습니다.**

**순수성을 얼마나 깨고 있나 — 정직한 평가.** register 넷은 "레지스트리를 누가 채우나"라 `drive` 본문을 한 줄도 바꾸지 않습니다. 소유권 표기 문제지 계층 지식이 아닙니다. 반대로 `flatten`/`prePass`/`firePostRefs` 세 줄은 `drive`가 "Modifier라는 게 있고, PreRef/PostRef라는 게 있으며, 후자는 앞뒤로 쪼개져 상태를 넘긴다"는 것을 아는 것이므로 진짜 위반입니다. 다만 canon은 이걸 **이미 한 번 위반이 아니라고 선언**했습니다 — `.claude/base/architecture.md:359`가 *"`Dispatch/` 아래엔 코어와 `drive`의 자기 단계만 둔다"*로 `Dispatch/Ref.luau`·`Dispatch/Modifier`를 "drive의 자기 단계"로 분류했고, `H-17`은 배치 Blocker를 아예 `drive`의 계약으로 못 박았습니다. 이 충돌은 제가 판정할 게 아니라 §5의 문항입니다.

**계획서의 "왜 지금 안 하나"가 어떻게 바뀌나.** 원래 근거는 *"알려진 소비자가 M8의 둘(pre-pass, postRefList)뿐"*이었습니다. 실제로 세어 보면 `drive`가 부르는 서브시스템 호출은 셋이지만 그중 둘은 같은 소비자(Ref)의 앞뒤 쌍이라, **독립 소비자는 여전히 둘(Modifier flatten / Ref pre-pass 쌍)이고 "세 번째 소비자" 트리거는 아직 안 왔습니다.** 백로그를 훑어도 새 `drive` 스테이지를 만드는 항목은 없습니다 — `research/component-flatten-sugar-plan.md`는 `flatten`을 **drive 밖 컴포넌트 코드에서** 쓰는 순수 슈거고, `__apply`는 `State:Apply` 쪽이라 무관합니다. 사용자 의견이 바꾸는 것은 개수가 아니라 **트리거의 종류**입니다: 관측된 문제를 "소비자 수"가 아니라 "코어가 계층을 아는 것 자체"로 놓으면 수는 더 이상 근거가 아니게 됩니다. 그 재정의를 받아들일지가 결정 사항이고, 받아들이더라도 **그 위반의 실물은 register 넷이 아니라 본문 세 줄**이라는 점은 그대로입니다.

---

### 2. 훅 설계 선택지 — 지금 재료로 구체화

**훅 지점은 셋을 넘지 않습니다.** 배치 게이트(⓪·⓪')는 `H-17`이 `drive`의 계약으로 못 박았고 재계산 재진입 가드까지 얽혀 있어 훅으로 내리면 계약 자체를 다시 여는 일이 됩니다 — 고정으로 둡니다. 도메인 검사(422~426)도 "어떤 핸들러가 부기를 만지기 전에"라는 위치가 `H-495`의 본질이라 고정입니다. 남는 실제 훅 자리는 **pre-flatten 계열(게이트 열기 전, 배열 길이를 안 바꾸는 변환)**, **pre-pass(게이트 연 뒤, 자리를 센티널로 소진)**, **post-body(본체 뒤, 배치 닫기 전)** 셋입니다.

**여기서 훅 모양이 하나로 좁혀집니다.** `ref-plan.md:1145`가 기록한 사용자 원칙은 *"새 전체 순회를 추가하지 않는 게 핵심"*인데, 지금 본체 전에 배열을 이미 세 번 훑습니다(도메인 검사 `pairs` 1회, flatten 역순 1회, prePass 정순 1회). 그래서 자연스러운 대안은 "drive가 배열을 한 번만 돌면서 등록된 방문자들에게 `(i, v)`를 넘긴다"인데, **이건 구조적으로 불가능합니다** — `flatten`은 *마지막 Modifier가 먼저 써야 한다*는 이유로 **역순 필수**(`Modifier/init.luau:475`의 ⚠️ 주석)이고 `prePass`는 `PreRef` 발화 순서 때문에 **정순 필수**라, 방향이 반대인 두 순회를 하나로 못 접습니다. 따라서 훅은 **"이름 붙은 스테이지 슬롯 = 순회 하나"** 모양밖에 남지 않고, 소비자가 늘면 순회도 같이 늘어납니다.

**순서·우선순위는 등록자에게 주면 안 됩니다.** 핸들러처럼 `priority` 숫자로 두면 canon이 고정한 ⓪ → flatten → (a) → (b) → (c) → ⓪' 순서(`bind-system-plan.md` 파이프라인 의사코드, `H-17`)가 등록자 손에 넘어갑니다. 훅으로 가더라도 **슬롯 이름은 drive가 고정**하고 같은 슬롯 안의 복수 훅만 등록 순서로 도는 모양이어야 합니다. 그러면 "drive가 개별 값 종류를 모른다"는 목표는 달성되지만 **스테이지의 개수와 위치는 여전히 drive가 압니다** — 훅은 결합을 없애는 게 아니라 간접화합니다. 실익은 하나로 정직하게 줄어듭니다: **새 스테이지를 추가할 때 `Dispatch/init.luau`를 안 고쳐도 된다.**

**상태 전달은 두 모양뿐입니다.** `prePass`가 `postRefList`를 (c)로 넘기므로 훅은 독립일 수 없습니다. (1) **쌍 등록** — pre 훅이 반환한 값이 그 훅의 짝인 post 훅에 그대로 전달(지금 코드와 1:1, 추가 할당 0). (2) **drive 1회용 컨텍스트 테이블**을 모든 훅에 넘김 — 유연하지만 매 `drive`마다 테이블 하나를 할당하게 되고, 자식 없는 `Frame { Size = … }`까지 물립니다. 이건 `H-17` 가드가 Blocker·`bk`에 대해 막으려던 eager 할당과 같은 부류라 같은 이유로 비쌉니다. **(1)을 권합니다.**

**실패 시 blame은 새 메커니즘이 필요 없습니다.** `addHandler`가 이미 받은 함수를 `Err.setFuncLevel(SURFACE, …)`로 태깅하고(364~365행), 그래서 pre-pass 안의 raise는 `errorBefore`로 사용자의 `D.Frame{}` 줄을 blame합니다. 훅 등록도 같은 한 줄을 하면 지금과 동일한 blame이 나옵니다.

---

### 3. `register` 호출 위치 — (A)와 (B)

**(A) 최상위 `init.luau`에서 전부 명시 호출.** 사용자가 든 장점(*"모든 핸들을 register 했다는게 알 수 있게"*)은 정당합니다. 다만 비용이 문서화된 불변식과 정면으로 부딪힙니다 — `quad-base/src/init.luau:174~175`가 *"각 Init이 자기 의존성을 `module:RunInit(...)`로 직접 당겨오므로(멱등) 여기 순서는 무관하다"*라고 적고 192행이 *"순서 무관하게 추가"*를 반복합니다. `register`는 Dispatch가 설치된 **뒤에** 와야 하므로 (A)는 바로 그 파일에 순서 있는 줄을 들여놓습니다. 그리고 이 레포에는 **그 의존이 결함으로 판정된 선례가 이미 있습니다** — `H-358`(`post-implementation-review-round1.md:81`): *"`module.Dispatch`/`_bookkeeping`을 `RunInit(InitDispatch)` 없이 직접 읽는 유일한 Init — `init.luau`의 '순서 무관' 불변식 위반(지금은 순서가 맞아 잠복)"*, 처방은 관용구로 되돌리기였고 그 흔적이 `Slot/init.luau:69` 주석에 남아 있습니다. (A)는 그때 없앤 종류의 의존을 넷 들여오는 셈입니다.

**(B) 각 모듈이 `Init`을 갖고 최상위는 목록만 부름.** 응집이 좋고, **레포의 기존 관례와 정확히 같은 모양**입니다(`Slot/init.luau` → `Slot/Handler.luau`가 이미 그 꼴이고, 백엔드 `RobloxFactory`도 같은 꼴). 시그니처 비대칭(`register(dispatch)` 셋 vs `register(dispatch, module)` 하나)도 `Init(module)` 한 모양으로 정규화됩니다. 사용자가 든 (B)의 단점("등록 순서·우선순위가 흩어짐")은 현재 재료로는 **실체가 없습니다** — 지금 HIGH 밴드에 몰린 핸들러들(`NoneHandler`/`NilHandler`/`Processed*` 셋/`StoreBind`/`RefLeafHandler`/`SlotHandler`)은 `isHandlable`이 서로 배타적이고(센티널 identity / `number`∧`nil` / `isState` / Ref 브랜드 / `isSlot`), `table.sort`가 불안정이라 동률 순서는 애초에 계약상 미정입니다(`addHandler` 330~332행 주석).

**(B)에 하나 실제 제약이 있습니다 — 순환 require.** 확인한 바로 `None.luau`·`StoreBind.luau`·`Modifier/Handler.luau`는 `Dispatch/init`을 require하지 **않고**, 그래서 `Dispatch/init`이 그들을 require할 수 있습니다. register를 빼면 43·44·45행 require가 사라지므로 **이 셋은 안전하게 `./Dispatch`를 require해 `H-278` 관용구(`module:RunInit(InitDispatch)`)를 쓸 수 있습니다.** 그런데 `Dispatch/Ref.luau`만은 `prePass`/`firePostRefs` 때문에 `Dispatch/init`이 계속 require하므로, 그 파일이 `./Dispatch`를 require하면 순환입니다. 해법 셋이 있습니다 — (b1) `Processed*Ref` 두 핸들러의 **등록만** `Ref/init.luau`로 올린다(그 파일은 이미 Dispatch를 require하고 `H-278` 관용구를 쓰며, 센티널 값 자체는 `Dispatch/Ref.luau`가 계속 소유하고 export만 하면 됩니다), (b2) `Dispatch/Ref.luau`를 스테이지 파일과 센티널+핸들러 파일로 쪼갠다, (b3) 그 하나만 Dispatch tail에 남긴다(비대칭이 남음). **(b1)이 제일 싸고 `H-278` 문장("값을 선언한 모듈이 자기 핸들러를 등록")과도 맞습니다** — `PreRef`/`PostRef`를 선언한 모듈이 `Ref/init.luau`이니까요.

**권고: (B), 보완은 (b1).** 근거는 셋입니다 — `init.luau`의 "순서 무관" 불변식을 지키고(그걸 깬 유일 사례가 `H-358`로 결함 판정됐음), 레포에 이미 서 있는 관례(Slot·백엔드)와 같아지며, 시그니처 비대칭이 사라집니다. 사용자가 (A)에서 원한 "전수를 한눈에"는 (B)에서도 `init.luau`의 `RunInit` 목록이 반쯤 제공하고, **완전한 전수 감사는 런타임 `listHandlers()`가 이미 답을 줍니다** — 실제로 `spec.dispatch.luau:344~349`가 그 방식으로 내장 쌍의 존재를 확인합니다. 다만 "빠뜨림"은 (A)든 (B)든 똑같이 가능합니다(A는 register 줄을, B는 `RunInit` 줄을 빠뜨림). 차이는 **빠뜨림이 어디서 드러나느냐**뿐이고, 이건 `dispatch-core-plan.md:926`의 재역전 근거와 직결됩니다 — 그 결정은 "프로바이더를 안 붙여도 FALLBACK 밴드가 채워져 있어야 한다"였지 "`Dispatch/init`이 채워야 한다"가 아니었으므로 (B)로 옮겨도 유지되지만, **조건은 그 모듈들의 `Init`이 실제로 `init.luau`의 `RunInit` 목록에 들어가는 것**입니다.

---

### 4. 비용·위험

**공개 계약은 무변경이어야 하고, 실제로 무변경으로 됩니다.** `docs/reference/extend/02-dispatch-handler-contract.md:190~201`이 `drive`의 7단계 순서를 사용자에게 약속해 놨습니다. `register` 위치 이동은 이 페이지와 무관합니다. 훅 레지스트리도 **기본 순서가 한 단계도 안 바뀌면** 무변경이지만, 훅이 공개 표면이 되는 순간 그 페이지에 절이 하나 늘고 루트 `CHANGELOG.md`의 `[Unreleased]`가 걸립니다(공개 표면 변경 규약). 이건 구현하는 세션의 제약으로 넘길 것이지 지금 할 일은 아닙니다.

**스펙 56은 안전합니다 — 단언해도 됩니다(확인함).** `listHandlers()`를 쓰는 곳은 둘인데, `spec.dispatch.luau:320~352`는 *"내장 개수는 여기서 안 센다"*고 명시하고 이름 존재(`NoneHandler`/`NilHandler`)만 보며, `spec.flatten.luau:90~93`도 `ProcessedModifierHandler`의 이름 존재만 봅니다. 순서 단언은 자기가 등록한 셋의 상대 순서뿐입니다. 그리고 **모든 스펙이 `mock.newQuad` → `Quad.New()`를 타므로**(`quad-base/test/mock.luau:772`) `New()` 안에서만 등록되면 그대로 통과합니다. 다만 `spec.flatten.luau:93`의 주석 문자열 *"handler registered by InitDispatch"*는 산문만 stale해지니 같은 커밋에서 고쳐야 합니다.

**진짜 위험은 창(window) 하나입니다.** 지금 register는 `module.Dispatch = Dispatch`(513행) **이전**에 끝납니다. 밖으로 옮기면 `RunInit(InitDispatch)`가 반환된 뒤에 등록되므로, 그 사이에 도는 코드가 디스패치를 하면 빈 레지스트리를 봅니다. 지금 그 창에 도는 것은 다른 `RunInit`들뿐이고 전부 등록만 하지 디스패치하지 않으므로 실제 위험은 0이지만, **(B)로 가면 "값 모듈의 `Init`은 자기 `Init` 안에서 디스패치하지 않는다"가 암묵 계약으로 승격**됩니다. 이걸 주석으로 명문화하지 않으면 다음에 누가 밟습니다.

**동률 순서**는 위에서 적었듯 지금은 상호 배타라 무해하지만, 옮긴 뒤 손 트레이싱 대상 하나로 남겨야 합니다 — "HIGH 밴드 집합이 여전히 서로 배타인가".

**이행 순서 제안.** (1단계) `register` 넷만 옮기고 `Dispatch/init.luau`의 require 셋(43·44·45)을 제거 — 이때 문서 넷을 같은 커밋에서 갱신해야 합니다: `architecture.md`의 319~321행·359행, `dispatch-core-plan.md`의 821행·926행 주변, 각 소스 파일 헤더(`None.luau:14`, `StoreBind.luau:29`, `Modifier/Handler.luau:12`, `Dispatch/Ref.luau:27`이 전부 "registered by InitDispatch"라고 적고 있습니다), 그리고 `spec.flatten.luau:93` 주석. (2단계) 그 상태에서 `drive` 본문에 남은 계층 지식이 정확히 세 줄임을 확인 — 이게 계획서의 "소비자 재계수"에 해당합니다. (3단계) 훅은 별건으로, 세 번째 **독립** 소비자가 실제로 생길 때.

**검증.** `./scripts/test.sh; echo $?`가 0인지(줄 세기 금지 — 2026-09-07 규약), `doc-check.py` ERROR 0. 손 트레이싱은 둘이면 충분합니다: quad-roblox를 안 붙인 상태에서 `Tag`/`Attr`의 FALLBACK 밴드가 여전히 채워지는가(`dispatch-core-plan.md:926` 재역전의 근거가 유지되는지), 그리고 `New()` 둘이 레지스트리를 안 나누는가(`spec.dispatch.luau` §12가 이미 검사).

---

### 5. 결정 문항

**첫째, 이번에 하려는 범위가 셋 중 어디까지입니까.** `register` 호출 넷의 위치만 옮기는 것인지, `drive` 본문의 `flatten`/`prePass`/`firePostRefs` 하드코딩까지 훅으로 바꾸는 것인지, 아니면 둘 다인지를 먼저 정해야 합니다. 둘은 완전히 분리 가능하고, 전자는 후자를 전혀 줄이지 않습니다 — 옮기기의 실익은 `Dispatch/init.luau`가 값 모듈에 대해 갖는 require가 다섯에서 둘로 주는 것 하나입니다. 제 판정은 "위치 이동은 지금 해도 남는 게 있고, 훅은 아직"입니다. 훅으로 가도 스테이지의 개수와 위치는 여전히 `drive`가 알고(순서를 등록자에게 넘길 수 없으므로) 순회 수도 그대로라, 남는 실익은 "새 스테이지 추가 시 `Dispatch/init.luau`를 안 고쳐도 된다" 하나인데 그 새 스테이지가 백로그 어디에도 없습니다.

**둘째, (A)와 (B) 중 어느 쪽입니까.** 저는 (B)를 권합니다. 근거는 `init.luau`가 스스로 선언한 "여기 순서는 무관" 불변식을 (A)가 깨고, 그 불변식을 깬 유일한 사례가 이미 `H-358`로 결함 판정돼 고쳐졌으며, 레포에 이미 (B) 모양이 셋(Slot, 값 모듈 전부, 백엔드 `RobloxFactory`) 서 있어 (A)로 가면 오히려 Dispatch만 다시 예외가 되기 때문입니다. 사용자가 (A)에서 원한 "모든 핸들을 register 했다는 걸 알 수 있게"는 별개로 성립하는 요구이고, 런타임 `listHandlers()`가 이미 그 답을 주고 있습니다(스펙이 실제로 그렇게 쓰고 있습니다). 다만 이건 제 권고일 뿐 사용자가 (A)를 골라도 동작상 문제는 없습니다 — 비용이 불변식 하나라는 것만 알고 고르시면 됩니다.

**셋째, 이 변경을 확정 역전으로 취급합니까, 범위 좁히기로 취급합니까.** 지금 코드는 세 개의 명시적 결정 위에 서 있습니다 — `architecture.md:359`가 *"`Dispatch/` 아래엔 코어와 `drive`의 자기 단계만 둔다"*로 pre-pass를 "서브시스템 누수가 아니라 drive 자신의 단계"로 분류했고, `H-278`은 그 범위를 *"한 값 타입의 leaf 핸들러"*로 명시적으로 한정했으며, round13 §0 Q3 (a)는 `StoreBind`를 *"값 모듈이 아니라 디스패치 자신의 언랩 단계"*라는 이유로 **일부러** Dispatch tail에 두었습니다(507행 주석에 그대로 적혀 있습니다). 이번 결정이 이 셋의 역전인지, 아니면 "등록 호출 자리만 바꾸고 소유권 분류는 그대로"라는 좁히기인지를 사용자가 정해 줘야 문서를 어느 쪽으로 고칠지가 정해집니다(역전이면 원문을 `archive/`로 옮기고 포인터를 남기는 절차가, 좁히기면 단서 추가가 붙습니다).

**넷째, `Dispatch/Ref.luau`의 순환 제약을 어떻게 풉니까.** (B)로 갈 때 `None`·`StoreBind`·`Modifier/Handler` 셋은 깨끗하게 자기 `Init`을 가질 수 있지만, `Dispatch/Ref.luau`만은 `drive`가 `prePass`/`firePostRefs` 때문에 계속 require하므로 그 파일이 Dispatch를 되받아 require하면 순환입니다. 제가 보기엔 `Processed*Ref` 두 핸들러의 등록만 `Ref/init.luau`(이미 Dispatch를 require하고 `H-278` 관용구를 쓰는 파일)로 올리고 센티널 값 자체는 `Dispatch/Ref.luau`가 계속 소유하는 게 가장 싸고 `H-278`의 문장과도 맞지만, 파일을 둘로 쪼개거나 그 하나만 tail에 남기는 선택지도 있습니다.

