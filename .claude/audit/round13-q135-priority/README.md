# Q135(+Q137 ②) — 가드 우선순위 조정안 프로토타입·실측 (2026-10-01)

원장 `qa-request/post-implementation-review-round13.md` Q135 재검토(사용자: *"이건 우선순위로 해결되는거 아냐?"*)와
후속 지시(*"우선순위 normal 과 high 사이에 이렇게 invalid 한걸 미리 필터하는 부분을 하나 놓는것도 확인"*)의 갈래를
mock으로 만들어 재 본 기록. 결정은 하지 않는다. 기준 커밋 `644dfbd1`, 격리 워크트리, 커밋 없음.

## 파일

| 파일 | 내용 |
|---|---|
| `probe.luau` | A 문자 키 오용(리터럴·Source·Store·`:Set`)·A3 Modifier 필드(Q137 ②)·B 정상 경로 27개·C 다른 키 종류·D 레지스트리 순서·E NORMAL 오버라이드 |
| `out-probe-before.txt` / `out-probe-ATM.txt` / `out-probe-F.txt` | HEAD / A+T+M / F+M (A+T+M과 F+M은 D(순서 목록)만 빼면 줄 단위로 같다) |
| `patch-A-priority.diff` | 가드 여섯(Ref·PreRef·PostRef·Observer·Effect·Slot)을 `HIGH - 1`로 + `spec.leaf` §7 재작성 |
| `patch-T-tagattr-guards.diff` | Tag/Attr 문자 키 가드 신설(`HIGH - 1`, 숫자 키 제외, 새 ID `Quad0266`/`Quad0267` + errors/05 절) + `spec.dispatch` H-567 단언 교체. A 위에 얹는 모양 |
| `patch-M-modifier-gate.diff` | Modifier 층 `isHandlerLayerValue`에 Tag/Attr 추가(`Quad0064`/`Quad0057` 그대로, 문구 목록만) |
| `patch-F-filter.diff` | 필터 하나 갈래(HEAD 기준 단독 적용): Dispatch의 `EarlyGuardFilter`(HIGH − 1) + 가드는 FALLBACK 그대로 + `module._earlyGuards` 등록, Tag/Attr 가드(FALLBACK), spec 둘 |
| `bench.luau` / `out-bench.txt` / `out-bench-F.txt` | 비용(mock `-O2`, 5라운드 중앙값, 모드 교대) |

실행(레포 루트, `./scripts/relink.sh` 뒤): `luau .claude/audit/round13-q135-priority/probe.luau`,
`luau -O2 .claude/audit/round13-q135-priority/bench.luau -a before,A,B 5`(F 트리에서는 `-a before,F 5`).
⚠️ bench 첫 판은 마운트한 mock Frame을 하나도 Destroy하지 않은 채 모듈 인스턴스 210개를 만들어 메모리를 다 먹고
OOM으로 죽었다(exit 137 — 같은 시각 메인 세션이 죽은 원인으로 의심). 지금 판은 케이스마다 만든 Instance를 계측 뒤
Destroy·전체 GC하고 N을 줄였다(라운드마다 힙 2.8MB로 평탄). `ulimit -v`를 걸고 돌릴 것.

워크트리의 현재 상태는 **F+M 적용본**이다(`patch-F-filter.diff` + `patch-M-modifier-gate.diff`).

## 디스패치 모델 (확인)

- 밴드 상수는 `quad-types/src/init.luau` 840행대: HIGH 1000 / NORMAL 0 / LOW −1000 / FALLBACK −1000000. `addHandler`가 매번
  `table.sort`(불안정 — 동률 순서 미정의, 무관한 등록마다 다시 섞임: E64 (a))로 정렬하고 `keyType`별 버킷 셋을 다시 만든다.
  debug 동률 안내는 `keyType`이 겹칠 수 있을 때만(`canCompete`, `Dispatch/init.luau` 441행).
