# E75 그룹 D·E·F 노트 (메인 세션 직접 실측)

실행 출력: `out/D.txt`·`out/D_probe2.txt`(D), `out/E.txt`(E), `out/F.txt`·`out/F_iso_version.txt`(F). 케이스: `cases/D.luau`·`cases/D_probe.luau`·`cases/D_probe2.luau`·`cases/E.luau`·`cases/F.luau`·`cases/F_iso_version.luau`. blame은 전 id가 케이스 파일 줄(사용자 코드)로 떨어졌다 — 내부로 떨어진 것 없음.

## 판정 표

| 페이지 | 섹션 | 시도 | 정확 | 불충분 | 틀림 | 미도달 |
|---|---|---|---|---|---|---|
| 04-ref-observer-effect.md | 34 | 32 | 30 | 2 (0093·0115 자리 묶임 갈래) | 0 | 2 (0098·0117 — E28 도달 없음) |
| 05-tag-attr.md | 26 | 24 | 22 | 2 (0016·0237) | 0 | 2 (0004·0009 — E28 도달 없음) |
| 06-module-backend.md | 25 | 25 | 25 | 0 | 0 | 0 |
| 07-roblox.md | 13 | 13 | 13 | 0 | 0 | 0 |
| 08-roblox-tween.md | 11 | 11 | 11 | 0 | 0 | 0 |

id별: 위 네 id를 뺀 시도 id는 전부 trigger → 그 id(메시지 원문은 out 파일), fix → 무에러 + 의도 확인(속성 값·태그·자식 부모·콜백 발화·Source 되쓰기·트윈 목표 기록 등 — 케이스의 `return` 설명 열).

## 발견

**Quad0016 (05-tag-attr.md:130, 코드 `quad-base/src/Attr/init.luau:262`) — 불충분.** 같은 `Attr` 그룹 값을 한 인스턴스 두 자리에 놓으면(`local a = q.Attr({ Hp = 1 }); D.Frame({ a, a })`) 0016이 나고, 고치려면은 "자리마다 별도의 `q.Attr(...)` 호출로 새 값을 만드세요"다. 그대로 하면(`D.Frame({ q.Attr({ Hp = 1 }), q.Attr({ Hp = 1 }) })`) 0016은 사라지지만 같은 이름을 두 그룹이 주장해 곧바로 `Quad0002 AttrKey: attribute "Hp" is already bound by another owner`가 난다(`cases/E.luau:110-116`, 출력 `FIX=intent-fail … Quad0002`). 같은 그룹을 두 번 놓는 프로그램에서 "새 값 두 개"는 정의상 같은 이름 둘이라 처방이 항상 0002로 이어진다. 실제로 통하는 것은 한 번만 놓는 것(또는 이름이 다른 두 그룹)이다. 문구 후보: "한 자리에만 놓으세요 — 두 자리에 같은 이름을 두면 Quad0002입니다".

**Quad0237 (05-tag-attr.md:210, 코드 `quad-base/src/Tag.luau:105`) — 불충분(LOW).** 언제가 대표 사례로 `q.Tag(state)`를 드는데, 그렇게 쓴 사용자의 의도는 State를 따라가는 태그다. 고치려면("문자열, `Tag`, 또는 평범한 리스트를 넘기세요")을 그대로 따르면 에러는 사라지지만 태그가 State를 따라가지 않는다(`cases/E.luau:156-168`, `literal follows state=false`). 같은 케이스에서 `s:Compute(function(h) return q.Tag(h:Get()) end)`를 숫자 키 자리에 놓는 경로는 동작함을 확인했다(`State<Tag> route works=true` — GS 05 §2가 가르치는 모양). 문구 후보: `q.Tag(state)` 갈래에 "반응형 태그는 `state:Compute(function(h) return q.Tag(h:Get()) end)`를 자리에" 한 줄.

