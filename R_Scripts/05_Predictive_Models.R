# Clear environment.
rm(list=ls())

# Load necessary packages, assuming they are already installed - use install.packages() otherwise.
library(dplyr)
library(readr)
library(tidyverse)
library(ggplot2)
library(lubridate)
library(forcats)
library(rlang)
library(glmmTMB)
library(emmeans)
library(broom.mixed)
library(performance)
library(car)

# Read in the post-HMM data.
df = read.csv("joined_glm.csv")

# View data.
df



# Prepare data for betabinomial GLMM.
df %>%
  mutate(
    Position_Time = ymd_hms(Position_Time),
    date = as.Date(Position_Time),
    month = factor(month(Position_Time, label = TRUE)),
    Serial = factor(Serial),
    Pasture_Version = factor(Pasture_Version),
    grid_x_5m = floor(x / 5),
    grid_y_5m = floor(y / 5),
    grid_id = factor(paste(grid_x_5m, grid_y_5m, sep = '_')),
    is_grazing = behaviour_state %in% c('Intensive Foraging', 'Extensive Foraging'),
    NVC_lumped = fct_lump_min(factor(NVC), min = 100)
  ) %>%
  filter(!is.na(NVC_lumped), !is.na(grid_id), !is.na(is_grazing))

cell_cow_day_habitat1 <- df %>%
  group_by(Serial, date, grid_id, NVC, Pasture_Version, month) %>%
  summarise(
    grazing_n = sum(is_grazing),
    total_n = n(),
    non_grazing_n = total_n - grazing_n,
    .groups = 'drop'
  )



# Set Woodland as the reference baseline level.
cell_cow_day_habitat1$NVC <- relevel(as.factor(cell_cow_day_habitat1$NVC), ref = "Woodland")

# Run betabinomial GLMM.
m_behaviour <- glmmTMB(
  cbind(grazing_n, non_grazing_n) ~
    NVC + month +
    (1 | Serial) +
    (1 | date) +
    (1 | grid_id) +
    (1 | Pasture_Version),
  family = betabinomial(link = 'logit'),
  data = cell_cow_day_habitat1
)

# Model summary.
summary(m_behaviour)

# Post-model checks.
plot(residuals(m_behaviour, type='pearson'), fitted(m_behaviour, type='pearson'))
check_model(m_behaviour)
Anova(m_behaviour, type=2)
VarCorr(m_behaviour)
m_behaviour$sdr$pdHess

# Tidy the glmmTMB model summary into a clean data frame.
model_results1 <- tidy(m_behaviour, effects = "fixed", conf.int = TRUE)

# Rename columns.
model_results_clean1 <- model_results1 %>%
  dplyr::select(
    Variable = term,
    Estimate = estimate,
    Std_Error = std.error,
    Statistic = statistic,
    P_Value = p.value,
    CI_Lower = conf.low,
    CI_Upper = conf.high
  )

# Save the data frame to a CSV file.
write_csv(model_results_clean1, "m_behaviour_model_summary.csv")



# Emmeans testing.
emmeans(m_behaviour, pairwise ~ NVC, type = 'response')

# Save the emmeans output as a data frame (extracting just the grid).
emm_output <- emmeans(m_behaviour, pairwise ~ NVC, type = 'response')

model_results <- tidy(emm_output$emmeans, effects = "fixed", conf.int = TRUE)

# Rename columns.
contrasts_clean1 <- model_results %>%
  dplyr::select(
    NVC = NVC,
    prob = prob,
    std.error = std.error,
    conf.low = conf.low,
    conf.high = conf.high,
    p.value = p.value
  )

# Save the data frame to a CSV file.
write_csv(contrasts_clean1, "m_behaviour_em1.csv")



# Create a plot of NVC communities ordered by grazing probability.
plot_data <- as.data.frame(emm_output$emmeans)
ggplot(plot_data, aes(x = prob, y = NVC)) +
  geom_errorbarh(aes(xmin = `asymp.LCL`, xmax = `asymp.UCL`), 
                 height = 0.2, color = "black", linewidth = 0.7) +
  geom_boxplot(aes(xmin = prob - SE, xlower = prob - SE, 
                   xmiddle = prob, 
                   xupper = prob + SE, xmax = prob + SE),
               stat = "identity", orientation = "y", 
               fill = "grey95", color = "black", width = 0.5) +
  theme_classic() +
  labs(x = "Probability (Estimated Marginal Mean)", y = "NVC Community") +
  theme(
    text = element_text(family = "sans", size = 12),
    axis.text = element_text(color = "black"),
    axis.line = element_line(linewidth = 0.6)
  )



# Show significant contrasts in grazing probability between NVC communities.
significant_contrasts <- emmeans(m_behaviour, pairwise ~ NVC, type = "response")$contrasts %>%
  as.data.frame() %>%
  filter(p.value < 0.05)

significant_contrasts

# Tidy into a clean data frame.
model_results <- tidy(significant_contrasts, effects = "fixed", conf.int = TRUE)

# Rename columns.
contrasts_clean <- significant_contrasts %>%
  dplyr::select(
    contrast = contrast,
    odds.ratio = odds.ratio,
    SE = SE,
    z.ratio = z.ratio,
    p.Value = p.value,
  )

# Save data frame to a CSV file.
write_csv(contrasts_clean, "m_behaviour_contrasts.csv")



# AIC testing for inclusion of random effects.
m1 <- glmmTMB(
  cbind(grazing_n, non_grazing_n) ~
    NVC + month +
    (1 | Serial) + (1 | date) + (1 | grid_id),
  family = betabinomial(link = 'logit'),
  data = cell_cow_day_habitat1
)

