#!/usr/bin/env bash
# usage: cmp.sh <labelA> <labelB>
cd /tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root/out
A=$1; B=$2
for f in e3fuzz e3counters e1reent_excl throw; do echo "## $f"; diff "$A/$f.txt" "$B/$f.txt"; done
for f in e1reent_unm e1reent_anc; do echo "## $f"; tail -n 1 "$A/$f.txt" | cut -c1-220; tail -n 1 "$B/$f.txt" | cut -c1-220; done
for f in obseff e1b e3 osc q109 q110 e79 e20-a e20-b e20-c e20-c2b e20-c3 e20-d e20-d3 e20-e e20-g e20-h; do
  echo "## $f"
  sed -E 's/\(-?[0-9.]+ ms\)//g' "$A/$f.txt" > /tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root/.a
  sed -E 's/\(-?[0-9.]+ ms\)//g' "$B/$f.txt" > /tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root/.b
  diff /tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root/.a /tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/obs-eff-root/.b | head -60
done
