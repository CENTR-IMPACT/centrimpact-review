# ==============================================================================
# test-generate_data.R
# Tests for generate_alignment_data(), generate_cascade_data(),
# generate_dynamics_data(), and generate_indicators_data()
# ==============================================================================

# ── generate_cascade_data() ───────────────────────────────────────────────────

test_that("generate_cascade_data returns a one-row data frame", {
  out <- generate_cascade_data(seed = 1)
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 1L)
})

test_that("generate_cascade_data has correct column names", {
  out <- generate_cascade_data(seed = 1)
  expect_named(out, c(
    "cascade_d1_people_1_1", "cascade_d1_people_2_1",
    "cascade_d2_people_1_1", "cascade_d2_people_2_1",
    "cascade_d2_stats_1",    "cascade_d2_stats_2",
    "cascade_d3_people",
    "cascade_d3_stats_1",    "cascade_d3_stats_2"
  ))
})

test_that("generate_cascade_data people counts are positive integers >= 1", {
  out <- generate_cascade_data(seed = 1)
  count_cols <- c(
    "cascade_d1_people_1_1", "cascade_d1_people_2_1",
    "cascade_d2_people_1_1", "cascade_d2_people_2_1",
    "cascade_d3_people"
  )
  for (col in count_cols) {
    expect_true(out[[col]] >= 1L, info = col)
    expect_true(out[[col]] == as.integer(out[[col]]), info = col)
  }
})

test_that("generate_cascade_data probability columns are in [0, 1]", {
  out <- generate_cascade_data(seed = 1)
  prob_cols <- c(
    "cascade_d2_stats_1", "cascade_d2_stats_2",
    "cascade_d3_stats_1", "cascade_d3_stats_2"
  )
  for (col in prob_cols) {
    expect_gte(out[[col]], 0, label = col)
    expect_lte(out[[col]], 1, label = col)
  }
})

test_that("generate_cascade_data is reproducible with same seed", {
  expect_identical(
    generate_cascade_data(seed = 7),
    generate_cascade_data(seed = 7)
  )
})

test_that("generate_cascade_data differs across seeds", {
  a <- generate_cascade_data(seed = 1)
  b <- generate_cascade_data(seed = 2)
  expect_false(identical(a, b))
})


# ── generate_alignment_data() ─────────────────────────────────────────────────

test_that("generate_alignment_data returns a data frame with correct columns", {
  out <- generate_alignment_data(seed = 1)
  expect_s3_class(out, "data.frame")
  expect_named(out, c("alignment", "role", "rating"))
})

test_that("generate_alignment_data has exactly 8 alignment categories", {
  out <- generate_alignment_data(seed = 1)
  expect_equal(length(unique(out$alignment)), 8L)
})

test_that("generate_alignment_data roles are only researcher and partner", {
  out <- generate_alignment_data(seed = 1)
  expect_setequal(unique(out$role), c("researcher", "partner"))
})

test_that("generate_alignment_data ratings are in [0.36, 1]", {
  out <- generate_alignment_data(seed = 1)
  expect_true(all(out$rating >= 0.36))
  expect_true(all(out$rating <= 1.00))
})

test_that("generate_alignment_data is reproducible with same seed", {
  expect_identical(
    generate_alignment_data(seed = 99),
    generate_alignment_data(seed = 99)
  )
})


# ── generate_dynamics_data() ──────────────────────────────────────────────────

test_that("generate_dynamics_data returns a data frame with correct columns", {
  out <- generate_dynamics_data(seed = 1)
  expect_s3_class(out, "data.frame")
  expect_named(out, c("domain", "dimension", "salience", "weight"))
})

test_that("generate_dynamics_data has 5 domains", {
  out <- generate_dynamics_data(seed = 1)
  expect_equal(
    sort(unique(out$domain)),
    sort(c("Contexts", "Partnerships", "Research", "Learning", "Outcomes"))
  )
})

test_that("generate_dynamics_data salience values are from expected set", {
  out <- generate_dynamics_data(seed = 1)
  valid_salience <- c(1, 0.8, 0.6, 0.4, 0.2)
  expect_true(all(out$salience %in% valid_salience))
})

test_that("generate_dynamics_data weight values are in expected range", {
  out <- generate_dynamics_data(seed = 1, na_prob = 0)
  expect_true(all(out$weight >= 0.78 & out$weight <= 1.00))
})

test_that("generate_dynamics_data respects na_prob = 0", {
  out <- generate_dynamics_data(seed = 1, na_prob = 0)
  expect_false(any(is.na(out$weight)))
})

test_that("generate_dynamics_data exclude removes domains", {
  out <- generate_dynamics_data(seed = 1, exclude = "Contexts")
  expect_false("Contexts" %in% out$domain)
  expect_true("Partnerships" %in% out$domain)
})

test_that("generate_dynamics_data warns on unknown exclude domain", {
  expect_warning(
    generate_dynamics_data(seed = 1, exclude = "NotADomain"),
    regexp = "not found"
  )
})

test_that("generate_dynamics_data custom weight_set is respected", {
  out <- generate_dynamics_data(seed = 1, na_prob = 0, weight_set = c(0.1, 0.5, 0.9))
  expect_true(all(out$weight %in% c(0.1, 0.5, 0.9)))
})

test_that("generate_dynamics_data is reproducible with same seed", {
  expect_identical(
    generate_dynamics_data(seed = 55),
    generate_dynamics_data(seed = 55)
  )
})


# ── generate_indicators_data() ────────────────────────────────────────────────

test_that("generate_indicators_data returns a data frame with correct columns", {
  out <- generate_indicators_data(seed = 1)
  expect_s3_class(out, "data.frame")
  expect_named(out, c("indicator", "value"))
})

test_that("generate_indicators_data has 7 indicators", {
  out <- generate_indicators_data(seed = 1)
  expect_equal(nrow(out), 7L)
})

test_that("generate_indicators_data values are non-negative integers", {
  out <- generate_indicators_data(seed = 1)
  expect_true(all(out$value >= 0))
  expect_true(all(out$value == as.integer(out$value)))
})

test_that("generate_indicators_data is reproducible with same seed", {
  expect_identical(
    generate_indicators_data(seed = 3),
    generate_indicators_data(seed = 3)
  )
})
