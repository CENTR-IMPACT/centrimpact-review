# ==============================================================================
# GLOBAL VARIABLE DEFINITIONS
# ==============================================================================
# Declare global variables to prevent R CMD check warnings about undefined
# global variables when using non-standard evaluation in dplyr, ggplot2, etc.
# These variables are typically column names used in data manipulation pipelines.

utils::globalVariables(c(
  "composite_score",
  "min_val",
  "max_val",
  "ring_label",
  "layer_factor",
  "id",
  "center_id",
  "pos_fraction",
  "is_left",
  "y_pos",
  "label_text",
  "hjust_val",
  "x",
  "y",
  "radius",
  "indicator",
  "label",
  "alignment",
  "role",
  "rating",
  "researcher",
  "partner",
  "layer",
  "knitting",
  "bridging",
  "channeling",
  "reaching",
  "weight",
  "salience",
  "dimension",
  "dimension_value",
  "domain",
  "dimension_score",
  "domain_score",
  "layer_score",

  # load_survey_data.R — .load_alignment() tidy-eval column names
  "Goals",
  "Outcomes",

  # load_survey_data.R — .load_main() tidy-eval column names
  "dynamic",
  "descriptor",

  # load_survey_data.R — .translate_google_headers() bare column references
  "Timestamp",
  "dynamics_selection",
  "indicators_outcomes",
  "cascade_d2_stats_1",
  "cascade_d2_stats_2",
  "cascade_d3_stats_1",
  "cascade_d3_stats_2",

  # analyze_cascade.R / build_network() — dplyr::tibble() bare column names
  "from",
  "to"
))
