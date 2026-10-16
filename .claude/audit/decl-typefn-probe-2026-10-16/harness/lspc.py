#!/usr/bin/env python3
"""Minimal LSP client for luau-lsp — completion / hover / pushed diagnostics at marked positions.

Re-written 2026-10-16 (the 2026-09-16 scratch harness `dprobe/lspc.py` was deleted).

Launch mirrors the user's VSCode extension (johnnymorganz.luau-lsp 1.70.1):
  server lsp --definitions:@roblox=<PluginSecurity defs> --docs=<api-docs.json> --no-flags-enabled --stdio
  initializationOptions.fflags = Roblox sync FFlags + LuauSolverV2 + workspace override (flags.py)

Markers (Luau comments, so the probe files stay valid in Studio too):
  -- @c(name) at='<substr>' [ins='<text>']   completion; cursor = right after the first <substr> on this
                                                line (+ optional inserted text, sent via didChange)
  -- @h(name) at='<substr>'                    hover at the first character of <substr> on this line
A marker applies to the line it sits on; if the marker is the whole line, it applies to the NEXT line.

Usage:
  lspc.py [--mode vsc|sync|pin] [--max-items N] <file.luau> [...]
Writes a text report to stdout.
"""
import json
import os
import re
import subprocess
import sys
import threading
import time
import queue

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "../../../.."))
EXT = "/code/.local/share/code-docker/code/extensions/johnnymorganz.luau-lsp-1.70.1-linux-x64/bin/server"
GS = "/code/.local/share/code-docker/code/user-data/User/globalStorage/johnnymorganz.luau-lsp"
SNAP = os.path.join(HERE, "../flags/roblox-sync-2026-10-16.json")

sys.path.insert(0, HERE)
import flags as flagsmod  # noqa: E402

MARK = re.compile(r"--\s*@([ch])\((?P<name>[^)]*)\)\s+at='(?P<at>(?:[^'\\]|\\.)*)'(?:\s+ins='(?P<ins>(?:[^'\\]|\\.)*)')?")


class Client:
    def __init__(self, cmd, init_flags, root):
        self.p = subprocess.Popen(
            cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            preexec_fn=lambda: open("/proc/self/oom_score_adj", "w").write("1000"),
        )
        self.id = 0
        self.pending = {}
        self.diags = {}
        self.diag_events = queue.Queue()
        self.lock = threading.Lock()
        self.root = root
        threading.Thread(target=self._reader, daemon=True).start()
        self.request("initialize", {
            "processId": os.getpid(),
            "rootUri": "file://" + root,
            "workspaceFolders": [{"uri": "file://" + root, "name": "probe"}],
            "initializationOptions": {"fflags": init_flags},
            "capabilities": {
                "workspace": {"configuration": True, "workspaceFolders": True},
                "textDocument": {
                    "completion": {"completionItem": {"snippetSupport": True, "documentationFormat": ["markdown", "plaintext"]}},
                    "hover": {"contentFormat": ["markdown", "plaintext"]},
                    "publishDiagnostics": {"relatedInformation": True},
                },
            },
        })
        self.notify("initialized", {})

    def _send(self, msg):
        body = json.dumps(msg).encode()
        self.p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
        self.p.stdin.flush()

    def _reader(self):
        f = self.p.stdout
        while True:
            headers = {}
            line = f.readline()
            if not line:
                return
            while line.strip():
                k, v = line.decode().split(":", 1)
                headers[k.strip().lower()] = v.strip()
                line = f.readline()
            msg = json.loads(f.read(int(headers["content-length"])))
            if "id" in msg and "method" in msg:  # server -> client request
                self._answer(msg)
            elif "id" in msg:
                with self.lock:
                    q = self.pending.pop(msg["id"], None)
                if q:
                    q.put(msg)
            elif msg.get("method") == "textDocument/publishDiagnostics":
                prm = msg["params"]
                self.diags[prm["uri"]] = prm["diagnostics"]
                self.diag_events.put((time.time(), prm["uri"]))

    def _answer(self, msg):
        m = msg["method"]
        result = None
        if m == "workspace/configuration":
            result = []
            for item in msg["params"]["items"]:
                if item.get("section") == "luau-lsp":
                    result.append({
                        "platform": {"type": "roblox"},
                        "sourcemap": {"enabled": False, "autogenerate": False},
                        "completion": {"enabled": True, "imports": {"enabled": False}, "autocompleteEnd": False,
                                       "fillCallArguments": True, "addParentheses": True},
                        "diagnostics": {"workspace": False, "strictDatamodelTypes": False},
                        "hover": {"enabled": True},
                        "types": {"roblox": True},
                    })
                else:
                    result.append(None)
        self._send({"jsonrpc": "2.0", "id": msg["id"], "result": result})

    def request(self, method, params, timeout=120):
        with self.lock:
            self.id += 1
            rid = self.id
            q = queue.Queue()
            self.pending[rid] = q
        self._send({"jsonrpc": "2.0", "id": rid, "method": method, "params": params})
        return q.get(timeout=timeout)

    def notify(self, method, params):
        self._send({"jsonrpc": "2.0", "method": method, "params": params})

    def wait_diags(self, uri, since, timeout=120):
        end = time.time() + timeout
        while time.time() < end:
            try:
                t, u = self.diag_events.get(timeout=max(0.05, end - time.time()))
            except queue.Empty:
                break
            if u == uri and t >= since:
                return t
        return None

    def close(self):
        try:
            self.request("shutdown", None, timeout=10)
            self.notify("exit", None)
        except Exception:
            pass
        try:
            self.p.wait(timeout=5)
        except Exception:
            self.p.kill()


