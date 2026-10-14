spec_file <- system.file("ext", "examples", "ADER_yspec.yml", package = "yspecx")
if (!nzchar(spec_file)) {
  spec_file <- testthat::test_path("..", "..", "inst", "ext", "examples", "ADER_yspec.yml")
}

load_test_spec <- function(file = spec_file) {
  suppressWarnings(yspec::load_spec(file))
}

# Build a data set that satisfies the spec: 2 subjects x 3 records, with
# every non-group column constant within subject.
make_data <- function(spec, n_subj = 2, n_rec = 3) {
  groups <- names(spec)[vapply(
    spec, function(x) isTRUE(x$dots$group), logical(1)
  )]
  n <- n_subj * n_rec
  subj <- rep(seq_len(n_subj), each = n_rec)
  out <- lapply(spec, function(x) {
    if (x$col %in% groups) {
      if (x$type == "numeric") subj else paste0("S", subj)
    } else if (x$type == "numeric") {
      subj * 10
    } else {
      paste0("V", subj)
    }
  })
  as.data.frame(out, stringsAsFactors = FALSE)
}

# Copy of the spec file with one column's `dots:` line replaced
modified_spec <- function(col, dots) {
  x <- readLines(spec_file, warn = FALSE)
  i <- which(x == paste0(col, ":"))
  j <- i + which(grepl("^  dots:", x[(i + 1):length(x)]))[1]
  if (is.na(j) || j > length(x) || grepl("^[A-Z]", x[j])) {
    x <- append(x, paste0("  dots: ", dots), after = i + 2)
  } else {
    x[j] <- paste0("  dots: ", dots)
  }
  f <- tempfile(fileext = ".yml")
  writeLines(x, f)
  load_test_spec(f)
}

test_that("clean data passes all checks", {
  spec <- load_test_spec()
  data <- make_data(spec)
  expect_true(suppressMessages(ys_checkx(data, spec)))
})

test_that("base ys_check failures are still reported", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$EXTRA <- 1
  expect_false(suppressMessages(ys_checkx(data, spec, error_on_fail = FALSE)))
  expect_error(suppressMessages(ys_checkx(data, spec)), "review messages")
})

test_that("NA is an error when missing_code is not NA", {
  spec <- load_test_spec()
  expect_equal(yspec::get_meta(spec)$missing_code, -999)
  data <- make_data(spec)
  data$CVA1[1:3] <- NA
  expect_message(
    res <- ys_checkx(data, spec, error_on_fail = FALSE),
    "CVA1.*coded NA"
  )
  expect_false(res)
  expect_error(suppressMessages(ys_checkx(data, spec)), "review messages")
})

test_that("missing_code values are accepted", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$CVA1[1:3] <- -999
  expect_true(suppressMessages(ys_checkx(data, spec)))
})

test_that("anymissing = false rejects NA and missing_code", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$SEX[1:3] <- "-999"
  expect_message(
    res <- ys_checkx(data, spec, error_on_fail = FALSE),
    "SEX: anymissing is false"
  )
  expect_false(res)
})

test_that("missing_code defaults to NA", {
  x <- readLines(spec_file, warn = FALSE)
  f <- tempfile(fileext = ".yml")
  writeLines(x[!grepl("missing_code", x)], f)
  spec <- load_test_spec(f)
  data <- make_data(spec)

  data$CVA1[1:3] <- NA
  expect_true(suppressMessages(ys_checkx(data, spec)))

  data$SEX[1:3] <- NA
  expect_false(suppressMessages(ys_checkx(data, spec, error_on_fail = FALSE)))
})

test_that("subject-level column that varies within group is an error", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$AGE[2] <- data$AGE[2] + 1
  expect_message(
    res <- ys_checkx(data, spec, error_on_fail = FALSE),
    "AGE: declared subject-level"
  )
  expect_false(res)
})

test_that("time_varying defaults to false", {
  spec <- load_test_spec()
  data <- make_data(spec)
  # CVB1 has no dots in the spec
  data$CVB1[2] <- data$CVB1[2] + 1
  expect_message(
    ys_checkx(data, spec, error_on_fail = FALSE),
    "CVB1: declared subject-level"
  )
})

test_that("time_varying column constant within every group is an error", {
  spec <- modified_spec("AGE", "{time_varying: true}")
  data <- make_data(spec)
  expect_message(
    res <- ys_checkx(data, spec, error_on_fail = FALSE),
    "AGE: declared time_varying"
  )
  expect_false(res)

  data$AGE[2] <- data$AGE[2] + 1
  expect_true(suppressMessages(ys_checkx(data, spec)))
})

test_that("group check is skipped when no group columns exist", {
  x <- readLines(spec_file, warn = FALSE)
  f <- tempfile(fileext = ".yml")
  writeLines(sub("group: true", "group: false", x, fixed = TRUE), f)
  spec <- load_test_spec(f)
  data <- make_data(spec)
  data$AGE[2] <- data$AGE[2] + 1
  expect_true(suppressMessages(ys_checkx(data, spec)))
})
