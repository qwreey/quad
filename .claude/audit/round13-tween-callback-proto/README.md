# round13 Tween 콜백 프로토타입 — 모으고→쓰고→부른다 + 콜백 인자 + `Mapped(fn, wrap)`/`Wrapped` + 숏핸드 대표 키 (2026-09-28, mock만)

`research/tween-callback-structure.md` §3·§7·§8·§8-1에서 사용자와 합의한 넷(2026-09-28)을 한 사본에 얹은 프로토타입이다.
격리 worktree(HEAD `1f684ed4`)에서만 고쳤고 원 레포의 `src`·spec·문서는 건드리지 않았다. 실기기 없음 — 엔진 사실이 필요한 판단은 "실기기 전제"로 표시했다.
결정 아님: 채택 여부·문서 문장·에러 번호 배정은 메인·사용자 몫.

## 파일

| 파일 | 뭔가 |
|---|---|
| `proto.diff` | worktree `git diff`(HEAD `1f684ed4` 기준) — src 넷(`Property.luau`·`Tween.luau`·`InstanceShorthand.luau`·`types.luau`), 에러 문서 `docs/reference/errors/08-roblox-tween.md`, spec 넷(`spec.tweenproperty` 12절·`spec.shorthand` 10절·`spec.tween` PROTO 절·`spec.tweentypes` 타입 양성) |
| `probe.cbproto.luau` | 런타임 프로브(절 A~G). `quad-roblox/test/`에 두고 `luau test/probe.cbproto.luau`(relink 뒤) |
| `out-cbproto.txt` | 위 프로브 출력 |
| `out-spikeprobe-proto.txt` | 앞 스파이크 프로브(`round13-tween-callback-structure-spike/probe.cbs.luau`)를 이 사본에서 그대로 돌린 출력 — 스파이크의 `out-v-X-false.txt`(Q99 c 변형)와 비교용 |
| `probe.tweencbtypes.pos.luau` / `.neg.luau` | strict 타입 프로브(양성 8 / 음성 6) |
| `out-types-neg.txt` | 음성 프로브 진단(양성은 진단 0이라 파일 없음) |
| `out-types-valueT-rejected.txt` | 처음 시도한 타입(저장된 Tween 콜백의 `value: T`)이 test.sh에서 낸 진단 — 기각 근거 |
| `lsp.sh` | test.sh 79행 한도 플래그 셋 그대로의 luau-lsp 신 솔버 실행기(첫 줄 `cd` 경로는 worktree — 쓸 때 고칠 것) |

재현: worktree에서 `mise exec -- pesde install` → `patch -p1 < proto.diff` → 프로브 셋을 `quad-roblox/test/`에 복사 →
`./scripts/test.sh; echo $?` → `cd quad-roblox && luau test/probe.cbproto.luau` → `lsp.sh quad-roblox/test/probe.tweencbtypes.pos.luau`(`.neg`도).

## 구현 요지

- **Property**: 앞 스파이크 diff(`settle`/`announce`)를 스위치 없이 고정 — 철거 창은 `Cancelled`(Q99 c), 무장 시점은 오늘 그대로.
  옛 정산 콜백(교체의 옛 `Cancelled`/창 `Completed`, 철거의 `Cancelled`)은 `fireSettled`가 `quad.Backend.isClaimed(inst)`일 때만 부른다(Q82 (a) — Cancel은 그대로).
  모든 발화 자리가 `(inst, k, value)`를 넘긴다: 스냅·교체·철거·plain 경로는 스코프의 `inst`/`k`와 그 레코드의 목표(`v.Value`/`prev.Value`/`slot.Value`),
  엔진 `Completed` 연결은 지금처럼 `rec`·`conn`만 포획하고 발화 때 `rec.Tween.Instance`·`rec.Key`·`rec.Value`를 읽는다. 레코드에 늘어난 필드는
  `Key` 하나(콜백이 있어 연결을 만들 때만 — 콜백 없는 레코드 모양·GC 그대로).
- **Tween**: `Mapped(fn, wrap?)`·`Wrapped(wrap)`. `wrap`은 호출마다 한 번, 얼린 핸들 `cb`(원본 `Started`/`Completed`/`Cancelled` 필드 + `cb:Map(g)`)를 받고,
  돌려준 테이블의 세 필드가 사본의 콜백 셋 전체가 된다(안 채운 필드 = 없음). 값은 `newTween`의 기존 검증(`Quad0246`)을 그대로 받는다. `Mapped(fn, wrap)`은 사본 하나.
  새 raise 자리 셋 — `Quad0256`(wrap이 함수 아님)·`Quad0257`(wrap 반환이 테이블 아님)·`Quad0258`(`cb:Map`의 g가 함수 아님, 과제 밖의 곁 게이트 — 빼도 됨).
  **번호는 이 사본의 `--next` 기준 임시값**이고 에러 문서 절도 사본에만 썼다. blame은 셋 다 사용자 줄(`setFuncLevel`에 `Wrapped`·`Map` 추가).
