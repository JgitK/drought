# STATE — current truth

**Owner: Claude.** Living document, edited in place and overwritten. Never
appended to. If something here is wrong, fix it — do not add a correction below
it. History lives in `git log -p docs/STATE.md`.

_Last updated: 2026-08-12_

---

## Where things are

| What | Path |
|---|---|
| Repo | `C:\Users\John Kent\Projects\drought` (`~/Projects/drought` in Git Bash) |
| venv | `~/Projects/drought/.venv` (inside the repo, gitignored) |
| Warehouse | `~/Projects/drought/warehouse/` (inside the repo, gitignored) |
| dbt project | `~/Projects/drought/transform/` |
| Python 3.12 | `C:\Users\John Kent\AppData\Local\Programs\Python\Python312\python.exe` |

The repo left OneDrive on 2026-08-10. **Any path in an older document naming
OneDrive or `C:\dev\drought` is stale.**

## Environment

- Windows 11, Git Bash. **No conda, no wget.** `tar` (GNU 1.35) and `curl` 8.6.0
  are available.
- **PATH trap:** `python` resolves to the Windows Store Python 3.9.13 shim. Don't
  fight it — activate the venv:
  ```bash
  source ~/Projects/drought/.venv/Scripts/activate
  ```
- Installed: **dbt-core 1.12.0, dbt-duckdb 1.11.0, duckdb 1.5.5**, Python 3.12.10.
  `dbt --version` verified working from the new location.
- **`DROUGHT_DUCKDB_PATH` was deliberately removed.** It existed only to keep the
  `.duckdb` file out of OneDrive's sync scope; that reason is gone. Do not
  re-create it. Caveat that still stands: dbt-duckdb passes `path` straight to
  DuckDB, which resolves relative paths against the **process CWD**, not the
  project dir — so a relative path only works if dbt is always run from
  `transform/`.
- Single C: volume, ~52 GB free. Note the OneDrive folder was always on C: too —
  leaving OneDrive bought sync safety, not disk space.

## Status: Step 0 (dbt skeleton) — IN PROGRESS

**Done**
- venv + all packages, rebuilt in the repo after the move.
- `warehouse/` created; `.gitignore` covers `.venv/`, `warehouse/`, `*.duckdb`.
- `transform/` exists with `models/staging|intermediate|marts`.
- `transform/models/staging/hello.sql` written — **contains a typo: `seelct`.**
  Left in place deliberately; it will be the first real dbt error message.
- Whole `Projects` tree moved out of OneDrive; all 6 repos intact, `git fsck`
  clean, 33,892 files verified.
- **Everything is committed.** `4da1965` added `docs/`, `CLAUDE.md`,
  `transform/`, both handoffs; `17488f2` removed `.DS_Store`. Working tree clean
  on branch `dbt-port`.

**Not done**
- `transform/dbt_project.yml` — still an empty key skeleton (5 bare keys, no
  values).
- `transform/profiles.yml` — still broken: top key `jacksons-gaming-pc`,
  `outputs.dev` empty, and a stray second root key `name:` holding
  `- type: duckdb` / `- path: threads` as a list.
- `dbt debug` / `dbt build` never run successfully.

**Leftover cleanup**
- `rm -rf /c/dev/drought` (superseded venv + warehouse).
- `rmdir` the two empty dirs at the old OneDrive path (blocked until the Claude
  Code session holding a CWD handle there exits).

## Next actions

⚠️ **D-006 is deliberately deferred — do NOT start there.** On 2026-08-12 the
attempt to answer it surfaced a foundational gap (layers, build order, what a
view is). Answering a materialization question before ever watching dbt build a
DAG is backwards. Do the toy-DAG exercise below first; D-006 becomes easy after.
Materialization is one line of YAML and is trivially reversible — it is not a
one-way door.

**THE EXERCISE — start here next session (~30 min, entirely throwaway):**

1. Rewrite `transform/profiles.yml`:
   ```
   <profile name>:
     target: dev
     outputs:
       dev:
         type: duckdb
         path: ...
         threads: 4
   ```
   Decide: absolute `path`, or always `cd transform` first (see the CWD caveat
   under Environment).
2. Rewrite `transform/dbt_project.yml`: flat `name` / `version` / `profile` /
   `model-paths`, then a `models:` block nesting project name → folder names
   (`staging`, `intermediate`, `marts`) → `+materialized:`. **Put `view` on all
   three for now** — this is not answering D-006, it is getting a toolchain.
3. `cd transform && dbt debug`.
4. `dbt build` **with the `seelct` typo still in `hello.sql`** — read the error
   before fixing it. Then fix it.
5. Write **four trivial models with hardcoded fake data** — no NOAA files, no
   fixed-width parsing. Two staging (`select 1 as id, 5.0 as prcp union all …`),
   one intermediate that `ref()`s and joins both, one mart that `ref()`s the
   intermediate. Real names, real folders.
6. `dbt build` and watch the printed order. Then rename a file so it sorts
   alphabetically last and rebuild — **order does not change.** That is the
   folders-vs-DAG lesson landing.
7. `duckdb warehouse/<db>.duckdb` →
   `SELECT table_name, table_type FROM information_schema.tables;`
   Flip one folder to `+materialized: table`, `dbt run`, re-query. Watch `VIEW`
   become `BASE TABLE`. This is the step that makes D-006 concrete.
