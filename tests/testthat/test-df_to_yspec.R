test_that("df_to_yspec creates a valid YAML file with top-level variables", {
  # Create a dummy data frame
  adam_df <- data.frame(
    varname = c("AGE", "SEX", "WEIGHT"),
    vardesc = c("Age of the subject", "Sex of the subject", "Weight of the subject"),
    varunit = c("years", NA, "kg"),
    vartype = c("numeric", "character", "numeric"),
    stringsAsFactors = FALSE
  )
  
  # Define output path
  output_path <- tempfile(fileext = ".yaml")
  
  # Run the function
  df_to_yspec(
    x = adam_df,
    desc = "Another example PK type data set",
    varname = "varname",
    vardesc = "vardesc",
    varunit = "varunit",
    vartype = "vartype",
    output = output_path
  )
  
  # Validate the YAML file
  yaml_content <- yspec::ys_load(output_path)
  
  # Validate SETUP__ section
  expect_equal(yspec::get_meta(yaml_content)[[1]], "Another example PK type data set")
  
  # Validate top-level variables
  expect_equal(yaml_content$AGE$long, "Age of the subject")
  expect_equal(yaml_content$AGE$unit, "years")
  expect_equal(yaml_content$AGE$type, "numeric")
  
  expect_equal(yaml_content$SEX$long, "Sex of the subject")
  expect_false("unit" %in% names(yaml_content$SEX)) # Ensure 'unit' is excluded for N/A
  
  expect_equal(yaml_content$WEIGHT$long, "Weight of the subject")
  expect_equal(yaml_content$WEIGHT$unit, "kg")
  expect_equal(yaml_content$WEIGHT$type, "numeric")
})


test_that("df_to_yspec with non-existing cols", {
  adam_df <- data.frame(
    varname = c("AGE", "SEX", "WEIGHT"),
    vardesc = c("Age of the subject", "Sex of the subject", "Weight of the subject"),
    vartype = c("numeric", "character", "numeric"),
    stringsAsFactors = FALSE
  )

  # Define output path
  output_path <- tempfile(fileext = ".yaml")

  df_to_yspec(
    x = adam_df,
    desc = "Another example PK type data set",
    varname = "varname",
    vardesc = "vardesc",
    vartype = "vartype",
    output = output_path
  ) |> expect_no_error()

  # Validate the YAML file
  yaml_content <- yspec::ys_load(output_path)

  # Validate SETUP__ section
  expect_equal(yspec::get_meta(yaml_content)[[1]], "Another example PK type data set")

  # Validate top-level variables
  expect_equal(yaml_content$AGE$long, "Age of the subject")
  expect_equal(yaml_content$AGE$type, "numeric")

  expect_equal(yaml_content$SEX$long, "Sex of the subject")
  expect_equal(yaml_content$SEX$type, "character")

  expect_equal(yaml_content$WEIGHT$long, "Weight of the subject")
  expect_equal(yaml_content$WEIGHT$type, "numeric")
})

test_that("df_to_yspec converts codelist strings to YAML values", {
  device_df <- data.frame(
    varname = c("MATERIAL", "STATE", "SERIAL", "EMPTY"),
    vartype = c("numeric", "numeric", "numeric", "numeric"),
    varcodelist = c(
      "10=Copper coil, 20=Glass panel, 30=Polymer casing, Unknown= -1",
      "0 = Idle\n1=Calibration pending\n2=Signal outside range\n3=Battery replacement needed\n4=Ready for shipping",
      NA_character_, ""
    )
  )
  output_path <- tempfile(fileext = ".yaml")

  df_to_yspec(device_df, varname = "varname", vartype = "vartype",
              varcodelist = "varcodelist", output = output_path)

  yaml_content <- yspec::ys_load(output_path)
  expect_equal(yaml_content$MATERIAL$values[["Copper coil"]], 10L)
  expect_equal(yaml_content$MATERIAL$values[["Polymer casing"]], 30L)
  expect_equal(yaml_content$MATERIAL$values[["Unknown"]], -1L)
  expect_equal(yaml_content$STATE$values[["Idle"]], 0L)
  expect_equal(yaml_content$STATE$values[["Signal outside range"]], 2L)
  expect_false("values" %in% names(yaml_content$SERIAL))
  expect_false("values" %in% names(yaml_content$EMPTY))
})

test_that("df_to_yspec accepts a custom codelist parser", {
  device_df <- data.frame(varname = "FINISH", varcodelist = "MATTE|GLOSS")
  output_path <- tempfile(fileext = ".yaml")
  parser <- function(text) {
    stats::setNames(as.list(c(1L, 2L)), strsplit(text, "|", fixed = TRUE)[[1]])
  }

  df_to_yspec(device_df, varname = "varname", varcodelist = "varcodelist",
              codelist_func = parser, output = output_path)

  expect_equal(yspec::ys_load(output_path)$FINISH$values[["GLOSS"]], 2L)
})



