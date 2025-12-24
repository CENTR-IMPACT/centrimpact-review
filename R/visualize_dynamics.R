#' Visualize Dynamics (Rose Diagram)
#'
#' @description
#' Creates a "Rose" or "Coxcomb" chart to visualize the developmental balance of a project.
#' Inspired by Florence Nightingale's historic diagrams, this plot wraps a bar chart around
#' a central point, allowing for the comparison of cyclical or categorized data without
#' the visual bias of linear rank.
#'
#'
#' @details
#' \strong{Historical Context:}
#' This visualization is adapted from the "Diagram of the Causes of Mortality in the Army in the East"
#' by Florence Nightingale (1858). Just as her diagram highlighted disproportionate causes of death,
#' this chart highlights disproportionate strengths or weaknesses in project infrastructure.
#'
#' \strong{Visual Metaphor:}
#' The chart separates data into two distinct layers to show both the "Forest" (Domain)
#' and the "Trees" (Dimensions):
#' \itemize{
#'   \item \strong{Petals (Background Wedges):} Represent the aggregated \emph{Domain} score.
#'   These form the background "fan." If a Domain is strong, its petal reaches the outer edge (1.0).
#'   If weak, it shrinks toward the center.
#'   \item \strong{Stamen (Foreground Lollipops):} Represent the specific \emph{Dimension} values.
#'   These radiating lines allow you to see if a specific dimension (e.g., "Trust") is lagging
#'   behind its parent Domain (e.g., "Partnerships").
#' }
#'
#' \strong{Interpretation:}
#' A well-balanced project will appear as a full, nearly circular bloom. Gaps or "wilted" sectors
#' indicate areas of the project infrastructure (Context, Partnerships, Research, Learning, Outcomes)
#' that require attention.
#'
#' @param analysis_object An object of class \code{dynamics_analysis}. This list must contain:
#'   \itemize{
#'     \item \code{dynamics_df}: A data frame with columns \code{domain}, \code{dimension},
#'       \code{domain_score}, and \code{dimension_value}.
#'     \item \code{dynamics_score}: A single numeric value representing the overall system score (\eqn{S_d}).
#'   }
#' @param project_title String. The title of the plot. Defaults to "Project Dynamics Visualization".
#'
#' @return A \code{ggplot2} object.
#'
#' @references
#' Nightingale, F. (1858). \emph{Notes on Matters Affecting the Health, Efficiency, and Hospital Administration of the British Army}. Harrison and Sons.
#'
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation}. CUMU.
#'
#' @importFrom ggplot2 ggplot geom_col geom_segment geom_point geom_text geom_vline geom_hline scale_y_continuous scale_x_discrete scale_fill_manual scale_color_manual coord_polar theme_minimal theme element_blank element_text labs annotate aes
#' @importFrom dplyr filter group_by reframe mutate arrange first
#' @importFrom grDevices adjustcolor
#'
#' @export
visualize_dynamics <- function(
    analysis_object,
    project_title = "Project Dynamics Visualization"
) {
  # ===========================================================================
  # INPUT VALIDATION
  # ===========================================================================

  if (!inherits(analysis_object, "dynamics_analysis")) {
    stop("Input must be a 'dynamics_analysis' object.")
  }

  raw_data <- analysis_object$dynamics_df
  score_val <- analysis_object$dynamics_score
  desired_order <- c("Contexts", "Partnerships", "Research", "Learning", "Outcomes")

  if (is.null(raw_data) || nrow(raw_data) == 0) {
    warning("No dynamics data found to visualize.")
    return(NULL)
  }

  # ===========================================================================
  # DATA PREPARATION
  # ===========================================================================

  # Aggregate data to ensure one row per dimension (prevents "dots" artifacts)
  clean_data <- raw_data |>
    dplyr::filter(!is.na(dimension_value)) |>
    dplyr::group_by(domain, dimension) |>
    dplyr::reframe(
      dimension_value = mean(dimension_value, na.rm = TRUE),
      domain_score = mean(domain_score, na.rm = TRUE)
    ) |>
    dplyr::filter(!is.nan(domain_score))

  # Factor ordering for correct circle layout
  clean_data <- clean_data |>
    dplyr::mutate(domain = factor(domain, levels = desired_order)) |>
    dplyr::arrange(domain, dimension) |>
    dplyr::mutate(
      dimension = factor(dimension, levels = unique(dimension)),
      id = as.numeric(dimension)
    )

  total_dims <- nrow(clean_data)

  # Calculate dynamic label positions
  label_data <- clean_data |>
    dplyr::group_by(domain) |>
    dplyr::reframe(
      center_id = mean(id),
      domain_score = dplyr::first(domain_score),
      label_text = paste0(domain, " (", sprintf("%.2f", domain_score), ")")
    ) |>
    dplyr::mutate(
      pos_fraction = (center_id - 0.5) / total_dims,
      is_left = pos_fraction > 0.5,
      hjust_val = ifelse(is_left, 1, 0),
      # Place label just above the petal, with a safety floor (0.35)
      y_pos = pmax(domain_score, 0.35) + 0.12
    )

  # ===========================================================================
  # GENERATE PLOT
  # ===========================================================================

  p <- ggplot2::ggplot(clean_data) +

    # --- STAMEN GUIDES (Dashed Lines) ---
    ggplot2::geom_segment(
      ggplot2::aes(x = dimension, xend = dimension, y = 0, yend = 1.3),
      linetype = "dashed",
      color = "#D0D0D0",
      linewidth = 0.4,
      show.legend = FALSE
    ) +

    # --- GRID SEPARATORS ---
    ggplot2::geom_vline(
      xintercept = seq(0.5, total_dims + 0.5, 1),
      color = "#E0E0E0", linewidth = 0.3, linetype = "dotted"
    ) +
    ggplot2::geom_hline(
      yintercept = c(0.25, 0.5, 0.75, 1),
      color = "#E0E0E0", linewidth = 0.3, linetype = "longdash"
    ) +

    # --- PETALS (Background Wedges) ---
    ggplot2::geom_col(
      ggplot2::aes(x = dimension, y = domain_score, fill = domain),
      width = 1,
      color = NA,
      alpha = 0.5
    ) +

    # --- STAMEN (Foreground Lollipops) ---
    ggplot2::geom_segment(
      ggplot2::aes(
        x = dimension, xend = dimension,
        y = 0, yend = dimension_value,
        color = domain
      ),
      linewidth = 1.2
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = dimension, y = dimension_value, color = domain),
      size = 3.5
    ) +

    # --- SCALES ---
    ggplot2::scale_y_continuous(
      limits = c(-0.1, 1.45), # -0.1 creates the small central hole
      breaks = c(0.25, 0.5, 0.75, 1),
      labels = NULL
    ) +
    ggplot2::scale_x_discrete(
      expand = c(0, 0)
    ) +

    # --- COORDINATES ---
    ggplot2::coord_polar(
      start = 0,
      clip = "off"
    ) +

    # --- THEME ---
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::labs(
      title = project_title,
      subtitle = bquote(S[d] == .(sprintf("%.2f", score_val))),
      x = NULL, y = NULL
    ) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = 9, face = "italic", color = "#666666"),
      plot.subtitle = ggplot2::element_text(hjust = 1, margin = ggplot2::margin(b = -10)),
      legend.position = "none"
    ) +

    # --- ANNOTATIONS ---
    ggplot2::annotate(
      "text",
      x = 1, y = c(0.25, 0.5, 0.75, 1),
      label = c("0.25", "0.50", "0.75", "1.00"),
      color = "#999999", size = 2.5, fontface = "italic"
    ) +

    # --- DOMAIN LABELS ---
    ggplot2::geom_text(
      data = label_data,
      ggplot2::aes(
        x = center_id,
        y = y_pos,
        label = label_text,
        color = domain,
        hjust = hjust_val
      ),
      angle = 0,
      fontface = "italic",
      size = 2.75
    )

  return(p)
}
