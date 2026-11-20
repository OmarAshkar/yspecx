# Sort specification variables to match a data frame

Sort specification variables to match a data frame

## Usage

``` r
ys_sort_spec_vars(data, spec)
```

## Arguments

- data:

  A data frame whose column order determines the variable order.

- spec:

  A loaded yspec object, as returned by
  [`yspec::ys_load()`](https://metrumresearchgroup.github.io/yspec/reference/ys_load.html).

## Value

A yspec object with matching variables in data frame column order.
Specification variables absent from `data` follow in their original
order. Data columns absent from `spec` are ignored. Metadata is
preserved.
