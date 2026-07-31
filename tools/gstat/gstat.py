#!/usr/bin/env python
"""fsgstat - quick repo summary: commits per author, status, current branch."""
import argparse
import subprocess
import sys


def run_git(args, check=True):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"fsgstat: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    return result


def main():
    parser = argparse.ArgumentParser(prog="fsgstat", description="Quick summary of the current git repo.")
    parser.parse_args()

    branch = run_git(["branch", "--show-current"]).stdout.strip() or "(detached HEAD)"
    status = run_git(["status", "--porcelain"]).stdout
    dirty = "yes" if status.strip() else "no"

    print(f"Branch:        {branch}")
    print(f"Uncommitted changes: {dirty}")
    if status.strip():
        changed = len(status.strip().splitlines())
        print(f"  ({changed} file(s) changed)")

    ahead_behind = run_git(["rev-list", "--left-right", "--count", "HEAD...@{u}"], check=False)
    if ahead_behind.returncode == 0:
        ahead, behind = ahead_behind.stdout.strip().split()
        print(f"Ahead/behind:  +{ahead} / -{behind} (vs upstream)")

    print("\nCommits per author:")
    shortlog = run_git(["shortlog", "-sn", "--all"], check=False)
    print(shortlog.stdout.rstrip() or "  (no commits yet)")

    print("\nLast 5 commits:")
    log = run_git(["log", "-5", "--oneline"], check=False)
    print(log.stdout.rstrip() or "  (no commits yet)")


if __name__ == "__main__":
    main()
