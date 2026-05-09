# Package index

## Data Generation

Generate example datasets for testing and demonstration

- [`generate_alignment_data()`](https://centr-impact.github.io/centrimpact-review/reference/generate_alignment_data.md)
  : Generate Alignment Data
- [`generate_cascade_data()`](https://centr-impact.github.io/centrimpact-review/reference/generate_cascade_data.md)
  : Generate Cascade Survey Parameters
- [`generate_dynamics_data()`](https://centr-impact.github.io/centrimpact-review/reference/generate_dynamics_data.md)
  : Generate Project Dynamics Data
- [`generate_indicators_data()`](https://centr-impact.github.io/centrimpact-review/reference/generate_indicators_data.md)
  : Generate Indicators Data

## Analysis Functions

Compute alignment, cascade, dynamics, and indicator scores

- [`analyze_alignment()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_alignment.md)
  : Calculate Alignment Scores
- [`analyze_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md)
  : Run the Cascade Analysis Pipeline
- [`analyze_dynamics()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_dynamics.md)
  : Analyze Project Dynamics

## Visualization Functions

Create publication-ready visualizations

- [`visualize_abacus()`](https://centr-impact.github.io/centrimpact-review/reference/visualize_abacus.md)
  : Visualize Researcher-Partner Alignment (Abacus Plot)
- [`visualize_alignment()`](https://centr-impact.github.io/centrimpact-review/reference/visualize_alignment.md)
  : Visualize Rater Alignment (Slopegraph)
- [`visualize_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/visualize_cascade.md)
  : Visualize Cascade (Ripple) Effects
- [`visualize_dynamics()`](https://centr-impact.github.io/centrimpact-review/reference/visualize_dynamics.md)
  : Visualize Dynamics (Rose Diagram)
- [`visualize_indicators()`](https://centr-impact.github.io/centrimpact-review/reference/visualize_indicators.md)
  : Visualize Project Indicators

## Data Loading

Load and clean CEnTR\*IMPACT survey exports from Google Forms or
Qualtrics

- [`load_survey_data()`](https://centr-impact.github.io/centrimpact-review/reference/load_survey_data.md)
  : Load and Clean CEnTR\*IMPACT Survey Data

## Pipeline Functions

Lower-level network construction and analysis called internally by
analyze_cascade()

- [`build_network()`](https://centr-impact.github.io/centrimpact-review/reference/build_network.md)
  : Build a Three-Layer Cascade Network Edge List
- [`calculate_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/calculate_cascade.md)
  : Calculate Cascade Metrics From a Network Edge List
