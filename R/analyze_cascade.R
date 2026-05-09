#' Build a Three-Layer Cascade Network Edge List
#'
#' @name build_network
#' @description
#' Constructs an edge list representing the three-layer cascade network from
#' a single row of cascade survey parameters. Layer 1 nodes form a fully
#' connected clique; Layer 2 nodes are connected to their Layer 1 parents
#' with probabilistic cross-connections; Layer 3 nodes are connected to
#' their Layer 2 parents with probabilistic cross-connections. Probabilistic
#' back-edges between layers are also generated.
#'
#' @param df_row A one-row data frame or named list containing the
#'   \code{cascade_*} survey columns.
#'
#' @return A data frame with columns \code{from}, \code{to}, and \code{layer},
#'   suitable for passing directly to \code{calculate_cascade()}.
#'
#' @seealso \code{\link{analyze_cascade}} which calls this function internally.
#'
#' @importFrom dplyr tibble bind_rows distinct arrange
#' @importFrom purrr map_dfr
#' @importFrom stats rbinom
#' @export
build_network <- function(df_row) {
  df_row <- as.list(df_row)

  # ── Extract parameters ──────────────────────────────────────────────────────
  n_l1_type1 <- df_row$cascade_d1_people_1_1
  n_l1_type2 <- df_row$cascade_d1_people_2_1
  l2_per_t1  <- df_row$cascade_d2_people_1_1
  l2_per_t2  <- df_row$cascade_d2_people_2_1
  l3_per_l2  <- df_row$cascade_d3_people
  p_l2_l2    <- df_row$cascade_d2_stats_1
  p_l2_l1    <- df_row$cascade_d2_stats_2
  p_l3_l3    <- df_row$cascade_d3_stats_1
  p_l3_l2    <- df_row$cascade_d3_stats_2

  # ── Assign node IDs ─────────────────────────────────────────────────────────
  n_l1 <- n_l1_type1 + n_l1_type2
  n_l2 <- n_l1_type1 * l2_per_t1 + n_l1_type2 * l2_per_t2
  n_l3 <- n_l2 * l3_per_l2

  l1_ids <- seq_len(n_l1)
  l2_ids <- seq_len(n_l2) + n_l1
  l3_ids <- seq_len(n_l3) + n_l1 + n_l2

  edges <- list()

  # ── Layer 1: fully connected clique ─────────────────────────────────────────
  if (n_l1 > 1) {
    l1_pairs    <- combn(l1_ids, 2)
    edges$l1_l1 <- dplyr::tibble(
      from  = l1_pairs[1, ],
      to    = l1_pairs[2, ],
      layer = 1L
    )
  }

  # ── Layer 1 -> Layer 2: parent-child edges ───────────────────────────────────
  l1_to_l2_from <- integer(n_l2)
  l1_to_l2_to   <- integer(n_l2)
  cursor <- 1L

  for (i in seq_len(n_l1)) {
    kids      <- if (i <= n_l1_type1) l2_per_t1 else l2_per_t2
    child_ids <- l2_ids[cursor:(cursor + kids - 1L)]
    l1_to_l2_from[cursor:(cursor + kids - 1L)] <- i
    l1_to_l2_to[cursor:(cursor + kids - 1L)]   <- child_ids
    cursor <- cursor + kids
  }

  edges$l1_l2 <- dplyr::tibble(
    from  = l1_to_l2_from,
    to    = l1_to_l2_to,
    layer = 2L
  )

  # ── Layer 2 -> Layer 3: parent-child edges ───────────────────────────────────
  l3_parent_l2 <- rep(l2_ids, each = l3_per_l2)

  edges$l2_l3 <- dplyr::tibble(
    from  = l3_parent_l2,
    to    = l3_ids,
    layer = 3L
  )

  # ── Layer 2 <-> Layer 2: probabilistic cross-edges ──────────────────────────
  if (n_l2 > 1 && p_l2_l2 > 0) {
    n_possible <- min(choose(n_l2, 2), .Machine$integer.max)
    n_edges    <- rbinom(1, n_possible, p_l2_l2)
    if (n_edges > 0) {
      pair_idx    <- sample.int(n_possible, n_edges)
      i_idx       <- ceiling((1 + sqrt(1 + 8 * pair_idx)) / 2)
      j_idx       <- pair_idx - choose(i_idx - 1, 2)
      edges$l2_l2 <- dplyr::tibble(
        from  = l2_ids[j_idx],
        to    = l2_ids[i_idx],
        layer = 2L
      )
    }
  }

  # ── Layer 2 -> Layer 1: probabilistic back-edges ────────────────────────────
  if (p_l2_l1 > 0) {
    l2_l1_edges <- purrr::map_dfr(seq_along(l2_ids), function(idx) {
      l2        <- l2_ids[idx]
      parent_l1 <- l1_to_l2_from[idx]
      if (runif(1) < p_l2_l1) {
        other_l1 <- setdiff(l1_ids, parent_l1)
        if (length(other_l1) > 0) {
          target <- sample(other_l1, 1)
          return(dplyr::tibble(
            from  = min(target, l2),
            to    = max(target, l2),
            layer = 2L
          ))
        }
      }
      dplyr::tibble(from = integer(0), to = integer(0), layer = integer(0))
    })
    if (nrow(l2_l1_edges) > 0) edges$l2_l1 <- l2_l1_edges
  }

  # ── Layer 3 <-> Layer 3: probabilistic cross-edges ──────────────────────────
  if (n_l3 > 1 && p_l3_l3 > 0) {
    n_possible <- min(choose(n_l3, 2), .Machine$integer.max)
    n_edges    <- rbinom(1, n_possible, p_l3_l3)
    if (n_edges > 0) {
      pair_idx    <- sample.int(n_possible, n_edges)
      i_idx       <- ceiling((1 + sqrt(1 + 8 * pair_idx)) / 2)
      j_idx       <- pair_idx - choose(i_idx - 1, 2)
      edges$l3_l3 <- dplyr::tibble(
        from  = l3_ids[j_idx],
        to    = l3_ids[i_idx],
        layer = 3L
      )
    }
  }

  # ── Layer 3 -> Layer 2: probabilistic back-edges ────────────────────────────
  if (p_l3_l2 > 0) {
    l3_l2_edges <- purrr::map_dfr(seq_along(l3_ids), function(idx) {
      l3        <- l3_ids[idx]
      parent_l2 <- l3_parent_l2[idx]
      if (runif(1) < p_l3_l2) {
        other_l2 <- setdiff(l2_ids, parent_l2)
        if (length(other_l2) > 0) {
          target <- sample(other_l2, 1)
          return(dplyr::tibble(
            from  = min(target, l3),
            to    = max(target, l3),
            layer = 3L
          ))
        }
      }
      dplyr::tibble(from = integer(0), to = integer(0), layer = integer(0))
    })
    if (nrow(l3_l2_edges) > 0) edges$l3_l2 <- l3_l2_edges
  }

  # ── Combine & deduplicate ────────────────────────────────────────────────────
  dplyr::bind_rows(edges) |>
    dplyr::distinct(from, to, layer) |>
    dplyr::arrange(layer, from, to)
}


