.onLoad <- function(libname, pkgname) {
  # A yspec change must not stop yspecx from loading; yspec only warns without it.
  tryCatch(
    extend_yspec_setup_names("missing_code"),
    error = function(e) {
      warning(
        "yspecx could not register 'missing_code' with yspec (",
        conditionMessage(e),
        "). yspec may warn about it in SETUP__.",
        call. = FALSE
      )
    }
  )
}

# yspec validates SETUP__ keys against an internal, locked constant.
# Append our extra keys so yspec does not warn about them.
extend_yspec_setup_names <- function(keys) {
  ns <- asNamespace("yspec")
  nm <- "VALID_SETUP_NAMES"
  current <- get(nm, envir = ns)
  new <- setdiff(keys, current)
  if (length(new) == 0) {
    return(invisible(FALSE))
  }
  locked <- bindingIsLocked(nm, ns)
  if (locked) {
    unlockBinding(nm, ns)
  }
  assign(nm, c(current, new), envir = ns)
  if (locked) {
    lockBinding(nm, ns)
  }
  invisible(TRUE)
}
