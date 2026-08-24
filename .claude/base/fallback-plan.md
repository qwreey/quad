# `Fallback`/`Traceback` — 컴포넌트 에러 격리 유틸

**상태**: base — 확정(2026-08-14 세션). research/에서 신설(사용자 제안) →
`luau` 스파이크로 `xpcall`/`debug.traceback` 배선
실측(같은 날 두 번째 세션) → `Fallback`/`Traceback` 분리·정확한 제네릭
시그니처·`err: any` 확정(같은 날 세 번째 세션, 사용자 확정)까지 한 흐름 —
`base/`로 승격. **구현 우선순위는 여전히 맨 뒤**(아래 "우선순위" 절), 승격은
설계가 다 정해졌다는 뜻이지 지금 만든다는 뜻이 아님.

## 동기

컴포넌트마다 개별적으로 `pcall`을 직접 감싸는 건 실용적이지 않음 — 매
호출 자리마다
`local ok, result = pcall(MyComp, props); if not ok then ... end`를
손으로 반복해 쓰는 건 번거롭고 빠뜨리기도 쉬움. 대신 컴포넌트
함수 하나를 받아서 "에러 나면 자동으로 플레이스홀더를 그려주는 버전"으로
바꿔주는 아주 단순한 유틸이면 충분함 — 클린업 동작(언마운트/리소스 해제)이
목적이 아니라, **실제 에러가 났을 때 디버깅이나 프로덕션 유저 리포트를
편하게 만드는 게 유일한 목적**.

## 왜 새 프리미티브가 아닌가

`research/additional-primitives-plan.md`가 이미 "Error Boundary는 빈
자리 아님 — `pcall(MyComp, props)`만으로 React Error Boundary와 같은
격리 효과를 프레임워크 지원 없이 얻는다"고 확정해둔 결론을 뒤집는 게
아니라, **그 결론 위에 얹는 순수 슈가**(그 문서를 다시 열 필요 없음) —
`Operator` 콤비네이터(`research/operator-sugar-plan.md`)가 `:Compute`/
`:Apply` 위에 얹힌 것과 같은 관계. `Fallback`/`Traceback` 둘 다 `original`을
호출하고 결과를 그대로 돌려주는 순수 함수일 뿐, 디스패치/Store/Handler
계층에 아무것도 새로 안 만듦.

## API — 왜 둘로 나뉘는가

```
Fallback<OkComp, ErrComp, Args...>(
  base: (Args...) -> OkComp,
  onError: (err: any) -> ErrComp
) -> (Args...) -> (OkComp | ErrComp)

Traceback<OkComp, ErrComp, Args...>(
  base: (Args...) -> OkComp,
  onError: (err: any, trace: string) -> ErrComp
) -> (Args...) -> (OkComp | ErrComp)
```

- **`Fallback`** — `pcall` 기반, 가벼움, `onError`엔 `err`만 넘어감(trace
  없음).
- **`Traceback`** — `xpcall`+`debug.traceback` 기반, `onError`엔 `err`와
  함께 `trace: string`이 **항상**(옵셔널 아님) 넘어감.
- **왜 플래그 하나로 안 합쳤는가**: quad는 이미 이런 갈림을 별도 타입/함수로
  가르는 쪽을 택해왔음(`Ref`/`PreRef`가 같은 예) — 항상 `xpcall`+
  `debug.traceback` 비용을 물지 않아도 되는 가벼운 경로를 자연스럽게 분리해
  둘 수 있고, `onError`의 시그니처 자체가 달라서(trace 유무) 타입으로도
  둘을 구분하는 게 더 정확함.
- `OkComp`/`ErrComp`를 하나로 합친 `Comp`가 아니라 **독립 제네릭**으로 둔
  이유: 원래 컴포넌트와 에러 플레이스홀더가 다른 컴포넌트 타입일 수 있고,
  래핑된 함수의 실제 반환 타입은 정확히 `OkComp | ErrComp` 유니온이기
  때문(사용자 확정).
- `onError` 자신이 추가 컨텍스트를 캡처하려고 커링된 클로저인 건 완전히
  자유 — `Fallback`/`Traceback`은 여기 관여하지 않음(아래 예시).

