#!/usr/bin/env python
"""fsbackup - zip up a folder with a timestamp for a quick manual snapshot."""
import argparse
import os
import shutil
import sys
from datetime import datetime


def main():
    parser = argparse.ArgumentParser(prog="fsbackup", description="Zip a folder with a timestamp.")
    parser.add_argument("folder", help="folder to back up")
    parser.add_argument("-o", "--output", help="output directory for the zip (default: current directory)")
    parser.add_argument("-n", "--name", help="base name for the archive (default: folder name)")
    args = parser.parse_args()

    source = os.path.abspath(args.folder)
    if not os.path.isdir(source):
        print(f"fsbackup: not a directory: {args.folder}", file=sys.stderr)
        sys.exit(1)

    base_name = args.name or os.path.basename(source.rstrip(os.sep))
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = args.output or "."
    os.makedirs(out_dir, exist_ok=True)
    archive_base = os.path.join(out_dir, f"{base_name}_{timestamp}")

    archive_path = shutil.make_archive(archive_base, "zip", root_dir=source)
    size = os.path.getsize(archive_path)
    print(f"Created {archive_path} ({size / (1024 * 1024):.2f} MB)")


if __name__ == "__main__":
    main()
