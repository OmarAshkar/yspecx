# yspecx

yspecx extends [yspec](https://github.com/metrumresearchgroup/yspec) for
validating data sets against their specifications.

## Installation

``` r
# install.packages("pak")
pak::pak("OmarAshkar/yspecx")
```

## What it does

- **Check** a data set: `ysx_check()`, `ysx_check_missing()` and
  `ysx_check_repeats()`.
- **Set groups** in a specification: `ysx_regroup()` and `ysx_ungroup()`.
- **Build and edit** specifications: `df_to_yspec()`, `ys_sort_spec_vars()`,
  `ys_write()` and `ysx_load_pkpdspec()`.
- **Use** a specification: `ysx_factors()` and `ysx_plt_relab()`.

See the [articles](https://omarashkar.github.io/yspecx/articles/) for worked
examples.