```lua
local SafeWidget = Fallback(Widget, function(err)
    return ErrorPlaceholder { Message = err }
end)

-- 추가 컨텍스트가 필요하면 onError 쪽에서 그냥 커링
local function makeErrorHandler(context)
    return function(err, trace)
        return ErrorPlaceholder { Message = err, Context = context, Trace = trace }
    end
end
local SafeWidget2 = Traceback(Widget, makeErrorHandler(someContext))

-- 호출부는 원래 컴포넌트 대신 그대로 씀
Frame { SafeWidget{ ... }, SafeWidget2{ ... } }
```

### `err: any`임을 반드시 문서화 — 흔한 함정

Lua/Luau의 `error()`는 문자열이 아닌 **임의의 값**(테이블 등)을 던질 수
있음 — `Fallback`/`Traceback` 둘 다 `err`를 `any`로 그대로 전달하고
어떤 가공도 안 함. `error(msg)`를 레벨 지정 없이(Luau 기본 level=1)
호출하면 `err`가 문자열이더라도 quad가 아무것도 안 붙였는데 Luau가
자동으로 `"파일:줄: "` 위치 접두를 붙여서 옴 — `error(msg, 0)`으로
호출해야 접두 없는 순수 메시지가 옴. **다들 `err`를 `string`으로 가정하고
코드를 짜는 게 제일 흔한 실수라 문서화에서 최우선으로 경고할 것**(가공은
`Fallback`/`Traceback`이 대신해주지 않음 — 가공까지 대신해주면 그게 또
다른 매직이라는 원칙, `onError` 구현 몫으로 완전히 열어둠).

## 메커니즘 스케치

```lua
function Fallback(base, onError)
    return function(...)
        local ok, resultOrErr = pcall(base, ...)
        if ok then
            return resultOrErr
        end
        return onError(resultOrErr)
    end
end

function Traceback(base, onError)
    return function(...)
        local trace: string? = nil
        local ok, resultOrErr = xpcall(base, function(err)
            trace = debug.traceback(nil, 2)
            return err
        end, ...)
        if ok then
            return resultOrErr
        end
        return onError(resultOrErr, trace :: string)
    end
end
```

`Traceback`의 `debug.traceback(nil, 2)` 배선(클로저 업밸류가 `xpcall`
리턴 이후에도 정상적으로 보이는지, 중첩 호출에서도 실패 지점까지
스택을 정확히 담는지)과 `err: any`(테이블 에러도 손실 없이 통과하는지)는
`luau` 스파이크로 실측 확인됨 — `audit/fallback-xpcall-verification.md`
참고(스크립트: `audit/fallback-xpcall-spike.luau`).
`research/debug-tooling-plan.md`가 이미 확인해둔 선례(Vide/Fusion 둘 다
`xpcall`+`debug.traceback`으로 **에러 나는 순간에만** 스택을 찍는
패턴)를 그대로 재사용 — 새 트레이싱 메커니즘을 발명하지 않음.

## ⚠️ 미해결 — 실패 이전에 생성된 부분 트리는 회수되지 않는다 (2026-08-24 신설, 6라운드 손 트레이싱 `H-26`)

