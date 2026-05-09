#' Load and Clean CEnTR*IMPACT Survey Data
#'
#' @description
#' Reads a CEnTR*IMPACT survey CSV file, detects the export format
#' (Google Forms or Qualtrics), applies the appropriate header translation
#' and cleaning, and returns analysis-ready data frames.
#'
#' @details
#' \strong{Survey types:}
#'
#' \strong{\code{survey = "main"}} reads the primary CEnTR*IMPACT survey
#' containing indicators, project dynamics, and cascade network parameters.
#' The function detects the export format automatically:
#' \itemize{
#'   \item \strong{Google Forms}: identified by the presence of a
#'     \code{Timestamp} column. Verbose question-text headers are translated
#'     to compact variable names, \code{dynamics_selection} (absent from the
#'     form) is inserted as \code{NA}, and cascade probability fields are
#'     rescaled from the 1--10 integer scale to \eqn{[0, 1]}.
#'   \item \strong{Qualtrics}: identified by the presence of Qualtrics system
#'     columns (\code{StartDate}, \code{ResponseId}, etc.). System meta
#'     columns, descriptor rows, and \code{_selection} columns are removed.
#'     The \code{" Applicability"} suffix is stripped from rating values and
#'     the \code{"Not Applicabie"} typo is corrected.
#' }
#' Returns a named list with three analysis-ready data frames:
#' \code{indicators}, \code{dynamics}, and \code{cascade}.
#'
#' \strong{\code{survey = "alignment"}} reads the alignment survey containing
#' researcher and community partner ratings across eight partnership factors.
#' Qualtrics system columns and descriptor rows are removed when present.
#' Returns a single long-format data frame ready for \code{analyze_alignment()}.
#'
#' \strong{Multiple rows:} For both survey types and both formats, if more
#' than one data row is present after cleaning, only the last row is kept.
#' This handles Qualtrics exports that include preview or test responses
#' before the final submission.
#'
#' @param file     Character. Path to the CSV file to load.
#' @param survey   Character. Which survey type to load. One of
#'   \code{"main"} or \code{"alignment"}.
#'
#' @return
#' For \code{survey = "main"}: a named list with elements:
#' \itemize{
#'   \item \code{indicators}: long-format indicators data frame for
#'     \code{visualize_indicators()}.
#'   \item \code{dynamics}: long-format dynamics data frame for
#'     \code{analyze_dynamics()}.
#'   \item \code{cascade}: wide-format cascade parameters data frame for
#'     \code{analyze_cascade()}.
#'   \item \code{source}: the detected source format,
#'     \code{"google"} or \code{"qualtrics"}.
#' }
#' For \code{survey = "alignment"}: a long-format data frame for
#' \code{analyze_alignment()}.
#'
#' @examples
#' \dontrun{
#' # Load the main survey (auto-detects Google Forms or Qualtrics format)
#' survey <- load_survey_data("data/mhfa_main.csv", survey = "main")
#'
#' # Access the ready-to-use sub-frames
#' indicators_data <- survey$indicators
#' dynamics_data   <- survey$dynamics
#' cascade_data    <- survey$cascade
#'
#' # Load the alignment survey
#' alignment_data <- load_survey_data("data/mhfa_alignment.csv", survey = "alignment")
#' }
#' @importFrom readr read_csv
#' @importFrom dplyr select mutate case_when across all_of starts_with
#'   ends_with relocate if_else slice_tail
#' @importFrom tidyr pivot_longer separate_wider_regex
#' @importFrom stringr str_squish str_remove
#' @importFrom utils type.convert
#' @export
load_survey_data <- function(file, survey = c("main", "alignment")) {
  survey <- match.arg(survey)

  if (!file.exists(file)) {
    stop(sprintf("File not found: %s", file))
  }

  if (survey == "main") {
    .load_main(file)
  } else {
    .load_alignment(file)
  }
}


# ==============================================================================
# Internal: main survey
# ==============================================================================

