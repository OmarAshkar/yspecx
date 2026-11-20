# yspecx (0.1.0)

- (feat) `df_to_yspec()`: Convert a data frame to a yspec specification file
- (feat) `ysx_check()`: Also runs `ysx_check_repeats()`, forwarding `error_on_fail`. Groups must be unique by default; set `dots: {pre_grp_count: <n>}` on group columns to require `n` rows, or `pre_grp_count: ~` (null) to skip the check.
- (feat) `ysx_check_missing()`: New exported missing-value check. Missing values are now disallowed by default; allow them per column with `dots: {na_ok: true}` (replaces `anymissing`). Every data column must be in the specification, optionally after merging a second specification (`spec2`), and every specification column must be in the data unless `error_on_fail = FALSE`.
- (feat) `ysx_check_repeats()`: Raise an error when any group defined by the specification's `group: true` columns does not have exactly `count` rows (default 1), unless `error_on_fail = FALSE`, in which case problems are returned. Use `groups` to define the groups in the same call, like `group_by()` then counting rows and checking that none has `n != count`.
- (feat) `ysx_load_pkpdspec()`: Load the bundled `pkpdspec.yaml` specification of standard NONMEM columns (ID, TIME, DV, CMT, EVID, AMT, ...).
- (feat) `ysx_regroup()`: Remove all existing `group` settings from a specification and mark new group columns.
- (feat) `ysx_plt_relab()`: Relabel plot axes, legend titles and facet strips from yspec, with custom variable and facet-level labels, plot-to-spec variable mappings, and validated long/short label selection.
- (feat) `ys_sort_spec_vars()`: Order a loaded specification to match data frame columns while preserving metadata and unmatched specification variables.
- (fix) `ys_write()`: Preserve coded-value labels and write reloadable metadata when saving loaded or sorted specifications.
- (feat) `ysx_factors()`: Extend yspec factor conversion with per-variable `dots$order` settings of `first` (default) or `biggest` (decreasing frequency), retaining unused levels and specification order for ties.
