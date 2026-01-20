# Materials and Methods

## Data Collection and Study Design

### Animals and Housing

The dataset comprised reproductive performance records from commercial pig farms collected between 2018 and 2023. Data were obtained from multiple production units within a multi-site production system, representing diverse management practices and environmental conditions. All farms adhered to standard commercial practices and animal welfare regulations.

### Variables and Measurements

The outcome variable of interest was lactation mortality, defined as the proportion of piglets that died during the lactation period relative to the number born alive (losses.born.alive). This continuous variable ranged from 0 (no mortality) to 1 (complete litter loss).

Twelve predictor variables were selected based on their biological and management relevance to lactation mortality:

**Continuous variables (n=7):**
- Average number of sows present (avg.sows): operational herd size indicator
- Previous lactation period duration (prev_sowlactpd, days): lactation length in the preceding cycle
- Previous litter size born alive (Prev_PBA, count): number of piglets born alive in the previous parity
- Previous number weaned (previous_weaned, count): piglets successfully weaned in the previous cycle
- Sow age at first mating (sow_age_first_mating, days): age at initial breeding
- Photoperiod at farrowing (F_light_hr, hours): daily light exposure during parturition
- Photoperiod at artificial insemination (AI_light_hr, hours): daily light exposure at conception

**Categorical variables (n=4):**
- Year of observation (Year): temporal effects and management changes
- Season (Seasons): spring, summer, autumn, winter
- Previous stillbirths categorised (Prev_PBD.cat): low, medium, high
- Previous lactation losses categorised (prev_losses.born.alive.cat): low, medium, high

**Random effect (n=1):**
- Farm identity (Company_farm): unique farm identifier to account for farm-specific effects

### Data Processing

Prior to analysis, all continuous variables were standardised to have mean zero and unit variance to facilitate numerical stability in correlation-based tests. Categorical variables were encoded as factors, with farm identity treated as a random effect to account for clustering within production units. Records with missing values were excluded using listwise deletion, ensuring complete case analysis.

## Causal Discovery Framework

### Theoretical Foundation

Causal relationships were identified using a constraint-based approach founded on the principles of directed acyclic graphs (DAGs) and conditional independence testing [1,2]. The analysis employed two complementary methods: the PC (Peter-Clark) algorithm for continuous variables and Bayesian network structure learning for the complete dataset including both continuous and categorical variables.

### PC Algorithm for Continuous Variables

The PC algorithm identifies causal structure by iteratively testing conditional independence relationships amongst variables [3]. The algorithm operates in three phases:

**Phase 1: Skeleton identification**  
Beginning with a complete undirected graph connecting all variables, the algorithm tests for conditional independence between each pair of adjacent nodes $X$ and $Y$ given subsets $Z$ of their neighbours. Variables are conditionally independent if:

$$P(X, Y \mid Z) = P(X \mid Z) \cdot P(Y \mid Z)$$

For continuous variables following a multivariate Gaussian distribution, conditional independence was assessed using partial correlation tests. The partial correlation coefficient between variables $X$ and $Y$ given $Z$ is:

$$\rho_{XY \cdot Z} = \frac{\rho_{XY} - \rho_{XZ} \cdot \rho_{YZ}}{\sqrt{(1 - \rho_{XZ}^2)(1 - \rho_{YZ}^2)}}$$

The test statistic follows:

$$T = \frac{1}{2} \log\left(\frac{1 + \rho_{XY \cdot Z}}{1 - \rho_{XY \cdot Z}}\right) \sqrt{n - |Z| - 3}$$

which is asymptotically distributed as $\mathcal{N}(0, 1)$ under the null hypothesis of conditional independence. Edges were removed when $P < 0.05$, employing a Gaussian conditional independence test (gaussCItest) implemented in the pcalg package [4].

**Phase 2: Edge orientation**  
V-structures (colliders) were identified where two non-adjacent variables both connect to a third variable. For a triple $(X, Y, Z)$ where $X$ and $Z$ are non-adjacent but both connect to $Y$, the pattern is oriented as $X \rightarrow Y \leftarrow Z$ if $Y$ was not in the separating set of $X$ and $Z$.

**Phase 3: Rule propagation**  
Additional edges were oriented by applying Meek's orientation rules [5] to avoid creating new V-structures or directed cycles whilst preserving the identified conditional independence relationships.

### Bayesian Network Structure Learning

To accommodate the mixed continuous and categorical data structure, we employed Bayesian network (BN) learning using the hill-climbing algorithm with Bayesian Information Criterion (BIC) scoring [6]. Bayesian networks represent joint probability distributions through a directed acyclic graph where nodes denote variables and directed edges represent direct probabilistic dependencies.

The joint probability distribution factorises according to the graph structure:

