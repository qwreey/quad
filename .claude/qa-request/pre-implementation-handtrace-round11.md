# M2 구현 **11라운드** — 발견 원문 + 배치 문항지

> **이 파일이 무엇인가**: **[2026-08-28 신설]** M2 자율 구현 구간
> (`-round11-brief.md`가 규약)에서 나온 발견 전부. 앞 라운드들과 달리 **종이
> 트레이싱이 아니라 실제 코드를 옮기고 돌리다 나온 것**이다. 번호는 `H-165`부터
> (10라운드 후속이 `H-164`까지 썼다).
>
> **갈래 표기**(규약 §2): **①** 자율로 고침(같은 커밋에서 `base/`+코드) /
> **②** §4 표에 쌓아 배치 회신 대기 / **③** 즉시 중단·보고.
>
> **상태의 소스는 이 파일 자신** — 요약 표의 상태 열이 최신.

## 요약 표

| 번호 | 갈래 | 단위 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|---|
| `H-165` | ① | 1 | 🟡 | `quad-types`에 `export type`을 더하면 pesde shim이 그걸 모른다 — `pesde install` 재실행 없이는 `QuadTypes.Ref`가 Unknown type | ✅ 반영(`project-setup-plan.md`) |
| `H-166` | ① | 1 | 🟢 | `Ref.Revision` 초기값을 어느 문서도 안 정했다 | ✅ 반영(`ref-plan.md`: `0`) |

## 상세

(단위별로 `### \`H-nnn\` 🔴/🟡/🟢 — 제목` 절을 이어 붙인다. 각 절엔 (1) 어디서
(파일:줄 / `base/` 절), (2) 무엇이, (3) 문서가 이미 답을 갖고 있는가, (4) 어떻게
처리했는가(①이면 커밋 해시).)

### 단위 1 — 공통 기반 (2026-08-28)

### `H-165` 🟡 — pesde shim은 생성 시점의 export 타입만 안다

- **어디서**: `quad-base/roblox_packages/quad_types.luau`(pesde 생성물, 커밋 안 됨) /
  `base/project-setup-plan.md`의 `test.sh` 절.
- **무엇이**: `quad-types/src/init.luau`에 `Ref<T>`/`Relate`/`Epoch`를 `export type`으로
  추가하고 `test.sh`를 돌리자 `luau-analyze`가 `Unknown type 'QuadTypes.Ref'`. shim이
  `export type Quad = module.Quad` / `CheckedQuad`만 손으로 나열한 파일이라
  `return module`로는 타입이 안 넘어온다. `relink.sh`는 복사만 갱신한다.
- **문서가 답을 갖고 있었나**: 아니다 — 첫 함정(심볼릭 링크)만 적혀 있었다.
- **처리**: `pesde install` 재실행으로 shim 재생성(같은 세션 실측), `project-setup-plan.md`에
  둘째 함정으로 기록. `test.sh`가 이제 `luau-analyze`를 같이 돌려 조용히 지나가지 않는다.

### `H-166` 🟢 — `Ref.Revision` 초기값이 문서에 없다

- **어디서**: `base/ref-plan.md` "`Ref`는 `Epoch`를 만족한다" 절 / `base/state-epoch-plan.md` §2.
- **무엇이**: 갱신식(`bit32.bnot(-rev)`)과 표만 있고 시작값이 없다.
- **처리**: `0`으로 구현하고 그 절에 한 줄 추가. 계약이 `==`/`~=`뿐이라 값은 무관.

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 | 옛 메커니즘 복원? |
|---|---|---|---|---|---|
| — | **[2026-08-28 기준] 비어 있음** | — | — | — | — |

코드 쪽 잔여 마커: `grep -rn "TODO(H-" quad-base/src` — 이 표의 문항과 1:1이어야
한다.

## §5 이상 없다고 확인한 것

(탐사자가 실제로 돌려보고 계약대로였던 자리 — 다음 탐사자가 다시 파지 않게.)

**단위 1 (메인 세션, 2026-08-28)**:
- `Relate.luau`(M1) ↔ `relate-plan.md` "API"/"실제 구조": 4 메서드, lazy 서브테이블,
  공유 `{__mode="v"}` 메타테이블, `inst` weak — 전부 일치(`spec.relate.luau`가 고정).
- `lifecycle-pattern.md` (0)/(1) 스케치는 mock 시그널 위에 그대로 돌아간다 — `Destroy` →
  `gcconn.Connected=false` → `canExecute` false/`canBound` true, gchold 강참조, 조기
  해제, 이중 바인드 게이트 모양. 스케치의 한국어 에러 문구는 같은 문서가 이미
  *"실제 문구는 영어"*라 밝힌 자리표시자라 문서 결함 아님(코드는 영어 + `level 2`).
- `ref-plan.md` `:Set` 블록을 한 줄씩 옮겼고 계약 9개가 테스트로 고정됐다. 함수키
  dedup(강+약 동시 등록 시 1회)과 순회 중 해제 skip이 실제로 성립한다.
- `brand-plan.md` 합성 술어(`isState = isSource or StateBrand`, `isRef = isPreRef or
  isPostRef or RefBrand`)와 weak-key 멤버십 — 성립.

**툴링 사실 둘**(설계 아님, 다음 단위가 알아야 함):
- `require("@self/X")`는 **`init.luau`에서만** 통한다 — 일반 파일에서 `@self`는 그 파일
  자신이라 `could not resolve child component`. 형제 모듈은 `./X`, 패키지는 `../roblox_packages/...`.
- GC 테스트 함정 둘: 같은 프레임의 죽은 레지스터가 임시값을 붙잡는다(별도 함수 안에서
  만들 것) / **불변 업밸류만 잡는 클로저는 Luau가 프로토에 캐시해 영영 GC되지 않는다**
  (테스트 클로저가 업밸류를 직접 변경하게 할 것 — `lifecycle-pattern.md` (0)의
  `false or` 트릭이 막는 것과 같은 최적화).

## §6 남은 의심 / 못 본 것
