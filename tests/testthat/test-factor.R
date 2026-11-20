test_that("first and missing order settings reproduce ys_factors", {
  spec <- yspec::ys_load(test_path("fixtures", "factor.yaml"))
  data <- data.frame(FIRST = c(2, 2, 1, 3), DEFAULT = c(3, 2, 2, 1))

  expect_identical(ysx_factors(data, spec), yspec::ys_factors(data, spec))
  expect_identical(
    levels(ysx_factors(data, spec)$FIRST),
    c("One", "Two", "Three", "Unused")
  )
})

test_that("biggest sorts frequencies with stable ties and unused levels", {
  spec <- yspec::ys_load(test_path("fixtures", "factor.yaml"))
  data <- data.frame(BIGGEST = c(3, 2, 2, 3, 2, 1, NA))
  attr(data$BIGGEST, "label") <- "Original label"
  original <- data
  result <- ysx_factors(data, spec)

  expect_identical(levels(result$BIGGEST), c("Two", "Three", "One", "Unused"))
  expect_identical(
    as.character(result$BIGGEST),
    c("Three", "Two", "Two", "Three", "Two", "One", NA_character_)
  )
  expect_identical(result$BIGGEST_v, data$BIGGEST)
  expect_identical(attr(result$BIGGEST, "label"), "Original label")
  expect_identical(data, original)
  tied <- ysx_factors(data.frame(BIGGEST = c(3, 2)), spec)
  expect_identical(levels(tied$BIGGEST), c("Two", "Three", "One", "Unused"))
  expect_identical(
    levels(ysx_factors(data.frame(BIGGEST = numeric()), spec)$BIGGEST),
    c("One", "Two", "Three", "Unused")
  )
  expect_identical(
    levels(
      ysx_factors(data.frame(BIGGEST = c(NA_real_, NA_real_)), spec)$BIGGEST
    ),
    c("One", "Two", "Three", "Unused")
  )
})

test_that("selection, suffixes, make_factor and existing factors follow yspec", {
  spec <- yspec::ys_load(test_path("fixtures", "factor.yaml"))
  data <- data.frame(
    FIRST = c(1, 2, 2),
    BIGGEST = c(1, 2, 2),
    TEXT = c("a", "b", "b")
  )
  result <- ysx_factors(data, spec, BIGGEST, .keep_values = FALSE)
  expect_named(result, names(data))
  expect_identical(result$FIRST, data$FIRST)
  expect_identical(result$TEXT, data$TEXT)
  expect_identical(levels(result$BIGGEST), c("Two", "One", "Three", "Unused"))
  expect_named(
    ysx_factors(data, spec, TEXT, .suffix = "_raw"),
    c(names(data), "TEXT_raw")
  )
  expect_identical(levels(ysx_factors(data, spec, TEXT)$TEXT), c("b", "a"))
  data$BIGGEST <- factor(data$BIGGEST, levels = c(1, 2))
  expect_identical(ysx_factors(data, spec, BIGGEST)$BIGGEST, data$BIGGEST)
})

test_that("invalid order settings fail only for converted columns", {
  spec <- yspec::ys_load(test_path("fixtures", "factor.yaml"))
  data <- data.frame(FIRST = 1, BIGGEST = 2)
  for (value in list("smallest", TRUE, NA_character_, c("first", "biggest"))) {
    spec$BIGGEST$dots$order <- value
    expect_snapshot(error = TRUE, ysx_factors(data, spec, BIGGEST))
  }
  expect_identical(
    ysx_factors(data, spec, FIRST),
    yspec::ys_factors(data, spec, FIRST)
  )
})

test_that("values outside the specification warn when they become NA", {
  spec <- yspec::ys_load(test_path("fixtures", "factor.yaml"))
  data <- data.frame(FIRST = c(1, 2, 9, 8, NA))
  expect_snapshot(result <- ysx_factors(data, spec))
  expect_identical(as.character(result$FIRST), c("One", "Two", NA, NA, NA))

  expect_no_warning(ysx_factors(data.frame(FIRST = c(1, NA)), spec))
  many <- data.frame(FIRST = 11:20)
  expect_snapshot(ysx_factors(many, spec) |> invisible())
})
