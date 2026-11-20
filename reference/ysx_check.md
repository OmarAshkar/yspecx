# Check a data set against its specification with extra checks

Runs
[`yspec::ys_check()`](https://metrumresearchgroup.github.io/yspec/reference/ys_check.html)
and then three additional checks:

## Usage

``` r
ysx_check(
  data,
  spec,
  verbose = FALSE,
  output = tempfile(),
  error_on_fail = TRUE
)
```

## Arguments

- data:

  a data frame

- spec:

  a yspec object

- verbose:

  `logical`; if `TRUE`, extra messages are printed during the check

- output:

  the name of a file or a connection for writing check results

- error_on_fail:

  if `FALSE`, return logical check status rather than generating an
  error

## Value

Invisibly, `TRUE` if all checks pass; otherwise an error is raised, or
`FALSE` is returned when `error_on_fail = FALSE`.

## Details

1.  Missing values, using
    [`ysx_check_missing()`](https://omarashkar.github.io/yspecx/reference/ysx_check_missing.md).
    By default, columns may not contain missing values; set
    `na_ok: true` in a column's `dots` to allow them.

2.  Repeats within groups, using
    [`ysx_check_repeats()`](https://omarashkar.github.io/yspecx/reference/ysx_check_repeats.md).
    By default, each combination of `group: true` columns must occur
    once. Set `pre_grp_count: <n>` in the `dots` of the group columns to
    require `n` rows, or `pre_grp_count: ~` (YAML null) to skip this
    check. All group columns that set it must agree. `error_on_fail` is
    forwarded.

3.  Time-varying columns. The data are grouped by all columns with
    `group: true` (default `false`). A column with `time_varying: false`
    (default) must be constant within each group; a column with
    `time_varying: true` must vary within at least one group.

Before any check, `data` and `spec` must match: every column in `data`
must be a variable in `spec`, and every variable in `spec` must be a
column in `data`. With `error_on_fail = TRUE` a mismatch raises an
error; with `FALSE` it is reported with the other problems.
[`ysx_check_missing()`](https://omarashkar.github.io/yspecx/reference/ysx_check_missing.md)
on its own only requires the data columns to be in the spec.
