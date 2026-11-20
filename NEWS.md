# yspecx (0.1.0)

- (feat) `df_to_yspec()`: Convert a data frame to a yspec specification file
- (feat) `ysx_check_missing()`: New exported missing-value check. Missing values are now disallowed by default; allow them per column with `dots: {na_ok: true}` (replaces `anymissing`). Every data column must be in the specification.
- (feat) `ysx_plt_relab()`: Relabel plot axes, legend titles and facet strips from yspec, with custom variable and facet-level labels, plot-to-spec variable mappings, and validated long/short label selection.
- (feat) `ys_sort_spec_vars()`: Order a loaded specification to match data frame columns while preserving metadata and unmatched specification variables.
- (fix) `ys_write()`: Preserve coded-value labels and write reloadable metadata when saving loaded or sorted specifications.
- (feat) `ysx_factors()`: Extend yspec factor conversion with per-variable `dots$order` settings of `first` (default) or `biggest` (decreasing frequency), retaining unused levels and specification order for ties.
