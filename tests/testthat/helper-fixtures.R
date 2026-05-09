# ==============================================================================
# TEST FIXTURES
# ==============================================================================
# Loaded automatically by testthat before any test file runs.
# All expensive computations (network building, SNA metrics) happen once here
# so individual test files can reuse results without re-running generators.

# ── Generate data ─────────────────────────────────────────────────────────────
cascade_params   <- generate_cascade_data(seed = 42)
alignment_data   <- generate_alignment_data(seed = 42)
dynamics_data    <- generate_dynamics_data(seed = 42)
indicators_data  <- generate_indicators_data(seed = 42)

# ── Run analyses ──────────────────────────────────────────────────────────────
cascade_result   <- analyze_cascade(cascade_params, seed = 42)
alignment_result <- analyze_alignment(alignment_data)
dynamics_result  <- analyze_dynamics(dynamics_data)