- **InstanceShorthand**: Tween이면 identity(`UIPadding`/`UIScale`)도 포함해 발행마다 사본 하나(`Wrapped` 또는 `Mapped(entry.wrap, wrap)`)를 네 체인이 공유.
  `wrap`은 `cb:Map`만 쓰므로 숏핸드는 콜백 필드 이름을 모른다. 감싼 콜백은 발화 때 `prop == entry.props[#entry.props]`일 때만 원 콜백을
  `(child.Parent, 숏핸드 키, 사용자가 준 값)`으로 부른다 — 포획은 원 콜백·마지막 키 문자열·숏핸드 키·사용자 값뿐, 인스턴스 없음.
- **types**: `TweenCallback<T> = (inst: Instance, prop: string, value: T) -> ()`. **생성자 옵션(`TweenOptions<T>`)에서만 `value: T`**, 저장된 값
  (`TweenData<T>`)·`wrap`의 핸들(`TweenCallbackHandle`)·돌려줄 셋(`TweenCallbacks`)·`AnimateInfo`는 `value: any`. 이유는 아래 결과 7.

## 결과 (수치의 소스는 out-*.txt)

1. **test.sh exit 0**(스펙 62, doc-coverage 203/203, error-codes 255 ids·0 untagged; doc-check ERROR 0). 기존 spec은 **런타임 단정 하나도 안 깨졌다** —
   `spec.tweenproperty` 11절의 순서 단정(`a:started,a:completed`, 교체 `b:started`, 창 `w:completed,x:started`, 던지는 Cancelled)은 인자가 늘어도 그대로다.
   깨진 것은 **타입 셋**(처음 타입 안 — 결과 7): `spec.shorthandtypes` 33·68행(`UICorner = q.Tween{…}`이 D 슬롯 유니언에 안 들어감), `spec.tween` 115행
   (`FAST:Mapped(...)` 추론 실패 "Type inference failed to complete"). 타입 안을 바꾼 뒤 기존 spec 수정 없이 클린. 추가한 spec 넷은 새 동작 단정용.
2. **패딩 `UIPaddingOffset` 10→101→102→103**(대표 `Completed`에서 잇기): 네 변 **103/103/103/103**, 고아 0, `Started 4 · Completed 4 · Cancelled 0`
   (단계마다 한 번씩), 인자는 매번 `(부모 P, "UIPaddingOffset", 10/101/102/103)`. `UIPadding`(identity, UDim 값)도 같은 수치·인자. 앞 스파이크는
   같은 연쇄가 `103/103/101/101`·`Started 14 · Completed 8 · Cancelled 8`이었다(`out-spikeprobe-proto.txt` 2a 행이 같은 프로브를 이 사본에서 돌린 것 — 이제 103 넷).
3. **네 트윈이 도는 중 동기 새 발행**(대표 `Cancelled`에서 `:Set(77)`, 들어오는 값이 엔진 트윈·`Time = 0`·plain 셋 다): 사용자 콜백 한 번
   (`X:P.UIPaddingOffset=10`), 네 변 모두 77로 도는 트윈 하나씩, 고아 0, State = 77. 통지 창 변형(대표 `Completed`에서 `:Set(77)`)도 같다.
   대표가 마지막 키라 안쪽 재발행 뒤 바깥 숏핸드 루프에 남은 변이 없다 — §7의 "바깥 루프가 옛 값으로 남은 변을 덮는" 문제가 구조적으로 사라졌다.
4. **엔진 완료 통지 순서**(앞→뒤 / 뒤→앞 / 대표 먼저 / 2·4·1·3): 네 순서 모두 결과가 같다(103 넷, 콜백 1회씩, 고아 0). 대표보다 먼저 온 비대표 통지는
   걸러지고, 대표가 먼저 와서 잇는 경우 남은 셋은 창 정산으로 끝나며(`Completed`가 걸러짐) 늦은 통지는 연결이 끊겨 사라진다. **실기기 전제**:
   같은 프레임에 끝나는 트윈들의 `PlaybackState`가 통지보다 먼저 바뀐다는 것(스파이크와 같은 전제, 미실측).
