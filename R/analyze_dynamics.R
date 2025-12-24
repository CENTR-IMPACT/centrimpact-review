#' Analyze Project Dynamics
#'
#' @description
#' Implements the "Dynamics" component of the CEnTR*IMPACT framework (Price, 2024).
#' This function processes multidimensional assessment data to calculate domain-level
#' scores using geometric means and computes a "Balance Score" (\eqn{S_d}) using the
#' Gini coefficient. It is designed to measure the equitable distribution of effort
#' and impact across the core domains of the CBPR Framework (Wallerstein & Duran, 2010; Wallerstein, et al., 2020).
#'
#' @details
#' The CEnTR*IMPACT framework uses this analysis to quantify "Developmental Balance."
#' A higher Balance Score indicates that the project is maintaining a healthy
#' equilibrium across its various dimensions, rather than over-indexing on just one
#' area at the expense of others.
#'
#' \strong{The Scoring Process:}
#' \enumerate{
#'   \item \strong{Dimension Scoring:} Calculated as the geometric mean of weight and salience.
#'   \deqn{Score_{dim} = \sqrt{Weight \times Salience}}
#'   \item \strong{Domain Scoring:} Aggregates dimension scores within each domain using the geometric mean.
#'   \item \strong{Dynamics Scoring:} Calculated based on the inequality of domain scores.
#'   \deqn{S_d = 1 - Gini(Score_{domains})}
#' }
#'
#' \strong{Dynamics Score Interpretation:}
#' The following rule of thumb (Haddad et al., 2024; Wang et al., 2020) is used to interpret the Dynamics Score (\eqn{S_d}):
#' \itemize{
#'   \item \eqn{S_d < 0.50}: \strong{Very Low Balance}
#'   \item \eqn{0.50 \le S_d < 0.59}: \strong{Low Balance}
#'   \item \eqn{0.60 \le S_d < 0.69}: \strong{Moderate Balance}
#'   \item \eqn{0.70 \le S_d \le 0.79}: \strong{High Balance}
#'   \item \eqn{S_d \ge 0.80}: \strong{Very High Balance}
#' }
#'
#' \strong{Handling Missing Data:}
#' The function is permissive with partial datasets. If a domain is included in the
#' input but contains \code{NA} values for weights or salience, it is retained in
#' the output. However, if sufficient data is missing to prevent calculation, the
#' score will be \code{NaN}.
#'
#' @param dynamics_df A data frame containing the assessment data. Required columns:
#'   \itemize{
#'     \item \code{domain}: Character or Factor. The broader category (e.g., "Partnerships").
#'     \item \code{dimension}: Character or Factor. The specific metric (e.g., "Trust").
#'     \item \code{salience}: Numeric. The importance of the dimension. Must be \eqn{0 < x \le 1}.
#'     \item \code{weight}: Numeric. The observed intensity or presence. Must be \eqn{0 < x \le 1}.
#'   }
#'
#' @return An object of class \code{dynamics_analysis} containing:
#'   \itemize{
#'     \item \code{dynamics_df}: The processed input data frame with added \code{dimension_score}.
#'     \item \code{domain_df}: A summary data frame with aggregated scores per domain.
#'     \item \code{dynamics_score}: A single numeric value representing the Balance Score (\eqn{S_d}), where 1 indicates perfect balance.
#'   }
#'
#' @references
#' Haddad, C. N., Mahler, D. G., Diaz-Bonilla, C., Hill, R., Lakner, C., & Lara Ibarra, G. (2024). \emph{The World Bank's New Inequality Indicator: The Number of Countries with High Inequality}. Washington, DC: World Bank. \doi{10.1596/41687}
#'
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation} (CUMU-Collaboratory Fellowship Report). Coalition of Urban and Metropolitan Universities.
#'
#' Wallerstein, N., & Duran, B. (2010). Community-Based Participatory Research Contributions to Intervention Research: The Intersection of Science and Practice to Improve Health Equity. \emph{American Journal of Public Health}, 100(S1), S40–S46. \doi{10.2105/AJPH.2009.184036}
#'
#' Wallerstein, N., et al. (2020). Engage for Equity: A Long-Term Study of Community-Based Participatory Research and Community-Engaged Research Practices and Outcomes. \emph{Health Education & Behavior}, 47(3), 380–390. \doi{10.1177/1090198119897075}
#'
#' Wang, H.-Y., Chou, W., Shao, Y., & Chien, T.-W. (2020). Comparison of Ferguson’s delta and the Gini coefficient used for measuring the inequality of data related to health quality of life outcomes. \emph{Health and Quality of Life Outcomes}, 18(1), 111. \doi{10.1186/s12955-020-01356-6}
#'
#' @examples
#' # 1. Generate synthetic data using the built-in generator
#' # We use a fixed seed to ensure the example is reproducible
#' df <- generate_dynamics_data(seed = 123)
#'
#' # 2. Run the Dynamics analysis
#' result <- analyze_dynamics(df)
#'
#' # 3. Inspect the global Balance Score (Sd)
#' # A score closer to 1.0 indicates high balance across domains
#' print(result$dynamics_score)
#'
#' # 4. Inspect the domain-level scores
#' print(result$domain_df)
#'
#' # 5. Example with high-variance data (to show lower balance)
#' df_unbalanced <- generate_dynamics_data(seed = 123, domain_variance = TRUE)
#' result_unbalanced <- analyze_dynamics(df_unbalanced)
#' print(result_unbalanced$dynamics_score)
#'
#' @importFrom psych geometric.mean
#' @importFrom dplyr group_by mutate select ungroup distinct summarize left_join
#' @export
analyze_dynamics <- function(dynamics_df) {

  # ==========================================================================
  # INPUT VALIDATION
  # ==========================================================================

  if (!is.data.frame(dynamics_df)) {
    stop("Input must be a data frame")
  }

  required_cols <- c("domain", "dimension", "weight", "salience")
  missing_cols <- setdiff(required_cols, names(dynamics_df))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  if (nrow(dynamics_df) == 0) {
    stop("Input data frame must contain at least one row")
  }

  # Validate numeric ranges (ignoring NAs)
  # Note: Geometric mean requires strictly positive numbers (>0).
  if (any(dynamics_df$weight <= 0 | dynamics_df$weight > 1, na.rm = TRUE)) {
    stop("weight must be strictly greater than 0 and less than or equal to 1")
  }
  if (any(dynamics_df$salience <= 0 | dynamics_df$salience > 1, na.rm = TRUE)) {
    stop("salience must be strictly greater than 0 and less than or equal to 1")
  }

  # Remove rows only if the Domain name itself is missing (orphaned data)
  valid_domains <- !is.na(dynamics_df$domain) & dynamics_df$domain != ""
  dynamics_df <- dynamics_df[valid_domains, ]

  if (nrow(dynamics_df) == 0) {
    stop("No valid domain values found after filtering")
  }

  # ==========================================================================
  # CALCULATE SCORES
  # ==========================================================================

  # Calculate dimension_value = weight * salience
  dynamics_df <- dynamics_df |>
    dplyr::mutate(dimension_value = weight * salience)

  # Calculate Dimension Scores (Geometric Mean)
  # na.rm = TRUE handles partial missing data within groups
  dynamics_df <- dynamics_df |>
    dplyr::group_by(dimension) |>
    dplyr::mutate(
      dimension_score = round(psych::geometric.mean(dimension_value, na.rm = TRUE), 2)
    ) |>
    dplyr::ungroup()

  # Create dimension summary for domain aggregation
  dimension_summary <- dynamics_df |>
    dplyr::distinct(domain, dimension, .keep_all = TRUE) |>
    dplyr::select(domain, dimension, dimension_score)

  # Calculate Domain Scores (Geometric Mean of Dimension Scores)
  domain_scores <- dimension_summary |>
    dplyr::group_by(domain) |>
    dplyr::summarize(
      domain_score = round(psych::geometric.mean(dimension_score, na.rm = TRUE), 2),
      .groups = "drop"
    )

  # Join back to original data
  dynamics_df <- dynamics_df |>
    dplyr::left_join(domain_scores, by = "domain")

  # ==========================================================================
  # PREPARE OUTPUTS
  # ==========================================================================

  # Domain DF for Visualization
  # Factors ordered by appearance or standard sort
  domain_df <- dynamics_df |>
    dplyr::distinct(domain, .keep_all = TRUE) |>
    dplyr::select(domain, domain_score) |>
    dplyr::mutate(domain = factor(domain, levels = unique(domain), ordered = TRUE))

  # Balance Score (Gini)
  # Uses helper function calculate_gini
  dynamics_score <- calculate_gini(domain_df$domain_score)

  # ==========================================================================
  # RETURN OBJECT
  # ==========================================================================
  result <- list(
    dynamics_df = dynamics_df,
    domain_df = domain_df,
    dynamics_score = dynamics_score
  )

  class(result) <- "dynamics_analysis"
  return(result)
}
