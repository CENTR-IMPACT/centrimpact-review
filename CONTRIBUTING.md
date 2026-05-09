# Contributing to centrimpact

Thank you for your interest in contributing to the `centrimpact` package! We welcome contributions from the community to help improve this tool for analyzing and visualizing community-engaged research metrics.

Confirm sections: https://github.com/ropensci/skimr/blob/main/.github/CONTRIBUTING.md#understanding-the-scope-of-skimr e.g., "Scope" seems to be missing.

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](https://ropensci.org/code-of-conduct/). By participating in this project, you agree to abide by its terms.

## How to Contribute

### Reporting Issues

Before creating a new issue, please:

1. Check if a similar issue already exists in the [issue tracker](https://github.com/CENTR-IMPACT/centrimpact/issues).
2. Make sure you're using the latest version of the package.
3. Provide a minimal, reproducible example if reporting a bug.

When creating an issue, please use one of our issue templates if available.

### Making Changes

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally.
3. Create a new **branch** for your changes:
   ```bash
   git checkout -b my-feature-branch
   ```
4. **Commit** your changes with clear, descriptive commit messages.
5. **Push** your branch to GitHub.
6. Open a **pull request** (PR) against the `main` branch.

### Development Setup

To set up your development environment:

1. Install the development version of the package:
   ```r
   # Install devtools if not already installed
   if (!require("devtools")) install.packages("devtools")
   
   # Install development dependencies
   devtools::install_dev_deps()
   
   # Load the package for development
   devtools::load_all()
   ```

2. Run tests to ensure everything works:
   ```r
   devtools::test()
   ```

3. Check package with `R CMD check`:
   ```r
   devtools::check()
   ```

### Code Style

Please follow these coding conventions:

- Follow the [tidyverse style guide](https://style.tidyverse.org/).
- Use `roxygen2` for documentation.
- Write tests for new functionality using `testthat`.
- Keep lines under 80 characters where possible.
- Use meaningful variable and function names.

### Documentation

- Document all exported functions using `roxygen2`.
- Update the `NEWS.md` file with user-facing changes.
- Add examples to function documentation.
- Keep the README up to date.

### Testing

- Write tests for new functionality.
- Run tests with `devtools::test()`.
- Aim for good test coverage but focus on testing behavior, not implementation.

## Pull Request Process

1. Ensure your code passes all tests and `R CMD check` runs without errors or warnings.
2. Update the documentation if you've changed any functions or added new ones.
3. Update the `NEWS.md` file with a brief description of your changes.
4. If your PR fixes an issue, reference it in the PR description (e.g., "Fixes #123").
5. Ensure your code is well-documented and follows the project's coding style.

## Getting Help

If you have questions about contributing:

1. Check the [documentation](https://centr-impact.github.io/centrimpact/).
2. Search the [issue tracker](https://github.com/CENTR-IMPACT/centrimpact/issues).
3. Open a new issue if your question hasn't been asked before.

## Recognition

All contributors will be recognized in the package documentation. Significant contributions may qualify for co-authorship on relevant publications.

## Thank You!

Your contributions help make `centrimpact` better for everyone. Thank you for taking the time to contribute!
