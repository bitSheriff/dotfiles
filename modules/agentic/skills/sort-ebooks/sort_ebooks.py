#!/usr/bin/env python3
"""Sort loose ebook files into one folder per book, grouped by series.

Dry-run by default; pass --apply to actually move files.
"""
import argparse
import hashlib
import re
import sys
from collections import defaultdict
from pathlib import Path

BOOK_EXTS = {
    ".epub", ".mobi", ".azw", ".azw3", ".pdf", ".cbz", ".cbr",
    ".djvu", ".fb2", ".txt", ".lit", ".m4b",
}
# Sidecars travel with the book that shares their stem (cover art, metadata).
SIDECAR_EXTS = {".jpg", ".jpeg", ".png", ".opf", ".nfo", ".json"}

# "<Series> <NN>[ und <NN>][ - Subtitle]" -> captures the series prefix.
SERIES_RE = re.compile(
    r"^(?P<prefix>.+?)[ _.\-]+"
    r"(?P<num>\d{1,3})"
    r"(?:[ _.\-]*(?:und|and|bis|to|[&+,])[ _.\-]*\d{1,3})?"
    r"(?=[ _.\-]|$)",
    re.IGNORECASE,
)


def series_prefix(stem: str) -> str | None:
    m = SERIES_RE.match(stem)
    if not m:
        return None
    prefix = m.group("prefix").strip(" _.-")
    # A bare number or a one-character prefix is noise, not a series name.
    return prefix if len(prefix) > 1 and not prefix.isdigit() else None


def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("directory", nargs="?", default=".", help="folder to sort (default: cwd)")
    ap.add_argument("--apply", action="store_true", help="perform the moves (default: dry run)")
    ap.add_argument("--min-series", type=int, default=2, metavar="N",
                    help="how many books must share a prefix to form a series (default: 2)")
    ap.add_argument("--series", action="append", default=[], metavar="NAME",
                    help="force NAME to be treated as a series (repeatable)")
    ap.add_argument("--no-series", action="append", default=[], metavar="NAME",
                    help="never treat NAME as a series (repeatable)")
    args = ap.parse_args()

    root = Path(args.directory).expanduser().resolve()
    if not root.is_dir():
        print(f"error: not a directory: {root}", file=sys.stderr)
        return 2

    # Only loose files at the top level; anything already in a subfolder is left alone.
    books: dict[str, list[Path]] = defaultdict(list)
    for p in sorted(root.iterdir()):
        if not p.is_file() or p.name.startswith("."):
            continue
        ext = p.suffix.lower()
        if ext in BOOK_EXTS or ext in SIDECAR_EXTS:
            books[p.stem].append(p)
    # Drop stems that are sidecars only (e.g. a stray cover.jpg with no book).
    books = {
        stem: files for stem, files in books.items()
        if any(f.suffix.lower() in BOOK_EXTS for f in files)
    }

    if not books:
        print(f"Nothing to sort in {root} (no loose ebook files).")
        return 0

    forced = {s.casefold() for s in args.series}
    blocked = {s.casefold() for s in args.no_series}

    counts: dict[str, int] = defaultdict(int)
    prefixes: dict[str, str | None] = {}
    for stem in books:
        pre = series_prefix(stem)
        prefixes[stem] = pre
        if pre:
            counts[pre] += 1

    def resolve_series(stem: str) -> str | None:
        for name in args.series:  # explicit override wins, prefix match
            if stem.casefold().startswith(name.casefold()):
                return name
        pre = prefixes[stem]
        if not pre or pre.casefold() in blocked:
            return None
        if counts[pre] >= args.min_series or pre.casefold() in forced:
            return pre
        return None

    plan: list[tuple[Path, Path]] = []  # (source file, destination folder)
    by_series: dict[str | None, list[str]] = defaultdict(list)
    for stem, files in sorted(books.items()):
        s = resolve_series(stem)
        by_series[s].append(stem)
        dest = (root / s / stem) if s else (root / stem)
        for f in files:
            plan.append((f, dest))

    # Report
    print(f"{root}\n{len(books)} book(s), {len(plan)} file(s)\n")
    for s in sorted(k for k in by_series if k is not None):
        print(f"  [Series] {s}/")
        for stem in by_series[s]:
            print(f"      {stem}/")
    if by_series.get(None):
        print("  [Standalone]")
        for stem in by_series[None]:
            print(f"      {stem}/")

    # Byte-identical duplicates are reported, never deleted.
    hashes: dict[str, list[str]] = defaultdict(list)
    for stem, files in books.items():
        for f in files:
            if f.suffix.lower() in BOOK_EXTS:
                hashes[md5(f)].append(f.name)
    dupes = [names for names in hashes.values() if len(names) > 1]
    if dupes:
        print("\n  ! Byte-identical duplicates (nothing deleted):")
        for names in dupes:
            print("      " + "  ==  ".join(sorted(names)))

    if not args.apply:
        print("\nDry run — nothing moved. Re-run with --apply to perform the moves.")
        return 0

    moved = skipped = 0
    for src, dest in plan:
        target = dest / src.name
        if target.exists():
            print(f"  skip (already exists): {target.relative_to(root)}")
            skipped += 1
            continue
        dest.mkdir(parents=True, exist_ok=True)
        src.rename(target)
        moved += 1
    print(f"\nDone: {moved} file(s) moved, {skipped} skipped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
