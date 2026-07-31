# Clears environment.
rm(list=ls())

#install.packages("remotes")
#remotes::install_version("terra", version = "1.8.5", repos = "https://cloud.r-project.org")

# Test if the spatial layers load cleanly now
library(dplyr)
library(sf)
library(terra)
library(raster)

# Install momentuHMM (it will now see the spatial tools are already satisfied)
#install.packages("momentuHMM")
library(momentuHMM)

your_dataframe = read.csv("hmm_df.csv")

your_dataframe

# Minimalist, publication-ready histogram
hist(your_dataframe$speed_m_per_min, 
     breaks = 50,
     main = "Empirical Speed",
     xlab = expression(paste("Speed (m ", min^-1, ")")), # Scientific notation
     col = "#2b5c8f",          # Professional steel blue
     border = "white",         # Crisp white separations
     las = 1,                  # Horizontal y-axis numbers
     bty = "l")                # Clean L-shaped frame (removes top/right box)

# Minimalist, publication-ready turning angle histogram
hist(your_dataframe$turning_angle, 
     breaks = 50, 
     main = "Empirical Turning Angles",
     xlab = expression(paste("Turning Angle (", textstyle(alpha), " rad)")), # Scientific notation (e.g., radians)
     col = "#2b5c8f",          # Professional steel blue
     border = "white",         # Crisp white separations
     las = 1,                  # Horizontal y-axis numbers
     bty = "l")                # Clean L-shaped frame (removes top/right box)

# Minimalist, publication-ready time delta histogram
hist(your_dataframe$time_delta_min, 
     breaks = 50,
     main = "Time Delta Distribution",          # Informative title
     xlab = "Time Delta (\u0394t, min)",        # Clean notation using a Greek Delta symbol
     col = "#2b5c8f",                           # Professional steel blue
     border = "white",                          # Crisp white separations
     las = 1,                                   # Horizontal y-axis numbers
     bty = "l")                                 # Clean L-shaped frame

summary(your_dataframe$speed_m_per_min)
quantile(your_dataframe$speed_m_per_min, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)
summary(your_dataframe$turning_angle)
quantile(your_dataframe$turning_angle, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)


# 1. Prepare your data frame correctly before feeding it to prepData
your_dataframe$ID <- your_dataframe$Serial
your_dataframe$speed <- your_dataframe$speed_m_per_min
your_dataframe$angle <- your_dataframe$turning_angle

# 2. Run prepData with explicit covariate registration and no conflicting type arguments
cattle_data <- prepData(
  data = your_dataframe, 
  coordNames = NULL,
  covNames = c("hour", "month") # Ensures these are carried over safely as covariates
)

# Define distributions
dist <- list(speed = "gamma", angle = "vm") 


# Initial values for Speed (Gamma distribution)
# Order: State 1 (Resting), State 2 (Foraging), State 3 (Transiting)
shape_effects_mean <- c(0.34, 1.99, 3.07, 7.28)  
shape_effects_sd   <- c(0.17, 1.00, 1.00, 1.00)  
Par0_speed <- c(shape_effects_mean, shape_effects_sd)


Par0_angle <- c(0.0, 0.0, 0.0, 0.0,        
                0.1, 1.0, 1.0, 5.0)        

Par0 <- list(speed = Par0_speed, angle = Par0_angle)



# Define the cyclical formulas for the Transition Probability Matrix (TPM)
model_formula <- ~ cosinor(hour, period = 24) + cosinor(month, period = 12)

set.seed(42)

# Fit the hidden Markov model
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

# Inspect model summary outputs
summary(cattle_hmm_model)

# Decode the most likely behavior sequence 
cattle_data$assigned_state <- viterbi(cattle_hmm_model)

# Generate updated diagnostic plots
plot(cattle_hmm_model)

# Time spent in states
state_proportions <- timeInStates(cattle_hmm_model)
print(state_proportions)

#    state 1   state 2   state 3
#1 0.1571851 0.3225705 0.5202444

# FIXED: Group by the correct column name (assigned_state)
cattle_data_summary <- cattle_data %>%
  group_by(assigned_state) %>%
  summarise(
    mean_speed   = mean(speed, na.rm = TRUE),
    sd_speed     = sd(speed, na.rm = TRUE),
    mean_angle   = mean(angle, na.rm = TRUE),
    sd_angle      = sd(angle, na.rm = TRUE),
    sample_count = n()
  )
print(cattle_data_summary)

# Ensure you have both packages loaded
install.packages('circular')
library(CircStats)
library(circular)

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



AIC(cattle_hmm_model)

# Compute pseudo-residuals for your fitted HMM model
res <- pseudoRes(cattle_hmm_model)

# Plot histograms and Q-Q plots for all data streams
plotPR(cattle_hmm_model)

# Open a 1x2 plotting window to view step and angle side-by-side
par(mfrow=c(1,2))

# Plot ACF for step length residuals (ignoring NA values)
acf(res$speed[!is.na(res$speed)], main="ACF of Speed Residuals")

# Plot ACF for turning angle residuals (ignoring NA values)
acf(res$angle[!is.na(res$angle)], main="ACF of Angle Residuals")



# Extract confidence intervals for your data stream distribution parameters
state_parameter_CIs <- CIreal(cattle_hmm_model, parms = c("speed", "angle"))
print(state_parameter_CIs)



#Scenario A: Peak Daytime Grazing vs. Night BeddingIf you want to know how cattle transition between behaviors at noon in the summer versus midnight in the summer:
# Noon in June
target_time_noon <- data.frame(hour = 12, month = 6)
CIreal(cattle_hmm_model, parms = "tpm", covs = target_time_noon)
# Midnight in June
target_time_night <- data.frame(hour = 0, month = 6)
CIreal(cattle_hmm_model, parms = "tpm", covs = target_time_night)

#Scenario B: Seasonal DifferencesIf you want to see if winter weather alters behavior patterns at the exact same time of day:
# Noon in December
target_time_winter <- data.frame(hour = 12, month = 12)
CIreal(cattle_hmm_model, parms = "tpm", covs = target_time_winter)

# FIXED: Changed parms = "gamma" to parms = "tpm"
tpm_at_noon_june <- CIreal(cattle_hmm_model, parms = "tpm", covs = target_time_noon)
print(tpm_at_noon_june)



# 1. Extract the estimated parameters for the movement distributions
# This converts them back from the working scale to the real scale (metres/min and radians)
estimated_params <- CIreal(cattle_hmm_model, parms = c("speed", "angle"))

# 2. Print out the clean estimates for Speed (Gamma: mean and sd)
cat("\n=== ESTIMATED SPEED PARAMETERS ===\n")
print(estimated_params$speed)

# 3. Print out the clean estimates for Turning Angle (Von Mises: mean and kappa)
cat("\n=== ESTIMATED TURNING ANGLE PARAMETERS ===\n")
print(estimated_params$angle)

cattle_data

write.csv(cattle_data, "hmm_df_b_R.csv", row.names = FALSE)
