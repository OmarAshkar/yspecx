test_that("ys_sort_spec_vars sorts messy YAML and it can be saved and reloaded", {
  input <- test_path("fixtures", "messy.yaml")
  spec <- yspec::ys_load(input)
  data <- data.frame(ID = 1, AGE = 35, SEX = "F", WEIGHT = 65)

  sorted <- ys_sort_spec_vars(data, spec)

  expect_identical(names(sorted), names(data))
  expect_s3_class(sorted, "yspec")
  expect_identical(yspec::get_meta(sorted), yspec::get_meta(spec))
  expect_identical(attr(sorted, "namespace"), attr(spec, "namespace"))
  for (variable in names(spec)) {
    expect_identical(sorted[[variable]], spec[[variable]])
  }
  expect_identical(names(spec), c("WEIGHT", "SEX", "AGE", "ID"))

  output <- tempfile(fileext = ".yaml")
  on.exit(unlink(output), add = TRUE)
  ys_write(sorted, output)
  reloaded <- yspec::ys_load(output)

  expect_identical(names(yaml::read_yaml(output)), c("SETUP__", names(data)))
  expect_identical(names(reloaded), names(data))
  expect_identical(
    yspec::get_meta(reloaded)$description,
    yspec::get_meta(spec)$description
  )
  for (variable in names(sorted)) {
    expect_identical(
      unclass(reloaded[[variable]])[sort(names(reloaded[[variable]]))],
      unclass(sorted[[variable]])[sort(names(sorted[[variable]]))]
    )
  }
})

test_that("ys_sort_spec_vars retains unmatched variables in their original order", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  data <- data.frame(AGE = numeric(), EXTRA = numeric(), ID = numeric())

  expect_identical(
    names(ys_sort_spec_vars(data, spec)),
    c("AGE", "ID", "WEIGHT", "SEX")
  )
  expect_identical(ys_sort_spec_vars(data.frame(), spec), spec)
  expect_identical(ys_sort_spec_vars(data, spec[NULL]), spec[NULL])
})

test_that("ys_write preserves setup and variable fields without changing input", {
  input <- test_path("fixtures", "messy.yaml")
  spec <- yspec::ys_load(input)
  original <- spec
  output <- tempfile(fileext = ".yaml")
  on.exit(unlink(output), add = TRUE)

  ys_write(spec, output)

  written <- yaml::read_yaml(output)
  source <- yaml::read_yaml(input)
  expect_identical(names(written), c("SETUP__", names(spec)))
  expect_identical(written$SETUP__[names(source$SETUP__)], source$SETUP__)
  expect_identical(written$WEIGHT$unit, "kg")
  expect_identical(written$AGE$unit, "years")
  expect_identical(written$SEX$values, source$SEX$values)
  expect_identical(spec, original)
})

test_that("ys_write retains unmatched variables after sorting and reloading", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  data <- data.frame(AGE = numeric(), EXTRA = numeric(), ID = numeric())
  sorted <- ys_sort_spec_vars(data, spec)
  output <- tempfile(fileext = ".yaml")
  on.exit(unlink(output), add = TRUE)

  ys_write(sorted, output)
  reloaded <- yspec::ys_load(output)

  expect_identical(names(reloaded), c("AGE", "ID", "WEIGHT", "SEX"))
  for (variable in names(sorted)) {
    expect_identical(
      unclass(reloaded[[variable]])[sort(names(reloaded[[variable]]))],
      unclass(sorted[[variable]])[sort(names(sorted[[variable]]))]
    )
  }
})

test_that("ys_write preserves sorted input and setup fields", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  data <- data.frame(ID = numeric(), SEX = character(), AGE = numeric())
  sorted <- ys_sort_spec_vars(data, spec)
  original <- sorted
  output <- tempfile(fileext = ".yaml")
  on.exit(unlink(output), add = TRUE)

  ys_write(sorted, output)
  written <- yaml::read_yaml(output)

  expect_identical(names(written), c("SETUP__", "ID", "SEX", "AGE", "WEIGHT"))
  expect_identical(sorted, original)
  expect_identical(
    written$SETUP__$description,
    yspec::get_meta(sorted)$description
  )
  expect_identical(
    written$SETUP__$projectnumber,
    yspec::get_meta(sorted)$projectnumber
  )
})

test_that("ys_write round-trips the full example after sorting", {
  input <- system.file("ext", "examples", "ADER_yspec.yml", package = "yspecx")
  if (!nzchar(input)) {
    input <- test_path("..", "..", "inst", "ext", "examples", "ADER_yspec.yml")
  }
  spec <- yspec::ys_load(input)
  data <- as.data.frame(stats::setNames(
    rep(list(numeric()), length(spec)),
    rev(names(spec))
  ))
  sorted <- ys_sort_spec_vars(data, spec)
  output <- tempfile(fileext = ".yaml")
  on.exit(unlink(output), add = TRUE)

  ys_write(sorted, output)
  reloaded <- yspec::ys_load(output)
  written <- yaml::read_yaml(output)

  expect_identical(names(reloaded), names(data))
  expect_identical(
    yspec::get_meta(reloaded)$missing_code,
    yspec::get_meta(spec)$missing_code
  )
  expect_identical(
    yspec::get_meta(reloaded)$control,
    yspec::get_meta(spec)$control
  )
  expect_null(written$SETUP__$control)
  expect_null(written$SETUP__$spec_file)
  for (variable in names(sorted)) {
    expect_identical(
      unclass(reloaded[[variable]])[sort(names(reloaded[[variable]]))],
      unclass(sorted[[variable]])[sort(names(sorted[[variable]]))]
    )
  }
})

test_that("ys_write preserves namespaces and materializes lookup results", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  spec$AGE$namespace <- list(
    base = list(unit = "years"),
    tex = list(unit = "yr")
  )
  spec$AGE$lookup <- "AGE_FROM_EXTERNAL_FILE"
  spec$AGE$do_lookup <- TRUE
  spec$AGE$lookup_source <- "unavailable.yaml"
  output <- tempfile(fileext = ".yaml")
  on.exit(unlink(output), add = TRUE)

  ys_write(spec, output)
  reloaded <- yspec::ys_load(output)

  expect_identical(reloaded$AGE$namespace, spec$AGE$namespace)
  expect_identical(reloaded$AGE$unit, spec$AGE$unit)
  expect_identical(reloaded$AGE$lookup, "<none>")
  expect_null(yaml::read_yaml(output)$AGE$lookup_source)
})

test_that("ys_write rejects non-spec inputs and non-YAML paths", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))

  expect_snapshot(error = TRUE, ys_write(list(), "spec.yaml"))
  expect_snapshot(error = TRUE, ys_write(spec, "spec.txt"))
})

test_that("ys_write accepts .yml paths", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  out <- tempfile(fileext = ".yml")
  on.exit(unlink(out), add = TRUE)
  ys_write(spec, out)
  expect_identical(names(yspec::ys_load(out)), names(spec))
})
