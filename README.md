
# obce-covid19

<!-- badges: start -->
<!-- badges: end -->

This repository contains code for 

## How it works

- `renv` is used to ensure exact reproducibility with respect to package version
- heavy data download and processing is done in separate R scripts which
- all Rmarkdown files (except those whose names start with `_`) are turned into webpages using `rmarkdown::render_site()`. The result ends up in `docs` turned into a website with a navigation bar, all of which is set up in `_site.yml`.
- the resulting website is deployed to netlify using `netlify-cli`: https://obce-covid19.netlify.app/
- `/docs` or `data-*` is never committed or pushed to Github
