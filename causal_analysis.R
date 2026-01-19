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

# Set working directory
cat("Setting working directory...\n")
setwd("/GMA_NAS1/miriam/Causal_pigletLoss")
cat("Working directory:", getwd(), "\n\n")

# Function to install packages if not available
install_if_missing <- function(packages, bioc_packages = character()) {
  # First, ensure BiocManager is installed if we have Bioconductor packages
  if (length(bioc_packages) > 0) {
    if (!require("BiocManager", quietly = TRUE)) {
      cat("Installing BiocManager...\n")
      install.packages("BiocManager", repos = "https://cloud.r-project.org/")
      if (!require("BiocManager", quietly = TRUE)) {
        stop("Failed to install BiocManager. Please install it manually:\n",
             "  install.packages('BiocManager')")
      }
    }
  }
  
  # Install CRAN packages
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("Installing CRAN package:", pkg, "\n")
      install.packages(pkg, repos = "https://cloud.r-project.org/")
      if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
        stop("Failed to install package: ", pkg)
      }
    }
  }
  
  # Install Bioconductor packages
  for (pkg in bioc_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("Installing Bioconductor package:", pkg, "\n")
      BiocManager::install(pkg, update = TRUE, ask = FALSE)
      if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
        stop("Failed to install Bioconductor package: ", pkg)
      }
    }
  }
}

# Define packages
cran_packages <- c("bnlearn", "dplyr", "ggplot2")
bioc_packages <- c("graph", "Rgraphviz", "pcalg")

cat("Checking and installing required packages...\n")
cat("This may take several minutes on first run...\n\n")
install_if_missing(cran_packages, bioc_packages)

# Load required libraries (now guaranteed to be installed)
library(pcalg)      # For PC algorithm causal discovery
library(graph)      # For graph operations
library(Rgraphviz)  # For graph visualization
library(bnlearn)    # Alternative causal discovery methods

################################################################################
# 1. DATA LOADING
################################################################################

cat("\n=== Loading Data ===\n")

# Load the data file
# The data file should be in the working directory (/GMA_NAS1/miriam/Causal_pigletLoss)
data_file <- "bdporc_dataC2.RData"

if (!file.exists(data_file)) {
  stop("Error: Data file '", data_file, "' not found in working directory.\n",
       "Working directory: ", getwd(), "\n",
       "Please ensure the data file is present.")
}

cat("Loading data from:", file.path(getwd(), data_file), "\n")
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
# Based on the problem statement and user feedback:
# TARGET OUTCOME: losses.born.alive (lactation losses over born alive)
# PREDICTOR VARIABLES (12):
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

# TARGET OUTCOME VARIABLE
target_variable <- "losses.born.alive"  # Lactation losses over born alive (continuous)

