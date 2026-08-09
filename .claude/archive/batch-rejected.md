# [기각됨] `Batch(fn)` — lexical block 기반 지연/합치기, `Blocker`로 대체됨

**기각 일시**: 2026-08-06~07. **현재 유효한 설계**: `base/
blocker-plan.md` — 이 문서가 다루는 것과 같은
문제("여러 Source를 한꺼번에 바꿔도 파생값 재계산이 한 번만 되게")를
값 기반으로 풀어 대체함. 이 파일은 더 이상 능동적으로 참고할 필요 없음
(구현에 안 씀) — "왜 lexical Batch를 기각하고 값 기반 Blocker를 택했는가"가
`quadnomicon`(프레임워크 설계자용 심화 콘텐츠) 소재로 가치 있어서 사유를
통째로 보존해둔 것.

**중요**: 이건 "값 기반 지연/합치기"라는 문제 자체를 기각한 게 아니라,
**그 문제를 lexical block(Solid `batch()`/MobX `runInAction()`류)으로
풀려는 접근만** 기각한 것 — 실제 해법은 완전히 다른 별개 primitive인
`Blocker`로 채택됨.

## 무엇을 검토했었나

`Batch(fn)`을 "플래그 세우고 `fn` 실행, 끝나면 flush"로 구현하는 안 —
`fn` 안에서 여러 `Set()`을 몰아서 호출해도 소비자에게 전파는 `fn`이 끝난
뒤 딱 한 번만 되게 하는, 함수/코루틴 스코프 lexical transaction 블록.

### "즉시 pull"이 뭔지 (참고용 예시)

store-bind 핸들러(예: `Frame { BackgroundColor3 = total }`)는 lazy가
아니다 — 화면에 실제로 반영하는 "누군가"가 바로 이 핸들러 자신이라,
무효화 신호를 받자마자 스스로 `Get()`하고 바로 대입한다:

```lua
local total = a:With(b):Compute(function(av, bv) return av + bv end)
Frame { BackgroundColor3 = total }

a:Set(1) -- total 무효화 → 핸들러가 즉시 (av=1, bv=이전b)로 재계산+대입
b:Set(2) -- total 무효화 → 핸들러가 즉시 (av=1, bv=2)로 다시 재계산+대입
-- BackgroundColor3가 중간값을 한 번 거쳐가고, 두 번 대입됨
```

## 기각 이유 — 코루틴 yield 위에서 구조적으로 위험

`Batch(fn)`을 "플래그 세우고 `fn` 실행, 끝나면 flush"로 구현하면 **`fn`이
yield하는 순간 위험해진다**(사용자 지적, 정확함):

1. 플래그가 전역이면, yield 중 스케줄러가 돌리는 무관한 코루틴의 `Set()`이
   이 Batch에 잘못 휘말릴 수 있음.
2. 플래그를 코루틴 스코프로 만들어도(Fusion `Contextual`류 코루틴 키 weak
   table), `fn` 안에서 새 코루틴을 스폰하는 API(Promise, `task.spawn`)를
   부르면 그 새 코루틴은 배치 스코프를 상속 못 받아 일부 Set이 새어나감.
3. `fn`이 영원히 재개 안 되면(장시간 대기, 리크된 코루틴) flush가 영영 안
   일어나 store-bind 핸들러들이 화면을 무기한 stale 상태로 방치 — 즉시
   pull보다 더 나쁜 실패 모드.

이건 구현을 잘 짜서 피할 수 있는 버그가 아니라 **lexical block 모델
자체가 협조적 스케줄링 환경과 구조적으로 안 맞는 것**으로 판단, 기각.

## 왜 완전히 헛수고는 아니었나

"지연 구간을 표현하고 싶다"는 문제의식 자체는 정확했고, `Blocker`가
정확히 그 문제를 콜스택/코루틴이 아니라 **값**(`Blocker` 객체의
`On()`/`Off()`)으로 표현해 풀었다 — Batch가 무너뜨렸던 세 가지 실패
모드(전역 플래그 오염, 새 코루틴 미상속, 영구 yield로 인한 무기한 방치)가
Blocker에선 구조적으로 전부 해당 안 됨(`On()`/`Off()` 사이에 얼마나 많은
yield/코루틴 전환이 끼어도, 심지어 완전히 다른 코루틴에서 `Off()`를
불러도 문제없음). `quadnomicon`에서 "콜스택/코루틴 스코프로 상태를
표현하려던 시도가 왜 항상 위험한가"의 구체 사례로 쓰기 좋음.
