spec_file <- system.file(
  "ext",
  "examples",
  "ADER_yspec.yml",
  package = "yspecx"
)
if (!nzchar(spec_file)) {
  spec_file <- testthat::test_path(
    "..",
    "..",
    "inst",
    "ext",
    "examples",
    "ADER_yspec.yml"
  )
}

load_test_spec <- function(file = spec_file) {
  suppressWarnings(yspec::load_spec(file))
}

# Build a data set that satisfies the spec: 2 subjects x 3 records, with
# every non-group column constant within subject.
make_data <- function(spec, n_subj = 2, n_rec = 3) {
  groups <- names(spec)[vapply(
    spec,
    function(x) isTRUE(x$dots$group),
    logical(1)
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
  expect_true(suppressMessages(ysx_check(data, spec)))
})

test_that("base ys_check failures are still reported", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$EXTRA <- 1
  expect_false(suppressMessages(ysx_check(data, spec, error_on_fail = FALSE)))
  expect_error(suppressMessages(ysx_check(data, spec)), "review messages")
})

test_that("NA is an error when missing_code is not NA", {
  spec <- load_test_spec()
  expect_equal(yspec::get_meta(spec)$missing_code, -999)
  data <- make_data(spec)
  data$CVA1[1:3] <- NA
  expect_message(
    res <- ysx_check(data, spec, error_on_fail = FALSE),
    "CVA1.*coded NA"
  )
  expect_false(res)
  expect_error(suppressMessages(ysx_check(data, spec)), "review messages")
})

test_that("missing_code values are accepted", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$CVA1[1:3] <- -999
  expect_true(suppressMessages(ysx_check(data, spec)))
})

test_that("missing values are rejected by default (na_ok is false)", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$SEX[1:3] <- "-999"
  expect_message(
    res <- ysx_check(data, spec, error_on_fail = FALSE),
    "SEX: 3 missing value\\(s\\) found but na_ok is not true"
  )
  expect_false(res)
})

test_that("ysx_check_missing checks every data column against the spec", {
  spec <- load_test_spec()
  data <- make_data(spec)
  expect_identical(ysx_check_missing(data, spec), character(0))

  data$CVA1[1:3] <- NA
  expect_match(ysx_check_missing(data, spec), "CVA1: 3 .* coded NA")

  data$CVA1 <- -999
  data$SEX[1] <- "-999"
  expect_match(ysx_check_missing(data, spec), "SEX: 1 missing")
  expect_length(ysx_check_missing(data, spec), 1L)

  extra <- cbind(make_data(spec), EXTRA = 1)
  expect_identical(
    ysx_check_missing(extra, spec),
    "EXTRA: column is not in the specification; missing values not checked"
  )
})

test_that("spec columns absent from the data raise unless error_on_fail = FALSE", {
  spec <- load_test_spec()
  data <- make_data(spec)[c("SEX", "CVA1")]
  expect_snapshot(
    error = TRUE,
    ysx_check_missing(data, yspec::ys_select(spec, SEX, CVA1, AGE, ID))
  )

  expect_identical(
    ysx_check_missing(data, spec, error_on_fail = FALSE),
    character(0)
  )
  data$SEX[2] <- NA
  expect_length(ysx_check_missing(data, spec, error_on_fail = FALSE), 2L)
  expect_error(ysx_check_missing(data, spec), "not found in data")
})

test_that("ysx_check forwards error_on_fail to the missing-column check", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$AGE <- NULL
  expect_error(
    suppressMessages(ysx_check(data, spec)),
    "Specification column\\(s\\) not found in data: AGE"
  )
  res <- suppressMessages(ysx_check(data, spec, error_on_fail = FALSE))
  expect_false(res)
})

test_that("absent columns from a merged second spec also raise", {
  spec <- load_test_spec()
  data <- make_data(spec)[c("SEX", "CVA1")]
  left <- yspec::ys_select(spec, SEX)
  right <- yspec::ys_select(spec, CVA1, AGE)
  expect_error(ysx_check_missing(data, left, right), "AGE")
  expect_identical(
    ysx_check_missing(data, left, right, error_on_fail = FALSE),
    character(0)
  )
})

test_that("ysx_check_missing merges a second spec before checking", {
  spec <- load_test_spec()
  data <- make_data(spec)[c("SEX", "CVA1")]
  left <- yspec::ys_select(spec, SEX)
  right <- yspec::ys_select(spec, CVA1)
  original <- left

  expect_length(ysx_check_missing(data, left), 1L)
  expect_identical(ysx_check_missing(data, left, right), character(0))
  expect_identical(left, original)

  data$CVA1[1] <- NA
  expect_match(ysx_check_missing(data, left, right), "CVA1: 1 .* coded NA")

  # First spec wins for columns defined in both
  right$SEX$dots$na_ok <- TRUE
  data$SEX[1] <- "-999"
  expect_match(
    ysx_check_missing(data, left, right),
    "SEX: 1 missing",
    all = FALSE
  )
  left$SEX$dots$na_ok <- TRUE
  expect_false(any(grepl("SEX", ysx_check_missing(data, left, right))))
})

