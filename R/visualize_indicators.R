#' Visualize Project Indicators
#'
#' @description
#' Creates a linear "Bubble Chart" to display key project metrics.
#' Each indicator is represented by a circle sized relative to its value,
#' set against a fixed background ring.
#'
#' @param indicator_data A data frame with columns:
#'   \itemize{
#'     \item \code{indicator}: Character strings (e.g., "Community Partners").
#'     \item \code{value}: Numeric values.
#'   }
#'   If NULL, random demo data is generated.
#' @param project_title String. The title of the plot.
#'
#' @return A ggplot2 object.
#' @importFrom ggplot2 ggplot geom_segment geom_text scale_fill_discrete scale_color_discrete theme_minimal theme element_blank element_text annotate labs coord_fixed scale_y_continuous scale_x_continuous margin
#' @importFrom ggforce geom_circle
#' @importFrom glue glue
#' @export
visualize_indicators <- function(
    indicator_data = NULL,
    project_title = "Project Indicators Visualization"
) {

  # 1. SETUP & VALIDATION
  if (!requireNamespace("ggforce", quietly = TRUE)) {
    stop("The 'ggforce' package is required for this visualization. Please install it using install.packages('ggforce').")
  }

  # 2. DATA PREPARATION
  if (is.null(indicator_data)) {
    indicator_data <- data.frame(
      indicator = c(
        "Community Partners", "Engagement Hours", "Individuals Served",
        "Infrastructure Tools", "Output Products", "Students Involved",
        "Successful Outcomes"
      ),
      value = round(runif(7, min = 5, max = 50), 0)
    )
  }

  # Limit to top 7 items for layout consistency
  plot_data <- head(indicator_data, 7)
  n_items <- nrow(plot_data)

  # Add Layout Coordinates
  plot_data$x <- 1:n_items
  plot_data$y <- 1

  # 4. DYNAMIC RADIUS CALCULATION
  # Target: Largest bubble should have radius ~0.35 (background ring is 0.40)
  max_val <- max(plot_data$value, na.rm = TRUE)
  if (max_val == 0) max_val <- 1

  scale_factor <- sqrt(max_val) / 0.35
  plot_data$radius <- sqrt(plot_data$value) / scale_factor

  # Construct Label
  plot_data$label <- glue::glue("{plot_data$value} {plot_data$indicator}")

  # Vertical Reference Lines
  v_lines <- data.frame(x = 1:n_items)

  # 5. BUILD PLOT
  p <- ggplot2::ggplot() +

    # --- REFERENCE GRID ---
    # Horizontal line
    ggplot2::annotate("segment", x = 0.5, y = 1, xend = n_items + 0.5, yend = 1,
                      color = "#E0E0E0", linewidth = 0.5) +

    # Vertical lines (Dashed)
    ggplot2::geom_segment(
      data = v_lines,
      ggplot2::aes(x = x, y = 0.2, xend = x, yend = 1.8),
      color = "#E0E0E0", linewidth = 0.5, linetype = "dashed"
    ) +

    # --- BACKGROUND RINGS ---
    # Fixed radius 0.4
    ggforce::geom_circle(
      data = data.frame(x = 1:n_items, y = 1),
      ggplot2::aes(x0 = x, y0 = y, r = 0.4),
      color = "#E0E0E0", fill = "transparent", linewidth = 0.5
    ) +

    # --- DATA BUBBLES ---
    ggforce::geom_circle(
      data = plot_data,
      ggplot2::aes(
        x0 = x,
        y0 = y,
        r = radius,
        fill = indicator,
        color = indicator
      )
    ) +

    # --- LABELS ---
    ggplot2::geom_text(
      data = plot_data,
      ggplot2::aes(
        x = x,
        y = 1.55,
        label = label
      ),
      angle = 45,
      hjust = 0,
      size = 4.5,
      fontface = "italic",
      color = "#444444"
    ) +

    # --- SCALES & THEME ---
    ggplot2::scale_fill_discrete() +
    ggplot2::scale_color_discrete() +

    # Ensure circles are perfectly round
    ggplot2::coord_fixed(ratio = 1) +

    # Limits: ample space at top (y=3) for rotated labels
    ggplot2::scale_y_continuous(limits = c(0, 3.5)) +
    ggplot2::scale_x_continuous(limits = c(0.5, n_items + 1)) +

    ggplot2::theme_minimal() +
    ggplot2::labs(title = project_title) +
    ggplot2::theme(
      legend.position = "none",
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 16, margin = ggplot2::margin(b = 20))
    )

  return(p)
}
