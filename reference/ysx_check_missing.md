# Check missing values against a specification

Missing values are not allowed by default. A column may contain them
only when its `dots` set `na_ok: true`. Missing values must be encoded
as the spec's `missing_code` (`SETUP__: missing_code`, default `NA`). If
`missing_code` is not `NA`, any `NA` in the data is an error, even when
`na_ok` is `true`.

## Usage

``` r
ysx_check_missing(data, spec, spec2 = NULL, error_on_fail = TRUE)
```

## Arguments

- data:

  A data frame.

- spec:

  A loaded yspec object.

- spec2:

  An optional second yspec object whose additional columns are merged
  into `spec` before checking.

- error_on_fail:

  If `TRUE` (default), an error is raised when a column of `data` is not
  in the (merged) specification. If `FALSE`, such columns are returned
  as problems instead.

## Value

A character vector of problems; `character(0)` if none are found. An
error is raised if a `na_ok` setting is not `true` or `false`.

## Details

Every column in `data` must be described in `spec`. With
`error_on_fail = TRUE` an error lists the unmatched columns, because
their missing-value rules cannot be checked; with `FALSE` they are
returned as problems. Specification columns that are not in `data` are
ignored.

If `spec2` is supplied, it is merged into `spec` with
[`yspec::ys_join()`](https://metrumresearchgroup.github.io/yspec/reference/ys_join.html)
before checking. Columns in both specifications use the definition from
`spec`, and metadata such as `missing_code` also comes from `spec`.
