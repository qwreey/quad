# quad-roblox 원칙 감사 (2026-10-01, opus 읽기 전용) — 요지

판정 기준 `PRINCIPLES.md`. 범위: 핸들러 다섯(Property·Event·OnChange/Out·InstanceChild·InstanceShorthand), Tween·Animate·LifetimeHandle·EngineOps·Reflection·Brand·RobloxFactory·init, 생성 Declaration 런타임, `scripts/gen-d.py` 특수 분기 목록, mock의 엔진 차이 자리. (가) 2 / (나) 0 / (다) 2 / (라) 약 73(대부분 사용자 원문 결정 Q25·Q26·Q33·Q48·Q49·Q53·Q58·Q65·Q71·Q104·Q115·Q116·Q126 등, 나머지는 엔진 실측·입구 한 줄 검사).

## (가)-1 던지는 Tween 콜백 뒤 "회복"을 문서·spec이 약속(D2·D1, 확신 높음)
`Property.luau` 121~123 머리 주석("Done은 콜백 전에 세워져 던지는 콜백이 기록을 진행 중으로 남길 수 없다"), `docs/reference/roblox/06-tween-animate.md` 322("다음 값이 오면 정상으로 이어지지만"), `base/tween-plan.md` 755 부근, `spec.tweenproperty` 11절 364~372("boom" — 던진 `Cancelled` 뒤 새 트윈). 출처 `H-582`(round11 §8 code-review ①, 사용자 원문 없음); round13 E4 정정이 이미 "예외 안전성 계약상 UB라 결함 아님" 판정 + 반례 실측(던진 뒤 같은 옛 목표를 다시 보내면 Dedup에 먹혀 중간값 고착 — 322행은 사실로도 틀림). 코드 비용 0(순서는 "모으고→쓰고→부른다"의 귀결) — 고칠 것은 약속 어조: spec 단언 삭제 또는 "관측 — 계약 아님", 322행 "던지면 이후 상태 정의 안 됨", 주석·tween-plan 어조.

## (가)-2 파괴된 인스턴스 위 `process`의 새 값 콜백 게이트(`H-877`, C6·D1·A2, 확신 중상)
`Property.luau` 178~183 `announce`의 `isClaimed(inst)`, `spec.tweenproperty` 13절 476~486(시체에 직접 `process` → `Started`·스냅 `Completed` 안 불림). 출처 `H-877`(round13 §1 code-review ①, 사용자 원문 없음) — 사용자 승인 Q82(*"82 는 권고대로"*)는 시체 위 `retractFrom` 정산 콜백만 막았는데 H-877이 "한 규칙"이라며 새 값 콜백까지 넓혔고 주석이 Q82 옆에 같은 결정처럼 적음. 코드 주석 스스로 "claim이 끝난 인스턴스에 대한 process는 `H-293` UB", extend/02 383 "파괴된 인스턴스에 공개 process/drive = UB, 핸들러가 조용히 성공". 비용: 콜백 실은 전이마다 `isClaimed` 1회(작음). 걷으면 시체 위 직접 process에서 콜백이 불림(= extend/02의 "조용히 성공"과 같아짐), spec 13 첫 단언 삭제(뒷부분 BrandPredicates·Quad0083·배열 자리 Tween 힌트는 무관). 추론(미실측): 콜백이 전이 도중 호스트를 Destroy한 경우의 `Started`도 막는데 그건 C1 UB.

## (다)-1 Animate·숏핸드가 발행마다 Tween 전체 재검증(E3, 확신 낮음 — 가벼움)
`Animate.luau` 423·434(`tweenOutermost` → `validate`), `InstanceShorthand.luau` 263(`Mapped`/`Wrapped` → `newTween`의 `validate`). 검증 자체는 사용자 결정(round19 Q5 (a)·Q16 (b)), 실행마다 도는 경로는 `H-464`·`H-502`·round10 G-1(①). 리터럴 옵션은 생성 때 이미 검증 — 실행마다 중복. 실측(CLI, 엔진 Create 제외): Tween 하나 1.1µs 중 검증 약 160ns(15%), 실제론 엔진 Create가 지배. 고정 spec: `spec.tweenproperty` 9, `spec.animate` 5·7, `spec.tween` 4(리터럴 재검증만 빼면 그대로).

## (다)-2 debug 모르는 키 검사 본문이 로직 한가운데(E2 형식, 확신 높음·사소)
`Tween.luau` 263~269, `Animate.luau` 358~364 — 파일 위쪽 함수로 뺄 것(`InstanceChild.luau` `checkNotOwnAncestor`가 본보기).

## 이미 정한 결정과 맞물림(한 줄)
Q91(모으고→쓰고→부른다)·Q92는 Tween 콜백 안 같은 자리 State `:Set`을 정의된 동작으로 만들었다(`spec.tweenproperty` 12 "Cancelled 재진입 → 한 트윈") — 파동 도중 자기 상류 되먹임 경로인데 core/05 정본의 예외 목록(엔진 왕복·Slot CRUD 고리)에 없다. 예외로 올리든 의식적으로 확인하든 필요.

## 경계선 메모((라)로 판정)
- `InstanceChild.luau` 70~73 `isHandlable` 양의 정수 키 검사(round10 §11 code-review, 원문 없음) — 입구 한 줄, B1 예외, `spec.handlers` 12 (6). 유지.
- `LifetimeHandle.luau` 82~95 `isClaimed`의 `gcconn.Connected`(`H-548` ①, 원래 `H-293` UB 동작을 결정적으로 만든 C6 결) — 뒤 사용자 결정 Q71(`H-594`)·Q82가 이 동기 의미에 기대 사실상 추인.
- `Property.luau` 313~325 두 순서 장치(`H-406` Create 먼저, 2026-09-28 code-review 쓰기 먼저) — 비용 0, 다만 주석이 던진 뒤 무결을 목표로 서술("남은 구멍 하나는 Play raise") — D2와 반대로 다음 장치를 부를 어조, 주석만 "비용이 없어 이 순서일 뿐, 약속 아님"으로(확신 중).
- `Tween.luau` 149~155 `H-463`(Value가 None·중첩 Tween 거부) — 사용자 불변식 Q16 (b)의 런타임판, 생성자 입구. 유지.

## 알려진 항목(재론 안 함)
`H-547`(평범한 값 쓰기마다 `tweenSlots` 조회·`SetStrong(true)`·retractor 캐시 — 핫 패스 비용도 이 안), `H-577` 철거 시 읽기 비교(Q97로 이관·열림), mock 리스너 순서·같은 값 발화·throw 전파(Q120·Q149), `H-581` 통지 창(Q91·Q99로 정함). mock이 UB 결과 고정에 관여하는 곳은 (가)-2 spec 13 하나.

## 곁 발견(원칙 밖 stale)
`quad-roblox/src/LifetimeHandle.luau` 14~24 머리 주석 "미claim 인스턴스 hold는 여기선 에러, mock은 lazy claim" — round11 Q64·round13 `H-658` 뒤 mock도 같은 게이트로 거부(`mock.luau` 725 부근).

## 미완
`spec.claim`·`spec.robloxfactory`·`spec.component`·타입 spec 정독 안 함, `onchange-plan`·`event-plan`·`ui-shorthand-plan`·`claim-plan`·`upward-flow-plan`은 grep 대조만, `gen-d.py` 줄 단위 안 봄, mock 타이머·Tag/Attr op 안 봄.
