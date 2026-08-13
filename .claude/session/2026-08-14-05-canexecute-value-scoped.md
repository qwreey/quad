# 2026-08-14 다섯 번째 세션 — `canExecute(value)` 1-인자로 정정, `Subscribed` 오염 제거, gcconn을 Instance 생성 시점으로

**발단**: 사용자가 `base/lifecycle-pattern.md`를 읽다가 한 줄에서 멈춤 —
*"canExecute 가 왜 inst 를 받음? 이상하네. observer 등의 execute 가능 유무는
이미 바운딩된 inst 가 존재해야하는거 아녔음? 에이전트가 그냥 잘못 말했나."*

## 1라운드 — 문서가 뭐라고 적혀 있었나

읽기만 요청받아 확인한 결과:

- `base/lifecycle-pattern.md`는 `canExecute(inst, value)` 2-인자를 확정으로
  적어두고 있었고, "2026-08-08 세션 재정정"이라는 배너까지 달려 있었음.
  근거는 *"Observer 자신의 바인딩 생존(`Subscribed`)과 `inst` 자체
  생존(gcconn)은 독립적인 두 조건이라 하나의 opaque handle로 뭉치면
  구별 못 함"*.
- 그런데 **`canExecute`의 실제 호출부가 코퍼스 어디에도 코드로 없었음.**
  `dispatch-core-plan.md`의 `StoreBind.process` 의사코드에도 없고,
  `bind-system-plan.md`의 `state:Observer(fn)` 절은 "발화 시 canExecute로
  게이팅됨"이라고 **서술만** 함. `dispatch-core-plan.md`는 아예 "핸들러가
  직접 canExecute를 재구현할 필요 없음 — Observer가 이미 자기 `Subscribed`
  상태로 게이팅됨"이라고 적어 호출부를 없는 것처럼 만들어놨음.
- 그리고 `bindLifetime`은 `value`에 `inst` 참조를 아무것도 안 남기고
  `value.Subscribed = true`만 세팅하고 있었음 → 문서가 주장하는
  "owning leaf가 죽으면 no-op"이 **`value`만 가지고는 성립 불가능**한 구조.

이 지점까지 정리해 보고하고, (a) 호출부 누락된 문서 갭이거나 (b) 원래
1-인자였는데 어디선가 오염됐거나 둘 중 하나라고 추정.

## 2라운드 — 사용자가 정확한 모델을 직접 서술

*"또 에이전트가 실수한듯. Observer 의 바인딩은 Subscribed=true 안 함.
정확히 Subscribed 는 글로벌 사이드에서 사용하기 위함이라고 **명시를 내가
여러번 했음**. 다시한번 말하지만, Subscribed 는 bindLifetime 과 **일절
이해관계가 엮이지가 않아.**"*

사용자가 못박은 `bindLifetime`의 계약 2줄:

1. Observer는 bind 계약이 유효한 중에는 `inst`만큼은 살 것이 보장된다.
2. Observer는 `inst`가 살아있는지 **확인할 수 있는 방법이 제공된다**.

2번이 핵심 — "확인할 방법을 `value`가 제공받는다"는 게 `canExecute`가
`inst` 없이 성립하는 이유이고, 옛 설계는 이 절반을 통째로 빠뜨린 채
`inst`를 인자로 받아 때우고 있었던 것.

### 사용자가 제시한 Roblox 구현 (원문 요지)

`inst -> gchold`가 먼저 존재한다. **Instance는 엔진 객체가 아니라 엔진
객체를 가리키는 포인터(userdata)라, Lua가 참조를 안 들면 지워지고 나중에
`.Parent` 등으로 다시 얻으면 다른 포인터가 나올 수 있다.** 따라서:

```lua
local nop = false or function(...) end -- local이라 인라인 안 됨
local gchold = {nil}
local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
   nop(gchold, inst)
end)
gchold[1] = gcconn
```

*"이럼, inst 의 Destroy 이전 까지 inst 의 userdata 포인터는 유일하고,
gchold 도 생명주기 상 유지됨. gcconn 도 유지돼. **이게 우리의 Instance
생성 시 바로 할 일이 돼.**"*

그리고 `InstData:SetWeak(inst, "gchold"/"gcconn", ...)` — *"이미 gchold 는
안전히 유지된다는 점. **안전히 유지된다면 항상 weak 를 써**, 안 그럼
gc 에선 예상하기 힘들어지는 버그가 발생하기 쉬움."*

