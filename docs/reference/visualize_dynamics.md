# Visualize Dynamics (Rose Diagram)

Creates a "Rose" or "Coxcomb" chart to visualize the developmental
balance of a project. Inspired by Florence Nightingale's historic
diagrams, this plot wraps a bar chart around a central point, allowing
for the comparison of cyclical or categorized data without the visual
bias of linear rank.

## Usage

``` r
visualize_dynamics(
  analysis_object,
  project_title = "Project Dynamics Visualization"
)
```

## Arguments

- analysis_object:

  An object of class `dynamics_analysis`. This list must contain:

  - `dynamics_df`: A data frame with columns `domain`, `dimension`,
    `domain_score`, and `dimension_value`.

  - `dynamics_score`: A single numeric value representing the overall
    system score (\\S_d\\).

- project_title:

  String. The title of the plot. Defaults to "Project Dynamics
  Visualization".

## Value

A `ggplot2` object.

## Details

**Historical Context:** This visualization is adapted from the "Diagram
of the Causes of Mortality in the Army in the East" by Florence
Nightingale (1858). Just as her diagram highlighted disproportionate
causes of death, this chart highlights disproportionate strengths or
weaknesses in project infrastructure.

**Visual Metaphor:** The chart separates data into two distinct layers
to show both the "Forest" (Domain) and the "Trees" (Dimensions):

- **Petals (Background Wedges):** Represent the aggregated *Domain*
  score. These form the background "fan." If a Domain is strong, its
  petal reaches the outer edge (1.0). If weak, it shrinks toward the
  center.

- **Stamen (Foreground Lollipops):** Represent the specific *Dimension*
  values. These radiating lines allow you to see if a specific dimension
  (e.g., "Trust") is lagging behind its parent Domain (e.g.,
  "Partnerships").

**Interpretation:** A well-balanced project will appear as a full,
nearly circular bloom. Gaps or "wilted" sectors indicate areas of the
project infrastructure (Context, Partnerships, Research, Learning,
Outcomes) that require attention.

## References

Nightingale, F. (1858). *Notes on Matters Affecting the Health,
Efficiency, and Hospital Administration of the British Army*. Harrison
and Sons.

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research – Inclusive Measurement of Projects & Community
Transformation*. CUMU.