.load_main <- function(file) {

  raw <- readr::read_csv(file, show_col_types = FALSE)

  # ── Detect source format ────────────────────────────────────────────────────
  # Google Forms: has a "Timestamp" column.
  # Qualtrics:    has known system columns (StartDate, ResponseId, etc.).
  is_google    <- "Timestamp" %in% names(raw)
  is_qualtrics <- any(.qualtrics_system_cols() %in% names(raw))
  source <- if (is_google) "google" else "qualtrics"
  message(sprintf("Detected source format: %s", source))

  # ── Qualtrics-specific pre-processing ───────────────────────────────────────
  if (source == "qualtrics") {
    raw <- .strip_qualtrics_meta(raw)   # system cols + descriptor rows
    raw <- .strip_selection_cols(raw)   # intro_selection_0, dynamics_selection
  }

  # ── Keep only the last data row ─────────────────────────────────────────────
  raw <- .keep_last_row(raw)

  # ── Header translation (Google Forms only) ──────────────────────────────────
  df <- .translate_google_headers(raw)

  # ── Rating normalization ────────────────────────────────────────────────────
  df <- .normalize_ratings(df, source)

  # ── Indicators ──────────────────────────────────────────────────────────────
  indicators <- df |>
    dplyr::select(dplyr::starts_with("indicators_")) |>
    tidyr::pivot_longer(
      cols         = dplyr::everything(),
      names_to     = "indicator",
      names_prefix = "indicators_",
      values_to    = "value"
    ) |>
    stats::na.omit() |>
    dplyr::mutate(
      indicator = dplyr::case_when(
        indicator == "partners"  ~ "Community Partners",
        indicator == "hours"     ~ "Engagement Hours",
        indicator == "served"    ~ "Individuals Served",
        indicator == "tools"     ~ "Infrastructure Tools",
        indicator == "students"  ~ "Students Involved",
        indicator == "outputs"   ~ "Output Products",
        indicator == "outcomes"  ~ "Outcomes Achieved"
      )
    )

  # ── Dynamics ────────────────────────────────────────────────────────────────
  dynamics <- df |>
    dplyr::select(dplyr::starts_with("dynamics_")) |>
    dplyr::select(-dplyr::ends_with("_selection")) |>
    tidyr::pivot_longer(
      cols         = dplyr::everything(),
      names_to     = "dynamic",
      names_prefix = "dynamics_",
      values_to    = "rating"
    ) |>
    # Use a regex split rather than separate_wider_delim() because Qualtrics
    # exports use compound dimension names that contain underscores
    # (e.g. dynamics_p_decision_making_1). The pattern is fixed: a single
    # letter domain code, a multi-piece dimension, and a 1-5 descriptor digit.
    # Anchoring on the domain prefix and descriptor suffix lets the dimension
    # absorb whatever lies between, including underscores.
    tidyr::separate_wider_regex(
      cols     = dynamic,
      patterns = c(
        domain     = "[a-z]",
        "_",
        dimension  = ".+",
        "_",
        descriptor = "[1-5]"
      )
    ) |>
    stats::na.omit() |>
    dplyr::mutate(
      domain = dplyr::case_when(
        domain == "c" ~ "Contexts",
        domain == "p" ~ "Partnerships",
        domain == "r" ~ "Research",
        domain == "l" ~ "Learning",
        domain == "o" ~ "Outcomes"
      ),
      salience = dplyr::case_when(
        descriptor == "1" ~ 1,
        descriptor == "2" ~ 0.8,
        descriptor == "3" ~ 0.6,
        descriptor == "4" ~ 0.4,
        descriptor == "5" ~ 0.2
      ),
      weight = dplyr::case_when(
        rating == "Very High" ~ 1,
        rating == "High"      ~ 0.95,
        rating == "Medium"    ~ 0.9,
        rating == "Low"       ~ 0.84,
        rating == "Very Low"  ~ 0.78,
        is.na(rating)         ~ NA_real_
      )
    ) |>
    dplyr::select(-descriptor, -rating)

  # ── Cascade ──────────────────────────────────────────────────────────────────
  cascade <- df |>
    dplyr::select(dplyr::starts_with("cascade_"))

  list(
    indicators = indicators,
    dynamics   = dynamics,
    cascade    = cascade,
    source     = source
  )
}


# ==============================================================================
# Internal: alignment survey
# ==============================================================================

.load_alignment <- function(file) {

  raw <- readr::read_csv(file, show_col_types = FALSE)

  # ── Qualtrics pre-processing (system cols + descriptor rows if present) ──────
  # No _selection columns exist in the alignment survey schema.
  if (any(.qualtrics_system_cols() %in% names(raw))) {
    raw <- .strip_qualtrics_meta(raw)
  }

  # ── Rename, pivot, and clean ─────────────────────────────────────────────────
  raw |>
    stats::setNames(c(
      "role", "Goals", "Values", "Roles", "Resources",
      "Activities", "Empowerment", "Outputs", "Outcomes"
    )) |>
    tidyr::pivot_longer(
      cols      = Goals:Outcomes,
      names_to  = "alignment",
      values_to = "rating"
    ) |>
    dplyr::mutate(
      role = dplyr::case_when(
        role == "Community Partner" ~ "partner",
        role == "Researcher"        ~ "researcher"
      )
    )
}


# ==============================================================================
# Internal: shared helpers
# ==============================================================================

# The fixed set of Qualtrics system column names, used for both format
# detection and meta column removal. Centralised here so .load_main and
# .load_alignment stay in sync.
.qualtrics_system_cols <- function() {
  c(
    "StartDate", "EndDate", "Status", "IPAddress", "Progress",
    "Duration (in seconds)", "Finished", "RecordedDate", "ResponseId",
    "RecipientLastName", "RecipientFirstName", "RecipientEmail",
    "ExternalReference", "LocationLatitude", "LocationLongitude",
    "DistributionChannel", "UserLanguage"
  )
}

