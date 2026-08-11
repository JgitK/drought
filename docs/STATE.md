# STATE — current truth

**Owner: Claude.** Living document, edited in place and overwritten. Never
appended to. If something here is wrong, fix it — do not add a correction below
it. History lives in `git log -p docs/STATE.md`.

_Last updated: 2026-08-10_

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
- `transform/models/staging/hello.sql` written (verify contents on resume).
- Whole `Projects` tree moved out of OneDrive; all 6 repos intact, `git fsck`
  clean, 33,892 files verified.

**Not done**
- `transform/dbt_project.yml` — still an empty key skeleton.
- `transform/profiles.yml` — still skeletal; top key is `jacksons-gaming-pc`,
  `outputs:`/`target:` empty, `type`/`path`/`threads` wrongly at root as a list.
- `dbt debug` / `dbt build` never run successfully.
- **Nothing is committed.** `git status`: ` M .gitignore`, `?? handoff-1.md`,
  `?? handoff-2.md`, `?? transform/`, `?? docs/`, `?? CLAUDE.md`.

**Leftover cleanup**
- `rm -rf /c/dev/drought` (superseded venv + warehouse).
- `rmdir` the two empty dirs at the old OneDrive path (blocked until the Claude
  Code session holding a CWD handle there exits).

## Next actions

1. **Answer the open decision in `docs/decisions.md`** — which materialization
   each layer gets, and why. Three identical answers means no decision was made.
2. John rewrites `transform/profiles.yml`:
   ```
   <profile name>:
     target: dev
     outputs:
       dev:
         type: duckdb
         path: ...
         threads: 4
   ```
3. John rewrites `transform/dbt_project.yml`: flat `name` / `version` / `profile`
   / `model-paths`, then a `models:` block nesting project name → folder names
   (`staging`, `intermediate`, `marts`) → `+materialized:`.
4. `cd transform && dbt debug`, then `dbt build`.
5. First `docs/translation-log.md` entry.
6. Begin Step 1 (EL boundary + fixed-width landing).

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

## Open questions

- Materialization per layer (see `docs/decisions.md`, D-006 — unanswered).
- Validating against R's numbers needs R runnable; conda is not installed.
  **Plan: do NOT install R yet.** Use dbt unit tests with hand-built fixtures
  through steps 1–4; revisit an end-to-end R diff at step 5, against the subset
  only if wanted.
