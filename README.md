# BIOS 544 · Fun R Packages + Making Tables

Slides and code for the November 9, 2026 lecture in BIOS 544 (Intro to R), Rollins School of Public Health, Emory University.

We cover four things:

1. **Tables**: a Table 1 with `table1`, then `gtsummary` for p-values, regression tables, unadjusted vs adjusted models, journal styles and exporting to Word
2. **Quality of life**: `janitor`, `skimr`, `tidylog`, `here` and a few small joys
3. **Interactive charts**: `highcharter` (heatmaps, maps, treemaps, time series, themes), plus `patchwork` and `gganimate`
4. **Color**: palettes from Wes Anderson, Studio Ghibli, the Met, Taylor Swift, medical journals and cartoons, plus `paletteer` and making your own

## What's here

| File | What it is |
|---|---|
| `BIOS544_Fun_R_Packages_slides.html` | The slides. Download it and open it in any web browser. |
| `bios544_fun_r_packages.R` | Every piece of code from the slides, in the same order, plus the in-class exercises and possible solutions at the end. |

## Viewing the slides

GitHub shows `.html` files as code, not as slides, so:

1. Click `BIOS544_Fun_R_Packages_slides.html`, then the **Download raw file** button.
2. Open the downloaded file in Chrome, Firefox, Safari or Edge.
3. Use the arrow keys (or swipe on a phone) to move between slides.

Many slides have tabs: click them to see each step of the code next to its real output. Every code block has a **Copy** button.

The interactive charts load from the internet. Offline they show a message instead, and everything else still works.

## Running the code

1. Open RStudio and create or open an RStudio Project (File → New Project), then put `bios544_fun_r_packages.R` in that folder.
2. Install the packages once:

```r
install.packages(c(
  "tidyverse", "NHANES", "palmerpenguins", "gapminder",
  "table1", "gtsummary", "labelled", "gt", "flextable",
  "janitor", "skimr", "tidylog", "here", "beepr", "reprex",
  "highcharter", "patchwork", "gganimate", "gifski",
  "wesanderson", "ghibli", "MetBrewer", "taylor", "ggsci",
  "paletteer", "colorspace"
))
```

3. Run the script one section at a time with **Ctrl+Enter** (Windows) or **Cmd+Enter** (Mac). Tables and interactive charts show up in the Viewer pane, ggplots in the Plots pane. If you `source()` the whole file at once, nothing prints, which is expected.

A few things to know:

- The script saves some files to your project folder: two Word tables (`table1_nhanes.docx`, `table1_quick.docx`), `table2_physactive.docx` from the exercise solutions, `wealth_health.html` and `nhanes_adults.csv`.
- `hcmap()` downloads the US map the first time you run it, so you need internet.
- The `gganimate` animation takes about 30 seconds to render.

## Data

All data come from R packages, so there is nothing to download:

- **NHANES** (`NHANES` package): US National Health and Nutrition Examination Survey, 2009–2012. We use adults 20 and older, one row per person.
- **Palmer penguins** (`palmerpenguins`) and **Gapminder** (`gapminder`)
- **Datasets bundled with highcharter**: measles cases by state, San Francisco weather, Pokémon
- **Datasets built into R**: `state.x77`, `ldeaths`, `mdeaths`, `fdeaths`

NHANES is a complex survey. The tables in this lecture are unweighted, which is fine for learning the packages but not for estimating national prevalence. For that, use survey weights (see `gtsummary::tbl_svysummary()` and the `survey` package).

## Learn more

- [table1 examples](https://benjaminrich.github.io/table1/vignettes/table1-examples.html)
- [gtsummary](https://www.danieldsjoberg.com/gtsummary/): see its [tbl_summary()](https://www.danieldsjoberg.com/gtsummary/articles/tbl_summary.html) and [tbl_regression()](https://www.danieldsjoberg.com/gtsummary/articles/tbl_regression.html) tutorials
- [janitor](https://sfirke.github.io/janitor/) and [skimr](https://docs.ropensci.org/skimr/)
- [highcharter](https://jkunst.com/highcharter/) and its [showcase](https://jkunst.com/highcharter/articles/showcase.html)
- [Highcharts demo gallery](https://www.highcharts.com/demo): any option there can be used through the `hc_*()` functions
- [patchwork](https://patchwork.data-imaginist.com/) and [gganimate](https://gganimate.com/)
- [paletteer gallery](https://pmassicotte.github.io/paletteer_gallery/): every palette, visually
- [The R Graph Gallery](https://r-graph-gallery.com/)