#' Calculate Cascade Metrics From a Network Edge List
#'
#' @name calculate_cascade
#' @description
#' Performs the core cascade analysis on an edge list returned by
#' \code{build_network()}. This function computes the topology score,
#' layer-level role scores, node-level metrics, and the overall cascade
#' balance score.
#'
#' @param network_df A data frame representing the edge list. Required columns:
#'   \itemize{
#'     \item \code{from}: Source node identifier.
#'     \item \code{to}: Target node identifier.
#'     \item \code{layer}: Integer (1-3). The "degree" of the interaction
#'       (1 = Core, 2 = Community, 3 = Distant).
#'   }
#' @param alpha_parameter Numeric. Damping factor for Alpha Centrality
#'   (defaults to 0.9).
#'
#' @return An object of class \code{cascade_analysis} containing:
#'   \itemize{
#'     \item \code{cascade_score}: The global Balance Score (\eqn{S_c}, 0-1).
#'     \item \code{summary}: A summary table aggregating roles by Layer (Degree).
#'     \item \code{node_data}: Detailed metrics for every node.
#'     \item \code{topology_score}: Baseline topological health score.
#'   }
#'
#' @section Pipeline:
#' For typical use, call \code{\link{analyze_cascade}} rather than
#' \code{calculate_cascade} directly. The pipeline accepts raw cascade survey
#' parameters, automatically routes to a full or scaled analysis based on
#' expected edge count, and averages results across multiple stochastic runs
#' when scaling is required.
#'
#' @details
#' \strong{Theoretical Foundation:}
#' Unlike general connectivity metrics, this method resembles the work of Long,
#' Cunningham, and Braithwaite (2013), examining participants' roles based on the
#' structure of the network formed through the research. It assesses how influence
#' ripples outward from the core team (Layer 1) to the broader community (Layer 3+).
#'
#' \strong{Operational Definitions:}
#' The function maps Social Network Analysis (SNA) metrics to four key influence roles:
#'
#' \strong{1. Knitting (Cohesion & Bonding):}
#' Measures how well the network strengthens internal bonds within a specific group.
#' \itemize{
#'   \item \emph{Metrics:} Community detection (Walktrap) + Eigenvector Centrality.
#'   \item \emph{Interpretation:} High scores indicate a tight-knit, resilient core.
#' }
#'
#' \strong{2. Bridging (Connection & Spanning):}
#' Measures the ability to connect otherwise disconnected groups (filling "structural holes").
#' \itemize{
#'   \item \emph{Metrics:} Structural Holes (Constraint) + Degree Centrality on the inter-layer graph.
#'   \item \emph{Interpretation:} High scores indicate key "brokers" connecting silos.
#' }
#'
#' \strong{3. Channeling (Flow & Transmission):}
#' Measures the efficiency of information flow and resource distribution.
#' \itemize{
#'   \item \emph{Metrics:} PageRank (local) + Harmonic Centrality (global) on the inter-layer graph.
#'   \item \emph{Interpretation:} High scores indicate effective pipelines for moving resources.
#' }
#'
#' \strong{4. Reaching (Access & Inclusion):}
#' Measures the extent of the network's periphery and accessibility.
#' \itemize{
#'   \item \emph{Metrics:} Clustering Coefficient + Communicability (matrix exponential) on the inter-layer graph.
#'   \item \emph{Interpretation:} High scores indicate an inclusive network with reduced barriers.
#' }
#'
#' \strong{The Scoring Process:}
#'   1. \strong{Layer (Degree) Scoring:} For each network layer (degree of separation),
#'   influence is calculated by combining local cohesion (Knitting + Bridging),
#'   global flow (Channeling), and peripheral access (Reaching):
#'   \deqn{s_{\text{layer}} = \gamma(\alpha L + \beta G) + \lambda T}
#'   where \eqn{L} represents combined Knitting and Bridging scores, \eqn{G} represents
#'   Channeling score, \eqn{T} represents Reaching score, and weights are:
#'   \itemize{
#'     \item \eqn{\alpha = 0.4} (local cohesion weight)
#'     \item \eqn{\beta = 0.3} (global flow weight)
#'     \item \eqn{\lambda = 0.3} (peripheral access weight)
#'     \item \eqn{\gamma} varies by layer: 0.9 (Layer 1), 0.5 (Layer 2), 0.45 (Layer 3)
#'   }
#'
#'   2. \strong{Cascade Balance Score:} Calculated based on the equality of layer scores.
#'   \deqn{S_{c} = 1 - \operatorname{Gini}(\{s_{\text{layer},k}\})}
#'   where \eqn{\{s_{\text{layer},k}\}} represents the set of all layer influence scores.
#'
#' \strong{Cascade Balance Interpretation:}
#' \itemize{
#'   \item \eqn{S_c < 0.50}: \strong{Very Low Balance} (Core-dominated)
#'   \item \eqn{0.50 \le S_c < 0.59}: \strong{Low Balance}
#'   \item \eqn{0.60 \le S_c < 0.69}: \strong{Moderate Balance}
#'   \item \eqn{0.70 \le S_c \le 0.79}: \strong{High Balance}
#'   \item \eqn{S_c \ge 0.80}: \strong{Very High Balance} (Equitable distribution)
#' }
#'
#' @references
#' Christakis, N. A., & Fowler, J. H. (2009). \emph{Connected: The Surprising
#' Power of Our Social Networks and How They Shape Our Lives}. Little, Brown Spark.
#'
#' Haddad, C. N., et al. (2024). \emph{The World Bank's New Inequality Indicator}.
#' World Bank. \doi{10.1596/41687}
#'
#' Long, J. C., Cunningham, F. C., & Braithwaite, J. (2013). Bridges, brokers and
#' boundary spanners in collaborative networks: a systematic review. \emph{BMC Health
#' Services Research}, 13, 158. \doi{10.1186/1472-6963-13-158}
#'
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative
#' Research - Inclusive Measurement of Projects & Community Transformation}. CUMU.
#'
#' Wang, H.-Y., et al. (2020). Comparison of Ferguson's delta and the Gini
#' coefficient used for measuring the inequality of data. \emph{Health and Quality
#' of Life Outcomes}, 18(1), 111.
#'
#' @seealso
#' \code{\link{build_network}} to create the edge list consumed by this function.
#' \code{\link{generate_cascade_data}} to simulate the network data used in examples.
#'
#' @importFrom igraph graph_from_data_frame V as_adjacency_matrix global_efficiency
#'   betweenness eigen_centrality transitivity harmonic_centrality constraint
#'   induced_subgraph page_rank degree
#' @importFrom stats aggregate setNames uniroot
#' @importFrom sna connectedness hierarchy lubness
#' @importFrom dplyr select mutate group_by summarize case_when n
#' @importFrom expm expm
#' @export
calculate_cascade <- function(network_df, alpha_parameter = 0.9) {
  # ===========================================================================
  # VALIDATION
  # ===========================================================================

  if (!all(c("from", "to", "layer") %in% names(network_df))) {
    stop("Input must contain columns: 'from', 'to', 'layer'")
  }

  # ===========================================================================
  # NETWORK SETUP
  # ===========================================================================

  all_nodes_list <- unique(c(network_df$from, network_df$to))

  node_layer_map <- rbind(
    network_df[, c("from", "layer")],
    stats::setNames(network_df[, c("to", "layer")], c("from", "layer"))
  )
  node_layers <- stats::aggregate(layer ~ from, data = node_layer_map, min)
  names(node_layers) <- c("name", "layer")

  missing_nodes <- setdiff(all_nodes_list, node_layers$name)
  if (length(missing_nodes) > 0) {
    node_layers <- rbind(node_layers, data.frame(name = missing_nodes, layer = 4))
  }

  node_layers$gamma <- dplyr::case_when(
    node_layers$layer == 1 ~ 0.9,
    node_layers$layer == 2 ~ 0.5,
    node_layers$layer == 3 ~ 0.45,
    TRUE ~ 0.1
  )

  g <- igraph::graph_from_data_frame(network_df, directed = FALSE, vertices = node_layers)
  adj_mat <- igraph::as_adjacency_matrix(g, sparse = FALSE)

  w_alpha  <- 0.4
  w_beta   <- 0.3
  w_lambda <- 0.3

  # ===========================================================================
  # CALCULATE TOPOLOGY METRICS
  # ===========================================================================

  topo_efficiency <- igraph::global_efficiency(g)
  topo_connect    <- sna::connectedness(adj_mat)
  topo_hierarchy  <- 1 - sna::hierarchy(adj_mat)

  deg <- igraph::degree(g)
  topo_leadership_balance <- calculate_gini(deg)

  topo_vals  <- c(topo_efficiency, topo_connect, topo_hierarchy, topo_leadership_balance)
  topo_score <- mean(topo_vals[is.finite(topo_vals)], na.rm = TRUE) * w_lambda

  # ===========================================================================
  # CALCULATE LOCAL METRICS
  # ===========================================================================

  # Knitting uses within-layer subgraph eigenvector centrality, normalized
  # per layer rather than graph-wide. This ensures L1 nodes are evaluated
  # against each other (where a clique scores uniformly high), not against
  # L3's large dense cluster which dominates graph-wide eigenvector scores.
  #
  # For each layer:
  #   1. Induce the subgraph on layer nodes only.
  #   2. Compute eigenvector centrality within that subgraph.
  #   3. Scale by within-layer edge density (actual / possible edges) so that
  #      a clique always anchors to 1.0 before per-layer normalization.
  #   4. Normalize within the layer, then map back to graph node order.
  layer_eigen_vec <- numeric(length(igraph::V(g)))
  names(layer_eigen_vec) <- igraph::V(g)$name

  for (ly in unique(node_layers$layer)) {
    layer_node_names <- node_layers$name[node_layers$layer == ly]
    n_ly <- length(layer_node_names)

    # Within-layer edge density: coerce both sides to character to avoid
    # integer-vs-character type mismatches between network_df and node_layers.
    from_chr <- as.character(network_df$from)
    to_chr   <- as.character(network_df$to)
    within_edges <- sum(
      network_df$layer == ly &
        from_chr %in% layer_node_names &
        to_chr   %in% layer_node_names
    )
    density_ly <- if (n_ly < 2) 1.0 else within_edges / choose(n_ly, 2)

    # Eigenvector centrality on the layer subgraph.
    # Explicitly name the result with layer_node_names rather than relying on
    # igraph to preserve vertex name attributes through induced_subgraph --
    # when node IDs are integers, the subgraph may not carry a name attribute,
    # leaving eigen_centrality()$vector unnamed and causing silent assignment
    # failures via layer_eigen_vec[NULL] <- values.
    g_ly <- igraph::induced_subgraph(g, vids = layer_node_names)
    eigen_raw <- tryCatch(
      igraph::eigen_centrality(g_ly)$vector,
      error = function(e) rep(1.0, n_ly)
    )
    eigen_ly <- stats::setNames(as.numeric(eigen_raw), layer_node_names)

    # Scale by density so a perfect clique (density=1) gets full weight.
    # Normalize within the layer: uniform vectors (e.g. perfect clique) map
    # to rep(1.0) so every L1 node scores identically at the maximum.
    # Names are carried explicitly so the assignment into layer_eigen_vec
    # is always by name, never silently positional or silently no-op.
    scaled_ly <- eigen_ly * density_ly
    normed_ly <- if (diff(range(scaled_ly)) == 0) {
      stats::setNames(rep(1.0, n_ly), layer_node_names)
    } else {
      (scaled_ly - min(scaled_ly)) / diff(range(scaled_ly))
    }
    layer_eigen_vec[names(normed_ly)] <- normed_ly
  }

  # local_community is already in [0,1] per layer; no further normalization
  # is applied here so that the clique signal is not graph-wide rescaled.
  local_community <- layer_eigen_vec[igraph::V(g)$name]

  # Bridging is computed on the inter-layer subgraph only -- edges whose
  # endpoints belong to different layers. Within-layer edges (L1-L1 clique,
  # L2-L2 and L3-L3 probabilistic edges) are excluded so that bridging
  # measures degree-boundary-crossing rather than within-cluster centrality.
  #
  # On the inter-layer graph:
  #   L1 nodes span multiple L2 subtrees -> high degree, low constraint
  #   L2 nodes relay between L1 and L3   -> moderate scores
  #   L3 nodes are leaves                -> near-zero degree, max constraint
  # This ranking reflects the theoretical intent (core team bridges outward).
  node_layer_lookup <- stats::setNames(node_layers$layer, node_layers$name)
  from_layer <- node_layer_lookup[as.character(network_df$from)]
  to_layer   <- node_layer_lookup[as.character(network_df$to)]
  inter_edges <- network_df[!is.na(from_layer) & !is.na(to_layer) &
                              from_layer != to_layer, ]

  g_inter <- igraph::graph_from_data_frame(
    inter_edges[, c("from", "to")],
    directed  = FALSE,
    vertices  = node_layers
  )

  local_crossclique <- normalize(1 - igraph::constraint(g_inter))
  local_crossclique[is.na(local_crossclique)] <- 0
  global_bridge    <- normalize(igraph::degree(g_inter))
  local_clustcoef  <- normalize(igraph::transitivity(g, type = "local"))
  local_clustcoef[is.na(local_clustcoef)] <- 0

  A_inter <- igraph::as_adjacency_matrix(g_inter, sparse = TRUE)

  comm_vec <- expm::expAtv(A_inter, rep(1, nrow(A_inter)))$eAtv

  global_comm_inter <- normalize(comm_vec)

  # Channeling local metric: PageRank on g_inter.
  # PageRank (random-walk based) asks "does information keep flowing through
  # you sustainedly?" -- conceptually distinct from betweenness ("are you on
  # the shortest path?") used in bridging. On g_inter, L3 leaf nodes receive
  # and return flow only to their single L2 parent, giving them low PageRank.
  # L2 nodes aggregate flow from multiple L3 children and relay to L1 (high).
  # L1 nodes receive from L2 subtrees and distribute across them (high).
  local_channeling <- normalize(igraph::page_rank(g_inter)$vector)

  # ===========================================================================
  # CALCULATE GLOBAL METRICS
  # ===========================================================================

  # global_harmonic: harmonic centrality on the full graph, used in reaching.
  # (global_eigen and global_between have been removed -- they are no longer
  # used in any formula after bridging and channeling moved to g_inter.)
  global_harmonic <- normalize(igraph::harmonic_centrality(g))

  # Channeling global metric: harmonic centrality on g_inter.
  # Harmonic centrality measures transmission reach -- how efficiently a node
  # can reach the entire network (sum of 1/d for all other nodes). Unlike
  # closeness(), it handles disconnected components gracefully (1/inf = 0),
  # which matters on g_inter where L1-L1 paths may not exist without back-edges.
  # This is substantively different from reaching's harmonic_centrality(g):
  # stripping within-layer edges changes the graph structure fundamentally,
  # so the same metric family yields a different substantive question --
  # "how fast can you transmit across degree boundaries?" rather than
  # "how accessible are you across the full network?"
  global_channeling <- normalize(igraph::harmonic_centrality(g_inter))

  # ===========================================================================
  # CALCULATE INFLUENCE
  # ===========================================================================

  results_df <- data.frame(
    name  = igraph::V(g)$name,
    layer = igraph::V(g)$layer,
    gamma = igraph::V(g)$gamma
  )

  # Knitting: local_community is already per-layer normalized to [0,1] and
  # the clique structure is encoded in the uniform 1.0 values for L1 nodes.
  # The outer normalize() is intentionally omitted here -- applying it
  # graph-wide would allow L2/L3 node variance to compress L1's signal back
  # toward the middle, defeating the per-layer normalization we just did.
  # topo_score is added as a constant offset after scaling by gamma so the
  # landscape contributes equally to every node regardless of layer.
  results_df$knitting <- results_df$gamma * (w_alpha + w_beta) * local_community + topo_score

  # Bridging and channeling use gamma = 1.0 (no degree discount).
  # Rationale: the gamma weights from Leng et al. (2018) are degree discounts
  # for influence *propagation* -- they encode the empirical finding that
  # influence attenuates as it spreads outward from the core. This is
  # appropriate for knitting (cohesion) and reaching (access), which are
  # inherently about how influence radiates from L1 outward.
  #
  # Bridging and channeling are structural *roles*, not influence measures.
  # Whether a node spans structural holes or serves as an information relay
  # is a topological fact independent of how far from the core it sits.
  # Applying degree discounts to these metrics conflates influence attenuation
  # with structural position, causing L1 to dominate by gamma mechanics alone
  # rather than by genuine structural advantage. With gamma = 1.0, L2 nodes
  # score competitively on bridging and channeling -- reflecting that they
  # genuinely occupy the relay and bridge positions in the cascade architecture.
  results_df$bridging <- normalize(
    w_alpha * local_crossclique +
      w_beta * global_bridge +
      topo_score
  )
  results_df$channeling <- normalize(
    w_alpha * local_channeling + w_beta * global_channeling + topo_score
  )
  results_df$reaching <- normalize(
    results_df$gamma * (w_alpha * local_clustcoef + w_beta * global_comm_inter) + topo_score
  )

  results_df$composite_score <- rowMeans(
    results_df[, c("knitting", "bridging", "channeling", "reaching")]
  )

  # ===========================================================================
  # AGGREGATE BY LAYER
  # ===========================================================================

  layer_summary <- results_df |>
    dplyr::group_by(layer) |>
    dplyr::summarize(
      count            = dplyr::n(),
      gamma            = mean(gamma),
      layer_knitting   = mean(knitting),
      layer_bridging   = mean(bridging),
      layer_channeling = mean(channeling),
      layer_reaching   = mean(reaching),
      layer_score      = mean(composite_score),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      layer_number = paste0(layer, dplyr::case_when(
        layer == 1 ~ "st degree",
        layer == 2 ~ "nd degree",
        layer == 3 ~ "rd degree",
        TRUE       ~ "th degree"
      ))
    )

  # ===========================================================================
  # CALCULATE CASCADE BALANCE SCORE
  # ===========================================================================
  # calculate_gini() from utils_helper.R is used

  cascade_balance <- calculate_gini(layer_summary$layer_score)

  # ===========================================================================
  # RETURN RESULTS
  # ===========================================================================

  result <- list(
    summary        = layer_summary,
    node_data      = results_df,
    cascade_score  = cascade_balance,
    topology_score = topo_score
  )

  class(result) <- "cascade_analysis"
  return(result)
}


