# Getting Started with centrimpact

## Introduction

The `centrimpact` package provides tools for analyzing and visualizing
community-engaged research metrics based on the CEnTR\*IMPACT framework
(Price, 2024). This framework quantifies four critical dimensions of
community-engaged research that go beyond traditional academic metrics:

1.  **Alignment** - Shared vision between researchers and partners
2.  **Cascade Effects** - Ripple effects across social networks
3.  **Dynamics** - Quality of partnership processes
4.  **Indicators** - Traditional academic productivity markers

This vignette demonstrates the basic workflow for analyzing each
dimension and creating publication-ready visualizations.

## Installation

``` r
# Install from GitHub
devtools::install_github("CENTR-IMPACT/centrimpact-review")
```

``` r
library(centrimpact)
```

## Analyzing Project Alignment

The Alignment Score (Sa) quantifies consensus between researchers and
community partners across four key areas: Goals, Values, Roles, and
Resources. Higher scores indicate stronger shared vision.

### Generate and Analyze Data

``` r
# Generate example alignment data
alignment_data <- generate_alignment_data(seed = 36)

# View the structure
head(alignment_data)
#>   alignment       role rating
#> 1     Goals researcher   0.53
#> 2     Goals researcher   0.85
#> 3     Goals researcher   0.37
#> 4     Goals researcher   0.97
#> 5     Goals researcher   0.64
#> 6     Goals    partner   0.42

# Analyze alignment
alignment_results <- analyze_alignment(alignment_data)

# View results
print(alignment_results)
#> $table
#>     alignment partner researcher
#> 1  Activities   0.545       0.86
#> 2 Empowerment   0.780       0.70
#> 3       Goals   0.565       0.64
#> 4    Outcomes   0.765       0.77
#> 5     Outputs   0.730       0.69
#> 6   Resources   0.790       0.68
#> 7       Roles   0.730       0.71
#> 8      Values   0.735       0.56
#> 
#> $plot_data
#>      alignment       role    rating min_val max_val
#> 1   Activities    partner 0.5450000   0.545   0.545
#> 2   Activities researcher 0.8600000   0.860   0.860
#> 3  Empowerment    partner 0.7800000   0.780   0.780
#> 4  Empowerment researcher 0.7000000   0.700   0.700
#> 5        Goals    partner 0.5650000   0.565   0.565
#> 6        Goals researcher 0.6400000   0.640   0.640
#> 7     Outcomes    partner 0.7650000   0.765   0.765
#> 8     Outcomes researcher 0.7700000   0.770   0.770
#> 9      Outputs    partner 0.7300000   0.730   0.730
#> 10     Outputs researcher 0.6900000   0.690   0.690
#> 11   Resources    partner 0.7900000   0.790   0.790
#> 12   Resources researcher 0.6800000   0.680   0.680
#> 13       Roles    partner 0.7300000   0.730   0.730
#> 14       Roles researcher 0.7100000   0.710   0.710
#> 15      Values    partner 0.7350000   0.735   0.735
#> 16      Values researcher 0.5600000   0.560   0.560
#> 17  Activities    overall 0.6846167      NA      NA
#> 18 Empowerment    overall 0.7389181      NA      NA
#> 19       Goals    overall 0.6013319      NA      NA
#> 20    Outcomes    overall 0.7674959      NA      NA
#> 21     Outputs    overall 0.7097183      NA      NA
#> 22   Resources    overall 0.7329393      NA      NA
#> 23       Roles    overall 0.7199306      NA      NA
#> 24      Values    overall 0.6415606      NA      NA
#> 
#> $icc
#>  Single Score Intraclass Correlation
#> 
#>    Model: twoway 
#>    Type : agreement 
#> 
#>    Subjects = 8 
#>      Raters = 2 
#>    ICC(A,1) = -0.383
#> 
#>  F-Test, H0: r0 = 0 ; H1: r0 > 0 
#>   F(7,6.99) = 0.515 , p = 0.799 
#> 
#>  95%-Confidence Interval for ICC Population Values:
#>   -1.05 < ICC < 0.473
#> 
#> $alignment_score
#> [1] 0.3829787
#> 
#> attr(,"class")
#> [1] "alignment_analysis"
```