5. **T5**(한 Source를 `Size`·`BackgroundTransparency`에): 시작 `S(F,Size,10) S(F,BackgroundTransparency,10)`, 끝 `C(F,Size,10) C(F,BackgroundTransparency,10)`,
   `Time = 0`은 `S,C`가 자리마다 — 두 번, 각자 다른 `prop`, 값은 그 Tween의 목표. 모든 Property 발화 자리의 인자도 절 A에서 확인(교체의 옛
   `Cancelled`/창 `Completed`는 **옛 목표**를 값으로, 자연 완료는 레코드에서 읽은 값).
6. **`H-589` 재진입 표·Q146 throw**: 앞 스파이크 프로브를 이 사본에서 돌린 출력이 스파이크의 Q99 c 변형(`out-v-X-false.txt`)과 **패딩 행 셋만 빼고 전 행 동일**
   (다른 행: 2a 두 줄 — 위 2, 6절 숏핸드 `Set(nil)` — `A:X` 넷 → 하나). 즉 재진입 전부 고아 0·최종 값 = 마지막 `:Set`, Q146은 스파이크 결론 그대로
   (옛 `Cancelled`/창 `Completed` throw 뒤 새 트윈 재생·기록, 새 `Started`만 유실; throw 뒤 철거가 먼저 오면 그 트윈은 안 끊김 — NOOP 표식).
   남은 잔여도 스파이크와 같다: 첫 쓰기(마운트 중) 스냅 `Started` 안 `:Set`은 State 77·화면 20으로 어긋남(StoreBind 등록 프레임 — 이 변경 밖).
   Q82 (a): 시체 위 `retractFrom`은 도는 중이면 Cancel 1·콜백 0, 창이면 Cancel 0·콜백 0(절 A2).
7. **새 API strict 타입**(luau-lsp 신 솔버, test.sh 한도 플래그 셋): 양성 8 진단 0 — `tween:Wrapped(function(cb) return cb:Map(function(f) return f end) end)`,
   `Wrapped`가 셋을 직접 돌려주는 모양, `Mapped(fn, wrap)`(number → UDim, 결과를 `UICorner.CornerRadius`에), 인자 없는 콜백, 세 인자 콜백(주석·무주석),
   결과가 D 슬롯에 들어감. 음성 6 전부 진단(`value: string`을 number Tween에, 첫 인자 `number`, `prop: number`, wrap이 5를 돌려줌, `Map`의 g가 5를 돌려줌,
   `Mapped`의 wrap이 5). 전체 quad-roblox 분석 시간 HEAD 3.92~3.97s → 사본 3.94~4.00s(차이 없음).
   **발견 — 과제의 타입 모양(`value: T`)을 저장된 Tween에 두면 깨진다**: 콜백 인자는 반대 극성이라 `T`가 `Value`(공변)와 콜백(반공변)에 동시에 서면
   `Tween<T>`가 불변이 되고, D 슬롯 유니언(`TweenData<UDim | number>`)에 `q.Tween{ Value = 12 }`가 안 들어가며 `Mapped`의 제네릭 추론이 실패한다(`out-types-valueT-rejected.txt`).
   `wrap` 핸들을 제네릭(`TweenCallbackHandle<T>`)으로 두면 `Wrapped(function(cb) return cb:Map(...) end)`도 추론이 실패했다. 그래서 정밀한 `T`는 생성자 옵션에만 두었다 —
   `q.Tween{ Value = 90, Completed = function(_, _, v: string) end }`는 잡히지만, 저장 뒤·`wrap` 안에서는 `value: any`다.
   부수 사실: `Mapped(fn)`(wrap 없음)은 콜백을 그대로 복사하므로 **런타임에 콜백이 받는 값은 매핑된 값**이다(number 콜백에 UDim) — `value: T`였다면
   타입이 거짓말을 했을 자리. `any`면 거짓말은 없고 정밀도만 없다.
8. **코드 줄 수**(주석·빈 줄 제외, HEAD → 사본): `Property.luau` 155 → 170(+15), `Tween.luau` 97 → 136(+39 — 핸들·`applyWrap`·`Wrapped`),
   `InstanceShorthand.luau` 71 → 87(+16), `types.luau` 69 → 82(+13). 기존 spec 단정 수정 없음, 새 spec 절 넷(+172줄).

## 채택하면 바뀌는 문서

콜백 셋은 3.2.0 게시 뒤 들어온 `[Unreleased]`라 모양을 바꿔도 BREAKING이 아니다(`Added` 줄 수정 + 새 `Added` 한 줄).

