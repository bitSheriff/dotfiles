---
name: sort-ebooks
description: Sorts loose ebook files (epub, pdf, mobi, ...) into one folder per book, grouping books of a series into a shared series folder. Use when the user wants to tidy up / organize / sort a folder of ebooks or an ebook collection into folders per book or per series.
allowed-tools: Bash, Read, Glob
---

Sort a folder of loose ebook files into this structure:

```
Series Name/
    Series Name 01 - Title/
        Series Name 01 - Title.epub
Standalone Book/
    Standalone Book.epub
```

Rules: one folder per book, folder name = filename without the extension. Books
belonging to a series go into a shared series folder. Files are **only moved** —
never renamed, never deleted.

## Procedure

1. **Determine the target folder.** The folder the user named, otherwise the current
   working directory. If it is ambiguous, ask once instead of guessing.

2. **Dry run.** The script sits next to this file:

   ```bash
   python3 ~/.claude/skills/sort-ebooks/sort_ebooks.py "<folder>"
   ```

   It detects series from the pattern `<Series Name> <NN> - <Title>` and only treats a
   prefix as a series once at least 2 books share it. The output is the planned
   structure plus a list of byte-identical duplicates.

3. **Review the plan — this is the part that needs judgment.** Look at the filenames and
   correct what the heuristic cannot know:
   - Series without numbering in the name? → `--series "Name"`
   - Wrongly detected as a series (e.g. a title starting with a year)? → `--no-series "Name"`
   - A single numbered volume that belongs to a series? → `--min-series 1`, or target it
     with `--series`.
   - Two series folders that are really the same series under different spellings? Do not
     merge them automatically — suggest it to the user.

   For a manageable collection, show the planned tree briefly. If the mapping is
   unambiguous, apply it directly; ask first only where there is genuine doubt.

4. **Apply.**

   ```bash
   python3 ~/.claude/skills/sort-ebooks/sort_ebooks.py "<folder>" --apply [--series ...]
   ```

   Files already sorted into subfolders are ignored, so the run is repeatable. If a
   destination file already exists, it is skipped rather than overwritten.

5. **Report.** Series with their volume counts, standalone books, and — separately — the
   things worth attention: duplicates and ambiguous series assignments. **Never delete
   duplicates unasked** — only report them and offer to remove them.

## Notes

- Sidecar files sharing a stem (`.jpg`, `.opf`, ...) move into the book folder alongside it.
- If the folder is under version control, do not commit without being asked.
