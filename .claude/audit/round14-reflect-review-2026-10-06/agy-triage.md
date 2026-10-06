# round14 반영 diff — Gemini(flash) 리뷰 추림

원문: 같은 폴더 `agy-report.md`(Gemini 보고서 원본 사본, 격리 worktree `/code/Projects/quad-agy/review-r14-reflect/`에서 생성).
범위: `git diff 1cef4ef7..HEAD`(HEAD `34a4f1f9`, round14 결정 반영 커밋 10개). 판정자: opus 서브에이전트(2026-10-06), 주장마다 HEAD를 직접 열어 대조했고 동작 주장은 mock 프로브로 재현했다(프로브는 quad-base/test 아래 임시 zz 파일로 돌리고 실행 뒤 지움, 워킹트리 클린 확인).

## 머리 요약

Gemini 발견은 넷(MED 1, LOW 3)이고 근본 원인 묶음은 둘이다. 판정은 **확정 3 · 그럴듯 0 · 기각 1**이다. 확정 셋은 모두 문서·주석 잔재이고 동작 결함은 없다. 가장 쓸모 있는 것은 발견 1 — `[Unreleased]` CHANGELOG의 Slot foreign BREAKING 항목에 `H-517` 시절 괄호 문장이 남아 같은 절 40행과 반대로 말한다(사이트 사본도 같음). `/code-review` 여섯과 겹치는 것은 없다(발견 3만 (3)과 같은 "공개 `Protocols` 표를 1st-party 코드가 읽는다" 축에 인접하나 주장이 다르다). 묶음 A(번복된 사전 검사의 잔재 동기화 누락)는 타당하고 발견 4도 같은 부류(일괄 치환이 놓친 파일)라 함께 묶을 만하다. 묶음 B는 발견 3과 함께 기각.

Gemini의 "확인 못 한 것" 둘(실기기 Deferred 순서, Roblox `-O2` 인라인)은 발견이 아니고 이미 추적 중이다(HUMAN_TODO I, `3fb4582e` 계획표 P3b 부수 발견 줄).

## 판정 표

