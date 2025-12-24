# ==============================================================================
# MATHEMATICAL AND STATISTICAL UTILITY FUNCTIONS
# ==============================================================================
# Core mathematical functions for data transformation, scaling, and
# statistical calculations used throughout the analysis pipeline.

#' Normalize a numeric vector to 0-1 range
#'
#' @description
#' Performs min-max normalization to scale values between 0 and 1.
#' This is useful for standardizing different metrics to a common scale.
#'
#' @param x Numeric vector. Values to normalize.
#'
#' @return Numeric vector. Normalized values between 0 and 1.
#'
#' @details Uses the formula: (x - min(x)) / (max(x) - min(x))
#'
#' @examples
#' normalize(c(10, 20, 30, 40, 50))
#' # Returns: c(0.0, 0.25, 0.5, 0.75, 1.0)
#'
#' @noRd
normalize <- function(x) {
  x_min <- min(x, na.rm = TRUE)
  x_max <- max(x, na.rm = TRUE)

  # Handle edge case where all values are identical
  if (x_min == x_max) {
    return(rep(0, length(x)))
  }

  (x - x_min) / (x_max - x_min)
}

#' Calculate the Gini-Simpson diversity index (balance score)
#'
#' @description
#' The Gini-Simpson index measures the diversity of values in a distribution.
#' Higher values indicate more balanced distributions. In the CEnTR*IMPACT
#' framework, higher balance scores indicate more equitable development.
#'
#' @param category_values Numeric vector. Values to calculate diversity for.
#'
#' @return Numeric. Balance score between 0 and 1.
#'
#' @details
#' The Gini coefficient measures inequality (0 = perfect equality,
#' 1 = maximum inequality). By subtracting from 1, we get a "balance" measure:
#' - 0 = completely unbalanced
#' - 1 = perfectly balanced
#'
#' @examples
#' calculate_gini(c(25, 25, 25, 25)) # Returns ~1.00 (balanced)
#' calculate_gini(c(90, 5, 3, 2))    # Returns ~0.38 (unbalanced)
#'
#' @noRd
calculate_gini <- function(category_values) {
  # Remove NA values and ensure positive values
  values <- category_values[!is.na(category_values) & category_values >= 0]

  if (length(values) == 0) {
    return(0)
  }

  # Sort values for Gini calculation
  values <- sort(values)
  n <- length(values)

  # Calculate Gini coefficient
  # Formula: G = (2 * sum(i * values[i])) / (n * sum(values)) - (n + 1) / n
  cumsum_values <- sum(seq_len(n) * values)
  total_values <- sum(values)

  if (total_values == 0) {
    return(1) # Perfect equality when all values are zero
  }

  gini <- (2 * cumsum_values) / (n * total_values) - (n + 1) / n
  gini <- max(0, min(1, gini)) # Constrain to [0, 1]

  # Return balance score (1 - Gini)
  1 - gini
}

# 2. Helper function to generate non-repeating blocks
# This function repeats the sampling process 'n_groups' times.
# Because replace=FALSE, numbers within a single group will never repeat.
#' @noRd
get_random_sets <- function(source_set, group_size, n_groups) {
  # replicate creates a matrix, as.vector flattens it into a single column
  as.vector(replicate(n_groups, sample(source_set, size = group_size, replace = FALSE)))
}
