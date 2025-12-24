#' Visualize Rater Alignment (Slopegraph)
#'
#' @description
#' Creates a slopegraph to visualize the alignment (or divergence) between "Partner" and
#' "Researcher" ratings. This visualization style highlights changes in rank and magnitude
#' between two groups, making it immediately apparent where perspectives align or conflict.
#'
#' @details
#' \strong{Methodology:}
#' The slopegraph, introduced by Edward Tufte (1983), is the preferred method for comparing
#' gradients of change or difference between two distinct states (in this case, two distinct
#' stakeholder roles).
#'
#' \strong{Interpretation:}
#' \itemize{
#'   \item \strong{Flat Lines:} Indicate perfect alignment (Partners and Researchers agree on the rating).
#'   \item \strong{Steep Slopes:} Indicate divergence (One group values the factor significantly higher than the other).
#'   \item \strong{Crossing Lines:} Indicate a difference in \emph{priority} or \emph{ranking} (e.g., Partners rate "Goals" highest, while Researchers rate it lowest).
#' }
#' The plot includes the Alignment Score (\eqn{S_a}) in the subtitle, providing a quick summary statistic
#' alongside the visual detail.
#'
#' @param analysis_object An object of class \code{alignment_analysis} produced by \code{\link{analyze_alignment}}.
#' @param project_title String. The title of the plot. Defaults to "Project Alignment Visualization".
#' @param color_palette Named vector of colors. If \code{NULL}, a colorblind-friendly hue palette is generated automatically.
#'
#' @return A \code{ggplot2} object that can be further customized (e.g., adding themes or changing labels).
#'
#' @references
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation}. CUMU.
#'
#' Tufte, E. R. (1983). \emph{The Visual Display of Quantitative Information}. Graphics Press.
#'
#' @examples
#' # 1. Generate and analyze data
#' data <- generate_alignment_data()
#' results <- analyze_alignment(data)
#'
#' # 2. Create the visualization
#' p <- visualize_alignment(results, project_title = "Year 1 Alignment")
#'
#' # 3. Display the plot
#' print(p)
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_point scale_color_manual scale_y_continuous theme_minimal labs theme element_blank element_text
#' @importFrom ggrepel geom_text_repel
#' @importFrom scales hue_pal
#' @importFrom stats setNames
#' @export
visualize_alignment <- function(
    analysis_object,
    project_title = "Project Alignment Visualization",
    color_palette = NULL) {

  # ===========================================================================
  # INPUT VALIDATION
  # ===========================================================================

  if (!inherits(analysis_object, "alignment_analysis")) stop("Invalid input. Object must be of class 'alignment_analysis'.")

  # ===========================================================================
  # DATA PREPARATION
  # ===========================================================================

  plot_data <- analysis_object$plot_data

  # 1. FIX: Ensure role case matches levels to avoid NAs
  # We force lower case for matching, then apply the correct factor levels/labels
  plot_data$role <- factor(
    tolower(plot_data$role),
    levels = c("partner", "overall", "researcher"),
    labels = c("Partners", "Overall", "Researchers")
  )

  # 2. FIX: Handle missing cascade_score to prevent subtitle crash
  score_val <- analysis_object$alignment_score
  if (is.null(score_val) || length(score_val) == 0) {
    score_text <- "N/A"
  } else {
    score_text <- sprintf("%.2f", score_val)
  }

  # Handle default palette if none provided
  if (is.null(color_palette)) {
    factors <- unique(plot_data$alignment)
    factors <- factors[!is.na(factors)] # Safety filter
    color_palette <- stats::setNames(scales::hue_pal()(length(factors)), factors)
  }

  # ===========================================================================
  # GENERATE PLOT
  # ===========================================================================

  p <- ggplot2::ggplot(
    data = plot_data,
    ggplot2::aes(x = role, y = rating, group = alignment, color = alignment)
  ) +
    # Draw Lines
    ggplot2::geom_line(linewidth = 1, alpha = 0.8) +

    # Draw Points
    ggplot2::geom_point(size = 3) +

    # --- LABELS ---
    # Labels for the lines (Left side - Partner)
    ggrepel::geom_text_repel(
      data = subset(plot_data, role == "Partners" & !is.na(alignment)),
      ggplot2::aes(label = as.character(alignment)), # Force character
      nudge_x = -0.3,
      direction = "y",
      hjust = 1,
      size = 3.5,
      segment.size = 0.2
    ) +

    # Labels for the lines (Right side - Researcher)
    ggrepel::geom_text_repel(
      data = subset(plot_data, role == "Researchers" & !is.na(alignment)),
      ggplot2::aes(label = as.character(alignment)), # Force character
      nudge_x = 0.3,
      direction = "y",
      hjust = 0,
      size = 3.5,
      segment.size = 0.2
    ) +

    # --- THEME AND SCALES ---
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = project_title,
      subtitle = bquote(S[a] == .(score_text)),
      y = "Alignment",
      x = NULL
    ) +
    ggplot2::theme(
      legend.position = "none",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = 12, face = "bold"),
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(size = 13, color = "#555555")
    )

  return(p)
}
