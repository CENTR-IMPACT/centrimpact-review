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

#' Generate Cascade Data
#'
#' @description
#' Generates synthetic network data to simulate a multi-layered network
#' showing how impact diffuses from primary agents (Layer 1) to secondary (Layer 2) and tertiary (Layer 3) actors.
#'
#' @details
#' This function constructs a directed graph structure (represented as an edge list) with three distinct layers.
#' It uses an optimized, vectorized approach to generate connections based on probabilistic rules defined
#' in the CEnTR*IMPACT framework.
#'
#' \strong{Network Logic:}
#' \itemize{
#'   \item \strong{Layer 1:} A fully connected clique of primary agents (3-10 nodes).
#'   \item \strong{Layer 2:} Children of Layer 1 (1-3 children per parent). 36% chance of internal connections.
#'   \item \strong{Layer 3:} Children of Layer 2 (parents selected with 72% probability). 10% chance of internal connections.
#' }
#'
#' @param seed Integer or POSIXct. The seed for random number generation. Defaults to \code{Sys.time()}.
#'
#' @return A data frame representing the edge list with columns: \code{from}, \code{to}, and \code{layer}.
#'
#' @references
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation} (CUMU-Collaboratory Fellowship Report). Coalition of Urban and Metropolitan Universities.
#'
#' @export
generate_cascade_data <- function(seed = Sys.time()) {
  set.seed(as.integer(seed))

  # --- Helper Function: Internal Connections ---
  # vectorizes the logic for connecting agents within the same layer
  get_internal_edges <- function(ids, max_pct, layer_val) {
    n <- length(ids)
    if (n < 2) return(NULL)

    # Total possible unique pairs
    max_possible <- (n * (n - 1)) / 2

    # Calculate limit based on percentage
    limit <- floor(max_possible * max_pct)

    # Sample how many connections we will actually make
    n_edges <- sample(0:limit, 1)

    if (n_edges == 0) return(NULL)

    # Generate all pairs (combn output is always sorted: row1 < row2)
    pairs <- combn(ids, 2)

    # Sample specific columns from the pairs matrix
    selected_idx <- sample(ncol(pairs), n_edges)

    data.frame(
      from = pairs[1, selected_idx],
      to   = pairs[2, selected_idx],
      layer = layer_val
    )
  }

  # --- Layer 1 Generation ---
  n_l1 <- sample(3:10, 1)
  ids_l1 <- 1:n_l1
  last_id <- n_l1

  # Layer 1 Internal: Connect all (Clique)
  pairs_l1 <- combn(ids_l1, 2)
  edges_l1_int <- data.frame(from = pairs_l1[1,], to = pairs_l1[2,], layer = 1)

  # --- Layer 2 Generation ---
  # Vectorized: Determine children count for ALL L1 agents at once
  n_children_l1 <- sample(1:3, n_l1, replace = TRUE)
  n_l2 <- sum(n_children_l1)

  # Assign IDs
  ids_l2 <- (last_id + 1):(last_id + n_l2)
  last_id <- last_id + n_l2

  # Vertical Connections (L1 -> L2)
  # rep(ids_l1, n_children_l1) repeats the parent ID for each of its children
  edges_l1_l2 <- data.frame(
    from  = rep(ids_l1, n_children_l1),
    to    = ids_l2,
    layer = 2
  )

  # Layer 2 Internal (36% limit)
  edges_l2_int <- get_internal_edges(ids_l2, 0.36, 2)

  # --- Layer 3 Generation ---
  # Vectorized: Filter parents (72% chance)
  # We create a boolean mask for all L2 agents
  is_parent <- runif(n_l2) <= 0.72
  parents_l2 <- ids_l2[is_parent]

  edges_l2_l3 <- NULL
  edges_l3_int <- NULL

  if (length(parents_l2) > 0) {
    # Determine children for the surviving parents
    n_children_l2 <- sample(1:3, length(parents_l2), replace = TRUE)
    n_l3 <- sum(n_children_l2)

    ids_l3 <- (last_id + 1):(last_id + n_l3)

    # Vertical Connections (L2 -> L3)
    edges_l2_l3 <- data.frame(
      from  = rep(parents_l2, n_children_l2),
      to    = ids_l3,
      layer = 3
    )

    # Layer 3 Internal (10% limit)
    edges_l3_int <- get_internal_edges(ids_l3, 0.10, 3)
  }

  # --- Final Assembly ---
  final_df <- rbind(edges_l1_int, edges_l1_l2, edges_l2_int, edges_l2_l3, edges_l3_int)

  return(final_df)
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
