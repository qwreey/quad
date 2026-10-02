#!/usr/bin/env python3
"""PreToolUse(Bash) guard: heavy runs (bench/fuzz/perf/stress) must be wrapped in choom.

Why: the container's memory cgroup is shared with every Claude session. A benchmark that
eats the remaining headroom triggers the cgroup OOM killer, which picks by oom_score —
and once killed a Claude process (2026-09-28, Q135 bench exit 137). We cannot lower
Claude's score (no CAP_SYS_RESOURCE), but raising a child's score is unprivileged and
inherited across exec, so `choom -n 1000 -- <cmd>` makes the heavy tree the first victim.

Heuristic (cheap on purpose — a false positive only costs a retry with choom):
  block when the command mentions a heavy keyword AND some segment executes a program
  (luau / lune / bash / sh / python / node / hyperfine / ./x.sh), unless the command
  already contains `choom` or is a git/gh command (commit messages mention these words).
"""
import json
import re
import sys

HEAVY = re.compile(r"(?<![A-Za-z])(bench|fuzz|perf|stress|soak|load-?test|hyperfine)", re.I)
EXECUTORS = {"luau", "lune", "bash", "sh", "zsh", "python", "python3", "node", "hyperfine"}
PREFIX_WORDS = {"(", "{", "time", "nice", "env", "command", "exec", "nohup"}
EXEMPT_HEADS = {"git", "gh"}


def segment_heads(cmd):
    for seg in re.split(r"&&|\|\||[;|\n]", cmd):
        words = seg.replace("(", " ( ").split()
        i = 0
        while i < len(words):
            w = words[i]
            if w in PREFIX_WORDS or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=\S*", w):
                i += 1
            elif w == "timeout":
                i += 1
                while i < len(words) and (words[i].startswith("-") or re.fullmatch(r"[\d.]+[smhd]?", words[i])):
                    i += 2 if words[i] in ("-s", "-k", "--signal", "--kill-after") else 1
            elif w == "mise" and i + 1 < len(words) and words[i + 1] == "exec":
                i += 2
                if i < len(words) and words[i] == "--":
                    i += 1
            else:
                break
        if i < len(words):
            yield words[i]


def is_executor(head):
    return head in EXECUTORS or head.endswith(".sh") or head.startswith("./")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    cmd = (data.get("tool_input") or {}).get("command") or ""
    # agy-delegate.sh puts choom in front of its own setpriv launch, so the whole agy tree
    # is already the preferred victim; its prompt text may mention bench/perf freely.
    if "choom" in cmd or "agy-delegate.sh" in cmd or not HEAVY.search(cmd):
        return 0
    heads = list(segment_heads(cmd))
    if heads and heads[0] in EXEMPT_HEADS:
        return 0
    if not any(is_executor(h) for h in heads):
        return 0
    reason = (
        "heavy-proc-guard: 벤치/퍼저/성능 실측으로 보이는 실행은 OOM 희생자 순위를 올려서 띄울 것 "
        "(컨테이너 cgroup OOM이 Claude 프로세스를 죽인 적 있음 — conventions.md 2026-10-02 항목). "
        "명령 맨 앞에 `choom -n 1000 -p $$;`를 붙이거나(이 셸과 그 자식 전부가 1순위 희생자가 된다) "
        "`choom -n 1000 -- prlimit --data=3221225472 -- <명령>`으로 감싸 다시 실행하라. "
        "무거운 실행이 아닌데 걸렸다면(오탐) 같은 방법으로 감싸면 통과한다."
    )
    json.dump({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
