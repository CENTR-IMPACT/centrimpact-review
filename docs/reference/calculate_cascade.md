# Calculate Cascade Metrics From a Network Edge List

Performs the core cascade analysis on an edge list returned by
[`build_network()`](https://centr-impact.github.io/centrimpact-review/reference/build_network.md).
This function computes the topology score, layer-level role scores,
node-level metrics, and the overall cascade balance score.

## Usage

``` r
calculate_cascade(network_df, alpha_parameter = 0.9)
```

## Arguments

- network_df:

  A data frame representing the edge list. Required columns:

  - `from`: Source node identifier.

  - `to`: Target node identifier.

  - `layer`: Integer (1-3). The "degree" of the interaction (1 = Core, 2
    = Community, 3 = Distant).

- alpha_parameter:

  Numeric. Damping factor for Alpha Centrality (defaults to 0.9).

## Value

An object of class `cascade_analysis` containing:

- `cascade_score`: The global Balance Score (\\S_c\\, 0-1).

- `summary`: A summary table aggregating roles by Layer (Degree).

- `node_data`: Detailed metrics for every node.

- `topology_score`: Baseline topological health score.

## Details

**Theoretical Foundation:** Unlike general connectivity metrics, this
method resembles the work of Long, Cunningham, and Braithwaite (2013),
examining participants' roles based on the structure of the network
formed through the research. It assesses how influence ripples outward
from the core team (Layer 1) to the broader community (Layer 3+).

**Operational Definitions:** The function maps Social Network Analysis
(SNA) metrics to four key influence roles:

**1. Knitting (Cohesion & Bonding):** Measures how well the network
strengthens internal bonds within a specific group.

- *Metrics:* Community detection (Walktrap) + Eigenvector Centrality.

- *Interpretation:* High scores indicate a tight-knit, resilient core.

**2. Bridging (Connection & Spanning):** Measures the ability to connect
otherwise disconnected groups (filling "structural holes").

- *Metrics:* Structural Holes (Constraint) + Degree Centrality on the
  inter-layer graph.

- *Interpretation:* High scores indicate key "brokers" connecting silos.

**3. Channeling (Flow & Transmission):** Measures the efficiency of
information flow and resource distribution.

- *Metrics:* PageRank (local) + Harmonic Centrality (global) on the
  inter-layer graph.

- *Interpretation:* High scores indicate effective pipelines for moving
  resources.

**4. Reaching (Access & Inclusion):** Measures the extent of the
network's periphery and accessibility.

- *Metrics:* Clustering Coefficient + Communicability (matrix
  exponential) on the inter-layer graph.

- *Interpretation:* High scores indicate an inclusive network with
  reduced barriers.

**The Scoring Process:**

1.  **Layer (Degree) Scoring:** For each network layer (degree of
    separation), influence is calculated by combining local cohesion
    (Knitting + Bridging), global flow (Channeling), and peripheral
    access (Reaching): \$\$s\_{\text{layer}} = \gamma(\alpha L +
    \beta G) + \lambda T\$\$ where \\L\\ represents combined Knitting
    and Bridging scores, \\G\\ represents Channeling score, \\T\\
    represents Reaching score, and weights are:

    - \\\alpha = 0.4\\ (local cohesion weight)

    - \\\beta = 0.3\\ (global flow weight)

    - \\\lambda = 0.3\\ (peripheral access weight)

    - \\\gamma\\ varies by layer: 0.9 (Layer 1), 0.5 (Layer 2), 0.45
      (Layer 3)

2.  **Cascade Balance Score:** Calculated based on the equality of layer
    scores. \$\$S\_{c} = 1 -
    \operatorname{Gini}(\\s\_{\text{layer},k}\\)\$\$ where
    \\\\s\_{\text{layer},k}\\\\ represents the set of all layer
    influence scores.

**Cascade Balance Interpretation:**

- \\S_c \< 0.50\\: **Very Low Balance** (Core-dominated)

- \\0.50 \le S_c \< 0.59\\: **Low Balance**

- \\0.60 \le S_c \< 0.69\\: **Moderate Balance**

- \\0.70 \le S_c \le 0.79\\: **High Balance**

- \\S_c \ge 0.80\\: **Very High Balance** (Equitable distribution)

## Pipeline

For typical use, call
[`analyze_cascade`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md)
rather than `calculate_cascade` directly. The pipeline accepts raw
cascade survey parameters, automatically routes to a full or scaled
analysis based on expected edge count, and averages results across
multiple stochastic runs when scaling is required.

## References

Christakis, N. A., & Fowler, J. H. (2009). *Connected: The Surprising
Power of Our Social Networks and How They Shape Our Lives*. Little,
Brown Spark.

Haddad, C. N., et al. (2024). *The World Bank's New Inequality
Indicator*. World Bank.
[doi:10.1596/41687](https://doi.org/10.1596/41687)

Long, J. C., Cunningham, F. C., & Braithwaite, J. (2013). Bridges,
brokers and boundary spanners in collaborative networks: a systematic
review. *BMC Health Services Research*, 13, 158.
[doi:10.1186/1472-6963-13-158](https://doi.org/10.1186/1472-6963-13-158)

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research - Inclusive Measurement of Projects & Community
Transformation*. CUMU.

Wang, H.-Y., et al. (2020). Comparison of Ferguson's delta and the Gini
coefficient used for measuring the inequality of data. *Health and
Quality of Life Outcomes*, 18(1), 111.

## See also

[`build_network`](https://centr-impact.github.io/centrimpact-review/reference/build_network.md)
to create the edge list consumed by this function.
[`generate_cascade_data`](https://centr-impact.github.io/centrimpact-review/reference/generate_cascade_data.md)
to simulate the network data used in examples.