m2 <- update(m1, . ~ . + (1 | Pasture_Version))
AIC(m1, m2)



# Generate accessibility table from GPS logs.
accessibility_table <- df %>%
  # Keep only the columns defining spatial containment and habitat.
  select(grid_id, date, Pasture_Version, NVC, ID) %>% 
  distinct() %>% 
  # Calculate how many unique cows were in that paddock version on that date.
  group_by(grid_id, date, Pasture_Version, NVC) %>%
  summarise(
    cows_present = n_distinct(ID),
    .groups = 'drop'
  ) %>%
  # Since each row represents 1 unique date, day = 1, multiply cows by days (1) to get daily accessible cow days.
  mutate(accessible_cow_days = cows_present * 1)

# Display accessibility table.
head(accessibility_table)

# Summarise accessibility to the grid-cell level.
cell_accessibility_summary <- accessibility_table %>%
  group_by(grid_id, NVC) %>%
  summarise(
    accessible_cow_days = sum(accessible_cow_days),
    .groups = 'drop'
  )

# Calculate actual grazing pressure from the raw GPS data.
pressure_data <- df %>%
  group_by(grid_id, NVC) %>%
  summarise(
    grazing_counts = sum(is_grazing),#, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  left_join(cell_accessibility_summary, by = c('grid_id', 'NVC')) %>%
  filter(accessible_cow_days > 0)

print(pressure_data, n = 5)



# Poisson GLM (dispersion issues).
m_pressure_poissonGLM <- glm(
  grazing_counts ~
    NVC +
    offset(log(accessible_cow_days)),
  family = poisson,
  data = pressure_data
)

summary(m_pressure_poissonGLM)



# Generalised poisson GLM.
m_pressure_genpois <- glmmTMB(
  grazing_counts ~ NVC + offset(log(accessible_cow_days)),
  family = genpois,
  data = pressure_data
)
summary(m_pressure_genpois)

# Post-model checks.
plot(residuals(m_pressure_genpois, type='pearson'), fitted(m_pressure_genpois, type='pearson'))
check_model(m_pressure_genpois)
Anova(m_pressure_genpois, type=2)



# Conway-Maxwell-Poisson (COM-Poisson) GLM.
m_pressure_compois <- glmmTMB(
  grazing_counts ~ NVC + offset(log(accessible_cow_days)),
  family = compois,
  data = pressure_data
)
summary(m_pressure_compois)

# Post-model checks.
plot(residuals(m_pressure_compois, type='pearson'), fitted(m_pressure_compois, type='pearson'))
check_model(m_pressure_compois)
Anova(m_pressure_compois, type=2)
VarCorr(m_pressure_compois)
m_pressure_compois$sdr$pdHess



# AIC testing between generalised and COM poisson GLMs (COM poisson selected based on AIC score).
AIC(m_pressure_genpois, m_pressure_compois)



# Tidy the model summary into a clean data frame.
model_results1 <- tidy(m_pressure_compois, effects = "fixed", conf.int = TRUE)

# Rename columns.
model_results_clean1 <- model_results1 %>%
  dplyr::select(
    Variable = term,
    Estimate = estimate,
    Std_Error = std.error,
    Statistic = statistic,
    P_Value = p.value,
    CI_Lower = conf.low,
    CI_Upper = conf.high
  )

# Save data frame to a CSV file.
write_csv(model_results_clean1, "com_model_summary.csv")



# Calculate Estimated Marginal Means.
nvc_emm <- emmeans(m_pressure_compois, ~ NVC, type = "response")

nvc_emm

# Create a plot of NVC communities ordered by estimated daily grazing count.
plot_data <- as.data.frame(nvc_emm)
ggplot(plot_data, aes(x = response, y = NVC)) +
  geom_errorbarh(aes(xmin = `asymp.LCL`, xmax = `asymp.UCL`), 
                 height = 0.2, color = "black", linewidth = 0.7) +
  geom_boxplot(aes(xmin = response - SE, xlower = response - SE, 
                   xmiddle = response, 
                   xupper = response + SE, xmax = response + SE),
               stat = "identity", orientation = "y", 
               fill = "grey95", color = "black", width = 0.5) +
  theme_classic() +
  labs(x = "Response (Estimated Marginal Mean)", y = "NVC Community") +
  theme(
    text = element_text(family = "sans", size = 12),
    axis.text = element_text(color = "black"),
    axis.line = element_line(linewidth = 0.6)
  )

# Tidy results.
model_results <- tidy(nvc_emm, effects = "fixed", conf.int = TRUE)

model_results

# Rename columns.
contrasts_clean1 <- model_results %>%
  dplyr::select(
    NVC = NVC,
    response = response,
    std.error = std.error,
    conf.low = conf.low,
    conf.high = conf.high,
    p.value = p.value
  )

# Save data frame to a CSV file.
write_csv(contrasts_clean1, "com_em.csv")



# Conduct pairwise comparisons with Tukey adjustment.
nvc_pairs <- pairs(nvc_emm, adjust = "tukey")

# View results.
summary(nvc_pairs)

# Show significant contrasts in expected daily grazing count between NVC communities.
significant <- nvc_pairs %>%
  as.data.frame() %>%
  filter(p.value < 0.05)

significant

# Rename columns.
contrasts_clean2 <- significant %>%
  dplyr::select(
    contrast = contrast,
    ratio = ratio,
    SE = SE,
    z.ratio = z.ratio,
    p.Value = p.value,
  )

# Save data frame to a CSV file.
write_csv(contrasts_clean2, "com_pairwise.csv")
