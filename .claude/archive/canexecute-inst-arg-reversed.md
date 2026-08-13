# [역전됨] `canExecute(inst, value)` 2-인자 + `bindLifetime`이 `.Subscribed`를 세팅 — 둘 다 오염, `canExecute(value)` 1-인자로 정정

**역전 일시**: 2026-08-14 (다섯 번째 세션). **원 확정 일시**: 2026-08-08
(다섯 번째 세션, "재정정"이라는 이름으로 들어옴) ~ 2026-08-09 (여섯 번째
세션, `canBound`가 이 전제 위에 세워짐).
**현재 유효한 설계**: `base/lifecycle-pattern.md`의
"`bindLifetime`/`canExecute`/`unbindLifetime`" 절이 최종 소스.

## 역전된 사례 — 원래 무엇을 확정했었나

```lua
bindLifetime(inst: any, value: any): ()
unbindLifetime(inst: any, value: any): ()
canExecute(inst: any, value: any): boolean
```

그리고 `bindLifetime` 구현 스케치가 이랬음:

```lua
function bindLifetime(inst, value)
    ...
    gchold[value] = true
    if isOE then value.Subscribed = true end -- canExecute가 보는 필드 그대로 재사용
end

function canExecute(inst, value)
    if (isObserver(value) or isEffect(value)) and not value.Subscribed then
        return false
    end
    local gcconn = relate:GetStrong(inst, GCCONN)
    return gcconn ~= nil and gcconn.Connected
end
```

당시 명시된 근거(2026-08-08 세션 원문): *"Observer 자신의 바인딩
생존(`Subscribed`)과 `inst` 자체 생존(gcconn)은 **독립적인 두 조건**이라
하나의 opaque `handle`로 뭉치면 'inst는 살아있지만 이 Observer는 이미
`:Unsubscribe()`됨' 케이스를 못 구별함."*

여기에 2026-08-09 여섯 번째 세션이 한 겹 더 얹어, `bind-system-plan.md`의
`canBound(handle)` 절에 **"이 내부 플래그는 새 필드가 아니라 `canExecute`가
이미 보는 `.Subscribed` 필드 그 자체"**라고 못박고, `bindLifetime`/
`unbindLifetime`이 이 필드를 세팅/해제하는 것으로 확정했음.

## 왜 틀렸나

**`.Subscribed`는 전역 `:Subscribe()` 경로 전용 필드이고, `bindLifetime`과는
일절 이해관계가 없다**(사용자가 여러 차례 명시해온 내용). 위 설계는 이
필드에 "leaf 바인딩도 살아있음"이라는 두 번째 의미를 억지로 겹쳐 얹었고,
그 순간 **leaf 경로의 생존을 `value`에게 물을 방법이 사라져서** 남은 유일한
경로가 "`inst`의 gcconn을 조회한다"가 됐음 — 2-인자 시그니처는 그 오염의
*증상*이지 원인이 아니었음.

정확한 분해는 이것:

| 묻는 것 | 근거 | `value`만으로 가능? |
| --- | --- | --- |
| 전역으로 등록됐나 | `value.Subscribed` 필드 | O |
| 묶인 `inst`가 살아있나 | `bindLifetime`이 `value` 쪽 릴레이션에 **복사해둔 gcconn** | O |

즉 두 조건이 "독립적"이라는 관찰 자체는 맞았지만, 그로부터 "`inst`를 인자로
받아야 한다"는 결론이 안 나옴 — `bindLifetime`이 바인딩 시점에 gcconn 참조를
`value` 쪽으로 복사해두면 둘 다 `value` 하나로 물을 수 있음. 실제로
2026-08-07 시점의 더 오래된 초안(`bind-system-plan.md`의 `:Subscribe()` 절)에
이미 올바른 모양이 스케치돼 있었음:

```lua
if self.Subscribed then return true end
if self.Connection then return self.Connection.Connected end
```

2026-08-08의 "재정정"은 이 초안을 개선한 게 아니라 **되돌린 것**이었음.

## 놓친 신호 — 호출부가 코드로 한 번도 안 나왔다

이 오류가 여섯 세션 넘게 살아남은 이유는 **`canExecute`의 실제 호출부가
어느 문서에도 코드로 등장한 적이 없기 때문**. `bind-system-plan.md`/
`source-state-plan.md`(당시 store-semantics.md)/`slot-plan.md`는 전부 "발화 시 `canExecute`로 게이팅됨"
같은 **서술만** 하고 넘어갔고, `dispatch-core-plan.md`는 아예
"핸들러가 직접 `canExecute`를 재구현할 필요 없음 — Observer가 이미 자기
`Subscribed` 상태로 게이팅됨"이라고 적어 호출부를 없는 것처럼 만들었음.

실제 호출부는 **State의 전파 루프**인데, 거기엔 `inst`가 없고 있어서도 안 됨
(State는 자기가 어느 Instance에 걸렸는지 모르는 게 정상 — 여러 곳에 걸릴 수
있음). 즉 2-인자 시그니처는 **진짜 호출부에서 호출 자체가 불가능**했고,
아무도 그 코드를 써보지 않아서 드러나지 않았을 뿐임.

**일반 교훈**: 계약(시그니처)을 정할 때 **호출부를 최소 하나는 의사코드로
같이 적어둘 것.** "어디선가 게이팅됨"이라는 서술은 검증이 안 되는 문장이고,
실제로 이 코퍼스에서 여섯 세션을 살아남았음. `.claude/tools/doc-check.py`가
잡을 수 있는 종류가 아니므로(문서 참조는 전부 정상이었음) 사람/에이전트
감사 체크리스트 쪽에 남김.

## 같이 폐기된 것

- **`canBound(handle)`** — 이 오염된 `.Subscribed` 재사용 위에 세워진
  predicate라 정의 자체가 성립 안 함. `canExecute(value)` 하나로 통합
  (`base/lifecycle-pattern.md`의 "`canBound` 폐기" 절).
- **gcconn/gchold의 lazy 생성** — `bindLifetime` 첫 호출에서 만들던 것을
  **Instance 생성 시점**으로 올림. 이유는 이 역전과 별개(Instance userdata
  포인터 동일성 — `inst`-키 `Relate` 전체의 전제), 같은 세션에 확정돼 같은
  절에 반영됨.
