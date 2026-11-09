# =============================================================================
# BIOS 544 · Intro to R · November 9
# Fun R packages + making tables (table1 and gtsummary)
#
# How to use this script
#   - Open it inside an RStudio Project so here() knows where "home" is.
#   - Run it section by section with Ctrl+Enter / Cmd+Enter. Tables and
#     interactive charts appear in the Viewer pane, ggplots in the Plots pane.
#     (If you source() the whole file, nothing prints; that's normal.)
#   - Sections follow the slides in the same order.
# =============================================================================


# ---- 0. Install (run once per computer) --------------------------------------
# install.packages(c(
#   "tidyverse", "NHANES", "palmerpenguins", "gapminder",
#   "table1", "gtsummary", "labelled", "gt", "flextable",
#   "janitor", "skimr", "tidylog", "here", "beepr", "reprex",
#   "highcharter", "patchwork", "gganimate", "gifski",
#   "wesanderson", "ghibli", "MetBrewer", "taylor", "ggsci",
#   "paletteer", "colorspace"
# ))


# ---- 1. Setup -----------------------------------------------------------------
library(tidyverse)
library(NHANES)

# The NHANES package repeats some participants (we'll see this with janitor),
# so keep one row per person, adults only, with a diabetes answer.
nh <- NHANES |>
  distinct(ID, .keep_all = TRUE) |>
  filter(Age >= 20, !is.na(Diabetes))

nrow(nh)   # 4,653 adults


# =============================================================================
# PART 1 · TABLES
# =============================================================================

# ---- 1.1 Prep once: pick variables and give them labels ----------------------
# Both table1 and gtsummary read the same "label" attribute, so set labels once
# and every table (and regression table) uses them.
library(labelled)

tab <- nh |>
  select(Diabetes, Age, Gender, Race1, Education, BMI, BPSysAve,
         PhysActive, SmokeNow, SleepHrsNight) |>
  set_variable_labels(
    Age           = "Age (years)",
    Race1         = "Race/ethnicity",
    BMI           = "Body mass index (kg/m²)",
    BPSysAve      = "Systolic BP (mmHg)",
    PhysActive    = "Physically active",
    SmokeNow      = "Current smoker",
    SleepHrsNight = "Sleep (hours/night)"
  )

# A quick data dictionary: labels, types, missing counts, factor levels
look_for(tab)


# ---- 1.2 table1: a Table 1 in one line ---------------------------------------
library(table1)

# rows ~ variables | columns
table1(~ Age + Gender + Race1 + BMI + PhysActive | Diabetes, data = tab)


# ---- 1.3 table1: nested columns and your choice of statistics ----------------
# Two-level column header: Gender, then Diabetes within Gender
table1(~ Age + BMI + SleepHrsNight | Gender * Diabetes,
       data = tab, overall = FALSE)

# Overall column on the left, two summary rows per continuous variable
table1(~ Age + BMI + BPSysAve | Diabetes,
       data = tab,
       overall = c(left = "Total"),
       render.continuous = c(. = "Mean (SD)",
                             . = "Median [Q1, Q3]"),
       caption = "NHANES 2009–2012, adults 20+")


# ---- 1.4 gtsummary: build a Table 1 one line at a time ----------------------
library(gtsummary)

# Step 1: the basic table
tab |>
  tbl_summary(by = Diabetes)

# Step 2: add p-values (tests are chosen for you; see the footnote)
tab |>
  tbl_summary(by = Diabetes) |>
  add_p()

# Step 3: overall column and N per variable
tab |>
  tbl_summary(by = Diabetes) |>
  add_p() |>
  add_overall() |>
  add_n()

# Step 4: polish the header and labels
tab |>
  tbl_summary(by = Diabetes) |>
  add_p() |>
  add_overall() |>
  modify_spanning_header(c("stat_1", "stat_2") ~ "**Diabetes**") |>
  bold_labels() |>
  bold_p()


