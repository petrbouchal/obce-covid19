#!/usr/bin/env zsh

if Rscript build_word.R && Rscript -e "rmarkdown::render_site()";
then
  echo "Deploying"
  netlify deploy --dir="docs" --prod
else
  echo "Build failed"
fi
