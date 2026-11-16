#' Convert columns to factors with specification-controlled ordering
#'
#' Extends [yspec::ys_factors()] with a per-variable `dots: {order: biggest}`
#' setting. `order` must be `"first"` or `"biggest"`. Missing settings default
#' to `"first"`, preserving yspec's factor level order. `"biggest"` orders
#' levels by decreasing frequency in the supplied data. Ties retain the
#' original level order, and unused levels are retained at the end. Missing
#' observations do not contribute to counts unless they are an explicit level.
#'
#' Selection, decoding, retained value columns and existing factors follow
#' [yspec::ys_factors()]. In particular, existing factors are not reordered.
#' Order settings are validated only for columns being converted.
#'
#' @inheritParams yspec::ys_factors
#' @return The data frame with selected columns converted to factors.
#' @export
ysx_factors <- function(data, spec, ..., .keep_values = TRUE, .suffix = "_v") {
  result <- yspec::ys_factors(
    data,
    spec,
    ...,
    .keep_values = .keep_values,
    .suffix = .suffix
  )
  converted <- intersect(names(data), names(spec))
  converted <- converted[vapply(
    converted,
    function(variable) {
      !is.factor(data[[variable]]) && is.factor(result[[variable]])
    },
    logical(1)
  )]
  for (variable in converted) {
    ordering <- spec[[variable]]$dots$order
    if (is.null(ordering)) {
      ordering <- "first"
    }
    if (
      !is.character(ordering) ||
        length(ordering) != 1L ||
        is.na(ordering) ||
        !ordering %in% c("first", "biggest")
    ) {
      stop(
        "Variable '",
        variable,
        "': dots$order must be 'first' or 'biggest'.",
        call. = FALSE
      )
    }
    if (ordering == "biggest") {
      column <- result[[variable]]
      counts <- tabulate(as.integer(column), nbins = nlevels(column))
      level_order <- order(-counts, seq_along(counts))
      # Remap integer codes without losing factor attributes or NA levels.
      attributes_saved <- attributes(column)
      codes <- match(as.integer(column), level_order)
      attributes_saved$levels <- levels(column)[level_order]
      attributes(codes) <- attributes_saved
      result[[variable]] <- codes
    }
  }
  result
}