### Visualize with Slopegraph

The slopegraph shows how researcher and partner ratings compare across
domains:

``` r
# Create slopegraph visualization
plot_slopegraph <- visualize_alignment(alignment_results)
print(plot_slopegraph)
```

![](getting-started_files/figure-html/alignment-slopegraph-1.png)

### Visualize with Abacus Plot

The abacus plot provides an alternative view of alignment patterns:

``` r
# Create abacus plot
plot_abacus <- visualize_abacus(alignment_results)
print(plot_abacus)
```

![](getting-started_files/figure-html/alignment-abacus-1.png)

## Analyzing Cascade Effects

The Cascade Effects Score (Sc) quantifies how information and power
distribute across three degrees of separation from core participants,
based on social network analysis principles.

### Generate and Analyze Data

``` r
# Generate example cascade data
cascade_data <- generate_cascade_data(seed = 36)

# View the structure
head(cascade_data)
#>   from to layer
#> 1    1  2     1
#> 2    1  3     1
#> 3    1  4     1
#> 4    1  5     1
#> 5    1  6     1
#> 6    1  7     1

# Analyze cascade effects
cascade_results <- analyze_cascade(cascade_data)

# View results
print(cascade_results)
#> $summary
#> # A tibble: 3 × 9
#>   layer count gamma layer_knitting layer_bridging layer_channeling
#>   <dbl> <int> <dbl>          <dbl>          <dbl>            <dbl>
#> 1     1     7  0.9           0.934         0.755             0.634
#> 2     2    15  0.5           0.216         0.425             0.290
#> 3     3    20  0.45          0.346         0.0797            0.145
#> # ℹ 3 more variables: layer_reaching <dbl>, layer_score <dbl>,
#> #   layer_number <chr>
#> 
#> $node_data
#>    name layer gamma   knitting  bridging channeling    reaching composite_score
#> 1     1     1  0.90 0.92872390 0.8501862 0.81471414 0.889305816      0.87073251
#> 2     2     1  0.90 0.96660721 0.8743880 0.79520506 0.801438399      0.85940967
#> 3     3     1  0.90 0.88548453 0.5963235 0.49237188 1.000000000      0.74354498
#> 4     4     1  0.90 0.96234601 1.0000000 1.00000000 0.815509694      0.94446393
#> 5     5     1  0.90 0.90987483 0.7786569 0.52925401 0.868198874      0.77149616
#> 6     6     1  0.90 1.00000000 0.6689262 0.48418729 0.827902856      0.74525408
#> 7     7     1  0.90 0.88593073 0.5148500 0.32185391 0.985928705      0.67714084
#> 8     8     2  0.50 0.19962967 0.4256315 0.30868732 0.114133834      0.26202058
#> 9     9     2  0.50 0.19634412 0.6073807 0.48254809 0.230795289      0.37926706
#> 10   10     2  0.50 0.00000000 0.0000000 0.20299515 0.059412133      0.06560182
#> 11   11     2  0.50 0.35183341 0.5073361 0.26402166 0.172764228      0.32398885
#> 12   12     2  0.50 0.22889525 0.5659467 0.50109325 0.282363977      0.39457479
#> 13   13     2  0.50 0.30187055 0.5385042 0.36349653 0.194262039      0.34953332
#> 14   14     2  0.50 0.40085099 0.5467642 0.40712653 0.172764228      0.38187649
#> 15   15     2  0.50 0.45604710 0.5750163 0.46421369 0.178627267      0.41847608
#> 16   16     2  0.50 0.15932011 0.3440167 0.26304728 0.248141199      0.25363132
#> 17   17     2  0.50 0.11150587 0.2874387 0.00000000 0.129768605      0.13217829
#> 18   18     2  0.50 0.14772716 0.4198883 0.22952173 0.119996873      0.22928351
#> 19   19     2  0.50 0.14438730 0.3392905 0.17788257 0.228597735      0.22253952
#> 20   20     2  0.50 0.18300776 0.3591698 0.19122450 0.313524078      0.26173154
#> 21   21     2  0.50 0.22504193 0.5026611 0.39520427 0.314189424      0.35927419
#> 22   22     2  0.50 0.13367106 0.3623489 0.09733949 0.153220763      0.18664506
#> 23   23     3  0.45 0.08149091 0.0000000 0.14339258 0.000000000      0.05622087
#> 24   24     3  0.45 0.34044001 0.1920602 0.09185278 0.033771107      0.16453102
#> 25   25     3  0.45 0.55566176 0.0000000 0.13067468 0.039047842      0.18134607
#> 26   26     3  0.45 0.40639828 0.2062014 0.23480648 0.067893996      0.22882503
#> 27   27     3  0.45 0.60669005 0.0000000 0.13067468 0.039047842      0.19410314
#> 28   28     3  0.45 0.18880460 0.0000000 0.03719723 0.026031895      0.06300843
#> 29   29     3  0.45 0.18880460 0.0000000 0.03719723 0.026031895      0.06300843
#> 30   30     3  0.45 0.66212792 0.0000000 0.17974928 0.047490619      0.22234195
#> 31   31     3  0.45 0.46142036 0.2064825 0.24770699 0.066838649      0.24561212
#> 32   32     3  0.45 0.34580239 0.2082577 0.09042981 0.058044090      0.17563349
#> 33   33     3  0.45 0.13868872 0.0000000 0.09755083 0.034122889      0.06759061
#> 34   34     3  0.45 0.23879243 0.0000000 0.12351274 0.023921201      0.09655659
#> 35   35     3  0.45 0.23879243 0.0000000 0.12351274 0.023921201      0.09655659
#> 36   36     3  0.45 0.49978507 0.1905862 0.21982938 0.053822702      0.24100584
#> 37   37     3  0.45 0.28961725 0.0000000 0.13767632 0.026735460      0.11350726
#> 38   38     3  0.45 0.39692160 0.2009160 0.23108297 0.059099437      0.22200500
#> 39   39     3  0.45 0.28961725 0.0000000 0.13767632 0.026735460      0.11350726
#> 40   40     3  0.45 0.03111227 0.0000000 0.08578924 0.002462477      0.02984100
#> 41   41     3  0.45 0.44518746 0.1845538 0.16751661 0.030253283      0.20687779
#> 42   42     3  0.45 0.51246390 0.2042615 0.25140890 0.070708255      0.25971064
#> 
#> $cascade_score
#> [1] 0.6493745
#> 
#> $topology_score
#> [1] 0.180723
#> 
#> attr(,"class")
#> [1] "cascade_analysis"
```

