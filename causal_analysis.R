################################################################################
# Causal Analysis of Piglet Loss Variables
################################################################################
# This script performs causal discovery analysis on a set of variables related
# to piglet loss in sow farms. It uses the PC algorithm and other causal
# discovery methods to identify causal relationships between variables.
#
# Author: Causal Analysis Script
# Date: 2026-01-19
################################################################################

# Load required libraries
library(pcalg)      # For PC algorithm causal discovery
library(graph)      # For graph operations
library(Rgraphviz)  # For graph visualization
library(bnlearn)    # Alternative causal discovery methods

# Function to install packages if not available
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org/")
      library(pkg, character.only = TRUE)
    }
  }
}

# Install required packages
required_packages <- c("pcalg", "graph", "Rgraphviz", "bnlearn", "dplyr", "ggplot2")
cat("Checking and installing required packages...\n")
install_if_missing(required_packages)

################################################################################
# 1. DATA LOADING
################################################################################

cat("\n=== Loading Data ===\n")

# Load the data file
data_file <- "bdporc_dataC2.RData"

if (!file.exists(data_file)) {
  stop("Error: Data file 'bdporc_dataC2.RData' not found in the current directory.\n",
       "Please ensure the data file is in the working directory: ", getwd())
}

load(data_file)

# Identify the data object (it might have a different name in the .RData file)
loaded_objects <- ls()
cat("Loaded objects:", paste(loaded_objects, collapse = ", "), "\n")

# Assume the main data object is the largest data frame
data_objects <- loaded_objects[sapply(loaded_objects, function(x) is.data.frame(get(x)))]
if (length(data_objects) == 0) {
  stop("No data frame found in the loaded .RData file")
}

# Use the first data frame found
data <- get(data_objects[1])
cat("Using data frame:", data_objects[1], "\n")
cat("Data dimensions:", nrow(data), "rows x", ncol(data), "columns\n")

################################################################################
# 2. VARIABLE SELECTION AND PREPARATION
################################################################################

cat("\n=== Selecting Variables for Causal Analysis ===\n")

# Define the variables for causal analysis
# Based on the problem statement:
# 1. Avg.sows (continuous)
# 2. Prev_sowlactpd (continuous)
# 3. Prev_PBA (continuous)
# 4. Previous_weaned (continuous)
# 5. Sow_age_first_mating (continuous)
# 6. F_light_hr (continuous)
# 7. AI_light_hr (continuous)
# 8. Company_farm (random factor - will be handled separately)
# 9. Year (discrete)
# 10. Seasons (discrete)
# 11. Prev_PBD.cat (discrete)
# 12. Prev_losses.born.alive.cat (discrete)

variable_list <- c(
  "avg.sows",                      # Average number of sows
  "prev_sowlactpd",                # Previous sow lactation period
  "Prev_PBA",                      # Previous piglets born alive
  "previous_weaned",               # Previous weaned piglets
  "sow_age_first_mating",          # Sow age at first mating
  "F_light_hr",                    # Light hours at farrowing (assumed)
  "AI_light_hr",                   # Light hours at AI (assumed)
  "Company_farm",                  # Company farm (random factor)
  "Year",                          # Year
  "Seasons",                       # Season
  "Prev_PBD.cat",                  # Previous piglets born dead (categorical)
  "prev_losses.born.alive.cat"     # Previous losses over born alive (categorical)
)

# Note: Some variable names might differ in capitalization or exact spelling
# Let's check which variables are actually present in the data
available_vars <- names(data)
cat("\nChecking variable availability:\n")

# Try to match variables (case-insensitive)
matched_vars <- character()
missing_vars <- character()

for (var in variable_list) {
  # Try exact match first
  if (var %in% available_vars) {
    matched_vars <- c(matched_vars, var)
    cat("  ✓", var, "- found\n")
  } else {
    # Try case-insensitive match
    match_idx <- grep(paste0("^", var, "$"), available_vars, ignore.case = TRUE)
    if (length(match_idx) > 0) {
      matched_var <- available_vars[match_idx[1]]
      matched_vars <- c(matched_vars, matched_var)
      cat("  ✓", var, "- found as", matched_var, "\n")
    } else {
      missing_vars <- c(missing_vars, var)
      cat("  ✗", var, "- NOT FOUND\n")
    }
  }
}

