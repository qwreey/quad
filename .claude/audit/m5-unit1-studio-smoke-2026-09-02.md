# M5 단위 ① Studio 스모크 — 엔진 대면 델타 실측

**상태**: 완료(2026-09-02). `quad-roblox/src/{LifetimeHandle,EngineOps}.luau`의
**엔진 대면 델타**(Lua 배선은 CLI `spec.robloxfactory.luau`가 실코드로 검증
— 이 스모크는 실물 Instance에서만 확인 가능한 부분)를 Studio MCP
`execute_luau`(Edit, "Place1", 별도 계정 컨테이너)로 실측. 스크립트는 op
본체의 전사물(한 줄짜리 op들이라 전사 위험 낮음 — round14 brief §1 단위 ①이
승인한 모양, 스파이크 `10` 선례).

## 결과 — 최종 14/14 PASS (1차 실행의 FAIL 1건이 곧 `H-291` 발견)

아래 표는 단언 14개를 항목 8줄로 묶은 요약이다 — 행별 단언 수:
`isInst` 2(Instance true / 테이블·nil false), `nativeClaim` 2(이중 claim
error / `Connected`), insert·extract 2, remove+`onDestroying` 2(지연 관측 +
1회 발화), `nativeFindChild` 2(조회/미조회), 재부착 거부 1, `Connected`
동기 전환 2(직접 Destroy / 조상 연쇄), 잔여물 1 — 합 14.

| 항목 | 결과 |
|---|---|
| `isInst` | ✅ 실물 Instance true / 테이블·nil false |
| `nativeClaim` | ✅ gcconn 셋업, 이중 claim error, `Connected` 유지 |
| `nativeInsert`/`nativeExtract` | ✅ 실물 reparent / 트리 밖으로 빼되 생존(참조 유지 시) |
| `nativeRemove`+`onDestroying` | ✅ Destroy + `Destroying` 정확 1회 — 단 **지연 배달**(아래) |
| `nativeFindChild` | ✅ 직계 조회, Destroy된 자식 미조회 |
| Destroy된 요소 재부착 | ✅ 엔진이 거부(locked) — `nativeRemove`가 "파괴"인 게 실물에서도 참 |
| `gcconn.Connected` | ✅ Destroy 직후 **동기** false, 조상 Destroy의 자손 연쇄 절단까지 |
| 잔여물 | ✅ 0 (workspace 스캔 단언) |

## ⭐ 발견 — `H-291`: Deferred 시그널 동작 (1차 실행 FAIL의 정체)

1차 실행에서 "`Destroying` 정확히 1회 발화" 단언이 깨졌다 — 같은 줄기에서
카운터가 0. 정밀 조사(별도 실행):

```
Destroy 직후(같은 줄기) Destroying fired = 0
task.wait() 후 fired = 1
Name 변경 직후 nameFired = 0
task.wait() 후 nameFired = 1
```

**이 플레이스(신형 기본값)는 Deferred 시그널 동작** — `Destroying`·
`GetPropertyChangedSignal` 콜백이 다음 재개 지점에 지연 배달된다. Destroy가
연결을 끊어도 큐잉된 발화는 정확히 1회 돈다. **`gcconn.Connected` 전환은
동기**(같은 실행에서 단언)라 `canBound`/`canExecute` 판정은 무영향 — 영향
범위는 시그널 배달 소비자(`onDestroying` → `Effect` cleanup 타이밍, 이후
`OnChange`/`Event`)뿐. 반영처는 round14 `H-291` 행 +
`lifecycle-pattern.md` "2." 절 배너 + `effect-plan.md` `H-182` 근거 정정.
부수: `workspace.SignalBehavior` 프로퍼티는 이 컨텍스트에서 읽기 자체가
거부됐다("not a valid member") — 설정 관측은 못 하고 동작 관측만 남김.

## 재현

스크립트 원문은 세션 트랜스크립트(전사물이라 파일로 안 남김 — 실코드 회귀는
CLI spec이 상시로 돌고, 실물 검증이 다시 필요하면 이 표의 단언 목록이 명세).
GC 강제는 불필요했던 스모크라 `waitForGC` 없이 `task.wait()`만 사용.
