# 무한 트윈(RepeatCount = -1) × Destroy/Parent=nil/GC/Cancel 실측 — 2026-09-21

**계기**: round12 Q71 후속. `tween-completed-2026-09-21/REPORT.md` 사실 5(유한 트윈은 파괴된 인스턴스 위에서 끝까지 돌아 `Completed`를
낸다)의 연장으로, 같은 문서 끝 문단이 "미실측"으로 남겨둔 것 — `RepeatCount = -1` 트윈을 철거 없이 `Destroy`하면 엔진이 시체 위에서
영원히 도는가. 아래는 그 실측.

**환경**: Studio Edit 스레드(샌드박스 `Place1.rbxl`, 같은 세션). 스크래치는 `CoreGui.QuadProbe-InfiniteTween-1789982450`(Folder) 하나
아래 `ScreenGui`를 테스트별로 붙여 사용, 끝에 통째로 `Destroy`. **참고**: 이 MCP 실행 스레드에서 `_G`와 `shared`는 둘 다 `nil`(각
`execute_luau` 호출이 완전히 새 환경에서 돎) — 호출 사이에 상태를 넘길 방법이 없어 스크래치 폴더 이름을 문자열로 하드코딩해 매 호출마다
`CoreGui:FindFirstChild(name)`으로 다시 찾았다. 또한 이 샌드박스의 `collectgarbage`는 `"count"`만 허용하고 `"collect"`를 거부한다
(`collectgarbage must be called with 'count'; use gcinfo() instead`) — 그래서 GC 압박은 `probe-log.md` 테스트 7·8과 같은 관용구
(`table.create(5000)` × 20회 할당 + `task.wait(0.05)`를 에포크마다 반복)로 걸었다.

## 사실

1. **무한 트윈 재생 중 `Destroy()`** — `TweenInfo.new(0.2, Linear, Out, -1, true)`로 만든 트윈을 `Play()`한 뒤 0.05초 뒤 대상 Frame을
   `Destroy()`, 그 뒤 `task.wait(1)`을 5회(5초) 돌며 관측: `tween.PlaybackState`는 5초 내내 `Playing` 그대로, `tween.Instance == frame`은
   계속 `true`(파괴된 인스턴스를 그대로 가리킴), `Completed`는 5초 동안 **한 번도 안 남**(`completedCount=0` — `RepeatCount=-1`이라 자연
   종료가 없으니 당연함), `frame.BackgroundTransparency`는 매초 다른 값으로 계속 바뀜(`0.6711 → 0.3306 → 0.7482 → 0.1662 → 0.8333`) — 엔진이
   시체 위에서 트윈을 계속 재생 중임을 값 변화로 직접 확인. 실측 끝에 살아있는 `tween` 변수로 `:Cancel()`을 부르니 **즉시**
   `PlaybackState=Cancelled`로 바뀜 — 무한 트윈도 살아있는 핸들만 있으면 언제든 `Cancel`로 멈출 수 있다.
   ```lua
   local info = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true)
   local tween = TweenService:Create(frame, info, {BackgroundTransparency = 1})
   tween:Play()
   task.wait(0.05)
   frame:Destroy()
   -- 이후 task.wait(1) x5 동안 tween.PlaybackState / tween.Instance == frame / frame.BackgroundTransparency 를 매번 읽음
   ```

2. **`Parent = nil` 대조군** — 같은 셋업에서 `Destroy()` 대신 `frame.Parent = nil`. 4초(`task.wait(1)` x4) 동안 사실 1과 **완전히
   동일한 패턴**: `PlaybackState=Playing` 유지, `tween.Instance == frame` 계속 `true`, `Completed` 0회, 값은 계속 변함
   (`0.6759 → 0.1669 → 0.8369 → 0.0809`). 즉 무한 트윈 관점에서 `Destroy()`와 `Parent = nil`은 구분되지 않는다 — 기존 유한 트윈
   실측(`REPORT.md` 사실 6)과 같은 결론이 무한 트윈에도 그대로 적용됨.

