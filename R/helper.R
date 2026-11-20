#' Convert a data frame to a yspec yaml file
#' @param x data frame to convert
#' @param desc description parameter for the yspec file
#' @param projectid projectid parameter for the yspec file
#' @param varname column specifying variable names to include in the yspec file
#' @param vardesc column specifying variable descriptions to include in the yspec file
#' @param varunit column specifying variable units to include in the yspec file
#' @param vartype column specifying variable types to include in the yspec file
#' @param output name of the output yspec file, ending in `.yaml` or `.yml`
#' @param varcodelist column containing coded values (comma- or newline-separated)
#' @param codelist_func function taking a codelist string and returning a named list of codes
#'
#' @importFrom yspec ys_load get_meta
#' @importFrom yaml write_yaml
#' @importFrom utils type.convert
#' @author Omar I. Elashkar
#' @export
df_to_yspec <- function(
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
) {
  stopifnot(is.data.frame(x))
  stopifnot(all(
    c(varname, vardesc, varunit, vartype, varcodelist) %in% colnames(x)
  ))
  stopifnot(grepl("\\.ya?ml$", output))
  if (!is.null(varcodelist)) {
    stopifnot(is.function(codelist_func))
  }
  duplicated_names <- unique(x[[varname]][duplicated(x[[varname]])])
  if (length(duplicated_names) > 0) {
    stop(
      "Duplicate variable names in `",
      varname,
      "`: ",
      paste(duplicated_names, collapse = ", "),
      call. = FALSE
    )
  }

  # Create the YAML structure
  yspec_list <- list(
    SETUP__ = list(
      description = desc,
      projectnumber = projectid
    )
  )

  # Add variables as top-level keys
  for (i in seq_len(nrow(x))) {
    variable <- list()

    # Define fields and their corresponding column names
    fields <- list(
      long = vardesc,
      unit = varunit,
      type = vartype
    )

    # Dynamically add fields if they are not NA or "N/A"
    for (field_name in names(fields)) {
      if (is.null(fields[[field_name]])) {
        next
      }
      field_value <- x[[fields[[field_name]]]][i]
      if (!is.na(field_value) && field_value != "N/A") {
        variable[[field_name]] <- field_value
      }
    }
    if (!is.null(varcodelist)) {
      codelist <- x[[varcodelist]][i]
      if (!is.na(codelist) && nzchar(trimws(codelist))) {
        variable$values <- codelist_func(codelist)
      }
    }

    # Add the variable to the YAML structure
    yspec_list[[x[[varname]][i]]] <- variable
  }

  # Write to YAML file
  yaml::write_yaml(yspec_list, output)
  message("YAML file created: ", output)
}

#' Default parser for codelist strings in the format "code=label"
#' @param text A character string containing codelist entries separated by commas or newlines.
#' @return A named list where names are labels and values are codes.
#' @examples
#' parse_yspec_codelist("10=Copper coil, 20=Glass panel, 30=Polymer casing, Unknown= -1")
#' parse_yspec_codelist("0 = Idle\n1=Calibration pending\n2=Signal outside range\n3=Battery replacement needed\n4=Ready for shipping")
#' @noRd
#' @author Omar I. Elashkar
parse_yspec_codelist <- function(text) {
  entries <- trimws(unlist(strsplit(text, "[,\r\n]+")))
  entries <- entries[nzchar(entries)]
  values <- lapply(entries, function(entry) {
    parts <- trimws(strsplit(entry, "=", fixed = TRUE)[[1]])
    if (length(parts) != 2L || any(!nzchar(parts))) {
      stop("Invalid codelist entry: ", entry)
    }
    code_first <- !is.na(suppressWarnings(as.numeric(parts[1])))
    code <- if (code_first) parts[1] else parts[2]
    label <- if (code_first) parts[2] else parts[1]
    list(label = label, code = type.convert(code, as.is = TRUE))
  })
  stats::setNames(
    lapply(values, `[[`, "code"),
    vapply(values, `[[`, "", "label")
  )
}


#' Sort specification variables to match a data frame
#'
#' @param data A data frame whose column order determines the variable order.
#' @param spec A loaded yspec object, as returned by [yspec::ys_load()].
#' @return A yspec object with matching variables in data frame column order.
#'   Specification variables absent from `data` follow in their original order.
#'   Data columns absent from `spec` are ignored. Metadata is preserved.
#' @export
ys_sort_spec_vars <- function(data, spec) {
  stopifnot(is.data.frame(data), inherits(spec, "yspec"))
  vars <- c(
    intersect(names(data), names(spec)),
    setdiff(names(spec), names(data))
  )
  sorted <- spec[vars]
  attributes(sorted) <- attributes(spec)
  names(sorted) <- vars
  sorted
}

#' Write a yspec object to a YAML file
#'
#' Writes a standalone specification using YAML input fields rather than loaded
#' object internals. Lookup and import results are materialized; their original
#' file references and loader provenance are not written. Control settings are
#' flattened into `SETUP__`. Variable order, namespaces and coded-value labels
#' are preserved, but comments and YAML formatting are not.
#'
#' @param x A yspec object, as returned by [yspec::ys_load()].
#' @param path Path to the output YAML file, ending in `.yaml` or `.yml`.
#' @importFrom yaml write_yaml
#' @importFrom yspec get_meta
#' @author Omar I. Elashkar
#' @export
ys_write <- function(x, path) {
  stopifnot(inherits(x, "yspec"))
  stopifnot(grepl("\\.ya?ml$", path))
  meta <- yspec::get_meta(x)
  setup_fields <- c(
    "description",
    "projectnumber",
    "sponsor",
    "data_path",
    "data_stem",
    "name",
    "comment",
    "comment_col",
    "glue",
    "primary_key",
    "flags",
    "max_nchar_label",
    "max_nchar_short",
    "max_nchar_col",
    "ys_document_namespace",
    "missing_code"
  )
  # Loaded control settings use a different layout than YAML input.
  for (field in names(meta$control)) {
    meta[[field]] <- meta$control[[field]]
  }
  meta <- meta[intersect(names(meta), setup_fields)]
  meta <- meta[lengths(meta) > 0L]
  column_fields <- c(
    "type",
    "unit",
    "values",
    "decode",
    "source",
    "comment",
    "short",
    "long",
    "about",
    "dots",
    "range",
    "longvalues",
    "lookup",
    "axis",
    "table",
    "label",
    "make_factor",
    "namespace"
  )
  columns <- lapply(as.list(x), function(column) {
    column <- column[sub("\\..*$", "", names(column)) %in% column_fields]
    # Lookup/import results are materialized, so the output is standalone.
    column$lookup <- FALSE
    column
  })
  yspec_list <- c(list(SETUP__ = meta), columns)
  as_yaml <- function(value) {
    # Named atomic vectors must be mappings, not sequences that lose labels.
    if (is.atomic(value) && !is.null(names(value))) {
      value <- as.list(value)
    }
    if (is.list(value)) {
      value <- lapply(value, as_yaml)
    }
    value
  }
  yaml::write_yaml(as_yaml(yspec_list), path)
}