test_that("ysx_check_missing validates inputs and na_ok settings", {
  spec <- load_test_spec()
  data <- make_data(spec)
  expect_snapshot(error = TRUE, ysx_check_missing(list(), spec))
  expect_snapshot(error = TRUE, ysx_check_missing(data, list()))
  spec$SEX$dots$na_ok <- "yes"
  expect_snapshot(error = TRUE, ysx_check_missing(data, spec))
  expect_snapshot(error = TRUE, ysx_check_missing(data, spec, list()))
  expect_snapshot(
    error = TRUE,
    ysx_check_missing(data, spec, error_on_fail = NA)
  )
})


test_that("missing_code defaults to NA", {
  x <- readLines(spec_file, warn = FALSE)
  f <- tempfile(fileext = ".yml")
  writeLines(x[!grepl("missing_code", x)], f)
  spec <- load_test_spec(f)
  data <- make_data(spec)

  data$CVA1[1:3] <- NA
  expect_true(suppressMessages(ysx_check(data, spec)))

  data$SEX[1:3] <- NA
  expect_false(suppressMessages(ysx_check(data, spec, error_on_fail = FALSE)))
})

test_that("subject-level column that varies within group is an error", {
  spec <- load_test_spec()
  data <- make_data(spec)
  data$AGE[2] <- data$AGE[2] + 1
  expect_message(
    res <- ysx_check(data, spec, error_on_fail = FALSE),
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
    ysx_check(data, spec, error_on_fail = FALSE),
    "CVB1: declared subject-level"
  )
})

test_that("time_varying column constant within every group is an error", {
  spec <- modified_spec("AGE", "{time_varying: true}")
  data <- make_data(spec)
  expect_message(
    res <- ysx_check(data, spec, error_on_fail = FALSE),
    "AGE: declared time_varying"
  )
  expect_false(res)

  data$AGE[2] <- data$AGE[2] + 1
  expect_true(suppressMessages(ysx_check(data, spec)))
})

test_that("group check is skipped when no group columns exist", {
  x <- readLines(spec_file, warn = FALSE)
  f <- tempfile(fileext = ".yml")
  writeLines(sub("group: true", "group: false", x, fixed = TRUE), f)
  spec <- load_test_spec(f)
  data <- make_data(spec)
  data$AGE[2] <- data$AGE[2] + 1
  expect_true(suppressMessages(ysx_check(data, spec)))
})

test_that("ysx_check requires unique groups by default", {
  spec <- ysx_regroup(load_test_spec(), "USUBJID")
  spec$USUBJID$dots[["pre_grp_count"]] <- NULL
  data <- make_data(spec)
  expect_message(
    res <- ysx_check(data, spec, error_on_fail = FALSE),
    "2 of 2 group\\(s\\) defined by USUBJID do not have 1 row"
  )
  expect_false(res)

  unique_data <- data[!duplicated(data$USUBJID), ]
  expect_true(suppressMessages(ysx_check(unique_data, spec)))
})

test_that("pre_grp_count sets the required rows and null skips the check", {
  spec <- ysx_regroup(load_test_spec(), "USUBJID")
  data <- make_data(spec)

  spec$USUBJID$dots$pre_grp_count <- 3
  expect_true(suppressMessages(ysx_check(data, spec)))
  spec$USUBJID$dots$pre_grp_count <- 2
  expect_message(
    ysx_check(data, spec, error_on_fail = FALSE),
    "do not have 2 row"
  )

  spec$USUBJID$dots["pre_grp_count"] <- list(NULL)
  expect_true(suppressMessages(ysx_check(data, spec)))
})

test_that("pre_grp_count accepts yaml null and None and is validated", {
  spec <- load_test_spec()
  expect_null(repeat_count(spec))
  data <- make_data(spec)
  expect_true(suppressMessages(ysx_check(data, spec)))

  spec <- ysx_regroup(spec, "USUBJID")
  spec$USUBJID$dots[["pre_grp_count"]] <- NULL
  expect_identical(repeat_count(spec), 1L)

  spec$USUBJID$dots$pre_grp_count <- "None"
  expect_null(repeat_count(spec))
  expect_true(suppressMessages(ysx_check(data, spec)))

  spec$USUBJID$dots$pre_grp_count <- 0
  expect_snapshot(error = TRUE, ysx_check(data, spec))
  spec$USUBJID$dots$pre_grp_count <- "many"
  expect_snapshot(error = TRUE, ysx_check(data, spec))
  spec <- ysx_regroup(spec, c("USUBJID", "ID"))
  spec$USUBJID$dots$pre_grp_count <- 2
  spec$ID$dots$pre_grp_count <- 3
  expect_snapshot(error = TRUE, ysx_check(data, spec))
})

test_that("ysx_check forwards error_on_fail to ysx_check_repeats", {
  spec <- ysx_regroup(load_test_spec(), "USUBJID")
  spec$USUBJID$dots[["pre_grp_count"]] <- NULL
  data <- make_data(spec)
  data$USUBJID <- NULL
  expect_error(
    suppressMessages(ysx_check(data, spec)),
    "column\\(s\\) not found in data: .*USUBJID"
  )
  expect_error(
    suppressMessages(ysx_check(data, spec, error_on_fail = FALSE)),
    NA
  )
})
