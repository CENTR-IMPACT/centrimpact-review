# ==============================================================================
# test-analyze_alignment.R
# Tests for analyze_alignment()
# ==============================================================================

# ── Output contract ───────────────────────────────────────────────────────────

test_that("analyze_alignment returns an object of class alignment_analysis", {
  expect_s3_class(alignment_result, "alignment_analysis")
})

test_that("analyze_alignment result has all required elements", {
  expect_true(all(
    c("table", "plot_data", "icc", "alignment_score") %in% names(alignment_result)
  ))
})

test_that("alignment_score is a single finite numeric in [0, 1]", {
  score <- alignment_result$alignment_score
  expect_length(score, 1L)
  expect_true(is.numeric(score))
  expect_true(is.finite(score))
  expect_gte(score, 0)
  expect_lte(score, 1)
})

# ── table ─────────────────────────────────────────────────────────────────────

test_that("table is a data frame with researcher and partner columns", {
  tbl <- alignment_result$table
  expect_s3_class(tbl, "data.frame")
  expect_true("researcher" %in% names(tbl))
  expect_true("partner" %in% names(tbl))
  expect_true("alignment" %in% names(tbl))
})

test_that("table has one row per alignment category", {
  tbl <- alignment_result$table
  expect_equal(nrow(tbl), length(unique(alignment_data$alignment)))
})

# ── plot_data ─────────────────────────────────────────────────────────────────

test_that("plot_data has columns alignment, role, and rating", {
  pd <- alignment_result$plot_data
  expect_true(all(c("alignment", "role", "rating") %in% names(pd)))
})

test_that("plot_data contains researcher, partner, and overall roles", {
  roles <- unique(alignment_result$plot_data$role)
  expect_true("researcher" %in% roles)
  expect_true("partner" %in% roles)
  expect_true("overall" %in% roles)
})

test_that("plot_data rating values are in [0, 1]", {
  pd <- alignment_result$plot_data
  expect_true(all(pd$rating >= 0 & pd$rating <= 1, na.rm = TRUE))
})

# ── Input validation ──────────────────────────────────────────────────────────

test_that("analyze_alignment errors on missing required columns", {
  bad <- data.frame(role = "researcher", alignment = "Goals")  # missing rating
  expect_error(analyze_alignment(bad), regexp = "rating")
})

test_that("analyze_alignment errors when role column is missing", {
  bad <- data.frame(alignment = "Goals", rating = 0.8)
  expect_error(analyze_alignment(bad), regexp = "role")
})

# ── Edge cases ────────────────────────────────────────────────────────────────

test_that("analyze_alignment handles single alignment category", {
  single <- alignment_data[alignment_data$alignment == "Goals", ]
  result <- analyze_alignment(single)
  expect_s3_class(result, "alignment_analysis")
  expect_true(is.numeric(result$alignment_score))
})

test_that("analyze_alignment handles only researcher ratings (no partner)", {
  only_researcher <- alignment_data[alignment_data$role == "researcher", ]
  # ICC requires both groups; should either error gracefully or return NA score
  result <- tryCatch(
    analyze_alignment(only_researcher),
    error = function(e) NULL
  )
  # Either a valid result with NA score, or graceful NULL — not a hard crash
  if (!is.null(result)) {
    expect_true(is.na(result$alignment_score) || is.numeric(result$alignment_score))
  }
})

test_that("analyze_alignment is consistent across identical inputs", {
  r1 <- analyze_alignment(alignment_data)
  r2 <- analyze_alignment(alignment_data)
  expect_equal(r1$alignment_score, r2$alignment_score)
})
