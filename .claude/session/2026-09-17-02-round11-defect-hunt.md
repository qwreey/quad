# 2026-09-17-02 — round11 결함 탐사(3차): 1차·2차 팬아웃, `H-538`~`H-559`, 문항 `Q59`~`Q63`

> 입력: `qa-request/post-implementation-review-round11.md` 브리프(§0 규약·§2 갈래·§3 새 표면). 사용자 지시: *"다음 작업을 진행하자. 팬아웃 허용, 병렬 에이전트를 통해서 breaking change 가 필요하거나, 큰 문제가 되는 결함을 찾는 탐사를 진행하자."* 판정·반영은 전부 메인. 원장은 위 파일(§1 결론·§2′ 반영·§3′ 확인·§4 문항)이 소스 — 여기는 흐름과 판정 근거만.

## 흐름

1. **1차 팬아웃 여섯(A′~F′, opus 다섯 + sonnet 하나)** — 공통 브리프는 세션 scratchpad `r11/common.md`(규약: 레포 소스 불변·임시 파일 `-ignoreme`·마지막 메시지에 전부·pcall 처방 금지). 메인은 그 사이 State 세대 스탬프·Effect cleanup·Property retractor·InstanceChild 자리 순서를 손 트레이싱해 후보 하나(던진 fn + 닫힌 게이트)를 기록 — B′가 같은 것을 HIGH로 냈다(`H-540`).
2. **판정 순서**: E′(가짜 프로바이더) → `H-538`·`H-539` 커밋 `2f8dad2` → B′·C′·D′·A′·F′ → `H-540`~`H-550` 커밋 `3348a68`. 판정 기준은 §0 세 갈래 그대로: 문서가 이미 답을 가진 것(선행 패스 원칙 `H-30`/`H-31`, `H-231` 태그 규약, `H-504` nil 게이트, `H-500` 순환 가드, tween-plan 3-상태, Q56 "창 안 throw = UB")은 자율, 새 메커니즘(핸들러 검증 단계·백엔드 술어·이름 변경·`OwnsElements=false` 분기 동작·`_running` 예외)은 문항.
3. **2차 팬아웃 넷(A″ 반영분 적대 검증·B″ raise 249자리 전수·C″ 슈거 층·D″ 문서 대조)** — A″가 **회귀** 하나를 잡았다: `H-539`가 claim을 bottom-up 계획 순서로 돌려 이미 claim된 루트로 `Claim`하면 자식을 전부 claim·drive한 뒤에야 던짐(`spec.claim` 7이 props를 비워 못 잡음). `H-551`(claim은 루트부터, drive만 bottom-up) 등 `H-551`~`H-559` 커밋 `69591cd`.
4. **감사 루프**(각도: base 정합성 4 → 인덱스·docs·주석 5 → 반영분 재검·미러 2 → 코드 주석·archive 4 — 0에 닿지 않아 각도 소진으로 닫음) → `71ad4fe`·`fa97a74`·`7b2a35e` → **`/code-review high`**(`27b8306..HEAD`, 파인더 8·검증자 4 opus: CONFIRMED 9·PLAUSIBLE 1 — `H-560`·`H-561` 코드 둘, 스펙 셋, 문구·문서 여섯, 문항 둘 Q64·Q65) → 반영분 감사 1라운드 4건(옛 문구 인용·CHANGELOG 누락) → 체크포인트 `d1cc1d4`.

## 메인의 사고와 되돌림

- **`git stash` 오용**: 대조용으로 `git stash -- Claim.luau`를 돌려 자기 편집을 잠깐 잃었다(즉시 `stash pop`). conventions의 "감사자에게 stash 금지"는 메인 자신에게도 적용된다 — 대조는 `git show HEAD:<경로>`로.
- **relink 누락**: quad-roblox 스펙은 `luau_packages/quad_base` 실복사를 보므로 quad-base를 고친 뒤 `./scripts/relink.sh` 없이 돌리면 옛 코드가 돈다 — `H-539` 첫 스펙 실패의 원인.
- **`H-544` 첫 문구가 틀렸다**(B″-5): "같은 자식으로 재시도"를 권했는데 `dispose(child.Parent)`가 자식을 같이 파괴한다 → 정정.
- **`H-539`가 회귀를 만들었다**(A″-1): 두 패스 자체는 맞았지만 claim 순서를 계획 순서에 묶은 것이 잘못 — 검증자를 반영분에 다시 붙이는 2차의 가치가 여기서 났다.

## 판정 근거 요약(문항으로 올린 것)

