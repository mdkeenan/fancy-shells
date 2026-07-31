#!/usr/bin/env python
"""fsgclean - list and delete local git branches already merged into main/master."""
import argparse
import subprocess
import sys


def run_git(args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"fsgclean: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    return result.stdout


def get_default_branch():
    for candidate in ("main", "master"):
        result = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{candidate}"]
        )
        if result.returncode == 0:
            return candidate
    print("fsgclean: could not find a local 'main' or 'master' branch", file=sys.stderr)
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        prog="fsgclean", description="Delete local branches already merged into main/master."
    )
    parser.add_argument("-y", "--yes", action="store_true", help="delete without confirmation prompt")
    parser.add_argument("--base", help="base branch to compare against (default: main or master)")
    args = parser.parse_args()

    base = args.base or get_default_branch()
    current = run_git(["branch", "--show-current"]).strip()

    output = run_git(["branch", "--merged", base])
    candidates = []
    for line in output.splitlines():
        name = line.strip().lstrip("* ").strip()
        if name and name not in (base, current):
            candidates.append(name)

    if not candidates:
        print(f"No merged branches to clean up (base: {base}).")
        return

    print(f"Branches merged into '{base}':")
    for name in candidates:
        print(f"  {name}")

    if not args.yes:
        answer = input(f"\nDelete these {len(candidates)} branch(es)? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted.")
            return

    for name in candidates:
        run_git(["branch", "-d", name])
        print(f"Deleted {name}")


if __name__ == "__main__":
    main()