# ---- 1.5 gtsummary: choose the statistics ------------------------------------
# Means instead of medians, and pick the digits
tab |>
  select(Diabetes, Age, BMI, BPSysAve, Gender) |>
  tbl_summary(
    by = Diabetes,
    statistic = list(all_continuous() ~ "{mean} ({sd})",
                     all_categorical() ~ "{n} ({p}%)"),
    digits = all_continuous() ~ 1
  )

# Hide the missing rows, show a dichotomous variable on one line,
# and treat a 0-10 count as continuous
tab |>
  select(Diabetes, PhysActive, SmokeNow, SleepHrsNight) |>
  tbl_summary(
    by = Diabetes,
    type = list(SleepHrsNight ~ "continuous",
                PhysActive ~ "dichotomous"),
    value = list(PhysActive ~ "Yes"),
    missing = "no"
  )

# Note: SmokeNow is missing for ~2,600 adults because NHANES only asked
# people who had smoked 100+ cigarettes. Look before you hide missing data!


# ---- 1.6 gtsummary: regression tables ----------------------------------------
fit <- glm(Diabetes ~ Age + Gender + BMI + PhysActive,
           data = tab, family = binomial)

# Odds ratios with 95% CIs (labels come along automatically)
tbl_regression(fit, exponentiate = TRUE) |>
  bold_p()

# Works for linear models too
lm(BPSysAve ~ Age + Gender + BMI, data = tab) |>
  tbl_regression() |>
  bold_p()


# ---- 1.7 gtsummary: unadjusted vs adjusted, side by side ---------------------
# One unadjusted model per variable, in one call
uv <- tab |>
  select(Diabetes, Age, Gender, BMI, PhysActive) |>
  tbl_uvregression(
    method = glm,
    y = Diabetes,
    method.args = list(family = binomial),
    exponentiate = TRUE
  )

mv <- tbl_regression(fit, exponentiate = TRUE)

tbl_merge(list(uv, mv),
          tab_spanner = c("**Unadjusted**", "**Adjusted**"))


# ---- 1.8 gtsummary: journal themes -------------------------------------------
# A theme applies to tables built AFTER you set it, so rebuild the table each time.
theme_gtsummary_journal("jama")
tab |>
  select(Diabetes, Age, BMI, Gender, PhysActive) |>
  tbl_summary(by = Diabetes) |>
  add_p()

theme_gtsummary_journal("lancet")
tab |>
  select(Diabetes, Age, BMI, Gender, PhysActive) |>
  tbl_summary(by = Diabetes) |>
  add_p()

theme_gtsummary_journal("nejm")
tab |>
  select(Diabetes, Age, BMI, Gender, PhysActive) |>
  tbl_summary(by = Diabetes) |>
  add_p()

theme_gtsummary_compact()   # themes stack: smaller font, tighter rows

reset_gtsummary_theme()     # back to the default


# ---- 1.9 More table types -----------------------------------------------------
# A cross-tab with row percents
tab |>
  tbl_cross(row = PhysActive, col = Diabetes, percent = "row")

# One table per stratum, side by side
tab |>
  select(Gender, Diabetes, Age, BMI) |>
  tbl_strata(
    strata = Gender,
    .tbl_fun = ~ .x |> tbl_summary(by = Diabetes)
  )


# ---- 1.10 Get tables out of R -------------------------------------------------
final <- tab |>
  tbl_summary(by = Diabetes) |>
  add_p() |>
  bold_labels()

# Word document
final |>
  as_gt() |>
  gt::gtsave("table1_nhanes.docx")

# Image for slides
# final |> as_gt() |> gt::gtsave("table1_nhanes.png")   # needs webshot2

# Numbers inside a sentence (great in Quarto / R Markdown)
inline_text(final, variable = Age, column = "Yes")
inline_text(final, variable = Age, column = "p.value")

# table1 to Word goes through flextable
table1(~ Age + BMI | Diabetes, data = tab) |>
  t1flex() |>
  flextable::save_as_docx(path = "table1_quick.docx")


# =============================================================================
# PART 2 · QUALITY OF LIFE
# =============================================================================

# ---- 2.1 janitor ----------------------------------------------------------------
library(janitor)

