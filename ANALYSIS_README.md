# Causal Analysis of Piglet Loss Variables

This repository contains a comprehensive causal analysis script for investigating causal relationships between variables related to piglet loss in sow farms.

## Overview

The analysis examines causal relationships between 12 key variables:

### Variables Analyzed

1. **avg.sows** (Continuous) - Average number of sows present in a farm
2. **prev_sowlactpd** (Continuous) - Previous sow lactation period in days
3. **Prev_PBA** (Continuous) - Previous piglets born alive
4. **previous_weaned** (Continuous) - Previous cycle record of weaned piglets
5. **sow_age_first_mating** (Continuous) - Sow age at the time of first mating
6. **F_light_hr** (Continuous) - Light hours at farrowing
7. **AI_light_hr** (Continuous) - Light hours at artificial insemination
8. **Company_farm** (Random Factor) - Company code and farm name identifier
9. **Year** (Discrete) - Year of observation
10. **Seasons** (Discrete) - Season of observation
11. **Prev_PBD.cat** (Discrete) - Previous piglets born dead (categorical)
12. **prev_losses.born.alive.cat** (Discrete) - Previous lactation losses over born alive (categorical)

## Requirements

### R Version
- R >= 4.0.0

### Required R Packages

The script will automatically install missing packages. Note that some packages come from Bioconductor:

**CRAN packages:**
- bnlearn
- dplyr
- ggplot2

**Bioconductor packages:**
- pcalg
- graph
- Rgraphviz

If automatic installation fails, install them manually:

```r
# Install BiocManager first
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

# Install CRAN packages
install.packages(c("bnlearn", "dplyr", "ggplot2"))

# Install Bioconductor packages
BiocManager::install(c("pcalg", "graph", "Rgraphviz"))
```

### Data File
- **bdporc_dataC2.RData** - The main dataset containing all variables
- **Colnames_discription.xlsx** - Variable descriptions (included in repository)

## How to Run the Analysis

### Step 1: Prepare Data
Ensure that the data file `bdporc_dataC2.RData` is in the same directory as the script, or in your R working directory.

### Step 2: Run the Script

#### Option A: Run from R Console
```r
source("causal_analysis.R")
```

#### Option B: Run from Command Line
```bash
Rscript causal_analysis.R
```

### Step 3: Review Results
The script will generate several output files:

- **causal_graph_continuous.pdf** - Causal graph from PC algorithm (continuous variables only)
- **causal_graph_bayesian_network.pdf** - Full Bayesian network structure (all variables)
- **arc_strength_plot.pdf** - Visualization of arc strength from bootstrap analysis
- **strong_causal_relationships.csv** - Table of strong causal relationships
- **causal_analysis_results.RData** - Complete workspace for further analysis

## Analysis Methods

### 1. PC Algorithm (Peter-Clark)
- Used for continuous variables
- Identifies causal structure using conditional independence tests
- Based on Gaussian correlation tests
- Significance level: α = 0.05

### 2. Bayesian Network Learning
- Uses Hill-Climbing algorithm with BIC scoring
- Automatically selects appropriate scoring function based on data types:
  - **bic-cg** (Conditional Gaussian): For mixed continuous and discrete variables
  - **bic-g** (Gaussian): For continuous-only variables
  - **bic** (Discrete): For discrete-only variables
- Learns directed acyclic graph (DAG) structure
- Handles mixed data types seamlessly

### 3. Bootstrap Analysis
- Assesses reliability of identified relationships
- 200 bootstrap samples
- Provides strength and direction scores for each arc

## Interpretation Guide

### Understanding the Output

#### Causal Graphs
- **Arrows (→)** indicate potential causal direction
  - X → Y means "X may cause Y"
- **Undirected edges (—)** indicate association without clear direction

#### Arc Strength
- **Strength** (0-1): Proportion of bootstrap samples containing the arc
- **Direction** (0-1): Proportion of times the arc has the same direction
- **Strong relationships**: Strength > 0.5 AND Direction > 0.5

#### BIC Score
- Bayesian Information Criterion for model quality
- Lower values indicate better fit
- Used to compare different network structures

### Example Interpretation

If the analysis shows:
```
prev_sowlactpd -> Prev_PBA
Strength: 0.85, Direction: 0.92
```

This means:
- Previous sow lactation period may causally influence piglets born alive
- The relationship appeared in 85% of bootstrap samples
- The direction was consistent in 92% of samples

## Customization

### Adjusting Significance Level
Edit line 128 in `causal_analysis.R`:
```r
pc_result <- pc(
  ...
  alpha = 0.05,  # Change this value (e.g., 0.01 for stricter tests)
  ...
)
```

### Changing Bootstrap Samples
Edit line 243 in `causal_analysis.R`:
```r
boot_strength <- boot.strength(bnlearn_data, R = 200, ...)  # Increase R for more samples
```

### Modifying Variable Selection
If you want to analyze a different set of variables, edit the `variable_list` starting at line 56.

## Troubleshooting

### Common Issues

**Issue**: "Data file not found"
- **Solution**: Ensure `bdporc_dataC2.RData` is in the working directory. Check with `getwd()` in R.

**Issue**: "Variable not found in data"
- **Solution**: Check variable names in the data file. The script provides a list of available variables.

**Issue**: "Cannot use character variables" or character type error
- **Cause**: bnlearn requires all discrete variables to be factors, not characters. This commonly affects `Company_farm`.
- **Solution**: The script now automatically converts character variables to factors. `Company_farm` will be included as a discrete factor in the analysis.
- **Note**: If you previously removed `Company_farm` due to this error, you can now keep it in the analysis. The script handles the conversion automatically.

**Issue**: "score 'bic-g' may only be used with continuous data"
- **Cause**: Using wrong BIC score for mixed data types.
- **Solution**: The script now automatically selects the correct score (bic-cg for mixed data). This is fixed in the latest version.

**Issue**: "Package installation failed" (e.g., 'pcalg' or 'ggm' had non-zero exit status)
- **Cause**: `pcalg`, `graph`, and `Rgraphviz` are Bioconductor packages, not CRAN packages. The script has been updated to handle this automatically.
- **Solution**: If you still encounter issues, install packages manually:
  ```r
  # Step 1: Install BiocManager
  if (!requireNamespace("BiocManager", quietly = TRUE))
      install.packages("BiocManager")
  
  # Step 2: Install CRAN packages
  install.packages(c("bnlearn", "dplyr", "ggplot2"))
  
  # Step 3: Install Bioconductor packages
  BiocManager::install(c("pcalg", "graph", "Rgraphviz"))
  ```
- **Note**: On some systems, you may need system dependencies. On Linux:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install libxml2-dev libgraphviz-dev
  ```

**Issue**: "Insufficient observations"
- **Solution**: The analysis requires sufficient data. Check for missing values and ensure adequate sample size.

## References

### Methods
- **PC Algorithm**: Spirtes, P., Glymour, C., & Scheines, R. (2000). Causation, Prediction, and Search. MIT Press.
- **Bayesian Networks**: Pearl, J. (2009). Causality: Models, Reasoning, and Inference. Cambridge University Press.
- **bnlearn Package**: Scutari, M. (2010). Learning Bayesian Networks with the bnlearn R Package. Journal of Statistical Software.

### R Packages
- `pcalg`: Kalisch, M., et al. (2012). Causal Inference Using Graphical Models with the R Package pcalg.
- `bnlearn`: Scutari, M. (2010). bnlearn: Bayesian Network Structure Learning.

## Contact

For questions or issues with the analysis, please open an issue in the repository.

## License

This analysis script is provided as-is for research purposes.
