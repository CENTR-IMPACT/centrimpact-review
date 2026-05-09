# ==============================================================================
# test-analyze_cascade.R
# Tests for build_network(), calculate_cascade(), and analyze_cascade()
# ==============================================================================

# ── build_network() ───────────────────────────────────────────────────────────

test_that("build_network returns a data frame with correct columns", {
  net <- build_network(cascade_params)
  expect_s3_class(net, "data.frame")
  expect_named(net, c("from", "to", "layer"))
})

test_that("build_network layer values are only 1, 2, or 3", {
  net <- build_network(cascade_params)
  expect_true(all(net$layer %in% 1:3))
})

test_that("build_network has no self-loops", {
  net <- build_network(cascade_params)
  expect_true(all(net$from != net$to))
})

test_that("build_network has no duplicate edges", {
  net <- build_network(cascade_params)
  dupes <- duplicated(net[, c("from", "to")])
  expect_false(any(dupes))
})

test_that("build_network Layer 1 forms a complete clique", {
  net <- build_network(cascade_params)
  n_l1 <- cascade_params$cascade_d1_people_1_1 +
    cascade_params$cascade_d1_people_2_1
  l1_edges <- net[net$layer == 1L, ]
  expect_equal(nrow(l1_edges), choose(n_l1, 2))
})

test_that("build_network all node IDs are positive integers", {
  net <- build_network(cascade_params)
  expect_true(all(net$from > 0))
  expect_true(all(net$to > 0))
})

test_that("build_network accepts a named list and returns same columns as data frame", {
  # Probabilistic edges (back-edges, cross-connections) differ between calls
  # because the RNG advances between the two build_network() invocations.
  # We only compare the deterministic Layer 1 clique, and verify column names.
  as_list  <- as.list(cascade_params)
  net_df   <- build_network(cascade_params)
  net_list <- build_network(as_list)
  # Column names must be identical regardless of input type
  expect_named(net_list, c("from", "to", "layer"))
  # L1 clique is deterministic: same params -> same edges
  l1_df   <- net_df[net_df$layer == 1L, ]
  l1_list <- net_list[net_list$layer == 1L, ]
  expect_equal(l1_df, l1_list)
})


# ── calculate_cascade() ───────────────────────────────────────────────────────

test_that("calculate_cascade returns an object of class cascade_analysis", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  expect_s3_class(result, "cascade_analysis")
})

test_that("calculate_cascade result has required list elements", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  expect_true(all(c("summary", "node_data", "cascade_score", "topology_score") %in%
                    names(result)))
})

test_that("calculate_cascade cascade_score is a scalar in [0, 1]", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  expect_length(result$cascade_score, 1L)
  expect_gte(result$cascade_score, 0)
  expect_lte(result$cascade_score, 1)
})

test_that("calculate_cascade topology_score is a finite non-negative scalar", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  expect_length(result$topology_score, 1L)
  expect_true(is.finite(result$topology_score))
  expect_gte(result$topology_score, 0)
})

test_that("calculate_cascade summary has one row per layer (1-3)", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  expect_equal(nrow(result$summary), 3L)
  expect_equal(sort(result$summary$layer), 1:3)
})

test_that("calculate_cascade summary has expected score columns", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  score_cols <- c("layer_knitting", "layer_bridging",
                  "layer_channeling", "layer_reaching", "layer_score")
  expect_true(all(score_cols %in% names(result$summary)))
})

test_that("calculate_cascade node-level role scores are in [0, 1]", {
  net <- build_network(cascade_params)
  result <- calculate_cascade(net)
  role_cols <- c("knitting", "bridging", "channeling", "reaching")
  for (col in role_cols) {
    vals <- result$node_data[[col]]
    expect_true(all(vals >= 0 & vals <= 1, na.rm = TRUE), info = col)
  }
})

test_that("calculate_cascade errors on missing required columns", {
  bad <- data.frame(from = 1:3, to = 2:4)   # missing 'layer'
  expect_error(calculate_cascade(bad), regexp = "layer")
})


# ── analyze_cascade() ─────────────────────────────────────────────────────────

test_that("analyze_cascade returns cascade_analysis class", {
  expect_s3_class(cascade_result, "cascade_analysis")
})

