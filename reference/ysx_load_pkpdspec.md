# Load the bundled PK/PD (NONMEM) specification

Loads the specification shipped with yspecx, which describes standard
NONMEM data set columns such as `ID`, `TIME`, `DV`, `CMT`, `EVID` and
`AMT`. It can be combined with a study-specific specification, for
example through the `spec2` argument of
[`ysx_check_missing()`](https://omarashkar.github.io/yspecx/reference/ysx_check_missing.md).

## Usage

``` r
ysx_load_pkpdspec(...)
```

## Arguments

- ...:

  Further arguments passed to
  [`yspec::ys_load()`](https://metrumresearchgroup.github.io/yspec/reference/ys_load.html).

## Value

A yspec object.
