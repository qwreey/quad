#!/usr/bin/env python3
"""Extract internal <a href> links from dist/**/index.html and verify that
the target file exists in dist and, if there's a #fragment, that an element
with that id exists in the target file. Read-only: does not modify anything.
"""
import os
import re
import sys
import html
import urllib.parse
from collections import defaultdict

DIST = "/code/Projects/quad/docs/site/dist"

HREF_RE = re.compile(r'href="([^"]*)"')
ID_RE = re.compile(r'\bid="([^"]*)"')

def all_html_files():
    for root, dirs, files in os.walk(DIST):
        for f in files:
            if f == "index.html":
                yield os.path.join(root, f)

def ids_of(path, cache):
    if path in cache:
        return cache[path]
    if not os.path.isfile(path):
        cache[path] = None
        return None
    with open(path, encoding="utf-8", errors="replace") as fh:
        content = fh.read()
    ids = set(ID_RE.findall(content))
    cache[path] = ids
    return ids

STATIC_EXT = (".css", ".js", ".mjs", ".svg", ".xml", ".png", ".jpg", ".jpeg",
              ".ico", ".woff", ".woff2", ".ttf", ".json", ".webmanifest",
              ".txt", ".md")

def resolve_target(href, source_file):
    # strip scheme-external links
    if href.startswith(("http://", "https://", "mailto:", "tel:", "//")):
        return None
    if href.startswith("#"):
        return (source_file, href[1:])
    parsed = urllib.parse.urlsplit(href)
    path = parsed.path
    frag = parsed.fragment
    if path == "":
        target_dir = os.path.dirname(source_file)
        return (source_file, frag if frag else None)
    if path.startswith("/"):
        target_path = DIST + path
    else:
        target_path = os.path.normpath(os.path.join(os.path.dirname(source_file), path))
    # literal static file (has a known extension) -> check as a plain file, no anchor semantics
    lower = target_path.lower()
    if any(lower.endswith(ext) for ext in STATIC_EXT):
        return ("__STATIC__", target_path, frag if frag else None)
    # normalize to index.html file (page route)
    if os.path.isdir(target_path):
        target_file = os.path.join(target_path, "index.html")
    else:
        target_file = target_path + "/index.html" if not target_path.endswith(".html") else target_path
    return (target_file, frag if frag else None)

def main():
    id_cache = {}
    missing_files = []
    missing_anchors = []
    external_ok = 0
    checked = 0
    files = sorted(all_html_files())
    for src in files:
        with open(src, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
        hrefs = HREF_RE.findall(content)
        for raw in hrefs:
            href = html.unescape(raw)
            if href.startswith(("http://", "https://", "mailto:", "tel:", "//", "javascript:")):
                external_ok += 1
                continue
            if href in ("", "#"):
                continue
            resolved = resolve_target(href, src)
            if resolved is None:
                continue
            if resolved[0] == "__STATIC__":
                _, target_path, frag = resolved
                checked += 1
                if not os.path.isfile(target_path):
                    missing_files.append((src, href, target_path))
                continue
            target_file, frag = resolved
            checked += 1
            if not os.path.isfile(target_file):
                missing_files.append((src, href, target_file))
                continue
            if frag:
                ids = ids_of(target_file, id_cache)
                decoded_frag = urllib.parse.unquote(frag)
                if ids is not None and frag not in ids and decoded_frag not in ids:
                    missing_anchors.append((src, href, target_file, frag))

    rel = lambda p: os.path.relpath(p, DIST)
    print(f"Total html files: {len(files)}")
    print(f"Total internal-ish hrefs checked: {checked}")
    print(f"External/mailto/tel links skipped: {external_ok}")
    print()
    print(f"=== MISSING TARGET FILES ({len(missing_files)}) ===")
    for src, href, target in missing_files:
        print(f"{rel(src)}  ->  href=\"{href}\"  (resolved: {rel(target)})")
    print()
    print(f"=== MISSING ANCHORS ({len(missing_anchors)}) ===")
    for src, href, target, frag in missing_anchors:
        print(f"{rel(src)}  ->  href=\"{href}\"  (target file {rel(target)} has no id=\"{frag}\")")

if __name__ == "__main__":
    main()
