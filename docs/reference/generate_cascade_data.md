# Generate Cascade Data

Generates synthetic network data to simulate a multi-layered network
showing how impact diffuses from primary agents (Layer 1) to secondary
(Layer 2) and tertiary (Layer 3) actors.

## Usage

``` r
generate_cascade_data(seed = Sys.time())
```

## Arguments

- seed:

  Integer or POSIXct. The seed for random number generation. Defaults to
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

A data frame representing the edge list with columns: `from`, `to`, and
`layer`.

## Details

This function constructs a directed graph structure (represented as an
edge list) with three distinct layers. It uses an optimized, vectorized
approach to generate connections based on probabilistic rules defined in
the CEnTR\*IMPACT framework.

**Network Logic:**

- **Layer 1:** A fully connected clique of primary agents (3-10 nodes).

- **Layer 2:** Children of Layer 1 (1-3 children per parent). 36% chance
  of internal connections.

- **Layer 3:** Children of Layer 2 (parents selected with 72%
  probability). 10% chance of internal connections.

## References

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research – Inclusive Measurement of Projects & Community
Transformation* (CUMU-Collaboratory Fellowship Report). Coalition of
Urban and Metropolitan Universities.