# Remove Qualtrics system (meta) columns and descriptor rows.
.strip_qualtrics_meta <- function(df) {

  # ── System columns ──────────────────────────────────────────────────────────
  meta_present <- intersect(names(df), .qualtrics_system_cols())
  if (length(meta_present) > 0L) {
    df <- df[, !names(df) %in% meta_present, drop = FALSE]
    message(sprintf("  Removed %d Qualtrics system column(s).", length(meta_present)))
  }

  # ── Descriptor rows ─────────────────────────────────────────────────────────
  # Qualtrics exports two extra rows after the column name header:
  #   Row 1: verbose question-text labels (contain "\n" from multi-line questions)
  #   Row 2: ImportId JSON descriptors (contain the literal string "ImportId")
  # Detection is value-based rather than positional so it is robust to files
  # where one row has already been removed or export options differ.
  rows_to_drop <- integer(0)

  for (i in seq_len(min(3L, nrow(df)))) {
    row_vals <- as.character(unlist(df[i, ], use.names = FALSE))
    row_vals <- row_vals[!is.na(row_vals)]
    if (length(row_vals) == 0L) next

    if (any(grepl('{"ImportId"', row_vals, fixed = TRUE)) ||
        any(grepl("\n",           row_vals, fixed = TRUE))) {
      rows_to_drop <- c(rows_to_drop, i)
    }
  }

  if (length(rows_to_drop) > 0L) {
    df <- df[-rows_to_drop, , drop = FALSE]
    message(sprintf("  Removed %d Qualtrics descriptor row(s).", length(rows_to_drop)))
  }

  # Re-parse columns coerced to character by the descriptor rows
  df <- utils::type.convert(df, as.is = TRUE)
  df
}

# Remove any column whose name contains "_selection".
# Applies to Qualtrics main exports (intro_selection_0, dynamics_selection).
# Named columns are listed in the message for transparency.
.strip_selection_cols <- function(df) {
  sel_cols <- grep("_selection", names(df), value = TRUE, fixed = TRUE)
  if (length(sel_cols) > 0L) {
    df <- df[, !names(df) %in% sel_cols, drop = FALSE]
    message(sprintf(
      "  Removed %d _selection column(s): %s.",
      length(sel_cols),
      paste(sel_cols, collapse = ", ")
    ))
  }
  df
}

# Keep only the last data row, emitting a message if rows were dropped.
# Handles Qualtrics exports with preview/test responses and Google Forms
# exports with revision history rows above the final submission.
.keep_last_row <- function(df) {
  n <- nrow(df)
  if (n > 1L) {
    message(sprintf("  %d data row(s) found; keeping only the last row.", n))
    df <- dplyr::slice_tail(df, n = 1L)
  }
  df
}


# ==============================================================================
# Internal: Google Forms header translation
# ==============================================================================

.translate_google_headers <- function(df) {
  if (!"Timestamp" %in% names(df)) return(df)

  google_names <- c(
    "indicators_partners", "indicators_hours", "indicators_served",
    "indicators_tools", "indicators_students", "indicators_outputs",
    "indicators_outcomes",
    # dynamics_selection is absent from the Google Form; inserted as NA below
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

  df <- dplyr::select(df, -Timestamp)

  if (ncol(df) != length(google_names)) {
    stop(sprintf(
      paste0(
        "Google Forms header translation failed: ",
        "expected %d columns after dropping Timestamp, found %d.\n",
        "The Google Form schema may have changed."
      ),
      length(google_names), ncol(df)
    ))
  }

  names(df) <- google_names

  # Insert dynamics_selection (absent from Google Form) as NA
  df <- df |>
    dplyr::mutate(dynamics_selection = NA_character_) |>
    dplyr::relocate(dynamics_selection, .after = indicators_outcomes)

  # Rescale cascade probability fields from 1-10 integer scale to [0, 1]
  df <- df |>
    dplyr::mutate(dplyr::across(
      c(cascade_d2_stats_1, cascade_d2_stats_2,
        cascade_d3_stats_1, cascade_d3_stats_2),
      ~ .x / 10
    ))

  message(sprintf(
    "  Renamed %d columns, inserted NA for dynamics_selection, rescaled cascade probabilities to [0, 1].",
    length(google_names)
  ))

  df
}


# ==============================================================================
# Internal: rating normalization
# ==============================================================================

.normalize_ratings <- function(df, source) {
  dyn_cols <- grep("^dynamics_", names(df), value = TRUE)
  dyn_cols <- dyn_cols[dyn_cols != "dynamics_selection"]

  if (source == "google") {
    # Google Forms uses short labels ("Very High", "Not Applicable").
    # "Not Applicable" -> NA so downstream weight logic treats it correctly.
    df <- df |>
      dplyr::mutate(dplyr::across(
        dplyr::all_of(dyn_cols),
        ~ dplyr::if_else(.x == "Not Applicable", NA_character_, .x)
      ))

  } else if (source == "qualtrics") {
    # Qualtrics uses full labels ("Very High Applicability", "Not Applicabie").
    # Strip " Applicability" suffix, fix the "Not Applicabie" typo, coerce to NA.
    df <- df |>
      dplyr::mutate(dplyr::across(
        dplyr::all_of(dyn_cols),
        \(x) {
          x <- stringr::str_squish(x)
          x <- stringr::str_remove(x, " Applicability$")
          dplyr::if_else(
            x %in% c("Not Applicabie", "Not Applicable"),
            NA_character_, x
          )
        }
      ))
  }

  df
}