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
#'      \item \code{rating}: Numeric (the rating provided, typically 0-1).
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
#' @importFrom dplyr group_by summarise mutate select ungroup rowwise c_across bind_rows rename
#' @importFrom tidyr pivot_wider
#' @importFrom psych interp.median geometric.mean
#' @importFrom irr icc
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
  # CALCULATE SUMMARY STATS (Median, Min, Max)
  # ==========================================================================
  stats_summary <- alignment_df |>
    dplyr::group_by(alignment, role) |>
    dplyr::summarise(
      rating = psych::interp.median(rating, na.rm = TRUE),
      min_val = min(rating, na.rm = TRUE),
      max_val = max(rating, na.rm = TRUE),
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
  result <- list(
    table = as.data.frame(wide_data),
    plot_data = as.data.frame(plot_data),
    icc = icc_res,
    alignment_score = abs(icc_res$value)
  )

  class(result) <- "alignment_analysis"
  return(result)
}
