# ==============================================================================
# test-analyze_dynamics.R
# Tests for analyze_dynamics()
# ==============================================================================

# ── Output contract ───────────────────────────────────────────────────────────

test_that("analyze_dynamics returns an object of class dynamics_analysis", {
  expect_s3_class(dynamics_result, "dynamics_analysis")
})

test_that("analyze_dynamics result has all required elements", {
  expect_true(all(
    c("dynamics_df", "domain_df", "dynamics_score") %in% names(dynamics_result)
  ))
})

test_that("dynamics_score is a single finite numeric in [0, 1]", {
  score <- dynamics_result$dynamics_score
  expect_length(score, 1L)
  expect_true(is.numeric(score))
  expect_true(is.finite(score))
  expect_gte(score, 0)
  expect_lte(score, 1)
})

# ── dynamics_df ───────────────────────────────────────────────────────────────

test_that("dynamics_df retains input columns plus dimension_score and domain_score", {
  df <- dynamics_result$dynamics_df
  expect_true(all(c("domain", "dimension", "salience", "weight",
                    "dimension_value", "dimension_score", "domain_score") %in%
                    names(df)))
})

test_that("dynamics_df dimension_score values are in (0, 1]", {
  scores <- dynamics_result$dynamics_df$dimension_score
  expect_true(all(scores > 0 & scores <= 1, na.rm = TRUE))
})

# ── domain_df ─────────────────────────────────────────────────────────────────

test_that("domain_df has one row per domain", {
  n_domains <- length(unique(dynamics_data$domain))
  expect_equal(nrow(dynamics_result$domain_df), n_domains)
})

test_that("domain_df has domain and domain_score columns", {
  expect_true(all(c("domain", "domain_score") %in%
                    names(dynamics_result$domain_df)))
})

test_that("domain_df domain_score values are in (0, 1]", {
  scores <- dynamics_result$domain_df$domain_score
  expect_true(all(scores > 0 & scores <= 1, na.rm = TRUE))
})

# ── Input validation ──────────────────────────────────────────────────────────

test_that("analyze_dynamics errors when input is not a data frame", {
  expect_error(analyze_dynamics(list(a = 1)), regexp = "data frame")
})

test_that("analyze_dynamics errors on missing required columns", {
  bad <- data.frame(domain = "X", dimension = "Y", salience = 0.5)  # no weight
  expect_error(analyze_dynamics(bad), regexp = "weight")
})

test_that("analyze_dynamics errors on empty data frame", {
  empty <- dynamics_data[0, ]
  expect_error(analyze_dynamics(empty), regexp = "one row")
})

test_that("analyze_dynamics errors when weight is out of (0, 1] range", {
  bad <- dynamics_data
  bad$weight[1] <- 0   # exactly zero — not allowed
  expect_error(analyze_dynamics(bad), regexp = "weight")
})

test_that("analyze_dynamics errors when salience is out of (0, 1] range", {
  bad <- dynamics_data
  bad$salience[1] <- 1.5
  expect_error(analyze_dynamics(bad), regexp = "salience")
})

test_that("analyze_dynamics drops rows with NA domain silently", {
  with_na_domain <- dynamics_data
  with_na_domain$domain[1] <- NA
  result <- analyze_dynamics(with_na_domain)
  expect_s3_class(result, "dynamics_analysis")
})

# ── Behaviour ─────────────────────────────────────────────────────────────────

test_that("analyze_dynamics gives higher score for balanced domain weights", {
  # All domains equal -> high balance
  balanced <- generate_dynamics_data(seed = 1, na_prob = 0,
                                     weight_set = c(0.9))
  # Extreme variance -> lower balance
  unbalanced <- generate_dynamics_data(seed = 1, na_prob = 0,
                                       domain_variance = TRUE)
  r_bal   <- analyze_dynamics(balanced)
  r_unbal <- analyze_dynamics(unbalanced)
  expect_gte(r_bal$dynamics_score, r_unbal$dynamics_score)
})

test_that("analyze_dynamics handles a single domain without error", {
  one_domain <- dynamics_data[dynamics_data$domain == "Contexts", ]
  result <- analyze_dynamics(one_domain)
  expect_s3_class(result, "dynamics_analysis")
  expect_equal(nrow(result$domain_df), 1L)
})

test_that("analyze_dynamics handles NA weights without error", {
  with_na <- dynamics_data
  with_na$weight[sample(nrow(with_na), 5)] <- NA
  result <- analyze_dynamics(with_na)
  expect_s3_class(result, "dynamics_analysis")
})

test_that("analyze_dynamics is deterministic (no randomness)", {
  r1 <- analyze_dynamics(dynamics_data)
  r2 <- analyze_dynamics(dynamics_data)
  expect_equal(r1$dynamics_score, r2$dynamics_score)
})
