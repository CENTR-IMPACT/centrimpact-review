#' Generate Alignment Data
#'
#' @description
#' Generates synthetic data to simulate "Alignment"—the degree of agreement between different
#' stakeholders (Researchers and Partners) across key project areas.
#'
#' @details
#' This function simulates a survey response dataset where multiple participants (Researchers and Partners)
#' rate their agreement or alignment on various axes (Goals, Values, Roles, etc.).
#'
#' \strong{Logic:}
#' \itemize{
#'   \item Randomly selects a number of researchers (1-10) and partners (Researcher Count + 1 to 15).
#'   \item Generates alignment ratings (0.36 to 1.00) for 8 categories.
#'   \item Useful for visualizing gaps in understanding or expectation between stakeholder groups.
#' }
#'
#' @param seed Integer or POSIXct. The seed for random number generation. Defaults to \code{Sys.time()}.
#'
#' @return A data frame with columns: \code{alignment}, \code{role}, and \code{rating}.
#'
#' @references
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation} (CUMU-Collaboratory Fellowship Report). Coalition of Urban and Metropolitan Universities.
#'
#' @export
generate_alignment_data <- function(seed = Sys.time()) {

  set.seed(as.integer(seed))

  number_of_researchers <- sample(1:10, 1)
  number_of_partners <- sample((number_of_researchers + 1):15, 1)
  total_participants <- sum(number_of_researchers, number_of_partners)

  alignment_df <- data.frame(
    alignment = c(
      rep("Goals", total_participants),
      rep("Values", total_participants),
      rep("Roles", total_participants),
      rep("Resources", total_participants),
      rep("Activities", total_participants),
      rep("Empowerment", total_participants),
      rep("Outputs", total_participants),
      rep("Outcomes", total_participants)
    ),
    role = rep(rep(c("researcher", "partner"), times = c(number_of_researchers, number_of_partners)), times = 8),
    rating = round(runif((8 * total_participants), 0.36, 1), 2)
  )

  return(alignment_df)
}

#' Generate Cascade Survey Parameters
#'
#' @description
#' Generates a synthetic one-row data frame of cascade survey parameters,
#' suitable for passing directly to \code{analyze_cascade()}. The parameters
#' represent a plausible set of cascade network inputs: Layer 1 team size
#' (split into two types), Layer 2 reach per type, Layer 3 reach, and
#' probabilistic cross-connection rates for each layer.
#'
#' @details
#' The returned data frame has the same column schema as the \code{cascade}
#' sub-frame produced by \code{load_survey_data()}, so it can be used as a
#' drop-in replacement for testing and examples without needing a real survey
#' file.
#'
#' \strong{Parameter ranges:}
#' \itemize{
#'   \item \code{cascade_d1_people_1_1}: Layer 1 Type 1 count (2--6).
#'   \item \code{cascade_d1_people_2_1}: Layer 1 Type 2 count (2--6).
#'   \item \code{cascade_d2_people_1_1}: Layer 2 children per Type 1 parent (1--4).
#'   \item \code{cascade_d2_people_2_1}: Layer 2 children per Type 2 parent (1--4).
#'   \item \code{cascade_d2_stats_1}: L2-L2 cross-connection probability (0.05--0.40).
#'   \item \code{cascade_d2_stats_2}: L2->L1 back-edge probability (0.05--0.30).
#'   \item \code{cascade_d3_people}: Layer 3 children per Layer 2 parent (1--4).
#'   \item \code{cascade_d3_stats_1}: L3-L3 cross-connection probability (0.02--0.20).
#'   \item \code{cascade_d3_stats_2}: L3->L2 back-edge probability (0.02--0.20).
#' }
#'
#' @param seed Integer or POSIXct. The seed for random number generation.
#'   Defaults to \code{Sys.time()}.
#'
#' @return A one-row data frame with columns matching the \code{cascade_d*}
#'   survey schema consumed by \code{analyze_cascade()}.
#'
#' @seealso \code{\link{analyze_cascade}}, \code{\link{load_survey_data}}
#'
#' @references
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative
#' Research – Inclusive Measurement of Projects & Community Transformation}
#' (CUMU-Collaboratory Fellowship Report). Coalition of Urban and Metropolitan
#' Universities.
#'
#' @examples
#' params <- generate_cascade_data(seed = 42)
#' result <- analyze_cascade(params)
#' print(result$cascade_score)
#'
#' @export
generate_cascade_data <- function(seed = Sys.time()) {
  set.seed(as.integer(seed))

  data.frame(
    cascade_d1_people_1_1 = sample(2:6, 1),
    cascade_d1_people_2_1 = sample(2:6, 1),
    cascade_d2_people_1_1 = sample(1:4, 1),
    cascade_d2_people_2_1 = sample(1:4, 1),
    cascade_d2_stats_1    = round(runif(1, 0.05, 0.40), 2),
    cascade_d2_stats_2    = round(runif(1, 0.05, 0.30), 2),
    cascade_d3_people     = sample(1:4, 1),
    cascade_d3_stats_1    = round(runif(1, 0.02, 0.20), 2),
    cascade_d3_stats_2    = round(runif(1, 0.02, 0.20), 2)
  )
}