- `getHandler` 스캔은 **값이 바뀔 때마다** 돈다 — `Dispatch.process`가 매 호출 `getHandler(inst, k, v)`를 부르고,
  StoreBind는 emit마다 `process(inst, k, realv, index + 1)`로 재진입한다. 그러니 가드 술어는 자리 해석 때 한 번이 아니라
  문자 키 프로퍼티의 매 emit에 돈다(비용의 핵심).
- 새 상수는 필요 없다 — 문서가 정한 "밴드에서 오프셋" 관용구(`HIGH - 1`)로 된다. 하한은 `NORMAL + 2`:
  `InstanceShorthand`가 `NORMAL + 1`이라 그 아래면 `UICorner = ref`가 계속 조용히 통과한다(HEAD 실측: 여덟 종류 전부 "ok").

## 사실 셋 (지시문과 다른 점)

1. **Tag/Attr에는 문자 키 가드가 없다.** `TagFallbackHandler`·`AttrGroupFallbackHandler`(FALLBACK, `keyType = "number"`)는
   숫자 키에서 일하는 **실제 핸들러**이지 가드가 아니다. 올릴 대상이 없으니 새 가드 둘이 필요하고, 새 raise 자리라 새 ID가
   든다(프로토에선 `--next` 값 `Quad0266`/`Quad0267`). 그리고 이 둘은 숫자 키를 반드시 제외해야 한다(안 그러면 실제 Tag/Attr
   핸들러를 가로챈다). 기존 가드는 일곱이 아니라 **여섯**(Ref 셋·Observer·Effect·**Slot** `Quad0141`).
2. **이 안은 한 번 올라와 닫힌 갈래다.** round1 `H-361`/Q4의 (c) "가드 우선순위를 NORMAL 위로(정본 FALLBACK 설계 역전)"가
   그것이고, 2026-09-07 회신 3차에서 (a)(그대로, 타입이 1차 방어)로 닫혔다(round1 94행, round3 §6). 정본 근거는
   `source-state-plan.md`의 "동적 경로 가드 — `k` 무관 매치, `HANDLER_PRIORITY_FALLBACK`" 절과 `dispatch-core-plan.md`의
   FALLBACK 밴드 절 — "백엔드가 평범한 우선순위로 자기 핸들러를 등록하면 언제나 이긴다". `spec.leaf.luau` §7
   "FALLBACK 의미론 — 평범한 우선순위 핸들러가 가드를 덮어쓴다"가 그 계약을 실측 중이었고, 갈래 A·F 모두 이 spec이 깨진다
   (첫 실행 exit 1). 프로토는 §7을 "NORMAL 핸들러는 이제 가드에 지고, HIGH 핸들러는 여전히 이긴다"로 바꿨다(probe E도 같은 실측).
3. 원장 Q135가 적은 증상은 그대로 재현됐다(HEAD, probe A·A2 문자 키 96칸 중 84칸이 자기 가드에 안 닿음: 원시 `Name must be a string` 32,
   조용한 대입 32(`Size`/`Visible`/숏핸드 `UICorner`), `Quad0218` 16, `Quad0076` 4 — Tag/Attr의 비반영 키).

## 갈래별 결과

