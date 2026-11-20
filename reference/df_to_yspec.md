# Convert a data frame to a yspec yaml file

Convert a data frame to a yspec yaml file

## Usage

``` r
df_to_yspec(
  x,
  desc = "",
  projectid = "",
  varname,
  vardesc = NULL,
  varunit = NULL,
  vartype = NULL,
  output = "yspec.yaml",
  varcodelist = NULL,
  codelist_func = parse_yspec_codelist
)
```

## Arguments

- x:

  data frame to convert

- desc:

  description parameter for the yspec file

- projectid:

  projectid parameter for the yspec file

- varname:

  column specifying variable names to include in the yspec file

- vardesc:

  column specifying variable descriptions to include in the yspec file

- varunit:

  column specifying variable units to include in the yspec file

- vartype:

  column specifying variable types to include in the yspec file

- output:

  name of the output yspec file, ending in `.yaml` or `.yml`

- varcodelist:

  column containing coded values (comma- or newline-separated)

- codelist_func:

  function taking a codelist string and returning a named list of codes

## Author

Omar I. Elashkar