`bindLifetime(inst, v)`은 그 위에서:

```lua
local gchold = InstData:GetWeak(inst, "gchold")
gchold[v] = true                       -- 계약 1 (해시 멤버십 — 제거를 O(1)로)
BindData:SetWeak(v, "gchold", gchold)
BindData:SetWeak(v, "gcconn", InstData:GetWeak(inst, "gcconn"))  -- 계약 2
```

*"여기서 생각해볼 점은. gcconn 도 자동으로 제거된다는 점임. gcconn 의
클로저가 죽으면 gchold 가 죽고 gcconn 을 강참조 하는건 없으니까"* — 즉
`inst`가 Destroy되면 weak 항목이 스스로 비워져 `canExecute`가 자연히
거짓이 됨(그 전 구간은 `.Connected == false`가 커버).

`unbindLifetime`은 그 역이고 **`inst`를 안 받음**. `canExecute`도 안 받음:

```lua
local gcconn = BindData:GetWeak(v, "gcconn")
if gcconn ~= nil and gcconn.Connected then return true end
return v.Subscribed == true   -- 글로벌 등록 경로
```

마지막으로 호출부: *"이 이후, state 전파가 이걸 실행할지 말지를
canExecute 로 담당하도록 emit 이 등록되는거임. **클로저로써, state 안에
weak 로 들어가있지.**"* — 1라운드에서 "코드로 한 번도 안 나온다"고 지적한
바로 그 자리가 여기서 확정됨.

또 *"Observer 에 콜백이 등록 되자 마자 바로 호출되는건 observer 자체 원래
그런거고 이거랑 연관 없음"* — 최초 1회 실행은 게이팅 대상이 아님(기존
`slot-plan.md` 주석과 일치).

## 3라운드 — 이중 바인딩 게이트, `canBound` 폐기

사용자가 이어서: ObserverHandler(leaf)와 `Subscribe` 둘 다 **먼저
`canExecute`를 본다**. 참이면 "이미 사용중인 옵저버"라 에러 —
*"좀더 명확하게, Subscribed 필드를 읽어서 글로벌인지, 리프인지 알려줘."*
`Subscribe`는 `.Subscribed = true` + 전역 하드테이블 `[v]=true`,
`Unsubscribe`는 그 역.

여기서 **`canBound(handle)` 폐기**가 따라나옴 — "아직 안 묶였는가"와
"지금 실행 가능한가"가 같은 질문이고, `canBound`의 내부 근거로 지목돼
있던 `.Subscribed` 겸용이 애초에 오염이었으므로 정의 자체가 성립 안 함.

부수 효과: **죽은 바인딩의 재사용은 허용**(Destroy됐거나 unbind된 값은
게이트를 통과해 다른 `inst`에 다시 걸림). 막는 건 살아있는 이중 바인딩뿐.

### 확인 질문 2개 (사용자 스니펫의 오타)

1. `bindLifetime` 안의 `BindData:GetWeak(inst, "gchold")` — `InstData`에서
   읽어야 맞지 않나? → *"내 실수임. InstData 에서 가져오고 BindData에
   넣는거 맞음"*
2. `unbindLifetime`의 `...[1] = nil` — 넣을 땐 해시(`gchold[v]=true`)였는데
   지울 때 배열 인덱스? → *"도 실수 맞음. 해시로 지우면 돼"*

## 오염 경로 추적 (archive에 보존)

- **2026-08-07 (더 오래된 초안)**: `bind-system-plan.md`의 `:Subscribe()`
  절에 이미 **올바른 1-인자 모양**이 있었음 —
  `if self.Subscribed then return true end` / `if self.Connection then
  return self.Connection.Connected end`. 즉 "값 자신이 자기 커넥션을
  들고 있다"가 원래 그림이었음.
- **2026-08-08 (다섯 번째 세션)**: "재정정"이라는 이름으로 `(inst, value)`
  2-인자가 들어옴. `.Subscribed`에 "leaf 바인딩 생존"이라는 두 번째 의미를
  겹쳐 얹은 게 원인 — 그 순간 leaf 경로 생존을 `value`에게 물을 방법이
  사라져서 `inst` 조회가 유일한 경로가 됨. **2-인자는 증상이지 원인이
  아니었음.**
