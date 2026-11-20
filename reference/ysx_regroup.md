# Replace the group columns of a specification

Removes every existing `group` setting from the `dots` of `spec`, then
marks the columns in `groups` with `group: true`. Other `dots` settings
are kept. The group columns are used by
[`ysx_check_repeats()`](https://omarashkar.github.io/yspecx/reference/ysx_check_repeats.md)
and
[`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md).
Use
[`ysx_ungroup()`](https://omarashkar.github.io/yspecx/reference/ysx_ungroup.md)
to remove all groups.

## Usage

``` r
ysx_regroup(spec, groups)
```

## Arguments

- spec:

  A loaded yspec object.

- groups:

  A character vector naming one or more columns in `spec`.

## Value

A yspec object with the new group columns. `spec` is not modified.
