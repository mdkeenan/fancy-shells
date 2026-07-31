#!/usr/bin/env python
"""fsdirsize - show the largest files/subfolders under a directory."""
import argparse
import os
import sys


def human_size(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def dir_size(path):
    total = 0
    for root, _dirs, files in os.walk(path):
        for name in files:
            fp = os.path.join(root, name)
            try:
                total += os.path.getsize(fp)
            except OSError:
                pass
    return total


def main():
    parser = argparse.ArgumentParser(prog="fsdirsize", description="Show the largest files/subfolders under a directory.")
    parser.add_argument("folder", nargs="?", default=".", help="folder to scan (default: current directory)")
    parser.add_argument("-n", "--top", type=int, default=10, help="how many entries to show (default: 10)")
    parser.add_argument("--files", action="store_true", help="scan individual files instead of top-level subfolders")
    args = parser.parse_args()

    root = args.folder
    if not os.path.isdir(root):
        print(f"fsdirsize: not a directory: {root}", file=sys.stderr)
        sys.exit(1)

    entries = []
    if args.files:
        for dirpath, _dirs, files in os.walk(root):
            for name in files:
                fp = os.path.join(dirpath, name)
                try:
                    entries.append((os.path.getsize(fp), fp))
                except OSError:
                    pass
    else:
        with os.scandir(root) as it:
            for entry in it:
                try:
                    if entry.is_dir(follow_symlinks=False):
                        entries.append((dir_size(entry.path), entry.path))
                    elif entry.is_file(follow_symlinks=False):
                        entries.append((entry.stat().st_size, entry.path))
                except OSError:
                    pass

    entries.sort(key=lambda e: e[0], reverse=True)

    if not entries:
        print("Nothing found.")
        return

    for size, path in entries[: args.top]:
        print(f"{human_size(size):>10}  {path}")


if __name__ == "__main__":
    main()
