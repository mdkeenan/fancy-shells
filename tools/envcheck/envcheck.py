#!/usr/bin/env python
"""fsenvcheck - check that required CLI tools and env vars are present."""
import argparse
import json
import os
import shutil
import sys

DEFAULT_TOOLS = ["git", "python"]


def load_config(path):
    if not path or not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    parser = argparse.ArgumentParser(
        prog="fsenvcheck", description="Check that required CLI tools and env vars are present."
    )
    parser.add_argument("-t", "--tool", action="append", default=[], help="CLI tool to check for (repeatable)")
    parser.add_argument("-e", "--env", action="append", default=[], help="env var to check for (repeatable)")
    parser.add_argument(
        "-c", "--config", help="JSON config file with {\"tools\": [...], \"env\": [...]}"
    )
    args = parser.parse_args()

    config = load_config(args.config)
    tools = list(config.get("tools", [])) + args.tool
    env_vars = list(config.get("env", [])) + args.env

    if not tools and not env_vars:
        tools = DEFAULT_TOOLS

    ok = True

    if tools:
        print("Tools:")
        for name in tools:
            path = shutil.which(name)
            if path:
                print(f"  [OK]   {name}  ({path})")
            else:
                print(f"  [MISS] {name}  not found on PATH")
                ok = False

    if env_vars:
        print("\nEnvironment variables:")
        for name in env_vars:
            value = os.environ.get(name)
            if value is not None:
                shown = value if len(value) <= 40 else value[:37] + "..."
                print(f"  [OK]   {name}={shown}")
            else:
                print(f"  [MISS] {name}  not set")
                ok = False

    print()
    if ok:
        print("All checks passed.")
    else:
        print("Some checks failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()
