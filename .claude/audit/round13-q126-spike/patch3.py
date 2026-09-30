import pathlib
p = pathlib.Path("/code/Projects/quad/.claude/worktrees/agent-a14bdc0013ba280eb/scripts/gen-d.py")
s = p.read_text()
old = '''# [Q126 spike] value types whose Dump category is Class (object references). The engine accepts a
# nil write there, so the State arm also carries nil/None (the runtime writes nil for both).
CLASS_VALUE_TYPES = set()
# [Q126 spike] "B" = StateMarker<(T | None)?> (NewChild's shape), "A" = StateMarker<T?>
import os as _os
NIL_SHAPE = _os.environ.get("QUAD_NIL_SHAPE", "B")


def nil_marker(inner):
    """State arm of a nil-accepting slot: the runtime treats a State's nil and None alike."""
    return f"StateMarker<({inner} | None)?>" if NIL_SHAPE == "B" else f"StateMarker<({inner})?>"
'''
new = '''# [Q126] object-reference value types (defs types whose `extends` chain reaches Instance — filled
# by emit()). The engine accepts a nil write there, so the State arm also carries nil/None.
CLASS_VALUE_TYPES = set()


def nil_marker(inner):
    """State arm of a slot whose runtime takes a State's nil/None as a feature (nil write, disconnect,
    destroy, detach) — NewChild's shape: `StateMarker<(X | None)?>`."""
    return f"StateMarker<({inner} | None)?>"
'''
assert old in s
s = s.replace(old, new, 1)
s = s.replace("# [Q126 spike]", "# [Q126]")
p.write_text(s)
print("ok")
