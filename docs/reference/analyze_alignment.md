# Calculate Alignment Scores

Performs a comprehensive analysis of alignment between "researcher" and
"partner" ratings using the CEnTR\*IMPACT methodology. This function
calculates the Intraclass Correlation Coefficient (ICC) to derive an
Alignment Score (\\S_a\\), alongside descriptive statistics
(interpolated medians and ranges) to visualize the gap between
perspectives.

## Usage

``` r
analyze_alignment(alignment_df)
```

## Arguments

- alignment_df:

  A data frame containing raw survey responses. Must contain:

  - `role`: Character ('researcher' or 'partner').

  - `alignment`: Character (the factor/category being rated).

  - `rating`: Numeric (the rating provided, typically 0-1).

## Value

An object of class `alignment_analysis` containing:

- `table`: Wide-format data frame with interpolated medians.

- `plot_data`: Long-format data frame suitable for ggplot2.

- `icc`: The full ICC object from the `irr` package.

- `alignment_score`: The numeric ICC value (\\S_a\\).
