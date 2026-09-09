---
title: "Vol. 3 — Luau 메모리 토폴로지: Ephemeron의 부재와 격리된 앵커 섬"
description: "Ephemeron이 없는 Luau GC 환경에서 quad가 메모리 누수를 막는 앵커 설계를 설명합니다"
---
# [Quadnomicon Vol. 3] Luau 메모리 토폴로지: Ephemeron의 부재와 격리된 앵커 섬

> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-base/src/Relate.luau`, `quad-base/src/Dispatch/init.luau`, `quad-roblox/src/LifetimeHandle.luau`

> [!CAUTION]
> 이 권은 Luau GC 토폴로지와 앵커 설계를 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](../getting-started/01-core-mental-model.md)부터 보십시오.

---

## 1. Luau GC의 제약: Ephemeron이 없다

선언형 UI 라이브러리를 바닥부터 짤 때 가장 까다로운 복병은 GC 누수입니다. 특히 Luau는 Lua 5.2+가 도입한 **에페메론 테이블(Ephemeron Tables)을 지원하지 않습니다** — 복잡성 때문에 그 기능을 들이지 않았다고 Luau 호환성 문서가 명시합니다.

### Ephemeron이란 무엇이며, 왜 중요한가

약참조 키 테이블(`{ __mode = "k" }`)에서 키 $K$는 약하게 잡힙니다. 그런데 값 $V$가 $K$를 직·간접적으로(클로저 업밸류, 객체 필드) 참조하고 있다면?

- **에페메론이 지원되는 언어**: $K$에 대한 외부 강참조가 사라지면, $V \to K$ 참조가 있어도 $K$와 $V$를 함께 수거합니다.
- **Luau**: $V$가 $K$를 잡고 있는 한 $K$는 살아 있고, $K$가 살아 있으니 엔트리가 살아 값 $V$도 삽니다. **순환이 끊기지 않습니다.**

quad는 이걸 추측이 아니라 실측으로 확인했습니다 — 되참조 모양을 만들어 50회 반복하면 50/50 남고, 그 참조를 약하게 낮추면 0/50으로 떨어집니다.

---

## 2. Dispatch 엔진에서 마주친 실제 누수

`quad-base/src/Dispatch/init.luau`는 인스턴스마다 키별로 핸들러 체인을 관리합니다:

```luau
-- {[inst(weak)] = {[k] = {[index] = {handler, retractor}}(weak value)}}
```

- 각 체인 슬롯은 핸들러와 함께, 직전 상태를 되돌리는 **`retractor` 클로저**를 들고 있습니다.
- `retractor`는 프로퍼티를 되돌리거나 관측자를 해제하기 위해 (전이적으로) **`inst`를 업밸류로 캡처합니다.**
- 그러니 체인 리스트를 `chains`에 **강하게** 걸면, weak 키(`inst`)의 버킷 값이 자기 키를 되참조하는 위 패턴이 그대로 됩니다 — 반응형 바인딩이 하나라도 있던 파괴 인스턴스가 전부 영구 잔존합니다. Destroy는 계약상 retract를 부르지 않으므로 스스로 풀리지도 않습니다.

---

## 3. 해법: 전부 weak, 앵커는 `bindLifetime` 하나

```mermaid
graph TD
    subgraph Engine ["Roblox 엔진 (C++)"]
        INST["Instance (userdata)"]
    end

    subgraph WeakRelate ["chains = Relate() (약참조 릴레이션)"]
        RELATE["buckets: { __mode = 'k' }"]
        BUCKET["Bucket.WeakMap: { __mode = 'v' }"]
    end

    subgraph AnchorIsland ["앵커 섬 (gchold)"]
        GCHOLD["gchold 테이블"]
        CHAIN["Chain List: { {handler, retractor}, ... }"]
        RETRACTOR["retractor (업밸류: inst)"]
    end

    INST -.->|weak key| RELATE
    RELATE --> BUCKET
    BUCKET -.->|weak value| CHAIN

    INST ===|nativeClaim의 클로저가 gchold와 inst를 캡처| GCHOLD
    GCHOLD ===|bindLifetime(inst, list)이 값을 넣음| CHAIN
    CHAIN --> RETRACTOR
    RETRACTOR -.->|클로저 캡처| INST

    style INST fill:#4a90e2,stroke:#2a70c2,stroke-width:2px,color:#fff
    style GCHOLD fill:#50e3c2,stroke:#30c3a2,stroke-width:2px,color:#000
    style CHAIN fill:#f5a623,stroke:#d58603,stroke-width:2px,color:#000
    style RELATE fill:#e8e8e8,stroke:#999,stroke-width:1px,color:#333
