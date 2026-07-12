# Database Setup (DB Browser for SQLite)

How to load the raw IMDb files into a local SQLite database and, just as
important, how "saving" actually works in DB Browser so nothing gets lost.

This doc is reusable: the same steps and the same three-saves model apply to
any SQLite portfolio project (Steam Hidden Gems, this one, future ones).

---

## The data files

Downloaded from the IMDb non-commercial datasets: https://datasets.imdbws.com/

| File | Size | Rows | What it is |
|---|---|---|---|
| `title.ratings.tsv` | 29 MB | ~1.7M | the score: `averageRating`, `numVotes` per title |
| `title.basics.tsv` | 1.1 GB | ~12.6M | what each title is: type, title, year, runtime, genres |

They are gunzipped from the `.tsv.gz` downloads and live in `data/`. Both the
raw files and the built `.db` are gitignored (too big for GitHub, easy to
rebuild), so only 1,000-row samples in `data/sample/` are committed.

---

## Three things that will trip you up on import

1. **These are TAB-separated, not comma-separated.** In the import dialog the
   Field separator must be set to **Tab**. Leave it on comma and every row
   lands mashed into a single column.
2. **IMDb writes a missing value as the literal two characters `\N`** (a
   backslash then an N), not an empty cell. DB Browser stores that as the text
   `\N`, so later queries filter it out explicitly (for example
   `WHERE runtimeMinutes <> '\N'`) rather than treating it as a true NULL.
3. **Every column imports as TEXT.** DB Browser does not know `numVotes` is a
   number. As text, `'999'` sorts AFTER `'10000'` because it compares character
   by character. So every numeric comparison in the queries wraps the column in
   `CAST(... AS INTEGER)` or `CAST(... AS REAL)` first. Forgetting the CAST does
   not throw an error, it just quietly returns the wrong answer, which is worse.

---

## Import walkthrough

1. Open **DB Browser for SQLite**.
2. **New Database** → save as `data\imdb.db`. When the "Edit table definition"
   dialog pops up, click **Cancel** (we are importing, not hand-building a
   table).
3. **File → Import → Table from CSV file…**
4. Pick the `.tsv` file. In the dialog set:
   - **Table name:** `title_ratings` (or `title_basics` for the big file)
   - **Column names in first line:** checked (the files have a header row)
   - **Field separator:** **Tab**
   - Leave the rest at defaults.
5. Click **OK** and let it run. The ratings file is quick; `title.basics` is
   1.1 GB and will take noticeably longer and use real memory. That size is
   itself a lesson (see the Handle Large Datasets guide:
   https://michaelnocito.github.io/analyst-prep-kit/guides/handle-large-datasets/).
6. **Click Write Changes** (see below) so the import is actually saved to disk.
7. Repeat for the second file into the same database.

---

## The three separate "saves" in DB Browser

This is the part people get wrong. DB Browser has three different saves and
they do completely different things.

| Action | What it saves | When you need it |
|---|---|---|
| **Write Changes** (top toolbar) | The actual data and tables into the `.db` file | Every time after an import or edit. This is the one that matters. Skip it and the work is lost when you close. |
| **Save Project** (`.sqbpro`) | The workspace: which database is attached, your SQL tabs, window layout. Not data. | Optional convenience so reopening restores your setup. |
| **Save SQL** (disk icon in the SQL toolbar) | The text in the SQL editor to a `.sql` file | When you want your queries as a real file. We keep ours in `queries/`. |

### Watch out for the project trap

The database file (`.db`) and the project file (`.sqbpro`) are different
things. If a project from another repo is still loaded (for example
`steam_gems.sqbpro`), clicking plain **Save Project** overwrites THAT project.
For a new project always use **File → Save Project As…** and save a fresh file,
here `streaming_gems.sqbpro`.

### The habit that keeps you safe

- After any import or data edit: **Write Changes** first (persists data to the
  `.db`).
- Then, if you want the workspace remembered: **Save Project As…** to this
  project's own `.sqbpro`.
- Both `.db` and `.sqbpro` are gitignored, so they stay local and never reach
  GitHub. The queries in `queries/` are what get committed.
