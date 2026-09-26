#!/usr/bin/env bash
# E58: mock 실행 전부 → out/mock/<key>.txt, 요약 out/mock-summary.tsv (END 도달 여부)
cd "$(dirname "$0")"
mkdir -p out/mock
: > out/mock-summary.tsv
for f in mock/*.luau; do
	k=$(basename "$f" .luau)
	timeout 20 luau "$f" > "out/mock/$k.txt" 2>&1; rc=$?
	if grep -q "<<END>>" "out/mock/$k.txt"; then st=END; else st=FAIL; fi
	printf '%s\t%s\t%s\n' "$k" "$rc" "$st" >> out/mock-summary.tsv
done
awk -F'\t' '{c[$3]++} END{for(k in c) print k, c[k]}' out/mock-summary.tsv
