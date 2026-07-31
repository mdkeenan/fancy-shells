#!/usr/bin/env python
"""fssift - search/filter lines in a file by pattern (mini-grep)."""
import argparse
import re
import sys


def main():
    parser = argparse.ArgumentParser(
        prog="fssift",
        description="Search a file for lines matching a pattern.",
    )
    parser.add_argument("pattern", help="regex pattern to search for")
    parser.add_argument("file", help="path to the file to search")
    parser.add_argument(
        "-i", "--ignore-case", action="store_true", help="case-insensitive match"
    )
    parser.add_argument(
        "-v", "--invert", action="store_true", help="show lines that do NOT match"
    )
    parser.add_argument(
        "-n", "--line-numbers", action="store_true", help="show line numbers"
    )
    args = parser.parse_args()

    flags = re.IGNORECASE if args.ignore_case else 0
    try:
        regex = re.compile(args.pattern, flags)
    except re.error as exc:
        print(f"fssift: invalid pattern: {exc}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(args.file, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError as exc:
        print(f"fssift: {exc}", file=sys.stderr)
        sys.exit(1)

    matches = 0
    for i, line in enumerate(lines, start=1):
        found = regex.search(line) is not None
        if found != args.invert:
            matches += 1
            text = line.rstrip("\n")
            if args.line_numbers:
                print(f"{i}: {text}")
            else:
                print(text)

    sys.exit(0 if matches else 1)


if __name__ == "__main__":
    main()
