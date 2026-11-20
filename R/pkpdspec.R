#' Load the bundled PK/PD (NONMEM) specification
#'
#' Loads the specification shipped with yspecx, which describes standard
#' NONMEM data set columns such as `ID`, `TIME`, `DV`, `CMT`, `EVID` and `AMT`.
#' It can be combined with a study-specific specification, for example through
#' the `spec2` argument of [ysx_check_missing()].
#'
#' @param ... Further arguments passed to [yspec::ys_load()].
#' @return A yspec object.
#' @export
ysx_load_pkpdspec <- function(...) {
  file <- system.file("pkpdspec.yaml", package = "yspecx")
  if (!nzchar(file)) {
    stop(
      "pkpdspec.yaml was not found in the yspecx installation.",
      call. = FALSE
    )
  }
  yspec::ys_load(file, ...)
}
