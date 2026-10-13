# Clear environment.
rm(list=ls())

# Load necessary packages, assuming they are already installed - use install.packages("...") otherwise.
library(dplyr)
library(sf)
library(terra)
library(raster)
library(momentuHMM)
library(CircStats)
library(circular)

# Read in the processed data.
processed_gps_data = read.csv("hmm_df.csv")

# View data.
processed_gps_data



# Basic statistical summaries, and percentiles of movement variables (used in conjunction with previous literature to help guide par0 paramater values in the HMM below).
summary(processed_gps_data$speed_m_per_min)
quantile(processed_gps_data$speed_m_per_min, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)
summary(processed_gps_data$turning_angle)
quantile(processed_gps_data$turning_angle, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)

# Minimalist, publication-ready histograms for speed.
hist(processed_gps_data$speed_m_per_min, 
     breaks = 50,
     main = "Empirical Speed",
     xlab = expression(paste("Speed (m ", min^-1, ")")), # Scientific notation
     col = "#2b5c8f",          # Professional steel blue
     border = "white",         # Crisp white separations
     las = 1,                  # Horizontal y-axis numbers
     bty = "l")                # Clean L-shaped frame (removes top/right box)

# Minimalist turning angle histogram.
hist(processed_gps_data$turning_angle, 
     breaks = 50, 
     main = "Empirical Turning Angles",
     xlab = expression(paste("Turning Angle (", textstyle(alpha), " rad)")), # Scientific notation (e.g., radians)
     col = "#2b5c8f",          # Professional steel blue
     border = "white",         # Crisp white separations
     las = 1,                  # Horizontal y-axis numbers
     bty = "l")                # Clean L-shaped frame (removes top/right box)

# Minimalist time delta histogram.
hist(processed_gps_data$time_delta_min, 
     breaks = 50,
     main = "Time Delta Distribution",          # Informative title
     xlab = "Time Delta (\u0394t, min)",        # Clean notation using a Greek Delta symbol
     col = "#2b5c8f",                           # Professional steel blue
     border = "white",                          # Crisp white separations
     las = 1,                                   # Horizontal y-axis numbers
     bty = "l")                                 # Clean L-shaped frame



# Prepare data frame before feeding it to prepData.
processed_gps_data$ID <- processed_gps_data$Serial
processed_gps_data$speed <- processed_gps_data$speed_m_per_min
processed_gps_data$angle <- processed_gps_data$turning_angle

# Run prepData with explicit covariate registration and no conflicting type arguments.
cattle_data <- prepData(
  data = processed_gps_data, 
  coordNames = NULL,
  covNames = c("hour", "month") # Ensures these are carried over safely as covariates.
)

# Define distributions.
dist <- list(speed = "gamma", angle = "vm") 

# Initial values for Speed (Gamma distribution)
# Order: State 1 (Resting), State 2 (Foraging), State 3 (Transiting)
shape_effects_mean <- c(0.34, 1.99, 3.07, 7.28)  
shape_effects_sd   <- c(0.17, 1.00, 1.00, 1.00)  
Par0_speed <- c(shape_effects_mean, shape_effects_sd)

Par0_angle <- c(0.0, 0.0, 0.0, 0.0,        
                0.1, 1.0, 1.0, 5.0)        
Par0 <- list(speed = Par0_speed, angle = Par0_angle)

# Define the cyclical formulas for the Transition Probability Matrix (TPM).
model_formula <- ~ cosinor(hour, period = 24) + cosinor(month, period = 12)

# Specify seed.
set.seed(42)

# Fit the Hidden Markov Model.
cattle_hmm_model <- fitHMM(
  data = cattle_data,
  nbStates = 4,
  dist = dist,
  Par0 = Par0,
  formula = model_formula,
  estAngleMean = list(angle = TRUE), 
  control = list(
    maxit = 500,                     
    reltol = 0.001                   
  )
)



# Inspect the model summary outputs.
summary(cattle_hmm_model)

# Decode the most likely behavior sequence. 
cattle_data$assigned_state <- viterbi(cattle_hmm_model)

# Generate updated diagnostic plots.
plot(cattle_hmm_model)

# Display time spent in states.
state_proportions <- timeInStates(cattle_hmm_model)
print(state_proportions)

# Summarise movement variable characteristics by state.
cattle_data_summary <- cattle_data %>%
  group_by(assigned_state) %>%
  summarise(
    mean_speed        = mean(speed, na.rm = TRUE),
    sd_speed          = sd(speed, na.rm = TRUE),
    mean_abs_angle    = mean(abs(angle), na.rm = TRUE),
    sd_abs_angle      = sd(abs(angle), na.rm = TRUE),
    sample_count      = n()
  )
print(cattle_data_summary)

# Extract confidence intervals for data stream distribution parameters.
state_parameter_CIs <- CIreal(cattle_hmm_model, parms = c("speed", "angle"))
print(state_parameter_CIs)



# Test the model using Akaike Information Criterion.
AIC(cattle_hmm_model)

# Compute pseudo-residuals for the fitted HMM model
res <- pseudoRes(cattle_hmm_model)

# Plot histograms and Q-Q plots for data streams
plotPR(cattle_hmm_model)

# Plot ACF for movement variable residuals.
par(mfrow=c(1,2))
acf(res$speed[!is.na(res$speed)], main="ACF of Speed Residuals")
acf(res$angle[!is.na(res$angle)], main="ACF of Angle Residuals")



# Save the dataset with the decoded behaviour states.
write.csv(cattle_data, "hmm_df_b_R.csv", row.names = FALSE)
