test_that("ysx_plt_relab labels axes, layer legends and decoded wrap facets", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  data <- data.frame(AGE = 35, WEIGHT = 65, SEX = "F")
  plot <- ggplot2::ggplot(data, ggplot2::aes(AGE, WEIGHT)) +
    ggplot2::geom_point(ggplot2::aes(colour = SEX)) +
    ggplot2::facet_wrap(~SEX)
  original <- plot$facet$params$labeller

  result <- ysx_plt_relab(plot, spec)

  expect_identical(result$labels$x, "AGE (years)")
  expect_identical(result$labels$y, "WEIGHT (kg)")
  expect_identical(result$labels$colour, "SEX")
  expect_identical(
    result$facet$params$labeller(data.frame(SEX = c("F", "M", "X"))),
    list(c("SEX: Female", "SEX: Male", "SEX: X"))
  )
  expect_identical(plot$facet$params$labeller, original)
  expect_s3_class(ggplot2::ggplotGrob(result), "gtable")
})

test_that("custom labels override spec and work with grid facets and plot lists", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  data <- data.frame(AGE = 35, WEIGHT = 65, SEX = "F", GROUP = "A")
  plot <- ggplot2::ggplot(data, ggplot2::aes(AGE, WEIGHT)) +
    ggplot2::geom_point() +
    ggplot2::facet_grid(GROUP ~ SEX)
  result <- ysx_plt_relab(
    plot,
    spec,
    labs = list(AGE = "Age", SEX = "Sex", GROUP = "Arm"),
    facet_labels = list(SEX = c(F = "Woman"), GROUP = c(A = "Active"))
  )

  expect_identical(result$labels$x, "Age")
  expect_identical(
    result$facet$params$labeller(data.frame(GROUP = "A", SEX = "F")),
    list("Arm: Active", "Sex: Woman")
  )
  expect_s3_class(ggplot2::ggplotGrob(result), "gtable")
  expect_named(ysx_plt_relab(list(first = plot), spec), "first")
})

test_that("custom-only labels and unmatched expressions are supported", {
  plot <- ggplot2::ggplot(
    data.frame(AGE = 35, WEIGHT = 65),
    ggplot2::aes(log(AGE), WEIGHT)
  ) +
    ggplot2::geom_point()
  result <- ysx_plt_relab(plot, labs = c(AGE = "Age", WEIGHT = "Weight"))

  expect_null(result$labels$x)
  expect_identical(result$labels$y, "Weight")
  expect_s3_class(ggplot2::ggplotGrob(result), "gtable")
})

test_that("variable mappings relabel axes and facets without renaming data", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  data <- data.frame(age = 35, wt = 65, sex = "F")
  plot <- ggplot2::ggplot(data, ggplot2::aes(age, wt, colour = sex)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~sex)
  result <- ysx_plt_relab(
    plot,
    spec,
    var_map = c(age = "AGE", wt = "WEIGHT", sex = "SEX"),
    label_type = "long"
  )

  expect_identical(result$labels$x, "Age (years)")
  expect_identical(result$labels$y, "Body weight (kg)")
  expect_identical(result$labels$colour, "Sex")
  expect_identical(
    result$facet$params$labeller(data.frame(sex = "F")),
    list("Sex: Female")
  )
  expect_identical(result$data, plot$data)
  expect_identical(result$mapping, plot$mapping)
  expect_s3_class(ggplot2::ggplotGrob(result), "gtable")
  expect_identical(
    ysx_plt_relab(
      plot,
      spec,
      var_map = c(wt = "WEIGHT"),
      label_type = "short"
    )$labels$y,
    "WEIGHT (kg)"
  )
})

test_that("field validation applies only to used variables without overrides", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  spec$AGE$long <- NULL
  plot <- ggplot2::ggplot(
    data.frame(AGE = 35, WEIGHT = 65),
    ggplot2::aes(AGE, WEIGHT)
  ) +
    ggplot2::geom_point()

  expect_snapshot(error = TRUE, ysx_plt_relab(plot, spec, label_type = "long"))
  expect_identical(
    ysx_plt_relab(
      plot,
      spec,
      labs = c(AGE = "Custom age"),
      label_type = "long"
    )$labels$x,
    "Custom age"
  )
  spec$AGE$long <- ""
  expect_snapshot(error = TRUE, ysx_plt_relab(plot, spec, label_type = "long"))
  expect_snapshot(
    error = TRUE,
    ysx_plt_relab(plot, spec, var_map = c(AGE = "UNKNOWN"))
  )
  expect_snapshot(error = TRUE, ysx_plt_relab(plot, spec, label_type = "other"))
  result <- ysx_plt_relab(list(plot), spec, label_type = "short")
  expect_identical(result[[1]]$labels$x, "AGE (years)")
})

test_that("plot_labels picks custom, then chosen field, then default label", {
  spec <- yspec::ys_load(test_path("fixtures", "messy.yaml"))
  used <- c("AGE", "WEIGHT", "SEX", "other")

  default <- plot_labels(used, spec, list(), character(), NULL)
  expect_identical(default$AGE, "AGE (years)")
  expect_identical(default$WEIGHT, "WEIGHT (kg)")
  expect_null(default$other)

  long <- plot_labels(used, spec, list(AGE = "Custom"), character(), "long")
  expect_identical(long$AGE, "Custom")
  expect_identical(long$WEIGHT, "Body weight (kg)")
  expect_identical(long$SEX, "Sex")
  expect_null(long$other)

  mapped <- plot_labels("w", spec, list(), c(w = "WEIGHT"), "long")
  expect_identical(mapped$w, "Body weight (kg)")

  expect_identical(
    plot_labels("x", NULL, list(x = "X"), character(), NULL),
    list(x = "X")
  )
  expect_identical(plot_labels("x", NULL, list(), character(), NULL), list())

  spec$AGE$long <- NULL
  expect_snapshot(
    error = TRUE,
    plot_labels("AGE", spec, list(), character(), "long")
  )
})
