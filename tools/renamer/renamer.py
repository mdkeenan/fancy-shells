#!/usr/bin/env python
"""fsrenamer - batch-rename files in a folder by pattern (dry-run by default)."""
import argparse
import sys
from pathlib import Path


def build_new_name(name, args, index):
    if "." in name:
        stem, ext = name.rsplit(".", 1)
        ext = f".{ext}"
    else:
        stem, ext = name, ""

    if args.case == "lower":
        stem = stem.lower()
    elif args.case == "upper":
        stem = stem.upper()
    elif args.case == "title":
        stem = stem.title()

    if args.prefix:
        stem = f"{args.prefix}{stem}"
    if args.suffix:
        stem = f"{stem}{args.suffix}"
    if args.number:
        stem = f"{stem}_{index:0{args.number_width}d}"

    return f"{stem}{ext}"


def main():
    parser = argparse.ArgumentParser(prog="fsrenamer", description="Batch-rename files in a folder.")
    parser.add_argument("folder", help="folder containing files to rename")
    parser.add_argument("--prefix", default="", help="text to prepend to each filename")
    parser.add_argument("--suffix", default="", help="text to append to each filename (before extension)")
    parser.add_argument("--case", choices=["lower", "upper", "title"], help="change case of filename")
    parser.add_argument("--number", action="store_true", help="append a sequential number to each filename")
    parser.add_argument("--number-width", type=int, default=3, help="zero-padding width for --number (default: 3)")
    parser.add_argument("--apply", action="store_true", help="actually perform the rename (default is dry-run)")
    args = parser.parse_args()

    folder = Path(args.folder)
    if not folder.is_dir():
        print(f"fsrenamer: not a directory: {folder}", file=sys.stderr)
        sys.exit(1)

    files = sorted(p for p in folder.iterdir() if p.is_file())
    if not files:
        print("No files found.")
        return

    plan = []
    for i, path in enumerate(files, start=1):
        new_name = build_new_name(path.name, args, i)
        if new_name != path.name:
            plan.append((path, path.with_name(new_name)))

    if not plan:
        print("No renames needed.")
        return

    for old, new in plan:
        print(f"{old.name}  ->  {new.name}")

    if not args.apply:
        print(f"\n{len(plan)} file(s) would be renamed. Re-run with --apply to perform it.")
        return

    renamed = 0
    for old, new in plan:
        if new.exists():
            print(f"fsrenamer: skipping, target exists: {new.name}", file=sys.stderr)
            continue
        old.rename(new)
        renamed += 1

    print(f"\nRenamed {renamed} file(s).")


if __name__ == "__main__":
    main()
