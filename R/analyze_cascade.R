#' Analyze Project Cascade Effects
#'
#' @description
#' Performs a comprehensive analysis of a network's "Cascade" structure to measure
#' localized influence. Based on the theory that direct personal influence typically
#' extends to "three degrees of impact" (Christakis & Fowler, 2009), this function
#' examines potential cascading effects across these layers using the formula:
#' \deqn{I = \gamma (\alpha L + \beta G) + \lambda T}
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
#'   \item \emph{Metrics:} Structural Holes (Constraint) + Betweenness Centrality.
#'   \item \emph{Interpretation:} High scores indicate key "brokers" connecting silos.
#' }
#'
#' \strong{3. Channeling (Flow & Transmission):}
#' Measures the efficiency of information flow and resource distribution.
#' \itemize{
#'   \item \emph{Metrics:} Local Betweenness + Alpha Centrality.
#'   \item \emph{Interpretation:} High scores indicate effective pipelines for moving resources.
#' }
#'
#' \strong{4. Reaching (Access & Inclusion):}
#' Measures the extent of the network's periphery and accessibility.
#' \itemize{
#'   \item \emph{Metrics:} Clustering Coefficient + Harmonic Centrality.
#'   \item \emph{Interpretation:} High scores indicate an inclusive network with reduced barriers.
#' }
#'
#' \strong{Cascade Score Interpretation:}
#' The "Cascade Balance Score" (\eqn{S_c}) is calculated using the inverse Gini coefficient
#' of layer-level scores to determine if influence is effectively distributed across
#' the "three degrees" or concentrated at the top.
#' \itemize{
#'   \item \eqn{S_c < 0.50}: \strong{Very Low Balance} (Core-dominated)
#'   \item \eqn{0.50 \le S_c < 0.59}: \strong{Low Balance}
#'   \item \eqn{0.60 \le S_c < 0.69}: \strong{Moderate Balance}
#'   \item \eqn{0.70 \le S_c \le 0.79}: \strong{High Balance}
#'   \item \eqn{S_c \ge 0.80}: \strong{Very High Balance} (Equitable distribution)
#' }
#'
#' @param network_df A data frame representing the edge list. Required columns:
#'   \itemize{
#'     \item \code{from}: Source node identifier.
#'     \item \code{to}: Target node identifier.
#'     \item \code{layer}: Integer (1-4). The "degree" of the interaction (1 = Core, 2 = Partners, 3 = Community, 4 = Distant).
#'   }
#' @param alpha_parameter Numeric. Damping factor for Alpha Centrality (defaults to 0.9).
#'
#' @return An object of class \code{cascade_analysis} containing:
#'   \itemize{
#'     \item \code{cascade_score}: The global Balance Score (\eqn{S_c}, 0-1).
#'     \item \code{summary}: A summary table aggregating roles by Layer (Degree).
#'     \item \code{node_data}: Detailed metrics for every node.
#'     \item \code{topology_score}: Baseline topological health score.
#'   }
#'
#' @references
#' Christakis, N. A., & Fowler, J. H. (2009). \emph{Connected: The Surprising Power of Our Social Networks and How They Shape Our Lives}. Little, Brown Spark.
#'
#' Haddad, C. N., et al. (2024). \emph{The World Bank's New Inequality Indicator}. World Bank. \doi{10.1596/41687}
#'
#' Long, J. C., Cunningham, F. C., & Braithwaite, J. (2013). Bridges, brokers and boundary spanners in collaborative networks: a systematic review. \emph{BMC Health Services Research}, 13, 158. \doi{10.1186/1472-6963-13-158}
#'
#' Price, J. F. (2024). \emph{CEnTR*IMPACT: Community Engaged and Transformative Research – Inclusive Measurement of Projects & Community Transformation}. CUMU.
#'
#' Wang, H.-Y., et al. (2020). Comparison of Ferguson’s delta and the Gini coefficient used for measuring the inequality of data. \emph{Health and Quality of Life Outcomes}, 18(1), 111.
#'
#' @seealso
#' \code{\link{generate_cascade_data}} to simulate the network data used in these examples.
#'
#' @examples
#' # 1. Generate a synthetic 3-layer network
#' # This simulates Core (L1) -> Partner (L2) -> Community (L3) flow
#' network_data <- generate_cascade_data(seed = 42)
#'
#' # 2. Run the cascade analysis
#' result <- analyze_cascade(network_data)
#'
#' # 3. Inspect the Global Balance Score (Sd)
#' # A high score (0.8+) implies influence is well-distributed across layers
#' print(result$cascade_score)
#'
#' # 4. View the Layer Summary
#' # Check if "Knitting" is high in Layer 1 vs "Reaching" in Layer 3
#' print(result$summary)
#'
#' @importFrom igraph graph_from_data_frame V as_adjacency_matrix global_efficiency betweenness eigen_centrality transitivity harmonic_centrality alpha_centrality constraint cluster_walktrap membership
#' @importFrom sna connectedness hierarchy lubness
#' @importFrom dplyr select mutate group_by summarize case_when n
#' @export
analyze_cascade <- function(network_df, alpha_parameter = 0.9) {
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

  w_alpha <- 0.4
  w_beta <- 0.3
  w_lambda <- 0.3

  # ===========================================================================
  # CALCULATE TOPOLOGY METRICS
  # ===========================================================================

  topo_efficiency <- igraph::global_efficiency(g)
  topo_connect    <- sna::connectedness(adj_mat)
  topo_hierarchy  <- 1 - sna::hierarchy(adj_mat)
  topo_lubness    <- 1 - sna::lubness(adj_mat)

  topo_vals <- c(topo_efficiency, topo_connect, topo_hierarchy, topo_lubness)
  topo_score <- mean(topo_vals[is.finite(topo_vals)], na.rm = TRUE) * w_lambda

  # ===========================================================================
  # CALCULATE LOCAL METRICS
  # ===========================================================================

  wt <- igraph::cluster_walktrap(g)
  local_community <- normalize(as.numeric(igraph::membership(wt)))

  local_crossclique <- normalize(1 - igraph::constraint(g))
  local_crossclique[is.na(local_crossclique)] <- 0

  local_clustcoef <- normalize(igraph::transitivity(g, type = "local"))
  local_clustcoef[is.na(local_clustcoef)] <- 0

  local_between <- normalize(igraph::betweenness(g, normalized = TRUE))

  # ===========================================================================
  # CALCULATE GLOBAL METRICS
  # ===========================================================================

  global_eigen    <- normalize(igraph::eigen_centrality(g)$vector)
  global_between  <- normalize(igraph::betweenness(g, normalized = TRUE))
  global_harmonic <- normalize(igraph::harmonic_centrality(g))

  global_alpha <- tryCatch({
    normalize(igraph::alpha_centrality(g, alpha = alpha_parameter))
  }, error = function(e) { rep(0, length(global_eigen)) })

  # ===========================================================================
  # CALCULATE INFLUENCE
  # ===========================================================================

  results_df <- data.frame(
    name = igraph::V(g)$name,
    layer = igraph::V(g)$layer,
    gamma = igraph::V(g)$gamma
  )

  results_df$knitting <- normalize(
    results_df$gamma * (w_alpha * local_community + w_beta * global_eigen) + topo_score
  )
  results_df$bridging <- normalize(
    results_df$gamma * (w_alpha * local_crossclique + w_beta * global_between) + topo_score
  )
  results_df$channeling <- normalize(
    results_df$gamma * (w_alpha * local_between + w_beta * global_alpha) + topo_score
  )
  results_df$reaching <- normalize(
    results_df$gamma * (w_alpha * local_clustcoef + w_beta * global_harmonic) + topo_score
  )

  results_df$composite_score <- rowMeans(results_df[, c("knitting", "bridging", "channeling", "reaching")])

  # ===========================================================================
  # AGGREGATE BY LAYER
  # ===========================================================================

  layer_summary <- results_df |>
    dplyr::group_by(layer) |>
    dplyr::summarize(
      count = dplyr::n(),
      gamma = mean(gamma),
      layer_knitting = mean(knitting),
      layer_bridging = mean(bridging),
      layer_channeling = mean(channeling),
      layer_reaching = mean(reaching),
      layer_score = mean(composite_score),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      layer_number = paste0(layer, dplyr::case_when(
        layer == 1 ~ "st degree",
        layer == 2 ~ "nd degree",
        layer == 3 ~ "rd degree",
        TRUE ~ "th degree"
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
    summary = layer_summary,
    node_data = results_df,
    cascade_score = cascade_balance,
    topology_score = topo_score
  )

  class(result) <- "cascade_analysis"
  return(result)
}
