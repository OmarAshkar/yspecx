#' Check a data set against its specification with extra checks
#'
#' Runs [yspec::ys_check()] and then two additional checks:
#'
#' 1. Missing values. Missing values must be encoded as the spec's
#'    `missing_code` (`SETUP__: missing_code`, default `NA`). If `missing_code`
#'    is not `NA`, any `NA` in the data is an error. Columns with
#'    `anymissing: false` (in `dots`) must have no missing values at all.
#' 1. Time-varying columns. The data are grouped by all columns with
#'    `group: true` (default `false`). A column with `time_varying: false`
#'    (default) must be constant within each group; a column with
#'    `time_varying: true` must vary within at least one group.
#'
#' @inheritParams yspec::ys_check
#' @return Invisibly, `TRUE` if all checks pass; otherwise an error is raised,
#'   or `FALSE` is returned when `error_on_fail = FALSE`.
#' @export
ys_checkx <- function(data, spec, verbose = FALSE, output = tempfile(),
                      error_on_fail = TRUE) {
  base_ok <- yspec::ys_check(
    data, spec,
    verbose = verbose, output = output, error_on_fail = FALSE
  )

  msgs <- c(check_missing(data, spec), check_time_varying(data, spec))

  if (length(msgs) > 0) {
    msgs <- c("Additional check messages:", paste0("  - ", msgs))
    cat("\n", paste(msgs, collapse = "\n"), "\n", file = output, sep = "",
        append = TRUE)
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

check_missing <- function(data, spec) {
  code <- yspec::get_meta(spec)[["missing_code"]]
  if (is.null(code)) code <- NA
  code_is_na <- is.na(code)
  out <- character(0)

  for (x in spec) {
    col <- x[["col"]]
    if (!col %in% names(data)) next
    y <- data[[col]]
    n_na <- sum(is.na(y))
    n_code <- if (code_is_na) 0L else sum(y == code, na.rm = TRUE)

    if (!code_is_na && n_na > 0) {
      out <- c(out, sprintf(
        "%s: %d missing value(s) coded NA; expected missing_code %s",
        col, n_na, format(code)
      ))
    }
    if (!spec_dot(x, "anymissing", TRUE) && (n_na + n_code) > 0) {
      out <- c(out, sprintf(
        "%s: anymissing is false but %d missing value(s) found",
        col, n_na + n_code
      ))
    }
  }
  out
}

check_time_varying <- function(data, spec) {
  is_group <- vapply(
    spec, function(x) isTRUE(spec_dot(x, "group", FALSE)), logical(1)
  )
  groups <- names(spec)[is_group]
  groups <- intersect(groups, names(data))
  if (length(groups) == 0) return(character(0))

  data <- as.data.frame(data)
  gid <- do.call(paste, c(unname(as.list(data[groups])), sep = "\r"))
  out <- character(0)

  for (x in spec) {
    col <- x[["col"]]
    if (!col %in% names(data) || col %in% groups) next
    # Distinct values per group, counting missing as a value
    n_distinct <- tapply(data[[col]], gid, function(v) length(unique(v)))
    varies <- any(n_distinct > 1)
    declared <- isTRUE(spec_dot(x, "time_varying", FALSE))

    if (!declared && varies) {
      out <- c(out, sprintf(
        "%s: declared subject-level (time_varying: false) but varies within %s",
        col, paste(groups, collapse = ", ")
      ))
    }
    if (declared && !varies) {
      out <- c(out, sprintf(
        "%s: declared time_varying but constant within every %s",
        col, paste(groups, collapse = ", ")
      ))
    }
  }
  out
}
