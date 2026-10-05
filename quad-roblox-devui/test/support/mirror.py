#!/usr/bin/env python3
"""Build a Lune-runnable mirror of a kit + the quad packages it requires.

Lune 0.10.5 (the newest release) parses an older Luau: it rejects `const` and explicit type
instantiation `f<<T>>(x)`. Both are runtime-irrelevant syntax, and both are idiomatic quad
(`q.Slot<<Instance>>()`, the docs' `const D = q.Declaration`). Instead of banning them from kit code,
the runner copies the needed tree to a temp dir and rewrites, line-preserving:
  - `<<...>>` explicit type arguments  -> removed (balanced-angle scan; `->` inside is skipped)
  - `const name` at statement start    -> `local name`
Line numbers are kept, so errors point at the same line in the original file.

usage: mirror.py <kit-folder-name> <out-dir>     (run from the repo root)
"""
import os, re, shutil, sys

CONST_RE = re.compile(r"^(\s*)const(\s+[A-Za-z_])", re.M)
LONG_OPEN = re.compile(r"\[(=*)\[")


def strip_type_args(src: str) -> str:
    out = []
    i, n = 0, len(src)
    in_str = None  # quote char while inside a short string
    while i < n:
        c = src[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1]); i += 2; continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in "\"'`":
            in_str = c; out.append(c); i += 1; continue
        long_at = i + 2 if src.startswith("--", i) else (i if c == "[" else -1)
        if long_at >= 0:
            m = LONG_OPEN.match(src, long_at)
            if m:  # block comment `--[==[ ... ]==]` or long string `[[ ... ]]`: copy verbatim
                close = "]" + m.group(1) + "]"
                j = src.find(close, m.end())
                j = n if j < 0 else j + len(close)
                out.append(src[i:j]); i = j; continue
        if c == "-" and src.startswith("--", i):  # line comment: copy to end of line
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(src[i:j]); i = j; continue
        if src.startswith("<<", i) and i > 0 and (src[i - 1].isalnum() or src[i - 1] in "_)]"):
            depth, j = 2, i + 2
            while j < n and depth > 0:
                ch = src[j]
                if ch == "-" and j + 1 < n and src[j + 1] == ">":
                    j += 2; continue
                if ch == "<":
                    depth += 1
                elif ch == ">":
                    depth -= 1
                elif ch == "\n":
                    out.append("\n")  # keep line count if type args span lines
                j += 1
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def rewrite(src: str) -> str:
    return CONST_RE.sub(r"\1local\2", strip_type_args(src))


def copy_tree(src_dir: str, dst_dir: str):
    for root, dirs, files in os.walk(src_dir, followlinks=True):
        rel = os.path.relpath(root, src_dir)
        target = os.path.join(dst_dir, rel)
        os.makedirs(target, exist_ok=True)
        for f in files:
            s = os.path.join(root, f)
            d = os.path.join(target, f)
            if f.endswith(".luau") or f.endswith(".lua"):
                with open(s, encoding="utf-8") as fh:
                    text = fh.read()
                with open(d, "w", encoding="utf-8") as fh:
                    fh.write(rewrite(text))
            else:
                shutil.copyfile(s, d)


def main():
    kit, out = sys.argv[1], sys.argv[2]
    if os.path.exists(out):
        shutil.rmtree(out)
    for part in [
        kit,
        "quad-base/src",
        "quad-base/test",
        "quad-base/luau_packages",
        "quad-roblox/src",
        "quad-roblox/luau_packages",
    ]:
        copy_tree(part, os.path.join(out, part))
    print(f"mirror: {out}")


if __name__ == "__main__":
    main()
