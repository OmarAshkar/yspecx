#' Relabel plot titles, legends and facet strips from a specification
#'
#' Labels use [yspec::axis_labs()], including units. Explicit `labs` entries
#' override specification labels and can also label variables absent from the
#' specification. Only direct variable mappings are relabelled; expressions and
#' unmatched labels are left unchanged. Layer-specific mappings are supported.
#'
#' Facet strips show the variable label and level. Coded levels are decoded
#' using the specification, with optional overrides in `facet_labels`. Existing
#' facet labellers are replaced. Axis tick labels and legend entries are not
#' changed. The input plot and specification are not modified.
#'
#' @param x A ggplot object or a list of ggplot objects.
#' @param spec A loaded yspec object, or `NULL` to use only custom labels.
#' @param labs A named list or character vector of variable labels.
#' @param facet_labels A named list of named character vectors mapping facet
#'   levels to labels, for example `list(SEX = c(F = "Female", M = "Male"))`.
#' @param var_map A named character vector mapping plot variable names to
#'   specification variable names, for example `c(wt = "WEIGHT")`. This changes
#'   label lookup only, not plot data or mappings. Custom labels use plot names.
#' @param label_type `NULL` (default) uses the usual axis labels. Otherwise,
#'   `"long"` or `"short"` selects that specification field, including units.
#'   An error is raised if the requested field is unavailable for a plotted
#'   specification variable, unless a custom label overrides it.
#' @return A relabelled plot, or a list of relabelled plots.
#' @export
ys_plt_relab <- function(
  x,
  spec = NULL,
  labs = list(),
  facet_labels = list(),
  var_map = character(),
  label_type = NULL
) {
  stopifnot(is.null(spec) || inherits(spec, "yspec"))
  if (!is.null(label_type)) {
    label_type <- match.arg(label_type, c("long", "short"))
  }
  valid_labels <- function(labels) {
    (is.list(labels) || is.character(labels)) &&
      (length(labels) == 0L ||
        (!is.null(names(labels)) &&
          all(nzchar(names(labels))) &&
          !anyDuplicated(names(labels)) &&
          all(vapply(
            labels,
            \(label) {
              is.character(label) &&
                length(label) == 1L &&
                !is.na(label)
            },
            logical(1)
          ))))
  }
  stopifnot(valid_labels(labs), is.list(facet_labels))
  stopifnot(is.character(var_map), valid_labels(var_map))
  if (length(var_map) && (is.null(spec) || any(!var_map %in% names(spec)))) {
    stop("Every var_map target must name a variable in spec.", call. = FALSE)
  }
  stopifnot(
    length(facet_labels) == 0L ||
      (!is.null(names(facet_labels)) &&
        all(nzchar(names(facet_labels))) &&
        all(vapply(facet_labels, valid_labels, logical(1))))
  )
  if (!inherits(x, "ggplot") && is.list(x)) {
    return(lapply(
      x,
      ys_plt_relab,
      spec = spec,
      labs = labs,
      facet_labels = facet_labels,
      var_map = var_map,
      label_type = label_type
    ))
  }
  stopifnot(inherits(x, "ggplot"))
  labels <- if (is.null(spec)) list() else as.list(yspec::axis_labs(spec))
  default_labels <- labels
  mappings <- c(
    x$mapping,
    do.call(c, lapply(unname(x$layers), \(layer) layer$mapping))
  )
  used <- unique(c(
    vapply(mappings, rlang::as_label, character(1)),
    names(x$facet$params$facets),
    names(x$facet$params$rows),
    names(x$facet$params$cols)
  ))
  lookup_variable <- function(variable) {
    if (variable %in% names(var_map)) unname(var_map[[variable]]) else variable
  }
  for (variable in used) {
    target <- lookup_variable(variable)
    if (variable %in% names(labs) || !target %in% names(spec)) {
      next
    }
    if (!is.null(label_type)) {
      value <- spec[[target]][[label_type]]
      if (
        !is.character(value) ||
          length(value) != 1L ||
          is.na(value) ||
          !nzchar(trimws(value))
      ) {
        stop(
          "Field '",
          label_type,
          "' is unavailable for variable '",
          target,
          "'.",
          call. = FALSE
        )
      }
      column <- spec[[target]]
      column$axis <- value
      labels[[variable]] <- yspec::axis_label(column)
    } else {
      labels[[variable]] <- default_labels[[target]]
    }
  }
  labels[names(labs)] <- as.list(labs)
  titles <- list()
  for (aesthetic in unique(names(mappings))) {
    variable <- rlang::as_label(mappings[[aesthetic]])
    if (variable %in% names(labels)) {
      titles[[aesthetic]] <- labels[[variable]]
    }
  }
  x <- x + do.call(ggplot2::labs, titles)
  decodes <- lapply(spec, function(column) {
    if (is.null(column$values) || is.null(column$decode)) {
      return(NULL)
    }
    stats::setNames(as.character(column$decode), as.character(column$values))
  })
  decodes[names(var_map)] <- lapply(unname(var_map), \(target) {
    decodes[[target]]
  })
  decodes[names(facet_labels)] <- facet_labels
  strip_labeller <- function(data) {
    for (variable in names(data)) {
      values <- as.character(data[[variable]])
      lookup <- decodes[[variable]]
      if (length(lookup)) {
        matched <- match(values, names(lookup))
        replace <- !is.na(matched)
        values[replace] <- unlist(lookup, use.names = FALSE)[matched[replace]]
      }
      data[[variable]] <- values
    }
    names(data) <- vapply(
      names(data),
      function(variable) {
        if (variable %in% names(labels)) labels[[variable]] else variable
      },
      character(1)
    )
    ggplot2::label_both(data)
  }
  class(strip_labeller) <- c("labeller", "function")
  facet <- x$facet
  x$facet <- ggplot2::ggproto(NULL, facet)
  x$facet$params$labeller <- strip_labeller
  x
}
