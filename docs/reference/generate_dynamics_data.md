# Generate Project Dynamics Data

Generates synthetic data to simulate the "Dynamics" of a collaborative
project—specifically its **Developmental Balance**—as defined in the
CEnTR\*IMPACT framework (Price, 2024).

## Usage

``` r
generate_dynamics_data(
  seed = Sys.time(),
  exclude = NULL,
  na_prob = 0.05,
  weight_set = c(0.78, 0.84, 0.9, 0.95, 1),
  domain_variance = FALSE
)
```

## Arguments

- seed:

  Integer or POSIXct. The seed for random number generation to ensure
  reproducibility. Defaults to
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

- exclude:

  Character vector. A list of Domain names to exclude from the dataset
  (e.g., `c("Contexts")`).

- na_prob:

  Numeric. The probability (0 to 1) that a `weight` value will be
  replaced with `NA`. Defaults to 0.05.

- weight_set:

  Numeric vector. The pool of numbers from which weights are sampled.
  Defaults to `c(0.78, 0.84, 0.90, 0.95, 1.00)`.

- domain_variance:

  Logical. If `TRUE`, introduces strong bias per Domain to ensure their
  averages differ significantly. Defaults to `FALSE`.

## Value

A data frame with columns:

- `domain`: The framework domain.

- `dimension`: The specific dimension within the domain.

- `salience`: A randomly assigned importance score (from 0.2 to 1.0).

- `weight`: A sampled intensity score based on the `weight_set`.

## Details

**Controlling Variance:** If `domain_variance = TRUE`, the function
applies **Hyper-Polarized Sampling**. It forces each Domain to choose a
"performance tier" (Low, High, or Mixed) with specific probabilities
(Low: 45%, High: 45%, Mixed: 10%).

- **Low Tier:** Samples weights only from the bottom 2 values of the
  provided `weight_set`.

- **High Tier:** Samples weights only from the top 2 values of the
  provided `weight_set`.

This maximizes the mathematical spread between domains, making it useful
for testing sensitivity or visualizing inequality in the Dynamics
scoring.

**Schema Structure:** The function uses a hardcoded schema representing
the 5 core domains of the framework:

- Contexts (4 dimensions)

- Partnerships (4 dimensions)

- Research (5 dimensions)

- Learning (4 dimensions)

- Outcomes (4 dimensions)

## Examples

``` r
# 1. Generate standard data
df_std <- generate_dynamics_data(seed = 123)

# 2. Generate "Unbalanced" data (High Variance)
# This is useful for testing low Balance Scores (Sd)
df_var <- generate_dynamics_data(seed = 123, domain_variance = TRUE)

# 3. Generate data with custom weights and no missing values
df_custom <- generate_dynamics_data(
  na_prob = 0,
  weight_set = c(0.1, 0.5, 0.9)
)
```
