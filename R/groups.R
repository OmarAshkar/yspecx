#' Replace the group columns of a specification
#'
#' Removes every existing `group` setting from the `dots` of `spec`, then marks
#' the columns in `groups` with `group: true`. Other `dots` settings are kept.
#' The group columns are used by [ysx_check_repeats()] and [ysx_check()].
#'
#' @param spec A loaded yspec object.
#' @param groups A character vector naming one or more columns in `spec`.
#' @return A yspec object with the new group columns. `spec` is not modified.
#' @export
ysx_regroup <- function(spec, groups) {
  stopifnot(
    inherits(spec, "yspec"),
    is.character(groups),
    length(groups) > 0L,
    !anyNA(groups)
  )
  absent <- setdiff(groups, names(spec))
  if (length(absent) > 0) {
    stop(
      "Group column(s) not found in spec: ",
      paste(absent, collapse = ", "),
      call. = FALSE
    )
  }
  for (col in names(spec)) {
    if ("group" %in% names(spec[[col]][["dots"]])) {
      spec[[col]][["dots"]][["group"]] <- NULL
    }
  }
  for (col in unique(groups)) {
    spec[[col]][["dots"]][["group"]] <- TRUE
  }
  spec
}

#' Check the number of rows in each group
#'
#' Groups the data by every column with `group: true` in `spec` (see
#' [ysx_regroup()]) and reports groups that do not have exactly `count` rows.
#' This is equivalent to counting rows by the group columns and checking that
#' none has `n != count`. Missing values count as a group value.
#'
#' If `groups` is supplied, it replaces the group columns of `spec` first, as
#' with [ysx_regroup()], so the whole check can be written as one call. If
#' there are no group columns, nothing can be checked and `character(0)` is
#' returned.
#'
#' @param data A data frame.
#' @param spec A loaded yspec object.
#' @param count The required number of rows in every group; a single positive
#'   whole number. The default, `1`, means that group values must be unique.
#' @param error_on_fail If `TRUE` (default), an error is raised when a group
#'   column in `spec` does not exist in `data`, or when any group does not have
#'   `count` rows. If `FALSE`, nothing is raised; problems are returned and
#'   only the group columns found in `data` are used.
#' @param groups Optional character vector of columns that define the groups,
#'   used instead of the `group: true` columns in `spec`. See [ysx_regroup()].
#' @return Invisibly, `character(0)` if no problems are found. With
#'   `error_on_fail = FALSE`, a character vector describing any problems.
#' @examples
#' \dontrun{
#' ysx_check_repeats(aetab, spec, groups = c("USUBJIDN", "AFRLT", "DCXLFLN"))
#' }
#' @export
ysx_check_repeats <- function(
  data,
  spec,
  count = 1,
  error_on_fail = TRUE,
  groups = NULL
) {
  if (!is.null(groups)) {
    spec <- ysx_regroup(spec, groups)
  }
  problems <- check_repeats(data, spec, count, error_on_fail)
  if (error_on_fail && length(problems) > 0L) {
    stop(problems, call. = FALSE)
  }
  invisible(problems)
}

# Returns problem messages; only absent group columns raise (if error_on_fail).
check_repeats <- function(data, spec, count = 1, error_on_fail = TRUE) {
  stopifnot(
    is.data.frame(data),
    inherits(spec, "yspec"),
    is.numeric(count),
    length(count) == 1L,
    !is.na(count),
    count >= 1,
    count == round(count),
    is.logical(error_on_fail),
    length(error_on_fail) == 1L,
    !is.na(error_on_fail)
  )
  is_group <- vapply(
    spec,
    function(x) isTRUE(spec_dot(x, "group", FALSE)),
    logical(1)
  )
  groups <- names(spec)[is_group]
  absent <- setdiff(groups, names(data))
  if (error_on_fail && length(absent) > 0) {
    stop(
      "Group column(s) not found in data: ",
      paste(absent, collapse = ", "),
      call. = FALSE
    )
  }
  groups <- intersect(groups, names(data))
  if (length(groups) == 0L || nrow(data) == 0L) {
    return(character(0))
  }

  data <- as.data.frame(data)
  gid <- do.call(paste, c(unname(as.list(data[groups])), sep = "\r"))
  n <- tabulate(match(gid, unique(gid)))
  bad <- n != count
  if (!any(bad)) {
    return(character(0))
  }
  sprintf(
    "%d of %d group(s) defined by %s do not have %d row(s) (row counts found: %s)",
    sum(bad),
    length(n),
    paste(groups, collapse = ", "),
    as.integer(count),
    paste(sort(unique(n[bad])), collapse = ", ")
  )
}

# Required rows per group from `dots: {pre_grp_count: <n>}` on group columns.
# Not set anywhere: 1. YAML null (`~`, `null`) or the string "None": NULL,
# meaning do not check repeats.
repeat_count <- function(spec) {
  is_group <- vapply(
    spec,
    function(x) isTRUE(spec_dot(x, "group", FALSE)),
    logical(1)
  )
  is_skip <- function(v) {
    is.null(v) ||
      (is.character(v) &&
        length(v) == 1L &&
        tolower(trimws(v)) %in% c("none", "null"))
  }
  values <- list()
  for (col in names(spec)[is_group]) {
    dots <- spec[[col]][["dots"]]
    if ("pre_grp_count" %in% names(dots)) {
      # list() wrapper keeps NULL; `[[<-` with NULL would drop the element
      values[col] <- list(dots[["pre_grp_count"]])
    }
  }
  if (length(values) == 0L) {
    return(1L)
  }
  valid <- vapply(
    values,
    function(v) {
      is_skip(v) ||
        (is.numeric(v) &&
          length(v) == 1L &&
          !is.na(v) &&
          v >= 1 &&
          v == round(v))
    },
    logical(1)
  )
  if (!all(valid)) {
    stop(
      paste(names(values)[!valid], collapse = ", "),
      ": dots$pre_grp_count must be a positive whole number, null or None.",
      call. = FALSE
    )
  }
  resolved <- lapply(values, function(v) {
    if (is_skip(v)) NULL else as.integer(v)
  })
  if (length(unique(resolved)) > 1L) {
    stop(
      "Group columns have conflicting dots$pre_grp_count settings: ",
      paste(names(values), collapse = ", "),
      call. = FALSE
    )
  }
  resolved[[1L]]
}
