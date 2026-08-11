# Findings — what the original code actually does

**Shared ownership.** Claude writes **Observation** — mechanical, verifiable,
with `file:line`. John writes **In my words** — what it means, why it matters,
and what he'd tell a reader.

Don't skip the "In my words" blocks. They're the ones that prove you understand
the port, and they drop almost verbatim into the writeup. If you can't write one
without rereading the observation, that's the signal to ask.

---

## F-001 — `grep "PRCP"` is a coarse filter, not a correct predicate

**Observation.** `code/concatenate_dly.bash` filters the tar stream with
`grep PRCP`. But ELEMENT lives at **columns 18–21** of a `.dly` line; `grep`
matches the string anywhere in the 269-byte record. It happens to be safe here,
but by luck rather than construction.

**In my words:** _(yours — what's the EL/T seam principle here? Why is
"pre-filter for volume, re-assert the predicate in staging" the right shape?)_

---

## F-002 — Missing precipitation is silently recorded as zero rain

**Observation.** `code/read_split_dly_files.R:49` — `replace_na(prcp, "0")`.
The `-9999` sentinel becomes `NA`, then becomes **`0`**. That value flows into
the mean, and therefore into the Z-score.

**In my words:** _(yours — is this a bug or an undeclared analytical decision?
What does it do to a Z-score for an arid cell with sparse coverage? What would
you do instead, and what would that change?)_

---

## F-003 — The "30-day" window is actually 29 days

**Observation.** `case_when((diff < window) & (diff > 0))` — both `diff == 0`
and `diff == 30` fall through every branch, produce `NA`, and get dropped by
`filter(is_in_window)`. Separately, `diff + 365` is hardcoded, so leap years
shift the wraparound by a day.

⚠️ **SQL will not reproduce this by accident.** R's `NA`-fallthrough silently
drops rows; a naive SQL `WHERE` clause won't drop the same ones.

**In my words:** _(yours — per D-004 we preserve this. How do you express an
off-by-one *deliberately* in SQL, and how do you make it obvious to a reader
that it's intentional?)_

---

## F-004 — `region = cur_group_id()` is dead code

**Observation.** Computed at `code/get_regions_years.R:30`, then ignored by
`code/plot_drought_by_region.R:48`, which groups by `(latitude, longitude)`
directly.

Two traps if you port it anyway:
- **R's `round()` is banker's rounding** (half-to-even); DuckDB's is
  half-away-from-zero. `round(72.5)` is **72** in R, **73** in DuckDB. Stations
  on exact `.5` coordinates land in different grid cells.
- A `DENSE_RANK`-derived surrogate key is **unstable across refreshes** — one new
  station in a new cell renumbers everything downstream.

**In my words:** _(yours — step 3 is really "should this dimension exist at
all?" Make the modeling argument either way.)_

---

## F-005 — ⭐ THE SPINE OF THE WRITEUP: SUM decomposes, MEAN and SD do not

**Observation.** The R aggregates **twice** — once per chunk inside
`process_xfiles()`, then again globally after `map_dfr()`. That is only valid
because **SUM is decomposable** (a sum of partial sums is the true sum) while
**MEAN and SD are not** (an average of averages is not the average).

This one fact explains:
- why chunking was possible at all,
- why the Z-score had to wait for a single in-memory frame,
- why you cannot incrementally maintain a Z-score without carrying sufficient
  statistics (`n`, `Σx`, `Σx²`).

**In my words:** _(yours — this is the paragraph the whole writeup rests on.
Take your time. Connect it forward to step 7: what exactly does the incremental
model have to carry, and why?)_

---

## F-006 — Smaller quirks worth a line each

**Observation.**
- `code/plot_drought_by_region.R:38` drops partial first/last years per station
  but **exempts the current year**.
- R's `sd()` is the *sample* sd; DuckDB's `STDDEV` defaults to `STDDEV_SAMP`, so
  they should match — **verify, don't assume**.
- The Snakefile's `get_all_filenames` rule is a **dead DAG node**.
- The GH Action's unconditional `git commit` **fails if the PNG is
  byte-identical** to the previous day's.

**In my words:** _(yours — which of these are worth keeping, and which are
accidents of the original that the port should quietly drop?)_
