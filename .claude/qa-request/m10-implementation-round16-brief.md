# M10 병렬 탐사 구현 규약 — 16라운드 지시서 (fork/worktree)

> **이 파일이 무엇인가**: **[2026-09-02 신설 — 사용자 승인]**
> `m6-implementation-round15-brief.md`와 쌍인 병렬 탐사 규약 — fork
> 에이전트가 자기 worktree에서 **M10(Tag/Attribute — mock 축)**을 탐사
> 구현한다. 승인 경위·산출물 지위(관측용 후보, 통합은 메인 몫)·멈춤 규칙
> 원문은 M6 브리프 머리말·§2가 소스 — 여기선 반복하지 않는다.
>
> **명명**: 라운드는 round16, 발견 번호는 **`H10-1`부터**(접두로 메인
> `H-nnn`·M6 `H6-nnn`과 구분, ID 영구). 발견 문서는
> `m10-implementation-round16.md`(fork가 자기 worktree에 신설).

## §1 스코프

`ROADMAP.md` M10 체크박스 전량이 소스 — Tag/Attribute 특수 키와 그
핸들러·주입 op(정본은 `base/tag-plan.md`/`base/attribute-plan.md`/
`base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진 op"
절). **mock 위에서 CLI로 굴릴 수 있는 몫 전부**:

- base 소유 핸들러(Tag / `AttributeKey<<T>>` 단일 키 / 그룹 `Attribute`·
  `Tag` — 부기·참조카운트는 base 알고리즘, 엔진 손대기는 op 한 줄).
- 주입 op `addTag`/`removeTag`/`setAttribute`의 **mock 구현**(이 fork가
  mock에 추가 — M5 Q4 (a)로 실물 quad-roblox 쪽은 M10 몫으로 남아 있고,
  실물 배선은 통합 후 메인이). mock 확장은 tag/attribute op까지만
  (native* mock op는 M6 fork 몫 — 겹치지 않게).
- 그룹 키의 이름 claim(`nameClaims` — 두 그룹이 같은 이름이면 즉시 error,
  0-Z 확정)과 재디스패치 하강 diff 경로.

**주의 — Attribute Instance 참조**: 실물은 `InstanceHandle` 언랩 경유임이
실측돼 있다(`audit/spike10-full-run-2026-09-01.md`, 쓰기는 자동 랩이라
무영향). mock은 쓰기 표면만 흉내내면 되고, 읽기 소비자 설계는 스코프 밖.

## §2 가드

M6 브리프 §2와 동일(사용자 정정 포함) — 치환만: 발견 문서/번호는 위 명명,
마커는 `-- TODO(H10-n)`, 브랜치는 `spike/m10-tag-attribute`, 기존 산출물
(M2~M5 — M6 브리프와 같은 경계, 같은 근거) 결함 의심은 고치지 말고
`H10-` 발견으로 기록.

## §3 운용

M6 브리프 §3과 동일(로컬 커밋만 / doc-check ERROR 0 + `./scripts/test.sh`
exit 0 / Studio·네트워크 금지 / 감사·리뷰는 통합 시 메인이 1회 / 종료
조건과 최종 보고 형식).
