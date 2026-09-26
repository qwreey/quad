import re
def parse_block(sig):
    """-> list of (kind, name, params, text)"""
    lines = sig.split("\n")
    # uncomment doc-commented type defs
    out = []
    for l in lines:
        s = l
        if re.match(r"^--\s+(export type |type |Relate = |Namespace = |ContextConstructor =)", s) or (out and out[-1][1] and re.match(r"^--\s", s)):
            s2 = re.sub(r"^--\s?", "", s)
            out.append((s2, True))
        else:
            out.append((s, False))
    items = []; cur = None
    def flush():
        if cur: items.append(cur)
    for s, was_comment in out:
        s = re.sub(r"\s--\s.*$", "", s) if not s.lstrip().startswith("--") else s
        if s.lstrip().startswith("--") and not was_comment: continue
        mt = re.match(r"^(?:export )?type (\w+)(<[^>]*>)?\s*=\s*(.*)$", s) or re.match(r"^(Relate|Namespace) = (\{.*)$", s)
        mm = re.match(r"^(?:read )?([\w.]+|\w+<\w+>):\s*(.*)$", s)
        if mt:
            flush()
            if mt.re.pattern.startswith("^(Relate"):
                cur = ["type", mt.group(1), None, mt.group(2)]
            else:
                cur = ["type", mt.group(1), mt.group(2), mt.group(3)]
        elif mm and not s.startswith((" ", "\t")):
            flush(); cur = ["member", mm.group(1), None, mm.group(2)]
        elif cur:
            cur[3] += "\n" + s
        globals()["cur"] = cur
    flush()
    return items

