#!/usr/bin/env python3
"""gen-d.py — 덤프 정규화 + 타입 함수가 읽는 정책 데이터 `quad-roblox/src/Surface/Data.luau` 생성기 (M5 단위 ②에서 시작;
[2026-10-20 3.4.0] 옛 생성 `Declaration` 모듈은 없어졌다 — 표면은 `quad-roblox/src/Surface/init.luau`의 타입 함수가 만든다).

두 단계(round14 Q5 (a) — 덤프를 재사용 가능한 형태로 남긴다):
  normalize <raw-API-Dump.json> <clientVersionUpload>
      → quad-roblox/dump/api-surface.json  (커밋되는 정규화 산출물 —
        M7 단위 ③·④가 같은 emit()을 확장해 <Class>Modifier 타입도 여기서 생성,
        Parent 제외는 여기 덤프 층)
  emit
      → quad-roblox/src/Surface/Data.luau      ([2026-10-20 3.4.0] 타입 함수가 읽는 데이터만 — 클래스 맵 둘,
        정의 클래스 기준 정책(normalized `policy` — 만들 수 있는 모든 클래스 사슬), Inject·Shorthand, 런타임 Superclass 표)
  check
      → emit과 같은 계산을 하고 커밋된 Data.luau와 다르면 실패(test.sh 게이트)

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
            — [사용자 결정 2026-09-09] Deprecated/Hidden 갈래는 좁혀졌다: v1 마이그레이션
              자동완성을 위해 Deprecated는 통째로, Hidden은 이름 허용목록(`Font`/`Transparency`)만
              표면에 남기고 `-- @deprecated` 주석으로 표시한다(PROP_TAG_LEGACY/옛 HIDDEN_NAME_KEEP·DEPRECATED_NAME_KEEP → [2026-10-20] 정의 클래스 기준 LEGACY_KEEP — [2026-09-21] Deprecated도 허용목록;
              실측·선택지는 `.claude/audit/deprecated-props-spike-2026-09-09/REPORT.md`).
              ReadOnly는 그대로 Q19 (a)의 readProps 경로, NotScriptable/보안은 그대로 제외.
  H-298 (a)+H-326 스칼라 = T | TweenData<T> | StateMarker<T | Tween<T>> | None(2026-09-07 마커; Tween 팔은 보간 가능 타입만 — Q34, 2026-09-08),
            이벤트 = 콜백 | StateMarker<콜백> | None, children = NewChild(types.luau) — None 표현은
            H-300 (a)로 확정(센티널 마커 필드 → QuadTypes.None)
  H-142     Parent는 덤프 층에서 제외(Q5 (a) — M7 목록과 공유되는 자리)
드롭된 항목은 전부 normalized의 dropped에 남긴다 — 조용한 절단 금지. (예외 하나 — 2026-09-27 G1 감사: `NotCreatable`/`Service` 태그 필터가 스코프 판정보다 먼저 걸리는 추상 클래스(GuiObject·GuiButton·LayerCollector·UIComponent 등 12개)는 `Instance.new`가 안 되는 것이라 dropped에 안 남긴다 — 의도된 생략이지 절단이 아님.)
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SURFACE = ROOT / "quad-roblox" / "dump" / "api-surface.json"
DATA_OUT = ROOT / "quad-roblox" / "src" / "Surface" / "Data.luau"  # [2026-10-20 3.4.0] data only — the type functions read it

SCOPE_ROOTS = ("GuiObject", "UIComponent", "LayerCollector")
SCOPE_EXTRA = {"Folder", "Camera", "WorldModel"}  # H-296 (a) 화이트리스트(vide 반례)
# H-301(실측 보강): 클래스 수준 제외 — Deprecated(GuiMain)·NotBrowsable(내부 UI)·
# MemoryCategory Internal(AdGui)은 사용자 표면이 아니고, RelativeGui는 태그론 안
# 드러나지만 Studio 실측에서 RobloxScript capability 없이 생성 불가였다
CLASS_TAG_EXCLUDE = {"Deprecated", "NotBrowsable"}
CLASS_DENY = {"RelativeGui"}  # 실측: lacking capability RobloxScript
PROP_TAG_EXCLUDE = {"ReadOnly", "Deprecated", "NotScriptable", "Hidden"}
# [사용자 결정 2026-09-09] engine-legacy props are kept in the surface instead of dropped —
# an agent migrating quad v1 → v2 needs `Font`/`FontSize`/`TextWrap` to autocomplete, and a
# missing key surfaces as a type error it cannot resolve. 실측·선택지·결정 원문은
# `.claude/audit/deprecated-props-spike-2026-09-09/REPORT.md`(Studio 실측으로 `ReflectionService`가
# 이 프로퍼티들을 `Permits.Write == Edit`로 준다는 전제도 확인 — 런타임 디스패치가 매치한다;
# ⚠️ [2026-09-27 round13 E25] 그 실측은 `GetPropertiesOfClass("TextLabel")` 하나다 — `Font`/`FontSize`/`TextWrap`은
# TextLabel·TextButton·TextBox가 각자 선언한 멤버라 뒤의 둘은 미실측(HUMAN_TODO I)).
# 정책: ~~Deprecated 태그는 통째로~~ **[2026-09-21 사용자 결정 — round11 실측 1번]** Deprecated도 이름
# 허용목록(옛 `DEPRECATED_NAME_KEEP`, 지금 `LEGACY_KEEP`)만 — 의도는 처음부터 "자주 쓰이던 것만"이었고(재작성 노고가 큰 것),
# 소문자 별칭(`className`/`focus`)은 quad v1 이전의 유물이라 뺀다(`className`의 변경 시그널은 Studio
# 실측에서 만들어지지만 발화하지 않는 죽은 시그널 — `audit/round11-studio-2026-09-21/REPORT.md` 1번);
# `Draggable`·`DistanceLowerLimit`/`DistanceUpperLimit`도 사용자 판단으로 뺀다. Hidden은 이름 허용목록(옛 `HIDDEN_NAME_KEEP`, 지금 `LEGACY_KEEP`)만.
# `Font`/`Transparency`는 Deprecated가 아니라 Hidden(+NotReplicated)이라 이름으로 연다.
# 되살린 프로퍼티는 필드 위 `---` 독 주석 + 뒤따르는 `-- @deprecated` 주석으로 표시한다 —
# 주석이 유일한 채널이다(Luau `@deprecated` 속성은 함수 전용, 테이블 타입 필드 앞은 SyntaxError).
PROP_TAG_LEGACY = {"Deprecated", "Hidden"}
# [2026-10-20 3.4.0 단위 1] the allow-list is keyed by the DECLARING class and keeps the member whichever of
# Deprecated/Hidden it carries — the name-per-tag lists (`Font`/`Transparency` for Hidden, `FontSize`/`TextWrap` for
# Deprecated) dropped `GuiObject.Transparency` the moment a newer dump tagged it Deprecated too (M4,
# `audit/decl-typefn-probe-2026-10-16/REPORT.md`). Same members as before for the committed dump.
LEGACY_KEEP = {("GuiObject", "Transparency")} | {
    (c, n) for c in ("TextLabel", "TextButton", "TextBox") for n in ("Font", "FontSize", "TextWrap")
}
# [2026-10-20] core props the dump tags Hidden although scripts use them every day — policy data only (outside the
# GUI scope; they reach users through `q.ForClasses`). Not legacy: no `@deprecated` note.
HIDDEN_CORE_KEEP = {("BasePart", "Position"), ("BasePart", "Orientation"), ("Attachment", "Position"),
    ("Attachment", "Orientation"), ("Attachment", "WorldPosition"), ("Attachment", "WorldOrientation")}
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


# [round11 Q66 (b), 사용자 결정 2026-09-18] Event parameters the engine passes as nil although the API
# Dump types them as a bare Class (the Dump has no optionality; the pinned defs say `Instance?`).
# This is the CLOSED list of "defs says optional, our surface said not" over the whole scope
# (탐사 J′): `Parent` (readProps, handled inline above) and `AncestryChanged.parent` — the other
# two the defs mark optional, `Camera.CameraSubject` and `Model.PrimaryPart`, are WRITE-surface
# properties where a bare type is harmless (writing nil is typed elsewhere), so they stay.
ENGINE_NIL_EVENT_PARAMS = {("AncestryChanged", "parent")}


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


def policy_of(classes):
    """[2026-10-20 3.4.0 단위 1] owner-keyed member policy for EVERY Instance class (not only the GUI scope) — the
    type functions (`quad-roblox/src/Surface/`) check a member against the class that DECLARES it, so a name denied on
    one class never leaks to another (M4: a global-name Deny erased `Part.Shape`). `q.ForClasses` maps reach any class.
      denyIn       both surfaces — Deprecated/NotScriptable/Hidden (minus LEGACY_KEEP/HIDDEN_CORE_KEEP), Read security,
                   events tagged Deprecated/Hidden or with security
      denyWriteIn  write surface only — ReadOnly, Write security, Parent (H-142)
    Same tag rules as the scope surface below; methods/callbacks are not listed (the type functions skip them)."""
    deny, deny_write = {}, {}
    # owners = the chains of every creatable (non-Service) Instance class — what a user map can name or an ancestor of it
    owners = set()
    for name, c in classes.items():
        ctags = set(c.get("Tags") or [])
        chain = class_chain(classes, name)
        if "Instance" in chain and not (ctags & {"NotCreatable", "Service"}):
            owners.update(chain)
    for owner in sorted(owners):
        for m in classes[owner].get("Members", []):
            mtags = set(m.get("Tags") or [])
            nm = m["Name"]
            if m["MemberType"] == "Property":
                if nm == "Parent":
                    deny_write.setdefault(owner, set()).add(nm)
                    continue
                keep = (mtags & PROP_TAG_LEGACY) if (owner, nm) in LEGACY_KEEP | HIDDEN_CORE_KEEP else set()
                sec = m.get("Security") or {}
                if mtags & (PROP_TAG_EXCLUDE - {"ReadOnly"} - keep) or sec.get("Read") != "None":
                    deny.setdefault(owner, set()).add(nm)
                elif "ReadOnly" in mtags or sec.get("Write") != "None":
                    deny_write.setdefault(owner, set()).add(nm)
            elif m["MemberType"] == "Event":
                if mtags & EVENT_TAG_EXCLUDE or m.get("Security") != "None":
                    deny.setdefault(owner, set()).add(nm)
    # [2026-10-20 3.4.0 단위 4] the superclass of every owner — the runtime registers `As<Class>` edges from it
    # (`q.Modifier "Part"` under a `q.ForClasses` map needs Part's chain without a scope class type)
    superclass = {o: classes[o]["Superclass"] for o in sorted(owners) if classes[o].get("Superclass") in owners}
    return {
        "denyIn": {o: sorted(v) for o, v in sorted(deny.items())},
        "denyWriteIn": {o: sorted(v) for o, v in sorted(deny_write.items())},
        "superclass": superclass,
    }


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
                # `D.VideoFrame { InternalVideoUsage = … }`가 왜 없는지 추적 가능해야 한다
                # ([2026-09-09] `Font`는 이제 안 잘린다 — legacy 되살리기, 위 PROP_TAG_LEGACY)
                if m["Name"] == "Parent":
                    # [Q35 (a), 사용자 결정 2026-09-08 — round3 §11] WRITE surface still excludes Parent (H-142);
                    # the READ surface (OnChange) keeps it — `OnChange("Parent", fn)` was a TypeError.
                    # [round11 Q66 (b), 사용자 결정 2026-09-18] `Instance?` — the engine hands nil the moment the
                    # Instance leaves the tree, which is the main reason to watch Parent at all; the API Dump
                    # carries no optionality, the pinned defs say `Instance?`. See ENGINE_NIL_EVENT_PARAMS.
                    dropped.append(f"{name}.Parent: excluded from the write surface by design (H-142, Q5 (a)); kept in readProps (Q35) as Instance? (Q66)")
                    read_props.append({"name": "Parent", "type": "Instance?", "owner": owner})
                    continue
                # [round1 Q19 (a), 2026-09-07] ReadOnly props (AbsoluteSize/AbsolutePosition/TextBounds…)
                # are not in the WRITE surface but ARE the main OnChange targets — they go to a
                # separate READ list that only the OnChange typing consumes (`PropTypesRead`,
                # `<Class>OnChange`). NotScriptable는 여전히 드롭이고, Deprecated/Hidden은
                # [사용자 결정 2026-09-09] legacy 정책(PROP_TAG_LEGACY/LEGACY_KEEP)이 정한다.
                # [2026-09-09 사용자 결정] ~~Deprecated 태그는 통째로~~ [2026-09-21] Deprecated·Hidden 둘 다 이름 허용목록 —
                # 두 팔을 따로 계산해 Deprecated∧Hidden 쌍둥이가 한쪽 팔을 타고 딸려오지 않게 한다
                keep = (mtags & PROP_TAG_LEGACY) if (owner, m["Name"]) in LEGACY_KEEP else set()
                other_excluded = mtags & (PROP_TAG_EXCLUDE - {"ReadOnly"} - keep)
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
                    entry = {"name": m["Name"], "type": t, "owner": owner}
                    legacy = sorted(mtags & keep) if keep else []
                    if legacy:
                        entry["legacy"] = legacy
                    (read_props if read_only else props).append(entry)
            elif m["MemberType"] == "Event":
                # `H-466`: event drops are noted like property drops (파일 머리 "조용한 절단 금지") —
                # `D.Frame { DragBegin = … }`가 왜 없는지도 추적 가능해야 한다
                if mtags & EVENT_TAG_EXCLUDE:
                    dropped.append(f"{name}.{m['Name']} (event): tags {sorted(mtags & EVENT_TAG_EXCLUDE)}")
                    continue
                if m.get("Security") != "None":
                    dropped.append(f"{name}.{m['Name']} (event): security {m.get('Security')}")
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
                    if (m["Name"], p["Name"]) in ENGINE_NIL_EVENT_PARAMS:
                        t += "?"  # after the defs gate — `Instance?` is not a declared type name
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
        "policy": policy_of(classes),
        "dumpVersion": version,
        "apiVersion": raw.get("Version"),
        "scopeRule": "creatable AND (GuiObject|UIComponent|LayerCollector descendant) OR {Folder,Camera,WorldModel} (H-296 a)",
        "classes": surface,
        "dropped": sorted(set(dropped)),
    }
    SURFACE.parent.mkdir(parents=True, exist_ok=True)
    SURFACE.write_text(json.dumps(out, indent=1, sort_keys=True) + "\n")
    print(f"normalize: {len(surface)} classes, {len(out['dropped'])} dropped notes -> {SURFACE}")


def emit():
    """[2026-10-20 3.4.0 단위 6] data only — the generated `Declaration` module and the generated root export block
    are gone (the type functions in `quad-roblox/src/Surface/init.luau` build the surface from the checker's class types
    and this data)."""
    data = json.loads(SURFACE.read_text())
    classes = data["classes"]
    names = sorted(classes.keys())
    # [round20 H-336] UI 편의 숏핸드 키 넷(ui-shorthand-plan "메커니즘"·"결론" 절) — GuiObject 계열에만. 런타임은
    # Handlers/InstanceShorthand.luau(우선순위 NORMAL+1).
    SHORTHAND = [("UICorner", "number | UDim"), ("UIPadding", "UDim"), ("UIPaddingOffset", "number"), ("UIScale", "number")]
    # [post-implementation review Q3 ⑦, 2026-09-07] the KEY set is gated against the runtime table (`TABLE`) — a key
    # added/renamed on one side only fails generation instead of drifting silently (no silent truncation)
    sh_src = (ROOT / "quad-roblox" / "src" / "Handlers" / "InstanceShorthand.luau").read_text()
    sh_blk = re.search(r"^local TABLE\b[^\n]*=\s*\{\n(.*?)^\}", sh_src, re.S | re.M)
    if not sh_blk:
        raise SystemExit("gate: could not find `local TABLE = {` in Handlers/InstanceShorthand.luau")
    sh_keys = set(re.findall(r"^\t([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{", sh_blk.group(1), re.M))
    if sh_keys != {k for k, _ in SHORTHAND}:
        raise SystemExit(f"gate: SHORTHAND keys {sorted(k for k, _ in SHORTHAND)} != InstanceShorthand.luau TABLE keys {sorted(sh_keys)}")
    # the Modifier/Spread name map = the scope plus every ancestor on its chains (normalize recorded `chain`)
    mod_classes = sorted({n for name in names for n in [name] + classes[name]["chain"]})
    data_text = emit_data(data, names, mod_classes, SHORTHAND)
    if CHECK_ONLY:
        current = DATA_OUT.read_text() if DATA_OUT.exists() else ""
        if current != data_text:
            raise SystemExit(f"gen-d check: {DATA_OUT} differs from a fresh emit — run `python3 scripts/gen-d.py emit` and commit")
        print(f"check: {len(names)} classes, {DATA_OUT.relative_to(ROOT)} is up to date")
        return
    DATA_OUT.parent.mkdir(parents=True, exist_ok=True)
    DATA_OUT.write_text(data_text)
    print(f"emit: {len(names)} classes -> {DATA_OUT}")


def luau_key(n):
    return n if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", n) and n not in RESERVED else f'["{n}"]'


def emit_data(data, names, mod_classes, shorthand):
    """[2026-10-20 3.4.0 단위 1] `quad-roblox/src/Surface/Data.luau` — DATA ONLY (2026-10-19 사용자 결정: the dump fills
    class maps and policy; every rule lives in the type functions). Two class maps (2026-10-19): creatable classes for
    `Elem`/`Mapper`, the same plus abstract ancestors for `Modifier`/`Spread`; both stay the small GUI scope (M4 (a)).
    The owner-keyed policy covers every creatable class chain (see `policy_of`) so `q.ForClasses` maps type right."""
    pol = data["policy"]
    L = [
        "--!strict",
        "-- GENERATED FILE — scripts/gen-d.py emit (do not edit by hand). Data only: the rules are the type functions",
        f"-- beside this file. Dump {data['dumpVersion']} (API {data['apiVersion']}); normalized surface quad-roblox/dump/api-surface.json.",
        "",
        "-- the names `q.Elem`/`q.Mapper` accept (creatable classes in the GUI scope)",
        "export type CreatableMap = {",
    ]
    L += [f"\t{n}: {n}," for n in names]
    L += ["}", "-- the names `q.Modifier`/`q.Spread` accept (the scope plus its abstract ancestors)", "export type ModClassMap = {"]
    L += [f"\t{n}: {n}," for n in mod_classes]
    L += ["}", "-- both surfaces: members denied on the class that DECLARES them", "export type DenyIn = {"]
    for o, ms in pol["denyIn"].items():
        L.append(f"\t{luau_key(o)}: {{ " + ", ".join(f"{luau_key(m)}: true" for m in ms) + " },")
    L += ["}", "-- write surface only (ReadOnly, write security, Parent)", "export type DenyWriteIn = {"]
    for o, ms in pol["denyWriteIn"].items():
        L.append(f"\t{luau_key(o)}: {{ " + ", ".join(f"{luau_key(m)}: true" for m in ms) + " },")
    inject = {}
    for c in names:
        for p in data["classes"][c]["props"]:
            if p.get("legacy"):
                inject.setdefault(p["owner"], {})[p["name"]] = p["type"]
    L += ["}", "-- engine-legacy members the checker's class types lack (kept for v1 migration — gen-d LEGACY_KEEP)", "export type Inject = {"]
    for o in sorted(inject):
        L.append(f"\t{luau_key(o)}: {{ " + ", ".join(f"{luau_key(n)}: {t}" for n, t in sorted(inject[o].items())) + " },")
    L += ["}", "-- shorthand keys (Handlers/InstanceShorthand.luau TABLE — gated in emit)", "export type Shorthand = {",
          "\tGuiObject: { " + ", ".join(f"{k}: {t}" for k, t in shorthand) + " },", "}", "",
          "-- RUNTIME: the superclass of every creatable class's chain — `q.Modifier \"<Class>\"` registers the `As<Class>`",
          "-- edges of the class it is asked for from this (the chain ends at Instance)",
          "return {", "\tSuperclass = {"]
    L += [f"\t\t{luau_key(c)} = \"{s}\"," for c, s in pol["superclass"].items()]
    L += ["\t},", "}", ""]
    return "\n".join(L)


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
