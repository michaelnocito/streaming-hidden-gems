# Streaming Hidden Gems (SQL)

Finding movies that audiences love but almost nobody has heard of, using the
official IMDb datasets, SQLite, and plain SQL.

Companion project to [Steam Hidden Gems](https://github.com/michaelnocito/steam-hidden-gems),
which runs the same hunt for video games.

## The findings

Out of 12.6 million titles on IMDb, only 751,802 are movies. Of those, just
347,689 have ever been rated by anyone. And only **581** qualify as hidden
gems: rated **8.0 or higher** (nearly two full points above the measured 6.13
average movie) with **5,000 to 50,000 votes**, enough opinions to trust the
score, too few to be mainstream.

Highlights from the top 25:

| Movie | Year | Rating | Votes |
|---|---|---|---|
| The Chaos Class | 1975 | 9.1 | 46,425 |
| Ramayana: The Legend of Prince Rama | 1993 | 9.1 | 17,832 |
| Mayabazar | 1957 | 9.0 | 6,984 |
| David Attenborough: A Life on Our Planet | 2020 | 8.9 | 36,252 |
| O.J.: Made in America | 2016 | 8.9 | 23,996 |
| The Marathon Family | 1982 | 8.8 | 18,218 |
| The Human Condition III: A Soldier's Prayer | 1961 | 8.8 | 8,915 |

The headline pattern: the list is dominated by non-US cinema. Turkish comedy
classics, Indian cinema across several languages and decades, Yugoslav and
Bangladeshi favorites, plus documentaries and filmed stage productions. These
are exactly the movies a US-centric recommendation feed never surfaces, so
"hidden" here largely means hidden from the English-speaking mainstream.

Full ranked list: run Step 10 in [`queries/hidden_gems.sql`](queries/hidden_gems.sql).

## The shrink ledger

Every filter has a cost, and the cost was counted before any titles were read:

| Rows | Filter |
|---|---|
| 12,635,420 | all titles in the IMDb file |
| 751,802 | keep only movies (6% of the file) |
| 347,689 | ...that anyone has ever rated |
| 14,295 | ...votes in the 5,000 to 50,000 band |
| 584 | ...rated 8.0 or higher |
| **581** | ...non-adult, with a real 60+ minute runtime |

Every threshold was measured before it was chosen: the 8.0 bar was calibrated
against the measured 6.13 average, and the vote floor and ceiling were picked
after counting the population at 1,000 / 5,000 / 50,000 votes.

## The data-quality stories

The real lessons of this project happened before a single gem was found. All
are documented as first-class content in the query file:

- **A quote character silently ate 256,000 rows.** The first import of the
  1.1 GB basics file returned 12,379,576 rows instead of 12,635,420. The
  import dialog treated `"` as a quote character; some titles contain one, and
  the importer quietly swallowed the rows that followed. The row-count sanity
  check (Step 1) is what caught it.
- **The files are TSVs that hide in the file picker.** DB Browser's import
  dialog filters to `*.csv` by default, and the separator must be set to Tab.
- **IMDb's nulls are fake.** A missing value is the literal text `\N`, which
  passes numeric CASTs as 0. It has to be excluded explicitly.
- **Everything imports as TEXT.** As text, '999' sorts after '10000', so every
  numeric comparison CASTs first. Forgetting the CAST does not error, it
  silently returns wrong answers.
- **A digit swap got caught by arithmetic.** A result misread as 14,925 failed
  a pre-computed reconciliation (18,908 - 4,613 = 14,295). Numbers that must
  reconcile, checked in advance, catch errors that eyeballs miss.

## How to actually learn from this

The query file is wall-to-wall commented in a specific format: a boxed WHY
above every query, then a clause-by-clause plain-English "read out loud"
block, then the clean SQL. That structure exists for a study method:

1. Take one section at a time.
2. Type and quietly say the read-out-loud comments until you can narrate the
   section smoothly, with no stumbling. Stumbling marks the exact gap.
3. Then read and run the SQL. It reads as the answer to a sentence you can
   already say.
4. Level up: hide the SQL and rebuild the query from the comments alone.

Why this works: self-explanation deepens understanding, producing beats
reading (Slamecka & Graf 1978, the generation effect), and retrieval practice
beats re-reading, 61% vs 40% recall at one week (Roediger & Karpicke 2006).

For portfolio or industry work you would strip these down to light intent
comments. The heavy version is a learning scaffold.

## Build it yourself

1. Download `title.basics.tsv.gz` and `title.ratings.tsv.gz` from
   [datasets.imdbws.com](https://datasets.imdbws.com/) and extract them into
   `data/`.
2. Import both into a SQLite database with DB Browser for SQLite. The full
   click-by-click walkthrough, including the three-saves model and every
   import trap listed above, is in
   [`docs/DATABASE_SETUP.md`](docs/DATABASE_SETUP.md).
3. Open `data/imdb.db` in DB Browser and work through
   [`queries/hidden_gems.sql`](queries/hidden_gems.sql) step by step,
   highlighting one query at a time.

The raw files are ~1.1 GB uncompressed, so they are not committed; 1,000-row
samples live in `data/sample/` so the schema is visible without downloading.
Working at this size is its own skill: see the
[Handle Large Datasets guide](https://michaelnocito.github.io/analyst-prep-kit/guides/handle-large-datasets/).

## Honest limitations

- **Whose ratings are these?** IMDb voters skew English-speaking and
  film-enthusiast. A movie can be "hidden" to this audience yet be a household
  name in its home country. The list answers "hidden to the global IMDb
  audience."
- **Snapshot in time.** Ratings and vote counts are as of the download date
  (2026-07-12) and drift daily.
- **Recency caution.** A few 2025/2026 releases sit just above the vote floor
  with very high ratings. Early votes skew toward devoted fans; these usually
  settle as votes accumulate. Documented rather than filtered.
- **Movies only.** TV series spread ratings across episodes and need their own
  gem definition. That is a future part, not a footnote.

## Roadmap

- **Part 2, JOINs:** join the 581 gems against streaming platform
  availability (Netflix / Prime / Hulu / Disney+) to answer "which service
  actually has the gems?", teaching INNER JOIN, LEFT JOIN, and GROUP BY on a
  second real dataset, with honest title-matching caveats.
- Possible front-end list site, in the style of
  [steam-hidden-gems-list](https://michaelnocito.github.io/steam-hidden-gems-list/).
