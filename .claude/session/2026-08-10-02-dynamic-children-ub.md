<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-10 세션 — 동적 자식 추가/제거는 `Slot`/`state<Frame>`만 정당,
그 외는 UB로 명문화(문서 갭 보강)

사용자 질문에서 시작: Slot이 마운트한 객체 수를 `Length`/`Offset`
누적합으로 세는 방식(2026-08-09 여섯 번째 세션 확정)이 되면서, 이 카운팅을
안 거치고 quad가 관리하는 부모 Instance에 외부에서 직접 `.Parent = inst`로
자식을 끼워 넣는 게 UB로 문서화돼 있는지 확인 요청 — 검토 결과 **문서
어디에도 명시돼 있지 않은 진짜 갭**이었음(기존 UB 목록엔 Handler 순환/
이중 바인딩/`Dispatch.process` 우회 직접 호출/`setLength`·`setOffsetSource`
생략 등은 있었지만 이 케이스는 빠져있었음, 인접했던 "수동 Visible 토글은
Length가 못 잡는 게 맞다"는 캐비엇은 이미 마운트된 element를 나중에
숨기는 별개 시나리오라 이것과 다름).

**확정**: 동적 자식 추가/제거의 유일한 정당 경로는 `Slot` 또는
`state<Frame>`류 store-bind 뿐 — 둘 다 그 위치의 Handler가
`Dispatch.setLength`/`Dispatch.setOffsetSource`를 정확히 호출하는 것으로
이미 보장돼 있음. 이 두 경로를 거치지 않고 quad가 마운트해둔 부모
Instance에 직접 `.Parent =` 대입으로 자식을 넣거나 빼면 `lengthList`/
`sourceList`가 그 변화를 전혀 몰라 `Length` 카운트와 형제 순서(offset)
계산이 조용히 어긋남 — 새 방어 로직 없이 UB로 문서화만 함(다른 UB
케이스들과 같은 톤). `base/bind-system-plan.md`("Length/Offset" 절
말미)/`base/slot-plan.md`("Slot.Length" 절 말미)에 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션은 순수 문서 갭 보강이라 우선순위엔 영향 없음.