**상태: 백로그.** `Fallback`/`Traceback` 자체가 슈가라 **그 둘을 구현할 때 같이
다룬다**(사용자 판단, 2026-08-24: *"의도적으로 error 를 사용하고자 하는 경우
항상 컴포넌트들이 쌓이거든. 이건 후행에서 더 다뤄보도록 백로깅해줘.
fallback/traceback 자체가 슈거라서, 그 때 가서 생각해도 될듯"*).

**무엇이 문제인가**: quad는 자기가 만든 Instance마다 생성 즉시 gcconn을 걸고 그
클로저가 `inst`를 캡처하므로(`base/lifecycle-pattern.md`의 "(0)" 절)
**참조를 놓는 것만으로는 회수되지 않고 반드시 `Destroy`로만 회수된다.** 이
모델은 "만든 Instance는 언젠가 반드시 `Destroy`된다"를 전제하는데, 컴포넌트가
자기 리터럴을 만드는 도중 예외를 던지면 그때까지 완성된 형제/자손은 **트리에
붙지도, `Destroy`되지도 않은 채** 예외에 실려 스코프를 빠져나간다.

```lua
local function Broken(props) error("bug!") end
local function Parent(props)
    return Frame {
        Frame { Text = "child A" },   -- (1) 완주 — gcconn/gchold 확정
        Broken {},                    -- (2) error
        Frame { Text = "child C" },   -- (3) 도달 안 함
    }
end
local SafeParent = Fallback(Parent, function(err) return Frame { Text = tostring(err) } end)
```

Lua 테이블 생성자는 원소를 좌→우로 완전히 평가하므로 `child A`는 실제
Instance로 완성되고 gcconn이 걸린다. 바깥 `Frame(...)` 호출은 인자 테이블조차
완성 못 해 **호출되지 않는다.** `Fallback`은 `pcall(base, ...)` 하나라 그
존재를 알 방법이 없고, `child A`는 (a) 어떤 지역 변수에도 안 남고 (b) 세팅된
적 없고 (c) 아무도 모르므로 — 자기 gcconn↔gchold 순환만이 그를 살려두고 그걸
끊는 유일한 수단(`Destroy`)을 부를 주체가 없다. **참조 0개인데 세션 끝까지 안
죽는다.** 실패 지점 앞에 중첩 서브트리가 있으면 그 전체가 대상이다.

**왜 `Fallback`/`Traceback`이 대표 사용처인가**: 이 문제는 이 둘 전용이 아니라
"부분 실패 후 아무도 `Destroy`를 안 부르는 모든 경로"의 일반적 위험인데,
**그 경로를 계속 살려두는 것을 존재 이유로 삼는** 게 정확히 이 둘이다.
예외가 밖으로 나가 아무것도 안 그려지는 기본 경로는 서술 정정으로 끝났지만
(같은 날 `base/dispatch-core-plan.md`에서 잔여 부기가 인스턴스 GC로 정리된다고
적은 **틀린 안전망 주장**을 삭제했다), 이쪽은 앱이 계속 도는 걸 약속하는
자리라 층위가 다르다.

**구현 시 검토할 갈래**(지금 정하지 않음):
1. `New`/`Dispatch.drive`가 "이번 construction에서 만든 것" 목록을 쌓고
   `pcall` 실패 시 역순 `Destroy` — 누수를 실제로 닫지만 **정상 경로에도**
   부기 비용이 붙고, 중첩 구성 경계를 어떻게 잡을지가 또 문제다.
2. gcconn 자기순환 재고(한 번도 Parent 안 된 채 참조가 끊기면 GC 가능하게) —
   `lifecycle-pattern.md` (0)의 핵심 트레이드오프를 건드리므로 재설계 규모가 크다.
3. UB로 명문화 + 컴포넌트 저작자에게 "생성 전에 검증부터" 권고.

**참고 — 인접 사례는 이미 인정돼 있다**: `materializeSlotTree`의 예외 시
Blocker가 켜진 채 남는 갭은 사용자 판단으로 이미 *"마운트 도중 예외는 quad가
복구를 보장하지 않는 상태"*로 정리됐다(`base/slot-plan.md`). 다만 그건
마운트 경로에 한정된 국소적 결과다.

## 패키지 배치

`quad-base` — `base`를 그냥 호출하고 결과를 그대로 돌려주는 순수 함수라
Store/Dispatch 어디에도 안 걸림, 엔진 지식이 전혀 필요 없음. `Operator`
콤비네이터와 같은 결(사용자 확정).

## 이름

`Fallback`/`Traceback` 확정 — 낱개 함수 둘뿐이라 `Tag`/`Attribute`류
네임스페이스가 필요했던 것과 달리 충돌 표면이 작다고 판단, 용어 정리
대기열에 안 올리고 바로 점유(사용자 확정).

## 우선순위

**형제 백로그 항목들(`quad-mock`/`quad-debug`/문서 사이트/`Operator`)과
동급, 맨 뒤 — "quad 개발 상당 부분 끝난 뒤"로 사용자가 못박은 후순위**
(`.claude/todos.md` 4번). 이 문서가 `base/`로 승격된 건 설계가 다
확정됐다는 뜻이지, 구현 착수 순서가 앞당겨졌다는 뜻이 아님 — `Operator`처럼
순수 슈가라 없어도 quad 기능상 완전함(`pcall`을 직접 쓰면 되므로).
