# Check the number of rows in each group

Groups the data by every column with `group: true` in `spec` (see
[`ysx_regroup()`](https://omarashkar.github.io/yspecx/reference/ysx_regroup.md))
and reports groups that do not have exactly `count` rows. This is
equivalent to counting rows by the group columns and checking that none
has `n != count`. Missing values count as a group value.

## Usage

``` r
ysx_check_repeats(data, spec, count = 1, error_on_fail = TRUE, groups = NULL)
```

## Arguments

- data:

  A data frame.

- spec:

  A loaded yspec object.

- count:

  The required number of rows in every group; a single positive whole
  number. The default, `1`, means that group values must be unique.

- error_on_fail:

  If `TRUE` (default), an error is raised when a group column in `spec`
  does not exist in `data`, or when any group does not have `count`
  rows. If `FALSE`, nothing is raised; problems are returned and only
  the group columns found in `data` are used.

- groups:

  Optional character vector of columns that define the groups, used
  instead of the `group: true` columns in `spec`. See
  [`ysx_regroup()`](https://omarashkar.github.io/yspecx/reference/ysx_regroup.md).

## Value

Invisibly, `character(0)` if no problems are found. With
`error_on_fail = FALSE`, a character vector describing any problems.

## Details

If `groups` is supplied, it replaces the group columns of `spec` first,
as with
[`ysx_regroup()`](https://omarashkar.github.io/yspecx/reference/ysx_regroup.md),
so the whole check can be written as one call. If there are no group
columns, nothing can be checked and `character(0)` is returned.

## Examples

``` r
if (FALSE) { # \dontrun{
ysx_check_repeats(aetab, spec, groups = c("USUBJIDN", "AFRLT", "DCXLFLN"))
} # }
```
