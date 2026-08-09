# [기각됨] `OnChange.PropertyName` 프로퍼티별 정적 코드 생성

**기각 일시**: 2026-08-10. **현재 유효한 설계**: `base/onchange-plan.md` —
`OnChange(name)` 제네릭 없는 단일 팩토리, 콜백 파라미터 타입은 호출부가
직접 명시.

## 무엇이었나

`Attribute`가 `[Attribute<<T>> "name"]`(제네릭 경로)과 `[BooleanAttribute
"name"]`(자주 쓰는 타입만 정적 지름길)을 둘 다 채택했던 것(`base/
attribute-plan.md`)과 같은 모양으로, `OnChange`도 `OnChange.Position`/
`OnChange.Size`처럼 프로퍼티 이름별로 이미 타입이 박힌 정적 필드를 코드
생성기로 전부 만들어두는 안이 검토됐음.

## 기각 이유

Attribute의 정적 지름길과 겉보기엔 같은 절충처럼 보이지만 실제로는 규모가
다른 문제:

- Attribute의 타입 파라미터 `T`는 Roblox Attribute가 지원하는 좁고 고정된
  프리미티브 집합(string/boolean/number/Color3/UDim/UDim2/Vector2/Vector3/
  CFrame/Instance 등, ~10종)에서만 옴 — 정적 지름길 후보가 유한하고 작음.
- `OnChange`가 감쌀 수 있는 프로퍼티는 **클래스마다 이름/타입 집합이 전부
  다름** — `Frame.Position`, `TextLabel.Text`, `ScrollingFrame.CanvasSize`
  등 클래스 종류만큼 프로퍼티 집합이 갈라지므로, "자주 쓰는 것만 정적
  지름길"이 성립하려면 사실상 (클래스 수 × 프로퍼티 수) 규모의 조합을
  전부 커버해야 함 — 유한한 지름길 목록으로 수렴하지 않음.
- 지름길을 특정 클래스 몇 개(Frame 등)로만 좁혀도, 그 클래스의 `OnChange`
  네임스페이스가 실제로 그 클래스에서만 유효한 프로퍼티인지 타입 레벨에서
  강제할 방법이 마땅치 않음 — 결국 반쯤 타입 안전한 것처럼 보이는 인터페이스만
  남고 실제 검증은 여전히 없음.

## 대안(채택됨)

콜백 파라미터 타입을 호출부가 직접 명시하는 것으로 충분 — 이미 이벤트
바인딩(`Frame { MouseButton1Click = fn }`)이 콜백 시그니처 검증을 포기하는
것과 같은 급의 트레이드오프를 받아들이는 것뿐, `OnChange`만 유별나게 정적
타입 안전성을 추구할 근거가 약함.
