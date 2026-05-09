# ==============================================================================
# test-visualize.R
# Smoke tests for visualize_cascade(), visualize_alignment(),
# visualize_abacus(), visualize_dynamics(), and visualize_indicators()
#
# Strategy: visualizations are hard to test for correctness, so we focus on:
#   1. Return type (ggplot object)
#   2. No error on valid input
#   3. Informative error on invalid input
#   4. Optional parameters are accepted without error
# ==============================================================================

# ── visualize_cascade() ───────────────────────────────────────────────────────

test_that("visualize_cascade returns a ggplot object", {
  p <- visualize_cascade(cascade_result)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_cascade accepts custom project_title", {
  p <- visualize_cascade(cascade_result, project_title = "My Project")
  expect_s3_class(p, "ggplot")
})

test_that("visualize_cascade accepts custom score_label_color", {
  p <- visualize_cascade(cascade_result, score_label_color = "black")
  expect_s3_class(p, "ggplot")
})

test_that("visualize_cascade errors on non-cascade_analysis input", {
  expect_error(
    visualize_cascade(list(a = 1)),
    regexp = "cascade_analysis"
  )
})

test_that("visualize_cascade returns NULL with warning on empty summary", {
  empty_result <- cascade_result
  empty_result$summary <- data.frame()
  expect_warning(out <- visualize_cascade(empty_result))
  expect_null(out)
})


# ── visualize_alignment() ─────────────────────────────────────────────────────

test_that("visualize_alignment returns a ggplot object", {
  p <- visualize_alignment(alignment_result)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_alignment accepts custom project_title", {
  p <- visualize_alignment(alignment_result, project_title = "Year 1")
  expect_s3_class(p, "ggplot")
})

test_that("visualize_alignment accepts a custom color_palette", {
  factors <- unique(alignment_data$alignment)
  pal <- setNames(rep("#FF0000", length(factors)), factors)
  p <- visualize_alignment(alignment_result, color_palette = pal)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_alignment errors on non-alignment_analysis input", {
  expect_error(
    visualize_alignment(list(a = 1)),
    regexp = "alignment_analysis"
  )
})


# ── visualize_abacus() ────────────────────────────────────────────────────────

test_that("visualize_abacus returns a ggplot object", {
  p <- visualize_abacus(alignment_result)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_abacus accepts custom project_title", {
  p <- visualize_abacus(alignment_result, project_title = "Abacus View")
  expect_s3_class(p, "ggplot")
})

test_that("visualize_abacus errors on non-alignment_analysis input", {
  expect_error(
    visualize_abacus(list(a = 1)),
    regexp = "alignment_analysis"
  )
})


# ── visualize_dynamics() ──────────────────────────────────────────────────────

test_that("visualize_dynamics returns a ggplot object", {
  p <- visualize_dynamics(dynamics_result)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_dynamics accepts custom project_title", {
  p <- visualize_dynamics(dynamics_result, project_title = "Dynamics View")
  expect_s3_class(p, "ggplot")
})

test_that("visualize_dynamics errors on non-dynamics_analysis input", {
  expect_error(
    visualize_dynamics(list(a = 1)),
    regexp = "dynamics_analysis"
  )
})


# ── visualize_indicators() ────────────────────────────────────────────────────

test_that("visualize_indicators returns a ggplot object with data", {
  p <- visualize_indicators(indicators_data)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_indicators works with NULL input (uses internal demo data)", {
  p <- visualize_indicators(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("visualize_indicators accepts custom project_title", {
  p <- visualize_indicators(indicators_data, project_title = "My Indicators")
  expect_s3_class(p, "ggplot")
})