8. `dbt docs generate && dbt docs serve` — look at the lineage graph.

**Then:**
9. Answer D-006 in `docs/decisions.md`.
10. First `docs/translation-log.md` entry.
11. Begin Step 1 (EL boundary + fixed-width landing).

## The 9-step order

| # | Step | Why here |
|---|---|---|
| 0 | dbt-duckdb skeleton, one trivial model | Prove toolchain before hard logic |
| 1 | EL boundary + fixed-width landing | One continuous decision |
| 2 | Staging: UNPIVOT, dates, `-9999`, `/100` | |
| 3 | The ~1° grid dimension | *Moved up* — independent, easy, gives a 2nd model to `ref()` |
| 4 | Julian rolling window + wraparound | Hardest logic, on clean daily rows |
| 5 | Z-score mart, `HAVING n>=50`, ±2 clip | |
| 6 | `anti_join` → `relationships` tests | *Interleaved*, not saved for last |
| 7 | Incrementality: baseline vs daily append | *Genuinely last* — the benchmark needs a correct baseline |
| 8 | Snakemake DAG → `ref()`, cron → `dbt build` | |
| 9 | Benchmark + translation log assembly | |

## Concepts already taught (don't re-teach unless asked)

- **What a dbt model is:** one `.sql` file, one `SELECT`; dbt wraps it in
  `CREATE VIEW/TABLE AS`; the filename becomes the object name.
- **YAML nesting** (indentation) vs lists (`-`). John's files used `-` wrongly.
- The `profile:` string in `dbt_project.yml` must match the top-level key in
  `profiles.yml`; profiles are many-to-one across projects.
- `target:` selects which `outputs:` entry is default; same SQL, different DB.
- `env_var('NAME', 'fallback')`: fallback = the portable committed path, env var
  = the machine-specific exception. **Now moot here** — see the removed env var.
- **`threads` = DAG-level parallelism, NOT query parallelism.** DuckDB
  parallelizes each query across cores for free. This DAG is near-linear, so
  threads buy ~nothing. Nice symmetry with the GH Action's `snakemake --cores 1`.

_Taught 2026-08-12:_

- **Folders do not control build order.** `staging/`/`intermediate/`/`marts/` are
  plain directories. Order comes from **`ref()`** alone — dbt parses every
  `ref()`, builds a DAG, topologically sorts. A flat folder would build in the
  same order. Folders do two things only: organize files, and act as a **config
  target** for the `models:` block. That is the *only* reason D-006 and the
  directory layout are connected.
- **`view` vs `table` is plain SQL, not dbt.** `CREATE TABLE AS` runs the query
  now and stores rows (pay once at build + disk, goes stale). `CREATE VIEW AS`
  stores only the query text (zero build, zero storage, but **recomputed on every
  read, once per referencing model**). Materialization = which `CREATE` dbt wraps
  the `SELECT` in.
- **What the layers mean:** staging = one model per source, rename/cast/parse/
  sentinels, **no joins, no aggregation**. Intermediate = joins and grain
  changes. Marts = what a consumer asks for. The payoff is isolation of failure,
  not tidiness.

## Layer mapping — derived 2026-08-12, do not re-derive

| Original R | Model | Layer | Notes |
|---|---|---|---|
| `read_split_dly_files.R:25–52` (`read_fwf`, `pivot_longer`, `-9999`, `/100`, `date`) | `stg_daily_prcp` | staging | grain = (station, date). Re-assert `ELEMENT='PRCP'` here — **F-001** |
| `get_regions_years.R:17–26` (`read_fwf` inventory, `filter(element=="PRCP")`) | `stg_inventory` | staging | grain = (station, element) |
| `read_split_dly_files.R:53–63` (julian window, wraparound, `sum` by id/year) | `int_station_year_prcp` | intermediate | grain → (station, year). **F-003** lives here |
| `get_regions_years.R:27–30` (`round()` lat/lon) | `int_grid_cell` | intermediate | step 3. **F-004** lives here |
| `plot_drought_by_region.R:37–40` (`inner_join`, drop partial years, `mean`) | `int_cell_year_prcp` | intermediate | grain → (cell, year) |
| `plot_drought_by_region.R:47–55` (z-score, `n>=50`, clip ±2) | `drought_z_score` | mart | |

```
stg_daily_prcp ──→ int_station_year_prcp ──┐
                                           ├──→ int_cell_year_prcp ──→ drought_z_score
stg_inventory  ──→ int_grid_cell ──────────┘
```

Key point: `read_split_dly_files.R` currently parses **and** windows **and**
aggregates in one script. Only the parsing half is staging.

## Open questions

- Materialization per layer (D-006 — unanswered, **deliberately deferred until
  after the toy-DAG exercise**). Two things to carry in when answering: (a) the
  "views are costly because many children re-run them" argument is **weak here**
  — this DAG is near-linear, nearly every model has one child, so don't borrow it
  from a blog post; the arguments that fit are dev iteration cost on the
  fixed-width parse, testability, and what step 7's incremental model needs to
  exist as a real object. (b) `ephemeral` is inlined **per child** (work runs once
  per child) and **cannot carry schema tests** — usually disqualifying here.
- Validating against R's numbers needs R runnable; conda is not installed.
  **Plan: do NOT install R yet.** Use dbt unit tests with hand-built fixtures
  through steps 1–4; revisit an end-to-end R diff at step 5, against the subset
  only if wanted.
