#' Visualize Cascade (Ripple) Effects
#'
#' @description
#' Visualizes the "Cascade" of effects—specifically the reach of the project across
#' different degrees of impact (1st Degree, 2nd Degree, and 3rd Degree)—using a radial bar chart
#' inspired by the sociological infographics of W.E.B. Du Bois.
#'
#'
#' @details
#' \strong{Historical Context:}
#' While often called a "racetrack plot" in modern plotting libraries, this visualization style
#' pays homage to the "City and Rural Population 1890" and other spiral charts created by
#' W.E.B. Du Bois for the 1900 Paris Exposition. Du Bois effectively used wrapped bars to
#' display magnitude within a confined space, allowing for immediate visual comparison of
#' lengths (impact) without the distortions of standard pie charts.
#'
#' \strong{Interpretation:}
#' This plot maps the "Ripple Effect" of the project:
#' \itemize{
#'   \item \strong{Inner Ring (1st Degree:} Immediate impact (Direct participants).
#'   \item \strong{Middle Ring (2nd Degree):} Intermediate impact (Partners of partners, local community).
#'   \item \strong{Outer Ring (3rd Degree):} Distant impact (Policy changes, broader field adoption).
#' }
#' The length of the arc represents the score (0 to 1). A "full" track indicates maximum impact at that level.
#'
#' @param analysis_object An object of class \code{cascade_analysis}.
#' @param project_title String. The title of the plot. Defaults to "Project Cascade Effects Visualization".
#' @param score_label_color String. Color code for the text labels inside the bars. Defaults to "white".
#'
#' @return A \code{ggplot2} object.
#'
#' @references
#' Du Bois, W. E. B. (1900). \emph{The Georgia Negro: A Social Study}. (Infographics displayed at the Paris Exposition of 1900). Library of Congress.
#'
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation}. CUMU.
#'
#' @examples
#' # 1. Generate and analyze data
#' data <- generate_cascade_data()
#' results <- analyze_cascade(data)
#'
#' # 2. Create the default visualization
#' p <- visualize_cascade(results)
#'
#' # 3. Customize the palette using standard ggplot2 grammar
#' # e.g., p + ggplot2::scale_fill_brewer(palette = "Dark2")
#' print(p)
#'
#' @importFrom ggplot2 ggplot aes geom_col geom_text scale_x_continuous scale_y_discrete coord_radial theme_bw theme element_blank element_text element_line labs
#' @importFrom dplyr mutate
#' @importFrom scales label_number
#' @export
visualize_cascade <- function(
    analysis_object,
    project_title = "Project Cascade Effects Visualization",
    score_label_color = "white"
) {
  # ===========================================================================
  # INPUT VALIDATION
  # ===========================================================================

  if (!inherits(analysis_object, "cascade_analysis")) {
    stop("Input must be a 'cascade_analysis' object from analyze_cascade().")
  }

  summary_df <- analysis_object$summary

  if (is.null(summary_df) || nrow(summary_df) == 0) {
    warning("No summary data found to visualize.")
    return(NULL)
  }

  # ===========================================================================
  # DATA PREPARATION
  # ===========================================================================

  plot_data <- summary_df |>
    dplyr::mutate(
      # Create "1 Degree", "2 Degree" labels for the axis
      ring_label = paste0(layer, " Degree"),
      # Ensure discrete factor for mapping
      layer_factor = factor(layer)
    )

  # ===========================================================================
  # GENERATE PLOT
  # ===========================================================================

  p <- ggplot2::ggplot(
    data = plot_data,
    ggplot2::aes(y = ring_label, fill = layer_factor, color = layer_factor)
  ) +

    # --- DATA BARS ---
    ggplot2::geom_col(
      ggplot2::aes(x = layer_score),
      width = 1,
      orientation = "y",
      show.legend = FALSE
    ) +

    # --- SCORE LABELS ---
    ggplot2::geom_text(
      ggplot2::aes(
        x = layer_score,
        label = sprintf("%.2f", layer_score)
      ),
      nudge_x = -0.04,
      size = 6,
      color = score_label_color,
      fontface = "bold",
      show.legend = FALSE
    ) +

    # --- SCALES ---
    ggplot2::scale_x_continuous(
      limits = c(0, 1.001), # Extra space for labels
      breaks = c(0, 0.25, 0.5, 0.75, 1.0),
      labels = scales::label_number(accuracy = 0.01) # Format as 0.00, 0.25, etc.
    ) +
    ggplot2::scale_y_discrete(
      expand = c(0, 0)
    ) +

    # --- COORDINATES ---
    ggplot2::coord_radial(
      inner.radius = 0.20,
      r.axis.inside = TRUE,
      rotate.angle = FALSE,
      expand = FALSE,
      end = 1.75 * pi
    ) +

    # --- THEME ---
    ggplot2::theme_bw() +
    ggplot2::labs(
      title = project_title,
      subtitle = bquote(S[c] == .(sprintf("%.2f", analysis_object$cascade_score)))
    ) +
    ggplot2::theme(
      panel.background = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),

      # Y-Axis Text (The degree labels)
      axis.text.y = ggplot2::element_text(
        size = 14,
        face = "italic",
        color = "#4A4A4A",
        margin = ggplot2::margin(r = 5)
      ),

      # X-Axis Text (The grid numbers)
      axis.text.x = ggplot2::element_text(
        size = 10,
        color = "#999999"
      ),
      panel.grid.major = ggplot2::element_line(linewidth = 0.5, color = "#E0E0E0"),
      plot.subtitle = ggplot2::element_text(hjust = 1, size = 14)
    )

  return(p)
}
