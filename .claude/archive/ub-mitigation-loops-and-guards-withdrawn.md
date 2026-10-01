# [철회됨] UB 입력을 달래던 루프·가드 셋 — `Get` 재시작 루프(`H-198`), Observer 설치 재실행 루프(round13 3′), Compute yield 가드(round13 Q93·Q98)

**[2026-10-01 신설 — 사용자 결정으로 셋 다 걷어냄]** 셋은 모두 "정의되지 않은 입력"(계산 함수 안의 `:Set`·yield, Observer의
자기 상류 되먹임) 아래서 결과를 다듬던 장치였고, 정의된 경로에서는 동작이 같았다. 같은 날 사용자 원칙: *반응형 콜백은 파동
도중 yield하지 않고, 꼬인 파동을 풀어 주는 도구가 없는 곳에서 자기 입력을 되먹이지 않는다* — Compute는 어떤 State도 `:Set`하지
않고, Observer는 최종 소비자(자기 상류 되먹임은 UB), `Effect`의 자기 의존성 `:Set`만 지연 재실행이 풀어 정의된다, yield는 모든
콜백에서 UB. 사용자 원문:

- `Get` 루프·설치 루프: *"compute 재시작 루프는 확인, 걷어내고 observer 설치 루프는 필요 없는것 같음. 설치 발화 중에 변경을
  계속 받을 필요 없고. 내 의도는 pending 으로 끝날 수 있음. 설치 중 즉시 도는거 아님."*
- Q93·Q98: *"yield 쪽 가드는 드러낸다 동의해."* 덧붙임: debug에서 사용자 실수를 쉽게 보여 주는 가드가 있으면 후보로 남길 수
  있지만 *"기본 답은 걷어낸다"* — 두 가드가 판별하던 "멈췄다 돌아온 실행 위에 더 새 세대가 있다"는 debug 감지기 (a)(새 실행이
  멈춘 옛 실행 위에서 시작)와 같은 사건이라 따로 남길 후보가 없었다.

지금 유효한 서술: `base/source-state-plan.md`의 "Compute 순수성" 절(2026-10-01 문단 둘)과 "전파 루프 — 확정 의사코드" 절,
`base/state-epoch-plan.md`의 "재계산 판정" 절. 남긴 것: fn 직전 스탬프(`H-198` — 비용 0, UB 피해 줄이기·계약 아님), Q50 세대
도장, `H-540` 드리프트 가지, `H-85` 카운터 쌍, Observer `_running` 저장/복원(`H-332` — 비용 0, 계약 아님).

---

## 1. `state-epoch-plan.md` "재계산 판정" 절의 `H-198` 항목(원문)

