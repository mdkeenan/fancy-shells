# Tools

How to use each `fs*` command shipped with fancy-shells.

The 13 tools fall into four groups:

- **Files:** `fssift`, `fsjsonfmt`, `fsrenamer`, `fsdirsize`, `fsbackup`
- **Git:** `fsgstat`, `fsgclean`, `fsgwip`
- **System:** `fssysinfo`, `fsenvcheck`, `fspw`
- **Notes:** `fsjott`, `fstodo`

## Setup

Install fancy-shells (prompt + tools) with the project installer. From a local checkout:

```powershell
.\install-fancy-shells.ps1
```

```bash
./install-fancy-shells.sh
```

Or use the one-liners in [README.md](README.md). Re-running install upgrades or reinstalls safely (see versioning there).

The installer:

1. Resolves the install root in order: local checkout (if run from this repo) → path in `~/.fancy-shells-home` (if valid) → clone/update `~/fancy-shells`
2. Creates `tools/venv` and installs dependencies (`psutil`, needed for `fssysinfo`)
3. Writes `~/.fancy-shells-home` and `~/.fancy-shells-version`
4. Installs the Bash or PowerShell config, which prepends `tools/bin` to `PATH`

After install, run any tool by name (e.g. `fssift <pattern> <file>`). Check the installed version with `Get-Content ~/.fancy-shells-version` (PowerShell) or `cat ~/.fancy-shells-version` (Bash).

---

## fssift — search/filter lines in a file

```
fssift <pattern> <file> [options]
```

| Flag | Meaning |
|------|---------|
| `-i`, `--ignore-case` | Case-insensitive match |
| `-v`, `--invert` | Show lines that do NOT match |
| `-n`, `--line-numbers` | Prefix each match with its line number |

Examples:

```
fssift "TODO" notes.txt
fssift -in "error" app.log
```

---

## fsjott — quick notes/journal

Notes are stored in `tools/jott/notes.local.json`, which is git-ignored and never committed.
Each note gets a sequential id, shown in brackets (e.g. `[3]`) by `list` and `search` —
that's the id `remove` expects, not an arbitrary number you pick.

```
fsjott add <text...>
fsjott list [-n COUNT]
fsjott search <query>
fsjott remove <id>
```

Examples:

```
fsjott add Remember to update the README
fsjott list -n 5
```

```
[1] 2026-07-24 09:12:03  Remember to update the README
```

```
fsjott search README
fsjott remove 1
```

`remove 1` deletes the note with id `1` — the id shown by `list`/`search` above, not a
line number or position in the list.

---

## fspw — password/passphrase generator

```
fspw [options]
```

| Flag | Meaning |
|------|---------|
| `-l`, `--length` | Password length (default: 16) |
| `-n`, `--count` | How many to generate |
| `--no-symbols` | Exclude symbols |
| `--no-digits` | Exclude digits |
| `--no-upper` | Exclude uppercase letters |
| `-p`, `--passphrase` | Generate a word-based passphrase instead |
| `-w`, `--words` | Number of words in passphrase (default: 4) |
| `-s`, `--separator` | Separator between passphrase words (default: `-`) |

Examples:

```
fspw -l 24 -n 3
fspw --passphrase --words 5 --separator "_"
```

---

## fssysinfo — system snapshot

```
fssysinfo
```

Prints hostname, OS, Python version, local IP, CPU core count/usage, memory usage, and
disk usage for the current drive.