3. **GC/피닝 — 약한 값 테이블(`{__mode="v"}`)에 담고 강한 참조를 전부 제거한 뒤 GC 압박을 가한 결과, 세 경우 모두 몇 에포크 안에
   *Lua 래퍼 자체는* 수거됐다 — 단 그것이 엔진 쪽 동작을 멈추지는 않는다.**
   - **3-A(재생 중인 무한 트윈)**: `wkA2 = setmetatable({t}, {__mode="v"}); t = nil` 뒤 GC 압박 에포크를 돌리자 **7에포크(40 캡)
     만에 `wkA2[1]`이 `nil`**이 됨 — Lua에서 그 Tween 객체로의 마지막 강한 경로가 끊기자 바로 회수됐다는 뜻. 그런데 그 트윈이
     쓰던 Frame(`frameA2`)은 `ScreenGui` 자식으로 다른 곳에 여전히 강하게 붙어 있었고, **래퍼가 수거된 뒤에도** 그
     `frameA2.BackgroundTransparency`를 다시 읽으면 계속 변했다(`0.3303 → 0.3349 → 0.4157`, 이어서 3초 뒤에도
     `0.5038 → 0.4173 → 0.6675`) — **`TweenService`가 트윈을 계속 돌리는 것은 Lua 쪽 강한 참조 때문이 아니다. 엔진(C++) 내부에서
     별도로 관리되므로, 그 트윈을 가리키던 마지막 Lua 래퍼가 통째로 GC돼도 트윈 자체는 전혀 영향받지 않고 계속 돈다.**
     **부작용(실측 중 실제로 발생)**: 래퍼가 사라진 뒤에는 그 트윈에 다시 접근할 방법이 없다(`TweenService`는 활성 트윈 목록을
     공개하지 않음) — 그래서 **`:Cancel()`로 멈출 수조차 없게 됐다.** 이 실험에서 만든 무한 트윈 하나는 실제로 이 상태가 됐고,
     핸들이 없어 정리 단계에서 `Cancel`을 부르지 못했다(아래 "정리" 절 참고) — 이 Studio 세션이 끝날 때까지 백그라운드에서
     계속 돈다는 뜻이며, 이건 이 실험 자체가 의도적으로 만든 상태다(값도 인스턴스도 남에게 보이지 않게 폐기했으므로 실질적
     피해는 없음, 다만 "핸들을 잃으면 무한 트윈은 진짜로 멈출 방법이 없다"는 사실을 그대로 보여준다).
     ```lua
     local t = TweenService:Create(frameA2, infoInf, {BackgroundTransparency = 1})
     t:Play()
     local wkA2 = setmetatable({t}, {__mode = "v"})
     t = nil
     -- 에포크마다: for _=1,20 do table.create(5000) end; task.wait(0.05); check wkA2[1] == nil
     ```
   - **3-B(유한 트윈, 완료 후 약한 보유)**: 0.2초 트윈이 끝나길 기다린(`task.wait(0.4)`) 뒤 같은 압박을 걸자 **4에포크만에 수거됨**
     — 평범한 Lua GC 그대로(참조가 없으면 회수), 특이점 없음.
   - **3-C(파괴된 Frame, 그 위에서 무한 트윈이 계속 재생 중, Frame 자체를 약한 테이블에만 담고 Frame·트윈 참조를 모두 버림)**:
     `frameC:Destroy()` 뒤 `wkC = setmetatable({frameC}, {__mode="v"}); frameC = nil; t3 = nil`로 전부 버리자 **4에포크만에
     `wkC[1]`도 `nil`**(수거됨). 다만 파괴+고아 상태라 그 뒤로는 그 인스턴스를 어디서도 다시 찾을 방법이 없어(부모도 없고
     아무 테이블에도 안 남음) **"래퍼가 수거된 뒤에도 그 프로퍼티가 계속 바뀌는가"는 직접 재확인이 불가능했다** — 사실을 지어내지
     않고 명시: 3-A가 "래퍼 수거와 엔진 쪽 트윈 동작은 무관하다"를 이미 증명했으므로 같은 일이 여기서도 벌어지고 있을 것으로 강하게
     추정되지만(사실 1이 "파괴된 인스턴스 위 무한 트윈은 계속 돈다"도 이미 보였으므로 둘을 합치면 사실상 확실), **핸들이 없어서
     측정 자체를 할 수 없었다는 점은 그대로 보고한다.**

