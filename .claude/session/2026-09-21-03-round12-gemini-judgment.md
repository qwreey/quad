# 2026-09-21-03 — round12(Gemini 3.1 Pro 여러 에이전트 합본) 판정

**계기**: 사용자가 이석 전 `qa-request/external-review-entry.md`를 오늘 기준으로 다듬어 두게 했고(§0 "이번 감사의 초점"), 돌아와 *"post-implementation-review-round12.md 에 gemini 여러 에이전트가 돌아 나온게 합쳐져있어"*라며 처리를 맡겼다. 합본이라 절 번호가 겹쳐 있어(`## 1.`~`## 3.` 두 번씩, G-24~G-31이 "사용자 회신 대기 문항" 절 아래) 판정 배너를 머리에 얹고 원문은 보존했다(round2·round4 선례).

**부수 확인(사용자 요청)**: 컴팩트 전에 띄웠던 `quad-site-tester`가 "조용히 남아 있다"는 물음 — `ListAgents`는 `completed`, 출력 파일 마지막 메시지가 `end_turn`, 자식 없음. 하네스 목록에 완료 항목이 계속 보이는 것일 뿐 토큰을 쓰지 않는다. 잔여물은 `quad-chrome` 컨테이너 하나(기본 정책대로 유지, `browser.sh down`으로 내림). 결과는 컴팩트 전에 반영된 내용과 같다(각주 팝오버·Agents 토픽 PASS, 좌표 클릭 미확정은 실기기 몫).

## 판정 흐름

항목마다 먼저 원장을 grep했다 — G-23·G-26은 `dispatch-core-plan.md`의 Q5 (a)(같은 `(inst, k)` 간접 재진입 UB, 사용자 *"재진입 게이트는 허용 안한다가 내 생각"*)가 그대로 답이라 Gemini의 가드(콜백 반환 + `GetStrong` 재확인 + abort)는 넣지 않았다. 대신 어느 콜백이 위험한지 손으로 갈랐다: 엔진 경로의 `Started`는 슬롯 쓰기·`Play` 뒤라 그 안의 같은 키 `:Set`도 branch 3가 일관되게 처리하고(옛 `Started` → 옛 `Cancelled` → 새 `Started`), 엔진 경로의 `Completed`는 `process` 밖, 스냅의 `Completed`는 슬롯을 쓴 뒤라 연쇄가 안전하다. 깨지는 건 branch 3의 `Cancelled`(바깥이 아직 자기 슬롯을 안 썼다)와 스냅의 `Started`(바깥 `Completed`가 뒤따른다)뿐 — 그래서 레퍼런스는 "`Started`·`Cancelled` 안에서 같은 프로퍼티를 다시 쓰지 말 것, 잇는 자리는 `Completed`"로 적었다(`H-589`).

G-25는 두 조각으로 갈랐다. 문서 조각: `tween-plan.md` 철거 문단이 *"연결이 먼저 끊겨 콜백에 닿지 않는다"*고 적어 뒀는데, 파괴 경로는 retractor를 돌리지 않는다(Dispatch·Bookkeeping·Slot/Tree 어디에도 `Destroying` 훅이 없고 `nativeDispose`는 `Destroy`뿐; GS 19의 `Destroy()` 답이 같은 말) — 오늘 오후 내가 쓴 문장이 틀렸다(`H-593`). 처방 조각은 새 메커니즘(레코드별 `onDestroying`)이거나 인자 없음 결정을 다시 여는 것이라 `Q71`.

G-28은 Deferred 순서를 따져 창을 좁혔다 — `Destroy`가 gcconn을 동기로 끊고(`H-574` 실측) `Destroying`은 다음 재개점이므로, `task.wait`로 멈춘 fn은 통지 뒤에 깨어나 `dying = true`를 받는다. 파괴한 청크가 직접 재개할 때만 `false`. 플래그 정의(Q57 사용자 원문 *"_dying 이 true 로 새워지는건 오직 onDestroying 콜백 뿐"*)가 그 값을 정당화하므로 확인 기록 + 한 문단(`H-590`). 실측은 안 했다 — 근거가 전부 기실측 사실(`H-574`, REPORT)의 조합이라.

G-29는 core/05가 "해제는 `fn` 안에서도 됩니다"까지만 약속하고 cleanup 안은 약속하지 않았음을 확인한 뒤, 그래도 `_consumeCleanup` 주석이 "cleanup may call `Unsubscribe` (Q63 (b))"라고 적어 둔 만큼 문서만으로 닫을지(권고 (a)) 플래그를 재사용할지((b), 약한 핸들 부수 효과) 사용자 문항 `Q72`로.

G-24·G-30(스킬 문서)은 `external-review-entry.md` §0 A가 이미 stale로 지목한 자리라 sonnet에게 네 지점 + 백틱 에러 문구 전수 대조를 맡겼다(`H-591`). G-31은 docs/·base/ 전수 스캔으로 둘뿐임을 확인하고 직접 고쳤다(`H-592`).

## 상태

감사 루프 2라운드 수렴(2 → 0). 1라운드 확실 발견 둘은 같은 뿌리였다 — `lifecycle-pattern.md`의 2026-08-04 가정 *"Roblox 엔진이 Destroy 시 … 실행 중인 Tween을 전부 알아서 정리해준다"*와 그걸 (a) 전제로 인용하는 `ui-shorthand-plan.md` `H-218` 블록. 둘 다 오늘 실측(REPORT 사실 5·6)에 반하므로 취소선 + `H-593` 정정을 달았고, `H-218`의 결론("자식을 버릴 때 `retractFrom` 의무")은 근거를 바꿔(죽은 인스턴스에 쓰는 건 무해 + 그 경로는 어차피 `stopRunning`이 돈다) 그대로 세웠다 — 결론 재검토는 `Q71` (b)와 같은 물음이라 거기서 답이 난다. 감사자가 사용자 판단으로 분류한 하나: SKILL/core·05/sugar·04의 `dying` 서술이 "죽을 때만 true"로 무조건인데 `H-590` 창을 안 적었다 — 그 창은 이미 "fn 안 yield는 UB" 우산 안이라 캐비엇을 더 적지 않았다(사용자가 원하면 한 줄). 2라운드(정정 전제의 인용처 전수 grep·인덱스 레이어·배너 자기모순)는 발견 0.

test.sh exit 0(스펙 61), doc-check ERROR 0, 사이트 동기화(GS 18·19·roblox/06 미러). 커밋은 이 파일과 같은 커밋.

## 사용자 회신(같은 날 저녁)

Q71 — 사용자: *"파괴로 인한 트윈이 진짜 컴플리트까지 나는지는 한번 봐야할 것 같음. isClaimed 를 통해서 완료 이후 inst 가 gcconn 이 disconnected 상태라면 무시할 수 있다고 봐. claim 이 안 돌면 tween 자체를 못 굴려서, 판정대상으로 쓸 수 있어. 되돌리지는 않지만, 무시할 수는 있는것 같음. defer 이여도 gcconn 판정 자체는 싱크로 돌거야"*. 앞 문장은 REPORT 사실 5가 이미 답(파괴 뒤 `Completed(Completed)` 발화·연결 잔존 — 오늘 Studio 실측); 뒤는 내가 낸 세 갈래 밖의 넷째 안이고 내 권고 (a)보다 낫다 — (b)의 연결 추가도 (c)의 `inst` 포획도 없이, 이미 있는 `isClaimed`(gcconn `.Connected`, `H-548`)와 트윈이 어차피 쥐고 있는 `tween.Instance`만으로 닫힌다. `H-594`로 반영. Q72 — *"권고대로"* (a).