### Visualize with Racetrack Plot

The radial bar chart (“racetrack plot”) shows distribution across
network degrees:

``` r
# Create cascade visualization
plot_cascade <- visualize_cascade(cascade_results)
print(plot_cascade)
```

![](getting-started_files/figure-html/cascade-plot-1.png)

## Analyzing Project Dynamics

The Project Dynamics Score (Sd) quantifies how well a project follows
Community-Based Participatory Research (CBPR) principles (Wallerstein &
Duran, 2010; Wallerstein et al., 2020).

### Generate and Analyze Data

``` r
# Generate example dynamics data
dynamics_data <- generate_dynamics_data(seed = 36)

# View the structure
head(dynamics_data)
#>     domain dimension salience weight
#> 1 Contexts Challenge      0.2   0.78
#> 2 Contexts Challenge      0.8   0.84
#> 3 Contexts Challenge      0.6   0.95
#> 4 Contexts Challenge      0.4   1.00
#> 5 Contexts Challenge      1.0   1.00
#> 6 Contexts Diversity      0.4   0.84

# Analyze project dynamics
dynamics_results <- analyze_dynamics(dynamics_data)

# View results
print(dynamics_results)
#> $dynamics_df
#> # A tibble: 103 × 7
#>    domain dimension salience weight dimension_value dimension_score domain_score
#>    <chr>  <chr>        <dbl>  <dbl>           <dbl>           <dbl>        <dbl>
#>  1 Conte… Challenge      0.2   0.78           0.156            0.47         0.45
#>  2 Conte… Challenge      0.8   0.84           0.672            0.47         0.45
#>  3 Conte… Challenge      0.6   0.95           0.57             0.47         0.45
#>  4 Conte… Challenge      0.4   1              0.4              0.47         0.45
#>  5 Conte… Challenge      1     1              1                0.47         0.45
#>  6 Conte… Diversity      0.4   0.84           0.336            0.42         0.45
#>  7 Conte… Diversity      0.2   0.9            0.18             0.42         0.45
#>  8 Conte… Diversity      0.6   0.78           0.468            0.42         0.45
#>  9 Conte… Diversity      1     0.78           0.78             0.42         0.45
#> 10 Conte… Diversity      0.8   0.78           0.624            0.42         0.45
#> # ℹ 93 more rows
#> 
#> $domain_df
#> # A tibble: 5 × 2
#>   domain       domain_score
#>   <ord>               <dbl>
#> 1 Contexts             0.45
#> 2 Partnerships         0.46
#> 3 Research             0.44
#> 4 Learning             0.46
#> 5 Outcomes             0.44
#> 
#> $dynamics_score
#> [1] 0.9893333
#> 
#> attr(,"class")
#> [1] "dynamics_analysis"
```

