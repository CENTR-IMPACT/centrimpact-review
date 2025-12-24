# Analyze Project Dynamics

Implements the "Dynamics" component of the CEnTR\*IMPACT framework
(Price, 2024). This function processes multidimensional assessment data
to calculate domain-level scores using geometric means and computes a
"Balance Score" (\\S_d\\) using the Gini coefficient. It is designed to
measure the equitable distribution of effort and impact across the core
domains of the CBPR Framework (Wallerstein & Duran, 2010; Wallerstein,
et al., 2020).

## Usage

``` r
analyze_dynamics(dynamics_df)
```

## Arguments

- dynamics_df:

  A data frame containing the assessment data. Required columns:

  - `domain`: Character or Factor. The broader category (e.g.,
    "Partnerships").

  - `dimension`: Character or Factor. The specific metric (e.g.,
    "Trust").

  - `salience`: Numeric. The importance of the dimension. Must be \\0 \<
    x \le 1\\.

  - `weight`: Numeric. The observed intensity or presence. Must be \\0
    \< x \le 1\\.

## Value

An object of class `dynamics_analysis` containing:

- `dynamics_df`: The processed input data frame with added
  `dimension_score`.

- `domain_df`: A summary data frame with aggregated scores per domain.

- `dynamics_score`: A single numeric value representing the Balance
  Score (\\S_d\\), where 1 indicates perfect balance.

## Details

The CEnTR\*IMPACT framework uses this analysis to quantify
"Developmental Balance." A higher Balance Score indicates that the
project is maintaining a healthy equilibrium across its various
dimensions, rather than over-indexing on just one area at the expense of
others.

**The Scoring Process:**

1.  **Dimension Scoring:** Calculated as the geometric mean of weight
    and salience. \$\$Score\_{dim} = \sqrt{Weight \times Salience}\$\$

2.  **Domain Scoring:** Aggregates dimension scores within each domain
    using the geometric mean.

3.  **Dynamics Scoring:** Calculated based on the inequality of domain
    scores. \$\$S_d = 1 - Gini(Score\_{domains})\$\$

**Dynamics Score Interpretation:** The following rule of thumb (Haddad
et al., 2024; Wang et al., 2020) is used to interpret the Dynamics Score
(\\S_d\\):

- \\S_d \< 0.50\\: **Very Low Balance**

- \\0.50 \le S_d \< 0.59\\: **Low Balance**

- \\0.60 \le S_d \< 0.69\\: **Moderate Balance**

- \\0.70 \le S_d \le 0.79\\: **High Balance**

- \\S_d \ge 0.80\\: **Very High Balance**

**Handling Missing Data:** The function is permissive with partial
datasets. If a domain is included in the input but contains `NA` values
for weights or salience, it is retained in the output. However, if
sufficient data is missing to prevent calculation, the score will be
`NaN`.

## References

Haddad, C. N., Mahler, D. G., Diaz-Bonilla, C., Hill, R., Lakner, C., &
Lara Ibarra, G. (2024). *The World Bank's New Inequality Indicator: The
Number of Countries with High Inequality*. Washington, DC: World Bank.
[doi:10.1596/41687](https://doi.org/10.1596/41687)

Price, J. F. (2024). *CEnTR\*IMPACT: Community Engaged and
Transformative Research – Inclusive Measurement of Projects & Community
Transformation* (CUMU-Collaboratory Fellowship Report). Coalition of
Urban and Metropolitan Universities.

Wallerstein, N., & Duran, B. (2010). Community-Based Participatory
Research Contributions to Intervention Research: The Intersection of
Science and Practice to Improve Health Equity. *American Journal of
Public Health*, 100(S1), S40–S46.
[doi:10.2105/AJPH.2009.184036](https://doi.org/10.2105/AJPH.2009.184036)

Wallerstein, N., et al. (2020). Engage for Equity: A Long-Term Study of
Community-Based Participatory Research and Community-Engaged Research
Practices and Outcomes. *Health Education & Behavior*, 47(3), 380–390.
[doi:10.1177/1090198119897075](https://doi.org/10.1177/1090198119897075)

Wang, H.-Y., Chou, W., Shao, Y., & Chien, T.-W. (2020). Comparison of
Ferguson’s delta and the Gini coefficient used for measuring the
inequality of data related to health quality of life outcomes. *Health
and Quality of Life Outcomes*, 18(1), 111.
[doi:10.1186/s12955-020-01356-6](https://doi.org/10.1186/s12955-020-01356-6)

## Examples

``` r
# 1. Generate synthetic data using the built-in generator
# We use a fixed seed to ensure the example is reproducible
df <- generate_dynamics_data(seed = 123)

# 2. Run the Dynamics analysis
result <- analyze_dynamics(df)

# 3. Inspect the global Balance Score (Sd)
# A score closer to 1.0 indicates high balance across domains
print(result$dynamics_score)
#> [1] 0.9763636

# 4. Inspect the domain-level scores
print(result$domain_df)
#> # A tibble: 5 × 2
#>   domain       domain_score
#>   <ord>               <dbl>
#> 1 Contexts             0.45
#> 2 Partnerships         0.45
#> 3 Research             0.44
#> 4 Learning             0.46
#> 5 Outcomes             0.4 

# 5. Example with high-variance data (to show lower balance)
df_unbalanced <- generate_dynamics_data(seed = 123, domain_variance = TRUE)
result_unbalanced <- analyze_dynamics(df_unbalanced)
print(result_unbalanced$dynamics_score)
#> [1] 0.9291139
```