```

### 1. `chains`는 리스트를 약하게만 잡는다

`Relate`의 `SetWeak` 슬롯은 **값이 약합니다**(`{ __mode = "v" }`). 바깥 키(`inst`)도 약합니다. 그래서 `chains`는 체인 리스트의 수명에 아무 영향을 주지 않습니다.

### 2. 강참조는 인스턴스의 `gchold`가 쥔다

`Dispatch.process`가 `(inst, k)` 리스트를 **처음 만들 때** `bindLifetime(inst, list)`로 gchold에 앵커하고, `chains`엔 `SetWeak`으로만 겁니다. 리스트의 수명은 `chains`가 아니라 그 인스턴스의 바인드 수명과 일치합니다.

이게 가능한 건 `bindLifetime`의 **확장 계약** 덕분입니다: 값이 어떤 알려진 타입(`Observer`/`Effect`)과도 일치하지 않는 평범한 테이블/클로저면, 타입별 후처리 없이 **순수 GC 릴레이션만** 겁니다. "이 값의 수명을 inst의 바인드 수명에 묶는다"가 원래 하던 일과 같은 일이라, 앵커 전용 표면을 따로 만들지 않았습니다.

그리고 앵커는 대칭적으로 풀립니다 — 체인이 완전히 비면 `unbindLifetime(list)` 후 `chains`에서도 빠집니다. 안 그러면 새 키가 생길 때마다 빈 리스트와 그 키가 인스턴스 수명 내내 남습니다.

### 3. 앵커 섬 자체는 무엇이 살려두나

`gchold`를 살려두는 건 릴레이션이 아니라 `nativeClaim`이 만든 클로저입니다. Instance 생성 시점에 절대 발화하지 않는 신호(`ClassName` 변경)에 콜백을 연결하고, **그 콜백이 `gchold`와 `inst`를 업밸류로 캡처**합니다. 엔진이 연결된 콜백을 살려두므로 섬 전체가 삽니다.

대가가 있습니다: **quad가 만든 Instance는 참조를 놓는 것만으로 회수되지 않고 반드시 `Destroy`로 회수됩니다.** 클로저가 `inst`를 잡고 그 클로저를 `inst` 자신의 신호가 잡는 순환이라, Destroy(엔진이 커넥션을 끊는 것)가 유일한 절단면입니다. 다만 실제로 바인딩이 하나라도 걸리면 그 관측자 클로저가 어차피 `inst`를 캡처해 같은 순환이 생기므로, 새로 생긴 제약이라기보다 "아무것도 안 걸린 Instance"까지 같은 규칙으로 통일한 것입니다.

---

## 4. Teardown의 철학: Destroy는 회수이지 철거가 아니다

많은 라이브러리는 인스턴스가 파괴될 때 모든 자식과 바인딩의 정리 함수를 순회하며 실행합니다. quad는 그러지 않습니다 — **파괴 시 `retractor`는 호출되지 않는 것이 계약입니다.**

- 인스턴스가 엔진 레벨에서 파괴됐다면 하위의 프로퍼티와 자식은 어차피 엔진이 정리합니다.
- Destroy로 gchold 섬이 무너지면 리스트·retractor·관측자·`inst` userdata가 전부 도달 불가능해집니다. **이건 철거가 아니라 메모리 해제입니다.**

정리를 즉시 해야 하는 경우(값 하나를 미리 놓아주기)를 위해 `unbindLifetime(value)`이 따로 있습니다. 그건 값 쪽의 바인딩 기록(`gchold`/`gcconn` 슬롯, `Effect`면 `Destroying` 훅까지)만 지우고 인스턴스는 건드리지 않으며, 역시 cleanup을 부르지 않습니다.

---

## 5. 백엔드·플러그인 작성자를 위한 규칙

"강참조 금지"가 규칙이 아닙니다 — `Relate`의 슬롯마다 위험이 다릅니다. 실제 규칙은 셋입니다:

1. **값이 바깥 키를 되참조하면 `SetWeak`을 쓸 것.** 되참조가 없다면 `SetStrong`도 정당합니다(예: 부기의 배치 Blocker는 소유자 키를 되참조하지 않아 강하게 잡습니다).
2. **내부 키로 쓰는 객체는 바깥 키를 되참조하면 안 된다.** `SetWeak`의 `WeakMap`도 **키는 강하게** 잡기 때문에, 이 슬롯은 `SetWeak`으로 도망갈 수가 없습니다 — 규칙으로 막는 수밖에 없습니다.
3. **실제 GC 앵커는 `q.bindLifetime(inst, value)` 하나로 통일할 것.** 릴레이션을 강하게 걸어 수명을 이중으로 표현하면 실제 수명이 어디서 끝나는지가 흐려집니다.

특히 위험한 모양 하나: **서로 다른 두 `Relate`가 서로의 키를 상대 값으로 강하게 제공하는 상호 순환**(`A[inst] = value` 강, `B[value] = inst` 강). `inst`의 도달 가능성 판정이 `value`에 의존하고 그 반대도 마찬가지라 판정 자체가 순환합니다 — ephemeron이 없는 Luau에서 이건 확정 누수입니다. 어떤 값을 다른 `Relate`의 바깥 키로 쓰고 싶어지면, 그 값이 `inst`로 되돌아가는 강한 참조를 갖고 있는지 먼저 확인하고, 최소 한쪽을 `SetWeak`으로 낮추십시오.
