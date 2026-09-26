# round13 E50: 트리 파괴(teardown) 순서와 cleanup 계약 퍼저

HEAD `bc531020`, 2026-09-27. 레포 파일은 바꾸지 않았다. 하네스는 E44의 `harness.luau`와 `engine-globals.luau` 사본이다(quad-roblox `luau_packages` 한 벌, `typing-limits.md` 8.34). `./scripts/relink.sh`를 돌린 뒤 이 폴더에서 `luau <파일>`로 실행한다.

| 파일 | 내용 |
|---|---|
| `fuzz.luau` | 참조 모델과 퍼저. `luau fuzz.luau -a <첫 시드> <개수> [v] [iso\|raw\|deferred] [변이]` |
| `fuzz-1-10000.txt`, `fuzz-10001-20000.txt` | Immediate 모드에서 핸들러를 격리한 결과. 시드 2만 개, 차등 0 |
| `fuzz-deferred-1-10000.txt` | Destroying을 Destroy가 돌아온 뒤에 배달한 결과(Roblox 기본 Deferred를 흉내). 시드 1만 개, 차등 0 |
| `fuzz-raw-1-2000.txt` | mock 원형(핸들러 격리 없음). 던지는 콜백이 mock `Destroy`를 끊는 한계를 보여 준다. 2000개 중 584개 |
| `mutations-500.txt` | 검출력 확인용 변이 셋(시드 500개 중 차등 386/282/177) |
| `axes.luau` → `out-axes.txt` | (a) 순서, 파동 안 발화, (b) 경로별 `dying`, H-590 yield 창, (c) 늦게 도착하는 신호, (d) 모듈 인스턴스를 버릴 때 |
| `probe-held.luau` → `out-probe-held.txt` | `q.Detach`로 보관 중인 원소가 호스트 파괴 때 어떻게 되는지, 그리고 재마운트 경로 |
| `probe-basic.luau` → `out-probe-basic.txt` | 부착물 전부를 한 번에 거는 기초 확인 |

퍼저는 깊이 1~4, 너비 0~4인 트리를 만든다. 노드마다 붙을 수 있는 것: 의존성 없는 Effect, pulse에 의존하는 Effect, OnDestroyed, Observer, Debounce를 건 Observer, Tag, Attr, Ref, 진행 중인 Tween. 자식을 놓는 방식은 네 가지다: 정적 숫자 키, 수동 Slot, `:List`(`OwnsElements`는 무작위), `State<Instance?>` 자리. 한 시드에서 1~3개의 파괴 연산을 차례로 건다: Destroy, dispose, Remove, Clear, Extract, KeyGone(소유/비소유), SeatNil, 붙잡힌 값의 dispose(Quad0179가 나와야 함). 분리된 서브트리는 절반 확률로 이어서 dispose한다. 콜백(cleanup이나 OnDestroyed)이 하는 일은 여섯 가지 중 무작위다: 아무것도 안 함, 읽기, Set, 자기 Slot의 CRUD, 던지기. 연산 뒤에는 트윈 완료 통지, pulse Set, 타이머 10초 진행을 차례로 보낸 다음 노드마다 계약을 대조한다.

## 모델 규칙과 근거 (23개)