| Gemini 번호 | 판정 | code-review 겹침 | 한 문장 | 근거 |
|---|---|---|---|---|
| 1 (MED) | **확정** | 없음 | `CHANGELOG.md:60`(사이트 `docs/site/src/content/docs/changelog.md:62`)의 괄호 "(`State`에 담긴 원소도 그 현재값으로 미리 검사합니다)"는 P2에서 되돌린 `H-517` 동작이고, 같은 `[Unreleased]` Changed 절 40행("`State`로 넣은 원소는 넣을 때 값을 읽지 않고 … 마운트·값 변경 때 검사")과 HEAD 동작에 어긋난다. | 그 괄호는 `83e85ade`(2026-09-16)에 들어왔고 범위 안 diff는 그 줄을 안 건드렸다(`git log -S`). 프로브: 마운트 전 Slot에 `q.Source(Instance.foreign("Frame"))`를 `Add` → debug 꺼짐·켜짐 모두 `ok true`, 마운트 줄에서 `Quad0241`. 마운트된 Slot이면 `Add` 줄에서 `Quad0241`·`Length 0`(마운트가 곧 읽는 시점이라 그렇게 보일 뿐 사전 검사는 아님). |
| 2 (LOW) | **확정** | 없음 | `quad-base/test/spec.slot.luau:817-818` 주석의 "with q.debug on, the round14 Q173 value-chain walk in wrapElement still reads it"는 P2 시점 서술이고, P3(`540207a1`)에서 그 걷기가 `wrapElement`에서 빠져 지금은 틀렸다. | 주석은 `a4813a5a`(P2)가 썼다. HEAD `quad-base/src/Slot/Elements.luau:75-81`이 "Quad0070 walk … is NOT run here"라 적고, 사슬 검사는 `Slot/List.luau:41-43`·`170` `checkItemChains`(마운트·값 변경 때). 같은 파일 1570-1584행 (7)절이 debug 켜짐에서 `runs == 0`을 단언한다. 프로브: debug 켜짐·꺼짐 모두 마운트 전 `Add(Compute)` 뒤 `runs 0`. |
| 3 (LOW) | **기각** | (3)에 인접 — 같은 "공개 `Protocols` 표 읽기" 축이나 주장이 다름 | `quad-roblox/src/Tween.luau:148`·`217`이 `quad.Protocols.DispatchHint`를 nil 확인 없이 쓰는 것은 결함이 아니다. | `nil` 확인 안내는 **타입 좁히기**용이다(`quad-types/src/init.luau:713-717`, 레퍼런스 `02-dispatch-handler-contract.md:232`). Tween의 `install(quad: any)`(`Tween.luau:115`)는 `quad`가 `any`라 좁힐 타입이 없고, quad-roblox는 quad-base와 lockstep 릴리즈라 그 키는 늘 있다(`quad-base/src/init.luau:91`). 값은 설치 때 한 번 지역에 캡처되므로 code-review (3)이 말하는 "설치 뒤 사용자가 공개 표 항목을 nil로 덮으면 크래시"도 Tween엔 해당 없다. 가드를 넣으면 등록 실패를 조용히 삼켜 오히려 진단이 사라진다. |
| 4 (LOW) | **확정**(영향 극소) | 없음 | `docs/getting-started/11-slot.md:269` HTML 주석의 "자리의 State는 StoreBind가 … 맡는다"는 Q175 개명(`06f01e8e`)이 놓친 현재형 서술이다. | 개명 커밋의 파일 목록에 `11-slot.md`가 없다. 다만 사이트 동기화가 한 줄 HTML 주석을 지우므로(`docs/site/sync-docs.py:130`·`170`) 사이트 사본 `11-slot.mdx`에는 그 줄이 없고, md-txt 산출물도 사이트 본문에서 나오므로 독자 노출은 0이다. 개명 커밋이 "경위 문장은 옛 이름 유지" 규약을 적었는데 이 주석은 날짜 붙은 근거 메모이면서 현재형이라 경계선이다. live `docs/`·`base/`·spec에 남은 다른 `StoreBind`는 `옛` 표기·CHANGELOG 개명 줄·히스토리 문맥뿐이다(`docs/site/dist/`는 gitignore 빌드 산출물, 재빌드 때 갱신). |
| 묶음 A | **타당**(보강) | — | 발견 1·2는 같은 뿌리 — 사전 검사가 여러 단계에 걸쳐 번복되면서(2026-09-16 `H-517` 도입 → P1 Q173 debug 이동 → P2 `H-517` 되돌림 → P3 debug 걷기도 철거) 앞 단계에 쓴 서술을 다음 단계가 전수로 쓸어내지 않았다. | 발견 1은 P2가 놓친 2026-09-16 서술, 발견 2는 P2가 직접 쓰고 P3가 놓친 서술이다. 발견 4(개명 일괄 치환이 놓친 한 파일)도 "결정을 바꾼 커밋이 그 결정의 옛 서술을 grep 전수하지 않았다"는 같은 부류로 묶을 수 있다. Gemini의 경위 서술 중 "round10~13 탐사가 `H-517`과 Q173 걷기를 추가"는 대략 맞다(Q173 걷기의 기원은 round13 Q113 (a), `Elements.luau:76` 주석). |
| 묶음 B | **기각** | — | 발견 3이 기각이므로 묶음도 기각. | 위 3번 행. |
| 확인 못 한 것 1·2 | 발견 아님 | — | 실기기 Deferred 순서·Roblox 최적화 수준의 프레임 보존은 이미 추적 중. | HUMAN_TODO I; `3fb4582e` 계획표 P3b 줄("`-O2`에서 `fireCompleted`·Debounce `commitIdle`이 실제로 인라인 … Roblox 실행 환경의 최적화 수준 실측이 필요(실기기 후보)"). |

Gemini의 인용 정확도: 파일:줄 넷 모두 HEAD와 일치했고, 인용한 사용자 발언(Q161 보강 (다))과 타입 주석 문장도 원장·소스에 실제로 있다(약간의 의역). 지어낸 인용은 찾지 못했다. 다만 "전체 판정 우수"류 총평과 원칙 준수 서술은 판정 대상이 아니라 따로 확인하지 않았다.

## 확정 항목별 처방 성격

- **발견 1 — 결정 없이 고칠 것.** Q170 최종 닫힘(원장 `post-implementation-review-round14.md` 97행)이 이미 동작을 정했고 40행이 그 서술을 갖고 있다. 60행과 사이트 사본 62행의 괄호를 지우거나 "`State`에 담긴 원소는 넣을 때가 아니라 마운트·값 변경 때 거부합니다"로 바꾸면 된다. 같은 줄의 "이제 `Add`·생성자·…가 … 거부합니다"도 마운트 전 Slot의 State 원소에는 "넣는 줄"이 아니라 "마운트 줄"이라는 점을 40행과 맞춰 둘 것.
- **발견 2 — 결정 없이 고칠 것.** spec 주석만 HEAD 동작으로 바꾼다(예: "the CRUD line reads no State value, debug or not — round14 P3 Q170 (최종); the chain check runs at mount"). 단언은 이미 맞다.
- **발견 4 — 결정 없이 고칠 것(선택).** 독자 노출이 없어 급하지 않다. 고친다면 "옛 StoreBind(지금 StateHandler)"처럼 개명 규약의 옛 표기로.
