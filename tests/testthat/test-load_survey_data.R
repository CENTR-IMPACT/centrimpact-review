# ==============================================================================
# test-load_survey_data.R
# Tests for load_survey_data()
#
# Both Qualtrics and Google Forms paths are fully tested.
#
# Google Forms: the 120-column google_names vector is reproduced verbatim from
# .translate_google_headers() so the test CSV passes the column-count check.
# If the real survey schema ever changes, update both places.
#
# withr::local_tempfile() handles temp file cleanup automatically.
# ==============================================================================


# ==============================================================================
# Shared: the 120 Google Forms column names (verbatim from .translate_google_headers)
# ==============================================================================

.google_names <- c(
  "indicators_partners", "indicators_hours", "indicators_served",
  "indicators_tools", "indicators_students", "indicators_outputs",
  "indicators_outcomes",
  # dynamics_selection is absent from Google Form; inserted as NA by loader
  "dynamics_c_challenge_1", "dynamics_c_challenge_2", "dynamics_c_challenge_3",
  "dynamics_c_challenge_4", "dynamics_c_challenge_5",
  "dynamics_c_diversity_1", "dynamics_c_diversity_2", "dynamics_c_diversity_3",
  "dynamics_c_diversity_4", "dynamics_c_diversity_5",
  "dynamics_c_resources_1", "dynamics_c_resources_2", "dynamics_c_resources_3",
  "dynamics_c_resources_4", "dynamics_c_resources_5",
  "dynamics_c_trust_1",     "dynamics_c_trust_2",     "dynamics_c_trust_3",
  "dynamics_c_trust_4",     "dynamics_c_trust_5",
  "dynamics_p_benef_1",    "dynamics_p_benef_2",    "dynamics_p_benef_3",
  "dynamics_p_benef_4",    "dynamics_p_benef_5",
  "dynamics_p_decision_1", "dynamics_p_decision_2", "dynamics_p_decision_3",
  "dynamics_p_decision_4", "dynamics_p_decision_5",
  "dynamics_p_reflect_1",  "dynamics_p_reflect_2",  "dynamics_p_reflect_3",
  "dynamics_p_reflect_4",  "dynamics_p_reflect_5",
  "dynamics_p_tool_1",     "dynamics_p_tool_2",     "dynamics_p_tool_3",
  "dynamics_p_tool_4",     "dynamics_p_tool_5",
  "dynamics_r_design_1",   "dynamics_r_design_2",   "dynamics_r_design_3",
  "dynamics_r_design_4",   "dynamics_r_design_5",
  "dynamics_r_duration_1", "dynamics_r_duration_2", "dynamics_r_duration_3",
  "dynamics_r_duration_4", "dynamics_r_duration_5",
  "dynamics_r_frequency_1","dynamics_r_frequency_2","dynamics_r_frequency_3",
  "dynamics_r_frequency_4","dynamics_r_frequency_5",
  "dynamics_r_questions_1","dynamics_r_questions_2","dynamics_r_questions_3",
  "dynamics_r_questions_4","dynamics_r_questions_5",
  "dynamics_r_voice_1",    "dynamics_r_voice_2",    "dynamics_r_voice_3",
  "dynamics_r_voice_4",    "dynamics_r_voice_5",
  "dynamics_l_civics_1",   "dynamics_l_civics_2",   "dynamics_l_civics_3",
  "dynamics_l_civics_4",   "dynamics_l_civics_5",
  "dynamics_l_integrate_1","dynamics_l_integrate_2","dynamics_l_integrate_3",
  "dynamics_l_integrate_4",                          # integrate stops at _4
  "dynamics_l_lrngls_1",   "dynamics_l_lrngls_2",   "dynamics_l_lrngls_3",
  "dynamics_l_lrngls_4",   "dynamics_l_lrngls_5",
  "dynamics_l_rcprcity_1", "dynamics_l_rcprcity_2", "dynamics_l_rcprcity_3",
  "dynamics_l_rcprcity_4", "dynamics_l_rcprcity_5",
  "dynamics_o_candc_1",    "dynamics_o_candc_2",    "dynamics_o_candc_3",
  "dynamics_o_candc_4",    "dynamics_o_candc_5",
  "dynamics_o_goals_1",    "dynamics_o_goals_2",    "dynamics_o_goals_3",
  "dynamics_o_goals_4",    "dynamics_o_goals_5",
  "dynamics_o_outputs_1",  "dynamics_o_outputs_2",  "dynamics_o_outputs_3",
  "dynamics_o_outputs_4",  "dynamics_o_outputs_5",
  "dynamics_o_sustain_1",  "dynamics_o_sustain_2",  "dynamics_o_sustain_3",
  "dynamics_o_sustain_4",  "dynamics_o_sustain_5",
  "cascade_d1_people_1_1", "cascade_d1_people_2_1",
  "cascade_d2_people_1_1", "cascade_d2_people_2_1",
  "cascade_d2_stats_1",    "cascade_d2_stats_2",
  "cascade_d3_people",
  "cascade_d3_stats_1",    "cascade_d3_stats_2"
)

