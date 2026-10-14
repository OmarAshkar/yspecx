.onLoad <- function(libname, pkgname) {
  extend_yspec_setup_names("missing_code")
}

# yspec validates SETUP__ keys against an internal, locked constant.
# Append our extra keys so yspec does not warn about them.
extend_yspec_setup_names <- function(keys) {
  ns <- asNamespace("yspec")
  nm <- "VALID_SETUP_NAMES"
  current <- get(nm, envir = ns)
  new <- setdiff(keys, current)
  if (length(new) == 0) return(invisible(FALSE))
  locked <- bindingIsLocked(nm, ns)
  if (locked) unlockBinding(nm, ns)
  assign(nm, c(current, new), envir = ns)
  if (locked) lockBinding(nm, ns)
  invisible(TRUE)
}
