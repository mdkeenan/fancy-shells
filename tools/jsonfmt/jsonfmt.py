#!/usr/bin/env python
"""fsjsonfmt - pretty-print, validate, and query JSON files by dot-path."""
import argparse
import json
import sys


def get_path(data, path):
    if not path:
        return data
    current = data
    for part in path.split("."):
        if isinstance(current, list):
            try:
                current = current[int(part)]
            except (ValueError, IndexError):
                raise KeyError(path)
        elif isinstance(current, dict):
            if part not in current:
                raise KeyError(path)
            current = current[part]
        else:
            raise KeyError(path)
    return current


def main():
    parser = argparse.ArgumentParser(prog="fsjsonfmt", description="Pretty-print, validate, and query JSON files.")
    parser.add_argument("file", help="path to the JSON file")
    parser.add_argument("-q", "--query", help="dot-path to extract, e.g. 'user.name' or 'items.0.id'")
    parser.add_argument("-c", "--compact", action="store_true", help="compact output instead of pretty-printed")
    parser.add_argument("--validate", action="store_true", help="only validate the JSON, print nothing on success")
    args = parser.parse_args()

    try:
        with open(args.file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except OSError as exc:
        print(f"fsjsonfmt: {exc}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"fsjsonfmt: invalid JSON: {exc}", file=sys.stderr)
        sys.exit(1)

    if args.validate:
        return

    if args.query:
        try:
            data = get_path(data, args.query)
        except KeyError:
            print(f"fsjsonfmt: path not found: {args.query}", file=sys.stderr)
            sys.exit(1)

    if args.compact:
        print(json.dumps(data, separators=(",", ":")))
    else:
        print(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
