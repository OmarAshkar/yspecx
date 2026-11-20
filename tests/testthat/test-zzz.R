test_that("a yspec change does not stop yspecx from loading", {
  expect_snapshot(
    local({
      testthat::local_mocked_bindings(
        extend_yspec_setup_names = function(keys) stop("binding not found"),
        .package = "yspecx"
      )
      .onLoad("lib", "yspecx")
    })
  )
})

test_that("missing_code is registered with yspec", {
  expect_true(
    "missing_code" %in% get("VALID_SETUP_NAMES", asNamespace("yspec"))
  )
  expect_false(extend_yspec_setup_names("missing_code"))
})
