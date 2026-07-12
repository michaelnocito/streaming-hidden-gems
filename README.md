# Streaming Hidden Gems (SQL)

Finding movies that audiences love but almost nobody has heard of, using the
official IMDb datasets, SQLite, and plain SQL.

Companion project to [Steam Hidden Gems](https://github.com/michaelnocito/steam-hidden-gems),
which does the same hunt for video games.

## The findings

Out of **751,802 movies** on IMDb, only **347,689** have even one rating, and
just **581** qualify as hidden gems: rated **8.0 or higher** (nearly two full
points above the 6.13 average movie) with **5,000 to 50,000 votes**, enough
opinions to trust the score, but far below the mainstream line.

Headliners from the top 25:

| Movie | Year | Rating | Votes |
|---|---|---|---|
| The Chaos Class | 1975 | 9.1 | 46,425 |
| Ramayana: The Legend of Prince Rama | 1993 | 9.1 | 17,832 |
| Mayabazar | 1957 | 9.0 | 6,984 |
| David Attenborough: A Life on Our Planet | 2020 | 8.9 | 36,252 |
| O.J.: Made in America | 2016 | 8.9 | 23,996 |
| The Human Condition III: A Soldier's Prayer | 1961 | 8.8 | 8,915 |

A striking pattern: the list is dominated by non-US cinema (Turkish, Indian,
Yugoslav, Japanese classics) plus documentaries, exactly the movies a US-centric
recommendation feed never surfaces.

Full ranked list: run `queries/hidden_gems.sql` (step 8).

## The full query file

Everything lives in [`queries/hidden_gems.sql`](queries/hidden_gems.sql), built
as 8 steps: sanity counts, scoping (movies are only ~6% of IMDb's file),
calibrating "good" from the data, setting the vote floor and ceiling from the
distributions, the gem definition and its cost, a spot-check validation, then
the answer. Every threshold was measured before it was chosen, and the shrink
at each step is documented (751,802 -> 347,689 -> 581).

Part 2 (`hidden_gems_joins.sql`, planned) will join the gems against
streaming-platform availability data to answer "which service actually has
them?"

## How to actually learn from this

The query file is wall-to-wall commented in a specific format: a boxed WHY
above every query, then a clause-by-clause plain-English "read out loud" block,
then the clean SQL. That structure exists for a study method:

1. Take one section at a time.
2. Type and quietly say the read-out-loud comments until you can narrate the
   section smoothly, no stumbling. Stumbling marks the exact gap.
3. Then read and run the SQL. It reads as the answer to a sentence you can
   already say.
4. Level up: hide the SQL and rebuild the query from the comments alone.

Why this works: self-explanation deepens understanding, generating beats
reading (Slamecka & Graf 1978, the generation effect), and retrieval practice
beats re-reading by 61% vs 40% recall at one week (Roediger & Karpicke 2006).

For portfolio or industry work you would strip these down to light
intent-comments. The heavy version is a learning scaffold.

## Pipeline

1. Download `title.basics.tsv.gz` and `title.ratings.tsv.gz` from
   [datasets.imdbws.com](https://datasets.imdbws.com/) (IMDb non-commercial
   datasets) and gunzip them into `data/`.
2. Import into SQLite (the files are tab-separated and use `\N` for nulls):

   ```
   sqlite3 data/imdb.db
   .mode ascii
   .separator "\t" "\n"
   .import data/title.basics.tsv title_basics
   .import data/title.ratings.tsv title_ratings
   ```

3. Open `data/imdb.db` in DB Browser for SQLite and run
   `queries/hidden_gems.sql` step by step (or pipe the whole file through the
   `sqlite3` shell).

The raw files are ~1.1 GB uncompressed, so they are not committed; 1,000-row
samples live in `data/sample/` so the schema is visible without downloading.
Working with files this size is its own skill, see the
[Handle Large Datasets guide](https://michaelnocito.github.io/analyst-prep-kit/guides/handle-large-datasets/).

## Honest limitations

- Everything imports as TEXT in SQLite, so every numeric comparison must CAST
  first. Forgetting a CAST gives silently wrong answers ('999' > '10000' as
  text). The query file explains this in the import story.
- IMDb voters skew English-speaking and film-enthusiast; a "hidden" movie here
  may be a household name in its home country.
- Ratings are a snapshot of the download date (2026-07-12) and drift over time.
- Movies only. TV series spread ratings across episodes and need their own gem
  definition; that is a future part, not a footnote.