# Clean column names
messy <- tibble(
  `Patient ID`    = 1:3,
  `Age (years)`   = c(34, 51, 27),
  `% Obese`       = c(31.2, 28.4, 35.0),
  `Visit Date #2` = c("2024-01-05", "2024-02-11", "2024-03-02")
)

messy |> clean_names()

# Find duplicate IDs (this is why we used distinct(ID) in setup)
NHANES |>
  get_dupes(ID) |>
  select(ID, dupe_count, SurveyYr, Age, Gender, BMI) |>
  head(6)

# Crosstabs you can read
nh |>
  tabyl(Education, Diabetes) |>
  adorn_totals("row") |>
  adorn_percentages("row") |>
  adorn_pct_formatting(digits = 1) |>
  adorn_ns()


# ---- 2.2 skimr ------------------------------------------------------------------
library(skimr)

nh |>
  select(Age, BMI, Pulse, Gender, Education) |>
  skim()

# By group
nh |>
  group_by(Diabetes) |>
  skim(BMI, Pulse) |>
  yank("numeric")

# Your own statistics
my_skim <- skim_with(
  numeric = sfl(iqr = ~ IQR(.x, na.rm = TRUE),
                n_zero = ~ sum(.x == 0, na.rm = TRUE)),
  append = FALSE
)

nh |>
  select(Age, BMI, SmokeAge, AlcoholYear) |>
  my_skim()

# The output is a tibble, so dplyr works on it
nh |>
  skim() |>
  yank("factor") |>
  filter(n_unique > 5) |>
  select(skim_variable, n_unique, top_counts)


# ---- 2.3 tidylog ----------------------------------------------------------------
library(tidylog)   # load AFTER dplyr/tidyverse

bp <- nh |>
  filter(!is.na(BPSysAve)) |>
  mutate(htn = BPSysAve >= 130) |>
  group_by(Gender) |>
  summarise(pct_htn = mean(htn))

# Catch a bad join: the original NHANES has repeat IDs, so rows multiply
nh_pulse <- nh |>
  left_join(select(NHANES, ID, Pulse2 = Pulse), by = "ID")

detach("package:tidylog", unload = TRUE)   # turn the narration off again


# ---- 2.4 here -------------------------------------------------------------------
library(here)

here()   # your project folder

write_csv(nh, here("nhanes_adults.csv"))
nh_again <- read_csv(here("nhanes_adults.csv"))


# ---- 2.5 Small joys -------------------------------------------------------------
fit_bmi <- glm(Diabetes ~ Age + BMI, data = nh, family = binomial)
beepr::beep("fanfare")

# reprex: copy some code to your clipboard, then run
# reprex::reprex()


# =============================================================================
# PART 3 · HIGHCHARTER
# =============================================================================
library(highcharter)
library(palmerpenguins)
library(gapminder)
library(MetBrewer)   # palettes, used in a few charts below

# ---- 3.1 hchart() picks the chart for you ------------------------------------
hchart(nh$BMI, name = "BMI")                       # numeric -> histogram
hchart(nh$Education, name = "Adults")              # factor  -> bar
hchart(density(nh$BMI, na.rm = TRUE),
       type = "area", name = "BMI")                # density -> curve
hchart(ldeaths, name = "UK lung disease deaths")   # ts      -> time series


