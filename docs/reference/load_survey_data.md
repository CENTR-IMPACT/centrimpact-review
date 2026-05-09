# Load and Clean CEnTR\*IMPACT Survey Data

Reads a CEnTR\*IMPACT survey CSV file, detects the export format (Google
Forms or Qualtrics), applies the appropriate header translation and
cleaning, and returns analysis-ready data frames.

## Usage

``` r
load_survey_data(file, survey = c("main", "alignment"))
```

## Arguments

- file:

  Character. Path to the CSV file to load.

- survey:

  Character. Which survey type to load. One of `"main"` or
  `"alignment"`.

## Value

For `survey = "main"`: a named list with elements:

- `indicators`: long-format indicators data frame for
  [`visualize_indicators()`](https://centr-impact.github.io/centrimpact-review/reference/visualize_indicators.md).

- `dynamics`: long-format dynamics data frame for
  [`analyze_dynamics()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_dynamics.md).

- `cascade`: wide-format cascade parameters data frame for
  [`analyze_cascade()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_cascade.md).

- `source`: the detected source format, `"google"` or `"qualtrics"`.

For `survey = "alignment"`: a long-format data frame for
[`analyze_alignment()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_alignment.md).

## Details

**Survey types:**

**`survey = "main"`** reads the primary CEnTR\*IMPACT survey containing
indicators, project dynamics, and cascade network parameters. The
function detects the export format automatically:

- **Google Forms**: identified by the presence of a `Timestamp` column.
  Verbose question-text headers are translated to compact variable
  names, `dynamics_selection` (absent from the form) is inserted as
  `NA`, and cascade probability fields are rescaled from the 1–10
  integer scale to \\\[0, 1\]\\.

- **Qualtrics**: identified by the presence of Qualtrics system columns
  (`StartDate`, `ResponseId`, etc.). System meta columns, descriptor
  rows, and `_selection` columns are removed. The `" Applicability"`
  suffix is stripped from rating values and the `"Not Applicabie"` typo
  is corrected.

Returns a named list with three analysis-ready data frames:
`indicators`, `dynamics`, and `cascade`.

**`survey = "alignment"`** reads the alignment survey containing
researcher and community partner ratings across eight partnership
factors. Qualtrics system columns and descriptor rows are removed when
present. Returns a single long-format data frame ready for
[`analyze_alignment()`](https://centr-impact.github.io/centrimpact-review/reference/analyze_alignment.md).

**Multiple rows:** For both survey types and both formats, if more than
one data row is present after cleaning, only the last row is kept. This
handles Qualtrics exports that include preview or test responses before
the final submission.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load the main survey (auto-detects Google Forms or Qualtrics format)
survey <- load_survey_data("data/mhfa_main.csv", survey = "main")

# Access the ready-to-use sub-frames
indicators_data <- survey$indicators
dynamics_data   <- survey$dynamics
cascade_data    <- survey$cascade

# Load the alignment survey
alignment_data <- load_survey_data("data/mhfa_alignment.csv", survey = "alignment")
} # }
```
