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
-- scoped the question, HOW we set thresholds FROM the data (not
-- by guessing), and HOW we validated the results. The reasoning
-- matters as much as the final query.
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
-- SQL FUNCTIONS & KEYWORDS USED IN THIS FILE
--   COUNT(*)          -- count rows
--   GROUP BY          -- collapse rows into one row per group
--   JOIN ... ON       -- match rows across two tables by a key
--   CAST(x AS INTEGER)-- treat text as a whole number
--   CAST(x AS REAL)   -- treat text as a decimal number
--   ROUND(x, n)       -- round to n decimal places
--   AVG(x)            -- average of a column
--   BETWEEN a AND b   -- value is >= a and <= b (inclusive)
--   ORDER BY ... DESC -- sort high to low
--   LIMIT n           -- keep only the first n rows
-- ============================================================

-- ============================================================
-- THE IMPORT STORY: everything arrives as TEXT
--
-- The IMDb files are TAB-separated (.tsv), not comma-separated,
-- and they use the two characters \N (backslash N) to mean
-- "no value" instead of leaving a field empty.
--
-- When SQLite imports a .tsv it does NOT know that numVotes is
-- a number -- every column lands as TEXT. That has a nasty
-- consequence: text sorts alphabetically, so as text,
-- '999' > '10000' (because '9' > '1'). Every numeric comparison
-- in this file therefore CASTs the column to INTEGER or REAL
-- first. Forgetting the CAST does not error -- it silently gives
-- WRONG answers, which is far worse.
--
-- Import commands used (sqlite3 shell):
--   .mode ascii
--   .separator "\t" "\n"
--   .import title.basics.tsv title_basics
--   .import title.ratings.tsv title_ratings
-- ============================================================

-- ============================================================
-- SCOPE & LIMITATIONS (decided up front, honestly)
--   * MOVIES ONLY (titleType = 'movie'). TV series spread their
--     ratings across episodes and need a different gem
--     definition; they are a future Part, not a footnote here.
--   * IMDb votes measure IMDb's audience, which skews toward
--     English-language and film-enthusiast voters. A "hidden"
--     movie here may be famous in its home country.
--   * Ratings are a snapshot of the download date; they drift.
--   * isAdult = '1' titles (9,132 movies) are excluded.
-- ============================================================


-- ============================================================
-- STEP 1: How big is each table? (sanity check before anything)
-- WHY: Before analyzing, confirm the import actually worked and
--      matches the source's advertised size. A silently truncated
--      import poisons every later answer.
-- ============================================================
--SELECT a COUNT of all rows:
--   COUNT(*) = count every row in the table
--FROM the title_basics table
SELECT COUNT(*) FROM title_basics;
-- Result: 12,635,420 titles. (title_ratings: 1,694,281 rows.)

--SELECT a COUNT of all rows:
--FROM the title_ratings table
SELECT COUNT(*) FROM title_ratings;


-- ============================================================
-- STEP 2: What KINDS of titles are in here? (scoping the question)
-- WHY: "Hidden gem movies" only makes sense if we know what else
--      is mixed in. IMDb bundles TV episodes, shorts, video games
--      and more into one file; movies are a small slice of it.
-- ============================================================
--SELECT the title type and a COUNT of rows for each:
--   COUNT(*) = how many titles of this type
--FROM the title_basics table
--GROUP BY titleType, so we get one row per type
--ORDER BY the count, highest first
SELECT titleType, COUNT(*) AS how_many
FROM title_basics
GROUP BY titleType
ORDER BY how_many DESC;
-- Result: tvEpisode 9.76M, short 1.14M, movie 751,802, ... .
-- Movies are only ~6% of the file. Everything below filters to
-- titleType = 'movie'.


-- ============================================================
-- STEP 3: How many movies actually HAVE a rating? (the first shrink)
-- WHY: title_basics knows what a movie IS; title_ratings knows how
--      it was RECEIVED. Only movies present in BOTH tables can be
--      judged, so this JOIN defines our real working population.
-- ============================================================
--SELECT a COUNT of matched rows:
--FROM the title_basics table (aliased b)
--JOIN the title_ratings table (aliased r) ON matching tconst IDs,
--   which keeps only movies that appear in BOTH tables
--WHERE the title type is 'movie'
SELECT COUNT(*)
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.titleType = 'movie';
-- Result: 347,689. So 751,802 movies shrink to 347,689 rated ones
-- (54% of movies have NO votes at all). Documented, not hidden.


-- ============================================================
-- STEP 4: What does a "good" rating even mean here? (calibration)
-- WHY: A threshold like "8.0 is great" is only meaningful relative
--      to the data. We measure the average movie rating first so
--      the gem bar is set FROM the data, not guessed.
-- ============================================================
--SELECT the average rating across all rated movies:
--   CAST(averageRating AS REAL) = treat the text column as a decimal
--   AVG(...)                    = average it across all rows
--   ROUND(..., 2)               = round to 2 decimal places
--FROM title_basics joined to title_ratings on tconst
--WHERE the title type is 'movie'
SELECT ROUND(AVG(CAST(r.averageRating AS REAL)), 2) AS avg_movie_rating
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.titleType = 'movie';
-- Result: 6.13. So a gem bar of 8.0 is roughly two full points
-- above the average movie -- genuinely "well-loved", not just fine.


