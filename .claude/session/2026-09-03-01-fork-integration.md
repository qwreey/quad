# 2026-09-03-01 — M6/M10 병렬 fork 통합 (밤샘 자율 구간)

사용자 승인(2026-09-02 밤): *"머지를 진행하고, audit/code-review 돌려가며
시간이 정말 오래걸려도 좋으니까(최장 6시간) 머지 이후 후행 작업 준비와
문제점 정리들을 해줘. 자고 일어나서 몰아서 봐줄게. 혹은 치명적이면,
거기서 멈추고 대기해도 돼."*

## 통합 경과

1. **M6(`spike/m6-slot`, 5커밋) 머지** — 충돌 둘(init.luau의 require/RunInit
   줄, mock export 테이블) 전부 양측 보존으로 해소. **(d′) 적응 하나**:
   fork의 `installNative`(mock native* 층)를 `mockProvider` 본문으로
   편입 — "프로바이더나 무엇이든 전부 같은 형태"(H-305 (d′) 사용자
   확정)대로 한 프로바이더가 백엔드 전부를 설치, 단독 export 제거.
   전 스위트 exit 0(spec.slot 14절 포함) — 커밋 `d253f6c`.
2. **M10(`spike/m10-tag-attribute`, 1커밋) 머지** — 충돌 넷(init.luau,
   Brand.luau, mock.luau, quad-types) 해소. **H10-3/H10-4 (d) 반영**:
   quad-types의 교집합 콜러블 타입을 `setmetatable<A,B>` 표기로
   교체(실험 오버레이 원문 그대로), quad-base 리터럴의 잠정 `:: any`
   캐스트 제거, `Quad` 필드 풀 타입 복원. 시행착오 하나 — git이 공통
   접미사 `end`를 접어 gameShim의 `end`가 소실(SyntaxError), 보정.
   전 스위트 exit 0 — 커밋 `91ea930`.
3. **통합 판정(메인 몫) 셋** — `H10-5`(M5 spec 6절 nil→안내 스텁 재작성)
   **승인**(Q4 (a) 본뜻 + 2026-08-18 재역전 취지 둘 다 보존), `H10-1`
   (6파일 분할 → 값+핸들러+등록 1파일, H-278 형) **승인** + ROADMAP M10
   서술 재편, `H10-3` (d)는 위 반영으로 종결.
4. **문서 반영** — ROADMAP M6/M10 배너+체크박스(편입 `[x]`·흡수 표시·잔여
   목록), round16 원장 행 ✅(H10-3/H10-4/H10-5), attribute-plan
   `error(…,2)` 둘을 현행 계약(`Err.errorBefore(SURFACE)`)으로 이관,
   **typing-limits 8.6절 신설**(교집합 무거주 → setmetatable 처방 +
   `__call` 인자 무검사 구멍 — session 03의 반영 계획 마지막 몫),
   question.md 두 항목 현황 갱신(AttributeGroup 롤백 / Slot foreign),
   머리말 3층(todos/CLAUDE.md/project-context) 병렬 트랙 종료.

## 아침 검토용 — 문제점·후행 작업 정리

**사용자 판단이 필요한 것** (급한 순):

1. **Slot의 foreign Instance 계약**(question.md 낮은 우선순위 절, 현황
   갱신됨) — 현 구현은 `isInst`만 보므로 quad 밖 Instance도 요소로
   받아들여지는데, 실물 Roblox에선 미claim userdata 동일성 구멍(H-293
   계열)이 그대로 적용된다. "받아진다"와 "안전하다"가 갈리는 자리 —
   v1-compat 착수 전 결정 필요(지금 막는 것 아님).
2. **`AttributeGroupHandler` 부분 실패 롤백**(같은 절) — fork도 롤백 없이
   문서화 노선 유지. M10 잔여(엔진 축) 마감 때 판단으로 이월.
3. **M6/M10의 "완료" 경계 승인** — 두 마일스톤 다 부분 완료 상태로
   편입됐다(잔여는 ROADMAP 배너가 소스). 다음 마일스톤 순서(M6 잔여
   마감 → M7? 또는 M10 엔진 축 먼저?)는 사용자 방향 결정 몫.
4. **Tag/Attribute 엔진 op의 설치 형태**(감사 A 제기) — mock의
   `installTagAttributeOps(quad, log?)`는 프로바이더 밖 opt-in 별도
   함수로 남아 있는데, (d′) "모든 프로바이더가 같은 형태" 원칙을 이 세
   op에도 적용해 `mockProvider`/`RobloxFactory`에 흡수시킬지, Tag/Attribute를
   의도적 opt-in 서브시스템으로 둘지 미정(실 백엔드 쪽 배치도 M10 잔여라
   아직 실사용례 없음 — 지금은 설계 공백이지 버그 아님). M10 엔진 축
   착수 때 정하면 됨.
5. **fork 워크트리·브랜치 정리 관례의 등재 위치**(감사 3라운드 제기) —
   "머지 확인 후 사용자 확인 뒤 remove"는 실무 관례일 뿐 `conventions.md`
   어디에도 명문화돼 있지 않다(grep 확인). 계속 지킬 거면 handover
   체크리스트나 밤샘 자율 구간 절에 한 줄 등재할지 결정 — 지금 워크트리
   둘(`agent-a7882c53ea8f0d292`=M6, `agent-a4faf5545e4b78e0c`=M10)은 머지
   완료 상태로 남겨뒀고 확인 주시면 제거한다.

**메인이 이어서 할 후행 작업** (승인 불요) — **목록의 유일한 소스는
`ROADMAP.md` M6/M10 배너다**(감사 B가 이 파일의 자체 목록이 배너와
갈리는 걸 잡아 포인터로 축소 — "개수·목록 소스 하나" 규약). 여기만 있는
항목 하나: fork 워크트리·브랜치 정리(머지 확인 후 remove — 사용자 확인
관례).

## 끝 절차 기록

- **감사 루프 — 3라운드 수렴(11 → 5 → 1)**, 각도: 1라운드 A(base/·코드↔정본)
  +B(인덱스·원장) 병렬(밤샘 예외) / 2라운드 수정분 재검·코드 주석·spec
  헤더·원장 시제·luau-test / 3라운드 수정분 재검·error 계약 역검증·archive·
  conventions. 실질 발견 중 코드 결함은 **`H10-7`** 하나(공개 생성자·메소드
  `H-238` 미태깅 — 사용자 인자 오류가 quad 내부를 blame; Nearest 전환+태깅+
  blame spec으로 닫음, `07d33d4`). 나머지는 서술 정합(architecture 소스
  트리 H10-1 재편, README 색인 합류, ROADMAP Q6 각주·잔여 단일 소스,
  slot-plan stale 삭제, question.md 시제 등 — 커밋 `368caba`/`07d33d4`/이
  커밋). 세션 재시작(Fable 5.1 전환) 중 2라운드가 한 번 중단돼 새로
  띄웠다.
- **`/code-review medium`** — 통합 흐름당 1회, 결과는 아래 후기.
