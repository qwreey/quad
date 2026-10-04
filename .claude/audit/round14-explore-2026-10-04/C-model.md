# round14 탐사 C — 모델 대조 축 넓히기(빈 축)

> opus 탐사자 원문(2026-10-04, 읽기 전용, 공통 규칙 `round14-explore-2026-10-04/common-rules.md`). 서브에이전트가 파일을 쓰지 않아 메인이 보고 본문을 옮겼다. 결정 아님 — 메인·검증자 판정 전 원문.

## round14 탐사 각도 C: 모델 퍼저가 아직 안 덮은 축 (HEAD `8592751f`, 스크래치 `r14x-c`)

**결론**: 원장에 올릴 새 발견은 문서 둘과 퍼저 쪽 문제 하나다. 코드 결함은 0건이다. 빈 축 전부(E72·E65·E66·E77 쪽)에서 논리 차등이 0이었고, 물리 순서가 어긋난 것은 기존 Q75뿐이었다.

**재사용과 실행 환경**
- 기존 퍼저 넷을 그대로 가져와 축만 넓혔다. 사본은 `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r14x-c/fz/{e72,e65,e66,e77}/`에 있고, 확장본은 `fuzz2.luau`, `fuzz-bk2.luau`, `fuzz-sh.luau`, `fuzz-x.luau`다.
- 패치 스크립트(`patch*.py`), 결과(`out/`), 프로브(`pr/`, `fz/e77/probe-wait.luau`)도 같은 스크래치에 있다.
- 실행은 전부 CLI `luau` 0.734 + mock이다. 프로세스는 `choom -n 1000` + `prlimit`(예산 계산식대로)로 하나씩 차례로 돌렸다. 최대 RSS는 E66x 5000시드 묶음의 약 0.9 GB다(나머지는 0.5 GB 이하).
- 레포 파일은 고치지 않았다.

### 발견

**1. [LOW, 문서] 값이 있는 같은 State도, 먼저 넣은 Slot이 아직 마운트 전이면 두 번째 자리에 들어간다.**
- **상황**: core/06 168행(`docs/reference/core/06-slot.md`, 사이트 사본 165행)은 UB 모양 (2)를 "값이 nil인 같은 State를 두 자리에 넣는 것"으로 적는다. 이어서 "값이 있었다면 `Quad0172`로 거부됐을 경우"라고 단언한다.
- **재현**: `pr/wrap3.luau`. `A = q.Slot({ st })`(st는 잎을 든 Source, A는 마운트 전) 다음 `B:Add(st)`는 OK다. 이어서 A를 마운트하면 OK, B를 마운트하면 `Quad0156`이 나고 B의 Length는 0이다. 그 뒤 `st:Set(l2)`는 A에만 반영되고 `B:Add(새것)`은 `Quad0167`로 동결된다. 대조군 `pr/wrap2.luau`: 같은 Slot에 다시 넣으면 `0170`, 둘 다 마운트돼 있을 때만 `0172`가 난다.
- **원인**: Q112와 같다. 선행 패스는 State의 현재값(occupant)을 보는데, 래퍼가 마운트되기 전에는 그 잎이 아무 자리에도 claim되지 않은 상태라 패스가 통과시킨다.
- **입력 분류**: "같은 State를 두 자리에"라는 UB 가족이다.
- **이전 결정**: Q112 닫힘(2026-10-01) — "UB 문서화 — Q111과 같은 회신; 신원 검사는 평범한 잎 Add도 +45%". `slot-plan.md` 974행은 nil만 적었고 "값이 있으면 거부된다"는 주장은 하지 않는다.
- **판정**: (나)에 가깝다. 공개 레퍼런스가 실제보다 넓게 정의된 거부를 약속한다.
- **처방**: 결정 없이 고칠 수 있다. Q112 결정 범위 안의 서술 정정이고, 괄호를 "값이 있어도 먼저 넣은 Slot이 아직 마운트 전이면 같은 결과"로 바꾸면 된다.
- **확신도**: 높음.

