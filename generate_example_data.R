################################################################################
# Example Data Generator for Testing Causal Analysis
################################################################################
# This script generates synthetic data with similar structure to bdporc_dataC2
# for testing the causal analysis script when the real data is not available.
#
# Author: Test Data Generator
# Date: 2026-01-19
################################################################################

cat("Generating example data for testing...\n")

# Set seed for reproducibility
set.seed(42)

# Number of observations
n <- 1000

# Generate example data
example_data <- data.frame(
  # Continuous variables
  avg.sows = rnorm(n, mean = 150, sd = 30),
  prev_sowlactpd = rnorm(n, mean = 21, sd = 3),
  Prev_PBA = rpois(n, lambda = 12),
  previous_weaned = rpois(n, lambda = 10),
  sow_age_first_mating = rnorm(n, mean = 365, sd = 50),
  F_light_hr = rnorm(n, mean = 14, sd = 2),
  AI_light_hr = rnorm(n, mean = 14, sd = 2),
  
  # Discrete/categorical variables
  Company_farm = sample(paste0("Farm_", 1:10), n, replace = TRUE),
  Year = sample(2018:2023, n, replace = TRUE),
  Seasons = sample(c("Spring", "Summer", "Fall", "Winter"), n, replace = TRUE),
  Prev_PBD.cat = sample(c("Low", "Medium", "High"), n, replace = TRUE),
  prev_losses.born.alive.cat = sample(c("Low", "Medium", "High"), n, replace = TRUE)
)

# Add some causal relationships to make the test more interesting
# For example: larger farms might have more weaned piglets
example_data$previous_weaned <- example_data$previous_weaned + 
  0.01 * (example_data$avg.sows - mean(example_data$avg.sows))

# Previous lactation period might affect previous piglets born alive
example_data$Prev_PBA <- example_data$Prev_PBA + 
  0.2 * (example_data$prev_sowlactpd - mean(example_data$prev_sowlactpd))

# TARGET OUTCOME: losses.born.alive
# Generate with causal relationships to predictor variables
# This represents lactation losses over born alive
example_data$losses.born.alive <- 0.05 +  # baseline
  0.002 * (example_data$prev_sowlactpd - mean(example_data$prev_sowlactpd)) +  # lactation effect
  -0.001 * (example_data$Prev_PBA - mean(example_data$Prev_PBA)) +  # more born alive reduces losses
  0.0005 * (example_data$sow_age_first_mating - mean(example_data$sow_age_first_mating)) +  # age effect
  rnorm(n, mean = 0, sd = 0.02)  # random noise

# Ensure losses.born.alive is positive and reasonable
example_data$losses.born.alive <- pmax(0, pmin(1, example_data$losses.born.alive))

# Introduce some missing values (5% random)
missing_prob <- 0.05
for (col in names(example_data)) {
  missing_idx <- sample(1:n, size = round(n * missing_prob))
  example_data[missing_idx, col] <- NA
}

cat("Generated data dimensions:", nrow(example_data), "rows x", ncol(example_data), "columns\n")
cat("\nVariable summary:\n")
print(str(example_data))

# Save to RData file
save(example_data, file = "bdporc_dataC2.RData")
cat("\nExample data saved to: bdporc_dataC2.RData\n")
cat("You can now run the causal analysis script with this test data.\n")