| | A 우선순위만 | B 우선순위 + 키 조건 | F 필터 하나(HIGH − 1) |
|---|---|---|---|
| 모양 | 가드 여섯 `FALLBACK` → `HIGH - 1`(+ T: Tag/Attr 가드 신설) | A + 가드를 문자 키 버킷에만 | Dispatch가 슬롯 하나·브랜드 지식 없음, 가드는 각 모듈이 FALLBACK에 그대로 등록하고 같은 테이블을 `module._earlyGuards`에 넣음 |
| 오용 96칸(A·A2) | 전부 자기 ID(0137 36·0116 12·0097 12·0141 12·0266 12·0267 12); C의 `Quad0136` 둘·`[0]` Slot은 그대로 | A와 같음(문자 키) | A와 같음(probe 출력 동일) |
| 정상 경로 B 27개 | 전후 동일 | 동일 | 동일 |
| test.sh | exit 0(스펙 62, spec 둘 수정 뒤) | (perf 모양만 실측) | exit 0(스펙 62) |
| 퍼저 축소(E64 base/prov 각 2000·E66 3000) | 차등 0 | — | 차등 0 |
| 문자 키 emit 비용 | **+55%**(1.45 → 2.24µs, 8프레임 `Text` 11.1 → 17.2µs, Event 교체 +46%) | A와 같음 | **+5%**(1.40 → 1.47µs) |
| 숫자 키 emit | +10~20% | ≈0 | +3%(Tag 교체만 +16% — 새 Tag/Attr 가드 둘이 숫자 버킷 FALLBACK 동률에 끼어서) |
| 마운트(문자 프로퍼티 5개) | +14% | +15% | +1% |
| `H-278` | 지킴(각 모듈이 자기 가드 소유·등록, 숫자만 바뀜) | 지킴 | 지킴 — 브랜드·메시지는 모듈에, Dispatch는 "이른 가드 목록"만. 다만 그 목록(`module._earlyGuards`)이 **새 메커니즘**(비공개) = 사용자 결정 |
| 새 개념 | 없음(오프셋만) | 없음 | 필터 슬롯 + 등록 목록 |

F가 싼 이유: 필터 술어가 `type(k) ~= "number"`와 `type(v) == "table"`로 먼저 걸러, 프로퍼티 값 대부분(문자열·수·불·엔진
userdata)은 함수 한 번 호출로 끝난다. A는 문자 키 스캔마다 가드 여덟의 클로저를 다 부른다. 테이블 값(Roblox `Tween` 등)은 F에서도
가드 목록을 돈다 — A와 같은 +0.8µs 정도로 추정(미실측: mock 하네스에 TweenService가 없음).

"브랜드를 Dispatch 한 곳에 모은 필터"(F1 — `isRef or isObserver or … or isTag or isAttr`를 Dispatch가 직접 검사)는 만들지 않았다.
`H-278`과 `architecture.md`의 `Dispatch/` 폴더 규칙("핸들러는 그 값 타입을 소유하는 모듈 안에 산다")을 정면으로 거스르고
(2026-09-01에 역전된 2026-08-08 옛 `Leaf.luau` 배치로 돌아가는 셈), ID는 raise 자리 하나에 하나라 각 가드의 `Quad01xx`를
다시 던질 수도 없어(가드로 넘기거나 새 범용 메시지가 필요) F보다 나은 점이 비용 한 줄 정도다. 선례로 Dispatch의
`BRAND_PROBES`가 브랜드 목록을 갖지만 그건 매치 실패 메시지용 콜드 패스다.

## 질문 3 — 키 무관(`k`-agnostic) 술어가 높은 자리에서도 안전한가

안전하다. 숫자 키에서 HIGH와 FALLBACK 사이의 내장 핸들러(InstanceChild·OnChange, 그리고 FALLBACK의 Tag/Attr)는 판정이
배타라, 올린 가드가 숫자 키에서 잡는 것은 전과 같은 둘뿐이다 — State 경유 PreRef/PostRef(`Quad0136`)와 직접 `process`의
`[0]` Slot(`Quad0141`). 거꾸로 기존 여섯 가드에 `type(k) ~= "number"`를 **넣으면 안 된다** — `Quad0136`이 사라지고 `Quad0076`으로
떨어진다(그러려면 FALLBACK 사본을 하나 더 둬야 함). 키 조건은 숫자 키 비용만 돌려주는 성능 손잡이(B)이고 문자 키 비용은 그대로다.
새 Tag/Attr 가드만은 숫자 키 제외가 필수다. 부수 효과 하나: 표 키(`[q.AttrKey("k")] = q.PreRef(nil)` 등)는 HEAD에서
`AttrKeyFallbackHandler`와 FALLBACK 동률이라 정렬 운에 따라 `Ref`만 `Quad0137`, PreRef/Observer/Effect/Tag/Attr는 원시
`table is not a supported attribute type`이었다 — A·F 모두 자기 ID로 결정적이 된다.