4. **파괴된 인스턴스 위의 트윈에 `:Cancel()`** — 사실 1과 같은 셋업으로 새로 만든 트윈을 0.1초 재생 후 대상 Frame을 `Destroy()`,
   0.8초 더 기다려 값이 계속 바뀌는 걸 확인한 뒤(`beforeCancel=0.9201`, `justBeforeCancel=0.5829`) `tween4:Cancel()`을 호출 —
   **`PlaybackState`는 호출 직후 동기적으로 `Cancelled`로 바뀌고**(`immediateState=Enum.PlaybackState.Cancelled`),
   `BackgroundTransparency`는 그 순간 값(`0.5829`)에 그대로 얼어붙어 이후 1.5초(`task.wait(0.5)` x3) 동안 **전혀 안 바뀜** —
   `Cancel()`은 파괴된 인스턴스 위에서도 정상적으로 엔진 쪽 재생을 멈춘다. `Completed`는 `Enum.PlaybackState.Cancelled`로
   정확히 1회 발화(`completedFired=[Enum.PlaybackState.Cancelled] count=1`).

## 설계에 주는 함의

핸들(트윈 객체에 대한 Lua 참조)만 계속 쥐고 있으면 `Cancel()`은 파괴된 인스턴스 위에서도, 무한 트윈에서도 항상 동기적으로 먹힌다(사실
1 끝부분·사실 4) — 그러니 quad가 철거 경로에서 핸들을 계속 쥐고 있는 한 무한 트윈이 시체 위에서 영원히 도는 상황 자체는 항상 피할 수
있다. 문제는 핸들을 놓치는 경우다: 사실 3-A가 보이듯 `TweenService`가 트윈을 계속 돌리는 것은 Lua GC 루트가 아니라 엔진 내부 상태이므로,
Lua 쪽에서 그 트윈으로 가는 마지막 강한 참조가 사라지는 순간 Lua 래퍼는 곧바로 회수되고 그 뒤로는 **`Cancel`로 멈출 방법이 영영 없어진다**
— `RepeatCount=-1` 트윈을 철거 없이(핸들을 안 쥔 채로) `Destroy`하면 세션이 끝날 때까지 계속 도는 상태가 실제로 재현됐다. 즉 quad의
철거 경로가 만든 `tweenSlots` 레코드가 `Tween` 핸들을 살아있는 동안 계속 쥐고 있다는 사실 자체가 "필요하면 언제든 멈출 수 있다"의
유일한 보장선이고, 그 레코드가 트윈 완료/철거 전에 어떤 이유로든 핸들을 놓치면(레코드 자체가 GC되는 등) 무한 트윈에 한해 복구 불가능한
누수가 된다.

## 정리

만든 스크래치 인스턴스는 모두 `Destroy()`됐다(마지막 확인: `root existed=true children-before-destroy=[T1,T2,T3,T3] root destroyed,
still-present-after=false` — `CoreGui`에 남은 `QuadProbe-InfiniteTween-*` 없음). 트윈은 핸들이 남아있던 것 전부(`tween`/`tween4`,
그리고 3-A의 `wkA2[1]`이 살아있었다면 그것도)에 `:Cancel()`을 불렀다. 단 하나 예외 — 사실 3-A 실험이 **의도적으로** 무한 트윈의 마지막
Lua 핸들을 GC로 없앴고, 그 결과 실측대로 그 트윈을 다시 참조할 방법이 없어 `Cancel()`을 부를 수 없었다. 대상 Frame·ScreenGui는 이미
`Destroy()`됐고 이 Studio 세션이 끝나면 함께 정리된다 — 이 사실 자체가 위 실측(사실 3-A)이 보고한 그대로다.

