## 공통 규칙 (반드시)

**레포**: `/code/Projects/quad` (Roblox Luau UI 렌더러 quad v2, 브랜치 main, 기준 HEAD는 `git rev-parse HEAD`로 적을 것). **읽기 전용** — 레포 파일을 만들거나 고치지 말 것, `git stash`·`git add`·`git commit` 금지(대조는 `git show HEAD:<경로>`). 결과는 **마지막 메시지 하나에 텍스트로 전부**(메인이 파일로 옮긴다), 다 못 본 것은 "미완".

**실측 환경**: 레포 밖 스크래치 사본 `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r14x-<각도>/`에 다섯 패키지(quad-base·quad-roblox·quad-types·quad-error·type-version-check)와 `scripts/`를 `cp -rL`로 복사하고 `scripts/relink.sh`를 그 사본에서 돌려 쓴다(사본에 원본 `.relink-manifest`가 따라오면 지우고 다시). 프로브는 기존 spec 머리(`quad-base/test/spec.*.luau`, `quad-roblox/test/spec.*.luau` — mock 하네스)를 본떠 사본의 test 폴더에 둔다. 모든 `luau`·`./scripts/test.sh` 실행은 `( ulimit -v 4000000; timeout 600 <명령> )`. **메모리 큰 실행**(퍼저·변이·대량 반복)은 conventions.md의 "`choom -n 1000`으로 OOM 희생자 1순위" 항목과 그 보강 다섯을 따른다. 요지: 예산 = min(3 GiB, (memory.max − memory.current)/2)를 `choom -n 1000 -- prlimit --data=<예산> --`로 걸고(`/sys/fs/cgroup/memory.max`·`memory.current`를 실행 직전에 읽어 계산), 시나리오·N은 프로세스를 나눠 순차로, 작은 N의 Max RSS(`/usr/bin/time -v`)로 외삽하고, 넘으면 멈춰 보고(N을 줄였으면 원래 N과 함께 적기). **다른 탐사자 넷이 동시에 돈다** — 한 번에 무거운 프로세스 하나만.

**먼저 읽을 것**: `.claude/audit/round14-principle-audit/PRINCIPLES.md`(판정 기준 A~E), `.claude/qa-request/post-implementation-review-round14.md`(§0 이관 23문항 표, §4 결정 대기·닫힘 Q160~Q180 — 2026-10-04 닫힘 포함). 최근 사용자 확정(요지): 던진 뒤 상태는 관측일 뿐 계약 아님(사용자가 계약으로 둔 회복은 Observer 자가 치유 하나); 모든 콜백 안 yield는 UB; Compute는 아무것도 Set하지 않음(UB); Observer는 최종 소비자 — 자기 상류 되먹임 UB(정의된 예외: `q.Out`/`OnChange` 엔진 왕복, Slot Offset/Length 부기 고리, Effect의 자기 의존성(상류 포함) Set은 지연 재실행 + 1만 회 한도 `Quad0263`); 같은 `(inst, k)`를 처리하는 도중의 간접 재진입은 UB(Q5); `Source:Set`은 같은 값도 늘 전파, `:SetIfChanged`는 `==`로 같으면 무동작, `:SetAndDispose`; 비싸거나 깊은 검사는 `q.debug` 층, 입구 한 줄 검사는 평소, 핫 패스 상시 가드 금지; Dispatch는 코어 객체를 모름; 새 필드·이름·메커니즘은 사용자 결정; 에러 메시지는 API가 아님.

**발견마다 거칠 검증 절차 — 이것이 이번 조사의 핵심이다**(지난 라운드들의 사고: 리뷰·탐사가 이전 사용자 결정을 인용하지 않고 반대로 굳히거나, UB 입력 안의 결과를 결함으로 올리거나, 추론만으로 단정했다):
1. **재현** — HEAD 사본에서 최소 프로브로 실측하고 출력을 그대로 붙인다. 실행으로 확인 못 한 것은 "추정"으로 표시하고 결함으로 올리지 말 것(최대 "의심").
2. **입력 분류** — 그 입력이 위 원칙상 정의된 사용인가, UB인가(yield, Compute 안 Set, 자기 상류 되먹임, 같은 키 재진입, 던진 뒤, 파괴된 인스턴스 위 공개 process 등). **UB 입력 안의 결과는 결함이 아니다** — 기껏해야 "문서·spec이 그 결과를 계약처럼 적었다"(D1)만 발견이 된다.
3. **이전 결정 대조** — 같은 장면·같은 모양을 `.claude/qa-request/post-implementation-review-round*.md`(특히 §4 문항과 그 닫힘 문단), `.claude/archive/v2-initial-implementation/`, `.claude/base/`(그 주제의 plan 문서, "검토 후 안 만들기로 한 것"류), `.claude/archive/`에서 grep한다. 이미 사용자 결정(정의/UB/기각)이 있으면 원문을 인용하고 지금 코드가 그 결정과 맞는지 판정한다. 이미 추적 중인 문항·발견(Q번호·H번호)이면 "기존(번호)"로만 적고 새로 쓰지 말 것. `.claude/audit/round14-principle-audit/`의 감사·후속 파일에 이미 있는 항목도 "기존".
4. **문서·spec 대조** — 공개 문서(`docs/reference/`·`docs/how-to/`·`docs/getting-started/`)와 spec이 이 동작을 무엇으로 약속하는지 인용.
5. **판정** — (가) 정의된 입력에서 코드가 문서·결정과 어긋남(결함) / (나) 문서·spec이 UB·관측을 계약처럼 적음 / (다) 검사 층 원칙 위반 / (라) 결함 아님(이유 한 줄). (라)도 보고에 짧게 남길 것 — 걸러낸 근거가 기록돼야 한다.
6. **처방의 성격** — "결정 없이 고칠 수 있음(문서가 이미 답을 가짐)" / "사용자 결정 필요(새 필드·이름·메커니즘·결정 역전)" 중 하나로 표시하고, 후자는 갈래만 낸다. 처방을 코드로 쓰지 말 것.

**출력 형식**: 발견마다 평문 한 문단 — 상황 → 재현(프로브 경로·출력) → 입력 분류 → 이전 결정(인용·번호) → 문서·spec → 판정 → 처방 성격 → 확신도(높음/중/낮음). 기호·약호 나열로 압축하지 말 것. 끝에 "확인했고 문제 없음"(본 축과 시도 수)과 "미완". 억지로 찾지 말 것 — 0건이면 0건이 정직한 결과다.
