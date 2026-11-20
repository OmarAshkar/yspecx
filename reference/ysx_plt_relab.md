# Relabel plot titles, legends and facet strips from a specification

Labels use
[`yspec::axis_labs()`](https://metrumresearchgroup.github.io/yspec/reference/axis_labs.html),
including units. Explicit `labs` entries override specification labels
and can also label variables absent from the specification. Only direct
variable mappings are relabelled; expressions and unmatched labels are
left unchanged. Layer-specific mappings are supported.

## Usage

``` r
ysx_plt_relab(
  x,
  spec = NULL,
  labs = list(),
  facet_labels = list(),
  var_map = character(),
  label_type = NULL
)
```

## Arguments

- x:

  A ggplot object or a list of ggplot objects.

- spec:

  A loaded yspec object, or `NULL` to use only custom labels.

- labs:

  A named list or character vector of variable labels.

- facet_labels:

  A named list of named character vectors mapping facet levels to
  labels, for example `list(SEX = c(F = "Female", M = "Male"))`.

- var_map:

  A named character vector mapping plot variable names to specification
  variable names, for example `c(wt = "WEIGHT")`. This changes label
  lookup only, not plot data or mappings. Custom labels use plot names.

- label_type:

  `NULL` (default) uses the usual axis labels. Otherwise, `"long"` or
  `"short"` selects that specification field, including units. An error
  is raised if the requested field is unavailable for a plotted
  specification variable, unless a custom label overrides it.

## Value

A relabelled plot, or a list of relabelled plots.

## Details

Facet strips show the variable label and level. Coded levels are decoded
using the specification, with optional overrides in `facet_labels`.
Existing facet labellers are replaced. Axis tick labels and legend
entries are not changed. The input plot and specification are not
modified.
