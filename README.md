# Causal Analysis of Piglet Loss

This repository contains scripts for performing causal analysis to identify which variables causally affect **lactation losses** (piglets dead during lactation) in sow farms. The analysis investigates causal relationships between 12 predictor variables and the target outcome variable `losses.born.alive`.

## Research Objective

Assess causal relationships between farm management and reproductive variables to understand what drives lactation losses, providing a Directed Acyclic Graph (DAG) showing causal pathways.

## Contents

- **causal_analysis.R** - Main causal analysis script using PC algorithm and Bayesian networks
- **ANALYSIS_README.md** - Detailed documentation and instructions
- **generate_example_data.R** - Script to generate example data for testing
- **Colnames_discription.xlsx** - Variable descriptions and metadata

## Quick Start

1. Ensure you have R installed (version 4.0.0 or higher)
2. The data file `bdporc_dataC2.RData` is located at `/work/miriam/Causal_pigletLoss/`
3. Run the analysis:
   ```r
   source("causal_analysis.R")
   ```

For detailed instructions, see [ANALYSIS_README.md](ANALYSIS_README.md)

## Target Outcome Variable

**`losses.born.alive`** - Lactation losses over born alive (continuous)
- Represents the proportion of piglets that die during lactation

## Predictor Variables (12)

The analysis examines how these variables causally affect the target:

### Continuous (7)
- avg.sows, prev_sowlactpd, Prev_PBA, previous_weaned, sow_age_first_mating, F_light_hr, AI_light_hr

### Discrete (4) 
- Year, Seasons, Prev_PBD.cat, prev_losses.born.alive.cat

### Random Factor (1)
- Company_farm

## Output

The analysis generates:
- **Directed Acyclic Graph (DAG)** showing causal structure
- Focused DAG highlighting direct causes of lactation losses
- Causal graphs (PDF format)
- Arc strength visualizations
- Table of causal relationships (CSV)
- Complete analysis workspace (RData)