# ---- 3.2 Data frames + hcaes() ------------------------------------------------
# Scatter with a custom tooltip (any column can go in the tooltip)
hchart(penguins, "scatter",
       hcaes(x = flipper_length_mm, y = body_mass_g, group = species)) |>
  hc_tooltip(pointFormat = "Island: {point.island}<br>
    Flipper: {point.x} mm<br>Mass: {point.y} g")

# Stacked column
penguins |>
  count(island, species) |>
  hchart("column", hcaes(x = island, y = n, group = species)) |>
  hc_plotOptions(column = list(stacking = "normal"))

# Boxplot
bp_data <- penguins |>
  drop_na(body_mass_g) |>
  data_to_boxplot(body_mass_g, species, name = "Body mass (g)")

highchart() |>
  hc_add_series_list(bp_data) |>
  hc_xAxis(type = "category")

# Lines with a shared tooltip
gapminder |>
  filter(country %in% c("United States", "Rwanda",
                        "China", "Brazil", "Sweden")) |>
  hchart("line", hcaes(x = year, y = lifeExp, group = country)) |>
  hc_tooltip(shared = TRUE, valueDecimals = 1) |>
  hc_yAxis(title = list(text = "Life expectancy (years)"))


# ---- 3.3 Measles and the vaccine (from the highcharter showcase) -------------
data(vaccines)   # measles cases per 100k, by state

hchart(vaccines, "heatmap",
       hcaes(x = year, y = state, value = count)) |>
  hc_colorAxis(
    type = "logarithmic",
    stops = color_stops(8, met.brewer("Tam", 8))) |>
  hc_xAxis(plotLines = list(list(
    value = 1963, color = "#1d1d1d", width = 2,
    zIndex = 5, label = list(
      text = "Vaccine introduced", rotation = 0, y = -5)))) |>
  hc_yAxis(title = list(text = ""), reversed = TRUE,
           labels = list(style = list(fontSize = "8px"))) |>
  hc_tooltip(pointFormat =
    "{point.state}, {point.x}: <b>{point.value:.1f}</b>") |>
  hc_title(text = "Measles and the vaccine")


# ---- 3.4 Time series with a navigator -----------------------------------------
highchart(type = "stock") |>
  hc_add_series(mdeaths, name = "Men") |>
  hc_add_series(fdeaths, name = "Women") |>
  hc_title(text = "Monthly lung disease deaths, UK") |>
  hc_tooltip(shared = TRUE)


# ---- 3.5 Maps (downloads the map shape the first time; needs internet) -------
states <- state.x77 |>
  as_tibble(rownames = "state") |>
  clean_names()

hcmap("countries/us/us-all", data = states,
      value = "life_exp",
      joinBy = c("name", "state"),
      name = "Life expectancy, 1969–71 (years)") |>
  hc_colorAxis(stops = color_stops(6, met.brewer("Hokusai2", 6)))

hcmap("countries/us/us-all", data = states,
      value = "hs_grad",
      joinBy = c("name", "state"),
      name = "High school graduates, 1970 (%)") |>
  hc_colorAxis(stops = color_stops(6, met.brewer("Hokusai3", 6)))

hcmap("countries/us/us-all", data = states,
      value = "murder",
      joinBy = c("name", "state"),
      name = "Murder rate per 100k, 1976") |>
  hc_colorAxis(stops = color_stops(6, met.brewer("OKeeffe2", 6)))


# ---- 3.6 Treemap and sunburst: click to drill down ---------------------------
gap07 <- gapminder |> filter(year == 2007)

gap07 |>
  data_to_hierarchical(c(continent, country), pop) |>
  hchart(type = "treemap", allowDrillToNode = TRUE,
         levelIsConstant = FALSE,
         levels = list(
           list(level = 1, borderWidth = 3,
                dataLabels = list(enabled = TRUE)),
           list(level = 2,
                dataLabels = list(enabled = FALSE)))) |>
  hc_title(text = "World population, 2007")

gap07 |>
  data_to_hierarchical(c(continent, country), pop) |>
  hchart(type = "sunburst", allowDrillToNode = TRUE) |>
  hc_title(text = "World population, 2007")


# ---- 3.7 Just for fun (from the showcase) ------------------------------------
data(weather)   # San Francisco, 2014

hchart(weather, type = "columnrange",
       hcaes(x = date, low = min_temperaturec,
             high = max_temperaturec,
             color = colorize(mean_temperaturec,
                              rev(met.brewer("Hiroshige"))))) |>
  hc_chart(polar = TRUE) |>
  hc_yAxis(max = 30, min = -10, showFirstLabel = FALSE,
           labels = list(format = "{value} °C")) |>
  hc_xAxis(title = list(text = ""), gridLineWidth = 0.5,
           labels = list(format = "{value: %b}")) |>
  hc_title(text = "A year of San Francisco weather")

data(pokemon)

pkmn <- pokemon |>
  mutate(type_1 = str_to_title(type_1),
         type_2 = if_else(is.na(type_2), type_1,
                          paste(type_1, "-", type_2)),
         val = 1)

cols <- pkmn |>
  count(type_1, type_2, type_1_color, sort = TRUE) |>
  pull(type_1_color) |>
  unique()

pkmn |>
  data_to_hierarchical(c(type_1, type_2), val, colors = cols) |>
  hchart(type = "treemap", allowDrillToNode = TRUE,
         levelIsConstant = FALSE,
         levels = list(
           list(level = 1, borderWidth = 0,
                dataLabels = list(enabled = TRUE)),
           list(level = 2, borderWidth = 0,
                dataLabels = list(enabled = FALSE)))) |>
  hc_title(text = "Gotta Catch 'Em All!")


# ---- 3.8 One chart, many themes -----------------------------------------------
p_hc <- hchart(gap07, "scatter",
               hcaes(x = gdpPercap, y = lifeExp,
                     size = pop, group = continent),
               maxSize = 40) |>
  hc_xAxis(type = "logarithmic", title = list(text = "GDP per capita")) |>
  hc_yAxis(title = list(text = "Life expectancy")) |>
  hc_title(text = "Wealth and health, 2007")

p_hc
p_hc |> hc_add_theme(hc_theme_economist())
p_hc |> hc_add_theme(hc_theme_538())
p_hc |> hc_add_theme(hc_theme_ggplot2())
p_hc |> hc_add_theme(hc_theme_darkunica())
p_hc |> hc_add_theme(hc_theme_tufte())
p_hc |> hc_add_theme(hc_theme_monokai())
p_hc |> hc_add_theme(hc_theme_ffx())


# ---- 3.9 Finishing touches ------------------------------------------------------
p_final <- p_hc |>
  hc_subtitle(text = "Gapminder, 2007") |>
  hc_caption(text = "Bubble size = population") |>
  hc_credits(enabled = TRUE, text = "BIOS 544") |>
  hc_exporting(enabled = TRUE)   # download menu: PNG, SVG, PDF, CSV

p_final

# Save as a web page anyone can open
htmlwidgets::saveWidget(p_final, "wealth_health.html")


# ---- 3.10 Two ggplot add-ons ----------------------------------------------------
library(patchwork)

p1 <- ggplot(nh, aes(BMI)) + geom_histogram()
p2 <- ggplot(nh, aes(Diabetes, BMI)) + geom_boxplot()
p3 <- ggplot(nh, aes(Age, BMI)) + geom_point(alpha = .2)

(p1 | p2) / p3 +
  plot_annotation(tag_levels = "A")

library(gganimate)   # also needs gifski installed to make a GIF

rosling <- ggplot(gapminder, aes(gdpPercap, lifeExp,
                                 size = pop, color = continent)) +
  geom_point(alpha = 0.7) +
  scale_x_log10() +
  labs(title = "Year: {frame_time}",
       x = "GDP per capita", y = "Life expectancy") +
  transition_time(year)

animate(rosling)             # takes ~30 seconds
anim_save("rosling.gif")


# =============================================================================
# PART 4 · COLOR WITH PERSONALITY
# =============================================================================

# ---- 4.1 One plot to recolor ------------------------------------------------------
p <- nh |>
  drop_na(Education, AgeDecade) |>
  ggplot(aes(AgeDecade, fill = Education)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Age group", y = NULL, fill = "Education") +
  theme_minimal(base_size = 14)

p


# ---- 4.2 Wes Anderson ---------------------------------------------------------------
library(wesanderson)
names(wes_palettes)

p + scale_fill_manual(values = wes_palette("Zissou1", 5))
p + scale_fill_manual(values = wes_palette("Darjeeling1", 5))
p + scale_fill_manual(values = wes_palette("AsteroidCity1", 5))
p + scale_fill_manual(values = wes_palette("GrandBudapest1", 5,
                                           type = "continuous"))


# ---- 4.3 Studio Ghibli ----------------------------------------------------------------
library(ghibli)

p + scale_fill_ghibli_d("SpiritedMedium")
p + scale_fill_ghibli_d("PonyoMedium")
p + scale_fill_ghibli_d("TotoroMedium")
p + scale_fill_ghibli_d("KikiMedium")


# ---- 4.4 The Met --------------------------------------------------------------------
p + scale_fill_met_d("Hiroshige")
p + scale_fill_met_d("Renoir")
p + scale_fill_met_d("Klimt")
p + scale_fill_met_d("Signac")

colorblind_palettes   # Met palettes that are colorblind-friendly


# ---- 4.5 Taylor Swift -----------------------------------------------------------------
library(taylor)

p + scale_fill_taylor_d(album = "Midnights")
p + scale_fill_taylor_d(album = "Lover")
p + scale_fill_taylor_d(album = "evermore")
p + scale_fill_taylor_d(album = "The Life of a Showgirl")


# ---- 4.6 Journals and TV (ggsci) --------------------------------------------------------
library(ggsci)

p + scale_fill_nejm()
p + scale_fill_lancet()
p + scale_fill_jama()
p + scale_fill_bmj()

p + scale_fill_simpsons()
p + scale_fill_futurama()
p + scale_fill_rickandmorty()
p + scale_fill_startrek()


# ---- 4.7 paletteer: every palette, one syntax ------------------------------------------
library(paletteer)

nrow(palettes_d_names)   # how many discrete palettes

p + scale_fill_paletteer_d("nationalparkcolors::Arches")
p + scale_fill_paletteer_d("ghibli::KikiMedium")

# Palette roulette
palettes_d_names |>
  filter(length >= 5) |>
  slice_sample(n = 1)


# ---- 4.8 Check a palette for color blindness ---------------------------------------
library(colorspace)

swatchplot(wes_palette("Darjeeling1", 5), cvd = TRUE)


# ---- 4.9 Your own palette ------------------------------------------------------------
emory <- c(blue = "#012169", gold = "#F2A900")

colorRampPalette(emory)(5)

p + scale_fill_manual(values = colorRampPalette(emory)(5))


# =============================================================================
# YOUR TURN (15 minutes)
# =============================================================================
# 1. Tables: summarize Age, BMI, SleepHrsNight and Education by PhysActive,
#    first with table1, then with gtsummary + add_p(). Give BMI a label.
# 2. Regression: fit glm(PhysActive ~ Age + Gender + BMI), make a
#    tbl_regression() with odds ratios, merge it with tbl_uvregression(),
#    and save it to Word.
# 3. highcharter: make a heatmap of mean BMI by AgeDecade and Education.
# 4. Color: spin the palette roulette and use the winner on any ggplot.


# ---- Possible solutions --------------------------------------------------------------

# 1. Tables
ex <- nh |>
  select(PhysActive, Age, BMI, SleepHrsNight, Education) |>
  set_variable_labels(BMI = "Body mass index (kg/m²)")

table1(~ Age + BMI + SleepHrsNight + Education | PhysActive, data = ex)

ex |>
  tbl_summary(by = PhysActive) |>
  add_p()

# 2. Regression
fit_pa <- glm(PhysActive ~ Age + Gender + BMI, data = nh, family = binomial)

uv_pa <- nh |>
  select(PhysActive, Age, Gender, BMI) |>
  tbl_uvregression(method = glm, y = PhysActive,
                   method.args = list(family = binomial),
                   exponentiate = TRUE)

table2_pa <- tbl_merge(list(uv_pa, tbl_regression(fit_pa, exponentiate = TRUE)),
                       tab_spanner = c("**Unadjusted**", "**Adjusted**"))
table2_pa

table2_pa |>
  as_gt() |>
  gt::gtsave("table2_physactive.docx")

# 3. highcharter heatmap
nh |>
  drop_na(AgeDecade, Education, BMI) |>
  group_by(AgeDecade, Education) |>
  summarise(mean_bmi = round(mean(BMI), 1), .groups = "drop") |>
  hchart("heatmap", hcaes(x = AgeDecade, y = Education, value = mean_bmi)) |>
  hc_colorAxis(stops = color_stops(6, met.brewer("Hiroshige", 6)))

# 4. Color
p + scale_fill_paletteer_d("MoMAColors::Klein")
