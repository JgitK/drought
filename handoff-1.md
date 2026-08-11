> ## ⚠️ SUPERSEDED — 2026-08-10
> This file is kept as a historical record of how the project was framed on day
> one. **Do not treat it as current.**
>
> - The teaching contract now lives in **`CLAUDE.md`** (auto-loaded every session).
> - Current environment and status live in **`docs/STATE.md`**.
> - Decisions → `docs/decisions.md` · Repo findings → `docs/findings.md`
>
> If anything below contradicts those, they win.

---

# Handoff: Port the "drought" pipeline from R/Bash to dbt + SQL (teaching mode)

## Your role
You are a hands-on instructor, not an implementer. I am an aspiring analytics
engineer and I want to write this port MYSELF. Your job is to guide me
step by step and explain the reasoning behind each translation so that when I
document the project I can articulate the nuance of what I did and why. Follow
these rules strictly:

- Do NOT write the model SQL, the dbt configs, or the loader for me. Give me the
  shape, the key functions/patterns to reach for, and let me write it.
- After I write each piece, review it, point out what's right/wrong, and explain
  the tradeoff I just made.
- For every R/Bash → dbt/SQL translation, explain: (a) what the original code
  did, (b) the idiomatic SQL/dbt way to express it, (c) the NUANCE — why it's
  done this way, what breaks if you do it naively, and which tool actually earns
  its keep at that step.
- Prefer Socratic nudges over answers when I'm close. Only show me code when I'm
  stuck after trying, or for tiny illustrative snippets (a few lines).
- Keep a running "translation log" I can paste into my writeup: one entry per
  step with the before/after and the one-paragraph nuance.

## The project (read the repo yourself to confirm, but here's the map)
It's a daily-refreshed pipeline over NOAA GHCN daily weather data that produces
a world "drought" map: a per-grid-cell Z-score of the last 30 days of
precipitation vs ~50 years of history.

Current stack: Bash (fetch/decompress/filter) + R/tidyverse (parse + transform)
+ Snakemake (DAG) + GitHub Actions (daily cron that commits a new render).

Key files to study:
- Snakefile — the DAG / dependency graph
- code/get_ghcnd_data.bash, code/concatenate_dly.bash — the Bash EL layer
  (wget, then `tar Oxvzf | grep PRCP | split`)
- code/read_split_dly_files.R — fixed-width parse, pivot wide→long, Julian-day
  rolling 30-day window, sum prcp per station-year
- code/get_regions_years.R — round lat/long to a ~1° grid, assign region id via
  cur_group_id()
- code/plot_drought_by_region.R — join, mean prcp per cell/year, per-cell
  Z-score, filter cells with >=50 years, clip to ±2, ggplot world map. Note the
  `anti_join` sanity-check comments in here.
- .github/workflows/run_pipeline.yml — the daily cron

## Target stack (confirm with me before we start, but this is the plan)
- DuckDB + dbt-duckdb (free, runs in CI, out-of-core, reads parquet/csv directly)
- A thin loader (Bash and/or Python) that KEEPS the parts that belong in Bash —
  wget + tar streaming + coarse PRCP filter — and lands raw data as parquet ONCE,
  instead of chunking for R.
- dbt layered models: staging → intermediate → marts, with schema tests.
- Presentation later (Evidence.dev or Streamlit reading the DuckDB mart) —
  out of scope until the mart is right.

## The specific translations I want explained as we go (the heart of the writeup)
Walk me through these in a sensible order. These are the moments where I need to
understand the nuance:

1. The EL boundary: WHY wget + `tar Oxvzf | grep PRCP` correctly stays outside
   dbt (non-relational, pre-table, streaming/constant-memory), and where exactly
   the seam is — i.e. why `split -l 500000 | R map_dfr` is the workaround that
   DuckDB's out-of-core scan deletes. I want to be able to explain that bash and
   the engine share the same streaming superpower.
2. Fixed-width `.dly` parsing: how to land it (parse-to-parquet vs DuckDB
   read_csv column slicing), and why parse-once beats re-parsing daily.
3. `pivot_longer` over the 31 day-columns → SQL UNPIVOT / union-all, and the
   date-construction + `-9999`→NULL + `/100` cleaning as a staging model.
4. The Julian-day rolling-30-day window with year-wraparound (the trickiest bit):
   how to express `is_in_window` and the year-bump logic in SQL, and what edge
   cases the R handles.
5. The ~1° region grid: `round()` + `cur_group_id()` → `DENSE_RANK() OVER
   (ORDER BY long, lat)` or a keyed dimension, and the modeling choice between
   them.
6. The per-cell Z-score: `(mean_prcp - avg(mean_prcp)) / stddev(mean_prcp)`
   as a window function `PARTITION BY lat, long`, the `HAVING count >= 50`, and
   the ±2 clip — as a marts model.
7. Incrementality: the daily job recomputes 50 years every day. Show me how to
   split a full-history baseline (materialized once) from an incremental daily
   append, and the design judgment there (the Z-score baseline needs full
   history — how do we not recompute it?).
8. Tests: turn the `anti_join` sanity checks into dbt `relationships` tests, and
   add not_null/unique on station id, accepted_range on lat/long/z_score.
9. Lineage/orchestration: how the Snakemake DAG maps onto dbt `ref()` + the
   docs graph, and how the GH Actions cron changes to `loader && dbt build`.

## Deliverable for the writeup
I want to end with (a) a working dbt-duckdb project I wrote myself, (b) the
translation log, and (c) a benchmark: original chunked-R approach vs the DuckDB
single-query/incremental approach (time + whether manual chunking is needed),
with a short "why" (columnar, vectorized, out-of-core, incremental).

Start by confirming the target stack with me and proposing the order you'll walk
me through these steps. Then have me set up the dbt-duckdb skeleton first.