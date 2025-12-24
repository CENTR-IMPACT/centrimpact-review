# Visualize Project Indicators

Creates a linear "Bubble Chart" to display key project metrics. Each
indicator is represented by a circle sized relative to its value, set
against a fixed background ring.

## Usage

``` r
visualize_indicators(
  indicator_data = NULL,
  project_title = "Project Indicators Visualization"
)
```

## Arguments

- indicator_data:

  A data frame with columns:

  - `indicator`: Character strings (e.g., "Community Partners").

  - `value`: Numeric values.

  If NULL, random demo data is generated.

- project_title:

  String. The title of the plot.

## Value

A ggplot2 object.
