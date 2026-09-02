#!/usr/bin/env python3
"""gen-d.py — `quad-roblox/src/D/init.luau` 코드 생성기 (M5 단위 ②).

두 단계(round14 Q5 (a) — 덤프를 재사용 가능한 형태로 남긴다):
  normalize <raw-API-Dump.json> <clientVersionUpload>
      → quad-roblox/dump/api-surface.json  (커밋되는 정규화 산출물 —
        M7 FrameModifier 생성기가 같은 파일을 재사용, Parent 제외는 여기 덤프 층)
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
  H-298 (a) 스칼라 = T | State<T> | Tween<T> | None, 이벤트 = 콜백 |
            State<콜백> | None, children = NewChild(types.luau) — None 표현은
            H-300 (a)로 확정(센티널 마커 필드 → QuadTypes.None)
  H-142     Parent는 덤프 층에서 제외(Q5 (a) — M7 목록과 공유되는 자리)
드롭된 항목은 전부 normalized의 dropped에 남긴다 — 조용한 절단 금지.
"""

import json
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
# ContentId는 핀 고정된 globalTypes(luau-lsp 1.69.0)가 옛 이름 `Content`로만
# 알고 있다 — defs를 올릴 때 이 매핑을 재검토할 것
DATATYPE_RENAME = {"OptionalCoordinateFrame": "CFrame", "ContentId": "Content"}
DATATYPE_SKIP = {"QDir", "QFont", "BinaryString", "ProtectedString", "SystemAddress"}

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
        return f"{luau_type.split('.', 1)[1]}:" in defs_text or luau_type in defs_text
    return f"declare extern type {luau_type} " in defs_text or f"declare extern type {luau_type}<" in defs_text


def chain_members(classes, name):
    seen = set()
    node = name
    while node in classes:
        for m in classes[node]["Members"]:
            key = (m["MemberType"], m["Name"])
            if key in seen:
                continue  # 하위 클래스의 오버라이드가 이김
            seen.add(key)
            yield m
        node = classes[node].get("Superclass")


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
        props, events = [], []
        for m in chain_members(classes, name):
            mtags = set(m.get("Tags") or [])
            if m["MemberType"] == "Property":
                if m["Name"] == "Parent":
                    continue  # H-142 — 덤프 층 제외(Q5 (a))
                if mtags & PROP_TAG_EXCLUDE:
                    continue
                sec = m.get("Security") or {}
                if sec.get("Write") != "None" or sec.get("Read") != "None":
                    continue
                t = map_type(m["ValueType"], dropped, f"{name}.{m['Name']}")
                if t is not None and not defs_knows(defs_text, t):
                    dropped.append(f"{name}.{m['Name']}: type {t} newer than pinned defs")
                    t = None
                if t is not None:
                    props.append({"name": m["Name"], "type": t})
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
                    events.append({"name": m["Name"], "params": params})
        props.sort(key=lambda p: p["name"])
        events.sort(key=lambda e: e["name"])
        surface[name] = {"props": props, "events": events}
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
    L.append("\tround14 H-295~H-298·H-300. 유니언: 스칼라 T | State<T> | Tween<T> | None,")
    L.append("\t이벤트 콜백 | State<콜백> | None (None 표현은 H-300 (a) — QuadTypes.None).")
    L.append("\t이벤트 필드의 런타임 핸들러는 M10(Handlers/Event) — 타입이 먼저 오는 것은")
    L.append("\tROADMAP M5 체크박스가 명시한 계약이다.")
    L.append("]]")
    L.append("")
    L.append('local QuadTypes = require("../luau_packages/quad_types")')
    L.append('local Types = require("./types")')
    L.append("")
    L.append("type State<T> = QuadTypes.State<T>")
    L.append("type Tween<T> = Types.Tween<T>")
    L.append("type NewChild = Types.NewChild")
    L.append("type None = QuadTypes.None")
    L.append("type MapperDescriptor = QuadTypes.MapperDescriptor")
    L.append("type MapperRoot = QuadTypes.MapperRoot")
    L.append("")
    names = sorted(classes.keys())
    for name in names:
        c = classes[name]
        L.append(f"export type {name}Param<E> = {{")
        L.append("\t[number]: E,")
        for p in c["props"]:
            t = p["type"]
            L.append(f"\t{p['name']}: ({t} | State<{t}> | Tween<{t}> | None)?,")
        for ev in c["events"]:
            sig = luau_event_sig(ev)
            L.append(f"\t{ev['name']}: (({sig}) | State<{sig}> | None)?,")
        L.append("}")
        L.append("")
    L.append("--[[ InitD(quad) — RobloxFactory가 module.D로 설치한다(round14 H-299).")
    L.append("\tNew의 ①~④ 순서는 bind-system-plan 파이프라인 의사코드가 계약. ]]")
    L.append("return function(quad: any)")
    L.append("\tlocal function flatten(props: any): any")
    L.append("\t\t-- ③ 자리 — M7 Modifier 소진이 여기 온다(modifier-plan \"flatten의")
    L.append("\t\t-- 정확한 형태\" 정본). M5엔 Modifier 표면이 없어 항등.")
    L.append("\t\treturn props")
    L.append("\tend")
    L.append("\tlocal function New<T>(className: string): (props: any) -> T")
    L.append("\t\tlocal function stage(props: any): T")
    L.append("\t\t\tlocal inst = Instance.new(className) -- ①")
    L.append("\t\t\tquad.nativeClaim(inst) -- ② 생성 직후 무조건, ③④보다 먼저")
    L.append("\t\t\tlocal flattened = flatten(props) -- ③")
    L.append("\t\t\tquad.Dispatch.drive(inst, flattened) -- ④")
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
    L.append("\tlocal D: { [string]: any } = { New = New, Mapper = Mapper }")
    for name in names:
        L.append(f'\tD.{name} = (New("{name}") :: any) :: ({name}Param<NewChild>) -> {name}')
    for name in names:
        L.append(
            f'\tMapper.{name} = (quad.newMapperClass("{name}") :: any) :: (key: string | MapperRoot) -> ({name}Param<NewChild | MapperDescriptor>) -> MapperDescriptor'
        )
    L.append("\tquad.errorNamespace.setFuncLevel(New, QuadTypes.ERROR_LEVEL_SURFACE) -- 별칭·스테이지는 New 안에서 태그됨")
    L.append("\treturn D")
    L.append("end")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(L) + "\n")
    print(f"emit: {len(names)} classes -> {OUT}")


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "normalize":
        normalize(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 2 and sys.argv[1] == "emit":
        emit()
    else:
        print(__doc__)
        sys.exit(2)


main()