stopifnot(length(.google_names) == 120L)  # guard: fail fast if schema drifts


# ==============================================================================
# Shared: cascade and indicator column sets used by both format helpers
# ==============================================================================

.cascade_cols <- c(
  "cascade_d1_people_1_1", "cascade_d1_people_2_1",
  "cascade_d2_people_1_1", "cascade_d2_people_2_1",
  "cascade_d2_stats_1",    "cascade_d2_stats_2",
  "cascade_d3_people",
  "cascade_d3_stats_1",    "cascade_d3_stats_2"
)

.cascade_vals <- c(3L, 2L, 2L, 1L, 0.3, 0.2, 2L, 0.1, 0.1)

.indicator_cols <- c(
  "indicators_partners", "indicators_hours", "indicators_served",
  "indicators_tools",    "indicators_students", "indicators_outputs",
  "indicators_outcomes"
)

.indicator_vals <- c(5L, 10L, 20L, 3L, 8L, 4L, 6L)


# ==============================================================================
# Helper: Google Forms main CSV (120 data columns + Timestamp)
# ==============================================================================
#
# Google Forms exports: one header row + one data row. No descriptor rows.
# Cascade probability fields use the 1-10 integer scale; the loader rescales
# them to [0, 1] by dividing by 10.

.make_google_main_csv <- function(path) {
  # Build values for all 120 columns in google_names order:
  #   7  indicators  -> integer counts
  #   104 dynamics   -> "Very High" (short Google Forms label)
  #   9  cascade     -> counts as integers, probabilities on 1-10 scale
  n_dyn <- sum(startsWith(.google_names, "dynamics"))   # 104
  n_ind <- sum(startsWith(.google_names, "indicators")) # 7

  # Cascade values on Google Forms scale (probabilities * 10)
  cascade_google <- .cascade_vals
  prob_idx <- grep("stats", .cascade_cols)              # indices 5,6,8,9
  cascade_google[prob_idx] <- cascade_google[prob_idx] * 10

  vals <- c(
    as.character(.indicator_vals),           # 7 indicator counts
    rep("Very High", n_dyn),                 # 104 dynamics ratings
    as.character(cascade_google)             # 9 cascade params
  )

  row <- as.data.frame(
    matrix(vals, nrow = 1L),
    stringsAsFactors = FALSE
  )
  names(row) <- .google_names

  # Prepend Timestamp — Google Forms always exports this as the first column
  row <- cbind(
    data.frame(Timestamp = "2024/01/01 10:00:00 AM", stringsAsFactors = FALSE),
    row
  )

  write.csv(row, path, row.names = FALSE)
}