$$P(X_1, X_2, \ldots, X_n) = \prod_{i=1}^{n} P(X_i \mid \text{Pa}(X_i))$$

where $\text{Pa}(X_i)$ denotes the parent variables of $X_i$ in the graph.

**Scoring function**  
The BIC score balances model fit against complexity:

$$\text{BIC} = -2 \log L(\theta \mid D) + k \log(n)$$

where $L(\theta \mid D)$ is the model likelihood given parameters $\theta$ and data $D$, $k$ is the number of free parameters, and $n$ is the sample size. The scoring function was automatically selected based on data composition:

- Conditional Gaussian BIC (bic-cg) for mixed continuous and discrete variables
- Gaussian BIC (bic-g) for continuous-only data
- Standard BIC for discrete-only data

**Hill-climbing algorithm**  
The hill-climbing procedure searches the space of directed acyclic graphs by iteratively evaluating three operations: adding an edge, removing an edge, or reversing an edge direction. At each step, the operation yielding the greatest improvement in BIC score is selected, subject to the constraint that no directed cycles are created. The algorithm terminates when no operation improves the score, indicating a local optimum has been reached.

### Domain Knowledge and Temporal Ordering Constraints

To ensure biologically and logically plausible causal inferences, domain knowledge constraints were incorporated into the structure learning process using blacklists [11]. These constraints prevent the algorithm from inferring causally impossible relationships.

**Exogenous variable constraints**  
Certain variables were classified as exogenous—determined by external factors and therefore incapable of being caused by reproductive outcomes. Four categories of exogenous variables were identified:

1. *Environmental variables*: Photoperiod (F_light_hr, AI_light_hr) is determined by season, latitude, and farm lighting policy, not by reproductive outcomes.

2. *Temporal variables*: Calendar year (Year) and season (Seasons) represent the passage of time, which cannot be caused by biological events.

3. *Farm identifiers*: Farm identity (Company_farm) is a fixed property, not an outcome of reproductive performance.

4. *Herd size*: Average sow numbers (avg.sows) reflects management decisions rather than consequences of individual litter outcomes.

For all exogenous variables $V_{\text{exog}}$, edges of the form $X \rightarrow V_{\text{exog}}$ were prohibited for any non-exogenous variable $X$. This ensures that exogenous variables may only appear as causes (parents) in the learned DAG, never as effects (children).

**Temporal ordering constraints**  
Variables measured at different time points within the reproductive cycle were constrained to respect temporal causality. Events occurring later in time cannot cause events that occurred earlier. The temporal sequence was defined as:

1. Birth events (t₁): prev_PBA, Prev_PBD.cat (litter size and stillbirths)
2. Lactation period (t₂): prev_sowlactpd (lactation duration)  
3. Weaning event (t₃): previous_weaned (number weaned)

For variables $V_{\text{late}}$ occurring at a later time point and $V_{\text{early}}$ at an earlier time point, edges $V_{\text{late}} \rightarrow V_{\text{early}}$ were blacklisted. This constraint prevents temporally impossible relationships such as weaning outcomes causing birth outcomes, whilst permitting the biologically plausible reverse direction.

**Implementation**  
Both exogenous variable and temporal ordering constraints were encoded as blacklists—sets of forbidden edges—and applied to both the hill-climbing structure learning and bootstrap resampling procedures. The combined blacklist ensures that the learned DAG respects both domain knowledge and temporal causality.

### Bootstrap Assessment of Relationship Strength

To evaluate the stability and reliability of identified causal relationships, we performed non-parametric bootstrap resampling with 200 iterations [7]. For each bootstrap sample, the complete structure learning procedure was repeated, and the frequency of each directed edge was recorded.

Two metrics quantified relationship robustness:

**Strength**: The proportion of bootstrap samples containing an edge between variables $X$ and $Y$ (in either direction):

$$S(X \rightarrow Y) = \frac{1}{R} \sum_{r=1}^{R} \mathbb{1}[(X \rightarrow Y) \in G_r \text{ or } (Y \rightarrow X) \in G_r]$$

**Direction**: The proportion of samples where the edge has direction $X \rightarrow Y$ when present:

$$D(X \rightarrow Y) = \frac{\sum_{r=1}^{R} \mathbb{1}[(X \rightarrow Y) \in G_r]}{\sum_{r=1}^{R} \mathbb{1}[(X \rightarrow Y) \in G_r \text{ or } (Y \rightarrow X) \in G_r]}$$

where $R = 200$ is the number of bootstrap replicates, $G_r$ is the graph learned from the $r$-th bootstrap sample, and $\mathbb{1}[\cdot]$ is the indicator function.

Relationships were classified as robust when both strength and direction exceeded 0.5, indicating presence in more than half of bootstrap samples with consistent directionality.

### Conditional Independence Testing

