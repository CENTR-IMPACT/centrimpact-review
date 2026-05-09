# Generate Cascade Survey Parameters

Generates a synthetic one-row data frame of cascade survey parameters,
suitable for passing directly to
[`analyze_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md).
The parameters represent a plausible set of cascade network inputs:
Layer 1 team size (split into two types), Layer 2 reach per type, Layer
3 reach, and probabilistic cross-connection rates for each layer.

## Usage

``` r
generate_cascade_data(seed = Sys.time())
```

## Arguments

- seed:

  Integer or POSIXct. The seed for random number generation. Defaults to
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

A one-row data frame with columns matching the `cascade_d*` survey
schema consumed by
[`analyze_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md).

## Details

The returned data frame has the same column schema as the `cascade`
sub-frame produced by
[`load_survey_data()`](https://centr-impact.github.io/centrimpact-review/reference/load_survey_data.md),
so it can be used as a drop-in replacement for testing and examples
without needing a real survey file.

**Parameter ranges:**

- `cascade_d1_people_1_1`: Layer 1 Type 1 count (2–6).

- `cascade_d1_people_2_1`: Layer 1 Type 2 count (2–6).

- `cascade_d2_people_1_1`: Layer 2 children per Type 1 parent (1–4).

- `cascade_d2_people_2_1`: Layer 2 children per Type 2 parent (1–4).

- `cascade_d2_stats_1`: L2-L2 cross-connection probability (0.05–0.40).

- `cascade_d2_stats_2`: L2-\>L1 back-edge probability (0.05–0.30).

- `cascade_d3_people`: Layer 3 children per Layer 2 parent (1–4).

- `cascade_d3_stats_1`: L3-L3 cross-connection probability (0.02–0.20).

- `cascade_d3_stats_2`: L3-\>L2 back-edge probability (0.02–0.20).

## References

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research – Inclusive Measurement of Projects & Community
Transformation* (CUMU-Collaboratory Fellowship Report). Coalition of
Urban and Metropolitan Universities.

## See also

[`analyze_cascade`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md),
[`load_survey_data`](https://centr-impact.github.io/centrimpact-review/reference/load_survey_data.md)

## Examples

``` r
params <- generate_cascade_data(seed = 42)
result <- analyze_cascade(params)
#> Running full exact analysis (~68 expected edges).
print(result$cascade_score)
#> [1] 0.768217
```
