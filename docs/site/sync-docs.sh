#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_KO="$SCRIPT_DIR/src/content/docs/ko"

echo "Syncing documentation from $DOCS_SRC to $DEST_KO..."

TRACKS=("overview" "getting-started" "how-to" "quadnomicon" "reference")

for track in "${TRACKS[@]}"; do
  src_dir="$DOCS_SRC/$track"
  dest_dir="$DEST_KO/$track"
  if [ -d "$src_dir" ]; then
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"
    for file in "$src_dir"/*.md; do
      [ -f "$file" ] || continue
      filename="$(basename "$file")"
      dest_file="$dest_dir/$filename"
      
            # 상대 링크 ../<track>/<file>.md (또는 ./<file>.md) -> /quad/ko/<track>/<file>/
      sed -E -e 's#\]\(\.\./([a-z-]+)/([0-9a-zA-Z_-]+)\.md\)#](/quad/ko/\1/\2/)#g' -e "s#\]\(\./([0-9a-zA-Z_-]+)\.md\)#](/quad/ko/$track/\1/)#g" "$file" > "$dest_file"
    done
    echo "  ✓ Synced $track"
  fi
done

echo "Documentation sync complete!"
