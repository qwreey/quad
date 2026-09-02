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

**메인이 이어서 할 후행 작업** (승인 불요, 큐):

- M6 잔여: 공개 CRUD 래퍼(`Move`/`Swap`/`Extract`/`Splice`/`Replace`+
  `collectLeaves`), `KeyGone` 파괴 분기 spec, quad-types `Quad`에 `Slot`
  필드(H-25), quad-roblox `Handlers/Slot.luau`, round12 §6 `H-286` ②,
  실기기 검증(Deferred 축).
- M10 잔여: quad-roblox EngineOps 실구현(addTag/removeTag/setAttribute —
  M5 Q4 (a)로 유예된 몫), `Handlers/Event`/`OnChange`, InstanceShorthand,
  Q6 각주(InstanceHandle 언랩 읽기 소비자).
- fork 워크트리·브랜치 정리(머지 확인 후 remove — 사용자 확인 관례).

## 끝 절차 기록

(이 절은 통합 커밋 뒤 감사 루프·리뷰가 돌며 갱신된다 — 결과는
아래 배치 보고와 원장 행이 소스.)