test_that("analyze_cascade result contains all expected elements", {
  expected <- c("summary", "node_data", "cascade_score",
                "mode", "estimated_edges", "scale_used", "n_runs")
  # Note: summary_sd is NULL in full mode and therefore absent from the list;
  # it is only present in scaled mode results.
  expect_true(all(expected %in% names(cascade_result)))
})

test_that("analyze_cascade cascade_score is a scalar in [0, 1]", {
  score <- cascade_result$cascade_score
  expect_length(score, 1L)
  expect_gte(score, 0)
  expect_lte(score, 1)
})

test_that("analyze_cascade full mode sets mode = 'full' and scale_used = 1", {
  result <- analyze_cascade(cascade_params, seed = 1)
  expect_equal(result$mode, "full")
  expect_equal(result$scale_used, 1)
  expect_equal(result$n_runs, 1L)
  expect_null(result$summary_sd)
})

test_that("analyze_cascade scaled mode works and returns averaged results", {
  result <- analyze_cascade(cascade_params, seed = 1,
                             always_scale = TRUE, n_runs = 3)
  expect_equal(result$mode, "scaled")
  expect_equal(result$n_runs, 3L)
  expect_false(is.null(result$summary_sd))
})

test_that("analyze_cascade keep_runs attaches run_results", {
  result <- analyze_cascade(cascade_params, seed = 1,
                             always_scale = TRUE, n_runs = 2,
                             keep_runs = TRUE)
  expect_true("run_results" %in% names(result))
  expect_length(result$run_results, 2L)
})

test_that("analyze_cascade warns on multi-row input and uses first row", {
  multi_row <- rbind(cascade_params, cascade_params)
  expect_warning(
    analyze_cascade(multi_row, seed = 1),
    regexp = "2 rows"
  )
})

test_that("analyze_cascade gives same cascade_score for single-row and extracted first row", {
  multi_row <- rbind(cascade_params, cascade_params)
  result_single <- analyze_cascade(cascade_params, seed = 1)
  result_multi  <- suppressWarnings(analyze_cascade(multi_row, seed = 1))
  expect_equal(result_single$cascade_score, result_multi$cascade_score)
})

test_that("analyze_cascade is reproducible with same seed", {
  r1 <- analyze_cascade(cascade_params, seed = 123)
  r2 <- analyze_cascade(cascade_params, seed = 123)
  expect_equal(r1$cascade_score, r2$cascade_score)
})


# ── utils: calculate_gini() ───────────────────────────────────────────────────

test_that("calculate_gini returns 1 for perfectly equal values", {
  expect_equal(calculate_gini(c(1, 1, 1, 1)), 1)
})

test_that("calculate_gini returns lower values for more unequal distributions", {
  balanced   <- calculate_gini(c(1, 1, 1, 1))
  unbalanced <- calculate_gini(c(10, 1, 1, 1))
  expect_gt(balanced, unbalanced)
})

test_that("calculate_gini result is in [0, 1]", {
  result <- calculate_gini(c(5, 10, 20, 1))
  expect_gte(result, 0)
  expect_lte(result, 1)
})

test_that("calculate_gini handles all-zero vector", {
  expect_equal(calculate_gini(c(0, 0, 0)), 1)
})

test_that("calculate_gini ignores NA values", {
  with_na    <- calculate_gini(c(1, 1, NA, 1))
  without_na <- calculate_gini(c(1, 1, 1))
  expect_equal(with_na, without_na)
})


# ── utils: normalize() ────────────────────────────────────────────────────────

test_that("normalize scales to [0, 1]", {
  out <- normalize(c(10, 20, 30, 40, 50))
  expect_equal(min(out), 0)
  expect_equal(max(out), 1)
})

test_that("normalize returns zeros for constant input", {
  out <- normalize(c(5, 5, 5))
  expect_true(all(out == 0))
})

test_that("normalize preserves vector length", {
  x <- c(3, 1, 4, 1, 5, 9)
  expect_length(normalize(x), length(x))
})

test_that("calculate_gini returns 0 for all-NA input", {
  expect_equal(calculate_gini(c(NA, NA, NA)), 0)
})

test_that("calculate_gini returns 0 for all-negative input", {
  expect_equal(calculate_gini(c(-1, -2, -3)), 0)
})
