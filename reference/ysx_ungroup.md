# Remove the group columns of a specification

Removes every `group` setting from the `dots` of `spec`, so that no
column defines groups. Other `dots` settings are kept, including
`pre_grp_count`, which has no effect while there are no group columns.
Use
[`ysx_regroup()`](https://omarashkar.github.io/yspecx/reference/ysx_regroup.md)
to set new groups.

## Usage

``` r
ysx_ungroup(spec)
```

## Arguments

- spec:

  A loaded yspec object.

## Value

A yspec object without group columns. `spec` is not modified.

## Details

With no group columns,
[`ysx_check_repeats()`](https://omarashkar.github.io/yspecx/reference/ysx_check_repeats.md)
has nothing to check, and
[`ysx_check()`](https://omarashkar.github.io/yspecx/reference/ysx_check.md)
skips its repeat and time-varying checks.
