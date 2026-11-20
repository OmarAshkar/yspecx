#' Check a data set against its specification with extra checks
#'
#' Runs [yspec::ys_check()] and then three additional checks:
#'
#' 1. Missing values, using [ysx_check_missing()]. By default, columns may not
#'    contain missing values; set `na_ok: true` in a column's `dots` to allow
#'    them. With `error_on_fail = TRUE`, a specification column that is absent
#'    from `data` raises an error immediately; with `FALSE` it is ignored.
#' 1. Repeats within groups, using [ysx_check_repeats()]. By default, each
#'    combination of `group: true` columns must occur once. Set
#'    `pre_grp_count: <n>` in the `dots` of the group columns to require `n`
#'    rows, or `pre_grp_count: ~` (YAML null) to skip this check. All group
#'    columns that set it must agree. `error_on_fail` is forwarded.
#' 1. Time-varying columns. The data are grouped by all columns with
#'    `group: true` (default `false`). A column with `time_varying: false`
#'    (default) must be constant within each group; a column with
#'    `time_varying: true` must vary within at least one group.
#'
#' @inheritParams yspec::ys_check
#' @return Invisibly, `TRUE` if all checks pass; otherwise an error is raised,
#'   or `FALSE` is returned when `error_on_fail = FALSE`.
#' @export
ysx_check <- function(
  data,
  spec,
  verbose = FALSE,
  output = tempfile(),
  error_on_fail = TRUE
) {
  base_ok <- yspec::ys_check(
    data,
    spec,
    verbose = verbose,
    output = output,
    error_on_fail = FALSE
  )

  repeat_msgs <- character(0)
  count <- repeat_count(spec)
  if (!is.null(count)) {
    repeat_msgs <- check_repeats(
      data,
      spec,
      count = count,
      error_on_fail = error_on_fail
    )
  }

  msgs <- c(
    ysx_check_missing(data, spec, error_on_fail = error_on_fail),
    repeat_msgs,
    check_time_varying(data, spec)
  )

  if (length(msgs) > 0) {
    msgs <- c("Additional check messages:", paste0("  - ", msgs))
    cat(
      "\n",
      paste(msgs, collapse = "\n"),
      "\n",
      file = output,
      sep = "",
      append = TRUE
    )
    message(paste(msgs, collapse = "\n"))
  }

  ok <- isTRUE(base_ok) && length(msgs) == 0
  if (!ok && error_on_fail) {
    stop("Please review messages and re-check.", call. = FALSE)
  }
  invisible(ok)
}

spec_dot <- function(x, name, default) {
  val <- x[["dots"]][[name]]
  if (is.null(val) || length(val) != 1 || is.na(val)) default else val
}

#' Check missing values against a specification
#'
#' Missing values are not allowed by default. A column may contain them only
#' when its `dots` set `na_ok: true`. Missing values must be encoded as the
#' spec's `missing_code` (`SETUP__: missing_code`, default `NA`). If
#' `missing_code` is not `NA`, any `NA` in the data is an error, even when
#' `na_ok` is `true`.
#'
#' Every column in `data` must be described in `spec`; unmatched columns are
#' reported because their missing-value rules cannot be checked. Specification
#' columns absent from `data` raise an error unless `error_on_fail` is `FALSE`,
#' in which case they are ignored.
#'
#' If `spec2` is supplied, it is merged into `spec` with [yspec::ys_join()]
#' before checking. Columns in both specifications use the definition from
#' `spec`, and metadata such as `missing_code` also comes from `spec`.
#'
#' @param data A data frame.
#' @param spec A loaded yspec object.
#' @param spec2 An optional second yspec object whose additional columns are
#'   merged into `spec` before checking.
#' @param error_on_fail If `TRUE` (default), an error is raised when a column
#'   in the (merged) specification does not exist in `data`. If `FALSE`, such
#'   columns are ignored.
#' @return A character vector of problems; `character(0)` if none are found.
#'   An error is raised if a `na_ok` setting is not `true` or `false`.
#' @export
ysx_check_missing <- function(data, spec, spec2 = NULL, error_on_fail = TRUE) {
  stopifnot(
    is.data.frame(data),
    inherits(spec, "yspec"),
    is.null(spec2) || inherits(spec2, "yspec"),
    is.logical(error_on_fail),
    length(error_on_fail) == 1L,
    !is.na(error_on_fail)
  )
  if (!is.null(spec2)) {
    spec <- yspec::ys_join(spec, spec2)
  }
  absent <- setdiff(names(spec), names(data))
  if (error_on_fail && length(absent) > 0) {
    stop(
      "Specification column(s) not found in data: ",
      paste(absent, collapse = ", "),
      call. = FALSE
    )
  }
  code <- yspec::get_meta(spec)[["missing_code"]]
  if (is.null(code)) {
    code <- NA
  }
  code_is_na <- is.na(code)
  out <- character(0)

  unmatched <- setdiff(names(data), names(spec))
  if (length(unmatched) > 0) {
    out <- sprintf(
      "%s: column is not in the specification; missing values not checked",
      unmatched
    )
  }

  for (col in intersect(names(data), names(spec))) {
    na_ok <- spec[[col]][["dots"]][["na_ok"]]
    if (is.null(na_ok)) {
      na_ok <- FALSE
    }
    if (!is.logical(na_ok) || length(na_ok) != 1L || is.na(na_ok)) {
      stop(col, ": dots$na_ok must be true or false.", call. = FALSE)
    }
    y <- data[[col]]
    n_na <- sum(is.na(y))
    n_code <- if (code_is_na) 0L else sum(y == code, na.rm = TRUE)

    if (!code_is_na && n_na > 0) {
      out <- c(
        out,
        sprintf(
          "%s: %d missing value(s) coded NA; expected missing_code %s",
          col,
          n_na,
          format(code)
        )
      )
    }
    if (!na_ok && (n_na + n_code) > 0) {
      out <- c(
        out,
        sprintf(
          "%s: %d missing value(s) found but na_ok is not true (default)",
          col,
          n_na + n_code
        )
      )
    }
  }
  out
}

check_time_varying <- function(data, spec) {
  is_group <- vapply(
    spec,
    function(x) isTRUE(spec_dot(x, "group", FALSE)),
    logical(1)
  )
  groups <- names(spec)[is_group]
  groups <- intersect(groups, names(data))
  if (length(groups) == 0) {
    return(character(0))
  }

  data <- as.data.frame(data)
  gid <- do.call(paste, c(unname(as.list(data[groups])), sep = "\r"))
  out <- character(0)

  for (x in spec) {
    col <- x[["col"]]
    if (!col %in% names(data) || col %in% groups) {
      next
    }
    # Distinct values per group, counting missing as a value
    n_distinct <- tapply(data[[col]], gid, function(v) length(unique(v)))
    varies <- any(n_distinct > 1)
    declared <- isTRUE(spec_dot(x, "time_varying", FALSE))

    if (!declared && varies) {
      out <- c(
        out,
        sprintf(
          "%s: declared subject-level (time_varying: false) but varies within %s",
          col,
          paste(groups, collapse = ", ")
        )
      )
    }
    if (declared && !varies) {
      out <- c(
        out,
        sprintf(
          "%s: declared time_varying but constant within every %s",
          col,
          paste(groups, collapse = ", ")
        )
      )
    }
  }
  out
}
