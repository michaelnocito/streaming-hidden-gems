-- ############################################################
-- #  STREAMING HIDDEN GEMS -- SQL ANALYSIS (PART 1: IMDb)    #
-- #  Find highly-rated movies that never went mainstream.    #
-- #  Data: IMDb non-commercial datasets (datasets.imdbws.com)#
-- #  Tools: SQLite + DB Browser for SQLite                   #
-- ############################################################

-- ============================================================
-- ABOUT THIS FILE (read me first)
-- This analysis is written to be followed by someone learning
-- SQL and data analysis. Each query has:
--   WHY  -- the reason the question is being asked
--   a plain-English "read out loud" of what the SQL does
-- The sections below document HOW the data was imported, HOW we
-- filtered out noise, HOW we scoped the question, and HOW we
-- validated the results -- the reasoning matters as much as the
-- final query.
-- ============================================================

-- ============================================================
-- HOW TO STUDY THIS FILE (most important step -- IF you're learning)
-- These wall-to-wall comments are a LEARNING SCAFFOLD, not how you
-- comment real work. Two modes:
--   * LEARNING: keep the "read out loud" comments and rehearse them
--     (method below).
--   * PORTFOLIO / INDUSTRY: strip them to standard LIGHT comments --
--     intent + anything non-obvious. A comment on every obvious line
--     is a red flag in professional code.
--
-- LEARNING METHOD -- rehearse, don't just retype:
--   1. Take one small section at a time.
--   2. Type and quietly SAY the read-out-loud comment
--      (--SELECT the movie's title, --WHERE at least 5,000 votes...).
--   3. Repeat the section until you can say the narration out loud
--      SMOOTHLY, no stumbling -- that fluency means it clicked;
--      stumbling shows the exact gap to revisit.
--   4. THEN read/run the SQL; it now reads as the answer to a
--      sentence you can already say.
--   5. LEVEL UP: hide the SQL and rebuild the query from the comment.
-- WHY IT WORKS (real learning science):
--   * Self-explanation -- narrating a step in your own words deepens
--     understanding (smooth = you get it; halting = the gap).
--   * Generation effect -- producing beats reading (Slamecka & Graf
--     1978; ~d=0.40).
--   * Retrieval practice -- recalling beats re-reading, 61% vs 40%
--     at one week (Roediger & Karpicke 2006) -- why step 5 matters.
--   Full write-up: "How to Actually Learn From This" in README.
-- ============================================================

-- ============================================================
-- THE DATA-QUALITY STORY: nothing about these files is a CSV
--
-- SYMPTOM(S): Three separate traps hit before a single query ran.
--   1. The .tsv files were INVISIBLE in the import file picker.
--   2. A file imported fine but landed under the WRONG table name
--      (the 1.1 GB basics file was sitting in a table called
--      title_ratings).
--   3. A re-extracted ratings file turned out to be 8 KB instead
--      of 29 MB -- silently truncated.
--
-- DIAGNOSIS / ROOT CAUSES:
--   1. DB Browser's import dialog filters to *.csv by default;
--      IMDb ships TAB-separated .tsv files, so the picker hides
--      them until you switch the filter to "All files (*)".
--   2. The import dialog auto-fills Table name from the filename
--      and it is easy to import file A while the name still says
--      B. The table name is a LABEL -- it does not prove what data
--      is inside. Only looking at the columns does.
--   3. An earlier partial extraction left a stub file behind.
--      File size is the fastest data-quality check that exists:
--      29,578,256 bytes expected vs 8,192 on disk = broken, before
--      you read a single row.
--
-- FIXES: switch the picker filter to All files; verify a table by
--   its COLUMNS (not its name) and ALTER TABLE ... RENAME when the
--   label lies; re-extract from the original .gz and confirm the
--   byte size before importing.
--
-- TWO MORE QUIRKS you must know before trusting any query below:
--   * IMDb writes a missing value as the literal two characters \N
--     (backslash-N), NOT as an empty cell. SQLite stores that as
--     the TEXT '\N', so later steps filter it out explicitly --
--     it is a fake null, not a real NULL.
--   * EVERYTHING imports as TEXT. SQLite does not know numVotes is
--     a number, and as text '999' sorts AFTER '10000' (character by
--     character). Every numeric comparison below CASTs first.
--     Forgetting the CAST does not error -- it silently returns
--     wrong answers, which is worse.
--
-- LESSON: A result that looks impossible is usually a DATA
--   problem, not a query problem. Always ask "is my logic wrong,
--   or is my data wrong?" -- and check file sizes, column names,
--   and a trusted record before trusting anything downstream.
-- ============================================================

-- ============================================================
-- FILTERING THE NOISE (the heart of this analysis)
--
-- Raw data is noisy. "Hidden gem movies" only become visible
-- after peeling away several layers of noise, one filter at a time:
--
--   1. WRONG-KIND noise -- IMDb bundles TV episodes, shorts, video
--      games and more into one file. Movies are a small slice.
--      Filter: titleType = 'movie'.
--
--   2. NO-SIGNAL noise -- a movie nobody has rated cannot be
--      judged at all. Joining basics to ratings keeps only movies
--      that have votes.
--
--   3. SMALL-SAMPLE noise -- a 9.8 from 40 voters is not "better"
--      than an 8.5 from 20,000. Fixed with a vote FLOOR (set from
--      the data in a later step, not guessed).
--
--   4. MAINSTREAM noise -- a beloved blockbuster is not "hidden."
--      Fixed with a vote CEILING (also set from the data).
--
--   5. MISSING-DATA noise -- runtimeMinutes of '\N' means "not
--      recorded," not zero. Excluded explicitly, because missing
--      data must not be treated as a real value.
--
--   6. CATEGORY noise -- adult titles and sub-60-minute entries
--      mislabeled as movies would pollute a movie list. Excluded,
--      and the exclusion is documented.
--
-- Each filter is a deliberate judgment, set by looking at counts
-- and distributions in the data -- never a number guessed blind.
--
-- THE SHRINK LEDGER -- every filter has a cost, and the cost is
-- counted BEFORE any titles are read. Running tally:
--   12,635,420  all titles in title_basics
--      751,802  titleType = 'movie'                    (Step 2)
--      347,689  ...that anyone has ever rated          (Step 3)
--       14,295  ...votes in the 5,000-50,000 band      (Step 6)
--          584  ...rated 8.0 or higher                 (Step 7)
--          581  ...non-adult, real 60+ min runtime     (Step 8)
--   FINAL: 581 hidden gems, showcased as a top 25.
-- A funnel documented this way can be audited at every stage:
-- anyone can re-run a step and check the number. A list with no
-- shrink trail is just an assertion.
-- ============================================================

-- ============================================================
-- SCOPE & LIMITATIONS (decided up front, honestly)
--
-- MOVIES ONLY (intentionally):
--   titleType = 'movie'. TV series spread their ratings across
--   episodes and need a different gem definition -- they are a
--   future Part, not a footnote here.
--
-- WHOSE RATINGS ARE THESE? IMDb voters skew English-speaking and
--   film-enthusiast. A movie can be "hidden" to this audience yet
--   be a household name in its home country. The list answers
--   "hidden to the global IMDb audience" -- state the audience or
--   the results get quietly misread.
--
-- SNAPSHOT IN TIME: ratings and vote counts are as of the download
--   date (2026-07-12) and drift daily. Numbers in this file will
--   not exactly match a re-download.
--
-- PRINCIPLE: every filter you leave OUT is also a decision. State
-- the audience assumption so results are never quietly misread.
-- ============================================================

-- ============================================================
-- VALIDATION STEPS (how we check the results are real)
--
--   A. ROW-COUNT CHECK -- each table's imported row count must
--      match the source file (a truncated import poisons all
--      downstream answers; we already caught one 8 KB stub).
--
--   B. KNOWN-RECORD CHECK -- verify one movie we can check by hand
--      on imdb.com before trusting any ranked list.
--
--   C. MONOTONICITY CHECK -- every stricter filter must return
--      FEWER rows. A stricter filter returning more rows is
--      logically impossible and means a query was mis-run.
--
--   D. COUNT-BEFORE-TRUST -- check HOW MANY movies each filter
--      returns before reading any titles, and record the shrink
--      at every step.
--
--   E. REALITY CHECK on the final list -- confirm titles against
--      real-world knowledge; investigate anything implausible
--      rather than silently keeping or dropping it.
--
--   (Results of each check are recorded in the steps below as we
--   run them.)
-- ============================================================

-- ============================================================
-- BEST PRACTICES USED IN THIS PROJECT
--   * Never edit raw data in place -- keep the original .gz, so
--     everything is reproducible from source.
--   * Keep queries in version control; large data stays out of
--     git (.gitignore), with small samples committed instead.
--   * Set thresholds from evidence (counts/distributions), not guesses.
--   * Comment the WHY, not just the WHAT.
--   * State scope and audience assumptions explicitly.
--   * Validate against a known record AND against reality.
--   * Document data defects and limitations openly.
-- ============================================================

-- ============================================================
-- SQL FUNCTIONS & KEYWORDS USED (quick reference)
--   SELECT ...          choose which columns to display
--   FROM <table>        which table to pull from
--   WHERE ...           keep only rows meeting a condition
--   AND                 combine conditions (ALL must be true)
--   ORDER BY ... DESC   sort results (DESC = highest first)
--   LIMIT n             return only the first n rows
--   AS <name>           give a column a custom name (an "alias")
--   COUNT(*)            count rows; * means "every row"
--   GROUP BY ...        collapse rows sharing a value into one summary row
--   JOIN ... ON         match rows across two tables by a shared key
--   CAST(x AS INTEGER)  treat x as a whole number (text '999' becomes 999)
--   CAST(x AS REAL)     treat x as a decimal (9/10 = 0.9, not 0)
--   ROUND(x, 1)         round x to 1 decimal place
--   AVG(x)              average all values in a column
--   BETWEEN a AND b     value is >= a and <= b (both ends included)
--   <>                  "not equal to"
-- ============================================================


-- ============================================================
-- STEP 1: Did both tables import at full size? (sanity check)
-- WHY: Before trusting ANY analysis, confirm the imports are
--      complete and not silently truncated (see the data-quality
--      story above: one source file turned out to be an 8 KB
--      stub). A cut-off import poisons every later answer.
--      Expected: title_ratings ~1,694,000 rows.
-- ============================================================
--SELECT (display) a COUNT of every row -- COUNT(*) counts every row
--FROM (pull from) the title_ratings table
SELECT COUNT(*) FROM title_ratings;
-- RESULT: 1,694,281 -- matches the source file exactly
-- (1,694,282 lines minus the header row). Import is complete.


-- ============================================================
-- STEP 1b: Same sanity check on the big table
-- WHY: title_basics is the 1.1 GB file -- the one most likely to
--      be silently cut off mid-import. Same rule: verify the row
--      count against the source before trusting anything.
--      Expected: about 12,635,000 rows.
-- ============================================================
--SELECT (display) a COUNT of every row -- COUNT(*) counts every row
--FROM (pull from) the title_basics table
SELECT COUNT(*) FROM title_basics;
-- RESULT: 12,635,420 -- but only on the SECOND import attempt.
-- The first attempt returned 12,379,576: about 256,000 rows were
-- silently LOST because the import dialog's Quote character was
-- set to '"'. Some titles contain a double-quote, and treating it
-- as special makes the importer mis-read those rows and swallow
-- the ones that follow. These files use NO quoting at all, so the
-- Quote character must be set to blank/none on import. THIS is
-- why the row-count check exists: the data looked fine, browsed
-- fine, and was quietly missing 2% of its rows.


-- ============================================================
-- STEP 2: What KINDS of titles are in this file? (scoping)
-- WHY: "Hidden gem movies" only makes sense knowing what else is
--      mixed in. IMDb bundles TV episodes, shorts, video games and
--      more into one file -- movies may be a surprisingly small
--      slice. This breakdown decides the first noise filter:
--      titleType = 'movie'.
--      Expected: tvEpisode dominates; movies well under 10%.
-- ============================================================
--SELECT (display) the title type, and a COUNT of rows for each:
--   COUNT(*) AS how_many = count every row, name the column how_many
--FROM (pull from) the title_basics table
--GROUP BY titleType -- collapse rows sharing a type into one summary row
--ORDER BY the count, DESC (most common type first)
SELECT titleType, COUNT(*) AS how_many
FROM title_basics
GROUP BY titleType
ORDER BY how_many DESC;
-- RESULT: tvEpisode 9,764,008 / short 1,143,445 / movie 751,802 /
-- video 328,097 / tvSeries 302,089 / tvMovie 155,366 / ... /
-- tvPilot 1. Movies are only ~6% of the file. Every query below
-- filters to titleType = 'movie'. (Note tvMovie is a SEPARATE
-- type -- made-for-TV movies are excluded from this analysis.)


-- ============================================================
-- STEP 3: How many movies actually HAVE a rating? (the first shrink)
-- WHY: title_basics knows what a movie IS; title_ratings knows how
--      it was RECEIVED. Only movies present in BOTH tables can be
--      judged at all, so this JOIN defines the real working
--      population -- and reveals how many movies nobody ever rated.
--      Expected: a big drop from 751,802.
-- ============================================================
--SELECT (display) a COUNT of the matched rows
--FROM (pull from) the title_basics table, nicknamed b
--JOIN the title_ratings table, nicknamed r, ON matching tconst IDs
--   -- an (INNER) JOIN keeps ONLY movies that appear in BOTH tables
--WHERE (keep only) rows whose title type is 'movie'
SELECT COUNT(*) AS rated_movies
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie';
-- RESULT: 347,689. The first shrink: 751,802 movies -> 347,689
-- with at least one vote. 54% of all movies on IMDb have NEVER
-- been rated by anyone -- they cannot be judged, so the working
-- population from here on is the 347,689.


-- ============================================================
-- STEP 4: What does a "good" rating even mean here? (calibration)
-- WHY: A gem threshold like "8.0 is great" is only meaningful
--      relative to the data. Measuring the average movie rating
--      first means the gem bar gets set FROM the data, not
--      guessed. This is also the first query where the
--      everything-is-TEXT trap matters: averageRating must be
--      CAST to a decimal before AVG can do real math on it.
--      Expected: somewhere in the 5-7 range.
-- ============================================================
--SELECT (display) one CALCULATED number, the average movie rating:
--   CAST(r.averageRating AS REAL) = treat the text as a decimal
--   AVG(...)                      = average it across all rows
--   ROUND(..., 2)                 = round to 2 decimal places
--   AS avg_movie_rating           = name (alias) the result column
--FROM the title_basics table (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) rows whose title type is 'movie'
SELECT ROUND(AVG(CAST(r.averageRating AS REAL)), 2) AS avg_movie_rating
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie';
-- RESULT: 6.13. The average rated movie sits at 6.13, so a gem
-- bar of 8.0 is nearly two full points above typical -- a movie
-- people genuinely love, not one they merely liked.


-- ============================================================
-- STEP 5: Threshold tuning -- measure the vote cutoffs, then pick
-- WHY: "Hidden" needs a vote FLOOR (below it, a rating is noise:
--      a 9.8 from 40 voters is not "better" than an 8.5 from
--      20,000) and a vote CEILING (above it, the movie has been
--      judged by a mainstream audience and is no secret). Each
--      candidate cutoff is COUNTED before any threshold is
--      chosen. Sanity rule: each higher cutoff must return fewer
--      movies (monotonicity check).
-- RESULTS:  >=  1,000 votes ...... 48,700  (86% of rated movies
--                                           are below even this)
--           >=  5,000 votes ...... 18,908  (the sturdy floor)
--           >= 50,000 votes ....... 4,613  (the mainstream tier)
-- DECISION: FLOOR = 5,000 (an average over five thousand opinions
--           barely moves when extreme voters pile on) and
--           CEILING = 50,000 (the 4,613 above it are the movies
--           everybody already knows -- excluded by definition).
-- ============================================================
--SELECT (display) a COUNT of the matched rows
--FROM title_basics (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) title type 'movie'
--   AND the vote count, CAST to a whole number, is at least 1,000
--   -- CAST(numVotes AS INTEGER) because as TEXT '999' > '10000'
--   -- (rerun with 5000 and 50000 to reproduce the table above)
SELECT COUNT(*) AS movies_at_cutoff
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND CAST(r.numVotes AS INTEGER) >= 1000;


-- ============================================================
-- STEP 6: Count the "known but not famous" band (5,000 - 50,000)
-- WHY: The floor (5,000) and ceiling (50,000) were measured and
--      chosen in Step 5. Everything between them is the band where
--      a hidden gem can even exist: enough votes for the rating to
--      be sturdy, too few for the movie to be mainstream. This
--      count sizes the hunting ground BEFORE quality enters the
--      picture. A check worth doing in advance: the band should
--      land near 18,908 - 4,613 = 14,295 from Step 5's counts.
--      New keyword: BETWEEN a AND b = ">= a and <= b", inclusive
--      on both ends.
-- ============================================================
--SELECT (display) a COUNT of the matched rows
--FROM title_basics (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) title type 'movie'
--   AND the vote count, CAST to a whole number, is BETWEEN
--       5,000 and 50,000 (both ends included)
SELECT COUNT(*) AS movies_in_band
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000;
-- RESULT: 14,295 -- reconciles exactly with Step 5's subtraction
-- (so zero movies sit at exactly 50,000 votes). Worth noting: a
-- first reading of this result was mis-transcribed as 14,925, and
-- the pre-computed arithmetic check is what caught the digit swap.
-- Numbers that must reconcile, checked in advance, catch errors
-- that eyeballs miss.


-- ============================================================
-- STEP 7: Add the quality bar -- rated 8.0+ inside the band
-- WHY: The band answers "hidden?"; the rating answers "gem?". An
--      8.0 bar was calibrated against the measured 6.13 average
--      (Step 4) -- almost two full points above the typical movie,
--      territory only genuinely beloved films reach. Counting
--      first (before reading any titles) shows how rare the
--      hidden-AND-loved combination is.
--      Monotonicity check: the result must be under 14,295.
-- ============================================================
--SELECT (display) a COUNT of the matched rows
--FROM title_basics (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) title type 'movie'
--   AND the vote count, CAST to a whole number, is BETWEEN
--       5,000 and 50,000 (the hidden band)
--   AND the rating, CAST to a decimal, is at least 8.0
SELECT COUNT(*) AS hidden_and_loved
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000
  AND CAST(r.averageRating AS REAL) >= 8.0;
-- RESULT: 584. Of 347,689 rated movies, fewer than 0.2% are both
-- hidden AND loved. Rarity is what makes the final list worth
-- reading.


-- ============================================================
-- STEP 8: Category hygiene -- exclude adult titles & quasi-shorts
-- WHY: Two pollutions can hide in the 584. (1) isAdult = '1'
--      titles don't belong on a general-audience gems list -- an
--      exclusion that must be stated, not silent. (2) Sub-60-
--      minute entries mislabeled as movies are shorts, not
--      features. The runtime test is also where the \N fake null
--      bites: a missing runtime is the literal TEXT '\N', and
--      CAST('\N' AS INTEGER) silently becomes 0 -- so \N rows must
--      be excluded EXPLICITLY, never trusted to a numeric test.
--      New keyword: <> means "not equal to".
--      Monotonicity check: result must be at or under 584.
-- ============================================================
--SELECT (display) a COUNT of the matched rows
--FROM title_basics (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) title type 'movie'
--   AND the adult flag is '0' (not an adult title)
--   AND the runtime is not the '\N' missing-value marker
--   AND the runtime, CAST to a whole number, is at least 60 minutes
--   AND the vote count is BETWEEN 5,000 and 50,000 (the hidden band)
--   AND the rating, CAST to a decimal, is at least 8.0
SELECT COUNT(*) AS hidden_gems
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND b.isAdult = '0'
  AND b.runtimeMinutes <> '\N'
  AND CAST(b.runtimeMinutes AS INTEGER) >= 60
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000
  AND CAST(r.averageRating AS REAL) >= 8.0;
-- RESULT: 581 -- the final gem population. The hygiene filters
-- cost only 3 movies, but the exclusions are now deliberate and
-- documented instead of accidental.


-- ============================================================
-- STEP 9: VALIDATION -- spot-check one known record
-- WHY: Before trusting a ranked list, verify a single movie
--      against a source checkable by hand (imdb.com). tt5275892,
--      "O.J.: Made in America", sits in the gem band and has a
--      public page to compare. If the known record is right, the
--      join, the CASTs, and the import line up; if it is wrong,
--      nothing downstream can be trusted.
--      Expected: title matches, year 2016, rating ~8.9,
--      votes in the 20,000s.
-- ============================================================
--SELECT (display) the title, year, runtime, rating, and vote count
--FROM title_basics (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) the row whose tconst ID is exactly 'tt5275892'
SELECT b.primaryTitle, b.startYear, b.runtimeMinutes,
       r.averageRating, r.numVotes
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.tconst = 'tt5275892';
-- RESULT: O.J.: Made in America | 2016 | 467 | 8.9 | 23,996 --
-- matches the public IMDb page (vote counts drift with snapshot
-- date). The 467-minute runtime is REAL (a near-8-hour episodic
-- documentary), a reminder that an outlier is not automatically
-- an error -- check before "fixing" anything.


-- ============================================================
-- STEP 10: THE ANSWER -- top 25 hidden gem movies
-- WHY: Every step above earns this one: the definition is locked
--      (Step 8 = 581 gems), the pipeline is validated (Step 9),
--      so NOW the titles can be read. Ranked by rating; ties
--      break by vote count, so between two equally-loved movies
--      the better-evidenced one ranks higher.
-- ============================================================
--SELECT (display) the title, year, genres, runtime, rating, votes
--FROM title_basics (b) JOINed to title_ratings (r) ON tconst
--WHERE (keep only) title type 'movie'
--   AND not adult, AND a real runtime of 60+ minutes
--   AND votes BETWEEN 5,000 and 50,000 (hidden band)
--   AND rating at least 8.0 (the quality bar)
--ORDER BY rating DESC, then votes DESC (the tiebreaker)
--LIMIT the output to the top 25 rows
SELECT b.primaryTitle, b.startYear, b.genres, b.runtimeMinutes,
       r.averageRating, r.numVotes
FROM title_basics AS b
JOIN title_ratings AS r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND b.isAdult = '0'
  AND b.runtimeMinutes <> '\N'
  AND CAST(b.runtimeMinutes AS INTEGER) >= 60
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000
  AND CAST(r.averageRating AS REAL) >= 8.0
ORDER BY CAST(r.averageRating AS REAL) DESC,
         CAST(r.numVotes AS INTEGER) DESC
LIMIT 25;

-- ------------------------------------------------------------
-- WHAT THIS REVEALED -- the reality check, read as findings:
--   * THE HEADLINE PATTERN: the list is dominated by NON-US
--     cinema -- Turkish classics (The Chaos Class, Tosun Pasha,
--     The Foster Brothers), Indian cinema across several
--     languages (Mayabazar 1957, Sandesham, Kireedam, C/o
--     Kancharapalem, Natsamrat, Nadodikkattu, Ramayana), Yugoslav
--     (The Marathon Family), Bangladeshi (Monpura, The Unnamed) --
--     plus documentaries (Attenborough, O.J., Dominion) and filmed
--     stage productions (Phantom at the Royal Albert Hall, Les
--     Miserables in Concert). Exactly the movies a US-centric
--     recommendation feed never surfaces: "hidden" here largely
--     means hidden FROM THE ENGLISH-SPEAKING MAINSTREAM, which is
--     the Scope box's audience caveat made visible.
--   * RECENCY CAUTION: Mission C1000 (2026, 9.3, only 5,787
--     votes), Unpaarvayil (2025) and The Devil (2025) are very new
--     releases sitting just above the vote floor. Early votes skew
--     toward devoted fans, so brand-new entries at the top deserve
--     skepticism -- their ratings usually settle as votes
--     accumulate. Documented rather than filtered: a release-year
--     cutoff is a defensible variant, but it would also delete
--     genuinely new gems.
--   * MISSING DATA IS VISIBLE: The Devil (2025) shows genres = \N.
--     The fake null appears in the OUTPUT, not just the filters --
--     display columns can carry \N too; only filter columns were
--     cleaned.
--   * CATEGORY EDGE CASE: concert films (Phantom, Les Mis) are
--     arguably events, not movies. IMDb types them as 'movie', so
--     they stay -- but the judgment call is recorded here.
-- ------------------------------------------------------------
