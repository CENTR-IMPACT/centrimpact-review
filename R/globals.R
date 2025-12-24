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
  "layer_score"
))
