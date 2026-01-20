# Fix for F_light_hr Reverse Causality Issue - Summary

## Problem
The causal analysis was showing that environmental variables (F_light_hr, AI_light_hr) were being **caused by** reproductive variables, which is biologically impossible.

Example of incorrect inference:
- `prev_PBA → F_light_hr` ❌ (Piglets born alive cannot cause light hours)
- `avg.sows → F_light_hr` ❌ (Number of sows cannot cause light hours)

## Root Cause
Causal discovery algorithms can infer incorrect directions when:
1. There are seasonal confounders affecting multiple variables
2. No domain knowledge constraints are applied
3. Variables are correlated but causally independent

## Solution
Added **domain knowledge constraints (blacklists)** to prevent environmental variables from being effects:

```r
# Environmental variables can only be CAUSES, not EFFECTS
blacklist: X → F_light_hr (for all X ≠ F_light_hr)
allowed: F_light_hr → Y (for any Y)
```

## Files Modified

### Code
- **causal_analysis.R**
  - Lines 426-487: Domain knowledge constraints implementation
  - Lines 629-636: Apply constraints to bootstrap analysis

### Documentation (Spanish)
- **METODOLOGIA_DETALLADA.md**: Section 6.3 - detailed explanation
- **SOLUCION_CAUSALIDAD_REVERSA.md**: Complete solution guide

### Documentation (English)  
- **ANALYSIS_README.md**: Domain Knowledge Constraints section

### Testing
- **test_domain_constraints.R**: Validation script

## Impact
✅ Environmental variables now correctly appear only as causes, never as effects  
✅ Causal inferences respect biological plausibility  
✅ Results are interpretable and actionable  
✅ Analysis automatically applies constraints when F_light_hr or AI_light_hr are present

## How to Use
Simply run the analysis as before - constraints apply automatically:
```r
source("causal_analysis.R")
```

The script will display:
```
*** Applying Domain Knowledge Constraints ***
Environmental variables identified: F_light_hr, AI_light_hr
Blacklisted XXX edges to prevent environmental variables from being effects
```

## Validation
To test that constraints work:
```r
Rscript test_domain_constraints.R
```

Expected output: `✅ All tests passed! Domain constraints are working correctly.`

---
**Issue Resolved**: Environmental variables can no longer be incorrectly inferred as effects of other variables.
