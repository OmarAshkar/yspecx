test_that("ysx_load_pkpdspec loads the bundled NONMEM specification", {
  spec <- ysx_load_pkpdspec()

  expect_s3_class(spec, "yspec")
  expect_true(all(
    c(
      "ID",
      "TIME",
      "DV",
      "CMT",
      "EVID",
      "AMT",
      "RATE",
      "II",
      "SS",
      "ADDL",
      "MDV"
    ) %in%
      names(spec)
  ))
  expect_identical(spec$EVID$decode[spec$EVID$values == 1], "dose")
  expect_identical(spec$DV$dots$na_ok, TRUE)
  expect_identical(spec$ID$dots$group, TRUE)
  expect_identical(yspec::get_meta(spec)$missing_code, -999L)
})

test_that("the bundled specification works with the checks and ysx_factors", {
  spec <- ysx_load_pkpdspec()
  data <- data.frame(
    ID = c(1, 1, 1),
    TIME = c(0, 1, 2),
    EVID = c(1, 0, 0),
    DV = c(-999, 5, 4),
    CMT = c(1, 2, 2)
  )
  expect_identical(
    ysx_check_missing(data, spec, error_on_fail = FALSE),
    character(0)
  )

  data$CMT[2] <- -999
  expect_match(
    ysx_check_missing(data, spec, error_on_fail = FALSE),
    "CMT: 1 missing"
  )
  data$DV[2] <- NA
  expect_match(
    ysx_check_missing(data, spec, error_on_fail = FALSE),
    "DV: 1 missing value\\(s\\) coded NA",
    all = FALSE
  )
  expect_identical(
    levels(ysx_factors(data["EVID"], spec)$EVID)[1:2],
    c("observation", "dose")
  )
})

test_that("ysx_load_pkpdspec passes arguments to ys_load", {
  expect_silent(ysx_load_pkpdspec(verbose = FALSE))
})
