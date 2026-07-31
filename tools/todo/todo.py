#!/usr/bin/env python
"""fstodo - simple task list with pending/done status."""
import argparse
import json
import os
import sys
from datetime import datetime

STORE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tasks.local.json")


def load_tasks():
    if not os.path.exists(STORE_PATH):
        return []
    with open(STORE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def save_tasks(tasks):
    with open(STORE_PATH, "w", encoding="utf-8") as f:
        json.dump(tasks, f, indent=2)


def cmd_add(args):
    tasks = load_tasks()
    task = {
        "id": (tasks[-1]["id"] + 1) if tasks else 1,
        "text": " ".join(args.text),
        "done": False,
        "created": datetime.now().isoformat(timespec="seconds"),
    }
    tasks.append(task)
    save_tasks(tasks)
    print(f"Added task #{task['id']}")


def cmd_list(args):
    tasks = load_tasks()
    if not args.all:
        tasks = [t for t in tasks if not t["done"]]
    if not tasks:
        print("No tasks." if not args.all else "No tasks yet.")
        return
    for t in tasks:
        mark = "x" if t["done"] else " "
        print(f"[{mark}] #{t['id']}  {t['text']}")


def cmd_done(args):
    tasks = load_tasks()
    for t in tasks:
        if t["id"] == args.id:
            t["done"] = True
            save_tasks(tasks)
            print(f"Marked #{args.id} as done")
            return
    print(f"fstodo: no task with id {args.id}", file=sys.stderr)
    sys.exit(1)


def cmd_remove(args):
    tasks = load_tasks()
    remaining = [t for t in tasks if t["id"] != args.id]
    if len(remaining) == len(tasks):
        print(f"fstodo: no task with id {args.id}", file=sys.stderr)
        sys.exit(1)
    save_tasks(remaining)
    print(f"Removed task #{args.id}")


def main():
    parser = argparse.ArgumentParser(prog="fstodo", description="Simple task list with pending/done status.")
    sub = parser.add_subparsers(dest="command", required=True)

    p_add = sub.add_parser("add", help="add a new task")
    p_add.add_argument("text", nargs="+", help="task text")
    p_add.set_defaults(func=cmd_add)

    p_list = sub.add_parser("list", help="list tasks (pending by default)")
    p_list.add_argument("-a", "--all", action="store_true", help="include done tasks")
    p_list.set_defaults(func=cmd_list)

    p_done = sub.add_parser("done", help="mark a task as done")
    p_done.add_argument("id", type=int, help="task id")
    p_done.set_defaults(func=cmd_done)

    p_remove = sub.add_parser("remove", help="remove a task")
    p_remove.add_argument("id", type=int, help="task id")
    p_remove.set_defaults(func=cmd_remove)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
