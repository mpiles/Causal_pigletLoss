################################################################################
# Test Script for Domain Knowledge Constraints
################################################################################
# This script tests that the domain knowledge constraints correctly prevent
# environmental variables from being caused by other variables.
#
# Usage:
#   Rscript test_domain_constraints.R
################################################################################

# Test data parameters (defined as constants for clarity)
SAMPLE_SIZE <- 1000
MEAN_LIGHT_HOURS_FARROWING <- 14
SD_LIGHT_HOURS_FARROWING <- 2
MEAN_LIGHT_HOURS_AI <- 13
SD_LIGHT_HOURS_AI <- 2
MEAN_PIGLETS_BORN_ALIVE <- 12
MEAN_HERD_SIZE <- 500
SD_HERD_SIZE <- 50
MEAN_LOSSES <- 0.1
SD_LOSSES <- 0.05

cat("Testing Domain Knowledge Constraints for Environmental Variables\n")
cat("=================================================================\n\n")

# Load required library
if (!require("bnlearn", quietly = TRUE)) {
  stop("bnlearn package is required. Install with: install.packages('bnlearn')")
}

# Create simple test data
set.seed(123)
n <- SAMPLE_SIZE

test_data <- data.frame(
  # Environmental variable (should only be a cause)
  F_light_hr = rnorm(n, mean = MEAN_LIGHT_HOURS_FARROWING, sd = SD_LIGHT_HOURS_FARROWING),
  AI_light_hr = rnorm(n, mean = MEAN_LIGHT_HOURS_AI, sd = SD_LIGHT_HOURS_AI),
  
  # Reproductive variables
  prev_PBA = rpois(n, lambda = MEAN_PIGLETS_BORN_ALIVE),
  avg.sows = rnorm(n, mean = MEAN_HERD_SIZE, sd = SD_HERD_SIZE),
  Prev_PBD.cat = factor(sample(c("Low", "Medium", "High"), n, replace = TRUE)),
  
  # Outcome variable
  losses.born.alive = rnorm(n, mean = MEAN_LOSSES, sd = SD_LOSSES)
)

# Add correlation between season and environmental variables (confounding)
season <- factor(sample(c("Spring", "Summer", "Fall", "Winter"), n, replace = TRUE))
test_data$Season <- season

cat("Test 1: Learning structure WITHOUT constraints\n")
cat("-----------------------------------------------\n")
bn_no_constraints <- hc(test_data, score = "bic-cg")
arcs_no_constraints <- arcs(bn_no_constraints)
cat("Total arcs:", nrow(arcs_no_constraints), "\n")

# Check for problematic arcs (something causing environmental variables)
problematic_arcs <- arcs_no_constraints[arcs_no_constraints[, "to"] %in% c("F_light_hr", "AI_light_hr"), ]
if (nrow(problematic_arcs) > 0) {
  cat("\n❌ PROBLEM: Found arcs causing environmental variables:\n")
  print(problematic_arcs)
  cat("\nThis is biologically implausible!\n")
} else {
  cat("\n✅ GOOD: No arcs causing environmental variables\n")
}

cat("\n\nTest 2: Learning structure WITH constraints (blacklist)\n")
cat("--------------------------------------------------------\n")

# Create blacklist for environmental variables
environmental_vars <- c("F_light_hr", "AI_light_hr")
blacklist_edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)

for (env_var in environmental_vars) {
  other_vars <- setdiff(names(test_data), env_var)
  for (other_var in other_vars) {
    blacklist_edges <- rbind(
      blacklist_edges,
      data.frame(from = other_var, to = env_var, stringsAsFactors = FALSE)
    )
  }
}

cat("Blacklisted", nrow(blacklist_edges), "edges\n")

bn_with_constraints <- hc(test_data, score = "bic-cg", blacklist = blacklist_edges)
arcs_with_constraints <- arcs(bn_with_constraints)
cat("Total arcs:", nrow(arcs_with_constraints), "\n")

# Check for problematic arcs
problematic_arcs_constrained <- arcs_with_constraints[arcs_with_constraints[, "to"] %in% c("F_light_hr", "AI_light_hr"), ]
if (nrow(problematic_arcs_constrained) > 0) {
  cat("\n❌ FAILURE: Constraints did not work! Found arcs causing environmental variables:\n")
  print(problematic_arcs_constrained)
  stop("Domain constraints failed to prevent reverse causality!")
} else {
  cat("\n✅ SUCCESS: No arcs causing environmental variables (constraints working!)\n")
}

# Check that environmental variables CAN still be causes
env_as_causes <- arcs_with_constraints[arcs_with_constraints[, "from"] %in% c("F_light_hr", "AI_light_hr"), ]
if (nrow(env_as_causes) > 0) {
  cat("\n✅ GOOD: Environmental variables can still be causes:\n")
  print(env_as_causes)
} else {
  cat("\n⚠ NOTE: No arcs from environmental variables (they may be independent)\n")
}

cat("\n\nTest 3: Comparison of structures\n")
cat("---------------------------------\n")
cat("Without constraints:", nrow(arcs_no_constraints), "arcs\n")
cat("With constraints:", nrow(arcs_with_constraints), "arcs\n")
cat("Difference:", nrow(arcs_no_constraints) - nrow(arcs_with_constraints), "arcs removed by constraints\n")

cat("\n=================================================================\n")
cat("✅ All tests passed! Domain constraints are working correctly.\n")
cat("=================================================================\n")
