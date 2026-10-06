# round14 반영 계획 (2026-10-06 착수)

> **[2026-10-06 신설]** 2026-10-02 새벽부터 2026-10-06까지 쌓인 사용자 결정을 코드·문서에 반영하는 순서표다. 결정의 소스는 원장 `post-implementation-review-round14.md`(각 문항의 닫힘 문단, §4 머리 "이미 정해졌고 반영만 남은 것" 문단, §5 `H-886`~`H-894`)와 `feedback/consumer-kits-2026-10-05.md`(머리의 사용자 회신 블록)다 — 여기는 묶음과 순서만 적고 결정 내용을 다시 풀어 쓰지 않는다. 사용자 지시(2026-10-06): *"반영은 시작하는게 맞지 않을까 싶음 … 적용 후에도 확인 검토를 한 패스 할 수도 있고"*. 단계마다 오푸스 실행자 하나 → 메인 검토·게이트(doc-check ERROR 0 && test.sh exit 0) → 커밋. 단계는 같은 파일을 겹쳐 고치지 않게 나눴고 **순서대로** 돈다(병렬 금지).

## 단계

| 단계 | 범위 | 항목(소스 문단) |
|---|---|---|
| P0 | 개명 | Q175 `StoreBind` → `StateHandler`(파일·spec·require·`spec.dispatch` 이름 목록·라이브 문서·사이트 사본·CHANGELOG Changed; 히스토리 문서·절 제목은 그대로) |
| P1 | 반응형 코어(quad-base: Effect·Observer·Source/State·Gate/Debounce·StateHandler) | 10-02 새벽: Debounce Time 진입 캐시와 `Flush` nil 가드 철거, `H-570` 두 줄 철거(+`spec.debounce` 13·CHANGELOG Fixed 줄) → debug 감지기 2(`Cancel` 머리 스택 검사, 핸들 `Flush` 경로 포함 — 재진입 `Flush`는 보고), `Source:Set` 계열 검사에 `type(v) == "table"` 먼저; Q174 StateHandler Observer `_internal` 빼기 + 경고 문구; debug 감지기 1(Observer 보류 갈래 되먹임 검사 + 내부 Observer 비공개 생성 경로 — Slot 자리 계산·`:List`·부기) + `H-886`; Q173 `assertAcyclicChain` debug로(StateHandler + Slot 경로 셋, 본문 위쪽 함수) |
| P2 | 디스패치·Slot·부기·Tag·Store·Modifier(+Tween 안내 등록) | `H-38` 사이클 끝 교체; Q170 최종(사전 패스 = `wrapElement`만, `H-517` 되돌림, `seen` debug로, `claimOwner` 문구 owner == self, 마운트 때 `Quad0156` 문구); Q171 `H-240` 검사 둘·재시작 가지 철거(+`dispatch-core-plan`·`Bookkeeping.luau` 머리 "자가 치유" 문장); Q168 (a); Q169 (1); Q167 + Modifier 필드·setter `type` 먼저; checked 캐스트 양성 캐시; Q176 Tag 깊이 가드 철거·`Quad0201` 퇴역; C0 Slot CRUD 호스트 claim debug 확인; debug 감지기 3(`Dispatch.process` 입구 claim); Q161·Q182 `module.Protocols.DispatchHint` + `__dispatchHint` 안내(Store·Context·Provider·Blocker·AttrKey·Tween), `noMatchMessage` 이름 분기 제거; `H-894` |
| P3 | quad-roblox 잔여 + 감지기 보강 | (2026-10-06 P1 뒤 추가 — 원장 "**Q174 보강" 문단) debug 감지기의 정의된 재진입 프레임 비공개 등록부(base Observer) + Property `Completed` 호출 프레임 등록(`Started`/`Cancelled`와 분리), 감지기 2에 재진입 `Flush`·leading 통과 프레임; Q166 `H-877` 새 값 콜백 차단 걷기(`spec.tweenproperty` 13 첫 단언); Q179 `__tostring` Info + debug 경고; Q163 `spec.tweenproperty` 12 관측 표시 |
| P4 | 문서만 | Q160·Q183(architecture 예외 안전성 절·00-index "약속하는 회복 하나·비회복 하나", errors/04 근거 표기), 10-02 core/05 Effect/Observer 구조 설명 + C3 한 줄, Q162(core/07·`spec.refhandlers` 4), Q163·Q164(roblox/06·GS 17·CHANGELOG Added 13), Q172(core/06 + architecture 고리 원칙), Q177(errors "고치려면"은 원인만·관측 별도 줄·내부자 태그 제거 — Q183 뒤), Q178, Q180(extend/01 mock 정책), Q181(core/06 134), `H-887`~`H-893`, `isClaimed` 계약(extend/01 두 층)·소비자 문서(`isClaimed`·`canExecute` (가)), `q.Backend` 정의(architecture·extend/01 표 두 층), 타입 레시피(`StateMarker<T>`로 받고 캐스트, F1·A5b·keyFn — how-to 01·typing-limits), Quadnomicon "파동을 받는 두 방식"(메인 초안 → 사용자 피드백) |
| P5 | 뒤로 | 라이브러리 저자 how-to(소비자 피드백 C1·C2·C4·C5·C6·C8), 업스트림 보고 초안 둘(최신 빌드 재확인 뒤) |

모든 단계 공통: 새 필드·이름·메커니즘은 위 결정에 있는 것만(그 밖은 멈추고 보고), 사용자 콜백을 pcall로 감싸지 않음, debug 검사는 본문을 파일 위쪽 함수로·호출은 `if module.debug then … end` 한 줄, 공개 동작이 바뀌면 같은 커밋에 CHANGELOG `[Unreleased]`, raise 자리를 지우면 `scripts/error-codes.py`의 퇴역 규칙(번호 재사용 금지), 레퍼런스의 UB 결과는 "관측 — 계약 아님". 다 끝나면 감사 루프 + `/code-review` 한 번(사용자: 적용 후 확인 검토 한 패스).

## 진행

- P0: 2026-10-06 완료 — `06f01e8e`.
- P1: 2026-10-06 완료 — `0da73eb6`(발견: Q174 vs Q164 스냅 `Completed` 오경보 → 사용자 (b), P3에 편입).
- P2: 착수 2026-10-06.