# ==============================================================================
# Helper: Qualtrics main CSV (system cols + descriptor rows + data)
# ==============================================================================
#
# Qualtrics exports: header row + descriptor row 1 (question labels, contain \n)
#                                + descriptor row 2 (ImportId JSON)
#                                + data rows.
# .strip_qualtrics_meta() detects descriptor rows by looking for \n or
# {"ImportId": in cell values within the first 3 data rows.

.make_qualtrics_main_csv <- function(path) {
  sys_cols <- c(
    "StartDate", "EndDate", "Status", "IPAddress", "Progress",
    "Duration..in.seconds.", "Finished", "RecordedDate", "ResponseId",
    "LocationLatitude", "LocationLongitude", "DistributionChannel",
    "UserLanguage"
  )
  sys_vals <- c(
    "2024-01-01 10:00:00", "2024-01-01 10:05:00", "IP Address",
    "1.2.3.4", "100", "300", "True", "2024-01-01 10:05:00",
    "R_abc123", "39.7", "-86.1", "anonymous", "EN"
  )

  dyn_cols <- .google_names[startsWith(.google_names, "dynamics")]
  dyn_vals <- rep("Very High Applicability", length(dyn_cols))

  all_cols <- c(sys_cols, .indicator_cols, dyn_cols, .cascade_cols)
  all_vals <- c(
    sys_vals,
    as.character(.indicator_vals),
    dyn_vals,
    as.character(.cascade_vals)
  )

  data_row <- as.data.frame(
    matrix(all_vals, nrow = 1L),
    stringsAsFactors = FALSE
  )
  names(data_row) <- all_cols

  # Descriptor row 1: embed \n so .strip_qualtrics_meta() detects it
  desc1 <- data_row
  desc1[1L, ] <- lapply(all_cols, function(col)
    paste0("Question\nLabel: ", col))

  # Descriptor row 2: embed {"ImportId": so detector fires
  desc2 <- data_row
  desc2[1L, ] <- lapply(all_cols, function(col)
    paste0('{"ImportId":"', col, '"}'))

  # Qualtrics order: header + desc1 + desc2 + data
  full <- rbind(desc1, desc2, data_row)
  write.csv(full, path, row.names = FALSE)
}


# ==============================================================================
# Helper: alignment CSV
# ==============================================================================

.make_alignment_csv <- function(path) {
  row <- data.frame(
    role        = "Researcher",
    Goals       = 0.85, Values      = 0.90,
    Roles       = 0.75, Resources   = 0.80,
    Activities  = 0.70, Empowerment = 0.95,
    Outputs     = 0.88, Outcomes    = 0.82,
    stringsAsFactors = FALSE
  )
  write.csv(row, path, row.names = FALSE)
}


# ==============================================================================
# Qualtrics main survey tests
# ==============================================================================

test_that("load_survey_data loads a Qualtrics main CSV without error", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  expect_no_error(load_survey_data(path, survey = "main"))
})

test_that("load_survey_data Qualtrics result has correct list elements", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(c("indicators", "dynamics", "cascade", "source") %in%
                    names(result)))
})

test_that("load_survey_data detects Qualtrics source correctly", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_equal(result$source, "qualtrics")
})

test_that("load_survey_data Qualtrics cascade has the 9 cascade_d* columns", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(.cascade_cols %in% names(result$cascade)))
})

test_that("load_survey_data Qualtrics cascade probability columns are present and non-NA", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  prob_cols <- c("cascade_d2_stats_1", "cascade_d2_stats_2",
                 "cascade_d3_stats_1", "cascade_d3_stats_2")
  for (col in prob_cols) {
    expect_true(col %in% names(result$cascade), info = col)
    expect_false(all(is.na(result$cascade[[col]])), info = col)
  }
})

test_that("load_survey_data Qualtrics cascade count columns are numeric", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  count_cols <- c("cascade_d1_people_1_1", "cascade_d1_people_2_1",
                  "cascade_d2_people_1_1", "cascade_d2_people_2_1",
                  "cascade_d3_people")
  for (col in count_cols) {
    expect_true(is.numeric(result$cascade[[col]]), info = col)
  }
})