#' Run the Cascade Analysis Pipeline
#'
#' @description
#' High-level entry point for cascade analysis. Accepts raw cascade survey
#' parameters directly, estimates the expected network size, and automatically
#' routes to either a full exact analysis (when the network is tractable) or a
#' scaled stochastic analysis (when the network is too large). In scaled mode,
#' multiple stochastic runs are averaged to reduce variance from the
#' probabilistic edge generation.
#'
#' @details
#' \strong{Routing Logic:}
#' The expected edge count is estimated analytically from the survey parameters
#' without constructing the network. If it falls within \code{max_edges}, a
#' single full \code{calculate_cascade(build_network())} call is made. Otherwise,
#' the five "people" parameters are scaled down proportionally so that the
#' resulting network has approximately \code{target_nodes} total nodes, and
#' \code{n_runs} independent runs are averaged.
#'
#' \strong{Scaling Method:}
#' The scale factor \eqn{s} is found by solving the cubic node-count equation
#' \deqn{n_1 s + n_2 s^2 + n_3 s^3 = \text{target\_nodes}}
#' numerically via \code{uniroot()}, where \eqn{n_1}, \eqn{n_2}, \eqn{n_3}
#' are the unscaled node counts per layer. This preserves the L1:L2:L3 ratio
#' and avoids the floor-collapse problem that occurs with a fixed multiplier
#' when small counts round to zero. Floors of \code{pmax(2, ...)} are applied
#' to L1 type counts (so the clique remains meaningful) and \code{pmax(1, ...)}
#' to all other counts.
#'
#' \strong{Why average runs?}
#' The probabilistic edges (L2-L2, L3-L3, back-edges) introduce stochastic
#' variance. A single scaled run can produce misleading scores when the scaled
#' network is small. Averaging \code{n_runs} independent realizations of the
#' same scaled parameters yields stable estimates; \code{summary_sd} quantifies
#' the remaining run-to-run variance.
#'
#' @param cascade_data  A one-row data frame containing the \code{cascade_*}
#'   survey columns (people counts and probability parameters). If a multi-row
#'   data frame is supplied (e.g. directly from \code{generate_cascade_data()}),
#'   only the first row is used and a warning is emitted.
#' @param max_edges     Maximum expected edge count for exact analysis.
#'   Default 2e6. Networks with more expected edges are scaled.
#' @param target_nodes  Target total node count when scaling is applied.
#'   Default 500. Larger values give more accurate results at higher runtime.
#' @param n_runs        Number of stochastic runs to average in scaled mode.
#'   Default 5.
#' @param seed          Optional integer seed for reproducibility. In scaled
#'   mode, run \eqn{i} uses \code{seed + i} so runs are independent but
#'   deterministic.
#' @param always_scale  Logical. If \code{TRUE}, force scaled analysis even
#'   when the network fits within \code{max_edges}. Useful for benchmarking.
#'   Default \code{FALSE}.
#' @param keep_runs     Logical. If \code{TRUE}, attach all individual
#'   \code{cascade_analysis} run results to the output as \code{run_results}.
#'   Default \code{FALSE}.
#'
#' @return A list of class \code{"cascade_pipeline"} containing:
#'   \itemize{
#'     \item \code{mode}: \code{"full"} or \code{"scaled"}.
#'     \item \code{summary}: Mean layer summary table (tibble with
#'       \code{layer_knitting}, \code{layer_bridging}, \code{layer_channeling},
#'       \code{layer_reaching}, \code{layer_score}, \code{layer_number}).
#'     \item \code{summary_sd}: Per-column SD across runs (\code{NULL} in full
#'       mode).
#'     \item \code{cascade_score}: Gini-based cascade balance score.
#'     \item \code{estimated_edges}: Expected edge count before any scaling.
#'     \item \code{scale_used}: Scale factor applied (\code{1} in full mode).
#'     \item \code{n_runs}: Number of runs averaged.
#'     \item \code{node_data}: Per-node metrics (full mode only; \code{NULL}
#'       in scaled mode -- use \code{keep_runs = TRUE} to access individual
#'       run node data).
#'     \item \code{run_results}: Individual run results (only present when
#'       \code{keep_runs = TRUE}).
#'   }
#'
#' @seealso \code{\link{calculate_cascade}} for the underlying network analysis
#'   function.
#'
#' @references
#' Leng, Y., et al. (2018). The rippling effect of social influence via phone
#' communication network. In \emph{Complex Spreading Phenomena in Social
#' Systems} (pp. 323-333). Springer.
#'
#' @examples
#' \dontrun{
#' # 1. Generate a synthetic 3-layer network
#' # This simulates Core (L1) -> Partner (L2) -> Community (L3) flow
#' network_data <- generate_cascade_data(seed = 42)
#'
#' # 2. Run the cascade analysis
#' result <- analyze_cascade(network_data)
#'
#' # 3. Inspect the Global Balance Score (Sc)
#' # A high score (0.8+) implies influence is well-distributed across layers
#' print(result$cascade_score)
#'
#' # 4. View the Layer Summary
#' # Check if "Knitting" is high in Layer 1 vs "Reaching" in Layer 3
#' print(result$summary)
#' }
#'
#' @importFrom dplyr bind_rows group_by summarise across all_of mutate
#'   left_join case_when
#' @importFrom stats uniroot setNames sd
#' @export
analyze_cascade <- function(cascade_data,
                            max_edges    = 2e6,
                            target_nodes = 500,
                            n_runs       = 5,
                            seed         = NULL,
                            always_scale = FALSE,
                            keep_runs    = FALSE) {

  # ── Input normalisation ──────────────────────────────────────────────────────
  # Guard against multi-row data frames (e.g. passed directly from
  # generate_cascade_data()). as.list() on a data frame returns a list of
  # column vectors, so estimate_expected_edges() would receive vectors instead
  # of scalars, producing a vector-valued estimated_edges whose length > 1
  # makes the && chain in use_full return NA and crash if(use_full).
  if (is.data.frame(cascade_data) && nrow(cascade_data) > 1L) {
    warning(sprintf(
      "cascade_data has %d rows; only the first row will be used.",
      nrow(cascade_data)
    ))
    cascade_data <- cascade_data[1L, , drop = FALSE]
  }

  # ── Internal helpers ─────────────────────────────────────────────────────────

  # Estimate expected edge count analytically from survey parameters.
  # Uses E[edges] = deterministic edges + p * choose(n, 2) for random edge sets.
  estimate_expected_edges <- function(row) {
    row   <- as.list(row)
    n1t1  <- as.numeric(row$cascade_d1_people_1_1)
    n1t2  <- as.numeric(row$cascade_d1_people_2_1)
    l2t1  <- as.numeric(row$cascade_d2_people_1_1)
    l2t2  <- as.numeric(row$cascade_d2_people_2_1)
    l3pl2 <- as.numeric(row$cascade_d3_people)
    p22   <- as.numeric(row$cascade_d2_stats_1)
    p21   <- as.numeric(row$cascade_d2_stats_2)
    p33   <- as.numeric(row$cascade_d3_stats_1)
    p32   <- as.numeric(row$cascade_d3_stats_2)

    n1 <- n1t1 + n1t2
    n2 <- n1t1 * l2t1 + n1t2 * l2t2
    n3 <- n2 * l3pl2

    as.numeric(
      choose(n1, 2) +           # L1 clique
        n2 +                    # L1->L2 parent-child
        n3 +                    # L2->L3 parent-child
        choose(n2, 2) * p22 +  # L2-L2 probabilistic
        n2 * p21 +              # L2->L1 back-edges
        choose(n3, 2) * p33 +  # L3-L3 probabilistic
        n3 * p32                # L3->L2 back-edges
    )
  }

  # Find scale factor s in (0, 1] such that the scaled network has
  # approximately target_nodes total nodes. Solves the cubic
  #   n1*s + n2*s^2 + n3*s^3 = target
  # via uniroot() on the continuous approximation, then rounds params
  # with pmax floors to prevent layer collapse.
  find_scale_factor <- function(row, target) {
    row   <- as.list(row)
    n1t1  <- as.numeric(row$cascade_d1_people_1_1)
    n1t2  <- as.numeric(row$cascade_d1_people_2_1)
    l2t1  <- as.numeric(row$cascade_d2_people_1_1)
    l2t2  <- as.numeric(row$cascade_d2_people_2_1)
    l3pl2 <- as.numeric(row$cascade_d3_people)

    n1 <- n1t1 + n1t2
    n2 <- n1t1 * l2t1 + n1t2 * l2t2
    n3 <- n2 * l3pl2

    if (is.na(n1 + n2 + n3) || (n1 + n2 + n3 <= target)) return(1.0)

    f <- function(s) n1 * s + n2 * s^2 + n3 * s^3 - target

    tryCatch(
      stats::uniroot(f, interval = c(1e-4, 1.0), tol = 1e-4)$root,
      error = function(e) {
        warning("uniroot failed to converge; using s = 0.1 as fallback.")
        0.1
      }
    )
  }

  # Scale the five people parameters by s, with floors to prevent collapse:
  #   L1 type counts: pmax(2) -- clique needs >= 2 nodes to be meaningful
  #   All other counts: pmax(1) -- no layer can be empty
  # Probability parameters are unchanged.
  scale_cascade_data <- function(row, s) {
    out <- row
    out$cascade_d1_people_1_1 <- max(2L, round(as.numeric(row$cascade_d1_people_1_1) * s))
    out$cascade_d1_people_2_1 <- max(2L, round(as.numeric(row$cascade_d1_people_2_1) * s))
    out$cascade_d2_people_1_1 <- max(1L, round(as.numeric(row$cascade_d2_people_1_1) * s))
    out$cascade_d2_people_2_1 <- max(1L, round(as.numeric(row$cascade_d2_people_2_1) * s))
    out$cascade_d3_people     <- max(1L, round(as.numeric(row$cascade_d3_people)     * s))
    out
  }

  # Average layer summaries across runs; return list(mean, sd).
  # Rejoins the character layer_number label dropped by summarise().
  summarise_runs <- function(run_results) {
    all_summaries <- dplyr::bind_rows(
      lapply(seq_along(run_results), function(i) {
        x     <- run_results[[i]]$summary
        x$run <- i
        x
      })
    )

    numeric_cols <- names(all_summaries)[
      startsWith(names(all_summaries), "layer_") &
        vapply(all_summaries, is.numeric, logical(1))
    ]

    mean_df <- dplyr::group_by(all_summaries, layer) |>
      dplyr::summarise(
        dplyr::across(dplyr::all_of(numeric_cols), ~ mean(.x, na.rm = TRUE)),
        .groups = "drop"
      )

    sd_df <- dplyr::group_by(all_summaries, layer) |>
      dplyr::summarise(
        dplyr::across(dplyr::all_of(numeric_cols), ~ stats::sd(.x, na.rm = TRUE)),
        .groups = "drop"
      )

    layer_labels <- dplyr::mutate(
      data.frame(layer = 1:3),
      layer_number = paste0(layer, dplyr::case_when(
        layer == 1 ~ "st degree",
        layer == 2 ~ "nd degree",
        layer == 3 ~ "rd degree",
        TRUE       ~ "th degree"
      ))
    )

    mean_df <- dplyr::left_join(mean_df, layer_labels, by = "layer")
    list(mean = mean_df, sd = sd_df)
  }

  # ── Main routing logic ───────────────────────────────────────────────────────

  if (!is.null(seed)) set.seed(seed)

  estimated_edges <- estimate_expected_edges(cascade_data)

  use_full <- !is.na(estimated_edges) &&
    is.finite(estimated_edges)        &&
    estimated_edges <= max_edges      &&
    !always_scale

  # ── Full exact analysis ──────────────────────────────────────────────────────
  if (isTRUE(use_full)) {
    message(sprintf(
      "Running full exact analysis (~%.0f expected edges).",
      estimated_edges
    ))
    result                 <- calculate_cascade(build_network(cascade_data))
    result$mode            <- "full"
    result$estimated_edges <- estimated_edges
    result$scale_used      <- 1
    result$n_runs          <- 1
    result$summary_sd      <- NULL
    return(result)
  }

  # ── Scaled stochastic analysis ───────────────────────────────────────────────
  s           <- find_scale_factor(cascade_data, target = target_nodes)
  scaled_data <- scale_cascade_data(cascade_data, s)

  n1s <- scaled_data$cascade_d1_people_1_1 + scaled_data$cascade_d1_people_2_1
  n2s <- scaled_data$cascade_d1_people_1_1 * scaled_data$cascade_d2_people_1_1 +
    scaled_data$cascade_d1_people_2_1  * scaled_data$cascade_d2_people_2_1
  n3s <- n2s * scaled_data$cascade_d3_people

  message(sprintf(
    paste0(
      "Network too large (~%.3e expected edges).\n",
      "  Scaling to ~%d nodes (s = %.4f): %d L1 | %d L2 | %d L3.\n",
      "  Averaging %d stochastic runs."
    ),
    estimated_edges, n1s + n2s + n3s, s, n1s, n2s, n3s, n_runs
  ))

  run_results <- vector("list", n_runs)
  for (i in seq_len(n_runs)) {
    if (!is.null(seed)) set.seed(seed + i)
    run_results[[i]] <- calculate_cascade(build_network(scaled_data))
  }

  summaries     <- summarise_runs(run_results)
  cascade_score <- calculate_gini(summaries$mean$layer_score)

  out <- list(
    mode            = "scaled",
    estimated_edges = estimated_edges,
    scale_used      = s,
    n_runs          = n_runs,
    summary         = summaries$mean,
    summary_sd      = summaries$sd,
    cascade_score   = cascade_score,
    node_data       = NULL
  )

  if (isTRUE(keep_runs)) out$run_results <- run_results

  # Include "cascade_analysis" in the class vector so that visualize_cascade()
  # and other functions that check inherits(x, "cascade_analysis") work
  # transparently on pipeline results without modification.
  class(out) <- c("cascade_pipeline", "cascade_analysis", "list")
  out
}