**2. [LOW, 문서] `q.Bookkeeping.setLength`의 anchor를 생략하면 Slot ownerKey에서 UB로 바로 이어진다.**
- **상황**: extend/02 251행은 anchor를 "생략하면 `ownerKey`"로 적고, 같은 표에서 ownerKey를 "요소이거나 Slot"이라 한다. 둘을 합쳐 읽으면 "Slot ownerKey + State 길이 + anchor 생략"이 정의된 사용처럼 보인다.
- **재현**: `pr/anchor1.luau`. 실 quad-roblox 프로바이더에서는 `Quad0226`, mock에서는 ID 없는 "not a mock instance"로 던진다. 이 raise는 `lengthList[1]`과 `N`을 쓴 뒤에 나므로 그 자리의 옵서버가 없다. 그래서 `len:Set(5)` 뒤 Slot.Length는 다른 자리를 등록해야 비로소 맞춰진다.
- **입력 분류**: 이전 결정상 UB다. Q18 (c)(round1, 사용자 *"에러로 죽은 다음 우린 데이터의 무결이 깨져도 상관이 없고"*)가 "잘못된 anchor"로 설치 중 throw하는 경우를 UB로 정했다.
- **설계 근거**: `dispatch-core-plan.md` C-4 절이 "4번째 인자를 실제로 넘겨야 하는 건 `ownerKey`가 Slot인 자리"라고 이미 답을 갖고 있다. 공개 레퍼런스와 errors/07 `Quad0226`의 "언제"에는 이 조건이 없다.
- **판정**: 문서 공백이다. 코드는 결정대로 동작한다.
- **처방**: 결정 없이 고칠 수 있다. anchor 행에 "ownerKey가 Slot이면 그 Slot이 마운트된 물리 Instance를 넘길 것" 한 줄을 넣는다.
- **확신도**: 높음.

**3. [퍼저 쪽 문제] 기존 E72 퍼저가 지금 HEAD에서는 UB 입력에 정의된 에러를 기대한다.**
- **상황**: E72 원본의 `err:cycle` 연산은 직접 Slot 순환에 `Quad0173`을 기대한다. 그런데 2026-10-01부터 이 검사는 `q.debug` 층이다(core/01 "비용이 드는 검사", errors/03 `Quad0173`). debug가 꺼진 상태에서 그 입력은 UB다.
- **결과**: 원본을 그대로 돌리면 200시드에서 차등 215건과 크래시가 났다(`expected Quad0173, got OK` 뒤 연쇄).
- **조치**: 사본에서는 debug를 켜서 돌렸다. debug를 끈 판(`nodebug`)에서는 그 연산을 뺐다.
- **같은 종류의 낡음**: E65 `fuzz-bk.luau`도 공개 표면에서 빠진 `BK.getBlocker`(Q152)를 부르고 있어 `_getBlocker`로 바꿔 돌렸다.
- 둘 다 퍼저 쪽 문제이고 제품 결함이 아니다.

### 기존 항목(새로 쓰지 않음)
- **Q75**: 재진입 모드에서 물리 순서가 어긋난 스텝이 40회였다. 전부 Splice이고 Q75 보강 넷째의 (f)다. 새 축(래퍼, OwnsElements=false)에서는 파괴 순회 중 stale extract가 Clear/Remove/Replace에서 나왔는데, 이는 Q75 보강 셋째의 (e)다. 논리 Length/Offset은 전부 정확했다.
  - 재검토 메모: 이 재진입 장면(Offset Observer가 앞 형제를 CRUD)은 2026-10-01부터 정의된 경로다(PRINCIPLES C3 예외, core/06 Offset 절). round14 §0의 Q75 재검토 칸을 채울 때 참고할 것.
- **좌석 교체 순간 발화**(SeatSet 230회): core/06 Offset 절의 "두 번 통지"가 이미 적고 있다.

### 확인했고 문제 없음(축별 시드·스텝·차등)

**E72 확장(`fuzz2.luau`)**
- 단일 축은 모두 2만 시드 × 30스텝(60만 스텝)이고 논리 차등 0이다.
  - `own`: OwnsElements=false인 `:List`/`:Single`. 해제·놓아주기, 빈 채로 살아남기, 재마운트 때 처음부터 다시 조정.
  - `nest`: `:List` 안의 `:List`.
  - `single`: `:Single` 항등·매핑, Detach 재부착.
  - `wrap`: 수동 Slot 안의 State 원소(래퍼). 언마운트 중 Set하면 옛 원소를 쥔 채 유지, Remove/Extract하면 잎 해제.
  - `xhost`: 호스트 둘, 호스트 사이 이동.
- 다섯 축 결합: 2만 시드 × 30스텝 0, 5천 시드 × 80스텝(40만 스텝) 0. 재진입 + 네 축 결합 2만 시드 0(물리 순서는 위 Q75). debug 끈 결합판 2만 시드 0.
- 변이 검출(1000시드 기준, 검출 시드 수): `ownIgnored` 179, `noSurvive` 81, `singleKeepOld` 317, `wrapDestroys` 330, `oneHost` 843, nest에 `noCatchUp` 62.