-- ============================================================
-- STEP 5: Where do the vote counts fall? (setting floor & ceiling)
-- WHY: "Hidden" needs a ceiling (too many votes = mainstream) and
--      a floor (too few votes = the rating is statistical noise).
--      We counted the population at several cutoffs before picking:
--        >= 1,000 votes:  48,700 movies
--        >= 5,000 votes:  18,908 movies
--        >= 50,000 votes:  4,613 movies
--      FLOOR = 5,000 (a rating built on thousands of opinions is
--      stable). CEILING = 50,000 (the ~4,600 movies above it are
--      the mainstream everyone already knows).
-- ============================================================
--SELECT a COUNT of matched rows:
--FROM title_basics joined to title_ratings on tconst
--WHERE the title type is 'movie'
--   AND the vote count, read as a whole number, is BETWEEN
--       5,000 and 50,000 (inclusive on both ends)
--   CAST(numVotes AS INTEGER) = treat the text column as a number,
--       otherwise '999' would sort AFTER '10000'
SELECT COUNT(*)
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000;
-- Result: 14,295 movies live in the "known but not famous" band.


-- ============================================================
-- STEP 6: The gem definition, and what it costs (the full shrink)
-- WHY: A hidden gem = rated 8.0 or higher (two points above the
--      6.13 average) AND 5,000-50,000 votes (real audience, not
--      mainstream) AND not adult AND at least 60 minutes long
--      (excludes quasi-shorts mislabeled as movies). Counting the
--      survivors makes the definition's cost visible: for context,
--      1,014 movies rate 8.0+ with 5,000+ votes; capping at 50,000
--      votes leaves 584; the adult and runtime filters leave 581.
--      751,802 movies -> 347,689 rated -> 581 gems.
-- ============================================================
--SELECT a COUNT of matched rows:
--FROM title_basics joined to title_ratings on tconst
--WHERE the title type is 'movie'
--   AND the movie is not flagged adult
--   AND the runtime field is not IMDb's \N "no value" marker
--   AND the runtime, read as a whole number, is at least 60 minutes
--   AND the vote count is BETWEEN 5,000 and 50,000
--   AND the rating, read as a decimal, is at least 8.0
SELECT COUNT(*)
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND b.isAdult = '0'
  AND b.runtimeMinutes <> '\N'
  AND CAST(b.runtimeMinutes AS INTEGER) >= 60
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000
  AND CAST(r.averageRating AS REAL) >= 8.0;
-- Result: 581 hidden gems.


-- ============================================================
-- STEP 7: VALIDATION -- spot-check one known record
-- WHY: Before trusting a ranked list, verify a single movie we can
--      check by hand on imdb.com. If the known record is wrong,
--      the import (or a CAST) is wrong. O.J.: Made in America
--      (tt5275892) is in our gem band and easy to verify.
-- ============================================================
--SELECT the title, year, rating, and vote count:
--FROM title_basics joined to title_ratings on tconst
--WHERE the tconst ID is exactly 'tt5275892'
SELECT b.primaryTitle, b.startYear, r.averageRating, r.numVotes
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.tconst = 'tt5275892';
-- Result: O.J.: Made in America | 2016 | 8.9 | ~24,000 votes.
-- Matches the live IMDb page (snapshot date differences aside).


-- ============================================================
-- STEP 8: THE ANSWER -- top 25 hidden gem movies
-- WHY: Everything above earns this query. Rank the 581 gems by
--      rating; break ties by vote count so the better-evidenced
--      movie ranks higher.
-- ============================================================
--SELECT the title, year, genres, runtime, rating, and vote count:
--FROM title_basics joined to title_ratings on tconst
--WHERE the title type is 'movie'
--   AND the movie is not flagged adult
--   AND the runtime is a real value of at least 60 minutes
--   AND the vote count is BETWEEN 5,000 and 50,000 (known, not famous)
--   AND the rating is at least 8.0 (two points above average)
--ORDER BY rating high-to-low, then vote count high-to-low (tiebreaker)
--LIMIT the first 25 rows
SELECT b.primaryTitle,
       b.startYear,
       b.genres,
       b.runtimeMinutes,
       r.averageRating,
       r.numVotes
FROM title_basics b
JOIN title_ratings r ON b.tconst = r.tconst
WHERE b.titleType = 'movie'
  AND b.isAdult = '0'
  AND b.runtimeMinutes <> '\N'
  AND CAST(b.runtimeMinutes AS INTEGER) >= 60
  AND CAST(r.numVotes AS INTEGER) BETWEEN 5000 AND 50000
  AND CAST(r.averageRating AS REAL) >= 8.0
ORDER BY CAST(r.averageRating AS REAL) DESC,
         CAST(r.numVotes AS INTEGER) DESC
LIMIT 25;
-- Headliners include The Chaos Class (1975, 9.1), Ramayana: The
-- Legend of Prince Rama (1993, 9.1), and O.J.: Made in America
-- (2016, 8.9) -- exactly the profile we wanted: beloved, and far
-- off the mainstream radar.
