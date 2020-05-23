
# obce-covid19

<!-- badges: start -->
<!-- badges: end -->

This repository contains code analysing Czech public finance data in order to understand the (potential) impact of COVID19 related measures on municipal budgets.

Outputs are published on https://obce-covid19.netlify.app/

## How it works

- `renv` is used to ensure exact reproducibility with respect to package version
  - at first project load, the right versions of the necessary packages should install automatically
  - all packages installed during work on the project are installed into a project-specific library (although they are not physically stored inside the project so they do not take up disk space)
  - anytime you install a new package, run `renv::snapshot()`
  - commit the `renv.lock` file alongside other scripts
- heavy data download and processing is done in separate R scripts which should only be run once, manually. `build.R` shows the order in which to run everything.
- all Rmarkdown files (except those whose names start with `_`) are turned into webpages using `rmarkdown::render_site()`. The result ends up in `docs` turned into a website with a navigation bar, all of which is set up in `_site.yml`. Together with generating Word docs, this can be done in `build.sh` on a UNIX-based machine.
- the resulting website is deployed to netlify using `netlify-cli`: https://obce-covid19.netlify.app/ (also done in `build.sh`.)
- `/docs` or `data-*` is never committed or pushed to Github
- public finance data is loaded and processed from the official [Státní pokladna system](https://monitor.statnipokladna.cz/) using the [`statnipokladna`](https://petrbouchal.github.io/statnipokladna/) package.

## What to do

### Data loading and processing

- all data is downloaded first and saved with minimal transformations in `data-input`
- also saved are subsets
- next, the data is summarised/subset and saved in `data-processed`
- these data preparation scripts should only be run once per machine to save time
- only add codelists when you reached the right subset/level and/or aggregation
- but make sure you do not aggregate too much, e.g. to get correct summaries across paragraf (odvětvové členění), you also need the polozka codelist (druhové členění) joined to the data.

### Scenario generation

see R script numbered 7-9

### Document generation

All documents will be generated properly by running `rmarkdown::render_site()`.

Special handling is neede when there is a need for rendering the scenario document (scenare.Rmd) separately, or when developing it further. For the first two outcomes simulated in each of the three scenarios, the same subdocument (`_scen_pt1.Rmd`) is run with different parameters, depending on the scenario. This generates and writes to disk `ggplot2` objects, which are then brought into the main `scenare.Rmd` document and displayed. For developing the individual charts, the right parameters have to be set (denoting the scenario and the outcome being simulated) so that the charts are generated correctly.

### After newly cloning this

1. run all the numbered R scripts in order
2. run Rmd files
3. create new Rmd files; use data from `data-*`
4. any new data creation or transformation should go into an R script and the data into `data-*`, so that Rmarkdown files only load the minimal data necessary and time to build them is minimised.