**Quad0093·Quad0115 (04-ref-observer-effect.md:82·:186, 코드 `quad-base/src/Effect.luau:285`·`quad-base/src/Observer.luau:176`) — 자리 묶임 갈래 불충분.** 두 절의 언제는 "자리에만 묶여 있거나"를 트리거로 들고, 메시지와 고치려면은 `:WeakUnsubscribe()`를 가리킨다. 자리에 묶인 핸들에 `:WeakUnsubscribe()`를 부르면 에러 없이 통과하지만 아무것도 풀리지 않는다 — Effect는 dep `Set`에 계속 다시 돌고 인스턴스 파괴 때 cleanup이 돌며, Observer도 계속 발화한다(`cases/D_probe2.luau`, `out/D_probe2.txt`: `WeakUnsubscribe -> true`, `after Set n 2`, `O still fires true`). core/05의 `WeakUnsubscribe` 절이 "관대하며(구독한 적 없어도 통과)"라고 적은 대로의 동작이라 코드 결함은 아니고, 처방이 이 갈래 사용자를 조용한 무동작으로 보낸다. 같은 파일에서 실제로 멈추는 경로 둘을 확인했다: State 자리에 담아 `nil`로 비우기, `q.Backend.unbindLifetime(handle)`(둘 다 `true`). 문구 후보: 자리 묶임 갈래에 "자리에 묶인 핸들은 구독 해제로 풀리지 않습니다 — 자리에서 빼세요(State 자리를 비우기)". `Effect` 쪽은 "강한 구독을 이미 한 번 풀었다면 다시 부르지 마세요"가 있으나 이 갈래 안내는 없다.

**Quad0108 메시지 꼬리 (코드 `quad-base/src/LifetimeHandle.luau:79`) — 처방과 메시지 불일치(LOW).** E28(`H-745`)이 06:122 고치려면의 `mock.installLifetime`(배포 안 됨)을 "자기 프로바이더를 `UseProvider`로"로 고쳤지만, 런타임 메시지의 꼬리 힌트는 아직 `; tests use mock.installLifetime`이다(`out/E.txt` 0108 줄 원문: `… a bare Quad.New() has none; tests use mock.installLifetime)`). 사용자는 메시지가 가리키는 배포되지 않은 헬퍼를 찾게 된다. 코드 문자열 한 곳.

**Quad0182 참고 앵커 (01-core-reactive.md:248)** — `../core/02-source.md#qsourcevalue`는 없는 앵커다. 대상 헤딩은 `` ## `q.Source(v)` ``(slug `qsourcev`). `scripts/anchors.py` 출력 `out/anchors.txt`. 같은 페이지 240행 `#sourcesetv`는 실재. 280개 링크 중 깨진 앵커는 이것 하나(나머지 한 줄은 `mod[key](...)` 본문 텍스트를 링크로 오인한 스크립트 오탐).

## 확인만 한 것 (D·E·F)

Quad0087 "fn/cleanup이 끝난 뒤 다시 묶기"(dispose 뒤 다른 인스턴스에 재바인드 — Effect·Observer 둘 다 동작, 재발화 확인), 죽은 핸들 갈래(rerun에서 던진 Effect는 `:Unsubscribe()` 통과 뒤에도 바인드가 0087 — 새 Effect로 해결). 0089/0091/0111/0114 승격·강등 처방(먼저 해제 → 다른 쪽 구독) 전부 동작. 0130 무관 코루틴에서 `Set`이 대기자를 깨움. 0134 명시 스레드 등록 처방 동작. 0135 PreRef + 이벤트 콜백 안 `Unwrap` 동작. 0002 두 처방(`Overridden` 합치기·먼저 비운 뒤 다음 `:Set`) 둘 다 동작, 그룹+AttrKey 변형도 0002. 0003 `store[""]` 경로 재현, `:Of` 처방 동작. 0029 두 갈래(디스크립터에서 빼고 따로 몰기·`q.dispose` 뒤 새로 만들어 claim) 동작. 0213 처방 `q.New()`는 모듈 인스턴스에서 불러도 동작. 0228 트리거 셋(`3.1.0`·`4.0.0`·`3.3.0-rc.1`) 전부 0228, 처방의 범위 서술(3.2.5·3.4.0·3.10.1 통과, rc는 rc를 정확히 적은 패턴만)과 `TypeVersionCheck.matchesPattern` 일치. 0216은 공개 `Debounce`로 닿지 않음(음수 `Time` State는 `Quad0039`가 먼저) — 페이지 서술과 모순 없음. 0226 파괴된 D 인스턴스에 `bindLifetime`은 GC 전엔 통과(E9·E11 기추적 UB, 페이지 "이미 파괴됐을 때"는 GC 뒤 기준). 0225 공개 경로(`q.Claim` 두 번)는 0029(페이지 서술대로). 0250 두 처방(`Apply(Animate)`·`Compute` 안 `Tween`) 둘 다 트윈 목표 1을 기록. 0251 `None` 방출로 프로퍼티 nil. 0097 Effect를 State에 담아 **숫자 키** 자리에 놓으면 에러 없이 동작(페이지는 문자 키만 주장 — 모순 없음).

## 미완

없음. 0004·0009·0098·0117은 E28 판정(도달 경로 없음)을 그대로 따랐고 공개 API로 새 경로를 찾지 않았다.
