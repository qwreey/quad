# [역전됨] `Dispatch.processAs`/`Dispatch.retractSelfAndUnder` 체크포인트 핸들러 패턴

**상태**: 역전됨 — 2026-08-13 네 번째 세션에 신설, 같은 날 다섯 번째
세션에 `chains`를 핸들러 객체 identity가 아니라 **인덱스**로 추적하는
더 근본적인 재설계로 대체되며 통째로 불필요해짐. 원문(신설 당시
`base/bind-system-plan.md`에 있던 그대로) + 역전 이유를 여기 보존.

## 신설 배경 (네 번째 세션)

`base/attribute-plan.md`의 그룹(`Attribute(...)`)이 여러 이름을 기존
단일 키 `AttributeKey` 경로에 재귀 위임하면서, 예전엔 `rawNew(name)`로
그룹 전용 키 객체를 만들고 `owners`라는 별도 `Relate` 레지스트리로
"누가 이 이름을 관리 중인가"를 수동 추적했음 — 이 방식이 "그룹이 이름을
놓았다 나중에 같은 그룹이 다시 그 이름을 포함하면 자기 자신과 충돌"하는
실제 버그로 이어져(소유권 반납이 `process`의 `v==nil` 분기에만 있어서,
그룹이 이름을 통째로 놓는 경로는 그 분기를 안 타서 옛 키가 영원히 남음),
전면 재설계됨.

## 원문 (신설 당시 pseudocode 그대로)

```lua
function Dispatch.processAs(inst, k, v, handler)
    -- getHandler 스캔을 건너뛰고 handler를 직접 지정 — isHandlable이
    -- 없는(스캔 자체에 안 걸리는) 체크포인트 핸들러 전용 진입점.
    -- push 직전 중복 검사는 Dispatch.process와 완전히 동일(같은 재진입 가드).
    local list = chains:GetStrong(inst, k) or {}
    for _, existing in list do
        if existing == handler then
            error("Dispatch: handler already active for this (inst,k) — re-entrant processAs")
        end
    end
    table.insert(list, handler)
    chains:SetStrong(inst, k, list)
    handler.process(inst, k, v)
end

function Dispatch.retractSelfAndUnder(inst, k, target, v)
    -- retractUnder와 동일하되 target "이하"(자기 자신 포함)까지 지움 —
    -- cutoff를 target의 인덱스가 아니라 그 한 칸 앞으로 잡는 것만 다름.
    local list = chains:GetStrong(inst, k)
    if not list then return end
    local cutoff = 0
    if target then
        for i, h in list do if h == target then cutoff = i - 1 break end end
    end
    for i = #list, cutoff + 1, -1 do
        list[i].retract(inst, k, if i == cutoff + 1 then v else nil)
        list[i] = nil
    end
end
```

**쓰는 쪽 패턴**: 위임하는 핸들러(`AttributeGroupHandler`)가 자기 전용
체크포인트 싱글톤(`AttributeGroupKeyHandler`, `isHandlable` 없음, `process`는
가공 없이 `Dispatch.process(inst,k,v)`로 그대로 전달해 실제 매치는 정상
스캔에 맡김, `retract`는 no-op — 자기 자원이 없는 순수 마커)을
`Dispatch.processAs(inst,k,v,checkpoint)`로 체인 맨 위에 꽂고, 나중에 그
이름을 완전히 정리할 때 `Dispatch.retractSelfAndUnder(inst,k,checkpoint,v)`
한 번으로 체크포인트 자신을 포함해 그 아래 전부를 정리.

당시 장점으로 꼽았던 것: 소유권 충돌 감지가 기존 "같은 (inst,k)에 같은
핸들러 재사용 시 error" 가드(`State<State<T>>` 가드와 동일 메커니즘)에
공짜로 얹힘 — 별도 `owners` 레지스트리 불필요.

## 역전 이유 (다섯 번째 세션, 같은 날)

사용자가 근본 문제를 다시 짚음: `chains`가 핸들러 **객체 identity**로
포지션을 추적하는 것 자체가 `State<State<T>>`가 UB여야 했던 원인이었고
(같은 싱글톤이 재귀로 스스로와 매치되면 identity로 구분 불가), 체크포인트
패턴은 그 문제를 Attribute 한정으로 우회한 것일 뿐 근본 해법이 아니었음.

대신 `chains`를 명시적 **재귀 깊이 인덱스**로 추적하도록 바꾸면(같은 키
재귀는 `index+1`, 다른 키로 위임은 `index=1`부터) 두 가지가 동시에
풀림:

1. `State<State<T>>`가 UB에서 **정상 지원 대상**으로 바뀜 — 각 재귀
   단계가 서로 다른 인덱스를 쓰므로 객체 identity 충돌 자체가 발생하지
   않음(순환 참조만 여전히 UB로 남음, 기존 "순환은 UB" 원칙과 같은 급).
2. Attribute 그룹은 체크포인트 마커 없이 `Dispatch.process(inst,
   AttributeKey(name), source, 1)`을 직접 부르면 됨 — "인덱스 1이 이미
   점유돼 있는가"라는 occupancy 체크가 소유권 충돌 감지를 그대로
   대신함, 별도 마커 객체·`processAs`·`retractSelfAndUnder` 전부 불필요.

`retractSelfAndUnder`가 `retractUnder`와 딱 하나(cutoff를 target
포함이냐 미만이냐)만 다른 거의 중복 함수였다는 것도 별도로 지적됨 —
새 모델의 `Dispatch.retractFrom(inst,k,index,v)` 하나가 "자기 포함
철거"(`index` 그대로 넘김)와 "자기 아래만 철거"(`index+1` 넘김) 둘 다
호출자의 인덱스 선택만으로 표현하므로 두 함수로 쪼갤 이유 자체가
없어짐.

**교훈**: 기존 메커니즘 위에 새 진입점을 얹어 특정 사례(Attribute)를
푸는 것보다, 그 문제를 만든 더 근본적인 표현(객체 identity 기반 추적)을
먼저 의심하는 게 나을 때가 있음 — 오늘 하루 안에서 신설과 역전이 바로
이어진 사례. 최신 설계는 `base/bind-system-plan.md`의 "Dispatch 체인"
절 참고.
