# Walkthrough Protocol (internal, do not publish)

How guided SQL walkthroughs are run in chat for these portfolio projects.
This is process documentation for Mike + assistant; it stays in private repos
only.

## The rules

1. **Concepts first.** At the very start of the walkthrough, before Step 1,
   post in chat: the complete "SQL FUNCTIONS & KEYWORDS USED (quick
   reference)" glossary (every keyword the project will use, one plain-English
   line each) plus the big-idea mental-model boxes (e.g. "HOW A JOIN THINKS",
   "TWO TABLES, ONE QUESTION", "EVERYTHING IMPORTS AS TEXT").

2. **Every step delivered in chat is the complete commented block:**
   - boxed `STEP N` header with the WHY
   - read-out-loud clause lines, with the `(display)` / `(pull from)` /
     `(keep only)` parentheticals
   - the expected result stated up front
   - the clean SQL underneath (no comments inside the query body)

   Never bare SQL. Never "the comments are in the repo file."

3. **One action per message, in short readable batches.** GUI/setup
   instructions are numbered micro-steps with exact full file paths. Wait for
   confirmation between actions.

4. **Mike runs each step and reports the result.** The confirmed numbers then
   get written back into the .sql file's WHY/RESULTS boxes, the same
   retrospective way the Steam file recorded its counts.

5. **Read the prior project's actual files before starting** (the Steam repo's
   `hidden_gems.sql` and `hidden_gems_joins.sql`) and gap-check against them.
   Don't work from memory of the format.

6. **The walkthrough is the product.** Don't pre-build and push the finished
   analysis. New repos start PRIVATE and only go public when Mike says so.

## Companion docs

- `queries/COMMENT_STYLE.md` — the .sql file comment canon (boxed WHY +
  read-out-loud + clean query).
- `docs/DATABASE_SETUP.md` — DB Browser import walkthrough + the
  three-saves model.
