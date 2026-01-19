# Usage Guide - Causal Analysis of Piglet Loss

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Data Preparation](#data-preparation)
4. [Running the Analysis](#running-the-analysis)
5. [Understanding Results](#understanding-results)
6. [Advanced Usage](#advanced-usage)
7. [Troubleshooting](#troubleshooting)

## Introduction

This guide provides step-by-step instructions for performing causal analysis on piglet loss data. The analysis uses state-of-the-art causal discovery algorithms to identify relationships between farm management practices and reproductive outcomes.

### What is Causal Analysis?

Causal analysis goes beyond correlation to identify directional relationships between variables. Instead of just knowing that two variables are related, causal analysis helps determine:
- Which variable influences which (direction of causality)
- How strong the causal relationship is
- Whether relationships are direct or mediated through other variables

## Installation

### Step 1: Install R

Download and install R from [CRAN](https://cran.r-project.org/):
- **Windows**: Download the `.exe` installer
- **macOS**: Download the `.pkg` installer
- **Linux**: Use your package manager (e.g., `sudo apt-get install r-base`)

### Step 2: Install RStudio (Optional but Recommended)

Download from [RStudio](https://www.rstudio.com/products/rstudio/download/)

### Step 3: Verify Installation

Open R or RStudio and run:
```r
version
```

You should see R version 4.0.0 or higher.

## Data Preparation

### Using Your Own Data

1. Place your `bdporc_dataC2.RData` file in the repository directory
2. Ensure the data contains all required variables:
   - avg.sows
   - prev_sowlactpd
   - Prev_PBA
   - previous_weaned
   - sow_age_first_mating
   - F_light_hr
   - AI_light_hr
   - Company_farm
   - Year
   - Seasons
   - Prev_PBD.cat
   - prev_losses.born.alive.cat

### Using Example Data (for Testing)

If you don't have the real data yet, generate example data:

```r
source("generate_example_data.R")
```

This creates a synthetic dataset with the same structure for testing purposes.

## Running the Analysis

### Method 1: RStudio (Recommended for Beginners)

1. Open RStudio
2. Set working directory: `Session > Set Working Directory > Choose Directory`
3. Navigate to the repository folder
4. Open `causal_analysis.R`
5. Click "Source" button (top-right of editor) or press `Ctrl+Shift+S` (Windows/Linux) or `Cmd+Shift+S` (macOS)

### Method 2: R Console

1. Open R
2. Set working directory:
   ```r
   setwd("/path/to/Causal_pigletLoss")
   ```
3. Run the script:
   ```r
   source("causal_analysis.R")
   ```

### Method 3: Command Line

```bash
cd /path/to/Causal_pigletLoss
Rscript causal_analysis.R
```

### What Happens During Execution

The script will:
1. Check and install required packages (first run may take 5-10 minutes)
2. Load the data file
3. Verify all variables are present
4. Clean and prepare the data
5. Run PC algorithm on continuous variables (~1-2 minutes)
6. Learn Bayesian network structure (~2-3 minutes)
7. Perform bootstrap analysis (~5-10 minutes)
8. Generate visualizations and reports
9. Save all results

**Total time**: 15-30 minutes depending on data size and computer speed

## Understanding Results

### Output Files

After running the analysis, you'll find:

#### 1. causal_graph_continuous.pdf
- Shows causal relationships between continuous variables only
- Arrows indicate causal direction
- Generated using PC algorithm

**How to read:**
- `A → B`: A causes B
- `A — B`: A and B are related, but direction is unclear
- No connection: No direct causal relationship detected

#### 2. causal_graph_bayesian_network.pdf
- Shows complete network including all variable types
- More comprehensive than PC algorithm graph
- Includes discrete and continuous variables

#### 3. arc_strength_plot.pdf
- Shows reliability of each causal relationship
- Thicker lines = stronger relationships
- Based on bootstrap analysis

**Interpretation:**
- **Thick, dark lines**: Very reliable relationships (appear in >80% of bootstrap samples)
- **Medium lines**: Moderately reliable (50-80%)
- **Thin, light lines**: Less reliable (<50%), may be spurious

#### 4. strong_causal_relationships.csv
- Tabular format for easy analysis
- Contains only relationships with strength > 0.5

**Columns:**
- `from`: Causing variable
- `to`: Affected variable
- `strength`: Proportion of bootstrap samples containing this relationship (0-1)
- `direction`: Consistency of causal direction (0-1)

**Example row:**
```
from,to,strength,direction
prev_sowlactpd,Prev_PBA,0.85,0.92
```
Interpretation: Previous lactation period → Piglets born alive
- Appears in 85% of bootstrap samples
- Direction is consistent in 92% of samples

#### 5. causal_analysis_results.RData
- Complete R workspace
- Can be reloaded for further analysis
- Contains all intermediate results

**To reload:**
```r
load("causal_analysis_results.RData")
```

### Console Output

The script prints detailed information during execution:

#### Section 1: Data Loading
```
=== Loading Data ===
Loaded objects: example_data
Using data frame: example_data
Data dimensions: 1000 rows x 12 columns
```

#### Section 2: Variable Selection
```
=== Selecting Variables for Causal Analysis ===
✓ avg.sows - found
✓ prev_sowlactpd - found
...
Selected 12 variables for analysis
```

#### Section 3: Preprocessing
```
=== Data Preprocessing ===
Removed 48 rows with missing values
Final dataset: 952 rows
```

#### Section 4: Causal Relationships
```
Identified Causal Relationships:
  prev_sowlactpd -> Prev_PBA
  avg.sows -> previous_weaned
  sow_age_first_mating -> Prev_PBA
```

#### Section 5: Summary Report
```
================================================================================
                        CAUSAL ANALYSIS SUMMARY REPORT
================================================================================
...
Key Findings:
  - Total causal relationships identified: 15
  - Strong relationships (bootstrap strength > 0.5): 8
...
```

## Advanced Usage

### Customizing the Analysis

#### 1. Change Significance Level

More strict (fewer, more confident relationships):
```r
# Edit line 128 in causal_analysis.R
alpha = 0.01  # Instead of 0.05
```

Less strict (more relationships, potentially spurious):
```r
alpha = 0.10
```

#### 2. Increase Bootstrap Samples

For more reliable strength estimates (slower):
```r
# Edit line 243 in causal_analysis.R
boot_strength <- boot.strength(bnlearn_data, R = 500, ...)  # Instead of R = 200
```

#### 3. Try Different Algorithms

The script uses Hill-Climbing by default. Try others:

**Tabu search** (often better, slower):
```r
bn_structure <- tabu(bnlearn_data, score = "bic-g")
```

**Greedy search** (faster, may miss optimal solution):
```r
bn_structure <- gs(bnlearn_data)
```

#### 4. Add Constraints

If you know certain relationships can't exist:

```r
# Create blacklist (relationships that should NOT exist)
blacklist <- data.frame(
  from = c("Year", "Seasons"),
  to = c("sow_age_first_mating", "sow_age_first_mating")
)

bn_structure <- hc(bnlearn_data, score = "bic-g", blacklist = blacklist)
```

### Extracting Specific Information

After running the analysis, you can query the results:

```r
# Load results
load("causal_analysis_results.RData")

# Get all parents of a variable
parents(bn_structure, "Prev_PBA")

# Get all children of a variable
children(bn_structure, "avg.sows")

# Get Markov blanket (parents, children, and parents of children)
mb(bn_structure, "Prev_PBA")

# Test specific relationship
ci.test("Prev_PBA", "previous_weaned", data = bnlearn_data)
```

### Exporting for Publications

```r
# Export graph in different formats
library(igraph)
g <- as.igraph(bn_structure)

# Export as GraphML (can be opened in Gephi, Cytoscape)
write_graph(g, "causal_network.graphml", format = "graphml")

# Export adjacency matrix
write.csv(amat(bn_structure), "adjacency_matrix.csv")

# Get network statistics
cat("Number of nodes:", length(nodes(bn_structure)), "\n")
cat("Number of arcs:", narcs(bn_structure), "\n")
cat("Average Markov blanket size:", mean(sapply(nodes(bn_structure), 
    function(x) length(mb(bn_structure, x)))), "\n")
```

## Troubleshooting

### Common Errors and Solutions

#### Error: "Data file not found"

**Problem**: Script can't find `bdporc_dataC2.RData`

**Solutions:**
1. Check working directory: `getwd()`
2. Set correct directory: `setwd("/path/to/data")`
3. Ensure filename is exactly `bdporc_dataC2.RData` (case-sensitive on Linux/macOS)

#### Error: "Variable not found in data"

**Problem**: Expected variable names don't match actual data

**Solutions:**
1. Check available variables: `names(data)`
2. Update variable names in script to match your data
3. Check the Excel file `Colnames_discription.xlsx` for correct names

#### Error: "Package installation failed"

**Problem**: Required packages won't install

**Solutions:**
1. Install Bioconductor packages manually:
   ```r
   if (!requireNamespace("BiocManager", quietly = TRUE))
       install.packages("BiocManager")
   BiocManager::install(c("graph", "Rgraphviz"))
   ```

2. If still failing, check your R version (need 4.0.0+)

3. On Linux, you may need system libraries:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libxml2-dev libgraphviz-dev
   ```

#### Warning: "Removed X rows with missing values"

**Problem**: Data contains missing values

**Solutions:**
1. If many rows removed (>20%), investigate why:
   ```r
   # Check missing patterns
   colSums(is.na(data[, matched_vars]))
   ```

2. Consider imputation instead of deletion (advanced):
   ```r
   library(mice)
   imputed_data <- mice(analysis_data, m = 5, method = "pmm")
   ```

#### Error: "Insufficient data for analysis"

**Problem**: Too few observations after cleaning

**Solutions:**
1. Need at least 100 observations for reliable causal discovery
2. Check if too many missing values
3. Consider using subset of variables with more complete data

#### Results: "No causal relationships identified"

**Problem**: Algorithm found no relationships

**Possible reasons:**
1. Alpha too strict (try 0.10 instead of 0.05)
2. Data truly has no relationships
3. Sample size too small (need >100 observations)
4. Variables are too noisy

**Solutions:**
1. Relax significance level
2. Increase sample size
3. Check data quality
4. Try different algorithm (Tabu instead of Hill-Climbing)

### Getting Help

If you encounter other issues:

1. Check R error messages carefully
2. Ensure all files are in correct locations
3. Verify R version and package versions
4. Check data format and variable names
5. Review the Excel documentation file

### Performance Tips

For large datasets (>10,000 observations):

1. Use parallel processing:
   ```r
   library(parallel)
   cl <- makeCluster(detectCores() - 1)
   boot_strength <- boot.strength(bnlearn_data, R = 200, 
                                   algorithm = "hc", 
                                   cluster = cl)
   stopCluster(cl)
   ```

2. Reduce bootstrap samples (R = 100 instead of 200)

3. Use subset of data for initial exploration:
   ```r
   sample_data <- analysis_data[sample(nrow(analysis_data), 1000), ]
   ```

## Next Steps

After completing the causal analysis:

1. **Interpret results** in context of domain knowledge
2. **Validate findings** with subject matter experts
3. **Test interventions** based on identified causal relationships
4. **Refine analysis** based on feedback
5. **Document insights** for stakeholders

Remember: Causal discovery is a tool to guide understanding, not a definitive answer. Always combine statistical results with domain expertise and experimental validation when possible.
