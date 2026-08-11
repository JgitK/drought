> ## ⚠️ SUPERSEDED — 2026-08-10
> Kept as a historical record. Its contents have been split by lifecycle into:
>
> | Was here | Now lives in |
> |---|---|
> | Environment facts, status, next actions | **`docs/STATE.md`** (living) |
> | Locked decisions | **`docs/decisions.md`** (append-only) |
> | Repo findings | **`docs/findings.md`** |
> | Teaching-mode rules | **`CLAUDE.md`** (auto-loaded) |
>
> **`docs/STATE.md` is the only source of truth for environment and status.**
> This file already went authoritative-and-wrong once — its "do not re-derive"
> environment section survived a repo move intact and pointed at paths that no
> longer existed. That is the failure this split exists to prevent.

---

# Handoff 2 — drought R/Bash → dbt-duckdb port (resume point)

**Session date:** 2026-08-07 → 08. Read `handoff-1.md` first: it defines the
teaching-mode contract and is still fully in force.

## Teaching-mode rules (carried forward, unchanged)
- Do NOT write the model SQL, the dbt configs, or the loader for me. Give shape,
  key functions/patterns; I write it.
- Review what I write, say what's right/wrong, explain the tradeoff I just made.
- Every translation: (a) what the R/Bash did, (b) idiomatic dbt/SQL, (c) the
  NUANCE — why, what breaks if done naively, which tool earns its keep.
- Socratic nudges over answers. Code only when I'm stuck after trying, or tiny
  illustrative snippets.
- Keep a running translation log for the writeup.

Note: environment plumbing (installers, venv, dirs) is fair game for the
assistant to just do — the ban is on model SQL, dbt configs, and the loader.

---

## STATUS: Step 0 (skeleton) — IN PROGRESS, NOT COMPLETE

### Done
- Python 3.12.10 installed via winget.
- venv now at **`~/Projects/drought/.venv`** (rebuilt in place after the move;
  venvs bake absolute paths into `pyvenv.cfg` + `Scripts/`, so it could not be
  moved). `dbt --version` verified working.