## Raw execute logs

### Setup(스크래치 루트 생성)
```
QuadProbe-InfiniteTween-1789982450
```

### 사실 1 (Destroy)
```
Play-called PlaybackState=Enum.PlaybackState.Playing @ 446291.9825 | Destroyed frame PlaybackState=Enum.PlaybackState.Playing InstanceIsFrame=true @ 446292.0477 | After final Cancel PlaybackState=Enum.PlaybackState.Cancelled @ 446297.0982
t+1s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.6711 completedCount=0
t+2s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.3306 completedCount=0
t+3s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.7482 completedCount=0
t+4s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.1662 completedCount=0
t+5s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.8333 completedCount=0
completedStates=[] count=0
```

### 사실 2 (Parent = nil)
```
Play-called PlaybackState=Enum.PlaybackState.Playing @ 446306.5152 | Parent=nil PlaybackState=Enum.PlaybackState.Playing InstanceIsFrame=true @ 446306.5810 | After final Cancel PlaybackState=Enum.PlaybackState.Cancelled @ 446310.6309
t+1s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.6759 completedCount=0
t+2s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.1669 completedCount=0
t+3s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.8369 completedCount=0
t+4s PlaybackState=Enum.PlaybackState.Playing Instance-is-frame=true frame.Parent=nil BGTransparency=0.0809 completedCount=0
completedStates=[] count=0
```

### 사실 3 — 1차 시도 (`collectgarbage("collect")` 거부됨)
```
error: ...AssistantCommand:53: collectgarbage must be called with 'count'; use gcinfo() instead
```
→ `table.create` 할당 압박 관용구로 재작성(아래).

### 사실 3 — A/B/C 합본 (재작성본)
```
epochs-run(cap=60) survivedA(infinite,playing)=false survivedB(finite,completed) emptyAtEpoch=4 stillAlive=false survivedC(destroyed-frame,weak,infinite-tween-driving) emptyAtEpoch=4 stillAlive=false
```
(A는 B·C가 둘 다 정리된 4에포크에 조기 종료해서 정확한 에포크를 못 얻어 아래 3-A 단독 재측정으로 보강)

### 사실 3-A 단독 재측정(에포크 추적) + 수거 후 프로퍼티 재확인
```
focused-A: emptyAtEpoch=7 (cap=40) stillAliveAfterLoop=false | frameA2 BGTransparency while engine still runs it: 0.3303 -> 0.3349 -> 0.4157
```
추가 확인(3초 더 경과, 핸들 없이 계속 도는지):
```
still-driven-with-no-lua-tween-handle: t+1s BGTransparency=0.5038 | t+2s BGTransparency=0.4173 | t+3s BGTransparency=0.6675
```

### 사실 4 (Cancel on corpse)
```
beforeCancel(t-0.3s)=0.9201 justBeforeCancel=0.5829 | Cancel() called -> immediateState=Enum.PlaybackState.Cancelled immediateVal=0.5829 | after 1 yield: state=Enum.PlaybackState.Cancelled val=0.5829 | t+0.5s val=0.5829 state=Enum.PlaybackState.Cancelled | t+1.0s val=0.5829 state=Enum.PlaybackState.Cancelled | t+1.5s val=0.5829 state=Enum.PlaybackState.Cancelled | completedFired=[Enum.PlaybackState.Cancelled] count=1
```

### 최종 정리 확인
```
root existed=true children-before-destroy=[T1,T2,T3,T3] root destroyed, still-present-after=false
```
