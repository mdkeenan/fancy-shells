#!/usr/bin/env python
"""fsjott - quick command-line notes/journal."""
import argparse
import json
import os
import sys
from datetime import datetime

STORE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "notes.local.json")


def load_notes():
    if not os.path.exists(STORE_PATH):
        return []
    with open(STORE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def save_notes(notes):
    with open(STORE_PATH, "w", encoding="utf-8") as f:
        json.dump(notes, f, indent=2)


def cmd_add(args):
    notes = load_notes()
    note = {
        "id": (notes[-1]["id"] + 1) if notes else 1,
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "text": " ".join(args.text),
    }
    notes.append(note)
    save_notes(notes)
    print(f"Added note #{note['id']}")


def cmd_list(args):
    notes = load_notes()
    if not notes:
        print("No notes yet.")
        return
    for note in notes[-args.count:]:
        print(f"[{note['id']}] {note['timestamp']}  {note['text']}")


def cmd_search(args):
    notes = load_notes()
    query = args.query.lower()
    hits = [n for n in notes if query in n["text"].lower()]
    if not hits:
        print("No matching notes.")
        return
    for note in hits:
        print(f"[{note['id']}] {note['timestamp']}  {note['text']}")


def cmd_remove(args):
    notes = load_notes()
    remaining = [n for n in notes if n["id"] != args.id]
    if len(remaining) == len(notes):
        print(f"fsjott: no note with id {args.id}", file=sys.stderr)
        sys.exit(1)
    save_notes(remaining)
    print(f"Removed note #{args.id}")


def main():
    parser = argparse.ArgumentParser(prog="fsjott", description="Quick command-line notes/journal.")
    sub = parser.add_subparsers(dest="command", required=True)

    p_add = sub.add_parser("add", help="add a new note")
    p_add.add_argument("text", nargs="+", help="note text")
    p_add.set_defaults(func=cmd_add)

    p_list = sub.add_parser("list", help="list recent notes")
    p_list.add_argument("-n", "--count", type=int, default=10, help="how many recent notes to show")
    p_list.set_defaults(func=cmd_list)

    p_search = sub.add_parser("search", help="search notes by keyword")
    p_search.add_argument("query", help="keyword to search for")
    p_search.set_defaults(func=cmd_search)

    p_remove = sub.add_parser("remove", help="remove a note by id")
    p_remove.add_argument("id", type=int, help="note id to remove")
    p_remove.set_defaults(func=cmd_remove)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