- `docs/reference/roblox/06-tween-animate.md` — `q.Tween` 타입 블록 50~52행(콜백 타입), 84행("인자 없는 함수"·"`:Mapped`로 만든 값에도 그대로"),
  `## tween:Mapped(fn)` 절(시그니처 119행에 `wrap?`, 예시 하나 — 헤딩을 바꾸면 앵커 `#tweenmappedfn`을 가리키는 에러 문서 링크·11행 심볼 목록도),
  **`tween:Wrapped(wrap)` 새 절**, `q.Animate` 타입 블록 171~173행, "프로퍼티에서의 동작" 콜백 표(44~48행 — 인자, "옛 정산 → 새 Started"가 창 안에서도
  성립, 창 교체는 `Completed`·철거는 늘 `Cancelled`, 재진입으로 대체된 값은 `Started` 없이 `Cancelled`, 시체 위 철거 무발화). 50행 파괴 문단은 유지.
- `docs/reference/roblox/02-d.md` 319행 — 숏핸드의 "콜백이 네 번" 캐비엇 → "마지막 키 대표로 한 번, `(부모, 숏핸드 키, 준 값)`".
- `docs/reference/errors/08-roblox-tween.md` — `Quad0246` 고치려면 문장, 새 절 `Quad0256`~`0258`(사본에 초안 — 번호는 채택 때 `--next`로 다시).
- `.claude/base/tween-plan.md` 688행 콜백 절(695행 "전부 `() -> ()`, 인자 없음", 702~708행 발화 목록·순서 불변식, 726행 재진입 UB 문단 — Property 층은
  이제 순서대로 한 트윈), 594행 `Mapped` 절(`wrap`, `Wrapped`), 568행 E24 배너 블록. `.claude/base/ui-shorthand-plan.md` 242~246행(`v:Mapped(wrap)` 서술 —
  identity도 사본), 272~275행(`H-630` 네 배·Q92 문항).
- `docs/getting-started/17-animation.md` 54~79행 — "인자 없는 콜백 셋"(56행), 규칙 셋·교체 순서(79행). 예제 코드는 인자 없는 함수라 그대로 돈다.
- how-to — `docs/how-to/`에는 콜백 사용처가 없다(grep 0).
- `docs/skills/quad-ui-dev/SKILL.md` 406~438행 — "always `() -> ()` — no Instance is passed"(415행), 재진입 금지 문장(432행), 순서 문장.
- `CHANGELOG.md` 13행 `Added` 문장(인자 없음 → `(inst, prop, value)`, 창 교체·철거 규칙, 숏핸드 한 번) + 새 `Added` 한 줄(`tween:Mapped(fn, wrap)`·`tween:Wrapped(wrap)`).
  `docs/site/` 사본은 `sync-docs.py`가 만든다. `docs/README.md` 65행(GS 17 요약)은 필요하면.
- 코드 주석: `Property.luau` 머리 콜백 문단(사본에서 다시 씀), `Tween.luau` 머리 Value API, `InstanceShorthand.luau` 머리("Tween 값은 `:Mapped(wrap)`").

## 남는 것·주의

- **숏핸드 identity 경로가 발행마다 사본을 만든다**(예전엔 Tween을 그대로 넘겼다 — "2차 리뷰" 최적화의 역전). 콜백이 없어도 만든다 — 숏핸드가 콜백 필드 이름을
  모르게 하려는 대가. 비용은 `table.clone` + 재검증 + freeze + 작은 클로저 하나(콜백 있으면 감싼 클로저 최대 셋). 값 dedup은 목표 `Value` 비교라 영향 없음.
- 네 체인이 모두 감싼 콜백을 들고 있어 엔진 연결은 여전히 넷(예전과 같은 수). 비대표 셋의 발화는 필터에서 버려진다.
- 재진입으로 대체된 새 값은 `Started` 없이 `Cancelled`를 받는다(스파이크의 관측 그대로 — 숏핸드에서는 대표 키 기준으로 한 번).
- Q82 게이트는 철거뿐 아니라 교체 경로의 옛 정산 콜백에도 걸린다(시체에 직접 `Dispatch.process`하면 옛 `Cancelled`는 안 오고 새 `Started`는 온다 — 드문 경로).
- 사용자가 `Mapped(fn)`(wrap 없이)으로 만든 사본을 여러 프로퍼티에 걸면 콜백은 자리마다 한 번, 각자 `prop`으로 온다 — "자리마다 한 번, 이름 붙은 사건"(§8 정의).
- 실기기 전제: 엔진 `Tween.Instance` 읽기(연결 발화 때), `PlaybackState`가 통지보다 먼저 바뀜(창), 실 엔진 트윈이 대상 인스턴스를 Lua 그래프에서 잡지 않음
  (mock은 약하게 잡는다 — 절 G의 "Destroy 뒤 수거"는 mock 기준; 파괴 전에는 claim이 잡고 있어 콜백 유무와 무관하게 살아 있다).