test_that("load_survey_data Qualtrics indicators has expected columns", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(c("indicator", "value") %in% names(result$indicators)))
})

test_that("load_survey_data Qualtrics dynamics has expected columns", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(c("domain", "dimension", "salience", "weight") %in%
                    names(result$dynamics)))
})

test_that("load_survey_data Qualtrics dynamics weight values are in (0, 1]", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_qualtrics_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  weights <- result$dynamics$weight
  weights <- weights[!is.na(weights)]
  expect_true(all(weights > 0 & weights <= 1))
})


# ==============================================================================
# Google Forms main survey tests
# ==============================================================================

test_that("load_survey_data loads a Google Forms main CSV without error", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  expect_no_error(load_survey_data(path, survey = "main"))
})

test_that("load_survey_data detects Google Forms source correctly", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_equal(result$source, "google")
})

test_that("load_survey_data Google Forms result has correct list elements", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(c("indicators", "dynamics", "cascade", "source") %in%
                    names(result)))
})

test_that("load_survey_data Google Forms cascade has the 9 cascade_d* columns", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(.cascade_cols %in% names(result$cascade)))
})

test_that("load_survey_data Google Forms rescales cascade probabilities to [0, 1]", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  prob_cols <- c("cascade_d2_stats_1", "cascade_d2_stats_2",
                 "cascade_d3_stats_1", "cascade_d3_stats_2")
  for (col in prob_cols) {
    val <- as.numeric(result$cascade[[col]])
    expect_gte(val, 0, label = col)
    expect_lte(val, 1, label = col)
  }
})

test_that("load_survey_data Google Forms inserts dynamics_selection as NA", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  # dynamics_selection is absent from Google Form; loader inserts it as NA
  # It gets dropped by the dynamics pipeline but should not cause an error
  expect_s3_class(result$dynamics, "data.frame")
})

test_that("load_survey_data Google Forms dynamics weight values are in (0, 1]", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  weights <- result$dynamics$weight
  weights <- weights[!is.na(weights)]
  expect_true(all(weights > 0 & weights <= 1))
})

test_that("load_survey_data Google Forms indicators has expected columns", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_google_main_csv(path)
  result <- load_survey_data(path, survey = "main")
  expect_true(all(c("indicator", "value") %in% names(result$indicators)))
})


# ==============================================================================
# Alignment survey tests
# ==============================================================================

test_that("load_survey_data loads an alignment CSV without error", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_alignment_csv(path)
  expect_no_error(load_survey_data(path, survey = "alignment"))
})

test_that("load_survey_data alignment result is a data frame", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_alignment_csv(path)
  result <- load_survey_data(path, survey = "alignment")
  expect_s3_class(result, "data.frame")
})

test_that("load_survey_data alignment result has correct columns", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_alignment_csv(path)
  result <- load_survey_data(path, survey = "alignment")
  expect_named(result, c("alignment", "role", "rating"), ignore.order = TRUE)
})

test_that("load_survey_data alignment role is recoded to partner/researcher", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_alignment_csv(path)
  result <- load_survey_data(path, survey = "alignment")
  expect_true(all(result$role %in% c("researcher", "partner")))
})

test_that("load_survey_data alignment result is compatible with analyze_alignment", {
  path <- withr::local_tempfile(fileext = ".csv")
  .make_alignment_csv(path)
  result <- load_survey_data(path, survey = "alignment")
  expect_no_error(analyze_alignment(result))
})


# ==============================================================================
# Error handling
# ==============================================================================

test_that("load_survey_data errors on non-existent file", {
  expect_error(
    load_survey_data("does_not_exist.csv", survey = "main"),
    regexp = "File not found"
  )
})

test_that("load_survey_data errors on invalid survey argument", {
  path <- withr::local_tempfile(fileext = ".csv")
  write.csv(data.frame(x = 1), path, row.names = FALSE)
  expect_error(
    load_survey_data(path, survey = "invalid"),
    regexp = "arg"
  )
})