def find_markers(lines):
    out = []
    for i, line in enumerate(lines):
        for m in MARK.finditer(line):
            target = i
            if line.strip().startswith("--"):
                target = i + 1
            out.append((m.group(1), m.group("name"), m.group("at").replace("\\'", "'"),
                        (m.group("ins") or "").replace("\\'", "'"), target, i))
    return out


def item_label(it):
    return it["label"] if isinstance(it.get("label"), str) else str(it.get("label"))


def main():
    args = sys.argv[1:]
    mode = "vsc"
    max_items = 60
    files = []
    i = 0
    while i < len(args):
        if args[i] == "--mode":
            mode = args[i + 1]; i += 2
        elif args[i] == "--max-items":
            max_items = int(args[i + 1]); i += 2
        else:
            files.append(os.path.abspath(args[i])); i += 1
    snap = json.load(open(SNAP))
    if mode == "vsc":
        bin_, defs, ov = EXT, os.path.join(GS, "globalTypes.PluginSecurity.d.luau"), True
    elif mode == "sync":
        bin_, defs, ov = EXT, os.path.join(GS, "globalTypes.PluginSecurity.d.luau"), False
    elif mode == "pin":
        bin_ = subprocess.check_output(["mise", "which", "luau-lsp"], cwd=ROOT, text=True).strip()
        defs, ov = os.path.join(ROOT, "scripts/roblox-defs/globalTypes.d.luau"), True
    else:
        raise SystemExit("mode?")
    cmd = [bin_, "lsp", f"--definitions:@roblox={defs}", "--no-flags-enabled", "--stdio"]
    if mode in ("vsc", "sync"):
        cmd.insert(3, f"--docs={os.path.join(GS, 'api-docs.json')}")
    init_flags = flagsmod.build(snap, ov)
    root = os.path.dirname(files[0])
    t0 = time.time()
    c = Client(cmd, init_flags, root)
    print(f"# mode={mode} bin={bin_} defs={os.path.basename(defs)} flags={len(init_flags)} override={ov}")
    print(f"# initialize {time.time() - t0:.2f}s")
    for path in files:
        uri = "file://" + path
        text = open(path).read()
        lines = text.split("\n")
        print(f"\n## {os.path.basename(path)}")
        t_open = time.time()
        c.notify("textDocument/didOpen", {"textDocument": {"uri": uri, "languageId": "luau", "version": 1, "text": text}})
        t_d = c.wait_diags(uri, t_open)
        print(f"# first publishDiagnostics after open: {('%.2fs' % (t_d - t_open)) if t_d else 'TIMEOUT'}")
        # diagnostics may be re-published once dependencies are checked; give it a moment
        time.sleep(1.0)
        ds = sorted(c.diags.get(uri, []), key=lambda d: (d["range"]["start"]["line"], d["range"]["start"]["character"]))
        print(f"### diagnostics ({len(ds)})")
        for d in ds:
            s = d["range"]["start"]
            msg = d["message"].replace("\n", " ⏎ ")
            if len(msg) > 400:
                msg = msg[:400] + " …(truncated)"
            print(f"  L{s['line'] + 1}:{s['character'] + 1} [{d.get('code', '')}] {msg}")
        version = 1
        for kind, name, at, ins, target, mline in find_markers(lines):
            tl = lines[target]
            col = tl.find(at)
            if col < 0:
                print(f"### @{kind}({name}) L{target + 1}: substring not found: {at!r}")
                continue
            if kind == "c":
                col += len(at)
                new_lines = list(lines)
                if ins:
                    new_lines[target] = tl[:col] + ins + tl[col:]
                version += 1
                c.notify("textDocument/didChange", {"textDocument": {"uri": uri, "version": version},
                                                    "contentChanges": [{"text": "\n".join(new_lines)}]})
                tq = time.time()
                r = c.request("textDocument/completion", {"textDocument": {"uri": uri},
                                                          "position": {"line": target, "character": col + len(ins)}})
                dt = time.time() - tq
                res = r.get("result")
                items = res.get("items", []) if isinstance(res, dict) else (res or [])
                labels = [item_label(it) for it in items]
                # sort the way VSCode would show them: sortText then label
                items_sorted = sorted(items, key=lambda it: (it.get("sortText", it["label"]), it["label"]))
                print(f"### @c({name}) L{target + 1}:{col + 1} ins={ins!r} — {len(labels)} items, {dt:.2f}s")
                if ins:
                    pref = [it for it in items_sorted if item_label(it).lower().startswith(ins.lower())]
                    print(f"  prefix-matching {ins!r}: " + ", ".join(
                        f"{item_label(it)}<{it.get('kind')}>" + (f"[{it.get('detail')}]" if it.get('detail') else "")
                        for it in pref[:max_items]))
                fields = [it for it in items_sorted if it.get("kind") in (5, 10, 12, 20, 21)]  # Field/Property/Value/EnumMember/Constant
                others = [it for it in items_sorted if it.get("kind") not in (5, 10, 12, 20, 21)]
                print(f"  fields/values ({len(fields)}): " + ", ".join(
                    f"{item_label(it)}" + (f"[{it.get('detail')}]" if it.get('detail') and len(fields) <= 12 else "")
                    for it in fields[:max_items]) + (" …" if len(fields) > max_items else ""))
                print(f"  other kinds ({len(others)}): " + ", ".join(f"{item_label(it)}<{it.get('kind')}>" for it in others[:12]) + (" …" if len(others) > 12 else ""))
                # restore text
                version += 1
                c.notify("textDocument/didChange", {"textDocument": {"uri": uri, "version": version},
                                                    "contentChanges": [{"text": text}]})
            else:
                tq = time.time()
                r = c.request("textDocument/hover", {"textDocument": {"uri": uri},
                                                     "position": {"line": target, "character": col}})
                dt = time.time() - tq
                res = r.get("result")
                val = ""
                if res:
                    cont = res.get("contents")
                    val = cont.get("value") if isinstance(cont, dict) else str(cont)
                val = (val or "").replace("\n", " ⏎ ")
                if len(val) > 700:
                    val = val[:700] + " …(truncated)"
                print(f"### @h({name}) L{target + 1}:{col + 1} {dt:.2f}s — {val}")
        c.notify("textDocument/didClose", {"textDocument": {"uri": uri}})
    c.close()


if __name__ == "__main__":
    main()
