# Factor ordering with ysx_factors

[`ysx_factors()`](https://omarashkar.github.io/yspecx/reference/ysx_factors.md)
extends
[`yspec::ys_factors()`](https://metrumresearchgroup.github.io/yspec/reference/ys_factors.html)
with per-variable ordering through `dots$order`. It converts coded
values to labelled factors while retaining the original values in
columns ending in `_v` by default.

## Specify the order in YAML

Set `order` to `first` to keep the level order defined in the
specification, or `biggest` to sort levels by decreasing frequency in
the data being converted. Omitting `order` is equivalent to `first`. No
other values are accepted.

``` yaml
SETUP__:
  description: Example factor ordering
RESPONSE:
  values: {Low: 1, Medium: 2, High: 3, Unused: 4}
  dots: {order: first}
```

The following example creates and loads this specification. In a
project, pass the path to your existing YAML file to
[`yspec::ys_load()`](https://metrumresearchgroup.github.io/yspec/reference/ys_load.html)
instead.

``` r

library(yspecx)

spec_path <- tempfile(fileext = ".yaml")
yaml::write_yaml(
  list(
    SETUP__ = list(description = "Example factor ordering"),
    RESPONSE = list(
      values = list(Low = 1, Medium = 2, High = 3, Unused = 4),
      dots = list(order = "first")
    )
  ),
  spec_path
)
spec <- yspec::ys_load(spec_path)
unlink(spec_path)

data <- data.frame(ID = seq_len(7), RESPONSE = c(3, 2, 2, 3, 2, 1, NA))
```

## Preserve specification order

`first` refers to specification order, not the order of first appearance
in the data. Here `High` appears first in the data, but `Low` is the
first factor level.

``` r

first <- ysx_factors(data, spec)
levels(first$RESPONSE)
#> [1] "Low"    "Medium" "High"   "Unused"
head(first)
#>   ID RESPONSE RESPONSE_v
#> 1  1     High          3
#> 2  2   Medium          2
#> 3  3   Medium          2
#> 4  4     High          3
#> 5  5   Medium          2
#> 6  6      Low          1
```

## Order from biggest to smallest

Change the setting in the YAML file, or update the loaded specification:

``` r

spec$RESPONSE$dots$order <- "biggest"
biggest <- ysx_factors(data, spec)
levels(biggest$RESPONSE)
#> [1] "Medium" "High"   "Low"    "Unused"
table(biggest$RESPONSE, useNA = "ifany")
#> 
#> Medium   High    Low Unused   <NA> 
#>      3      2      1      0      1
```

`Medium` occurs three times, `High` twice and `Low` once. The unused
level remains last. Missing observations do not contribute to these
counts unless they are an explicit factor level. The underlying
observations are not sorted or changed; only the level order changes.

Frequencies are calculated from the data supplied to each call. If
levels have equal counts, their relative order follows the original
yspec factor order.

``` r

tied <- ysx_factors(data.frame(RESPONSE = c(3, 2)), spec)
levels(tied$RESPONSE)
#> [1] "Medium" "High"   "Low"    "Unused"
```

Although `High` appears first, `Medium` precedes it because they have
equal counts and `Medium` comes first in the specification. Unused
levels also keep their relative specification order.

## Select columns and retain original values

Column selection and value-column options follow
[`yspec::ys_factors()`](https://metrumresearchgroup.github.io/yspec/reference/ys_factors.html).
Pass unquoted column names to restrict conversion. Use
`.keep_values = FALSE` to omit the original codes, or `.suffix` to
choose their column suffix.

``` r

selected <- ysx_factors(data, spec, RESPONSE, .keep_values = FALSE)
names(selected)
#> [1] "ID"       "RESPONSE"

with_codes <- ysx_factors(data, spec, RESPONSE, .suffix = "_code")
head(with_codes)
#>   ID RESPONSE RESPONSE_code
#> 1  1     High             3
#> 2  2   Medium             2
#> 3  3   Medium             2
#> 4  4     High             3
#> 5  5   Medium             2
#> 6  6      Low             1
```

## Existing factors and validation

Existing factor columns are left unchanged, including their level order.
To change the ordering after a previous conversion, call
[`ysx_factors()`](https://omarashkar.github.io/yspecx/reference/ysx_factors.md)
on the original coded data rather than the factor output.

``` r

unchanged <- ysx_factors(first, spec)
identical(levels(unchanged$RESPONSE), levels(first$RESPONSE))
#> [1] TRUE
```

An invalid `dots$order` setting raises an error when that variable is
converted. Settings on unselected variables or existing factors are not
validated.
