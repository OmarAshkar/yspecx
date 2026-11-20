ader_file <- system.file(
  "ext",
  "examples",
  "ADER_yspec.yml",
  package = "yspecx"
)
if (!nzchar(ader_file)) {
  ader_file <- test_path(
    "..",
    "..",
    "inst",
    "ext",
    "examples",
    "ADER_yspec.yml"
  )
}

group_cols <- function(spec) {
  names(spec)[vapply(
    spec,
    function(x) isTRUE(x$dots$group),
    logical(1)
  )]
}

test_that("ysx_regroup replaces all existing group settings", {
  spec <- yspec::ys_load(ader_file)
  original <- spec
  expect_setequal(group_cols(spec), c("USUBJID", "ID"))

  result <- ysx_regroup(spec, c("AGE", "SEX"))

  expect_identical(group_cols(result), c("AGE", "SEX"))
  expect_null(result$USUBJID$dots$group)
  expect_identical(result$AGE$dots$time_varying, FALSE)
  expect_identical(spec, original)
})

test_that("ysx_regroup works for columns without dots and repeated names", {
  spec <- yspec::ys_load(test_path("fixatures", "messy.yaml"))
  result <- ysx_regroup(spec, c("ID", "ID", "AGE"))
  expect_identical(group_cols(result), c("AGE", "ID"))
  expect_identical(group_cols(ysx_regroup(result, "WEIGHT")), "WEIGHT")
})

test_that("ysx_regroup validates its inputs", {
  spec <- yspec::ys_load(test_path("fixatures", "messy.yaml"))
  expect_snapshot(error = TRUE, ysx_regroup(list(), "ID"))
  expect_snapshot(error = TRUE, ysx_regroup(spec, character()))
  expect_snapshot(error = TRUE, ysx_regroup(spec, c("ID", "NOPE", "ALSO")))
})

test_that("ysx_check_repeats raises on repeats by default", {
  spec <- ysx_regroup(
    yspec::ys_load(test_path("fixatures", "messy.yaml")),
    c("ID", "AGE")
  )
  data <- data.frame(ID = c(1, 1, 2), AGE = c(30, 31, 30), SEX = "F")
  expect_identical(ysx_check_repeats(data, spec), character(0))
  expect_invisible(ysx_check_repeats(data, spec))

  data$AGE[2] <- 30
  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec))
  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec, count = 2))
  expect_identical(
    ysx_check_repeats(data, spec, count = 2, error_on_fail = FALSE),
    "1 of 2 group(s) defined by AGE, ID do not have 2 row(s) (row counts found: 1)"
  )
  expect_length(ysx_check_repeats(data, spec, error_on_fail = FALSE), 1L)
})

test_that("ysx_check_repeats takes groups directly without changing spec", {
  spec <- yspec::ys_load(test_path("fixatures", "messy.yaml"))
  original <- spec
  data <- data.frame(ID = c(1, 1, 2), AGE = c(30, 31, 30))

  expect_identical(
    ysx_check_repeats(data, spec, groups = c("ID", "AGE")),
    character(0)
  )
  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec, groups = "ID"))
  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec, groups = "NOPE"))
  expect_identical(spec, original)

  # Existing group settings are replaced, not added to
  grouped <- ysx_regroup(spec, "AGE")
  expect_error(
    ysx_check_repeats(data, grouped, groups = "ID"),
    "defined by ID do not"
  )
  expect_error(ysx_check_repeats(data, grouped), "defined by AGE do not")
})

test_that("ysx_check_repeats treats missing values as group values", {
  spec <- ysx_regroup(
    yspec::ys_load(test_path("fixatures", "messy.yaml")),
    "ID"
  )
  expect_snapshot(
    error = TRUE,
    ysx_check_repeats(data.frame(ID = c(NA, 1, NA)), spec)
  )
  expect_identical(
    ysx_check_repeats(data.frame(ID = c(NA, 1)), spec),
    character(0)
  )
})

test_that("ysx_check_repeats handles absent and missing group columns", {
  spec <- ysx_regroup(
    yspec::ys_load(test_path("fixatures", "messy.yaml")),
    c("ID", "AGE")
  )
  data <- data.frame(ID = c(1, 1))

  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec))
  expect_match(
    ysx_check_repeats(data, spec, error_on_fail = FALSE),
    "defined by ID do not have 1"
  )
  expect_identical(
    ysx_check_repeats(
      data.frame(SEX = c("F", "F")),
      spec,
      error_on_fail = FALSE
    ),
    character(0)
  )
  no_groups <- yspec::ys_load(test_path("fixatures", "messy.yaml"))
  expect_identical(ysx_check_repeats(data, no_groups), character(0))
  expect_identical(
    ysx_check_repeats(data[0, , drop = FALSE], spec, error_on_fail = FALSE),
    character(0)
  )
})

test_that("ysx_check_repeats validates its inputs", {
  spec <- ysx_regroup(
    yspec::ys_load(test_path("fixatures", "messy.yaml")),
    "ID"
  )
  data <- data.frame(ID = 1)
  expect_snapshot(error = TRUE, ysx_check_repeats(list(), spec))
  expect_snapshot(error = TRUE, ysx_check_repeats(data, list()))
  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec, count = 0))
  expect_snapshot(error = TRUE, ysx_check_repeats(data, spec, count = 1.5))
  expect_snapshot(
    error = TRUE,
    ysx_check_repeats(data, spec, error_on_fail = NA)
  )
})
