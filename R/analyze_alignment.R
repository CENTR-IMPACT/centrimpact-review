#' Calculate Alignment Scores
#'
#' @description
#' Performs a comprehensive analysis of alignment between "researcher" and "partner"
#' ratings using the CEnTR*IMPACT methodology. This function calculates the Intraclass
#' Correlation Coefficient (ICC) to derive an Alignment Score (\eqn{S_a}), alongside
#' descriptive statistics (interpolated medians and ranges) to visualize the gap between
#' perspectives.
#'
#' @param alignment_df A data frame containing raw survey responses. Must contain:
#'    \itemize{
#'      \item \code{role}: Character ('researcher' or 'partner').
#'      \item \code{alignment}: Character (the factor/category being rated).
#'      \item \code{rating}: Numeric. Ratings on a 1–10 scale (as exported by
#'        Qualtrics or Google Forms) or already normalised to \eqn{[0, 1]}.
#'        Values greater than 1 are automatically rescaled to \eqn{[0, 1]}
#'        using min–max normalisation before any summaries are computed.
#'    }
#'
#' @return An object of class \code{alignment_analysis} containing:
#'    \itemize{
#'      \item \code{table}: Wide-format data frame with interpolated medians.
#'      \item \code{plot_data}: Long-format data frame suitable for ggplot2.
#'      \item \code{icc}: The full ICC object from the \code{irr} package.
#'      \item \code{alignment_score}: The numeric ICC value (\eqn{S_a}).
#'    }
#'
#' @importFrom dplyr group_by summarise mutate select ungroup rowwise c_across bind_rows rename left_join relocate
#' @importFrom tidyr pivot_wider
#' @importFrom psych interp.median geometric.mean
#' @importFrom irr icc
#' @importFrom stats median
#' @export
analyze_alignment <- function(alignment_df) {

  # ==========================================================================
  # DATA VALIDATION
  # ==========================================================================
  required_cols <- c("role", "alignment", "rating")
  if (!all(required_cols %in% names(alignment_df))) {
    stop("Input must contain columns: 'role', 'alignment', 'rating'")
  }

  # ==========================================================================
  # NORMALIZE RATINGS TO [0, 1]
  # ==========================================================================
  # The alignment survey uses a 1–10 scale. Both visualizations hard-code
  # their axes to [0, 1], so ratings must be rescaled before any summaries
  # are computed. If ratings are already in [0, 1] (max <= 1) we leave them
  # untouched to keep the function idempotent.
  raw_max <- max(alignment_df$rating, na.rm = TRUE)
  if (raw_max > 1) {
    raw_min <- min(alignment_df$rating, na.rm = TRUE)
    scale_range <- raw_max - raw_min
    if (scale_range == 0) {
      alignment_df$rating <- 0.5  # degenerate: all identical, place at midpoint
    } else {
      alignment_df$rating <- (alignment_df$rating - raw_min) / scale_range
    }
  }

  # ==========================================================================
  # CALCULATE SUMMARY STATS (Median, Min, Max)
  # ==========================================================================
  # NOTE: min_val and max_val must be computed BEFORE rating is overwritten
  # with the interpolated median. psych::interp.median() returns NA for a
  # single observation, so we fall back to stats::median() in that case.
  stats_summary <- alignment_df |>
    dplyr::group_by(alignment, role) |>
    dplyr::summarise(
      min_val = min(rating, na.rm = TRUE),
      max_val = max(rating, na.rm = TRUE),
      rating  = {
        m <- psych::interp.median(rating, na.rm = TRUE)
        if (is.na(m)) stats::median(rating, na.rm = TRUE) else m
      },
      .groups = "drop"
    )

  # ==========================================================================
  # PIVOT WIDE (For ICC & Geometric Mean)
  # ==========================================================================
  wide_data <- stats_summary |>
    dplyr::select(alignment, role, rating) |>
    tidyr::pivot_wider(
      names_from = role,
      values_from = rating
    )

  # Safety check: Ensure columns exist for calculation
  if (!"researcher" %in% names(wide_data)) wide_data$researcher <- NA
  if (!"partner" %in% names(wide_data)) wide_data$partner <- NA

  # ==========================================================================
  # CALCULATE OVERALL CONSENSUS
  # ==========================================================================
  # Use rowwise to apply geometric mean across the specific role columns
  overall_df <- wide_data |>
    dplyr::rowwise() |>
    dplyr::mutate(
      rating = psych::geometric.mean(dplyr::c_across(c(researcher, partner))),
      role = "overall"
    ) |>
    dplyr::ungroup() |>
    dplyr::select(alignment, role, rating)

  # ==========================================================================
  # ASSEMBLE PLOT DATA
  # ==========================================================================
  # Combine the detailed group stats with the overall consensus rows
  plot_data <- dplyr::bind_rows(stats_summary, overall_df)

  # ==========================================================================
  # ICC CALCULATION
  # ==========================================================================
  icc_res <- tryCatch({
    irr::icc(
      wide_data[, c("researcher", "partner")],
      model = "twoway", type = "agreement", unit = "single"
    )
  }, error = function(e) list(value = NA))

  # ==========================================================================
  # RETURN
  # ==========================================================================
  # Build a display table that includes partner, researcher, AND overall so
  # the data table modal shows the complete picture.
  overall_wide <- overall_df |>
    tidyr::pivot_wider(names_from = role, values_from = rating)

  display_table <- wide_data |>
    dplyr::left_join(overall_wide, by = "alignment") |>
    dplyr::relocate(alignment, partner, researcher, overall)

  result <- list(
    table = as.data.frame(display_table),
    plot_data = as.data.frame(plot_data),
    icc = icc_res,
    alignment_score = abs(icc_res$value)
  )

  class(result) <- "alignment_analysis"
  return(result)
}
