#' Visualize Researcher-Partner Alignment (Abacus Plot)
#'
#' @description
#' Creates a "Single Rail Abacus" plot to visualize alignment. This method places "beads"
#' (representing ratings) onto category "rails," providing a clear view of both central
#' tendency and divergence on a linear scale.
#'
#' @details
#' \strong{Methodology:}
#' Inspired by the "Degree of Collaboration Tool" (Doberneck & Dann, 2019), this visualization
#' maps multiple dimensions of a project onto horizontal tracks (0 to 1). It is adapted here
#' for the CEnTR*IMPACT framework (Price, 2024) to show the consensus and spread of
#' survey ratings.
#'
#' \strong{Visual Elements:}
#' \itemize{
#'   \item \strong{Rails:} Horizontal gray bars representing the full continuum of possible agreement (0 to 1).
#'   \item \strong{Solid Beads:} The median rating for each group (Researchers vs. Partners).
#'   \item \strong{Transparent Beads:} The minimum and maximum ratings, showing the spread or disagreement \emph{within} a group.
#'   \item \strong{Overall Square:} The geometric mean (consensus) rating.
#' }
#' This format is particularly useful for identifying "outliers" (individuals who rated extremely high or low)
#' relative to the group's median.
#'
#' @param analysis_object An object of class \code{alignment_analysis} produced by \code{\link{analyze_alignment}}.
#' @param project_title String. The title of the plot. Defaults to "Project Alignment Visualization".
#' @param point_size Numeric. The size of the main median bead. Defaults to 5.
#'
#' @return A \code{ggplot2} object.
#'
#' @references
#' Doberneck, D. M., & Dann, S. L. (2019). \emph{The Degree of Collaboration Tool}. Engagement Scholarship. Available at: \url{https://engagementscholarship.org/upload/eesw/2022/2-5\%20\%20Doberneck\%20_\%20Dann\%20(2019)\%20The\%20Degree\%20of\%20Collaboration\%20Tool.pdf}
#'
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation}. CUMU. Available at: \url{https://cumuonline.org/wp-content/uploads/2024-CUMU-Collaboratory-Fellowship-Report.pdf}
#'
#' @examples
#' # 1. Generate and analyze data
#' data <- generate_alignment_data()
#' results <- analyze_alignment(data)
#'
#' # 2. Create the abacus visualization
#' p <- visualize_abacus(results, project_title = "Partnership Alignment")
#'
#' # 3. Display the plot
#' print(p)
#'
#' @importFrom ggplot2 ggplot aes geom_segment geom_vline geom_point scale_y_continuous scale_x_continuous scale_shape_manual theme_minimal labs theme element_blank element_text
#' @export
visualize_abacus <- function(
    analysis_object,
    project_title = "Project Alignment Visualization",
    point_size = 5) {

  # ===========================================================================
  # INPUT VALIDATION
  # ===========================================================================
  if (!inherits(analysis_object, "alignment_analysis")) stop("Invalid input. Object must be of class 'alignment_analysis'.")

  # ===========================================================================
  # DATA PREPARATION
  # ===========================================================================
  plot_data <- analysis_object$plot_data

  # 1. FIX: Handle missing alignment_score to prevent subtitle crash
  score_val <- analysis_object$alignment_score
  if (is.null(score_val) || length(score_val) == 0) {
    score_text <- "N/A"
  } else {
    score_text <- sprintf("%.2f", score_val)
  }

  # 2. Split Data for Plotting Layers
  # 'beads_data' = Researcher and Partner (Have Min/Max/Median)
  # 'overall_data' = Overall (Has Geometric Mean only)
  beads_data <- subset(plot_data, role %in% c("researcher", "partner"))
  overall_data <- subset(plot_data, role == "overall")

  # 3. FIX: Ensure role case matches levels to avoid NAs
  beads_data$role <- factor(
    tolower(beads_data$role),
    levels = c("partner", "researcher"),
    labels = c("Partners", "Researchers")
  )

  # Add role label to overall data for legend
  overall_data$role <- factor("Overall", levels = c("Partners", "Researchers", "Overall"))

  # 4. Factor Management - Categories are sorted
  categories <- sort(unique(plot_data$alignment))
  categories <- categories[!is.na(categories)] # Safety filter

  # ===========================================================================
  # GENERATE PLOT
  # ===========================================================================
  p <- ggplot2::ggplot() +
    # --- A. THE RAILS ---
    # Draw horizontal bars for each category
    ggplot2::geom_segment(
      data = data.frame(cat = categories),
      ggplot2::aes(x = 0, xend = 1,
                   y = match(cat, categories), yend = match(cat, categories)),
      color = "gray85", linewidth = 2, lineend = "round"
    ) +

    # --- B. FRAME LINES ---
    # Vertical markers at 0 (Low) and 1 (High)
    ggplot2::geom_vline(xintercept = 0, color = "gray50", linewidth = 0.5) +
    ggplot2::geom_vline(xintercept = 1, color = "gray50", linewidth = 0.5) +

    # --- C. MIN/MAX BEADS (Small, Transparent) ---
    # These show the range of answers within a group
    ggplot2::geom_point(
      data = beads_data,
      ggplot2::aes(x = min_val, y = match(alignment, categories), color = role),
      size = point_size * 0.8,
      alpha = 0.6
    ) +
    ggplot2::geom_point(
      data = beads_data,
      ggplot2::aes(x = max_val, y = match(alignment, categories), color = role),
      size = point_size * 0.8,
      alpha = 0.6
    ) +

    # --- D. MEDIAN BEADS (Large, Opaque) ---
    # Filled circles representing the group median
    ggplot2::geom_point(
      data = beads_data,
      ggplot2::aes(x = rating, y = match(alignment, categories),
                   fill = role, color = role),
      size = point_size,
      shape = 21,    # Filled circle
      stroke = 0.5,
      alpha = 1
    ) +

    # --- E. OVERALL SQUARE ---
    # A distinct marker for the calculated consensus
    ggplot2::geom_point(
      data = overall_data,
      ggplot2::aes(x = rating, y = match(alignment, categories), shape = role),
      size = point_size - 1,
      color = "black",
      fill = "white",
      stroke = 1
    ) +

    # --- THEME AND SCALES ---
    ggplot2::scale_y_continuous(
      breaks = 1:length(categories),
      labels = categories,
      expand = c(0.1, 0.1)
    ) +
    ggplot2::scale_x_continuous(
      limits = c(-0.02, 1.02),
      breaks = seq(0, 1, 0.2)
    ) +
    ggplot2::scale_shape_manual(
      values = c("Overall" = 0),
      name = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = project_title,
      subtitle = bquote(S[a] == .(score_text)),
      x = "Alignment Score",
      y = NULL
    ) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 11, face = "bold"),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank()
    )

  return(p)
}
