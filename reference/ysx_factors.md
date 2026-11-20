# Convert columns to factors with specification-controlled ordering

Extends
[`yspec::ys_factors()`](https://metrumresearchgroup.github.io/yspec/reference/ys_factors.html)
with a per-variable `dots: {order: biggest}` setting. `order` must be
`"first"` or `"biggest"`. Missing settings default to `"first"`,
preserving yspec's factor level order. `"biggest"` orders levels by
decreasing frequency in the supplied data. Ties retain the original
level order, and unused levels are retained at the end. Missing
observations do not contribute to counts unless they are an explicit
level.

## Usage

``` r
ysx_factors(data, spec, ..., .keep_values = TRUE, .suffix = "_v")
```

## Arguments

- data:

  the data set to modify.

- spec:

  a yspec object.

- ...:

  unquoted column names for modification; passing nothing through `...`
  will signal for all columns to be considered for factors.

- .keep_values:

  logical; if `TRUE`, value columns will be retained with a `.suffix`.

- .suffix:

  a suffix to be added to original columns (holding values).

## Value

The data frame with selected columns converted to factors.

## Details

Selection, decoding, retained value columns and existing factors follow
[`yspec::ys_factors()`](https://metrumresearchgroup.github.io/yspec/reference/ys_factors.html).
In particular, existing factors are not reordered. Order settings are
validated only for columns being converted. A warning is given when
values that are not in the specification become `NA`.
