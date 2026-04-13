-- ============================================================
-- 03_data_cleaning.sql
-- Opioid Pipeline Analysis — Phase 3: Data Cleaning
-- Cleans CMS, CDC, and AHRQ staging tables
-- ============================================================


-- ============================================================
-- Phase 3: CMS Data Cleaning & State-Level Aggregation
-- ============================================================

DROP TABLE IF EXISTS clean_cms_state;

CREATE TABLE clean_cms_state AS
SELECT
    d.state_abbrev,
    d.state_name,
    d.state_fips,
    d.census_region,
    d.census_division,

    -- Prescribing volume metrics
    SUM(c.tot_clms)                         AS total_opioid_claims,
    SUM(c.tot_30day_fills)                   AS total_30day_fills,
    SUM(c.tot_day_suply)                     AS total_day_supply,
    ROUND(SUM(c.tot_drug_cst)::numeric, 2)   AS total_opioid_cost,

    -- Prescriber counts
    COUNT(DISTINCT c.prscrbr_npi)            AS total_opioid_prescribers,

    -- Drug diversity
    COUNT(DISTINCT c.gnrc_name)              AS distinct_opioid_drugs,

    -- Row count (for validation)
    COUNT(*)                                 AS cms_row_count

FROM stg_cms_partd c
JOIN dim_state d ON TRIM(c.prscrbr_state_abrvtn) = d.state_abbrev

WHERE
    -- 1. Remove false-positive non-opioid drugs
    c.gnrc_name NOT IN (
        'Tiotropium Bromide',
        'Ipratropium Bromide',
        'Ipratropium/Albuterol Sulfate',
        'Tiotropium Br/Olodaterol Hcl',
        'Apomorphine Hcl'
    )
    -- 2. Exclude territories (JOIN to dim_state already handles this)
    -- 3. Specialty consolidation handled below

GROUP BY
    d.state_abbrev, d.state_name, d.state_fips,
    d.census_region, d.census_division

ORDER BY total_opioid_claims DESC;



-- ============================================================
-- Phase 3: CDC Data Cleaning
-- ============================================================

DROP TABLE IF EXISTS clean_cdc_state;

CREATE TABLE clean_cdc_state AS
SELECT DISTINCT
    d.state_abbrev,
    d.state_name,
    cdc.data_value          AS opioid_deaths,
    cdc.predicted_value     AS predicted_deaths,
    cdc.percent_complete,
    cdc.percent_pending_investigation,
    cdc.indicator           AS death_indicator

FROM stg_cdc_overdose cdc
JOIN dim_state d ON cdc.state_name = d.state_name

WHERE
    -- Filter to our chosen indicator (best coverage at 42 states)
    cdc.indicator LIKE 'Natural & semi-synthetic opioids, incl. methad%%'
    -- December 2020 = 12-month-ending annual total
    AND cdc.year = 2020
    AND cdc.month = 'December'
    -- Exclude aggregates and non-state entries
    AND cdc.state_name NOT IN ('United States', 'New York City')
    -- Only states with actual death data
    AND cdc.data_value IS NOT NULL

ORDER BY opioid_deaths DESC;



-- ============================================================
-- Phase 3: AHRQ SDOH Cleaning & Population-Weighted Aggregation
-- ============================================================

DROP TABLE IF EXISTS agg_state_sdoh;

CREATE TABLE agg_state_sdoh AS
WITH deduplicated AS (
    -- Step 1: Remove exact duplicate rows
    SELECT DISTINCT
        countyfips, statefips, county, state,
        pct_poverty, pct_unemployed, median_hh_income,
        gini_index, pct_uninsured, total_population
    FROM stg_ahrq_sdoh
    WHERE
        -- Exclude territories
        statefips NOT IN ('60', '66', '69', '72', '78')
        -- Exclude counties with no population (can't weight)
        AND total_population IS NOT NULL
        AND total_population > 0
)
SELECT
    d.state_abbrev,
    d.state_name,
    dd.statefips,

    -- Population-weighted averages
    -- Formula: SUM(county_value * county_pop) / SUM(county_pop)
    ROUND(
        SUM(dd.pct_poverty * dd.total_population) / 
        NULLIF(SUM(dd.total_population), 0)
    , 2) AS w_pct_poverty,

    ROUND(
        SUM(dd.pct_unemployed * dd.total_population) / 
        NULLIF(SUM(dd.total_population), 0)
    , 2) AS w_pct_unemployed,

    ROUND(
        SUM(dd.median_hh_income * dd.total_population) / 
        NULLIF(SUM(dd.total_population), 0)
    , 2) AS w_median_income,

    ROUND((
        SUM(dd.gini_index * dd.total_population) / 
        NULLIF(SUM(dd.total_population), 0)
    )::numeric, 4) AS w_gini_index,

    ROUND(
        SUM(dd.pct_uninsured * dd.total_population) / 
        NULLIF(SUM(dd.total_population), 0)
    , 2) AS w_pct_uninsured,

    -- State population total
    SUM(dd.total_population) AS state_population,

    -- County count (for validation)
    COUNT(*) AS county_count

FROM deduplicated dd
JOIN dim_state d ON dd.statefips = d.state_fips

GROUP BY d.state_abbrev, d.state_name, dd.statefips
ORDER BY state_population DESC;