if (length(missing_vars) > 0) {
  cat("\nWarning: The following variables were not found in the data:\n")
  cat(paste("  -", missing_vars, collapse = "\n"), "\n")
  cat("\nAvailable variable names in the dataset:\n")
  cat(paste(sort(available_vars), collapse = ", "), "\n")
}

# Use only matched variables for analysis
analysis_data <- data[, matched_vars, drop = FALSE]
cat("\nSelected", length(matched_vars), "variables for analysis\n")

################################################################################
# 3. DATA PREPROCESSING
################################################################################

cat("\n=== Data Preprocessing ===\n")

# Remove rows with missing values in the selected variables
original_rows <- nrow(analysis_data)
analysis_data <- na.omit(analysis_data)
cat("Removed", original_rows - nrow(analysis_data), "rows with missing values\n")
cat("Final dataset:", nrow(analysis_data), "rows\n")

# Separate continuous and discrete variables
# Continuous variables (for PC algorithm)
continuous_vars <- c(
  "avg.sows", "prev_sowlactpd", "Prev_PBA", "previous_weaned",
  "sow_age_first_mating", "F_light_hr", "AI_light_hr"
)

# Discrete variables
discrete_vars <- c(
  "Year", "Seasons", "Prev_PBD.cat", "prev_losses.born.alive.cat"
)

# Random factor (for mixed models, not directly in causal discovery)
random_factor <- "Company_farm"

# Filter to only include variables that exist in matched_vars
continuous_vars <- intersect(continuous_vars, matched_vars)
discrete_vars <- intersect(discrete_vars, matched_vars)
random_factor <- intersect(random_factor, matched_vars)

cat("\nContinuous variables (", length(continuous_vars), "):\n")
cat(paste("  -", continuous_vars, collapse = "\n"), "\n")

cat("\nDiscrete variables (", length(discrete_vars), "):\n")
cat(paste("  -", discrete_vars, collapse = "\n"), "\n")

if (length(random_factor) > 0) {
  cat("\nRandom factor:\n")
  cat(paste("  -", random_factor, collapse = "\n"), "\n")
}

# Convert discrete variables to factors
for (var in discrete_vars) {
  if (var %in% names(analysis_data)) {
    analysis_data[[var]] <- as.factor(analysis_data[[var]])
  }
}

# Convert random factor to factor
for (var in random_factor) {
  if (var %in% names(analysis_data)) {
    analysis_data[[var]] <- as.factor(analysis_data[[var]])
  }
}

################################################################################
# 4. CAUSAL DISCOVERY - PC ALGORITHM (Continuous Variables)
################################################################################

cat("\n=== Causal Discovery using PC Algorithm ===\n")