### Visualize with Rose Chart

The rose chart displays dynamics across CBPR dimensions:

``` r
# Create dynamics visualization
plot_dynamics <- visualize_dynamics(dynamics_results)
print(plot_dynamics)
```

![](getting-started_files/figure-html/dynamics-plot-1.png)

## Visualizing Project Indicators

Project Indicators capture traditional academic metrics. These require
no separate analysis function as they represent direct counts.

### Generate and Visualize Data

``` r
# Generate example indicators data
indicators_data <- generate_indicators_data(seed = 36)

# View the structure
head(indicators_data)
#>              indicator value
#> 1   Community Partners    20
#> 2     Engagement Hours    13
#> 3   Individuals Served     2
#> 4 Infrastructure Tools     3
#> 5      Output Products    24
#> 6    Students Involved    22

# Create horizontal bubble chart
plot_indicators <- visualize_indicators(indicators_data)
print(plot_indicators)
```

![](getting-started_files/figure-html/indicators-plot-1.png)

## Customizing Visualizations

All visualization functions return `ggplot2` objects, allowing for
further customization:

``` r
library(ggplot2)

# Customize alignment plot
plot_slopegraph +
  labs(title = "Researcher-Partner Alignment",
       subtitle = "Community Health Equity Project") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))
```

![](getting-started_files/figure-html/customize-example-1.png)

## Complete Workflow Example

Here’s a complete workflow analyzing all four dimensions for a single
project:

``` r
# 1. Alignment
alignment_data <- generate_alignment_data()
alignment_results <- analyze_alignment(alignment_data)
alignment_plot <- visualize_alignment(alignment_results)

# 2. Cascade Effects
cascade_data <- generate_cascade_data()
cascade_results <- analyze_cascade(cascade_data)
cascade_plot <- visualize_cascade(cascade_results)

# 3. Dynamics
dynamics_data <- generate_dynamics_data()
dynamics_results <- analyze_dynamics(dynamics_data)
dynamics_plot <- visualize_dynamics(dynamics_results)

# 4. Indicators
indicators_data <- generate_indicators_data()
indicators_plot <- visualize_indicators(indicators_data)

# Display alignment as example
print(alignment_plot)
```

