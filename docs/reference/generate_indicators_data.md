# Generate Indicators Data

Generates synthetic data for project "Indicators"—quantitative metrics
used to track the outputs and reach of a collaborative project.

## Usage

``` r
generate_indicators_data(seed = Sys.time())
```

## Arguments

- seed:

  Integer or POSIXct. The seed for random number generation. Defaults to
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

A data frame with columns: `indicator` and `value`.

## Details

This function creates a simple dataframe of common impact metrics (e.g.,
"Community Partners", "Students Involved") and assigns random integer
values to them. This serves as input for visualizing the scale or
"reach" of a project.

## References

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research – Inclusive Measurement of Projects & Community
Transformation* (CUMU-Collaboratory Fellowship Report). Coalition of
Urban and Metropolitan Universities.
