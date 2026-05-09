# Run the Cascade Analysis Pipeline

High-level entry point for cascade analysis. Accepts raw cascade survey
parameters directly, estimates the expected network size, and
automatically routes to either a full exact analysis (when the network
is tractable) or a scaled stochastic analysis (when the network is too
large). In scaled mode, multiple stochastic runs are averaged to reduce
variance from the probabilistic edge generation.

## Usage

``` r
analyze_cascade(
  cascade_data,
  max_edges = 2e+06,
  target_nodes = 500,
  n_runs = 5,
  seed = NULL,
  always_scale = FALSE,
  keep_runs = FALSE
)
```

## Arguments

- cascade_data:

  A one-row data frame containing the `cascade_*` survey columns (people
  counts and probability parameters). If a multi-row data frame is
  supplied (e.g. directly from
  [`generate_cascade_data()`](https://centr-impact.github.io/centrimpact-review/reference/generate_cascade_data.md)),
  only the first row is used and a warning is emitted.

- max_edges:

  Maximum expected edge count for exact analysis. Default 2e6. Networks
  with more expected edges are scaled.

- target_nodes:

  Target total node count when scaling is applied. Default 500. Larger
  values give more accurate results at higher runtime.

- n_runs:

  Number of stochastic runs to average in scaled mode. Default 5.

- seed:

  Optional integer seed for reproducibility. In scaled mode, run \\i\\
  uses `seed + i` so runs are independent but deterministic.

- always_scale:

  Logical. If `TRUE`, force scaled analysis even when the network fits
  within `max_edges`. Useful for benchmarking. Default `FALSE`.

- keep_runs:

  Logical. If `TRUE`, attach all individual `cascade_analysis` run
  results to the output as `run_results`. Default `FALSE`.

## Value

A list of class `"cascade_pipeline"` containing:

- `mode`: `"full"` or `"scaled"`.

- `summary`: Mean layer summary table (tibble with `layer_knitting`,
  `layer_bridging`, `layer_channeling`, `layer_reaching`, `layer_score`,
  `layer_number`).

- `summary_sd`: Per-column SD across runs (`NULL` in full mode).

- `cascade_score`: Gini-based cascade balance score.

- `estimated_edges`: Expected edge count before any scaling.

- `scale_used`: Scale factor applied (`1` in full mode).

- `n_runs`: Number of runs averaged.

- `node_data`: Per-node metrics (full mode only; `NULL` in scaled mode –
  use `keep_runs = TRUE` to access individual run node data).

- `run_results`: Individual run results (only present when
  `keep_runs = TRUE`).

## Details

**Routing Logic:** The expected edge count is estimated analytically
from the survey parameters without constructing the network. If it falls
within `max_edges`, a single full `calculate_cascade(build_network())`
call is made. Otherwise, the five "people" parameters are scaled down
proportionally so that the resulting network has approximately
`target_nodes` total nodes, and `n_runs` independent runs are averaged.

**Scaling Method:** The scale factor \\s\\ is found by solving the cubic
node-count equation \$\$n_1 s + n_2 s^2 + n_3 s^3 =
\text{target\\nodes}\$\$ numerically via
[`uniroot()`](https://rdrr.io/r/stats/uniroot.html), where \\n_1\\,
\\n_2\\, \\n_3\\ are the unscaled node counts per layer. This preserves
the L1:L2:L3 ratio and avoids the floor-collapse problem that occurs
with a fixed multiplier when small counts round to zero. Floors of
`pmax(2, ...)` are applied to L1 type counts (so the clique remains
meaningful) and `pmax(1, ...)` to all other counts.

**Why average runs?** The probabilistic edges (L2-L2, L3-L3, back-edges)
introduce stochastic variance. A single scaled run can produce
misleading scores when the scaled network is small. Averaging `n_runs`
independent realizations of the same scaled parameters yields stable
estimates; `summary_sd` quantifies the remaining run-to-run variance.

## References

Leng, Y., et al. (2018). The rippling effect of social influence via
phone communication network. In *Complex Spreading Phenomena in Social
Systems* (pp. 323-333). Springer.

## See also

[`calculate_cascade`](https://centr-impact.github.io/centrimpact-review/reference/calculate_cascade.md)
for the underlying network analysis function.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Generate a synthetic 3-layer network
# This simulates Core (L1) -> Partner (L2) -> Community (L3) flow
network_data <- generate_cascade_data(seed = 42)

# 2. Run the cascade analysis
result <- analyze_cascade(network_data)

# 3. Inspect the Global Balance Score (Sc)
# A high score (0.8+) implies influence is well-distributed across layers
print(result$cascade_score)

# 4. View the Layer Summary
# Check if "Knitting" is high in Layer 1 vs "Reaching" in Layer 3
print(result$summary)
} # }
```
