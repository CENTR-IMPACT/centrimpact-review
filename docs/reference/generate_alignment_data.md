# Generate Alignment Data

Generates synthetic data to simulate "Alignment"—the degree of agreement
between different stakeholders (Researchers and Partners) across key
project areas.

## Usage

``` r
generate_alignment_data(seed = Sys.time())
```

## Arguments

- seed:

  Integer or POSIXct. The seed for random number generation. Defaults to
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

A data frame with columns: `alignment`, `role`, and `rating`.

## Details

This function simulates a survey response dataset where multiple
participants (Researchers and Partners) rate their agreement or
alignment on various axes (Goals, Values, Roles, etc.).

**Logic:**

- Randomly selects a number of researchers (1-10) and partners
  (Researcher Count + 1 to 15).

- Generates alignment ratings (0.36 to 1.00) for 8 categories.

- Useful for visualizing gaps in understanding or expectation between
  stakeholder groups.

## References

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research – Inclusive Measurement of Projects & Community
Transformation* (CUMU-Collaboratory Fellowship Report). Coalition of
Urban and Metropolitan Universities.
