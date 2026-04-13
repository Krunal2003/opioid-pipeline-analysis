# Phase 1: Business Understanding

> **CRISP-DM Phase**: 1 of 6 — Business Understanding  
> **Project**: Opioid Pipeline Analysis  
> **Author**: Krunal  
> **Date**: March 2026  
> **Status**: Complete

---

## Table of Contents

- [1. Business Objectives](#1-business-objectives)
  - [1.1 Stakeholder Context](#11-stakeholder-context)
  - [1.2 Primary Business Question](#12-primary-business-question)
  - [1.3 Secondary Business Questions](#13-secondary-business-questions)
  - [1.4 Business Success Criteria](#14-business-success-criteria)
  - [1.5 Technical Success Criteria](#15-technical-success-criteria)
- [2. Situation Assessment](#2-situation-assessment)
  - [2.1 Data Resources Inventory](#21-data-resources-inventory)
  - [2.2 Tools and Infrastructure](#22-tools-and-infrastructure)
  - [2.3 Assumptions to Validate](#23-assumptions-to-validate)
  - [2.4 Key Risks and Mitigation Strategies](#24-key-risks-and-mitigation-strategies)
  - [2.5 Known Limitations](#25-known-limitations)
  - [2.6 Terminology and Definitions](#26-terminology-and-definitions)
- [3. Data Mining Goals](#3-data-mining-goals)
  - [3.1 Analytical Objectives](#31-analytical-objectives)
  - [3.2 Mapping: Business Questions → Analytical Methods](#32-mapping-business-questions--analytical-methods)
- [4. Project Plan](#4-project-plan)
  - [4.1 Four-Week Timeline](#41-four-week-timeline)
  - [4.2 Deliverables by Phase](#42-deliverables-by-phase)
- [5. How to Reproduce This Project](#5-how-to-reproduce-this-project)

---

## 1. Business Objectives

### 1.1 Stakeholder Context

**Simulated Client**: A state health department's Opioid Prevention Program, modeled after real-world programs such as the New York State Department of Health (NYSDOH) Opioid Prevention Program and Pennsylvania's Prescription Drug Monitoring Program (PDMP) analysis unit.

**What the stakeholder does with data**:

The opioid prevention program uses data analytics to inform four core operational decisions:

1. **Naloxone distribution planning** — Deciding which counties and communities receive overdose-reversal kits based on overdose incidence and prescribing density.
2. **Prescriber education targeting** — Identifying medical specialties and geographic regions where opioid prescribing rates are disproportionately high, so outreach campaigns reach the providers most likely to impact outcomes.
3. **Medicaid fraud investigation prioritization** — Flagging providers whose prescribing volume or patterns are statistical outliers for further review.
4. **PDMP policy recommendations** — Evaluating whether mandatory prescriber consultation with the state's PDMP database correlates with lower overdose rates, informing legislative advocacy.

**Why this analysis matters**: The U.S. opioid epidemic has killed over 500,000 people since 1999. The crisis has evolved through three waves — prescription opioids (1990s–2010), heroin (2010+), and illicit fentanyl (2013+) — but the relationship between physician prescribing behavior and overdose outcomes remains a critical lever for public health intervention, especially for the Medicare population where prescription opioids still play a significant role.

### 1.2 Primary Business Question

> **"Which U.S. regions show the strongest link between physician opioid prescribing patterns and overdose mortality, and what socioeconomic factors amplify or buffer this relationship — so a state health department can prioritize intervention resources?"**

This question is designed to be answerable with publicly available federal data, actionable for a health department stakeholder, and analytically rich enough to demonstrate correlation analysis, controlled regression, and geographic segmentation.

### 1.3 Secondary Business Questions

| # | Question | Why It Matters |
|---|----------|---------------|
| 1 | Which medical specialties account for the highest volume of opioid prescriptions? | Helps the stakeholder target prescriber education campaigns toward the specialties writing the most opioid scripts. |
| 2 | Have prescribing rates declined since the 2016 CDC Guideline for Prescribing Opioids, and if so, unevenly across states? | Evaluates the policy impact of the most significant federal prescribing intervention and identifies lagging states. |
| 3 | Do states with mandatory PDMP consultation laws show lower overdose rates? | Informs the stakeholder's legislative advocacy — should they push for mandatory PDMP consultation? |
| 4 | Which socioeconomic risk factors (poverty, unemployment, uninsured rate) most amplify the prescribing-to-death pipeline? | Helps the stakeholder understand which communities are most vulnerable, enabling more precise resource allocation. |
| 5 | Can we identify 10 priority states for targeted intervention based on a combined risk score? | Delivers the core actionable output: a ranked priority list the stakeholder can use to allocate budget and staff. |

### 1.4 Business Success Criteria

This project succeeds from a business perspective if it delivers:

| # | Criterion | Measurement |
|---|-----------|-------------|
| 1 | A ranked list of the top 10 priority states for opioid intervention | List produced, with supporting risk scores and methodology |
| 2 | Explanation of at least 50% of the variance in state-level overdose death rates | Multiple regression R² ≥ 0.50 |
| 3 | 3–5 specific, actionable policy recommendations | Recommendations grounded in analytical findings, not generic advice |
| 4 | An interactive Tableau dashboard published on Tableau Public | Dashboard is live, functional, and tells a coherent data story |

### 1.5 Technical Success Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | The correlation between state-level opioid prescribing rate and overdose death rate is statistically significant | Pearson or Spearman p-value < 0.05 |
| 2 | Multiple regression model with SDOH controls achieves meaningful explanatory power | R² ≥ 0.50 |
| 3 | All three data sources are successfully merged on common geographic keys | Join validation queries confirm no orphaned records on critical keys |
| 4 | The analysis covers a sufficient time window to observe trends | At least 5 years (2017–2022 recommended) |

---

## 2. Situation Assessment

### 2.1 Data Resources Inventory

This project integrates three publicly available federal datasets. Each is described below with its source, scope, granularity, and known quality issues.

#### Dataset 1: CMS Medicare Part D Prescribers — by Provider and Drug

| Attribute | Detail |
|-----------|--------|
| **Source** | Centers for Medicare & Medicaid Services (CMS) |
| **URL** | https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers/medicare-part-d-prescribers-by-provider-and-drug |
| **Size** | ~25 million rows per year (4–6 GB CSV per year) |
| **Granularity** | One row per prescriber (NPI) × drug × year |
| **Years available** | 2013–2023 |
| **Key columns** | `Prscrbr_NPI`, `Prscrbr_State_Abrvtn`, `Prscrbr_Type`, `Gnrc_Name`, `Tot_Clms`, `Tot_Drug_Cst`, `Tot_Benes`, `Opioid_Drug_Flag`, `Opioid_LA_Drug_Flag` |

**Known data quality issues**:
- `Tot_Benes` is suppressed (NULL) when beneficiary count ≤10, per CMS privacy rules.
- Drug name inconsistencies exist across rows (e.g., "OXYCODONE HCL" vs. "OXYCODONE HYDROCHLORIDE" vs. "OXYCODONE HCL ER" are separate entries).
- Specialty name near-duplicates exist (e.g., "Family Practice" vs. "Family Medicine").
- **Population coverage limitation**: Part D covers only Medicare beneficiaries (~65+ population). It does not include commercial insurance, Medicaid, or uninsured prescriptions.
- File size (4–6 GB) exceeds in-memory capacity for standard `pd.read_csv()` — must use chunked reading or direct PostgreSQL `COPY` command.

#### Dataset 2: CDC VSRR Provisional Drug Overdose Death Counts

| Attribute | Detail |
|-----------|--------|
| **Source** | CDC National Center for Health Statistics (NCHS) — Vital Statistics Rapid Release (VSRR) |
| **URL** | https://data.cdc.gov/NCHS/VSRR-Provisional-Drug-Overdose-Death-Counts/xkb8-kh2a |
| **Size** | ~60,000+ rows (~15 MB) |
| **Granularity** | State × month × drug indicator |
| **Years available** | 2015–present (provisional, updated monthly) |
| **Key columns** | `State`, `Year`, `Month`, `Indicator`, `Data Value`, `Percent Complete`, `Percent Pending Investigation`, `Predicted Value` |

**Known data quality issues**:
- Data is provisional: recent months (2024–2025) may be incomplete. This analysis anchors on 2017–2022 for reliability.
- Death counts of 1–9 are suppressed (blank) per NCHS confidentiality rules.
- `Percent Pending Investigation` >15% indicates that drug-specific causes of death are underreported in that state/month.
- `Data Value` for a given month often represents a 12-month rolling period ending in that month, not the single month. December rows will be used to approximate annual totals.
- State names are formatted as full names (e.g., "Massachusetts") — a mapping table is needed to join with CMS state abbreviations.

#### Dataset 3: AHRQ Social Determinants of Health (SDOH) Database

| Attribute | Detail |
|-----------|--------|
| **Source** | Agency for Healthcare Research and Quality (AHRQ) |
| **URL** | https://www.ahrq.gov/sdoh/data-analytics/sdoh-data.html |
| **Documentation** | https://www.ahrq.gov/sites/default/files/wysiwyg/sdoh/SDOH-Data-Sources-Documentation-v1-Final.pdf |
| **Size** | County-level ~3,200 rows; ZIP-level ~33,000 rows; 17,000+ variables |
| **Granularity** | County (5-digit FIPS), ZIP code (ZCTA), or Census tract |
| **Years available** | 2009–2020 |
| **Key variables** | `ACS_PCT_LT_POVERTY`, `ACS_PCT_UNEMPLOY`, `ACS_MEDIAN_HH_INC`, `ACS_PCT_UNINSURED`, `ACS_GINI_INDEX`, `AHRF_TOT_PHYSICIANS`, `COUNTYFIPS`, `STATEFIPS` |

**Known data quality issues**:
- The database ends at 2020, creating a 2–3 year lag relative to CMS/CDC data. However, SDOH variables (poverty rates, unemployment, insurance coverage) change slowly enough that 2020 values remain reasonable proxies for 2021–2022 conditions.
- Variable names are extremely long (e.g., "ACS_PCT_PERSON_BELOW_100PCT_FPL_EST") — a column-renaming step is required during data preparation.
- Two Minnesota counties were mislabeled in earlier AHRQ versions (FIPS 27111 and 27165) — will be verified during data validation.
- County-to-state aggregation must use population-weighted averages, not simple means. A simple average would treat a county of 500 people equally with a county of 5 million.
- The database draws from 44 different data sources — variable availability differs by year and geography.

### 2.2 Tools and Infrastructure

| Category | Tool | Purpose |
|----------|------|---------|
| Database | PostgreSQL (local, via pgAdmin) | Data storage, SQL-based cleaning, merging, and feature engineering |
| Programming | Python 3.x (pandas, numpy, scipy, scikit-learn, statsmodels, seaborn, matplotlib) | Statistical analysis, regression modeling, visualization |
| IDE | VS Code with Jupyter extension | Notebook-based analysis |
| Visualization | Tableau Public (free tier) | Interactive dashboard for deployment |
| Version control | Git + GitHub | Code management and portfolio hosting |
| Deployment | Streamlit Community Cloud (optional) | Web-hosted interactive app |

### 2.3 Assumptions to Validate

These assumptions will be explicitly tested during Phase 2 (Data Understanding). Each has a defined validation method and a contingency plan if the assumption fails.

| # | Assumption | Validation Method (Phase 2) | Contingency if False |
|---|-----------|---------------------------|----------------------|
| A1 | The CMS `Opioid_Drug_Flag` reliably classifies opioid prescriptions, and filtering on `Opioid_Drug_Flag = 'Y'` captures all relevant opioid claims. | Cross-reference flagged drugs against a known opioid list (e.g., CDC's list of commonly prescribed opioids). Check if major opioids like oxycodone, hydrocodone, and fentanyl patches are consistently flagged. | Supplement with a manual drug-name filter using `Gnrc_Name ILIKE '%OXYCODONE%'` patterns. |
| A2 | Geographic join keys (state abbreviations, full state names, FIPS codes) are consistent and mappable across all three datasets. | Create a `dim_state` reference table with 51 rows (50 states + DC). Perform LEFT JOINs and check for NULL join keys (orphaned records). | Fix mismatches manually in the reference table. Drop territories (PR, VI, GU) if they lack data in all three sources. |
| A3 | CDC provisional death data for 2017–2022 is sufficiently complete (≥85% `Percent Complete`) for state-level analysis. | Query `Percent Complete` and `Percent Pending Investigation` for all state × year combinations in the analysis window. Flag any rows below 85%. | Exclude state-year combinations below the threshold, or use the CDC's `Predicted Value` column as an adjusted alternative. |
| A4 | The relationship between prescribed opioid rates and overdose mortality is not entirely confounded by the rise of illicit fentanyl after 2016. | Visually inspect the prescribing rate vs. death rate time series. If prescribing rates decline while death rates rise sharply, the illicit fentanyl confound is significant. | Acknowledge the confound explicitly in findings. Consider limiting the primary analysis to 2017–2019 (pre-fentanyl-surge window) as a sensitivity check, or add a fentanyl-specific indicator from CDC data as a control variable. |

### 2.4 Key Risks and Mitigation Strategies

| # | Risk | Severity | Likelihood | Mitigation |
|---|------|----------|------------|------------|
| R1 | **Data size**: CMS Part D files are 4–6 GB per year. Loading 6 years into pandas will exceed memory. | High | High | Use PostgreSQL `COPY` command for bulk ingestion. Filter to `Opioid_Drug_Flag = 'Y'` rows only during loading to reduce size by ~95%. Alternatively, use chunked reading with `pd.read_csv(chunksize=500000)`. |
| R2 | **Suppressed values**: Both CMS and CDC suppress small counts (≤10 patients, 1–9 deaths) for privacy. This creates systematic NULLs. | Medium | High | Document the suppression mechanism. For CMS, use `Tot_Clms` as the primary metric (not suppressed) instead of `Tot_Benes`. For CDC, state-level annual totals are large enough that suppression rarely applies — validate this in Phase 2. |
| R3 | **Ecological fallacy**: State-level correlations do not imply individual-level causation. A state with high prescribing and high deaths does not mean the same individuals are being prescribed and dying. | Medium | Certain | This is a fundamental limitation of state-level analysis, not a fixable error. Acknowledge it prominently in all findings and the README. Frame conclusions as "state-level associations" rather than causal claims. |
| R4 | **Illicit fentanyl confound**: Post-2016, overdose deaths are increasingly driven by illicit fentanyl, not prescribed opioids. This weakens the prescribing→death causal pathway. | High | High | Acknowledge this as the most significant analytical limitation. Run a sensitivity analysis comparing pre-2017 vs. post-2017 correlation strength. Consider adding illicit fentanyl death counts (from CDC `Indicator` = "Synthetic opioids excl. methadone") as a control variable. |
| R5 | **SDOH temporal lag**: AHRQ data ends at 2020, while CMS/CDC data extends to 2022. | Low | Certain | SDOH variables (poverty, unemployment, insurance rates) change slowly. Using 2019–2020 values as proxies for 2021–2022 is standard practice in health services research. Document the assumption. |
| R6 | **Timeline pressure**: Estimated 36 hours of work over 4 weeks, while balancing co-op responsibilities. | Medium | Medium | Follow the project plan strictly. Prioritize the core analysis (correlation + regression) over stretch goals (Streamlit deployment). Maintain a decision log to avoid revisiting completed work. |

### 2.5 Known Limitations

These limitations should be disclosed in the final README and any presentation of findings:

1. **Population coverage bias**: CMS Part D covers only Medicare beneficiaries (predominantly age 65+). Prescribing patterns for younger adults — who experience the highest rates of opioid use disorder — are not captured. Findings should be framed as reflecting "Medicare prescribing patterns," not all U.S. prescribing.

2. **Ecological fallacy**: All analysis is at the state level. A correlation between a state's prescribing rate and its overdose death rate does not mean the individuals being prescribed opioids are the same individuals dying of overdoses. This is especially true given the rise of illicit opioids.

3. **Illicit fentanyl disruption**: Since approximately 2016, illicitly manufactured fentanyl has become the dominant driver of overdose deaths in many states. This partially decouples the prescribing→death relationship that is central to this analysis. The analysis will quantify this decoupling but cannot fully control for it.

4. **Provisional data uncertainty**: CDC VSRR data is provisional and subject to revision. Death counts for recent years may be undercounted, particularly in states with high rates of pending death investigations.

5. **SDOH temporal mismatch**: Socioeconomic indicators from AHRQ are available only through 2020, while the analysis window extends to 2022. A 2-year lag is assumed acceptable for slowly changing variables, but this should be noted.

### 2.6 Terminology and Definitions

| Term | Definition |
|------|-----------|
| **CRISP-DM** | Cross-Industry Standard Process for Data Mining — a six-phase methodology for structuring analytics projects. |
| **NPI** | National Provider Identifier — a unique 10-digit number assigned to every healthcare provider in the U.S. |
| **Part D** | The Medicare prescription drug benefit program, covering outpatient prescription drugs for Medicare beneficiaries. |
| **PDMP** | Prescription Drug Monitoring Program — a state-run electronic database that tracks dispensing of controlled substances. |
| **VSRR** | Vital Statistics Rapid Release — the CDC's system for publishing provisional mortality data before final death certificate processing is complete. |
| **SDOH** | Social Determinants of Health — the conditions in which people are born, grow, live, work, and age that affect health outcomes. |
| **FIPS code** | Federal Information Processing Standards code — a numeric code uniquely identifying U.S. states (2-digit) and counties (5-digit). |
| **Opioid prescribing rate** | The number of opioid prescriptions (claims) per 1,000 Medicare Part D beneficiaries in a given state and year. |
| **Overdose death rate** | The number of opioid-involved overdose deaths per 100,000 population in a given state and year. |
| **Ecological fallacy** | The logical error of inferring individual-level relationships from group-level (aggregate) data. |
| **R²** | Coefficient of determination — the proportion of variance in the dependent variable explained by the model. An R² of 0.50 means 50% of variance is explained. |

---

## 3. Data Mining Goals

### 3.1 Analytical Objectives

Each business question is translated below into a specific, measurable analytical objective with a defined method and output.

#### Objective 1: Descriptive Analytics — Characterize Prescribing Patterns

| Attribute | Detail |
|-----------|--------|
| **Business question addressed** | Q1 (specialty rankings) and Q2 (post-2016 trends) |
| **Method** | SQL aggregation with `GROUP BY` on `Prscrbr_State_Abrvtn`, `Prscrbr_Type`, and year. Compute opioid claims per capita by state. Rank specialties by total opioid claims volume. |
| **Output** | State-level prescribing rate table (50 states × 6 years), top-10 specialty ranking, year-over-year trend lines |
| **SQL skills demonstrated** | `GROUP BY`, `COUNT DISTINCT`, `SUM`, `CASE WHEN`, `ORDER BY` |

#### Objective 2: Correlation Analysis — Quantify the Prescribing-Death Relationship

| Attribute | Detail |
|-----------|--------|
| **Business question addressed** | Primary question (prescribing patterns ↔ overdose mortality) |
| **Method** | Compute Pearson and Spearman correlation coefficients between `opioid_rx_rate` and `death_rate_per_100k` at the state × year level. Test for statistical significance (p < 0.05). Visualize with a scatter plot. |
| **Output** | Correlation coefficient with p-value, scatter plot with regression line and confidence interval |
| **Python skills demonstrated** | `scipy.stats.pearsonr`, `scipy.stats.spearmanr`, `seaborn.regplot` |

#### Objective 3: Controlled Regression — Isolate Prescribing Effect from SDOH Confounders

| Attribute | Detail |
|-----------|--------|
| **Business question addressed** | Q4 (socioeconomic amplifiers) |
| **Method** | Multiple linear regression predicting `death_rate_per_100k` from `opioid_rx_rate` + SDOH controls (`w_pct_poverty`, `w_pct_unemployed`, `w_median_income`, `w_pct_uninsured`, `w_gini_index`). Report R², adjusted R², p-values for each coefficient, and standardized (beta) coefficients to compare effect sizes. |
| **Output** | Regression summary table, coefficient plot, R² interpretation |
| **Target** | R² ≥ 0.50 |
| **Python skills demonstrated** | `statsmodels.api.OLS`, `sklearn.preprocessing.StandardScaler` |

#### Objective 4: Cohort Segmentation — Compare Outcomes Across Prescribing Quartiles

| Attribute | Detail |
|-----------|--------|
| **Business question addressed** | Primary question (regional patterns) and Q2 (post-2016 trends) |
| **Method** | Assign each state to a prescribing quartile using `NTILE(4)` window function on `opioid_rx_rate`. Compare mean overdose death rates across quartiles using ANOVA or Kruskal-Wallis test. Track quartile stability over time (do states move between quartiles year-over-year?). |
| **Output** | Box plot of death rates by prescribing quartile, quartile transition matrix, significance test results |
| **SQL skills demonstrated** | `NTILE()`, `LAG()` window functions |

#### Objective 5: Intervention Targeting — Identify Top-10 Priority States

| Attribute | Detail |
|-----------|--------|
| **Business question addressed** | Q5 (priority state identification) |
| **Method** | Create a composite risk score combining: (a) opioid prescribing rate (normalized 0–100), (b) overdose death rate (normalized 0–100), (c) SDOH risk index (poverty, unemployment, uninsured — normalized and averaged). Rank states by composite score. Estimate potential impact: "If the top-10 states reduced prescribing to the national median, how many fewer claims would that represent?" |
| **Output** | Ranked state list with composite scores, geographic heat map, impact estimation |
| **SQL/Python skills demonstrated** | Min-max normalization, `RANK()` window function, `groupby` + `rank` in pandas |

### 3.2 Mapping: Business Questions → Analytical Methods

| Business Question | Analytical Objective | Primary Method | Key Output |
|-------------------|---------------------|----------------|------------|
| Primary: Prescribing ↔ mortality link | Obj 2: Correlation | Pearson/Spearman | r, p-value, scatter plot |
| Primary: Regional variation | Obj 4: Cohort segmentation | NTILE quartiles + ANOVA | Box plot, quartile comparison |
| Q1: Top specialties | Obj 1: Descriptive | SQL GROUP BY + ranking | Specialty leaderboard |
| Q2: Post-2016 decline | Obj 1: Descriptive | Year-over-year LAG() | Trend lines by state |
| Q3: PDMP policy effect | Obj 3: Regression | Binary indicator in model | Coefficient + p-value |
| Q4: SDOH amplifiers | Obj 3: Regression | Multiple regression with controls | Standardized coefficients |
| Q5: Priority states | Obj 5: Targeting | Composite risk score | Top-10 ranked list |

---

## 4. Project Plan

### 4.1 Four-Week Timeline

#### Week 1: Data Understanding + Initial Preparation (~12 hours)

**CRISP-DM Phases**: Phase 2 (Data Understanding) + Phase 3 start (Data Preparation)

| Day | Task | Hours | Deliverable |
|-----|------|-------|-------------|
| 1–2 | Download all three datasets. Set up PostgreSQL database and create schema (`dim_state`, staging tables). | 3 | `sql/01_schema_creation.sql` |
| 3–4 | Load data into PostgreSQL using `COPY` command. Validate row counts against source documentation. | 4 | `sql/02_data_loading.sql` |
| 5–6 | Profile each dataset: NULL rates, value distributions, outlier detection. Validate the four assumptions from Section 2.3. | 3 | First half of `notebooks/01_data_ingestion_cleaning.ipynb` |
| 7 | Run 7 EDA visualizations (distributions, bar charts, time series). Document findings in notebook markdown cells. | 2 | `notebooks/02_exploratory_analysis.ipynb` (started) |

#### Week 2: Data Preparation + EDA Completion (~8 hours)

**CRISP-DM Phase**: Phase 3 (Data Preparation)

| Day | Task | Hours | Deliverable |
|-----|------|-------|-------------|
| 1–2 | Execute 7 data cleaning operations (drug name normalization, specialty consolidation, suppressed value handling, date standardization, state name mapping, SDOH variable selection, outlier treatment). | 3 | Second half of `notebooks/01_data_ingestion_cleaning.ipynb` |
| 3–4 | Write the 4-CTE master merge query joining all three sources via `dim_state`. Validate join results. | 3 | `sql/03_master_merge.sql` |
| 5 | Engineer all 14 features in SQL and Python. Populate `fact_opioid_analysis` table. | 2 | `sql/04_feature_engineering.sql` |

#### Week 3: Modeling + Evaluation (~8 hours)

**CRISP-DM Phases**: Phase 4 (Modeling) + Phase 5 (Evaluation)

| Day | Task | Hours | Deliverable |
|-----|------|-------|-------------|
| 1–2 | Descriptive analysis: state-level prescribing rates, specialty rankings, drug rankings. | 2 | `notebooks/02_exploratory_analysis.ipynb` (completed) |
| 3–4 | Correlation analysis (Pearson/Spearman) + multiple regression with SDOH controls. | 3 | `notebooks/03_correlation_regression.ipynb` |
| 5 | Cohort segmentation: prescribing quartiles, outcome comparison, quartile stability. | 1.5 | Continued in `notebooks/03_correlation_regression.ipynb` |
| 6 | Evaluation: cross-year validation, business sense checks, limitation documentation. | 1.5 | `sql/05_validation_queries.sql` + notebook evaluation section |

#### Week 4: Deployment + Polish (~8 hours)

**CRISP-DM Phase**: Phase 6 (Deployment)

| Day | Task | Hours | Deliverable |
|-----|------|-------|-------------|
| 1–2 | Export final analysis CSV. Build 4-view Tableau dashboard on Tableau Public. | 3 | Live Tableau Public dashboard |
| 3–4 | Write README.md with executive summary, methodology, key findings, embedded figures. | 2.5 | `README.md` |
| 5 | GitHub repo polish: .gitignore, requirements.txt, folder structure, code comments review. | 1.5 | Clean repository |
| 6 | Write resume bullet point and draft LinkedIn post. | 1 | Resume line + LinkedIn draft |

**Total estimated effort**: ~36 hours over 4 weeks.

### 4.2 Deliverables by Phase

| CRISP-DM Phase | Key Deliverables |
|----------------|-----------------|
| Phase 1: Business Understanding | `01_business_understanding.md` (this document) |
| Phase 2: Data Understanding | `notebooks/01_data_ingestion_cleaning.ipynb` (first half: profiling + EDA) |
| Phase 3: Data Preparation | `sql/01_schema_creation.sql`, `sql/02_data_loading.sql`, `sql/03_master_merge.sql`, `sql/04_feature_engineering.sql`, `notebooks/01_data_ingestion_cleaning.ipynb` (second half: cleaning) |
| Phase 4: Modeling | `notebooks/03_correlation_regression.ipynb` |
| Phase 5: Evaluation | `sql/05_validation_queries.sql`, evaluation sections in notebooks |
| Phase 6: Deployment | Tableau Public dashboard, `README.md`, `figures/` PNGs, resume bullet, LinkedIn post |

---

## 5. How to Reproduce This Project

This section provides step-by-step instructions for setting up and running this analysis from scratch.

### Step 1: Set Up the Repository

```bash
# Create the project directory structure
mkdir -p opioid-pipeline-analysis/{data/{raw,processed},notebooks,sql,figures,dashboards/screenshots}

# Navigate into the project
cd opioid-pipeline-analysis

# Initialize git
git init

# Create .gitignore (raw data files are too large for GitHub)
cat <<EOF > .gitignore
data/raw/
*.csv
*.tsv
*.xlsx
__pycache__/
.ipynb_checkpoints/
.DS_Store
*.pyc
EOF

# Create requirements.txt
cat <<EOF > requirements.txt
pandas>=2.0.0
numpy>=1.24.0
scipy>=1.10.0
scikit-learn>=1.3.0
statsmodels>=0.14.0
seaborn>=0.12.0
matplotlib>=3.7.0
geopandas>=0.13.0
requests>=2.31.0
psycopg2-binary>=2.9.0
sqlalchemy>=2.0.0
jupyter>=1.0.0
EOF

# Install Python dependencies
pip install -r requirements.txt
```

### Step 2: Set Up PostgreSQL

```sql
-- In pgAdmin or psql, create the project database
CREATE DATABASE opioid_analysis;

-- Connect to the new database, then create the schema
-- (The full schema DDL will be in sql/01_schema_creation.sql, built in Phase 3)
```

### Step 3: Download the Three Datasets

**Dataset 1 — CMS Medicare Part D** (⚠️ Large files, 4–6 GB each):
1. Go to: https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers/medicare-part-d-prescribers-by-provider-and-drug
2. Download CSV files for years 2017, 2018, 2019, 2020, 2021, and 2022.
3. Save to `data/raw/` (these are gitignored due to size).
4. **Important**: Do not attempt to open these in Excel or load fully into pandas. Use PostgreSQL `COPY` or chunked reading.

**Dataset 2 — CDC VSRR Overdose Deaths**:
1. Go to: https://data.cdc.gov/NCHS/VSRR-Provisional-Drug-Overdose-Death-Counts/xkb8-kh2a
2. Click "Export" → "CSV" to download the full dataset.
3. Save as `data/raw/cdc_vsrr_overdose.csv`.

**Dataset 3 — AHRQ SDOH**:
1. Go to: https://www.ahrq.gov/sdoh/data-analytics/sdoh-data.html
2. Download the county-level file for the most recent available year (2020 recommended).
3. Save as `data/raw/ahrq_sdoh_county.csv`.
4. Also download the documentation PDF for variable name reference.

### Step 4: Load Data into PostgreSQL

```bash
# After creating the schema (sql/01_schema_creation.sql), load data using:
# Full loading scripts will be in sql/02_data_loading.sql (Phase 3 deliverable)

# For the large CMS files, the recommended approach is:
psql -d opioid_analysis -c "\COPY stg_cms_partd FROM 'data/raw/cms_partd_2022.csv' WITH (FORMAT csv, HEADER true);"
```

### Step 5: Run the Analysis Notebooks (in order)

```bash
# Open VS Code and run notebooks in sequence:
# 1. notebooks/01_data_ingestion_cleaning.ipynb  — Data profiling, cleaning, validation
# 2. notebooks/02_exploratory_analysis.ipynb     — 7 EDA visualizations
# 3. notebooks/03_correlation_regression.ipynb   — Statistical modeling
# 4. notebooks/04_feature_engineering.ipynb      — Feature computation and final table
```

### Step 6: Run SQL Scripts (in order)

```bash
# Execute against the opioid_analysis database:
psql -d opioid_analysis -f sql/01_schema_creation.sql
psql -d opioid_analysis -f sql/02_data_loading.sql
psql -d opioid_analysis -f sql/03_master_merge.sql
psql -d opioid_analysis -f sql/04_feature_engineering.sql
psql -d opioid_analysis -f sql/05_validation_queries.sql
```

### Step 7: Build the Tableau Dashboard

1. Export the final `fact_opioid_analysis` table to CSV: `data/processed/fact_opioid_analysis.csv`
2. Open Tableau Public and connect to the CSV file.
3. Build four dashboard views (Executive KPI, Geographic Dual-Map, Scatter with SDOH Overlay, Time-Series Trend).
4. Publish to Tableau Public and save the link in `dashboards/tableau_public_link.md`.

### Step 8: Polish and Publish

1. Write the `README.md` with executive summary, methodology, key findings, and embedded figures.
2. Take screenshots of the Tableau dashboard and save in `dashboards/screenshots/`.
3. Review all code for comments and documentation completeness.
4. Push to GitHub.
5. Draft the LinkedIn post and update your resume bullet point.

---

*This document was created as part of Phase 1 (Business Understanding) of the CRISP-DM methodology. All assumptions, risks, and limitations documented here will be revisited and validated in Phase 2 (Data Understanding).*