- Q59 밑줄 메소드 이름 — 동작은 맞고 문서로 닫힘, 이름 변경은 BREAKING이라 사용자.
- Q60 거부 전 철거 — Dispatch 순서(옛 retractor → 새 process 게이트) 자체가 계약; 검증 단계는 새 메커니즘. 권고 캐비엇.
- Q61 `OwnsElements=false` 폐기 — round1 Q14 (a)의 역방향; 사용자 확정 "재사용 가능"과의 정합을 사용자가 판단.
- Q62 Slot 원소 순환 — base가 엔진 무관이라 조상 사슬을 못 걸음; 술어 추가는 계약 BREAKING. 권고 UB.
- Q63 던진 Effect 해제 — `_running` 하나로 "fn 위"와 "굳음"을 못 가름; 권고 `Unsubscribe`만 통과.
- Q64 Claim 1패스 `isClaimed` — mock의 lazy claim(모든 인스턴스 참)과 충돌; 권고 문서(이미 quad 소유인 자식은 디스크립터에서 뺀다).
- Q65 핸들러 교체 시 Tween 기록 — retractor가 `retracting` 하나로 철거와 교체를 못 가름; 권고 새 동작(종류가 바뀌면 스냅) 채택.

## 체크포인트 판정에서 배운 것

- 두 패스 Claim의 "아무것도 claim하기 전에"는 세 번 과장됐다(19번 → 21번 → code-review): 실제 무손상은 "해석 실패·이미 claim된 루트·배열 키"까지이고, "자식이 이미 claim" · "drive 단계"는 남는다.
- H-547의 "모든 체인이 retractor"는 Dispatch (B) 갈래(핸들러 교체)가 `retracting == true`로 부른다는 사실을 놓쳐 동작을 바꿨다(Q65) — retractor 계약의 두 호출 경로를 항상 같이 볼 것.
- 스크립트로 문서를 고칠 때 `open(p,'w')`를 예외 가능한 식과 같은 문장에 두면 파일이 비워진다(claim-plan.md 391줄이 0바이트가 됐다가 HEAD에서 복구) — 문자열을 먼저 만들고 마지막에 쓸 것.

## 소진 판정

1차 18·2차 22, 두 라운드 모두 0인 갈래 없음 — **소진 아님**. 다만 무게가 내려왔다: 2차의 HIGH 둘 중 하나는 이 라운드 반영분의 회귀, 하나는 문서화된 UB 가족의 새 자리(`Offset` 구독 throw). 값·통지·부기 차등 퍼즈(반응형 1200시드·Debounce 5000시드·소유권 1600시드·문서 스니펫 525·앱 시나리오 4)는 전부 0 — 남은 발견 축은 "예외·GC·거부 뒤에 남는 상태"와 슈거 층 게이트. 3차는 체크포인트 뒤 반영분 재검 + 새 축(mock 충실도 보완 하네스, 타입 표면)으로. bump 3.3.0은 수렴 뒤(사용자 결정).

## 게이트

매 커밋 test.sh exit 0(스펙 61), doc-check ERROR 0, `sync-docs.py`. 스펙 신설: `spec.claim` 12·13, `spec.state` 15, `spec.debounce` 12, `spec.handlers` 14, `spec.tweenproperty` 10, `spec.operator` 7, `spec.modifier` 16.

## 3차 탐사(같은 밤, 사용자 지시 *"못 판 각이나 안 나온 각을 좀 더 유심히 … 안 나오면 그것도 좋은 시그널"*)

새 각도 여섯을 팬아웃(G′ Dispatch 코어·다중 모듈·blame 전수 / H′ 엄격 mock 재실행 / I′ List·Single 차등·Store / J′ 타입 표면·생성 D 대 Reflection / K′ 동시성·yield·스케줄링 / L′ 성능·복잡도). 발견 31, 반영 `H-562`~`H-574`(커밋 `1b850b6`·이번), 문항 `Q66`~`Q69`. **코어 산술은 전 축 0**(Dispatch 1500시드·flatten 3000·List 18만 사이클·Store·동시성 합법 표면 1500·타입 생성물 31클래스·성능 선형성) — 나온 것은 입력 게이트 도메인·이름 공간 계약(`is*`)·엔진 사실(Deferred·nil 자리)·yield 입구·성능 상수. 엄격 mock 위 전수 재실행에서 mock 관대함이 가린 quad 결함은 `H-574` 하나. 원장 §6이 소스.

**절차 사고**: H′ 탐사자가 지시에 없던 Studio MCP `execute_luau`로 엔진 사실을 실측했다(Place1.rbxl, 스크래치 인스턴스만 생성·파괴, 사용자 트리 무변경이라 보고). SAFETY.md의 "별도 계정" 조건을 메인이 확인하지 않은 채 일어난 일이라 사용자에게 보고했다 — 이후 탐사 브리프에 "Studio MCP 사용 금지"를 명시한다(common.md에 추가).

**판정 근거(문항)**: Q66 타입 BREAKING(반공변 콜백 인자) / Q67 재drive 관용구 여부 / Q68 "yield는 UB" 입장과 한 줄 가드의 저울 / Q69 "누가 붙였나" 기억의 비용 — 상세는 원장 §4.