**E65 확장(`fuzz-bk2.luau`)**
- 축마다 2만 시드(약 65만 연산), 차등 0: `share`(오프셋 Source를 owner·자리 사이에 공유), `slot`(Slot을 ownerKey로, physical anchor를 넘김; Slot.Length 대조 약 27만 회), `cmp`(Compute 길이, Q151 사전 검사, 무효값 `Quad0021` 뒤 유효값 재Set), 셋 결합.
- `cmp`의 무효값 Set은 런마다 약 2만 회였고 기대 ID가 전부 맞았다. 동결된 owner가 걸린 경우(약 1.6천)는 던진 뒤의 상태라 대조하지 않았다.
- Q151 Compute 변형 프로브(`pr/q151c.luau`): 초기값이 무효면 아무것도 쓰기 전에 `Quad0021`이 나고, 계산은 1회, N은 nil이다. 문서와 일치한다.
- 오프셋 Source 공유는 문서에 정의가 없다. 확인한 것은 owner 자신의 산술(캐시·N·동결)이 영향받지 않는다는 것과, 공유 Source의 최종값이 마지막에 쓴 쪽이라는 것이다. owner가 둘 이상일 때 그 순서는 옵서버 순서에 달려 있고, 한 가지 고정 순서를 가정한 변이 `shareFirst`는 1000시드 중 11시드에서 실제와 달랐다. 정해진 순서가 없다는 뜻이므로 (라)로 둔다. 드문 오용이라 구조 대응은 안 한다(B1).
- 변이 검출: `q151old` 221/1000시드.

**E66 확장(`fuzz-sh.luau`)**
- `UICorner`(number는 offset UDim으로, UDim은 그대로)와 `UIPadding` 또는 `UIPaddingOffset`(인스턴스마다 한 키만 — 02-d 315행 "같이 쓰지 마세요")을 기존 일곱 자리에 더했다.
- 2만5천 시드, 약 99.7만 연산, 숏핸드 대조 약 228만 회, 차등 0. nil/None이면 관리 자식 파괴, retract는 Void, 공유 패딩 자식 확인.
- 변이 검출: `cornerNoWrap` 553, `shdestroy2` 219, 기존 `shdestroy` 93.
- **Slot 원소의 외부 파괴**는 Q9 (b)로 확정된 UB 가족이고 공개 문서도 `q.dispose`만 안전 경로로 둔다. 그래서 퍼징하지 않았다. 관측용 프로브(`pr/extdestroy.luau`)만 돌렸다: Length는 3에 멈추고 Remove/Extract는 통과한다. (라).

**E77 확장(`fuzz-x.luau`)**
- 추가한 축: `Claim`(미claim 템플릿 + Mapper 자식), `q.Store` 필드·store를 Attr로, `Operator`(Sum/Clamp/Max/Not), `Ref:Wait` 대기자(마운트 전에 등록한 것은 마운트 `:Set`으로 정확히 1회, inst 값으로 깨어남; 실행 중 등록한 것은 깨어나지 않고 트리를 붙잡지 않음), Q129 연속 상류(철거 뒤 0.3초 간격 20회 발화, 그 뒤 10초 정지).
- Immediate 8000시드(20.5만 스텝), Deferred 6000시드(15.3만 스텝). 불변식 다섯 + 대기자 검사가 전부 0이다.
- 생성량: Claim 6.1만, Store 9.1만, Operator 8.1만, 대기자 7.9만(전부 1회 깨어남), 연속 발화 28만.
- 변이 검출: `waitPin` 291/300, `claimPin` 284/300.
- 대기자 의미 프로브(`fz/e77/probe-wait.luau`): 철거하면 nil로 깨어나고, 끝났거나 닫힌 스레드는 건너뛰고, Destroy하면 깨어나지 않고 남는다. core/07 caution과 일치한다.

**입력 분류**
새 생성기는 UB 입력을 만들지 않게 짰다. 래퍼·Single 항등 값은 예약 표시로 두 자리 재사용을 막았고, nil 값 State를 다시 넣는 경우는 제외했다. 동결된 owner 위의 대조는 건너뛰었고, 콜백 안 yield와 자기 상류 되먹임은 없다. 유일한 재진입(Offset Observer → 앞 형제 Add)은 C3의 정의된 예외다. 기존 E77이 콜백 안에서 던지는 경우의 cleanup 기대(Effect 사망)는 core/05 242행의 서술을 따른 것이라 퍼저 쪽 문제로 올리지 않았다.

### 미완
- 숏핸드에 Tween/Animate를 거는 경우와 두 패딩 키 동시 사용(문서상 승자가 정해지지 않음)은 퍼징하지 않았다.
- E72x에서 재진입과 xhost는 결합하지 않았다(재진입 모델이 호스트 하나를 전제한다).
- E65 Slot owner는 마운트되지 않은 Slot(base 0)만 썼다. 마운트된 Slot owner는 E72x가 실제 트리로 덮는다.
- Q129는 정지 뒤 잔여 0만 확인했다. 발화 중 게이트가 살아 있는지(의도된 보유)는 재지 않았다.
- Deferred는 E77의 `Destroying` 지연만이다(Q157류 프로퍼티·이벤트 Deferred는 없음).
- 실기기(Studio)는 없다.
