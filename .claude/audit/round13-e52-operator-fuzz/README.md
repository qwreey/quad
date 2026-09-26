# E52 — `q.Operator` 값 대수 차등 퍼저 (2026-09-27, HEAD `a5f82c28`)

레포 파일 무변경, 이 폴더만 새로 만듦. 런타임은 `quad-base/src`(그 안의 `luau_packages` 한 벌)만 require —
mock·quad-roblox 불필요(8.34). strict는 같은 한 벌을 luau-lsp 신 솔버 + test.sh 한도 플래그 셋으로.

## 파일

| 파일 | 무엇 |
|---|---|
| `model.luau` | 참조 모델 — `docs/reference/sugar/02-operator.md` 서술만으로 쓴 순수 함수(각 규칙에 문서 줄). 비트 연산은 `bit32`를 부르지 않고 32비트 루프로 다시 짬. 문서가 정하지 않은 칸은 `U1`~`U6` 태그로 세고 실측값을 기록 |
| `fuzz.luau` → `fuzz-1-15000.txt`·`fuzz-100001-115000.txt` | 차등 퍼저. 연산 14 무작위, 인자 0~4(리터럴·State·nil State·`None`·문자열 숫자·불리언·테이블·명시 nil), 값 40종(정수·실수·음수·0·-0·NaN·±inf·2^31~2^53·2^63 이상·1e300), 대상은 Source/`:Compute` 파생/`:Depend` 파생, 결과 위에 사용자 `:Compute`를 얹는 자리, 팩토리 재사용(대상 1~3, 같은 State에 두 번 포함). 이후 무작위 `Set` 1~6회마다 모든 노드 `Get` 대조(값·에러 ID), 같은 세대 재읽기(던진 뒤 `Quad0184`) 포함 |
| `mutants.out` | 감도 확인 — 대조군 1(0 기대) + 틀린 모델 넷(None=nil / 비트 floor 절단 / nil State 건너뛰기 / Clamp 경계 스왑) 1000시드: 대조군 0, 넷 전부 차등 92~294 |
| `probe-axes.luau` → `.out` | 별도 축 (a) 던진 뒤 회복 (b) `Indexed` 키 타입·중첩 + 기타 경계 (d) 성능 |
| `p1-bit32.luau` → `.out` | 이 빌드(luau 0.734, x86_64)의 `bit32` 경계값 실측 |
| `strict-types.luau` → `.out` | (c) 결과 타입 표면 — 양성 11(전부 무진단), 음성 15(의도한 14 진단, N13 `Indexed(State)`는 `key: any`라 무진단이 기대대로) |

실행(레포 루트, `./scripts/relink.sh` 뒤): `luau .claude/audit/round13-e52-operator-fuzz/fuzz.luau -a <시드수> [시작] [v] [뮤턴트]`.

## 숫자

연산 14, 모델 규칙 약 12(팩토리 게이트·읽기 게이트·fold 7·Clamp·shift 2·Not·Bnot·Alternative·Indexed·같은 세대 재읽기),
시드 30,000(1..15000, 100001..115000), 팩토리·Apply 약 7.7만, 읽기 대조 약 28.3만(그중 에러 약 10만 — 0120/0121/0122/0124/0127/0129/0184) — **차등 0**.
미정 칸 여섯(U1 비트 피연산자 |x|≥2^63, U2 비트 피연산자 ±inf, U3 인자 0개 비트 fold, U4 이동량 비정수/NaN/inf, U5 Min/Max/Clamp의 -0, U6 Sum/Product의 inf/NaN) 약 5.8만 회 적중 — 전부 실측값(x86)을 모델에 적어 대조.
성능: `Sum`(State 100개) 재계산 16.1µs(손으로 쓴 같은 `:Compute` 13.3µs), 리터럴 100개 4.1µs.

발견은 원장 쪽 보고가 소스(이 README는 재현 위치만).
