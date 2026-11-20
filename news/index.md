# Changelog

## yspecx 0.1.0

- (feat)
  [`df_to_yspec()`](https://omarashkar.github.io/yspecx/reference/df_to_yspec.md):
  Convert a data frame to a yspec specification file
- (fix)
  [`df_to_yspec()`](https://omarashkar.github.io/yspecx/reference/df_to_yspec.md):
  Stop on duplicate variable names instead of silently keeping the last
  row, and accept `.yml` output paths.
- (feat)
  [`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md):
  Also runs
  [`ysx_check_repeats()`](https://omarashkar.github.io/yspecx/reference/ysx_check_repeats.md),
  forwarding `error_on_fail`. Groups must be unique by default; set
  `dots: {pre_grp_count: <n>}` on group columns to require `n` rows, or
  `pre_grp_count: ~` (null) to skip the check. Data columns and
  specification variables must match in both directions: a mismatch
  raises an error, or is reported with `error_on_fail = FALSE`.
- (feat)
  [`ysx_check_missing()`](https://omarashkar.github.io/yspecx/reference/ysx_check_missing.md):
  New exported missing-value check. Missing values are now disallowed by
  default; allow them per column with `dots: {na_ok: true}` (replaces
  `anymissing`). Every data column must be in the specification (an
  error unless `error_on_fail = FALSE`), optionally after merging a
  second specification (`spec2`). The specification may describe more
  columns than the data has.
- (feat)
  [`ysx_check_repeats()`](https://omarashkar.github.io/yspecx/reference/ysx_check_repeats.md):
  Raise an error when any group defined by the specification’s
  `group: true` columns does not have exactly `count` rows (default 1),
  unless `error_on_fail = FALSE`, in which case problems are returned.
  Use `groups` to define the groups in the same call, like `group_by()`
  then counting rows and checking that none has `n != count`.
- (feat)
  [`ysx_load_pkpdspec()`](https://omarashkar.github.io/yspecx/reference/ysx_load_pkpdspec.md):
  Load the bundled `pkpdspec.yaml` specification of standard NONMEM
  columns (ID, TIME, DV, CMT, EVID, AMT, …).
- (feat)
  [`ysx_ungroup()`](https://omarashkar.github.io/yspecx/reference/ysx_ungroup.md):
  Remove all `group` settings from a specification, so no column defines
  groups.
- (feat)
  [`ysx_regroup()`](https://omarashkar.github.io/yspecx/reference/ysx_regroup.md):
  Remove all existing `group` settings from a specification and mark new
  group columns.
- (feat)
  [`ysx_plt_relab()`](https://omarashkar.github.io/yspecx/reference/ysx_plt_relab.md):
  Relabel plot axes, legend titles and facet strips from yspec, with
  custom variable and facet-level labels, plot-to-spec variable
  mappings, and validated long/short label selection.
- (feat)
  [`ys_sort_spec_vars()`](https://omarashkar.github.io/yspecx/reference/ys_sort_spec_vars.md):
  Order a loaded specification to match data frame columns while
  preserving metadata and unmatched specification variables.
- (fix)
  [`ys_write()`](https://omarashkar.github.io/yspecx/reference/ys_write.md):
  Accept `.yml` output paths. Preserve coded-value labels and write
  reloadable metadata when saving loaded or sorted specifications.
- (feat)
  [`ysx_factors()`](https://omarashkar.github.io/yspecx/reference/ysx_factors.md):
  Extend yspec factor conversion with per-variable `dots$order` settings
  of `first` (default) or `biggest` (decreasing frequency), retaining
  unused levels and specification order for ties. Warns when values that
  are not in the specification become `NA`.
