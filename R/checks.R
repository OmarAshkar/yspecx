#' Check a data set against its specification with extra checks
#'
#' Runs [yspec::ys_check()] and then three additional checks:
#'
#' 1. Missing values, using [ysx_check_missing()]. By default, columns may not
#'    contain missing values; set `na_ok: true` in a column's `dots` to allow
#'    them.
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
#' Before any check, `data` and `spec` must match: every column in `data` must
#' be a variable in `spec`, and every variable in `spec` must be a column in
#' `data`. With `error_on_fail = TRUE` a mismatch raises an error; with `FALSE`
#' it is reported with the other problems. [ysx_check_missing()] on its own
#' only requires the data columns to be in the spec.
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
  unmatched <- setdiff(names(data), names(spec))
  absent <- setdiff(names(spec), names(data))
  match_msgs <- c(
    if (length(unmatched) > 0) {
      paste0(
        "Data column(s) not found in specification: ",
        paste(unmatched, collapse = ", ")
      )
    },
    if (length(absent) > 0) {
      paste0(
        "Specification column(s) not found in data: ",
        paste(absent, collapse = ", ")
      )
    }
  )
  if (error_on_fail && length(match_msgs) > 0) {
    stop(paste(match_msgs, collapse = "; "), call. = FALSE)
  }

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
    match_msgs,
    # Only matched columns: mismatches are already in match_msgs
    ysx_check_missing(
      data[intersect(names(data), names(spec))],
      spec,
      error_on_fail = FALSE
    ),
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

# Names of the columns with `dots: {group: true}`
group_cols <- function(spec) {
  names(spec)[vapply(
    spec,
    function(x) isTRUE(spec_dot(x, "group", FALSE)),
    logical(1)
  )]
}

#' Check missing values against a specification
#'
#' Missing values are not allowed by default. A column may contain them only
#' when its `dots` set `na_ok: true`. Missing values must be encoded as the
#' spec's `missing_code` (`SETUP__: missing_code`, default `NA`). If
#' `missing_code` is not `NA`, any `NA` in the data is an error, even when
#' `na_ok` is `true`.
#'
#' Every column in `data` must be described in `spec`. With `error_on_fail =
#' TRUE` an error lists the unmatched columns, because their missing-value
#' rules cannot be checked; with `FALSE` they are returned as problems.
#' Specification columns that are not in `data` are ignored.
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
#'   of `data` is not in the (merged) specification. If `FALSE`, such columns
#'   are returned as problems instead.
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
  unmatched <- setdiff(names(data), names(spec))
  if (error_on_fail && length(unmatched) > 0) {
    stop(
      "Data column(s) not found in specification: ",
      paste(unmatched, collapse = ", "),
      call. = FALSE
    )
  }
  code <- yspec::get_meta(spec)[["missing_code"]]
  if (is.null(code)) {
    code <- NA
  }
  code_is_na <- is.na(code)
  out <- character(0)

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
  groups <- intersect(group_cols(spec), names(data))
  if (length(groups) == 0) {
    return(character(0))
  }

  data <- as.data.frame(data)
  gid <- do.call(paste, c(unname(as.list(data[groups])), sep = "\r"))
  gi <- match(gid, unique(gid))
  first <- which(!duplicated(gi))
  out <- character(0)

  for (x in spec) {
    col <- x[["col"]]
    if (!col %in% names(data) || col %in% groups) {
      next
    }
    varies <- varies_within_group(data[[col]], gi, first)
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

# TRUE if any group holds more than one distinct value of `x`; missing counts
# as a value. `gi` is the group index of each row, `first` the first row of each
# group. Comparing every row with its group's first row avoids a per-group call.
varies_within_group <- function(x, gi, first) {
  if (is.list(x)) {
    return(any(tapply(x, gi, function(v) length(unique(v))) > 1))
  }
  f <- x[first][gi]
  na_x <- is.na(x)
  na_f <- is.na(f)
  any(
    na_x != na_f |
      (na_x & na_f & is.nan(x) != is.nan(f)) |
      (!na_x & !na_f & x != f)
  )
}
