#!/usr/bin/env python
"""fsgwip - stage everything and commit as a quick work-in-progress checkpoint."""
import argparse
import subprocess
import sys
from datetime import datetime


def run_git(args, check=True):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"fsgwip: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    return result


def main():
    parser = argparse.ArgumentParser(prog="fsgwip", description="Stage and commit all changes as a WIP checkpoint.")
    parser.add_argument("message", nargs="*", help="optional commit message (default: timestamped WIP)")
    args = parser.parse_args()

    status = run_git(["status", "--porcelain"]).stdout
    if not status.strip():
        print("Nothing to commit, working tree clean.")
        return

    run_git(["add", "-A"])

    if args.message:
        commit_message = " ".join(args.message)
    else:
        commit_message = f"WIP: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"

    run_git(["commit", "-m", commit_message])
    print(f"Committed: {commit_message}")


if __name__ == "__main__":
    main()
