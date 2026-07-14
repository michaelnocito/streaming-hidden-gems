# Extend This Project (No New Skills Required)

Reading a finished analysis teaches you a little. Changing one and watching
the results move teaches you a lot more — learning science calls it the
generation effect: producing an answer beats reading one. Every idea below
uses only tools already used in `queries/hidden_gems.sql` (`WHERE`, `LIKE`,
`CAST`, `GROUP BY`, `ORDER BY`, CASE, and the INNER JOIN between
`title_basics` and `title_ratings`). If you followed the walkthrough, you
can do all of it.

The method for each idea: predict what will happen first, run it, compare.
The gap between your prediction and the result is where the learning is.

## Change the definition of a gem

1. **Stricter love.** Raise the rating threshold by half a point and rerun
   the gem query. How many of the original gems survive? Read the ones
   that dropped — do you agree with their elimination?
2. **Change the obscurity band.** Widen or narrow the vote-count band that
   defines "hidden." At what vote count does a movie stop feeling hidden
   to you — and can you defend that number the way the walkthrough
   defended its thresholds?

## Slice the gems by a column you haven't used yet

3. **By genre.** `genres` holds comma-separated values, so
   `WHERE b.genres LIKE '%Documentary%'` finds every documentary gem.
   Build a top-10 gem list for a genre you actually watch.
4. **By decade.** A CASE ladder on `startYear` buckets movies into decades
   (`WHEN startYear >= 2020 THEN '2020s'` and so on). Which decade hides
   the most gems? Is old obscurity different from new obscurity?
5. **By runtime.** Filter to `CAST(runtimeMinutes AS INTEGER) <= 90`.
   Great short movies are the most re-watchable gems there are.
6. **Beyond movies.** The gem query filters `titleType = 'movie'`. Point
   the same query at `'tvMovie'` or `'short'` instead. Does the gem signal
   still behave, or do those catalogs need different thresholds?

## Ask a new question of the same data

7. **Gems per decade, counted.** `GROUP BY` the decade bucket from idea 4
   and count gems in each. One query, one table, a finding worth writing
   down.
8. **The missing-data census.** This dataset marks missing values with
   `\N`. Count how many gems have `genres = '\N'` or
   `runtimeMinutes = '\N'`. Knowing how much of your result rests on
   incomplete rows is a real analyst habit, and here it takes one query.
9. **The devotion angle.** Among HIGH-vote movies (the ones the gem query
   excludes), find the lowest-rated. That's the inverse question — famous
   but unloved — and it reuses every skill the gem query taught, just
   pointed the other way.

## Make it yours

The real graduation exercise: pick a question this README never asked,
write the query yourself, and add your finding to your own fork's README
with one sentence on why the threshold you picked is defensible. That last
sentence — defending a number — is the analyst skill everything here has
been building toward.