![](getting-started_files/figure-html/complete-workflow-1.png)

## Interpreting Results

### Alignment Scores

- **0.80-1.00**: Strong alignment; shared vision well-established
- **0.60-0.79**: Moderate alignment; some areas need attention
- **Below 0.60**: Low alignment; significant discussion needed

### Cascade Scores

Higher scores indicate information and power successfully distributed
across network degrees, suggesting sustainable community impact.

### Dynamics Scores

Scores reflect adherence to CBPR principles. Track changes over time to
assess partnership development.

### Indicators

Contextualize traditional metrics within alignment, cascade, and
dynamics scores for comprehensive impact assessment.

## Preparing Your Own Data

Each analysis function expects data in specific formats. Use the
`generate_*_data()` functions as templates:

``` r
# Examine expected structure
str(generate_alignment_data())
#> 'data.frame':    184 obs. of  3 variables:
#>  $ alignment: chr  "Goals" "Goals" "Goals" "Goals" ...
#>  $ role     : chr  "researcher" "researcher" "researcher" "researcher" ...
#>  $ rating   : num  0.47 0.41 0.58 0.49 0.57 0.55 0.45 0.65 0.93 0.83 ...
str(generate_cascade_data())
#> 'data.frame':    15 obs. of  3 variables:
#>  $ from : int  1 1 2 1 2 2 3 4 4 5 ...
#>  $ to   : int  2 3 3 4 5 6 7 8 9 10 ...
#>  $ layer: num  1 1 1 2 2 2 2 3 3 3 ...
str(generate_dynamics_data())
#> 'data.frame':    103 obs. of  4 variables:
#>  $ domain   : chr  "Contexts" "Contexts" "Contexts" "Contexts" ...
#>  $ dimension: chr  "Challenge" "Challenge" "Challenge" "Challenge" ...
#>  $ salience : num  1 0.4 0.2 0.8 0.6 1 0.8 0.4 0.6 0.2 ...
#>  $ weight   : num  1 1 0.84 0.84 0.84 0.9 0.78 0.78 0.78 0.95 ...
str(generate_indicators_data())
#> 'data.frame':    7 obs. of  2 variables:
#>  $ indicator: chr  "Community Partners" "Engagement Hours" "Individuals Served" "Infrastructure Tools" ...
#>  $ value    : int  24 23 20 9 4 26 12
```

## Next Steps

- See
  [`?analyze_alignment`](https://centr-impact.github.io/centrimpact-review/reference/analyze_alignment.md)
  for detailed parameter descriptions
- Explore
  [`?visualize_alignment`](https://centr-impact.github.io/centrimpact-review/reference/visualize_alignment.md)
  for customization options
- Review individual function documentation for each dimension
- Consult the CEnTR\*IMPACT framework report for theoretical foundations

## References

Price, J. F. (2024). *CEnTR*IMPACT: Community Engaged and Transformative
Research – Inclusive Measurement of Projects & Community
Transformation\* (CUMU-Collaboratory Fellowship Report). Coalition of
Urban and Metropolitan Universities.
<https://cumuonline.org/wp-content/uploads/2024-CUMU-Collaboratory-Fellowship-Report.pdf>

Wallerstein, N., & Duran, B. (2010). Community-Based Participatory
Research Contributions to Intervention Research: The Intersection of
Science and Practice to Improve Health Equity. *American Journal of
Public Health*, 100(S1), S40–S46.
<https://doi.org/10.2105/AJPH.2009.184036>

Wallerstein, N., et al. (2020). Engage for Equity: A Long-Term Study of
Community-Based Participatory Research and Community-Engaged Research
Practices and Outcomes. *Health Education & Behavior*, 47(3), 380–390.
<https://doi.org/10.1177/1090198119897075>