# PREDICTOR VARIABLES
predictor_list <- c(
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

# ALL VARIABLES (target + predictors)
variable_list <- c(target_variable, predictor_list)

# Note: Some variable names might differ in capitalization or exact spelling
# Let's check which variables are actually present in the data
available_vars <- names(data)
cat("\nChecking variable availability:\n")

# Try to match variables (case-insensitive)
matched_vars <- character()
missing_vars <- character()
var_name_map <- list()  # Map from original to matched names

for (var in variable_list) {
  # Try exact match first
  if (var %in% available_vars) {
    matched_vars <- c(matched_vars, var)
    var_name_map[[var]] <- var
    cat("  ✓", var, "- found\n")
  } else {
    # Try case-insensitive match
    match_idx <- grep(paste0("^", var, "$"), available_vars, ignore.case = TRUE)
    if (length(match_idx) > 0) {
      matched_var <- available_vars[match_idx[1]]
      matched_vars <- c(matched_vars, matched_var)
      var_name_map[[var]] <- matched_var
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
# Use the target_variable defined earlier (don't duplicate)

# Get the actual matched names for each variable category
# This handles case differences (e.g., Company_farm vs company_farm)

# Continuous predictor variables (for PC algorithm)
continuous_vars_orig <- c(
  target_variable,                     # TARGET: Lactation losses over born alive
  "avg.sows", "prev_sowlactpd", "Prev_PBA", "previous_weaned",
  "sow_age_first_mating", "F_light_hr", "AI_light_hr"
)

# Discrete variables
discrete_vars_orig <- c(
  "Year", "Seasons", "Prev_PBD.cat", "prev_losses.born.alive.cat"
)

# Random factor (for mixed models, not directly in causal discovery)
random_factor_orig <- "Company_farm"

# Map to actual variable names in the data (handles case differences)
continuous_vars <- unname(sapply(continuous_vars_orig, function(v) {
  if (v %in% names(var_name_map)) var_name_map[[v]] else v
}))
continuous_vars <- intersect(continuous_vars, matched_vars)

discrete_vars <- unname(sapply(discrete_vars_orig, function(v) {
  if (v %in% names(var_name_map)) var_name_map[[v]] else v
}))
discrete_vars <- intersect(discrete_vars, matched_vars)

random_factor <- if (random_factor_orig %in% names(var_name_map)) {
  var_name_map[[random_factor_orig]]
} else {
  random_factor_orig
}
random_factor <- intersect(random_factor, matched_vars)

cat("\n*** TARGET OUTCOME VARIABLE ***\n")
if (target_variable %in% matched_vars) {
  cat("  ✓", target_variable, "(continuous) - Lactation losses over born alive\n")
} else {
  cat("  ✗", target_variable, "- NOT FOUND (analysis may be limited)\n")
}

# Count predictor variables (excluding target if present)
continuous_predictors <- setdiff(continuous_vars, target_variable)
cat("\nContinuous predictor variables (", length(continuous_predictors), "):\n")
cat(paste("  -", continuous_predictors, collapse = "\n"), "\n")

cat("\nDiscrete predictor variables (", length(discrete_vars), "):\n")
cat(paste("  -", discrete_vars, collapse = "\n"), "\n")

if (length(random_factor) > 0) {
  cat("\nRandom factor:\n")
  cat(paste("  -", random_factor, collapse = "\n"), "\n")
}

cat("\n*** ANALYSIS FOCUS ***\n")
cat("The causal analysis will examine how the 12 predictor variables\n")
cat("causally affect the target outcome:", target_variable, "\n\n")

# Convert discrete variables to factors
for (var in discrete_vars) {
  if (var %in% names(analysis_data)) {
    if (is.character(analysis_data[[var]])) {
      cat("Converting discrete variable", var, "from character to factor\n")
    }
    analysis_data[[var]] <- as.factor(analysis_data[[var]])
  }
}

# Convert random factor to factor
# Note: Company_farm is often character type and must be converted to factor
for (var in random_factor) {
  if (var %in% names(analysis_data)) {
    if (is.character(analysis_data[[var]])) {
      cat("Converting random factor", var, "from character to factor\n")
      cat("  This variable will be included in the analysis as a discrete factor\n")
    }
    analysis_data[[var]] <- as.factor(analysis_data[[var]])
    cat("  ✓", var, "has", length(levels(analysis_data[[var]])), "levels\n")
  } else {
    cat("  ✗ Warning:", var, "not found in data\n")
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
  
  # Save the graph with larger text size for readability
  pdf("causal_graph_continuous.pdf", width = 12, height = 10)
  # Increase text size: cex controls overall size, cex.main for title, cex.axis for axis labels
  plot(pc_result, main = "Causal Graph - Continuous Variables (PC Algorithm)", 
       cex = 1.5, cex.main = 1.8)
  dev.off()
  cat("\nCausal graph saved to: causal_graph_continuous.pdf\n")
  
  # Identify edges (causal relationships)
  edges <- which(adj_matrix != 0, arr.ind = TRUE)
  if (nrow(edges) > 0) {
    cat("\nIdentified Causal Relationships:\n")
    
    # Separate relationships involving the target outcome
    target_related <- c()
    other_relationships <- c()
    
    for (i in 1:nrow(edges)) {
      from <- rownames(adj_matrix)[edges[i, 1]]
      to <- colnames(adj_matrix)[edges[i, 2]]
      relationship <- paste("  ", from, "->", to)
      
      if (from == target_variable || to == target_variable) {
        target_related <- c(target_related, relationship)
      } else {
        other_relationships <- c(other_relationships, relationship)
      }
    }
    
    if (length(target_related) > 0) {
      cat("\n*** Relationships involving TARGET (", target_variable, ") ***\n", sep = "")
      cat(paste(target_related, collapse = "\n"), "\n")
    }
    
    if (length(other_relationships) > 0) {
      cat("\nOther relationships between predictors:\n")
      cat(paste(other_relationships, collapse = "\n"), "\n")
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
# For mixed data, we use conditional Gaussian Bayesian Networks (CG-BN)
# which allows both continuous and discrete variables

# Prepare data for bnlearn
# Convert all discrete/factor variables properly
bnlearn_data <- analysis_data

# For bnlearn, we need to ensure proper data types
# IMPORTANT: bnlearn cannot handle character variables - they must be factors
for (var in names(bnlearn_data)) {
  if (var %in% c(discrete_vars, random_factor)) {
    # Convert to factor (handles both character and numeric discrete variables)
    bnlearn_data[[var]] <- as.factor(bnlearn_data[[var]])
  } else if (var %in% continuous_vars) {
    bnlearn_data[[var]] <- as.numeric(bnlearn_data[[var]])
  } else if (is.character(bnlearn_data[[var]])) {
    # Any remaining character variables should be converted to factors
    cat("Warning: Converting character variable", var, "to factor\n")
    bnlearn_data[[var]] <- as.factor(bnlearn_data[[var]])
  }
}

cat("\nRunning Hill-Climbing algorithm with appropriate BIC score...\n")
cat("Number of observations:", nrow(bnlearn_data), "\n")
cat("Number of variables:", ncol(bnlearn_data), "\n")

# Determine if we have mixed data (both continuous and discrete)
has_continuous <- any(sapply(bnlearn_data, is.numeric))
has_discrete <- any(sapply(bnlearn_data, is.factor))

# Select appropriate score based on data types
if (has_continuous && has_discrete) {
  cat("Data type: Mixed (continuous and discrete variables)\n")
  cat("Using conditional Gaussian BN with bic-cg score\n\n")
  selected_score <- "bic-cg"
} else if (has_continuous) {
  cat("Data type: Continuous only\n")
  cat("Using Gaussian BN with bic-g score\n\n")
  selected_score <- "bic-g"
} else {
  cat("Data type: Discrete only\n")
  cat("Using discrete BN with bic score\n\n")
  selected_score <- "bic"
}

# Learn the structure using hill-climbing with selected score
bn_structure <- hc(bnlearn_data, score = selected_score)

cat("\n=== Bayesian Network Structure ===\n")
print(bn_structure)

# Get the arcs (directed edges)
arcs_bn <- arcs(bn_structure)
cat("\nNumber of arcs (directed edges):", nrow(arcs_bn), "\n")

if (nrow(arcs_bn) > 0) {
  cat("\nIdentified Causal Relationships (Bayesian Network):\n")
  
  # Separate relationships involving the target outcome
  target_causes <- c()
  target_effects <- c()
  other_relationships <- c()
  
  for (i in 1:nrow(arcs_bn)) {
    from <- arcs_bn[i, "from"]
    to <- arcs_bn[i, "to"]
    
    if (to == target_variable) {
      target_causes <- c(target_causes, from)
      cat("  ", from, "->", to, " *** (CAUSES TARGET) ***\n", sep = "")
    } else if (from == target_variable) {
      target_effects <- c(target_effects, to)
      cat("  ", from, "->", to, " (target affects this)\n", sep = "")
    } else {
      other_relationships <- c(other_relationships, paste(from, "->", to))
    }
  }
  
  cat("\n*** DIRECT CAUSES OF TARGET (", target_variable, ") ***\n", sep = "")
  if (length(target_causes) > 0) {
    cat("Variables that directly cause ", target_variable, ":\n", sep = "")
    cat(paste("  -", target_causes, collapse = "\n"), "\n")
  } else {
    cat("No direct causes identified (may indicate independence or data issues)\n")
  }
  
  if (length(other_relationships) > 0) {
    cat("\nOther relationships (between predictors):\n")
    cat(paste("  ", other_relationships, collapse = "\n"), "\n")
  }
}

# Plot the Bayesian network with larger PDF size
pdf("causal_graph_bayesian_network.pdf", width = 14, height = 12)
# Highlight the target variable
node_attrs <- list()
if (target_variable %in% nodes(bn_structure)) {
  node_attrs[[target_variable]] <- list(fillcolor = "lightblue", style = "filled")
}
graphviz.plot(bn_structure, main = paste("Causal DAG - Focus on", target_variable))
dev.off()
cat("\nBayesian network graph saved to: causal_graph_bayesian_network.pdf\n")

# Calculate network score using the same score type as structure learning
bn_score <- score(bn_structure, bnlearn_data, type = selected_score)
cat("\nBIC Score (", selected_score, "):", bn_score, "\n")

################################################################################
# 5.5. TARGET VARIABLE CAUSAL STRUCTURE ANALYSIS
################################################################################

cat("\n\n=== Detailed Analysis of Target Variable (", target_variable, ") ===\n", sep = "")

# Get parents (direct causes)
if (target_variable %in% nodes(bn_structure)) {
  target_parents <- parents(bn_structure, target_variable)
  cat("\nDirect causes (parents) of", target_variable, ":\n")
  if (length(target_parents) > 0) {
    cat(paste("  ", 1:length(target_parents), ". ", target_parents, sep = "", collapse = "\n"), "\n")
    cat("\nThese", length(target_parents), "variable(s) directly influence", target_variable, "\n")
  } else {
    cat("  None identified (may indicate the target is independent or exogenous)\n")
  }
  
  # Get children (direct effects)
  target_children <- children(bn_structure, target_variable)
  cat("\nDirect effects (children) of", target_variable, ":\n")
  if (length(target_children) > 0) {
    cat(paste("  ", 1:length(target_children), ". ", target_children, sep = "", collapse = "\n"), "\n")
  } else {
    cat("  None identified\n")
  }
  
  # Get Markov blanket (parents + children + parents of children)
  target_mb <- mb(bn_structure, target_variable)
  cat("\nMarkov Blanket of", target_variable, ":\n")
  cat("(Variables that are statistically relevant for predicting", target_variable, ")\n")
  if (length(target_mb) > 0) {
    cat(paste("  ", 1:length(target_mb), ". ", target_mb, sep = "", collapse = "\n"), "\n")
  } else {
    cat("  None identified\n")
  }
  
  # Create a focused subgraph showing only target and its immediate neighbors
  if (length(target_parents) > 0 || length(target_children) > 0) {
    cat("\n*** Creating focused DAG for target variable ***\n")
    
    # Get all relevant nodes (target + markov blanket)
    relevant_nodes <- unique(c(target_variable, target_mb))
    
    # Extract subgraph
    if (length(relevant_nodes) > 1) {
      # Filter arcs to only those involving relevant nodes
      all_arcs <- arcs(bn_structure)
      relevant_arcs <- all_arcs[all_arcs[, "from"] %in% relevant_nodes & 
                                 all_arcs[, "to"] %in% relevant_nodes, , drop = FALSE]
      
      if (nrow(relevant_arcs) > 0) {
        # Create subgraph
        subgraph <- empty.graph(relevant_nodes)
        arcs(subgraph) <- relevant_arcs
        
        # Plot focused DAG with larger PDF size
        pdf("causal_dag_target_focused.pdf", width = 12, height = 10)
        graphviz.plot(subgraph, 
                     main = paste("Focused DAG: Direct Causes and Effects of", target_variable))
        dev.off()
        cat("Focused DAG saved to: causal_dag_target_focused.pdf\n")
      }
    }
  }
} else {
  cat("\nWarning: Target variable", target_variable, "not found in the Bayesian network\n")
}

################################################################################
# 6. STRENGTH OF RELATIONSHIPS
################################################################################

cat("\n\n=== Assessing Strength of Causal Relationships ===\n")

# Bootstrap to assess arc strength
cat("\nPerforming bootstrap to assess arc strength (this may take a while)...\n")

# Use the same score as determined earlier for consistency
cat("Using", selected_score, "score for bootstrap analysis\n")
boot_strength <- boot.strength(bnlearn_data, R = 200, algorithm = "hc", 
                               algorithm.args = list(score = selected_score))

# Filter strong arcs (strength > 0.5, direction > 0.5)
strong_arcs <- boot_strength[boot_strength$strength > 0.5 & boot_strength$direction > 0.5, ]

if (nrow(strong_arcs) > 0) {
  cat("\nStrong Causal Relationships (strength > 0.5, direction > 0.5):\n")
  
  # Separate target-related and other relationships
  target_arcs <- strong_arcs[strong_arcs$from == target_variable | strong_arcs$to == target_variable, ]
  other_arcs <- strong_arcs[strong_arcs$from != target_variable & strong_arcs$to != target_variable, ]
  
  if (nrow(target_arcs) > 0) {
    cat("\n*** Strong relationships involving TARGET (", target_variable, ") ***\n", sep = "")
    print(target_arcs[order(-target_arcs$strength), ])
  }
  
  if (nrow(other_arcs) > 0) {
    cat("\nStrong relationships between predictors:\n")
    print(other_arcs[order(-other_arcs$strength), ])
  }
  
  # Save to CSV
  write.csv(strong_arcs, "strong_causal_relationships.csv", row.names = FALSE)
  cat("\nAll strong relationships saved to: strong_causal_relationships.csv\n")
  
  # Save target-specific relationships if any
  if (nrow(target_arcs) > 0) {
    write.csv(target_arcs, "target_causal_relationships.csv", row.names = FALSE)
    cat("Target-specific relationships saved to: target_causal_relationships.csv\n")
  }
} else {
  cat("\nNo strong causal relationships found with current thresholds\n")
}

# Plot arc strength with larger PDF size
pdf("arc_strength_plot.pdf", width = 14, height = 12)
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

cat("*** RESEARCH OBJECTIVE ***\n")
cat("Assess causal relationships between 12 predictor variables and the outcome:\n")
cat("  TARGET: ", target_variable, " (lactation losses over born alive)\n", sep = "")
cat("\n")

cat("Dataset Information:\n")
cat("  - Total observations:", nrow(analysis_data), "\n")
cat("  - Total variables analyzed:", ncol(analysis_data), "\n")
cat("  - Target outcome: 1 (", target_variable, ")\n", sep = "")
cat("  - Continuous predictors:", length(continuous_vars) - 1, "\n")
cat("  - Discrete predictors:", length(discrete_vars), "\n")
cat("  - Random factors:", length(random_factor), "\n")
cat("\n")

cat("Analysis Methods Used:\n")
cat("  1. PC Algorithm (Peter-Clark) for continuous variables\n")
cat("  2. Hill-Climbing with BIC score for all variables (Bayesian Network/DAG)\n")
cat("  3. Bootstrap analysis (200 samples) for arc strength assessment\n")
cat("  4. Markov Blanket analysis for target variable\n")
cat("\n")

cat("Output Files Generated:\n")
cat("  - causal_graph_continuous.pdf: Causal graph from PC algorithm\n")
cat("  - causal_graph_bayesian_network.pdf: Complete Bayesian network (DAG)\n")
cat("  - causal_dag_target_focused.pdf: Focused DAG showing causes of target\n")
cat("  - arc_strength_plot.pdf: Arc strength visualization\n")
cat("  - strong_causal_relationships.csv: Table of all strong relationships\n")
cat("  - target_causal_relationships.csv: Relationships involving target only\n")
cat("\n")

cat("*** KEY FINDINGS ***\n")
if (exists("arcs_bn") && nrow(arcs_bn) > 0) {
  cat("Total causal relationships identified:", nrow(arcs_bn), "\n")
  
  if (exists("target_causes") && length(target_causes) > 0) {
    cat("\nDirect causes of", target_variable, "(", length(target_causes), "):\n")
    cat(paste("  -", target_causes, collapse = "\n"), "\n")
  } else {
    cat("\nDirect causes of", target_variable, ": None identified\n")
  }
  
  if (exists("strong_arcs") && nrow(strong_arcs) > 0) {
    cat("\nStrong relationships (bootstrap strength > 0.5):", nrow(strong_arcs), "\n")
    if (exists("target_arcs") && nrow(target_arcs) > 0) {
      cat("  - Involving target:", nrow(target_arcs), "\n")
    }
  }
}
cat("\n")

cat("Interpretation Notes:\n")
cat("  - The DAG shows causal direction: X -> Y means X causally influences Y\n")
cat("  - Direct causes (parents) of the target are the primary variables to consider\n")
cat("  - Markov blanket variables are statistically relevant for prediction\n")
cat("  - Strength > 0.5 indicates reliable relationship (appears in >50% of bootstraps)\n")
cat("  - BIC score:", ifelse(exists("bn_score"), round(bn_score, 2), "N/A"), "\n")
cat("\n")

cat("================================================================================\n")
cat("Analysis completed successfully!\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("================================================================================\n")

# Save the workspace for further analysis
save.image("causal_analysis_results.RData")
cat("\nWorkspace saved to: causal_analysis_results.RData\n")
cat("You can reload this with: load('causal_analysis_results.RData')\n")