- Installed: **dbt-core 1.12.0, dbt-duckdb 1.11.0, duckdb 1.5.5**.
- **`~/Projects/drought/warehouse/`** created (empty), gitignored.
- Created `transform/` with `models/staging|intermediate|marts`.
- `transform/models/staging/hello.sql` created (verify contents on resume).
- `.gitignore` modified (uncommitted) — now also ignores `.venv/`, `warehouse/`.
- **2026-08-10: whole `Projects` tree moved out of OneDrive** to
  `C:\Users\John Kent\Projects\`. All 6 repos intact, `git fsck` clean,
  33,892 files verified. `DROUGHT_DUCKDB_PATH` removed.

### Not done
- `transform/dbt_project.yml` — still an empty key skeleton.
- `transform/profiles.yml` — still skeletal; top key is `jacksons-gaming-pc`,
  `outputs:`/`target:` empty, `type`/`path`/`threads` wrongly at root as a list.
- `dbt debug` / `dbt build` never run successfully.
- Leftover cleanup: `rm -rf /c/dev/drought` (old venv+warehouse, superseded),
  and `rmdir` the two empty dirs left at the old OneDrive path.

### Nothing is committed
`git status`: ` M .gitignore`, `?? handoff-1.md`, `?? handoff-2.md`, `?? transform/`

---

## Environment facts (do not re-derive)

> **UPDATED 2026-08-10 — the repo MOVED. Everything below supersedes the paths
> used earlier in this document.**

- **Repo now lives at `C:\Users\John Kent\Projects\drought`** (`~/Projects/drought`
  in Git Bash). It is **no longer inside OneDrive.** The whole `Projects`
  directory was moved out on 2026-08-10.
- Windows 11, Git Bash available. **No conda, no wget.** `tar` (GNU 1.35) and
  `curl` 8.6.0 ARE available.
- **PATH trap:** `python` still resolves to the Windows Store Python 3.9.13.
  Do not fight it. Use the venv, which now lives **inside the repo**:
  ```
  source ~/Projects/drought/.venv/Scripts/activate
  ```
  Python 3.12.10; the interpreter itself is at
  `C:\Users\John Kent\AppData\Local\Programs\Python\Python312\python.exe`.
  Installed: dbt-core 1.12.0, dbt-duckdb 1.11.0, duckdb 1.5.5. `dbt --version`
  verified working from the new location.
- **Warehouse is now `~/Projects/drought/warehouse/`** (inside the repo,
  gitignored). `.gitignore` gained `.venv/` and `warehouse/`.
- **`DROUGHT_DUCKDB_PATH` has been REMOVED.** The env-var indirection existed
  only to keep the `.duckdb` file out of OneDrive's sync scope. That problem no
  longer exists, so `profiles.yml` can carry a committed relative path.
  Remaining caveat is unchanged: dbt-duckdb passes `path` straight to DuckDB,
  which resolves relative paths against the **process CWD**, not the project
  dir — so a relative path only works if dbt is always run from `transform/`.
- Disk: single C: volume, ~52 GB free. Note the OneDrive folder was always on C:
  too — leaving OneDrive bought sync safety, not disk space.

### Windows/Git-Bash tooling lessons from the move (worth not repeating)
- A directory rename **out of a OneDrive sync root is refused** while the
  `cldflt` cloud-filter driver is attached. Killing `OneDrive.exe` makes it
  *worse*, not better: the driver stays attached with no provider to service it,
  so operations return `ERROR_ACCESS_DENIED`. Leave OneDrive running.
- `Move-Item` silently degrades from atomic rename to per-file copy+delete, and
  a mid-way failure leaves the tree split across two locations with no manifest.
  Use `robocopy /E /MOVE /R:3 /W:2 /TEE /LOG:...` instead — retries, logging,
  long-path support. Default retry is 1,000,000 × 30s, so always set `/R` `/W`.
- **robocopy's exit code is a bitmask: 0–7 = success, ≥8 = failure.**
- Calling robocopy from Git Bash requires **`MSYS_NO_PATHCONV=1`**, or MSYS
  rewrites switches that look like paths — `/E` becomes `E:/`.
- Windows cannot delete a directory any process is *standing in* (CWD holds a
  handle) — `ERROR 32` sharing violation. Same class of problem as the
  `git fsmonitor--daemon`, which must be stopped before a bulk move.
- `cygpath -w` / `cygpath -u` converts between `/c/...` and `C:\...`;
  `explorer .` opens the current bash directory in File Explorer.

---

## Decisions locked this session
1. **Stack confirmed:** DuckDB + dbt-duckdb, thin loader keeping wget/tar/grep
   outside dbt, layered staging → intermediate → marts, presentation later.
2. **Dev data:** subset now (~2–5k stations), one full-history run before the
   benchmark. Options 1 and 2 produce identical SQL; only iteration speed differs.
3. **`by_year` CSVs:** rejected as the build path (would delete the fixed-width
   parse and tar-streaming lessons), but user wants to **recommend it in the
   writeup's conclusion.** Sharpened claim to build toward, with numbers from
   step 7: *worse for a cold backfill* (~275 files, CSV repeats station id + date
   per observation vs `.dly` packing 31 days into one 269-byte line), *decisively
   better for the daily incremental* (fetch one year's file, not a 3.6 GB tarball).
4. **Fidelity:** preserve the R's quirks bug-for-bug first, then fix in a
   documented second pass.
   - Deferred dependency: validating against R's numbers needs R runnable, and
     the conda env is not installed. **Plan: do NOT install R yet.** Use dbt unit
     tests (dbt 1.8+) with hand-built fixtures through steps 1–4; revisit an
     end-to-end R diff at step 5, and if wanted, run R against the subset only.
5. `threads: 4`, and only a `dev` output for now. Add `prod` at step 8.

---

## Repo findings (the writeup's raw material — do not re-derive)
1. **`grep "PRCP"` is a coarse filter, not a correct predicate.** ELEMENT lives
   at cols 18–21 of a `.dly` line; grep matches anywhere in the 269-byte line.
   Safe by luck, not construction. This is the EL/T seam: pre-filter for volume,
   re-assert the predicate in staging.
2. **`read_split_dly_files.R:49` — `replace_na(prcp, "0")`.** `-9999` → NA → **0**.
   Missing precipitation is recorded as *no rain*, and it flows into the mean and
   therefore the Z-score. An undeclared analytical decision, not a bug.
3. **The window is 29 days, not 30.** `case_when((diff < window) & (diff > 0))` —
   `diff == 0` and `diff == 30` fall through every branch → NA → dropped by
   `filter(is_in_window)`. Also `diff + 365` is hardcoded, so leap years shift the
   wraparound by a day. SQL will NOT silently drop NULLs the same way.
4. **`region = cur_group_id()` is dead code.** Computed in
   `get_regions_years.R:30`, ignored by `plot_drought_by_region.R:48`, which
   groups by `(latitude, longitude)` directly. So step 5 is really "should this
   dimension exist at all?" Related trap: R's `round()` is banker's rounding
   (half-to-even), DuckDB's is half-away-from-zero — `round(72.5)` is 72 in R,
   73 in DuckDB. Stations on exact `.5` coords land in different grid cells.
   Also: a `DENSE_RANK`-derived surrogate key is UNSTABLE across refreshes — a
   new station in a new cell renumbers everything downstream.
5. **THE SPINE OF THE WRITEUP.** The R aggregates twice — per chunk inside
   `process_xfiles()`, then again globally after `map_dfr()`. That works only
   because **SUM is decomposable and MEAN/SD are not.** That one fact explains
   why chunking was possible, why the Z-score had to wait for a single in-memory
   frame, and why you cannot incrementally maintain a Z-score without carrying
   sufficient statistics (n, Σx, Σx²). Everything in the project rhymes with it.
6. Other: `plot_drought_by_region.R:38` drops partial first/last years per station
   but exempts the current year. `sd()` in R is the *sample* sd — DuckDB's
   `STDDEV` defaults to `STDDEV_SAMP`, so they match (but verify, don't assume).
   Snakefile's `get_all_filenames` rule is a dead DAG node. The GH Action's
   unconditional `git commit` fails if the PNG is byte-identical.

---

## The 9-step order (resequenced from handoff-1)
| # | Step | handoff-1 # | Why here |
|---|---|---|---|
| 0 | dbt-duckdb skeleton, one trivial model | — | Prove toolchain before hard logic |
| 1 | EL boundary + fixed-width landing | 1 + 2 | One continuous decision |
| 2 | Staging: UNPIVOT, dates, `-9999`, `/100` | 3 | |
| 3 | The ~1° grid dimension | **5** | *Moved up* — independent, easy, gives a 2nd model to `ref()` |
| 4 | Julian rolling window + wraparound | 4 | Hardest logic, on clean daily rows |
| 5 | Z-score mart, `HAVING n>=50`, ±2 clip | 6 | |
| 6 | `anti_join` → `relationships` tests | **8** | *Interleaved from step 2*, not saved for last |
| 7 | Incrementality: baseline vs daily append | 7 | *Genuinely last* — the benchmark needs a correct baseline to measure |
| 8 | Snakemake DAG → `ref()`, cron → `dbt build` | 9 | |
| 9 | Benchmark + translation log assembly | — | |

---

## Concepts already taught (don't re-teach unless asked)
- What a dbt model is: one `.sql` file, one `SELECT`; dbt wraps it in
  `CREATE VIEW/TABLE AS`; filename becomes the object name.
- YAML nesting (indentation) vs lists (`-`). User's files used `-` wrongly.
- The `profile:` string in `dbt_project.yml` must match the top-level key in
  `profiles.yml`; profiles are many-to-one across projects.
- `target:` selects which `outputs:` entry is default; same SQL, different DB.
- `env_var('NAME', 'fallback')`: **fallback = portable relative path (committed,
  used by CI and clones); env var = the machine-specific exception (this machine
  has the OneDrive problem, CI does not).** Caveat: dbt-duckdb passes `path`
  straight to DuckDB, which resolves relative paths against the *process CWD*,
  not the project dir — a legitimate argument for making both absolute.
- `threads` = DAG-level parallelism, NOT query parallelism. DuckDB parallelizes
  each query across cores for free. The DAG here is near-linear, so threads buy
  ~nothing. Nice symmetry with the GH Action's `snakemake --cores 1`.

---

## IMMEDIATE NEXT ACTIONS on resume

> ~~1. Set the env var `DROUGHT_DUCKDB_PATH`~~ — **OBSOLETE.** The var was
> deliberately removed on 2026-08-10 when the repo left OneDrive. Do not
> re-create it; put a relative path in `profiles.yml` instead (see Environment
> facts for the CWD caveat).

1. User rewrites `transform/profiles.yml` to this shape (values are theirs):
   ```
   <profile name>:
     target: dev
     outputs:
       dev:
         type: duckdb
         path: ...
         threads: 4
   ```
3. User rewrites `transform/dbt_project.yml`: flat `name` / `version` / `profile` /
   `model-paths`, then a `models:` block nesting project name → folder names
   (`staging`, `intermediate`, `marts`) → `+materialized:`.
4. **Outstanding question the user still owes an answer to:** decision (a) —
   which materialization each layer gets, and why. Three identical answers means
   no decision was made. This is the one to press on.
5. `cd transform && dbt debug`, then `dbt build`.
6. Then start step 1 (EL boundary + fixed-width landing).

## Also outstanding
- Translation log (`docs/translation-log.md`) promised but not yet created —
  first entry lands after step 0 completes.