if (length(continuous_vars) >= 2) {
  # Extract continuous data for PC algorithm
  continuous_data <- analysis_data[, continuous_vars, drop = FALSE]
  
  # Standardize continuous variables for better numerical stability
  continuous_data_scaled <- scale(continuous_data)
  
  # Calculate correlation matrix
  suffStat <- list(C = cor(continuous_data_scaled), n = nrow(continuous_data_scaled))
  
  # Run PC algorithm
  # alpha: significance level for conditional independence tests
  # indepTest: independence test (Gaussian for continuous data)
  cat("\nRunning PC algorithm on continuous variables...\n")
  cat("Number of observations:", nrow(continuous_data_scaled), "\n")
  cat("Number of variables:", ncol(continuous_data_scaled), "\n")
  
  pc_result <- pc(
    suffStat = suffStat,
    indepTest = gaussCItest,
    alpha = 0.05,  # Significance level
    labels = colnames(continuous_data_scaled),
    verbose = TRUE
  )
  
  cat("\n=== PC Algorithm Results ===\n")
  print(pc_result)
  
  # Extract the adjacency matrix
  adj_matrix <- as(pc_result@graph, "matrix")
  cat("\nAdjacency Matrix:\n")
  print(adj_matrix)
  
  # Save the graph
  pdf("causal_graph_continuous.pdf", width = 10, height = 8)
  plot(pc_result, main = "Causal Graph - Continuous Variables (PC Algorithm)")
  dev.off()
  cat("\nCausal graph saved to: causal_graph_continuous.pdf\n")
  
  # Identify edges (causal relationships)
  edges <- which(adj_matrix != 0, arr.ind = TRUE)
  if (nrow(edges) > 0) {
    cat("\nIdentified Causal Relationships:\n")
    for (i in 1:nrow(edges)) {
      from <- rownames(adj_matrix)[edges[i, 1]]
      to <- colnames(adj_matrix)[edges[i, 2]]
      cat("  ", from, "->", to, "\n")
    }
  } else {
    cat("\nNo causal relationships identified at alpha = 0.05\n")
  }
  
} else {
  cat("\nInsufficient continuous variables for PC algorithm (need at least 2)\n")
}

################################################################################
# 5. CAUSAL DISCOVERY - MIXED DATA (bnlearn)
################################################################################

cat("\n\n=== Causal Discovery using bnlearn (Mixed Data) ===\n")

# bnlearn can handle mixed continuous and discrete data
# Use hill-climbing algorithm with BIC score

# Prepare data for bnlearn
# Convert all discrete/factor variables properly
bnlearn_data <- analysis_data

# For bnlearn, we need to ensure proper data types
for (var in names(bnlearn_data)) {
  if (var %in% c(discrete_vars, random_factor)) {
    bnlearn_data[[var]] <- as.factor(bnlearn_data[[var]])
  } else if (var %in% continuous_vars) {
    bnlearn_data[[var]] <- as.numeric(bnlearn_data[[var]])
  }
}

cat("\nRunning Hill-Climbing algorithm with BIC score...\n")
cat("Number of observations:", nrow(bnlearn_data), "\n")
cat("Number of variables:", ncol(bnlearn_data), "\n")

# Learn the structure using hill-climbing
bn_structure <- hc(bnlearn_data, score = "bic-g")

cat("\n=== Bayesian Network Structure ===\n")
print(bn_structure)

# Get the arcs (directed edges)
arcs_bn <- arcs(bn_structure)
cat("\nNumber of arcs (directed edges):", nrow(arcs_bn), "\n")

if (nrow(arcs_bn) > 0) {
  cat("\nIdentified Causal Relationships (Bayesian Network):\n")
  for (i in 1:nrow(arcs_bn)) {
    cat("  ", arcs_bn[i, "from"], "->", arcs_bn[i, "to"], "\n")
  }
}

# Plot the Bayesian network
pdf("causal_graph_bayesian_network.pdf", width = 12, height = 10)
graphviz.plot(bn_structure, main = "Causal Graph - Bayesian Network (All Variables)")
dev.off()
cat("\nBayesian network graph saved to: causal_graph_bayesian_network.pdf\n")

# Calculate network score
bn_score <- score(bn_structure, bnlearn_data, type = "bic-g")
cat("\nBIC Score:", bn_score, "\n")

################################################################################
# 6. STRENGTH OF RELATIONSHIPS
################################################################################

cat("\n\n=== Assessing Strength of Causal Relationships ===\n")

# Bootstrap to assess arc strength
cat("\nPerforming bootstrap to assess arc strength (this may take a while)...\n")
boot_strength <- boot.strength(bnlearn_data, R = 200, algorithm = "hc", 
                               algorithm.args = list(score = "bic-g"))

# Filter strong arcs (strength > 0.5, direction > 0.5)
strong_arcs <- boot_strength[boot_strength$strength > 0.5 & boot_strength$direction > 0.5, ]

