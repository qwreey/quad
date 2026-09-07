#!/usr/bin/env python3
"""gen-d.py — `quad-roblox/src/D/init.luau` 코드 생성기 (M5 단위 ②).

두 단계(round14 Q5 (a) — 덤프를 재사용 가능한 형태로 남긴다):
  normalize <raw-API-Dump.json> <clientVersionUpload>
      → quad-roblox/dump/api-surface.json  (커밋되는 정규화 산출물 —
        M7 단위 ③·④가 같은 emit()을 확장해 <Class>Modifier 타입도 여기서 생성,
        Parent 제외는 여기 덤프 층)
  emit
      → quad-roblox/src/D/init.luau        (커밋되는 최종 산출물)

raw 덤프 취득(재생성 때만 네트워크 필요 — 테스트 경로 의존 아님):
  VER=$(curl -s https://clientsettings.roblox.com/v2/client-version/WindowsStudio64 \
        | python3 -c "import json,sys;print(json.load(sys.stdin)['clientVersionUpload'])")
  curl -s -o /tmp/API-Dump.json "https://setup.rbxcdn.com/$VER-API-Dump.json"
  python3 scripts/gen-d.py normalize /tmp/API-Dump.json "$VER"
  python3 scripts/gen-d.py emit

결정의 소스(전부 round14 §4 확정):
  H-295 (a) JSON API Dump 주 소스 + 유한 타입명 매핑
  H-296 (a) 범위 = creatable ∧ (GuiObject∪UIComponent∪LayerCollector 하위)
            + 명시 화이트리스트 {Folder, Camera, WorldModel}
  H-297 (a) ReadOnly/Deprecated/NotScriptable/Hidden/보안≠None 프로퍼티 제외
  H-298 (a)+H-326 스칼라 = T | TweenData<T> | StateMarker<T | Tween<T>> | None(2026-09-07 마커),
            이벤트 = 콜백 | StateMarker<콜백> | None, children = NewChild(types.luau) — None 표현은
            H-300 (a)로 확정(센티널 마커 필드 → QuadTypes.None)
  H-142     Parent는 덤프 층에서 제외(Q5 (a) — M7 목록과 공유되는 자리)
드롭된 항목은 전부 normalized의 dropped에 남긴다 — 조용한 절단 금지.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SURFACE = ROOT / "quad-roblox" / "dump" / "api-surface.json"
OUT = ROOT / "quad-roblox" / "src" / "D" / "init.luau"

SCOPE_ROOTS = ("GuiObject", "UIComponent", "LayerCollector")
SCOPE_EXTRA = {"Folder", "Camera", "WorldModel"}  # H-296 (a) 화이트리스트(vide 반례)
# H-301(실측 보강): 클래스 수준 제외 — Deprecated(GuiMain)·NotBrowsable(내부 UI)·
# MemoryCategory Internal(AdGui)은 사용자 표면이 아니고, RelativeGui는 태그론 안
# 드러나지만 Studio 실측에서 RobloxScript capability 없이 생성 불가였다
CLASS_TAG_EXCLUDE = {"Deprecated", "NotBrowsable"}
CLASS_DENY = {"RelativeGui"}  # 실측: lacking capability RobloxScript
PROP_TAG_EXCLUDE = {"ReadOnly", "Deprecated", "NotScriptable", "Hidden"}
EVENT_TAG_EXCLUDE = {"Deprecated", "Hidden"}
PRIMITIVES = {
    "int": "number", "int64": "number", "float": "number", "double": "number",
    "bool": "boolean", "string": "string",
}
# DataType 중 이름 그대로가 아닌 것/버리는 것만 여기 — 나머지는 defs의 같은 이름
# [2026-09-07 7순회 H-420] `ContentId` → `Content`는 틀렸다: 핀 defs 4행은 `type ContentId = string`
# (문자열 별칭)이고 `Content`는 ImageContent용 별개 userdata 클래스라, 생성 D의 Image/Video/
# CursorIcon 슬롯 10개가 엔진이 받는 유일한 값(asset id 문자열)을 거부했다. 문자열 별칭은
# defs에서 읽어 `string`으로 — QDir/QFont/BinaryString/ProtectedString도 같은 규칙(SKIP 해제).
DATATYPE_RENAME = {"OptionalCoordinateFrame": "CFrame"}
DATATYPE_SKIP = {"SystemAddress"}
_STRING_ALIASES = None


def string_aliases():
    """defs의 `type X = string` 별칭 집합 — DataType 이름이 여기 있으면 Luau 타입은 `string`."""
    global _STRING_ALIASES
    if _STRING_ALIASES is None:
        _STRING_ALIASES = set(re.findall(r"^type (\w+) = string$", DEFS.read_text(), re.M))
    return _STRING_ALIASES

RESERVED = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
    "true", "until", "while",
}


def load_classes(raw):
    return {c["Name"]: c for c in raw["Classes"]}


def is_desc(classes, name, root):
    while name in classes:
        if name == root:
            return True
        name = classes[name].get("Superclass")
    return False


def map_type(vt, dropped, ctx):
    cat, name = vt["Category"], vt["Name"]
    if cat == "Primitive":
        if name in PRIMITIVES:
            return PRIMITIVES[name]
    elif cat == "DataType":
        if name in DATATYPE_SKIP:
            dropped.append(f"{ctx}: DataType {name} (skip-listed)")
            return None
        if name in string_aliases():
            return "string"  # H-420
        return DATATYPE_RENAME.get(name, name)
    elif cat == "Enum":
        return f"Enum.{name}"
    elif cat == "Class":
        return name
    elif cat == "Group" and name == "Array":
        # 덤프가 요소 타입을 안 실음(Touch* 이벤트의 touchPositions 등) —
        # 거짓 정밀도 대신 { any }로 받아 이벤트 자체는 살린다
        return "{ any }"
    dropped.append(f"{ctx}: unmapped {cat}/{name}")
    return None


def defs_knows(defs_text, luau_type):
    if luau_type in ("number", "boolean", "string", "{ any }"):
        return True
    if luau_type.startswith("Enum."):
        # [2026-09-07 H-359] precise form only — the old `"<Name>:" in defs_text` substring
        # matched any FIELD named like the enum (e.g. `Style: Enum.FrameStyle`) and let an
        # enum newer than the pinned defs through the gate (silent-truncation contract broken
        # the other way: an undeclared type in the emitted D fails the whole module)
        return f"declare extern type Enum{luau_type.split('.', 1)[1]} extends EnumItem" in defs_text
    return f"declare extern type {luau_type} " in defs_text or f"declare extern type {luau_type}<" in defs_text


def chain_members(classes, name):
    """(owner, member) up the superclass chain — owner is the LOWEST class that
    declares the member (M7 단위 ④: 상위 클래스 Modifier 타입이 소유 클래스별
    프로퍼티를 알아야 한다)."""
    seen = set()
    node = name
    while node in classes:
        for m in classes[node]["Members"]:
            key = (m["MemberType"], m["Name"])
            if key in seen:
                continue  # 하위 클래스의 오버라이드가 이김
            seen.add(key)
            yield node, m
        node = classes[node].get("Superclass")


def class_chain(classes, name):
    """[name, parent, …, Instance] — `Object`(덤프의 루트)는 뺀다."""
    out = []
    node = name
    while node in classes and node != "Object":
        out.append(node)
        node = classes[node].get("Superclass")
    return out


DEFS = ROOT / "scripts" / "roblox-defs" / "globalTypes.d.luau"


def normalize(raw_path, version):
    raw = json.loads(Path(raw_path).read_text())
    classes = load_classes(raw)
    # 핀 고정 defs보다 새로운 API는 타입을 못 쓴다 — defs에 이름이 없으면
    # 떨어뜨리고 dropped에 남긴다(defs를 올리면 자동 복귀)
    defs_text = DEFS.read_text()
    dropped = []
    surface = {}
    for name, c in sorted(classes.items()):
        tags = set(c.get("Tags") or [])
        if "NotCreatable" in tags or "Service" in tags:
            continue
        if not (name in SCOPE_EXTRA or any(is_desc(classes, name, r) for r in SCOPE_ROOTS)):
            continue
        if tags & CLASS_TAG_EXCLUDE or c.get("MemoryCategory") == "Internal" or name in CLASS_DENY:
            dropped.append(f"{name}: class excluded (H-301 — deprecated/internal/capability-gated)")
            continue
        if f"declare extern type {name} " not in defs_text:
            dropped.append(f"{name}: class newer than pinned defs (whole class dropped)")
            continue
        props, events, read_props = [], [], []
        for owner, m in chain_members(classes, name):
            mtags = set(m.get("Tags") or [])
            if m["MemberType"] == "Property":
                # [7순회] 멤버 단위 제외도 dropped에 남긴다(파일 머리 "조용한 절단 금지") —
                # `D.TextLabel { Font = … }`가 왜 없는지 추적 가능해야 한다
                if m["Name"] == "Parent":
                    dropped.append(f"{name}.Parent: excluded by design (H-142, Q5 (a))")
                    continue
                # [round1 Q19 (a), 2026-09-07] ReadOnly props (AbsoluteSize/AbsolutePosition/TextBounds…)
                # are not in the WRITE surface but ARE the main OnChange targets — they go to a
                # separate READ list that only the OnChange typing consumes (`PropTypesRead`,
                # `<Class>OnChange`). Other excluded tags (Deprecated/NotScriptable/Hidden) still drop.
                other_excluded = mtags & (PROP_TAG_EXCLUDE - {"ReadOnly"})
                read_only = "ReadOnly" in mtags and not other_excluded
                if other_excluded:
                    dropped.append(f"{name}.{m['Name']}: tags {sorted(mtags & PROP_TAG_EXCLUDE)}")
                    continue
                sec = m.get("Security") or {}
                if sec.get("Read") != "None" or (not read_only and sec.get("Write") != "None"):
                    dropped.append(f"{name}.{m['Name']}: security {sec}")
                    continue
                t = map_type(m["ValueType"], dropped, f"{name}.{m['Name']}")
                if t is not None and not defs_knows(defs_text, t):
                    dropped.append(f"{name}.{m['Name']}: type {t} newer than pinned defs")
                    t = None
                if t is not None:
                    (read_props if read_only else props).append({"name": m["Name"], "type": t, "owner": owner})
            elif m["MemberType"] == "Event":
                if mtags & EVENT_TAG_EXCLUDE:
                    continue
                if m.get("Security") != "None":
                    continue
                params, ok = [], True
                for p in m.get("Parameters") or []:
                    t = map_type(p["Type"], dropped, f"{name}.{m['Name']}({p['Name']})")
                    if t is not None and not defs_knows(defs_text, t):
                        dropped.append(f"{name}.{m['Name']}({p['Name']}): type {t} newer than pinned defs")
                        t = None
                    if t is None:
                        ok = False
                        break
                    pname = p["Name"]
                    if pname in RESERVED or not pname.isidentifier():
                        pname = "_" + pname
                    params.append({"name": pname, "type": t})
                if ok:
                    events.append({"name": m["Name"], "params": params, "owner": owner})
        props.sort(key=lambda p: p["name"])
        read_props.sort(key=lambda p: p["name"])
        events.sort(key=lambda e: e["name"])
        # chain: 상위 클래스 Modifier 타입(M7 단위 ④)의 재료 — 조상 자체는 스코프
        # 밖(비생성)이라 별도 항목이 없고, 프로퍼티는 하위의 owner로 되짚는다
        surface[name] = {"props": props, "readProps": read_props, "events": events, "chain": class_chain(classes, name)[1:]}
    out = {
        "dumpVersion": version,
        "apiVersion": raw.get("Version"),
        "scopeRule": "creatable AND (GuiObject|UIComponent|LayerCollector descendant) OR {Folder,Camera,WorldModel} (H-296 a)",
        "classes": surface,
        "dropped": sorted(set(dropped)),
    }
    SURFACE.parent.mkdir(parents=True, exist_ok=True)
    SURFACE.write_text(json.dumps(out, indent=1, sort_keys=True) + "\n")
    print(f"normalize: {len(surface)} classes, {len(out['dropped'])} dropped notes -> {SURFACE}")


def luau_event_sig(ev):
    args = ", ".join(f"{p['name']}: {p['type']}" for p in ev["params"])
    return f"({args}) -> ()"


def emit():
    data = json.loads(SURFACE.read_text())
    classes = data["classes"]
    L = []
    L.append("--!strict")
    L.append("--[[")
    L.append("\tGENERATED FILE — do not edit by hand. `scripts/gen-d.py` (M5 단위 ②).")
    L.append(f"\tdump: {data['dumpVersion']} (API {data['apiVersion']}); 재생성 방법은 생성기 헤더.")
    L.append("\t표면 계약: bind-system-plan.md 인스턴스 생성 절(New 커링·①~④ 파이프라인·")
    L.append("\tD는 캐스트 별칭·Parent 제외 H-142), claim-plan §7-12(<Class>Param<E> 공유),")
    L.append("\tround14 H-295~H-298·H-300. 유니언: 스칼라 T | TweenData<T> | StateMarker<T | Tween<T>> | None")
    L.append("\t(H-326 → 2026-09-07 마커: State 팔은 공변 StateMarker 하나, typing-limits 8.11),")
    L.append("\t이벤트 콜백 | StateMarker<콜백> | None (None 표현은 H-300 (a) — QuadTypes.None).")
    L.append("\t이벤트 필드의 런타임 핸들러는 Handlers/Event.luau(M10, 2026-09-03 구현됨 —")
    L.append("\t`base/event-plan.md`); M5엔 타입이 먼저 왔다(ROADMAP M5 체크박스의 계약).")
    L.append("\tOnChange(M10, 2026-09-03 역전 — base/onchange-plan.md): 배열부 디스크립터.")
    L.append("\tPropTypes(스코프 전체 프로퍼티 이름 → 타입, 클래스 간 충돌 이름은 any) +")
    L.append("\tOnChangeFn(`K & keyof<PropTypesRead>` / `index<PropTypesRead, K>` — 읽기 표면(Q19); 이름 오타·콜백")
    L.append("\t타입·무주석 추론까지, luau-test 30) + 클래스별 <Class>OnChange 유니언이 E에")
    L.append("\t합류(클래스 밖 이름은 생성자 자리에서 거부).")
    L.append("\tModifier(M7 단위 ③, round17): 클래스별 <Class>Modifier(필드 setter — 값은")
    L.append("\tField<T> = T | Tween<T> | StateMarker<T | Tween<T>> | None | 변환 함수(H-327 → 마커), 자기 타입 반환; 예약 메소드")
    L.append("\tApply/Peek/Overridden; 이벤트는 제외 — 함수 인자는 변환 함수라 콜백과 겹친다)")
    L.append("\t+ D.Modifier.<Class>() 타입드 생성자(round17 Q3 (a) — 단위 ③엔 quad.Modifier 캐스트 별칭,")
    L.append("\t단위 ④부터 아래 TypedFactory 태그 생성자)")
    L.append("\t+ children엔 마커만(<Class>Modifier를 유니언에 직접 넣으면 큰 클래스에서 too complex —")
    L.append("\ttyping-limits 8.8절): 무타입 base는 `{ read __quadModifier: true }`(NewChild, types.luau),")
    L.append("\t클래스 태그는 조상 체인 마커 `{ read __quadModifier: \"Frame\" | \"GuiObject\" | … }`(<Class>Elem).")
    L.append("\t단위 ④(2026-09-04, 사용자 설계 — modifier-plan 11절): 상위 클래스 Modifier 타입도 전부")
    L.append("\t생성(스코프 클래스의 조상 전부 — GuiObjectModifier류; 개수는 이 파일의 <Class>Modifier 선언이")
    L.append("\t소스), 검사형 하강 `As<Class>()`(하위 클래스 + 항등),")
    L.append("\t무검사 `As<<T>>()`, 인터페이스 `Into<Class> = { As<Class>: (self: any) -> <Class>Modifier }`,")
    L.append("\tApply는 self·factory 둘 다 any(8.9절 — 재귀 필드 + 유니언 멤버 메소드 이름 충돌 시")
    L.append("\t유니언 검사가 조용히 통과하는 솔버 결함을 피해 클래스 소속 검사를 되찾음). 런타임은")
    L.append("\tquad.Modifier.TypedFactory(name)이 돌려주는 태그 생성자 + DefineSubtype(parent, name) 간선.")
    L.append("\tRef/PreRef/PostRef(M8 단위 ③, round18 H-321 — 사용자 확정): children엔 클래스별 반공변")
    L.append("\t팬텀 마커 <Class>RefMarker = { read __quadRefAccepts: (<Class>) -> () }(+ State<…>)만 — Ref<T>를")
    L.append("\t직접 넣으면 8.9절 결함으로 형제 클래스 Ref가 샌다(실측). Ref<<Class>?>·상위 박스 통과, 형제·Ref<nil> 거부.")
    L.append("]]")
    L.append("")
    L.append('local QuadTypes = require("../luau_packages/quad_types")')
    L.append('local Types = require("./types")')
    L.append("")
    L.append("type State<T> = QuadTypes.State<T>")
    L.append("type StateMarker<T> = QuadTypes.StateMarker<T> -- 입력 자리의 State 팔(2026-09-07 마커, typing-limits 8.11)")
    L.append("type Tween<T> = Types.Tween<T>")
    L.append("type TweenData<T> = Types.TweenData<T> -- 유니언 멤버용 데이터부(H-326, 8.8절)")
    L.append("type NewChild = Types.NewChild")
    L.append("type None = QuadTypes.None")
    L.append("type MapperDescriptor = QuadTypes.MapperDescriptor")
    L.append("type MapperRoot = QuadTypes.MapperRoot")
    L.append("-- Modifier 필드 setter의 값 타입(modifier-plan 4·4-1·10절): 리터럴 T | Tween<T> |")
    L.append("-- State(마커, T | Tween<T>를 품음) | None(unsetter) | 변환 함수(old는 '현재 저장된 그대로').")
    L.append("-- [2026-09-07 마커] 옛 `State<T> | State<Tween<T>>` 두 팔(H-327 — State 불변성)은 공변 마커")
    L.append("-- `StateMarker<T | Tween<T>>` 하나로; old(출력)만 전체형 `FieldOut<T>`(State 팔 하나 — Q23 (a) 사용자 확정).")
    # [2026-09-06 M11 단위 ① H-327] 옛 Field<V>에 V = T | Tween<T>를 넣던 모양은 새 솔버의
    # State 불변성 때문에 State<T>를 거부했다(M7 하자 — m:Position(state)가 strict에서
    # 막힘, 실측). 프로퍼티 setter의 값 타입은 T와 Tween<T>의 State 형을 각각 나열한다.
    # setter 쪽은 전체형 Tween<T>(Mapped 포함): 함수 멤버가 든 이 유니언에서 데이터부
    # TweenData<T>는 교집합 Tween 값을 받지 못했다(2026-09-06 실측 — Param 슬롯의 리터럴
    # 자리와 달리 호출 인자 자리). Modifier 타입은 클래스별이라 복잡도 문제도 없다.
    # (옛 규칙 "값/함수 인자/함수 반환 셋이 같은 유니언 — 별칭 하나로"는 마커로 깨졌다: 입력 둘은
    # FieldV, 출력 old는 FieldOut — round3 H-432/Q23)
    # [2026-09-07 마커] 입력 팔은 StateMarker 하나(공변 — State<T>·State<Tween<T>>·정직한
    # State<T | Tween<T>>·유니언 T의 멤버 State 전부, 스파이크 35). 변환 함수의 old는 출력이라
    # 전체형(FieldOut) — 사용자가 old:Get()을 부를 수 있게. 값 팔 Tween<T>는 그대로 전체형.
    L.append("export type FieldV<T> = T | Tween<T> | StateMarker<T | Tween<T>> | None")
    L.append("export type FieldOut<T> = QuadTypes.FieldOut<T> -- 변환 함수 old·Peek 반환(출력, 전체형 — 정의는 quad-types, Q23 (a)/Q24 후속)")
    L.append("export type Field<T> = FieldV<T> | ((old: FieldOut<T>?) -> FieldV<T>?)")
    L.append("")
    names = sorted(classes.keys())
    # [2026-09-06 M11 단위 ① H-326] + State<Tween<T>> — tween-plan "타입 대수"의
    # T' = T | Tween<T> 확장(Animate가 State<Tween<T>>를 돌려준다). 새 솔버는
    # State<T>가 불변이라 State<T | Tween<T>> 하나로는 State<T>를 못 받는다(실측).
    # 프로퍼티 값 유니언은 타입별 별칭 하나로(PVn) — 같은 유니언을 수백 자리에
    # 인라인하면 State<Tween<T>>가 더해진 뒤 DMapper 인스턴스화에서 "too complex"
    # (Tarjan 640000·다른 한도 플래그로도 안 풀림, 실측). State 안은 전체형 Tween<T>:
    # State<X>는 불변이라 Animate/`:Compute`가 돌려주는 State<Tween<T>>와 X가 글자
    # 그대로 같아야 들어간다(데이터부·정밀판 별칭은 거부). 바깥은 데이터부(8.8절).
    # [round20 H-336] UI 편의 숏핸드 키 넷(ui-shorthand-plan "메커니즘"·"결론" 절) — GuiObject
    # 계열(자기 또는 조상에 GuiObject)의 Param과 Modifier setter에만 얹는다. 런타임은
    # Handlers/InstanceShorthand.luau(우선순위 NORMAL+1). PropTypes/OnChange엔 넣지 않는다
    # (실프로퍼티가 아니라 GetPropertyChangedSignal 대상이 아님).
    SHORTHAND = [("UICorner", "number | UDim"), ("UIPadding", "UDim"), ("UIPaddingOffset", "number"), ("UIScale", "number")]
    # [post-implementation review Q3 ⑦, 2026-09-07] the KEY set is gated against the runtime
    # table (`Handlers/InstanceShorthand.luau` `TABLE`) — the types stay here (the runtime keeps
    # `wrap` functions, not type strings), but a key added/renamed on one side only fails generation
    # instead of drifting silently (file-head rule: no silent truncation).
    sh_src = (ROOT / "quad-roblox" / "src" / "Handlers" / "InstanceShorthand.luau").read_text()
    sh_blk = re.search(r"^local TABLE\b[^\n]*=\s*\{\n(.*?)^\}", sh_src, re.S | re.M)
    if not sh_blk:
        raise SystemExit("gate: could not find `local TABLE = {` in Handlers/InstanceShorthand.luau")
    sh_keys = set(re.findall(r"^\t([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{", sh_blk.group(1), re.M))
    if sh_keys != {s for s, _ in SHORTHAND}:
        raise SystemExit(f"gate: SHORTHAND keys {sorted(s for s, _ in SHORTHAND)} != InstanceShorthand.luau TABLE keys {sorted(sh_keys)}")
    # [7순회 H-424] `parent_of` itself is a free variable of `ancestors` — it was assembled
    # ~90 lines later, so H-412's move only shifted the same latent NameError one step
    parent_of = {}
    for name in names:
        chain = [name] + classes[name]["chain"]
        for i, node in enumerate(chain):
            parent_of[node] = chain[i + 1] if i + 1 < len(chain) else None
    # [6순회 H-412] bound BEFORE is_gui_object (which closes over it) — it used to be defined
    # ~90 lines later and the earlier call only survived because `node in classes` was always true
    def ancestors(node):
        out = []
        node = parent_of.get(node)
        while node:
            out.append(node)
            node = parent_of.get(node)
        return out

    def is_gui_object(node):
        return node == "GuiObject" or "GuiObject" in ((classes[node]["chain"] if node in classes else ancestors(node)))
    prop_types = []
    for name in names:
        for p in classes[name]["props"]:
            if p["type"] not in prop_types:
                prop_types.append(p["type"])
    for _, t in SHORTHAND:
        if t not in prop_types:
            prop_types.append(t)
    def union_members(t):
        return [m.strip() for m in t.split("|")]
    # [2026-09-07 마커 — 사용자 결정] 슬롯 값 유니언은 `T | TweenData<T> | StateMarker<T | Tween<T>> | None`
    # 한 벌. 옛 모양(`State<T> | State<Tween<T>>` + 유니언 T의 멤버별 팔 — H-353/H-362/H-363, PV73이
    # 11팔)은 State 불변성(H-326/H-327)의 우회였고, 공변 마커는 `State<m>`·`State<Tween<m>>`·정직한
    # `State<T | Tween<T>>`(H-334가 "too complex"로 포기한 팔)를 전부 한 팔로 받는다(스파이크 35).
    # 바깥 값 팔은 데이터부 TweenData(8.8), 마커 안은 전체형 Tween(State<Tween<T>>의 필드형 그대로).
    # H-362의 SHF(숏핸드 setter 멤버별 값 팔) 별칭도 같이 사라진다 — Field<number | UDim> 하나로 충분.
    def pv_arms(t):
        return [t, f"TweenData<{t}>", f"StateMarker<{t} | Tween<{t}>>", "None"]
    pv_name = {}
    for i, t in enumerate(prop_types):
        pv_name[t] = f"PV{i}"
        L.append(f"type PV{i} = {' | '.join(pv_arms(t))} -- {t}")
    L.append("")
    for name in names:
        c = classes[name]
        L.append(f"export type {name}Param<E> = {{")
        L.append("\t[number]: E,")
        for p in c["props"]:
            t = p["type"]
            L.append(f"\t{p['name']}: {pv_name[t]}?,")
        if is_gui_object(name):
            for sname, t in SHORTHAND:
                L.append(f"\t{sname}: {pv_name[t]}?, -- 숏핸드(H-336)")
        for ev in c["events"]:
            sig = luau_event_sig(ev)
            L.append(f"\t{ev['name']}: (({sig}) | StateMarker<{sig}> | None)?,")
        L.append("}")
        L.append("")
    # OnChange 타이핑(onchange-plan 2026-09-03 역전, luau-test 30 실측):
    #  - PropTypes: 스코프 전체 (이름 → 타입). 같은 이름이 클래스마다 다른
    #    타입이면 `any`(index<>가 유니언을 주면 주석 콜백이 반공변으로 거부됨 —
    #    실측 6건: Style/CanvasSize/Color/Offset/Transparency/Padding).
    #  - 이름 싱글톤 유니언을 `K &`로 직접 교차하면 "too complex"(실측) —
    #    `keyof<PropTypes>`는 같은 유니언이지만 index<>와 짝일 때만 통과했다.
    prop_types = {}
    for name in names:
        for p in classes[name]["props"]:
            prop_types.setdefault(p["name"], set()).add(p["type"])
    def emit_prop_map(tname, mapping, comment):
        L.append(f"-- {comment}")
        L.append(f"export type {tname} = {{")
        for pname in sorted(mapping):
            ts = sorted(mapping[pname])
            L.append(f"\t{pname}: {ts[0] if len(ts) == 1 else 'any'},")
        L.append("}")
    emit_prop_map("PropTypes", prop_types, "PropTypes(D 스코프 전체 쓰기 프로퍼티 이름 → 타입; 클래스 간 충돌은 any)")
    # [round1 Q19 (a), 2026-09-07] the READ surface (write props + ReadOnly props) — OnChange's
    # name/callback typing only; `OnChange("AbsoluteSize", fn)` used to be a strict TypeError (H-414)
    read_types = {k: set(v) for k, v in prop_types.items()}
    for name in names:
        for p in classes[name].get("readProps", []):
            read_types.setdefault(p["name"], set()).add(p["type"])
    emit_prop_map("PropTypesRead", read_types, "OnChange — PropTypesRead(쓰기 표면 + ReadOnly 프로퍼티; AbsoluteSize/AbsolutePosition/TextBounds…, Q19)")
    L.append("export type OnChangeDescriptor<K> = { Name: K, Callback: (index<PropTypesRead, K>) -> () }")
    L.append("export type OnChangeFn = <K>(name: K & keyof<PropTypesRead>, fn: (index<PropTypesRead, K>) -> ()) -> OnChangeDescriptor<K>")
    L.append("")
    # ── 클래스 계층(M7 단위 ④) ──────────────────────────────────────────
    # 조상(비생성 추상 클래스)도 Modifier 타입을 갖는다 — 프로퍼티는 스코프 하위
    # 클래스들의 owner 필드로 되짚는다(surface `chain`/`owner`, normalize가 기록).
    mod_classes = sorted(parent_of)  # 스코프 + 조상 (parent_of는 위 H-412 자리에서 조립)

    def descendants(node):
        return sorted(m for m in mod_classes if m != node and node in ancestors(m))

    def mod_props(node):
        if node in classes:
            return classes[node]["props"]
        above = set(ancestors(node)) | {node}
        acc = {}
        for n in names:
            if node in ancestors(n):
                for p in classes[n]["props"]:
                    if p["owner"] in above:
                        acc[p["name"]] = p
        return [acc[k] for k in sorted(acc)]

    # ── 생성기 게이트(단위 ④) — 조용한 구멍 금지 ────────────────────────
    # (1) `As` + 대문자 프로퍼티는 런타임 캐스트 접두와 충돌 → 생성 실패.
    # (2) children 유니언 멤버(Instance·State·Tag·Attribute·OnChange 디스크립터)의
    #     함수 필드와 같은 이름의 setter는 typing-limits 8.9절의 솔버 결함(재귀
    #     필드 + 같은 이름 함수 필드 → 유니언 검사가 조용히 통과)을 다시 연다 →
    #     생성 실패. 이름 집합은 defs(Instance/Object의 function 멤버)와 quad-types
    #     소스(State/StateData/Tag/Attribute 블록의 키)에서 읽는다.
    defs_text = DEFS.read_text()
    # OnChangeDescriptor's function fields (`Callback`) — read from quad-roblox `types.luau`, not
    # hand-copied (Q3 ⑦); `type_body`/`function_fields` are defined below, so this is resolved there
    union_member_functions = set()
    # defs: `declare extern type Instance extends Object with` / `declare extern type Object with`
    # — 못 찾으면 게이트가 조용히 비는 대신 생성을 실패시킨다(리뷰 반영)
    for cls in ("Instance", "Object"):
        blk = re.search(rf"^declare extern type {cls}\b[^\n]*\n(.*?)^end", defs_text, re.S | re.M)
        if not blk:
            raise SystemExit(f"gate: could not find `declare extern type {cls}` in {DEFS}")
        union_member_functions |= set(re.findall(r"^\s+function ([A-Za-z_]+)", blk.group(1), re.M))
    # [4순회 H-388] comments are stripped ONCE, before both scanners: `type_body`'s brace balance
    # and `function_fields`' depth-0 scan must see the same text (a brace or paren inside a
    # comment silently shifted the harvest). One alternation — a block comment wins where it
    # starts, a line comment swallows a `--[[` that follows it on the same line.
    def strip_comments(text):
        return re.sub(r"--\[\[.*?\]\]|--[^\n]*", "", text, flags=re.S)
    qt = strip_comments((ROOT / "quad-types" / "src" / "init.luau").read_text())  # one regex for every scanner (round3 H-438)
    rt = strip_comments((ROOT / "quad-roblox" / "src" / "types.luau").read_text())

    def type_body(tname, text=qt, where="quad-types"):
        # `export type X = ... {` 뒤 중괄호 균형으로 본문을 끊는다 — 한 줄 선언
        # (`Attribute = { NameMap: … }`)도 다음 선언으로 넘치지 않게(리뷰 반영)
        m = re.search(rf"^export type {re.escape(tname)} = ", text, re.M)
        if not m:
            raise SystemExit(f"gate: could not find `export type {tname}` in {where}")
        i = text.index("{", m.end())
        depth, j = 0, i
        while j < len(text):
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
                if depth == 0:
                    return text[i + 1:j]
            j += 1
        raise SystemExit(f"gate: unbalanced braces in `export type {tname}`")

    # [0순회 H-364] `Slot<T>` joined NewChild (H-351) — its function fields must be gated too. The
    # regex is narrowed to FUNCTION fields (`name: (` / `name: <`): Slot's data fields (`Length`/
    # `Offset: Source<number>`) are not the 8.9 hazard and `Offset` is a real setter (UIGradient).
    # [1순회 H-369] the old regex without `re.M` only matched the body start — every field after a
    # comment line (`State<T>`'s `Compute`/`Observer`/`Gate`/`Apply`, the recursive function fields
    # 8.9 is about) was silently not harvested. [3순회 H-381] a regex cannot tell a depth-0 field
    # from a parameter on its own line inside a multi-line signature (`fn`/`factory`/`keyFn` were
    # harvested; a PascalCase parameter would have been a phantom collision → SystemExit), so the
    # harvest is a depth-0 scan of the type body instead.
    def function_fields(body):
        names, depth, i, n = set(), 0, 0, len(body)
        while i < n:
            c = body[i]
            if body.startswith("->", i):
                i += 2
                continue
            if c in "(<{[":
                depth += 1
            elif c in ")>}]":
                depth -= 1
            elif depth == 0 and (c.isalpha() or c == "_"):
                j = i
                while j < n and (body[j].isalnum() or body[j] == "_"):
                    j += 1
                k = j
                while k < n and body[k] in " \t":
                    k += 1
                if k < n and body[k] == ":":
                    k += 1
                    while k < n and body[k] in " \t\n":
                        k += 1
                    if k < n and body[k] in "(<":
                        names.add(body[i:j])
                i = j
                continue
            i += 1
        if depth != 0:
            # a string literal type with a bracket, or an unbalanced body — never a silent
            # shrink of the gate (file-head rule: no silent truncation)
            raise SystemExit(f"gate: depth-0 scan ended at depth {depth} — cannot harvest function fields")
        return names
    for tname in ("StateData<T>", "State<T>", "Tag", "Attribute", "Slot<T>", "Observer", "EffectHandle"):
        union_member_functions |= function_fields(type_body(tname))
    # `<Class>Elem` = NewChild | <Class>OnChange | … — the descriptor's function fields join too
    union_member_functions |= function_fields(type_body("OnChangeDescriptor", rt, "quad-roblox types.luau"))
    if "Callback" not in union_member_functions:
        raise SystemExit("gate: OnChangeDescriptor.Callback not harvested from quad-roblox types.luau")
    # reserved Modifier methods — read from the runtime `methods` table in `Modifier.luau`
    # (`function methods.X(` / `methods.X = `), not hand-copied (Q3 ⑦); the cast prefix `As` is
    # a method there too, so it lands in the set as well as in the prefix check below
    mod_src = strip_comments((ROOT / "quad-base" / "src" / "Modifier.luau").read_text())
    reserved = set(re.findall(r"^function methods\.([A-Za-z_][A-Za-z0-9_]*)\s*\(", mod_src, re.M))
    reserved |= set(re.findall(r"^methods\.([A-Za-z_][A-Za-z0-9_]*)\s*=", mod_src, re.M))
    if not {"Apply", "Peek", "Overridden", "As"} <= reserved:
        raise SystemExit(f"gate: reserved Modifier methods harvested from Modifier.luau look wrong: {sorted(reserved)}")
    for node in mod_classes:
        for p in mod_props(node):
            if p["name"] in reserved:
                # 런타임 `__index`가 예약 메소드를 먼저 잡아 그런 setter는 존재할 수
                # 없다 — 조용한 절단 금지(파일 머리 규칙): 생성 자체를 실패시킨다
                raise SystemExit(f"{node}.{p['name']}: property collides with a reserved Modifier method")
            if re.match(r"^As[A-Z]", p["name"]):
                raise SystemExit(f"{node}.{p['name']}: property matches the reserved cast prefix As<Class>")
            if p["name"] in union_member_functions:
                raise SystemExit(f"{node}.{p['name']}: setter name collides with a children-union member method (typing-limits 8.9)")

    def emit_modifier(node):
        props = mod_props(node)
        desc = descendants(node)
        L.append(f"export type {node}Modifier = {{")
        L.append(f'\tread __quadModifier: "{node}", -- 클래스 태그(H-300 관례) — 런타임 값의 태그와 같은 리터럴')
        L.append(f"\tPeek: <T>(self: {node}Modifier, key: string) -> FieldOut<T>?, -- 저장된 그대로(Q24 후속: old와 같은 타입)")
        L.append("\tApply: <U>(self: any, factory: (any) -> U) -> U, -- any: 8.9절(재귀 필드 이름 충돌)")
        L.append(f"\tOverridden: (self: {node}Modifier, ...any) -> any,")
        L.append(f"\tAs: <T>(self: {node}Modifier, name: string?) -> T, -- 무검사(11절)")
        L.append(f"\tAs{node}: (self: {node}Modifier) -> {node}Modifier, -- 항등(Into<{node}> 구현)")
        for d in desc:
            L.append(f"\tAs{d}: (self: {node}Modifier) -> {d}Modifier,")
        for p in props:
            t = p["type"]
            L.append(f"\t{p['name']}: (self: {node}Modifier, value: Field<{t}>) -> {node}Modifier,")
        if is_gui_object(node):
            for sname, t in SHORTHAND:
                L.append(f"\t{sname}: (self: {node}Modifier, value: Field<{t}>) -> {node}Modifier, -- 숏핸드(H-336; 유니언 T도 마커 한 벌)")
        L.append("}")
        # Into<Class> — "이 클래스로 갈 수 있는 모든 것"(상위·자기·커스텀 구현체).
        # self는 any여야 한다: self를 인터페이스 타입으로 두면 반공변 때문에
        # setter를 가진 실제 Modifier가 안 들어온다(실측)
        L.append(f"export type Into{node} = {{ As{node}: (self: any) -> {node}Modifier }}")

    for name in mod_classes:
        if name not in classes:
            emit_modifier(name)
            L.append("")
            continue
        c = classes[name]
        L.append(f"export type {name}OnChange =")
        # Q19: the per-class OnChange union takes the READ surface too (ReadOnly props)
        members = [f'\t{{ Name: "{p["name"]}", Callback: ({p["type"]}) -> () }}' for p in c["props"] + c.get("readProps", [])]
        # 리뷰 반영: 프로퍼티가 0개인 클래스(지금은 없음 — 최소 Folder 4개)가
        # 생기면 우변 없는 별칭이 찍혀 파일 전체가 깨진다 → never
        L.append("\n\t| ".join(members) if members else "\tnever")
        # <Class>Modifier — 프로퍼티만(이벤트 제외: setter의 함수 인자는 변환 함수라
        # 콜백과 구분 불가 — modifier-plan 4절)
        emit_modifier(name)
        # ⚠️ <Class>Modifier는 Elem에 직접 넣지 않는다 — 재귀 메소드 수십 개짜리
        # 테이블 타입이 유니언에 들어가면 큰 클래스의 캐스트 자리에서 솔버가
        # "too complex"(2026-09-04 실측 — typing-limits 8.8절). 대신 조상 체인 마커
        # 하나로 폭 서브타이핑: 자기 클래스와 조상 클래스의 Modifier만 들어온다
        # (다른 클래스는 태그 불일치로 거부 — 단위 ④가 되찾은 클래스 소속 검사).
        # 배열 원소 유니언은 클래스당 별칭 하나 — D/DMapper 타입과 런타임 캐스트
        # 네 자리가 같은 별칭을 참조한다(손 나열 드리프트 방지, 리뷰 반영)
        marker = " | ".join(f'"{n}"' for n in [name] + ancestors(name))
        # M8 단위 ③(round18 H-321): Ref/PreRef/PostRef는 반공변 팬텀 마커로 —
        # `Ref<T>`의 `__quadRefAccepts: (T) -> ()`에 (<Class>) -> ()를 대조하면 상위
        # 박스(`Ref<GuiObject?>`)는 받고 형제·`Ref<nil>`은 거부. `State<Ref>`는 8.7
        # 캐비엇 5대로 마커로 캐스트해 만든다(`q.Source(ref :: FrameRefMarker)`);
        # `State<PreRef>`는 타입이 못 가르고 런타임 가드(Ref.luau)가 잡는다.
        L.append(f"export type {name}RefMarker = {{ read __quadRefAccepts: ({name}) -> () }}")
        # [2026-09-07 마커] State 팔은 StateMarker — `State<Ref<Frame?>>`가 캐스트 없이 `StateMarker<FrameRefMarker>`에
        # 든다(공변 + Ref의 반공변 팬텀이 폭 서브타이핑으로 대조됨), 8.7 캐비엇 5의 캐스트 관용구는 불필요
        L.append(f"export type {name}Elem = NewChild | {name}OnChange | StateMarker<{name}OnChange> | {{ read __quadModifier: {marker} }} | {name}RefMarker | StateMarker<{name}RefMarker>")
        L.append(f"export type {name}MapperElem = {name}Elem | MapperDescriptor")
        L.append("")
    L.append("-- D 네임스페이스 타입(H-305 (d′)) — `UseProvider` 확장 `RobloxExtension`이")
    L.append("-- 싣는 풀 타입 표면. 아래 런타임 별칭 캐스트와 1:1 — 손 나열 금지 계약대로")
    L.append("-- 생성기가 같이 찍는다.")
    L.append("export type DMapper = {")
    L.append("\tRoot: MapperRoot,")
    for name in names:
        L.append(
            f"\t{name}: (key: string | MapperRoot) -> ({name}Param<{name}MapperElem>) -> MapperDescriptor,"
        )
    L.append("}")
    L.append("export type DModifier = {")
    for name in mod_classes:
        L.append(f"\t{name}: (...({name}Modifier | {{ [string]: any }})) -> {name}Modifier,")
    L.append("}")
    L.append("export type D = {")
    L.append("\tNew: <T>(className: string) -> (props: any) -> T,")
    L.append("\tMapper: DMapper,")
    L.append("\tModifier: DModifier,")
    for name in names:
        L.append(f"\t{name}: ({name}Param<{name}Elem>) -> {name},")
    L.append("}")
    L.append("")
    L.append("--[[ InitD(quad) — `UseProvider` 확장(`RobloxExtension.D`)으로 실린다")
    L.append("\t(round14 H-299의 module.D 직접 대입 채널을 H-305 (d′)가 병합 채널로 이동).")
    L.append("\tNew의 ①~④ 순서는 bind-system-plan 파이프라인 의사코드가 계약. ]]")
    L.append("return function(quad: any): D")
    L.append("\tlocal function New<T>(className: string): (props: any) -> T")
    L.append("\t\tlocal function stage(props: any): T")
    L.append("\t\t\tlocal inst = Instance.new(className) -- ①")
    L.append("\t\t\tquad.nativeClaim(inst) -- ② 생성 직후 무조건, ③④보다 먼저")
    L.append("\t\t\t-- ③④ — flatten(Modifier 소진)은 drive의 첫 pre-pass(round17 Q4 (a),")
    L.append("\t\t\t-- 2026-09-04): New와 Claim이 같은 호출 자리를 쓴다")
    L.append("\t\t\tquad.Dispatch.drive(inst, props)")
    L.append("\t\t\treturn inst :: any")
    L.append("\t\tend")
    L.append("\t\t-- H-238: 범위 밖 클래스의 D.New(name)(props) 경로도 blame이 사용자")
    L.append("\t\t-- 줄에 닿아야 한다 — 스테이지를 만들 때 태그(별칭도 이 경로로 만들어져")
    L.append("\t\t-- 전부 태그됨; 리뷰 발견 반영)")
    L.append("\t\tquad.errorNamespace.setFuncLevel(stage, QuadTypes.ERROR_LEVEL_SURFACE)")
    L.append("\t\treturn stage")
    L.append("\tend")
    L.append("\t-- D.Mapper — Claim용 디스크립터 생성기(claim-plan §2; 본체는 quad-base")
    L.append("\t-- Claim.luau의 newMapperClass — 여기선 클래스별 캐스트 별칭만, D.<Class> 동형)")
    L.append("\tlocal Mapper: { [string]: any } = { Root = quad.MapperRoot }")
    L.append("\t-- D.Modifier — 클래스별 타입드 Modifier 생성자(round17 §0 Q3 (a); 단위 ④):")
    L.append("\t-- quad.Modifier.TypedFactory(name)이 돌려주는 태그 생성자(런타임 병합 본문은")
    L.append("\t-- base 하나) + DefineSubtype(parent, name) 간선 — 둘 다 dedup이라 순서 자유")
    L.append("\tlocal ModifierNS: { [string]: any } = {}")
    L.append("\tlocal D: { [string]: any } = { New = New, Mapper = Mapper, Modifier = ModifierNS }")
    for name in names:
        L.append(f'\tD.{name} = (New("{name}") :: any) :: ({name}Param<{name}Elem>) -> {name}')
    for name in names:
        L.append(
            f'\tMapper.{name} = (quad.newMapperClass("{name}") :: any) :: (key: string | MapperRoot) -> ({name}Param<{name}MapperElem>) -> MapperDescriptor'
        )
    for name in mod_classes:
        L.append(f'\tModifierNS.{name} = (quad.Modifier.TypedFactory("{name}") :: any) :: (...({name}Modifier | {{ [string]: any }})) -> {name}Modifier')
    for name in mod_classes:
        parent = parent_of[name]
        if parent:
            L.append(f'\tquad.Modifier.DefineSubtype("{parent}", "{name}")')
    L.append("\tquad.errorNamespace.setFuncLevel(New, QuadTypes.ERROR_LEVEL_SURFACE) -- 별칭·스테이지는 New 안에서 태그됨")
    L.append("\treturn (D :: any) :: D")
    L.append("end")
    text = "\n".join(L) + "\n"
    if CHECK_ONLY:
        # [7순회 H-423] `check` — test.sh gate: the committed D must equal a fresh emit
        # (deterministic: every output walk is sorted, every input is tracked). Also runs
        # every SystemExit gate above without touching the tree.
        current = OUT.read_text() if OUT.exists() else ""
        if current != text:
            raise SystemExit(f"gen-d check: {OUT} differs from a fresh emit — run `python3 scripts/gen-d.py emit` and commit")
        print(f"check: {len(names)} classes, generated D is up to date")
        return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text)
    print(f"emit: {len(names)} classes -> {OUT}")


CHECK_ONLY = False


def main():
    global CHECK_ONLY
    if len(sys.argv) >= 2 and sys.argv[1] == "normalize":
        normalize(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 2 and sys.argv[1] == "emit":
        emit()
    elif len(sys.argv) >= 2 and sys.argv[1] == "check":
        CHECK_ONLY = True
        emit()
    else:
        print(__doc__)
        sys.exit(2)


main()
