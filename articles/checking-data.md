# Checking data against a specification

[`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md)
extends
[`yspec::ys_check()`](https://metrumresearchgroup.github.io/yspec/reference/ys_check.html)
with three checks that are driven by the `dots` of each column in the
specification:

| Check | `dots` setting | Default |
|----|----|----|
| Missing values | `na_ok` | `false`: missing values are not allowed |
| Rows per group | `group`, `pre_grp_count` | each group occurs once |
| Time-varying columns | `group`, `time_varying` | constant within each group |

Missing values must be coded as the specification’s `missing_code`
(`SETUP__: missing_code`) when one is set.

``` r

library(yspecx)

spec <- yspec::ys_select(ysx_load_pkpdspec(), ID, TIME, EVID, DV, CMT)

data <- data.frame(
  ID = c(1, 1, 1, 2, 2),
  TIME = c(0, 1, 2, 0, 1),
  EVID = c(1, 0, 0, 1, 0),
  DV = c(-999, 5.1, 4.2, -999, 6.3),
  CMT = c(1, 2, 2, 1, 2)
)
```

The bundled specification marks `ID` as the group column and sets
`pre_grp_count: ~` (null), because a NONMEM data set has many rows per
subject. `DV` allows missing values, coded as `-999`.

## Run all checks

``` r

ysx_check(data, spec)
#> The data set passed all checks.
```

[`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md)
returns `TRUE` invisibly when everything passes. If any check fails it
prints every problem and stops. Use `error_on_fail = FALSE` to get
`FALSE` back instead.

``` r

bad <- data
bad$CMT[2] <- -999
ysx_check(bad, spec, error_on_fail = FALSE)
#> The data set passed all checks.
#> Additional check messages:
#>   - CMT: 1 missing value(s) found but na_ok is not true (default)
```

Before it runs any check,
[`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md)
asserts that the data and the specification match: every column in
`data` must be a variable in the specification, and every specification
variable must be a column in `data`. With the default
`error_on_fail = TRUE` a mismatch raises an error. With `FALSE` it is
reported with the other problems, and `error_on_fail` is also forwarded
to the individual checks.
[`ysx_check_missing()`](https://omarashkar.github.io/yspecx/reference/ysx_check_missing.md)
is less strict: it only requires the data columns to be in the
specification.

## Missing values

[`ysx_check_missing()`](https://omarashkar.github.io/yspecx/reference/ysx_check_missing.md)
runs only the missing-value check and returns the problems as a
character vector. Every column in `data` must be described in the
specification, otherwise it raises an error (or returns a problem with
`error_on_fail = FALSE`). The specification may describe more columns
than the data has.

``` r

ysx_check_missing(bad, spec)
#> [1] "CMT: 1 missing value(s) found but na_ok is not true (default)"
```

Missing values are not allowed by default. Allow them for a column with
`dots: {na_ok: true}` in the YAML. If the specification has a
`missing_code`, a plain `NA` is a problem even when `na_ok` is true.

A second specification can be merged before checking with `spec2`.
Columns that exist in both keep the definition from `spec`.

``` r

ysx_check_missing(
  data[c("ID", "DV")],
  yspec::ys_select(spec, ID),
  spec2 = yspec::ys_select(spec, DV)
)
#> character(0)
```

## Repeats within groups

[`ysx_check_repeats()`](https://omarashkar.github.io/yspecx/reference/ysx_check_repeats.md)
counts the rows in each group and stops if any group does not have
exactly `count` rows (default 1). It is the equivalent of grouping,
counting, and checking that no count differs from `count`. Missing
values count as a group value.

Pass the grouping columns with `groups` to avoid editing the
specification. The columns must exist in the specification.

``` r

ids <- data.frame(ID = c(1, 1, 2), TIME = c(0, 0, 0))
ysx_check_repeats(ids, spec, groups = c("ID", "TIME"))
#> Error:
#> ! 1 of 2 group(s) defined by ID, TIME do not have 1 row(s) (row counts found: 2)
```

With `error_on_fail = FALSE` the problems are returned instead:

``` r

ysx_check_repeats(ids, spec, groups = c("ID", "TIME"), error_on_fail = FALSE)
```

## Setting groups in the specification

[`ysx_regroup()`](https://omarashkar.github.io/yspecx/reference/ysx_regroup.md)
removes all existing `group` settings and marks new ones.
[`ysx_ungroup()`](https://omarashkar.github.io/yspecx/reference/ysx_ungroup.md)
removes them all. Both return a new specification.

``` r

regrouped <- ysx_regroup(spec, c("ID", "TIME"))
names(Filter(function(x) isTRUE(x$dots$group), regrouped))
#> [1] "ID"   "TIME"

ungrouped <- ysx_ungroup(spec)
names(Filter(function(x) isTRUE(x$dots$group), ungrouped))
#> character(0)
```

Within
[`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md),
the required number of rows per group comes from `pre_grp_count` in the
`dots` of the group columns:

| `pre_grp_count`        | Meaning                        |
|------------------------|--------------------------------|
| not set                | every group must have 1 row    |
| a whole number `n`     | every group must have `n` rows |
| `~`, `null`, or `None` | do not check repeats           |

All group columns that set it must agree.
