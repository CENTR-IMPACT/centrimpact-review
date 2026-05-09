# Build a Three-Layer Cascade Network Edge List

Constructs an edge list representing the three-layer cascade network
from a single row of cascade survey parameters. Layer 1 nodes form a
fully connected clique; Layer 2 nodes are connected to their Layer 1
parents with probabilistic cross-connections; Layer 3 nodes are
connected to their Layer 2 parents with probabilistic cross-connections.
Probabilistic back-edges between layers are also generated.

## Usage

``` r
build_network(df_row)
```

## Arguments

- df_row:

  A one-row data frame or named list containing the `cascade_*` survey
  columns.

## Value

A data frame with columns `from`, `to`, and `layer`, suitable for
passing directly to
[`calculate_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/calculate_cascade.md).

## See also

[`analyze_cascade`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md)
which calls this function internally.
