#!/usr/bin/env bash
# E56 재실행: relink → strict(주석 전·문서 안·최소·우회·how-to 01·탐침) → mock 비교
set -u
cd "$(dirname "$0")"
( cd ../../.. && ./scripts/relink.sh >/dev/null )
./strict.sh bare/*.luau bare/mod/*.luau > out/bare-strict.txt
./strict.sh annotated/*.luau annotated/mod/*.luau > out/annotated-strict.txt
./strict.sh minimal/mod/*.luau > out/minimal-strict.txt
./strict.sh workaround/*.luau > out/workaround-strict.txt
./strict.sh howto01/howto01-chain.luau > out/howto01-strict.txt
./strict.sh probes/*.luau probes/mixed/*.luau > out/probes-strict.txt
for f in bare annotated minimal workaround howto01; do printf '%-11s %s\n' "$f" "$(grep -cE "^$f/.*TypeError" out/$f-strict.txt)"; done
luau mock-modules.luau -a bare > out/mock-bare.txt && luau mock-modules.luau -a annotated > out/mock-annotated.txt && diff -q out/mock-bare.txt out/mock-annotated.txt && echo "mock modules: identical"
luau mock-runtime-edits.luau > out/mock-runtime-edits.txt && cat out/mock-runtime-edits.txt