if (nrow(strong_arcs) > 0) {
  cat("\nStrong Causal Relationships (strength > 0.5, direction > 0.5):\n")
  print(strong_arcs[order(-strong_arcs$strength), ])
  
  # Save to CSV
  write.csv(strong_arcs, "strong_causal_relationships.csv", row.names = FALSE)
  cat("\nStrong relationships saved to: strong_causal_relationships.csv\n")
} else {
  cat("\nNo strong causal relationships found with current thresholds\n")
}

# Plot arc strength
pdf("arc_strength_plot.pdf", width = 12, height = 10)
strength.plot(bn_structure, boot_strength, shape = "ellipse",
              main = "Arc Strength - Causal Relationships")
dev.off()
cat("\nArc strength plot saved to: arc_strength_plot.pdf\n")

################################################################################
# 7. CONDITIONAL INDEPENDENCE TESTS
################################################################################

cat("\n\n=== Conditional Independence Tests ===\n")

# Test some specific relationships
# Example: Is Prev_PBA independent of previous_weaned given other variables?

if (all(c("Prev_PBA", "previous_weaned") %in% names(bnlearn_data))) {
  cat("\nTesting: Prev_PBA _||_ previous_weaned | {other variables}\n")
  
  # Get conditioning set (other continuous variables)
  cond_set <- setdiff(continuous_vars, c("Prev_PBA", "previous_weaned"))
  
  if (length(cond_set) > 0) {
    ci_test <- ci.test("Prev_PBA", "previous_weaned", cond_set, 
                       data = bnlearn_data, test = "cor")
    print(ci_test)
  }
}

################################################################################
# 8. SUMMARY REPORT
################################################################################

cat("\n\n")
cat("================================================================================\n")
cat("                        CAUSAL ANALYSIS SUMMARY REPORT                          \n")
cat("================================================================================\n")
cat("\n")

cat("Dataset Information:\n")
cat("  - Total observations:", nrow(analysis_data), "\n")
cat("  - Total variables analyzed:", ncol(analysis_data), "\n")
cat("  - Continuous variables:", length(continuous_vars), "\n")
cat("  - Discrete variables:", length(discrete_vars), "\n")
cat("  - Random factors:", length(random_factor), "\n")
cat("\n")

cat("Analysis Methods Used:\n")
cat("  1. PC Algorithm (Peter-Clark) for continuous variables\n")
cat("  2. Hill-Climbing with BIC score for all variables (Bayesian Network)\n")
cat("  3. Bootstrap analysis for arc strength assessment\n")
cat("\n")

cat("Output Files Generated:\n")
cat("  - causal_graph_continuous.pdf: Causal graph from PC algorithm\n")
cat("  - causal_graph_bayesian_network.pdf: Bayesian network structure\n")
cat("  - arc_strength_plot.pdf: Arc strength visualization\n")
cat("  - strong_causal_relationships.csv: Table of strong relationships\n")
cat("\n")

cat("Key Findings:\n")
if (exists("arcs_bn") && nrow(arcs_bn) > 0) {
  cat("  - Total causal relationships identified:", nrow(arcs_bn), "\n")
  if (exists("strong_arcs") && nrow(strong_arcs) > 0) {
    cat("  - Strong relationships (bootstrap strength > 0.5):", nrow(strong_arcs), "\n")
  }
}
cat("\n")

cat("Interpretation Notes:\n")
cat("  - Arrows indicate potential causal direction (X -> Y means X may cause Y)\n")
cat("  - Strength indicates reliability of the relationship (based on bootstrap)\n")
cat("  - BIC score:", ifelse(exists("bn_score"), round(bn_score, 2), "N/A"), "\n")
cat("  - Lower BIC scores indicate better model fit\n")
cat("\n")

cat("================================================================================\n")
cat("Analysis completed successfully!\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("================================================================================\n")

# Save the workspace for further analysis
save.image("causal_analysis_results.RData")
cat("\nWorkspace saved to: causal_analysis_results.RData\n")
cat("You can reload this with: load('causal_analysis_results.RData')\n")
