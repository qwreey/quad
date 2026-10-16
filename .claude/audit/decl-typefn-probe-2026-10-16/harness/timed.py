#!/usr/bin/env python3
"""timed.py <mode> <file> — run run-cli.sh, print wall time, children max RSS, TypeError count, too-complex count."""
import resource, subprocess, sys, time, os
here = os.path.dirname(os.path.abspath(__file__))
t = time.time()
out = subprocess.run([os.path.join(here, "run-cli.sh"), sys.argv[1], *sys.argv[2:]], capture_output=True, text=True, timeout=900).stdout
rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss // 1024
print(f"{sys.argv[1]} {os.path.basename(sys.argv[2])}(+{len(sys.argv)-3}): {time.time()-t:.2f}s {rss}MiB TypeError={out.count('TypeError')} complex={out.count('too complex')}")