**Note:** CPU and memory details require `psutil` — see [Setup](#setup). Without it,
`fssysinfo` still runs, but prints a warning and skips those two lines.

---

## fsrenamer — batch rename files

**Warning — dry-run by default:** always shows the planned renames before touching
anything. Nothing is renamed until you pass `--apply`.

```
fsrenamer <folder> [options]
```

| Flag | Meaning |
|------|---------|
| `--prefix TEXT` | Prepend text to each filename |
| `--suffix TEXT` | Append text to each filename (before extension) |
| `--case {lower,upper,title}` | Change case of filename |
| `--number` | Append a sequential number to each filename |
| `--number-width N` | Zero-padding width for `--number` (default: 3) |
| `--apply` | Actually perform the rename (omit for dry-run) |

Case, prefix/suffix, and numbering are applied in that order — case only affects the
original filename, so a prefix or suffix you add is never re-cased. Extensions are
split on the last `.` (so `a.b.c.txt` keeps `.txt`).

Examples:

```
fsrenamer .\photos --prefix vacation_ --number
fsrenamer .\photos --prefix vacation_ --number --apply
```

The first command only prints the planned renames (e.g. `photo1.jpg -> vacation_photo1_001.jpg`);
nothing on disk changes until the second command, with `--apply`, is run.

---

## fsgclean — delete merged git branches

Run from inside any git repo. Compares local branches against `main`/`master` (or
`--base <branch>`) and offers to delete the ones already merged.

```
fsgclean [-y] [--base BRANCH]
```

| Flag | Meaning |
|------|---------|
| `-y`, `--yes` | Delete without confirmation prompt |
| `--base BRANCH` | Base branch to compare against (default: `main` or `master`) |

---

## fsgstat — quick repo summary

Run from inside any git repo.

```
fsgstat
```

Prints current branch, whether the working tree is dirty, ahead/behind vs upstream (if
set), commits per author, and the last 5 commits.

---

## fsgwip — quick WIP commit

Run from inside any git repo. Stages everything and commits.

```
fsgwip [message...]
```

Examples:

```
fsgwip
fsgwip fixing the login bug
```

If no message is given, the commit message is a timestamp like `WIP: 2026-07-24 13:05:02`.
If the working tree is already clean, it prints a message and does nothing — it won't
create an empty commit.

---

## fstodo — task list

Tasks are stored in `tools/todo/tasks.local.json`, which is git-ignored and never committed.
Like `fsjott`, each task gets a sequential id shown by `list` — that's the id `done`
and `remove` expect.

```
fstodo add <text...>
fstodo list [-a]
fstodo done <id>
fstodo remove <id>
```

`list` shows only pending tasks by default; use `-a`/`--all` to include done ones.

Examples:

```
fstodo add write the docs
fstodo list
```

```
[ ] #1  write the docs
```

```
fstodo done 1
```

`done 1` marks the task with id `1` as complete (the id shown in `#1` above) — it doesn't
delete it. Use `remove 1` instead if you want it gone entirely.

---

## fsdirsize — largest files/subfolders

```
fsdirsize [folder] [options]
```

| Flag | Meaning |
|------|---------|
| `-n`, `--top` | How many entries to show (default: 10) |
| `--files` | Scan individual files recursively instead of top-level subfolders |

By default, entries are the immediate children of `folder` (each subfolder's size is the
total of everything inside it, computed recursively, but shown as a single line). With
`--files`, every file under `folder` at any depth is listed individually instead.

Examples:

```
fsdirsize
fsdirsize ~/Downloads -n 20 --files
```

---

## fsenvcheck — environment doctor

Checks that CLI tools are on PATH and env vars are set. With no arguments, checks for
`git` and `python`.

```
fsenvcheck [-t TOOL]... [-e VAR]... [-c CONFIG.json]
```

| Flag | Meaning |
|------|---------|
| `-t`, `--tool` | CLI tool to check for (repeatable) |
| `-e`, `--env` | Env var to check for (repeatable) |
| `-c`, `--config` | JSON file with `{"tools": [...], "env": [...]}` |

Examples:

```
fsenvcheck -t git -t node -t docker -e GITHUB_TOKEN
```

**Tip — scripting:** exits with a non-zero status if anything is missing, so it can gate
a script or CI step.

---

## fsjsonfmt — pretty-print / query JSON

```
fsjsonfmt <file> [options]
```

| Flag | Meaning |
|------|---------|
| `-q`, `--query` | Dot-path to extract, e.g. `user.name` or `items.0.id` |
| `-c`, `--compact` | Compact output instead of pretty-printed |
| `--validate` | Only validate the JSON, no output on success |

A dot-path like `items.0.id` walks into the parsed JSON step by step: `items` looks up a
key (or, if the current value is a list, `0` is used as a list index), then `id` looks up
the next key. It's not a literal string key in the JSON file — it's a path you build to
navigate into nested objects and arrays.

Examples:

```
fsjsonfmt data.json
fsjsonfmt data.json -q user.tags.0
fsjsonfmt data.json --validate
```

Given `{"user": {"tags": ["admin", "beta"]}}` in `data.json`, `-q user.tags.0` prints
`"admin"` — the first (index `0`) element of the `tags` array under `user`.

---

## fsbackup — zip a folder with a timestamp

```
fsbackup <folder> [options]
```

| Flag | Meaning |
|------|---------|
| `-o`, `--output` | Output directory for the zip (default: current directory) |
| `-n`, `--name` | Base name for the archive (default: folder name) |

The zip's contents are whatever is *inside* `folder`, not a folder itself — unzipping
`important_folder_20260724_090000.zip` extracts the files directly, without an enclosing
`important_folder/` directory.

Examples:

```
fsbackup ./important_folder
fsbackup ./important_folder -o ./backups -n project_snapshot
```
