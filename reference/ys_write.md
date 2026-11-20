# Write a yspec object to a YAML file

Writes a standalone specification using YAML input fields rather than
loaded object internals. Lookup and import results are materialized;
their original file references and loader provenance are not written.
Control settings are flattened into `SETUP__`. Variable order,
namespaces and coded-value labels are preserved, but comments and YAML
formatting are not.

## Usage

``` r
ys_write(x, path)
```

## Arguments

- x:

  A yspec object, as returned by
  [`yspec::ys_load()`](https://metrumresearchgroup.github.io/yspec/reference/ys_load.html).

- path:

  Path to the output YAML file, ending in `.yaml` or `.yml`.

## Author

Omar I. Elashkar