- **⭐ [2026-08-31 `H-198`, 사용자 확정] 이 판정 전체가 `Get` 안의 루프다 —
  한 번 재계산하고 끝이 아니라, 두 갈래(카운터 상이 / `Refresh` 드리프트) 다
  거짓인 깨끗한 패스가 나올 때까지 재시작한다.** `fn` 도중에 온 `Set`(재진입이든,
  닫힌 게이트에 유보돼 `_receive`에 안 온 것이든)을 그 `Get`이 반환하기 전에
  다시 계산해, **모든 `Get`이 최신 읽기로 수렴한 값을 돌려준다**(사용자: *"그럼
  항상 최신 값만 읽게되어 문제가 없다"*). 게이트 너머 움직임의 탐지는 아래
  "재계산이 끝나면"의 스탬프 위치 이동이 맡는다. **`fn`이 매 패스마다 자기
  (전이적) dep을 `Set`하면 수렴하지 않는다 — UB**(사용자 확정; 관측상 무한
  재계산 루프).

## 2. `source-state-plan.md` "전파 루프 — 확정 의사코드" 절의 Observer 부분(원문, round13 3′ 판)

```lua
-- ⭐⭐ [2026-09-30 round13 묶음 3′, 사용자 결정 — Q73 (a)·Q109·Q110 (b)] Effect의 어휘를 그대로 쓴다(새 이름 없음):
--   `_rerunRequired` = "실행 자격이 없을 때 온 변경"(보류, 살아날 때 1회 재생) **한 뜻** — 시드 `false`(옛 `true`);
--   `_pending` = "실행 중에 왔는데 그 자리에서 못 돈 배달"(Effect와 같은 뜻 — 설치 창, 또는 fn이 자기를
--   해제한 뒤); `force` = 설치 실행(Effect와 같은 뜻). 자격 있는 배달은 **여전히 중첩**이다 — Effect의 지연
--   재실행과 다른 이 한 점은 의도다: 던진 Observer가 다음 변경에 다시 도는 자가치유(`H-445`/`H-545` 등 스펙
--   고정)를 pcall 없이 지키려면 중첩이어야 한다(사용자: *"자가 치유적 성질이 옵져버에 있다 - 이건 버리기
--   싫은 부분중 하나야"*). 그 대가로 대상을 되써서 수렴시키는 fn(clamp)은 바깥 fn의 꼬리가 옛 값을 본다 —
--   문서화로 둔다(core/05 재귀 항목).
--   `_seenRevision`(Q109) = 이 핸들이 마지막으로 돈 Source 리비전 숫자 하나. **Effect의 `_epochs` 맵 항목과 같은
--   뜻의 기록을 대상 하나에 특수화한 것**이다(Effect: fn 직전 `Sync`, 배달 때 `Update`) — 외부자 검토가 든
--   Preact signals·Vue 3.4+의 "간선 하나당 버전 숫자 하나"와 같은 모양. 비교는 대상이 **Source일 때만**
--   (`from == self._state`); 게이트 배치(EpochSet)는 건너뛰지 않는다.
--   ⚠️ [2026-09-30 mock 실측] 파생 State 대상은 이 비교 밖이라, 파동 도중 되살아난 핸들(Q109 모양)과 중첩
--   파동(C6 모양)에서 **같은 값으로 두 번 돌 수 있다**(해시 순서에 따라 약 절반) — "파생 State는 자기 emit 맵이
--   이미 거른다"는 전제는 이 두 경우엔 성립하지 않는다(emit 맵은 노드 입구에서 거를 뿐, 이미 도는 스냅샷
--   순회의 뒤쪽 구독자에게 가는 바깥 배달은 막지 않는다). Effect는 `from`(원천 Source)을 `_epochs`에 기록하므로
--   파생 dep의 중첩 파동은 거르지만, 되살림 경우는 같이 두 번 돈다(fn 직전 `Sync`는 직접 Epoch dep만).
local function runLoop(self, from, force)  -- 설치(force)와 캐치업(_catchUp)이 쓰는 본체
    local outer = self._running            -- `H-183`/`H-332` save
    self._running = true
    repeat
        self._pending = false
        self._seenRevision = rawget(self._state, "Revision")  -- 파생 State면 nil
        self.fn(self._state, self, from)   -- ⭐ (리시버 State, Observer 자신, 출처)
        from = nil                         -- 재실행은 "값을 읽어라"(`H-164`)
    until not (self._pending and (force or canExecute(self)))
    if self._pending then                  -- fn 안에서 실행 자격을 잃고 변경이 왔다: 보류로
        self._pending = false
        self._rerunRequired = true
    end
    self._running = outer                  -- `H-332` restore
end

function Observer:_receive(from)
    local rev = nil
    if from == self._state then            -- 자기 자신을 `from`으로 내는 것은 Source뿐
        rev = from.Revision
        if self._seenRevision == rev then return end   -- Q109: 이미 돈 리비전 — 새 변경이 아니다
    end
    if canExecute(self) then               -- 발화 시점에 읽는다(`H-174`)
        local outer = self._running
        self._running = true               -- `H-183`
        if rev ~= nil then self._seenRevision = rev end
        self.fn(self._state, self, from)   -- 자격 있는 배달은 **중첩**(위 배너)
        self._running = outer              -- `H-332`
        if self._pending and not outer then    -- fn이 자기를 해제한 뒤 대상을 바꿨다: 보류로
            self._pending = false
            self._rerunRequired = true
        end
    elseif self._running then
        self._pending = true               -- 제자리에서 못 도는 실행 중(설치 창) — runLoop가 다시 돈다
    else
        self._rerunRequired = true         -- [2026-08-28 `H-159`] 묶이기 전의 변경은 홀드 — 묶일 때 1회
    end
end

-- ⭐ [2026-08-28 확정] 캐치업 — 묶이거나 구독될 때 홀드가 있었으면 1회. 출처 없음(`nil`)이라
--   `_receive`가 아니라 별도 내부 메소드(사용자: *"observer 계열의 rerun 느낌이네. 외부적으로
--   쓸 일은 안 보여서"* — 공개 표면 아님). `bindLifetime`·`Subscribe`·`WeakSubscribe`가
--   부르는 유일한 자리 — 네 곳이 각자 세 줄을 반복하던 것을 여기로(감사 4라운드 지적).
function Observer:_catchUp()
    if self._rerunRequired then
        self._rerunRequired = false
        runLoop(self, nil, false)          -- 3′: 재생도 `_seenRevision`을 찍는다(Q109)
    end
end

-- `EmitReceive` — 구독자 집합 `_subs`의 원소가 만족하는 인터페이스(`Epoch`처럼 구조적).
type EmitReceive = { _receive: (self: any, from: Epoch | EpochSet) -> () }
-- 구현: `ComputeNode`/`GateNode`(state-epoch-plan.md §4 규칙 1~3 / gate-plan.md 조립 절), `Observer`(위),
--   **[2026-09-30 round13 3′]** `Effect`(자기 `_receive` — `_epochs:Update(from)`이 참이면 `Rerun`; effect-plan.md).

-- `state:Observer(fn)` 생성자 — **[2026-09-30 round13 3′, Q73 (a) 사용자 결정] 합류가 먼저다.**
--   옛 순서(`H-159`/`H-164` — (1) fn 1회 → (2) 플래그 내림 → (3) `_subs` 합류, "순서가 계약")는 설치 발화 도중 온
--   emit을 버렸다(Q73: `setLength` 설치 발화 창의 형제 `Offset` stale, Q157 F6: `:List` 첫 재조정 안의 `data:Set`).
--   사용자: *"첫 발화든 어느 발화든 자기 state 가 set 된다면 다시 실행되어도 됨. 그거는 내가 가정했던 부분인데,
--   의도치 않게 막게 된것 같음."* — 옛 순서는 의도가 아니라 부수적으로 굳은 것. 진동 상한 없음 — 수렴하지 않는
--   설치 fn은 UB(Effect 설치와 대칭; [2026-10-01] `q.debug`면 1만 회에서 `Quad0262` — architecture debug 층). 설치 fn이 던지면 핸들이 `_subs`에 남는다(weak-키라 핸들과 같이 사라지고,
--   그동안 `_running`이 선 채라 받기만 하고 안 돈다).
function State:Observer(fn)
    local o = setmetatable({ fn = fn, _state = self, _rerunRequired = false,
        _seenRevision = false, _pending = false, _running = false }, Observer)
    ObserverBrand:register(o)
    self._subs[o] = true               -- (1) 먼저 구독자 집합에
    runLoop(o, nil, true)              -- (2) 설치 실행(force) — 창 안 emit은 `_pending` → 그 자리에서 재실행
    return o
end
```

## 3. `state-epoch-plan.md`의 Q93·Q98 닫힘 문단(원문)

**[2026-09-29 round13 Q93·Q98·Q88 닫힘 — 사용자 결정] 멈췄다 돌아온 fn은 자기 세대인지 확인한다.** 위 "잡는 것 (2)"는 yield 창 안에 상류 변경이 없을 때만 참이었다 — 코루틴 A가 세대 1의 fn에서 yield한 사이 상류가 바뀌고 B가 세대 2로 들어가 멈추면, A가 돌아와 B의 스탬프를 `-1`로 지워 세대 2의 fn이 멈춘 B 위에 한 번 더 돌았고(Q93), B가 세대 2를 끝낸 뒤 A가 돌아오면 옛 결과로 유효한 세대 2 캐시를 덮어 한 번 더 돌았다(Q98 — 같은 코루틴 안 중첩 재진입에서도 난다). 처방 둘, 새 필드 없음: fn 복귀 뒤 `if self._computing == gen then self._computing = -1 end`(찍은 사람만 지운다), 캐시 쓰기는 `gen == _cacheTargetCount or _cacheCurrCount ~= _cacheTargetCount`일 때만(현재 목표에 이미 유효한 캐시가 있으면 덮지 않는다 — 조건 "`gen == target`일 때만"인 원안 (a)는 버려진 결과 때문에 다음 `previous`가 더 옛 값이 되어 뺐다). 사용자: *"사실 이미 UB에 가깝지만, 그 UB일 때 동작을 약간 완화 하는 방향이네, 한 줄 의미 자체는 나쁘지 않아보이는데, 다른 부작용이 있는지 … 실측/정적분석"* → 적용 전후 검증(`audit/round13-bundle5-guard/`): 두 조건이 거짓이 되는 길은 fn 도중 같은 노드에 더 새 세대로 재진입하는 것(yield 또는 fn이 자기 의존성을 쓰는 UB)뿐이라 **정의된 경로는 바이트 동일**(스펙 62 출력 동일, yield 없는 차분 퍼저 5만 시드 차이 0 — 순서 잡음 한 시드 제외); yield 퍼저의 겹침·세대 중복·순차 중복은 전부 0. UB 경로의 대가(문서화): 겹쳐 돌던 자리가 **돌아온 쪽**의 `Quad0184`가 되고, 그 에러 창이 "가장 새 세대 실행이 돌아올 때까지"로 길어지며(그 창에서 읽는 Effect는 죽는다 — 늦은 복귀 전 파동이면 전에도 같았다), 돌아오지 않는 코루틴이 계산하다 멈춘 노드들은 상류가 바뀔 때까지 막히고, 늦은 복귀 뒤의 `previous`·반환값은 "유효한 새 세대 실행"의 것을 따른다. 사용자: *"채택할게."* 스펙 `spec.state` 16(두 가드 각각 음성 대조로 실패 확인). **blame(Q88)**: quad 내부가 이 노드를 읽다 나는 `Quad0184`는 가장 가까운 태그 프레임이 내부 호출자라 잎 파일을 가리킨다 — 내부 raw 읽기를 두지 않고 how-to 10 "알려진 한계" 3으로 문서화했다(사용자: blame은 *"한 눈에 문제 위치를 볼 수 있다는 편의일 뿐"*). 위 "순환을 닫은 그 `:Get()` 줄 blame"은 사용자 fn이 읽을 때의 약속이다. **[2026-10-01 사용자 결정 — Q159·회고 검토]** 두 가드는 **계약이 아니라 UB 피해를 줄이는 표시**다(정의된 경로에선 항상 참, 바이트 동일 — 사용자: *"필요한게 맞다는걸 봤고. 표기만 잘 해줘"*; `State.luau` 주석·`spec.state` 16 머리 주석에 "계약 아님"). **이미 무효가 된 더 새 캐시는 덮일 수 있다 — yield Compute UB**(Q159: (a″) 가드는 "현재 목표에 유효한 캐시"만 지키므로, 늦게 돌아온 실행이 그 사이 다시 무효가 된 더 새 세대 캐시를 덮는 틈이 남는다; 동등 비교만 쓰는 (a′) 스냅샷 처방은 넣지 않고 UB로 닫았다). 위 "UB 경로의 대가" 서술도 보장이 아니라 지금의 관측이다. **무효일 때도 캐시를 쓰는 이유**(Q159 회신 때 기록): `_cache`는 "유효할 때의 캐시 값"과 "다음 실행의 `previous`(직전에 끝난 결과)" 두 일을 하고, 무효일 때 쓰는 것은 뒤쪽 때문이다(원안 (a)는 위에 적은 대로 `previous`를 한 칸 옛 값/nil로 만들었다) — 유효성은 번호 둘(`_cacheCurrCount`/`_cacheTargetCount`)이 따로 쥔다. 근거 한 줄은 `State.luau` `_recompute`의 Q98 (a″) 주석.
