# Translation log

**Owner: John.** This is the deliverable — the thing that gets pasted into the
writeup. Claude reviews, corrects, and pushes back; Claude does **not** draft
entries. One entry per step of the 9-step order in `docs/STATE.md`.

Write each entry *after* the step works, while the reasoning is fresh. The three
required sections mirror the teaching contract: **what the original did**, **the
idiomatic form**, and **the nuance**. The nuance paragraph is the one that
matters — anyone can show two code blocks.

---

## Template — copy this for each entry

```markdown
## Step N — <short title>
**Date:** YYYY-MM-DD

### Before (R / Bash)
​```r
<the original, trimmed to what matters>
​```

### After (dbt / SQL)
​```sql
<what I wrote>
​```

### The nuance
<One paragraph, in my own words. Why is it done this way? What breaks if you do
it naively? Which tool actually earns its keep at this step — and would a
simpler tool have done the job?>

### What surprised me
<Optional, one or two lines. These are the most readable parts of a writeup.>
```

---

## Step 0 — dbt-duckdb skeleton
**Date:** _(fill when `dbt build` succeeds)_

### Before
Snakemake DAG + a conda `environment.yml`; no project scaffold, no warehouse —
R scripts invoked directly by rule.

### After
_(yours: `dbt_project.yml`, `profiles.yml`, one trivial model)_

### The nuance
_(yours. Prompts, not answers — pick what's actually interesting:_
- _What does `dbt_project.yml` do that `Snakefile` did, and what does itـnot do?_
- _Why is `profiles.yml` separate from `dbt_project.yml`, and why is that
  separation the right call for a repo that runs in both CI and on your machine?_
- _What did choosing a materialization per layer actually commit you to?
  (see D-006)_
- _`threads: 4` — after what you learned, is that number doing anything?)_

### What surprised me
_(yours)_
