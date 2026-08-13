# 컴포넌트 에러 격리 유틸 — `Fallback`

**상태**: research — 사용자 제안(2026-08-14 세션)으로 신설, 착수 전
백로그. `research/additional-primitives-plan.md`가 이미 "Error Boundary는
빈 자리 아님 — `pcall(MyComp, props)`만으로 React Error Boundary와 같은
격리 효과를 얻는다"고 확정해둔 결론을 뒤집는 게 아니라, **그 결론 위에
얹는 순수 슈가**(그 문서를 다시 열 필요 없음) — `Operator` 콤비네이터
(`research/operator-sugar-plan.md`)가 `:Compute`/`:Apply` 위에 얹힌 것과
같은 관계. 우선순위는 그 형제 백로그 항목들(`quad-mock`/`quad-debug`/
문서 사이트/`Operator`)과 동급 — "quad 개발 상당 부분 끝난 뒤"로 사용자가
명시(`CLAUDE.md` "지금 할 일" 4번).

## 동기 (사용자 원 메모)

컴포넌트마다 개별적으로 `pcall`을 직접 감싸는 건 실용적이지 않음 — 매
컴포넌트 호출 자리마다
`local ok, result = pcall(MyComp, props); if not ok then ... end`를
손으로 반복해 쓰는 건 번거롭고 빠뜨리기도 쉬움. 대신
컴포넌트 함수 하나를 받아서 "에러 나면 자동으로 플레이스홀더를 그려주는
버전"으로 바꿔주는 아주 단순한 유틸이 있으면 충분함 — 클린업 동작
(언마운트/리소스 해제)이 목적이 아니라, **실제 에러가 났을 때 디버깅이나
프로덕션 유저 리포트를 편하게 만드는 게 유일한 목적**.

## 제안 API — `Fallback(original, onError) -> wrapped`

```
Fallback(
  original: (T...) -> Comp,
  onError: (errorMessage: string, trace: string?) -> Comp
) -> (T...) -> Comp
```

`original`은 평범한 컴포넌트 함수(`function(props) return Frame{...} end`
모양) 그대로. `Fallback`은 그걸 감싼 **같은 시그니처의 새 컴포넌트 함수**를
돌려주므로, 호출부 입장에선 원래 컴포넌트를 쓰던 자리에 그대로 대체해
끼워 넣을 수 있음(`MyComp{...}` → `Fallback(MyComp, OnMyCompError){...}`).

```lua
local SafeWidget = Fallback(Widget, function(message, trace)
    return ErrorPlaceholder { Message = message }
end)

-- 호출부는 Widget 대신 SafeWidget을 그대로 씀
Frame { SafeWidget{ ... } }
```

### 메커니즘 스케치 — 새 프리미티브 아님, `pcall`/`xpcall` 위의 순수 함수

```lua
function Fallback(original, onError)
    return function(...)
        local trace: string? = nil
        local ok, resultOrErr = xpcall(original, function(err)
            trace = debug.traceback(nil, 2)
            return err
        end, ...)
        if ok then
            return resultOrErr
        end
        return onError(resultOrErr, trace)
    end
end
```

(의사코드 수준 — `xpcall` 에러 핸들러 안에서 잡은 `trace`를 업밸류로
빼내는 게 실제로 원하는 순서/타이밍에 실행되는지는 Luau로 직접 실측
필요, 아래 "열린 질문" 참고.) `research/debug-tooling-plan.md`가 이미
확인해둔 선례(Vide/Fusion 둘 다 `xpcall`+`debug.traceback`으로 **에러
나는 순간에만** 스택을 찍는 패턴)를 그대로 재사용 — 새 트레이싱
메커니즘을 발명하지 않음.

### `ErrorComp`가 추가 상태가 필요하면 — 커링 (사용자 명시)

`onError` 자체가 클로저이므로, 별도 API 없이 그냥 커링으로 풀림:

```lua
local function makeErrorHandler(context)
    return function(message, trace)
        return ErrorPlaceholder { Message = message, Context = context }
    end
end

local SafeWidget = Fallback(Widget, makeErrorHandler(someContext))
```

`Fallback` 자신은 이런 경우를 특별히 신경 쓸 필요 없음 — `onError`가
이미 평범한 함수이기 때문.

## 왜 기존 "Error Boundary는 빈 자리 아님" 결론과 안 부딪히는가

`research/additional-primitives-plan.md`의 결론은 "새 프리미티브가 필요
없다"는 것이었지 "지금 이대로 편하다"는 게 아니었음 — `Fallback`은 그
문서가 이미 지목한 정확히 같은 메커니즘(`pcall(MyComp, props)`)을 감싸는
얇은 편의 함수일 뿐, 디스패치/Store/Handler 계층에 아무것도 새로 안 만듦.
`Operator` 콤비네이터가 `:Compute`/`:Apply` 위에서 그랬던 것과 동일한
관계 — 그 문서를 다시 열 필요 없음.

## 열린 질문

- **`pcall` vs `xpcall`+`debug.traceback`**: 스택 트레이스까지 항상
  캡처할지, 아니면 가벼운 `pcall`(에러 메시지만)을 기본으로 하고 트레이스는
  옵션(`onError`가 2번째 인자를 안 받으면 그냥 안 계산)으로 둘지. Roblox
  `debug` 라이브러리가 제한적이라는 건 이미 확인돼 있어서(`debug-tooling-plan.md`)
  부담은 크지 않아 보이나 실측 필요.
- **`xpcall` 에러 핸들러 배선의 실측**: 위 의사코드가 실제 Luau에서
  그대로 동작하는지(에러 핸들러 안에서 클로저 업밸류에 쓴 값이 바깥에서
  제대로 보이는지 등) 착수 시점에 `luau`로 직접 확인 필요.
- **패키지 배치**: `original`을 그냥 호출하고 결과를 그대로 돌려주는
  순수 함수라 Store/Dispatch 어디에도 안 걸림 — `quad-base`(엔진 무종속)가
  자연스러워 보임, `Operator`와 같은 결. 최종 확인 필요.
- **이름**: `Fallback`이 흔한 단어라 top-level 노출 시 충돌 위험 — 다른
  가칭들과 같은 용어 정리 대기열로 볼지, 아니면 이 유틸 하나뿐이라
  네임스페이스 없이 top-level 함수로 둬도 괜찮을지(`Tag`/`Attribute`류
  네임스페이스가 필요했던 건 그 안에 여러 이름이 몰려서였고, 이건 낱개
  함수 하나뿐이라 충돌 표면이 작음).
- **프로덕션에서의 동작**: 에러 메시지/트레이스를 유저에게 보이는 화면에
  그대로 노출할지, 아니면 로그로만 보내고 화면엔 일반화된 메시지만
  보여줄지는 `onError` 구현(사용자 코드) 몫으로 완전히 열어두는 게 맞아
  보임 — `Fallback` 자체는 raw 에러 정보를 그대로 넘기기만 하고 가공은
  안 함(가공까지 대신해주면 그게 또 다른 매직).
- 그 외 확정된 결정 없음 — 착수 시점에 위 항목들을 순서대로 확인.

## 우선순위

**형제 백로그 항목들과 동급, 맨 뒤.** `Operator`처럼 순수 슈가라 없어도
기능 격차 없음(`pcall`을 직접 쓰면 되므로, `additional-primitives-plan.md`가
이미 확인한 그대로) — 편의성 문제일 뿐.
