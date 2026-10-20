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
  # Preserve source fields instead of serializing yspec's derived fields.
  source <- yaml::read_yaml(input)
  yaml::write_yaml(source[c("SETUP__", names(sorted))], output)
  reloaded <- yspec::ys_load(output)

  expect_identical(names(yaml::read_yaml(output)), c("SETUP__", names(data)))
  expect_identical(names(reloaded), names(data))
  expect_identical(
    yspec::get_meta(reloaded)$description,
    yspec::get_meta(spec)$description
  )
  for (variable in names(sorted)) {
    expect_identical(reloaded[[variable]], sorted[[variable]])
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