- **2026-08-09 (여섯 번째 세션)**: 그 위에 `canBound`를 세우고, *"이 내부
  플래그는 `canExecute`가 이미 보는 `.Subscribed` 필드 그 자체"*라고
  명문화하며 오염을 고착.

**왜 여섯 세션을 살아남았나** — 호출부가 한 번도 의사코드로 안 적혔기
때문. 진짜 호출부(State 전파 루프)엔 `inst`가 없어서 2-인자 시그니처는
거기서 **호출 자체가 불가능**했는데, 아무도 그 코드를 써보지 않았음.
`doc-check.py`가 잡을 수 있는 종류가 아님(문서 참조는 전부 정상이었음).

> **일반 교훈**: 계약(시그니처)을 정할 때 **호출부를 최소 하나는
> 의사코드로 같이 적어둘 것.** "어디선가 게이팅됨"은 검증이 안 되는 문장.

## 부수 확정 — gcconn을 Instance 생성 시점으로 올린 것의 의미

사용자의 userdata 포인터 논거가 `bindLifetime`을 넘어 **`inst`를 키로 쓰는
모든 `Relate`의 전제**임을 확인 — userdata가 회수되고 재생성되면
`elementOwner`/`nameClaims`/Tag 참조카운트 항목이 전부 조용히 미아가 됨
(크래시가 아니라 "부기가 없던 일이 되는" 오작동). 그래서 gcconn 셋업은
바인딩 유무와 무관하게 Instance 생성 시 무조건 실행되어야 하고, 이걸
`base/relate-plan.md`에 "전제" 절로 신설.

**대가**: 클로저가 `inst`를 캡처하므로 quad가 만든 Instance는 참조를 놓는
것만으로는 회수 안 되고 `Destroy`가 유일한 절단면이 됨. 다만 **실질적으로
새 제약은 아님** — 실제 바인딩이 하나라도 걸리면 그 Observer 클로저가
어차피 `inst`를 캡처해 같은 순환이 생기므로(예: `StoreBind.process`),
"아무것도 안 걸린 Instance"까지 같은 규칙으로 통일한 것뿐. 이 판단을
`lifecycle-pattern.md`에 명시적으로 남김.

또 사용자의 *"안전히 유지된다면 항상 weak 를 써"*를 `relate-plan.md`에
일반 규칙으로 승격 — 근거는 성능이 아니라 **디버깅 가능성**(강참조가 둘이면
"이 값의 수명이 어디서 끝나는가"의 답이 둘이 되어 한쪽만 지웠을 때 조용한
누수가 남음).

## 반영 결과

- `base/lifecycle-pattern.md` — 시그니처/구현 전면 재작성, (0) Instance 생성
  시점 셋업 / (1) bind·unbind·canExecute / (2) 전역 경로 / (3) `canBound`
  폐기 / (4) 실제 호출부 5개 절로 재구성.
- `archive/canexecute-inst-arg-reversed.md` 신설 — 역전 원문 + 오염 경로 +
  "호출부를 안 적어서 못 잡았다"는 교훈.
- `base/bind-system-plan.md` — `canBound` 절 역전, `:Subscribe()` 절
  스케치 정정, `state:Observer(fn)` 절에 실제 호출부 명시화.
- `base/dispatch-core-plan.md` — `unbindLifetime` 1-인자 2곳, "Observer가
  자기 `Subscribed`로 게이팅" 근거 정정.
- `base/relate-plan.md` — "전제 — `inst` 키의 동일성은 공짜가 아니다",
  "다른 곳에서 안전하게 유지되는 것은 항상 `SetWeak`" 두 절 신설.
- `base/effect-plan.md` / `base/slot-plan.md`(호출부 5곳 + 주석 2곳) /
  `base/architecture.md` / `base/store-semantics.md` /
  `research/pre-implementation-audit.md` — 시그니처·근거 정정.
- `luau-test`(`10`을 `rewrite-required/`로) / `audit/gcconn-trick-verification.md` /
  `ROADMAP.md` / `question.md` / `.claude/README.md` / `CLAUDE.md` — 동기화.

**새로 연 설계 질문 없음.** `question.md`의 `canExecute` 이름 3순위 항목은
이름 논의라 그대로 열려 있음(시그니처는 이번에 확정).