Specific hypotheses regarding conditional independence were evaluated using correlation-based tests for continuous variables. The null hypothesis $H_0: X \perp\!\!\perp Y \mid Z$ (conditional independence) was tested against the alternative $H_1: X \not\perp Y \mid Z$ (conditional dependence) using partial correlation with Fisher's z-transformation.

### Identification of Direct Causes

Variables with directed edges terminating at the outcome variable (lactation mortality) in the learned DAG were classified as direct causes. The set of parent nodes:

$$\text{Pa}(\text{losses.born.alive}) = \{X : X \rightarrow \text{losses.born.alive}\}$$

represents the minimal set of variables that directly influence lactation mortality after accounting for other measured variables in the system.

## Statistical Software

All analyses were conducted in R version 4.3.3 (R Core Team, 2024). The PC algorithm was implemented using the pc() function from the pcalg package (version 2.7) [4]. Bayesian network structure learning employed the hc() and boot.strength() functions from the bnlearn package (version 4.9) [8]. Graph visualisation utilised the Rgraphviz package (version 2.44) from Bioconductor [9]. Data manipulation was performed using dplyr (version 1.1.4) [10].

## Model Assumptions and Validation

### PC Algorithm Assumptions

The PC algorithm relies on several key assumptions: (1) the causal Markov condition, whereby each variable is independent of its non-descendants given its parents; (2) faithfulness, requiring that all conditional independencies in the data arise from the graphical structure; and (3) for Gaussian tests, multivariate normality of continuous variables. Standardisation of continuous variables improved conformity to normality assumptions.

### Bayesian Network Assumptions

Bayesian network structure learning assumes: (1) causal sufficiency, meaning all common causes of measured variables are included; (2) acyclicity, precluding instantaneous feedback loops; and (3) correct specification of local probability models (linear Gaussian for continuous variables conditional on their parents).

### Limitations

The constraint-based approach may identify Markov equivalence classes rather than unique causal structures, particularly for edges whose direction cannot be determined from observational data alone. Bootstrap resampling provides insight into structural uncertainty but does not eliminate fundamental identifiability limitations inherent to observational studies. Unmeasured confounding variables could potentially bias estimates of causal relationships.

## Ethical Statement

All data were collected as part of routine commercial farm management. No experimental procedures were performed on animals specifically for this research. Data handling and analysis complied with institutional data protection policies.

---

## References

1. Pearl J (2009) Causality: Models, Reasoning, and Inference, 2nd edn. Cambridge University Press, Cambridge

2. Spirtes P, Glymour C, Scheines R (2000) Causation, Prediction, and Search, 2nd edn. MIT Press, Cambridge

3. Spirtes P, Glymour C (1991) An algorithm for fast recovery of sparse causal graphs. Soc Sci Comput Rev 9:62–72. https://doi.org/10.1177/089443939100900106

4. Kalisch M, Mächler M, Colombo D, Maathuis MH, Bühlmann P (2012) Causal inference using graphical models with the R package pcalg. J Stat Softw 47:1–26. https://doi.org/10.18637/jss.v047.i11

5. Meek C (1995) Causal inference and causal explanation with background knowledge. In: Proceedings of the Eleventh Conference on Uncertainty in Artificial Intelligence. Morgan Kaufmann, San Francisco, pp 403–410

6. Schwarz G (1978) Estimating the dimension of a model. Ann Stat 6:461–464. https://doi.org/10.1214/aos/1176344136

7. Friedman N, Goldszmidt M, Wyner A (1999) Data analysis with Bayesian networks: a bootstrap approach. In: Proceedings of the Fifteenth Conference on Uncertainty in Artificial Intelligence. Morgan Kaufmann, San Francisco, pp 196–205

8. Scutari M (2010) Learning Bayesian networks with the bnlearn R package. J Stat Softw 35:1–22. https://doi.org/10.18637/jss.v035.i03

9. Hansen KD, Gentry J, Long L, Gentleman R, Falcon S, Hahne F, Sarkar D (2023) Rgraphviz: Provides plotting capabilities for R graph objects. R package version 2.44.0

10. Wickham H, François R, Henry L, Müller K, Vaughan D (2023) dplyr: A grammar of data manipulation. R package version 1.1.4. https://CRAN.R-project.org/package=dplyr

11. Scutari M, Denis J-B (2014) Bayesian Networks: With Examples in R. CRC Press, Boca Raton

---

**Note:** This document is formatted in Markdown and optimised for conversion to Microsoft Word (.docx) format using pandoc, with mathematical equations rendered as editable Office Math expressions. To convert:

```bash
pandoc MATERIALS_METHODS_GSE.md -o MATERIALS_METHODS_GSE.docx
```

For enhanced formatting with a reference document template:

```bash
pandoc MATERIALS_METHODS_GSE.md -o MATERIALS_METHODS_GSE.docx --reference-doc=template.docx
```
