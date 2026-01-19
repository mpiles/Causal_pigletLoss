# Causal Analysis of Piglet Loss

This repository contains scripts for performing causal analysis on variables related to piglet loss in sow farms. The analysis investigates causal relationships between various factors including farm characteristics, sow management practices, and reproductive outcomes.

## Contents

- **causal_analysis.R** - Main causal analysis script using PC algorithm and Bayesian networks
- **ANALYSIS_README.md** - Detailed documentation and instructions
- **generate_example_data.R** - Script to generate example data for testing
- **Colnames_discription.xlsx** - Variable descriptions and metadata

## Quick Start

1. Ensure you have R installed (version 4.0.0 or higher)
2. Place your data file `bdporc_dataC2.RData` in the repository directory
3. Run the analysis:
   ```r
   source("causal_analysis.R")
   ```

For detailed instructions, see [ANALYSIS_README.md](ANALYSIS_README.md)

## Variables Analyzed

The analysis examines 12 key variables:
- 7 continuous variables (avg.sows, prev_sowlactpd, Prev_PBA, previous_weaned, sow_age_first_mating, F_light_hr, AI_light_hr)
- 4 discrete variables (Year, Seasons, Prev_PBD.cat, prev_losses.born.alive.cat)
- 1 random factor (Company_farm)

## Output

The analysis generates:
- Causal graphs (PDF format)
- Arc strength visualizations
- Table of strong causal relationships (CSV)
- Complete analysis workspace (RData)