#' Generate Project Dynamics Data
#'
#' @description
#' Generates synthetic data to simulate the "Dynamics" of a collaborative project—specifically
#' its \strong{Developmental Balance}—as defined in the CEnTR*IMPACT framework (Price, 2024).
#'
#' @details
#' \strong{Controlling Variance:}
#' If \code{domain_variance = TRUE}, the function applies \strong{Hyper-Polarized Sampling}.
#' It forces each Domain to choose a "performance tier" (Low, High, or Mixed) with specific probabilities
#' (Low: 45%, High: 45%, Mixed: 10%).
#' \itemize{
#'   \item \strong{Low Tier:} Samples weights only from the bottom 2 values of the provided \code{weight_set}.
#'   \item \strong{High Tier:} Samples weights only from the top 2 values of the provided \code{weight_set}.
#' }
#' This maximizes the mathematical spread between domains, making it useful for testing
#' sensitivity or visualizing inequality in the Dynamics scoring.
#'
#' \strong{Schema Structure:}
#' The function uses a hardcoded schema representing the 5 core domains of the framework:
#' \itemize{
#'   \item Contexts (4 dimensions)
#'   \item Partnerships (4 dimensions)
#'   \item Research (5 dimensions)
#'   \item Learning (4 dimensions)
#'   \item Outcomes (4 dimensions)
#' }
#'
#' @param seed Integer or POSIXct. The seed for random number generation to ensure reproducibility. Defaults to \code{Sys.time()}.
#' @param exclude Character vector. A list of Domain names to exclude from the dataset (e.g., \code{c("Contexts")}).
#' @param na_prob Numeric. The probability (0 to 1) that a \code{weight} value will be replaced with \code{NA}. Defaults to 0.05.
#' @param weight_set Numeric vector. The pool of numbers from which weights are sampled. Defaults to \code{c(0.78, 0.84, 0.90, 0.95, 1.00)}.
#' @param domain_variance Logical. If \code{TRUE}, introduces strong bias per Domain to ensure their averages differ significantly. Defaults to \code{FALSE}.
#'
#' @return A data frame with columns:
#' \itemize{
#'   \item \code{domain}: The framework domain.
#'   \item \code{dimension}: The specific dimension within the domain.
#'   \item \code{salience}: A randomly assigned importance score (from 0.2 to 1.0).
#'   \item \code{weight}: A sampled intensity score based on the \code{weight_set}.
#' }
#'
#' @examples
#' # 1. Generate standard data
#' df_std <- generate_dynamics_data(seed = 123)
#'
#' # 2. Generate "Unbalanced" data (High Variance)
#' # This is useful for testing low Balance Scores (Sd)
#' df_var <- generate_dynamics_data(seed = 123, domain_variance = TRUE)
#'
#' # 3. Generate data with custom weights and no missing values
#' df_custom <- generate_dynamics_data(
#'   na_prob = 0,
#'   weight_set = c(0.1, 0.5, 0.9)
#' )
#'
#' @export
generate_dynamics_data <- function(seed = Sys.time(),
                                   exclude = NULL,
                                   na_prob = 0.05,
                                   weight_set = c(0.78, 0.84, 0.90, 0.95, 1.00),
                                   domain_variance = FALSE) {

  assigned_salience_set <- c(1, 0.8, 0.6, 0.4, 0.2)

  set.seed(as.integer(seed))

  get_random_block <- function(source_set, size, allow_replace) {
    sample(source_set, size = size, replace = allow_replace)
  }

  schema <- list(
    # Contexts
    list(domain = "Contexts", dimension = "Challenge", n = 5),
    list(domain = "Contexts", dimension = "Diversity", n = 5),
    list(domain = "Contexts", dimension = "Resources", n = 5),
    list(domain = "Contexts", dimension = "Trust", n = 5),

    # Partnerships
    list(domain = "Partnerships", dimension = "Beneficence", n = 5),
    list(domain = "Partnerships", dimension = "Decisions", n = 5),
    list(domain = "Partnerships", dimension = "Reflection", n = 5),
    list(domain = "Partnerships", dimension = "Tools", n = 5),

    # Research
    list(domain = "Research", dimension = "Design", n = 5),
    list(domain = "Research", dimension = "Duration", n = 5),
    list(domain = "Research", dimension = "Frequency", n = 5),
    list(domain = "Research", dimension = "Questions", n = 5),
    list(domain = "Research", dimension = "Voice", n = 5),

    # Learning
    list(domain = "Learning", dimension = "Civic Learning", n = 5),
    list(domain = "Learning", dimension = "Integration", n = 4),
    list(domain = "Learning", dimension = "Learning Goals", n = 5),
    list(domain = "Learning", dimension = "Reciprocity", n = 5),

    # Outcomes
    list(domain = "Outcomes", dimension = "Capabilities", n = 5),
    list(domain = "Outcomes", dimension = "Goals", n = 4),
    list(domain = "Outcomes", dimension = "Outputs", n = 5),
    list(domain = "Outcomes", dimension = "Sustainability", n = 5)
  )

  # 1. Handle Exclusion
  if (!is.null(exclude)) {
    valid_domains <- unique(sapply(schema, function(x) x$domain))
    if (any(!exclude %in% valid_domains)) warning("Excluded domain not found in schema.")
    schema <- Filter(function(x) !x$domain %in% exclude, schema)
  }

  if (length(schema) == 0) {
    return(data.frame(domain = character(), dimension = character(),
                      salience = numeric(), weight = numeric()))
  }

  # 2. Build Dataframe
  domain_col <- c()
  dimension_col <- c()
  salience_col <- c()
  weight_col <- c()

  current_domain <- ""
  local_weight_set <- weight_set

  # Ensure sorted so indexing works correctly
  weight_set <- sort(weight_set)
  n_weights <- length(weight_set)

  for (item in schema) {
    if (item$domain != current_domain) {
      current_domain <- item$domain

      if (domain_variance) {
        # HYPER-POLARIZED LOGIC
        # Force domains to extreme ends of the provided set.
        # 45% chance Low, 45% chance High, 10% chance Mixed.
        tier <- sample(c("low", "high", "mixed"), 1, prob = c(0.45, 0.45, 0.10))

        if (tier == "low") {
          # Bottom 2 weights only (e.g. 0.78, 0.84)
          # Uses min(2, ...) to ensure code doesn't break if set is small
          end_idx <- min(2, n_weights)
          local_weight_set <- weight_set[1:end_idx]
        } else if (tier == "high") {
          # Top 2 weights only (e.g. 0.95, 1.00)
          start_idx <- max(1, n_weights - 1)
          local_weight_set <- weight_set[start_idx:n_weights]
        } else {
          local_weight_set <- weight_set
        }
      } else {
        local_weight_set <- weight_set
      }
    }

    domain_col <- c(domain_col, rep(item$domain, item$n))
    dimension_col <- c(dimension_col, rep(item$dimension, item$n))
    salience_col <- c(salience_col, get_random_block(assigned_salience_set, item$n, allow_replace = FALSE))

    # Weight: Random Sample from the restricted local set
    weight_col <- c(weight_col, get_random_block(local_weight_set, item$n, allow_replace = TRUE))
  }

  dynamics_df <- data.frame(
    domain = domain_col,
    dimension = dimension_col,
    salience = salience_col,
    weight = weight_col
  )

  # 3. Handle NAs
  if (na_prob > 0) {
    weight_na_mask <- sample(c(TRUE, FALSE), nrow(dynamics_df), replace = TRUE, prob = c(na_prob, 1 - na_prob))
    dynamics_df$weight[weight_na_mask] <- NA
  }

  return(dynamics_df)
}

#' Generate Indicators Data
#'
#' @description
#' Generates synthetic data for project "Indicators"—quantitative metrics used to track
#' the outputs and reach of a collaborative project.
#'
#' @details
#' This function creates a simple dataframe of common impact metrics (e.g., "Community Partners",
#' "Students Involved") and assigns random integer values to them. This serves as input for
#' visualizing the scale or "reach" of a project.
#'
#' @param seed Integer or POSIXct. The seed for random number generation. Defaults to \code{Sys.time()}.
#'
#' @return A data frame with columns: \code{indicator} and \code{value}.
#'
#' @references
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation} (CUMU-Collaboratory Fellowship Report). Coalition of Urban and Metropolitan Universities.
#'
#' @export
generate_indicators_data <- function(seed = Sys.time()) {

  set.seed(as.integer(seed))

  indicators_df <- data.frame(
    indicator = c(
      "Community Partners", "Engagement Hours", "Individuals Served",
      "Infrastructure Tools", "Output Products", "Students Involved",
      "Successful Outcomes"
    )
  )
  indicators_df$value <- sample(0:30, nrow(indicators_df))

  return(indicators_df)
}