## 질문 4 — Q137 ②

T(Tag/Attr 문자 키 가드)가 있으면 우선순위 수단으로 같이 닫힌다 — 마운트 때 `Quad0266`/`Quad0267`(필드가 `Source(Tag)`여도).
T 없이 여섯만 올리면 안 닫힌다(Tag/Attr는 여전히 Property로). Modifier 층 거부(M)는 따로 고를 수 있는 추가분이다: 생성 시점에
`Quad0064`/`Quad0057`(같은 ID, 문구의 목록에 Tag/Attr 추가) — Ref를 Modifier 필드에 넣으면 이미 생성 시점에 거부되므로 그와 맞춘
모양. M만으로는 `Modifier{ Name = q.Source(q.Tag(…)) }`(생성 때 `:Get` 안 함)를 못 막고, 인라인 `D.Frame{ Name = q.Tag(…) }`도 못 막는다.

## 남는 구멍

- 실엔진 메시지(대입 에러 문구)는 미실측 — 다만 갈래 A·F에선 엔진까지 안 간다.
- 범위 밖 같은 결: Store·Blocker·Context·Provider 값을 반영 프로퍼티 키에 두면 여전히 Property가 받는다(배열 전용 값이 아님 —
  지금도 비반영 키에선 `Quad0076` 힌트).
- 프로바이더 자기 브랜드는 대상 밖(F의 목록은 비공개라 프로바이더가 못 넣음; A에선 프로바이더가 자기 가드를 HIGH − 1에 두면 됨).
- F의 Tag/Attr 가드는 숫자 버킷 FALLBACK 동률 안에 있다(판정 배타라 결과는 같고 비용만 — 위 +16%). `keyType`을 못 쓰는 이유는
  `"number"`/`"string"`/nil 셋뿐이라 "숫자 아님"을 적을 수 없어서.
- 오버라이드 계약 변화: 가드 자리를 프로바이더가 가로채려면 이제 HIGH 밴드에 등록해야 한다(StoreBind·NoneHandler와 같은 밴드 —
  E64 (b)가 본 "HIGH+1이 언랩을 가린다" 함정 근처).

## 고칠 문서(결정 뒤)

- core/07 53행("단 그 문자 키가 그 클래스의 반영 프로퍼티 이름이면…")·61행(반영 프로퍼티 키 bullet 통째), core/07 60행(M이면 Quad0064 문구),
  errors/04 `Quad0137` "언제"(예외 문장 삭제) — `Quad0116`/`Quad0097`/`Quad0141` 절은 이미 예외 없이 적혀 있어 결정 뒤에야 맞게 된다.
- core/05 58행 근처(반영 키도 포함됨을 한 줄), core/09(Tag/Attr 문자 키 → 새 ID 절), errors/05 `Quad0266`/`Quad0267`(패치에 초안).
- M이면: errors/02 140·196행, core/08 99·149행, roblox/03 158행의 문구 목록.
- extend/02 우선순위 밴드 표 아래 — 배열 전용 값 가드가 HIGH − 1(또는 필터)에 있어 NORMAL 핸들러로는 못 덮는다는 한 줄.
- CHANGELOG `[Unreleased]` Changed(반영 프로퍼티·이벤트·숏핸드 키의 quad 값이 조용한 대입/엔진 에러 대신 전용 에러).
- 정본: `source-state-plan.md` "동적 경로 가드" 절과 그 `H-361` 배너, `ref-plan.md` 1216행대, `effect-plan.md` "동적 경로 가드" 절,
  `slot-plan.md` 244행대, `dispatch-core-plan.md` FALLBACK 밴드 절(가드의 자리 서술), round1 Q4 닫힘 문단에 역전 포인터.