| # | 규칙 | 근거 |
|---|---|---|
| R1 | cleanup은 인스턴스가 죽을 때만 `dying=true`, 나머지 세 자리에서는 `false` | `docs/reference/core/05-observer-effect.md:226` |
| R2 | 매단 Effect는 cleanup이 한 번 돈 뒤 멈춘다(`fn`을 다시 실행하지 않는다) | core/05:32 |
| R3 | 매단 Observer는 파괴 뒤 발화가 0이다. 단 Immediate에서는 같은 호스트의 핸들이 한 번 더 돌 수 있다 | core/05:32 |
| R4 | OnDestroyed는 정확히 1회. 자리에서 뺀 채로 파괴되면 0회 | `docs/reference/sugar/04-lifecycle-hooks.md:90` |
| R5 | 한 인스턴스 위의 OnDestroyed끼리의 순서는 미정이다(mock에서는 역순) | sugar/04:30 |
| R6 | `Destroy()`는 자리별 되돌리기를 거치지 않는다(따라서 removeTag, Ref 비우기, Tween 취소가 없다) | `docs/getting-started/20-handlers.md:207-212`, `:269-277` |
| R7 | Ref는 파괴된 인스턴스를 그대로 가리킨다 | `docs/reference/core/07-ref.md:92` |
| R8 | Attr의 엔진 값은 남는다 | GS 20:189 + R6 |
| R9 | 파괴된 호스트의 Tween은 Cancelled 0, 늦게 온 Completed는 무시된다(isClaimed, H-594). 자리가 철거되면 Cancelled가 동기로 1회 | `docs/reference/roblox/06-tween-animate.md:257`, `:266-271` |
| R10 | Debounce는 호스트가 파괴된 뒤 하류로 발화하지 않는다 | `docs/reference/sugar/03-debounce-throttle.md:42` + R3 |
| R11 | Remove/Replace/Clear는 파괴하고 Extract는 파괴하지 않는다 | `docs/reference/core/06-slot.md:186`, `:196`, `:215`, `:276` |
| R12 | KeyGone이 nil을 돌려주면 소유 Slot은 파괴, `OwnsElements=false`는 언마운트만 | core/06:375, `:402-406`, GS 14:210 |
| R13 | 보관 중인(Detach) 원소는 Slot이 파괴될 때 같이 파괴된다 | core/06:508 |
| R14 | `OwnsElements=false`라도 마운트된 호스트가 파괴되면 원소는 죽는다(엔진이 자손을 지운다) | core/06:406 |
| R15 | `State<Instance?>` 자리를 nil로 하면 자식은 떼어지기만 한다 | GS 20:193, core/10:110 |
| R16 | 붙잡힌 값의 dispose는 Quad0179 | `docs/reference/core/10-lifetime-sentinels.md:110`, `:116` |
| R17 | dispose는 Slot 트리나 백엔드 값을 파괴한다 | core/10:108, core/06:575 |
| R18 | unbindLifetime은 cleanup을 부르지 않는다 | core/10:182 |
| R19 | yield 창: 돌아온 cleanup을 즉시 소진한다(죽어서면 `true`, 자리를 떠나서면 `false`) | core/05:233 |
| R20 | 모듈 인스턴스를 버리기만 하면 cleanup이 없다. Destroy해야 회수된다 | `docs/reference/core/01-quad-module.md:34` |
| R21 | `q.dispose(screen)`: Observer는 멈추고, Effect와 OnDestroyed는 1회 | `docs/getting-started/21-wrap-up.md:47` |
| R22 | cleanup 안에서 dep을 Set해도 된다 | core/05:225 |
| R23 | 파괴된 인스턴스는 다시 쓸 수 없다. 분리된 것은 나중에 dispose할 수 있다 | GS 20:212, core/10:110 |

## 결과

- Immediate 격리 모드, 시드 2만 개(노드 23만): 차등 0. Deferred 모드, 시드 1만 개: 차등 0. 변이 셋은 모두 검출된다.
- 파동 안의 발화(Immediate, 2만 시드): Destroy가 이미 시작된 호스트의 Observer가 발화한 횟수는 같은 호스트에서 6256, **다른 호스트에서 7343**. 의존성 Effect가 dying cleanup 전에 같은 호스트에서 다시 도는 경우는 2622. Deferred에서는 둘 다 0.
- 순서(mock): 파괴 순서는 부모가 먼저인 전위(pre-order)다. 한 노드 안에서는 등록의 역순이고, 형제 사이는 순방향이다. `Clear`는 원소를 역순(e3, e2, e1)으로, `dispose(slot)`과 `:List` KeyGone은 순방향으로 파괴한다(`out-axes.txt` A1~A5).
- 발견 세 갈래는 round13 원장에 반영할 몫이다. 이 폴더에는 근거만 둔다.
