# Decisions

**Owner: John.** Append-only — once a decision is written it is never edited. If
it turns out wrong, add a new entry that supersedes it and link back. Claude's
job is to pose the question, lay out the options and the tradeoffs, and then
stop. **The "Call" and "Why" lines are John's words.**

The `Why` lines are drafts of the writeup. Write them like you're explaining to
a reader who hasn't seen the code.

---

## D-001 — Target stack: DuckDB + dbt-duckdb
**Date:** 2026-08-07 · **Status:** locked

**Question:** What replaces Bash + R/tidyverse + Snakemake?

**Call:** DuckDB + dbt-duckdb. A thin loader keeps `curl`/`tar`/`grep` outside
dbt. Layered staging → intermediate → marts. Presentation deferred.

**Why:** Free, runs in CI, out-of-core, reads parquet/CSV directly. The original
R/Snakemake code stays in place so both stacks sit side by side in the writeup.

---

## D-002 — Dev against a subset, not full history
**Date:** 2026-08-07 · **Status:** locked

**Question:** Develop against all ~120k stations, or a subset?

**Call:** Subset now (~2–5k stations); one full-history run before the benchmark.

**Why:** Both options produce **identical SQL** — only iteration speed differs.
There is no correctness reason to pay the full-scan cost on every dev loop.

---

## D-003 — Reject the `by_year` CSVs as the build path
**Date:** 2026-08-07 · **Status:** locked

**Question:** NOAA publishes per-year CSVs. Use those instead of the `.dly`
tarball?

**Call:** No — build from the `.dly` tarball. But **recommend `by_year` in the
writeup's conclusion**, for the incremental case only.

**Why:** Using the CSVs would delete the two lessons the project exists to teach
— fixed-width parsing and tar-streaming. The sharpened claim to build toward,
with numbers from step 7: `by_year` is *worse for a cold backfill* (~275 files,
and CSV repeats station id + date on every observation where `.dly` packs 31 days
into one 269-byte line), but *decisively better for the daily incremental* (fetch
one year's file, not a 3.6 GB tarball).

---

## D-004 — Fidelity first: preserve the R's bugs
**Date:** 2026-08-07 · **Status:** locked

**Question:** Port the R's quirks faithfully, or fix them on the way?

**Call:** Preserve bug-for-bug first, then fix in a documented second pass.

**Why:** A port you can't diff against the original isn't a port. And the bugs
(see `findings.md`) are the most interesting material in the writeup — silently
correcting them throws that away.

---

## D-005 — `threads: 4`, dev output only
**Date:** 2026-08-07 · **Status:** locked

**Call:** `threads: 4`, only a `dev` output for now. Add `prod` at step 8.

**Why:** `threads` is DAG-level parallelism, not query parallelism — DuckDB
parallelizes each query across cores for free, and this DAG is near-linear, so
the number is nearly cosmetic here.

---

## D-006 — Materialization per layer — ⬜ **UNANSWERED**
**Date raised:** 2026-08-07 · **Status:** OPEN — blocks `dbt_project.yml`

**Question:** Which materialization does each layer get — `view`, `table`, or
`ephemeral` — and why?

**The options, and what each actually costs:**

| | What it does | Costs | Earns its keep when |
|---|---|---|---|
| `view` | Stores the SQL; re-runs on every query | Zero build time, zero storage. Recomputed *every* time it's referenced | Cheap transforms; the source is already fast to scan |
| `table` | Runs once at build, stores the result | Build time + disk. Stale until the next `dbt build` | Expensive transforms read many times downstream |
| `ephemeral` | Not built at all — inlined as a CTE into its children | No object exists; can't be queried or tested directly | Thin glue you never want to materialize or inspect |

**Things worth weighing before you answer:**
- Which layer gets read *repeatedly* by downstream models? That's where a `view`
  quietly re-runs the same scan many times.
- Which layer do you need to be able to **inspect or test directly**? Ephemeral
  models can't be — they have no database object.
- The Z-score needs a full pass over ~50 years. Where does that cost land, and
  how many times does it get paid?
- DuckDB is columnar and fast; a `view` over parquet is not the same performance
  story as a `view` over a row-store.

⚠️ **If your answer is the same for all three layers, you haven't made a decision
yet** — you've picked a default. Each layer has a different read pattern.

**Call:** _(yours)_

**Why:** _(yours — one paragraph, writeup-quality)_
